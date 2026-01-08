#!/bin/bash

# Script para ejecutar pruebas de carga con JMeter
# Puede ejecutarse manualmente o desde Jenkins

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directorios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOAD_TESTS_DIR="$PROJECT_ROOT/ProyectoQA/jenkins/load-tests"
REPORTS_DIR="$LOAD_TESTS_DIR/load-test-reports"

# Variables por defecto
SCENARIO="normal"
BACKEND_URL="http://localhost:8080"
HEALTH_ENDPOINT="/actuator/health"
CONFIG_FILE="$LOAD_TESTS_DIR/load-test-config.properties"

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --scenario)
            SCENARIO="$2"
            shift 2
            ;;
        --backend-url)
            BACKEND_URL="$2"
            shift 2
            ;;
        --health-endpoint)
            HEALTH_ENDPOINT="$2"
            shift 2
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Uso: $0 [OPCIONES]"
            echo ""
            echo "Opciones:"
            echo "  --scenario SCENARIO      Escenario de carga: normal, peak, stress (default: normal)"
            echo "  --backend-url URL        URL del backend (default: http://localhost:8080)"
            echo "  --health-endpoint PATH   Endpoint de health check (default: /actuator/health)"
            echo "  --config FILE            Archivo de configuración (default: load-test-config.properties)"
            echo "  --help                   Muestra esta ayuda"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Opción desconocida: $1${NC}"
            exit 1
            ;;
    esac
done

# Cargar configuración desde archivo si existe
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}Cargando configuración desde: $CONFIG_FILE${NC}"
    source <(grep -v '^#' "$CONFIG_FILE" | grep -v '^$' | sed 's/\(.*\)=\(.*\)/export \1=\2/')
fi

# Detectar si estamos en Jenkins
if [ -n "$JENKINS_URL" ] || [ -n "$BUILD_NUMBER" ]; then
    IS_JENKINS=true
    echo -e "${YELLOW}Ejecutando en entorno Jenkins${NC}"
else
    IS_JENKINS=false
    echo -e "${GREEN}Ejecutando manualmente${NC}"
fi

# Verificar si JMeter está instalado
if command -v jmeter >/dev/null 2>&1; then
    JMETER_CMD="jmeter"
    echo -e "${GREEN}JMeter encontrado en el sistema${NC}"
elif [ -f "/opt/jmeter/bin/jmeter" ]; then
    JMETER_CMD="/opt/jmeter/bin/jmeter"
    echo -e "${GREEN}JMeter encontrado en /opt/jmeter${NC}"
elif [ -n "$JMETER_HOME" ] && [ -f "$JMETER_HOME/bin/jmeter" ]; then
    JMETER_CMD="$JMETER_HOME/bin/jmeter"
    echo -e "${GREEN}JMeter encontrado en $JMETER_HOME${NC}"
else
    echo -e "${RED}Error: JMeter no está instalado${NC}"
    echo "Instala JMeter o configura JMETER_HOME"
    exit 1
fi

# Verificar Java
if ! command -v java >/dev/null 2>&1; then
    echo -e "${RED}Error: Java no está instalado${NC}"
    exit 1
fi

# Verificar que el backend esté disponible
echo -e "${YELLOW}Verificando que el backend esté disponible en $BACKEND_URL$HEALTH_ENDPOINT${NC}"
if curl -f -s "$BACKEND_URL$HEALTH_ENDPOINT" > /dev/null 2>&1; then
    echo -e "${GREEN}Backend está disponible${NC}"
else
    echo -e "${RED}Error: Backend no está disponible en $BACKEND_URL$HEALTH_ENDPOINT${NC}"
    echo "Asegúrate de que el backend esté corriendo"
    exit 1
fi

# Obtener configuración del escenario
case $SCENARIO in
    normal)
        USERS=${scenario.normal.users:-50}
        RAMPUP=${scenario.normal.rampup:-60}
        DURATION=${scenario.normal.duration:-300}
        ;;
    peak)
        USERS=${scenario.peak.users:-200}
        RAMPUP=${scenario.peak.rampup:-120}
        DURATION=${scenario.peak.duration:-600}
        ;;
    stress)
        USERS=${scenario.stress.users:-500}
        RAMPUP=${scenario.stress.rampup:-180}
        DURATION=${scenario.stress.duration:-900}
        ;;
    *)
        echo -e "${RED}Error: Escenario desconocido: $SCENARIO${NC}"
        echo "Escenarios disponibles: normal, peak, stress"
        exit 1
        ;;
esac

echo -e "${GREEN}Configuración del escenario '$SCENARIO':${NC}"
echo "  Usuarios concurrentes: $USERS"
echo "  Ramp-up (segundos): $RAMPUP"
echo "  Duración (segundos): $DURATION"

# Crear directorio de reportes
mkdir -p "$REPORTS_DIR"

# Archivo JMX
JMX_FILE="$LOAD_TESTS_DIR/stock-simulator-load-test.jmx"
if [ ! -f "$JMX_FILE" ]; then
    echo -e "${RED}Error: Archivo JMX no encontrado: $JMX_FILE${NC}"
    exit 1
fi

# Timestamp para reportes
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_PREFIX="$REPORTS_DIR/load-test-${SCENARIO}-${TIMESTAMP}"
JTL_FILE="${REPORT_PREFIX}.jtl"
HTML_REPORT_DIR="${REPORT_PREFIX}-html"

echo -e "${GREEN}Iniciando pruebas de carga...${NC}"
echo "JMX: $JMX_FILE"
echo "Reporte JTL: $JTL_FILE"
echo "Reporte HTML: $HTML_REPORT_DIR"

# Ejecutar JMeter
"$JMETER_CMD" \
    -n \
    -t "$JMX_FILE" \
    -l "$JTL_FILE" \
    -e \
    -o "$HTML_REPORT_DIR" \
    -Jbackend.url="$BACKEND_URL" \
    -Jscenario.users="$USERS" \
    -Jscenario.rampup="$RAMPUP" \
    -Jscenario.duration="$DURATION" \
    -j "${REPORT_PREFIX}.log"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Pruebas de carga completadas exitosamente${NC}"
    
    # Crear enlace simbólico al último reporte
    ln -sfn "load-test-${SCENARIO}-${TIMESTAMP}-html" "$REPORTS_DIR/latest-html"
    
    echo ""
    echo -e "${GREEN}Reportes generados:${NC}"
    echo "  JTL: $JTL_FILE"
    echo "  HTML: $HTML_REPORT_DIR/index.html"
    echo "  Log: ${REPORT_PREFIX}.log"
    
    # Abrir reporte HTML si no estamos en Jenkins
    if [ "$IS_JENKINS" = false ] && command -v xdg-open >/dev/null 2>&1; then
        echo -e "${YELLOW}Abriendo reporte HTML...${NC}"
        xdg-open "$HTML_REPORT_DIR/index.html" 2>/dev/null &
    elif [ "$IS_JENKINS" = false ] && command -v open >/dev/null 2>&1; then
        echo -e "${YELLOW}Abriendo reporte HTML...${NC}"
        open "$HTML_REPORT_DIR/index.html" 2>/dev/null &
    fi
    
    # Ejecutar script de análisis si existe
    if [ -f "$SCRIPT_DIR/generate_load_test_report.py" ]; then
        echo -e "${YELLOW}Generando reporte consolidado...${NC}"
        python3 "$SCRIPT_DIR/generate_load_test_report.py" "$JTL_FILE" "$REPORTS_DIR" || echo "No se pudo generar reporte consolidado"
    fi
    
    exit 0
else
    echo -e "${RED}✗ Error ejecutando las pruebas de carga${NC}"
    exit 1
fi

