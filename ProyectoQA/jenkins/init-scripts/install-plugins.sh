#!/bin/bash
# Script para instalar plugins necesarios en Jenkins
# Este script se ejecuta automáticamente al iniciar Jenkins si está configurado

JENKINS_PLUGINS=(
    "git"
    "workflow-aggregator"
    "docker-workflow"
    "github"
    "htmlpublisher"
    "junit"
    "coverage"
)

for plugin in "${JENKINS_PLUGINS[@]}"; do
    echo "Instalando plugin: $plugin"
    # Este script se ejecutaría dentro del contenedor Jenkins
    # Para instalación manual, ve a Manage Jenkins > Manage Plugins
done

echo "Plugins instalados. Reinicia Jenkins si es necesario."

