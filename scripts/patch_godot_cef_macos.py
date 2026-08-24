from pathlib import Path
import plistlib
import sys


ROOT = Path(__file__).resolve().parent.parent

CEF_DIR = ROOT / "godot/addons/godot_cef"
MACOS_DIR = CEF_DIR / "bin/universal-apple-darwin"
FRAMEWORK = MACOS_DIR / "Godot CEF.framework"
PLIST = FRAMEWORK / "Resources/Info.plist"

OLD_EXECUTABLE = FRAMEWORK / "libgdcef.dylib"
NEW_EXECUTABLE = FRAMEWORK / "Godot CEF"


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
    if not PLIST.is_file():
        fail(f"CEF framework Info.plist not found: {PLIST}")

    with PLIST.open("rb") as file:
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

    with PLIST.open("wb") as file:
        plistlib.dump(data, file, sort_keys=False)

    print(f"Patched: {PLIST}")


def main() -> None:
    if not FRAMEWORK.is_dir():
        fail(f"Godot CEF.framework not found: {FRAMEWORK}")

    patch_framework_executable()
    patch_framework_plist()

    print("Godot CEF macOS framework patch complete.")


if __name__ == "__main__":
    main()
