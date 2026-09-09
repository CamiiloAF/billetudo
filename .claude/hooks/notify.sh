#!/usr/bin/env python3
"""macOS desktop notification + sound for Claude Code hooks."""
import json
import os
import subprocess
import sys


def esc_applescript(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def notify(title: str, message: str, sound: str) -> None:
    script = (
        f'display notification "{esc_applescript(message)}" '
        f'with title "{esc_applescript(title)}" sound name "{sound}"'
    )
    subprocess.run(["osascript", "-e", script], check=False)
    sound_path = f"/System/Library/Sounds/{sound}.aiff"
    if os.path.isfile(sound_path):
        subprocess.Popen(
            ["afplay", sound_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else "attention"
    raw = sys.stdin.read()
    data = json.loads(raw) if raw.strip() else {}

    if mode == "done":
        title = "Claude Code — done"
        last = (data.get("last_assistant_message") or "").strip()
        if last:
            preview = last.replace("\n", " ")[:100]
            message = f"Turn finished: {preview}…"
        else:
            message = "Turn finished — ready for your next prompt"
        sound = "Hero"
    else:
        title = data.get("title") or "Claude Code"
        message = data.get("message") or "Needs your attention"
        ntype = data.get("notification_type") or ""
        if ntype == "permission_prompt":
            sound = "Ping"
        elif ntype == "idle_prompt":
            sound = "Glass"
        else:
            sound = "Submarine"

    notify(title, message, sound)


if __name__ == "__main__":
    main()
