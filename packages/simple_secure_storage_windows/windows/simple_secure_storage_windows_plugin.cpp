#include "simple_secure_storage_windows_plugin.h"

#include <flutter/standard_method_codec.h>

#include <filesystem>
#include <fstream>

#include "utilities.h"

using namespace flutter;
namespace fs = std::filesystem;

namespace simple_secure_storage {

  // static
  void SimpleSecureStorageWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar
  ) {
    auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "fr.skyost.simple_secure_storage", &flutter::StandardMethodCodec::GetInstance()
      );

    auto plugin = std::make_unique<SimpleSecureStorageWindowsPlugin>();

    channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      }
    );

    registrar->AddPlugin(std::move(plugin));
  }

  SimpleSecureStorageWindowsPlugin::SimpleSecureStorageWindowsPlugin() {}

  SimpleSecureStorageWindowsPlugin::~SimpleSecureStorageWindowsPlugin() {}

  void SimpleSecureStorageWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &methodCall,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
  ) {
    const auto &method = methodCall.method_name();
    const auto *arguments = std::get_if<EncodableMap>(methodCall.arguments());
    if (method.compare("initialize") == 0) {
      auto _appNamespace = std::get<std::string>(arguments->find(EncodableValue("namespace"))->second);
      initialize(_appNamespace);
      result->Success(flutter::EncodableValue(true));
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
      auto map = list();
      auto encodableMap = EncodableMap{};
      for (auto &[key, value] : map) {
        encodableMap.insert({EncodableValue(std::string(key)), EncodableValue(std::string(value))});
      }
      result->Success(EncodableValue(encodableMap));
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
        result->Error("write_error", std::get<1>(callResult), std::get<0>(callResult));
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
        result->Error("delete_error", std::get<1>(callResult), std::get<0>(callResult));
      }
    } else if (method.compare("clear") == 0) {
      if (!ensureInitialized(result)) {
        return;
      }
      auto callResult = clear();
      if (std::get<0>(callResult) == 0) {
        result->Success(flutter::EncodableValue(true));
      } else {
        result->Error("clear_error", std::get<1>(callResult), std::get<0>(callResult));
      }
    } else {
      result->NotImplemented();
    }
  }

  // Initializes the plugin .
  void SimpleSecureStorageWindowsPlugin::initialize(std::string _appNamespace) {
    this->appNamespace = _appNamespace;
  }

  // Check if a key exists in the secure storage.
  bool SimpleSecureStorageWindowsPlugin::has(const std::string &key) {
    return read(key).has_value();
  }

  // Retrieve the value associated with a key from the secure storage.
  std::optional<std::string> SimpleSecureStorageWindowsPlugin::read(const std::string &key) {
    std::wstring targetName = getTargetName(key);
    PCREDENTIAL credential;
    BOOL result = CredRead(targetName.c_str(), CRED_TYPE_GENERIC, 0, &credential);
    if (!result) {
      auto test = getReturnTuple(result);
      return std::optional<std::string>();
    }
    std::string value = std::string((char*)credential->CredentialBlob);
    CredFree(credential);
    return value;
  }

  // Lists all key / value pairs.
  std::map<std::string, std::string> SimpleSecureStorageWindowsPlugin::list() {
    std::wstring targetName = getTargetName("*");
    DWORD count;
    PCREDENTIAL *credentials;
    BOOL result = CredEnumerate(targetName.c_str(), 0, &count, &credentials);
    std::map<std::string, std::string> map = std::map<std::string, std::string>();
    if (!result) {
      return map;
    }
    for (DWORD i = 0; i < count; ++i) {
      auto credential = credentials[i];
      std::string key = toUtf8(credential->UserName);
      std::string value = std::string((char *)credential->CredentialBlob);
      map[key] = value;
    }
    CredFree(credentials);
    return map;
  }

  // Store a key-value pair in the secure storage.
  std::tuple<int, std::string> SimpleSecureStorageWindowsPlugin::write(
    const std::string &key, const std::string &value
  ) {
    auto targetName = getTargetName(key);
    auto userName = toUtf16(key);

    auto credentialValue = value.c_str();

    CREDENTIAL credential = {};
    credential.Flags = 0;
    credential.Type = CRED_TYPE_GENERIC;
    credential.TargetName = (LPWSTR)targetName.c_str();
    credential.UserName = (LPWSTR)userName.c_str();
    credential.CredentialBlobSize = (DWORD)(1 + strlen(credentialValue));
    credential.CredentialBlob = (LPBYTE)credentialValue;
    credential.Persist = CRED_PERSIST_LOCAL_MACHINE;

    BOOL result = CredWrite(&credential, 0);
    return getReturnTuple(result);
  }

  // Remove a key-value pair from the secure storage.
  std::tuple<int, std::string> SimpleSecureStorageWindowsPlugin::remove(
    const std::string &key
  ) {
    std::wstring targetName = getTargetName(key);
    BOOL result = CredDelete(targetName.c_str(), CRED_TYPE_GENERIC, 0);
    return getReturnTuple(result);
  }

  // Clear all data from the secure storage.
  std::tuple<int, std::string> SimpleSecureStorageWindowsPlugin::clear() {
    std::wstring targetName = getTargetName("*");
    DWORD count;
    PCREDENTIAL *credentials;
    BOOL result = CredEnumerate(targetName.c_str(), 0, &count, &credentials);
    if (!result) {
      return getReturnTuple(result);
    }
    for (DWORD i = 0; i < count; ++i) {
      auto credential = credentials[i];
      result = CredDelete(credential->TargetName, credential->Type, 0);
      if (!result) {
        return getReturnTuple(result);
      }
    }
    CredFree(credentials);
    return getReturnTuple(result);
  }

  // Returns the target name associated with the specified key.
  std::wstring SimpleSecureStorageWindowsPlugin::getTargetName(const std::string &key) {
    return toUtf16(appNamespace.value() + "_" + key);
  }

  // Allows to unify the return object between methods.
  std::tuple<int, std::string> SimpleSecureStorageWindowsPlugin::getReturnTuple(bool result) {
    if (result) {
      return std::tuple<int, std::string>(0, "Success.");
    } else {
      DWORD error = GetLastError();
      if (error == ERROR_NOT_FOUND) {
        return std::tuple<int, std::string>(0, "Operation done with success since the specified key has not been found.");
      }
      LPWSTR errorMessageBuffer = nullptr;
      FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, nullptr, error, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPWSTR)&errorMessageBuffer, 0, nullptr);
      if (errorMessageBuffer != nullptr) {
        std::string errorMessage = toUtf8(std::wstring(errorMessageBuffer));
        LocalFree(errorMessageBuffer);
        return std::tuple<int, std::string>(error, errorMessage);
      }
      return std::tuple<int, std::string>(error, "An error occured.");
    }
  }

  // Ensures the plugin has been initialized.
  bool SimpleSecureStorageWindowsPlugin::ensureInitialized(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> & result) {
    if (!appNamespace.has_value()) {
      result->Error("namespace_is_null", "Please make sure you have initialized the plugin.");
      return false;
    }
    return true;
  }

}  // namespace simple_secure_storage
