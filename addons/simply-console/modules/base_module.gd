extends Control
class_name ConsoleModule

## Reference to the console window.
@onready var ConsoleRef: Window = Console.ConsoleRef


func _ready() -> void:
	set_visible(ConsoleRef.visible)
	ConsoleRef.connect("visibility_changed", on_console_toggled)


## Called when the module gets added to the console.
## Prefer using this over '_ready', '_enter_tree' and '_init'
## to avoid possible loading issues.
func _module_init() -> void:
	pass


## Called when the console's visibility is toggled.
## Can be overwritten if needed.
func on_console_toggled() -> void:
	if ConsoleRef.is_visible():
		set_visible(true)
		set_process_mode(Node.PROCESS_MODE_INHERIT)
	else:
		set_visible(false)
		set_process_mode(Node.PROCESS_MODE_DISABLED)
