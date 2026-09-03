extends Node

func d(a1="", a2="", a3="", a4="", a5="", a6="") -> void:
	if OS.is_debug_build():
		print(a1, a2, a3, a4, a5, a6)