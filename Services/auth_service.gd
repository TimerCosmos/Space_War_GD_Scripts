extends Node

func login(email: String, password: String, callback: Callable):
	var data = {
		"email": email,
		"password": password
	}

	ApiClient.post("/api/v1/auth/login", data, callback)


func register(email: String, name: String, password: String, callback: Callable):
	var data = {
		"email": email,
		"name": name,
		"password": password
	}

	ApiClient.post("/api/v1/auth/register", data, callback)
