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


#if VALA_0_17
#else //VALA_0_16 and older
	/*
	 * quirk for Ubuntu precise (12.04)
	 * bug 675403.
	 * https://mail.gnome.org/archives/commits-list/2012-June/msg05401.html
	*/ 
	[CCode (cname = "gtk_style_context_lookup_color")]
	extern bool vala_016_style_context_lookup_color(Gtk.StyleContext context,string color_name,out Gdk.RGBA color);
#endif

public enum CFG_CHECK{
	OK,
	REPLACE,
	USE_DEFAULT
	}

public enum VER{
	major,
	minor,
	rc
	}

public enum DISTRIB_ID{
	UBUNTU,
	OTHER
	}
	
public delegate CFG_CHECK check_string(ref string s);
public delegate CFG_CHECK check_string_list(ref string[] sl);
public delegate CFG_CHECK check_integer(ref int i);
public delegate CFG_CHECK check_double(ref double d);
public delegate CFG_CHECK check_boolean(ref bool b);
public delegate CFG_CHECK check_integer_list(ref int[] il);

[SimpleType]
public enum CFG_TYPE{
	TYPE_UNKNOWN,
	TYPE_BOOLEAN,
	TYPE_DOUBLE,
	TYPE_INTEGER,
	TYPE_STRING,
	TYPE_STRING_LIST,
	TYPE_ACCEL_STRING,
	TYPE_INTEGER_LIST,
	}


public class MySettings : Object {
	private KeyFile kf;
	public string conf_file;
	private string profile {get;set;default = "profile0";}
	private string accel_section {get;set;default = "KeyBindings";}
	private string qconnection_section {get;set;default = "QConnections";}
	public bool opened {get;set; default = false;}
	private bool changed {get;set; default = false;}
	private HashTable<string, int> typemap;
	public  bool disable_hotkey = false;
	public  bool standalone_mode = false;
	public  bool readonly = false;
	public string? default_path = null;
	public DISTRIB_ID DISTR_ID=DISTRIB_ID.OTHER;
	public  bool reduce_memory_usage = false;
	public  bool force_debug = false;

	public signal void on_load();

	public MySettings(string? cmd_conf_file=null,bool? standalone=false ){
		this.typemap = new HashTable<string, int> (str_hash, str_equal);
		if(standalone!=null)
			this.standalone_mode=standalone;
			
		if(cmd_conf_file!=null)
			this.conf_file = cmd_conf_file;
		else{
			
			if(standalone!=null && this.standalone_mode==true)
				this.conf_file = GLib.Environment.get_user_config_dir()+"/altyo"+"/config-standalone.ini";
			else
				this.conf_file = GLib.Environment.get_user_config_dir()+"/altyo"+"/config.ini";
		}
		kf = new KeyFile();
		this.load_config();
		if(this.opened){
			this.set_integer_list("profile_version",this.check_for_migrate(this.get_integer_list("profile_version", {0,0,0}, (ref new_val)=>{
				if(new_val.length != 3){
					new_val = {0,0,0};
					return CFG_CHECK.REPLACE;
				}
				return CFG_CHECK.OK;
				})) );
			/* some options related only for ubuntu, so to run same binary 
			 * try to guess linux distribution on which we are have runned,
			 * guess only once, then save in config*/
			string distr=this.get_string("distrib_id","");
			if(distr==""){
				distr=this.check_linux_distribution();
				this.set_string("distrib_id",distr);
			}
			if(distr=="ubuntu")
				this.DISTR_ID=DISTRIB_ID.UBUNTU;

			this.reduce_memory_usage = this.get_boolean("reduce_memory_usage",false);
		}
	}

	public void load_config(){
		debug("loading config...");
		if(!GLib.FileUtils.test(this.conf_file,GLib.FileTest.EXISTS) )
					GLib.DirUtils.create_with_parents(GLib.Path.get_dirname(this.conf_file),502);//755

				try {
						kf.load_from_file(this.conf_file, KeyFileFlags.KEEP_COMMENTS);
						this.opened = true;
						this.changed=false;
						this.on_load();
				} catch (GLib.KeyFileError.PARSE err) {
						this.opened = true;
						this.changed=false;
						this.on_load();
				} catch (KeyFileError err) {
						debug("Filed: kf.load_from_file");
						warning (err.message);
						this.opened = false;
				} catch (FileError err) {
						//create default settings
						kf.set_string  (this.profile, "custom_command", "");
						/*
						 * other settings will be filled on reation time
						 */
						var str = kf.to_data (null);
						try {
								FileUtils.set_contents (this.conf_file, str, str.length);
								this.opened = true;
						} catch (FileError err) {
								warning (err.message);
						}
				}				
	}

	public void reload_config(){
		this.on_load();
	}

	public void save(bool force=false){
		if(this.readonly==false){
			if(this.changed || force){
				var str = kf.to_data (null);
				try {
					debug("\tsave settings into file=%s\n",this.conf_file);
					FileUtils.set_contents (this.conf_file, str, str.length);
				} catch (FileError err) {
					warning (err.message);
				}
			}
		}else
			debug("config is read only, all changes will be lost!\n");
		this.changed=false;
	}

	public void reset_to_defaults(){
			var tmp=this.conf_file;
			this.conf_file+=".bak";
			this.save(true);//save backup
			this.conf_file=tmp;
			try {
				debug("\treset_to_defaults settings file=%s\n",this.conf_file);
				FileUtils.set_contents (this.conf_file, "", 0);
				this.load_config();
			} catch (FileError err) {
				warning (err.message);
			}
	}

	private int[] check_for_migrate(int[] version){

		if(version[VER.major]==0 && version[VER.minor]==0){
			version[VER.minor]=3;//update settings to latest version 0.3
		}
			
		if(version[VER.major]==0 && version[VER.minor]==3 && version[VER.rc]<5){
			/*migrate from 0.3 rc4 to rc5
			* move autostart file*/
			string old_default_desktop_file=GLib.Environment.get_user_config_dir()+"/autostart/altyo.desktop";
			string new_default_desktop_file=GLib.Environment.get_user_config_dir()+"/autostart/org.gtk.altyo.desktop";
			
			if(GLib.FileUtils.test(old_default_desktop_file,GLib.FileTest.EXISTS) )
						GLib.FileUtils.rename(old_default_desktop_file,new_default_desktop_file);

			version[VER.rc]=5;//update version
		}

		if(version[VER.major]==0 && version[VER.minor]==3 && version[VER.rc]<6){
			try {
				var old=kf.get_boolean(this.profile,"window_hide_after_close_last_tab");
				if(old)
					kf.set_integer(this.profile,"window_action_on_close_last_tab",1);//restart shell and hide
				kf.remove_key(this.profile,"window_hide_after_close_last_tab");
				this.changed=true;
			}catch (KeyFileError err) {}
			
			version[VER.rc]=6;//update version
		}

		/*if was 0.3.6
		 * update program_style option, gtk prior 3.8 have memory leak when text-shadow is used.
		 * */
		if(version[VER.major]==0 && version[VER.minor]==3 && version[VER.rc]<7){
			if(Gtk.get_major_version()>=3 && Gtk.get_minor_version()<7){
				try {
					string old=kf.get_string(this.profile,"program_style");
					if(old!=null && old!="" ){
						Regex regex = new Regex ("VTToggleButton\\:active \\{ text-shadow\\: 1px 1px 2px #005555\\;\\}");
						try {
							string result = regex.replace(old,-1,0,"");
							kf.set_string(this.profile,"program_style",result);
							this.changed=true;
						}catch (RegexError e) {
							stdout.printf ("Error: %s\n", e.message);
						}						
							kf.set_integer(this.profile,"window_action_on_close_last_tab",1);//restart shell and hide
					}
				}catch (KeyFileError err) {}
			}
			
			version[VER.rc]=7;//update version
		}

		/*if was 0.3.7
		 * update program_style option, fix background for quick_options_notebook
		 * */
		if(version[VER.major]==0 && version[VER.minor]==3 && version[VER.rc]<8){
				try {
					string old=kf.get_string(this.profile,"program_style");
					if(old!=null && old!="" ){
						Regex regex = new Regex ("HVBox,#search_hbox\\{");
						try {
							string result = regex.replace(old,-1,0,"HVBox,#quick_options_notebook {");
							kf.set_string(this.profile,"program_style",result);
							this.changed=true;
						}catch (RegexError e) {
							stdout.printf ("Error: %s\n", e.message);
						}						
					}
				}catch (KeyFileError err) {}
			version[VER.rc]=8;//update version
		}
		/*if was 0.3.8
		 * now window position and size is unique for each monitor
		 * */
		if(version[VER.major]==0 && version[VER.minor]==3 && version[VER.rc]<9){
			try {
				string monitor=kf.get_string(this.profile,"window_default_monitor");
				if(monitor!=null && monitor!=""){
					kf.set_integer(this.profile,"terminal_width_%s".printf(monitor),kf.get_integer(this.profile,"terminal_width"));
					kf.set_integer(this.profile,"terminal_height_%s".printf(monitor),kf.get_integer(this.profile,"terminal_height"));
					kf.set_integer(this.profile,"window_position_y_%s".printf(monitor),kf.get_integer(this.profile,"window_position_y"));
					kf.set_integer(this.profile,"window_position_x_%s".printf(monitor),kf.get_integer(this.profile,"position"));
				}
				
				kf.remove_key(this.profile,"terminal_height");
				kf.remove_key(this.profile,"terminal_width");
				kf.remove_key(this.profile,"window_position_y");
				kf.remove_key(this.profile,"position");
			}catch (KeyFileError err) {}
			
			version[VER.rc]=9;//update version
		}
		/*if was 0.3.9
		 * update program_style option, fix background for settings tab
		 * */
		if(version[VER.major]==0 && version[VER.minor]==3 && version[VER.rc]<10){
				try {
					string old=kf.get_string(this.profile,"program_style");
					if(old!=null && old!="" ){
						kf.set_string(this.profile,"program_style",old+" #settings-scrolledwindow{ background-color: @bg_color;} ");
					}
				}catch (KeyFileError err) {}
			version[VER.rc]=10;//update version
		}		
		/*if was 0.3.10
		 * update program_style option, remove button shadow, disable animation
		 * */
		if(version[VER.major]==0 && version[VER.minor]==3 && version[VER.rc]<11){
				try {
					string old=kf.get_string(this.profile,"program_style");
					if(old!=null && old!="" ){
						Regex regex = new Regex ("#tasks_notebook");
						try {
							string result = regex.replace(old,-1,0,".window_multitabs");
							old=result;
						}catch (RegexError e) {
							stdout.printf ("Error: %s\n", e.message);
						}

						kf.set_string(this.profile,"program_style",old+" VTToggleButton{ box-shadow: none;"+((Gtk.get_major_version()>=3 && Gtk.get_minor_version()>4)?"transition-duration: 0s;":"")+"} .window_single_tab {border-width: 2px 2px 2px 2px;border-color: #3C3B37;border-style: solid;}");
					}
				}catch (KeyFileError err) {}
			version[VER.rc]=11;//update version
		}
		/*if was 0.3.11
		 * update program_style option, new theme handling
		 * */
		if(version[VER.major]==0 && version[VER.minor]==3 && version[VER.rc]<12){
				try {
					string old=kf.get_string(this.profile,"program_style");
					if(old!=null && old!="" ){
						kf.remove_key(this.profile,"program_style");
						kf.remove_key(this.profile,"tab_title_format");
						kf.remove_key(this.profile,"tab_title_format_regex");
					}
				}catch (KeyFileError err) {}
			version[VER.rc]=12;//update version
		}	
		return version;
	}
	
	private  string check_linux_distribution(){
		string contents;
		size_t length;
		if( GLib.FileUtils.test("/etc/lsb-release",GLib.FileTest.EXISTS) ){
			try{
				GLib.FileUtils.get_contents("/etc/lsb-release",out contents,out length);
				if(length>1 && Regex.match_simple(".*ubuntu.*",contents,GLib.RegexCompileFlags.CASELESS|GLib.RegexCompileFlags.MULTILINE)){
					return "ubuntu";
				}
			} catch (FileError err) {
			}
		}else
		if( GLib.FileUtils.test("/etc/issue",GLib.FileTest.EXISTS) ){
			try{
				GLib.FileUtils.get_contents("/etc/issue",out contents,out length);
				if(length>1 && Regex.match_simple(".*ubuntu.*",contents,GLib.RegexCompileFlags.CASELESS|GLib.RegexCompileFlags.MULTILINE)){
					return "ubuntu";
				}
			} catch (FileError err) {
			}			
		}
		return "other";
	}

	public bool get_boolean (string key,bool? def,check_boolean? check_cb=null){
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,(int)CFG_TYPE.TYPE_BOOLEAN);
		else if(key_type!=CFG_TYPE.TYPE_BOOLEAN)
			GLib.assert(key_type==CFG_TYPE.TYPE_BOOLEAN);

		bool ret = def;
			try {
				ret = kf.get_boolean(this.profile,key);
				if(check_cb!=null)
					switch(check_cb(ref ret)){
						case CFG_CHECK.REPLACE:
							this.changed=true;
							kf.set_boolean(this.profile,key,ret);
						break;
						case CFG_CHECK.USE_DEFAULT:
							ret=def;
							this.changed=true;
							kf.set_boolean(this.profile,key,def);
						break;
					}
			} catch (KeyFileError err) {
				warning (err.message);
				this.changed=true;
				kf.set_boolean(this.profile,key,def);
				ret = def;
			}
		return ret;
		}

	public int get_integer (string key,int def,check_integer? check_cb=null){
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_INTEGER);
		else if(key_type!=CFG_TYPE.TYPE_INTEGER)
			GLib.assert(key_type==CFG_TYPE.TYPE_INTEGER);

		int ret = def;
			try {
				ret = kf.get_integer(this.profile,key);
				if(check_cb!=null)
					switch(check_cb(ref ret)){
						case CFG_CHECK.REPLACE:
							this.changed=true;
							kf.set_integer(this.profile,key,ret);
						break;
						case CFG_CHECK.USE_DEFAULT:
							ret=def;
							this.changed=true;
							kf.set_integer(this.profile,key,def);
						break;
					}
			} catch (KeyFileError err) {
				warning (err.message);
				this.changed=true;
				kf.set_integer(this.profile,key,def);
				ret = def;
			}
		return ret;
		}
		
	public int[] get_integer_list (string key,int[] def,check_integer_list? check_cb=null){
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_INTEGER_LIST);
		else if(key_type!=CFG_TYPE.TYPE_INTEGER_LIST)
			GLib.assert(key_type==CFG_TYPE.TYPE_INTEGER_LIST);

		int[] ret = def;
			try {
				ret = kf.get_integer_list(this.profile,key);
				if(check_cb!=null)
					switch(check_cb(ref ret)){
						case CFG_CHECK.REPLACE:
							this.changed=true;
							kf.set_integer_list(this.profile,key,ret);
						break;
						case CFG_CHECK.USE_DEFAULT:
							ret=def;
							this.changed=true;
							kf.set_integer_list(this.profile,key,def);
						break;
					}
			} catch (KeyFileError err) {
				warning (err.message);
				this.changed=true;
				kf.set_integer_list(this.profile,key,def);
				ret = def;
			}
		return ret;
		}
		
	public double get_double (string key,double def,check_double? check_cb=null){
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_DOUBLE);
		else if(key_type!=CFG_TYPE.TYPE_DOUBLE)
			GLib.assert(key_type==CFG_TYPE.TYPE_DOUBLE);

		double ret = def;
			try {
				ret = kf.get_double(this.profile,key);
				if(check_cb!=null)
					switch(check_cb(ref ret)){
						case CFG_CHECK.REPLACE:
							this.changed=true;
							kf.set_double(this.profile,key,ret);
						break;
						case CFG_CHECK.USE_DEFAULT:
							ret=def;
							this.changed=true;
							kf.set_double(this.profile,key,def);
						break;
					}
			} catch (KeyFileError err) {
				warning (err.message);
				this.changed=true;
				kf.set_double(this.profile,key,def);
				ret = def;
			}
		return ret;
		}

	public string[] get_string_list (string key, string[] def,check_string_list? check_cb=null) {
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_STRING_LIST);
		else if(key_type!=CFG_TYPE.TYPE_STRING_LIST)
			GLib.assert(key_type==CFG_TYPE.TYPE_STRING_LIST);

		string[] ret = def;
			try {
				ret = kf.get_string_list(this.profile,key);
				if(check_cb!=null)
					switch(check_cb(ref ret)){
						case CFG_CHECK.REPLACE:
							this.changed=true;
							kf.set_string_list(this.profile,key,ret);
						break;
						case CFG_CHECK.USE_DEFAULT:
							ret=def;
							this.changed=true;
							kf.set_string_list(this.profile,key,def);
						break;
					}
			} catch (KeyFileError err) {
				warning (err.message);
				this.changed=true;
				kf.set_string_list(this.profile,key,def);
				ret = def;
			}
		return ret;
		}

	public string? get_string(string key, string def,check_string? check_cb=null) {
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_STRING);
		else if(key_type!=CFG_TYPE.TYPE_STRING)
			GLib.assert(key_type==CFG_TYPE.TYPE_STRING);

		string ret = def;
			try {
				ret = kf.get_string(this.profile,key);
				if(check_cb!=null)
					switch(check_cb(ref ret)){
						case CFG_CHECK.REPLACE:
							this.changed=true;
							kf.set_string(this.profile,key,ret);
						break;
						case CFG_CHECK.USE_DEFAULT:
							ret=def;
							this.changed=true;
							kf.set_string(this.profile,key,def);
						break;
					}
			} catch (KeyFileError err) {
				warning (err.message);
				this.changed=true;
				kf.set_string(this.profile,key,def);
				ret = def;
			}
		return ret;//can be null
		}


	public bool set_string_list (string key, string[] def) {
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_STRING_LIST);
		else if(key_type!=CFG_TYPE.TYPE_STRING_LIST)
			GLib.assert(key_type==CFG_TYPE.TYPE_STRING_LIST);

		bool ret = true;
			try {
				this.changed=true;
				kf.set_string_list(this.profile,key,def);
			} catch (KeyFileError err) {
				warning (err.message);
				ret = false;
			}
		return ret;
		}

	public bool set_string(string key, string? def) {
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_STRING);
		else if(key_type!=CFG_TYPE.TYPE_STRING)
			GLib.assert(key_type==CFG_TYPE.TYPE_STRING);

		bool ret = true;
			try {
				this.changed=true;
				if(def==null)
					kf.set_string(this.profile,key,"");
				else
					kf.set_string(this.profile,key,def);
			} catch (KeyFileError err) {
				warning (err.message);
				ret = false;
			}
		return ret;
		}

	public bool set_integer (string key,int def){
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_INTEGER);
		else if(key_type!=CFG_TYPE.TYPE_INTEGER)
			GLib.assert(key_type==CFG_TYPE.TYPE_INTEGER);

		bool ret = true;
			try {
				this.changed=true;
				kf.set_integer(this.profile,key,def);
			} catch (KeyFileError err) {
				warning (err.message);
				ret = false;
			}
		return ret;
		}
		
	public bool set_integer_list (string key,int[] def){
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_INTEGER_LIST);
		else if(key_type!=CFG_TYPE.TYPE_INTEGER_LIST)
			GLib.assert(key_type==CFG_TYPE.TYPE_INTEGER_LIST);

		bool ret = true;
			try {
				this.changed=true;
				kf.set_integer_list(this.profile,key,def);
			} catch (KeyFileError err) {
				warning (err.message);
				ret = false;
			}
		return ret;
		}

	public bool set_boolean (string key,bool def){
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_BOOLEAN);
		else if(key_type!=CFG_TYPE.TYPE_BOOLEAN)
			GLib.assert(key_type==CFG_TYPE.TYPE_BOOLEAN);

		bool ret = true;
			try {
				this.changed=true;
				kf.set_boolean(this.profile,key,def);
			} catch (KeyFileError err) {
				warning (err.message);
				ret = false;
			}
		return ret;
		}

	public bool set_double (string key,double def,uint digits_after_comma){
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_DOUBLE);
		else if(key_type!=CFG_TYPE.TYPE_DOUBLE)
			GLib.assert(key_type==CFG_TYPE.TYPE_DOUBLE);

		bool ret = true;
			try {
				this.changed=true;
				if(digits_after_comma>0){
					string S="%.2f".printf(round_double(def,digits_after_comma));
					//printf string is localized, but KeyFile allow only
					//dot as digits delimeter in double,
					//so replace comma with dot
					//is there better solution?
					S=S.replace(",",".");
					debug("set_double=%s",S);
					kf.set_string(this.profile,key,S);
				}else{
					kf.set_double(this.profile,key,def);
				}
			} catch (KeyFileError err) {
				warning (err.message);
				ret = false;
			}
		return ret;
		}

	public string get_accel_string(string key, string def,check_string? check_cb=null) {
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_ACCEL_STRING);
		else if(key_type!=CFG_TYPE.TYPE_ACCEL_STRING)
			GLib.assert(key_type==CFG_TYPE.TYPE_ACCEL_STRING);

		string ret = def;
			try {
				ret = kf.get_string(this.accel_section,key);
			} catch (KeyFileError err) {
				warning (err.message);
				this.changed=true;
				kf.set_string(this.accel_section,key,def);
				ret = def;
			}
		return ret;
		}

	public bool set_accel_string(string key, string def) {
		int key_type;
		if(!this.typemap.lookup_extended(key,null,out key_type))
			this.typemap.insert(key,CFG_TYPE.TYPE_ACCEL_STRING);
		else if(key_type!=CFG_TYPE.TYPE_ACCEL_STRING)
			GLib.assert(key_type==CFG_TYPE.TYPE_ACCEL_STRING);

		bool ret = true;
			try {
				this.changed=true;
				kf.set_string(this.accel_section,key,def);
			} catch (KeyFileError err) {
				warning (err.message);
				ret = false;
			}
		return ret;
		}

	public string[] get_qconnection_list () {
		string[] ret = {};
		if(kf.has_group(this.qconnection_section)){
				try {
					ret = kf.get_keys(this.qconnection_section);
				} catch (KeyFileError err) {
					warning (err.message);
					this.changed=true;
					//if(err.code == GLib.KeyFileError.GROUP_NOT_FOUND)
						kf.set_string(this.qconnection_section,null,"");
					ret = {};
				}
			}
		return ret;
		}

	public string[] get_qconnection_data_list (string key) {
		string[] ret = {};
			try {
				ret = kf.get_string_list(this.qconnection_section,key);
			} catch (KeyFileError err) {
				warning (err.message);
				//kf.set_string_list(this.qconnection_section,key,{});
				ret = {};
			}
		return ret;
		}

	public string[] get_profile_keys (){
		return this.kf.get_keys (this.profile);
	}

	public CFG_TYPE  get_key_type(string key){
		int key_type;
		if(this.typemap.lookup_extended(key,null,out key_type)){
			return (CFG_TYPE)key_type;
		}else{
			debug("get_key_type TYPE_UNKNOWN for key=%s",key);
			return CFG_TYPE.TYPE_UNKNOWN;
		}
	}

	public bool check_markup(string pattern,out string err_text){
		bool ret=true;
		Pango.AttrList attr_list;
		string text;
		unichar accel_char;
		try {
			Pango.parse_markup(pattern,-1,(unichar)"_",out attr_list, out text, out accel_char);
		} catch( Error re ) {
			ret=false;
			debug("check_markup err:%s",re.message);
			err_text=re.message;
		}
		return ret;
	}

	public bool check_regex(string pattern,out string err_text){
		bool ret=true;
		try {
			var regex = new Regex( pattern, RegexCompileFlags.EXTENDED );
		} catch( RegexError re ) {
			ret=false;
			debug("check_regex err:%s",re.message);
			err_text=re.message;
		}
		return ret;
	}
/*	todo
public get_boolean_list
public get_comment
public get_double
public get_double_list
public get_groups
public get_int64
public get_integer
public get_integer_list
public get_keys
public get_locale_string
public get_locale_string_list
public get_start_group
public get_string
public get_string_list
public get_uint64
public get_value
public has_group
public has_key
public load_from_data
public load_from_data_dirs
public load_from_dirs
public load_from_file
public remove_comment
public remove_group
public remove_key
public set_boolean
public set_boolean_list
public set_comment
public set_double
public set_double_list
public set_int64
public set_integer
public set_integer_list
public set_list_separator
public set_locale_string
public set_locale_string_list
public set_string
public set_string_list
public set_uint64
public set_value
public to_data
*/
}

public string hexRGBA(Gdk.RGBA c){
  //output #AABBCC
  return "#%02hhX%02hhX%02hhX".printf((char)((int)(c.red*255)),(char)((int)(c.green*255)),(char)((int)(c.blue*255)));
}

public double round_double(double def,uint digits_after_comma){
					uint round=1;
					double rest=5.0;
					while(digits_after_comma-->0){
						round*=10;
					}
					rest/=(round*10);
					int i=(int)((def+rest) * round);//round
					def=(double)((double)(i)/(double)round);
          return def;
}

extern void gtk_style_context_get_style_property (Gtk.StyleContext context,
                                      string property_name,
                                      ref Value          value);
public string replace_color_in_markup(Widget w,string markup,StateFlags state=Gtk.StateFlags.NORMAL){
        Regex regex = new Regex ("""(foreground\=['"]\s*(?P<foreground>[^'"]+)\s*['"])|(background\=['"]\s*(?P<background>[^'"]+)\s*['"])""");
        int offset=0;
        var ret = regex.replace_eval(markup,-1,0,0, (match_info, result)=>{
            int start_pos, end_pos;
            string? name;
            unowned Gdk.RGBA? tmp=null;
            name = match_info.fetch_named("foreground");
            if(name!=null){
              if(name.get_char(0)!='#'){//if color is css color name
                //try to guess
                Gdk.RGBA? color=null;
                GLib.ParamSpec? prop = w.find_style_property(name);
                if(prop!=null){
                  var context = w.get_style_context();
                  var old=context.get_state();
                  context.set_state(state);
                  var val = new Value(typeof(Gdk.RGBA));
                  //vala bug, vala binding for gtk_style_context_get_style_property is broken
                  //context.get_style_property(name,val);
                  gtk_style_context_get_style_property(context,name,ref val);
                  if(val.get_boxed()!=null)
					color=*(Gdk.RGBA*)val.get_boxed();
                  context.set_state(old);
//~                   w.style_get(name,out tmp);
//~                   color=tmp;
//~                   tmp.free();
                }
				#if VALA_0_17
				if(color!=null || w.get_style_context().lookup_color(name,out color) ){
				#else
				if(color!=null || vala_016_style_context_lookup_color(w.get_style_context(),name,out color) ){
				#endif
                  result.append("foreground='");
                  result.append(hexRGBA(color));
                  result.append("'");
                }else
				  debug("markup: wrong color '%s', foreground will be ignored",name);
              }else
                result.append(match_info.fetch(0));
            }else{
              name = match_info.fetch_named("background");

              if(name!=null){
                if(name.get_char(0)!='#'){//if color is css color name
                  Gdk.RGBA? color=null;
                  GLib.ParamSpec? prop = w.find_style_property(name);
                  if(prop!=null){
                      var context = w.get_style_context();
                      var old=context.get_state();
                      context.set_state(state);
                      var val = new Value(typeof(Gdk.RGBA));
                      //vala bug, vala binding for gtk_style_context_get_style_property is broken
                      //context.get_style_property(name,val);
                      gtk_style_context_get_style_property(context,name,ref val);
                      if(val.get_boxed()!=null)
						color=*(Gdk.RGBA*)val.get_boxed();
                      context.set_state(old);
//~                     w.style_get(name,out color);
//~                     color=tmp;
//~                     tmp.free();
                  }
				#if VALA_0_17
				  if(color!=null || w.get_style_context().lookup_color(name,out color) ){
				#else
				  if(color!=null || vala_016_style_context_lookup_color(w.get_style_context(),name,out color) ){
				#endif
                    result.append("background='");
                    result.append(hexRGBA(color));
                    result.append("'");
                  }else
				  debug("markup: wrong color '%s', background will be ignored",name);
                }else
                  result.append(match_info.fetch(0));
              }else
                result.append(match_info.fetch(0));
            }
          return false;
          });//while
  return ret;
}//replace_color_in_markup
