# 🚀 Configurar Repositorio CI/CD desde tu Carpeta Local

Guía paso a paso para crear y configurar el repositorio CI/CD desde tu carpeta actual.

## 📋 Pasos desde PowerShell

### Paso 1: Crear el Repositorio en GitHub

1. Ve a GitHub y crea un nuevo repositorio:
   - Nombre sugerido: `stock-simulator-ci-cd`
   - Puede ser público o privado
   - **NO inicialices con README, .gitignore o licencia** (lo haremos localmente)

### Paso 2: Preparar Carpeta Local para CI/CD

Desde tu carpeta actual (`ProyectoQA`), ejecuta estos comandos:

```powershell
# 1. Crear carpeta para el repositorio CI/CD (en el mismo nivel que ProyectoQA)
cd ..
mkdir stock-simulator-ci-cd
cd stock-simulator-ci-cd

# 2. Inicializar git
git init

# 3. Copiar archivos necesarios desde ProyectoQA
# Copiar Jenkinsfile
Copy-Item ..\ProyectoQA\Jenkinsfile .

# Copiar docker-compose.jenkins.yml
Copy-Item ..\ProyectoQA\docker-compose.jenkins.yml .

# Copiar carpeta jenkins completa
Copy-Item -Recurse ..\ProyectoQA\jenkins .

# 4. Crear README básico para el repo CI/CD
@"
# Stock Simulator - CI/CD Configuration

Este repositorio contiene la configuración de CI/CD para el proyecto Stock Simulator.

## Contenido

- \`Jenkinsfile\` - Pipeline de Jenkins
- \`docker-compose.jenkins.yml\` - Configuración de Docker para Jenkins
- \`jenkins/\` - Scripts y documentación

## Configuración

Ver la documentación en \`jenkins/MULTI_REPO_SETUP.md\`
"@ | Out-File -FilePath README.md -Encoding UTF8

# 5. Crear .gitignore básico
@"
# Test reports
test-reports/
*.csv

# Jenkins data (no versionar)
jenkins_home/

# Logs
*.log

# OS
.DS_Store
Thumbs.db
"@ | Out-File -FilePath .gitignore -Encoding UTF8

# 6. Verificar que los archivos se copiaron correctamente
Get-ChildItem -Recurse | Select-Object FullName
```

### Paso 3: Conectar con el Repositorio de GitHub

```powershell
# Agregar el repositorio remoto (reemplaza TU_USUARIO con tu usuario de GitHub)
git remote add origin https://github.com/sebaveaa/stock-simulator-ci-cd.git

# O si prefieres usar SSH:
# git remote add origin git@github.com:sebaveaa/stock-simulator-ci-cd.git

# Verificar que se agregó correctamente
git remote -v
```

### Paso 4: Hacer Commit y Push

```powershell
# Agregar todos los archivos
git add .

# Hacer commit inicial
git commit -m "Initial commit: CI/CD configuration"

# Push al repositorio (primera vez)
git branch -M main
git push -u origin main
```

### Paso 5: Verificar en GitHub

1. Ve a tu repositorio en GitHub: `https://github.com/sebaveaa/stock-simulator-ci-cd`
2. Verifica que veas:
   - ✅ `Jenkinsfile`
   - ✅ `docker-compose.jenkins.yml`
   - ✅ Carpeta `jenkins/` con todos los scripts

## ✅ Script Completo (Todo en Uno)

Si prefieres ejecutar todo de una vez, aquí está el script completo:

```powershell
# Ir al directorio padre
cd ..

# Crear carpeta para CI/CD
New-Item -ItemType Directory -Force -Path "stock-simulator-ci-cd" | Out-Null
cd stock-simulator-ci-cd

# Inicializar git
git init

# Copiar archivos
Copy-Item ..\ProyectoQA\Jenkinsfile .
Copy-Item ..\ProyectoQA\docker-compose.jenkins.yml .
Copy-Item -Recurse ..\ProyectoQA\jenkins .

# Crear README
@"
# Stock Simulator - CI/CD Configuration

Este repositorio contiene la configuración de CI/CD para el proyecto Stock Simulator.

## Contenido

- \`Jenkinsfile\` - Pipeline de Jenkins
- \`docker-compose.jenkins.yml\` - Configuración de Docker para Jenkins
- \`jenkins/\` - Scripts y documentación

## Configuración

Ver la documentación en \`jenkins/MULTI_REPO_SETUP.md\`
"@ | Out-File -FilePath README.md -Encoding UTF8

# Crear .gitignore
@"
test-reports/
*.csv
jenkins_home/
*.log
.DS_Store
Thumbs.db
"@ | Out-File -FilePath .gitignore -Encoding UTF8

# Agregar remoto (REEMPLAZA con tu URL real)
git remote add origin https://github.com/sebaveaa/stock-simulator-ci-cd.git

# Commit y push
git add .
git commit -m "Initial commit: CI/CD configuration"
git branch -M main
git push -u origin main

Write-Host "✅ Repositorio CI/CD creado y configurado exitosamente!" -ForegroundColor Green
Write-Host "📍 Ubicación: $(Get-Location)" -ForegroundColor Cyan
```

## 🔧 Siguiente Paso

Una vez que el repositorio esté en GitHub:

1. **Configura el Pipeline en Jenkins** (ver `jenkins/MULTI_REPO_SETUP.md` Paso 3)
2. **Configura webhooks** en ambos repositorios (backend y frontend)

## 🆘 Problemas Comunes

### Error: "remote origin already exists"

```powershell
# Eliminar el remoto existente
git remote remove origin

# Agregar el correcto
git remote add origin https://github.com/sebaveaa/stock-simulator-ci-cd.git
```

### Error: "fatal: not a git repository"

```powershell
# Asegúrate de estar en la carpeta correcta
cd stock-simulator-ci-cd

# Si no existe, inicializa git
git init
```

### Los archivos no se copiaron

```powershell
# Verificar que estás en la ubicación correcta
Get-Location

# Verificar que los archivos fuente existen
Test-Path ..\ProyectoQA\Jenkinsfile
Test-Path ..\ProyectoQA\docker-compose.jenkins.yml
Test-Path ..\ProyectoQA\jenkins
```

## 📝 Notas

- El repositorio CI/CD puede estar en la misma organización o cuenta de GitHub
- No necesitas clonar los repositorios backend/frontend en el repo CI/CD
- El `Jenkinsfile` clonará automáticamente ambos repos cuando se ejecute

