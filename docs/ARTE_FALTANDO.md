# Arte faltando

Mapa de tudo que hoje é placeholder (desenhado em código, só texto ou arte provisória).
Levantado a partir de `ui/` e `assets/`. Prioridade: **A** aparece em toda luta, **B** aparece
toda jornada, **C** detalhe/polimento.

## O que já tem arte

| Elemento | Arquivo |
|---|---|
| Fotos dos 8 arquétipos (3 variações cada): Feiticeiro, Assassino, Minimalista, Metalurgista, Copista, Perfeccionista, Vampiro e Bárbaro | `assets/portraits/<arquétipo>_1..3.png` |
| Fotos do Mestre e das variantes (1 cada): Porteiro de Chumbo, Lixeiro, Piromante, Fundidor, Monge do Silêncio | `assets/portraits/<id>_1.png` |
| Molduras das fotos (ferro; filete verde no jogador, vermelho no inimigo) | `assets/portraits/frame_player.png`, `frame_enemy.png` |
| Logo do título no menu; logo antigo (dado com chapéu de mago) e ícone do app | `assets/title_logo.png`, `assets/logo.png`, `assets/icon.png` |
| Fundos: luta (e reflexo dos dados 3D), menu, torre, vitória e derrota | `assets/backgrounds/tavern.jpg`, `menu.jpg`, `tower.jpg`, `victory.jpg`, `defeat.jpg` (`Kit.background`) |
| Moeda (faixa da luta e preços da torre) | `assets/icons/coin.png` (`Kit.coin`) |
| Interface 9-slice: painel, botão, moldura da barra de vida, moldura do cartão de magia por raridade | `assets/ui/panel.png`, `button.png`, `hp_frame.png`, `card_<raridade>.png` (`Kit.nine`, bordas em `Kit.NINE`) |
| Ícones de status (os 11): bloqueio, veneno, queima, espelho, esquiva, revide, imune, dado guardado, fúria, sede, próxima mão | `assets/icons/status/<id>.png` (64×64) |
| Ícones de efeito nos cartões de magia: dano, cura, vida máxima, dreno, truque de dados, sacrifício, limpeza (bloqueio, esquiva, espelho, revide, imune e mexida na mão usam os de status) | `assets/icons/fx/<id>.png` (64×64); `Spells.icon_key` escolhe |
| Torre: portas (Fácil, Normal, Difícil, Insana, Mestre), paradas (Loja, Cura, Escola, Poço), todas as ofertas e as 3 recompensas do Mestre | `assets/tower/door_<id>.png`, `stop_<id>.png` (128×128); `assets/icons/offer/<kind>.png` (64×64) |
| Fonte dos números sobre as fotos | `assets/fonts/Bungee-Regular.ttf` |
| Dados 3D e 2D | gerados em código de propósito (`ui/dice_3d.gd`, `ui/die_face.gd`, `docs/DADOS_VISUAL.md`); não precisam de arquivo |

Prompts e andamento item a item: [`docs/PAUTA_ARTE.html`](PAUTA_ARTE.html). Para recortar fundo de
arte gerada: `tools/recortar_fundo.py`.

## 1. O que ainda é desenhado em código ou só texto

A pauta de arte está toda feita. O que sobra é opcional ou é código.

| Elemento | Arquivo | Hoje |
|---|---|---|
| Fotos da Alquimista (andar 20) e do Reator (andar 30) | `assets/portraits/alquimista_1.png`, `reator_1.png` | sem a arte, usam a foto do arquétipo (Copista e Bárbaro) |
| Cartões da torre | `ui/tower_screen.gd` | ilustração no topo, mas o cartão em si é cor lisa (dá para usar `card_<raridade>.png` nas ofertas de magia) |
| Ilustração por magia | `ui/spell_card.gd` | só o ícone do tipo de efeito (opcional) |
| Buracos dos dados | `ui/hole.gd` | desenhados em código (aceitável; arte opcional) |
| Efeito da magia (bola de luz) | `ui/spell_bolt.gd` | círculos e rastro em código, só cor muda (verde/vermelho/azul) |
| Painéis translúcidos da luta e botões coloridos | `ui/duel_screen.gd`, `ui/kit.gd` | `StyleBoxFlat` de propósito (a textura só entra nas cores neutras) |
| Nome e bolsa sobre as fotos | — | SPEC_v3 §13: "placeholder até haver arte" |
| Peças do grimório | `ui/grimoire_view.gd` | blocos coloridos pelo efeito, com texto |
| Lista da bolsa | `ui/bag_panel.gd` | botões de texto por face (adesivo e face travada só mudam a cor) |
| Adesivo ×2 | `bag_panel.gd`, `die_face.gd` | texto "×2"; a arte já existe (`assets/icons/offer/sticker.png`), falta usar na bolsa |

## 6. Fora da arte visual

- **Som:** não há nenhum áudio no projeto (nem música nem efeitos).
- **Fonte da interface:** tudo fora dos números das fotos usa a fonte padrão do Godot
  (`ThemeDB.fallback_font`); só a Bungee foi adicionada.
- **Extras dos dados não feitos** (`docs/DADOS_VISUAL.md`): superfície ondulando no Mercúrio,
  tranco de câmera no Ósmio, rebite nas faces travadas do Chumbo, linha de luz entre Carbonos.

## Ordem sugerida

1. Retrato nos cartões do menu (as fotos já existem; é só código).
2. Selo do adesivo na bolsa (arte já existe).
3. Som.
4. Fonte da interface.
