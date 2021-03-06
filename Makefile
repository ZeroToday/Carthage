XCODEFLAGS=-workspace 'Carthage.xcworkspace' -scheme 'carthage'

TEMPORARY_FOLDER=/tmp/Carthage.dst
PREFIX?=/usr/local
BUILD_TOOL?=xcodebuild

BUILT_BUNDLE=$(TEMPORARY_FOLDER)/Applications/carthage.app
CARTHAGEKIT_BUNDLE=$(BUILT_BUNDLE)/Contents/Frameworks/CarthageKit.framework
CARTHAGE_EXECUTABLE=$(BUILT_BUNDLE)/Contents/MacOS/carthage

FRAMEWORKS_FOLDER=/Library/Frameworks
BINARIES_FOLDER=/usr/local/bin

OUTPUT_PACKAGE=Carthage.pkg

VERSION_STRING=$(shell agvtool what-marketing-version -terse1)
COMPONENTS_PLIST=Source/carthage/Components.plist

.PHONY: all bootstrap clean install package test uninstall

all: bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) build

bootstrap:
	script/bootstrap

test: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) test

clean:
	rm -f "$(OUTPUT_PACKAGE)"
	rm -rf "$(TEMPORARY_FOLDER)"
	$(BUILD_TOOL) $(XCODEFLAGS) clean

install: package
	sudo installer -pkg Carthage.pkg -target /

uninstall:
	rm -rf "$(FRAMEWORKS_FOLDER)/CarthageKit.framework"
	rm -f "$(BINARIES_FOLDER)/carthage"

installables: clean bootstrap
	$(BUILD_TOOL) $(XCODEFLAGS) install

	mkdir -p "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)"
	mv -f "$(CARTHAGEKIT_BUNDLE)" "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/CarthageKit.framework"
	mv -f "$(CARTHAGE_EXECUTABLE)" "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/carthage"
	rm -rf "$(BUILT_BUNDLE)"

prefix_install: installables
	mkdir -p "$(PREFIX)/Frameworks" "$(PREFIX)/bin"
	cp -rf "$(TEMPORARY_FOLDER)$(FRAMEWORKS_FOLDER)/CarthageKit.framework" "$(PREFIX)/Frameworks/"
	cp -f "$(TEMPORARY_FOLDER)$(BINARIES_FOLDER)/carthage" "$(PREFIX)/bin/"
	install_name_tool -add_rpath "@executable_path/../Frameworks" "$(PREFIX)/bin/carthage"
	install_name_tool -add_rpath "@executable_path/../Frameworks/CarthageKit.framework/Versions/Current/Frameworks/"  "$(PREFIX)/bin/carthage"

package: installables
	pkgbuild \
		--component-plist "$(COMPONENTS_PLIST)" \
		--identifier "org.carthage.carthage" \
		--install-location "/" \
		--root "$(TEMPORARY_FOLDER)" \
		--version "$(VERSION_STRING)" \
		"$(OUTPUT_PACKAGE)"
