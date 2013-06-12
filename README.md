AltYo
=====

AltYo - drop-down console, is written in vala, depends only on libvte, gtk3.

Main program advantages.
------------------------
* Design of altyo allow open unlimited tab count, even with long terminal title.  
     if tabs  not fit in the row, they move to a new line.
* Drag and drop tabs.
* Tabs does not stand out from the terminal.(solid view)
* Title of the tabs fully customisable.  
     You can highlight parts of the terminal header by color (for example, highlight username and hostname)  
     You can adjust the header of the terminal, using regular expressions(for example cut unnecessary parts).
* Autostart with desktop session.
* Autostart programs,for example, start mocp and mutt in new tabs by default.
* Program will warn you if you try to close the terminal with an important program(ssh,wget pattern is customizable), even if program runned in the background.
* All options can be configured via graphical settings dialog.
* Program will warn you if you setup incorrect setting value, if settings is absent in config file, program will use default value.
* Hotkey for the first 20 tabs (double press of `alt+5` will switch to 15 tab)
* You may use css to styling program (thanks to gtk3)
* Multi monitor support.  
  * You can setup, on which monitor start by default.  
  * Program have mode "Follow the mouse", in this mode, after hiding, window will shown on same monitor with mouse pointer.
* Tiling window manager support (usual window).  
     Use `--tiling_wm_mode` command line option to run in tiling window manager
* Multiple instances. You may run several instances of alto in same time.  
  To do that you should setup unique id for each instance and use separate configuration file.  
  For example:  
  `altyo --id=org.gtk.altyo_left_monitor -c ~/.config/altyo/config_left_monitor.ini`  
  `altyo --id=org.gtk.altyo_right_monitor -c ~/.config/altyo/config_right_monitor.ini`  
  now you may control each instance individually  
  `altyo --id=org.gtk.altyo_left_monitor -e "htop"`  
  `altyo --id=org.gtk.altyo_right_monitor -e "mc"`  

[![Main window](http://storage6.static.itmages.ru/i/13/0406/s_1365230653_4853839_d41d8cd98f.png)](http://itmages.ru/image/view/971951/d41d8cd9)
[![Preferences Look and feel](http://storage3.static.itmages.ru/i/13/0406/s_1365229810_3352986_d41d8cd98f.png)](http://itmages.ru/image/view/971932/d41d8cd9)
[![Preferences Key bindings](http://storage5.static.itmages.ru/i/13/0406/s_1365229912_4764716_d41d8cd98f.png)](http://itmages.ru/image/view/971933/d41d8cd9)
[![Preferences Advanced](http://storage6.static.itmages.ru/i/13/0406/s_1365229959_4473970_d41d8cd98f.png)](http://itmages.ru/image/view/971934/d41d8cd9)
[![Tiling window manager](http://storage3.static.itmages.ru/i/13/0612/s_1371022015_7777413_5cf29d0faf.png)](http://itmages.ru/image/view/1071250/5cf29d0f)
[![Tiling window manager](http://storage5.static.itmages.ru/i/13/0612/s_1371022059_3043913_a19d77ddef.png)](http://itmages.ru/image/view/1071252/a19d77dd)


small video presentation of available features:
* altyo 0.3 http://youtu.be/IEabsuFresk
* altyo 0.2 http://youtu.be/9W8m6T7HyVs and http://youtu.be/utxeh-SBTvI

Source code available there https://github.com/linvinus/AltYo

Packages for ubuntu available there https://launchpad.net/~linvinus/+archive/altyo

Package for Arch Linux AUR https://aur.archlinux.org/packages/altyo-git/ (package created by willemw)

FAQ:
----
* Q) ubuntu "global menu" + alt+grave
     "global menu" show application menu, when user press alt+grave, but it should not
* A) disable gtk3 auto mnemonics
```
     dconf write /org/gnome/desktop/interface/automatic-mnemonics false
```

* Q) when resizing terminal, lines break, if you are running Zsh
* A) bug is described there https://bbs.archlinux.org/viewtopic.php?pid=1246865
  you need to apply patch (https://bbs.archlinux.org/viewtopic.php?pid=1246865#p1246865).
  to resolve that.
  for ubuntu users, patched vte available in this ppa https://launchpad.net/~linvinus/+archive/vte

* Q) Window gravity south, not working under xfwm4
* A) it is xfwm4 bug https://bugzilla.xfce.org/show_bug.cgi?id=3634
