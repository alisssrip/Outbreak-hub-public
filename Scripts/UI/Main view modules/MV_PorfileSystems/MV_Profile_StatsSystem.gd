class_name MV_Profile_StatsSystem
extends Node

@export var most_used_label : Label
@export var time_label : Label
@export var hits_label : Label
@export var shots_label : Label
@export var points_label : Label
@export var deaths_label : Label

func set_stats(most_used_char: int, time_seconds: int, hits: int, shots: int, points: int, deaths: int) -> void:
	if most_used_char < 0:
		most_used_label.text = tr("STATS_MUC") % "---"
	else:
		most_used_label.text = tr("STATS_MUC") % OutbreakMeta.character_name(most_used_char)
	time_label.text = tr("STATS_TIME") % _format_time(time_seconds)
	hits_label.text = tr("STATS_HITS") % hits
	shots_label.text = tr("STATS_SHOTS") % shots
	points_label.text = tr("STATS_POINTS") % points
	deaths_label.text = tr("STATS_DEATHS") % deaths

func _format_time(seconds: int) -> String:
	var hours := seconds / 3600.0
	return "%.1fh" % hours
