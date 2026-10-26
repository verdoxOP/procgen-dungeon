@tool
class_name GeneratorRunner
extends RefCounted

# Runs a generator program following the command-line contract:
#   <generator> --seed <int>
#   stdout: only the dungeon JSON      stderr: logs (ignored unless it fails)
#   exit 0 = ok, 1 = generation failed, 2 = invalid arguments
# Any language works, as long as the program sticks to this.

const EXIT_REASONS := {
	-1: "could not start the program",
	1: "generation failed",
	2: "invalid arguments",
}
# Max characters of the generator's own output shown in an error.
const MAX_DETAILS := 1500


# Generators live in a generators/ folder: in the project folder while running
# from the editor, next to the executable in an exported game.
static func generators_dir() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://").path_join("generators")
	return OS.get_executable_path().get_base_dir().path_join("generators")


# Names of the generator programs found, e.g. ["procgen-csharp", "procgen-rust"].
# Windows: <name>.exe, Linux (Pi): <name> without an extension.
static func available() -> PackedStringArray:
	var names := PackedStringArray()
	var dir := DirAccess.open(generators_dir())
	if dir == null:
		return names
	for file in dir.get_files():
		if OS.has_feature("windows"):
			if file.get_extension() == "exe":
				names.append(file.get_basename())
		elif file.get_extension() == "":
			names.append(file)
	names.sort()
	return names


static func program_path(generator_name: String) -> String:
	var file := generator_name + (".exe" if OS.has_feature("windows") else "")
	return generators_dir().path_join(file)


# Returns {"text": stdout, "process_ms": float} on success, or {"error": String}.
# OS.execute() blocks the game until the generator is done.
static func run(generator_name: String, seed_value: int) -> Dictionary:
	var path := program_path(generator_name)
	if not FileAccess.file_exists(path):
		return {"error": "Generator not found: %s" % path}

	var args := PackedStringArray(["--seed", str(seed_value)])
	var output := []
	var start := Time.get_ticks_usec()
	var code := OS.execute(path, args, output)
	var process_ms := (Time.get_ticks_usec() - start) / 1000.0

	if code != 0:
		# Run once more with stderr included, only to show the generator's own message.
		# Same seed, so it fails the same way.
		var details := []
		OS.execute(path, args, details, true)
		var text := "".join(details).strip_edges()
		if text.length() > MAX_DETAILS:
			text = "..." + text.right(MAX_DETAILS)
		return {"error": "%s exited with code %d (%s).\n%s" % [
			generator_name, code, EXIT_REASONS.get(code, "unknown error"), text]}

	return {"text": "".join(output), "process_ms": process_ms}
