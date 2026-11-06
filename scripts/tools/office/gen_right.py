# Genera los PNG de la vista derecha de la oficina, píxel a píxel: la habitación con dos apliques,
# la vitrina en perspectiva con su peana e insignia, el cristal y las medallas (una por familia de
# color y el hueco de las que faltan). Mismo método que gen_center.py.
import json, math, os
import numpy as np
from pixkit import *

ys, xs = np.mgrid[0:H, 0:W]

# La peana va del suelo a la pared; la vitrina está de pie sobre ella, separada de la pared.
CASE = (267, 80, 693, 408)        # marco de fuera (abajo: donde apoya en la tapa de la peana)
OPEN = (283, 104, 677, 392)       # hueco del cristal
DEPTH = 0.94                      # el fondo, escalado hacia el punto de fuga
BASE_WALL = 392                   # la tapa de la peana toca la pared aquí
BASE_TOP = 414                    # canto delantero de la tapa
BASE = (225, 735, 506)            # frente: x0, x1, abajo
BASE_BACK = (275, 685)            # tapa: ancho junto a la pared
SCONCES = (150, 810)


def quad(pts):
    return poly_mask(pts)


def build_sconces(cv):
    for sx in SCONCES:
        # Luz cálida en la pared, arriba y abajo de la pantalla.
        for (y0, y1, up) in ((112, 186, True), (208, 290, False)):
            yy = (ys - y0) / (y1 - y0)
            near = (1 - yy) if up else yy
            spread = 10 + (y1 - ys if up else ys - y0) * 0.45
            cone = (ys >= y0) & (ys < y1) & (np.abs(xs - sx) < spread)
            level_a = np.clip((1 - near) * 7, 0, 16) * (1 - np.abs(xs - sx) / np.maximum(spread, 1))
            wall = np.all(cv.px[..., :3] != OUT[:3], axis=-1)
            cv.px[cone & wall & bayer_mask(level_a * 0.9)] = A0
            cv.px[cone & wall & bayer_mask(level_a * 0.2)] = A1
        # Placa de pared y pantalla de metal con la luz arriba y abajo.
        plate = rect_mask(sx - 6, 176, sx + 6, 218)
        drop_shadow(cv, plate)
        bevel(cv, plate, [OUT, (M2, M1, M0)], body=M0)
        shade = quad([(sx - 13, 186), (sx + 13, 186), (sx + 10, 208), (sx - 10, 208)])
        drop_shadow(cv, shade)
        bevel(cv, shade, [OUT, OUT, (M3, M2, M0), (M2, M1, M0)], body=M1)
        cv.rect(sx - 10, 185, 20, 2, A3)
        cv.rect(sx - 9, 183, 18, 2, A2)
        cv.rect(sx - 8, 208, 16, 2, A2)
        cv.rect(sx - 7, 210, 14, 1, A1)
        rivet(cv, sx, 197, light=True)


def build_case(cv):
    x0, y0, x1, y1 = CASE
    ox0, oy0, ox1, oy1 = OPEN
    bx0, by0 = to_vp(ox0, oy0, DEPTH)
    bx1, by1 = to_vp(ox1, oy1, DEPTH)
    bx0, by0, bx1, by1 = int(round(bx0)), int(round(by0)), int(round(bx1)), int(round(by1))
    case = rect_mask(x0, y0, x1, y1)
    cap = rect_mask(x0 - 8, y0 - 6, x1 + 8, y0 + 10)
    base_top = quad([(BASE_BACK[0], BASE_WALL), (BASE_BACK[1], BASE_WALL), (BASE[1], BASE_TOP), (BASE[0], BASE_TOP)])
    base_front = rect_mask(BASE[0], BASE_TOP, BASE[1], BASE[2])
    whole = case | cap | base_top | base_front
    # --- Interior: techo con la luz, laterales, suelo y fondo de terciopelo acolchado.
    ceil = quad([(ox0, oy0), (ox1, oy0), (bx1, by0), (bx0, by0)])
    lwall = quad([(ox0, oy0), (bx0, by0), (bx0, by1), (ox0, oy1)])
    rwall = quad([(ox1, oy0), (bx1, by0), (bx1, by1), (ox1, oy1)])
    shelf = quad([(bx0, by1), (bx1, by1), (ox1, oy1), (ox0, oy1)])
    back = rect_mask(bx0, by0, bx1 + 1, by1 + 1)
    cv.px[back] = VEL
    # Acolchado en rombos, con botones.
    u = (xs - 480) + (ys - 300)
    v = (xs - 480) - (ys - 300)
    STEP = 28
    lines = back & ((np.mod(u, STEP) < 2) | (np.mod(v, STEP) < 2))
    cv.px[lines] = VEL0
    cv.px[back & ((np.mod(u, STEP) == 2) | (np.mod(v, STEP) == 2))] = VEL2
    for i in range(-20, 21):
        for j in range(-20, 21):
            px_, py_ = 480 + (i * STEP + j * STEP) / 2, 300 + (i * STEP - j * STEP) / 2
            if bx0 + 3 < px_ < bx1 - 3 and by0 + 3 < py_ < by1 - 3:
                cv.template(["oo.", "ohs", ".ss"], {"o": VEL0, "h": VEL2, "s": D2}, int(px_) - 1, int(py_) - 1)
    # Luz cálida de arriba sobre el terciopelo.
    warm = back & bayer_mask(np.clip((by0 + 60 - ys) / 60 * 5, 0, 16)) & ~lines
    cv.px[warm] = c("1c2238")
    cv.px[lwall] = VEL2
    cv.px[lwall & bayer_mask(np.clip((oy0 + 120 - ys) / 120 * 6, 0, 16))] = c("1c2238")
    cv.px[rwall] = VEL0
    cv.px[shelf] = D4
    cv.px[shelf & (ys <= by1 + 1)] = D3
    cv.px[ceil] = D1
    # Tira de luz del techo de la vitrina.
    for (yy, col) in ((oy0 + 2, OUT), (oy0 + 3, A3), (oy0 + 4, A3), (oy0 + 5, A2), (oy0 + 6, OUT)):
        cv.px[ceil & (ys == yy) & (xs > ox0 + 24) & (xs < ox1 - 24)] = col
    cv.px[ceil & (ys > oy0 + 6) & bayer_mask(2)] = A0
    # Aristas del interior.
    for (a, b) in (((ox0, oy0), (bx0, by0)), ((ox1, oy0), (bx1, by0)), ((ox0, oy1), (bx0, by1)), ((ox1, oy1), (bx1, by1))):
        n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1])))
        for t in range(n + 1):
            cv.put(int(round(a[0] + (b[0] - a[0]) * t / n)), int(round(a[1] + (b[1] - a[1]) * t / n)), OUT)
    cv.rect(bx0, by0, bx1 - bx0 + 1, 1, OUT)
    cv.rect(bx0, by1, bx1 - bx0 + 1, 1, OUT)
    cv.rect(bx0, by0, 1, by1 - by0 + 1, OUT)
    cv.rect(bx1, by0, 1, by1 - by0 + 1, OUT)

    # --- Marco: metal oscuro con contorno de 2 px, bisel y un labio dorado alrededor del cristal.
    frame = case & ~rect_mask(ox0, oy0, ox1, oy1)
    bevel(cv, frame, [OUT, OUT, (D6, D5, D2), (D5, D4, D2), (D5, D4, D2)], body=D4)
    d_open, k_open = chamfer_terms(xs, ys, ox0, oy0, ox1, oy1)
    for dd, prof in ((1, OUT), (2, (A3, A2, A1)), (3, (A2, A1, A0)), (4, OUT)):
        sel = frame & (d_open == dd)
        if isinstance(prof, tuple) and isinstance(prof[0], tuple):
            cv.px[sel & np.isin(k_open, [2, 3])] = prof[0]
            cv.px[sel & np.isin(k_open, [0, 1])] = prof[2]
        else:
            cv.px[sel] = prof
    # Remate de arriba, un poco más ancho.
    bevel(cv, cap, [OUT, OUT, (D6, D5, D2), (D6, D5, D2), (D5, D4, D2)], body=D4)
    cv.rect(x0 - 2, y0 + 10, x1 - x0 + 4, 2, OUT)
    # Escuadras doradas en las esquinas del hueco.
    for (fx, fy) in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        L, Tk = 14, 4
        cx_ = ox0 - 5 if fx > 0 else ox1 + 4
        cy_ = oy0 - 5 if fy > 0 else oy1 + 4
        hx0 = cx_ if fx > 0 else cx_ - L + 1
        vy0 = cy_ if fy > 0 else cy_ - L + 1
        hy0 = cy_ if fy > 0 else cy_ - Tk + 1
        vx0 = cx_ if fx > 0 else cx_ - Tk + 1
        cv.rect(hx0 - 1, hy0 - 1, L + 2, Tk + 2, OUT)
        cv.rect(vx0 - 1, vy0 - 1, Tk + 2, L + 2, OUT)
        cv.rect(hx0, hy0, L, Tk, A2)
        cv.rect(vx0, vy0, Tk, L, A2)
        cv.rect(hx0, hy0, L, 1, A3)
        cv.rect(vx0, vy0, 1, L, A3)
        cv.rect(hx0, hy0 + Tk - 1, L, 1, A1)
        cv.rect(vx0 + Tk - 1, vy0, 1, L, A1)
    for (rx, ry) in ((x0 + 8, y0 + 18), (x1 - 9, y0 + 18), (x0 + 8, y1 - 9), (x1 - 9, y1 - 9)):
        rivet(cv, rx, ry)

    # --- Peana: la tapa de arriba se ve a los lados y delante de la vitrina, que está de pie encima.
    top_vis = base_top & ~case
    bevel(cv, top_vis, [OUT, (D6, D6, D5)], body=D5)
    cv.px[top_vis & (ys == BASE_WALL)] = OUT
    cv.px[top_vis & (ys >= BASE_TOP - 3)] = D6
    cv.px[top_vis & (ys == BASE_TOP - 1)] = M1
    # Sombra de la vitrina sobre la tapa: a su pie y hacia la derecha (luz arriba a la izquierda).
    cv.px[top_vis & (ys >= y1) & (ys < y1 + 3) & (xs >= x0) & (xs < x1 + 4)] = D3
    wedge = top_vis & (xs >= x1) & (xs < x1 + 14 + (ys - BASE_WALL) // 2) & (ys < y1 + 3)
    cv.px[wedge] = D3
    cv.px[wedge & bayer_mask(8) & (xs >= x1 + 8)] = D5
    # Pie de la vitrina: canto oscuro donde toca la tapa.
    cv.rect(x0, y1 - 2, x1 - x0, 2, OUT)
    bevel(cv, base_front, [OUT, OUT, (D6, D5, D2), (D5, D4, D2), (D5, D4, D2)], body=D4)
    cv.rect(BASE[0] + 4, BASE_TOP + 5, BASE[1] - BASE[0] - 8, 1, A2)
    cv.rect(BASE[0] + 4, BASE_TOP + 6, BASE[1] - BASE[0] - 8, 1, A1)
    panel = rect_mask(BASE[0] + 34, BASE_TOP + 16, BASE[1] - 34, BASE[2] - 14)
    bevel(cv, panel, [OUT, (D6, D4, OUT), (D5, D3, D2)], body=D3, sunk=True)
    for (rx, ry) in ((BASE[0] + 14, BASE_TOP + 16), (BASE[1] - 15, BASE_TOP + 16), (BASE[0] + 14, BASE[2] - 14), (BASE[1] - 15, BASE[2] - 14)):
        rivet(cv, rx, ry)
    insignia(cv, 480, (BASE_TOP + 16 + BASE[2] - 14) // 2)
    return (bx0, by0, bx1, by1)


def insignia(cv, cx, cy):
    """Estrella con alas, en oro, con facetas."""
    # Alas: cuatro plumas por lado, de arriba abajo, cada una más corta.
    for s in (-1, 1):
        for i in reversed(range(4)):
            ln = 44 - i * 9
            yy = cy - 9 + i * 6
            xa = cx + s * 15
            xb = xa + s * ln
            tip = 6
            pts = [(xa, yy), (xb - s * tip, yy), (xb, yy + 3), (xb - s * tip, yy + 6), (xa, yy + 6)]
            m = quad(pts)
            bevel(cv, m, [OUT, (A3, A2, A1)], body=A2 if i < 2 else A1)
    # Estrella de cinco puntas.
    r_out, r_in = 19, 8
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        r = r_out if k % 2 == 0 else r_in
        pts.append((cx + math.cos(a) * r, cy + 1 + math.sin(a) * r))
    star = quad(pts)
    dist = inner_dist(star, 2)
    ang = np.arctan2(ys - cy - 1, xs - cx)
    axes = np.array([-math.pi / 2 + k * 2 * math.pi / 5 for k in range(5)])
    diff = (ang[..., None] - axes[None, None, :] + math.pi) % (2 * math.pi) - math.pi
    nearest = np.argmin(np.abs(diff), axis=-1)
    side = np.sign(np.take_along_axis(diff, nearest[..., None], axis=-1)[..., 0])
    axis_ang = axes[nearest]
    face_ang = axis_ang + side * math.pi / 2
    light = np.cos(face_ang - (-3 * math.pi / 4))
    sel = star & (dist >= 1)
    cv.px[sel] = A2
    cv.px[sel & (light > 0.25)] = A3
    cv.px[sel & (light < -0.25)] = A1
    cv.px[star & (dist == 0)] = OUT
    cv.px[star & (np.hypot(xs - cx, ys - cy - 1) < 2.2)] = A4


# ---------------------------------------------------------------- medallas
MW, MH = 46, 72
DISC_CY = 49
FAMILIES = {"A": (A1, A2, A3), "R": (R1, R2, R3), "C": (C1, C2, C3)}


# Logros del juego (GameState.ACHIEVEMENTS) y color de su cinta.
ACH = [("first_win", "A"), ("flawless", "A"), ("wins_5", "A"), ("all_levels", "A"), ("kills_100", "R"), ("kills_1000", "R"),
       ("seen_10", "C"), ("turrets_50", "C"), ("fuse_first", "A"), ("fuse_all", "A"), ("power_first", "C"), ("perfect_10", "C")]
ICON_DIR = os.path.join(ROOT, "assets", "ui", "achievements")
PLATE = {OUT[:3], M1[:3], M0[:3]}  # colores de la placa de metal del icono, que se quita


def scale3x(img):
    """Scale3x: amplía ×3 suavizando las diagonales (img: lista de filas de colores o None)."""
    h, w = len(img), len(img[0])
    g = lambda x, y: img[y][x] if 0 <= x < w and 0 <= y < h else None
    out = [[None] * (w * 3) for _ in range(h * 3)]
    for y in range(h):
        for x in range(w):
            A, B, C = g(x - 1, y - 1), g(x, y - 1), g(x + 1, y - 1)
            D, E, F = g(x - 1, y), g(x, y), g(x + 1, y)
            G, Hh, I = g(x - 1, y + 1), g(x, y + 1), g(x + 1, y + 1)
            e = [E] * 9
            if B != Hh and D != F:
                e[0] = D if D == B else E
                e[1] = B if (D == B and E != C) or (B == F and E != A) else E
                e[2] = F if B == F else E
                e[3] = D if (D == B and E != G) or (D == Hh and E != A) else E
                e[5] = F if (B == F and E != I) or (Hh == F and E != C) else E
                e[6] = D if D == Hh else E
                e[7] = Hh if (D == Hh and E != I) or (Hh == F and E != G) else E
                e[8] = F if Hh == F else E
            for k in range(9):
                out[y * 3 + k // 3][x * 3 + k % 3] = e[k]
    return out


def symbol(ach_id):
    """El símbolo del icono del logro, sin la placa, ampliado ×3 y con contorno de 1 px."""
    from PIL import Image
    im = Image.open(os.path.join(ICON_DIR, ach_id + ".png")).convert("RGBA")
    px = im.load()
    pts = [(x, y) for y in range(im.height) for x in range(im.width) if px[x, y][3] >= 128 and px[x, y][:3] not in PLATE]
    x0, x1 = min(p[0] for p in pts), max(p[0] for p in pts)
    y0, y1 = min(p[1] for p in pts), max(p[1] for p in pts)
    keep = set(pts)
    img = [[px[x, y][:3] + (255,) if (x, y) in keep else None for x in range(x0, x1 + 1)] for y in range(y0, y1 + 1)]
    big = scale3x(img)
    h, w = len(big) + 2, len(big[0]) + 2
    out = [[None] * w for _ in range(h)]
    for y, row in enumerate(big):
        for x, col in enumerate(row):
            out[y + 1][x + 1] = col
    on = lambda x, y: 0 <= x < w and 0 <= y < h and out[y][x] is not None and out[y][x] != OUT
    for y in range(h):
        for x in range(w):
            if out[y][x] is None and (on(x - 1, y) or on(x + 1, y) or on(x, y - 1) or on(x, y + 1)):
                out[y][x] = OUT
    return out


def build_medal(ach_id, fam):
    cv = Canvas(MW, MH)
    k0, k1, k2 = FAMILIES[fam]
    cx = MW // 2
    # Cinta con rayas (contorno de 2 px) y el pasador de arriba.
    stripes = [k0, k0, k1, k1, k1, k2, k2, k2, A4, A4, A4, k2, k2, k2, k1, k1, k1, k0, k0, k0]
    cv.rect(cx - 12, 3, 24, 24, OUT)
    for i, col in enumerate(stripes):
        cv.rect(cx - 10 + i, 5, 1, 21, col)
    cv.rect(cx - 10, 5, 20, 1, k2)
    cv.rect(cx - 10, 23, 20, 2, k0)
    cv.rect(cx - 14, 0, 28, 7, OUT)
    cv.rect(cx - 12, 1, 24, 4, A2)
    cv.rect(cx - 12, 1, 24, 1, A3)
    cv.rect(cx - 12, 4, 24, 1, A1)
    # Anilla.
    cv.template([".oooo.", "oaAAao", "oa..ao", "o....o"], {"o": OUT, "a": A1, "A": A2}, cx - 3, 25)
    # Disco: contorno de 2 px, canto dorado biselado y esmalte oscuro con el símbolo grande.
    my, mx = np.mgrid[0:MH, 0:MW]
    r = np.hypot(mx - cx + 0.5, my - DISC_CY + 0.5)
    ang = np.arctan2(my - DISC_CY + 0.5, mx - cx + 0.5)
    lit = np.cos(ang - (-3 * math.pi / 4))
    cv.px[(r <= 22.5) & (r > 20.5)] = OUT
    rim = (r <= 20.5) & (r > 16.8)
    cv.px[rim] = A2
    cv.px[rim & (lit > 0.35)] = A3
    cv.px[rim & (lit < -0.35)] = A1
    cv.px[rim & (r <= 17.8) & (lit > 0.35)] = A2
    cv.px[rim & (r <= 17.8) & (lit < -0.35)] = A3
    cv.px[(r <= 16.8) & (r > 15.8)] = OUT
    enamel = r <= 15.8
    cv.px[enamel] = D1
    cv.px[enamel & (r > 14.6) & (lit < -0.2)] = D3
    sym = symbol(ach_id)
    sh, sw = len(sym), len(sym[0])
    sx, sy = cx - sw // 2, DISC_CY - sh // 2
    for y, row in enumerate(sym):
        for x, col in enumerate(row):
            if col is not None:
                cv.put(sx + x, sy + y, col)
    cv.save("medal_%s.png" % ach_id)


def build_empty():
    """Hueco de una medalla que falta: el alfiler y la marca tenue de la cinta y el disco."""
    cv = Canvas(MW, MH)
    cx = MW // 2
    mark = c("131e34")
    my, mx = np.mgrid[0:MH, 0:MW]
    r = np.hypot(mx - cx + 0.5, my - DISC_CY + 0.5)
    dots = ((mx + my) % 2) == 0
    cv.px[(r <= 22.5) & (r > 20.5) & dots] = mark
    rib = np.zeros((MH, MW), bool)
    rib[3:27, cx - 12:cx - 10] = True
    rib[3:27, cx + 10:cx + 12] = True
    cv.px[rib & dots] = mark
    cv.template(["oo..oo", "ohhhho", "osssso", ".oooo."], {"o": OUT, "h": D6, "s": D4}, cx - 3, 1)
    cv.save("medal_empty.png")


def medal_positions():
    """Filas de 5, 4 y 3, centradas y escalonadas medio paso, sin solaparse y con margen en el fondo."""
    ox0, oy0, ox1, oy1 = OPEN
    by0, by1 = to_vp(ox0, oy0, DEPTH)[1], to_vp(ox1, oy1, DEPTH)[1]
    pitch, gap = 66, 11
    top0 = int(round((by0 + by1) / 2 - (3 * MH + 2 * gap) / 2))
    pos = []
    for row, n in enumerate((5, 4, 3)):
        for i in range(n):
            pos.append([480 + int(round((i - (n - 1) / 2) * pitch)), top0 + row * (MH + gap)])
    return pos


def build_glass():
    cv = Canvas(W, H)
    ox0, oy0, ox1, oy1 = OPEN
    for y in range(oy0, oy1):
        for (off, wd, a) in ((40, 22, 18), (70, 6, 22), (240, 30, 14), (278, 8, 20)):
            xs0 = ox0 + off - int((y - oy0) * 0.8)
            for x in range(max(xs0, ox0), min(xs0 + wd, ox1)):
                cv.px[y, x] = (190, 250, 255, a)
    cv.rect(ox0, oy0, ox1 - ox0, 1, (190, 250, 255, 70))
    cv.rect(ox0, oy0, 1, oy1 - oy0, (190, 250, 255, 45))
    cv.save("case_glass.png")


def main():
    cv = build_side_room()
    build_sconces(cv)
    back = build_case(cv)
    cv.save("right_static.png")
    build_glass()
    for ach_id, fam in ACH:
        build_medal(ach_id, fam)
    build_empty()
    meta = {
        "case": list(CASE), "open": list(OPEN), "back": list(back),
        "base": [BASE[0], BASE_TOP, BASE[1], BASE[2]],
        "medal": {"w": MW, "h": MH, "disc_cy": DISC_CY, "r": 22},
        "medals": medal_positions(),
    }
    print("ok derecha")
    return meta


if __name__ == "__main__":
    main()
