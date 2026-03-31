# Paleta de Colores Medieval - Hero Roster

## 🎨 Nueva Paleta Implementada

### Colores de Rareza (HeroData.gd)
Reemplazados los colores brillantes por tonos medievales:

| Rareza | Antes | Ahora | Descripción |
|--------|-------|-------|-------------|
| Común | `Color.GRAY` | `Color(0.5, 0.48, 0.45, 1)` | Hierro/gris piedra |
| Raro | `Color("4da6ff")` (azul brillante) | `Color(0.55, 0.6, 0.65, 1)` | Plata envejecida |
| Épico | `Color("a855f7")` (morado brillante) | `Color(0.65, 0.5, 0.4, 1)` | Cobre oxidado |
| Legendario | `Color("f59e0b")` (dorado brillante) | `Color(0.7, 0.6, 0.45, 1)` | Bronce antiguo |

### Colores de UI (HeroRosterScreen.gd)

#### Títulos y Encabezados
- **Título principal**: `Color(0.75, 0.65, 0.5, 1)` - Pergamino envejecido
- **Subtítulo del héroe**: `Color(0.75, 0.65, 0.5, 1)` - Pergamino envejecido
- **Títulos de sección**: `Color(0.8, 0.7, 0.55, 1)` - Pergamino claro
- **Botón volver**: `Color(0.8, 0.7, 0.55, 1)` - Pergamino claro

#### Elementos de Nivel y Progreso
- **Nivel actual**: `Color(0.6, 0.75, 0.5, 1)` - Verde musgo
- **Badge de nivel (fondo)**: `Color(0.15, 0.1, 0.08, 0.95)` - Madera oscura
- **Badge de nivel (borde)**: `Color(0.6, 0.5, 0.35, 1)` - Bronce
- **Badge de nivel (texto)**: `Color(0.85, 0.75, 0.6, 1)` - Pergamino claro
- **Barra de experiencia**: `Color(0.7, 0.55, 0.35, 1)` - Bronce/cobre
- **Nivel máximo**: `Color(0.8, 0.7, 0.5, 1)` - Oro viejo

#### Estadísticas
- **Título de stats**: `Color(0.8, 0.7, 0.55, 1)` - Pergamino/bronce
- **Facción**: `Color(0.7, 0.6, 0.5, 1)` - Bronce envejecido

#### Estrellas y Copias
- **Panel de estrellas (fondo)**: `Color(0.2, 0.15, 0.12, 0.7)` - Madera oscura
- **Panel de estrellas (borde)**: `Color(0.65, 0.55, 0.4, 0.8)` - Bronce envejecido
- **Texto de copias**: `Color(0.8, 0.7, 0.55, 1)` - Pergamino
- **Máximo alcanzado**: `Color(0.8, 0.7, 0.5, 1)` - Oro viejo

#### Historia y Lore
- **Título de lore**: `Color(0.8, 0.7, 0.55, 1)` - Pergamino

#### Botones de Acción
- **Botón ascender (borde)**: `Color(0.7, 0.6, 0.45, 1)` - Bronce
- **Botón ascender (fondo)**: `Color(0.3, 0.2, 0.35, 1)` - Madera oscura con tinte

### Colores de Tarjetas (HeroRosterCard.gd)
- **Borde de selección**: `Color(0.7, 0.6, 0.45, 1)` - Bronce

### Colores de Escena (HeroRosterScreen.tscn)
- **Título principal**: `Color(0.75, 0.65, 0.5, 1)` - Pergamino envejecido
- **Botón volver**: `Color(0.8, 0.7, 0.55, 1)` - Pergamino claro
- **Filtros**: `Color(0.8, 0.7, 0.55, 1)` - Pergamino claro

## 🎯 Filosofía de la Paleta

### Inspiración Medieval
La paleta está inspirada en:
- **Pergaminos envejecidos**: Tonos beige/marrón claro para texto importante
- **Metales oxidados**: Bronce, cobre y hierro envejecido para acentos
- **Madera oscura**: Fondos de paneles y elementos estructurales
- **Piedra y tierra**: Colores base neutros y naturales
- **Plata empañada**: Para elementos raros pero no ostentosos

### Evitar
❌ Amarillos brillantes (#FFD700, #FFC107)
❌ Azules neón (#00FFFF, #4DA6FF)
❌ Morados vibrantes (#A855F7, #9333EA)
❌ Verdes neón (#00FF00, #4ADE80)
❌ Colores saturados y brillantes

### Usar
✅ Tonos tierra (marrones, beiges, ocres)
✅ Metales oxidados (bronce, cobre, hierro)
✅ Verdes naturales (musgo, bosque)
✅ Grises piedra
✅ Colores desaturados y envejecidos

## 📝 Notas de Implementación

### Para aplicar los cambios:
1. Los cambios en `HeroData.gd` afectan a TODOS los héroes automáticamente
2. Reiniciar el juego o recargar la escena para ver los cambios
3. Los colores de rareza ahora son consistentes en toda la UI

### Archivos modificados:
- `scripts/resources/HeroData.gd` - Colores de rareza base
- `scripts/ui/HeroRosterScreen.gd` - Colores de UI de detalles
- `scripts/ui/HeroRosterCard.gd` - Colores de tarjetas
- `scenes/ui/HeroRosterScreen.tscn` - Colores de elementos de escena
- `scenes/ui/HeroRosterCard.tscn` - Colores de elementos de tarjeta

### Resultado esperado:
- Nombres de héroes en tonos bronce/cobre según rareza (no azul/morado brillante)
- Bordes y acentos en bronce envejecido (no dorado brillante)
- Texto en tonos pergamino (no amarillo brillante)
- Niveles en verde musgo (no verde neón)
- Barras de progreso en bronce/cobre (no naranja brillante)
- Estética general medieval coherente y atmosférica
