# Genera los PNG de la vista central de la oficina, píxel a píxel: marco del ventanal, alféizar,
# consola inclinada pegada al ventanal, mesa del radar, módulo de opciones, bandeja y tablet.
# Los marcos se sombrean por perfiles (distancia al borde -> color, con luz arriba a la izquierda),
# los detalles pequeños son plantillas de texto (un carácter por píxel).
import json, os
import numpy as np
from pixkit import *


# ================================================================ VISTA CENTRAL
PANES = [(12, 20, 250, 262), (276, 20, 684, 262), (710, 20, 948, 262)]
PANE_CH = 18
SILL = 262
TOP = 298


def build_center():
    cv = Canvas(W, H)
    ys, xs = np.mgrid[0:H, 0:W]
    # --- Estructura del ventanal: distancia hacia fuera desde la hoja más cercana.
    dist = np.full((H, W), 10 ** 6)
    cls = np.zeros((H, W), int)
    for (x0, y0, x1, y1) in PANES:
        d, k = chamfer_terms(xs, ys, x0, y0, x1, y1, tl=PANE_CH, tr=PANE_CH)
        better = d < dist
        dist[better] = d[better]
        cls[better] = k[better]
    region = ys < SILL + 2
    # Junta con luz, bisel hacia el cristal (sombreado según hacia dónde mira) y cara del marco con una ranura.
    slope = (D6, D5, D2)
    profile = [None, OUT, C1, C0, OUT, slope, slope, (c("5c667a"), D5, D2), D5, D4, D4, D4, OUT, D5, D4, D4, D3, D2, OUT]
    light_cls, mid_cls = [2, 3], [5]
    inside = dist <= 0
    cv.px[region & (dist >= len(profile))] = D1
    prof = [p if p is not None else CLEAR for p in profile]
    shade_by_profile(cv, region & ~inside, dist, cls, prof, light_cls, mid_cls)
    # Remaches sobre la cara del marco.
    for (x0, y0, x1, y1) in PANES:
        for x in range(x0 + 26, x1 - 20, 34):
            rivet(cv, x, y0 - 10)
        for y in range(y0 + 30, SILL - 10, 34):
            if x0 < 20:
                rivet(cv, x0 - 7, y)
            if x1 > 940:
                rivet(cv, x1 + 6, y)
    for px in (263, 697):
        for y in range(48, SILL - 10, 34):
            rivet(cv, px, y)
    # Reflejos del cristal y brillo de las pantallas abajo.
    for i, (x0, y0, x1, y1) in enumerate(PANES):
        for y in range(y0, y1):
            for off, wd in ((150, 18), (180, 6)):
                xs0 = x0 + off - (y - y0) + (60 if i == 1 else 0)
                for x in range(max(xs0, x0), min(xs0 + wd, x1)):
                    if not inside[y, x]:
                        continue
                    cv.blend(x, y, (190, 250, 255, 16))
        for y in range(y1 - 40, y1):
            k = (y - (y1 - 40)) / 40
            for x in range(x0, x1):
                if inside[y, x] and ((x + y * 2) % 4 == 0 if k < 0.5 else (x + y) % 2 == 0) and k > 0.15:
                    cv.blend(x, y, (64, 224, 240, 22))
    # Los píxeles del cristal quedan transparentes salvo reflejos.
    clamps = build_console(cv, ys, xs)
    return cv, ys, xs, clamps


# ---------------------------------------------------------------- consola inclinada
# Vista en tercera persona: la consola sube desde el jugador hasta el ventanal y se pega a él. Las
# piezas son rectángulos apoyados en la superficie inclinada: se ve su canto de delante (abajo) y su
# sombra cae hacia el jugador.
# Barra de luz entre el ventanal y la consola, de arriba abajo: carcasa de metal, tubo de luz de 5 filas
# (núcleo blanco azulado) y sombra bajo la carcasa. Abrazaderas de metal atornilladas bajo los
# montantes del ventanal y anillas pequeñas que parten el tubo en tramos.
BAR_ROWS = [OUT, D6, D5, OUT, C1, C2, C3, C2, C1, OUT, D2]
TUBE_Y, TUBE_H = SILL + 4, 5
BIG_CLAMPS = (263, 697)                       # centros, bajo los montantes
SMALL_CLAMPS = (70, 131, 192, 372, 480, 588, 768, 829, 890)
SURF_TOP = SILL + len(BAR_ROWS)   # empieza la franja de los pilotos, justo bajo la barra
BAND_H = 14
SEAM = SURF_TOP + BAND_H   # junta entre la franja (fina) de los pilotos y la superficie de trabajo
LIP = 520             # borde delantero
LIP_ROWS = [OUT, D6, D6, D5, D5, D4, D4, D4, OUT, C0, C1, C0, OUT, D3, D3, D2, D2, D1, OUT, OUT]


def thickness(cv, face, rows):
    """Canto de delante de una pieza apoyada en la superficie: la cara desplazada hacia abajo,
    una fila de color por píxel de grosor, con contorno a los lados y abajo."""
    edge = np.zeros_like(face)
    prev = face.copy()
    for d, col in enumerate(rows, 1):
        sh = np.zeros_like(face)
        sh[d:] = face[:-d]
        m = sh & ~prev
        cv.px[m] = col
        edge |= m
        prev |= sh
    solid = face | edge
    side = edge & ~(np.roll(solid, 1, 1) & np.roll(solid, -1, 1))
    cv.px[side] = OUT
    bottom = edge & ~np.roll(solid, -1, 0)
    cv.px[bottom] = OUT
    return solid


def shadow_on_surface(cv, solid, dx=3, dy=7):
    """Sombra que cae hacia el jugador (la luz viene del ventanal)."""
    sh = np.zeros_like(solid)
    sh[dy:, dx:] = solid[:-dy, :-dx]
    sel = sh & ~solid
    cv.px[sel, :3] = (cv.px[sel, :3] * 0.55).astype(np.uint8)


def build_light_bar(cv, ys, xs):
    """Barra de luz de lado a lado; devuelve los tramos [x, ancho] que tapan las abrazaderas."""
    for i, col in enumerate(BAR_ROWS):
        cv.rect(0, SILL + i, W, 1, col)
    # Reflejo del tubo en la carcasa: trama cian tenue en la fila de metal de encima.
    cv.px[(ys == SILL + 2) & bayer_mask(4)] = C0
    clamps = []
    # Anillas: 4 px de metal que abrazan el tubo, con contorno.
    for x in SMALL_CLAMPS:
        cv.rect(x - 3, TUBE_Y - 1, 6, TUBE_H + 2, OUT)
        cv.rect(x - 2, TUBE_Y, 4, TUBE_H, M1)
        cv.rect(x - 2, TUBE_Y, 1, TUBE_H, M2)
        cv.rect(x + 1, TUBE_Y, 1, TUBE_H, M0)
        cv.put(x - 2, TUBE_Y, M3)
        clamps.append([x - 3, 6])
    # Abrazaderas grandes: placa de 17x15 con bisel que sobresale de la barra, con el remache en su
    # centro exacto y una ranura encima y otra debajo.
    for x in BIG_CLAMPS:
        cy = TUBE_Y + 1
        m = rect_mask(x - 8, cy - 7, x + 9, cy + 8)
        bevel(cv, m, [OUT, (M3, M2, M0), (M2, M1, M0)], body=M1)
        cv.rect(x - 5, cy - 4, 11, 1, M0)
        cv.rect(x - 5, cy + 4, 11, 1, M0)
        rivet(cv, x, cy, light=True)
        clamps.append([x - 8, 17])
    return sorted(clamps)


def build_console(cv, ys, xs):
    clamps = build_light_bar(cv, ys, xs)
    # Franja de arriba, junto al cristal: le llega la luz de fuera y lleva los pilotos.
    cv.rect(0, SURF_TOP, W, SEAM - SURF_TOP, D4)
    band = (ys >= SURF_TOP) & (ys < SEAM)
    cv.px[band & bayer_mask(np.clip((SEAM - ys) / BAND_H * 9, 0, 16))] = D5
    cv.px[band & bayer_mask(np.clip((SURF_TOP + 4 - ys) / 4 * 5, 0, 16))] = C0
    pal = ["C2", "C2", "A2", "C2", "G2", "C2"]
    for n, x in enumerate(range(30, W - 30, 50)):
        led_housing(cv, x, SURF_TOP + (BAND_H - 3) // 2, pal[n % 6], 1.6 if n % 7 == 3 else 0, 14, 3)
    for i, col in enumerate([OUT, OUT, D5]):
        cv.rect(0, SEAM + i, W, 1, col)
    # Superficie de trabajo: más clara lejos (junto a la luz) y más oscura cerca del jugador.
    cv.rect(0, SEAM + 3, W, LIP - SEAM - 3, D3)
    near = (ys >= 440) & (ys < LIP)
    cv.px[near & bayer_mask(np.clip((ys - 440) / 80 * 9, 0, 16))] = D2
    far = (ys >= SEAM + 3) & (ys < SEAM + 20)
    cv.px[far & bayer_mask(np.clip((SEAM + 20 - ys) / 17 * 6, 0, 16))] = D4
    # Borde delantero redondeado, con una tira de luz.
    for i, col in enumerate(LIP_ROWS):
        cv.rect(0, LIP + i, W, 1, col)
    for x in range(20, W - 10, 40):
        cv.rect(x, LIP + 10, 22, 1, C2)
    return clamps


# ---------------------------------------------------------------- plano inclinado
# Todas las piezas se apoyan en el mismo plano: una x "de mundo" X se ve en la fila y en
# 480 + (X - 480) * kk(y), que crece hacia el jugador (las piezas se ensanchan hacia abajo).
# El plano empieza en SILL + 4 (no en SURF_TOP) para que la barra de luz no mueva las piezas.
PLANE_Y0, PLANE_Y1, ALPHA = SILL + 4, LIP, 0.25


def kk(y):
    return 1 + (y - PLANE_Y0) / (PLANE_Y1 - PLANE_Y0) * ALPHA


def to_screen(X, y):
    return 480 + (X - 480) * kk(y)


def plane_rect(ys, xs, X0, y0, X1, y1, tl=0, br=0):
    """Máscara de un rectángulo de mundo apoyado en el plano."""
    wx = 480 + (xs + 0.5 - 480) / kk(ys)
    d, _ = chamfer_terms(wx, ys, X0, y0, X1, y1, tl=tl, br=br)
    return d <= 0


def quad_of(m, ox=0, oy=0):
    """Trapecio de una máscara: filas de arriba y abajo y sus extremos (para OfficeLayout)."""
    rows = np.where(m.any(1))[0]
    top, bot = int(rows.min()), int(rows.max())
    rt, rb = np.where(m[top])[0], np.where(m[bot])[0]
    return {"top": top + oy, "bot": bot + oy, "tl": int(rt.min()) + ox, "tr": int(rt.max()) + 1 + ox,
            "bl": int(rb.min()) + ox, "br": int(rb.max()) + 1 + ox}


def bbox_of(m, extra_h=0):
    """Caja [x, y, ancho, alto] de una máscara (más `extra_h` filas de canto abajo)."""
    rows, cols = np.where(m.any(1))[0], np.where(m.any(0))[0]
    return [int(cols.min()), int(rows.min()), int(cols.max() - cols.min() + 1), int(rows.max() - rows.min() + 1 + extra_h)]


def rnd(v):
    """Redondeo como roundi() de Godot (mitades hacia fuera), para que coincidan los dos lados."""
    return int(np.floor(v + 0.5)) if v >= 0 else -int(np.floor(-v + 0.5))


def plane_corners(X0, y0, X1, y1, extra_h=0):
    """Esquinas [arriba izq., arriba der., abajo der., abajo izq.] de un rectángulo de mundo, en
    píxeles de la vista y con el borde derecho y el de abajo por fuera (más `extra_h` filas de canto).
    Para los corchetes inclinados del ratón."""
    return [[rnd(to_screen(X0, y0)), y0], [rnd(to_screen(X1, y0)), y0],
            [rnd(to_screen(X1, y1)), y1 + 1 + extra_h], [rnd(to_screen(X0, y1)), y1 + 1 + extra_h]]


def lean_quad(X, top, bot, w):
    """Trapecio (claves de OfficeLayout) de una pieza de `w` px de ancho que se inclina con el plano
    alrededor de la x de mundo X: sus lados siguen la línea X de top a bot."""
    tl, bl = rnd(to_screen(X, top) - w / 2), rnd(to_screen(X, bot) - w / 2)
    return {"top": top, "bot": bot, "tl": tl, "tr": tl + w, "bl": bl, "br": bl + w}


def lean_x(q, y):
    """Izquierda de la fila y de un trapecio de lean_quad, igual que OfficePaint.quad_span."""
    v = (y - q["top"]) / max(q["bot"] - q["top"], 1)
    return rnd(q["tl"] + (q["bl"] - q["tl"]) * v)


def plane_seam(cv, X, y0, y1):
    for y in range(y0, y1):
        x = int(round(to_screen(X, y)))
        cv.put(x, y, OUT)
        cv.put(x + 1, y, OUT)
        cv.put(x + 2, y, D5)


# ---------------------------------------------------------------- mesa del radar
TABLE = (115, 314, 503, 494)    # rectángulo de mundo: X0, y0, X1, y1
TABLE_EDGE = [M0, M0, D6, D6, D5, D5, D4, D4]
TABLE_INSET = 14


def build_table(cv, ys, xs):
    X0, y0, X1, y1 = TABLE
    face = plane_rect(ys, xs, X0, y0, X1, y1)
    solid = face.copy()
    for dd in range(1, len(TABLE_EDGE) + 1):
        solid |= np.roll(face, dd, 0)
    shadow_on_surface(cv, solid)
    thickness(cv, face, TABLE_EDGE)
    prof = [OUT, OUT, (M3, M2, M1), (M2, M1, M0), M1, M1, (M2, M1, M1), M1, M1, M0, M0, D2, OUT, OUT]
    dist = bevel(cv, face, prof, body=S1)
    # Proyectores en las cuatro esquinas.
    EMIT = ["oooooooooooo", "ommmmmmmmmmo", "omhaaaaaahso", "omaccccccaso", "omacbbbbcaso", "omaccccccaso", "omssssssssso", "oooooooooooo"]
    pal = {"o": OUT, "m": M2, "h": M3, "a": A1, "c": A2, "b": A3, "s": M0}
    q = quad_of(face)
    for (x, y) in [(q["tl"] + 1, y0 + 1), (q["tr"] - 13, y0 + 1), (q["bl"] + 1, y1 - 9), (q["br"] - 13, y1 - 9)]:
        cv.template(EMIT, pal, x, y)
    for X in range(X0 + 60, X1 - 60, 22):
        led_housing(cv, int(to_screen(X, y0 + 4)), y0 + 4, "C2", 0, 8, 2)
    inner = face & (dist >= len(prof))
    return quad_of(inner), [[q["tl"], q["top"]], [q["tr"], q["top"]], [q["br"], q["bot"] + len(TABLE_EDGE)], [q["bl"], q["bot"] + len(TABLE_EDGE)]]


# ---------------------------------------------------------------- módulo de opciones
OPT = (690, 316, 860, 486)      # rectángulo de mundo
OPT_EDGE = [M0, M0, D6, D6, D5, D5, D4, D4]


def build_options(cv, ys, xs):
    X0, y0, X1, y1 = OPT
    face = plane_rect(ys, xs, X0, y0, X1, y1, tl=8, br=8)
    solid = face.copy()
    for dd in range(1, len(OPT_EDGE) + 1):
        solid |= np.roll(face, dd, 0)
    shadow_on_surface(cv, solid)
    thickness(cv, face, OPT_EDGE)
    bevel(cv, face, [OUT, OUT, (M3, M2, M0), (M2, M1, M0), (M2, M1, M0)], body=M1)
    # Recuadros hundidos: pantalla arriba y mandos abajo (luz invertida: el canto de arriba en sombra).
    scr = plane_rect(ys, xs, X0 + 10, y0 + 11, X1 - 10, y0 + 89, tl=4, br=4)
    deck = plane_rect(ys, xs, X0 + 10, y0 + 98, X1 - 10, y1 - 10, tl=4, br=4)
    ds = bevel(cv, scr, [(M2, M1, OUT), (M3, M2, D2), OUT], body=S1, sunk=True)
    dd_ = bevel(cv, deck, [(M2, M1, OUT), (M3, M2, D2), OUT], body=M0, sunk=True)
    for (X, y) in [(X0 + 5, y0 + 5), (X1 - 6, y0 + 5), (X0 + 5, y1 - 6), (X1 - 6, y1 - 6)]:
        rivet(cv, int(round(to_screen(X, y))), y, light=True)
    # Mandos centrados en el recuadro de abajo: tres pomos brillantes y cuatro interruptores.
    # Se colocan en la fila del medio y se pasan a x de mundo: cada mando se inclina con el plano.
    dq = quad_of(deck & (dd_ >= 3))
    cy = (dq["top"] + dq["bot"]) // 2 - 1
    wl, wr = to_screen(X0 + 13, cy), to_screen(X1 - 13, cy)
    r, kstep, gap, sstep = 12, 32, 14, 13
    span = (2 * kstep + 2 * r + 2) + gap + (3 * sstep + 10)
    left = wl + ((wr - wl) - span) / 2

    def world(x):
        return 480 + (x - 480) / kk(cy)

    knobs = []
    for i in range(3):
        kx = left + r + 1 + i * kstep
        lean_knob(cv, world(kx), cy, r)
        knobs.append([rnd(kx), cy])
    # Ranuras de los interruptores (la palanca la pinta OptionsConsole en su trapecio).
    switches = []
    sx0 = left + 2 * kstep + 2 * r + 2 + gap
    sy = cy - 15
    for i in range(4):
        q = lean_quad(world(sx0 + i * sstep + 4), sy, sy + 29, 8)
        for y in range(sy - 1, sy + 31):
            x = lean_x(q, min(max(y, sy), sy + 29))
            cv.rect(x - 1, y, 10, 1, OUT)
            if sy + 2 <= y < sy + 30:
                cv.rect(x, y, 8, 1, D1)
        switches.append(q)
    return {"rect": bbox_of(face, len(OPT_EDGE)), "quad": plane_corners(X0, y0, X1, y1, len(OPT_EDGE)),
            "screen": quad_of(scr & (ds >= 3)), "knobs": knobs, "switches": switches}


def lean_knob(cv, KX, cy, r):
    """Pomo de la consola (como pixkit.knob) apoyado en el plano: cada fila se desplaza con la línea
    de mundo KX, así que se inclina como las demás piezas, y deja ver su canto abajo."""
    face = np.zeros((H, W), bool)
    pix = {}
    for y in range(cy - r - 2, cy + r + 3):
        cx = to_screen(KX, y + 0.5)
        for x in range(int(cx) - r - 3, int(cx) + r + 4):
            xx, yy = x + 0.5 - cx, y - cy
            dd = (xx * xx + yy * yy) ** 0.5
            if dd <= r + 1.5:
                face[y, x] = True
                pix[(x, y)] = (xx, yy, dd)
    thickness(cv, face, [M0, M0, D2])
    for (x, y), (xx, yy, dd) in pix.items():
        if dd > r + 0.5:
            cv.put(x, y, OUT)
        elif dd > r - 2.5:
            # Aro: luz arriba a la izquierda.
            lt = (-xx - yy) / (abs(xx) + abs(yy) + 1e-6)
            cv.put(x, y, M3 if lt > 0.5 else M2 if lt > -0.2 else M0)
        else:
            # Cara del pomo: rampa por la normal de una semiesfera.
            nz = max(0.0, 1 - (dd / (r - 2)) ** 2) ** 0.5
            lum = (-xx * 0.5 - yy * 0.6) / (r - 2) + nz * 0.6
            cv.put(x, y, M3 if lum > 0.75 else M2 if lum > 0.45 else M1 if lum > 0.1 else M0)


# ---------------------------------------------------------------- tablet y su bandeja
TRAY = (548, 314, 668, 456)     # bandeja hundida (mundo)
# Cara de la tablet (mundo): centrada en el hueco de la bandeja (318-452 dentro del borde de 4 px),
# contando su canto de 6 filas: 5 px de hueco a cada lado. La ranura de luz queda en el hueco de abajo.
TAB = (556, 323, 660, 441)
TAB_EDGE = [D5, D5, D4, D3, D2, D2]


def build_tray(cv, ys, xs):
    X0, y0, X1, y1 = TRAY
    m = plane_rect(ys, xs, X0, y0, X1, y1, tl=6, br=6)
    bevel(cv, m, [OUT, OUT, (D4, D3, OUT), (D3, D2, D1)], body=D1, sunk=True)
    # Ranura de luz al fondo de la bandeja (la enciende ArchiveTablet al sacar la tablet).
    yl = y1 - 7
    xa, xb = int(round(to_screen(X0 + 14, yl))), int(round(to_screen(X1 - 14, yl)))
    cv.rect(xa - 1, yl - 1, xb - xa + 2, 3, OUT)
    return bbox_of(m), plane_corners(X0, y0, X1, y1), [xa, yl, xb - xa, 1]


def build_tablet(ys, xs):
    """Tablet robusta apoyada en el plano: marco grueso, escuadras atornilladas y el canto abajo."""
    X0, y0, X1, y1 = TAB
    full = Canvas(W, H)
    face = plane_rect(ys, xs, X0, y0, X1, y1, tl=6, br=6)
    thickness(full, face, TAB_EDGE)
    bevel(full, face, [OUT, OUT, (D6, D5, D2), (D5, D4, D2), D4], body=D4)
    scr = plane_rect(ys, xs, X0 + 8, y0 + 8, X1 - 8, y1 - 8)
    ring = plane_rect(ys, xs, X0 + 7, y0 + 7, X1 - 7, y1 - 7) & ~scr
    full.px[ring] = OUT
    full.px[scr] = S1
    # Escuadras de las esquinas: L de metal claro con tornillo.
    L, Tk = 20, 7
    for (fx, fy) in [(1, 1), (-1, 1), (1, -1), (-1, -1)]:
        cx0 = X0 if fx > 0 else X1 - L
        cy0 = y0 if fy > 0 else y1 - L
        hy = cy0 if fy > 0 else cy0 + L - Tk
        vx = cx0 if fx > 0 else cx0 + L - Tk
        arm = plane_rect(ys, xs, cx0, hy, cx0 + L, hy + Tk) | plane_rect(ys, xs, vx, cy0, vx + Tk, cy0 + L)
        bevel(full, arm, [OUT, (M3, M2, M0), (M2, M1, M0)], body=M1)
        rivet(full, rnd(to_screen(vx + 3.5, hy + 3)), hy + 3, light=True)
    solid = face.copy()
    for dd in range(1, len(TAB_EDGE) + 1):
        solid |= np.roll(face, dd, 0)
    q = quad_of(solid)
    # Recorte: caja de todo lo pintado (el recorte de las esquinas no debe cortar las escuadras).
    cols = np.where(full.px[..., 3].any(0))[0]
    rows = np.where(full.px[..., 3].any(1))[0]
    x0, x1, y0_, y1_ = int(cols.min()), int(cols.max()) + 1, int(rows.min()), int(rows.max()) + 1
    from PIL import Image
    Image.fromarray(full.px[y0_:y1_, x0:x1], "RGBA").save(os.path.join(OUT_DIR, "tablet.png"))
    return {"x": int(x0), "y": int(y0_), "w": int(x1 - x0), "h": int(y1_ - y0_),
            "screen": quad_of(scr[y0_:y1_, x0:x1]), "shadow": quad_of(solid, 0, 0)}


def main():
    cv, ys, xs, clamps = build_center()
    for X in (525, 679):
        plane_seam(cv, X, SEAM + 3, LIP)
    table_in, table_out = build_table(cv, ys, xs)
    tray, tray_quad, tray_light = build_tray(cv, ys, xs)
    opt = build_options(cv, ys, xs)
    cv.save("center_static.png")
    tablet = build_tablet(ys, xs)
    meta = {"table_in": table_in, "table_out": table_out, "opt": opt, "tablet": tablet, "tray": tray,
            "tray_quad": tray_quad, "tray_light": tray_light, "leds": LEDS, "sill": SILL, "top": SEAM,
            "strip": {"y": TUBE_Y, "h": TUBE_H, "clamps": clamps}}
    print("ok", json.dumps(table_in), json.dumps(tablet), len(LEDS), "pilotos")
    return meta


if __name__ == "__main__":
    main()
