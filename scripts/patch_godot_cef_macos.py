from pathlib import Path
import plistlib
import sys


ROOT = Path(__file__).resolve().parent.parent

CEF_DIR = ROOT / "godot/addons/godot_cef"
MACOS_DIR = CEF_DIR / "bin/universal-apple-darwin"

FRAMEWORK = MACOS_DIR / "Godot CEF.framework"
FRAMEWORK_PLIST = FRAMEWORK / "Resources/Info.plist"

OLD_EXECUTABLE = FRAMEWORK / "libgdcef.dylib"
NEW_EXECUTABLE = FRAMEWORK / "Godot CEF"

GDEXTENSION = CEF_DIR / "godot_cef.gdextension"

ORIGINAL_MACOS_DEPENDENCIES = """macos = {
  "bin/universal-apple-darwin/Godot CEF.framework" : "Contents/Frameworks",
  "bin/universal-apple-darwin/Godot CEF.app" : "Contents/Frameworks"
}"""

PATCHED_MACOS_DEPENDENCIES = """macos = {
  "bin/universal-apple-darwin/Godot CEF.framework" : "Contents/Frameworks"
}"""


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def patch_framework_executable() -> None:
    if NEW_EXECUTABLE.exists():
        print(f"Already patched: {NEW_EXECUTABLE}")
        return

    if not OLD_EXECUTABLE.is_file():
        fail(f"CEF framework executable not found: {OLD_EXECUTABLE}")

    OLD_EXECUTABLE.rename(NEW_EXECUTABLE)
    print(f"Renamed: {OLD_EXECUTABLE.name} -> {NEW_EXECUTABLE.name}")


def patch_framework_plist() -> None:
    if not FRAMEWORK_PLIST.is_file():
        fail(f"CEF framework Info.plist not found: {FRAMEWORK_PLIST}")

    with FRAMEWORK_PLIST.open("rb") as file:
        data = plistlib.load(file)

    data["CFBundleExecutable"] = "Godot CEF"
    data["CFBundleIdentifier"] = data.get(
        "CFBundleIdentifier",
        "me.delton.gdcef.libgdcef",
    )
    data["CFBundleInfoDictionaryVersion"] = "6.0"
    data["CFBundleName"] = "Godot CEF"
    data["CFBundlePackageType"] = "FMWK"
    data["CFBundleSupportedPlatforms"] = ["MacOSX"]

    with FRAMEWORK_PLIST.open("wb") as file:
        plistlib.dump(data, file, sort_keys=False)

    print(f"Patched: {FRAMEWORK_PLIST}")


def patch_gdextension_dependencies() -> None:
    if not GDEXTENSION.is_file():
        fail(f"GDExtension config not found: {GDEXTENSION}")

    text = GDEXTENSION.read_text(encoding="utf-8")

    if ORIGINAL_MACOS_DEPENDENCIES in text:
        text = text.replace(
            ORIGINAL_MACOS_DEPENDENCIES,
            PATCHED_MACOS_DEPENDENCIES,
            1,
        )
        GDEXTENSION.write_text(text, encoding="utf-8")
        print("Removed Godot CEF.app from macOS GDExtension dependencies.")
        return

    if PATCHED_MACOS_DEPENDENCIES in text:
        print("macOS GDExtension dependencies already patched.")
        return

    fail(
        "Unexpected macOS dependency block in godot_cef.gdextension. "
        "The installed godot-cef version may have changed."
    )


def main() -> None:
    if not FRAMEWORK.is_dir():
        fail(f"Godot CEF.framework not found: {FRAMEWORK}")

    patch_framework_executable()
    patch_framework_plist()
    patch_gdextension_dependencies()

    print("Godot CEF macOS patch complete.")


if __name__ == "__main__":
    main()
