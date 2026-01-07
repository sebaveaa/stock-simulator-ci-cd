# 🔄 Configuración para Múltiples Repositorios

Esta guía explica cómo configurar Jenkins cuando tienes repositorios separados para frontend y backend.

## 📋 Situación Actual

Tienes:
- ✅ Repositorio separado para **Backend** (Spring Boot)
- ✅ Repositorio separado para **Frontend** (Angular)
- ✅ Configuración de Jenkins (Jenkinsfile, scripts) que necesita estar en un lugar

## 🎯 Solución Recomendada: Repositorio de CI/CD

Crea un **tercer repositorio** para la configuración de CI/CD que:

1. Contenga el `Jenkinsfile`
2. Contenga los scripts de generación de reportes
3. Clone ambos repositorios (backend y frontend) cuando se ejecute
4. Se ejecute cuando **cualquiera** de los dos repos se actualice

### Estructura del Repositorio CI/CD

```
ci-cd-repo/
├── Jenkinsfile                    # Pipeline principal
├── docker-compose.jenkins.yml     # Configuración de Jenkins
├── README.md                      # Documentación
└── jenkins/
    ├── scripts/                   # Scripts de generación de reportes
    │   ├── generate_backend_report.py
    │   ├── generate_frontend_report.py
    │   └── generate_consolidated_report.py
    └── README.md
```

## 🚀 Pasos de Configuración

### Paso 1: Crear Repositorio CI/CD

1. Crea un nuevo repositorio en GitHub (ej: `stock-simulator-ci-cd`)
   - **NO inicialices con README, .gitignore o licencia**

2. Desde tu carpeta local, copia los archivos necesarios:
   
   **Opción A: Usar PowerShell (Recomendado)**
   
   Ve a la guía detallada: [`SETUP_CI_CD_REPO.md`](SETUP_CI_CD_REPO.md)
   
   O ejecuta estos comandos desde tu carpeta `ProyectoQA`:
   ```powershell
   # Crear carpeta para CI/CD
   cd ..
   mkdir stock-simulator-ci-cd
   cd stock-simulator-ci-cd
   
   # Inicializar git
   git init
   
   # Copiar archivos
   Copy-Item ..\ProyectoQA\Jenkinsfile .
   Copy-Item ..\ProyectoQA\docker-compose.jenkins.yml .
   Copy-Item -Recurse ..\ProyectoQA\jenkins .
   
   # Conectar con GitHub (reemplaza con tu URL)
   git remote add origin https://github.com/TU_USUARIO/stock-simulator-ci-cd.git
   
   # Commit y push
   git add .
   git commit -m "Initial commit: CI/CD configuration"
   git branch -M main
   git push -u origin main
   ```
   
   **Opción B: Manualmente**
   
   - Crea una carpeta nueva
   - Copia manualmente: `Jenkinsfile`, `docker-compose.jenkins.yml`, y la carpeta `jenkins/`
   - Inicializa git y haz push

### Paso 2: Actualizar Jenkinsfile

El `Jenkinsfile` ya está configurado para clonar ambos repositorios. Solo necesitas:

1. Editar las URLs de los repositorios en el `Jenkinsfile`:
   ```groovy
   BACKEND_REPO_URL = 'https://github.com/TU_USUARIO/stock-simulator-backend.git'
   FRONTEND_REPO_URL = 'https://github.com/TU_USUARIO/stock-simulator-frontend.git'
   ```

2. Si los repos son privados, configura credenciales en Jenkins:
   - Ve a **Manage Jenkins > Manage Credentials**
   - Agrega credenciales de GitHub (usuario/contraseña o token)
   - Usa el ID de las credenciales en el `Jenkinsfile`

### Paso 3: Configurar Pipeline en Jenkins

1. En Jenkins, crea un nuevo **Pipeline**
2. Configuración:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: URL del repositorio CI/CD
   - **Branch**: `*/main`
   - **Script Path**: `Jenkinsfile`

### Paso 4: Configurar Webhooks en Ambos Repositorios

Necesitas configurar webhooks en **ambos** repositorios (backend y frontend) que apunten al mismo pipeline de Jenkins.

#### En el Repositorio Backend:

1. Ve a **Settings > Webhooks > Add webhook**
2. **Payload URL**: `https://TU_NGROK_URL/github-webhook/`
3. **Content type**: `application/json`
4. **Events**: Just the push event
5. Guarda

#### En el Repositorio Frontend:

1. Repite los mismos pasos que en el backend
2. Usa la misma URL de webhook

**✅ Resultado**: Cuando cualquiera de los dos repos tenga un push, el pipeline se ejecutará y probará ambos.

## 🔄 Alternativa: Pipelines Separados

Si prefieres tener pipelines separados para cada repositorio:

### Opción A: Jenkinsfile en cada Repo

1. Copia el `Jenkinsfile` al repositorio backend
2. Modifica para que solo ejecute pruebas del backend
3. Copia el `Jenkinsfile` al repositorio frontend
4. Modifica para que solo ejecute pruebas del frontend
5. Crea dos pipelines separados en Jenkins

**Ventajas:**
- Cada repo es independiente
- Puedes ejecutar pruebas solo del repo que cambió

**Desventajas:**
- No tienes reporte consolidado automático
- Más configuración

### Opción B: Pipeline que Detecta el Repo que Cambió

Puedes modificar el `Jenkinsfile` para detectar qué repositorio disparó el webhook y ejecutar solo esas pruebas.

## 📝 Configuración de Credenciales (Si los Repos son Privados)

1. En Jenkins: **Manage Jenkins > Manage Credentials**
2. **Add Credentials**:
   - **Kind**: Username with password
   - **Username**: Tu usuario de GitHub
   - **Password**: Tu token de GitHub (o contraseña)
   - **ID**: `github-credentials` (o el que uses en el Jenkinsfile)
3. Guarda

### Generar Token de GitHub

1. Ve a GitHub: **Settings > Developer settings > Personal access tokens > Tokens (classic)**
2. **Generate new token**
3. Marca: `repo` (acceso completo a repositorios)
4. Copia el token y úsalo como contraseña en Jenkins

## 🎯 Recomendación Final

**Usa el repositorio CI/CD separado** porque:
- ✅ Mantiene la configuración de CI/CD separada del código
- ✅ Permite ejecutar pruebas de ambos repos cuando cualquiera cambia
- ✅ Genera reportes consolidados
- ✅ Es más fácil de mantener

## 🔧 Actualizar Scripts para Nuevos Paths

Los scripts de generación de reportes ya están configurados para buscar en:
- `backend/` (en lugar de `stock-simulator-spring/`)
- `frontend/` (en lugar de `stock-simulator-angular/`)

Si necesitas ajustar los paths, edita los scripts en `jenkins/scripts/`.

## 📊 Flujo Completo

1. **Push a Backend** → Webhook → Jenkins ejecuta pipeline → Clona ambos repos → Prueba ambos → Reporte
2. **Push a Frontend** → Webhook → Jenkins ejecuta pipeline → Clona ambos repos → Prueba ambos → Reporte

Esto asegura que siempre tengas pruebas completas del sistema, incluso si solo cambias un repositorio.

