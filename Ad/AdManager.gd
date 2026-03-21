extends Node

# -------------------------------------------------
# STATE
# -------------------------------------------------

var rewarded_ads : Dictionary = {}
var last_ad_type : String = ""

var reward_listener := OnUserEarnedRewardListener.new()

var ads_initialized := false


# -------------------------------------------------
# READY (NO INIT HERE)
# -------------------------------------------------

func _ready():

	# Only setup reward listener
	reward_listener.on_user_earned_reward = func(rewarded_item : RewardedItem):

		print("Reward earned")

		var backend_type = last_ad_type.to_lower()
		request_backend_reward(backend_type)


# -------------------------------------------------
# INIT ADS (CALL AFTER CONSENT ONLY)
# -------------------------------------------------

func init_ads():

	if ads_initialized:
		print("Ads already initialized")
		return

	print("Initializing Ads (Consent granted)")

	MobileAds.initialize()

	# preload ads AFTER consent
	load_rewarded("coins")
	load_rewarded("diamonds")

	ads_initialized = true


# -------------------------------------------------
# LOAD REWARDED AD
# -------------------------------------------------

func load_rewarded(type:String):

	type = type.to_lower()

	var unit_id : String

	if OS.get_name() == "Android":
		unit_id = GameState.admob_rewarded[type]
	else:
		print("Unsupported platform for ads")
		return

	var callback := RewardedAdLoadCallback.new()

	callback.on_ad_failed_to_load = func(error : LoadAdError):
		print("Ad failed to load: ", error.message)

	callback.on_ad_loaded = func(ad : RewardedAd):

		print("Rewarded ad loaded for ", type)

		rewarded_ads[type] = ad

		var fullscreen := FullScreenContentCallback.new()

		fullscreen.on_ad_dismissed_full_screen_content = func():
			print("Ad closed")
			load_rewarded(type)

		ad.full_screen_content_callback = fullscreen

	# No Bundle → simple request
	var request := AdRequest.new()

	RewardedAdLoader.new().load(unit_id, request, callback)


# -------------------------------------------------
# SHOW REWARDED AD
# -------------------------------------------------

func show_rewarded(type:String):

	if not ads_initialized:
		print("Ads not initialized (no consent yet)")
		return

	type = type.to_lower()

	if not GameState.ad_limits.has(type) or GameState.ad_limits[type].remaining <= 0:
		print("No ads remaining")
		return

	if not rewarded_ads.has(type):
		print("Ad not loaded yet for ", type)
		return

	last_ad_type = type
	rewarded_ads[type].show(reward_listener)


# -------------------------------------------------
# BACKEND REWARD
# -------------------------------------------------

func request_backend_reward(type:String):

	ApiClient.post_with_auth(
		"/api/v1/ads/reward",
		{ "ad_type": type },
		func(code, body):

			if code != 200:
				print("Backend reward failed")
				return

			var data = JSON.parse_string(body)

			if typeof(data) != TYPE_DICTIONARY:
				print("Invalid backend response")
				return

			if data.get("status","") != "success":
				print("Reward rejected")
				return

			# -------------------------
			# Update user economy
			# -------------------------
			if data.has("user_economy"):
				
				var econ = data["user_economy"]

				GameState.user.coins = econ.get("COINS", GameState.user.coins)
				GameState.user.diamonds = econ.get("DIAMONDS", GameState.user.diamonds)
				GameState.economy_updated.emit()
			
			# -------------------------
			# Update specific ad info
			# -------------------------
			if data.has("ads"):

				var ad_data = data["ads"]
				var ad = Ad.from_dict(ad_data)

				GameState.ad_limits[ad.type] = ad
				GameState.ads_updated.emit()

			print("Reward granted")
	)
