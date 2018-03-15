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
public static string? export = null;
public static string out_dir = null;

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
		{ "dir", 'd', 0, OptionArg.FILENAME, ref out_dir, "The output directory where images will be exported (default: export)", "DIRECTORY" },
		{ "export", 'e', 0, OptionArg.STRING, ref export, "Export valid images to the specified format", "png,jpeg,bmp" },
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

		if (directories.length < 1) {
			print ("Please, specify at least one directory\n");
			return 0;
		}

		if (size < 1 ) {
			print ("Size must be positive (was: %d)\n", size);
			return 0;
		};

		if (0 > num_threads > get_num_processors()) {
			/* setting num_threads to 0, will make parallellise accross all cores */
			num_threads = 0;
		}

		/* prepare directory for valid images */
		out_dir = out_dir ?? "export";
		if (export != null && !fast) {
			try {
				var dir = File.new_for_commandline_arg (out_dir);
				dir.make_directory_with_parents ();
			} catch (Error e) {
				stdout.printf ("Error: %s\n", e.message);
			}
		} else {
			warning ("export option is ignored when running in fast mode.\n");
		}

		/* get all files from directories */
		string[] files = {};
		foreach (var directory in directories) {
			var inner_file = list_files (directory, recursive);
			foreach (var df in inner_file) {
				files += df;
			}
		}
		var num_files = files.length;
		if (verbose) {
			message ("Found %u files", num_files);
		}

		/* actually filter images */
		var par = new ParArray<string> ();
		par.data = files;
		par.function = filter_images;
		par.num_threads = num_threads;
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

		stderr.printf ("Found %u images larger than %dx%d in %u files\n", num_imgs, size, size, num_files);

		return 0;
	}
}

void filter_images (ParArray<string> p) {
	var file_path = p.data[p.index];
	try {
		int width, height;
		if (fast) {
			Gdk.Pixbuf.get_file_info (file_path, out width, out height);
			if (width < size || height < size) {
				p.data[p.index] = null;
			}
		} else {
			var img = new Gdk.Pixbuf.from_file (file_path);
			width = img.width;
			height = img.height;
			if (width < size || height < size) {
				p.data[p.index] = null;
			} else if (export != null) {
				var name = Path.get_basename (file_path);
				var dot_index = name.last_index_of_char ('.');
				stdout.printf ("%s\n", name[0:dot_index]);
				img.save(out_dir + Path.DIR_SEPARATOR_S + name[0:dot_index] + "." + export, export);
			}
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
				var inner_file = list_files (file_path, recursive);
				foreach (var df in inner_file) {
					files += df;
				}
			} else {
				files += file_path;
			}
		}
		return files;
	} catch (FileError e) {
		if (verbose) {
			warning (e.message);
		}
		return files;
	}
}
