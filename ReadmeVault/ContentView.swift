#if os(macOS)
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var store: ProjectStore
    @State private var showAddSheet = false
    @State private var showImportSheet = false
    @State private var showFileImportPicker = false
    @State private var fileImportData: (content: String, filename: String)? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var showImportFormSheet: Binding<Bool> {
        Binding(
            get: { fileImportData != nil },
            set: { if !$0 { fileImportData = nil } }
        )
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                showAddSheet: $showAddSheet,
                showImportSheet: $showImportSheet,
                showFileImportPicker: $showFileImportPicker
            )
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
        } detail: {
            if let project = store.selectedProject {
                ProjectDetailView(project: project)
            } else {
                EmptyStateView(showAddSheet: $showAddSheet)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            ProjectFormView(mode: .add)
        }
        .sheet(isPresented: $showImportSheet) {
            ImportGitHubView()
        }
        .sheet(isPresented: showImportFormSheet) {
            if let data = fileImportData {
                ProjectFormView(mode: .importFile(content: data.content, filename: data.filename))
            }
        }
        .fileImporter(
            isPresented: $showFileImportPicker,
            allowedContentTypes: [.text, UTType(filenameExtension: "md") ?? .text],
            allowsMultipleSelection: false
        ) { result in
            guard let url = try? result.get().first,
                  url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                fileImportData = (content: content, filename: url.deletingPathExtension().lastPathComponent)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addProject)) { _ in
            showAddSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFile)) { _ in
            showFileImportPicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .importGitHub)) { _ in
            showImportSheet = true
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

struct EmptyStateView: View {
    @Binding var showAddSheet: Bool

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#6C63FF")!, Color(hex: "#FF6584")!],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                    .opacity(0.4)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#6C63FF")!, Color(hex: "#FF6584")!],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Aucun projet sélectionné")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Sélectionne un projet ou crée-en un nouveau.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Button {
                showAddSheet = true
            } label: {
                Label("Nouveau projet", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#6C63FF"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
#endif
