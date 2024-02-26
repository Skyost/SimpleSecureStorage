#include "simple_secure_storage_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <filesystem>
#include <fstream>
#include <nlohmann/json.hpp>

#include "utilities.h"

using namespace flutter;
using json = nlohmann::json;
namespace fs = std::filesystem;

namespace simple_secure_storage {

  // static
  void SimpleSecureStoragePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar
  ) {
    auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "fr.skyost.simple_secure_storage", &flutter::StandardMethodCodec::GetInstance()
      );

    auto plugin = std::make_unique<SimpleSecureStoragePlugin>();

    channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      }
    );

    registrar->AddPlugin(std::move(plugin));
  }

  SimpleSecureStoragePlugin::SimpleSecureStoragePlugin() {
    secureFileContent = json::object();
  }

  SimpleSecureStoragePlugin::~SimpleSecureStoragePlugin() {}

  void SimpleSecureStoragePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &methodCall,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
  ) {
    const auto &method = methodCall.method_name();
    const auto *arguments = std::get_if<EncodableMap>(methodCall.arguments());
    if (method.compare("initialize") == 0) {
      auto directoryName = arguments->find(EncodableValue("appName"));
      auto fileName = arguments->find(EncodableValue("namespace"));
      fs::path directoryPath =
        fs::path(getUserDataDirectory()) /
        fs::path(directoryName == arguments->end() ? L"Flutter" : toUtf16(std::get<std::string>(directoryName->second)));
      if (!fs::exists(directoryPath) || !fs::is_directory(directoryPath)) {
        fs::create_directory(directoryPath);
      }
      fs::path filePath = directoryPath /
                          fs::path(
                            (fileName == arguments->end()
                               ? L"fr.skyost.simple_secure_storage"
                               : toUtf16(std::get<std::string>(fileName->second))) +
                            L".dat"
                          );
      auto callResult = initialize(filePath.string());
      if (std::get<0>(callResult) == 0) {
        result->Success(flutter::EncodableValue(true));
      } else {
        result->Error("initialization_error", std::get<1>(callResult), std::get<0>(callResult));
      }
    } else if (method.compare("has") == 0) {
      if (!ensureInitialized(result)) {
        return;
      }
      auto key =
        std::get<std::string>(arguments->find(EncodableValue("key"))->second);
      result->Success(flutter::EncodableValue(has(key)));
    } else if (method.compare("list") == 0) {
      if (!ensureInitialized(result)) {
        return;
      }
      auto map = EncodableMap{};
      for (auto& [key, value] : secureFileContent.items()) {
        map.insert({EncodableValue(std::string(key)), EncodableValue(std::string(value))});
      }
      result->Success(EncodableValue(map));
    } else if (method.compare("read") == 0) {
      if (!ensureInitialized(result)) {
        return;
      }
      auto key =
        std::get<std::string>(arguments->find(EncodableValue("key"))->second);
      auto value = read(key);
      if (value.has_value()) {
        result->Success(flutter::EncodableValue(value.value()));
      } else {
        result->Success(flutter::EncodableValue());
      }
    } else if (method.compare("write") == 0) {
      if (!ensureInitialized(result)) {
        return;
      }
      auto key =
        std::get<std::string>(arguments->find(EncodableValue("key"))->second);
      auto value =
        std::get<std::string>(arguments->find(EncodableValue("value"))->second);
      auto callResult = write(key, value);
      if (std::get<0>(callResult) == 0) {
        result->Success(flutter::EncodableValue(true));
      } else {
        result->Error("initialization_error", std::get<1>(callResult), std::get<0>(callResult));
      }
    } else if (method.compare("delete") == 0) {
      if (!ensureInitialized(result)) {
        return;
      }
      auto key =
        std::get<std::string>(arguments->find(EncodableValue("key"))->second);
      auto callResult = remove(key);
      if (std::get<0>(callResult) == 0) {
        result->Success(flutter::EncodableValue(true));
      } else {
        result->Error("initialization_error", std::get<1>(callResult), std::get<0>(callResult));
      }
    } else if (method.compare("clear") == 0) {
      if (!ensureInitialized(result)) {
        return;
      }
      auto callResult = clear();
      if (std::get<0>(callResult) == 0) {
        result->Success(flutter::EncodableValue(true));
      } else {
        result->Error("initialization_error", std::get<1>(callResult), std::get<0>(callResult));
      }
    } else {
      result->NotImplemented();
    }
  }

  // Initializes the plugin and load the encrypted file content.
  std::tuple<int, std::string> SimpleSecureStoragePlugin::initialize(
    std::string filePath
  ) {
    secureFilePath = toUtf16(filePath);
    if (!fs::exists(filePath)) {
      return std::tuple<int, std::string>(0, "File doesn't exists.");
    }
    std::tuple<int, std::string> result = readEncryptedData(filePath);
    if (std::get<0>(result) != 0) {
      return result;
    }
    try {
      secureFileContent = json::parse(std::get<1>(result));
    } catch (json::parse_error& error) {
      (void)error;
      return std::tuple<int, std::string>(1, "JSON parse error.");
    }
    return std::tuple<int, std::string>(0, "Success.");
  }

  // Check if a key exists in the secure storage.
  bool SimpleSecureStoragePlugin::has(const std::string &key) const {
    return secureFileContent.contains(key);
  }

  // Retrieve the value associated with a key from the secure storage.
  std::optional<std::string> SimpleSecureStoragePlugin::read(const std::string &key) {
    return has(key) ? std::optional<std::string>(secureFileContent[key])
                    : std::optional<std::string>();
  }

  // Store a key-value pair in the secure storage.
  std::tuple<int, std::string> SimpleSecureStoragePlugin::write(
    const std::string &key, const std::string &value
  ) {
    secureFileContent[key] = value;
    return save();
  }

  // Remove a key-value pair from the secure storage.
  std::tuple<int, std::string> SimpleSecureStoragePlugin::remove(
    const std::string &key
  ) {
    secureFileContent.erase(key);
    return save();
  }

  // Clear all data from the secure storage.
  std::tuple<int, std::string> SimpleSecureStoragePlugin::clear() {
    secureFileContent = json::object();
    return save();
  }

  // Encrypts and save the content to the file.
  std::tuple<int, std::string> SimpleSecureStoragePlugin::save() const {
    if (secureFileContent.empty() && fs::exists(secureFilePath.value())) {
      fs::remove(secureFilePath.value());
      return std::tuple<int, std::string>(0, "Deleted with success.");
    }
    return writeEncryptedData(secureFilePath.value(), secureFileContent.dump());
  }

  // Ensures the plugin has been initialized.
  bool SimpleSecureStoragePlugin::ensureInitialized(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> &result
  ) {
    if (!secureFilePath.has_value()) {
      result->Error("file_is_null",
                    "The secure file path is null. Make sure you have "
                    "initialized the plugin.");
      return false;
    }
    return true;
  }

}  // namespace simple_secure_storage
