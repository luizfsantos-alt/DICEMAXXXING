# DICEMAXXING — Especificação de Regras (v2)

Consolida a v1 com todas as decisões tomadas na sessão de design. Onde houver conflito com a v1, **esta versão vale**.

Jogo de dados leve, de "desligar o cérebro", num coliseu de 100 lutas. Brutal, mas com poucas decisões calculadas.

---

## 0. Escopo do protótipo

| Tema | Decisão |
|---|---|
| Plataforma | Só Android. |
| Tecnologia | Godot 4 (4.7.x estável) + GDScript. Motor de regras em classes puras, testado com GUT, com simulador headless. |
| Build | GitHub Actions roda os testes e gera APK de debug a cada push. |
| Conteúdo | **Blocos 1 a 3** (lutas 1–30, chefes C1–C3). Todos os itens e passivos no pool da loja. |
| Personagem | Só o Gladiador. |
| Rede | 100% offline, sem conta, sem anúncios, sem compras. |
| Salvamento | Automático a cada turno (já com os dados rolados) e a cada visita à loja. Fechar e abrir o app não rerrola nada. |
| Idioma | Só PT-BR, com textos externalizados (`data/texts_pt_br.json`). |
| Fim | Vencer a luta 30 mostra "Você venceu o protótipo" com estatísticas da jornada e volta ao menu. |

---

## 1. Visão geral

- Coliseu de **100 duelos** em sequência, até morrer ou vencer.
- **Morreu, zerou.** A build é perdida.
- Chefe a cada 10 lutas.
- Coliseus II, III… são futuros.

---

## 2. Duelo

### 2.1 Dados
- Cada lado tem **sempre 6 dados**. O jogador começa com 6d6.
- Dados maiores (d8, d10, d20) **substituem** um dado existente; nunca viram sétimo dado.

### 2.2 Turno — visão do jogador
1. Os dois lados rolam. **Ambos veem todos os resultados.** Não há sugestão pré-preenchida: os 6 dados ficam soltos na bandeja.
2. O jogador usa **no máximo 3 dados ativos**, somando:
   - dados **lançados** no item de ataque;
   - dados **encaixados** no item de defesa.
3. **Autodano = todos os dados que sobraram** quando o turno termina (no mínimo 3; se o jogador encerrar usando só 2 ativos, são 4 de autodano, e assim por diante).
4. **Lançamento (swipe):** sem efeito mecânico de direção, força ou timing — é só *wow factor*.
   - Itens **de padrão** (Martelo, Lança, Arco): o jogador monta o grupo de 1 a 3 dados dentro do item e dá **um único swipe**. Depois disso não lança mais nada no turno.
   - Demais itens: dados lançados **um a um** com swipe.
   - Dado lançado é **irreversível**. O dado encaixado na defesa pode ser retirado até o fim do turno. Os demais ficam livres.
   - A ordem de lançamento só importa quando um item diz isso (ex.: Clava).
5. Item de defesa é só um **encaixe**: encaixou, está ativo ao fim do turno.
6. O turno termina **automaticamente** quando os 3 ativos tiverem sido usados, ou pelo botão **"Terminar turno"** (com aviso de quantos dados irão para o autodano e o total).
7. As escolhas são **simultâneas**: o inimigo decide vendo só os dados rolados (exceção futura: A Banca).
8. Resolução na ordem oficial (seção 3).

### 2.3 Itens declaram seus dados
Cada item declara quantos dados aceita (mínimo e máximo) e os requisitos de valor. Hoje:
- Ataque: 0 a 3 dados (0 só se o jogador encerrar sem lançar).
- Defesa: 0 ou 1 dado.

### 2.4 Vitória, derrota e empate
- Quem chega a 0 de vida perde. **Empate = derrota do jogador.**
- Trava de segurança contra duelos infinitos: se um duelo chegar ao **turno 60**, conta como derrota do jogador. *(Salvaguarda técnica; ajustável.)*

### 2.5 Vida
- Jogador: 30 base + modificadores. Gladiador: +10 (Casca Grossa).
- **A vida é totalmente restaurada após cada batalha.**
- Toda cura respeita a vida máxima.

### 2.6 Arredondamento
**Tudo arredonda para cima**, sobre o valor que cada efeito produz. Exemplos:
- Martelo sem par: 7 × 0,8 = 5,6 → **6**.
- Bálsamo: autodano 7 → **4** (o efeito produz o autodano restante).
- Muralha: dano 7 → bloqueia **4**, passam 3 (o efeito produz o valor bloqueado).

---

## 3. Ordem oficial de resolução

Uma única sequência, usada pelo jogo, pelos testes e pelo simulador.

**A. Início do turno**
1. Efeitos de início: cura do Bandeide; escudo da Dona Neide; escudo da Pochete (só no turno 1).
2. Leitura da vida para efeitos condicionais (Meia de Compressão, Garrafa de Pedreiro). Vale para o turno inteiro.

**B. Rolagem**
1. Rolar os dados (Gato da Sorte: o 1 nunca sai).
2. Regras de rolagem de chefe (Cleitinho rola 7 e descarta o menor).
3. Passivos de dado, nesta ordem: **Pé de Coelho → Ioiô → Dado Viciado → Figurinha Repetida**.
4. Checagens: **Raspadinha**, **Nota de 3 Reais**.

**C. Alocação** — simultânea, depois revelada.

**D. Efeitos negativos** — Corrente e afins. O Chapéu de Alumínio pode anular um.

**E. Travar condições** — par, trio, sequência e requisitos de valor da defesa são avaliados agora e **nada do oponente os desfaz depois**.
- As condições usam **só os dados no item de ataque**. Trio e sequência exigem os 3 dados no ataque.
- Os **seus próprios modificadores de valor** contam (Mangual: 1 e 2 viram 6; Calculadora: +1). Multiplicadores de dano de um dado (Clava, Adaga, explosões do Chicote) não mudam o valor para fins de condição.

**F. Cálculo do ataque de cada lado**
1. Modificadores próprios por dado: Mangual, Calculadora, Clava, Adaga, explosões do Chicote.
2. Modificadores do oponente por dado: Colete, Cota de Malha, anulações do Elmo e do Broquel. Nenhum dado fica abaixo de 0.
3. Fórmula do item de ataque (Martelo, Lança, Arco, Foice).
4. Multiplicadores globais (Raspadinha).
5. Resultado: **total do ataque**, dividido em **contribuições proporcionais** ao valor efetivo de cada dado (após F1 e F2), incluindo bônus fixos.

**G. Espelhos** — cada espelho tira do total a **maior contribuição restante** (ordem do maior para o menor valor efetivo), arredondada para cima; passa o total menos o refletido. O refletido vira dano para quem atacou. Reflexo nunca é espelhado de volta.

**H. Espinhos** — cada dado de ataque inimigo **não anulado** gera dano de espinhos para quem atacou.

**I. Reduções** — valem para dano que passou, refletido e espinhos, aplicadas por **quem recebe**, nesta ordem:
1. Reduções fixas (Meia de Compressão).
2. Muralha.
3. Escudos da rodada (Placa Vampírica por último).
4. Escudos persistentes (Barreira Acumulada).

Reflexo e espinhos **não** sofrem reduções por dado de ataque (Colete, Cota, Elmo, Broquel).

**J. Aplicação do dano direto** — simultânea. Curas ligadas ao ataque (Machado Sanguessuga).

**K. Curas antes do autodano** — Amuleto da Fênix.

**L. Autodano** — Capacete de Obra → Elmo dos Gêmeos → Ímã de Pizzaria → soma → Bálsamo → Garrafa de Pedreiro → Cadeado de Bicicleta.

**M. Fim do turno** — sobra da Placa Vampírica vira cura; escudos da rodada somem; Barreira fica (teto 20).

**N. Morte** — empate = derrota do jogador; Desafio à Morte restaura; pós-vitória: moedas, Chinelo de Dedo.

---

## 4. Corrente, Espelho e habilidades

- **Jogadores e inimigos comuns não têm habilidades ativas.**
- Corrente, Espelho e afins vêm **só de efeitos de itens** (no futuro, também de personagens) ou de **regras de chefe**. Cada item define suas próprias exigências de dado.
- **Corrente**: o **maior dado ativo** do alvo troca de lugar com o **menor dado de autodano** do alvo. O dado que entra ocupa o mesmo lugar (inclusive na ordem de lançamento). Se não atender ao requisito do item, aquele item não ativa no turno. Duas Correntes resolvem ao mesmo tempo, sobre as colocações originais.
- **Espelho**: ver etapa G. O reflexo é o **dano bruto** daquela contribuição, depois reduzido só pelas reduções gerais de quem atacou (etapa I).
  - Exemplo: Martelo com 6-6-2 (par): total ⌈14 × 1,3⌉ = 19; o primeiro 6 reflete ⌈19 × 6/14⌉ = 9; passam 10.
  - Exemplo: Arco com 3-4-5: total 12 + 10 = 22; o 5 reflete ⌈22 × 5/12⌉ = 10; passam 12.
- **Escudos duram 1 rodada**, salvo quando o item diz explicitamente o contrário.

---

## 5. Equipamentos

1 item de ataque e 1 de defesa por vez. Comprar outro substitui o atual.

### 5.1 Ataque

| Código | Nome | Lançamento | Efeito |
|---|---|---|---|
| A1 | Canhão de Dados (inicial) | um a um | Dano = soma dos dados. |
| A2 | Martelo de Pares | grupo | Com par entre os dados do ataque: +30% no total. Sem par: −20%. |
| A3 | Lança Trina | grupo | Com trio (3 dados no ataque): total ×2. Sem trio: −20%. |
| A4 | Arco da Sequência | grupo | Com sequência de 3 (ex.: 3-4-5): +10. Sem: normal. |
| A5 | Clava Pesada | um a um | **O primeiro dado lançado conta em dobro.** |
| A6 | Mangual dos Fracos | um a um | Dados 1 e 2 no ataque valem 6. |
| A7 | Chicote Explosivo | um a um | Cada dado de valor 6 rola um dado extra **do mesmo tipo** e soma; se o extra der 6, explode de novo. A explosão acontece mesmo que o oponente reduza o dado. |
| A8 | Adaga Ímpar | um a um | Cada dado ímpar causa +2. |
| A9 | Machado Sanguessuga | um a um | Cada dado de ataque de valor 5 ou mais cura 2. |
| A10 | Foice do Desespero | um a um | +dano igual ao **maior dado de autodano** (após a Corrente). Exige ao menos 1 dado no ataque. |

### 5.2 Defesa (recebem 1 dado de valor X)

| Código | Nome | Efeito |
|---|---|---|
| D1 | Escudo de Madeira (inicial) | Escudo de 2X. |
| D2 | Bálsamo | Autodano total pela metade. **Só aceita 5.** |
| D3 | Muralha | Bloqueia metade do dano recebido. **Só aceita 4.** |
| D4 | Amuleto da Fênix | Cura 2X antes do autodano. |
| D5 | Barreira Acumulada | Escudo de X **persistente** no duelo, acumulando até 20. |
| D6 | Couraça de Espinhos | ⌈X/2⌉ espinhos: cada dado de ataque inimigo não anulado devolve esse valor. Só na rodada. |
| D7 | Elmo dos Gêmeos | Anula todos os dados de valor X (ataque do inimigo e seu autodano). A condição do item inimigo continua valendo. |
| D8 | Broquel da Paridade | X par: anula os dados pares de ataque do inimigo. X ímpar: os ímpares. |
| D9 | Cota de Malha | Cada dado de ataque do inimigo perde ⌈X/2⌉. |
| D10 | Placa Vampírica | Escudo de X; o que sobrar **desse** escudo no fim do turno vira cura. |
| D11 | Espelho de Camelô *(novo)* | **Só aceita 1 ou 2.** Aplica Espelho. |
| D12 | Algema de Feira *(novo)* | **Só aceita 6.** Aplica Corrente no inimigo. |

---

## 6. Itens passivos

Sempre ativos. **Limite de 3.** Podem ser vendidos na loja.

### 6.1 Defensivos

| Código | Nome | Efeito |
|---|---|---|
| DF1 | Chinelo de Dedo | +1 de vida máxima por batalha vencida enquanto estiver no inventário. Vendeu, perdeu o bônus. |
| DF2 | Capacete de Obra | No primeiro turno de cada duelo, seu autodano é negado. |
| DF3 | Colete de Mototáxi | O maior dado de ataque do inimigo perde 1. |
| DF4 | Pochete Blindada | 3 de escudo no **primeiro turno** de cada duelo. |
| DF5 | Bandeide | Cura 2 no início de cada turno. |
| DF6 | Meia de Compressão | Com vida cheia no início do turno, o dano recebido cai 2. |
| DF7 | Garrafa de Pedreiro | Com 10 de vida ou menos no início do turno, o autodano cai pela metade. |
| DF8 | Chapéu de Alumínio | Ignora o primeiro efeito negativo de cada duelo (Corrente, espinhos e futuros). |
| DF9 | Boné de Aba Reta | Seus escudos ganham +20%. |
| DF10 | Cadeado de Bicicleta | Seu autodano nunca passa de 10 num turno. |

### 6.2 De dados

| Código | Nome | Efeito |
|---|---|---|
| DD1 | Dado Viciado de Feira | Seu menor dado vira para a face oposta (`máx + 1 − valor`). |
| DD2 | Raspadinha | Se os valores 1 a 6 estiverem todos presentes, seu dano de ataque do turno é dobrado. |
| DD3 | Pé de Coelho Sintético | Na primeira rolagem de cada duelo, seus 1s são rerrolados. |
| DD4 | Calculadora do Paraguai | Seu menor dado de ataque ganha +1. |
| DD5 | Nota de 3 Reais | Rolar 3 ou mais dados iguais dá 1 moeda. |
| DD6 | Ioiô | Seu maior valor do turno substitui seu menor dado na próxima rodada (sem limite de face). |
| DD7 | Ímã de Pizzaria | Todo dado de autodano cujo valor se repete é anulado (3-3-5 → sobra 5; 4-4-4 → 0). |
| DD8 | Figurinha Repetida | Seu maior valor é copiado para o maior dado de valor diferente. |
| DD9 | Gato da Sorte | Você não rola mais o número 1. |
| DD10 | Whey | Efeitos numéricos de defesa ganham +1, antes de multiplicadores como o do Boné: escudos (D1, D5, D10, DF4), cura da Fênix, bloqueio da Muralha, redução do Bálsamo, Cota, Colete, Meia e espinhos. |

---

## 7. Personagens

| Código | Nome | Itens iniciais | Passiva |
|---|---|---|---|
| P1 | O Gladiador | Canhão de Dados + Escudo de Madeira | **Casca Grossa**: +10 de vida máxima. |
| P2 | O Carrasco *(futuro)* | Clava Pesada + Muralha | Excesso de dano vira moedas. |
| P3 | O Penitente *(futuro)* | Foice + Fênix | +3 de vida máxima por vitória. |

---

## 8. Inimigos

### 8.1 Princípios
- Mesmas regras do jogador. Personalidade **oculta**; dados, vida, itens e passivos visíveis.
- Inimigos comuns **não têm habilidades**.

### 8.2 Blocos

| Bloco | Lutas | Vida | Pool |
|---|---|---|---|
| 1 | 1–10 | 18–24 | Canhão, sem defesa. |
| 2 | 11–20 | 22–28 | Ataque A1–A10, defesa D1–D10. |
| 3 | 21–30 | 26–32 | + D11 e D12. |
| 4–10 | 31–100 | — | Como na v1 (proposta; fora do protótipo). |

### 8.3 Personalidades (protótipo)
A IA sempre usa 3 dados ativos e lança do maior para o menor.
- **Bruto**: os 3 maiores no ataque; nunca defende.
- **Cauteloso**: os 3 maiores ativos; o melhor dado válido vai para a defesa (com requisito de valor, um dado válido entra no lugar do menor dos três). Sem dado válido, ataca com os três.
- **Caótico**: 3 dados aleatórios, defesa aleatória, ordem aleatória.
- **Esperto**: a partir do bloco 7 (fora do protótipo).

### 8.4 Nomes
Título + nome + epíteto, em tom brainrot (lista em `data/texts_pt_br.json`).

### 8.5 Chefes

| Código | Luta | Nome | Vida | Itens | Regra |
|---|---|---|---|---|---|
| C1 | 10 | Cleitinho, o Porteiro | 35 | Canhão, sem defesa | Rola 7 dados e descarta o menor. |
| C2 | 20 | Dona Neide, Mãe dos Escudos | 40 | Canhão + Escudo de Madeira | Começa todo turno com 5 de escudo. |
| C3 | 30 | **Kevin, Reflexo de Bolinha** | 45 | Martelo de Pares + Cota de Malha | Cada 6 que você lançar é refletido em você (pela regra do Espelho; a Cota dele não reduz o reflexo). |
| C4–C10 | 40–100 | Como na v1 | | | Fora do protótipo. |

---

## 9. Economia e loja

Valores iniciais, ajustáveis em `engine/config.gd`.

- Vitória comum: **5 moedas**. Chefe: **15**. Perdidas ao morrer.
- Loja após cada duelo, com **1 oferta** por visita. **3 rerrolagens grátis por jornada.**
- Preços:
  - Vida máxima +5: 6 moedas, +3 a cada compra.
  - Equipamento: 12.
  - Passivo: 15; venda por metade (arredondada para cima).
  - Desafio à Morte: 40.
  - d8 / d10 / d20: 10 / 16 / 25 — só a partir do bloco em que o tipo é liberado (d8 na luta 31, d10 na 51, d20 na 81). **O protótipo não vende dados.** O jogador pode trocar qualquer dado seu por qualquer dado da loja.
- Raridade do sorteio: **comum 70%** (vida máxima, equipamentos), **raro 25%** (passivos), **Desafio 5%**.
- **Desafio à Morte**: ao chegar a 0 de vida (inclusive empate), é consumido e o jogador volta com vida cheia na mesma batalha. Só 1 por vez.

---

## 10. Interface (protótipo)

- Retrato. Placeholders na disposição final, sem texturas.
- Dados 2D com forma por tipo (d6 quadrado, d8 losango, d10 pentágono, d20 triângulo), valor grande e tipo pequeno.
- Única animação: o voo do dado no swipe (e dos dados do inimigo na revelação).
- Resultado instantâneo + painel de log com cada etapa + botão "Próximo turno".

---

## 11. Balanceamento

- Simulador headless com um bot que põe os 3 maiores no ataque, sem defesa.
- Metas: vencer o bloco 1 em ~90% das jornadas; chegar à luta 30 em ~25%.
- Notas da v1 continuam valendo (Arco, Martelo, Lança, D2/D3, DD1, DD9).

## 12. Pendências

- Esperto e chefes C4–C10 (blocos 4 a 10).
- Itens de Corrente/Espelho adicionais; personagens futuros.
- Inspiração (meta-progressão).
