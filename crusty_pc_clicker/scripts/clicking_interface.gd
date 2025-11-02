extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	print("--- Debug: GameManager is type:", GameManager.get_class())
	if is_instance_valid(GameManager):
		var ui_refs = {
			"viewer_label": $stats_bar/MarginContainer/HBoxContainer/current_viewers,
			"passive_label": $stats_bar/MarginContainer/HBoxContainer/passive_viewers,
			"vpc_label": $stats_bar/MarginContainer/HBoxContainer/viewers_per_click,
			"item_log_label": $HBoxContainer/sidebar/LogLabel
		}
		GameManager.set_ui_references(ui_refs)

func _on_click_area_pressed():
	GameManager.area_clicked()
func _on_shop_button_pressed():
	GameManager.toggle_shop_visibility()
func _on_admin_button_pressed():
	GameManager.toggle_admin_visibility()
