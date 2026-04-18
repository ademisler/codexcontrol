import Foundation

struct AccountHomeMigrationService {
    func migrateImportedAccounts(_ accounts: [StoredAccount]) throws -> [StoredAccount] {
        try FileLocations.ensureDirectories()

        return try accounts.map { account in
            guard account.source == .importedCodexBar else {
                return account
            }

            let sourceURL = URL(fileURLWithPath: account.codexHomePath, isDirectory: true)
            guard FileManager.default.fileExists(atPath: sourceURL.path) else {
                return account
            }

            let targetURL = FileLocations.managedHomesDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)

            try FileManager.default.copyItem(at: sourceURL, to: targetURL)

            var migrated = account
            migrated.codexHomePath = targetURL.path
            migrated.source = .managedByApp
            migrated.updatedAt = Date()
            return migrated
        }
    }
}
