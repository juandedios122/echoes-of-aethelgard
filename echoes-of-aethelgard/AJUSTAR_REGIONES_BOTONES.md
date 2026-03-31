# 🎯 Ajustar las Regiones de los Botones

He creado AtlasTextures para recortar cada botón de la imagen `buttons_set_fantasy.png` y eliminar el fondo blanco.

## 📍 Valores Actuales de las Regiones

Basándome en la imagen que proporcionaste, he configurado estas regiones:

- **Botón JUGAR**: `Rect2(165, 30, 900, 250)`
- **Botón INVOCACIONES**: `Rect2(165, 330, 900, 250)`
- **Botón HÉROES**: `Rect2(165, 630, 900, 250)`

## 🔧 Cómo Ajustar si es Necesario

Si los botones aún muestran fondo blanco o están mal recortados:

### Opción 1: Ajustar en Godot (Recomendado)

1. Abre Godot y ve a `resources/ui/`
2. Selecciona uno de los archivos de tema (ej. `theme_button_jugar.tres`)
3. En el Inspector, expande `Button > Styles > Normal`
4. Busca la propiedad `Region Rect`
5. Ajusta los valores:
   - **X**: Posición horizontal del inicio del recorte
   - **Y**: Posición vertical del inicio del recorte
   - **W (Width)**: Ancho del recorte
   - **H (Height)**: Alto del recorte

6. Observa la previsualización en tiempo real
7. Repite para los otros dos temas de botones

### Opción 2: Editar los Archivos .tres Manualmente

Edita estos archivos y cambia los valores en `region_rect`:

- `resources/ui/theme_button_jugar.tres`
- `resources/ui/theme_button_invocaciones.tres`
- `resources/ui/theme_button_heroes.tres`

Busca la línea:
```
region_rect = Rect2(X, Y, Ancho, Alto)
```

## 📐 Cómo Encontrar los Valores Correctos

1. Abre `assets/ui/buttons_set_fantasy.png` en un editor de imágenes
2. Usa la herramienta de selección rectangular
3. Selecciona solo la parte metálica del primer botón (sin blanco)
4. Anota las coordenadas X, Y y el tamaño W, H
5. Usa esos valores en Godot

## 🎨 Ajustes Adicionales

### Márgenes de Textura

Si los bordes del botón se ven estirados, ajusta los márgenes:

```
texture_margin_left = 40.0
texture_margin_top = 40.0
texture_margin_right = 40.0
texture_margin_bottom = 40.0
```

Estos valores definen qué partes del botón NO se estiran (las esquinas y bordes).

### Color del Texto

El texto ahora está en color oscuro para contrastar con el metal claro:

```
Button/colors/font_color = Color(0.3, 0.25, 0.2, 1)
```

Si quieres texto más claro, cambia a valores más altos (ej. `0.9, 0.85, 0.8`).

## ✅ Resultado Esperado

Después de ajustar correctamente:
- ✅ Solo se ve el botón de metal con su decoración
- ✅ No hay fondo blanco
- ✅ Los bordes están limpios
- ✅ El texto es legible sobre el metal

## 🐛 Solución de Problemas

**Problema**: Los botones se ven estirados o deformados
- **Solución**: Ajusta `custom_minimum_size` en `MainMenu.tscn` para que coincida con la proporción de tus botones

**Problema**: Aún veo fondo blanco
- **Solución**: Reduce el ancho (W) y alto (H) en `region_rect` hasta que solo veas el metal

**Problema**: Los botones están cortados
- **Solución**: Aumenta el ancho (W) y alto (H) en `region_rect`

**Problema**: El botón está en la posición incorrecta
- **Solución**: Ajusta X e Y en `region_rect` para mover el recorte
