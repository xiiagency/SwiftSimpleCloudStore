# SwiftSimpleCloudStore Library

[![GitHub](https://img.shields.io/github/license/xiiagency/SwiftSimpleCloudStore?style=for-the-badge)](./LICENSE)

An open source library that provides a wrapper around `NSUbiquitousKeyValueStore` to access cloud synched simple storage.

Developed as re-usable components for various projects at
[XII's](https://github.com/xiiagency) iOS, macOS, and watchOS applications.

## Installation

### Swift Package Manager

1. In Xcode, select File > Swift Packages > Add Package Dependency.
2. Follow the prompts using the URL for this repository
3. Select the `SwiftSimpleCloudStore` library to add to your project

## Dependencies

- [xiiagency/SwiftFoundationExtensions](https://github.com/xiiagency/SwiftFoundationExtensions)

## License

See the [LICENSE](LICENSE) file.

## `SimpleCloudStore` service ([Source](Sources/SwiftSimpleCloudStore/SimpleCloudStore.swift))

```Swift
class SimpleCloudStore {
  static let DEFAULT_LOG_LEVEL: OSLogType = .info

  init(logLevel: OSLogType = DEFAULT_LOG_LEVEL)

  func synchronize()

  func getArray<Element>(
    forKey: String,
    defaultValue: [Element]
  ) -> [Element]

  func getBool(forKey: String) -> Bool

  func getData(
    forKey: String,
    defaultValue: Data
  ) -> Data

  func getDictionary<Value>(
    forKey: String,
    defaultValue: [String: Value]
  ) -> [String: Value]

  func getDouble(forKey: String) -> Double

  func getInt(forKey: String) -> Int

  func getSet<Element>(
    forKey: String,
    defaultValue: Set<Element>
  ) -> Set<Element>

  func getString(
    forKey: String,
    defaultValue: String
  ) -> String

  func set<Element>(forKey: String, value: Array<Element>)

  func set(forKey: String, value: Bool)

  func set(forKey: String, value: Data)

  func set<Value>(forKey: String, value: [String: Value])

  func set(forKey: String, value: Double)

  func set(forKey: String, value: Int)

  func set<Element>(forKey: String, value: Set<Element>)

  func set(forKey: String, value: String)

  func clear(forKey: String)
}
```

A wrapper around `NSUbiquitousKeyValueStore` providing shorthand for settings/reading/clearing stored values.

The `synchronize` function synchronizes the in-memory storage with their stored state (and possibly the cloud state). This function should be called once during app start up and when the app comes back into foreground.

## Adding the store to your environment ([Source](Sources/SwiftSimpleCloudStore/EnvironmentValues%2BExtensions.swift))

### The `SimpleCloudServiceProvider` protocol

```Swift
protocol SimpleCloudStoreProvider {
  var store: SimpleCloudStore { get }
}
```

Defines a provider that can return an instance of `SimpleCloudService`.

Indirect access to the store is used via this provider protocol to prevent multiple stores from being initialized in `EnvironmentValues`.

### Two provider implementation available

```Swift
struct UnavailableSimpleCloudStoreProvider : SimpleCloudStoreProvider { }
```

An implementation of `SimpleCloudStoreProvider` that is used when no `SimpleCloudStore` is available.

Raises a `fatalError` if the store is requested.

---

```Swift
struct StaticSimpleCloudStoreProvider : SimpleCloudStoreProvider { }
```

An implementation of `SimpleCloudStoreProvider` that returns the `SimpleCloudStore` instance provided during
initialization.

### Providing an instance via `View` extensions

```Swift
extension View {
  func simpleCloudStoreProvider(_ provider: SimpleCloudStoreProvider) -> some View

  func simpleCloudStore(_ store: SimpleCloudStore) -> some View
}
```

### Retrieving an instance in your `View`s

```Swift
struct FooView : View {
  @Environment(\.simpleCloudStoreProvider) private var simpleCloudStoreProvider

  var body : some View {
    Test("Bar")
      .onAppear {
        let value = simpleCloudStoreProvider.store
          .getBool(forKey: "someKey")

        print("Value: \(value))
      }
  }
}
```
