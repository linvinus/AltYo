using Gtk;

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
	public AYSettings(MySettings my_conf,Notebook notebook, int tab_index,AYObject ayo) {
		base(my_conf, notebook, tab_index);
		this.tbutton.tab_format="AYSettings";
		this.ayobject=ayo;
		this.builder = new Gtk.Builder ();
 			try {
				this.builder.add_from_resource ("/org/gnome/altyo/preferences.ui");
				this.keybindings_store = builder.get_object ("keybindings_store") as Gtk.ListStore;
				this.builder.connect_signals(this);
				var B = builder.get_object ("settings-scrolledwindow") as Gtk.Widget;
				this.hbox.add(B);
				this.get_from_conf();
 			} catch (Error e) {
 				error ("loading menu builder file: %s", e.message);
 			}
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
	public void reset_terminal_background_image_file  (Gtk.Button w,Gtk.FileChooserButton F) {
		if(F!=null){
			F.unselect_all();
//~			string? S = this.my_conf.get_string("terminal_background_image_file","");
//~			if(S!=null && S!=""){
//~				F.set_filename(S);
//~			}
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
	public void on_lock_keybindings_toggled  (Gtk.CheckButton w) {
		this.ayobject.action_group.set_sensitive(!w.active);
	}
	
	[CCode (instance_pos = -1)]
    public void accel_edited_cb (Gtk.CellRendererAccel cell, string path_string, uint accel_key, Gdk.ModifierType accel_mods, uint hardware_keycode){
		debug("accel_edited_cb start");
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

		if(Gtk.AccelMap.change_entry(accel_path,accel_key,accel_mods,false)){
			debug("accel_edited_cb name:%s ",accel_path);
			string? name = this.get_name_from_path(accel_path);
			if(name!=null){
				var parsed_name=Gtk.accelerator_name (accel_key, accel_mods);
				this.my_conf.set_accel_string(name,parsed_name);				
				this.keybindings_store.set (iter, 2, accel_key);
				this.keybindings_store.set (iter, 3, accel_mods);
				this.my_conf.save();
			}
			
			if(name=="main_hotkey"){
				this.ayobject.main_window.reconfigure();
			}
		}else{
			debug("accel_edited_cb unable to change!");
			string action_label="";
			foreach(var action in this.ayobject.action_group.list_actions ()){
				if(action.get_accel_path()==accel_path){
					action_label=action.get_label();
					break;
					}
			}
			string s=_("Key binding \"%s\" already binded to \"%s\"").printf(Gtk.accelerator_name (accel_key, accel_mods),action_label);
			this.ayobject.main_window.show_message_box("error",s);
		}
    }
    
    [CCode (instance_pos = -1)]
     public void accel_cleared_cb (Gtk.CellRendererAccel cell,string path_string){
		debug("accel_cleared_cb start");
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

    private string? get_name_from_path(string accel_path){
				string[] regs;
				regs=GLib.Regex.split_simple("^.*/(.*)$",accel_path,RegexCompileFlags.CASELESS,0);
					if(regs!=null && regs[1]!=null){
						return regs[1];
					}
			return null;
	}
    	
	public void get_from_conf() {

		var chb = builder.get_object ("lock_keybindings_checkbutton") as Gtk.CheckButton;
		if(chb!=null)
			chb.active = !this.ayobject.action_group.sensitive;
		
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
				if(key=="position"){
					var B = builder.get_object (key) as Gtk.ComboBox;
						B.active=this.my_conf.get_integer(key,0);
				}else{
					var B = builder.get_object (key) as Gtk.SpinButton;
					if(B!=null){
						B.value=this.my_conf.get_integer(key,0);
					}else debug(" no gui for key %s",key);
				}
				break;
				case CFG_TYPE.TYPE_STRING:
						if(key=="terminal_font"){
							var B = builder.get_object (key) as Gtk.FontButton;
							B.font_name=this.my_conf.get_string(key,"");
						}else
						if(key=="terminal_color_fg" || key=="terminal_color_bg" || key=="terminal_tint_color"){
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
							}
						}else						
						if(key=="program_style"){
							var B = builder.get_object (key) as Gtk.TextView;
							var s=this.my_conf.get_string(key,"");
							Regex regex = new Regex ("[{};]");
							string result = regex.replace_eval(s, s.length,0,0, (match_info, result)=>{
							result.append(match_info.fetch(match_info.get_match_count()-1)+"\n");	
							return false;//continue
							});
							B.buffer.text=result;
						}else{
							var B = builder.get_object (key) as Gtk.Entry;
							if(B!=null){
								B.text=this.my_conf.get_string(key,"");
							}else
								debug(" no gui for key %s",key);
						}
				break;
				case CFG_TYPE.TYPE_STRING_LIST:
				break;
				case CFG_TYPE.TYPE_ACCEL_STRING:
				break;
			}
		}
		
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
						-1);
					}
				});		
				
	}//get_from_conf

	public void apply() {
		var keys = this.my_conf.get_profile_keys();
		foreach(var key in keys){
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
						if(B.value!=this.my_conf.get_double(key,0))
							this.my_conf.set_double(key, B.value, 2);
					}else debug(" no gui for key %s",key);
				break;
				case CFG_TYPE.TYPE_INTEGER:
				if(key=="position"){
					var B = builder.get_object (key) as Gtk.ComboBox;
						if(B.active!=this.my_conf.get_integer(key,0))
							this.my_conf.set_integer(key,B.active);
				}else{
					var B = builder.get_object (key) as Gtk.SpinButton;
					if(B!=null){
						if(B.value!=this.my_conf.get_integer(key,0))
							this.my_conf.set_integer(key,(int)B.value);
					}else debug(" no gui for key %s",key);
				}
				break;
				case CFG_TYPE.TYPE_STRING:
						if(key=="terminal_font"){
							var B = builder.get_object (key) as Gtk.FontButton;
							if(B.font_name!=this.my_conf.get_string(key,""))
								this.my_conf.set_string(key,B.font_name);
						}else
						if(key=="terminal_color_fg" || key=="terminal_color_bg" || key=="terminal_tint_color"){
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
							Regex regex = new Regex ("\n");
							string result = regex.replace (s, s.length, 0, "");
							if(result!=this.my_conf.get_string(key,"")){
								this.my_conf.set_string(key,result);
							}
						}else{
							var B = builder.get_object (key) as Gtk.Entry;
							if(B!=null){
								if(B.text!=this.my_conf.get_string(key,""))
									this.my_conf.get_string(key,B.text);
							}else
								debug(" no gui for key %s",key);
						}
				break;
				case CFG_TYPE.TYPE_STRING_LIST:
				break;
				case CFG_TYPE.TYPE_ACCEL_STRING:
				break;
			}
		}
		this.my_conf.reload_config();
		this.my_conf.save();
	}//apply

}//class AYSettings
