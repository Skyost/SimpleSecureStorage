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
}  // namespace simple_secure_storage