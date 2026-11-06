# Notas para o Claude

## Sempre subir a versão

Toda mudança no app (código, textos, arte, regras) sobe `config/version` no `project.godot`
no mesmo trabalho. Na branch principal, versão nova sem tag faz o CI gerar o release, e o
jogo instalado avisa "Nova versão disponível" (ver README, "Releases e atualização").

- Ajustes e correções: último número (`0.6.0` → `0.6.1`).
- Novidades maiores: número do meio, zerando o último (`0.6.3` → `0.7.0`).
- Só docs, testes ou CI, sem mudar o jogo: não precisa subir.
- Não mexa em `export_presets.cfg`: o CI preenche `version/name` e `version/code`.

## Rodar

Ver README, seção "Rodar": testes (GUT), `sim/check.gd` e capturas em `sim/shot_*.gd`.
