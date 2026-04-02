# Tutorial: Crear Texturas NinePatch para UI Medieval

## ¿Qué es un NinePatch?

Un NinePatch es una imagen especial que se divide en 9 secciones:

```
┌─────┬─────────┬─────┐
│  1  │    2    │  3  │  ← Esquinas y borde superior
├─────┼─────────┼─────┤
│  4  │    5    │  6  │  ← Bordes laterales y centro
├─────┼─────────┼─────┤
│  7  │    8    │  9  │  ← Esquinas y borde inferior
└─────┴─────────┴─────┘
```

- **Secciones 1, 3, 7, 9**: Esquinas (nunca se estiran)
- **Secciones 2, 8**: Bordes horizontales (se estiran horizontalmente)
- **Secciones 4, 6**: Bordes verticales (se estiran verticalmente)
- **Sección 5**: Centro (se estira en ambas direcciones)

## Estructura de Archivo Recomendada

```
assets/ui/
├── panels/
│   ├── panel_madera_32x32.png
│   ├── panel_piedra_32x32.png
│   └── panel_pergamino_32x32.png
├── buttons/
│   ├── boton_madera_32x32.png
│   └── boton_metal_32x32.png
└── frames/
    └── marco_retrato_64x64.png
```

## Ejemplo 1: Panel de Madera (32x32)

### Diseño del Sprite

```
Píxeles 0-7: Borde izquierdo decorado
Píxeles 8-23: Centro repetible
Píxeles 24-31: Borde derecho decorado

┌────────┬────────────────┬────────┐
│ 8x8    │ 16x8           │ 8x8    │
│ Esquina│ Borde superior │ Esquina│
├────────┼────────────────┼────────┤
│ 8x16   │ 16x16          │ 8x16   │
│ Borde  │ Centro         │ Borde  │
├────────┼────────────────┼────────┤
│ 8x8    │ 16x8           │ 8x8    │
│ Esquina│ Borde inferior │ Esquina│
└────────┴────────────────┴────────┘
```

### Paleta de Colores Medieval

```gdscript
# Madera
var wood_dark = Color("#3d2817")    # Sombras
var wood_mid = Color("#6b4423")     # Base
var wood_light = Color("#8b6f47")   # Luces
var wood_highlight = Color("#a89968") # Brillos

# Piedra
var stone_dark = Color("#3a3a3a")
var stone_mid = Color("#5a5a5a")
var stone_light = Color("#7a7a7a")

# Metal
var metal_dark = Color("#4a4a4a")
var metal_mid = Color("#8a8a8a")
var metal_light = Color("#b8b8b8")
var metal_shine = Color("#e8e8e8")
```

## Ejemplo 2: Configuración en Godot

### Método 1: StyleBoxTexture (Recomendado para Paneles)

```gdscript
func create_wooden_panel_style() -> StyleBoxTexture:
    var style = StyleBoxTexture.new()
    style.texture = load("res://assets/ui/panels/panel_madera_32x32.png")
    
    # Márgenes de textura (define las 9 secciones)
    style.texture_margin_left = 8
    style.texture_margin_right = 8
    style.texture_margin_top = 8
    style.texture_margin_bottom = 8
    
    # Márgenes de contenido (padding interno)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    
    # Modulación de color (opcional)
    style.modulate_color = Color(1, 1, 1, 1)
    
    return style

# Uso:
var panel = PanelContainer.new()
panel.add_theme_stylebox_override("panel", create_wooden_panel_style())
```

### Método 2: NinePatchRect (Para Decoraciones)

```gdscript
func create_wooden_frame() -> NinePatchRect:
    var frame = NinePatchRect.new()
    frame.texture = load("res://assets/ui/panels/panel_madera_32x32.png")
    
    # Región de la textura a usar
    frame.region_rect = Rect2(0, 0, 32, 32)
    
    # Márgenes del patch
    frame.patch_margin_left = 8
    frame.patch_margin_right = 8
    frame.patch_margin_top = 8
    frame.patch_margin_bottom = 8
    
    # Tamaño mínimo
    frame.custom_minimum_size = Vector2(100, 100)
    
    # Modo de dibujo
    frame.draw_center = true  # Dibujar el centro
    
    return frame
```

## Ejemplo 3: Botón con Textura

```gdscript
func create_medieval_button(text: String) -> Button:
    var button = Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(120, 40)
    
    # Estilo normal
    var normal_style = StyleBoxTexture.new()
    normal_style.texture = load("res://assets/ui/buttons/boton_madera_32x32.png")
    normal_style.texture_margin_left = 8
    normal_style.texture_margin_right = 8
    normal_style.texture_margin_top = 8
    normal_style.texture_margin_bottom = 8
    button.add_theme_stylebox_override("normal", normal_style)
    
    # Estilo hover (más claro)
    var hover_style = normal_style.duplicate()
    hover_style.modulate_color = Color(1.2, 1.2, 1.2, 1)
    button.add_theme_stylebox_override("hover", hover_style)
    
    # Estilo pressed (más oscuro)
    var pressed_style = normal_style.duplicate()
    pressed_style.modulate_color = Color(0.8, 0.8, 0.8, 1)
    button.add_theme_stylebox_override("pressed", pressed_style)
    
    return button
```

## Ejemplo 4: Sistema de Temas Reutilizable

```gdscript
# MedievalTheme.gd - Autoload
extends Node

var wooden_panel_style: StyleBoxTexture
var stone_panel_style: StyleBoxTexture
var parchment_style: StyleBoxTexture

func _ready():
    _load_styles()

func _load_styles():
    # Panel de madera
    wooden_panel_style = _create_style(
        "res://assets/ui/panels/panel_madera_32x32.png",
        8, 8, 8, 8
    )
    
    # Panel de piedra
    stone_panel_style = _create_style(
        "res://assets/ui/panels/panel_piedra_32x32.png",
        8, 8, 8, 8
    )
    
    # Pergamino
    parchment_style = _create_style(
        "res://assets/ui/panels/panel_pergamino_32x32.png",
        10, 10, 10, 10
    )

func _create_style(path: String, ml: int, mr: int, mt: int, mb: int) -> StyleBoxTexture:
    var style = StyleBoxTexture.new()
    style.texture = load(path)
    style.texture_margin_left = ml
    style.texture_margin_right = mr
    style.texture_margin_top = mt
    style.texture_margin_bottom = mb
    style.content_margin_left = ml + 4
    style.content_margin_right = mr + 4
    style.content_margin_top = mt + 4
    style.content_margin_bottom = mb + 4
    return style

func apply_wooden_style(panel: PanelContainer):
    panel.add_theme_stylebox_override("panel", wooden_panel_style)

func apply_stone_style(panel: PanelContainer):
    panel.add_theme_stylebox_override("panel", stone_panel_style)

func apply_parchment_style(panel: PanelContainer):
    panel.add_theme_stylebox_override("panel", parchment_style)

# Uso en cualquier script:
# MedievalTheme.apply_wooden_style(my_panel)
```

## Ejemplo 5: Animación de Textura

```gdscript
# Cambiar entre texturas con animación
func animate_panel_upgrade(panel: PanelContainer):
    var tween = create_tween()
    
    # Fade out
    tween.tween_property(panel, "modulate:a", 0.0, 0.2)
    
    # Cambiar estilo
    tween.tween_callback(func():
        MedievalTheme.apply_stone_style(panel)
    )
    
    # Fade in con efecto
    tween.tween_property(panel, "modulate:a", 1.0, 0.3)
    tween.parallel().tween_property(panel, "scale", Vector2(1.1, 1.1), 0.15)
    tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.15)
```

## Tips de Diseño

### 1. Consistencia Visual
- Usa la misma paleta de colores en todos los paneles
- Mantén el mismo grosor de borde (8px es estándar)
- Usa el mismo estilo de decoración (clavos, grietas, etc.)

### 2. Legibilidad
- El centro debe ser lo suficientemente neutro para no distraer del contenido
- Evita patrones muy repetitivos en el centro
- Usa colores que contrasten bien con el texto

### 3. Optimización
- Usa texturas pequeñas (32x32 o 64x64)
- Comparte texturas entre elementos similares
- Usa atlas de texturas para reducir draw calls

### 4. Variaciones
Crea variaciones para diferentes contextos:
- **Normal**: Uso general
- **Destacado**: Información importante (bordes dorados)
- **Peligro**: Advertencias (bordes rojos)
- **Éxito**: Confirmaciones (bordes verdes)

## Plantilla de Código Completa

```gdscript
# UIStyleManager.gd
class_name UIStyleManager
extends Node

static func create_panel_style(
    texture_path: String,
    margin: int = 8,
    tint: Color = Color.WHITE
) -> StyleBoxTexture:
    var style = StyleBoxTexture.new()
    style.texture = load(texture_path)
    style.texture_margin_left = margin
    style.texture_margin_right = margin
    style.texture_margin_top = margin
    style.texture_margin_bottom = margin
    style.content_margin_left = margin + 4
    style.content_margin_right = margin + 4
    style.content_margin_top = margin + 4
    style.content_margin_bottom = margin + 4
    style.modulate_color = tint
    return style

static func create_button_styles(
    texture_path: String,
    margin: int = 8
) -> Dictionary:
    var normal = create_panel_style(texture_path, margin, Color.WHITE)
    var hover = create_panel_style(texture_path, margin, Color(1.2, 1.2, 1.2))
    var pressed = create_panel_style(texture_path, margin, Color(0.8, 0.8, 0.8))
    var disabled = create_panel_style(texture_path, margin, Color(0.5, 0.5, 0.5))
    
    return {
        "normal": normal,
        "hover": hover,
        "pressed": pressed,
        "disabled": disabled
    }

static func apply_button_styles(button: Button, styles: Dictionary):
    button.add_theme_stylebox_override("normal", styles.normal)
    button.add_theme_stylebox_override("hover", styles.hover)
    button.add_theme_stylebox_override("pressed", styles.pressed)
    button.add_theme_stylebox_override("disabled", styles.disabled)

# Uso:
# var styles = UIStyleManager.create_button_styles("res://assets/ui/buttons/boton_madera.png")
# UIStyleManager.apply_button_styles(my_button, styles)
```

## Recursos para Crear Texturas

### Software Recomendado
1. **Aseprite** ($19.99) - El mejor para pixel art
2. **Piskel** (Gratis) - Editor online
3. **GIMP** (Gratis) - Para edición general

### Tutoriales Útiles
- Busca "pixel art wood texture tutorial"
- Busca "pixel art stone texture tutorial"
- Busca "medieval UI pixel art"

### Sitios de Recursos
- **OpenGameArt.org** - Assets gratuitos
- **Itch.io** - Packs de UI medieval
- **Kenney.nl** - Assets gratuitos de alta calidad

---

**Próximos Pasos:**
1. Crea tus primeras texturas 32x32
2. Pruébalas en Godot con StyleBoxTexture
3. Ajusta los márgenes hasta que se vean bien
4. Crea un sistema de temas reutilizable
5. Aplica a toda tu UI

¡Tu juego se verá mucho más profesional con texturas pixel art bien implementadas!
