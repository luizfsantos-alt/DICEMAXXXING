# DICEMAXXING

Jogo de dados para Android num coliseu de 100 lutas. Feito em Godot 4.7 + GDScript.
Tela em paisagem.

- Regras: [`docs/SPEC.md`](docs/SPEC.md) (v2, fonte da verdade do código atual).
- Próxima versão (design fechado, ainda não implementada): [`docs/SPEC_v3.md`](docs/SPEC_v3.md) — bolsa de dados, magias, torre.
- Motor de regras (sem cenas, testável): `engine/`.
- Interface (placeholders, paisagem): `ui/`. A tela de duelo anima os eventos do motor.
- Textos PT-BR: `data/texts_pt_br.json`.
- Testes (GUT): `tests/`.
- Simulador de balanceamento: `sim/simulate.gd`.

## Rodar

```sh
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gexit                 # testes
godot --headless -s res://sim/simulate.gd -- --runs=2000 --seed=1   # simulação
```

## APK

Cada push roda o workflow `CI` no GitHub Actions: testes, simulação e um APK de debug
(artefato `dicemaxxing-apk`). Baixe o artefato, descompacte e instale o `.apk` no celular
(é preciso permitir "instalar apps desconhecidos").
