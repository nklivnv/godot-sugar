@abstract
extends Object
class_name Runtime


enum Mode {
	NONE           = 0,
	
	EDITOR_ONLY    = 1 << 0,                          # 0001
	EDITOR_PLAYING = 1 << 1,                          # 0010
	EDITOR_ANY     = EDITOR_ONLY    | EDITOR_PLAYING, # 0011
	
	BUILD_DEBUG    = 1 << 2,                          # 0100
	BUILD_RELEASE  = 1 << 3,                          # 1000
	BUILD_ANY      = BUILD_DEBUG    | BUILD_RELEASE,  # 1100
	
	DEBUG_PLAYING  = EDITOR_PLAYING | BUILD_DEBUG,    # 0110
	DEBUG_ANY      = BUILD_DEBUG    | EDITOR_ANY,     # 0111
	PLAYING        = BUILD_ANY      | EDITOR_PLAYING, # 1110
	
	ALWAYS         = EDITOR_ANY     | BUILD_ANY,      # 1111
}


static func get_mask() -> Mode:
	if Engine.is_editor_hint():  return Mode.EDITOR_ONLY
	if OS.has_feature("editor"): return Mode.EDITOR_PLAYING
	if OS.is_debug_build():      return Mode.BUILD_DEBUG
	return                              Mode.BUILD_RELEASE

static func is_valid_mode(allowed: Mode) -> bool: return (allowed & get_mask()) != 0


#static func is_runtime_mode(editor: bool = true, editor_play: bool = true, debug_build: bool = true, release_build: bool = true) -> bool:
	#if Engine.is_editor_hint(): return editor
	#if OS.has_feature("editor"): return editor_play
	#if OS.is_debug_build(): return debug_build
	#return release_build



## Для запуска тяжелых функций внутри _process

## (<=0) => 0, 1, 2, 3...
##   (1) => 0, 2, 4, 6...
##   (2) => 0, 3, 6, 9...
static func _is_frame_active(skip_frames: int, frames_drawn: int) -> bool:
	return true if skip_frames <= 0 else frames_drawn % (skip_frames + 1) == 0

static func is_process_frame_active(skip_frames: int = 0, offset: int = 0) -> bool: 
	return _is_frame_active(skip_frames, offset + Engine.get_process_frames())

static func is_physics_frame_active(skip_frames: int = 0, offset: int = 0) -> bool: 
	return _is_frame_active(skip_frames, offset + Engine.get_physics_frames())
