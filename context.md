# Clappy — Contexto Completo de la App

## Idea de la App

Clappy es una app para macOS que vive en el **notch** (la muesca) del MacBook. Cuando el usuario pasa el cursor sobre el notch, el panel se expande mostrando herramientas útiles sin ocupar espacio en pantalla cuando no se usa.

Las funcionalidades actuales son:
- **Clipboard**: historial de los últimos 20 ítems copiados (texto e imágenes)
- **Media Player**: control de reproducción de música (Apple Music, Spotify, etc.)

La app se mantiene siempre visible por encima de otras ventanas sin robar el foco. No tiene ícono en el Dock — solo un ícono en la barra de menú para acceder a preferencias y salir.

---

## Dependencias Externas

### Homebrew (instalación manual del usuario)
```bash
brew install ungive/tap/media-control
```

**`media-control`** es una CLI open-source ([github.com/ungive/mediaremote-adapter](https://github.com/ungive/mediaremote-adapter)) que actúa como proxy para acceder a `mediaremoted` de macOS. Es necesaria porque en **macOS 15.4+ en MacBook Air M4**, Apple requiere entitlements privados para usar MediaRemote directamente vía `dlopen`/`dlsym` — ninguna app de terceros puede tener esos entitlements.

- **Apple Silicon:** `/opt/homebrew/bin/media-control`
- **Intel:** `/usr/local/bin/media-control`

La app detecta automáticamente cuál existe. Si no está instalada, muestra un mensaje con el comando brew dentro del panel.

#### Comandos usados de `media-control`:
| Uso | Comando |
|---|---|
| Stream de metadatos | `media-control stream --no-diff` |
| Play/Pause | `media-control toggle-play-pause` |
| Siguiente pista | `media-control next-track` |
| Pista anterior | `media-control previous-track` |

#### Formato JSON del stream:
```json
{
  "type": "data",
  "diff": false,
  "payload": {
    "title": "TQM",
    "artist": "Fuerza Regida",
    "album": "TQM - Single",
    "duration": 159.008,
    "elapsedTime": 42.3,
    "playbackRate": 1.0,
    "playing": true,
    "artworkData": "<base64 JPEG>",
    "timestamp": "2026-03-20T05:41:17Z"
  }
}
```

### Swift Package Manager (sin dependencias de terceros en Swift)
El proyecto usa **solo frameworks de Apple** — no hay paquetes Swift de terceros. Todo está en `Package.swift`:
```swift
platforms: [.macOS(.v14)]
linkedFramework("AppKit")
linkedFramework("SwiftUI")
linkedFramework("Combine")
```

---

## Estructura de Archivos

```
notch_app_macbook/
├── Package.swift
├── .gitignore
├── context.md                        ← este archivo
└── Clappy/
    ├── App/
    │   ├── ClappyApp.swift           ← entry point, NSApp accessory mode
    │   └── AppDelegate.swift         ← orquesta todo el setup al lanzar
    ├── Architecture/
    │   └── NotchFacade.swift         ← facade que agrupa los servicios
    ├── Window/
    │   ├── NotchWindowController.swift  ← posiciona y maneja el panel
    │   ├── NotchPanel.swift             ← NSPanel customizado (siempre visible)
    │   └── NotchHoverMonitor.swift      ← detecta hover/click en el notch
    ├── UI/
    │   ├── AnimationConstants.swift     ← constantes de tamaño y animación
    │   ├── NotchContentView.swift       ← vista raíz del panel
    │   ├── NotchContentViewModel.swift  ← isExpanded Bool
    │   └── PanelBackground.swift        ← NSVisualEffectView (blur)
    ├── Settings/
    │   ├── PreferencesView.swift
    │   └── PreferencesViewModel.swift
    └── Features/
        ├── Slots/
        │   ├── Models/SlotConfig.swift
        │   ├── Services/SlotConfiguration.swift
        │   ├── ViewModels/SlotsViewModel.swift
        │   └── Views/SlotContainerView.swift
        ├── Media/
        │   ├── Models/NowPlayingInfo.swift
        │   ├── Services/MediaController.swift
        │   ├── ViewModels/MediaViewModel.swift
        │   └── Views/MediaPlayerView.swift
        └── Clipboard/
            ├── Models/ClipboardItem.swift
            ├── Repository/ClipboardRepositoryProtocol.swift
            ├── Repository/UserDefaultsClipboardRepository.swift
            ├── Services/ClipboardManager.swift
            ├── ViewModels/ClipboardViewModel.swift
            └── Views/ClipboardView.swift
```

---

## Patrones de Diseño

### MVVM (Model–View–ViewModel)
Cada feature sigue la separación estricta:
- **Model**: struct de datos puro (ej. `NowPlayingInfo`, `ClipboardItem`)
- **Service**: lógica de negocio y I/O (ej. `MediaController`, `ClipboardManager`)
- **ViewModel**: `ObservableObject` que conecta Service → View vía `@Published`
- **View**: SwiftUI puro, sin lógica de negocio

Las vistas **nunca** tocan los servicios directamente.

### Facade
`NotchFacade` agrupa todos los servicios. El `AppDelegate` construye el facade y lo pasa a los view models. Los view models no se conocen entre sí.

```
AppDelegate
  └── NotchFacade
        ├── MediaController
        ├── ClipboardManager
        └── SlotConfiguration
```

### Repository Pattern
El clipboard usa una capa de abstracción para persistencia:
- `ClipboardRepositoryProtocol` define la interfaz
- `UserDefaultsClipboardRepository` es la implementación concreta

Esto permite cambiar el backend de persistencia sin tocar el `ClipboardManager`.

### Reactive (Combine)
Toda la comunicación entre capas usa `@Published` + `Combine`:
- `assign(to:)` para pipelines simples
- `sink` para efectos secundarios
- `debounce` donde se necesita evitar spam de eventos

### Dependency Injection
Todas las dependencias se inyectan por constructor. No hay singletons ni acceso global al estado (excepto `AnimationConstants` que son constantes puras).

---

## Cómo Funciona el Panel

### Posicionamiento
`NotchWindowController` usa `NSScreen.auxiliaryTopLeftArea` y `auxiliaryTopRightArea` para calcular la posición exacta del notch en la pantalla. El panel se centra sobre el notch.

Tamaños definidos en `AnimationConstants`:
| Estado | Tamaño |
|---|---|
| Collapsed | 200 × 32 pt |
| Expanded | 420 × 280 pt |

### Detección de Hover
`NotchHoverMonitor` tiene tres modos configurables:
- **hover**: expande al pasar el cursor
- **click**: expande al hacer clic
- **both**: responde a los dos

Lógica de dos rectángulos:
1. **Para expandir (collapsed)**: mouse debe estar en `notchTriggerRect` (±5px H, ±2px V del notch exacto)
2. **Para colapsar (expanded)**: mouse debe salir del `panelFrame` completo (420×280)

Esto evita expansiones accidentales al mover el cursor por la barra de menú.

### Ciclo de Vida del Panel
```
App launch → setupFacade() → setupWindowLayer() → setupHoverMonitor()
                                    ↓
                          NotchWindowController
                                    ↓
                          NotchHoverMonitor (global + local event monitors)
                                    ↓
                          isHovering → NotchContentViewModel.isExpanded
                                    ↓
                          NotchContentView anima expand/collapse
```

---

## Feature: Media Player

### Flujo de datos
```
media-control stream --no-diff (subprocess)
        ↓ stdout JSON lines
MediaController (parsea JSON, actualiza @Published nowPlaying)
        ↓ Combine assign
MediaViewModel (@Published nowPlaying: NowPlayingInfo?)
        ↓ @ObservedObject
MediaPlayerView (3 estados: sin herramienta / sin música / reproduciendo)
```

### Estados de la UI
1. **`media-control` no instalado**: muestra el comando brew + botón "Check Again"
2. **Instalado pero sin música**: el slot desaparece completamente (no hay placeholder)
3. **Reproduciendo**: artwork 80×80, título (marquee si es largo), artista–álbum, barra de progreso, controles prev/play/next

### Progreso en tiempo real (sin Timer)
`NowPlayingInfo.currentElapsed` calcula el tiempo actual usando el timestamp del último evento:
```swift
var currentElapsed: TimeInterval {
    let delta = Date().timeIntervalSince(lastUpdated) * playbackRate
    return min(elapsed + delta, max(duration, 0))
}
```
No hay polling. El progreso se actualiza cada vez que SwiftUI redibuja.

### Reinicio automático del subproceso
Si `media-control` se cae inesperadamente, `MediaController` lo reinicia hasta 3 veces con un delay de 2 segundos entre intentos.

---

## Feature: Clipboard

### Flujo de datos
```
NSPasteboard (polling cada 0.5s)
        ↓
ClipboardManager (detecta cambios, normaliza, persiste)
        ↓ Combine assign
ClipboardViewModel (@Published items: [ClipboardItem])
        ↓ @ObservedObject
ClipboardView (lista scrolleable con indicador fino)
```

### Comportamiento
- Captura texto plano e imágenes (TIFF → JPEG 0.7, máximo 256px)
- Máximo 20 ítems en historial
- El ítem más reciente aparece arriba
- No duplica si el mismo contenido se copia dos veces seguidas
- Persiste en `UserDefaults` (key: `clappy.clipboard.items`)

### UI de cada fila
```
[thumbnail 32×32 si imagen] [texto preview···] [doc.on.doc] [xmark]
```
- Click en la fila → recopia al portapapeles
- Botón `doc.on.doc` → recopia explícitamente
- Botón `xmark` → elimina el ítem
- Indicador de scroll: rectángulo de 2pt en el borde derecho

---

## Persistencia (UserDefaults)

| Clave | Tipo | Contenido |
|---|---|---|
| `clappy.clipboard.items` | `[ClipboardItem]` JSON | Historial del portapapeles |
| `clappy.slots.config` | `[SlotConfig]` JSON | Orden y estado (on/off) de los slots |
| `clappy.trigger.mode` | `String` | Modo hover: "hover" / "click" / "both" |

---

## Preferencias

Accesibles desde el ícono de la barra de menú → "Preferences…"

- **Trigger mode**: hover / click / both
- **Slots**: reordenar con drag-and-drop, activar/desactivar cada slot
- **Clipboard**: botón para limpiar todo el historial

---

## Compatibilidad

- **macOS**: 14.0+ (Sonoma)
- **Arquitectura**: Universal (Apple Silicon nativo + Intel)
- **Notch**: detectado automáticamente. En Macs sin notch, el panel se centra en la parte superior de la pantalla
- **Media detection**: requiere `media-control` instalado vía Homebrew (necesario en macOS 15.4+ con M4)

---

## Estado Actual (Marzo 2026)

### Funciona
- Hover detection con lógica de dos rectángulos (no se expande al pasar por la barra de menú)
- Clipboard: historial, thumbnails de imágenes, botón de copia por ítem, scroll indicator fino
- Media: detección vía `media-control stream`, artwork, progreso en tiempo real, controles
- Hide automático del slot de media cuando no hay nada reproduciéndose
- Reinicio automático del subproceso `media-control` si falla

### Conocido / Pendiente
- El progreso no tiene scrubber interactivo (solo visual)
- No hay soporte para múltiples fuentes de audio simultáneas en la UI (se quitó el layout compacto multi-fuente)
- Las preferencias no tienen opción para cambiar el tamaño del panel
