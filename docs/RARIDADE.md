# Raridade de magias e dados (proposta)

> **Status: implementado.** Classes aprovadas (rodada 1). Código: `engine/shop.gd` (sorteio e preços), `engine/spells.gd` e `engine/elements.gd` (classe de cada item), `engine/enemy_factory.gd` (compras dos inimigos). O simulador mostra, por magia, ofertas, escolhas e vitórias com `--spells`. Cada magia e cada dado com elemento recebe uma **classe de raridade**. A classe controla a **chance de aparecer** nas ofertas, o **preço** e **a partir de quando os inimigos podem ter**. O efeito da magia não muda com a raridade. Números *(iniciais)*, a passar pelo simulador. Inclui as magias e o Amianto propostos em `docs/PERSONAGENS.md`.

---

## Feedback (rodada 1)

| Tema | Decisão |
|---|---|
| Classes | **Mantidas** as três (Comum, Incomum, Rara). A Lendária fica para depois. |
| Evolução de Rara | Custa o **preço de uma magia Rara** (18) na Escola. |
| Recompensa do Mestre | Ganha a opção "magia Rara". |
| Ósmio | Passa a sair **em toda mão** (`docs/PERSONAGENS.md` §5.3) e sobe para **Raro**. |

---

## 1. Para que serve

| Hoje | Com raridade |
|---|---|
| Toda magia tem a mesma chance de aparecer (1 em 58). | As simples aparecem muito; as que mudam a jornada aparecem pouco. |
| Toda magia custa 10 na Loja. | O preço acompanha a força. |
| Um inimigo do andar 2 pode comprar a Matemática Superior. | As magias raras só aparecem nos inimigos mais altos. |
| Para enfraquecer uma magia forte, é preciso mexer no efeito. | Há uma alavanca a mais: **subir a raridade** (aparece menos e custa mais), sem mudar a regra. |

---

## 2. Classes

| Classe | Critério | Cor (borda do cartão e do dado) |
|---|---|---|
| **Comum** | Um efeito direto, número pequeno. Funciona sozinha. | cinza |
| **Incomum** | Exigência específica, efeito condicional, mexida no inimigo ou pico 1× por luta. | azul |
| **Rara** | Multiplica valores, fabrica dados, muda a regra do jogo ou define uma build. | dourada |

---

## 3. Magias

### 3.1 Comuns (23)

| Magia | Por quê |
|---|---|
| Faísca, Estocada, **Dardo Arcano** | As básicas. |
| Corte Duplo, Levantar Peso, Impulso Calculado, **Machadada**, **Mordida** | Dano direto, um dado ou dois. |
| Escudo Arcano, Esquiva, Armadura de Músculo, Pose Congelada | Defesa direta. |
| Remendo, **Cerrar os Dentes**, Imune a Críticas, Suor de Campeão | Cura e limpeza. |
| **Segunda Chance**, **Ajuste Fino**, **Pico**, **Sangria**, **Virar**, **Nivelar**, **Polarizar** | Mexidas simples nos próprios dados (as cinco primeiras são as iniciais dos jogáveis). |

### 3.2 Incomuns (24)

| Magia | Por quê |
|---|---|
| Bola de Fogo, Meteoro, Golpe nas Sombras, Lição de Anatomia, Expectativa Tóxica | Pico forte, 1× por luta ou exigência difícil. |
| **Obra-Prima**, **Banquete**, Exibição de Velocidade | Muitos dados ou trio. |
| Plágio, Roubar a Cena, Arrancar das Mãos | Mexem na bolsa ou na mão do inimigo. |
| Meia Verdade, Interrupção Rude, Rasteira Humilhante | Enfraquecem a próxima mão do inimigo. |
| Espelho, Revide Elegante, Recuo Estratégico, Presença Imponente, Concentrar Força, Transfusão | Defesa ou ganho com condição. |
| **Eco**, **Inflar**, **Juntar Cacos**, **Escada** | Mexidas que fabricam par, dobram ou fundem dados. |

### 3.3 Raras (11)

| Magia | Por quê |
|---|---|
| Matemática Superior, Física Aplicada, Golpe para a Foto, Bis! | Multiplicam valores: com adesivos, passam de 100. |
| Força Desnecessária, Imitação Barata | Fabricam dados: são o motor dos combos. |
| Sacrifício | Mexe na bolsa para sempre e soma em todas as magias. |
| Improviso Brilhante | Transforma a mão inteira em bloqueio. |
| Chave de Braço Didática | Corta pela metade a mão inteira do inimigo. |
| **Tudo ou Nada** | Mexida arriscada: rola de novo e fica com o novo valor ×2. |
| **Lapidar** | Mexida que edita a face do dado para sempre. |

Os **kits iniciais** ignoram a raridade (o Copista começa com a Imitação Barata, que é Rara).

---

## 4. Dados

| Classe | Dados | Por quê |
|---|---|---|
| **Comum** | Sódio, **Amianto**, **Carbono**, **Ouro**, **Lítio**, **Titânio** | Efeito simples, sem risco grande. O Carbono só rende em quantidade, por isso é comum. O Lítio pede paciência (carrega parado); o Titânio é a defesa simples. |
| **Incomum** | Urânio, Mercúrio, **Césio**, **Estrôncio** | Valor alto com custo, valor que depende do inimigo, ou dano que se acumula (o veneno do Césio não cai sozinho). |
| **Raro** | Hidrogênio, Ósmio | O Hidrogênio (×3) define a build da bolsa pequena. O Ósmio sai em toda mão: com adesivos, é um valor alto garantido todo turno. |
| — | Chumbo | Lixo: só o inimigo dá. Para o Metalurgista, conta como Comum. |

**Adesivo de ouro** (Loja e Poço, 8 moedas): marca uma face; cada vez que ela é usada numa magia, +1 moeda. **Copiar um dado** (Loja, 12 moedas): uma cópia exata de um dado da bolsa (elemento, faces e adesivos) entra na bolsa.

O **dado sem elemento** não tem classe: pela proposta de `docs/PERSONAGENS.md` §5.3, ele deixa de ser oferecido. **Adesivo +2** e **editar face** são modificações, não dados: ficam fora da raridade.

---

## 5. Chance de aparecer

Cada oferta de magia ou dado sorteia primeiro a **classe** e depois um item dentro dela. As chances mudam com o andar:

| Andares | Comum | Incomum | Rara |
|---|---|---|---|
| 1 a 3 | 70% | 25% | 5% |
| 4 a 6 | 55% | 32% | 13% |
| 7 a 10 | 45% | 35% | 20% |

**Chance de uma magia específica** em cada oferta (dividida pelo número de magias na classe):

| Andares | Uma Comum | Uma Incomum | Uma Rara |
|---|---|---|---|
| 1 a 3 | 4,4% | 1,2% | 0,6% |
| 4 a 6 | 3,4% | 1,6% | 1,4% |
| 7 a 10 | 2,8% | 1,8% | 2,2% |

**Chance de um dado específico** em cada oferta de dado (2 em cada classe): no andar 1, cada Comum tem 35%, cada Incomum 12,5% e cada Raro 2,5%. Nos andares 7 a 10: 22,5%, 17,5% e 10%.

### 5.1 Onde as chances mudam

| Lugar | Regra |
|---|---|
| **Recompensa pós-luta** | Usa a tabela do andar. A **porta difícil** sobe uma faixa (andar 2 sorteia como 4 a 6). A **porta insana** garante uma opção Rara. |
| **Loja** | Usa a tabela do andar. |
| **Escola de Magia** | A 1ª magia usa a tabela; a 2ª é **no mínimo Incomum**. |
| **Poço** | Os elementos para aplicar usam a tabela do andar. |
| **Inimigos** | Compram com a mesma tabela do andar deles. **Nada Raro antes do andar 4.** |

---

## 6. Preço

| Classe | Magia (Loja) | Dado com elemento (Loja) | Aplicar elemento (Poço) | Venda da magia |
|---|---|---|---|---|
| Comum | 8 | 8 | 6 | 4 |
| Incomum | 12 | 11 | 9 | 6 |
| Rara | 18 | 15 | 13 | 9 |

Hoje: magia 10, dado 6 (+8 com elemento), elemento no Poço 8, venda pela metade. A venda continua sendo a metade do preço.

---

## 7. Como a raridade ajuda o balanceamento

1. O simulador registra, por magia e por dado: quantas vezes foi oferecido, escolhido e quantas jornadas com ele chegaram ao fim.
2. **Muito escolhido e vencendo muito:** sobe uma classe (aparece menos e custa mais). Se já for Rara, aí sim mexer no efeito.
3. **Pouco escolhido:** desce uma classe, ou o efeito precisa melhorar.
4. Os inimigos herdam a correção sozinhos, porque compram pela mesma tabela.

---

## 8. Decisões

| Tema | Decisão |
|---|---|
| Evolução | Na Escola, evoluir uma magia **Rara custa 18** (o preço dela na Loja). Comum e Incomum continuam grátis. |
| Recompensa do Mestre | Três opções, escolher uma: **+casas no inventário**, **+1 dado na mão** ou **uma magia Rara** (escolhida entre 3). |

## 9. Em aberto

| Tema | Pergunta |
|---|---|
| Lendária | **Implementada (0.23.0)** como 4ª classe, só de magias: 1% das ofertas nos andares 1–3 e 2% depois (`Config.RARITY_WEIGHTS`), preço 28, moldura vermelho-brasa (`assets/ui/card_legendary.png`). A primeira é a **Charada Fatal**. Não há elemento Lendário. A porta insana conta a Lendária como "Rara ou melhor". |
