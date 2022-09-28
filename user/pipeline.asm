
user/_pipeline:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char const *argv[])
{
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	0080                	addi	s0,sp,64
    if(argc < 3){
   e:	4789                	li	a5,2
  10:	02a7c063          	blt	a5,a0,30 <main+0x30>
        printf("Too few arguments. Expected 3 got %d.\n", argc);
  14:	85aa                	mv	a1,a0
  16:	00001517          	auipc	a0,0x1
  1a:	90a50513          	addi	a0,a0,-1782 # 920 <malloc+0xe6>
  1e:	00000097          	auipc	ra,0x0
  22:	764080e7          	jalr	1892(ra) # 782 <printf>
        exit(0);
  26:	4501                	li	a0,0
  28:	00000097          	auipc	ra,0x0
  2c:	3c0080e7          	jalr	960(ra) # 3e8 <exit>
  30:	84ae                	mv	s1,a1
    }
    int n, x, k;
    n = atoi(argv[1]);
  32:	6588                	ld	a0,8(a1)
  34:	00000097          	auipc	ra,0x0
  38:	2ba080e7          	jalr	698(ra) # 2ee <atoi>
  3c:	892a                	mv	s2,a0
    x = atoi(argv[2]);
  3e:	6888                	ld	a0,16(s1)
  40:	00000097          	auipc	ra,0x0
  44:	2ae080e7          	jalr	686(ra) # 2ee <atoi>
  48:	84aa                	mv	s1,a0
    
    if(n <= 0){
  4a:	0d205963          	blez	s2,11c <main+0x11c>
        printf("First argument expected positive.\n");
        exit(0);
    }

    int fd[2];
    if(pipe(fd) < 0){
  4e:	fc840513          	addi	a0,s0,-56
  52:	00000097          	auipc	ra,0x0
  56:	3a6080e7          	jalr	934(ra) # 3f8 <pipe>
  5a:	0c054e63          	bltz	a0,136 <main+0x136>
        exit(0);
    }
    int y, z;
    k = n;
    k--;
    y = getpid() + x;
  5e:	00000097          	auipc	ra,0x0
  62:	40a080e7          	jalr	1034(ra) # 468 <getpid>
  66:	9d25                	addw	a0,a0,s1
  68:	fca42223          	sw	a0,-60(s0)
    printf("%d: %d\n", getpid(), y);
  6c:	00000097          	auipc	ra,0x0
  70:	3fc080e7          	jalr	1020(ra) # 468 <getpid>
  74:	85aa                	mv	a1,a0
  76:	fc442603          	lw	a2,-60(s0)
  7a:	00001517          	auipc	a0,0x1
  7e:	91e50513          	addi	a0,a0,-1762 # 998 <malloc+0x15e>
  82:	00000097          	auipc	ra,0x0
  86:	700080e7          	jalr	1792(ra) # 782 <printf>
    write(fd[1], &y, 1);
  8a:	4605                	li	a2,1
  8c:	fc440593          	addi	a1,s0,-60
  90:	fcc42503          	lw	a0,-52(s0)
  94:	00000097          	auipc	ra,0x0
  98:	374080e7          	jalr	884(ra) # 408 <write>
    while(k--){
  9c:	4785                	li	a5,1
  9e:	06f90a63          	beq	s2,a5,112 <main+0x112>
  a2:	397d                	addiw	s2,s2,-1
  a4:	1902                	slli	s2,s2,0x20
  a6:	02095913          	srli	s2,s2,0x20
  aa:	4481                	li	s1,0
        if(fork() == 0){
            read(fd[0], &z, 8);
            y = z + getpid();
            printf("%d: %d\n", getpid(), y);
  ac:	00001997          	auipc	s3,0x1
  b0:	8ec98993          	addi	s3,s3,-1812 # 998 <malloc+0x15e>
        if(fork() == 0){
  b4:	00000097          	auipc	ra,0x0
  b8:	32c080e7          	jalr	812(ra) # 3e0 <fork>
  bc:	e951                	bnez	a0,150 <main+0x150>
            read(fd[0], &z, 8);
  be:	4621                	li	a2,8
  c0:	fc040593          	addi	a1,s0,-64
  c4:	fc842503          	lw	a0,-56(s0)
  c8:	00000097          	auipc	ra,0x0
  cc:	338080e7          	jalr	824(ra) # 400 <read>
            y = z + getpid();
  d0:	00000097          	auipc	ra,0x0
  d4:	398080e7          	jalr	920(ra) # 468 <getpid>
  d8:	fc042783          	lw	a5,-64(s0)
  dc:	9fa9                	addw	a5,a5,a0
  de:	fcf42223          	sw	a5,-60(s0)
            printf("%d: %d\n", getpid(), y);
  e2:	00000097          	auipc	ra,0x0
  e6:	386080e7          	jalr	902(ra) # 468 <getpid>
  ea:	85aa                	mv	a1,a0
  ec:	fc442603          	lw	a2,-60(s0)
  f0:	854e                	mv	a0,s3
  f2:	00000097          	auipc	ra,0x0
  f6:	690080e7          	jalr	1680(ra) # 782 <printf>
            write(fd[1], &y, 8);
  fa:	4621                	li	a2,8
  fc:	fc440593          	addi	a1,s0,-60
 100:	fcc42503          	lw	a0,-52(s0)
 104:	00000097          	auipc	ra,0x0
 108:	304080e7          	jalr	772(ra) # 408 <write>
    while(k--){
 10c:	0485                	addi	s1,s1,1
 10e:	fb2493e3          	bne	s1,s2,b4 <main+0xb4>
            close(fd[1]);
            exit(0);
        }
    }
    
    exit(0);
 112:	4501                	li	a0,0
 114:	00000097          	auipc	ra,0x0
 118:	2d4080e7          	jalr	724(ra) # 3e8 <exit>
        printf("First argument expected positive.\n");
 11c:	00001517          	auipc	a0,0x1
 120:	82c50513          	addi	a0,a0,-2004 # 948 <malloc+0x10e>
 124:	00000097          	auipc	ra,0x0
 128:	65e080e7          	jalr	1630(ra) # 782 <printf>
        exit(0);
 12c:	4501                	li	a0,0
 12e:	00000097          	auipc	ra,0x0
 132:	2ba080e7          	jalr	698(ra) # 3e8 <exit>
        printf("Error: cannot create pipe. Aborting \n");
 136:	00001517          	auipc	a0,0x1
 13a:	83a50513          	addi	a0,a0,-1990 # 970 <malloc+0x136>
 13e:	00000097          	auipc	ra,0x0
 142:	644080e7          	jalr	1604(ra) # 782 <printf>
        exit(0);
 146:	4501                	li	a0,0
 148:	00000097          	auipc	ra,0x0
 14c:	2a0080e7          	jalr	672(ra) # 3e8 <exit>
            wait(0);
 150:	4501                	li	a0,0
 152:	00000097          	auipc	ra,0x0
 156:	29e080e7          	jalr	670(ra) # 3f0 <wait>
            close(fd[0]);
 15a:	fc842503          	lw	a0,-56(s0)
 15e:	00000097          	auipc	ra,0x0
 162:	2b2080e7          	jalr	690(ra) # 410 <close>
            close(fd[1]);
 166:	fcc42503          	lw	a0,-52(s0)
 16a:	00000097          	auipc	ra,0x0
 16e:	2a6080e7          	jalr	678(ra) # 410 <close>
            exit(0);
 172:	4501                	li	a0,0
 174:	00000097          	auipc	ra,0x0
 178:	274080e7          	jalr	628(ra) # 3e8 <exit>

000000000000017c <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 17c:	1141                	addi	sp,sp,-16
 17e:	e422                	sd	s0,8(sp)
 180:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 182:	87aa                	mv	a5,a0
 184:	0585                	addi	a1,a1,1
 186:	0785                	addi	a5,a5,1
 188:	fff5c703          	lbu	a4,-1(a1)
 18c:	fee78fa3          	sb	a4,-1(a5)
 190:	fb75                	bnez	a4,184 <strcpy+0x8>
    ;
  return os;
}
 192:	6422                	ld	s0,8(sp)
 194:	0141                	addi	sp,sp,16
 196:	8082                	ret

0000000000000198 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 198:	1141                	addi	sp,sp,-16
 19a:	e422                	sd	s0,8(sp)
 19c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 19e:	00054783          	lbu	a5,0(a0)
 1a2:	cb91                	beqz	a5,1b6 <strcmp+0x1e>
 1a4:	0005c703          	lbu	a4,0(a1)
 1a8:	00f71763          	bne	a4,a5,1b6 <strcmp+0x1e>
    p++, q++;
 1ac:	0505                	addi	a0,a0,1
 1ae:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1b0:	00054783          	lbu	a5,0(a0)
 1b4:	fbe5                	bnez	a5,1a4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1b6:	0005c503          	lbu	a0,0(a1)
}
 1ba:	40a7853b          	subw	a0,a5,a0
 1be:	6422                	ld	s0,8(sp)
 1c0:	0141                	addi	sp,sp,16
 1c2:	8082                	ret

00000000000001c4 <strlen>:

uint
strlen(const char *s)
{
 1c4:	1141                	addi	sp,sp,-16
 1c6:	e422                	sd	s0,8(sp)
 1c8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1ca:	00054783          	lbu	a5,0(a0)
 1ce:	cf91                	beqz	a5,1ea <strlen+0x26>
 1d0:	0505                	addi	a0,a0,1
 1d2:	87aa                	mv	a5,a0
 1d4:	4685                	li	a3,1
 1d6:	9e89                	subw	a3,a3,a0
 1d8:	00f6853b          	addw	a0,a3,a5
 1dc:	0785                	addi	a5,a5,1
 1de:	fff7c703          	lbu	a4,-1(a5)
 1e2:	fb7d                	bnez	a4,1d8 <strlen+0x14>
    ;
  return n;
}
 1e4:	6422                	ld	s0,8(sp)
 1e6:	0141                	addi	sp,sp,16
 1e8:	8082                	ret
  for(n = 0; s[n]; n++)
 1ea:	4501                	li	a0,0
 1ec:	bfe5                	j	1e4 <strlen+0x20>

00000000000001ee <memset>:

void*
memset(void *dst, int c, uint n)
{
 1ee:	1141                	addi	sp,sp,-16
 1f0:	e422                	sd	s0,8(sp)
 1f2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1f4:	ca19                	beqz	a2,20a <memset+0x1c>
 1f6:	87aa                	mv	a5,a0
 1f8:	1602                	slli	a2,a2,0x20
 1fa:	9201                	srli	a2,a2,0x20
 1fc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 200:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 204:	0785                	addi	a5,a5,1
 206:	fee79de3          	bne	a5,a4,200 <memset+0x12>
  }
  return dst;
}
 20a:	6422                	ld	s0,8(sp)
 20c:	0141                	addi	sp,sp,16
 20e:	8082                	ret

0000000000000210 <strchr>:

char*
strchr(const char *s, char c)
{
 210:	1141                	addi	sp,sp,-16
 212:	e422                	sd	s0,8(sp)
 214:	0800                	addi	s0,sp,16
  for(; *s; s++)
 216:	00054783          	lbu	a5,0(a0)
 21a:	cb99                	beqz	a5,230 <strchr+0x20>
    if(*s == c)
 21c:	00f58763          	beq	a1,a5,22a <strchr+0x1a>
  for(; *s; s++)
 220:	0505                	addi	a0,a0,1
 222:	00054783          	lbu	a5,0(a0)
 226:	fbfd                	bnez	a5,21c <strchr+0xc>
      return (char*)s;
  return 0;
 228:	4501                	li	a0,0
}
 22a:	6422                	ld	s0,8(sp)
 22c:	0141                	addi	sp,sp,16
 22e:	8082                	ret
  return 0;
 230:	4501                	li	a0,0
 232:	bfe5                	j	22a <strchr+0x1a>

0000000000000234 <gets>:

char*
gets(char *buf, int max)
{
 234:	711d                	addi	sp,sp,-96
 236:	ec86                	sd	ra,88(sp)
 238:	e8a2                	sd	s0,80(sp)
 23a:	e4a6                	sd	s1,72(sp)
 23c:	e0ca                	sd	s2,64(sp)
 23e:	fc4e                	sd	s3,56(sp)
 240:	f852                	sd	s4,48(sp)
 242:	f456                	sd	s5,40(sp)
 244:	f05a                	sd	s6,32(sp)
 246:	ec5e                	sd	s7,24(sp)
 248:	1080                	addi	s0,sp,96
 24a:	8baa                	mv	s7,a0
 24c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 24e:	892a                	mv	s2,a0
 250:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 252:	4aa9                	li	s5,10
 254:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 256:	89a6                	mv	s3,s1
 258:	2485                	addiw	s1,s1,1
 25a:	0344d863          	bge	s1,s4,28a <gets+0x56>
    cc = read(0, &c, 1);
 25e:	4605                	li	a2,1
 260:	faf40593          	addi	a1,s0,-81
 264:	4501                	li	a0,0
 266:	00000097          	auipc	ra,0x0
 26a:	19a080e7          	jalr	410(ra) # 400 <read>
    if(cc < 1)
 26e:	00a05e63          	blez	a0,28a <gets+0x56>
    buf[i++] = c;
 272:	faf44783          	lbu	a5,-81(s0)
 276:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 27a:	01578763          	beq	a5,s5,288 <gets+0x54>
 27e:	0905                	addi	s2,s2,1
 280:	fd679be3          	bne	a5,s6,256 <gets+0x22>
  for(i=0; i+1 < max; ){
 284:	89a6                	mv	s3,s1
 286:	a011                	j	28a <gets+0x56>
 288:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 28a:	99de                	add	s3,s3,s7
 28c:	00098023          	sb	zero,0(s3)
  return buf;
}
 290:	855e                	mv	a0,s7
 292:	60e6                	ld	ra,88(sp)
 294:	6446                	ld	s0,80(sp)
 296:	64a6                	ld	s1,72(sp)
 298:	6906                	ld	s2,64(sp)
 29a:	79e2                	ld	s3,56(sp)
 29c:	7a42                	ld	s4,48(sp)
 29e:	7aa2                	ld	s5,40(sp)
 2a0:	7b02                	ld	s6,32(sp)
 2a2:	6be2                	ld	s7,24(sp)
 2a4:	6125                	addi	sp,sp,96
 2a6:	8082                	ret

00000000000002a8 <stat>:

int
stat(const char *n, struct stat *st)
{
 2a8:	1101                	addi	sp,sp,-32
 2aa:	ec06                	sd	ra,24(sp)
 2ac:	e822                	sd	s0,16(sp)
 2ae:	e426                	sd	s1,8(sp)
 2b0:	e04a                	sd	s2,0(sp)
 2b2:	1000                	addi	s0,sp,32
 2b4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2b6:	4581                	li	a1,0
 2b8:	00000097          	auipc	ra,0x0
 2bc:	170080e7          	jalr	368(ra) # 428 <open>
  if(fd < 0)
 2c0:	02054563          	bltz	a0,2ea <stat+0x42>
 2c4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2c6:	85ca                	mv	a1,s2
 2c8:	00000097          	auipc	ra,0x0
 2cc:	178080e7          	jalr	376(ra) # 440 <fstat>
 2d0:	892a                	mv	s2,a0
  close(fd);
 2d2:	8526                	mv	a0,s1
 2d4:	00000097          	auipc	ra,0x0
 2d8:	13c080e7          	jalr	316(ra) # 410 <close>
  return r;
}
 2dc:	854a                	mv	a0,s2
 2de:	60e2                	ld	ra,24(sp)
 2e0:	6442                	ld	s0,16(sp)
 2e2:	64a2                	ld	s1,8(sp)
 2e4:	6902                	ld	s2,0(sp)
 2e6:	6105                	addi	sp,sp,32
 2e8:	8082                	ret
    return -1;
 2ea:	597d                	li	s2,-1
 2ec:	bfc5                	j	2dc <stat+0x34>

00000000000002ee <atoi>:

int
atoi(const char *s)
{
 2ee:	1141                	addi	sp,sp,-16
 2f0:	e422                	sd	s0,8(sp)
 2f2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2f4:	00054683          	lbu	a3,0(a0)
 2f8:	fd06879b          	addiw	a5,a3,-48
 2fc:	0ff7f793          	zext.b	a5,a5
 300:	4625                	li	a2,9
 302:	02f66863          	bltu	a2,a5,332 <atoi+0x44>
 306:	872a                	mv	a4,a0
  n = 0;
 308:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 30a:	0705                	addi	a4,a4,1
 30c:	0025179b          	slliw	a5,a0,0x2
 310:	9fa9                	addw	a5,a5,a0
 312:	0017979b          	slliw	a5,a5,0x1
 316:	9fb5                	addw	a5,a5,a3
 318:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 31c:	00074683          	lbu	a3,0(a4)
 320:	fd06879b          	addiw	a5,a3,-48
 324:	0ff7f793          	zext.b	a5,a5
 328:	fef671e3          	bgeu	a2,a5,30a <atoi+0x1c>
  return n;
}
 32c:	6422                	ld	s0,8(sp)
 32e:	0141                	addi	sp,sp,16
 330:	8082                	ret
  n = 0;
 332:	4501                	li	a0,0
 334:	bfe5                	j	32c <atoi+0x3e>

0000000000000336 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 336:	1141                	addi	sp,sp,-16
 338:	e422                	sd	s0,8(sp)
 33a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 33c:	02b57463          	bgeu	a0,a1,364 <memmove+0x2e>
    while(n-- > 0)
 340:	00c05f63          	blez	a2,35e <memmove+0x28>
 344:	1602                	slli	a2,a2,0x20
 346:	9201                	srli	a2,a2,0x20
 348:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 34c:	872a                	mv	a4,a0
      *dst++ = *src++;
 34e:	0585                	addi	a1,a1,1
 350:	0705                	addi	a4,a4,1
 352:	fff5c683          	lbu	a3,-1(a1)
 356:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 35a:	fee79ae3          	bne	a5,a4,34e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 35e:	6422                	ld	s0,8(sp)
 360:	0141                	addi	sp,sp,16
 362:	8082                	ret
    dst += n;
 364:	00c50733          	add	a4,a0,a2
    src += n;
 368:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 36a:	fec05ae3          	blez	a2,35e <memmove+0x28>
 36e:	fff6079b          	addiw	a5,a2,-1
 372:	1782                	slli	a5,a5,0x20
 374:	9381                	srli	a5,a5,0x20
 376:	fff7c793          	not	a5,a5
 37a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 37c:	15fd                	addi	a1,a1,-1
 37e:	177d                	addi	a4,a4,-1
 380:	0005c683          	lbu	a3,0(a1)
 384:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 388:	fee79ae3          	bne	a5,a4,37c <memmove+0x46>
 38c:	bfc9                	j	35e <memmove+0x28>

000000000000038e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 38e:	1141                	addi	sp,sp,-16
 390:	e422                	sd	s0,8(sp)
 392:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 394:	ca05                	beqz	a2,3c4 <memcmp+0x36>
 396:	fff6069b          	addiw	a3,a2,-1
 39a:	1682                	slli	a3,a3,0x20
 39c:	9281                	srli	a3,a3,0x20
 39e:	0685                	addi	a3,a3,1
 3a0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3a2:	00054783          	lbu	a5,0(a0)
 3a6:	0005c703          	lbu	a4,0(a1)
 3aa:	00e79863          	bne	a5,a4,3ba <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3ae:	0505                	addi	a0,a0,1
    p2++;
 3b0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3b2:	fed518e3          	bne	a0,a3,3a2 <memcmp+0x14>
  }
  return 0;
 3b6:	4501                	li	a0,0
 3b8:	a019                	j	3be <memcmp+0x30>
      return *p1 - *p2;
 3ba:	40e7853b          	subw	a0,a5,a4
}
 3be:	6422                	ld	s0,8(sp)
 3c0:	0141                	addi	sp,sp,16
 3c2:	8082                	ret
  return 0;
 3c4:	4501                	li	a0,0
 3c6:	bfe5                	j	3be <memcmp+0x30>

00000000000003c8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3c8:	1141                	addi	sp,sp,-16
 3ca:	e406                	sd	ra,8(sp)
 3cc:	e022                	sd	s0,0(sp)
 3ce:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3d0:	00000097          	auipc	ra,0x0
 3d4:	f66080e7          	jalr	-154(ra) # 336 <memmove>
}
 3d8:	60a2                	ld	ra,8(sp)
 3da:	6402                	ld	s0,0(sp)
 3dc:	0141                	addi	sp,sp,16
 3de:	8082                	ret

00000000000003e0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3e0:	4885                	li	a7,1
 ecall
 3e2:	00000073          	ecall
 ret
 3e6:	8082                	ret

00000000000003e8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 3e8:	4889                	li	a7,2
 ecall
 3ea:	00000073          	ecall
 ret
 3ee:	8082                	ret

00000000000003f0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3f0:	488d                	li	a7,3
 ecall
 3f2:	00000073          	ecall
 ret
 3f6:	8082                	ret

00000000000003f8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3f8:	4891                	li	a7,4
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <read>:
.global read
read:
 li a7, SYS_read
 400:	4895                	li	a7,5
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <write>:
.global write
write:
 li a7, SYS_write
 408:	48c1                	li	a7,16
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <close>:
.global close
close:
 li a7, SYS_close
 410:	48d5                	li	a7,21
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <kill>:
.global kill
kill:
 li a7, SYS_kill
 418:	4899                	li	a7,6
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <exec>:
.global exec
exec:
 li a7, SYS_exec
 420:	489d                	li	a7,7
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <open>:
.global open
open:
 li a7, SYS_open
 428:	48bd                	li	a7,15
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 430:	48c5                	li	a7,17
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 438:	48c9                	li	a7,18
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 440:	48a1                	li	a7,8
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <link>:
.global link
link:
 li a7, SYS_link
 448:	48cd                	li	a7,19
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 450:	48d1                	li	a7,20
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 458:	48a5                	li	a7,9
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <dup>:
.global dup
dup:
 li a7, SYS_dup
 460:	48a9                	li	a7,10
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 468:	48ad                	li	a7,11
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 470:	48b1                	li	a7,12
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 478:	48b5                	li	a7,13
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 480:	48b9                	li	a7,14
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <getppid>:
.global getppid
getppid:
 li a7, SYS_getppid
 488:	48d9                	li	a7,22
 ecall
 48a:	00000073          	ecall
 ret
 48e:	8082                	ret

0000000000000490 <yield>:
.global yield
yield:
 li a7, SYS_yield
 490:	48dd                	li	a7,23
 ecall
 492:	00000073          	ecall
 ret
 496:	8082                	ret

0000000000000498 <getpa>:
.global getpa
getpa:
 li a7, SYS_getpa
 498:	48e1                	li	a7,24
 ecall
 49a:	00000073          	ecall
 ret
 49e:	8082                	ret

00000000000004a0 <waitpid>:
.global waitpid
waitpid:
 li a7, SYS_waitpid
 4a0:	48e5                	li	a7,25
 ecall
 4a2:	00000073          	ecall
 ret
 4a6:	8082                	ret

00000000000004a8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4a8:	1101                	addi	sp,sp,-32
 4aa:	ec06                	sd	ra,24(sp)
 4ac:	e822                	sd	s0,16(sp)
 4ae:	1000                	addi	s0,sp,32
 4b0:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4b4:	4605                	li	a2,1
 4b6:	fef40593          	addi	a1,s0,-17
 4ba:	00000097          	auipc	ra,0x0
 4be:	f4e080e7          	jalr	-178(ra) # 408 <write>
}
 4c2:	60e2                	ld	ra,24(sp)
 4c4:	6442                	ld	s0,16(sp)
 4c6:	6105                	addi	sp,sp,32
 4c8:	8082                	ret

00000000000004ca <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4ca:	7139                	addi	sp,sp,-64
 4cc:	fc06                	sd	ra,56(sp)
 4ce:	f822                	sd	s0,48(sp)
 4d0:	f426                	sd	s1,40(sp)
 4d2:	f04a                	sd	s2,32(sp)
 4d4:	ec4e                	sd	s3,24(sp)
 4d6:	0080                	addi	s0,sp,64
 4d8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4da:	c299                	beqz	a3,4e0 <printint+0x16>
 4dc:	0805c963          	bltz	a1,56e <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4e0:	2581                	sext.w	a1,a1
  neg = 0;
 4e2:	4881                	li	a7,0
 4e4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4e8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4ea:	2601                	sext.w	a2,a2
 4ec:	00000517          	auipc	a0,0x0
 4f0:	51450513          	addi	a0,a0,1300 # a00 <digits>
 4f4:	883a                	mv	a6,a4
 4f6:	2705                	addiw	a4,a4,1
 4f8:	02c5f7bb          	remuw	a5,a1,a2
 4fc:	1782                	slli	a5,a5,0x20
 4fe:	9381                	srli	a5,a5,0x20
 500:	97aa                	add	a5,a5,a0
 502:	0007c783          	lbu	a5,0(a5)
 506:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 50a:	0005879b          	sext.w	a5,a1
 50e:	02c5d5bb          	divuw	a1,a1,a2
 512:	0685                	addi	a3,a3,1
 514:	fec7f0e3          	bgeu	a5,a2,4f4 <printint+0x2a>
  if(neg)
 518:	00088c63          	beqz	a7,530 <printint+0x66>
    buf[i++] = '-';
 51c:	fd070793          	addi	a5,a4,-48
 520:	00878733          	add	a4,a5,s0
 524:	02d00793          	li	a5,45
 528:	fef70823          	sb	a5,-16(a4)
 52c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 530:	02e05863          	blez	a4,560 <printint+0x96>
 534:	fc040793          	addi	a5,s0,-64
 538:	00e78933          	add	s2,a5,a4
 53c:	fff78993          	addi	s3,a5,-1
 540:	99ba                	add	s3,s3,a4
 542:	377d                	addiw	a4,a4,-1
 544:	1702                	slli	a4,a4,0x20
 546:	9301                	srli	a4,a4,0x20
 548:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 54c:	fff94583          	lbu	a1,-1(s2)
 550:	8526                	mv	a0,s1
 552:	00000097          	auipc	ra,0x0
 556:	f56080e7          	jalr	-170(ra) # 4a8 <putc>
  while(--i >= 0)
 55a:	197d                	addi	s2,s2,-1
 55c:	ff3918e3          	bne	s2,s3,54c <printint+0x82>
}
 560:	70e2                	ld	ra,56(sp)
 562:	7442                	ld	s0,48(sp)
 564:	74a2                	ld	s1,40(sp)
 566:	7902                	ld	s2,32(sp)
 568:	69e2                	ld	s3,24(sp)
 56a:	6121                	addi	sp,sp,64
 56c:	8082                	ret
    x = -xx;
 56e:	40b005bb          	negw	a1,a1
    neg = 1;
 572:	4885                	li	a7,1
    x = -xx;
 574:	bf85                	j	4e4 <printint+0x1a>

0000000000000576 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 576:	7119                	addi	sp,sp,-128
 578:	fc86                	sd	ra,120(sp)
 57a:	f8a2                	sd	s0,112(sp)
 57c:	f4a6                	sd	s1,104(sp)
 57e:	f0ca                	sd	s2,96(sp)
 580:	ecce                	sd	s3,88(sp)
 582:	e8d2                	sd	s4,80(sp)
 584:	e4d6                	sd	s5,72(sp)
 586:	e0da                	sd	s6,64(sp)
 588:	fc5e                	sd	s7,56(sp)
 58a:	f862                	sd	s8,48(sp)
 58c:	f466                	sd	s9,40(sp)
 58e:	f06a                	sd	s10,32(sp)
 590:	ec6e                	sd	s11,24(sp)
 592:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 594:	0005c903          	lbu	s2,0(a1)
 598:	18090f63          	beqz	s2,736 <vprintf+0x1c0>
 59c:	8aaa                	mv	s5,a0
 59e:	8b32                	mv	s6,a2
 5a0:	00158493          	addi	s1,a1,1
  state = 0;
 5a4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5a6:	02500a13          	li	s4,37
 5aa:	4c55                	li	s8,21
 5ac:	00000c97          	auipc	s9,0x0
 5b0:	3fcc8c93          	addi	s9,s9,1020 # 9a8 <malloc+0x16e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 5b4:	02800d93          	li	s11,40
  putc(fd, 'x');
 5b8:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5ba:	00000b97          	auipc	s7,0x0
 5be:	446b8b93          	addi	s7,s7,1094 # a00 <digits>
 5c2:	a839                	j	5e0 <vprintf+0x6a>
        putc(fd, c);
 5c4:	85ca                	mv	a1,s2
 5c6:	8556                	mv	a0,s5
 5c8:	00000097          	auipc	ra,0x0
 5cc:	ee0080e7          	jalr	-288(ra) # 4a8 <putc>
 5d0:	a019                	j	5d6 <vprintf+0x60>
    } else if(state == '%'){
 5d2:	01498d63          	beq	s3,s4,5ec <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 5d6:	0485                	addi	s1,s1,1
 5d8:	fff4c903          	lbu	s2,-1(s1)
 5dc:	14090d63          	beqz	s2,736 <vprintf+0x1c0>
    if(state == 0){
 5e0:	fe0999e3          	bnez	s3,5d2 <vprintf+0x5c>
      if(c == '%'){
 5e4:	ff4910e3          	bne	s2,s4,5c4 <vprintf+0x4e>
        state = '%';
 5e8:	89d2                	mv	s3,s4
 5ea:	b7f5                	j	5d6 <vprintf+0x60>
      if(c == 'd'){
 5ec:	11490c63          	beq	s2,s4,704 <vprintf+0x18e>
 5f0:	f9d9079b          	addiw	a5,s2,-99
 5f4:	0ff7f793          	zext.b	a5,a5
 5f8:	10fc6e63          	bltu	s8,a5,714 <vprintf+0x19e>
 5fc:	f9d9079b          	addiw	a5,s2,-99
 600:	0ff7f713          	zext.b	a4,a5
 604:	10ec6863          	bltu	s8,a4,714 <vprintf+0x19e>
 608:	00271793          	slli	a5,a4,0x2
 60c:	97e6                	add	a5,a5,s9
 60e:	439c                	lw	a5,0(a5)
 610:	97e6                	add	a5,a5,s9
 612:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 614:	008b0913          	addi	s2,s6,8
 618:	4685                	li	a3,1
 61a:	4629                	li	a2,10
 61c:	000b2583          	lw	a1,0(s6)
 620:	8556                	mv	a0,s5
 622:	00000097          	auipc	ra,0x0
 626:	ea8080e7          	jalr	-344(ra) # 4ca <printint>
 62a:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 62c:	4981                	li	s3,0
 62e:	b765                	j	5d6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 630:	008b0913          	addi	s2,s6,8
 634:	4681                	li	a3,0
 636:	4629                	li	a2,10
 638:	000b2583          	lw	a1,0(s6)
 63c:	8556                	mv	a0,s5
 63e:	00000097          	auipc	ra,0x0
 642:	e8c080e7          	jalr	-372(ra) # 4ca <printint>
 646:	8b4a                	mv	s6,s2
      state = 0;
 648:	4981                	li	s3,0
 64a:	b771                	j	5d6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 64c:	008b0913          	addi	s2,s6,8
 650:	4681                	li	a3,0
 652:	866a                	mv	a2,s10
 654:	000b2583          	lw	a1,0(s6)
 658:	8556                	mv	a0,s5
 65a:	00000097          	auipc	ra,0x0
 65e:	e70080e7          	jalr	-400(ra) # 4ca <printint>
 662:	8b4a                	mv	s6,s2
      state = 0;
 664:	4981                	li	s3,0
 666:	bf85                	j	5d6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 668:	008b0793          	addi	a5,s6,8
 66c:	f8f43423          	sd	a5,-120(s0)
 670:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 674:	03000593          	li	a1,48
 678:	8556                	mv	a0,s5
 67a:	00000097          	auipc	ra,0x0
 67e:	e2e080e7          	jalr	-466(ra) # 4a8 <putc>
  putc(fd, 'x');
 682:	07800593          	li	a1,120
 686:	8556                	mv	a0,s5
 688:	00000097          	auipc	ra,0x0
 68c:	e20080e7          	jalr	-480(ra) # 4a8 <putc>
 690:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 692:	03c9d793          	srli	a5,s3,0x3c
 696:	97de                	add	a5,a5,s7
 698:	0007c583          	lbu	a1,0(a5)
 69c:	8556                	mv	a0,s5
 69e:	00000097          	auipc	ra,0x0
 6a2:	e0a080e7          	jalr	-502(ra) # 4a8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6a6:	0992                	slli	s3,s3,0x4
 6a8:	397d                	addiw	s2,s2,-1
 6aa:	fe0914e3          	bnez	s2,692 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 6ae:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6b2:	4981                	li	s3,0
 6b4:	b70d                	j	5d6 <vprintf+0x60>
        s = va_arg(ap, char*);
 6b6:	008b0913          	addi	s2,s6,8
 6ba:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 6be:	02098163          	beqz	s3,6e0 <vprintf+0x16a>
        while(*s != 0){
 6c2:	0009c583          	lbu	a1,0(s3)
 6c6:	c5ad                	beqz	a1,730 <vprintf+0x1ba>
          putc(fd, *s);
 6c8:	8556                	mv	a0,s5
 6ca:	00000097          	auipc	ra,0x0
 6ce:	dde080e7          	jalr	-546(ra) # 4a8 <putc>
          s++;
 6d2:	0985                	addi	s3,s3,1
        while(*s != 0){
 6d4:	0009c583          	lbu	a1,0(s3)
 6d8:	f9e5                	bnez	a1,6c8 <vprintf+0x152>
        s = va_arg(ap, char*);
 6da:	8b4a                	mv	s6,s2
      state = 0;
 6dc:	4981                	li	s3,0
 6de:	bde5                	j	5d6 <vprintf+0x60>
          s = "(null)";
 6e0:	00000997          	auipc	s3,0x0
 6e4:	2c098993          	addi	s3,s3,704 # 9a0 <malloc+0x166>
        while(*s != 0){
 6e8:	85ee                	mv	a1,s11
 6ea:	bff9                	j	6c8 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 6ec:	008b0913          	addi	s2,s6,8
 6f0:	000b4583          	lbu	a1,0(s6)
 6f4:	8556                	mv	a0,s5
 6f6:	00000097          	auipc	ra,0x0
 6fa:	db2080e7          	jalr	-590(ra) # 4a8 <putc>
 6fe:	8b4a                	mv	s6,s2
      state = 0;
 700:	4981                	li	s3,0
 702:	bdd1                	j	5d6 <vprintf+0x60>
        putc(fd, c);
 704:	85d2                	mv	a1,s4
 706:	8556                	mv	a0,s5
 708:	00000097          	auipc	ra,0x0
 70c:	da0080e7          	jalr	-608(ra) # 4a8 <putc>
      state = 0;
 710:	4981                	li	s3,0
 712:	b5d1                	j	5d6 <vprintf+0x60>
        putc(fd, '%');
 714:	85d2                	mv	a1,s4
 716:	8556                	mv	a0,s5
 718:	00000097          	auipc	ra,0x0
 71c:	d90080e7          	jalr	-624(ra) # 4a8 <putc>
        putc(fd, c);
 720:	85ca                	mv	a1,s2
 722:	8556                	mv	a0,s5
 724:	00000097          	auipc	ra,0x0
 728:	d84080e7          	jalr	-636(ra) # 4a8 <putc>
      state = 0;
 72c:	4981                	li	s3,0
 72e:	b565                	j	5d6 <vprintf+0x60>
        s = va_arg(ap, char*);
 730:	8b4a                	mv	s6,s2
      state = 0;
 732:	4981                	li	s3,0
 734:	b54d                	j	5d6 <vprintf+0x60>
    }
  }
}
 736:	70e6                	ld	ra,120(sp)
 738:	7446                	ld	s0,112(sp)
 73a:	74a6                	ld	s1,104(sp)
 73c:	7906                	ld	s2,96(sp)
 73e:	69e6                	ld	s3,88(sp)
 740:	6a46                	ld	s4,80(sp)
 742:	6aa6                	ld	s5,72(sp)
 744:	6b06                	ld	s6,64(sp)
 746:	7be2                	ld	s7,56(sp)
 748:	7c42                	ld	s8,48(sp)
 74a:	7ca2                	ld	s9,40(sp)
 74c:	7d02                	ld	s10,32(sp)
 74e:	6de2                	ld	s11,24(sp)
 750:	6109                	addi	sp,sp,128
 752:	8082                	ret

0000000000000754 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 754:	715d                	addi	sp,sp,-80
 756:	ec06                	sd	ra,24(sp)
 758:	e822                	sd	s0,16(sp)
 75a:	1000                	addi	s0,sp,32
 75c:	e010                	sd	a2,0(s0)
 75e:	e414                	sd	a3,8(s0)
 760:	e818                	sd	a4,16(s0)
 762:	ec1c                	sd	a5,24(s0)
 764:	03043023          	sd	a6,32(s0)
 768:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 76c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 770:	8622                	mv	a2,s0
 772:	00000097          	auipc	ra,0x0
 776:	e04080e7          	jalr	-508(ra) # 576 <vprintf>
}
 77a:	60e2                	ld	ra,24(sp)
 77c:	6442                	ld	s0,16(sp)
 77e:	6161                	addi	sp,sp,80
 780:	8082                	ret

0000000000000782 <printf>:

void
printf(const char *fmt, ...)
{
 782:	711d                	addi	sp,sp,-96
 784:	ec06                	sd	ra,24(sp)
 786:	e822                	sd	s0,16(sp)
 788:	1000                	addi	s0,sp,32
 78a:	e40c                	sd	a1,8(s0)
 78c:	e810                	sd	a2,16(s0)
 78e:	ec14                	sd	a3,24(s0)
 790:	f018                	sd	a4,32(s0)
 792:	f41c                	sd	a5,40(s0)
 794:	03043823          	sd	a6,48(s0)
 798:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 79c:	00840613          	addi	a2,s0,8
 7a0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7a4:	85aa                	mv	a1,a0
 7a6:	4505                	li	a0,1
 7a8:	00000097          	auipc	ra,0x0
 7ac:	dce080e7          	jalr	-562(ra) # 576 <vprintf>
}
 7b0:	60e2                	ld	ra,24(sp)
 7b2:	6442                	ld	s0,16(sp)
 7b4:	6125                	addi	sp,sp,96
 7b6:	8082                	ret

00000000000007b8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7b8:	1141                	addi	sp,sp,-16
 7ba:	e422                	sd	s0,8(sp)
 7bc:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7be:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7c2:	00000797          	auipc	a5,0x0
 7c6:	2567b783          	ld	a5,598(a5) # a18 <freep>
 7ca:	a02d                	j	7f4 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7cc:	4618                	lw	a4,8(a2)
 7ce:	9f2d                	addw	a4,a4,a1
 7d0:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7d4:	6398                	ld	a4,0(a5)
 7d6:	6310                	ld	a2,0(a4)
 7d8:	a83d                	j	816 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7da:	ff852703          	lw	a4,-8(a0)
 7de:	9f31                	addw	a4,a4,a2
 7e0:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 7e2:	ff053683          	ld	a3,-16(a0)
 7e6:	a091                	j	82a <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7e8:	6398                	ld	a4,0(a5)
 7ea:	00e7e463          	bltu	a5,a4,7f2 <free+0x3a>
 7ee:	00e6ea63          	bltu	a3,a4,802 <free+0x4a>
{
 7f2:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7f4:	fed7fae3          	bgeu	a5,a3,7e8 <free+0x30>
 7f8:	6398                	ld	a4,0(a5)
 7fa:	00e6e463          	bltu	a3,a4,802 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7fe:	fee7eae3          	bltu	a5,a4,7f2 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 802:	ff852583          	lw	a1,-8(a0)
 806:	6390                	ld	a2,0(a5)
 808:	02059813          	slli	a6,a1,0x20
 80c:	01c85713          	srli	a4,a6,0x1c
 810:	9736                	add	a4,a4,a3
 812:	fae60de3          	beq	a2,a4,7cc <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 816:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 81a:	4790                	lw	a2,8(a5)
 81c:	02061593          	slli	a1,a2,0x20
 820:	01c5d713          	srli	a4,a1,0x1c
 824:	973e                	add	a4,a4,a5
 826:	fae68ae3          	beq	a3,a4,7da <free+0x22>
    p->s.ptr = bp->s.ptr;
 82a:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 82c:	00000717          	auipc	a4,0x0
 830:	1ef73623          	sd	a5,492(a4) # a18 <freep>
}
 834:	6422                	ld	s0,8(sp)
 836:	0141                	addi	sp,sp,16
 838:	8082                	ret

000000000000083a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 83a:	7139                	addi	sp,sp,-64
 83c:	fc06                	sd	ra,56(sp)
 83e:	f822                	sd	s0,48(sp)
 840:	f426                	sd	s1,40(sp)
 842:	f04a                	sd	s2,32(sp)
 844:	ec4e                	sd	s3,24(sp)
 846:	e852                	sd	s4,16(sp)
 848:	e456                	sd	s5,8(sp)
 84a:	e05a                	sd	s6,0(sp)
 84c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 84e:	02051493          	slli	s1,a0,0x20
 852:	9081                	srli	s1,s1,0x20
 854:	04bd                	addi	s1,s1,15
 856:	8091                	srli	s1,s1,0x4
 858:	0014899b          	addiw	s3,s1,1
 85c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 85e:	00000517          	auipc	a0,0x0
 862:	1ba53503          	ld	a0,442(a0) # a18 <freep>
 866:	c515                	beqz	a0,892 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 868:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 86a:	4798                	lw	a4,8(a5)
 86c:	02977f63          	bgeu	a4,s1,8aa <malloc+0x70>
 870:	8a4e                	mv	s4,s3
 872:	0009871b          	sext.w	a4,s3
 876:	6685                	lui	a3,0x1
 878:	00d77363          	bgeu	a4,a3,87e <malloc+0x44>
 87c:	6a05                	lui	s4,0x1
 87e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 882:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 886:	00000917          	auipc	s2,0x0
 88a:	19290913          	addi	s2,s2,402 # a18 <freep>
  if(p == (char*)-1)
 88e:	5afd                	li	s5,-1
 890:	a895                	j	904 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 892:	00000797          	auipc	a5,0x0
 896:	18e78793          	addi	a5,a5,398 # a20 <base>
 89a:	00000717          	auipc	a4,0x0
 89e:	16f73f23          	sd	a5,382(a4) # a18 <freep>
 8a2:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8a4:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8a8:	b7e1                	j	870 <malloc+0x36>
      if(p->s.size == nunits)
 8aa:	02e48c63          	beq	s1,a4,8e2 <malloc+0xa8>
        p->s.size -= nunits;
 8ae:	4137073b          	subw	a4,a4,s3
 8b2:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8b4:	02071693          	slli	a3,a4,0x20
 8b8:	01c6d713          	srli	a4,a3,0x1c
 8bc:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8be:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8c2:	00000717          	auipc	a4,0x0
 8c6:	14a73b23          	sd	a0,342(a4) # a18 <freep>
      return (void*)(p + 1);
 8ca:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8ce:	70e2                	ld	ra,56(sp)
 8d0:	7442                	ld	s0,48(sp)
 8d2:	74a2                	ld	s1,40(sp)
 8d4:	7902                	ld	s2,32(sp)
 8d6:	69e2                	ld	s3,24(sp)
 8d8:	6a42                	ld	s4,16(sp)
 8da:	6aa2                	ld	s5,8(sp)
 8dc:	6b02                	ld	s6,0(sp)
 8de:	6121                	addi	sp,sp,64
 8e0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8e2:	6398                	ld	a4,0(a5)
 8e4:	e118                	sd	a4,0(a0)
 8e6:	bff1                	j	8c2 <malloc+0x88>
  hp->s.size = nu;
 8e8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8ec:	0541                	addi	a0,a0,16
 8ee:	00000097          	auipc	ra,0x0
 8f2:	eca080e7          	jalr	-310(ra) # 7b8 <free>
  return freep;
 8f6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8fa:	d971                	beqz	a0,8ce <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8fc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8fe:	4798                	lw	a4,8(a5)
 900:	fa9775e3          	bgeu	a4,s1,8aa <malloc+0x70>
    if(p == freep)
 904:	00093703          	ld	a4,0(s2)
 908:	853e                	mv	a0,a5
 90a:	fef719e3          	bne	a4,a5,8fc <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 90e:	8552                	mv	a0,s4
 910:	00000097          	auipc	ra,0x0
 914:	b60080e7          	jalr	-1184(ra) # 470 <sbrk>
  if(p == (char*)-1)
 918:	fd5518e3          	bne	a0,s5,8e8 <malloc+0xae>
        return 0;
 91c:	4501                	li	a0,0
 91e:	bf45                	j	8ce <malloc+0x94>
