# Lo que tienes que hacer tú (paso a paso)

Tiempo total aproximado: **1 hora** para lo imprescindible ahora (pasos 1-3) y **40 min** extra para el login con Google/teléfono (paso 4). Play Console (paso 5) puede esperar.

---

## 1. Crear el repositorio en GitHub — 3 minutos
1. Entra a https://github.com/new (con tu cuenta `juankm770-cmyk`).
2. **Repository name:** `dermalay`
3. Marca **Private**.
4. **No** marques "Add a README", ni ".gitignore", ni licencia (debe quedar vacío).
5. Pulsa el botón verde **Create repository**.
6. Dile a Claude: "ya creé el repo". Él lo conecta y sube todo.

## 2. Base de datos en Railway — 10 minutos
La base de datos que ya tienes pertenece al bot (proyecto `zestful-appreciation`). Para Dermalay conviene una **separada**, porque tendrá datos personales de pacientes.
1. Entra a https://railway.com/dashboard e inicia sesión.
2. Pulsa **New Project** → **Deploy PostgreSQL**. Ponle de nombre `dermalay`.
3. (Alternativa: dile a Claude "créala tú" y la crea con su acceso a Railway. Te cobrará Railway igual que cualquier base de datos.)

## 3. Subir el backend a Railway — 15 minutos
1. En el proyecto `dermalay` de Railway: **New** → **GitHub Repo** → elige `dermalay`. Si no sale, pulsa **Configure GitHub App** y dale permiso a ese repo.
2. Entra al servicio nuevo → **Settings**:
   - **Root Directory:** `apps/api`
   - **Build Command:** `npm ci && npx prisma generate && npm run build`
   - **Start Command:** `npx prisma migrate deploy && node dist/main`
3. Pestaña **Variables** → **New Variable**, una por una:
   - `DATABASE_URL` → pulsa **Add Reference** y elige la variable `DATABASE_URL` del servicio Postgres.
   - `JWT_SECRET` → una clave larga y aleatoria. Genérala en https://www.random.org/strings/ (64 caracteres) o pídele a Claude una. Guárdala tú en un lugar seguro.
   - `JWT_EXPIRES_IN` → `7d`
   - `CORS_ORIGINS` → déjalo vacío por ahora.
4. Pestaña **Settings** → **Networking** → **Generate Domain**. Esa es la dirección de tu API.
5. Dile a Claude la dirección. Él prueba que responde, carga ciudades y especialidades y te crea el usuario administrador.

## 4. Login con Google y teléfono (Firebase) — 40 minutos
1. Entra a https://console.firebase.google.com con tu cuenta de Google.
2. **Crear un proyecto** → nombre `dermalay` → puedes desactivar Google Analytics.
3. Menú izquierdo **Build → Authentication** → **Comenzar** → pestaña **Método de acceso**:
   - Activa **Google**.
   - Activa **Teléfono**. (Firebase da SMS de prueba gratis, pero para producción pide activar facturación: el plan Blaze. Los primeros SMS del mes son gratis según la región; revisa el precio de Colombia antes de lanzar.)
4. Pulsa el engranaje ⚙️ → **Configuración del proyecto** → pestaña **Cuentas de servicio** → **Generar nueva clave privada**. Se descarga un archivo `.json`. **No lo subas a GitHub ni lo pegues en el chat.**
5. Convierte ese archivo a una sola línea de texto (base64):
   - En Windows (PowerShell): `[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\ruta\al\archivo.json"))`
   - En Mac/Linux: `base64 -w0 archivo.json`
6. En Railway, servicio `dermalay` → Variables → crea `FIREBASE_SERVICE_ACCOUNT_B64` con ese texto.
7. En Firebase → engranaje → **General** → **Agregar app** → Android. Paquete: `co.dermalay.app`. Descarga `google-services.json` y guárdalo (me lo pasarás cuando lleguemos a la app; es un archivo de configuración, no es secreto crítico, pero no lo publiques en un repo público).

## 5. Google Play Console — 20 minutos + 1-3 días de verificación (NO urgente)
1. https://play.google.com/console/signup
2. Cuenta de **persona** u **organización** (con organización necesitas el número D-U-N-S si es empresa; es más largo).
3. Pago único de **25 US$**.
4. Verificación de identidad: documento y a veces video. Tarda de 1 a 3 días.
5. Las cuentas personales nuevas deben hacer una **prueba cerrada con 12 testers durante 14 días** antes de poder publicar. Planéalo con tiempo.

## 6. Más adelante (no ahora)
- Cuenta de Apple Developer (99 US$/año) para iOS.
- Servicio de video (Mux o Cloudflare Stream) para los videos de los doctores.
- Clave de Google Maps para mostrar consultorios.
