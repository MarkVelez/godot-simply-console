extends PanelContainer

@export var SuggestionScene: PackedScene

# Object references
@onready var ConsoleWindowRef: Window = owner
@onready var ParserRef: CommandParser = ConsoleWindowRef.CommandParserRef
@onready var LexerRef: CommandLexer = ConsoleWindowRef.CommandLexerRef
@onready var SuggestionListRef: VBoxContainer = %SuggestionList
@onready var IndicatorRef: TextureRect = %OverflowIndicator
@onready var InputFieldRef: LineEdit = %InputField
@onready var ViewportRef: Viewport = get_viewport()

const MAX_SUGGESTIONS: int = 5

# Suggestion caches
var currentSuggestions_: Array[Dictionary]
var overflowSuggestions_: Array[Dictionary]
var processedText_: Dictionary = {}
var selectedIdx: int = MAX_SUGGESTIONS - 1

# Flags
var suggestionsDismissed: bool = false
var isMouseInside: bool = false


func _ready() -> void:
	# Populate suggestion list
	for i in range(MAX_SUGGESTIONS):
		var SuggestionRef: RichTextLabel = SuggestionScene.instantiate()
		SuggestionRef.set_name("Suggestion" + str(i))
		SuggestionRef.hide()
		SuggestionListRef.add_child(SuggestionRef)
		SuggestionRef.connect("mouse_entered", on_mouse_entered)
		SuggestionRef.connect("mouse_exited", on_mouse_exited)


## Used to hide the suggestion list.
func dismiss_suggestions() -> void:
	hide()
	currentSuggestions_.clear()
	overflowSuggestions_.clear()
	suggestionsDismissed = true
	selectedIdx = MAX_SUGGESTIONS - 1
	InputFieldRef.grab_focus()
	InputFieldRef.set_caret_column(InputFieldRef.text.length())
	for ChildRef in SuggestionListRef.get_children():
		ChildRef.clear()
		ChildRef.hide()


## Inserts the suggestion into the input field.
func insert_suggestion(suggestion: String) -> void:
	# Ignore arguments when copying
	var command: String = suggestion.substr(0, suggestion.find("("))
	InputFieldRef.set_text(command)
	on_input_field_text_changed(command)
	InputFieldRef.grab_focus()
	InputFieldRef.set_caret_column(InputFieldRef.text.length())


#region Flag toggling
func on_input_field_text_submitted(_text) -> void:
	suggestionsDismissed = false


func on_mouse_entered() -> void:
	isMouseInside = true


func on_mouse_exited() -> void:
	isMouseInside = false
#endregion


#region Suggestion handling
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	if event is InputEventMouseButton:
		# Hide the suggestion list when clicking away from it
		if not isMouseInside:
			dismiss_suggestions()
			ViewportRef.set_input_as_handled()
			return
		
		if ViewportRef.gui_get_focus_owner().get_parent().name != "SuggestionList":
			return
		
		# Check if a selected suggestion is clicked
		await get_tree().process_frame
		var FocusRef = ViewportRef.gui_get_focus_owner()
		
		if selectedIdx == FocusRef.get_index():
			insert_suggestion(
				FocusRef.get_parsed_text()
			)
			ViewportRef.set_input_as_handled()
			return
		
		selectedIdx = FocusRef.get_index()
	
	if not event is InputEventKey:
		return
	
	# Hide the suggestion list when esc is pressed
	if event.pressed and event.keycode == KEY_ESCAPE:
		dismiss_suggestions()
		ViewportRef.set_input_as_handled()
		return
	
	var FocusRef = ViewportRef.gui_get_focus_owner()
	# Fallback to prevent issues
	if not FocusRef:
		InputFieldRef.grab_focus()
		FocusRef = ViewportRef.gui_get_focus_owner()
	
	# Move upwards in the suggestion list when the up button is pressed
	if event.pressed and event.keycode == KEY_UP:
		# Start selecting if not selecting yet
		if FocusRef.get_parent().name != "SuggestionList":
			selectedIdx = currentSuggestions_.size() - 1
			SuggestionListRef.get_child(
				selectedIdx
			).grab_focus()
			ViewportRef.set_input_as_handled()
			return
		
		if overflowSuggestions_.is_empty() and selectedIdx == 0:
			ViewportRef.set_input_as_handled()
			return
		
		# Move along the current suggestions
		if selectedIdx > 0:
			SuggestionListRef.get_child(selectedIdx).release_focus()
			selectedIdx -= 1
			SuggestionListRef.get_child(selectedIdx).grab_focus()
			ViewportRef.set_input_as_handled()
			return
		
		# Move along the overflow suggestions
		overflowSuggestions_.push_front(currentSuggestions_.pop_back())
		currentSuggestions_.push_front(overflowSuggestions_.pop_back())
		update_all()
		ViewportRef.set_input_as_handled()
	
	# Move downwards in the suggestion list when the down button is pressed
	if event.pressed and event.keycode == KEY_DOWN:
		# Start selecting if not selecting yet
		if FocusRef.get_parent().name != "SuggestionList":
			selectedIdx = currentSuggestions_.size() - 1
			SuggestionListRef.get_child(
				selectedIdx
			).grab_focus()
			ViewportRef.set_input_as_handled()
			return
		
		if (
			overflowSuggestions_.is_empty()
			and selectedIdx == currentSuggestions_.size() - 1
		):
			ViewportRef.set_input_as_handled()
			return
		
		# Move along the current suggestions
		if selectedIdx < MAX_SUGGESTIONS - 1:
			SuggestionListRef.get_child(selectedIdx).release_focus()
			selectedIdx += 1
			SuggestionListRef.get_child(selectedIdx).grab_focus()
			ViewportRef.set_input_as_handled()
			return
		
		if overflowSuggestions_.is_empty():
			return
		
		# Move along the overflow suggestions
		overflowSuggestions_.push_back(currentSuggestions_.pop_front())
		currentSuggestions_.append(overflowSuggestions_.pop_front())
		update_all()
		ViewportRef.set_input_as_handled()
	
	# Check if the suggestions are currently being selected
	if FocusRef.get_parent().name == "SuggestionList":
		if (
			event.keycode != KEY_UP
			and event.keycode != KEY_DOWN
			and event.keycode != KEY_ENTER
		):
			InputFieldRef.grab_focus()
		
		# Select the suggestion and autocomplete when enter is pressed
		if event.pressed and event.keycode == KEY_ENTER:
			insert_suggestion(FocusRef.get_parsed_text())
			ViewportRef.set_input_as_handled()
			return


func on_input_field_text_changed(text: String) -> void:
	if text.is_empty():
		dismiss_suggestions()
		suggestionsDismissed = false
		return
	
	if suggestionsDismissed:
		return
	
	# Process input text
	processedText_ = LexerRef.process_input_text(text, true)
	var commandName: String = processedText_["command"]
	var keyword: String = processedText_["keyword"]
	
	# Handle command that is a valid keyword
	if (
		keyword.is_empty()
		and ConsoleDataManager.keywordList_.has(commandName)
	):
		processedText_["keyword"] = commandName
		keyword = commandName
		processedText_["command"] = ""
		commandName = ""
	
	# Handle keyword with no command
	if (
		not keyword.is_empty()
		and commandName.is_empty()
		and ConsoleDataManager.keywordList_.has(keyword)
	):
		var commandList_: Array[String] = get_target_commands(
			ConsoleDataManager.keywordList_[keyword]
		)
		for command in commandList_:
			if matching_command(command):
				continue
			add_suggestion(command, keyword)
	else:
		# Check for valid suggestions
		for command in ConsoleDataManager.COMMAND_LIST_:
			if matching_command(command):
				continue
			
			if command.begins_with(commandName):
				add_suggestion(command, keyword)
	
	if currentSuggestions_.is_empty():
		return
	
	# Filter our invalid overflow suggestions and then sort the overflow list
	overflowSuggestions_ =\
		overflowSuggestions_.filter(filter_suggestions)
	overflowSuggestions_.sort_custom(sort_suggestions)
	
	var invalidSuggestions_: Array[Dictionary] = []
	# Filter out invalid suggestions and replace them if there overflow ones
	for entry_ in currentSuggestions_:
		var SuggestionRef: RichTextLabel =\
			SuggestionListRef.get_child(currentSuggestions_.find(entry_))
		
		if not filter_suggestions(entry_):
			if not overflowSuggestions_.is_empty():
				var newCommand_: Dictionary = overflowSuggestions_.pop_back()
				currentSuggestions_[
					currentSuggestions_.find(entry_)
				] = newCommand_
			else:
				SuggestionRef.hide()
				invalidSuggestions_.append(entry_)
	
	# Remove invalid suggestions
	for command in invalidSuggestions_:
		currentSuggestions_.erase(command)
	
	if overflowSuggestions_.is_empty():
		IndicatorRef.hide()
	else:
		IndicatorRef.show()
	
	# Sort the visible suggestions and update the UI
	currentSuggestions_.sort_custom(sort_suggestions)
	update_all()


## Updates an individual suggestion in the suggestion list.
func update_suggestion(entry_: Dictionary) -> void:
	# Check suggestion list visibility
	if not is_visible_in_tree():
		for i in range(MAX_SUGGESTIONS):
			SuggestionListRef.get_child(i).release_focus()
		suggestionsDismissed = false
		show()
	
	var SuggestionRef: RichTextLabel =\
		SuggestionListRef.get_child(currentSuggestions_.find(entry_))
	SuggestionRef.show()
	SuggestionRef.clear()
	
	if not processedText_["keyword"].is_empty():
		SuggestionRef.push_color(Color.RED)
		SuggestionRef.append_text(processedText_["keyword"])
		SuggestionRef.pop()
		SuggestionRef.append_text(".")
	
	# Update command
	SuggestionRef.push_color(Color.YELLOW)
	SuggestionRef.append_text(processedText_["command"])
	SuggestionRef.pop()
	SuggestionRef.append_text(
		entry_["command"].substr(processedText_["command"].length())
	)
	
	# Check for arguments
	if entry_["args"].is_empty():
		return
	
	# Update arguments
	SuggestionRef.append_text("(")
	for i in range(entry_["args"].size()):
		if processedText_["arguments"].size() - 1 == i:
			SuggestionRef.push_bgcolor(Color(Color.WHITE, 0.1))
		
		var arg_: Dictionary = entry_["args"][i]
		SuggestionRef.append_text(
				"[color=PALE_TURQUOISE]"
				+ arg_["name"]
				+ "[/color]"
				+ ": [color=MEDIUM_SPRING_GREEN]"
				+ type_string(arg_["type"])
				+ "[/color]"
			)
		
		if arg_["default"] != null:
			var default: String = str(arg_["default"])
			if arg_["type"] == TYPE_STRING and arg_["default"].is_empty():
				default = "\"\""
			SuggestionRef.append_text(
				" = "
				+ "[color=SANDY_BROWN]"
				+ default
				+ "[/color]"
			)
		
		if processedText_["arguments"].size() - 1 == i:
			SuggestionRef.pop()
		
		if entry_["args"].find(arg_) != entry_["args"].size() - 1:
			SuggestionRef.append_text(", ")
	
	SuggestionRef.append_text(")")


## Updates all suggestions in the suggestion list.
func update_all() -> void:
	for i in range(MAX_SUGGESTIONS):
		if i < currentSuggestions_.size():
			update_suggestion(currentSuggestions_[i])
		else:
			SuggestionListRef.get_child(i).hide()


## Sorts the suggestions based on length in descending order
## then in descending alphanumerical order.
## This puts the most relevant suggestion to the bottom of the list.
func sort_suggestions(a_: Dictionary, b_: Dictionary) -> bool:
	var aCmd: String = a_["command"]
	var bCmd: String = b_["command"]
	if aCmd.length() != bCmd.length():
		return aCmd.length() > bCmd.length()
	return aCmd > bCmd


## Filters out invalid suggestions.
func filter_suggestions(entry_: Dictionary) -> bool:
	# Keyword with no command filtering
	if (
		not processedText_["keyword"].is_empty()
		and processedText_["command"].is_empty()
		and ConsoleDataManager.keywordList_.has(processedText_["keyword"])
	):
		return ConsoleDataManager.keywordList_[
				processedText_["keyword"]
			].has_method(entry_["command"])
	
	# Normal command filtering
	if entry_["command"].begins_with(processedText_["command"]):
		if (
			entry_["command"] != processedText_["command"]
			and not processedText_["arguments"].is_empty()
		):
			return false
		
		if processedText_["arguments"].size() > entry_["args"].size():
			return false
		
		return true
	
	return false


## Checks if a command is already suggested.
func matching_command(command: String) -> bool:
	for entry in currentSuggestions_:
		if entry["command"] == command:
			return true
		
	for entry in overflowSuggestions_:
		if entry["command"] == command:
			return true
	
	return false


## Returns an array of all the commands that are associated with the target.
func get_target_commands(TargetRef: Node) -> Array[String]:
	var commandList_: Array[String] = []
	if not TargetRef:
		return commandList_
	
	for command in ConsoleDataManager.COMMAND_LIST_:
		var method: String =\
			ConsoleDataManager.COMMAND_LIST_[command]["method"]
		if TargetRef.has_method(method):
			commandList_.append(command)
	
	return commandList_


## Adds the provided command to the appropriate suggestions array.
func add_suggestion(command: String, keyword: String) -> void:
	var TargetRef: Node = ParserRef.get_command_target(command, keyword)
	if not TargetRef:
		return
	
	var method: String = ConsoleDataManager.COMMAND_LIST_[command]["method"]
	if not TargetRef.has_method(method):
		return
	
	var args: Array[Dictionary] =\
		ParserRef.get_method_arguments(
			TargetRef,
			method
		)
	
	if currentSuggestions_.size() < MAX_SUGGESTIONS:
		currentSuggestions_.append({
			"command": command,
			"args": args
		})
	else:
		overflowSuggestions_.append({
			"command": command,
			"args": args
		})
#endregion
