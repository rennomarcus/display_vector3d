@tool
extends Node3D
class_name DisplayVector3D


## ---------- Exports ----------
@export var source_node_path: NodePath = ^".."
@export var source_property: StringName = &"velocity"

@export_range(0.0, 1000.0, 0.001) var length_scale: float = 0.1

@export var color: Color = Color(1, 0, 0, 1.0) : set = _set_color
@export_range(0.0, 1.0, 0.01) var opacity: float = 0.85 : set = _set_opacity
@export_range(0.001, 1.0, 0.001) var thickness: float = 0.03
@export_range(0.01, 1.0, 0.01) var head_fraction: float = 0.15
@export_range(0.0, 100.0, 0.001) var min_display_length: float = 0.01

@export var toggle_action: StringName = &"debug"
@export var auto_add_action_if_missing: bool = true
@export var default_toggle_key: int = KEY_V
@export var start_visible: bool = true

@export var vector_is_world_space: bool = true

@export var offset_position: Vector3 = Vector3.ZERO

## ---------- Internals ----------
var _source: Node
var _shaft: MeshInstance3D
var _head: MeshInstance3D
var _mat: StandardMaterial3D
var _arrow_root: Node3D

func _enter_tree() -> void:
	_setup_action()
	visible = start_visible

func _ready() -> void:
	_find_source()
	_build_mesh()
	_update_material()

func _process(_dt: float) -> void:
	_handle_toggle()
	_draw_vector()

## ---------- Setup helpers ----------
func _find_source() -> void:
	_source = get_node_or_null(source_node_path)
	if _source == null:
		_source = get_parent()

func _build_mesh() -> void:
	_arrow_root = Node3D.new()
	add_child(_arrow_root, true)

	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.no_depth_test = false
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.disable_receive_shadows = true

	# Shaft: Cylinder oriented +Y by default → rotate X +90° to align along +Z
	_shaft = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = 1.0
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.radial_segments = 16
	_shaft.mesh = cyl
	_shaft.material_override = _mat
	_shaft.rotation_degrees.x = 90.0
	_arrow_root.add_child(_shaft, true)

	# Head: make a cone via CylinderMesh with top_radius = 0.0
	_head = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.height = 1.0
	cone.top_radius = 0.0      # <- cone tip
	cone.bottom_radius = 0.75  # <- cone base
	cone.radial_segments = 20
	_head.mesh = cone
	_head.material_override = _mat
	_head.rotation_degrees.x = 90.0
	_arrow_root.add_child(_head, true)

	_update_material()

func _update_material() -> void:
	var c := color
	c.a = opacity
	_mat.albedo_color = c

## ---------- Input / Toggle ----------
func _setup_action() -> void:
	if String(toggle_action).is_empty():
		return
	if !InputMap.has_action(toggle_action) and auto_add_action_if_missing:
		InputMap.add_action(toggle_action)
		var ev := InputEventKey.new()
		ev.physical_keycode = default_toggle_key
		InputMap.action_add_event(toggle_action, ev)

func _handle_toggle() -> void:
	if String(toggle_action).is_empty():
		return
	if Input.is_action_just_pressed(toggle_action):
		visible = !visible

## ---------- Main draw ----------
func _draw_vector() -> void:
	if !_source:
		return

	var v := Vector3.ZERO
	var ok := false

	# Check if the source has a property named source_property
	if _has_property(_source, source_property):
		var any_val = _source.get(source_property)
		if typeof(any_val) == TYPE_VECTOR3:
			v = any_val
			ok = true
	
	# Fallback: if a method with that name returns Vector3, use it
	if !ok and _source.has_method(String(source_property)):
		var ret = _source.call(String(source_property))
		if typeof(ret) == TYPE_VECTOR3:
			v = ret
			ok = true
		
	
	if !ok:
		_arrow_root.visible = false
		return

	var world_v := v
	if !vector_is_world_space and _source is Node3D:
		world_v = (_source as Node3D).global_transform.basis * v
	
	var len := world_v.length() * length_scale
	if len < min_display_length:
		_arrow_root.visible = false
		return

	_arrow_root.visible = true

	# Anchor arrow at the source origin
	if _source is Node3D:
		global_transform.origin = (_source as Node3D).global_transform.origin
	
	# Orient the arrow so +Z matches the vector direction
	var dir := world_v.normalized()
	if dir.is_equal_approx(Vector3.ZERO):
		_arrow_root.visible = false
		return

	_arrow_root.visible = true
	_arrow_root.position = offset_position
	_arrow_root.transform.basis = Basis.looking_at(-dir, Vector3.UP)  # +Z -> dir

	# Split length into shaft + head
	var head_len := clampf(len * head_fraction, 0.05, maxf(len * 0.5, 0.05))
	var shaft_len := maxf(len - head_len, 0.0)

	# Thickness scaling (base radius on CylinderMesh is 0.5 → multiply by 2)
	var radius_scale := thickness * 2.0

	# Meshes were created with rotation X=+90° (height along +Z). Keep ALL scales positive.
	_shaft.visible = shaft_len > 0.0
	_head.rotation_degrees.x = 90.0
	if _shaft.visible:
		_shaft.scale = Vector3(radius_scale, shaft_len, radius_scale)      # length on Y (height), ends up along +Z
		_shaft.position = Vector3(0, 0, shaft_len * 0.5)                   # center on +Z

	_head.scale = Vector3(radius_scale * 1.5, head_len, radius_scale * 1.5)
	_head.position = Vector3(0, 0, shaft_len + head_len * 0.5)


## ---------- Property helpers ----------
func _has_property(obj: Object, name: StringName) -> bool:
	for p in obj.get_property_list():
		if p.has("name") and p.name == name:
			return true
	return false


func _set_color(v: Color) -> void:
	color = v
	if is_instance_valid(_mat):
		_update_material()

func _set_opacity(v: float) -> void:
	opacity = v
	if is_instance_valid(_mat):
		_update_material()

