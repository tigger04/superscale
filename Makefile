# ABOUTME: Build entry points for Superscale.
# ABOUTME: Provides build, test, install, release, and model conversion targets.

SHELL := /bin/bash
.DEFAULT_GOAL := help

BINARY_NAME := superscale
BUILD_DIR := .build/release
LINK_DIR := $(HOME)/.local/bin
RELEASE_VERSION ?=
SKIP_TESTS ?=

.PHONY: help build build-debug test test-one-off clean install uninstall release release-models sync convert-models download-models

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

download-models: ## Download missing models from GitHub release
	@./scripts/download-models.sh

build: download-models ## Build release binary
	swift build -c release

build-debug: download-models ## Build debug binary
	swift build

test: ## Run regression tests
	swift test

test-one-off: ## Run one-off tests
ifdef ISSUE
	swift test --filter "OT.*$(ISSUE)"
else
	swift test --filter "OT"
endif

clean: ## Remove build artefacts
	rm -rf .build

install: build ## Build and symlink to ~/.local/bin
	@mkdir -p "$(LINK_DIR)"
	@ln -sf "$(CURDIR)/$(BUILD_DIR)/$(BINARY_NAME)" "$(LINK_DIR)/$(BINARY_NAME)"
	@ln -sfn "$(CURDIR)/models" "$(CURDIR)/$(BUILD_DIR)/models"
	@echo "Installed: $(LINK_DIR)/$(BINARY_NAME)"
	@case ":$$PATH:" in \
		*":$(LINK_DIR):"*) ;; \
		*) echo "WARNING: $(LINK_DIR) is not in your PATH. Add it to your shell profile." ;; \
	esac

uninstall: ## Remove symlink from ~/.local/bin
	@if [ -L "$(LINK_DIR)/$(BINARY_NAME)" ]; then rm -f "$(LINK_DIR)/$(BINARY_NAME)"; fi
	@echo "Uninstalled."

convert-models: ## Convert PyTorch models to CoreML (requires Python venv)
	@if [ ! -d ".venv" ]; then \
		echo "Creating venv with Python 3.12..."; \
		/opt/homebrew/bin/python3.12 -m venv .venv; \
		. .venv/bin/activate && pip install --upgrade pip && pip install -r scripts/requirements-convert.txt; \
	fi
	. .venv/bin/activate && python scripts/convert_model.py --all --input-dir checkpoints --output-dir models

release: ## Tag a release and update Homebrew formula (usage: make release [VERSION=x.y.z])
ifndef SKIP_TESTS
	@$(MAKE) test
endif
	@./scripts/release.sh $(RELEASE_VERSION)

release-models: ## Upload model artefacts to GitHub Release (usage: make release-models)
	@./scripts/release-models.sh

sync: ## Stage all, commit, pull (merge), push
	@if git diff --quiet && git diff --cached --quiet && [ -z "$$(git ls-files --others --exclude-standard)" ]; then \
		echo "Nothing to commit."; \
	else \
		git add --all && \
		git commit -m "sync: $$(date +%Y-%m-%d)" && \
		echo "Committed."; \
	fi
	@if [ -f .gitmodules ]; then \
		git submodule update --init --recursive; \
	fi
	@./scripts/check-models.sh
	git pull --rebase=false
	git push
