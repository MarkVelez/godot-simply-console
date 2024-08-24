extends Window

## Permissions for executing commands.
@export var permissionLevel: ConsoleDataManager.PermissionLevel = 0
## Whether the user has access to cheats.
@export var cheatsEnabled: bool = false

# Console node references.
@onready var OutputFieldRef: RichTextLabel = %OutputField
@onready var InputFieldRef: LineEdit = %InputField
@onready var CommandParserRef: CommandParser = $CommandParser
@onready var CommandLexerRef: CommandLexer = $CommandLexer
@onready var SuggestionsRef: PanelContainer = %CommandSuggestions

# Response limits
const MAX_RESPONSES: int = 256
const MAX_CHAR_COUNT: int = 8192

# Command history limit
const MAX_COMMAND_HISTORY: int = 16

# Command history variables
var commandHistory_: PackedStringArray
var historyPosition: int = 0


func _ready() -> void:
	output_comment(
		"To see a list of available commands use the 'help' command."
	)
	output_comment(
		"Optionally, use 'help (command)' to get more information about a specific command."
	)


func on_close_requested() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if (
		SuggestionsRef.is_visible_in_tree()
		or commandHistory_.is_empty()
		or not event is InputEventKey
	):
		return
	
	# Move up in command history
	if event.pressed and event.keycode == KEY_UP:
		if historyPosition < commandHistory_.size() - 1:
			historyPosition += 1
		InputFieldRef.set_text(commandHistory_[historyPosition])
		InputFieldRef.set_caret_column(
			commandHistory_[historyPosition].length()
		)
		set_input_as_handled()
	
	# Move down in command history
	if event.pressed and event.keycode == KEY_DOWN:
		if historyPosition > 0:
			historyPosition -= 1
		InputFieldRef.set_text(commandHistory_[historyPosition])
		InputFieldRef.set_caret_column(
			commandHistory_[historyPosition].length()
		)
		set_input_as_handled()


func on_output_field_updated() -> void:
	# Cap the amount of responses to not bloat memory
	if (
		OutputFieldRef.get_paragraph_count() > MAX_RESPONSES
		or OutputFieldRef.get_total_character_count() > MAX_CHAR_COUNT
	):
		# Compatibility for 4.2
		if Engine.get_version_info().hex >= 0x040300:
			OutputFieldRef.call("remove_paragraph", 0, true)
		else:
			OutputFieldRef.call_deferred("remove_paragraph", 1)


func on_input_field_text_submitted(text: String) -> void:
	if text == "":
		return
	
	InputFieldRef.clear()
	# Escape bbcode tags to avoid possible issues
	text = escape_bbcode(text)
	update_command_history(text)
	
	# Separate the command name and the arguments
	var processedText_: PackedStringArray =\
		CommandLexerRef.process_input_text(text)
	var command: String = processedText_[0]
	processedText_.remove_at(0)
	
	var response: String =\
		CommandParserRef.parse_command(
			command,
			processedText_,
			permissionLevel,
			cheatsEnabled
		)
	
	if not response.is_empty():
		output_text(response)


func escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")


func update_command_history(text: String) -> void:
	# Remove duplicate command history entry
	if commandHistory_.has(text):
		commandHistory_.remove_at(commandHistory_.find(text))
	
	commandHistory_.append(text)
	# Cap command history size
	if commandHistory_.size() > MAX_COMMAND_HISTORY:
		commandHistory_.remove_at(0)
	
	historyPosition = commandHistory_.size() - 1


#region Print methods
func output_text(text: String, color := Color.WHITE) -> void:
	OutputFieldRef.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
	
	if color != Color.WHITE: 
		OutputFieldRef.push_color(color)
	
	OutputFieldRef.append_text(text)
	OutputFieldRef.pop_all()


func output_warning(text: String) -> void:
	output_text(text, Color.YELLOW)


func output_error(text: String) -> void:
	output_text(text, Color.RED)


func output_comment(text: String) -> void:
	output_text(text, Color.DARK_GRAY)
#endregion


#region Console Commands
func show_command_list(commandName: String = "") -> String:
	var response: String = "List of available commands:\n"
	var COMMAND_LIST_: Dictionary = ConsoleDataManager.COMMAND_LIST_
	
	# Show list of commands
	if commandName == "":
		for command in COMMAND_LIST_:
			# Only show accessible commands
			if (
				permissionLevel >= COMMAND_LIST_[command]["minPermission"]
				and int(cheatsEnabled) >= int(COMMAND_LIST_[command]["cheats"])
			):
				response += command + ", "
		
		return response.trim_suffix(", ")
	
	# Check permission level requirement
	if permissionLevel < COMMAND_LIST_[commandName]["minPermission"]:
		return "Permission level too low for command '" + commandName + "'."
	
	# Check cheats requirement
	if cheatsEnabled < COMMAND_LIST_[commandName]["cheats"]:
		return "Cheats are required for command '" + commandName + "'."
	
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


func clear_console() -> void:
	OutputFieldRef.clear()


func toggle_cheats(state: bool = cheatsEnabled) -> String:
	if state == cheatsEnabled:
		return "Cheats are currently " + ("enabled." if state else "disabled.")
	
	cheatsEnabled = state
	return "Cheats have been " + ("enabled." if state else "disabled.")
#endregion
