"""Regenerate the offline fixtures with imageio-ffmpeg==0.6.0."""

from pathlib import Path
import hashlib
import json
import math
import struct
import subprocess
import wave

import imageio_ffmpeg


root = Path(__file__).resolve().parents[2]
assets = root / "examples/simple_chat/assets/compat_media"
assets.mkdir(parents=True, exist_ok=True)
with wave.open(str(assets / "tone.wav"), "wb") as output:
    output.setnchannels(1)
    output.setsampwidth(2)
    output.setframerate(22050)
    frames = (
        struct.pack("<h", int(4096 * math.sin(2 * math.pi * 440 * i / 22050)))
        for i in range(44100)
    )
    output.writeframes(b"".join(frames))
subprocess.run(
    [
        imageio_ffmpeg.get_ffmpeg_exe(), "-hide_banner", "-loglevel", "error",
        "-y", "-f", "lavfi", "-i", "color=c=blue:s=64x64:r=10", "-t", "2",
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
        str(assets / "blue.mp4"),
    ],
    check=True,
)
hashes = {
    file.name: hashlib.sha256(file.read_bytes()).hexdigest()
    for file in sorted(assets.iterdir())
}
(root / "docs/compatibility/evidence/media-fixtures.json").write_text(
    json.dumps(
        {
            "generator": "imageio-ffmpeg 0.6.0; PCM 16-bit mono 22050 Hz; 2 seconds",
            "description": "Locally generated test tone and 64x64 blue H264 video; no external resources",
            "sha256": hashes,
        },
        indent=2,
    ) + "\n",
    encoding="utf-8",
)
print("Generated offline media fixtures:", hashes)
