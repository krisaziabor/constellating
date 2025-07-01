import Foundation

struct ArenaBlock: Codable {
    let id: Int
    let title: String?
    let source: BlockSource?
    
    struct BlockSource: Codable {
        let url: String?
    }
}