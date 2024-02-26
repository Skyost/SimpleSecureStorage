#include <flutter_linux/flutter_linux.h>

#include "include/simple_secure_storage/simple_secure_storage_plugin.h"
#include "include/f_hash_table.hpp"

#include <nlohmann/json.hpp>

#define secret_autofree _GLIB_CLEANUP(secret_cleanup_free)
static inline void secret_cleanup_free(gchar **p) { secret_password_free(*p); }

FHashTable attributes;
SecretSchema schema;
static nlohmann::json secureFileContent;
const gchar *label;

std::tuple<bool, std::string> initialize(const gchar *label);
bool has(std::string key);
tl::optional<std::string> read(std::string key);
std::tuple<bool, std::string> write(std::string key, std::string value);
std::tuple<bool, std::string> del(std::string key);
std::tuple<bool, std::string> clear();
std::tuple<bool, std::string> save();
std::tuple<bool, std::string> ensureInitialized();
std::tuple<bool, std::string> warmupKeyring();
