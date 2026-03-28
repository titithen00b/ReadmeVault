# ================================
#  ReadmeVault — Makefile
#  Compiler et lancer sans Xcode UI
# ================================

PROJECT     = ReadmeVault.xcodeproj
SCHEME      = ReadmeVault
CONFIG      = Debug
DERIVED     = $(HOME)/Library/Developer/Xcode/DerivedData
APP_PATH    = $(shell find $(DERIVED) -name "ReadmeVault.app" -path "*/Debug/*" 2>/dev/null | head -1)

# Désactive la signature de code pour le dev local
SIGN_FLAGS  = CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

.DEFAULT_GOAL := help

# -------------------------------------------------------
.PHONY: help
help: ## Affiche cette aide
	@echo ""
	@echo "  \033[1;35mReadmeVault\033[0m — commandes disponibles"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""

# -------------------------------------------------------
.PHONY: build
build: ## Compile l'app en Debug
	@echo "\033[1;34m▶ Compilation...\033[0m"
	@xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIG) \
		$(SIGN_FLAGS) \
		build \
		| xcpretty 2>/dev/null || xcodebuild \
			-project $(PROJECT) \
			-scheme $(SCHEME) \
			-configuration $(CONFIG) \
			$(SIGN_FLAGS) \
			build
	@echo "\033[1;32m✓ Build terminé\033[0m"

# -------------------------------------------------------
.PHONY: run
run: build ## Compile puis lance l'app
	@echo "\033[1;34m▶ Lancement de ReadmeVault...\033[0m"
	@APP="$(APP_PATH)"; \
	if [ -z "$$APP" ]; then \
		echo "\033[1;31m✗ App introuvable. Lance 'make build' d'abord.\033[0m"; exit 1; \
	fi; \
	open "$$APP"

# -------------------------------------------------------
.PHONY: release
release: ## Compile en Release (optimisé)
	@echo "\033[1;34m▶ Build Release...\033[0m"
	@xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		$(SIGN_FLAGS) \
		build \
		| xcpretty 2>/dev/null || xcodebuild \
			-project $(PROJECT) \
			-scheme $(SCHEME) \
			-configuration Release \
			$(SIGN_FLAGS) \
			build
	@echo "\033[1;32m✓ Release build terminé\033[0m"

# -------------------------------------------------------
.PHONY: clean
clean: ## Supprime les fichiers de build
	@echo "\033[1;33m⚑ Nettoyage...\033[0m"
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean $(SIGN_FLAGS) > /dev/null 2>&1
	@echo "\033[1;32m✓ Nettoyé\033[0m"

# -------------------------------------------------------
.PHONY: open
open: ## Ouvre l'app déjà buildée (sans recompiler)
	@APP="$(APP_PATH)"; \
	if [ -z "$$APP" ]; then \
		echo "\033[1;31m✗ App introuvable. Lance 'make build' d'abord.\033[0m"; exit 1; \
	fi; \
	echo "\033[1;34m▶ Ouverture de $$APP\033[0m"; \
	open "$$APP"

# -------------------------------------------------------
.PHONY: where
where: ## Affiche le chemin de l'app buildée
	@APP="$(APP_PATH)"; \
	if [ -z "$$APP" ]; then \
		echo "\033[1;31m✗ Aucun build trouvé.\033[0m"; \
	else \
		echo "\033[1;32m$$APP\033[0m"; \
	fi

# -------------------------------------------------------
.PHONY: install
install: release ## Installe l'app dans /Applications
	@APP="$(shell find $(DERIVED) -name "ReadmeVault.app" -path "*/Release/*" 2>/dev/null | head -1)"; \
	if [ -z "$$APP" ]; then \
		echo "\033[1;31m✗ Build Release introuvable.\033[0m"; exit 1; \
	fi; \
	echo "\033[1;34m▶ Installation dans /Applications...\033[0m"; \
	cp -R "$$APP" /Applications/ReadmeVault.app; \
	echo "\033[1;32m✓ ReadmeVault installé dans /Applications !\033[0m"

# -------------------------------------------------------
.PHONY: xcpretty-check
xcpretty-check: ## Installe xcpretty si absent (logs plus lisibles)
	@which xcpretty > /dev/null 2>&1 || (echo "💡 Installe xcpretty pour de meilleurs logs : gem install xcpretty" )
