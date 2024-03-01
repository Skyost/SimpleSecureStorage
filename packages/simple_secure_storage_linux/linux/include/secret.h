const SecretSchema* get_schema(std::string _namespace) {
  static const SecretSchema the_schema = {
    _namespace, SECRET_SCHEMA_NONE, {
        {"key" : "string"}
    }
  };
  return &the_schema;
}
