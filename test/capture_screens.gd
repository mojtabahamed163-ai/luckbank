extends SceneTree

const OUTPUT_DIR := "/home/ubuntu/luckbank-delivery/screenshots"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var packed: PackedScene = load("res://scenes/main.tscn")
	var app: Control = packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	app.locale = "ar"
	app.locale_data = app.catalogs["ar"]
	app._show_home()
	await _settle()
	await _capture(app, "01-home-landscape.png")

	app._show_setup()
	await process_frame
	app.mode_option.select(1)
	app.player_count_option.select(2)
	app.duration_option.select(0)
	app._on_setup_changed(2)
	await process_frame
	await _capture(app, "02-setup-landscape.png")

	seed(20261024)
	app._start_match()
	await _settle()
	assert(app.tile_buttons.size() == 40)
	await _capture(app, "03-board-landscape.png")

	await app._on_roll_pressed()
	await _settle()
	print("[capture] dice=%d, landing=%d, phase=%s" % [int(app.game.state["last_dice"]), int(app.game.state["current_tile"]), str(app.game.state["phase"])])
	await _capture(app, "04-during-play-landscape.png")

	if int(app.game.state.get("pending_property", -1)) >= 0:
		app._perform_buy()
		await _settle()
		await _capture(app, "05-after-purchase-landscape.png")
	else:
		app._show_market()
		await _settle()
		await _capture(app, "05-market-landscape.png")

	print("[capture] saved landscape screenshots in " + OUTPUT_DIR)
	app.queue_free()
	quit()

func _settle() -> void:
	await process_frame
	await process_frame
	await create_timer(0.2).timeout

func _capture(app: Control, filename: String) -> void:
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	var error := image.save_png(OUTPUT_DIR.path_join(filename))
	if error != OK:
		push_error("Could not save %s: %s" % [filename, error_string(error)])
	else:
		print("[capture] %s (%dx%d) screen=%s" % [filename, image.get_width(), image.get_height(), str(app.screen_name)])