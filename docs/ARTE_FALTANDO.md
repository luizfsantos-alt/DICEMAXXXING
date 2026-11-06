# Arte faltando

Mapa de tudo que hoje é placeholder (desenhado em código, só texto ou arte provisória).
Levantado a partir de `ui/` e `assets/`. Prioridade: **A** aparece em toda luta, **B** aparece
toda jornada, **C** detalhe/polimento.

## O que já tem arte

| Elemento | Arquivo |
|---|---|
| Fotos dos 7 arquétipos com arte (3 variações cada): Feiticeiro, Assassino, Metalurgista, Copista, Perfeccionista, Vampiro e Bárbaro | `assets/portraits/<arquétipo>_1..3.png` |
| Fotos do Mestre e das variantes (1 cada): Porteiro de Chumbo, Lixeiro, Piromante, Fundidor, Monge do Silêncio | `assets/portraits/<id>_1.png` |
| Molduras das fotos (ferro; filete verde no jogador, vermelho no inimigo) | `assets/portraits/frame_player.png`, `frame_enemy.png` |
| Logo (dado com chapéu de mago) e ícone do app | `assets/logo.png`, `assets/icon.png` |
| Fundo da tela de luta (e reflexo dos dados 3D) | `assets/backgrounds/tavern.jpg` |
| Ícones de status (os 11): bloqueio, veneno, queima, espelho, esquiva, revide, imune, dado guardado, fúria, sede, próxima mão | `assets/icons/status/<id>.png` (64×64) |
| Ícones de efeito nos cartões de magia: dano, cura, vida máxima, dreno, truque de dados, sacrifício, limpeza (bloqueio, esquiva, espelho, revide, imune e mexida na mão usam os de status) | `assets/icons/fx/<id>.png` (64×64); `Spells.icon_key` escolhe |
| Fonte dos números sobre as fotos | `assets/fonts/Bungee-Regular.ttf` |
| Dados 3D e 2D | gerados em código de propósito (`ui/dice_3d.gd`, `ui/die_face.gd`, `docs/DADOS_VISUAL.md`); não precisam de arquivo |

Prompts e andamento item a item: [`docs/PAUTA_ARTE.html`](PAUTA_ARTE.html). Para recortar fundo de
arte gerada: `tools/recortar_fundo.py`.

## 1. Personagens (fotos) — prioridade A

`Portrait.WITH_ART` lista os arquétipos com foto; o resto cai em `generic_1..3.png` (provisórias).
Para ligar um arquétipo novo: salvar `<id>_1..3.png` em `assets/portraits/` e incluir o id em
`WITH_ART` (`ui/portrait.gd`). Mestre e variantes não precisam de código: `Portrait.art_path` usa
`<master_id>_1.png` ou `<variant>_1.png` quando o arquivo existe.

| Falta | Id | Situação |
|---|---|---|
| Minimalista (3 variações) | `minimalist` | sem arte (usa genérica); é o último arquétipo |

Quando o Minimalista tiver foto, as genéricas deixam de ser usadas e podem sair.

## 2. Menu inicial (`ui/menu_screen.gd`) — prioridade B

| Elemento | Hoje |
|---|---|
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
| Cartões de magia (46 magias) | `ui/spell_card.gd` | ícone pelo tipo de efeito ao lado do nome; sem ilustração por magia (opcional) |
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

1. Fotos do Minimalista.
2. Retrato nos cartões do menu (as fotos já existem; é só código).
3. Moeda.
4. Ícones de porta, parada e oferta na torre.
5. Fundos do menu, torre e fim de jornada; tema de painéis/botões; som.
