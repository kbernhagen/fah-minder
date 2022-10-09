binary = fah-minder

bin_path = $(shell swift build -c release --show-bin-path)
bin_path_u = $(shell swift build -c release --show-bin-path \
	--arch arm64 --arch x86_64)

source = $(bin_path)/$(binary)
source_u = $(bin_path_u)/$(binary)

destination = $(HOME)/bin

pkghome = .build/pkg/$(binary)
pkgroot = $(pkghome)/root
pkgrootdest = $(pkgroot)/usr/local/bin
pkgresources = $(pkghome)/Resouces
pkgscripts = $(pkghome)/scripts

id_app = Developer ID Application: Kevin Bernhagen
id_pkg = Developer ID Installer: Kevin Bernhagen
id_prefix = io.github.kbernhagen.

notarize_profile = kbernhagen.github@gmail.com 2KHMKJ3Y44

ifdef NOTARIZE_PROFILE
 notarize_profile = $(NOTARIZE_PROFILE)
endif

build: autorev
	swift build --configuration release
	strip "$(source)"

debug: autorev
	swift build --configuration debug

install: build
	mkdir -p "$(destination)"
	install -S "$(source)" "$(destination)/."

build-universal: autorev
	swift build --configuration release --arch arm64 --arch x86_64
	strip "$(source_u)"

sign: build-universal
	codesign --force --timestamp --options runtime \
		--prefix "$(id_prefix)" \
		--sign "$(id_app)" \
		"$(source_u)"

zip: sign
	$(eval version=$(shell "$(source_u)" --version))
	mkdir -p dist
	zip -j "dist/$(binary)-$(version).zip" "$(source_u)"

pkg package: sign
	rm -rf "$(pkghome)"
	mkdir -p "$(pkghome)"

	# copy pkg resources
	cp -rp install/macos/* "$(pkghome)/."
	mkdir -p "$(pkgresources)" "$(pkgscripts)"

	# copy build to pkg root stage
	mkdir -p "$(pkgrootdest)"
	install "$(source_u)" "$(pkgrootdest)/."

	# determine version string and pkg filename
	$(eval version=$(shell "$(source_u)" --version))
	$(eval pkgfile = $(binary)-$(version).pkg)
	$(eval pkg = $(pkghome)/$(pkgfile))

	# make component pkg
	mkdir -p "$(pkghome)/Packages"
	pkgbuild --root "$(pkgroot)" --ownership recommended \
		--install-location / \
		--identifier "$(id_prefix)$(binary).pkg" \
		--version "$(version)" \
		--scripts "$(pkgscripts)" \
		"$(pkghome)/Packages/$(binary).pkg"

	# set version in distribution.xml
	sed -i .bak "s/__VERSION__/$(version)/g" "$(pkghome)/distribution.xml"

	productbuild \
		--distribution "$(pkghome)/distribution.xml" \
		--package-path "$(pkghome)/Packages" \
		--version "$(version)" \
		--resources "$(pkgresources)" \
		--sign "$(id_pkg)" --timestamp \
		"$(pkg)"

notarize:
	$(eval version=$(shell "$(source_u)" --version))
	$(eval pkgfile = $(binary)-$(version).pkg)
	$(eval pkg = $(pkghome)/$(pkgfile))
	xcrun notarytool submit --wait -p "$(notarize_profile)" "$(pkg)"
	xcrun stapler staple "$(pkg)"
	mkdir -p dist
	mv -f "$(pkg)" dist/.

tools/autorevision.sh:
	mkdir -p tools
	curl -fsSL -o tools/autorevision.sh \
	https://raw.githubusercontent.com/Autorevision/autorevision/v/1.22/autorevision.sh
	chmod +x tools/autorevision.sh

autorev: tools/autorevision.sh
	./tools/autorevision.sh -t swift > Sources/fah-minder/autorevision.swift

uninstall:
	rm -f "$(destination)/$(binary)"

clean:
	swift package clean
	rm -rf .build

distclean: clean
	find . -type f -name .DS_Store -print -delete
	rm -rv dist || true
	rm tools/autorevision.sh || true
	rm Sources/fah-minder/autorevision.swift || true
	rmdir tools || true

.PHONY: build install uninstall clean distclean autorev debug
.PHONY: build-universal sign package pkg notarize
