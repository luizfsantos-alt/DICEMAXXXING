# Magias de "dice-fuckery" (proposta)

> **Status: proposta, nada implementado.** São 10 magias ofensivas e 10 defensivas que mexem **temporariamente** no valor e nas características dos dados (face, adesivo, elemento, quantidade na mão). Os números são *(iniciais)* e devem passar pelo simulador. Formato, exigência, efeito e uso seguem o padrão de `docs/SPEC_v3.md` §5.

---

## 0. Regras de apoio

### 0.1 Durações (sempre escritas no cartão)

| Etiqueta | Dura até |
|---|---|
| **neste turno** | o fim do seu turno |
| **próxima mão dele** | o fim do próximo turno do inimigo (depois que ele rola) |
| **nesta luta** | o fim da luta; tudo volta ao normal na tela de recompensa |

Nada aqui é permanente. A bolsa salva (`SaveGame`) nunca guarda efeito temporário.

### 0.2 Truque ⚡ (categoria nova, 1 magia nesta lista)

Um **Truque** resolve **na hora da alocação**, não na resolução: o dado que paga o truque é consumido e o efeito cai num **outro dado que ficou na mão**, que pode alimentar outra magia no mesmo turno. Tudo continua reversível até "Terminar turno": tirar o dado do truque desfaz o efeito e solta o que dependia dele. A regra "cada dado alimenta uma magia" continua valendo, porque o dado que paga o truque não alimenta mais nada.

### 0.3 Hélio, Ósmio e Chumbo

- **Hélio** (imune a efeitos do inimigo) fica valioso: todo efeito "na mão dele" ou "na bolsa dele" abaixo **pula dados de Hélio**.
- **Ósmio** "não pode ser roubado" (§4.1): vale para o Golpe do Pix e a Mão Leve.
- **Chumbo**: faces travadas não aceitam adesivo, nem roubado.

### 0.4 Os inimigos também compram estas magias

Como o inimigo monta o inventário com as mesmas regras, **o jogador também vai sofrer tudo isto**. Isso dá valor ao Hélio, à Capa de Hélio e ao Reset de Fábrica, e torna a ficha do inimigo (inventário visível) ainda mais importante.

### 0.5 Exigências e formatos novos

**Exigências** (somam-se a `any`, `max`, `exact`, `pair`, `seq3`):

| Código | Lê-se no buraco | Significado |
|---|---|---|
| `min` | "≥ 5" | 1 dado de valor ≥ v |
| `odd` / `even` | "ímpar" / "par" | 1 dado ímpar / par (n dados, se "n") |
| `max_n` | "≤ 2" ×2 | n dados, todos ≤ v |
| `distinct` | "≠" entre os buracos | n dados de valores todos diferentes |
| `top` | "MÁX" | o dado está na **face mais alta que ele tem** (um d6 com adesivo na face 6 precisa mostrar 12) |

**Formatos novos** (todos giram, como hoje):

```
Z (4)        T (4)        Cruz (5)     U (5)        Diagonal (2)   Xadrez (3)   Reta 4
##.          ###          .#.          #.#          #.             #.#          ####
.##          .#.          ###          ###          .#             .#.
                          .#.
```

- **Diagonal** e **Xadrez** são peças **com buracos**: as casas não se tocam, e outra peça pode ocupar o vão. Elas ocupam pouco, mas espalham a grade.
- **No cinto 6×1 do Assassino** só cabem as retas (1×1, 2×1, 3×1, reta 4).

---

## 1. Ofensivas

| # | Magia | Formato | Pede | Efeito | Duração | Uso |
|---|---|---|---|---|---|---|
| O1 | **Tigrinho** | 1×1 | qualquer dado | Rola o **mesmo dado** de novo. Se repetir o valor: **JACKPOT**, dano = valor ×6. Se não: dano = valor novo. | neste turno | sempre |
| O2 | **Pipoca** | 3×1 | `top` (MÁX) | Dano = valor. Rola o dado de novo e **soma enquanto sair a face máxima** dele (no máximo 5 estouros). | neste turno | sempre |
| O3 | **Golpe do Pix** | 1×2 | dado ≤ 2 | Rouba **1 adesivo ×2** do dado mais adesivado da bolsa do inimigo e o cola na face que você rolou. Dano = valor novo. | nesta luta (o adesivo volta) | 1× por luta |
| O4 | **De Ponta-Cabeça** | Z | dado par | Dano = valor. Na próxima mão do inimigo, **cada dado mostra a face oposta** à que rolou (posição 1↔6, 2↔5, 3↔4; os adesivos vão junto, então o 24 dele vira o 1 do outro lado). | próxima mão dele | 1× por luta |
| O5 | **Inflação** | 1×1 | `min` ≥ 4 | Dano = valor. Próxima mão do inimigo: **+3 em todos os dados**. Ele bate mais, mas perde Escudo (≤ 3), Esquiva (≤ 2), Espelho e Sacrifício (= 1). | próxima mão dele | sempre |
| O6 | **Banho de Chumbo** | L (3 casas) | 2 dados ≤ 2 | Dano = soma ×2. **2 dados aleatórios da bolsa do inimigo viram Chumbo** (faces 1, 1, 1 travadas; o resto não muda). | nesta luta | 1× por luta |
| O7 | **Mão Leve** | 1×1 | um 2 | No próximo turno do inimigo, depois que ele rola, o **maior dado dele sai da mão dele** e entra na **sua** próxima mão com o mesmo valor (sem rolar). Depois volta para a bolsa dele. | próxima mão dele + sua próxima mão | 1× por luta |
| O8 | **Ctrl+C Ctrl+V** ⚡ | 2×1 | qualquer dado | **Truque.** Toque num dado da mão: ele vira **cópia exata** deste (valor e elemento). Fabrica pares para Bola de Fogo e Transfusão, ou duplica um 24. Copiar Urânio também copia o veneno. | neste turno | sempre |
| O9 | **Radiação** | T | `min` ≥ 5 | Dano = valor. **Todos os dados da próxima mão do inimigo viram Urânio** (mantêm o valor): o que ele não usar o envenena (+2 cada). | próxima mão dele | 1× por luta |
| O10 | **Tabuada Proibida** | Cruz (5) | 3 dados ≤ 4 | Dano = **produto** dos três (4 × 4 × 4 = 64). Dados baixos e adesivos pequenos (um 2 com ×2 vale 4) viram arma. | — | 1× por luta |

**Notas de design**
- **Tigrinho e Pipoca** são as magias de **cassino**: rolar no meio da resolução, com animação própria (o dado gira de novo no cartão). O valor esperado do Tigrinho (≈ 2× o valor) passa pelo simulador antes de fixar o ×6.
- **Pipoca** combina com edição de face: um dado editado para 6, 6, 6, 6, 1, 1 estoura com frequência. Por isso o limite de 5 estouros.
- **De Ponta-Cabeça** contra **Chumbo** (1, 1, 1, 2, 2, 3) dá 3, 2, 2, 1, 1, 1: a mesma distribuição. Chumbo é imune "de graça", e é engraçado que seja assim.
- **Inflação** é de dois gumes: serve para travar Feiticeiros defensivos, mas aumenta o dano que você vai receber.
- **Banho de Chumbo e Golpe do Pix** atacam **a build** do inimigo, não a vida dele. São as respostas a inimigos de andares altos, cheios de adesivos.

---

## 2. Defensivas

| # | Magia | Formato | Pede | Efeito | Duração | Uso |
|---|---|---|---|---|---|---|
| D1 | **Leão da Receita** | 2×1 | um 4 | No próximo turno do inimigo, o **maior dado dele é taxado**: passa a valer 1, e você ganha **bloqueio = a diferença** (um 24 vira 1 e você ganha 23 de bloqueio). | próxima mão dele | 1× por luta |
| D2 | **Reset de Fábrica** | 2×2 | `seq3` | Próxima mão do inimigo: **sem adesivos e sem elementos**, só a face crua. Sem queima de Sódio, sem ×3 de Hidrogênio, sem cópia de Mercúrio. Disputa a sequência com o Meteoro. | próxima mão dele | 1× por luta |
| D3 | **Ímpar ou Par** | 1×1 | qualquer dado | Os dados da próxima mão do inimigo com a **mesma paridade** deste **viram 1**. Cuidado: 1 alimenta o Espelho e o Sacrifício dele. | próxima mão dele | 1× por luta |
| D4 | **Algema** | Diagonal (2) | 2 dados ≤ 3 | O inimigo tira **2 dados a menos** na próxima mão (mínimo 2). Ósmio continua saindo. | próxima mão dele | 1× por luta |
| D5 | **Freezer da Vó** | 1×2 | qualquer dado | Bloqueio = valor. O dado **não vai para o descarte**: entra **congelado** na sua próxima mão, com o mesmo valor e sem rolar, **além** da mão normal. Um dado congelado por vez. | até a sua próxima mão | sempre |
| D6 | **Reciclagem** | Reta 4 | um 1 | No fim deste turno, **cada dado que sobrou na mão vira bloqueio = valor**. Urânio reciclado **não envenena**. É o seguro contra o turno em branco. | neste turno | sempre |
| D7 | **Capa de Hélio** | 1×1 | dado par | Bloqueio = valor ×2. **3 dados aleatórios da sua bolsa** ficam imunes a efeitos do inimigo, como se fossem Hélio (mantêm o próprio elemento). Responde ao Porteiro, à Alquimista e a todas as ofensivas acima. | nesta luta | 1× por luta |
| D8 | **Cada Um no Seu Quadrado** | Xadrez (3) | `distinct` ×3 | Bloqueio = maior valor. Na próxima mão do inimigo, **dados repetidos rolam de novo** até não sobrar valor repetido (no máximo 10 tentativas por dado). Sem pares, sem Bola de Fogo, sem Transfusão. | próxima mão dele | sempre |
| D9 | **Rachar a Conta** | U (5) | 2 dados ímpares | Na próxima mão do inimigo, **todos os dados valem a média** da mão (arredonda para baixo): 24, 1, 1, 1, 1 vira 5, 5, 5, 5, 5. Acaba com os picos, mas dá pares para ele. | próxima mão dele | 1× por luta |
| D10 | **Dado Dublê** | 1×1 | um 6 | O **próximo golpe** que você receber causa dano igual ao **menor dado da mão de quem atacou**, em vez do dano normal. | até o início do seu próximo turno | 1× por luta |

**Notas de design**
- **D1, D3, D9 e O4** agem **depois que o inimigo rola e antes de ele alocar**. Para o jogador humano isso aparece como um selo na mão dele (como o Chumbo do Porteiro); para a IA, os valores já chegam alterados.
- **Freezer da Vó** é a única que aumenta a mão sem ser o Assassino. Se ficar forte demais, passa a "1× por luta" ou o dado congelado passa a contar dentro da mão normal.
- **Reciclagem + Urânio** forma uma build própria: muito valor alto, sem medo de sobrar.
- **Dado Dublê** é uma Esquiva parcial que piora contra o Assassino (mão de 6, menor dado provavelmente baixo) e é ótima contra mãos infladas. A Inflação (O5) do inimigo aumenta o menor dado dele, então o Dublê protege menos contra ela.

---

## 3. Combos que o desenho permite (e que o simulador deve medir)

| Combo | O que acontece | Risco |
|---|---|---|
| Ctrl+C Ctrl+V + Bola de Fogo | fabrica o par de 12 → 72 de dano + queima | baixo: a Bola continua 1× por luta, e o truque gasta um dado |
| Golpe do Pix + Pipoca | o adesivo roubado cai na face máxima → estoura mais alto | limite de 5 estouros |
| Inflação (dele) + Dado Dublê (seu) | ele infla a própria mão → o menor dado dele sobe → o Dublê protege menos | interação desejada |
| Ímpar ou Par + Inflação | os 1 viram 4 → ele perde o Espelho | dois turnos de setup |
| Radiação + Algema | 2 dados a menos e o resto é Urânio → ele quase não consegue usar tudo | os dois 1× por luta |
| Reset de Fábrica vs. Mestre de andar 20 (Alquimista) | não protege; a troca dela é regra de Mestre, não efeito de dado | escrever no cartão |

---

## 4. Impacto no motor (para quando for implementar)

- `Spells.DATA`: novos `req` (`min`, `odd`, `even`, `max_n`, `distinct`, `top`) em `accepts_partial`; novos `fx`; formatos novos são só listas de `Vector2i`, e as peças com buraco já funcionam porque o inventário trabalha por casas.
- `Fighter`: uma lista `hand_mods` ("próxima mão dele"), aplicada em `Resolver.draw_and_roll` logo depois de `roll_hand`; uma camada de luta em `Die` (`fight_element`, `fight_stickers`) limpa em `reset_fight_state`; `frozen` (Freezer), `stand_in` (Dublê).
- **Truque:** `TurnChoice` ganha uma alocação "truque → dado-alvo"; `validate` aplica os truques antes de checar as outras magias.
- **Rolar no meio da resolução** (Tigrinho, Pipoca, Cada Um no Seu Quadrado) usa o `rng` do `Duel`, para o simulador continuar determinístico.
- **Eventos novos** para a tela de duelo animar: `reroll`, `explode`, `jackpot`, `steal_sticker`, `hand_mod` (com o tipo: virado, inflado, taxado, algemado, rachado…), `frozen`, `recycle`.
- **IA:** a IA cautelosa precisa saber avaliar "próxima mão dele"; no início dá para tratar essas magias como "lançar se sobrar o dado certo".
- Textos em `data/texts_pt_br.json` (`spells` e `spell_fx`).
