extends Control


func _on_retry_button_pressed() -> void:
	GameManager.start_game()


func _on_menu_button_pressed() -> void:
	GameManager.go_to_main_menu()
