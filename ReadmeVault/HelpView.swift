import SwiftUI
import AppKit

final class HelpWindowController {
    static let shared = HelpWindowController()
    private var window: NSWindow?

    func show() {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }
        let view = HelpView()
        let hosting = NSHostingView(rootView: view)
        hosting.sizingOptions = .preferredContentSize

        let win = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Aide ReadmeVault"
        win.contentView = hosting
        win.center()
        win.isReleasedWhenClosed = false
        win.makeKeyAndOrderFront(nil)
        self.window = win
    }
}

struct HelpView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#4A3FD4")!, Color(hex: "#6C63FF")!, Color(hex: "#A89BFF")!],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
                VStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                    Text("Aide ReadmeVault")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 28)
            }
            .frame(height: 140)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Raccourcis clavier
                    HelpSection(title: "Raccourcis clavier", icon: "keyboard") {
                        VStack(spacing: 0) {
                            HelpShortcutRow(shortcut: "⌘N", description: "Nouveau projet")
                            Divider().padding(.horizontal, 12)
                            HelpShortcutRow(shortcut: "⌘O", description: "Ouvrir un fichier README local")
                            Divider().padding(.horizontal, 12)
                            HelpShortcutRow(shortcut: "⌘I", description: "Importer depuis GitHub")
                            Divider().padding(.horizontal, 12)
                            HelpShortcutRow(shortcut: "⌘D", description: "Dupliquer le projet sélectionné")
                            Divider().padding(.horizontal, 12)
                            HelpShortcutRow(shortcut: "⌘F", description: "Rechercher dans tous les READMEs")
                            Divider().padding(.horizontal, 12)
                            HelpShortcutRow(shortcut: "⌘↩", description: "Enregistrer (dans le formulaire)")
                            Divider().padding(.horizontal, 12)
                            HelpShortcutRow(shortcut: "⌫", description: "Supprimer le(s) projet(s) sélectionné(s)")
                            Divider().padding(.horizontal, 12)
                            HelpShortcutRow(shortcut: "⎋", description: "Annuler / Fermer")
                        }
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Fonctionnalités
                    HelpSection(title: "Fonctionnalités", icon: "star") {
                        VStack(alignment: .leading, spacing: 8) {
                            HelpFeatureRow(icon: "arrow.down.circle", color: "#43D9AD", text: "Import GitHub — colle une URL de dépôt pour récupérer le README automatiquement")
                            HelpFeatureRow(icon: "doc.badge.plus", color: "#6C63FF", text: "Import local — ouvre un fichier .md, le titre et les tags sont détectés")
                            HelpFeatureRow(icon: "pin.fill", color: "#F7B731", text: "Épingler — clic droit sur un projet pour le garder en tête de liste")
                            HelpFeatureRow(icon: "arrow.up.arrow.down", color: "#4ECDC4", text: "Trier — par nom, date, taille ou manuellement par glisser-déposer")
                            HelpFeatureRow(icon: "checkmark.circle", color: "#43D9AD", text: "Multi-sélection — ⌘+clic pour sélectionner plusieurs projets, ⌫ pour supprimer")
                            HelpFeatureRow(icon: "arrow.down.doc", color: "#FF6584", text: "Export PDF — depuis l'onglet README, bouton \"Exporter PDF\"")
                            HelpFeatureRow(icon: "square.and.arrow.up", color: "#A29BFE", text: "Partager — partage le contenu Markdown via les services macOS")
                        }
                    }

                    // Ressources
                    HelpSection(title: "Ressources", icon: "link") {
                        VStack(spacing: 0) {
                            Link(destination: URL(string: "https://github.com/Titithen00b/ReadmeVault")!) {
                                HStack {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#6C63FF")!)
                                    Text("Code source sur GitHub")
                                        .font(.system(size: 12))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            Divider().padding(.horizontal, 12)
                            Link(destination: URL(string: "https://github.com/Titithen00b/ReadmeVault/releases")!) {
                                HStack {
                                    Image(systemName: "tag")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#43D9AD")!)
                                    Text("Notes de version")
                                        .font(.system(size: 12))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            Divider().padding(.horizontal, 12)
                            Link(destination: URL(string: "https://github.com/Titithen00b/ReadmeVault/issues")!) {
                                HStack {
                                    Image(systemName: "exclamationmark.bubble")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#FF6584")!)
                                    Text("Signaler un problème")
                                        .font(.system(size: 12))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                        }
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 460, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

private struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#6C63FF")!)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#6C63FF")!)
                    .tracking(0.8)
            }
            content()
        }
    }
}

private struct HelpShortcutRow: View {
    let shortcut: String
    let description: String

    var body: some View {
        HStack {
            Text(shortcut)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: "#6C63FF")!)
                .frame(width: 60, alignment: .leading)
                .padding(.leading, 12)
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

private struct HelpFeatureRow: View {
    let icon: String
    let color: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: color)!)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
