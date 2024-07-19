extends Node

# Command list file location constants
const FILE: String = "command_list.json"
const DIRECTORY: String = "res://addons/simply-console/data/"
const PATH: String = DIRECTORY + FILE

var COMMAND_LIST_: Dictionary


func _ready() -> void:
	# Verify the directory
	DirAccess.make_dir_absolute(DIRECTORY)
	
	if FileAccess.file_exists(PATH):
		call_deferred("get_data")
	else:
		save_data()
		push_warning("No command list file found.")


func save_data() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	
	file.store_string(JSON.stringify(COMMAND_LIST_))
	file.close()


func get_data() -> void:
	var file := FileAccess.open(PATH, FileAccess.READ)
	COMMAND_LIST_ = JSON.parse_string(file.get_as_text())
	
	file.close()
	
	# Check for issues with parsing
	if COMMAND_LIST_ == null:
		push_error("Failed to parse command list file.")
		return
