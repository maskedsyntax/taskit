namespace Taskit {
    public class Window : Adw.ApplicationWindow {
        private Gtk.ListBox sidebar_list;
        private Gtk.ListBox task_list;
        private Gtk.Entry task_entry;
        private Adw.WindowTitle window_title;
        
        private int current_project_id = -1;
        private string current_view = "all"; // "all", "today", "project"
        
        public Window (Application app) {
            Object (
                application: app,
                title: "Taskit",
                default_width: 900,
                default_height: 600
            );
            
            build_ui ();
            load_sidebar ();
            load_tasks ();
        }
        
        private void build_ui () {
            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            
            var header_bar = new Adw.HeaderBar ();
            window_title = new Adw.WindowTitle ("Taskit", "All Tasks");
            header_bar.title_widget = window_title;
            
            var add_project_btn = new Gtk.Button.from_icon_name ("folder-new-symbolic");
            add_project_btn.tooltip_text = "New Project";
            add_project_btn.clicked.connect (on_add_project_clicked);
            header_bar.pack_start (add_project_btn);
            
            main_box.append (header_bar);
            
            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            paned.vexpand = true;
            paned.hexpand = true;
            paned.position = 250;
            
            // Sidebar
            var sidebar_scroll = new Gtk.ScrolledWindow ();
            sidebar_scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
            
            sidebar_list = new Gtk.ListBox ();
            sidebar_list.selection_mode = Gtk.SelectionMode.SINGLE;
            sidebar_list.add_css_class ("navigation-sidebar");
            sidebar_list.row_selected.connect (on_sidebar_row_selected);
            
            sidebar_scroll.set_child (sidebar_list);
            
            // Main Content Area
            var content_area = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
            content_area.margin_top = 20;
            content_area.margin_start = 40;
            content_area.margin_end = 40;
            content_area.margin_bottom = 20;
            
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
            task_list.add_css_class ("boxed-list");
            scroll.set_child (task_list);
            
            content_area.append (scroll);
            
            paned.set_start_child (sidebar_scroll);
            paned.set_end_child (content_area);
            
            main_box.append (paned);
            
            this.content = main_box;
        }
        
        private void load_sidebar () {
            // Clear existing
            var child = sidebar_list.get_first_child ();
            while (child != null) {
                var next = child.get_next_sibling ();
                sidebar_list.remove (child);
                child = next;
            }
            
            // Smart lists
            sidebar_list.append (new Widgets.SidebarRow ("all", "All Tasks", "view-list-symbolic"));
            sidebar_list.append (new Widgets.SidebarRow ("today", "Today", "go-today-symbolic"));
            
            // Projects header
            var sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            sep.margin_top = 10;
            sep.margin_bottom = 10;
            sidebar_list.append (sep);
            
            var projects = DatabaseManager.get_instance ().get_all_projects ();
            foreach (var project in projects) {
                var row = new Widgets.SidebarRow ("project_" + project.id.to_string(), project.name, "folder-symbolic");
                row.set_color (project.color);
                sidebar_list.append (row);
            }
        }
        
        private void on_sidebar_row_selected (Gtk.ListBoxRow? row) {
            if (row == null) return;
            
            if (row is Widgets.SidebarRow) {
                var s_row = (Widgets.SidebarRow) row;
                if (s_row.id == "all") {
                    current_view = "all";
                    current_project_id = -1;
                    window_title.subtitle = "All Tasks";
                } else if (s_row.id == "today") {
                    current_view = "today";
                    current_project_id = -1;
                    window_title.subtitle = "Today";
                } else if (s_row.id.has_prefix ("project_")) {
                    current_view = "project";
                    current_project_id = int.parse (s_row.id.substring (8));
                    // Get project name for subtitle
                    var projects = DatabaseManager.get_instance ().get_all_projects ();
                    foreach (var p in projects) {
                        if (p.id == current_project_id) {
                            window_title.subtitle = p.name;
                            break;
                        }
                    }
                }
                load_tasks ();
            }
        }
        
        private void on_add_project_clicked () {
            // Simple prompt for project name (In a real app, use a proper Dialog)
            var dialog = new Adw.MessageDialog (this, "New Project", "");
            
            var entry = new Gtk.Entry ();
            entry.placeholder_text = "Project Name";
            dialog.set_extra_child (entry);
            
            dialog.add_response ("cancel", "Cancel");
            dialog.add_response ("add", "Add");
            dialog.set_response_appearance ("add", Adw.ResponseAppearance.SUGGESTED);
            
            dialog.response.connect ((response) => {
                if (response == "add") {
                    var name = entry.get_text ().strip ();
                    if (name != "") {
                        var p = new Models.Project ();
                        p.name = name;
                        p.color = "#007bff"; // Default color
                        DatabaseManager.get_instance ().insert_project (p);
                        load_sidebar ();
                    }
                }
            });
            
            dialog.present ();
        }
        
        private void on_add_task_clicked () {
            var text = task_entry.get_text ().strip ();
            if (text != "") {
                var task = new Models.Task ();
                task.title = text;
                task.is_completed = false;
                task.priority = 1;
                task.project_id = current_project_id;
                
                DatabaseManager.get_instance ().insert_task (task);
                add_task_row (task);
                
                task_entry.set_text ("");
            }
        }
        
        private void load_tasks () {
            // Clear current list
            var child = task_list.get_first_child ();
            while (child != null) {
                var next = child.get_next_sibling ();
                task_list.remove (child);
                child = next;
            }
            
            var tasks = DatabaseManager.get_instance ().get_all_tasks ();
            foreach (var task in tasks) {
                bool show = false;
                if (current_view == "all") {
                    show = true;
                } else if (current_view == "today") {
                    // Placeholder logic: would check if due_date is today
                    show = (task.due_date != null && task.due_date != "");
                } else if (current_view == "project") {
                    show = (task.project_id == current_project_id);
                }
                
                if (show) {
                    add_task_row (task);
                }
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