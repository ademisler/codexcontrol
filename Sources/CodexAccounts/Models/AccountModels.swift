import Foundation

enum StoredAccountSource: String, Codable, CaseIterable, Sendable {
    case ambient
    case importedCodexBar
    case managedByApp

    var displayName: String {
        switch self {
        case .ambient:
            "Sistem"
        case .importedCodexBar:
            "CodexBar"
        case .managedByApp:
            "Bu uygulama"
        }
    }

    var ownsFiles: Bool {
        self == .managedByApp
    }
}

struct StoredAccount: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var nickname: String?
    var emailHint: String?
    var providerAccountID: String?
    var codexHomePath: String
    var source: StoredAccountSource
    let createdAt: Date
    var updatedAt: Date
    var lastAuthenticatedAt: Date?

    var displayName: String {
        if let nickname, !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let emailHint, !emailHint.isEmpty {
            return emailHint
        }
        return URL(fileURLWithPath: self.codexHomePath).lastPathComponent
    }

    var normalizedEmailHint: String? {
        Self.normalizeEmail(self.emailHint)
    }

    var standardizedHomePath: String {
        URL(fileURLWithPath: self.codexHomePath, isDirectory: true).standardizedFileURL.path
    }

    func matches(_ other: StoredAccount) -> Bool {
        if let providerAccountID, let otherProviderAccountID = other.providerAccountID,
           providerAccountID == otherProviderAccountID
        {
            return true
        }

        if self.standardizedHomePath == other.standardizedHomePath {
            return true
        }

        if let normalizedEmailHint, normalizedEmailHint == other.normalizedEmailHint {
            return true
        }

        return false
    }

    mutating func merge(from other: StoredAccount) {
        if self.nickname == nil || self.nickname?.isEmpty == true {
            self.nickname = other.nickname
        }
        if self.emailHint == nil || self.emailHint?.isEmpty == true {
            self.emailHint = other.emailHint
        }
        if self.providerAccountID == nil || self.providerAccountID?.isEmpty == true {
            self.providerAccountID = other.providerAccountID
        }
        if other.sourcePriority > self.sourcePriority {
            self.source = other.source
            self.codexHomePath = other.codexHomePath
        }
        self.updatedAt = max(self.updatedAt, other.updatedAt)
        self.lastAuthenticatedAt = max(self.lastAuthenticatedAt ?? .distantPast, other.lastAuthenticatedAt ?? .distantPast)
    }

    private var sourcePriority: Int {
        switch self.source {
        case .managedByApp:
            3
        case .ambient:
            2
        case .importedCodexBar:
            1
        }
    }

    static func normalizeEmail(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value.lowercased()
    }
}

struct StoredAccountList: Codable, Sendable {
    let version: Int
    let accounts: [StoredAccount]
}

struct AccountRuntimeState: Sendable {
    var snapshot: AccountUsageSnapshot?
    var errorMessage: String?
    var isLoading: Bool = false
}

struct AccountUsageSnapshot: Codable, Sendable {
    let email: String?
    let providerAccountID: String?
    let plan: String?
    let allowed: Bool?
    let limitReached: Bool?
    let primaryWindow: UsageWindowSnapshot?
    let secondaryWindow: UsageWindowSnapshot?
    let credits: CreditsBalanceSnapshot?
    let updatedAt: Date

    var lowestRemainingPercent: Double {
        if self.isQuotaBlocked {
            return 0
        }

        let values = [self.secondaryWindow?.remainingPercent, self.primaryWindow?.remainingPercent]
            .compactMap { $0 }
        return values.min() ?? 101
    }

    var hasQuotaWindows: Bool {
        self.primaryWindow != nil || self.secondaryWindow != nil
    }

    var isQuotaBlocked: Bool {
        self.limitReached == true || self.allowed == false
    }

    var sortPriority: Int {
        self.isQuotaBlocked ? 1 : 0
    }

    var nextResetAt: Date? {
        [self.primaryWindow?.resetAt, self.secondaryWindow?.resetAt]
            .compactMap { $0 }
            .min()
    }

    var planDisplayName: String {
        guard let plan, !plan.isEmpty else { return "Bilinmiyor" }
        return plan
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}

struct UsageWindowSnapshot: Codable, Sendable {
    let usedPercent: Double
    let resetAt: Date?
    let limitWindowSeconds: Int

    var remainingPercent: Double {
        max(0, 100 - self.usedPercent)
    }

    var displayName: String {
        switch self.limitWindowSeconds {
        case 18_000:
            return "5 Saat"
        case 604_800:
            return "7 Gün"
        default:
            let hours = Double(self.limitWindowSeconds) / 3600
            if hours < 24 {
                return "\(Int(hours.rounded())) Saat"
            }
            let days = hours / 24
            return "\(Int(days.rounded())) Gün"
        }
    }

    var shortLabel: String {
        switch self.limitWindowSeconds {
        case 18_000:
            return "5s"
        case 604_800:
            return "7g"
        default:
            let hours = Double(self.limitWindowSeconds) / 3600
            if hours < 24 {
                return "\(Int(hours.rounded()))s"
            }
            let days = hours / 24
            return "\(Int(days.rounded()))g"
        }
    }

    var resetAtDisplay: String? {
        guard let resetAt else { return nil }
        return resetAt.formatted(Self.resetAtFormat)
    }

    private static let resetAtFormat = Date.FormatStyle(date: .abbreviated, time: .shortened)
}

struct CreditsBalanceSnapshot: Codable, Sendable {
    let hasCredits: Bool
    let unlimited: Bool
    let balance: Double?

    var displayValue: String {
        if self.unlimited {
            return "Sınırsız"
        }
        if let balance {
            return balance.formatted(.number.precision(.fractionLength(0...2)))
        }
        if self.hasCredits {
            return "Var"
        }
        return "Yok"
    }
}
