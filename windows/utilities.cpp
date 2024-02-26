#include "utilities.h"

#include <windows.h>
#include <dpapi.h>
#include <shlobj.h>

#include <fstream>
#include <stdexcept>
#include <vector>

namespace simple_secure_storage {
  std::wstring toUtf16(const std::string string) {
    // see https://stackoverflow.com/a/69410299/8707976

    if (string.empty()) {
      return L"";
    }

    auto sizeNeeded = MultiByteToWideChar(CP_UTF8, 0, &string.at(0), (int)string.size(), nullptr, 0);
    if (sizeNeeded <= 0) {
      throw std::runtime_error("MultiByteToWideChar() failed: " + std::to_string(sizeNeeded));
      // see
      // https://docs.microsoft.com/en-us/windows/win32/api/stringapiset/nf-stringapiset-multibytetowidechar
      // for error codes
    }

    std::wstring result(sizeNeeded, 0);
    MultiByteToWideChar(CP_UTF8, 0, &string.at(0), (int)string.size(), &result.at(0), sizeNeeded);
    return result;
  }

  std::string toUtf8(const std::wstring wide_string) {
    // see https://stackoverflow.com/a/69410299/8707976

    if (wide_string.empty()) {
      return "";
    }

    auto sizeNeeded = WideCharToMultiByte(CP_UTF8, 0, &wide_string.at(0), (int)wide_string.size(), nullptr, 0, nullptr, nullptr);
    if (sizeNeeded <= 0) {
      throw std::runtime_error("WideCharToMultiByte() failed: " + std::to_string(sizeNeeded));
      // see
      // https://docs.microsoft.com/en-us/windows/win32/api/stringapiset/nf-stringapiset-multibytetowidechar
      // for error codes
    }

    std::string result(sizeNeeded, 0);
    WideCharToMultiByte(CP_UTF8, 0, &wide_string.at(0), (int)wide_string.size(), &result.at(0), sizeNeeded, nullptr, nullptr);
    return result;
  }

  // Get the path to the user's data directory
  std::wstring getUserDataDirectory() {
    wchar_t* userDataDir;
    if (SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, NULL, &userDataDir) != S_OK) {
      return L"";
    }
    std::wstring userDataDirectory(userDataDir);
    CoTaskMemFree(static_cast<void*>(userDataDir));
    return userDataDirectory;
  }

  // Reads encrypted data from the given path.
  std::tuple<int, std::string> readEncryptedData(std::string path) {
    std::ifstream decryptFile(path, std::ios::binary);
    if (decryptFile.is_open()) {
      DATA_BLOB encryptedData, dataVerify;

      if (!decryptFile.read(reinterpret_cast<char*>(&encryptedData.cbData), sizeof(encryptedData.cbData))) {
        return std::tuple<int, std::string>(1, "Failed to read encrypted file.");
      }

      std::vector<BYTE> buffer(encryptedData.cbData);
      encryptedData.pbData = buffer.data();

      if (!decryptFile.read(reinterpret_cast<char*>(encryptedData.pbData), encryptedData.cbData)) {
        return std::tuple<int, std::string>(1, "Failed to decrypt file.");
      }

      if (!CryptUnprotectData(&encryptedData, nullptr,
                              nullptr,  // Optional entropy
                              nullptr,  // Reserved
                              nullptr,  // Optional PromptStruct
                              CRYPTPROTECT_LOCAL_MACHINE,
                              &dataVerify)) {
        DWORD errCode = GetLastError();
        return std::tuple<int, std::string>(errCode, "Failed to read encrypted file.");
      }

      std::string decryptedString(
        reinterpret_cast<const char*>(dataVerify.pbData), dataVerify.cbData
      );

      LocalFree(dataVerify.pbData);
      decryptFile.close();
      return std::tuple<int, std::string>(0, decryptedString);
    }

    return std::tuple<int, std::string>(1, "Failed to open encrypted file.");
  }

  // Encrypts and save the content to the given path.
  std::tuple<int, std::string> writeEncryptedData(std::wstring path, std::string content) {
    std::ofstream encryptedfile(path, std::ios::binary);
    if (encryptedfile.is_open()) {
      DATA_BLOB datain, dataout;

      datain.pbData =
        reinterpret_cast<BYTE*>(const_cast<char*>(content.c_str()));
      datain.cbData = (DWORD)(content.size() + 1);

      if (!CryptProtectData(&datain,
                            nullptr,  // a description string.
                            nullptr,  // optional entropy not used.
                            nullptr,  // reserved.
                            nullptr,  // pass a promptstruct.
                            CRYPTPROTECT_LOCAL_MACHINE,
                            &dataout)) {
        DWORD errcode = GetLastError();
        return std::tuple<int, std::string>(errcode, "Failed to encrypt data.");
      }

      if (!(encryptedfile.write(reinterpret_cast<char*>(&dataout.cbData), sizeof(dataout.cbData)) &&
            encryptedfile.write(reinterpret_cast<char*>(dataout.pbData), dataout.cbData))) {
        return std::tuple<int, std::string>(1, "Failed to write encrypted data.");
      }

      encryptedfile.close();
      return std::tuple<int, std::string>(0, "Success.");
    }
    return std::tuple<int, std::string>(1, "Failed to open file for writing.");
  }

}  // namespace simple_secure_storage