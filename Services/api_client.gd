extends Node

const BASE_URL := "http://127.0.0.1:8000"
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
# -------------------------------------------------
# Internal Unified Request Handler
# -------------------------------------------------
func _make_request(
	method: int,
	endpoint: String,
	body: Dictionary,
	requires_auth: bool,
	callback: Callable
):
	var http := HTTPRequest.new()
	add_child(http)

	var headers: Array = []

	# Add JSON header if body exists
	if body.size() > 0:
		headers.append("Content-Type: application/json")

	# Add auth header if needed
	if requires_auth:
		if GameState.access_token == "":
			push_warning("No access token available.")
		else:
			headers.append("Authorization: Bearer " + GameState.access_token)

	var json_body := ""
	if body.size() > 0:
		json_body = JSON.stringify(body)

	http.request_completed.connect(
		func(result, response_code, response_headers, response_body):
			var response_text: String = response_body.get_string_from_utf8()

			if response_code == 401:
				print("Unauthorized. Logging out.")
				GameState.logout()
				get_tree().change_scene_to_file("res://Scenes/Startup/login.tscn")
				http.queue_free()
				return

			if callback.is_valid():
				callback.call(response_code, response_text)

			http.queue_free(),
		CONNECT_ONE_SHOT
	)
	
	var error = http.request(
		BASE_URL + endpoint,
		headers,
		method,
		json_body
	)

	if error != OK:
		push_error("HTTP request failed to start.")
		http.queue_free()


# -------------------------------------------------
# Public API Methods
# -------------------------------------------------

# GET without auth
func get_request(endpoint: String, callback: Callable):
	_make_request(
		HTTPClient.METHOD_GET,
		endpoint,
		{},
		false,
		callback
	)

# GET with auth
func get_with_auth(endpoint: String, callback: Callable):
	_make_request(
		HTTPClient.METHOD_GET,
		endpoint,
		{},
		true,
		callback
	)

# POST without auth
func post(endpoint: String, data: Dictionary, callback: Callable):
	_make_request(
		HTTPClient.METHOD_POST,
		endpoint,
		data,
		false,
		callback
	)

# POST with auth
func post_with_auth(endpoint: String, data: Dictionary, callback: Callable):
	_make_request(
		HTTPClient.METHOD_POST,
		endpoint,
		data,
		true,
		callback
	)

# PATCH with auth
func patch_with_auth(endpoint: String, data: Dictionary, callback: Callable):
	_make_request(
		HTTPClient.METHOD_PATCH,
		endpoint,
		data,
		true,
		callback
	)

# DELETE with auth (future-proofing)
func delete_with_auth(endpoint: String, callback: Callable):
	_make_request(
		HTTPClient.METHOD_DELETE,
		endpoint,
		{},
		true,
		callback
	)
