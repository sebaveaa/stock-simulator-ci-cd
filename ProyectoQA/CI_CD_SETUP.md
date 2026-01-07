# 🚀 Configuración CI/CD con Jenkins

Este proyecto incluye una configuración completa de CI/CD con Jenkins que ejecuta automáticamente todas las pruebas del sistema cuando se hace un push a GitHub y genera reportes CSV.

## 📋 Resumen

- ✅ **Jenkins** configurado con Docker
- ✅ **Pipeline automatizado** que se ejecuta en cada push a GitHub
- ✅ **Soporte para repositorios separados** (Backend y Frontend en repos diferentes)
- ✅ **Pruebas Backend** (Spring Boot / Maven / JUnit)
- ✅ **Pruebas Frontend** (Angular / Karma / Jasmine)
- ✅ **Reportes CSV** automáticos
- ✅ **PostgreSQL** para pruebas aisladas

## 🔄 ¿Tienes Repositorios Separados?

Si tienes el **backend y frontend en repositorios separados**, consulta la guía específica:

👉 **[jenkins/MULTI_REPO_SETUP.md](jenkins/MULTI_REPO_SETUP.md)** - Configuración para múltiples repositorios

Esta guía explica cómo:
- Crear un repositorio CI/CD separado
- Configurar webhooks en ambos repositorios
- Hacer que el pipeline se ejecute cuando cualquiera de los dos repos se actualice

## 🎯 Respuesta a tus Preguntas

### ¿El proyecto se conecta a Supabase?

**No**, el proyecto se conecta a **PostgreSQL local** en Docker. La configuración está en:

- `docker-compose.yml` - Define el servicio PostgreSQL
- `stock-simulator-spring/src/main/resources/application.properties` - Configuración de conexión

El proyecto usa variables de entorno que se pueden sobrescribir, pero por defecto usa PostgreSQL local.

### ¿Por qué no veo tablas en PostgreSQL local?

Las tablas se crean automáticamente cuando el backend inicia gracias a la configuración JPA:

```properties
spring.jpa.hibernate.ddl-auto=update
```

Esto significa que las tablas se crean/actualizan automáticamente cuando la aplicación Spring Boot inicia. Si no ves tablas, puede ser porque:

1. El backend no se ha iniciado aún
2. La base de datos está en un contenedor Docker diferente
3. Necesitas conectarte a la base de datos correcta

Para verificar:

```powershell
# Ver contenedores corriendo
docker ps

# Conectarte a PostgreSQL
docker exec -it stock-simulator-db psql -U postgres -d postgres

# Listar tablas
\dt
```

## 🚀 Inicio Rápido

### 1. Iniciar Jenkins

```powershell
# Iniciar Jenkins y PostgreSQL para pruebas
docker-compose -f docker-compose.jenkins.yml up -d

# Ver logs
docker-compose -f docker-compose.jenkins.yml logs -f jenkins
```

### 2. Acceder a Jenkins

1. Abre: `http://localhost:8081`
2. Obtén la contraseña inicial:
   ```powershell
   docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Instala plugins sugeridos
4. Crea un usuario administrador

### 3. Configurar Pipeline

Sigue las instrucciones en [`jenkins/README.md`](jenkins/README.md)

### 4. Configurar Webhook de GitHub

Sigue las instrucciones en [`jenkins/webhook-setup.md`](jenkins/webhook-setup.md)

## 📁 Estructura de Archivos

```
ProyectoQA/
├── docker-compose.yml              # Docker Compose principal (aplicación)
├── docker-compose.jenkins.yml     # Docker Compose para Jenkins
├── Jenkinsfile                    # Pipeline de CI/CD
├── .gitignore                     # Archivos ignorados por Git
│
├── jenkins/
│   ├── README.md                  # Documentación de Jenkins
│   ├── webhook-setup.md           # Guía de configuración de webhook
│   ├── scripts/
│   │   ├── generate_backend_report.py      # Genera CSV de pruebas backend
│   │   ├── generate_frontend_report.py     # Genera CSV de pruebas frontend
│   │   └── generate_consolidated_report.py # Genera CSV consolidado
│   └── init-scripts/
│       └── install-plugins.sh     # Script de instalación de plugins
│
├── stock-simulator-spring/        # Backend (Spring Boot)
│   └── src/test/                  # Pruebas del backend
│
└── stock-simulator-angular/       # Frontend (Angular)
    └── src/app/                   # Pruebas del frontend
```

## 🔄 Flujo del Pipeline

1. **Checkout**: Obtiene el código del repositorio Git
2. **Preparar Entorno**: Crea directorios para reportes
3. **Iniciar PostgreSQL**: Levanta base de datos para pruebas
4. **Pruebas Backend**: Ejecuta pruebas Maven/JUnit
5. **Pruebas Frontend**: Ejecuta pruebas Angular/Karma
6. **Generar Reportes**: Crea reportes CSV consolidados
7. **Limpiar**: Elimina contenedores de prueba

## 📊 Reportes Generados

Después de cada ejecución del pipeline, se generan reportes CSV en `test-reports/`:

### Backend
- `backend/backend_test_report.csv` - Resumen
- `backend/backend_test_details.csv` - Detalles por prueba

### Frontend
- `frontend/frontend_test_report.csv` - Resumen
- `frontend/frontend_coverage_report.csv` - Cobertura de código
- `frontend/frontend_test_details.csv` - Detalles por prueba

### Consolidado
- `consolidated_test_report.csv` - Vista general de todo el sistema

## 🔧 Configuración

### Variables de Entorno del Pipeline

Puedes modificar las variables en `Jenkinsfile`:

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

### Ejecutar Pipeline Manualmente

1. Ve a Jenkins: `http://localhost:8081`
2. Selecciona tu Pipeline
3. Haz clic en **Build Now**

## 🐛 Solución de Problemas

### Jenkins no inicia

```powershell
# Verificar logs
docker-compose -f docker-compose.jenkins.yml logs jenkins

# Reiniciar
docker-compose -f docker-compose.jenkins.yml restart jenkins
```

### Las pruebas fallan

1. Verifica que PostgreSQL esté corriendo:
   ```powershell
   docker-compose -f docker-compose.jenkins.yml ps
   ```

2. Verifica los logs del pipeline en Jenkins

3. Ejecuta las pruebas localmente para verificar:
   ```powershell
   # Backend
   cd stock-simulator-spring
   mvn test
   
   # Frontend
   cd stock-simulator-angular
   npm test
   ```

### Webhook no funciona

Ver [`jenkins/webhook-setup.md`](jenkins/webhook-setup.md) para solución de problemas detallada.

## 📝 Próximos Pasos

1. ✅ Iniciar Jenkins
2. ✅ Configurar Pipeline
3. ✅ Configurar Webhook de GitHub
4. ✅ Hacer un push de prueba
5. ✅ Verificar reportes CSV generados

## 🔗 Enlaces Útiles

- [Documentación de Jenkins](https://www.jenkins.io/doc/)
- [Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [GitHub Webhooks](https://docs.github.com/en/developers/webhooks-and-events/webhooks)

## ⚠️ Notas Importantes

- **Puerto Jenkins**: 8081 (para evitar conflicto con backend en 8080)
- **Base de Datos**: PostgreSQL local, NO Supabase
- **Persistencia**: Los datos de Jenkins se guardan en volumen Docker
- **Reportes**: Se archivan automáticamente en cada ejecución

## 🆘 Soporte

Si tienes problemas:

1. Revisa los logs: `docker-compose -f docker-compose.jenkins.yml logs`
2. Verifica la documentación en `jenkins/README.md`
3. Revisa la configuración del webhook en `jenkins/webhook-setup.md`

