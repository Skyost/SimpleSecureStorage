#include <flutter_linux/flutter_linux.h>

#include "include/simple_secure_storage_linux/simple_secure_storage_linux_plugin.h"

bool initialized;
SecretSchema secretSchema;

std::tuple<bool, std::string> initialize(const gchar *name);
bool has(std::string key);
tl::optional<std::string> read(std::string key);
std::map<std::string, std::string> list();
std::tuple<bool, std::string> write(std::string key, std::string value);
std::tuple<bool, std::string> del(std::string key);
std::tuple<bool, std::string> clear();
std::tuple<bool, std::string> getReturnValue(GError *error);
std::tuple<bool, std::string> ensureInitialized();
std::tuple<bool, std::string> warmupKeyring(const gchar *name);
