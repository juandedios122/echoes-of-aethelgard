# Guía de Optimización de UI - Juego Medieval RPG

## 1. Migración de Código a Escenas (.tscn)

### ✅ Ventajas de usar Escenas
- **Visualización en tiempo real**: Ves cómo queda la UI mientras la diseñas
- **Mejor rendimiento**: Los nodos se instancian más rápido desde escenas
- **Mantenibilidad**: Cambios visuales sin tocar código
- **Reutilización**: Usa la misma escena en múltiples lugares

### 📝 Ejemplo de Migración

**Antes (Todo en código):**
```gdscript
func _create_hero_panel():
    var panel = PanelContainer.new()
    var vbox = VBoxContainer.new()
    var label = Label.new()
    label.text = "Nombre"
    label.add_theme_font_size_override("font_size", 24)
    # ... 50 líneas más
```

**Después (Usando escena):**
```gdscript
@onready var hero_panel = preload("res://scenes/ui/HeroDetailPanel.tscn")
@onready var name_label = $HeroPanel/NameLabel

func display_hero(hero: HeroData):
    name_label.text = hero.hero_name
    # Solo 1 línea para actualizar
```

## 2. NinePatchRect y StyleBoxTexture para Pixel Art

### 🎨 Crear Texturas de Panel Medieval

1. **Crea un sprite de 32x32 píxeles** con:
   - Esquinas decoradas (8x8 píxeles cada una)
   - Bordes que se pueden repetir
   - Centro que se puede estirar

2. **Configurar en Godot:**
```gdscript
var texture_style = StyleBoxTexture.new()
texture_style.texture = load("res://ui/panel_madera.png")
# Márgenes para las esquinas (no se estiran)
texture_style.texture_margin_left = 8
texture_style.texture_margin_right = 8
texture_style.texture_margin_top = 8
texture_style.texture_margin_bottom = 8
# Márgenes de contenido (padding interno)
texture_style.content_margin_left = 12
texture_style.content_margin_right = 12
texture_style.content_margin_top = 12
texture_style.content_margin_bottom = 12

panel.add_theme_stylebox_override("panel", texture_style)
```

### 📦 Texturas Recomendadas para tu Juego

Crea estas texturas en tu carpeta `assets/ui/`:

- `panel_madera.png` - Panel de madera para información general
- `panel_piedra.png` - Panel de piedra para stats
- `panel_pergamino.png` - Fondo de pergamino para historia/lore
- `boton_madera.png` - Botón estilo tabla de madera
- `boton_metal.png` - Botón metálico para acciones importantes
- `marco_retrato.png` - Marco decorativo para retratos de héroes

### 🎯 Ejemplo Completo con NinePatchRect

```gdscript
# En el editor, añade un NinePatchRect
# O créalo por código:
var nine_patch = NinePatchRect.new()
nine_patch.texture = load("res://assets/ui/panel_madera.png")
nine_patch.region_rect = Rect2(0, 0, 32, 32)
nine_patch.patch_margin_left = 8
nine_patch.patch_margin_right = 8
nine_patch.patch_margin_top = 8
nine_patch.patch_margin_bottom = 8
nine_patch.custom_minimum_size = Vector2(200, 100)
```

## 3. Sistema de Partículas para Feedback Visual

### ✨ Partículas de Nivel Subido

```gdscript
func _spawn_level_up_particles(position: Vector2) -> void:
    var particles = GPUParticles2D.new()
    add_child(particles)
    particles.global_position = position
    
    # Configuración básica
    particles.amount = 30
    particles.lifetime = 1.0
    particles.one_shot = true
    particles.explosiveness = 0.8
    
    # Material de partícula
    var material = ParticleProcessMaterial.new()
    material.direction = Vector3(0, -1, 0)
    material.spread = 45.0
    material.gravity = Vector3(0, 200, 0)
    material.initial_velocity_min = 100.0
    material.initial_velocity_max = 200.0
    material.scale_min = 2.0
    material.scale_max = 4.0
    
    # Color dorado
    var gradient = Gradient.new()
    gradient.add_point(0.0, Color(1, 0.9, 0.3, 1))
    gradient.add_point(1.0, Color(1, 0.6, 0.1, 0))
    material.color_ramp = gradient
    
    particles.process_material = material
    particles.emitting = true
    
    # Auto-eliminar
    await get_tree().create_timer(2.0).timeout
    particles.queue_free()
```

### 🌟 Partículas de Ascensión (Más Espectaculares)

```gdscript
func _spawn_ascension_particles(hero_portrait: Control) -> void:
    # Partículas principales
    var main_particles = _create_star_particles(hero_portrait.global_position)
    add_child(main_particles)
    
    # Anillo de luz expandiéndose
    var ring_particles = _create_ring_particles(hero_portrait.global_position)
    add_child(ring_particles)
    
    # Destello de luz
    var flash = ColorRect.new()
    flash.color = Color(1, 1, 1, 0.8)
    flash.size = hero_portrait.size
    flash.position = hero_portrait.position
    hero_portrait.add_child(flash)
    
    var tween = create_tween()
    tween.tween_property(flash, "modulate:a", 0.0, 0.5)
    tween.tween_callback(flash.queue_free)

func _create_star_particles(pos: Vector2) -> GPUParticles2D:
    var particles = GPUParticles2D.new()
    particles.global_position = pos
    particles.amount = 50
    particles.lifetime = 2.0
    particles.one_shot = true
    
    var material = ParticleProcessMaterial.new()
    material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    material.emission_sphere_radius = 100.0
    material.direction = Vector3(0, -1, 0)
    material.spread = 180.0
    material.gravity = Vector3(0, -50, 0)
    material.initial_velocity_min = 150.0
    material.initial_velocity_max = 300.0
    
    # Colores místicos (púrpura/dorado)
    var gradient = Gradient.new()
    gradient.add_point(0.0, Color(0.9, 0.7, 1, 1))
    gradient.add_point(0.5, Color(1, 0.8, 0.3, 1))
    gradient.add_point(1.0, Color(1, 0.5, 0.2, 0))
    material.color_ramp = gradient
    
    particles.process_material = material
    particles.emitting = true
    
    return particles
```

## 4. Optimizaciones Adicionales

### 🚀 Pool de Objetos para Partículas

```gdscript
# Singleton: ParticlePool.gd
extends Node

var particle_pool: Array[GPUParticles2D] = []
const POOL_SIZE = 10

func _ready():
    for i in POOL_SIZE:
        var particles = GPUParticles2D.new()
        particles.one_shot = true
        particle_pool.append(particles)

func get_particles() -> GPUParticles2D:
    for p in particle_pool:
        if not p.emitting:
            return p
    # Si no hay disponibles, crear uno nuevo
    var new_p = GPUParticles2D.new()
    particle_pool.append(new_p)
    return new_p

func spawn_effect(type: String, position: Vector2):
    var particles = get_particles()
    # Configurar según el tipo
    match type:
        "level_up":
            _configure_level_up(particles)
        "ascension":
            _configure_ascension(particles)
    particles.global_position = position
    particles.restart()
```

### 🎵 Sistema de Audio Mejorado

```gdscript
# AudioManager.gd - Añadir variaciones
func play_sfx(sfx_name: String, pitch_variation: float = 0.1):
    var player = AudioStreamPlayer.new()
    add_child(player)
    player.stream = load("res://audio/sfx/%s.ogg" % sfx_name)
    # Variación de pitch para que no suene repetitivo
    player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
    player.play()
    player.finished.connect(player.queue_free)
```

### 📊 Animaciones de Números (Juice++)

```gdscript
func animate_stat_change(label: Label, from: int, to: int, duration: float = 0.5):
    var tween = create_tween()
    tween.tween_method(
        func(value): label.text = str(int(value)),
        float(from),
        float(to),
        duration
    )
    
    # Efecto de "pop" cuando cambia
    tween.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), duration * 0.3)
    tween.tween_property(label, "scale", Vector2(1.0, 1.0), duration * 0.2)
    
    # Color temporal si aumenta
    if to > from:
        label.add_theme_color_override("font_color", Color(0.3, 1, 0.3, 1))
        await get_tree().create_timer(duration).timeout
        label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
```

## 5. Checklist de Implementación

### Fase 1: Migración a Escenas
- [ ] Crear `HeroDetailPanel.tscn` con todos los nodos necesarios
- [ ] Crear script `HeroDetailPanel.gd` con referencias @onready
- [ ] Reemplazar código de creación dinámica por instanciación de escena
- [ ] Probar que todo funciona igual

### Fase 2: Texturas Pixel Art
- [ ] Diseñar sprites de paneles 32x32 con bordes de 8px
- [ ] Crear `panel_madera.png`, `panel_piedra.png`, `panel_pergamino.png`
- [ ] Configurar StyleBoxTexture con márgenes correctos
- [ ] Aplicar a todos los paneles principales

### Fase 3: Partículas y Efectos
- [ ] Implementar partículas de nivel subido (doradas)
- [ ] Implementar partículas de ascensión (púrpura/dorado)
- [ ] Añadir efectos de sonido con variación de pitch
- [ ] Crear animaciones de números para stats

### Fase 4: Pulido Final
- [ ] Pool de partículas para mejor rendimiento
- [ ] Transiciones suaves entre estados
- [ ] Feedback visual en todos los botones
- [ ] Probar en diferentes resoluciones

## 6. Recursos Útiles

### Herramientas para Pixel Art
- **Aseprite** - Editor profesional de pixel art
- **Piskel** - Editor online gratuito
- **Lospec** - Paletas de colores para pixel art

### Paleta Medieval Recomendada
```
Madera oscura: #3d2817
Madera clara: #8b6f47
Piedra: #5a5a5a
Metal: #b8b8b8
Oro: #ffd700
Bronce: #cd7f32
Pergamino: #f4e4c1
Tinta: #2b1810
```

### Sonidos Recomendados
- Subir nivel: Campanilla + "whoosh" ascendente
- Ascensión: Coro épico corto + destello
- Error: Madera golpeando + tono bajo
- Click: Madera suave

## 7. Ejemplo Completo Integrado

```gdscript
# HeroRosterScreen.gd - Versión optimizada
extends Control

const HERO_DETAIL_PANEL = preload("res://scenes/ui/HeroDetailPanel.tscn")

@onready var detail_container: Control = $DetailContainer
var current_detail_panel: HeroDetailPanel = null

func _on_hero_selected(hero: HeroData) -> void:
    # Limpiar panel anterior
    if current_detail_panel:
        current_detail_panel.queue_free()
    
    # Instanciar nuevo panel
    current_detail_panel = HERO_DETAIL_PANEL.instantiate()
    detail_container.add_child(current_detail_panel)
    
    # Animación de entrada
    current_detail_panel.modulate.a = 0
    current_detail_panel.position.x += 50
    var tween = create_tween()
    tween.tween_property(current_detail_panel, "modulate:a", 1.0, 0.3)
    tween.parallel().tween_property(current_detail_panel, "position:x", 0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    
    # Mostrar héroe
    var is_owned = GameManager.player_data.has_hero(hero.hero_id)
    current_detail_panel.display_hero(hero, is_owned)
```

---

**Nota Final**: Estas optimizaciones no solo mejoran el rendimiento, sino que hacen que tu juego se sienta más profesional y satisfactorio de jugar. El "game feel" es crucial en juegos gacha/RPG donde los jugadores pasan mucho tiempo en menús.
