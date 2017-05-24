// modules: gio-2.0 gdk-pixbuf-2.0

using GLib;

const uint16 JPG = 55551;
const uint16 PNG = 20617;

int main (string[] args) {
	string file_name;
	var base_dir = args[1];
	try {
		var dir = Dir.open (base_dir);
		while ((file_name = dir.read_name ()) != null) {
			var file = File.new_for_path (base_dir + Path.DIR_SEPARATOR_S + file_name);
			try {

				var file_stream = file.read ();
				var data_stream = new DataInputStream (file_stream);
				data_stream.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);

				try {
					uint16 signature = data_stream.read_uint16 ();
					if ((signature == JPG) || (signature ==  PNG)) {
						print (file_name + "\n");
					}
				} catch (IOError ioe) {
					stderr.printf (ioe.message + "\n");
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
