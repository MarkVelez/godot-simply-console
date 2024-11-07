extends Window

## Permissions for executing commands.
@export var permissionLevel: Console.PermissionLevel = 0
## Whether the user has access to cheats.
@export var cheatsEnabled: bool = false
## List of modules that will be added to the console.
@export var moduleList_: Array[PackedScene] = []

# Console node references.
@onready var OutputFieldRef: RichTextLabel = %OutputField
@onready var InputFieldRef: LineEdit = %InputField
@onready var SuggestionsRef: PanelContainer = %CommandSuggestions

# Response limits
const MAX_RESPONSES: int = 256
const MAX_CHAR_COUNT: int = 8192

# Command history limit
const MAX_COMMAND_HISTORY: int = 16

# Command processor references
var CommandParserRef: CommandParser
var CommandLexerRef: CommandLexer

# Command history variables
var commandHistory_: PackedStringArray
var historyPosition: int = 0


func _enter_tree() -> void:
	if not Console.ConsoleRef:
		Console.ConsoleRef = self
	else:
		assert(false, "Duplicate console window found.")
	
	CommandParserRef = CommandParser.new()
	add_child(CommandParserRef)
	CommandParserRef.set_owner(self)
	
	CommandLexerRef = CommandLexer.new()
	add_child(CommandLexerRef)
	CommandLexerRef.set_owner(self)
	
	add_modules()


func _ready() -> void:
	set_visible(false)
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
		if historyPosition > 0:
			historyPosition -= 1
		InputFieldRef.set_text(commandHistory_[historyPosition])
		InputFieldRef.set_caret_column(
			commandHistory_[historyPosition].length()
		)
		set_input_as_handled()
	
	# Move down in command history
	if event.pressed and event.keycode == KEY_DOWN:
		if historyPosition == commandHistory_.size():
			historyPosition -= 1
		
		if historyPosition < commandHistory_.size() - 1:
			historyPosition += 1
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
	
	# Process input text
	var processedText_: Dictionary =\
		CommandLexerRef.process_input_text(text)
	var response: String =\
		CommandParserRef.parse_command(
			processedText_["command"],
			processedText_["arguments"],
			processedText_["keyword"],
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
	
	historyPosition = commandHistory_.size()


func add_modules() -> void:
	if moduleList_.is_empty():
		return
	
	# Create module list
	var ModuleListRef := Control.new()
	ModuleListRef.set_name("ModuleList")
	Console.add_child(ModuleListRef)
	ModuleListRef.set_owner(Console)
	ModuleListRef.set_anchors_preset(Control.PRESET_FULL_RECT)
	ModuleListRef.set_mouse_filter(Control.MOUSE_FILTER_PASS)
	
	# Add modules
	for module in moduleList_:
		if not module:
			push_warning(
				"Null reference found in module list at index "
				+ str(moduleList_.find(module))
			)
			continue
		
		var ModuleRef: Node = module.instantiate()
		if not ModuleRef is ConsoleModule:
			push_warning("Invalid console module found: " + ModuleRef.get_name())
			continue
		
		ModuleListRef.add_child(ModuleRef)
		ModuleRef.set_owner(ModuleListRef)
		ModuleRef.set_visible(false)
		ModuleRef.set_process_mode(Node.PROCESS_MODE_DISABLED)
		Console.moduleList_[ModuleRef.name] = ModuleRef
		ModuleRef.call_deferred("_module_init")


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
func show_command_list(filter: String = "") -> String:
	var response: String = "List of available commands:\n"
	var COMMAND_LIST_: Dictionary = Console.COMMAND_LIST_
	var keywordList_: Dictionary = Console.keywordList_
	var isKeywordFilter: bool = keywordList_.has(filter)
	
	# Show list of commands
	if filter == "" or isKeywordFilter:
		var commandList_: Array = COMMAND_LIST_.keys()
		# Check if filter is a keyword
		if isKeywordFilter:
			if not keywordList_[filter]:
				return "Keyword '" + filter + "' holds no reference."
			
			response = (
				"List of available commands for '"
				+ keywordList_[filter].get_name()
				+ "':\n"
			)
			commandList_ =\
				SuggestionsRef.get_target_commands(keywordList_[filter])
		
		for command in commandList_:
			var commandInfo_: Dictionary = COMMAND_LIST_[command]
			# Only show accessible commands
			if (
				permissionLevel < commandInfo_["minPermission"]
				or cheatsEnabled < commandInfo_["cheats"]
				or not isKeywordFilter
				and commandInfo_["requiresKeyword"]
			):
				continue
			
			response += command + ", "
		
		return response.trim_suffix(", ")
	
	# Check if filter command exists
	if not COMMAND_LIST_.has(filter):
		return "Command '" + filter + "' does not exist."
	
	# Check permission level requirement
	if permissionLevel < COMMAND_LIST_[filter]["minPermission"]:
		return "Permission level too low for command '" + filter + "'."
	
	# Check cheats requirement
	if cheatsEnabled < COMMAND_LIST_[filter]["cheats"]:
		return "Cheats are required for command '" + filter + "'."
	
	# Check for keyword
	var keyword: String = ""
	if filter.contains("."):
		keyword = filter.substr(0, filter.find("."))
		filter = filter.substr(keyword.length() + 1)
	
	# Show list of arguments for command
	var TargetRef: Node =\
		CommandParserRef.get_command_target(filter, keyword)
	if not TargetRef:
		if COMMAND_LIST_[filter]["requiresKeyword"]:
			return "Command '" + filter + "' requires a keyword."
		
		return "Target for '" + filter + "' could not be found."
	
	var argList_: Array[Dictionary] =\
		CommandParserRef.get_method_arguments(
			TargetRef,
			COMMAND_LIST_[filter]["method"]
		)
	if argList_.is_empty():
		return "Command '" + filter + "' does not have any arguments."
	
	response = "Argument(s) for '" + filter + "':\n"
	for arg_ in argList_:
		response += (
			"[color=PALE_TURQUOISE]"
			+ arg_["name"]
			+ "[/color]"
			+ ": [color=MEDIUM_SPRING_GREEN]"
			+ type_string(arg_["type"])
			+ "[/color]"
		)
		
		if arg_.has("default"):
			var default: String = str(arg_["default"])
			if arg_["type"] == TYPE_STRING and arg_["default"].is_empty():
				default = "\"\""
			response += (
				" = "
				+ "[color=SANDY_BROWN]"
				+ default
				+ "[/color]"
			)
		
		response += "\n"
	
	return response.trim_suffix("\n")


func clear_console() -> void:
	OutputFieldRef.clear()


func toggle_cheats(state: bool) -> String:
	if state == cheatsEnabled:
		return "Cheats are currently " + ("enabled." if state else "disabled.")
	
	cheatsEnabled = state
	return "Cheats have been " + ("enabled." if state else "disabled.")
#endregion
