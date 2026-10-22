extends Node

const SFX := {
	"ui_click":   "res://audio/sfx/universfield-menu-button-click-147349.mp3" ,
	"ui_hover":    "res://audio/sfx/universfield-menu-button-click-hover.mp3" ,
	"pause_open":   "res://audio/sfx/soundshelfstudio-ui-holographic-menu-open-537622.mp3",
	"pause_close":  "res://audio/sfx/litupsubway-ui-close-sfx-513359.mp3",
	"dialogue_open": "res://audio/sfx/freesound_community-paper-rustle-81855.mp3",
	"dialogue_blip": "res://audio/sfx/ncprime-keyboard-typing-one-short-292592.mp3",
	"dialogue_close": "res://audio/sfx/freesound_community-crumple-03-40747.mp3",
	"saber_swing":  "res://audio/sfx/xpmonster-quick-swing-sound-419581.mp3",
	"orb_fire":     "res://audio/sfx/freesound_community-steam_burst-6822.mp3",
	"enemy_hit":    "res://audio/sfx/freesound_community-monster-attack-47786.mp3",
	"enemy_die":    "res://audio/sfx/666herohero-monster-death-grunt-131480.mp3",
	"enemy_growl":  "res://audio/sfx/dragon-studio-beast-growl-sound-376873.mp3",
	"player_hurt":  "res://audio/sfx/freesound_community-jump-climb-or-damage-sound-f-95942.mp3",
	"pickup_good":  "res://audio/sfx/yodguard-item-pickup-3-540193.mp3",
	"pickup_bad":   "res://audio/sfx/dragon-studio-caution-sfx-570427.mp3",
	"key":          "res://audio/sfx/litupsubway-key-collect-sfx-522219.mp3",
	"door":         "res://audio/sfx/freesound_community-creepysound1-cave_entrance.mp3",
}
const MUSIC := {
	"boss":    "res://audio/music/john_evil_boss_battle_music.mp3",
	"dungeon": "res://audio/music/dueslower_dungeon_ambient_piano.mp3",
	"menu":    "res://audio/music/freesound_community-resonating-very-far-away-56773.mp3",
}

# negative = quieter. Tune by ear.
const SFX_DB := {
	"ui_click": -6.0,
	"ui_hover": -4.0,
	"saber_swing": -3.0,
	"enemy_hit": -5.0,
	"enemy_die": -4.0,
	"enemy_growl": -6.0,
	"player_hurt": -2.0,
	"door": -4.0,
}

const CREDIT_INFO := {
	"boss":    {"title": "Boss track name",      "by": "Artist", "license": "CC BY 4.0", "url": "opengameart.org"},
	"dungeon": {"title": "Dungeon ambience",     "by": "Artist", "license": "CC0",       "url": "freesound.org"},
	"menu":    {"title": "Menu theme",           "by": "Artist", "license": "CC0",       "url": ""},
	"ui_click":    {"title": "UI click",  "by": "Kenney", "license": "CC0", "url": "kenney.nl"},
	"ui_hover":    {"title": "UI hover",  "by": "Kenney", "license": "CC0", "url": "kenney.nl"},
	"saber_swing": {"title": "Saber swing", "by": "jsfxr",  "license": "Generated", "url": "sfxr.me"},
	# add one entry per key as you add the file
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

func play_sfx(key: String, volume_db := -2.0, pitch_var := 0.06, cooldown := 0.04) -> void:
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
			p.volume_db = volume_db + float(SFX_DB.get(key, 0.0))
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
	
# =======
# CREDIT LOGIC
# Handles the credits, dynamically.
# =========

func _exists(table: Dictionary, key: String) -> bool:
	return table.has(key) and ResourceLoader.exists(table[key])

# music: one line per track
func music_credit_lines() -> Array[String]:
	var out: Array[String] = []
	for key in MUSIC:
		if _exists(MUSIC, key) and CREDIT_INFO.has(key):
			out.append(_fmt(CREDIT_INFO[key], true))
	return out

# sfx: grouped by author so "Kenney" appears once, not 10 times
func sfx_credit_lines() -> Array[String]:
	var groups := {}   # "by|license|url" -> [titles]
	for key in SFX:
		if not (_exists(SFX, key) and CREDIT_INFO.has(key)):
			continue
		var c: Dictionary = CREDIT_INFO[key]
		var gk := "%s|%s|%s" % [c.by, c.license, c.get("url", "")]
		if not groups.has(gk):
			groups[gk] = []
		if not c.title in groups[gk]:
			groups[gk].append(c.title)

	var out: Array[String] = []
	for gk in groups:
		var parts: PackedStringArray = gk.split("|")
		var line := "%s (%s)" % [parts[0], parts[1]]
		if parts[2] != "":
			line += " - " + parts[2]
		out.append(line)
		out.append(", ".join(groups[gk]))
	return out

func _fmt(c: Dictionary, with_url: bool) -> String:
	var s := "\"%s\" by %s (%s)" % [c.title, c.by, c.license]
	if with_url and c.get("url", "") != "":
		s += " - " + c.url
	return s
