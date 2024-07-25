@tool
extends Node

# GLOBAL = Singleton(Autorun)
# LOCAL = Scene Node
enum CommandType {
	GLOBAL,
	LOCAL
}

# Command list file location constants
const FILE: String = "command_list.json"
const DIRECTORY: String = "res://addons/simply-console/data/"
const PATH: String = DIRECTORY + FILE

var COMMAND_LIST_: Dictionary = {
	"help": {
		"target": "ConsoleDataManager",
		"type": CommandType.GLOBAL,
		"method": "show_command_list",
		"argumentList": [
			{
				"name": "command",
				"type": TYPE_STRING,
				"optional": true
			}
		]
	},
	"clear": {
		"target": "",
		"type": CommandType.LOCAL,
		"method": "clear_console",
		"argumentList": []
	},
}


func _ready() -> void:
	# Verify the directory
	DirAccess.make_dir_absolute(DIRECTORY)
	
	# Check if the command list file exists
	if FileAccess.file_exists(PATH):
		# Stop automatically loading data in the editor
		if not Engine.is_editor_hint():
			call_deferred("get_data")
	else:
		save_data()
		push_warning("No command list file found.")


func save_data() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	
	file.store_string(JSON.stringify(COMMAND_LIST_, "\t", false))
	file.close()


func get_data() -> void:
	var file := FileAccess.open(PATH, FileAccess.READ)
	COMMAND_LIST_ = JSON.parse_string(file.get_as_text())
	
	file.close()
	
	# Check for issues with parsing
	if COMMAND_LIST_ == null:
		push_error("Failed to parse command list file.")
		return


func show_command_list(commandName: String = "") -> String:
	var response: String = "List of available commands:\n"
	
	# Show list of commands
	if commandName == "":
		for command in COMMAND_LIST_:
			response += command + ", "
		
		return response.trim_suffix(", ")
	
	# Show list of arguments for command
	if COMMAND_LIST_.has(commandName):
		if COMMAND_LIST_[commandName]["argumentList"].is_empty():
			return "Command '" + commandName + "' does not have any arguments."
		
		response = "Argument(s) for '" + commandName + "':\n"
		for ARGUMENT_ in COMMAND_LIST_[commandName]["argumentList"]:
			response += ARGUMENT_["name"]
			if ARGUMENT_["optional"]:
				response += " (optional)"
			response += "\n"
		
		return response.trim_suffix("\n")
	
	return "Command '" + commandName + "' does not exist."
