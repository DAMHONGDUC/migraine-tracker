#!/usr/bin/env python3
"""Export the licensed scan as 15 pickable regions. Python standard library only.

Run `python3 tool/head_model.py`; source attribution is in head_model/README.md.
The scan owns the face. This exporter only crops, partitions and normalizes it.
"""
import hashlib
import json
import math
import os
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'tool/head_model/source/LeePerrySmith.glb'
SOURCE_SHA256 = '402b8a8ac9f03232e6d64b5962929703a069daf99d3c49ac8eb0e48bedc9c576'
REGIONS = ['crown', 'foreheadL', 'foreheadR', 'templeL', 'templeR', 'eyeL',
           'nose', 'eyeR', 'cheekL', 'cheekR', 'jawL', 'jawR',
           'occipitalL', 'occipitalR', 'nape']
# Planes use the original scan coordinates, before normalization.
CUT = (0, 1, 0.4, -0.1)
HEIGHTS = [2.8, 2.15, 1.85, 1.65, 0.85, 1.05, 0.55, 0.45, 0]
TEMPLE_TAN = math.tan(math.radians(50))
PLANES = [(0, 1, 0, -y) for y in HEIGHTS] + [
    (1, 0, 0, 0.08), (0, 0, 1, -0.1),
    (1, 0, -TEMPLE_TAN, 0.08 + TEMPLE_TAN*0.1),
    (1, 0, TEMPLE_TAN, 0.08 - TEMPLE_TAN*0.1),
    (1, 0, 0, 0.43), (1, 0, 0, -0.27)]


def source_mesh():
    data = SOURCE.read_bytes()
    if hashlib.sha256(data).hexdigest() != SOURCE_SHA256:
        raise ValueError('Source scan changed; verify attribution and coordinates before exporting')
    length = struct.unpack_from('<I', data, 12)[0]
    gltf = json.loads(data[20:20+length])
    binary = data[28+length:]

    def accessor(index):
        a = gltf['accessors'][index]
        v = gltf['bufferViews'][a['bufferView']]
        fmt = {5123: 'H', 5126: 'f'}[a['componentType']] * {'SCALAR': 1, 'VEC3': 3}[a['type']]
        start = v.get('byteOffset', 0) + a.get('byteOffset', 0)
        return list(struct.iter_unpack('<'+fmt, binary[start:start+a['count']*struct.calcsize(fmt)]))

    positions, normals = accessor(1), accessor(2)
    return [tuple(p)+tuple(n) for p, n in zip(positions, normals)], [v[0] for v in accessor(0)]


def distance(v, plane):
    return sum(v[i]*plane[i] for i in range(3)) + plane[3]


def clip(poly, plane):
    result = []
    for a, b in zip(poly, poly[1:]+poly[:1]):
        da, db = distance(a, plane), distance(b, plane)
        if da >= -1e-9:
            result.append(a)
        if (da > 1e-9 and db < -1e-9) or (da < -1e-9 and db > 1e-9):
            t = da/(da-db)
            result.append(tuple(a[i]+t*(b[i]-a[i]) for i in range(6)))
    return result


def region_at(p):
    x, y, z = p[:3]
    x += 0.08
    lon = math.degrees(math.atan2(x, z-0.1))
    side = 'L' if x < 0 else 'R'
    if y >= 2.8:
        return 'crown'
    if abs(lon) > 90:
        return 'nape' if y < 1.05 else 'occipital'+side
    if 0.45 <= y < 1.85 and abs(x) < 0.35:
        return 'nose'
    if 0.55 <= y < 2.15 and abs(lon) > 50:
        return 'temple'+side
    if y >= 1.65:
        return 'forehead'+side
    if y >= 0.85:
        return 'eye'+side
    return ('cheek' if y >= 0 else 'jaw')+side


def build_model():
    vertices, indices = source_mesh()
    polygons, rim = [], {}
    for start in range(0, len(indices), 3):
        poly = clip([vertices[i] for i in indices[start:start+3]], CUT)
        if len(poly) < 3:
            continue
        polygons.append(poly)
        for v in poly:
            if abs(distance(v, CUT)) < 1e-6:
                rim[tuple(round(c, 7) for c in v[:3])] = v[:3]
    # Close the cropped underside so pitching cannot expose a hollow shell.
    edge = list(rim.values())
    center = tuple(sum(v[i] for v in edge)/len(edge) for i in range(3))
    edge.sort(key=lambda v: math.atan2(v[2]-center[2], v[0]-center[0]))
    normal = (0, -1/math.sqrt(1+0.4**2), -0.4/math.sqrt(1+0.4**2))
    for a, b in zip(edge, edge[1:]+edge[:1]):
        polygons.append([center+normal, a+normal, b+normal])

    meshes = {r: {'pos': [], 'nrm': [], 'tri': [], 'lookup': {}} for r in REGIONS}
    for original in polygons:
        pieces = [original]
        labels = {region_at(v) for v in original}
        labels.add(region_at(tuple(sum(v[i] for v in original)/len(original) for i in range(3))))
        for plane in (PLANES if len(labels) > 1 else []):
            next_pieces = []
            for poly in pieces:
                ds = [distance(v, plane) for v in poly]
                if min(ds) < -1e-8 and max(ds) > 1e-8:
                    for half in (plane, tuple(-c for c in plane)):
                        part = clip(poly, half)
                        if len(part) >= 3:
                            next_pieces.append(part)
                else:
                    next_pieces.append(poly)
            pieces = next_pieces
        for poly in pieces:
            center = tuple(sum(v[i] for v in poly)/len(poly) for i in range(3))
            mesh = meshes[region_at(center)]
            face = []
            for v in poly:
                length = math.sqrt(sum(n*n for n in v[3:])) or 1
                pos = ((v[0]+0.08)*46, (v[1]-1.58)*46, (v[2]-0.1)*46)
                nrm = tuple(n/length for n in v[3:])
                key = tuple(round(c, 7) for c in pos+nrm)
                if key not in mesh['lookup']:
                    mesh['lookup'][key] = len(mesh['pos'])
                    mesh['pos'].append(pos)
                    mesh['nrm'].append(nrm)
                face.append(mesh['lookup'][key])
            for i in range(1, len(face)-1):
                if len({face[0], face[i], face[i+1]}) == 3:
                    mesh['tri'].extend([face[0], face[i], face[i+1]])
    return meshes


# --- glTF ------------------------------------------------------------------

SCALE = 0.01   # design units to metres: a 2.23 unit head reads as a 2m prop


def write_glb(path, meshes, features):
    buffer = bytearray()
    views, accessors, gltf_meshes, nodes = [], [], [], []

    def add_view(data, target):
        while len(buffer) % 4:
            buffer.append(0)
        views.append({"buffer": 0, "byteOffset": len(buffer),
                      "byteLength": len(data), "target": target})
        buffer.extend(data)
        return len(views) - 1

    def add_mesh(name, pos, nrm, tri, material):
        flat = [c * SCALE for p in pos for c in p]
        lo = [min(flat[i::3]) for i in range(3)]
        hi = [max(flat[i::3]) for i in range(3)]

        p_view = add_view(struct.pack("<%df" % len(flat), *flat), 34962)
        n_view = add_view(struct.pack("<%df" % (len(nrm) * 3),
                                      *[c for n in nrm for c in n]), 34962)
        i_view = add_view(struct.pack("<%dI" % len(tri), *tri), 34963)

        accessors.append({"bufferView": p_view, "componentType": 5126,
                          "count": len(pos), "type": "VEC3",
                          "min": lo, "max": hi})
        accessors.append({"bufferView": n_view, "componentType": 5126,
                          "count": len(nrm), "type": "VEC3"})
        accessors.append({"bufferView": i_view, "componentType": 5125,
                          "count": len(tri), "type": "SCALAR"})

        gltf_meshes.append({"name": name, "primitives": [{
            "attributes": {"POSITION": len(accessors) - 3,
                           "NORMAL": len(accessors) - 2},
            "indices": len(accessors) - 1, "material": material}]})
        nodes.append({"name": name, "mesh": len(gltf_meshes) - 1})
        return len(nodes) - 1

    children = [add_mesh("region_" + name, meshes[name]["pos"],
                         meshes[name]["nrm"], meshes[name]["tri"], 0)
                for name in REGIONS]

    nodes.append({"name": "head", "children": children})

    gltf = {
        "asset": {"version": "2.0", "generator": "BaroEase trimmed Lee Perry-Smith scan / CC BY 3.0", "copyright": "Infinite, 3D Head Scan by Lee Perry-Smith / triplegangers.com. CC BY 3.0. Modified: head crop, region partition, normals and materials."},
        "scene": 0,
        "scenes": [{"nodes": [len(nodes) - 1]}],
        "nodes": nodes,
        "meshes": gltf_meshes,
        "accessors": accessors,
        "bufferViews": views,
        "buffers": [{"byteLength": len(buffer)}],
        "materials": [
            {"name": "region", "pbrMetallicRoughness": {
                "baseColorFactor": [0.173, 0.173, 0.180, 1.0],
                "metallicFactor": 0.0, "roughnessFactor": 0.9}},
            {"name": "feature", "pbrMetallicRoughness": {
                "baseColorFactor": [0.62, 0.61, 0.65, 1.0],
                "metallicFactor": 0.0, "roughnessFactor": 1.0}},
        ],
    }

    json_chunk = json.dumps(gltf, separators=(",", ":")).encode()
    json_chunk += b" " * (-len(json_chunk) % 4)
    bin_chunk = bytes(buffer) + b"\0" * (-len(buffer) % 4)

    total = 12 + 8 + len(json_chunk) + 8 + len(bin_chunk)
    with open(path, "wb") as out:
        out.write(struct.pack("<III", 0x46546C67, 2, total))
        out.write(struct.pack("<II", len(json_chunk), 0x4E4F534A) + json_chunk)
        out.write(struct.pack("<II", len(bin_chunk), 0x004E4942) + bin_chunk)

    return total


# --- The preview -----------------------------------------------------------
# A software rasteriser, because the question this script exists to answer —
# does a parametric head beat the SVG — must be answerable before a package,
# an SDK bump or a line of Dart is spent on it.

BACKGROUND = (0x0E, 0x0E, 0x10)          # AppColors.background
SKIN = (0xB4, 0xB2, 0xBA)                # only for judging the form
SURFACE = (0x2C, 0x2C, 0x2E)             # AppColors.surfaceElevated
PRIMARY = (0xA5, 0x94, 0xF9)             # AppColors.primary
FEATURE = (0x9E, 0x9C, 0xA6)             # AppColors.textSecondary

CELL_W, CELL_H = 300, 372
CAMERA_Z = 700.0
FOCAL = 900.0


SELECTED_MIX = 0.55


def _selected_tint():
    """What a picked area is painted: the accent mixed INTO the surface, not
    laid over it. The flat diagram filled at 0.45 alpha for the same reason — a
    solid accent block reads as a sticker stuck on a head."""
    return tuple(
        int(SURFACE[i] * (1 - SELECTED_MIX) + PRIMARY[i] * SELECTED_MIX)
        for i in range(3)
    )


def _region_tint(name, index):
    """Every area its own shade, so the cuts can be read off the picture. Not
    what ships — the app tints the picked areas only."""
    hue = (index * 0.618033) % 1.0
    r, g, b = [max(0.0, min(1.0, abs(((hue + off) % 1.0) * 6.0 - 3.0) - 1.0))
               for off in (0.0, 2.0 / 3.0, 1.0 / 3.0)]
    mix = 0.55
    return tuple(int(SURFACE[i] * (1 - mix) + c * 255 * mix)
                 for i, c in enumerate((r, g, b)))


def render(triangles, yaw, tinted):
    pixels = bytearray(BACKGROUND * (CELL_W * CELL_H))
    depth = [1e30] * (CELL_W * CELL_H)
    cos_y, sin_y = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    light = (-0.35, 0.45, 0.82)
    light_len = math.sqrt(sum(c * c for c in light))
    light = tuple(c / light_len for c in light)

    for (a, b, c), normals, colour in triangles:
        def turn(p):
            return (p[0] * cos_y + p[2] * sin_y, p[1],
                    -p[0] * sin_y + p[2] * cos_y)

        pa, pb, pc = turn(a), turn(b), turn(c)
        na, nb, nc = turn(normals[0]), turn(normals[1]), turn(normals[2])
        face = ((pb[0] - pa[0]) * (pc[1] - pa[1]) - (pb[1] - pa[1]) * (pc[0] - pa[0]),
                (pb[1] - pa[1]) * (pc[2] - pa[2]) - (pb[2] - pa[2]) * (pc[1] - pa[1]),
                (pb[2] - pa[2]) * (pc[0] - pa[0]) - (pb[0] - pa[0]) * (pc[2] - pa[2]))
        if face[1] * 0 + (na[2] + nb[2] + nc[2]) <= 0.03:
            continue

        def project(p):
            d = CAMERA_Z - p[2]
            # Minus, because flutter_scene's camera puts +X on the screen's
            # LEFT. A preview that disagrees is a preview of a different head.
            return (CELL_W / 2 - FOCAL * p[0] / d,
                    CELL_H / 2 - FOCAL * p[1] / d, d)

        sa, sb, sc = project(pa), project(pb), project(pc)
        area = (sb[0] - sa[0]) * (sc[1] - sa[1]) - (sc[0] - sa[0]) * (sb[1] - sa[1])
        if abs(area) < 1e-9:
            continue

        min_x = max(0, int(min(sa[0], sb[0], sc[0])))
        max_x = min(CELL_W - 1, int(max(sa[0], sb[0], sc[0])) + 1)
        min_y = max(0, int(min(sa[1], sb[1], sc[1])))
        max_y = min(CELL_H - 1, int(max(sa[1], sb[1], sc[1])) + 1)

        for py in range(min_y, max_y + 1):
            for px in range(min_x, max_x + 1):
                x, y = px + 0.5, py + 0.5
                w0 = ((sb[0] - sa[0]) * (y - sa[1]) - (x - sa[0]) * (sb[1] - sa[1])) / area
                w1 = ((x - sa[0]) * (sc[1] - sa[1]) - (sc[0] - sa[0]) * (y - sa[1])) / area
                if w0 < 0 or w1 < 0 or w0 + w1 > 1:
                    continue
                z = sa[2] + w1 * (sb[2] - sa[2]) + w0 * (sc[2] - sa[2])
                slot = py * CELL_W + px
                if z >= depth[slot]:
                    continue
                depth[slot] = z
                w2 = 1.0 - w0 - w1
                n = [w2 * na[i] + w1 * nb[i] + w0 * nc[i] for i in range(3)]
                length = math.sqrt(sum(v * v for v in n)) or 1.0
                shade = max(0.0, sum(n[i] * light[i] for i in range(3)) / length)
                shade = 0.22 + 0.78 * shade ** 0.8
                pixels[slot * 3:slot * 3 + 3] = bytes(
                    min(255, int(ch * shade)) for ch in colour)

    return pixels


def write_png(path, width, height, pixels):
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        raw += pixels[y * width * 3:(y + 1) * width * 3]

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

    with open(path, "wb") as out:
        out.write(b"\x89PNG\r\n\x1a\n")
        out.write(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height,
                                             8, 2, 0, 0, 0)))
        out.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        out.write(chunk(b"IEND", b""))


def preview(meshes, features, path):
    plain, shipped, tinted = [], [], []

    def collect(pos, nrm, tri, colour_plain, colour_ship, colour_tint):
        for t in range(0, len(tri), 3):
            a, b, c = (pos[tri[t]], pos[tri[t + 1]], pos[tri[t + 2]])
            n = (nrm[tri[t]], nrm[tri[t + 1]], nrm[tri[t + 2]])
            plain.append(((a, b, c), n, colour_plain))
            shipped.append(((a, b, c), n, colour_ship))
            tinted.append(((a, b, c), n, colour_tint))

    for index, name in enumerate(REGIONS):
        mesh = meshes[name]
        # Row 2 shows one picked area, because that is the state the screen is
        # usually in and the one nobody has looked at yet.
        shipped_colour = _selected_tint() if name == "templeL" else SURFACE
        collect(mesh["pos"], mesh["nrm"], mesh["tri"], SKIN, shipped_colour,
                _region_tint(name, index))
    collect(features["pos"], features["nrm"], features["tri"], FEATURE,
            FEATURE, FEATURE)

    yaws = [0, 35, 90, 180]
    rows = (plain, shipped, tinted)
    width, height = CELL_W * len(yaws), CELL_H * len(rows)
    sheet = bytearray(BACKGROUND * (width * height))

    for row, triangles in enumerate(rows):
        for column, yaw in enumerate(yaws):
            cell = render(triangles, yaw, row == 1)
            for y in range(CELL_H):
                start = ((row * CELL_H + y) * width + column * CELL_W) * 3
                sheet[start:start + CELL_W * 3] = cell[y * CELL_W * 3:(y + 1) * CELL_W * 3]

    write_png(path, width, height, sheet)


def main():
    meshes = build_model()
    features = {'pos': [], 'nrm': [], 'tri': []}
    triangles = sum(len(m['tri'])//3 for m in meshes.values())
    if any(not m['tri'] for m in meshes.values()) or triangles > 25000:
        raise ValueError('Missing region or exceeded triangle budget')
    output = ROOT / 'assets/models/head.glb'
    size = write_glb(str(output), meshes, features)
    if size > 1024*1024:
        raise ValueError('Exceeded GLB size budget')
    (ROOT / 'build').mkdir(exist_ok=True)
    preview(meshes, features, str(ROOT / 'build/head_preview.png'))
    print(f'head.glb: {size} bytes, {triangles} triangles, {len(REGIONS)} regions')
    for name, mesh in meshes.items():
        print(f'  {name}: {len(mesh["tri"])//3} triangles')


if __name__ == '__main__':
    main()
