import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 10) {
            self.header
            self.searchBar
            self.accountList
        }
        .padding(12)
        .frame(width: 430, height: 580)
        .background(Color(NSColor.windowBackgroundColor))
        .alert(
            "Hesabı Kaldır",
            isPresented: Binding(
                get: { self.model.pendingRemovalAccount != nil },
                set: { newValue in
                    if !newValue {
                        self.model.cancelPendingRemoval()
                    }
                }))
        {
            Button("Kaldır", role: .destructive) {
                self.model.confirmPendingRemoval()
            }
            Button("İptal", role: .cancel) {
                self.model.cancelPendingRemoval()
            }
        } message: {
            if let account = self.model.pendingRemovalAccount {
                Text("\(account.displayName) bu uygulamadan kaldırılacak.")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Codex")
                    .font(.system(size: 14, weight: .semibold))
                Text(self.headerStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 8) {
                HeaderIconButton(
                    systemName: "plus",
                    action: { self.model.startAddAccount() },
                    alternateSystemName: "xmark",
                    isActive: self.model.isAddingAccount,
                    activeAction: { self.model.cancelAddAccount() })
                    .help(self.model.isAddingAccount ? "Yeni hesap eklemeyi iptal et" : "Yeni hesap ekle")

                HeaderIconButton(
                    systemName: "arrow.clockwise",
                    action: { Task { await self.model.refreshAll() } })
                    .help("Tüm hesapları yenile")
                    .disabled(self.model.isRefreshingAll)
            }
        }
        .padding(.horizontal, 2)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Hesap ara", text: self.$model.searchText)
                .textFieldStyle(.plain)

            if !self.model.searchText.isEmpty {
                Button {
                    self.model.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    @ViewBuilder
    private var accountList: some View {
        if self.model.filteredAccounts.isEmpty {
            ContentUnavailableView(
                "Hesap Yok",
                systemImage: "tray",
                description: Text("İçe aktar veya yeni bir Codex hesabı ekle."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(self.model.filteredAccounts) { account in
                        let isSelected = self.model.selectedAccountID == account.id
                        let nextSelection = isSelected ? nil : account.id

                        AccountRowView(
                            account: account,
                            state: self.model.runtimeState(for: account.id),
                            isSelected: isSelected,
                            isReauthenticating: self.model.reauthenticatingAccountID == account.id,
                            onSelect: {
                                self.model.selectedAccountID = nextSelection
                            },
                            onSaveNickname: { self.model.updateNickname(for: account.id, nickname: $0) },
                            onRefresh: { Task { await self.model.refresh(account: account) } },
                            onReauthenticate: { Task { await self.model.reauthenticate(account) } },
                            onOpenFolder: { self.model.openFolder(for: account) },
                            onRemove: { self.model.requestRemoval(of: account) })
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var headerStatusText: String {
        if let statusMessage = self.model.statusMessage, !statusMessage.isEmpty {
            return statusMessage
        }

        let lowQuotaCount = self.model.lowQuotaCount
        if lowQuotaCount > 0 {
            return "\(self.model.accountCount) hesap, \(lowQuotaCount) tanesi kritik"
        }
        return "\(self.model.accountCount) hesap"
    }
}

private struct HeaderIconButton: View {
    let defaultSystemName: String
    let action: () -> Void
    var alternateSystemName: String?
    var isActive = false
    var activeAction: (() -> Void)?

    init(
        systemName: String,
        action: @escaping () -> Void,
        alternateSystemName: String? = nil,
        isActive: Bool = false,
        activeAction: (() -> Void)? = nil)
    {
        self.defaultSystemName = systemName
        self.action = action
        self.alternateSystemName = alternateSystemName
        self.isActive = isActive
        self.activeAction = activeAction
    }

    var body: some View {
        Button(action: self.currentAction) {
            Image(systemName: self.currentSystemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(self.isActive ? Color.accentColor.opacity(0.16) : Color(NSColor.controlBackgroundColor)))
        }
        .buttonStyle(.plain)
    }

    private var currentAction: () -> Void {
        if self.isActive, let activeAction {
            return activeAction
        }
        return self.action
    }

    private var currentSystemName: String {
        if self.isActive, let alternateSystemName {
            return alternateSystemName
        }
        return self.defaultSystemName
    }
}
