# Configuración de Jenkins CI/CD

Este directorio contiene la configuración para ejecutar un pipeline CI/CD con Jenkins que ejecuta todas las pruebas del sistema y genera reportes CSV.

## 📋 Requisitos Previos

- Docker y Docker Compose instalados
- Git configurado
- Repositorios GitHub con acceso (para webhooks)
  - Repositorio Backend (Spring Boot)
  - Repositorio Frontend (Angular)
  - **Repositorio CI/CD** (contiene Jenkinsfile y scripts) - Ver [`MULTI_REPO_SETUP.md`](MULTI_REPO_SETUP.md)

## 🚀 Instalación y Configuración

### 1. Iniciar Jenkins

```powershell
# Iniciar Jenkins y PostgreSQL para pruebas
docker-compose -f docker-compose.jenkins.yml up -d

# Esperar a que Jenkins esté listo (puede tardar 1-2 minutos)
# Verificar logs
docker-compose -f docker-compose.jenkins.yml logs -f jenkins
```

### 2. Acceder a Jenkins

1. Abre tu navegador en: `http://localhost:8081`
2. Obtén la contraseña inicial de Jenkins:
   ```powershell
   docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Copia la contraseña y pégala en Jenkins
4. Instala los plugins recomendados o selecciona "Install suggested plugins"

### 3. Instalar Plugins Necesarios

Ve a **Manage Jenkins > Manage Plugins** e instala:

- **Git Plugin** (generalmente ya incluido)
- **Pipeline Plugin** (generalmente ya incluido)
- **Docker Pipeline Plugin**
- **GitHub Plugin** (para webhooks)
- **HTML Publisher Plugin** (opcional, para reportes HTML)

### 4. Configurar Credenciales

1. Ve a **Manage Jenkins > Manage Credentials**
2. Agrega credenciales si es necesario (para repositorios privados)

### 5. Crear Pipeline Job

#### Opción A: Pipeline desde SCM (Recomendado)

1. Ve a **New Item**
2. Selecciona **Pipeline** y dale un nombre (ej: `stock-simulator-ci`)
3. En la configuración:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: URL de tu repositorio GitHub
   - **Credentials**: Si es privado, selecciona las credenciales
   - **Branch Specifier**: `*/main` o `*/master` (según tu rama principal)
   - **Script Path**: `Jenkinsfile`
4. Guarda

#### Opción B: Pipeline Multibranch

1. Ve a **New Item**
2. Selecciona **Multibranch Pipeline**
3. Configura el repositorio Git
4. Jenkins detectará automáticamente el `Jenkinsfile` en cada rama

### 6. Configurar Webhook de GitHub

#### En GitHub:

1. Ve a tu repositorio en GitHub
2. **Settings > Webhooks > Add webhook**
3. Configura:
   - **Payload URL**: Debe ser una URL accesible desde Internet público
     - ⚠️ **NO uses `localhost`** - GitHub no puede acceder a localhost
     - ✅ **Para desarrollo local**: Usa ngrok (ver abajo)
     - ✅ **Para servidor con IP pública**: `http://TU_IP_PUBLICA:8081/github-webhook/`
     - ✅ **Para producción**: `https://TU_DOMINIO.com/github-webhook/`
     - ✅ **Con ngrok (recomendado para desarrollo)**: `https://TU_DOMINIO_NGROK.ngrok.io/github-webhook/`
   - **Content type**: `application/json`
   - **SSL verification**: 
     - ✅ **Habilitar** (Enable SSL verification) si:
       - Usas HTTPS con certificado válido (producción)
       - Usas ngrok con HTTPS (recomendado)
     - ❌ **Deshabilitar** (Disable SSL verification) si:
       - Usas HTTP (no HTTPS) - **Solo para desarrollo local**
       - Usas HTTPS con certificado autofirmado
       - **⚠️ Advertencia**: Deshabilitar SSL reduce la seguridad. Solo para desarrollo.
   - **Secret**: (Opcional pero recomendado) Genera un secreto para mayor seguridad
   - **Events**: Selecciona "Just the push event" o "Let me select individual events" y marca "Pushes"
   - **Active**: ✓
4. Guarda el webhook

#### En Jenkins:

1. Ve a la configuración de tu Pipeline
2. En **Build Triggers**, marca:
   - ✓ **GitHub hook trigger for GITScm polling**
3. Guarda

### 7. Ejecutar Pipeline Manualmente (Primera Vez)

1. Ve a tu Pipeline en Jenkins
2. Haz clic en **Build Now**
3. Observa la ejecución en tiempo real
4. Los reportes CSV se generarán en `test-reports/`

## 📊 Reportes Generados

El pipeline genera los siguientes reportes CSV:

### Backend
- `test-reports/backend/backend_test_report.csv` - Resumen de pruebas
- `test-reports/backend/backend_test_details.csv` - Detalles de cada prueba

### Frontend
- `test-reports/frontend/frontend_test_report.csv` - Resumen de pruebas
- `test-reports/frontend/frontend_coverage_report.csv` - Cobertura de código
- `test-reports/frontend/frontend_test_details.csv` - Detalles de cada prueba

### Consolidado
- `test-reports/consolidated_test_report.csv` - Reporte consolidado de todo el sistema

## 🔧 Configuración Avanzada

### Variables de Entorno

Puedes personalizar el pipeline editando las variables de entorno en el `Jenkinsfile`:

```groovy
environment {
    DB_HOST = 'postgres-test'
    DB_PORT = '5432'
    DB_NAME = 'postgres'
    DB_USERNAME = 'postgres'
    DB_PASSWORD = 'postgres'
    // ...
}
```

### Ejecutar Solo Pruebas Backend o Frontend

Puedes comentar las etapas que no necesites en el `Jenkinsfile`:

```groovy
// stage('Pruebas Frontend') {
//     // ... código comentado
// }
```

## 🐛 Solución de Problemas

### Jenkins no inicia

```powershell
# Verificar logs
docker-compose -f docker-compose.jenkins.yml logs jenkins

# Verificar permisos de Docker
docker ps
```

### PostgreSQL no está disponible

```powershell
# Verificar que el contenedor está corriendo
docker-compose -f docker-compose.jenkins.yml ps

# Verificar logs
docker-compose -f docker-compose.jenkins.yml logs postgres-test
```

### Las pruebas fallan

1. Verifica los logs del pipeline en Jenkins
2. Asegúrate de que PostgreSQL esté corriendo antes de las pruebas
3. Verifica que las dependencias estén instaladas (Maven, Node.js, npm)

### Webhook no funciona

1. Verifica que la URL del webhook sea accesible desde GitHub
2. Si Jenkins está detrás de un firewall, configura un túnel o usa ngrok
3. Verifica los logs de Jenkins: **Manage Jenkins > System Log**

## 📝 Notas Importantes

- **Base de Datos**: El pipeline usa PostgreSQL local en Docker, NO Supabase
- **Puerto**: Jenkins usa el puerto 8081 para evitar conflictos con el backend (8080)
- **Persistencia**: Los datos de Jenkins se guardan en el volumen `jenkins_home`
- **Reportes**: Los reportes se archivan automáticamente en cada ejecución del pipeline

## 🔄 Actualizar Jenkins

```powershell
# Detener Jenkins
docker-compose -f docker-compose.jenkins.yml down

# Actualizar imagen (si es necesario)
docker-compose -f docker-compose.jenkins.yml pull

# Reiniciar
docker-compose -f docker-compose.jenkins.yml up -d
```

## 🗑️ Limpiar Todo

```powershell
# Detener y eliminar contenedores y volúmenes
docker-compose -f docker-compose.jenkins.yml down -v

# Esto eliminará TODOS los datos de Jenkins (jobs, configuración, etc.)
```

