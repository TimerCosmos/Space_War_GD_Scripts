class_name Ad
extends RefCounted

var type : String
var limit : int
var remaining : int


static func from_dict(data: Dictionary) -> Ad:
	var ad = Ad.new()

	var t = data.get("type")
	ad.type = str(t) if t != null else ""

	var l = data.get("limit")
	ad.limit = int(l) if l != null else 0

	var r = data.get("remaining")
	ad.remaining = int(r) if r != null else 0

	return ad
