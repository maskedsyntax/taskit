namespace Taskit.Widgets {
    public class TaskRow : Gtk.ListBoxRow {
        public Models.Task task { get; private set; }
        
        public signal void task_updated ();
        public signal void task_deleted ();
        public signal void task_edit_requested ();
        public signal void subtask_add_requested ();
        
        private Gtk.CheckButton check_button;
        private Gtk.Label title_label;
        private Gtk.Button add_subtask_button;
        private Gtk.Button edit_button;
        private Gtk.Button delete_button;
        
        public TaskRow (Models.Task task) {
            this.task = task;
            
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            box.margin_top = 4;
            box.margin_bottom = 4;
            box.margin_start = 8;
            box.margin_end = 8;
            
            // Indentation for subtasks
            if (task.parent_id != -1) {
                box.margin_start = 32;
            }
            
            check_button = new Gtk.CheckButton ();
            check_button.active = task.is_completed;
            check_button.valign = Gtk.Align.CENTER;
            check_button.toggled.connect (on_check_toggled);
            
            title_label = new Gtk.Label (task.title);
            title_label.hexpand = true;
            title_label.halign = Gtk.Align.START;
            title_label.valign = Gtk.Align.CENTER;
            title_label.ellipsize = Pango.EllipsizeMode.END;
            
            update_title_style ();
            
            // Deadline indicator
            if (task.due_date != null && task.due_date != "") {
                var date_label = new Gtk.Label (task.due_date);
                date_label.add_css_class (Granite.CssClass.DIM);
                date_label.add_css_class ("small-label");
                date_label.margin_end = 8;
                
                // Overdue check
                var now = new DateTime.now_local ();
                var today_str = now.format ("%Y-%m-%d");
                if (task.due_date.strip () != "" && task.due_date.strip () < today_str && !task.is_completed) {
                    date_label.add_css_class ("overdue");
                    date_label.remove_css_class (Granite.CssClass.DIM);
                }
                
                box.append (date_label);
            }
            
            add_subtask_button = new Gtk.Button.from_icon_name ("taskit-plus-symbolic");
            add_subtask_button.valign = Gtk.Align.CENTER;
            add_subtask_button.add_css_class ("flat");
            add_subtask_button.tooltip_text = "Add Subtask";
            add_subtask_button.clicked.connect (() => {
                subtask_add_requested ();
            });
            
            edit_button = new Gtk.Button.from_icon_name ("taskit-edit-symbolic");
            edit_button.valign = Gtk.Align.CENTER;
            edit_button.add_css_class ("flat");
            edit_button.clicked.connect (() => {
                task_edit_requested ();
            });
            
            delete_button = new Gtk.Button.from_icon_name ("taskit-trash-symbolic");
            delete_button.valign = Gtk.Align.CENTER;
            delete_button.add_css_class ("destructive-action");
            delete_button.clicked.connect (() => {
                task_deleted ();
            });
            
            box.append (check_button);
            box.append (title_label);
            box.append (add_subtask_button);
            box.append (edit_button);
            box.append (delete_button);
            
            this.child = box;
        }
        
        private void on_check_toggled () {
            task.is_completed = check_button.active;
            update_title_style ();
            task_updated ();
        }
        
        private void update_title_style () {
            if (task.is_completed) {
                title_label.set_markup ("<s>" + GLib.Markup.escape_text (task.title) + "</s>");
                title_label.add_css_class (Granite.CssClass.DIM);
                title_label.opacity = 0.5;
            } else {
                title_label.set_markup (GLib.Markup.escape_text (task.title));
                title_label.remove_css_class (Granite.CssClass.DIM);
                title_label.opacity = 1.0;
            }
        }
    }
}