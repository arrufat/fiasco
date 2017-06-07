// modules: gio-2.0 gdk-pixbuf-2.0
// sources: subprojects/optionguess/src/optionguess.vala
// sources: subprojects/optionguess/src/termcolors.vala
// sources: subprojects/optionguess/src/levenshtein.vala
// sources: subprojects/parallel-vala/src/parallel.vala

using GLib;
using OG;
using Parallel;

public static bool fast = false;
public static int size = 0;
public static bool verbose = false;

public class Main : Object {
	private static bool version = false;
	[CCode (array_length = false, array_null_terminated = true)]
	private static string[] directory = null;
	private static int num_threads = 0;

	private const OptionEntry[] options = {
		{ "", 0, 0, OptionArg.FILENAME_ARRAY, ref directory, "Directory with images to parse", "DIRECTORY" },
		{ "threads", 't', 0, OptionArg.INT, ref num_threads, "Use the given number of threads (default: all)", "INT" },
		{ "size", 's', 0, OptionArg.INT, ref size, "Filter out images smaller than size x size (default: 16)", "INT" },
		{ "fast", 'f', 0, OptionArg.NONE, ref fast, "Faster but less reliable mode without image loading", null },
		{ "verbose", 'v', 0, OptionArg.NONE, ref verbose, "Be verbose", null },
		{ "version", 0, 0, OptionArg.NONE, ref version, "Display version number", null },
		{ null } // list terminator
	};

	public static int main (string[] args) {

		var args_length = args.length;
		string help;
		/* parse the command line */
		try {
			var opt_context = new OptionContext ("- filter out bad images");
			opt_context.set_help_enabled (true);
			opt_context.add_main_entries (options, null);
			opt_context.parse (ref args);
			help = opt_context.get_help (true, null);
		} catch (OptionError e) {
			var opt_guess = new OptionGuess (options, e);
			opt_guess.print_message ();
			return 0;
		}

		if (args_length == 1) {
			print (help + "\n");
			return 0;
		}

		if (version) {
			print ("vparser - 0.1.0\n");
			return 0;
		}

		if (size < 1 ) {
			size = 16;
		}

		/* get the number of threads to use */
		if (num_threads < 1) {
			num_threads = (int) get_num_processors ();
		}
		if (verbose) {
			message ("Using %d threads", num_threads);
		}

		/* get all files from directory */
		string file_name;
		var base_dir = directory[0];
		string[] files = {};
		try {
			var dir = Dir.open (base_dir);
			while ((file_name = dir.read_name ()) != null) {
				var file_path = Path.build_filename (base_dir, file_name);
				files += file_path;
			}
		} catch (FileError e) {
			error (e.message);
		}
		var num_files = files.length;
		if (verbose) {
			message ("Found %u files", num_files);
		}

		var par = new ParArray<string> ();
		par.data = files;
		par.function = filter_images;
		par.dispatch ();

		var num_imgs = 0;
		foreach (var f in files) {
			if (f != null) {
				stdout.printf (f + "\n");
				num_imgs++;
			}
		}

		if (verbose) {
			message ("Found %u images", num_imgs);
		}

		return 0;
	}
}

void filter_images (ParArray<string> p) {
	var file_path = p.data[p.index];
	try {
		int width, height;
		if (fast) {
			Gdk.Pixbuf.get_file_info (file_path, out width, out height);
		} else {
			var img = new Gdk.Pixbuf.from_file (file_path);
			width = img.width;
			height = img.height;
		}
		if (width < size || height < size) {
			p.data[p.index] = null;
		}
	} catch (Error e) {
		p.data[p.index] = null;
		if (verbose) {
			message ("i = %06u => %s (%s)", p.index, file_path, e.message);
		}
	}
}
