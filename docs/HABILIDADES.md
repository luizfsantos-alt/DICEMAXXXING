# DICEMAXXING — Lista de habilidades (para revisão)

Retrato do que existe hoje no jogo (fontes: `data/texts_pt_br.json`, `engine/items.gd`, `ui/chip.gd`, `docs/SPEC.md`).
A fonte da verdade das regras continua sendo o `docs/SPEC.md`; este arquivo serve para anotar mudanças.

**Como usar:** escreva o que quer mudar na coluna **Mudança desejada** (deixe vazio o que fica igual).
Para itens novos, use as linhas `NOVO` no fim de cada seção.

> Pela regra (SPEC §4), jogadores e inimigos comuns **não têm habilidades ativas**: tudo vem de equipamentos, itens, passiva do personagem ou regra de chefe.

## Formatos visuais

| Formato | Onde aparece | Detalhe |
|---|---|---|
| Retângulo com 3 slots | Palco central, equipamento de **ataque** | 0 a 3 dados; ordem dos slots só importa para a Clava |
| Círculo com 1 slot | Palco central, equipamento de **defesa** | 0 ou 1 dado (o "X" das descrições) |
| Quadradinho 52px com sigla | Itens, passiva do personagem, regra de chefe | Cor por categoria: DF azul-escudo, DD amarelo, personagem/chefe dourado; pisca quando age |
| Medalha redonda | Desafio à Morte | Vermelha; racha ao ser consumida |

---

## Ataque (equipamento, até 3 dados)

| Cód. | Nome | Efeito atual | Mudança desejada |
|---|---|---|---|
| A1 | Canhão de Dados *(inicial)* | Dano = soma dos dados. | |
| A2 | Martelo de Pares | Com par: +30% no total. Sem par: −20%. | |
| A3 | Lança Trina | Com trio (3 dados): ×2. Sem trio: −20%. | |
| A4 | Arco da Sequência | Com sequência de 3 (ex.: 3-4-5): +10. | |
| A5 | Clava Pesada | O dado do slot 1 conta em dobro. | |
| A6 | Mangual dos Fracos | Dados 1 e 2 no ataque valem 6. | |
| A7 | Chicote Explosivo | Cada 6 rola um dado extra do mesmo tipo e soma; extra 6 explode de novo. | |
| A8 | Adaga Ímpar | Cada dado ímpar causa +2. | |
| A9 | Machado Sanguessuga | Cada dado de ataque 5+ cura 2. | |
| A10 | Foice do Desespero | +dano igual ao maior dado de autodano (exige ao menos 1 dado no ataque). | |
| NOVO | | | |

## Defesa (equipamento, 1 dado = X)

| Cód. | Nome | Requisito | Efeito atual | Mudança desejada |
|---|---|---|---|---|
| D1 | Escudo de Madeira *(inicial)* | qualquer | Escudo de 2X. | |
| D2 | Bálsamo | só 5 | Autodano total pela metade. | |
| D3 | Muralha | só 4 | Bloqueia metade do dano recebido. | |
| D4 | Amuleto da Fênix | qualquer | Cura 2X antes do autodano. | |
| D5 | Barreira Acumulada | qualquer | Escudo de X persistente no duelo, até 20. | |
| D6 | Couraça de Espinhos | qualquer | ⌈X/2⌉ espinhos por dado de ataque inimigo não anulado. | |
| D7 | Elmo dos Gêmeos | qualquer | Anula dados de valor X (ataque inimigo e seu autodano). | |
| D8 | Broquel da Paridade | qualquer | X par anula os pares do inimigo; X ímpar, os ímpares. | |
| D9 | Cota de Malha | qualquer | Cada dado de ataque inimigo perde ⌈X/2⌉. | |
| D10 | Placa Vampírica | qualquer | Escudo de X; a sobra no fim do turno vira cura. | |
| D11 | Espelho de Camelô | só 1 ou 2 | Aplica Espelho (reflete o maior ataque do inimigo). | |
| D12 | Algema de Feira | só 6 | Aplica Corrente no inimigo. | |
| NOVO | | | | |

## Itens defensivos (quadradinho azul; limite de 3 itens no total)

| Cód. | Sigla | Nome | Efeito atual | Mudança desejada |
|---|---|---|---|---|
| DF1 | CHI | Chinelo de Dedo | +1 de vida máxima por vitória enquanto estiver no inventário. | |
| DF2 | CAP | Capacete de Obra | No 1º turno de cada duelo, seu autodano é negado. | |
| DF3 | COL | Colete de Mototáxi | O maior dado de ataque do inimigo perde 1. | |
| DF4 | POC | Pochete Blindada | 3 de escudo no 1º turno de cada duelo. | |
| DF5 | BAN | Bandeide | Cura 2 no início de cada turno. | |
| DF6 | MEI | Meia de Compressão | Com vida cheia no início do turno, dano recebido cai 2. | |
| DF7 | GAR | Garrafa de Pedreiro | Com 10 de vida ou menos, autodano pela metade. | |
| DF8 | CHA | Chapéu de Alumínio | Ignora o 1º efeito negativo de cada duelo. | |
| DF9 | BON | Boné de Aba Reta | Seus escudos ganham +20%. | |
| DF10 | CAD | Cadeado de Bicicleta | Seu autodano nunca passa de 10 num turno. | |
| NOVO | | | | |

## Itens de dados (quadradinho amarelo)

| Cód. | Sigla | Nome | Efeito atual | Mudança desejada |
|---|---|---|---|---|
| DD1 | VIC | Dado Viciado de Feira | Seu menor dado vira para a face oposta (`máx + 1 − valor`). | |
| DD2 | RAS | Raspadinha | Se rolar 1-2-3-4-5-6, seu dano do turno dobra. | |
| DD3 | COE | Pé de Coelho Sintético | Na 1ª rolagem do duelo, seus 1s são rerrolados. | |
| DD4 | CAL | Calculadora do Paraguai | Seu menor dado de ataque ganha +1. | |
| DD5 | N3 | Nota de 3 Reais | Rolar 3 ou mais dados iguais dá 1 moeda. | |
| DD6 | IOI | Ioiô | Seu maior valor substitui seu menor dado na próxima rodada. | |
| DD7 | ÍMÃ | Ímã de Pizzaria | Dados de autodano com valor repetido são anulados. | |
| DD8 | FIG | Figurinha Repetida | Seu maior valor é copiado para o maior dado de valor diferente. | |
| DD9 | GAT | Gato da Sorte | Você não rola mais o número 1. | |
| DD10 | WHE | Whey | Efeitos numéricos de defesa ganham +1. | |
| NOVO | | | | |

## Passiva do personagem e regras de chefe (quadradinho dourado)

| Cód. | Sigla | Dono | Efeito atual | Mudança desejada |
|---|---|---|---|---|
| P1 | CG | O Gladiador — Casca Grossa | +20 de vida máxima. | |
| C1 | 7D | Cleitinho, o Porteiro (luta 10) | Rola 7 dados e descarta o menor. | |
| C2 | NEI | Dona Neide, Mãe dos Escudos (luta 20) | Começa todo turno com 5 de escudo. | |
| C3 | KEV | Kevin, Reflexo de Bolinha (luta 30) | Todo 6 que você lançar é refletido em você. | |
| NOVO | | | | |

## Outros

| Cód. | Formato | Nome | Efeito atual | Mudança desejada |
|---|---|---|---|---|
| DEATH_DEFY | Medalha redonda (DM) | Desafio à Morte | Ao morrer, volta com vida cheia; consumido ao usar (1 por vez). | |
| HP | Oferta da loja | Vida Máxima +5 | +5 de vida máxima. | |

## Mecânicas aplicadas por itens

| Mecânica | Quem aplica | Regra atual | Mudança desejada |
|---|---|---|---|
| Corrente | D12 | O maior dado ativo do alvo troca de lugar com o menor dado de autodano dele. | |
| Espelho | D11, Kevin (C3) | Reflete a maior contribuição restante do ataque para quem atacou. | |
| Espinhos | D6 | Cada dado de ataque inimigo não anulado devolve dano a quem atacou. | |

## Planejado (fora do protótipo)

- P2 O Carrasco (Clava + Muralha) — passiva: excesso de dano vira moedas.
- P3 O Penitente (Foice + Fênix) — passiva: +3 de vida máxima por vitória.
- Chefes C4–C10 e personalidade Esperto.

## Anotações livres

-
