extends Node3D

@export var bolt_count = 30
@export var segments = 8
@export var radius = 0.6
@export var thickness = 0.03
var bolts = []

func _ready():

	for i in bolt_count:

		var mesh_instance = MeshInstance3D.new()
		var mesh = ImmediateMesh.new()

		mesh_instance.mesh = mesh
		add_child(mesh_instance)

		var mat = StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = Color(0.4,0.8,1.0)
		mat.emission_energy = 18

		mesh_instance.material_override = mat

		bolts.append(mesh)

func random_point_on_sphere():

	var dir = Vector3(
		randf_range(-1,1),
		randf_range(-1,1),
		randf_range(-1,1)
	).normalized()

	return dir * radius

func build_lightning(mesh):

	var start = random_point_on_sphere()
	var end = random_point_on_sphere()

	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	#mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	var prev = start

	for i in range(1, segments + 1):
		var t = float(i) / segments
		var pos = start.lerp(end, t)

		pos += Vector3(
			randf_range(-0.05,0.05),
			randf_range(-0.05,0.05),
			randf_range(-0.05,0.05)
			)

		var dir = (pos - prev).normalized()
		var side = dir.cross(Vector3.UP).normalized() * thickness

		mesh.surface_add_vertex(prev + side)
		mesh.surface_add_vertex(prev - side)

		prev = pos

		mesh.surface_add_vertex(pos)

	mesh.surface_end()

func _process(delta):

	for mesh in bolts:

		if randf() < 0.25:
			build_lightning(mesh)
