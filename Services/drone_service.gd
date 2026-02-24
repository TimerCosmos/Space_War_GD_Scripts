extends Node

func get_all_drones(callback: Callable):
	ApiClient.get_with_auth("/api/v1/drones", callback)
