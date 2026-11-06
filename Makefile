.DEFAULT_GOAL := help
.PHONY: help app-release lint test website-install website-dev website-check website-build

PROJECT := Sunalta.xcodeproj
SCHEME := Sunalta
TEST_DESTINATION ?= platform=iOS Simulator,name=iPhone 17,OS=latest
UNIT_TEST_TARGET ?= SunaltaTests
WEBSITE_DIR := sites/sunalta

export VERSION

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

app-release: ## Bump the iOS version and publish a release (VERSION=x.y.z)
	@./Scripts/release-app.sh

lint: ## Check Swift formatting in the app, widget, shared code, and unit tests
	xcrun swift-format lint --strict --recursive Sunalta SunaltaWidgets AlarmShared ClockShared Tests

test: ## Run unit tests (override TEST_DESTINATION or UNIT_TEST_TARGET as needed)
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration Debug \
		-destination '$(TEST_DESTINATION)' -only-testing:'$(UNIT_TEST_TARGET)' test

website-install: ## Install the website's locked npm dependencies
	npm --prefix "$(WEBSITE_DIR)" ci

website-dev: ## Start the local Astro development server
	npm --prefix "$(WEBSITE_DIR)" run dev

website-check: ## Check Astro and TypeScript
	npm --prefix "$(WEBSITE_DIR)" run check

website-build: ## Build the static website into sites/sunalta/dist
	npm --prefix "$(WEBSITE_DIR)" run build
