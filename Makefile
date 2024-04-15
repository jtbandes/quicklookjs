.PHONY: build
build:
	# https://developer.apple.com/documentation/xcode/building-swift-packages-or-apps-that-use-them-in-continuous-integration-workflows
	# https://stackoverflow.com/questions/4969932/separate-build-directory-using-xcodebuild
	xcodebuild \
		-disableAutomaticPackageResolution \
		-clonedSourcePackagesDirPath .swiftpm-packages \
		-destination generic/platform=macOS \
		-scheme PreviewExtension \
		SYMROOT=$(PWD)/build \
		-configuration Release \
		clean build
	lipo build/Release/PreviewExtension.appex/Contents/MacOS/PreviewExtension -verify_arch arm64 x86_64
	rm -rf dist
	mkdir -p dist
	cp -R build/Release/PreviewExtension.appex dist/
	cp PreviewExtension/PreviewExtension.entitlements dist/

.PHONY: lint-ci
lint-ci:
	docker run -t --rm -v $(PWD):/work -w /work ghcr.io/realm/swiftlint:0.53.0

.PHONY: format-ci
format-ci:
	docker run -t --rm -v $(PWD):/work ghcr.io/nicklockwood/swiftformat:0.53.7 --lint /work
