# Visual dos dados: cor, acabamento e brilho

Cada elemento tem uma matéria própria. As três camadas respondem a perguntas diferentes:

| Camada | Pergunta | Regra |
|---|---|---|
| Cor | Que dado é este? | Um matiz por elemento, inspirado na química real (descarga do hidrogênio lilás, vidro de urânio verde, lâmpada de sódio âmbar). |
| Acabamento | Do que ele é feito? | Marfim, vidro, espelho, fosco, fibroso, ferrugem, grafite ou ceroso. Separa dados de cor parecida (Comum × Mercúrio). |
| Brilho | Ele está fazendo algo agora? | Só Hidrogênio, Urânio, Sódio e Carbono brilham, e o brilho cresce com o estado do jogo. Dado sem efeito ativo nunca brilha. |

A tabela fica em `Elements.LOOKS` (`engine/elements.gd`). `Elements.COLORS` continua existindo e é a cor de texto (`accent`) de cada elemento, legível sobre o fundo escuro.

## Os dez dados

| Dado | Corpo | Tinta | Texto | Acabamento | Brilho |
|---|---|---|---|---|---|
| Comum | `#efe6d2` | `#2a2230` | `#efe6d2` | marfim (rugosidade 0,5, clearcoat 0,3) | — |
| Hidrogênio | `#5b2fb0` | `#ffffff` | `#d9a6ff` | vidro (rugosidade 0,12, alfa 0,95, clearcoat 1, rim) | pontinhos `#d58cff` |
| Ósmio | `#2f3d63` | `#cfd8f0` | `#8fa8ff` | espelho (metal 0,8, rugosidade 0,16) | — |
| Urânio | `#5fcf2a` | `#0f2a06` | `#8cf259` | vidro (rugosidade 0,25, clearcoat 0,6) | corpo `#7cff3a` |
| Sódio | `#e8780f` | `#3a1600` | `#ff9e4d` | ceroso (rugosidade 0,55, rim) | arestas `#ff6a00` |
| Mercúrio | `#dfe5ee` | `#1a1f2a` | `#d1d6e6` | espelho (metal 0,7, rugosidade 0,14, clearcoat 0,4) | — |
| Chumbo | `#555a60` | `#c4c9cf` | `#9aa0a8` | fosco com arranhões (rugosidade 0,85) | — |
| Amianto | `#d9b44a` | `#2b2410` | `#e3c25e` | fibroso (rugosidade 0,9) | — |
| Carbono | `#18181c` | `#f4f8ff` | `#b8c4d6` | grafite (metal 0,5, clearcoat 0,5) | pontinhos `#9fd8ff` |
| Ferro | `#7a4128` | `#f0c8a8` | `#c7764e` | ferrugem com arestas gastas (rugosidade 0,85) | — |
| Ouro | `#e0a514` | `#3a2604` | `#ffcf3f` | espelho (metal 0,85, rugosidade 0,18, clearcoat 0,5) | — |
| Césio | `#1d4fc4` | `#eaf3ff` | `#6fb4ff` | vidro (rugosidade 0,2, alfa 0,95, clearcoat 0,7, rim) | corpo `#3d9bff` (o azul do cloreto de césio) |
| Lítio | `#737980` | `#d8ff6a` | `#b8ff2e` | espelho escovado (metal 0,7, rugosidade 0,3) | só pontinhos e algarismos `#b8ff2e` (emissão em modo multiplicar, `glow_only`: o corpo fica cinza) |
| Titânio | `#a33cc4` → `#3d6fe0` → `#e0b040` | `#ffffff` | `#e08cf0` | anodizado: faixas furta-cor magenta, azul e dourado (metal 0,8, rugosidade 0,22) | — |
| Cobre | `#18655a` → `#c8682e` | `#ff9f5f` | `#5fe0cc` | pátina: verdete em manchas, com o cobre aparecendo nas arestas gastas (rugosidade 0,6, metal 0,15) | — (pontinhos em cobre polido) |
| Estrôncio | `#c8161d` | `#ffd23a` | `#ff6b5a` | envernizado (marfim com clearcoat 0,9): o tubo vermelho dos fogos | — (pontinhos amarelos das faíscas) |

## Brilho como estado

`Elements.heat(f, d, idle)` dá o estado de 0 (repouso) a 1 (ativo); `Elements.energy(el, heat)` converte em energia de emissão.

| Dado | Em repouso | Ativo quando | Reação |
|---|---|---|---|
| Hidrogênio | pontinhos fracos, pulso lento | Solitário valendo (bolsa de menos de 8) | halo e pontinhos fortes |
| Carbono | pontinhos fracos | outro Carbono na mão (cresce até 4 na cadeia) | pontinhos mais fortes a cada elo |
| Urânio | corpo aceso, pulso lento | parado na mão, ainda não posto numa magia | pisca como contador Geiger |
| Sódio | brasa nas arestas | queima o inimigo ao ser usado | faíscas |
| Amianto | — | causa dano em quem usa | nuvem de poeira |
| Césio | corpo azul aceso | posto numa magia (vai irradiar o inimigo) | faíscas azuis saindo do cartão |
| Lítio | pontinhos apagados | carga da bateria (+2, +4, +6: acende aos poucos) | "Lítio carrega +2" no fim do turno |

## Luz e aparência na coluna

- A mesa tem quatro luzes (`DiceRoll3D.add_lights`): a principal do alto à esquerda, uma suave de cima, uma lateral baixa da esquerda e um preenchimento fraco do outro lado. O céu de reflexo (`DiceRoll3D.reflection_sky`) é uma sala quente e escura, o feltro rubro embaixo e a lâmpada da mesa (um ponto forte na direção da luz principal, outro mais fraco na da lateral): é o que Mercúrio, Ósmio e Ouro refletem. Os metais não são espelho puro (Mercúrio metal 0,7, Ósmio 0,8).
- **Mesa de feltro** (`FeltTable`, o fundo da luta): um plano 3D atrás de tudo, com a mesma câmera e as mesmas luzes. A rolagem põe os dados no mundo dela: a luz principal faz sombra de verdade no feltro (só ela, um mapa de sombra) e cada dado aceso leva uma `OmniLight3D` fraca, que tinge o pano em volta (o shader soma um brilho que não depende da cor do pano, senão o verde do Urânio sumiria no vermelho). A vista da rolagem, por cima da interface, não vê o feltro (camada `FELT_LAYER`) e mostra só os dados. Parada, a mesa é desenhada uma vez (`UPDATE_ONCE`); só redesenha a cada quadro durante a rolagem.
- **Magias pintadas no feltro** (`SpellCard`): como as linhas de uma mesa de roleta, tudo é tinta fosca absorvida pelo pano (`FeltPaint`, shader de CanvasItem): a cor da família um pouco dessaturada e puxada para o creme, escurecida, com borda serrilhada fina e falhas de pigmento seguindo a fibra. O texto e os buracos usam a mesma tinta; o dado posto não. Nada brilha: aceitar o dado engrossa o traço e ganha um fio de ouro fosco pintado por dentro; pronta engrossa o traço; usada ou recusando, a tinta fica gasta (`WORN`). **Tudo** no palco das magias (contornos, textos, ícones, buracos e o dado posto) fica na perspectiva da mesa: uma homografia leva o retângulo do palco a um trapézio (`FeltPaint.KEYSTONE` = 11%: a borda de cima encolhe para o centro e as fileiras de cima ficam mais baixas), aplicada no shader de vértice. Os controles continuam no lugar: o toque usa a homografia inversa (`_has_point` de `SpellCard` e `Hole`), e os efeitos e dados que voam até um cartão usam a direta (`DuelScreen._on_screen`). A câmera dos dados é ortográfica; a perspectiva é só da pintura.
- Os dados da coluna e dos cartões são fotos do próprio dado 3D (`DieSnapshot`), com a mesma câmera e as mesmas luzes da mesa. Quando a rolagem para, cada dado voa de onde parou até o seu buraco, girando até ficar reto, com a mesma cara. Sem vídeo (testes, simulação) ou enquanto a foto não fica pronta, vale a face 2D (`DieFace`).

## Itinerário

- [x] **Fase 1: paleta e acabamento.** `Elements.LOOKS`; `Dice3D.material()` lê rugosidade, metal, clearcoat, rim e transparência da tabela; texturas de arranhão, fibra e ferrugem com `FastNoiseLite` (albedo e normal); `DieFace` desenha o mesmo acabamento em 2D.
- [x] **Fase 2: reflexo e halo.** A rolagem 3D ganha um céu só de reflexo, com o fundo ainda transparente. Os dados que brilham projetam um halo colorido na mesa (quad com gradiente, como a sombra), em vez do glow do `Environment`, que não é confiável com fundo transparente no renderer Compatibility.
- [x] **Fase 5: mesa de feltro.** O fundo da luta vira feltro rubro em 3D; sombras reais e luz dos dados acesos no pano (o halo e a sombra desenhados ficam só para a rolagem sem mesa); céu de reflexo trocado pela sala com a lâmpada; magias pintadas no feltro.
- [x] **Fase 3: brilho de estado.** `heat` vai no evento `hand` do resolver e nos buracos (`Hole`) da bandeja e dos cartões; a emissão pulsa no 3D (`DiceRoll3D.glow_pulse`) e no 2D (halo do `StyleBoxFlat` e pontinhos acesos).
- [x] **Fase 4: partículas.** Faíscas do Sódio e poeira do Amianto (`CPUParticles2D`) saindo do cartão da magia.
- [ ] **Ajuste visual no aparelho.** Os números foram escolhidos sem ver o jogo rodando: conferir energia do brilho, transparência do vidro e força do reflexo num celular.
- [ ] **Extras da proposta, não feitos:** superfície ondulando no Mercúrio, tranco de câmera no Ósmio, rebite nas faces travadas do Chumbo e linha de luz entre Carbonos.

## Testes

`tests/test_dados_3d.gd` confere que todo elemento tem visual completo, que a tinta tem contraste mínimo de 3:1 com o corpo, que o texto tem 4,5:1 com o fundo, que os corpos são diferentes entre si, que só os quatro dados brilham e que o estado acende cada um no momento certo.
