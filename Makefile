.PHONY: build release clean run help

# Configuration
APP_NAME := AutoKey
BUILD_DIR := .build
BUNDLE_DIR := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR := $(BUNDLE_DIR)/Contents
MACOS_DIR := $(CONTENTS_DIR)/MacOS
RESOURCES_DIR := $(CONTENTS_DIR)/Resources
RESOURCES_SRC := Sources/Resources

# Default target
all: build

# Build Swift executable only
build:
	@echo "Building executable..."
	swift build

# Build and package as .app bundle with DMG
release: clean
	@echo "Building app bundle..."
	@echo " Building $(APP_NAME).app..."
	
	# Clean and create directories
	rm -rf "$(BUNDLE_DIR)"
	mkdir -p "$(MACOS_DIR)" "$(RESOURCES_DIR)"

	@echo "Building Swift executable with performance and size optimizations..."
	swift build -c release \
		-Xswiftc -O \
		-Xswiftc -Osize \
		-Xswiftc -whole-module-optimization \
		-Xswiftc -cross-module-optimization \
		-Xlinker -dead_strip \
		-Xlinker -S
	
	@echo "Creating app bundle structure..."
	
	# Copy the executable
	cp "$(BUILD_DIR)/release/$(APP_NAME)" "$(MACOS_DIR)/"
	
	# Strip binary to further reduce size
	strip -rSTx "$(MACOS_DIR)/$(APP_NAME)"
	
	# Report original and optimized binary size
	@orig_size=$$(stat -f %z "$(BUILD_DIR)/release/$(APP_NAME)" 2>/dev/null || stat -c %s "$(BUILD_DIR)/release/$(APP_NAME)"); \
	opt_size=$$(stat -f %z "$(MACOS_DIR)/$(APP_NAME)" 2>/dev/null || stat -c %s "$(MACOS_DIR)/$(APP_NAME)"); \
	echo "Binary size: Original: $$(($${orig_size}/1024))KB, Optimized: $$(($${opt_size}/1024))KB, Reduction: $$((($${orig_size} - $${opt_size}) * 100 / $${orig_size}))%"
	
	# Copy Info.plist
	cp "$(RESOURCES_SRC)/Info.plist" "$(CONTENTS_DIR)/"
	
	# Copy app icon and assets (optimized)
	@if [ -d "$(RESOURCES_SRC)/Assets.xcassets" ]; then \
		echo "Copying and optimizing assets..."; \
		mkdir -p "$(RESOURCES_DIR)/Assets.xcassets"; \
	fi
	
	@if [ -d "$(RESOURCES_SRC)/Assets.xcassets" ]; then \
		echo "Optimizing PNG files..."; \
		find "$(RESOURCES_SRC)/Assets.xcassets" -type f -name "*.png" | while read png_file; do \
			dest_file="$(RESOURCES_DIR)/$${png_file#$(RESOURCES_SRC)/}"; \
			dest_dir="$$(dirname "$$dest_file")"; \
			mkdir -p "$$dest_dir"; \
			if command -v optipng >/dev/null 2>&1; then \
				optipng -quiet -strip all -o7 "$$png_file" -out "$$dest_file"; \
			else \
				cp "$$png_file" "$$dest_file"; \
			fi; \
		done; \
	fi
	
	@if [ -d "$(RESOURCES_SRC)/Assets.xcassets" ]; then \
		echo "Copying non-PNG asset files..."; \
		find "$(RESOURCES_SRC)/Assets.xcassets" -type f -not -name "*.png" | while read file; do \
			dest_file="$(RESOURCES_DIR)/$${file#$(RESOURCES_SRC)/}"; \
			dest_dir="$$(dirname "$$dest_file")"; \
			mkdir -p "$$dest_dir"; \
			cp "$$file" "$$dest_file"; \
		done; \
	fi
	
	# Copy App.icns file
	cp "$(RESOURCES_SRC)/App.icns" "$(RESOURCES_DIR)/"
	
	# Copy entitlements for reference (not directly used in bundle)
	cp "$(RESOURCES_SRC)/AutoKey.entitlements" "$(RESOURCES_DIR)/"
	
	# Create PkgInfo file
	echo "APPL????" > "$(CONTENTS_DIR)/PkgInfo"
	
	# Make executable
	chmod +x "$(MACOS_DIR)/$(APP_NAME)"
	
	@echo "Code signing with hardened runtime..."
	# Sign the app with hardened runtime for better security
	codesign --force --deep --sign - --entitlements "$(RESOURCES_SRC)/AutoKey.entitlements" \
		--options runtime "$(BUNDLE_DIR)"
	
	@echo "Successfully built $(BUNDLE_DIR)"
	
	@echo "Creating professional DMG package with drag-and-drop installation..."
	
	# Create temp directory for DMG contents
	rm -rf "$(BUILD_DIR)/dmg_tmp"
	mkdir -p "$(BUILD_DIR)/dmg_tmp"
	
	# Copy app to temp directory
	cp -r "$(BUNDLE_DIR)" "$(BUILD_DIR)/dmg_tmp/"
	
	# Create Applications folder symlink
	ln -s /Applications "$(BUILD_DIR)/dmg_tmp/Applications"
	
	# Create background directory
	mkdir -p "$(BUILD_DIR)/dmg_tmp/.background"
	
	# Copy background image for DMG
	@if [ -f "$(RESOURCES_SRC)/dmg_background.png" ]; then \
		echo "Using dmg_background.png as DMG background"; \
		cp "$(RESOURCES_SRC)/dmg_background.png" "$(BUILD_DIR)/dmg_tmp/.background/background.png"; \
	elif [ -f "$(RESOURCES_SRC)/icon.png" ]; then \
		echo "Using icon.png as DMG background"; \
		cp "$(RESOURCES_SRC)/icon.png" "$(BUILD_DIR)/dmg_tmp/.background/background.png"; \
	else \
		echo "No background image found for DMG"; \
	fi
	
	# Create temporary applescript for DMG customization
	echo 'tell application "Finder"' > "$(BUILD_DIR)/dmg_setup.applescript"
	echo '    tell disk "$(APP_NAME)"' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        open' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        set current view of container window to icon view' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        set toolbar visible of container window to false' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        set statusbar visible of container window to false' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        set the bounds of container window to {400, 100, 900, 450}' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        set theViewOptions to the icon view options of container window' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        set arrangement of theViewOptions to not arranged' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        set icon size of theViewOptions to 80' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        set background picture of theViewOptions to file ".background:background.png"' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        set position of item "$(APP_NAME).app" of container window to {120, 180}' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        set position of item "Applications" of container window to {380, 180}' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        update without registering applications' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        delay 5' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '        close' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo '    end tell' >> "$(BUILD_DIR)/dmg_setup.applescript"
	echo 'end tell' >> "$(BUILD_DIR)/dmg_setup.applescript"
	
	# Create DMG file with maximum compression
	hdiutil create -volname "$(APP_NAME)" -srcfolder "$(BUILD_DIR)/dmg_tmp" -ov -format UDZO -fs HFS+ \
		-imagekey zlib-level=9 \
		"$(BUILD_DIR)/$(APP_NAME)_temp.dmg"
	
	# Remove existing DMG if it exists
	rm -f "$(BUILD_DIR)/$(APP_NAME).dmg"
	
	# Convert the DMG to read-only with maximum compression
	hdiutil convert "$(BUILD_DIR)/$(APP_NAME)_temp.dmg" -format UDZO -o "$(BUILD_DIR)/$(APP_NAME).dmg" -imagekey zlib-level=9
	
	# Report DMG size
	@dmg_size=$$(stat -f %z "$(BUILD_DIR)/$(APP_NAME).dmg" 2>/dev/null || stat -c %s "$(BUILD_DIR)/$(APP_NAME).dmg"); \
	echo "DMG size: $$(($${dmg_size}/1024))KB"
	
	# Clean up
	rm -f "$(BUILD_DIR)/$(APP_NAME)_temp.dmg"
	rm -f "$(BUILD_DIR)/dmg_setup.applescript"
	rm -rf "$(BUILD_DIR)/dmg_tmp"
	
	@echo "Successfully created $(APP_NAME).dmg at $(BUILD_DIR)/$(APP_NAME).dmg"
	@echo "To view the app: open $(BUNDLE_DIR)"
	@echo "To view the DMG: open $(BUILD_DIR)/$(APP_NAME).dmg"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)

# Run the executable directly (for debugging)
run: build
	@echo "Running executable..."
	$(BUILD_DIR)/debug/$(APP_NAME)

# Show available targets
help:
	@echo "Available targets:"
	@echo "  build         - Build Swift executable only"
	@echo "  release       - Build and package as .app bundle with DMG (optimized for performance and size)"
	@echo "  clean         - Clean build artifacts"
	@echo "  run           - Run executable directly (debug build)"
	@echo "  help          - Show this help"
