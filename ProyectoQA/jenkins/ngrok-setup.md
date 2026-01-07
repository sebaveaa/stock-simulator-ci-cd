# 🚀 Configuración Rápida de ngrok para Jenkins

Guía paso a paso para configurar ngrok en Windows (la opción más simple si no puedes usar tu IP directamente).

## ⚡ Instalación Rápida (2 minutos)

### Paso 1: Descargar ngrok

1. Ve a: https://ngrok.com/download
2. Descarga la versión para Windows
3. Extrae `ngrok.exe` a una carpeta (ej: `C:\ngrok\`)

### Paso 2: Ejecutar ngrok

**Opción A: Desde la carpeta de ngrok**

```powershell
cd C:\ngrok
.\ngrok http 8081
```

**Opción B: Agregar ngrok al PATH (recomendado)**

1. Agrega `C:\ngrok` a tu PATH de Windows
2. Luego puedes ejecutar desde cualquier lugar:
   ```powershell
   ngrok http 8081
   ```

### Paso 3: Copiar la URL

ngrok mostrará algo como:

```
ngrok                                                                              
                                                                                   
Session Status                online                                                
Account                       Tu Email (Plan: Free)                                
Version                       3.x.x                                                 
Region                        United States (us)                                    
Latency                       45ms                                                  
Web Interface                 http://127.0.0.1:4040                                
Forwarding                    https://abc123-def456.ngrok-free.app -> http://localhost:8081
                                                                                    
Connections                   ttl     opn     rt1     rt5     p50     p90            
                              0       0       0.00    0.00    0.00    0.00          
```

**Copia la URL HTTPS** de la línea "Forwarding":
```
https://abc123-def456.ngrok-free.app
```

### Paso 4: Usar en GitHub

1. Ve a tu repositorio en GitHub
2. **Settings > Webhooks > Add webhook**
3. **Payload URL**: `https://abc123-def456.ngrok-free.app/github-webhook/`
4. **SSL verification**: ✅ **Habilitar** (ngrok usa certificados válidos)
5. Guarda el webhook

## ✅ Verificar que Funciona

1. Mantén ngrok corriendo (no cierres la ventana)
2. Haz un push a tu repositorio
3. El webhook debería funcionar automáticamente

## 🔄 Mantener ngrok Corriendo

**Problema**: Si cierras ngrok, la URL cambia y el webhook deja de funcionar.

**Soluciones:**

### Opción 1: Ejecutar ngrok en segundo plano

```powershell
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd C:\ngrok; .\ngrok http 8081"
```

### Opción 2: Usar ngrok como servicio de Windows

Puedes configurar ngrok para que se inicie automáticamente con Windows.

### Opción 3: URL fija con cuenta de pago

Si necesitas una URL que no cambie, considera la cuenta de pago de ngrok ($8/mes) que permite URLs personalizadas.

## 🆘 Problemas Comunes

**ngrok no se ejecuta:**
- Verifica que Jenkins esté corriendo en el puerto 8081
- Verifica que no haya otro proceso usando el puerto 8081

**La URL cambia cada vez:**
- Esto es normal en la versión gratuita
- Actualiza el webhook en GitHub con la nueva URL
- O considera la cuenta de pago para URL fija

**ngrok muestra error de autenticación:**
- Crea una cuenta gratuita en https://ngrok.com/
- Obtén tu token de autenticación
- Ejecuta: `ngrok config add-authtoken TU_TOKEN`

## 💡 Tips

- Mantén la ventana de ngrok abierta mientras trabajas
- Puedes ver las peticiones en tiempo real en: http://127.0.0.1:4040
- La versión gratuita es suficiente para desarrollo
- Si necesitas producción, considera un servidor con dominio propio

