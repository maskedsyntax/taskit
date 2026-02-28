using Notify;

namespace Taskit {
    public class NotificationManager : Object {
        private static NotificationManager? instance = null;
        private Gee.HashSet<int> notified_task_ids;
        
        private NotificationManager () {
            notified_task_ids = new Gee.HashSet<int> ();
            Notify.init ("Taskit");
        }
        
        public static NotificationManager get_instance () {
            if (instance == null) {
                instance = new NotificationManager ();
            }
            return instance;
        }
        
        public void start_monitoring () {
            // Check every minute
            GLib.Timeout.add_seconds (60, () => {
                check_deadlines ();
                return true;
            });
            
            // Immediate check on start
            check_deadlines ();
        }
        
        private void check_deadlines () {
            var tasks = DatabaseManager.get_instance ().get_all_tasks ();
            var now = new DateTime.now_local ();
            var now_str = now.format ("%Y-%m-%d %H:%M");
            
            // Also check for 15 minutes ahead
            var upcoming = now.add_minutes (15);
            var upcoming_str = upcoming.format ("%Y-%m-%d %H:%M");
            
            foreach (var task in tasks) {
                if (task.is_completed || task.due_date == null || task.due_date == "" || notified_task_ids.contains (task.id)) {
                    continue;
                }
                
                if (task.due_date <= now_str) {
                    send_notification (task, "Deadline reached!");
                    notified_task_ids.add (task.id);
                } else if (task.due_date <= upcoming_str) {
                    send_notification (task, "Due in 15 minutes");
                    notified_task_ids.add (task.id);
                }
            }
        }
        
        private void send_notification (Models.Task task, string message) {
            var notification = new Notify.Notification (
                "Taskit: " + task.title,
                message,
                "org.gnome.Taskit"
            );
            
            try {
                notification.show ();
            } catch (GLib.Error e) {
                warning ("Failed to show notification: %s", e.message);
            }
        }
    }
}