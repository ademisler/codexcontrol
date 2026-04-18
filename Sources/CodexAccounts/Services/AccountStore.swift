import Foundation

struct AccountBootstrapResult {
    let accounts: [StoredAccount]
    let didBootstrap: Bool
    let importedCount: Int
}

struct AccountStore {
    private static let currentVersion = 1

    func loadAccounts() throws -> [StoredAccount] {
        guard FileManager.default.fileExists(atPath: FileLocations.accountsFile.path) else {
            return []
        }

        let data = try Data(contentsOf: FileLocations.accountsFile)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let stored = try decoder.decode(StoredAccountList.self, from: data)
        return self.sorted(stored.accounts)
    }

    func saveAccounts(_ accounts: [StoredAccount]) throws {
        try FileLocations.ensureDirectories()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(StoredAccountList(version: Self.currentVersion, accounts: self.sorted(accounts)))
        try data.write(to: FileLocations.accountsFile, options: .atomic)
    }

    func loadOrBootstrap(importer: CodexBarImportService) throws -> AccountBootstrapResult {
        let existing = try self.loadAccounts()
        guard existing.isEmpty else {
            return AccountBootstrapResult(accounts: existing, didBootstrap: false, importedCount: 0)
        }

        let imported = importer.importAccounts()
        if imported.isEmpty {
            return AccountBootstrapResult(accounts: [], didBootstrap: false, importedCount: 0)
        }

        try self.saveAccounts(imported)
        return AccountBootstrapResult(accounts: self.sorted(imported), didBootstrap: true, importedCount: imported.count)
    }

    func merge(existing: [StoredAccount], incoming: [StoredAccount]) -> [StoredAccount] {
        var result = existing

        for candidate in incoming {
            if let index = result.firstIndex(where: { $0.matches(candidate) }) {
                var merged = result[index]
                merged.merge(from: candidate)
                result[index] = merged
            } else {
                result.append(candidate)
            }
        }

        return self.sorted(result)
    }

    private func sorted(_ accounts: [StoredAccount]) -> [StoredAccount] {
        accounts.sorted {
            let left = $0.displayName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let right = $1.displayName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            return left < right
        }
    }
}
