// modules: gio-2.0 gdk-pixbuf-2.0

using GLib;

int main (string[] args) {
	string file_name;
	var base_dir = args[1];
	try {
		var dir = Dir.open (base_dir);
		while ((file_name = dir.read_name ()) != null) {
			try {
				var img = new Gdk.Pixbuf.from_file (base_dir + Path.DIR_SEPARATOR_S + file_name);
				if (img.get_height() > 16 && img.get_width() > 16) {
						print (file_name + "\n");
				}
			} catch (Error e) {
				stderr.printf (e.message + "\n");
			}
		}
	} catch (FileError fe) {
		error (fe.message);
	}
	return 0;
}
