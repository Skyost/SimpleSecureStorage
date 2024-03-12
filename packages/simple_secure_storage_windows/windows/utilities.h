#include <string>

namespace simple_secure_storage {
  std::wstring toUtf16(const std::string string);

  std::string toUtf8(const std::wstring wide_string);
}  // namespace simple_secure_storage