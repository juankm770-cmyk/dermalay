import { Controller, Get, NotFoundException, Param, Query } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Transform } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';

class ListDoctorsQuery {
  @IsOptional() @IsString() city?: string; // slug
  @IsOptional() @IsString() specialty?: string; // slug
  @IsOptional() @Transform(({ value }) => Number(value)) @IsInt() @Min(1) page = 1;
  @IsOptional() @Transform(({ value }) => Number(value)) @IsInt() @Min(1) @Max(50) pageSize = 20;
}

const listSelect = {
  id: true, fullName: true, slug: true, photoUrl: true, consultationFee: true,
  ratingAvg: true, ratingCount: true, bio: true,
  city: { select: { name: true, slug: true } },
  specialties: { select: { specialty: { select: { name: true, slug: true, icon: true } } } },
} satisfies Prisma.DoctorSelect;

@Controller('doctors')
export class DoctorsController {
  constructor(private prisma: PrismaService) {}

  @Get()
  async list(@Query() q: ListDoctorsQuery) {
    const where: Prisma.DoctorWhereInput = {
      status: 'PUBLISHED',
      ...(q.city && { city: { slug: q.city } }),
      ...(q.specialty && { specialties: { some: { specialty: { slug: q.specialty } } } }),
    };
    const [total, items] = await Promise.all([
      this.prisma.doctor.count({ where }),
      this.prisma.doctor.findMany({
        where, select: listSelect,
        orderBy: [{ ratingAvg: 'desc' }, { ratingCount: 'desc' }],
        skip: (q.page - 1) * q.pageSize, take: q.pageSize,
      }),
    ]);
    return { total, page: q.page, pageSize: q.pageSize, items };
  }

  @Get(':slug')
  async detail(@Param('slug') slug: string) {
    const doctor = await this.prisma.doctor.findFirst({
      where: { slug, status: 'PUBLISHED' },
      select: {
        ...listSelect, videoUrl: true,
        slots: {
          where: { booked: false, startsAt: { gt: new Date() } },
          orderBy: { startsAt: 'asc' }, take: 30,
          select: { id: true, startsAt: true, endsAt: true },
        },
      },
    });
    if (!doctor) throw new NotFoundException();
    return doctor;
  }
}
