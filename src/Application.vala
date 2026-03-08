namespace Taskit {
    public class Application : Adw.Application {
        private Window? main_window;
        
        public Application () {
            Object (
                application_id: "org.gnome.Taskit",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }
        
        protected override void activate () {
            if (main_window == null) {
                main_window = new Window (this);
            }
            main_window.present ();
        }
        
        protected override void startup () {
            base.startup ();
            
            // Initialize Granite
            Granite.init();
            
            // Register icons from resources
            Gtk.IconTheme.get_for_display (Gdk.Display.get_default ()).add_resource_path ("/org/gnome/Taskit/icons");
            
            // Database init
            DatabaseManager.get_instance().init_db();
            
            // Start notification monitoring
            NotificationManager.get_instance ().start_monitoring ();
            
            // Adaptive CSS for Dark Mode support (Refined for crispness, removing redundant borders)
            var css_provider = new Gtk.CssProvider();
            css_provider.load_from_string("""
                .compact-toolbar {
                    background: @headerbar_bg_color;
                    border-bottom: 1px solid alpha(@border_color, 0.3);
                    min-height: 32px;
                }
                
                .navigation-sidebar {
                    background-color: @window_bg_color;
                    border-right: 1px solid alpha(@border_color, 0.3);
                }
                
                button {
                    padding: 2px 6px;
                    min-height: 24px;
                }
                
                button.flat {
                    border: none;
                    background: none;
                    box-shadow: none;
                }
                
                button.suggested-action {
                    background-color: @accent_bg_color;
                    color: @accent_fg_color;
                    border-radius: 3px;
                    border: none;
                    font-weight: 500;
                }
                
                entry {
                    border-radius: 3px;
                    border: 1px solid alpha(@border_color, 0.5);
                    background-color: @view_bg_color;
                    padding: 4px 8px;
                    min-height: 28px;
                    font-size: 10pt;
                }
                
                list {
                    background-color: transparent;
                }
                
                .boxed-list {
                    border: none; /* Removed redundant outer border */
                }
                
                row {
                    padding: 6px 10px;
                    border-bottom: 1px solid alpha(@border_color, 0.1);
                    background-color: @view_bg_color;
                }
                
                row:last-child {
                    border-bottom: none;
                }
                
                row:selected {
                    background-color: alpha(@accent_bg_color, 0.1);
                    color: inherit;
                }
                
                /* Remove rounding from rows to make them crisp and joined */
                row, row > box {
                    border-radius: 0;
                }
                
                window {
                    border-radius: 0;
                }
                
                .overdue {
                    color: @error_color;
                    font-weight: bold;
                }
                
                .small-label {
                    font-size: 8pt;
                }
                
                separator {
                    background-color: alpha(@border_color, 0.2);
                    min-height: 1px;
                }
            """);
            Gtk.StyleContext.add_provider_for_display(
                Gdk.Display.get_default(),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }
    }
}