
user/_uptime:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
  printf("%d\n", uptime());
   8:	00000097          	auipc	ra,0x0
   c:	328080e7          	jalr	808(ra) # 330 <uptime>
  10:	85aa                	mv	a1,a0
  12:	00000517          	auipc	a0,0x0
  16:	7be50513          	addi	a0,a0,1982 # 7d0 <malloc+0xe6>
  1a:	00000097          	auipc	ra,0x0
  1e:	618080e7          	jalr	1560(ra) # 632 <printf>
  exit(0);
  22:	4501                	li	a0,0
  24:	00000097          	auipc	ra,0x0
  28:	274080e7          	jalr	628(ra) # 298 <exit>

000000000000002c <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  2c:	1141                	addi	sp,sp,-16
  2e:	e422                	sd	s0,8(sp)
  30:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  32:	87aa                	mv	a5,a0
  34:	0585                	addi	a1,a1,1
  36:	0785                	addi	a5,a5,1
  38:	fff5c703          	lbu	a4,-1(a1)
  3c:	fee78fa3          	sb	a4,-1(a5)
  40:	fb75                	bnez	a4,34 <strcpy+0x8>
    ;
  return os;
}
  42:	6422                	ld	s0,8(sp)
  44:	0141                	addi	sp,sp,16
  46:	8082                	ret

0000000000000048 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  48:	1141                	addi	sp,sp,-16
  4a:	e422                	sd	s0,8(sp)
  4c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  4e:	00054783          	lbu	a5,0(a0)
  52:	cb91                	beqz	a5,66 <strcmp+0x1e>
  54:	0005c703          	lbu	a4,0(a1)
  58:	00f71763          	bne	a4,a5,66 <strcmp+0x1e>
    p++, q++;
  5c:	0505                	addi	a0,a0,1
  5e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  60:	00054783          	lbu	a5,0(a0)
  64:	fbe5                	bnez	a5,54 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  66:	0005c503          	lbu	a0,0(a1)
}
  6a:	40a7853b          	subw	a0,a5,a0
  6e:	6422                	ld	s0,8(sp)
  70:	0141                	addi	sp,sp,16
  72:	8082                	ret

0000000000000074 <strlen>:

uint
strlen(const char *s)
{
  74:	1141                	addi	sp,sp,-16
  76:	e422                	sd	s0,8(sp)
  78:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  7a:	00054783          	lbu	a5,0(a0)
  7e:	cf91                	beqz	a5,9a <strlen+0x26>
  80:	0505                	addi	a0,a0,1
  82:	87aa                	mv	a5,a0
  84:	4685                	li	a3,1
  86:	9e89                	subw	a3,a3,a0
  88:	00f6853b          	addw	a0,a3,a5
  8c:	0785                	addi	a5,a5,1
  8e:	fff7c703          	lbu	a4,-1(a5)
  92:	fb7d                	bnez	a4,88 <strlen+0x14>
    ;
  return n;
}
  94:	6422                	ld	s0,8(sp)
  96:	0141                	addi	sp,sp,16
  98:	8082                	ret
  for(n = 0; s[n]; n++)
  9a:	4501                	li	a0,0
  9c:	bfe5                	j	94 <strlen+0x20>

000000000000009e <memset>:

void*
memset(void *dst, int c, uint n)
{
  9e:	1141                	addi	sp,sp,-16
  a0:	e422                	sd	s0,8(sp)
  a2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  a4:	ca19                	beqz	a2,ba <memset+0x1c>
  a6:	87aa                	mv	a5,a0
  a8:	1602                	slli	a2,a2,0x20
  aa:	9201                	srli	a2,a2,0x20
  ac:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  b0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  b4:	0785                	addi	a5,a5,1
  b6:	fee79de3          	bne	a5,a4,b0 <memset+0x12>
  }
  return dst;
}
  ba:	6422                	ld	s0,8(sp)
  bc:	0141                	addi	sp,sp,16
  be:	8082                	ret

00000000000000c0 <strchr>:

char*
strchr(const char *s, char c)
{
  c0:	1141                	addi	sp,sp,-16
  c2:	e422                	sd	s0,8(sp)
  c4:	0800                	addi	s0,sp,16
  for(; *s; s++)
  c6:	00054783          	lbu	a5,0(a0)
  ca:	cb99                	beqz	a5,e0 <strchr+0x20>
    if(*s == c)
  cc:	00f58763          	beq	a1,a5,da <strchr+0x1a>
  for(; *s; s++)
  d0:	0505                	addi	a0,a0,1
  d2:	00054783          	lbu	a5,0(a0)
  d6:	fbfd                	bnez	a5,cc <strchr+0xc>
      return (char*)s;
  return 0;
  d8:	4501                	li	a0,0
}
  da:	6422                	ld	s0,8(sp)
  dc:	0141                	addi	sp,sp,16
  de:	8082                	ret
  return 0;
  e0:	4501                	li	a0,0
  e2:	bfe5                	j	da <strchr+0x1a>

00000000000000e4 <gets>:

char*
gets(char *buf, int max)
{
  e4:	711d                	addi	sp,sp,-96
  e6:	ec86                	sd	ra,88(sp)
  e8:	e8a2                	sd	s0,80(sp)
  ea:	e4a6                	sd	s1,72(sp)
  ec:	e0ca                	sd	s2,64(sp)
  ee:	fc4e                	sd	s3,56(sp)
  f0:	f852                	sd	s4,48(sp)
  f2:	f456                	sd	s5,40(sp)
  f4:	f05a                	sd	s6,32(sp)
  f6:	ec5e                	sd	s7,24(sp)
  f8:	1080                	addi	s0,sp,96
  fa:	8baa                	mv	s7,a0
  fc:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
  fe:	892a                	mv	s2,a0
 100:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 102:	4aa9                	li	s5,10
 104:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 106:	89a6                	mv	s3,s1
 108:	2485                	addiw	s1,s1,1
 10a:	0344d863          	bge	s1,s4,13a <gets+0x56>
    cc = read(0, &c, 1);
 10e:	4605                	li	a2,1
 110:	faf40593          	addi	a1,s0,-81
 114:	4501                	li	a0,0
 116:	00000097          	auipc	ra,0x0
 11a:	19a080e7          	jalr	410(ra) # 2b0 <read>
    if(cc < 1)
 11e:	00a05e63          	blez	a0,13a <gets+0x56>
    buf[i++] = c;
 122:	faf44783          	lbu	a5,-81(s0)
 126:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 12a:	01578763          	beq	a5,s5,138 <gets+0x54>
 12e:	0905                	addi	s2,s2,1
 130:	fd679be3          	bne	a5,s6,106 <gets+0x22>
  for(i=0; i+1 < max; ){
 134:	89a6                	mv	s3,s1
 136:	a011                	j	13a <gets+0x56>
 138:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 13a:	99de                	add	s3,s3,s7
 13c:	00098023          	sb	zero,0(s3)
  return buf;
}
 140:	855e                	mv	a0,s7
 142:	60e6                	ld	ra,88(sp)
 144:	6446                	ld	s0,80(sp)
 146:	64a6                	ld	s1,72(sp)
 148:	6906                	ld	s2,64(sp)
 14a:	79e2                	ld	s3,56(sp)
 14c:	7a42                	ld	s4,48(sp)
 14e:	7aa2                	ld	s5,40(sp)
 150:	7b02                	ld	s6,32(sp)
 152:	6be2                	ld	s7,24(sp)
 154:	6125                	addi	sp,sp,96
 156:	8082                	ret

0000000000000158 <stat>:

int
stat(const char *n, struct stat *st)
{
 158:	1101                	addi	sp,sp,-32
 15a:	ec06                	sd	ra,24(sp)
 15c:	e822                	sd	s0,16(sp)
 15e:	e426                	sd	s1,8(sp)
 160:	e04a                	sd	s2,0(sp)
 162:	1000                	addi	s0,sp,32
 164:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 166:	4581                	li	a1,0
 168:	00000097          	auipc	ra,0x0
 16c:	170080e7          	jalr	368(ra) # 2d8 <open>
  if(fd < 0)
 170:	02054563          	bltz	a0,19a <stat+0x42>
 174:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 176:	85ca                	mv	a1,s2
 178:	00000097          	auipc	ra,0x0
 17c:	178080e7          	jalr	376(ra) # 2f0 <fstat>
 180:	892a                	mv	s2,a0
  close(fd);
 182:	8526                	mv	a0,s1
 184:	00000097          	auipc	ra,0x0
 188:	13c080e7          	jalr	316(ra) # 2c0 <close>
  return r;
}
 18c:	854a                	mv	a0,s2
 18e:	60e2                	ld	ra,24(sp)
 190:	6442                	ld	s0,16(sp)
 192:	64a2                	ld	s1,8(sp)
 194:	6902                	ld	s2,0(sp)
 196:	6105                	addi	sp,sp,32
 198:	8082                	ret
    return -1;
 19a:	597d                	li	s2,-1
 19c:	bfc5                	j	18c <stat+0x34>

000000000000019e <atoi>:

int
atoi(const char *s)
{
 19e:	1141                	addi	sp,sp,-16
 1a0:	e422                	sd	s0,8(sp)
 1a2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1a4:	00054683          	lbu	a3,0(a0)
 1a8:	fd06879b          	addiw	a5,a3,-48
 1ac:	0ff7f793          	zext.b	a5,a5
 1b0:	4625                	li	a2,9
 1b2:	02f66863          	bltu	a2,a5,1e2 <atoi+0x44>
 1b6:	872a                	mv	a4,a0
  n = 0;
 1b8:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1ba:	0705                	addi	a4,a4,1
 1bc:	0025179b          	slliw	a5,a0,0x2
 1c0:	9fa9                	addw	a5,a5,a0
 1c2:	0017979b          	slliw	a5,a5,0x1
 1c6:	9fb5                	addw	a5,a5,a3
 1c8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1cc:	00074683          	lbu	a3,0(a4)
 1d0:	fd06879b          	addiw	a5,a3,-48
 1d4:	0ff7f793          	zext.b	a5,a5
 1d8:	fef671e3          	bgeu	a2,a5,1ba <atoi+0x1c>
  return n;
}
 1dc:	6422                	ld	s0,8(sp)
 1de:	0141                	addi	sp,sp,16
 1e0:	8082                	ret
  n = 0;
 1e2:	4501                	li	a0,0
 1e4:	bfe5                	j	1dc <atoi+0x3e>

00000000000001e6 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1e6:	1141                	addi	sp,sp,-16
 1e8:	e422                	sd	s0,8(sp)
 1ea:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 1ec:	02b57463          	bgeu	a0,a1,214 <memmove+0x2e>
    while(n-- > 0)
 1f0:	00c05f63          	blez	a2,20e <memmove+0x28>
 1f4:	1602                	slli	a2,a2,0x20
 1f6:	9201                	srli	a2,a2,0x20
 1f8:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 1fc:	872a                	mv	a4,a0
      *dst++ = *src++;
 1fe:	0585                	addi	a1,a1,1
 200:	0705                	addi	a4,a4,1
 202:	fff5c683          	lbu	a3,-1(a1)
 206:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 20a:	fee79ae3          	bne	a5,a4,1fe <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 20e:	6422                	ld	s0,8(sp)
 210:	0141                	addi	sp,sp,16
 212:	8082                	ret
    dst += n;
 214:	00c50733          	add	a4,a0,a2
    src += n;
 218:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 21a:	fec05ae3          	blez	a2,20e <memmove+0x28>
 21e:	fff6079b          	addiw	a5,a2,-1
 222:	1782                	slli	a5,a5,0x20
 224:	9381                	srli	a5,a5,0x20
 226:	fff7c793          	not	a5,a5
 22a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 22c:	15fd                	addi	a1,a1,-1
 22e:	177d                	addi	a4,a4,-1
 230:	0005c683          	lbu	a3,0(a1)
 234:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 238:	fee79ae3          	bne	a5,a4,22c <memmove+0x46>
 23c:	bfc9                	j	20e <memmove+0x28>

000000000000023e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 23e:	1141                	addi	sp,sp,-16
 240:	e422                	sd	s0,8(sp)
 242:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 244:	ca05                	beqz	a2,274 <memcmp+0x36>
 246:	fff6069b          	addiw	a3,a2,-1
 24a:	1682                	slli	a3,a3,0x20
 24c:	9281                	srli	a3,a3,0x20
 24e:	0685                	addi	a3,a3,1
 250:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 252:	00054783          	lbu	a5,0(a0)
 256:	0005c703          	lbu	a4,0(a1)
 25a:	00e79863          	bne	a5,a4,26a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 25e:	0505                	addi	a0,a0,1
    p2++;
 260:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 262:	fed518e3          	bne	a0,a3,252 <memcmp+0x14>
  }
  return 0;
 266:	4501                	li	a0,0
 268:	a019                	j	26e <memcmp+0x30>
      return *p1 - *p2;
 26a:	40e7853b          	subw	a0,a5,a4
}
 26e:	6422                	ld	s0,8(sp)
 270:	0141                	addi	sp,sp,16
 272:	8082                	ret
  return 0;
 274:	4501                	li	a0,0
 276:	bfe5                	j	26e <memcmp+0x30>

0000000000000278 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 278:	1141                	addi	sp,sp,-16
 27a:	e406                	sd	ra,8(sp)
 27c:	e022                	sd	s0,0(sp)
 27e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 280:	00000097          	auipc	ra,0x0
 284:	f66080e7          	jalr	-154(ra) # 1e6 <memmove>
}
 288:	60a2                	ld	ra,8(sp)
 28a:	6402                	ld	s0,0(sp)
 28c:	0141                	addi	sp,sp,16
 28e:	8082                	ret

0000000000000290 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 290:	4885                	li	a7,1
 ecall
 292:	00000073          	ecall
 ret
 296:	8082                	ret

0000000000000298 <exit>:
.global exit
exit:
 li a7, SYS_exit
 298:	4889                	li	a7,2
 ecall
 29a:	00000073          	ecall
 ret
 29e:	8082                	ret

00000000000002a0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2a0:	488d                	li	a7,3
 ecall
 2a2:	00000073          	ecall
 ret
 2a6:	8082                	ret

00000000000002a8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2a8:	4891                	li	a7,4
 ecall
 2aa:	00000073          	ecall
 ret
 2ae:	8082                	ret

00000000000002b0 <read>:
.global read
read:
 li a7, SYS_read
 2b0:	4895                	li	a7,5
 ecall
 2b2:	00000073          	ecall
 ret
 2b6:	8082                	ret

00000000000002b8 <write>:
.global write
write:
 li a7, SYS_write
 2b8:	48c1                	li	a7,16
 ecall
 2ba:	00000073          	ecall
 ret
 2be:	8082                	ret

00000000000002c0 <close>:
.global close
close:
 li a7, SYS_close
 2c0:	48d5                	li	a7,21
 ecall
 2c2:	00000073          	ecall
 ret
 2c6:	8082                	ret

00000000000002c8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2c8:	4899                	li	a7,6
 ecall
 2ca:	00000073          	ecall
 ret
 2ce:	8082                	ret

00000000000002d0 <exec>:
.global exec
exec:
 li a7, SYS_exec
 2d0:	489d                	li	a7,7
 ecall
 2d2:	00000073          	ecall
 ret
 2d6:	8082                	ret

00000000000002d8 <open>:
.global open
open:
 li a7, SYS_open
 2d8:	48bd                	li	a7,15
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2e0:	48c5                	li	a7,17
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 2e8:	48c9                	li	a7,18
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 2f0:	48a1                	li	a7,8
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <link>:
.global link
link:
 li a7, SYS_link
 2f8:	48cd                	li	a7,19
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 300:	48d1                	li	a7,20
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 308:	48a5                	li	a7,9
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <dup>:
.global dup
dup:
 li a7, SYS_dup
 310:	48a9                	li	a7,10
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 318:	48ad                	li	a7,11
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 320:	48b1                	li	a7,12
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 328:	48b5                	li	a7,13
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 330:	48b9                	li	a7,14
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <getppid>:
.global getppid
getppid:
 li a7, SYS_getppid
 338:	48d9                	li	a7,22
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <yield>:
.global yield
yield:
 li a7, SYS_yield
 340:	48dd                	li	a7,23
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <getpa>:
.global getpa
getpa:
 li a7, SYS_getpa
 348:	48e1                	li	a7,24
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <waitpid>:
.global waitpid
waitpid:
 li a7, SYS_waitpid
 350:	48e5                	li	a7,25
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 358:	1101                	addi	sp,sp,-32
 35a:	ec06                	sd	ra,24(sp)
 35c:	e822                	sd	s0,16(sp)
 35e:	1000                	addi	s0,sp,32
 360:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 364:	4605                	li	a2,1
 366:	fef40593          	addi	a1,s0,-17
 36a:	00000097          	auipc	ra,0x0
 36e:	f4e080e7          	jalr	-178(ra) # 2b8 <write>
}
 372:	60e2                	ld	ra,24(sp)
 374:	6442                	ld	s0,16(sp)
 376:	6105                	addi	sp,sp,32
 378:	8082                	ret

000000000000037a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 37a:	7139                	addi	sp,sp,-64
 37c:	fc06                	sd	ra,56(sp)
 37e:	f822                	sd	s0,48(sp)
 380:	f426                	sd	s1,40(sp)
 382:	f04a                	sd	s2,32(sp)
 384:	ec4e                	sd	s3,24(sp)
 386:	0080                	addi	s0,sp,64
 388:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 38a:	c299                	beqz	a3,390 <printint+0x16>
 38c:	0805c963          	bltz	a1,41e <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 390:	2581                	sext.w	a1,a1
  neg = 0;
 392:	4881                	li	a7,0
 394:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 398:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 39a:	2601                	sext.w	a2,a2
 39c:	00000517          	auipc	a0,0x0
 3a0:	49c50513          	addi	a0,a0,1180 # 838 <digits>
 3a4:	883a                	mv	a6,a4
 3a6:	2705                	addiw	a4,a4,1
 3a8:	02c5f7bb          	remuw	a5,a1,a2
 3ac:	1782                	slli	a5,a5,0x20
 3ae:	9381                	srli	a5,a5,0x20
 3b0:	97aa                	add	a5,a5,a0
 3b2:	0007c783          	lbu	a5,0(a5)
 3b6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3ba:	0005879b          	sext.w	a5,a1
 3be:	02c5d5bb          	divuw	a1,a1,a2
 3c2:	0685                	addi	a3,a3,1
 3c4:	fec7f0e3          	bgeu	a5,a2,3a4 <printint+0x2a>
  if(neg)
 3c8:	00088c63          	beqz	a7,3e0 <printint+0x66>
    buf[i++] = '-';
 3cc:	fd070793          	addi	a5,a4,-48
 3d0:	00878733          	add	a4,a5,s0
 3d4:	02d00793          	li	a5,45
 3d8:	fef70823          	sb	a5,-16(a4)
 3dc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3e0:	02e05863          	blez	a4,410 <printint+0x96>
 3e4:	fc040793          	addi	a5,s0,-64
 3e8:	00e78933          	add	s2,a5,a4
 3ec:	fff78993          	addi	s3,a5,-1
 3f0:	99ba                	add	s3,s3,a4
 3f2:	377d                	addiw	a4,a4,-1
 3f4:	1702                	slli	a4,a4,0x20
 3f6:	9301                	srli	a4,a4,0x20
 3f8:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3fc:	fff94583          	lbu	a1,-1(s2)
 400:	8526                	mv	a0,s1
 402:	00000097          	auipc	ra,0x0
 406:	f56080e7          	jalr	-170(ra) # 358 <putc>
  while(--i >= 0)
 40a:	197d                	addi	s2,s2,-1
 40c:	ff3918e3          	bne	s2,s3,3fc <printint+0x82>
}
 410:	70e2                	ld	ra,56(sp)
 412:	7442                	ld	s0,48(sp)
 414:	74a2                	ld	s1,40(sp)
 416:	7902                	ld	s2,32(sp)
 418:	69e2                	ld	s3,24(sp)
 41a:	6121                	addi	sp,sp,64
 41c:	8082                	ret
    x = -xx;
 41e:	40b005bb          	negw	a1,a1
    neg = 1;
 422:	4885                	li	a7,1
    x = -xx;
 424:	bf85                	j	394 <printint+0x1a>

0000000000000426 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 426:	7119                	addi	sp,sp,-128
 428:	fc86                	sd	ra,120(sp)
 42a:	f8a2                	sd	s0,112(sp)
 42c:	f4a6                	sd	s1,104(sp)
 42e:	f0ca                	sd	s2,96(sp)
 430:	ecce                	sd	s3,88(sp)
 432:	e8d2                	sd	s4,80(sp)
 434:	e4d6                	sd	s5,72(sp)
 436:	e0da                	sd	s6,64(sp)
 438:	fc5e                	sd	s7,56(sp)
 43a:	f862                	sd	s8,48(sp)
 43c:	f466                	sd	s9,40(sp)
 43e:	f06a                	sd	s10,32(sp)
 440:	ec6e                	sd	s11,24(sp)
 442:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 444:	0005c903          	lbu	s2,0(a1)
 448:	18090f63          	beqz	s2,5e6 <vprintf+0x1c0>
 44c:	8aaa                	mv	s5,a0
 44e:	8b32                	mv	s6,a2
 450:	00158493          	addi	s1,a1,1
  state = 0;
 454:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 456:	02500a13          	li	s4,37
 45a:	4c55                	li	s8,21
 45c:	00000c97          	auipc	s9,0x0
 460:	384c8c93          	addi	s9,s9,900 # 7e0 <malloc+0xf6>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 464:	02800d93          	li	s11,40
  putc(fd, 'x');
 468:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 46a:	00000b97          	auipc	s7,0x0
 46e:	3ceb8b93          	addi	s7,s7,974 # 838 <digits>
 472:	a839                	j	490 <vprintf+0x6a>
        putc(fd, c);
 474:	85ca                	mv	a1,s2
 476:	8556                	mv	a0,s5
 478:	00000097          	auipc	ra,0x0
 47c:	ee0080e7          	jalr	-288(ra) # 358 <putc>
 480:	a019                	j	486 <vprintf+0x60>
    } else if(state == '%'){
 482:	01498d63          	beq	s3,s4,49c <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 486:	0485                	addi	s1,s1,1
 488:	fff4c903          	lbu	s2,-1(s1)
 48c:	14090d63          	beqz	s2,5e6 <vprintf+0x1c0>
    if(state == 0){
 490:	fe0999e3          	bnez	s3,482 <vprintf+0x5c>
      if(c == '%'){
 494:	ff4910e3          	bne	s2,s4,474 <vprintf+0x4e>
        state = '%';
 498:	89d2                	mv	s3,s4
 49a:	b7f5                	j	486 <vprintf+0x60>
      if(c == 'd'){
 49c:	11490c63          	beq	s2,s4,5b4 <vprintf+0x18e>
 4a0:	f9d9079b          	addiw	a5,s2,-99
 4a4:	0ff7f793          	zext.b	a5,a5
 4a8:	10fc6e63          	bltu	s8,a5,5c4 <vprintf+0x19e>
 4ac:	f9d9079b          	addiw	a5,s2,-99
 4b0:	0ff7f713          	zext.b	a4,a5
 4b4:	10ec6863          	bltu	s8,a4,5c4 <vprintf+0x19e>
 4b8:	00271793          	slli	a5,a4,0x2
 4bc:	97e6                	add	a5,a5,s9
 4be:	439c                	lw	a5,0(a5)
 4c0:	97e6                	add	a5,a5,s9
 4c2:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4c4:	008b0913          	addi	s2,s6,8
 4c8:	4685                	li	a3,1
 4ca:	4629                	li	a2,10
 4cc:	000b2583          	lw	a1,0(s6)
 4d0:	8556                	mv	a0,s5
 4d2:	00000097          	auipc	ra,0x0
 4d6:	ea8080e7          	jalr	-344(ra) # 37a <printint>
 4da:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 4dc:	4981                	li	s3,0
 4de:	b765                	j	486 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4e0:	008b0913          	addi	s2,s6,8
 4e4:	4681                	li	a3,0
 4e6:	4629                	li	a2,10
 4e8:	000b2583          	lw	a1,0(s6)
 4ec:	8556                	mv	a0,s5
 4ee:	00000097          	auipc	ra,0x0
 4f2:	e8c080e7          	jalr	-372(ra) # 37a <printint>
 4f6:	8b4a                	mv	s6,s2
      state = 0;
 4f8:	4981                	li	s3,0
 4fa:	b771                	j	486 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 4fc:	008b0913          	addi	s2,s6,8
 500:	4681                	li	a3,0
 502:	866a                	mv	a2,s10
 504:	000b2583          	lw	a1,0(s6)
 508:	8556                	mv	a0,s5
 50a:	00000097          	auipc	ra,0x0
 50e:	e70080e7          	jalr	-400(ra) # 37a <printint>
 512:	8b4a                	mv	s6,s2
      state = 0;
 514:	4981                	li	s3,0
 516:	bf85                	j	486 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 518:	008b0793          	addi	a5,s6,8
 51c:	f8f43423          	sd	a5,-120(s0)
 520:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 524:	03000593          	li	a1,48
 528:	8556                	mv	a0,s5
 52a:	00000097          	auipc	ra,0x0
 52e:	e2e080e7          	jalr	-466(ra) # 358 <putc>
  putc(fd, 'x');
 532:	07800593          	li	a1,120
 536:	8556                	mv	a0,s5
 538:	00000097          	auipc	ra,0x0
 53c:	e20080e7          	jalr	-480(ra) # 358 <putc>
 540:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 542:	03c9d793          	srli	a5,s3,0x3c
 546:	97de                	add	a5,a5,s7
 548:	0007c583          	lbu	a1,0(a5)
 54c:	8556                	mv	a0,s5
 54e:	00000097          	auipc	ra,0x0
 552:	e0a080e7          	jalr	-502(ra) # 358 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 556:	0992                	slli	s3,s3,0x4
 558:	397d                	addiw	s2,s2,-1
 55a:	fe0914e3          	bnez	s2,542 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 55e:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 562:	4981                	li	s3,0
 564:	b70d                	j	486 <vprintf+0x60>
        s = va_arg(ap, char*);
 566:	008b0913          	addi	s2,s6,8
 56a:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 56e:	02098163          	beqz	s3,590 <vprintf+0x16a>
        while(*s != 0){
 572:	0009c583          	lbu	a1,0(s3)
 576:	c5ad                	beqz	a1,5e0 <vprintf+0x1ba>
          putc(fd, *s);
 578:	8556                	mv	a0,s5
 57a:	00000097          	auipc	ra,0x0
 57e:	dde080e7          	jalr	-546(ra) # 358 <putc>
          s++;
 582:	0985                	addi	s3,s3,1
        while(*s != 0){
 584:	0009c583          	lbu	a1,0(s3)
 588:	f9e5                	bnez	a1,578 <vprintf+0x152>
        s = va_arg(ap, char*);
 58a:	8b4a                	mv	s6,s2
      state = 0;
 58c:	4981                	li	s3,0
 58e:	bde5                	j	486 <vprintf+0x60>
          s = "(null)";
 590:	00000997          	auipc	s3,0x0
 594:	24898993          	addi	s3,s3,584 # 7d8 <malloc+0xee>
        while(*s != 0){
 598:	85ee                	mv	a1,s11
 59a:	bff9                	j	578 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 59c:	008b0913          	addi	s2,s6,8
 5a0:	000b4583          	lbu	a1,0(s6)
 5a4:	8556                	mv	a0,s5
 5a6:	00000097          	auipc	ra,0x0
 5aa:	db2080e7          	jalr	-590(ra) # 358 <putc>
 5ae:	8b4a                	mv	s6,s2
      state = 0;
 5b0:	4981                	li	s3,0
 5b2:	bdd1                	j	486 <vprintf+0x60>
        putc(fd, c);
 5b4:	85d2                	mv	a1,s4
 5b6:	8556                	mv	a0,s5
 5b8:	00000097          	auipc	ra,0x0
 5bc:	da0080e7          	jalr	-608(ra) # 358 <putc>
      state = 0;
 5c0:	4981                	li	s3,0
 5c2:	b5d1                	j	486 <vprintf+0x60>
        putc(fd, '%');
 5c4:	85d2                	mv	a1,s4
 5c6:	8556                	mv	a0,s5
 5c8:	00000097          	auipc	ra,0x0
 5cc:	d90080e7          	jalr	-624(ra) # 358 <putc>
        putc(fd, c);
 5d0:	85ca                	mv	a1,s2
 5d2:	8556                	mv	a0,s5
 5d4:	00000097          	auipc	ra,0x0
 5d8:	d84080e7          	jalr	-636(ra) # 358 <putc>
      state = 0;
 5dc:	4981                	li	s3,0
 5de:	b565                	j	486 <vprintf+0x60>
        s = va_arg(ap, char*);
 5e0:	8b4a                	mv	s6,s2
      state = 0;
 5e2:	4981                	li	s3,0
 5e4:	b54d                	j	486 <vprintf+0x60>
    }
  }
}
 5e6:	70e6                	ld	ra,120(sp)
 5e8:	7446                	ld	s0,112(sp)
 5ea:	74a6                	ld	s1,104(sp)
 5ec:	7906                	ld	s2,96(sp)
 5ee:	69e6                	ld	s3,88(sp)
 5f0:	6a46                	ld	s4,80(sp)
 5f2:	6aa6                	ld	s5,72(sp)
 5f4:	6b06                	ld	s6,64(sp)
 5f6:	7be2                	ld	s7,56(sp)
 5f8:	7c42                	ld	s8,48(sp)
 5fa:	7ca2                	ld	s9,40(sp)
 5fc:	7d02                	ld	s10,32(sp)
 5fe:	6de2                	ld	s11,24(sp)
 600:	6109                	addi	sp,sp,128
 602:	8082                	ret

0000000000000604 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 604:	715d                	addi	sp,sp,-80
 606:	ec06                	sd	ra,24(sp)
 608:	e822                	sd	s0,16(sp)
 60a:	1000                	addi	s0,sp,32
 60c:	e010                	sd	a2,0(s0)
 60e:	e414                	sd	a3,8(s0)
 610:	e818                	sd	a4,16(s0)
 612:	ec1c                	sd	a5,24(s0)
 614:	03043023          	sd	a6,32(s0)
 618:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 61c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 620:	8622                	mv	a2,s0
 622:	00000097          	auipc	ra,0x0
 626:	e04080e7          	jalr	-508(ra) # 426 <vprintf>
}
 62a:	60e2                	ld	ra,24(sp)
 62c:	6442                	ld	s0,16(sp)
 62e:	6161                	addi	sp,sp,80
 630:	8082                	ret

0000000000000632 <printf>:

void
printf(const char *fmt, ...)
{
 632:	711d                	addi	sp,sp,-96
 634:	ec06                	sd	ra,24(sp)
 636:	e822                	sd	s0,16(sp)
 638:	1000                	addi	s0,sp,32
 63a:	e40c                	sd	a1,8(s0)
 63c:	e810                	sd	a2,16(s0)
 63e:	ec14                	sd	a3,24(s0)
 640:	f018                	sd	a4,32(s0)
 642:	f41c                	sd	a5,40(s0)
 644:	03043823          	sd	a6,48(s0)
 648:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 64c:	00840613          	addi	a2,s0,8
 650:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 654:	85aa                	mv	a1,a0
 656:	4505                	li	a0,1
 658:	00000097          	auipc	ra,0x0
 65c:	dce080e7          	jalr	-562(ra) # 426 <vprintf>
}
 660:	60e2                	ld	ra,24(sp)
 662:	6442                	ld	s0,16(sp)
 664:	6125                	addi	sp,sp,96
 666:	8082                	ret

0000000000000668 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 668:	1141                	addi	sp,sp,-16
 66a:	e422                	sd	s0,8(sp)
 66c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 66e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 672:	00000797          	auipc	a5,0x0
 676:	1de7b783          	ld	a5,478(a5) # 850 <freep>
 67a:	a02d                	j	6a4 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 67c:	4618                	lw	a4,8(a2)
 67e:	9f2d                	addw	a4,a4,a1
 680:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 684:	6398                	ld	a4,0(a5)
 686:	6310                	ld	a2,0(a4)
 688:	a83d                	j	6c6 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 68a:	ff852703          	lw	a4,-8(a0)
 68e:	9f31                	addw	a4,a4,a2
 690:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 692:	ff053683          	ld	a3,-16(a0)
 696:	a091                	j	6da <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 698:	6398                	ld	a4,0(a5)
 69a:	00e7e463          	bltu	a5,a4,6a2 <free+0x3a>
 69e:	00e6ea63          	bltu	a3,a4,6b2 <free+0x4a>
{
 6a2:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6a4:	fed7fae3          	bgeu	a5,a3,698 <free+0x30>
 6a8:	6398                	ld	a4,0(a5)
 6aa:	00e6e463          	bltu	a3,a4,6b2 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6ae:	fee7eae3          	bltu	a5,a4,6a2 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6b2:	ff852583          	lw	a1,-8(a0)
 6b6:	6390                	ld	a2,0(a5)
 6b8:	02059813          	slli	a6,a1,0x20
 6bc:	01c85713          	srli	a4,a6,0x1c
 6c0:	9736                	add	a4,a4,a3
 6c2:	fae60de3          	beq	a2,a4,67c <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6c6:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6ca:	4790                	lw	a2,8(a5)
 6cc:	02061593          	slli	a1,a2,0x20
 6d0:	01c5d713          	srli	a4,a1,0x1c
 6d4:	973e                	add	a4,a4,a5
 6d6:	fae68ae3          	beq	a3,a4,68a <free+0x22>
    p->s.ptr = bp->s.ptr;
 6da:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 6dc:	00000717          	auipc	a4,0x0
 6e0:	16f73a23          	sd	a5,372(a4) # 850 <freep>
}
 6e4:	6422                	ld	s0,8(sp)
 6e6:	0141                	addi	sp,sp,16
 6e8:	8082                	ret

00000000000006ea <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6ea:	7139                	addi	sp,sp,-64
 6ec:	fc06                	sd	ra,56(sp)
 6ee:	f822                	sd	s0,48(sp)
 6f0:	f426                	sd	s1,40(sp)
 6f2:	f04a                	sd	s2,32(sp)
 6f4:	ec4e                	sd	s3,24(sp)
 6f6:	e852                	sd	s4,16(sp)
 6f8:	e456                	sd	s5,8(sp)
 6fa:	e05a                	sd	s6,0(sp)
 6fc:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6fe:	02051493          	slli	s1,a0,0x20
 702:	9081                	srli	s1,s1,0x20
 704:	04bd                	addi	s1,s1,15
 706:	8091                	srli	s1,s1,0x4
 708:	0014899b          	addiw	s3,s1,1
 70c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 70e:	00000517          	auipc	a0,0x0
 712:	14253503          	ld	a0,322(a0) # 850 <freep>
 716:	c515                	beqz	a0,742 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 718:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 71a:	4798                	lw	a4,8(a5)
 71c:	02977f63          	bgeu	a4,s1,75a <malloc+0x70>
 720:	8a4e                	mv	s4,s3
 722:	0009871b          	sext.w	a4,s3
 726:	6685                	lui	a3,0x1
 728:	00d77363          	bgeu	a4,a3,72e <malloc+0x44>
 72c:	6a05                	lui	s4,0x1
 72e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 732:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 736:	00000917          	auipc	s2,0x0
 73a:	11a90913          	addi	s2,s2,282 # 850 <freep>
  if(p == (char*)-1)
 73e:	5afd                	li	s5,-1
 740:	a895                	j	7b4 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 742:	00000797          	auipc	a5,0x0
 746:	11678793          	addi	a5,a5,278 # 858 <base>
 74a:	00000717          	auipc	a4,0x0
 74e:	10f73323          	sd	a5,262(a4) # 850 <freep>
 752:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 754:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 758:	b7e1                	j	720 <malloc+0x36>
      if(p->s.size == nunits)
 75a:	02e48c63          	beq	s1,a4,792 <malloc+0xa8>
        p->s.size -= nunits;
 75e:	4137073b          	subw	a4,a4,s3
 762:	c798                	sw	a4,8(a5)
        p += p->s.size;
 764:	02071693          	slli	a3,a4,0x20
 768:	01c6d713          	srli	a4,a3,0x1c
 76c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 76e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 772:	00000717          	auipc	a4,0x0
 776:	0ca73f23          	sd	a0,222(a4) # 850 <freep>
      return (void*)(p + 1);
 77a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 77e:	70e2                	ld	ra,56(sp)
 780:	7442                	ld	s0,48(sp)
 782:	74a2                	ld	s1,40(sp)
 784:	7902                	ld	s2,32(sp)
 786:	69e2                	ld	s3,24(sp)
 788:	6a42                	ld	s4,16(sp)
 78a:	6aa2                	ld	s5,8(sp)
 78c:	6b02                	ld	s6,0(sp)
 78e:	6121                	addi	sp,sp,64
 790:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 792:	6398                	ld	a4,0(a5)
 794:	e118                	sd	a4,0(a0)
 796:	bff1                	j	772 <malloc+0x88>
  hp->s.size = nu;
 798:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 79c:	0541                	addi	a0,a0,16
 79e:	00000097          	auipc	ra,0x0
 7a2:	eca080e7          	jalr	-310(ra) # 668 <free>
  return freep;
 7a6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7aa:	d971                	beqz	a0,77e <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7ac:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7ae:	4798                	lw	a4,8(a5)
 7b0:	fa9775e3          	bgeu	a4,s1,75a <malloc+0x70>
    if(p == freep)
 7b4:	00093703          	ld	a4,0(s2)
 7b8:	853e                	mv	a0,a5
 7ba:	fef719e3          	bne	a4,a5,7ac <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7be:	8552                	mv	a0,s4
 7c0:	00000097          	auipc	ra,0x0
 7c4:	b60080e7          	jalr	-1184(ra) # 320 <sbrk>
  if(p == (char*)-1)
 7c8:	fd5518e3          	bne	a0,s5,798 <malloc+0xae>
        return 0;
 7cc:	4501                	li	a0,0
 7ce:	bf45                	j	77e <malloc+0x94>
