// modules: gio-2.0 gdk-pixbuf-2.0

using GLib;

int main (string[] args) {
	var num_proc = (int) get_num_processors ();
	message ("Using %d threads\n", num_proc);
	string file_name;
	var base_dir = args[1];
	var files = new Array<string> ();
	try {
		var dir = Dir.open (base_dir);
		while ((file_name = dir.read_name ()) != null) {
			var file_path = base_dir + Path.DIR_SEPARATOR_S + file_name;
			files.append_val (file_path);
		}
	} catch (FileError fe) {
		error (fe.message);
	}
	var n = files.length;
	message ("Found %u files\n", n);
	var lst = new string[n];

	try {
		var threads = new ThreadPool<Worker>.with_owned_data ((ThreadPoolFunc<Worker>) filter_image, num_proc, true);
		for (var i = 0; i < num_proc; i++) {
			uint start = i * (n / num_proc);
			uint end = (i + 1) * (n / num_proc) - 1;
			if (i == num_proc - 1) end += n % num_proc;
			message (@"Thread $(i + 1): start: $start, end: $end (amount: $(end - start + 1))\n");
			threads.add (new Worker (ref files, ref lst, start, end));
		}
	} catch (ThreadError e) {
		stderr.printf ("%s\n", e.message);
	}

	var imgs = new Array<string> ();
	for (var i = 0; i < lst.length; i ++) {
		if (lst[i] != null) {
			imgs.append_val (lst[i]);
			stdout.printf (lst[i] + "\n");
		}
	}
	message ("Found %u images\n", imgs.length);

	return 0;
}

class Worker {
	public unowned Array<string> arr;
	public unowned string[] lst;
	public uint start;
	public uint end;

	public Worker (ref Array<string> arr, ref string[] lst, uint start, uint end) {
		this.arr = arr;
		this.lst = lst;
		this.start = start;
		this.end = end;
	}
}

void filter_image (Worker w) {
	for (var i = w.start; i < w.end; i++) {
		var file_path = w.arr.index (i);
		try {
			var img = new Gdk.Pixbuf.from_file (file_path);
			if (img.get_height() > 16 && img.get_width() > 16) {
				w.lst[i] = file_path;
			}
		} catch (Error e) {
			stderr.printf ("i = %06u => %s\n", i, file_path);
		}
	}
}
