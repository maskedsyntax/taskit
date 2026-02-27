namespace Taskit.Models {
    public class Project : Object {
        public int id { get; set; }
        public string name { get; set; }
        public string color { get; set; }
        
        public Project () {
            id = -1;
            name = "";
            color = "#007bff";
        }
    }
}