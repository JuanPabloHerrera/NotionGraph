# NotionGraph

A beautiful iOS and macOS app that visualizes your Notion databases as interactive knowledge graphs, similar to Obsidian's graph view.

## Features

- 📊 **Interactive Knowledge Graph**: Visualize your Notion database as a force-directed graph using D3.js
- 🔗 **Relationship Mapping**: Automatically detects and displays relations between Notion pages
- 🎨 **Beautiful Visualization**: Color-coded nodes with smooth animations and transitions
- 🔍 **Interactive**: Zoom, pan, drag nodes, and hover for details
- 📱 **Cross-platform**: Works on both iOS 17+ and macOS 14+
- ⚡ **Real-time Updates**: Refresh your graph with the latest data from Notion

## Setup Instructions

### 1. Create Xcode Project

Since we're starting from source files, you'll need to create the Xcode project:

1. Open Xcode
2. Select "Create a new Xcode project"
3. Choose "Multiplatform" → "App"
4. Set the following:
   - Product Name: `NotionGraph`
   - Interface: SwiftUI
   - Language: Swift
   - Platforms: iOS and macOS
   - Save location: Choose this directory (`~/Documents/Apps/NotionGraph`)

5. After creation, replace the generated files with the existing source files in `NotionGraph/Sources/`

**OR** simply open the `Package.swift` file in Xcode and create an app target manually.

### 2. Configure Build Settings

In Xcode:
1. Select the project in the navigator
2. Under "Signing & Capabilities", add your development team
3. Update bundle identifier to something unique (e.g., `com.yourname.notiongraph`)
4. Ensure deployment targets are set to:
   - iOS: 17.0 or later
   - macOS: 14.0 or later

### 3. Set Up Notion Integration

1. Go to [notion.so/my-integrations](https://www.notion.so/my-integrations)
2. Click "+ New integration"
3. Give it a name (e.g., "NotionGraph")
4. Select the workspace you want to use
5. Click "Submit"
6. Copy the "Internal Integration Token"

### 4. Share Database with Integration

1. Open the Notion database you want to visualize
2. Click "..." (three dots) in the top right
3. Click "Connections" → "Add connection"
4. Select your integration
5. Copy the database ID from the URL:
   - URL format: `notion.so/workspace/DATABASE_ID?v=...`
   - The DATABASE_ID is the part between the workspace name and `?v=`

### 5. Configure the App

1. Build and run the app
2. Click the settings (gear) icon
3. Enter your Notion API key and database ID
4. Click "Done"
5. The app will automatically fetch and display your knowledge graph

## Project Structure

```
NotionGraph/
├── NotionGraph/
│   ├── Sources/
│   │   ├── NotionGraphApp.swift      # App entry point
│   │   ├── ContentView.swift         # Main view with state management
│   │   ├── KnowledgeGraphView.swift  # D3.js graph visualization
│   │   ├── SettingsView.swift        # Configuration UI
│   │   ├── NotionService.swift       # Notion API client
│   │   └── Models.swift              # Data models
│   ├── Assets.xcassets/              # App icons and assets
│   └── Info.plist                    # App configuration
├── Package.swift                      # Swift Package Manager manifest
└── README.md                          # This file
```

## How It Works

1. **Fetch Data**: The app connects to your Notion database using the Notion API
2. **Build Graph**: Pages become nodes, and relation properties become edges
3. **Visualize**: D3.js renders an interactive force-directed graph in a WebView
4. **Interact**: Users can zoom, pan, drag nodes, and see page details

## Technology Stack

- **SwiftUI**: Modern declarative UI framework for iOS and macOS
- **WebKit**: Embeds web content for D3.js visualization
- **D3.js v7**: Powerful JavaScript library for data visualization
- **Notion API**: RESTful API for accessing Notion data

## Database Requirements

For best results, your Notion database should:
- Have a title property (displayed as node labels)
- Have relation properties connecting to other pages in the same database
- Be shared with your Notion integration

## Future Enhancements

- [ ] Filtering by properties or tags
- [ ] Different graph layouts (hierarchical, circular, etc.)
- [ ] Search and highlight specific nodes
- [ ] Export graph as image
- [ ] Support for multiple databases
- [ ] Custom color schemes
- [ ] Node clustering by property values

## Troubleshooting

**"No data" message**:
- Verify your API key is correct
- Ensure the database ID is accurate
- Check that the database is shared with your integration

**Graph not loading**:
- Check your internet connection
- Verify the D3.js CDN is accessible
- Look for errors in the console

**API errors**:
- Ensure your integration has access to the database
- Check that the API key hasn't expired
- Verify you haven't exceeded rate limits

## Contributing

This is a personal project, but suggestions and improvements are welcome!

## License

MIT License - Feel free to use and modify as needed.

## Acknowledgments

- Inspired by Obsidian's graph view
- Built with Notion's excellent API
- Powered by D3.js for beautiful visualizations
