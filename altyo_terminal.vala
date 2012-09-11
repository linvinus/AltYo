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
using Vte;
#if HAVE_QLIST
using GnomeKeyring;
#endif

public delegate void OnChildExitCallBack(VTTerminal vt);

public class TildaAuth:Object{
	public string? user;
	public string? password;
	public string? host;
	public string? command;
	public string? type;

	public TildaAuth(string? user,string? password,string? host,string? command){
		this.user=user;
		this.password=password;
		this.host=host;
		//string[] commands={};
		//commands=command.split(",");
		this.command=command;
		if( GLib.Regex.match_simple("^ *ssh *(,.*)?$",this.command,RegexCompileFlags.CASELESS,0) )
			this.type="ssh";
		else
			this.type="unknown";
		debug("TildaAuth this.type=%s",this.type);
	}
}//class TildaAuth

public class VTToggleButton : Gtk.ToggleButton {
	public bool really_toggling {get;set;default = false;}
	public Gtk.Label label;
	public unowned Object object;
	public string tab_format  {get;set;}
	public string tab_title_format  {get;set;}
	public string host_name {get;set;default = null;}

	private string tab_title {get;set;default = null;}
	private int    tab_index {get;set;default = -1;}
	public string markup_normal  {get;set;}
	public string markup_active  {get;set;}
	public string markup_prelight  {get;set;}

	//private string label_text;

	public VTToggleButton() {
		Object();
	}
	/*public VTToggleButton.with_label (string label) {
		this.label_text = label;
		Object();
	}*/

	construct {
		this.label = new Gtk.Label(null);
		this.label.use_underline=false;
		this.label.show();
		this.add(this.label);
		this.inconsistent=true;//prevent 2px shift
		this.draw_indicator=false;
		this.label.mnemonic_widget=null;
	}

	public override void toggled () {
		debug ("toggled = %s , %s ",this.really_toggling.to_string(),this.label.get_text());
		this.active=this.really_toggling;
		if(this.active)
			this.label.set_markup(this.markup_active);
		else
			this.label.set_markup(this.markup_normal);
	}

//~ 	public  bool draw22 (Cairo.Context cr){

 	public override  bool draw (Cairo.Context cr){

		//base.draw(cr);
		int width = this.get_allocated_width ();
		int height = this.get_allocated_height ();
		cr.save();
		/*var context = this.get_style_context();
		var BORDER_WIDTH = 3;
		cr.save();
		//cr.translate (-3, -2);//actual move in context
		if ( (this.get_state_flags() & Gtk.StateFlags.ACTIVE) == Gtk.StateFlags.ACTIVE ){
			var color = context.get_background_color(StateFlags.ACTIVE);
			//cr.set_source_rgba (color.red,color.green,color.blue,color.alpha);//background
			//cr.set_source_rgba (1.0 , 0.0, 0.0, 1.0);
			//render_background(context,cr, 0, 0, width, height);
			//render_extension(context,cr, 0, 0, width, height,PositionType.TOP);
			var p = new Cairo.Pattern.linear(0,0,0,height);
			p.add_color_stop_rgba (0.0, 0, 0, 0, 1.0);
			p.add_color_stop_rgba (1.0, color.red, color.green, color.blue, 1.0);
			//cr.set_source (p);
			cr.set_source_rgba (color.red,color.green,color.blue,color.alpha);//background
			cr.rectangle (BORDER_WIDTH, BORDER_WIDTH,
                         width - 2 * BORDER_WIDTH,
                         height - 2 * BORDER_WIDTH);
			cr.fill ();
			cr.stroke ();
		}
		//render_background(context,cr, -2, -2, width+3, height+3);
		//render_frame (context, cr, 0, 0, width+1, height+1);

		//cr.stroke ();
		*/
		//draw small devision line
		cr.set_source_rgb (0.6, 0.6, 0.6);
		cr.set_line_width (2.0);
		cr.set_line_join (Cairo.LineJoin.ROUND);
		cr.move_to(width,4);
		cr.line_to(width, height-4);
		cr.stroke ();
		cr.restore();

		/*Pango.Layout layout = this.label.get_layout();//Pango.cairo_create_layout(cr);//create_pango_layout (this.label);
          // And draw the text in the middle of the allocated space
		int fontw, fonth;
		layout.get_pixel_size (out fontw, out fonth);
		cr.move_to ((width - fontw) / 2,
				   (height - fonth) / 2);
		Pango.cairo_update_layout (cr, layout);
		Pango.cairo_show_layout (cr, layout);
		cr.stroke ();*/
		this.propagate_draw(((Gtk.Widget)this.get_child ()),cr);

		//this.label.draw(cr);
		//base.draw(cr);
	return false;
	}

	public override bool enter_notify_event (Gdk.EventCrossing event) {
		if( event.type == Gdk.EventType.ENTER_NOTIFY)
			this.label.set_markup(this.markup_prelight);
		return false;
	}
	public override bool leave_notify_event (Gdk.EventCrossing event) {
		if(event.type == Gdk.EventType.LEAVE_NOTIFY){
			if(this.active)
				this.label.set_markup(this.markup_active);
			else
				this.label.set_markup(this.markup_normal);
		}
		return false;
	}

	private bool RegexEvalCallback (MatchInfo match_info, StringBuilder result){
		debug(" RegexEvalCallback %s %s",result.str,match_info.fetch(0));
		result.append("<span font_weight='bold'>");
		result.append(match_info.fetch(0));
		result.append("</span>");
		host_name=match_info.fetch(0);
		return false;
	}

	public void set_title(int tab_index,string? title){
		debug("set_title(%d,%s)",tab_index,title);
		if(title!=null && title!="")
			this.tab_title = title;
		this.tab_index = tab_index;
		string result="";
		if((this.tab_title!=null && this.tab_title!="") ){
			try{
				var grx_host = new GLib.Regex("([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+)");
				var reg_title=grx_host.replace_eval(this.tab_title,(ssize_t) this.tab_title.size(), 0,0, this.RegexEvalCallback );

				var grx_index = new GLib.Regex(GLib.Regex.escape_string("_INDEX_"));
				var grx_title = new GLib.Regex(GLib.Regex.escape_string("_TITLE_"));
                result = grx_index.replace_literal(this.tab_title_format,(ssize_t) this.tab_title_format.size(), 0, tab_index.to_string() );
                result = grx_title.replace_literal(result,(ssize_t) result.size(), 0, reg_title);
			}catch(GLib.RegexError e){
				this.label.set_markup("TAB: Error in regexp");
			}
		}else{
			try{
				var grx_index = new GLib.Regex(GLib.Regex.escape_string("_INDEX_"));
                result = grx_index.replace_literal(this.tab_format,(ssize_t) this.tab_title_format.size(), 0, tab_index.to_string() );

			}catch(GLib.RegexError e){
				this.label.set_markup("TAB: Error in regexp");
			}
		}
		var context = this.get_style_context();
        Gdk.RGBA color_f = context.get_color(StateFlags.NORMAL);
        Gdk.RGBA color_b = context.get_background_color(StateFlags.NORMAL);
		this.markup_normal="<span foreground='#"+"%I02x".printf(((int)(color_f.red*255)))+"%I02x".printf(((int)(color_f.green*255)))+"%I02x".printf(((int)(color_f.blue*255)))+"' "+
		"background='#"+"%I02x".printf(((int)(color_b.red*255)))+"%I02x".printf(((int)(color_b.green*255)))+"%I02x".printf(((int)(color_b.blue*255)))+"' "+
		">"+result+"</span>";
		//this.label.set_markup(this.markup_normal);

		//var grx_prelight = new GLib.Regex(GLib.Regex.escape_string("foreground"));
		//result = grx_prelight.replace_literal(result,(ssize_t) result.size(), 0, "background" );
        color_f = context.get_color(StateFlags.ACTIVE);
        color_b = context.get_background_color(StateFlags.ACTIVE);
		this.markup_active="<span foreground='#"+"%I02x".printf(((int)(color_f.red*255)))+"%I02x".printf(((int)(color_f.green*255)))+"%I02x".printf(((int)(color_f.blue*255)))+"' "+
		"background='#"+"%I02x".printf(((int)(color_b.red*255)))+"%I02x".printf(((int)(color_b.green*255)))+"%I02x".printf(((int)(color_b.blue*255)))+"' "+
		">"+result+"</span>";

        color_f = context.get_color(StateFlags.PRELIGHT);
        color_b = context.get_background_color(StateFlags.PRELIGHT);
		this.markup_prelight="<span foreground='#"+"%I02x".printf(((int)(color_f.red*255)))+"%I02x".printf(((int)(color_f.green*255)))+"%I02x".printf(((int)(color_f.blue*255)))+"' "+
		"background='#"+"%I02x".printf(((int)(color_b.red*255)))+"%I02x".printf(((int)(color_b.green*255)))+"%I02x".printf(((int)(color_b.blue*255)))+"' "+
		">"+result+"</span>";
		//this.markup_prelight = result;//"<i>"+result+"</i>";

		if(this.active)
			this.label.set_markup(this.markup_active);
		else
			this.label.set_markup(this.markup_normal);

		this.label.show();
	}
}//private class VTToggleButton

public class VTTerminal : Object{
	public Vte.Terminal vte_term {get; set; default = null;}
	public HBox hbox {get; set; default = null;}
	public Scrollbar scrollbar {get; set; default = null;}
	public VTToggleButton tbutton {get; set; default = null;}
	public int page_index {get; set; default = -1;}
	public Pid pid {get; set; default = -1;}
	public bool auto_restart {get; set; default = true;}
	public bool match_case {get; set; default = false;}
	private Notebook notebook {get; set; default = null;}
	private unowned MySettings my_conf {get; set; default = null;}
	private OnChildExitCallBack on_child_exit {get; set; default = null;}


	public VTTerminal(MySettings my_conf,Notebook notebook, int tab_index,string? session_command=null,OnChildExitCallBack? on_child_exit=null) {
		this.my_conf=my_conf;
		this.notebook=notebook;
		if(on_child_exit!=null)
			this.on_child_exit=on_child_exit;
		this.tbutton = new VTToggleButton();
		this.tbutton.tab_format = my_conf.get_string("tab_format","[ _INDEX_ ]");
		this.tbutton.tab_title_format = my_conf.get_string("tab_title_format","[_INDEX_: _TITLE_ ]");
		this.tbutton.set_title(tab_index,null);
		this.tbutton.can_focus=false;//vte shoud have focus
		this.tbutton.can_default = false; //encrease size
		this.tbutton.has_focus = false; //encrease size
		this.tbutton.set_use_underline(false);
		this.tbutton.set_focus_on_click(false);
		this.tbutton.set_relief(ReliefStyle.NONE); //подумать как улучшить вид
		this.tbutton.set_has_window (false);
		this.tbutton.show();

		this.hbox = new HBox(false, 0);


		this.vte_term = new Vte.Terminal();
		/*this.vte_term.size_allocate.connect((allocation)=>{
			debug("[screen %p] size-alloc   %d : %d at (%d, %d)\n",
                         this.vte_term, allocation.width, allocation.height, allocation.x, allocation.y);
			});*/

		/*this.vte_term.size_request.connect((req)=>{
			debug("[window %p] size-request result %d : %d\n",
                         this.vte_term, req.width, req.height);
			});*/




		if(!this.start_command(session_command)){
			if(!this.start_command()){//try without session
				this.my_conf.set_string("custom_command","");
				if(!this.start_command()){//try without custom_command
					debug("Unable to run shell command!");
					Gtk.main_quit();
					}
			}
		}
		this.vte_term.child_exited.connect(this.child_exited);

		this.hbox.pack_start(this.vte_term,true,true,0);
		//this.vte_term.grab_focus();
		//this.vte_term.can_default=true;
		this.hbox.show();
		this.vte_term.show();
		this.scrollbar = new VScrollbar(((Scrollable)this.vte_term).get_vadjustment());
		this.scrollbar.show () ;
		hbox.pack_start(scrollbar,false,false,0);
		page_index = this.notebook.prepend_page (hbox,null);

		this.tbutton.object = this;

		this.vte_term.search_set_wrap_around(my_conf.get_boolean("search_wrap_around",true));
		this.match_case =my_conf.get_boolean("search_match_case",this.match_case);
		this.my_conf.on_load.connect(()=>{
			this.configure(this.my_conf);
			});
	}

	public void destroy() {
		this.vte_term.child_exited.disconnect(this.child_exited);
		this.hbox.hide();
		this.notebook.remove_page(this.notebook.page_num(this.hbox));
		//this.tbutton.label.destroy();
		//this.tbutton.destroy();
		//this.vte_term.destroy();
		this.hbox.destroy();//destroy all widgets and unref self
	}

	public bool start_command(string? session_command = null){
		string? command = this.my_conf.get_string("custom_command","");

		if(command == null || command == "")
			command = GLib.Environment.get_variable ("SHELL");

		if(command==null)
			command = "/bin/sh";

		if(session_command!=null && session_command != "" && command!=session_command)
			command=session_command;
			//command+=" -c \""+session_command+"; "+command+"\"";

		debug("run command:%s",command);

		string[] argvp;
		if(!GLib.Shell.parse_argv(command,out argvp))
			error("Error: Shell not found!"); //todo gui err

		PtyFlags pty_flags = PtyFlags.DEFAULT;

		var path = GLib.Environment.get_current_dir();
		if(path==null)
			path="/";

		GLib.SpawnFlags sflags = GLib.SpawnFlags.SEARCH_PATH;
		/*(Vte.PtyFlags pty_flags,
		 *  string? working_directory,
		 *  string[] argv,
		 *  string[]? envv,
		 *  GLib.SpawnFlags spawn_flags,
		 *  GLib.SpawnChildSetupFunc? child_setup,
		 *  out GLib.Pid child_pid)*/
		Pid p;
		var ret = this.vte_term.fork_command_full(pty_flags ,path,argvp,argvp,sflags,null,out p);
		this.pid=p;
		return ret;
	}

	public void child_exited(){
		if(this.auto_restart){
			if(!this.start_command()){//try without session
				this.my_conf.set_string("custom_command","");
				if(!this.start_command()){//try without custom_command
					debug("Unable to run shell command!");
					Gtk.main_quit();
					}
			}
		}
 		else if(this.on_child_exit!=null)
 			this.on_child_exit(this);
	}

	public void configure(MySettings my_conf){
		uint path_length=0;
		string spath = "";
		string spath_reversed = "";

//~ 		StyleContext style = this.tbutton.get_style_context ();//new StyleContext ();//
//~ 		var css = new CssProvider ();

//	"HVBox {border-radius: 0 0 4 4; background-image: none; margin:0; padding:0 ; border-width: 0 ;}"+
//	"VTToggleButton:active {-border-gradient: none; -outer-inner-width: 0; -outer-stroke-width: 0; background-image: none;  margin:0; padding:5; background-color: @bg_color; border-color: #00DD00; border-width: 0 0 0 0;}"+
//	"* {color: #0000FF; border-radius: 0 0 4 4; background-image: none; margin:0; padding:0 ; border-width: 0 ;}"+
//font:Ubuntu Mono 10;
//~ 		string style_str="VTToggleButton {font: \"Ubuntu Mono 8\"; -GtkWidget-focus-padding: 0px;  -GtkButton-default-border:0px; -GtkButton-default-outside-border:0px; -GtkButton-inner-border:0px; border-width: 0px 0px 0px 0px; -outer-stroke-width: 0px; border-radius: 0px 0px 0px 0px; border-style: solid;  background-image: none; margin:0px; padding:0px 3px 3px 3px; background-color: #000000; color: #AAAAAA; transition: 0ms ease-in-out;}"+
//~ 					 "VTToggleButton:active {font: \"Ubuntu Mono 8\"; -GtkWidget-focus-padding: 0px;  -GtkButton-default-border:0px; -GtkButton-default-outside-border:0px; -GtkButton-inner-border:0px; border-width: 0px 0px 0px 0px; -outer-stroke-width: 0px; border-radius: 0px 0px 0px 0px; border-style: solid;  background-image: none; margin:0px; padding:0px 3px 3px 3px; background-color: #00AAAA; color: #000000; transition: 0ms ease-in-out;}"+
//~ 					 "VTToggleButton:prelight {font: \"Ubuntu Mono 8\"; -GtkWidget-focus-padding: 0px;  -GtkButton-default-border:0px; -GtkButton-default-outside-border:0px; -GtkButton-inner-border:0px; border-width: 0px 0px 0px 0px; -outer-stroke-width: 0px; border-radius: 0px 0px 0px 0px; border-style: solid;  background-image: none; margin:0px; padding:0px 3px 3px 3px; background-color: #AAAAAA; color: #000000; transition: 0ms ease-in-out;}"+
//~ 					 "";
//~ 		css.load_from_data (this.my_conf.get_string("tbutton_style",style_str),-1);
/*
 ".background {"+
    "background-color: #FF0000;"+
"    border-width: 0;margin:0; padding:0; "+
"}"+
"VTToggleButton.button { background-image: none; "+
"border-radius: 0 0 4 4; border-width: 0;"+
"color: #FF0000;  font: bold; text-shadow: 0 2 alpha (shade (@selected_fg_color, 1.26), 0.7);"+
"background-color: @selected_bg_color; border-color: @selected_bg_color;"+
"-outer-stroke-width: 0; -inner-stroke-width: 0;"+
""+
"margin:0; padding:4; }"+
"VTToggleButton:active{margin:0; padding:0; background-color: @bg_color;}"+
"VTToggleButton:active:hover{background-color: #00FF00;}"+

*/
		//style.remove_class ("*");

		//style.add_class("GtkToolbarButton");

		//style.add_provider(css,900);

		//var wpath = new WidgetPath();
		//wpath.append_type(typeof(Gtk.Window));
		//wpath.append_type(typeof(Gtk.MenuItem));
		//wpath.iter_add_region (0, "tab", RegionFlags.FIRST|RegionFlags.EVEN) ;
		//style.set_path(wpath);
		//tbutton.reset_style();//set_style(style);

		//this.tbutton.path(out path_length,out spath,out spath_reversed);
		//debug("\t tbutton.path=%s",spath);
		//new Pango.FontDescription();

		Pango.FontDescription font_description = Pango.FontDescription.from_string (my_conf.get_string("terminal_font","Mono 12")) ;

		this.vte_term.set_font(font_description);//same color for terminal

		
		//debian patch vte_terminal_set_alternate_screen_scroll
		this.vte_term.set_alternate_screen_scroll(my_conf.get_boolean("terminal_set_alternate_screen_scroll",true));

		this.vte_term.set_scrollback_lines (my_conf.get_integer("terminal_scrollback_lines",512));

		unowned Gdk.Color? fg;
		unowned Gdk.Color? bg;
		if(!Gdk.Color.parse(my_conf.get_string("terminal_color_fg","#00FFAA"),out fg))
			fg = null;//use color from pallete
		if(!Gdk.Color.parse(my_conf.get_string("terminal_color_bg",""),out bg))
			bg = null;//use color from pallete

		//default color palette - "Linux", in term of gnome-terminal
		Gdk.Color[] palette=  new Gdk.Color[16];
		palette=  {
				Gdk.Color(){ pixel=0, red=0x0000, green=0x0000, blue=0x0000 },
				Gdk.Color(){ pixel=0, red=0xaaaa, green=0x0000, blue=0x0000 },
				Gdk.Color(){ pixel=0, red=0x0000, green=0xaaaa, blue=0x0000 },
				Gdk.Color(){ pixel=0, red=0xaaaa, green=0x5555, blue=0x0000 },
				Gdk.Color(){ pixel=0, red=0x0000, green=0x0000, blue=0xaaaa },
				Gdk.Color(){ pixel=0, red=0xaaaa, green=0x0000, blue=0xaaaa },
				Gdk.Color(){ pixel=0, red=0x0000, green=0xaaaa, blue=0xaaaa },
				Gdk.Color(){ pixel=0, red=0xaaaa, green=0xaaaa, blue=0xaaaa },
				Gdk.Color(){ pixel=0, red=0x5555, green=0x5555, blue=0x5555 },
				Gdk.Color(){ pixel=0, red=0xffff, green=0x5555, blue=0x5555 },
				Gdk.Color(){ pixel=0, red=0x5555, green=0xffff, blue=0x5555 },
				Gdk.Color(){ pixel=0, red=0xffff, green=0xffff, blue=0x5555 },
				Gdk.Color(){ pixel=0, red=0x5555, green=0x5555, blue=0xffff },
				Gdk.Color(){ pixel=0, red=0xffff, green=0x5555, blue=0xffff },
				Gdk.Color(){ pixel=0, red=0x5555, green=0xffff, blue=0xffff },
				Gdk.Color(){ pixel=0, red=0xffff, green=0xffff, blue=0xffff }
				};

		string[] palette_s = new string [16];
		var i = 0;
		foreach(var c in palette){
			palette_s[i] = c.to_string();
			i++;
		}

		string[] palette_s_conf = my_conf.get_string_list("terminal_palette",palette_s);
		i = 0;
		if(palette_s_conf != null && palette_s_conf.length==16)//todo: make different sizes
		foreach(var s in palette_s_conf){
			 Gdk.Color.parse(s,out palette[i]);
			i++;
		}

		this.vte_term.set_colors(fg,bg,palette);

		var bg_img_file = my_conf.get_string("terminal_background_image_file","");
		if(bg_img_file!=null && bg_img_file!="" && GLib.FileUtils.test(bg_img_file,GLib.FileTest.EXISTS)){
			message("set_background_image_file=%s",bg_img_file);
			this.vte_term.set_background_image_file (bg_img_file);
			var sat = my_conf.get_double("terminal_background_saturation",0.5);
			if(sat>1) sat=1; if(sat<0) sat=0;
			this.vte_term.set_background_saturation (sat);
		}

		/*Gdk.RGBA c = Gdk.RGBA();
		c.parse(my_conf.get_string("tab_button_color_normal","#00FF00"));
		//this.tbutton.override_color(StateFlags.NORMAL , c);
		this.tbutton.label.override_color(StateFlags.NORMAL , c);
		c.parse(my_conf.get_string("tab_button_color_prelight","#FFFF00"));
		this.tbutton.label.override_color(StateFlags.PRELIGHT , c);
		c.parse(my_conf.get_string("tab_button_color_active","#FFFF00"));
		this.tbutton.label.override_color(StateFlags.ACTIVE , c);*/

		this.vte_term.button_press_event.connect(vte_button_press_event);

	}

	public bool vte_button_press_event(Widget widget,Gdk.EventButton event) {
		if(event.type==Gdk.EventType.BUTTON_PRESS){
			if(event.button== 3){//right mouse button
				this.popup_menu(event);
				return true;
			}
		}
		return false; //true == ignore event
	}

	public void popup_menu(Gdk.EventButton event){
		//debug("terminal popup_menu");
		var menu = new Gtk.Menu();
		//debug("popup_menu ref_count=%d",(int)menu.ref_count);
		unowned Gtk.Widget parent;
			parent = this.vte_term;
			while(parent.parent!=null ){parent = parent.parent;} //find VTMainWindow
		VTMainWindow vtw=(VTMainWindow)parent;
		menu.set_accel_group(vtw.accel_group);
		Gtk.ActionGroup acg=vtw.action_group;

		Gtk.MenuItem menuitem;

		menuitem = (Gtk.MenuItem)acg.get_action("terminal_copy_text").create_menu_item();
		menu.append(menuitem);
		menuitem = (Gtk.MenuItem)acg.get_action("terminal_paste_text").create_menu_item();
		menu.append(menuitem);

		menuitem = new Gtk.SeparatorMenuItem();
		menu.append(menuitem);

		menuitem = (Gtk.MenuItem)acg.get_action("terminal_add_tab").create_menu_item();
		menu.append(menuitem);
		menuitem = (Gtk.MenuItem)acg.get_action("terminal_close_tab").create_menu_item();
		menu.append(menuitem);
		menuitem = (Gtk.MenuItem)acg.get_action("terminal_search_dialog").create_menu_item();
		menu.append(menuitem);
		menuitem = (Gtk.MenuItem)acg.get_action("open_settings").create_menu_item();
		menu.append(menuitem);
		menuitem = (Gtk.MenuItem)acg.get_action("follow_the_mouse").create_menu_item();
		menu.append(menuitem);
		menuitem = (Gtk.MenuItem)acg.get_action("altyo_help").create_menu_item();
		menu.append(menuitem);

		menuitem = new Gtk.SeparatorMenuItem();
		menu.append(menuitem);

		menuitem = (Gtk.MenuItem)acg.get_action("main_hotkey").create_menu_item();
		menu.append(menuitem);
		menuitem = (Gtk.MenuItem)acg.get_action("altyo_exit").create_menu_item();
		menu.append(menuitem);

		menu.deactivate.connect (this.on_deactivate);
        //menu.attach_to_widget (this.vte_term, null);
		menu.popup(null, null, null, event.button, event.time);
		menu.show_all();
		menu.ref();//no one own menu,emulate owners,uref will be on_deactivate
		//debug("popup_menu ref_count=%d",(int)menu.ref_count);
	}

	private void on_deactivate(Widget m) {
			((Gtk.Menu)m).deactivate.disconnect(on_deactivate);
			m.unref();//menu will be destroyed after end of deactivate event
			//debug("popup_menu ref_count=%d",(int)m.ref_count);//normal count 4
		}

	private string find_other_pgrp(int pid){
	GLib.Dir dir = GLib.Dir.open("/proc/");
	unowned string filename;
	/* scan whole proc, for another last-child
	 * there is no other way to do that, ps do the same
	 * * * * * * * * * * * * * * * * * * * * * * * * */
		while ( (filename = dir.read_name())!=null  )
		if(int.parse(filename)>0){  //is it pid number? =)

			var parent_stat = "/proc/"+filename+"/stat";

			if(GLib.FileUtils.test(parent_stat,GLib.FileTest.EXISTS) ){
				string contents = "";
				size_t length = -1;
				if(GLib.FileUtils.get_contents (parent_stat,out contents,out length) ){
					//<  skip    > [ 0 ] [ 1 ] [ 2 ] [ 3 ] [ 4 ] < skip  ... >
					//31266 (mc) S 31253 31266 31253 34817 31266 4202496 ...
					contents=contents.substring(contents.last_index_of(")")+4,-1);
					var stat_cont=contents.split(" ");
					//debug("pid=%d parse=%d stat_cont0=%s",pid,int.parse(stat_cont[1]),stat_cont[0]);
					//we found another last child, probably from subshell
					if(pid==int.parse(stat_cont[0]) ){
						return "/proc/"+stat_cont[4]+"/cmdline";
					}
				}
			}
		}
	return "";
	}

	public string find_tty_pgrp(int pid){
		//for more info look at kernel/Documentation/filesystems/proc.txt
		var parent_stat = "/proc/"+((int)pid).to_string()+"/stat";

		if(GLib.FileUtils.test(parent_stat,GLib.FileTest.EXISTS) ){
			string contents = "";
			size_t length = -1;
			if(GLib.FileUtils.get_contents (parent_stat,out contents,out length) ){
				contents=contents.substring(contents.last_index_of(")")+4,-1);
				var stat_cont=contents.split(" ");
				var tty_pgrp = "/proc/"+stat_cont[4]+"/cmdline";

				var other=find_other_pgrp(int.parse(stat_cont[4]));
				if(other!=null && other!="")	tty_pgrp=other;
				//debug("find_others_pgrp=%s",other);
				if(GLib.FileUtils.test(tty_pgrp,GLib.FileTest.EXISTS) ){
					uint8[] data;
					if(GLib.FileUtils.get_data(tty_pgrp,out data) ){
						for(var i=0;i<data.length-1;i++){
							if(data[i]==0)
								data[i]=' ';
							}
					}
						return (string)data;
				}
			}
		}
		return "";
	}

	public delegate void expect_callback();

	public void expect_and_paste(string expect_string,string paste,owned expect_callback cb){
		var count=10;
		GLib.Timeout.add(500,()=>{
				long column, row;
				this.vte_term.get_cursor_position(out column,out row);
				string vte_text=this.vte_term.get_text_range(row,0,row,column,null,null);
				//Password:
				vte_text=vte_text.strip();
				debug("expect=%s get '%s'",expect_string,vte_text);
				if(GLib.Regex.match_simple(".*"+expect_string+".*",vte_text,RegexCompileFlags.CASELESS,0)){
					this.vte_term.feed_child(paste,paste.length);
					if(cb!=null) cb();
					return false;
				}else
				if(count>0){
						count--;
						return true;
					}else
						return false;
			});
	}

	private string parse_port(ref string host_name){
		string port="";
		if(host_name!=null && host_name.contains(":")){
			port=host_name.substring(host_name.index_of_char(':',1)+1,host_name.length-1);
			if(int.parse(port)<=0){//is it number?
				port="";//port is not number
				error("port parse problem");
			}else{
				host_name=host_name.substring(0,host_name.index_of_char(':',1)-1);
			}
		}
	return port;
	}

	public void try_run_command(owned TildaAuth tauth){
	#if HAVE_QLIST
	if(tauth.password=="!"){
		debug("find_network_password");
		//GnomeKeyring.is_available()
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
		unowned Gtk.Widget parent;
		parent = this.vte_term;
		while(parent.parent!=null ){parent = parent.parent;} //find VTMainWindow
		VTMainWindow vtw=(VTMainWindow)parent;
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
		var res=GnomeKeyring.set_default_keyring_sync (vtw.conf.get_string("terminal_default_keyring","altyo"));
		if(res!=Result.OK)
			debug("GnomeKeyring.set_default_keyring_sync error");
		else{
			unowned Info info=null;
			GnomeKeyring.get_info_sync (vtw.conf.get_string("terminal_default_keyring","altyo"), out info) ;
			if(info!=null){
				debug("Update keyring info...");
				info.set_lock_timeout(60*3);//lock after 3 min
				info.set_lock_on_idle(true);
				GnomeKeyring.set_info_sync (vtw.conf.get_string("terminal_default_keyring","altyo"), info) ;
				}

			GnomeKeyring.find_network_password (tauth.user, null, tauth.host, null, tauth.type, "auth", 0, (result, list)=>{

				debug("find_network_password done=%d",result);
				if (result == Result.OK && list.length () > 0) {
					weak NetworkPasswordData npd = (NetworkPasswordData) list.first().data;
					if (npd.authtype == "auth") {
						tauth.password=npd.password;
						this.run_command(tauth);
					}
				}else{
					var dialog = new MessageDialog (null, (DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL), MessageType.QUESTION, ButtonsType.OK_CANCEL, "Password not foud!\n create new one?");
					var ent=new Entry();
					ent.invisible_char='~';
					ent.invisible_char_set=true;
					ent.visibility=false;
					ent.show();
					var dialog_box = ((Gtk.Box)dialog.get_content_area ());
					dialog_box.pack_start(ent,false,false,0);
					uint32 item_id=0;
					dialog.response.connect ((response_id) => {
						if(response_id == Gtk.ResponseType.OK){
							tauth.password=ent.text;
							Result r=GnomeKeyring.set_network_password_sync(null,
								tauth.user ,
								null /*string? domain*/,
								tauth.host,
								null /*string? object*/,
								tauth.type /*string? protocol*/,
								"auth" /*string? authtype*/,
								22 /*uint32 port*/,
								tauth.password /*string? password*/,
								out item_id);
							this.run_command(tauth);
							dialog.destroy ();
						}else{
							//this.window_set_active();
							dialog.destroy ();
						}
					});

					dialog.focus_out_event.connect (() => {
						return true; //same bug as discribed in this.focus_out_event
					});

					dialog.show ();
					//disable close by window manager
					Gdk.Window w = dialog.get_window();
					w.set_functions((Gdk.WMFunction.ALL|Gdk.WMFunction.CLOSE));
					dialog.grab_focus();
					dialog.set_transient_for(vtw);
					vtw.hotkey.send_net_active_window(dialog.get_window ());
					dialog.run();
					}
			});
		}//if GnomeKeyring.set_default_keyring_sync
	}else
		run_command(tauth);
	#endif
	}//try_run_command

	public void run_command(TildaAuth tauth){
		string host_name=tauth.host;
		string user_password=tauth.password;
		string user_name=tauth.user;
		string command=tauth.command;
		if(command=="ssh"){
			string port=this.parse_port(ref host_name);
			if(port!="") port=" -p "+port;
			string cmd="ssh %s@%s %s\n".printf(user_name,host_name,port);
			debug("ssh = %s",cmd);
			this.vte_term.feed_child(cmd,cmd.length);
		}else if(tauth.type=="ssh"){
			string[] commands=command.split(",");
			if(commands.length==3 && commands[0]=="ssh" && commands[1].contains("expect-user=") && commands[2].contains("expect-password=")){
				string port=this.parse_port(ref host_name);
				if(port!="") port=" -p "+port;
				string cmd="ssh %s@%s %s\n".printf(user_name,host_name,port);
				debug("ssh = %s",cmd);
				this.vte_term.feed_child(cmd,cmd.length);
				string tmp=commands[1];
				var idx=tmp.index_of_char('=',0)+1;
				string expect_name=tmp.substring(idx,tmp.length-idx);
				tmp=commands[2];
				idx=tmp.index_of_char('=',0)+1;
				string expect_password=tmp.substring(idx,tmp.length-idx);
				user_name+="\n";
				user_password+="\n";
				debug("expect_name=%s expect_password=%s",expect_name,expect_password);
				this.expect_and_paste(expect_name,user_name,()=>{
					this.expect_and_paste(expect_password,user_password,()=>{});
				});

			}else
				if(commands.length==2 && commands[0]=="ssh" && commands[1].contains("expect-password=")){
					string port=this.parse_port(ref host_name);
					if(port!="") port=" -p "+port;
					string cmd="ssh %s@%s %s\n".printf(user_name,host_name,port);
					debug("ssh = %s",cmd);
					this.vte_term.feed_child(cmd,cmd.length);
					string tmp=commands[1];
					var idx=tmp.index_of_char('=',0)+1;
					string expect_password=tmp.substring(idx,tmp.length-idx);
					user_name+="\n";
					user_password+="\n";
					debug(" expect_password=%s",expect_password);
					this.expect_and_paste(expect_password,user_password,()=>{});
				}
			else
				if(commands.length==2 && commands[0]=="ssh" && commands[1].contains("paste-password")){
					debug(" paste-password=%s",user_password);
					user_password+="\n";
					this.vte_term.feed_child(user_password,user_password.length);
				}
		}/*else if(){
		}*/
	//tauth.unref();//not needed
	}//run_command

}
