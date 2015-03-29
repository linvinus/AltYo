using X;

[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "X11/XKBlib.h")]
namespace Xkb {
    [CCode (cname = "XkbGetState")]
    public void get_state (X.Display dpy, uint device_spec, out State state);

    [CCode (cname = "XkbLockGroup")]
    public void lock_group (X.Display dpy, uint device_spec, uint group);

    [Compact]
    [CCode (cname = "XkbStateRec", free_function = "")]
    public struct State {
        uchar   group;
        uchar   locked_group;
        ushort  base_group;
        ushort  latched_group;
        uchar   mods;
        uchar   base_mods;
        uchar   latched_mods;
        uchar   locked_mods;
        uchar   compat_state;
        uchar   grab_mods;
        uchar   compat_grab_mods;
        uchar   lookup_mods;
        uchar   compat_lookup_mods;
        ushort  ptr_buttons;
    }

    [CCode (cname = "XkbUseCoreKbd")]
    public int UseCoreKbd;

}
