package fr.skyost.simple_secure_storage.android

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.annotation.RequiresApi
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/**
 * SimpleSecureStorage Android plugin.
 */
class SimpleSecureStorageAndroidPlugin: FlutterPlugin, MethodCallHandler {
  /**
   * The MethodChannel that will the communication between Flutter and native Android.
   *
   * This local reference serves to register the plugin with the Flutter Engine and unregister it
   * when the Flutter Engine is detached from the Activity.
   */
  private lateinit var channel : MethodChannel

  /**
   * The context instance.
   */
  private var context: Context? = null

  /**
   * The preferences instance.
   */
  private var preferences: SharedPreferences? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fr.skyost.simple_secure_storage")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  @SuppressLint("ApplySharedPref")
  @RequiresApi(Build.VERSION_CODES.M)
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "initialize" -> {
        if (context == null) {
          result.error("context_is_null", "Context is null.", null)
          return
        }
        val key: MasterKey = MasterKey.Builder(context!!)
          .setKeyGenParameterSpec(
            KeyGenParameterSpec.Builder(MasterKey.DEFAULT_MASTER_KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
              .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
              .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
              .setKeySize(256)
              .build()
          )
          .build()
         preferences = EncryptedSharedPreferences.create(
          context!!,
          call.argument<String>("namespace") ?: "fr.skyost.simple_secure_storage",
          key,
          EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
          EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
        result.success(true)
      }
      "has" -> {
        if (!ensureInitialized(result)) {
          return
        }
        result.success(preferences!!.contains(call.argument("key")))
      }
      "read" -> {
        if (!ensureInitialized(result)) {
          return
        }
        result.success(preferences!!.getString(call.argument("key"), null))
      }
      "list" -> {
        if (!ensureInitialized(result)) {
          return
        }
        result.success(preferences!!.all)
      }
      "write" -> {
        if (!ensureInitialized(result)) {
          return
        }
        val editor = preferences!!.edit()
        editor.putString(call.argument("key"), call.argument("value"))
        result.success(editor.commit())
      }
      "delete" -> {
        if (!ensureInitialized(result)) {
          return
        }
        val editor = preferences!!.edit()
        editor.remove(call.argument("key"))
        result.success(editor.commit())
      }
      "clear" -> {
        if (!ensureInitialized(result)) {
          return
        }
        val editor = preferences!!.edit()
        editor.clear()
        result.success(editor.commit())
      }
      else -> result.notImplemented()
    }
  }

  /**
   * Ensures the plugin is initialized.
   *
   * @param result The result instance.
   *
   * @return Whether the plugin has been correctly initialized.
   */
  fun ensureInitialized(result: Result): Boolean {
    if (preferences == null) {
      result.error("preferences_is_null", "Preferences instance is null. Make sure you have initialized the plugin.", null)
      return false
    }
    return true
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    context = null
  }
}
