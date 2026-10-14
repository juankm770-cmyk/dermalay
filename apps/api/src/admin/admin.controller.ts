import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty, IsArray, IsDateString, IsEnum, IsInt, IsOptional, IsString, IsUrl, Min, MinLength, ValidateNested,
} from 'class-validator';
import { AuthGuard, Roles } from '../common/auth.guard';
import { PrismaService } from '../prisma/prisma.service';

class DoctorDto {
  @IsString() @MinLength(2) fullName!: string;
  @IsString() @MinLength(2) slug!: string;
  @IsString() bio!: string;
  @IsOptional() @IsUrl() photoUrl?: string;
  @IsOptional() @IsUrl() videoUrl?: string;
  @IsString() cityId!: string;
  @IsInt() @Min(0) consultationFee!: number;
  @IsOptional() @IsString() registroMedico?: string;
  @IsOptional() @IsEnum(['DRAFT', 'PUBLISHED', 'HIDDEN']) status?: 'DRAFT' | 'PUBLISHED' | 'HIDDEN';
  @IsArray() @ArrayNotEmpty() @IsString({ each: true }) specialtyIds!: string[];
}

class SlotDto {
  @IsDateString() startsAt!: string;
  @IsDateString() endsAt!: string;
}
class SlotsDto {
  @IsArray() @ValidateNested({ each: true }) @Type(() => SlotDto) slots!: SlotDto[];
}

@Controller('admin')
@UseGuards(AuthGuard)
@Roles('ADMIN')
export class AdminController {
  constructor(private prisma: PrismaService) {}

  @Get('doctors') list() {
    return this.prisma.doctor.findMany({ include: { city: true, specialties: { include: { specialty: true } } }, orderBy: { createdAt: 'desc' } });
  }

  @Post('doctors') create(@Body() { specialtyIds, ...d }: DoctorDto) {
    return this.prisma.doctor.create({ data: { ...d, specialties: { create: specialtyIds.map((specialtyId) => ({ specialtyId })) } } });
  }

  @Patch('doctors/:id') async update(@Param('id') id: string, @Body() { specialtyIds, ...d }: Partial<DoctorDto>) {
    return this.prisma.doctor.update({
      where: { id },
      data: {
        ...d,
        ...(specialtyIds && { specialties: { deleteMany: {}, create: specialtyIds.map((specialtyId) => ({ specialtyId })) } }),
      },
    });
  }

  @Delete('doctors/:id') remove(@Param('id') id: string) { return this.prisma.doctor.delete({ where: { id } }); }

  @Post('doctors/:id/slots') addSlots(@Param('id') id: string, @Body() dto: SlotsDto) {
    return this.prisma.availabilitySlot.createMany({
      data: dto.slots.map((s) => ({ doctorId: id, startsAt: new Date(s.startsAt), endsAt: new Date(s.endsAt) })),
    });
  }
}
