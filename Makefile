# Added by aaron@ardvarx.com on 2025.11.08.SAT

SHELL = /bin/bash
MAKEFLAGS += --no-print-directory

# 🚫 DEPLOYMENT GUARD: Claude should NEVER run 'make install' or 'make uninstall'
# See /home/aaron/src/go/src/github.com/ardvarx/CLAUDE.md for deployment workflow

project = opencommit


################################################################################
# secrets
#

# INF
INF = INFISICAL_TOKEN=$$(get_inf_token.sh) infisical secrets --silent --plain --projectId=${ARDVARX_INF_PROJECT_ID}


CI_REPOS_DIR               = $$($(INF) --env=xx get CI_REPOS_DIR)
CI_TOKEN_BUMP_VERSION      = $$($(INF) --env=xx get CI_TOKEN_BUMP_VERSION)
CI_PROJECT_SLUG_OPENCOMMIT = $$($(INF) --env=xx get CI_PROJECT_SLUG_OPENCOMMIT)


.PHONY: print-secrets
print-secrets:
	@echo "CI_REPOS_DIR .......................... '${CI_REPOS_DIR}'"
	@echo "CI_TOKEN_BUMP_VERSION ................. '${CI_TOKEN_BUMP_VERSION}'"
	@echo "CI_PROJECT_SLUG_OPENCOMMIT ............ '${CI_PROJECT_SLUG_OPENCOMMIT}'"


################################################################################
# dirs
#

projectDir = ${REPOS_DIR}/${project}
ifeq (${CI}, true)
	projectDir = ${CI_REPOS_DIR}
endif

sharedScriptsDir = ${REPOS_DIR}/shared-scripts
ifeq (${CI}, true)
	sharedScriptsDir = ${CI_REPOS_DIR}/shared-scripts
endif

tmpDir = ${projectDir}/tmp


.PHONY: print-dirs
print-dirs:
	@echo "--------------------------------------------------------------------------------"
	@echo "[${project} --> print-dirs]"
	@echo "tmpDir ................ ${tmpDir}"


################################################################################
# bump
#

tmpCiDir = ${tmpDir}/ci
bumpVersionScript = ${sharedScriptsDir}/bump/bump_version.sh


.PHONY: bump
bump:
	@echo "--------------------------------------------------------------------------------"
	@echo "[${project} --> bump]"
	@${bumpVersionScript} \
	--circle-ci-token ${CI_TOKEN_BUMP_VERSION} \
	--circle-ci-project-slug ${CI_PROJECT_SLUG_OPENCOMMIT} \
	--tmp-ci-dir ${tmpCiDir} \
	--skip-ci


################################################################################
# install-dependencies
#

.PHONY: install-dependencies
install-dependencies:
	@echo "--------------------------------------------------------------------------------"
	@echo "[opencommit-fork]: install-dependencies"
	@npm install


################################################################################
# build
#

.PHONY: build
build:
	@echo "--------------------------------------------------------------------------------"
	@echo "[opencommit-fork]: build"
	@npm run build


################################################################################
# link
#

.PHONY: link
link:
	@echo "--------------------------------------------------------------------------------"
	@echo "[opencommit-fork]: link"
	@npm link


################################################################################
# install
#

.PHONY: install
install:
	@echo "--------------------------------------------------------------------------------"
	@echo "[opencommit-fork]: install"
	@$(MAKE) install-dependencies
	@$(MAKE) build
	@$(MAKE) link
	@echo ""
	@echo "✓ Installation complete"
	@opencommit --version


################################################################################
################################################################################
################################################################################
# Configuration Management
#

################################################################################
# Show current configuration
#

.PHONY: show-config
show-config:
	@echo "--------------------------------------------------------------------------------"
	@echo "[opencommit-fork]: Current Configuration"
	@echo "AI Provider: $$(opencommit config get OCO_AI_PROVIDER)"
	@echo "AI Model:    $$(opencommit config get OCO_MODEL)"
	@echo "Git Push:    $$(opencommit config get OCO_GITPUSH)"
	@echo "API Key:     [hidden]"


################################################################################
# List all available models
#

.PHONY: list-models
list-models:
	@echo "--------------------------------------------------------------------------------"
	@echo "[opencommit-fork]: Available AI Models"
	@echo ""
	@echo "Anthropic Claude Models:"
	@grep -E "^\s+'claude-" src/commands/config.ts | sed "s/[',]//g" | sed 's/^[[:space:]]*/  - /' | sort -r
	@echo ""
	@echo "Google Gemini Models:"
	@grep -E "^\s+'google/gemini-" src/commands/config.ts | sed "s/[',]//g" | sed 's/^[[:space:]]*/  - /'
	@echo ""
	@echo "DeepSeek Models:"
	@grep -E "^\s+'deepseek-" src/commands/config.ts | sed "s/[',]//g" | sed 's/^[[:space:]]*/  - /'
	@echo ""
	@echo "Mistral Models:"
	@grep -E "^\s+'mistralai/" src/commands/config.ts | sed "s/[',]//g" | sed 's/^[[:space:]]*/  - /'
	@echo ""
	@echo "Groq Models:"
	@grep -E "^\s+'groq/" src/commands/config.ts | sed "s/[',]//g" | sed 's/^[[:space:]]*/  - /'
	@echo ""
	@echo "To set a model, run: make set-model MODEL=<model-name>"
	@echo "Current model: $$(opencommit config get OCO_MODEL)"


################################################################################
# Set AI model
# Usage: make set-model MODEL=claude-sonnet-4-20250514
#
# Common models:
#   - claude-sonnet-4-20250514 (Latest Sonnet 4 - Recommended)
#   - claude-opus-4-20250514 (Latest Opus 4 - Most powerful)
#   - claude-3-7-sonnet-20250219 (Claude 3.7)
#   - claude-3-5-sonnet-20241022 (Claude 3.5)
#

.PHONY: set-model
set-model:
	@echo "--------------------------------------------------------------------------------"
	@echo "[opencommit-fork]: set-model (MODEL=$(MODEL))"
	@if [ -z "$(MODEL)" ]; then \
		echo "ERROR: MODEL required. Usage: make set-model MODEL=claude-sonnet-4-20250514"; \
		echo ""; \
		echo "Available models:"; \
		echo "  - claude-sonnet-4-20250514 (Latest Sonnet 4 - Recommended)"; \
		echo "  - claude-opus-4-20250514 (Latest Opus 4 - Most powerful)"; \
		echo "  - claude-3-7-sonnet-20250219 (Claude 3.7)"; \
		echo "  - claude-3-5-sonnet-20241022 (Claude 3.5)"; \
		exit 1; \
	fi
	@echo "Setting OCO_MODEL to: $(MODEL)"
	@opencommit config set OCO_MODEL=$(MODEL)
	@echo ""
	@echo "✓ Model updated successfully"
	@$(MAKE) show-config


################################################################################
################################################################################
################################################################################
# Pull and Merge the Fix (As per Claude-Code)
#

################################################################################
# Pull PR from upstream repository
# Usage: make pull-pr PR=521
# This will:
#   1. Add upstream remote if it doesn't exist
#   2. Fetch the PR from upstream
#   3. Create a local branch pr-<number> from the PR
#   4. Checkout the new branch
#

.PHONY: pull-pr
pull-pr:
	@echo "--------------------------------------------------------------------------------"
	@echo "[opencommit-fork]: pull-pr (PR=$(PR))"
	@if [ -z "$(PR)" ]; then \
		echo "ERROR: PR number required. Usage: make pull-pr PR=521"; \
		exit 1; \
	fi
	@echo "Adding upstream remote (if not exists)..."
	@git remote add upstream https://github.com/di-sukharev/opencommit.git 2>/dev/null || echo "Upstream remote already exists"
	@echo "Fetching PR #$(PR) from upstream..."
	@git fetch upstream pull/$(PR)/head:pr-$(PR)
	@echo "Checking out branch pr-$(PR)..."
	@git checkout pr-$(PR)
	@echo ""
	@echo "✓ Successfully pulled PR #$(PR) into local branch 'pr-$(PR)'"
	@echo "  To merge into your fork's master:"
	@echo "    git checkout master"
	@echo "    git merge pr-$(PR)"
	@echo "    git push origin master"


################################################################################
# Merge a previously pulled PR into current branch
# Usage: make merge-pr PR=521
#

.PHONY: merge-pr
merge-pr:
	@echo "--------------------------------------------------------------------------------"
	@echo "[opencommit-fork]: merge-pr (PR=$(PR))"
	@if [ -z "$(PR)" ]; then \
		echo "ERROR: PR number required. Usage: make merge-pr PR=521"; \
		exit 1; \
	fi
	@echo "Merging pr-$(PR) into current branch..."
	@git merge pr-$(PR)
	@echo ""
	@echo "✓ Successfully merged PR #$(PR)"
	@echo "  To push to your fork: git push origin $$(git branch --show-current)"


################################################################################
# Combined: Pull and merge PR in one step
# Usage: make apply-pr PR=521
#

.PHONY: apply-pr
apply-pr:
	@echo "--------------------------------------------------------------------------------"
	@echo "[opencommit-fork]: apply-pr (PR=$(PR))"
	@if [ -z "$(PR)" ]; then \
		echo "ERROR: PR number required. Usage: make apply-pr PR=521"; \
		exit 1; \
	fi
	@$(MAKE) pull-pr PR=$(PR)
	@git checkout master
	@$(MAKE) merge-pr PR=$(PR)
	@echo ""
	@echo "✓ PR #$(PR) has been applied to master branch"
	@echo "  To push to your fork: git push origin master"

