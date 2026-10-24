#!/bin/bash
cd /home/arcade/games/pong_neon/game
# X picks the TV's 120Hz mode; with vsync that doubles the GPU work for no gain
OUTPUT=$(xrandr | awk '/ connected/ {print $1; exit}')
[ -n "$OUTPUT" ] && xrandr --output "$OUTPUT" --mode 1920x1080 --rate 60
# Godot 3 GLES3 asks for a GL 3.3 core context; the Pi 5 V3D driver reports 3.1
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLSL_VERSION_OVERRIDE=330
exec godot3 --path . --fullscreen "$@"
