"""
    Asset: Godot Dynamic Catenary
    File: catenary.gd
    Description: Node for drawing a catenary between two points using the catenary shader.
                 Based on algorithms from https://www.alanzucconi.com/2020/12/13/catenary-2/
    Instructions: The script will create a temporary mesh instance for the catenary.
                  The position of this node acts as the starting point for the catenary.
                  Assign the target path to another spatial node which will act as the end point.
    Repository: https://github.com/Donitzo/godot-catenary
    License: MIT License
"""

tool
extends Spatial
class_name Catenary

## The minimum number of binary search iterations to find the catenary "a" parameter.
const _a_search_min_iterations:int = 16

## The mesh with the rope-like object spanning the x-axis
export var mesh:Mesh setget _set_mesh

## The end point target
export var target_path:NodePath setget _set_target_path

## Whether to track the target node ingame using process
export var track_target:bool = true setget _set_track_target

## The real-world length of the catenary (limited by the distance between the start/end point)
export var length:float = 5.0 setget _set_length

## The scale multiplier of the yz-axes of the mesh
export(float, 0.01, 10, 0.01) var width = 1.0 setget _set_width

## The catenary swing angle in radians
export(float, 3.141593) var swing_angle:float = 0.5 setget _set_swing_angle

## The catenary swing frequency
export(float, 10) var swing_frequency:float = 2 setget _set_swing_frequency

## The target node instance
var _target_node:Spatial

## The last known target node position
var _target_position:Vector3

## A temporary catenary mesh instance
var _mesh_instance:MeshInstance

## A temporary catenary material
var _material:ShaderMaterial

func _set_mesh(v:Mesh) -> void:
    if v != mesh:
        mesh = v

        _create_mesh_instance()
        _update_curve()

func _set_target_path(v:NodePath) -> void:
    target_path = v
    _target_node = null

    _update_curve()

func _set_track_target(v:bool) -> void:
    track_target = v
    
    set_process(track_target or Engine.is_editor_hint())

func _set_length(v:float) -> void:
    length = v
    
    _update_curve()

func _set_width(v:float) -> void:
    width = v
    
    if _material != null:
        _material.set_shader_param("width", width)

func _set_swing_angle(v:float) -> void:
    swing_angle = v
    
    if _material != null:
        _material.set_shader_param("swing_angle", swing_angle)

func _set_swing_frequency(v:float) -> void:
    swing_frequency = v
    
    if _material != null:
        _material.set_shader_param("swing_frequency", swing_frequency)

func _notification(what) -> void:
    if what == NOTIFICATION_TRANSFORM_CHANGED:
        _update_curve()

func _ready() -> void:
    _update_curve()

func _process(_delta:float) -> void:
    if _target_node != null and _target_position != _target_node.global_translation:
        _update_curve()

func _create_mesh_instance() -> void:
    # Enable transform notifications for this spatial
    set_notify_transform(true)
   
    # Create a catenary material
    if _material == null:
        _material = ShaderMaterial.new()
        _material.shader = preload("res://shaders/catenary.tres")
        _material.set_shader_param("width", width)
        _material.set_shader_param("swing_phase_offset", rand_range(0, PI * 2))
        _material.set_shader_param("swing_angle", swing_angle)
        _material.set_shader_param("swing_frequency", swing_frequency)

    # Remove any old mesh instance (updating old instance doesn't work in editor)
    if _mesh_instance != null:
        remove_child(_mesh_instance)

    # Create the catenary mesh instance as a child node of this spatial.
    # The mesh instance is an orphan which will not be saved with the scene,
    # otherwise the override material (+ textures) would be saved with the scene in the editor.
    _mesh_instance = MeshInstance.new()
    _mesh_instance.name = "Catenary"
    _mesh_instance.mesh = mesh
    _mesh_instance.material_override = _material

    add_child(_mesh_instance)

    # If no mesh is assigned, just create an empty mesh instance
    if mesh == null:
        return

    # The mesh size is required for scaling the catenary
    var aabb:AABB = mesh.get_aabb()
    _material.set_shader_param("minmax_x", Vector2(aabb.position.x, aabb.end.x))

    # You may need to replace these uniforms based on what kind of shader is used on the mesh.
    # These uniforms act as a standard SchlickGGX shader in Godot.
    var material:SpatialMaterial = mesh.surface_get_material(0)
    _material.set_shader_param("albedo", material.albedo_color)
    _material.set_shader_param("texture_albedo", material.albedo_texture)
    _material.set_shader_param("specular", material.metallic_specular)
    _material.set_shader_param("metallic", material.metallic)
    _material.set_shader_param("alpha_scissor_threshold", material.params_alpha_scissor_threshold)
    _material.set_shader_param("roughness", material.roughness)
    _material.set_shader_param("texture_metallic", material.metallic_texture)
    _material.set_shader_param("texture_roughness", material.roughness_texture)
    _material.set_shader_param("texture_emission", material.emission_texture)
    _material.set_shader_param("emission", material.emission)
    _material.set_shader_param("emission_energy", material.emission_energy)
    _material.set_shader_param("texture_normal", material.normal_texture)
    _material.set_shader_param("normal_scale", material.normal_scale)

func _update_curve() -> void:
    # Create a mesh instance of none exists
    if _mesh_instance == null:
        _create_mesh_instance()

    # Get the target node
    if _target_node == null:
        if is_inside_tree() and target_path != "":
            _target_node = get_node(target_path)
        else:
            return

    var start:Vector3 = global_translation
    var target:Vector3 = _target_node.global_translation

    _target_position = target

    # Flip start and end point so that p0 is always the lowest
    var flip:bool = target.y < start.y
    var p0:Vector3 = target if flip else start
    var p1:Vector3 = start if flip else target

    # Get the catenary arc length
    var shift:Vector3 = p1 - p0
    var l:float = max(shift.length() * 1.0001, length)

    # Approximate the "a" parameter of the catenary expression
    # See formulas at https://www.alanzucconi.com/2020/12/13/catenary-2/

    var h:float = sqrt(shift.x * shift.x + shift.z * shift.z)
    var v:float = shift.y
    var c:float = sqrt(l * l - v * v)
    
    if h == 0:
        return

    # Exponentially grow "a" range to a maximum of 2^32
    
    var a_min:float = 0
    var a_max:float = 1

    var i:int = 0

    while i < 32 and c < 2 * a_max * sinh(h / (2 * a_max)):
        i += 1
        a_min = a_max
        a_max *= 2

    # Binary search for "a" parameter
    
    i += _a_search_min_iterations

    var a:float

    while i > 0:
        i -= 1
        a = (a_min + a_max) * 0.5
        if c < 2 * a * sinh(h / (2 * a)):
            a_min = a
        else:
            a_max = a

    # Calculate "p" and "q" parameters based on catenary arc length and "a"
    var p:float = (h - a * log((l + v) / (l - v))) / 2
    var q:float = (v - l * (1 / tanh(h / (2 * a)))) / 2

    # Add the catenary arc length to the cull margin (this size is often larger than required)
    var ref:Node = self
    if ref is MeshInstance:
        ref.extra_cull_margin = l + 1
    _mesh_instance.extra_cull_margin = l + 1

    # Set shader uniforms related to the catenary
    _material.set_shader_param("p0", p0)
    _material.set_shader_param("p1", p1)
    _material.set_shader_param("apq", Vector3(a, p, q))
    _material.set_shader_param("arc_length", l)
    _material.set_shader_param("flip_x", 1.0 if flip else 0.0)
