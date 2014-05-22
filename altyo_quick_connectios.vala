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
 * http://developer.gnome.org/glib/2.30/glib-Simple-XML-Subset-Parser.html
 * http://gitorious.org/tuntun/tuntun/blobs/master/src/tuntun-auth-dialog.vala
 *
 * */
using Gtk;

//const string GETTEXT_PACKAGE = "altyo";

enum QCOLUMN {
	NAME,
	HOST_NAME,
	USER_NAME,
	USER_PASSWORD,
	COMMAND,
	DESCRIPTION,
	CREATION_TIME,
	MODIFICATION_TIME,
	EXPIRATION_TIME
}
public class QConnect  {
	public string name;
	public string? description;
	public int64 creation_time;
	public int64 modification_time;
	public int64 expiration_time;
	public string? user_name;
	public string? user_password;
	public string? host_name;
	public string? command;

	private int64 parse_time(string time_s){
		if(time_s.length>0){
			if(time_s.contains("(") && time_s.contains(")")){
			var s = time_s.substring(time_s.index_of_char('(',0)+1,time_s.index_of_char(')',1)-1);
			return int.parse(s);
			}
		}
		return 0;
	}

	public QConnect(string[] data_list){
		 this.name=data_list[QCOLUMN.NAME];
		 this.description=data_list[QCOLUMN.DESCRIPTION];
		 this.creation_time=this.parse_time(data_list[QCOLUMN.CREATION_TIME]);
		 this.modification_time=this.parse_time(data_list[QCOLUMN.MODIFICATION_TIME]);
		 this.expiration_time=this.parse_time(data_list[QCOLUMN.EXPIRATION_TIME]);
		 this.user_name=data_list[QCOLUMN.USER_NAME];
		 this.user_password=data_list[QCOLUMN.USER_PASSWORD];
		 this.host_name=data_list[QCOLUMN.HOST_NAME];
		 this.command=data_list[QCOLUMN.COMMAND];
		 //debug("name=%s description=%s creation_time=%d modification_time=%d expiration_time=%d user_name=%s user_password=%s host_name=%s command=%s",
		 //this.name,this.description,(int)this.creation_time,(int)this.modification_time,(int)this.expiration_time,this.user_name,this.user_password,this.host_name,this.command);
	}
}//class QConnect

public class QConnections {
	private MySettings conf;
	public List<unowned QConnect> children;

	//constructor
	public QConnections(MySettings conf) {
		this.conf = conf;
		this.children = new List<QConnect> ();
		foreach(string conn in this.conf.get_qconnection_list()){
			debug("get_qconnection_list=%s",conn);
			string[] data = this.conf.get_qconnection_data_list(conn);
			debug("data=%d",data.length);
			if(data.length<8){
				var t_l=data.length;
				for(var i=0;i<(8-t_l);i++)
					data+="";//add empty entries
				}

			if(data.length==8){
				//add key name in to array[0]
				data +=data[data.length-1];
				for(var i=data.length-2;i>0;i--){
					data[i]=data[i-1];
					}
				data[0]=conn;//key name
				var item = new QConnect(data);
				children.append(item);
			}
		}
	}
}//class QConnections


public class QList: HBox {
	private TreeView view;
	private QConnections qconn;
	private MySettings conf;
	private Gtk.Menu popup_menu;

	private Gtk.ActionGroup action_group;
	private TreeStore store;
	public VTMainWindow win_parent {get;set;default=null;}

	public QList(MySettings conf){
		this.conf = conf;


		this.view = new TreeView ();
        var scroll = new ScrolledWindow (null, null);
        scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scroll.add (this.view);
		this.pack_start(scroll,true,true,0);

		this.store = new TreeStore (9, typeof (string), typeof (string)
		, typeof (string), typeof (string), typeof (string), typeof (string)
		, typeof (string), typeof (string), typeof (string) );
        this.view.set_model (store);

		CellRendererText crt;
		TreeViewColumn column;
		crt=new CellRendererText();
		crt.edited.connect((path,new_text)=>{
			debug("path=%s new_text=%s",path,new_text);
			TreeIter? iter=null;
			this.store.get_iter_from_string(out iter,path);
			if(!this.store.iter_has_child(iter))
				store.set (iter, QCOLUMN.NAME, new_text,-1);
			});
		column=new TreeViewColumn.with_attributes("Name",crt , "text", QCOLUMN.NAME, null);
		column.set_sort_indicator(true);
        this.view.insert_column (column,-1);
		crt=new CellRendererText();
		crt.edited.connect((path,new_text)=>{
			debug("path=%s new_text=%s",path,new_text);
			TreeIter? iter=null;
			this.store.get_iter_from_string(out iter,path);
			if(!this.store.iter_has_child(iter))
				store.set (iter, QCOLUMN.HOST_NAME, new_text,-1);
			});
		column=new TreeViewColumn.with_attributes( "host_name", crt, "text", QCOLUMN.HOST_NAME, null);
        this.view.insert_column (column,-1);
		crt=new CellRendererText();
		crt.edited.connect((path,new_text)=>{
			debug("path=%s new_text=%s",path,new_text);
			TreeIter? iter=null;
			this.store.get_iter_from_string(out iter,path);
			if(!this.store.iter_has_child(iter))
				store.set (iter, QCOLUMN.USER_NAME, new_text,-1);
			});
		column=new TreeViewColumn.with_attributes( "user_name", crt, "text", QCOLUMN.USER_NAME, null);
        this.view.insert_column (column,-1);
		crt=new CellRendererText();
		crt.edited.connect((path,new_text)=>{
			debug("path=%s new_text=%s",path,new_text);
			TreeIter? iter=null;
			this.store.get_iter_from_string(out iter,path);
			if(!this.store.iter_has_child(iter))
				store.set (iter, QCOLUMN.USER_PASSWORD, new_text,-1);
			});
		column=new TreeViewColumn.with_attributes( "user_password", crt, "text", QCOLUMN.USER_PASSWORD, null);
        this.view.insert_column (column,-1);
		crt=new CellRendererText();
		crt.edited.connect((path,new_text)=>{
			debug("path=%s new_text=%s",path,new_text);
			TreeIter? iter=null;
			this.store.get_iter_from_string(out iter,path);
			if(!this.store.iter_has_child(iter))
				store.set (iter, QCOLUMN.COMMAND, new_text,-1);
			});
		column=new TreeViewColumn.with_attributes( "command", crt, "text", QCOLUMN.COMMAND, null);
        this.view.insert_column (column,-1);
		crt=new CellRendererText();
		crt.edited.connect((path,new_text)=>{
			debug("path=%s new_text=%s",path,new_text);
			TreeIter? iter=null;
			this.store.get_iter_from_string(out iter,path);
			if(!this.store.iter_has_child(iter))
				store.set (iter, QCOLUMN.DESCRIPTION, new_text,-1);
			});
		crt.ellipsize_set=true;
		column=new TreeViewColumn.with_attributes( "Description", crt, "text", QCOLUMN.DESCRIPTION, null);
        this.view.insert_column (column,-1);
        this.view.insert_column_with_attributes (-1, "creation_time", new CellRendererText (), "text", QCOLUMN.CREATION_TIME, null);
        this.view.insert_column_with_attributes (-1, "modification_time", new CellRendererText (), "text", QCOLUMN.MODIFICATION_TIME, null);
        this.view.insert_column_with_attributes (-1, "expiration_time", new CellRendererText (), "text", QCOLUMN.EXPIRATION_TIME, null);

		this.qconn = new QConnections(this.conf);

		foreach(var conn in this.qconn.children){
			debug("conn=%s",conn.name);
			var levels = conn.name.split("/");
			debug("levels=%d",levels.length);
			TreeIter? level=null;
			TreeIter? sublevel=null;
			TreeIter? data_iter=null;
			TreePath path = new TreePath.first();
			//TreeIter data_iter=store.get_iter_first();
			for(var i=0;i<levels.length-1;i++){
				//store.iter_children()
				TreeIter? tmp_iter=level;
				string tmp_s="";
				bool found=false;
				while(store.get_iter(out tmp_iter,path)){
					debug("store.get");
					store.get(tmp_iter,0,out tmp_s,-1);
					if(tmp_s!=null && tmp_s==levels[i]){
						found=true;
						sublevel=tmp_iter;
						path.down();
						debug("tmp_iter.get_path=%s",store.get_path(tmp_iter).to_string());
						break;
					}
					path.next();
				}
				if(!found){
					store.append (out sublevel, level);
					debug("sublevel.get_path=%s",store.get_path(sublevel).to_string());
					store.set (sublevel, 0,levels[i], -1);
				}
				level=sublevel;
			}
			store.append (out data_iter, level);
			store.set (data_iter,
			QCOLUMN.NAME, levels[levels.length-1],
			QCOLUMN.DESCRIPTION, conn.description,
			QCOLUMN.CREATION_TIME,(conn.creation_time!=0?new DateTime.from_unix_local (conn.creation_time).format ("%x %X"):""),
			QCOLUMN.MODIFICATION_TIME,(conn.modification_time!=0?new DateTime.from_unix_local (conn.modification_time).format ("%x %X"):""),
			QCOLUMN.EXPIRATION_TIME,(conn.expiration_time!=0?new DateTime.from_unix_local (conn.expiration_time).format ("%x %X"):""),
			QCOLUMN.USER_NAME, conn.user_name,
			QCOLUMN.USER_PASSWORD, conn.user_password,
			QCOLUMN.HOST_NAME, conn.host_name,
			QCOLUMN.COMMAND, conn.command,
			-1);
		}
		//this.view.expand_all ();
		this.view.row_activated.connect ((path, column)=>{
			debug("this.view.row_activated");
			TreeIter? iter=null;
			store.get_iter(out iter,path);
			if(store.iter_has_child(iter)){
				if(!this.view.is_row_expanded(path))
					this.view.expand_row(path,false);
				else
					this.view.collapse_row(path);
			}else{
				string command;
				string host_name;
				string user_name;
				string user_password;
				store.get(iter,QCOLUMN.COMMAND,out command,QCOLUMN.HOST_NAME, out host_name,QCOLUMN.USER_NAME,out user_name,QCOLUMN.USER_PASSWORD,out user_password,-1);
				debug("got command(%s)",command);
				if(command!=null && command!="" && GLib.Regex.match_simple("^ *xdg-open *",command,RegexCompileFlags.CASELESS,0))
					Process.spawn_command_line_async(command);//run command
				else{
					//unowned Gtk.Widget parent;
					//parent = this;
					//while(parent.parent!=null ){parent = parent.parent;} //find VTMainWindow
					//VTMainWindow vtw=(VTMainWindow)parent;
					//todo: prevent double ssh
					var tauth = new TildaAuth(user_name,user_password,host_name,command);
					((VTTerminal)this.win_parent.active_tab.object).try_run_command(tauth);
					this.action_group.get_action("altyo_toogle_quick_list").activate();
				}
			}
		} );




		this.view.button_press_event.connect((event)=>{
			//public void popup_menu(Gdk.EventButton event){
			if(event.type==Gdk.EventType.BUTTON_PRESS){
			if(event.button== 3){//right mouse button
					this.create_popup();
					//menu.ref();
					return true;
			}
		}
		debug("tut");
		return false;
		//}
		});

		this.view.key_press_event.connect(on_key_press_event);

        Gdk.RGBA c =  new Gdk.RGBA();
        c.parse("#000000");//black todo: make same color as vte
        c.alpha = 1.0;//transparency
        this.view.override_background_color(StateFlags.NORMAL, c);
        //this.parent.override_background_color(StateFlags.NORMAL, c);
        c.parse("#AAFF88");//black todo: make same color as vte
        c.alpha = 1.0;//transparency
        this.view.override_color(StateFlags.NORMAL, c);

        this.can_focus=false;
		this.can_default = false;
		this.has_focus = false;
		//this.setup_keyboard_accelerators();

		this.view.map.connect(()=>{
			this.action_group.sensitive=true;
			view.grab_focus();
			//this.view.get_window().set_events(Gdk.EventMask.SCROLL_MASK);
		});

		this.view.set_search_equal_func(search_inline);
		//this.view.hover_expand=true;
		//this.view.model=true;

		/*var scrollbar = new VScrollbar(((Scrollable)this.view).get_vadjustment());
		scrollbar.show () ;
		this.pack_end(scrollbar,false,false,0);*/

        this.show_all();
	}


	private void add_window_accel(string name,string? label, string? tooltip, string? stock_id,string default_accel, MyCallBack cb){
		this.add_window_accel_real(new Gtk.Action(name, label, tooltip, stock_id),conf.get_accel_string(name,default_accel),cb);
	}

	private void add_window_toggle_accel(string name,string? label, string? tooltip, string? stock_id,string default_accel, MyCallBack cb){
		this.add_window_accel_real(new Gtk.ToggleAction(name, label, tooltip, stock_id),conf.get_accel_string(name,default_accel),cb);
	}

	private void add_window_accel_real(Gtk.Action action, string accel, MyCallBack cb){

		//we can't connect cb dirrectly to action.activate
		//so, using lambda again =(
		action.activate.connect(()=>{cb(action);});
		//add in to action_group to make a single repository
		this.action_group.add_action_with_accel (action,accel);
		action.set_accel_group (this.win_parent.accel_group);//use main window accel group
		action.connect_accelerator ();
		//inc refcount otherwise action will be freed at the end of this function
		action.ref();
	}

	private void set_active_column(QCOLUMN new_index){
					TreePath path;
			TreeViewColumn s_column;
			this.view.get_cursor(out path,out s_column);

			List<weak TreeViewColumn> tvc=this.view.get_columns ();

			unowned TreeViewColumn my_column=null;
			foreach(var column in tvc){
				var index=tvc.index(column);//know better way?
				if (index==new_index ){
					my_column=column;
				}else
					column.set_sort_indicator(false);
			}
//~ 			if(!my_column.get_sort_indicator())
				my_column.set_sort_indicator(true);
//~ 			else{
//~ 				if(SortType.ASCENDING == my_column.get_sort_order())
//~ 					my_column.set_sort_order(SortType.DESCENDING);
//~ 					else
//~ 					my_column.set_sort_order(SortType.ASCENDING);
//~ 				}

			this.view.set_cursor_on_cell(path,my_column,null,((Gtk.ToggleAction)this.action_group.get_action("qlist_edit_table")).active);
			this.view.set_search_column(new_index);

	}

	public void setup_keyboard_accelerators() {
		debug("setup_keyboard_accelerators");

		//this.accel_group = new Gtk.AccelGroup();
		//((Window)this.win_parent).add_accel_group (accel_group);

		this.action_group = new Gtk.ActionGroup("QList");
		this.action_group.sensitive=false;

		this.add_window_accel("altyo_toogle_quick_list", "Show/Hide Quick list", "Show/Hide Quick list", Gtk.Stock.QUIT,"<Control><Shift>D",()=> {
			debug("QuickLIst <Ctrl><Shift>d");
			this.action_group.sensitive=false;
			this.win_parent.action_group.sensitive=true;
			this.win_parent.action_group.get_action("altyo_toogle_quick_list").activate();
        });

		this.add_window_toggle_accel("qlist_edit_table", "Edit table", "Edit table", Gtk.Stock.EDIT,"<Control>E",()=> {
			/*var selection = this.view.get_selection();
			TreeModel model;
			TreeIter iter;
			if(selection.get_selected(out model,out iter)){
				store.get_path(iter);

			}*/
			List<weak TreeViewColumn> tvc=this.view.get_columns ();
			//tvc=unowned tvc.next;//skip name
			foreach(var column in tvc){
				List<weak CellRenderer> cells = column.get_cells();
				var index=tvc.index(column);//know better way?
				if( index==QCOLUMN.DESCRIPTION ||
					index==QCOLUMN.USER_NAME ||
					index==QCOLUMN.USER_PASSWORD ||
					index==QCOLUMN.HOST_NAME ||
					index==QCOLUMN.COMMAND ||
					index==QCOLUMN.NAME )
				foreach(var renderer in cells){
					((CellRendererText)renderer).editable=((Gtk.ToggleAction)this.action_group.get_action("qlist_edit_table")).active;
				}
			}
		});

		this.add_window_accel("qlist_create_folder", "Create Folder", "Create Folder", Gtk.Stock.DIRECTORY,"<Control>D",()=> {
			if(((Gtk.ToggleAction)this.action_group.get_action("qlist_edit_table")).active){
				var selection = this.view.get_selection();
				TreeModel model;
				TreeIter iter;
				TreeIter samelevel;
				if(selection.get_selected(out model,out iter)){
					//TreePath path = store.get_path(iter);
					//path.up();
					this.store.insert_after (out samelevel, null, iter);
					debug("sublevel.get_path=%s",this.store.get_path(samelevel).to_string());
					this.store.set (samelevel, 0,"<new folder>", -1);

				}
			}
		});

		this.add_window_accel("qlist_create_sub_folder", "Create Sub Folder", "Create Sub Folder", Gtk.Stock.DIRECTORY,"<Control><Alt>D",()=> {
			if(((Gtk.ToggleAction)this.action_group.get_action("qlist_edit_table")).active){
				var selection = this.view.get_selection();
				TreeModel model;
				TreeIter iter;
				TreeIter samelevel;
				if(selection.get_selected(out model,out iter)){
					//TreePath path = store.get_path(iter);
					//path.up();
					this.store.append(out samelevel, iter);
					debug("sublevel.get_path=%s",this.store.get_path(samelevel).to_string());
					this.store.set (samelevel, 0,"<new subfolder>", -1);

				}
			}
		});

		this.add_window_accel("qlist_new_item", "Create new item", "Create new item", Gtk.Stock.NEW,"<Control>N",()=> {
			overlay_dialog();
			return;
			if(((Gtk.ToggleAction)this.action_group.get_action("qlist_edit_table")).active){
				var selection = this.view.get_selection();
				TreeModel model;
				TreeIter iter;
				TreeIter samelevel;
				TreeIter? tmp_iter;
				if(selection.get_selected(out model,out iter)){
					this.store.insert_after (out samelevel, null, iter);
					TreePath path = store.get_path(samelevel);
					string qpath="<New item>";
					debug("while(path.up())");
					while(path.up() && path.get_depth()>0){
						string name;
						this.store.get_iter(out tmp_iter,path);
						this.store.get (tmp_iter,QCOLUMN.NAME, out name,-1);
						if(name!=null)
							qpath=name+"/"+qpath;
					}

					debug("sublevel.get_path=%s",store.get_path(samelevel).to_string());
					var conn = new QConnect({qpath,"","","","","Проверка \n комментария","(%d)%s".printf(((int)new DateTime.now_local()),new DateTime.now_local().format ("%x %X")),"",""});
					this.qconn.children.append(conn);
					this.store.set (samelevel,
							QCOLUMN.NAME, /*"<New item>"*/conn.name,
							QCOLUMN.DESCRIPTION, conn.description,
							QCOLUMN.CREATION_TIME,(conn.creation_time!=0?new DateTime.now_local().format ("%x %X"):""),
							QCOLUMN.MODIFICATION_TIME,(conn.modification_time!=0?new DateTime.now_local().format ("%x %X"):""),
							QCOLUMN.EXPIRATION_TIME,(conn.expiration_time!=0?new DateTime.from_unix_local (conn.expiration_time).format ("%x %X"):""),
							QCOLUMN.USER_NAME, conn.user_name,
							QCOLUMN.USER_PASSWORD, conn.user_password,
							QCOLUMN.HOST_NAME, conn.host_name,
							QCOLUMN.COMMAND, conn.command,
					-1);

				}
			}
		});

		this.add_window_accel("qlist_edit_name", "Edit Name", "Edit Name", null,"<Alt>1",()=> {
			this.set_active_column(QCOLUMN.NAME);
		});

		this.add_window_accel("qlist_edit_host_name", "Edit Host Name", "Edit Host Name", null,"<Alt>2",()=> {
			this.set_active_column(QCOLUMN.HOST_NAME);
		});

		this.add_window_accel("qlist_edit_user_name", "Edit User Name", "Edit User Name", null,"<Alt>3",()=> {
			this.set_active_column(QCOLUMN.USER_NAME);
		});

		this.add_window_accel("qlist_edit_password", "Edit Password", "Edit Password", null,"<Alt>4",()=> {
			this.set_active_column(QCOLUMN.USER_PASSWORD);
		});

		this.add_window_accel("qlist_edit_command", "Edit command", "Edit command", null,"<Alt>5",()=> {
			this.set_active_column(QCOLUMN.COMMAND);
		});

		this.add_window_accel("qlist_edit_description", "Edit description", "Edit description", null,"<Alt>6",()=> {
			this.set_active_column(QCOLUMN.DESCRIPTION);
		});

		this.add_window_accel("qlist_delete_row", "Delete row", "Delete row", Gtk.Stock.DELETE,"<Control>Delete",()=> {
			if(((Gtk.ToggleAction)this.action_group.get_action("qlist_edit_table")).active){
				TreePath path;
				TreeViewColumn s_column;
				TreeIter? iter=null;
				this.view.get_cursor(out path,out s_column);
				if(store.get_iter(out iter,path))
				if(!store.iter_has_child(iter)){
					this.store.remove(ref iter);
					if(store.get_iter(out iter,path))
						this.view.set_cursor(path,null,false);
					else if(path.prev())
						this.view.set_cursor(path,null,false);
					else if(path.up())
						this.view.set_cursor(path,null,false);
				}
			}
		});

		this.create_popup();
	}//setup_keyboard_accelerators

	public void create_popup(){
		this.action_group.get_action("qlist_create_folder").sensitive=((Gtk.ToggleAction)this.action_group.get_action("qlist_edit_table")).active;
		this.action_group.get_action("qlist_create_sub_folder").sensitive=((Gtk.ToggleAction)this.action_group.get_action("qlist_edit_table")).active;
		this.action_group.get_action("qlist_new_item").sensitive=((Gtk.ToggleAction)this.action_group.get_action("qlist_edit_table")).active;
		this.action_group.get_action("qlist_delete_row").sensitive=((Gtk.ToggleAction)this.action_group.get_action("qlist_edit_table")).active;

		if(this.popup_menu==null){
			this.popup_menu = new Gtk.Menu();
			Gtk.MenuItem menuitem;

			menuitem = (Gtk.MenuItem)this.action_group.get_action("qlist_edit_table").create_menu_item();
			this.popup_menu.append(menuitem);

			menuitem = new Gtk.SeparatorMenuItem();
			this.popup_menu.append(menuitem);

			menuitem = (Gtk.MenuItem)this.action_group.get_action("qlist_create_folder").create_menu_item();
			this.popup_menu.append(menuitem);

			menuitem = (Gtk.MenuItem)this.action_group.get_action("qlist_create_sub_folder").create_menu_item();
			this.popup_menu.append(menuitem);

			menuitem = (Gtk.MenuItem)this.action_group.get_action("qlist_new_item").create_menu_item();
			this.popup_menu.append(menuitem);

			menuitem = new Gtk.SeparatorMenuItem();
			this.popup_menu.append(menuitem);

			menuitem = (Gtk.MenuItem)this.action_group.get_action("qlist_delete_row").create_menu_item();
			this.popup_menu.append(menuitem);

			this.popup_menu.show_all();
		}else{
			this.popup_menu.popup(null, null, null, 3, 0);
		}
	}

	bool search_inline (Gtk.TreeModel model, int column, string key,
        Gtk.TreeIter iter) {
        var path = store.get_path(iter);
		if(store.iter_has_child(iter)){
			if(!this.view.is_row_expanded(path))
					this.view.expand_row(path,false);
		}else{
			string? message=null;
			this.store.get (iter, column, out message);
			debug("search_inline message=%s",message);
			if(message!=null)
				return !GLib.Regex.match_simple(".*"+key+".*",message,RegexCompileFlags.CASELESS,0);
				//RegexCompileFlags.CASELESS - ignore case
		}
        return true;
    }

    bool on_key_press_event (Gdk.EventKey event){
		//var keyname = Gdk.keyval_name(event.keyval);
		event.state &= Gtk.accelerator_get_default_mod_mask();
		if( event.keyval==0xff0d && /*GDK_KEY_Return*/
			((event.state & Gdk.ModifierType.CONTROL_MASK)>0)
			){
			debug("this.view.row_activated");

			TreePath path;
			TreeViewColumn s_column;
			TreeIter? iter=null;
			this.view.get_cursor(out path,out s_column);

			store.get_iter(out iter,path);
			if(!store.iter_has_child(iter)){
				string command;
				string host_name;
				string user_name;
				string user_password;
				store.get(iter,QCOLUMN.HOST_NAME, out host_name,QCOLUMN.USER_NAME,out user_name,QCOLUMN.USER_PASSWORD,out user_password,-1);

				command="ssh,paste-password";
				debug("try_run_command host_name=%s,user_name=%s,user_password=%s,command=%s",host_name,user_name,user_password,command);
				var tauth = new TildaAuth(user_name,user_password,host_name,command);
				((VTTerminal)this.win_parent.active_tab.object).try_run_command(tauth);
				this.action_group.get_action("altyo_toogle_quick_list").activate();

			}

			}
		return false;
	}

    /*public override void get_preferred_width (out int o_minimum_width, out int o_natural_width) {
		o_minimum_width=o_natural_width= this.win_parent.terminal_width;
	}

    public override void get_preferred_height_for_width (int width,out int minimum_height, out int natural_height) {
		minimum_height=natural_height= this.win_parent.terminal_height;
	}

	public override SizeRequestMode get_request_mode () {
		return (Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH);
	}*/

	public void overlay_dialog(){
		debug("overlay_dialog");

		//this.pack_start(scroll,true,true,0);

		VTMainWindow vtw=(VTMainWindow)this.get_toplevel();

		var dialog_vbox = new VBox(false, 0);
//~ 		dialog_vbox.set_has_window (true);
		var but = new Button.with_label("test");

		dialog_vbox.add(but);

		vtw.overlay_notebook.prepend_page (dialog_vbox,null);
		vtw.overlay_notebook.show_all();
		vtw.overlay_notebook.show();

		/*var attributes = new Gdk.WindowAttr();
		int attributes_mask;
		Gtk.Allocation allocation;

		dialog_vbox.get_allocation (out allocation);

		attributes.window_type = Gdk.WindowType.CHILD;
		attributes.wclass = Gdk.WindowWindowClass.OUTPUT;
		attributes.width = allocation.width;
		attributes.height = allocation.height;
		attributes.x = allocation.x;
		attributes.y = allocation.y;
		attributes_mask = Gdk.WindowAttributesType.X | Gdk.WindowAttributesType.Y;
		attributes.event_mask = vtw.get_events () | Gdk.EventMask.EXPOSURE_MASK;

		var window = new Gdk.Window (vtw.get_window (),
                           attributes, attributes_mask);

		//dialog_vbox.set_window (vtw.get_window());
		vtw.overlay_notebook.set_window (window);
		vtw.overlay_notebook.show_all();*/


		//this.overlay_notebook.set_show_tabs(false);
	}//overlay_dialog

}//class QList
