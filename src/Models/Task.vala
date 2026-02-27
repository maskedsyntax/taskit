namespace Taskit.Models {
    public class Task : Object {
        public int id { get; set; }
        public string title { get; set; }
        public string description { get; set; }
        public bool is_completed { get; set; }
        public int priority { get; set; }
        public string due_date { get; set; }
        public int project_id { get; set; }
        
        public Task () {
            id = -1;
            title = "";
            description = "";
            is_completed = false;
            priority = 1;
            due_date = "";
            project_id = -1;
        }
    }
}