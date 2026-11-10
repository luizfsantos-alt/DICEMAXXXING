# Xamã (spec)

> **Status: implementado (0.25.0).** Personagem jogável novo, que também aparece como inimigo.
> Mudanças pedidas na aprovação do plano: a Síntese só aceita dado ≥ 2, e o cartão da
> Antítese tem um selo de prioridade ("1º"). No código, o Marcado é `Fighter.sigil`
> (`marked` já era a marca do Perfeccionista).
> Segue o padrão de `docs/PERSONAGENS.md`: formato do inventário, uma passiva, vida, mão,
> bolsa e magias iniciais. Números iniciais: o simulador ajusta (seção 7).

## 1. Ficha

| | |
|---|---|
| **Nome** | Xamã (cego: só tema, sem regra) |
| **Frase** | *"Assim como acima, abaixo. O que entra em mim, sai em você."* |
| **Passiva** | **Correspondência**: toda cura efetiva que você recebe causa o mesmo tanto de dano no inimigo. Todo bloqueio que você ganha põe o mesmo tanto de **marcado** nele. |
| **Vida** | 75 |
| **Mão** | 4 |
| **Bolsa** | 8 dados: 6 comuns + 2 Cobre |
| **Inventário** | Ampulheta 4×4 (12 casas) |
| **Magias iniciais** | Síntese, Antítese, Polarizar (nível 1) |
| **Grupo de magias** | `shaman` (Síntese e Antítese) |

```
####
.##.
.##.
####
```

`.` = casa que não existe. Posição inicial: Antítese em (1, 1), Síntese em (2, 1), as duas em pé
(1×2), e Polarizar em (0, 0).

## 2. Magias novas

| Magia | Forma | Exige | Efeito | Uso | Raridade |
|---|---|---|---|---|---|
| **Síntese** | 1×2 em pé | 1 dado ≥ 2 | Cura **d − 1** e dá **d − 1** de bloqueio (cada um × nível). | sempre | comum |
| **Antítese** | 1×2 em pé | 1 dado, qualquer | **d × 2** de dano no inimigo (× nível) e **d** de dano em você (não escala com o nível). | sempre | comum |

O Polarizar já existe (mexida: dado ≤ 3 vira 1, dado ≥ 4 vira 6).

### 2.1 O dano da Antítese em você

- **Não é golpe** (como o Amianto): ignora o seu bloqueio, a Esquiva, o Espelho e o Revestimento.
- **Resolve antes de todas as magias do turno**, qualquer que seja a ordem do inventário, para
  que a cura do mesmo turno encontre a vida perdida. O dano no inimigo fica no lugar normal da
  Antítese na ordem.
- **Não deixa você com menos de 1 de vida** (ver seção 8).

## 3. Correspondência (passiva)

- **Cura efetiva:** conta só o que a vida de fato subiu. Com a vida cheia, cura 0, dano 0.
- **Fontes que contam:** toda cura e todo bloqueio **dentro da luta**: magias (Síntese, Cerrar
  os Dentes, Remendo, Mordida...), Cobre, Titânio, Esquiva evoluída etc. A Parada de Cura e a vida
  ganha ao vencer **não** contam.
- **O dano da passiva não é golpe:** não passa por Esquiva nem por Espelho, não ganha
  Sacrifício nem Fúria e não sofre Revestimento. O bloqueio do inimigo absorve normalmente.
- **A ordem dentro de uma magia:** primeiro a cura (e o dano dela), depois o bloqueio (e a marca).

## 4. Marcado (status novo)

- **Ganhar:** cada ponto de bloqueio que o Xamã ganha põe 1 acúmulo de marcado no inimigo. Os
  acúmulos somam, sem limite, e duram até o fim da luta.
- **Quebrar:** na **primeira vez que a vida do marcado diminui de fato** depois de receber a marca,
  todas as marcas quebram juntas e causam **+X de dano direto na vida** (X = acúmulos; passa por
  cima do bloqueio).
- **O que não quebra:**
  - dano do mesmo efeito que pôs a marca (a mesma magia lançada, incluindo o dano da passiva vindo
    da cura dela);
  - golpe esquivado, refletido ou absorvido por inteiro pelo bloqueio (a vida não baixou);
  - o próprio +X.
- **Vários golpes:** só o primeiro golpe que tira vida quebra a marca.
- **Veneno e queima quebram a marca** (a vida baixa). Ver seção 8.
- **Na tela:** ícone de status com o número de acúmulos. Ao quebrar, número flutuante "+X" e uma
  linha no histórico.
- **Simetria:** o Xamã inimigo marca o jogador do mesmo jeito.

## 5. Exemplos

**Turno típico.** Xamã com 60/75 de vida, inimigo com 31 e 0 marcas. Mão: 5, 2, 3, Cobre 4.

1. Alocação: Polarizar no 5, que vira 6 e vai para a Síntese. Cobre 4 na Antítese.
2. Resolução: a Antítese tira 4 do Xamã antes de tudo (60 → 56).
3. Antítese: 8 de dano no inimigo (31 → 23). O Cobre usado cura 2 (56 → 58), o que vira 2 de
   dano (23 → 21).
4. Síntese: cura 5 (58 → 63), o que vira 5 de dano (21 → 16). Depois, 5 de bloqueio, que viram
   5 marcados no inimigo.
5. Turno do inimigo: um golpe de 7 bate no bloqueio de 5, e o Xamã perde 2 (63 → 61).
6. Próximo turno: o primeiro dano que tirar vida do inimigo quebra as 5 marcas, e ele perde +5.

**Vida cheia.** Xamã com 75/75 joga só a Síntese com 4: cura 0, dano 0, bloqueio 3, 3 marcados.

**Marca com bloqueio do inimigo.** Inimigo com 4 de bloqueio e 6 marcas leva um golpe de 3: o
bloqueio absorve tudo, a vida não baixa e as marcas ficam. Depois, um golpe de 5: o bloqueio
absorve 1, a vida baixa 4 e as marcas quebram, +6 (total de 10).

**Vários golpes.** Corte Duplo de 2 golpes de 5 com 4 marcas: o primeiro tira 5 + 4, e o segundo
tira 5.

**Mesmo efeito.** Uma magia que dá bloqueio e cura (Síntese) não quebra a própria marca. Uma
segunda Síntese, outra magia, quebra.

## 6. Critérios de aceite

1. O Xamã aparece na escolha de personagem com ficha, frase e retrato.
2. A Síntese não aceita dado 1. Com d = 6 no nível 1: cura até 5 e dá 5 de bloqueio.
3. Cura com vida cheia não causa dano no inimigo. Cura parcial (faltam 3, cura 5) causa 3.
4. O dano da Antítese em você ignora o seu bloqueio e acontece antes das outras magias, com
   qualquer ordem no inventário. Nunca deixa você com menos de 1.
5. Marcas: somam, ignoram o bloqueio ao quebrar, não quebram com golpe absorvido ou esquivado,
   não quebram com o efeito que as criou, só o primeiro golpe de uma magia de vários golpes as
   quebra, e veneno e queima quebram.
6. A Parada de Cura e a vida da vitória não causam dano.
7. O Xamã inimigo usa as magias dele, e a IA conta o dano da passiva e das marcas.
8. A prévia do cartão ("→ X de dano") inclui o dano da passiva.
9. Save no meio da luta guarda as marcas.

### Métricas do simulador (`sim/simulate.gd --char=shaman`)

- Taxa de vitória e andar médio de derrota, comparados com os outros 5 jogáveis. Alvo: dentro da
  faixa deles.
- Dano por turno no andar 1. Alvo: 10 a 14, perto do Feiticeiro com a Bola de Fogo.
- Mortes perto de 1 de vida causadas pela Antítese, e quanto da cura é desperdiçada (vida cheia).
- Marcas: acúmulo médio quando quebram e o maior acúmulo por luta (para ver se acumular sem limite
  vira estratégia dominante).
- Ajustes, em ordem, se ficar forte: Síntese com d − 2, Antítese × 1,5, vida 70.

## 7. Fora do escopo

- Magias novas do grupo `shaman` além das duas iniciais.
- Mestre Xamã.
- Arte final do retrato (entra a pauta em `docs/ARTE_FALTANDO.md`, com um retrato provisório).

## 8. Decisões

- **Veneno e queima quebram a marca** (aprovado): a regra é a literal, "a vida diminuiu". Também
  quebram o Amianto e a Expectativa Tóxica (dado parado), que tiram vida do próprio dono.
- **A Antítese não mata o próprio Xamã** (aprovado): deixa no mínimo 1.
- **Imune a Críticas anula a marca** (decisão da implementação): a marca é um efeito do
  adversário, como a queima e o veneno.
- **Várias marcas, um efeito:** o monte de marcas guarda o último efeito que pôs marca. Se um
  efeito novo marca por cima de marcas antigas que ainda não quebraram, só um efeito diferente
  quebra o monte todo.

## 9. Calibração (0.25.1)

Simulador (`sim/simulate.gd`, bot novo, porta pela vida), vitória até o andar:

| Versão | Andar 10 | Andar 20 | Andar 30 |
|---|---|---|---|
| 0.25.0 (Antítese tira o valor) | 78,5% | 61% | 22,5% |
| **0.25.1 (Antítese tira o valor ×2)** | **48%** | **38%** | **9%** |
| Os outros 5 jogáveis | 25–50% | 6–18% | 1–5,5% |

Decisão: o Xamã pode ser o melhor, mas não por 4× (era 22,5% contra 5,5% do Vampiro). Com o
dano em si ×2 a Antítese tem custo de verdade e a Síntese é o que segura a vida. Testados e
descartados: Síntese d − 2, Antítese ×1,5, vida 70 (juntos: 13%), Marcado só da Síntese
(19%) ou com teto 10 (15%), Síntese dividida (1,3%) e Síntese 2× por luta (3,3%).
