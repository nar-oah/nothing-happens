from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parent.parent

CEF_APP_SOURCE = (
    ROOT / "godot/addons/godot_cef/bin/universal-apple-darwin/Godot CEF.app"
)

ENTITLEMENTS = ROOT / "scripts/macos-ad-hoc.entitlements.plist"


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def run(*args: str | Path) -> None:
    command = [str(arg) for arg in args]
    print("+", " ".join(command))
    subprocess.run(command, check=True)


def find_exported_app(directory: Path) -> Path:
    apps = list(directory.glob("*.app"))

    if not apps:
        apps = list(directory.glob("*/*.app"))

    if len(apps) != 1:
        fail(f"Expected exactly one exported .app, found {len(apps)} in {directory}")

    return apps[0]


def sign_bundle(path: Path, *, entitlements: bool = False) -> None:
    command: list[str | Path] = [
        "codesign",
        "--force",
        "--sign",
        "-",
    ]

    if entitlements:
        command.extend(
            [
                "--entitlements",
                ENTITLEMENTS,
            ]
        )

    command.append(path)
    run(*command)


def main() -> None:
    if sys.platform != "darwin":
        fail("macOS export post-processing must run on macOS.")

    if len(sys.argv) not in (2, 3):
        fail(
            "Usage: python3 scripts/postprocess_macos_export.py "
            "<input.zip> [output.zip]"
        )

    input_zip = Path(sys.argv[1]).resolve()

    if len(sys.argv) == 3:
        output_zip = Path(sys.argv[2]).resolve()
    else:
        output_zip = input_zip.with_name(f"{input_zip.stem}-signed.zip")

    if not input_zip.is_file():
        fail(f"Input ZIP does not exist: {input_zip}")

    if not CEF_APP_SOURCE.is_dir():
        fail(f"Godot CEF.app does not exist: {CEF_APP_SOURCE}")

    if not ENTITLEMENTS.is_file():
        fail(f"Entitlements file does not exist: {ENTITLEMENTS}")

    with tempfile.TemporaryDirectory(prefix="nothing-happens-macos-") as temp:
        temp_dir = Path(temp)

        run(
            "ditto",
            "-x",
            "-k",
            input_zip,
            temp_dir,
        )

        app = find_exported_app(temp_dir)

        frameworks_dir = app / "Contents/Frameworks"
        frameworks_dir.mkdir(parents=True, exist_ok=True)

        cef_app = frameworks_dir / "Godot CEF.app"

        if cef_app.exists():
            shutil.rmtree(cef_app)

        run(
            "ditto",
            CEF_APP_SOURCE,
            cef_app,
        )

        cef_frameworks = sorted((cef_app / "Contents/Frameworks").glob("*.framework"))

        for framework in cef_frameworks:
            sign_bundle(framework)

        cef_helpers = sorted((cef_app / "Contents/Frameworks").glob("*.app"))

        for helper in cef_helpers:
            sign_bundle(helper, entitlements=True)

        sign_bundle(cef_app, entitlements=True)

        godot_cef_framework = frameworks_dir / "Godot CEF.framework"

        if not godot_cef_framework.is_dir():
            fail(f"Exported Godot CEF.framework was not found: {godot_cef_framework}")

        sign_bundle(godot_cef_framework)

        sign_bundle(app, entitlements=True)

        run(
            "codesign",
            "--verify",
            "--deep",
            "--strict",
            "--verbose=4",
            app,
        )

        if output_zip.exists():
            output_zip.unlink()

        run(
            "ditto",
            "-c",
            "-k",
            "--sequesterRsrc",
            "--keepParent",
            app,
            output_zip,
        )

    print(f"Finished: {output_zip}")


if __name__ == "__main__":
    main()
