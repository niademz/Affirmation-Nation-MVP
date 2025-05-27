extends Control

#var affirmation_1 = $Panel/affirmation_1.text
#var affirmation_2 = $Panel/affirmation_2.text
#var affirmation_3 = $Panel/affirmation_3.text

# Called when the node enters the scene tree for the first time.
func _ready():
	print(Global.affirmation_1_date)
	Global.load_point_data()
	Global.load_aff1_date()
	Global.load_aff2_date()
	Global.load_aff3_date()
	print("Points: ", Global.player_point)
	if Global.affirmation_1_date == Time.get_date_string_from_system(false):
		$Panel/affirmation_1.text = "Daily Affirmation submitted"
		$Panel/affirmation_1.editable = false
	if Global.affirmation_2_date == Time.get_date_string_from_system(false):
		$Panel/affirmation_2.text = "Daily Affirmation submitted"
		$Panel/affirmation_2.editable = false
	if Global.affirmation_3_date == Time.get_date_string_from_system(false):
		$Panel/affirmation_3.text = "Daily Affirmation submitted"
		$Panel/affirmation_3.editable = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Panel/display_points.text = "Points: " + str(Global.player_point)
	pass


func _on_submit_pressed():
	if $Panel/affirmation_1.text != "":
		if Global.affirmation_1_date != Time.get_date_string_from_system(false):
			Global.affirmation_1_date = Time.get_date_string_from_system(false)
			Global.save_aff1_date()
			Global.player_point += 5
			print(Global.affirmation_1_date, 1)
	if $Panel/affirmation_2.text != "":
		if Global.affirmation_2_date != Time.get_date_string_from_system(false):
			Global.affirmation_2_date = Time.get_date_string_from_system(false)
			Global.save_aff2_date()
			Global.player_point += 5
			print(Global.affirmation_2_date, 2)
	if $Panel/affirmation_3.text != "":
		if Global.affirmation_3_date != Time.get_date_string_from_system(false):
			Global.player_point += 5
			Global.affirmation_3_date = Time.get_date_string_from_system(false)
			Global.save_aff3_date()
			print(Global.affirmation_3_date, 3)
	Global.save_points()
	Global.log_affirmation()


func _on_exit_pressed():
	$".".visible = false
