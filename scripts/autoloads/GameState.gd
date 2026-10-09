extends Node

var current_level: int = 50

func is_unlocked(i: int) -> bool:
	return i <= current_level

func is_completed(i: int) -> bool:
	return i < current_level
