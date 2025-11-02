extends Node

#STATS
var current_viewers:float = 500.0
var viewers_per_click:float = 1.0
var passive_viewers:float = 0.0
var item_counts: Dictionary = {}
var is_raided:bool = false
var current_raid_name: String = ""
var base_vpc:float = 0.0
var base_passive_viewers:float = 0.0
var raid_duration

var viewer_label:Label = null
var passive_label:Label = null
var vpc_label:Label = null
var item_log_label: Label = null
@onready var passive_timer = $Timer
@onready var shop_canvas_layer = $ShopCanvasLayer
@onready var shop_panel = $ShopCanvasLayer/ShopPanel
@onready var left_column = $ShopCanvasLayer/ShopPanel/ScrollContainer/HBoxContainer/VBoxContainer
@onready var right_column = $ShopCanvasLayer/ShopPanel/ScrollContainer/HBoxContainer/VBoxContainer2


@onready var admin_canvas_layer = $AdminCanvasLayer
@onready var admin_panel = $AdminCanvasLayer/AdminPanel
@onready var add_viewer_input = $AdminCanvasLayer/AdminPanel/AmountInput


const SHOP_ITEM_SCENE = preload("res://scenes/shop_item.tscn")

const ITEM_EFFECTS = {
	"vpc_1":{"type":"vpc", "value":3.0, "price":10.0, "name": "Bum Ram"},
	"vpc_2":{"type":"vpc","value":1.0, "price":50.0, "name": "New Ram"},
	"passive_1":{"type":"passive","value":5.0, "price":350.0, "name": "Channel Ads"}
}
#format of:Streamer: {boost factor, probability}
const STREAMERS = {
	"Ludwig": {"boost": 1.5, "probability": 2.0},
	"Valkyrae": {"boost":1.8, "probability": 2.0},
	"IRONMOUSE": {"boost":2.1, "probability": 2.0},
	"XQC": {"boost": 2.8, "probability": 1.2},
	"JYNXZI": {"boost": 3.5, "probability": 1.2},
	"Caseoh": {"boost": 4.5, "probability": 1.0},
	"JASONTHEWEEN": {"boost": 6.0, "probability": 0.6}
}
@onready var raid_timer = $RaidTimer
@onready var raid_duration_timer = $RaidDurationTimer

static func _item_price_comparator(a: Dictionary, b: Dictionary) -> bool:
	return a.price < b.price

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_stats_ui()
	
	if shop_canvas_layer != null and shop_panel!= null:
		shop_canvas_layer.visible = false
		shop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if admin_canvas_layer != null and admin_panel != null:
		admin_canvas_layer.visible = false
		admin_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_populate_shop()
	
	passive_timer.wait_time = 1.0
	
	if not passive_timer.is_connected("timeout",Callable(self, "_on_passive_timer_timeout")):
		passive_timer.timeout.connect(Callable(self, "_on_passive_timer_timeout"))
	passive_timer.start()
	if raid_timer != null:
		if not raid_timer.timeout.is_connected(Callable(self, "_on_raid_timer_timeout")):
			raid_timer.timeout.connect(Callable(self, "_on_raid_timer_timeout"))
		_start_next_raid_timer()

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
	left_column.add_child(_create_shop_item("vpc_1", ITEM_EFFECTS["vpc_1"].name, ITEM_EFFECTS["vpc_1"].price, "Adds +3 subscribers per click"))
	left_column.add_child(_create_shop_item("vpc_2", ITEM_EFFECTS["vpc_2"].name, ITEM_EFFECTS["vpc_2"].price, "Adds +1 subscriber per click."))
	right_column.add_child(_create_shop_item("passive_1", ITEM_EFFECTS["passive_1"].name, ITEM_EFFECTS["passive_1"].price, "Adds +5 subscribers/sec"))
func set_ui_references(ui_nodes: Dictionary):
	viewer_label = ui_nodes.get("viewer_label")
	passive_label = ui_nodes.get("passive_label")
	vpc_label = ui_nodes.get("vpc_label")
	item_log_label = ui_nodes.get("item_log_label")
	_update_stats_ui()


func toggle_shop_visibility():
	if shop_canvas_layer != null and shop_panel != null:
		shop_canvas_layer.visible = !shop_canvas_layer.visible
		if shop_canvas_layer.visible:
			shop_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			shop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func toggle_admin_visibility():
	if admin_canvas_layer != null and admin_panel != null:
		admin_canvas_layer.visible = !admin_canvas_layer.visible
		if admin_canvas_layer.visible:
			admin_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			admin_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	

func _on_add_viewer_button_pressed():
	print("button pressed")
	if add_viewer_input == null:
		return
	var input_text = add_viewer_input.text
	var amount:float = float(input_text)
	print("Admin: Attempting to add %0.2f viewers." % amount)
	if amount > 0.0:
		current_viewers += amount
		_update_stats_ui()
		add_viewer_input.text = ""
	else:
		add_viewer_input.text = ""
		return

func _update_stats_ui():
	if viewer_label != null:
		viewer_label.text = "VIEWERS: %0.2f$" % current_viewers
	if passive_label != null:
		passive_label.text = "PASSIVE VIEWERS: +%s/s" % [passive_viewers]
	if vpc_label != null:
		vpc_label.text = "VIEWERS PER CLICK: +%s" % [viewers_per_click]
		_update_item_log()

func _get_random_streamer() -> String:
	var total_weight: float = 0.0
	for streamer in STREAMERS.keys():
		total_weight += STREAMERS[streamer].probability
	var random_point = randf() * total_weight
	var cumulative_weight: float = 0.0
	for streamer in STREAMERS.keys():
		var weight = STREAMERS[streamer].proabbility
		cumulative_weight += weight
		if random_point <= cumulative_weight:
			return streamer
	return STREAMERS.keys()[0]

func _start_next_raid_timer():
	if raid_timer == null:
		return
	
	var min_minutes:float = 40.0
	var max_minutes: float = 50.0
	raid_timer.wait_time = randf_range(60.0 * min_minutes, 60.0 * max_minutes)
	raid_timer.start()

func _on_raid_timer_timeout():
	if is_raided:
		_start_next_raid_timer()
		return
	var streamer = _get_random_streamer()
	var raid_data = STREAMERS[streamer]
	current_raid_name = streamer
	var boost_factor: float = raid_data.boost
	base_vpc = viewers_per_click
	base_passive_viewers = passive_viewers
	is_raided = true
	print("You were raided by %s! (Boost Factor: %0.2f)") % [current_raid_name, boost_factor]
	if raid_duration_timer != null:
		raid_duration_timer.wait_time = raid_duration
		if not raid_duration_timer.timeout.is_connected(Callable(self, "_on_raid_duration_timer_timeout")):
			raid_duration_timer.timeout.connect(Callable(self, "_on_raid_duration_timer_timeout"))
		raid_duration_timer.start()
	else:
		return
	_update_stats_ui()
	_start_next_raid_timer()
	
func _on_raid_duration_timer_timeout():
	if not is_raided:
		return
	viewers_per_click = base_vpc
	passive_viewers = base_passive_viewers
	is_raided = false
	current_raid_name = ""
	_update_stats_ui()


func area_clicked():
	current_viewers += viewers_per_click
	_update_stats_ui()

func _on_passive_timer_timeout():
	current_viewers += passive_viewers
	_update_stats_ui()

func shop_exit_button_pressed():
	toggle_shop_visibility()

func admin_exit_button_pressed():
	toggle_admin_visibility()
