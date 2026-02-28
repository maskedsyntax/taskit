taskit_sources = [
  'main.vala',
  'Application.vala',
  'Window.vala',
  'DatabaseManager.vala',
  'NotificationManager.vala',
  'Models/Task.vala',
  'Models/Project.vala',
  'Widgets/TaskRow.vala',
  'Widgets/SidebarRow.vala',
  'Widgets/TaskDialog.vala'
]

taskit_deps = [
  dependency('gtk4'),
  dependency('libadwaita-1'),
  dependency('granite-7'),
  dependency('sqlite3'),
  dependency('gee-0.8'),
  dependency('libnotify')
]

taskit_resources = gnome.compile_resources('taskit-resources',
  '../data/org.gnome.Taskit.gresource.xml',
  source_dir: '../data',
  c_name: 'taskit'
)

executable('taskit', taskit_sources + [taskit_resources],
  dependencies: taskit_deps,
  install: true,
)