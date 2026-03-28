import SwiftUI

@main
struct ReadmeVaultApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = ProjectStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear { appDelegate.setStore(store) }
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

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var mainWindow: NSWindow?
    private weak var projectStore: ProjectStore?

    func setStore(_ store: ProjectStore) {
        projectStore = store
        applyStoreToPopover(store)
    }

    private func applyStoreToPopover(_ store: ProjectStore) {
        guard let popover else { return }
        let content = MenuBarView().environmentObject(store)
        popover.contentViewController = NSHostingController(rootView: content)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let window = NSApp.windows.first(where: { !($0 is NSPanel) }) {
                window.isReleasedWhenClosed = false
                self.mainWindow = window
            }
        }

        NotificationCenter.default.addObserver(forName: .openMainWindow, object: nil, queue: .main) { [weak self] notification in
            let projectID = (notification.userInfo?["projectID"] as? String).flatMap { UUID(uuidString: $0) }
            self?.showMainWindow(selectingProjectID: projectID)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.text.magnifyingglass", accessibilityDescription: "ReadmeVault")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        let pop = NSPopover()
        pop.contentSize = CGSize(width: 280, height: 420)
        pop.behavior = .transient
        self.popover = pop
        if let store = projectStore {
            applyStoreToPopover(store)
        }
    }

    private func showMainWindow(selectingProjectID projectID: UUID? = nil) {
        popover?.performClose(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            let window = self.mainWindow ?? NSApp.windows.first(where: { !($0 is NSPanel) })
            window?.isReleasedWhenClosed = false
            window?.makeKeyAndOrderFront(nil)
            if let id = projectID,
               let project = self.projectStore?.projects.first(where: { $0.id == id }) {
                self.projectStore?.selectedProject = project
            }
        }
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover else { return }
        if popover.contentViewController == nil, let store = projectStore {
            applyStoreToPopover(store)
        }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let addProject     = Notification.Name("addProject")
    static let openFile       = Notification.Name("openFile")
    static let importGitHub   = Notification.Name("importGitHub")
    static let focusSearch    = Notification.Name("focusSearch")
    static let openMainWindow = Notification.Name("openMainWindow")
}
