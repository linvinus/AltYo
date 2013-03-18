/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 */

using Gtk;
using Gdk;
using Gee;

// Based on http://code.valaide.org/content/global-hotkeys by Oliver Sauder <os@esite.ch>

/*public static void static_handler (string a) {
    PanelHotkey.instance().triggered (a);
}*/

public class KeyBinding {
	public string combination;
	public uint key_code;
	public uint modifiers;
	public bool relesed {get;set;default=true;}
	public signal void on_trigged();

	public void emit_on_trigged(){
		GLib.Timeout.add(50,on_timeout);//async call
	}
	public bool on_timeout(){
		this.on_trigged();
		return false;//stop timer
	}

	public KeyBinding (string combination, uint key_code, uint modifiers) {
		this.combination = combination;
		this.key_code = key_code;
		this.modifiers = modifiers;
	}
}

public class PanelHotkey {
    public signal void triggered (string combination);
    public uint32 last_event_time {get;set;default =0;}
    private unowned X.Display display;
    private Gdk.Window root_window;
    private X.ID x_id;
    private bool processing_event = false;

    static PanelHotkey _instance;

    public static PanelHotkey instance () {
        return _instance;
    }

    private static uint[] lock_modifiers = {
        0,
        Gdk.ModifierType.MOD2_MASK, // NUM_LOCK
        Gdk.ModifierType.LOCK_MASK, // CAPS_LOCK
        Gdk.ModifierType.MOD5_MASK, // SCROLL_LOCK
        Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK,
        Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.MOD5_MASK,
        Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK,
        Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK
    };

    private static Gee.List<KeyBinding> bindings;

    public PanelHotkey () {
        _instance = this;
        bindings = new Gee.ArrayList<KeyBinding> ();
        root_window = get_default_root_window ();

        this.display = Gdk.x11_get_default_xdisplay ();
        x_id = X11Window.get_xid (root_window);
        root_window.add_filter (event_filter);

    }

    public Gdk.FilterReturn event_filter (Gdk.XEvent gxevent, Gdk.Event event) {

        FilterReturn filter = FilterReturn.CONTINUE;
		this.processing_event = true;
        void* p = gxevent;
        X.Event* xevent = (X.Event*) p;
        last_event_time = (uint32)xevent->xkey.time;

        if (xevent->type == X.EventType.KeyPress) {
            foreach (var binding in bindings) {
                if (xevent->xkey.keycode == binding.key_code &&
                    (xevent->xkey.state & ~ (lock_modifiers[7]))  == binding.modifiers) {
					if(binding.relesed == true){
						binding.relesed=false;
						binding.emit_on_trigged();//binding.on_trigged();
					}
					filter=FilterReturn.REMOVE;
                }
            }
        }else if (xevent->type == X.EventType.KeyRelease ){
            foreach (var binding in bindings) {
                if (xevent->xkey.keycode == binding.key_code &&
                    (xevent->xkey.state & ~ (lock_modifiers[7]))  == binding.modifiers) {
                    binding.relesed=true;//to ignore AutoRepeat
                    filter=FilterReturn.REMOVE;
                }
            }
		}
        this.processing_event = false;
        return filter;
    }

    public KeyBinding bind (string combination) {
		bool error = false;
        uint key_sym;
        ModifierType modifiers;

        if(this.display==null)
			return null;

        accelerator_parse (combination, out key_sym, out modifiers);
		debug("bind %s display=%d key_sym=%d modifiers=%d",combination,(int)display,(int)key_sym,modifiers);
		if(key_sym != 0 && (combination.contains(">") == (modifiers!=0?true:false) ) ){
			var key_code = display.keysym_to_keycode ((ulong)key_sym);

			if (key_code != 0) {


				foreach (var mod in lock_modifiers){
					error_trap_push ();
					this.display.grab_key (key_code, modifiers | mod, x_id, false, X.GrabMode.Async, X.GrabMode.Async);
					flush();
					if (error_trap_pop()>0) {
					   this.display.ungrab_key (key_code, modifiers | mod, x_id);
					   error=true;
						}
				}
				if(!error){
					var binding = new KeyBinding (combination, key_code, modifiers);
					bindings.add (binding);
					return binding;
				}
			}
		}
    debug ("Binding '%s' failed!\n", combination);
    return null;
    }

    public void unbind(){
		foreach(var bind in bindings){
			foreach (var mod in lock_modifiers){
				this.display.ungrab_key ((int)bind.key_code, bind.modifiers | mod, x_id);
			}
			bindings.remove(bind);
			//bind.destroy();
		}
	}

/*	comment from tilda source, key_grabber.c
 * Shamelessly adapted (read: ripped off) from gdk_window_focus() and
 * http://code.google.com/p/ttm/ trunk/src/window.c set_active()
 *
 * Also, more thanks to halfline and marnanel from irc.gnome.org #gnome
 * for their help in figuring this out.
 *
 * Thank you. And boo to metacity, because they keep breaking us.
 */
	public void send_net_active_window(Gdk.Window window){

			if(window==null)
				return;

			var t = Gdk.x11_get_server_time(window);
			window.focus(t);

//~ 	        var event = X.ClientMessageEvent ();
//~ 	        event.type          = X.EventType.ClientMessage;
//~ 	        event.serial        = 0;
//~ 	        event.send_event    = true;
//~ 	        event.display       = Gdk.x11_get_default_xdisplay (); //this.display;
//~ 	        event.window        = Gdk.X11Window.get_xid(window);//send altyo window id
//~ 	        event.message_type  = x11_get_xatom_by_name ("_NET_ACTIVE_WINDOW");
//~ 	        event.format        = 32;
//~ 	        event.data.l [0]    = 2;
//~ 	        event.data.l [1]    = Gtk.get_current_event_time();//(this.processing_event == true ? this.last_event_time : Gdk.CURRENT_TIME);
//~ 	        event.data.l [2]    = 0;
//~ 	        event.data.l [3]    = 0;
//~ 	        event.data.l [4]    = 0;
//~ 	        X.Event e = (X.Event) event;
//~
//~ 	        display.send_event (Gdk.x11_get_default_root_xwindow(), false, X.EventMask.SubstructureRedirectMask|X.EventMask.StructureNotifyMask, ref e);

	}
}
