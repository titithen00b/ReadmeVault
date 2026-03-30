import SwiftUI

struct ImportBulkGitHubView: View {
    @EnvironmentObject var store: ProjectStore
    @Environment(\.dismiss) var dismiss

    enum Step { case token, loading, select, importing, done }

    @State private var token = ""
    @State private var step: Step = .token
    @State private var repos: [GitHubRepoSummary] = []
    @State private var selectedIDs: Set<Int> = []
    @State private var error: String? = nil
    @State private var progress: (current: Int, total: Int) = (0, 0)
    @State private var importedCount = 0
    @State private var currentRepoName = ""
    @State private var filterText = ""

    var filteredRepos: [GitHubRepoSummary] {
        if filterText.isEmpty { return repos }
        return repos.filter { $0.name.localizedCaseInsensitiveContains(filterText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#6C63FF")!.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "tray.and.arrow.down.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#6C63FF"))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Import en masse")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("Importe tous tes repos GitHub d'un coup")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button { dismiss() } label: {
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
                    case .token:   tokenView
                    case .loading: loadingView
                    case .select:  selectView
                    case .importing: importingView
                    case .done:    doneView
                    }
                }
                .padding(24)
            }

            if let error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text(error).font(.system(size: 12)).foregroundColor(.orange)
                    Spacer()
                    Button { self.error = nil } label: {
                        Image(systemName: "xmark").font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 24)
            }

            Divider()

            // Actions
            HStack {
                if step == .select {
                    Button("Retour") {
                        step = .token
                        repos = []
                        selectedIDs = []
                    }
                }
                Spacer()
                Button("Annuler") { dismiss() }
                    .keyboardShortcut(.escape)

                if step == .token {
                    Button("Charger mes repos") {
                        Task { await fetchRepos() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#6C63FF"))
                    .disabled(token.isEmpty)
                } else if step == .select {
                    Button("Importer \(selectedIDs.count) repo\(selectedIDs.count > 1 ? "s" : "")") {
                        Task { await importSelected() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#6C63FF"))
                    .disabled(selectedIDs.isEmpty)
                } else if step == .done {
                    Button("Fermer") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "#43D9AD"))
                }
            }
            .padding(20)
        }
        .frame(width: 580, height: 520)
    }

    // MARK: - Token

    var tokenView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Personal Access Token GitHub")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $token)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .onSubmit { Task { await fetchRepos() } }

                Text("github.com → Settings → Developer settings → Personal access tokens → scope \"repo\"")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Ce qui sera importé")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                ForEach([
                    ("lock.fill", "Repos privés inclus", "#6C63FF"),
                    ("doc.text.fill", "README de chaque repo", "#43D9AD"),
                    ("tag.fill", "Nom, description, topics", "#FF6584")
                ], id: \.0) { icon, label, color in
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: color))
                            .frame(width: 20)
                        Text(label).font(.system(size: 13))
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.cardBackground))
        }
    }

    // MARK: - Loading

    var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(.circular)
                .tint(Color(hex: "#6C63FF"))
            Text("Chargement de tes repos...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Select

    var selectView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(repos.count) repos trouvés")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(selectedIDs.count == repos.count ? "Tout désélectionner" : "Tout sélectionner") {
                    toggleSelectAll()
                }
                .font(.system(size: 12))
                .buttonStyle(.plain)
                .foregroundColor(Color(hex: "#6C63FF"))
                .keyboardShortcut("a", modifiers: .command)
            }

            TextField("Filtrer...", text: $filterText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))

            VStack(spacing: 4) {
                ForEach(filteredRepos) { repo in
                    RepoRowView(repo: repo, isSelected: selectedIDs.contains(repo.id)) {
                        if selectedIDs.contains(repo.id) {
                            selectedIDs.remove(repo.id)
                        } else {
                            selectedIDs.insert(repo.id)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Importing

    var importingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView(value: Double(progress.current), total: Double(progress.total))
                .tint(Color(hex: "#6C63FF"))
                .frame(maxWidth: .infinity)
            Text("\(progress.current) / \(progress.total)")
                .font(.system(size: 14, weight: .semibold))
            Text(currentRepoName)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Done

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
            Text("\(importedCount) projet\(importedCount > 1 ? "s" : "") importé\(importedCount > 1 ? "s" : "") !")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text("Retrouve-les dans ta vault.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Actions

    func toggleSelectAll() {
        if selectedIDs.count == repos.count {
            selectedIDs = []
        } else {
            selectedIDs = Set(repos.map { $0.id })
        }
    }

    @MainActor
    func fetchRepos() async {
        error = nil
        step = .loading
        do {
            repos = try await store.fetchUserRepos(token: token)
            selectedIDs = Set(repos.map { $0.id })
            step = .select
        } catch {
            self.error = error.localizedDescription
            step = .token
        }
    }

    @MainActor
    func importSelected() async {
        let toImport = repos.filter { selectedIDs.contains($0.id) }
        progress = (0, toImport.count)
        step = .importing
        importedCount = 0

        for repo in toImport {
            currentRepoName = repo.full_name
            if let project = try? await store.importRepoWithToken(summary: repo, token: token) {
                store.add(project)
                importedCount += 1
            }
            progress.current += 1
        }
        step = .done
    }
}

// MARK: - RepoRowView

struct RepoRowView: View {
    let repo: GitHubRepoSummary
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? Color(hex: "#6C63FF") : .secondary.opacity(0.4))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(repo.name)
                            .font(.system(size: 13, weight: .semibold))
                        if repo.private {
                            Text("privé")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.secondary.opacity(0.12)))
                        }
                    }
                    if let desc = repo.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#6C63FF")!.opacity(0.06) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
