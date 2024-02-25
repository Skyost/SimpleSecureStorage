#include <string>

namespace simple_secure_storage {
  std::wstring toUtf16(const std::string string);

  std::string toUtf8(const std::wstring wide_string);

  std::wstring getUserDataDirectory();

  std::tuple<int, std::string> readEncryptedData(std::string path);

  std::tuple<int, std::string> writeEncryptedData(std::wstring path,
                                                  std::string content);
  }  // namespace bonsoir_windows