@tool
class_name ItemWheel
extends Control
## A radial item selection wheel.
##
## Hold [member open_mouse_button] (or [member open_action]) to show the wheel,
## point at a segment to highlight it, then release to select it. Releasing
## inside the centre dead zone (or pressing [code]ui_cancel[/code]) cancels.
##
## Connect to [signal item_selected] and [signal selection_cancelled] to react
## to the player's choice. The wheel itself never calls into game code.

## Emitted when the wheel becomes visible.
signal opened()
## Emitted when the wheel is hidden again, after selection or cancellation.
signal closed()
## Emitted when the player releases over an enabled segment.
signal item_selected(index: int, item: ItemWheelItem)
## Emitted when the player releases over the dead zone or a disabled segment.
signal selection_cancelled()

## Maximum number of items a single wheel supports.
const MAX_ITEMS := 10

@export_group("Layout")
## Outer radius of the wheel, in pixels.
@export_range(50.0, 1000.0, 1.0, "or_greater") var radius: float = 150.0:
	set(value):
		radius = value
		queue_redraw()
		_reposition_overlays()

## Radius of the central "cancel" zone. Releasing inside it cancels selection.
@export_range(0.0, 500.0, 1.0) var dead_zone_radius: float = 40.0:
	set(value):
		dead_zone_radius = value
		queue_redraw()
		_reposition_overlays()

## Angular gap between segments, in degrees.
@export_range(0.0, 20.0, 0.1) var gap_degrees: float = 2.0:
	set(value):
		gap_degrees = value
		queue_redraw()

## Box that item icons are fitted into, preserving each icon's aspect ratio
## (no squishing). Individual items can scale further via their icon_scale.
@export var icon_size: Vector2 = Vector2(48, 48):
	set(value):
		icon_size = value
		queue_redraw()
		_reposition_overlays()

@export_group("Appearance")
## Default fill color of segments (items can override it per segment).
@export var background_color: Color = Color(0.1, 0.1, 0.1, 0.85):
	set(value):
		background_color = value
		queue_redraw()

## Fill/tint color of the currently hovered segment.
@export var highlight_color: Color = Color(0.9, 0.75, 0.2, 0.9):
	set(value):
		highlight_color = value
		queue_redraw()

## Fill/tint color of disabled segments.
@export var disabled_color: Color = Color(0.15, 0.15, 0.15, 0.5):
	set(value):
		disabled_color = value
		queue_redraw()

## Optional texture drawn under the whole wheel (sized to the wheel's rect).
@export var background_texture: Texture2D:
	set(value):
		background_texture = value
		queue_redraw()

@export_group("Selection Display")
## Tint the previously selected item's segment so the player can see what is
## currently equipped when the wheel reopens.
@export var show_previous_selection: bool = false:
	set(value):
		show_previous_selection = value
		queue_redraw()

## Fill/tint used for the previously selected segment.
@export var previous_selection_color: Color = Color(0.3, 0.5, 0.85, 0.9):
	set(value):
		previous_selection_color = value
		queue_redraw()

## Show the hovered item's name under the wheel while it is open.
@export var show_selection_name: bool = false:
	set(value):
		show_selection_name = value
		_ensure_name_label()

## Pixel offset applied to the selection name label.
@export var selection_name_offset: Vector2 = Vector2.ZERO:
	set(value):
		selection_name_offset = value
		_reposition_overlays()

@export_group("Input")
## InputMap action that opens the wheel while held. When empty,
## [member open_mouse_button] is used instead.
@export var open_action: String = ""

## Mouse button that opens the wheel while held (used when [member open_action] is empty).
@export var open_mouse_button: MouseButton = MOUSE_BUTTON_MIDDLE

## Alter [member Engine.time_scale] while the wheel is open, creating a
## slow-motion (or fully frozen) selection experience. Set
## [member open_time_scale] to [code]0.0[/code] to freeze the game entirely.
## The original time scale is restored when the wheel closes.
@export var change_time_scale_while_open: bool = false

## Time scale applied while the wheel is open.
## [code]0.0[/code] = frozen; [code]1.0[/code] = full speed.
## Only used when [member change_time_scale_while_open] is [code]true[/code].
@export_range(0.0, 1.0, 0.05) var open_time_scale: float = 0.0

@export_group("Behaviour")
## When false the whole wheel is inactive and will never open.
@export var enabled: bool = true:
	set(value):
		enabled = value
		if not enabled and _is_open:
			_close(false)
		queue_redraw()

## The items shown on the wheel, clockwise from the top. Supports 1 to 10 items.
@export var items: Array[ItemWheelItem] = []:
	set(value):
		if value.size() > MAX_ITEMS:
			push_warning("ItemWheel supports at most %d items; extra entries were dropped." % MAX_ITEMS)
			value.resize(MAX_ITEMS)
		items = value
		_connect_item_signals()
		_rebuild_overlays()
		queue_redraw()

## Index of the previously selected item, or -1. Set automatically on
## selection; games can also set it directly (e.g. to the starting weapon).
var previous_selection_index := -1:
	set(value):
		previous_selection_index = value
		queue_redraw()

var _is_open := false
var _hovered_index := -1
var _labels: Array[Label] = []
var _bars: Array[ProgressBar] = []
var _name_label: Label
var _prev_time_scale := 1.0


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _ready() -> void:
	resized.connect(_reposition_overlays)
	_connect_item_signals()
	_ensure_name_label()
	_rebuild_overlays()
	if not Engine.is_editor_hint():
		hide()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not _is_open:
		return
	var idx := _angle_to_index(get_local_mouse_position())
	if idx != _hovered_index:
		_hovered_index = idx
		queue_redraw()
		_update_name_label()
	# Keep labels/bars live so ammo counters etc. update while the wheel is open.
	_refresh_overlay_values()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not enabled:
		return
	if _is_open and event.is_action_pressed("ui_cancel"):
		_close(false)
		get_viewport().set_input_as_handled()
		return
	if open_action != "" and InputMap.has_action(open_action):
		if event.is_action_pressed(open_action):
			_open()
			get_viewport().set_input_as_handled()
		elif event.is_action_released(open_action) and _is_open:
			_close(true)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == open_mouse_button:
		if event.pressed:
			_open()
			get_viewport().set_input_as_handled()
		elif _is_open:
			_close(true)
			get_viewport().set_input_as_handled()


# --- Public API --------------------------------------------------------------


## Enable or disable the whole wheel.
## Disabling while open closes the wheel silently (emits [signal closed] and,
## if a slice was highlighted, [signal selection_cancelled]).
func set_enabled(value: bool) -> void:
	enabled = value


## Returns [code]true[/code] when the wheel is active.
func is_enabled() -> bool:
	return enabled


## Replace the wheel's item list. The array is clamped to [constant MAX_ITEMS]
## and overlays are rebuilt automatically, identical to setting [member items].
func set_items(new_items: Array[ItemWheelItem]) -> void:
	items = new_items


## Returns the current item list.
func get_items() -> Array[ItemWheelItem]:
	return items


## Set the selected item by index. Updates [member previous_selection_index] and
## redraws the previous-selection tint. Pass -1 to clear the selection.
func set_selected_index(index: int) -> void:
	previous_selection_index = index


## Returns the index of the previously selected item, or -1 if none.
func get_selected_index() -> int:
	return previous_selection_index


## Returns the previously selected [ItemWheelItem], or [code]null[/code] if
## nothing has been selected yet or [member previous_selection_index] is -1.
func get_selected_item() -> ItemWheelItem:
	if previous_selection_index < 0 or previous_selection_index >= items.size():
		return null
	return items[previous_selection_index]


# --- Wheel state -------------------------------------------------------------


func _open() -> void:
	if _is_open or not enabled or items.is_empty():
		return
	_is_open = true
	_hovered_index = _angle_to_index(get_local_mouse_position())
	show()
	queue_redraw()
	_update_name_label()
	_refresh_overlay_values()
	_reposition_overlays()
	if change_time_scale_while_open:
		_prev_time_scale = Engine.time_scale
		Engine.time_scale = open_time_scale
	opened.emit()


func _close(confirm: bool) -> void:
	if not _is_open:
		return
	_is_open = false
	hide()
	if change_time_scale_while_open:
		Engine.time_scale = _prev_time_scale
	var idx := _hovered_index
	_hovered_index = -1
	var valid := confirm and idx >= 0 and idx < items.size()
	if valid and items[idx] != null and not items[idx].disabled:
		previous_selection_index = idx
		item_selected.emit(idx, items[idx])
	else:
		selection_cancelled.emit()
	closed.emit()


## Returns the segment index under [param local_pos], or -1 for the dead zone.
func _angle_to_index(local_pos: Vector2) -> int:
	var v := local_pos - size / 2.0
	if items.is_empty() or v.length() < dead_zone_radius:
		return -1
	# Rotate so segment 0 starts at the top, going clockwise.
	var t := fposmod(v.angle() + PI / 2.0, TAU)
	return int(t / (TAU / items.size())) % items.size()


# --- Drawing -----------------------------------------------------------------


func _draw() -> void:
	var center := size / 2.0
	if background_texture != null:
		var rect := Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
		draw_texture_rect(background_texture, rect, false)
	var count := items.size()
	if count == 0:
		if Engine.is_editor_hint():
			# Editor placeholder so an unconfigured wheel is still visible.
			var mid := (dead_zone_radius + radius) * 0.5
			draw_arc(center, mid, 0.0, TAU, 64, background_color, radius - dead_zone_radius)
		return
	var seg := TAU / count
	var gap := deg_to_rad(gap_degrees) if count > 1 else 0.0
	for i in count:
		var item := items[i]
		var t_start := i * seg + gap * 0.5
		var t_end := (i + 1) * seg - gap * 0.5
		var pts := _wedge_points(t_start, t_end, dead_zone_radius, radius, center)
		var is_disabled := item != null and item.disabled
		var is_previous := show_previous_selection and i == previous_selection_index
		if item != null and item.segment_texture != null:
			var tint := Color.WHITE
			if is_disabled:
				tint = disabled_color
			elif i == _hovered_index:
				tint = highlight_color
			elif is_previous:
				tint = previous_selection_color
			draw_colored_polygon(pts, tint, _wedge_uvs(pts), item.segment_texture)
		else:
			var fill := background_color
			if item != null and item.override_segment_color:
				fill = item.segment_color
			if is_disabled:
				fill = disabled_color
			elif i == _hovered_index:
				fill = highlight_color
			elif is_previous:
				fill = previous_selection_color
			draw_colored_polygon(pts, fill)
		if item != null and item.icon != null:
			var mid_angle := (t_start + t_end) * 0.5 - PI / 2.0
			var mid_r := (dead_zone_radius + radius) * 0.5
			var pos := center + Vector2(cos(mid_angle), sin(mid_angle)) * mid_r
			var icon_tint := Color(1, 1, 1, 0.35) if is_disabled else Color.WHITE
			var tex_size := item.icon.get_size()
			var fit_box := item.icon_size if item.override_icon_size else icon_size
			var fit := 1.0
			if tex_size.x > 0.0 and tex_size.y > 0.0:
				fit = minf(fit_box.x / tex_size.x, fit_box.y / tex_size.y)
			var draw_size := tex_size * fit * item.icon_scale
			var top_left := pos + item.icon_offset - draw_size * 0.5
			draw_texture_rect(item.icon, Rect2(top_left, draw_size), false, icon_tint)


## Builds the outline of one ring segment between [param t_start] and
## [param t_end] (angles in "wheel space", where 0 is the top of the wheel).
func _wedge_points(t_start: float, t_end: float, inner: float, outer: float, center: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := maxi(3, int(ceil((t_end - t_start) / 0.1)))
	for s in steps + 1:
		var a := lerpf(t_start, t_end, float(s) / steps) - PI / 2.0
		pts.append(center + Vector2(cos(a), sin(a)) * outer)
	for s in steps + 1:
		var a := lerpf(t_end, t_start, float(s) / steps) - PI / 2.0
		pts.append(center + Vector2(cos(a), sin(a)) * inner)
	return pts


## Maps wedge points to UVs spanning the wedge's bounding box.
func _wedge_uvs(pts: PackedVector2Array) -> PackedVector2Array:
	var bounds := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		bounds = bounds.expand(p)
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append((p - bounds.position) / bounds.size)
	return uvs


# --- Label / progress bar overlays -------------------------------------------


func _connect_item_signals() -> void:
	for item in items:
		if item != null and not item.changed.is_connected(_on_item_changed):
			item.changed.connect(_on_item_changed)


func _on_item_changed() -> void:
	queue_redraw()
	_refresh_overlay_values()
	_reposition_overlays()


func _rebuild_overlays() -> void:
	if not is_inside_tree():
		return
	for label in _labels:
		if is_instance_valid(label):
			label.queue_free()
	for bar in _bars:
		if is_instance_valid(bar):
			bar.queue_free()
	_labels.clear()
	_bars.clear()
	for i in items.size():
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(120, 20)
		label.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(label)
		_labels.append(label)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.size = Vector2(70, 8)
		bar.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(bar)
		_bars.append(bar)
	_refresh_overlay_values()
	_reposition_overlays()


func _refresh_overlay_values() -> void:
	for i in mini(items.size(), _labels.size()):
		var item := items[i]
		var label := _labels[i]
		var bar := _bars[i]
		if item == null:
			label.visible = false
			bar.visible = false
			continue
		label.text = item.name
		label.visible = item.display_name and item.name != ""
		bar.visible = item.show_progress_bar
		bar.max_value = item.progress_max
		bar.value = item.progress_value
		var tint := Color(1, 1, 1, 0.4) if item.disabled else Color.WHITE
		label.modulate = tint
		bar.modulate = tint


func _reposition_overlays() -> void:
	if not is_inside_tree():
		return
	if _name_label != null and is_instance_valid(_name_label):
		var name_pos := size / 2.0 + Vector2(-_name_label.size.x * 0.5, radius + 16.0)
		_name_label.position = name_pos + selection_name_offset
	if items.is_empty():
		return
	var center := size / 2.0
	var seg := TAU / items.size()
	var mid_r := (dead_zone_radius + radius) * 0.5
	for i in mini(items.size(), _labels.size()):
		var item := items[i]
		var a := seg * (i + 0.5) - PI / 2.0
		var pos := center + Vector2(cos(a), sin(a)) * mid_r
		var fit_box := item.icon_size if item != null and item.override_icon_size else icon_size
		var base_y := fit_box.y * 0.5 + 4.0
		var label_off := item.label_offset if item != null else Vector2.ZERO
		var bar_off := item.progress_bar_offset if item != null else Vector2.ZERO
		_labels[i].position = pos + Vector2(-_labels[i].size.x * 0.5, base_y) + label_off
		# When the item's name is hidden the bar takes its spot.
		var name_shown := item != null and item.display_name and item.name != ""
		var bar_y := base_y + (22.0 if name_shown else 0.0)
		_bars[i].position = pos + Vector2(-_bars[i].size.x * 0.5, bar_y) + bar_off


func _ensure_name_label() -> void:
	if not is_inside_tree():
		return
	if _name_label == null or not is_instance_valid(_name_label):
		_name_label = Label.new()
		_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_name_label.size = Vector2(300, 26)
		_name_label.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_name_label)
	_name_label.visible = show_selection_name
	if Engine.is_editor_hint():
		# Placeholder so the label can be positioned while designing.
		_name_label.text = "Item Name"
	_reposition_overlays()


func _update_name_label() -> void:
	if _name_label == null or not is_instance_valid(_name_label) or not show_selection_name:
		return
	var text := ""
	if _hovered_index >= 0 and _hovered_index < items.size() and items[_hovered_index] != null:
		text = items[_hovered_index].name
	_name_label.text = text
