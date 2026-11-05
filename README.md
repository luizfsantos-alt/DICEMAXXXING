# DICEMAXXING

Jogo de dados para Android: suba uma torre com uma bolsa de dados e um grimório de magias. Feito em Godot 4.7 + GDScript.
Tela em paisagem.

- Regras: [`docs/SPEC_v3.md`](docs/SPEC_v3.md) (v3, fonte da verdade). A fatia vertical (seção 12) está implementada.
- Magias: [`docs/CATALOGO_MAGIAS.md`](docs/CATALOGO_MAGIAS.md) (catálogo único e princípios de design). Propostas anteriores, com o feedback, em `docs/MAGIAS_DICE_FUCKERY.md` e `docs/MAGIAS_FISICAS.md`.
- Personagens: [`docs/PERSONAGENS.md`](docs/PERSONAGENS.md). Jogáveis: Minimalista, Vampiro e Bárbaro.
- Raridade de magias e dados: [`docs/RARIDADE.md`](docs/RARIDADE.md).
- Ideias futuras: [`docs/ROADMAP.md`](docs/ROADMAP.md) (ex.: builds vencedoras viram inimigos).
- Histórico: [`docs/SPEC.md`](docs/SPEC.md) (v2, coliseu com equipamentos; substituída).
- Motor de regras (sem cenas, testável): `engine/`.
- Interface (placeholders, paisagem): `ui/`. A tela de duelo anima os eventos do motor.
- Dados: as mãos rolam em 3D por cima do palco (`ui/dice_roll_3d.gd`, física própria em
  `ui/dice_physics.gd`, malha e texturas geradas em código em `ui/dice_3d.gd`). Faces de 1 a 6
  com pontinhos, valores maiores com algarismos, tudo em baixo relevo; o 2D segue a mesma regra
  (`ui/die_face.gd`). Tocar na tela pula a rolagem.
- Fotos dos personagens: `assets/portraits/`, 3 variações por arquétipo (`sorcerer_1..3`,
  `vampire_1..3`, `barbarian_1..3`); quem ainda não tem arte usa as provisórias `generic_1..3`.
  A variação é sorteada uma vez por lutador e salva (`Fighter.portrait`), tanto para você quanto
  para o inimigo. A arte preenche a foto e só aparece dentro da moldura (`frame_enemy.png`
  vermelha, `frame_player.png` verde). Sem a arte, `ui/portrait.gd` desenha uma silhueta.
- Números sobre as fotos na fonte Bungee (`assets/fonts/`, licença SIL OFL) com contorno preto.
- Efeitos das magias (`ui/spell_bolt.gd`): cada efeito voa do cartão da magia até a foto do alvo, em
  verde para cura, vermelho para dano e azul para os outros efeitos; ao chegar, a foto pisca na cor
  (e treme no dano) e o número sobe sobre ela (+X verde, −X vermelho). Veneno, queima e efeitos do
  fim do turno aparecem direto no alvo, sem viagem.
- Logo provisório: `assets/logo.png` (também é o ícone do app, `assets/icon.png`).
- Textos PT-BR: `data/texts_pt_br.json`. Tom (duelo de egos entre magos): [`docs/TOM.md`](docs/TOM.md).
- Testes (GUT): `tests/`.
- Simulador de balanceamento: `sim/simulate.gd`.

## Rodar

```sh
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gexit                 # testes
godot --headless -s res://sim/check.gd                              # scripts sem erro
godot --headless -s res://sim/simulate.gd -- --runs=1000 --door=normal --char=all --spells   # simulação
xvfb-run godot -s res://sim/shot_duel.gd -- --out=/tmp   # capturas: menu e rolagem 3D (precisa de vídeo)
```

## APK

Cada push roda o workflow `CI` no GitHub Actions: testes, simulação e um APK de debug
(artefato `dicemaxxing-apk`). Baixe o artefato, descompacte e instale o `.apk` no celular
(é preciso permitir "instalar apps desconhecidos").
