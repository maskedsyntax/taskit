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
    }
}
