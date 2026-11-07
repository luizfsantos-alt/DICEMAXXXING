"""Fecha o pulso cortado da mão (assets/icons/offer/hand.png) com o punho de uma manga.

Uso: python3 tools/manga_da_mao.py entrada.png saida.png (já aplicado; rodar de novo na
saída engrossaria a manga).
"""
import sys
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA")
W, H = im.size
px = im.load()
OUT = (26, 18, 32, 255)
PLUM, PLUM_D, PLUM_L = (86, 44, 110, 255), (58, 28, 78, 255), (120, 70, 150, 255)
GOLD, GOLD_D = (255, 199, 51, 255), (196, 132, 30, 255)
def d(x, y):  # distância ao canto de baixo à esquerda, ao longo do antebraço
    # Distância à linha do corte original, de (0, 49) a (22, 63), medida para dentro da mão.
    return (14 * x - 22 * (y - 49)) / 26.08
orig = {(x, y): px[x, y][3] > 128 for x in range(W) for y in range(H)}
# A manga cobre o pulso: faixa entre CUT e TOP; abaixo de CUT, nada (a manga termina ali).
CUT, TOP = 1.0, 10.0
grow = 2  # a manga é um pouco mais larga que o pulso
mask = set()
for (x, y), on in orig.items():
    if on and d(x, y) < TOP:
        mask.add((x, y))
for (x, y) in list(mask):
    for dx in range(-grow, grow + 1):
        for dy in range(-grow, grow + 1):
            p = (x + dx, y + dy)
            if 0 <= p[0] < W and 0 <= p[1] < H and CUT <= d(*p) < TOP + 0.5:
                mask.add(p)
mask = {p for p in mask if d(*p) >= CUT}
for x in range(W):
    for y in range(H):
        if d(x, y) < TOP and (x, y) not in mask:
            px[x, y] = (0, 0, 0, 0)
for (x, y) in mask:
    t = d(x, y)
    if t >= TOP - 2.0:
        c = GOLD if t >= TOP - 1.0 else GOLD_D
    elif t < CUT + 2.0:
        c = GOLD if t < CUT + 1.0 else GOLD_D
    else:
        c = PLUM_L if (x + y) % 5 == 0 else (PLUM if t > (CUT + TOP) / 2 else PLUM_D)
    px[x, y] = c
# Contorno escuro em volta da manga.
for (x, y) in list(mask):
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        p = (x + dx, y + dy)
        if 0 <= p[0] < W and 0 <= p[1] < H and p not in mask and px[p][3] < 128:
            px[p] = OUT
# A borda da manga encostada no papel não pode ficar sem contorno.
for (x, y) in mask:
    if x == 0 or y == H - 1:
        px[x, y] = OUT
im.save(out)
