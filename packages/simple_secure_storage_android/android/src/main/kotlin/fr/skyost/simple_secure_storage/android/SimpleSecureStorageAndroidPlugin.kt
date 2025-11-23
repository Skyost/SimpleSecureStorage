package fr.skyost.simple_secure_storage.android

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.annotation.RequiresApi
import dev.spght.encryptedprefs.EncryptedSharedPreferences
import dev.spght.encryptedprefs.MasterKey
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors


/**
 * SimpleSecureStorage Android plugin.
 */
class SimpleSecureStorageAndroidPlugin : FlutterPlugin, MethodCallHandler {
    /**
     * The MethodChannel that will the communication between Flutter and native Android.
     *
     * This local reference serves to register the plugin with the Flutter Engine and unregister it
     * when the Flutter Engine is detached from the Activity.
     */
    private lateinit var channel: MethodChannel

    /**
     * The context instance.
     */
    private var context: Context? = null

    /**
     * The preferences instance.
     */
    private var preferences: SharedPreferences? = null

    /**
     * ExecutorService for background operations to prevent ANR with Flutter Thread Merge.
     */
    private val executorService: ExecutorService = Executors.newSingleThreadExecutor()

    /**
     * Handler for posting results back to the main thread.
     */
    private val mainHandler: Handler = Handler(Looper.getMainLooper())

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
                executeInBackground(result) {
                    val key = MasterKey.Builder(context!!)
                        .setKeyGenParameterSpec(
                            KeyGenParameterSpec.Builder(MasterKey.DEFAULT_MASTER_KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                                .setKeySize(256)
                                .build()
                        )
                        .build()
                    preferences = EncryptedSharedPreferences(
                        context!!,
                        call.argument<String>("namespace") ?: "fr.skyost.simple_secure_storage",
                        key,
                        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                    )
                    true
                }
            }

            "has" -> {
                if (!ensureInitialized(result)) {
                    return
                }
                executeInBackground(result) {
                    preferences!!.contains(call.argument("key"))
                }
            }

            "read" -> {
                if (!ensureInitialized(result)) {
                    return
                }
                executeInBackground(result) {
                    preferences!!.getString(call.argument("key"), null)
                }
            }

            "list" -> {
                if (!ensureInitialized(result)) {
                    return
                }
                executeInBackground(result) {
                    preferences!!.all
                }
            }

            "write" -> {
                if (!ensureInitialized(result)) {
                    return
                }
                executeInBackground(result) {
                    val editor = preferences!!.edit()
                    editor.putString(call.argument("key"), call.argument("value"))
                    editor.commit()
                }
            }

            "delete" -> {
                if (!ensureInitialized(result)) {
                    return
                }
                executeInBackground(result) {
                    val editor = preferences!!.edit()
                    editor.remove(call.argument("key"))
                    editor.commit()
                }
            }

            "clear" -> {
                if (!ensureInitialized(result)) {
                    return
                }
                executeInBackground(result) {
                    val editor = preferences!!.edit()
                    editor.clear()
                    editor.commit()
                }
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Executes an operation in a background thread to prevent ANR.
     * Results are posted back to the main thread.
     *
     * @param result The result instance to send back to Flutter.
     * @param operation The operation to execute in background.
     */
    private fun <T> executeInBackground(result: Result, operation: () -> T) {
        executorService.execute {
            try {
                val operationResult = operation()
                mainHandler.post {
                    result.success(operationResult)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("operation_failed", e.message, e.toString())
                }
            }
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
        executorService.shutdown()
    }
}
