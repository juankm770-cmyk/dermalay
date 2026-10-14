import { Body, Controller, Delete, HttpCode, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthGuard } from '../common/auth.guard';
import { ChangePasswordDto, FirebaseLoginDto, LoginDto, RegisterDto } from './auth.dto';
import { AuthService } from './auth.service';

@Controller('auth')
@Throttle({ default: { limit: 10, ttl: 60_000 } })
export class AuthController {
  constructor(private auth: AuthService) {}

  @Post('register') register(@Body() dto: RegisterDto) { return this.auth.register(dto); }
  @Post('login') @HttpCode(200) login(@Body() dto: LoginDto) { return this.auth.login(dto); }
  @Post('firebase') @HttpCode(200) firebase(@Body() dto: FirebaseLoginDto) { return this.auth.firebaseLogin(dto); }

  @Patch('password') @UseGuards(AuthGuard) @HttpCode(204)
  async password(@Req() req: { user: { sub: string } }, @Body() dto: ChangePasswordDto) { await this.auth.changePassword(req.user.sub, dto); }

  @Delete('account') @UseGuards(AuthGuard) @HttpCode(204)
  async remove(@Req() req: { user: { sub: string } }) { await this.auth.deleteAccount(req.user.sub); }
}
