project('vparser', ['vala', 'c'])
gio = dependency('gio-2.0')
gpb = dependency('gdk-pixbuf-2.0')

deps = [gio, gpb]

parse_src = ['src/main.vala']
inc = include_directories('src')

wordspotter = executable('vparser',
    sources: parse_src,
    dependencies: deps,
    include_directories: inc,
    install: true)

