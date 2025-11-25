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
    var initialized: Bool = false

    override public init() {
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
            executeInBackground(result: result) {
                self.initialize(arguments["appName"] == nil ? "Flutter" : (arguments["appName"] as! String))
                return true
            }
        case "has":
            if !ensureInitialized(result) {
                return
            }
            executeInBackground(result: result) {
                self.has(arguments["key"] as! String)
            }
        case "read":
            if !ensureInitialized(result) {
                return
            }
            executeInBackground(result: result) {
                let readResult = self.read(arguments["key"] as! String)
                if readResult.0 == noErr {
                    return readResult.1
                } else {
                    return FlutterError(code: "read_error", message: "Error while reading.", details: readResult.0)
                }
            }
        case "list":
            if !ensureInitialized(result) {
                return
            }
            executeInBackground(result: result) {
                let listResult = self.list()
                if listResult.0 == noErr {
                    return listResult.1
                } else {
                    return FlutterError(code: "list_error", message: "Error while listing.", details: listResult.0)
                }
            }
        case "write":
            if !ensureInitialized(result) {
                return
            }
            executeInBackground(result: result) {
                let status = self.write(arguments["key"] as! String, arguments["value"] as! String)
                if status == noErr {
                    return true
                } else {
                    return FlutterError(code: "write_error", message: "Error while writing data.", details: status)
                }
            }
        case "delete":
            if !ensureInitialized(result) {
                return
            }
            executeInBackground(result: result) {
                let status = self.delete(arguments["key"] as! String)
                if status == noErr {
                    return true
                } else {
                    return FlutterError(code: "delete_error", message: "Error while deleting data.", details: status)
                }
            }
        case "clear":
            if !ensureInitialized(result) {
                return
            }
            executeInBackground(result: result) {
                let status = self.clear()
                if status == noErr {
                    return true
                } else {
                    return FlutterError(code: "clear_error", message: "Error while clearing data.", details: status)
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Executes an operation in a background thread to prevent UI freezes.
    /// Results are posted back to the main thread.
    ///
    /// - Parameters:
    ///   - result: The FlutterResult to send back to Flutter.
    ///   - operation: The operation to execute in background.
    private func executeInBackground(result: @escaping FlutterResult, operation: @escaping () -> Any?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let operationResult = operation()
            DispatchQueue.main.async {
                result(operationResult)
            }
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
        return read(key).1 != nil
    }

    /// Returns the value associated with the given key.
    func read(_ key: String) -> (OSStatus, String?) {
        let result = get(key)
        return result.1.isEmpty ? (result.0, nil) : (result.0, result.1.values.first!)
    }

    /// Returns all values.
    func list() -> (OSStatus, [String: String]) {
        return get()
    }

    /// Returns the values associated with the given key, or all values if omitted.
    func get(_ key: String? = nil) -> (OSStatus, [String: String]) {
        var search = query
        search[kSecMatchLimit] = kSecMatchLimitAll
        search[kSecReturnAttributes] = kCFBooleanTrue
        if key != nil {
            search[kSecAttrAccount] = key
        }
        
        var values: [String: String] = [:]
        var status = SecItemCopyMatching(search as CFDictionary, nil)
        if status == errSecItemNotFound {
            return (noErr, values)
        }
        
        search[kSecReturnData] = kCFBooleanTrue
        // search[kSecReturnRef] = kCFBooleanTrue

        var result: AnyObject?
        status = SecItemCopyMatching(search as CFDictionary, &result)
        if status != noErr {
            return (status, values)
        }

        if let items = result as? [[NSString: Any?]] {
            for item in items {
                if let key = item[kSecAttrAccount] as? String, let valueData = item[kSecValueData] as? Data, let value = String(data: valueData, encoding: .utf8) {
                    values[key] = value
                }
            }
        }
        return (noErr, values)
    }

    /// Puts the given value for the given key.
    func write(_ key: String, _ value: String) -> OSStatus {
        var search = query
        search[kSecAttrAccount] = key
        search[kSecMatchLimit] = kSecMatchLimitOne

        var status: OSStatus
        if SecItemCopyMatching(search as CFDictionary, nil) == noErr {
            search[kSecMatchLimit] = nil
            
            var update: [AnyHashable: Any] = [kSecValueData: value.data(using: .utf8)!]
            if #available(macOS 10.15, *) {
                update[kSecUseDataProtectionKeychain] = kCFBooleanTrue
            }
            status = SecItemUpdate(search as CFDictionary, update as CFDictionary)
        } else {
            search[kSecValueData] = value.data(using: .utf8)!
            search[kSecMatchLimit] = nil
            if #available(macOS 10.15, *) {
                search[kSecUseDataProtectionKeychain] = kCFBooleanTrue
            }
            status = SecItemAdd(search as CFDictionary, nil)
        }

        return status
    }

    /// Removes the value associated with the given key.
    func delete(_ key: String) -> OSStatus {
        var search = query
        search[kSecAttrAccount] = key
        let status = SecItemDelete(search as CFDictionary)
        return status == noErr || status == errSecItemNotFound ? noErr : status
    }

    /// Clears everything.
    func clear() -> OSStatus {
        let search = query
        let status = SecItemDelete(search as CFDictionary)
        return status == noErr || status == errSecItemNotFound ? noErr : status
    }

    /// Ensures that the plugin has been initialized.
    func ensureInitialized(_ result: FlutterResult) -> Bool {
        if initialized {
            return true
        }
        result(FlutterError(code: "not_initialized", message: "Please make sure you have initialized the plugin.", details: nil))
        return false
    }
}
