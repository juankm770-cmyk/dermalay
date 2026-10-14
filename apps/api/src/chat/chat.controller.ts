import { Body, Controller, ForbiddenException, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { AuthGuard, AuthUser } from '../common/auth.guard';
import { PrismaService } from '../prisma/prisma.service';

class SendDto {
  @IsString() @MinLength(1) @MaxLength(2000) body!: string;
}

type Req_ = { user: AuthUser };

/** MVP: chat por REST (polling). Se migra a WebSocket más adelante. */
@Controller('chat')
@UseGuards(AuthGuard)
export class ChatController {
  constructor(private prisma: PrismaService) {}

  @Post('doctors/:doctorId')
  open(@Req() req: Req_, @Param('doctorId') doctorId: string) {
    return this.prisma.conversation.upsert({
      where: { patientId_doctorId: { patientId: req.user.sub, doctorId } },
      update: {}, create: { patientId: req.user.sub, doctorId },
    });
  }

  @Get('conversations')
  mine(@Req() req: Req_) {
    return this.prisma.conversation.findMany({
      where: { patientId: req.user.sub },
      include: { doctor: { select: { fullName: true, photoUrl: true, slug: true } }, messages: { orderBy: { createdAt: 'desc' }, take: 1 } },
    });
  }

  private async own(userId: string, id: string) {
    const c = await this.prisma.conversation.findUnique({ where: { id } });
    if (!c || c.patientId !== userId) throw new ForbiddenException();
  }

  @Get('conversations/:id/messages')
  async messages(@Req() req: Req_, @Param('id') id: string) {
    await this.own(req.user.sub, id);
    return this.prisma.message.findMany({ where: { conversationId: id }, orderBy: { createdAt: 'asc' }, take: 200 });
  }

  @Post('conversations/:id/messages')
  async send(@Req() req: Req_, @Param('id') id: string, @Body() dto: SendDto) {
    await this.own(req.user.sub, id);
    return this.prisma.message.create({ data: { conversationId: id, senderId: req.user.sub, body: dto.body } });
  }
}
