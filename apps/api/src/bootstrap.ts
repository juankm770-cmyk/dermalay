import { Logger } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from './prisma/prisma.service';

const CITIES = ['Bogotá', 'Medellín', 'Cali', 'Barranquilla', 'Bucaramanga', 'Cartagena'];
const SPECIALTIES: [string, string][] = [
  ['Caída del cabello', 'hair'],
  ['Acné', 'acne'],
  ['Manchas', 'spots'],
  ['Dermatología estética', 'aesthetic'],
  ['Dermatología pediátrica', 'kids'],
  ['Cáncer de piel', 'oncology'],
];

const slug = (s: string) =>
  s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

/** Idempotente: se ejecuta en cada arranque. Carga catálogo y garantiza el usuario administrador. */
export async function seedAndAdmin(prisma: PrismaService) {
  const log = new Logger('Bootstrap');
  for (const name of CITIES) {
    await prisma.city.upsert({ where: { slug: slug(name) }, update: {}, create: { name, slug: slug(name) } });
  }
  for (const [name, icon] of SPECIALTIES) {
    await prisma.specialty.upsert({ where: { slug: slug(name) }, update: {}, create: { name, slug: slug(name), icon } });
  }

  const email = process.env.ADMIN_EMAIL?.toLowerCase();
  const password = process.env.ADMIN_PASSWORD;
  if (!email || !password) return;
  const existing = await prisma.user.findUnique({ where: { email } });
  if (!existing) {
    await prisma.user.create({
      data: { email, role: 'ADMIN', fullName: 'Administrador', passwordHash: await bcrypt.hash(password, 12) },
    });
    log.log(`Usuario administrador creado: ${email}`);
  } else if (existing.role !== 'ADMIN') {
    await prisma.user.update({ where: { id: existing.id }, data: { role: 'ADMIN' } });
    log.log(`Usuario ${email} promovido a administrador`);
  }
}
