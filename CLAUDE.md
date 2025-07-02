# Claude Code Context: Constellating v1 - Are.na Search Tool

## Project Vision

I'm building "Constellating" - a macOS app that helps designers discover connections between their inspirations using Are.na's community-curated collections. Version 1 focuses solely on the Are.na search functionality. The name represents the ongoing action of connecting design elements to form larger creative constellations.

## Current Development Focus (v1)

- [x] Project structure setup
- [ ] Are.na API integration
- [ ] SQLite caching system
- [ ] Search flow implementation
- [ ] URL/Channel dual view
- [ ] Channel preview cards
- [ ] Rate limit handling
- [ ] Cache management (6-month freshness)

## Are.na API Workflow

### Complete Search Process

1. Input: [https://example.com/blog/post](https://example.com/blog/post)
2. Strip to domain: "example"
3. Search blocks: GET /v2/search/blocks?q=example&page=1...n
4. For each matching block (check .blocks[].source.url):
    - GET /v2/blocks/{id}/channels?page=1...n
5. For each channel found:
    - GET /v2/channels/{slug}/contents
    - Extract all class:"Link" blocks
    - Count URL occurrences
6. Present ranked results

### URL Matching Rules

- **Strip URL**: Extract domain name only (example.com → example)
- **Flexible Matching**: Accept www/no-www, http/https
- **Inexact Matches**: Flag URLs with extra path segments
- **Example**: Searching "example.com" matches:
  - ✅ Exact: <https://example.com>, <http://www.example.com>
  - ⚠️ Inexact: <https://example.com/blog/post>

### API Details

- **Base URL**: <https://api.are.na/v2>
- **Auth**: None required for GET requests
- **Rate Limit**: 60 requests/minute
- **Pagination**: Check `total_pages` in responses

### Channel Preview Data

When hovering a channel, fetch:

GET /v2/channels/{slug}/thumb → title, user.full_name, length GET /v2/channels/{slug}/connections → connection count First 6 thumbnails from contents[].image.thumb.url

## Business Rules

### Caching

- **Fresh**: < 6 months old
- **Stale**: > 6 months old (show warning, auto-refresh unless user opts out)
- **Re-index**: User can manually trigger anytime

### Large Channel Handling

- Fetch first 50 URLs automatically
- Show "Load more" option for channels with more content
- User controls continued fetching

### Error Handling

- **401 Unauthorized**: Skip private channels silently
- **Rate Limit**: Queue requests, show progress
- **Network Errors**: Fall back to cached data if available

### Duplicate Prevention

- Within a single channel, count each unique URL only once
- Across channels, sum occurrences for ranking

## Database Schema

```sql
-- Core tables for v1
searches → Track search history and cache age
blocks → Store Are.na block data
channels → Cache channel metadata
block_channels → Many-to-many relationships
channel_urls → URLs found in channels with occurrence counts
```

## Code Architecture

### Key Services

swift

```swift
// API communication with rate limiting
class ArenaAPIService {
    func searchBlocks(query: String) async throws -> [Block]
    func getBlockChannels(blockId: String) async throws -> [Channel]
    func getChannelContents(slug: String) async throws -> [URL]
}

// Cache management
class CacheManager {
    func getCachedSearch(url: String) -> CachedSearch?
    func isStale(search: CachedSearch) -> Bool
    func saveSearch(url: String, results: SearchResults)
}

// URL processing
class URLProcessor {
    func stripToDomain(url: URL) -> String
    func compareURLs(_ url1: String, _ url2: String) -> MatchResult
}
```

### View Models

```swift
class SearchViewModel: ObservableObject {
    @Published var searchResults: SearchResults?
    @Published var isLoading: Bool = false
    @Published var viewMode: ViewMode = .urls // .urls or .channels
    
    func search(url: String) async
    func reindex(url: String) async
    func loadMoreResults(for channel: Channel) async
}
```

## UI Components

### Main Views

1. **SearchView**: Input field, search button, re-index option
2. **ResultsView**: Toggle between URL/Channel views
3. **ChannelPreviewCard**: Hover state with metadata
4. **ProgressView**: Beautiful loading states

### Channel Actions

- **Click**: Open in browser
- **Context Menu**:
  - View inner channels (contents)
  - View outer channels (connections)

## Common Queries for Claude

1. **API Integration** "Help me implement pagination handling for Are.na API calls with rate limiting"
2. **URL Processing** "Create a URL matching system that handles www/protocol variations and detects path differences"
3. **Caching Logic** "Implement 6-month cache staleness checking with user-controlled refresh"
4. **UI Components** "Build a channel preview card that loads thumbnails lazily"
5. **Database Queries** "Write efficient SQL to get ranked URLs by occurrence across channels"

## Current Priorities

1. Get basic search flow working end-to-end
2. Implement proper rate limiting
3. Build out caching system
4. Create beautiful UI with smooth animations
5. Handle edge cases (private channels, large datasets)

## Code Quality Commands

**IMPORTANT**: After making any code changes, always run these commands before building:

```bash
# Format code with SwiftFormat
swiftformat .

# Check for linting issues
swiftlint
```

### Code Quality Guidelines

- When you do swiftlint and see violations, fix them and run the command again until the violations are all gone.

## Remember

- v1 is Are.na search only (no Eagle/Sanity/mobile yet)
- Cache aggressively - API calls are expensive
- Make loading states beautiful and informative
- Handle errors gracefully
- "Inexact" matches need clear visual indication
- User controls the experience (refresh, load more, etc.)

## Future v2 Features (Not Current Focus)

- Eagle integration
- Sanity CMS sync
- iOS/iPadOS helper apps
- Safari extension
- Script automation with beautiful logging

