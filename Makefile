SHELL := /bin/bash

.PHONY: help validate-fast validate-ci validate-commands validate-frontmatter validate-structure validate-hook-paths validate-markdown lint-frontmatter validate-generated validate-workflows install-hooks

help: ## Show available validation targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "} {printf "%-24s %s\n", $$1, $$2}'

validate-fast: ## Run the fast local validation path
	bash ./tools/validate-fast.sh

validate-ci: ## Run the CI-parity validation path
	bash ./tools/validate-ci.sh

validate-commands: ## Run command-focused Node validators
	npm run validate:commands
	npm run validate:no-duplicates

validate-frontmatter: ## Run shell frontmatter validation
	bash ./tools/check-frontmatter.sh

validate-structure: ## Run command structure validation
	bash ./tools/validate-command.sh

validate-hook-paths: ## Run hook path validation
	bash ./tools/validate-hook-paths.sh

validate-markdown: ## Run markdown lint
	bash ./tools/validate-markdown.sh

lint-frontmatter: ## Run frontmatter YAML lint
	bash ./tools/lint-frontmatter.sh

validate-generated: ## Regenerate COMMANDS.md and fail if it changes
	bash ./tools/validate-generated.sh

validate-workflows: ## Validate GitHub workflow YAML syntax locally
	bash ./tools/validate-workflows.sh

install-hooks: ## Install pre-commit hooks
	pre-commit install
