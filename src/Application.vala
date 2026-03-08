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
            
            // Adaptive CSS for Dark Mode support
            var css_provider = new Gtk.CssProvider();
            css_provider.load_from_string("""
                .compact-toolbar {
                    background: @headerbar_bg_color;
                    border-bottom: 1px solid @border_color;
                    min-height: 28px;
                }
                
                .navigation-sidebar {
                    background-color: @window_bg_color;
                    border-right: 1px solid @border_color;
                }
                
                button {
                    padding: 2px 6px;
                    min-height: 24px;
                }
                
                button.suggested-action {
                    background-color: @accent_bg_color;
                    color: @accent_fg_color;
                    border-radius: 2px;
                    border: none;
                    font-weight: 500;
                }
                
                entry {
                    border-radius: 2px;
                    border: 1px solid @border_color;
                    padding: 2px 6px;
                    min-height: 24px;
                    font-size: 9pt;
                }
                
                label {
                    font-size: 9pt;
                }
                
                .project-folder {
                    background-color: @accent_bg_color;
                    color: @accent_fg_color;
                    border-radius: 2px;
                    padding: 1px 4px;
                }
                
                list {
                    background-color: @view_bg_color;
                }
                
                .boxed-list {
                    border: 1px solid @border_color;
                    border-radius: 2px;
                }
                
                row {
                    padding: 2px 6px;
                    border-bottom: 1px solid @border_color;
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
            """);
            Gtk.StyleContext.add_provider_for_display(
                Gdk.Display.get_default(),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }
    }
}