#!/usr/bin/env python3
"""Builds the head model the log flow's location step turns, plus a still
preview of it.

    python3 tool/head_model.py

Writes `assets/models/head.glb` (16 nodes) and `build/head_preview.png`.

The cuts come from `head_region_geometry.dart` and nowhere else: this script
reads the same numbers the 2D diagram is drawn from, so the 3D areas and the 2D
fallback cannot drift apart. The only translation is of coordinates, because a
cut the drawing states as "y = 62 on a 200x248 box" is a latitude on a head.

Standard library only, on purpose — it has to run on a machine with no Blender
and no pip install.
"""

import json
import math
import os
import struct
import zlib

# --- The drawing's numbers, unchanged -------------------------------------
# Every constant below is a copy of one in head_region_geometry.dart. Keep them
# in step; the node-name test in Dart catches a missing region, not a moved cut.

HAIRLINE = 62.0
BROW = 102.0
UNDER_EYE = 144.0
MOUTH = 184.0
BACK_NECK = 160.0
CENTRE = 100.0
TEMPLE_EDGE = 46.0          # _templeEdgeL; the right edge is its mirror
NOSE_TOP, NOSE_BOTTOM = 104.0, 174.0
NOSE_HALF_X = 17.0

# The silhouette's own extent, off _headPath: the top of the skull and the chin.
TOP_Y, CHIN_Y = 8.0, 231.0
HALF_H = (CHIN_Y - TOP_Y) / 2.0
CENTRE_Y = (CHIN_Y + TOP_Y) / 2.0
HALF_W = 83.0               # (183 - 17) / 2, the widest the head gets

# How deep the head is. The drawing never says, because a flat view cannot:
# a head is deeper than it is wide, and fuller behind the ears than in front.
DEPTH_FRONT = 92.0
DEPTH_BACK = 104.0

NOSE_HEIGHT = 15.0          # how far the nose stands off the face


def lon_of(x):
    """The drawing's x, as a longitude east of the face's midline. Negative is
    the user's LEFT, matching the mirrored front view the app already draws."""
    return math.degrees(math.asin(max(-1.0, min(1.0, (x - CENTRE) / HALF_W))))


# The vertical cuts are constant LONGITUDES, taken where the head is widest —
# not the drawing's vertical straight lines. On a flat view those are the same
# thing; on a head they are not, and a boundary that follows the side of the
# skull is the one a finger expects. Deliberate, and the only place the 3D
# areas leave the 2D drawing.
LON_TEMPLE = -lon_of(TEMPLE_EDGE)        # 40.6 degrees either side of centre
LON_NOSE = lon_of(CENTRE + NOSE_HALF_X)  # 11.8


# --- Which area a point of the surface belongs to --------------------------
# The same partition the 2D bands make, in the same order, with one difference
# the flat views could not have: front and back are two halves of one sphere
# rather than two drawings, so |lon| > 90 IS the back of the head.


def nose_half_lon(y):
    """How wide the nose is at this height, in degrees either side of the
    midline. Zero outside it, so the test below is the whole boundary."""
    if not (NOSE_TOP <= y <= NOSE_BOTTOM):
        return 0.0
    t = (y - NOSE_TOP) / (NOSE_BOTTOM - NOSE_TOP)
    # Narrow along the bridge, flaring to the wings, then rounded under them.
    flare = 0.42 + 0.58 * math.sin(math.pi * min(1.0, t * 1.12)) ** 0.55
    return LON_NOSE * flare * (1.0 - max(0.0, t - 0.88) / 0.12) ** 0.5


def region_at(y, lon):
    if y < HAIRLINE:
        return "crown"

    side = "L" if lon < 0 else "R"

    if abs(lon) > 90.0:
        if y < BACK_NECK:
            return "occipital" + side
        return "nape"

    if abs(lon) < nose_half_lon(y):
        return "nose"
    if y < BROW:
        return "forehead" + side
    if y < UNDER_EYE:
        return ("temple" + side) if abs(lon) > LON_TEMPLE else ("eye" + side)
    if y < MOUTH:
        return "cheek" + side
    return "jaw" + side


# In HeadRegion's own order, so a diff against the enum reads straight down.
REGIONS = [
    "crown", "foreheadL", "foreheadR", "templeL", "templeR", "eyeL", "nose",
    "eyeR", "cheekL", "cheekR", "jawL", "jawR", "occipitalL", "occipitalR",
    "nape",
]

# --- The shape -------------------------------------------------------------
# The silhouette is NOT invented here: it is `_headPath` out of
# head_region_geometry.dart, sampled. Revolving the drawing's own outline is
# what gives the model a round skull and a jaw, and it means the head seen
# head-on is the head the app has always drawn. A hand-written profile table
# was tried first and produced a lemon.

HEAD_PATH = [
    # The right half, from the top of the skull down to the chin, as the four
    # cubics the Dart traces. Each entry is (start, control1, control2, end).
    ((100, 8), (148, 8), (181, 42), (183, 98)),
    ((183, 98), (184, 120), (180, 142), (173, 162)),
    ((173, 162), (164, 186), (148, 208), (130, 221)),
    ((130, 221), (120, 228), (110, 231), (100, 231)),
]


def _outline():
    points = []
    for p0, p1, p2, p3 in HEAD_PATH:
        for step in range(81):
            t = step / 80.0
            u = 1.0 - t
            x = (u ** 3 * p0[0] + 3 * u * u * t * p1[0]
                 + 3 * u * t * t * p2[0] + t ** 3 * p3[0])
            y = (u ** 3 * p0[1] + 3 * u * u * t * p1[1]
                 + 3 * u * t * t * p2[1] + t ** 3 * p3[1])
            points.append((y, x - CENTRE))
    return sorted(points)


OUTLINE = _outline()


def half_width(y):
    """How wide the drawing's head is at this height. 0 at the crown and at
    the chin, 83 at the ears."""
    if y <= OUTLINE[0][0]:
        return 0.0
    if y >= OUTLINE[-1][0]:
        return 0.0
    lo, hi = 0, len(OUTLINE) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if OUTLINE[mid][0] <= y:
            lo = mid
        else:
            hi = mid
    (y0, w0), (y1, w1) = OUTLINE[lo], OUTLINE[hi]
    if y1 == y0:
        return max(0.0, w0)
    return max(0.0, w0 + (w1 - w0) * (y - y0) / (y1 - y0))


# How much deeper than wide the head is at a given height, front and back of
# the ear plane. A head is about 19cm long and 15cm wide, and the extra length
# is nearly all behind the ears — which is the single thing that stops a
# revolved outline from reading as an egg.
DEPTH_FRONT = [(8, 0.88), (62, 1.04), (102, 1.14), (144, 1.18),
               (184, 1.14), (231, 1.00)]
DEPTH_BACK = [(8, 1.00), (62, 1.30), (102, 1.32), (144, 1.18),
              (184, 1.02), (231, 0.92)]

NOSE_HEIGHT = 21.0          # how far the nose stands off the face

# How far a cut rides up at the face and drops at the back. The flat diagram
# bowed every horizontal cut for this reason (`_sag`): a brow line, a cheek
# line and a jaw line all follow the face round, and a ring at constant height
# reads as a barcode printed on a head rather than as the head's own anatomy.
#
# It is applied to the PARAMETER, not to the region test: a row of the grid is
# still one cut, so the areas stay exactly as exact as they were.
SAG = 7.0

# What turns a mannequin into a head: a brow that overhangs, sockets the eyes
# sit inside, cheekbones, lips and a chin. Each is (y, longitude, y radius,
# longitude radius, height) in drawing units, and each falls smoothly to zero
# at its own edge — a displacement with a step in it would tear the mesh.
SCULPT = [
    (97, -21, 16, 22, 4.2),      # brow ridge, left
    (97, 21, 16, 22, 4.2),
    (122, -24, 13, 17, -4.0),    # eye socket, left
    (122, 24, 13, 17, -4.0),
    (158, -31, 20, 20, 3.4),     # cheekbone, left
    (158, 31, 20, 20, 3.4),
    (193, 0, 11, 15, 2.8),       # lips
    (216, 0, 15, 17, 2.4),       # chin
    (150, 0, 46, 95, -1.6),      # the face plane, flattened off the sphere
]


def _profile(table, y):
    if y <= table[0][0]:
        return table[0][1]
    for (a_y, a_val), (b_y, b_val) in zip(table, table[1:]):
        if y <= b_y:
            t = (y - a_y) / (b_y - a_y)
            t = t * t * (3.0 - 2.0 * t)     # smoothstep: a linear ramp leaves
            return a_val + (b_val - a_val) * t   # a crease at every knot
    return table[-1][1]


def _sculpt(y, lon):
    total = 0.0
    for c_y, c_lon, r_y, r_lon, height in SCULPT:
        dy = (y - c_y) / r_y
        dl = (lon - c_lon) / r_lon
        d = math.sqrt(dy * dy + dl * dl)
        if d >= 1.0:
            continue
        total += height * math.cos(0.5 * math.pi * d) ** 2
    return total


def _nose_bump(y, lon):
    """Raised on the midline and flat at its own boundary, so the nose stands
    off the face without tearing the areas it is cut out of."""
    if not (NOSE_TOP <= y <= NOSE_BOTTOM) or abs(lon) >= LON_NOSE:
        return 0.0
    u = (y - NOSE_TOP) / (NOSE_BOTTOM - NOSE_TOP)     # 0 at the brow, 1 at the tip
    v = abs(lon) / LON_NOSE
    # It peaks LOW, near the tip, because that is where a nose peaks; a bump
    # centred on the bridge reads as a snout.
    along = math.sin(math.pi * min(1.0, u * 1.08)) ** 0.7 * (0.45 + 0.55 * u)
    across = math.cos(0.5 * math.pi * v) ** 1.5
    return NOSE_HEIGHT * along * across


def surface_point(band_y, lon):
    rad = math.radians(lon)
    face = (math.cos(rad) + 1.0) / 2.0                 # 1 at the face, 0 behind
    y = band_y - SAG * math.cos(rad)
    w = half_width(y)
    depth = w * (_profile(DEPTH_BACK, y)
                 + (_profile(DEPTH_FRONT, y) - _profile(DEPTH_BACK, y)) * face)

    out = _sculpt(y, lon) + _nose_bump(band_y, lon)

    return (w * math.sin(rad) + out * math.sin(rad), CENTRE_Y - y,
            depth * math.cos(rad) + out * math.cos(rad))


# --- The grid --------------------------------------------------------------
# Every cut is an explicit grid line. That is the whole trick: a boundary the
# grid lands on exactly is a boundary the mesh can be split along exactly, so
# the pickable areas follow the drawing rather than the nearest row of quads.

Y_CUTS = sorted({TOP_Y, HAIRLINE, BROW, NOSE_TOP, UNDER_EYE, BACK_NECK,
                 NOSE_BOTTOM, MOUTH, CHIN_Y})
LON_CUTS = sorted({-180.0, -90.0, -LON_TEMPLE, -LON_NOSE, 0.0,
                   LON_NOSE, LON_TEMPLE, 90.0, 180.0})

Y_STEP = 4.0     # drawing units between two rows of quads
LON_STEP = 3.0   # degrees between two columns


def _subdivide(cuts, step):
    out = []
    for a, b in zip(cuts, cuts[1:]):
        out.append(a)
        n = max(1, int(round(abs(b - a) / step)))
        for k in range(1, n):
            out.append(a + (b - a) * k / n)
    out.append(cuts[-1])
    return out


YS = _subdivide(Y_CUTS, Y_STEP)
LONS = _subdivide(LON_CUTS, LON_STEP)[:-1]   # -180 and +180 are one meridian


def build_grid():
    points = [[surface_point(y, lon) for lon in LONS] for y in YS]
    normals = [[[0.0, 0.0, 0.0] for _ in LONS] for _ in YS]

    def accumulate(a, b, c):
        (ai, aj), (bi, bj), (ci, cj) = a, b, c
        pa, pb, pc = points[ai][aj], points[bi][bj], points[ci][cj]
        ux, uy, uz = pb[0] - pa[0], pb[1] - pa[1], pb[2] - pa[2]
        vx, vy, vz = pc[0] - pa[0], pc[1] - pa[1], pc[2] - pa[2]
        n = (uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx)
        for i, j in (a, b, c):
            normals[i][j][0] += n[0]
            normals[i][j][1] += n[1]
            normals[i][j][2] += n[2]

    for i in range(len(YS) - 1):
        for j in range(len(LONS)):
            k = (j + 1) % len(LONS)
            accumulate((i, j), (i + 1, j), (i + 1, k))
            accumulate((i, j), (i + 1, k), (i, k))

    for row in normals:
        for n in row:
            length = math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2) or 1.0
            n[0] /= length
            n[1] /= length
            n[2] /= length

    return points, normals


def build_regions(points, normals):
    """One mesh per region, each with its own vertices. Duplicating the
    boundary vertices is the point: separate meshes are what let a raycast hand
    back the answer as a node name."""
    meshes = {name: {"index": {}, "pos": [], "nrm": [], "tri": []}
              for name in REGIONS}

    def vertex(mesh, i, j):
        key = (i, j)
        if key not in mesh["index"]:
            mesh["index"][key] = len(mesh["pos"])
            mesh["pos"].append(points[i][j])
            mesh["nrm"].append(tuple(normals[i][j]))
        return mesh["index"][key]

    lon_count = len(LONS)
    for i in range(len(YS) - 1):
        y_mid = (YS[i] + YS[i + 1]) / 2.0
        for j in range(lon_count):
            k = (j + 1) % lon_count
            lon_b = LONS[k] if k else LONS[0] + 360.0
            lon_mid = (LONS[j] + lon_b) / 2.0
            if lon_mid > 180.0:
                lon_mid -= 360.0

            mesh = meshes[region_at(y_mid, lon_mid)]
            top_degenerate = half_width(YS[i]) < 1e-6
            bottom_degenerate = half_width(YS[i + 1]) < 1e-6

            a, b = vertex(mesh, i, j), vertex(mesh, i + 1, j)
            c, d = vertex(mesh, i + 1, k), vertex(mesh, i, k)
            # Wound so the front of a triangle faces out of the head.
            if not top_degenerate:
                mesh["tri"] += [a, b, d] if bottom_degenerate else [a, b, c]
            if not bottom_degenerate and not top_degenerate:
                mesh["tri"] += [a, c, d]
            elif top_degenerate:
                mesh["tri"] += [a, b, c]

    return meshes


# --- The face, as one node nothing can tap --------------------------------

FEATURE_CURVES = [
    # (name, [(x, y) on the drawing], half-width in degrees)
    ("browL", [(48, 99), (60, 93), (74, 91), (86, 94)], 2.6),
    ("browR", [(152, 99), (140, 93), (126, 91), (114, 94)], 2.6),
    ("eyeL", [(54, 116), (66, 111), (80, 113), (88, 119), (74, 123), (60, 121)], 1.8),
    ("eyeR", [(146, 116), (134, 111), (120, 113), (112, 119), (126, 123), (140, 121)], 1.8),
    ("mouth", [(84, 196), (92, 193), (100, 194), (108, 193), (116, 196)], 2.0),
]


# Every boundary between two areas, as a line to draw. This is `dividers()`
# from head_region_geometry.dart, in the same (band y, longitude) space: the
# flat diagram stroked its cuts, and without them a head whose areas are all
# one colour is a blank oval. They are features rather than geometry of their
# own, so they are drawn and never picked, and they carry the same weight as
# the brows and the lips — one thin hand across the whole head (owner's rule).
#
# Each entry is a polyline in (band y, longitude).
def _seam_lines():
    lines = []

    def ring(y, lon_from, lon_to):
        steps = max(2, int(abs(lon_to - lon_from) / 3))
        lines.append([
            (y, lon_from + (lon_to - lon_from) * i / steps)
            for i in range(steps + 1)
        ])

    def meridian(lon, y_from, y_to):
        steps = max(2, int(abs(y_to - y_from) / 3))
        lines.append([
            (y_from + (y_to - y_from) * i / steps, lon)
            for i in range(steps + 1)
        ])

    # The hairline and the nape cut go all the way round: both separate areas
    # on the front AND on the back.
    ring(HAIRLINE, -180, 180)
    ring(BACK_NECK, 90, 270)
    # The face's own cuts stop at the silhouette, because behind it they would
    # be a line drawn across the middle of one area.
    for y in (BROW, UNDER_EYE, MOUTH):
        ring(y, -90, 90)
    meridian(0.0, HAIRLINE, CHIN_Y - 2)
    meridian(180.0, HAIRLINE, BACK_NECK)
    for edge in (-LON_TEMPLE, LON_TEMPLE):
        meridian(edge, BROW, UNDER_EYE)

    # And the nose, whose edge is a curve rather than a cut.
    for side in (-1, 1):
        steps = 26
        lines.append([
            (
                NOSE_TOP + (NOSE_BOTTOM - NOSE_TOP) * i / steps,
                side * nose_half_lon(
                    NOSE_TOP + (NOSE_BOTTOM - NOSE_TOP) * i / steps
                ),
            )
            for i in range(steps + 1)
        ])

    return lines


SEAM_HALF = 0.9          # drawing units either side of the line
SEAM_LIFT = 0.8          # how far it floats off the skin


def _seam_ribbons(pos, nrm, tri):
    for line in _seam_lines():
        for step in range(len(line) - 1):
            quad = []
            for y, lon in (line[step], line[step + 1]):
                rad = math.radians(lon)
                normal = (math.sin(rad), 0.0, math.cos(rad))
                for offset in (SEAM_HALF, -SEAM_HALF):
                    p = surface_point(y + offset, lon)
                    quad.append(
                        tuple(p[i] + normal[i] * SEAM_LIFT for i in range(3))
                    )
            base = len(pos)
            for p in quad:
                pos.append(p)
                rad = math.radians(line[step][1])
                nrm.append((math.sin(rad), 0.0, math.cos(rad)))
            tri += [base, base + 1, base + 2, base + 1, base + 3, base + 2]


EARS = [(-88.0, 1), (88.0, -1)]          # longitude, and which way it juts
EAR_Y, EAR_HALF_Y, EAR_HALF_LON = 132.0, 21.0, 6.5


def _ear_patch(pos, nrm, tri, lon_centre, sign):
    """A raised disc on the side of the head. It is a feature, not a region —
    the enum has no word for an ear, and a tap on one belongs to the temple or
    the occiput underneath it."""
    rings, spokes = 4, 16
    centre = len(pos)
    base = surface_point(EAR_Y, lon_centre)
    lift = 6.0
    normal = (math.sin(math.radians(lon_centre)), 0.0,
              math.cos(math.radians(lon_centre)))
    pos.append(tuple(base[i] + normal[i] * lift for i in range(3)))
    nrm.append(normal)

    for ring in range(1, rings + 1):
        t = ring / rings
        for spoke in range(spokes):
            angle = 2.0 * math.pi * spoke / spokes
            y = EAR_Y + math.sin(angle) * EAR_HALF_Y * t
            lon = lon_centre + math.cos(angle) * EAR_HALF_LON * t
            p = surface_point(y, lon)
            # Hollow in the middle and proud at the rim: the shape that reads
            # as an ear from any angle. A dome reads as a button.
            height = lift + 7.5 * math.sin(math.pi * min(1.0, t * 0.92)) ** 1.6
            n = (math.sin(math.radians(lon)), 0.0, math.cos(math.radians(lon)))
            pos.append(tuple(p[i] + n[i] * height for i in range(3)))
            nrm.append(n)

    def index(ring, spoke):
        return centre + 1 + (ring - 1) * spokes + (spoke % spokes)

    for spoke in range(spokes):
        a, b = index(1, spoke), index(1, spoke + 1)
        tri += [centre, b, a] if sign > 0 else [centre, a, b]
    for ring in range(1, rings):
        for spoke in range(spokes):
            a, b = index(ring, spoke), index(ring, spoke + 1)
            c, d = index(ring + 1, spoke + 1), index(ring + 1, spoke)
            tri += ([a, c, b, a, d, c] if sign > 0 else [a, b, c, a, c, d])


def build_features():
    """Brows, eyes and the mouth, as thin ribbons floating just off the skin.
    One node, `raycastable: false` in the app, so a brow never eats a tap that
    was meant for the eye under it."""
    pos, nrm, tri = [], [], []

    for _, points_2d, half in FEATURE_CURVES:
        ring = [(y, lon_of(x)) for x, y in points_2d]
        closed = len(ring) > 4
        span = range(len(ring)) if closed else range(len(ring) - 1)
        for step in span:
            a = ring[step]
            b = ring[(step + 1) % len(ring)]
            quad = []
            for y, lon in (a, b):
                for offset in (half, -half):
                    p = surface_point(y + offset, lon)
                    n = surface_point(y + offset, lon)
                    length = math.sqrt(sum(c * c for c in n)) or 1.0
                    lift = 1.0 + 1.2 / length
                    quad.append(((p[0] * lift, p[1] * lift, p[2] * lift),
                                 (n[0] / length, n[1] / length, n[2] / length)))
            base = len(pos)
            for p, n in quad:
                pos.append(p)
                nrm.append(n)
            tri += [base, base + 1, base + 2, base + 1, base + 3, base + 2]

    _seam_ribbons(pos, nrm, tri)

    for lon_centre, sign in EARS:
        _ear_patch(pos, nrm, tri, lon_centre, sign)

    return {"pos": pos, "nrm": nrm, "tri": tri}


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
    children.append(add_mesh("features", features["pos"], features["nrm"],
                             features["tri"], 1))

    nodes.append({"name": "head", "children": children})

    gltf = {
        "asset": {"version": "2.0", "generator": "tool/head_model.py"},
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
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    models = os.path.join(root, "assets", "models")
    build = os.path.join(root, "build")
    os.makedirs(models, exist_ok=True)
    os.makedirs(build, exist_ok=True)

    points, normals = build_grid()
    meshes = build_regions(points, normals)
    features = build_features()

    empty = [name for name in REGIONS if not meshes[name]["tri"]]
    if empty:
        raise SystemExit("regions with no geometry: %s" % ", ".join(empty))

    glb = os.path.join(models, "head.glb")
    size = write_glb(glb, meshes, features)
    triangles = sum(len(meshes[n]["tri"]) for n in REGIONS) // 3

    print("head.glb    %6.1f KB   %d triangles, %d nodes"
          % (size / 1024.0, triangles, len(REGIONS) + 1))
    for name in REGIONS:
        print("  region_%-12s %5d tris" % (name, len(meshes[name]["tri"]) // 3))

    png = os.path.join(build, "head_preview.png")
    preview(meshes, features, png)
    print("preview     %s" % png)


if __name__ == "__main__":
    main()
