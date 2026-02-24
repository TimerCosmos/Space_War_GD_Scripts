extends Node

# ---------------------------------
# Global drone selection manager
# ---------------------------------

var selected_drone_id: String = ""

# ---------------------------------
# Get Selected Drone Resource
# ---------------------------------

func get_selected_drone_data() -> DroneData:

	var drone_id := selected_drone_id

	if drone_id == "":
		return null

	var backend_drone = _find_drone_by_id(drone_id)
	if backend_drone == null:
		return null

	if backend_drone.tres_file_path == "":
		return null

	var resource: DroneData = load(backend_drone.tres_file_path)
	return resource


# ---------------------------------
# Get Backend Drone DTO
# ---------------------------------

func get_selected_backend_drone():
	if selected_drone_id == "":
		return null

	return _find_drone_by_id(selected_drone_id)


# ---------------------------------
# Internal
# ---------------------------------

func _find_drone_by_id(id: String):
	for drone in GameState.all_drones:
		if drone.id == id:
			return drone
	return null
