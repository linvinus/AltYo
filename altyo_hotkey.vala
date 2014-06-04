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

// Based on http://code.valaide.org/content/global-hotkeys by Oliver Sauder <os@esite.ch>

/*public static void static_handler (string a) {
    PanelHotkey.instance().triggered (a);
}*/

public class KeyBinding : Object {
	public string combination;
	public uint key_code;
	public uint modifiers;
	public bool relesed {get;set;default=true;}
	public signal void on_trigged();

	public KeyBinding (string combination, uint key_code, uint modifiers) {
		this.combination = combination;
		this.key_code = key_code;
		this.modifiers = modifiers;
	}

	~KeyBinding(){
		debug("~KeyBinding");
		//free(this.combination);
	}
}

public class PanelHotkey : Object {
    public signal void triggered (string combination);
    public uint32 last_key_event_time {get;set;default =0;}
    public uint32 last_property_event_time {get;set;default =0;}
    private unowned X.Display display;
    private Gdk.Window root_window;
    private X.ID x_id;
    private X.Atom active_window;
    private bool processing_event = false;
    public signal void on_active_window_change();

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

    private GLib.List<KeyBinding> bindings;

    public PanelHotkey () {
        bindings = new GLib.List<KeyBinding> ();
        root_window = get_default_root_window ();

        this.display = Gdk.x11_get_default_xdisplay ();
        this.active_window = this.display.intern_atom("_NET_ACTIVE_WINDOW",false);
        x_id = X11Window.get_xid (root_window);
        root_window.add_filter (event_filter);

    }

    ~PanelHotkey () {
		debug("~PanelHotkey ()");
		this.unbind();
		 var root_window = Gdk.get_default_root_window ();
		 root_window.remove_filter(event_filter);
	}

    public Gdk.FilterReturn event_filter (Gdk.XEvent gxevent, Gdk.Event event) {

        FilterReturn filter = FilterReturn.CONTINUE;
			this.processing_event = true;
			void* p = gxevent;
			X.Event* xevent = (X.Event*) p;
			this.last_key_event_time = (uint32)xevent->xkey.time;

			if (xevent->type == X.EventType.KeyPress) {
				foreach (var binding in bindings) {
					if (binding.relesed == true && xevent->xkey.keycode == binding.key_code &&
						(xevent->xkey.state & ~ (lock_modifiers[7]))  == binding.modifiers) {
						binding.relesed=false;
						binding.on_trigged();
					}
				}
			}else if (xevent->type == X.EventType.KeyRelease ){
				foreach (var binding in bindings) {
					if (xevent->xkey.keycode == binding.key_code &&
						(xevent->xkey.state & ~ (lock_modifiers[7]))  == binding.modifiers) {
						binding.relesed=true;//to ignore AutoRepeat
					}
				}
			} else if (xevent->type == X.EventType.PropertyNotify ) {
				X.PropertyEvent* pevent = (X.PropertyEvent*) p;
				if(pevent->atom == this.active_window){//_NET_ACTIVE_WINDOW usual come after focus change
					this.last_property_event_time=(uint32)pevent->time;
					this.on_active_window_change();
				}
				//debug("event_filter type=%d state=%d window=%d atom=%s",(int)pevent->type,(int)pevent->state,(int)pevent->window,this.display.get_atom_name(pevent->atom));
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
					if(bindings.first()!=null)
						bindings.append(binding);
					else
						bindings.prepend(binding);
					return binding;
				}
			}
		}
    debug ("Binding '%s' failed!\n", combination);
    return null;
    }

    public void unbind(){
		foreach(unowned KeyBinding bind in bindings){
			foreach (var mod in lock_modifiers){
				this.display.ungrab_key ((int)bind.key_code, bind.modifiers | mod, x_id);
				flush();
			}
			bindings.remove(bind);
			bind.unref();//destroy
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
	public X.Window get_input_focus(){
		int revert_to_return;
		X.Window w,root_return;
		X.Window root_xwin=Gdk.X11Window.get_xid(this.root_window);

		this.display.get_input_focus(out w, out revert_to_return);
		//debug("get_input_focus=%x revert_to_return=%d",(int)w,revert_to_return);
		if(w>1){//not None, not PointerRoot, see XGetInputFocus
			do{
				X.Window parent_return;
				X.Window[] children_return;
				X.Atom[] protocols=null;
				this.display.query_tree (w, out root_return, out parent_return, out children_return);
				//debug("get_input_focus=%x",(int)parent_return);

				if(parent_return>1){
					this.display.get_wm_protocols(parent_return,out protocols);
					if(parent_return != root_xwin && protocols != null)
						w=parent_return;
					else
						break;
				}else
					break;
			}while(true);
		}
		return w;
	}

	public X.Window get_transient_for_xid(X.Window w){
		X.Window result;
		this.display.get_transient_for_hint(w,out result);
		return result;
	}
}
