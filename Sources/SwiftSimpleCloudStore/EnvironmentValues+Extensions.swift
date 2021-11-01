import SwiftUI

/**
 Defines a provider that can return an instance of `SimpleCloudService`.
 
 Indirect access to the store is used via this provider protocol to prevent multiple stores from being initialized in `EnvironmentValues`.
 */
public protocol SimpleCloudStoreProvider {
  /**
   Returns the provided `SimpleCloudStore`.
   */
  var store: SimpleCloudStore { get }
}

/**
 An implementation of `SimpleCloudStoreProvider` that is used when no `SimpleCloudStore` is available.
 
 Raises a `fatalError` if the store is requested.
 */
public struct UnavailableSimpleCloudStoreProvider : SimpleCloudStoreProvider {
  /**
   Raises a `fatalError` when the `store` is requested.
   */
  public var store: SimpleCloudStore {
    fatalError("No SimpleCloudStore currently available.")
  }
}

/**
 An implementation of `SimpleCloudStoreProvider` that returns the `SimpleCloudStore` instance provided during
 initialization.
 */
public struct StaticSimpleCloudStoreProvider : SimpleCloudStoreProvider {
  /**
   Returns the `SimpleCloudStore` provided during initialization.
   */
  public let store: SimpleCloudStore
}

/**
 The `EnvironmentKey` used to read/write the `simpleCloudStoreProvider` value from `EnvironmentValues`.
 */
private struct SimpleCloudStoreProviderKey : EnvironmentKey {
  /**
   Uses an instance of `UnavailableSimpleCloudStoreProvider` as the default value.
   */
  static let defaultValue: SimpleCloudStoreProvider = UnavailableSimpleCloudStoreProvider()
}

extension EnvironmentValues {
  /**
   Allows access to a `SimpleCloudStoreProvider` or the default one (unavailable) if no specific one was registered.
   */
  public var simpleCloudStoreProvider: SimpleCloudStoreProvider {
    get { self[SimpleCloudStoreProviderKey.self] }
    set { self[SimpleCloudStoreProviderKey.self] = newValue }
  }
}

extension View {
  /**
   Registers a specific `SimpleCloudStoreProvider` with the `Environment`.
   */
  public func simpleCloudStoreProvider(_ provider: SimpleCloudStoreProvider) -> some View {
    environment(\.simpleCloudStoreProvider, provider)
  }
  
  /**
   Registers a `SimpleCloudStoreProvider` in the environment using the `StaticSimpleCloudStoreProvider`
   using the provided `SimpleCloudStore` instance.
   */
  public func simpleCloudStore(_ store: SimpleCloudStore) -> some View {
    simpleCloudStoreProvider(StaticSimpleCloudStoreProvider(store: store))
  }
}
