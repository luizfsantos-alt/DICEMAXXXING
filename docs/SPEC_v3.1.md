# DICEMAXXING — Spec v3.1: mexidas, portas, desgaste, Mestres e bot

> **Status: implementada (histórico).** O conteúdo foi incorporado à `docs/SPEC_v3.md` e ao `docs/CATALOGO_MAGIAS.md` (§2.2 e §11); os resultados da calibração estão no fim deste arquivo. Altera a `docs/SPEC_v3.md` e o `docs/CATALOGO_MAGIAS.md`. Saiu da crítica de mecânicas de novembro de 2026. Depois de implementada, o conteúdo entra nos dois documentos e este arquivo vira histórico. Números marcados com *(inicial)* passam pelo simulador.

---

## 0. Objetivo e escopo

**Problemas que esta rodada ataca** (achados da crítica):

| # | Problema | Mudança |
|---|---|---|
| 1+2 | Primeiras lutas sem decisão nem emoção (o maior dado vai na Faísca e o resto fica parado) | **Mexidas**: família nova de magias que modificam os próprios dados; cada personagem jogável começa com uma (§1) |
| 3+9 | A porta fácil domina; o inimigo oculto impede a preparação | A porta mostra o arquétipo; prêmios das portas reprecificados (§2) |
| 4 | Desgaste em espiral; o Mestre é mais fácil que o andar anterior | Cura pequena após cada vitória; Mestres mais fortes, com kit fixo (§3, §4) |
| 5 | O balanceamento é medido com um bot que não monta build | Bot com heurística de valor e telemetria de jornada (§5) |
| 6 | Imitação Barata gera números exponenciais, Sacrifício grátis e vida máxima infinita | Dados devolvidos não alimentam Imitação, Sacrifício nem Transfusão (§6) |
| 7 | O herói multiplica e o inimigo só soma | Inimigos crescem mais depois do andar 10 (§7) |
| 10 | Mudanças na sua mão difíceis de entender | O dado mexido mostra o valor original riscado e a causa (§8) |
| 12 | Documentação desatualizada | Atualizar SPEC e catálogo (§9) |

**Fora do escopo:** mexer no Ósmio (achado 8, só observar), mudar o Hidrogênio (achado 11, fica como aposta), alongar as lutas, simplificar durações e marcas, modificadores de andar, Hélio e os outros elementos que ainda não existem.

---

## 1. Mexidas

### 1.1 Conceito

Uma **mexida** é uma magia que **não causa efeito no inimigo**: ela pega o dado posto no buraco, muda o valor dele e o devolve à sua mão **na hora**, durante a alocação. O dado mexido pode então alimentar outra magia neste turno. É a resposta ao achado 1+2: as lutas continuam curtas, mas cada turno passa a ter a pergunta "em qual dado eu mexo?".

As mexidas seguem os princípios do catálogo: tudo passa por dado posto em buraco (princípio 2), o resultado é calculável antes de terminar o turno (princípio 4) e a sorte só entra onde o jogador controla a chance (princípio 6).

### 1.2 Regras gerais

1. **Resolve na alocação.** Assim que o buraco da mexida fica completo, ela resolve: o dado volta à mão com o valor novo. Ela não age de novo na fase de resolução, e a ordem do inventário não importa para ela.
2. **O mesmo dado volta.** A mexida não cria dados (exceto a Sangria, que divide o dado em 3, §1.3). O dado da bolsa continua sendo o mesmo dado: vai para o descarte no fim do turno como qualquer outro.
3. **O valor novo vale só neste turno**, salvo quando o cartão diz "para sempre" (Lapidar).
4. **Um dado pode receber várias mexidas no mesmo turno** (cada mexida continua 1× por turno). O dado mexido mostra o selo "mexido" e o valor original da rolagem riscado. Dados devolvidos por outras magias (Imitação Barata, Força Desnecessária, as partes da Sangria) entram em qualquer magia, inclusive em mexidas, e **mantêm o elemento** (e as faces) do dado de origem.
5. **Cada mexida é uma magia:** no máximo 1 uso por turno; cópias da mesma mexida são permitidas, se couberem.
6. **Usar uma mexida não é usar o dado.** Só a magia que gasta o dado no fim conta como uso. Isso vale para os elementos que reagem ao uso (Sódio queima, Amianto fere quem usa) e para o Urânio: o Urânio mexido que termina o turno parado na mão envenena normalmente.
7. **Face máxima ("MÁX").** Depois de uma mexida, o dado está na face máxima se o valor novo for igual à face mais alta que ele tem (com adesivos). O Pico sempre deixa o dado na face máxima.
8. **Rolar de novo** (Segunda Chance, Tudo ou Nada) usa as faces do próprio dado, com adesivos, e os efeitos de rolagem do dado: Hidrogênio ×3 (se ligado), Carbono em cadeia e o +2 do Impulso Calculado. O Mercúrio rolado de novo fica com o valor da face, sem copiar. Os **efeitos do dado** (Sódio, Césio, Amianto, Ouro, adesivo de ouro) valem **uma vez por golpe** que o dado dá (Sódio e Césio, só nos golpes que acertam; ver o item seguinte): no Corte Duplo com dados ímpares, duas vezes; na Exibição de Velocidade com dados iguais, duas vezes cada. A **cadeia do Carbono fica fixa na rolagem da mão**: o Carbono rolado de novo (ou a parte/cópia de um Carbono) soma o mesmo bônus que tinha, sem recontar; partes, cópias e dados gastos não viram elos.
9. **O que vem no golpe só pega se o golpe pegar** (0.26.1). Sódio (queima 3), Césio (veneno 2), a queima da Bola de Fogo e as mexidas que vêm num golpe (Lição de Anatomia, Expectativa Tóxica) vão para quem o golpe acertou. Bloqueio e Revestimento resistem: o golpe acertou e o efeito entra. **Esquiva** evita: nada entra. **Espelho** evita e devolve: os efeitos vão para quem atacou (o Imune a Críticas dele ainda anula; se o reflexo for esquivado, ninguém recebe). Magia que **não golpeia** (bloqueio, cura, mexidas) não põe Sódio nem Césio no inimigo. As magias que miram o inimigo sem golpear (Rasteira, Roubar a Cena, Originalidade Obrigatória) continuam como antes. Os efeitos em quem usa (Titânio, Cobre, Ouro, Amianto, Lítio) valem em qualquer magia.
10. **Dado que não rola não aceita mexida aleatória.** As partes da Sangria e as cópias aceitam: rolam com as faces do dado de origem. Dados marcados (Pose Congelada, Recuo Estratégico, Concentrar Força), guardados (Perfeccionista) e recebidos (Roubar a Cena) só aceitam mexidas determinísticas.
11. **Desfazer:**
    - **Mexidas determinísticas** (todas, menos Segunda Chance e Tudo ou Nada) podem ser desfeitas até "Terminar turno": toque no dado mexido e escolha "desfazer". O dado volta ao valor anterior e o cartão volta ao palco. Se o dado mexido estava noutra magia, ele sai de lá antes.
    - **Mexidas aleatórias** são **definitivas**: o dado rola na hora em que entra no buraco e o resultado fica. Sem isso, o jogador poderia ver o resultado e desfazer, e o Tudo ou Nada perderia o risco. O dado já rolado pode trocar de magia livremente.
11. **Os inimigos usam mexidas** com as mesmas regras (§1.6).

### 1.3 Catálogo das 13 mexidas

5 iniciais (uma por personagem jogável) e 8 novas para Loja, Escola e recompensas. Todas entram nas ofertas de qualquer personagem; o **grupo** limita só o que os inimigos compram (catálogo §2.8).

| # | id | Mexida | Formato | Grupo | Pede | Efeito | Uso | Raridade |
|---|---|---|---|---|---|---|---|---|
| 40 | `segunda` | **Segunda Chance** | 1×1 | Feiticeiro | qualquer dado que rola | Rola o dado de novo e fica com o **maior** dos dois valores. | sempre | Comum |
| 41 | `ajuste` | **Ajuste Fino** | 1×1 | Assassino | qualquer dado | +1 ou −1 no valor (o jogador escolhe; mínimo 1). | sempre | Comum |
| 42 | `pico` | **Pico** | 1×1 | qualquer | qualquer dado | O dado vai para a sua **face máxima** (com adesivos). | 1× por luta | Comum |
| 43 | `sangria` | **Sangria** | 1×1 | qualquer | dado ≥ 3 | O dado se divide em **3 partes iguais** (§1.4). As partes são temporárias e mantêm o elemento do dado. | sempre | Comum |
| 44 | `virar` | **Virar** | 1×1 | qualquer | dado ≤ 6 | O dado mostra a face oposta: valor = 7 − valor (1 ↔ 6, 2 ↔ 5, 3 ↔ 4). | sempre | Comum |
| 45 | `nivelar` | **Nivelar** | 2×1 | Assassino | 2 dados | Os dois viram a média deles, arredondada para cima (2 e 6 → 4 e 4). | sempre | Comum |
| 46 | `polarizar` | **Polarizar** | 1×1 | Assassino | qualquer dado | Dado ≤ 3 vira 1; dado ≥ 4 vira 6. | sempre | Comum |
| 47 | `eco` | **Eco** | 2×1 | Assassino | 2 dados | O segundo dado vira igual ao primeiro (os buracos mostram "1º" e "2º"). | sempre | Incomum |
| 48 | `inflar` | **Inflar** | 1×1 | Feiticeiro | dado ≤ 3 | O dado vale o dobro. | sempre | Incomum |
| 49 | `juntar` | **Juntar Cacos** | 2×1 | Assassino | 2 dados | Os dois se fundem: volta **um** dado valendo a soma (o primeiro; o segundo vai para o descarte, como usado). | sempre | Incomum |
| 50 | `escada` | **Escada** | L (3) | Feiticeiro | 3 dados | Viram uma sequência a partir do menor: menor, menor + 1, menor + 2 (2, 6, 6 → 2, 3, 4). | sempre | Incomum |
| 51 | `tudo_nada` | **Tudo ou Nada** | 1×2 | Feiticeiro | qualquer dado que rola | Rola o dado de novo e fica com o **novo** valor ×2, seja qual for. O cartão mostra a chance de melhorar (§1.5). | sempre | Rara |
| 52 | `lapidar` | **Lapidar** | 3×1 | qualquer | um 1 (dado da bolsa, face não travada) | A face que saiu vira 6 **para sempre** (edição de face). O dado volta valendo 6. | 1× por luta | Rara |

Contagem: 7 Comuns, 4 Incomuns, 2 Raras. Todas são retas ou 1×1, menos a Escada (L) — 12 cabem no cinto do Assassino.

### 1.4 Detalhes de cada mexida

- **Segunda Chance:** rolagem nova com as regras do §1.2.8; fica o maior entre o valor atual e o novo. Nunca piora o dado.
- **Ajuste Fino:** o cartão tem **dois buracos**, "+1" e "−1"; o dado vai em um deles e o outro apaga. Um 1 no "−1" continua 1 (o buraco "−1" não aceita um 1).
- **Pico:** valor = maior face do dado. Um Chumbo vira 3. Um dado com o 6 adesivado duas vezes vira 24.
- **Sangria:** v ≥ 3 vira 3 partes: q = v ÷ 3 (inteiro) e as primeiras (v mod 3) partes ganham +1. Exemplos: 3 → 1, 1, 1; 6 → 2, 2, 2; 7 → 3, 2, 2; 8 → 3, 3, 2; 12 → 4, 4, 4. O dado original vai para o descarte como usado. As partes são temporárias, contam como mexidas e somem no fim do turno. Cada parte **mantém o elemento** (e as faces) do dado original: Sódio queima por parte usada, Amianto machuca por parte, Urânio parado envenena por parte, Carbono conta na cadeia, e rolar de novo usa as faces do dado original. O Mercúrio não é recalculado: a parte fica com o valor dividido, sem copiar o maior de novo.
- **Virar:** só valores de 1 a 6 (dado com adesivo ou Urânio acima de 6 não serve). O Chumbo 1 vira 6. É temporário: não edita a face travada.
- **Nivelar:** média arredondada para cima: 3 e 4 → 4 e 4; 1 e 6 → 4 e 4. Sempre produz um par.
- **Polarizar:** prepara exigências "um 1" (Espelho, Sacrifício, Levantar Peso) e "um 6" (Golpe nas Sombras, Meia Verdade, Presença Imponente).
- **Eco:** a ordem dos buracos importa: o dado do buraco "1º" é o modelo. O segundo copia só o valor, não o elemento.
- **Inflar:** 1 → 2, 2 → 4, 3 → 6.
- **Juntar Cacos:** o dado que fica é o do buraco "1º", com o elemento dele. Exemplo: 12 + 12 → um 24.
- **Escada:** se dois dados têm o menor valor, qualquer um é o "menor". Os três voltam à mão, com os valores na ordem dos buracos.
- **Tudo ou Nada:** resultado = 2 × (face nova). Exemplo: um 5 rola 2 → vira 4; rola 6 → vira 12.
- **Lapidar:** muda o número da face (como "editar face" no Poço) e zera os adesivos daquela face. Não aceita dado temporário, face travada (Chumbo) nem dado marcado.

### 1.5 Prévia e chance

- Com um dado selecionado ou arrastado sobre uma mexida determinística, o buraco mostra o resultado ("→ 6"; na Sangria, "→ 2 · 2 · 2").
- Nas aleatórias, o buraco mostra a chance:
  - **Segunda Chance:** "chance de subir: X%" = faces do dado maiores que o valor atual ÷ 6.
  - **Tudo ou Nada:** "chance de melhorar: X%" = faces f com 2f > valor atual ÷ 6. Exemplo: um 5 num d6 comum melhora com 3, 4, 5 ou 6 → 67%.

### 1.6 Escola (níveis)

Nível 2 e nível 3 somam **+1 / +2 ao valor de cada dado devolvido** pela mexida (na Sangria, a cada parte; no Juntar Cacos, ao dado único). Exceção: **Tudo ou Nada** multiplica a face nova por 2 / 3 / 4 nos níveis 1 / 2 / 3. Lapidar: a face vira 6 / 7 / 8 *(inicial)*.

### 1.7 IA

O inimigo (e o bot do simulador) escolhe as mexidas antes de alocar o resto, com uma busca gulosa:

1. Para cada mexida que pode usar e cada dado (ou par/trio) que ela aceita, simula a mexida e roda a alocação normal (`EnemyAI.choose`) na mão resultante.
2. Pontua a alocação: dano previsto + bloqueio previsto × 0,7 + cura prevista × 0,5 (cura vale 0 com a vida cheia).
3. Fica com a melhor mexida se ela superar a alocação sem mexida; repete enquanto houver mexidas e melhora.
4. Mexidas aleatórias entram na busca pelo **valor esperado** (Segunda Chance: média de max(atual, face); Tudo ou Nada: média de 2 × face) e depois rolam de verdade antes da alocação final.
5. O Caótico pula a busca e usa cada mexida no dado mais baixo que ela aceite.

### 1.8 Kits iniciais

Cada personagem jogável começa com uma mexida nível 1, posta no grimório. Os inimigos desses arquétipos também (o kit é o mesmo). Copista, Perfeccionista e Minimalista ficam como estão.

| Personagem | Mexida inicial | Casa sugerida | Decisão que cria |
|---|---|---|---|
| Feiticeiro | Segunda Chance | (3, 1), abaixo da Faísca, preservando o espaço em L do Meteoro | Rolar o dado solto para tentar o par da Bola, ou o maior para a Faísca? |
| Assassino | Ajuste Fino | (4, 0) no cinto | Fazer o 2 da Esquiva, dois ímpares para o Corte Duplo? |
| Bárbaro | Pico | (2, 0) | Gastar agora num 4 (vira 6 → Machadada 12) ou guardar para um dado com adesivo? |
| Vampiro | Sangria | (0, 1) | Um dado alto enche o Banquete sozinho; os outros vão na Mordida |
| Metalurgista | Virar | (2, 0) | Virar o Chumbo 1 em 6 para a Estocada, ou deixar o 1 para o Levantar Peso? |

### 1.9 Interface: o cartão que resolveu sai do palco

Pedido do autor: **quando uma magia resolve antes da fase de ataque, ela sai da tela.**

- Vale para toda magia que resolve na alocação: as 13 mexidas, **Imitação Barata** e **Força Desnecessária**.
- **Sequência:** o dado voa até o buraco → animação da mexida (rolagem 3D para as aleatórias; o número troca, com um brilho, nas determinísticas) → o dado volta voando para a coluna da mão com o valor novo → o cartão some (encolhe e esmaece, ~0,25 s) → o palco reorganiza os cartões que sobraram (a grade recalcula e eles podem voltar a crescer até o tamanho padrão), com animação de ~0,25 s, sem tirar os dados já encaixados.
- **Desfazer** (só determinísticas, Imitação e Força): tocar no dado mexido mostra "desfazer [nome da magia]"; o cartão volta ao palco no lugar dele.
- **Magia sem uso disponível** não aparece no palco nos turnos seguintes. Vale para **toda** magia "1× por luta" (e a 2ª da "2× por luta") já gasta, não só para as mexidas; hoje elas aparecem como "usada".
- **Turno do inimigo:** a mesma sequência para as mexidas dele, antes das outras magias. O cartão sai do palco.
- **Ficha do inimigo** (segurar a foto) e **grimório**: mostram todas as magias, inclusive as mexidas; as já usadas aparecem como "usada".
- O histórico registra cada mexida: "Segunda Chance: 2 → 5".

### 1.10 Exemplos de jogada

**Feiticeiro, andar 1, 1º turno.** Mão 1, 3, 4, 6. Sem par.
- Opção A: Segunda Chance no 1 (chance de subir 83%). Rola 4 → mão 4, 3, 4, 6. Bola de Fogo com 4 + 4 → 16 de dano e queima 3. Faísca com 6 → 6. Total 22 + queima. O cartão da Segunda Chance sai do palco.
- Se a rolagem desse 2: mão 2, 3, 4, 6, sem par; Faísca com 6. O dado 2 fica parado.
- Opção B: Segunda Chance no 3 (chance de subir 50%) mira o par com o 4 ou o 6.

**Metalurgista, andar 2.** Mão Chumbo 1, Chumbo 1 (o Peso Morto puxou mais um dado), 4, 2, 5.
- Sem virar: Levantar Peso nv 2 com um 1 → 4 × 2 (dois 1 na mão) × 1,5 = 12. Estocada com 5 → 6. Total 18.
- Virando um Chumbo (1 → 6): Levantar Peso → 4 × 1 × 1,5 = 6. Estocada com 6 → 7. Total 13.
- Virar é pior aqui. Seria melhor se houvesse só um Chumbo na mão. Decisão real.

**Assassino, Tudo ou Nada no nível 1.** Dado 5. Chance de melhorar 67%. Rola 1 → vira 2 (perdeu 3). O resultado fica; o 2 ainda serve à Esquiva Melhorada.

**Vampiro.** Mão 6, 2, 3, 1. Sangria no 6 → 2, 2, 2. Banquete com 2, 2, 2 → 6 de dano, cura 2. Mordida com o 3 → 3 de dano, cura 2. Sobram 2 e 1. Sem a Sangria: Banquete 6 + 3 + 2 = 11, cura 2; Mordida 1 → 1, cura 1. A Sangria aqui é pior para dano e igual para cura — ela compensa quando os dados são poucos ou quando a Sangria nv 2 soma +1 a cada parte.

### 1.11 Casos extremos

- **Sangria num dado de 24:** 8, 8, 8. Três dados grandes para magias de um dado. Fica limitado por "1 vez por turno" de cada magia.
- **Juntar Cacos + Juntar Cacos:** o dado fundido já é mexido; não entra em outra mexida. Sem corrente.
- **Eco com dado de Hidrogênio ligado:** o segundo copia o valor (já ×3); não vira Hidrogênio.
- **Polarizar ou Pico no Urânio parado:** o Urânio continua envenenando se terminar o turno sem uso.
- **Mexida e mexidas do inimigo** (metade, pares viram 1...): as do inimigo acontecem antes, na rolagem; a mexida age sobre o valor já alterado.
- **Alquimista:** a troca acontece na rolagem, antes das mexidas.
- **Porteiro de Chumbo:** o Chumbo posto na sua mão pode ser virado (1 → 6). É a resposta pensada ao Mestre.
- **Mão com um dado só ou vazia:** as mexidas que pedem 2 ou 3 dados não acendem.
- **Save no meio do turno:** a mão já mexida (valores, selos "mexido", resultados das aleatórias) é salva com o duelo. Ao abrir de novo, as mexidas aleatórias continuam definitivas.

---

## 2. Portas (achados 3 e 9)

### 2.1 A porta mostra o inimigo

- O inimigo de cada porta é **gerado quando as portas aparecem** (não mais ao entrar na luta) e salvo com as opções.
- Cada porta mostra: a dificuldade, as moedas, a recompensa (§2.2) e o **nome do arquétipo do inimigo** (e, se houver, a variante: "Assassino", "Lixeiro"). Só o nome, sem retrato.
- Não mostra a build (magias, bolsa, vida). A ficha completa continua só na luta.
- O "i" da porta explica o arquétipo em uma linha (a passiva e o estilo).
- **Mestre:** a porta única mostra o nome do Mestre.
- **Save antigo** na fase de portas, sem inimigo salvo: gera os inimigos ao carregar.

### 2.2 Prêmios das portas *(inicial)*

| Porta | Moedas (hoje → novo) | Recompensa pós-luta |
|---|---|---|
| Fácil | 4 → **3** | escolher 1 de **2** |
| Normal | 6 → **7** | escolher 1 de 3 |
| Difícil | 9 → **12** | 1 de 3, com faixa de raridade +1 (como hoje) |
| Insana | 15 → **20** | 1 de **4** (todos os tipos), com uma magia Rara garantida (como hoje) |

Pular a recompensa continua dando 3 moedas.

---

## 3. Desgaste (achado 4)

- **Depois de cada vitória** fora dos Mestres, o herói recupera **10% da vida máxima** (arredondado para cima) *(inicial)*, antes da tela de recompensa. A tela mostra "+X de vida".
- **Mestres:** continuam recuperando 30% (não soma com os 10%).
- **Parada de Cura:** de 50% para **35%** da vida máxima *(inicial)*.
- A cura pós-vitória **não ativa** a Sede do Vampiro (é fora da luta). A parada de Cura continua ativando, como hoje.

---

## 4. Mestres com kit fixo (achado 4)

- Cada Mestre tem **bolsa, magias e níveis fixos**, sem o orçamento aleatório. O inventário é o do arquétipo dele.
- **Vida:** `MASTER_HP_MULT` de 1,6 para **2,0** *(inicial)*.
- A regra de cada Mestre (SPEC v3 §8.3) não muda.

| Mestre | Arquétipo (inventário) | Bolsa | Magias (nível) | Como sinergiza | Resposta do jogador |
|---|---|---|---|---|---|
| **Porteiro de Chumbo** (10) | Feiticeiro (4×3) | 5 comuns + 3 Chumbo | Levantar Peso (2), Escudo Arcano (1), Interrupção Rude (1), Faísca (2) | Os 1 dele viram dano (Levantar Peso) e escudo; o Chumbo que ele põe na sua mão e a Interrupção entopem e encolhem a sua mão | Virar ou Polarizar no Chumbo; Levantar Peso próprio |
| **A Alquimista** (20) | Copista (4×2) | 4 comuns + 4 Mercúrio | Imitação Barata (1), Bola de Fogo (2), Faísca (2), mais a cópia da Inspiração (passiva do Copista, 1 casa livre) | A troca leva o seu maior dado para a última mão dela e o Mercúrio dela copia o maior; a Imitação fabrica o par da Bola | Ósmio não troca; Imune a Críticas anula; jogar com a mão baixa |
| **O Reator** (30) | Bárbaro (3×3) | 8 Urânio | Machadada (3), Expectativa Tóxica (1), Mordida (2), Suor de Campeão (1) | O veneno que ele toma o leva à Fúria (+1 por golpe a cada 10 de vida perdida); a Expectativa faz os seus dados parados doerem duas vezes | Gastar todos os dados (Sangria, Improviso Brilhante) e acabar rápido |

- Os arranjos no grimório devem ser válidos (um teste confere que tudo cabe).
- A IA dos Mestres continua "cautelosa".

---

## 5. Bot e telemetria (achado 5)

### 5.1 Bot com heurística de valor

`sim/simulate.gd` ganha `--bot=old|new` (padrão `new`). O bot `old` é o de hoje, para comparar.

| Momento | Regra do bot `new` |
|---|---|
| Luta | IA cautelosa + busca das mexidas (§1.7) |
| Portas | Vida ≥ 70%: Difícil; ≥ 40%: Normal; abaixo: Fácil. Insana só com vida ≥ 90%. Se a porta pedida não existe, a mais próxima abaixo |
| Recompensa | Pontua: magia que cabe = 8 (+4 Incomum, +8 Rara, +6 se for a 1ª mexida ou a 1ª defesa); adesivo = 10 (vai na face mais alta do dado de maior soma; Ósmio primeiro); dado = 4 (−2 para cada dado acima de 10 na bolsa); vida máxima = 6 (+6 com vida < 50%). Fica com a maior; pula se a maior for < 5 |
| Parada | Vida < 50%: Cura; senão Escola se houver evolução; senão Loja com ≥ 12 moedas; senão Poço |
| Loja | Compra o item de maior pontuação que puder pagar, até não poder mais |
| Escola | Evolui a magia mais usada nas lutas da jornada; sem nenhuma, aprende a melhor |
| Poço | Adesivo na face mais alta do dado de maior soma, se der; senão destrói o pior dado comum, se a bolsa tiver mais de 8 |

O relatório passa a mostrar também: meios-turnos médios por luta nos andares 1–3, uso de cada mexida (vezes por luta) e a chance de vencer cada andar por posição no bloco (1ª, 2ª, 3ª luta depois da parada).

### 5.2 Telemetria local

- O jogo grava cada jornada encerrada (vitória ou derrota) em `user://jornadas.json`, guardando as **últimas 50**. Nada sai do aparelho.
- **Campos por jornada:** versão do jogo, personagem, semente, data, resultado, andar final, causa da derrota (arquétipo/Mestre do inimigo, vida dele no fim, turno), moedas totais. **Por andar:** portas oferecidas e escolhida (com o arquétipo), meios-turnos da luta, vida antes e depois, recompensas oferecidas e escolhida (ou pulou), parada oferecida e escolhida, compras, mexidas usadas (id e quantidade).
- **Exportar:** botão "Copiar dados das jornadas" no menu, que põe o JSON na área de transferência.
- Um script `sim/telemetria.gd` lê o arquivo exportado e imprime o mesmo resumo do simulador, para comparar humano e bot.

---

## 6. Imitação Barata sem corrente (achado 6)

**Revogada (0.13.0):** dados **devolvidos** por magias (Imitação Barata, Força Desnecessária, partes da Sangria) entram em **qualquer** magia, inclusive Imitação Barata, Sacrifício, Transfusão e mexidas. Cada magia continua no máximo 1× por turno, então a corrente só cresce com várias cópias da Imitação no inventário. A regra antiga ("não aceita cópia") saiu a pedido, para dar mais estratégia aos dados com elemento.

---

## 7. Escala dos inimigos (achado 7)

- `ENEMY_UPGRADES_PER_FLOOR_LATE`: de 0,2 para **0,35** *(inicial)*.
- O adesivo do inimigo prefere acumular: 50% das vezes vai na face que já tem mais adesivos de um dado que já tem adesivo *(inicial)*.
- **Calibrar com o bot `new`:** o alvo é a chance de vencer cada andar ficar parecida nos três atos (diferença de até 5 pontos entre as médias de cada ato).

---

## 8. Dado mexido mostra o original (achado 10)

- Todo dado da mão cujo valor foi mudado por algo que não seja a rolagem mostra o **valor original riscado**, pequeno, acima do valor novo, e o **ícone da causa** num canto.
- **Causas:** mexidas do inimigo (metade, pares viram 1, face máxima vira 1, Alquimista), suas mexidas (§1), Mercúrio, Carbono e Hidrogênio.
- Segurar o dado mostra o nome da causa e a conta ("Chave de Braço Didática: 6 → 3").
- Dados postos na mão pelo inimigo (Chumbo do Porteiro) mostram o ícone da causa, sem valor riscado.

---

## 9. Documentação (achado 12)

No fim da implementação:
- **SPEC v3:** §4.1 separa os elementos implementados dos futuros (Nitrogênio, Oganessônio, Ouro, Hélio, Vidro); §12 passa a "Histórico: fatia vertical"; §8.3 ganha os kits fixos e os números novos do simulador; §2 e §3 ganham as regras das portas, da cura e as mexidas iniciais.
- **Catálogo:** seção nova "Mexidas" (§1 deste documento), regra 6 em §2.2, contagem de magias atualizada (58).
- **RARIDADE.md:** contagem por classe com as 13 mexidas.
- Este arquivo vira histórico.

---

## 10. Critérios de aceite

**Testes automáticos (GUT):**
1. Cada uma das 13 mexidas produz os valores dos exemplos de §1.4 (Sangria 7 → 3, 2, 2; Nivelar 2 e 6 → 4 e 4; Escada 2, 6, 6 → 2, 3, 4; Virar Chumbo 1 → 6; Pico num dado com 6 adesivado → 12; Juntar 12 + 12 → um 24; Ajuste Fino recusa −1 num 1).
2. Um dado mexido não é aceito por outra mexida; dados devolvidos não são aceitos por Imitação, Sacrifício e Transfusão.
3. A corrente da crítica (2 Imitações nv 3 → 24) não acontece mais.
4. Mexidas aleatórias não podem ser desfeitas; as determinísticas desfazem e restauram o valor e o cartão.
5. Urânio mexido e parado envenena; Sódio só queima ao ser gasto numa magia que não é mexida.
6. Lapidar edita a face para sempre e não aceita Chumbo travado nem dado temporário.
7. Os kits dos três Mestres cabem no inventário e as regras deles continuam funcionando.
8. Portas: o inimigo gerado na porta é o mesmo da luta; save antigo na fase de portas carrega; recompensa da porta fácil tem 2 opções, da insana 4.
9. Cura de 10% após vitória comum; 30% (sem somar) após Mestre; Cura da parada 35%.
10. Telemetria grava e limita a 50 jornadas; o JSON exportado é lido por `sim/telemetria.gd`.

**Simulador (bot `new`, 1000 jornadas, todos os personagens jogáveis)** *(metas iniciais)*:
- Meios-turnos por luta nos andares 1–3: **4 a 6** (as lutas continuam curtas).
- A mexida inicial é usada em **≥ 60%** dos turnos do jogador.
- Vencer o andar 10: entre **20% e 35%** para cada personagem, e a diferença entre o melhor e o pior personagem **≤ 8 pontos**.
- O 3º andar de cada bloco não pode ter chance de vitória mais de **12 pontos** abaixo da média do bloco (hoje são até 30).
- Cada Mestre deve ter chance de vitória **menor** que a média dos 3 andares anteriores.
- Nenhuma mexida nova com uso **< 3%** ou **> 40%** das lutas em que está no grimório.

**Playtest humano (telemetria)** — perguntar e medir:
- O jogador usa a mexida inicial na maioria dos turnos e diz que o 1º andar "teve escolha"?
- Taxa de escolha de cada porta (alvo: nenhuma porta acima de 60% das escolhas).
- Onde as jornadas morrem (andar e posição no bloco) e em que andar médio.
- Quais mexidas são escolhidas quando oferecidas.

---

## 11. Decisões do Portão 3

| Questão | Decisão |
|---|---|
| Total de mexidas | **13**: as 5 iniciais e 8 novas |
| Magias já usadas no palco | Somem nos turnos seguintes, para **todas** as magias, não só as mexidas (§1.9) |
| Mexidas aleatórias | **Definitivas** (Segunda Chance e Tudo ou Nada); as determinísticas desfazem |
| Ajuste Fino | **Dois buracos**, "+1" e "−1" |
| Porta | **Só o nome** do arquétipo, sem retrato |
| Copista, Perfeccionista e Minimalista | **Sem mexida inicial** por ora |

---

## 12. Resultado da implementação e da calibração

**Calibração** (bot novo, 500 jornadas por personagem, semente 1). Números ajustados a partir dos iniciais: `ENEMY_HP_MULT` 0,9 → **1,035** (inimigos ×1,15), `MASTER_HP_MULT` 2,0 → **2,6**. Decidido com o autor durante a implementação: a **Esquiva Melhorada** do Assassino passou de "sem limite" a **2× por luta**, porque com o Ajuste Fino ele acertava o 2 quase todo turno (andar 10: 50% → 33%).

| Personagem | Meios-turnos (andares 1–3) | Turnos com mexida | 1ª / 2ª / 3ª luta do bloco | Andar 10 | Andar 20 | Andar 30 |
|---|---|---|---|---|---|---|
| Feiticeiro | 5,05 | 76% | 94 / 91 / 89% | 31,0% | 14,8% | 7,4% |
| Assassino | 4,52 | 97% | 91 / 92 / 91% | 33,4% | 6,0% | 2,8% |
| Metalurgista | 5,21 | 80% | 93 / 92 / 86% | 27,2% | 11,6% | 5,4% |
| Vampiro | 5,63 | 36% | 94 / 93 / 87% | 28,8% | 17,2% | 7,4% |
| Bárbaro | 5,90 | 43% | 93 / 92 / 92% | 31,8% | 18,4% | 11,8% |

Antes (bot novo, regras antigas): andar 10 entre 16,6% e 25,4%; 3ª luta do bloco até 15 pontos abaixo da 1ª; os Mestres eram mais fáceis que o andar anterior.

**Critérios do §10:**
- Meios-turnos nos andares 1–3 entre 4 e 6: **ok** (4,5 a 5,9).
- Andar 10 entre 20% e 35% e diferença ≤ 8 pontos: **ok** (27,2% a 33,4%; 6,2 pontos).
- 3ª luta do bloco até 12 pontos abaixo da média: **ok** (no máximo 5 pontos).
- Mestre mais difícil que a média dos 3 andares anteriores: **ok** nos três atos para todos.
- Mexida inicial em ≥ 60% dos turnos: **ok** para Feiticeiro, Assassino e Metalurgista; **não** para o Vampiro (36%) e o Bárbaro (43%). O Pico é 1× por luta (o teto fica perto de 40%) e a Sangria só compensa quando faltam dados; a IA usa quando vale. Fica para o playtest.
- Nenhuma mexida nova com uso < 3% ou > 40% das lutas em que está no grimório: nenhuma abaixo de 3%, mas **todas acima de 40%** (Escada 53% a Eco e Polarizar 82%; Lapidar 27%). O critério estava mal calibrado: mexida é barata de usar e entra em quase toda luta em que ajuda. O sinal de mexida dominante passa a ser a taxa de escolha na telemetria.

**Desvios do spec na implementação:**
- **Ajuste Fino no nível 2/3:** o passo cresce (±2 / ±3) em vez de somar +1/+2 (somar no −1 anularia o efeito).
- **Causa do dado mexido:** aparece ao **tocar** no dado (o texto da dica), não ao segurar.
- **Reorganização do palco:** os cartões deslizam para o lugar novo depois que o que saiu some (0,25 s cada).

## 13. Mercado, Escola paga e jornada fantasma (calibração)

Mudanças (decididas com o autor): a parada virou **mercado** (sempre com "Vender magias"); a Loja vende 1 dado com elemento e 1 adesivo com estoque de 1 a 3 e, em metade das visitas, cópia de dado ou +vida máxima (estoque 1), sem magias; troca de ofertas (Loja: 1ª grátis, depois 3, 5, 7...; Escola: 5, 8, 11...); a Escola cobra as 2 magias (preço da raridade) e as 2 evoluções (8 / 14, Rara e Lendária +6); a magia ganha ou comprada abre o grimório com a peça na mão. Os inimigos trocaram o orçamento solto (`ENEMY_UPGRADES_PER_FLOOR`) pela **jornada fantasma** (`EnemyFactory.journey`, SPEC_v3 §8); a porta multiplica os andares da jornada (`DOOR_JOURNEY`: 0,8 / 1 / 1,2 / 1,4).

Com a jornada fantasma, o inimigo cresce muito mais do que antes (vida máxima, adesivos e magias do mercado). A vida base deixou de subir com o andar. Valores novos: `ENEMY_HP_PER_FLOOR` 5 → **1**, `ENEMY_HP_PER_FLOOR_LATE` 3 → **0**, `ENEMY_HP_MULT` 1,035 → **0,72**, `MASTER_HP_MULT` 2,6 → **3,5** (os Mestres ficam com a vida de antes, mais ou menos). Base 0.27.0 (Sódio 3, Césio 2, golpes novos).

**Calibração** (bot novo com a economia nova: compra até esgotar, troca as ofertas quando nada serve, vende a magia mais fraca para caber uma melhor; 300 jornadas por personagem, semente 1). Alvo: personagem médio vence o andar 10 em 35–40% e o 30 em 5–10%.

| Personagem | Meios-turnos (lutas / andares 1–3) | Andar 10 | Andar 20 | Andar 30 |
|---|---|---|---|---|
| Feiticeiro | 3,07 / 2,64 | 62,3% | 25,0% | 16,7% |
| Assassino | 4,56 / 3,50 | 24,7% | 6,7% | 2,0% |
| Minimalista | 3,02 / 3,50 | 33,7% | 5,3% | 4,0% |
| Metalurgista | 3,27 / 2,63 | 44,0% | 17,7% | 13,0% |
| Copista | 5,17 / 6,27 | 7,0% | 2,3% | 1,0% |
| Perfeccionista | 3,76 / 4,59 | 23,0% | 6,7% | 3,0% |
| Vampiro | 3,56 / 4,07 | 44,3% | 19,3% | 15,7% |
| Bárbaro | 4,03 / 4,76 | 38,3% | 12,3% | 8,0% |
| Xamã | 3,58 / 3,18 | 48,0% | 13,7% | 8,3% |
| **Média** | | **36,1%** | **12,1%** | **8,0%** |

Observações: as lutas dos andares 1–3 ficaram mais curtas (2,6 a 6,3 meios-turnos; antes 4,5 a 5,9). A diferença entre personagens é grande: o Copista perde 22% já no andar 1 (o bot escolhe a porta insana com vida cheia e ele não segura), e o Feiticeiro passa de 60% no andar 10. Fica para o balanceamento por personagem.

### 13.1 Vida que volta a crescer depois do andar 10 (0.28.1)

Problema: com a vida base parada depois do andar 10, o inimigo comum ficava com uns 50 de vida no andar 25 (o herói tinha uns 120) e os três Mestres tinham a mesma vida (101). A jornada fantasma não compensava: a vida máxima é a compra de que o inimigo menos gosta, e metade dos adesivos ia para a mesma face (andar 25: 12 dos 24 numa face só). No simulador, quase ninguém morria entre o 20 e o 29.

Valores novos: `ENEMY_HP_PER_FLOOR_LATE` 0 → **2,5**; `MASTER_HP_MULT` vira um multiplicador por Mestre, **{10: 3,5, 20: 2,3, 30: 2,2}** (vida 101 / 108 / 143); `ENEMY_STICKER_STACK` 0,5 → **0,2**. Os andares 1 a 10 não mudam. `sim/enemies.gd` mostra o inimigo médio de cada andar.

Bot novo, 300 jornadas por personagem jogável, semente 1 (média dos 6):

| Venceu o andar | 10 | 19 | 20 | 29 | 30 |
|---|---|---|---|---|---|
| Antes | 43,0% | 20,8% | 13,8% | 11,0% | 9,7% |
| Depois | 44,6% | 20,8% | 12,6% | 7,0% | 5,4% |

O "antes" usou 100 jornadas por personagem.
