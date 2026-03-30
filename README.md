# 🗄️ ReadmeVault

> Centralisez tous vos READMEs de projets en un seul endroit — natif macOS & iOS, rapide, élégant.

![SwiftUI](https://img.shields.io/badge/SwiftUI-macOS%2014%2B%20%7C%20iOS%2017%2B-blue?style=for-the-badge&logo=swift)
![Xcode](https://img.shields.io/badge/Xcode-16%2B-blue?style=for-the-badge&logo=xcode)
![Licence](https://img.shields.io/badge/Licence-MIT-green?style=for-the-badge)
![Langue](https://img.shields.io/badge/Langue-Français-blueviolet?style=for-the-badge)
![Build](https://img.shields.io/github/actions/workflow/status/Titithen00b/ReadmeVault/build.yml?style=for-the-badge&label=Build)

---

## Présentation

**ReadmeVault** est une application **macOS & iOS** native construite avec **SwiftUI** qui permet de centraliser, organiser et consulter les fichiers README de tous vos projets. Plus besoin d'ouvrir GitHub ou de fouiller dans vos dossiers — tous vos READMEs sont accessibles en un clic, avec rendu Markdown complet.

---

## Fonctionnalités

### Import
- **Import GitHub** — Colle une URL de dépôt GitHub, l'app récupère automatiquement le README, la description, les topics et le nom via l'API REST GitHub
- **Import en masse** — Connecte ton compte GitHub via un Personal Access Token et importe tous tes repos (publics **et privés**) en une seule opération, avec sélection individuelle (`⌘A` pour tout sélectionner)
- **Import fichier local** — Ouvre un fichier `.md` depuis le Finder (`⌘O`), le titre, la description et les tags sont détectés automatiquement
- **Saisie manuelle** — Crée un projet et colle ton Markdown directement dans l'éditeur

### Mise à jour
- **Rafraîchir depuis GitHub** — Bouton ↺ dans la vue détail pour re-fetch le README, la description et les topics depuis GitHub
- Support des **repos privés** via token stocké — saisi une fois, réutilisé automatiquement
- Si aucun topic GitHub n'est défini, les **tags sont auto-détectés** depuis le contenu du README (Swift, React, Docker, etc.)

### Export & Partage
- **Export PDF** — Exporte le README rendu en PDF
- **Share sheet** — Partage le Markdown via les services système (Mail, Messages, AirDrop…)
- **Copier le README** — Copie le Markdown brut en un clic

### Rendu Markdown
- Rendu HTML via **WKWebView** avec parser Markdown maison
- Support complet : titres, gras/italique, code inline et blocs, tableaux, listes, blockquotes, liens, images, badges shields.io
- Thème adaptatif Light/Dark
- Couleur d'accent personnalisable par projet

### Organisation
- **Tags** — ajout libre, filtre par tag en sidebar
- **Couleur par projet** — palette de 12 couleurs
- **Recherche plein texte** — filtre en temps réel sur nom, description, tags et contenu README
- **Tri** — par nom, date de modification ou taille du README
- **Épingler** — projets épinglés toujours en tête de liste
- **Multi-sélection** — `⌘+clic` pour sélectionner plusieurs projets, `⌫` pour suppression groupée
- **Dupliquer** — clone un projet (`⌘D`)
- **Glisser-déposer** — réordonne les projets manuellement
- **3 onglets** par projet : README rendu / Markdown brut / Informations
- **Compteur** — nombre de mots, caractères et lignes dans l'onglet Infos

### Stockage
- Données stockées dans `~/Library/Application Support/ReadmeVault/`
- `projects.json` pour les métadonnées
- `readmes/<uuid>.md` pour chaque README (pas de limite de taille)

---

## Plateformes

| Plateforme | Version minimale | Statut |
|------------|-----------------|--------|
| macOS | 14.0 (Sonoma) | ✅ Stable |
| iPhone | iOS 17.0 | ✅ Stable |
| iPad | iOS 17.0 | ✅ Stable |

---

## Installation

### macOS — Télécharger la dernière release

Rends-toi sur la page [Releases](https://github.com/Titithen00b/ReadmeVault/releases), télécharge `ReadmeVault.zip`, décompresse et glisse `ReadmeVault.app` dans `/Applications`.

> Première ouverture : clic droit → **Ouvrir** pour bypasser Gatekeeper.

### ⚠️ App non signée — étapes obligatoires

L'app est distribuée sans signature Apple. Après avoir copié `ReadmeVault.app` dans `/Applications` :

**1. Retirer le flag de quarantaine**

```bash
xattr -cr /Applications/ReadmeVault.app
```

**2. Forcer l'enregistrement auprès de macOS**

```bash
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f /Applications/ReadmeVault.app
```

**3. Relancer le Dock / Launchpad**

```bash
killall Dock
```

> Après ces trois commandes, ReadmeVault apparaît dans le Launchpad et s'ouvre normalement.

### macOS — Build depuis les sources

```bash
git clone https://github.com/Titithen00b/ReadmeVault.git
cd ReadmeVault
make run
```

### Commandes disponibles

```bash
make run       # Build Debug + lance l'app
make build     # Build sans lancer
make open      # Rouvre sans rebuild
make clean     # Nettoie DerivedData
make install   # Copie dans /Applications
make uninstall # Supprime l'app + toutes les données
```

### iOS — Via Xcode

1. Clone le repo, ouvre `ReadmeVault.xcodeproj`
2. Sélectionne le scheme `ReadMeVault`
3. Branche ton iPhone et appuie sur `⌘R`

---

## Architecture

```
ReadmeVault/
├── ReadmeVaultApp.swift         # Point d'entrée @main, menus, status bar (macOS)
├── ProjectStore.swift           # Modèle Project + Store + API GitHub (partagé)
├── SharedViews.swift            # Composants partagés macOS/iOS
├── ContentView.swift            # NavigationSplitView macOS
├── ContentViewIOS.swift         # NavigationSplitView iOS
├── SidebarView.swift            # Sidebar macOS
├── ProjectListViewIOS.swift     # Liste projets iOS
├── ProjectDetailView.swift      # Vue détail macOS
├── ProjectDetailViewIOS.swift   # Vue détail iOS
├── MarkdownRendererView.swift   # WKWebView cross-platform
├── ProjectFormView.swift        # Sheet création/édition (partagé)
├── ImportGitHubView.swift       # Import GitHub unitaire (partagé)
├── ImportBulkGitHubView.swift   # Import en masse avec token (partagé)
├── MenuBarView.swift            # Status bar macOS
├── AboutView.swift              # Fenêtre À propos (macOS)
└── HelpView.swift               # Aide (macOS)
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
    var tags: [String]        // Tags (GitHub topics ou auto-détectés)
    var color: String         // Couleur hex ex: "#6C63FF"
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
}
```

---

## Raccourcis clavier (macOS)

| Raccourci | Action |
|-----------|--------|
| `⌘N` | Nouveau projet |
| `⌘O` | Ouvrir un fichier README local |
| `⌘I` | Importer depuis GitHub |
| `⌘D` | Dupliquer le projet sélectionné |
| `⌘F` | Rechercher |
| `⌘A` | Tout sélectionner (import en masse) |
| `⌘↩` | Enregistrer (dans le formulaire) |
| `⌫` | Supprimer le(s) projet(s) sélectionné(s) |
| `⎋` | Annuler / Fermer |

---

## CI / CD

| Workflow | Déclencheur | Action |
|----------|-------------|--------|
| `build.yml` | Push / PR sur `master` | Vérifie que le projet compile |
| `release.yml` | Push d'un tag `v*` | Archive + publie le `.app` sur GitHub Releases |

```bash
git tag v2.2.0
git push origin v2.2.0
```

---

## Pistes d'évolution

- [ ] Sync iCloud
- [ ] Import depuis GitLab / Bitbucket
- [ ] Mode présentation plein écran
- [ ] Raccourcis Siri (iOS)
- [ ] Widget iOS

---

## Licence

MIT © 2026 Valentin R. (Titithen00b) — voir [LICENSE](LICENSE)
