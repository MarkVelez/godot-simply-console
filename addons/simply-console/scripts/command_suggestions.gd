extends PanelContainer

@export var SuggestionScene: PackedScene

# Object references
@onready var ConsoleWindowRef: Window = owner
@onready var SuggestionListRef: VBoxContainer = %SuggestionList
@onready var IndicatorRef: TextureRect = %OverflowIndicator
@onready var InputFieldRef: LineEdit = %InputField
@onready var ViewportRef: Viewport = get_viewport()

const MAX_SUGGESTIONS: int = 5

# Suggestion caches
var currentSuggestions_: Array[String]
var overflowSuggestions_: Array[String]

var selectedIdx: int = MAX_SUGGESTIONS - 1

# Flags
var suggestionsDismissed: bool = false
var isMouseInside: bool = false


func _ready() -> void:
	# Populate suggestion list
	for i in range(0, MAX_SUGGESTIONS):
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
func insert_suggestion(suggestion) -> void:
	InputFieldRef.set_text(suggestion)
	dismiss_suggestions()


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
	
	# Move upwards in the suggestion list when the up button is pressed
	if event.pressed and event.keycode == KEY_UP:
		# Start selecting if not selecting yet
		if FocusRef.get_parent().name != "SuggestionList":
			SuggestionListRef.get_child(
				currentSuggestions_.size() - 1
			).grab_focus()
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
		update_all(InputFieldRef.get_text())
		ViewportRef.set_input_as_handled()
	
	# Move downwards in the suggestion list when the down button is pressed
	if event.pressed and event.keycode == KEY_DOWN:
		# Start selecting if not selecting yet
		if FocusRef.get_parent().name != "SuggestionList":
			SuggestionListRef.get_child(
				currentSuggestions_.size() - 1
			).grab_focus()
			ViewportRef.set_input_as_handled()
			return
		
		# Move along the current suggestions
		if selectedIdx < MAX_SUGGESTIONS - 1:
			SuggestionListRef.get_child(selectedIdx).release_focus()
			selectedIdx += 1
			SuggestionListRef.get_child(selectedIdx).grab_focus()
			ViewportRef.set_input_as_handled()
			return
		
		# Move along the overflow suggestions
		overflowSuggestions_.push_back(currentSuggestions_.pop_front())
		currentSuggestions_.append(overflowSuggestions_.pop_front())
		update_all(InputFieldRef.get_text())
		ViewportRef.set_input_as_handled()


func on_input_field_text_changed(text: String) -> void:
	if text.is_empty():
		dismiss_suggestions()
		suggestionsDismissed = false
		return
	
	if suggestionsDismissed:
		return
	
	# Check for valid suggestions
	for command in ConsoleDataManager.COMMAND_LIST_:
		if command in currentSuggestions_ or command in overflowSuggestions_:
			continue
		
		if command.begins_with(text):
			if currentSuggestions_.size() < MAX_SUGGESTIONS:
				currentSuggestions_.append(command)
			else:
				overflowSuggestions_.append(command)
	
	if currentSuggestions_.is_empty():
		return
	
	# Filter our invalid overflow suggestions and then sort the overflow list
	overflowSuggestions_ =\
		overflowSuggestions_.filter(filter_suggestions.bind(text))
	overflowSuggestions_.sort_custom(sort_suggestions)
	
	var invalidSuggestions_: PackedStringArray = []
	# Filter out invalid suggestions and replace them if there overflow ones
	for command in currentSuggestions_:
		var SuggestionRef: RichTextLabel =\
			SuggestionListRef.get_child(currentSuggestions_.find(command))
		if not command.begins_with(text):
			if not overflowSuggestions_.is_empty():
				var newCommand: String = overflowSuggestions_.pop_back()
				currentSuggestions_[
					currentSuggestions_.find(command)
				] = newCommand
			else:
				SuggestionRef.hide()
				invalidSuggestions_.append(command)
	
	# Remove invalid suggestions
	for command in invalidSuggestions_:
		currentSuggestions_.erase(command)
	
	if overflowSuggestions_.is_empty():
		IndicatorRef.hide()
	else:
		IndicatorRef.show()
	
	# Sort the visible suggestions and update the UI
	currentSuggestions_.sort_custom(sort_suggestions)
	update_all(text)


## Updates an individual suggestion in the suggestion list.
func update_suggestion(command: String, text: String) -> void:
	# Check suggestion list visibility
	if not is_visible_in_tree():
		for i in range(MAX_SUGGESTIONS):
			SuggestionListRef.get_child(i).release_focus()
		suggestionsDismissed = false
		show()
	
	# Update command
	var SuggestionRef: RichTextLabel =\
		SuggestionListRef.get_child(currentSuggestions_.find(command))
	SuggestionRef.show()
	SuggestionRef.clear()
	SuggestionRef.push_color(Color.YELLOW)
	SuggestionRef.append_text(text)
	SuggestionRef.pop()
	SuggestionRef.append_text(command.substr(text.length()))
	
	# Update arguments
	var argumentList_: Array =\
		ConsoleDataManager.COMMAND_LIST_[command]["argumentList"]
	if argumentList_.is_empty():
		return
	
	for argument in argumentList_:
		SuggestionRef.push_color(Color.DARK_GRAY)
		SuggestionRef.append_text(" <" + argument["name"] + ">")
		SuggestionRef.pop()


## Updates all suggestions in the suggestion list.
func update_all(text: String) -> void:
	for i in range(MAX_SUGGESTIONS):
		if i < currentSuggestions_.size():
			update_suggestion(currentSuggestions_[i], text)
		else:
			SuggestionListRef.get_child(i).hide()


## Sorts the suggestions based on length in descending order
## then in descending alphanumerical order.
## This puts the most relevant suggestion to the bottom of the list.
func sort_suggestions(a: String, b: String) -> bool:
	if a.length() != b.length():
		return a.length() > b.length()
	return a > b


## Filters out invalid suggestions.
func filter_suggestions(command: String, text: String) -> bool:
	return command.begins_with(text)
#endregion
