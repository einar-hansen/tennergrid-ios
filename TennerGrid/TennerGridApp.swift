import SwiftUI

@main
struct TennerGridApp: App {
    init() {
        // Initialize AdMob SDK on app launch
        AdManager.shared.initializeMobileAdsSDK()
    }

    var body: some Scene {
        WindowGroup {
            TabBarView()
        }
    }
}
