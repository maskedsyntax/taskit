namespace Taskit.Widgets {
    public class SidebarRow : Gtk.ListBoxRow {
        public string id { get; private set; }
        private Gtk.Label title_label;
        private Gtk.Image icon;
        
        public SidebarRow (string id, string title, string icon_name) {
            this.id = id;
            
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            box.margin_top = 8;
            box.margin_bottom = 8;
            box.margin_start = 12;
            box.margin_end = 12;
            
            icon = new Gtk.Image.from_icon_name (icon_name);
            title_label = new Gtk.Label (title);
            title_label.halign = Gtk.Align.START;
            title_label.hexpand = true;
            
            box.append (icon);
            box.append (title_label);
            
            this.child = box;
        }
        
        public void set_color (string color_hex) {
            // Apply a color to the icon or row if it's a project
            var css_provider = new Gtk.CssProvider ();
            css_provider.load_from_string (@"* { color: $color_hex; }");
            icon.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }
    }
}