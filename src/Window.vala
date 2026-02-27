namespace Taskit {
    public class Window : Adw.ApplicationWindow {
        private Gtk.ListBox task_list;
        private Gtk.Entry task_entry;
        
        public Window (Application app) {
            Object (
                application: app,
                title: "Taskit",
                default_width: 800,
                default_height: 600
            );
            
            build_ui ();
            load_tasks ();
        }
        
        private void build_ui () {
            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            
            var header_bar = new Adw.HeaderBar ();
            header_bar.title_widget = new Adw.WindowTitle ("Taskit", "");
            
            var add_btn = new Gtk.Button.from_icon_name ("list-add-symbolic");
            add_btn.clicked.connect (on_add_task_clicked);
            header_bar.pack_start (add_btn);
            
            main_box.append (header_bar);
            
            // Sidebar and Content area using Adw.Leaflet or Gtk.Paned
            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            paned.vexpand = true;
            paned.hexpand = true;
            
            // Sidebar
            var sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
            sidebar.width_request = 200;
            sidebar.margin_top = 10;
            sidebar.margin_start = 10;
            sidebar.margin_end = 10;
            
            var all_tasks_btn = new Gtk.Button.with_label ("All Tasks");
            sidebar.append (all_tasks_btn);
            
            // Main Content Area
            var content_area = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
            content_area.margin_top = 10;
            content_area.margin_start = 10;
            content_area.margin_end = 10;
            content_area.margin_bottom = 10;
            
            // Input for new task
            var input_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            task_entry = new Gtk.Entry ();
            task_entry.placeholder_text = "What needs to be done?";
            task_entry.hexpand = true;
            task_entry.activate.connect (on_add_task_clicked);
            
            input_box.append (task_entry);
            
            var add_task_btn = new Gtk.Button.with_label ("Add");
            add_task_btn.clicked.connect (on_add_task_clicked);
            add_task_btn.add_css_class ("suggested-action");
            input_box.append (add_task_btn);
            
            content_area.append (input_box);
            
            // Task List
            var scroll = new Gtk.ScrolledWindow ();
            scroll.vexpand = true;
            scroll.hexpand = true;
            scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
            scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            
            task_list = new Gtk.ListBox ();
            task_list.selection_mode = Gtk.SelectionMode.NONE;
            scroll.set_child (task_list);
            
            content_area.append (scroll);
            
            paned.set_start_child (sidebar);
            paned.set_end_child (content_area);
            
            main_box.append (paned);
            
            this.content = main_box;
        }
        
        private void on_add_task_clicked () {
            var text = task_entry.get_text ().strip ();
            if (text != "") {
                var task = new Models.Task ();
                task.title = text;
                task.is_completed = false;
                task.priority = 1;
                
                DatabaseManager.get_instance ().insert_task (task);
                add_task_row (task);
                
                task_entry.set_text ("");
            }
        }
        
        private void load_tasks () {
            var tasks = DatabaseManager.get_instance ().get_all_tasks ();
            foreach (var task in tasks) {
                add_task_row (task);
            }
        }
        
        private void add_task_row (Models.Task task) {
            var row = new Widgets.TaskRow (task);
            row.task_updated.connect (() => {
                DatabaseManager.get_instance ().update_task (task);
            });
            row.task_deleted.connect (() => {
                DatabaseManager.get_instance ().delete_task (task.id);
                task_list.remove (row);
            });
            task_list.append (row);
        }
    }
}