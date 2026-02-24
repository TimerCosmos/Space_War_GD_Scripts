# No api call is needed

extends Control

@onready var health_bar: ProgressBar = $HealthBar
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var damage: Label = $VBoxContainer/Damage
@onready var drone_count: Label = $VBoxContainer/DroneCount

var DroneCount: int = 0

func _ready():
	add_to_group("hud")

func set_max_health(max_hp: int):
	health_bar.max_value = max_hp

func update_health(value: int, max_hp := -1):
	health_bar.value = value

func update_score(value: int):
	score_label.text = "Score: " + str(value)
	
func update_damage(value:int):
	damage.text = "Damage: "+str(value)

func update_drone_count(value: int):
	DroneCount += value
	drone_count.text = "Drones: " + str(DroneCount)
