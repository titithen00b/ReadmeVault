import SwiftUI

@main
struct ReadmeVaultApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.store)
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
                        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                            .appendingPathComponent("ReadmeVault")
                        try? FileManager.default.removeItem(at: appSupport)

                        let prefs = FileManager.default.homeDirectoryForCurrentUser
                            .appendingPathComponent("Library/Preferences/ReadmeVault.plist")
                        try? FileManager.default.removeItem(at: prefs)

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

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ProjectStore()
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenMainWindow),
            name: .openMainWindow,
            object: nil
        )
    }

    @objc private func handleOpenMainWindow() {
        popover?.performClose(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows
                .filter { !($0 is NSPanel) && $0.canBecomeMain }
                .first?
                .makeKeyAndOrderFront(nil)
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.text.magnifyingglass", accessibilityDescription: "ReadmeVault")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        let content = MenuBarView().environmentObject(store)
        let controller = NSHostingController(rootView: content)

        let pop = NSPopover()
        pop.contentViewController = controller
        pop.contentSize = CGSize(width: 280, height: 420)
        pop.behavior = .transient
        self.popover = pop
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let addProject   = Notification.Name("addProject")
    static let openFile     = Notification.Name("openFile")
    static let importGitHub = Notification.Name("importGitHub")
    static let focusSearch  = Notification.Name("focusSearch")
    static let openMainWindow = Notification.Name("openMainWindow")
}
