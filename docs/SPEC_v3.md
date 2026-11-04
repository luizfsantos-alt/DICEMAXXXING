# DICEMAXXING — Especificação v3

> **Status: fonte da verdade.** Saiu da conversa de design sobre "batalhas parecidas demais, sem sensação de progresso". A **fatia vertical** (seção 12) está implementada. Os números marcados com *(inicial)* são pontos de partida; os valores em uso estão em `engine/config.gd`.

---

## 0. O que muda em relação à v2

| v2 | v3 |
|---|---|
| Sempre 6d6 iguais | **Bolsa de dados** que cresce, encolhe e se modifica |
| Escolher 3 ativos; o resto vira autodano | **Magias pedem dados**; quem não serve a nenhuma magia volta para a bolsa |
| Autodano como regra geral | Veneno só como **propriedade de alguns elementos** (Urânio) |
| 1 arma + 1 defesa + 3 itens | **Inventário com formato**, onde as magias precisam caber |
| Gladiador | **Feiticeiro** e **Assassino** jogáveis |
| Turno simultâneo | **Turnos sequenciais** |
| 30 lutas em linha, vida cheia a cada luta | **Torre** com portas, **vida persistente** |
| Inimigos sem itens | Inimigos montados **com as mesmas regras do jogador** |
| Dano de 10 a 20 do começo ao fim | **Números explodem para os dois lados** |

**Mantém:** só dados d6; **perdeu, morreu** (a jornada zera); offline, Android, paisagem. **Tom:** antes brainrot BR, agora **duelo de egos entre magos** (`docs/TOM.md`).

---

## 1. Pilares

1. **O dado é a build.** O progresso está escrito nos dados: faces alteradas, elementos.
2. **Profundidade fora do turno, turno rápido.** O quebra-cabeça pesado é montar a bolsa e o inventário; o turno é "qual dado vai em qual magia".
3. **Química é tempero, não tema.** Os elementos dão nome e personalidade aos dados. Não há reações, fusão nem tabela para decorar.
4. **Cada luta tem outra leitura.** Ela vem do inimigo (arquétipo, bolsa, inventário), não de regras novas.
5. **Inimigos seguem as mesmas regras.** Nunca são inofensivos, nem na aparência.

---

## 2. Torre

- O jogador sobe uma torre andar por andar. **Perder uma luta = fim da jornada.** Empate = derrota do jogador.
- **Protótipo: 30 andares.**
- **A vida não é restaurada entre as lutas.**
- **Portas** (antes de cada luta): normalmente **2**, às vezes **3** (a terceira é uma porta "insana", que paga muito). Cada porta mostra **só a dificuldade e a recompensa**; o inimigo e o arquétipo dele ficam ocultos até a luta começar.
- **Trifurcação sem luta, a cada 3 lutas.** Escolhe-se uma entre:
  - **Loja**: magias, dados, vida máxima.
  - **Cura**: recupera vida (*inicial: 50% da vida máxima*).
  - **Escola de Magia**: aprender uma magia ou **evoluir** uma conhecida.
  - **Poço de Modificação**: aplicar elemento, adesivo ×2, editar face, destruir dado.
- **Recompensa pós-luta:** escolher 1 entre 3 (dado, modificação, magia simples ou vida máxima), ou pular e levar moedas.
- **Mestre de Andar** nos andares 10, 20 e 30 (seção 8.3). A recompensa é escolher uma: **+casas no inventário** ou **+1 dado na mão**.

### 2.1 Escala e vida

- **Tudo cresce junto.** Os inimigos têm faces com adesivo ×2, magias evoluídas e vida maior a cada andar.
- **Vida máxima é investimento:** comprar ou gerar vida na hora certa disputa moedas e escolhas com dados e magias.
- Fontes de vida: Loja (vida máxima, preço crescente), Cura (recupera, não aumenta a máxima), magias de vida, recompensa pós-luta.

---

## 3. Personagens

Jogáveis, escolhidos no início. O **formato do inventário** é a identidade; cada personagem tem também **uma passiva simples**. As peças podem girar.

| Personagem | Inventário | Passiva | Vida *(inicial)* | Magias iniciais |
|---|---|---|---|---|
| **Feiticeiro** | Grade **4×3** | **Erudito**: começa com 1 magia extra, à escolha entre 3. | 50 | Faísca, Escudo Arcano, Bola de Fogo |
| **Assassino** | Cinto **6×1** | **Ágil**: mão de **6** dados (em vez de 5). | 40 | Estocada, Esquiva, Corte Duplo |

- **Feiticeiro**: magias grandes e exigentes (pares, sequências), efeitos fortes, várias de uso único por luta.
- **Assassino**: técnicas finas que aceitam quase qualquer dado; força na quantidade e na esquiva.
- A loja é a mesma para todos, mas peças 2×2 ou em L não cabem num cinto.
- **Futuro:** vários outros arquétipos, cada um com um formato de inventário próprio (ex.: cruz, 2×5, grade com buracos). Inimigos ganham os mesmos arquétipos quando eles forem criados.

---

## 4. Bolsa de dados

- Começa com **8 d6 comuns** *(inicial)*. Todos os dados são d6, sempre.
- **Cada luta começa com a bolsa cheia e embaralhada.**
- No início do seu turno você **tira a mão** (5 dados; 6 para o Assassino) e rola.
- No fim do turno, todos os dados da mão vão para o **descarte**. Quando a bolsa esvazia, o descarte volta para ela.
- **Adicionar dados tem consequência real:** dilui os bons, mas alimenta dados que gostam de bolsa grande.
- **Destruir dados é caro:** Poço de Modificação, preço crescente por jornada *(inicial: 10 moedas, +10 por uso)*.
- **Dados-lixo** que um inimigo põe na sua bolsa **ficam com você depois da luta**, até serem destruídos. Só alguns inimigos fazem isso.

### 4.1 Elementos

Cada dado pode ter **um** elemento, além de qualquer número de adesivos. O efeito vem de uma característica real, escrito em uma linha.

| Elemento | Efeito |
|---|---|
| **Hidrogênio** | Solitário: vale ×3 se a bolsa tiver 8 dados ou menos. |
| **Nitrogênio** | Multidão: +1 em cada face para cada 4 dados na bolsa. |
| **Carbono** | Cadeia: +1 para cada outro Carbono na bolsa. |
| **Ósmio** | Âncora: sempre sai na primeira mão de cada luta; não pode ser roubado. |
| **Oganessônio** | Faces enormes; desintegra (sai da bolsa) após 1 uso. |
| **Urânio** | Valor alto; se ficar na mão sem uso até o fim do seu turno, **envenena** você (acumula). |
| **Chumbo** | **3 faces são 1 fixo** (não podem ser editadas). Normalmente é lixo posto pelo inimigo. |
| **Sódio** | Ao ser usado, **queima** o inimigo por alguns turnos. |
| **Mercúrio** | Amálgama: copia o maior valor entre a sua mão e a **última mão do inimigo**. |
| **Ferro** | Magnético: ao sair, puxa outro Ferro da bolsa para a mão. |
| **Ouro** | Ao ser usado com 6, dá moedas. |
| **Hélio** | Inerte: imune a efeitos do inimigo. |
| **Vidro** (molécula) | Valor ×2; 1 chance em 6 de quebrar ao ser usado. |

### 4.2 Faces

- **Adesivo ×2:** dobra aquela face **para sempre**; acumula (6 → 12 → 24). O preço sobe a cada adesivo no mesmo dado.
- **Editar face:** troca o número de uma face (ex.: 1 → 5).
- É por aqui que **os números explodem**. Um 24 é ótimo numa Faísca e inútil numa magia que pede "dado ≤ 3".

---

## 5. Magias

Cada magia tem **formato** (no inventário), **exigência** (quais dados aceita), **efeito** e **uso** (sempre ou **1× por luta**).

| Magia | Formato | Pede | Efeito | Uso |
|---|---|---|---|---|
| Faísca | 1×1 | qualquer dado | dano = valor | sempre |
| Estocada | 1×1 | qualquer dado | dano = valor +1 | sempre |
| Escudo Arcano | 1×2 | dado ≤ 3 | bloqueio = valor ×3 | sempre |
| Esquiva | 1×1 | dado ≤ 2 | anula o **próximo golpe** do inimigo | 1× por luta |
| Corte Duplo | 2×1 | dois dados | soma; se ambos ímpares, golpeia de novo | sempre |
| Bola de Fogo | 2×2 | dois iguais | soma ×3 e queima | 1× por luta |
| Meteoro | L (4 casas) | sequência de 3 | 40 de dano | 1× por luta |
| Espelho | 1×1 | um 1 | reflete o próximo golpe recebido | sempre |
| Golpe nas Sombras | 3×1 | um 6 | dano ignora bloqueio | 1× por luta |
| Sacrifício | 1×1 | um 1 | destrói o dado usado; +5 de dano em todas as magias nesta luta | sempre |
| Remendo | 1×1 | qualquer dado | cura = valor | 1× por luta |
| Transfusão | 2×1 | dois iguais | +valor de um deles na vida máxima, permanente | 1× por luta |

- **Cada dado alimenta uma magia por turno; cada magia é usada no máximo 1 vez por turno.**
- **Cópias da mesma magia são permitidas**, se couberem no inventário.
- Se nenhuma magia aceita os dados da mão, **o turno passa em branco**.
- **Formatos que não combinam** são o custo das magias fortes.
- O inventário **se mantém** entre as lutas; reorganizar é opcional, antes de cada luta. Ele **só cresce pelos Mestres de Andar**.
- **Evolução: 3 níveis.** Cada nível melhora uma coisa: efeito, exigência ou formato (Escola de Magia).
- Magias podem ser **vendidas** por metade do preço.

---

## 6. Turno (sequencial)

Os lados se alternam. **O jogador começa** *(inicial; o simulador avalia se o primeiro turno precisa de compensação)*.

**Turno de um lado:**
1. **Início:** veneno e queima desse lado causam dano. Os bloqueios que **esse lado** criou no turno anterior somem (ver abaixo).
2. **Mão:** tira os dados da bolsa e rola. Efeitos de dado (Ósmio, Ferro, Mercúrio, Vidro…).
3. **Alocação:** põe dados nas magias. Tudo é reversível até "Terminar turno". Durante a alocação o jogador vê a vida, os bloqueios, a bolsa (composição) e o inventário do inimigo, e a última mão dele.
4. **Resolução:** as magias acontecem na ordem dos slots do inventário (da esquerda para a direita, de cima para baixo), com animação.
5. **Fim:** Urânio que ficou na mão envenena; Vidro usado testa a quebra; Sacrifício e Oganessônio saem da bolsa; a mão vai para o descarte.
6. **Morte:** quem chega a 0 de vida perde imediatamente.

**Bloqueio e proteções:** duram **até o fim do turno seguinte do adversário**, salvo quando a magia diz explicitamente outra coisa. Na prática: você se protege no seu turno e a proteção vale contra o ataque que vem logo depois; ela some no início do seu próximo turno.

- **Trava de segurança:** se a luta chegar ao **turno 60** (contando os dois lados), conta como derrota do jogador.

---

## 7. Economia *(valores iniciais)*

- Vitória: moedas conforme a porta (fácil < normal < insana).
- Preços: magia, dado novo, elemento, adesivo ×2 (crescente por dado), editar face, destruir dado (crescente por jornada), vida máxima (crescente por compra).
- Valores exatos em `engine/config.gd` quando implementado.

---

## 8. Inimigos

### 8.1 Princípios
- **Mesmos arquétipos** dos personagens (Feiticeiro e Assassino no protótipo), **inclusive o formato do inventário**.
- **Bolsa (composição), inventário, vida e bloqueios visíveis**, consultáveis a qualquer momento.
- **Montados como um jogador:** um inimigo do andar N recebe o orçamento de recompensas de uma jornada de N andares e "compra" na mesma loja, com as mesmas regras. A dificuldade da porta escala esse orçamento *(inicial: fácil 80%, normal 100%, insana 130%)*.
- A vantagem do jogador é a **sinergia**: o inimigo monta de forma genérica.
- Variantes de conteúdo dentro do arquétipo: o **Lixeiro** (Assassino que põe Chumbo na sua bolsa), o **Piromante** (Feiticeiro de Sódio e Bola de Fogo) etc.
- IA: reaproveita as personalidades da v2 (Bruto, Cauteloso, Caótico), adaptadas para escolher magias.

### 8.2 Contaminação
Alguns inimigos põem dados-lixo na sua bolsa durante a luta. **Os dados-lixo ficam depois da luta**, até serem destruídos no Poço.

### 8.3 Mestres de Andar (protótipo)

| Andar | Mestre | Regra |
|---|---|---|
| 10 | **Porteiro de Chumbo** | No início de cada turno seu, põe 1 Chumbo na sua mão (só durante a luta). |
| 20 | **A Alquimista** | No início de cada turno seu, o seu maior dado troca de valor com o menor dado da última mão dela (reaproveita a Corrente da v2). |
| 30 | **O Reator** | Bolsa cheia de Urânio. No fim de cada turno, **todo** dado que sobrou na mão envenena quem o rolou (dos dois lados). |

---

## 9. Meta-progressão

- **Nenhuma no protótipo.**
- Futuro: desbloquear personagens e magias novas na loja, **sem poder permanente**.

---

## 10. Reaproveitamento do motor atual

| Hoje (v2) | Na v3 |
|---|---|
| Requisitos de valor da defesa (`DEFENSE_REQUIREMENTS`), par, trio e sequência (Martelo, Lança, Arco) | Viram **exigências de magia** |
| Escudo, Espelho, espinhos, cura, anulação, Corrente (`resolver.gd`) | Viram **efeitos de magia** e regra da Alquimista |
| Eventos do motor (`rep.events`) e animação da resolução | Continuam; ganham tipos novos (veneno, queima, quebra) |
| `Duel`, `RunState`, `SaveGame`, simulador, testes GUT | Base mantida; o duelo passa a alternar turnos; mudam os dados do lutador (bolsa + inventário) e a progressão (torre) |
| `Fighter.dice` (6 inteiros) | Vira **bolsa de objetos** (faces + elemento) |
| Personalidades da IA | Adaptadas para escolher magias |
| Equipamentos, itens, autodano geral, resolução simultânea | Saem |

---

## 11. Próximo passo

Jogar a fatia vertical e decidir o que ajustar antes de investir em conteúdo.

---

## 12. Fatia vertical (implementada)

**Escopo:** só o Feiticeiro jogável; inimigos Feiticeiro e Assassino (com as variantes Lixeiro e Piromante); 6 elementos (Hidrogênio, Ósmio, Urânio, Sódio, Mercúrio e Chumbo); 11 magias (as 10 da seção 5, menos Golpe nas Sombras, mais as 3 do Assassino); 10 andares com portas, trifurcação a cada 3 lutas e o Porteiro de Chumbo no andar 10. Vencer o andar 10 encerra a jornada.

**Decisões tomadas na implementação** (revisar depois de jogar):
- **Evolução** de magia só melhora o **efeito** (×1; ×1,5; ×2). Melhorar exigência ou formato fica para depois.
- **Urânio**: faces 3 a 8. **Chumbo** (lixo): faces 1, 1, 1 (travadas), 2, 2, 3.
- **Queima**: causa o valor acumulado no início do turno de quem queima e cai 1 por turno. **Veneno** não cai durante a luta.
- **Espelho e Esquiva** valem até o início do próximo turno de quem os ergueu, como o bloqueio.
- **Lixeiro**: no primeiro turno dele, põe 1 Chumbo na sua bolsa (permanente).
- **Adicionar magia** reorganiza o grimório sozinho quando ela só cabe mexendo nas outras peças. "Não cabe" só aparece quando nenhum arranjo serve.
- **Arranjo inicial** do Feiticeiro deixa um espaço em L, para o Meteoro caber.
- **Recompensa do Mestre** (+casas ou +1 na mão) não existe na fatia, porque o Mestre é a última luta.
- O inimigo recebe **0,4 melhoria por andar** × o multiplicador da porta (fácil 0,8; normal 1,0; difícil 1,3; insana 1,7).
- **Vida:** Feiticeiro 90; inimigo 36 + 6 por andar (× porta); Mestre ×1,6.

**Simulador** (`sim/simulate.gd`, bot com a IA cautelosa, 400 jornadas): lutas com cerca de 4 turnos de cada lado. Chegam ao fim do andar 10 cerca de 11% pela porta fácil, 9% pela normal e 2% pela difícil. Um humano escolhendo portas, recompensas e paradas deve ir melhor que o bot.

---

## 13. Tela de luta (paisagem)

- **Trilho à esquerda** com os dois personagens: inimigo em cima (tocar abre a ficha completa), você embaixo. Cada um tem espaço para o personagem (placeholder até haver arte), nome, bolsa, vida e efeitos.
- **Magias do inimigo** no alto, **bandeja da mão** no meio com "Terminar turno", **suas magias** embaixo, perto do polegar.
- Na luta, toda magia é um **cartão do mesmo tamanho**: nome, efeito curto, "1× por luta"/"usada" e **um buraco por dado pedido**. O formato só importa no grimório.
- **Buracos:** a exigência fica escrita no fundo do buraco vazio ("≤ 3", "1"); par = dois buracos ligados por "=". Com um dado selecionado, os buracos que o aceitam acendem e as magias que não aceitam apagam ("não aceita 6"). A mão também é uma bandeja de buracos: o dado que sai deixa o buraco com o nome da magia.
- **Prévia** no cartão ("→ 5 de dano") e resumo do turno embaixo da mão.
- **Sem registro fixo:** o resultado aparece no lugar (números sobre a vida, cartão do inimigo aceso com os dados que ele usou) e um **resumo do turno do inimigo** fica até você tocar num dado. O histórico completo abre pelo botão **Histórico**.
- **Os dois lados rolam no centro.** Na vez do inimigo, a mão dele rola na mesma bandeja e cada dado voa até o buraco da magia dele, na ordem do inventário. Os dados ficam nos cartões do inimigo até o próximo turno dele.

### 13.1 Grimório (organizar as magias)

- É o **único lugar onde o formato importa**. Grade grande à esquerda; à direita, o cartão da peça tocada (nome, descrição, casas e a ordem em que acontece na luta).
- Cada peça mostra um **número**: a ordem de resolução (de cima para baixo, da esquerda para a direita).
- Toque numa peça para levantá-la, "Girar" para girar, toque numa casa para soltar.
- **Sempre que o jogador ganha uma magia** (Loja, Escola, recompensa, Erudito), o grimório abre sozinho com a peça nova marcada **NOVA**, já encaixada onde couber, para ele reorganizar antes de seguir.
