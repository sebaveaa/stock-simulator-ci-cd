# 🔧 Solución de Problemas - Jenkins Pipeline

## ✅ Problemas Corregidos

1. **`publishTestResults` → `junit`**: Corregido en el Jenkinsfile
2. **Dockerfile personalizado creado**: Con Docker CLI, Maven, Node.js y Python

## 🚀 Pasos para Solucionar

### 1. Reconstruir el Contenedor de Jenkins

El contenedor de Jenkins ahora tiene un Dockerfile personalizado con todas las herramientas. **DEBES reconstruir el contenedor**:

```powershell
# Detener el contenedor actual
docker-compose -f docker-compose.jenkins.yml down

# Reconstruir con el nuevo Dockerfile
docker-compose -f docker-compose.jenkins.yml build --no-cache jenkins

# Iniciar de nuevo
docker-compose -f docker-compose.jenkins.yml up -d
```

### 2. Verificar que Funciona

```powershell
# Verificar que Docker CLI está disponible
docker exec jenkins-server docker --version

# Verificar Maven
docker exec jenkins-server mvn --version

# Verificar Node.js/npm
docker exec jenkins-server node --version
docker exec jenkins-server npm --version

# Verificar Python
docker exec jenkins-server python3 --version
```

### 3. Plugins de Jenkins Necesarios

Asegúrate de tener estos plugins instalados en Jenkins:

#### Plugins OBLIGATORIOS (generalmente ya incluidos):
- ✅ **Git Plugin** (para clonar repositorios)
- ✅ **Pipeline Plugin** (para ejecutar pipelines)
- ✅ **JUnit Plugin** (para mostrar resultados de pruebas XML)

#### Plugins OPCIONALES (recomendados):
- **Docker Pipeline Plugin** (si quieres usar sintaxis Docker en pipelines)
- **GitHub Plugin** (para webhooks de GitHub)
- **HTML Publisher Plugin** (para publicar reportes HTML)

#### Cómo instalar plugins:
1. Ve a **Manage Jenkins** → **Manage Plugins**
2. Busca cada plugin en la pestaña **Available**
3. Selecciona y haz clic en **Install without restart**
4. Reinicia Jenkins cuando termine

### 4. Verificar Configuración de Docker

El contenedor de Jenkins necesita acceso al socket de Docker del host. Verifica que está montado correctamente:

```powershell
# Verificar que el socket está montado
docker exec jenkins-server ls -la /var/run/docker.sock

# Probar ejecutar un contenedor desde Jenkins
docker exec jenkins-server docker run hello-world
```

Si no funciona, verifica que el `docker-compose.jenkins.yml` tiene:
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

### 5. Red Docker

El contenedor de PostgreSQL debe estar en la misma red que Jenkins. Verifica:

```powershell
# Ver redes Docker
docker network ls

# Verificar que jenkins-network existe
docker network inspect jenkins-network
```

Si no existe, el `docker-compose.jenkins.yml` la crea automáticamente.

### 6. Probar el Pipeline

1. Ve a Jenkins: `http://localhost:8081`
2. Ejecuta el pipeline manualmente con **Build Now**
3. Revisa los logs en tiempo real

## 🐛 Errores Comunes

### Error: "docker: not found"
**Solución**: Reconstruye el contenedor con el nuevo Dockerfile (paso 1)

### Error: "mvn: not found"
**Solución**: Reconstruye el contenedor con el nuevo Dockerfile (paso 1)

### Error: "npm: not found"
**Solución**: Reconstruye el contenedor con el nuevo Dockerfile (paso 1)

### Error: "publishTestResults not found"
**Solución**: Ya corregido, ahora usa `junit` en lugar de `publishTestResults`

### Error: "Cannot connect to Docker daemon"
**Solución**: Verifica que el socket de Docker está montado (paso 4)

### Error: PostgreSQL no inicia
**Solución**: Verifica que la red `jenkins-network` existe (paso 5)

## 📝 Notas Importantes

1. **Primera vez**: Después de reconstruir, puede que necesites configurar Jenkins de nuevo (contraseña inicial, plugins, etc.)

2. **Contraseña inicial**: 
   ```powershell
   docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword
   ```

3. **Permisos**: El contenedor corre como `root` para tener permisos Docker, pero luego cambia a usuario `jenkins` para seguridad.

4. **Volúmenes**: Los volúmenes de Jenkins se mantienen entre reconstrucciones, así que no perderás configuración.

## ✅ Checklist Final

- [ ] Contenedor reconstruido con nuevo Dockerfile
- [ ] Docker CLI funciona en el contenedor
- [ ] Maven instalado y funciona
- [ ] Node.js/npm instalados y funcionan
- [ ] Python instalado y funciona
- [ ] Plugins de Jenkins instalados (Git, Pipeline, JUnit)
- [ ] Socket de Docker montado correctamente
- [ ] Red `jenkins-network` existe
- [ ] Pipeline ejecuta sin errores

