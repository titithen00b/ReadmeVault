import SwiftUI

@main
struct ReadmeVaultApp: App {
    @StateObject private var store = ProjectStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("À propos de ReadmeVault") {
                    AboutWindowController.shared.show()
                }
            }
            CommandGroup(replacing: .newItem) {
                Button("Nouveau projet") {
                    NotificationCenter.default.post(name: .addProject, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Ouvrir un fichier README…") {
                    NotificationCenter.default.post(name: .openFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Importer depuis GitHub…") {
                    NotificationCenter.default.post(name: .importGitHub, object: nil)
                }
                .keyboardShortcut("i", modifiers: .command)
            }

            CommandMenu("Projets") {
                Button("Rechercher") {
                    NotificationCenter.default.post(name: .focusSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let addProject   = Notification.Name("addProject")
    static let openFile     = Notification.Name("openFile")
    static let importGitHub = Notification.Name("importGitHub")
    static let focusSearch  = Notification.Name("focusSearch")
}
