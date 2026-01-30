extends Node3D
"""
Gestion du regard avec des bones (yeux, tête, colonne)
"""

@onready var skeleton: Skeleton3D = $"../Armature_1/Skeleton3D"
@export var target: Node3D

@export var spine_bone_name := "Spine1"
@export var head_bone_name := "Head"
@export var left_eye_bone_name := "LeftEye"
@export var right_eye_bone_name := "RightEye"

@export var speed: float = 5.0

func _process(delta):
	if skeleton == null or target == null:
		return

	_look_at_bone(spine_bone_name, 0.75, delta)
	_look_at_bone(head_bone_name, 0.75, delta)
	_look_at_bone(left_eye_bone_name, 0.75, delta)
	_look_at_bone(right_eye_bone_name, 0.75, delta)


func _look_at_bone(bone_name: String, weight: float, delta: float) -> void:
	var bone_idx = skeleton.find_bone(bone_name)
	if bone_idx == -1:
		return

	# Transform global actuel du bone
	var bone_global = skeleton.get_bone_global_pose(bone_idx)

	# Direction vers la cible
	var dir = (target.global_position - bone_global.origin).normalized()

	# Axe forward du bone (souvent -Z)
	var forward = bone_global.basis.z.normalized()

	# Quaternion qui amène forward -> dir
	var rot = Quaternion(forward, dir)

	# On blend pour éviter un snap brutal
	rot = Quaternion.IDENTITY.slerp(rot, weight)

	# Appliquer uniquement la rotation locale
	skeleton.set_bone_pose_rotation(bone_idx, rot)
