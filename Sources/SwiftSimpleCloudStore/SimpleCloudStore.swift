import Foundation
import SwiftConcurrency
import SwiftFoundationExtensions
import os

/**
 A wrapper around `NSUbiquitousKeyValueStore` providing the ability to wait for the initial cloud state download
 after an app is installed and shorthand for settings/reading stored values.
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
   The polling interval for initial cloud sync completion: 250ms.
   */
  public static let DEFAULT_INITIAL_CLOUD_SYNC_POLL_INTERVAL_SECONDS = 0.25
  
  /**
   The max amount of time for the initial cloud sync, upon `syncWithCloud`: 5 seconds.
   */
  public static let DEFAULT_INITIAL_CLOUD_SYNC_TIMEOUT_SECONDS = 5.0
  
  /**
   Key for recording whether the initial cloud sync of the data was done.
   */
  private static let KEY_INITIAL_CLOUD_SYNC_COMPLETED = "isInitialCloudSyncCompleted"
  
  /**
   The log level used for informational messages from the store.
   */
  private let logLevel: OSLogType
  
  /**
   The polling interval if a call to `syncWithCloud` is called the first time after installation and we are waiting for the initial
   cloud sync to complete.
   */
  private let initialCloudSyncPollIntervalSeconds: Double
  
  /**
   The maximum amount of time to wait if a call to `syncWithCloud` is called the first time after installation and we are waiting
   for the initial cloud sync to complete
   */
  private let initialCloudSyncTimeoutSeconds: Double
  
  /**
   True if this class is registered to external store change notifications, false otherwise.
   */
  private var notificationRegistered: Bool = false
  
  /**
   When true, the initial sync has bee completed, either in a prior sync operation or during initialization.
   */
  private var initialCloudSyncCompleted: Bool = false
  
  /**
   The underlying value store.
   */
  private let store = NSUbiquitousKeyValueStore.default
  
  /**
   Initializes a new `SimpleCloudStore`.
   
   `syncWithCloud` can be called once in the app's lifecycle after initialization to ensure that the local
   values reflect those in the cloud.
   
   - Parameter logLevel: the log level used for informational messages from the store.
   - Parameter initialCloudSyncPollIntervalSeconds: polling interval for the initial cloud state sync.
   - Parameter initialCloudSyncTimeoutSeconds: the timeout for the initial cloud state sync.
   */
  public init(
    logLevel: OSLogType = DEFAULT_LOG_LEVEL,
    initialCloudSyncPollIntervalSeconds: Double = DEFAULT_INITIAL_CLOUD_SYNC_POLL_INTERVAL_SECONDS,
    initialCloudSyncTimeoutSeconds: Double = DEFAULT_INITIAL_CLOUD_SYNC_TIMEOUT_SECONDS
  ) {
    self.logLevel = logLevel
    self.initialCloudSyncPollIntervalSeconds = initialCloudSyncPollIntervalSeconds
    self.initialCloudSyncTimeoutSeconds = initialCloudSyncTimeoutSeconds
    
    // Subscribe to external change notifications so that we know when synchronization has finished.
    subscribeToExternalChangeNotifications()
  }
  
  deinit {
    // Ensure we unsubscribe from key/value store modification notifications when shutting down.
    unsubscribeFromExternalChangeNotifications()
  }
  
  /**
   Subscribes to the underlying store's `NSUbiquitousKeyValueStore.didChangeExternallyNotification` notification,
   allowing this store to know when the initial synchronization has completed. See `syncWithCloud` for details.
   */
  private func subscribeToExternalChangeNotifications() {
    // If already registered, nothing to do.
    guard !notificationRegistered else {
      return
    }
    
    Self.logger.log(
      level: logLevel,
      "Registering to external store change notifications."
    )
    
    NotificationCenter.default
      .addObserver(
        self,
        selector: #selector(onStoreExternallyChanged(_:)),
        name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
        object: store
      )
    
    notificationRegistered = true
  }
  
  /**
   Unsubscribes from the underlying store's `NSUbiquitousKeyValueStore.didChangeExternallyNotification`
   notification. See `syncWithCloud` for details.
   */
  private func unsubscribeFromExternalChangeNotifications() {
    Self.logger.log(
      level: logLevel,
      "Shutting down, unregistering from external store change notifications."
    )
    
    NotificationCenter.default
      .removeObserver(
        self,
        name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
        object: store
      )
    
    notificationRegistered = false
  }
  
  /**
   Called when external change notifications are received for the underlying store.
   */
  @objc
  private func onStoreExternallyChanged(_ notification: Notification) {
    // Extract notification change reason.
    let rawChangeReason = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey]
    guard let reason = rawChangeReason as? Int else {
      return
    }
    
    // If we received a notification that the initial sync is done, mark it as done.
    if reason == NSUbiquitousKeyValueStoreInitialSyncChange {
      initialCloudSyncCompleted = true
    }
  }
  
  /**
   Synchronizes the in-memory storage with their stored and cloud state.
   This function should be called once during app start up and when the app comes back into foreground.
   The first time this function is called after app installation, it will wait for the cloud state to be downloaded.
   
   NOTE: Cloud synchronization is not guaranteed to happen right away.
   
   NOTE: The operation is restricted to `@MainActor` for simplicity, but will not block the main thread.
   */
  @MainActor
  public func syncWithCloud() async throws {
    // Trigger the underlying store's in-memory -> disk synchronization, which will in turn schedule
    // the cloud sync if needed.
    if !store.synchronize() {
      // Synchronization failed, let the caller know and exit.
      Self.logger.warning("Failed to synchronize simple cloud store.")
      return
    }
    
    // Notify the log that the main sync succeeded.
    Self.logger.log(level: logLevel, "Synchronizing simple cloud store.")
    
    // If there was a previous initial cloud sync, nothing left to do.
    initialCloudSyncCompleted = initialCloudSyncCompleted ||
      getBool(forKey: Self.KEY_INITIAL_CLOUD_SYNC_COMPLETED)
    
    if initialCloudSyncCompleted {
      Self.logger.log(
        level: logLevel,
        "Simple cloud store initial cloud sync already done, skipping wait."
      )
      return
    }
    
    // Poll for completion via notification callback.
    let syncCompleted = try await Task.poll(
      intervalSeconds: initialCloudSyncPollIntervalSeconds,
      timeoutSeconds: initialCloudSyncTimeoutSeconds
    ) { @MainActor [self] in
      // See if the sync completed via onStoreExternallyChanged callback.
      if initialCloudSyncCompleted {
        // Mark it as done in the store itself, so that we don't do it again.
        set(forKey: Self.KEY_INITIAL_CLOUD_SYNC_COMPLETED, value: true)
        
        // Let the caller know the whole process is done.
        Self.logger.log(level: logLevel, "Initial simple cloud store sync done.")
      }
      
      return initialCloudSyncCompleted
    }
    
    // If the sync didn't finish and we're not cancelled, it was a timeout.
    if !Task.isCancelled && !syncCompleted {
      Self.logger.log(level: logLevel, "Initial simple cloud store sync timed out.")
    }
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
