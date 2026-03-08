namespace Taskit {
    public abstract class HistoryAction : Object {
        public abstract void undo ();
        public abstract void redo ();
    }

    public class DeleteTaskAction : HistoryAction {
        private Models.Task task;
        private Gee.ArrayList<Models.Task> subtasks;

        public DeleteTaskAction (Models.Task task, Gee.ArrayList<Models.Task> subtasks) {
            this.task = task;
            this.subtasks = subtasks;
        }

        public override void undo () {
            DatabaseManager.get_instance ().insert_task (task);
            foreach (var sub in subtasks) {
                DatabaseManager.get_instance ().insert_task (sub);
            }
        }

        public override void redo () {
            DatabaseManager.get_instance ().delete_task (task.id);
        }
    }

    public class HistoryManager : Object {
        private static HistoryManager? instance = null;
        private Gee.Deque<HistoryAction> undo_stack;
        private Gee.Deque<HistoryAction> redo_stack;
        private const int MAX_HISTORY = 20;

        public signal void history_changed ();

        private HistoryManager () {
            undo_stack = new Gee.ArrayDeque<HistoryAction> ();
            redo_stack = new Gee.ArrayDeque<HistoryAction> ();
        }

        public static HistoryManager get_instance () {
            if (instance == null) {
                instance = new HistoryManager ();
            }
            return instance;
        }

        public void add_action (HistoryAction action) {
            undo_stack.add_first (action);
            if (undo_stack.size > MAX_HISTORY) {
                undo_stack.remove_last ();
            }
            redo_stack.clear ();
            history_changed ();
        }

        public void undo () {
            if (undo_stack.is_empty) return;
            var action = undo_stack.remove_first ();
            action.undo ();
            redo_stack.add_first (action);
            history_changed ();
        }

        public void redo () {
            if (redo_stack.is_empty) return;
            var action = redo_stack.remove_first ();
            action.redo ();
            undo_stack.add_first (action);
            history_changed ();
        }

        public bool can_undo { get { return !undo_stack.is_empty; } }
        public bool can_redo { get { return !redo_stack.is_empty; } }
    }
}
