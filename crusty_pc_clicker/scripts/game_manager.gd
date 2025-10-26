extends Node

#STATS
var current_money:float = 0.0
var money_per_click:float = 1.0
var passive_income:float = 0.0

var money_label:Label = null
var passive_label:Label = null
var mpc_label:Label = null
@onready var passive_timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_stats_ui()
	
	passive_timer.wait_time = 1.0
	passive_timer.autostart = true
	
	if not passive_timer.is_connected("timeout",Callable(self, "_on_passive_timer_timeout")):
		passive_timer.connect("timeout", Callable(self, "_on_passive_timer_timeout"))

func set_ui_references(ui_nodes: Dictionary):
	money_label = ui_nodes.get("money_label")
	passive_label = ui_nodes.get("passive_label")
	mpc_label = ui_nodes.get("mpc_label")
	_update_stats_ui()

func _update_stats_ui():
	if money_label != null:
		money_label.text = "MONEY: %s$" % [round(current_money*100.0) / 100.0]
	if passive_label != null:
		passive_label.text = "PASSIVE INCOME: +%s/s" % [passive_income]
	if mpc_label != null:
		mpc_label.text = "MONEY PER CLICK: +%s" % [money_per_click]

func area_clicked():
	current_money += money_per_click
	_update_stats_ui()

func _on_passive_timer_timeout():
	current_money += passive_income
	_update_stats_ui()
	
