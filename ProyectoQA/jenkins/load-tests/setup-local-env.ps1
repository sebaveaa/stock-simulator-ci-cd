# Script PowerShell para configurar el entorno local para pruebas de carga

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

Write-Host "Configurando entorno local para pruebas de carga..." -ForegroundColor Green

# Verificar Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker no está instalado" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Docker encontrado" -ForegroundColor Green

# Verificar Docker Compose
$HasDockerCompose = (Get-Command docker-compose -ErrorAction SilentlyContinue) -ne $null
$HasDockerComposeV2 = try { docker compose version 2>$null; $true } catch { $false }

if (-not $HasDockerCompose -and -not $HasDockerComposeV2) {
    Write-Host "Error: Docker Compose no está instalado" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Docker Compose encontrado" -ForegroundColor Green

# Verificar Java (para JMeter)
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "Advertencia: Java no está instalado" -ForegroundColor Yellow
    Write-Host "Necesitas Java para ejecutar JMeter localmente"
    Write-Host "Puedes usar Docker para ejecutar JMeter"
}

# Verificar JMeter
$HasJmeter = (Get-Command jmeter -ErrorAction SilentlyContinue) -ne $null
$HasJmeterPath = Test-Path "C:\Program Files\Apache\jmeter\bin\jmeter.bat"
$HasJmeterHome = $env:JMETER_HOME -ne $null -and (Test-Path (Join-Path $env:JMETER_HOME "bin\jmeter.bat"))

if ($HasJmeter -or $HasJmeterPath -or $HasJmeterHome) {
    Write-Host "✓ JMeter encontrado" -ForegroundColor Green
} else {
    Write-Host "Advertencia: JMeter no está instalado" -ForegroundColor Yellow
    Write-Host "Instala JMeter o usa Docker para ejecutar las pruebas"
}

# Verificar docker-compose para load tests
$ComposeFile = Join-Path $ScriptDir "docker-compose.load-test.yml"
if (Test-Path $ComposeFile) {
    Write-Host "Iniciando servicios con Docker Compose..." -ForegroundColor Green
    
    Set-Location $ScriptDir
    
    # Detener servicios existentes si están corriendo
    if ($HasDockerCompose) {
        docker-compose -f docker-compose.load-test.yml down 2>$null
    } else {
        docker compose -f docker-compose.load-test.yml down 2>$null
    }
    
    # Iniciar servicios
    if ($HasDockerCompose) {
        docker-compose -f docker-compose.load-test.yml up -d
    } else {
        docker compose -f docker-compose.load-test.yml up -d
    }
    
    Write-Host "Esperando a que los servicios estén listos..." -ForegroundColor Green
    
    # Esperar a que PostgreSQL esté listo
    Write-Host "Esperando PostgreSQL..."
    for ($i = 1; $i -le 30; $i++) {
        $result = docker-compose -f docker-compose.load-test.yml exec -T postgres pg_isready -U postgres 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ PostgreSQL está listo" -ForegroundColor Green
            break
        }
        Start-Sleep -Seconds 1
    }
    
    # Esperar a que el backend esté listo
    Write-Host "Esperando backend..."
    for ($i = 1; $i -le 60; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -Method Get -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
            Write-Host "✓ Backend está listo" -ForegroundColor Green
            break
        } catch {
            Start-Sleep -Seconds 2
        }
    }
    
    Write-Host ""
    Write-Host "✓ Entorno listo para pruebas de carga" -ForegroundColor Green
    Write-Host ""
    Write-Host "Servicios disponibles:"
    Write-Host "  Backend: http://localhost:8080"
    Write-Host "  PostgreSQL: localhost:5432"
    Write-Host ""
    Write-Host "Para ejecutar las pruebas:"
    Write-Host "  cd $(Split-Path -Parent $ScriptDir)"
    Write-Host "  .\scripts\run_load_tests.ps1 -Scenario normal"
    Write-Host ""
} else {
    Write-Host "Advertencia: docker-compose.load-test.yml no encontrado" -ForegroundColor Yellow
    Write-Host "Usa el docker-compose principal o inicia los servicios manualmente"
}

