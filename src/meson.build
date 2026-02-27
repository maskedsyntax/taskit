taskit_sources = [
  'main.vala',
  'Application.vala',
  'Window.vala',
  'DatabaseManager.vala',
  'Models/Task.vala',
  'Models/Project.vala',
  'Widgets/TaskRow.vala',
  'Widgets/SidebarRow.vala',
  'Widgets/TaskDialog.vala'
]

taskit_deps = [
  dependency('gtk4'),
  dependency('libadwaita-1'),
  dependency('sqlite3'),
  dependency('gee-0.8')
]

executable('taskit', taskit_sources,
  dependencies: taskit_deps,
  install: true,
)