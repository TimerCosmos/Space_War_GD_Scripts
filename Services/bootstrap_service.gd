extends Node

func load_bootstrap(callback: Callable):
	ApiClient.get_with_auth("/api/v1/bootstrap", callback)
