# Roadmap

> **Status: lista de ideias para o futuro.** Nada aqui está implementado. Cada item vira proposta própria (com feedback) antes de entrar no jogo.

---

## 1. Builds vencedoras viram inimigos ("fantasmas")

**Ideia:** quando o jogador vence uma masmorra inteira, a build dele é salva. Na masmorra seguinte, surge um **inimigo idêntico** a essa build. Aos poucos, as masmorras ficam povoadas por **cópias das builds do próprio jogador**.

**Por que encaixa no jogo:**
- Os inimigos já seguem **as mesmas regras do jogador** (`docs/SPEC_v3.md` §8): arquétipo, bolsa, inventário e passiva. Uma build salva é um inimigo pronto, sem regra nova.
- Combina com o tom (`docs/TOM.md`): o maior rival de um mago vaidoso é **ele mesmo**, na versão de ontem.
- É meta-progressão **sem poder permanente** (SPEC §9): a torre fica mais difícil e pessoal, mas o jogador não fica mais forte.

**O que salvar** (já existe em `Fighter.to_dict()`): arquétipo, vida máxima, mão, bolsa (faces, adesivos, elementos), inventário (peças, níveis, posições). Mais: o andar em que venceu, a data e o personagem.

**Perguntas para a proposta:**

| Tema | Pergunta |
|---|---|
| Onde aparece | Em que andar entra o fantasma? No andar equivalente à força da build (ex.: build do fim da torre só no fim), ou como Mestre de Andar? |
| Escala | A build entra igual ou ajustada ao andar (vida e orçamento de melhorias)? |
| Quantas | Quantos fantasmas por masmorra? Os mais recentes substituem os antigos? Existe um limite salvo? |
| Leitura | O jogador sabe que é a build dele (nome, data, "você, há 3 jornadas")? Isso mexe com a regra de "inimigo oculto até a porta abrir". |
| Personalidade | Qual IA o fantasma usa (Bruto, Cauteloso, Caótico)? |
| Perder para si mesmo | Se o fantasma vence, ele "sobe" (fica mais tempo) ou some? |
| Variedade | Como evitar que a mesma build dominante apareça sempre (ex.: só uma build por personagem)? |
| Compartilhar | No futuro, trocar fantasmas com amigos? (Exige rede; o jogo hoje é offline.) |

**Dependências:** ter "masmorras" encadeadas (hoje a jornada termina no andar 10) e um salvamento persistente separado da jornada (`SaveGame` hoje só guarda a jornada atual).

---

## 2. Outros itens já registrados

| Item | Onde |
|---|---|
| Raridade Lendária | `docs/RARIDADE.md` §9 |
| Personagens jogáveis restantes (Feiticeiro, Assassino, Metalurgista, Copista, Perfeccionista) | `docs/PERSONAGENS.md` |
| Elementos novos (Hélio, Vidro, Ferro, Ouro…) | `docs/SPEC_v3.md` §4.1 |
| Mestres dos andares 20 e 30 | `docs/SPEC_v3.md` §8.3 |
| Tirar a ordem de resolução das magias | `docs/CATALOGO_MAGIAS.md` §7 |
