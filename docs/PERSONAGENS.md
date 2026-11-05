# Personagens novos (proposta)

> **Status: implementado** (rodada 6 aprovada). **Jogáveis: Minimalista, Vampiro e Bárbaro**; os outros aparecem como inimigos. Decisões de implementação e números do simulador na seção 8. São 6 arquétipos novos (os 5 da proposta mais o Bárbaro), além do Feiticeiro e do Assassino, que continuam, jogáveis e usados pelos inimigos, no padrão de `docs/SPEC_v3.md` §3: **formato do inventário**, **uma passiva**, vida, mão, bolsa inicial e magias iniciais. Seguem o tom de `docs/TOM.md` e os princípios de `docs/CATALOGO_MAGIAS.md` §1. Números *(iniciais)*, a passar pelo simulador.

---

## Feedback (rodada 1)

| Veredito | Personagens |
|---|---|
| **Manter** | Minimalista, Metalurgista, Perfeccionista |
| **Ajustar** | **Copista**: copia uma magia **aleatória** do inimigo que caiba, não a maior. Deixar espaço livre no inventário deve ser uma decisão séria, por isso a Mesa de Empréstimo saiu: a cópia vai para as casas livres da grade dele. |
| **Cortar** | **Populista** (com o Nitrogênio e o Abaixo-Assinado). No lugar: **Vampiro**, com magias de dano, cura e ganho de vida. |

## Feedback (rodada 2)

| Tema | Decisão |
|---|---|
| Faísca demais | Criar outra magia **básica**: **Dardo Arcano** (seção 3.1). Ela entra no lugar da 2ª Faísca do Minimalista e da Faísca do Perfeccionista. |
| Feiticeiro e Assassino | **Continuam** jogáveis, ao lado dos novos. |
| Elementos | "Não estão comuns o suficiente, ou não entendi como funcionam." Diagnóstico e proposta na seção 4. |
| Personagem novo | **Bárbaro**: cura a si mesmo e causa mais dano com pouca vida (seção 2.6). |

## Feedback (rodada 3)

| Tema | Decisão |
|---|---|
| Fúria | Só liga com **metade da vida ou menos** (50% de vida perdida). |
| Urânio do Bárbaro | Trocado por uma substância nova que **machuca quem usa**: **Amianto** (seção 3.2). O Urânio continua no jogo. |
| Ósmio | Pergunta: o que faz? Resposta na seção 5.1. |

## Feedback (rodada 4)

| Tema | Decisão |
|---|---|
| Ácido | Nome ruim: vira **Amianto**, com o mesmo efeito. As decisões (o dano a si mesmo não é golpe; à venda para todos) foram aprovadas. |
| Raridade | Falta classe de raridade para magias e dados: proposta em `docs/RARIDADE.md`. |

## Feedback (rodada 5)

| Tema | Decisão |
|---|---|
| Ósmio | Deve sair **em toda mão**, não só na primeira. Fica forte: sobe para **Raro** (`docs/RARIDADE.md`). |
| Raridade | Respostas em `docs/RARIDADE.md` §8. |

## Feedback (rodada 6)

*(Em branco.)*

---

## 0. Como estes personagens foram pensados

### 0.1 A ideia

O arquétipo pesa muito no começo da jornada e pouco no fim, quando a bolsa e o grimório já foram montados. Por isso cada personagem é **muito específico**: ele começa com um plano de jogo fechado (bolsa, magias e passiva que se encaixam) e **vence os primeiros andares sem comprar nada**. Depois, a passiva puxa as escolhas da loja, do Poço e das recompensas numa direção própria, sem proibir as outras.

Cada um **testa uma regra diferente** do jogo, para que nenhum seja "o Feiticeiro com outro número":

| Personagem | Regra que ele explora | Inventário |
|---|---|---|
| **Minimalista** | bolsa pequena (Hidrogênio) | Grade 3×2 |
| **Metalurgista** | dados ruins viram combustível (Chumbo e 1) | Esteira 5×2 |
| **Copista** | o inventário do inimigo e o espaço livre do seu | Grade 4×2 |
| **Perfeccionista** | guardar dados entre turnos (marca) | Moldura 4×3, sem o meio |
| **Vampiro** | vida como recurso (dano que cura, cura que vira vida máxima) | Caixão 2×4 |
| **Bárbaro** | vida baixa como arma (Fúria) e autocura | Grade 3×3 |

O **Vampiro** e o **Bárbaro** mexem os dois com vida, em direções opostas: o Vampiro quer a vida cheia (a cura que sobra vira vida máxima); o Bárbaro quer a vida baixa (Fúria), e se cura só para não morrer.

### 0.2 Regras mantidas

| Regra | Como aparece aqui |
|---|---|
| **Ninguém começa com defesa** | Nenhum kit tem bloqueio, Esquiva ou Espelho. O Vampiro cura causando dano; o Bárbaro tem uma cura limitada (2× por luta). |
| Passiva simples | Uma linha de regra cada (a do Metalurgista e a do Vampiro têm duas frases curtas). |
| Inimigos com as mesmas regras | Cada arquétipo também aparece como inimigo, com a mesma passiva, a mesma bolsa e o mesmo inventário (seção 3). |
| A loja é a mesma para todos | O formato do inventário filtra o que cabe. A única exceção é o Chumbo do Metalurgista. |
| Princípios do catálogo | As magias novas só usam os dados nos slots e têm resultado calculável antes de "Terminar turno". |

### 0.3 Referência de força

Para comparar: o **Feiticeiro** tem 90 de vida, mão de 5 e causa uns **6 a 8 de dano por turno** com a Faísca, mais um pico de 14 a 20 com a Bola de Fogo (1× por luta). O inimigo do andar 1 tem **31 de vida** (porta normal). Os números de "por que se vira" abaixo são médias aproximadas para o andar 1, sem melhorias.

---

## 1. Fichas

| Personagem | Inventário | Passiva | Vida | Mão | Bolsa inicial | Magias iniciais |
|---|---|---|---|---|---|---|
| **Minimalista** | Grade **3×2** (6 casas) | **Voto de Pobreza**: destruir dado no Poço é grátis, e toda recompensa pós-luta tem a opção "destruir 1 dado". | 70 | **4** | **5 dados**: 3 Hidrogênio + 2 comuns | Faísca, **Dardo Arcano** (nova) |
| **Metalurgista** | Esteira **5×2** (10 casas) | **Peso Morto**: cada Chumbo que sai com 1 puxa mais um dado da bolsa para a mão. A Loja e o Poço vendem Chumbo para você. | 100 | 5 | 8 dados: 5 comuns + 3 Chumbo | Levantar Peso (nível 2), Estocada |
| **Copista** | Grade **4×2** (8 casas) | **Inspiração**: no início de cada luta, uma magia aleatória do inimigo que caiba nas suas casas livres é copiada nelas, no mesmo nível, até o fim da luta. | 80 | 5 | 7 comuns + 1 Mercúrio | Faísca, Imitação Barata |
| **Perfeccionista** | **Moldura 4×3** sem as 2 casas do meio (10 casas) | **Ainda Não Está Bom**: no fim do turno, até 2 dados que sobraram na mão ficam marcados. Você pode ter 2 marcas. | 80 | 5 | 7 comuns + 1 Ósmio | **Dardo Arcano** (nova), **Obra-Prima** (nova) |
| **Vampiro** | **Caixão 2×4** (2 de largura, 4 de altura) | **Sede**: toda cura que você recebe também dá +1 de vida máxima, para sempre (até 3 por luta). Queima causa o dobro de dano em você. | **65** | 5 | 7 comuns + 1 Sódio | **Mordida** (nova), **Banquete** (nova) |
| **Bárbaro** | Grade **3×3** (9 casas) | **Fúria**: com metade da vida ou menos, toda magia de dano causa +1 por golpe para cada 10 de vida que você perdeu. | **110** | 5 | 6 comuns + 2 **Amianto** (novo) | **Machadada** (nova), **Cerrar os Dentes** (nova) |

### 1.1 Formatos

```
Minimalista   Metalurgista   Copista   Perfeccionista   Vampiro   Bárbaro
###           #####          ####      ####             ##        ###
###           #####          ####      #..#             ##        ###
                                       ####             ##        ###
                                                        ##
```

`.` = casa que não existe.

---

## 2. Os personagens

### 2.1 Minimalista: "Possuo cinco dados. Os outros possuem desculpas."

- **Plano:** bolsa minúscula. Com 5 dados e mão de 4, quase todo turno sai a bolsa inteira, e o Hidrogênio (×3 com bolsa de 8 ou menos) vale de 3 a 18. A Faísca e o Dardo Arcano usam os dois maiores: o Dardo pede um valor par, e o Hidrogênio ×3 dá 6, 12 ou 18 nas faces pares.
- **Por que se vira:** dois dados de 9 a 18 por turno (+2 no Dardo) dão uns **20 a 24 de dano**. O inimigo do andar 1 cai em 2 turnos. A vida baixa (70) é o preço.
- **Como cresce:** adesivos ×2 nos Hidrogênios (um 6 com adesivo vale 36). Cada dado novo é uma decisão séria: com 9 dados, o Hidrogênio desliga. A passiva deixa limpar a bolsa de graça.
- **Inventário:** 6 casas, 2 já ocupadas. Cabem o Meteoro (L de 4) ou uma Reta 3, não os dois.
- **Ponto fraco:** o Lixeiro (Chumbo na bolsa), o Arrancar das Mãos (tira o melhor dado de uma bolsa de 5) e a Interrupção Rude (mão de 4 vira 2) machucam muito mais que nos outros.
- **Combos do catálogo:** Bis! (o Hidrogênio na face máxima rola de novo e soma ×3), Física Aplicada (Hidrogênio com 1 = 3, o "menor" perfeito), Plágio.

### 2.2 Metalurgista: "Chumbo é só ouro que ainda não se esforçou."

- **Plano:** o dado que todo mundo odeia é o combustível. O Chumbo (faces 1, 1, 1, 2, 2, 3) sai com 1 metade das vezes; cada 1 dele puxa mais um dado. Levantar Peso causa dano = **6 × quantos 1 há na mão** (nível 2). A Estocada usa o melhor dado comum.
- **Por que se vira:** uns 2 dados de valor 1 por turno, e a mão chega a 6 ou 7 dados: **12 de Levantar Peso + 5 a 6 de Estocada ≈ 17 por turno**. A vida alta (100) segura as lutas de 2 a 3 turnos.
- **Como cresce:** compra Chumbo (na Loja, como dado novo; no Poço, como elemento aplicado em um dado). Mais Chumbo, mais 1, mais dados na mão. Os adesivos vão nos dados comuns, para a Estocada.
- **Inventário:** reto e comprido, como um cinto largo: cabem as magias retas e as de 2 linhas (1×2, 2×2, L de 3).
- **Matchups:** o **Lixeiro** e o **Porteiro de Chumbo** viram presentes. O Chumbo do Lixeiro fica na bolsa, e o do Porteiro sai na mão todo turno.
- **Ponto fraco:** dano baixo contra inimigos com muita vida no fim da torre: ele precisa evoluir o Levantar Peso. A **Interrupção Rude** e a **Rasteira** (mão menor) cortam os 1. Em compensação, a **Meia Verdade** e a **Chave de Braço** quase não o atrapalham (1 continua 1).
- **Combos do catálogo:** Espelho e Sacrifício (pedem um 1), Improviso Brilhante (pede um 1), Exibição de Velocidade e Armadura de Músculo (dados ≤ 3: o Chumbo nunca passa de 3).

### 2.3 Copista: "Não é cópia. É homenagem, com melhorias."

- **Plano:** no início de cada luta, sorteia uma magia do inimigo entre as que **cabem nas casas livres** do inventário dele, do jeito que as peças estão (a cópia pode girar, mas nada é movido). A cópia entra **no mesmo nível** e some no fim da luta. Ela tem os próprios usos ("1× por luta" conta separado do inimigo). Se nada couber, não há cópia.
- **A decisão:** toda casa livre é uma aposta. Comprar uma magia fixa é garantido; deixar 4 casas livres (um 2×2, uma Reta 4, um L) abre espaço para as peças grandes do inimigo, mas a cópia pode ser uma Faísca. O arranjo também pesa: 4 casas em quadrado aceitam a Bola de Fogo; 4 em linha, não.
- **Por que se vira:** a grade 4×2 começa com 3 casas ocupadas e 5 livres. No andar 1, o Feiticeiro inimigo tem Faísca e Bola de Fogo; o Assassino, Estocada e Corte Duplo: metade das vezes vem a peça forte. O Mercúrio inicial copia o maior valor da mão ou da última mão do inimigo: é o dado ideal para a Imitação. Com ela, qualquer dado vira um par: dado X na Imitação → dois X na mão → Bola de Fogo de **4X, mais queima 3**, ou Corte Duplo de **2X (4X se X for ímpar) todo turno**. Quando a cópia é fraca, ele tem duas Faíscas (a sua e a copiada) e a Imitação: ~10 a 12 por turno.
- **Como cresce:** quanto mais alto o andar, mais magias e níveis o inimigo traz, e o sorteio fica mais rico. As compras dele vão para magias que **combinam com qualquer coisa** (Imitação, Faísca, Pose Congelada), sempre pesando quanto espaço sobra.
- **Ponto fraco:** sorte no sorteio, e a escolha entre poder fixo e espaço livre a cada compra. Inimigos com uma magia boa e várias pequenas costumam entregar a pequena.
- **Combos do catálogo:** Imitação Barata → qualquer magia de par copiada (Bola de Fogo, Transfusão, Concentrar Força, Lição de Anatomia).

### 2.4 Perfeccionista: "Ainda não está bom. Vai ficar."

- **Plano:** nunca usa a mão inteira. O Ósmio inicial sai em toda mão: um dado garantido para começar o par, turno após turno. No fim do turno, guarda até 2 dados que sobraram (**marca**: entram na próxima mão com o mesmo valor, sem rolar, além da mão normal). Com dois 6 guardados, a próxima mão de 5 tem 60% de chance de completar o trio para a **Obra-Prima** (3 dados iguais: dano = soma ×2; três 6 = 36).
- **Por que se vira:** no 1º turno, Dardo Arcano num par (~6) e guarda o par; no 2º, Obra-Prima (~27) + Dardo. O inimigo do andar 1 cai entre o 2º e o 3º turno. Os turnos são lentos e o pico é alto.
- **Como cresce:** adesivos ×2 em várias faces do mesmo número (três 12 = 72). Combina com todas as magias de par e sequência.
- **Inventário:** a Moldura não tem o meio. Não cabem 2×2 (Bola de Fogo), T nem Cruz. Cabem Reta 4 (em cima ou embaixo), Retas 3, 1×2 nas laterais e L de 3 e de 4 nos cantos.
- **Ponto fraco:** as mexidas do inimigo na próxima mão também pegam os dados guardados (é a mesma regra da marca hoje): a **Meia Verdade** transforma o par de 6 guardado em dois 1. A Interrupção Rude não tira os guardados, porque eles entram além da mão.
- **Combos do catálogo:** Pose Congelada, Concentrar Força e Impulso Calculado (marcas que agora convivem), Meteoro e Matemática Superior (o trio guardado também serve), Transfusão.

### 2.5 Vampiro: "Não bebo sangue. Recebo homenagens."

- **Plano:** começa com pouca vida (65) e se mantém de pé batendo. A **Mordida** (nova) causa dano = valor e cura metade. O **Banquete** (novo) pede 3 dados, causa dano = soma e cura o menor dado. A passiva dá **+1 de vida máxima a cada cura**: quanto mais ele se cura, mais cresce.
- **Por que se vira:** Mordida com o melhor dado (~5) + Banquete com os 3 seguintes (~11): **~16 de dano e ~5 de cura por turno**. O inimigo do andar 1 cai em 2 turnos, e o Vampiro sai quase com a vida com que entrou.
- **Como cresce:** a vida máxima sobe até 3 por luta (até +30 numa fatia de 10 andares), sem comprar vida na Loja. Toda cura conta, então Mordida e Banquete no mesmo turno já valem 2; o Remendo e a parada de Cura também contam.
- **Inventário:** o Caixão é estreito e alto. Cabem 1×1, 1×2, 2×1, 2×2, Retas 3 e 4 em pé e L de 3 e de 4; não cabem T, Cruz nem a Diagonal de 3.
- **Elemento:** o Sódio inicial queima o inimigo quando usado. Ele odeia fogo, mas adora pôr fogo nos outros.
- **Ponto fraco:** a vida baixa, e a **queima em dobro**: o Piromante, a Bola de Fogo e o Sódio são o pesadelo dele. A Interrupção Rude e a Rasteira cortam o Banquete. A cura só vem com dano, então quando a mão é ruim, ele não se recupera.
- **Combos do catálogo:** Transfusão (ganho de vida máxima direto), Remendo (com a vida cheia, vira vida máxima), Suor de Campeão (tira a queima, o maior perigo dele), Imitação Barata (as cópias alimentam o Banquete).

### 2.6 Bárbaro: "Li um livro uma vez. Depois bati em quem escreveu."

- **Plano:** muita vida (110) e a **Fúria**: ela **só liga com metade da vida ou menos**. Ligada, toda magia de dano causa **+1 por golpe para cada 10 de vida perdida** (vida máxima − vida atual, arredondando para baixo). Com 110 de vida máxima, ela acende em 55 com +5 de uma vez e chega a +9 com 20 de vida. A **Machadada** (nova) pede um dado ≥ 4 e causa dano = valor ×2. O **Cerrar os Dentes** (nova) pede um dado ≤ 3 e cura valor ×3 (2× por luta).
- **A decisão:** curar tira Fúria. Cada Cerrar os Dentes, cada parada de Cura e cada compra de vida máxima é uma escolha entre ficar vivo e bater forte.
- **Por que se vira:** a Machadada com o melhor dado alto: ~11 a 13 por turno com a vida acima da metade, ~18 a 22 com a Fúria ligada. Os 2 Amiantos (faces 4 a 9) quase sempre pagam a Machadada, mas cada um usado tira 3 de vida dele: é o caminho para a Fúria. A primeira metade da vida é o tempo de aquecer; a segunda é a fase perigosa, dos dois lados.
- **Como cresce:** magias de vários golpes multiplicam a Fúria (Corte Duplo ímpar, Exibição de Velocidade, Bis!). Adesivos nos Amiantos para a Machadada (o dano a si mesmo não cresce).
- **Inventário:** 3×3, quadrado. Cabe quase tudo, inclusive T e Cruz, mas tem só 9 casas.
- **Ponto fraco:** o dano depende de já ter apanhado, e o começo da jornada (vida cheia) é a fase mais fraca dele. Um inimigo que bate muito forte de uma vez mata antes de a Fúria render. O Espelho do inimigo devolve a Machadada inteira, com a Fúria. A Chave de Braço (metade) derruba os dados ≥ 4.
- **Combos do catálogo:** Exibição de Velocidade (3 golpes, +Fúria em cada), Corte Duplo, Remendo (cura de emergência), Sacrifício (+5 por magia, soma com a Fúria).

---

## 3. O que é novo

### 3.1 Magias

| Magia | Formato | Grupo | Pede | Efeito | Uso | De quem |
|---|---|---|---|---|---|---|
| **Obra-Prima** | L (4) | Perfeccionista | **3 dados iguais** | Dano = soma ×2. | sempre | Perfeccionista |
| **Dardo Arcano** | 1×1 | qualquer | **dado par** | Dano = valor + 2. | sempre | básica (Minimalista, Perfeccionista) |
| **Mordida** | 1×1 | Vampiro | qualquer dado | Dano = valor. Cura metade do valor (arredonda para cima). | sempre | Vampiro |
| **Banquete** | Reta 3 | Vampiro | 3 dados quaisquer | Dano = soma. Cura = o menor dos três. | sempre | Vampiro |
| **Machadada** | 1×2 | Bárbaro | dado ≥ 4 | Dano = valor ×2. | sempre | Bárbaro |
| **Cerrar os Dentes** | 1×1 | Bárbaro | dado ≤ 3 | Cura = valor ×3. | 2× por luta | Bárbaro |

- **Exigência nova: "trio"** (3 dados iguais). Os buracos mostram "=" entre os três.
- **Dardo Arcano** é a 2ª magia básica: tão simples quanto a Faísca, mas com uma escolha (só aceita par, e paga +2 por isso). Com ela, a Faísca fica só no Feiticeiro, no Copista e no Minimalista.
- Todas entram no catálogo e na loja para todos, como as outras. A cura cresce com o nível, como o dano.

### 3.2 Substância nova

| Substância | Símbolo | Efeito | Na loja? |
|---|---|---|---|
| **Amianto** | Am | Fibroso: +3 em todas as faces (4 a 9). Ao ser usado numa magia, causa 3 de dano em **você**. | sim (Loja, recompensa e Poço) |

- É o oposto do Urânio: o Urânio machuca quando **sobra**; o Amianto, quando é **usado**.
- O dano a si mesmo não é golpe: bloqueio, Esquiva, Espelho e Revide não param. Imune a Críticas também não, porque não vem do inimigo.
- Não é limitado à tabela periódica: o nome só precisa ser curto.

### 3.3 Regras

| Regra | Onde | O que muda |
|---|---|---|
| **Destruir na recompensa** | Minimalista | A tela de recompensa pós-luta ganha uma 4ª opção: "destruir 1 dado". |
| **Chumbo à venda** | Metalurgista | A Loja oferece "dado de Chumbo" e o Poço oferece "aplicar Chumbo". Só para ele. |
| **Cópia nas casas livres** | Copista | A cópia ocupa casas livres do inventário até o fim da luta. Ela não pode ser vendida, evoluída nem movida; o resto do grimório não se mexe para abrir espaço. |
| **Fúria** | Bárbaro | Liga com a vida em metade da máxima ou menos, e desliga se a cura passar disso. "+1 por golpe": cada golpe de uma magia de vários golpes ganha o bônus (como o Sacrifício). Conta no momento do golpe. |
| **Cura vira vida máxima** | Vampiro | Cada cura que ele recebe (maior que zero) dá +1 de vida máxima e +1 de vida, até 3 por luta. Vale para toda cura dele (Mordida, Banquete, Remendo, a parada de Cura). |
| **Duas marcas** | Perfeccionista | Exceção à regra "uma marca por vez" do catálogo (§2.3): ele pode ter 2. Uma marca nova substitui a mais antiga. |
| **Escolher dados no fim do turno** | Perfeccionista | Antes de "Terminar turno", tocar em até 2 dados livres da mão para marcá-los. |

### 3.4 Grupos de magia (o que cada inimigo compra)

Hoje os inimigos só compram do próprio grupo (Feiticeiro ou Assassino) e do "qualquer". Os novos usam uma lista:

| Arquétipo | Compra |
|---|---|
| Minimalista | Feiticeiro (magias de 1 dado e de face máxima: Faísca, Bis!, Plágio, Sacrifício) |
| Metalurgista | Assassino + magias que pedem um 1 (Espelho, Sacrifício, Improviso Brilhante) |
| Copista | Feiticeiro |
| Perfeccionista | Feiticeiro + Assassino, só as de par, trio e sequência, e as de marca |
| Vampiro | Feiticeiro + Assassino, só as de dano, mais Remendo, Transfusão, Mordida e Banquete |
| Bárbaro | Assassino, mais Remendo, Machadada e Cerrar os Dentes |

---

## 4. Como inimigos

| Arquétipo | Como luta | Variante proposta |
|---|---|---|
| **Minimalista** | Bate forte e cedo, morre rápido. Vida do inimigo ×0,8 para compensar o Hidrogênio. | **Monge do Silêncio**: só 4 dados, todos Hidrogênio. Aparece a partir do andar 5. |
| **Metalurgista** | Lento e resistente; a passiva vale para ele. | **Fundidor**: no primeiro turno, transforma 1 dado comum **seu** em Chumbo até o fim da luta (diferente do Lixeiro, que adiciona). |
| **Copista** | **Copia uma magia aleatória sua** que caiba nas casas livres dele. A sua build vira a arma dele. | — |
| **Perfeccionista** | A IA guarda os dois dados de valor mais repetido. | — |
| **Bárbaro** | Fica mais perigoso a cada golpe que você dá. Contra ele, vale juntar dano e acabar num turno só. | — |
| **Vampiro** | Alonga a luta curando. Como inimigo, a vida dele começa cheia, então a passiva já faz ele crescer durante a luta. | — |

---

## 5. Elementos: por que quase não aparecem

### 5.1 Como funcionam hoje

Cada dado pode ter **um** elemento, que dá uma regra de uma linha a ele. No jogo existem 6:

| Elemento | Na prática |
|---|---|
| **Hidrogênio** | Vale ×3, mas só com a bolsa de 8 dados ou menos (a bolsa inicial tem 8: comprar um dado já desliga). |
| **Ósmio** | Âncora: sai sempre na primeira mão da luta. Também **não pode ser roubado nem arrancado** (Roubar a Cena e Arrancar das Mãos o pulam). O valor rola normalmente: é um dado comum que você sabe que vem. **Proposta (rodada 5): sai em toda mão** (ver 5.3). |
| **Urânio** | Faces de 3 a 8. Se sobrar na mão sem uso, envenena **você** em 2 (o veneno não cai durante a luta). |
| **Sódio** | Ao ser usado numa magia, queima o inimigo em 2. |
| **Mercúrio** | Ao rolar, vale o maior valor entre a sua mão e a última mão do inimigo. |
| **Chumbo** | Lixo: três faces 1 travadas. Só vem do inimigo. |

### 5.2 Diagnóstico

A sensação procede: **é raro ver um elemento, e quando aparece, a tela não explica**.

| Problema | Por quê (no código) |
|---|---|
| Ninguém começa com elemento | A bolsa inicial do Feiticeiro e do Assassino é de 8 dados comuns. |
| A recompensa raramente oferece | Das 3 ofertas, uma é "dado" em 3 de 4 lutas, e esse dado tem elemento só metade das vezes. |
| A loja cobra caro | Dado com elemento custa 14 moedas (6 + 8), contra 10 de uma magia. Uma vitória paga 4 a 9. |
| O Poço é uma parada entre quatro | Aparece a cada 3 lutas, disputando com Loja, Cura e Escola. |
| Os inimigos quase não têm | Recebem 0,4 melhoria por andar, e só 1 em 5 melhorias é elemento. No andar 5 (porta normal), um inimigo recebe 2 melhorias: em média 0,4 elemento. Só o Piromante sempre tem (2 Sódio). |
| A tela não explica | O dado mostra só a cor e o símbolo ("Na"). A descrição está num tooltip da lista da bolsa, e **tooltip não abre no toque** (Android). Quando o Sódio queima, a queima aparece, mas não diz que veio do Sódio. |

### 5.3 Proposta

1. **Todo personagem começa com elemento.** Minimalista (3 Hidrogênio), Metalurgista (3 Chumbo), Copista (1 Mercúrio), Perfeccionista (1 Ósmio), Vampiro (1 Sódio) e Bárbaro (2 Amianto), já nas fichas. Para os que continuam: **Feiticeiro, 1 Sódio** (combina com a Bola de Fogo); **Assassino, 1 Mercúrio** (a mão de 6 aproveita o maior valor).
2. **Dado oferecido sempre tem elemento.** Na recompensa e na loja, o "dado comum" sai. Preço na loja: 10 (igual a uma magia).
3. **Todo inimigo tem pelo menos 1 elemento**, pelo arquétipo (os mesmos da lista acima), a partir do andar 1. Assim o jogador vê o efeito agindo contra ele.
4. **Tocar e segurar um dado** (na mão, na bolsa ou na mão do inimigo) mostra o nome e o efeito do elemento. No lugar do tooltip.
5. **Ósmio em toda mão.** Âncora: sai em **toda** mão, ocupando uma das vagas (não é dado extra). Não volta para a bolsa: no fim do turno, fica reservado para a próxima mão. Com mais Ósmios que vagas, a mão inteira é de Ósmio. Mexidas na mão (Interrupção Rude) cortam primeiro os outros dados. Continua sem poder ser roubado nem arrancado. Com adesivos, vira um valor alto garantido todo turno: por isso passa a ser **Raro**.
6. **O efeito se anuncia** quando acontece: "Sódio: queima 2", "Urânio: veneno 2", "Mercúrio: copiou 6", "Hidrogênio ×3".

Elementos novos (Hélio, Vidro, Ferro, Ouro… da `SPEC_v3.md` §4.1) ficam para depois: primeiro os 6 atuais precisam aparecer e ser entendidos.

---

## 6. Combos para o simulador medir primeiro

| Combo | Por quê |
|---|---|
| Minimalista no andar 1 | Duas Faíscas com Hidrogênio podem matar em 1 turno quando sai 18 + 18. Medir a chance. |
| Minimalista + Bis! | Hidrogênio na face máxima rola de novo e soma ×3 a cada rolagem. Pode passar de 100. |
| Metalurgista contra o Porteiro | O Mestre do andar 10 vira o melhor matchup dele. |
| Copista com 0, 2 e 4 casas livres | Medir quanto o espaço livre vale contra uma magia fixa comprada. |
| Copista inimigo contra o jogador | Sortear a Bola de Fogo nível 3 do jogador pode ser forte demais. |
| Perfeccionista com Obra-Prima evoluída | Três 12 com nível 3 = 144. Medir em que andar isso aparece. |
| Vampiro em 10 andares | Medir quanta vida máxima ele junta (teto de +50) e se a trava de 60 turnos aparece contra o Vampiro inimigo. |
| Vampiro contra o Piromante | Queima em dobro: medir se o matchup é perdido de saída. |
| Bárbaro com Exibição de Velocidade | 3 golpes, cada um com a Fúria: com 60 de vida perdida, são +18. |
| Bárbaro até ligar a Fúria | Medir em quantos turnos ele chega à metade da vida e se o Amianto acelera demais. |
| Bárbaro e Cerrar os Dentes | Medir se o jogador cura ou prefere ficar com Fúria; se ninguém cura, a magia está errada. |
| Elementos para todos | Medir o efeito de ter elemento desde o andar 1, dos dois lados. |

---

## 7. Em aberto

| Tema | Pergunta |
|---|---|
| Vida dos personagens | 60 a 110: o simulador deve dizer se a ordem (Vampiro e Minimalista mais frágeis, Metalurgista e Bárbaro mais resistentes) faz sentido. |
| Escolha de personagem | Todos liberados desde o começo (a SPEC não tem meta-progressão no protótipo). |
| Nomes | Minimalista, Metalurgista, Copista e Perfeccionista servem para qualquer gênero (TOM §5). "Vampiro" e "Bárbaro" não: manter assim? |

---

## 8. Implementação

Código: `engine/characters.gd` (kits e passivas), `engine/resolver.gd` (Fúria, Sede, Amianto, Fundidor, Copista, dados guardados), `engine/fighter.gd` (Ósmio em toda mão, Peso Morto), `engine/shop.gd` (ofertas dos passivos e raridade). Testes em `tests/test_personagens.gd`.

### 8.1 Decisões tomadas na implementação (revisar depois de jogar)

- **Jogáveis:** Minimalista, Vampiro e Bárbaro, os 3 com passiva automática (nenhuma interação nova na tela). Para liberar outro, basta incluir o id em `Characters.PLAYABLE`; o Perfeccionista ainda precisa da tela para escolher os dados guardados.
- **Inimigos:** o arquétipo é sorteado entre os 8, com a mesma chance. Variantes (20%): Lixeiro (Assassino), Piromante (Feiticeiro), Fundidor (Metalurgista) e Monge do Silêncio (Minimalista, a partir do andar 5).
- **Fúria:** calculada em cada golpe, com a vida daquele momento.
- **Sede:** o limite de 3 volta a zero em cada luta e na parada de Cura.
- **Peso Morto:** os dados puxados também podem puxar (um Chumbo puxado que sai com 1 puxa outro).
- **Copista:** os dois lados copiam no começo da luta (o jogador primeiro). Só copia peças originais, nunca a cópia do outro. A cópia aparece no cartão com a etiqueta CÓPIA.
- **Perfeccionista:** os dados guardados e a marca das magias somam no máximo 2. A IA guarda os dois valores mais repetidos.
- **Fundidor:** troca o dado comum mais forte (maior soma de faces).
- **Elementos:** "tocar e segurar" virou **tocar**: o dado selecionado mostra o elemento e o efeito. A lista da bolsa mostra o efeito escrito em cada linha.

### 8.2 Simulador

`--char=all`, 300 jornadas por porta, bot com a IA cautelosa. Porcentagem que vence o andar 10:

| Personagem | Fácil | Normal | Difícil |
|---|---|---|---|
| Bárbaro | 21% | 18% | 4% |
| Feiticeiro | 19% | 15% | 3% |
| Metalurgista | 14% | 11% | 1% |
| Minimalista | 10% | 7% | 1% |
| Vampiro | 7% | 6% | 1% |
| Copista | 2% | 1% | 0% |
| Perfeccionista | 1% | 1% | 0% |
| Assassino | 0% | 0% | 0% |

O bot não sabe usar bem o espaço livre do Copista nem o trio do Perfeccionista, então esses números subestimam os dois. O Vampiro é o mais fraco dos jogáveis; o Bárbaro, o mais forte.

#### Rebalanceamento do Vampiro

O Vampiro estava bem abaixo dos outros jogáveis (6% na porta normal): a Sede antiga só convertia a cura que passava do máximo, e ele quase nunca se curava com a vida cheia. Tentativas no CI (500 jornadas, porta normal, `--seed=1`, % que vence o andar 10):

| Versão | Vampiro |
|---|---|
| Original (Sede: cura que sobra, até 5; Mordida cura metade; 60 de vida) | 6% |
| Sede +1 por cura até 8; Mordida cura o dano inteiro; 70 de vida | 37% |
| Sede +1 por cura até 8; Mordida cura metade; 70 de vida | 25% |
| Sede +1 por cura até 4; Mordida cura metade; 65 de vida | 17% |
| **Sede +1 por cura até 3; Mordida cura metade; 65 de vida (atual)** | **13%** |

Na mesma rodada: Bárbaro 16%, Feiticeiro 14%, Minimalista 5%.
