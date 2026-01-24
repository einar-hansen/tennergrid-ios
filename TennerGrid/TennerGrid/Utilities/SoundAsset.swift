import Foundation

/// Represents all sound effects available in the app
enum SoundAsset: String, CaseIterable {
    /// General button tap and UI interaction sound
    case click = "click.mp3"

    /// Error or invalid move sound
    case error = "error.mp3"

    /// Success and completion sound
    case success = "success.mp3"

    /// Alternative button tap sound for secondary actions
    case buttonTap = "button_tap.mp3"

    // MARK: - Properties

    /// The filename of the sound asset
    var filename: String {
        rawValue
    }

    /// The full path to the sound file in the bundle
    var url: URL? {
        guard let path = Bundle.main.path(
            forResource: filename.replacingOccurrences(of: ".mp3", with: ""),
            ofType: "mp3",
            inDirectory: "Sounds"
        ) else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }

    /// Check if the sound file exists in the bundle
    var exists: Bool {
        url != nil
    }

    // MARK: - Validation

    /// Validate that all sound assets exist in the bundle
    static func validateAssets() -> [SoundAsset] {
        allCases.filter { !$0.exists }
    }
}

// MARK: - CustomStringConvertible

extension SoundAsset: CustomStringConvertible {
    var description: String {
        filename
    }
}
