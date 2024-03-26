@tool
extends EditorPlugin
const SELECTED_FILE_BG_COLOR = Color("3c4152")
const CONFIG_FILE_PATH = "res://addons/AI-Context-Generator/ai_context_generator_settings.cfg"
var window_scene = preload("res://addons/AI-Context-Generator/AiContextWindow.tscn")
var window_node
var ai_button
var total_file_size = 0
var config = ConfigFile.new()
var selected_files = {}

func _enter_tree():
	setup_window()
	setup_ai_button()

func _exit_tree():
	cleanup()

func setup_window():
	window_node = window_scene.instantiate()
	get_editor_interface().get_base_control().add_child(window_node)
	window_node.hide()
	
	window_node.connect("close_requested", _on_close_requested)
	window_node.get_node("%SendToClipboardButton").connect("pressed", _on_send_to_clipboard_button_pressed)
	window_node.get_node("%OpenWebsiteButton").connect("pressed", _on_open_website_button_pressed)
	window_node.get_node("%SelectAllButton").connect("pressed", _on_select_all_button_pressed)
	window_node.get_node("%DeselectAllButton").connect("pressed", _on_deselect_all_button_pressed)
	window_node.get_node("%FileTree").connect("item_mouse_selected", _on_tree_item_mouse_selected)
	window_node.get_node("%FileTypeLineEdit").connect("text_changed", _on_file_type_line_edit_text_changed)
	window_node.get_node("%FileTypeLineEdit").connect("text_submitted", _on_text_submitted)
	window_node.get_node("%FileTypeLineEdit").connect("focus_exited", _on_search_for_files)
	window_node.get_node("%ExcludeLineEdit").connect("text_changed", _on_exclude_line_edit_text_changed)
	window_node.get_node("%ExcludeLineEdit").connect("text_submitted", _on_text_submitted)
	window_node.get_node("%ExcludeLineEdit").connect("focus_exited", _on_search_for_files)
	window_node.get_node("%WebsiteLineEdit").connect("text_changed", _on_website_line_edit_text_changed)
	window_node.get_node("PanelContainer").connect("gui_input", _on_gui_input)
	
	window_node.size = (get_window().size * 0.5) + Vector2(0,13)

func setup_ai_button():
	ai_button = Button.new()
	ai_button.text = "AI"
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, ai_button)
	ai_button.connect("pressed", _on_ai_button_pressed)

func cleanup():
	if is_instance_valid(ai_button):
		ai_button.queue_free()
	if is_instance_valid(window_node):
		window_node.queue_free()
	total_file_size = 0

func _on_ai_button_pressed():
	window_node.popup_centered()
	load_settings()
	_on_search_for_files()

func load_settings():
	if config.load(CONFIG_FILE_PATH) == OK:
		window_node.get_node("%FileTypeLineEdit").text = config.get_value("Settings", "file_types", "")
		window_node.get_node("%ExcludeLineEdit").text = config.get_value("Settings", "excluded_directories", "")
		window_node.get_node("%WebsiteLineEdit").text = config.get_value("Settings", "website_url", "")
		selected_files = config.get_value("Settings", "selected_files", {})

func generate_file_list(file_tree, path):
	if FileAccess.file_exists(path + "/.gdignore"):
		return
	
	if window_node.get_node("%ExcludeLineEdit").text.length() > 0:
		if is_excluded_directory(path):
			return

	var file_types = window_node.get_node("%FileTypeLineEdit").text.replace(".", "").replace(",", " ").strip_edges().split(" ")
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				generate_file_list(file_tree, path + file_name + "/")
			elif file_name.get_extension() in file_types:
				var full_path = path + file_name
				var file_item = file_tree.create_item()
				file_item.set_text(0, '/' + full_path.trim_prefix("res://"))
				file_item.set_metadata(0, full_path)
				if selected_files.has(full_path):
					select_tree_item(file_item)
			file_name = dir.get_next()
		dir.list_dir_end()

func is_excluded_directory(path):
	var excluded_directories = window_node.get_node("%ExcludeLineEdit").text.replace(",", " ").strip_edges().split(" ")
	for excluded in excluded_directories:
		if '/'+excluded in path.strip_edges():
			return true
	return false


func _on_search_for_files():
	var file_tree = window_node.get_node("%FileTree")
	file_tree.clear()
	total_file_size = 0
	update_file_size_label()
	file_tree.create_item() # invisible root node
	generate_file_list(file_tree, "res://")
	update_selected_files(file_tree.get_root())

func update_selected_files(item):
	var currently_selected_files = get_selected_file_paths(item)
	for file_path in selected_files.keys():
		if currently_selected_files.has(file_path) == false:
			selected_files.erase(file_path)

func get_selected_file_paths(item):
	var selected_files = {}

	if item:
		if item.get_custom_bg_color(0) == SELECTED_FILE_BG_COLOR:
			var file_path = item.get_metadata(0)
			if file_path:
				selected_files[file_path] = true

		var child = item.get_first_child()
		if child:
			selected_files.merge(get_selected_file_paths(child))

		var next = item.get_next()
		if next:
			selected_files.merge(get_selected_file_paths(next))

	return selected_files

func _on_tree_item_mouse_selected(position, mouse_button_index):
	var tree = window_node.get_node("%FileTree")
	var item = tree.get_item_at_position(position)
	var column = tree.get_column_at_position(position)
	item.deselect(column)
	if item.get_custom_bg_color(0) != SELECTED_FILE_BG_COLOR:
		select_tree_item(item)
	else:
		deselect_tree_item(item)

func _on_open_website_button_pressed():
	OS.shell_open(window_node.get_node("%WebsiteLineEdit").text)

func _on_select_all_button_pressed():
	recursively_process_items(window_node.get_node("%FileTree").get_root(), select_tree_item)

func _on_deselect_all_button_pressed():
	recursively_process_items(window_node.get_node("%FileTree").get_root(), deselect_tree_item)

func recursively_process_items(item, process_func):
	process_func.call(item)
	var child = item.get_first_child()
	while child:
		recursively_process_items(child, process_func)
		child = child.get_next()

func select_tree_item(item):
	if item.get_custom_bg_color(0) != SELECTED_FILE_BG_COLOR:
		item.set_custom_bg_color(0, SELECTED_FILE_BG_COLOR)
		item.set_custom_color(0, Color.WHITE)
		var file_path = item.get_metadata(0)
		if file_path:
			selected_files[file_path] = true
			update_total_file_size(file_path, true)
		update_file_size_label()

func deselect_tree_item(item):
	if item.get_custom_bg_color(0) == SELECTED_FILE_BG_COLOR:
		item.set_custom_bg_color(0, Color.TRANSPARENT)
		item.set_custom_color(0, Color(0.8,0.8,0.8))
		var file_path = item.get_metadata(0)
		if file_path:
			selected_files.erase(file_path)
			update_total_file_size(file_path, false)
		update_file_size_label()

func update_total_file_size(file_path, add):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var file_size = file.get_length()
		total_file_size += file_size if add else -file_size
		file.close()

func _on_send_to_clipboard_button_pressed():
	var all_content = ""
	for file_path in selected_files.keys():
		var file_content = FileAccess.get_file_as_string(file_path)
		if file_content:
			all_content += "-------------------\n# File: " + file_path + "\n\n" + file_content + "\n"
	
	DisplayServer.clipboard_set(all_content)
	print("Content copied to clipboard.")

func update_file_size_label():
	window_node.get_node("%FileSizeLabel").text = str(total_file_size/4/1000) + "k Tokens (Estimated)"

func _on_close_requested():
	window_node.hide()
	save_settings()

func save_settings():
	config.set_value("Settings", "file_types", window_node.get_node("%FileTypeLineEdit").text)
	config.set_value("Settings", "excluded_directories", window_node.get_node("%ExcludeLineEdit").text)
	config.set_value("Settings", "website_url", window_node.get_node("%WebsiteLineEdit").text)
	config.set_value("Settings", "selected_files", selected_files)
	config.save(CONFIG_FILE_PATH)

func _on_file_type_line_edit_text_changed(new_text):
	save_settings()

func _on_exclude_line_edit_text_changed(new_text):
	save_settings()

func _on_website_line_edit_text_changed(new_text):
	save_settings()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var focused_control = window_node.gui_get_focus_owner()
		if focused_control and not focused_control.get_global_rect().has_point(event.global_position):
			focused_control.release_focus()

func _on_text_submitted(newtext):
	window_node.gui_get_focus_owner().release_focus()
	_on_search_for_files()
