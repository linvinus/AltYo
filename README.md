AltYo
=====

AltYo - drop-down terminal emulator, written in Vala, depends only on libvte and gtk3.

Main program advantages.
------------------------
* The design of altyo allows to open an unlimited tab count, even with long terminal titles.  
     if tabs do not fit in one row, they will move to a new line.
* Drag and drop tabs.
* Tabs do not stand out from the terminal. (solid view)
* Title of the tabs fully customisable.  
     Highlight parts of the terminal header by color (for example, highlight username and hostname)  
     Adjust the header of the terminal, using regular expressions(for example cut unnecessary parts).
* Autostart with desktop session.
* Autostarts programs in new tabs ,for example start mocp and mutt, by default.
* Alert popup shows when you the terminal will be closed with an important program (ssh, wget pattern is customizable), even if executed in the background.
* Delayed "Close tab", 10 seconds before tab will actually be closed. If necessary, `<Ctrl><Shift>R` can be pressed to restore the closed tab, tabs can also be restored from the terminal popup menu.
* Important tabs can be 'Locked', the program will then ask to confirm tab closing. ("Lock tab" is in from the context menu on tab button)
* All options can be configured via graphical settings dialog.
* The program will warn the user when incorrect values are filled in the configuration, if settings are absent in config file, the program will use the default values.
* Hotkey for ~~the first 20~~ unlimited tabs (double press of `alt+5` will switch to the 15th tab, triple press will switch to the 25th tab and so on)
* You may use css to style the program (thanks to gtk3)
* Multi monitor support.  
  * The monitor in which altYo is started by default can be configured.  
  * Individual window size and position for each monitor.
  * Program contains "Follow the mouse" mode, after hiding, window will shown on the monitor with mouse pointer.
* Tiling window manager support (usual window).  
     Use `--standalone` command line option to run in tiling window manager,  
     For any other window managers, altyo will operate as usual terminal emulator (like xterm).
* Multiple instances. You may run several instances of alto in same time.  
  In order to do that, an unique id and configuration file for each instance should be setup.  
  For example:  
  `altyo --id=org.gtk.altyo_left_monitor -c ~/.config/altyo/config_left_monitor.ini`  
  `altyo --id=org.gtk.altyo_right_monitor -c ~/.config/altyo/config_right_monitor.ini`  
  now each instance can be controlled individually  
  `altyo --id=org.gtk.altyo_left_monitor -e "htop"`  
  `altyo --id=org.gtk.altyo_right_monitor -e "mc"`  
  The id can be omitted: `--id=none` may be used, but in that case there will be no possibility to control instances from the command line.

[![Main window](http://storage6.static.itmages.ru/i/13/0406/s_1365230653_4853839_d41d8cd98f.png)](http://itmages.ru/image/view/971951/d41d8cd9)
[![Preferences Look and feel](http://storage3.static.itmages.ru/i/13/0406/s_1365229810_3352986_d41d8cd98f.png)](http://itmages.ru/image/view/971932/d41d8cd9)
[![Preferences Key bindings](http://storage5.static.itmages.ru/i/13/0406/s_1365229912_4764716_d41d8cd98f.png)](http://itmages.ru/image/view/971933/d41d8cd9)
[![Preferences Advanced](http://storage6.static.itmages.ru/i/13/0406/s_1365229959_4473970_d41d8cd98f.png)](http://itmages.ru/image/view/971934/d41d8cd9)
[![Tiling window manager](http://storage3.static.itmages.ru/i/13/0612/s_1371022015_7777413_5cf29d0faf.png)](http://itmages.ru/image/view/1071250/5cf29d0f)
[![Tiling window manager](http://storage5.static.itmages.ru/i/13/0612/s_1371022059_3043913_a19d77ddef.png)](http://itmages.ru/image/view/1071252/a19d77dd)
[![Normal window](http://storage2.static.itmages.ru/i/13/0612/s_1371037750_9206122_f69d88b067.png)](http://itmages.ru/image/view/1071578/f69d88b0)

small video presentation of the available features:
* youtube video altyo 0.3  
  [![youtube altyo 0.3](http://img.youtube.com/vi/IEabsuFresk/0.jpg)](http://youtu.be/IEabsuFresk)
* altyo 0.2 http://youtu.be/9W8m6T7HyVs and http://youtu.be/utxeh-SBTvI

Installing
----
Packages for *Ubuntu and Debian* available there https://launchpad.net/~linvinus/+archive/altyo  
Package for *Arch Linux* AUR https://aur.archlinux.org/packages/altyo-git/ (package created by willemw)  
Ebuild for *Gentoo/Sabayon* https://drive.google.com/file/d/0B6vs0mKF7AyLQzdYOEdEVzJOZWM/view?usp=sharing (ebuild created by giacomogiorgianni)

Source code available there https://github.com/linvinus/AltYo  
How to install from sources is described in INSTALL file.

Tips and tricks:
----
1. You always may open new stand-alone terminal, in current directory, by pressing `<Ctrl><Shift>N` (default key binding)
2. In search mode (when text entry have a focus), you may use following hotkeys  
   `ctrl+1` - toggle "Wrap search"  
   `ctrl+2` - toggle "Match case-sensitive"  
   `ctrl+3` - toggle search mode "terminal text"/"terminals titles"  
   `ctrl+Up` or `Enter` - find next  
   `ctrl+Down` - find prev  
   `Up` - search history  
   `Down` - search history  
   `Esc` - close search dialog  
sorry, this keys is hardcoded.
3. You may switching to tab by searching in a titles.  
   To do that you need to open search dialog `<Ctrl><Shift>F` (default key binding),  
   then activate search option  "terminals titles", by pressing `<Ctrl+3>`,  
   then type sought-for part of tab title.  
   Then you may use hotkeys to cycle through the search results  
   `ctrl+Up` or `Enter` - find next  
   `ctrl+Down` - find prev  
   Also, you may configure special hotkey to quickly activate this mode "Search in terminals titles"
4. You may sort tabs by hostname (if tab title contain host name in the following form `<user>@<host>:<path>`)  
   To do that press right mouse button on tab title, then, in context menu, select "Sort by hostname"  
   Also, you may configure special hotkey for this action "Sort by hostname".
5. Altyo is portable, you may copy executable file on your USB flash drive.  
   All you need to run on target machine is installed Gtk 3.4 or newer and libvte 3.0 or newer.  
   This libraries should be available on fresh distributives.
6. Double click on empty space in tab bar will open new tab.
7. Middle click on tab button will close tab.
8. You may set default TERM variable at Advanced -> Terminal regexps ->TERM, for example `TERM=xterm-256color`

FAQ:
----
* Q) ubuntu "global menu" + alt+grave
     "global menu" show application menu, when user press alt+grave, but it should not
* A) disable gtk3 auto mnemonics
```
     dconf write /org/gnome/desktop/interface/automatic-mnemonics false
```

* Q) when resizing terminal, lines break, if you are running Zsh
* A) bug is described there https://bugzilla.gnome.org/show_bug.cgi?id=708213 and there https://bbs.archlinux.org/viewtopic.php?pid=1246865
  ~~you need to apply patch (https://bbs.archlinux.org/viewtopic.php?pid=1246865#p1246865).
  to resolve that.
  for ubuntu users, patched vte available in this ppa https://launchpad.net/~linvinus/+archive/vte~~  
  this bug resolved in vte 0.36

* Q) Window gravity south, not working under xfwm4
* A) it is xfwm4 bug https://bugzilla.xfce.org/show_bug.cgi?id=3634

* Q) tabs does not close after entering "exit" command (mc restarting after pressing F10 if it was runned as autorun command)
* A) if you prefer close tabs by "exit" command, you may turn off option "Auto restart shell"

* Q) "auto run" commands doesn't see environment variables from bashrc file
* A) this happen because they are running as standalone application,  
     but, for example, you may use following wrap around `bash -c "EDITOR=vim mc"`  
     in this example mc will runned with special environment variable

* Q) F11 (maximize) not working in lubuntu (with openbox)
* A) you need to remove following lines in ~/.config/openbox/lubuntu-rc.xml  
  `<keybind key="F11">  
  <action name="ToggleFullscreen"/>  
  </keybind>`

* Q) Missing terminal focus-in (libvte bug)
* A) Bug report is here https://bugzilla.gnome.org/show_bug.cgi?id=677329  
     https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=699907  
     resolved in Ubuntu 12.04 updates xserver-xorg-core-lts-trusty >= 2:1.15.1-0ubuntu2~precise2  
     resolved in Ubuntu 14.04 and newer  
     Workarounds:  
     1) ~~window.unrealize();~~  
     2) ~~export GDK_CORE_DEVICE_EVENTS=1~~  
     3) Set checkbox "Workaround if focus lost" in settings, then restart altyo.


Reviews about AltYo
-------------------
zenway.ru (Russian) http://zenway.ru/page/altyo  
muhas.ru (Russian) http://muhas.ru/?p=202
