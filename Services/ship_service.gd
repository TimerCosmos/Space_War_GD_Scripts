extends Node

func get_all_ships(callback: Callable):
	ApiClient.get_with_auth("/api/v1/ships", callback)
