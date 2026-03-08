namespace Taskit.Widgets {
    public class TaskDialog : Gtk.Window {
        private Models.Task task;
        
        private Gtk.Entry title_entry;
        private Gtk.TextView desc_view;
        private Gtk.Entry tags_entry;
        private Gtk.ListBox attachments_list;
        private Gee.ArrayList<string> attachments;
        private Gtk.Button due_date_btn;
        private string current_due_date = "";
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
            this.current_due_date = task.due_date;
            this.attachments = new Gee.ArrayList<string> ();
            if (task.attachments != null && task.attachments != "") {
                foreach (var a in task.attachments.split (",")) {
                    if (a.strip () != "") this.attachments.add (a.strip ());
                }
            }
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
            
            var scroll = new Gtk.ScrolledWindow ();
            scroll.vexpand = true;
            var inner_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 16);
            scroll.set_child (inner_content);
            
            // Title
            var title_label = new Granite.HeaderLabel ("Title");
            title_label.halign = Gtk.Align.START;
            title_label.size = Granite.HeaderLabel.Size.H3;
            title_entry = new Gtk.Entry ();
            title_entry.set_text (task.title);
            inner_content.append (title_label);
            inner_content.append (title_entry);
            
            // Description
            var desc_label = new Granite.HeaderLabel ("Description");
            desc_label.halign = Gtk.Align.START;
            desc_label.size = Granite.HeaderLabel.Size.H3;
            
            var desc_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            desc_box.add_css_class ("boxed-list");
            desc_box.height_request = 150;
            
            var format_toolbar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
            format_toolbar.margin_top = 2;
            format_toolbar.margin_bottom = 2;
            format_toolbar.margin_start = 4;
            
            var bold_btn = new Gtk.Button.from_icon_name ("format-text-bold-symbolic");
            bold_btn.add_css_class ("flat");
            var italic_btn = new Gtk.Button.from_icon_name ("format-text-italic-symbolic");
            italic_btn.add_css_class ("flat");
            
            format_toolbar.append (bold_btn);
            format_toolbar.append (italic_btn);
            desc_box.append (format_toolbar);

            desc_view = new Gtk.TextView ();
            desc_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
            var buffer = desc_view.get_buffer ();
            buffer.set_text (task.description != null ? task.description : "", -1);
            
            var bold_tag = buffer.create_tag ("bold", "weight", Pango.Weight.BOLD);
            var italic_tag = buffer.create_tag ("italic", "style", Pango.Style.ITALIC);
            
            bold_btn.clicked.connect (() => {
                Gtk.TextIter start, end;
                if (buffer.get_selection_bounds (out start, out end)) {
                    if (buffer.has_selection && start.has_tag (bold_tag)) {
                        buffer.remove_tag (bold_tag, start, end);
                    } else {
                        buffer.apply_tag (bold_tag, start, end);
                    }
                }
            });
            
            italic_btn.clicked.connect (() => {
                Gtk.TextIter start, end;
                if (buffer.get_selection_bounds (out start, out end)) {
                    if (buffer.has_selection && start.has_tag (italic_tag)) {
                        buffer.remove_tag (italic_tag, start, end);
                    } else {
                        buffer.apply_tag (italic_tag, start, end);
                    }
                }
            });

            var desc_scroll = new Gtk.ScrolledWindow ();
            desc_scroll.set_child (desc_view);
            desc_scroll.vexpand = true;
            desc_box.append (desc_scroll);
            
            inner_content.append (desc_label);
            inner_content.append (desc_box);
            
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
            
            due_date_btn = new Gtk.Button.with_label (current_due_date != "" ? current_due_date : "None");
            due_date_btn.add_css_class ("flat");
            
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
            var min_spin = new Gtk.SpinButton.with_range (0, 59, 1);
            
            // Initializing values from current_due_date
            if (current_due_date != "") {
                var parts = current_due_date.split (" ");
                var date_parts = parts[0].split ("-");
                if (date_parts.length == 3) {
                    var dt = new DateTime.local (int.parse (date_parts[0]), int.parse (date_parts[1]), int.parse (date_parts[2]), 0, 0, 0);
                    calendar.select_day (dt);
                }
                if (parts.length == 2) {
                    var time_parts = parts[1].split (":");
                    if (time_parts.length == 2) {
                        hour_spin.set_value (int.parse (time_parts[0]));
                        min_spin.set_value (int.parse (time_parts[1]));
                    }
                } else {
                    hour_spin.set_value (12);
                    min_spin.set_value (0);
                }
            } else {
                hour_spin.set_value (12);
                min_spin.set_value (0);
            }
            
            time_box.append (new Gtk.Label ("Time:"));
            time_box.append (hour_spin);
            time_box.append (new Gtk.Label (":"));
            time_box.append (min_spin);
            picker_box.append (time_box);
            
            calendar.day_selected.connect (() => {
                var dt = calendar.get_date ();
                current_due_date = dt.format ("%Y-%m-%d") + " " + "%02g:%02g".printf (hour_spin.get_value (), min_spin.get_value ());
                due_date_btn.set_label (current_due_date);
            });
            hour_spin.value_changed.connect (() => {
                var dt = calendar.get_date ();
                current_due_date = dt.format ("%Y-%m-%d") + " " + "%02g:%02g".printf (hour_spin.get_value (), min_spin.get_value ());
                due_date_btn.set_label (current_due_date);
            });
            min_spin.value_changed.connect (() => {
                var dt = calendar.get_date ();
                current_due_date = dt.format ("%Y-%m-%d") + " " + "%02g:%02g".printf (hour_spin.get_value (), min_spin.get_value ());
                due_date_btn.set_label (current_due_date);
            });
            
            popover.set_child (picker_box);
            due_date_btn.clicked.connect (() => {
                popover.set_parent (due_date_btn);
                popover.popup ();
            });
            
            form_grid.attach (date_label, 0, 1);
            form_grid.attach (due_date_btn, 1, 1);

            // Tags
            var tags_label = new Gtk.Label ("Tags");
            tags_label.halign = Gtk.Align.START;
            tags_entry = new Gtk.Entry ();
            tags_entry.placeholder_text = "tag1, tag2...";
            tags_entry.set_text (task.tags != null ? task.tags : "");
            
            form_grid.attach (tags_label, 0, 2);
            form_grid.attach (tags_entry, 1, 2);
            
            inner_content.append (form_grid);

            // Attachments
            var attach_label = new Granite.HeaderLabel ("Attachments");
            attach_label.halign = Gtk.Align.START;
            attach_label.size = Granite.HeaderLabel.Size.H3;
            inner_content.append (attach_label);

            attachments_list = new Gtk.ListBox ();
            attachments_list.add_css_class ("boxed-list");
            attachments_list.selection_mode = Gtk.SelectionMode.NONE;
            inner_content.append (attachments_list);

            foreach (var a in attachments) {
                add_attachment_row (a);
            }

            var add_attach_btn = new Gtk.Button.with_label ("Add File");
            add_attach_btn.clicked.connect (on_add_attachment_clicked);
            inner_content.append (add_attach_btn);
            
            main_box.append (scroll);
            this.set_child (main_box);
        }

        private void add_attachment_row (string path) {
            var row_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            row_box.margin_top = 4;
            row_box.margin_bottom = 4;
            row_box.margin_start = 8;
            row_box.margin_end = 8;

            var label = new Gtk.Label (path);
            label.hexpand = true;
            label.halign = Gtk.Align.START;
            label.ellipsize = Pango.EllipsizeMode.MIDDLE;
            row_box.append (label);

            var del_btn = new Gtk.Button.from_icon_name ("taskit-trash-symbolic");
            del_btn.add_css_class ("flat");
            del_btn.clicked.connect (() => {
                attachments.remove (path);
                attachments_list.remove (row_box.get_parent () as Gtk.Widget);
            });
            row_box.append (del_btn);

            attachments_list.append (row_box);
        }

        private void on_add_attachment_clicked () {
            var chooser = new Gtk.FileChooserNative ("Select File", this, Gtk.FileChooserAction.OPEN, "Open", "Cancel");
            chooser.response.connect ((res) => {
                if (res == Gtk.ResponseType.ACCEPT) {
                    var file = chooser.get_file ();
                    var path = file.get_path ();
                    if (!attachments.contains (path)) {
                        attachments.add (path);
                        add_attachment_row (path);
                    }
                }
            });
            chooser.show ();
        }
        
        private void on_save_clicked () {
            task.title = title_entry.get_text ();
            Gtk.TextIter start, end;
            desc_view.get_buffer ().get_bounds (out start, out end);
            task.description = desc_view.get_buffer ().get_text (start, end, false);
            task.priority = (int)priority_dropdown.selected;
            task.due_date = current_due_date;
            task.tags = tags_entry.get_text ();
            
            // Serialize attachments
            string attach_str = "";
            foreach (var a in attachments) {
                if (attach_str != "") attach_str += ",";
                attach_str += a;
            }
            task.attachments = attach_str;
            
            task_updated ();
            this.destroy ();
        }
    }
}