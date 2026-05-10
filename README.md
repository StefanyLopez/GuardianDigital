# Guardian Digital Kids 🌟

> Aplicación móvil de acompañamiento digital empático para niños y adolescentes.  
> Flutter · Groq (Llama 3.1) · Supabase · SQLite

---

## ¿Qué es este proyecto?

Guardian Digital Kids es un prototipo MVP de una app móvil que acompaña a niños (8–12) y adolescentes (13–17) a construir hábitos digitales más saludables. El núcleo es **Luma**, un asistente de IA con personalidad propia que conversa con el usuario, propone micro-retos y envía intervenciones suaves cuando detecta uso excesivo.

**Stack:**

| Qué | Tecnología |
|-----|-----------|
| App móvil | Flutter 3.x (Dart) — iOS y Android |
| IA del NPC | Groq API con Llama 3.1-8b-instant (gratis) |
| Base de datos remota | Supabase (PostgreSQL) — auth + perfiles + logros |
| Base de datos local | SQLite (sqflite) — historial de chat privado |
| Estado | Riverpod |
| Navegación | GoRouter |
| Notificaciones | flutter_local_notifications |

---

## Requisitos previos

Antes de instalar nada, verifica que tu PC cumple con esto:

- Windows 10/11 de 64 bits (el proyecto fue desarrollado en Windows 11 Pro)
- Al menos 10 GB de espacio libre en disco
- Conexión a internet estable
- Un celular Android con cable USB de datos (no solo de carga)

---

## Parte 1 — Instalar Flutter

### 1.1 Descargar el SDK

1. Ve a [https://docs.flutter.dev/get-started/install/windows/mobile](https://docs.flutter.dev/get-started/install/windows/mobile)
2. Haz clic en **"Download Flutter SDK"** y descarga el archivo `.zip`
3. **Importante:** extrae el ZIP en `C:\Users\TU_USUARIO\dev\flutter`
   - La ruta final debe quedar así: `C:\Users\TU_USUARIO\dev\flutter\bin\flutter.bat`
   - ❌ **Nunca** lo pongas en `C:\Program Files\` ni en el escritorio
   - ❌ **Nunca** uses rutas con espacios o caracteres especiales

### 1.2 Agregar Flutter al PATH

1. Presiona `Windows + S` y busca **"Variables de entorno"**
2. Haz clic en **"Editar las variables de entorno del sistema"**
3. En la ventana que abre, clic en **"Variables de entorno..."**
4. En la sección **"Variables del sistema"**, busca la variable `Path` y haz doble clic
5. Clic en **"Nuevo"** y escribe: `C:\Users\TU_USUARIO\dev\flutter\bin`
6. Acepta todo con **OK** en todas las ventanas
7. **Cierra y vuelve a abrir** cualquier terminal que tengas abierta

### 1.3 Verificar la instalación

Abre una terminal nueva (PowerShell o CMD) y ejecuta:

```bash
flutter doctor
```

Deberías ver algo así. Los únicos `✓` que necesitas para este proyecto son los dos primeros:

```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Windows Version (Windows 11)
[✗] Android toolchain  ← no importa si no tienes emulador
[✗] Chrome            ← no lo necesitamos
[!] Visual Studio     ← no lo necesitamos
[✓] Connected device  ← esto importa cuando conectes el celular
[✓] Network resources
```

> **Nota:** en este proyecto no se usó Android Studio ni emuladores. Todo se prueba conectando el celular Android físico por USB. Android Studio lo puedes ignorar completamente.

---

## Parte 2 — Instalar VS Code

### 2.1 Descargar e instalar

1. Ve a [https://code.visualstudio.com](https://code.visualstudio.com)
2. Descarga e instala la versión para Windows
3. Abre VS Code

### 2.2 Instalar la extensión de Flutter

1. Presiona `Ctrl + Shift + X` para abrir el panel de extensiones
2. Busca **"Flutter"** (la oficial de Dart Code)
3. Haz clic en **Instalar** — esto instala Flutter y Dart automáticamente

---

## Parte 3 — Conectar el celular Android

Este proyecto se desarrolló y probó exclusivamente con un celular físico conectado por USB. No necesitas emuladores.

### 3.1 Activar modo desarrollador

1. En tu celular Android ve a **Ajustes**
2. Busca **"Acerca del teléfono"** (o "Información del teléfono")
3. Toca **"Número de compilación"** exactamente **7 veces seguidas**
4. Ingresa tu PIN o patrón si te lo pide
5. Aparece el mensaje **"¡Ya eres desarrollador!"**

### 3.2 Activar depuración USB

1. Vuelve a **Ajustes**
2. Ahora aparece **"Opciones de desarrollador"** (a veces dentro de "Sistema")
3. Activa **"Depuración USB"**
4. Confirma en el popup

### 3.3 Conectar el cable

1. Usa un cable USB que sea **de datos** (no todos los cables cargan y transfieren datos)
2. Conecta el celular al PC
3. En el celular aparece un popup: **"¿Permitir depuración USB desde este equipo?"**
4. Toca **"Permitir siempre"** y luego **"Aceptar"**

### 3.4 Verificar que Flutter detecta el celular

```bash
flutter devices
```

Deberías ver tu celular en la lista:

```
SM A366E (mobile) • RFCY81P9S9X • android-arm64 • Android 14
```

---

## Parte 4 — Obtener el código

Tienes dos opciones para clonar el repositorio. Elige la que prefieras.

### Opción A — Con GitHub Desktop (más fácil)

1. Descarga GitHub Desktop desde [https://desktop.github.com](https://desktop.github.com)
2. Instala y abre sesión con tu cuenta de GitHub
3. En la pantalla principal haz clic en **"Clone a repository"**
4. Pega la URL del repositorio: `https://github.com/TU_USUARIO/guardian_digital`
5. En **"Local path"** elige dónde guardar el proyecto, por ejemplo `C:\Users\TU_USUARIO\Desktop\GuardianDigital`
6. Clic en **"Clone"**
7. Cuando termine, clic en **"Open in Visual Studio Code"**

### Opción B — Con Git en la terminal

Si tienes Git instalado ([https://git-scm.com](https://git-scm.com)):

```bash
# Navega a donde quieres guardar el proyecto
cd C:\Users\TU_USUARIO\Desktop

# Clona el repositorio
git clone https://github.com/TU_USUARIO/guardian_digital.git

# Entra a la carpeta
cd guardian_digital

# Abre en VS Code
code .
```

---

## Parte 5 — Configurar las variables de entorno

Este paso es **obligatorio** antes de correr la app. El archivo `.env` contiene las keys de conexión y **no está en el repositorio** por seguridad.

### 5.1 Crear tu archivo .env

En la raíz del proyecto (la misma carpeta donde está `pubspec.yaml`) crea un archivo llamado exactamente `.env` (sin extensión, con el punto al inicio).

En Windows Explorer puede que no te deje crear archivos que empiecen con punto. En ese caso créalo desde VS Code: `Archivo → Nuevo archivo → escribe .env`.

### 5.2 Llenar las variables

Copia este contenido en tu `.env` y llena los valores:

```env
# Supabase — pídele a Stef el SUPABASE_URL y el SUPABASE_ANON_KEY
# Son los mismos para todo el equipo porque es el mismo proyecto
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...

# Groq — cada uno crea la suya gratis en https://console.groq.com/keys
# Es tu key personal, no la compartas
GROQ_API_KEY=gsk_...

# Modo de la app
APP_MODE=demo
```

### ¿De dónde saco cada key?

**`SUPABASE_URL` y `SUPABASE_ANON_KEY`:**
- Estos dos valores son los mismos para todo el equipo porque todos conectan a la misma base de datos del proyecto
- **Pídele a Stef** que te los comparta (no los subas a GitHub)
- Los puedes encontrar en: Supabase → tu proyecto → Settings → API

**`GROQ_API_KEY`:**
- Cada miembro del equipo crea la suya **gratis** en [https://console.groq.com/keys](https://console.groq.com/keys)
- Clic en **"Create API Key"**, ponle un nombre, copia la key y pégala en tu `.env`
- La capa gratuita de Groq permite 500.000 tokens/día, más que suficiente para desarrollo

---

## Parte 6 — Instalar dependencias y correr la app

Abre la terminal integrada de VS Code con `Ctrl + ñ` (o `Ctrl + backtick`) y corre estos comandos en orden:

### 6.1 Instalar dependencias de Flutter

```bash
flutter pub get
```

Espera a que termine. Descarga todos los paquetes del `pubspec.yaml`.

### 6.2 Verificar que el celular está conectado

```bash
flutter devices
```

Copia el ID de tu celular (la cadena como `RFCY81P9S9X`).

### 6.3 Correr la app

```bash
# Opción 1: Flutter elige el dispositivo automáticamente
flutter run

# Opción 2: Especificar el celular por ID (recomendado si tienes varios)
flutter run -d TU_ID_DE_DISPOSITIVO
```

La primera vez tarda entre 3 y 8 minutos porque compila todo. Las siguientes veces es mucho más rápido.

Cuando esté lista verás esto en la terminal:

```
Flutter run key commands.
r  Hot reload  🔥
R  Hot restart
q  Quit
```

### 6.4 Hot reload mientras desarrollas

Una vez que la app está corriendo, cada vez que guardas un archivo (`Ctrl + S`) puedes presionar `r` en la terminal para ver los cambios al instante sin recompilar. Si el cambio es estructural (nuevo provider, nuevo widget raíz), usa `R` para hot restart.

---

## Estructura del proyecto

```
guardian_digital/
├── .env                          ← tus keys (NO subir a GitHub)
├── .env.example                  ← plantilla del .env
├── pubspec.yaml                  ← dependencias
├── supabase_setup.sql            ← script para crear las tablas
├── assets/
│   ├── images/                   ← avatares e imágenes (ya creada)
│   ├── animations/               ← archivos Lottie (ya creada)
│   └── fonts/                    ← tipografías custom (ya creada)
└── lib/
    ├── main.dart                 ← entrada de la app
    ├── core/
    │   ├── theme/app_theme.dart  ← colores, tipografía, tema
    │   ├── router/app_router.dart← todas las rutas
    │   ├── notifications/        ← notificaciones push locales
    │   ├── database/             ← SQLite local (chat privado)
    │   ├── widgets/              ← banner de intervención
    │   ├── shell/main_shell.dart ← bottom navigation
    │   └── constants/            ← constantes y prompts de Luma
    │   └── luma/                 ← avatar dinámico
    └── features/
        ├── auth/                 ← login y registro
        ├── onboarding/           ← 5 pasos de configuración inicial
        ├── kid/                  ← home, chat con Luma, logros, stats
        │   ├── models/           ← ProfileModel, ChatMessage
        │   ├── providers/        ← estado con Riverpod
        │   ├── services/         ← groq_service.dart (llama a la API)
        │   └── presentation/     ← pantallas del menor
        ├── guardian/             ← panel del cuidador
        └── demo/                 ← panel de demo para presentaciones
```

---

## Flujo completo de la app

```
Login / Registro
      ↓
Onboarding (5 pasos)
  1. Bienvenida con Luma
  2. ¿Eres cuidador o el menor?
  3. Nombre del menor
  4. Edad (8-12 / 13-17) y avatar
  5. Metas iniciales (hasta 3)
      ↓
Panel del cuidador (/guardian)
  → Ver perfiles creados
  → Stats de sincronización
  → Botón "Ver app de [nombre]"
      ↓
Home del menor (/kid/:profileId)
  → Saludo contextual
  → Tarjeta de Luma (abre el chat)
  → Racha de días
  → Nivel de autonomía
      ↓
Chat con Luma (/kid/:profileId/chat)
  → Conversación con IA real (Groq/Llama 3.1)
  → Luma recuerda nombre, metas y nivel
  → Propone micro-retos
      ↓
Logros (/kid/:profileId/achievements)
  → Insignias desbloqueadas
  → Retos activos
      ↓
Mi semana (/kid/:profileId/stats)
  → Gráfico de bienestar
  → Resumen de hábitos
```
---
---

## Sistema de tema 🎨

Modo claro/oscuro con persistencia. Archivos en `lib/core/theme/`:

- `app_theme.dart` — constantes (`GDSpacing`, `GDRadius`, `GDTypography`) + `buildGDTheme()` / `buildGDDarkTheme()`
- `theme_extension.dart` — extensión `context.gd` para colores adaptativos
- `theme_provider.dart` — `themeModeProvider` (Riverpod + SharedPreferences)

**Uso en widgets — siempre `context.gd`, nunca valores hardcodeados:**

```dart
color: context.gd.primary       // ✅ se adapta al tema
color: const Color(0xFF6C63FF)  // ❌ no cambia con el tema
```

**Toggle desde cualquier widget:**

```dart
ref.read(themeModeProvider.notifier).toggle();
// o
ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
```

> ⚠️ `context.gd` es runtime — nunca lo uses dentro de un `const`.

---

## Avatar Luma 🌟

Personaje central dibujado en canvas (sin imágenes). Archivos en `lib/features/kid/presentation/widgets/luma/`:

- `luma_state.dart` — enums, `LumaData`, `calculateLumaData()`, catálogo de cosméticos
- `luma_colors.dart` — paleta cromática del personaje
- `luma_painter.dart` — `CustomPainter` que dibuja blob, expresiones y accesorios
- `luma_avatar.dart` — widget con 4 animaciones (respiración, flotación, parpadeo, partículas)

**Estados** (calculados automáticamente desde el perfil): `sleeping` → `tired` → `glowing` → `excited` → `happy` → `normal`

**Evoluciones:** `sprout` (nivel 1–2) · `growing` (nivel 3 o racha 3+) · `guardian` (nivel 4+, tiene halo)

**Cosméticos desbloqueables con puntos:** 5 colores de cuerpo · 6 accesorios · 5 tipos de ojos

---

## Panel de demo 🧪

Para la presentación del prototipo, hay un panel de demo que simula triggers sin necesidad de esperar tiempo real. Accede desde el panel del cuidador → botón **"Panel de demo"**.

| Control | Qué simula |
|---------|-----------|
| Slider tiempo en pantalla | Usuario lleva X minutos usando el celular |
| Botón "Mostrar banner" | Banner suave dentro de la app |
| Botón "Enviar push" | Notificación del sistema con mensaje de Luma |
| Botón "Uso nocturno" | Programa push de seguimiento para mañana |
| Botón "Inactividad 48h" | Push de reencuentro de Luma |
| Botón "Avanzar 1 día" | Incrementa la racha del perfil |
| Botón "Limpiar chat" | Borra el historial para empezar demo limpia |

---

## Cómo funciona Groq en el proyecto

No hay servidor propio ni Python. Flutter llama directo a la API REST de Groq:

```
Tu celular
    ↓ POST https://api.groq.com/openai/v1/chat/completions
    ↓ modelo: llama-3.1-8b-instant
    ↓ system prompt con personalidad de Luma + contexto del perfil
Groq devuelve respuesta
    ↓
Se guarda en SQLite local (privado, nunca sale del dispositivo)
    ↓
Aparece en el chat
```

El historial de conversación se almacena en SQLite en el dispositivo y **nunca se sube a ningún servidor**. El cuidador no puede verlo.

---

## Límites gratuitos de Groq

| Límite | Valor |
|--------|-------|
| Requests por minuto | 30 |
| Tokens por minuto | 6.000 |
| Tokens por día | 500.000 |

Para desarrollo es más que suficiente. Con respuestas de máx 300 tokens, el límite diario alcanza para ~1.600 mensajes.

---

## Comandos útiles

```bash
# Ver dispositivos conectados
flutter devices

# Correr en modo debug (con hot reload)
flutter run

# Correr en release (más rápido, sin debug)
flutter run --release

# Hot reload mientras la app corre (presionar en la terminal)
r

# Hot restart (cuando hot reload no es suficiente)
R

# Limpiar build cache si hay errores raros
flutter clean
flutter pub get

# Generar APK para compartir (queda en build/app/outputs/flutter-apk/)
flutter build apk --release
```

---

## Solución de problemas frecuentes

**El celular no aparece en `flutter devices`**
- Verifica que el cable sea de datos (prueba cargando y transfiriendo un archivo)
- Revisa que "Depuración USB" esté activada
- Acepta el popup de depuración en el celular
- Intenta con `flutter doctor` para ver si hay algún problema

**Error "unable to find directory entry: assets/images/"**
- Las carpetas ya están creadas en el repo, pero si no aparecen:
```bash
mkdir assets\images assets\animations assets\fonts
```

**Error de Groq "algo salió mal"**
- Verifica que `GROQ_API_KEY` en tu `.env` empieza con `gsk_`
- El modelo correcto es `llama-3.1-8b-instant` (no `llama3-8b-8192`)
- Verifica en [console.groq.com](https://console.groq.com) que tu key esté activa

**Error "Error al conectar con la base de datos"**
- Verifica `SUPABASE_URL` y `SUPABASE_ANON_KEY` en tu `.env`
- Confirma que el `supabase_setup.sql` fue ejecutado en el SQL Editor de Supabase
- Revisa en Supabase → Table Editor que existan las tablas `profiles`, `challenges`, etc.

**`flutter pub get` falla**
- Verifica conexión a internet
- Corre `flutter doctor` para ver si Flutter está bien instalado
- Intenta `flutter clean` y luego `flutter pub get` de nuevo

---

## Variables de entorno — resumen para el equipo

| Variable | Quién la tiene | Dónde obtenerla |
|----------|---------------|-----------------|
| `SUPABASE_URL` | Todos usan la misma | Pídela a Stef |
| `SUPABASE_ANON_KEY` | Todos usan la misma | Pídela a Stef |
| `GROQ_API_KEY` | Cada uno crea la suya | [console.groq.com/keys](https://console.groq.com/keys) |
| `APP_MODE` | `demo` para todos | Escribirlo directamente |

> ⚠️ **Nunca subas el archivo `.env` a GitHub.** Ya está en el `.gitignore`. Si accidentalmente lo subes, regenera las keys inmediatamente.

---

## Equipo

Anjhi Bonilla · Daniel Colmenares · Nicolás Hurtado · Stefany López  
Universidad Militar Nueva Granada · Ingeniería Multimedia · 2026
