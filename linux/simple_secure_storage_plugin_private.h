#include <flutter_linux/flutter_linux.h>

#include "include/simple_secure_storage/simple_secure_storage_plugin.h"

// This file exposes some plugin internals for unit testing. See
// https://github.com/flutter/flutter/issues/88724 for current limitations
// in the unit-testable API.

static SecretStorage keyring;

FlValue* has(const gchar* key);
FlValue *read(const gchar *key);
void write(const gchar *key, const gchar *value);
void del(const gchar *key);
void clear();