#if os(iOS)
import SwiftUI

struct ProjectListViewIOS: View {
    @EnvironmentObject var store: ProjectStore
    @Binding var showAddSheet: Bool
    @Binding var showImportSheet: Bool

    var body: some View {
        List(store.filteredProjects, selection: $store.selectedProject) { project in
            ProjectRowViewIOS(project: project)
                .tag(project)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("ReadmeVault")
        .searchable(text: $store.searchText, prompt: "Rechercher dans les READMEs…")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Nouveau projet", systemImage: "plus.circle")
                    }
                    Button {
                        showImportSheet = true
                    } label: {
                        Label("Importer depuis GitHub", systemImage: "arrow.down.circle")
                    }
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            store.sortOrder = order
                        } label: {
                            HStack {
                                Text(order.rawValue)
                                if store.sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        // Tag filter chips
        .safeAreaInset(edge: .top, spacing: 0) {
            if !store.allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        TagChipIOS(label: "Tous", isSelected: store.selectedTag == nil) {
                            store.selectedTag = nil
                        }
                        ForEach(store.allTags, id: \.self) { tag in
                            TagChipIOS(label: tag, isSelected: store.selectedTag == tag) {
                                store.selectedTag = store.selectedTag == tag ? nil : tag
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial)
            }
        }
    }
}

struct ProjectRowViewIOS: View {
    let project: Project

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        colors: [project.accentColor, project.accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                Text(project.initials)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(project.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    if project.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(project.accentColor)
                    }
                }
                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Text(project.updatedAt.relativeFormatted)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                // handled via context menu or detail view
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                // togglePin handled via store
            } label: {
                Label(project.isPinned ? "Désépingler" : "Épingler",
                      systemImage: project.isPinned ? "pin.slash" : "pin")
            }
            if !project.gitURL.isEmpty {
                Button {
                    if let url = URL(string: project.gitURL) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Ouvrir sur GitHub", systemImage: "arrow.up.right.square")
                }
            }
        }
    }
}

struct TagChipIOS: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected
                            ? Color(hex: "#6C63FF")!
                            : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
}
#endif
