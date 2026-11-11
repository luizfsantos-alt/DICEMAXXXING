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

## 2. Personagem: o Pescador

**Ideia:** um mago que vive de **sorte**. Passa turnos jogando a linha e pescando quase nada, e de repente puxa um peixe enorme: **dano imenso, mas inconstante**. A emoção é a da pescaria: espera, puxão, e às vezes a linha arrebenta.

**Eventos de sorte (rascunho para a proposta):**
- **Fisgada:** cada turno sem acertar o "peixe" aumenta a chance (ou o tamanho) do próximo. A tensão cresce até soltar.
- **Peixe grande:** quando a pesca vinga, o golpe multiplica (×3, ×4), passando dos limites normais do jogo.
- **Linha arrebentada:** às vezes o golpe grande vira nada, ou volta contra o próprio Pescador.
- **Isca:** gastar dados agora para melhorar a chance da próxima pescaria (combina com as mexidas e com a família da Maré: Maré Baixa / Maré Cheia).

**Encaixe:** dados de Estrôncio (estouram na face mais alta) e Hidrogênio servem de "isca de sorte"; a família da Maré já trabalha com ondas de dados altos e baixos.

**Perguntas para a proposta:**

| Tema | Pergunta |
|---|---|
| Passiva | A sorte é um contador visível (a linha esticando) ou escondido? |
| Variância | Quanto o dano pode oscilar sem a luta ficar decidida só no dado? Há um piso? |
| Kit | Quais magias começam no kit (uma de pesca, uma de isca, uma de sobrevivência)? |
| Leitura | Como mostrar a chance da fisgada na tela (bóia afundando, linha tremendo)? |
| Inimigo | O Pescador inimigo vai ser justo ou frustrante (golpe gigante do nada)? |

---

## 3. Refletir e Esquiva acumulam como os outros efeitos — **feito na 0.26.0**

**Ideia:** o Espelho (refletir) e a Esquiva passam a **acumular** como bloqueio, veneno ou queimadura. Lançar Espelho duas vezes guarda **dois reflexos**, e cada golpe recebido gasta um.

**Como ficou:** `Fighter.mirror` e `Fighter.dodge` viraram contadores de cargas (`engine/fighter.gd`).

| Tema | Decisão |
|---|---|
| Contador | Número de cargas, sem teto (os limites de uso das magias já seguram). |
| Nível | Vale o maior nível entre as magias usadas (como antes). |
| Duração | As cargas somem no início do próximo turno de quem as ergueu, como o bloqueio. |
| Ordem | A Esquiva gasta antes do Espelho; cada golpe (cada acerto de um golpe múltiplo) gasta uma carga. |
| Leitura | Ícone de status com o selo da quantidade. |
| Inimigo | A IA não muda: usa Espelho e Esquiva quando a mão deixa. |

---

## 4. Outros itens já registrados

| Item | Onde |
|---|---|
| Raridade Lendária | `docs/RARIDADE.md` §9 |
| Personagens jogáveis restantes (Feiticeiro, Assassino, Metalurgista, Copista, Perfeccionista) | `docs/PERSONAGENS.md` |
| Elementos novos (Hélio, Vidro, Ferro, Ouro…) | `docs/SPEC_v3.md` §4.1 |
| Mestres dos andares 20 e 30 | `docs/SPEC_v3.md` §8.3 |
| Tirar a ordem de resolução das magias | `docs/CATALOGO_MAGIAS.md` §7 |
