namespace Taskit.Widgets {
    public class TaskDialog : Gtk.Window {
        private Models.Task task;
        
        private Gtk.Entry title_entry;
        private Gtk.TextView desc_view;
        private Gtk.Entry due_date_entry;
        private Gtk.DropDown priority_dropdown;
        
        public signal void task_updated ();
        
        public TaskDialog (Gtk.Window parent, Models.Task task) {
            Object (
                transient_for: parent,
                modal: true,
                title: "Task Details",
                default_width: 450,
                default_height: 550
            );
            
            this.task = task;
            build_ui ();
        }
        
        private void build_ui () {
            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            
            var header = new Gtk.HeaderBar ();
            header.show_title_buttons = true;
            
            var save_btn = new Gtk.Button.with_label ("Save");
            save_btn.add_css_class (Granite.CssClass.SUGGESTED);
            save_btn.clicked.connect (on_save_clicked);
            header.pack_end (save_btn);
            
            main_box.append (header);
            
            var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 16);
            content.margin_top = 24;
            content.margin_start = 32;
            content.margin_end = 32;
            content.margin_bottom = 24;
            
            // Title
            var title_label = new Granite.HeaderLabel ("Title");
            title_label.halign = Gtk.Align.START;
            title_label.size = Granite.HeaderLabel.Size.H3;
            title_entry = new Gtk.Entry ();
            title_entry.set_text (task.title);
            content.append (title_label);
            content.append (title_entry);
            
            // Description
            var desc_label = new Granite.HeaderLabel ("Description");
            desc_label.halign = Gtk.Align.START;
            desc_label.size = Granite.HeaderLabel.Size.H3;
            desc_view = new Gtk.TextView ();
            desc_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            desc_view.get_buffer ().set_text (task.description != null ? task.description : "", -1);
            var desc_scroll = new Gtk.ScrolledWindow ();
            desc_scroll.set_child (desc_view);
            desc_scroll.vexpand = true;
            desc_scroll.add_css_class ("boxed-list");
            content.append (desc_label);
            content.append (desc_scroll);
            
            var form_grid = new Gtk.Grid ();
            form_grid.column_spacing = 12;
            form_grid.row_spacing = 12;
            
            // Priority
            var prio_label = new Gtk.Label ("Priority");
            prio_label.halign = Gtk.Align.START;
            var prio_model = new Gtk.StringList (null);
            prio_model.append ("Low");
            prio_model.append ("Medium");
            prio_model.append ("High");
            priority_dropdown = new Gtk.DropDown (prio_model, null);
            priority_dropdown.selected = task.priority;
            
            form_grid.attach (prio_label, 0, 0);
            form_grid.attach (priority_dropdown, 1, 0);
            
            // Due Date
            var date_label = new Gtk.Label ("Due Date");
            date_label.halign = Gtk.Align.START;
            due_date_entry = new Gtk.Entry ();
            due_date_entry.placeholder_text = "YYYY-MM-DD";
            if (task.due_date != null) due_date_entry.set_text (task.due_date);
            
            form_grid.attach (date_label, 0, 1);
            form_grid.attach (due_date_entry, 1, 1);
            
            content.append (form_grid);
            
            main_box.append (content);
            this.set_child (main_box);
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