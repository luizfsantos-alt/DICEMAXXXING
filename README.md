# DICEMAXXING

Jogo de dados para Android: suba uma torre com uma bolsa de dados e um grimório de magias. Feito em Godot 4.7 + GDScript.
Tela em paisagem.

- Regras: [`docs/SPEC_v3.md`](docs/SPEC_v3.md) (v3, fonte da verdade). A fatia vertical (seção 12) está implementada.
- Histórico: [`docs/SPEC.md`](docs/SPEC.md) (v2, coliseu com equipamentos; substituída).
- Motor de regras (sem cenas, testável): `engine/`.
- Interface (placeholders, paisagem): `ui/`. A tela de duelo anima os eventos do motor.
- Textos PT-BR: `data/texts_pt_br.json`. Tom (duelo de egos entre magos): [`docs/TOM.md`](docs/TOM.md).
- Testes (GUT): `tests/`.
- Simulador de balanceamento: `sim/simulate.gd`.

## Rodar

```sh
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gexit                 # testes
godot --headless -s res://sim/check.gd                              # scripts sem erro
godot --headless -s res://sim/simulate.gd -- --runs=1000 --door=normal   # simulação
```

## APK

Cada push roda o workflow `CI` no GitHub Actions: testes, simulação e um APK de debug
(artefato `dicemaxxing-apk`). Baixe o artefato, descompacte e instale o `.apk` no celular
(é preciso permitir "instalar apps desconhecidos").
