#if canImport(Flutter)
    import Flutter
#elseif canImport(FlutterMacOS)
    import FlutterMacOS
#endif

/// The main plugin Swift class.
public class SimpleSecureStoragePlugin: NSObject, FlutterPlugin {
    /// The query.
    var query: [AnyHashable: Any] = [:]
    
    /// The loaded values.
    var values: [String: String] = [:]

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
            // query[kSecAttrAccessGroup as String] = arguments["namespace"] == nil ? "fr.skyost.simple_secure_storage" : (arguments["namespace"] as! String)
            query[kSecAttrService as String] = arguments["appName"] == nil ? "Flutter" : (arguments["appName"] as! String)
            let status = initialize()
            if status == noErr {
                result(true)
            } else {
                result(FlutterError.init(code: "initialization_error", message: "Error while initializing.", details: status))
            }
        case "has":
            result(has(arguments["key"] as! String))
        case "read":
            result(read(arguments["key"] as! String))
        case "list":
            result(values)
        case "write":
            let status = write(arguments["key"] as! String, arguments["value"] as! String)
            if status == noErr {
                result(true)
            } else {
                result(FlutterError.init(code: "write_error", message: "Error while writing data.", details: status))
            }
        case "delete":
            let status = delete(arguments["key"] as! String)
            if status == noErr {
                result(true)
            } else {
                result(FlutterError.init(code: "delete_error", message: "Error while deleting data.", details: status))
            }
        case "clear":
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
    
    /// Initialies the plugin by loading everything in the memory.
    func initialize() -> OSStatus {
        var search = query
        search[kSecMatchLimit] = kSecMatchLimitAll
        search[kSecReturnAttributes] = kCFBooleanTrue
        search[kSecMatchLimit] = kSecMatchLimitAll

        var result: AnyObject?

        let status = SecItemCopyMatching(search as CFDictionary, &result)
        if status == errSecItemNotFound {
            return noErr
        }
        if status != noErr {
            return status
        }
        
        if let items = result as? [[NSString: Any?]] {
            for item in items {
                if let keyData = item[kSecAttrAccount] as? Data, let key = String(data: keyData, encoding: .utf8), let valueData = item[kSecValueData] as? Data, let value = String(data: valueData, encoding: .utf8){
                    values[key] = value
                }
            }
        }
        return noErr
    }
    
    /// Returns whether there is a value associated with the given key.
    func has(_ key: String) -> Bool {
        return values[key] != nil
    }

    /// Returns the value associated with the given key.
    func read(_ key: String) -> String? {
        return values[key]
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
        values.removeValue(forKey: key)
        var search = query
        search[kSecAttrAccount] = key
        return SecItemDelete(search as CFDictionary)
    }

    /// Clears everything.
    func clear() -> OSStatus {
        values.removeAll()
        let search = query
        return SecItemDelete(search as CFDictionary)
    }
}
