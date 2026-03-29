#if os(iOS)
import SwiftUI

struct ContentViewIOS: View {
    @EnvironmentObject var store: ProjectStore
    @State private var showAddSheet = false
    @State private var showImportSheet = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ProjectListViewIOS(showAddSheet: $showAddSheet, showImportSheet: $showImportSheet)
        } detail: {
            if let project = store.selectedProject {
                ProjectDetailViewIOS(project: project)
            } else {
                EmptyStateViewIOS(showAddSheet: $showAddSheet)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            ProjectFormView(mode: .add)
                .environmentObject(store)
        }
        .sheet(isPresented: $showImportSheet) {
            ImportGitHubView()
                .environmentObject(store)
        }
    }
}

struct EmptyStateViewIOS: View {
    @Binding var showAddSheet: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#6C63FF")!, Color(hex: "#FF6584")!],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text("Aucun projet sélectionné")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Text("Sélectionne un projet ou crée-en un nouveau.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
