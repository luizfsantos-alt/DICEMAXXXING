# Arte faltando

Mapa de tudo que hoje é placeholder (desenhado em código, só texto ou arte provisória).
Levantado a partir de `ui/` e `assets/`. Prioridade: **A** aparece em toda luta, **B** aparece
toda jornada, **C** detalhe/polimento.

## O que já tem arte

| Elemento | Arquivo |
|---|---|
| Fotos do Feiticeiro, Vampiro e Bárbaro (3 variações cada) | `assets/portraits/<arquétipo>_1..3.png` |
| Molduras das fotos (jogador verde, inimigo vermelha) | `assets/portraits/frame_player.png`, `frame_enemy.png` |
| Fundo da tela de luta (e reflexo dos dados 3D) | `assets/backgrounds/tavern.jpg` |
| Fonte dos números sobre as fotos | `assets/fonts/Bungee-Regular.ttf` |
| Dados 3D e 2D | gerados em código de propósito (`ui/dice_3d.gd`, `ui/die_face.gd`, `docs/DADOS_VISUAL.md`); não precisam de arquivo |

## 1. Personagens (fotos) — prioridade A

Hoje `Portrait.WITH_ART = ["sorcerer", "vampire", "barbarian"]`; o resto cai em `generic_1..3.png`
(provisórias). Para ligar um arquétipo novo: salvar `<id>_1..3.png` em `assets/portraits/` e
incluir o id em `WITH_ART` (`ui/portrait.gd`).

| Arquétipo | Id | Jogável | Situação |
|---|---|---|---|
| **Assassino** | `assassin` | **sim** | **sem arte** (usa genérica) — o único jogável sem foto |
| Minimalista | `minimalist` | não (inimigo) | sem arte |
| Metalurgista | `metallurgist` | não (inimigo) | sem arte |
| Copista | `copyist` | não (inimigo) | sem arte |
| Perfeccionista | `perfectionist` | não (inimigo) | sem arte |

Variantes e Mestre (hoje usam a foto do arquétipo base, sem nada que os diferencie):

| Quem | Base | Situação |
|---|---|---|
| Porteiro de Chumbo (Mestre do andar 10) | Feiticeiro | sem arte própria |
| Lixeiro | Assassino | sem arte própria |
| Piromante | Feiticeiro | sem arte própria |
| Fundidor | Metalurgista | sem arte própria |
| Monge do Silêncio | Minimalista | sem arte própria |

Arte provisória a substituir: `generic_1..3.png` (somem quando os 8 arquétipos tiverem foto).

## 2. Menu inicial (`ui/menu_screen.gd`) — prioridade B

| Elemento | Hoje |
|---|---|
| Logo | `assets/logo.png` marcado como **provisório** no código e no README |
| Ícone do app | `assets/icon.png` = cópia do logo provisório |
| Cartões de escolha de personagem | só texto e borda na cor do arquétipo; **sem foto/ilustração** |
| Fundo | cor lisa (`Kit.BG`) |

## 3. Torre: portas, paradas e ofertas (`ui/tower_screen.gd`) — prioridade B

Todos os cartões são botões de cor lisa com texto; nenhum tem ilustração ou ícone.

| Grupo | Itens |
|---|---|
| Portas | Fácil, Normal, Difícil, Insana, Mestre (só muda a cor do fundo) |
| Paradas | Loja (`shop`), Cura (`heal`), Escola (`school`), Poço (`well`) |
| Ofertas | magia, dado com elemento (`die`), elemento num dado (`element`), adesivo ×2 (`sticker`), vida máxima (`maxhp`), evoluir magia (`evolve`), destruir dado (`destroy`) |
| Recompensa do Mestre | +casas (`slots`), +1 dado na mão (`hand`), magia rara (`rare_pick`) |
| Fundo da tela | cor lisa |

## 4. Tela de luta (`ui/duel_screen.gd` e componentes) — prioridade A

| Elemento | Arquivo | Hoje |
|---|---|---|
| **Ícones de status** (11) | `ui/status_icon.gd` | sigla de 2 letras num quadrado colorido ("Placeholders até haver arte"): bloqueio `BL`, veneno `VE`, queima `QU`, espelho `ES`, esquiva `EV`, revide `RE`, imune `IM`, dado guardado `GU`, fúria `FU`, sede `SE`, mexida na próxima mão `PM` |
| **Cartões de magia** (46 magias) | `ui/spell_card.gd` | só texto (nome, efeito, uso) e buracos; sem ícone/ilustração por magia nem por tipo de efeito |
| Ícone de moeda | `duel_screen.gd` (faixa do rodapé) | dois círculos dourados desenhados |
| Barra de vida | `ui/hp_bar.gd` | retângulo arredondado liso |
| Buracos dos dados | `ui/hole.gd` | desenhados em código (aceitável; arte opcional) |
| Efeito da magia (bola de luz) | `ui/spell_bolt.gd` | círculos e rastro em código, só cor muda (verde/vermelho/azul) |
| Painéis e botões | `ui/kit.gd` | `StyleBoxFlat` ("Fábrica de controles placeholder, sem texturas") |
| Nome e bolsa sobre as fotos | — | SPEC_v3 §13: "placeholder até haver arte" |

## 5. Grimório, bolsa e fim de jornada — prioridade B/C

| Elemento | Arquivo | Hoje |
|---|---|---|
| Peças do grimório | `ui/grimoire_view.gd` | blocos coloridos pelo efeito, com texto |
| Lista da bolsa | `ui/bag_panel.gd` | botões de texto por face (adesivo e face travada só mudam a cor) |
| Adesivo ×2 | `bag_panel.gd`, `die_face.gd` | texto "×2"; sem selo/arte de adesivo |
| Tela de vitória/derrota | `ui/end_screen.gd` | texto em painéis; sem ilustração nem fundo |
| Janelas (overlay) | `ui/overlay.gd` | painel liso |

## 6. Fora da arte visual

- **Som:** não há nenhum áudio no projeto (nem música nem efeitos).
- **Fonte da interface:** tudo fora dos números das fotos usa a fonte padrão do Godot
  (`ThemeDB.fallback_font`); só a Bungee foi adicionada.
- **Extras dos dados não feitos** (`docs/DADOS_VISUAL.md`): superfície ondulando no Mercúrio,
  tranco de câmera no Ósmio, rebite nas faces travadas do Chumbo, linha de luz entre Carbonos.

## Ordem sugerida

1. Fotos do **Assassino** (único jogável sem arte).
2. **Ícones de status** (11 ícones pequenos, aparecem em toda luta).
3. Fotos dos 4 arquétipos inimigos restantes, depois Porteiro de Chumbo.
4. Logo/ícone definitivo e retrato nos cartões do menu.
5. Ícones de porta, parada e oferta na torre; ícone de moeda.
6. Ícone por tipo de efeito nos cartões de magia (dano, bloqueio, cura, esquiva, debuff…), antes de
   pensar em ilustração por magia.
7. Fundos do menu, torre e fim de jornada; tema de painéis/botões; som.
