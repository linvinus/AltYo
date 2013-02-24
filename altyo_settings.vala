using Gtk;

public class AYSettings : AYTab{
	public string name;
	public AYSettings(MySettings my_conf,Notebook notebook, int tab_index) {
		base(my_conf, notebook, tab_index);
		this.tbutton.tab_format="AYSettings";
		var builder = new Gtk.Builder ();
 			try {
				builder.add_from_resource ("/org/gnome/altyo/preferences.ui");
 			} catch (Error e) {
 				error ("loading menu builder file: %s", e.message);
 			}
 		builder.connect_signals(this);
		var B = builder.get_object ("settings-notebook") as Gtk.Widget;
		
		this.hbox.add(B);
		name="blabla";
	}
	[CCode (instance_pos = -1)]
	public void on_font_set  (Gtk.FontButton w) {
		debug("New font is: %s",w.get_font_name());
	}
}//class AYSettings
