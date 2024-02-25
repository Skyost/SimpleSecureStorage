//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <simple_secure_storage/simple_secure_storage_linux.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) simple_secure_storage_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SimpleSecureStorageLinux");
  simple_secure_storage_linux_register_with_registrar(simple_secure_storage_registrar);
}
