# 🎵 Cómo Agregar Música al Juego

## Paso 1: Descargar Música Gratis

### Opción A: Incompetech (Recomendado - Fácil)

1. Ve a: **https://incompetech.com/music/royalty-free/music.html**
2. En el buscador, escribe estas palabras clave:

**Para menu_theme.mp3:**
- Busca: "Heroic Age" o "Crusade"
- Click en el nombre de la canción
- Click en "Download MP3"

**Para battle_theme.mp3:**
- Busca: "Crusade" o "Warrior"
- Download MP3

**Para exploration_theme.mp3:**
- Busca: "Enchanted Journey" o "Mystical"
- Download MP3

**Para gacha_theme.mp3:**
- Busca: "Mystical" o "Magic"
- Download MP3

### Opción B: Pixabay

1. Ve a: **https://pixabay.com/music/**
2. Busca: "epic medieval"
3. Click en la canción que te guste
4. Click en "Free Download"
5. Selecciona calidad y descarga

### Opción C: FreePD (Dominio Público)

1. Ve a: **https://freepd.com/**
2. Navega por categorías: "Epic" o "Orchestral"
3. Click derecho en "Download" → "Guardar enlace como..."

## Paso 2: Renombrar los Archivos

Después de descargar, renombra los archivos exactamente así:

```
menu_theme.mp3
battle_theme.mp3
exploration_theme.mp3
gacha_theme.mp3
```

## Paso 3: Colocar en la Carpeta Correcta

1. Abre la carpeta del proyecto
2. Ve a: `assets/audio/music/`
3. Copia los 4 archivos MP3 ahí

## Paso 4: Verificar en Godot

1. Abre el proyecto en Godot
2. En el panel "FileSystem", ve a `res://assets/audio/music/`
3. Deberías ver los 4 archivos con un ícono de audio
4. Godot los importará automáticamente

## Paso 5: Probar

1. Ejecuta el juego (F5)
2. La música debería sonar automáticamente:
   - Menú principal → menu_theme
   - Gacha → gacha_theme
   - Exploración → exploration_theme
   - Batalla → battle_theme

## 🎼 Recomendaciones Específicas de Incompetech

Si usas Incompetech, estas canciones funcionan perfecto:

| Archivo | Canción Recomendada | URL Directa |
|---------|---------------------|-------------|
| menu_theme.mp3 | "Heroic Age" | https://incompetech.com/music/royalty-free/music.html (buscar "Heroic Age") |
| battle_theme.mp3 | "Crusade" | https://incompetech.com/music/royalty-free/music.html (buscar "Crusade") |
| exploration_theme.mp3 | "Enchanted Journey" | https://incompetech.com/music/royalty-free/music.html (buscar "Enchanted Journey") |
| gacha_theme.mp3 | "Mystical Theme" | https://incompetech.com/music/royalty-free/music.html (buscar "Mystical") |

## ⚠️ Importante

- Los archivos DEBEN llamarse exactamente como se indica
- Formato: MP3 u OGG
- Si no pones música, el juego funcionará igual pero sin sonido
- La música es opcional pero mejora mucho la experiencia

## 🔧 Solución de Problemas

**"No suena la música":**
1. Verifica que los archivos estén en `assets/audio/music/`
2. Verifica que los nombres sean exactos (con extensión .mp3)
3. Reinicia Godot para que reimporte los archivos

**"Error al cargar música":**
- Asegúrate de que los archivos MP3 no estén corruptos
- Intenta con archivos OGG en su lugar

## 📝 Atribución (Si usas Incompetech)

Si publicas el juego, incluye en los créditos:
```
Music by Kevin MacLeod (incompetech.com)
Licensed under Creative Commons: By Attribution 4.0 License
http://creativecommons.org/licenses/by/4.0/
```
