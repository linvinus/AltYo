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
	bool _active = false;
	public bool active {get{ return _active;}
						set{
							if(this._active != value){
								if(this._active){
									this.get_style_context().remove_class("aytab_active");
									this.get_style_context().add_class("aytab_normal");
								}else{
									this.get_style_context().remove_class("aytab_normal");
									this.get_style_context().add_class("aytab_active");
								}
								this._active=value;
							}

							//debug ("toggled = %s , %s ",this._active.to_string(),this.label.get_text());
							this.update_state();
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
	public int    tab_index {get;set;default = -1;}
	private string markup_normal  {get;set;}
	private string markup_active  {get;set;}
	private string markup_prelight  {get;set;}
	private bool force_update_tab_title {get;set;default = false;}
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

	construct {
		this.label = new Gtk.Label(null);
		this.label.use_underline=false;
		this.label.show();
		this.add(this.label);
		this.label.mnemonic_widget=null;
		this.user_notify=false;
		this.get_style_context().remove_class("button");//don't use default button theme
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


	public bool set_title(int tab_index,string? title){
		debug("set_title start");
		if( ((this.tab_title != null && this.tab_title == title && this.tab_index == tab_index )||
		   (title == null && this.tab_index == tab_index )) && this.force_update_tab_title==false )
			return false; //prevent unneccesary redraw
		debug("set_title(%d,%s)",tab_index,title);
		
		this.force_update_tab_title=false;
		
		if(!this.active && 
		   this.notify_on_title_change && 
		   this.tab_title != null && 
		   this.tab_title != title && 
		   this.user_notify == false &&
		   this.tab_index == tab_index)//ignore DnD index change
			this.user_notify=true;

		if(title!=null && title!="")
			this.tab_title = title;

		this.tab_index = tab_index;
		string result2="";
		if((this.tab_title!=null && this.tab_title!="") ){
			try{
				GLib.Regex grx_arr;
				string reg_title=GLib.Markup.escape_text(this.tab_title,-1);//replace < > with &lt; &gt;
				bool done[4]={false,false,false,false};
				for(int i=0; i<this.tab_title_regex.length-1;i+=2){
					grx_arr = new GLib.Regex(this.tab_title_regex[i]);

					reg_title=grx_arr.replace_eval(reg_title,(ssize_t) reg_title.size(),0,0, (match_info, result)=>{
							debug(" RegexEvalCallback %s %s %d",result.str,match_info.fetch(0),match_info.get_match_count());
							GLib.Regex grx;

							if(!done[0] && Regex.match_simple(".*_REPLACE_.*",this.tab_title_regex[i+1])){
								//done[0]=true;//replace is allowed repeatedly
								grx = new GLib.Regex(GLib.Regex.escape_string("_REPLACE_"));
								result.append(grx.replace_literal(this.tab_title_regex[i+1],(ssize_t) this.tab_title_regex[i+1].size(), 0, match_info.fetch(match_info.get_match_count()-1)) );
								return true;//stop
							}else
							if(!done[1] && Regex.match_simple(".*_USER_.*",this.tab_title_regex[i+1])){
								done[1]=true;
								grx = new GLib.Regex(GLib.Regex.escape_string("_USER_"));
								result.append(grx.replace_literal(this.tab_title_regex[i+1],(ssize_t) this.tab_title_regex[i+1].size(), 0, match_info.fetch(match_info.get_match_count()-1)) );
								return true;//stop
							}else
							if(!done[2] && Regex.match_simple(".*_HOSTNAME_.*",this.tab_title_regex[i+1])){
								done[2]=true;
								grx = new GLib.Regex(GLib.Regex.escape_string("_HOSTNAME_"));
								result.append(grx.replace_literal(this.tab_title_regex[i+1],(ssize_t) this.tab_title_regex[i+1].size(), 0, match_info.fetch(match_info.get_match_count()-1)) );
								this.host_name=match_info.fetch(match_info.get_match_count()-1);
								return true;//stop
							}else
							if(!done[3] && Regex.match_simple(".*_PATH_.*",this.tab_title_regex[i+1])){
								done[3]=true;
								grx = new GLib.Regex(GLib.Regex.escape_string("_PATH_"));
								result.append(grx.replace_literal(this.tab_title_regex[i+1],(ssize_t) this.tab_title_regex[i+1].size(), 0, match_info.fetch(match_info.get_match_count()-1)) );
								return true;//stop
							}
							return false;//continue
						} );
					//g_free(grx_arr);
				}

				var grx_index = new GLib.Regex(GLib.Regex.escape_string("_INDEX_"));
				var grx_title = new GLib.Regex(GLib.Regex.escape_string("_TITLE_"));
                result2 = grx_index.replace_literal(this.tab_title_format,(ssize_t) this.tab_title_format.size(), 0, tab_index.to_string() );
                result2 = grx_title.replace_literal(result2,(ssize_t) result2.size(), 0, reg_title);
			}catch(GLib.RegexError e){
				this.label.set_markup("TAB: Error in regexp");
			}
		}else{
			try{
				var grx_index = new GLib.Regex(GLib.Regex.escape_string("_INDEX_"));
                result2 = grx_index.replace_literal(this.tab_format,(ssize_t) this.tab_format.size(), 0, tab_index.to_string() );

			}catch(GLib.RegexError e){
				this.label.set_markup("TAB: Error in regexp");
			}
		}
		var context = this.get_style_context(); //todo: use this.label instead
        Gdk.RGBA color_f = context.get_color(StateFlags.NORMAL);
        Gdk.RGBA color_b = context.get_background_color(StateFlags.NORMAL);
		this.markup_normal=(this.prevent_close ? "[!] " : "")+"<span foreground='#"+"%I02x".printf(((int)(color_f.red*255)))+"%I02x".printf(((int)(color_f.green*255)))+"%I02x".printf(((int)(color_f.blue*255)))+"' "+
		/*"background='#"+"%I02x".printf(((int)(color_b.red*255)))+"%I02x".printf(((int)(color_b.green*255)))+"%I02x".printf(((int)(color_b.blue*255)))+"' "+*/
		">"+result2+"</span>";
		//this.label.set_markup(this.markup_normal);
		this.tooltip_markup=this.markup_normal;
		//var grx_prelight = new GLib.Regex(GLib.Regex.escape_string("foreground"));
		//result = grx_prelight.replace_literal(result,(ssize_t) result.size(), 0, "background" );
        color_f = context.get_color(StateFlags.ACTIVE);
        color_b = context.get_background_color(StateFlags.ACTIVE);
		this.markup_active=(this.prevent_close ? "[!] " : "")+"<span foreground='#"+"%I02x".printf(((int)(color_f.red*255)))+"%I02x".printf(((int)(color_f.green*255)))+"%I02x".printf(((int)(color_f.blue*255)))+"' "+
		/*"background='#"+"%I02x".printf(((int)(color_b.red*255)))+"%I02x".printf(((int)(color_b.green*255)))+"%I02x".printf(((int)(color_b.blue*255)))+"' "+*/
		">"+result2+"</span>";

        color_f = context.get_color(StateFlags.PRELIGHT);
        color_b = context.get_background_color(StateFlags.PRELIGHT);
		this.markup_prelight=(this.prevent_close ? "[!] " : "")+"<span foreground='#"+"%I02x".printf(((int)(color_f.red*255)))+"%I02x".printf(((int)(color_f.green*255)))+"%I02x".printf(((int)(color_f.blue*255)))+"' "+
		/*"background='#"+"%I02x".printf(((int)(color_b.red*255)))+"%I02x".printf(((int)(color_b.green*255)))+"%I02x".printf(((int)(color_b.blue*255)))+"' "+*/
		">"+result2+"</span>";
		//this.markup_prelight = result;//"<i>"+result+"</i>";

		if(this.active)
			this.label.set_markup(this.markup_active);
		else
			this.label.set_markup(this.markup_normal);

		this.label.show();
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
	public HBox hbox {get; set; default = null;}
	public Scrollbar scrollbar {get; set; default = null;}
	public VTToggleButton tbutton {get; set; default = null;}
	public int page_index {get; set; default = -1;}
	public Notebook notebook {get; set; default = null;}
	public unowned MySettings my_conf {get; set; default = null;}
	private uint remove_timer = 0;
	public signal void on_remove_timeout(AYTab self);
	private uint destroe_delay = 0;
	
	public AYTab(MySettings my_conf,Notebook notebook, int tab_index) {
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
		page_index = this.notebook.insert_page (hbox,null,tab_index);

		this.tbutton.object = this;
		this.my_conf.on_load.connect(()=>{
			this.configure(this.my_conf);
			});
	}
	public void destroy(){
		this.hbox.hide();
		this.notebook.remove_page(this.notebook.page_num(this.hbox));
		//this.tbutton.label.destroy();
		//this.tbutton.destroy();
		//this.vte_term.destroy();
		this.hbox.destroy();//destroy all widgets and unref self
	}

	private void configure(MySettings my_conf){
		this.tbutton.tab_format = my_conf.get_string("tab_format","[ _INDEX_ ]",(ref new_val)=>{
			string err;
			if(!my_conf.check_markup(new_val,out err)){
				debug(_("tab_format wrong value! will be used default value. err:%s"),err);
				return CFG_CHECK.USE_DEFAULT;
			}

			return CFG_CHECK.OK;
			});

		this.tbutton.tab_title_format = my_conf.get_string("tab_title_format","<span foreground='#FFF000'>_INDEX_</span>/_TITLE_<span foreground='#999999' font_family='sans' size='9000' rise='1000'>|</span>",(ref new_val)=>{
			string err;
			if(!my_conf.check_markup(new_val,out err)){
				debug(_("tab_title_format wrong value! will be used default value. err:%s"),err);
				return CFG_CHECK.USE_DEFAULT;
			}

			return CFG_CHECK.OK;
			});

		this.tbutton.tab_title_regex = my_conf.get_string_list("tab_title_format_regex",{"^(mc) \\[","<span>_REPLACE_ </span>","([\\w\\.]+)@","<span font_weight='bold' foreground='#EEEEEE'>_USER_</span>@","@([\\w\\.\\-]+)\\]?:(?!/{2})","@<span font_weight='bold' foreground='#FFF000'>_HOSTNAME_</span>:","([^:]*)$","<span>_PATH_</span>"},(ref new_val)=>{
			if(new_val!=null && (new_val.length % 2)!=0){
				debug(_("tab_title_format_regex odd value of array length! will be used default value."));
				return CFG_CHECK.USE_DEFAULT;
			}
			for(int i=0; i<new_val.length-1;i+=2){
				string err="";
				string err2="";
				if(!my_conf.check_regex(new_val[i],out err) || !my_conf.check_markup(new_val[i+1],out err2)){
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
		this.on_remove_timeout(this);
		debug("tab destroyed");
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

public class VTTerminal : AYTab{
	public Vte.Terminal vte_term {get; set; default = null;}
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
	

	public VTTerminal(MySettings my_conf,Notebook notebook, int tab_index,string? session_command=null,string? session_path=null,OnChildExitCallBack? on_child_exit=null) {
		base(my_conf, notebook, tab_index);
		this.my_conf=my_conf;
		this.notebook=notebook;
		this.session_command=session_command;
		this.session_path=session_path;
		this.lock_settings	 = new Array<VTT_LOCK_SETTING> ();
		
		if(on_child_exit!=null)
			this.on_child_exit=on_child_exit;

		this.match_tags = new HashTable<int, string> (direct_hash, direct_equal);
		this.vte_term = new Vte.Terminal();
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
		this.tbutton.button_press_event.connect(vttoggle_button_press_event);
		this.configure(my_conf);
		//GLib.Idle.add(call);
		
		this.start_shell();
				
		this.hbox.show();
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

	public void destroy() {
		this.vte_term.child_exited.disconnect(this.child_exited);
		base.destroy();
	}

	public bool start_command(string? session_command = null,string? session_path=null){
		PtyFlags pty_flags = PtyFlags.DEFAULT;
		GLib.SpawnFlags sflags = 0;
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
			sflags |= GLib.SpawnFlags.SEARCH_PATH;
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
				sflags |= GLib.SpawnFlags.FILE_AND_ARGV_ZERO;
				argvp+="-%s".printf(GLib.Path.get_basename(command));
			}else
				sflags |= GLib.SpawnFlags.SEARCH_PATH;
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
		Pid p;
		string[] new_args = {};
		string[] args = GLib.Environment.list_variables ();
		foreach(string arg in args){
			if( !GLib.Regex.match_simple("COLUMNS|LINES|GNOME_DESKTOP_ICON|COLORTERM|WINDOWID",arg,RegexCompileFlags.CASELESS,0) ){
				unowned string val=GLib.Environment.get_variable(arg);
				string s="%s=%s".printf(arg,(val!=null?val:""));
				new_args+=s;
			}
		}
		new_args+="COLORTERM="+GLib.Environment.get_prgname();
				
		var ret = this.vte_term.fork_command_full(pty_flags ,path,argvp,new_args,sflags,null,out p);
		this.pid=p;
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

		#if ALTERNATE_SCREEN_SCROLL
		if(my_conf.DISTR_ID==DISTRIB_ID.UBUNTU){
			//debian patch vte_terminal_set_alternate_screen_scroll
			this.vte_term.set_alternate_screen_scroll(my_conf.get_boolean("terminal_set_alternate_screen_scroll",true));
		}
		#endif

		this.vte_term.set_scrollback_lines (my_conf.get_integer("terminal_scrollback_lines",512,(ref new_val)=>{
			if(new_val<-1){new_val=-1;return CFG_CHECK.REPLACE;}//infinite scrollback
			return CFG_CHECK.OK;
			}));

		Gdk.RGBA? fg;
		fg=new Gdk.RGBA();
		Gdk.RGBA? bg;
		bg=new Gdk.RGBA();
		if(!fg.parse(my_conf.get_string("terminal_color_fg","#00FFAA")))
			fg = null;//use color from pallete
		if(!bg.parse(my_conf.get_string("terminal_color_bg","")))
			bg = null;//use color from pallete

		//default color palette - "Linux", in term of gnome-terminal
		Gdk.RGBA[] palette=  new Gdk.RGBA[16];
		palette=  {
				Gdk.RGBA(){  red=0x0000/65535.0,green=0x0000/65535.0,blue=0x0000/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0xaaaa/65535.0,green=0x0000/65535.0,blue=0x0000/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0x0000/65535.0,green=0xaaaa/65535.0,blue=0x0000/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0xaaaa/65535.0,green=0x5555/65535.0,blue=0x0000/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0x0000/65535.0,green=0x0000/65535.0,blue=0xaaaa/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0xaaaa/65535.0,green=0x0000/65535.0,blue=0xaaaa/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0x0000/65535.0,green=0xaaaa/65535.0,blue=0xaaaa/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0xaaaa/65535.0,green=0xaaaa/65535.0,blue=0xaaaa/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0x5555/65535.0,green=0x5555/65535.0,blue=0x5555/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0xffff/65535.0,green=0x5555/65535.0,blue=0x5555/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0x5555/65535.0,green=0xffff/65535.0,blue=0x5555/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0xffff/65535.0,green=0xffff/65535.0,blue=0x5555/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0x5555/65535.0,green=0x5555/65535.0,blue=0xffff/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0xffff/65535.0,green=0x5555/65535.0,blue=0xffff/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0x5555/65535.0,green=0xffff/65535.0,blue=0xffff/65535.0,alpha=1.0 },
				Gdk.RGBA(){  red=0xffff/65535.0,green=0xffff/65535.0,blue=0xffff/65535.0,alpha=1.0 }
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
			palette[i].parse(s);
			i++;
		}

		this.vte_term.set_colors_rgba(fg,bg,palette);
		//vte bug, set_opacity don't call vte_terminal_queue_background_update
		// we force update later
		this.vte_term.set_opacity((uint16)((my_conf.get_double("terminal_opacity",1.0,(ref new_val)=>{
			if(new_val<0.0){new_val=0.0;return CFG_CHECK.REPLACE;}
			if(new_val>1.0){new_val=1.0;return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			}) )*65535) );


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
		if(bg_faket){
			this.vte_term.set_background_transparent(true);//fake transparent
		}else{
			//set_background_transparent call vte_terminal_queue_background_update
			this.vte_term.set_background_transparent(true);//but only when changes
			this.vte_term.set_background_transparent(false);//but only when changes
		}
		/*0-BLOCK,1-IBEAM,2-UNDERLINE*/
		var cursorshape  = my_conf.get_integer("terminal_cursorshape",0,(ref new_val)=>{
			if(new_val>2){new_val=0;return CFG_CHECK.REPLACE;}
			if(new_val<0){new_val=0;return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			});
		this.vte_term.set_cursor_shape((Vte.TerminalCursorShape)cursorshape);
		/*0-SYSTEM,1-ON,2-OFF*/
		var cursor_blinkmode  = my_conf.get_integer("terminal_cursor_blinkmode",0,(ref new_val)=>{
			if(new_val>2){new_val=0;return CFG_CHECK.REPLACE;}
			if(new_val<0){new_val=0;return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			});
		this.vte_term.set_cursor_blink_mode ((Vte.TerminalCursorBlinkMode)cursor_blinkmode);
		if(!this.is_locked(VTT_LOCK_SETTING.DELETE_BINDING)){
			/*0-AUTO,1-BACKSPACE,2-DELETE,3-SEQUENCE,4-TTY*/
			var delbinding  = my_conf.get_integer("terminal_delete_binding",0,(ref new_val)=>{
				if(new_val>4){new_val=0;return CFG_CHECK.REPLACE;}
				if(new_val<0){new_val=0;return CFG_CHECK.REPLACE;}
				return CFG_CHECK.OK;
				});
			this.vte_term.set_delete_binding ((Vte.TerminalEraseBinding)delbinding);
		}

		if(!this.is_locked(VTT_LOCK_SETTING.BACKSPACE_BINDING)){
			/*0-AUTO,1-BACKSPACE,2-DELETE,3-SEQUENCE,4-TTY*/
			var backspace  = my_conf.get_integer("terminal_backspace_binding",0,(ref new_val)=>{
				if(new_val>4){new_val=0;return CFG_CHECK.REPLACE;}
				if(new_val<0){new_val=0;return CFG_CHECK.REPLACE;}
				return CFG_CHECK.OK;
				});
			this.vte_term.set_backspace_binding ((Vte.TerminalEraseBinding)backspace);
		}

		if(!this.is_locked(VTT_LOCK_SETTING.ENCODING)){
			/* default - is special value
			 * */
			var s = my_conf.get_string("terminal_default_encoding","default");
			if(s!="default"){
				this.vte_term.set_encoding (s);
			}else
				this.vte_term.set_encoding (null);//reset to default
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
			this.vte_term.match_clear_all();
			this.match_tags.foreach ((key, val) => {
				free(val);
			});
			this.match_tags.steal_all();
			debug("url_regexps=%d",url_regexps.length);
			for(i=0;i<url_regexps.length-1;i+=2){
				var key=this.vte_term.match_add_gregex((new Regex (url_regexps[i])),0);
				debug("match_add_gregex %d",key);
				if(!this.match_tags.lookup_extended(key,null,null))
					this.match_tags.insert(key,url_regexps[i+1]);
			}
		}

		var word_chars = my_conf.get_string("terminal_word_chars","-A-Za-z0-9,./?%&#:_=+@~");
		if(word_chars!=null){
			this.vte_term.set_word_chars(word_chars);
		}

		this.vte_term.set_scroll_on_output(my_conf.get_boolean("terminal_scroll_on_output",false));
		this.vte_term.set_scroll_on_keystroke(my_conf.get_boolean("terminal_scroll_on_keystroke",true));
		this.vte_term.set_audible_bell(my_conf.get_boolean("terminal_audible_bell",true));
		this.vte_term.set_visible_bell(my_conf.get_boolean("terminal_visible_bell",true));
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

	private ulong get_action_handler_id(Gtk.Action action){
		Type type = action.get_type();
		uint sig_id=GLib.Signal.lookup("activate",type);
		return GLib.SignalHandler.find(action,GLib.SignalMatchType.ID,sig_id,0,null,null,null);		
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

		if(vtw.ayobject.tab_sort_order==TAB_SORT_ORDER.HOSTNAME && vtw.ayobject.active_tab==this.tbutton){
			var action_sort=acg.get_action("disable_sort_tab") as ToggleAction;
			
			var handler_id = this.get_action_handler_id(action_sort);
			GLib.SignalHandler.block(action_sort,handler_id);//prevent emit signal
			action_sort.set_active(this.tbutton.do_not_sort);
			GLib.SignalHandler.unblock(action_sort,handler_id);
			
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

		if(vtw.ayobject.active_tab==this.tbutton){
			var lock_tab=acg.get_action("lock_tab") as ToggleAction;
			var handler_id = this.get_action_handler_id(lock_tab);
			GLib.SignalHandler.block(lock_tab,handler_id);//prevent emit signal
			lock_tab.set_active(this.tbutton.prevent_close);
			GLib.SignalHandler.unblock(lock_tab,handler_id);
			
			menuitem = (Gtk.MenuItem)lock_tab.create_menu_item();
			menu.append(menuitem);
		}

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
			this.vte_term.style_get("inner-border", out inner_border, null);
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
