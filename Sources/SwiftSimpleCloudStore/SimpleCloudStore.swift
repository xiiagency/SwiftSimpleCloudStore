import Foundation
import SwiftFoundationExtensions
import os

/**
 A wrapper around `NSUbiquitousKeyValueStore` providing shorthand for settings/reading/clearing stored values.
 */
public class SimpleCloudStore {
  /**
   Logger used for logging messages from the store.
   */
  private static let logger: Logger = .loggerFor(SimpleCloudStore.self)
  
  /**
   The default log level to use for informational messages from the store: `OSLogType.info`.
   */
  public static let DEFAULT_LOG_LEVEL: OSLogType = .info
  
  /**
   The log level used for informational messages from the store.
   */
  private let logLevel: OSLogType
  
  /**
   The underlying value store.
   */
  private let store = NSUbiquitousKeyValueStore.default
  
  /**
   Initializes a new `SimpleCloudStore`.
   
   - Parameter logLevel: the log level used for informational messages from the store.
   */
  public init(logLevel: OSLogType = DEFAULT_LOG_LEVEL) {
    self.logLevel = logLevel
  }
  
  /**
   Synchronizes the in-memory storage with their stored state (and possibly the cloud state).
   This function should be called once during app start up and when the app comes back into foreground.
   */
  public func synchronize() {
    // Trigger the underlying store's in-memory -> disk synchronization, which will in turn schedule
    // the cloud sync if needed.
    if !store.synchronize() {
      // Synchronization failed, let the caller know and exit.
      Self.logger.warning("Failed to synchronize simple cloud store.")
      return
    }
    
    // Notify the log that the main sync succeeded.
    Self.logger.log(level: logLevel, "Synchronized simple cloud store.")
  }
  
  /**
   Returns the value for the key as an `Array` or the `defaultValue` if no value is set.
   */
  public func getArray<Element>(forKey: String, defaultValue: [Element]) -> [Element] {
    store.array(forKey: forKey) as? [Element] ?? defaultValue
  }
  
  /**
   Returns the value for the key as an `Bool` or `false` if no value is set.
   */
  public func getBool(forKey: String) -> Bool {
    store.bool(forKey: forKey)
  }
  
  /**
   Returns the value for the key as a `Data` or  the `defaultValue` if no value is set.
   */
  public func getData(forKey: String, defaultValue: Data) -> Data {
    store.data(forKey: forKey) ?? defaultValue
  }
  
  /**
   Returns the value for the key as a `Dictionary` or  the `defaultValue` if no value is set.
   */
  public func getDictionary<Value>(forKey: String, defaultValue: [String: Value]) -> [String: Value] {
    store.dictionary(forKey: forKey) as? [String: Value] ?? defaultValue
  }
  
  /**
   Returns the value for the key as a `Double` or `0.0` if no value is set.
   */
  public func getDouble(forKey: String) -> Double {
    store.double(forKey: forKey)
  }
  
  /**
   Returns the value for the key  as an `Int` or `0` if no value is set.
   */
  public func getInt(forKey: String) -> Int {
    Int(store.longLong(forKey: forKey))
  }
  
  /**
   Returns the value for the key as a `Set` or the `defaultValue` if no value is set.
   */
  public func getSet<Element>(forKey: String, defaultValue: Set<Element>) -> Set<Element> {
    Set(getArray(forKey: forKey, defaultValue: Array(defaultValue)))
  }
  
  /**
   Returns the value for the key as a `String` or the `defaultValue` if no value is set.
   */
  public func getString(forKey: String, defaultValue: String) -> String {
    store.string(forKey: forKey) ?? defaultValue
  }
  
  /**
   Sets the `Array` value for the given key.
   */
  public func set<Element>(forKey: String, value: Array<Element>) {
    store.set(value, forKey: forKey)
  }
  
  /**
   Sets the `Bool` value for the given key.
   */
  public func set(forKey: String, value: Bool) {
    store.set(value, forKey: forKey)
  }
  
  /**
   Sets the `Data` value for the given key.
   */
  public func set(forKey: String, value: Data) {
    store.set(value, forKey: forKey)
  }
  
  /**
   Sets the `Dictionary` value for the given key.
   */
  public func set<Value>(forKey: String, value: [String: Value]) {
    store.set(value, forKey: forKey)
  }
  
  /**
   Sets the `Double` value for the given key.
   */
  public func set(forKey: String, value: Double) {
    store.set(value, forKey: forKey)
  }
  
  /**
   Sets the `Int` value for the given key.
   */
  public func set(forKey: String, value: Int) {
    store.set(value, forKey: forKey)
  }
  
  /**
   Sets the `Set` value for the given key.
   */
  public func set<Element>(forKey: String, value: Set<Element>) {
    set(forKey: forKey, value: Array(value))
  }
  
  /**
   Sets the `String` value for the given key.
   */
  public func set(forKey: String, value: String) {
    store.set(value, forKey: forKey)
  }
  
  /**
   Clears the value for the given key.
   */
  public func clear(forKey: String) {
    store.removeObject(forKey: forKey)
  }
}
