import SwiftUI
import AppKit

final class AboutWindowController {
    static let shared = AboutWindowController()
    private var window: NSWindow?

    func show() {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }
        let view = AboutView()
        let hosting = NSHostingView(rootView: view)
        hosting.sizingOptions = .preferredContentSize

        let win = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "À propos de ReadmeVault"
        win.contentView = hosting
        win.center()
        win.isReleasedWhenClosed = false
        win.makeKeyAndOrderFront(nil)
        self.window = win
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header gradient
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#4A3FD4")!, Color(hex: "#6C63FF")!, Color(hex: "#A89BFF")!],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )

                VStack(spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)

                    Text("ReadmeVault")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(.vertical, 32)
            }
            .frame(height: 200)

            // Info
            VStack(spacing: 0) {
                AboutInfoRow(label: "Développeur", value: "Valentin R. (Titithen00b)")
                Divider().padding(.horizontal, 20)
                AboutInfoRow(label: "Technologie", value: "SwiftUI · macOS 14+")
                Divider().padding(.horizontal, 20)
                AboutInfoRow(label: "Stockage", value: "Local · Library/Application Support/ReadmeVault/")
                Divider().padding(.horizontal, 20)
                AboutInfoRow(label: "Licence", value: "MIT")
            }
            .padding(.vertical, 8)

            Divider()

            // Footer
            VStack(spacing: 6) {
                Text("Centralisez tous vos READMEs en un seul endroit.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Text("© \(currentYear) Valentin R. (Titithen00b)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(16)
        }
        .frame(width: 360)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var currentYear: String {
        String(Calendar.current.component(.year, from: Date()))
    }
}

private struct AboutInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .trailing)
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
