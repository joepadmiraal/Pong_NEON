#!/bin/bash
cd /home/arcade/games/pong_neon/game
# Godot 3 GLES3 asks for a GL 3.3 core context; the Pi 5 V3D driver reports 3.1
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLSL_VERSION_OVERRIDE=330
exec godot3 --path . --fullscreen "$@"
