using Sqlite;

namespace Taskit {
    public class DatabaseManager : Object {
        private static DatabaseManager? instance = null;
        private Database db;
        
        private DatabaseManager () {
            string db_path = Environment.get_user_data_dir () + "/taskit/tasks.db";
            
            // Ensure directory exists
            var dir = GLib.File.new_for_path (Environment.get_user_data_dir () + "/taskit");
            if (!dir.query_exists ()) {
                try {
                    dir.make_directory_with_parents (null);
                } catch (GLib.Error e) {
                    warning ("Failed to create directory: %s", e.message);
                }
            }
            
            if (Database.open (db_path, out db) != Sqlite.OK) {
                warning ("Can't open database: %d", db.errcode ());
            }
        }
        
        public static DatabaseManager get_instance () {
            if (instance == null) {
                instance = new DatabaseManager ();
            }
            return instance;
        }
        
        public void init_db () {
            string query = """
                CREATE TABLE IF NOT EXISTS tasks (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    title TEXT NOT NULL,
                    description TEXT,
                    is_completed INTEGER DEFAULT 0,
                    priority INTEGER DEFAULT 1,
                    due_date TEXT,
                    project_id INTEGER
                );
            """;
            
            char* errmsg;
            if (db.exec (query, null, out errmsg) != Sqlite.OK) {
                warning ("Error creating table: %s", (string)errmsg);
            }
        }
        
        public void insert_task (Models.Task task) {
            Statement stmt;
            string query = "INSERT INTO tasks (title, description, is_completed, priority, due_date, project_id) VALUES (?, ?, ?, ?, ?, ?)";
            
            if (db.prepare_v2 (query, -1, out stmt, null) == Sqlite.OK) {
                stmt.bind_text (1, task.title);
                stmt.bind_text (2, task.description != null ? task.description : "");
                stmt.bind_int (3, task.is_completed ? 1 : 0);
                stmt.bind_int (4, task.priority);
                stmt.bind_text (5, task.due_date != null ? task.due_date : "");
                stmt.bind_int (6, task.project_id);
                
                if (stmt.step () != Sqlite.DONE) {
                    warning ("Error inserting task");
                }
                
                task.id = (int)db.last_insert_rowid ();
            }
        }
        
        public Gee.ArrayList<Models.Task> get_all_tasks () {
            var list = new Gee.ArrayList<Models.Task> ();
            Statement stmt;
            string query = "SELECT id, title, description, is_completed, priority, due_date, project_id FROM tasks";
            
            if (db.prepare_v2 (query, -1, out stmt, null) == Sqlite.OK) {
                while (stmt.step () == Sqlite.ROW) {
                    var task = new Models.Task ();
                    task.id = stmt.column_int (0);
                    task.title = stmt.column_text (1);
                    task.description = stmt.column_text (2);
                    task.is_completed = stmt.column_int (3) == 1;
                    task.priority = stmt.column_int (4);
                    task.due_date = stmt.column_text (5);
                    task.project_id = stmt.column_int (6);
                    list.add (task);
                }
            }
            
            return list;
        }
        
        public void update_task (Models.Task task) {
            Statement stmt;
            string query = "UPDATE tasks SET title=?, description=?, is_completed=?, priority=?, due_date=?, project_id=? WHERE id=?";
            
            if (db.prepare_v2 (query, -1, out stmt, null) == Sqlite.OK) {
                stmt.bind_text (1, task.title);
                stmt.bind_text (2, task.description != null ? task.description : "");
                stmt.bind_int (3, task.is_completed ? 1 : 0);
                stmt.bind_int (4, task.priority);
                stmt.bind_text (5, task.due_date != null ? task.due_date : "");
                stmt.bind_int (6, task.project_id);
                stmt.bind_int (7, task.id);
                
                if (stmt.step () != Sqlite.DONE) {
                    warning ("Error updating task");
                }
            }
        }
        
        public void delete_task (int id) {
            Statement stmt;
            string query = "DELETE FROM tasks WHERE id=?";
            
            if (db.prepare_v2 (query, -1, out stmt, null) == Sqlite.OK) {
                stmt.bind_int (1, id);
                if (stmt.step () != Sqlite.DONE) {
                    warning ("Error deleting task");
                }
            }
        }
    }
}