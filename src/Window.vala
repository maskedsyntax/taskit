namespace Taskit {
    public class Window : Adw.ApplicationWindow {
        private Gtk.ListBox sidebar_list;
        private Gtk.ListBox task_list;
        private Gtk.Entry task_entry;
        private Gtk.Button date_btn;
        private string selected_date = "";
        private int current_sort = 0; // 0: None, 1: Priority, 2: Deadline, 3: Alphabetical
        private Gtk.Label window_title;
        
        private int current_project_id = -1;
        private string current_view = "all"; // "all", "today", "project"
        
        public Window (Application app) {
            Object (
                application: app,
                title: "Taskit",
                default_width: 900,
                default_height: 600
            );
            
            this.width_request = 850;
            this.height_request = 500;
            
            build_ui ();
            load_sidebar ();
            load_tasks ();
        }
        
        private void build_ui () {
            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            
            // Compact Toolbar with vertical centering
            var toolbar = new Gtk.CenterBox ();
            toolbar.add_css_class ("compact-toolbar");
            toolbar.margin_top = 4;
            toolbar.margin_bottom = 4;
            toolbar.margin_start = 8;
            toolbar.margin_end = 8;
            
            var left_toolbar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            left_toolbar.valign = Gtk.Align.CENTER;
            var add_project_btn = new Gtk.Button.from_icon_name ("taskit-folder-new-symbolic");
            add_project_btn.tooltip_text = "New Project";
            add_project_btn.add_css_class ("flat");
            add_project_btn.clicked.connect (on_add_project_clicked);
            left_toolbar.append (add_project_btn);

            var undo_btn = new Gtk.Button.from_icon_name ("edit-undo-symbolic");
            undo_btn.add_css_class ("flat");
            undo_btn.tooltip_text = "Undo";
            undo_btn.clicked.connect (() => { HistoryManager.get_instance ().undo (); load_tasks (); });
            left_toolbar.append (undo_btn);

            var redo_btn = new Gtk.Button.from_icon_name ("edit-redo-symbolic");
            redo_btn.add_css_class ("flat");
            redo_btn.tooltip_text = "Redo";
            redo_btn.clicked.connect (() => { HistoryManager.get_instance ().redo (); load_tasks (); });
            left_toolbar.append (redo_btn);

            HistoryManager.get_instance ().history_changed.connect (() => {
                undo_btn.sensitive = HistoryManager.get_instance ().can_undo;
                redo_btn.sensitive = HistoryManager.get_instance ().can_redo;
            });
            undo_btn.sensitive = false;
            redo_btn.sensitive = false;
            
            toolbar.set_start_widget (left_toolbar);

            window_title = new Gtk.Label ("Taskit");
            window_title.valign = Gtk.Align.CENTER;
            window_title.add_css_class ("header-title");
            toolbar.set_center_widget (window_title);
            
            var right_toolbar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            right_toolbar.valign = Gtk.Align.CENTER;
            
            var sort_model = new Gtk.StringList (null);
            sort_model.append ("Manual");
            sort_model.append ("Priority");
            sort_model.append ("Deadline");
            sort_model.append ("Alphabetical");
            var sort_dropdown = new Gtk.DropDown (sort_model, null);
            sort_dropdown.notify["selected"].connect (() => {
                current_sort = (int)sort_dropdown.selected;
                load_tasks ();
            });
            right_toolbar.append (sort_dropdown);

            var search_entry = new Gtk.SearchEntry ();
            search_entry.placeholder_text = "Search...";
            search_entry.width_request = 180;
            search_entry.search_changed.connect (() => {
                var query = search_entry.get_text ().down ();
                filter_tasks_by_query (query);
            });
            right_toolbar.append (search_entry);

            var theme_btn = new Gtk.Button ();
            theme_btn.add_css_class ("flat");
            theme_btn.tooltip_text = "Toggle Dark Mode";
            
            var style_manager = Adw.StyleManager.get_default ();
            style_manager.notify["dark"].connect (() => {
                if (style_manager.dark) {
                    theme_btn.icon_name = "taskit-sun-symbolic";
                } else {
                    theme_btn.icon_name = "taskit-theme-symbolic";
                }
            });
            
            // Initial icon
            if (style_manager.dark) theme_btn.icon_name = "taskit-sun-symbolic";
            else theme_btn.icon_name = "taskit-theme-symbolic";
            
            theme_btn.clicked.connect (() => {
                if (style_manager.dark) {
                    style_manager.color_scheme = Adw.ColorScheme.FORCE_LIGHT;
                } else {
                    style_manager.color_scheme = Adw.ColorScheme.FORCE_DARK;
                }
            });
            right_toolbar.append (theme_btn);

            toolbar.set_end_widget (right_toolbar);
            
            main_box.append (toolbar);
            
            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            paned.vexpand = true;
            paned.hexpand = true;
            paned.position = 200;
            
            // Sidebar
            var sidebar_scroll = new Gtk.ScrolledWindow ();
            sidebar_scroll.vexpand = true; // Ensure list takes up space
            sidebar_scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
            sidebar_scroll.add_css_class (Granite.STYLE_CLASS_SIDEBAR);
            
            sidebar_list = new Gtk.ListBox ();
            sidebar_list.selection_mode = Gtk.SelectionMode.SINGLE;
            sidebar_list.row_selected.connect (on_sidebar_row_selected);
            
            sidebar_scroll.set_child (sidebar_list);

            var sidebar_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            sidebar_box.append (sidebar_scroll);

            var export_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
            export_box.margin_top = 8;
            export_box.margin_bottom = 8;
            export_box.margin_start = 8;
            export_box.margin_end = 8;
            export_box.vexpand = false; // Don't let it take extra space

            var json_btn = new Gtk.Button.with_label ("Export JSON");
            json_btn.add_css_class ("flat");
            json_btn.hexpand = true;
            json_btn.clicked.connect (() => {
                var chooser = new Gtk.FileChooserNative ("Export JSON", this, Gtk.FileChooserAction.SAVE, "Save", "Cancel");
                chooser.set_current_name ("tasks.json");
                chooser.response.connect ((res) => {
                    if (res == Gtk.ResponseType.ACCEPT) {
                        ExportManager.export_to_json (chooser.get_file ().get_path ());
                    }
                });
                chooser.show ();
            });

            var ical_btn = new Gtk.Button.with_label ("Export iCal");
            ical_btn.add_css_class ("flat");
            ical_btn.hexpand = true;
            ical_btn.clicked.connect (() => {
                var chooser = new Gtk.FileChooserNative ("Export iCal", this, Gtk.FileChooserAction.SAVE, "Save", "Cancel");
                chooser.set_current_name ("tasks.ics");
                chooser.response.connect ((res) => {
                    if (res == Gtk.ResponseType.ACCEPT) {
                        ExportManager.export_to_ical (chooser.get_file ().get_path ());
                    }
                });
                chooser.show ();
            });

            export_box.append (json_btn);
            export_box.append (ical_btn);
            sidebar_box.append (export_box);

            var import_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
            import_box.margin_bottom = 8;
            import_box.margin_start = 8;
            import_box.margin_end = 8;

            var import_json_btn = new Gtk.Button.with_label ("Import JSON");
            import_json_btn.add_css_class ("flat");
            import_json_btn.hexpand = true;
            import_json_btn.clicked.connect (() => {
                var chooser = new Gtk.FileChooserNative ("Import JSON", this, Gtk.FileChooserAction.OPEN, "Open", "Cancel");
                chooser.response.connect ((res) => {
                    if (res == Gtk.ResponseType.ACCEPT) {
                        ExportManager.import_from_json (chooser.get_file ().get_path ());
                        load_tasks ();
                    }
                });
                chooser.show ();
            });

            var import_ical_btn = new Gtk.Button.with_label ("Import iCal");
            import_ical_btn.add_css_class ("flat");
            import_ical_btn.hexpand = true;
            import_ical_btn.clicked.connect (() => {
                var chooser = new Gtk.FileChooserNative ("Import iCal", this, Gtk.FileChooserAction.OPEN, "Open", "Cancel");
                chooser.response.connect ((res) => {
                    if (res == Gtk.ResponseType.ACCEPT) {
                        ExportManager.import_from_ical (chooser.get_file ().get_path ());
                        load_tasks ();
                    }
                });
                chooser.show ();
            });

            import_box.append (import_json_btn);
            import_box.append (import_ical_btn);
            sidebar_box.append (import_box);
            
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
            
            // Date Picker Popover
            date_btn = new Gtk.Button.from_icon_name ("taskit-today-symbolic");
            date_btn.tooltip_text = "Set Deadline";
            date_btn.add_css_class ("flat");
            
            var popover = new Gtk.Popover ();
            var picker_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            picker_box.margin_top = 4;
            picker_box.margin_bottom = 4;
            picker_box.margin_start = 4;
            picker_box.margin_end = 4;
            
            var calendar = new Gtk.Calendar ();
            picker_box.append (calendar);
            
            var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
            time_box.halign = Gtk.Align.CENTER;
            
            var hour_spin = new Gtk.SpinButton.with_range (0, 23, 1);
            hour_spin.set_value (12);
            var min_spin = new Gtk.SpinButton.with_range (0, 59, 1);
            min_spin.set_value (0);
            
            time_box.append (new Gtk.Label ("Time:"));
            time_box.append (hour_spin);
            time_box.append (new Gtk.Label (":"));
            time_box.append (min_spin);
            picker_box.append (time_box);
            
            calendar.day_selected.connect (() => {
                var dt = calendar.get_date ();
                selected_date = dt.format ("%Y-%m-%d") + " " + "%02g:%02g".printf (hour_spin.get_value (), min_spin.get_value ());
                date_btn.tooltip_text = "Deadline: " + selected_date;
                date_btn.add_css_class ("suggested-action");
            });
            
            // Also update when time changes
            hour_spin.value_changed.connect (() => {
                var dt = calendar.get_date ();
                selected_date = dt.format ("%Y-%m-%d") + " " + "%02g:%02g".printf (hour_spin.get_value (), min_spin.get_value ());
                date_btn.tooltip_text = "Deadline: " + selected_date;
            });
            min_spin.value_changed.connect (() => {
                var dt = calendar.get_date ();
                selected_date = dt.format ("%Y-%m-%d") + " " + "%02g:%02g".printf (hour_spin.get_value (), min_spin.get_value ());
                date_btn.tooltip_text = "Deadline: " + selected_date;
            });
            
            popover.set_child (picker_box);
            date_btn.clicked.connect (() => {
                popover.set_parent (date_btn);
                popover.popup ();
            });
            input_box.append (date_btn);
            
            var add_task_btn = new Gtk.Button.with_label ("Add Task");
            add_task_btn.width_request = 100; // Better width
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
            scroll.set_child (task_list);
            
            content_area.append (scroll);
            
            paned.set_start_child (sidebar_box);
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
            var all_row = new Widgets.SidebarRow ("all", "All Tasks", "taskit-all-symbolic");
            sidebar_list.append (all_row);
            var today_row = new Widgets.SidebarRow ("today", "Today", "taskit-today-symbolic");
            sidebar_list.append (today_row);
            var scheduled_row = new Widgets.SidebarRow ("scheduled", "Scheduled", "taskit-scheduled-symbolic");
            sidebar_list.append (scheduled_row);
            
            if (current_view == "all") sidebar_list.select_row (all_row);
            else if (current_view == "today") sidebar_list.select_row (today_row);
            else if (current_view == "scheduled") sidebar_list.select_row (scheduled_row);

            // Projects header
            var sep_row = new Gtk.ListBoxRow ();
            sep_row.selectable = false;
            sep_row.activatable = false;
            sep_row.can_focus = false;
            
            var sep_line = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            sep_line.add_css_class ("sidebar-separator");
            sep_row.set_child (sep_line);
            sidebar_list.append (sep_row);
            
            var projects = DatabaseManager.get_instance ().get_all_projects ();
            foreach (var project in projects) {
                var row = new Widgets.SidebarRow ("project_" + project.id.to_string(), project.name, "taskit-folder-symbolic");
                row.set_color (project.color);
                sidebar_list.append (row);
                if (current_view == "project" && project.id == current_project_id) {
                    sidebar_list.select_row (row);
                }
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
                } else if (s_row.id == "scheduled") {
                    current_view = "scheduled";
                    current_project_id = -1;
                    window_title.label = "Scheduled";
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
                        
                        current_view = "project";
                        current_project_id = p.id;
                        
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
                task.due_date = selected_date;
                
                DatabaseManager.get_instance ().insert_task (task);
                add_task_row (task);
                
                task_entry.set_text ("");
                selected_date = "";
                date_btn.tooltip_text = "Set Deadline";
                date_btn.remove_css_class ("suggested-action");
            }
        }
        
        private void filter_tasks_by_query (string query) {
            var child = task_list.get_first_child ();
            while (child != null) {
                if (child is Widgets.TaskRow) {
                    var row = (Widgets.TaskRow) child;
                    var t = row.task;
                    bool match = (query == "" || 
                                 t.title.down ().contains (query) || 
                                 (t.description != null && t.description.down ().contains (query)) ||
                                 (t.tags != null && t.tags.down ().contains (query)));
                    
                    if (match) {
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
                    var now = new DateTime.now_local ();
                    var today_str = now.format ("%Y-%m-%d");
                    show = (task.due_date != null && task.due_date.has_prefix (today_str));
                } else if (current_view == "scheduled") {
                    show = (task.due_date != null && task.due_date != "");
                } else if (current_view == "project") {
                    show = (task.project_id == current_project_id);
                }
                
                if (show) visible_tasks.add (task);
            }

            if (current_view == "scheduled") {
                visible_tasks.sort ((a, b) => {
                    return strcmp (a.due_date, b.due_date);
                });
            } else if (current_sort == 1) { // Priority
                visible_tasks.sort ((a, b) => {
                    return b.priority - a.priority; // High priority first
                });
            } else if (current_sort == 2) { // Deadline
                visible_tasks.sort ((a, b) => {
                    if (a.due_date == "" && b.due_date == "") return 0;
                    if (a.due_date == "") return 1;
                    if (b.due_date == "") return -1;
                    return strcmp (a.due_date, b.due_date);
                });
            } else if (current_sort == 3) { // Alphabetical
                visible_tasks.sort ((a, b) => {
                    return strcmp (a.title.down (), b.title.down ());
                });
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
                var all_tasks = DatabaseManager.get_instance ().get_all_tasks ();
                var subtasks = new Gee.ArrayList<Models.Task> ();
                foreach (var t in all_tasks) {
                    if (t.parent_id == task.id) {
                        subtasks.add (t);
                    }
                }
                
                var action = new DeleteTaskAction (task, subtasks);
                HistoryManager.get_instance ().add_action (action);
                
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
                subtask.title = "New Subtask";
                subtask.parent_id = task.id;
                subtask.project_id = task.project_id;
                DatabaseManager.get_instance ().insert_task (subtask);
                load_tasks ();
            });
            task_list.append (row);
        }
    }
}