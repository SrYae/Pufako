# send2ereader en el servidor de casa

Instancia propia de [send2ereader](https://github.com/daniel-j/send2ereader) (el código detrás de send.djazz.se) para enviar EPUB desde el móvil al Kobo a través de la Wi‑Fi de casa.

Fijado al commit `eb0b646` del repositorio oficial, el último de `master` (20‑oct‑2024).

Usa un `Dockerfile` propio en lugar del oficial: el oficial falla al construir porque instala pdfCropMargins sobre `node:lts-alpine` sin versión fija y PyMuPDF no compila. Esta imagen incluye solo lo necesario para Kobo (Node 20 + kepubify 4.0.4). La conversión a MOBI para Kindle y el recorte de márgenes de PDF no están incluidos; los EPUB, PDF y demás formatos se envían igual.

## Requisitos

- Un servidor en casa con Docker y Docker Compose v2 (`docker compose`, no `docker-compose`).
- El servidor, el móvil y el Kobo conectados a la **misma red**.
- Una IP fija para el servidor (resérvala por DHCP en el router). En los ejemplos uso `192.168.1.50`; pon la tuya.

## Instalación

```bash
git clone https://github.com/SrYae/Pufako.git
cd Pufako/send2ereader
docker compose up -d --build
```

En Windows: abre antes Docker Desktop y espera a que indique *Engine running*. Para que el Kobo y el móvil lleguen al PC, abre el puerto en el firewall (PowerShell como administrador):

```powershell
New-NetFirewallRule -DisplayName "send2ereader" -Direction Inbound -Protocol TCP -LocalPort 3001 -Action Allow -Profile Private
```

Para comprobar que funciona:

```bash
docker compose logs -f        # debe salir "server is listening on port 3001"
curl -I http://localhost:3001 # debe responder 200
```

Si el puerto 3001 ya está ocupado, arranca el servicio en otro puerto: `S2E_PORT=8080 docker compose up -d`.

## Uso: del móvil al Kobo

1. **Kobo:** abre el navegador (en el firmware actual está en *Más → Funciones beta → Navegador web*) y entra en `http://192.168.1.50:3001`. Aparece una **clave de 4 caracteres**.
2. **Móvil:** abre `http://192.168.1.50:3001` en el navegador. El servicio detecta que no es un e‑reader y te muestra el formulario de subida.
3. Escribe la clave, elige el `.epub` y deja marcada la casilla **Kepubify** (convierte a KEPUB: el formato nativo de Kobo, con estadísticas de lectura y mejor paginación).
4. Pulsa enviar. En el Kobo aparece el enlace de descarga: púlsalo y el libro entra en la biblioteca.

Consejo: guarda `http://192.168.1.50:3001` en los marcadores del Kobo y en la pantalla de inicio del móvil.

### Comportamiento que tienes que conocer

- **La clave caduca** si la página del Kobo deja de consultar el servidor durante 30 s, y como máximo a la hora. Deja la página abierta en el Kobo mientras subes desde el móvil.
- Formatos aceptados: EPUB, MOBI, PDF, CBZ, CBR, TXT y HTML. Límite: 800 MB por archivo.
- Los archivos subidos no se conservan: el servidor los borra cuando caduca la clave y vacía la carpeta de subidas cada vez que arranca.

## Seguridad

El servicio **no tiene autenticación**: úsalo solo en la red local. No abras el puerto en el router. Si algún día quieres enviar libros desde fuera de casa, conecta el móvil a la red de casa por VPN (WireGuard, Tailscale) en vez de exponer el servicio a Internet.

## Mantenimiento

```bash
docker compose restart        # reiniciar
docker compose down           # parar
```

Para actualizar a una versión nueva del código, cambia el hash del commit en el `Dockerfile` y vuelve a ejecutar `docker compose up -d --build`.
