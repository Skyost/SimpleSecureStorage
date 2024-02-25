#ifndef FLUTTER_PLUGIN_simple_secure_storage_PLUGIN_H_
#define FLUTTER_PLUGIN_simple_secure_storage_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <nlohmann/json.hpp>

#include <memory>

namespace simple_secure_storage {

class SimpleSecureStoragePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  SimpleSecureStoragePlugin();

  virtual ~SimpleSecureStoragePlugin();

  // Disallow copy and assign.
  SimpleSecureStoragePlugin(const SimpleSecureStoragePlugin&) = delete;
  SimpleSecureStoragePlugin& operator=(const SimpleSecureStoragePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

private:
  std::optional<std::wstring> secureFilePath;
  nlohmann::json secureFileContent;

  std::tuple<int, std::string> initialize(std::string filePath);
  bool has(const std::string &key) const;
  std::optional<std::string> read(const std::string &key);
  std::tuple<int, std::string> write(const std::string &key,
                                     const std::string &value);
  std::tuple<int, std::string> remove(const std::string &key);
  std::tuple<int, std::string> clear();
  std::tuple<int, std::string> save() const;
  bool ensureInitialized(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> &result);
};

}  // namespace simple_secure_storage

#endif  // FLUTTER_PLUGIN_simple_secure_storage_PLUGIN_H_
