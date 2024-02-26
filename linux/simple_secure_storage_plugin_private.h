#include <flutter_linux/flutter_linux.h>

#include "include/simple_secure_storage/simple_secure_storage_plugin.h"
#include "include/f_hash_table.hpp"

#include <nlohmann/json.hpp>

// This file exposes some plugin internals for unit testing. See
// https://github.com/flutter/flutter/issues/88724 for current limitations
// in the unit-testable API.

FHashTable attributes;
SecretSchema schema;
static nlohmann::json secureFileContent;
gchar *label;

std::tuple<bool, std::string> initialize(const gchar *label);
bool has(const gchar *key);
tl::optional<string> read(const gchar *key);
std::tuple<bool, std::string> write(const gchar *key, const gchar *value);
std::tuple<bool, std::string> del(const gchar *key);
std::tuple<bool, std::string> clear();
std::tuple<bool, std::string> save();
std::tuple<bool, std::string> warmupKeyring();
