# Arte faltando

Mapa de tudo que hoje é placeholder (desenhado em código, só texto ou arte provisória).
Levantado a partir de `ui/` e `assets/`. Prioridade: **A** aparece em toda luta, **B** aparece
toda jornada, **C** detalhe/polimento.

## O que já tem arte

| Elemento | Arquivo |
|---|---|
| Fotos dos 8 arquétipos (3 variações cada): Feiticeiro, Assassino, Minimalista, Metalurgista, Copista, Perfeccionista, Vampiro e Bárbaro | `assets/portraits/<arquétipo>_1..3.png` |
| Fotos do Xamã (3 variações) | `assets/portraits/shaman_1..3.png` |
| Fotos dos Mestres e das variantes (1 cada): Porteiro de Chumbo, Alquimista, Reator, Lixeiro, Piromante, Fundidor, Monge do Silêncio | `assets/portraits/<id>_1.png` |
| Molduras das fotos (ferro; filete verde no jogador, vermelho no inimigo) | `assets/portraits/frame_player.png`, `frame_enemy.png` |
| Logo do título no menu; logo antigo (dado com chapéu de mago) e ícone do app | `assets/title_logo.png`, `assets/logo.png`, `assets/icon.png` |
| Fundos: luta (e reflexo dos dados 3D), menu, torre, vitória e derrota | `assets/backgrounds/tavern.jpg`, `menu.jpg`, `tower.jpg`, `victory.jpg`, `defeat.jpg` (`Kit.background`) |
| Moeda (faixa da luta e preços da torre) | `assets/icons/coin.png` (`Kit.coin`) |
| Interface 9-slice: painel, botão, moldura da barra de vida, moldura do cartão de magia por raridade | `assets/ui/panel.png`, `button.png`, `hp_frame.png`, `card_<raridade>.png` (`Kit.nine`, bordas em `Kit.NINE`) |
| Ícones de status (os 12): bloqueio, veneno, queima, espelho, esquiva, revide, imune, dado guardado, fúria, sede, próxima mão, marcado (olho) | `assets/icons/status/<id>.png` (64×64) |
| Ícones de efeito nos cartões de magia: dano, cura, vida máxima, dreno, truque de dados, sacrifício, limpeza (bloqueio, esquiva, espelho, revide, imune e mexida na mão usam os de status) | `assets/icons/fx/<id>.png` (64×64); `Spells.icon_key` escolhe |
| Torre: portas (Fácil, Normal, Difícil, Insana, Mestre), paradas (Loja, Cura, Escola, Poço), todas as ofertas e as 3 recompensas do Mestre | `assets/tower/door_<id>.png`, `stop_<id>.png` (128×128); `assets/icons/offer/<kind>.png` (64×64) |
| Fontes: números (vida, dano, contagens) e títulos | `assets/fonts/Bungee-Regular.ttf`, `assets/fonts/PixelifySans.ttf` (`Kit.num_font`, `Kit.title_font`, `Kit.title`) |
| Dados 3D e 2D | gerados em código de propósito (`ui/dice_3d.gd`, `ui/die_face.gd`, `docs/DADOS_VISUAL.md`); não precisam de arquivo |

Prompts e andamento item a item: [`docs/PAUTA_ARTE.html`](PAUTA_ARTE.html). Para recortar fundo de
arte gerada: `tools/recortar_fundo.py`.

## 1. O que ainda é desenhado em código ou só texto

A pauta de arte está toda feita. O que sobra é opcional ou é código.

| Elemento | Arquivo | Hoje |
|---|---|---|
| Cartões da torre | `ui/tower_screen.gd` | ilustração no topo, mas o cartão em si é cor lisa (dá para usar `card_<raridade>.png` nas ofertas de magia) |
| Ilustração por magia | `ui/spell_card.gd` | só o ícone do tipo de efeito (opcional) |
| Buracos dos dados | `ui/hole.gd` | desenhados em código (aceitável; arte opcional) |
| Efeito da magia (bola de luz) | `ui/spell_bolt.gd` | círculos e rastro em código, só cor muda (verde/vermelho/azul) |
| Painéis translúcidos da luta e botões coloridos | `ui/duel_screen.gd`, `ui/kit.gd` | `StyleBoxFlat` de propósito (a textura só entra nas cores neutras) |
| Nome e bolsa sobre as fotos | — | SPEC_v3 §13: "placeholder até haver arte" |
| Peças do grimório | `ui/grimoire_view.gd` | forma única por peça (sem emendas), cor do efeito, borda da raridade e ícone do efeito; sem textura própria |

## 6. Fora da arte visual

- **Som:** não há nenhum áudio no projeto (nem música nem efeitos).
- **Fonte da interface:** títulos na Pixelify Sans (a partir de 20 px; menor que isso ela
  embaralha letras) e corpo na fonte padrão do Godot.
- **Extras dos dados não feitos** (`docs/DADOS_VISUAL.md`): superfície ondulando no Mercúrio,
  tranco de câmera no Ósmio, rebite nas faces travadas do Chumbo, linha de luz entre Carbonos.

## Ordem sugerida

1. Som.
2. Retratos com vaidade no próprio desenho (medalha, diploma, broche), para quando houver gerador: hoje a vaidade é a roseta na moldura (`assets/ui/rosette_*.png`).
