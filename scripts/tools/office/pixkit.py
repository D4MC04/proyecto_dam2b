# Utilidades comunes de los generadores de la oficina del menú (gen_center.py, gen_left.py, gen_right.py;
# se lanzan todos con make_office.py):
# paleta, lienzo, perfiles de bisel, remaches, pomos, pilotos y la habitación de las vistas laterales.
import os
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
# Raíz del proyecto (este script está en scripts/tools/office) y carpeta de los PNG.
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
OUT_DIR = os.path.join(ROOT, "assets", "sprites", "office")
os.makedirs(OUT_DIR, exist_ok=True)
W, H = 960, 540


def c(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


# Paleta del juego (art.md) y rampas de la oficina.
OUT = c("0c0e16")
M0, M1, M2, M3 = c("343a4a"), c("606a7c"), c("96a2b6"), c("d2dceb")
D0, D1, D2, D3, D4, D5, D6 = c("10141c"), c("151a24"), c("1d2330"), c("242b3a"), c("2c3446"), c("3a4256"), c("4f596d")
C0, C1, C2, C3 = c("14304a"), c("1c7496"), c("40e0f0"), c("befaff")
A0, A1, A2, A3, A4 = c("523710"), c("96641e"), c("ecb23c"), c("ffe082"), c("fff8e6")
R0, R1, R2, R3 = c("3a0a16"), c("961432"), c("ff3c5a"), c("ffaabe")
G0, G1, G2, G3 = c("0a2216"), c("1c7440"), c("3cb860"), c("7ee89a")
S0, S1 = c("060d18"), c("08111f")
VEL, VEL2, VEL0 = c("0b1322"), c("101b30"), c("070c17")
CLEAR = (0, 0, 0, 0)
BAYER = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
VP = (480, 300)  # punto de fuga de las vistas


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = np.zeros((h, w, 4), np.uint8)

    def rect(self, x, y, w, h, col):
        x0, y0, x1, y1 = max(0, x), max(0, y), min(self.w, x + w), min(self.h, y + h)
        if x1 > x0 and y1 > y0:
            self.px[y0:y1, x0:x1] = col

    def put(self, x, y, col):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y, x] = col

    def blend(self, x, y, col):
        if 0 <= x < self.w and 0 <= y < self.h:
            a = col[3] / 255
            base = self.px[y, x].astype(float)
            out = base[:3] * (1 - a) + np.array(col[:3]) * a
            self.px[y, x, :3] = out.astype(np.uint8)
            self.px[y, x, 3] = max(int(base[3]), col[3])

    def template(self, rows, pal, x, y):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch != "." and ch in pal:
                    self.put(x + i, y + j, pal[ch])

    def save(self, name):
        Image.fromarray(self.px, "RGBA").save(os.path.join(OUT_DIR, name))


LEDS = []


def led_housing(cv, x, y, color, period=0.0, w=4, h=2):
    """Hueco de un piloto (1 px de contorno); el piloto lo enciende OfficeLights."""
    cv.rect(x - 1, y - 1, w + 2, h + 2, OUT)
    cv.rect(x, y, w, h, D1)
    LEDS.append({"x": x, "y": y, "w": w, "h": h, "c": color, "p": period})


RIVET = [".ooo.", "ohlmo", "olmso", "omsso", ".ooo."]


def rivet(cv, x, y, light=False):
    pal = {"o": OUT, "h": M3 if light else D6, "l": M2 if light else D5, "m": M1 if light else D4, "s": M0 if light else D2}
    cv.template(RIVET, pal, x - 2, y - 2)


# ---------------------------------------------------------------- perfiles
def shade_by_profile(cv, mask, dist, cls, profile, light_classes, mid_classes):
    """Pinta los píxeles de `mask` con el color de `profile[dist]` (tuplas luz/medio/sombra)."""
    for d, entry in enumerate(profile):
        sel = mask & (dist == d)
        if not sel.any():
            continue
        if isinstance(entry, tuple) and len(entry) == 3 and isinstance(entry[0], tuple):
            lit = np.isin(cls, light_classes)
            mid = np.isin(cls, mid_classes)
            cv.px[sel & lit] = entry[0]
            cv.px[sel & mid & ~lit] = entry[1]
            cv.px[sel & ~lit & ~mid] = entry[2]
        else:
            cv.px[sel] = entry


def chamfer_terms(xs, ys, x0, y0, x1, y1, tl=0, tr=0, bl=0, br=0):
    """Distancias (en pasos de píxel) fuera de un rectángulo con esquinas recortadas a 45°.
    Clases: 0 izq, 1 arriba, 2 der, 3 abajo, 4 recorte arriba-izq, 5 arriba-der, 6 abajo-izq, 7 abajo-der."""
    big = -10 ** 6
    terms = [x0 - xs, y0 - ys, xs - (x1 - 1), ys - (y1 - 1),
             (tl - (xs - x0) - (ys - y0)) if tl else np.full(xs.shape, big),
             (tr - ((x1 - 1) - xs) - (ys - y0)) if tr else np.full(xs.shape, big),
             (bl - (xs - x0) - ((y1 - 1) - ys)) if bl else np.full(xs.shape, big),
             (br - ((x1 - 1) - xs) - ((y1 - 1) - ys)) if br else np.full(xs.shape, big)]
    st = np.stack(terms)
    return st.max(0), st.argmax(0)


def edge_dist(xs, ys, pts):
    """Distancia hacia dentro a cada lado de un polígono convexo (horario en pantalla)."""
    ds = []
    n = len(pts)
    for i in range(n):
        (ax, ay), (bx, by) = pts[i], pts[(i + 1) % n]
        ex, ey = bx - ax, by - ay
        L = (ex * ex + ey * ey) ** 0.5
        nx, ny = -ey / L, ex / L  # normal hacia dentro (polígono en sentido horario con y hacia abajo)
        ds.append((xs - ax) * nx + (ys - ay) * ny)
    st = np.stack(ds)
    return st.min(0), st.argmin(0)


def drop_shadow(cv, mask, dx=4, dy=4):
    sh = np.zeros_like(mask)
    sh[dy:, dx:] = mask[:-dy, :-dx]
    sel = sh & ~mask
    cv.px[sel, :3] = (cv.px[sel, :3] * 0.55).astype(np.uint8)


def knob(cv, cx, cy, r=13):
    for yy in range(-r - 2, r + 3):
        for xx in range(-r - 2, r + 3):
            dd = (xx * xx + yy * yy) ** 0.5
            if dd > r + 1.5:
                continue
            if dd > r + 0.5:
                cv.put(cx + xx, cy + yy, OUT)
                continue
            if dd > r - 2.5:
                # Aro con marcas: luz arriba a la izquierda.
                lt = (-xx - yy) / (abs(xx) + abs(yy) + 1e-6)
                col = M3 if lt > 0.5 else M2 if lt > -0.2 else M0
                cv.put(cx + xx, cy + yy, col)
                continue
            # Cara del pomo: rampa por la normal de una semiesfera.
            nz = max(0.0, 1 - (dd / (r - 2)) ** 2) ** 0.5
            l = (-xx * 0.5 - yy * 0.6) / (r - 2) + nz * 0.6
            col = M3 if l > 0.75 else M2 if l > 0.45 else M1 if l > 0.1 else M0
            cv.put(cx + xx, cy + yy, col)
    cv.put(cx, cy + r + 2, OUT)


# ---------------------------------------------------------------- máscaras de forma libre
def poly_mask(pts, w=W, h=H):
    """Máscara de un polígono cualquiera (cóncavo también), con sus bordes incluidos."""
    im = Image.new("L", (w, h), 0)
    ImageDraw.Draw(im).polygon([tuple(p) for p in pts], fill=255)
    return np.array(im) > 0


def rect_mask(x0, y0, x1, y1, w=W, h=H):
    m = np.zeros((h, w), bool)
    m[max(0, y0):max(0, y1), max(0, x0):max(0, x1)] = True
    return m


def disc_mask(cx, cy, r, w=W, h=H):
    ys, xs = np.mgrid[0:h, 0:w]
    return (xs - cx) ** 2 + (ys - cy) ** 2 <= r * r + r * 0.8


def _shift(m, dx, dy):
    out = np.zeros_like(m)
    h, w = m.shape
    out[max(0, dy):h + min(0, dy), max(0, dx):w + min(0, dx)] = m[max(0, -dy):h + min(0, -dy), max(0, -dx):w + min(0, -dx)]
    return out


def inner_dist(mask, maxd):
    """Capa de cada píxel contando desde el borde de la máscara (0 = borde); `maxd` en lo hondo."""
    dist = np.full(mask.shape, -1, int)
    cur = mask.copy()
    for d in range(maxd):
        er = cur & _shift(cur, 1, 0) & _shift(cur, -1, 0) & _shift(cur, 0, 1) & _shift(cur, 0, -1)
        dist[cur & ~er] = d
        cur = er
    dist[cur] = maxd
    return dist


def facing(dist):
    """Hacia dónde mira cada píxel del bisel: 1 luz (arriba/izquierda), 0 medio, -1 sombra."""
    d = dist.astype(int)
    gx = _shift(d, -1, 0) - _shift(d, 1, 0)
    gy = _shift(d, 0, -1) - _shift(d, 0, 1)
    # Fuera de la máscara vale -1: los bordes del lienzo cuentan como borde.
    s = gx + gy
    return np.sign(s)


def bevel(cv, mask, profile, body=None, sunk=False):
    """Sombrea una máscara cualquiera por capas desde su borde. Cada entrada del perfil es un color
    o una tupla (luz, medio, sombra). `sunk` invierte la luz (recuadro hundido)."""
    dist = inner_dist(mask, len(profile))
    face = facing(np.where(mask, dist, -1))
    if sunk:
        face = -face
    for d, entry in enumerate(profile):
        sel = mask & (dist == d)
        if entry is None or not sel.any():
            continue
        if isinstance(entry, tuple) and isinstance(entry[0], tuple):
            cv.px[sel & (face > 0)] = entry[0]
            cv.px[sel & (face == 0)] = entry[1]
            cv.px[sel & (face < 0)] = entry[2]
        else:
            cv.px[sel] = entry
    if body is not None:
        cv.px[mask & (dist >= len(profile))] = body
    return dist


def bayer_mask(level, w=W, h=H):
    """Trama ordenada: verdadero donde el umbral de Bayer queda por debajo de `level` (0..16, puede ser un array)."""
    ys, xs = np.mgrid[0:h, 0:w]
    th = np.array(BAYER)[(ys & 3) * 4 + (xs & 3)]
    return th < level


def darken(cv, mask, k=0.55):
    cv.px[mask, :3] = (cv.px[mask, :3] * k).astype(np.uint8)


def to_vp(x, y, k):
    """Punto escalado hacia el punto de fuga (k < 1 = más hondo)."""
    return (VP[0] + (x - VP[0]) * k, VP[1] + (y - VP[1]) * k)


# ================================================================ HABITACIÓN DE LOS LADOS
# Pared de enfrente sin rincones: techo, pared y suelo llegan a los dos bordes.
CEIL, FLOOR = 38, 466
CORNICE = 62      # fin de la moldura de arriba
SKIRT = 432       # empieza el zócalo
PLATE_W = 120
PLATE_SPLIT = 250  # junta horizontal de las placas


def build_side_room():
    cv = Canvas(W, H)
    ys, xs = np.mgrid[0:H, 0:W]
    # --- Techo: placas en perspectiva.
    cv.rect(0, 0, W, CEIL, D1)
    for y in (10, 22):
        cv.rect(0, y, W, 2, OUT)
        cv.rect(0, y + 2, W, 1, D3)
    for xb in range(-360, W + 360, 120):
        for y in range(0, CEIL):
            k = (VP[1] - y) / (VP[1] - CEIL)
            x = int(round(VP[0] + (xb - VP[0]) * k))
            cv.put(x, y, OUT)
            cv.put(x + 1, y, OUT)
            cv.put(x + 2, y, D3)
    # --- Moldura de arriba con una ranura de luz que baña la pared.
    rows = [OUT, OUT, D6, D6, D5, D5, D4, D4, D4, D4, D3, D3, D2, OUT, OUT, C1, C2, C1, OUT, D5, D4, D2, OUT, OUT]
    for i, col in enumerate(rows):
        cv.rect(0, CEIL + i, W, 1, col)
    top = CEIL + len(rows)
    # --- Pared: placas grandes con bisel y junta de 2 px.
    cv.rect(0, top, W, SKIRT - top, D2)
    for x0 in range(0, W, PLATE_W):
        for (ya, yb) in ((top, PLATE_SPLIT), (PLATE_SPLIT, SKIRT)):
            m = rect_mask(x0, ya, x0 + PLATE_W, yb)
            bevel(cv, m, [OUT, (D5, D4, D1), (D4, D3, D1), (D3, D2, D2)], body=D2)
            for (rx, ry) in ((x0 + 9, ya + 9 if ya != top else ya + 8), (x0 + PLATE_W - 10, ya + 9 if ya != top else ya + 8),
                             (x0 + 9, yb - 10), (x0 + PLATE_W - 10, yb - 10)):
                rivet(cv, rx, ry)
    # Luz de la moldura bajando por la pared y penumbra cerca del suelo.
    wash = (ys >= top) & (ys < top + 28) & bayer_mask(np.clip((top + 28 - ys) / 28 * 7, 0, 16))
    wall = (ys >= top) & (ys < SKIRT)
    tint = wash & wall & np.all(cv.px[..., :3] == D2[:3], axis=-1)
    cv.px[tint] = D3
    low = wall & (ys > SKIRT - 60) & bayer_mask(np.clip((ys - (SKIRT - 60)) / 60 * 8, 0, 16)) & np.all(cv.px[..., :3] == D2[:3], axis=-1)
    cv.px[low] = D1
    # --- Zócalo: sale de la pared (cara de arriba con luz) y lleva una tira de luz.
    rows = [OUT, D6, D6, D5, D4, D4, D4, D4, D4, OUT, C0, C1, C1, C0, OUT, D4, D4, D4, D4, D3, D3, D3, D3, D2, D2, D2, D1, D1, OUT, OUT, OUT, OUT, OUT, OUT]
    rows = rows[:FLOOR - SKIRT]
    for i, col in enumerate(rows):
        cv.rect(0, SKIRT + i, W, 1, col)
    for x in range(14, W, 32):
        cv.rect(x, SKIRT + 11, 18, 2, C2)
    for x0 in range(0, W, PLATE_W):
        cv.rect(x0, SKIRT + 15, 2, 13, OUT)
    # --- Suelo de placas en perspectiva, con rejilla en las del medio.
    cv.rect(0, FLOOR, W, H - FLOOR, D2)
    seams_y = [474, 488, 510]
    fl = ys >= FLOOR
    # Placas: índice de fila y columna en perspectiva.
    k = (ys - VP[1]) / (FLOOR - VP[1])
    xb = VP[0] + (xs - VP[0]) / np.maximum(k, 1e-6)
    col = np.floor(xb / 56).astype(int)
    row = np.searchsorted(np.array(seams_y), ys, side="right")
    grate = fl & ((col + row) % 2 == 0) & (ys % 4 < 2)
    cv.px[grate] = D1
    for y in seams_y:
        cv.rect(0, y, W, 2, OUT)
        cv.rect(0, y + 2, W, 1, D4)
    for xc in range(-1200, W + 1300, 56):
        for y in range(FLOOR, H):
            kk = (y - VP[1]) / (FLOOR - VP[1])
            x = int(round(VP[0] + (xc - VP[0]) * kk))
            cv.put(x, y, OUT)
            cv.put(x + 1, y, OUT)
            cv.put(x + 2, y, D4)
    # Reflejo de la tira del zócalo en el suelo.
    refl = fl & (ys < FLOOR + 10) & bayer_mask(np.clip((FLOOR + 10 - ys) / 10 * 6, 0, 16))
    cv.px[refl] = C0
    cv.rect(0, FLOOR, W, 1, OUT)
    return cv


def to_vp_at(x, y, y_target):
    """Punto de la recta (x, y) -> punto de fuga a la altura `y_target`."""
    k = (VP[1] - y_target) / (VP[1] - y)
    return (VP[0] + (x - VP[0]) * k, y_target)
