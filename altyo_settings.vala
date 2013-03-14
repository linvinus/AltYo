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
	private string autorun_file;
	public AYSettings(MySettings my_conf,Notebook notebook, int tab_index,AYObject ayo) {
		base(my_conf, notebook, tab_index);
		this.tbutton.tab_format="AYSettings";
		this.ayobject=ayo;
		this.autorun_file = GLib.Environment.get_user_config_dir()+"/autostart"+"/altyo.desktop";
		this.builder = new Gtk.Builder ();
 			try {
				this.builder.add_from_resource ("/org/gnome/altyo/preferences.glade");
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
				if(name=="main_hotkey"){
					this.ayobject.main_window.reconfigure();//check is it was correct, and not busy
					var saved_key = this.my_conf.get_accel_string(name,"");
					if(parsed_name != saved_key){
						//some thing was wrong,update key value
						unowned uint accelerator_key;
						unowned Gdk.ModifierType accelerator_mods;
						Gtk.accelerator_parse(saved_key,out accelerator_key,out accelerator_mods);
						accel_key=accelerator_key;
						accel_mods=accelerator_mods;
					}
				}
			this.keybindings_store.set (iter, 2, accel_key);
			this.keybindings_store.set (iter, 3, accel_mods);
			this.my_conf.save();
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

    [CCode (instance_pos = -1)]
    public bool on_command_list_button_press_event(Gtk.Widget w,Gdk.EventButton event){
		debug("command_list_button_press_event %s",w.name);
			if((int)event.button == 3){//right mouse button
					if(((Gtk.Buildable)w).get_name()=="terminal_autostart_session_treeview")
						this.create_popup_command_list(event);
					else
					if(((Gtk.Buildable)w).get_name()=="tab_title_format_regex_treeview")
						this.create_popup_tab_title_format_regex(event);
					else
					if(((Gtk.Buildable)w).get_name()=="terminal_url_regexps_treeview")
						this.create_popup_terminal_url_regexps(event);
					return true;
			}
		return false;
	}

    private void create_popup_command_list(Gdk.EventButton event){
		debug("popup_command_list");
		Gtk.MenuItem menuitem;

    	var popup_menu = new Gtk.Menu();

		menuitem = new Gtk.MenuItem.with_label(_("Add"));
		menuitem.activate.connect(on_popup_command_list_add);
		popup_menu.append(menuitem);

		menuitem = new Gtk.MenuItem.with_label(_("Remove"));
		menuitem.activate.connect(on_popup_command_list_remove);
		popup_menu.append(menuitem);

		popup_menu.deactivate.connect (this.on_popup_deactivate);
		popup_menu.show_all();
        //menu.attach_to_widget (this.vte_term, null);
		popup_menu.popup(null, null, null, event.button, event.time);
		popup_menu.ref();//no one own menu,emulate owners,uref will be on_deactivate
	}

    private void create_popup_tab_title_format_regex(Gdk.EventButton event){
		debug("popup_tab_title_format_regex");
		Gtk.MenuItem menuitem;

    	var popup_menu = new Gtk.Menu();

		menuitem = new Gtk.MenuItem.with_label(_("Add"));
		menuitem.activate.connect(on_popup_tab_title_format_regex_add);
		popup_menu.append(menuitem);

		menuitem = new Gtk.MenuItem.with_label(_("Remove"));
		menuitem.activate.connect(on_popup_tab_title_format_regex_remove);
		popup_menu.append(menuitem);

		popup_menu.deactivate.connect (this.on_popup_deactivate);
		popup_menu.show_all();
        //menu.attach_to_widget (this.vte_term, null);
		popup_menu.popup(null, null, null, event.button, event.time);
		popup_menu.ref();//no one own menu,emulate owners,uref will be on_deactivate
	}

    private void create_popup_terminal_url_regexps(Gdk.EventButton event){
		debug("popup_terminal_url_regexps");
		Gtk.MenuItem menuitem;

    	var popup_menu = new Gtk.Menu();

		menuitem = new Gtk.MenuItem.with_label(_("Add"));
		menuitem.activate.connect(on_popup_terminal_url_regexps_add);
		popup_menu.append(menuitem);

		menuitem = new Gtk.MenuItem.with_label(_("Remove"));
		menuitem.activate.connect(on_popup_terminal_url_regexps_remove);
		popup_menu.append(menuitem);

		popup_menu.deactivate.connect (this.on_popup_deactivate);
		popup_menu.show_all();
        //menu.attach_to_widget (this.vte_term, null);
		popup_menu.popup(null, null, null, event.button, event.time);
		popup_menu.ref();//no one own menu,emulate owners,uref will be on_deactivate
	}

	private void on_popup_deactivate(Widget m) {
			((Gtk.Menu)m).deactivate.disconnect(on_popup_deactivate);
			m.unref();//menu will be destroyed after end of deactivate event
			//debug("popup_menu ref_count=%d",(int)m.ref_count);//normal count 4
		}

	private void on_popup_command_list_add(){
		var store = builder.get_object ("terminal_autostart_session") as Gtk.ListStore;
		if(store!=null){
			TreeIter? data_iter=null;
			store.append (out data_iter);
			store.set (data_iter,
			0, "/bin/sh",
			-1);
		}
	}

	private void on_popup_command_list_remove(){
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

	private void on_popup_tab_title_format_regex_add(){
		var store = builder.get_object ("tab_title_format_regex") as Gtk.ListStore;
		if(store!=null){
			TreeIter? data_iter=null;
			store.append (out data_iter);
			store.set (data_iter,
			0, "",
			1, "",
			-1);
		}
	}

	private void on_popup_tab_title_format_regex_remove(){
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

	private void on_popup_terminal_url_regexps_add(){
		var store = builder.get_object ("terminal_url_regexps") as Gtk.ListStore;
		if(store!=null){
			TreeIter? data_iter=null;
			store.append (out data_iter);
			store.set (data_iter,
			0, "",
			1, "",
			-1);
		}
	}

	private void on_popup_terminal_url_regexps_remove(){
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

		store.set (iter,
			0, new_text,
			-1);
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

		store.set (iter,
			1, new_text,
			-1);
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

		store.set (iter,
			0, new_text,
			-1);
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
				if(key=="position" ||
				   key=="terminal_cursorshape" ||
				   key=="terminal_cursor_blinkmode" ||
				   key=="terminal_delete_binding" ||
				   key=="terminal_backspace_binding" ){
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
						if(key=="window_default_monitor"){
							var store = builder.get_object (key+"_liststore") as Gtk.ListStore;
							unowned Gdk.Screen gscreen = this.ayobject.main_window.get_screen ();
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
							int x,y;
							this.ayobject.main_window.get_position (out x, out y);
							var curr_monitor = builder.get_object (key+"_label") as Gtk.Label;
							curr_monitor.label = gscreen.get_monitor_plug_name(gscreen.get_monitor_at_point (x,y));
						}else
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
		//debian patch vte_terminal_set_alternate_screen_scroll
		var ASS = builder.get_object ("terminal_set_alternate_screen_scroll") as Gtk.CheckButton;
		ASS.sensitive=false;
		#endif

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
				if(key=="position" ||
				   key=="terminal_cursorshape" ||
				   key=="terminal_cursor_blinkmode" ||
				   key=="terminal_delete_binding" ||
				   key=="terminal_backspace_binding"){
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
									this.my_conf.set_string(key,B.text);
							}else
								debug(" no gui for key %s",key);
						}
				break;
				case CFG_TYPE.TYPE_STRING_LIST:
						var store = builder.get_object (key) as Gtk.ListStore;
						if(store!=null){

							if(key=="tab_title_format_regex" || key=="terminal_url_regexps"){
								string[] sl = {};
								store.foreach((model,  path,  iter) =>{
										string? s1=null,s2=null;
										store.get (iter,
										0, out s1,
										1, out s2,
										-1);
										if(s1!=null)
											sl+=s1;
										if(s2!=null)
											sl+=s2;
										debug("s1=%s s2=%s",s1,s2);
										return false;//continue
									});
								this.my_conf.set_string_list(key,sl);
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
Exec=altyo
						""";
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
