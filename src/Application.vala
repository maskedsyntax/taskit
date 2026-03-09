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
            
            // Adaptive CSS for Dark Mode support (Ultra-minimal, zero unnecessary lines)
            var css_provider = new Gtk.CssProvider();
            css_provider.load_from_string("""
                .compact-toolbar {
                    background: @headerbar_bg_color;
                    border: none;
                    min-height: 36px;
                    padding: 0 8px;
                }
                
                .navigation-sidebar {
                    background-color: @window_bg_color;
                    border-right: 1px solid alpha(@border_color, 0.2);
                }
                
                button {
                    border: none;
                    background: none;
                    box-shadow: none;
                    padding: 4px 8px;
                    min-height: 28px;
                }
                
                button:hover {
                    background-color: alpha(currentColor, 0.08);
                }
                
                button.suggested-action {
                    background-color: @accent_bg_color;
                    color: @accent_fg_color;
                    font-weight: 500;
                    border-radius: 2px;
                }
                
                entry {
                    border: 1px solid alpha(@border_color, 0.3);
                    background-color: @view_bg_color;
                    border-radius: 2px;
                    padding: 4px 8px;
                    box-shadow: none;
                }
                
                list {
                    background-color: transparent;
                }
                
                row {
                    border: none;
                    background-color: transparent;
                    padding: 8px 12px;
                    margin: 0;
                }
                
                row:hover {
                    background-color: alpha(currentColor, 0.03);
                }
                
                row:selected {
                    background-color: alpha(@accent_bg_color, 0.15);
                    color: inherit;
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
                    background-color: alpha(@border_color, 0.1);
                    min-height: 1px;
                    margin: 4px 0;
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