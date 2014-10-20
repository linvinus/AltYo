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
using Cairo;

public class point_a {
	public unowned Gtk.ActionGroup ag;
	public StringBuilder sb;
	public point_a(Gtk.ActionGroup ag) {
		this.ag=ag;
		this.sb=new StringBuilder();
	}
}

public enum WStates{
	VISIBLE,
	HIDDEN
	}

public enum TASKS{
	TERMINALS,
	QLIST
	}

public enum TAB_SORT_ORDER{
	NONE,
	HOSTNAME
	}

public enum SEARCH_MODE{
	SEARCH_IN_TEXT,
	SEARCH_IN_NAME
	}

public enum NEW_TAB_MODE{
	RIGHT_NEXT,
	FAR_RIGHT
	}

public enum OPTIONS_TAB{
	SEARCH,
	ENCODINGS
	}
public enum MYWINStates{
	NULL,
	MAXIMIZED,
	FULLSCREEN
	}
public enum HVBOXDISPLAY{
	VISIBLE,
	HIDDEN,
	HIDEIFONETAB
	}
public delegate void MyCallBack(Gtk.Action a);

public class VTMainWindow : Window{
	public OffscreenWindow pixwin;
	public AYObject ayobject;
	
	private int my_window_state;
	private bool wait_window_manager=false;
	private bool not_configured=true;//prevent some errors while starting
	private uint wait_for_window_position_update=0;
	private uint on_monitor_changed_force_new_position_glib_timer_id=0;
	private uint update_position_size_for_glib_timer_id=0;
	private bool _maximized=false;//cached value
	public bool maximized {
        get {
			
			var win = this.get_window();
			if( win!=null ){
				if( (win.get_state() & Gdk.WindowState.MAXIMIZED) == Gdk.WindowState.MAXIMIZED){
					_maximized=true;
					return true; 
				}else{
					_maximized=false;
					return false;
				}
			}else
				return _maximized;
		}

        set {
			if(value == true){
				debug("mainvt_maximize");
				this.my_window_state |= MYWINStates.MAXIMIZED;
				if(!this.maximized){
					this.wait_window_manager=true;
					this.maximize();
					if(this.fullscreen_on_maximize)
						this.fullscreened=true;
				}
			}else{
				debug("mainvt_unmaximize");
				this.my_window_state &= ~(MYWINStates.MAXIMIZED);
				this.fullscreened=false;
				if(this.maximized){
					this.wait_window_manager=true;
					this.wait_for_window_position_update=5;
					this.width_request=-1;//allow main window resize
					this.height_request=-1;//allow main window resize
					this.unmaximize();
				}
			}
		}		
	}//public bool maximized
	
	private bool _fullscreened=false;
	public bool fullscreened {
		get{
			var win = this.get_window();
			if( win!=null ){
				if( (win.get_state() & Gdk.WindowState.FULLSCREEN) == Gdk.WindowState.FULLSCREEN ){
					_fullscreened=true;
					return true; 
				}else{
					_fullscreened=false;
					return false;
				}
			}else
				return _fullscreened;			
		}
		set{
			if(value == true){
				this.my_window_state |= MYWINStates.FULLSCREEN;
				this.fullscreen();
			}else{
				this.my_window_state &= ~MYWINStates.FULLSCREEN;
				
				if(this.fullscreened){
					this.unfullscreen();
				}
			}
		}
	}//public bool fullscreen
	
	public bool allow_update_size {
		get{
//~ 			debug("maximized=%d fullscreened=%d update_maximized_size=%d update_minimized_size=%d pull_animation_active=%d pull_active=%d standalone_mode=%d wait_window_manager=%d" ,
//~ 			   (int)this.maximized,
//~ 			   (int)this.fullscreened,
//~ 			   (int)this.update_maximized_size,
//~ 			   (int)this.update_minimized_size,
//~ 			   (int)this.pull_animation_active,
//~ 			   (int)this.pull_active,
//~ 			   (int)this.conf.standalone_mode,
//~ 			   (int)this.wait_window_manager);
			   
			if(!this.conf.standalone_mode &&
			   !this.maximized && 
			   !this.fullscreened &&
			   !this.pull_animation_active && 
			   !this.pull_active &&
			   !this.not_configured &&
			   !this.wait_window_manager)
				return true;
			else
				return false;
			
		}	
	}
	public bool fullscreen_on_maximize=false;
	public bool animation_enabled = true;
	public int animation_speed=5;
	public int pull_steps=20;
	public bool pull_animation_active = false;
	public bool pull_active = false;
	public bool pull_update_maximize_size = false; /*used to update size on pull down*/
	public WStates current_state {get;set; default = WStates.VISIBLE;}
	public unowned MySettings conf {get;set; default = null;}
	public bool keep_above=true;
	public bool orig_stick=true;

	public PanelHotkey hotkey;
	public bool mouse_follow=false;
	public unowned Widget prev_focus=null;

	private int pull_step = 0;
	public int orig_x = 0;
	public int orig_y = 0;
	private int pull_w = 0;
	private int pull_h = 0;
	private int pull_x = 0;
	private int pull_y = 0;
	private int orig_h_tasks_notebook=0;
	private int orig_w_tasks_notebook=0;
	private int orig_h_main_vbox=0;
	private int orig_w_main_vbox=0;
	private int orig_monitor=-1;
	public int position = 1;
	public bool config_maximized=false;
	public bool start_maximized=false;
	public bool pull_maximized=false;
	public bool temporary_maximized=false;
	public bool allow_close=false;
	public bool gravity_north_west=true;
	public bool autohide=false;

	private uint32 last_focus_out_event_time;
	private unowned Gdk.Window ignore_last_active_window = null;
	private DateTime on_monitors_changed_start_time = null;

	public VTMainWindow(WindowType type) {
		Object(type:type);
		}

	construct {
		this.title = "AltYo"; 
		//this.border_width = 0;
		this.skip_taskbar_hint = true;
		this.urgency_hint = true;
		this.set_decorated (false);
		this.resizable = true;//we need resize!
		this.set_has_resize_grip(false);//but hide grip
		//this.set_focus_on_map (true);
		//this.set_accept_focus (true);
		//this.set_keep_above(true);
		//this.stick ();
		this.pixwin = new OffscreenWindow ();
		this.pixwin.name="OffscreenWindow";
		this.pixwin.show();
		this.pixwin.damage_event.connect((event)=>{
			if(this.visible && (this.pull_animation_active || this.pull_active)){
				debug("pixwin.damage_event");
				var w = this.get_window();
				w.invalidate_rect(null,false);
			}
			});
		//this.set_app_paintable(true);
		//this.set_double_buffered(false);

//~ 		Gdk.RGBA c = Gdk.RGBA();
//~ 		c.parse("#000000");//black todo: make same color as vte
//~ 		c.alpha = 0.0;//transparency

		this.set_visual (this.screen.get_rgba_visual ());//transparancy
		this.set_app_paintable(true);//do not draw backgroud
//~ 		this.override_background_color(StateFlags.NORMAL, c);
		//this.pixwin.set_visual (this.screen.get_rgba_visual ());//transparancy
		//this.pixwin.set_app_paintable(true);//do not draw backgroud
	}

	public void CreateVTWindow(MySettings conf) {
		this.conf=conf;

		Image img = new Image.from_resource ("/org/gnome/altyo/altyo.svg");
		this.set_icon(img.pixbuf);

		this.keep_above=conf.get_boolean("keep_above_at_startup",this.keep_above);
		if(!this.keep_above){
			this.skip_taskbar_hint = false;
			this.set_keep_above(false);
		}

		this.hotkey = new PanelHotkey ();
		this.hotkey.on_active_window_change.connect(this.check_focusout);
		this.reconfigure();//window
		this.not_configured=false;

		this.ayobject= new AYObject(this,conf);
		this.add(this.ayobject.main_vbox);


		this.delete_event.connect (()=>{
			if(this.allow_close==false){
				this.ayobject.ShowQuitDialog();
				return true;//prevent close
			}
			return false;//default is allow
			});

		this.destroy.connect (()=>{			
			this.hide();
			this.hotkey.on_active_window_change.disconnect(this.check_focusout);
			this.hotkey.unref();//destroy
			this.ayobject.save_configuration();
			this.conf.save();
			unowned Gtk.Widget ch=this.pixwin.get_child();
			if(ch is Gtk.Widget)
				ch.destroy();		
			Gtk.main_quit();
			});

		this.conf.on_load.connect(()=>{
			this.reconfigure();
			if(this.current_state==WStates.VISIBLE){
				this.configure_position();
				this.update_position_size();
				/*update maximize state according to config_maximized*/
				if(!this.config_maximized && this.maximized){
					this.maximized=false;
				}else
				if(this.config_maximized && !this.maximized){
					this.maximized=true;
				}
			}
			});

		this.check_monitor_and_configure_position();

		if(this.config_maximized && conf.get_boolean("start_hidden",false)){
			this.ayobject.on_maximize(false);
			this.maximized=true;
			this.update_position_size(false);
		}else{
			this.update_position_size(false);
		}
		debug("CreateVTWindow end");

		if(!this.conf.standalone_mode){
			if ( conf.get_boolean("start_hidden",false) ){
				this.pull_up();//all workarounds is inside pull_up,pull_down,update_position_size
				this.pull_maximized=this.start_maximized;
			}else{
				this.show();
				if(!this.start_maximized){
					this.update_position_size();
				}else{
					this.maximized=true;
					this.update_events();//process maximize event
				}
				this.window_set_active();
			}
		}else{
			this.set_wmclass("altyo-tiling","Altyo");
			this.set_decorated (true);
			this.ayobject.on_maximize(false);
			this.ayobject.on_maximize(true);
			//this.update_position_size(false);
			var should_be_h = this.ayobject.get_altyo_height(this.conf.standalone_mode);
			this.set_default_size(this.ayobject.terminal_width,should_be_h);
			this.show();
			
			
			this.window_set_active();
		}
		GLib.Idle.add(this.ayobject.create_tabs);
		if(!this.conf.standalone_mode){
			unowned Gdk.Screen gscreen = this.get_screen ();
			gscreen.monitors_changed.connect (()=>{
					GLib.Timeout.add(1000,this.on_monitors_changed);//wait for some time until the monitor is configured
				});
		}
		debug("end win show");

	}
	
	public bool on_monitors_changed(){
		debug("gscreen.monitors_changed");
		if(this.current_state == WStates.VISIBLE){
			this.check_monitor_and_configure_position();//check if was attached window_default_monitor
			if( this.configure_position() )
				this.update_position_size();
		}
		return false; //stop the timer
	}

	private void check_monitor_and_configure_position(){
			/* move window to appropriate monitor
			 * */
			string? cfg_monitor = this.conf.get_string("window_default_monitor","");
			if(cfg_monitor!=null && cfg_monitor!=""){
				int x,y;
				this.get_position (out x, out y);
				unowned Gdk.Screen gscreen = this.get_screen ();

				var current_monitor = gscreen.get_monitor_at_point (this.orig_x,this.orig_y);
				var current_monitor_name = gscreen.get_monitor_plug_name (current_monitor);
				if(current_monitor_name!=null && current_monitor_name!=cfg_monitor){
					for(var i=0;i<gscreen.get_n_monitors ();i++){
						if(gscreen.get_monitor_plug_name(i)==cfg_monitor){
							debug("found monitor name %s",gscreen.get_monitor_plug_name (i));
							Gdk.Rectangle rectangle;
							this.orig_monitor=i;
							rectangle=gscreen.get_monitor_workarea(i);
							this.orig_x=rectangle.x+10;
							var tmp=this.mouse_follow;
							this.mouse_follow=false;
							this.configure_position();
							this.mouse_follow=tmp;
							this.move(this.orig_x,this.orig_y);
							return;//configured
						}
					}
				}

			}
		/* mointor not found,
		 * use primary*/
		this.configure_position();
	}

	private void save_current_monitor(int x,int y){
			/* save position for current monitor
			 * */
				unowned Gdk.Screen gscreen = this.get_screen ();
				var current_monitor = gscreen.get_monitor_at_point (x,y);
				if(this.orig_monitor!=current_monitor){
					this.orig_monitor=current_monitor;
					this.orig_x=x;
					this.orig_y=y;
					this.configure_position();
				}
	}

	public bool on_pull_down(){

			if(this.pull_step<this.pull_steps){

				int arith_progress=(int)( ((float)(1+this.pull_steps)/2.0)*this.pull_steps);
				int tmp =this.pull_steps-this.pull_step;
				//int arith_progress2=(int)( ((float)(1+tmp)/2.0)*this.pull_step); //bubble
				int arith_progress2=(int)( ((float)(1+tmp)/2.0)*(tmp));
				int h=(this.pull_h-(this.pull_h/arith_progress)*(arith_progress2) );
				if(h==0)h=1;//set minimum height

				this.resize(this.pull_w,h);
				this.display_sync();
				this.pull_step++;
				return true;//continue animation
			}else{

				if(this.pull_step==this.pull_steps){
					debug("on_pull_down last step %d",(int)this.maximized);
					if(this.pull_maximized){
						if(!this.maximized){
							this.pull_update_maximize_size=true;
							this.maximized=true;
						}
					}else{
						this.resize (this.pull_w,pull_h);
					}
					this.display_sync();
					this.pull_step++;
					return true;//continue animation
				}

				var ch=this.pixwin.get_child();//.reparent(this);//reparent from offscreen window
				this.pixwin.remove(ch);
				this.add(ch);
				this.pull_animation_active=false;
				this.pull_active=false;
				this.current_state=WStates.VISIBLE;
				debug("on_pull_down very last step");
				this.update_position_size();
				this.window_set_active();
				return false;
			}
	}

	public void pull_down(){
		if(this.pull_animation_active || this.current_state!=WStates.HIDDEN)
			return;
		if(!this.animation_enabled ||
			this.pixwin.get_child()==null){//prevent error if start hidden
			this.configure_position();
			this.resize (this.pull_w,this.pull_h);//start height
			this.show();
			if((this.mouse_follow || !this.gravity_north_west) && !this.pull_maximized){
				this.move (this.orig_x,this.orig_y);//new position
			}else
				if(this.gravity_north_west)
					this.move (this.pull_x,this.pull_y);
				else
					this.move (this.pull_x,this.orig_y);

			debug("pull_down pull_maximized=%d",(int)this.pull_maximized);
			if(this.pull_maximized)
				this.maximized=true;
			this.current_state=WStates.VISIBLE;
			this.update_position_size(false);//reset size to -1
			this.window_set_active();
			//this.queue_draw();//fix some draw problems (when mouse inside hvbox after show?).
			this.pull_active=false;
			return;
		}
		this.pull_animation_active=true;
		if(!this.pull_maximized)
			this.configure_position();
		this.set_default_size(this.pull_w,2);//Default size - used only the FIRST time we map a window
		this.show();
		this.display_sync();
		this.current_state=WStates.VISIBLE;
		this.window_set_active();//update keep_above stick and focus
		if((this.mouse_follow || !this.gravity_north_west) && !this.pull_maximized){
			this.move (this.orig_x,this.orig_y);//new position
		}else
			if(this.gravity_north_west)
				this.move (this.pull_x,this.pull_y);
			else
				this.move (this.pull_x,this.orig_y);
		this.display_sync();
		if (this.pull_w >1 && this.pull_h >1)
			this.pull_step=0;
		else
			this.pull_step=this.pull_steps;//skip animation
		GLib.Timeout.add(this.animation_speed,this.on_pull_down);
	}

	public bool on_pull_up(){

			if(this.pull_step<this.pull_steps){
				int arith_progress=(int)( ((float)(1+this.pull_steps)/2.0)*this.pull_steps);
				int tmp =this.pull_steps-this.pull_step;
				int arith_progress2=(int)( ((float)(this.pull_steps+tmp)/2.0)*this.pull_step);

				int h=(this.pull_h-(this.pull_h/arith_progress)*(arith_progress2) );
				//debug("ff=%d this.pull_step=%d h=%d",ff,this.pull_step,h);
//~ 				debug("on_pull_up h=%d",h);
				if(h==0)h=1;//set minimum height
				/* object Gdk.Window have option "state" with current window state
				 * we will check is window still in fullscreen satate*/
				this.fullscreened=false;//force unfullscreen, some WMs sets fullscreen state if window size equal to fullscreen
				this.resize(this.pull_w,h);
				this.pull_step++;
//~ 				this.update_events();
				this.display_sync();

				return true;//continue animation
			}else{
				this.iconify ();//this.hide(); use iconify to prevent loss of keyboard layout per window in XFCE.
				this.current_state=WStates.HIDDEN;
				this.pull_animation_active=false;
				return false;
			}
	}

	public void pull_up(){
		if(this.pull_animation_active || this.current_state!=WStates.VISIBLE)
			return;
		this.pull_h=this.get_allocated_height();
		this.pull_w=this.get_allocated_width();
		this.get_position (out this.pull_x, out this.pull_y);
		this.prev_focus=this.get_focus();
		debug("pull_up orig_h=%d orig_w=%d",this.pull_h,this.pull_w);
		this.orig_h_main_vbox = this.ayobject.main_vbox.get_allocated_height();
		this.orig_w_main_vbox = this.ayobject.main_vbox.get_allocated_width();
		this.orig_h_tasks_notebook = this.ayobject.tasks_notebook.get_allocated_height();
		this.orig_w_tasks_notebook = this.ayobject.tasks_notebook.get_allocated_width();
		debug("pull_up orig_h_tasks_notebook=%d orig_w_tasks_notebook=%d",orig_h_tasks_notebook,orig_w_tasks_notebook);
		this.pull_maximized=this.maximized;
		 
		if(this.pull_w<2 || this.pull_h<2){//if start hidden
			//we don't know size , guess
			this.orig_w_tasks_notebook=orig_w_main_vbox=this.pull_w=this.ayobject.terminal_width;
			this.orig_h_tasks_notebook=orig_h_main_vbox=this.pull_h=this.ayobject.terminal_height;

		}
		this.save_current_monitor(this.pull_x,this.pull_y);
		if(!this.animation_enabled){
			this.pull_active=true;
			this.ayobject.clear_prelight_state();
			this.prev_focus=this.get_focus();
			this.iconify ();//this.hide(); use iconify to prevent loss of keyboard layout per window in XFCE.
			this.current_state=WStates.HIDDEN;
			return;
		}
		this.pull_active=true;

		this.height_request=-1;//allow main window resize

		//debug("reparent to offscreen window");
		//this.get_child().reparent(this.pixwin);//reparent to offscreen window
		var ch=this.get_child();//.reparent(this);//reparent from offscreen window
		this.pixwin.set_size_request(pull_w,pull_h);
		this.remove(ch);
		this.pixwin.add(ch);
		
		//set main_vbox size same as original,otherwise draw will be broken
		this.ayobject.main_vbox.height_request = this.orig_h_main_vbox;
		this.ayobject.main_vbox.width_request = this.orig_w_main_vbox;
		//debug("end reparent to offscreen window");

		if(this.maximized){
			//set main_vbox size after unmaximize
			this.width_request=this.pull_w;
			this.height_request=this.pull_h;
			this.check_resize();//container
			
			this.maximized=false;
			this.move(this.pull_x,this.pull_y);
		}else
			this.check_resize();

		//debug("pull_up 0-%d  this.get_allocated_height=%d this.orig_h=%d",this.get_allocated_height()-this.pull_h, this.get_allocated_height(),this.pull_h);
		//debug("pull_up orig_h=%d orig_w=%d",this.pull_h,this.pull_w);
		if (this.get_allocated_height()>1)
			this.pull_step=0;
		else
			this.pull_step=this.pull_steps;//skip animation
		this.pull_animation_active=true;
		this.ayobject.clear_prelight_state();
		this.update_events();//process pixwin.damage_event
		GLib.Timeout.add(this.animation_speed,this.on_pull_up);
	}

	/*public void fake_pullup(){
		 * according to user settings
		 * setup pixwin size,
		 * setup main_vbox size,
		 * setup tasks_notebook,
		 * setup all nesessary variables for pull down
		 * reparent to pix win
		 * Think, is it worth it? }*/

	public void toggle_window(){
		debug("toggle_window start");
		if(this.pull_animation_active || this.conf.standalone_mode) return;
		/* when hotkey is pressed, main window loose focus,
		 * so impossible to check, is windows focused or not.
		 * as workaround, remember last focus-out time,
		 * if it more than 100ms, then window was unfocused
		 * */
		 X.Window w=this.hotkey.get_input_focus();
		 var slf_win=this.get_window();
		 if(slf_win!=null)
			debug("slf=%d w=%d",(int)Gdk.X11Window.get_xid(slf_win),(int)w);
		//debug("toggle_window %d %d",(int)this.last_event_time,(int)this.hotkey.last_focus_out_event_time);
		//&& !this.is_active && (this.current_state == WStates.VISIBLE) && ((int)this.hotkey.last_key_event_time-(int)this.last_focus_out_event_time)>100
		if(this.current_state==WStates.VISIBLE && !this.keep_above && slf_win!=null && Gdk.X11Window.get_xid(slf_win) != w ){
			this.window_set_active();
			return;
		}

		if(this.current_state == WStates.HIDDEN)
				this.pull_down();
			else
				this.pull_up();
		debug("toggle_window end");
	}

	public override bool window_state_event (Gdk.EventWindowState event){
//~	public bool window_state_event2 (Gdk.EventWindowState event){
//~ 		debug("window_state_event type=%d new_state=%d mask=%d",(int)event.type,(int)event.new_window_state,(int)event.changed_mask);
		var ret=base.window_state_event(event);
		debug("window_state_event !!!!!!!!! this.maximized=%d event.changed_mask=%d",(int)this.maximized,event.changed_mask);
		
			//ignore maximize event when pull active
			if( (event.changed_mask & Gdk.WindowState.FULLSCREEN)==Gdk.WindowState.FULLSCREEN ){//maximize state change
				debug("changed_mask FULLSCREEN");
				if(!this.pull_active && !this.pull_animation_active && !this.conf.standalone_mode){
					if( (this.my_window_state & MYWINStates.MAXIMIZED) != MYWINStates.MAXIMIZED)
						this.maximized = false;//some WMs set FULLSCREEN flag when window maximized
				}
			}
			
			if( (event.changed_mask & Gdk.WindowState.MAXIMIZED)==Gdk.WindowState.MAXIMIZED ){//maximize state change
				this.wait_window_manager=false;
				if(!this.pull_active && !this.pull_animation_active && !this.conf.standalone_mode){
					if((Gdk.WindowState.MAXIMIZED & event.new_window_state)== Gdk.WindowState.MAXIMIZED){//maximize
						debug("new state maximize");
						this.my_window_state |= MYWINStates.MAXIMIZED;
						this.update_position_size();							
					}else{//unmaximize
						debug("new state unmaximize");
						this.my_window_state &= ~MYWINStates.MAXIMIZED;
						this.configure_position();
						this.update_position_size();
					}
				}
			}

			if( (event.changed_mask & Gdk.WindowState.ICONIFIED)==Gdk.WindowState.ICONIFIED ){//ICONIFIED state change
				debug("changed_mask ICONIFIED");
				if((event.new_window_state & Gdk.WindowState.ICONIFIED)!=Gdk.WindowState.ICONIFIED){
					//deiconify from window manager
					this.pull_down();
				}
			}	
	return ret;
	//false;//continue
	//base.window_state_event(event);
	}

	public override bool configure_event(Gdk.EventConfigure event){
//~ 		debug("configure_event");
//~ 		debug("event.type=%d window=%d x=%d y=%d width=%d height=%d",event.type,(int)event.window,event.x,event.y,event.width,event.height);
		var ret=base.configure_event(event);
		
		if(this.allow_update_size && this.wait_for_window_position_update>0){
				if(this.update_position_size_for_glib_timer_id == 0)
					this.update_position_size_for_glib_timer_id=GLib.Timeout.add(50,this.update_position_size_for_glib);//recheck position after 50ms			
				return ret;
		}
		
		/*update position and size when window has moved to another monitor*/ 
		if(this.allow_update_size){
			unowned Gdk.Screen gscreen = this.get_screen ();
			int current_monitor = gscreen.get_monitor_at_point (event.x,event.y);
			if(this.orig_monitor != current_monitor){
				debug("configure_event monitor changed");
				/*event on monitor changed*/
				/* if window was dragged by mouse, then window_resize and window_move will not working until user release mouse button
				 * we don't have resize/move events, so we do not know when the user is finished moving
				 */ 
				this.on_monitors_changed_start_time = new DateTime.now_local();
				
				if(this.on_monitor_changed_force_new_position_glib_timer_id != 0)
 					GLib.Source.remove(this.on_monitor_changed_force_new_position_glib_timer_id);
				this.on_monitor_changed_force_new_position_glib_timer_id=GLib.Timeout.add(500,this.on_monitor_changed_force_new_position);//every 0.5s
			}
		}
	return ret;
	}
	
	public bool on_monitor_changed_force_new_position(){
		debug("on_monitor_changed_force_new_position");
		int x,y;
		this.get_position (out x, out y);
		if(!this.allow_update_size)
			return false; //stop
			
		if(this.orig_x == x && this.orig_y == y)
			return false; //stop
			
		this.orig_x=x;//set coordinates in new monitor
		this.orig_y=y;//set coordinates in new monitor
		this.configure_position();//configure position for new monitor

		var now = new DateTime.now_local();
		TimeSpan tdelta = now.difference(this.on_monitors_changed_start_time);
		if(x!=this.orig_x &&  tdelta < (1000000*30) && this.allow_update_size){ //timeout 30 seconds
			this.update_position_size();
			return true; //continue
		}else{
			if(this.on_monitor_changed_force_new_position_glib_timer_id>0)
				this.on_monitor_changed_force_new_position_glib_timer_id=0;
			return false; //stop
		}
	}

	public override bool focus_out_event (Gdk.EventFocus event) {
		this.last_focus_out_event_time=Gdk.x11_get_server_time(this.get_window());
		return base.focus_out_event (event);
	}

	private void check_focusout(){
		debug("check_focusout focus=%d state=%d",(int)this.has_toplevel_focus,(int)this.current_state);
		if( !this.has_toplevel_focus &&
			 this.autohide &&
			!this.pull_active &&
		     this.current_state==WStates.VISIBLE ){
				var slf_win=this.get_window();
				if(slf_win!=null){
					X.Window w=this.hotkey.get_input_focus();
					X.Window slf_xid = Gdk.X11Window.get_xid(slf_win);
					debug("active_window4 slf=%x focus=%x",(int)slf_xid,(int)w);

					if(slf_xid!=w){
						X.Window transient = this.hotkey.get_transient_for_xid(w);
						debug("active_window5 slf=%x transient_for=%x",(int)slf_xid,(int)transient);
						if(transient!=slf_xid)//include transient==0
							this.pull_up();//not exist,hide
					}
				}
		}
	}

	public override  bool draw (Cairo.Context cr){
		if(this.pull_animation_active || this.pull_active){
			cr.save();
			//debug("draw 0-%d  this.get_allocated_height=%d this.orig_h=%d",this.get_allocated_height()-this.pull_h, this.get_allocated_height(),this.pull_h);
			cr.set_source_surface(this.pixwin.get_surface(),0,this.get_allocated_height()-this.pull_h);
			cr.paint();
			cr.stroke ();
			cr.restore();
			return false;
		}else{
			return base.draw(cr);
		}
	}


	public void update_events(){
		while (Gtk.events_pending ()){
			Gtk.main_iteration ();
			Gdk.flush();
			}
	}

	public void display_sync(){
 		var window = this.get_window();
		if(window!=null){
			window.get_display().sync();
		}
	}
	

	
	public void reconfigure(){
		debug("reconfigure VTWindow");

		if(this.conf.reduce_memory_usage){
			var settings = Gtk.Settings.get_default();
			settings.gtk_menu_images=false;
			settings.gtk_button_images=false;
			settings.gtk_enable_animations=false;
			settings.gtk_toolbar_style=Gtk.ToolbarStyle.TEXT;
		}

		//update on reset
		conf.get_boolean("keep_above_at_startup",true);
		conf.get_boolean("start_hidden",false);
		conf.get_string("window_default_monitor","");
		this.allow_close=!conf.get_boolean("confirm_to_quit",true);

		var css_main = new CssProvider ();
		string style_str= ""+
					 "VTToggleButton GtkLabel  { font: Mono 10; -GtkWidget-focus-padding: 0px; -GtkButton-default-border:0px; -GtkButton-default-outside-border:0px; -GtkButton-inner-border:0px; border-width:0px; -outer-stroke-width: 0px; margin:0px; padding:0px;}"+
					 "VTToggleButton {-GtkWidget-focus-padding: 0px;-GtkButton-default-border:0px;-GtkButton-default-outside-border:0px;-GtkButton-inner-border:0px;border-color:alpha(#000000,0.0);border-width: 1px;-outer-stroke-width: 0px;border-radius: 3px;border-style: solid;background-image: none;margin:0px;padding:0px 0px 0px 0px;background-color: alpha(#000000,0.0);color: #AAAAAA; box-shadow: none;}"+
					 "VTToggleButton:active{background-color: #00AAAA;background-image: -gtk-gradient(radial,center center, 0,center center, 1, from (#00BBBB),to (#008888) );color: #000000;}"+
					 "VTToggleButton:prelight {background-color: #AAAAAA;background-image: -gtk-gradient(radial,center center, 0,center center, 1, from (#AAAAAA),to (#777777) ); color: #000000;}"+
					 "VTToggleButton:active:prelight{background-color: #00AAAA;background-image: -gtk-gradient(radial,center center, 0,center center, 1, from (lighter(#00BBBB)),to (#008888) );color: #000000;}"+
					 "VTToggleButton *:selected{ background-color: alpha(#FF0000, 0.4);background-image: none;}"+
					 ".window_multitabs {border-width: 2px 2px 0px 2px;border-color: #3C3B37;border-style: solid;padding:0px;margin:0;}"+
					 ".window_single_tab {border-width: 2px 2px 2px 2px;border-color: #3C3B37;border-style: solid;}"+
					 "#terms_notebook {border-width: 0px;border-style: solid;padding:0px;margin:0;}"+
					 "#search_hbox :active { border-color: @fg_color; color: #FF0000;}"+
					 "#search_hbox :prelight { background-color: alpha(#000000,0.0); border-color: @fg_color; color: #FF0000;}"+
					 "#search_hbox {border-width: 0px 0px 0px 0px; -outer-stroke-width: 0px; border-radius: 0px 0px 0px 0px; border-style: solid;  background-image: none; margin:0px; padding:0px 0px 1px 0px; background-color: #000000; border-color: @bg_color; color: #00FFAA;}"+
					 "HVBox {border-width: 0px 2px 2px 2px; border-color: #3C3B37;border-style: solid; background-color: #000000;}"+
					 "#OffscreenWindow, VTMainWindow,#HVBox_dnd_window {border-width: 0px; border-style: solid; background-color: alpha(#000000,0.1);}"+
					 "HVBox,#quick_options_notebook{background-color: alpha(#000000,1.0);}"+
					 "#settings-scrolledwindow{ background-color: @bg_color;}"+
					 "";

		if(Gtk.get_major_version()>=3 && Gtk.get_minor_version()>4)
			style_str+= "VTToggleButton{transition-duration: 0s;}";

		if(Gtk.get_major_version()>=3 && Gtk.get_minor_version()>6)//special eyecandy if supported ;)
			style_str+= "VTToggleButton:active { text-shadow: 1px 1px 2px #005555;}";

		//prevent  transparency of window background in  standalone mode
		if(conf.standalone_mode)
			style_str+= "#OffscreenWindow, VTMainWindow,#HVBox_dnd_window {background-color: alpha(#000000,1.0);}";

			//todo: bad performance on pull_up. when tab state is prelight then, on every animation step happens recursive size recalculation
			//style_str+= "VTToggleButton { transition: 400ms ease-in-out;} VTToggleButton:active { transition: 0ms ease-in-out;text-shadow: 1px 1px 2px #005555;} VTToggleButton:prelight {transition: 0ms ease-in-out;}";

		css_main.parsing_error.connect((section,error)=>{
			debug("css_main.parsing_error %s",error.message);
			});

		try{
			css_main.load_from_data (this.conf.get_string("program_style",style_str),-1);
			Gtk.StyleContext.add_provider_for_screen(this.get_screen(),css_main,Gtk.STYLE_PROVIDER_PRIORITY_USER);
		}catch (Error e) {
			debug("Theme error! loading default..");
			try{
				css_main.load_from_data (style_str,-1);
				Gtk.StyleContext.add_provider_for_screen(this.get_screen(),css_main,Gtk.STYLE_PROVIDER_PRIORITY_USER);
			}catch (Error e) {
				debug("Theme error! default theme is broken!");
			}
		}

		this.animation_enabled=conf.get_boolean("animation_enabled",true);
		this.pull_steps=conf.get_integer("animation_pull_steps",10,(ref new_val)=>{
				if(new_val<1){new_val=10;return CFG_CHECK.REPLACE;}
				return CFG_CHECK.OK;
			});

		this.hotkey.unbind();
		if(!this.conf.disable_hotkey){
			KeyBinding grave=this.hotkey.bind (this.conf.get_accel_string("main_hotkey","<Alt>grave"));
			if(grave!=null)
				grave.on_trigged.connect(this.toggle_window);
			else{
				var new_key = this.conf.get_accel_string("main_hotkey","<Alt>grave");
				do{
					new_key = this.ShowGrabKeyDialog(new_key);
					if(this.ayobject!=null && this.ayobject.action_group!=null){
						/*update main_hotkey on reset*/
						var action = this.ayobject.action_group.get_action("main_hotkey");
						if(action!=null){
							uint accelerator_key;
							Gdk.ModifierType accelerator_mods;							
							Gtk.accelerator_parse(new_key,out accelerator_key,out accelerator_mods);
							if(accelerator_key!=0){
								if(this.ayobject.update_action_keybinding(action,accelerator_key,accelerator_mods))
									grave=this.hotkey.bind (new_key);//if new_key is not used for other actions then, try to bind
							}
						}
					}else{
						grave=this.hotkey.bind (new_key);//currently we have no actions, try to bind
					}
				}while(grave==null && !this.allow_close);
				
				if(this.allow_close) return;//possible on destroying
				
				this.conf.set_accel_string("main_hotkey",new_key);
				grave.on_trigged.connect(this.toggle_window);
			}
		}else{
			this.conf.get_accel_string("main_hotkey","<Alt>grave");//just read option
		}

		this.mouse_follow  = conf.get_boolean("follow_the_white_rabbit",false);
		this.gravity_north_west  = conf.get_boolean("window_gravity_north_west",true);
		if(this.gravity_north_west)
			this.gravity=Gdk.Gravity.NORTH_WEST;
		else
			this.gravity=Gdk.Gravity.SOUTH_WEST;
		this.autohide  = conf.get_boolean("window_autohide",false);
	}//reconfigure

	public bool configure_position(){
			unowned Gdk.Screen gscreen = this.get_screen ();
			debug("x=%d,y=%d",this.orig_x,this.orig_y);
			int current_monitor;

			if(this.mouse_follow){
				X.Display display = new X.Display();
				X.Event event = X.Event();
				X.Window window = display.default_root_window();

				display.query_pointer(window, out window,
				out event.xbutton.subwindow, out event.xbutton.x_root,
				out event.xbutton.y_root, out event.xbutton.x,
				out event.xbutton.y, out event.xbutton.state);
				current_monitor = gscreen.get_monitor_at_point (event.xbutton.x,event.xbutton.y);
			}else
			    current_monitor = gscreen.get_monitor_at_point (this.orig_x,this.orig_y);

			if(this.orig_monitor != current_monitor)
				this.orig_monitor=current_monitor;
			    
			string? monitor_name = gscreen.get_monitor_plug_name (current_monitor);
			
			if(monitor_name==null){
				monitor_name="null";
				//return false;//bad idia! can happen at startup. get_monitor_plug_name asynchronous?
			}
				
			debug("monitor name %s %d",monitor_name,current_monitor);
			Gdk.Rectangle rectangle;
			
			/* gdk_screen_get_monitor_workarea returns workarea only for the primary monitor.
			 * and only when primary monitor is on the left side
			 * */
			rectangle=gscreen.get_monitor_workarea(current_monitor);
			debug("monitor_workarea x=%d,y=%d w=%d h=%d",rectangle.x,rectangle.y,rectangle.width,rectangle.height);

			/*get width,height,window_position_x,window_position_y for current monitor*/
			int w = conf.get_integer("terminal_width_%s".printf(monitor_name),80,(ref new_val)=>{
				if(new_val < 1){new_val = 80; return CFG_CHECK.REPLACE;}
				return CFG_CHECK.OK;
			});//if less 101 then it persentage
		
			int h = conf.get_integer("terminal_height_%s".printf(monitor_name),50,(ref new_val)=>{
				if(new_val < 1){new_val = 50; return CFG_CHECK.REPLACE;}
				return CFG_CHECK.OK;
			});//if less 101 then it persentage
			
			int pos_y = conf.get_integer("window_position_y_%s".printf(monitor_name),-1,(ref new_val)=>{
				if(new_val<-1){new_val=-1;return CFG_CHECK.REPLACE;}
				return CFG_CHECK.OK;
			});//if less 101 then it persentage

			this.position  = conf.get_integer("window_position_x_%s".printf(monitor_name),1,(ref new_val)=>{
				if(new_val>3 || new_val<0){new_val=1;return CFG_CHECK.REPLACE;}
				return CFG_CHECK.OK;
				});
			
			debug("settings for monitor x=%d,y=%d w=%d h=%d",this.position,pos_y,w,h);
			
			this.fullscreen_on_maximize = conf.get_boolean("window_fullscreen_on_maximize",false);
			var max_tmp = conf.get_boolean("window_start_maximized",false);
//~ 
			if(this.start_maximized!=max_tmp){
				this.start_maximized=max_tmp;//start_maximized store previous state of max_tmp
				this.config_maximized=max_tmp;//config_maximized store window state, which is should be
			}
			if(h==100)
				this.maximized=true;

			/*calculate window size according to config_maximized*/
			if(this.maximized){
				/*used in pull_up, only if start hidden*/
				pos_y = (int)rectangle.height/4;//workaroud, for bug with gdk_screen_get_monitor_workarea when window_start_maximized==true
			}else{

				if(w<101){
					this.ayobject.terminal_width=(int)(((float)rectangle.width/100.0)*(float)w);
				}else{
					this.ayobject.terminal_width=w;
				}

				if(h<101){
					this.ayobject.terminal_height=(int)(((float)rectangle.height/100.0)*(float)h);
				}else{
					this.ayobject.terminal_height=h;
				}
			}

			switch(this.position){
				case 0://left
					this.orig_x=rectangle.x;
				break;
				case 1://center
					this.orig_x=rectangle.x+((rectangle.width/2)-(this.ayobject.terminal_width/2));
				break;
				case 2://right
					this.orig_x=rectangle.x+(rectangle.width-this.ayobject.terminal_width);
				break;
			}

			//this.orig_x=rectangle.x;
			if(pos_y < 0){// auto position
				if(this.gravity_north_west)
					this.orig_y=rectangle.y;
				else
					this.orig_y=rectangle.y+rectangle.height;
			}else{ //manual position
				this.orig_y = pos_y;
			}

			debug("configure_position end x=%d,y=%d term_w=%d term_h=%d",this.orig_x,this.orig_y,this.ayobject.terminal_width,this.ayobject.terminal_height);
			return true;
	}//configure_position


		public void window_set_active(){

		if(this.current_state==WStates.VISIBLE){

			if(this.keep_above && this.conf.standalone_mode==false){
				this.skip_taskbar_hint = true;
				this.set_keep_above(true);
				//this.show ();//first show then send_net_active_window!
				if(this.orig_stick)
					this.stick();
				this.present() ;
			}else{
				this.skip_taskbar_hint = false;
				this.set_keep_above(false);
			}

			this.hotkey.send_net_active_window(this.get_window ());
			if(this.prev_focus!=null)
				this.prev_focus.grab_focus();
			else
				if(this.ayobject!=null && this.ayobject.active_tab!=null)//this.ayobject==null possible at startup
					this.ayobject.activate_tab(this.ayobject.active_tab);
		}
	}


	public string ShowGrabKeyDialog(string? prev_bind=null){

			var title=_("Please select key combination, to show/hide AltYo.");
			if(prev_bind!=null)
				title+="\n"+_("Previous key '%s' incorrect or busy").printf(prev_bind);
			Gtk.MessageType message_type=Gtk.MessageType.OTHER;	
			var settings = Gtk.Settings.get_default();
			if(settings.gtk_menu_images){
				message_type = MessageType.QUESTION;
			}
		
		
			var dialog = new MessageDialog (null, (DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL), message_type, ButtonsType.OK, title);
			var aLabel = new Label(_("Press any key"));
			var dialog_box = ((Gtk.Box)dialog.get_content_area ());
			dialog_box.pack_start(aLabel,false,false,0);
			aLabel.show();

			var grab_another_key = new Button.with_label(_("Grab another key."));
			grab_another_key.clicked.connect(()=>{
				grab_another_key.sensitive=false;
				dialog.set_response_sensitive(Gtk.ResponseType.OK,false);
				});

			((Gtk.ButtonBox)dialog.get_action_area ()).pack_start(grab_another_key,false,false,0);
			grab_another_key.show();
			grab_another_key.sensitive=false;

			dialog.focus_out_event.connect (() => {
				return true; //same bug as discribed in this.focus_out_event
				});

			dialog.set_response_sensitive(Gtk.ResponseType.OK,false);
			dialog.set_transient_for(this);
			dialog.show ();
			//disable close by window manager
			Gdk.Window w = dialog.get_window();
			w.set_functions((Gdk.WMFunction.ALL|Gdk.WMFunction.CLOSE));
			dialog.grab_focus();
			this.hotkey.send_net_active_window(dialog.get_window ());
			string accelerator_name="";

			dialog.key_press_event.connect((widget,event) => {
					unowned Button ok = (Button)dialog.get_widget_for_response(Gtk.ResponseType.OK);
					if(!ok.sensitive)
						if (Gtk.accelerator_valid (event.keyval, event.state))
						/*See GDK_KEY_* in gdk/gdkkeysyms.h (not available in Vala)*/
							if(event.keyval!=0xff1b && /*GDK_KEY_Escape*/
							   event.keyval!=0xff0d && /*GDK_KEY_Return*/
							   event.keyval!=0xff08    /*GDK_KEY_BackSpace*/
							   ){
								event.state &= Gtk.accelerator_get_default_mod_mask();
								accelerator_name = Gtk.accelerator_name (event.keyval, event.state);
								aLabel.label = Gtk.accelerator_get_label  (event.keyval, event.state);
								ok.sensitive=true;
								ok.grab_focus();
								grab_another_key.sensitive=true;
							}
					if(event.keyval!=0xff1b && ok.sensitive)
						return false;
					else
						return true; //true == ignore event
				});//tab_button_press_event
			int result = dialog.run();
			dialog.destroy ();
			if(result != Gtk.ResponseType.NONE)
				this.window_set_active();
			return accelerator_name;
	}

	public void show_message_box(string title,string message){
			Gtk.MessageType message_type=Gtk.MessageType.OTHER;	
			var settings = Gtk.Settings.get_default();
			if(settings.gtk_menu_images){
				message_type = MessageType.QUESTION;
			}		
			var dialog = new MessageDialog (null, (DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL), message_type, ButtonsType.OK, title);
			var aLabel = new Label(message);
			var dialog_box = ((Gtk.Box)dialog.get_content_area ());
			dialog_box.pack_start(aLabel,false,false,0);
			aLabel.show();
			dialog.set_transient_for(this);
			dialog.show_all();
			dialog.grab_focus();
			this.hotkey.send_net_active_window(dialog.get_window ());
			int result = dialog.run();
			dialog.destroy ();
			if(result != Gtk.ResponseType.NONE)
				this.window_set_active();
	}//show_message_box
	

	public void update_position_size(bool force_sync=true){
				debug ("update_position_size start maximized=%d this.my_window_state=%d",(int)this.maximized,this.my_window_state);

				if(this.conf.standalone_mode){
					this.width_request=-1;//allow main window resize
					this.height_request=-1;//allow main window resize
					 return;
				 }else
					this.ayobject.on_maximize(this.maximized);	//update terminal align policy



				/* update position only in unmaximized mode
				 * */
				if((this.my_window_state & MYWINStates.MAXIMIZED) == 0){
					this.fullscreened=false;
					debug("terminal w=%d h=%d",this.ayobject.terminal_width,this.ayobject.terminal_height);
					/*set terminal size in non maximized mode*/
					this.ayobject.main_vbox.width_request=-1;
					this.ayobject.main_vbox.height_request=-1;					
					this.ayobject.tasks_notebook.width_request=this.ayobject.terminal_width;
					this.ayobject.tasks_notebook.height_request=this.ayobject.terminal_height;
					int should_be_h=this.ayobject.get_altyo_height();
					int allocated_height=this.get_allocated_height();
					if(allocated_height>should_be_h){
						this.resize(this.ayobject.terminal_width,should_be_h);
						this.move (this.orig_x,this.orig_y);
						this.wait_for_window_position_update=5;//wait while movement will be confirmed in configure_event 
						debug("WINDOW update_position_size resize!!! %d",should_be_h);
					}else{
						this.move (this.orig_x,this.orig_y);
					}
						
					debug ("update_position_size should_be_h=%d terminal_width=%d x=%d y=%d",should_be_h,this.ayobject.terminal_width,this.orig_x,this.orig_y) ;
				}else{
					this.ayobject.tasks_notebook.width_request=-1;
					this.ayobject.tasks_notebook.height_request=-1;
					this.ayobject.main_vbox.width_request=-1;
					this.ayobject.main_vbox.height_request=-1;
					this.check_resize();
					debug("update_position_size maximized mode");
				}
	}
	
	public bool update_position_size_for_glib(){
		this.update_position_size_for_glib_timer_id=0;
		this.check_position();
		return false;
	}
	
	private void check_position(){
		debug("check_position");
		if( this.allow_update_size && (this.my_window_state & MYWINStates.MAXIMIZED) == 0 ){
			if(this.wait_for_window_position_update>0){
				int x,y;
				this.get_position(out x,out y);
				if(x != this.orig_x /*|| event.y != this.orig_y*/){
					this.move(this.orig_x,this.orig_y);
					this.wait_for_window_position_update--;
					debug("check_size this.wait_for_window_position_update=%d",(int)this.wait_for_window_position_update);
					if(this.update_position_size_for_glib_timer_id == 0)
						this.update_position_size_for_glib_timer_id=GLib.Timeout.add(50,this.update_position_size_for_glib);//recheck size after 50ms
					return; //prevent GLib.Source.remove
				}else
					this.wait_for_window_position_update=0;
			}
		}
		
		/*stop timer if not needed*/
		if(this.update_position_size_for_glib_timer_id!=0 && GLib.Source.remove(this.update_position_size_for_glib_timer_id))
			this.update_position_size_for_glib_timer_id=0;
	}
	
	/* get_preferred_height_for_width -> allow_update_size? is it necessary? -> resize() -> get_preferred_height_for_width (new limited size)
	 * */
	public override void get_preferred_height_for_width (int width,out int minimum_height, out int natural_height) {
		base.get_preferred_height_for_width (width,out minimum_height, out natural_height);
		natural_height=minimum_height;//always minimize height!
		if(this.allow_update_size) {
			//constrain window size in non maximized mode
			int allocated_height=this.get_allocated_height();
			int allocated_width=this.get_allocated_width();
			
			if( (allocated_height>minimum_height || allocated_width>this.ayobject.terminal_width) && this.ayobject!=null ){
				/* queueing resize, if set_size_request is used nowhere, then resize should be completed in one step
				 * simple, powerfull and fast*/
				this.resize(this.ayobject.terminal_width,minimum_height);
				debug("get_preferred_height_for_width resize!");
			}
			if(this.wait_for_window_position_update>0)
				this.check_position();
		}
//~		debug("WINDOW get_preferred_height_for_width width=%d minimum_height=%d, natural_height=%d  get_allocated_height=%d",width,minimum_height, natural_height,this.get_allocated_height());
	}//get_preferred_height_for_width

}//class VTMainWindow

/*********************************************************************/
/*********************************************************************/
/*********************************************************************/
/*********************************************************************/
/*********************************************************************/
/*********************************************************************/
/*********************************************************************/

public class AYObject :Object{
	public Gtk.ActionGroup action_group;
	public Gtk.AccelGroup  accel_group;

	public bool save_session = false;

	private int double_hotkey_milliseconds = 0;
	private int double_hotkey = 0;
	private int double_hotkey_level = 0;
	private DateTime double_hotkey_last_time = null;

//~ 	public Overlay main_overlay {get;set;}
//~ 	public MyOverlayBox main_overlay {get;set;}
	public VTMainWindow main_window;
	public Notebook terms_notebook {get; set;}
	public Notebook tasks_notebook {get; set;}
	public Notebook overlay_notebook {get; set;}
	public HVBox hvbox {get;set;}
	public QoptNotebook quick_options_notebook {get; set;}
	public unowned VTToggleButton active_tab {get;set; default = null;}
	public unowned VTToggleButton previous_active_tab {get;set; default = null;}
	public unowned MySettings conf {get;set; default = null;}
	//public Gtk.Window win {get;set; default = null;}

	public Gtk.Box main_vbox  {get;set;}

	public TAB_SORT_ORDER tab_sort_order {get;set; default = TAB_SORT_ORDER.NONE;}


	private GLib.List<unowned AYTab> children;
	private GLib.List<unowned AYTab> children_removed;
	public int terminal_width {get;set; default = 80;}
	public int terminal_height {get;set; default = 50;}
	private int hvbox_height_old {get;set; default = 0;}
	//public bool maximized {get; set; default = false;}
	//private bool quit_dialog {get; set; default = false;}

	private AYSettings aysettings;
	private bool aysettings_shown=false;
	private int action_on_close_last_tab=0;
	private int new_tab_position=0;
	private int hvbox_display_mode=0;

	public AYObject(VTMainWindow _MW ,MySettings _conf) {
		debug("AYObject new");
		this.conf=_conf;
		this.main_window=_MW;

		this.main_vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);//new VBox(false,0);
		this.main_vbox.halign=Gtk.Align.FILL;
		this.main_vbox.valign=Gtk.Align.START;
		this.main_vbox.expand=false;
		this.main_vbox.name="main_vbox";
		this.main_vbox.show();


		this.terms_notebook = new Notebook() ;
//~		this.terms_notebook.halign=Gtk.Align.FILL;
//~		this.terms_notebook.valign=Gtk.Align.START;
		this.terms_notebook.expand=false;

		this.terms_notebook.name="terms_notebook";
		this.terms_notebook.set_show_tabs(false);//HVBox will have tabs ;)

		//this.terms_notebook.set_show_border(false);

		this.tasks_notebook = new Notebook();
//~ 		this.tasks_notebook.halign=Gtk.Align.START;
//~ 		this.tasks_notebook.valign=Gtk.Align.START;
		this.tasks_notebook.expand=false;
		this.tasks_notebook.name="tasks_notebook";
		this.tasks_notebook.set_show_tabs(false);
		this.tasks_notebook.insert_page(terms_notebook,null,TASKS.TERMINALS);
		this.tasks_notebook.switch_page.connect(on_switch_task);
		unowned Gtk.StyleContext context = this.tasks_notebook.get_style_context();
		context.add_class("window_multitabs");

		this.save_session    = conf.get_boolean("autosave_session",false);

		this.hvbox = new HVBox();
		this.hvbox.halign=Gtk.Align.FILL;
		this.hvbox.valign=Gtk.Align.START;
		this.hvbox.expand=false;

		this.hvbox.child_reordered.connect(this.move_tab);
		this.hvbox.on_dnd_above_changed.connect((dnd_widget,above_widget)=>{
			VTToggleButton dnd = (VTToggleButton) dnd_widget;
			VTToggleButton above = (VTToggleButton) above_widget;
			dnd.set_title((int)(this.children.index((AYTab)above.object)),null);
			});
//~		this.hvbox.size_changed.connect(this.hvbox_size_changed);

		this.hvbox.can_focus=false;//vte shoud have focus
		this.hvbox.can_default = false;
		this.hvbox.has_focus = false;
		
		//double click on empty space will open new tab
		this.main_window.add_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		this.main_window.button_press_event.connect((event)=>{
			int dest_x,dest_y;
			if(event.type==Gdk.EventType.@2BUTTON_PRESS){
				this.hvbox.translate_coordinates(this.main_window,0,0,out dest_x, out dest_y);
				//check is event was inside hvbox
				if( (event.x>dest_x && event.x < (dest_x + this.hvbox.get_allocated_width())) &&
					(event.y>dest_y && event.y < (dest_y + this.hvbox.get_allocated_height())) ){
					this.add_tab();
					return true;//stop other handlers
				}
			}
			return false;//continue
			});

		this.quick_options_notebook = new QoptNotebook(this);
		
		//this.main_vbox.pack_start(this.tasks_notebook,true,true,0);//maximum size

		#if HAVE_QLIST
		var qlist = new QList(this.conf);
		qlist.win_parent=this;
		this.tasks_notebook.insert_page(qlist,null,TASKS.QLIST);
		#endif

		/*this.main_overlay = new MyOverlayBox();//Gtk.Overlay();
		this.main_overlay.show();
		this.main_overlay.add(this.tasks_notebook);

		this.overlay_notebook = new Notebook() ;
		this.overlay_notebook.set_show_tabs(false);

		this.main_overlay.add_overlay(this.overlay_notebook);*/

		//this.main_vbox.pack_start(this.main_overlay,true,true,0);//maximum size
		this.main_vbox.pack_start(this.tasks_notebook,true,true,0);//maximum size


		//this.main_vbox.pack_start(notebook,true,true,0);//maximum size
		this.main_vbox.pack_start(this.quick_options_notebook,false,false,0);//minimum size
		this.main_vbox.pack_start(hvbox,false,false,0);//minimum size

		this.reconfigure();
		this.main_vbox.show_all();

		this.quick_options_notebook.hide();//search hidden by default
		//this.overlay_notebook.hide();//this.overlay_notebook hidden by default
		this.tasks_notebook.set_current_page(TASKS.TERMINALS);//this.overlay_notebook hidden by default


		//this.setup_keyboard_accelerators() ;
		#if HAVE_QLIST
		qlist.setup_keyboard_accelerators();
		#endif

		this.conf.on_load.connect(()=>{
			this.reconfigure();
			});

	}//CreateAYObject
	
	public bool create_tabs(){
		if(Globals.exec_file_with_args!=null){
			if(Globals.standalone_mode){
				this.action_on_close_last_tab=2;//quit
				this.hvbox_display_mode=HVBOXDISPLAY.HIDEIFONETAB;
				return false;
			}
		}

		var autostart_terminal_session=this.conf.get_string_list("terminal_autostart_session",null);
		if(autostart_terminal_session != null && autostart_terminal_session.length>0){
			foreach(var s in autostart_terminal_session){
				if(s!=""){
					this.add_tab_with_title(s,s);
				}
			}
		}

		var restore_terminal_session=this.conf.get_string_list("terminal_session",null);
		if(restore_terminal_session != null && restore_terminal_session.length>0){
			foreach(var s in restore_terminal_session){
				if(s!=""){
					this.add_tab_with_title(s,s);
				}
			}
		}

		if(this.children.length()==0)
			this.add_tab();

		
		return false;
	}


	public void reconfigure(){
		debug("reconfigure AYObject");

		//add type into type array
		this.conf.get_boolean("terminal_new_tab_in_current_directory",true);
		this.conf.get_string("terminal_prevent_close_regex","/?ssh\\ ?|/?scp\\ ?|/?wget\\ ?|/?rsync\\ ?|/?curl\\ ?");
		this.conf.get_string("terminal_session_exclude_regex","/?zsh\\ ?|/?mc\\ ?|/?bash\\ ?|/?screen\\ ?|/?tmux\\ ?");
		/* 0 - restart shell
		 * 1 - restart shell, hide
		 * 2 - quit
		 * */
		this.action_on_close_last_tab=this.conf.get_integer("window_action_on_close_last_tab",(Globals.standalone_mode?2:0),(ref new_val)=>{
			if(new_val>2){ new_val=1; return CFG_CHECK.REPLACE;}
			if(new_val<0){ new_val=0; return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			});
			
// this.terminal_width and
// this.terminal_height will be updated in VTMainWindow.configure_position
//
//~		this.terminal_width = conf.get_integer("terminal_width_%s".printf(monitor_name),80,(ref new_val)=>{
//~			if(new_val<1){new_val=this.terminal_width;return CFG_CHECK.REPLACE;}
//~			return CFG_CHECK.OK;
//~			});
//~			
//~		this.terminal_height = conf.get_integer("terminal_height_%s".printf(monitor_name),50,(ref new_val)=>{
//~			if(new_val<1){new_val=this.terminal_height;return CFG_CHECK.REPLACE;}
//~			return CFG_CHECK.OK;
//~			});

		this.hvbox.background_only_behind_widgets= !conf.get_boolean("tab_box_have_background",false);

		this.save_session  = conf.get_boolean("autosave_session",false);
		this.double_hotkey_milliseconds=conf.get_integer("double_hotkey_milliseconds",500)*1000;
		string ret = conf.get_string("tab_sort_order","none");
			switch(ret){
				case "none":
					this.tab_sort_order=TAB_SORT_ORDER.NONE;
				break;
				case "hostname":
					this.tab_sort_order=TAB_SORT_ORDER.HOSTNAME;
				break;
				default:
					this.tab_sort_order=TAB_SORT_ORDER.NONE;
					conf.set_string("tab_sort_order","none");
				break;
				}

		/* 0 - NEW_TAB_MODE.RIGHT_NEXT
		 * 1 - NEW_TAB_MODE.FAR_RIGHT
		 * */
		this.new_tab_position=this.conf.get_integer("window_new_tab_position",NEW_TAB_MODE.FAR_RIGHT,(ref new_val)=>{
			if(new_val>1){ new_val=NEW_TAB_MODE.FAR_RIGHT; return CFG_CHECK.REPLACE;}
			if(new_val<0){ new_val=NEW_TAB_MODE.FAR_RIGHT; return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			});


		this.setup_keyboard_accelerators();
		/* 0 - HVBOXDISPLAY.VISIBLE
		 * 1 - HVBOXDISPLAY.HIDDEN
		 * 2 - HVBOXDISPLAY.HIDEIFONETAB
		 * */
		this.hvbox_display_mode=this.conf.get_integer("window_hvbox_display_mode",(Globals.standalone_mode?HVBOXDISPLAY.HIDEIFONETAB:HVBOXDISPLAY.VISIBLE),(ref new_val)=>{
			if(new_val>HVBOXDISPLAY.HIDEIFONETAB){ new_val=HVBOXDISPLAY.VISIBLE; return CFG_CHECK.REPLACE;}
			if(new_val<0){ new_val=HVBOXDISPLAY.VISIBLE; return CFG_CHECK.REPLACE;}
			return CFG_CHECK.OK;
			});
	}

	public VTTerminal add_tab(string? session_command=null,string? session_path=null,OnChildExitCallBack? on_exit=null) {
		VTTerminal vt;
		int index;//must be assigned!

		if(this.new_tab_position==NEW_TAB_MODE.RIGHT_NEXT)
			index=this.hvbox.children_index(this.active_tab);
		else
			index=(int)this.children.length();//NEW_TAB_MODE.FAR_RIGHT
		
		if(on_exit==null){
			vt = new VTTerminal(this.conf,this.terms_notebook,index,session_command,(session_path!=null?session_path:conf.default_path),(terminal)=>{		
				/* if child exited (guess by ctrl+d) and it was last tab
				 * and action_on_close_last_tab==quit then quit*/
				if(this.children.length()==1 && this.action_on_close_last_tab==2){//quit
					this.main_window.allow_close=true;
					this.main_window.destroy();
					return;
				}else{
					if(terminal.auto_restart && terminal.session_command==null){//restart shell if allowed
						string S=_("Shell terminated.")+"\n\r\n\r";
						debug(S);
						terminal.vte_term.feed(S,S.length);
						terminal.start_shell();
					}else{//or close tab
						this.close_tab(this.hvbox.children_index(terminal.tbutton));
					}
				}
				
			});
		}else{
			vt = new VTTerminal(this.conf,this.terms_notebook,index,session_command,session_path,on_exit );
		}
		index++;//next position
		this.children.insert( vt ,(int) index);

		vt.vte_term.window_title_changed.connect( () => {
			this.title_changed((Vte.Terminal)vt.vte_term);
        } );

		vt.tbutton.button_press_event.connect(tab_button_press_event);
		this.hvbox.insert( vt.tbutton ,(int) index);


		this.activate_tab(vt.tbutton) ;//this.active_tab = this.hvbox.children_index(tbutton);

		if(this.new_tab_position==NEW_TAB_MODE.RIGHT_NEXT)
			this.update_tabs_title();

		this.search_update();
		return vt;
	}

	public VTTerminal add_tab_with_title(string title,string session_command,string? session_path=null) {
		var vt=this.add_tab(session_command,session_path);
		var tab_index =  this.children.index(vt);
		vt.tbutton.set_title(tab_index,title);
		return vt;
	}

	private bool confirm_close_tab(string question){
		bool close=true;
		Gtk.MessageType message_type=Gtk.MessageType.OTHER;	
		var settings = Gtk.Settings.get_default();
		if(settings.gtk_menu_images){
			message_type = MessageType.QUESTION;
		}			
		var dialog = new MessageDialog (null, (DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL), message_type, ButtonsType.YES_NO, question);
		dialog.response.connect ((response_id) => {
			if(response_id == Gtk.ResponseType.YES)
				close=true;
			else
				close=false;
		});

		dialog.focus_out_event.connect (() => {
			return true; //same bug as discribed in this.focus_out_event
			});
		dialog.set_transient_for(this.main_window);
		dialog.show ();
		dialog.grab_focus();
		this.main_window.hotkey.send_net_active_window(dialog.get_window ());
		int result = dialog.run();
		dialog.destroy ();
		if(result != Gtk.ResponseType.NONE)
			this.main_window.window_set_active();
		return close;
	}

	public void on_tab_remove_timeout(AYTab vtt){
			this.children_removed.remove(vtt);
	}
	
	public void close_tab (int tab_position){
		unowned VTToggleButton tab_button=(VTToggleButton)this.hvbox.children_nth(tab_position);
		if(tab_button==null) return;

		//unowned
		AYTab vtt = ((AYTab)tab_button.object);
		if(vtt is VTTerminal){
			bool close=true;
			VTTerminal vt=(VTTerminal)vtt;
			if(vt.tbutton.prevent_close){
				if(!this.confirm_close_tab(_("Tab is locked, are you sure you want to close?"))){
					return;//prevent close
				}else{
					vt.tbutton.prevent_close=false;
					vt.tbutton.reconfigure();
				}
			}
			
			var prevent_s = this.conf.get_string("terminal_prevent_close_regex","",(ref new_val)=>{
			string err;
			if(!this.conf.check_regex(new_val,out err)){
				debug(_("terminal_prevent_close_regex wrong value! will be used default value. err:%s"),err);
				return CFG_CHECK.USE_DEFAULT;
			}

			return CFG_CHECK.OK;
			});

			GLib.Regex? grx_exclude=null;

			if(prevent_s !=null && prevent_s != "" )
				grx_exclude = new GLib.Regex(prevent_s);

			string[] childs = {};
			childs+=vt.find_tty_pgrp(vt.pid,FIND_TTY.CMDLINE);
			var tmp_spid=vt.find_tty_pgrp(vt.pid,FIND_TTY.PID);
			if(tmp_spid!=null && tmp_spid!=""){
				foreach(string s in vt.find_all_suspended_pgrp(int.parse(tmp_spid))){
					childs+=s;
				}
			}
			foreach(string ch in childs){
				debug("checking %s",ch);
				if(grx_exclude!=null && grx_exclude.match_all(ch,0,null)){
					var q=_("Found important task \"%s\"").printf(ch);
					q+="\n"+_("Close tab anyway?");
					if(!this.confirm_close_tab(q)){
						close=false;
					}
				}
				if(!close)
					return;//prevent close
			}
		}
		
//~ 		if(this.children.length()==1 && !this.conf.get_boolean("terminal_auto_restart_shell",true)){
//~ 			this.ShowQuitDialog();
//~ 			if(this.main_window.allow_close) return;//exit now, window is terminating
//~ 		}

		this.hvbox.remove(tab_button);
		if(tab_button==this.active_tab)
			this.active_tab=null;

		this.children.remove(vtt);


		bool switch_to_previous=false;
		if(vtt is VTTerminal){
			/* delayed remove
			 * 
			 * 1) remove AYTab from children
			 * 2) append to children_removed
			 * 3) run timer
			 * 4.1) if timer finished and not lock_tab_remove
			 * 4.1.1) remove from children_removed
			 * 4.1.2) destroy object
			 * 
			 * 4.2) if user want to restore tab before timer was finished
			 * 4.2.1) restore tab on previous position
			 * 
			 * */
			this.children_removed.append(vtt);
			vtt.on_remove_timeout.connect(this.on_tab_remove_timeout);
			vtt.start_remove_timer(); 				
		}else
		if(vtt is AYSettings){
			((AYSettings)vtt).destroy();
			this.aysettings=null;
			this.aysettings_shown=false;
			switch_to_previous=true;
		}else
			vtt.destroy();


		if(this.children.length()>0){
			if (tab_position>(this.children.length()-1))
				tab_position=(int)this.children.length()-1;

			unowned VTToggleButton new_active_tbutton = (switch_to_previous ? this.previous_active_tab : (VTToggleButton)this.hvbox.children_nth(tab_position));
			this.activate_tab(new_active_tbutton);
			this.update_tabs_title();
			this.search_update();
		}else{//action_on_close_last_tab
			if(this.action_on_close_last_tab==2){//quit
				this.main_window.allow_close=true;
				this.main_window.destroy();
				return;				
			}
			
			if(this.action_on_close_last_tab<2){//restart shell
				var vt_new=this.add_tab();
				string S=_("Shell terminated.")+"\n\r\n\r";
				vt_new.vte_term.feed(S,S.length);
			}
			if(this.action_on_close_last_tab==1)//restart shell and hide
				this.main_window.toggle_window();			
		}
	}

	public bool tab_button_press_event(Widget widget,Gdk.EventButton event) {
		if(event.type==Gdk.EventType.BUTTON_PRESS){
			if(event.button == 1){
				VTToggleButton tbutton = (VTToggleButton) widget;
				if ( this.active_tab != tbutton)
					this.activate_tab(tbutton);

			}
			if(event.button == 2){//middle mouse button
				VTToggleButton tbutton = (VTToggleButton) widget;
				this.close_tab(this.hvbox.children_index(tbutton));
				return true;//stop
			}
		}
		return false; //true == ignore event
	}//tab_button_press_event

	public void activate_tab (VTToggleButton tab_button){
		if (tab_button != null )
		if(this.active_tab==null || this.active_tab!=tab_button){
			foreach (AYTab vt in this.children) {
				if (vt.tbutton == tab_button){

					this.terms_notebook.set_current_page(this.terms_notebook.page_num(vt.hbox));

					if (this.active_tab!=null){
						this.active_tab.active=false;
						this.previous_active_tab=active_tab;
					}
					this.active_tab = tab_button;
					this.active_tab.active=true;
					//vt.tbutton.set_title((this.children.index(vt)),null);//not necessary
					if(vt is VTTerminal){
						((VTTerminal)vt).vte_term.grab_focus();
						((VTTerminal)vt).vte_term.show () ;
						//this.set_default(vt.vte_term);
					}
					this.search_update();
					if(tab_button.object is VTTerminal)
						this.main_window.prev_focus=((VTTerminal)tab_button.object).vte_term;//update focus, helps if window was hidden
					break;
					}
			}
		}else{
			if(this.active_tab.object is VTTerminal){
			((VTTerminal)this.active_tab.object).vte_term.grab_focus();
			((VTTerminal)this.active_tab.object).vte_term.show () ;
			if(this.active_tab.object is VTTerminal)
				this.main_window.prev_focus=((VTTerminal)this.active_tab.object).vte_term;//update focus, helps if window was hidden
			}
			this.search_update();
		}
	}

	public void move_tab(Widget widget, uint new_index){
		VTToggleButton tab_button = (VTToggleButton) widget;
		foreach (var vt in this.children) {
			if (vt.tbutton == tab_button){
				this.children.remove(vt);
				this.children.insert( vt ,(int) new_index);
				this.activate_tab(tab_button);
				break;
			}
		}
		this.update_tabs_title();
		this.search_update();
	}

	public void update_tabs_title(){
		foreach (var vt in this.children) {
			//reindex all tabs
			if(vt.tbutton.set_title(this.children.index(vt),null)){
				this.hvbox.queue_draw();
				this.main_window.update_events();
			}
		}
	}

	public void tab_next () {
		unowned List<unowned AYTab> item_it = null;
		unowned AYTab vt = null;
		for (item_it = this.children; item_it != null; item_it = item_it.next) {
			vt = item_it.data;
			if (vt.tbutton == this.active_tab){
				if (item_it.next!=null){
					vt = item_it.next.data;
					debug("tab_next %s",vt.tbutton.tab_title);
					this.activate_tab(vt.tbutton) ;
					break;
				}else{
					vt = this.children.first().data;
					this.activate_tab(vt.tbutton) ;
					break;
				}
			}
		}
	}

	public void tab_prev () {
		unowned List<unowned AYTab> item_it=null;
		unowned AYTab vt=null;
		for (item_it = this.children; item_it != null; item_it = item_it.next) {
			vt = item_it.data;
			if (vt.tbutton == this.active_tab){
				if (item_it.prev!=null){
					vt = item_it.prev.data;
					this.activate_tab(vt.tbutton) ;
					break;
				}else{
					vt = this.children.last().data;
					this.activate_tab(vt.tbutton) ;
					break;
				}
			}
		}
	}

	public void title_changed(Vte.Terminal term){
		string? s = term.window_title;
		//title_changed in altyo_window
		//becouse of this.children.index
		foreach (var vt in this.children) {
			if (vt is VTTerminal && ((VTTerminal)vt).vte_term == term){
				var tab_index =  this.children.index(vt);
				if(vt.tbutton.set_title(tab_index, s )){
					this.hvbox.queue_draw();
					this.main_window.update_events();
					this.window_title_update();
				}
				if( (this.tab_sort_order==TAB_SORT_ORDER.HOSTNAME) &&
				    ( vt.tbutton.host_name!=null || !vt.tbutton.do_not_sort) )
						this.tab_sort();
				break;
			}
		}

	}


	public void tab_sort () {
		bool update_titles=false;
		bool changed=false;

		do{
			changed=false;
			/*sort while sorting*/

			this.children.sort_with_data( (vt_a, vt_next_b)=>{
				VTTerminal vt = vt_a as VTTerminal, vt_next = vt_next_b as VTTerminal;

				//debug("compare: %s == %s",vt.tbutton.host_name,vt_next.tbutton.host_name);
				if(vt.tbutton.host_name!=null && vt_next.tbutton.host_name!=null ){
					int res=vt.tbutton.host_name.collate(vt_next.tbutton.host_name);
					//debug("compare: %d> %d == %d",res,this.children.index(vt),this.children.index(vt_next));
					if(res>0 && !vt.tbutton.do_not_sort){
						this.hvbox.place_before(vt.tbutton,vt_next.tbutton);
						changed=true;
						return 1;
					}else if(res<0 /*&& !vt.tbutton.do_not_sort*/){
						return -1;
					}else
						return 0;
					//return vt.tbutton.host_name.collate(vt_next.tbutton.host_name);
				}else
					return 0;
			});
			
			if(changed)
				update_titles=true;
		}while(changed);

		if(update_titles)
			this.update_tabs_title();

	}//tab_sort

	public void ShowQuitDialog(){
			Gtk.MessageType message_type=Gtk.MessageType.OTHER;	
			var settings = Gtk.Settings.get_default();
			if(settings.gtk_menu_images){
				message_type = MessageType.QUESTION;
			}		
			var dialog = new MessageDialog (null, (DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL), message_type, ButtonsType.YES_NO, _("Really quit?"));
			var checkbox = new CheckButton.with_label(_("Save session"));
			checkbox.active=this.save_session;
			var dialog_box = ((Gtk.ButtonBox)dialog.get_action_area ());
			dialog_box.pack_start(checkbox,false,false,0);
			//dialog_box.reorder_child(checkbox,0);
			checkbox.show();
			dialog.response.connect ((response_id) => {
				if(response_id == Gtk.ResponseType.YES){
					this.save_session=checkbox.active;
					this.main_window.allow_close=true;
					this.main_window.destroy();
				}else
					this.main_window.allow_close=false;
			});

			dialog.focus_out_event.connect (() => {
				return true; //same bug as discribed in this.focus_out_event
				});
			dialog.set_transient_for(this.main_window);
			dialog.show ();
			dialog.grab_focus();
			this.main_window.hotkey.send_net_active_window(dialog.get_window ());
			int result = dialog.run();
			dialog.destroy ();
			if(result != Gtk.ResponseType.NONE)
				this.main_window.window_set_active();
	}



	public void ShowAbout(){
			var dialog = new AboutDialog();
			dialog.license_type = Gtk.License.GPL_3_0;
			dialog.authors={"Konstantinov Denis linvinus@gmail.com"};
			dialog.website ="https://github.com/linvinus/AltYo";
			dialog.version = (AY_CHANGELOG_TAG!="" ? AY_CHANGELOG_TAG : "0.3") +" "+AY_GIT_HASH;
			dialog.translator_credits=_("willemw12@gmail.com");
			dialog.comments="id: "+Globals.app_id;
			Image img = new Image.from_resource ("/org/gnome/altyo/altyo.svg");
			dialog.set_logo(img.pixbuf);

			dialog.focus_out_event.connect (() => {
				return true; //same bug as discribed in this.focus_out_event
				});
			dialog.set_transient_for(this.main_window);
			dialog.show_all();
			dialog.grab_focus();
			dialog.set_destroy_with_parent(true);
			this.main_window.hotkey.send_net_active_window(dialog.get_window ());
			int result = dialog.run();
			dialog.destroy ();
			debug("ShowAbout end");
			if(result != Gtk.ResponseType.NONE)
				this.main_window.window_set_active();			
	}

	public void show_reset_to_defaults_dialog(){
			string msg=_("Really reset to defaults?\nCurrent settings will be saved in backup file %s.bak").printf(this.conf.conf_file);
			Gtk.MessageType message_type=Gtk.MessageType.OTHER;	
			var settings = Gtk.Settings.get_default();
			if(settings.gtk_menu_images){
				message_type = MessageType.QUESTION;
			}				
			var dialog = new MessageDialog (null, (DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL), message_type, ButtonsType.YES_NO, msg);

			dialog.response.connect ((response_id) => {
				if(response_id == Gtk.ResponseType.YES){
					//this.conf.
					this.action_group.set_sensitive(true);//activate
					this.action_group.get_action("open_settings").activate();//close
					this.conf.reset_to_defaults();//make empty config
					//reset all keybindings
					foreach(var action_in_list in this.action_group.list_actions ()){
						Gtk.AccelMap.change_entry(action_in_list.get_accel_path(),0,0,true);
					}					
					this.conf.reload_config();
					this.action_group.get_action("open_settings").activate();//open
				}
			});

			dialog.focus_out_event.connect (() => {
				return true; //same bug as discribed in this.focus_out_event
				});
			dialog.set_transient_for(this.main_window);
			dialog.show ();
			dialog.grab_focus();
			this.main_window.hotkey.send_net_active_window(dialog.get_window ());
			int result = dialog.run();
			dialog.destroy ();
			if(result != Gtk.ResponseType.NONE)
				this.main_window.window_set_active();			
	}
	
	public void set_custom_title_dialog(VTToggleButton tab){
			Gtk.MessageType message_type=Gtk.MessageType.OTHER;	
			var settings = Gtk.Settings.get_default();
			if(settings.gtk_menu_images){
				message_type = MessageType.QUESTION;
			}		
			var dialog = new MessageDialog (null, (DialogFlags.DESTROY_WITH_PARENT | DialogFlags.MODAL), message_type, ButtonsType.YES_NO, _("Setup custom title?"));
			var entry = new Gtk.Entry();
			entry.set_text ( ( tab.tab_custom_title==null ? _("new custom title") : tab.tab_custom_title) );
			entry.activate.connect(()=>{
					dialog.response (Gtk.ResponseType.YES);
			});

			var dialog_box = ((Gtk.Box)dialog.get_content_area ());
			dialog_box.pack_start(entry,false,false,0);
			entry.show();
			dialog.response.connect ((response_id) => {
				if(response_id == Gtk.ResponseType.YES){
					tab.tab_custom_title = entry.get_text();
				}else{
					tab.tab_custom_title=null;
				}
				this.hvbox.queue_draw();//redraw border
			});
		
			dialog.focus_out_event.connect (() => {
				return true; //same bug as discribed in this.focus_out_event
				});
				
			dialog.set_transient_for(this.main_window);
			dialog.show ();
			dialog.grab_focus();
			this.main_window.hotkey.send_net_active_window(dialog.get_window ());
			int result = dialog.run();
			dialog.destroy ();
			if(result != Gtk.ResponseType.NONE)
				this.main_window.window_set_active();			
	}
	
	public bool update_action_keybinding(Gtk.Action action, uint accelerator_key,Gdk.ModifierType accelerator_mods, bool force=false){
				//if current accel don't equal to parsed, then try to update
				
				//debug("accel error: %s key:%d mod:%d",action.get_accel_path(),(int)accelerator_key,(int)accelerator_mods);
				
				AccelKey current_ak;
				Gtk.AccelMap.lookup_entry(action.get_accel_path(),out current_ak);
				debug("update accel: %s current_ak.accel_key=%d != accelerator_key=%d current_ak.accel_mods=%d != accelerator_mods=%d",action.get_accel_path(),
				(int)current_ak.accel_key,(int)accelerator_key,
				current_ak.accel_mods,accelerator_mods);
				
				if( (current_ak.accel_key!=accelerator_key || current_ak.accel_mods!=accelerator_mods) &&
				    !Gtk.AccelMap.change_entry(action.get_accel_path(),accelerator_key,accelerator_mods,force) ){
					//if accelerator could not be changed becouse another action already bind the same hotkey
					//find conflicting action
					debug("found conflicting action! trying find name...");

					string action_label="";
					AccelKey conflicting_ak;
					foreach(var action_in_list in this.action_group.list_actions ()){
						Gtk.AccelMap.lookup_entry(action_in_list.get_accel_path(),out conflicting_ak);
						if(conflicting_ak.accel_key==accelerator_key && conflicting_ak.accel_mods==accelerator_mods){
							action_label=action_in_list.get_label();
							break;
							}
					}
					string s=_("You are trying to use key binding \"%s\"\nfor action \"%s\"\nbut, same key binding already binded to the action \"%s\"").printf(Gtk.accelerator_get_label(accelerator_key,accelerator_mods),action.get_label(),action_label);
					this.main_window.show_message_box(_("error"),s);

					return false;
					}
		return true;//succesfull
	}
	
	private bool check_for_existing_action(string name,string default_accel){
		unowned Gtk.Action action = this.action_group.get_action(name);
		uint accelerator_key;
		Gdk.ModifierType accelerator_mods;
		AccelKey current_ak;
		string key_string=conf.get_accel_string(name,default_accel);
		AccelMap am=Gtk.AccelMap.get();
		string accel_path;

		if(action!=null){
			accel_path=action.get_accel_path();
			
			if(key_string==""){
				am.change_entry(accel_path,0,0,true);//clear hotkey if present
				return true; //action exist
			}
			
			//get current action AccelKey
			am.lookup_entry(accel_path,out current_ak);
			
			Gtk.accelerator_parse(key_string,out accelerator_key,out accelerator_mods);
			if(accelerator_key==0 && accelerator_mods==0){
				debug("parsing error! action_name=%s key_string=%s",name,key_string);
				//update config for best setting that we know
				var parsed_name=Gtk.accelerator_name (current_ak.accel_key, current_ak.accel_mods);
				conf.set_accel_string(name,parsed_name);
				return true;//action exist
			}else if(current_ak.accel_key!=accelerator_key || current_ak.accel_mods!=accelerator_mods){
				this.update_action_keybinding(action,accelerator_key,accelerator_mods);
				//if error was occurred in update_action_keybinding, then accell in config will be sinchronized with current binded accel
			}
			//reload current_ak if it was changed in update_action_keybinding
			am.lookup_entry(accel_path,out current_ak);
			//just update config to be enshure that settings are same as we think
			var parsed_name=Gtk.accelerator_name (current_ak.accel_key, current_ak.accel_mods);
			conf.set_accel_string(name,parsed_name);
			return true;//action exist
		}
		return false;
	}

	private void add_window_accel(string name,string? label, string? tooltip, string? stock_id,string default_accel, MyCallBack cb){
		if(!check_for_existing_action(name,default_accel))
			this.add_window_accel_real(new Gtk.Action(name, label, tooltip, stock_id),conf.get_accel_string(name,default_accel),cb);
	}

	private void add_window_toggle_accel(string name,string? label, string? tooltip, string? stock_id,string default_accel, MyCallBack cb){
		if(!check_for_existing_action(name,default_accel))
			this.add_window_accel_real(new Gtk.ToggleAction(name, label, tooltip, stock_id),conf.get_accel_string(name,default_accel),cb);
	}

	private void add_window_accel_real(Gtk.Action action, string accel, MyCallBack cb){
		uint accelerator_key;
		Gdk.ModifierType accelerator_mods;
		
		//we can't connect cb dirrectly to action.activate
		//so, using lambda again =(
		action.activate.connect_after(()=>{cb(action);});

		//add action into action_group to make a single repository
		this.action_group.add_action_with_accel (action,"");//create accel path
		action.set_accel_group (this.accel_group);//use main window accel group
		action.connect_accelerator ();
		//set up key binding, and check for conflicts
		Gtk.accelerator_parse(accel,out accelerator_key,out accelerator_mods);	

		if(!this.update_action_keybinding(action,accelerator_key,accelerator_mods)){
			conf.set_accel_string(action.name,"");//clear conflicting value
		}
		
	}

	public void setup_keyboard_accelerators() {


		if(this.accel_group==null){
			this.accel_group = new Gtk.AccelGroup();
			this.main_window.add_accel_group (accel_group);
		}

		if(this.action_group==null)
			this.action_group = new Gtk.ActionGroup("AltYo");


		/* Add New Tab on <Ctrl><Shift>t */
		this.add_window_accel("terminal_add_tab", _("New tab"), _("Open new tab"), Gtk.Stock.NEW,"<Control><Shift>T",()=>{
			if(this.conf.get_boolean("terminal_new_tab_in_current_directory",true)){
				debug("terminal_new_tab_in_current_directory");
				if(this.active_tab!=null){
					if(this.active_tab.object is VTTerminal){
					VTTerminal vt =((VTTerminal)this.active_tab.object);
					var tmp=vt.find_tty_pgrp(vt.pid,FIND_TTY.CWD);
					//var tmp = vt.vte_term.get_current_directory_uri();//:TODO in vte 0.34
					debug("path: %s",tmp);
					this.add_tab(null,tmp);
					}else
					this.add_tab();
				}
			}else{
				this.add_tab();
			}
		});

        /* Close Current Tab on <Ctrl><Shift>w */
		this.add_window_accel("terminal_close_tab", _("Close tab"), _("Close current tab"), Gtk.Stock.CLOSE,"<Control><Shift>W",()=> {
            this.close_tab(this.hvbox.children_index(this.active_tab));
        });

        /* Go to Next Tab on <Ctrl>Page_Down */
		this.add_window_accel("terminal_tab_next", _("Next tab"), _("Switch to next tab"), Gtk.Stock.GO_FORWARD,"<Control>Page_Down",()=> {
            this.tab_next();
        });

        /* Go to Prev Tab on <Ctrl>Page_Up */
		this.add_window_accel("terminal_tab_prev", _("Previous tab"), _("Switch to previous tab"), Gtk.Stock.GO_BACK,"<Control>Page_Up",()=> {
            this.tab_prev();
        });

		/* Change page 1..9 0 */
        for(var i=1;i<11;i++){
			this.add_window_accel("terminal_switch_tab%d".printf(i), _("Switch to tab %d").printf(i), _("Switch to tab %d,double press switch to tab %d").printf(i,i+10), null,"<Alt>%d".printf((i==10?0:i)),(a)=> {
					//"a" - is action, get index from action name,
					//because "i" is unavailable in action callback
					var s=a.name.replace("terminal_switch_tab","");
					var j=int.parse(s);
					var now = new DateTime.now_local();

					if(this.double_hotkey==j && this.double_hotkey_last_time!=null && now.difference(this.double_hotkey_last_time)<this.double_hotkey_milliseconds){
						this.double_hotkey=j;
						this.double_hotkey_level+=10;
					}else{
						this.double_hotkey=j;
						this.double_hotkey_level=0;
					}

					this.double_hotkey_last_time=now;
					uint index = j+this.double_hotkey_level-1;
					if(index >= children.length())
						index = children.length()-1;//switch to last tab

					unowned AYTab vt = children.nth_data(index);
					if(vt != null)
						this.activate_tab(vt.tbutton);
			});
		}

		///* Copy on <Ctrl><Shift>с */

		this.add_window_accel("terminal_copy_text",_("Copy"), _("Copy selected text"), Gtk.Stock.COPY,"<Control><Shift>C",()=> {
            this.ccopy();
        });

		/* Paste on <Ctrl><Shift>v */
		this.add_window_accel("terminal_paste_text", _("Paste"), _("Paste from primary clipboard"), Gtk.Stock.PASTE,"<Control><Shift>V",()=> {
            this.cpaste();
        });

		/* Find on <Ctrl><Shift>f */
		this.add_window_accel("terminal_search_dialog", _("Search"), _("Search"), Gtk.Stock.FIND,"<Control><Shift>F",()=> {
			if(!((Entry)this.quick_options_notebook.search_text_combo.get_child()).has_focus || this.quick_options_notebook.search_mode_rbutton.active )
				this.quick_options_notebook.search_show();

			if(!this.quick_options_notebook.search_mode_rbutton.active){
				this.quick_options_notebook.search_mode_rbutton.set_active(true);
			}

        });

		/* QuickLIst <Ctrl><Shift>d */
		#if HAVE_QLIST
		this.add_window_accel("altyo_toggle_quick_list", _("Show/Hide Quick list"), _("Show/Hide Quick list"), Gtk.Stock.QUIT,"<Control><Shift>D",()=> {
			if(this.tasks_notebook.get_current_page() == TASKS.TERMINALS)
				this.tasks_notebook.set_current_page(TASKS.QLIST);
			else
				this.tasks_notebook.set_current_page(TASKS.TERMINALS);
        });
        #endif

		this.add_window_toggle_accel("follow_the_mouse", _("Follow mouse cursor"), _("Follow mouse cursor"), Gtk.Stock.EDIT,"",(action)=> {
				this.main_window.mouse_follow = ((ToggleAction)action).active;
        });
		this.add_window_accel("open_settings", _("Settings..."), _("Settings"), Gtk.Stock.EDIT,"",()=> {
				this.conf.save(true);//force save before edit
				if(this.conf.reduce_memory_usage){
					VTTerminal vt;
					string editor = conf.get_string("text_editor_command","");

					if(editor=="" ||editor==null)
						editor=GLib.Environment.get_variable("EDITOR");

					string[] editor_names={"editor","nano","vi","emacs"};
					string[] paths={"/usr/bin/","/bin/","/usr/local/bin/"};
					bool done=false;
					if(editor==""||editor==null)
					foreach(string editor_name in editor_names){
						foreach(string path in paths){
							if(GLib.FileUtils.test(path+editor_name,GLib.FileTest.EXISTS|GLib.FileTest.IS_EXECUTABLE)){
							editor=path+editor_name;
							done=true;
							break;
							}
						}
						if(done) break;
					}
					debug("Found editor: %s",editor);
					vt = this.add_tab(editor+" "+this.conf.conf_file,null,(vt1)=>{
						debug("OnChildExited");
						this.conf.load_config();
						vt1.destroe_delay=0;
						this.close_tab(this.hvbox.children_index(vt1.tbutton));
						});
					vt.auto_restart=false;
					vt.destroe_delay=0;
					var tab_index =  this.children.index(vt);
					vt.tbutton.set_title(tab_index, _("AltYo Settings") );
				}else{
					if(!this.aysettings_shown){
						this.aysettings=new AYSettings(this.conf,this.terms_notebook,(int)(this.children.length()),this);
						this.children.append(this.aysettings);
						this.aysettings.tbutton.button_press_event.connect(tab_button_press_event);
						this.hvbox.add(this.aysettings.tbutton);
						this.activate_tab(this.aysettings.tbutton) ;//this.active_tab = this.hvbox.children_index(tbutton);
						this.aysettings_shown=true;
					}else{
						if(this.active_tab!=this.aysettings.tbutton){
							this.activate_tab(this.aysettings.tbutton);
						}else{//close
							this.close_tab(this.hvbox.children_index(this.aysettings.tbutton));
							this.aysettings_shown=false;
						}
					}
			}
        });



		/* Quit on <Ctrl><Shift>q */
		this.add_window_accel("altyo_exit", _("Quit"), _("Quit"), Gtk.Stock.QUIT,"<Control><Shift>Q",()=> {
			if(this.main_window.allow_close==false){
				this.ShowQuitDialog();
			}else{
				this.main_window.destroy();
			}
        });

   		/* Show/hide main window on <Alt>grave
   		 * add main_hotkey just to be able show it in popup menu*/
		this.add_window_accel("main_hotkey", _("Show/Hide"), _("Show/Hide"), Gtk.Stock.GO_UP,"<Alt>grave",()=>{
			this.main_window.toggle_window();
		});

		/* Add New Tab on <Ctrl><Shift>t */
		this.add_window_accel("altyo_about", _("About"), _("About"), Gtk.Stock.ABOUT,"",()=>{
			this.ShowAbout();
		});

		this.add_window_toggle_accel("disable_sort_tab", _("Disable sort tab"), _("Disable sort tab"), Gtk.Stock.EDIT,"",()=> {
			if(this.active_tab!=null){
				debug("disable_sort_tab");
				this.active_tab.do_not_sort=!this.active_tab.do_not_sort;
				//((Gtk.ToggleAction)
			}
        });

		this.add_window_toggle_accel("keep_above", _("Stay on top"), _("Stay on top"), Gtk.Stock.EDIT,"",(action)=> {
			this.main_window.keep_above=((ToggleAction)action).active;
			debug("action keep_above %d",(int)this.main_window.keep_above);
			if(this.main_window.keep_above && !this.conf.standalone_mode){
				this.main_window.skip_taskbar_hint = true;
				this.main_window.set_keep_above(true);
			}else{
				this.main_window.skip_taskbar_hint = false;
				this.main_window.set_keep_above(false);
			}
        });
		this.add_window_toggle_accel("window_toggle_stick", _("Stick"), _("Toggle stick"), Gtk.Stock.EDIT,"",(action)=> {
			this.main_window.orig_stick=((ToggleAction)action).active;
			//debug("action keep_above %d",(int)this.main_window.keep_above);
			if(this.main_window.orig_stick && !this.conf.standalone_mode){
				this.main_window.stick();
			}else{
				this.main_window.unstick();
			}
        });
		this.add_window_toggle_accel("window_toggle_autohide", _("Autohide"), _("Toggle autohide"), Gtk.Stock.EDIT,"",(action)=> {
			this.main_window.autohide=((ToggleAction)action).active;
        });

		this.add_window_toggle_accel("toggle_maximize", _("Maximize - restore"), _("Maximize window, or restore to normal size"), Gtk.Stock.EDIT,"",()=> {
			if(this.main_window.maximized ||
			   this.main_window.fullscreened ){
				this.main_window.maximized=false;
			}else{
				this.main_window.maximized=true;
			}
        });

        this.add_window_accel("terminal_sort_by_hostname",_("Sort by hostname"), _("Sort by hostname"), Gtk.Stock.SORT_ASCENDING,"",()=> {
            this.tab_sort();
        });
        
        this.add_window_accel("window_open_new_window",_("Open new window"), _("Open new window"), Gtk.Stock.NEW,"<Control><Shift>N",()=> {
			if(this.conf.get_boolean("terminal_new_tab_in_current_directory",true)){
				debug("window_open_new_window_in_current_directory");
				if(this.active_tab!=null){
					if(this.active_tab.object is VTTerminal){
					VTTerminal vt =((VTTerminal)this.active_tab.object);
					var tmp=vt.find_tty_pgrp(vt.pid,FIND_TTY.CWD);
					//var tmp = vt.vte_term.get_current_directory_uri();//:TODO in vte 0.34
					//debug("path: %s",tmp);
					
					/* firstly try to find absolite path
					 * else search in default system path*/
					string exec="%s --standalone --default-path '%s'".printf(GLib.FileUtils.read_link("/proc/self/exe"),tmp);
					/*pass cfg only if sure that it is for standalone_mode*/
					if(conf.standalone_mode)
						exec+=" --config-readonly -c '%s'&".printf(this.conf.conf_file);
					else
						exec+="&";
					
					debug("window_open_new_window: %s",exec);
					Posix.system(exec);
					}
					//else
					//this.add_tab();
				}
			}else{
					/* firstly try to find absolite path
					 * else search in default system path*/
					string exec;
					if(GLib.FileUtils.test(GLib.Environment.get_current_dir()+"/"+GLib.Environment.get_prgname(),GLib.FileTest.EXISTS) ){
						exec="%s/%s --standalone --default-path='%s'".printf(GLib.Environment.get_current_dir(),GLib.Environment.get_prgname(),GLib.Environment.get_current_dir());
					}else{
						exec="%s --standalone --default-path='%s'".printf(GLib.Environment.get_prgname(),GLib.Environment.get_current_dir());
					}
					/*pass cfg only if sure that it is for standalone_mode*/
					if(conf.standalone_mode)
						exec+=" --config-readonly -c '%s'&".printf(this.conf.conf_file);
					else
						exec+="&";
											
					debug("window_open_new_window: %s",exec);
					Posix.system(exec);				
			}
        });

        this.add_window_accel("terminal_search_in_tab_title",_("Search in terminals titles"), _("Search in terminals titles"), Gtk.Stock.FIND,"<Control><Shift>D",()=> {
				unowned SList <Gtk.RadioButton> rbutton_group = this.quick_options_notebook.search_mode_rbutton.get_group ();
				if(!((Entry)this.quick_options_notebook.search_text_combo.get_child()).has_focus || !this.quick_options_notebook.search_mode_rbutton.active )
					this.quick_options_notebook.search_show();

				if(this.quick_options_notebook.search_mode_rbutton.active){
					//set SEARCH_MODE.SEARCH_IN_NAME
					var rb=rbutton_group.nth_data(0) as Gtk.RadioButton;
					rb.set_active(true);
				}
        });
        this.add_window_accel("window_terminal_quick_settings",_("Terminal quick settings"), _("Terminal quick settings"), Gtk.Stock.EDIT,"",()=> {
				if(!((Entry)this.quick_options_notebook.encodings_combo.get_child()).has_focus)
					this.quick_options_notebook.encodings_show();
        });
        
		this.add_window_toggle_accel("lock_tab", _("Lock tab"), _("Lock tab"), Gtk.Stock.DIALOG_AUTHENTICATION,"",()=> {
			debug("lock_tab");
			if(this.active_tab!=null){
				this.active_tab.prevent_close=!this.active_tab.prevent_close;
				this.active_tab.reconfigure();
				//((Gtk.ToggleAction)
			}
        });
        
		this.add_window_accel("restore_tab", _("Restore closed tab"), _("Restore last closed tab"), Gtk.Stock.GO_UP,"<Control><Shift>R",()=>{
			unowned List<unowned AYTab>? element = this.children_removed.last ();
			if(element!=null){
				this.restore_tab(element.data);
			}
			
		});
		
		this.add_window_toggle_accel("tab_custom_title", _("Custom title"), _("Custom title"), Gtk.Stock.DIALOG_AUTHENTICATION,"<Control><Shift>I",()=> {
			debug("tab_custom_title");
			if(this.active_tab!=null){
				this.set_custom_title_dialog(this.active_tab);
			}
        });		
	}//setup_keyboard_accelerators





	public void ccopy() {
				unowned AYTab vtt = ((AYTab)this.active_tab.object);
				if(vtt is VTTerminal)
					((VTTerminal)vtt).vte_term.copy_clipboard ();
	}

	public void cpaste() {
				unowned AYTab vtt = ((AYTab)this.active_tab.object);
				if(vtt is VTTerminal)
					((VTTerminal)vtt).vte_term.paste_clipboard ();
	}

	/*public override bool focus_out_event (Gdk.EventFocus event){
		//on ubuntu 11.10,libvte9 1:0.28.2-0ubuntu2
		//prevent vost focus, for some rason we recieve focus_out_event
		//after window show, but still have input focus
		//may be in the future we will have more luck, try to comment
		//this callback
		return true;
	}*/
	
	public void search_in_tab_name(string? new_pattern,bool forward=true){
		
		unowned List<unowned AYTab> item_it = null;
		unowned AYTab vt = null;
		
		uint length = this.children.length();
		
		//skip search if pattern is empty, or if only one tab is open
		if(new_pattern==null || new_pattern=="" || length<2) return; 

		var reg_exp = new GLib.Regex(".*"+new_pattern+".*",0);
		
		item_it =  this.children.find((AYTab)this.active_tab.object); //this.children;
		//start search from next avaylable tab
		if(forward){
			if (item_it.next!=null)
					item_it = item_it.next;
			else
					item_it = this.children.first();
		}else{
			if (item_it.prev!=null)
					item_it = item_it.prev;
			else
					item_it = this.children.last();
		}
		//cycle through all items
		do{
			vt = item_it.data;
			debug("search %s in %s",new_pattern,(vt.tbutton.tab_custom_title_enabled? vt.tbutton.tab_custom_title : vt.tbutton.tab_title));
			if(reg_exp.match((vt.tbutton.tab_custom_title_enabled? vt.tbutton.tab_custom_title : vt.tbutton.tab_title),0,null)){
				this.activate_tab(vt.tbutton);
				break;
			}
			
			if(forward){
				if (item_it.next!=null)
						item_it = item_it.next;
				else
						item_it = this.children.first();
			}else{
				if (item_it.prev!=null)
						item_it = item_it.prev;
				else
						item_it = this.children.last();
			}		
			length--;	
		}while(length>0);
	}

	public void window_title_update(){
		AYTab vtt = ((AYTab)this.active_tab.object);
		if(vtt!=null) {
			if(vtt.tbutton.tab_title!=null)
				this.main_window.title=vtt.tbutton.tab_title;
			else				
				this.main_window.title=_("Tab%d - AltYo").printf(this.children.index(vtt)+1);
		}
	}
	
	public void search_update(){
		this.window_title_update();
		
		if(this.hvbox_display_mode == HVBOXDISPLAY.HIDEIFONETAB){
			if(this.children.length()==1){
				unowned Gtk.StyleContext context = this.tasks_notebook.get_style_context();
				context.remove_class("window_multitabs");
				context.add_class("window_single_tab");
				context.invalidate();
				this.hvbox.visible=false;
			}else{
				unowned Gtk.StyleContext context = this.tasks_notebook.get_style_context();
				context.remove_class("window_single_tab");
				context.add_class("window_multitabs");
				context.invalidate();
				this.hvbox.visible=true;
			}
		}else if(this.hvbox_display_mode == HVBOXDISPLAY.VISIBLE && !this.hvbox.visible){
			unowned Gtk.StyleContext context = this.tasks_notebook.get_style_context();
			context.remove_class("window_single_tab");
			context.add_class("window_multitabs");
			context.invalidate();
			this.hvbox.visible=true;
		}else if(this.hvbox_display_mode == HVBOXDISPLAY.HIDDEN && this.hvbox.visible){
			unowned Gtk.StyleContext context = this.tasks_notebook.get_style_context();
			context.remove_class("window_multitabs");
			context.add_class("window_single_tab");
			context.invalidate();
			this.hvbox.visible=false;
		}
//~ 		Gtk.StyleContext.reset_widgets(this.main_window.get_screen ());//force apply new class

		if(this.quick_options_notebook.visible){
			unowned AYTab vtt = ((AYTab)this.active_tab.object);
			if(!(vtt is VTTerminal)) {
				this.quick_options_notebook_hide();
				return;
			}
			this.quick_options_notebook.update_search(((VTTerminal)vtt));
			this.quick_options_notebook.update_encoding(((VTTerminal)vtt));
		}
	}

	public void quick_options_notebook_hide(){
		//prevent resizing of the terminal after closing the search
		var should_be_h = this.terminal_height+this.hvbox.get_allocated_height();
		if(this.main_window.get_allocated_height()>should_be_h+2){
			//this.configure_position();//this needed to update position after unmaximize
			debug ("search_hide terminal_width=%d should_be_h=%d",terminal_width,should_be_h) ;
		}
		this.quick_options_notebook.hide();

		unowned AYTab vtt = ((AYTab)this.active_tab.object);
		if(vtt is VTTerminal) {
			((VTTerminal)vtt).vte_term.search_set_gregex(null);
			((VTTerminal)vtt).vte_term.grab_focus();
		}
	}
	
	public void save_configuration(){
			this.quick_options_notebook.save_search_history();

			var autostart_terminal_session=this.conf.get_string_list("terminal_autostart_session",null);

			string[] terminal_session = {};
			var grx_exclude = new GLib.Regex(this.conf.get_string("terminal_session_exclude_regex","",(ref new_val)=>{
			string err;
			if(!this.conf.check_regex(new_val,out err)){
				debug(_("terminal_session_exclude_regex wrong value! will be used default value. err:%s"),err);
				return CFG_CHECK.USE_DEFAULT;
			}

			return CFG_CHECK.OK;
			}));

			foreach (var vt in this.children) {
				if(vt is VTTerminal){
					bool cont=false;
					var tmp=((VTTerminal)vt).find_tty_pgrp(((VTTerminal)vt).pid);
					if(autostart_terminal_session != null && autostart_terminal_session.length>0){
						foreach(var s in autostart_terminal_session){
							if(s==tmp){
								cont=true;//exclude terminal_autostart_session commands
								break;
							}
						}
					}
					if(!cont && tmp!="" && !grx_exclude.match_all(tmp,0,null) && this.save_session)
						terminal_session+=tmp;
				}
			}
			//g_list_free(this.children);
			this.conf.set_string_list("terminal_session",terminal_session);
	}//save_configuration

	public void on_switch_task (Widget page, uint page_num) {
		if(page_num==TASKS.TERMINALS){
			//while loading,on_switch_task perhaps before this.action_group is configured
			if(this.action_group!=null) //ignore if not configured
				this.action_group.sensitive=true;
			//this.overlay_notebook.hide();
			if(this.active_tab!=null){//possible on start
				unowned AYTab vtt = ((AYTab)this.active_tab.object);
				if( vtt is VTTerminal )
					((VTTerminal) vtt).vte_term.grab_focus();
			}
		}else if(page_num==TASKS.QLIST){
			if(this.action_group!=null) //ignore if not configured
				this.action_group.sensitive=false;
			//this.overlay_notebook.show();

		}
	}

	public void on_maximize(bool new_maximize){
		if(new_maximize && this.tasks_notebook.halign!=Gtk.Align.FILL){
			this.tasks_notebook.halign=Gtk.Align.FILL;
			this.tasks_notebook.valign=Gtk.Align.FILL;
			this.main_vbox.halign=Gtk.Align.FILL;
			this.main_vbox.valign=Gtk.Align.FILL;
			this.tasks_notebook.expand=true;
			this.tasks_notebook.queue_resize_no_redraw();
			debug("maximize==FILL");
		}else if(!new_maximize && this.tasks_notebook.halign!=Gtk.Align.START){
			this.tasks_notebook.halign=Gtk.Align.START;
			this.tasks_notebook.valign=Gtk.Align.START;
			this.main_vbox.halign=Gtk.Align.START;
			this.main_vbox.valign=Gtk.Align.START;
			this.tasks_notebook.expand=false;
			this.tasks_notebook.queue_resize_no_redraw();
			debug("maximize==START");
		}

	}

	public void clear_prelight_state(){
		int flags;
		foreach (var yatab in this.children) {
			flags=yatab.tbutton.get_state_flags();
			if((flags & Gtk.StateFlags.PRELIGHT)==Gtk.StateFlags.PRELIGHT){
				yatab.tbutton.update_state();//clear PRELIGHT
			}
		}
	}

	public int get_altyo_height(bool standalone_mode=false){
		int hvbox_h,hvbox_h_ignore,should_be_h=this.terminal_height;
		if(!standalone_mode)
			this.hvbox.width_request=this.terminal_width;
		if(this.hvbox.visible){
			this.hvbox.get_preferred_height_for_width(this.terminal_width,out hvbox_h,out hvbox_h_ignore);
			should_be_h+=hvbox_h;
		}
		if(this.quick_options_notebook.visible){
			this.quick_options_notebook.get_preferred_height_for_width(this.terminal_width,out hvbox_h,out hvbox_h_ignore);
			should_be_h+=hvbox_h;
		}
		debug("get_altyo_height terminal_width=%d should_be_h=%d",this.terminal_width,should_be_h);
		return should_be_h;
	}

	public void create_popup_menu_for_removed_tabs(Gtk.Menu menu){
		Gtk.MenuItem menuitem;
		if(this.children_removed.length()>0){
			var submenu = new Gtk.Menu ();
			menuitem = new Gtk.MenuItem.with_label (_("Restore tabs"));
			menuitem.set_submenu(submenu);
			menu.append(menuitem);
			
			menuitem = (Gtk.MenuItem)this.action_group.get_action("restore_tab").create_menu_item();
			submenu.append(menuitem);

			menuitem = new Gtk.MenuItem.with_label (_("Restore all closed tabs"));
			menuitem.activate.connect(()=>{
				do{
					this.restore_tab(this.children_removed.nth_data(this.children_removed.length()-1));
				}while(this.children_removed.length()>0);
				});		
			submenu.append(menuitem);

			menuitem = new Gtk.SeparatorMenuItem();
			submenu.append(menuitem);
			int index=1;
			unowned List<unowned AYTab> item_it = null;
			//reverse order
			for (item_it = this.children_removed.last(); item_it != null; item_it = item_it.prev) {
				AYTab tab = item_it.data;
				tab.stop_remove_timer();//disable timer while popup shown
				string s = ( tab.tbutton.tab_title != null ? tab.tbutton.tab_title : _("index %d").printf(tab.tbutton.tab_index) );
				menuitem = new Gtk.MenuItem.with_label ("%d: %s".printf(index,s));
				menuitem.activate.connect(()=>{
					debug("trying to restore tab %s",menuitem.label);
					this.restore_tab(tab);
					});
				submenu.append(menuitem);
				index++;
			}
			menu.deactivate.connect (()=>{
				foreach(var tab in this.children_removed){
					tab.start_remove_timer();//re enable timer
				}
				});
		}
	}//create_popup_menu_for_removed_tabs

	public void restore_tab(AYTab vt){
		if(this.children_removed.find(vt)!=null){
			vt.stop_remove_timer();
			uint index = vt.tbutton.tab_index;
			
			debug("restore tab index %u",index);
			this.hvbox.insert( vt.tbutton ,(int) index);
			this.children.insert(vt,(int)index);
			
			this.update_tabs_title();
			this.search_update();					
			this.activate_tab(vt.tbutton) ;
			this.children_removed.remove(vt);
			vt.on_remove_timeout.disconnect(this.on_tab_remove_timeout);
		}
	}

	public int cmd_get_tab_index(){
		return this.children.index((AYTab)this.active_tab.object);/*starting from 0*/
	}
	public uint cmd_get_tabs_count(){
		return this.children.length ();
	}
	public void cmd_set_tab_title(uint index/*starting from 0*/,string? s){
		var tbutton = this.children.nth_data(index).tbutton;
		tbutton.force_update_tab_title=true;	
		if(tbutton.set_title(index, s )){
			this.hvbox.queue_draw();
			this.main_window.update_events();
			this.window_title_update();
		}
	}
	public string cmd_get_tab_title(uint index/*starting from 0*/){
		var tbutton = this.children.nth_data(index).tbutton;
		return tbutton.tab_title;
	}
	
	public void cmd_activate_tab(uint index/*starting from 0*/){
		unowned AYTab vt = children.nth_data(index);
		if(vt != null)
			this.activate_tab(vt.tbutton);		
	}

}//class AYObject

public class QoptNotebook: Notebook{
	private unowned AYObject ayobject;

	public ComboBoxText search_text_combo {get;set;}
	public CheckButton search_wrap_around {get;set;}
	public CheckButton search_match_case {get;set;}
	public Gtk.RadioButton search_mode_rbutton {get;set;}
	public Gtk.ComboBox encodings_combo {get;set;}
	public Gtk.ComboBox delete_binding_combo {get;set;}
	public Gtk.ComboBox terminal_backspace_combo {get;set;}
	public int search_history_length = 10;
	public SEARCH_MODE search_in = SEARCH_MODE.SEARCH_IN_TEXT;

	private unowned MySettings conf {get;set; default = null;}
	
	public QoptNotebook(AYObject ao) {
		this.ayobject=ao;
		this.conf=this.ayobject.conf;
		this.halign=Gtk.Align.FILL;
		this.valign=Gtk.Align.START;
		this.expand=false;
		this.show_border=false;
		
		this.name="quick_options_notebook";
		this.set_show_tabs(false);

		this.draw.connect((cr)=>{
			int width = this.get_allocated_width ();
			int height = this.get_allocated_height ();
			var context = this.get_style_context();
			render_background(context,cr, 0, 0,width, height);
			this.foreach((widget)=>{
				if(widget.parent==this)
					this.propagate_draw(widget,cr);
				});
				return false;
			});

		this.insert_page(this.create_search_box(),null,OPTIONS_TAB.SEARCH);
		this.insert_page(this.create_encogings_box(),null,OPTIONS_TAB.ENCODINGS);

	}

	public Gtk.Box create_search_box(){

		var search_hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);//new HBox(false,0);
		search_hbox.halign=Gtk.Align.FILL;
		search_hbox.valign=Gtk.Align.START;
		search_hbox.expand=false;
		search_hbox.name="search_hbox";
			
		this.search_text_combo = new ComboBoxText.with_entry ();
		((Entry)this.search_text_combo.get_child()).key_press_event.connect((event)=>{
			unowned AYTab ayt = ((AYTab)this.ayobject.active_tab.object);
			if(!(ayt is VTTerminal)) return false;
			unowned VTTerminal vtt = ((VTTerminal) ayt);
			var keyname = Gdk.keyval_name(event.keyval);
			
			if(       keyname == "1" && (event.state & Gdk.ModifierType.CONTROL_MASK ) == Gdk.ModifierType.CONTROL_MASK ){
				this.search_wrap_around.activate();
			}else if( keyname == "2" && (event.state & Gdk.ModifierType.CONTROL_MASK ) == Gdk.ModifierType.CONTROL_MASK ){
				this.search_match_case.activate();
			}else if( keyname == "3" && (event.state & Gdk.ModifierType.CONTROL_MASK ) == Gdk.ModifierType.CONTROL_MASK ){
				/*change search mode*/
				unowned SList <Gtk.RadioButton> rbutton_group = this.search_mode_rbutton.get_group ();
				if(this.search_mode_rbutton.active){
					var rb=rbutton_group.nth_data(0) as Gtk.RadioButton;
					rb.set_active(true);
				}else{
					var rb=rbutton_group.nth_data(1) as Gtk.RadioButton;
					rb.set_active(true);
				}
			}
			if(this.search_in == SEARCH_MODE.SEARCH_IN_TEXT){
				if( keyname == "Return"){
						this.search_update_pattern(vtt);
						vtt.vte_term.search_find_previous();
						return true;
					}else if( keyname == "Up" && (event.state & Gdk.ModifierType.CONTROL_MASK ) == Gdk.ModifierType.CONTROL_MASK ){
						vtt.vte_term.search_find_previous();
						return true;
					}else if( keyname == "Down" && (event.state & Gdk.ModifierType.CONTROL_MASK ) == Gdk.ModifierType.CONTROL_MASK ){
						vtt.vte_term.search_find_next();
						return true;
					}else if( keyname == "Escape"){
						this.ayobject.quick_options_notebook_hide();
						return true;
					}
			}else if(this.search_in == SEARCH_MODE.SEARCH_IN_NAME){
				if( keyname == "Return"){
						this.ayobject.search_in_tab_name(this.search_text_combo.get_active_text());
						this.search_text_combo.grab_focus();//if tab was switched it grab focus, so regrab it for search entry
						return true;
					}else if( keyname == "Up" && (event.state & Gdk.ModifierType.CONTROL_MASK ) == Gdk.ModifierType.CONTROL_MASK ){
						this.ayobject.search_in_tab_name(this.search_text_combo.get_active_text());
						this.search_text_combo.grab_focus();//if tab was switched it grab focus, so regrab it for search entry
						return true;
					}else if( keyname == "Down" && (event.state & Gdk.ModifierType.CONTROL_MASK ) == Gdk.ModifierType.CONTROL_MASK ){
						this.ayobject.search_in_tab_name(this.search_text_combo.get_active_text(),false);//backward
						this.search_text_combo.grab_focus();//if tab was switched it grab focus, so regrab it for search entry
						return true;
					}else if( keyname == "Escape"){
						this.ayobject.quick_options_notebook_hide();
						return true;
					}
			}
			return false;
			});//key_press_event
			
		this.search_text_combo.show();
		search_hbox.pack_start(search_text_combo,false,false,0);

		string[]? search_s_conf = this.conf.get_string_list("search_history",null);

		if(search_s_conf!=null && search_s_conf.length<=this.search_history_length)
			foreach(var s in search_s_conf){
				this.search_text_combo.prepend_text(s);
			}


		this.search_wrap_around = new CheckButton.with_label(_("Wrap search"));
		((Label)this.search_wrap_around.get_child()).ellipsize=Pango.EllipsizeMode.END;//allow reducing size of button if needed
		this.search_wrap_around.clicked.connect(()=>{
			unowned AYTab vtt = ((AYTab)this.ayobject.active_tab.object);
			if(!(vtt is VTTerminal)) return;
			((VTTerminal)vtt).vte_term.search_set_wrap_around(this.search_wrap_around.active);
			this.search_text_combo.grab_focus();
			});
		this.search_wrap_around.show();
		this.search_wrap_around.tooltip_text=((Label)search_wrap_around.get_child()).get_label()+" Ctrl+1";
		search_hbox.pack_start(this.search_wrap_around,false,false,0);

		this.search_match_case = new CheckButton.with_label(_("Match case-sensitive"));
		((Label)this.search_match_case.get_child()).ellipsize=Pango.EllipsizeMode.END;//allow reducing size of button if needed
		this.search_match_case.clicked.connect(()=>{
			unowned AYTab vtt = ((AYTab)this.ayobject.active_tab.object);
			if(!(vtt is VTTerminal)) return;
			((VTTerminal)vtt).match_case=this.search_match_case.active;
			this.search_text_combo.grab_focus();
			});
		this.search_match_case.show();
		this.search_match_case.tooltip_text=((Label)search_match_case.get_child()).get_label()+" Ctrl+2";
		search_hbox.pack_start(this.search_match_case,false,false,0);


		Gtk.Box rbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		Gtk.RadioButton rbutton;
		
		this.search_mode_rbutton = new Gtk.RadioButton.with_label_from_widget (null, _("terminal text"));
		((Label)this.search_mode_rbutton.get_child()).ellipsize=Pango.EllipsizeMode.END;//allow reducing size of button if needed
		this.search_mode_rbutton.set_active (true);
		this.search_mode_rbutton.tooltip_text=((Label)search_mode_rbutton.get_child()).get_label()+" Ctrl+3";
		rbox.pack_start (this.search_mode_rbutton, false, false, 0);
		this.search_mode_rbutton.toggled.connect ((button)=>{
			if(button.active){
				debug("toggled=%s",button.label);
				this.search_in=SEARCH_MODE.SEARCH_IN_TEXT;
				this.search_wrap_around.sensitive=true;
				this.search_match_case.sensitive=true;
			}
			this.search_text_combo.grab_focus();
			});

		rbutton = new Gtk.RadioButton.with_label_from_widget (this.search_mode_rbutton, _("terminals titles"));
		((Label)rbutton.get_child()).ellipsize=Pango.EllipsizeMode.END;//allow reducing size of button if needed
		rbutton.tooltip_text=((Label)rbutton.get_child()).get_label()+" Ctrl+3";
		rbox.pack_start (rbutton, false, false, 0);
		rbutton.toggled.connect ((button)=>{
			if(button.active){
				debug("toggled=%s",button.label);
				this.search_in=SEARCH_MODE.SEARCH_IN_NAME;
				this.search_wrap_around.sensitive=false;
				this.search_match_case.sensitive=false;				
			}
			this.search_text_combo.grab_focus();
			});
		
		search_hbox.pack_start(rbox,false,false,0);

		var next_button = new Button();
		var settings = Gtk.Settings.get_default();
		if(settings.gtk_button_images){
			Image img = new Image.from_stock ("gtk-go-up",Gtk.IconSize.SMALL_TOOLBAR);
			next_button.add(img);
		}
		next_button.clicked.connect(()=>{
			if(this.search_in == SEARCH_MODE.SEARCH_IN_TEXT){
				unowned AYTab ayt = ((AYTab)this.ayobject.active_tab.object);
				if(!(ayt is VTTerminal)) return;
				unowned VTTerminal vtt = (VTTerminal)ayt;
				this.search_update_pattern(vtt);
				vtt.vte_term.search_find_previous();
			}else
			if(this.search_in == SEARCH_MODE.SEARCH_IN_NAME){
				this.ayobject.search_in_tab_name(this.search_text_combo.get_active_text(),true);//forward
				this.search_text_combo.grab_focus();//if tab was switched it grab focus, so regrab it for search entry				
			}
			});
		next_button.set_focus_on_click(false);
		next_button.tooltip_text=_("Find previous")+" Ctrl+UP";
		next_button.show();
		search_hbox.pack_start(next_button,false,false,0);

		var prev_button = new Button();
		if(settings.gtk_button_images){
			var img = new Image.from_stock ("gtk-go-down",Gtk.IconSize.SMALL_TOOLBAR);
			prev_button.add(img);
		}
		prev_button.clicked.connect(()=>{
			if(this.search_in == SEARCH_MODE.SEARCH_IN_TEXT){
				unowned AYTab ayt = ((AYTab)this.ayobject.active_tab.object);
				if(!(ayt is VTTerminal)) return;
				unowned VTTerminal vtt = (VTTerminal)ayt;
				this.search_update_pattern(vtt);
				vtt.vte_term.search_find_next();
			}else
			if(this.search_in == SEARCH_MODE.SEARCH_IN_NAME){
				this.ayobject.search_in_tab_name(this.search_text_combo.get_active_text(),false);//backward
				this.search_text_combo.grab_focus();//if tab was switched it grab focus, so regrab it for search entry				
			}				
			});
		prev_button.set_focus_on_click(false);
		prev_button.tooltip_text=_("Find next")+" Ctrl+Down";
		prev_button.show();
		search_hbox.pack_start(prev_button,false,false,0);

		var hide_button = new Button();
		if(settings.gtk_button_images){
			var img = new Image.from_stock ("gtk-close",Gtk.IconSize.SMALL_TOOLBAR);
			hide_button.add(img);
		}
		hide_button.clicked.connect(()=>{
			this.ayobject.quick_options_notebook_hide();
			});
		hide_button.set_focus_on_click(false);
		hide_button.tooltip_text=_("Close search dialog")+" Esc";
		hide_button.show();
		search_hbox.pack_end(hide_button,false,false,0);

		return search_hbox;
	}//create_search_box

	private void show_page(OPTIONS_TAB page){
			this.set_current_page(page);
			if(this.ayobject.main_window.maximized){
				var was_h=this.ayobject.main_window.get_allocated_height();
				var was_w=this.ayobject.main_window.get_allocated_width();
				var was_wn=this.ayobject.tasks_notebook.get_allocated_width();
				this.show();
			}else
				this.show();
	}
	public void search_show(){
		unowned AYTab vtt = ((AYTab)this.ayobject.active_tab.object);
		if(!(vtt is VTTerminal)) return;
		if(!((Entry)this.search_text_combo.get_child()).has_focus){
			this.show_page(OPTIONS_TAB.SEARCH);

			var term = ((VTTerminal)this.ayobject.active_tab.object).vte_term;
			if( term.get_has_selection()){
				term.copy_clipboard();
				var display = this.ayobject.main_window.get_display ();
				var clipboard = Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
				// Get text from clipboard
				string text = clipboard.wait_for_text ();
				if(text != null && text != "")
					((Entry)this.search_text_combo.get_child()).set_text(text);
			}
			this.ayobject.search_update();
			this.search_text_combo.grab_focus();
		}else{
			this.ayobject.quick_options_notebook_hide();
		}
	}

	public bool search_add_string(string text){
		debug("search_add_string");
		if(text != null && text != ""){
			unowned TreeIter iter;
			var index = 0;
			//try to find in a list, and place item at start
			if(this.search_text_combo.model.get_iter_first(out iter))
				do{
					unowned string s;
					this.search_text_combo.model.get(iter,0,out s);
					if(s == text){
						this.search_text_combo.remove(index);
						this.search_text_combo.prepend_text(text);
						return true;
						}
					index++;
				}while(this.search_text_combo.model.iter_next(ref iter));

			var count = this.search_text_combo.model.iter_n_children(null);
			if(count>this.search_history_length-1)//max count in a history
				this.search_text_combo.remove(count-1);
			this.search_text_combo.prepend_text(text);
			return true;
			}
		return false;
	}

	public void search_update_pattern(VTTerminal vtt){
					string? s_pattern = null;
					GLib.RegexCompileFlags cflags = 0;
					if( vtt.vte_term.search_get_gregex() != null ){
						var rgx=vtt.vte_term.search_get_gregex();
						s_pattern = rgx.get_pattern();
						cflags=rgx.get_compile_flags();
					}
					string? new_pattern = this.search_text_combo.get_active_text();
					debug(" new_pattern '%s' != '%s'", new_pattern,s_pattern);
					bool needs_udatate = false;
					//if((cflags & GLib.RegexCompileFlags.CASELESS)!=(int)(!vtt.match_case)) {
						cflags = GLib.RegexCompileFlags.OPTIMIZE;
						if(!vtt.match_case)
							cflags |= GLib.RegexCompileFlags.CASELESS;
						//needs_udatate=true;
					//}



					if( (s_pattern == null && new_pattern != null && new_pattern != "") ||
						(s_pattern != null && new_pattern != null && s_pattern != new_pattern) ){
							search_add_string(new_pattern);
							needs_udatate=true;
						}
					if(needs_udatate){
						var reg_exp = new GLib.Regex(new_pattern,cflags);
						vtt.vte_term.search_set_gregex(reg_exp);
					}
	}

	public void save_search_history(){
		string[] search_s = new string [this.search_history_length];
		unowned TreeIter iter;
		var count = this.search_text_combo.model.iter_n_children(null);
		//reverse index
		int index = count-1;
		if(this.search_text_combo.model.get_iter_first(out iter))
			do{
				string s;
				this.search_text_combo.model.get(iter,0,out s);
				search_s[index]=s;
				index--;
			}while(this.search_text_combo.model.iter_next(ref iter) && index>=0);


		this.conf.set_string_list("search_history",search_s);
	}


	public Gtk.Box create_encogings_box(){
		var encogings_box_hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);//new HBox(false,0);
		encogings_box_hbox.halign=Gtk.Align.FILL;
		encogings_box_hbox.valign=Gtk.Align.START;
		encogings_box_hbox.expand=false;
		encogings_box_hbox.name="encogings_box_hbox";


		var builder = new Gtk.Builder ();
		builder.add_from_resource("/org/gnome/altyo/encodings_list.glade");
		builder.add_from_resource("/org/gnome/altyo/main_window_encodings_combo.glade");
		builder.connect_signals(this);
			
		this.encodings_combo = builder.get_object ("encodings_combobox") as Gtk.ComboBox;
		encogings_box_hbox.pack_start(this.encodings_combo,false,false,0);

		//catch deactivate signal from combobox popup,solution was found in gailcombobox.c
		var popup0 = ((Gtk.Menu) ((Gtk.Accessible) this.encodings_combo.get_popup_accessible()).widget);
		popup0.deactivate.connect(()=>{
				this.encodings_combo.grab_focus();
			});
		
		var encodinsg_store = builder.get_object ("encodings_liststore") as Gtk.ListStore;
		encodinsg_store.set_sort_column_id(1,Gtk.SortType.ASCENDING);
		this.encodings_combo.model=encodinsg_store;
		// Encodings autocompletion:
		Gtk.EntryCompletion enc_completion = new Gtk.EntryCompletion ();

		((Entry)this.encodings_combo.get_child()).set_completion(enc_completion);

		enc_completion.set_model (encodinsg_store);

		var completion_info= new CellRendererText();
		enc_completion.pack_end(completion_info,false);
		enc_completion.add_attribute(completion_info, "text", 1);

		enc_completion.set_text_column (0);
		
		((Entry)this.encodings_combo.get_child()).key_press_event.connect((event)=>{
			var keyname = Gdk.keyval_name(event.keyval);
			if( keyname == "Return"){
				unowned AYTab vtt = ((AYTab)this.ayobject.active_tab.object);
				if(!(vtt is VTTerminal)) return false;
				this.apply_encoding(((VTTerminal)vtt));
				return true;
			}else if( keyname == "Escape"){
				this.ayobject.quick_options_notebook_hide();
				return true;
			}
			return false;
		});
		//connect model from encodings_list.glade to main_window_encodings_combo.glade
		var del_combo = builder.get_object ("terminal_delete_binding") as Gtk.ComboBox;
		del_combo.model= builder.get_object ("terminal_delete_binding_liststore") as Gtk.ListStore;
		var bps_combo = builder.get_object ("terminal_backspace_binding") as Gtk.ComboBox;
		bps_combo.model= builder.get_object ("terminal_delete_binding_liststore") as Gtk.ListStore;
		
		var settings = Gtk.Settings.get_default();
		
		var apply_button = new Button();
		if(settings.gtk_button_images){
			var img = new Image.from_stock ("gtk-apply",Gtk.IconSize.SMALL_TOOLBAR);
			apply_button.add(img);
		}
		apply_button.clicked.connect(()=>{
			unowned AYTab vtt = ((AYTab)this.ayobject.active_tab.object);
			if(!(vtt is VTTerminal)) return;
			this.apply_encoding(((VTTerminal)vtt));
			});
		apply_button.set_focus_on_click(false);
		apply_button.tooltip_text=_("Press enter to appy");
		apply_button.show();
		encogings_box_hbox.pack_start(apply_button,false,false,0);

		this.delete_binding_combo = builder.get_object ("terminal_delete_binding") as Gtk.ComboBox;
		encogings_box_hbox.pack_start(this.delete_binding_combo,false,false,0);
		//catch deactivate signal from combobox popup
		var popup1 = ((Gtk.Menu) ((Gtk.Accessible) this.delete_binding_combo.get_popup_accessible()).widget);
		popup1.deactivate.connect(()=>{
				this.encodings_combo.grab_focus();
			});
		this.terminal_backspace_combo = builder.get_object ("terminal_backspace_binding") as Gtk.ComboBox;
		encogings_box_hbox.pack_start(this.terminal_backspace_combo,false,false,0);
		//catch deactivate signal from combobox popup
		var popup2 = ((Gtk.Menu) ((Gtk.Accessible) this.terminal_backspace_combo.get_popup_accessible()).widget);
		popup2.deactivate.connect(()=>{
				this.encodings_combo.grab_focus();
			});
			
		var hide_button = new Button();
		if(settings.gtk_button_images){
			var img = new Image.from_stock ("gtk-close",Gtk.IconSize.SMALL_TOOLBAR);
			hide_button.add(img);
		}
		hide_button.clicked.connect(()=>{
			this.ayobject.quick_options_notebook_hide();
			});
		hide_button.set_focus_on_click(false);
		hide_button.tooltip_text=_("Close dialog")+"Esc";
		hide_button.show();
		encogings_box_hbox.pack_end(hide_button,false,false,0);
		
		return encogings_box_hbox;
	}

		public void encodings_show(){
		AYTab vtt = ((AYTab)this.ayobject.active_tab.object);
		if(!(vtt is VTTerminal)) return;
		debug("this.quick_options_notebook show1");
		if(!((Entry)this.encodings_combo.get_child()).has_focus){
			this.show_page(OPTIONS_TAB.ENCODINGS);
			this.update_encoding(((VTTerminal)vtt));
			this.encodings_combo.grab_focus();
		}else
			this.ayobject.quick_options_notebook_hide();
	}

	public void update_encoding(VTTerminal vtt){

		if(this.page!=OPTIONS_TAB.ENCODINGS) return;//don't update if unnecessary
		
		var term = vtt.vte_term;
		unowned TreeIter iter;
		string term_encoding ="";
		term_encoding +=  term.get_encoding();//copy string
		bool found=false;
		//try to find encoding in a list
		if(this.encodings_combo.model.get_iter_first(out iter))
			do{
				unowned string s;
				this.encodings_combo.model.get(iter,0,out s);
				if(s == term_encoding){
					found=true;
					break;
					}
			}while(this.encodings_combo.model.iter_next(ref iter));
			
		if(found)
			this.encodings_combo.set_active_iter(iter);
		else
			((Entry)this.encodings_combo.get_child()).set_text(term_encoding);

		//prevent double change
		GLib.SignalHandler.block_by_func(this.delete_binding_combo,(void*)this.on_terminal_backspace_combo_changed,this);
		GLib.SignalHandler.block_by_func(this.terminal_backspace_combo,(void*)this.on_terminal_backspace_combo_changed,this);

		this.delete_binding_combo.set_active(term.delete_binding);
		this.terminal_backspace_combo.set_active(term.backspace_binding);
		
		GLib.SignalHandler.unblock_by_func(this.delete_binding_combo,(void*)this.on_terminal_backspace_combo_changed,this);
		GLib.SignalHandler.unblock_by_func(this.terminal_backspace_combo,(void*)this.on_terminal_backspace_combo_changed,this);
	}

	public void update_search(VTTerminal vtt){
		if(this.page!=OPTIONS_TAB.SEARCH) return;//don't update if unnecessary
		this.search_wrap_around.active=((VTTerminal)vtt).vte_term.search_get_wrap_around();
		this.search_match_case.active=((VTTerminal)vtt).match_case;
	}

	public void apply_encoding(VTTerminal vtt){
		var term = vtt.vte_term;
		vtt.lock_setting(VTT_LOCK_SETTING.ENCODING);
		var new_encoding = ((Entry)this.encodings_combo.get_child()).get_text();
		term.set_encoding (new_encoding);
		this.encodings_combo.grab_focus();
	}
	
	[CCode (instance_pos = -1)]
	public void on_terminal_delete_binding_combo_changed(Gtk.ComboBox w){
		AYTab vtt = ((AYTab)this.ayobject.active_tab.object);
		if(!(vtt is VTTerminal)) return;
		((VTTerminal)vtt).lock_setting(VTT_LOCK_SETTING.DELETE_BINDING);
		var term = ((VTTerminal)vtt).vte_term;
		term.delete_binding = (Vte.TerminalEraseBinding)this.delete_binding_combo.get_active();
	}
	
	[CCode (instance_pos = -1)]
	public void on_terminal_backspace_combo_changed(Gtk.ComboBox w){
		AYTab vtt = ((AYTab)this.ayobject.active_tab.object);
		if(!(vtt is VTTerminal)) return;
		((VTTerminal)vtt).lock_setting(VTT_LOCK_SETTING.BACKSPACE_BINDING);
		var term = ((VTTerminal)vtt).vte_term;
		term.backspace_binding = (Vte.TerminalEraseBinding) this.terminal_backspace_combo.get_active();
	}
	[CCode (instance_pos = -1)]
	public void on_terminal_combos_popupdown(Gtk.ComboBox w){
		//escape keybinding
		this.encodings_combo.grab_focus();
	}

}//class QoptNotebook 
