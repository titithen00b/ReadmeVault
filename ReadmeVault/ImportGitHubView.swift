import SwiftUI

struct ImportGitHubView: View {
    @EnvironmentObject var store: ProjectStore
    @Environment(\.dismiss) var dismiss

    @State private var urlText = ""
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var importedProject: Project? = nil
    @State private var step: ImportStep = .input

    enum ImportStep {
        case input, loading, preview, done
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#43D9AD")!.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#43D9AD"))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Importer depuis GitHub")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("Importe le README et les infos du dépôt")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    switch step {
                    case .input:
                        inputView
                    case .loading:
                        loadingView
                    case .preview:
                        if let project = importedProject {
                            previewView(project: project)
                        }
                    case .done:
                        doneView
                    }
                }
                .padding(24)
            }

            if let error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Spacer()
                    Button {
                        self.error = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 24)
            }

            Divider()

            // Bottom actions
            HStack {
                if step == .preview {
                    Button("Retour") {
                        step = .input
                        importedProject = nil
                    }
                }
                Spacer()
                Button("Annuler") { dismiss() }
                    .keyboardShortcut(.escape)

                if step == .input {
                    Button("Importer") {
                        Task { await doImport() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#43D9AD"))
                    .disabled(urlText.isEmpty || isLoading)
                } else if step == .preview, let project = importedProject {
                    Button("Ajouter à la vault") {
                        store.add(project)
                        step = .done
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#43D9AD"))
                } else if step == .done {
                    Button("Fermer") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "#43D9AD"))
                }
            }
            .padding(20)
        }
        .frame(width: 540, height: 480)
    }

    var inputView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("URL du dépôt GitHub")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                TextField("https://github.com/user/repository", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14, design: .monospaced))
                    .onSubmit {
                        Task { await doImport() }
                    }

                Text("Ex: https://github.com/apple/swift ou github.com/facebook/react")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            // What gets imported
            VStack(alignment: .leading, spacing: 10) {
                Text("Ce qui sera importé")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                ForEach([
                    ("doc.text.fill", "Contenu du README.md", "#6C63FF"),
                    ("tag.fill", "Nom, description et topics", "#43D9AD"),
                    ("link", "URL du dépôt", "#FF6584")
                ], id: \.0) { icon, label, color in
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: color))
                            .frame(width: 20)
                        Text(label)
                            .font(.system(size: 13))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }

    var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(.circular)
                .tint(Color(hex: "#43D9AD"))
            Text("Récupération du dépôt...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text(urlText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.6))
            Spacer()
        }
    }

    func previewView(project: Project) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aperçu du projet importé")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(project.accentColor)
                        .frame(width: 48, height: 48)
                        .shadow(color: project.accentColor.opacity(0.4), radius: 8, y: 4)
                    Text(project.initials)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.system(size: 16, weight: .bold))
                    if !project.description.isEmpty {
                        Text(project.description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(project.accentColor.opacity(0.3), lineWidth: 1)
                    )
            )

            if !project.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Topics").font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                    HStack {
                        ForEach(project.tags.prefix(6), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(project.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(project.accentColor.opacity(0.12)))
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("README").font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                Text(String(project.readme.prefix(200)) + (project.readme.count > 200 ? "..." : ""))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(10)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
            }
        }
    }

    var doneView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(hex: "#43D9AD")!.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "#43D9AD"))
            }
            Text("Projet importé avec succès !")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text("Tu peux retrouver \"\(importedProject?.name ?? "")\" dans ta vault.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    @MainActor
    func doImport() async {
        error = nil
        isLoading = true
        step = .loading

        do {
            let project = try await store.importFromGitHub(url: urlText)
            importedProject = project
            step = .preview
        } catch {
            self.error = error.localizedDescription
            step = .input
        }
        isLoading = false
    }
}
