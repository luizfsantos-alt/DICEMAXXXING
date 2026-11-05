#!/usr/bin/env python3
"""Recorta o fundo de artes geradas por IA e salva PNG com transparência de verdade.

Geradores como o Gemini não fazem fundo transparente: pintam um quadriculado imitando
a transparência. Por isso os prompts (docs/PAUTA_ARTE.html) pedem fundo chapado numa
cor-chave (magenta #FF00FF ou verde #00FF00), e este script tira essa cor.

Também recupera imagens que já vieram com o quadriculado falso (modo "checker"): parte
das bordas e apaga só o que encosta nelas, para não furar cinzas dentro do desenho.

Uso:
  python3 tools/recortar_fundo.py entrada.png saida.png
  python3 tools/recortar_fundo.py entrada.png saida.png --size 64x64
  python3 tools/recortar_fundo.py *.png --dir recortados/ --size 64x64
  python3 tools/recortar_fundo.py velho.png novo.png --key checker

Opções:
  --key   auto (padrão), magenta, green, blue, checker ou uma cor #rrggbb
  --tol   tolerância da cor-chave, 0 a 441 (padrão 90; quadriculado usa 40)
  --flood só apaga o fundo que encosta nas bordas (quando a cor-chave aparece dentro do desenho)
  --size  LxA final: corta a sobra, encaixa sem distorcer e reduz com vizinho mais
          próximo (não borra o pixel). Sem --size, só corta a sobra (use --no-trim para manter)
Só precisa de Pillow (pip install pillow).
"""

import argparse
import os
import sys
from collections import deque

from PIL import Image

KEYS = {"magenta": (255, 0, 255), "green": (0, 255, 0), "blue": (0, 0, 255)}


def dist2(a, b):
    return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2


def border_pixels(px, w, h, step=1):
    for x in range(0, w, step):
        yield px[x, 0]
        yield px[x, h - 1]
    for y in range(0, h, step):
        yield px[0, y]
        yield px[w - 1, y]


def guess_key(px, w, h):
    """Cor-chave pelas bordas: a chroma mais presente, ou o quadriculado (dois tons claros)."""
    border = list(border_pixels(px, w, h, max(1, min(w, h) // 200)))
    best, best_n = None, 0
    for name, c in KEYS.items():
        n = sum(1 for p in border if dist2(p, c) < 90 ** 2)
        if n > best_n:
            best, best_n = name, n
    if best_n > len(border) * 0.5:
        return best, [KEYS[best]]
    return "checker", checker_colors(border)


def checker_colors(border):
    """Os tons do quadriculado falso: as duas cores neutras mais comuns nas bordas."""
    buckets = {}
    for p in border:
        if max(p[:3]) - min(p[:3]) > 24:  # quadriculado é cinza/branco
            continue
        k = tuple(v // 8 * 8 for v in p[:3])
        buckets[k] = buckets.get(k, 0) + 1
    top = sorted(buckets, key=buckets.get, reverse=True)[:2]
    if not top:
        sys.exit("Não achei fundo chroma nem quadriculado nas bordas; use --key.")
    return [tuple(v + 4 for v in c) for c in top]


def despill(px, w, h, gone, key, reach=4):
    """Tira o tom da chave que vazou nos pixels perto do recorte (franja roxa do magenta).

    Só mexe até `reach` pixels do recorte, e só nos canais que a chave tem: no magenta,
    o que vermelho e azul passam do verde volta para o nível do verde.
    """
    dist = [0] * (w * h)
    q = deque()
    for i in range(w * h):
        if gone[i]:
            q.append(i)
    while q:
        i = q.popleft()
        d = dist[i]
        if d >= reach:
            continue
        x, y = i % w, i // w
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                j = ny * w + nx
                if not gone[j] and dist[j] == 0:
                    dist[j] = d + 1
                    q.append(j)
    on = [c > 127 for c in key]
    for i in range(w * h):
        if gone[i] or dist[i] == 0:
            continue
        x, y = i % w, i // w
        p = list(px[x, y])
        hi = [p[c] for c in range(3) if on[c]]
        lo = [p[c] for c in range(3) if not on[c]]
        if not hi or not lo:
            continue
        spill = min(hi) - max(lo)
        if spill > 0:
            for c in range(3):
                if on[c]:
                    p[c] -= spill
            px[x, y] = tuple(p)


def recortar(img, key="auto", tol=None, trim=True, size=None, flood=False):
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    if key == "auto":
        mode, colors = guess_key(px, w, h)
    elif key == "checker":
        mode, colors = "checker", checker_colors(list(border_pixels(px, w, h)))
    elif key in KEYS:
        mode, colors = key, [KEYS[key]]
    else:
        c = key.lstrip("#")
        mode, colors = "custom", [tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))]
    if tol is None:
        tol = 40 if mode == "checker" else 90
    t2 = tol * tol
    near = lambda p: any(dist2(p, c) <= t2 for c in colors)
    gone = bytearray(w * h)
    if mode == "checker" or flood:
        # Só o que encosta na borda: cinzas (ou a cor-chave, com --flood) dentro do desenho ficam.
        q = deque()
        for x in range(w):
            for y in (0, h - 1):
                if near(px[x, y]) and not gone[y * w + x]:
                    gone[y * w + x] = 1
                    q.append((x, y))
        for y in range(h):
            for x in (0, w - 1):
                if near(px[x, y]) and not gone[y * w + x]:
                    gone[y * w + x] = 1
                    q.append((x, y))
        while q:
            x, y = q.popleft()
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < w and 0 <= ny < h and not gone[ny * w + nx] and near(px[nx, ny]):
                    gone[ny * w + nx] = 1
                    q.append((nx, ny))
    else:
        # Cor-chave não existe no desenho: some em todo lugar (inclusive entre os dedos).
        for y in range(h):
            for x in range(w):
                if near(px[x, y]):
                    gone[y * w + x] = 1
    if mode != "checker":
        # Franja: pixel misturado com a chave, colado no recorte, também sai.
        fr2 = (tol * 2) ** 2
        fringe = []
        for y in range(h):
            for x in range(w):
                i = y * w + x
                if gone[i]:
                    continue
                p = px[x, y]
                if not any(dist2(p, c) <= fr2 for c in colors):
                    continue
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and gone[ny * w + nx]:
                        fringe.append(i)
                        break
        for i in fringe:
            gone[i] = 1
        despill(px, w, h, gone, colors[0])
    for y in range(h):
        for x in range(w):
            if gone[y * w + x]:
                px[x, y] = (0, 0, 0, 0)
            else:
                r, g, b, _ = px[x, y]
                px[x, y] = (r, g, b, 255)  # pixel art: alfa só 0 ou 255
    if trim or size:
        box = img.getbbox()
        if box:
            img = img.crop(box)
    if size:
        tw, th = size
        s = min(tw / img.width, th / img.height)
        nw, nh = max(1, round(img.width * s)), max(1, round(img.height * s))
        img = img.resize((nw, nh), Image.NEAREST)
        canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
        canvas.paste(img, ((tw - nw) // 2, (th - nh) // 2))
        img = canvas
    return img, mode


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="+", help="entrada(s); com uma entrada sem --dir, o último nome é a saída")
    ap.add_argument("--dir", help="pasta de saída (mesmo nome, .png)")
    ap.add_argument("--key", default="auto")
    ap.add_argument("--tol", type=int)
    ap.add_argument("--size", help="LxA, ex.: 64x64")
    ap.add_argument("--no-trim", action="store_true")
    ap.add_argument("--flood", action="store_true", help="só apaga o fundo ligado às bordas (a cor-chave aparece dentro do desenho)")
    a = ap.parse_args()
    size = tuple(int(v) for v in a.size.lower().split("x")) if a.size else None
    if a.dir:
        os.makedirs(a.dir, exist_ok=True)
        pairs = [(f, os.path.join(a.dir, os.path.splitext(os.path.basename(f))[0] + ".png")) for f in a.files]
    elif len(a.files) == 2:
        pairs = [(a.files[0], a.files[1])]
    else:
        ap.error("passe entrada e saída, ou várias entradas com --dir")
    for src, dst in pairs:
        out, mode = recortar(Image.open(src), a.key, a.tol, not a.no_trim, size, a.flood)
        out.save(dst)
        print(f"{src} -> {dst}  ({mode}, {out.width}x{out.height})")


if __name__ == "__main__":
    main()
