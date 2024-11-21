# Verificar se o script está sendo executado com permissões administrativas
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    # Se não estiver como administrador, pedir para reexecutar como administrador
    Write-Warning "O script precisa ser executado como administrador. Reexecutando como administrador..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Output "    
 O QUE O SCRIPT FAZ?:______________DESABILITA OS SEGUINTES SERVICOS:_____________________________
|                 Coluna 1                      |                Coluna 2                         |
|-----------------------------------------------|-------------------------------------------------|
| 1. Telefonia                                  | 10. Atualizacao do Edge                         |
| 2. Area de Trabalho Remota                    | 11. Gerenciador de Autenticacao Xbox Live       |
| 3. Servico de Telefonia                       | 12. Relatorio de Erros do Windows               |
| 4. Rede Xbox                                  |                                                 |
| 5. Criptografia de Unidade de Disco BitLocker |                                                 |
| 6. Armazenamento de Jogos Xbox                |                                                 |
| 7. Registro Remoto                            |                                                 |
| 8. Elevacao do Microsoft Edge                 |                                                 |
| 9. Atualizacao do Edge                        |                                                 |
|_______________________________________________|_________________________________________________|
 
 _________________________________REMOVE OS SEGUINTES BLOATWARES:_________________________________
|          Coluna 1            |         Coluna 2           |             Coluna 3                |
|------------------------------|----------------------------|-------------------------------------|
| 1. 3D Viewer                 | 10. Gravador de Som        | 19. Mapas                           |
| 2. Camera                    | 11. Jogo Paciencia         | 20. Identidade Xbox                 |
| 3. Feedback do Windows       | 12. Captura de Tela        | 21. Conversao de Fala em Texto Xbox |
| 4. Ajuda do Windows          | 13. Notas Adesivas         | 22. Aplicativo Xbox                 |
| 5. Paint                     | 14. Tarefas                | 23. Musica Zune                     |
| 6. Visualizador 3D           | 15. Hub do Office          | 24. Video Zune                      |
| 7. Portal de Realidade Mista | 16. Quadro Branco          |                                     |
| 8. Seu Telefone              | 17. Alarmes                |                                     |
| 9. Bing Noticias             | 18. Comunicacao do Windows |                                     |
|______________________________|____________________________|_____________________________________|

 ____________________________ADICIONA AS SEGUINTES CHAVES DE REGISTRO:____________________________
|           Coluna 1                            |                    Coluna 2                     |
|-----------------------------------------------|-------------------------------------------------|
| 1. SvcHostSplitThresholdInKB                  | 2. WaitToKillServiceTimeout                     |
|_______________________________________________|_________________________________________________|

 ____________________________DESATIVA OS SEGUINTES EFEITOS VISUAIS________________________________
| 1. Abrir caixas de combinacao                | 7. Esmaecer ou deslizar menus para a exibicao    |
| 2. Animacoes na barra de tarefas             | 8. Mostrar sombras sob janelas                   |
| 3. Animar controles e elementos no Windows   | 9. Mostrar sombras sob o ponteiro do mouse       |
| 4. Animar janelas ao minimizar e maximizar   | 10. Rolar caixas de listagem suavemente          |
| 5. Esmaecer itens de menu apos clicados      | 11. Salvar visu. de miniaturas da bara de tarefas|
| 6. Esmaecer ou deslizar Dicas de ferramentas |                                                  |
|______________________________________________|__________________________________________________|
"

# Função para criar um ponto de restauração do sistema
function Create-RestorePoint {
    param (
        [string]$description
    )
    try {
        $restorePoint = Get-WmiObject -List Win32_RestorePoint | Invoke-WmiMethod -Name CreateRestorePoint -ArgumentList $description, 0, 100
        if ($restorePoint.ReturnValue -eq 0) {
            Write-Output "Ponto de restauracao criado com sucesso: $description"
        } else {
            Write-Output "Erro ao criar ponto de restauracao. Codigo de retorno: $($restorePoint.ReturnValue)"
        }
    }
    catch {
        Write-Output "Erro ao criar ponto de restauracao: $($_.Exception.Message)"
    }
}

# Função para ativar a proteção do sistema e configurar espaço para pontos de restauração, se necessário
function Enable-RestorePoint {
    param (
        [string]$description
    )
    
    # Verificar se a proteção do sistema já está ativada
    $restoreStatus = Get-ComputerRestorePoint | Select-Object -First 1

    if ($restoreStatus -eq $null) {
        # Ativar a proteção do sistema na unidade C: se não estiver ativada
        Enable-ComputerRestore -Drive "C:\"
        
        # Calcular 3% do espaço total do disco para pontos de restauração
        $totalSpaceGB = (Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Name -eq "C"}).Used / 1GB
        $restoreSpaceGB = [math]::Round($totalSpaceGB * 0.03)

        # Definir espaço calculado para pontos de restauração
        vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=${restoreSpaceGB}GB
        Write-Output "Espaco de pontos de restauracao configurado para ${restoreSpaceGB}GB."
    } else {
        Write-Output "Criando ponto de restauracao..."
    }

    # Criar um ponto de restauração
    Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS"
    Write-Output "Ponto de restauracao criado com sucesso."
}

# Solicitar ao usuário se deseja criar um ponto de restauração
do {
    $response = Read-Host "`n`n                               PONTO DE RESTAURACAO: `nSe a protecao estiver desativada, ela sera ativada e consumira entre 3% e 5% da unidade C:.`n`n                                      S=Sim     N=Nao  `nDeseja criar um ponto de restauracao?"
    if ($response -ne "S" -and $response -ne "s" -and $response -ne "N" -and $response -ne "n" -and $response -ne "Sim" -and $response -ne "sim" -and $response -ne "Não" -and $response -ne "não" -and $response -ne "Nao" -and $response -ne "nao") {
        Write-Output "Resposta invalida. Por favor, responda 'S' ou 'N'."
    }
} while ($response -ne "S" -and $response -ne "s" -and $response -ne "N" -and $response -ne "n" -and $response -ne "Sim" -and $response -ne "sim" -and $response -ne "Não" -and $response -ne "não" -and $response -ne "Nao" -and $response -ne "nao")

if ($response -eq "S" -or $response -eq "s") {
    $restorePointDescription = "Remover Script OtimizarPC"
    Enable-RestorePoint -description $restorePointDescription
    Write-Output "Nome do ponto de restauracao: $restorePointDescription"
    Write-Output "Ponto de restauracao criado. Continuando com o processo."
} else {
    Write-Output "Ponto de restauracao ignorado. Continuando com o processo."
}

# Lista dos serviços que será desabilitado (PS. Você pode adicionar ou remover processos da lista a baixo segundo a sua necessidade, basta seguir o padrão)
$services = @(
    "TapiSrv",
    "TermService",
    "PhoneSvc",
    "XboxNetApiSvc",
    "BDESVC",
    "XblGameSave",
    "RemoteRegistry",
    "MicrosoftEdgeElevationService",
    "edgeupdate",
    "edgeupdatem",
    "XblAuthManager",
    "WerSvc",
    "XboxGipSvc"
)

# Variável para rastrear serviços não encontrados
$servicesNotFound = @()

# Iterar através da lista de serviços e desabilitar cada um
foreach ($service in $services) {
    try {
        Get-Service -Name $service -ErrorAction Stop | Set-Service -StartupType Disabled -ErrorAction Stop
        Stop-Service -Name $service -Force -ErrorAction Stop
    }
    catch {
        $servicesNotFound += $service
    }
}

# Exibir serviços não encontrados, se houver
if ($servicesNotFound.Count -gt 0) {
    Write-Output "Os seguintes serviços não foram encontrados:"
    $servicesNotFound | ForEach-Object { Write-Output " - $_" }
}

# Mensagem final
Write-Output "Servicos desativados."

# Lista dos aplicativos que será removido (OBS:. Você pode adicionar ou remover programas da lista a baixo segundo a sua necessidade, basta serguir o padrão)
$applicationsToRemove = @(
    "3D Viewer",
    "Microsoft.WindowsCamera",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.GetHelp",
    "Microsoft.MSPaint",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MixedReality.Portal",
    "Microsoft.YourPhone",
    "Microsoft.BingNews",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.ScreenSketch",
    "Microsoft.StickyNotes",
    "Microsoft.Todos",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.Whiteboard",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCommunicationsApps",
    "Microsoft.WindowsMaps",
    "Microsoft.XboxApp",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

# Função para remover aplicativos
function Remove-App {
    param (
        [string]$appName
    )
    Get-AppxPackage -Name "*$appName*" | Remove-AppxPackage
}

# Remover cada aplicativo
foreach ($app in $applicationsToRemove) {
    Remove-App -appName $app
}

Write-Output "Remocao de aplicativos concluida."

# Função para adicionar ou modificar chaves de registro
function Set-RegistryKeys {
    param (
        [hashtable]$keys
    )
    if ($keys -eq $null) {
        Write-Output "A variavel 'keys' esta nula. Certifique-se de que ela foi corretamente inicializada."
        return
    }

    foreach ($key in $keys.GetEnumerator()) {
        foreach ($subKey in $key.Value.GetEnumerator()) {
            try {
                New-ItemProperty -Path "Registry::$($key.Key)" -Name $subKey.Key -Value $subKey.Value -PropertyType DWord -Force | Out-Null
            }
            catch {
                Write-Output "Erro ao definir a chave de registro $($key.Key)\$($subKey.Key): $($_.Exception.Message)"
            }
        }
    }

    Write-Output "Chaves de registro definidas com sucesso."
}

# Chaves de registro a serem definidas
$registryKeys = @{
    "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" = @{
        "SvcHostSplitThresholdInKB" = 0x04000000
        "WaitToKillServiceTimeout" = 0x00002000
    }
}

# Executar a função para definir as chaves de registro
Set-RegistryKeys -keys $registryKeys

# Função para desativar efeitos visuais específicos
function Set-VisualEffects {
    # Desativar Animações e Efeitos Visuais
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations' -Value 0
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WindowAnimation' -Value 0
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'FontSmoothing' -Value 0
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'DragFullWindows' -Value 0
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value 20
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MouseHoverTime' -Value 20
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MinAnimate' -Value 0

    # Configurações adicionais
    $visualFX = @(
        "Animation", "AnimationClipboard", "AnimationFade", "AnimationTooltip", "DragFullWindows", "ListboxSmoothScrolling", "MenuAnimation", "Shadow"
    )

    foreach ($fx in $visualFX) {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name $fx -Value 0
    }

    Write-Output "Configuracoes visuais definidas!"
}

# Configuração do efeito Visual

Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 3
Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2

# Configurar Efeitos Visuais Específicos - Personalizado (Para ativar use o valor 1, e 0 para desativar)
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'UserPreferencesMask' -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations' -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name 'AlwaysHibernateThumbnails' -Value 0
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'MinAnimate' -Value 0
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WindowAnimation' -Value 0
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'DropShadow' -Value 1
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuAnimation' -Value 0
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'ToolTipAnimation' -Value 0
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'SelectionFade' -Value 0
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'FontSmoothing' -Value 2  # Nesse caso o valor 2 Ativa ClearType
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'FontSmoothingType' -Value 2  # Nesse caso o valor 2 Ativa Natural ClearType

# Atualizar a interface do usuário para aplicar as mudanças imediatamente
rundll32.exe user32.dll, UpdatePerUserSystemParameters -force

Write-Output "Configuracoes visuais atualizadas com sucesso!"

# Função para aguardar com opção de cancelamento
function Wait-WithCancel {
    param (
        [int]$seconds
    )
    Write-Host "Reiniciara em 10 segundos `nPressione qualquer tecla para cancelar a reinicializacao..."
    for ($i = 0; $i -lt $seconds; $i++) {
        Start-Sleep -Milliseconds 1000
        if ($Host.UI.RawUI.KeyAvailable) {
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return $false
        }
    }
    return $true
}

#Verificar e corrigir problemas no sistema
sfc /scannow


# Reiniciar o computador
do {
    $response = Read-Host "Reinicie para que tudo seja aplicado. Deseja reiniciar agora? (S=Sim  N=Nao)"
    if ($response -eq "S" -or $response -eq "s" -or $response -eq "Sim" -or $response -eq "sim") {
        if (Wait-WithCancel -seconds 10) {
            Restart-Computer -Force
        } else {
            Write-Output "Reinicializacao cancelada."
        }
    } elseif ($response -eq "N" -or $response -eq "n" -or $response -eq "Não" -or $response -eq "não" -or $response -eq "Nao" -or $response -eq "nao") {
        Write-Output "Reinicializacao cancelada."
        exit
    } else {
        Write-Output "Resposta invalida. Por favor, responda 'S' ou 'N'."
    }
} while ($response -ne "S" -and $response -ne "s" -and $response -ne "N" -and $response -ne "n" -and $response -ne "Sim" -and $response -ne "sim" -and $response -ne "Não" -and $response -ne "não" -and $response -ne "Nao" -and $response -ne "nao")
