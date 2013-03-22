AltYo
=====

AltYo - drop-down console,like tilda (terminal emulator with first person shooter console likeness) ,
with many improvements, is written in vala, depends on libvte, gtk3.Supports multi-line tabs, support DnD tabs,
fully customizable.

[![Main window](http://storage5.static.itmages.ru/i/13/0306/s_1362553192_8481235_e88c7350b2.png)](http://itmages.ru/image/view/926657/e88c7350)
[![Preferences](http://storage6.static.itmages.ru/i/13/0306/s_1362553212_3021546_770183e9e7.png)](http://itmages.ru/image/view/926658/770183e9)

Source code available there https://github.com/linvinus/AltYoA

small video presentation of available features - (obsolete) http://youtu.be/9W8m6T7HyVs and http://youtu.be/utxeh-SBTvI

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
