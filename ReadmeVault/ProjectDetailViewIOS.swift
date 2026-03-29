#if os(iOS)
import SwiftUI

struct ProjectDetailViewIOS: View {
    @EnvironmentObject var store: ProjectStore
    let project: Project
    @State private var selectedTab = 0
    @State private var showEditSheet = false
    @State private var exportPDFTrigger = false
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            // Segment picker
            Picker("Vue", selection: $selectedTab) {
                Label("README", systemImage: "doc.text").tag(0)
                Label("Brut", systemImage: "chevron.left.forwardslash.chevron.right").tag(1)
                Label("Infos", systemImage: "info.circle").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))

            Divider()

            Group {
                switch selectedTab {
                case 0:
                    MarkdownRendererView(
                        content: project.readme,
                        accentColor: project.accentColor,
                        filename: project.name
                    )
                case 1:
                    ScrollView {
                        Text(project.readme)
                            .font(.system(size: 13, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.sheetBackground)
                case 2:
                    ProjectInfoView(project: project)
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // Copy
                    Button {
                        UIPasteboard.general.string = project.readme
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        Label(copied ? "Copié !" : "Copier README",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                    }

                    // Share
                    ShareLink(item: project.readme, subject: Text(project.name)) {
                        Label("Partager", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    // Pin
                    Button {
                        store.togglePin(project)
                    } label: {
                        Label(project.isPinned ? "Désépingler" : "Épingler",
                              systemImage: project.isPinned ? "pin.slash" : "pin")
                    }

                    // GitHub
                    if !project.gitURL.isEmpty {
                        Button {
                            if let url = URL(string: project.gitURL) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Ouvrir sur GitHub", systemImage: "arrow.up.right.square")
                        }
                    }

                    Divider()

                    // Edit
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Modifier", systemImage: "pencil")
                    }

                    // Delete
                    Button(role: .destructive) {
                        store.delete(project)
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            ProjectFormView(mode: .edit(project))
                .environmentObject(store)
        }
    }
}
#endif
