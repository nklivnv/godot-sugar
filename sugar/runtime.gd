@abstract
extends Object
class_name Runtime


enum Mode {
	NONE          = 0,
	
	EDITOR_ONLY   = 1 << 0,                      # 0001
	EDITOR_PLAY   = 1 << 1,                      # 0010
	EDITOR_ANY    = EDITOR_ONLY | EDITOR_PLAY,   # 0011
	
	BUILD_DEBUG   = 1 << 2,                      # 0100
	BUILD_RELEASE = 1 << 3,                      # 1000
	BUILD_ANY     = BUILD_DEBUG | BUILD_RELEASE, # 1100
	
	PLAY          = EDITOR_PLAY | BUILD_ANY,     # 1110
	ALL           = EDITOR_ANY  | BUILD_ANY,     # 1111
}


static func get_mode() -> Mode:
	if Engine.is_editor_hint():  return Mode.EDITOR_ONLY
	if OS.has_feature("editor"): return Mode.EDITOR_PLAY
	if OS.is_debug_build():      return Mode.BUILD_DEBUG
	return                              Mode.BUILD_RELEASE

static func is_mode(allowed: Mode) -> bool: return (allowed & get_mode()) != 0


#static func is_runtime_mode(editor: bool = true, editor_play: bool = true, debug_build: bool = true, release_build: bool = true) -> bool:
	#if Engine.is_editor_hint(): return editor
	#if OS.has_feature("editor"): return editor_play
	#if OS.is_debug_build(): return debug_build
	#return release_build
