using Json;

namespace Taskit {
    public class ExportManager : GLib.Object {
        public static void export_to_json (string path) {
            var tasks = DatabaseManager.get_instance ().get_all_tasks ();
            var array = new Json.Array ();
            
            foreach (var t in tasks) {
                var obj = new Json.Object ();
                obj.set_int_member ("id", t.id);
                obj.set_string_member ("title", t.title);
                obj.set_string_member ("description", t.description);
                obj.set_boolean_member ("is_completed", t.is_completed);
                obj.set_int_member ("priority", t.priority);
                obj.set_string_member ("due_date", t.due_date);
                obj.set_int_member ("project_id", t.project_id);
                obj.set_int_member ("parent_id", t.parent_id);
                obj.set_string_member ("tags", t.tags);
                obj.set_string_member ("attachments", t.attachments);
                array.add_element (new Json.Node.alloc ().init_object (obj));
            }
            
            var root = new Json.Node.alloc ().init_array (array);
            var generator = new Json.Generator ();
            generator.set_root (root);
            generator.set_pretty (true);
            
            try {
                generator.to_file (path);
            } catch (GLib.Error e) {
                warning ("Failed to export JSON: %s", e.message);
            }
        }

        public static void export_to_ical (string path) {
            var tasks = DatabaseManager.get_instance ().get_all_tasks ();
            var sb = new StringBuilder ();
            sb.append ("BEGIN:VCALENDAR\n");
            sb.append ("VERSION:2.0\n");
            sb.append ("PRODID:-//Taskit//Task Manager//EN\n");
            
            foreach (var t in tasks) {
                if (t.due_date == null || t.due_date == "") continue;
                
                sb.append ("BEGIN:VTODO\n");
                sb.append ("UID:%d@taskit\n".printf (t.id));
                sb.append ("SUMMARY:%s\n".printf (t.title));
                if (t.description != "") sb.append ("DESCRIPTION:%s\n".printf (t.description));
                if (t.is_completed) sb.append ("STATUS:COMPLETED\n");
                
                // Format date for iCal (YYYYMMDDTHHMMSS)
                var d = t.due_date.replace ("-", "").replace (":", "").replace (" ", "T") + "00";
                sb.append ("DUE:%s\n".printf (d));
                
                sb.append ("END:VTODO\n");
            }
            
            sb.append ("END:VCALENDAR\n");
            
            try {
                FileUtils.set_contents (path, sb.str);
            } catch (GLib.Error e) {
                warning ("Failed to export iCal: %s", e.message);
            }
        }

        public static void import_from_json (string path) {
            var parser = new Json.Parser ();
            try {
                parser.load_from_file (path);
                var root = parser.get_root ();
                if (root == null || root.get_node_type () != Json.NodeType.ARRAY) return;
                
                var array = root.get_array ();
                foreach (var element in array.get_elements ()) {
                    var obj = element.get_object ();
                    var task = new Models.Task ();
                    task.title = obj.get_string_member ("title");
                    task.description = obj.get_string_member ("description");
                    task.is_completed = obj.get_boolean_member ("is_completed");
                    task.priority = (int)obj.get_int_member ("priority");
                    task.due_date = obj.get_string_member ("due_date");
                    task.project_id = (int)obj.get_int_member ("project_id");
                    task.parent_id = (int)obj.get_int_member ("parent_id");
                    task.tags = obj.get_string_member ("tags");
                    task.attachments = obj.get_string_member ("attachments");
                    
                    DatabaseManager.get_instance ().insert_task (task);
                }
            } catch (GLib.Error e) {
                warning ("Failed to import JSON: %s", e.message);
            }
        }

        public static void import_from_ical (string path) {
            try {
                string content;
                FileUtils.get_contents (path, out content);
                var lines = content.split ("\n");
                Models.Task? current_task = null;
                
                foreach (var line in lines) {
                    var l = line.strip ();
                    if (l == "BEGIN:VTODO") {
                        current_task = new Models.Task ();
                    } else if (l == "END:VTODO" && current_task != null) {
                        DatabaseManager.get_instance ().insert_task (current_task);
                        current_task = null;
                    } else if (current_task != null) {
                        if (l.has_prefix ("SUMMARY:")) {
                            current_task.title = l.substring (8);
                        } else if (l.has_prefix ("DESCRIPTION:")) {
                            current_task.description = l.substring (12);
                        } else if (l.has_prefix ("STATUS:COMPLETED")) {
                            current_task.is_completed = true;
                        } else if (l.has_prefix ("DUE:")) {
                            var d = l.substring (4); // YYYYMMDDTHHMMSS00
                            if (d.length >= 15) {
                                current_task.due_date = "%s-%s-%s %s:%s".printf (
                                    d.substring (0, 4), d.substring (4, 2), d.substring (6, 2),
                                    d.substring (9, 2), d.substring (11, 2)
                                );
                            }
                        }
                    }
                }
            } catch (GLib.Error e) {
                warning ("Failed to import iCal: %s", e.message);
            }
        }
    }
}
