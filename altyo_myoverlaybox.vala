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
 * Custom implementation of GtkOverlay
 * author: Konstantinov Denis <linvinus@gmail.com>
 *
 * */

using Gtk;

public class MyOverlayBox : Bin {
	private Widget main_widget=null;
	private Widget overlay_widget=null;

	public MyOverlayBox(){
		//this.set_has_window (false);
	}

	public override void add (Widget w){
		if(main_widget==null){
			w.set_parent(this);
			main_widget=w;
			w.show();
		}
	}

	public void add_overlay (Widget w){
		if(overlay_widget==null){
			w.set_parent(this);
			overlay_widget=w;
		}
	}

	public override SizeRequestMode get_request_mode () {
		return (Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH);
	}

	public override void get_preferred_width (out int o_minimum_width, out int o_natural_width) {
		var nat = 0;
		var min = 0;
		if(main_widget!=null)
			main_widget.get_preferred_width (out min, out nat);

		o_minimum_width=int.max(o_minimum_width,min);
		o_natural_width=int.max(o_natural_width,nat);

		if(overlay_widget!=null)
			overlay_widget.get_preferred_width (out min, out nat);
//~Ignore overlay_widget size
//~ 		o_minimum_width=int.max(o_minimum_width,min);
//~ 		o_natural_width=int.max(o_natural_width,nat);
	}

	public override void get_preferred_height_for_width (int width,out int minimum_height, out int natural_height) {
		var nat = 0;
		var min = 0;
		if(main_widget!=null)
			main_widget.get_preferred_height_for_width (width,out min, out nat);

		minimum_height=int.max(minimum_height,min);
		natural_height=int.max(natural_height,nat);

		if(overlay_widget!=null)
			overlay_widget.get_preferred_height_for_width (width,out min, out nat);
//~Ignore overlay_widget size
//~ 			minimum_height=int.max(minimum_height,min);
//~ 			natural_height=int.max(natural_height,nat);
	}

	public override void size_allocate (Gtk.Allocation allocation) {
		base.size_allocate (allocation);//allocate container it self

		if(main_widget!=null)
			main_widget.size_allocate(allocation);

		if(overlay_widget!=null){
			allocation.x+=0;
			allocation.y+=0;
			//setup same size as main_widget no variants
			overlay_widget.set_size_request(allocation.width,allocation.height);
			overlay_widget.size_allocate(allocation);
		}

	}

    public override void forall_internal(bool include_internal,Gtk.Callback callback){
		if(main_widget!=null && main_widget.parent==this)
			callback(main_widget);
		if(overlay_widget!=null && overlay_widget.parent==this)
			callback(overlay_widget);
	}

	public override void remove (Widget widget){
		widget.unparent();
	}

	public override void map () {
		//first present overlay_widget , otherwise overlay_widget will be behind main_widget!
		if(this.overlay_widget.visible)
			this.overlay_widget.map();
		base.map();
	}

	public override void realize () {
		debug("realize");

		/*var attributes = new Gdk.WindowAttr();
		int attributes_mask;
		Gtk.Allocation allocation;

		this.get_allocation (out allocation);

		attributes.window_type = Gdk.WindowType.CHILD;
		attributes.wclass = Gdk.WindowWindowClass.OUTPUT;
		attributes.width = allocation.width;
		attributes.height = allocation.height;
		attributes.x = allocation.x;
		attributes.y = allocation.y;
		attributes_mask = Gdk.WindowAttributesType.X | Gdk.WindowAttributesType.Y;
		attributes.event_mask = this.get_events () | Gdk.EventMask.EXPOSURE_MASK;

		var window = new Gdk.Window (this.get_window (),
                           attributes, attributes_mask);

		//dialog_vbox.set_window (vtw.get_window());
		this.set_window (window);
		//this.set_has_window (true);*/

		debug("before base realize");
		base.realize();
		debug("after base realize");

		var attributes = Gdk.WindowAttr();
		int attributes_mask;
		Gtk.Allocation allocation;

		overlay_widget.get_allocation (out allocation);

		attributes.window_type = Gdk.WindowType.CHILD;
		attributes.wclass = Gdk.WindowWindowClass.INPUT_OUTPUT;
		attributes.width = allocation.width;
		attributes.height = allocation.height;
		attributes.x = allocation.x;
		attributes.y = allocation.y;
		attributes_mask = Gdk.WindowAttributesType.X | Gdk.WindowAttributesType.Y;
		attributes.event_mask = overlay_widget.get_events () | Gdk.EventMask.EXPOSURE_MASK;

		var window = new Gdk.Window (this.get_window (),
                           attributes, attributes_mask);

		//dialog_vbox.set_window (vtw.get_window());
		overlay_widget.set_parent_window (window);
		overlay_widget.set_has_window (true);
		//vtw.overlay_notebook.show_all();
	}

}//MyOverlayBox
