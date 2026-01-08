# Pruebas de Carga - Stock Simulator

Este directorio contiene los scripts y configuraciones para ejecutar pruebas de carga en el sistema de simulación de stocks usando Apache JMeter.

## 📋 Requisitos Previos

- **Java 8+** (requerido para JMeter)
- **Apache JMeter 5.6+** (o usar Docker)
- **Docker y Docker Compose** (para entorno de pruebas)
- **Python 3** (para scripts de reportes)

## 🚀 Ejecución Manual

### Opción 1: Ejecución Rápida con Docker

```bash
# 1. Configurar y levantar entorno
cd ProyectoQA/jenkins/load-tests
./setup-local-env.sh  # Linux/Mac
# o
.\setup-local-env.ps1  # Windows PowerShell

# 2. Ejecutar pruebas
cd ..
./scripts/run_load_tests.sh --scenario normal
```

### Opción 2: Ejecución Manual Paso a Paso

#### 1. Iniciar Backend y Base de Datos

```bash
# Opción A: Usar docker-compose principal
cd ProyectoQA
docker-compose up -d backend postgres

# Opción B: Usar docker-compose específico para load tests
cd ProyectoQA/jenkins/load-tests
docker-compose -f docker-compose.load-test.yml up -d
```

#### 2. Verificar que el Backend está Disponible

```bash
curl http://localhost:8080/actuator/health
```

#### 3. Configurar Variables (Opcional)

Edita `load-test-config.properties` si necesitas personalizar:
- URL del backend
- Usuarios concurrentes
- Tiempos de ramp-up y duración
- Umbrales de validación

#### 4. Ejecutar Pruebas

```bash
# Desde el directorio ProyectoQA/jenkins
./scripts/run_load_tests.sh --scenario normal --backend-url http://localhost:8080

# O en Windows PowerShell
.\scripts\run_load_tests.ps1 -Scenario normal -BackendUrl http://localhost:8080
```

#### 5. Ver Reportes

Los reportes se generan en `load-test-reports/`:
- **HTML**: `load-test-reports/latest-html/index.html` - Reporte visual completo
- **JTL**: `load-test-reports/*.jtl` - Resultados en formato JTL
- **CSV**: `load-test-reports/load_test_summary_*.csv` - Resumen consolidado

## 📊 Escenarios de Carga

### Normal (50 usuarios)
```bash
./scripts/run_load_tests.sh --scenario normal
```
- 50 usuarios concurrentes
- Ramp-up: 60 segundos
- Duración: 5 minutos

### Peak (200 usuarios)
```bash
./scripts/run_load_tests.sh --scenario peak
```
- 200 usuarios concurrentes
- Ramp-up: 120 segundos
- Duración: 10 minutos

### Stress (500 usuarios)
```bash
./scripts/run_load_tests.sh --scenario stress
```
- 500 usuarios concurrentes
- Ramp-up: 180 segundos
- Duración: 15 minutos

## 🔧 Configuración

### Archivo de Configuración: `load-test-config.properties`

```properties
# URL del backend
backend.url=http://localhost:8080
backend.health.endpoint=/actuator/health

# Configuración de escenarios
scenario.normal.users=50
scenario.normal.rampup=60
scenario.normal.duration=300

# Umbrales de validación
max.avg.response.time.ms=1000
max.error.percentage=1.0
min.throughput.per.second=10
```

### Variables de Entorno

También puedes usar variables de entorno:
```bash
export BACKEND_URL=http://localhost:8080
export SCENARIO=normal
./scripts/run_load_tests.sh
```

## 📈 Interpretación de Resultados

### Métricas Clave

1. **Tiempo de Respuesta Promedio**: Tiempo promedio que tarda el servidor en responder
2. **Percentil 95 (P95)**: 95% de las requests completan en este tiempo o menos
3. **Percentil 99 (P99)**: 99% de las requests completan en este tiempo o menos
4. **Porcentaje de Errores**: Porcentaje de requests que fallaron
5. **Throughput**: Número de requests procesadas por segundo

### Reportes HTML de JMeter

El reporte HTML incluye:
- **Dashboard**: Vista general con gráficos y métricas clave
- **Charts**: Gráficos de tiempo de respuesta, throughput, etc.
- **Statistics**: Estadísticas detalladas por endpoint
- **Errors**: Lista de errores encontrados

### Reporte CSV Consolidado

El script `generate_load_test_report.py` genera un CSV con:
- Métricas agregadas (totales, promedios, percentiles)
- Estadísticas por endpoint
- Validación contra umbrales configurados

## 🔄 Ejecución desde Jenkins

Las pruebas de carga están integradas en el pipeline de Jenkins pero son **opcionales** por defecto.

### Activar en Jenkins

#### Opción 1: Variable de Entorno
Configura en el job de Jenkins:
- Variable: `RUN_LOAD_TESTS`
- Valor: `true`

#### Opción 2: Branch Main
Las pruebas se ejecutan automáticamente en el branch `main`.

#### Opción 3: Parámetro de Build
Puedes agregar un parámetro boolean `RUN_LOAD_TESTS` y activarlo manualmente.

### Ver Reportes en Jenkins

1. Ve al build que ejecutó las pruebas de carga
2. Los reportes están en "Artifacts" → `jenkins/load-tests/load-test-reports/`
3. Descarga el reporte HTML y ábrelo en tu navegador

## 🐛 Troubleshooting

### Error: "JMeter no está instalado"

**Solución**: 
- Instala JMeter desde https://jmeter.apache.org/download_jmeter.cgi
- O configura `JMETER_HOME` apuntando a la instalación
- O usa Docker para ejecutar JMeter

### Error: "Backend no está disponible"

**Solución**:
- Verifica que el backend esté corriendo: `curl http://localhost:8080/actuator/health`
- Inicia el backend con `docker-compose up -d backend`
- Verifica la URL en `load-test-config.properties`

### Error: "Java no está instalado"

**Solución**:
- Instala Java 8 o superior
- Verifica con `java -version`

### Las pruebas son muy lentas

**Posibles causas**:
- Muy pocos recursos en el servidor
- Backend no optimizado
- Demasiados usuarios concurrentes

**Soluciones**:
- Reduce el número de usuarios en el escenario
- Optimiza el backend
- Ejecuta en un servidor con más recursos

### Alto porcentaje de errores

**Verifica**:
1. Logs del backend para ver qué errores están ocurriendo
2. Si el backend puede manejar la carga
3. Configuración de base de datos (conexiones, timeouts)
4. Si hay datos suficientes en la BD para las pruebas

## 📝 Personalización

### Agregar Nuevos Endpoints

1. Abre `stock-simulator-load-test.jmx` en JMeter GUI
2. Agrega nuevos HTTP Request samplers
3. Configura los endpoints que necesites
4. Guarda el archivo

### Modificar Escenarios

Edita `load-test-config.properties`:
```properties
scenario.normal.users=100  # Aumentar usuarios
scenario.normal.duration=600  # Aumentar duración
```

### Agregar Autenticación

Si tu API requiere autenticación:
1. Agrega un HTTP Header Manager en JMeter con el token
2. O usa HTTP Authorization Manager
3. Configura credenciales en `load-test-config.properties`

## 📚 Recursos Adicionales

- [Documentación de JMeter](https://jmeter.apache.org/usermanual/)
- [Guía de Pruebas de Carga](https://jmeter.apache.org/usermanual/test_plan.html)
- [Pipeline CI/CD](../README.md)

## ✅ Checklist Pre-Ejecución

- [ ] Backend corriendo y accesible
- [ ] Base de datos disponible
- [ ] JMeter instalado o Docker disponible
- [ ] Java instalado (si usas JMeter local)
- [ ] Configuración revisada (`load-test-config.properties`)
- [ ] Datos de prueba cargados en la BD (si es necesario)

## 🎯 Buenas Prácticas

1. **Empieza con escenarios pequeños**: Usa `normal` antes de `stress`
2. **Monitorea recursos**: Vigila CPU, memoria y red durante las pruebas
3. **Revisa logs**: Los logs del backend te dirán qué está fallando
4. **Prueba en ambiente similar a producción**: Configuración, datos, recursos
5. **Documenta los resultados**: Guarda reportes para comparar mejoras

