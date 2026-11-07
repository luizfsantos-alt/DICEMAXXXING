#!/usr/bin/env python3
"""Desenha as rosetas de prêmio (pixel art) presas na moldura dos retratos.

Vaidade do tema (docs/TOM.md): todo mago pendura um prêmio no próprio retrato.
Gera assets/ui/rosette_<metal>.png (bronze, silver, gold), 17×23 pixels, para o jogo
mostrar ampliado com filtro "nearest". Uso: python3 tools/desenhar_roseta.py
"""
import math
import os
from PIL import Image

W, H = 17, 23
OUT = (26, 18, 32, 255)
METALS = {
    # metal: (claro, base, escuro), fita: (base, escura)
    "bronze": (((242, 192, 138), (208, 138, 74), (138, 82, 38)), ((58, 154, 82), (34, 104, 58))),
    "silver": (((255, 255, 255), (215, 220, 230), (143, 150, 166)), ((61, 111, 214), (38, 74, 153))),
    "gold": (((255, 241, 168), (255, 199, 51), (196, 132, 30)), ((200, 50, 60), (142, 30, 40))),
}
STAR = [(8, 5), (7, 6), (8, 6), (9, 6), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7), (7, 8), (8, 8), (9, 8), (7, 9), (9, 9)]


def draw(metal):
    (hi, base, dark), (rib, rib_d) = METALS[metal]
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    cx, cy = 8, 8
    # Fitas: duas pontas que saem de trás da roseta, abertas, com corte em V.
    for side in (-1, 1):
        for y in range(12, H - 1):
            t = y - 12
            x0 = cx + side * (1 + t // 3)
            for k in range(3):
                x = x0 + side * k
                # Corte em V na ponta: o meio da fita termina antes das bordas.
                notch = y == H - 2 and k == 1
                if 0 <= x < W and not notch:
                    px[x, y] = rib if k < 2 else rib_d
        # Vão entre as duas fitas.
    for y in range(14, H):
        px[cx, y] = (0, 0, 0, 0)
    # Roseta: borda pregueada (alterna claro e escuro pelo ângulo) e o disco no meio.
    for y in range(H):
        for x in range(W):
            dx, dy = x - cx, y - cy
            r = math.hypot(dx, dy)
            if r <= 7.6:
                a = (math.atan2(dy, dx) + math.pi) / (2 * math.pi)
                if r > 5.2:
                    px[x, y] = rib if int(a * 16) % 2 == 0 else rib_d
                elif r > 4.4:
                    px[x, y] = dark
                else:
                    light = dx + dy < -1
                    px[x, y] = hi if light and r > 2.5 else base
    # Estrela em baixo relevo (tom escuro do metal) no disco.
    for p in STAR:
        px[p] = dark
    # Contorno escuro de 1 pixel em volta de tudo.
    solid = {(x, y) for x in range(W) for y in range(H) if px[x, y][3] > 0}
    for (x, y) in solid:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            p = (x + dx, y + dy)
            if p not in solid:
                if 0 <= p[0] < W and 0 <= p[1] < H:
                    px[p] = OUT
    for (x, y) in solid:
        if x in (0, W - 1) or y in (0, H - 1):
            px[x, y] = OUT
    return im


if __name__ == "__main__":
    root = os.path.join(os.path.dirname(__file__), "..", "assets", "ui")
    for m in METALS:
        path = os.path.join(root, "rosette_%s.png" % m)
        draw(m).save(path)
        print(path)
