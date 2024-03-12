#ifndef FLUTTER_PLUGIN_SIMPLE_SECURE_STORAGE_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_SIMPLE_SECURE_STORAGE_WINDOWS_PLUGIN_H_

// This must be included before many other Windows headers.
#include <windows.h>
#include <wincred.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace simple_secure_storage {
  static const std::wstring APP_ATTRIBUTE_NAME = L"app";

  class SimpleSecureStorageWindowsPlugin : public flutter::Plugin {
   public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

    SimpleSecureStorageWindowsPlugin();

    virtual ~SimpleSecureStorageWindowsPlugin();

    // Disallow copy and assign.
    SimpleSecureStorageWindowsPlugin(const SimpleSecureStorageWindowsPlugin &) = delete;
    SimpleSecureStorageWindowsPlugin &operator=(const SimpleSecureStorageWindowsPlugin &) = delete;

    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
    );

   private:
    std::optional<std::string> appNamespace;
    void initialize(std::string appNamespace);
    bool has(const std::string &key);
    std::optional<std::string> read(const std::string &key);
    std::map<std::string, std::string> list();
    std::tuple<int, std::string> write(const std::string &key, const std::string &value);
    std::tuple<int, std::string> remove(const std::string &key);
    std::tuple<int, std::string> clear();
    std::wstring getTargetName(const std::string &key);
    std::tuple<int, std::string> getReturnTuple(bool result);
    bool ensureInitialized(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> &result);
  };

}  // namespace simple_secure_storage

#endif  // FLUTTER_PLUGIN_SIMPLE_SECURE_STORAGE_WINDOWS_PLUGIN_H_
