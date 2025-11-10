import SwiftUI
import WebKit

struct KnowledgeGraphView: View {
    let nodes: [GraphNode]
    let links: [GraphLink]

    var body: some View {
        #if os(macOS)
        D3WebView(nodes: nodes, links: links)
            .ignoresSafeArea(edges: .bottom)
        #else
        GeometryReader { geometry in
            D3WebView(nodes: nodes, links: links)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .edgesIgnoringSafeArea(.all)
        }
        .edgesIgnoringSafeArea(.all)
        #endif
    }
}

// Shared HTML generation logic for both platforms
fileprivate func generateHTML(nodes: [GraphNode], links: [GraphLink]) -> String {
    let graphData = GraphData(nodes: nodes, links: links)

    // Safely encode the graph data
    guard let jsonData = try? JSONEncoder().encode(graphData),
          let jsonString = String(data: jsonData, encoding: .utf8) else {
        // Return empty graph if encoding fails
        return generateHTMLWithData("{\"nodes\":[],\"links\":[]}")
    }

    return generateHTMLWithData(jsonString)
}

fileprivate func generateHTMLWithData(_ jsonString: String) -> String {
    return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, height=device-height, initial-scale=1.0, minimum-scale=1.0, maximum-scale=5.0, user-scalable=yes, viewport-fit=cover">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                html {
                    width: 100vw;
                    height: 100vh;
                    height: -webkit-fill-available;
                }
                body {
                    margin: 0;
                    padding: 0;
                    width: 100vw;
                    height: 100vh;
                    height: -webkit-fill-available;
                    overflow: hidden;
                    background: #fafafa;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                }
                #graph {
                    width: 100vw;
                    height: 100vh;
                    height: -webkit-fill-available;
                    position: absolute;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                }
                .node {
                    cursor: pointer;
                }
                .node circle {
                    stroke: #d1d5db;
                    stroke-width: 1.5px;
                }
                .node text {
                    font-size: 11px;
                    font-weight: 400;
                    fill: #37352f;
                    pointer-events: none;
                    text-anchor: middle;
                    dominant-baseline: middle;
                }
                .link {
                    fill: none;
                }
                #debug-overlay {
                    display: none;  /* Hidden for clean minimalist view */
                }

                /* Context Menu Styles - shadcn inspired */
                #context-menu {
                    position: fixed;
                    display: none;
                    z-index: 1000;
                    background: white;
                    border: 1px solid #e5e7eb;
                    border-radius: 8px;
                    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
                    padding: 4px;
                    min-width: 180px;
                }

                .menu-button {
                    display: flex;
                    align-items: center;
                    width: 100%;
                    padding: 8px 12px;
                    border: none;
                    background: white;
                    color: #37352f;
                    font-size: 13px;
                    font-weight: 400;
                    text-align: left;
                    cursor: pointer;
                    border-radius: 4px;
                    transition: background-color 0.15s ease;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                }

                .menu-button:hover {
                    background: #f5f5f5;
                }

                .menu-button:active {
                    background: #e5e7eb;
                }

                .menu-button.disabled {
                    color: #9ca3af;
                    cursor: not-allowed;
                }

                .menu-button.disabled:hover {
                    background: white;
                }
            </style>
        </head>
        <body>
            <div id="debug-overlay"></div>
            <div id="context-menu">
                <button class="menu-button disabled" id="local-graph-btn">
                    Open Local Graph
                </button>
                <button class="menu-button" id="open-notion-btn">
                    Open in Notion
                </button>
            </div>
            <div id="graph"></div>
            <script src="https://d3js.org/d3.v7.min.js"></script>
            <script>
                const data = \(jsonString);

                const width = window.innerWidth;
                const height = window.innerHeight;

                const svg = d3.select("#graph")
                    .append("svg")
                    .attr("width", width)
                    .attr("height", height)
                    .attr("viewBox", [0, 0, width, height]);

                // Add zoom behavior
                const g = svg.append("g");

                let nodeText;  // Will be defined after nodes are created

                svg.call(d3.zoom()
                    .extent([[0, 0], [width, height]])
                    .scaleExtent([0.1, 8])
                    .on("zoom", (event) => {
                        g.attr("transform", event.transform);

                        // Update text opacity based on zoom level
                        if (nodeText) {
                            // More aggressive fade: text becomes transparent faster as you zoom out
                            // At zoom 1.0: fully visible
                            // At zoom 0.75: ~56% visible
                            // At zoom 0.5: invisible
                            const normalizedZoom = Math.max(0, Math.min(1, (event.transform.k - 0.5) / 0.5));
                            const opacity = Math.pow(normalizedZoom, 1.5);  // Power curve for smoother fade
                            nodeText.style("opacity", opacity);
                        }
                    }));

                const simulation = d3.forceSimulation(data.nodes)
                    .force("link", d3.forceLink(data.links).id(d => d.id).distance(80))
                    .force("charge", d3.forceManyBody().strength(-100))
                    .force("center", d3.forceCenter(width / 2, height / 2))
                    .force("x", d3.forceX(width / 2).strength(0.1))
                    .force("y", d3.forceY(height / 2).strength(0.1))
                    .force("collision", d3.forceCollide().radius(35))
                    .velocityDecay(0.6)  // Increased friction for smoother movement
                    .alphaDecay(0.02);   // Slower cooldown for smoother transitions

                // Create links FIRST (so they draw behind nodes)
                const link = g.append("g")
                    .attr("class", "links")
                    .selectAll("line")
                    .data(data.links)
                    .join("line")
                    .attr("class", "link")
                    .style("stroke", "#e5e7eb")  // Light gray for minimalist look
                    .style("stroke-width", "1px")
                    .style("stroke-opacity", "0.6");

                // Create nodes SECOND (so they draw on top of links)
                // Context menu state
                let currentNode = null;
                const contextMenu = document.getElementById('context-menu');
                const localGraphBtn = document.getElementById('local-graph-btn');
                const openNotionBtn = document.getElementById('open-notion-btn');

                const node = g.append("g")
                    .attr("class", "nodes")
                    .selectAll("g")
                    .data(data.nodes)
                    .join("g")
                    .attr("class", "node")
                    .call(drag(simulation))
                    .on("click", (event, d) => {
                        // Only show menu for page nodes, not tags
                        if (d.type === "page" && d.url) {
                            event.stopPropagation();
                            currentNode = d;

                            // Get click position on the page
                            let x = event.pageX || event.clientX;
                            let y = event.pageY || event.clientY;

                            // Show menu temporarily to measure it
                            contextMenu.style.display = 'block';
                            contextMenu.style.visibility = 'hidden';

                            // Get menu dimensions
                            const menuWidth = contextMenu.offsetWidth;
                            const menuHeight = contextMenu.offsetHeight;

                            // Get viewport dimensions
                            const viewportWidth = window.innerWidth;
                            const viewportHeight = window.innerHeight;

                            // Adjust horizontal position if menu would overflow right edge
                            if (x + menuWidth > viewportWidth) {
                                x = viewportWidth - menuWidth - 10; // 10px padding from edge
                            }
                            // Ensure menu doesn't go off left edge
                            if (x < 10) {
                                x = 10;
                            }

                            // Adjust vertical position if menu would overflow bottom edge
                            if (y + menuHeight > viewportHeight) {
                                y = viewportHeight - menuHeight - 10; // 10px padding from edge
                            }
                            // Ensure menu doesn't go off top edge
                            if (y < 10) {
                                y = 10;
                            }

                            // Position and show menu
                            contextMenu.style.left = x + 'px';
                            contextMenu.style.top = y + 'px';
                            contextMenu.style.visibility = 'visible';
                        }
                    })
                    .style("cursor", d => d.type === "page" ? "pointer" : "default");

                node.append("circle")
                    .attr("r", 5)
                    .attr("fill", d => d.type === "tag" ? "#d1d5db" : "#9ca3af")  // Light gray for tags
                    .attr("stroke", d => d.type === "tag" ? "#9ca3af" : "#6b7280")
                    .attr("stroke-width", 1);

                nodeText = node.append("text")
                    .attr("dy", 18)
                    .text(d => d.name)
                    .style("font-size", "11px")
                    .style("fill", d => d.type === "tag" ? "#9ca3af" : "#37352f")  // Light gray for tags
                    .style("opacity", 1.0);  // Start fully visible

                let hasZoomed = false;

                simulation.on("tick", () => {
                    link
                        .attr("x1", d => d.source.x)
                        .attr("y1", d => d.source.y)
                        .attr("x2", d => d.target.x)
                        .attr("y2", d => d.target.y);

                    node.attr("transform", d => `translate(${d.x},${d.y})`);
                });

                // Auto-zoom to fit all nodes after simulation stabilizes
                simulation.on("end", () => {
                    if (!hasZoomed && data.nodes.length > 0) {
                        hasZoomed = true;
                        zoomToFit();
                    }
                });

                // Also zoom after initial layout (around 1 second)
                setTimeout(() => {
                    if (!hasZoomed && data.nodes.length > 0) {
                        hasZoomed = true;
                        zoomToFit();
                    }
                }, 1000);

                function zoomToFit() {
                    // Calculate bounds of all nodes
                    const nodes = data.nodes;
                    if (nodes.length === 0) return;

                    let minX = Infinity, maxX = -Infinity;
                    let minY = Infinity, maxY = -Infinity;

                    nodes.forEach(d => {
                        if (d.x < minX) minX = d.x;
                        if (d.x > maxX) maxX = d.x;
                        if (d.y < minY) minY = d.y;
                        if (d.y > maxY) maxY = d.y;
                    });

                    // Add padding
                    const padding = 100;
                    const boundsWidth = maxX - minX + padding * 2;
                    const boundsHeight = maxY - minY + padding * 2;
                    const centerX = (minX + maxX) / 2;
                    const centerY = (minY + maxY) / 2;

                    // Calculate scale to fit
                    const scale = Math.min(
                        width / boundsWidth,
                        height / boundsHeight,
                        2.0  // Max zoom level
                    );

                    // Calculate translation
                    const translateX = width / 2 - scale * centerX;
                    const translateY = height / 2 - scale * centerY;

                    // Apply zoom transform with animation
                    svg.transition()
                        .duration(750)
                        .call(
                            d3.zoom().transform,
                            d3.zoomIdentity.translate(translateX, translateY).scale(scale)
                        );
                }

                function drag(simulation) {
                    function dragstarted(event) {
                        if (!event.active) simulation.alphaTarget(0.1).restart();  // Reduced from 0.3 for smoother movement
                        event.subject.fx = event.subject.x;
                        event.subject.fy = event.subject.y;
                    }

                    function dragged(event) {
                        event.subject.fx = event.x;
                        event.subject.fy = event.y;
                    }

                    function dragended(event) {
                        if (!event.active) simulation.alphaTarget(0);
                        event.subject.fx = null;
                        event.subject.fy = null;
                    }

                    return d3.drag()
                        .on("start", dragstarted)
                        .on("drag", dragged)
                        .on("end", dragended);
                }

                // Handle window resize - just update viewport, don't rescale nodes
                window.addEventListener('resize', () => {
                    const newWidth = window.innerWidth;
                    const newHeight = window.innerHeight;
                    svg.attr("width", newWidth).attr("height", newHeight)
                       .attr("viewBox", [0, 0, newWidth, newHeight]);
                });

                // Context menu button handlers
                openNotionBtn.addEventListener('click', (event) => {
                    event.stopPropagation();
                    if (currentNode && currentNode.url) {
                        // Send message to Swift to open URL in default browser
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.openURL) {
                            window.webkit.messageHandlers.openURL.postMessage(currentNode.url);
                        } else {
                            // Fallback for platforms without message handler
                            window.open(currentNode.url, '_blank');
                        }
                    }
                    contextMenu.style.display = 'none';
                    contextMenu.style.visibility = 'visible';
                });

                localGraphBtn.addEventListener('click', (event) => {
                    event.stopPropagation();
                    // TODO: Implement local graph view
                    // For now, just hide the menu
                    contextMenu.style.display = 'none';
                    contextMenu.style.visibility = 'visible';
                });

                // Hide menu when clicking elsewhere
                document.addEventListener('click', (event) => {
                    if (contextMenu.style.display === 'block' && !contextMenu.contains(event.target)) {
                        contextMenu.style.display = 'none';
                        contextMenu.style.visibility = 'visible';
                    }
                });

                // Hide menu when pressing Escape
                document.addEventListener('keydown', (event) => {
                    if (event.key === 'Escape' && contextMenu.style.display === 'block') {
                        contextMenu.style.display = 'none';
                        contextMenu.style.visibility = 'visible';
                    }
                });
            </script>
        </body>
        </html>
        """
}

// MARK: - macOS Implementation
#if os(macOS)
struct D3WebView: NSViewRepresentable {
    let nodes: [GraphNode]
    let links: [GraphLink]

    func makeNSView(context: Context) -> WKWebView {
        // Configure WebView for better debugging and no caching
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        // Add message handler for opening URLs
        configuration.userContentController.add(context.coordinator, name: "openURL")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        // Enable developer tools
        #if DEBUG
        webView.setValue(true, forKey: "drawsBackground")
        #endif

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Clear any existing content first
        nsView.loadHTMLString("", baseURL: nil)

        // Small delay to ensure clean slate, then load new content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let html = generateHTML(nodes: nodes, links: links)
            nsView.loadHTMLString(html, baseURL: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Graph loaded
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "openURL", let urlString = message.body as? String {
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
#else
// Custom WKWebView that ignores safe area insets
class FullscreenWKWebView: WKWebView {
    override var safeAreaInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Force the scroll view to match our bounds exactly
        scrollView.frame = bounds
    }

    override var intrinsicContentSize: CGSize {
        return UIScreen.main.bounds.size
    }
}

// MARK: - iOS Implementation
struct D3WebView: UIViewRepresentable {
    let nodes: [GraphNode]
    let links: [GraphLink]

    func makeUIView(context: Context) -> FullscreenWKWebView {
        // Configure WebView for better debugging and no caching
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        // Add message handler for opening URLs
        configuration.userContentController.add(context.coordinator, name: "openURL")

        // Use custom fullscreen webview that ignores safe areas
        let webView = FullscreenWKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        return webView
    }

    func updateUIView(_ uiView: FullscreenWKWebView, context: Context) {
        // Clear any existing content first
        uiView.loadHTMLString("", baseURL: nil)

        // Small delay to ensure clean slate, then load new content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let html = generateHTML(nodes: nodes, links: links)
            uiView.loadHTMLString(html, baseURL: nil)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: FullscreenWKWebView, context: Context) -> CGSize? {
        // Return the screen size to ensure fullscreen
        return CGSize(width: proposal.width ?? UIScreen.main.bounds.width,
                     height: proposal.height ?? UIScreen.main.bounds.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Graph loaded
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "openURL", let urlString = message.body as? String {
                if let url = URL(string: urlString) {
                    #if os(iOS)
                    UIApplication.shared.open(url)
                    #endif
                }
            }
        }
    }
}
#endif
