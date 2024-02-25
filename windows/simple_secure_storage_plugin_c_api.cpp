#include "include/simple_secure_storage/simple_secure_storage_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "simple_secure_storage_plugin.h"

void SimpleSecureStoragePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  simple_secure_storage::SimpleSecureStoragePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
