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


public enum FIND_TTY{
	CMDLINE,
	CWD,
	PID
	}

public enum VTT_LOCK_SETTING{
	ENCODING,
	DELETE_BINDING,
	BACKSPACE_BINDING
	}
	
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

public class VTToggleButton : Gtk.Button{
  	static construct {
		install_style_property (param_spec_boxed ("tab-index-color",
												   null, null,
												   typeof(Gdk.RGBA),
												   GLib.ParamFlags.READABLE));
		install_style_property (param_spec_boxed ("username-color",
												   null, null,
												   typeof(Gdk.RGBA),
												   GLib.ParamFlags.READABLE));
		install_style_property (param_spec_boxed ("hostname-color",
												   null, null,
												   typeof(Gdk.RGBA),
												   GLib.ParamFlags.READABLE));
    }
	bool _active = false;
	public bool active {get{ return _active;}
						set{
							if(this._active != value){
								this._active=value;								
								this.update_state();
							}
							//debug ("toggled = %s , %s ",this._active.to_string(),this.label.get_text());
						}
				}
	private Gtk.Label label;
	public unowned Object object;
	public string tab_format  {get;set;}
	public string tab_title_format  {get;set;}
	public string[] tab_title_regex  {get;set;}
	public string host_name {get;set;default = null;}
	public bool do_not_sort  {get;set;default = false;}
	public int  conf_max_width {get;set;default = -1;}
	public bool prevent_close=false;

	public string tab_title {get;set;default = null;}
	private string? _tab_custom_title = null;
	public string? tab_custom_title {
		get { return _tab_custom_title;}
		set{
			_tab_custom_title=value;
			this.force_update_tab_title = true;
			this.set_title(this.tab_index,null);
			this.user_notify=false;
		}
	}
	public bool tab_custom_title_enabled {
		get{ return _tab_custom_title!=null; }
	}
	public  uint    tab_index; /*tab position starting from 0*/
	private string markup_normal  {get;set;}
	private string markup_active  {get;set;}
	private string markup_prelight  {get;set;}
	public bool force_update_tab_title {get;set;default = false;}
	private bool _user_notify=false;
	public bool user_notify {
		get{
			return _user_notify;
		}
		set{
			if(value && !_user_notify && !this.active){
				var flags = this.get_state_flags();
				this.set_state_flags(Gtk.StateFlags.SELECTED,true);
				_user_notify=true;
			}else{
				if(!value){
					var flags = this.get_state_flags();
					this.set_state_flags(flags&~Gtk.StateFlags.SELECTED,true);
					_user_notify=false;
					if(this.terminal_contents_changed_timer!=0){
						GLib.Source.remove(this.terminal_contents_changed_timer);
						this.terminal_contents_changed_timer=0;//stop timer if active
					}
				}
			}
		}//set
		}
	public bool notify_on_title_change=false;
	private uint terminal_contents_changed_timer = 0;
	public uint notify_timeout = 1;

	//private string label_text;

	public VTToggleButton() {
		Object();
	}
	/*public VTToggleButton.with_label (string label) {
		this.label_text = label;
		Object();
	}*/
	~VTToggleButton() {
		debug("~VTToggleButton");
	}

	construct {
		this.label = new Gtk.Label(null);
		this.label.use_underline=false;
		this.label.show();
		this.add(this.label);
		this.label.mnemonic_widget=null;
		this.user_notify=false;
		unowned Gtk.StyleContext context = this.get_style_context();
//~ 		context.remove_class("button");//don't use default button theme
		context.add_class("aytab");
	}

	public override void state_flags_changed (StateFlags previous_state_flags) {
               var flags = this.get_state_flags();
               if(this.active && (flags & Gtk.StateFlags.ACTIVE)!=Gtk.StateFlags.ACTIVE){
                               this.set_state_flags(flags|Gtk.StateFlags.ACTIVE,false);//force state active
                               return;
               }
               base.state_flags_changed(previous_state_flags);
	}

	public override bool enter_notify_event (Gdk.EventCrossing event) {
		if( event.type == Gdk.EventType.ENTER_NOTIFY){
			this.set_state_flags(Gtk.StateFlags.PRELIGHT,true);
			this.label.set_markup(this.markup_prelight);
		}
		return true;//stop
	}
	public override bool leave_notify_event (Gdk.EventCrossing event) {
		if(event.type == Gdk.EventType.LEAVE_NOTIFY){
			this.update_state();
		}
		return true;//stop
	}

	public void update_state(){
		if(this._active){
			this.user_notify=false;
			this.set_state_flags(Gtk.StateFlags.ACTIVE,true);
			this.label.set_markup(this.markup_active);
		}else{
			this.set_state_flags((this._user_notify?Gtk.StateFlags.NORMAL|Gtk.StateFlags.SELECTED:Gtk.StateFlags.NORMAL),true);
			this.label.set_markup(this.markup_normal);
		}
	}


	public bool set_title(uint tab_index /*starting from 0*/,string? title){
		debug("set_title start");
		if( ((this.tab_title != null && this.tab_title == title && this.tab_index == tab_index )||
		   (title == null && this.tab_index == tab_index )) && this.force_update_tab_title==false )
			return false; //prevent unneccesary redraw
		debug("set_title(%u,%s)",tab_index,title);
		
		
		
		if(!this.active && 
		   this.notify_on_title_change && 
		   this.tab_title != null && 
		   this.tab_title != title && 
		   this.tab_custom_title_enabled == false && 
		   this.user_notify == false &&
		   this.tab_index == tab_index)//ignore DnD index change
			this.user_notify=true;
			
		string? new_title=null;
		
		if((title!=null && title!="") || this.force_update_tab_title)
			this.tab_title = title;
		
		this.force_update_tab_title=false;
		
		if(this.tab_custom_title_enabled)
			new_title = this.tab_custom_title;
		else
			new_title = this.tab_title;

		this.tab_index = tab_index;
		
		tab_index++;//convert index from 0 to 1
		
		string result2="";
		if((new_title!=null && new_title!="") ){
			try{
				GLib.Regex grx_arr;
				string reg_title=GLib.Markup.escape_text(new_title,-1);//replace < > with &lt; &gt;
				bool done[4]={false,false,false,false};
				for(int i=0; i<this.tab_title_regex.length-1;i+=2){
					grx_arr = new GLib.Regex(this.tab_title_regex[i]);

					reg_title=grx_arr.replace_eval(reg_title,(ssize_t) reg_title.size(),0,0, (match_info, result)=>{
							debug(" RegexEvalCallback %s %s %d",result.str,match_info.fetch(0),match_info.get_match_count());
							GLib.Regex grx;

							if(!done[0] && Regex.match_simple(".*_REPLACE_.*",this.tab_title_regex[i+1])){
								//done[0]=true;//replace is allowed repeatedly
								grx = new GLib.Regex(GLib.Regex.escape_string("_REPLACE_"));
								result.append(grx.replace_literal(this.tab_title_regex[i+1],-1, 0, match_info.fetch(match_info.get_match_count()-1)) );
								return true;//stop
							}else
							if(!done[1] && Regex.match_simple(".*_USER_.*",this.tab_title_regex[i+1])){
								done[1]=true;
								grx = new GLib.Regex(GLib.Regex.escape_string("_USER_"));
								result.append(grx.replace_literal(this.tab_title_regex[i+1],-1, 0, match_info.fetch(match_info.get_match_count()-1)) );
								return true;//stop
							}else
							if(!done[2] && Regex.match_simple(".*_HOSTNAME_.*",this.tab_title_regex[i+1])){
								done[2]=true;
								grx = new GLib.Regex(GLib.Regex.escape_string("_HOSTNAME_"));
								result.append(grx.replace_literal(this.tab_title_regex[i+1],-1, 0, match_info.fetch(match_info.get_match_count()-1)) );
								this.host_name=match_info.fetch(match_info.get_match_count()-1);
								return true;//stop
							}else
							if(!done[3] && Regex.match_simple(".*_PATH_.*",this.tab_title_regex[i+1])){
								done[3]=true;
								grx = new GLib.Regex(GLib.Regex.escape_string("_PATH_"));
								result.append(grx.replace_literal(this.tab_title_regex[i+1],-1, 0, match_info.fetch(match_info.get_match_count()-1)) );
								return true;//stop
							}
							return false;//continue
						} );
					//g_free(grx_arr);
				}

				var grx_index = new GLib.Regex(GLib.Regex.escape_string("_INDEX_"));
				var grx_title = new GLib.Regex(GLib.Regex.escape_string("_TITLE_"));
                result2 = grx_index.replace_literal(this.tab_title_format,-1, 0, tab_index.to_string() );
                result2 = grx_title.replace_literal(result2,(ssize_t) result2.size(), 0, reg_title);
			}catch(GLib.RegexError e){
				this.label.set_markup("TAB: Error in regexp");
			}
		}else{
			try{
				var grx_index = new GLib.Regex(GLib.Regex.escape_string("_INDEX_"));
                result2 = grx_index.replace_literal(this.tab_format,-1, 0, tab_index.to_string() );

			}catch(GLib.RegexError e){
				this.label.set_markup("TAB: Error in regexp");
			}
		}
		
		unowned Gtk.StyleContext context = this.get_style_context(); //todo: use this.label instead
		context.invalidate();//fix wrong colors
		
        Gdk.RGBA color_f = context.get_color(StateFlags.NORMAL);
        Gdk.RGBA color_b = context.get_background_color(StateFlags.NORMAL);
		this.markup_normal=replace_color_in_markup(this,(this.prevent_close ? "[!] " : "")+"<span foreground='"+hexRGBA(color_f)+"' "+
		/*"background='#"+"%I02x".printf(((int)(color_b.red*255)))+"%I02x".printf(((int)(color_b.green*255)))+"%I02x".printf(((int)(color_b.blue*255)))+"' "+*/
		">"+result2+"</span>");
		//this.label.set_markup(this.markup_normal);
		this.tooltip_markup=this.markup_normal;
		//var grx_prelight = new GLib.Regex(GLib.Regex.escape_string("foreground"));
		//result = grx_prelight.replace_literal(result,(ssize_t) result.size(), 0, "background" );
        color_f = context.get_color(StateFlags.ACTIVE);
        color_b = context.get_background_color(StateFlags.ACTIVE);
		this.markup_active=replace_color_in_markup(this,(this.prevent_close ? "[!] " : "")+"<span foreground='"+hexRGBA(color_f)+"' "+
		/*"background='#"+"%I02x".printf(((int)(color_b.red*255)))+"%I02x".printf(((int)(color_b.green*255)))+"%I02x".printf(((int)(color_b.blue*255)))+"' "+*/
		">"+result2+"</span>",StateFlags.ACTIVE);

        color_f = context.get_color(StateFlags.PRELIGHT);
        color_b = context.get_background_color(StateFlags.PRELIGHT);
		this.markup_prelight=replace_color_in_markup(this,(this.prevent_close ? "[!] " : "")+"<span foreground='"+hexRGBA(color_f)+"' "+
		/*"background='#"+"%I02x".printf(((int)(color_b.red*255)))+"%I02x".printf(((int)(color_b.green*255)))+"%I02x".printf(((int)(color_b.blue*255)))+"' "+*/
		">"+result2+"</span>",StateFlags.PRELIGHT);
		//this.markup_prelight = result;//"<i>"+result+"</i>";

		if(this.active)
			this.label.set_markup(this.markup_active);
		else
			this.label.set_markup(this.markup_normal);

		return true;
	}

	public override void get_preferred_width (out int minimum_width, out int natural_width) {
		int max_width=-1;
		/* if label ellipsized, then normal size will be in natural_width
		 * but because we use this.width_request as maximum width,
		 * natural_width will be equal to width_request
		 * */
		base.get_preferred_width (out minimum_width, out natural_width);

		//set limit if configured
		if(this.conf_max_width>0)
			max_width=this.conf_max_width;
		//use this.width_request as limiting size from hvbox
		if( (this.width_request>0 &&
			 this.conf_max_width>0 &&
			 this.width_request<this.conf_max_width ) ||
			(this.width_request>0 && this.conf_max_width<1) ){
				max_width=this.width_request;
		}
		//debug("VTToggleButton1 max_width=%d minimum_width=%d,natural_width=%d ele=%d width_request=%d",max_width,minimum_width,natural_width,this.label.ellipsize,this.width_request);
		/*limit width if necessary*/
		if(max_width>0 && natural_width>max_width){
			if(this.label.ellipsize != Pango.EllipsizeMode.MIDDLE)
				this.label.ellipsize = Pango.EllipsizeMode.MIDDLE;//limit label size,queue resize (hardcoded in label)
			natural_width=minimum_width=max_width;//return limited size
			this.has_tooltip=true;
		}else{
			if(this.label.ellipsize != Pango.EllipsizeMode.NONE)
				this.label.ellipsize = Pango.EllipsizeMode.NONE;//reset limit,queue resize (hardcoded in label)
			minimum_width = natural_width;
			this.has_tooltip=false;
			if(this.width_request>0)
				this.width_request=-1;//reset it if size is ok
		}
		//debug("VTToggleButton2 max_width=%d minimum_width=%d,natural_width=%d ele=%d width_request=%d",max_width,minimum_width,natural_width,this.label.ellipsize,this.width_request);
	}

	public override void get_preferred_height (out int minimum_height, out int natural_height) {
		var tmp = this.label.ellipsize;
		this.label.ellipsize = Pango.EllipsizeMode.NONE;
		base.get_preferred_height (out minimum_height, out natural_height);
		this.label.ellipsize = tmp;
	}

	public void reconfigure(){
		unowned Gtk.StyleContext context = this.get_style_context();
		context.invalidate();		
		this.force_update_tab_title=true;
		this.set_title(this.tab_index,this.tab_title);//force update title
	}

	public void check_for_notify(){
		if(!this.active && !this.user_notify){
			debug("terminal_contents_changed");
			if(this.terminal_contents_changed_timer!=0)
				GLib.Source.remove(this.terminal_contents_changed_timer);
			this.terminal_contents_changed_timer=GLib.Timeout.add_seconds(this.notify_timeout,this.on_terminal_contents_changed_timeout);
		}		
	}
	
	public bool on_terminal_contents_changed_timeout(){
		debug("on_terminal_contents_changed_timeout");
		if(this.terminal_contents_changed_timer!=0){
			this.terminal_contents_changed_timer=0;
			this.user_notify=true;
		}
		return false;//stop timer
	}
}//private class VTToggleButton

public class AYTab : Object{
	public HBox hbox;
	public Scrollbar scrollbar;
	public VTToggleButton tbutton;
	public int page_index = -1;
	public Notebook notebook;
	public unowned MySettings my_conf;
	private uint remove_timer = 0;
	public signal void on_remove_timeout(AYTab self);
	public uint destroe_delay = 0;
	public signal void on_destroy ();
	
	public AYTab(MySettings my_conf,Notebook notebook, uint tab_index /*starting from 0*/) {
		this.my_conf=my_conf;
		this.notebook=notebook;
		this.tbutton = new VTToggleButton();


		this.tbutton.can_focus=false;//vte shoud have focus
		this.tbutton.can_default = false; //encrease size
		this.tbutton.has_focus = false; //encrease size
		this.tbutton.set_use_underline(false);
		this.tbutton.set_focus_on_click(false);
		this.tbutton.set_has_window (false);
		this.tbutton.tab_index=tab_index;
		this.tbutton.show();
		this.configure(my_conf);
		//this.tbutton.set_title(tab_index,null);
		

		this.hbox = new HBox(false, 0);
		this.hbox.halign=Gtk.Align.FILL;
		this.hbox.valign=Gtk.Align.FILL;
		this.hbox.expand=false;		
		//this.hbox.pack_start(this.vte_term,true,true,0);
		//this.vte_term.grab_focus();
		//this.vte_term.can_default=true;
		this.hbox.show();
//~		this.scrollbar = new VScrollbar(((Scrollable)this.vte_term).get_vadjustment());
//~		hbox.pack_start(scrollbar,false,false,0);
		page_index = this.notebook.insert_page (hbox,null,(int)tab_index);

		this.tbutton.object = this;
		
		this.my_conf.on_load.connect(()=>{
			this.configure(this.my_conf);
			});
			
		this.hbox.destroy.connect(()=>{ debug("AYTab hbox destroyed"); });
	}
	
	public void destroy(){
		this.on_destroy();//emit signal
		this.hbox.hide();
		this.notebook.remove_page(this.notebook.page_num(this.hbox));
		this.hbox.destroy();//destroy all widgets and unref self
	}

//~ 	public override void dispose(){	debug("AYTab dispose");	}

	private void configure(MySettings my_conf){
		this.tbutton.tab_format = my_conf.get_string("tab_format","[ _INDEX_ ]",(ref new_val)=>{
			string err;
			if(!my_conf.check_markup(replace_color_in_markup(this.tbutton,new_val),out err)){
				debug(_("tab_format wrong value! will be used default value. err:%s"),err);
				return CFG_CHECK.USE_DEFAULT;
			}

			return CFG_CHECK.OK;
			});

		this.tbutton.tab_title_format = my_conf.get_string("tab_title_format","<span foreground='tab-index-color'>_INDEX_</span>/_TITLE_<span foreground='#999999' font_family='sans' size='9000' rise='1000'>|</span>",(ref new_val)=>{
			string err;
			if(!my_conf.check_markup(replace_color_in_markup(this.tbutton,new_val),out err)){
				debug(_("tab_title_format wrong value! will be used default value. err:%s"),err);
				return CFG_CHECK.USE_DEFAULT;
			}

			return CFG_CHECK.OK;
			});
		this.tbutton.tab_title_regex = my_conf.get_string_list("tab_title_format_regex",{"^(mc) \\[","<span>_REPLACE_ </span>","([\\w\\.]+)@","<span font_weight='bold' foreground='username-color'>_USER_</span>@","@([\\w\\.\\-]+)\\]?:(?!/{2})","@<span font_weight='bold' foreground='hostname-color'>_HOSTNAME_</span>:","([^:]*)$","<span>_PATH_</span>"},(ref new_val)=>{
			if(new_val!=null && (new_val.length % 2)!=0){
				debug(_("tab_title_format_regex odd value of array length! will be used default value."));
				return CFG_CHECK.USE_DEFAULT;
			}
			for(int i=0; i<new_val.length-1;i+=2){
				string err="";
				string err2="";
				if(!my_conf.check_regex(new_val[i],out err) || !my_conf.check_markup(replace_color_in_markup(this.tbutton,new_val[i+1]),out err2)){
					debug(_("tab_title_format_regex wrong value! will be used default value. err:%s"),(err!=null?err:(err2!=null?err2:"unknown")));
					return CFG_CHECK.USE_DEFAULT;
				}
			}

			return CFG_CHECK.OK;
			});

		this.tbutton.conf_max_width=my_conf.get_integer("tab_max_width",-1,(ref new_val)=>{
			if(new_val<-1){new_val=-1;return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			});

		this.destroe_delay = my_conf.get_integer("window_tab_destroy_delay",10,(ref new_val)=>{
			if(new_val<0){new_val=0;return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			});
			
		this.tbutton.reconfigure();
	}
	
	public bool timer_on_remove_timeout(){
		debug("tab will be destroyed");
		this.on_remove_timeout(this);
		this.destroy();
		return false;//stop timer
	}
	
	public void start_remove_timer(){		
		if(this.remove_timer!=0)
			GLib.Source.remove(this.remove_timer);
		this.remove_timer=GLib.Timeout.add_seconds(this.destroe_delay,this.timer_on_remove_timeout);
	}//start_remove_timer

	public void stop_remove_timer(){		
		if(this.remove_timer!=0)
			GLib.Source.remove(this.remove_timer);
		this.remove_timer=0;
	}
}

public class term_colors_t {
  public Gdk.RGBA? fg;
  public Gdk.RGBA? bg;
  public Gdk.RGBA palette[16];
  public term_colors_t(){
    fg={0};
    bg={0};
  }
}

[CCode (cname = "g_param_spec_boxed")]
extern unowned GLib.ParamSpec param_spec_boxed(string name,string nick,string blurb,Type boxed_type,ParamFlags flags);

public class AYTerm : Vte.Terminal{

	static construct {
		int i=0;
		for(i=0;i<16;i++){
		install_style_property (param_spec_boxed ("palette-%0d".printf(i),
												   null, null,
												   typeof(Gdk.RGBA),
												   GLib.ParamFlags.READABLE));
		}
		install_style_property (param_spec_boxed ("fg-color",
												   null, null,
												   typeof(Gdk.RGBA),
												   GLib.ParamFlags.READABLE));
		install_style_property (param_spec_boxed ("bg-color",
												   null, null,
												   typeof(Gdk.RGBA),
												   GLib.ParamFlags.READABLE));												   		
	}//construct

//~ 	public override void style_updated (){
//~ 		base.style_updated ();
//~ 		this.update_style();
//~ 	}

	private bool get_style_color(string name,ref Gdk.RGBA color){
		unowned Gdk.RGBA? tmp;
		this.style_get(name,out tmp);
		if(tmp!=null){
			color=tmp;
			debug("AYTerm: %s:%s",name,color.to_string());
			tmp.free();
			return true;
		}else
			debug("AYTerm: css color \"%s\" not found ",name);
		return false;
	}

  public void gen_colors(term_colors_t tct){
		int i;
		Gdk.RGBA c={0};
		for(i=0;i<tct.palette.length;i++){
			if(!this.get_style_color("palette-%0d".printf(i),ref c))
        tct.palette[i]=terminal_palettes_linux[i];
			else
			    tct.palette[i]=c;
		}
		
		if(!this.get_style_color("fg-color",ref c))
			tct.fg=null;
		else
			tct.fg=c;

		if(!this.get_style_color("bg-color",ref c))
			tct.bg=null;
		else
			tct.bg=c;
  }//gen_colors
  
  public void apply_style(term_colors_t tct){
		#if ! VTE_2_91
		this.set_colors_rgba(tct.fg,tct.bg,tct.palette);
		if(tct.bg!=null)
			this.set_opacity((uint16)((tct.bg.alpha)*65535));
		//set_background_transparent call vte_terminal_queue_background_update
    if(background_transparent){
      this.set_background_transparent(false);//but only when changes
      this.set_background_transparent(true);//but only when changes
    }else{
      this.set_background_transparent(true);//but only when changes
      this.set_background_transparent(false);//but only when changes
    }
		#else
		this.set_colors(tct.fg,tct.bg,tct.palette);
		#endif
  }//apply_style

	public void update_style(){
    var tct =  new term_colors_t();
    
    this.gen_colors(tct);
    this.apply_style(tct);
	}//update_style

	public AYTerm(){
//~ 		this.update_style();
//~ 		var context = this.get_style_context ();
//~ 		context.changed.connect(()=>{
//~ 			this.update_style();
//~ 			});
	}

}
public class VTTerminal : AYTab{
	public AYTerm vte_term {get; set; default = null;}
	public Pid pid {get; set; default = -1;}
	public bool auto_restart {get; set; default = true;}
	public bool match_case {get; set; default = false;}
	private OnChildExitCallBack on_child_exit {get; set; default = null;}
	private HashTable<int, string> match_tags;
	public  string session_command {get;set;default=null;}
	public  string session_path {get;set;default=null;}
	private string? last_link;
	private int?    last_tag;
	private bool disable_terminal_popup=false;
	private Array<VTT_LOCK_SETTING> lock_settings;
	

	public VTTerminal(MySettings my_conf,Notebook notebook, uint tab_index/*starting from 0*/,string? session_command=null,string? session_path=null,OnChildExitCallBack? on_child_exit=null) {
		base(my_conf, notebook, tab_index);
		this.my_conf=my_conf;
		this.notebook=notebook;
		this.session_command=session_command;
		this.session_path=session_path;
		this.lock_settings	 = new Array<VTT_LOCK_SETTING> ();
		
		if(on_child_exit!=null)
			this.on_child_exit=on_child_exit;

		this.match_tags = new HashTable<int, string> (direct_hash, direct_equal);
		this.vte_term = new AYTerm();
		this.vte_term.halign=Gtk.Align.FILL;
		this.vte_term.valign=Gtk.Align.FILL;
		this.vte_term.expand=false;
		/*this.vte_term.size_allocate.connect((allocation)=>{
			debug("[screen %p] size-alloc   %d : %d at (%d, %d)\n",
                         this.vte_term, allocation.width, allocation.height, allocation.x, allocation.y);
			});*/

		/*this.vte_term.size_request.connect((req)=>{
			debug("[window %p] size-request result %d : %d\n",
                         this.vte_term, req.width, req.height);
			});*/


		this.vte_term.child_exited.connect(this.child_exited);

		this.hbox.pack_start(this.vte_term,true,true,0);
		//this.vte_term.grab_focus();
		//this.vte_term.can_default=true;
		this.scrollbar = new VScrollbar(((Scrollable)this.vte_term).get_vadjustment());
		hbox.pack_start(scrollbar,false,false,0);
		this.vte_term.search_set_wrap_around(my_conf.get_boolean("search_wrap_around",true));
		this.match_case =my_conf.get_boolean("search_match_case",this.match_case);
		this.my_conf.on_load.connect(()=>{
			this.configure(this.my_conf);
			});
		
		this.vte_term.button_press_event.connect(vte_button_press_event);
		#if VTE_2_91
                this.vte_term.notification_received.connect(notification_received_cb);
                #endif

		this.tbutton.button_press_event.connect(vttoggle_button_press_event);
		this.configure(my_conf);
		//GLib.Idle.add(call);
		
		this.start_shell();
				
		this.hbox.show();
		this.vte_term.destroy.connect(()=>{	debug("VTTerminal vte_term destroyed");	});
		this.on_destroy.connect(()=>{
			this.vte_term.child_exited.disconnect(this.child_exited);
			debug("VTTerminal destroyed");
			});
	}
			
	public void start_shell(){
		if(!this.start_command(this.session_command,this.session_path)){
			if(!this.start_command()){//try without session
				this.my_conf.set_string("custom_command","");
				if(!this.start_command()){//try without custom_command
					debug("Unable to run shell command!");
					Gtk.main_quit();
					}
			}
		}		
	}


	public bool start_command(string? session_command = null,string? session_path=null){
		PtyFlags pty_flags = PtyFlags.DEFAULT;
		GLib.SpawnFlags spawn_flags =  0;
		string? command = null;
		string[] argvp;
		
		bool run_as_login_shell = this.my_conf.get_boolean("terminal_run_as_login_shell",false);

		if(!run_as_login_shell){
			pty_flags |= PtyFlags.NO_LASTLOG;
		}

		if(!this.my_conf.get_boolean("terminal_update_login_records",false)){
			pty_flags |= PtyFlags.NO_UTMP | PtyFlags.NO_WTMP;
		}

		if(session_command != null && session_command != ""){
			command = session_command;
			spawn_flags |= GLib.SpawnFlags.SEARCH_PATH;
			try {
				GLib.Shell.parse_argv(command,out argvp);
			}catch (ShellError e) {
				error("Error: %s", e.message);
			}
		}else{
			command = this.my_conf.get_string("custom_command","");
			if(command == null || command == "")
				command = GLib.Environment.get_variable ("SHELL");

			if(command==null)
				command = "/bin/sh";
			
			try {
				GLib.Shell.parse_argv(command,out argvp);
			}catch (ShellError e) {
				error("Error: %s", e.message);
			}
				
			if(run_as_login_shell){
				spawn_flags |= GLib.SpawnFlags.FILE_AND_ARGV_ZERO;
				argvp+="-%s".printf(GLib.Path.get_basename(command));
			}else
				spawn_flags |= GLib.SpawnFlags.SEARCH_PATH;
		}

		debug("run command:%s",command);
		
		string path="";
		if(session_path==null || session_path==""){
			path = GLib.Environment.get_current_dir();
		}else{
			path = session_path;
		}
		if(path==null)
			path="/";

		
		/*(Vte.PtyFlags pty_flags,
		 *  string? working_directory,
		 *  string[] argv,
		 *  string[]? envv,
		 *  GLib.SpawnFlags spawn_flags,
		 *  GLib.SpawnChildSetupFunc? child_setup,
		 *  out GLib.Pid child_pid)*/
		Pid child_pid;
		string?[] envv = {};
		string[] args = GLib.Environment.list_variables ();
		string term_var = this.my_conf.get_string("terminal_term_variable","xterm",(ref new_val)=>{
				if(new_val==""){new_val="xterm";return CFG_CHECK.REPLACE;}
				return CFG_CHECK.OK;
			});
		string term_exclude_vars = this.my_conf.get_string("terminal_exclude_variables","^(COLUMNS|LINES|GNOME_DESKTOP_ICON|COLORTERM|WINDOWID)$",(ref new_val)=>{
			string err;
			if(!this.my_conf.check_regex(new_val,out err) || new_val.strip() == ""){ //prevent empty regexp issue #36
				debug(_("terminal_exclude_variables wrong value! will be used default value. err:%s"),err);
				return CFG_CHECK.USE_DEFAULT;
			}

			return CFG_CHECK.OK;
			});
		foreach(string arg in args){
			if(arg == "TERM" ||
			  (arg == "GDK_CORE_DEVICE_EVENTS" && this.my_conf.get_boolean("workaround_if_focuslost",false) ) ){
				continue;//skip
			}else
			if( !GLib.Regex.match_simple(term_exclude_vars,arg,RegexCompileFlags.CASELESS,0) ){
				unowned string val=GLib.Environment.get_variable(arg);
				string s="%s=%s".printf(arg,(val!=null?val:""));
				envv+=s;
			}else{
				debug("exclude:%s",arg);
			}
		}
		envv+="TERM="+term_var;
		envv+="COLORTERM="+GLib.Environment.get_prgname();
		envv+=null;
		bool ret=false;
		//var ret = this.vte_term.fork_command_full(pty_flags ,path,argvp,envv,spawn_flags,null,out p);
		//don't use fork_command_full because with it, is not possible to set up TERM variable
		#if ! VTE_2_91
		Vte.Pty pty = this.vte_term.pty_new(pty_flags);
		#else
		Vte.Pty pty = new Vte.Pty.sync(pty_flags);
		#endif
		spawn_flags |= GLib.SpawnFlags.CHILD_INHERITS_STDIN;
		spawn_flags |= GLib.SpawnFlags.DO_NOT_REAP_CHILD;
		try{
        ret = GLib.Process.spawn_async_with_pipes(path,
                                       argvp, envv,
                                       spawn_flags,
                                       (GLib.SpawnChildSetupFunc) pty.child_setup,
                                       out child_pid,
                                       null, null, null);
		}catch(GLib.SpawnError.CHDIR err){
			 /* try spawning in our working directory */
			if(path!=null)
			ret = GLib.Process.spawn_async_with_pipes(null,
										   argvp, envv,
										   spawn_flags,
										   (GLib.SpawnChildSetupFunc) pty.child_setup,
										   out child_pid,
										   null, null, null);
		}

		if(ret==true){
			#if ! VTE_2_91
			this.vte_term.set_pty_object(pty);
			#else
			this.vte_term.pty = pty;
			#endif
			this.vte_term.watch_child(child_pid);
			this.pid=child_pid;
		}

		return ret;
	}

	public void child_exited(){
		if(this.on_child_exit!=null)
 			this.on_child_exit(this);
	}
	
	private void configure(MySettings my_conf){
		uint path_length=0;
		string spath = "";
		string spath_reversed = "";

		if(my_conf.get_boolean("terminal_show_scrollbar",true))
			this.scrollbar.show();
		else
			this.scrollbar.hide();


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
		this.auto_restart=my_conf.get_boolean("terminal_auto_restart_shell",true);

		#if ALTERNATE_SCREEN_SCROLL && ! VTE_2_91
		if(my_conf.DISTR_ID==DISTRIB_ID.UBUNTU){
			//debian patch vte_terminal_set_alternate_screen_scroll
			this.vte_term.set_alternate_screen_scroll(my_conf.get_boolean("terminal_set_alternate_screen_scroll",true));
		}
		#endif

		this.vte_term.set_scrollback_lines (my_conf.get_integer("terminal_scrollback_lines",512,(ref new_val)=>{
			if(new_val<-1){new_val=-1;return CFG_CHECK.REPLACE;}//infinite scrollback
			return CFG_CHECK.OK;
			}));

		#if ! VTE_2_91
		var bg_img_file = my_conf.get_string("terminal_background_image_file","");
		if(bg_img_file!=null && bg_img_file!="" && GLib.FileUtils.test(bg_img_file,GLib.FileTest.EXISTS)){
			message("set_background_image_file=%s",bg_img_file);
			this.vte_term.set_background_image_file (bg_img_file);
		}else
			this.vte_term.set_background_image_file ("/dev/null");

		var bg_faket = my_conf.get_boolean("terminal_background_fake_transparent",false);

		this.vte_term.set_scroll_background(my_conf.get_boolean("terminal_background_fake_transparent_scroll",false));
		Gdk.Color? tint;//currently libvte don't support rgba tint
		if(Gdk.Color.parse(my_conf.get_string("terminal_tint_color","#000000"),out tint))
			this.vte_term.set_background_tint_color(tint);

		var sat = my_conf.get_double("terminal_background_saturation",0.5,(ref new_val)=>{
			if(new_val>1){ new_val=1; return CFG_CHECK.REPLACE;}
			if(new_val<0){ new_val=0; return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			});
		this.vte_term.set_background_saturation(sat);
		//if(bg_faket){
			this.vte_term.set_background_transparent(bg_faket);//fake transparent
		//}//else{//moved -> this.vte_term.update_style();
			//set_background_transparent call vte_terminal_queue_background_update
			//this.vte_term.set_background_transparent(true);//but only when changes
			//this.vte_term.set_background_transparent(false);//but only when changes
		//}
		#endif
		/*0-BLOCK,1-IBEAM,2-UNDERLINE*/
		var cursorshape  = my_conf.get_integer("terminal_cursorshape",0,(ref new_val)=>{
			if(new_val>2){new_val=0;return CFG_CHECK.REPLACE;}
			if(new_val<0){new_val=0;return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			});
		#if ! VTE_2_91
		this.vte_term.set_cursor_shape((Vte.TerminalCursorShape)cursorshape);
		#else
		this.vte_term.set_cursor_shape((Vte.CursorShape)cursorshape);
		#endif
		/*0-SYSTEM,1-ON,2-OFF*/
		var cursor_blinkmode  = my_conf.get_integer("terminal_cursor_blinkmode",0,(ref new_val)=>{
			if(new_val>2){new_val=0;return CFG_CHECK.REPLACE;}
			if(new_val<0){new_val=0;return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			});
		#if ! VTE_2_91
		this.vte_term.set_cursor_blink_mode ((Vte.TerminalCursorBlinkMode)cursor_blinkmode);
		#else
		this.vte_term.set_cursor_blink_mode ((Vte.CursorBlinkMode)cursor_blinkmode);
		#endif

		if(!this.is_locked(VTT_LOCK_SETTING.DELETE_BINDING)){
			/*0-AUTO,1-BACKSPACE,2-DELETE,3-SEQUENCE,4-TTY*/
			var delbinding  = my_conf.get_integer("terminal_delete_binding",0,(ref new_val)=>{
				if(new_val>4){new_val=0;return CFG_CHECK.REPLACE;}
				if(new_val<0){new_val=0;return CFG_CHECK.REPLACE;}
				return CFG_CHECK.OK;
				});
			#if ! VTE_2_91
			this.vte_term.set_delete_binding ((Vte.TerminalEraseBinding)delbinding);
			#else
			this.vte_term.set_delete_binding ((Vte.EraseBinding)delbinding);
			#endif
		}

		if(!this.is_locked(VTT_LOCK_SETTING.BACKSPACE_BINDING)){
			/*0-AUTO,1-BACKSPACE,2-DELETE,3-SEQUENCE,4-TTY*/
			var backspace  = my_conf.get_integer("terminal_backspace_binding",0,(ref new_val)=>{
				if(new_val>4){new_val=0;return CFG_CHECK.REPLACE;}
				if(new_val<0){new_val=0;return CFG_CHECK.REPLACE;}
				return CFG_CHECK.OK;
				});
			#if ! VTE_2_91
			this.vte_term.set_backspace_binding ((Vte.TerminalEraseBinding)backspace);
			#else
			this.vte_term.set_backspace_binding ((Vte.EraseBinding)backspace);
			#endif
		}

		if(!this.is_locked(VTT_LOCK_SETTING.ENCODING)){
			/* default - is special value
			 * */
			var s = my_conf.get_string("terminal_default_encoding","default");
			if(s!="default"){
				#if ! VTE_2_91
				this.vte_term.set_encoding (s);
				#else
				this.vte_term.encoding=s;
				#endif
			}else
				#if ! VTE_2_91
				this.vte_term.set_encoding (null);//reset to default
				#else
				this.vte_term.encoding=null;
				#endif
		}

		string[] url_regexps = my_conf.get_string_list("terminal_url_regexps",{"(\\\"\\s*)?((?i)http|https|ftp|sftp)\\://([a-zA-Z0-9\\-]+(\\.)?)+(:[0-9]+)?(/([a-zA-Z0-9\\(\\)\\[\\]\\{\\};\\!\\*'\"`\\:@&=\\+\\$\\,/\\?#\\-\\_\\.\\~%\\^<>\\|\\\\])*)?","xdg-open"},(ref new_val)=>{
			if(new_val!=null && (new_val.length % 2)!=0){
				debug(_("terminal_url_regexps odd value of array length! will be used default value."));
				return CFG_CHECK.USE_DEFAULT;
			}
			for(int j=0; j<new_val.length-1;j+=2){
				string err;
				if(!my_conf.check_regex(new_val[j],out err)){
					debug(_("terminal_url_regexps wrong value! will be used default value. err:%s"),err);
					return CFG_CHECK.USE_DEFAULT;
				}
			}

			return CFG_CHECK.OK;
			});

		if((url_regexps.length % 2) == 0){
			#if ! VTE_2_91
			this.vte_term.match_clear_all();
			#endif
			this.match_tags.foreach ((key, val) => {
				free(val);
			});
			this.match_tags.steal_all();
			debug("url_regexps=%d",url_regexps.length);
			for(int j=0;j<url_regexps.length-1;j+=2){
				var key=this.vte_term.match_add_gregex((new Regex (url_regexps[j])),0);
				debug("match_add_gregex %d",key);
				if(!this.match_tags.lookup_extended(key,null,null))
					this.match_tags.insert(key,url_regexps[j+1]);
			}
		}
		#if ! VTE_2_91
		/*since 0.38 set_word_chars is hardcoded
		 * https://bugzilla.gnome.org/show_bug.cgi?id=727743
		 * */
		var word_chars = my_conf.get_string("terminal_word_chars","-A-Za-z0-9,./?%&#:_=+@~");
		if(word_chars!=null){
			this.vte_term.set_word_chars(word_chars);
		}
		#endif

		this.vte_term.set_scroll_on_output(my_conf.get_boolean("terminal_scroll_on_output",false));
		this.vte_term.set_scroll_on_keystroke(my_conf.get_boolean("terminal_scroll_on_keystroke",true));
		this.vte_term.set_audible_bell(my_conf.get_boolean("terminal_audible_bell",true));
		#if ! VTE_2_91
		this.vte_term.set_visible_bell(my_conf.get_boolean("terminal_visible_bell",true));
		#endif
		this.vte_term.set_allow_bold(my_conf.get_boolean("terminal_allow_bold_text",true));
		var notify  = my_conf.get_integer("terminal_notify_level",2,(ref new_val)=>{
			if(new_val>3){new_val=0;return CFG_CHECK.REPLACE;}
			if(new_val<0){new_val=0;return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			});
		this.vte_term.contents_changed.disconnect(this.tbutton.check_for_notify);
		
		if((notify & 1)==1)
			this.vte_term.contents_changed.connect(this.tbutton.check_for_notify);
		if((notify & 2)==2)
			this.tbutton.notify_on_title_change=true;
		else
			this.tbutton.notify_on_title_change=false;
		
		this.tbutton.notify_timeout  = my_conf.get_integer("terminal_timeout_before_notify",5,(ref new_val)=>{
				if(new_val>1440){new_val=1440;return CFG_CHECK.REPLACE;}
				if(new_val<0){new_val=0;return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			});
		this.disable_terminal_popup=my_conf.get_boolean("terminal_disable_popup_menu",false);
		this.vte_term.update_style();

		this.scrollbar.get_settings().gtk_primary_button_warps_slider=!my_conf.get_boolean("terminal_scroll_by_page",true);
	}//configure

	public bool vte_button_press_event(Widget widget,Gdk.EventButton event) {
		if(event.type==Gdk.EventType.BUTTON_PRESS){
			if(event.button==1 && (event.state & Gdk.ModifierType.CONTROL_MASK)==Gdk.ModifierType.CONTROL_MASK){
				this.check_match(event);
			}else
			if(event.button== 3 && !this.disable_terminal_popup){//right mouse button
				this.popup_menu(event);
				return true;
			}
		}
		return false; //true == ignore event
	}

	private void notification_received_cb(Vte.Terminal terminal, string summary, string? body) {
           print ("[%s]: %s\n", summary, body);

           //FIXME: detect actual tab
	   unowned Gtk.Widget parent;
			parent = this.vte_term;
			while(parent.parent!=null ){parent = parent.parent;} //find VTMainWindow
	   VTMainWindow vtw=(VTMainWindow)parent;
           if (vtw.current_state == WStates.VISIBLE)
               return;

           var notification = new GLib.Notification (summary);
           notification.set_body (body);
           var gicon = GLib.Icon.new_for_string ("altyo");
           notification.set_icon (gicon);
           GLib.Application.get_default().send_notification (null, notification);
       }


	public bool vttoggle_button_press_event(Widget widget,Gdk.EventButton event) {
		if(event.type==Gdk.EventType.BUTTON_PRESS){
//~			if(event.button==1 && (event.state & Gdk.ModifierType.CONTROL_MASK)==Gdk.ModifierType.CONTROL_MASK){
//~				this.check_match(event);
//~			}else
			if(event.button== 3){//right mouse button
				this.popup_tab_menu(event);
				return true;
			}
		}
		return false; //true == ignore event
	}
	
	public void on_copy_link_activate(){
		Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (Gdk.Display.get_default (), Gdk.SELECTION_CLIPBOARD);
		clipboard.set_text (this.last_link, -1);
		this.last_link=null;
	}

	public void on_run_link_activate(){
		string tag_value="";
		if(last_tag!=null && this.match_tags.lookup_extended(this.last_tag,null,out tag_value) ){
					if( (this.last_link.get_char (0).to_string ()=="\"" && this.last_link.get_char (this.last_link.length-1).to_string ()=="\"")
					||  (this.last_link.get_char (0).to_string ()=="'"  && this.last_link.get_char (this.last_link.length-1).to_string ()=="'" ) ){
					/*remove quotes if present at beggining and at the end
					 * example: " http://www.google.com/?q="denis""
					 * */
					this.last_link=this.last_link.slice(1,this.last_link.length-1);
					this.last_link=this.last_link.strip();
				}
				debug("check_match run=%s params=%s",tag_value,this.last_link);
				Posix.system(tag_value+" '"+this.last_link+"' &");
		}
		this.last_tag=null;
	}

	public void create_popup_menu(Gtk.Menu menu){
		//debug("popup_menu ref_count=%d",(int)menu.ref_count);
		unowned Gtk.Widget parent;
			parent = this.vte_term;
			while(parent.parent!=null ){parent = parent.parent;} //find VTMainWindow
		VTMainWindow vtw=(VTMainWindow)parent;
		menu.set_accel_group(vtw.ayobject.accel_group);
		Gtk.ActionGroup acg=vtw.ayobject.action_group;

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
		if(this.my_conf.standalone_mode){
			menuitem = (Gtk.MenuItem)acg.get_action("window_open_new_window").create_menu_item();
			menu.append(menuitem);
		}
		
		vtw.ayobject.create_popup_menu_for_removed_tabs(menu);
					
		menuitem = (Gtk.MenuItem)acg.get_action("terminal_search_dialog").create_menu_item();
		menu.append(menuitem);

		menuitem = new Gtk.SeparatorMenuItem();
		menu.append(menuitem);
		menuitem = (Gtk.MenuItem)acg.get_action("open_settings").create_menu_item();
		menu.append(menuitem);

		/**************************************************************/
		var submenu = new Gtk.Menu ();

			menuitem = (Gtk.MenuItem)acg.get_action("window_terminal_quick_settings").create_menu_item();
			submenu.append(menuitem);

			if(!this.my_conf.standalone_mode){
				menuitem = (Gtk.MenuItem)acg.get_action("follow_the_mouse").create_menu_item();
				submenu.append(menuitem);
				
				var action_keepabove = acg.get_action("keep_above") as ToggleAction;
				action_keepabove.set_active(vtw.keep_above);
				menuitem = (Gtk.MenuItem)action_keepabove.create_menu_item();
				submenu.append(menuitem);

				var action_stick = acg.get_action("window_toggle_stick") as ToggleAction;
				action_stick.set_active(vtw.orig_stick);
				menuitem = (Gtk.MenuItem)action_stick.create_menu_item();
				submenu.append(menuitem);

				var action_autohide = acg.get_action("window_toggle_autohide") as ToggleAction;
				action_autohide.set_active(vtw.autohide);
				menuitem = (Gtk.MenuItem)action_autohide.create_menu_item();
				submenu.append(menuitem);

			}
			if(!this.my_conf.standalone_mode){
				menuitem = (Gtk.MenuItem)acg.get_action("window_open_new_window").create_menu_item();
				submenu.append(menuitem);
			}

			menuitem = (Gtk.MenuItem)acg.get_action("terminal_copy_all_text").create_menu_item();
			submenu.append(menuitem);

		menuitem = new Gtk.MenuItem.with_label (_("Quick settings"));
		menuitem.set_submenu(submenu);
		menu.append(menuitem);
		
		menuitem = (Gtk.MenuItem)acg.get_action("altyo_about").create_menu_item();
		menu.append(menuitem);

		menuitem = new Gtk.SeparatorMenuItem();
		menu.append(menuitem);

		if(!this.my_conf.standalone_mode){
			menuitem = (Gtk.MenuItem)acg.get_action("main_hotkey").create_menu_item();
			menu.append(menuitem);
		}
		menuitem = (Gtk.MenuItem)acg.get_action("altyo_exit").create_menu_item();
		menu.append(menuitem);		
	}
	
	public void popup_menu(Gdk.EventButton event){
		//debug("terminal popup_menu");
		var menu = new Gtk.Menu();
		
		Gtk.MenuItem menuitem;
		
		this.last_link=null;
		this.last_tag=null;
		string? match=this.get_match((int)event.x,(int)event.y,out this.last_tag);
		if(match!=null){
			this.last_link=match;
			menuitem = new Gtk.MenuItem.with_label (_("Copy link"));
			menuitem.activate.connect(this.on_copy_link_activate);
			menu.append(menuitem);
			menuitem = new Gtk.MenuItem.with_label (_("Run link Ctrl+left mouse button"));
			menuitem.activate.connect(this.on_run_link_activate);
//~			var label=menuitem.get_child() as Gtk.Label;
//~			label.set_justify( Gtk.Justification.RIGHT);
//~			label.set_pattern( "___ ___");
//~			((Gtk.Widget)menuitem).add_accelerator( "activate", vtw.ayobject.accel_group,
//~                              0xfee9, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
			menu.append(menuitem);
		}
		
		this.create_popup_menu(menu);

		menu.deactivate.connect (this.on_deactivate);
		menu.show_all();
        //menu.attach_to_widget (this.vte_term, null);
		menu.popup(null, null, null, event.button, event.time);
		menu.ref();//no one own menu,emulate owners,uref will be on_deactivate
		//debug("popup_menu ref_count=%d",(int)menu.ref_count);
	}

	private void force_action_state(Gtk.ToggleAction action, bool new_state){
		Type type = action.get_type();
		uint sig_id=GLib.Signal.lookup("activate",type);
		var handler_id =  GLib.SignalHandler.find(action,GLib.SignalMatchType.ID,sig_id,0,null,null,null);		
		GLib.SignalHandler.block(action,handler_id);//prevent emit signal
		action.set_active(new_state);
		GLib.SignalHandler.unblock(action,handler_id);
	}
	
	private void stop_signal_emission(Gtk.Action action){
		Type type = action.get_type();
		uint sig_id=GLib.Signal.lookup("activate",type);
		GLib.Signal.stop_emission(action,sig_id,0);		
	}

	public void popup_tab_menu(Gdk.EventButton event){
		//debug("terminal popup_menu");
		var menu = new Gtk.Menu();
		//debug("popup_menu ref_count=%d",(int)menu.ref_count);
		unowned Gtk.Widget parent;
			parent = this.vte_term;
			while(parent.parent!=null ){parent = parent.parent;} //find VTMainWindow
		VTMainWindow vtw=(VTMainWindow)parent;
		menu.set_accel_group(vtw.ayobject.accel_group);
		Gtk.ActionGroup acg=vtw.ayobject.action_group;

		Gtk.MenuItem menuitem;

		menuitem = (Gtk.MenuItem)acg.get_action("terminal_sort_by_hostname").create_menu_item();
		menu.append(menuitem);
		menuitem = (Gtk.MenuItem)acg.get_action("terminal_search_in_tab_title").create_menu_item();
		menu.append(menuitem);

		if(vtw.ayobject.tab_sort_order==TAB_SORT_ORDER.HOSTNAME ){
			var action_sort=acg.get_action("disable_sort_tab") as ToggleAction;
			
			this.force_action_state(action_sort,this.tbutton.do_not_sort);

			//override default action handler
			var action_sort_activate_id = action_sort.activate.connect(()=>{
				debug("disable_sort_tab.activate");
				this.tbutton.do_not_sort=!this.tbutton.do_not_sort;
				this.stop_signal_emission(action_sort);
				});
			//restore default action handler
			menu.destroy.connect(()=>{ 
				GLib.SignalHandler.disconnect(action_sort,action_sort_activate_id); 
				});
			
			menuitem = (Gtk.MenuItem)action_sort.create_menu_item();
			menu.append(menuitem);
		}
		Gtk.Settings settings = Gtk.Settings.get_default();
		
		Gtk.ImageMenuItem image_menuitem;
		Gtk.Image image;
		image_menuitem = new Gtk.ImageMenuItem.with_label (_("Copy terminal name"));
		if(settings.gtk_menu_images){
			//show images only if it not disabled globally
			image = new Gtk.Image.from_icon_name ("gtk-copy", Gtk.IconSize.MENU);
			image_menuitem.set_image(image);
		}
		image_menuitem.activate.connect(()=>{
			Gdk.Display display = vtw.get_display ();
			Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
			clipboard.set_text(this.tbutton.tab_title,-1);
			});		
		menu.append(image_menuitem);

		if(this.tbutton.host_name!=null && this.tbutton.host_name!=""){
			image_menuitem = new Gtk.ImageMenuItem.with_label (_("Copy terminal host name"));
			if(settings.gtk_menu_images){
				//show images only if it not disabled globally
				image = new Gtk.Image.from_icon_name ("gtk-copy", Gtk.IconSize.MENU);
				image_menuitem.set_image(image);
			}
			image_menuitem.activate.connect(()=>{
				Gdk.Display display = vtw.get_display ();
				Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
				clipboard.set_text(this.tbutton.host_name,-1);
				});		
			menu.append(image_menuitem);
		}

		image_menuitem = new Gtk.ImageMenuItem.with_label (_("Copy running command"));
		if(settings.gtk_menu_images){
			//show images only if it not disabled globally
			image = new Gtk.Image.from_icon_name ("gtk-copy", Gtk.IconSize.MENU);
			image_menuitem.set_image(image);
		}
		image_menuitem.activate.connect(()=>{
			Gdk.Display display = vtw.get_display ();
			Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
			clipboard.set_text(this.find_tty_pgrp(this.pid,FIND_TTY.CMDLINE),-1);
			});
		menu.append(image_menuitem);

		Gtk.CheckMenuItem chmenuitem;
		
		chmenuitem = new Gtk.CheckMenuItem.with_label (_("Disable key bindings"));
		chmenuitem.set_active (!acg.get_sensitive());
		chmenuitem.activate.connect(()=>{
			acg.set_sensitive(!acg.get_sensitive());
		});
		menu.append(chmenuitem);
		
		chmenuitem = new Gtk.CheckMenuItem.with_label (_("Disable terminal menu"));
		chmenuitem.set_active (this.disable_terminal_popup);
		chmenuitem.activate.connect(()=>{
			this.disable_terminal_popup=chmenuitem.get_active();
		});
		menu.append(chmenuitem);

		var lock_tab=acg.get_action("lock_tab") as ToggleAction;
		this.force_action_state(lock_tab,this.tbutton.prevent_close);
		//override default action handler
		var lock_tab_activate_id = lock_tab.activate.connect(()=>{
			debug("lock_tab.activate");
			this.tbutton.prevent_close=!this.tbutton.prevent_close;
			this.tbutton.reconfigure();
			vtw.ayobject.hvbox.queue_draw();//redraw border
			this.stop_signal_emission(lock_tab);
			});
		//restore default action handler
		menu.destroy.connect(()=>{ 
			GLib.SignalHandler.disconnect(lock_tab,lock_tab_activate_id); 
			});
		menuitem = (Gtk.MenuItem)lock_tab.create_menu_item();
		menu.append(menuitem);

		var custom_title=acg.get_action("tab_custom_title") as ToggleAction;
		this.force_action_state(custom_title,this.tbutton.tab_custom_title_enabled);
		//override default action handler
		var custom_title_activate_id = custom_title.activate.connect(()=>{
			debug("custom_title.activate");
			vtw.ayobject.set_custom_title_dialog(this.tbutton);
			this.stop_signal_emission(custom_title);
			});
		//restore default action handler
		menu.destroy.connect(()=>{ 
			GLib.SignalHandler.disconnect(custom_title,custom_title_activate_id); 
			});
		
		menuitem = (Gtk.MenuItem)custom_title.create_menu_item();
		menu.append(menuitem);


		if(this.disable_terminal_popup){
			var submenu = new Gtk.Menu ();
			menuitem = new Gtk.MenuItem.with_label (_("Terminal menu"));
			menuitem.set_submenu(submenu);
			menu.append(menuitem);				
			this.create_popup_menu(submenu);
		}

		
		menu.deactivate.connect (this.on_deactivate);
		menu.show_all();
        //menu.attach_to_widget (this.vte_term, null);
		menu.popup(null, null, null, event.button, event.time);
		menu.ref();//no one own menu,emulate owners,uref will be on_deactivate
		//debug("popup_menu ref_count=%d",(int)menu.ref_count);		
	}//popup_tab_menu

	private string? get_match(int x,int y ,out int? tag){
			int char_width=(int)this.vte_term.get_char_width();
			int char_height=(int)this.vte_term.get_char_height();
			unowned Gtk.Border? inner_border=null;
			#if ! VTE_2_91
			this.vte_term.style_get("inner-border", out inner_border, null);
			#else
			unowned Gtk.StyleContext context = this.vte_term.get_style_context();
			inner_border=context.get_padding(this.vte_term.get_state_flags());
			#endif
			int col = ((int)x - (inner_border!=null ? inner_border.left : 0)) / char_width;
			int row = ((int)y - (inner_border!=null ? inner_border.top : 0)) / char_height;
			return this.vte_term.match_check (col, row, out tag);
	}
	
	private void check_match (Gdk.EventButton event){
			string tag_value="";
			int? tag=null;
			string? match=this.get_match((int)event.x,(int)event.y,out tag);
			if(tag!=null && this.match_tags.lookup_extended(tag,null,out tag_value) ){		
					if( (match.get_char (0).to_string ()=="\"" && match.get_char (match.length-1).to_string ()=="\"")
					||  (match.get_char (0).to_string ()=="'"  && match.get_char (match.length-1).to_string ()=="'" ) ){
						/*remove quotes if present at beggining and at the end
						 * example: " http://www.google.com/?q="denis""
						 * */
						match=match.slice(1,match.length-1);
						match=match.strip();
					}
					debug("check_match run: \"%s '%s' &\"",tag_value,match);
					Posix.system(tag_value+" '"+match+"' &");
			}
	}

	private void on_deactivate(Widget m) {
			((Gtk.Menu)m).deactivate.disconnect(on_deactivate);
			m.unref();//menu will be destroyed after end of deactivate event
			//debug("popup_menu ref_count=%d",(int)m.ref_count);//normal count 4
		}

	private int find_other_pgrp(int pid){
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
						return int.parse(stat_cont[4]);
						//"/proc/"+stat_cont[4]+"/cmdline";
					}
				}
			}
		}
	return -1;
	}

	public string?[] find_all_suspended_pgrp(int pid){
	GLib.Dir dir = GLib.Dir.open("/proc/");
	unowned string filename;
	string?[] result=null;
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

						//return int.parse(stat_cont[4]);
						//"/proc/"+stat_cont[4]+"/cmdline";
						var tty_pgrp="/proc/"+filename+"/cmdline";
						if(GLib.FileUtils.test(tty_pgrp,GLib.FileTest.EXISTS) ){
							uint8[] data;
							if(GLib.FileUtils.get_data(tty_pgrp,out data) ){
								for(var i=0;i<data.length-1;i++){
									if(data[i]==0)
										data[i]=' ';
									}
							}
								result +=(string)data;
						}
					}
				}
			}
		}
	return result;
	}
	public string find_tty_pgrp(int pid,FIND_TTY f_type=FIND_TTY.CMDLINE){
		//for more info look at kernel/Documentation/filesystems/proc.txt
		var parent_stat = "/proc/"+((int)pid).to_string()+"/stat";

		if(GLib.FileUtils.test(parent_stat,GLib.FileTest.EXISTS) ){
			string contents = "";
			size_t length = -1;
			if(GLib.FileUtils.get_contents (parent_stat,out contents,out length) ){
				contents=contents.substring(contents.last_index_of(")")+4,-1);
				var stat_cont=contents.split(" ");
				string s_pid=stat_cont[4];
				var tty_pgrp = "/proc/"+s_pid;

				int other=find_other_pgrp(int.parse(stat_cont[4]));
				if(other>0){
					s_pid=((int)other).to_string();
					tty_pgrp="/proc/"+s_pid;
				}
				//debug("find_others_pgrp=%s",other);
				switch(f_type){
				case FIND_TTY.CMDLINE:
					tty_pgrp+="/cmdline";
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
				break;
				case FIND_TTY.CWD:
					tty_pgrp+="/cwd";
					if(GLib.FileUtils.test(tty_pgrp,GLib.FileTest.EXISTS|GLib.FileTest.IS_SYMLINK) ){
						return (string)GLib.FileUtils.read_link(tty_pgrp);
					}
				break;
				case FIND_TTY.PID:
					return s_pid;
				break;
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
			//unowned
			Info info=null;
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

	public void lock_setting(VTT_LOCK_SETTING l){
		if(!this.is_locked(l))
			this.lock_settings.append_val(l);
	}

	public bool is_locked(VTT_LOCK_SETTING locked_s){
		bool ret=false;
		//foreach(var l in this.lock_settings){
		for (int i = 0; i < this.lock_settings.length ; i++) {
			if( locked_s == this.lock_settings.index(i) ){
				ret=true;
				}
		}
		return ret;
	}
}
