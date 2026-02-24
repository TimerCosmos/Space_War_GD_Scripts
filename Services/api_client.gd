extends Node

const BASE_URL = "http://127.0.0.1:8000"

var http: HTTPRequest

func _ready():
	http = HTTPRequest.new()
	add_child(http)


func post(endpoint: String, data: Dictionary, callback: Callable):
	var url = BASE_URL + endpoint
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(data)

	http.request_completed.connect(
		func(result, response_code, headers, body):
			var response_text = body.get_string_from_utf8()
			callback.call(response_code, response_text)
	, CONNECT_ONE_SHOT)

	http.request(url, headers, HTTPClient.METHOD_POST, body)


func get_with_auth(endpoint: String, callback: Callable):
	var url = BASE_URL + endpoint
	
	var headers = [
		"Authorization: Bearer " + GameState.access_token
	]

	http.request_completed.connect(
		func(result, response_code, headers, body):
			var response_text = body.get_string_from_utf8()
			callback.call(response_code, response_text)
	, CONNECT_ONE_SHOT)

	http.request(url, headers, HTTPClient.METHOD_GET)
