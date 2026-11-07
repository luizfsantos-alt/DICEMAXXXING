# Catálogo de magias

> **Status: fonte da verdade e implementado.** Junta as magias da `docs/SPEC_v3.md` §5 com as aprovadas nas duas rodadas de proposta (`docs/MAGIAS_DICE_FUCKERY.md` e `docs/MAGIAS_FISICAS.md`, que passam a ser histórico), já com os ajustes do feedback. **Todas as 39 magias estão no jogo** (`engine/spells.gd`, ids na seção 9), mais 6 dos personagens novos (seção 10). Cada magia tem uma raridade (`docs/RARIDADE.md`). Números *(iniciais)*, a passar pelo simulador.

**58 magias** (39 + 6 dos personagens, seção 10, + 13 mexidas, seção 11). As 39 originais: 21 ofensivas e 18 defensivas. Vêm 12 da base, 11 da rodada 1 e 16 da rodada 2. 31 são retas e cabem no cinto do Assassino.

---

## 1. Princípios de design

Saíram das duas rodadas de feedback e valem para toda magia nova.

1. **A magia só usa os dados que estão nos slots agora.** Ela não lê a mão anterior do inimigo nem depende de um valor que só se descobre no turno dele. Ela **pode** deixar uma consequência simples para a próxima mão dele (menos dados, metade do valor, dado roubado). Exceções fora das magias: o elemento Mercúrio e a Alquimista leem a mão anterior.
2. **Tudo passa por dado posto em slot.** Não existe efeito que mexe em outro dado da mão sem passar por um buraco. Uma magia pode **devolver dados para a mão** ou **marcar** um dado para a próxima.
3. **Um dado que volta tem que voltar com certeza.** Mexer num dado da bolsa até o fim da luta vale pouco, porque ele pode não sair de novo. Fica reservado a efeitos muito fortes.
4. **O que diverte é fazer conta com a mão:** quebrar, fundir, multiplicar, golpear várias vezes, estourar na face máxima. O jogador deve conseguir calcular o resultado antes de "Terminar turno".
5. **Uma regra que vale para todos é melhor que uma regra que escolhe alvo.** Escreva "todos os dados", "efeitos negativos em geral". Evite "2 dados aleatórios".
6. **Sorte pura não diverte.** Rolar de novo só funciona quando o jogador controla a chance (o Bis! pede a face máxima).
7. **Magia forte se paga com formato e exigência**, não com "1× por luta": peça maior, exigência mais difícil.
8. **Enfraquecer o inimigo sempre reduz.** Nada aumenta os dados dele nem lhe dá pares.
9. **A magia não pode atrapalhar mais quem lança do que o alvo.**
10. **Efeito pouco intuitivo não paga formato grande.**
11. **Cada efeito tem uma forma só.** Veneno é sempre o veneno do Urânio; uma magia nova que causa dano depois diz "dano", não "veneno". Não use o nome de um efeito existente para um comportamento diferente.

---

## 2. Regras de apoio

### 2.1 Durações

| Etiqueta | Dura até |
|---|---|
| **neste turno** | o fim do seu turno |
| **próxima mão dele** | o fim do próximo turno do inimigo |
| **nesta luta** | o fim da luta; tudo volta ao normal na tela de recompensa |

Nada é permanente, salvo quando o cartão diz "para sempre" (Sacrifício, Transfusão). A bolsa salva nunca guarda efeito temporário.

**Uso:** **sempre**, **1× por luta** ou **2× por luta** (Suor de Campeão). Em todos os casos, no máximo 1 vez por turno.

### 2.2 Dados devolvidos para a mão

Imitação Barata e Força Desnecessária devolvem dados à bandeja **na hora em que o dado entra no buraco**. Os dados devolvidos são temporários e podem alimentar outras magias **neste turno**. Tirar o dado do buraco recolhe os devolvidos e solta as magias que eles alimentavam. No fim do turno, eles somem.

**Cópias não alimentam Imitação, Sacrifício nem Transfusão** (spec v3.1 §6). Isso acaba com a corrente de Imitações (6 → 12 → 24 → 48…), o Sacrifício sem perder dado e a vida máxima infinita. As cópias continuam servindo para qualquer outra magia (Bola de Fogo, Matemática Superior…). Valem também para as partes da Sangria (seção 11).

### 2.3 Marca para a próxima mão

Pose Congelada, Impulso Calculado, Recuo Estratégico e Concentrar Força **marcam** um dado. Ele não vai para o descarte: entra na sua próxima mão **além da mão normal**, com o valor que o cartão diz (o Impulso Calculado rola com +2 em todas as faces). **Uma marca por vez**: uma marca nova substitui a anterior.

### 2.4 Efeito negativo

É tudo o que o inimigo aplica em você e não é dano direto: veneno, queima, dado posto ou tirado da sua bolsa ou da sua mão, mão menor, valor alterado. Imune a Críticas anula o próximo; Suor de Campeão remove os que estão ativos.

### 2.5 Exigências

| No buraco | Significado |
|---|---|
| (vazio) | qualquer dado |
| "≤ 3", "≥ 4" | valor até / a partir de v |
| "3" | valor exato |
| "=" entre buracos | dados iguais |
| "→" entre buracos | sequência |
| "par" / "ímpar" | paridade |
| "MÁX" | o dado está na face mais alta que ele tem |
| "≤ 3" num dos buracos | n dados, e pelo menos um é ≤ v (Física Aplicada) |

**A exigência checa o valor rolado** (ou o valor da marca).

### 2.6 Formatos

As peças giram. As peças com buraco (**Diagonal**, **Cruz**) têm casas que não se tocam, e outra peça pode ocupar o vão. **No cinto 6×1 do Assassino só cabem as retas.**

```
Diagonal (2)  Diagonal (3)  L (3)   L (4)   T (4)   Cruz (5)   Reta 4
#.            #..           #.      #.      ###     .#.        ####
.#            .#.           ##      #.      .#.     ###
              ..#                   ##              .#.
```

### 2.7 Hélio, Ósmio e Chumbo

- **Hélio** é imune a efeitos do inimigo: todo efeito na mão ou na bolsa dele **pula dados de Hélio**.
- **Ósmio** não pode ser roubado nem arrancado.
- **Chumbo**: faces travadas não recebem adesivo, nem roubado.

### 2.8 Os inimigos usam o catálogo

O inimigo compra deste catálogo com as mesmas regras. Ele usa as magias do grupo do arquétipo dele e as marcadas como "qualquer".

---

## 3. Ofensivas

| # | Magia | Formato | Grupo | Pede | Efeito | Uso | Origem |
|---|---|---|---|---|---|---|---|
| 1 | **Faísca** | 1×1 | Feiticeiro | qualquer dado | Dano = valor. | sempre | base |
| 2 | **Estocada** | 1×1 | Assassino | qualquer dado | Dano = valor + 1. | sempre | base |
| 3 | **Corte Duplo** | 2×1 | Assassino | 2 dados | Dano = soma; se os dois forem ímpares, golpeia de novo. | sempre | base |
| 4 | **Bola de Fogo** | 2×2 | Feiticeiro | 2 dados iguais | Dano = soma ×2 e queima 3. | 1× por luta | base |
| 5 | **Meteoro** | L (4) | Feiticeiro | sequência de 3 | Dano = soma + 10. | 1× por luta | base |
| 6 | **Golpe nas Sombras** | 3×1 | Assassino | um 6 | Dano = valor, ignora todas as defesas: bloqueio, Esquiva, Espelho e Revide. | 1× por luta | base (planejada) |
| 7 | **Sacrifício** | 1×1 | Feiticeiro | um 1 | Destrói o dado para sempre; +5 de dano em todas as magias de dano nesta luta. | sempre | base |
| 8 | **Bis!** | 3×1 | Feiticeiro | dado na face MÁX | Dano = valor. Rola o dado de novo e soma enquanto sair a face máxima dele (até 5 vezes). | sempre | rodada 1 |
| 9 | **Plágio** | 1×2 | Feiticeiro | dado ≤ 2 | Rouba 1 adesivo ×2 do dado com mais adesivos da bolsa do inimigo e cola na face usada, até o fim da luta. Dano = valor novo. Se o inimigo não tiver adesivo: dano = valor. | 1× por luta | rodada 1 |
| 10 | **Roubar a Cena** | 1×1 | Feiticeiro | um 2 | O maior dado da próxima mão do inimigo sai da mão dele e entra na sua próxima mão com o mesmo valor. Depois volta para a bolsa dele. | 1× por luta | rodada 1 |
| 11 | **Imitação Barata** | 2×1 | Feiticeiro | qualquer dado | O dado entra no slot e voltam à mão 2 dados iguais a ele (valor e elemento), para outras magias neste turno. | sempre | rodada 1 |
| 12 | **Expectativa Tóxica** | T (4) | Feiticeiro | dado ≥ 5 | Dano = valor ×2. Na próxima mão do inimigo, cada dado que ele não usar causa 2 de dano nele. | 1× por luta | rodada 1 |
| 13 | **Matemática Superior** | Cruz (5) | Feiticeiro | 3 dados ≤ 4 | Dano = produto dos três (4 × 4 × 4 = 64). | 1× por luta | rodada 1 |
| 14 | **Força Desnecessária** | 1×1 | Assassino | dado ≥ 4 | Dano = valor. O dado se parte: voltam à mão 2 dados com metade do valor cada (arredonda para cima), para outras magias neste turno. | sempre | rodada 2 |
| 15 | **Física Aplicada** | 3×1 | Assassino | 2 dados, um ≤ 3 | Dano = maior × menor (12 × 3 = 36). | sempre | rodada 2 |
| 16 | **Arrancar das Mãos** | 1×2 | Assassino | dado ≤ 2 | Dano = valor. O dado mais forte da bolsa do inimigo (maior soma de faces) fica fora da bolsa dele até o fim da luta. Ósmio não sai. | 1× por luta | rodada 2 |
| 17 | **Exibição de Velocidade** | 3×1 | Assassino | 3 dados ≤ 3 | 3 golpes separados, cada um = valor ×2. Esquiva e Espelho só param o primeiro. Se os 3 forem iguais: 6 golpes. | sempre | rodada 2 |
| 18 | **Levantar Peso** | 1×1 | Assassino | um 1 | Dano = 4 × quantos dados de valor 1 há na sua mão (contando este). | sempre | rodada 2 |
| 19 | **Impulso Calculado** | 1×2 | Assassino | qualquer dado | Dano = valor. O dado volta obrigatoriamente na sua próxima mão, além da mão normal, com +2 em todas as faces, e é rolado. O +2 dura essa mão. | sempre | rodada 2 |
| 20 | **Lição de Anatomia** | L (3) | Assassino | 2 dados iguais | Dano = soma ×2. Na próxima mão do inimigo, todo dado que cair na face mais alta vale 1. | 1× por luta | rodada 2 |
| 21 | **Golpe para a Foto** | Reta 4 | Assassino | 4 dados ≥ 5 | Dano = o maior dado × 4 (um 24 dá 96). | 1× por luta | rodada 2 |

## 4. Defensivas

| # | Magia | Formato | Grupo | Pede | Efeito | Uso | Origem |
|---|---|---|---|---|---|---|---|
| 22 | **Escudo Arcano** | 1×2 | Feiticeiro | dado ≤ 3 | Bloqueio = valor ×3. | sempre | base |
| 23 | **Esquiva** | 1×1 | Assassino | dado ≤ 2 | Anula o próximo golpe do inimigo. | 1× por luta | base |
| 24 | **Espelho** | 1×1 | Feiticeiro | um 1 | Reflete o próximo golpe recebido. | sempre | base |
| 25 | **Remendo** | 1×1 | qualquer | qualquer dado | Cura = valor. | 1× por luta | base |
| 26 | **Transfusão** | 2×1 | Feiticeiro | 2 dados iguais | + valor de um deles na vida máxima, para sempre. | 1× por luta | base |
| 27 | **Meia Verdade** | 1×1 | Feiticeiro | um 6 | Na próxima mão do inimigo, todos os dados de valor par viram 1. | 1× por luta | rodada 1 |
| 28 | **Interrupção Rude** | Diagonal (2) | Feiticeiro | 2 dados ≤ 3 | O inimigo tira 2 dados a menos na próxima mão (mínimo 2). | 1× por luta | rodada 1 |
| 29 | **Pose Congelada** | 1×2 | Feiticeiro | qualquer dado | Bloqueio = valor. O dado fica marcado: entra na sua próxima mão com o mesmo valor, sem rolar. | sempre | rodada 1 |
| 30 | **Improviso Brilhante** | Reta 4 | Feiticeiro | um 1 | No fim deste turno, cada dado que sobrou na mão vira bloqueio = valor. Urânio que sobrou não envenena. | sempre | rodada 1 |
| 31 | **Imune a Críticas** | 1×1 | Feiticeiro | dado par | Bloqueio = valor ×2. O próximo efeito negativo que o inimigo aplicar em você é anulado. | 1× por luta | rodada 1 |
| 32 | **Revide Elegante** | 2×1 | Assassino | dado ≤ 3 | Bloqueio = valor ×2. Cada golpe que acertar você enquanto este bloqueio existir devolve dano = valor ao atacante. | sempre | rodada 2 |
| 33 | **Chave de Braço Didática** | 1×1 | Assassino | um 3 | Na próxima mão do inimigo, todos os dados valem metade (arredonda para baixo, mínimo 1). | 1× por luta | rodada 2 |
| 34 | **Rasteira Humilhante** | Diagonal (3) | Assassino | 2 dados ≤ 2 | Bloqueio = soma ×2. O inimigo tira 1 dado a menos na próxima mão. | sempre | rodada 2 |
| 35 | **Suor de Campeão** | 1×1 | Assassino | dado ímpar | Remove todos os efeitos negativos em você. Bloqueio = valor. | 2× por luta | rodada 2 |
| 36 | **Armadura de Músculo** | 2×1 | Assassino | 2 dados ≤ 3 | Bloqueio = produto ×2 (3 × 3 × 2 = 18). | sempre | rodada 2 |
| 37 | **Recuo Estratégico** | 1×1 | Assassino | dado ≤ 2 | Anula o próximo golpe. O dado fica marcado: entra na sua próxima mão valendo 6, sem rolar. | 1× por luta | rodada 2 |
| 38 | **Presença Imponente** | 1×2 | Assassino | um 6 | Bloqueio = 3 × quantos dados você tem na mão agora (contando os postos e os devolvidos). | sempre | rodada 2 |
| 39 | **Concentrar Força** | L (3) | Assassino | 2 dados iguais | Bloqueio = soma. Os dois dados se fundem: um dado marcado entra na sua próxima mão valendo a soma, sem rolar. | sempre | rodada 2 |

---

## 5. O que mudou em relação às propostas

| Magia | Mudança |
|---|---|
| Bola de Fogo | ×2 (era ×3). Já aplicado no jogo. |
| Meteoro | Era 40 fixo. Já aplicado no jogo. |
| Golpe nas Sombras | Ignora todas as defesas, não só o bloqueio. Ainda não implementada. |
| Plágio | Texto do feedback; sem adesivo, dano = dado. |
| Imitação Barata | Deixou de ser Truque: agora é dado no slot e 2 cópias na mão. |
| Expectativa Tóxica | Dano dobrado agora; os dados parados causam dano, não veneno (cada efeito tem uma forma só). |
| Física Aplicada | Peça maior: de 2×1 para 3×1. |
| Levantar Peso | Nome: era Levantar Peso Morto. |
| Impulso Calculado | Antes voltava com valor +2 fixo; agora +2 em todas as faces e volta com certeza. |
| Lição de Anatomia | Simplificada: sem dados aleatórios da bolsa, efeito só na próxima mão. |
| Golpe para a Foto | Exigência mais difícil: todos os dados ≥ 5. |
| Meia Verdade | Pede um dado específico (um 6) e a paridade fica fixa: par. |
| Imune a Críticas | Antes: 3 dados imunes. Agora: imunidade a 1 efeito. |
| Revide Elegante | Devolve valor simples (era ×2). |
| Chave de Braço Didática | Todos os dados, não só o maior. |
| Rasteira Humilhante | Peça maior: Diagonal de 3 casas. |
| Suor de Campeão | Simplificada: efeitos negativos em geral. 2× por luta (era sempre). |

**Cortadas:** Lance de Gênio, Refutação, Ego Inflado, Crítica Pesada, Taxa de Humildade, Diploma Cassado, Originalidade Obrigatória, Mediocridade, Dublê, Combo Ensaiado, Elegância Marcial, Calo de Orgulho, Agarrão Técnico. **Regras cortadas:** Truque, ordem do inventário como mecânica de magia, exigência "igual a um dado da mão anterior dele".

---

## 6. Decisões da rodada 3

| Tema | Decisão |
|---|---|
| Mão anterior do inimigo | Fica como **exceção** no Mercúrio e na Alquimista (Mestre do andar 20). Nenhuma magia lê a mão anterior. |
| Uma marca por vez | Mantida: as quatro magias de marca disputam a mesma marca. |
| Suor de Campeão | Passa a 2× por luta. |
| Interrupção Rude x Rasteira | Os formatos estão coerentes. |
| Golpe para a Foto | Exigência corrigida para 4 dados ≥ 5. |

## 7. Em aberto

| Tema | Situação |
|---|---|
| Tirar a ordem de resolução | Fica para uma conversa própria, com mais atenção. Até lá, as magias acontecem na ordem do inventário, como hoje. Precisa de regra para: morte no meio do turno, bloqueio antes ou depois do dano, Sacrifício (+5 vale para as magias do mesmo turno?). |

---

## 8. Combos para o simulador medir primeiro

| Combo | Por quê |
|---|---|
| Força Desnecessária → Física Aplicada / Exibição de Velocidade / Armadura de Músculo | Um dado alto vira dados baixos que pagam várias exigências ≤ 3; tudo "sempre" e reto. É o candidato mais forte do Assassino. |
| Imitação Barata → Bola de Fogo ou Transfusão | Fabrica o par na hora. |
| Bola de Fogo ×2 e Meteoro soma + 10 | Feiticeiro ficou mais fraco no pico: o simulador deve medir se a fatia continua vencível. |
| Concentrar Força → Golpe para a Foto | A fusão é o caminho mais fácil para um dado alto, sem adesivos. |
| Levantar Peso contra o Porteiro de Chumbo | O Chumbo dele vira dano. |
| Suor de Campeão contra o Reator | Mesmo 2× por luta, pode aliviar muito o Mestre do andar 30. |
| Chave de Braço Didática + Meia Verdade | Os dados pares viram 1 e o resto vale metade: uma mão inteira quase inútil. |

---

## 9. Implementação

Todas as magias estão em `engine/spells.gd` (dados), `engine/resolver.gd` (efeitos), `engine/turn_choice.gd` (dados devolvidos) e `engine/fighter.gd` (marca, mexidas, dados fora da luta). Testes em `tests/test_magias.gd`.

| id | Magia | id | Magia |
|---|---|---|---|
| `sombras` | Golpe nas Sombras | `forca` | Força Desnecessária |
| `bis` | Bis! | `fisica` | Física Aplicada |
| `plagio` | Plágio | `arrancar` | Arrancar das Mãos |
| `roubar_cena` | Roubar a Cena | `velocidade` | Exibição de Velocidade |
| `imitacao` | Imitação Barata | `peso` | Levantar Peso |
| `expectativa` | Expectativa Tóxica | `impulso` | Impulso Calculado |
| `matematica` | Matemática Superior | `anatomia` | Lição de Anatomia |
| `meia_verdade` | Meia Verdade | `foto` | Golpe para a Foto |
| `interrupcao` | Interrupção Rude | `revide` | Revide Elegante |
| `pose` | Pose Congelada | `chave` | Chave de Braço Didática |
| `improviso` | Improviso Brilhante | `rasteira` | Rasteira Humilhante |
| `imune` | Imune a Críticas | `suor` | Suor de Campeão |
| | | `armadura` | Armadura de Músculo |
| | | `recuo` | Recuo Estratégico |
| | | `presenca` | Presença Imponente |
| | | `concentrar` | Concentrar Força |

### 9.1 Decisões tomadas na implementação (revisar depois de jogar)

- **Bis!** sempre rola o dado de novo uma vez e soma; se sair a face máxima, rola e soma de novo (até 5 vezes).
- **Força Desnecessária**: as duas metades são dados comuns (sem o elemento do original). **Imitação Barata** copia o elemento.
- **Dados devolvidos e marcados** valem como dados da mão para Presença Imponente e Levantar Peso. Um dado marcado nunca está na face máxima.
- **Mexidas na próxima mão do inimigo**, sempre nesta ordem: dados a menos (somam: Interrupção Rude + Rasteira = −3), face máxima vira 1, pares viram 1, metade, roubar o maior.
- **Roubar a Cena** não rouba Ósmio. O dado roubado volta para o descarte do inimigo.
- **Arrancar das Mãos** escolhe entre os dados que estão na bolsa ou no descarte do inimigo (a mão dele está vazia no seu turno).
- **Plágio** não rouba de Ósmio e não cola em face de Chumbo nem em dado marcado.
- **Efeitos negativos** que Imune a Críticas anula: queima (Bola de Fogo, Sódio), mexidas na próxima mão, Arrancar das Mãos, Plágio, o Chumbo do Porteiro e o do Lixeiro. **Suor de Campeão** remove veneno, queima e as mexidas pendentes; não devolve dados arrancados nem adesivos roubados.
- **Nível (Escola)**: o efeito vezes 1 / 1,5 / 2 nos níveis 1 / 2 / 3 (arredondado para cima). As magias sem número também crescem:
  - **Espelho** devolve o golpe ×1,5 / ×2.
  - **Esquivas** (e o Recuo) transformam o golpe anulado em bloqueio: metade no nível 2, todo no 3.
  - **Improviso Brilhante**: o bloqueio das sobras ×1,5 / ×2.
  - **Imitação Barata**: as cópias valem ×1,5 / ×2.
  - **Mexidas** (Roubar a Cena, Meia Verdade, Interrupção Rude, Chave de Braço) também causam dano = valor no nível 2 e valor ×2 no 3.
- **Revide Elegante**: vale enquanto houver bloqueio no começo do golpe; o revide não é refletido nem revidado.
- **Hélio** ainda não existe no jogo; quando entrar, os efeitos acima devem pular dados de Hélio.
- **Loja e Escola** oferecem todas as magias ao jogador. **Inimigos** só compram do próprio grupo (Feiticeiro ou Assassino) e as de "qualquer".

---

## 10. Magias dos personagens novos (implementadas)

Vieram de `docs/PERSONAGENS.md`. Todas entram na Loja, na Escola e nas recompensas para qualquer personagem.

| id | Magia | Formato | Grupo | Pede | Efeito | Uso | Raridade |
|---|---|---|---|---|---|---|---|
| `dardo` | **Dardo Arcano** | 1×1 | qualquer | dado par | Dano = valor + 2. | sempre | Comum |
| `obra` | **Obra-Prima** | L (4) | Perfeccionista | 3 dados iguais (trio) | Dano = soma ×2. | sempre | Incomum |
| `mordida` | **Mordida** | 1×1 | Vampiro | qualquer dado | Dano = valor; cura metade (arredonda para cima). | sempre | Comum |
| `banquete` | **Banquete** | Reta 3 | Vampiro | 3 dados quaisquer | Dano = soma; cura = o menor dos três. | sempre | Incomum |
| `machadada` | **Machadada** | 1×2 | Bárbaro | dado ≥ 4 | Dano = valor ×2. | sempre | Comum |
| `cerrar` | **Cerrar os Dentes** | 1×1 | Bárbaro | dado ≤ 3 | Cura = valor ×3. | 2× por luta | Comum |

- **Exigência nova "trio"**: 3 dados iguais; os buracos mostram "=" entre eles.
- A cura cresce com o nível, como o dano. A Fúria do Bárbaro e o Sacrifício somam em cada golpe.


---

## 11. Mexidas (implementadas)

Saíram da crítica de mecânicas (spec `docs/SPEC_v3.1.md` §1, hoje histórico). Uma **mexida** não age no inimigo: muda o valor dos seus dados **na alocação**, quando o buraco fica completo, e devolve o dado à mão para outra magia neste turno. O cartão sai do palco assim que resolve.

**Regras:**
- Um dado recebe **no máximo uma mexida por turno**; dados devolvidos (cópias, metades, partes da Sangria) contam como mexidos.
- **Mexer não é usar o dado:** Sódio e Amianto só reagem quando o dado é gasto numa magia que não é mexida; o Urânio mexido que fica parado envenena.
- **Rolar de novo** usa as faces do dado (com adesivos) e os efeitos de rolagem (Hidrogênio, Carbono, +2 do Impulso); o Mercúrio fica com a face, sem copiar.
- Dado que não rola (marcado, guardado, recebido) só aceita mexidas determinísticas.
- **Desfazer:** as determinísticas se desfazem até "Terminar turno" (tocar no dado mexido → "Desfazer"); as **aleatórias** (Segunda Chance, Tudo ou Nada) **são definitivas**.
- **Nível (Escola):** +1 / +2 no valor de cada dado devolvido. Exceções: Ajuste Fino ganha passo ±2 / ±3; Tudo ou Nada multiplica por 3 / 4; Lapidar faz a face virar 7 / 8.
- Os inimigos usam mexidas com as mesmas regras (busca gulosa; as aleatórias pela média das 6 faces).
- O dado mudado por qualquer coisa que não seja a rolagem mostra **o valor original riscado** e o **selo da causa** (também as mexidas do inimigo, a Alquimista, o Mercúrio, o Carbono e o Hidrogênio).

| id | Mexida | Formato | Grupo | Pede | Efeito | Uso | Raridade |
|---|---|---|---|---|---|---|---|
| `segunda` | **Segunda Chance** | 1×1 | Feiticeiro | dado que rola | Rola de novo e fica com o maior. | sempre | Comum |
| `ajuste` | **Ajuste Fino** | 1×1 | Assassino | qualquer dado | Dois buracos: +1 ou −1 (mínimo 1). | sempre | Comum |
| `pico` | **Pico** | 1×1 | qualquer | qualquer dado | O dado vai à face máxima (com adesivos). | 1× por luta | Comum |
| `sangria` | **Sangria** | 1×1 | qualquer | dado ≥ 3 | Divide em 3 partes iguais (7 → 3, 2, 2); o original é gasto. | sempre | Comum |
| `virar` | **Virar** | 1×1 | qualquer | dado ≤ 6 | 7 − valor (o Chumbo 1 vira 6). | sempre | Comum |
| `nivelar` | **Nivelar** | 2×1 | Assassino | 2 dados | Os dois viram a média, para cima. | sempre | Comum |
| `polarizar` | **Polarizar** | 1×1 | Assassino | qualquer dado | ≤ 3 vira 1; ≥ 4 vira 6. | sempre | Comum |
| `eco` | **Eco** | 2×1 | Assassino | 2 dados | O 2º vira igual ao 1º. | sempre | Incomum |
| `inflar` | **Inflar** | 1×1 | Feiticeiro | dado ≤ 3 | Vale o dobro. | sempre | Incomum |
| `juntar` | **Juntar Cacos** | 2×1 | Assassino | 2 dados | Volta um dado com a soma; o 2º é gasto. | sempre | Incomum |
| `escada` | **Escada** | L (3) | Feiticeiro | 3 dados | Sequência a partir do menor (2, 6, 6 → 2, 3, 4). | sempre | Incomum |
| `tudo_nada` | **Tudo ou Nada** | 1×2 | Feiticeiro | dado que rola | Rola de novo: novo valor ×2, seja qual for. | sempre | Rara |
| `lapidar` | **Lapidar** | 3×1 | qualquer | um 1 (dado da bolsa, face não travada) | A face vira 6 para sempre; o dado volta valendo 6. | 1× por luta | Rara |

**Mexidas iniciais:** Feiticeiro (Segunda Chance), Assassino (Ajuste Fino), Bárbaro (Pico), Vampiro (Sangria), Metalurgista (Virar). Copista, Perfeccionista e Minimalista ficam sem.

Implementação: `engine/spells.gd` (dados), `engine/turn_choice.gd` (resolução na alocação e desfazer), `engine/resolver.gd` (uso, Lapidar e evento `mod`), `engine/enemy_ai.gd` (busca), `ui/duel_screen.gd` e `ui/spell_card.gd` (animação, cartão saindo do palco, dois buracos do Ajuste Fino). Testes em `tests/test_mexidas.gd`.
