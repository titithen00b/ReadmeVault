#if os(macOS)
import SwiftUI
import AppKit

struct ProjectDetailView: View {
    @EnvironmentObject var store: ProjectStore
    let project: Project
    @State private var showEditSheet = false
    @State private var selectedTab = 0
    @State private var showDeleteConfirm = false
    @State private var isRefreshing = false
    @State private var refreshError: String? = nil
    @State private var copied = false
    @State private var exportPDFTrigger = false

    var body: some View {
        VStack(spacing: 0) {
            // Top header bar
            HStack(spacing: 16) {
                // Project identity
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [project.accentColor, project.accentColor.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: project.accentColor.opacity(0.4), radius: 8, y: 4)
                        Text(project.initials)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        if !project.description.isEmpty {
                            Text(project.description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Tags
                if !project.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(project.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(project.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(project.accentColor.opacity(0.12))
                                )
                        }
                    }
                }

                // GitHub link + refresh
                if !project.gitURL.isEmpty {
                    Button {
                        if let url = URL(string: project.gitURL) {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 13))
                            Text("GitHub")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    // Refresh depuis GitHub
                    if project.gitURL.contains("github.com") {
                        Button {
                            isRefreshing = true
                            refreshError = nil
                            Task {
                                do {
                                    let updated = try await store.importFromGitHub(url: project.gitURL)
                                    var refreshed = project
                                    refreshed.readme = updated.readme
                                    refreshed.description = updated.description
                                    refreshed.tags = updated.tags
                                    store.update(refreshed)
                                } catch {
                                    refreshError = error.localizedDescription
                                }
                                isRefreshing = false
                            }
                        } label: {
                            Image(systemName: isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                                .font(.system(size: 13, weight: .medium))
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(isRefreshing)
                        .help("Rafraîchir le README depuis GitHub")
                    }
                }

                // Edit
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                }
                .buttonStyle(.plain)

                // Delete
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))

            // Accent line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [project.accentColor, project.accentColor.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)

            // Tab selector
            HStack(spacing: 0) {
                TabButton(title: "README", icon: "doc.text", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "Brut (Markdown)", icon: "chevron.left.forwardslash.chevron.right", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabButton(title: "Infos", icon: "info.circle", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                Spacer()

                // Share
                ShareLink(item: project.readme, subject: Text(project.name)) {
                    Label("Partager", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)

                // Export PDF
                if selectedTab == 0 {
                    Button {
                        exportPDFTrigger = true
                    } label: {
                        Label("Exporter PDF", systemImage: "arrow.down.doc")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }

                // Copy button
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(project.readme, forType: .string)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Label(copied ? "Copié !" : "Copier README",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(copied ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                .animation(.easeInOut(duration: 0.2), value: copied)
            }
            .padding(.horizontal, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Content
            Group {
                switch selectedTab {
                case 0:
                    MarkdownRendererView(content: project.readme, accentColor: project.accentColor, filename: project.name, exportTrigger: $exportPDFTrigger)
                case 1:
                    RawMarkdownView(content: project.readme)
                case 2:
                    ProjectInfoView(project: project)
                default:
                    EmptyView()
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .sheet(isPresented: $showEditSheet) {
            ProjectFormView(mode: .edit(project))
        }
        .alert("Erreur de rafraîchissement", isPresented: .init(
            get: { refreshError != nil },
            set: { if !$0 { refreshError = nil } }
        )) {
            Button("OK", role: .cancel) { refreshError = nil }
        } message: {
            Text(refreshError ?? "")
        }
        .alert("Supprimer \"\(project.name)\" ?", isPresented: $showDeleteConfirm) {
            Button("Supprimer", role: .destructive) {
                store.delete(project)
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cette action est irréversible.")
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? Color(hex: "#6C63FF") : .secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                VStack {
                    Spacer()
                    if isSelected {
                        Rectangle()
                            .fill(Color(hex: "#6C63FF")!)
                            .frame(height: 2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

struct RawMarkdownView: View {
    let content: String
    @State private var copied = false

    var body: some View {
        ScrollView {
            Text(content)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.primary.opacity(0.85))
                .textSelection(.enabled)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(NSColor.textBackgroundColor))
    }
}

#endif
