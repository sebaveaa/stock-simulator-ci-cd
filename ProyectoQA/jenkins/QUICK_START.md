# 🚀 Inicio Rápido - Jenkins CI/CD

Guía rápida para poner en marcha el pipeline CI/CD en 5 minutos.

## ⚡ Pasos Rápidos

### 1. Iniciar Jenkins (2 minutos)

```powershell
# Iniciar Jenkins
docker-compose -f docker-compose.jenkins.yml up -d

# Esperar 30 segundos y obtener contraseña inicial
Start-Sleep -Seconds 30
docker exec jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword
```

### 2. Configurar Jenkins (2 minutos)

1. Abre: `http://localhost:8081`
2. Pega la contraseña obtenida
3. Selecciona **"Install suggested plugins"**
4. Espera a que se instalen (1-2 minutos)
5. Crea un usuario administrador (o salta este paso)

### 3. Crear Pipeline (1 minuto)

1. En Jenkins, haz clic en **"New Item"**
2. Nombre: `stock-simulator-ci`
3. Selecciona **"Pipeline"** → **OK**
4. En la configuración:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: URL de tu repositorio GitHub
   - **Branch**: `*/main` o `*/master`
   - **Script Path**: `Jenkinsfile`
5. **Save**

### 4. Ejecutar Primera Vez

1. Haz clic en **"Build Now"**
2. Observa la ejecución en tiempo real
3. Los reportes CSV estarán en `test-reports/` después de completarse

## ✅ Verificar que Funciona

```powershell
# Ver estado de contenedores
docker-compose -f docker-compose.jenkins.yml ps

# Ver logs de Jenkins
docker-compose -f docker-compose.jenkins.yml logs -f jenkins
```

## 🔗 Siguiente Paso: Webhook

Una vez que el pipeline funcione manualmente, configura el webhook para ejecución automática:

**⚠️ IMPORTANTE**: GitHub NO puede acceder a `localhost`. Para desarrollo local, usa **ngrok** (la opción más simple):

### Configuración Rápida de ngrok:

1. **Descarga ngrok**: https://ngrok.com/download (gratis)
2. **Ejecuta**:
   ```powershell
   ngrok http 8081
   ```
3. **Copia la URL HTTPS** que ngrok muestra (ej: `https://abc123.ngrok.io`)
4. **Usa esa URL en GitHub**: `https://abc123.ngrok.io/github-webhook/`
5. **Habilita SSL verification** en GitHub

**✅ Ventajas de ngrok:**
- No requiere VPN
- No requiere abrir puertos
- Funciona en segundos
- HTTPS automático

Ver guías completas:
- **Guía rápida ngrok**: [`ngrok-setup.md`](ngrok-setup.md)
- **Guía completa webhook**: [`webhook-setup.md`](webhook-setup.md)

## 🆘 Problemas Comunes

**Jenkins no carga:**
- Espera 1-2 minutos más
- Verifica: `docker ps` (debe estar corriendo jenkins-server)

**No puedo acceder:**
- Verifica que el puerto 8081 no esté en uso
- Intenta: `http://localhost:8081`

**Pipeline falla:**
- Verifica que Docker esté corriendo
- Revisa los logs en Jenkins: Click en el build → Console Output

