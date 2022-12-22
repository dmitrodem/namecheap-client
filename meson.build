project('namecheap-client', ['c', 'vala'],
  version : '0.1',
  default_options : ['warning_level=3'])

dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
  dependency('libsoup-2.4'),
  dependency('libxml-2.0'),
  meson.get_compiler('vala').find_library('posix'),
  meson.get_compiler('vala').find_library('linux'),
]


executable('namecheap-client',
           'namecheap.vala',
           dependencies : dependencies,
           install : true)
