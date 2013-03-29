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
using Gee;
public enum CFG_CHECK{
	OK,
	REPLACE,
	USE_DEFAULT
	}

public delegate CFG_CHECK check_string(ref string s);
public delegate CFG_CHECK check_string_list(ref string[] sl);
public delegate CFG_CHECK check_integer(ref int i);
public delegate CFG_CHECK check_double(ref double d);
public delegate CFG_CHECK check_boolean(ref bool b);

public enum CFG_TYPE{
	TYPE_UNKNOWN,
	TYPE_BOOLEAN,
	TYPE_DOUBLE,
	TYPE_INTEGER,
	TYPE_STRING,
	TYPE_STRING_LIST,
	TYPE_ACCEL_STRING
	}

public class MySettings : Object {
	private KeyFile kf;
	public string conf_file;
	private string profile {get;set;default = "profile0";}
	private string accel_section {get;set;default = "KeyBindings";}
	private string qconnection_section {get;set;default = "QConnections";}
	private bool opened {get;set; default = false;}
	private bool changed {get;set; default = false;}
	private HashMap<string, CFG_TYPE> typemap;

	public signal void on_load();

	public MySettings(string? cmd_conf_file=null){
		this.typemap = new HashMap<string, CFG_TYPE> ();
		if(cmd_conf_file!=null)
			this.conf_file = cmd_conf_file;
		else
			this.conf_file = GLib.Environment.get_user_config_dir()+"/altyo"+"/config.ini";
		kf = new KeyFile();
		this.load_config();
	}

	public void load_config(){
		debug("loading config...");
		if(!GLib.FileUtils.test(this.conf_file,GLib.FileTest.EXISTS) )
					GLib.DirUtils.create(GLib.Path.get_dirname(this.conf_file),502);//755

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
						} catch (FileError err) {
								warning (err.message);
						}
				}
	}

	public void reload_config(){
		this.on_load();
	}

	public void save(bool force=false){
		if(this.changed || force){
			var str = kf.to_data (null);
			try {
				debug("\tsave settings into file=%s\n",this.conf_file);
				FileUtils.set_contents (this.conf_file, str, str.length);
			} catch (FileError err) {
				warning (err.message);
			}
		}
		this.changed=false;
	}

	public bool get_boolean (string key,bool? def,check_boolean? check_cb=null){
		if(!this.typemap.has_key(key))
			this.typemap[key]=CFG_TYPE.TYPE_BOOLEAN;
		else if(this.typemap[key]!=CFG_TYPE.TYPE_BOOLEAN)
			assert(this.typemap[key]==CFG_TYPE.TYPE_BOOLEAN);

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
		if(!this.typemap.has_key(key))
			this.typemap[key]=CFG_TYPE.TYPE_INTEGER;
		else if(this.typemap[key]!=CFG_TYPE.TYPE_INTEGER)
			assert(this.typemap[key]==CFG_TYPE.TYPE_INTEGER);

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

	public double get_double (string key,double def,check_double? check_cb=null){
		if(!this.typemap.has_key(key))
			this.typemap[key]=CFG_TYPE.TYPE_DOUBLE;
		else if(this.typemap[key]!=CFG_TYPE.TYPE_DOUBLE)
			assert(this.typemap[key]==CFG_TYPE.TYPE_DOUBLE);

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
		if(!this.typemap.has_key(key))
			this.typemap[key]=CFG_TYPE.TYPE_STRING_LIST;
		else if(this.typemap[key]!=CFG_TYPE.TYPE_STRING_LIST)
			assert(this.typemap[key]==CFG_TYPE.TYPE_STRING_LIST);

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
		if(!this.typemap.has_key(key))
			this.typemap[key]=CFG_TYPE.TYPE_STRING;
		else if(this.typemap[key]!=CFG_TYPE.TYPE_STRING)
			assert(this.typemap[key]==CFG_TYPE.TYPE_STRING);

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
		if(!this.typemap.has_key(key))
			this.typemap[key]=CFG_TYPE.TYPE_STRING_LIST;
		else if(this.typemap[key]!=CFG_TYPE.TYPE_STRING_LIST)
			assert(this.typemap[key]==CFG_TYPE.TYPE_STRING_LIST);

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
		if(!this.typemap.has_key(key))
			this.typemap[key]=CFG_TYPE.TYPE_STRING;
		else if(this.typemap[key]!=CFG_TYPE.TYPE_STRING)
			assert(this.typemap[key]==CFG_TYPE.TYPE_STRING);

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
		if(!this.typemap.has_key(key))
			this.typemap[key]=CFG_TYPE.TYPE_INTEGER;
		else if(this.typemap[key]!=CFG_TYPE.TYPE_INTEGER)
			assert(this.typemap[key]==CFG_TYPE.TYPE_INTEGER);

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

	public bool set_boolean (string key,bool def){
		if(!this.typemap.has_key(key))
			this.typemap[key]=CFG_TYPE.TYPE_BOOLEAN;
		else if(this.typemap[key]!=CFG_TYPE.TYPE_BOOLEAN)
			assert(this.typemap[key]==CFG_TYPE.TYPE_BOOLEAN);

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
		if(!this.typemap.has_key(key))
			this.typemap[key]=CFG_TYPE.TYPE_DOUBLE;
		else if(this.typemap[key]!=CFG_TYPE.TYPE_DOUBLE)
			assert(this.typemap[key]==CFG_TYPE.TYPE_DOUBLE);

		bool ret = true;
			try {
				this.changed=true;
				if(digits_after_comma>0){
					uint round=1;
					while(digits_after_comma-->0){
						round*=10;
					}
					int i=(int)(def * round);//round
					def=(double)((double)(i)/(double)round);
					string S="%.2f".printf(def);
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
		if(!this.typemap.has_key(key))
			this.typemap[key]=CFG_TYPE.TYPE_ACCEL_STRING;
		else if(this.typemap[key]!=CFG_TYPE.TYPE_ACCEL_STRING)
			assert(this.typemap[key]==CFG_TYPE.TYPE_ACCEL_STRING);

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
		if(!this.typemap.has_key(key))
			this.typemap[key]=CFG_TYPE.TYPE_ACCEL_STRING;
		else if(this.typemap[key]!=CFG_TYPE.TYPE_ACCEL_STRING)
			assert(this.typemap[key]==CFG_TYPE.TYPE_ACCEL_STRING);

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
		if(this.typemap.has_key(key)){
			return this.typemap[key];
		}else{
			debug("get_key_type TYPE_UNKNOWN for key=%s",key);
			return CFG_TYPE.TYPE_UNKNOWN;
		}
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


