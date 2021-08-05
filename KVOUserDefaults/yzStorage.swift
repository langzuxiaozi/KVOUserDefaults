//
//  yzStorage.swift
//  KVOUserDefaults
//
//  Created by langzuxiaozi on 2019/12/18.
//  Copyright © 2019 langzuxiaozi. All rights reserved.
//

import Foundation


// The marker protocol
protocol PropertyListValue {}

extension Data: PropertyListValue {}
extension String: PropertyListValue {}
extension Date: PropertyListValue {}
extension Bool: PropertyListValue {}
extension Int: PropertyListValue {}
extension Double: PropertyListValue {}
extension Float: PropertyListValue {}

// Every element must be a property-list type
extension Array: PropertyListValue where Element: PropertyListValue {}
extension Dictionary: PropertyListValue where Key == String, Value: PropertyListValue {}

struct Key: RawRepresentable {
    let rawValue: String
}

extension Key: ExpressibleByStringLiteral {
    init(stringLiteral: String) {
        rawValue = stringLiteral
    }
}

// MARK: DefaultsObservation
class DefaultsObservation: NSObject {
    let key: Key
    private var onChange: (Any, Any) -> Void

    // 1
    init(key: Key, onChange: @escaping (Any, Any) -> Void) {
        self.onChange = onChange
        self.key = key
        super.init()
        UserDefaults.standard.addObserver(self, forKeyPath: key.rawValue, options: [.old, .new], context: nil)
    }
    
    // 2
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = change, object != nil, keyPath == key.rawValue else { return }
        onChange(change[.oldKey] as Any, change[.newKey] as Any)
    }
    
    // 3
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: key.rawValue, context: nil)
    }
}
@propertyWrapper
struct UserDefaultWrapper<T: PropertyListValue> {
    let key: Key
    let defaultValue: T
    let userDefaults: UserDefaults
    var projectedValue: UserDefaultWrapper<T> { return self }
    /// 构造函数
    /// - Parameters:
    ///   - key: 存储key值
    ///   - defaultValue: 当存储值不存在时返回的默认值
    init(_ key: Key, defaultValue: T, userDefaults: UserDefaults = UserDefaults.standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    /// wrappedValue是@propertyWrapper必须需要实现的属性
    /// 当操作我们要包裹的属性时，其具体的set、get方法实际上走的都是wrappedValue的get、set方法
    public var wrappedValue: T {
        get {
            return userDefaults.object(forKey: key.rawValue) as? T ?? defaultValue
        }
        set {
            userDefaults.setValue(newValue, forKey: key.rawValue)
        }
    }
    
    public func observe(change: @escaping (T?, T?) -> Void) -> NSObject {
        return DefaultsObservation(key: key) { old, new in
            change(old as? T, new as? T)
        }
    }
}

extension Key:PropertyListValue {
    static let isFirstLaunch: Key = "isFirstLaunch"
}
struct Storage {
    @UserDefaultWrapper(Key.isFirstLaunch , defaultValue: false)
    var isFirstLaunch: Bool
}


