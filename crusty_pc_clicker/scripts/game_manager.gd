extends Node

#STATS
var current_money:float = 500.0
var money_per_click:float = 1.0
var passive_income:float = 0.0
var item_counts: Dictionary = {}

var money_label:Label = null
var passive_label:Label = null
var mpc_label:Label = null
var item_log_label: Label = null
@onready var passive_timer = $Timer
@onready var shop_canvas_layer = $ShopCanvasLayer
@onready var shop_panel = $ShopCanvasLayer/ShopPanel
@onready var left_column = $ShopCanvasLayer/ShopPanel/ScrollContainer/HBoxContainer/VBoxContainer
@onready var right_column = $ShopCanvasLayer/ShopPanel/ScrollContainer/HBoxContainer/VBoxContainer2

const SHOP_ITEM_SCENE = preload("res://scenes/shop_item.tscn")

const ITEM_EFFECTS = {
	"mpc_1":{"type":"mpc", "value":3.0, "price":10.0, "name": "Bum Ram"},
	"mpc_2":{"type":"mpc","value":1.0, "price":50.0, "name": "New Ram"},
	"passive_1":{"type":"passive","value":5.0, "price":350.0, "name": "Channel Ads"}
}

static func _item_price_comparator(a: Dictionary, b: Dictionary) -> bool:
	return a.price < b.price

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_stats_ui()
	
	if shop_canvas_layer != null and shop_panel!= null:
		shop_canvas_layer.visible = false
		shop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_populate_shop()
	
	passive_timer.wait_time = 1.0
	
	if not passive_timer.is_connected("timeout",Callable(self, "_on_passive_timer_timeout")):
		passive_timer.timeout.connect(Callable(self, "_on_passive_timer_timeout"))
	passive_timer.start()

func _create_shop_item(id: String, name: String, price: float, description: String) -> Panel:
	var item = SHOP_ITEM_SCENE.instantiate()
	item.item_id = id
	item.item_name = name
	item.item_price = price
	item.item_description = description
	return item

func _populate_shop():
	if left_column == null or right_column == null:
		return
	left_column.add_child(_create_shop_item("mpc_1", ITEM_EFFECTS["mpc_1"].name, ITEM_EFFECTS["mpc_1"].price, "Adds +3 money per click"))
	left_column.add_child(_create_shop_item("mpc_2", ITEM_EFFECTS["mpc_2"].name, ITEM_EFFECTS["mpc_2"].price, "Adds +1 money per click."))
	right_column.add_child(_create_shop_item("passive_1", ITEM_EFFECTS["passive_1"].name, ITEM_EFFECTS["passive_1"].price, "Adds +5 passive income/sec"))
func set_ui_references(ui_nodes: Dictionary):
	money_label = ui_nodes.get("money_label")
	passive_label = ui_nodes.get("passive_label")
	mpc_label = ui_nodes.get("mpc_label")
	item_log_label = ui_nodes.get("item_log_label")
	_update_stats_ui()


func toggle_shop_visibility():
	if shop_canvas_layer != null and shop_panel != null:
		shop_canvas_layer.visible = !shop_canvas_layer.visible
		if shop_canvas_layer.visible:
			shop_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			shop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func add_item_purchase(id: String):
	item_counts[id] = item_counts.get(id,0) + 1
	_update_item_log()

func _update_item_log():
	if item_log_label == null:
		return
		
	var log_text: String
	var items_to_sort = []
	
	# 1. Gather all item data (ID, Name, Price) from ITEM_EFFECTS
	for id in ITEM_EFFECTS.keys():
		var item_data = ITEM_EFFECTS[id]
		items_to_sort.append({
			"id": id,
			"name": item_data.name,
			"price": item_data.price # Data used for sorting
		})
		
	# 2. Sort the array based on price using the custom comparator
	items_to_sort.sort_custom(Callable(self, "_item_price_comparator"))
	
	# 3. Build the final log text using the sorted array (FIXED: Loop is outside the data gathering)
	for item in items_to_sort:
		var id = item.id
		var item_name = item.name
		# Get the count, defaulting to 0 if the item hasn't been purchased
		var count = item_counts.get(id, 0) 
		
		log_text += "%s: x%d\n" % [item_name, count]
			
	item_log_label.text = log_text
	

func _update_stats_ui():
	if money_label != null:
		money_label.text = "MONEY: %0.2f$" % current_money
	if passive_label != null:
		passive_label.text = "PASSIVE INCOME: +%s/s" % [passive_income]
	if mpc_label != null:
		mpc_label.text = "MONEY PER CLICK: +%s" % [money_per_click]
		_update_item_log()

func area_clicked():
	current_money += money_per_click
	_update_stats_ui()

func _on_passive_timer_timeout():
	current_money += passive_income
	_update_stats_ui()

func shop_exit_button_pressed():
	toggle_shop_visibility()
