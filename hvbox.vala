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

private class HVBoxItem : Object{
	public unowned Widget widget;
	public int max_width = -1;
	public bool ignore = false;
	public HVBoxItem(Widget W){
			this.widget = W;
		}
//	public void destroy(){
//~ 		base.destroy();
//            delete (void*) this;
//		}
	}

public class HVBox : Container {

    private int height = 28;
    private int self_minimum_width = 0;
    private int self_natural_width = 0;//store available width
    private int self_natural_height = 0;
    private int self_width = 0;
    private int initial_size = 0;
    private int cur_level = 0;

    private Gtk.SizeRequestMode mode = Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;

    private List<HVBoxItem> children;
    //private Window HVBParent;

    private bool drop_data_ready { get; set; default = false; }
    private bool drop_occured { get; set; default = false; }
    private TargetList drop_targets { get; set; default = null; }
    private string[]? drop_uris { get; set; default = null; }
    private Window dnd_window { get; set; default = null; }
    private bool dnd_inprocess { get; set; default = false; }

	public bool background_only_behind_widgets { get; set; default = true; }
	public bool minimize_size { get; set; default = true; }
    public signal void child_reordered(Widget child, uint new_index);
    public signal void size_changed(int width, int height,bool on_size_request);
    private bool size_changed_send { get; set; default = false; }
//~ 	public static enum DragInfo {
//~ 	TEXT_URI_LIST
//~ 	}

    const TargetEntry[] target_entries = {
        { "GTK_HVBOX_ITEM",     (1 << 0) , 0 }
    };


    public HVBox(/*Window parent*/) {
        set_has_window (false);
        children = new List<HVBoxItem> ();
        //HVBParent=parent;

		/* create list of supported drop targets */
//~ 		TargetEntry[] target_entries = {
//~ 			{"text/uri-list", 0, DragInfo.TEXT_URI_LIST	}
//~ 		};


		/* remember this list for use in DnD handlers */
		drop_targets = new TargetList (target_entries);

		/* set the view as a drag destination for these targets */
		drag_dest_set (this, 0, target_entries, Gdk.DragAction.MOVE);
		this.set_reallocate_redraws(true);//redraw all elements, needed for redraw HVBox border
		//this.resize_mode=ResizeMode.QUEUE; //this break window size

    }

	public override bool drag_motion (Gdk.DragContext context,
	//public bool some_drag_motion (Gdk.DragContext context,
									int x,
									int y,
									uint time) {
	//debug("drag_motion drop_data_ready=%s\n",drop_data_ready.to_string());


		/* request drop data on demand */
		if (!drop_data_ready) {
		  /* check if we can handle the drag data (only text/uri-list supported) */
		  var target = drag_dest_find_target (this, context, drop_targets);
		  debug("drag_motion drag_dest_find_target\n");
		  if (target == Gdk.Atom.intern_static_string ("GTK_HVBOX_ITEM")) {
			/* request drop data from the source */
			drag_get_data (this, context, target, time);
		  }

		  /* we are not ready to drop yet */
		  Gdk.drag_status (context, 0, time);
		} else {
		  /* create a file object for the URI */
		  //var file = GLib.File.new_for_uri (drop_uris[0]);
	//~       debug("drag_motion uri=%s\n",drop_uris[0]);

		  /* find the correct category for it */
	//~       CategoryExpander? expander = null;
	//~       if (find_category_for_file (file, out expander)) {
	//~         if (expander.drop_indicator != null) {
	//~           expander.drop_indicator.is_drop_target = true;
	//~           expander.drop_indicator.set_visible (true);
	//~         }

			/* we have drop data, now we can create the bookmark */
			Gdk.drag_status (context, Gdk.DragAction.MOVE, time);
	//~       } else {
			/* we have an unsupported drop URI, cannot handle it */
	//~         Gdk.drag_status (context, 0, time);
	//~       }
		}

	return true;//we a ready
	}

	public override void drag_leave (Gdk.DragContext context, uint time) {
	debug ("drag leave, reset flags\n");
	}

	public override bool drag_drop (Gdk.DragContext context,
								  int x,
								  int y,
								  uint time)
	{
	debug ("drag_drop\n");

    /* determine the DnD target and see if we can handle it */
    var target = drag_dest_find_target (this, context, drop_targets);
    if (target == Gdk.Atom.intern_static_string ("GTK_HVBOX_ITEM")) {
      debug ("drag drop, supports target, perform drop");

      /* set flag so that drag_data_received knows we are dropping for real */
      drop_occured = true;

      /* request data from drag source */
      drag_get_data (this, context, target, time);

      /* we will call drag_finish later */
      return true;
    } else {
      debug ("drag drop, target unsupported, cancel drop");

      /* cancel drop */
      return false;
    }

	}


  public override void drag_data_received (Gdk.DragContext context,
                                           int x,
                                           int y,
                                           SelectionData selection_data,
                                           uint info,
                                           uint time)
  {
    debug ("drag data received x=%d y=%d",x,y);

    string[] uris = selection_data.get_uris ();


    if ( !drop_data_ready && selection_data.get_target () == Gdk.Atom.intern_static_string ("GTK_HVBOX_ITEM")) {
      drop_data_ready = true;

      if (uris != null) {
        debug ("request from drag motion, have uris");
      } else {
        debug ("request from drag motion, don't have uris");
      }
    }

    if (drop_occured) {
      /* reset the drop state */
      drop_occured = false;
		ulong* data;
        data = (ulong[])selection_data.get_data();
        //if(data==null)return;
		if(data!=null){
			debug ("data data= %d",(int)((ulong)data[0]));

			unowned HVBoxItem** pitem=(HVBoxItem**)data[0];
			if(pitem==null || !(*pitem is HVBoxItem) )return;
			HVBoxItem dnd_item=*pitem;

		debug ("data = %d %s",(int)(pitem),dnd_item.widget.get_type().name());


/********************************/
		var line_h = 0;
		var dnd_done = false;
		var allocation = Gtk.Allocation();//don't use new for struct
		var width = this.get_allocated_width();
		Gtk.StyleContext style_context = this.get_style_context();
		Gtk.Border border=style_context.get_border(StateFlags.NORMAL);

		allocation.x=0;
		allocation.y=0;
		allocation.height=0;
		allocation.width=0;

		unowned List<HVBoxItem> item_it=null;
		unowned List<HVBoxItem> end_of_line=null;
		for (item_it = this.children; !dnd_done && item_it != null; item_it = item_it.next) {

			end_of_line=item_it;
			line_h = get_line_height(ref end_of_line, width-border.left-border.right,false);
			if((allocation.y+line_h)>y){
				allocation.x = 0 ;//start of the line
				allocation.height=line_h;//base height for line

				unowned List<HVBoxItem> line_item=item_it;

				for (line_item=item_it; (line_item != null && end_of_line != null) &&
					line_item != end_of_line.next ; line_item = line_item.next) {

					unowned HVBoxItem item = line_item.data;
					unowned Widget widget = item.widget;

					var ingnore_h = 0;
					widget.get_preferred_width (out allocation.width, out ingnore_h);

					debug("\torig2 size_allocate position=%d x=%d y=%d w=%d h=%d\n",this.children.position(line_item),allocation.x,allocation.y,allocation.width,allocation.height);

					if(line_item == end_of_line && x>allocation.x+allocation.width){
						if(dnd_item==line_item.data){ //ignore same position
							dnd_done=true;
							break;
							}
						this.children.remove(dnd_item);
						var new_pos=this.children.position(line_item)+1;
						this.children.insert( dnd_item , new_pos);
						this.child_reordered(dnd_item.widget,new_pos);
						dnd_done=true;
						debug("Found at EOL! Xx=%d Yy=%d\n",x,y);
						break;
						}

					if(x<allocation.x+allocation.width){
						debug("Found at ! index=%d \n",this.children.position(line_item));
						if(dnd_item==line_item.data){//ignore same position
							dnd_done=true;
							break;
							}
						var old_pos=this.children.index(dnd_item);
						this.children.remove(dnd_item);
						var new_pos=this.children.position(line_item);
						if(old_pos==new_pos)
							new_pos++;
						this.children.insert( dnd_item , new_pos);
						this.child_reordered(dnd_item.widget,new_pos);
						//this.children.append(item2);
						dnd_done=true;
						break;
						}
					allocation.x+=allocation.width;
				}//end of line
			}
			allocation.y += line_h;//next line pos
			item_it = end_of_line;
			debug("\tNext line\n");
		}

		if(!dnd_done){
//~ 			if( ( y > allocation.y && y < (allocation.y+(allocation.height)) ) &&
//~ 				x < orig_pos_w  ){
					debug("Found at the end! Xx=%d Yy=%d\n",x,y);
					this.children.remove(dnd_item);
					//this.children.insert( item2 , this.children.position(item));
					this.children.append(dnd_item);
					this.child_reordered(dnd_item.widget,this.children.index(dnd_item));
					dnd_done=true;
//~ 				}

			}


		//debug("orig2 size_allocate x=%d y=%d w=%d h=%d\n",allocation.x,allocation.y,allocation.width,allocation.height);

		//minimum_height=natural_height=allocation.height;

/********************************/
		}//if(!data==null)

      if (drop_uris != null) {
        debug ("have uris, create bookmark now");
      } else {
        debug ("don't have uris, abort drag-and-drop");
      }

      /* tell the drag source that we handled the drop */
      drag_finish (context, drop_uris != null, false, time);

      /* disable highlighting and release the drag data */
      drag_leave (context, time);
    }
  }







//~     public static Gdk.Rectangle get_primary_monitor_geometry () {
//~         Gdk.Rectangle r = {0, 0};
//~         var screen = Gdk.Screen.get_default ();
//~         screen.get_monitor_geometry (screen.get_primary_monitor(), out r);
//~         return r;
//~     }

		public void update_size(){
			debug("update_size\n");
			//this.parent.set_size_request (2,2);
			//this.parent.parent.set_size_request (2,2);
			this.set_size_request (1,1);
			this.set_property("width-request",2);
			this.set_property("height-request",2);
			//this.get_requisition();
			//return;
	//~ 		Gtk.Window HVBParent = this.get_window ();
			/*HVBParent.set_size_request (1,1);
			HVBParent.set_property("width-request",2);
			HVBParent.set_property("height-request",2);
			HVBParent.get_requisition();*/
		}



		private int get_line_height (ref unowned List<HVBoxItem> first_item=null,int width, bool get_max_natural_height = false) {

			if(first_item==null)
				return -1;//assert

			int minimum_height = 0;
			int natural_height = 0;
			int natural_width = 0;

			var allocation = Gtk.Allocation();//don't use new for struct

			allocation.x=0;
			allocation.y=0;
			allocation.height=0;
			allocation.width=0;

			var sum_w=0;


			unowned List<HVBoxItem> item_it=null;
			unowned List<HVBoxItem> last_item=first_item;

			for (item_it = first_item; item_it != null; item_it = item_it.next) {
				unowned HVBoxItem item = item_it.data;
				unowned Widget widget = item.widget;
				var m_h =0;
				var n_h =0;

				widget.get_preferred_width (out allocation.width, out natural_width);
				widget.get_preferred_height(out m_h,out n_h);

				minimum_height=int.max(minimum_height,m_h);
				natural_height=int.max(natural_height,n_h);

				if( (sum_w + allocation.width) > width)
					break;//normal out

				sum_w += allocation.width;
				last_item=item_it;
			}

			first_item=last_item;
			return (get_max_natural_height == true ? natural_height : minimum_height);
	}//get_line_height


   public override void size_allocate (Gtk.Allocation allocation) {
			//this.update_size();

		debug("size_allocate x=%d y=%d w=%d h=%d\n",allocation.x,allocation.y,allocation.width,allocation.height);

		Gtk.StyleContext context = this.get_style_context();
		Gtk.Border border=context.get_border(StateFlags.NORMAL);
        //original allocation values
        var pos_x=allocation.x;
        var orig_pos_x = allocation.x;
        var orig_pos_y = allocation.y;
        var orig_pos_h = allocation.height;
        var orig_pos_w = allocation.width;
        var orig_pos_w_max = orig_pos_w-border.left-border.right;
        var sum_w=0;
        var line_h=0;

		unowned List<HVBoxItem> item_it=null;
		unowned List<HVBoxItem> end_of_line=null;

		for (item_it = this.children; item_it != null; item_it = item_it.next) {

			end_of_line=item_it;
			line_h = get_line_height(ref end_of_line,orig_pos_w_max,false);
			if(line_h<0){
				debug("Something wrong!");
				break;
			}
			allocation.x = orig_pos_x+border.left ;//start of line
			allocation.height=line_h;//base height for line

			unowned List<HVBoxItem> line_item=item_it;


			for (line_item=item_it; (line_item != null && end_of_line != null) &&
				line_item != end_of_line.next ; line_item = line_item.next) {

				unowned HVBoxItem item = line_item.data;
				unowned Widget widget = item.widget;

				var ingnore_h = 0;
				widget.get_preferred_width (out allocation.width, out ingnore_h);

				if(allocation.width>orig_pos_w_max){
					widget.width_request=orig_pos_w_max;//set width_request for VTToggleButton
					widget.get_preferred_width (out allocation.width, out ingnore_h);//now width shuld be limited to the maximum
					if(allocation.width>orig_pos_w_max)
						allocation.width=orig_pos_w_max;//just ensure that width is limited
				}

				if(!item.ignore)//skip but remember size
					widget.size_allocate(allocation);
				allocation.x+=allocation.width;
			}//end of line
			allocation.y += line_h;//next line pos
			item_it = end_of_line;
		}
		if(minimize_size)
			allocation.height = allocation.y-orig_pos_y;
		else
			allocation.height = orig_pos_h;
		allocation.height+=border.bottom;
        allocation.x = orig_pos_x;
        allocation.y = orig_pos_y;
        allocation.width  = orig_pos_w;
		base.size_allocate (allocation);//allocate container it self
    }

	public override SizeRequestMode get_request_mode () {
		return (this.mode);
	}


	public override void get_preferred_width (out int o_minimum_width, out int o_natural_width) {
		var sum_w = 0;
		var max_w = 0;
		foreach(unowned HVBoxItem item in this.children){
			unowned Widget widget = item.widget;
			widget.get_preferred_width (out o_minimum_width, out o_natural_width);
			max_w=int.max(o_minimum_width,max_w);
			sum_w+=o_minimum_width;
		}
		if (max_w == 0){
			max_w =sum_w= 80;
		}
		if(sum_w>this.self_natural_width){//limit max child widget size
			sum_w=max_w=this.self_natural_width;
			}
		this.self_minimum_width=o_minimum_width=this.self_width=max_w;
		o_natural_width=sum_w;
 		//debug("get_preferred_width self_nat=%d self_min=%d  minimum=%d natural=%d\n",this.self_natural_width,this.self_minimum_width,o_minimum_width,o_natural_width);
	}

	private void _get_preferred_height_for_width (int width, out int minimum_height, out int natural_height) {

		unowned List<HVBoxItem> item_it=null;
		unowned List<HVBoxItem> end_of_line=null;
		Gtk.StyleContext context = this.get_style_context();
		Gtk.Border border=context.get_border(StateFlags.NORMAL);
		for (item_it = this.children; item_it != null; item_it = item_it.next) {

			end_of_line=item_it;
			minimum_height += get_line_height(ref end_of_line, width-border.left-border.right,false);
			end_of_line=item_it;
			natural_height +=  get_line_height(ref end_of_line,width-border.left-border.right,true);
			item_it = end_of_line;
		}

	}

 	public override void get_preferred_height_for_width (int width,out int minimum_height, out int natural_height) {
		hvbox_get_preferred_height_for_width (width,out minimum_height, out natural_height);
	}
	public void hvbox_get_preferred_height_for_width (int width,out int minimum_height, out int natural_height) {

		/*workaround for min_height, if actual available width more than self minimum width*/
		if(this.self_minimum_width == width && initial_size <10){
			initial_size++;
		}

		if( this.self_minimum_width!=width || initial_size >2){
			this.self_natural_width=width;
			initial_size=0;
			this._get_preferred_height_for_width(this.self_natural_width,out minimum_height, out natural_height);
		}else{
			this._get_preferred_height_for_width(this.self_natural_width,out minimum_height, out natural_height);
			}
		Gtk.StyleContext context = this.get_style_context();
		Gtk.Border border=context.get_border(StateFlags.NORMAL);
		minimum_height+=border.bottom;
		natural_height+=border.bottom;

		if(!this.size_changed_send){
			this.size_changed_send=true;
			size_changed(width, minimum_height,true);//important!
			this.size_changed_send=false;
		}
		this.self_natural_height = natural_height;
		debug("get_preferred_height_for width=%d min=%d natural=%d",width,minimum_height,natural_height);
 		//debug("get_preferred_height_for_width=%d != %d self_min=%d  minimum=%d natural=%d\n",width,this.self_natural_width,this.self_minimum_width,minimum_height,natural_height);
	}


/*
 * width for heigth not yet supported
 *
 * public override void get_preferred_width_for_height (int height,out int minimum_width, out int natural_width) {
		var sum_w = 0;
		foreach(unowned HVBoxItem item in this.children){
			Widget widget = item.widget;
			widget.get_preferred_width (out minimum_width,out natural_width);
			sum_w+=minimum_width;
		}
		if(minimum_width>this.self_width){
			minimum_width=(int)(sum_w/((int)(height/28)));
		}else{
			minimum_width=this.self_width;
		}
		natural_width=minimum_width;
//~ 		debug("get_preferred_width_for_height=%d minimum=%d natural=%d\n",height,minimum_width,natural_width);
	}


	public override void get_preferred_height (out int minimum_height, out int natural_height) {
		natural_height=minimum_height=28;
	}*/

    public override void forall_internal(bool include_internal,Gtk.Callback callback){
		//unowned
		//foreach(HVBoxItem item in this.children){
		unowned List<HVBoxItem> item_it=null;
		if(this.children != null)
		for (item_it = this.children; this.children !=null && item_it != null; item_it = item_it.next) {
			unowned HVBoxItem item = item_it.data;
			if(item.widget!=null && (item.widget is Gtk.Widget)){
				unowned Widget widget = item.widget;
				if(item!=null && !item.ignore && widget!=null) //ignore dnd window
					callback(widget);
			}
		}
	}

	public override void add (Widget w){
		debug("add\n");
		unowned Widget widget = w;
		widget.set_parent(this);
		var item = new HVBoxItem(widget);


		drag_source_set (widget, Gdk.ModifierType.BUTTON1_MASK, target_entries, Gdk.DragAction.MOVE);

		widget.drag_begin.connect ((context) => {
			if(dnd_inprocess)return;
			dnd_inprocess=true;
			  debug ("drag begin");
	//~ 		  drag_highlight (widget);
			  widget.unparent ();

			  dnd_window = new Window (WindowType.POPUP);
			  dnd_window.name="HVBox_dnd_window";
			  dnd_window.set_screen(widget.get_screen());
			  dnd_window.add (widget);
			  dnd_window.show();

			  item.ignore=true;

			  dnd_window.draw.connect ((cr)=>{widget.draw(cr); return true;});

			  drag_set_icon_widget(context, dnd_window, (widget.get_allocated_width()/2), (widget.get_allocated_height()/2));
			  //this.update_size();
			  debug ("drag begin2");
//~ 			  base.drag_begin(context) ;
		});

		widget.drag_data_get.connect ((context, selection_data, info, time) => {
				debug ("drag data get");
				Gdk.Atom target = Gdk.Atom.intern_static_string ("GTK_HVBOX_ITEM");

				if(selection_data.get_target () == target){
					//workaround for vala 0.14 selection_data.set uchar[]
 					uchar[] adata = new uchar[sizeof(void *)];//should work on x86_64 too
 					ulong* pdata = (ulong *)(&adata[0]);//should work on x86_64 too
					HVBoxItem** pitem=&item;//should work on x86_64 too
					*pdata=pitem;
					selection_data.set (target,8,(uchar[])adata);
//~ 					base.drag_data_get(context, selection_data, info, time) ;
				}
		});

		widget.drag_end.connect ((context) => {
			  debug ("drag end");
			  dnd_window.remove (widget);
			  widget.set_parent (this);
			  dnd_window.destroy();
			  item.ignore=false;
			  this.update_size();
			  drag_end(context);
			  dnd_inprocess=false;
		});


		if(children.first()!=null)
			children.append(item);
		else
			children.prepend(item);
		this.queue_resize();
	}

	public override void remove (Widget widget){
		debug("remove\n");
		foreach(unowned HVBoxItem item in this.children){
			if(item.widget == widget){
				item.widget.unparent();
				children.remove(item);
				if(children.length()>0 && this.visible){
					int minimum_height,natural_height;
					hvbox_get_preferred_height_for_width(this.get_allocated_width(),out minimum_height, out natural_height);
					this.queue_resize();//and redraw
				}
				return;
				//possible problem not optimized exit
//~ 				item.destroy();
//~ 				return;
			}
		}
	}

	public int children_index (Widget widget){
		foreach( HVBoxItem item in this.children){
			if (item.widget==widget)
				return children.index(item) ;
		}

	return -1;
	}

	public unowned Widget children_nth (int index){
		debug("Get_from_index\n");
		HVBoxItem item = children.nth_data(index);
		if(item != null)
			return item.widget;
		else
			return null;
	}

	public unowned Widget children_last (){
		debug("children_last\n");
		HVBoxItem item = children.last().data;
		if(item != null)
			return item.widget;
		else
			return null;

	}
	public void place_before(Widget before,Widget what){
		unowned List<unowned HVBoxItem> item_it=null;
		int b_index=this.children_index(before);
		int w_index=this.children_index(what);
		debug("place_before bef=%d what=%d\n",b_index,w_index);
		if(b_index>=0 && w_index>=0){
			debug("place_before bef=%d what=%d\n",b_index,w_index);
			item_it= children.nth(b_index);
			HVBoxItem bdata=children.nth_data(w_index) ;
			this.children.remove(bdata);
			this.children.insert_before(item_it,bdata);
		}
		//else{}//shouldnot happens!
	}
	public void place_on_index(Widget what,int new_index){
		unowned List<unowned HVBoxItem> item_it=null;
		int w_index=this.children_index(what);

		if(w_index!=new_index){
			debug("place_on_index w_index=%d new_index=%d\n",w_index,new_index);
			//item_it= children.nth(a_index);
			HVBoxItem bdata=children.nth_data(w_index) ;
			this.children.remove(bdata);
			this.children.insert(bdata,new_index);
		}
	}

	/*public  new void propagate_draw (Gtk.Widget child, Cairo.Context cr) {
		//draw line between child widgets
		var dest_x =0;
		var dest_y =0;
		child.translate_coordinates (this, 0, 0, out dest_x, out dest_y);
		cr.set_line_width (1.0);
		cr.set_line_join (LineJoin.ROUND);
		cr.move_to(dest_x+child.get_allocated_width(),dest_y);
		cr.line_to(dest_x+child.get_allocated_width(), dest_y+child.get_allocated_height());
		cr.stroke ();
		//cr.set_source_rgba (1.0, 0.0, 0.0, 1);
		base.propagate_draw (child, cr);
	}*/
	public override  bool draw (Cairo.Context cr){
		if(!this.visible){
			debug("draw invisible\n");
			return false;//prevent X Window System error
		}
		if(this.children.length()<1){
			return base.draw(cr);
		}
		int width = this.get_allocated_width ();
		int height = this.get_allocated_height ();
		debug("draw\n");
		cr.save ();

		Gtk.StyleContext context = this.get_style_context();
		Gtk.Border border=context.get_border(StateFlags.NORMAL);

		var line_h = 0;
		var allocation = Gtk.Allocation();//don't use new for struct

		allocation.x=0;
		allocation.y=0;
		allocation.height=0;
		allocation.width=0;

		int[] arr_w = {};
		int[] arr_h = {};
		var color = context.get_background_color(StateFlags.NORMAL);
		cr.set_source_rgba (color.red,color.green,color.blue,color.alpha);//background

		if(!background_only_behind_widgets)
			render_background(context,cr, 0, 0,width+border.left+border.right, height+border.top+border.bottom);

		unowned List<HVBoxItem> item_it=null;
		unowned List<HVBoxItem> end_of_line=null;
		//draw background only behind widgets
		for (item_it = this.children; item_it != null; item_it = item_it.next) {

			end_of_line=item_it;
			line_h = get_line_height(ref end_of_line, width-border.left-border.right,false);//get end of line

			allocation.x = 0 ;//start of the line
			allocation.height=line_h;//base height for line
			allocation.width=0;
			unowned List<HVBoxItem> line_item=item_it;

			for (line_item=item_it; (line_item != null && end_of_line != null) &&
				line_item != end_of_line.next ; line_item = line_item.next) {

				unowned HVBoxItem item = line_item.data;
				unowned Widget widget = item.widget;
				allocation.width+=item.widget.get_allocated_width();
			}
			if(background_only_behind_widgets)
				render_background(context,cr, allocation.x, allocation.y,allocation.width+border.left+border.right, allocation.height+border.top+border.bottom);
			//calculate every line width and height
			arr_h += allocation.height;
			arr_w += allocation.width;

			allocation.y+=allocation.height;
			item_it = end_of_line;
		}

		cr.set_line_width (2.0);
		cr.set_line_join (LineJoin.ROUND);
		color = context.get_border_color(StateFlags.NORMAL);
		cr.set_source_rgba (color.red,color.green,color.blue,color.alpha);//border
		//horizontal top
		cr.set_line_width (border.bottom);
		cr.move_to(arr_w[0]+border.right,0+border.bottom/2);
		cr.line_to(width, 0+border.bottom/2);
		cr.stroke ();
		var h_tmp = arr_h[0];
		var line_count = arr_w.length;
		for(var i = 1; i<line_count;i++){
			if(arr_w[i]<=arr_w[i-1]){
				//horizontal
				cr.set_line_width (border.bottom);
				cr.move_to (border.left+arr_w[i], h_tmp+border.bottom/2);
				cr.line_to(border.left+arr_w[i-1]+border.right, h_tmp+border.bottom/2);
				cr.stroke ();
				//vertical
				cr.set_line_width (border.right);
				cr.move_to (border.left+arr_w[i-1]+border.right/2, h_tmp+border.bottom);
				cr.line_to(border.left+arr_w[i-1]+border.right/2, h_tmp-arr_h[i-1]);
				cr.stroke ();
			}else{
				//horizontal
				cr.set_line_width (border.bottom);
				cr.move_to (border.left+arr_w[i-1], h_tmp);
				cr.line_to(border.left+arr_w[i]+border.right, h_tmp);
				cr.stroke ();
				//vertical
				cr.set_line_width (border.right);
				cr.move_to (border.left+arr_w[i-1]+border.right/2, h_tmp+border.bottom/2);
				cr.line_to(border.left+arr_w[i-1]+border.right/2, h_tmp-arr_h[i-1]);
				cr.stroke ();
			}
			h_tmp += arr_h[i];
		}
		//horizontal bottom
		cr.set_line_width (border.bottom);
		cr.move_to (0,allocation.y+border.bottom/2);
		cr.line_to(allocation.width+border.left+border.right, allocation.y+border.bottom/2);
		cr.stroke ();
		//vertical right
		cr.set_line_width (border.right);
		cr.move_to (border.left+allocation.width+border.right/2,allocation.y-arr_h[line_count-1]+border.right/2);
		cr.line_to(border.left+allocation.width+border.right/2, allocation.y+border.right/2);
		cr.stroke ();
		//vertical left
		cr.set_line_width (border.left);
		cr.move_to (border.left/2,0);
		cr.line_to(border.left/2, height);
		cr.stroke ();

		cr.restore();
		var pos_x=0;
		foreach(unowned HVBoxItem item in this.children){
			if(item.widget.parent==this)//prevent dnd crash
				this.propagate_draw(item.widget,cr);
			//manual draw emplementation
			//cr.save();
			//item.widget.draw(cr);
			//cr.new_path();
			//pos_x+=item.widget.get_allocated_width();
			//debug("draw\n %s",((VTToggleButton) item.widget).label);
			//cr.move_to (pos_x,0);
			//cr.translate (pos_x, 0);//actual move in context
			//cr.stroke();
			//cr.restore();
			//cr.restore();
		}
		return false;
	}

	public void set_default_width(int new_width){
		this.initial_size=0;
		this.self_minimum_width=new_width;
		this.self_natural_width=new_width;
		this.update_size();
	}

}
