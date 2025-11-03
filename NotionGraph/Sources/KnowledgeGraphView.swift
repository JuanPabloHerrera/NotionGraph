import SwiftUI
import WebKit

struct KnowledgeGraphView: View {
    let nodes: [GraphNode]
    let links: [GraphLink]

    var body: some View {
        D3WebView(nodes: nodes, links: links)
            .ignoresSafeArea()
    }
}

#if os(macOS)
struct D3WebView: NSViewRepresentable {
    let nodes: [GraphNode]
    let links: [GraphLink]

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        loadGraph(in: nsView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Graph loaded successfully")
        }
    }

    private func loadGraph(in webView: WKWebView) {
        let html = generateHTML()
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func generateHTML() -> String {
        let graphData = GraphData(nodes: nodes, links: links)

        // Safely encode the graph data
        guard let jsonData = try? JSONEncoder().encode(graphData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            // Return empty graph if encoding fails
            return generateHTMLWithData("{\"nodes\":[],\"links\":[]}")
        }

        return generateHTMLWithData(jsonString)
    }

    private func generateHTMLWithData(_ jsonString: String) -> String {

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    overflow: hidden;
                    background: #fafafa;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                }
                #graph {
                    width: 100vw;
                    height: 100vh;
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
                    stroke: #e5e7eb;
                    stroke-opacity: 1;
                    stroke-width: 1.5px;
                }
            </style>
        </head>
        <body>
            <div id="graph"></div>
            <script src="https://d3js.org/d3.v7.min.js"></script>
            <script>
                const data = \(jsonString);

                const width = window.innerWidth;
                const height = window.innerHeight;

                // Notion-style light gray color palette
                const color = d3.scaleOrdinal([
                    "#e5e7eb", "#d1d5db", "#c7ccd1", "#b8bdc3", "#e8eaed",
                    "#dfe2e6", "#d4d7db", "#caced3", "#e3e5e8", "#dadde1"
                ]);

                const svg = d3.select("#graph")
                    .append("svg")
                    .attr("width", width)
                    .attr("height", height)
                    .attr("viewBox", [0, 0, width, height]);

                // Add zoom behavior
                const g = svg.append("g");

                svg.call(d3.zoom()
                    .extent([[0, 0], [width, height]])
                    .scaleExtent([0.1, 8])
                    .on("zoom", (event) => {
                        g.attr("transform", event.transform);
                    }));

                const simulation = d3.forceSimulation(data.nodes)
                    .force("link", d3.forceLink(data.links).id(d => d.id).distance(80))
                    .force("charge", d3.forceManyBody().strength(-100))
                    .force("center", d3.forceCenter(width / 2, height / 2))
                    .force("x", d3.forceX(width / 2).strength(0.1))
                    .force("y", d3.forceY(height / 2).strength(0.1))
                    .force("collision", d3.forceCollide().radius(35));

                const link = g.append("g")
                    .selectAll("line")
                    .data(data.links)
                    .join("line")
                    .attr("class", "link");

                const node = g.append("g")
                    .selectAll("g")
                    .data(data.nodes)
                    .join("g")
                    .attr("class", "node")
                    .call(drag(simulation));

                node.append("circle")
                    .attr("r", 6)
                    .attr("fill", d => color(d.group));

                node.append("text")
                    .attr("dy", 18)
                    .text(d => d.name)
                    .style("font-size", "11px")
                    .style("fill", "#37352f");

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
                        if (!event.active) simulation.alphaTarget(0.3).restart();
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
            </script>
        </body>
        </html>
        """
    }
}
#else
struct D3WebView: UIViewRepresentable {
    let nodes: [GraphNode]
    let links: [GraphLink]

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadGraph(in: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Graph loaded successfully")
        }
    }

    private func loadGraph(in webView: WKWebView) {
        let html = generateHTML()
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func generateHTML() -> String {
        let graphData = GraphData(nodes: nodes, links: links)

        // Safely encode the graph data
        guard let jsonData = try? JSONEncoder().encode(graphData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            // Return empty graph if encoding fails
            return generateHTMLWithData("{\"nodes\":[],\"links\":[]}")
        }

        return generateHTMLWithData(jsonString)
    }

    private func generateHTMLWithData(_ jsonString: String) -> String {

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    overflow: hidden;
                    background: #fafafa;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                }
                #graph {
                    width: 100vw;
                    height: 100vh;
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
                    stroke: #e5e7eb;
                    stroke-opacity: 1;
                    stroke-width: 1.5px;
                }
            </style>
        </head>
        <body>
            <div id="graph"></div>
            <script src="https://d3js.org/d3.v7.min.js"></script>
            <script>
                const data = \(jsonString);

                const width = window.innerWidth;
                const height = window.innerHeight;

                // Notion-style light gray color palette
                const color = d3.scaleOrdinal([
                    "#e5e7eb", "#d1d5db", "#c7ccd1", "#b8bdc3", "#e8eaed",
                    "#dfe2e6", "#d4d7db", "#caced3", "#e3e5e8", "#dadde1"
                ]);

                const svg = d3.select("#graph")
                    .append("svg")
                    .attr("width", width)
                    .attr("height", height)
                    .attr("viewBox", [0, 0, width, height]);

                // Add zoom behavior
                const g = svg.append("g");

                svg.call(d3.zoom()
                    .extent([[0, 0], [width, height]])
                    .scaleExtent([0.1, 8])
                    .on("zoom", (event) => {
                        g.attr("transform", event.transform);
                    }));

                const simulation = d3.forceSimulation(data.nodes)
                    .force("link", d3.forceLink(data.links).id(d => d.id).distance(80))
                    .force("charge", d3.forceManyBody().strength(-100))
                    .force("center", d3.forceCenter(width / 2, height / 2))
                    .force("x", d3.forceX(width / 2).strength(0.1))
                    .force("y", d3.forceY(height / 2).strength(0.1))
                    .force("collision", d3.forceCollide().radius(35));

                const link = g.append("g")
                    .selectAll("line")
                    .data(data.links)
                    .join("line")
                    .attr("class", "link");

                const node = g.append("g")
                    .selectAll("g")
                    .data(data.nodes)
                    .join("g")
                    .attr("class", "node")
                    .call(drag(simulation));

                node.append("circle")
                    .attr("r", 8)
                    .attr("fill", d => color(d.group));

                node.append("text")
                    .attr("dy", 20)
                    .text(d => d.name)
                    .style("font-size", "10px")
                    .style("fill", "#ffffff");

                const tooltip = d3.select("#tooltip");

                node.on("touchstart click", function(event, d) {
                    event.preventDefault();
                    tooltip.style("display", "block")
                        .html(`<strong>${d.name}</strong><br/>ID: ${d.id}`)
                        .style("left", (event.pageX + 10) + "px")
                        .style("top", (event.pageY - 10) + "px");

                    d3.select(this).select("circle")
                        .transition()
                        .duration(200)
                        .attr("r", 12);

                    setTimeout(() => {
                        tooltip.style("display", "none");
                        d3.select(this).select("circle")
                            .transition()
                            .duration(200)
                            .attr("r", 8);
                    }, 3000);
                });

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
                        if (!event.active) simulation.alphaTarget(0.3).restart();
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
            </script>
        </body>
        </html>
        """
    }
}
#endif
