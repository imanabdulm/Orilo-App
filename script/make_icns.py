#!/usr/bin/env python3
import struct
from pathlib import Path

root = Path.cwd()
iconset = root / "Config" / "AppIcon.iconset"
output = root / "Config" / "AppIcon.icns"

chunks = [
    ("icp4", "icon_16x16.png"),
    ("icp5", "icon_32x32.png"),
    ("icp6", "icon_32x32@2x.png"),
    ("ic07", "icon_128x128.png"),
    ("ic08", "icon_256x256.png"),
    ("ic09", "icon_512x512.png"),
    ("ic10", "icon_512x512@2x.png"),
]

body = bytearray()
for icon_type, filename in chunks:
    data = (iconset / filename).read_bytes()
    body.extend(icon_type.encode("ascii"))
    body.extend(struct.pack(">I", len(data) + 8))
    body.extend(data)

output.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)
