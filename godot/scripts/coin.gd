extends Area2D

@onready var animation_player = $AnimationPlayer

func _on_body_entered(body):
	if body.has_method("player"):
		print("+1 coin")
		Global.player_coin += 1
		Global.save_coins()
		print("Coin count: ", Global.player_coin)
		animation_player.play("pickup")
