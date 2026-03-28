import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: ProjectStore
    @Binding var showAddSheet: Bool
    @Binding var showImportSheet: Bool
    @Binding var showFileImportPicker: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("README")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#6C63FF")!, Color(hex: "#FF6584")!],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Vault")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                }
                Spacer()
                Text("\(store.projects.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#6C63FF")!)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
                TextField("Rechercher...", text: $store.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !store.searchText.isEmpty {
                    Button {
                        store.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            // Tags filter
            if !store.allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        TagChip(label: "Tous", isSelected: store.selectedTag == nil) {
                            store.selectedTag = nil
                        }
                        ForEach(store.allTags, id: \.self) { tag in
                            TagChip(label: tag, isSelected: store.selectedTag == tag) {
                                store.selectedTag = store.selectedTag == tag ? nil : tag
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.bottom, 8)
            }

            Divider()

            // Project list
            if store.filteredProjects.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Aucun projet")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(store.filteredProjects) { project in
                            ProjectRowView(project: project)
                                .onTapGesture {
                                    store.selectedProject = project
                                }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                }
            }

            Divider()

            // Bottom actions
            HStack(spacing: 8) {
                Button {
                    showImportSheet = true
                } label: {
                    Label("Importer GitHub", systemImage: "arrow.down.circle")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(Color(hex: "#43D9AD"))

                Spacer()

                Menu {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Nouveau projet", systemImage: "plus.circle")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    Button {
                        showFileImportPicker = true
                    } label: {
                        Label("Importer un fichier .md", systemImage: "doc.badge.plus")
                    }
                    .keyboardShortcut("o", modifiers: .command)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#6C63FF")!)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(12)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            store.searchText = ""
        }
    }
}

struct ProjectRowView: View {
    @EnvironmentObject var store: ProjectStore
    let project: Project
    @State private var isHovered = false

    var isSelected: Bool {
        store.selectedProject?.id == project.id
    }

    var body: some View {
        HStack(spacing: 10) {
            // Color badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                project.accentColor,
                                project.accentColor.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Text(project.initials)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !project.gitURL.isEmpty {
                Image(systemName: "link")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected
                    ? project.accentColor.opacity(0.15)
                    : (isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isSelected ? project.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button("Modifier") {
                // handled in detail view
            }
            Divider()
            Button("Supprimer", role: .destructive) {
                store.delete(project)
            }
        }
    }
}

struct TagChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected
                            ? Color(hex: "#6C63FF")!.opacity(0.9)
                            : Color(NSColor.controlBackgroundColor))
                )
        }
        .buttonStyle(.plain)
    }
}
