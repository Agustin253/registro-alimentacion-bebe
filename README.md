# 🍼 Registro Alimentación Bebé

App web gratuita y de código abierto para registrar las tomas de alimentación de un bebé desde el celular.

**[➡️ Abrir la app](https://agustin253.github.io/registro-alimentacion-bebe/)**

## Qué hace

- **Botón Empezar / Terminar toma** con cronómetro (sigue corriendo aunque cierres la app).
- Registra **hora de inicio, hora de fin, tipo** (relactador, mamadera, jeringa), **ml de fórmula** y una nota opcional.
- Calcula **cuándo es la próxima toma** (hora de inicio de la última + intervalo configurable, por ejemplo cada 3 h) y avisa visualmente si está atrasada.
- Totales de **hoy** y de las **últimas 24 h** (cantidad de tomas y ml).
- **Estadísticas** por día, semana, mes, últimos N días o rango personalizado: totales, promedios, duración e intervalo promedio, reparto por tipo y gráfico diario.
- Carga manual, edición y borrado de tomas.
- **Copia de seguridad** (.json) y exportación a Excel (.csv). La copia también sirve para pasar los datos a otro teléfono.
- Funciona **sin conexión** y se instala como app.

## Privacidad

Los datos se guardan **solo en el teléfono de cada persona** (almacenamiento local del navegador). No hay servidor, cuentas ni seguimiento.

⚠️ Si borrás los datos del navegador o desinstalás la app, se pierden los registros. Hacé una copia de seguridad cada tanto desde **Ajustes**.

## Cómo instalarla en el celular

- **iPhone (Safari):** abrí el link → botón *Compartir* → **Agregar a inicio**.
- **Android (Chrome):** abrí el link → menú ⋮ → **Instalar app** / **Agregar a pantalla principal**.

En iPhone conviene instalarla: así Safari no borra los datos de sitios que no se usan por varios días.

## Limitaciones conocidas

- **No suena una alarma** a la hora de la próxima toma. Las apps web no pueden programar notificaciones sin un servidor.
- **No sincroniza entre dispositivos**: cada teléfono tiene sus propios datos. Para pasarlos, usá la copia de seguridad.

## Desarrollo

Es un sitio estático: `index.html` (HTML + CSS + JS sin dependencias), `manifest.webmanifest`, `sw.js` (service worker para uso offline) e `icons/`.

Para probarla localmente:

```bash
python3 -m http.server 8000
# abrir http://localhost:8000
```

Cuando cambies algún archivo, subí la versión de `CACHE` en `sw.js` (`alimentacion-v1` → `alimentacion-v2`) para que los usuarios reciban la actualización.

### Publicar en GitHub Pages

1. Subí estos archivos a la raíz de un repositorio.
2. *Settings → Pages → Build and deployment*: Source **Deploy from a branch**, Branch **main** / **(root)**.
3. En un par de minutos queda en `https://TU-USUARIO.github.io/NOMBRE-DEL-REPO/`.

## Aviso

Esta app es solo una herramienta de registro. No reemplaza las indicaciones del pediatra sobre cantidades ni frecuencia de alimentación.

## Licencia

MIT
