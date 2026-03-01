desktop_file = i18n.merge_file(
  input: 'org.gnome.Taskit.desktop.in',
  output: 'org.gnome.Taskit.desktop',
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data('icons/hicolor/256x256/apps/org.gnome.Taskit.png',
  install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', '256x256', 'apps')
)
