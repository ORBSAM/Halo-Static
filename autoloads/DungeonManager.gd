extends Node
# ==========================================
# GLOBAL MANAGER (AUTOLOAD SINGLETON)
# Responsible for persistent game variables across room loads.
# ==========================================

# TODO: Declare HP and Harmonic Energy variables (HP max 100, Energy 0-100)
# TODO: Declare boolean flags (e.g., has_key, is_boss_defeated)
# TODO: Define signals for UI updates (signal hp_changed, signal energy_changed)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: Initialize default player metrics on game launch
	pass # Replace with function body.

func take_damage(amount: int) -> void:
	# TODO: Subtract HP by amount
	# TODO: Emit hp_changed signal
	# TODO: Check if HP <= 0 -> trigger player death / Game Over scene
	pass

func add_energy(amount: int) -> void:
	# TODO: Increase Harmonic Energy
	# TODO: Check if Energy >= 100 -> trigger Overload Blast and reset Energy to 25
	# TODO: Emit energy_changed signal
	pass

func consume_energy(amount: int) -> void:
	# TODO: Decrease Harmonic Energy on weapon swing
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
