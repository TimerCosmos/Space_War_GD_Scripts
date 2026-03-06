extends Node
class_name DropService

static func load_drop_groups(Callback: Callable):
	ApiClient.get_with_auth("/api/v1/drop-groups", Callback)
