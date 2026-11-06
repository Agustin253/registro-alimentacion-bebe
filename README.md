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
- **Compartir con la familia** (opcional): con una cuenta, varias personas comparten el mismo registro y ven los cambios al instante, incluida la toma en curso.
- Funciona **sin conexión**: lo que cargues se guarda en el teléfono y se sube solo cuando vuelve la señal.
- **Copia de seguridad** (.json) y exportación a Excel (.csv).

## Compartir con otra persona

1. Los dos instalan la app (ver abajo).
2. Uno entra a **Ajustes → Compartir con tu familia**, crea su cuenta y toca **Crear** (con el nombre del bebé). Si ya tenía tomas cargadas en el teléfono, se suben al grupo.
3. Toca **Invitar** y le manda el código a la otra persona.
4. La otra persona crea su cuenta, escribe el código y toca **Unirme**.

Desde ese momento los dos ven y cargan las mismas tomas.

## Privacidad

- **Sin cuenta:** los datos se guardan solo en tu teléfono. No se envían a ningún lado.
- **Con cuenta:** las tomas se guardan en una base de datos (Supabase) y **solo las pueden ver los integrantes de tu grupo familiar**. Cada consulta pasa por reglas de seguridad en la base (Row Level Security): nadie más puede leerlas ni modificarlas.
- Si el último integrante sale del grupo, el grupo y sus tomas se borran del servidor.

⚠️ Sin cuenta, si borrás los datos del navegador o desinstalás la app, se pierden los registros. Hacé una copia de seguridad cada tanto desde **Ajustes**.

## Cómo instalarla en el celular

- **iPhone (Safari):** abrí el link → botón *Compartir* → **Agregar a inicio**.
- **Android (Chrome):** abrí el link → menú ⋮ → **Instalar app** / **Agregar a pantalla principal**.

En iPhone conviene instalarla: así Safari no borra los datos de sitios que no se usan por varios días.

## Limitaciones conocidas

- **No suena una alarma** a la hora de la próxima toma. Para eso haría falta un servidor de notificaciones.
- Si dos personas editan **la misma toma** a la vez sin conexión, queda la última que se sube.

## Desarrollo

Sitio estático, sin build:

| Archivo | Para qué |
|---|---|
| `index.html` | Toda la app (HTML + CSS + JS) |
| `config.js` | URL y clave pública de Supabase. Vacíos = modo solo local |
| `vendor/supabase.js` | Cliente oficial `@supabase/supabase-js` (UMD), incluido para que funcione sin conexión |
| `supabase/schema.sql` | Tablas, funciones y reglas de seguridad |
| `sw.js` | Service worker para uso offline |
| `manifest.webmanifest`, `icons/` | Instalación como app |

Para probarla localmente:

```bash
python3 -m http.server 8000
# abrir http://localhost:8000
```

Cuando cambies algún archivo, subí la versión de `CACHE` en `sw.js` (por ejemplo `alimentacion-v2` → `alimentacion-v3`).

### Configurar la sincronización (Supabase)

1. Creá un proyecto gratis en [supabase.com](https://supabase.com) (región sugerida para Argentina: *South America (São Paulo)*).
2. **SQL Editor → New query**: pegá el contenido de `supabase/schema.sql` y tocá **Run**.
3. **Authentication → URL Configuration**: en *Site URL* y en *Redirect URLs* poné la dirección de la app (por ejemplo `https://agustin253.github.io/registro-alimentacion-bebe/`). Es a donde llevan los mails de confirmación y de “olvidé mi contraseña”.
4. **Project Settings → API**: copiá la *Project URL* y la clave *anon / publishable* a `config.js`. Esa clave es pública por diseño; la seguridad la dan las reglas del paso 2. **Nunca** pongas la clave *service_role / secret*.

Notas del plan gratis:
- El envío de mails de Supabase está limitado a unos pocos por hora. Alcanza para una familia; si la app la usa mucha gente, configurá un SMTP propio en *Authentication → Emails*.
- Un proyecto gratis se **pausa tras una semana sin uso**. Con uso diario no pasa; si pasa, se reactiva desde el panel y la app sigue funcionando sin conexión mientras tanto.

### Publicar en GitHub Pages

*Settings → Pages → Build and deployment*: Source **Deploy from a branch**, Branch **main** / **(root)**.

## Aviso

Esta app es solo una herramienta de registro. No reemplaza las indicaciones del pediatra sobre cantidades ni frecuencia de alimentación.

## Licencia

MIT. Incluye `@supabase/supabase-js` (MIT).
