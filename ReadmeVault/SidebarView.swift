import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: ProjectStore
    @Binding var showAddSheet: Bool
    @Binding var showImportSheet: Bool
    @Binding var showFileImportPicker: Bool
    @State private var selectedIDs: Set<UUID> = []
    @State private var draggingID: UUID? = nil

    private func deleteSelected() {
        let count = selectedIDs.count
        guard count > 0 else { return }
        let alert = NSAlert()
        alert.messageText = count == 1
            ? "Supprimer ce projet ?"
            : "Supprimer \(count) projets ?"
        alert.informativeText = "Cette action est irréversible."
        alert.addButton(withTitle: "Supprimer")
        alert.addButton(withTitle: "Annuler")
        alert.alertStyle = .warning
        if alert.runModal() == .alertFirstButtonReturn {
            store.deleteMultiple(selectedIDs)
            selectedIDs = []
        }
    }

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
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Trier les projets")

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
                TextField("Rechercher dans tous les READMEs...", text: $store.searchText)
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
                    LazyVStack(spacing: 0) {
                        ForEach(store.filteredProjects) { project in
                            ProjectRowView(project: project, selectedIDs: selectedIDs)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    let isCmd = NSEvent.modifierFlags.contains(.command)
                                    if isCmd {
                                        if selectedIDs.contains(project.id) {
                                            selectedIDs.remove(project.id)
                                        } else {
                                            selectedIDs.insert(project.id)
                                            store.selectedProject = project
                                        }
                                    } else {
                                        selectedIDs = [project.id]
                                        store.selectedProject = project
                                    }
                                }
                                .ifManualSort(store.sortOrder == .manual) {
                                    $0.onDrag {
                                        draggingID = project.id
                                        return NSItemProvider(object: project.id.uuidString as NSString)
                                    }
                                    .onDrop(of: [.plainText], delegate: ProjectDropDelegate(
                                        targetID: project.id,
                                        draggingID: $draggingID,
                                        store: store
                                    ))
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onAppear {
                    if let sel = store.selectedProject {
                        selectedIDs = [sel.id]
                    }
                }
                .onDeleteCommand(perform: deleteSelected)
            }

            Divider()

            // Bottom actions
            HStack(spacing: 8) {
                if selectedIDs.count > 1 {
                    Button(action: deleteSelected) {
                        Label("Supprimer (\(selectedIDs.count))", systemImage: "trash")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Button {
                        showImportSheet = true
                    } label: {
                        Label("Importer GitHub", systemImage: "arrow.down.circle")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(Color(hex: "#43D9AD"))
                }

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
    var selectedIDs: Set<UUID> = []
    @State private var isHovered = false

    var isSelected: Bool {
        selectedIDs.contains(project.id)
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
                Text(project.updatedAt.relativeFormatted)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }

            Spacer()

            if project.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(project.accentColor.opacity(0.7))
            } else if !project.gitURL.isEmpty {
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
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button {
                store.togglePin(project)
            } label: {
                Label(project.isPinned ? "Désépingler" : "Épingler",
                      systemImage: project.isPinned ? "pin.slash" : "pin")
            }
            Button {
                store.duplicate(project)
            } label: {
                Label("Dupliquer", systemImage: "plus.square.on.square")
            }
            .keyboardShortcut("d", modifiers: .command)
            if !project.gitURL.isEmpty {
                Divider()
                Button {
                    if let url = URL(string: project.gitURL) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Ouvrir sur GitHub", systemImage: "arrow.up.right.square")
                }
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(project.gitURL, forType: .string)
                } label: {
                    Label("Copier l'URL GitHub", systemImage: "link")
                }
            }
            Divider()
            Button("Supprimer", role: .destructive) {
                store.delete(project)
            }
        }
    }
}

struct ProjectDropDelegate: DropDelegate {
    let targetID: UUID
    @Binding var draggingID: UUID?
    let store: ProjectStore

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let fromID = draggingID, fromID != targetID,
              store.sortOrder == .manual else { return false }
        withAnimation { store.move(from: fromID, to: targetID) }
        draggingID = nil
        return true
    }
}

private extension View {
    @ViewBuilder
    func ifManualSort<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
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
