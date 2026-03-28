# CLAUDE.md — Contexte projet pour l'IA

> Ce fichier donne à Claude tout le contexte nécessaire pour t'aider à développer ReadmeVault.
> Colle son contenu en début de conversation quand tu veux continuer le dev.

---

## 🗂 Projet : ReadmeVault

App macOS native en **SwiftUI** (macOS 14+, Xcode 15+).
Permet de centraliser tous les READMEs de projets avec import GitHub.

## 📁 Architecture des fichiers

```
ReadmeVault/
├── .vscode/                    # Config VSCode (settings, tasks, snippets)
├── Makefile                    # make run / build / clean / install
├── ReadmeVault.xcodeproj/
└── ReadmeVault/
    ├── ReadmeVaultApp.swift    # @main, App entry, Notification.Name extensions
    ├── ProjectStore.swift      # Modèle Project + ObservableObject store + GitHub API
    ├── ContentView.swift       # NavigationSplitView principal + EmptyStateView
    ├── SidebarView.swift       # Liste projets, recherche, filtres tags, TagChip
    ├── ProjectDetailView.swift # 3 onglets : README rendu / brut / infos + FlowLayout
    ├── MarkdownRendererView.swift  # NSViewRepresentable WKWebView + parser Markdown maison
    ├── ProjectFormView.swift   # Sheet création/édition (2 onglets : Général / README)
    └── ImportGitHubView.swift  # Import GitHub en 3 étapes (input → loading → preview)
```

## 🧩 Modèle de données

```swift
struct Project: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var description: String
    var readme: String          // Contenu Markdown brut
    var gitURL: String
    var tags: [String]
    var color: String           // Hex string ex: "#6C63FF"
    var createdAt: Date
    var updatedAt: Date

    var accentColor: Color      // Computed depuis color hex
    var initials: String        // Computed : 2 premières lettres
}
```

## 🏪 Store

`ProjectStore` est un `@MainActor ObservableObject` injecté via `.environmentObject`.

Méthodes principales :
- `add(_ project:)` — ajoute + sélectionne + sauvegarde
- `update(_ project:)` — met à jour updatedAt + sauvegarde
- `delete(_ project:)` — supprime + reset sélection
- `importFromGitHub(url:) async throws -> Project` — appelle l'API GitHub REST

Persistance : `UserDefaults` avec clé `"readme_vault_projects"`.

## 🎨 Design system

Palette principale :
```
#6C63FF  violet (couleur principale / accent)
#FF6584  rose
#43D9AD  vert menthe
#F7B731  jaune
#4ECDC4  turquoise
#FF6B6B  rouge corail
```

Utilitaire couleur dans `ProjectStore.swift` :
```swift
Color(hex: "#6C63FF")  // Extension Color init?(hex:)
```

## 🔧 Commandes de build

```bash
make run      # build Debug + lance l'app  [⌘⇧B dans VSCode]
make build    # build sans lancer
make open     # rouvre sans rebuild
make clean    # nettoie DerivedData
make install  # copie dans /Applications
```

## 📋 Conventions de code

- Indentation : 4 espaces
- Nommage : camelCase pour variables/fonctions, PascalCase pour types
- Les vues SwiftUI utilisent `@EnvironmentObject var store: ProjectStore`
- Toujours `@MainActor` sur les classes ObservableObject
- Les sheets sont présentées via `@State private var showXxx = false`
- Les couleurs via CSS variables dans le rendu WebKit de MarkdownRendererView

## 🚧 Pistes d'évolution possibles

- [ ] Support des dépôts GitHub privés (token OAuth)
- [ ] Export PDF d'un README
- [ ] Sync iCloud (remplacer UserDefaults par NSUbiquitousKeyValueStore)
- [ ] Glisser-déposer pour réordonner les projets
- [ ] Raccourci menu bar (NSStatusItem)
- [ ] Mode présentation plein écran du README
- [ ] Importer depuis GitLab / Bitbucket
