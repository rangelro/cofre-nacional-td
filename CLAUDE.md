# Cofre Nacional TD (Roblox)

Tower defense satírico, ondas infinitas, co-op 2-4 jogadores.
Vilões são o "Clã Mitomano": personagens FICTÍCIOS, sem nomes ou rostos
de pessoas reais. Alusões a escândalos públicos só como caricatura.

## Regras de código
- Edite código só pelos arquivos em src/ (Rojo sincroniza com o Studio).
- Linguagem: Luau. Lógica de jogo sempre no servidor; cliente só UI/efeitos.
- Inimigos NÃO usam Humanoid: movimento por waypoints com CFrame/Tween.
- Máximo ~50-60 inimigos simultâneos na tela.

## Escala por onda (n)
- Vida: base * 1.10^n até a onda 30, depois 1.05^n
- Quantidade: base + n * 0.8 (teto 50-60)
- Velocidade: +1% por onda (teto +50%)
- Recompensa por kill cresce mais devagar que a vida
- Inimigo novo a cada 5 ondas, chefe a cada 10, mutadores após a onda 40

## Monetização
- Game Passes e Developer Products vendem velocidade de progresso
  (pontos x2, boosts temporários) e cosméticos.
- NUNCA torre exclusiva mais forte. Sem loot box.

## Estrutura
src/server -> ServerScriptService | src/shared -> ReplicatedStorage
src/client -> StarterPlayerScripts