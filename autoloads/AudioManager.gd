extends Node

const SFX := {
	"ui_click":     "res://audio/sfx/ui_click.ogg",
	"ui_hover":     "res://audio/sfx/ui_hover.ogg",
	"pause_open":   "res://audio/sfx/pause_open.ogg",
	"pause_close":  "res://audio/sfx/pause_close.ogg",
	"dialogue_open":"res://audio/sfx/dialogue_open.ogg",
	"dialogue_blip":"res://audio/sfx/dialogue_blip.ogg",
	"saber_swing":  "res://audio/sfx/saber_swing.ogg",
	"orb_fire":     "res://audio/sfx/orb_fire.ogg",
	"enemy_hit":    "res://audio/sfx/enemy_hit.ogg",
	"enemy_die":    "res://audio/sfx/enemy_die.ogg",
	"enemy_growl":  "res://audio/sfx/enemy_growl.ogg",
	"player_hurt":  "res://audio/sfx/player_hurt.ogg",
	"pickup_good":  "res://audio/sfx/pickup_good.ogg",
	"pickup_bad":   "res://audio/sfx/pickup_bad.ogg",
	"key":          "res://audio/sfx/key.ogg",
	"door":         "res://audio/sfx/door.ogg",
}
const MUSIC := {
	"boss":    "res://audio/music/boss.ogg",
	"dungeon": "res://audio/music/dungeon_ambience.ogg",
	"menu":    "res://audio/music/menu.ogg",
}

var _cache := {}
var _music: Array[AudioStreamPlayer] = []
var _active := 0
var _music_key := ""
var _pool: Array[AudioStreamPlayer] = []
var _last := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS     # keeps playing while paused
	for b in ["Music", "SFX"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -6.0)

	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		add_child(p)
		_music.append(p)
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)

	# every Button, present or future, gets click and hover sounds
	get_tree().node_added.connect(_hook)
	_hook_tree(get_tree().root)

func _hook_tree(n: Node) -> void:
	_hook(n)
	for c in n.get_children():
		_hook_tree(c)

func _hook(n: Node) -> void:
	if n is BaseButton:
		if not n.pressed.is_connected(_on_ui_pressed):
			n.pressed.connect(_on_ui_pressed)
		if not n.mouse_entered.is_connected(_on_ui_hover):
			n.mouse_entered.connect(_on_ui_hover)

func _on_ui_pressed() -> void: play_sfx("ui_click")
func _on_ui_hover() -> void: play_sfx("ui_hover", -10.0)

func _stream(table: Dictionary, key: String) -> AudioStream:
	if not table.has(key):
		return null
	if not _cache.has(key):
		var path: String = table[key]
		_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return _cache[key]

func play_sfx(key: String, volume_db := 0.0, pitch_var := 0.06, cooldown := 0.04) -> void:
	var s := _stream(SFX, key)
	if s == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(key, -10.0)) < cooldown:
		return                                    # stops stacked sounds from getting loud
	_last[key] = now
	for p in _pool:
		if not p.playing:
			p.stream = s
			p.volume_db = volume_db
			p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
			p.play()
			return

func play_music(key: String, fade := 1.2) -> void:
	if key == _music_key:
		return
	_music_key = key
	var old := _music[_active]
	_active = 1 - _active
	var nw := _music[_active]
	var s := _stream(MUSIC, key)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(old, "volume_db", -60.0, fade)
	tw.chain().tween_callback(old.stop)
	if s:
		if "loop" in s:
			s.loop = true
		nw.stream = s
		nw.volume_db = -60.0
		nw.play()
		tw.tween_property(nw, "volume_db", 0.0, fade)

func stop_music(fade := 1.0) -> void:
	play_music("", fade)
