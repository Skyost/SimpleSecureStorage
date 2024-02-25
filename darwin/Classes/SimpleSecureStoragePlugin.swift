#if canImport(Flutter)
    import Flutter
#elseif canImport(FlutterMacOS)
    import FlutterMacOS
#endif

/// The main plugin Swift class.
public class SimpleSecureStoragePlugin: NSObject, FlutterPlugin {
    /// The query.
    var query: [AnyHashable: Any] = [:]

    public override init() {
        super.init()
        query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KEYCHAIN_SERVICE
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
        let arguments: [String: Any?] = call.arguments as! [String: Any?]
        switch call.method {
        case "initialize":
            query[kSecAttrService as String] = arguments["namespace"] == nil ? "fr.skyost.simple_secure_storage" : (arguments["namespace"] as! String)
            result(true)
        case "has":
            result(read(call.key) != nil)
        case "read":
            result(read(call.key)!)
        case "write":
            let status = write(call.key!, forKey: call.value!)
            if status == noErr {
                result(true)
            } else {
                result(FlutterError.init(code: "incorrect_return_code", message: "Error while writing data.", details: status))
            }
        case "delete":
            let status = delete(call.key!)
            if status == noErr {
                result(true)
            } else {
                result(FlutterError.init(code: "incorrect_return_code", message: "Error while deleting data.", details: status))
            }
        case "clear":
            let status = clear()
            if status == noErr {
                result(true)
            } else {
                result(FlutterError.init(code: "incorrect_return_code", message: "Error while clearing data.", details: status))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Returns the value associated with the given key.
    func read(_ key: String) -> String? {
        var search = query
        search[kSecAttrAccount] = key
        search[kSecReturnData] = kCFBooleanTrue

        var resultData: AnyObject?
        var value: String?

        if SecItemCopyMatching(search as CFDictionary, &resultData) == noErr {
            if let data = resultData as? Data {
                value = String(data: data, encoding: .utf8)
            }
        }

        return value
    }

    /// Puts the given value for the given key.
    func write(_ value: String, forKey key: String) -> OSStatus {
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
        search[kSecReturnData] = kCFBooleanTrue
        return SecItemDelete(search as CFDictionary)
    }

    /// Clears everything.
    func clear() -> OSStatus {
        let search = query
        return SecItemDelete(search as CFDictionary)
    }
}

/// Easily get "key" and "value" inside a method call.
extension FlutterMethodCall {
  /// The key.
  var key: String? {
    return arguments?["key"] as? String
  }

  /// The value.
  var value: String? {
    return arguments?["value"] as? String
  }
}
