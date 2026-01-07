# Configuración de Webhook de GitHub para Jenkins

Esta guía te ayudará a configurar el webhook de GitHub para que Jenkins ejecute automáticamente el pipeline cuando se haga un push al repositorio.

## ⚠️ IMPORTANTE: GitHub NO puede acceder a localhost

**GitHub rechazará cualquier URL con `localhost`** porque no es accesible desde Internet público. Necesitas usar una de las opciones a continuación.

## 🔧 Configuración Paso a Paso

### Paso 1: Obtener la URL de Jenkins

La URL del webhook debe ser accesible desde Internet público. Tienes varias opciones:

#### Opción A: Usar ngrok (Recomendado - La más simple) ⭐

Esta es la mejor opción para desarrollo local. ngrok crea un túnel HTTPS público hacia tu Jenkins local **sin necesidad de VPN ni configuración de firewall**.

**Instalación rápida (2 minutos):**

1. Descarga ngrok desde https://ngrok.com/download (gratis, no requiere registro)
2. Extrae el archivo `ngrok.exe` a una carpeta (ej: `C:\ngrok\`)
3. Abre PowerShell y ejecuta:
   ```powershell
   cd C:\ngrok
   .\ngrok http 8081
   ```
   O si agregaste ngrok al PATH:
   ```powershell
   ngrok http 8081
   ```

4. ngrok mostrará algo como:
   ```
   Forwarding  https://abc123.ngrok.io -> http://localhost:8081
   ```

5. **Copia la URL HTTPS** (ej: `https://abc123.ngrok.io`)

6. Usa esta URL en el webhook de GitHub:
   ```
   https://abc123.ngrok.io/github-webhook/
   ```

7. **Habilita SSL verification** (ngrok usa certificados válidos)

**✅ Ventajas:**
- ✅ No requiere VPN
- ✅ No requiere abrir puertos en firewall
- ✅ No requiere IP pública
- ✅ HTTPS automático con certificado válido
- ✅ Gratis para uso básico
- ✅ Funciona en segundos

**⚠️ Nota**: La URL de ngrok cambia cada vez que lo reinicias (a menos que tengas cuenta de pago). Si necesitas una URL fija, considera la cuenta de pago de ngrok ($8/mes) o usa una de las alternativas abajo.

#### Opción B: Jenkins en servidor con IP pública

Si Jenkins está en un servidor accesible desde Internet:

```
http://TU_IP_PUBLICA:8081/github-webhook/
```

**Ejemplo:**
```
http://203.0.113.42:8081/github-webhook/
```

**⚠️ Requisitos:**
- El servidor debe tener IP pública
- El puerto 8081 debe estar abierto en el firewall
- Considera usar HTTPS con certificado válido para mayor seguridad

#### Opción C: Alternativas a ngrok (Otras opciones simples)

Si prefieres otras alternativas a ngrok:

**1. localtunnel (Gratis, sin instalación)**

```powershell
# Instalar Node.js primero si no lo tienes
npm install -g localtunnel

# Crear túnel
lt --port 8081
```

**2. cloudflared (Cloudflare Tunnel - Gratis)**

```powershell
# Descargar desde: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/
cloudflared tunnel --url http://localhost:8081
```

**3. serveo (Sin instalación, solo SSH)**

```powershell
# Requiere SSH (generalmente ya instalado en Windows 10+)
ssh -R 80:localhost:8081 serveo.net
```

**Recomendación**: ngrok sigue siendo la opción más simple y confiable.

#### Opción D: Jenkins en producción con dominio y HTTPS

Si tienes un dominio y certificado SSL:

```
https://jenkins.tudominio.com/github-webhook/
```

**Requisitos:**
- Dominio configurado
- Certificado SSL válido
- Proxy reverso (nginx, Apache, etc.) configurado
- **Habilita SSL verification** para máxima seguridad

### Paso 2: Configurar Webhook en GitHub

1. Ve a tu repositorio en GitHub
2. Haz clic en **Settings** (Configuración)
3. En el menú lateral, haz clic en **Webhooks**
4. Haz clic en **Add webhook** (Agregar webhook)
5. Completa el formulario:
   - **Payload URL**: La URL que obtuviste en el Paso 1 (debe ser accesible desde Internet)
   - **Content type**: Selecciona `application/json`
   - **SSL verification**: 
     
     | Escenario | URL | SSL Verification | Razón |
     |-----------|-----|------------------|-------|
     | Desarrollo con ngrok | `https://abc123.ngrok.io/...` | ✅ **Habilitar** | ngrok usa certificados válidos |
     | Servidor con IP pública (HTTP) | `http://203.0.113.42:8081/...` | ❌ **Deshabilitar** | No hay SSL en HTTP |
     | Producción (HTTPS válido) | `https://jenkins.tudominio.com/...` | ✅ **Habilitar** | Certificado válido, máxima seguridad |
     | Producción (certificado autofirmado) | `https://...` | ❌ **Deshabilitar** | Solo si no puedes obtener certificado válido |
     
     **⚠️ IMPORTANTE:**
     - ❌ **NO uses `localhost`** - GitHub lo rechazará
     - ✅ **Para desarrollo local**: Usa ngrok (Opción A)
     - ✅ **Regla general**: `https://...` → Habilitar SSL | `http://...` → Deshabilitar SSL
     - ⚠️ **Nunca deshabilites SSL en producción** a menos que sea absolutamente necesario
   
   - **Secret**: (Opcional pero **altamente recomendado**) Genera un secreto para mayor seguridad
   - **Which events would you like to trigger this webhook?**:
     - Selecciona **Just the push event** (Solo eventos de push)
     - O **Let me select individual events** y marca:
       - ✓ Pushes
       - ✓ Pull requests (opcional)
   - **Active**: Asegúrate de que esté marcado ✓
6. Haz clic en **Add webhook**

### Paso 3: Configurar Jenkins para Recibir Webhooks

1. Inicia sesión en Jenkins (`http://localhost:8081`)
2. Ve a tu Pipeline (o créalo si no existe)
3. Haz clic en **Configure** (Configurar)
4. En la sección **Build Triggers**, marca:
   - ✓ **GitHub hook trigger for GITScm polling**
5. Guarda la configuración

### Paso 4: Verificar la Configuración

1. En GitHub, después de crear el webhook, verás un checkmark verde ✓ si la conexión fue exitosa
2. Si hay un error, verás una X roja. Haz clic en el webhook para ver los detalles del error
3. Haz un push de prueba a tu repositorio:
   ```powershell
   git add .
   git commit -m "Test webhook"
   git push origin main
   ```
4. Ve a Jenkins y verifica que el pipeline se ejecute automáticamente

## 🔍 Solución de Problemas

### El webhook muestra un error en GitHub

**Error: "is not supported because it isn't reachable over the public Internet (localhost)"**

- ❌ **Problema**: Estás usando `localhost` en la URL
- ✅ **Solución**: Usa ngrok (ver Opción A arriba) o una IP pública
- **Ejemplo de URL incorrecta**: `http://localhost:8081/github-webhook/`
- **Ejemplo de URL correcta**: `https://abc123.ngrok.io/github-webhook/`

**Error: "We couldn't deliver this payload"**

- Verifica que Jenkins esté corriendo: `docker-compose -f docker-compose.jenkins.yml ps`
- Verifica que la URL sea correcta y accesible desde Internet
- **Si usas localhost**: GitHub lo rechazará. Debes usar ngrok o una IP pública
- Si usas ngrok: Verifica que ngrok esté corriendo y que la URL sea correcta
- Si usas IP pública: Verifica que el puerto 8081 esté abierto en el firewall

**Error: "Jenkins returned HTTP 403"** ⚠️ **ERROR COMÚN**

Este error significa que GitHub puede llegar a Jenkins, pero Jenkins rechaza la petición. Soluciones:

1. **Verificar Plugin de GitHub** (más común):
   - Ve a **Manage Jenkins > Manage Plugins > Installed**
   - Busca "GitHub plugin" - debe estar instalado
   - Si no está, instálalo desde **Available**

2. **Verificar Configuración del Pipeline**:
   - Ve a tu Pipeline > **Configure**
   - En **Build Triggers**, marca: ✅ **GitHub hook trigger for GITScm polling**
   - Guarda

3. **Verificar Autenticación**:
   - Si Jenkins requiere login, puede estar bloqueando el webhook
   - Para desarrollo local, considera deshabilitar autenticación temporalmente

4. **Ver Logs**:
   - Ve a **Manage Jenkins > System Log**
   - O ejecuta: `docker logs jenkins-server`

**Ver guía completa**: [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md)

**Error: "Jenkins returned HTTP 404"**

- Verifica que la URL termine en `/github-webhook/`
- Verifica que el plugin de GitHub esté instalado

### El webhook funciona pero el pipeline no se ejecuta

1. Verifica que el Pipeline tenga marcado "GitHub hook trigger for GITScm polling"
2. Verifica los logs de Jenkins: **Manage Jenkins > System Log**
3. Verifica que el repositorio configurado en el Pipeline coincida con el del webhook

### Usar un secreto para mayor seguridad

1. Genera un secreto aleatorio:
   ```powershell
   # En PowerShell
   [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([System.Guid]::NewGuid().ToString()))
   ```

2. En GitHub, al crear el webhook, pega el secreto en el campo **Secret**

3. En Jenkins:
   - Ve a **Manage Jenkins > Configure System**
   - Busca la sección **GitHub**
   - Agrega el mismo secreto en **Shared secrets**

## 📝 Notas Adicionales

- Los webhooks de GitHub tienen un timeout de 10 segundos. Si tu pipeline tarda más, GitHub mostrará un error, pero el pipeline seguirá ejecutándose en Jenkins.
- Puedes ver el historial de entregas del webhook en GitHub: **Settings > Webhooks > [Tu webhook] > Recent Deliveries**
- Para desarrollo local, **ngrok es la mejor opción** ya que proporciona una URL HTTPS pública temporal.
- Si reinicias ngrok, la URL cambiará y necesitarás actualizar el webhook en GitHub.

## 🔐 Seguridad

### Verificación SSL

La verificación SSL es importante para prevenir ataques man-in-the-middle:

- **✅ HABILITAR SSL verification** cuando:
  - Usas HTTPS con certificado válido (producción)
  - Usas ngrok con HTTPS (desarrollo)
  - Quieres máxima seguridad

- **❌ DESHABILITAR SSL verification** solo cuando:
  - Desarrollo local con HTTP (sin HTTPS)
  - Certificados autofirmados (no recomendado en producción)
  - **Nunca en producción con tráfico real**

### Mejores Prácticas de Seguridad

Si Jenkins está expuesto a Internet, considera:

1. **Usar HTTPS** (configura un proxy reverso con nginx o similar)
2. **Habilitar verificación SSL** en el webhook
3. **Configurar autenticación** en Jenkins
4. **Usar un secreto** para el webhook (altamente recomendado)
5. **Restringir el acceso por IP** en GitHub (si tienes una IP fija)
6. **Usar firewall** para limitar acceso al puerto 8081
