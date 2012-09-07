VALA_FLAGS = -v
VALA_FLAGS += --disable-warnings
#VALA_FLAGS += -g --save-temps
#VALA_FLAGS += -X -D\ GETTEXT_PACKAGE="altyo"\ -I.\ -include\ "./config.h" -v
VALA_FLAGS += --vapidir ./vapi --pkg gtk+-3.0 --pkg vte-2.90 --pkg gee-1.0 --pkg gdk-x11-3.0 --pkg cairo --pkg posix --pkg gnome-keyring-1
#DESTDIR?=
PREFIX?=/usr

VALA_FILES  = main.vala \
				hvbox.vala \
				altyo_terminal.vala \
				altyo_window.vala \
				altyo_hotkey.vala \
				altyo_config.vala \
				altyo_quick_connectios.vala \
#				altyo_myoverlaybox.vala


default:
	#test -e ./altyo && rm ./altyo
	valac -o altyo $(VALA_FLAGS) $(VALA_FILES)

source:
	valac -C -H $(VALA_FLAGS)  $(VALA_FILES)

clean:
	rm *.c *.h || true

install:
	test -z "$(DESTDIR)$(PREFIX)/bin" || mkdir -p "$(DESTDIR)$(PREFIX)/bin";
	cp -a ./altyo $(DESTDIR)$(PREFIX)/bin
	test -z "$(DESTDIR)$(PREFIX)/share/applications" || mkdir -p "$(DESTDIR)$(PREFIX)/share/applications";
	cp -a ./altyo.desktop $(DESTDIR)$(PREFIX)/share/applications
