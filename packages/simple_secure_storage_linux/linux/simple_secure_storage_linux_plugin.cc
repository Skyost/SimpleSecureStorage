#include "include/simple_secure_storage_linux/simple_secure_storage_linux_plugin.h"
#include "include/tl/optional.hpp"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <libsecret/secret.h>
#include <sys/utsname.h>
#include <iostream>

#include <cstring>

#include "simple_secure_storage_linux_plugin_private.h"

#define simple_secure_storage_linux_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), simple_secure_storage_linux_plugin_get_type(), SimpleSecureStorageLinuxPlugin))

struct _SimpleSecureStorageLinuxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(SimpleSecureStorageLinuxPlugin, simple_secure_storage_linux_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void simple_secure_storage_linux_plugin_handle_method_call(
  SimpleSecureStorageLinuxPlugin* self,
  FlMethodCall* methodCall
) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(methodCall);
  FlValue* arguments = fl_method_call_get_args(methodCall);

  if (strcmp(method, "initialize") == 0) {
    FlValue* name = fl_value_lookup_string(arguments, "appName");
    const gchar* nameString = "Simple Secure Storage";
    if (name == nullptr) {
      name = fl_value_lookup_string(arguments, "namespace");
    }
    if (name != nullptr) {
      nameString = fl_value_get_string(name);
    }

    auto callResult = initialize(nameString);
    if (std::get<0>(callResult)) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("initialization_error", std::get<1>(callResult).c_str(), nullptr));
    }
  } else if (strcmp(method, "has") == 0) {
    auto callResult = ensureInitialized();
    if (std::get<0>(callResult)) {
      FlValue* key = fl_value_lookup_string(arguments, "key");
      std::string keyString (fl_value_get_string(key));
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(has(keyString))));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("not_initialized", std::get<1>(callResult).c_str(), nullptr));
    }
  } else if (strcmp(method, "read") == 0) {
    auto callResult = ensureInitialized();
    if (!std::get<0>(callResult)) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("not_initialized", std::get<1>(callResult).c_str(), nullptr));
    } else {
      FlValue* key = fl_value_lookup_string(arguments, "key");
      std::string keyString (fl_value_get_string(key));
      auto value = read(keyString);
      if (value.has_value()) {
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(value.value().c_str())));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
      }
    }
  } else if (strcmp(method, "list") == 0) {
    auto callResult = ensureInitialized();
    if (std::get<0>(callResult)) {
      auto map = fl_value_new_map();
      for (auto& element : secureFileContent.items()) {
        fl_value_set_string_take(map, std::string(element.key()).c_str(), fl_value_new_string(std::string(element.value()).c_str()));
      }
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(map));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("not_initialized", std::get<1>(callResult).c_str(), nullptr));
    }
  } else if (strcmp(method, "write") == 0) {
    auto callResult = ensureInitialized();
    if (std::get<0>(callResult)) {
      FlValue* key = fl_value_lookup_string(arguments, "key");
      std::string keyString (fl_value_get_string(key));
      FlValue* value = fl_value_lookup_string(arguments, "value");
      std::string valueString (fl_value_get_string(value));
      callResult = write(keyString, valueString);
    }
    if (std::get<0>(callResult)) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("write_error", std::get<1>(callResult).c_str(), nullptr));
    }
  } else if (strcmp(method, "delete") == 0) {
    auto callResult = ensureInitialized();
    if (std::get<0>(callResult)) {
      FlValue* key = fl_value_lookup_string(arguments, "key");
      std::string keyString (fl_value_get_string(key));
      callResult = del(keyString);
    }
    if (std::get<0>(callResult)) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("delete_error", std::get<1>(callResult).c_str(), nullptr));
    }
  } else if (strcmp(method, "clear") == 0) {
    auto callResult = ensureInitialized();
    if (std::get<0>(callResult)) {
      callResult = clear();
    }
    if (std::get<0>(callResult)) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new("clear_error", std::get<1>(callResult).c_str(), nullptr));
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(methodCall, response, nullptr);
}

// Initializes the plugin and load the encrypted file content.
std::tuple<bool, std::string> initialize(const gchar* name) {
  GError* error = NULL;

  std::tuple<bool, std::string> warmupResult = warmupKeyring(name);
  if (!std::get<0>(warmupResult)) {
    return warmupResult;
  }

  initialized = true;
  return std::tuple<bool, std::string>(true, "Success.");
}

// Check if a key exists in the secure storage.
bool has(std::string key) {
  return read(key).has_value();
}

// Retrieve the value associated with a key from the secure storage.
tl::optional<std::string> read(std::string key) {
  GError* error = NULL;
  gchar* value = secret_password_lookup_sync(SECRET_SCHEMA, SECRET_COLLECTION_DEFAULT, &error, "key", key, NULL);
  if (error != NULL) {
    std::cerr << (error->message);
    g_error_free(error);
  }
  tl::optional<std::string> result == NULL ? tl::optional<std::string>() : td::optional<std::string>(std::string(value));
  secret_password_free(value);
  return result;
}

// Store a key-value pair in the secure storage.
std::tuple<bool, std::string> write(std::string key, std::string value) {
  GError* error = NULL;
  secret_password_store_sync(SECRET_SCHEMA, SECRET_COLLECTION_DEFAULT, key.c_str(), value.c_str(), &error, "key", key, NULL);
  return getReturnValue(error);
}

// Remove a key-value pair from the secure storage.
std::tuple<bool, std::string> del(std::string key) {
  GError* error = NULL;
  secret_password_clear_sync(SECRET_SCHEMA, NULL, &error, "key", key, NULL);
  return getReturnValue(error);
}

// Clear all data from the secure storage.
std::tuple<bool, std::string> clear() {
  GError* error = NULL;
  secret_password_clear_sync(SECRET_SCHEMA, NULL, &error, NULL);
  return getReturnValue(error);
}

// Ensures the plugin has been initialized.
std::tuple<bool, std::string> ensureInitialized() {
  if (initialized) {
    return std::tuple<bool, std::string>(true, "Correctly initialized.");
  }
  return std::tuple<bool, std::string>(false, "Please make sure you have initialized the plugin.");
}

// Search with schemas fails in cold keyrings.
// https://gitlab.gnome.org/GNOME/gnome-keyring/-/issues/89
//
// Note that we're not using the workaround mentioned in the above issue. Instead, we're using
// a workaround as implemented in http://crbug.com/660005. Reason being that with the lookup
// approach we can't distinguish whether the keyring was actually unlocked or whether the user
// cancelled the password prompt.
//
// Kudos to FlutterSecureStorage for this one.
std::tuple<bool, std::string> warmupKeyring(const gchar* name) {
  GError* error = nullptr;

  // Store a dummy entry without `schema`.
  bool success = secret_password_storev_sync(
    NULL,
    "explanation",
    "Because of quirks in the gnome libsecret API, "
    "SimpleSecureStorage needs to store a dummy entry to guarantee that "
    "this keyring was properly unlocked. More details at http://crbug.com/660005.",
    NULL,
    name + " Control",
    "The meaning of life.",
    NULL,
    &error
  );

  return getReturnValue(error);
}

// Returns the return value associated to the given error pointer.
std::tuple<bool, std::string> getReturnValue(GError* error) {
  if (error != NULL) {
    std::string message = error->message;
    g_error_free(error);
    return std::tuple<bool, std::string>(false, message);
  }
  return std::tuple<bool, std::string>(true, "Success.");
}

static void simple_secure_storage_linux_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(simple_secure_storage_linux_plugin_parent_class)->dispose(object);
}

static void simple_secure_storage_linux_plugin_class_init(SimpleSecureStorageLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = simple_secure_storage_linux_plugin_dispose;
}

static void simple_secure_storage_linux_plugin_init(SimpleSecureStorageLinuxPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  SimpleSecureStorageLinuxPlugin* plugin = simple_secure_storage_linux_PLUGIN(user_data);
  simple_secure_storage_linux_plugin_handle_method_call(plugin, method_call);
}

void simple_secure_storage_linux_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  SimpleSecureStorageLinuxPlugin* plugin = simple_secure_storage_linux_PLUGIN(
    g_object_new(simple_secure_storage_linux_plugin_get_type(), nullptr)
  );

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
    fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar), "fr.skyost.simple_secure_storage", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
