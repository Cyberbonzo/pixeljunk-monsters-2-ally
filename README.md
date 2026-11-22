# Moedas infinitas em PixelJunk Monsters 2

Ajuste para a edição Steam de Windows, AppID 749800, build 3279074. Nas fases locais, o jogador tem 9.999 moedas disponíveis em cada consulta de compra. O jogo continua contabilizando os custos e os itens coletados. Gemas, outras categorias de inventário e partidas de rede seguem as regras do jogo.

## Aplicação

1. Feche o jogo. Guarde uma cópia do arquivo original `PixeljunkMonsters2_Data/Managed/Assembly-CSharp.dll` fora da instalação. O script reconhece a edição pelo SHA-256.
2. No PowerShell, use os arquivos da sua própria instalação e o caminho para Mono.Cecil 0.11.4. Escolha um arquivo de saída que ainda não exista.

```powershell
./Set-LocalCoins.ps1 -Original './Managed/Assembly-CSharp.dll' -OutputFile './local-coins.dll' -Cecil './Mono.Cecil.dll'
```

3. Coloque o arquivo de saída no lugar de `Assembly-CSharp.dll` e inicie pela Steam. No Bazzite o executável Windows usa Proton. Para desfazer, feche o jogo e restaure a DLL original. A verificação dos arquivos pela Steam também pode repor a versão oficial.

O saldo de fase é um inteiro de 32 bits. O ajuste intervém na consulta de disponibilidade usada pelas compras e pelo HUD. A validação do jogador ocorre antes da intervenção. O limite de 9.999 é renovado a cada consulta local, inclusive após gastar. Uma atualização da Steam pode requerer revisão do ajuste.

No ROG Ally com Bazzite e Proton 11, a fase 1 de Pockulu Forest mostrou 9.999 moedas ao selecionar a torre Arrow de 100 moedas e continuou em 9.999 com a torre construída. O contador de gemas estava em zero nos dois quadros.
