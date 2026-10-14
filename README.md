# Dermalay

Directorio de dermatólogos de Colombia. Monorepo:

- `apps/api` — backend NestJS + Prisma + PostgreSQL (Railway)
- `apps/mobile` — app Flutter (Android primero, iOS después) *(pendiente)*
- `docs/` — decisiones de arquitectura

## API: arrancar en local

```bash
cd apps/api
cp .env.example .env      # rellenar DATABASE_URL (Postgres de Railway) y JWT_SECRET
npm install
npx prisma migrate dev    # crea las tablas
npm run db:seed           # ciudades y especialidades
npm run start:dev         # http://localhost:3000/v1  (docs en /docs)
```

## Seguridad (decisiones)
- Contraseñas con bcrypt (coste 12); JWT firmado; guard por rol (`ADMIN` para el panel).
- Validación estricta de entradas (`whitelist` + `forbidNonWhitelisted`), `helmet`, CORS por lista, rate limit global y más estricto en `/auth`.
- Login con Google/teléfono verificando el idToken de Firebase en el servidor.
- Borrado de cuenta (`DELETE /v1/auth/account`) por requisito de Google Play.
- Secretos solo por variables de entorno, nunca en el repo.

## Pendiente (siguientes pasos)
Refresh tokens, chat en tiempo real (WebSocket), reservar slots, reseñas, app Flutter, panel web de admin, CI.
