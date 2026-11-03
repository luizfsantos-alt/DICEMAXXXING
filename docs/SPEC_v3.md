# DICEMAXXING — Direção v3 (rascunho)

> **Status: rascunho de direção.** Saiu da conversa de design sobre "batalhas parecidas demais, sem sensação de progresso". O código atual ainda segue a [`SPEC.md`](SPEC.md) (v2). Os números aqui são pontos de partida, não balanceamento.

---

## 0. O que muda em relação à v2

| v2 | v3 |
|---|---|
| Sempre 6d6 iguais | **Bolsa de dados** que cresce, encolhe e se modifica |
| Escolher 3 ativos; o resto vira autodano | **Magias pedem dados**; quem não serve a nenhuma magia volta para a bolsa |
| Autodano como regra geral | Autodano/veneno só como **propriedade de alguns elementos** (Urânio) |
| 1 arma + 1 defesa + 3 itens | **Grimório**: grade onde as magias, com formatos, precisam caber |
| Gladiador | **Personagens jogáveis por arquétipo** (Mago, Assassino) |
| 30 lutas em linha, vida cheia a cada luta | **Torre** com bifurcações, **vida persistente** |
| Inimigos sem itens | Inimigos com **bolsa e grimório visíveis**, nos mesmos arquétipos |
| Dano de 10 a 20 do começo ao fim | **Números explodem** pelas faces dos dados e pela evolução das magias |

**Mantém:** só dados d6; resolução simultânea; tudo visível depois da rolagem; **perdeu, morreu** (a jornada zera); tom brainrot BR nos nomes.

---

## 1. Pilares

1. **O dado é a build.** O progresso está escrito nos dados: faces alteradas, elementos.
2. **Profundidade fora do turno, turno rápido.** O quebra-cabeça pesado é montar a bolsa e o grimório; o turno é "qual dado vai em qual magia".
3. **Química é tempero, não tema.** Os elementos dão nome e personalidade aos dados. Não há reações, fusão nem tabela para decorar.
4. **Cada luta tem outra leitura.** Ela vem do inimigo (arquétipo, bolsa e grimório dele), não de regras novas.

---

## 2. Torre

- O jogador sobe uma torre andar por andar. **Perder uma luta = fim da jornada.**
- **A vida não é restaurada entre as lutas.** A cura é recurso: parada de Cura, magias, elementos.
- **Bifurcação comum** (antes de cada luta): 2 ou 3 portas de **dificuldade diferente**. O inimigo não é revelado; só a dificuldade e a recompensa.
- **Trifurcação sem combate** (a cada 3 ou 4 lutas): escolhe-se uma entre
  - **Loja**: magias, dados, modificações.
  - **Cura**: recupera vida.
  - **Escola de Magia**: aprender uma magia ou **evoluir** uma conhecida (mais efeito, menos exigência ou formato menor).
  - **Poço de Modificação**: aplicar elemento, adesivo ×2, editar face, destruir dado.
- **Recompensa pós-luta:** escolher 1 entre 3 (dado, modificação ou magia simples), ou pular e levar moedas.
- **Mestre de Andar** (chefe) a cada 10 andares, com uma regra própria e recompensa grande: espaço no grimório ou +1 na mão.
- Protótipo sugerido: andares 1–30, três Mestres.

---

## 3. Personagens

Jogáveis, escolhidos no início. **O formato do inventário é a identidade.** As peças podem girar.

| Personagem | Inventário | Estilo | Magias iniciais |
|---|---|---|---|
| **Mago** | Grimório **4×3** | Magias grandes e exigentes (pares, sequências), efeitos fortes, muitas com uso único por luta | Faísca, Escudo Arcano, Bola de Fogo |
| **Assassino** | Cinto **6×1** | Técnicas finas que aceitam quase qualquer dado; força na quantidade | Estocada, Esquiva, Corte Duplo |

A loja é a mesma para todos, mas peças 2×2 ou em L simplesmente não cabem num cinto. Cada personagem "enxerga" um mundo diferente na mesma loja.

Personagens futuros: outros formatos de inventário (ex.: cruz, 2×5, grade com buracos).

---

## 4. Bolsa de dados

- Começa com **8 d6 comuns**. Todos os dados são d6, sempre.
- Por turno, **tira 5 dados** (a "mão") e rola. Os usados e os não usados vão para o descarte; quando a bolsa esvazia, o descarte volta para ela.
- **Adicionar dados tem consequência real:** dilui os bons, mas alimenta dados que gostam de bolsa grande.
- **Destruir dados é caro:** Poço de Modificação, com preço crescente por jornada.
- A mão cresce com recompensas raras (Mestres): 5 → 6 → 7.

### 4.1 Elementos (tempero)

Cada dado pode ter **um** elemento. O efeito vem de uma característica real, escrito em uma linha.

| Elemento | Efeito |
|---|---|
| **Hidrogênio** | Solitário: vale ×3 se a bolsa tiver 8 dados ou menos. |
| **Nitrogênio** | Multidão: +1 em cada face para cada 4 dados na bolsa. |
| **Carbono** | Cadeia: +1 para cada outro Carbono na bolsa. |
| **Ósmio** | Âncora: sempre sai na primeira mão de cada luta; não pode ser roubado. |
| **Oganessônio** | Faces enormes; desintegra (sai da bolsa) após 1 uso. |
| **Urânio** | Valor alto; se ficar na mão sem uso, **envenena** você (acumula entre turnos). |
| **Chumbo** | **3 faces são 1 fixo** (não podem ser editadas). Normalmente é lixo que o inimigo põe na sua bolsa. |
| **Sódio** | Ao ser usado, **queima** o inimigo (dano por alguns turnos). |
| **Mercúrio** | Amálgama: copia o valor do **maior dado da mesa** (dos dois lados). |
| **Ferro** | Magnético: ao sair, puxa outro Ferro da bolsa para a mão. |
| **Ouro** | Ao ser usado com 6, dá moedas. |
| **Hélio** | Inerte: imune a efeitos do inimigo. |
| **Vidro** (molécula) | Valor ×2; 1 chance em 6 de quebrar ao ser usado. |

### 4.2 Faces

- **Adesivo ×2:** dobra aquela face **para sempre**; acumula (6 → 12 → 24).
- **Editar face:** troca o número de uma face (ex.: 1 → 5).
- É por aqui que **os números explodem**. Um 24 é ótimo numa Faísca e inútil numa magia que pede "dado ≤ 3".

---

## 5. Magias

Cada magia tem **formato** (no grimório), **exigência** (quais dados aceita), **efeito** e **uso** (sempre ou **1× por luta**).

| Magia | Formato | Pede | Efeito | Uso |
|---|---|---|---|---|
| Faísca | 1×1 | qualquer dado | dano = valor | sempre |
| Estocada | 1×1 | qualquer dado | dano = valor +1 | sempre |
| Escudo Arcano | 1×2 | dado ≤ 3 | bloqueio = valor ×3 | sempre |
| Esquiva | 1×1 | dado ≤ 2 | anula o maior golpe inimigo do turno | 1× por luta |
| Corte Duplo | 2×1 | dois dados | soma; se ambos ímpares, golpeia de novo | sempre |
| Bola de Fogo | 2×2 | dois iguais | soma ×3 e queima | 1× por luta |
| Meteoro | L (4 casas) | sequência de 3 | 40 de dano | 1× por luta |
| Espelho | 1×1 | um 1 | reflete o próximo golpe recebido | sempre |
| Golpe nas Sombras | 3×1 | um 6 | dano ignora bloqueio | 1× por luta |
| Sacrifício | 1×1 | um 1 | destrói o dado usado; +5 de dano em todas as magias nesta luta | sempre |

- **Cada dado alimenta uma magia por turno; cada magia é usada no máximo 1 vez por turno.**
- **Formatos que não combinam** são o custo das magias fortes: o L do Meteoro deixa buracos que só peças 1×1 tapam.
- O **grimório se mantém** entre as lutas; reorganizar é opcional, antes de cada luta.
- Evoluir uma magia (Escola de Magia) aumenta o efeito, afrouxa a exigência ou diminui o formato.

---

## 6. Turno

1. **Início:** veneno, queima e outros efeitos contínuos.
2. **Rolagem:** os dois lados tiram a mão da bolsa e rolam; todos veem tudo. Efeitos de dado (Mercúrio, Ferro…).
3. **Alocação simultânea:** cada lado põe dados nas magias. Tudo é reversível até "Terminar turno".
4. **Resolução:** proteções (bloqueio, esquiva, espelho) → dano → curas → efeitos de fim (Urânio na mão envenena, Vidro quebra, Sacrifício destrói).
5. **Descarte:** todos os dados da mão vão para o descarte.
6. Vida 0 = derrota. Empate = derrota do jogador.

---

## 7. Inimigos

- Seguem **os mesmos arquétipos** dos personagens, **inclusive o formato do inventário** (Mago inimigo com grimório 4×3, Assassino inimigo com cinto 6×1).
- **Bolsa e grimório visíveis** (composição da bolsa, não a ordem). É isso que diferencia uma luta da outra.
- **Contaminação:** cada inimigo pode pôr um dado-lixo na sua bolsa, que fica com você depois da luta (Chumbo, Urânio...).
- Variantes dentro do arquétipo pelo conteúdo: o "Lixeiro" (Assassino que joga Chumbo), o "Piromante" (Mago de Sódio e Bola de Fogo) etc.
- A IA reaproveita as personalidades da v2 (Bruto, Cauteloso, Caótico), adaptadas para escolher magias.

---

## 8. Reaproveitamento do motor atual

| Hoje (v2) | Na v3 |
|---|---|
| Requisitos de valor da defesa (`DEFENSE_REQUIREMENTS`), par, trio e sequência (Martelo, Lança, Arco) | Viram **exigências de magia** |
| Escudo, Espelho, espinhos, cura, anulação (`resolver.gd`) | Viram **efeitos de magia** |
| Eventos do motor (`rep.events`) e animação da resolução | Continuam; ganham tipos novos (veneno, queima, quebra) |
| `Duel`, `RunState`, `SaveGame`, simulador, testes GUT | Base mantida; mudam os dados do lutador (bolsa + grimório) e a progressão (torre) |
| `Fighter.dice` (6 inteiros) | Vira **bolsa de objetos** (faces + elemento) |
| Equipamentos, itens, autodano geral | Saem |

---

## 9. Em aberto

- **Escala:** a vida do jogador também cresce, ou fica pequena enquanto o dano explode?
- Tamanho da bolsa inicial e da mão (8 / 5).
- Quantas portas por bifurcação e o ritmo das trifurcações (3 ou 4 lutas).
- Lista final de magias por personagem e da loja; regras dos Mestres de Andar.
- Como o jogador vê a bolsa do inimigo na tela em paisagem.
- Meta-progressão entre jornadas (ex.: desbloquear magias e personagens).
