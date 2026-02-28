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
            
            // Elementary-style CSS (Modified for crispness/compactness)
            var css_provider = new Gtk.CssProvider();
            css_provider.load_from_string("""
                .compact-toolbar {
                    background: #f8f8f8;
                    border-bottom: 1px solid #ddd;
                    min-height: 28px;
                }
                
                .navigation-sidebar {
                    background-color: #f0f0f0;
                    border-right: 1px solid #ddd;
                }
                
                button {
                    padding: 2px 6px;
                    min-height: 24px;
                }
                
                button.suggested-action {
                    background-color: #368aeb;
                    color: white;
                    border-radius: 2px;
                    border: none;
                    font-weight: 500;
                }
                
                entry {
                    border-radius: 2px;
                    border: 1px solid #ccc;
                    padding: 2px 6px;
                    min-height: 24px;
                    font-size: 9pt;
                }
                
                label {
                    font-size: 9pt;
                }
                
                .project-folder {
                    background-color: #368aeb;
                    color: white;
                    border-radius: 2px;
                    padding: 1px 4px;
                }
                
                list {
                    background-color: white;
                }
                
                .boxed-list {
                    border: 1px solid #eee;
                    border-radius: 2px;
                }
                
                row {
                    padding: 2px 6px;
                    border-bottom: 1px solid #fafafa;
                }
                
                window {
                    border-radius: 0;
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