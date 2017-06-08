project('fiasco', ['vala', 'c'],
    version: '0.1.0',
    default_options: ['buildtype=release'])

glib = dependency('glib-2.0')
gobject= dependency('gobject-2.0')
gio = dependency('gio-2.0')
gpb = dependency('gdk-pixbuf-2.0')

optionguess = subproject('optionguess')
optionguess_dep = optionguess.get_variable('optionguess_dep')
parallel = subproject('parallel-vala')
parallel_dep = parallel.get_variable('parallel_dep')

deps = [gio, gpb, optionguess_dep, parallel_dep]

srcs = ['src/main.vala']

executable('fiasco',
    sources: srcs,
    dependencies: deps,
    install: true)

