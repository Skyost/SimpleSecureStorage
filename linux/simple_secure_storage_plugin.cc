#include "include/simple_secure_storage/simple_secure_storage_plugin.h"
#include "include/tl/optional.hpp"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <libsecret/secret.h>
#include <sys/utsname.h>

#include <cstring>
#include <nlohmann/json.hpp>

#include "simple_secure_storage_plugin_private.h"

#define simple_secure_storage_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), simple_secure_storage_plugin_get_type(), SimpleSecureStoragePlugin))

struct _SimpleSecureStoragePlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(SimpleSecureStoragePlugin, simple_secure_storage_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void simple_secure_storage_plugin_handle_method_call(
  SimpleSecureStoragePlugin* self,
  FlMethodCall* methodCall
) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(methodCall);
  FlValue* arguments = fl_method_call_get_args(methodCall);

  FlValue* key = fl_value_lookup_string(arguments, "key");
  const gchar* keyString = key == nullptr ? nullptr : fl_value_get_string(key);

  if (strcmp(method, "initialize") == 0) {
    FlValue* name = fl_value_lookup_string(arguments, "appName");
    const gchar* nameString = "Simple Secure Storage";
    if (name == nullptr) {
      name = fl_value_lookup_string(arguments, "namespace");
    }
    if (name != nullptr) {
      nameString == fl_value_get_string(name);
    }

    auto callResult = initialize(nameString);
    if (std::get<0>(callResult)) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("initialization_error", std::get<1>(callResult)));
    }
  } else if (strcmp(method, "has") == 0) {
    if (!ensureInitialized(methodCall)) {
      return;
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(has(keyString))));
  } else if (strcmp(method, "read") == 0) {
    if (!ensureInitialized(methodCall)) {
      return;
    }
    auto value = read(keyString);
    if (value.has_value()) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(value.c_str())));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
  } else if (strcmp(method, "write") == 0) {
    if (!ensureInitialized(methodCall)) {
      return;
    }
    FlValue* value = fl_value_lookup_string(arguments, "value");
    const gchar* valueString = value == nullptr ? nullptr : fl_value_get_string(value);
    auto callResult = write(keyString, valueString);
    if (std::get<0>(callResult)) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("write_error", std::get<1>(callResult)));
    }
  } else if (strcmp(method, "delete") == 0) {
    if (!ensureInitialized(methodCall)) {
      return;
    }
    auto callResult = del(keyString);
    if (std::get<0>(callResult)) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("delete_error", std::get<1>(callResult)));
    }
  } else if (strcmp(method, "clear") == 0) {
    if (!ensureInitialized(methodCall)) {
      return;
    }
    auto callResult = clear();
    if (std::get<0>(callResult)) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("clear_error", std::get<1>(callResult)));
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(methodCall, response, nullptr);
}

// Initializes the plugin and load the encrypted file content.
std::tuple<bool, std::string> initialize(const gchar* name) {
  g_autoptr(GError) error = nullptr;

  std::tuple<bool, std::string> warmupResult = warmupKeyring();
  if (!std::get<0>(warmupResult)) {
    return warmupResult;
  }

  secret_autofree gchar* result = secret_password_lookupv_sync(
    &schema, attributes.getGHashTable(), nullptr, &error
  );

  if (error) {
    return std::tuple<bool, std::string>(false, error->message);
  }
  if (result != NULL && strcmp(result, "") != 0) {
    nlohmann::json json = nlohmann::json::parse(result, nullptr, false);
    if (json.is_discarded()) {
      std::tuple<bool, std::string>(false, "Parse failed.");
    }
    secureFileContent = json;
  }
  label = name;
  return std::tuple<bool, std::string>(true, "Success.");
}

// Check if a key exists in the secure storage.
bool has(const gchar* key) {
  return secureFileContent.contains(key);
}

// Retrieve the value associated with a key from the secure storage.
tl::optional<string> read(const gchar* key) {
  return has(key) ? tl::optional<std::string>(secureFileContent[key])
                  : tl::optional<std::string>();
}

// Store a key-value pair in the secure storage.
std::tuple<bool, std::string> write(const gchar* key, const gchar* value) {
  secureFileContent[key] = value;
  return save();
}

// Remove a key-value pair from the secure storage.
std::tuple<bool, std::string> del(const gchar* key) {
  secureFileContent.erase(key);
  return save();
}

// Clear all data from the secure storage.
std::tuple<bool, std::string> clear() {
  secureFileContent = json::object();
  return save();
}

// Save the content to the keyring.
std::tuple<bool, std::string> save() {
  std::tuple<bool, std::string> warmupResult = warmupKeyring();
  if (!std::get<0>(warmupResult)) {
    return warmupResult;
  }

  const std::string output = secureFileContent.dump();
  g_autoptr(GError) error = nullptr;
  bool result = secret_password_storev_sync(
    &schema, attributes.getGHashTable(), nullptr, label.c_str(), output.c_str(), nullptr, &error
  );

  if (error) {
    return std::tuple<bool, std::string>(false, "Unable to save to keyring.");
  }

  return std::tuple<bool, std::string>(true, "Success.");
}

// Ensures the plugin has been initialized.
bool ensureInitialized(
  FlMethodCall* methodCall
) {
  if (label == nullptr) {
    fl_method_call_respond(methodCall, FL_METHOD_RESPONSE(fl_method_error_response_new("not_initialized", "Please make sure you have initialized the plugin.")), nullptr);
    return false;
  }
  return true;
}

// Search with schemas fails in cold keyrings.
// https://gitlab.gnome.org/GNOME/gnome-keyring/-/issues/89
//
// Note that we're not using the workaround mentioned in the above issue. Instead, we're using
// a workaround as implemented in http://crbug.com/660005. Reason being that with the lookup
// approach we can't distinguish whether the keyring was actually unlocked or whether the user
// cancelled the password prompt.
std::tuple<bool, std::string> warmupKeyring() {
  g_autoptr(GError) error = nullptr;

  FHashTable attributes;
  attributes.insert("explanation",
                    "Because of quirks in the gnome libsecret API, "
                    "flutter_secret_storage needs to store a dummy entry to guarantee that "
                    "this keyring was properly unlocked. More details at http://crbug.com/660005.");

  const gchar* dummy_label = "FlutterSecureStorage Control";

  // Store a dummy entry without `schema`.
  bool success = secret_password_storev_sync(
    NULL, attributes.getGHashTable(), nullptr, dummy_label, "The meaning of life", nullptr, &error
  );

  return std::tuple<bool, std::string>(success, success ? "Success." : "Failed to unlock the keyring.")
}

static void simple_secure_storage_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(simple_secure_storage_plugin_parent_class)->dispose(object);
}

static void simple_secure_storage_plugin_class_init(SimpleSecureStoragePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = simple_secure_storage_plugin_dispose;
}

static void simple_secure_storage_plugin_init(SimpleSecureStoragePlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  SimpleSecureStoragePlugin* plugin = simple_secure_storage_PLUGIN(user_data);
  simple_secure_storage_plugin_handle_method_call(plugin, method_call);
}

void simple_secure_storage_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  SimpleSecureStoragePlugin* plugin = simple_secure_storage_PLUGIN(
    g_object_new(simple_secure_storage_plugin_get_type(), nullptr)
  );

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
    fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar), "fr.skyost.simple_secure_storage", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
