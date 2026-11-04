# Personagens novos (proposta)

> **Status: proposta, aguardando feedback.** São 5 arquétipos novos, jogáveis e usados pelos inimigos, no padrão de `docs/SPEC_v3.md` §3: **formato do inventário**, **uma passiva**, vida, mão, bolsa inicial e magias iniciais. Seguem o tom de `docs/TOM.md` e os princípios de `docs/CATALOGO_MAGIAS.md` §1. Números *(iniciais)*, a passar pelo simulador.

---

## Feedback (rodada 1)

*(Em branco. Quando um personagem for cortado, entra outro no lugar, até termos 5 aprovados.)*

| Veredito | Personagens |
|---|---|
| **Manter** | |
| **Ajustar** | |
| **Cortar** | |

---

## 0. Como estes personagens foram pensados

### 0.1 A ideia

O arquétipo pesa muito no começo da jornada e pouco no fim, quando a bolsa e o grimório já foram montados. Por isso cada personagem é **muito específico**: ele começa com um plano de jogo fechado (bolsa, magias e passiva que se encaixam) e **vence os primeiros andares sem comprar nada**. Depois, a passiva puxa as escolhas da loja, do Poço e das recompensas numa direção própria, sem proibir as outras.

Cada um **testa uma regra diferente** do jogo, para que nenhum seja "o Feiticeiro com outro número":

| Personagem | Regra que ele explora | Inventário |
|---|---|---|
| **Minimalista** | bolsa pequena (Hidrogênio) | Grade 3×2 |
| **Metalurgista** | dados ruins viram combustível (Chumbo e 1) | Esteira 5×2 |
| **Copista** | o inventário do inimigo | Grade 3×2 + Mesa de Empréstimo 2×2 |
| **Perfeccionista** | guardar dados entre turnos (marca) | Moldura 4×3, sem o meio |
| **Populista** | bolsa grande (Nitrogênio) | Palanque em cruz (11 casas) |

O **Minimalista** e o **Populista** são rivais de propósito: um acha que talento é ter pouco; o outro, que talento é ter muitos.

### 0.2 Regras mantidas

| Regra | Como aparece aqui |
|---|---|
| **Ninguém começa com defesa** | Nenhum kit tem bloqueio, Esquiva ou Espelho. A única coisa parecida é o Remendo do Populista (cura 1× por luta, a mesma opção que o Erudito já oferece). |
| Passiva simples | Uma linha de regra cada (a do Metalurgista tem duas frases curtas). |
| Inimigos com as mesmas regras | Cada arquétipo também aparece como inimigo, com a mesma passiva, a mesma bolsa e o mesmo inventário (seção 3). |
| A loja é a mesma para todos | O formato do inventário filtra o que cabe. A única exceção é o Chumbo do Metalurgista. |
| Princípios do catálogo | As duas magias novas só usam os dados nos slots e têm resultado calculável antes de "Terminar turno". |

### 0.3 Referência de força

Para comparar: o **Feiticeiro** tem 90 de vida, mão de 5 e causa uns **6 a 8 de dano por turno** com a Faísca, mais um pico de 14 a 20 com a Bola de Fogo (1× por luta). O inimigo do andar 1 tem **31 de vida** (porta normal). Os números de "por que se vira" abaixo são médias aproximadas para o andar 1, sem melhorias.

---

## 1. Fichas

| Personagem | Inventário | Passiva | Vida | Mão | Bolsa inicial | Magias iniciais |
|---|---|---|---|---|---|---|
| **Minimalista** | Grade **3×2** (6 casas) | **Voto de Pobreza**: destruir dado no Poço é grátis, e toda recompensa pós-luta tem a opção "destruir 1 dado". | 70 | **4** | **5 dados**: 3 Hidrogênio + 2 comuns | Faísca, Faísca |
| **Metalurgista** | Esteira **5×2** (10 casas) | **Peso Morto**: cada Chumbo que sai com 1 puxa mais um dado da bolsa para a mão. A Loja e o Poço vendem Chumbo para você. | 100 | 5 | 8 dados: 5 comuns + 3 Chumbo | Levantar Peso (nível 2), Estocada |
| **Copista** | Grade **3×2** + **Mesa de Empréstimo 2×2** | **Inspiração**: no início de cada luta, a maior magia do inimigo que cabe na Mesa é copiada nela, no mesmo nível, até o fim da luta. | 80 | 5 | 8 comuns | Faísca, Imitação Barata |
| **Perfeccionista** | **Moldura 4×3** sem as 2 casas do meio (10 casas) | **Ainda Não Está Bom**: no fim do turno, até 2 dados que sobraram na mão ficam marcados. Você pode ter 2 marcas. | 80 | 5 | 8 comuns | Faísca, **Obra-Prima** (nova) |
| **Populista** | **Palanque**: cruz 5×3 sem os 4 cantos (11 casas) | **Aclamação**: todo dado que você ganha (Loja ou recompensa) vem com uma cópia igual. | 90 | **6** | **12 dados**: 8 comuns + 4 Nitrogênio (novo) | **Abaixo-Assinado** (nova), Remendo |

### 1.1 Formatos

```
Minimalista   Metalurgista   Copista           Perfeccionista   Populista
###           #####          ###   Mesa: ##    ####             .###.
###           #####          ###         ##    #..#             #####
                                               ####             .###.
```

`.` = casa que não existe. A Mesa de Empréstimo do Copista é separada da grade: só a magia copiada fica nela, e ela some no fim da luta.

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

- **Plano:** o inventário dele é pequeno, mas toda luta ele ganha a melhor peça do inimigo. A **Mesa de Empréstimo** (2×2) recebe uma cópia da maior magia do inimigo que caiba nela (em empate, a primeira na ordem do inventário dele), **no mesmo nível**. A cópia tem os próprios usos ("1× por luta" conta separado da do inimigo).
- **Por que se vira:** no andar 1, o Feiticeiro inimigo traz a Bola de Fogo e o Assassino traz o Corte Duplo. Com a Imitação Barata, qualquer dado vira um par: dado X na Imitação → dois X na mão → Bola de Fogo de **4X, mais queima 3** (com um 5: 20 + queima). Mais a Faísca, o 1º turno passa de **25**. Contra o Assassino, a cópia é o Corte Duplo, que alimentado pela Imitação dá **2X, ou 4X se X for ímpar, todo turno** (~12 a 15 por turno com a Faísca).
- **Como cresce:** quanto mais alto o andar, mais magias e níveis o inimigo traz, e melhor a cópia. As compras dele vão para magias que **combinam com qualquer coisa** (Imitação, Faísca, Pose Congelada).
- **Inventário:** grade 3×2 (6 casas, 3 livres) + a Mesa. Cabem 1×1, 1×2, 2×1, Reta 3 e L de 3.
- **Ponto fraco:** inimigos com magias que não cabem na Mesa (Reta 4, Cruz, T) ou que só têm magias de 1 casa entregam pouco. Ele precisa ler o inimigo antes de jogar.
- **Combos do catálogo:** Imitação Barata → qualquer magia de par copiada (Bola de Fogo, Transfusão, Concentrar Força, Lição de Anatomia).

### 2.4 Perfeccionista: "Ainda não está bom. Vai ficar."

- **Plano:** nunca usa a mão inteira. No fim do turno, guarda até 2 dados que sobraram (**marca**: entram na próxima mão com o mesmo valor, sem rolar, além da mão normal). Com dois 6 guardados, a próxima mão de 5 tem 60% de chance de completar o trio para a **Obra-Prima** (3 dados iguais: dano = soma ×2; três 6 = 36).
- **Por que se vira:** no 1º turno, Faísca (~5) e guarda o par; no 2º, Obra-Prima (~27) + Faísca. O inimigo do andar 1 cai entre o 2º e o 3º turno. Os turnos são lentos e o pico é alto.
- **Como cresce:** adesivos ×2 em várias faces do mesmo número (três 12 = 72). Combina com todas as magias de par e sequência.
- **Inventário:** a Moldura não tem o meio. Não cabem 2×2 (Bola de Fogo), T nem Cruz. Cabem Reta 4 (em cima ou embaixo), Retas 3, 1×2 nas laterais e L de 3 e de 4 nos cantos.
- **Ponto fraco:** as mexidas do inimigo na próxima mão também pegam os dados guardados (é a mesma regra da marca hoje): a **Meia Verdade** transforma o par de 6 guardado em dois 1. A Interrupção Rude não tira os guardados, porque eles entram além da mão.
- **Combos do catálogo:** Pose Congelada, Concentrar Força e Impulso Calculado (marcas que agora convivem), Meteoro e Matemática Superior (o trio guardado também serve), Transfusão.

### 2.5 Populista: "Se tanta gente concorda comigo, devo estar certo."

- **Plano:** bolsa enorme. O **Nitrogênio** (novo) ganha +1 em cada face para cada 4 dados na bolsa: com 12 dados, rola de 4 a 9. O **Abaixo-Assinado** (novo) pede 4 dados quaisquer e causa dano = soma + 1 para cada 2 dados na bolsa (+6 com 12).
- **Por que se vira:** 4 dados de ~4,5 + 6 = **~24 de dano por turno**, sem exigência. Com mão de 6, sobram 2 dados: um vai no Remendo (1× por luta) quando precisar.
- **Como cresce:** a passiva dobra cada dado ganho, então a bolsa passa de 20 rápido. Isso alimenta o Nitrogênio e o Abaixo-Assinado. Adesivo rende pouco: o dado bom sai raramente numa bolsa grande.
- **Inventário:** a cruz tem a linha do meio com 5 casas (Reta 4 + 1). Cabem Cruz, T, L e Retas 3; não cabe 2×2 nos braços.
- **Ponto fraco:** precisa de quantidade, não de qualidade. Magias de exigência exata (um 6, um 1) quase nunca acham o dado. O Hidrogênio é inútil para ele. Inimigos que cortam a mão (Interrupção Rude, Rasteira) derrubam o Abaixo-Assinado.
- **Combos do catálogo:** Presença Imponente (bloqueio por dado na mão), Exibição de Velocidade (se o Nitrogênio não passar de 3), Golpe para a Foto (4 dados ≥ 5: o Nitrogênio facilita).

---

## 3. O que é novo

### 3.1 Magias

| Magia | Formato | Grupo | Pede | Efeito | Uso | De quem |
|---|---|---|---|---|---|---|
| **Obra-Prima** | L (4) | Perfeccionista | **3 dados iguais** | Dano = soma ×2. | sempre | Perfeccionista |
| **Abaixo-Assinado** | Reta 4 | Populista | 4 dados quaisquer | Dano = soma + 1 para cada 2 dados na sua bolsa. | sempre | Populista |

- **Exigência nova: "trio"** (3 dados iguais). Os buracos mostram "=" entre os três.
- As duas entram no catálogo e na loja para todos, como as outras.

### 3.2 Elemento

| Elemento | Efeito | Na loja? |
|---|---|---|
| **Nitrogênio** | Multidão: +1 em cada face para cada 4 dados na bolsa. | sim |

Já estava na `SPEC_v3.md` §4.1. O bônus conta a bolsa inteira (descarte e dados fora da luta também) e é calculado ao rolar.

### 3.3 Regras

| Regra | Onde | O que muda |
|---|---|---|
| **Destruir na recompensa** | Minimalista | A tela de recompensa pós-luta ganha uma 4ª opção: "destruir 1 dado". |
| **Chumbo à venda** | Metalurgista | A Loja oferece "dado de Chumbo" e o Poço oferece "aplicar Chumbo". Só para ele. |
| **Mesa de Empréstimo** | Copista | Área separada do inventário, 2×2, que só recebe a cópia. A cópia não pode ser vendida, evoluída nem movida. |
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
| Populista | Assassino + Abaixo-Assinado |

---

## 4. Como inimigos

| Arquétipo | Como luta | Variante proposta |
|---|---|---|
| **Minimalista** | Bate forte e cedo, morre rápido. Vida do inimigo ×0,8 para compensar o Hidrogênio. | **Monge do Silêncio**: só 4 dados, todos Hidrogênio. Aparece a partir do andar 5. |
| **Metalurgista** | Lento e resistente; a passiva vale para ele. | **Fundidor**: no primeiro turno, transforma 1 dado comum **seu** em Chumbo até o fim da luta (diferente do Lixeiro, que adiciona). |
| **Copista** | **Copia a sua maior magia que cabe na Mesa.** A sua build vira a arma dele. | — |
| **Perfeccionista** | A IA guarda os dois dados de valor mais repetido. | — |
| **Populista** | Mão de 6 e bolsa grande, sempre visível. O Arrancar das Mãos rende pouco contra ele. | **Cabo Eleitoral**: no primeiro turno, põe 1 dado comum na **sua** bolsa até o fim da luta (dilui, mas não fica depois). |

---

## 5. Combos para o simulador medir primeiro

| Combo | Por quê |
|---|---|
| Minimalista no andar 1 | Duas Faíscas com Hidrogênio podem matar em 1 turno quando sai 18 + 18. Medir a chance. |
| Minimalista + Bis! | Hidrogênio na face máxima rola de novo e soma ×3 a cada rolagem. Pode passar de 100. |
| Metalurgista contra o Porteiro | O Mestre do andar 10 vira o melhor matchup dele. |
| Copista contra Feiticeiro com Matemática Superior | Não cabe na Mesa (Cruz): medir quantas lutas ele fica sem cópia útil. |
| Copista inimigo contra o jogador | Copiar a magia do jogador pode ser forte demais quando o jogador tem uma Bola de Fogo nível 3. |
| Perfeccionista com Obra-Prima evoluída | Três 12 com nível 3 = 144. Medir em que andar isso aparece. |
| Populista com 30 dados | Abaixo-Assinado com +15 e Nitrogênio +7 em cada face. Medir se a bolsa cresce rápido demais com a Aclamação. |

---

## 6. Em aberto

| Tema | Pergunta |
|---|---|
| Vida dos personagens | 70 a 100: o simulador deve dizer se a ordem (Minimalista mais frágil, Metalurgista mais resistente) faz sentido. |
| Feiticeiro e Assassino | Continuam como os "genéricos" ou são substituídos pelos novos? O Assassino ainda não é jogável. |
| Escolha de personagem | Todos liberados desde o começo (a SPEC não tem meta-progressão no protótipo). |
| Nomes | Os cinco são substantivos que servem para qualquer gênero (TOM §5). |
