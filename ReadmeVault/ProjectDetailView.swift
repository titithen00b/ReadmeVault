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

                // Copy button
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(project.readme, forType: .string)
                } label: {
                    Label("Copier README", systemImage: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
            .padding(.horizontal, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Content
            Group {
                switch selectedTab {
                case 0:
                    MarkdownRendererView(content: project.readme, accentColor: project.accentColor)
                case 1:
                    RawMarkdownView(content: project.readme)
                case 2:
                    ProjectInfoView(project: project)
                default:
                    EmptyView()
                }
            }
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

struct ProjectInfoView: View {
    let project: Project

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                InfoCard(title: "Identité du projet", accentColor: project.accentColor) {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "Nom", value: project.name)
                        InfoRow(label: "Description", value: project.description.isEmpty ? "–" : project.description)
                        InfoRow(label: "Lien Git", value: project.gitURL.isEmpty ? "–" : project.gitURL, isLink: true)
                    }
                }

                if !project.tags.isEmpty {
                    InfoCard(title: "Tags", accentColor: project.accentColor) {
                        FlowLayout(spacing: 6) {
                            ForEach(project.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(project.accentColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(project.accentColor.opacity(0.12)))
                            }
                        }
                    }
                }

                InfoCard(title: "Dates", accentColor: project.accentColor) {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "Créé le", value: project.createdAt.formatted(date: .long, time: .shortened))
                        InfoRow(label: "Modifié le", value: project.updatedAt.formatted(date: .long, time: .shortened))
                    }
                }

                InfoCard(title: "README", accentColor: project.accentColor) {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "Taille", value: "\(project.readme.count) caractères")
                        InfoRow(label: "Lignes", value: "\(project.readme.split(separator: "\n").count) lignes")
                    }
                }
            }
            .padding(24)
        }
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    let accentColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(accentColor)
                .textCase(.uppercase)
                .tracking(0.8)
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var isLink: Bool = false

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            if isLink, let url = URL(string: value), value != "–" {
                Link(value, destination: url)
                    .font(.system(size: 12))
                    .lineLimit(1)
            } else {
                Text(value)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0, +)
            + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentRowWidth: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([view])
                currentRowWidth = size.width + spacing
            } else {
                rows[rows.count - 1].append(view)
                currentRowWidth += size.width + spacing
            }
        }
        return rows
    }
}
