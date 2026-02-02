extends Node3D

var timeBetweenViseme = 175.0
var referenceVisemeTime

var referenceFaceTime
var referenceBlinkTime
var deltaBlink
var timeBetweenBlink = 5000.0
var facialExpressionDuration = 2000.0
var aus:Array = [ 0 ]


var curve = Curve.new()



@onready var Meshes: Array = []
@onready var audiostreamplayer = $"../AudioStreamPlayer3D"
var viseme_animation_parameters: Dictionary[String, float] = {}
var viseme_animation_parameters_back: Dictionary[String, float] = {}
var face_animation_parameters: Dictionary[int,ActionUnit] = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	deltaBlink = randf_range(-1.0,1.0)
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.25, 1.0))
	curve.add_point(Vector2(0.75, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	
	referenceVisemeTime = Time.get_ticks_msec()
	referenceFaceTime = Time.get_ticks_msec()
	referenceBlinkTime = Time.get_ticks_msec()
	
	Meshes.append($"../Armature_1/Skeleton3D/Eye_Mesh")
	Meshes.append($"../Armature_1/Skeleton3D/EyeAO_Mesh")
	Meshes.append($"../Armature_1/Skeleton3D/Eyelash_Mesh")
	Meshes.append($"../Armature_1/Skeleton3D/Head_Mesh")
	Meshes.append($"../Armature_1/Skeleton3D/Teeth_Mesh")
	Meshes.append($"../Armature_1/Skeleton3D/Tongue_Mesh")
	var viseme_names = [
		"viseme_sil",
		"viseme_PP",
		"viseme_FF",
		"viseme_TH",
		"viseme_DD",
		"viseme_kk",
		"viseme_CH",
		"viseme_SS",
		"viseme_nn",
		"viseme_RR",
		"viseme_aa",
		"viseme_E",
		"viseme_I",
		"viseme_O",
	    "viseme_U"
	]
	for viseme_name in viseme_names:
		viseme_animation_parameters[viseme_name] = 0
		viseme_animation_parameters_back[viseme_name] = 0
	
	
	# AU1
	face_animation_parameters[1] = ActionUnit.new(1, ["browInnerUp"])
	# AU2
	face_animation_parameters[2] = ActionUnit.new(2, ["browOuterUpLeft", "browOuterUpRight"])
	# AU4
	face_animation_parameters[4] = ActionUnit.new(4, ["browDownLeft", "browDownRight"])
	# AU5
	face_animation_parameters[5] = ActionUnit.new(5, ["eyeWideLeft", "eyeWideRight"])
	# AU6
	face_animation_parameters[6] = ActionUnit.new(6, ["cheekSquintLeft", "cheekSquintRight"])
	# AU7
	face_animation_parameters[7] = ActionUnit.new(7, ["eyeSquintLeft", "eyeSquintRight"])
	# AU9
	face_animation_parameters[9] = ActionUnit.new(9, ["noseSneerLeft", "noseSneerRight"])
	# AU10
	face_animation_parameters[10] = ActionUnit.new(10, ["mouthUpperUpLeft", "mouthUpperUpRight"])
	# AU12
	face_animation_parameters[12] = ActionUnit.new(12, ["mouthSmileLeft", "mouthSmileRight"])
	# AU14
	face_animation_parameters[14] = ActionUnit.new(14, ["mouthDimpleLeft", "mouthDimpleRight"])
	# AU15
	face_animation_parameters[15] = ActionUnit.new(15, ["mouthFrownLeft", "mouthFrownRight"])
	# AU16
	face_animation_parameters[16] = ActionUnit.new(16, ["mouthLowerDownLeft", "mouthLowerDownRight"])
	# AU17
	face_animation_parameters[17] = ActionUnit.new(17, ["mouthShrugLower"])
	# AU18
	face_animation_parameters[18] = ActionUnit.new(18, ["mouthPucker"])
	# AU20
	face_animation_parameters[20] = ActionUnit.new(20, ["mouthStretchLeft", "mouthStretchRight"])
	# AU22
	face_animation_parameters[22] = ActionUnit.new(22, ["mouthFunnel"])
	# AU24
	face_animation_parameters[24] = ActionUnit.new(24, ["mouthPressLeft", "mouthPressRight"])
	# AU26
	face_animation_parameters[26] = ActionUnit.new(26, ["jawOpen"])
	# AU27
	face_animation_parameters[27] = ActionUnit.new(27, ["jawOpen"])
	# AU28
	face_animation_parameters[28] = ActionUnit.new(28, ["mouthRollLower", "mouthRollUpper"])
	# AD29
	face_animation_parameters[29] = ActionUnit.new(29, ["jawForward"])
	# AD30
	face_animation_parameters[30] = ActionUnit.new(30, ["jawLeft"])
	# AD34
	face_animation_parameters[34] = ActionUnit.new(34, ["cheekPuff"])
	# AU45
	face_animation_parameters[45] = ActionUnit.new(45, ["eyeBlink"])
	# M63
	face_animation_parameters[63] = ActionUnit.new(63, ["eyeLookUpLeft", "eyeLookUpRight"])
	# M64
	face_animation_parameters[64] = ActionUnit.new(64, ["eyeLookDownLeft", "eyeLookDownRight"])
	# AU65
	face_animation_parameters[65] = ActionUnit.new(65, ["eyeLookOutLeft", "eyeLookOutRight"])
	# AU66
	face_animation_parameters[66] = ActionUnit.new(66, ["eyeLookInLeft", "eyeLookInRight"])

func setFacialAUs(_aus:Array, intensities:Array, duration:float):
	aus = _aus.duplicate(true);
	facialExpressionDuration = duration;
	referenceFaceTime = Time.get_ticks_msec()
	for i in range(aus.size()):
		face_animation_parameters[aus[i]].Value = intensities[i];


func update_lip_back_weight() -> void:
	viseme_animation_parameters_back = viseme_animation_parameters.duplicate(true)

func set_viseme_neutral() -> void:
	for key in viseme_animation_parameters:
		viseme_animation_parameters[key] = 0

func set_face_neutral() -> void:
	for key in face_animation_parameters:
		face_animation_parameters[key].Value = 0

func set_random_viseme() -> void:
	set_viseme_neutral()
	var keys = viseme_animation_parameters.keys()
	if keys.is_empty():
		return
	var key = keys.pick_random()
	viseme_animation_parameters[key] = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var now = Time.get_ticks_msec()
	var lipLerp:float = (now - referenceVisemeTime) / (timeBetweenViseme)
	var faceLerp = (now - referenceFaceTime) / facialExpressionDuration

	if audiostreamplayer.playing:
		if now - referenceVisemeTime > timeBetweenViseme:
			update_lip_back_weight()
			referenceVisemeTime = now
			set_random_viseme()
	else:
		set_viseme_neutral()
		if now - referenceFaceTime > facialExpressionDuration:
			set_face_neutral()

	lerp_viseme(lipLerp)
	interpolate_face(faceLerp)
	#Blink
	if now > referenceBlinkTime + timeBetweenBlink + deltaBlink:
		blink()
	if now > referenceBlinkTime + timeBetweenBlink + deltaBlink + 200.0:
		unblink()
		referenceBlinkTime = now;
		deltaBlink = randf_range(-1.0, 1.0)

func lerp_viseme(lerp_amount: float) -> void:
	for mesh_target in Meshes:
		var m: Mesh = mesh_target.mesh
		if m == null:
			continue

		for key in viseme_animation_parameters.keys():
			var blend_index = get_blend_shape_index(mesh_target,key)
			
			if blend_index >= 0:
				var weight = lerp(
					viseme_animation_parameters_back[key],
					viseme_animation_parameters[key],
					clampf(lerp_amount,0,1)
				)
				mesh_target.set_blend_shape_value(blend_index, weight)
	

func interpolate_face(lerp_amount: float) -> void:
	for mesh_target in Meshes:
		var m: Mesh = mesh_target.mesh
		if m == null:
			continue
		for fp in face_animation_parameters.keys():
			for k in face_animation_parameters[fp].Names:
				var blend_index = get_blend_shape_index(mesh_target,k)
				if blend_index >= 0:
					var weight = lerp(
						0,
						face_animation_parameters[fp].Value,
						clampf(curve.sample(lerp_amount),0,1)
					)
					mesh_target.set_blend_shape_value(blend_index, weight)

func blink():
	for mesh_target in Meshes:
		var m: Mesh = mesh_target.mesh
		if m == null:
			continue
		var i = get_blend_shape_index(mesh_target,"eyeBlinkLeft")
		var j = get_blend_shape_index(mesh_target,"eyeBlinkRight")
		if i >= 0 && j >= 0:
			mesh_target.set_blend_shape_value(i, 1)
			mesh_target.set_blend_shape_value(j, 1)
		
	
func unblink():
	for mesh_target in Meshes:
		var m: Mesh = mesh_target.mesh
		if m == null:
			continue
		var i = get_blend_shape_index(mesh_target,"eyeBlinkLeft")
		var j = get_blend_shape_index(mesh_target,"eyeBlinkRight")
		if i >= 0 && j >= 0:
			mesh_target.set_blend_shape_value(i, 0)
			mesh_target.set_blend_shape_value(j, 0)


func get_blend_shape_index(mesh_instance: MeshInstance3D, blend_name: String) -> int:
	var mesh = mesh_instance.mesh
	if mesh == null:
		return -1
	for i in range(mesh.get_blend_shape_count()):
		if mesh.get_blend_shape_name(i) == blend_name:
			return i
	return -1
