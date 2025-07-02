import Foundation
import SwiftUI

struct DiscoveredURL {
    let url: String
    let count: Int
    let isTopResult: Bool
}

struct ClassifiedBlock {
    let block: ArenaBlock
    let isExact: Bool
}

struct MatchResult {
    let exact: Int
    let inexact: Int
    let classifiedBlocks: [ClassifiedBlock]
}

struct ArenaBlockSearchView: View {
    @State private var inputURL: String = ""
    @State private var isLoading: Bool = false
    @State private var exactCount: Int = 0
    @State private var inexactCount: Int = 0
    @State private var errorMessage: String?
    @State private var foundChannels: [ArenaChannel] = []
    @State private var discoveredURLs: [DiscoveredURL] = []
    @State private var classifiedBlocks: [ClassifiedBlock] = []
    @State private var isBlocksExpanded: Bool = false
    @State private var isChannelsExpanded: Bool = false
    @State private var isOtherWebsitesExpanded: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Are.na Block URL Matcher")
                    .font(.title)
                TextField("Enter a URL", text: $inputURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                Button(action: searchBlocks) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Search")
                    }
                }
                .disabled(inputURL.isEmpty || isLoading)
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                HStack {
                    Text("Exact matches: \(exactCount)")
                    Text("Inexact matches: \(inexactCount)")
                }
                .font(.headline)

                // --- Collapsible Sections ---
                VStack(spacing: 16) {
                    // Blocks Section
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isBlocksExpanded.toggle()
                            }
                        }, label: {
                            HStack {
                                Image(systemName: isBlocksExpanded ? "chevron.down" : "chevron.right")
                                    .foregroundColor(.primary)
                                Text("Blocks (\(classifiedBlocks.count))")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        })
                        .buttonStyle(PlainButtonStyle())

                        if isBlocksExpanded, !classifiedBlocks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                let exactBlocks = classifiedBlocks.filter(\.isExact)
                                let inexactBlocks = classifiedBlocks.filter { !$0.isExact }

                                if !exactBlocks.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Exact Matches (\(exactBlocks.count))")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.green)

                                        ForEach(
                                            Array(exactBlocks.enumerated()),
                                            id: \.element.block.id
                                        ) { _, classifiedBlock in
                                            BlockRow(classifiedBlock: classifiedBlock)
                                        }
                                    }
                                }

                                if !inexactBlocks.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Inexact Matches (\(inexactBlocks.count))")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.orange)

                                        ForEach(
                                            Array(inexactBlocks.enumerated()),
                                            id: \.element.block.id
                                        ) { _, classifiedBlock in
                                            BlockRow(classifiedBlock: classifiedBlock)
                                        }
                                    }
                                }
                            }
                            .padding(.leading, 20)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    // Channels Section
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isChannelsExpanded.toggle()
                            }
                        }, label: {
                            HStack {
                                Image(systemName: isChannelsExpanded ? "chevron.down" : "chevron.right")
                                    .foregroundColor(.primary)
                                Text("Channels (\(foundChannels.count))")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        })
                        .buttonStyle(PlainButtonStyle())

                        if isChannelsExpanded, !foundChannels.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(foundChannels, id: \.slug) { channel in
                                    Button(action: {
                                        let arenaURL = "https://are.na/\(channel.ownerSlug ?? "user")/\(channel.slug)"
                                        if let url = URL(string: arenaURL) {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }, label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(channel.title ?? channel.slug)
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(.primary)
                                            Text("Slug: \(channel.slug)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            if let username = channel.username {
                                                Text("User: \(username)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(6)
                                        .background(Color(NSColor.windowBackgroundColor))
                                        .cornerRadius(6)
                                    })
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.leading, 20)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)

                    // Other Websites Section
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isOtherWebsitesExpanded.toggle()
                            }
                        }, label: {
                            HStack {
                                Image(systemName: isOtherWebsitesExpanded ? "chevron.down" : "chevron.right")
                                    .foregroundColor(.primary)
                                Text("Other Websites (\(discoveredURLs.count))")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        })
                        .buttonStyle(PlainButtonStyle())

                        if isOtherWebsitesExpanded, !discoveredURLs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(discoveredURLs.enumerated()), id: \.element.url) { _, discoveredURL in
                                    HStack {
                                        Button(action: {
                                            if let url = URL(string: discoveredURL.url) {
                                                NSWorkspace.shared.open(url)
                                            }
                                        }, label: {
                                            HStack {
                                                Text(discoveredURL.url)
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                                if discoveredURL.isTopResult {
                                                    Image(systemName: "star.fill")
                                                        .foregroundColor(.yellow)
                                                        .font(.caption2)
                                                }
                                                if discoveredURL.count > 1 {
                                                    Text("\(discoveredURL.count)")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 2)
                                                        .background(Color.secondary.opacity(0.2))
                                                        .cornerRadius(4)
                                                }
                                            }
                                        })
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(4)
                                    .background(Color(NSColor.windowBackgroundColor))
                                    .cornerRadius(4)
                                }
                            }
                            .padding(.leading, 20)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding(.top)

                Spacer()
            }
            .padding()
        }
    }

    func searchBlocks() {
        guard let url = URL(string: inputURL) else {
            errorMessage = "Invalid URL"
            return
        }
        resetSearchState()
        let domainTitle = stripToDomain(from: url)

        Task {
            do {
                let searchResults = try await performSearch(domainTitle: domainTitle, originalURL: inputURL)
                updateUI(with: searchResults)
            } catch {
                handleSearchError(error)
            }
        }
    }

    private func resetSearchState() {
        errorMessage = nil
        isLoading = true
        exactCount = 0
        inexactCount = 0
        foundChannels = []
        discoveredURLs = []
        classifiedBlocks = []
    }

    private func performSearch(domainTitle: String, originalURL: String) async throws -> SearchResults {
        print("🔍 Searching for domain: '\(domainTitle)'")
        let blocks = try await fetchArenaBlocks(for: domainTitle)
        print("📦 Found \(blocks.count) blocks")

        let matchCounts = countMatches(in: blocks, against: originalURL)
        print("✅ Exact matches: \(matchCounts.exact), Inexact matches: \(matchCounts.inexact)")

        let channels = try await fetchAllChannels(from: blocks)
        print("📺 Found \(channels.count) unique channels")

        let urlFrequency = try await fetchURLFrequency(from: channels)
        let discoveredURLs = createDiscoveredURLs(from: urlFrequency)
        print("🌐 Discovered \(discoveredURLs.count) unique URLs")

        return SearchResults(
            exactCount: matchCounts.exact,
            inexactCount: matchCounts.inexact,
            channels: channels,
            discoveredURLs: discoveredURLs,
            classifiedBlocks: matchCounts.classifiedBlocks
        )
    }

    private func countMatches(
        in blocks: [ArenaBlock],
        against originalURL: String
    ) -> MatchResult {
        var exact = 0
        var inexact = 0
        var classifiedBlocks: [ClassifiedBlock] = []

        for block in blocks {
            if let sourceURL = block.source?.url {
                let (matches, isExact) = urlsMatch(originalURL, sourceURL)
                if matches {
                    classifiedBlocks.append(ClassifiedBlock(block: block, isExact: isExact))
                    if isExact { exact += 1 } else { inexact += 1 }
                }
            }
        }

        return MatchResult(exact: exact, inexact: inexact, classifiedBlocks: classifiedBlocks)
    }

    private func fetchAllChannels(from blocks: [ArenaBlock]) async throws -> [ArenaChannel] {
        var allChannels: [ArenaChannel] = []

        for block in blocks {
            let channels = try await fetchChannelsForBlock(blockID: block.id)
            allChannels.append(contentsOf: channels)
        }

        return Dictionary(grouping: allChannels, by: { $0.slug }).compactMap(\.value.first)
    }

    private func fetchURLFrequency(from channels: [ArenaChannel]) async throws -> [String: Int] {
        var urlFrequency: [String: Int] = [:]

        for channel in channels {
            do {
                let channelBlocks = try await fetchChannelContents(slug: channel.slug)
                print("📍 Channel '\(channel.slug)' has \(channelBlocks.count) link blocks")
                for block in channelBlocks {
                    if let sourceURL = block.source?.url {
                        urlFrequency[sourceURL, default: 0] += 1
                        print("🔗 Found URL: \(sourceURL)")
                    }
                }
            } catch {
                print("⚠️ Failed to fetch contents for channel '\(channel.slug)': \(error)")
                continue // Skip channels that can't be fetched
            }
        }

        print("📊 Total unique URLs found: \(urlFrequency.count)")
        return urlFrequency
    }

    private func createDiscoveredURLs(from urlFrequency: [String: Int]) -> [DiscoveredURL] {
        let sortedURLs = urlFrequency.sorted { $0.value > $1.value }
        let maxCount = sortedURLs.first?.value ?? 0

        return sortedURLs.map { url, count in
            DiscoveredURL(url: url, count: count, isTopResult: count == maxCount && maxCount > 1)
        }
    }

    @MainActor
    private func updateUI(with results: SearchResults) {
        exactCount = results.exactCount
        inexactCount = results.inexactCount
        foundChannels = results.channels
        discoveredURLs = results.discoveredURLs
        classifiedBlocks = results.classifiedBlocks
        isLoading = false
    }

    @MainActor
    private func handleSearchError(_ error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
    }
}

// MARK: - Networking & Utilities

func fetchArenaBlocks(for title: String) async throws -> [ArenaBlock] {
    var allBlocks: [ArenaBlock] = []
    var page = 1
    var totalPages = 1
    let session = URLSession.shared
    while page <= totalPages {
        let urlString =
            "https://api.are.na/v2/search/blocks?q="
                + (title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
                + "&page=\(page)"
        guard let url = URL(string: urlString) else { break }
        let (data, _) = try await session.data(from: url)
        let decoded = try JSONDecoder().decode(ArenaBlockSearchResponse.self, from: data)
        allBlocks.append(contentsOf: decoded.blocks)
        totalPages = decoded.totalPages
        page += 1
    }
    return allBlocks
}

struct ArenaBlockSearchResponse: Decodable {
    let blocks: [ArenaBlock]
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case blocks
        case totalPages = "total_pages"
    }
}

func stripToDomain(from url: URL) -> String {
    // Extract just the domain name (without www, protocol, or path)
    let host = url.host?.replacingOccurrences(of: "www.", with: "") ?? url.absoluteString
    let comps = host.components(separatedBy: ".")
    return comps.first ?? host
}

func urlsMatch(_ url1: String, _ url2: String) -> (matches: Bool, isExact: Bool) {
    // Compare URLs flexibly: ignore protocol, www, and detect path differences
    func normalize(_ urlStr: String) -> (domain: String, path: String) {
        guard let url = URL(string: urlStr) else { return (urlStr, "") }
        let host = url.host?.replacingOccurrences(of: "www.", with: "") ?? urlStr
        let comps = host.components(separatedBy: ".")
        let domain = comps.first ?? host
        let path = url.path
        return (domain, path)
    }
    let n1 = normalize(url1)
    let n2 = normalize(url2)
    let matches = n1.domain == n2.domain
    let isExact = matches && (n1.path == n2.path || n2.path.isEmpty)
    return (matches, isExact)
}

// MARK: - Fetch channels for a block

func fetchChannelsForBlock(blockID: Int) async throws -> [ArenaChannel] {
    var allChannels: [ArenaChannel] = []
    var page = 1
    var totalPages = 1
    let session = URLSession.shared
    while page <= totalPages {
        let urlString = "https://api.are.na/v2/blocks/\(blockID)/channels?page=\(page)"
        guard let url = URL(string: urlString) else { break }
        let (data, _) = try await session.data(from: url)
        let decoded = try JSONDecoder().decode(ArenaChannelSearchResponse.self, from: data)
        allChannels.append(contentsOf: decoded.channels)
        totalPages = decoded.totalPages
        page += 1
    }
    return allChannels
}

// MARK: - Fetch channel contents

func fetchChannelContents(slug: String) async throws -> [ArenaBlock] {
    let session = URLSession.shared
    let urlString = "https://api.are.na/v2/channels/\(slug)/contents"
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }

    let (data, _) = try await session.data(from: url)
    let decoded = try JSONDecoder().decode(ArenaChannelContentsResponse.self, from: data)

    // Filter for blocks with class "Link" that have source URLs
    let linkBlocks = decoded.contents.filter { block in
        block.blockClass == "Link" && block.source?.url != nil
    }

    return linkBlocks
}

struct ArenaChannelSearchResponse: Decodable {
    let channels: [ArenaChannel]
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case channels
        case totalPages = "total_pages"
    }
}

struct ArenaChannelContentsResponse: Decodable {
    let contents: [ArenaBlock]
    let length: Int?
    let page: Int?
    let per: Int?

    enum CodingKeys: String, CodingKey {
        case contents
        case length
        case page
        case per
    }
}

private struct SearchResults {
    let exactCount: Int
    let inexactCount: Int
    let channels: [ArenaChannel]
    let discoveredURLs: [DiscoveredURL]
    let classifiedBlocks: [ClassifiedBlock]
}

struct BlockRow: View {
    let classifiedBlock: ClassifiedBlock

    var body: some View {
        Button(action: {
            let arenaURL = "https://are.na/block/\(classifiedBlock.block.id)"
            if let url = URL(string: arenaURL) {
                NSWorkspace.shared.open(url)
            }
        }, label: {
            VStack(alignment: .leading, spacing: 2) {
                if let title = classifiedBlock.block.title, !title.isEmpty {
                    Text(title)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.primary)
                } else {
                    Text("Block #\(classifiedBlock.block.id)")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.primary)
                }

                if let sourceURL = classifiedBlock.block.source?.url {
                    Text(sourceURL)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(2)
                }

                HStack {
                    Text("ID: \(classifiedBlock.block.id)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    if classifiedBlock.isExact {
                        Text("EXACT")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(3)
                    } else {
                        Text("INEXACT")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(3)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(6)
        })
        .buttonStyle(PlainButtonStyle())
    }
}

// NOTE: If ArenaBlock or ArenaChannel are not found, ensure Models.swift is in your app target (File Inspector > Target
// Membership).
