# Offline Support Implementation

## Overview

NotionGraph now supports full offline functionality with automatic background syncing. The app caches graph data locally and works seamlessly whether you're online or offline.

## Features

### 1. **Local Caching with SwiftData**
- All graph nodes and links are stored locally using SwiftData
- Data persists across app launches
- Fast loading from cache on startup
- Automatic cache updates after successful syncs

### 2. **Smart Loading Strategy**
```
App Launch
    ↓
Load from Cache (instant)
    ↓
Check Network Status
    ↓
If Online → Sync from Notion API → Update Cache
If Offline → Use Cached Data
```

### 3. **Network Monitoring**
- Real-time detection of network connectivity
- Automatic background sync when connection is restored
- Visual indicators for online/offline status

### 4. **Status Indicators**
- **Green dot + "Synced Xm ago"**: Online, recently synced
- **Orange dot + "Offline"**: No connection, using cached data
- **Red dot**: Connection issues

## Architecture

### Core Components

#### 1. **CachedModels.swift**
SwiftData models for persistent storage:
- `CachedGraphNode`: Stores graph nodes
- `CachedGraphLink`: Stores graph links
- `SyncMetadata`: Tracks last sync date and database ID

#### 2. **CacheService.swift**
Manages all cache operations:
- `saveGraphData()`: Saves nodes and links to cache
- `loadGraphData()`: Retrieves cached data
- `clearCache()`: Clears all cached data
- `hasCachedData()`: Checks if cache exists
- `getLastSyncDate()`: Returns last sync timestamp

#### 3. **NetworkMonitor.swift**
Real-time network connectivity monitoring:
- Uses `NWPathMonitor` from Network framework
- Publishes `isConnected` state
- Detects connection type (WiFi, Cellular, Ethernet)

#### 4. **NotionService.swift** (Enhanced)
Updated with offline support:
- `loadGraphData()`: New method that loads from cache first, then syncs
- `loadFromCache()`: Loads cached data
- `saveToCache()`: Saves after successful API fetch
- Tracks `lastSyncDate` and `isOfflineMode`

## How It Works

### Initial App Launch (No Cache)
1. App starts
2. No cached data found
3. Shows welcome screen
4. User configures API credentials
5. Fetches from Notion API
6. Displays graph
7. **Saves to cache**

### Subsequent Launch (With Cache)
1. App starts
2. **Loads from cache immediately** (instant display)
3. Checks network status
4. If online: Fetches fresh data from Notion API
5. Updates cache with new data
6. UI updates automatically

### Offline Mode
1. App starts
2. **Loads from cache**
3. Detects no network connection
4. Sets `isOfflineMode = true`
5. Shows orange "Offline" badge
6. User can view cached graph
7. When connection returns: Auto-syncs in background

## Data Flow

```
┌─────────────────┐
│  NotionGraph    │
│      App        │
└────────┬────────┘
         │
         ├─────────────────────────────┐
         │                             │
    ┌────▼──────┐              ┌───────▼──────┐
    │  SwiftData │              │   Notion API  │
    │   Cache    │              │               │
    └────┬───────┘              └───────┬───────┘
         │                              │
         │◄─────── Save After ──────────┤
         │         Successful Sync      │
         │                              │
    ┌────▼───────┐              ┌───────▼──────┐
    │ Load First │              │  Sync Fresh  │
    │  (Instant) │              │   (Online)   │
    └────────────┘              └──────────────┘
```

## Code Examples

### Loading Graph Data
```swift
// In ContentView
.task {
    // Inject services
    if notionService.cacheService == nil {
        notionService.cacheService = CacheService(modelContainer: modelContext.container)
        notionService.networkMonitor = networkMonitor
    }

    // Loads from cache first, then syncs if online
    await notionService.loadGraphData()
}
```

### Checking Offline Status
```swift
// In NotionService
@Published var isOfflineMode = false
@Published var lastSyncDate: Date?

// Automatically set when loading
if networkMonitor?.isConnected ?? true {
    await fetchDatabase()
} else {
    isOfflineMode = true
}
```

### Manual Refresh
```swift
Button {
    Task {
        await notionService.loadGraphData() // Tries to sync if online
    }
} label: {
    Image(systemName: "arrow.clockwise")
}
```

## Cache Management

### When Cache is Updated
- After successful Notion API fetch
- When new pages or links are added
- When database data changes

### Cache Location
- iOS: `Library/Application Support/` directory
- macOS: `~/Library/Application Support/[Bundle ID]/` directory
- Managed automatically by SwiftData

### Clearing Cache
Currently automatic on each sync. Future versions may include:
- Manual cache clear option in settings
- Cache expiration after X days
- Selective cache clearing

## Performance Benefits

### Before (Online Only)
- App launch: Wait for API → Display (2-5 seconds)
- Network issues: No graph display
- Offline: Unusable

### After (With Offline Support)
- App launch: Cache → Display (instant) → Background sync
- Network issues: Shows cached data
- Offline: Fully functional with cached data

## Limitations

- **Maximum 100 pages**: Notion API limit per query
- **Cache size**: Limited only by device storage
- **Sync frequency**: Manual or on app launch
- **No conflict resolution**: Last sync wins

## Future Enhancements

### Planned Features
1. **Background refresh**: Periodic auto-sync (15 min, 1 hour, etc.)
2. **Incremental sync**: Only fetch changed pages
3. **Cache settings**: Configure cache behavior
4. **Sync indicators**: Progress bar during sync
5. **Pull-to-refresh**: iOS gesture support
6. **Conflict resolution**: Handle concurrent edits
7. **Selective sync**: Choose which databases to cache

### Possible Optimizations
- Delta sync (only changed data)
- Compression for large graphs
- Multiple database support
- Cache preloading on idle
- Smart prefetching

## Troubleshooting

### Cache not loading
- Check SwiftData initialization in `NotionGraphApp.swift`
- Verify `modelContainer` is properly injected
- Check console for cache errors

### Sync not working
- Verify network connection
- Check Notion API credentials
- Review console logs for API errors

### Offline mode stuck
- Force quit and restart app
- Check network settings
- Toggle Airplane mode off/on

## Technical Details

### SwiftData Schema
```swift
@Model
final class CachedGraphNode {
    @Attribute(.unique) var id: String
    var name: String
    var type: String?
    var group: Int
    var url: String?
    var lastUpdated: Date
}

@Model
final class CachedGraphLink {
    @Attribute(.unique) var id: String
    var source: String
    var target: String
    var value: Int
    var lastUpdated: Date
}

@Model
final class SyncMetadata {
    @Attribute(.unique) var key: String
    var lastSyncDate: Date?
    var databaseId: String
}
```

### Dependency Injection
```swift
// App level
let modelContainer = try ModelContainer(
    for: CachedGraphNode.self,
    CachedGraphLink.self,
    SyncMetadata.self
)

// Service level
notionService.cacheService = CacheService(modelContainer: modelContext.container)
notionService.networkMonitor = networkMonitor
```

## Migration Notes

### From Previous Version
1. No migration needed - cache starts empty
2. First launch will fetch and cache
3. Subsequent launches use cache

### Database Changes
- SwiftData handles schema migrations automatically
- Cache will rebuild if schema changes detected

## Security & Privacy

### Data Storage
- Cached data stored locally on device
- Not encrypted by default (uses system protection)
- Not synced to iCloud (currently)

### API Keys
- Stored in UserDefaults (existing behavior)
- Separate from cache data
- Not included in cached graph data

## Testing Offline Mode

### Test Scenarios
1. **First launch**: No cache, online
2. **Cached launch**: Has cache, online (should see instant load + refresh)
3. **Offline launch**: Has cache, offline (should see orange badge)
4. **Network toggle**: Online → Offline → Online (watch status change)
5. **API error**: Bad credentials with cache (should show cached data)

### Testing Tools
- Xcode Network Link Conditioner
- macOS Network preferences → Offline
- iOS Settings → Airplane Mode
- Firewall rules to block traffic

## Conclusion

The offline support implementation provides a robust, production-ready solution for local data caching with automatic background syncing. Users can now use NotionGraph anytime, anywhere, with or without an internet connection.
