import SwiftUI

@main
struct CodexGaugeApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            RootView(model: self.model)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: self.model.menuBarSymbol)
                if self.model.lowQuotaCount > 0 {
                    Text("\(self.model.lowQuotaCount)")
                        .font(.caption2.monospacedDigit())
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
