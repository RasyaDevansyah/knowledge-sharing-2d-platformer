@tool
class_name ItemWheelItem
extends Resource
## A single selectable entry in an [ItemWheel].
##
## Save instances of this resource as [code].tres[/code] files to reuse them
## across multiple wheels, or create them inline in the Inspector.

## Icon drawn at the centre of this item's wheel segment.
@export var icon: Texture2D:
	set(value):
		icon = value
		emit_changed()

## Scale multiplier for this item's icon. Icons are fitted into the wheel's
## icon_size box with their aspect ratio preserved, then scaled by this value.
@export_range(0.05, 10.0, 0.05) var icon_scale: float = 1.0:
	set(value):
		icon_scale = value
		emit_changed()

## Override the wheel's icon_size fit box for this item.
@export var override_icon_size: bool = false:
	set(value):
		override_icon_size = value
		emit_changed()

## Fit box used when override_icon_size is on (aspect ratio still preserved).
@export var icon_size: Vector2 = Vector2(48, 48):
	set(value):
		icon_size = value
		emit_changed()

## The item's name, shown under the icon when display_name is on.
@export var name: String = "":
	set(value):
		name = value
		emit_changed()

## Show the name under the icon on this item's segment.
@export var display_name: bool = true:
	set(value):
		display_name = value
		emit_changed()

## When true this segment is greyed out and cannot be selected.
@export var disabled: bool = false:
	set(value):
		disabled = value
		emit_changed()

@export_group("Segment Appearance")
## Optional texture drawn over this item's wedge instead of the flat fill color.
@export var segment_texture: Texture2D:
	set(value):
		segment_texture = value
		emit_changed()

## When true, [member segment_color] replaces the wheel's background color
## for this segment (ignored while [member segment_texture] is set).
@export var override_segment_color: bool = false:
	set(value):
		override_segment_color = value
		emit_changed()

## Per-segment fill color, used when [member override_segment_color] is on.
@export var segment_color: Color = Color(0.2, 0.2, 0.2, 0.85):
	set(value):
		segment_color = value
		emit_changed()

@export_group("Display Offsets")
## Pixel offset applied to the icon, relative to the segment's centre.
@export var icon_offset: Vector2 = Vector2.ZERO:
	set(value):
		icon_offset = value
		emit_changed()

## Pixel offset applied to the label.
@export var label_offset: Vector2 = Vector2.ZERO:
	set(value):
		label_offset = value
		emit_changed()

## Pixel offset applied to the progress bar.
@export var progress_bar_offset: Vector2 = Vector2.ZERO:
	set(value):
		progress_bar_offset = value
		emit_changed()

@export_group("Progress Bar")
## Show a small progress bar under the item (useful for ammo, charges, cooldowns).
@export var show_progress_bar: bool = false:
	set(value):
		show_progress_bar = value
		emit_changed()

## Current value of the progress bar.
@export var progress_value: float = 1.0:
	set(value):
		progress_value = value
		emit_changed()

## Maximum value of the progress bar.
@export var progress_max: float = 1.0:
	set(value):
		progress_max = value
		emit_changed()
