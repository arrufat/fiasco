// modules: gio-2.0 gdk-pixbuf-2.0

using GLib;

public class Main : Object {
	private static bool version = false;
	[CCode (array_length = false, array_null_terminated = true)]
	private static string[] directory = null;
	private static int num_threads = 0;

	private const OptionEntry[] options = {
		{ "", 0, 0, OptionArg.FILENAME_ARRAY, ref directory, "Directory with images to parse", "DIRECTORY" },
		{ "threads", 't', 0, OptionArg.INT, ref num_threads, "Use the given number of threads", "INT" },
		{ "version", 0, 0, OptionArg.NONE, ref version, "Display version number", null },
		{ null } // list terminator
	};

	public static int main (string[] args) {

		/* parse the command line */
		try {
			var opt_context = new OptionContext ("- filter out bad images");
			opt_context.set_help_enabled (true);
			opt_context.add_main_entries (options, null);
			opt_context.parse (ref args);
		} catch (OptionError e) {
			stdout.printf ("error: %s\n", e.message);
			stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
			return 0;
		}

		/* get the number of threads to use */
		if (num_threads < 1) {
			num_threads = (int) get_num_processors ();
		}
		message ("Using %d threads\n", num_threads);

		/* get all files from directory */
		string file_name;
		var base_dir = directory[0];
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
		var num_files = files.length;
		message ("Found %u files\n", num_files);
		var lst = new string[num_files];

		/* process files in parallel */
		try {
			var threads = new ThreadPool<Worker>.with_owned_data ((ThreadPoolFunc<Worker>) Worker.filter_images, num_threads, true);
			for (var i = 0; i < num_threads; i++) {
				uint start = i * (num_files / num_threads);
				uint end = (i + 1) * (num_files / num_threads) - 1;
				if (i == num_files - 1) end += num_files % num_threads;
				message (@"Thread $(i + 1): start: $start, end: $end (amount: $(end - start + 1))\n");
				threads.add (new Worker (ref files, ref lst, start, end));
			}
		} catch (ThreadError e) {
			stderr.printf ("%s\n", e.message);
		}

		/* fill an array with image files only */
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
}


class Worker : Object {
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

	/* filter out non image files */
	public static void filter_images (Worker w) {
		for (var i = w.start; i < w.end; i++) {
			var file_path = w.arr.index (i);
			try {
				var img = new Gdk.Pixbuf.from_file (file_path);
				if (img.get_height () >= 16 && img.get_width () >= 16) {
					w.lst[i] = file_path;
				}
			} catch (Error e) {
				stderr.printf ("i = %06u => %s\n", i, file_path);
			}
		}
	}
}
