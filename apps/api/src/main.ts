import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { seedAndAdmin } from './bootstrap';
import { PrismaService } from './prisma/prisma.service';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(helmet());
  app.enableCors({ origin: (process.env.CORS_ORIGINS ?? '').split(',').filter(Boolean) });
  app.setGlobalPrefix('v1');
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
  if (process.env.NODE_ENV !== 'production') {
    SwaggerModule.setup('docs', app, SwaggerModule.createDocument(app, new DocumentBuilder().setTitle('Dermalay API').build()));
  }
  await seedAndAdmin(app.get(PrismaService));
  await app.listen(process.env.PORT ?? 3000, '0.0.0.0');
}
void bootstrap();
