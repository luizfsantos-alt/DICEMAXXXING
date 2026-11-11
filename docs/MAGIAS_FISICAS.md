# Magias de dano físico (proposta)

> **Status: histórico.** O resultado está em `docs/CATALOGO_MAGIAS.md`. Proposta original: São 10 ofensivas e 10 defensivas para **magos de dano físico**: os que acham que o músculo é o feitiço mais avançado de todos. Seguem o tom de `docs/TOM.md` (duelo de egos) e as diretrizes do feedback da rodada 1 (`docs/MAGIAS_DICE_FUCKERY.md`, "Feedback"). Números *(iniciais)*, a passar pelo simulador.

---

## Feedback (rodada 2)

Respostas completas em `docs/MAGIAS_FISICAS_opinioes.xlsx`.

| Veredito | Magias |
|---|---|
| **Manter** | Força Desnecessária, Arrancar das Mãos, Exibição de Velocidade, Levantar Peso Morto (**renomear para "Levantar Peso"**), Armadura de Músculo, Recuo Estratégico, Presença Imponente, Concentrar Força |
| **Ajustar** | **Física Aplicada**: peça maior, porque é forte. **Impulso Calculado**: o dado volta com **+2 em todas as faces** e aparece **obrigatoriamente** na próxima mão. **Lição de Anatomia**: a dinâmica é boa, mas o texto é difícil de entender rápido. **Golpe para a Foto**: todos os dados > 5. **Revide Elegante**: devolve valor simples, não ×2. **Chave de Braço Didática**: **todos** os dados dele valem metade. **Rasteira Humilhante**: Diagonal de 3 casas. **Suor de Campeão**: reduz efeitos negativos em geral. |
| **Cortar** | Combo Ensaiado e a regra da ordem do inventário (a ordem de resolução deve sair do jogo no futuro); Elegância Marcial e Agarrão Técnico (leem a mão anterior do inimigo); Calo de Orgulho (alterar um dado da bolsa até o fim da luta vale pouco, porque ele pode não voltar à mão) |
| **Regras mantidas** | Dados devolvidos para a mão, marca para a próxima mão, exigências novas (menos a `match`) |

---

## 0. Como estas magias foram pensadas

### 0.1 A identidade física

O mago físico **não muda a regra do jogo: muda o próprio dado**. Ele quebra o dado em dois, funde dois em um, calcula a força com multiplicação, aproveita a força do adversário e castiga a bolsa dele. Ele combina com o **Assassino** (mão de 6 e cinto 6×1), por isso **quase tudo é reto** e cabe no cinto. As poucas peças tortas ficam para o Feiticeiro ou para um arquétipo físico futuro.

### 0.2 Diretrizes do feedback aplicadas

| Diretriz | Como aparece aqui |
|---|---|
| Tudo passa por dado posto em slot | Nenhum truque. As magias que mexem em dados **devolvem dados para a mão** (Força Desnecessária, Concentrar Força) ou **marcam o próprio dado** (Impulso Calculado, Recuo Estratégico, Calo de Orgulho). |
| O ganho é calculado na hora | Todo dano e todo bloqueio têm número fechado ao lançar. O Revide Elegante devolve um **valor fixo**, conhecido agora. |
| Counterplay por exigência específica | Agarrão Técnico pede um dado **igual a um da última mão do inimigo**; Chave de Braço pede um **3**; Levantar Peso Morto pede um **1**. |
| Sem sorte pura | Nada rola de novo no meio da resolução. |
| Efeito confuso não paga formato grande | As peças com 3 ou 4 casas têm efeitos de uma linha. |
| Não atrapalhar quem lança | Nenhum efeito aumenta os dados do inimigo nem dá pares a ele. |

### 0.3 Regras de apoio

- **Dados devolvidos para a mão** (Força Desnecessária, Concentrar Força): aparecem na bandeja **na hora em que o dado entra no buraco**, como dados temporários, e podem alimentar outras magias **neste turno**. Tirar o dado do buraco recolhe os devolvidos e solta as magias que eles alimentavam. No fim do turno, os temporários somem.
- **Dado marcado para a próxima mão** (Impulso Calculado, Recuo Estratégico, Concentrar Força): o dado não vai para o descarte. Ele entra na sua próxima mão **com o valor indicado, sem rolar, além da mão normal**. Só um dado marcado por vez; uma marca nova substitui a anterior.
- **Exigência checa o valor rolado.** Bônus de outras magias (Combo Ensaiado) só entram no cálculo do efeito.
- **Ordem do inventário importa.** O Combo Ensaiado lê a magia anterior na ordem de resolução. No cinto do Assassino, isso quer dizer "a peça à esquerda".

### 0.4 Exigências novas (além das já aprovadas)

| Código | No buraco | Significado |
|---|---|---|
| `match` | "= dele" | 1 dado de valor **igual a algum valor da última mão do inimigo** |
| `low_one` | "≤ 3" num dos buracos | n dados, e **pelo menos um** é ≤ v |
| `top_any` | "MÁX" num dos buracos | n dados, e **pelo menos um** está na face máxima dele |

---

## 1. Ofensivas

| # | Magia | Formato | Cinto | Pede | Efeito | Uso |
|---|---|---|---|---|---|---|
| F-O1 | **Força Desnecessária** | 1×1 | sim | dado ≥ 4 | Dano = valor. O dado **se parte em dois**: voltam à mão 2 dados com **metade do valor** cada (arredonda para cima), prontos para outras magias neste turno. Um 6 vira 3 + 3, um par para a Bola de Fogo. | sempre |
| F-O2 | **Física Aplicada** | 2×1 | sim | 2 dados, um ≤ 3 | Dano = **maior × menor**. O dado baixo é o ponto de apoio da alavanca: 12 × 3 = 36. | sempre |
| F-O3 | **Combo Ensaiado** | 1×1 | sim | qualquer dado | Dano = valor + **o maior dado usado na magia anterior** do inventário (a peça à esquerda, no cinto). Na primeira posição, só o valor. | sempre |
| F-O4 | **Arrancar das Mãos** | 1×2 | sim | dado ≤ 2 | Dano = valor. O **dado mais forte da bolsa do inimigo** (maior soma de faces) fica fora da bolsa dele até o fim da luta. Ósmio não pode ser arrancado. | 1× por luta |
| F-O5 | **Elegância Marcial** | 1×1 | sim | dado ≤ 3 | Dano = valor + **o maior valor da última mão do inimigo**. Quanto mais forte ele, pior para ele. | sempre |
| F-O6 | **Exibição de Velocidade** | 3×1 | sim | 3 dados ≤ 3 | **3 golpes separados**, cada um = valor ×2. Cada carga de Esquiva ou Espelho para um golpe. Se os 3 forem iguais, são **6 golpes**. | sempre |
| F-O7 | **Levantar Peso Morto** | 1×1 | sim | um 1 | Dano = **4 × quantos dados de valor 1 há na sua mão** (contando este). O Chumbo do Lixeiro e do Porteiro vira peso de treino. | sempre |
| F-O8 | **Impulso Calculado** | 1×2 | sim | qualquer dado | Dano = valor. O dado fica **marcado**: entra na sua próxima mão com **valor +2**, sem rolar. | sempre |
| F-O9 | **Lição de Anatomia** | L (3) | não | 2 dados iguais | Dano = soma ×2. A **face mais alta de 2 dados aleatórios da bolsa do inimigo vira 1** até o fim da luta (adesivos daquela face desligados). Hélio é imune. | 1× por luta |
| F-O10 | **Golpe para a Foto** | Reta 4 | sim | 4 dados, um na face MÁX | Dano = **o maior dado × 4**. Um 24 com adesivos dá 96. Os outros três dados servem só como plateia. | 1× por luta |

**Notas**
- **Força Desnecessária** é o motor do mago físico: quebra dado alto em dados baixos, que pagam as exigências ≤ 3 (Física Aplicada, Elegância Marcial, Exibição de Velocidade, Escudo Arcano). Como cada magia só é usada 1 vez por turno, a cadeia termina sozinha.
- **Combo Ensaiado** dá valor à ordem no cinto, que hoje quase não importa: vale pôr a magia de dado alto logo antes dele.
- **Elegância Marcial** é a resposta do jogo aos inimigos de andar alto, cheios de adesivos: a última mão deles fica visível, e o jogador sabe o dano antes de lançar.
- **Levantar Peso Morto** transforma em força os dados-lixo que o jogo põe na sua bolsa.

---

## 2. Defensivas

| # | Magia | Formato | Cinto | Pede | Efeito | Uso |
|---|---|---|---|---|---|---|
| F-D1 | **Calo de Orgulho** | 1×1 | sim | qualquer dado | Bloqueio = valor. A **menor face desse dado passa a valer este valor** até o fim da luta. O dado fica mais forte a cada uso. Faces de Chumbo não mudam. | sempre |
| F-D2 | **Revide Elegante** | 2×1 | sim | dado ≤ 3 | Bloqueio = valor ×2. Cada golpe que acertar você enquanto este bloqueio existir **devolve valor ×2 de dano** ao atacante. | sempre |
| F-D3 | **Agarrão Técnico** | 1×1 | sim | `match` (= um valor da última mão dele) | Bloqueio = valor. Um dado da bolsa do inimigo **que tenha esse valor numa face** fica **preso**: fora da bolsa dele nos próximos 2 turnos dele. | sempre |
| F-D4 | **Chave de Braço Didática** | 1×1 | sim | um 3 | Na próxima mão do inimigo, **o maior dado dele vale metade** (arredonda para baixo). | 1× por luta |
| F-D5 | **Rasteira Humilhante** | Diagonal (2) | não | 2 dados ≤ 2 | Bloqueio = soma ×2. O inimigo tira **1 dado a menos** na próxima mão. | sempre |
| F-D6 | **Suor de Campeão** | 1×1 | sim | dado ímpar | Seu **veneno e sua queima caem pelo valor** do dado (primeiro a queima, depois o veneno). Você ganha **bloqueio = o quanto caiu**. | sempre |
| F-D7 | **Armadura de Músculo** | 2×1 | sim | 2 dados ≤ 3 | Bloqueio = **produto ×2** (3 × 3 × 2 = 18). | sempre |
| F-D8 | **Recuo Estratégico** | 1×1 | sim | dado ≤ 2 | Anula o **próximo golpe**. O dado fica **marcado** e entra na sua próxima mão **valendo 6**, sem rolar. Recuar não é fugir, é tomar distância. | 1× por luta |
| F-D9 | **Presença Imponente** | 1×2 | sim | um 6 | Bloqueio = **3 × quantos dados você tem na mão** agora (contando os já postos e os devolvidos). Com mão de 6, 18; com Força Desnecessária, mais. | sempre |
| F-D10 | **Concentrar Força** | L (3) | não | 2 dados iguais | Bloqueio = soma. Os dois dados **se fundem**: um dado marcado entra na sua próxima mão **valendo a soma**, sem rolar. O inverso da Força Desnecessária. | sempre |

**Notas**
- **Calo de Orgulho** é dice-fuckery de característica: edita uma face durante a luta e tudo volta ao normal no fim dela. Num dado de Urânio, a face 3 vira 8 e o veneno continua.
- **Agarrão Técnico** só funciona se você **ler a mão do inimigo** e guardar o dado certo: é o counterplay pedido.
- **Recuo Estratégico, Impulso Calculado e Concentrar Força** disputam a única marca, então escolher qual dado guardar é uma decisão do turno.
- **Presença Imponente + Força Desnecessária**: quebrar um dado aumenta a mão, e o bloqueio sobe.

---

## 3. Combos para o simulador medir

| Combo | O que acontece | Risco |
|---|---|---|
| Força Desnecessária (12) → 6 + 6 → Bola de Fogo | 12 de dano + par de 6 → 36 + queima | a Bola não tem mais limite por luta |
| Força Desnecessária (6) → 3 + 3 → Física Aplicada e Armadura de Músculo | dano e bloqueio com um dado só | conferir se o Assassino fica forte demais |
| Concentrar Força (6 + 6) → próximo turno um 12 marcado → Física Aplicada com um 3 | 12 × 3 = 36 | 2 turnos de preparo, a marca é única; um dado marcado **não** conta como face MÁX |
| Levantar Peso Morto contra o Porteiro de Chumbo | o Chumbo dele vira dano | pode deixar o Mestre do andar 10 fácil |
| Calo de Orgulho repetido no mesmo dado | o dado sobe a menor face a cada turno | só volta na mão quando a bolsa gira |
| Elegância Marcial contra inimigo de adesivos | ≤ 3 + 24 da mão dele = 27 | sempre: limitar se dominar o andar alto |

---

## 4. Impacto no motor

- **Dados devolvidos:** `TurnChoice` passa a gerar entradas temporárias na mão (`bag = -1`, como o Chumbo do Porteiro) quando certas magias recebem dado; `validate` resolve isso em ordem de alocação.
- **Marca:** `Fighter.marked = {bag: int, value: int}`, consumida em `draw_hand`.
- **Camada de luta no `Die`:** `fight_faces` (Calo de Orgulho, Lição de Anatomia), limpa em `reset_fight_state`.
- **Fora da bolsa por N turnos:** `Fighter.held = [{bag, turns}]` (Agarrão Técnico); "até o fim da luta" (Arrancar das Mãos) usa o mesmo campo com turnos infinitos.
- **Multi-golpe:** `Resolver.hit` já trata golpe a golpe; Exibição de Velocidade só chama `hit` várias vezes.
- **Revide:** guardar `riposte` junto do bloqueio; `hit` devolve o valor fixo enquanto `block > 0`.
- **Eventos novos:** `split`, `merge`, `mark`, `face_edit`, `held`, `riposte`.
- Textos em `data/texts_pt_br.json`.
