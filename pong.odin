package main

import "core:math"
import "core:math/linalg"
import "vendor:raylib"

GAME: struct {
	player_left, player_right:             f32,
	player_left_score, player_right_score: int,
	ball_position, ball_direction:         raylib.Vector2,
}

SCREEN_W :: 1200; SCREEN_H :: 800
PLAYER_W :: 30;   PLAYER_H :: 120
BALL_W   :: 20;   BALL_H :: 20

PLAYER_SPEED :: SCREEN_H / 1.5
BALL_SPEED   :: SCREEN_W / 2

BOUNCE_ANGLE :: raylib.PI / 3
BALL_CENTER  :: raylib.Vector2{(SCREEN_W - BALL_W) / 2, (SCREEN_H - BALL_H) / 2}

InitGame :: proc() {
	GAME = {
		player_left = (SCREEN_H - PLAYER_H) / 2,
		player_right = (SCREEN_H - PLAYER_H) / 2,
		ball_position = BALL_CENTER,
		ball_direction = {-1, 0},
	}
}

PaddleHitRange :: proc(player: f32) -> f32 {
	ball_center   := GAME.ball_position.y + BALL_H / 2
	player_center := player + PLAYER_H / 2
	range         := ball_center - player_center // [-PLAYER_H/2, PLAYER_H/2]
	return range / (PLAYER_H / 2) // [-1, 1]
}

PlayerLeftRectangle :: proc() -> raylib.Rectangle {
	return {0, GAME.player_left, PLAYER_W, PLAYER_H}
}

PlayerRightRectangle :: proc() -> raylib.Rectangle {
	return {SCREEN_W - PLAYER_W, GAME.player_right, PLAYER_W, PLAYER_H}
}

BallRectangle :: proc() -> raylib.Rectangle {
	return {GAME.ball_position.x, GAME.ball_position.y, BALL_W, BALL_H}
}

UpdateDrawFrame :: proc() {
	using raylib
	using GAME

	player_distance_travelled := GetFrameTime() * PLAYER_SPEED
	if (IsKeyDown(.W)) {
		player_left = clamp(player_left - player_distance_travelled, 0, SCREEN_H - PLAYER_H)
	}
	if (IsKeyDown(.S)) {
		player_left = clamp(player_left + player_distance_travelled, 0, SCREEN_H - PLAYER_H)
	}
	if (IsKeyDown(.DOWN)) {
		player_right = clamp(player_right + player_distance_travelled, 0, SCREEN_H - PLAYER_H)
	}
	if (IsKeyDown(.UP)) {
		player_right = clamp(player_right - player_distance_travelled, 0, SCREEN_H - PLAYER_H)
	}

	ball_distance_travelled := GetFrameTime() * BALL_SPEED * ball_direction
	ball_position = linalg.clamp(
		ball_position + ball_distance_travelled,
		Vector2{0, 0},
		Vector2{SCREEN_W - BALL_W, SCREEN_H - BALL_H},
	)

	ball_passed_left  := ball_position.x == 0
	ball_passed_right := ball_position.x + BALL_W == SCREEN_W

	ball_hit_top      := ball_position.y == 0
	ball_hit_bottom   := ball_position.y + BALL_H == SCREEN_H

	player_left_hit :=
		ball_direction.x < 0 && CheckCollisionRecs(PlayerLeftRectangle(), BallRectangle())

	player_right_hit :=
		ball_direction.x > 0 && CheckCollisionRecs(PlayerRightRectangle(), BallRectangle())

	switch {
	case ball_passed_left:
		player_right_score += 1
		ball_position = BALL_CENTER
		ball_direction = {-1, 0}

	case ball_passed_right:
		player_left_score += 1
		ball_position = BALL_CENTER
		ball_direction = {1, 0}

	case ball_hit_top:
		ball_direction = linalg.reflect(ball_direction, Vector2{0, 1})

	case ball_hit_bottom:
		ball_direction = linalg.reflect(ball_direction, Vector2{0, -1})

	case player_left_hit:
		range := PaddleHitRange(player_left)
		ball_direction = {math.cos(range * BOUNCE_ANGLE), math.sin(range * BOUNCE_ANGLE)}

	case player_right_hit:
		range := PaddleHitRange(player_right)
		ball_direction = {-math.cos(range * BOUNCE_ANGLE), math.sin(range * BOUNCE_ANGLE)}
	}

	BeginDrawing();{
		ClearBackground(BLACK)

		DrawLine(SCREEN_W / 2, 0, SCREEN_W / 2, SCREEN_H, RAYWHITE)

		DrawText(TextFormat("%d", player_left_score), SCREEN_W / 4, 10, 32, RAYWHITE)
		DrawText(TextFormat("%d", player_right_score), 3 * SCREEN_W / 4, 10, 32, RAYWHITE)

		DrawRectangleRec(PlayerLeftRectangle(), RAYWHITE)
		DrawRectangleRec(PlayerRightRectangle(), RAYWHITE)
		DrawRectangleRec(BallRectangle(), LIGHTGRAY)
	}
	EndDrawing()
}

main :: proc() {
	using raylib

	SetTraceLogLevel(.WARNING)
	SetTargetFPS(60)

	InitWindow(SCREEN_W, SCREEN_H, "Pong")
	defer CloseWindow()

	InitGame()

	for !WindowShouldClose() do UpdateDrawFrame()
}
