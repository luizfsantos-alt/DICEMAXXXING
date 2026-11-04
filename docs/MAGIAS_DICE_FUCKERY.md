# Magias de "dice-fuckery" (proposta)

> **Status: proposta, nada implementado.** São 10 magias ofensivas e 10 defensivas que mexem **temporariamente** no valor e nas características dos dados (face, adesivo, elemento, quantidade na mão). Os números são *(iniciais)* e devem passar pelo simulador. Nomes e falas seguem o tom de `docs/TOM.md` (disputa de ego entre magos). Formato, exigência, efeito e uso seguem o padrão de `docs/SPEC_v3.md` §5.

---

## Feedback (rodada 1)

Respostas completas em `docs/MAGIAS_DICE_FUCKERY_opinioes.xlsx`.

| Veredito | Magias |
|---|---|
| **Manter** | Bis!, Roubar a Cena, Matemática Superior, Interrupção Rude, Pose Congelada, Improviso Brilhante |
| **Ajustar** | **Plágio**: rouba 1 adesivo de um dado da bolsa do inimigo e cola na face usada; o dano usa o valor novo; se o inimigo não tiver adesivo, dano = dado. **Imitação Barata**: recebe 1 dado no slot e devolve 2 dados iguais a ele para a mão (deixa de ser Truque). **Expectativa Tóxica**: o veneno que o inimigo sofre não compensa o dano que você toma no turno dele. **Meia Verdade**: precisa pedir um dado específico, para haver counterplay. **Imune a Críticas**: em vez de 3 dados imunes, você fica imune a 1 efeito aplicado. |
| **Cortar** | Lance de Gênio, Refutação, Ego Inflado, Crítica Pesada (nota: "soma ×3, 3 dados inimigos"), Taxa de Humildade, Diploma Cassado, Originalidade Obrigatória, Mediocridade, Dublê, **regra Truque** |
| **Regras mantidas** | Peças com buraco, exigências novas, inimigos usam as magias, tom de duelo de egos. **As falas não aparecem na luta.** |

**Diretrizes que saíram do feedback** (valem para as próximas propostas):
1. **Tudo passa por dado posto em slot.** Nada de efeito que mexe em outro dado da mão sem passar por um buraco. Uma magia pode **devolver dados para a mão** (como a nova Imitação Barata).
2. **O que você ganha é calculado na hora de lançar.** Nada de bloqueio ou dano que só se descobre no turno do inimigo (por isso a Taxa de Humildade saiu). Mexer na próxima mão dele é aceitável, se o efeito for simples (Interrupção Rude, Roubar a Cena).
3. **Exigência específica cria counterplay.** Um efeito forte precisa pedir um dado específico.
4. **Sorte pura não diverte** (Lance de Gênio). Rolar de novo funciona quando o jogador controla a chance (o Bis! pede a face máxima).
5. **Efeito pouco intuitivo não paga formato grande** (Mediocridade).
6. **Não pode atrapalhar mais quem lança do que o alvo** (Originalidade Obrigatória, Ego Inflado).

---

## 0. Regras de apoio

### 0.1 Durações (sempre escritas no cartão)

| Etiqueta | Dura até |
|---|---|
| **neste turno** | o fim do seu turno |
| **próxima mão dele** | o fim do próximo turno do inimigo (depois que ele rola) |
| **nesta luta** | o fim da luta; tudo volta ao normal na tela de recompensa |

Nada aqui é permanente. A bolsa salva (`SaveGame`) nunca guarda efeito temporário.

### 0.2 Truque ⚡ (cortado no feedback: fica só como registro)

Um **Truque** resolve **na hora da alocação**, não na resolução: o dado que paga o truque é consumido e o efeito cai num **outro dado que ficou na mão**, que pode alimentar outra magia no mesmo turno. Tudo continua reversível até "Terminar turno": tirar o dado do truque desfaz o efeito e solta o que dependia dele. A regra "cada dado alimenta uma magia" continua valendo, porque o dado que paga o truque não alimenta mais nada.

### 0.3 Hélio, Ósmio e Chumbo

- **Hélio** (imune a efeitos do inimigo) fica valioso: todo efeito "na mão dele" ou "na bolsa dele" abaixo **pula dados de Hélio**.
- **Ósmio** "não pode ser roubado" (§4.1): vale para o Plágio e a Roubar a Cena.
- **Chumbo**: faces travadas não aceitam adesivo, nem roubado.

### 0.4 Os inimigos também compram estas magias

Como o inimigo monta o inventário com as mesmas regras, **o jogador também vai sofrer tudo isto**. Isso dá valor ao Hélio, à Imune a Críticas e ao Diploma Cassado, e torna a ficha do inimigo (inventário visível) ainda mais importante.

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
| O1 | **Lance de Gênio** | 1×1 | qualquer dado | Rola o **mesmo dado** de novo. Se repetir o valor: **GENIAL**, dano = valor ×6. Se não: dano = valor novo. | neste turno | sempre |
| O2 | **Bis!** | 3×1 | `top` (MÁX) | Dano = valor. Rola o dado de novo e **soma enquanto sair a face máxima** dele (no máximo 5 bis). | neste turno | sempre |
| O3 | **Plágio** | 1×2 | dado ≤ 2 | Rouba **1 adesivo ×2** do dado mais adesivado da bolsa do inimigo e o cola na face que você rolou. Dano = valor novo. | nesta luta (o adesivo volta) | 1× por luta |
| O4 | **Refutação** | Z | dado par | Dano = valor. Na próxima mão do inimigo, **cada dado mostra a face oposta** à que rolou (posição 1↔6, 2↔5, 3↔4; os adesivos vão junto, então o 24 dele vira o 1 do outro lado). | próxima mão dele | 1× por luta |
| O5 | **Ego Inflado** | 1×1 | `min` ≥ 4 | Dano = valor. Próxima mão do inimigo: **+3 em todos os dados**. Ele bate mais, mas perde Escudo (≤ 3), Esquiva (≤ 2), Espelho e Sacrifício (= 1). | próxima mão dele | sempre |
| O6 | **Crítica Pesada** | L (3 casas) | 2 dados ≤ 2 | Dano = soma ×2. **2 dados aleatórios da bolsa do inimigo viram Chumbo** (faces 1, 1, 1 travadas; o resto não muda). | nesta luta | 1× por luta |
| O7 | **Roubar a Cena** | 1×1 | um 2 | No próximo turno do inimigo, depois que ele rola, o **maior dado dele sai da mão dele** e entra na **sua** próxima mão com o mesmo valor (sem rolar). Depois volta para a bolsa dele. | próxima mão dele + sua próxima mão | 1× por luta |
| O8 | **Imitação Barata** ⚡ | 2×1 | qualquer dado | **Truque.** Toque num dado da mão: ele vira **cópia exata** deste (valor e elemento). Fabrica pares para Bola de Fogo e Transfusão, ou duplica um 24. Copiar Urânio também copia o veneno. | neste turno | sempre |
| O9 | **Expectativa Tóxica** | T | `min` ≥ 5 | Dano = valor. **Todos os dados da próxima mão do inimigo viram Urânio** (mantêm o valor): o que ele não usar o envenena (+2 cada). | próxima mão dele | 1× por luta |
| O10 | **Matemática Superior** | Cruz (5) | 3 dados ≤ 4 | Dano = **produto** dos três (4 × 4 × 4 = 64). Dados baixos e adesivos pequenos (um 2 com ×2 vale 4) viram arma. | — | 1× por luta |

**Notas de design**
- **Lance de Gênio e Bis!** são as magias de **exibição**: rolar no meio da resolução, com animação própria (o dado gira de novo no cartão). O valor esperado do Lance de Gênio (≈ 2× o valor) passa pelo simulador antes de fixar o ×6.
- **Bis!** combina com edição de face: um dado editado para 6, 6, 6, 6, 1, 1 ganha bis com frequência. Por isso o limite de 5.
- **Refutação** contra **Chumbo** (1, 1, 1, 2, 2, 3) dá 3, 2, 2, 1, 1, 1: a mesma distribuição. Chumbo é imune "de graça", e é engraçado que seja assim.
- **Ego Inflado** é de dois gumes: serve para travar Feiticeiros defensivos, mas aumenta o dano que você vai receber.
- **Crítica Pesada e Plágio** atacam **a build** do inimigo, não a vida dele. São as respostas a inimigos de andares altos, cheios de adesivos.

---

## 2. Defensivas

| # | Magia | Formato | Pede | Efeito | Duração | Uso |
|---|---|---|---|---|---|---|
| D1 | **Taxa de Humildade** | 2×1 | um 4 | No próximo turno do inimigo, o **maior dado dele é taxado**: passa a valer 1, e você ganha **bloqueio = a diferença** (um 24 vira 1 e você ganha 23 de bloqueio). | próxima mão dele | 1× por luta |
| D2 | **Diploma Cassado** | 2×2 | `seq3` | Próxima mão do inimigo: **sem adesivos e sem elementos**, só a face crua. Sem queima de Sódio, sem ×3 de Hidrogênio, sem cópia de Mercúrio. Disputa a sequência com o Meteoro. | próxima mão dele | 1× por luta |
| D3 | **Meia Verdade** | 1×1 | qualquer dado | Os dados da próxima mão do inimigo com a **mesma paridade** deste **viram 1**. Cuidado: 1 alimenta o Espelho e o Sacrifício dele. | próxima mão dele | 1× por luta |
| D4 | **Interrupção Rude** | Diagonal (2) | 2 dados ≤ 3 | O inimigo tira **2 dados a menos** na próxima mão (mínimo 2). Ósmio continua saindo. | próxima mão dele | 1× por luta |
| D5 | **Pose Congelada** | 1×2 | qualquer dado | Bloqueio = valor. O dado **não vai para o descarte**: entra **congelado** na sua próxima mão, com o mesmo valor e sem rolar, **além** da mão normal. Um dado congelado por vez. | até a sua próxima mão | sempre |
| D6 | **Improviso Brilhante** | Reta 4 | um 1 | No fim deste turno, **cada dado que sobrou na mão vira bloqueio = valor**. Urânio reciclado **não envenena**. É o seguro contra o turno em branco. | neste turno | sempre |
| D7 | **Imune a Críticas** | 1×1 | dado par | Bloqueio = valor ×2. **3 dados aleatórios da sua bolsa** ficam imunes a efeitos do inimigo, como se fossem Hélio (mantêm o próprio elemento). Responde ao Porteiro, à Alquimista e a todas as ofensivas acima. | nesta luta | 1× por luta |
| D8 | **Originalidade Obrigatória** | Xadrez (3) | `distinct` ×3 | Bloqueio = maior valor. Na próxima mão do inimigo, **dados repetidos rolam de novo** até não sobrar valor repetido (no máximo 10 tentativas por dado). Sem pares, sem Bola de Fogo, sem Transfusão. | próxima mão dele | sempre |
| D9 | **Mediocridade** | U (5) | 2 dados ímpares | Na próxima mão do inimigo, **todos os dados valem a média** da mão (arredonda para baixo): 24, 1, 1, 1, 1 vira 5, 5, 5, 5, 5. Acaba com os picos, mas dá pares para ele. | próxima mão dele | 1× por luta |
| D10 | **Dublê** | 1×1 | um 6 | O **próximo golpe** que você receber causa dano igual ao **menor dado da mão de quem atacou**, em vez do dano normal. | até o início do seu próximo turno | 1× por luta |

**Notas de design**
- **D1, D3, D9 e O4** agem **depois que o inimigo rola e antes de ele alocar**. Para o jogador humano isso aparece como um selo na mão dele (como o Chumbo do Porteiro); para a IA, os valores já chegam alterados.
- **Pose Congelada** é a única que aumenta a mão sem ser o Assassino. Se ficar forte demais, passa a "1× por luta" ou o dado congelado passa a contar dentro da mão normal.
- **Improviso Brilhante + Urânio** forma uma build própria: muito valor alto, sem medo de sobrar.
- **Dublê** é uma Esquiva parcial que piora contra o Assassino (mão de 6, menor dado provavelmente baixo) e é ótima contra mãos infladas. A Ego Inflado (O5) do inimigo aumenta o menor dado dele, então o Dublê protege menos contra ela.

## 2.1 Falas (o que o mago diz ao lançar)

Uma fala curta por magia, para o balão do retrato na tela de duelo. Servem para o jogador e para o inimigo.

| Magia | Fala |
|---|---|
| Lance de Gênio | "Sorte? Eu chamo de método." |
| Bis! | "Eles pedem mais. Sempre pedem." |
| Plágio | "Inspiração. A palavra é inspiração." |
| Refutação | "Tudo o que você disse, ao contrário, é verdade." |
| Ego Inflado | "Vai, se ache. Se ache bastante." |
| Crítica Pesada | "Li o seu grimório. Que pena." |
| Roubar a Cena | "Obrigado, obrigado. Não precisam aplaudir." |
| Imitação Barata | "Fiz igual. Só que melhor." |
| Expectativa Tóxica | "Todos esperam muito de você. Coitado." |
| Matemática Superior | "Você soma. Eu multiplico." |
| Taxa de Humildade | "Isso aí vale menos do que você pensa." |
| Diploma Cassado | "Onde você estudou mesmo?" |
| Meia Verdade | "Metade do que você faz não conta." |
| Interrupção Rude | "Desculpe, você estava falando?" |
| Pose Congelada | "Segura essa pose. Ficou ótima." |
| Improviso Brilhante | "Eu nem tinha preparado nada." |
| Imune a Críticas | "Não li, mas discordo." |
| Originalidade Obrigatória | "Repetiu? Que falta de criatividade." |
| Mediocridade | "Aqui ninguém é especial. Principalmente você." |
| Dublê | "Aquele não era eu." |

---

## 3. Combos que o desenho permite (e que o simulador deve medir)

| Combo | O que acontece | Risco |
|---|---|---|
| Imitação Barata + Bola de Fogo | fabrica o par de 12 → 72 de dano + queima | baixo: a Bola continua 1× por luta, e o truque gasta um dado |
| Plágio + Bis! | o adesivo roubado cai na face máxima → cada bis vale mais | limite de 5 bis |
| Ego Inflado (dele) + Dublê (seu) | ele infla a própria mão → o menor dado dele sobe → o Dublê protege menos | interação desejada |
| Meia Verdade + Ego Inflado | os 1 viram 4 → ele perde o Espelho | dois turnos de setup |
| Expectativa Tóxica + Interrupção Rude | 2 dados a menos e o resto é Urânio → ele quase não consegue usar tudo | os dois 1× por luta |
| Diploma Cassado vs. Mestre de andar 20 (Alquimista) | não protege; a troca dela é regra de Mestre, não efeito de dado | escrever no cartão |

---

## 4. Impacto no motor (para quando for implementar)

- `Spells.DATA`: novos `req` (`min`, `odd`, `even`, `max_n`, `distinct`, `top`) em `accepts_partial`; novos `fx`; formatos novos são só listas de `Vector2i`, e as peças com buraco já funcionam porque o inventário trabalha por casas.
- `Fighter`: uma lista `hand_mods` ("próxima mão dele"), aplicada em `Resolver.draw_and_roll` logo depois de `roll_hand`; uma camada de luta em `Die` (`fight_element`, `fight_stickers`) limpa em `reset_fight_state`; `frozen` (Freezer), `stand_in` (Dublê).
- **Truque:** `TurnChoice` ganha uma alocação "truque → dado-alvo"; `validate` aplica os truques antes de checar as outras magias.
- **Rolar no meio da resolução** (Lance de Gênio, Bis!, Originalidade Obrigatória) usa o `rng` do `Duel`, para o simulador continuar determinístico.
- **Eventos novos** para a tela de duelo animar: `reroll`, `encore` (bis), `genius` (genial), `steal_sticker`, `hand_mod` (com o tipo: refutado, inflado, taxado, interrompido, medíocre…), `frozen`, `recycle`.
- **IA:** a IA cautelosa precisa saber avaliar "próxima mão dele"; no início dá para tratar essas magias como "lançar se sobrar o dado certo".
- Textos em `data/texts_pt_br.json` (`spells` e `spell_fx`).
