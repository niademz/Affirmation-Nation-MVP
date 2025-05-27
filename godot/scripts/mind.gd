extends Node

var BUILDABLE_PLACES = [
	{ "name": "Garden", "tag": "Nature", "weight": 1.0 },
	{ "name": "ReadingNook", "tag": "Books", "weight": 0.7 },
	{ "name": "TeaCorner", "tag": "Tea", "weight": 0.5 },
	{ "name": "BenchSpot", "tag": "Relax", "weight": 0.3 }
]


func process_villager(name: String, data: Dictionary) -> Dictionary:
	var mood = decay_mood(data["mood"])
	var traits = data["personality_traits"]
	var preferences = data["preferences"]
	var memory = data["memory"]
	var friends = data["friends"]
	
	if is_villager_sleeping(data):
		print("[MIND]", name, " is currently sleeping. No decision made.")
		return data
	
	if data.has("plans"):
		for plan in data["plans"]:
			if plan["time"] == Global.current_hour:
				execute_plan(name, plan)
				data["plans"].erase(plan)
				return data
	
	var decision = make_decision(data)
	var penalty = recent_action_penalty(memory, decision)
	
	# Update memory
	memory.append({
		"hour": Global.current_hour,
		"action": decision,
		"emotion_snapshot": mood["emotions"].duplicate()
	})

	# Simulate emotional impact
	match decision:
		"wander":
			mood["emotions"]["joy"] += max(0.05 * traits["wanderer"] - penalty, 0)
			mood["emotions"]["boredom"] = max(mood["emotions"]["boredom"] - 0.1, 0.0)

		"visit_friend":
			mood["emotions"]["joy"] += max(0.04 * traits["cheerful"] - penalty, 0)
			mood["social_meter"] = min(mood["social_meter"] + 0.2, 1.0)

		"stay_home":
			mood["emotions"]["boredom"] += 0.03
			mood["emotions"]["joy"] += max(0.01 * traits["hermit"] - penalty, 0)

		"tend_garden":
			mood["emotions"]["joy"] += max(0.06 * traits["caretaker"] - penalty, 0)

		"build":
			mood["emotions"]["joy"] += max(0.08 * traits["tinkerer"] - penalty, 0)
			mood["emotions"]["boredom"] = max(mood["emotions"]["boredom"] - 0.05, 0)
			
			var owned = data["ownership"]["places"]
			var chosen = choose_place_to_build(preferences, owned)
			
			if chosen != "":
				owned.append(chosen)
				data["ownership"]["places"] = owned
				var already_has_ownedspot = false
				for block in data["schedule"]:
					if block.get("spot") == "OwnedSpot":
						already_has_ownedspot = true
						break
				if not already_has_ownedspot:
					data["schedule"] = update_schedule_with_new_place(data["schedule"], chosen)
				
				prints("[MIND]", name, "built", chosen, "| Ownership now:", owned)
				print("Updated schedule for", name, ":", data["schedule"])

		"read":
			mood["emotions"]["joy"] += max(0.04 * traits["planner"] - penalty, 0)
			mood["emotions"]["boredom"] = max(mood["emotions"]["boredom"] - 0.03, 0)

		"observe_nature":
			mood["emotions"]["joy"] += max(0.05 * traits["cheerful"] - penalty, 0)
			mood["emotions"]["fear"] = max(mood["emotions"]["fear"] - 0.02, 0)

		"eat_snack":
			mood["emotions"]["joy"] += 0.03
			mood["emotions"]["boredom"] = max(mood["emotions"]["boredom"] - 0.01, 0)
		
		"visit_friends_owned_place":
			var friend_name = friends[randi() % friends.size()]
			var friend = VillagerManager.villagers.get(friend_name, null)
			if friend != null and friend["ownership"]["places"].size() > 0:
				var place = friend["ownership"]["places"][randi() % friend["ownership"]["places"].size()]
				mood["emotions"]["joy"] += 0.04
				prints("[MIND]", name, "visited", friend_name, "at", place)
		
		"make_plan_with_friend":
			var friend_name = friends[randi() % friends.size()]
			var friend = VillagerManager.villagers.get(friend_name, null)
			if friend != null:
				create_joint_plan(name, friend_name)
				mood["emotions"]["joy"] += 0.2
				prints("[MIND]", name, "made a plan with", friend_name)
	
	# Clamp emotion values between 0 and 1
	for key in mood["emotions"]:
		mood["emotions"][key] = clamp(mood["emotions"][key], 0.0, 1.0)
	mood["social_meter"] = clamp(mood["social_meter"], 0.0, 1.0)

	data["mood"] = mood
	data["memory"] = memory

	prints("[MIND]", name, "did", decision, "| New mood:", mood["emotions"])

	return data


func make_decision(data: Dictionary) -> String:
	var traits = data["personality_traits"]
	var mood = data["mood"]
	var preferences = data["preferences"]
	var friends = data.get("friends", [])
	var plans = data.get("plans", [])
	var boredom = mood["emotions"]["boredom"]
	var joy = mood["emotions"]["joy"]
	var social = mood["social_meter"]

	var likes_places = preferences.get("likes_places", [])
	var likes_items = preferences.get("likes_items", [])

	var weights = {
	"wander": traits["wanderer"] * 0.6 + boredom * 0.5,
	"visit_friend": (traits["cheerful"] * 0.5 + (1.0 - social)) * 0.6 if friends.size() > 0 else 0.0,
	"stay_home": traits["hermit"] * 0.7 + joy * 0.1,
	"tend_garden": traits["caretaker"] * 0.5 + (0.3 if "Garden" in likes_places else 0.0),
	"build": (traits["tinkerer"] * 0.6 + boredom * 0.1) * 0.4,
	"read": traits["planner"] * 0.4 + (0.3 if "Books" in likes_items else 0.0),
	"observe_nature": traits["cheerful"] * 0.3 + (0.5 if "Nature" in likes_places else 0.0),
	"eat_snack": traits["cheerful"] * 0.2 + (0.3 if "Apples" in likes_items else 0.0)
	} 
	
	if friends.size() > 0:
		weights["visit_friends_owned_place"] = 0.3 + traits["cheerful"] * 0.3
		weights["make_plan_with_friend"] = 0.2 + traits["planner"] * 0.4
	# Normalize weights
	var total = 0.0
	for val in weights.values():
		total += val

	if total <= 0:
		return "stay_home" # fallback

	var pick = randf() * total
	var sum = 0.0
	for action in weights.keys():
		sum += weights[action]
		if pick <= sum:
			return action

	return "stay_home"

func decay_mood(mood: Dictionary) -> Dictionary:
	for key in mood["emotions"]:
		match key:
			"joy":
				mood["emotions"][key] = max(mood["emotions"][key] - 0.01, 0.0)
			"boredom":
				mood["emotions"][key] = min(mood["emotions"][key] + 0.01, 1.0)
			"sadness", "fear":
				mood["emotions"][key] = max(mood["emotions"][key] - 0.005, 0.0)
	# Social meter also naturally decays (needs recharge!)
	mood["social_meter"] = max(mood["social_meter"] - 0.01, 0.0)
	return mood

func recent_action_penalty(memory: Array, action: String, depth := 5) -> float:
	var recent = memory.slice(-depth, depth)
	var count = 0
	for entry in recent:
		if entry["action"] == action:
			count += 1
			
	return count * 0.02  # 2% loss per repeat

func is_villager_sleeping(data):
	var schedule = data.get("schedule", [])
	var current = Global.current_hour * 100 + Global.current_minute
	
	for entry in schedule:
		if entry.get("type", "") == "SLEEP":
			var start = entry.get("start", 0)
			var end = entry.get("end", 0)
			
			if start < end:
				if current >= start and current < end:
					return true
			
			else:
				if current >= start or current < end:
					return true
	return false

func choose_place_to_build(preferences: Dictionary, owned_places: Array) -> String:
	var weights = {}

	for option in BUILDABLE_PLACES:
		var name = option["name"]
		var tag = option["tag"]
		var base_weight = option["weight"]

		# Skip already owned
		if name in owned_places:
			continue

		var bonus = 0.0
		if tag in preferences.get("likes_places", []):
			bonus += 0.5
		if tag in preferences.get("likes_items", []):
			bonus += 0.2

		weights[name] = base_weight + bonus

	# Pick randomly
	var total = 0.0
	for val in weights.values():
		total += val
	if total == 0:
		return ""

	var pick = randf() * total
	var accum = 0.0
	for name in weights.keys():
		accum += weights[name]
		if pick <= accum:
			return name

	return ""


func update_schedule_with_new_place(original_schedule: Array, new_place: String) -> Array:
	var new_schedule = []
	var sleep_block = null
	var active_blocks = []

	# Separate sleep and activity
	for block in original_schedule:
		if block["type"] == "SLEEP":
			sleep_block = block
		else:
			active_blocks.append(block)

	# Do nothing if new place is already in schedule
	for block in active_blocks:
		if block.get("spot") == new_place:
			return original_schedule

	# Get total time available (excluding sleep)
	var time_blocks = []
	for block in active_blocks:
		var duration = time_range_duration(block["start"], block["end"])
		time_blocks.append({ "spot": block["spot"], "duration": duration })

	# Determine how much time to give to new place (e.g., steal 1 hour total)
	var total_stolen = 100  # Time in "HHMM" format. 1 hour = 100
	var per_block_cut = int(round(float(total_stolen) / time_blocks.size() / 60)) * 60
	var new_time_block = { "type": "GOTO", "spot": "OwnedSpot" }

	# Build new blocks with cuts
	var cur_time = 900  # Let's assume villagers always start their day at 9:00
	var rebuilt_blocks = []

	for tb in time_blocks:
		var new_duration = tb["duration"] - per_block_cut
		var start_time = cur_time
		var end_time = add_minutes_to_time(cur_time, new_duration)
		rebuilt_blocks.append({
			"type": "GOTO",
			"spot": tb["spot"],
			"start": start_time,
			"end": end_time
		})
		cur_time = end_time

	# Insert the new block at the end of day (but before sleep)
	var new_block_start = cur_time
	var new_block_end = add_minutes_to_time(cur_time, total_stolen)
	new_time_block["start"] = new_block_start
	new_time_block["end"] = new_block_end
	rebuilt_blocks.append(new_time_block)

	# Add back sleep
	if sleep_block != null:
		rebuilt_blocks.append(sleep_block)

	return rebuilt_blocks

func clamp_time(value: int) -> int:
	if value >= 2400:
		return value - 2400
	return value

# Converts HHMM to minutes
func hhmm_to_minutes(hhmm: int) -> int:
	var hours = hhmm / 100
	var minutes = hhmm % 100
	return hours * 60 + minutes

# Converts minutes to HHMM
func minutes_to_hhmm(minutes: int) -> int:
	var h = int(minutes / 60) % 24
	var m = int(minutes % 60)
	return h * 100 + m

# Adds minutes to HHMM time safely
func add_minutes_to_time(hhmm: int, delta: int) -> int:
	var total_minutes = hhmm_to_minutes(hhmm) + delta
	return minutes_to_hhmm(total_minutes)

# Duration between two HHMM times (wraps around midnight)
func time_range_duration(start: int, end: int) -> int:
	var start_min = hhmm_to_minutes(start)
	var end_min = hhmm_to_minutes(end)
	if end_min < start_min:
		end_min += 1440  # Wrap around midnight
	return end_min - start_min

func attempt_social_interaction(name1, name2):
	var v1 = VillagerManager.villagers[name1]
	var v2 = VillagerManager.villagers[name2]
	
	var t1 = v1["personality_traits"]
	var t2 = v2["personality_traits"]
	
	var m1 = v1["mood"]
	var m2 = v2["mood"]
	
	var social_chance = (t1["cheerful"] + t2["cheerful"]) * 0.3 + (1.0 - abs(m1["social_meter"] - m2["social_meter"])) * 0.2
	
	if randf() < social_chance:
		m1["emotions"]["joy"] += 0.03
		m2["emotions"]["joy"] += 0.03
		
		m1["social_meter"] = min(m1["social_meter"] + 0.1, 1.0)
		m2["social_meter"] = min(m2["social_meter"] + 0.1, 1.0)
		
		if !(name2 in v1["friends"]):
			v1["friends"].append(name2)
		if !(name1 in v2["friends"]):
			v2["friends"].append(name1)
		
		prints("[SOCIAL]", name1, "interacted with", name2)
		
		VillagerManager.villagers[name1]["mood"] = m1
		VillagerManager.villagers[name2]["mood"] = m2
		VillagerManager.villagers[name1]["friends"] = v1["friends"]
		VillagerManager.villagers[name2]["friends"] = v2["friends"]

func create_joint_plan(name1: String, name2: String):
	var hour = Global.current_hour + 1
	if hour >= 24:
		hour -= 24

	var place = pick_shared_place(name1, name2)
	var plan = {
		"time": hour,
		"activity": "meet_at_place",
		"place": place
	}

	for name in [name1, name2]:
		var villager = VillagerManager.villagers[name]
		if !villager.has("plans"):
			villager["plans"] = []
		villager["plans"].append(plan)
		VillagerManager.villagers[name] = villager

func pick_shared_place(name1: String, name2: String) -> String:
	var p1 = VillagerManager.villagers[name1]["preferences"]["likes_places"]
	var p2 = VillagerManager.villagers[name2]["preferences"]["likes_places"]
	var shared = p1.filter(func(p): return p2.has(p))
	if shared.size() > 0:
		return shared[randi() % shared.size()]
	return "Statue"

func execute_plan(name: String, plan: Dictionary):
	if plan["activity"] == "meet_at_place":
		var mood = VillagerManager.villagers[name]["mood"]
		mood["emotions"]["joy"] += 0.05
		mood["social_meter"] = min(mood["social_meter"] + 0.1, 1.0)
		prints("[PLAN]", name, "followed plan and met friend at", plan["place"])
		VillagerManager.villagers[name]["mood"] = mood
