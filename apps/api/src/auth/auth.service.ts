import { Injectable, ServiceUnavailableException, UnauthorizedException, ConflictException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { App, cert, initializeApp } from 'firebase-admin/app';
import { DecodedIdToken, getAuth } from 'firebase-admin/auth';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseLoginDto, LoginDto, RegisterDto } from './auth.dto';

@Injectable()
export class AuthService {
  private firebase?: App;

  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    config: ConfigService,
  ) {
    const b64 = config.get<string>('FIREBASE_SERVICE_ACCOUNT_B64');
    if (b64) {
      const cred = JSON.parse(Buffer.from(b64, 'base64').toString('utf8'));
      this.firebase = initializeApp({ credential: cert(cred) });
    }
  }

  private async token(user: { id: string; role: string }) {
    return { accessToken: await this.jwt.signAsync({ sub: user.id, role: user.role }) };
  }

  async register(dto: RegisterDto) {
    const email = dto.email.toLowerCase();
    if (await this.prisma.user.findUnique({ where: { email } })) {
      throw new ConflictException('El correo ya está registrado');
    }
    const user = await this.prisma.user.create({
      data: { email, fullName: dto.fullName, passwordHash: await bcrypt.hash(dto.password, 12) },
    });
    return this.token(user);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email.toLowerCase() } });
    const ok = user?.passwordHash && (await bcrypt.compare(dto.password, user.passwordHash));
    if (!user || !ok || user.deletedAt) throw new UnauthorizedException('Credenciales inválidas');
    return this.token(user);
  }

  /** Login con Google / teléfono: la app obtiene un idToken de Firebase y lo cambia por nuestro JWT. */
  async firebaseLogin(dto: FirebaseLoginDto) {
    if (!this.firebase) throw new ServiceUnavailableException('Firebase no configurado');
    let decoded: DecodedIdToken;
    try {
      decoded = await getAuth(this.firebase).verifyIdToken(dto.idToken);
    } catch {
      throw new UnauthorizedException();
    }
    const user = await this.prisma.user.upsert({
      where: { firebaseUid: decoded.uid },
      update: {},
      create: {
        firebaseUid: decoded.uid,
        email: decoded.email?.toLowerCase(),
        phone: decoded.phone_number,
        fullName: decoded.name ?? 'Paciente',
      },
    });
    return this.token(user);
  }

  /** Borrado de cuenta (requisito de Google Play). */
  async deleteAccount(userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { deletedAt: new Date(), email: null, phone: null, firebaseUid: null, passwordHash: null, fullName: 'Usuario eliminado' },
    });
  }
}
