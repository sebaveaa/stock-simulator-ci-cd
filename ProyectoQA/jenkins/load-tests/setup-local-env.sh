#!/bin/bash

# Script para configurar el entorno local para pruebas de carga

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${GREEN}Configurando entorno local para pruebas de carga...${NC}"

# Verificar Docker
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker encontrado${NC}"

# Verificar Docker Compose
if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker Compose no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker Compose encontrado${NC}"

# Verificar Java (para JMeter)
if ! command -v java >/dev/null 2>&1; then
    echo -e "${YELLOW}Advertencia: Java no está instalado${NC}"
    echo "Necesitas Java para ejecutar JMeter localmente"
    echo "Puedes usar Docker para ejecutar JMeter"
fi

# Verificar JMeter
if command -v jmeter >/dev/null 2>&1 || [ -f "/opt/jmeter/bin/jmeter" ] || [ -n "$JMETER_HOME" ]; then
    echo -e "${GREEN}✓ JMeter encontrado${NC}"
else
    echo -e "${YELLOW}Advertencia: JMeter no está instalado${NC}"
    echo "Instala JMeter o usa Docker para ejecutar las pruebas"
fi

# Verificar docker-compose para load tests
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.load-test.yml"
if [ -f "$COMPOSE_FILE" ]; then
    echo -e "${GREEN}Iniciando servicios con Docker Compose...${NC}"
    
    cd "$SCRIPT_DIR"
    
    # Detener servicios existentes si están corriendo
    docker-compose -f docker-compose.load-test.yml down 2>/dev/null || true
    
    # Iniciar servicios
    docker-compose -f docker-compose.load-test.yml up -d
    
    echo -e "${GREEN}Esperando a que los servicios estén listos...${NC}"
    
    # Esperar a que PostgreSQL esté listo
    echo "Esperando PostgreSQL..."
    for i in {1..30}; do
        if docker-compose -f docker-compose.load-test.yml exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
            echo -e "${GREEN}✓ PostgreSQL está listo${NC}"
            break
        fi
        sleep 1
    done
    
    # Esperar a que el backend esté listo
    echo "Esperando backend..."
    for i in {1..60}; do
        if curl -f -s http://localhost:8080/actuator/health >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Backend está listo${NC}"
            break
        fi
        sleep 2
    done
    
    echo ""
    echo -e "${GREEN}✓ Entorno listo para pruebas de carga${NC}"
    echo ""
    echo "Servicios disponibles:"
    echo "  Backend: http://localhost:8080"
    echo "  PostgreSQL: localhost:5432"
    echo ""
    echo "Para ejecutar las pruebas:"
    echo "  cd $SCRIPT_DIR/.."
    echo "  ./scripts/run_load_tests.sh --scenario normal"
    echo ""
else
    echo -e "${YELLOW}Advertencia: docker-compose.load-test.yml no encontrado${NC}"
    echo "Usa el docker-compose principal o inicia los servicios manualmente"
fi

