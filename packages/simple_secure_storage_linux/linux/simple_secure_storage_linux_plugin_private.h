#include <flutter_linux/flutter_linux.h>

#include "include/simple_secure_storage_linux/simple_secure_storage_linux_plugin.h"
#include "include/secret.h"

const SecretSchema *get_secret_schema(void) G_GNUC_CONST;
#define SECRET_SCHEMA get_secret_schema()

bool initialized;

std::tuple<bool, std::string> initialize(const gchar *name);
bool has(std::string key);
tl::optional<std::string> read(std::string key);
std::tuple<bool, std::string> write(std::string key, std::string value);
std::tuple<bool, std::string> del(std::string key);
std::tuple<bool, std::string> clear();
std::tuple<bool, std::string> getReturnValue(GError *error);
std::tuple<bool, std::string> ensureInitialized();
std::tuple<bool, std::string> warmupKeyring(const gchar *name);
