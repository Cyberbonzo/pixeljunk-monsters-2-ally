param(
    [Parameter(Mandatory)][string] $Original,
    [Parameter(Mandatory)][string] $OutputFile,
    [Parameter(Mandatory)][string] $Cecil
)
$ErrorActionPreference = 'Stop'
$inputPath = (Resolve-Path -LiteralPath $Original).Path
$outputPath = [IO.Path]::GetFullPath($OutputFile)
if (Test-Path -LiteralPath $outputPath) { throw "Choose a new output file." }
if ((Get-FileHash -LiteralPath $inputPath).Hash -ne 'CC48B7781F34652B99D613E44F5D4A6926F3D4CD120E2F64C2D972019EEF5968') {
    throw "Unsupported game build. Expected Steam build 3279074."
}
Add-Type -Path (Resolve-Path -LiteralPath $Cecil).Path
$resolver = [Mono.Cecil.DefaultAssemblyResolver]::new()
$resolver.AddSearchDirectory([IO.Path]::GetDirectoryName($inputPath))
$params = [Mono.Cecil.ReaderParameters]::new()
$params.AssemblyResolver = $resolver
$game = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($inputPath, $params)
try {
    $module = $game.MainModule
    $inventory = $module.GetType('GameCore.GameCoreInventory')
    $available = $inventory.Methods | Where-Object Name -eq 'GetAvailableInventory'
    $network = $module.GetType('Q4.Networking.NetworkMatch').Methods | Where-Object Name -eq 'get_IsNetworkMatch'
    $coin = ($inventory.NestedTypes | Where-Object Name -eq 'EInventoryType').Fields | Where-Object Name -eq 'Coin'
    if ($coin.Constant -ne 0) { throw "Unexpected coin identifier." }
    $read = @($available.Body.Instructions | Where-Object {
        $_.OpCode.Name -eq 'callvirt' -and $_.Operand.Name -eq 'GetValue'
    })
    if ($read.Count -ne 1 -or $read[0].Next.OpCode.Name -ne 'ret') { throw "Unexpected inventory getter." }

    $attributes = [Mono.Cecil.MethodAttributes]'Private, Static, HideBySig'
    $balance = [Mono.Cecil.MethodDefinition]::new('LocalSpendableBalance', $attributes, $module.TypeSystem.Int32)
    $balance.Parameters.Add([Mono.Cecil.ParameterDefinition]::new($module.TypeSystem.Int32))
    $balance.Parameters.Add([Mono.Cecil.ParameterDefinition]::new($available.Parameters[1].ParameterType))
    $inventory.Methods.Add($balance)
    $il = $balance.Body.GetILProcessor()
    $op = [Mono.Cecil.Cil.OpCodes]
    $originalValue = $il.Create($op::Ldarg_0)
    $il.Emit($op::Ldarg_1)
    $il.Emit($op::Brtrue_S, $originalValue)
    $il.Emit($op::Call, $network)
    $il.Emit($op::Brtrue_S, $originalValue)
    $il.Emit($op::Ldc_I4, [int]9999)
    $il.Emit($op::Ret)
    $il.Append($originalValue)
    $il.Emit($op::Ret)

    # Only a valid player's inventory reaches this return in the original method.
    $return = $read[0].Next
    $il = $available.Body.GetILProcessor()
    $il.InsertBefore($return, $il.Create($op::Ldarg_2))
    $il.InsertBefore($return, $il.Create($op::Call, $balance))
    $game.Write($outputPath)
} finally {
    $game.Dispose()
    $resolver.Dispose()
}
