namespace Taskit {
    public class Window : Adw.ApplicationWindow {
        private Gtk.ListBox sidebar_list;
        private Gtk.ListBox task_list;
        private Gtk.Entry task_entry;
        private Granite.HeaderLabel window_title;
        
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
            
            // Compact Toolbar instead of HeaderBar (No window decorations)
            var toolbar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            toolbar.add_css_class ("compact-toolbar");
            toolbar.margin_top = 4;
            toolbar.margin_bottom = 4;
            toolbar.margin_start = 8;
            toolbar.margin_end = 8;
            
            var add_project_btn = new Gtk.Button.from_icon_name ("taskit-folder-new-symbolic");
            add_project_btn.tooltip_text = "New Project";
            add_project_btn.add_css_class ("flat");
            add_project_btn.clicked.connect (on_add_project_clicked);
            toolbar.append (add_project_btn);
            
            window_title = new Granite.HeaderLabel ("Taskit");
            window_title.hexpand = true;
            window_title.halign = Gtk.Align.CENTER;
            toolbar.append (window_title);
            
            var search_entry = new Gtk.SearchEntry ();
            search_entry.placeholder_text = "Search...";
            search_entry.width_request = 150;
            search_entry.search_changed.connect (() => {
                var query = search_entry.get_text ().down ();
                filter_tasks_by_query (query);
            });
            toolbar.append (search_entry);
            
            main_box.append (toolbar);
            
            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            paned.vexpand = true;
            paned.hexpand = true;
            paned.position = 200;
            
            // Sidebar
            var sidebar_scroll = new Gtk.ScrolledWindow ();
            sidebar_scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
            sidebar_scroll.add_css_class (Granite.STYLE_CLASS_SIDEBAR);
            
            sidebar_list = new Gtk.ListBox ();
            sidebar_list.selection_mode = Gtk.SelectionMode.SINGLE;
            sidebar_list.row_selected.connect (on_sidebar_row_selected);
            
            sidebar_scroll.set_child (sidebar_list);
            
            // Main Content Area
            var content_area = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            content_area.margin_top = 8;
            content_area.margin_start = 12;
            content_area.margin_end = 12;
            content_area.margin_bottom = 8;
            
            // Input for new task
            var input_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
            task_entry = new Gtk.Entry ();
            task_entry.placeholder_text = "Task...";
            task_entry.hexpand = true;
            task_entry.activate.connect (on_add_task_clicked);
            
            input_box.append (task_entry);
            
            var add_task_btn = new Gtk.Button.with_label ("Add");
            add_task_btn.clicked.connect (on_add_task_clicked);
            add_task_btn.add_css_class (Granite.CssClass.SUGGESTED);
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
            task_list.add_css_class ("rich-list");
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
            sidebar_list.append (new Widgets.SidebarRow ("all", "All Tasks", "taskit-all-symbolic"));
            sidebar_list.append (new Widgets.SidebarRow ("today", "Today", "taskit-today-symbolic"));
            
            // Projects header
            var sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            sep.margin_top = 10;
            sep.margin_bottom = 10;
            sidebar_list.append (sep);
            
            var projects = DatabaseManager.get_instance ().get_all_projects ();
            foreach (var project in projects) {
                var row = new Widgets.SidebarRow ("project_" + project.id.to_string(), project.name, "taskit-folder-symbolic");
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
                    window_title.label = "All Tasks";
                } else if (s_row.id == "today") {
                    current_view = "today";
                    current_project_id = -1;
                    window_title.label = "Today";
                } else if (s_row.id.has_prefix ("project_")) {
                    current_view = "project";
                    current_project_id = int.parse (s_row.id.substring (8));
                    // Get project name for subtitle
                    var projects = DatabaseManager.get_instance ().get_all_projects ();
                    foreach (var p in projects) {
                        if (p.id == current_project_id) {
                            window_title.label = p.name;
                            break;
                        }
                    }
                }
                load_tasks ();
            }
        }
        
        private void on_add_project_clicked () {
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
                        p.color = "#368aeb"; // elementary blue
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
        
        private void filter_tasks_by_query (string query) {
            var child = task_list.get_first_child ();
            while (child != null) {
                if (child is Widgets.TaskRow) {
                    var row = (Widgets.TaskRow) child;
                    if (query == "" || row.task.title.down ().contains (query) || row.task.description.down ().contains (query)) {
                        row.set_visible (true);
                    } else {
                        row.set_visible (false);
                    }
                }
                child = child.get_next_sibling ();
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
            
            var all_tasks = DatabaseManager.get_instance ().get_all_tasks ();
            
            // First, identify which tasks to show in the current view
            var visible_tasks = new Gee.ArrayList<Models.Task> ();
            foreach (var task in all_tasks) {
                bool show = false;
                if (current_view == "all") {
                    show = true;
                } else if (current_view == "today") {
                    show = (task.due_date != null && task.due_date != "");
                } else if (current_view == "project") {
                    show = (task.project_id == current_project_id);
                }
                
                if (show) visible_tasks.add (task);
            }
            
            // For tasks to be added, we track if they've been added to prevent duplicates
            var added_ids = new Gee.HashSet<int> ();
            
            foreach (var task in visible_tasks) {
                if (task.parent_id == -1 && !added_ids.contains(task.id)) {
                    add_task_row (task);
                    added_ids.add(task.id);
                    // Find and add its subtasks immediately after
                    foreach (var sub in all_tasks) {
                        if (sub.parent_id == task.id) {
                            add_task_row (sub);
                            added_ids.add(sub.id);
                        }
                    }
                }
            }
            
            // Add orphaned tasks (tasks that should be visible but their parents aren't or aren't in view)
            foreach (var task in visible_tasks) {
                if (!added_ids.contains(task.id)) {
                    add_task_row (task);
                    added_ids.add(task.id);
                }
            }
        }
        
        private void add_task_row (Models.Task task) {
            var row = new Widgets.TaskRow (task);
            row.task_updated.connect (() => {
                DatabaseManager.get_instance ().update_task (task);
                
                // 1. If parent is checked/unchecked, update all subtasks
                if (task.parent_id == -1) {
                    var all_tasks = DatabaseManager.get_instance ().get_all_tasks ();
                    var updated = false;
                    foreach (var sub in all_tasks) {
                        if (sub.parent_id == task.id && sub.is_completed != task.is_completed) {
                            sub.is_completed = task.is_completed;
                            DatabaseManager.get_instance ().update_task (sub);
                            updated = true;
                        }
                    }
                    if (updated) load_tasks ();
                }
                
                // 2. If it's a subtask, check parent completion status
                if (task.parent_id != -1) {
                    var all_tasks = DatabaseManager.get_instance ().get_all_tasks ();
                    Models.Task? parent = null;
                    var all_subs_done = true;
                    
                    foreach (var t in all_tasks) {
                        if (t.id == task.parent_id) parent = t;
                        if (t.parent_id == task.parent_id && !t.is_completed) {
                            all_subs_done = false;
                        }
                    }
                    
                    if (parent != null && all_subs_done != parent.is_completed) {
                        parent.is_completed = all_subs_done;
                        DatabaseManager.get_instance ().update_task (parent);
                        load_tasks (); // Reload to update UI
                    }
                }
            });
            row.task_deleted.connect (() => {
                DatabaseManager.get_instance ().delete_task (task.id);
                load_tasks (); // Reload to handle subtask cascade removal
            });
            row.task_edit_requested.connect (() => {
                var dialog = new Widgets.TaskDialog (this, task);
                dialog.task_updated.connect (() => {
                    DatabaseManager.get_instance ().update_task (task);
                    load_tasks ();
                });
                dialog.present ();
            });
            row.subtask_add_requested.connect (() => {
                var subtask = new Models.Task ();
                subtask.title = "Subtask for: " + task.title;
                subtask.parent_id = task.id;
                subtask.project_id = task.project_id;
                DatabaseManager.get_instance ().insert_task (subtask);
                load_tasks ();
            });
            task_list.append (row);
        }
    }
}