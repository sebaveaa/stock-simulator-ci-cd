# 🔧 Solución de Problemas - Jenkins CI/CD

Guía para resolver problemas comunes con Jenkins y webhooks de GitHub.

## ❌ Error 403: Invalid HTTP Response: 403

Este error significa que GitHub puede llegar a Jenkins, pero Jenkins está rechazando la petición.

### Solución 1: Verificar Plugin de GitHub (Más Común)

1. En Jenkins, ve a **Manage Jenkins > Manage Plugins**
2. Busca en la pestaña **Installed**:
   - ✅ **GitHub plugin** debe estar instalado
   - ✅ **Git plugin** debe estar instalado
3. Si NO están instalados:
   - Ve a la pestaña **Available**
   - Busca "GitHub plugin"
   - Márcalo y haz clic en **Install without restart**
   - Espera a que se instale
   - Repite para "Git plugin" si falta

### Solución 2: Configurar GitHub en Jenkins

1. Ve a **Manage Jenkins > Configure System**
2. Busca la sección **GitHub**
3. Si no aparece la sección GitHub:
   - El plugin no está instalado (ver Solución 1)
4. Si aparece:
   - Deja la configuración por defecto (no es necesario configurar nada para webhooks básicos)
   - Guarda

### Solución 3: Verificar Configuración del Pipeline

1. Ve a tu Pipeline en Jenkins
2. Haz clic en **Configure**
3. En **Build Triggers**, verifica:
   - ✅ **GitHub hook trigger for GITScm polling** debe estar marcado
4. En **Pipeline**, verifica:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Debe ser la URL correcta de tu repositorio
   - **Credentials**: Si el repo es privado, debe tener credenciales válidas
5. Guarda los cambios

### Solución 4: Verificar Autenticación de Jenkins

Si Jenkins requiere autenticación, puede estar bloqueando el webhook:

1. Ve a **Manage Jenkins > Configure Global Security**
2. Verifica la configuración de autenticación
3. Si está habilitada, considera temporalmente deshabilitarla para pruebas:
   - **Security Realm**: None (solo para pruebas)
   - ⚠️ **Advertencia**: Esto hace Jenkins accesible sin contraseña. Solo para desarrollo local.

### Solución 5: Verificar Logs de Jenkins

1. Ve a **Manage Jenkins > System Log**
2. Busca errores relacionados con GitHub o webhooks
3. También puedes ver los logs del contenedor:
   ```powershell
   docker logs jenkins-server
   ```

### Solución 6: Probar Webhook Manualmente

1. En GitHub, ve a **Settings > Webhooks > [Tu webhook]**
2. Haz clic en **Recent Deliveries**
3. Haz clic en la última entrega fallida
4. Revisa el **Response** para ver el mensaje de error específico

### Solución 7: Verificar URL del Webhook

Asegúrate de que la URL termine en `/github-webhook/`:

✅ **Correcto**: `https://abc123.ngrok.io/github-webhook/`
❌ **Incorrecto**: `https://abc123.ngrok.io/`
❌ **Incorrecto**: `https://abc123.ngrok.io/github-webhook` (sin barra final)

## ✅ Verificación Paso a Paso

Sigue estos pasos en orden:

1. ✅ Jenkins está corriendo: `docker ps | grep jenkins`
2. ✅ ngrok está corriendo y muestra la URL correcta
3. ✅ Plugin de GitHub instalado en Jenkins
4. ✅ Pipeline configurado con "GitHub hook trigger"
5. ✅ URL del webhook termina en `/github-webhook/`
6. ✅ SSL verification habilitada (si usas HTTPS)

## 🔍 Otros Errores Comunes

### Error: "We couldn't deliver this payload"

- Jenkins no está corriendo
- ngrok no está corriendo
- URL incorrecta en el webhook

### Error: "Jenkins returned HTTP 404"

- URL incorrecta (falta `/github-webhook/`)
- Plugin de GitHub no instalado

### Error: "Connection refused"

- Jenkins no está corriendo
- Puerto incorrecto en ngrok

### El webhook funciona pero el pipeline no se ejecuta

1. Verifica que el Pipeline tenga "GitHub hook trigger" habilitado
2. Verifica que el repositorio en el Pipeline coincida con el del webhook
3. Verifica los logs: **Manage Jenkins > System Log**

## 📝 Checklist de Configuración

Antes de reportar un problema, verifica:

- [ ] Jenkins está corriendo (`docker ps`)
- [ ] ngrok está corriendo y muestra URL HTTPS
- [ ] Plugin de GitHub instalado en Jenkins
- [ ] Pipeline creado y configurado
- [ ] "GitHub hook trigger" habilitado en el Pipeline
- [ ] URL del webhook correcta (termina en `/github-webhook/`)
- [ ] Repositorio en Pipeline coincide con el del webhook
- [ ] Si el repo es privado, credenciales configuradas

## 🆘 Si Nada Funciona

1. Reinicia Jenkins:
   ```powershell
   docker restart jenkins-server
   ```

2. Reinicia ngrok (obtendrás nueva URL):
   ```powershell
   # Detén ngrok (Ctrl+C)
   # Reinicia
   ngrok http 8081
   # Actualiza la URL en GitHub
   ```

3. Revisa los logs completos:
   ```powershell
   docker logs jenkins-server --tail 100
   ```

4. Crea un nuevo Pipeline desde cero:
   - Elimina el Pipeline actual
   - Crea uno nuevo
   - Configura desde el principio

