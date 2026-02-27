namespace Taskit.Widgets {
    public class TaskDialog : Adw.Window {
        private Models.Task task;
        
        private Gtk.Entry title_entry;
        private Gtk.TextView desc_view;
        private Gtk.Entry due_date_entry;
        private Gtk.DropDown priority_dropdown;
        
        public signal void task_updated ();
        
        public TaskDialog (Adw.ApplicationWindow parent, Models.Task task) {
            Object (
                transient_for: parent,
                modal: true,
                title: "Task Details",
                default_width: 400,
                default_height: 500
            );
            
            this.task = task;
            build_ui ();
        }
        
        private void build_ui () {
            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            
            var header = new Adw.HeaderBar ();
            header.show_end_title_buttons = false;
            
            var close_btn = new Gtk.Button.with_label ("Save");
            close_btn.add_css_class ("suggested-action");
            close_btn.clicked.connect (on_save_clicked);
            header.pack_end (close_btn);
            
            main_box.append (header);
            
            var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 15);
            content.margin_top = 20;
            content.margin_start = 20;
            content.margin_end = 20;
            content.margin_bottom = 20;
            
            // Title
            var title_label = new Gtk.Label ("Title");
            title_label.halign = Gtk.Align.START;
            title_entry = new Gtk.Entry ();
            title_entry.set_text (task.title);
            content.append (title_label);
            content.append (title_entry);
            
            // Description
            var desc_label = new Gtk.Label ("Description");
            desc_label.halign = Gtk.Align.START;
            desc_view = new Gtk.TextView ();
            desc_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            desc_view.get_buffer ().set_text (task.description, -1);
            var desc_scroll = new Gtk.ScrolledWindow ();
            desc_scroll.set_child (desc_view);
            desc_scroll.vexpand = true;
            content.append (desc_label);
            content.append (desc_scroll);
            
            // Priority
            var prio_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            var prio_label = new Gtk.Label ("Priority");
            var prio_model = new Gtk.StringList (null);
            prio_model.append ("Low");
            prio_model.append ("Medium");
            prio_model.append ("High");
            priority_dropdown = new Gtk.DropDown (prio_model, null);
            priority_dropdown.selected = task.priority;
            prio_box.append (prio_label);
            prio_box.append (priority_dropdown);
            content.append (prio_box);
            
            // Due Date
            var date_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            var date_label = new Gtk.Label ("Due Date");
            due_date_entry = new Gtk.Entry ();
            due_date_entry.placeholder_text = "YYYY-MM-DD";
            if (task.due_date != null) due_date_entry.set_text (task.due_date);
            date_box.append (date_label);
            date_box.append (due_date_entry);
            content.append (date_box);
            
            main_box.append (content);
            this.content = main_box;
        }
        
        private void on_save_clicked () {
            task.title = title_entry.get_text ();
            Gtk.TextIter start, end;
            desc_view.get_buffer ().get_bounds (out start, out end);
            task.description = desc_view.get_buffer ().get_text (start, end, false);
            task.priority = (int)priority_dropdown.selected;
            task.due_date = due_date_entry.get_text ();
            
            task_updated ();
            this.destroy ();
        }
    }
}