PRG_NAME=altyo

# guess Linux distro
LINUX.DISTRIB.FILE=$(shell ls /etc/lsb-release 2>/dev/null)
ifeq ($(LINUX.DISTRIB.FILE),)
LINUX.DISTRIB.FILE=$(shell ls /etc/debian_version 2>/dev/null)
endif

ifeq ($(LINUX.DISTRIB.FILE),/etc/lsb-release)
LINUX.DISTRIB.ID=$(shell grep DISTRIB_ID /etc/lsb-release | sed 's/DISTRIB_ID=//')
endif

ifeq ($(LINUX.DISTRIB.FILE),/etc/debian_version)
LINUX.DISTRIB.ID=debian
endif

ifeq ($(LINUX.DISTRIB.ID),Ubuntu)
LINUX.DISTRIB.ID=ubuntu
endif

CHANGELOG_TAG=${shell grep -m 1 "^altyo" ./debian/changelog | sed 's/.*(//' | sed 's/).*$$//'| sed 's/~/_/' | sed 's/:/%/'}
GIT_HASH=${shell which git >/dev/null && git log -1 --pretty=format:%h}
VALA_FLAGS ?= 

#use tmpfs for ssd hard drive
TMPFS=$(shell ls -d ./tmpfs 2>/dev/null)
ifeq ($(TMPFS),./tmpfs)
$(shell `[ \(  -L ./tmpfs \)  -a \( -e ./tmpfs \) ] || mkdir -p /run/shm/altyo_build; rm -rf ./tmpfs ; ln -s /run/shm/altyo_build ./tmpfs` )
VALA_FLAGS += -d ./tmpfs
endif

VALA_FLAGS += -v
VALA_FLAGS += --disable-warnings
#VALA_FLAGS += -g --save-temps -X -O0
VALA_FLAGS += -X -DGETTEXT_PACKAGE=\"$(PRG_NAME)\" -X -DAY_GIT_HASH=\"$(GIT_HASH)\" -X -DAY_CHANGELOG_TAG=\"$(CHANGELOG_TAG)\"
#\ -I.\ -include\ "./config.h" -v
ifeq ($(LINUX.DISTRIB.ID),ubuntu)
#debian specific possibility
VALA_FLAGS += -D ALTERNATE_SCREEN_SCROLL
endif

VTE ?= $(shell pkg-config  --exists vte-2.91 && echo 2.91)
VTE ?= $(shell pkg-config  --exists vte-2.90 && echo 2.90)

VALA_FLAGS += --vapidir ./vapi --pkg gtk+-3.0 --pkg gdk-x11-3.0 --pkg cairo --pkg posix --pkg gmodule-2.0



ifeq ($(VTE),2.91)
VALA_FLAGS += -D VTE_2_91
VALA_FLAGS += --pkg vte-2.91
else
VALA_FLAGS += --pkg vte-2.90
endif

#DESTDIR?=
PREFIX?=/usr

VALA_FILES  = vapi/config.vapi \
				vapi/xkb.vapi \
				main.vala \
				hvbox.vala \
				altyo_terminal.vala \
				altyo_window.vala \
				altyo_hotkey.vala \
				altyo_config.vala \
				altyo_settings.vala \
				data/altyo.c
#				altyo_myoverlaybox.vala

#VALA_FLAGS += --pkg gnome-keyring-1 -D HAVE_QLIST
#VALA_FILES += 	altyo_quick_connectios.vala

GLADE_FILES = data/preferences.glade data/encodings_list.glade data/main_window_encodings_combo.glade


default: data/altyo.c
	#test -e ./altyo && rm ./altyo
	valac -o $(PRG_NAME) $(VALA_FLAGS) $(VALA_FILES)

source: data/altyo.c
	valac -C -H $(VALA_FLAGS)  $(VALA_FILES)

data/altyo.c: data/altyo.gresource.xml data/altyo.svg $(GLADE_FILES)
	glib-compile-resources --sourcedir=./data --generate-source ./data/altyo.gresource.xml
	
clean:
	rm *.c *.h || true
	rm ./altyo || true
	rm ./data/*.c *.h || true

install: gen_mo
	test -z "$(DESTDIR)$(PREFIX)/bin" || mkdir -p "$(DESTDIR)$(PREFIX)/bin";
	cp -a ./$(PRG_NAME) $(DESTDIR)$(PREFIX)/bin
	test -z "$(DESTDIR)$(PREFIX)/share/applications" || mkdir -p "$(DESTDIR)$(PREFIX)/share/applications";
	cp -a ./data/altyo.desktop $(DESTDIR)$(PREFIX)/share/applications/org.gtk.altyo.desktop
	cp -a ./data/altyo_standalone.desktop $(DESTDIR)$(PREFIX)/share/applications
	test -z "$(DESTDIR)$(PREFIX)/share/locale/ru/LC_MESSAGES" || mkdir -p "$(DESTDIR)$(PREFIX)/share/locale/ru/LC_MESSAGES";
	cp -a ./po/ru/LC_MESSAGES/altyo.mo $(DESTDIR)$(PREFIX)/share/locale/ru/LC_MESSAGES
	test -z "$(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps" || mkdir -p "$(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps";
	cp -a ./data/altyo.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps
	test -z "$(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps" || mkdir -p "$(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps";
	cp -a ./data/altyo.svg $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps

gen_po:
	xgettext -o ./po/altyo.po --from-code=UTF-8 -language=C --keyword=_ --keyword=N_ $(VALA_FILES) $(GLADE_FILES)
	msgmerge -s -U ./po/ru/LC_MESSAGES/$(PRG_NAME).po  ./po/$(PRG_NAME).po

gen_mo:
	msgfmt -c -v -o ./po/ru/LC_MESSAGES/$(PRG_NAME).mo ./po/ru/LC_MESSAGES/$(PRG_NAME).po

source-package:
	rm ./altyo || true
	rm ./po/ru/LC_MESSAGES/$(PRG_NAME).mo || true
	git-buildpackage --git-upstream-tree=branch --git-upstream-branch=master -rfakeroot -S -sa
	sed -i -re '1 s/(altyo \(.*)\) .*\;/\1~precise\) precise\;/' ./debian/changelog
	dpkg-buildpackage -S -sa
	git checkout ./debian/changelog
	sed -i -re '1 s/(altyo \(.*)\) .*\;/\1~trusty\) trusty\;/' ./debian/changelog
	dpkg-buildpackage -S -sa
	git checkout ./debian/changelog
	sed -i -re '1 s/(altyo \(.*)\) .*\;/\1~vivid\) vivid\;/' ./debian/changelog
	dpkg-buildpackage -S -sa
	git checkout ./debian/changelog
	sed -i -re '1 s/(altyo \(.*)\) .*\;/\1~wily\) wily\;/' ./debian/changelog
	dpkg-buildpackage -S -sa
	git checkout ./debian/changelog
	sed -i -re '1 s/(altyo \(.*)\) .*\;/\1~xenial\) xenial\;/' ./debian/changelog
	dpkg-buildpackage -S -sa
	git checkout ./debian/changelog

gen_changes:
	git-dch --ignore-branch --debian-branch=master --verbose -a -R
	git add .
	$(MAKE) gen_changes_stage2

gen_changes_stage2:
	git commit -m "new: debian release $(CHANGELOG_TAG)"
	git tag "debian/$(CHANGELOG_TAG)"
	git push
	git push origin --tags

#git tag "debian/0.2_121003-linvinus1" ~ -> _ , : -> %
#git-dch --ignore-branch --debian-branch=master --verbose
#git push origin --tags
