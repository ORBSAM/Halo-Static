extends Node

# Persistent player state shared between rooms.
signal health_changed(current_health: float, max_health: float)
signal energy_changed(current_energy: float, max_energy: float)
signal player_died

const DEFAULT_MAX_HEALTH: float = 100.0
const MAX_HARMONIC_ENERGY: float = 100.0

var max_health: float = DEFAULT_MAX_HEALTH
var current_health: float = DEFAULT_MAX_HEALTH
var harmonic_energy: float = 0.0

var has_key: bool = false
var is_boss_defeated: bool = false


func _ready() -> void:
	reset_run()


func reset_run() -> void:
	max_health = DEFAULT_MAX_HEALTH
	current_health = max_health
	harmonic_energy = 0.0
	has_key = false
	is_boss_defeated = false

	health_changed.emit(current_health, max_health)
	energy_changed.emit(harmonic_energy, MAX_HARMONIC_ENERGY)


func take_damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		player_died.emit()


func heal(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return

	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func add_energy(amount: float) -> void:
	if amount <= 0.0:
		return

	harmonic_energy = clampf(
		harmonic_energy + amount,
		0.0,
		MAX_HARMONIC_ENERGY
	)
	energy_changed.emit(harmonic_energy, MAX_HARMONIC_ENERGY)


func consume_energy(amount: float) -> bool:
	if amount < 0.0 or harmonic_energy < amount:
		return false

	harmonic_energy -= amount
	energy_changed.emit(harmonic_energy, MAX_HARMONIC_ENERGY)
	return true
