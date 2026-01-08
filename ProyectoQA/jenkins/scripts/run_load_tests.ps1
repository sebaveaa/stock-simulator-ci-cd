# Script PowerShell para ejecutar pruebas de carga con JMeter
# Puede ejecutarse manualmente o desde Jenkins

param(
    [string]$Scenario = "normal",
    [string]$BackendUrl = "http://localhost:8080",
    [string]$HealthEndpoint = "/actuator/health",
    [string]$ConfigFile = ""
)

$ErrorActionPreference = "Stop"

# Directorios
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$LoadTestsDir = Join-Path $ProjectRoot "ProyectoQA\jenkins\load-tests"
$ReportsDir = Join-Path $LoadTestsDir "load-test-reports"

# Si no se especifica config file, usar el por defecto
if ([string]::IsNullOrEmpty($ConfigFile)) {
    $ConfigFile = Join-Path $LoadTestsDir "load-test-config.properties"
}

# Detectar si estamos en Jenkins
$IsJenkins = $env:JENKINS_URL -ne $null -or $env:BUILD_NUMBER -ne $null

if ($IsJenkins) {
    Write-Host "Ejecutando en entorno Jenkins" -ForegroundColor Yellow
} else {
    Write-Host "Ejecutando manualmente" -ForegroundColor Green
}

# Función para mostrar ayuda
function Show-Help {
    Write-Host "Uso: .\run_load_tests.ps1 [PARAMETROS]"
    Write-Host ""
    Write-Host "Parámetros:"
    Write-Host "  -Scenario SCENARIO       Escenario de carga: normal, peak, stress (default: normal)"
    Write-Host "  -BackendUrl URL          URL del backend (default: http://localhost:8080)"
    Write-Host "  -HealthEndpoint PATH     Endpoint de health check (default: /actuator/health)"
    Write-Host "  -ConfigFile FILE         Archivo de configuración"
    Write-Host "  -Help                    Muestra esta ayuda"
}

if ($Help) {
    Show-Help
    exit 0
}

# Cargar configuración desde archivo si existe
$Config = @{}
if (Test-Path $ConfigFile) {
    Write-Host "Cargando configuración desde: $ConfigFile" -ForegroundColor Green
    Get-Content $ConfigFile | Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' } | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $Config[$key] = $value
        }
    }
}

# Verificar si JMeter está instalado
$JMeterCmd = $null

if (Get-Command jmeter -ErrorAction SilentlyContinue) {
    $JMeterCmd = "jmeter"
    Write-Host "JMeter encontrado en el sistema" -ForegroundColor Green
} elseif (Test-Path "C:\Program Files\Apache\jmeter\bin\jmeter.bat") {
    $JMeterCmd = "C:\Program Files\Apache\jmeter\bin\jmeter.bat"
    Write-Host "JMeter encontrado en C:\Program Files\Apache\jmeter" -ForegroundColor Green
} elseif ($env:JMETER_HOME -and (Test-Path (Join-Path $env:JMETER_HOME "bin\jmeter.bat"))) {
    $JMeterCmd = Join-Path $env:JMETER_HOME "bin\jmeter.bat"
    Write-Host "JMeter encontrado en $env:JMETER_HOME" -ForegroundColor Green
} else {
    Write-Host "Error: JMeter no está instalado" -ForegroundColor Red
    Write-Host "Instala JMeter o configura la variable de entorno JMETER_HOME"
    exit 1
}

# Verificar Java
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Java no está instalado" -ForegroundColor Red
    exit 1
}

# Verificar que el backend esté disponible
$HealthUrl = "$BackendUrl$HealthEndpoint"
Write-Host "Verificando que el backend esté disponible en $HealthUrl" -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri $HealthUrl -Method Get -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    Write-Host "Backend está disponible" -ForegroundColor Green
} catch {
    Write-Host "Error: Backend no está disponible en $HealthUrl" -ForegroundColor Red
    Write-Host "Asegúrate de que el backend esté corriendo"
    exit 1
}

# Obtener configuración del escenario
$Users = 50
$Rampup = 60
$Duration = 300

switch ($Scenario.ToLower()) {
    "normal" {
        $Users = if ($Config.ContainsKey("scenario.normal.users")) { [int]$Config["scenario.normal.users"] } else { 50 }
        $Rampup = if ($Config.ContainsKey("scenario.normal.rampup")) { [int]$Config["scenario.normal.rampup"] } else { 60 }
        $Duration = if ($Config.ContainsKey("scenario.normal.duration")) { [int]$Config["scenario.normal.duration"] } else { 300 }
    }
    "peak" {
        $Users = if ($Config.ContainsKey("scenario.peak.users")) { [int]$Config["scenario.peak.users"] } else { 200 }
        $Rampup = if ($Config.ContainsKey("scenario.peak.rampup")) { [int]$Config["scenario.peak.rampup"] } else { 120 }
        $Duration = if ($Config.ContainsKey("scenario.peak.duration")) { [int]$Config["scenario.peak.duration"] } else { 600 }
    }
    "stress" {
        $Users = if ($Config.ContainsKey("scenario.stress.users")) { [int]$Config["scenario.stress.users"] } else { 500 }
        $Rampup = if ($Config.ContainsKey("scenario.stress.rampup")) { [int]$Config["scenario.stress.rampup"] } else { 180 }
        $Duration = if ($Config.ContainsKey("scenario.stress.duration")) { [int]$Config["scenario.stress.duration"] } else { 900 }
    }
    default {
        Write-Host "Error: Escenario desconocido: $Scenario" -ForegroundColor Red
        Write-Host "Escenarios disponibles: normal, peak, stress"
        exit 1
    }
}

Write-Host "Configuración del escenario '$Scenario':" -ForegroundColor Green
Write-Host "  Usuarios concurrentes: $Users"
Write-Host "  Ramp-up (segundos): $Rampup"
Write-Host "  Duración (segundos): $Duration"

# Crear directorio de reportes
if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

# Archivo JMX
$JmxFile = Join-Path $LoadTestsDir "stock-simulator-load-test.jmx"
if (-not (Test-Path $JmxFile)) {
    Write-Host "Error: Archivo JMX no encontrado: $JmxFile" -ForegroundColor Red
    exit 1
}

# Timestamp para reportes
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportPrefix = Join-Path $ReportsDir "load-test-$Scenario-$Timestamp"
$JtlFile = "$ReportPrefix.jtl"
$HtmlReportDir = "$ReportPrefix-html"

Write-Host "Iniciando pruebas de carga..." -ForegroundColor Green
Write-Host "JMX: $JmxFile"
Write-Host "Reporte JTL: $JtlFile"
Write-Host "Reporte HTML: $HtmlReportDir"

# Ejecutar JMeter
$JmeterArgs = @(
    "-n",
    "-t", $JmxFile,
    "-l", $JtlFile,
    "-e",
    "-o", $HtmlReportDir,
    "-Jbackend.url=$BackendUrl",
    "-Jscenario.users=$Users",
    "-Jscenario.rampup=$Rampup",
    "-Jscenario.duration=$Duration",
    "-j", "$ReportPrefix.log"
)

try {
    & $JMeterCmd $JmeterArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Pruebas de carga completadas exitosamente" -ForegroundColor Green
        
        # Crear enlace al último reporte
        $LatestLink = Join-Path $ReportsDir "latest-html"
        if (Test-Path $LatestLink) {
            Remove-Item $LatestLink -Force
        }
        New-Item -ItemType SymbolicLink -Path $LatestLink -Target "load-test-$Scenario-$Timestamp-html" -Force | Out-Null
        
        Write-Host ""
        Write-Host "Reportes generados:" -ForegroundColor Green
        Write-Host "  JTL: $JtlFile"
        Write-Host "  HTML: $HtmlReportDir\index.html"
        Write-Host "  Log: $ReportPrefix.log"
        
        # Abrir reporte HTML si no estamos en Jenkins
        if (-not $IsJenkins) {
            $HtmlReportIndex = Join-Path $HtmlReportDir "index.html"
            if (Test-Path $HtmlReportIndex) {
                Write-Host "Abriendo reporte HTML..." -ForegroundColor Yellow
                Start-Process $HtmlReportIndex
            }
        }
        
        # Ejecutar script de análisis si existe
        $GenerateReportScript = Join-Path $ScriptDir "generate_load_test_report.py"
        if (Test-Path $GenerateReportScript) {
            Write-Host "Generando reporte consolidado..." -ForegroundColor Yellow
            python $GenerateReportScript $JtlFile $ReportsDir
        }
        
        exit 0
    } else {
        Write-Host "✗ Error ejecutando las pruebas de carga" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Error ejecutando JMeter: $_" -ForegroundColor Red
    exit 1
}

