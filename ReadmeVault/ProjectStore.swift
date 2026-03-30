import Foundation
import SwiftUI
import Combine

struct Project: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var description: String
    var readme: String
    var gitURL: String
    var tags: [String]
    var color: String // hex string
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool = false

    init(
        name: String = "",
        description: String = "",
        readme: String = "",
        gitURL: String = "",
        tags: [String] = [],
        color: String = "#6C63FF"
    ) {
        self.name = name
        self.description = description
        self.readme = readme
        self.gitURL = gitURL
        self.tags = tags
        self.color = color
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var accentColor: Color {
        Color(hex: color) ?? .purple
    }

    var initials: String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// Métadonnées stockées en JSON (sans le contenu README)
private struct ProjectMetadata: Codable {
    var id: UUID
    var name: String
    var description: String
    var gitURL: String
    var tags: [String]
    var color: String
    var createdAt: Date
    var updatedAt: Date

    init(from project: Project) {
        self.id = project.id
        self.name = project.name
        self.description = project.description
        self.gitURL = project.gitURL
        self.tags = project.tags
        self.color = project.color
        self.createdAt = project.createdAt
        self.updatedAt = project.updatedAt
    }

    func toProject(readme: String) -> Project {
        var p = Project(
            name: name,
            description: description,
            readme: readme,
            gitURL: gitURL,
            tags: tags,
            color: color
        )
        p.id = id
        p.createdAt = createdAt
        p.updatedAt = updatedAt
        return p
    }
}

enum SortOrder: String, CaseIterable {
    case nameAsc    = "Nom (A→Z)"
    case nameDesc   = "Nom (Z→A)"
    case updatedDesc = "Modifié récemment"
    case updatedAsc  = "Modifié anciennement"
    case sizeDesc   = "Taille (grand→petit)"
    case sizeAsc    = "Taille (petit→grand)"
    case manual     = "Manuel (glisser-déposer)"
}

@MainActor
class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selectedProject: Project?
    @Published var searchText: String = ""
    @Published var selectedTag: String? = nil
    @Published var sortOrder: SortOrder = .updatedDesc

    var githubToken: String {
        get { UserDefaults.standard.string(forKey: "github_pat") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "github_pat") }
    }

    // MARK: - Chemins de stockage

    private var baseURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ReadmeVault", isDirectory: true)
    }

    private var metadataURL: URL {
        baseURL.appendingPathComponent("projects.json")
    }

    private var readmesURL: URL {
        baseURL.appendingPathComponent("readmes", isDirectory: true)
    }

    private func readmeURL(for id: UUID) -> URL {
        readmesURL.appendingPathComponent("\(id.uuidString).md")
    }

    // MARK: - Init

    init() {
        createDirectoriesIfNeeded()
        migrateFromUserDefaultsIfNeeded()
        load()
        if projects.isEmpty {
            loadSampleProjects()
        }
    }

    // MARK: - Filtres

    var filteredProjects: [Project] {
        var result = projects
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ||
                $0.readme.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }
        // Épinglés toujours en premier
        result.sort { $0.isPinned && !$1.isPinned }
        switch sortOrder {
        case .nameAsc:    result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:   result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .updatedDesc: result.sort { $0.updatedAt > $1.updatedAt }
        case .updatedAsc:  result.sort { $0.updatedAt < $1.updatedAt }
        case .sizeDesc:   result.sort { $0.readme.count > $1.readme.count }
        case .sizeAsc:    result.sort { $0.readme.count < $1.readme.count }
        case .manual:     break // ordre du tableau
        }
        return result
    }

    var allTags: [String] {
        Array(Set(projects.flatMap { $0.tags })).sorted()
    }

    // MARK: - CRUD

    func add(_ project: Project) {
        projects.append(project)
        selectedProject = project
        save()
    }

    func update(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            var updated = project
            updated.updatedAt = Date()
            projects[idx] = updated
            if selectedProject?.id == project.id {
                selectedProject = updated
            }
        }
        save()
    }

    func togglePin(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx].isPinned.toggle()
            if selectedProject?.id == project.id {
                selectedProject = projects[idx]
            }
        }
        saveMetadata()
    }

    func delete(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        if selectedProject?.id == project.id {
            selectedProject = projects.first
        }
        // Supprimer le fichier README associé
        try? FileManager.default.removeItem(at: readmeURL(for: project.id))
        saveMetadata()
    }

    func move(from sourceID: UUID, to destinationID: UUID) {
        guard let fromIndex = projects.firstIndex(where: { $0.id == sourceID }),
              let toIndex = projects.firstIndex(where: { $0.id == destinationID }),
              fromIndex != toIndex else { return }
        projects.move(fromOffsets: IndexSet(integer: fromIndex),
                      toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        saveMetadata()
    }

    func duplicate(_ project: Project) {
        var copy = project
        copy.id = UUID()
        copy.name = "\(project.name) (copie)"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.isPinned = false
        projects.append(copy)
        selectedProject = copy
        save()
    }

    func deleteMultiple(_ ids: Set<UUID>) {
        for id in ids {
            projects.removeAll { $0.id == id }
            try? FileManager.default.removeItem(at: readmeURL(for: id))
        }
        if let selected = selectedProject, ids.contains(selected.id) {
            selectedProject = projects.first
        }
        saveMetadata()
    }

    // MARK: - Import GitHub

    func importFromGitHub(url: String) async throws -> Project {
        let cleaned = url
            .replacingOccurrences(of: "https://github.com/", with: "")
            .replacingOccurrences(of: "http://github.com/", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let parts = cleaned.split(separator: "/")
        guard parts.count >= 2 else {
            throw ImportError.invalidURL
        }
        let owner = String(parts[0])
        let repo = String(parts[1])

        let apiURL = URL(string: "https://api.github.com/repos/\(owner)/\(repo)")!
        let (repoData, _) = try await URLSession.shared.data(from: apiURL)
        let repoInfo = try JSONDecoder().decode(GitHubRepo.self, from: repoData)

        let readmeURL = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/readme")!
        var readmeContent = "# \(repo)\n\nAucun README trouvé."
        if let (readmeData, _) = try? await URLSession.shared.data(from: readmeURL),
           let readmeJSON = try? JSONDecoder().decode(GitHubReadme.self, from: readmeData),
           let decoded = Data(base64Encoded: readmeJSON.content.replacingOccurrences(of: "\n", with: "")),
           let text = String(data: decoded, encoding: .utf8) {
            readmeContent = text
        }

        let colors = ["#6C63FF", "#FF6584", "#43D9AD", "#F7B731", "#4ECDC4", "#FF6B6B", "#A29BFE"]
        let randomColor = colors.randomElement() ?? "#6C63FF"

        let title = extractTitle(from: readmeContent) ?? repoInfo.name
        let tags = extractTags(fromTopics: repoInfo.topics ?? [], readme: readmeContent)

        return Project(
            name: title,
            description: repoInfo.description ?? "",
            readme: readmeContent,
            gitURL: repoInfo.html_url,
            tags: tags,
            color: randomColor
        )
    }

    func refreshFromGitHub(project: Project) async throws -> Project {
        let cleaned = project.gitURL
            .replacingOccurrences(of: "https://github.com/", with: "")
            .replacingOccurrences(of: "http://github.com/", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = cleaned.split(separator: "/")
        guard parts.count >= 2 else { throw ImportError.invalidURL }
        let fullName = "\(parts[0])/\(parts[1])"

        var repoRequest = URLRequest(url: URL(string: "https://api.github.com/repos/\(fullName)")!)
        repoRequest.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        if !githubToken.isEmpty {
            repoRequest.setValue("Bearer \(githubToken)", forHTTPHeaderField: "Authorization")
        }
        let (repoData, repoResponse) = try await URLSession.shared.data(for: repoRequest)
        if let http = repoResponse as? HTTPURLResponse, http.statusCode == 401 {
            throw ImportError.unauthorized
        }
        let repoInfo = try JSONDecoder().decode(GitHubRepo.self, from: repoData)

        var readmeContent = project.readme
        var readmeRequest = URLRequest(url: URL(string: "https://api.github.com/repos/\(fullName)/readme")!)
        readmeRequest.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        if !githubToken.isEmpty {
            readmeRequest.setValue("Bearer \(githubToken)", forHTTPHeaderField: "Authorization")
        }
        if let (readmeData, _) = try? await URLSession.shared.data(for: readmeRequest),
           let readmeJSON = try? JSONDecoder().decode(GitHubReadme.self, from: readmeData),
           let decoded = Data(base64Encoded: readmeJSON.content.replacingOccurrences(of: "\n", with: "")),
           let text = String(data: decoded, encoding: .utf8) {
            readmeContent = text
        }

        let topics = repoInfo.topics ?? []
        var updated = project
        updated.description = repoInfo.description ?? project.description
        updated.readme = readmeContent
        updated.tags = extractTags(fromTopics: topics, readme: readmeContent)
        return updated
    }

    func fetchUserRepos(token: String) async throws -> [GitHubRepoSummary] {
        var allRepos: [GitHubRepoSummary] = []
        var page = 1
        while true {
            var request = URLRequest(url: URL(string: "https://api.github.com/user/repos?per_page=100&page=\(page)&type=all&sort=updated")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                throw ImportError.unauthorized
            }
            let repos = try JSONDecoder().decode([GitHubRepoSummary].self, from: data)
            if repos.isEmpty { break }
            allRepos.append(contentsOf: repos)
            page += 1
        }
        return allRepos
    }

    func importRepoWithToken(summary: GitHubRepoSummary, token: String) async throws -> Project {
        var repoRequest = URLRequest(url: URL(string: "https://api.github.com/repos/\(summary.full_name)")!)
        repoRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        repoRequest.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (repoData, _) = try await URLSession.shared.data(for: repoRequest)
        let repoInfo = try JSONDecoder().decode(GitHubRepo.self, from: repoData)

        var readmeContent = "# \(summary.name)\n\nAucun README trouvé."
        var readmeRequest = URLRequest(url: URL(string: "https://api.github.com/repos/\(summary.full_name)/readme")!)
        readmeRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        readmeRequest.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        if let (readmeData, _) = try? await URLSession.shared.data(for: readmeRequest),
           let readmeJSON = try? JSONDecoder().decode(GitHubReadme.self, from: readmeData),
           let decoded = Data(base64Encoded: readmeJSON.content.replacingOccurrences(of: "\n", with: "")),
           let text = String(data: decoded, encoding: .utf8) {
            readmeContent = text
        }

        let colors = ["#6C63FF", "#FF6584", "#43D9AD", "#F7B731", "#4ECDC4", "#FF6B6B", "#A29BFE"]
        let title = extractTitle(from: readmeContent) ?? repoInfo.name
        let topics = repoInfo.topics ?? summary.topics ?? []
        let tags = extractTags(fromTopics: topics, readme: readmeContent)
        return Project(
            name: title,
            description: repoInfo.description ?? "",
            readme: readmeContent,
            gitURL: repoInfo.html_url,
            tags: tags,
            color: colors.randomElement() ?? "#6C63FF"
        )
    }

    private func extractTags(fromTopics topics: [String], readme: String) -> [String] {
        if !topics.isEmpty { return topics }
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
        let lowercased = readme.lowercased()
        return keywords.filter { lowercased.contains($0) }.prefix(6).map { $0 }
    }

    private func extractTitle(from markdown: String) -> String? {
        return markdown
            .components(separatedBy: "\n")
            .first(where: { $0.hasPrefix("# ") })
            .map { raw -> String in
                var title = String(raw.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                // Strip markdown bold/italic
                title = title.replacingOccurrences(of: "\\*\\*([^*]+)\\*\\*", with: "$1", options: .regularExpression)
                title = title.replacingOccurrences(of: "\\*([^*]+)\\*", with: "$1", options: .regularExpression)
                title = title.replacingOccurrences(of: "__([^_]+)__", with: "$1", options: .regularExpression)
                return title
            }
    }

    // MARK: - Persistance

    private func createDirectoriesIfNeeded() {
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: readmesURL, withIntermediateDirectories: true)
    }

    private func save() {
        saveMetadata()
        for project in projects {
            try? project.readme.write(to: readmeURL(for: project.id), atomically: true, encoding: .utf8)
        }
    }

    private func saveMetadata() {
        let metadata = projects.map { ProjectMetadata(from: $0) }
        if let data = try? JSONEncoder().encode(metadata) {
            try? data.write(to: metadataURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode([ProjectMetadata].self, from: data) else {
            return
        }
        projects = metadata.map { meta in
            let readme = (try? String(contentsOf: readmeURL(for: meta.id), encoding: .utf8)) ?? ""
            return meta.toProject(readme: readme)
        }
        selectedProject = projects.first
    }

    // MARK: - Migration UserDefaults → FileManager

    private func migrateFromUserDefaultsIfNeeded() {
        let legacyKey = "readme_vault_projects"
        guard let data = UserDefaults.standard.data(forKey: legacyKey),
              let legacy = try? JSONDecoder().decode([Project].self, from: data) else {
            return
        }
        projects = legacy
        save()
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }

    // MARK: - Projets exemple

    private func loadSampleProjects() {
        let samples = [
            Project(
                name: "Mon Portfolio",
                description: "Site web personnel avec Next.js et Tailwind",
                readme: """
# Mon Portfolio 🚀

Site web personnel construit avec **Next.js 14** et **Tailwind CSS**.

## Stack technique
- Next.js 14 (App Router)
- Tailwind CSS
- TypeScript
- Vercel (déploiement)

## Installation

```bash
npm install
npm run dev
```

## Structure
```
├── app/
│   ├── page.tsx
│   └── layout.tsx
├── components/
└── public/
```
""",
                gitURL: "https://github.com/monuser/portfolio",
                tags: ["nextjs", "typescript", "web"],
                color: "#6C63FF"
            ),
            Project(
                name: "API REST",
                description: "Backend Node.js avec Express et PostgreSQL",
                readme: """
# API REST 🔧

Backend robuste construit avec **Node.js**, **Express** et **PostgreSQL**.

## Endpoints principaux

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | /api/users | Liste des utilisateurs |
| POST | /api/auth/login | Authentification |
| GET | /api/products | Catalogue produits |

## Variables d'environnement

```env
DATABASE_URL=postgresql://...
JWT_SECRET=...
PORT=3000
```

## Lancer le projet

```bash
npm install
npm run migrate
npm start
```
""",
                gitURL: "https://github.com/monuser/api-rest",
                tags: ["nodejs", "backend", "postgresql"],
                color: "#43D9AD"
            )
        ]
        projects = samples
        selectedProject = samples.first
        save()
    }
}

// MARK: - Erreurs import

enum ImportError: LocalizedError {
    case invalidURL
    case networkError
    case notFound
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL GitHub invalide"
        case .networkError: return "Erreur réseau"
        case .notFound: return "Dépôt introuvable"
        case .unauthorized: return "Token invalide ou expiré"
        }
    }
}

// MARK: - Modèles GitHub

struct GitHubRepo: Codable {
    let name: String
    let description: String?
    let html_url: String
    let topics: [String]?
}

struct GitHubReadme: Codable {
    let content: String
}

struct GitHubRepoSummary: Codable, Identifiable {
    let id: Int
    let name: String
    let full_name: String
    let description: String?
    let html_url: String
    let `private`: Bool
    let topics: [String]?

    var owner: String { String(full_name.split(separator: "/")[0]) }
}

// MARK: - Extension Color

// MARK: - Extension Date

extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension Color {
    init?(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard hex.count == 6 else { return nil }
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    func toHex() -> String {
        #if os(macOS)
        let native = NSColor(self)
        #else
        let native = UIColor(self)
        #endif
        guard let components = native.cgColor.components, components.count >= 3 else {
            return "#6C63FF"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
