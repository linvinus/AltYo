using Gtk;

  //vala bug, without CCode will generate AY_SETTINGS_terminal_palettes[5] = {{{
  //https://bugzilla.gnome.org/show_bug.cgi?id=604371
  //[CCode (cname = "AY_SETTINGS_terminal_palettes[5][16]",array_length_cname = "5",array_length= false)]
  //[CCode (cname = "AY_SETTINGS_terminal_palettes[16]",array_length= false)]
    /* Tango palette */
    const Gdk.RGBA terminal_palettes_tango[16] = {
      { 0,         0,        0,         1 },
      { 0.8,       0,        0,         1 },
      { 0.305882,  0.603922, 0.0235294, 1 },
      { 0.768627,  0.627451, 0,         1 },
      { 0.203922,  0.396078, 0.643137,  1 },
      { 0.458824,  0.313725, 0.482353,  1 },
      { 0.0235294, 0.596078, 0.603922,  1 },
      { 0.827451,  0.843137, 0.811765,  1 },
      { 0.333333,  0.341176, 0.32549,   1 },
      { 0.937255,  0.160784, 0.160784,  1 },
      { 0.541176,  0.886275, 0.203922,  1 },
      { 0.988235,  0.913725, 0.309804,  1 },
      { 0.447059,  0.623529, 0.811765,  1 },
      { 0.678431,  0.498039, 0.658824,  1 },
      { 0.203922,  0.886275, 0.886275,  1 },
      { 0.933333,  0.933333, 0.92549,   1 }
    };

    /* Linux palette */
public const Gdk.RGBA terminal_palettes_linux[16] = {
      { 0,        0,        0,        1 },
      { 0.666667, 0,        0,        1 },
      { 0,        0.666667, 0,        1 },
      { 0.666667, 0.333333, 0,        1 },
      { 0,        0,        0.666667, 1 },
      { 0.666667, 0,        0.666667, 1 },
      { 0,        0.666667, 0.666667, 1 },
      { 0.666667, 0.666667, 0.666667, 1 },
      { 0.333333, 0.333333, 0.333333, 1 },
      { 1,        0.333333, 0.333333, 1 },
      { 0.333333, 1,        0.333333, 1 },
      { 1,        1,        0.333333, 1 },
      { 0.333333, 0.333333, 1,        1 },
      { 1,        0.333333, 1,        1 },
      { 0.333333, 1,        1,        1 },
      { 1,        1,        1,        1 }
    };


    /* XTerm palette */
    const Gdk.RGBA terminal_palettes_xterm[16] = {
      { 0,        0,        0,        1 },
      { 0.803922, 0,        0,        1 },
      { 0,        0.803922, 0,        1 },
      { 0.803922, 0.803922, 0,        1 },
      { 0.117647, 0.564706, 1,        1 },
      { 0.803922, 0,        0.803922, 1 },
      { 0,        0.803922, 0.803922, 1 },
      { 0.898039, 0.898039, 0.898039, 1 },
      { 0.298039, 0.298039, 0.298039, 1 },
      { 1,        0,        0,        1 },
      { 0,        1,        0,        1 },
      { 1,        1,        0,        1 },
      { 0.27451,  0.509804, 0.705882, 1 },
      { 1,        0,        1,        1 },
      { 0,        1,        1,        1 },
      { 1,        1,        1,        1 }
    };

    /* RXVT palette */
    const Gdk.RGBA terminal_palettes_rxvt[16] = {
      { 0,        0,        0,        1 },
      { 0.803922, 0,        0,        1 },
      { 0,        0.803922, 0,        1 },
      { 0.803922, 0.803922, 0,        1 },
      { 0,        0,        0.803922, 1 },
      { 0.803922, 0,        0.803922, 1 },
      { 0,        0.803922, 0.803922, 1 },
      { 0.980392, 0.921569, 0.843137, 1 },
      { 0.25098,  0.25098,  0.25098,  1 },
      { 1, 0, 0, 1 },
      { 0, 1, 0, 1 },
      { 1, 1, 0, 1 },
      { 0, 0, 1, 1 },
      { 1, 0, 1, 1 },
      { 0, 1, 1, 1 },
      { 1, 1, 1, 1 }
    };

    /* Solarized palette (1.0.0beta2): http://ethanschoonover.com/solarized */
    const Gdk.RGBA terminal_palettes_solarized[16] = {
      { 0.02745,  0.211764, 0.258823, 1 },
      { 0.862745, 0.196078, 0.184313, 1 },
      { 0.521568, 0.6,      0,        1 },
      { 0.709803, 0.537254, 0,        1 },
      { 0.149019, 0.545098, 0.823529, 1 },
      { 0.82745,  0.211764, 0.509803, 1 },
      { 0.164705, 0.631372, 0.596078, 1 },
      { 0.933333, 0.909803, 0.835294, 1 },
      { 0,        0.168627, 0.211764, 1 },
      { 0.796078, 0.294117, 0.086274, 1 },
      { 0.345098, 0.431372, 0.458823, 1 },
      { 0.396078, 0.482352, 0.513725, 1 },
      { 0.513725, 0.580392, 0.588235, 1 },
      { 0.423529, 0.443137, 0.768627, 1 },
      { 0.57647,  0.631372, 0.631372, 1 },
      { 0.992156, 0.964705, 0.890196, 1 }
    };

const string settings_base_css = """
 AYTerm {
 -AYTerm-bg-color: @ayterm-bg-color;
 -AYTerm-fg-color: @ayterm-fg-color;
 -AYTerm-palette-0 : @ayterm-palette-0;
 -AYTerm-palette-1 : @ayterm-palette-1;
 -AYTerm-palette-2 : @ayterm-palette-2;
 -AYTerm-palette-3 : @ayterm-palette-3;
 -AYTerm-palette-4 : @ayterm-palette-4;
 -AYTerm-palette-5 : @ayterm-palette-5;
 -AYTerm-palette-6 : @ayterm-palette-6;
 -AYTerm-palette-7 : @ayterm-palette-7;
 -AYTerm-palette-8 : @ayterm-palette-8;
 -AYTerm-palette-9 : @ayterm-palette-9;
 -AYTerm-palette-10 : @ayterm-palette-10;
 -AYTerm-palette-11 : @ayterm-palette-11;
 -AYTerm-palette-12 : @ayterm-palette-12;
 -AYTerm-palette-13 : @ayterm-palette-13;
 -AYTerm-palette-14 : @ayterm-palette-14;
 -AYTerm-palette-15 : @ayterm-palette-15;
 }

VTToggleButton GtkLabel  {
 font: Mono 10;
 -GtkWidget-focus-padding: 0px;
 -GtkButton-default-border:0px;
 -GtkButton-default-outside-border:0px;
 -GtkButton-inner-border:0px;
 border-width:0px;
 -outer-stroke-width: 0px;
 margin:0px;
 padding:0px;
}

VTToggleButton {
 -GtkWidget-focus-padding: 0px;
 -GtkButton-default-border:0px;
 -GtkButton-default-outside-border:0px;
 -GtkButton-inner-border:0px;
 border-color:alpha(#000000,0.0);
 border-width: 1px;
 -outer-stroke-width: 0px;
 border-radius: 3px;
 border-style: solid;
 background-image: none;
 margin:0px;
 padding:0px 0px 0px 0px;
}

VTToggleButton:active {
 text-shadow: none;
}
.window_multitabs {
border-width: 2px 2px 0px 2px;
border-color: #3C3B37;
border-style: solid;
padding:0px;
margin:0;
}
#terms_notebook {
border-width: 0px;
border-style: solid;
padding:0px;
margin:0;
}
#search_hbox :active {
 border-color: @fg_color;
 color: #FF0000;
}
#search_hbox :prelight {
 background-color: @ayterm-bg-color;
 border-color: @fg_color;
 color: #FF0000;
}
#search_hbox {
 border-width: 0px 0px 0px 0px;
 -outer-stroke-width: 0px;
 border-radius: 0px 0px 0px 0px;
 border-style: solid;
 background-image: none;
 margin:0px;
 padding:0px 0px 1px 0px;
}
HVBox {
 border-width: 0px 2px 2px 2px;
 border-style: solid;
}

#OffscreenWindow, VTMainWindow,#HVBox_dnd_window {
 border-width: 0px;
 border-style: solid;
 background-color: alpha(@ayterm-bg-color,0.0);
}
HVBox,#quick_options_notebook{
 background-color: @ayterm-bg-color;
}
#settings-scrolledwindow{
 background-color: @bg_color;
}

VTToggleButton{
 box-shadow: none;
 transition-duration: 0s;
}

.window_single_tab {
 border-width: 2px 2px 2px 2px;
 border-style: solid;
}
""";

const string settings_css_solarized_dark="""
 @define-color ayterm-bg-color alpha(#063541,1.00);
 @define-color ayterm-fg-color #EDE7D4;
 @define-color ayterm-palette-15 #FCF5E2;
 @define-color ayterm-palette-14 #92A0A0;
 @define-color ayterm-palette-13 #6B70C3;
 @define-color ayterm-palette-12 #829395;
 @define-color ayterm-palette-11 #647A82;
 @define-color ayterm-palette-10 #576D74;
 @define-color ayterm-palette-9 #CA4A15;
 @define-color ayterm-palette-8 #002A35;
 @define-color ayterm-palette-7 #EDE7D4;
 @define-color ayterm-palette-6 #29A097;
 @define-color ayterm-palette-5 #D23581;
 @define-color ayterm-palette-4 #258AD1;
 @define-color ayterm-palette-3 #B48800;
 @define-color ayterm-palette-2 #849900;
 @define-color ayterm-palette-1 #DB312E;
 @define-color ayterm-palette-0 #063541;
 @define-color tab-index-color @ayterm-palette-11;
 @define-color username-color  @ayterm-palette-2;
 @define-color hostname-color  @ayterm-palette-9;


VTToggleButton {
 -VTToggleButton-tab-index-color:@ayterm-palette-11;
 -VTToggleButton-username-color:@ayterm-palette-2;
 -VTToggleButton-hostname-color:@ayterm-palette-9; 
 background-color: alpha(@ayterm-bg-color,0.0);
 color: @ayterm-fg-color;
}
VTToggleButton:active{
 background-color: @ayterm-palette-15;
 background-image: none;
 color: @ayterm-palette-11;
}
VTToggleButton:prelight {
 background-color: @ayterm-palette-7;
 background-image:none;
 color: @ayterm-bg-color;
}
VTToggleButton:active:prelight{
 background-color:@ayterm-palette-7;
 background-image: none;
 color: @ayterm-palette-0;
}
.window_multitabs {
 border-color: #3C3B37;
 border-style: solid;
}
#search_hbox :active {
 border-color: @fg_color;
 color: #FF0000;
}
#search_hbox :prelight {
 background-color: @ayterm-bg-color;
 border-color: @fg_color;
 color: #FF0000;
}
#search_hbox {
 background-color: @ayterm-bg-color;
 border-color: @bg_color;
 color: #00FFAA;
}
HVBox {
 border-color: #3C3B37;
 border-style: solid;
 background-color: @ayterm-bg-color;
}
#OffscreenWindow, VTMainWindow,#HVBox_dnd_window {
 border-style: solid;
 background-color: alpha(@ayterm-bg-color,0.0);
}
HVBox,#quick_options_notebook{
 background-color: @ayterm-bg-color;
}
#settings-scrolledwindow{
 background-color: @bg_color;
}
#settings-scrolledwindow{
 background-color: @bg_color;
}
VTToggleButton{
 box-shadow: none;
 transition-duration: 0s;
}

.window_single_tab {
 border-color: #3C3B37;
 border-style: solid;
}
""";


const string settings_css_linux = """
 @define-color ayterm-bg-color alpha(#000000,1.00);
 @define-color ayterm-fg-color #AAAAAA;
 @define-color ayterm-palette-15 #FFFFFF;
 @define-color ayterm-palette-14 #54FFFF;
 @define-color ayterm-palette-13 #FF54FF;
 @define-color ayterm-palette-12 #5454FF;
 @define-color ayterm-palette-11 #FFFF54;
 @define-color ayterm-palette-10 #54FF54;
 @define-color ayterm-palette-9 #FF5454;
 @define-color ayterm-palette-8 #545454;
 @define-color ayterm-palette-7 #AAAAAA;
 @define-color ayterm-palette-6 #00AAAA;
 @define-color ayterm-palette-5 #AA00AA;
 @define-color ayterm-palette-4 #0000AA;
 @define-color ayterm-palette-3 #AA5400;
 @define-color ayterm-palette-2 #00AA00;
 @define-color ayterm-palette-1 #AA0000;
 @define-color ayterm-palette-0 #000000;
 @define-color tab-index-color @ayterm-palette-11;
 @define-color username-color  @ayterm-palette-15;
 @define-color hostname-color  @ayterm-palette-11;

VTToggleButton {
  -VTToggleButton-tab-index-color:@ayterm-palette-11;
  -VTToggleButton-username-color:@ayterm-palette-15;
  -VTToggleButton-hostname-color:@ayterm-palette-11;
  border-color:alpha(#000000,0.0);
  background-color: alpha(#000000,0.0);
  color: #AAAAAA;
  box-shadow: none;
}
VTToggleButton:active{
  background-color: #00AAAA;
  background-image: -gtk-gradient(radial,center center, 0,center center, 1, from (#00BBBB),to (#008888) );
  color: #000000;
}
VTToggleButton:prelight {
  background-color: #AAAAAA;
  background-image: -gtk-gradient(radial,center center, 0,center center, 1, from (#AAAAAA),to (#777777) );
  color: #000000;
}
VTToggleButton:active:prelight{
  background-color: #00AAAA;
  background-image: -gtk-gradient(radial,center center, 0,center center, 1, from (lighter(#00BBBB)),to (#008888) );
  color: #000000;
}
.window_multitabs {
 border-color: #3C3B37;
 border-style: solid;
}
#search_hbox :active {
 border-color: @fg_color;
 color: #FF0000;
}
#search_hbox :prelight {
 background-color: @ayterm-bg-color;
 border-color: @fg_color;
 color: #FF0000;
}
#search_hbox {
 background-color: @ayterm-bg-color;
 border-color: @bg_color;
 color: #00FFAA;
}
HVBox {
 border-color: #3C3B37;
 border-style: solid;
 background-color: @ayterm-bg-color;
}
#OffscreenWindow, VTMainWindow,#HVBox_dnd_window {
 border-style: solid;
 background-color: alpha(@ayterm-bg-color,0.0);
}
HVBox,#quick_options_notebook{
 background-color: @ayterm-bg-color;
}
#settings-scrolledwindow{
 background-color: @bg_color;
}
#settings-scrolledwindow{
 background-color: @bg_color;
}
VTToggleButton{
 box-shadow: none;
 transition-duration: 0s;
}
.window_single_tab {
 border-color: #3C3B37;
 border-style: solid;
}

""";
//terminal_palettes_rxvt;

public class point_ActionGroup_store {
	public unowned Gtk.ActionGroup action_group;
	public unowned Gtk.ListStore store;
	public unowned AYSettings yasettings;
	public point_ActionGroup_store(Gtk.ActionGroup ag,Gtk.ListStore st,AYSettings yas) {
		this.action_group=ag;
		this.store=st;
		this.yasettings=yas;
	}
}



public class AYSettings : AYTab{
	private Gtk.Builder builder;
	public AYObject ayobject {get;set;default=null;}
	private Gtk.ListStore keybindings_store;
	private string autorun_file;
	private string monitor_name;/*save monitor name on which settings was opened*/
	private bool ignore_on_loading;/*ignore some events when loading settings from ini file*/
  private VTToggleButton vttbut;
  
	public AYSettings(MySettings my_conf,Notebook notebook, int tab_index,AYObject ayo) {
		base(my_conf, notebook, tab_index);
		this.tbutton.set_title(tab_index, _("AYsettings") );
		this.ayobject=ayo;
		if(this.ayobject.main_window.application.application_id!=null)
			this.autorun_file = GLib.Environment.get_user_config_dir()+"/autostart"+"/"+this.ayobject.main_window.application.application_id+".desktop";
		else{
			if(my_conf.standalone_mode)
				this.autorun_file = GLib.Environment.get_user_config_dir()+"/autostart"+"/altyo.standalone.desktop";
			else
				this.autorun_file = GLib.Environment.get_user_config_dir()+"/autostart"+"/altyo.none.desktop";
		}
		this.builder = new Gtk.Builder ();
 			try {
				this.builder.add_from_resource ("/org/gnome/altyo/preferences.glade");
				this.builder.add_from_resource("/org/gnome/altyo/encodings_list.glade");
				this.keybindings_store = builder.get_object ("keybindings_store") as Gtk.ListStore;

				var encodings_combo = builder.get_object ("terminal_default_encoding") as Gtk.ComboBox;
				var encodinsg_store = this.builder.get_object ("encodings_liststore") as Gtk.ListStore;
				encodinsg_store.set_sort_column_id(1,Gtk.SortType.ASCENDING);
				encodings_combo.model=encodinsg_store;
				//connect model from encodings_list.glade to preferences.glade
				var del_combo = builder.get_object ("terminal_delete_binding") as Gtk.ComboBox;
				del_combo.model= this.builder.get_object ("terminal_delete_binding_liststore") as Gtk.ListStore;
				var bps_combo = builder.get_object ("terminal_backspace_binding") as Gtk.ComboBox;
				bps_combo.model= this.builder.get_object ("terminal_delete_binding_liststore") as Gtk.ListStore;
				
				this.builder.connect_signals(this);
				var B = builder.get_object ("settings-scrolledwindow") as Gtk.Widget;
				B.name="settings-scrolledwindow";
				B.destroy.connect(()=>{debug("~settings-scrolledwindow");});
				this.hbox.add(B);
				var L = builder.get_object ("config_path_linkbutton") as Gtk.LinkButton;
				L.label=my_conf.conf_file;
				L.uri="file://"+my_conf.conf_file;
				#if VTE_2_91
				/*hide unavailable options*/
				Gtk.Grid grid;
				int r = 0;
				Gtk.Widget? child;

				grid = (builder.get_object ("grid9") as Gtk.Grid);
				while( (child=grid.get_child_at(1,r)) != null){
					switch(child.get_name()){
						case "terminal_background_image_file":
						case "terminal_background_fake_transparent":
						case "terminal_background_fake_transparent_scroll":
						case "terminal_tint_color":
						case "terminal_background_saturation":
						grid.remove_row(r);
						break;
						default:
						r++;
						break;
					}
				}
				grid = (builder.get_object ("grid1") as Gtk.Grid);
				while( (child=grid.get_child_at(1,r)) != null){
					switch(child.get_name()){
						case "terminal_visible_bell":
						case "terminal_set_alternate_screen_scroll":
						grid.remove_row(r);
						break;
						default:
						r++;
						break;
					}
				}
				grid = (builder.get_object ("grid5") as Gtk.Grid);
				r = 0;
				while( (child=grid.get_child_at(1,r)) != null){
					switch(child.get_name()){
						case "terminal_word_chars":
						grid.remove_row(r);
						break;
						default:
						r++;
						break;
					}
				}
				#endif
        this.vttbut = new VTToggleButton();
				this.get_from_conf();
 			} catch (Error e) {
 				error ("loading menu builder file: %s", e.message);
 			}
 		if(my_conf.readonly){
			var A = builder.get_object ("apply_button") as Gtk.Button;
			A.sensitive=false;
			var R = builder.get_object ("restore_button") as Gtk.Button;
			R.sensitive=false;
			R.tooltip_text=A.tooltip_text=_("Config is read only!");
		}
	}
	
	~AYSettings(){
		debug("~AYSettings");	
	}

	[CCode (instance_pos = -1)]
	public void on_font_set  (Gtk.FontButton w) {
		debug("New font is: %s",w.get_font_name());
	}

	[CCode (instance_pos = -1)]
	public void on_animation_enabled_toggled  (Gtk.CheckButton w) {
		var B = builder.get_object ("animation_pull_steps") as Gtk.SpinButton;
		if(B!=null){
			B.sensitive=w.active;
		}
	}
	
	[CCode (instance_pos = -1)]
	public void on_workaround_if_focuslost_toggled  (Gtk.CheckButton w) {
		if(!this.ignore_on_loading && w.active){
			string title=_("AltYo attention");
			string msg=_("You must restart altyo for the workaround to take effect.");
			this.ayobject.main_window.show_message_box(title,msg);
		}
	}

	[CCode (instance_pos = -1)]
	public void on_size_changed  (Gtk.SpinButton w,Gtk.Label L) {
		if(L!=null){
			if(w.value>100){
				L.label=_("px");
			}else
			if(w.value==100){
				L.label=_("maximize");
			}else{
				L.label=_("%");
			}
		}
	}

	[CCode (instance_pos = -1)]
	public void on_reset_terminal_background_image_file  (Gtk.Button w,Gtk.FileChooserButton F) {
		if(F!=null){
			F.unselect_all();
		}
	}

	[CCode (instance_pos = -1)]
	public void on_apply(Gtk.Button w) {
		this.apply();
	}

	[CCode (instance_pos = -1)]
	public void on_close(Gtk.Button w) {
		this.ayobject.action_group.set_sensitive(true);//activate
		this.ayobject.action_group.get_action("open_settings").activate();
	}

	[CCode (instance_pos = -1)]
	public void on_reset_to_defaults(Gtk.Button w) {
		GLib.Timeout.add(50,()=>{this.ayobject.show_reset_to_defaults_dialog();return false;});//async call
	}

	[CCode (instance_pos = -1)]
    public void accel_edited_cb (Gtk.CellRendererAccel cell, string path_string, uint accel_key, Gdk.ModifierType accel_mods, uint hardware_keycode){
		debug("accel_edited_cb start");
		this.ayobject.action_group.set_sensitive(true);
        var path = new Gtk.TreePath.from_string (path_string);
        if (path == null)
            return;
        Gtk.TreeIter iter;
        if (!this.keybindings_store.get_iter (out iter, path))
            return;
        string? accel_path = null;
        this.keybindings_store.get (iter, 0, out accel_path);
        if (accel_path == null)
            return;

		Gtk.Action action=this.ayobject.action_group.get_action(this.get_name_from_path(accel_path));
		
		if(this.ayobject.update_action_keybinding(action,accel_key,accel_mods)){
			debug("accel_edited_cb name:%s ",accel_path);
			string? name = this.get_name_from_path(accel_path);
			if(name!=null){
				var parsed_name=Gtk.accelerator_name (accel_key, accel_mods);
				this.my_conf.set_accel_string(name,parsed_name);
				if(name=="main_hotkey"){
					this.ayobject.main_window.reconfigure();//check is it was correct, and not busy
					var saved_key = this.my_conf.get_accel_string(name,"");
					if(parsed_name != saved_key){
						//some thing was wrong,update key value
						uint accelerator_key;
						Gdk.ModifierType accelerator_mods;
						Gtk.accelerator_parse(saved_key,out accelerator_key,out accelerator_mods);
						accel_key=accelerator_key;
						accel_mods=accelerator_mods;
					}
				}
			this.keybindings_store.set (iter, 2, accel_key);
			this.keybindings_store.set (iter, 3, accel_mods);
			this.my_conf.save();
			}
		}
    }

    [CCode (instance_pos = -1)]
     public void accel_cleared_cb (Gtk.CellRendererAccel cell,string path_string){
		debug("accel_cleared_cb start");
		this.ayobject.action_group.set_sensitive(true);
        var path = new Gtk.TreePath.from_string (path_string);
        if (path == null)
            return;
        Gtk.TreeIter iter;
        if (!this.keybindings_store.get_iter (out iter, path))
            return;
        string? accel_path = null;
        this.keybindings_store.get (iter, 0, out accel_path);
        if (accel_path == null)
            return;
		if(Gtk.AccelMap.change_entry(accel_path,0,0,false)){
			string? name = get_name_from_path(accel_path);
			if(name!=null){
				this.my_conf.set_accel_string(name,"");//clear in config
				this.keybindings_store.set (iter, 2, 0);
				this.my_conf.save();
			}
		}
//~         settings.set_int (key, 0);
    }
	[CCode (instance_pos = -1)]
	public void accel_editing_started_cb (Gtk.CellRenderer cell,
						  Gtk.CellEditable editable,
						  string    path_string){
		debug("accel_editing_started_cb");
		this.ayobject.action_group.set_sensitive(false);
		var tree = builder.get_object ("keybindings_treeview") as Gtk.TreeView;
		tree.grab_focus();//so Gtk.CellRendererAccel will have a focus
	}

    [CCode (instance_pos = -1)]
    public bool on_list_button_press_event(Gtk.Widget w,Gdk.EventButton event){
		debug("command_list_button_press_event %s",w.name);
			if((int)event.button == 3){//right mouse button
					if(((Gtk.Buildable)w).get_name()=="terminal_autostart_session_treeview"){
						var popup_menu = builder.get_object ("popup_command_list") as Gtk.Menu;
						popup_menu.popup(null, null, null, event.button, event.time);
					}else
					if(((Gtk.Buildable)w).get_name()=="tab_title_format_regex_treeview"){
						var popup_menu = builder.get_object ("popup_tab_title_format_regex") as Gtk.Menu;
						popup_menu.popup(null, null, null, event.button, event.time);
					}else
					if(((Gtk.Buildable)w).get_name()=="terminal_url_regexps_treeview"){
						var popup_menu = builder.get_object ("popup_terminal_url_regexps") as Gtk.Menu;
						popup_menu.popup(null, null, null, event.button, event.time);
					}
					return true;
			}
		return false;
	}

	[CCode (instance_pos = -1)]
	public void on_popup_command_list_add(Gtk.MenuItem item){
		var store = builder.get_object ("terminal_autostart_session") as Gtk.ListStore;
		TreeIter? data_iter = this.list_store_add_after_selected("terminal_autostart_session_treeview",store);
		if(data_iter!=null){
			store.set (data_iter,
			0, "/bin/sh",
			-1);
		}
	}

	[CCode (instance_pos = -1)]
	public void on_popup_command_list_remove(Gtk.MenuItem item){
		var store = builder.get_object ("terminal_autostart_session") as Gtk.ListStore;
		var view = builder.get_object ("terminal_autostart_session_treeview") as Gtk.TreeView;
		if(store!=null && view!=null){
				TreePath path;
				TreeViewColumn s_column;
				TreeIter? iter=null;
				view.get_cursor(out path,out s_column);
				if(store.get_iter(out iter,path))
				if(!store.iter_has_child(iter)){
					store.remove(iter);
					if(store.get_iter(out iter,path))
						view.set_cursor(path,null,false);
					else if(path.prev())
						view.set_cursor(path,null,false);
					else if(path.up())
						view.set_cursor(path,null,false);
				}
		}
	}

	[CCode (instance_pos = -1)]
	public void on_popup_tab_title_format_regex_add(Gtk.MenuItem item){
		var store = builder.get_object ("tab_title_format_regex") as Gtk.ListStore;
		TreeIter? data_iter = this.list_store_add_after_selected("tab_title_format_regex_treeview",store);
		if(data_iter!=null){
			store.set (data_iter,
				0, "",
				1, "",
				-1);
		}
	}

	[CCode (instance_pos = -1)]
	public void on_popup_tab_title_format_regex_remove(Gtk.MenuItem item){
		var store = builder.get_object ("tab_title_format_regex") as Gtk.ListStore;
		var view = builder.get_object ("tab_title_format_regex_treeview") as Gtk.TreeView;
		if(store!=null && view!=null){
				TreePath path;
				TreeViewColumn s_column;
				TreeIter? iter=null;
				view.get_cursor(out path,out s_column);
				if(store.get_iter(out iter,path))
				if(!store.iter_has_child(iter)){
					store.remove(iter);
					if(store.get_iter(out iter,path))
						view.set_cursor(path,null,false);
					else if(path.prev())
						view.set_cursor(path,null,false);
					else if(path.up())
						view.set_cursor(path,null,false);
				}
		}
	}

	[CCode (instance_pos = -1)]
	public void on_popup_terminal_url_regexps_add(Gtk.MenuItem item){
		var store = builder.get_object ("terminal_url_regexps") as Gtk.ListStore;
		TreeIter? data_iter = this.list_store_add_after_selected("terminal_url_regexps_treeview",store);
		if(data_iter!=null){
			store.set (data_iter,
			0, "",
			1, "",
			-1);
		}
	}

	[CCode (instance_pos = -1)]
	public void on_popup_terminal_url_regexps_remove(Gtk.MenuItem item){
		var store = builder.get_object ("terminal_url_regexps") as Gtk.ListStore;
		var view = builder.get_object ("terminal_url_regexps_treeview") as Gtk.TreeView;
		if(store!=null && view!=null){
				TreePath path;
				TreeViewColumn s_column;
				TreeIter? iter=null;
				view.get_cursor(out path,out s_column);
				if(store.get_iter(out iter,path))
				if(!store.iter_has_child(iter)){
					store.remove(iter);
					if(store.get_iter(out iter,path))
						view.set_cursor(path,null,false);
					else if(path.prev())
						view.set_cursor(path,null,false);
					else if(path.up())
						view.set_cursor(path,null,false);
				}
		}
	}

	[CCode (instance_pos = -1)]
	public void on_terminal_autostart_session_cellrenderertext_edited (Gtk.CellRendererText renderer, string path_string, string new_text){
		debug("on_terminal_autostart_session_cellrenderertext_edited start %s",path_string);

		Gtk.ListStore? store=null;

		store = builder.get_object("terminal_autostart_session") as Gtk.ListStore;

		if(store == null) return;

        var path = new Gtk.TreePath.from_string (path_string);

        if (path == null) return;

        Gtk.TreeIter iter;
        if (!store.get_iter (out iter, path)) return;

		store.set (iter,
			0, new_text,
			-1);
	}

	[CCode (instance_pos = -1)]
	public void on_tab_title_format_regex_cellrenderertext_pattern_edited (Gtk.CellRendererText renderer, string path_string, string new_text){
		debug("on_tab_title_format_regex_cellrenderertext_pattern_edited start %s",path_string);

		Gtk.ListStore? store=null;

		store = builder.get_object ("tab_title_format_regex") as Gtk.ListStore;

		if(store == null) return;

        var path = new Gtk.TreePath.from_string (path_string);

        if (path == null) return;

        Gtk.TreeIter iter;
        if (!store.get_iter (out iter, path)) return;

		string err;
		if(!this.my_conf.check_regex(new_text,out err)){
			var bg=new Gdk.RGBA();
			bg.parse("#FF0000");
			store.set (iter,
			0, new_text,
			2, GLib.Markup.escape_text(err,-1), /*tooltip*/
			3, bg,
			5, true,/*strikethrough*/
			-1);
		}else{
			store.set (iter,
			0, new_text,
			2, null,
			3, null,
			5, false,/*strikethrough*/
			-1);
		}
	}

	[CCode (instance_pos = -1)]
	public void on_tab_title_format_regex_cellrenderertext_replace_edited (Gtk.CellRendererText renderer, string path_string, string new_text){
		debug("on_tab_title_format_regex_cellrenderertext_replace_edited start %s",path_string);

		Gtk.ListStore? store=null;

		store = builder.get_object ("tab_title_format_regex") as Gtk.ListStore;

		if(store == null) return;

        var path = new Gtk.TreePath.from_string (path_string);

        if (path == null) return;

        Gtk.TreeIter iter;
        if (!store.get_iter (out iter, path)) return;


		string err;
    var s = replace_color_in_markup(this.vttbut,new_text);

		if(!this.my_conf.check_markup(s,out err)){
			var bg=new Gdk.RGBA();
			bg.parse("#FF0000");
			store.set (iter,
			1, new_text,
			2, GLib.Markup.escape_text(err,-1), /*tooltip*/
			4, bg,
			6, true,/*strikethrough*/
			-1);
		}else{
			store.set (iter,
			1, new_text,
			2, null,
			4, null,
			6, false,/*strikethrough*/
			-1);
		}
	}

	[CCode (instance_pos = -1)]
	public void on_terminal_url_regexps_match_cellrenderertext_pattern_edited (Gtk.CellRendererText renderer, string path_string, string new_text){
		debug("on_terminal_url_regexps_match_cellrenderertext_pattern_edited start %s",path_string);

		Gtk.ListStore? store=null;

		store = builder.get_object ("terminal_url_regexps") as Gtk.ListStore;

		if(store == null) return;

        var path = new Gtk.TreePath.from_string (path_string);

        if (path == null) return;

        Gtk.TreeIter iter;
        if (!store.get_iter (out iter, path)) return;

		string err;
		if(!this.my_conf.check_regex(new_text,out err)){
			var bg=new Gdk.RGBA();
			bg.parse("#FF0000");
			store.set (iter,
			0, new_text,
			2, GLib.Markup.escape_text(err,-1), /*tooltip*/
			3, bg,
			4, true,/*strikethrough*/
			-1);
		}else{
			store.set (iter,
			0, new_text,
			2, null,
			3, null,
			4, false,/*strikethrough*/
			-1);
		}

	}
	[CCode (instance_pos = -1)]
	public void on_terminal_url_regexps_run_cellrenderertext_pattern_edited (Gtk.CellRendererText renderer, string path_string, string new_text){
		debug("on_terminal_url_regexps_run_cellrenderertext_pattern_edited start %s",path_string);

		Gtk.ListStore? store=null;

		store = builder.get_object ("terminal_url_regexps") as Gtk.ListStore;

		if(store == null) return;

        var path = new Gtk.TreePath.from_string (path_string);

        if (path == null) return;

        Gtk.TreeIter iter;
        if (!store.get_iter (out iter, path)) return;

		store.set (iter,
			1, new_text,
			-1);
	}

    private string? get_name_from_path(string accel_path){
				string[] regs;
				regs=GLib.Regex.split_simple("^.*/(.*)$",accel_path,RegexCompileFlags.CASELESS,0);
					if(regs!=null && regs[1]!=null){
						return regs[1];
					}
			return null;
	}

	[CCode (instance_pos = -1)]
	public void on_check_css_button_activate(Gtk.Button w) {
		debug("on_check_css_button_activate");
		var B = builder.get_object ("program_style") as Gtk.TextView;
		var L = builder.get_object ("check_css_label") as Gtk.Label;
		string S="";
		string msg="";
		uint line,pos;
		if(!this.check_css(B.buffer.text,ref S,out line,out pos)){
			msg=_("in line %d  at position %d error:%s").printf(line,pos,S);
			debug("on_check_css_button_activate %s",msg);
			TextIter where;
			B.buffer.get_iter_at_line_offset(out where,(int)line,(int)pos);
			B.buffer.place_cursor(where);
			B.grab_focus();
		}else
			msg=_("Looks good");
		L.label=msg;
	}

	private bool check_css(string css_text,ref string msg,out uint line,out uint pos){
		bool ret=true;
		string S="";
		uint L=0,P=0;
		var css_main = new CssProvider ();
		css_main.parsing_error.connect((section,error)=>{
			if(ret){
				debug("css_main.parsing_error %s",error.message);
				L=section.get_end_line();
				P=section.get_end_position();
				S=error.message;
				ret=false;
			}
			});

		try{
			css_main.load_from_data (css_text,-1);
		}catch (Error e) {
			//debug("Theme error! loading default..");
		}
		msg=S;
		line=L;
		pos=P;
		return ret;
	}

	[CCode (instance_pos = -1)]
	public void on_terminal_prevent_close_regex_changed(Gtk.Editable editable) {
		var E = builder.get_object ("terminal_prevent_close_regex") as Gtk.Entry;
		this.check_entry_regex(E);
	}

	[CCode (instance_pos = -1)]
	public void on_terminal_session_exclude_regex(Gtk.Editable editable) {
		var E = builder.get_object ("terminal_session_exclude_regex") as Gtk.Entry;
		this.check_entry_regex(E);
	}

	[CCode (instance_pos = -1)]
	public void on_terminal_terminal_exclude_variables(Gtk.Editable editable) {
		var E = builder.get_object ("terminal_exclude_variables") as Gtk.Entry;
		this.check_entry_regex(E);
	}

	[CCode (instance_pos = -1)]
	public void on_tab_format_markup(Gtk.Editable editable) {
		var E = builder.get_object ("tab_format") as Gtk.Entry;
		this.check_entry_markup(E);
	}

	[CCode (instance_pos = -1)]
	public void on_tab_title_format_markup(Gtk.Editable editable) {
		var E = builder.get_object ("tab_title_format") as Gtk.Entry;
		this.check_entry_markup(E);
	}

	private void check_entry_regex(Gtk.Entry E) {
		if( E != null){
			string err;
			if(!this.my_conf.check_regex(replace_color_in_markup(this.vttbut,E.text),out err)){
				E.set_tooltip_text (err);
				var bg=new Gdk.RGBA();
				bg.parse("#FF0000");
				E.override_color(Gtk.StateFlags.NORMAL,bg);
			}else{
				E.set_tooltip_text (err);
				E.override_color(Gtk.StateFlags.NORMAL,null);
			}
		}
	}

	private void check_entry_markup(Gtk.Entry E) {
		if( E != null){
			string err;
			if(!this.my_conf.check_markup(replace_color_in_markup(this.vttbut,E.text),out err)){
				E.set_tooltip_text (err);
				var bg=new Gdk.RGBA();
				bg.parse("#FF0000");
				E.override_color(Gtk.StateFlags.NORMAL,bg);
			}else{
				E.set_tooltip_text (err);
				E.override_color(Gtk.StateFlags.NORMAL,null);
			}
		}
	}

	private TreeIter? list_store_add_after_selected(string key,Gtk.ListStore store){
		TreeIter? data_iter=null;
		var view = builder.get_object (key) as Gtk.TreeView;

		if(store!=null && view!=null){
			TreeModel model;
			TreeIter selected_iter;
			var selection = view.get_selection();
			if(selection.get_selected(out model,out selected_iter)){
				store.insert_after (out data_iter, selected_iter);
			}else{
				store.append (out data_iter);
			}
		}
		return data_iter;
	}

	[CCode (instance_pos = -1)]
	public void on_terminal_background_image_file_file_set  (Gtk.FileChooserButton w) {
		string? S=null;
		S=w.get_filename();		
		var B = builder.get_object ("terminal_background_fake_transparent_scroll") as Gtk.CheckButton;
		if(B!=null){
			if(S!=null && S!="")
				B.sensitive=true;
			else
				B.sensitive=true;
		}
	}

	[CCode (instance_pos = -1)]
	public void on_terminal_notify_level_changed(Gtk.ComboBox w){
		var B = builder.get_object ("terminal_timeout_before_notify") as Gtk.SpinButton;
		if(B!=null){
			B.sensitive=( (w.active==1 || w.active==3) ?true:false);
		}
	}
  /*multidimensional array, hahaha*/
	private Gdk.RGBA? get_color_from_array(int theme,int x){
    switch(theme){
      case 0 : return terminal_palettes_tango[x];
      case 1 : return terminal_palettes_linux[x];
      case 2 : return terminal_palettes_xterm[x];
      case 3 : return terminal_palettes_rxvt[x];
      case 4 : return terminal_palettes_solarized[x];
    };
    return null;
  }
  [CCode (instance_pos = -1)]
	public void on_opacity_changed  (Gtk.SpinButton opacity_w) {//ay_settings_on_opacity_changed
    var CB = builder.get_object ("terminal_color_bg") as Gtk.ColorButton;
    var bg = CB.get_rgba();
    bg.alpha=opacity_w.get_value();
    CB.set_rgba(bg);
    var B = builder.get_object ("program_style") as Gtk.TextView;
    string css_inner = B.buffer.text;//get
    string alpha="%1.2f".printf(round_double(bg.alpha,2));
    alpha=alpha.replace(",",".");
    update_css_global_color(ref css_inner,"ayterm-bg-color","alpha(%s,%s)".printf(hexRGBA(bg),alpha) );
    
    B.buffer.text=css_inner;//done
  }
  [CCode (instance_pos = -1)]
	public void on_theme_changed  (Gtk.ComboBox w) {//ay_settings_on_theme_changed
    Gtk.ColorButton CB;
    int theme_index=w.get_active();
    var B = builder.get_object ("program_style") as Gtk.TextView;
    //B.buffer.text;
    string css_inner="";
    switch(theme_index){
      case 0 : css_inner=settings_css_linux; break;
      case 1 : css_inner=settings_css_linux; break;
      case 2 : css_inner=settings_css_linux; break;
      case 3 : css_inner=settings_css_linux; break;
      case 4 : css_inner=settings_css_solarized_dark; break;
    };
    
    for(int i=1; i<17;i++){
      CB = builder.get_object ("terminal_palette_colorbutton"+i.to_string()) as Gtk.ColorButton;
      if(CB!=null){
          //vala bug problem with accsess to multidimentional array
          CB.set_rgba(get_color_from_array(theme_index,i-1));
          update_css_global_color(ref css_inner,"ayterm-palette-%d".printf(i-1),hexRGBA(CB.rgba) );
        }
    }
    CB = builder.get_object ("terminal_color_fg") as Gtk.ColorButton;
    CB.set_rgba(get_color_from_array(theme_index,7));
    update_css_global_color(ref css_inner,"ayterm-fg-color",hexRGBA(CB.rgba) );
    
    CB = builder.get_object ("terminal_color_bg") as Gtk.ColorButton;
    var bg = get_color_from_array(theme_index,0);
    var opacity_w = builder.get_object ("terminal_opacity") as Gtk.SpinButton;
    bg.alpha=opacity_w.get_value();
    CB.set_rgba(bg);

    string alpha="%1.2f".printf(round_double(bg.alpha,2));
    alpha=alpha.replace(",",".");
    update_css_global_color(ref css_inner,"ayterm-bg-color","alpha(%s,%s)".printf(hexRGBA(bg),alpha) );
    
    B.buffer.text=css_inner;//done
              
              //string css = "AYTerm { %s } ".printf(css_inner);
              //debug(css);
              
              //https://regex101.com/r/iT2eR5/9
//~               Regex css_regex = new Regex ("""((^\s*)|(\}\s*))(?P<AYTerm_css>AYTerm\s*\{\s*(([\/\*].*[\*\/])?[^}]+?)+\s*\})""");
//~               MatchInfo match_info;
//~               var css_result = new StringBuilder(s); 
//~               if(css_regex.match(s,0, out match_info) ){
//~                 debug(" RegexEvalCallback match_info ");
//~                 int start_pos, end_pos;
//~                 if(match_info.fetch_named_pos("AYTerm_css",out start_pos, out end_pos) ){
//~                   debug(" RegexEvalCallback %d %d ",start_pos,end_pos);
//~                   
//~                   css_result.erase(start_pos,end_pos-start_pos);
//~                   css_result.insert(start_pos,css);
//~                 }
//~               }else{
//~                   css_result.prepend(css);
//~               }    
	}
    
	private string css_ini_to_human(string s){
    Regex regex = new Regex ("[{};]");
    string result = regex.replace_eval(s, s.length,0,0, (match_info, result)=>{
    result.append(match_info.fetch(match_info.get_match_count()-1)+"\n");
    return false;//continue
    });
    return result;
  }
  private void load_css(){
    //load css colors  
    var test_term =new AYTerm();//will be  destroyed automatically
    var tct =  new term_colors_t();

    test_term.gen_colors(tct);
    
    Gtk.ColorButton CB;
    CB = builder.get_object ("terminal_color_fg") as Gtk.ColorButton;
    if(tct.fg!=null)
      CB.set_rgba(tct.fg);
    else
      CB.set_rgba(terminal_palettes_linux[7]);
    CB = builder.get_object ("terminal_color_bg") as Gtk.ColorButton;
    var opacity_w = builder.get_object ("terminal_opacity") as Gtk.SpinButton;
    if(tct.bg!=null){
      CB.set_rgba(tct.bg);
      opacity_w.set_value(tct.bg.alpha);
    }else{
      CB.set_rgba(terminal_palettes_linux[0]);
      opacity_w.set_value(1.0);
    }
    for(int i=1; i<17;i++){
      CB = builder.get_object ("terminal_palette_colorbutton"+i.to_string()) as Gtk.ColorButton;
      if(CB!=null)
          CB.set_rgba(tct.palette[i-1]);
    }

  }
  
  private void update_css_global_color(ref string where,string name, string val){
    bool done=false;
    Regex regex = new Regex ("""\@define\-color\s+"""+GLib.Regex.escape_string(name)+"""\s+(?P<val>[^\;]+);""");
    var result = regex.replace_eval(where,-1,0,0,(match_info, result)=>{
            var v = match_info.fetch_named("val");
            if(v!=null){
                result.append("@define-color ");
                result.append(name);
                result.append(" ");
                result.append(val);
                result.append(";");
                done=true;
                return true;
            }else
              result.append(match_info.fetch(0));
      return false;
      });
      if(!done){
        string s = "@define-color %s %s;\n %s".printf(name,val,where);
        where=s;
      }else
        where=result;
  }

	public void get_from_conf() {
		unowned Gdk.Screen gscreen = this.ayobject.main_window.get_screen ();
        int win_x,win_y;
        this.ayobject.main_window.get_position (out win_x, out win_y);	
		this.monitor_name = gscreen.get_monitor_plug_name(gscreen.get_monitor_at_point (win_x,win_y));
		this.ignore_on_loading = true;
		
		var keys = this.my_conf.get_profile_keys();
		foreach(var key in keys){
			switch(this.my_conf.get_key_type(key)){
				case CFG_TYPE.TYPE_UNKNOWN:
				continue;
				break;
				case CFG_TYPE.TYPE_BOOLEAN:
				var B = builder.get_object (key) as Gtk.CheckButton;
					if(B!=null){
						B.active=this.my_conf.get_boolean(key,false);
					}else debug(" no gui for key %s",key);
				break;
				case CFG_TYPE.TYPE_DOUBLE:
				var B = builder.get_object (key) as Gtk.SpinButton;
					if(B!=null){
						B.value=this.my_conf.get_double(key,0);
					}else debug(" no gui for key %s",key);
				break;
				case CFG_TYPE.TYPE_INTEGER:
				if(key=="terminal_cursorshape" ||
				   key=="terminal_cursor_blinkmode" ||
				   key=="terminal_delete_binding" ||
				   key=="terminal_backspace_binding" ||
				   key=="terminal_notify_level" ||
				   key=="window_action_on_close_last_tab" ||
				   key=="window_new_tab_position" ||
				   key=="window_hvbox_display_mode"){
					var B = builder.get_object (key) as Gtk.ComboBox;
						B.active=this.my_conf.get_integer(key,0);
				}else if(key=="window_position_x_%s".printf(this.monitor_name) ){
					string unikey = key.substring(0,key.index_of (this.monitor_name)-1);//window_position_x_VGA-0 -> window_position_x
					var B = builder.get_object (unikey) as Gtk.ComboBox;
						B.active=this.my_conf.get_integer(key,0);					
				}else if(key=="terminal_width_%s".printf(this.monitor_name) ||
					   key=="terminal_height_%s".printf(this.monitor_name) ||
					   key=="window_position_y_%s".printf(this.monitor_name) ) {
						   string unikey = key.substring(0,key.index_of (this.monitor_name)-1);//terminal_width_VGA-0 -> terminal_width
							var B = builder.get_object (unikey) as Gtk.SpinButton;
							if(B!=null){
								B.value=this.my_conf.get_integer(key,0);
							}else debug(" no gui for key %s",key);
				}else{
					var B = builder.get_object (key) as Gtk.SpinButton;
					if(B!=null){
						B.value=this.my_conf.get_integer(key,0);
					}else debug(" no gui for key %s",key);
				}
				break;
				case CFG_TYPE.TYPE_STRING:
						if(key=="window_default_monitor"){
							var store = builder.get_object (key+"_liststore") as Gtk.ListStore;
							
							for(var i=0;i<gscreen.get_n_monitors ();i++){
								TreeIter? data_iter=null;
								store.append (out data_iter);
								store.set (data_iter,
								0,gscreen.get_monitor_plug_name(i),
								-1);
							}
							var combo = builder.get_object (key) as Gtk.ComboBox;
							var entry = combo.get_child() as Gtk.Entry;
							entry.text=this.my_conf.get_string(key,"");

							var curr_monitor = builder.get_object (key+"_label") as Gtk.Label;
							curr_monitor.label = this.monitor_name;
						}else
						if(key=="terminal_font"){
							var B = builder.get_object (key) as Gtk.FontButton;
							B.font_name=this.my_conf.get_string(key,"");
						}else
						if(key=="terminal_tint_color"){
							var B = builder.get_object (key) as Gtk.ColorButton;
							var color=new Gdk.RGBA();
							if(color.parse(this.my_conf.get_string(key,"")))
								B.set_rgba(color);
						}else
						if(key=="terminal_background_image_file"){
							var S = this.my_conf.get_string(key,"");
							if(S!=""){
								var B = builder.get_object (key) as Gtk.FileChooserButton;
								B.set_filename(S);
							}else{
								var B = builder.get_object ("terminal_background_fake_transparent_scroll") as Gtk.CheckButton;
								if(B!=null){
									B.sensitive=false;
								}
							}
						}else
						if(key=="program_style"){
							var B = builder.get_object (key) as Gtk.TextView;
							var s=this.my_conf.get_string(key,"");
							B.buffer.text=this.css_ini_to_human(s);
						}else
						if(key=="tab_sort_order"){
							var B = builder.get_object (key) as Gtk.ComboBox;
							var store = builder.get_object (key+"_liststore") as Gtk.ListStore;
							string ret = this.my_conf.get_string(key,"none");
							store.foreach((model,  path,  iter) =>{
									string? val=null;
									store.get (iter,1, out val,	-1);//get combobox item value
									if(val!=null && val==ret){
										B.active=path.get_indices()[0];
										return true;//stop
									}
								return false;//continue
							});
					
						}else
						if(key=="terminal_default_encoding"){
							unowned TreeIter iter;
							string term_encoding = this.my_conf.get_string(key,"");
							var encodings_combo = builder.get_object ("terminal_default_encoding") as Gtk.ComboBox;
							bool found=false;
							//try to find encoding in a list
							if(encodings_combo.model.get_iter_first(out iter))
								do{
									string s;
									encodings_combo.model.get(iter,0,out s);
									if(s == term_encoding){
										found=true;
										break;
										}
								}while(encodings_combo.model.iter_next(ref iter));
								
							if(found)
								encodings_combo.set_active_iter(iter);
							else
								((Entry)encodings_combo.get_child()).set_text(term_encoding);
						}else{
							var B = builder.get_object (key) as Gtk.Entry;
							if(B!=null){
								B.text=this.my_conf.get_string(key,"");
							}else
								debug(" no gui for key %s",key);
						}
				break;
				case CFG_TYPE.TYPE_STRING_LIST:
						var store = builder.get_object (key) as Gtk.ListStore;
						if(store!=null){
							string[] sl=this.my_conf.get_string_list(key,null);
							if(key=="tab_title_format_regex" || key=="terminal_url_regexps"){
								for(int i=0; i<sl.length-1;i+=2){
									TreeIter? data_iter=null;
									store.append (out data_iter);
									store.set (data_iter,
									0, sl[i],
									1, sl[i+1],
									-1);
								}
							}else
							if(key=="terminal_autostart_session"){
								for(int i=0; i<sl.length;i++){
									TreeIter? data_iter=null;
									store.append (out data_iter);
									store.set (data_iter,
									0, sl[i],
									-1);
								}
							}
						}else
						if(key=="terminal_palette"){
							string[] sl=this.my_conf.get_string_list(key,null);
							if(sl.length==16){
								for(int i=1; i<17;i++){
									var B = builder.get_object ("terminal_palette_colorbutton"+i.to_string()) as Gtk.ColorButton;
									if(B!=null){
										var color=new Gdk.RGBA();
										if(color.parse(sl[i-1]))
											B.set_rgba(color);
									}
								}
							}
						}else
							debug(" no gui for key %s",key);
				break;
				case CFG_TYPE.TYPE_ACCEL_STRING:
				break;
			}//
		}//foreach key

			AccelMap am2=Gtk.AccelMap.get();
			var p2 = new point_ActionGroup_store(this.ayobject.action_group,this.keybindings_store,this);

			am2.foreach(p2,(pvoid,accel_path,accel_key,accel_mods,ref changed)=>{
				unowned Gtk.ListStore p_store=(Gtk.ListStore)((point_ActionGroup_store)pvoid).store;
				unowned Gtk.ActionGroup ag=(Gtk.ActionGroup)((point_ActionGroup_store)pvoid).action_group;
				unowned AYSettings yasettings=(AYSettings)((point_ActionGroup_store)pvoid).yasettings;

				string? s = yasettings.get_name_from_path(accel_path);

					if(s!=null && ag.get_action(s)!=null){
						TreeIter? data_iter=null;
						p_store.append (out data_iter);
						p_store.set (data_iter,
						0, accel_path,
						1, ag.get_action(s).get_label(),
						2, accel_key,
						3, accel_mods,
						4, true,/*editable*/
						5, ag.get_action(s).get_tooltip(),
						-1);
					}
				});
				this.keybindings_store.set_sort_column_id(0,Gtk.SortType.ASCENDING);

				if(GLib.FileUtils.test(this.autorun_file,GLib.FileTest.EXISTS)){

						if(!this.get_autostart_hidden()){
							var B = builder.get_object ("window_autostart_with_desktop") as Gtk.CheckButton;
								if(B!=null){
									B.active=true;
								}else debug(" no gui for window_autostart_with_desktop");
						}
				}
		#if !ALTERNATE_SCREEN_SCROLL
		if(my_conf.DISTR_ID!=DISTRIB_ID.UBUNTU){
			//debian patch vte_terminal_set_alternate_screen_scroll
			var ASS = builder.get_object ("terminal_set_alternate_screen_scroll") as Gtk.CheckButton;
			ASS.sensitive=false;
		}
		#endif
    
    this.load_css();
    
		this.ignore_on_loading = false;
	}//get_from_conf

	public void apply() {
		var keys = this.my_conf.get_profile_keys();
		foreach(var key_bug in keys){
			var key=key_bug;//bug in UBUNTU precise
			switch(this.my_conf.get_key_type(key)){
				case CFG_TYPE.TYPE_UNKNOWN:
				continue;
				break;
				case CFG_TYPE.TYPE_BOOLEAN:
				var B = builder.get_object (key) as Gtk.CheckButton;
					if(B!=null){
						if(B.active!=this.my_conf.get_boolean(key,false))
							this.my_conf.set_boolean(key,B.active);
					}else debug(" no gui for key %s",key);
				break;
				case CFG_TYPE.TYPE_DOUBLE:
				var B = builder.get_object (key) as Gtk.SpinButton;
					if(B!=null){
						/***** WARNING! *******************
						 * accuracy, two sign after comma*/
						int r_val=(int)((B.value+0.005) * 100);//round
						B.value=(double)((double)(r_val)/(double)100);
						//debug("CFG_TYPE.TYPE_DOUBLE=%.2f",B.value);
						if(B.value!=this.my_conf.get_double(key,0))
							this.my_conf.set_double(key, B.value, 2);//two sign after comma
					}else debug(" no gui for key %s",key);
				break;
				case CFG_TYPE.TYPE_INTEGER:
				if(key=="terminal_cursorshape" ||
				   key=="terminal_cursor_blinkmode" ||
				   key=="terminal_delete_binding" ||
				   key=="terminal_backspace_binding" ||
				   key=="terminal_notify_level" ||
				   key=="window_action_on_close_last_tab" ||
				   key=="window_new_tab_position" ||
				   key=="window_hvbox_display_mode"){
					var B = builder.get_object (key) as Gtk.ComboBox;
						if(B.active!=this.my_conf.get_integer(key,0))
							this.my_conf.set_integer(key,B.active);
				}else if(key=="window_position_x_%s".printf(this.monitor_name) ){
					string unikey = key.substring(0,key.index_of (this.monitor_name)-1);//window_position_x_VGA-0 -> window_position_x
					var B = builder.get_object (unikey) as Gtk.ComboBox;
						if(B.active!=this.my_conf.get_integer(key,0))
							this.my_conf.set_integer(key,B.active);
				}else if(key=="terminal_width_%s".printf(this.monitor_name) ||
					   key=="terminal_height_%s".printf(this.monitor_name) ||
					   key=="window_position_y_%s".printf(this.monitor_name) ) {
						   string unikey = key.substring(0,key.index_of (this.monitor_name)-1);//terminal_width_VGA-0 -> terminal_width
							var B = builder.get_object (unikey) as Gtk.SpinButton;
							if(B!=null){
								if(B.value!=this.my_conf.get_integer(key,0))
									this.my_conf.set_integer(key,(int)B.value);
							}else debug(" no gui for key %s",key);
				}else{
					var B = builder.get_object (key) as Gtk.SpinButton;
					if(B!=null){
						if(B.value!=this.my_conf.get_integer(key,0))
							this.my_conf.set_integer(key,(int)B.value);
					}else debug(" no gui for key %s",key);
				}
				break;
				case CFG_TYPE.TYPE_STRING:
						if(key=="window_default_monitor"){
							var combo = builder.get_object (key) as Gtk.ComboBox;
							var entry = combo.get_child() as Gtk.Entry;
							if(entry.text!=this.my_conf.get_string(key,"")){
								this.my_conf.set_string(key,entry.text);
							}
						}else
						if(key=="terminal_font"){
							var B = builder.get_object (key) as Gtk.FontButton;
							if(B.font_name!=this.my_conf.get_string(key,""))
								this.my_conf.set_string(key,B.font_name);
						}else
						if(/*key=="terminal_color_fg" || key=="terminal_color_bg" ||*/ key=="terminal_tint_color"){
							var B = builder.get_object (key) as Gtk.ColorButton;
							var color=B.get_rgba();
							var S = color.to_string();
							if(S!=null && S != this.my_conf.get_string(key,"")){
								this.my_conf.set_string(key,S);
							}

						}else
						if(key=="terminal_background_image_file"){
							string? S=null;
							var B = builder.get_object (key) as Gtk.FileChooserButton;
							S=B.get_filename();
							if(S!=this.my_conf.get_string(key,"")){
								debug("terminal_background_image_file=%s",S);
								this.my_conf.set_string(key,S);
							}
						}else
						if(key=="program_style"){
							var B = builder.get_object (key) as Gtk.TextView;
							var s=B.buffer.text;
							string S="";
							uint line,pos;
							if(!this.check_css(s,ref S,out line,out pos)){
								string msg=_("New style will not be saved!\nin line %d  at position %d\nerror:%s").printf(line,pos,S);
								debug("on config apply css error %s",msg);
								this.ayobject.main_window.show_message_box(_("AltYo CSS style error"),msg);
							}else{//looks good
								Regex regex = new Regex ("\n");
								string result = regex.replace (s,-1, 0, "");
								if(result!=this.my_conf.get_string(key,"")){
									this.my_conf.set_string(key,result);
                  B.buffer.text=this.css_ini_to_human(result);//update 
								}
							}
						}else
						if(key=="tab_sort_order"){
							var B = builder.get_object (key) as Gtk.ComboBox;
							var store = builder.get_object (key+"_liststore") as Gtk.ListStore;
							string ret = this.my_conf.get_string(key,"none");
							var path = new TreePath.from_indices(B.active);
							TreeIter? iter=null;
							string? val=null;
							if(path!=null && store.get_iter (out iter, path)){
								store.get (iter, 1, out val);
								if(val!=ret){
									this.my_conf.set_string(key,val);
									if(val!="none")
										this.ayobject.tab_sort();
									}
							}
						}else
						if(key=="terminal_default_encoding"){
							unowned TreeIter iter;
							var encodings_combo = builder.get_object ("terminal_default_encoding") as Gtk.ComboBox;
							var new_encoding = ((Entry)encodings_combo.get_child()).get_text();
							if(new_encoding==""){
								if(this.my_conf.get_string(key,new_encoding)!="default"){
									this.my_conf.set_string(key,"default");
									((Entry)encodings_combo.get_child()).set_text("default");
								}
							}else if(new_encoding!="default"){
								this.my_conf.set_string(key,new_encoding);
							}
						}else{
							var B = builder.get_object (key) as Gtk.Entry;
							if(B!=null){
								if(B.text!=this.my_conf.get_string(key,"")){
									if(key=="terminal_prevent_close_regex" || key=="terminal_session_exclude_regex" || key =="terminal_exclude_variables"){
										string err;
                    var s = replace_color_in_markup(this.vttbut,B.text);
										if(this.my_conf.check_regex(s,out err)){
											this.my_conf.set_string(key,B.text);//save unchanged markup
										}else{
											string title=_("AltYo %s error").printf(key);
											string msg=_("New value of %s will not be saved!\n%s").printf(key,err);
											this.ayobject.main_window.show_message_box(title,msg);
										}
									}else
									if(key=="tab_format" || key=="tab_title_format"){
										string err;
                    var s = replace_color_in_markup(this.vttbut,B.text);
										if(this.my_conf.check_markup(s,out err)){
											this.my_conf.set_string(key,B.text);//save unchanged markup
										}else{
											string title=_("AltYo %s error").printf(key);
											string msg=_("New value of %s will not be saved!\n%s").printf(key,err);
											this.ayobject.main_window.show_message_box(title,msg);
										}
									}else
										this.my_conf.set_string(key,B.text);
								}
							}else
								debug(" no gui for key %s",key);
						}
				break;
				case CFG_TYPE.TYPE_STRING_LIST:
						var store = builder.get_object (key) as Gtk.ListStore;
						if(store!=null){

							if(key=="tab_title_format_regex" || key=="terminal_url_regexps"){
								string[] sl = {};
								bool ignore_changes=false;
								string err="";
								store.foreach((model,  path,  iter) =>{
										string? s1=null,s2=null;
										store.get (iter,
										0, out s1,
										1, out s2,
										-1);
										if(s1!=null && s2!=null){
                      var smark = replace_color_in_markup(this.vttbut,s2);
											if(this.my_conf.check_regex(s1,out err) &&
											((key=="tab_title_format_regex" && this.my_conf.check_markup(smark,out err)) ||
											  key!="tab_title_format_regex"
											)){
													sl+=s1;
													sl+=s2;
												debug("s1=%s s2=%s",s1,s2);
												return false;//continue
											}else{
												ignore_changes=true;
												return true;//stop
											}
										}else
											return false;//continue, skip empty
									});
								if(!ignore_changes)
									this.my_conf.set_string_list(key,sl);
								else{
									string title=_("AltYo %s error").printf(key);
									string msg=_("New value of %s will not be saved!\n%s").printf(key,err);
									this.ayobject.main_window.show_message_box(title,msg);
								}
							}else
							if(key=="terminal_autostart_session"){
								string[] sl = {};
								store.foreach((model,  path,  iter) =>{
										string? s1=null;
										store.get (iter,
										0, out s1,
										-1);
										if(s1!=null)
											sl+=s1;
										debug("s1=%s",s1);
										return false;//continue
									});
								this.my_conf.set_string_list(key,sl);
							}
						}else
						if(key=="terminal_palette"){
							string[] sl = {};
								for(int i=1; i<17;i++){
									var B = builder.get_object ("terminal_palette_colorbutton"+i.to_string()) as Gtk.ColorButton;
									if(B!=null){
										sl+=B.rgba.to_string();
									}
								}
								this.my_conf.set_string_list(key,sl);
						}else
							debug(" no gui for key %s",key);
				break;
				case CFG_TYPE.TYPE_ACCEL_STRING:
				break;
			}
		}

		var B = builder.get_object ("window_autostart_with_desktop") as Gtk.CheckButton;
		if(B!=null){
			if(B.active){
				if(!GLib.FileUtils.test(this.autorun_file,GLib.FileTest.EXISTS)){
					GLib.DirUtils.create_with_parents(GLib.Path.get_dirname(this.autorun_file),502);//755 create autostart dir if not exist
					try{
						string autorun_content = """
[Desktop Entry]
Type=Application
Encoding=UTF-8
Version=1.0
Name=altyo
Name[ru_RU]=АльтЁ
Comment[ru_RU]=АльтЁ терминал
Comment=AltYo terminal
Exec=altyo""";
					if(my_conf.standalone_mode)
						autorun_content += " --standalone";
						
					if(this.ayobject.main_window.application.application_id!=null)
						autorun_content += " --id="+this.ayobject.main_window.application.application_id+"\n";
					else
						autorun_content += " --id=none\n";
					
						if(!GLib.FileUtils.set_contents (this.autorun_file, autorun_content)){
							debug(" unable to save altyo.desktop file");
							}
					} catch (GLib.FileError err) {
						warning (err.message);
					}
				}else{//file exist, set hidden false
					this.set_autostart_hidden(false);
				}
			}else{//disable autrun
				if(GLib.FileUtils.test(this.autorun_file,GLib.FileTest.EXISTS)){
					//GLib.FileUtils.remove(this.autorun_file);
					this.set_autostart_hidden(true);
				}
			}
		}
		this.my_conf.reload_config();
		this.my_conf.save();
    this.load_css();//reload 
	}//apply


	private void set_autostart_hidden(bool newstate){
		var kf = new KeyFile();
		try {
			kf.load_from_file(this.autorun_file, KeyFileFlags.KEEP_COMMENTS);
		} catch (GLib.KeyFileError err) {
			warning (err.message);
			return;
		}
		bool ret=false;
		try{
			ret=kf.get_boolean(GLib.KeyFileDesktop.GROUP,GLib.KeyFileDesktop.KEY_HIDDEN);
		} catch (GLib.KeyFileError err) {
		}
		if(ret!=newstate){
			kf.set_boolean(GLib.KeyFileDesktop.GROUP,GLib.KeyFileDesktop.KEY_HIDDEN,newstate);//enable
			var str = kf.to_data (null);
			try{
				FileUtils.set_contents (this.autorun_file, str, str.length);
			} catch (FileError err) {
				warning (err.message);
			}
		}
	}//set_autostart_hidden

	private bool get_autostart_hidden(){
		bool ret=false;
		var kf = new KeyFile();
		try {
			kf.load_from_file(this.autorun_file, KeyFileFlags.KEEP_COMMENTS);
		} catch (GLib.KeyFileError err) {
			warning (err.message);
		}
		try{
			ret=kf.get_boolean(GLib.KeyFileDesktop.GROUP,GLib.KeyFileDesktop.KEY_HIDDEN);
		} catch (GLib.KeyFileError err) {
		}
		return ret;
	}//get_autostart_hidden

}//class AYSettings
