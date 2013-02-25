using Gtk;

public class AYSettings : AYTab{
	private Gtk.Builder builder;
	public AYSettings(MySettings my_conf,Notebook notebook, int tab_index) {
		base(my_conf, notebook, tab_index);
		this.tbutton.tab_format="AYSettings";
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
				var B = builder.get_object (key) as Gtk.SpinButton;
					if(B!=null){
						B.value=this.my_conf.get_integer(key,0);
					}else debug(" no gui for key %s",key);
				break;
				case CFG_TYPE.TYPE_STRING:
				var B = builder.get_object (key) as Gtk.Entry;
					if(B!=null){
						B.text=this.my_conf.get_string(key,"");
					}else{
						if(key=="terminal_font"){
							var BF = builder.get_object (key) as Gtk.FontButton;
							BF.font_name=this.my_conf.get_string(key,"");
						}else
						if(key=="terminal_color_fg" || key=="terminal_color_bg"){
							var BC = builder.get_object (key) as Gtk.ColorButton;
							unowned Gdk.Color? color;
							if(Gdk.Color.parse(this.my_conf.get_string(key,""),out color))
								BC.set_color(color);
						}else
						if(key=="terminal_background_image_file"){
							var BFl = builder.get_object (key) as Gtk.FileChooserButton;
							BFl.set_filename(this.my_conf.get_string(key,""));
						}else						
						if(key=="program_style"){
							var BTv = builder.get_object (key) as Gtk.TextView;
							var s=this.my_conf.get_string(key,"");
							Regex regex = new Regex ("}");
							string result = regex.replace (s, s.length, 0, "}\n");
							BTv.buffer.text=result;
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
		//this.my_conf.get_string("custom_command","");
	}

}//class AYSettings
