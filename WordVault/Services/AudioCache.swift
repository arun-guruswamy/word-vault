import Foundation
import AVFoundation

actor AudioCache {
    static let shared = AudioCache()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 50 * 1024 * 1024 // 50MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    private init() {
        // Get the cache directory URL
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("AudioCache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Clean up old cache files on init
        Task {
            await cleanupCache()
        }
    }
    
    func getAudio(for url: String) async throws -> Data {
        let fileName = url.replacingOccurrences(of: "/", with: "_")
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        // Check if file exists and is not expired
        if fileManager.fileExists(atPath: fileURL.path) {
            let attributes = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
            if let modificationDate = attributes.contentModificationDate,
               Date().timeIntervalSince(modificationDate) < maxCacheAge {
                return try Data(contentsOf: fileURL)
            }
        }
        
        // If not in cache or expired, download and cache
        let audioData = try await DictionaryService.shared.fetchAudio(from: url)
        try audioData.write(to: fileURL)
        
        // Clean up cache if needed
        await cleanupCache()
        
        return audioData
    }
    
    private func cleanupCache() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            // Sort files by modification date (oldest first)
            let sortedFiles = files.sorted { file1, file2 in
                let date1 = try? file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                let date2 = try? file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                return date1 ?? Date.distantPast < date2 ?? Date.distantPast
            }
            
            // Calculate total cache size
            var totalSize: Int64 = 0
            for file in sortedFiles {
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attributes.fileSize ?? 0)
            }
            
            // Remove oldest files until we're under the max size
            for file in sortedFiles {
                if totalSize <= maxCacheSize {
                    break
                }
                
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                let fileSize = Int64(attributes.fileSize ?? 0)
                try fileManager.removeItem(at: file)
                totalSize -= fileSize
            }
            
            // Remove expired files
            for file in files {
                let attributes = try file.resourceValues(forKeys: [.contentModificationDateKey])
                if let modificationDate = attributes.contentModificationDate,
                   Date().timeIntervalSince(modificationDate) >= maxCacheAge {
                    try fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("Error cleaning up cache: \(error)")
        }
    }
    
    func clearCache() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [])
            for file in files {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
} 