#include "include/simple_secure_storage_windows/simple_secure_storage_windows_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "simple_secure_storage_windows_plugin.h"

void SimpleSecureStorageWindowsPluginCApiRegisterWithRegistrar(
  FlutterDesktopPluginRegistrarRef registrar
) {
  simple_secure_storage::SimpleSecureStorageWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarManager::GetInstance()
      ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar)
  );
}
