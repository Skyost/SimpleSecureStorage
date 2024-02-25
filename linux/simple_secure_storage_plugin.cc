#include "include/simple_secure_storage/simple_secure_storage_plugin.h"
#include "include/secret.hpp"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <libsecret/secret.h>
#include <sys/utsname.h>

#include <cstring>

#include <nlohmann/json.hpp>

#include "simple_secure_storage_plugin_private.h"

#define simple_secure_storage_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), simple_secure_storage_plugin_get_type(), \
                              SimpleSecureStoragePlugin))

struct _SimpleSecureStoragePlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(SimpleSecureStoragePlugin, simple_secure_storage_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void simple_secure_storage_plugin_handle_method_call(
    SimpleSecureStoragePlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue *arguments = fl_method_call_get_args(method_call);

  FlValue *key = fl_value_lookup_string(arguments, "key");
  const gchar *keyString = key == nullptr ? nullptr : fl_value_get_string(key);

  if (strcmp(method, "initialize") == 0) {
    FlValue *name = fl_value_lookup_string(arguments, "namespace");
    const gchar *nameString = name == nullptr ? "fr.skyost.simple_secure_storage" : fl_value_get_string(name);
    keyring = SecretStorage(nameString);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
  } else if (strcmp(method, "has") == 0) {
    g_autoptr(FlValue) result = has(keyString);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "read") == 0) {
    g_autoptr(FlValue) result = read(keyString);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "write") == 0) {
    FlValue *value = fl_value_lookup_string(arguments, "value");
    const gchar *valueString = value == nullptr ? nullptr : fl_value_get_string(value);
    write(keyString, valueString);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
  } else if (strcmp(method, "delete") == 0) {
    del(keyString);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
  } else if (strcmp(method, "clear") == 0) {
    clear();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(true)));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlValue* has(const gchar* key) {
  nlohmann::json data = keyring.readFromKeyring();
  return fl_value_new_bool(data.contains(key));
}

FlValue *read(const gchar *key)
{
  auto value = keyring.getItem(key);
  return value.has_value() ? fl_value_new_string(value.value().c_str()) : nullptr;
}

void write(const gchar *key, const gchar *value)
{
  keyring.addItem(key, value);
}

void del(const gchar *key)
{
  keyring.deleteItem(key);
}

void clear()
{ 
  keyring.deleteKeyring();
}

static void simple_secure_storage_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(simple_secure_storage_plugin_parent_class)->dispose(object);
}

static void simple_secure_storage_plugin_class_init(SimpleSecureStoragePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = simple_secure_storage_plugin_dispose;
}

static void simple_secure_storage_plugin_init(SimpleSecureStoragePlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  SimpleSecureStoragePlugin* plugin = simple_secure_storage_PLUGIN(user_data);
  simple_secure_storage_plugin_handle_method_call(plugin, method_call);
}

void simple_secure_storage_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  SimpleSecureStoragePlugin* plugin = simple_secure_storage_PLUGIN(
      g_object_new(simple_secure_storage_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "fr.skyost.simple_secure_storage",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
