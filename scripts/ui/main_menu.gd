extends Control


func _on_start_button_pressed() -> void:
	GameManager.go_to_character_select()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
