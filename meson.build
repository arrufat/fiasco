project('vparser', ['vala', 'c'],
    version: '0.1.0',
    default_options: ['buildtype=release'])

glib = dependency('glib-2.0')
gobject= dependency('gobject-2.0')
gio = dependency('gio-2.0')
gpb = dependency('gdk-pixbuf-2.0')

optionguess = subproject('optionguess')
optionguess_dep = optionguess.get_variable('optionguess_dep')

deps = [gio, gpb, optionguess_dep]

parse_src = ['src/main.vala']

vparser = executable('vparser',
    sources: parse_src,
    dependencies: deps,
    install: true)

