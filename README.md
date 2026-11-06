# DICEMAXXING

Jogo de dados para Android: suba uma torre com uma bolsa de dados e um grimório de magias. Feito em Godot 4.7 + GDScript.
Tela em paisagem.

- Regras: [`docs/SPEC_v3.md`](docs/SPEC_v3.md) (v3, fonte da verdade). A fatia vertical (seção 12) está implementada.
- Magias: [`docs/CATALOGO_MAGIAS.md`](docs/CATALOGO_MAGIAS.md) (catálogo único e princípios de design). Propostas anteriores, com o feedback, em `docs/MAGIAS_DICE_FUCKERY.md` e `docs/MAGIAS_FISICAS.md`.
- Personagens: [`docs/PERSONAGENS.md`](docs/PERSONAGENS.md). Jogáveis: Assassino, Vampiro e Bárbaro.
- Raridade de magias e dados: [`docs/RARIDADE.md`](docs/RARIDADE.md).
- Ideias futuras: [`docs/ROADMAP.md`](docs/ROADMAP.md) (ex.: builds vencedoras viram inimigos).
- Histórico: [`docs/SPEC.md`](docs/SPEC.md) (v2, coliseu com equipamentos; substituída).
- Motor de regras (sem cenas, testável): `engine/`.
- Interface (paisagem): `ui/`. A tela de duelo anima os eventos do motor.
- Dados: as mãos rolam em 3D por cima do palco (`ui/dice_roll_3d.gd`, física própria em
  `ui/dice_physics.gd`, malha e texturas geradas em código em `ui/dice_3d.gd`). Faces de 1 a 6
  com pontinhos, valores maiores com algarismos, tudo em baixo relevo; o 2D segue a mesma regra
  (`ui/die_face.gd`). Tocar na tela pula a rolagem.
- Fotos dos personagens: `assets/portraits/`, 3 variações por arquétipo (`sorcerer_1..3`, `assassin_1..3`, `minimalist_1..3`, `metallurgist_1..3`, `copyist_1..3`,
  `perfectionist_1..3`, `vampire_1..3`, `barbarian_1..3`). Mestre e variantes têm foto própria (`porteiro_1`, `lixeiro_1`, `piromante_1`, `fundidor_1`, `monge_1`).
  A variação é sorteada uma vez por lutador e salva (`Fighter.portrait`), tanto para você quanto
  para o inimigo. A arte preenche a foto e só aparece dentro da moldura (`frame_enemy.png`
  vermelha, `frame_player.png` verde). Sem a arte, `ui/portrait.gd` desenha uma silhueta.
- Fundos: `assets/backgrounds/` — `tavern.jpg` na luta, `menu.jpg`, `tower.jpg`, `victory.jpg` e
  `defeat.jpg` nas outras telas (`Kit.background`: cobre a tela, escurecido; painéis por cima).
- Interface: painel, botão, moldura da barra de vida e moldura do cartão de magia por raridade em
  `assets/ui/` (9-slice, `Kit.nine`/`Kit.NINE`); moeda em `assets/icons/coin.png` (`Kit.coin`).
- Ícones de status: `assets/icons/status/<id>.png` (64×64), os 11 com arte; sem o arquivo, mostra a sigla colorida.
- Cartões de magia: ícone do tipo de efeito ao lado do nome (`assets/icons/fx/`, ou o de status quando o
  efeito é o mesmo; `Spells.icon_key`).
- Torre: cada porta, parada e oferta é a ilustração grande (`assets/tower/`, `assets/icons/offer/`;
  `TowerScreen.art_path`), sem moldura, que escolhe ao toque. Embaixo, o nome curto (até 5 palavras,
  `short` nos textos; portas só o nome) e um "i" com os detalhes; o nome não reage ao toque.
  No topo, a faixa do jogador (`ui/player_strip.gd`): vida, moedas e a bolsa por elemento.
  Captura manual: `sim/shot_tower.gd`.
- Elementos citados em textos (detalhes das ofertas, grimório, ficha do inimigo) viram links na
  cor do elemento; o toque abre o que ele faz (`ui/element_info.gd`).
- Números sobre as fotos na fonte Bungee (`assets/fonts/`, licença SIL OFL) com contorno preto.
- Efeitos das magias (`ui/spell_bolt.gd`): cada efeito voa do cartão da magia até a foto do alvo, em
  verde para cura, vermelho para dano e azul para os outros efeitos; ao chegar, a foto pisca na cor
  (e treme no dano) e o número sobe sobre ela (+X verde, −X vermelho). Veneno, queima e efeitos do
  fim do turno aparecem direto no alvo, sem viagem.
- Logo do título no menu: `assets/title_logo.png` (sem ele, o menu volta ao dado com chapéu e ao nome em texto).
- Logo: `assets/logo.png` (dado com chapéu de mago, fundo recortado); ícone do app: `assets/icon.png` (o mesmo dado sobre fundo ameixa).
- Arte a fazer, com prompts de gerador: [`docs/PAUTA_ARTE.html`](docs/PAUTA_ARTE.html). Geradores não fazem
  transparência; os prompts pedem fundo magenta/verde chapado e `tools/recortar_fundo.py` recorta (também limpa o
  quadriculado falso): `python3 tools/recortar_fundo.py gerada.png saida.png --size 64x64`.
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
xvfb-run godot --fixed-fps 30 -s res://sim/shot_shake.gd -- --out=/tmp   # quadros da tremida em cada faixa de dano
```

## APK

Cada push roda o workflow `CI` no GitHub Actions: testes, simulação e um APK de debug
(artefato `dicemaxxing-apk`, em .zip). Em pushes, o `.apk` também sai solto num
pré-lançamento por branch, mais fácil de baixar pelo celular:
`https://github.com/luizfsantos-alt/DICEMAXXXING/releases/download/apk-<branch com / trocado por ->/dicemaxxing.apk`.
Instale o `.apk` no celular (é preciso permitir "instalar apps desconhecidos").

### Releases e atualização sem perder o save

- Todo APK (branch e tag) é assinado com a mesma chave, vinda dos secrets
  `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD` e `ANDROID_KEY_ALIAS`. Assinatura
  igual + `version/code` maior (o número do run do CI) = o Android instala por cima e o save fica.
  Sem os secrets, branches saem com chave descartável e tags falham.
- **Lançar uma versão:** suba `config/version` no `project.godot` (ex.: `0.4.0`) e faça o merge
  na branch principal. O CI vê que ainda não existe a tag `v0.4.0`, gera o APK de release e
  cria a tag e o release sozinho. Versão com sufixo (`0.5.0-beta`) sai como pré-lançamento.
- Push de uma tag `v1.2.3` gera um APK de release e o release `v1.2.3` no GitHub. A versão
  (`version/name` e `application/config/version`) vem da tag. Tag com sufixo (`v1.2.3-beta`)
  sai como pré-lançamento.
- Ao abrir, o jogo exportado consulta `/releases/latest` e, se houver versão mais nova, mostra
  "Nova versão disponível" no menu com um botão para baixar o APK. Sem internet, nada aparece.

Gerar a chave (uma vez; guarde o arquivo e a senha fora do repositório):

```sh
keytool -genkeypair -v -keystore dicemaxxing.keystore -alias dicemaxxing \
  -keyalg RSA -keysize 4096 -validity 36500 -storetype PKCS12
base64 -w0 dicemaxxing.keystore > keystore.b64   # macOS: base64 -i dicemaxxing.keystore
```
