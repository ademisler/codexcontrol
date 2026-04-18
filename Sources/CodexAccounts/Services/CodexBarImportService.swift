import Foundation

private struct ImportedCodexBarAccountList: Decodable {
    let accounts: [ImportedCodexBarAccount]
}

private struct ImportedCodexBarAccount: Decodable {
    let email: String
    let providerAccountID: String?
    let workspaceLabel: String?
    let managedHomePath: String
    let createdAt: Double
    let updatedAt: Double
    let lastAuthenticatedAt: Double?
}

struct CodexBarImportService {
    func importAccounts() -> [StoredAccount] {
        AccountStore().merge(existing: [], incoming: self.importCodexBarManagedAccounts())
    }

    private func importCodexBarManagedAccounts() -> [StoredAccount] {
        guard FileManager.default.fileExists(atPath: FileLocations.codexBarManagedAccountsFile.path),
              let data = try? Data(contentsOf: FileLocations.codexBarManagedAccountsFile),
              let decoded = try? JSONDecoder().decode(ImportedCodexBarAccountList.self, from: data)
        else {
            return []
        }

        return decoded.accounts.map { account in
            let actualIdentity = try? CodexAPI.loadIdentity(codexHomePath: account.managedHomePath)
            let nickname: String?
            if let workspaceLabel = account.workspaceLabel?.trimmingCharacters(in: .whitespacesAndNewlines),
               !workspaceLabel.isEmpty,
               workspaceLabel.caseInsensitiveCompare("Personal") != .orderedSame
            {
                nickname = workspaceLabel
            } else {
                nickname = nil
            }

            return StoredAccount(
                id: UUID(),
                nickname: nickname,
                emailHint: actualIdentity?.email ?? StoredAccount.normalizeEmail(account.email),
                providerAccountID: actualIdentity?.providerAccountID ?? account.providerAccountID,
                codexHomePath: account.managedHomePath,
                source: .importedCodexBar,
                createdAt: Date(timeIntervalSince1970: account.createdAt),
                updatedAt: Date(timeIntervalSince1970: account.updatedAt),
                lastAuthenticatedAt: account.lastAuthenticatedAt.map(Date.init(timeIntervalSince1970:)))
        }
    }
}
