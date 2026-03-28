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

            CommandGroup(replacing: .help) {
                Button("Aide ReadmeVault") {
                    HelpWindowController.shared.show()
                }
                .keyboardShortcut("/", modifiers: .command)
            }

            CommandGroup(replacing: .appTermination) {
                Button("Désinstaller ReadmeVault…") {
                    let alert = NSAlert()
                    alert.messageText = "Désinstaller ReadmeVault ?"
                    alert.informativeText = "Toutes vos données (projets, READMEs) seront supprimées définitivement. Cette action est irréversible."
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "Désinstaller")
                    alert.addButton(withTitle: "Annuler")

                    if alert.runModal() == .alertFirstButtonReturn {
                        // Supprimer les données
                        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                            .appendingPathComponent("ReadmeVault")
                        try? FileManager.default.removeItem(at: appSupport)

                        // Supprimer les préférences
                        let prefs = FileManager.default.homeDirectoryForCurrentUser
                            .appendingPathComponent("Library/Preferences/ReadmeVault.plist")
                        try? FileManager.default.removeItem(at: prefs)

                        // Supprimer l'app elle-même
                        let appURL = Bundle.main.bundleURL
                        NSWorkspace.shared.recycle([appURL]) { _, _ in
                            NSApp.terminate(nil)
                        }
                    }
                }
                Divider()
                Button("Quitter ReadmeVault") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
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
