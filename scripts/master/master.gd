extends Node

var p1_score = 0 # Player 1 score
var p2_score = 0 # Player 2 score

const MATCH_DURATION = 120 # Length of a match in seconds
const RESULT_LOCK_TIME = 1.5 # Ignore input this long after the result shows
const RESULT_TIMEOUT = 15 # Go back to the main menu automatically after this

var time_left = MATCH_DURATION
var sudden_death = false # Time is up with a tie: the next goal wins
var match_over = false
var result_time = 0.0 # Time since the result screen was shown
var players = 2

onready var music = get_node("sounds/music")

signal show_pause_menu

func _ready():

	set_labels_scores()
	set_clock_label()
	$ball.start()

func init(args):

	players = args.players

	if args.players == 1:

		$player_2.set_mode(args.cpu_mode)

	elif args.players == 2:

		# Add to the second platform a controlled player script
		var player_script = load("res://scripts/master/player.gd")
		$player_2.set_script(player_script)
		$player_2.set_input_actions("p2_up", "p2_down")

func _process(delta):

	if match_over:

		result_time += delta

		if result_time > RESULT_TIMEOUT or (result_time > RESULT_LOCK_TIME and \
				(Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"))):

			set_process(false)
			SceneManager.goto_scene("res://scenes/main_menu.tscn")

		return

	if Input.is_action_just_pressed("ui_cancel"):

		pause()
		return

	if not sudden_death:

		time_left = max(time_left - delta, 0)

		if time_left == 0:

			if p1_score == p2_score: sudden_death = true
			else: end_match()

		set_clock_label()

func set_clock_label():

	if match_over:

		$background/clock.set_text("time up")
		return

	if sudden_death:

		$background/clock.set_text("sudden death")
		return

	var seconds = int(ceil(time_left))
	$background/clock.set_text("%d:%02d" % [seconds / 60, seconds % 60])

func check_match_end():

	# Called after every goal: in sudden death the goal decides the match
	if sudden_death: end_match()

func end_match():

	match_over = true
	result_time = 0.0

	# Freeze the field
	for node in [$ball, $player_1, $player_2]: node.set_process(false)
	$ball.visible = false

	var winner
	if p1_score > p2_score: winner = "player 1"
	elif players == 1: winner = "cpu"
	else: winner = "player 2"

	set_clock_label()
	$match_over/lines/winner.set_text(winner + " wins")
	$match_over/lines/score.set_text("%d - %d" % [p1_score, p2_score])
	$match_over.visible = true

	# Machine-readable result on stdout, for anything watching the game
	print("MATCH_RESULT winner=%s p1=%d p2=%d" % [winner.replace(" ", ""), p1_score, p2_score])

func set_labels_scores():

	$background/p1_score.set_text(str(p1_score))
	$background/p2_score.set_text(str(p2_score))

func pause():

	emit_signal("show_pause_menu")
	music.stream_paused = true
	set_process(false)

############# Signals #############

func _on_door_1_body_exited(body):

	# This function is called when the ball
	# hit the door of the first player

	if "ball" in body.name and not match_over:

		p2_score += 1
		$ball.start()
		set_labels_scores()
		$"sounds/goal".play()
		$"background/animations".play("p2_score_increase")
		check_match_end()

func _on_door_2_body_exited(body):

	# The same thing of the upper function
	# but with the door of the second player

	if "ball" in body.name and not match_over:

		p1_score += 1
		$ball.start()
		set_labels_scores()
		$"sounds/goal".play()
		$"background/animations".play("p1_score_increase")
		check_match_end()

func _on_pause_menu_hidden_pause_menu():

	music.stream_paused = false
	set_process(true)

func _notification(what):

	if what == NOTIFICATION_WM_FOCUS_OUT and not match_over: pause()
