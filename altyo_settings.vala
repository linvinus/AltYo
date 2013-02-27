using Gtk;

public class AYSettings : AYTab{
	private Gtk.Builder builder;
	public VTMainWindow win_parent {get;set;default=null;}
	public AYSettings(MySettings my_conf,Notebook notebook, int tab_index,VTMainWindow wp) {
		base(my_conf, notebook, tab_index);
		this.tbutton.tab_format="AYSettings";
		this.win_parent=wp;
		this.builder = new Gtk.Builder ();
 			try {
				this.builder.add_from_resource ("/org/gnome/altyo/preferences.ui");
				this.builder.connect_signals(this);
				var B = builder.get_object ("settings-notebook") as Gtk.Widget;
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
		this.win_parent.action_group.get_action("open_settings").activate();
	}
	
	public void get_from_conf() {
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
							unowned Gdk.Color? color;
							if(Gdk.Color.parse(this.my_conf.get_string(key,""),out color))
								B.set_color(color);
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
							Regex regex = new Regex ("}");
							string result = regex.replace (s, s.length, 0, "}\n");
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
							this.my_conf.set_double(key,B.value);
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
							unowned Gdk.Color? color;
							B.get_color(out color);
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
							Regex regex = new Regex ("}\n");
							string result = regex.replace (s, s.length, 0, "}");
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
