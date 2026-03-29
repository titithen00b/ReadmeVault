import SwiftUI

extension Color {
    static var cardBackground: Color {
        #if os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color.cardBackground
        #endif
    }
    static var sheetBackground: Color {
        #if os(macOS)
        Color(NSColor.textBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
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
                        InfoRow(label: "Caractères", value: "\(project.readme.count)")
                        InfoRow(label: "Mots", value: "\(project.readme.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)")
                        InfoRow(label: "Lignes", value: "\(project.readme.split(separator: "\n").count)")
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
                .fill(Color.cardBackground)
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
