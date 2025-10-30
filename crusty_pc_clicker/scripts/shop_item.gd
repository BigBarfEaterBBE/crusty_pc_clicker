extends Panel

@export var item_id:String = ""
@export var item_name:String = "Default Item"
@export var item_price:float = 10.0
@export var item_description:String = "Description of item"

@onready var price_label = $ItemPrice
@onready var buy_button = $BuyButton
@onready var item_icon = $ItemImage
@onready var name_label = $ItemName
@onready var description_label = $ItemDescription

func _ready():
	name_label.text = item_name
	description_label.text = item_description
	price_label.text = "%0.2f" % item_price
	buy_button.pressed.connect(Callable(self, "_on_buy_button_pressed"))

func _on_buy_button_pressed():
	if GameManager.current_money >= item_price:
		GameManager.current_money -= item_price
		var effect_data: Dictionary = GameManager.ITEM_EFFECTS[item_id]
		var effect_type: String = effect_data.type
		var value:float = effect_data.value
		if effect_type == 'passive':
			GameManager.passive_income += value
		elif effect_type == "mpc":
			GameManager.money_per_click += value
		GameManager._update_stats_ui()
		
