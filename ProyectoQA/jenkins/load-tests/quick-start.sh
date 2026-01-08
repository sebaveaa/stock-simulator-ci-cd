#!/bin/bash

# Script de inicio rápido para pruebas de carga

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Inicio Rápido - Pruebas de Carga ===${NC}"
echo ""

# Verificar y configurar entorno
echo -e "${YELLOW}1. Configurando entorno...${NC}"
"$SCRIPT_DIR/setup-local-env.sh"

# Esperar un poco más para asegurar que todo esté listo
echo ""
echo -e "${YELLOW}Esperando 10 segundos adicionales para estabilización...${NC}"
sleep 10

# Ejecutar pruebas normales
echo ""
echo -e "${YELLOW}2. Ejecutando pruebas de carga (escenario normal)...${NC}"
cd "$SCRIPT_DIR/.."
./scripts/run_load_tests.sh --scenario normal

echo ""
echo -e "${GREEN}✓ Pruebas completadas${NC}"
echo ""
echo "Para ver los reportes:"
echo "  cd $SCRIPT_DIR/load-test-reports"
echo "  Abre latest-html/index.html en tu navegador"

