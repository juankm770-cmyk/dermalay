import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const cities = ['Bogotá', 'Medellín', 'Cali', 'Barranquilla', 'Bucaramanga', 'Cartagena'];
const specialties: [string, string][] = [
  ['Caída del cabello', 'hair'], ['Acné', 'acne'], ['Manchas', 'spots'],
  ['Dermatología estética', 'aesthetic'], ['Dermatología pediátrica', 'kids'], ['Cáncer de piel', 'oncology'],
];
const slug = (s: string) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

async function main() {
  for (const name of cities) {
    await prisma.city.upsert({ where: { slug: slug(name) }, update: {}, create: { name, slug: slug(name) } });
  }
  for (const [name, icon] of specialties) {
    await prisma.specialty.upsert({ where: { slug: slug(name) }, update: {}, create: { name, slug: slug(name), icon } });
  }
}
main().finally(() => prisma.$disconnect());
