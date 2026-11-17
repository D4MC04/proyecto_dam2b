# Genera los PNG de la vista izquierda de la oficina, píxel a píxel: la habitación, el marco de la
# puerta con su luz, las dos hojas, el pasillo de detrás, el panel de acceso y la pantalla de stats.
# Mismo método que gen_center.py: perfiles por distancia al borde (luz arriba a la izquierda).
import json, os
import numpy as np
from pixkit import *

ys, xs = np.mgrid[0:H, 0:W]

# ---------------------------------------------------------------- puerta
DOOR_OUT = (93, 135, 438, 52)     # x0, y0, x1, recorte de las esquinas de arriba
DOOR_HOLE = (115, 157, 416, 40)
PLANE = (126, 161, 418, 39)       # plano de las hojas: el hueco un poco más hondo, hacia el punto de fuga
SEAM_X0, SEAM_X1, SEAM_Y = 248, 294, 282  # junta en zigzag: baja en x0, cruza a 45° y baja en x1
STRIPS = [(151, 250, 6, 136), (386, 250, 6, 136)]  # franjas de luz de las hojas (con su contorno)
SLIDE = 26  # la puerta solo se entreabre: cada hoja se aparta 26 px
BAR = (206, 106, 120, 18)          # carcasa de la barra de estado encima de la puerta


def chamf_mask(x0, y0, x1, ch, y1=600):
    d, k = chamfer_terms(xs, ys, x0, y0, x1, y1, tl=ch, tr=ch)
    return d, k


def seam_x(y):
    return np.where(y < SEAM_Y, SEAM_X0, np.where(y < SEAM_Y + (SEAM_X1 - SEAM_X0), SEAM_X0 + (y - SEAM_Y), SEAM_X1))


def build_frame(cv):
    d_out, _ = chamf_mask(DOOR_OUT[0], DOOR_OUT[1], DOOR_OUT[2], DOOR_OUT[3])
    d_hole, k_hole = chamf_mask(DOOR_HOLE[0], DOOR_HOLE[1], DOOR_HOLE[2], DOOR_HOLE[3])
    room = ys < FLOOR
    outer = (d_out <= 0) & room
    hole = (d_hole <= 0) & room
    frame = outer & ~hole
    cv.px[frame] = D3
    # Canto de fuera: contorno de 2 px y bisel con luz arriba a la izquierda.
    di = -d_out
    _, k_out = chamf_mask(DOOR_OUT[0], DOOR_OUT[1], DOOR_OUT[2], DOOR_OUT[3])
    # Marco empotrado en la pared, a ras: ranura de 2 px y el canto de dentro de la ranura en sombra.
    shade_by_profile(cv, frame & (di < 5), di, k_out, [OUT, OUT, (D2, D3, D5), (D3, D3, D4), D3], [0, 1, 4], [5])
    # Canto de dentro (hacia el hueco): da a la luz solo el lado derecho.
    prof_in = [None, OUT, OUT, (D5, D4, D1), (D4, D3, D1)]
    sel = frame & (d_hole < len(prof_in))
    shade_by_profile(cv, sel, d_hole, k_hole, [p if p is not None else D3 for p in prof_in], [2], [5])
    # Ranura de luz que sigue la forma del marco.
    glow = {}
    for dd, col in ((8, OUT), (9, C1), (10, C0), (11, OUT)):
        m = frame & (d_hole == dd)
        cv.px[m] = col
        glow[dd] = m
    # Remaches en la cara del marco.
    for y in range(200, FLOOR - 20, 56):
        rivet(cv, 104, y)
        rivet(cv, 427, y)
    # Jamba: el grosor del hueco hasta el plano de las hojas (solo se ve la izquierda y arriba).
    d_pl, k_pl = chamf_mask(PLANE[0], PLANE[1], PLANE[2], PLANE[3])
    plane = (d_pl <= 0) & room
    jamb = hole & ~plane
    cv.px[jamb & np.isin(k_pl, [0])] = D2
    cv.px[jamb & np.isin(k_pl, [1, 4, 5])] = D1
    cv.px[jamb & (d_hole == 0)] = OUT
    cv.px[jamb & (d_pl == 1)] = OUT
    # Canto de luz de la jamba izquierda.
    cv.px[jamb & (k_pl == 0) & (d_pl == 2)] = D4
    # Luz del marco encendida (la enciende OfficeDoor al pasar el ratón).
    lit = Canvas(W, H)
    lit.px[glow[9]] = C3
    lit.px[glow[10]] = C2
    for dd, col in ((8, C1), (11, C1)):
        lit.px[glow[dd] & bayer_mask(8)] = col
    lit.save("door_glow.png")
    return plane


def build_skirting_ends(cv):
    """El zócalo se corta contra el marco (que está en la pared): se ve su testa a la izquierda."""
    x0, x1 = DOOR_OUT[0], DOOR_OUT[2]
    cv.rect(x0 - 5, SKIRT, 1, FLOOR - SKIRT, OUT)
    cv.rect(x0 - 4, SKIRT, 4, FLOOR - SKIRT, D2)
    cv.rect(x0 - 4, SKIRT + 1, 4, 1, D4)
    cv.rect(x1, SKIRT, 1, FLOOR - SKIRT, OUT)
    # Umbral: chapa a ras del suelo en el hueco de la puerta.
    hx0, hx1 = DOOR_HOLE[0], DOOR_HOLE[2]
    for i, col in enumerate((OUT, M1, M0, OUT)):
        cv.rect(hx0, FLOOR + i, hx1 - hx0, 1, col)


def build_leaves(plane):
    y_ok = ys < FLOOR
    sx = seam_x(ys)
    masks = {"l": plane & y_ok & (xs <= sx), "r": plane & y_ok & (xs > sx)}
    for key, m in masks.items():
        cv = Canvas(W, H)
        dist = bevel(cv, m, [OUT, (D6, D5, D2), (D6, D5, D2), (D5, D4, D2)], body=D4)
        # Placa del medio, en relieve, entre las dos juntas.
        mid = m & (dist >= 3) & (ys >= 244) & (ys <= 392)
        mid = mid & (inner_dist(m, 12) >= 12)
        bevel(cv, mid, [(D6, D5, D2), (D5, D4, D2), (D5, D4, D2)], body=D4)
        # Juntas horizontales: ranura de 2 px con canto de luz debajo.
        for y in (232, 398):
            row = m & (dist >= 2) & (ys >= y) & (ys < y + 2)
            cv.px[row] = OUT
            cv.px[m & (dist >= 2) & (ys == y + 2)] = D6
            cv.px[m & (dist >= 2) & (ys == y - 1)] = D2
        # Zócalo de la hoja más oscuro.
        kick = m & (dist >= 3) & (ys >= 401)
        cv.px[kick & bayer_mask(6)] = D3
        # Franja de luz hundida (la enciende OfficeDoor).
        fx, fy, fw, fh = STRIPS[0] if key == "l" else STRIPS[1]
        cv.rect(fx - 1, fy - 1, fw + 2, fh + 2, D2)
        cv.rect(fx, fy, fw, fh, OUT)
        cv.rect(fx + 1, fy + 1, fw - 2, fh - 2, C0)
        cv.rect(fx - 1, fy + fh + 1, fw + 2, 1, D6)
        # Remaches del zócalo y de arriba.
        bx0, bx1 = (140, 230) if key == "l" else (312, 400)
        for x in (bx0, bx1):
            rivet(cv, x, 420)
            rivet(cv, x, 452)
        cv.save("door_leaf_%s.png" % key)
    # Junta encendida (puerta cerrada): las dos líneas de contorno que se tocan.
    seam = Canvas(W, H)
    for y in range(PLANE[1], FLOOR):
        x = int(seam_x(np.array(y)))
        seam.put(x, y, C2)
        seam.put(x + 1, y, C2)
        if y % 2 == 0:
            seam.put(x - 1, y, C1)
            seam.put(x + 2, y, C1)
    seam.save("door_seam.png")
    # Máscara del plano de las hojas (para recortarlas al abrir).
    pm = Canvas(W, H)
    pm.px[plane & y_ok] = (255, 255, 255, 255)
    pm.save("door_plane.png")


def build_corridor(plane):
    """Lo que se ve por la rendija al entreabrir: luz del pasillo y su suelo, sin más detalle."""
    cv = Canvas(W, H)
    m = plane & (ys < FLOOR)
    cx = (SEAM_X0 + SEAM_X1) / 2
    near = np.clip(1 - np.abs(xs - cx) / 90, 0, 1)
    cv.px[m] = C1
    cv.px[m & bayer_mask(near * 9)] = C2
    cv.px[m & bayer_mask((near - 0.7) * 14)] = C3
    # Suelo del pasillo: más claro al fondo.
    floor = m & (ys >= 404)
    cv.px[floor] = C1
    cv.px[floor & bayer_mask(np.clip((436 - ys) / 32 * 10, 0, 16))] = C2
    cv.rect(0, 404, W, 1, C2)
    cv.px[~m] = CLEAR
    cv.save("corridor.png")


# ---------------------------------------------------------------- panel de acceso
ACCESS = (456, 230, 52, 112)


def build_access(cv):
    """Pantallita y teclado, sin lector de palma."""
    x, y, w, h = ACCESS
    d, k = chamfer_terms(xs, ys, x, y, x + w, y + h, tl=6, br=6)
    m = d <= 0
    drop_shadow(cv, m)
    shade_by_profile(cv, m & (-d < 5), -d, k, [OUT, OUT, (M3, M2, M0), (M2, M1, M0), (M2, M1, M0)], [0, 1, 4], [5, 6])
    cv.px[m & (-d >= 5)] = M1
    # Pantallita hundida.
    sx0, sy0, sx1, sy1 = x + 7, y + 8, x + w - 7, y + 32
    sm = rect_mask(sx0, sy0, sx1, sy1)
    bevel(cv, sm, [(M2, M1, OUT), (M3, M2, D2), OUT], body=G0, sunk=True)
    for i, ln in enumerate((22, 14, 26)):
        cv.rect(sx0 + 4, sy0 + 5 + i * 5, ln, 2, G1)
    lit = Canvas(W, H)
    inner = sm & (inner_dist(sm, 3) >= 3)
    lit.px[inner] = G1
    for i, ln in enumerate((22, 14, 26)):
        lit.rect(sx0 + 4, sy0 + 5 + i * 5, ln, 2, G3 if i != 1 else G2)
    lit.save("access_lit.png")
    # Teclado: 3x4 teclas grandes con volumen.
    for j in range(4):
        for i in range(3):
            kx, ky = x + 7 + i * 13, y + 39 + j * 14
            cv.rect(kx, ky, 12, 12, OUT)
            cv.rect(kx + 1, ky + 1, 10, 10, D5)
            cv.rect(kx + 1, ky + 1, 10, 1, D6)
            cv.rect(kx + 1, ky + 1, 1, 10, D6)
            cv.rect(kx + 1, ky + 10, 10, 1, D3)
            cv.rect(kx + 10, ky + 1, 1, 10, D3)
    for i, (col, p) in enumerate((("G2", 1.4), ("C2", 0), ("A2", 0.8))):
        led_housing(cv, x + 9 + i * 13, y + 101, col, p, 6, 2)


# ---------------------------------------------------------------- pantalla de stats
STATS = (524, 87, 376, 330)


def build_stats(cv):
    x, y, w, h = STATS
    d, k = chamfer_terms(xs, ys, x, y, x + w, y + h, tl=10, br=10)
    m = d <= 0
    drop_shadow(cv, m)
    shade_by_profile(cv, m & (-d < 5), -d, k, [OUT, OUT, (D6, D5, D2), (D6, D5, D2), (D5, D4, D2)], [0, 1, 4], [5, 6])
    cv.px[m & (-d >= 5)] = D4
    # Pantalla hundida: el canto de arriba en sombra.
    bx, by, bw, bh = x + 16, y + 16, w - 32, h - 56
    sm = rect_mask(bx, by, bx + bw, by + bh)
    bevel(cv, sm, [OUT, (D6, D4, OUT), (D5, D3, OUT), OUT], body=S1, sunk=True)
    screen = [bx + 4, by + 4, bw - 8, bh - 8]
    # Remaches de las esquinas.
    for (rx, ry) in ((x + 9, y + 9), (x + w - 10, y + 9), (x + 9, y + h - 10), (x + w - 10, y + h - 10)):
        rivet(cv, rx, ry)
    # Labio de abajo: rejilla del altavoz y pilotos.
    ly = by + bh + 10
    for i in range(18):
        gx = x + w // 2 - 107 + i * 12
        cv.rect(gx, ly, 8, 14, OUT)
        cv.rect(gx, ly + 12, 8, 2, D5)
        cv.rect(gx + 1, ly + 1, 6, 1, D2)
    for i, col in enumerate(("G2", "C2")):
        led_housing(cv, x + 26 + i * 10, ly + 5, col, 0 if i == 0 else 2.2, 6, 3)
    led_housing(cv, x + w - 34, ly + 5, "A2", 1.1, 6, 3)
    return screen


def build_bar(cv):
    x, y, w, h = BAR
    m = rect_mask(x, y, x + w, y + h)
    drop_shadow(cv, m, 3, 3)
    bevel(cv, m, [OUT, OUT, (D6, D5, D2), (D5, D4, D2)], body=D4)
    cv.rect(x + 7, y + 6, w - 14, 6, OUT)
    cv.rect(x + 8, y + 7, w - 16, 4, D1)
    return [x + 8, y + 7, w - 16, 4]


def main():
    cv = build_side_room()
    plane = build_frame(cv)
    build_skirting_ends(cv)
    bar = build_bar(cv)
    build_access(cv)
    screen = build_stats(cv)
    cv.save("left_static.png")
    build_leaves(plane)
    build_corridor(plane)
    meta = {
        "door": {"rect": [DOOR_OUT[0], DOOR_OUT[1], DOOR_OUT[2] - DOOR_OUT[0], FLOOR - DOOR_OUT[1]], "slide": SLIDE, "seam_x": SEAM_X1, "floor": FLOOR,
                 "strips": [[x + 1, y + 1, w - 2, h - 2] for (x, y, w, h) in STRIPS], "bar": bar},
        "access": list(ACCESS),
        "stats": {"rect": list(STATS), "screen": screen},
        "leds": LEDS,
    }
    print("ok izquierda", len(LEDS), "pilotos")
    return meta


if __name__ == "__main__":
    main()
