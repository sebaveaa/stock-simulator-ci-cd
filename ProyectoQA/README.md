# Stock Simulator - Proyecto Completo

Este proyecto contiene tanto el frontend (Angular) como el backend (Spring Boot) del simulador de acciones.

## 🚀 Inicio Rápido

### Opción 1: Usar Docker Compose Principal (Recomendado)

Para ejecutar todos los servicios (frontend, backend y base de datos) conectados:

```powershell
# Desde la raíz del proyecto
docker-compose up -d
```

Esto iniciará:
- **PostgreSQL** en el puerto `5432`
- **Backend (Spring Boot)** en el puerto `8080`
- **Frontend (Angular)** en el puerto `80`

### Acceder a la aplicación

- **Frontend**: http://localhost
- **Backend API**: http://localhost:8080/api
- **Base de datos**: localhost:5432

### Verificar que todo está funcionando

```powershell
# Ver el estado de los contenedores
docker-compose ps

# Ver los logs
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f frontend
docker-compose logs -f backend
docker-compose logs -f postgres
```

### Detener los servicios

```powershell
docker-compose down
```

### Detener y eliminar volúmenes (incluyendo datos de la BD)

```powershell
docker-compose down -v
```

## 🔧 Configuración

### Variables de Entorno

Puedes crear un archivo `.env` en la raíz del proyecto para personalizar la configuración:

```env
# Base de Datos
DB_NAME=postgres
DB_USERNAME=postgres
DB_PASSWORD=tu_contraseña
DB_PORT=5432

# Servidor Backend
SERVER_PORT=8080

# Servidor Frontend
FRONTEND_PORT=80

# CORS (orígenes permitidos separados por coma)
CORS_ALLOWED_ORIGINS=http://localhost:4200,http://localhost:80,http://localhost

# Email (opcional)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=tu-email@gmail.com
MAIL_PASSWORD=tu-app-password
```

## 📁 Estructura del Proyecto
```
ProyectoQA/
├── docker-compose.yml          # Docker Compose principal (usa este)
├── stock-simulator-angular/    # Frontend Angular
│   ├── docker-compose.yml      # Docker Compose individual (opcional)
│   └── ...
└── stock-simulator-spring/      # Backend Spring Boot
    ├── docker-compose.yml      # Docker Compose individual (opcional)
    └── ...
```

## 🔌 Conexión entre Servicios

Cuando usas el `docker-compose.yml` principal:

- **Frontend → Backend**: El frontend se conecta al backend usando el nombre del servicio Docker `http://backend:8080`
- **Backend → Base de Datos**: El backend se conecta a PostgreSQL usando el nombre del servicio `postgres:5432`
- **Red Docker**: Todos los servicios están en la misma red `stock-simulator-network` y pueden comunicarse entre sí

## 🛠️ Opción 2: Ejecutar Servicios por Separado

Si prefieres ejecutar los servicios por separado:

### Backend y Base de Datos

```powershell
cd stock-simulator-spring
docker-compose up -d
```

### Frontend (desde otra terminal)

```powershell
cd stock-simulator-angular
docker-compose up -d
```

**Nota**: En este caso, el frontend usará `host.docker.internal:8080` para conectarse al backend (funciona en Windows/Mac, pero puede requerir configuración adicional en Linux).

## 🐛 Troubleshooting

### Los servicios no se conectan

1. Verifica que todos los contenedores estén corriendo:
   ```powershell
   docker-compose ps
   ```

2. Verifica que estén en la misma red:
   ```powershell
   docker network inspect proyectoqa_stock-simulator-network
   ```

3. Revisa los logs para errores:
   ```powershell
   docker-compose logs backend
   docker-compose logs frontend
   ```

### Error de CORS

Si ves errores de CORS en la consola del navegador, verifica que el origen del frontend esté en `CORS_ALLOWED_ORIGINS`. El docker-compose principal ya incluye `http://localhost:80` y `http://localhost`.

### Puerto ya en uso

Si algún puerto está ocupado, puedes cambiarlo en el archivo `.env` o directamente en el `docker-compose.yml`.

## 📝 Notas Importantes

- El frontend usa Nginx como proxy reverso para las llamadas a `/api`, que se redirigen al backend
- La base de datos PostgreSQL persiste los datos en un volumen Docker llamado `postgres_data`
- Los servicios tienen healthchecks configurados para verificar su estado
- El backend espera a que la base de datos esté lista antes de iniciar (usando `depends_on` con condición de salud)

## 🔄 CI/CD con Jenkins

Este proyecto incluye una configuración completa de CI/CD con Jenkins que ejecuta automáticamente todas las pruebas cuando se hace un push a GitHub.

### Inicio Rápido CI/CD

```powershell
# Iniciar Jenkins
docker-compose -f docker-compose.jenkins.yml up -d

# Acceder a Jenkins
# http://localhost:8081
```

### Documentación CI/CD

- **[CI_CD_SETUP.md](CI_CD_SETUP.md)** - Guía completa de configuración CI/CD
- **[jenkins/QUICK_START.md](jenkins/QUICK_START.md)** - Inicio rápido (5 minutos)
- **[jenkins/README.md](jenkins/README.md)** - Documentación detallada de Jenkins
- **[jenkins/webhook-setup.md](jenkins/webhook-setup.md)** - Configuración de webhook de GitHub

### Características del Pipeline

- ✅ Ejecución automática en cada push a GitHub
- ✅ Pruebas Backend (Spring Boot / Maven / JUnit)
- ✅ Pruebas Frontend (Angular / Karma / Jasmine)
- ✅ Generación automática de reportes CSV
- ✅ PostgreSQL aislado para pruebas

### Reportes Generados

Después de cada ejecución, se generan reportes CSV en `test-reports/`:
- Resumen de pruebas backend y frontend
- Detalles de cada prueba
- Cobertura de código
- Reporte consolidado del sistema

