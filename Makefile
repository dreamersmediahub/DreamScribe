# Define a directory for dependencies in the user's home folder
DEPS_DIR := $(HOME)/DreamScribe-Dependencies
WHISPER_CPP_DIR := $(DEPS_DIR)/whisper.cpp
FRAMEWORK_PATH := $(WHISPER_CPP_DIR)/build-apple/whisper.xcframework
LOCAL_DERIVED_DATA := $(CURDIR)/.local-build

.PHONY: all clean whisper setup build local check healthcheck help dev run install permissions rebuild

# Default target
all: check build

# Development workflow
dev: build run

# Prerequisites
check:
	@echo "Checking prerequisites..."
	@command -v git >/dev/null 2>&1 || { echo "git is not installed"; exit 1; }
	@command -v xcodebuild >/dev/null 2>&1 || { echo "xcodebuild is not installed (need Xcode)"; exit 1; }
	@command -v swift >/dev/null 2>&1 || { echo "swift is not installed"; exit 1; }
	@echo "Prerequisites OK"

healthcheck: check

# Build process
whisper:
	@mkdir -p $(DEPS_DIR)
	@if [ ! -d "$(FRAMEWORK_PATH)" ]; then \
		echo "Building whisper.xcframework in $(DEPS_DIR)..."; \
		if [ ! -d "$(WHISPER_CPP_DIR)" ]; then \
			git clone https://github.com/ggerganov/whisper.cpp.git $(WHISPER_CPP_DIR); \
		else \
			(cd $(WHISPER_CPP_DIR) && git pull); \
		fi; \
		cd $(WHISPER_CPP_DIR) && ./build-xcframework.sh; \
	else \
		echo "whisper.xcframework already built in $(DEPS_DIR), skipping build"; \
	fi

setup: whisper
	@echo "Whisper framework is ready at $(FRAMEWORK_PATH)"
	@echo "Please ensure your Xcode project references the framework from this new location."

build: setup
	xcodebuild -project DreamScribe.xcodeproj -scheme DreamScribe -configuration Debug CODE_SIGN_IDENTITY="" build

# Build for local use with ad-hoc signing (no Developer ID needed; Gatekeeper allows ad-hoc)
local: check setup
	@echo "Building DreamScribe with ad-hoc signing..."
	@rm -rf "$(LOCAL_DERIVED_DATA)"
	xcodebuild -project DreamScribe.xcodeproj -scheme DreamScribe -configuration Debug \
		-derivedDataPath "$(LOCAL_DERIVED_DATA)" \
		-xcconfig LocalBuild.xcconfig \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=YES \
		DEVELOPMENT_TEAM="" \
		CODE_SIGN_ENTITLEMENTS=$(CURDIR)/DreamScribe/VoiceInk.local.entitlements \
		SWIFT_ACTIVE_COMPILATION_CONDITIONS='$$(inherited) LOCAL_BUILD' \
		build
	@BUILT_APP="$(LOCAL_DERIVED_DATA)/Build/Products/Debug/DreamScribe.app" && \
	if [ -d "$$BUILT_APP" ]; then \
		echo "Copying DreamScribe.app to ~/Downloads..."; \
		rm -rf "$$HOME/Downloads/DreamScribe.app"; \
		ditto "$$BUILT_APP" "$$HOME/Downloads/DreamScribe.app"; \
		xattr -cr "$$HOME/Downloads/DreamScribe.app"; \
		echo "Re-codesigning ad-hoc with stable designated requirement..."; \
		codesign --force --deep --sign - \
			--identifier "co.dreamersmedia.dreamscribe" \
			--requirements '=designated => identifier "co.dreamersmedia.dreamscribe"' \
			"$$HOME/Downloads/DreamScribe.app" 2>&1 || echo "(codesign DR override failed — TCC may still re-prompt across rebuilds)"; \
		echo ""; \
		echo "Build complete! App saved to: ~/Downloads/DreamScribe.app"; \
		echo "Run with: open ~/Downloads/DreamScribe.app"; \
		echo "Or 'make rebuild' to build + install + relaunch with fresh permissions."; \
	else \
		echo "Error: Could not find built DreamScribe.app at $$BUILT_APP"; \
		exit 1; \
	fi

# Install the built app to /Applications (does not touch permissions)
install:
	@if [ ! -d "$$HOME/Downloads/DreamScribe.app" ]; then \
		echo "No build to install. Run 'make local' first."; \
		exit 1; \
	fi
	@echo "Quitting any running DreamScribe..."
	@osascript -e 'tell application "DreamScribe" to quit' 2>/dev/null || true
	@sleep 1
	@pkill -x DreamScribe 2>/dev/null || true
	@echo "Copying to /Applications..."
	@rm -rf /Applications/DreamScribe.app
	@cp -R "$$HOME/Downloads/DreamScribe.app" /Applications/DreamScribe.app
	@echo "Installed at /Applications/DreamScribe.app"

# Reset macOS TCC permissions for DreamScribe and relaunch the app.
# Needed after a rebuild changes the binary hash — TCC keys trust on the
# (bundleID + designated-requirement + cdhash) tuple. You'll be prompted
# for your sudo password once, then click "Allow" on each permission dialog.
permissions:
	@echo "Quitting DreamScribe..."
	@osascript -e 'tell application "DreamScribe" to quit' 2>/dev/null || true
	@sleep 1
	@pkill -x DreamScribe 2>/dev/null || true
	@echo "Resetting TCC entries for co.dreamersmedia.dreamscribe (sudo password required)..."
	@for srv in Microphone Accessibility ListenEvent PostEvent ScreenCapture; do \
		sudo tccutil reset $$srv co.dreamersmedia.dreamscribe || true; \
	done
	@if [ -d /Applications/DreamScribe.app ]; then \
		echo "Relaunching DreamScribe — click Allow on each permission prompt..."; \
		open /Applications/DreamScribe.app; \
	else \
		echo "DreamScribe not in /Applications — run 'make install' first."; \
	fi

# One-shot: build, install, reset permissions, relaunch.
# Asks for your sudo password once (for tccutil reset).
rebuild: local install permissions
	@echo ""
	@echo "✓ DreamScribe rebuilt + installed + permissions reset."
	@echo "  Click Allow on each permission prompt in the dialogs that appeared."

# Run application
run:
	@if [ -d "$$HOME/Downloads/DreamScribe.app" ]; then \
		echo "Opening ~/Downloads/DreamScribe.app..."; \
		open "$$HOME/Downloads/DreamScribe.app"; \
	else \
		echo "Looking for built app in DerivedData..."; \
		APP_PATH=$$(find "$$HOME/Library/Developer/Xcode/DerivedData" -name "DreamScribe.app" -type d | head -1) && \
		if [ -n "$$APP_PATH" ]; then \
			echo "Found app at: $$APP_PATH"; \
			open "$$APP_PATH"; \
		else \
			echo "App not found. Please run 'make build' or 'make local' first."; \
			exit 1; \
		fi; \
	fi

# Cleanup
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(DEPS_DIR)
	@rm -rf $(LOCAL_DERIVED_DATA)
	@echo "Clean complete"

# Help
help:
	@echo "Available targets:"
	@echo "  check/healthcheck  Check if required CLI tools are installed"
	@echo "  whisper            Clone and build whisper.cpp XCFramework"
	@echo "  setup              Prepare whisper framework"
	@echo "  build              Build the DreamScribe Xcode project"
	@echo "  local              Build DreamScribe ad-hoc signed; output to ~/Downloads"
	@echo "  install            Copy ~/Downloads/DreamScribe.app to /Applications"
	@echo "  permissions        Reset TCC + relaunch (asks for sudo password once)"
	@echo "  rebuild            local + install + permissions (one-shot daily-driver flow)"
	@echo "  run                Launch the installed DreamScribe app"
	@echo "  dev                Build and run (for development)"
	@echo "  all                Run full build process (default)"
	@echo "  clean              Remove build artifacts"
	@echo "  help               Show this help message"
