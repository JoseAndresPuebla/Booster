# Booster TCG 🎴

> **Apertura de sobres diarios y coleccionismo multijuego al estilo Pokémon TCG Pocket.**
> Totalmente gratuito, independiente y con soporte para **Pokémon**, **Magic: The Gathering**, **Riftbound** y **One Piece TCG**.

---

## 🌟 Características Principales

- 📦 **Apertura interactiva de sobres:**
  - Desliza el dedo por la parte superior del sobre metálico para rasgar el envoltorio con respuesta háptica (vibración).
  - Efectos 3D de volteo e inclinación (*tilt*) de cartas con reflejo de luz.
  - Efectos holográficos/foil iridiscentes dinámicos calculados según el ángulo de visión.
- ⏳ **Límite diario gratuito:**
  - 2 sobres gratuitos al día por cada juego de cartas con contador de tiempo de recarga en tiempo real.
- 🗂️ **Álbum y colección:**
  - Estructura de carpetas virtual para coleccionar y organizar cartas.
  - Filtrado por rareza (*Común, Infrecuente, Rara, Ultra Rara, Secreta*) y buscador por nombre.
  - Contadores de duplicados (`x2`, `x3`, etc.).
- 🚀 **Actualizaciones automáticas vía GitHub:**
  - La app consulta la API de GitHub Releases al iniciar.
  - Si hay una nueva versión del `.apk`, avisa al usuario para actualizar con un solo clic.
- ☁️ **Modo Sin Contraseña & Sincronización Supabase:**
  - Acceso instantáneo con apodo/nickname (sin contraseñas ni correos obligatorios).
  - Guarda la colección en local (0 ms de carga) y sincroniza con Supabase en la nube.

---

## 🃏 Juegos y Fuentes de Cartas Soportadas

1. **Pokémon TCG:** Consumo mediante la API pública de *TcgDex* (Expansiones como *Pokémon 151*, *Surging Sparks*, *Crown Zenith*, *Base Set*).
2. **Magic: The Gathering:** Integración con la API de *Scryfall* (*Bloomburrow*, *Modern Horizons 3*, *Outlaws of Thunder Junction*, *Kamigawa*).
3. **Riftbound TCG:** El nuevo TCG de Riot Games basado en Runaterra (*Origins*, *Spiritforged*, *Radiance* con campeones como Yasuo, Jinx, Viktor, Ahri y Darius).
4. **One Piece TCG:** Base de datos con las expansiones más populares (*OP-05 Awakening of the New Era*, *OP-01 Romance Dawn*, *OP-07*).

---

## 🛠️ Configuración de Supabase

En tu panel de [Supabase](https://supabase.com):
1. Ve al **SQL Editor**.
2. Pega y ejecuta el contenido del archivo [`supabase/schema.sql`](supabase/schema.sql).
3. ¡Listo! La base de datos creará las tablas `profiles`, `user_collection` y `daily_pack_timers`.

---

## 📱 Compilación del APK

### Compilación Local en Android
```bash
flutter build apk --release
```
El archivo `.apk` se generará en: `build/app/outputs/flutter-apk/app-release.apk`.

### Compilación Automática en GitHub (CI/CD)
El proyecto incluye un flujo de trabajo en `.github/workflows/build-apk.yml`. Cada vez que crees y subas una etiqueta (tag), por ejemplo:
```bash
git tag v1.0.0
git push origin v1.0.0
```
GitHub Actions compilará automáticamente el APK y lo publicará en la sección de **Releases** de tu repositorio.
