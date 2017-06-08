// modules: gio-2.0 gdk-pixbuf-2.0
// sources: subprojects/optionguess/src/optionguess.vala
// sources: subprojects/optionguess/src/termcolors.vala
// sources: subprojects/optionguess/src/levenshtein.vala
// sources: subprojects/parallel-vala/src/parallel.vala

using GLib;
using OG;
using Parallel;

public static bool fast = false;
public static int size = 16;
public static bool verbose = false;
public static bool recursive = false;

public class Main : Object {
	private static bool version = false;
	[CCode (array_length = false, array_null_terminated = true)]
	private static string[] directories = null;
	private static int num_threads = 0;
	private static string? output = null;

	private const OptionEntry[] options = {
		{ "", 0, 0, OptionArg.FILENAME_ARRAY, ref directories, "Directories with images to parse", "DIRECTORY..." },
		{ "size", 's', 0, OptionArg.INT, ref size, "Filter out images smaller than size x size (default: 16)", "INT" },
		{ "output", 'o', 0, OptionArg.FILENAME, ref output, "The file where the resulting list will be written (default: stdout)", "FILENAME" },
		{ "recursive", 'r', 0, OptionArg.NONE, ref recursive, "Crawl directories recursively", null },
		{ "fast", 'f', 0, OptionArg.NONE, ref fast, "Faster but less reliable mode without image loading", null },
		{ "threads", 't', 0, OptionArg.INT, ref num_threads, "Use the given number of threads (default: all)", "INT" },
		{ "verbose", 'v', 0, OptionArg.NONE, ref verbose, "Be verbose", null },
		{ "version", 0, 0, OptionArg.NONE, ref version, "Display version number", null },
		{ null } // list terminator
	};

	public static int main (string[] args) {

		var args_length = args.length;
		string help;
		/* parse the command line */
		try {
			var opt_context = new OptionContext ("- Filter Images According to Size using Command-line Options");
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
			print ("Fiasco - 0.1.0\n");
			return 0;
		}

		if (size < 1 ) {
			print ("Size must be positive (was: %d)\n", size);
			return 0;
		};

		/* get all files from directories */
		string[] files = {};
		foreach (var directory in directories) {
			var deep_files = list_files (directory, recursive);
			foreach (var df in deep_files) {
				files += df;
			}
		}
		var num_files = files.length;
		if (verbose) {
			message ("Found %u files", num_files);
		}

		var par = new ParArray<string> ();
		par.data = files;
		par.function = filter_images;
		par.dispatch ();

		/* print to a file if output was specified */
		unowned FileStream out_file = stdout;
		FileStream tmp;
		if (output != null) {
			tmp = FileStream.open (output, "w");
			out_file = tmp;
		}

		var num_imgs = 0;
		foreach (var f in files) {
			if (f != null) {
				out_file.printf (f + "\n");
				num_imgs++;
			}
		}

		stderr.printf ("Found %u images larger than %dx%d\n", num_imgs, size, size);

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

string[] list_files (string directory, bool recursive = false) {
	string[] files = {};
	string file_name;
	try {
		var dir = Dir.open (directory);
		while ((file_name = dir.read_name ()) != null) {
			var file_path = Path.build_filename (directory, file_name);
			if (recursive && FileUtils.test (file_path, FileTest.IS_DIR)) {
				var deep_files = list_files (file_path, recursive);
				foreach (var df in deep_files) {
					files += df;
				}
			} else {
				files += file_path;
			}
		}
		return files;
	} catch (FileError e) {
		error (e.message);
	}
}
