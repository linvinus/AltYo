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

/*
 * Yet another terminal =)
 *
 * valac --pkg gtk+-3.0  ./main.vala ./hvbox.vala ...
 *
 * http://www.valadoc.org/gtk+-3.0/Gtk.Container.html
 * http://developer.gnome.org/gtk3/3.0/GtkContainer.html#gtk-container-get-resize-mode
 * http://developer.gnome.org/gtkmm-tutorial/3.0/sec-custom-containers.html.en
 * https://github.com/mdamt/blankon-panel
 * https://live.gnome.org/Vala/CustomWidgetSamples
 * http://git.xmms2.org/xmms2/abraca/tree/src/widgets/rating_entry.vala?id=ed5e182c4074f1bff56010658a36a75d95807921
 * http://git.freesmartphone.org/?p=vala-terminal.git;a=tree;f=src;h=fca9afcd911ef55db74734080894abfc84576f3c;hb=HEAD
 * http://live.gnome.org/Vala/GStreamerSample
 * http://zetcode.com/tutorials/gtktutorial/gtkevents/
 *
 * pool replace, In C, you can put your buttons and widgets in a GtkOffscreenWindow using gtk_widget_reparent() and then use gtk_offscreen_window_get_pixbuf() to render it onto a GdkPixbuf, which you can then save to a file. Sorry I don't have any Python code, but I don't think the offscreen window is available in PyGTK yet.
 * http://developer.gnome.org/gtk3/3.0/GtkStyleContext.html#gtk-render-frame
 * http://developer.gnome.org/gtk3/3.0/gtk-migrating-GtkApplication.html
 * https://gitorious.org/gnome-boxes/gnome-boxes/blobs/master/src/app.vala
 * http://live.gnome.org/Vala/GSettingsSample
 * http://code.valaide.org/content/example-program-using-keyfile-glib-class-readwrite-ini-files
 * http://developer.gnome.org/pango/stable/PangoMarkupFormat.html
 * http://developer.gnome.org/gcr/3.2/
 *
 * http://www.mono-project.com/GtkSharp_TreeView_Tutorial
 * http://www.kksou.com/php-gtk2/articles/finetune-interactive-search-in-GtkTreeView---Part-4---set-custom-compare-function.php
 * https://mail.gnome.org/archives/commits-list/2012-February/msg03582.html
 * about reparent http://developer.gnome.org/gtk-faq/stable/x635.html
 */

using Gtk;
using Posix;

struct Globals{
	static bool reload = false;
	static bool opt_help = false;
	static string? cmd_conf_file = null;
	static bool toggle = false;
	static string? app_id = null;
	static bool disable_hotkey = false;
	static bool standalone_mode = false;
	static string? path = null;
	static bool config_readonly = false;
	static bool force_debug = false;
	static bool cmd_fullscreen = false;
	static string? cmd_title_tab = null;
	static string? cmd_select_tab = null;
	static string? cmd_close_tab = null;

	[CCode (array_length = false, array_null_terminated = true)]
	public static string[]? exec_file_with_args = null;

	public static const OptionEntry[] options = {
					/*allow show help from remote call*/
					{ "help", 'h', OptionFlags.HIDDEN, OptionArg.NONE, ref Globals.opt_help, null, null },
					{ "reload", 'r', 0, OptionArg.NONE, ref Globals.reload,N_("Reload configuration"), null },
					{ "cfg", 'c', 0, OptionArg.FILENAME, ref Globals.cmd_conf_file,N_("Read configuration from file"), N_("/path/to/config.ini") },
					/*The option takes a string argument, multiple uses of the option are collected into an array of strings. */
					{ "exec", 'e', 0, OptionArg.STRING_ARRAY, ref Globals.exec_file_with_args,N_("Run command in new tab"), N_("\"command arg1 argN...\"") },
					{ "toggle", 0, 0, OptionArg.NONE, ref Globals.toggle,N_("Show/hide window"), null },
					{ "id", 0, 0, OptionArg.STRING, ref Globals.app_id,N_("Set application id, none means disable application id"),"org.gtk.altyo_my,none" },
					{ "disable_hotkey", 0, 0, OptionArg.NONE, ref Globals.disable_hotkey,N_("Disable main hotkey"),null},
					{ "standalone", 0, 0, OptionArg.NONE, ref Globals.standalone_mode,N_("Disable control of window dimension, and set --id=none"),null},
					{ "default_path", 0, 0, OptionArg.STRING, ref Globals.path,N_("Set/update default path"),"/home/user/special" },
					{ "config_readonly", 0, 0, OptionArg.NONE, ref Globals.config_readonly, N_("Lock any configuration changes"), null },
					{ "debug", 'd', 0, OptionArg.NONE, ref Globals.force_debug,N_("Force debug"), null },
					{ "fullscreen", 'f', 0, OptionArg.NONE, ref Globals.cmd_fullscreen,N_("Toggle AltYo in fullscreen mode"), null },
					{ "get-set-tab-title", 't', 0, OptionArg.STRING, ref Globals.cmd_title_tab,N_("Get/Set tab title"), null },
					{ "select-tab", 0, 0, OptionArg.STRING, ref Globals.cmd_select_tab,N_("Select tab by index"), null },
					{ "close-tab", 0, 0, OptionArg.STRING, ref Globals.cmd_close_tab,N_("Close tab by index"), null },
					{ null }
			};

}//Globals

unowned Gtk.Window main_win;

static void signal_handler (int signum) {
	main_win.destroy();
}

static void null_handler(string? domain, LogLevelFlags flags, string message) {
	    }

static void print_handler(string? domain, LogLevelFlags flags, string message) {
		printf("domain:%s message:%s\n",domain,message);
		GLib.stdout.flush();
	    }

/* sync file_workaround_if_focuslost with  workaround_if_focuslost option
 * */
static void sync_workaround(MySettings conf, string file_workaround_if_focuslost){
	bool workaround = conf.get_boolean("workaround_if_focuslost",false);
	bool w_file = GLib.FileUtils.test(file_workaround_if_focuslost,GLib.FileTest.EXISTS);
	debug("workaround != w_file %d != %d",(int)workaround,(int)w_file);
	if(workaround && !w_file){
		GLib.FileUtils.set_data(file_workaround_if_focuslost,null);
	}else if(!workaround && w_file){
		GLib.FileUtils.remove(file_workaround_if_focuslost);
	}	
}

static void configure_debug(MySettings conf){
				if(conf.force_debug) {
					Log.set_handler(null, 
						LogLevelFlags.LEVEL_MASK & 
						(LogLevelFlags.LEVEL_DEBUG | 
						LogLevelFlags.LEVEL_MESSAGE |
						LogLevelFlags.LEVEL_WARNING |
						LogLevelFlags.LEVEL_INFO |
						LogLevelFlags.LEVEL_CRITICAL), print_handler);

				}else if(!conf.get_boolean("debug",false))
					Log.set_handler(null, LogLevelFlags.LEVEL_MASK & ~LogLevelFlags.LEVEL_ERROR, null_handler);
				else{
					var mask = conf.get_string_list("debug_level",{"debug","message","warning","info","critical"});
					LogLevelFlags log_mask = LogLevelFlags.LEVEL_ERROR;//for accerts
					if(mask!=null)
					foreach(var level in mask){
						log_mask = ((level == "debug") ?
						log_mask | LogLevelFlags.LEVEL_DEBUG :
						log_mask);
						log_mask = ((level == "message") ?
						log_mask | LogLevelFlags.LEVEL_MESSAGE :
						log_mask);
						log_mask = ((level == "warning") ?
						log_mask | LogLevelFlags.LEVEL_WARNING :
						log_mask);
						log_mask = ((level == "info") ?
						log_mask | LogLevelFlags.LEVEL_INFO :
						log_mask);
						log_mask = ((level == "critical") ?
						log_mask | LogLevelFlags.LEVEL_CRITICAL :
						log_mask);
					}
					//disable all except log_mask
					//Log.set_handler(null, LogLevelFlags.LEVEL_MASK & ~log_mask, null_handler);
					Log.set_handler(null, LogLevelFlags.LEVEL_MASK & log_mask, print_handler);
				}
}

public class AppAltYo: Gtk.Application {
	public AppAltYo(string? application_id, ApplicationFlags flags){
		Object (application_id:application_id, flags:flags);
	}
	//CCode for vala 0.18 (backport from vala 0.22)
	//prevent segmentation fault if compiled with valac 0.18
	public override bool local_command_line ([CCode (array_length = false, array_null_terminated = true)]ref unowned string[] arguments, out int exit_status){
		exit_status=-1;
        return false;
    }
/* glib compatability hack
 * http://www.trevorpounds.com/blog/?p=103
 * >Building and linking to an older version of libc or using a chroot is a much better, less error prone approach.
 * */
//~[CCode (cname = "__asm__(\".symver memcpy,memcpy@GLIBC_2.2.5\");//",type="")]
//~	public extern void* fake_function();
    
}
int main (string[] args) {
	
	GLib.ApplicationFlags appflags=ApplicationFlags.HANDLES_COMMAND_LINE;
	
	Intl.setlocale (LocaleCategory.ALL, "");
	Intl.bindtextdomain (GETTEXT_PACKAGE, null);
	Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
	Intl.textdomain (GETTEXT_PACKAGE);

	//Gtk.init (ref args);
	Globals.app_id="org.gtk.altyo";//default app id

	/* Parse only --id and --standalone options
	 * others will be parsed in application app.startup.connect event
	 * */
	OptionContext local_ctx = new OptionContext("AltYo");//global var, used in app.startup
	try {
	   local_ctx.set_help_enabled (false);//disable exit from application
	   local_ctx.set_ignore_unknown_options (true);//disable exit from application if wrong parameters
	   local_ctx.add_main_entries(Globals.options, null);
	   string[] args2 = args;         //copy args for local use, original args will be used on remote side
	   unowned string[] args3 = args2;//tmp pointer
	   local_ctx.parse(ref args3);
	   args2=null;                    //destroy
	} catch (Error e) {
	   GLib.stderr.printf("Error initializing: %s\n", e.message);
	   return 1;
	}


	if(Globals.app_id == "none")
		Globals.app_id=null;
	else if(!GLib.Application.id_is_valid(Globals.app_id)){
		printf("Wrong application id \"%s\"\n",Globals.app_id);
		return 1;//stop on error
	}
	
	if(Globals.standalone_mode){
		Globals.disable_hotkey=true;
		Globals.app_id=null;
		appflags|=GLib.ApplicationFlags.NON_UNIQUE;
	}

	/******************************************************************/
	/* use file as special configuration marker
	 * because we should not parse config.ini file yet
	 * later we will sync it in sync_workaround()
	 * simple and fast
	 * */
	string file_workaround_if_focuslost = GLib.Environment.get_user_config_dir()+"/altyo/workaround_if_focuslost";
	if(GLib.FileUtils.test(file_workaround_if_focuslost,GLib.FileTest.EXISTS) ){
		/* more info in README.md in FAQ.
		 * */
		if(!GLib.Environment.set_variable("GDK_CORE_DEVICE_EVENTS","1",true)) //must be set before new AppAltYo()
			printf("altyo: Unable to set GDK_CORE_DEVICE_EVENTS=1\n");
		else if(Globals.force_debug)
			printf("altyo: set GDK_CORE_DEVICE_EVENTS=1\n");
	}
	/******************************************************************/
	
    var app = new AppAltYo(Globals.app_id, appflags);

	//remote args usage
    app.command_line.connect((command_line)=>{//ApplicationCommandLine

			if(!command_line.get_is_remote() )//local command line was handled in app.startup
					return 0;//just ignore it

			string[] argv = command_line.get_arguments();
			debug("app.command_line.connect argv.length=%d",argv.length);

			OptionContext ctx = new OptionContext("AltYo");
			ctx.add_main_entries(Globals.options, null);

			if(argv.length==1 ){//no parameters
				unowned List<weak Window> list = app.get_windows();
				if(list!=null)
					((VTMainWindow)list.data).pull_down(); //another altyo already running, show it
				return 0;//ok
			}else{
				ctx.set_help_enabled (false);//disable exit from application if wrong parameters
				unowned string[] pargv=argv;
				Globals.exec_file_with_args=null;//clear array
				Globals.cmd_conf_file=null;
				Globals.reload=false;
				Globals.opt_help=false;
				Globals.toggle=false;
				Globals.path=null;
				Globals.force_debug=false;
				
				Globals.cmd_fullscreen = false;
				Globals.cmd_title_tab = null;
				Globals.cmd_select_tab = null;
				Globals.cmd_close_tab = null;

				try {
					if(!ctx.parse(ref pargv))return 3;
				} catch (Error e) {
						command_line.print("Error initializing: %s\n", e.message);
				}
				
				if (Globals.opt_help) {
					command_line.printerr (ctx.get_help (true, null));
					Globals.opt_help=false;
				}
								
				debug("app.command_line.connect reload=%d",(int)Globals.reload);
				VTMainWindow remote_window=null;
				unowned List<weak Window> list = app.get_windows();
				if(list!=null)
					remote_window=((VTMainWindow)list.data);
				else{
					command_line.print("Err: remote window not found");
					return 2;
				}

				if(Globals.force_debug){
					configure_debug(remote_window.conf);
				}else 
				if(Globals.reload){
					remote_window.conf.load_config();
				}else
				if(Globals.exec_file_with_args!=null){				
					foreach(var s in Globals.exec_file_with_args){
						debug("exec %s",s);
						if(Globals.path!=null){
							remote_window.conf.default_path=Globals.path;
						}
						remote_window.ayobject.add_tab_with_title(s,s);
					}

					if(remote_window.current_state == WStates.HIDDEN)
						remote_window.pull_down();
				}else
				if(Globals.toggle){
					remote_window.toggle_window();
				}else
				if(Globals.cmd_fullscreen){
					if(remote_window.maximized)
						remote_window.maximized=false;
					else
						remote_window.maximized=true;
				}else
				if(remote_window.conf.get_boolean("window_allow_remote_control",false)){
					if(Globals.cmd_title_tab!=null){
						var current_index=remote_window.ayobject.cmd_get_tab_index();
						var count=remote_window.ayobject.cmd_get_tabs_count();
						if(Globals.cmd_title_tab!=""){
							var s_arr = Globals.cmd_title_tab.split (":",2);
							uint64 index=0;/*index from user starting from 1*/
							if(s_arr.length==2 && uint64.try_parse(s_arr[0],out index) && index<=count && index>0){
								if(s_arr[1]=="") s_arr[1]=null;
								command_line.print("new title=%d:%s\n",(int)index,s_arr[1]);
								remote_window.ayobject.cmd_set_tab_title((uint)index-1,s_arr[1]);
							}else{
								if(s_arr.length!=2)
									command_line.print("usage:\n\t-t \"3:new title\"\n\t-t \"\"\n");
									
								if(index>count)
									command_line.print("Err: index>count (%d > %d)\n",(int)index,(int)count);
								if(index==0)
									command_line.print("Err: index must be > 1\n");
							}
						}else{
							command_line.print("%d/%d \n",current_index+1,(int)count);
							for(var i=0; i<count; i++){
								command_line.print("%d:%s\n",i+1,remote_window.ayobject.cmd_get_tab_title(i));
							}
						}
					}else
					if(Globals.cmd_select_tab!=null){
						var count=remote_window.ayobject.cmd_get_tabs_count();
						uint64 index=0;/*index from user starting from 1*/
						if(uint64.try_parse(Globals.cmd_select_tab,out index) && index<=count && index>0 ){
							remote_window.ayobject.cmd_activate_tab((uint)(index-1));
							command_line.print("selected %d\n",(int)index);
						}else{
							if(index>count)
								command_line.print("Err: index>count (%d > %d)\n",(int)index,(int)count);
							if(index==0)
								command_line.print("Err: index must be > 1\n");							
						}
					}else
					if(Globals.cmd_close_tab!=null){
						var count=remote_window.ayobject.cmd_get_tabs_count();
						uint64 index=0;/*index from user starting from 1*/
						if(uint64.try_parse(Globals.cmd_close_tab,out index) && index<=count && index>0 ){
							remote_window.ayobject.close_tab((int)(index-1));
							command_line.print("closed %d\n",(int)index);
						}else{
							if(index>count)
								command_line.print("Err: index>count (%d > %d)\n",(int)index,(int)count);
							if(index==0)
								command_line.print("Err: index must be > 1\n");
						}
					}
				}//if window_allow_remote_control
				else{
					if(Globals.cmd_title_tab!=null || Globals.cmd_select_tab!=null || Globals.cmd_close_tab!=null)
						command_line.print("Err: remote commands is disabled in configuration file!\n");
				}
				
				Globals.reload=false;

				return 2;//exit status
			}
		});//app.command_line.connect

	app.startup.connect(()=>{//first run
				debug("app.startup.connect");
				if (Globals.opt_help) {
					printf(local_ctx.get_help (true, null));
					return;//show help and exit
				}
				var conf = new MySettings(Globals.cmd_conf_file,Globals.standalone_mode);
				conf.readonly=Globals.config_readonly;
				conf.disable_hotkey=Globals.disable_hotkey;
				conf.default_path=Globals.path;
				conf.force_debug=Globals.force_debug;

				if(!conf.opened){
					printf("Unable to open configuration file!\n");
					Posix.exit(1);
				}
				
				conf.get_boolean("window_allow_remote_control",false);//remember option type

				configure_debug(conf);
				sync_workaround(conf,file_workaround_if_focuslost);
				
				debug("git_hash=%s",AY_GIT_HASH);
				debug("changelog_tag=%s",AY_CHANGELOG_TAG);

				conf.on_load.connect(()=>{
					configure_debug(conf);
					sync_workaround(conf,file_workaround_if_focuslost);
				});

				var win = new VTMainWindow (WindowType.TOPLEVEL);
				win.set_application(app);
				win.CreateVTWindow(conf);
				main_win=win;

				if(Globals.exec_file_with_args!=null){
					foreach(var s in Globals.exec_file_with_args){
						debug("exec %s",s);
						win.ayobject.add_tab_with_title(s,s);
					}
					
					
				}
				
				sigaction_t action = sigaction_t ();
				action.sa_handler = signal_handler;
				/* Hook up signal handlers */
				sigaction (SIGINT, action, null);
				sigaction (SIGQUIT, action, null);
				//sigaction (SIGABRT, action, null);//something wrong! don't save file
				sigaction (SIGTERM, action, null);
				sigaction (SIGKILL, action, null);
				Gtk.main ();

		});//app.startup.connect
	var status = app.run(args);

    return status;
}
