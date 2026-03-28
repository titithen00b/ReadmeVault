# 🗄️ ReadmeVault

> Centralisez tous vos READMEs de projets en un seul endroit — natif macOS, rapide, élégant.

![SwiftUI](https://img.shields.io/badge/SwiftUI-macOS%2014%2B-blue?style=for-the-badge&logo=swift)
![Xcode](https://img.shields.io/badge/Xcode-15%2B-blue?style=for-the-badge&logo=xcode)
![Licence](https://img.shields.io/badge/Licence-MIT-green?style=for-the-badge)
![Langue](https://img.shields.io/badge/Langue-Français-blueviolet?style=for-the-badge)
![Build](https://img.shields.io/github/actions/workflow/status/Titithen00b/ReadmeVault/build.yml?style=for-the-badge&label=Build)

---

## Présentation

**ReadmeVault** est une application macOS native construite avec **SwiftUI** qui permet de centraliser, organiser et consulter les fichiers README de tous vos projets. Plus besoin d'ouvrir GitHub ou de fouiller dans vos dossiers — tous vos READMEs sont accessibles en un clic, avec rendu Markdown complet.

---

## Fonctionnalités

### Import
- **Import GitHub** — Colle une URL de dépôt GitHub, l'app récupère automatiquement le README, la description, les topics et le nom via l'API REST GitHub
- **Import fichier local** — Ouvre un fichier `.md` depuis le Finder (`⌘O`), le titre, la description et les tags sont détectés automatiquement
- **Saisie manuelle** — Crée un projet et colle ton Markdown directement dans l'éditeur

### Rendu Markdown
- Rendu HTML via **WKWebView** avec parser Markdown maison
- Support complet : titres, gras/italique, code inline et blocs, tableaux, listes, blockquotes, liens, images, badges shields.io
- Thème adaptatif Light/Dark
- Couleur d'accent personnalisable par projet

### Organisation
- **Tags** — ajout libre, filtre par tag en sidebar
- **Couleur par projet** — palette de 12 couleurs
- **Recherche** — filtre en temps réel sur nom, description et tags (`⌘F`)
- **3 onglets** par projet : README rendu / Markdown brut / Informations

### Stockage
- Données stockées dans `~/Documents/ReadmeVault/`
- `projects.json` pour les métadonnées (léger, chargement rapide)
- `readmes/<uuid>.md` pour chaque README (pas de limite de taille)
- Migration automatique depuis l'ancien stockage UserDefaults au premier lancement
- Architecture prête pour iCloud (un changement d'URL suffit)

### Interface
- Interface native macOS avec `NavigationSplitView`
- Menus système entièrement en français
- Fenêtre **À propos** personnalisée
- Raccourcis clavier complets
- Icône custom pour macOS, iPhone et iPad

---

## Captures d'écran

> *(à venir)*

---

## Prérequis

| Élément | Version minimale |
|---------|-----------------|
| macOS | 14.0 (Sonoma) |
| Xcode | 15.0 |
| Swift | 5.9 |

---

## Installation

### Option 1 — Télécharger la dernière release

Rends-toi sur la page [Releases](https://github.com/Titithen00b/ReadmeVault/releases), télécharge `ReadmeVault.zip`, décompresse et glisse `ReadmeVault.app` dans `/Applications`.

> Première ouverture : clic droit → **Ouvrir** pour bypasser Gatekeeper.

### Option 2 — Build depuis les sources

```bash
git clone https://github.com/Titithen00b/ReadmeVault.git
cd ReadmeVault
make run
```

### Commandes disponibles

```bash
make run      # Build Debug + lance l'app
make build    # Build sans lancer
make open     # Rouvre sans rebuild
make clean    # Nettoie DerivedData
make install  # Copie dans /Applications
```

> **Note** — À la première ouverture dans Xcode, va dans le target `ReadmeVault` → *Signing & Capabilities* → sélectionne ton compte Apple (gratuit suffit).

---

## CI / CD

| Workflow | Déclencheur | Action |
|----------|-------------|--------|
| `build.yml` | Push / PR sur `main` | Vérifie que le projet compile |
| `release.yml` | Push d'un tag `v*` | Archive + publie le `.app` sur GitHub Releases |

Pour créer une nouvelle release :
```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## Architecture

```
ReadmeVault/
├── ReadmeVaultApp.swift       # Point d'entrée @main, menus, notifications
├── ProjectStore.swift         # Modèle Project + Store ObservableObject + API GitHub
├── ContentView.swift          # NavigationSplitView principal + gestion des sheets
├── SidebarView.swift          # Liste projets, recherche, filtres tags
├── ProjectDetailView.swift    # 3 onglets : README / Brut / Infos
├── MarkdownRendererView.swift # WKWebView + parser Markdown maison
├── ProjectFormView.swift      # Sheet création/édition/import avec auto-détection
├── ImportGitHubView.swift     # Import GitHub en 3 étapes
└── AboutView.swift            # Fenêtre À propos custom
```

---

## Modèle de données

```swift
struct Project: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String          // Titre (auto-extrait du # Titre)
    var description: String   // Premier paragraphe du README
    var readme: String        // Contenu Markdown complet
    var gitURL: String        // URL du dépôt
    var tags: [String]        // Tags (auto-détectés ou manuels)
    var color: String         // Couleur hex ex: "#6C63FF"
    var createdAt: Date
    var updatedAt: Date
}
```

### Stockage sur disque

```
~/Documents/ReadmeVault/
├── projects.json          ← métadonnées de tous les projets (sans le contenu README)
└── readmes/
    ├── <uuid>.md          ← README de chaque projet
    └── <uuid>.md
```

---

## Raccourcis clavier

| Raccourci | Action |
|-----------|--------|
| `⌘N` | Nouveau projet |
| `⌘O` | Ouvrir un fichier README local |
| `⌘I` | Importer depuis GitHub |
| `⌘F` | Rechercher |
| `⌘↩` | Enregistrer (dans le formulaire) |
| `⎋` | Annuler / Fermer |

---

## Palette de couleurs

| Couleur | Hex | Usage |
|---------|-----|-------|
| Violet | `#6C63FF` | Accent principal |
| Rose | `#FF6584` | Projets |
| Vert menthe | `#43D9AD` | Import GitHub |
| Jaune | `#F7B731` | Projets |
| Turquoise | `#4ECDC4` | Projets |
| Corail | `#FF6B6B` | Projets |

---

## Pistes d'évolution

- [ ] Support des dépôts GitHub privés (token OAuth)
- [ ] Export PDF d'un README
- [ ] Sync iCloud (remplacer FileManager local par container iCloud)
- [ ] Glisser-déposer pour réordonner les projets
- [ ] Raccourci menu bar (NSStatusItem)
- [ ] Mode présentation plein écran
- [ ] Import depuis GitLab / Bitbucket
- [ ] Port iPhone & iPad (iOS 17+)

---

## Contribution

Les contributions sont les bienvenues. Pour proposer une modification :

1. Fork le dépôt
2. Crée une branche (`git checkout -b feature/ma-fonctionnalite`)
3. Commit tes changements (`git commit -m 'Ajout de ma fonctionnalité'`)
4. Push (`git push origin feature/ma-fonctionnalite`)
5. Ouvre une Pull Request

---

## Licence

MIT © 2026 Valentin R. (Titithen00b) — voir [LICENSE](LICENSE)
