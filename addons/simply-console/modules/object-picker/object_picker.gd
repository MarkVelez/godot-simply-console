extends ConsoleModule
## Addon for the console window that let's you click on objects in a scene
## and get their reference.
##
## [b]Note:[/b] The object picker requires that the scene has an active camera.

## Emitted when an object is selected.
signal object_selected(ObjectRef: Node)

## Fixed scene type for the object picker.[br]
## This can be set to skip needing to determine the current scene type.
## Set to "Unknown" to ignore this.
@export_enum(
	"Unknown",
	"2D",
	"3D"
) var FIXED_SCENE_TYPE: String = "Unknown"

var CameraRef: Node

var SelectedRef: Node
var sceneType: String


func _module_init() -> void:
	Console.keywordList_["this"] = null


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not ConsoleRef.is_visible():
		return
	
	# Get reference of selected object when clicked on
	if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		match sceneType:
			"2D":
				SelectedRef = get_2d_object_reference()
			"3D":
				SelectedRef = get_3d_object_reference()
			_:
				return
		
		if SelectedRef:
			ConsoleRef.output_comment(
				"Selected Object: " + str(SelectedRef)
				+ "\nUse keyword 'this' to access reference."
			)
			Console.keywordList_["this"] = SelectedRef
			emit_signal("object_selected", SelectedRef)
		get_viewport().set_input_as_handled()


## Retrieves the active camera reference when the console window is made visible.
func on_console_toggled() -> void:
	super.on_console_toggled()
	if ConsoleRef.is_visible():
		var ViewportRef: Viewport = get_viewport()
		sceneType = get_scene_type(ViewportRef)
		
		match sceneType:
			"2D":
				CameraRef = ViewportRef.get_camera_2d()
			"3D":
				CameraRef = ViewportRef.get_camera_3d()
		
		if not CameraRef:
			ConsoleRef.output_error("Could not find active camera.")


## Determines the scene type based on the active camera type.
func get_scene_type(ViewportRef: Viewport) -> String:
	if FIXED_SCENE_TYPE != "Unknown":
		return FIXED_SCENE_TYPE
	
	if ViewportRef.get_camera_2d():
		return "2D"
	elif ViewportRef.get_camera_3d():
		return "3D"
	else:
		ConsoleRef.output_error("Could not determine scene type.")
		return ""


func get_2d_object_reference() -> Node2D:
	var mousePosition: Vector2 = CameraRef.get_global_mouse_position()
	var space = CameraRef.get_world_2d().direct_space_state

	var query = PhysicsPointQueryParameters2D.new()
	query.position = mousePosition

	var result = space.intersect_point(query, 1)

	if result.is_empty():
		return null

	return result[0]["collider"]


func get_3d_object_reference() -> Node3D:
	var mousePosition: Vector2 = get_viewport().get_mouse_position()
	var rayLength: float = 1000
	var from: Vector3 = CameraRef.project_ray_origin(mousePosition)
	var to: Vector3 =\
		from + CameraRef.project_ray_normal(mousePosition) * rayLength
		
	var space = CameraRef.get_world_3d().direct_space_state
	var rayQuery := PhysicsRayQueryParameters3D.new()
	rayQuery.from = from
	rayQuery.to = to
	
	var raycastResult_: Dictionary = space.intersect_ray(rayQuery)
	
	if raycastResult_.is_empty():
		return null
	
	return raycastResult_["collider"]
