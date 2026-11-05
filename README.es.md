<p align="center">
  <img src="docs/icon.png" alt="Ícono de DocMonitor" width="128">
</p>

<h1 align="center">DocMonitor</h1>

<p align="center">
  Una app nativa de macOS para la barra de menús que gestiona las imágenes, los contenedores y los proyectos de Compose de Docker.
</p>

<p align="center"><a href="README.md">English</a> · Español</p>

<p align="center"><img src="docs/screenshot.png" alt="Captura de pantalla de DocMonitor" width="480"></p>

## Características

- **Contenedores:** listar, iniciar, detener y eliminar.
- **Consola:** abre una terminal dentro de un contenedor desde la barra de menús.
- **Imágenes:** listar, descargar (pull), eliminar y construir desde un Dockerfile.
- **Creación de contenedores:** crea un contenedor directamente desde una imagen.
- **Docker Compose:** `up` y `down` de proyectos, añadirlos manualmente y conservarlos entre sesiones (opcional).
- **Preferencias:** intervalo de actualización, abrir al iniciar sesión, rutas del socket y del CLI de Docker, shell de la consola, política de reinicio por defecto, visibilidad de imágenes sin etiqueta y de contenedores detenidos, y búsqueda de actualizaciones.
- **Nativa:** desarrollada con Swift y SwiftUI, con el diseño Liquid Glass de macOS 26. Se comunica con Docker directamente a través de su socket Unix, así que no hay Electron ni un runtime adicional.

## Requisitos

- macOS 26 (Tahoe) o posterior.
- Un motor de Docker en ejecución. Docker Desktop, OrbStack, Colima y Rancher Desktop se detectan automáticamente; para cualquier otro caso, indica la ruta del socket en **Preferences → Docker**.

## Instalación

DocMonitor es de código disponible (*source-available*) y se distribuye **sin notarización de Apple** (consulta [¿Por qué no está notarizada?](#por-qué-no-está-notarizada)). Esto significa que macOS te mostrará una advertencia la primera vez que la abras. Es lo esperado y solo hay que hacerlo una vez.

1. Descarga `DocMonitor-x.y.z.zip` desde el [último release](https://github.com/cessadev/docmonitor/releases/latest).
2. *(Opcional)* Verifica la descarga con el SHA-256 publicado en las notas del release:
   ```bash
   shasum -a 256 DocMonitor-x.y.z.zip
   ```
3. Descomprímelo y mueve `DocMonitor.app` a tu carpeta `Aplicaciones`.
4. Ábrela. macOS dirá que no pudo verificar la app. Pulsa **Listo** (no "Mover al basurero").
5. Abre **Ajustes del Sistema → Privacidad y seguridad**, baja hasta la sección **Seguridad** y pulsa **Abrir de todos modos** junto al mensaje de DocMonitor. Elige otra vez **Abrir de todos modos** si macOS lo vuelve a pedir. Por último, confirma con tu contraseña o Touch ID y pulsa **Abrir**.

Si prefieres la terminal, puedes quitar el indicador de cuarentena que macOS añade a los archivos descargados:

```bash
xattr -dr com.apple.quarantine /Applications/DocMonitor.app
```

> En macOS 15 y posteriores, el antiguo atajo de clic derecho → Abrir ya no evita esta advertencia, así que usa uno de los dos métodos anteriores.

### Permisos

La primera vez que abras una consola en un contenedor, macOS preguntará si DocMonitor puede controlar Terminal. Pulsa **OK**. Si lo denegaste por error, vuelve a activarlo en **Ajustes del Sistema → Privacidad y seguridad → Automatización**.

Como la app tiene una firma ad-hoc (ver más abajo), macOS trata cada versión nueva como una app distinta y puede volver a pedir este permiso después de una actualización. Para restablecerlo manualmente:

```bash
tccutil reset AppleEvents com.cessadev.DocMonitor
```

## Compilar desde el código fuente

Necesitas Xcode 26 o posterior.

```bash
git clone https://github.com/cessadev/docmonitor.git
cd docmonitor
open DocMonitor.xcodeproj
```

Luego pulsa **Run** (⌘R).

Para generar una compilación Release desde la línea de comandos:

```bash
xcodebuild -project DocMonitor.xcodeproj -scheme DocMonitor \
  -configuration Release -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

La app se crea en `build/Build/Products/Release/DocMonitor.app`. Compilar desde el código fuente en tu propio Mac también evita la advertencia de Gatekeeper, ya que las apps compiladas localmente no se ponen en cuarentena.

## ¿Por qué no está notarizada?

La notarización requiere una membresía de pago del Apple Developer Program. DocMonitor es un proyecto gratuito y de código disponible, por lo que los releases se firman con una firma *ad-hoc*. Esa firma no identifica a un desarrollador, pero sí garantiza que el código no ha sido modificado desde que se compiló. Si prefieres no confiar en un binario ya compilado, compílalo tú mismo desde el código fuente como se indica arriba.

## Contribuciones

Los reportes de errores, las sugerencias y los comentarios son bienvenidos como issues. Por la licencia, las contribuciones de código requieren un acuerdo previo: consulta [CONTRIBUTING.es.md](CONTRIBUTING.es.md) para saber cómo ayudar y qué no está permitido.

## Licencia

DocMonitor está licenciado bajo la [PolyForm Strict License 1.0.0](LICENSE). Puedes usarlo con fines no comerciales. Distribuirlo, modificarlo o usarlo comercialmente requiere el permiso del autor.
