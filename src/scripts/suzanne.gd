@tool
"""
    Asset: Godot Dynamic Catenary
    File: suzenne.gd
    Description: Suzanne go wild.
    Repository: https://github.com/Donitzo/godot-catenary
    License: MIT License
"""

extends Node3D

var _total_seconds:float

var _move_seconds:float
var _move_duration:float
var _move_easing:float
var _wait_seconds:float

var _start_position:Vector3
var _start_rotation:Vector3

var _target_position:Vector3
var _target_rotation:Vector3

func _ready() -> void:
    _start_move()

func _process(delta:float) -> void:
    _total_seconds += delta
    
    _move_seconds -= delta
    if _move_seconds < -_wait_seconds:
        _start_move()
    
    if _move_seconds < 0:
        return
    
    var t:float = ease(min(1, 1.0 - _move_seconds / _move_duration), _move_easing)
    position = _start_position.lerp(_target_position, t)
    rotation = Vector3(
        lerp_angle(_start_rotation.x, _target_rotation.x, t),
        lerp_angle(_start_rotation.y, _target_rotation.y, t),
        lerp_angle(_start_rotation.z, _target_rotation.z, t))

func _start_move() -> void:
    _move_duration = 1.1 + sin(_total_seconds) * randf_range(0.5, 1)
    _move_seconds = _move_duration
    _move_easing = randf_range(-4, 4)
    _wait_seconds = max(randf_range(-5, 1), 0)
    
    _start_position = position
    _start_rotation = rotation
    
    _target_position = Vector3(0, 1.3, 0) + Vector3(randf_range(-0.5, 0.5), randf_range(-0.3, 0.3), randf_range(-0.5, 0.5))
    _target_rotation = Vector3(randf_range(-0.5, 0.5), randf_range(-1, 1), randf_range(-0.5, 0.5))
