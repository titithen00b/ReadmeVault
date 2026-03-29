import SwiftUI
import UniformTypeIdentifiers

enum FormMode {
    case add
    case edit(Project)
    case importFile(content: String, filename: String)
}

struct ProjectFormView: View {
    @EnvironmentObject var store: ProjectStore
    @Environment(\.dismiss) var dismiss

    let mode: FormMode

    @State private var name = ""
    @State private var description = ""
    @State private var readme = ""
    @State private var gitURL = ""
    @State private var tagsText = ""
    @State private var selectedColor = "#6C63FF"
    @State private var currentTab = 0
    @State private var showFilePicker = false

    let colorOptions = [
        "#6C63FF", "#FF6584", "#43D9AD", "#F7B731",
        "#4ECDC4", "#FF6B6B", "#A29BFE", "#FD79A8",
        "#00B894", "#FDCB6E", "#E17055", "#74B9FF"
    ]

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var isImporting: Bool {
        if case .importFile = mode { return true }
        return false
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEditing ? "Modifier le projet" : isImporting ? "Importer un README" : "Nouveau projet")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(isEditing ? "Mets à jour les informations" : isImporting ? "Vérifie les infos détectées" : "Ajoute un projet à ta vault")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
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

            // Tab selector
            HStack(spacing: 0) {
                FormTabButton(title: "Général", icon: "info.circle", isSelected: currentTab == 0) {
                    currentTab = 0
                }
                FormTabButton(title: "README", icon: "doc.text", isSelected: currentTab == 1) {
                    currentTab = 1
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Divider()
                .padding(.top, 8)

            // Form content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if currentTab == 0 {
                        generalForm
                    } else {
                        readmeForm
                    }
                }
                .padding(24)
            }

            Divider()

            // Actions
            HStack {
                if isEditing, case .edit(let project) = mode {
                    Button("Supprimer", role: .destructive) {
                        store.delete(project)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button("Annuler") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button(isEditing ? "Enregistrer" : "Créer le projet") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: selectedColor))
                .disabled(!isValid)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(20)
        }
        .frame(width: 620, height: 560)
        .onAppear {
            switch mode {
            case .edit(let project):
                name = project.name
                description = project.description
                readme = project.readme
                gitURL = project.gitURL
                tagsText = project.tags.joined(separator: ", ")
                selectedColor = project.color
            case .importFile(let content, let filename):
                readme = content
                name = extractTitle(from: content) ?? filename
                description = extractDescription(from: content)
                tagsText = extractTags(from: content).joined(separator: ", ")
                currentTab = 0
            case .add:
                break
            }
        }
    }

    var generalForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Name + color
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    FormLabel("Nom du projet *")
                    TextField("ex: Mon API REST", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    FormLabel("Couleur")
                    // Color picker grid
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(24), spacing: 6), count: 6), spacing: 6) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .purple)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white, lineWidth: selectedColor == hex ? 2 : 0)
                                        .padding(2)
                                )
                                .shadow(color: (Color(hex: hex) ?? .purple).opacity(0.5), radius: selectedColor == hex ? 4 : 0)
                                .onTapGesture { selectedColor = hex }
                                .scaleEffect(selectedColor == hex ? 1.15 : 1.0)
                                .animation(.spring(response: 0.2), value: selectedColor)
                        }
                    }
                }
                .frame(width: 180)
            }

            VStack(alignment: .leading, spacing: 6) {
                FormLabel("Description")
                TextField("Brève description du projet", text: $description)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                FormLabel("Lien GitHub / Git")
                TextField("https://github.com/user/repo", text: $gitURL)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                FormLabel("Tags (séparés par des virgules)")
                TextField("ex: swift, ios, backend", text: $tagsText)
                    .textFieldStyle(.roundedBorder)
            }

            // Preview card
            VStack(alignment: .leading, spacing: 8) {
                FormLabel("Aperçu")
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: selectedColor) ?? .purple, (Color(hex: selectedColor) ?? .purple).opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        Text(name.isEmpty ? "??" : Project(name: name).initials)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name.isEmpty ? "Nom du projet" : name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(name.isEmpty ? .secondary : .primary)
                        Text(description.isEmpty ? "Description..." : description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder((Color(hex: selectedColor) ?? .purple).opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }

    var readmeForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                FormLabel("Contenu README (Markdown)")
                Spacer()
                Text("\(readme.split(separator: "\n").count) lignes")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Button {
                    showFilePicker = true
                } label: {
                    Label("Importer un fichier", systemImage: "square.and.arrow.down")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            TextEditor(text: $readme)
                .font(.system(size: 13, design: .monospaced))
                .frame(minHeight: 320)
                .padding(8)
                .background(Color.sheetBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.text, UTType(filenameExtension: "md") ?? .text],
            allowsMultipleSelection: false
        ) { result in
            guard let url = try? result.get().first,
                  url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                readme = content
                if name.isEmpty {
                    name = extractTitle(from: content) ?? url.deletingPathExtension().lastPathComponent
                }
            }
        }
    }

    private func extractTitle(from markdown: String) -> String? {
        markdown
            .components(separatedBy: "\n")
            .first(where: { $0.hasPrefix("# ") })
            .map { raw -> String in
                var title = String(raw.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                title = title.replacingOccurrences(of: "\\*\\*([^*]+)\\*\\*", with: "$1", options: .regularExpression)
                title = title.replacingOccurrences(of: "\\*([^*]+)\\*", with: "$1", options: .regularExpression)
                title = title.replacingOccurrences(of: "__([^_]+)__", with: "$1", options: .regularExpression)
                return title
            }
    }

    private func extractDescription(from markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var foundTitle = false
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") { foundTitle = true; continue }
            guard foundTitle, !trimmed.isEmpty,
                  !trimmed.hasPrefix("#"), !trimmed.hasPrefix("!"),
                  !trimmed.hasPrefix("|"), !trimmed.hasPrefix("```") else { continue }
            return trimmed
                .replacingOccurrences(of: #"\*\*([^*]+)\*\*"#, with: "$1", options: .regularExpression)
                .replacingOccurrences(of: #"\*([^*]+)\*"#, with: "$1", options: .regularExpression)
                .replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
        }
        return ""
    }

    private func extractTags(from markdown: String) -> [String] {
        let keywords = [
            "swift", "swiftui", "uikit", "python", "javascript", "typescript",
            "react", "vue", "angular", "nextjs", "nuxt", "svelte",
            "node", "express", "django", "flask", "fastapi", "rails",
            "go", "rust", "java", "kotlin", "flutter", "dart", "php", "laravel",
            "docker", "kubernetes", "aws", "gcp", "azure",
            "postgresql", "mysql", "mongodb", "redis", "sqlite", "graphql",
            "ios", "android", "macos", "linux",
            "tailwind", "sass", "webpack", "vite", "terraform"
        ]
        let lowercased = markdown.lowercased()
        return keywords.filter { lowercased.contains($0) }.prefix(6).map { $0 }
    }

    private func save() {
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if case .edit(var project) = mode {
            project.name = name.trimmingCharacters(in: .whitespaces)
            project.description = description
            project.readme = readme
            project.gitURL = gitURL
            project.tags = tags
            project.color = selectedColor
            store.update(project)
        } else {
            let project = Project(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description,
                readme: readme,
                gitURL: gitURL,
                tags: tags,
                color: selectedColor
            )
            store.add(project)
        }
        dismiss()
    }
}

struct FormLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
    }
}

struct FormTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12))
                Text(title).font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? Color(hex: "#6C63FF") : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
