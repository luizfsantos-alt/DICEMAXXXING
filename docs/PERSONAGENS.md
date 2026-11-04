# Personagens novos (proposta)

> **Status: proposta, rodada 2.** São 5 arquétipos novos, jogáveis e usados pelos inimigos, no padrão de `docs/SPEC_v3.md` §3: **formato do inventário**, **uma passiva**, vida, mão, bolsa inicial e magias iniciais. Seguem o tom de `docs/TOM.md` e os princípios de `docs/CATALOGO_MAGIAS.md` §1. Números *(iniciais)*, a passar pelo simulador.

---

## Feedback (rodada 1)

| Veredito | Personagens |
|---|---|
| **Manter** | Minimalista, Metalurgista, Perfeccionista |
| **Ajustar** | **Copista**: copia uma magia **aleatória** do inimigo que caiba, não a maior. Deixar espaço livre no inventário deve ser uma decisão séria, por isso a Mesa de Empréstimo saiu: a cópia vai para as casas livres da grade dele. |
| **Cortar** | **Populista** (com o Nitrogênio e o Abaixo-Assinado). No lugar: **Vampiro**, com magias de dano, cura e ganho de vida. |

## Feedback (rodada 2)

*(Em branco: Copista ajustado e Vampiro novo.)*

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

### 0.2 Regras mantidas

| Regra | Como aparece aqui |
|---|---|
| **Ninguém começa com defesa** | Nenhum kit tem bloqueio, Esquiva ou Espelho. O Vampiro cura, mas só causando dano. |
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
| **Minimalista** | Grade **3×2** (6 casas) | **Voto de Pobreza**: destruir dado no Poço é grátis, e toda recompensa pós-luta tem a opção "destruir 1 dado". | 70 | **4** | **5 dados**: 3 Hidrogênio + 2 comuns | Faísca, Faísca |
| **Metalurgista** | Esteira **5×2** (10 casas) | **Peso Morto**: cada Chumbo que sai com 1 puxa mais um dado da bolsa para a mão. A Loja e o Poço vendem Chumbo para você. | 100 | 5 | 8 dados: 5 comuns + 3 Chumbo | Levantar Peso (nível 2), Estocada |
| **Copista** | Grade **4×2** (8 casas) | **Inspiração**: no início de cada luta, uma magia aleatória do inimigo que caiba nas suas casas livres é copiada nelas, no mesmo nível, até o fim da luta. | 80 | 5 | 8 comuns | Faísca, Imitação Barata |
| **Perfeccionista** | **Moldura 4×3** sem as 2 casas do meio (10 casas) | **Ainda Não Está Bom**: no fim do turno, até 2 dados que sobraram na mão ficam marcados. Você pode ter 2 marcas. | 80 | 5 | 8 comuns | Faísca, **Obra-Prima** (nova) |
| **Vampiro** | **Caixão 2×4** (2 de largura, 4 de altura) | **Sede**: a cura que passaria da vida máxima vira vida máxima, para sempre (até 5 por luta). Queima causa o dobro de dano em você. | **60** | 5 | 8 comuns | **Mordida** (nova), **Banquete** (nova) |

### 1.1 Formatos

```
Minimalista   Metalurgista   Copista   Perfeccionista   Vampiro
###           #####          ####      ####             ##
###           #####          ####      #..#             ##
                                       ####             ##
                                                        ##
```

`.` = casa que não existe.

---

## 2. Os personagens

### 2.1 Minimalista: "Possuo cinco dados. Os outros possuem desculpas."

- **Plano:** bolsa minúscula. Com 5 dados e mão de 4, quase todo turno sai a bolsa inteira, e o Hidrogênio (×3 com bolsa de 8 ou menos) vale de 3 a 18. Duas Faíscas usam os dois maiores.
- **Por que se vira:** dois dados de 9 a 18 por turno dão uns **20 a 24 de dano**. O inimigo do andar 1 cai em 2 turnos. A vida baixa (70) é o preço.
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
- **Por que se vira:** a grade 4×2 começa com 3 casas ocupadas e 5 livres. No andar 1, o Feiticeiro inimigo tem Faísca e Bola de Fogo; o Assassino, Estocada e Corte Duplo: metade das vezes vem a peça forte. Com a Imitação Barata, qualquer dado vira um par: dado X na Imitação → dois X na mão → Bola de Fogo de **4X, mais queima 3**, ou Corte Duplo de **2X (4X se X for ímpar) todo turno**. Quando a cópia é fraca, ele tem duas Faíscas (a sua e a copiada) e a Imitação: ~10 a 12 por turno.
- **Como cresce:** quanto mais alto o andar, mais magias e níveis o inimigo traz, e o sorteio fica mais rico. As compras dele vão para magias que **combinam com qualquer coisa** (Imitação, Faísca, Pose Congelada), sempre pesando quanto espaço sobra.
- **Ponto fraco:** sorte no sorteio, e a escolha entre poder fixo e espaço livre a cada compra. Inimigos com uma magia boa e várias pequenas costumam entregar a pequena.
- **Combos do catálogo:** Imitação Barata → qualquer magia de par copiada (Bola de Fogo, Transfusão, Concentrar Força, Lição de Anatomia).

### 2.4 Perfeccionista: "Ainda não está bom. Vai ficar."

- **Plano:** nunca usa a mão inteira. No fim do turno, guarda até 2 dados que sobraram (**marca**: entram na próxima mão com o mesmo valor, sem rolar, além da mão normal). Com dois 6 guardados, a próxima mão de 5 tem 60% de chance de completar o trio para a **Obra-Prima** (3 dados iguais: dano = soma ×2; três 6 = 36).
- **Por que se vira:** no 1º turno, Faísca (~5) e guarda o par; no 2º, Obra-Prima (~27) + Faísca. O inimigo do andar 1 cai entre o 2º e o 3º turno. Os turnos são lentos e o pico é alto.
- **Como cresce:** adesivos ×2 em várias faces do mesmo número (três 12 = 72). Combina com todas as magias de par e sequência.
- **Inventário:** a Moldura não tem o meio. Não cabem 2×2 (Bola de Fogo), T nem Cruz. Cabem Reta 4 (em cima ou embaixo), Retas 3, 1×2 nas laterais e L de 3 e de 4 nos cantos.
- **Ponto fraco:** as mexidas do inimigo na próxima mão também pegam os dados guardados (é a mesma regra da marca hoje): a **Meia Verdade** transforma o par de 6 guardado em dois 1. A Interrupção Rude não tira os guardados, porque eles entram além da mão.
- **Combos do catálogo:** Pose Congelada, Concentrar Força e Impulso Calculado (marcas que agora convivem), Meteoro e Matemática Superior (o trio guardado também serve), Transfusão.

### 2.5 Vampiro: "Não bebo sangue. Recebo homenagens."

- **Plano:** começa com pouca vida (60) e se mantém de pé batendo. A **Mordida** (nova) causa dano = valor e cura metade. O **Banquete** (novo) pede 3 dados, causa dano = soma e cura o menor dado. A passiva transforma a cura que sobra em **vida máxima**: quanto mais cheio ele entra na luta, mais cresce.
- **Por que se vira:** Mordida com o melhor dado (~5) + Banquete com os 3 seguintes (~11): **~16 de dano e ~5 de cura por turno**. O inimigo do andar 1 cai em 2 turnos, e o Vampiro sai quase com a vida com que entrou.
- **Como cresce:** a vida máxima sobe até 5 por luta (até +50 numa fatia de 10 andares), sem comprar vida na Loja. O Remendo e a Transfusão rendem mais nele: o Remendo com vida cheia vira vida máxima.
- **Inventário:** o Caixão é estreito e alto. Cabem 1×1, 1×2, 2×1, 2×2, Retas 3 e 4 em pé e L de 3 e de 4; não cabem T, Cruz nem a Diagonal de 3.
- **Ponto fraco:** a vida baixa, e a **queima em dobro**: o Piromante, a Bola de Fogo e o Sódio são o pesadelo dele. A Interrupção Rude e a Rasteira cortam o Banquete. A cura só vem com dano, então quando a mão é ruim, ele não se recupera.
- **Combos do catálogo:** Transfusão (ganho de vida máxima direto), Remendo (com a vida cheia, vira vida máxima), Suor de Campeão (tira a queima, o maior perigo dele), Imitação Barata (as cópias alimentam o Banquete).

---

## 3. O que é novo

### 3.1 Magias

| Magia | Formato | Grupo | Pede | Efeito | Uso | De quem |
|---|---|---|---|---|---|---|
| **Obra-Prima** | L (4) | Perfeccionista | **3 dados iguais** | Dano = soma ×2. | sempre | Perfeccionista |
| **Mordida** | 1×1 | Vampiro | qualquer dado | Dano = valor. Cura metade do valor (arredonda para cima). | sempre | Vampiro |
| **Banquete** | Reta 3 | Vampiro | 3 dados quaisquer | Dano = soma. Cura = o menor dos três. | sempre | Vampiro |

- **Exigência nova: "trio"** (3 dados iguais). Os buracos mostram "=" entre os três.
- As três entram no catálogo e na loja para todos, como as outras. A cura delas cresce com o nível, como o dano.

### 3.2 Regras

| Regra | Onde | O que muda |
|---|---|---|
| **Destruir na recompensa** | Minimalista | A tela de recompensa pós-luta ganha uma 4ª opção: "destruir 1 dado". |
| **Chumbo à venda** | Metalurgista | A Loja oferece "dado de Chumbo" e o Poço oferece "aplicar Chumbo". Só para ele. |
| **Cópia nas casas livres** | Copista | A cópia ocupa casas livres do inventário até o fim da luta. Ela não pode ser vendida, evoluída nem movida; o resto do grimório não se mexe para abrir espaço. |
| **Cura vira vida máxima** | Vampiro | A cura que passaria do máximo aumenta a vida máxima, até 5 por luta. Vale para toda cura dele (Mordida, Banquete, Remendo, a parada de Cura). |
| **Duas marcas** | Perfeccionista | Exceção à regra "uma marca por vez" do catálogo (§2.3): ele pode ter 2. Uma marca nova substitui a mais antiga. |
| **Escolher dados no fim do turno** | Perfeccionista | Antes de "Terminar turno", tocar em até 2 dados livres da mão para marcá-los. |

### 3.3 Grupos de magia (o que cada inimigo compra)

Hoje os inimigos só compram do próprio grupo (Feiticeiro ou Assassino) e do "qualquer". Os novos usam uma lista:

| Arquétipo | Compra |
|---|---|
| Minimalista | Feiticeiro (magias de 1 dado e de face máxima: Faísca, Bis!, Plágio, Sacrifício) |
| Metalurgista | Assassino + magias que pedem um 1 (Espelho, Sacrifício, Improviso Brilhante) |
| Copista | Feiticeiro |
| Perfeccionista | Feiticeiro + Assassino, só as de par, trio e sequência, e as de marca |
| Vampiro | Feiticeiro + Assassino, só as de dano, mais Remendo, Transfusão, Mordida e Banquete |

---

## 4. Como inimigos

| Arquétipo | Como luta | Variante proposta |
|---|---|---|
| **Minimalista** | Bate forte e cedo, morre rápido. Vida do inimigo ×0,8 para compensar o Hidrogênio. | **Monge do Silêncio**: só 4 dados, todos Hidrogênio. Aparece a partir do andar 5. |
| **Metalurgista** | Lento e resistente; a passiva vale para ele. | **Fundidor**: no primeiro turno, transforma 1 dado comum **seu** em Chumbo até o fim da luta (diferente do Lixeiro, que adiciona). |
| **Copista** | **Copia uma magia aleatória sua** que caiba nas casas livres dele. A sua build vira a arma dele. | — |
| **Perfeccionista** | A IA guarda os dois dados de valor mais repetido. | — |
| **Vampiro** | Alonga a luta curando. Como inimigo, a vida dele começa cheia, então a passiva já faz ele crescer durante a luta. | — |

---

## 5. Combos para o simulador medir primeiro

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

---

## 6. Em aberto

| Tema | Pergunta |
|---|---|
| Vida dos personagens | 60 a 100: o simulador deve dizer se a ordem (Vampiro e Minimalista mais frágeis, Metalurgista mais resistente) faz sentido. |
| Feiticeiro e Assassino | Continuam como os "genéricos" ou são substituídos pelos novos? O Assassino ainda não é jogável. |
| Escolha de personagem | Todos liberados desde o começo (a SPEC não tem meta-progressão no protótipo). |
| Nomes | Minimalista, Metalurgista, Copista e Perfeccionista servem para qualquer gênero (TOM §5). "Vampiro" não: manter assim? |
