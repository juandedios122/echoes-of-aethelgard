# ⚔️ Echoes of Aethelgard — Guía del Proyecto

Juego gacha medieval 2D para móvil desarrollado en **Godot 4.x (GDScript)**.

---

## 📁 Estructura del Proyecto

```
EchoesOfAethelgard/
│
├── project.godot                    ← Configuración de Godot
│
├── scripts/
│   ├── autoloads/
│   │   ├── GameManager.gd           ← Singleton principal (registrar en Autoloads)
│   │   └── PlayerData.gd            ← Datos persistentes del jugador
│   │
│   ├── resources/
│   │   ├── HeroData.gd              ← Resource de héroe (instanciar como .tres)
│   │   ├── SkillData.gd             ← Resource de habilidades
│   │   └── StageData.gd             ← Resource de etapas
│   │
│   ├── systems/
│   │   ├── GachaSystem.gd           ← Lógica de invocaciones con pity
│   │   └── CombatManager.gd         ← Motor de combate por turnos
│   │
│   ├── combat/
│   │   ├── CombatUnit.gd            ← Héroe/enemigo en combate
│   │   └── BattleScene.gd           ← Controlador de la escena de batalla
│   │
│   └── ui/
│       ├── GachaScreen.gd           ← Pantalla de invocaciones
│       ├── HeroCard.gd              ← Tarjeta visual de héroe
│       └── HubCamp.gd               ← Campamento principal (menú hub)
│
├── scenes/
│   ├── ui/
│   │   ├── main_menu.tscn           ← Crear manualmente (usa HubCamp.gd)
│   │   ├── hub_camp.tscn
│   │   ├── gacha_screen.tscn
│   │   ├── hero_roster.tscn
│   │   └── HeroCard.tscn            ← Instancia de tarjeta
│   └── combat/
│       ├── battle_scene.tscn        ← Usa BattleScene.gd
│       ├── CombatUnit.tscn          ← Usa CombatUnit.gd
│       └── DamageLabel.tscn         ← Label flotante de daño
│
├── resources/
│   ├── heroes/                      ← Archivos .tres de HeroData
│   │   ├── aethan_paladin.tres
│   │   ├── lyra_archer.tres
│   │   └── ...
│   ├── enemies/                     ← HeroData usados como enemigos
│   │   ├── wolf_common.tres
│   │   └── skeleton_warrior.tres
│   └── stages/                      ← Archivos .tres de StageData
│       ├── stage_1-1.tres
│       └── ...
│
└── assets/
	├── sprites/
	│   ├── heroes/                  ← SpriteFrames por héroe
	│   └── enemies/
	├── backgrounds/
	├── ui/
	│   └── icon.png
	└── audio/
		├── bgm/
		└── sfx/
```

---

## 🚀 Pasos de Configuración en Godot

### 1. Crear el Proyecto
1. Abrir Godot 4 → Nuevo Proyecto → Nombre: `EchoesOfAethelgard`
2. Copiar todos los archivos `.gd` a sus rutas correspondientes
3. Copiar `project.godot` (o configurar manualmente)

### 2. Registrar el Autoload
```
Proyecto → Configuración del Proyecto → Autoloads
  Nombre: GameManager
  Ruta:   res://scripts/autoloads/GameManager.gd
```

### 3. Crear los Recursos de Héroes
1. En el Inspector: `Nuevo Recurso → HeroData`
2. Rellenar los campos: id, nombre, facción, rareza, stats, habilidades
3. Guardar como `res://resources/heroes/<hero_id>.tres`

**Ejemplo de héroe inicial:**
```
hero_id:    "aethan_paladin"
hero_name:  "Aethan"
title:      "El Último Paladín"
faction:    ORDEN_ALBA
rarity:     EPICO
role:       TANQUE
base_hp:    2200
base_atk:   95
base_def:   180
base_spd:   60
faction_bonus_hp:  0.10   ← +10% HP en sinergia de 3
```

### 4. Crear la Escena BattleScene
```
Node2D (BattleScene.gd)
├── ColorRect (Transition) — negro, full-rect
├── Node2D (PlayerUnitsContainer)
├── Node2D (EnemyUnitsContainer)
├── CombatManager (Node — CombatManager.gd)
└── CanvasLayer (BattleUI)
	├── HBoxContainer (SkillBar) — anclado abajo-centro
	├── Button (SpeedToggle) — arriba derecha
	├── Button (AutoToggle)
	└── Panel (ResultPanel) — centrado, oculto por defecto
```

### 5. Crear la Escena CombatUnit
```
Node2D (CombatUnit.gd)
├── AnimatedSprite2D
├── ProgressBar (HpBar) — encima del sprite
└── ProgressBar (EnergyBar) — debajo de HpBar
```

### 6. Crear DamageLabel
```
Node2D (DamageLabel.gd — script propio)
└── Label — texto grande, centrado
```

```gdscript
# DamageLabel.gd — script simple
extends Node2D
func setup(amount: int, is_heal: bool) -> void:
	$Label.text = ("%+d" if is_heal else "%d") % amount
	$Label.modulate = Color.GREEN if is_heal else Color.WHITE
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 80, 0.7)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.7)
	await tween.finished
	queue_free()
```

---

## 💎 Sistema Gacha — Tasas de Rareza

| Rareza     | Tasa Base | Pity Suave (75+) | Pity Duro |
|------------|-----------|------------------|-----------|
| Legendario |  0.6%     | +6% por tirada   | Tirada 90 |
| Épico      |  6.0%     | —                | —         |
| Raro       | 24.0%     | —                | —         |
| Común      | ~69.4%    | —                | —         |

**Garantía x10:** Al menos 1 héroe Raro o superior en cada tirada múltiple.

---

## ⚔️ Fórmula de Daño

```
daño_base = ATK_atacante × power_multiplier_habilidad
reducción  = 100 / (100 + DEF_defensor)
daño_final = daño_base × reducción × varianza(0.9–1.1)
crítico    = si rand() < crit_rate → daño × crit_dmg
escudo     = absorbe daño antes que el HP
```

---

## 🗺️ Capítulos y Biomas

| Capítulo | Bioma               | Enemigos Sugeridos       |
|----------|---------------------|--------------------------|
| 1        | Bosque Susurrante   | Lobos, Limos, Bandidos   |
| 2        | Ruinas de Hierro    | Esqueletos, Armaduras    |
| 3        | Ciudad de Cristal   | Sombras, Corrompidos     |

---

## 🛠️ Próximas Fases de Desarrollo

- [ ] **Fase 1 — Core:** GameManager + PlayerData + Guardado
- [ ] **Fase 2 — Gacha:** GachaSystem + 8 héroes base (2 por facción)
- [ ] **Fase 3 — UI:** HubCamp + GachaScreen + HeroCard
- [ ] **Fase 4 — Combate:** CombatManager + BattleScene + 3 etapas
- [ ] **Fase 5 — Audio:** BGM ambiental por bioma + SFX de habilidades
- [ ] **Fase 6 — Animaciones:** SpriteFrames + VFX de habilidades
- [ ] **Fase 7 — Monetización:** Tienda de Ámbar (opcional, cosmético)
- [ ] **Fase 8 — Exportación:** Build Android (.apk) + iO## ═══════════════════════════════════════════════════════════════
## ECHOES OF AETHELGARD — 10 Héroes Base
## Crear un archivo .tres por héroe en: res://resources/heroes/
## En Godot: Inspector → botón "+" → HeroData → guardar como .tres
## ═══════════════════════════════════════════════════════════════

## ─────────────────────────────────────────────────────────────────────────────
## 1. ORDEN DEL ALBA
## ─────────────────────────────────────────────────────────────────────────────

# ┌──────────────────────────────────────────────────────────┐
# │  AETHAN  —  "El Último Paladín"              [ÉPICO]     │
# │  Facción: Orden del Alba  │  Rol: Tanque  │ Elem: Luz    │
# └──────────────────────────────────────────────────────────┘
# Archivo: res://resources/heroes/aethan_paladin.tres

hero_id:    "aethan_paladin"
hero_name:  "Aethan"
title:      "El Último Paladín"
lore_text:  "Sobreviviente del asedio de Solheim, Aethan juró proteger a los inocentes mientras quede un hálito de fe en sus pulmones."
faction:    Faction.ORDEN_ALBA
rarity:     Rarity.EPICO
role:       Role.TANQUE
element:    Element.LUZ

# Stats base (nivel 1)
base_hp:    2200
base_atk:   95
base_def:   180
base_spd:   60
base_crit_rate: 0.05
base_crit_dmg:  1.5

# Crecimiento por nivel
hp_growth:  0.09   # +9% HP por nivel
atk_growth: 0.05
def_growth: 0.08   # Tanque = crece más en DEF

# Sinergia de facción (activa con 3 Orden del Alba)
faction_bonus_hp:   0.10   # +10% HP a todos los de su facción

# Habilidades:
# ⚔ Básica    — "Golpe Sagrado": 1.2× ATK, gana +10 de energía
# ✦ Activa    — "Juicio Divino": 0.9× ATK a TODOS los enemigos + aplica Bendición (+15% DEF) a todos los aliados por 2 turnos (coste: 40 energía)
# ◆ Pasiva    — "Aura Protectora": Reduce el daño recibido por aliados en un 8% permanentemente
# ★ Ultimate  — "Resurrección del Alba": Revive a 1 aliado caído con el 30% de su HP máximo (coste: 100 energía)

# Notas de diseño:
#   - Sinergiza perfecto con Seraphel y Kael (equipo 100% Orden del Alba)
#   - Su pasiva hace que incluso Magos tengan suficiente aguante
#   - Su ultimate crea situaciones de comeback dramáticas en combate
#   - Contrarresta al Cónclave Arcano (DEF buff)


# ┌──────────────────────────────────────────────────────────┐
# │  SERAPHEL  —  "La Jueza de Hierro"        [LEGENDARIO]  │
# │  Facción: Orden del Alba  │  Rol: Guerrero │ Elem: Luz   │
# └──────────────────────────────────────────────────────────┘
# Archivo: res://resources/heroes/seraphel_jueza.tres

hero_id:    "seraphel_jueza"
hero_name:  "Seraphel"
title:      "La Jueza de Hierro"
lore_text:  "Primera Comandante del Orden, su espada dictó sentencia sobre un centenar de generales traidores antes de que el Olvido la reclamara."
faction:    Faction.ORDEN_ALBA
rarity:     Rarity.LEGENDARIO
role:       Role.GUERRERO
element:    Element.LUZ

base_hp:    1800
base_atk:   210
base_def:   120
base_spd:   85
base_crit_rate: 0.12
base_crit_dmg:  1.75

hp_growth:  0.07
atk_growth: 0.08   # Legendaria = crece fuerte en ATK
def_growth: 0.06

faction_bonus_atk:  0.10   # +10% ATK a todos los de su facción

# Habilidades:
# ⚔ Básica    — "Cuchilla Solar": 1.5× ATK en golpe único al objetivo
# ✦ Activa    — "Veredicto": 2.2× ATK a 1 enemigo; si tiene <20% HP, lo ejecuta instantáneamente (coste: 50 energía)
# ◆ Pasiva    — "Fe Inquebrantable": Cada vez que un aliado muere, gana +15% ATK de forma permanente (máx 3 cargas)
# ★ Ultimate  — "Espada del Amanecer": 3× ATK a 1 objetivo, ignora el 50% de su DEF (coste: 100 energía)

# Notas de diseño:
#   - La mecánica de ejecución al <20% HP elimina la frustración del "casi muerto"
#   - Convierte las muertes del equipo en poder, incentivando builds de riesgo
#   - Su ultimate es el mayor daño single-target del pool base


# ┌──────────────────────────────────────────────────────────┐
# │  KAEL  —  "Soldado del Último Bastión"        [COMÚN]   │
# │  Facción: Orden del Alba  │  Rol: Guerrero │ Elem: Neutro│
# └──────────────────────────────────────────────────────────┘
# Archivo: res://resources/heroes/kael_soldado.tres

hero_id:    "kael_soldado"
hero_name:  "Kael"
title:      "Soldado del Último Bastión"
lore_text:  "No hay leyenda que contar de Kael. Solo un hombre que siguió peleando cuando todos los demás huyeron."
faction:    Faction.ORDEN_ALBA
rarity:     Rarity.COMUN
role:       Role.GUERRERO
element:    Element.NEUTRO

base_hp:    1600
base_atk:   120
base_def:   100
base_spd:   75
base_crit_rate: 0.05
base_crit_dmg:  1.5

hp_growth:  0.07
atk_growth: 0.06
def_growth: 0.06

faction_bonus_hp:  0.10   # Comparte sinergia con Aethan

# Habilidades:
# ⚔ Básica    — "Estocada": 1.2× ATK al objetivo frontal
# ✦ Activa    — "Golpe de Escudo": 0.8× ATK + 40% probabilidad de aturdir al objetivo 1 turno (coste: 30 energía)
# ◆ Pasiva    — "Veterano": Gana +5% ATK y +5% DEF acumulativos por cada turno que sobreviva (sin límite de stacks, sí de turnos)
# ★ Ultimate  — "Por la Corona": 1.8× ATK al objetivo + todos los aliados son inmunes al próximo golpe (escudo 1 hit)

# Notas de diseño:
#   - Personaje de tutorial / introducción: mecánicas simples, comprensibles
#   - Su pasiva escala bien en batallas largas (compensando su rareza)
#   - Completa el equipo Orden del Alba activa la sinergia de Seraphel y Aethan


## ─────────────────────────────────────────────────────────────────────────────
## 2. CAZADORES DEL BOSQUE
## ─────────────────────────────────────────────────────────────────────────────

# ┌──────────────────────────────────────────────────────────┐
# │  LYRA  —  "Susurro del Bosque"                [RARO]    │
# │  Facción: Cazadores  │  Rol: Arquero  │ Elem: Naturaleza │
# └──────────────────────────────────────────────────────────┘
# Archivo: res://resources/heroes/lyra_arquera.tres

hero_id:    "lyra_arquera"
hero_name:  "Lyra"
title:      "Susurro del Bosque"
lore_text:  "Nadie la ha visto moverse entre las ramas. Solo escuchan el silbido de la flecha cuando ya es demasiado tarde."
faction:    Faction.CAZADORES_BOSQUE
rarity:     Rarity.RARO
role:       Role.ARQUERO
element:    Element.NATURALEZA

base_hp:    1100
base_atk:   160
base_def:   60
base_spd:   130   # La más rápida de los RARO
base_crit_rate: 0.18
base_crit_dmg:  2.0

hp_growth:  0.05
atk_growth: 0.07
def_growth: 0.04

faction_bonus_atk:  0.05   # +5% ATK al equipo Cazadores

# Habilidades:
# ⚔ Básica    — "Flecha Rápida": 0.9× ATK; siempre actúa primero en el turno (ignora el orden normal de SPD)
# ✦ Activa    — "Lluvia de Flechas": 0.7× ATK × 2 golpes a TODOS los enemigos (coste: 40 energía)
# ◆ Pasiva    — "Ojo de Águila": Los ataques básicos ganan +25% daño crítico
# ★ Ultimate  — "Tiro Perfecto": 3.5× ATK al enemigo con mayor HP actual (coste: 100 energía)

# Notas de diseño:
#   - Alta velocidad compensa su baja defensa
#   - Synergy con Theron: Lyra envenena, Theron hace bonus sobre debuffed


# ┌──────────────────────────────────────────────────────────┐
# │  THERON  —  "Sombra entre las Ramas"          [ÉPICO]   │
# │  Facción: Cazadores  │  Rol: Mercenario │ Elem: Natur.  │
# └──────────────────────────────────────────────────────────┘
# Archivo: res://resources/heroes/theron_cazador.tres

hero_id:    "theron_cazador"
hero_name:  "Theron"
title:      "Sombra entre las Ramas"
lore_text:  "Dicen que es mitad hombre, mitad lobo. Quienes sobreviven para contarlo solo recuerdan sus ojos en la oscuridad."
faction:    Faction.CAZADORES_BOSQUE
rarity:     Rarity.EPICO
role:       Role.MERCENARIO
element:    Element.NATURALEZA

base_hp:    1350
base_atk:   190
base_def:   70
base_spd:   120
base_crit_rate: 0.22   # Crítico más alto del pool
base_crit_dmg:  2.2

hp_growth:  0.06
atk_growth: 0.08
def_growth: 0.04

faction_bonus_atk:  0.05

# Habilidades:
# ⚔ Básica    — "Daga Envenenada": 1.0× ATK + aplica Veneno (3% HP por turno durante 3 turnos)
# ✦ Activa    — "Emboscada": 2.0× ATK; daño aumentado en +50% si el objetivo tiene algún debuff activo (coste: 50 energía)
# ◆ Pasiva    — "Instinto Salvaje": 20% de probabilidad de atacar dos veces en el mismo turno
# ★ Ultimate  — "Danza de la Muerte": Ataca 4 veces a objetivos aleatorios, 1.2× ATK cada golpe (coste: 100 energía)

# Notas de diseño:
#   - Su combo natural: Daga → Emboscada (+50% daño sobre envenenado)
#   - Con 3 Cazadores activos y sinergia, su crit sube al 37% base → muy explosivo


# ┌──────────────────────────────────────────────────────────┐
# │  MIRA  —  "Guardiana del Claro"               [RARO]    │
# │  Facción: Cazadores  │  Rol: Curandero │ Elem: Natur.  │
# └──────────────────────────────────────────────────────────┘
# Archivo: res://resources/heroes/mira_sanadora.tres

hero_id:    "mira_sanadora"
hero_name:  "Mira"
title:      "Guardiana del Claro"
lore_text:  "El bosque llora cuando ella llora. Sus hierbas han cerrado heridas que ni la magia era capaz de sanar."
faction:    Faction.CAZADORES_BOSQUE
rarity:     Rarity.RARO
role:       Role.CURANDERO
element:    Element.NATURALEZA

base_hp:    1400
base_atk:   110
base_def:   90
base_spd:   95
base_crit_rate: 0.05
base_crit_dmg:  1.5

hp_growth:  0.07
atk_growth: 0.04   # No es un DPS
def_growth: 0.06

faction_bonus_hp:  0.05

# Habilidades:
# ⚔ Básica    — "Pulso Natural": 0.8× ATK al enemigo; cura simultáneamente al aliado con menos HP por (0.6× ATK)
# ✦ Activa    — "Regeneración": Cura a TODOS los aliados por el 25% de su HP máximo (coste: 50 energía)
# ◆ Pasiva    — "Raíces Antiguas": Cuando cura, tiene 30% de probabilidad de generar un Escudo al objetivo (absorbe 15% de HP máximo, dura 1 turno)
# ★ Ultimate  — "Florecer": Cura masiva a todos + incrementa SPD de todos los aliados en 20% durante 2 turnos (coste: 100 energía)

# Notas de diseño:
#   - La única sanadora del pool base; su presencia cambia radicalmente la estrategia
#   - Combina con Lyra (SPD alta ya de base + Florecer = siempre actúan primero)
#   - El escudo de su pasiva puede absorber el golpe de ejecución de Seraphel


## ─────────────────────────────────────────────────────────────────────────────
## 3. CÓNCLAVE ARCANO
## ─────────────────────────────────────────────────────────────────────────────

# ┌──────────────────────────────────────────────────────────┐
# │  ALDRIC  —  "El Archimago Errante"        [LEGENDARIO]  │
# │  Facción: Cónclave Arcano  │  Rol: Mago │ Elem: Arcano  │
# └──────────────────────────────────────────────────────────┘
# Archivo: res://resources/heroes/aldric_archimago.tres

hero_id:    "aldric_archimago"
hero_name:  "Aldric"
title:      "El Archimago Errante"
lore_text:  "Abandonó la torre hace cien años buscando el origen del Olvido. Su memoria está fragmentada, pero su poder, intacto."
faction:    Faction.CONCLAVE_ARCANO
rarity:     Rarity.LEGENDARIO
role:       Role.MAGO
element:    Element.ARCANO

base_hp:    1200
base_atk:   250   # ATK más alto de toda la plantilla
base_def:   55
base_spd:   90
base_crit_rate: 0.15
base_crit_dmg:  1.8

hp_growth:  0.05
atk_growth: 0.09   # Crece en ATK muy fuerte
def_growth: 0.03

faction_bonus_atk:  0.20   # +20% ATK si hay 3 Cónclave (brutal)

# Habilidades:
# ⚔ Básica    — "Proyectil Arcano": 1.3× ATK, ignora 20% de la DEF del objetivo
# ✦ Activa    — "Tormenta de Runas": 3 impactos de 0.6× ATK a TODOS los enemigos (total 1.8× AoE) (coste: 50 energía)
# ◆ Pasiva    — "Maestría Arcana": Cada habilidad lanzada acumula +10% de daño (máximo 30%, 3 cargas)
# ★ Ultimate  — "Fragmento del Nexo": 4× ATK a 1 objetivo + activa un turno extra inmediatamente (coste: 100 energía)

# Notas de diseño:
#   - Con sinergia Cónclave (+20%) y pasiva al máx (+30%): su ultimate hace ~5.2× ATK efectivo
#   - El turno extra de su ultimate es el efecto más poderoso del pool
#   - Contrabalanceado por 1.200 HP: un golpe de Varra o Theron lo mata


# ┌──────────────────────────────────────────────────────────┐
# │  VEX  —  "El Nigromante de Cristal"           [ÉPICO]   │
# │  Facción: Cónclave Arcano  │  Rol: Mago │ Elem: Sombra  │
# └──────────────────────────────────────────────────────────┘
# Archivo: res://resources/heroes/vex_nigromante.tres

hero_id:    "vex_nigromante"
hero_name:  "Vex"
title:      "El Nigromante de Cristal"
lore_text:  "La muerte no es un final para Vex. Es una materia prima."
faction:    Faction.CONCLAVE_ARCANO
rarity:     Rarity.EPICO
role:       Role.MAGO
element:    Element.SOMBRA

base_hp:    1100
base_atk:   220
base_def:   50
base_spd:   80
base_crit_rate: 0.10
base_crit_dmg:  1.6

hp_growth:  0.05
atk_growth: 0.08
def_growth: 0.03

faction_bonus_atk:  0.20

# Habilidades:
# ⚔ Básica    — "Toque Sombra": 1.1× ATK + aplica Debilidad (−15% DEF del objetivo, 2 turnos)
# ✦ Activa    — "Ejército Espectral": 1.4× ATK a TODOS los enemigos (coste: 40 energía)
# ◆ Pasiva    — "Drenar Alma": El 10% de todo el daño infligido se convierte en HP propio
# ★ Ultimate  — "Colapso de Olvido": 2× ATK a todos los enemigos + reduce la energía de todos a 0 (anula ultimates enemigos)

# Notas de diseño:
#   - Su ultimate "Colapso de Olvido" es el anti-meta definitivo: bloquea ultimates rivales
#   - Synergy con Aldric: Vex aplica Debilidad (−15% DEF), Aldric destroza con su ultimate
#   - La pasiva de robo de vida le da suficiente sustain para sobrevivir un turno más


## ─────────────────────────────────────────────────────────────────────────────
## 4. LOS RENEGADOS
## ─────────────────────────────────────────────────────────────────────────────

# ┌──────────────────────────────────────────────────────────┐
# │  GORN  —  "La Tormenta de Acero"              [ÉPICO]   │
# │  Facción: Renegados  │  Rol: Guerrero  │  Elem: Fuego   │
# └──────────────────────────────────────────────────────────┘
# Archivo: res://resources/heroes/gorn_barbaro.tres

hero_id:    "gorn_barbaro"
hero_name:  "Gorn"
title:      "La Tormenta de Acero"
lore_text:  "Fue soldado hasta que quemaron su aldea. Ahora pelea por el único rey que reconoce: el caos."
faction:    Faction.RENEGADOS
rarity:     Rarity.EPICO
role:       Role.GUERRERO
element:    Element.FUEGO

base_hp:    2000
base_atk:   200
base_def:   100
base_spd:   70
base_crit_rate: 0.10
base_crit_dmg:  1.6

hp_growth:  0.08
atk_growth: 0.07
def_growth: 0.06

faction_bonus_def:  0.10   # +10% DEF a todos los Renegados

# Habilidades:
# ⚔ Básica    — "Hachazo Brutal": 1.4× ATK al objetivo; reduce su DEF en 10% por 1 turno
# ✦ Activa    — "Furia Salvaje": 3 golpes de 1.0× ATK a enemigos aleatorios (coste: 40 energía)
# ◆ Pasiva    — "Piel de Hierro": Cuando su HP baja del 50%, activa permanentemente +30% ATK y +20% DEF adicionales
# ★ Ultimate  — "Berserker": 2.5× ATK al objetivo + es inmune a stun y debuffs durante 2 turnos (coste: 100 energía)

# Notas de diseño:
#   - Su pasiva lo convierte en más peligroso cuanto más lo golpean
#   - Combinarlo con Varra (que genera DoT) crea presión constante


# ┌──────────────────────────────────────────────────────────┐
# │  VARRA  —  "La Espada Sin Nombre"             [RARO]    │
# │  Facción: Renegados  │  Rol: Mercenario │ Elem: Fuego   │
# └──────────────────────────────────────────────────────────┘
# Archivo: res://resources/heroes/varra_mercenaria.tres

hero_id:    "varra_mercenaria"
hero_name:  "Varra"
title:      "La Espada Sin Nombre"
lore_text:  "Nadie sabe de dónde viene. Solo que su hoja siempre apunta hacia el oro y hacia la sangre."
faction:    Faction.RENEGADOS
rarity:     Rarity.RARO
role:       Role.MERCENARIO
element:    Element.FUEGO

base_hp:    1500
base_atk:   170
base_def:   80
base_spd:   100
base_crit_rate: 0.14
base_crit_dmg:  1.75

hp_growth:  0.06
atk_growth: 0.07
def_growth: 0.05

faction_bonus_atk:  0.10   # +10% ATK a los Renegados

# Habilidades:
# ⚔ Básica    — "Tajo Ardiente": 1.1× ATK + aplica Quemadura (3% HP máximo/turno durante 3 turnos)
# ✦ Activa    — "Precio de Sangre": 1.8× ATK al objetivo; el 50% del daño infligido se convierte en HP propio (coste: 50 energía)
# ◆ Pasiva    — "Sin Piedad": Inflige +30% de daño adicional a objetivos que tengan Quemadura o cualquier debuff activo
# ★ Ultimate  — "Inferno Sellado": Aplica Quemadura masiva a TODOS los enemigos (5% HP/turno durante 3 turnos) (coste: 100 energía)

# Notas de diseño:
#   - Su ultimate + pasiva + ataques básicos forman un loop de daño continuo
#   - Synergy con Gorn: Gorn reduce DEF, Varra explota con Quemadura
#   - El robo de vida de "Precio de Sangre" la hace autosuficiente a medias


## ═══════════════════════════════════════════════════════════════
## RESUMEN DE SINERGIAS
## ═══════════════════════════════════════════════════════════════

# EQUIPO A — Full Orden del Alba (Tanque/Sostenido)
#   Aethan + Seraphel + Kael
#   Sinergia: +10% HP (Aethan) + +10% ATK (Seraphel)
#   Estrategia: Kael aturde, Aethan aguanta, Seraphel ejecuta con Veredicto

# EQUIPO B — Full Cazadores del Bosque (Velocidad/Crítico)
#   Lyra + Theron + Mira
#   Sinergia: +15% CRIT implícita + Mira mantiene vivos a los frágiles
#   Estrategia: Lyra actúa primero, Theron envenena → Emboscada, Mira heal

# EQUIPO C — Full Cónclave Arcano (Nuke/AoE)
#   Aldric + Vex + [3er Arcano futuro]
#   Sinergia: +20% ATK brutal; Vex aplica Debilidad para Aldric
#   Estrategia: Vex anula ultimates → Aldric destruye con turno extra

# EQUIPO D — Full Renegados (Brutalidad/DoT)
#   Gorn + Varra + [3er Renegado futuro]
#   Sinergia: +10% DEF (Gorn) + +10% ATK (Varra)
#   Estrategia: Gorn reduce DEF → Varra quema → todos explotan

# EQUIPO E — Mixto Meta Recomendado para Campaña Early Game
#   Aethan (tanque) + Lyra (velocidad/DPS) + Mira (sanadora)
#   Sin sinergia de facción, pero cubre todos los roles esenciales
#   Accesible desde Capítulo 1

## ═══════════════════════════════════════════════════════════════
## ESCALADO DE STATS — Ejemplo nivel 30
## (base_stat × (1 + growth)^(level-1))
## ═══════════════════════════════════════════════════════════════
#
#  AETHAN (Tanque) al nivel 30:
#    HP:  2200 × (1.09)^29 ≈ 23,960
#    ATK:  95 × (1.05)^29  ≈   394
#    DEF: 180 × (1.08)^29  ≈ 1,721
#
#  ALDRIC (Mago) al nivel 30:
#    HP:  1200 × (1.05)^29 ≈  4,980
#    ATK:  250 × (1.09)^29 ≈  2,720   ← devastador
#    DEF:   55 × (1.03)^29 ≈    129   ← de cristal
#
# Esta diferencia hace que los roles se sientan distintos en endgame.
