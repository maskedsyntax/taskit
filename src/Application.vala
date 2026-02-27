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
            
            // Database init
            DatabaseManager.get_instance().init_db();
            
            // Any custom styles or icons
            var css_provider = new Gtk.CssProvider();
            css_provider.load_from_string("""
                .project-folder {
                    background-color: #007bff;
                    color: white;
                    border-radius: 8px;
                    padding: 4px 8px;
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