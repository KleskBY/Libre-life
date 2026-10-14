"""Generate DarkPlaces .rtlights files from Half-Life BSP v30 maps.

Sources of light:
  1. Entity lights (light, light_spot) from the entity lump.
  2. Texture lights (emissive textures per valve lights.rad table), extracted
     from world faces, clustered per fixture.

DP dynamic lights use linear falloff vs HL's inverse-square static lighting,
so radii are boosted and brightness reduced.

Brightness is baked in rather than relying on r_shadow_lightintensityscale,
since that cvar is global and would also blow out Quake 1 maps. Override
per-run with --intensity-scale without editing this file.

rtlights line: [!]x y z radius r g b style  (style kept: 0-11 patterns, 32+ switchable via QC)
"""
import argparse, struct, re, os, math, sys, time, collections

MAPS_DIR = None  # HL v30 BSP source dir; supply via --maps-dir (e.g. your Half-Life/valve/maps)
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "maps")
INTENSITY_SCALE = 2.5            # flat multiplier on final r/g/b (radius untouched)

# ---------------------------------------------------------------- rad table
# name -> (r, g, b, intensity)   (community-normalized valve lights.rad)
RAD_RAW = """
+0~gymlight 255 251 129 1000
+0~light1 170 212 240 1500
+0~light2a 200 200 200 1000
+0~light3a 180 180 230 1000
+0~light4a 230 225 195 800
+0~light5a 80 150 200 1000
+0~light6a 150 5 5 1000
~light3a 190 20 20 1500
~light3b 192 192 240 100
~light3c 255 248 192 100
~light3d 190 255 49 1000
~light3e 90 190 140 1000
~light3f 255 200 70 1000
~light5a 210 246 255 1000
~light5c 149 255 199 1000
~light5d 165 255 149 1000
~light5e 232 63 65 1000
~light5f 237 233 178 1000
litepanel1 191 213 212 1000
panellite1 191 213 212 1000
skkylite 191 213 212 2500
skkylite2 191 213 212 2500
skkylitedawn 213 178 196 2500
+0~fifts_lght01 208 214 245 1000
+0~fifts_lght06 232 232 232 1000
+0~fifts_lght3 250 234 184 1000
+0~fifts_lght4 160 170 220 2000
+0~fifts_lght5 160 135 55 1000
+0~fifties_lgt2 208 214 245 500
+0~fifties_lgt3 232 232 232 1000
fifties_mon1b 100 100 180 30
+0~tnnl_lgt1 237 232 166 1000
+0~tnnl_lgt2 255 230 160 1000
+0~tnnl_lgt3 210 210 236 2500
+0~tnnl_lgt4 255 208 160 1000
+0lab1_w6 225 225 240 4400
+0lab1_w6b 165 230 255 2000
+0lab1_w6d 165 230 255 2000
+0lab1_w7 225 225 240 4000
+alab1_w6 150 160 210 3200
~lab_crt9a 225 150 150 100
~lab_crt9b 100 100 255 100
~lab_crt9c 100 200 150 100
+0~lab_crt8 50 50 255 100
+0~generic65 255 255 255 200
+0~generic85 207 230 255 350
+0~generic86 255 245 210 100
+0~generic86b 158 220 201 400
+0~generic86r 255 0 0 500
~generic87 200 230 250 250
generic87a 100 255 100 250
generic88a 255 100 100 250
generic89a 40 40 130 250
generic90a 200 255 200 250
flatbed_hlite2 214 178 94 500
flatbed_lite1 214 178 94 500
flatbed_tlite2 214 0 3 500
tech_lite1 255 236 162 3000
tech_lite2 231 126 20 1000
tech_lite3 59 213 25 1000
+0~white 255 255 255 1000
~spotblue 61 194 255 100
~spotgreen 61 255 126 100
~spotred 255 26 29 100
~spotyellow 255 255 255 50
crys_1a 248 193 255 1000
crys_1b 248 193 255 1000
crys_1c 248 193 255 1000
crys_1top 248 193 255 1000
crys_2a 169 255 182 1000
crys_2b 169 255 182 1000
crys_2top 169 255 182 1000
crys_3a 255 152 79 1000
crys_3b 255 152 79 1000
crys_3top 255 152 79 1000
crys_4a 255 209 153 1000
crys_4b 255 160 128 2000
+0~c2a4_lgt1 235 214 52 1000
+0~drkmtllgt1 235 194 98 1000
+0~drkmtls2 150 120 20 2500
+0~drkmtls2c 255 200 100 500
+0drkmtl_scrn 60 80 255 5000
emerglight 255 235 200 1200
subway_lights 255 248 202 50
+0buttonlite 235 22 22 1000
+abuttonlite 24 235 24 1000
c1a3c_map 100 100 255 100
elev2_ciel 255 200 100 400
fill1 142 191 176 10
fill2 247 164 124 5
fill3 90 100 180 10
~trn_lt1 240 236 199 70
glassgreen 50 255 50 20
c3a2_light 234 193 0 250
crete3_wall02a 86 144 48 400
!radio 80 255 40 180
!greenslime 80 255 40 600
c4a1a_spike1b 162 173 255 2500
xeno_18 15 129 255 600
"""
RAD = {}
for line in RAD_RAW.strip().splitlines():
    p = line.split()
    RAD[p[0].lower()] = (float(p[1]), float(p[2]), float(p[3]), float(p[4]))

# a toggled-off variant (+a...) of a lit texture is dark at map start when the
# +0 name is in the table but the face was compiled with +a -> treat as unlit.
# Table entries listed with explicit +a names stay.

TEXLIGHT_MIN_EFFECT = 40.0      # I * maxrgb/255 below this -> ignore texture
CLUSTER_DIST = 192.0            # faces of same texture within this merge
SURF_OFFSET = 12.0              # push light off the emitting surface
MAX_TEXLIGHTS = 100             # per map, keep brightest clusters
TEXLIGHT_SHADOWS = 32           # per map, brightest N texlights cast shadows
ENT_SHADOW_MIN_I = 100.0        # entity lights below this intensity: no shadows

BRUSH_ENT_OK = {"worldspawn", "func_wall", "func_illusionary", "func_detail"}

# ---------------------------------------------------------------- bsp parse
def read_lump(data, i):
    ofs, ln = struct.unpack_from("<ii", data, 4 + i * 8)
    return data[ofs:ofs + ln]

def parse_entities(text):
    ents = []
    for block in re.findall(r"\{(.*?)\}", text, re.S):
        e = {}
        for k, v in re.findall(r'"([^"]*)"\s+"([^"]*)"', block):
            e[k.lower()] = v
        ents.append(e)
    return ents

def parse_bsp(path):
    with open(path, "rb") as f:
        data = f.read()
    ver = struct.unpack_from("<i", data, 0)[0]
    if ver != 30:
        raise ValueError(f"{path}: bsp version {ver}, expected 30")

    ents_text = read_lump(data, 0).split(b"\x00")[0].decode("latin-1")
    ents = parse_entities(ents_text)

    planes_raw = read_lump(data, 1)
    planes = [struct.unpack_from("<ffff", planes_raw, i * 20)[:4]
              for i in range(len(planes_raw) // 20)]

    tex_raw = read_lump(data, 2)
    texnames = []
    if len(tex_raw) >= 4:
        (ntex,) = struct.unpack_from("<i", tex_raw, 0)
        for i in range(ntex):
            (ofs,) = struct.unpack_from("<i", tex_raw, 4 + i * 4)
            if ofs < 0 or ofs + 16 > len(tex_raw):
                texnames.append("")
                continue
            name = tex_raw[ofs:ofs + 16].split(b"\x00")[0].decode("latin-1").lower()
            texnames.append(name)

    verts_raw = read_lump(data, 3)
    verts = [struct.unpack_from("<fff", verts_raw, i * 12)
             for i in range(len(verts_raw) // 12)]

    ti_raw = read_lump(data, 6)
    texinfo_miptex = [struct.unpack_from("<i", ti_raw, i * 40 + 32)[0]
                      for i in range(len(ti_raw) // 40)]

    faces_raw = read_lump(data, 7)
    faces = [struct.unpack_from("<HHiHH4bi", faces_raw, i * 20)
             for i in range(len(faces_raw) // 20)]

    edges_raw = read_lump(data, 12)
    edges = [struct.unpack_from("<HH", edges_raw, i * 4)
             for i in range(len(edges_raw) // 4)]

    sedges_raw = read_lump(data, 13)
    surfedges = [struct.unpack_from("<i", sedges_raw, i * 4)[0]
                 for i in range(len(sedges_raw) // 4)]

    models_raw = read_lump(data, 14)
    models = []
    for i in range(len(models_raw) // 64):
        firstface, numfaces = struct.unpack_from("<ii", models_raw, i * 64 + 56)
        models.append((firstface, numfaces))

    return ents, planes, texnames, verts, texinfo_miptex, faces, edges, surfedges, models

# ---------------------------------------------------------------- geometry
def face_verts(fi, faces, edges, surfedges, verts):
    _, _, firstedge, numedges, _, _, _, _, _, _ = faces[fi]
    out = []
    for k in range(numedges):
        se = surfedges[firstedge + k]
        v = edges[abs(se)][1 if se < 0 else 0]
        out.append(verts[v])
    return out

def poly_center_area(vs):
    n = len(vs)
    if n < 3:
        return None, 0.0
    cx = sum(v[0] for v in vs) / n
    cy = sum(v[1] for v in vs) / n
    cz = sum(v[2] for v in vs) / n
    area = 0.0
    for i in range(1, n - 1):
        ax = (vs[i][0] - vs[0][0], vs[i][1] - vs[0][1], vs[i][2] - vs[0][2])
        bx = (vs[i+1][0] - vs[0][0], vs[i+1][1] - vs[0][1], vs[i+1][2] - vs[0][2])
        cxp = (ax[1]*bx[2] - ax[2]*bx[1], ax[2]*bx[0] - ax[0]*bx[2], ax[0]*bx[1] - ax[1]*bx[0])
        area += 0.5 * math.sqrt(cxp[0]**2 + cxp[1]**2 + cxp[2]**2)
    return (cx, cy, cz), area

# ---------------------------------------------------------------- lights
def norm_color(r, g, b):
    m = max(r, g, b, 1.0)
    return r / m, g / m, b / m

def entity_lights(ents):
    out = []
    for e in ents:
        cn = e.get("classname", "")
        if cn not in ("light", "light_spot"):
            continue
        if "origin" not in e:
            continue
        try:
            ox, oy, oz = (float(x) for x in e["origin"].split())
        except ValueError:
            continue
        vals = []
        if "_light" in e:
            try:
                vals = [float(x) for x in e["_light"].replace(",", " ").split()]
            except ValueError:
                vals = []
        if len(vals) >= 4:
            r, g, b, inten = vals[0], vals[1], vals[2], vals[3]
        elif len(vals) == 3:
            r, g, b = vals
            inten = max(r, g, b)
        elif len(vals) == 1:
            r = g = b = 255.0
            inten = vals[0]
        else:
            r = g = b = 255.0
            inten = 200.0
        if inten <= 0:
            continue
        cr, cg, cb = norm_color(r, g, b)

        if len(vals) == 3:  # dim fill light: rgb doubles as brightness
            radius = min(max(inten * 3.0, 150.0), 360.0)
            bright = min(max(inten / 300.0, 0.08), 0.35)
            shadow = False  # ambient tint only, shadows buy nothing
        else:
            radius = min(max(inten * 2.2, 160.0), 620.0)
            bright = min(max(inten / 500.0, 0.15), 0.6)
            shadow = inten >= ENT_SHADOW_MIN_I
        if cn == "light_spot":
            radius *= 0.75

        style = 0
        try:
            style = int(float(e.get("style", "0")))
        except ValueError:
            pass
        # styles 12..31 are unassigned patterns in QC -> flatten to 0
        if 12 <= style < 32:
            style = 0
        # switchable (32+) kept only when something can actually toggle it
        if style >= 32 and not e.get("targetname"):
            style = 0
        out.append((ox, oy, oz, radius, cr * bright, cg * bright, cb * bright, style, shadow))
    return out

def texture_lights(parsed):
    ents, planes, texnames, verts, texinfo_miptex, faces, edges, surfedges, models = parsed

    # face index ranges of allowed brush models
    allowed = set()
    if models:
        ff, nf = models[0]
        allowed.update(range(ff, ff + nf))
    for e in ents:
        if e.get("classname") in BRUSH_ENT_OK and e.get("model", "").startswith("*"):
            try:
                mi = int(e["model"][1:])
                ff, nf = models[mi]
                allowed.update(range(ff, ff + nf))
            except (ValueError, IndexError):
                pass

    emitters = collections.defaultdict(list)  # texname -> [(center, normal, area)]
    for fi in range(len(faces)):
        if fi not in allowed:
            continue
        planenum, side, _, _, ti, _, _, _, _, _ = faces[fi]
        if ti >= len(texinfo_miptex):
            continue
        mip = texinfo_miptex[ti]
        if mip < 0 or mip >= len(texnames):
            continue
        name = texnames[mip]
        rad = RAD.get(name)
        if rad is None:
            continue
        r, g, b, inten = rad
        if inten * (max(r, g, b) / 255.0) < TEXLIGHT_MIN_EFFECT:
            continue
        vs = face_verts(fi, faces, edges, surfedges, verts)
        center, area = poly_center_area(vs)
        if center is None or area < 4.0:
            continue
        nx, ny, nz, _ = planes[planenum]
        if side:
            nx, ny, nz = -nx, -ny, -nz
        emitters[name].append((center, (nx, ny, nz), area))

    out = []
    for name, lst in emitters.items():
        r, g, b, inten = RAD[name]
        cr, cg, cb = norm_color(r, g, b)
        # greedy clustering
        used = [False] * len(lst)
        for i in range(len(lst)):
            if used[i]:
                continue
            cluster = [i]
            used[i] = True
            changed = True
            while changed:
                changed = False
                for j in range(len(lst)):
                    if used[j]:
                        continue
                    for k in cluster:
                        d = math.dist(lst[j][0], lst[k][0])
                        if d < CLUSTER_DIST:
                            cluster.append(j)
                            used[j] = True
                            changed = True
                            break
            tot_a = sum(lst[k][2] for k in cluster)
            wx = sum(lst[k][0][0] * lst[k][2] for k in cluster) / tot_a
            wy = sum(lst[k][0][1] * lst[k][2] for k in cluster) / tot_a
            wz = sum(lst[k][0][2] * lst[k][2] for k in cluster) / tot_a
            anx = sum(lst[k][1][0] * lst[k][2] for k in cluster)
            any_ = sum(lst[k][1][1] * lst[k][2] for k in cluster)
            anz = sum(lst[k][1][2] * lst[k][2] for k in cluster)
            nl = math.sqrt(anx*anx + any_*any_ + anz*anz)
            if nl > 0.01:
                anx, any_, anz = anx / nl, any_ / nl, anz / nl
            else:
                anx = any_ = 0.0
                anz = 1.0
            px = wx + anx * SURF_OFFSET
            py = wy + any_ * SURF_OFFSET
            pz = wz + anz * SURF_OFFSET

            eff = inten * tot_a
            radius = min(max(math.sqrt(eff) * 0.15, 120.0), 450.0)
            bright = min(max(math.sqrt(eff) / 6000.0, 0.10), 0.45)
            out.append((px, py, pz, radius, cr * bright, cg * bright, cb * bright, 0, eff))

    out.sort(key=lambda L: -L[8])
    out = out[:MAX_TEXLIGHTS]
    # only the brightest few cast shadows; rest are cheap fill
    return [L[:8] + (i < TEXLIGHT_SHADOWS,) for i, L in enumerate(out)]

# ---------------------------------------------------------------- main
def fmt(v):
    s = f"{v:.6g}"
    return s

def write_retry(path, text, attempts=8, delay=0.1):
    # Windows AV/indexer/OneDrive can hold a freshly-written file briefly,
    # surfacing as OSError 22 on the next open() a few files later.
    for i in range(attempts):
        try:
            with open(path, "w", newline="\n") as f:
                f.write(text)
            return
        except OSError:
            if i == attempts - 1:
                raise
            time.sleep(delay)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--maps-dir", default=MAPS_DIR, required=(MAPS_DIR is None),
                    help="Directory of Half-Life v30 BSP maps to read")
    ap.add_argument("--out-dir", default=OUT_DIR,
                    help="Output directory for generated .rtlights (default: repo data/maps)")
    ap.add_argument("--intensity-scale", type=float, default=INTENSITY_SCALE,
                     help="flat multiplier on final light r/g/b (default %(default)s)")
    args = ap.parse_args()
    scale = args.intensity_scale

    os.makedirs(args.out_dir, exist_ok=True)
    total_maps = 0
    report = []
    for fn in sorted(os.listdir(args.maps_dir)):
        if not fn.lower().endswith(".bsp"):
            continue
        path = os.path.join(args.maps_dir, fn)
        name = os.path.splitext(fn)[0]
        try:
            parsed = parse_bsp(path)
        except Exception as ex:
            report.append(f"{name}: SKIP ({ex})")
            continue
        ents = parsed[0]
        el = entity_lights(ents)
        tl = texture_lights(parsed)
        lights = el + tl
        lines = []
        for (x, y, z, rad, r, g, b, style, shadow) in lights:
            pfx = "" if shadow else "!"
            r, g, b = r * scale, g * scale, b * scale
            lines.append(f"{pfx}{fmt(x)} {fmt(y)} {fmt(z)} {fmt(rad)} {fmt(r)} {fmt(g)} {fmt(b)} {style}")
        outp = os.path.join(args.out_dir, name + ".rtlights")
        write_retry(outp, "\n".join(lines) + ("\n" if lines else ""))
        total_maps += 1
        report.append(f"{name}: {len(el)} entity + {len(tl)} texlight = {len(lights)}")
    print("\n".join(report))
    print(f"\n{total_maps} maps written to {args.out_dir} (intensity_scale={scale})")

if __name__ == "__main__":
    main()
