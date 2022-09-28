
user/_forksleep:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char const *argv[])
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
    if(argc < 2){
   c:	4785                	li	a5,1
   e:	04a7d363          	bge	a5,a0,54 <main+0x54>
  12:	84ae                	mv	s1,a1
        printf("Too few arguments. Expected 3 got $d.\n", argc);
        exit(0);
    }

    int m, n;
    m = atoi(argv[1]);
  14:	6588                	ld	a0,8(a1)
  16:	00000097          	auipc	ra,0x0
  1a:	218080e7          	jalr	536(ra) # 22e <atoi>
  1e:	892a                	mv	s2,a0
    n = atoi(argv[2]);
  20:	6888                	ld	a0,16(s1)
  22:	00000097          	auipc	ra,0x0
  26:	20c080e7          	jalr	524(ra) # 22e <atoi>
  2a:	84aa                	mv	s1,a0

    if(fork() == 0){
  2c:	00000097          	auipc	ra,0x0
  30:	2f4080e7          	jalr	756(ra) # 320 <fork>
  34:	e521                	bnez	a0,7c <main+0x7c>
        if(n == 0) sleep(m);
  36:	cc8d                	beqz	s1,70 <main+0x70>
        printf("%d: Child.\n", getpid());
  38:	00000097          	auipc	ra,0x0
  3c:	370080e7          	jalr	880(ra) # 3a8 <getpid>
  40:	85aa                	mv	a1,a0
  42:	00001517          	auipc	a0,0x1
  46:	83e50513          	addi	a0,a0,-1986 # 880 <malloc+0x10e>
  4a:	00000097          	auipc	ra,0x0
  4e:	670080e7          	jalr	1648(ra) # 6ba <printf>
  52:	a891                	j	a6 <main+0xa6>
        printf("Too few arguments. Expected 3 got $d.\n", argc);
  54:	85aa                	mv	a1,a0
  56:	00001517          	auipc	a0,0x1
  5a:	80250513          	addi	a0,a0,-2046 # 858 <malloc+0xe6>
  5e:	00000097          	auipc	ra,0x0
  62:	65c080e7          	jalr	1628(ra) # 6ba <printf>
        exit(0);
  66:	4501                	li	a0,0
  68:	00000097          	auipc	ra,0x0
  6c:	2c0080e7          	jalr	704(ra) # 328 <exit>
        if(n == 0) sleep(m);
  70:	854a                	mv	a0,s2
  72:	00000097          	auipc	ra,0x0
  76:	346080e7          	jalr	838(ra) # 3b8 <sleep>
  7a:	bf7d                	j	38 <main+0x38>
    }
    else{
        if(n == 1) sleep(m);
  7c:	4785                	li	a5,1
  7e:	02f48963          	beq	s1,a5,b0 <main+0xb0>
        printf("%d: Parent.\n", getpid());
  82:	00000097          	auipc	ra,0x0
  86:	326080e7          	jalr	806(ra) # 3a8 <getpid>
  8a:	85aa                	mv	a1,a0
  8c:	00001517          	auipc	a0,0x1
  90:	80450513          	addi	a0,a0,-2044 # 890 <malloc+0x11e>
  94:	00000097          	auipc	ra,0x0
  98:	626080e7          	jalr	1574(ra) # 6ba <printf>
        wait(0);
  9c:	4501                	li	a0,0
  9e:	00000097          	auipc	ra,0x0
  a2:	292080e7          	jalr	658(ra) # 330 <wait>
    }
    exit(0);
  a6:	4501                	li	a0,0
  a8:	00000097          	auipc	ra,0x0
  ac:	280080e7          	jalr	640(ra) # 328 <exit>
        if(n == 1) sleep(m);
  b0:	854a                	mv	a0,s2
  b2:	00000097          	auipc	ra,0x0
  b6:	306080e7          	jalr	774(ra) # 3b8 <sleep>
  ba:	b7e1                	j	82 <main+0x82>

00000000000000bc <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  bc:	1141                	addi	sp,sp,-16
  be:	e422                	sd	s0,8(sp)
  c0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  c2:	87aa                	mv	a5,a0
  c4:	0585                	addi	a1,a1,1
  c6:	0785                	addi	a5,a5,1
  c8:	fff5c703          	lbu	a4,-1(a1)
  cc:	fee78fa3          	sb	a4,-1(a5)
  d0:	fb75                	bnez	a4,c4 <strcpy+0x8>
    ;
  return os;
}
  d2:	6422                	ld	s0,8(sp)
  d4:	0141                	addi	sp,sp,16
  d6:	8082                	ret

00000000000000d8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  d8:	1141                	addi	sp,sp,-16
  da:	e422                	sd	s0,8(sp)
  dc:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  de:	00054783          	lbu	a5,0(a0)
  e2:	cb91                	beqz	a5,f6 <strcmp+0x1e>
  e4:	0005c703          	lbu	a4,0(a1)
  e8:	00f71763          	bne	a4,a5,f6 <strcmp+0x1e>
    p++, q++;
  ec:	0505                	addi	a0,a0,1
  ee:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  f0:	00054783          	lbu	a5,0(a0)
  f4:	fbe5                	bnez	a5,e4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  f6:	0005c503          	lbu	a0,0(a1)
}
  fa:	40a7853b          	subw	a0,a5,a0
  fe:	6422                	ld	s0,8(sp)
 100:	0141                	addi	sp,sp,16
 102:	8082                	ret

0000000000000104 <strlen>:

uint
strlen(const char *s)
{
 104:	1141                	addi	sp,sp,-16
 106:	e422                	sd	s0,8(sp)
 108:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 10a:	00054783          	lbu	a5,0(a0)
 10e:	cf91                	beqz	a5,12a <strlen+0x26>
 110:	0505                	addi	a0,a0,1
 112:	87aa                	mv	a5,a0
 114:	4685                	li	a3,1
 116:	9e89                	subw	a3,a3,a0
 118:	00f6853b          	addw	a0,a3,a5
 11c:	0785                	addi	a5,a5,1
 11e:	fff7c703          	lbu	a4,-1(a5)
 122:	fb7d                	bnez	a4,118 <strlen+0x14>
    ;
  return n;
}
 124:	6422                	ld	s0,8(sp)
 126:	0141                	addi	sp,sp,16
 128:	8082                	ret
  for(n = 0; s[n]; n++)
 12a:	4501                	li	a0,0
 12c:	bfe5                	j	124 <strlen+0x20>

000000000000012e <memset>:

void*
memset(void *dst, int c, uint n)
{
 12e:	1141                	addi	sp,sp,-16
 130:	e422                	sd	s0,8(sp)
 132:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 134:	ca19                	beqz	a2,14a <memset+0x1c>
 136:	87aa                	mv	a5,a0
 138:	1602                	slli	a2,a2,0x20
 13a:	9201                	srli	a2,a2,0x20
 13c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 140:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 144:	0785                	addi	a5,a5,1
 146:	fee79de3          	bne	a5,a4,140 <memset+0x12>
  }
  return dst;
}
 14a:	6422                	ld	s0,8(sp)
 14c:	0141                	addi	sp,sp,16
 14e:	8082                	ret

0000000000000150 <strchr>:

char*
strchr(const char *s, char c)
{
 150:	1141                	addi	sp,sp,-16
 152:	e422                	sd	s0,8(sp)
 154:	0800                	addi	s0,sp,16
  for(; *s; s++)
 156:	00054783          	lbu	a5,0(a0)
 15a:	cb99                	beqz	a5,170 <strchr+0x20>
    if(*s == c)
 15c:	00f58763          	beq	a1,a5,16a <strchr+0x1a>
  for(; *s; s++)
 160:	0505                	addi	a0,a0,1
 162:	00054783          	lbu	a5,0(a0)
 166:	fbfd                	bnez	a5,15c <strchr+0xc>
      return (char*)s;
  return 0;
 168:	4501                	li	a0,0
}
 16a:	6422                	ld	s0,8(sp)
 16c:	0141                	addi	sp,sp,16
 16e:	8082                	ret
  return 0;
 170:	4501                	li	a0,0
 172:	bfe5                	j	16a <strchr+0x1a>

0000000000000174 <gets>:

char*
gets(char *buf, int max)
{
 174:	711d                	addi	sp,sp,-96
 176:	ec86                	sd	ra,88(sp)
 178:	e8a2                	sd	s0,80(sp)
 17a:	e4a6                	sd	s1,72(sp)
 17c:	e0ca                	sd	s2,64(sp)
 17e:	fc4e                	sd	s3,56(sp)
 180:	f852                	sd	s4,48(sp)
 182:	f456                	sd	s5,40(sp)
 184:	f05a                	sd	s6,32(sp)
 186:	ec5e                	sd	s7,24(sp)
 188:	1080                	addi	s0,sp,96
 18a:	8baa                	mv	s7,a0
 18c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 18e:	892a                	mv	s2,a0
 190:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 192:	4aa9                	li	s5,10
 194:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 196:	89a6                	mv	s3,s1
 198:	2485                	addiw	s1,s1,1
 19a:	0344d863          	bge	s1,s4,1ca <gets+0x56>
    cc = read(0, &c, 1);
 19e:	4605                	li	a2,1
 1a0:	faf40593          	addi	a1,s0,-81
 1a4:	4501                	li	a0,0
 1a6:	00000097          	auipc	ra,0x0
 1aa:	19a080e7          	jalr	410(ra) # 340 <read>
    if(cc < 1)
 1ae:	00a05e63          	blez	a0,1ca <gets+0x56>
    buf[i++] = c;
 1b2:	faf44783          	lbu	a5,-81(s0)
 1b6:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1ba:	01578763          	beq	a5,s5,1c8 <gets+0x54>
 1be:	0905                	addi	s2,s2,1
 1c0:	fd679be3          	bne	a5,s6,196 <gets+0x22>
  for(i=0; i+1 < max; ){
 1c4:	89a6                	mv	s3,s1
 1c6:	a011                	j	1ca <gets+0x56>
 1c8:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1ca:	99de                	add	s3,s3,s7
 1cc:	00098023          	sb	zero,0(s3)
  return buf;
}
 1d0:	855e                	mv	a0,s7
 1d2:	60e6                	ld	ra,88(sp)
 1d4:	6446                	ld	s0,80(sp)
 1d6:	64a6                	ld	s1,72(sp)
 1d8:	6906                	ld	s2,64(sp)
 1da:	79e2                	ld	s3,56(sp)
 1dc:	7a42                	ld	s4,48(sp)
 1de:	7aa2                	ld	s5,40(sp)
 1e0:	7b02                	ld	s6,32(sp)
 1e2:	6be2                	ld	s7,24(sp)
 1e4:	6125                	addi	sp,sp,96
 1e6:	8082                	ret

00000000000001e8 <stat>:

int
stat(const char *n, struct stat *st)
{
 1e8:	1101                	addi	sp,sp,-32
 1ea:	ec06                	sd	ra,24(sp)
 1ec:	e822                	sd	s0,16(sp)
 1ee:	e426                	sd	s1,8(sp)
 1f0:	e04a                	sd	s2,0(sp)
 1f2:	1000                	addi	s0,sp,32
 1f4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1f6:	4581                	li	a1,0
 1f8:	00000097          	auipc	ra,0x0
 1fc:	170080e7          	jalr	368(ra) # 368 <open>
  if(fd < 0)
 200:	02054563          	bltz	a0,22a <stat+0x42>
 204:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 206:	85ca                	mv	a1,s2
 208:	00000097          	auipc	ra,0x0
 20c:	178080e7          	jalr	376(ra) # 380 <fstat>
 210:	892a                	mv	s2,a0
  close(fd);
 212:	8526                	mv	a0,s1
 214:	00000097          	auipc	ra,0x0
 218:	13c080e7          	jalr	316(ra) # 350 <close>
  return r;
}
 21c:	854a                	mv	a0,s2
 21e:	60e2                	ld	ra,24(sp)
 220:	6442                	ld	s0,16(sp)
 222:	64a2                	ld	s1,8(sp)
 224:	6902                	ld	s2,0(sp)
 226:	6105                	addi	sp,sp,32
 228:	8082                	ret
    return -1;
 22a:	597d                	li	s2,-1
 22c:	bfc5                	j	21c <stat+0x34>

000000000000022e <atoi>:

int
atoi(const char *s)
{
 22e:	1141                	addi	sp,sp,-16
 230:	e422                	sd	s0,8(sp)
 232:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 234:	00054683          	lbu	a3,0(a0)
 238:	fd06879b          	addiw	a5,a3,-48
 23c:	0ff7f793          	zext.b	a5,a5
 240:	4625                	li	a2,9
 242:	02f66863          	bltu	a2,a5,272 <atoi+0x44>
 246:	872a                	mv	a4,a0
  n = 0;
 248:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 24a:	0705                	addi	a4,a4,1
 24c:	0025179b          	slliw	a5,a0,0x2
 250:	9fa9                	addw	a5,a5,a0
 252:	0017979b          	slliw	a5,a5,0x1
 256:	9fb5                	addw	a5,a5,a3
 258:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 25c:	00074683          	lbu	a3,0(a4)
 260:	fd06879b          	addiw	a5,a3,-48
 264:	0ff7f793          	zext.b	a5,a5
 268:	fef671e3          	bgeu	a2,a5,24a <atoi+0x1c>
  return n;
}
 26c:	6422                	ld	s0,8(sp)
 26e:	0141                	addi	sp,sp,16
 270:	8082                	ret
  n = 0;
 272:	4501                	li	a0,0
 274:	bfe5                	j	26c <atoi+0x3e>

0000000000000276 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 276:	1141                	addi	sp,sp,-16
 278:	e422                	sd	s0,8(sp)
 27a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 27c:	02b57463          	bgeu	a0,a1,2a4 <memmove+0x2e>
    while(n-- > 0)
 280:	00c05f63          	blez	a2,29e <memmove+0x28>
 284:	1602                	slli	a2,a2,0x20
 286:	9201                	srli	a2,a2,0x20
 288:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 28c:	872a                	mv	a4,a0
      *dst++ = *src++;
 28e:	0585                	addi	a1,a1,1
 290:	0705                	addi	a4,a4,1
 292:	fff5c683          	lbu	a3,-1(a1)
 296:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 29a:	fee79ae3          	bne	a5,a4,28e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 29e:	6422                	ld	s0,8(sp)
 2a0:	0141                	addi	sp,sp,16
 2a2:	8082                	ret
    dst += n;
 2a4:	00c50733          	add	a4,a0,a2
    src += n;
 2a8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2aa:	fec05ae3          	blez	a2,29e <memmove+0x28>
 2ae:	fff6079b          	addiw	a5,a2,-1
 2b2:	1782                	slli	a5,a5,0x20
 2b4:	9381                	srli	a5,a5,0x20
 2b6:	fff7c793          	not	a5,a5
 2ba:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2bc:	15fd                	addi	a1,a1,-1
 2be:	177d                	addi	a4,a4,-1
 2c0:	0005c683          	lbu	a3,0(a1)
 2c4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2c8:	fee79ae3          	bne	a5,a4,2bc <memmove+0x46>
 2cc:	bfc9                	j	29e <memmove+0x28>

00000000000002ce <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2ce:	1141                	addi	sp,sp,-16
 2d0:	e422                	sd	s0,8(sp)
 2d2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2d4:	ca05                	beqz	a2,304 <memcmp+0x36>
 2d6:	fff6069b          	addiw	a3,a2,-1
 2da:	1682                	slli	a3,a3,0x20
 2dc:	9281                	srli	a3,a3,0x20
 2de:	0685                	addi	a3,a3,1
 2e0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2e2:	00054783          	lbu	a5,0(a0)
 2e6:	0005c703          	lbu	a4,0(a1)
 2ea:	00e79863          	bne	a5,a4,2fa <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2ee:	0505                	addi	a0,a0,1
    p2++;
 2f0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2f2:	fed518e3          	bne	a0,a3,2e2 <memcmp+0x14>
  }
  return 0;
 2f6:	4501                	li	a0,0
 2f8:	a019                	j	2fe <memcmp+0x30>
      return *p1 - *p2;
 2fa:	40e7853b          	subw	a0,a5,a4
}
 2fe:	6422                	ld	s0,8(sp)
 300:	0141                	addi	sp,sp,16
 302:	8082                	ret
  return 0;
 304:	4501                	li	a0,0
 306:	bfe5                	j	2fe <memcmp+0x30>

0000000000000308 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 308:	1141                	addi	sp,sp,-16
 30a:	e406                	sd	ra,8(sp)
 30c:	e022                	sd	s0,0(sp)
 30e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 310:	00000097          	auipc	ra,0x0
 314:	f66080e7          	jalr	-154(ra) # 276 <memmove>
}
 318:	60a2                	ld	ra,8(sp)
 31a:	6402                	ld	s0,0(sp)
 31c:	0141                	addi	sp,sp,16
 31e:	8082                	ret

0000000000000320 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 320:	4885                	li	a7,1
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <exit>:
.global exit
exit:
 li a7, SYS_exit
 328:	4889                	li	a7,2
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <wait>:
.global wait
wait:
 li a7, SYS_wait
 330:	488d                	li	a7,3
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 338:	4891                	li	a7,4
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <read>:
.global read
read:
 li a7, SYS_read
 340:	4895                	li	a7,5
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <write>:
.global write
write:
 li a7, SYS_write
 348:	48c1                	li	a7,16
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <close>:
.global close
close:
 li a7, SYS_close
 350:	48d5                	li	a7,21
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <kill>:
.global kill
kill:
 li a7, SYS_kill
 358:	4899                	li	a7,6
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <exec>:
.global exec
exec:
 li a7, SYS_exec
 360:	489d                	li	a7,7
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <open>:
.global open
open:
 li a7, SYS_open
 368:	48bd                	li	a7,15
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 370:	48c5                	li	a7,17
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 378:	48c9                	li	a7,18
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 380:	48a1                	li	a7,8
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <link>:
.global link
link:
 li a7, SYS_link
 388:	48cd                	li	a7,19
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 390:	48d1                	li	a7,20
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 398:	48a5                	li	a7,9
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3a0:	48a9                	li	a7,10
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3a8:	48ad                	li	a7,11
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3b0:	48b1                	li	a7,12
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3b8:	48b5                	li	a7,13
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3c0:	48b9                	li	a7,14
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <getppid>:
.global getppid
getppid:
 li a7, SYS_getppid
 3c8:	48d9                	li	a7,22
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <yield>:
.global yield
yield:
 li a7, SYS_yield
 3d0:	48dd                	li	a7,23
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <getpa>:
.global getpa
getpa:
 li a7, SYS_getpa
 3d8:	48e1                	li	a7,24
 ecall
 3da:	00000073          	ecall
 ret
 3de:	8082                	ret

00000000000003e0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3e0:	1101                	addi	sp,sp,-32
 3e2:	ec06                	sd	ra,24(sp)
 3e4:	e822                	sd	s0,16(sp)
 3e6:	1000                	addi	s0,sp,32
 3e8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3ec:	4605                	li	a2,1
 3ee:	fef40593          	addi	a1,s0,-17
 3f2:	00000097          	auipc	ra,0x0
 3f6:	f56080e7          	jalr	-170(ra) # 348 <write>
}
 3fa:	60e2                	ld	ra,24(sp)
 3fc:	6442                	ld	s0,16(sp)
 3fe:	6105                	addi	sp,sp,32
 400:	8082                	ret

0000000000000402 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 402:	7139                	addi	sp,sp,-64
 404:	fc06                	sd	ra,56(sp)
 406:	f822                	sd	s0,48(sp)
 408:	f426                	sd	s1,40(sp)
 40a:	f04a                	sd	s2,32(sp)
 40c:	ec4e                	sd	s3,24(sp)
 40e:	0080                	addi	s0,sp,64
 410:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 412:	c299                	beqz	a3,418 <printint+0x16>
 414:	0805c963          	bltz	a1,4a6 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 418:	2581                	sext.w	a1,a1
  neg = 0;
 41a:	4881                	li	a7,0
 41c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 420:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 422:	2601                	sext.w	a2,a2
 424:	00000517          	auipc	a0,0x0
 428:	4dc50513          	addi	a0,a0,1244 # 900 <digits>
 42c:	883a                	mv	a6,a4
 42e:	2705                	addiw	a4,a4,1
 430:	02c5f7bb          	remuw	a5,a1,a2
 434:	1782                	slli	a5,a5,0x20
 436:	9381                	srli	a5,a5,0x20
 438:	97aa                	add	a5,a5,a0
 43a:	0007c783          	lbu	a5,0(a5)
 43e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 442:	0005879b          	sext.w	a5,a1
 446:	02c5d5bb          	divuw	a1,a1,a2
 44a:	0685                	addi	a3,a3,1
 44c:	fec7f0e3          	bgeu	a5,a2,42c <printint+0x2a>
  if(neg)
 450:	00088c63          	beqz	a7,468 <printint+0x66>
    buf[i++] = '-';
 454:	fd070793          	addi	a5,a4,-48
 458:	00878733          	add	a4,a5,s0
 45c:	02d00793          	li	a5,45
 460:	fef70823          	sb	a5,-16(a4)
 464:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 468:	02e05863          	blez	a4,498 <printint+0x96>
 46c:	fc040793          	addi	a5,s0,-64
 470:	00e78933          	add	s2,a5,a4
 474:	fff78993          	addi	s3,a5,-1
 478:	99ba                	add	s3,s3,a4
 47a:	377d                	addiw	a4,a4,-1
 47c:	1702                	slli	a4,a4,0x20
 47e:	9301                	srli	a4,a4,0x20
 480:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 484:	fff94583          	lbu	a1,-1(s2)
 488:	8526                	mv	a0,s1
 48a:	00000097          	auipc	ra,0x0
 48e:	f56080e7          	jalr	-170(ra) # 3e0 <putc>
  while(--i >= 0)
 492:	197d                	addi	s2,s2,-1
 494:	ff3918e3          	bne	s2,s3,484 <printint+0x82>
}
 498:	70e2                	ld	ra,56(sp)
 49a:	7442                	ld	s0,48(sp)
 49c:	74a2                	ld	s1,40(sp)
 49e:	7902                	ld	s2,32(sp)
 4a0:	69e2                	ld	s3,24(sp)
 4a2:	6121                	addi	sp,sp,64
 4a4:	8082                	ret
    x = -xx;
 4a6:	40b005bb          	negw	a1,a1
    neg = 1;
 4aa:	4885                	li	a7,1
    x = -xx;
 4ac:	bf85                	j	41c <printint+0x1a>

00000000000004ae <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4ae:	7119                	addi	sp,sp,-128
 4b0:	fc86                	sd	ra,120(sp)
 4b2:	f8a2                	sd	s0,112(sp)
 4b4:	f4a6                	sd	s1,104(sp)
 4b6:	f0ca                	sd	s2,96(sp)
 4b8:	ecce                	sd	s3,88(sp)
 4ba:	e8d2                	sd	s4,80(sp)
 4bc:	e4d6                	sd	s5,72(sp)
 4be:	e0da                	sd	s6,64(sp)
 4c0:	fc5e                	sd	s7,56(sp)
 4c2:	f862                	sd	s8,48(sp)
 4c4:	f466                	sd	s9,40(sp)
 4c6:	f06a                	sd	s10,32(sp)
 4c8:	ec6e                	sd	s11,24(sp)
 4ca:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4cc:	0005c903          	lbu	s2,0(a1)
 4d0:	18090f63          	beqz	s2,66e <vprintf+0x1c0>
 4d4:	8aaa                	mv	s5,a0
 4d6:	8b32                	mv	s6,a2
 4d8:	00158493          	addi	s1,a1,1
  state = 0;
 4dc:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4de:	02500a13          	li	s4,37
 4e2:	4c55                	li	s8,21
 4e4:	00000c97          	auipc	s9,0x0
 4e8:	3c4c8c93          	addi	s9,s9,964 # 8a8 <malloc+0x136>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4ec:	02800d93          	li	s11,40
  putc(fd, 'x');
 4f0:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4f2:	00000b97          	auipc	s7,0x0
 4f6:	40eb8b93          	addi	s7,s7,1038 # 900 <digits>
 4fa:	a839                	j	518 <vprintf+0x6a>
        putc(fd, c);
 4fc:	85ca                	mv	a1,s2
 4fe:	8556                	mv	a0,s5
 500:	00000097          	auipc	ra,0x0
 504:	ee0080e7          	jalr	-288(ra) # 3e0 <putc>
 508:	a019                	j	50e <vprintf+0x60>
    } else if(state == '%'){
 50a:	01498d63          	beq	s3,s4,524 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 50e:	0485                	addi	s1,s1,1
 510:	fff4c903          	lbu	s2,-1(s1)
 514:	14090d63          	beqz	s2,66e <vprintf+0x1c0>
    if(state == 0){
 518:	fe0999e3          	bnez	s3,50a <vprintf+0x5c>
      if(c == '%'){
 51c:	ff4910e3          	bne	s2,s4,4fc <vprintf+0x4e>
        state = '%';
 520:	89d2                	mv	s3,s4
 522:	b7f5                	j	50e <vprintf+0x60>
      if(c == 'd'){
 524:	11490c63          	beq	s2,s4,63c <vprintf+0x18e>
 528:	f9d9079b          	addiw	a5,s2,-99
 52c:	0ff7f793          	zext.b	a5,a5
 530:	10fc6e63          	bltu	s8,a5,64c <vprintf+0x19e>
 534:	f9d9079b          	addiw	a5,s2,-99
 538:	0ff7f713          	zext.b	a4,a5
 53c:	10ec6863          	bltu	s8,a4,64c <vprintf+0x19e>
 540:	00271793          	slli	a5,a4,0x2
 544:	97e6                	add	a5,a5,s9
 546:	439c                	lw	a5,0(a5)
 548:	97e6                	add	a5,a5,s9
 54a:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 54c:	008b0913          	addi	s2,s6,8
 550:	4685                	li	a3,1
 552:	4629                	li	a2,10
 554:	000b2583          	lw	a1,0(s6)
 558:	8556                	mv	a0,s5
 55a:	00000097          	auipc	ra,0x0
 55e:	ea8080e7          	jalr	-344(ra) # 402 <printint>
 562:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 564:	4981                	li	s3,0
 566:	b765                	j	50e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 568:	008b0913          	addi	s2,s6,8
 56c:	4681                	li	a3,0
 56e:	4629                	li	a2,10
 570:	000b2583          	lw	a1,0(s6)
 574:	8556                	mv	a0,s5
 576:	00000097          	auipc	ra,0x0
 57a:	e8c080e7          	jalr	-372(ra) # 402 <printint>
 57e:	8b4a                	mv	s6,s2
      state = 0;
 580:	4981                	li	s3,0
 582:	b771                	j	50e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 584:	008b0913          	addi	s2,s6,8
 588:	4681                	li	a3,0
 58a:	866a                	mv	a2,s10
 58c:	000b2583          	lw	a1,0(s6)
 590:	8556                	mv	a0,s5
 592:	00000097          	auipc	ra,0x0
 596:	e70080e7          	jalr	-400(ra) # 402 <printint>
 59a:	8b4a                	mv	s6,s2
      state = 0;
 59c:	4981                	li	s3,0
 59e:	bf85                	j	50e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5a0:	008b0793          	addi	a5,s6,8
 5a4:	f8f43423          	sd	a5,-120(s0)
 5a8:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5ac:	03000593          	li	a1,48
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	e2e080e7          	jalr	-466(ra) # 3e0 <putc>
  putc(fd, 'x');
 5ba:	07800593          	li	a1,120
 5be:	8556                	mv	a0,s5
 5c0:	00000097          	auipc	ra,0x0
 5c4:	e20080e7          	jalr	-480(ra) # 3e0 <putc>
 5c8:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5ca:	03c9d793          	srli	a5,s3,0x3c
 5ce:	97de                	add	a5,a5,s7
 5d0:	0007c583          	lbu	a1,0(a5)
 5d4:	8556                	mv	a0,s5
 5d6:	00000097          	auipc	ra,0x0
 5da:	e0a080e7          	jalr	-502(ra) # 3e0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5de:	0992                	slli	s3,s3,0x4
 5e0:	397d                	addiw	s2,s2,-1
 5e2:	fe0914e3          	bnez	s2,5ca <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5e6:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5ea:	4981                	li	s3,0
 5ec:	b70d                	j	50e <vprintf+0x60>
        s = va_arg(ap, char*);
 5ee:	008b0913          	addi	s2,s6,8
 5f2:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5f6:	02098163          	beqz	s3,618 <vprintf+0x16a>
        while(*s != 0){
 5fa:	0009c583          	lbu	a1,0(s3)
 5fe:	c5ad                	beqz	a1,668 <vprintf+0x1ba>
          putc(fd, *s);
 600:	8556                	mv	a0,s5
 602:	00000097          	auipc	ra,0x0
 606:	dde080e7          	jalr	-546(ra) # 3e0 <putc>
          s++;
 60a:	0985                	addi	s3,s3,1
        while(*s != 0){
 60c:	0009c583          	lbu	a1,0(s3)
 610:	f9e5                	bnez	a1,600 <vprintf+0x152>
        s = va_arg(ap, char*);
 612:	8b4a                	mv	s6,s2
      state = 0;
 614:	4981                	li	s3,0
 616:	bde5                	j	50e <vprintf+0x60>
          s = "(null)";
 618:	00000997          	auipc	s3,0x0
 61c:	28898993          	addi	s3,s3,648 # 8a0 <malloc+0x12e>
        while(*s != 0){
 620:	85ee                	mv	a1,s11
 622:	bff9                	j	600 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 624:	008b0913          	addi	s2,s6,8
 628:	000b4583          	lbu	a1,0(s6)
 62c:	8556                	mv	a0,s5
 62e:	00000097          	auipc	ra,0x0
 632:	db2080e7          	jalr	-590(ra) # 3e0 <putc>
 636:	8b4a                	mv	s6,s2
      state = 0;
 638:	4981                	li	s3,0
 63a:	bdd1                	j	50e <vprintf+0x60>
        putc(fd, c);
 63c:	85d2                	mv	a1,s4
 63e:	8556                	mv	a0,s5
 640:	00000097          	auipc	ra,0x0
 644:	da0080e7          	jalr	-608(ra) # 3e0 <putc>
      state = 0;
 648:	4981                	li	s3,0
 64a:	b5d1                	j	50e <vprintf+0x60>
        putc(fd, '%');
 64c:	85d2                	mv	a1,s4
 64e:	8556                	mv	a0,s5
 650:	00000097          	auipc	ra,0x0
 654:	d90080e7          	jalr	-624(ra) # 3e0 <putc>
        putc(fd, c);
 658:	85ca                	mv	a1,s2
 65a:	8556                	mv	a0,s5
 65c:	00000097          	auipc	ra,0x0
 660:	d84080e7          	jalr	-636(ra) # 3e0 <putc>
      state = 0;
 664:	4981                	li	s3,0
 666:	b565                	j	50e <vprintf+0x60>
        s = va_arg(ap, char*);
 668:	8b4a                	mv	s6,s2
      state = 0;
 66a:	4981                	li	s3,0
 66c:	b54d                	j	50e <vprintf+0x60>
    }
  }
}
 66e:	70e6                	ld	ra,120(sp)
 670:	7446                	ld	s0,112(sp)
 672:	74a6                	ld	s1,104(sp)
 674:	7906                	ld	s2,96(sp)
 676:	69e6                	ld	s3,88(sp)
 678:	6a46                	ld	s4,80(sp)
 67a:	6aa6                	ld	s5,72(sp)
 67c:	6b06                	ld	s6,64(sp)
 67e:	7be2                	ld	s7,56(sp)
 680:	7c42                	ld	s8,48(sp)
 682:	7ca2                	ld	s9,40(sp)
 684:	7d02                	ld	s10,32(sp)
 686:	6de2                	ld	s11,24(sp)
 688:	6109                	addi	sp,sp,128
 68a:	8082                	ret

000000000000068c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 68c:	715d                	addi	sp,sp,-80
 68e:	ec06                	sd	ra,24(sp)
 690:	e822                	sd	s0,16(sp)
 692:	1000                	addi	s0,sp,32
 694:	e010                	sd	a2,0(s0)
 696:	e414                	sd	a3,8(s0)
 698:	e818                	sd	a4,16(s0)
 69a:	ec1c                	sd	a5,24(s0)
 69c:	03043023          	sd	a6,32(s0)
 6a0:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6a4:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6a8:	8622                	mv	a2,s0
 6aa:	00000097          	auipc	ra,0x0
 6ae:	e04080e7          	jalr	-508(ra) # 4ae <vprintf>
}
 6b2:	60e2                	ld	ra,24(sp)
 6b4:	6442                	ld	s0,16(sp)
 6b6:	6161                	addi	sp,sp,80
 6b8:	8082                	ret

00000000000006ba <printf>:

void
printf(const char *fmt, ...)
{
 6ba:	711d                	addi	sp,sp,-96
 6bc:	ec06                	sd	ra,24(sp)
 6be:	e822                	sd	s0,16(sp)
 6c0:	1000                	addi	s0,sp,32
 6c2:	e40c                	sd	a1,8(s0)
 6c4:	e810                	sd	a2,16(s0)
 6c6:	ec14                	sd	a3,24(s0)
 6c8:	f018                	sd	a4,32(s0)
 6ca:	f41c                	sd	a5,40(s0)
 6cc:	03043823          	sd	a6,48(s0)
 6d0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6d4:	00840613          	addi	a2,s0,8
 6d8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6dc:	85aa                	mv	a1,a0
 6de:	4505                	li	a0,1
 6e0:	00000097          	auipc	ra,0x0
 6e4:	dce080e7          	jalr	-562(ra) # 4ae <vprintf>
}
 6e8:	60e2                	ld	ra,24(sp)
 6ea:	6442                	ld	s0,16(sp)
 6ec:	6125                	addi	sp,sp,96
 6ee:	8082                	ret

00000000000006f0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6f0:	1141                	addi	sp,sp,-16
 6f2:	e422                	sd	s0,8(sp)
 6f4:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6f6:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6fa:	00000797          	auipc	a5,0x0
 6fe:	21e7b783          	ld	a5,542(a5) # 918 <freep>
 702:	a02d                	j	72c <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 704:	4618                	lw	a4,8(a2)
 706:	9f2d                	addw	a4,a4,a1
 708:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 70c:	6398                	ld	a4,0(a5)
 70e:	6310                	ld	a2,0(a4)
 710:	a83d                	j	74e <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 712:	ff852703          	lw	a4,-8(a0)
 716:	9f31                	addw	a4,a4,a2
 718:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 71a:	ff053683          	ld	a3,-16(a0)
 71e:	a091                	j	762 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 720:	6398                	ld	a4,0(a5)
 722:	00e7e463          	bltu	a5,a4,72a <free+0x3a>
 726:	00e6ea63          	bltu	a3,a4,73a <free+0x4a>
{
 72a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 72c:	fed7fae3          	bgeu	a5,a3,720 <free+0x30>
 730:	6398                	ld	a4,0(a5)
 732:	00e6e463          	bltu	a3,a4,73a <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 736:	fee7eae3          	bltu	a5,a4,72a <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 73a:	ff852583          	lw	a1,-8(a0)
 73e:	6390                	ld	a2,0(a5)
 740:	02059813          	slli	a6,a1,0x20
 744:	01c85713          	srli	a4,a6,0x1c
 748:	9736                	add	a4,a4,a3
 74a:	fae60de3          	beq	a2,a4,704 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 74e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 752:	4790                	lw	a2,8(a5)
 754:	02061593          	slli	a1,a2,0x20
 758:	01c5d713          	srli	a4,a1,0x1c
 75c:	973e                	add	a4,a4,a5
 75e:	fae68ae3          	beq	a3,a4,712 <free+0x22>
    p->s.ptr = bp->s.ptr;
 762:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 764:	00000717          	auipc	a4,0x0
 768:	1af73a23          	sd	a5,436(a4) # 918 <freep>
}
 76c:	6422                	ld	s0,8(sp)
 76e:	0141                	addi	sp,sp,16
 770:	8082                	ret

0000000000000772 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 772:	7139                	addi	sp,sp,-64
 774:	fc06                	sd	ra,56(sp)
 776:	f822                	sd	s0,48(sp)
 778:	f426                	sd	s1,40(sp)
 77a:	f04a                	sd	s2,32(sp)
 77c:	ec4e                	sd	s3,24(sp)
 77e:	e852                	sd	s4,16(sp)
 780:	e456                	sd	s5,8(sp)
 782:	e05a                	sd	s6,0(sp)
 784:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 786:	02051493          	slli	s1,a0,0x20
 78a:	9081                	srli	s1,s1,0x20
 78c:	04bd                	addi	s1,s1,15
 78e:	8091                	srli	s1,s1,0x4
 790:	0014899b          	addiw	s3,s1,1
 794:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 796:	00000517          	auipc	a0,0x0
 79a:	18253503          	ld	a0,386(a0) # 918 <freep>
 79e:	c515                	beqz	a0,7ca <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7a0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7a2:	4798                	lw	a4,8(a5)
 7a4:	02977f63          	bgeu	a4,s1,7e2 <malloc+0x70>
 7a8:	8a4e                	mv	s4,s3
 7aa:	0009871b          	sext.w	a4,s3
 7ae:	6685                	lui	a3,0x1
 7b0:	00d77363          	bgeu	a4,a3,7b6 <malloc+0x44>
 7b4:	6a05                	lui	s4,0x1
 7b6:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7ba:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7be:	00000917          	auipc	s2,0x0
 7c2:	15a90913          	addi	s2,s2,346 # 918 <freep>
  if(p == (char*)-1)
 7c6:	5afd                	li	s5,-1
 7c8:	a895                	j	83c <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7ca:	00000797          	auipc	a5,0x0
 7ce:	15678793          	addi	a5,a5,342 # 920 <base>
 7d2:	00000717          	auipc	a4,0x0
 7d6:	14f73323          	sd	a5,326(a4) # 918 <freep>
 7da:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7dc:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7e0:	b7e1                	j	7a8 <malloc+0x36>
      if(p->s.size == nunits)
 7e2:	02e48c63          	beq	s1,a4,81a <malloc+0xa8>
        p->s.size -= nunits;
 7e6:	4137073b          	subw	a4,a4,s3
 7ea:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7ec:	02071693          	slli	a3,a4,0x20
 7f0:	01c6d713          	srli	a4,a3,0x1c
 7f4:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7f6:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7fa:	00000717          	auipc	a4,0x0
 7fe:	10a73f23          	sd	a0,286(a4) # 918 <freep>
      return (void*)(p + 1);
 802:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 806:	70e2                	ld	ra,56(sp)
 808:	7442                	ld	s0,48(sp)
 80a:	74a2                	ld	s1,40(sp)
 80c:	7902                	ld	s2,32(sp)
 80e:	69e2                	ld	s3,24(sp)
 810:	6a42                	ld	s4,16(sp)
 812:	6aa2                	ld	s5,8(sp)
 814:	6b02                	ld	s6,0(sp)
 816:	6121                	addi	sp,sp,64
 818:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 81a:	6398                	ld	a4,0(a5)
 81c:	e118                	sd	a4,0(a0)
 81e:	bff1                	j	7fa <malloc+0x88>
  hp->s.size = nu;
 820:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 824:	0541                	addi	a0,a0,16
 826:	00000097          	auipc	ra,0x0
 82a:	eca080e7          	jalr	-310(ra) # 6f0 <free>
  return freep;
 82e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 832:	d971                	beqz	a0,806 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 834:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 836:	4798                	lw	a4,8(a5)
 838:	fa9775e3          	bgeu	a4,s1,7e2 <malloc+0x70>
    if(p == freep)
 83c:	00093703          	ld	a4,0(s2)
 840:	853e                	mv	a0,a5
 842:	fef719e3          	bne	a4,a5,834 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 846:	8552                	mv	a0,s4
 848:	00000097          	auipc	ra,0x0
 84c:	b68080e7          	jalr	-1176(ra) # 3b0 <sbrk>
  if(p == (char*)-1)
 850:	fd5518e3          	bne	a0,s5,820 <malloc+0xae>
        return 0;
 854:	4501                	li	a0,0
 856:	bf45                	j	806 <malloc+0x94>
