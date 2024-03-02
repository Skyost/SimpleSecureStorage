#if canImport(Flutter)
    import Flutter
#elseif canImport(FlutterMacOS)
    import FlutterMacOS
#endif

/// The main plugin Swift class.
public class SimpleSecureStoragePlugin: NSObject, FlutterPlugin {
    /// The query.
    var query: [AnyHashable: Any] = [:]

    /// Whether the plugin has been initialized.
    bool initialized = false

    public override init() {
        super.init()
        query = [
            kSecClass as String: kSecClassGenericPassword
        ]
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if canImport(Flutter)
            let messenger = registrar.messenger()
        #elseif canImport(FlutterMacOS)
            let messenger = registrar.messenger
        #endif
        let channel = FlutterMethodChannel(name: "fr.skyost.simple_secure_storage", binaryMessenger: messenger)
        let instance = SimpleSecureStoragePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments: [String: Any?] = call.arguments == nil ? [:] : (call.arguments as! [String: Any?])
        switch call.method {
        case "initialize":
            initialize(arguments["appName"] == nil ? "Flutter" : (arguments["appName"] as! String))
            result(true)
        case "has":
            if !ensureInitialized(result) {
                return
            }
            result(has(arguments["key"] as! String))
        case "read":
            if !ensureInitialized(result) {
                return
            }
            let readResult = read(arguments["key"] as! String)
            if readResult.1 == noErr {
                result(readResult.2)
            } else {
                result(FlutterError.init(code: "read_error", message: "Error while reading.", details: status))
            }
        case "list":
            if !ensureInitialized(result) {
                return
            }
            let listResult = list()
            if listResult.1 == noErr {
                result(listResult.2)
            } else {
                result(FlutterError.init(code: "list_error", message: "Error while listing.", details: status))
            }
        case "write":
            if !ensureInitialized(result) {
                return
            }
            let status = write(arguments["key"] as! String, arguments["value"] as! String)
            if status == noErr {
                result(true)
            } else {
                result(FlutterError.init(code: "write_error", message: "Error while writing data.", details: status))
            }
        case "delete":
            if !ensureInitialized(result) {
                return
            }
            let status = delete(arguments["key"] as! String)
            if status == noErr {
                result(true)
            } else {
                result(FlutterError.init(code: "delete_error", message: "Error while deleting data.", details: status))
            }
        case "clear":
            if !ensureInitialized(result) {
                return
            }
            let status = clear()
            if status == noErr {
                result(true)
            } else {
                result(FlutterError.init(code: "clear_error", message: "Error while clearing data.", details: status))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// Initializes the plugin.
    func initialize(_ appName: String) {
        // query[kSecAttrAccessGroup as String] = arguments["namespace"] == nil ? "fr.skyost.simple_secure_storage" : (arguments["namespace"] as! String)
        query[kSecAttrService as String] = appName
        initialized = true
    }
    
    /// Returns whether there is a value associated with the given key.
    func has(_ key: String) -> Bool {
        return read(key) != nil
    }

    /// Returns the value associated with the given key.
    func read(_ key: String) -> (OSError, String?) {
        var result = get(key)
        return result.1.isEmpty ? (result.0, nil) : (result.0, result.1.values.first!)
    }

    /// Returns all values.
    func list() -> (OSError, [String: String]) {
        return get()
    }

    /// Returns the values associated with the given key, or all values if omitted.
    func get(_ key: String? = nil) -> (OSError, [String: String]) {
      var search = query
      search[kSecMatchLimit] = kSecMatchLimitAll
      search[kSecReturnAttributes] = kCFBooleanTrue
      if key != nil {
          search[kSecAttrAccount] = key
      }

      var values: [String: String] = [:]
      var result: AnyObject?
      let status = SecItemCopyMatching(search as CFDictionary, &result)
      if status == errSecItemNotFound {
          return (noErr, values)
      }
      if status != noErr {
          return (status, values)
      }

      if let items = result as? [[NSString: Any?]] {
          for item in items {
            if let keyData = item[kSecAttrAccount] as? Data, let key = String(data: keyData, encoding: .utf8), let valueData = item[kSecValueData] as? Data, let value = String(data: valueData, encoding: .utf8){
                values[key] = value
            }
          }
      }
      return (noErr, values)
    }

    /// Puts the given value for the given key.
    func write(_ key: String, _ value: String) -> OSStatus {
        values[key] = value
        
        var search = query
        search[kSecAttrAccount] = key
        search[kSecMatchLimit] = kSecMatchLimitOne

        var status: OSStatus

        if SecItemCopyMatching(search as CFDictionary, nil) == noErr {
            search[kSecMatchLimit] = nil
            let update: [AnyHashable: Any] = [kSecValueData: value.data(using: .utf8)!]
            status = SecItemUpdate(search as CFDictionary, update as CFDictionary)
        } else {
            search[kSecValueData] = value.data(using: .utf8)!
            search[kSecMatchLimit] = nil
            status = SecItemAdd(search as CFDictionary, nil)
        }

        return status
    }

    /// Removes the value associated with the given key.
    func delete(_ key: String) -> OSStatus {
        var search = query
        search[kSecAttrAccount] = key
        return SecItemDelete(search as CFDictionary)
    }

    /// Clears everything.
    func clear() -> OSStatus {
        let search = query
        return SecItemDelete(search as CFDictionary)
    }
    
    /// Ensures that the plugin has been initialized.
    func ensureInitialized(_ result: FlutterResult) -> Bool {
        if initialized {
            return true;
        }
        result(FlutterError.init(code: "not_initialized", message: "Please make sure you have initialized the plugin."))
        return false
    }
}
