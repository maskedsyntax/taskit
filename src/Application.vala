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
            
            // Elementary-style CSS
            var css_provider = new Gtk.CssProvider();
            css_provider.load_from_string("""
                headerbar {
                    background: #fcfcfc;
                    border-bottom: 1px solid #dcdcdc;
                    padding: 8px 12px;
                }
                
                .navigation-sidebar {
                    background-color: #f6f6f6;
                    border-right: 1px solid #dcdcdc;
                }
                
                button.suggested-action {
                    background-color: #368aeb;
                    color: white;
                    border-radius: 4px;
                    border: none;
                    font-weight: bold;
                }
                
                button.suggested-action:hover {
                    background-color: #4ea1ff;
                }
                
                .project-folder {
                    background-color: #368aeb;
                    color: white;
                    border-radius: 4px;
                    padding: 4px 8px;
                }
                
                entry {
                    border-radius: 4px;
                    border: 1px solid #dcdcdc;
                    padding: 6px 10px;
                }
                
                list {
                    background-color: white;
                }
                
                .boxed-list {
                    border: 1px solid #dcdcdc;
                    border-radius: 6px;
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