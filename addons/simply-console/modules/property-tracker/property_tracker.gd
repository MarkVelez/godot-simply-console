extends ConsoleModule

@onready var ObjectNameRef: Label = %Object
@onready var PropertyListRef: VBoxContainer = %PropertyList
@onready var PagesRef: VBoxContainer = %Pages
@onready var PageNumberRef: Label = %PageNumber
@onready var PrevPageRef: Button = %PreviousPage
@onready var NextPageRef: Button = %NextPage

const PROPERTIES_PER_PAGE: int = 5

var TrackedObjectRef: Node = null
var propertyList_: PackedStringArray = []
var trackedProperties_: Dictionary = {}
var isEnabled: bool = false
var isPersistent: bool = true

var lastPage: int = 0
var currentPage: int = 0 :
	set(value):
		currentPage = wrapi(value, 0, lastPage)
		change_page()

var isDragging: bool = false
var dragOffset := Vector2.ZERO


func _module_init() -> void:
	if Console.moduleList_.has("ObjectPicker"):
		Console.moduleList_["ObjectPicker"].connect(
			"object_selected",
			on_object_selected
		)
	
	ObjectNameRef.connect(
		"gui_input",
		func(event: InputEvent):
			if not event is InputEventMouseButton: return
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.is_double_click():
					set_position(Vector2.ZERO)
					dragOffset = Vector2.ZERO
					return
				isDragging = event.is_pressed()
				dragOffset = get_global_mouse_position() - global_position
	)
	PrevPageRef.connect("pressed", func(): currentPage -= 1)
	NextPageRef.connect("pressed", func(): currentPage += 1)
	
	Console.COMMAND_LIST_["property_tracker"] = {
		"target": "PropertyTracker",
		"minPermission": Console.PermissionLevel.NONE,
		"cheats": false,
		"requiresKeyword": false,
		"method": "toggle_module"
	}


func on_console_toggled() -> void:
	if isPersistent:
		return
	elif isEnabled:
		super.on_console_toggled()


func toggle_module(persistent: bool = true, ObjectRef: Node = null) -> void:
	if ObjectRef:
		on_object_selected(ObjectRef)
		if isEnabled:
			isPersistent = persistent
			return
	
	if isEnabled and isPersistent != persistent:
		isPersistent = persistent
		return
	
	set_visible(!is_visible())
	isEnabled = !isEnabled
	if isEnabled:
		set_process_mode(Node.PROCESS_MODE_DISABLED)
	else:
		set_process_mode(Node.PROCESS_MODE_INHERIT)


func on_object_selected(ObjectRef: Node) -> void:
	# Reset property list
	propertyList_.clear()
	clear_tracked_properties()
	currentPage = 0
	lastPage = 0
	
	# Update object name label
	TrackedObjectRef = ObjectRef
	if not ObjectRef:
		ObjectNameRef.set_text("<null>")
		return
	else:
		ObjectNameRef.set_text(TrackedObjectRef.name)
	
	# Update property list
	get_object_properties()
	for i in range(mini(propertyList_.size(), PROPERTIES_PER_PAGE)):
		add_property_label(propertyList_[i])
	
	# Update page section
	if propertyList_.size() > PROPERTIES_PER_PAGE:
		lastPage = ceili(propertyList_.size() / float(PROPERTIES_PER_PAGE))
		PageNumberRef.set_text(
			str(currentPage + 1)
			+ "/"
			+ str(lastPage)
		)
		PagesRef.set_visible(true)
	else:
		PagesRef.set_visible(false)


func clear_tracked_properties() -> void:
	trackedProperties_.clear()
	for PropertyRef in PropertyListRef.get_children():
		PropertyRef.queue_free()


func add_property_label(propertyName: String) -> void:
	var PropertyRef := HBoxContainer.new()
	PropertyRef.set_name(propertyName)
	
	var NameRef := Label.new()
	NameRef.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	NameRef.set_text(propertyName + ": ")
	PropertyRef.add_child(NameRef)
	
	var ValueRef := Label.new()
	ValueRef.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_RIGHT)
	ValueRef.set_text(str(TrackedObjectRef.get(propertyName)))
	trackedProperties_[propertyName] = ValueRef
	PropertyRef.add_child(ValueRef)
	
	PropertyListRef.add_child(PropertyRef)


func get_object_properties() -> void:
	for property_ in TrackedObjectRef.get_property_list():
		if property_["usage"] == PropertyUsageFlags.PROPERTY_USAGE_SCRIPT_VARIABLE:
			propertyList_.append(property_["name"])


func change_page() -> void:
	clear_tracked_properties()
	
	var from: int = currentPage * PROPERTIES_PER_PAGE
	var to: int =\
		mini((currentPage + 1) * PROPERTIES_PER_PAGE, propertyList_.size())
	for i in range(from, to):
		add_property_label(propertyList_[i])
	
	PageNumberRef.set_text(
		str(currentPage + 1)
		+ "/"
		+ str(lastPage)
	)


func _process(_delta) -> void:
	# Update property values
	for property in trackedProperties_:
		trackedProperties_[property].text = str(TrackedObjectRef.get(property))
	
	if isDragging:
		position = get_global_mouse_position() - dragOffset
