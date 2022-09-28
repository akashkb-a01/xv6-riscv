
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	97013103          	ld	sp,-1680(sp) # 80008970 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ff070713          	addi	a4,a4,-16 # 80009040 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	15e78793          	addi	a5,a5,350 # 800061c0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	35e080e7          	jalr	862(ra) # 80002488 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	77e080e7          	jalr	1918(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	eb2080e7          	jalr	-334(ra) # 80002082 <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	226080e7          	jalr	550(ra) # 80002432 <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	1f2080e7          	jalr	498(ra) # 800024de <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	dce080e7          	jalr	-562(ra) # 8000220e <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	4a678793          	addi	a5,a5,1190 # 80021918 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7c70713          	addi	a4,a4,-900 # 80000100 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00011797          	auipc	a5,0x11
    8000054a:	ce07ad23          	sw	zero,-774(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00009717          	auipc	a4,0x9
    8000057e:	a8f72323          	sw	a5,-1402(a4) # 80009000 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00011d97          	auipc	s11,0x11
    800005ba:	c8adad83          	lw	s11,-886(s11) # 80011240 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	c3450513          	addi	a0,a0,-972 # 80011228 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00011517          	auipc	a0,0x11
    80000756:	ad650513          	addi	a0,a0,-1322 # 80011228 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00011497          	auipc	s1,0x11
    80000772:	aba48493          	addi	s1,s1,-1350 # 80011228 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00011517          	auipc	a0,0x11
    800007d2:	a7a50513          	addi	a0,a0,-1414 # 80011248 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00009797          	auipc	a5,0x9
    800007fe:	8067a783          	lw	a5,-2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	7d67b783          	ld	a5,2006(a5) # 80009008 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	7d673703          	ld	a4,2006(a4) # 80009010 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	980080e7          	jalr	-1664(ra) # 8000220e <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00011517          	auipc	a0,0x11
    800008ce:	97e50513          	addi	a0,a0,-1666 # 80011248 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	7267a783          	lw	a5,1830(a5) # 80009000 <panicked>
    800008e2:	c391                	beqz	a5,800008e6 <uartputc+0x2e>
    for(;;)
    800008e4:	a001                	j	800008e4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	72a73703          	ld	a4,1834(a4) # 80009010 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	71a7b783          	ld	a5,1818(a5) # 80009008 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    800008fa:	02e79b63          	bne	a5,a4,80000930 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	94a98993          	addi	s3,s3,-1718 # 80011248 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	70248493          	addi	s1,s1,1794 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	70290913          	addi	s2,s2,1794 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	768080e7          	jalr	1896(ra) # 80002082 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00011497          	auipc	s1,0x11
    80000934:	91848493          	addi	s1,s1,-1768 # 80011248 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	6ce7b623          	sd	a4,1740(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee6080e7          	jalr	-282(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	89448493          	addi	s1,s1,-1900 # 80011248 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00025797          	auipc	a5,0x25
    800009fa:	60a78793          	addi	a5,a5,1546 # 80026000 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	86a90913          	addi	s2,s2,-1942 # 80011280 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00025517          	auipc	a0,0x25
    80000acc:	53850513          	addi	a0,a0,1336 # 80026000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e10080e7          	jalr	-496(ra) # 8000197a <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	dde080e7          	jalr	-546(ra) # 8000197a <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd2080e7          	jalr	-558(ra) # 8000197a <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	dba080e7          	jalr	-582(ra) # 8000197a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d7a080e7          	jalr	-646(ra) # 8000197a <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d4e080e7          	jalr	-690(ra) # 8000197a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9001>
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	40d707bb          	subw	a5,a4,a3
    80000e06:	37fd                	addiw	a5,a5,-1
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6dc080e7          	jalr	1756(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	c32080e7          	jalr	-974(ra) # 80002aea <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	340080e7          	jalr	832(ra) # 80006200 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	008080e7          	jalr	8(ra) # 80001ed0 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88c080e7          	jalr	-1908(ra) # 80000764 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69c080e7          	jalr	1692(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68c080e7          	jalr	1676(ra) # 80000584 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67c080e7          	jalr	1660(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	992080e7          	jalr	-1646(ra) # 800018ba <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	b92080e7          	jalr	-1134(ra) # 80002ac2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	bb2080e7          	jalr	-1102(ra) # 80002aea <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	2aa080e7          	jalr	682(ra) # 800061ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	2b8080e7          	jalr	696(ra) # 80006200 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	482080e7          	jalr	1154(ra) # 800033d2 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	b10080e7          	jalr	-1264(ra) # 80003a68 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	ac2080e7          	jalr	-1342(ra) # 80004a22 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	3b8080e7          	jalr	952(ra) # 80006320 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d26080e7          	jalr	-730(ra) # 80001c96 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	560080e7          	jalr	1376(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	83a9                	srli	a5,a5,0xa
    8000108a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	777d                	lui	a4,0xfffff
    800010b2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	fff58993          	addi	s3,a1,-1
    800010ba:	99b2                	add	s3,s3,a2
    800010bc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c0:	893e                	mv	s2,a5
    800010c2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43a080e7          	jalr	1082(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	42a080e7          	jalr	1066(ra) # 8000053a <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3de080e7          	jalr	990(ra) # 8000053a <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	292080e7          	jalr	658(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	282080e7          	jalr	642(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	272080e7          	jalr	626(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	262080e7          	jalr	610(ra) # 8000053a <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6ce080e7          	jalr	1742(ra) # 800009e2 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	184080e7          	jalr	388(ra) # 8000053a <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	76fd                	lui	a3,0xfffff
    800013da:	8f75                	and	a4,a4,a3
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff5                	and	a5,a5,a3
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6785                	lui	a5,0x1
    80001422:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001424:	95be                	add	a1,a1,a5
    80001426:	77fd                	lui	a5,0xfffff
    80001428:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	554080e7          	jalr	1364(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a829                	j	800014e4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014ce:	00c79513          	slli	a0,a5,0xc
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	fde080e7          	jalr	-34(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014de:	04a1                	addi	s1,s1,8
    800014e0:	03248163          	beq	s1,s2,80001502 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014e4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e6:	00f7f713          	andi	a4,a5,15
    800014ea:	ff3701e3          	beq	a4,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ee:	8b85                	andi	a5,a5,1
    800014f0:	d7fd                	beqz	a5,800014de <freewalk+0x2e>
      panic("freewalk: leaf");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	c8650513          	addi	a0,a0,-890 # 80008178 <digits+0x138>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	040080e7          	jalr	64(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    80001502:	8552                	mv	a0,s4
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	4de080e7          	jalr	1246(ra) # 800009e2 <kfree>
}
    8000150c:	70a2                	ld	ra,40(sp)
    8000150e:	7402                	ld	s0,32(sp)
    80001510:	64e2                	ld	s1,24(sp)
    80001512:	6942                	ld	s2,16(sp)
    80001514:	69a2                	ld	s3,8(sp)
    80001516:	6a02                	ld	s4,0(sp)
    80001518:	6145                	addi	sp,sp,48
    8000151a:	8082                	ret

000000008000151c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151c:	1101                	addi	sp,sp,-32
    8000151e:	ec06                	sd	ra,24(sp)
    80001520:	e822                	sd	s0,16(sp)
    80001522:	e426                	sd	s1,8(sp)
    80001524:	1000                	addi	s0,sp,32
    80001526:	84aa                	mv	s1,a0
  if(sz > 0)
    80001528:	e999                	bnez	a1,8000153e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000152a:	8526                	mv	a0,s1
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	f84080e7          	jalr	-124(ra) # 800014b0 <freewalk>
}
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6105                	addi	sp,sp,32
    8000153c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153e:	6785                	lui	a5,0x1
    80001540:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001542:	95be                	add	a1,a1,a5
    80001544:	4685                	li	a3,1
    80001546:	00c5d613          	srli	a2,a1,0xc
    8000154a:	4581                	li	a1,0
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	d0e080e7          	jalr	-754(ra) # 8000125a <uvmunmap>
    80001554:	bfd9                	j	8000152a <uvmfree+0xe>

0000000080001556 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001556:	c679                	beqz	a2,80001624 <uvmcopy+0xce>
{
    80001558:	715d                	addi	sp,sp,-80
    8000155a:	e486                	sd	ra,72(sp)
    8000155c:	e0a2                	sd	s0,64(sp)
    8000155e:	fc26                	sd	s1,56(sp)
    80001560:	f84a                	sd	s2,48(sp)
    80001562:	f44e                	sd	s3,40(sp)
    80001564:	f052                	sd	s4,32(sp)
    80001566:	ec56                	sd	s5,24(sp)
    80001568:	e85a                	sd	s6,16(sp)
    8000156a:	e45e                	sd	s7,8(sp)
    8000156c:	0880                	addi	s0,sp,80
    8000156e:	8b2a                	mv	s6,a0
    80001570:	8aae                	mv	s5,a1
    80001572:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001574:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001576:	4601                	li	a2,0
    80001578:	85ce                	mv	a1,s3
    8000157a:	855a                	mv	a0,s6
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	a30080e7          	jalr	-1488(ra) # 80000fac <walk>
    80001584:	c531                	beqz	a0,800015d0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001586:	6118                	ld	a4,0(a0)
    80001588:	00177793          	andi	a5,a4,1
    8000158c:	cbb1                	beqz	a5,800015e0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158e:	00a75593          	srli	a1,a4,0xa
    80001592:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001596:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	546080e7          	jalr	1350(ra) # 80000ae0 <kalloc>
    800015a2:	892a                	mv	s2,a0
    800015a4:	c939                	beqz	a0,800015fa <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a6:	6605                	lui	a2,0x1
    800015a8:	85de                	mv	a1,s7
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	77e080e7          	jalr	1918(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015b2:	8726                	mv	a4,s1
    800015b4:	86ca                	mv	a3,s2
    800015b6:	6605                	lui	a2,0x1
    800015b8:	85ce                	mv	a1,s3
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	ad8080e7          	jalr	-1320(ra) # 80001094 <mappages>
    800015c4:	e515                	bnez	a0,800015f0 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	6785                	lui	a5,0x1
    800015c8:	99be                	add	s3,s3,a5
    800015ca:	fb49e6e3          	bltu	s3,s4,80001576 <uvmcopy+0x20>
    800015ce:	a081                	j	8000160e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	bb850513          	addi	a0,a0,-1096 # 80008188 <digits+0x148>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	bc850513          	addi	a0,a0,-1080 # 800081a8 <digits+0x168>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f52080e7          	jalr	-174(ra) # 8000053a <panic>
      kfree(mem);
    800015f0:	854a                	mv	a0,s2
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	3f0080e7          	jalr	1008(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015fa:	4685                	li	a3,1
    800015fc:	00c9d613          	srli	a2,s3,0xc
    80001600:	4581                	li	a1,0
    80001602:	8556                	mv	a0,s5
    80001604:	00000097          	auipc	ra,0x0
    80001608:	c56080e7          	jalr	-938(ra) # 8000125a <uvmunmap>
  return -1;
    8000160c:	557d                	li	a0,-1
}
    8000160e:	60a6                	ld	ra,72(sp)
    80001610:	6406                	ld	s0,64(sp)
    80001612:	74e2                	ld	s1,56(sp)
    80001614:	7942                	ld	s2,48(sp)
    80001616:	79a2                	ld	s3,40(sp)
    80001618:	7a02                	ld	s4,32(sp)
    8000161a:	6ae2                	ld	s5,24(sp)
    8000161c:	6b42                	ld	s6,16(sp)
    8000161e:	6ba2                	ld	s7,8(sp)
    80001620:	6161                	addi	sp,sp,80
    80001622:	8082                	ret
  return 0;
    80001624:	4501                	li	a0,0
}
    80001626:	8082                	ret

0000000080001628 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001628:	1141                	addi	sp,sp,-16
    8000162a:	e406                	sd	ra,8(sp)
    8000162c:	e022                	sd	s0,0(sp)
    8000162e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001630:	4601                	li	a2,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	97a080e7          	jalr	-1670(ra) # 80000fac <walk>
  if(pte == 0)
    8000163a:	c901                	beqz	a0,8000164a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000163c:	611c                	ld	a5,0(a0)
    8000163e:	9bbd                	andi	a5,a5,-17
    80001640:	e11c                	sd	a5,0(a0)
}
    80001642:	60a2                	ld	ra,8(sp)
    80001644:	6402                	ld	s0,0(sp)
    80001646:	0141                	addi	sp,sp,16
    80001648:	8082                	ret
    panic("uvmclear");
    8000164a:	00007517          	auipc	a0,0x7
    8000164e:	b7e50513          	addi	a0,a0,-1154 # 800081c8 <digits+0x188>
    80001652:	fffff097          	auipc	ra,0xfffff
    80001656:	ee8080e7          	jalr	-280(ra) # 8000053a <panic>

000000008000165a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000165a:	c6bd                	beqz	a3,800016c8 <copyout+0x6e>
{
    8000165c:	715d                	addi	sp,sp,-80
    8000165e:	e486                	sd	ra,72(sp)
    80001660:	e0a2                	sd	s0,64(sp)
    80001662:	fc26                	sd	s1,56(sp)
    80001664:	f84a                	sd	s2,48(sp)
    80001666:	f44e                	sd	s3,40(sp)
    80001668:	f052                	sd	s4,32(sp)
    8000166a:	ec56                	sd	s5,24(sp)
    8000166c:	e85a                	sd	s6,16(sp)
    8000166e:	e45e                	sd	s7,8(sp)
    80001670:	e062                	sd	s8,0(sp)
    80001672:	0880                	addi	s0,sp,80
    80001674:	8b2a                	mv	s6,a0
    80001676:	8c2e                	mv	s8,a1
    80001678:	8a32                	mv	s4,a2
    8000167a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000167c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167e:	6a85                	lui	s5,0x1
    80001680:	a015                	j	800016a4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001682:	9562                	add	a0,a0,s8
    80001684:	0004861b          	sext.w	a2,s1
    80001688:	85d2                	mv	a1,s4
    8000168a:	41250533          	sub	a0,a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	69a080e7          	jalr	1690(ra) # 80000d28 <memmove>

    len -= n;
    80001696:	409989b3          	sub	s3,s3,s1
    src += n;
    8000169a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000169c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a0:	02098263          	beqz	s3,800016c4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a8:	85ca                	mv	a1,s2
    800016aa:	855a                	mv	a0,s6
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	9a6080e7          	jalr	-1626(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b4:	cd01                	beqz	a0,800016cc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b6:	418904b3          	sub	s1,s2,s8
    800016ba:	94d6                	add	s1,s1,s5
    800016bc:	fc99f3e3          	bgeu	s3,s1,80001682 <copyout+0x28>
    800016c0:	84ce                	mv	s1,s3
    800016c2:	b7c1                	j	80001682 <copyout+0x28>
  }
  return 0;
    800016c4:	4501                	li	a0,0
    800016c6:	a021                	j	800016ce <copyout+0x74>
    800016c8:	4501                	li	a0,0
}
    800016ca:	8082                	ret
      return -1;
    800016cc:	557d                	li	a0,-1
}
    800016ce:	60a6                	ld	ra,72(sp)
    800016d0:	6406                	ld	s0,64(sp)
    800016d2:	74e2                	ld	s1,56(sp)
    800016d4:	7942                	ld	s2,48(sp)
    800016d6:	79a2                	ld	s3,40(sp)
    800016d8:	7a02                	ld	s4,32(sp)
    800016da:	6ae2                	ld	s5,24(sp)
    800016dc:	6b42                	ld	s6,16(sp)
    800016de:	6ba2                	ld	s7,8(sp)
    800016e0:	6c02                	ld	s8,0(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret

00000000800016e6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e6:	caa5                	beqz	a3,80001756 <copyin+0x70>
{
    800016e8:	715d                	addi	sp,sp,-80
    800016ea:	e486                	sd	ra,72(sp)
    800016ec:	e0a2                	sd	s0,64(sp)
    800016ee:	fc26                	sd	s1,56(sp)
    800016f0:	f84a                	sd	s2,48(sp)
    800016f2:	f44e                	sd	s3,40(sp)
    800016f4:	f052                	sd	s4,32(sp)
    800016f6:	ec56                	sd	s5,24(sp)
    800016f8:	e85a                	sd	s6,16(sp)
    800016fa:	e45e                	sd	s7,8(sp)
    800016fc:	e062                	sd	s8,0(sp)
    800016fe:	0880                	addi	s0,sp,80
    80001700:	8b2a                	mv	s6,a0
    80001702:	8a2e                	mv	s4,a1
    80001704:	8c32                	mv	s8,a2
    80001706:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001708:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000170a:	6a85                	lui	s5,0x1
    8000170c:	a01d                	j	80001732 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170e:	018505b3          	add	a1,a0,s8
    80001712:	0004861b          	sext.w	a2,s1
    80001716:	412585b3          	sub	a1,a1,s2
    8000171a:	8552                	mv	a0,s4
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	60c080e7          	jalr	1548(ra) # 80000d28 <memmove>

    len -= n;
    80001724:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001728:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000172a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172e:	02098263          	beqz	s3,80001752 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001732:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001736:	85ca                	mv	a1,s2
    80001738:	855a                	mv	a0,s6
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	918080e7          	jalr	-1768(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    80001742:	cd01                	beqz	a0,8000175a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001744:	418904b3          	sub	s1,s2,s8
    80001748:	94d6                	add	s1,s1,s5
    8000174a:	fc99f2e3          	bgeu	s3,s1,8000170e <copyin+0x28>
    8000174e:	84ce                	mv	s1,s3
    80001750:	bf7d                	j	8000170e <copyin+0x28>
  }
  return 0;
    80001752:	4501                	li	a0,0
    80001754:	a021                	j	8000175c <copyin+0x76>
    80001756:	4501                	li	a0,0
}
    80001758:	8082                	ret
      return -1;
    8000175a:	557d                	li	a0,-1
}
    8000175c:	60a6                	ld	ra,72(sp)
    8000175e:	6406                	ld	s0,64(sp)
    80001760:	74e2                	ld	s1,56(sp)
    80001762:	7942                	ld	s2,48(sp)
    80001764:	79a2                	ld	s3,40(sp)
    80001766:	7a02                	ld	s4,32(sp)
    80001768:	6ae2                	ld	s5,24(sp)
    8000176a:	6b42                	ld	s6,16(sp)
    8000176c:	6ba2                	ld	s7,8(sp)
    8000176e:	6c02                	ld	s8,0(sp)
    80001770:	6161                	addi	sp,sp,80
    80001772:	8082                	ret

0000000080001774 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001774:	c2dd                	beqz	a3,8000181a <copyinstr+0xa6>
{
    80001776:	715d                	addi	sp,sp,-80
    80001778:	e486                	sd	ra,72(sp)
    8000177a:	e0a2                	sd	s0,64(sp)
    8000177c:	fc26                	sd	s1,56(sp)
    8000177e:	f84a                	sd	s2,48(sp)
    80001780:	f44e                	sd	s3,40(sp)
    80001782:	f052                	sd	s4,32(sp)
    80001784:	ec56                	sd	s5,24(sp)
    80001786:	e85a                	sd	s6,16(sp)
    80001788:	e45e                	sd	s7,8(sp)
    8000178a:	0880                	addi	s0,sp,80
    8000178c:	8a2a                	mv	s4,a0
    8000178e:	8b2e                	mv	s6,a1
    80001790:	8bb2                	mv	s7,a2
    80001792:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001794:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001796:	6985                	lui	s3,0x1
    80001798:	a02d                	j	800017c2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000179a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a0:	37fd                	addiw	a5,a5,-1
    800017a2:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret
    srcva = va0 + PGSIZE;
    800017bc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c0:	c8a9                	beqz	s1,80001812 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017c2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c6:	85ca                	mv	a1,s2
    800017c8:	8552                	mv	a0,s4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	888080e7          	jalr	-1912(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d2:	c131                	beqz	a0,80001816 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017d4:	417906b3          	sub	a3,s2,s7
    800017d8:	96ce                	add	a3,a3,s3
    800017da:	00d4f363          	bgeu	s1,a3,800017e0 <copyinstr+0x6c>
    800017de:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e0:	955e                	add	a0,a0,s7
    800017e2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e6:	daf9                	beqz	a3,800017bc <copyinstr+0x48>
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	fff48593          	addi	a1,s1,-1
    800017f2:	95da                	add	a1,a1,s6
    while(n > 0){
    800017f4:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800017f6:	00f60733          	add	a4,a2,a5
    800017fa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017fe:	df51                	beqz	a4,8000179a <copyinstr+0x26>
        *dst = *p;
    80001800:	00e78023          	sb	a4,0(a5)
      --max;
    80001804:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001808:	0785                	addi	a5,a5,1
    while(n > 0){
    8000180a:	fed796e3          	bne	a5,a3,800017f6 <copyinstr+0x82>
      dst++;
    8000180e:	8b3e                	mv	s6,a5
    80001810:	b775                	j	800017bc <copyinstr+0x48>
    80001812:	4781                	li	a5,0
    80001814:	b771                	j	800017a0 <copyinstr+0x2c>
      return -1;
    80001816:	557d                	li	a0,-1
    80001818:	b779                	j	800017a6 <copyinstr+0x32>
  int got_null = 0;
    8000181a:	4781                	li	a5,0
  if(got_null){
    8000181c:	37fd                	addiw	a5,a5,-1
    8000181e:	0007851b          	sext.w	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183a:	00010497          	auipc	s1,0x10
    8000183e:	e9648493          	addi	s1,s1,-362 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001852:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00016a17          	auipc	s4,0x16
    80001858:	e7ca0a13          	addi	s4,s4,-388 # 800176d0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if(pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	859d                	srai	a1,a1,0x7
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188e:	18048493          	addi	s1,s1,384
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c88080e7          	jalr	-888(ra) # 8000053a <panic>

00000000800018ba <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	91258593          	addi	a1,a1,-1774 # 800081e0 <digits+0x1a0>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9ca50513          	addi	a0,a0,-1590 # 800112a0 <pid_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	262080e7          	jalr	610(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	90258593          	addi	a1,a1,-1790 # 800081e8 <digits+0x1a8>
    800018ee:	00010517          	auipc	a0,0x10
    800018f2:	9ca50513          	addi	a0,a0,-1590 # 800112b8 <wait_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	24a080e7          	jalr	586(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fe:	00010497          	auipc	s1,0x10
    80001902:	dd248493          	addi	s1,s1,-558 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001906:	00007b17          	auipc	s6,0x7
    8000190a:	8f2b0b13          	addi	s6,s6,-1806 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000190e:	8aa6                	mv	s5,s1
    80001910:	00006a17          	auipc	s4,0x6
    80001914:	6f0a0a13          	addi	s4,s4,1776 # 80008000 <etext>
    80001918:	04000937          	lui	s2,0x4000
    8000191c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000191e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00016997          	auipc	s3,0x16
    80001924:	db098993          	addi	s3,s3,-592 # 800176d0 <tickslock>
      initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	879d                	srai	a5,a5,0x7
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	18048493          	addi	s1,s1,384
    80001952:	fd349be3          	bne	s1,s3,80001928 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	94a50513          	addi	a0,a0,-1718 # 800112d0 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e4080e7          	jalr	484(ra) # 80000b84 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	00010717          	auipc	a4,0x10
    800019b2:	8f270713          	addi	a4,a4,-1806 # 800112a0 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26a080e7          	jalr	618(ra) # 80000c24 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ce:	1101                	addi	sp,sp,-32
    800019d0:	ec06                	sd	ra,24(sp)
    800019d2:	e822                	sd	s0,16(sp)
    800019d4:	e426                	sd	s1,8(sp)
    800019d6:	1000                	addi	s0,sp,32
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d8:	00000097          	auipc	ra,0x0
    800019dc:	fbe080e7          	jalr	-66(ra) # 80001996 <myproc>
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	2a4080e7          	jalr	676(ra) # 80000c84 <release>

  if (first) {
    800019e8:	00007797          	auipc	a5,0x7
    800019ec:	f387a783          	lw	a5,-200(a5) # 80008920 <first.1>
    800019f0:	e795                	bnez	a5,80001a1c <forkret+0x4e>
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }
  myproc()->stime = ticks;
    800019f2:	00007497          	auipc	s1,0x7
    800019f6:	63e4a483          	lw	s1,1598(s1) # 80009030 <ticks>
    800019fa:	00000097          	auipc	ra,0x0
    800019fe:	f9c080e7          	jalr	-100(ra) # 80001996 <myproc>
    80001a02:	1482                	slli	s1,s1,0x20
    80001a04:	9081                	srli	s1,s1,0x20
    80001a06:	16953823          	sd	s1,368(a0)
  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	0f8080e7          	jalr	248(ra) # 80002b02 <usertrapret>
}
    80001a12:	60e2                	ld	ra,24(sp)
    80001a14:	6442                	ld	s0,16(sp)
    80001a16:	64a2                	ld	s1,8(sp)
    80001a18:	6105                	addi	sp,sp,32
    80001a1a:	8082                	ret
    first = 0;
    80001a1c:	00007797          	auipc	a5,0x7
    80001a20:	f007a223          	sw	zero,-252(a5) # 80008920 <first.1>
    fsinit(ROOTDEV);
    80001a24:	4505                	li	a0,1
    80001a26:	00002097          	auipc	ra,0x2
    80001a2a:	fc2080e7          	jalr	-62(ra) # 800039e8 <fsinit>
    80001a2e:	b7d1                	j	800019f2 <forkret+0x24>

0000000080001a30 <allocpid>:
allocpid() {
    80001a30:	1101                	addi	sp,sp,-32
    80001a32:	ec06                	sd	ra,24(sp)
    80001a34:	e822                	sd	s0,16(sp)
    80001a36:	e426                	sd	s1,8(sp)
    80001a38:	e04a                	sd	s2,0(sp)
    80001a3a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3c:	00010917          	auipc	s2,0x10
    80001a40:	86490913          	addi	s2,s2,-1948 # 800112a0 <pid_lock>
    80001a44:	854a                	mv	a0,s2
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	18a080e7          	jalr	394(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a4e:	00007797          	auipc	a5,0x7
    80001a52:	ed678793          	addi	a5,a5,-298 # 80008924 <nextpid>
    80001a56:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a58:	0014871b          	addiw	a4,s1,1
    80001a5c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5e:	854a                	mv	a0,s2
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	224080e7          	jalr	548(ra) # 80000c84 <release>
}
    80001a68:	8526                	mv	a0,s1
    80001a6a:	60e2                	ld	ra,24(sp)
    80001a6c:	6442                	ld	s0,16(sp)
    80001a6e:	64a2                	ld	s1,8(sp)
    80001a70:	6902                	ld	s2,0(sp)
    80001a72:	6105                	addi	sp,sp,32
    80001a74:	8082                	ret

0000000080001a76 <proc_pagetable>:
{
    80001a76:	1101                	addi	sp,sp,-32
    80001a78:	ec06                	sd	ra,24(sp)
    80001a7a:	e822                	sd	s0,16(sp)
    80001a7c:	e426                	sd	s1,8(sp)
    80001a7e:	e04a                	sd	s2,0(sp)
    80001a80:	1000                	addi	s0,sp,32
    80001a82:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a84:	00000097          	auipc	ra,0x0
    80001a88:	89a080e7          	jalr	-1894(ra) # 8000131e <uvmcreate>
    80001a8c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8e:	c121                	beqz	a0,80001ace <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a90:	4729                	li	a4,10
    80001a92:	00005697          	auipc	a3,0x5
    80001a96:	56e68693          	addi	a3,a3,1390 # 80007000 <_trampoline>
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	040005b7          	lui	a1,0x4000
    80001aa0:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aa2:	05b2                	slli	a1,a1,0xc
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	5f0080e7          	jalr	1520(ra) # 80001094 <mappages>
    80001aac:	02054863          	bltz	a0,80001adc <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab0:	4719                	li	a4,6
    80001ab2:	05893683          	ld	a3,88(s2)
    80001ab6:	6605                	lui	a2,0x1
    80001ab8:	020005b7          	lui	a1,0x2000
    80001abc:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001abe:	05b6                	slli	a1,a1,0xd
    80001ac0:	8526                	mv	a0,s1
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	5d2080e7          	jalr	1490(ra) # 80001094 <mappages>
    80001aca:	02054163          	bltz	a0,80001aec <proc_pagetable+0x76>
}
    80001ace:	8526                	mv	a0,s1
    80001ad0:	60e2                	ld	ra,24(sp)
    80001ad2:	6442                	ld	s0,16(sp)
    80001ad4:	64a2                	ld	s1,8(sp)
    80001ad6:	6902                	ld	s2,0(sp)
    80001ad8:	6105                	addi	sp,sp,32
    80001ada:	8082                	ret
    uvmfree(pagetable, 0);
    80001adc:	4581                	li	a1,0
    80001ade:	8526                	mv	a0,s1
    80001ae0:	00000097          	auipc	ra,0x0
    80001ae4:	a3c080e7          	jalr	-1476(ra) # 8000151c <uvmfree>
    return 0;
    80001ae8:	4481                	li	s1,0
    80001aea:	b7d5                	j	80001ace <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aec:	4681                	li	a3,0
    80001aee:	4605                	li	a2,1
    80001af0:	040005b7          	lui	a1,0x4000
    80001af4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af6:	05b2                	slli	a1,a1,0xc
    80001af8:	8526                	mv	a0,s1
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	760080e7          	jalr	1888(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001b02:	4581                	li	a1,0
    80001b04:	8526                	mv	a0,s1
    80001b06:	00000097          	auipc	ra,0x0
    80001b0a:	a16080e7          	jalr	-1514(ra) # 8000151c <uvmfree>
    return 0;
    80001b0e:	4481                	li	s1,0
    80001b10:	bf7d                	j	80001ace <proc_pagetable+0x58>

0000000080001b12 <proc_freepagetable>:
{
    80001b12:	1101                	addi	sp,sp,-32
    80001b14:	ec06                	sd	ra,24(sp)
    80001b16:	e822                	sd	s0,16(sp)
    80001b18:	e426                	sd	s1,8(sp)
    80001b1a:	e04a                	sd	s2,0(sp)
    80001b1c:	1000                	addi	s0,sp,32
    80001b1e:	84aa                	mv	s1,a0
    80001b20:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b22:	4681                	li	a3,0
    80001b24:	4605                	li	a2,1
    80001b26:	040005b7          	lui	a1,0x4000
    80001b2a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b2c:	05b2                	slli	a1,a1,0xc
    80001b2e:	fffff097          	auipc	ra,0xfffff
    80001b32:	72c080e7          	jalr	1836(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	020005b7          	lui	a1,0x2000
    80001b3e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b40:	05b6                	slli	a1,a1,0xd
    80001b42:	8526                	mv	a0,s1
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	716080e7          	jalr	1814(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4c:	85ca                	mv	a1,s2
    80001b4e:	8526                	mv	a0,s1
    80001b50:	00000097          	auipc	ra,0x0
    80001b54:	9cc080e7          	jalr	-1588(ra) # 8000151c <uvmfree>
}
    80001b58:	60e2                	ld	ra,24(sp)
    80001b5a:	6442                	ld	s0,16(sp)
    80001b5c:	64a2                	ld	s1,8(sp)
    80001b5e:	6902                	ld	s2,0(sp)
    80001b60:	6105                	addi	sp,sp,32
    80001b62:	8082                	ret

0000000080001b64 <freeproc>:
{
    80001b64:	1101                	addi	sp,sp,-32
    80001b66:	ec06                	sd	ra,24(sp)
    80001b68:	e822                	sd	s0,16(sp)
    80001b6a:	e426                	sd	s1,8(sp)
    80001b6c:	1000                	addi	s0,sp,32
    80001b6e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b70:	6d28                	ld	a0,88(a0)
    80001b72:	c509                	beqz	a0,80001b7c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	e6e080e7          	jalr	-402(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b7c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b80:	68a8                	ld	a0,80(s1)
    80001b82:	c511                	beqz	a0,80001b8e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b84:	64ac                	ld	a1,72(s1)
    80001b86:	00000097          	auipc	ra,0x0
    80001b8a:	f8c080e7          	jalr	-116(ra) # 80001b12 <proc_freepagetable>
  p->pagetable = 0;
    80001b8e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b92:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b96:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b9a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001baa:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bae:	0004ac23          	sw	zero,24(s1)
}
    80001bb2:	60e2                	ld	ra,24(sp)
    80001bb4:	6442                	ld	s0,16(sp)
    80001bb6:	64a2                	ld	s1,8(sp)
    80001bb8:	6105                	addi	sp,sp,32
    80001bba:	8082                	ret

0000000080001bbc <allocproc>:
{
    80001bbc:	1101                	addi	sp,sp,-32
    80001bbe:	ec06                	sd	ra,24(sp)
    80001bc0:	e822                	sd	s0,16(sp)
    80001bc2:	e426                	sd	s1,8(sp)
    80001bc4:	e04a                	sd	s2,0(sp)
    80001bc6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc8:	00010497          	auipc	s1,0x10
    80001bcc:	b0848493          	addi	s1,s1,-1272 # 800116d0 <proc>
    80001bd0:	00016917          	auipc	s2,0x16
    80001bd4:	b0090913          	addi	s2,s2,-1280 # 800176d0 <tickslock>
    acquire(&p->lock);
    80001bd8:	8526                	mv	a0,s1
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	ff6080e7          	jalr	-10(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001be2:	4c9c                	lw	a5,24(s1)
    80001be4:	cf81                	beqz	a5,80001bfc <allocproc+0x40>
      release(&p->lock);
    80001be6:	8526                	mv	a0,s1
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	09c080e7          	jalr	156(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf0:	18048493          	addi	s1,s1,384
    80001bf4:	ff2492e3          	bne	s1,s2,80001bd8 <allocproc+0x1c>
  return 0;
    80001bf8:	4481                	li	s1,0
    80001bfa:	a8b9                	j	80001c58 <allocproc+0x9c>
  p->pid = allocpid();
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	e34080e7          	jalr	-460(ra) # 80001a30 <allocpid>
    80001c04:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c06:	4785                	li	a5,1
    80001c08:	cc9c                	sw	a5,24(s1)
  p->ctime = ticks;
    80001c0a:	00007797          	auipc	a5,0x7
    80001c0e:	4267e783          	lwu	a5,1062(a5) # 80009030 <ticks>
    80001c12:	16f4b423          	sd	a5,360(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	eca080e7          	jalr	-310(ra) # 80000ae0 <kalloc>
    80001c1e:	892a                	mv	s2,a0
    80001c20:	eca8                	sd	a0,88(s1)
    80001c22:	c131                	beqz	a0,80001c66 <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001c24:	8526                	mv	a0,s1
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	e50080e7          	jalr	-432(ra) # 80001a76 <proc_pagetable>
    80001c2e:	892a                	mv	s2,a0
    80001c30:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c32:	c531                	beqz	a0,80001c7e <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001c34:	07000613          	li	a2,112
    80001c38:	4581                	li	a1,0
    80001c3a:	06048513          	addi	a0,s1,96
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	08e080e7          	jalr	142(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c46:	00000797          	auipc	a5,0x0
    80001c4a:	d8878793          	addi	a5,a5,-632 # 800019ce <forkret>
    80001c4e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c50:	60bc                	ld	a5,64(s1)
    80001c52:	6705                	lui	a4,0x1
    80001c54:	97ba                	add	a5,a5,a4
    80001c56:	f4bc                	sd	a5,104(s1)
}
    80001c58:	8526                	mv	a0,s1
    80001c5a:	60e2                	ld	ra,24(sp)
    80001c5c:	6442                	ld	s0,16(sp)
    80001c5e:	64a2                	ld	s1,8(sp)
    80001c60:	6902                	ld	s2,0(sp)
    80001c62:	6105                	addi	sp,sp,32
    80001c64:	8082                	ret
    freeproc(p);
    80001c66:	8526                	mv	a0,s1
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	efc080e7          	jalr	-260(ra) # 80001b64 <freeproc>
    release(&p->lock);
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	012080e7          	jalr	18(ra) # 80000c84 <release>
    return 0;
    80001c7a:	84ca                	mv	s1,s2
    80001c7c:	bff1                	j	80001c58 <allocproc+0x9c>
    freeproc(p);
    80001c7e:	8526                	mv	a0,s1
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	ee4080e7          	jalr	-284(ra) # 80001b64 <freeproc>
    release(&p->lock);
    80001c88:	8526                	mv	a0,s1
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	ffa080e7          	jalr	-6(ra) # 80000c84 <release>
    return 0;
    80001c92:	84ca                	mv	s1,s2
    80001c94:	b7d1                	j	80001c58 <allocproc+0x9c>

0000000080001c96 <userinit>:
{
    80001c96:	1101                	addi	sp,sp,-32
    80001c98:	ec06                	sd	ra,24(sp)
    80001c9a:	e822                	sd	s0,16(sp)
    80001c9c:	e426                	sd	s1,8(sp)
    80001c9e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	f1c080e7          	jalr	-228(ra) # 80001bbc <allocproc>
    80001ca8:	84aa                	mv	s1,a0
  initproc = p;
    80001caa:	00007797          	auipc	a5,0x7
    80001cae:	36a7bf23          	sd	a0,894(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb2:	03400613          	li	a2,52
    80001cb6:	00007597          	auipc	a1,0x7
    80001cba:	c7a58593          	addi	a1,a1,-902 # 80008930 <initcode>
    80001cbe:	6928                	ld	a0,80(a0)
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	68c080e7          	jalr	1676(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001cc8:	6785                	lui	a5,0x1
    80001cca:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ccc:	6cb8                	ld	a4,88(s1)
    80001cce:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd2:	6cb8                	ld	a4,88(s1)
    80001cd4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd6:	4641                	li	a2,16
    80001cd8:	00006597          	auipc	a1,0x6
    80001cdc:	52858593          	addi	a1,a1,1320 # 80008200 <digits+0x1c0>
    80001ce0:	15848513          	addi	a0,s1,344
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	132080e7          	jalr	306(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cec:	00006517          	auipc	a0,0x6
    80001cf0:	52450513          	addi	a0,a0,1316 # 80008210 <digits+0x1d0>
    80001cf4:	00002097          	auipc	ra,0x2
    80001cf8:	72a080e7          	jalr	1834(ra) # 8000441e <namei>
    80001cfc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d00:	478d                	li	a5,3
    80001d02:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	f7e080e7          	jalr	-130(ra) # 80000c84 <release>
}
    80001d0e:	60e2                	ld	ra,24(sp)
    80001d10:	6442                	ld	s0,16(sp)
    80001d12:	64a2                	ld	s1,8(sp)
    80001d14:	6105                	addi	sp,sp,32
    80001d16:	8082                	ret

0000000080001d18 <growproc>:
{
    80001d18:	1101                	addi	sp,sp,-32
    80001d1a:	ec06                	sd	ra,24(sp)
    80001d1c:	e822                	sd	s0,16(sp)
    80001d1e:	e426                	sd	s1,8(sp)
    80001d20:	e04a                	sd	s2,0(sp)
    80001d22:	1000                	addi	s0,sp,32
    80001d24:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d26:	00000097          	auipc	ra,0x0
    80001d2a:	c70080e7          	jalr	-912(ra) # 80001996 <myproc>
    80001d2e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d30:	652c                	ld	a1,72(a0)
    80001d32:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d36:	00904f63          	bgtz	s1,80001d54 <growproc+0x3c>
  } else if(n < 0){
    80001d3a:	0204cd63          	bltz	s1,80001d74 <growproc+0x5c>
  p->sz = sz;
    80001d3e:	1782                	slli	a5,a5,0x20
    80001d40:	9381                	srli	a5,a5,0x20
    80001d42:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d46:	4501                	li	a0,0
}
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6902                	ld	s2,0(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d54:	00f4863b          	addw	a2,s1,a5
    80001d58:	1602                	slli	a2,a2,0x20
    80001d5a:	9201                	srli	a2,a2,0x20
    80001d5c:	1582                	slli	a1,a1,0x20
    80001d5e:	9181                	srli	a1,a1,0x20
    80001d60:	6928                	ld	a0,80(a0)
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	6a4080e7          	jalr	1700(ra) # 80001406 <uvmalloc>
    80001d6a:	0005079b          	sext.w	a5,a0
    80001d6e:	fbe1                	bnez	a5,80001d3e <growproc+0x26>
      return -1;
    80001d70:	557d                	li	a0,-1
    80001d72:	bfd9                	j	80001d48 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d74:	00f4863b          	addw	a2,s1,a5
    80001d78:	1602                	slli	a2,a2,0x20
    80001d7a:	9201                	srli	a2,a2,0x20
    80001d7c:	1582                	slli	a1,a1,0x20
    80001d7e:	9181                	srli	a1,a1,0x20
    80001d80:	6928                	ld	a0,80(a0)
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	63c080e7          	jalr	1596(ra) # 800013be <uvmdealloc>
    80001d8a:	0005079b          	sext.w	a5,a0
    80001d8e:	bf45                	j	80001d3e <growproc+0x26>

0000000080001d90 <fork>:
{
    80001d90:	7139                	addi	sp,sp,-64
    80001d92:	fc06                	sd	ra,56(sp)
    80001d94:	f822                	sd	s0,48(sp)
    80001d96:	f426                	sd	s1,40(sp)
    80001d98:	f04a                	sd	s2,32(sp)
    80001d9a:	ec4e                	sd	s3,24(sp)
    80001d9c:	e852                	sd	s4,16(sp)
    80001d9e:	e456                	sd	s5,8(sp)
    80001da0:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	bf4080e7          	jalr	-1036(ra) # 80001996 <myproc>
    80001daa:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	e10080e7          	jalr	-496(ra) # 80001bbc <allocproc>
    80001db4:	10050c63          	beqz	a0,80001ecc <fork+0x13c>
    80001db8:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dba:	048ab603          	ld	a2,72(s5)
    80001dbe:	692c                	ld	a1,80(a0)
    80001dc0:	050ab503          	ld	a0,80(s5)
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	792080e7          	jalr	1938(ra) # 80001556 <uvmcopy>
    80001dcc:	04054863          	bltz	a0,80001e1c <fork+0x8c>
  np->sz = p->sz;
    80001dd0:	048ab783          	ld	a5,72(s5)
    80001dd4:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dd8:	058ab683          	ld	a3,88(s5)
    80001ddc:	87b6                	mv	a5,a3
    80001dde:	058a3703          	ld	a4,88(s4)
    80001de2:	12068693          	addi	a3,a3,288
    80001de6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dea:	6788                	ld	a0,8(a5)
    80001dec:	6b8c                	ld	a1,16(a5)
    80001dee:	6f90                	ld	a2,24(a5)
    80001df0:	01073023          	sd	a6,0(a4)
    80001df4:	e708                	sd	a0,8(a4)
    80001df6:	eb0c                	sd	a1,16(a4)
    80001df8:	ef10                	sd	a2,24(a4)
    80001dfa:	02078793          	addi	a5,a5,32
    80001dfe:	02070713          	addi	a4,a4,32
    80001e02:	fed792e3          	bne	a5,a3,80001de6 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e06:	058a3783          	ld	a5,88(s4)
    80001e0a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e0e:	0d0a8493          	addi	s1,s5,208
    80001e12:	0d0a0913          	addi	s2,s4,208
    80001e16:	150a8993          	addi	s3,s5,336
    80001e1a:	a00d                	j	80001e3c <fork+0xac>
    freeproc(np);
    80001e1c:	8552                	mv	a0,s4
    80001e1e:	00000097          	auipc	ra,0x0
    80001e22:	d46080e7          	jalr	-698(ra) # 80001b64 <freeproc>
    release(&np->lock);
    80001e26:	8552                	mv	a0,s4
    80001e28:	fffff097          	auipc	ra,0xfffff
    80001e2c:	e5c080e7          	jalr	-420(ra) # 80000c84 <release>
    return -1;
    80001e30:	597d                	li	s2,-1
    80001e32:	a059                	j	80001eb8 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e34:	04a1                	addi	s1,s1,8
    80001e36:	0921                	addi	s2,s2,8
    80001e38:	01348b63          	beq	s1,s3,80001e4e <fork+0xbe>
    if(p->ofile[i])
    80001e3c:	6088                	ld	a0,0(s1)
    80001e3e:	d97d                	beqz	a0,80001e34 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e40:	00003097          	auipc	ra,0x3
    80001e44:	c74080e7          	jalr	-908(ra) # 80004ab4 <filedup>
    80001e48:	00a93023          	sd	a0,0(s2)
    80001e4c:	b7e5                	j	80001e34 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e4e:	150ab503          	ld	a0,336(s5)
    80001e52:	00002097          	auipc	ra,0x2
    80001e56:	dd2080e7          	jalr	-558(ra) # 80003c24 <idup>
    80001e5a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e5e:	4641                	li	a2,16
    80001e60:	158a8593          	addi	a1,s5,344
    80001e64:	158a0513          	addi	a0,s4,344
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	fae080e7          	jalr	-82(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e70:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e74:	8552                	mv	a0,s4
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e0e080e7          	jalr	-498(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e7e:	0000f497          	auipc	s1,0xf
    80001e82:	43a48493          	addi	s1,s1,1082 # 800112b8 <wait_lock>
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	d48080e7          	jalr	-696(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001e90:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e94:	8526                	mv	a0,s1
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	dee080e7          	jalr	-530(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001e9e:	8552                	mv	a0,s4
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	d30080e7          	jalr	-720(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001ea8:	478d                	li	a5,3
    80001eaa:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001eae:	8552                	mv	a0,s4
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	dd4080e7          	jalr	-556(ra) # 80000c84 <release>
}
    80001eb8:	854a                	mv	a0,s2
    80001eba:	70e2                	ld	ra,56(sp)
    80001ebc:	7442                	ld	s0,48(sp)
    80001ebe:	74a2                	ld	s1,40(sp)
    80001ec0:	7902                	ld	s2,32(sp)
    80001ec2:	69e2                	ld	s3,24(sp)
    80001ec4:	6a42                	ld	s4,16(sp)
    80001ec6:	6aa2                	ld	s5,8(sp)
    80001ec8:	6121                	addi	sp,sp,64
    80001eca:	8082                	ret
    return -1;
    80001ecc:	597d                	li	s2,-1
    80001ece:	b7ed                	j	80001eb8 <fork+0x128>

0000000080001ed0 <scheduler>:
{
    80001ed0:	7139                	addi	sp,sp,-64
    80001ed2:	fc06                	sd	ra,56(sp)
    80001ed4:	f822                	sd	s0,48(sp)
    80001ed6:	f426                	sd	s1,40(sp)
    80001ed8:	f04a                	sd	s2,32(sp)
    80001eda:	ec4e                	sd	s3,24(sp)
    80001edc:	e852                	sd	s4,16(sp)
    80001ede:	e456                	sd	s5,8(sp)
    80001ee0:	e05a                	sd	s6,0(sp)
    80001ee2:	0080                	addi	s0,sp,64
    80001ee4:	8792                	mv	a5,tp
  int id = r_tp();
    80001ee6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ee8:	00779a93          	slli	s5,a5,0x7
    80001eec:	0000f717          	auipc	a4,0xf
    80001ef0:	3b470713          	addi	a4,a4,948 # 800112a0 <pid_lock>
    80001ef4:	9756                	add	a4,a4,s5
    80001ef6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001efa:	0000f717          	auipc	a4,0xf
    80001efe:	3de70713          	addi	a4,a4,990 # 800112d8 <cpus+0x8>
    80001f02:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f04:	498d                	li	s3,3
        p->state = RUNNING;
    80001f06:	4b11                	li	s6,4
        c->proc = p;
    80001f08:	079e                	slli	a5,a5,0x7
    80001f0a:	0000fa17          	auipc	s4,0xf
    80001f0e:	396a0a13          	addi	s4,s4,918 # 800112a0 <pid_lock>
    80001f12:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f14:	00015917          	auipc	s2,0x15
    80001f18:	7bc90913          	addi	s2,s2,1980 # 800176d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f1c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f20:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f24:	10079073          	csrw	sstatus,a5
    80001f28:	0000f497          	auipc	s1,0xf
    80001f2c:	7a848493          	addi	s1,s1,1960 # 800116d0 <proc>
    80001f30:	a811                	j	80001f44 <scheduler+0x74>
      release(&p->lock);
    80001f32:	8526                	mv	a0,s1
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	d50080e7          	jalr	-688(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3c:	18048493          	addi	s1,s1,384
    80001f40:	fd248ee3          	beq	s1,s2,80001f1c <scheduler+0x4c>
      acquire(&p->lock);
    80001f44:	8526                	mv	a0,s1
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	c8a080e7          	jalr	-886(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80001f4e:	4c9c                	lw	a5,24(s1)
    80001f50:	ff3791e3          	bne	a5,s3,80001f32 <scheduler+0x62>
        p->state = RUNNING;
    80001f54:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f58:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f5c:	06048593          	addi	a1,s1,96
    80001f60:	8556                	mv	a0,s5
    80001f62:	00001097          	auipc	ra,0x1
    80001f66:	af6080e7          	jalr	-1290(ra) # 80002a58 <swtch>
        c->proc = 0;
    80001f6a:	020a3823          	sd	zero,48(s4)
    80001f6e:	b7d1                	j	80001f32 <scheduler+0x62>

0000000080001f70 <sched>:
{
    80001f70:	7179                	addi	sp,sp,-48
    80001f72:	f406                	sd	ra,40(sp)
    80001f74:	f022                	sd	s0,32(sp)
    80001f76:	ec26                	sd	s1,24(sp)
    80001f78:	e84a                	sd	s2,16(sp)
    80001f7a:	e44e                	sd	s3,8(sp)
    80001f7c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f7e:	00000097          	auipc	ra,0x0
    80001f82:	a18080e7          	jalr	-1512(ra) # 80001996 <myproc>
    80001f86:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	bce080e7          	jalr	-1074(ra) # 80000b56 <holding>
    80001f90:	c93d                	beqz	a0,80002006 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f92:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f94:	2781                	sext.w	a5,a5
    80001f96:	079e                	slli	a5,a5,0x7
    80001f98:	0000f717          	auipc	a4,0xf
    80001f9c:	30870713          	addi	a4,a4,776 # 800112a0 <pid_lock>
    80001fa0:	97ba                	add	a5,a5,a4
    80001fa2:	0a87a703          	lw	a4,168(a5)
    80001fa6:	4785                	li	a5,1
    80001fa8:	06f71763          	bne	a4,a5,80002016 <sched+0xa6>
  if(p->state == RUNNING)
    80001fac:	4c98                	lw	a4,24(s1)
    80001fae:	4791                	li	a5,4
    80001fb0:	06f70b63          	beq	a4,a5,80002026 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fb8:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fba:	efb5                	bnez	a5,80002036 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fbc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fbe:	0000f917          	auipc	s2,0xf
    80001fc2:	2e290913          	addi	s2,s2,738 # 800112a0 <pid_lock>
    80001fc6:	2781                	sext.w	a5,a5
    80001fc8:	079e                	slli	a5,a5,0x7
    80001fca:	97ca                	add	a5,a5,s2
    80001fcc:	0ac7a983          	lw	s3,172(a5)
    80001fd0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fd2:	2781                	sext.w	a5,a5
    80001fd4:	079e                	slli	a5,a5,0x7
    80001fd6:	0000f597          	auipc	a1,0xf
    80001fda:	30258593          	addi	a1,a1,770 # 800112d8 <cpus+0x8>
    80001fde:	95be                	add	a1,a1,a5
    80001fe0:	06048513          	addi	a0,s1,96
    80001fe4:	00001097          	auipc	ra,0x1
    80001fe8:	a74080e7          	jalr	-1420(ra) # 80002a58 <swtch>
    80001fec:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fee:	2781                	sext.w	a5,a5
    80001ff0:	079e                	slli	a5,a5,0x7
    80001ff2:	993e                	add	s2,s2,a5
    80001ff4:	0b392623          	sw	s3,172(s2)
}
    80001ff8:	70a2                	ld	ra,40(sp)
    80001ffa:	7402                	ld	s0,32(sp)
    80001ffc:	64e2                	ld	s1,24(sp)
    80001ffe:	6942                	ld	s2,16(sp)
    80002000:	69a2                	ld	s3,8(sp)
    80002002:	6145                	addi	sp,sp,48
    80002004:	8082                	ret
    panic("sched p->lock");
    80002006:	00006517          	auipc	a0,0x6
    8000200a:	21250513          	addi	a0,a0,530 # 80008218 <digits+0x1d8>
    8000200e:	ffffe097          	auipc	ra,0xffffe
    80002012:	52c080e7          	jalr	1324(ra) # 8000053a <panic>
    panic("sched locks");
    80002016:	00006517          	auipc	a0,0x6
    8000201a:	21250513          	addi	a0,a0,530 # 80008228 <digits+0x1e8>
    8000201e:	ffffe097          	auipc	ra,0xffffe
    80002022:	51c080e7          	jalr	1308(ra) # 8000053a <panic>
    panic("sched running");
    80002026:	00006517          	auipc	a0,0x6
    8000202a:	21250513          	addi	a0,a0,530 # 80008238 <digits+0x1f8>
    8000202e:	ffffe097          	auipc	ra,0xffffe
    80002032:	50c080e7          	jalr	1292(ra) # 8000053a <panic>
    panic("sched interruptible");
    80002036:	00006517          	auipc	a0,0x6
    8000203a:	21250513          	addi	a0,a0,530 # 80008248 <digits+0x208>
    8000203e:	ffffe097          	auipc	ra,0xffffe
    80002042:	4fc080e7          	jalr	1276(ra) # 8000053a <panic>

0000000080002046 <yield>:
{
    80002046:	1101                	addi	sp,sp,-32
    80002048:	ec06                	sd	ra,24(sp)
    8000204a:	e822                	sd	s0,16(sp)
    8000204c:	e426                	sd	s1,8(sp)
    8000204e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002050:	00000097          	auipc	ra,0x0
    80002054:	946080e7          	jalr	-1722(ra) # 80001996 <myproc>
    80002058:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	b76080e7          	jalr	-1162(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    80002062:	478d                	li	a5,3
    80002064:	cc9c                	sw	a5,24(s1)
  sched();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	f0a080e7          	jalr	-246(ra) # 80001f70 <sched>
  release(&p->lock);
    8000206e:	8526                	mv	a0,s1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	c14080e7          	jalr	-1004(ra) # 80000c84 <release>
}
    80002078:	60e2                	ld	ra,24(sp)
    8000207a:	6442                	ld	s0,16(sp)
    8000207c:	64a2                	ld	s1,8(sp)
    8000207e:	6105                	addi	sp,sp,32
    80002080:	8082                	ret

0000000080002082 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002082:	7179                	addi	sp,sp,-48
    80002084:	f406                	sd	ra,40(sp)
    80002086:	f022                	sd	s0,32(sp)
    80002088:	ec26                	sd	s1,24(sp)
    8000208a:	e84a                	sd	s2,16(sp)
    8000208c:	e44e                	sd	s3,8(sp)
    8000208e:	1800                	addi	s0,sp,48
    80002090:	89aa                	mv	s3,a0
    80002092:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002094:	00000097          	auipc	ra,0x0
    80002098:	902080e7          	jalr	-1790(ra) # 80001996 <myproc>
    8000209c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	b32080e7          	jalr	-1230(ra) # 80000bd0 <acquire>
  release(lk);
    800020a6:	854a                	mv	a0,s2
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	bdc080e7          	jalr	-1060(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    800020b0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020b4:	4789                	li	a5,2
    800020b6:	cc9c                	sw	a5,24(s1)

  sched();
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	eb8080e7          	jalr	-328(ra) # 80001f70 <sched>

  // Tidy up.
  p->chan = 0;
    800020c0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020c4:	8526                	mv	a0,s1
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	bbe080e7          	jalr	-1090(ra) # 80000c84 <release>
  acquire(lk);
    800020ce:	854a                	mv	a0,s2
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	b00080e7          	jalr	-1280(ra) # 80000bd0 <acquire>
}
    800020d8:	70a2                	ld	ra,40(sp)
    800020da:	7402                	ld	s0,32(sp)
    800020dc:	64e2                	ld	s1,24(sp)
    800020de:	6942                	ld	s2,16(sp)
    800020e0:	69a2                	ld	s3,8(sp)
    800020e2:	6145                	addi	sp,sp,48
    800020e4:	8082                	ret

00000000800020e6 <wait>:
{
    800020e6:	715d                	addi	sp,sp,-80
    800020e8:	e486                	sd	ra,72(sp)
    800020ea:	e0a2                	sd	s0,64(sp)
    800020ec:	fc26                	sd	s1,56(sp)
    800020ee:	f84a                	sd	s2,48(sp)
    800020f0:	f44e                	sd	s3,40(sp)
    800020f2:	f052                	sd	s4,32(sp)
    800020f4:	ec56                	sd	s5,24(sp)
    800020f6:	e85a                	sd	s6,16(sp)
    800020f8:	e45e                	sd	s7,8(sp)
    800020fa:	e062                	sd	s8,0(sp)
    800020fc:	0880                	addi	s0,sp,80
    800020fe:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002100:	00000097          	auipc	ra,0x0
    80002104:	896080e7          	jalr	-1898(ra) # 80001996 <myproc>
    80002108:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000210a:	0000f517          	auipc	a0,0xf
    8000210e:	1ae50513          	addi	a0,a0,430 # 800112b8 <wait_lock>
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	abe080e7          	jalr	-1346(ra) # 80000bd0 <acquire>
    havekids = 0;
    8000211a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000211c:	4a15                	li	s4,5
        havekids = 1;
    8000211e:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002120:	00015997          	auipc	s3,0x15
    80002124:	5b098993          	addi	s3,s3,1456 # 800176d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002128:	0000fc17          	auipc	s8,0xf
    8000212c:	190c0c13          	addi	s8,s8,400 # 800112b8 <wait_lock>
    havekids = 0;
    80002130:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002132:	0000f497          	auipc	s1,0xf
    80002136:	59e48493          	addi	s1,s1,1438 # 800116d0 <proc>
    8000213a:	a0bd                	j	800021a8 <wait+0xc2>
          pid = np->pid;
    8000213c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002140:	000b0e63          	beqz	s6,8000215c <wait+0x76>
    80002144:	4691                	li	a3,4
    80002146:	02c48613          	addi	a2,s1,44
    8000214a:	85da                	mv	a1,s6
    8000214c:	05093503          	ld	a0,80(s2)
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	50a080e7          	jalr	1290(ra) # 8000165a <copyout>
    80002158:	02054563          	bltz	a0,80002182 <wait+0x9c>
          freeproc(np);
    8000215c:	8526                	mv	a0,s1
    8000215e:	00000097          	auipc	ra,0x0
    80002162:	a06080e7          	jalr	-1530(ra) # 80001b64 <freeproc>
          release(&np->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b1c080e7          	jalr	-1252(ra) # 80000c84 <release>
          release(&wait_lock);
    80002170:	0000f517          	auipc	a0,0xf
    80002174:	14850513          	addi	a0,a0,328 # 800112b8 <wait_lock>
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	b0c080e7          	jalr	-1268(ra) # 80000c84 <release>
          return pid;
    80002180:	a09d                	j	800021e6 <wait+0x100>
            release(&np->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	b00080e7          	jalr	-1280(ra) # 80000c84 <release>
            release(&wait_lock);
    8000218c:	0000f517          	auipc	a0,0xf
    80002190:	12c50513          	addi	a0,a0,300 # 800112b8 <wait_lock>
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	af0080e7          	jalr	-1296(ra) # 80000c84 <release>
            return -1;
    8000219c:	59fd                	li	s3,-1
    8000219e:	a0a1                	j	800021e6 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021a0:	18048493          	addi	s1,s1,384
    800021a4:	03348463          	beq	s1,s3,800021cc <wait+0xe6>
      if(np->parent == p){
    800021a8:	7c9c                	ld	a5,56(s1)
    800021aa:	ff279be3          	bne	a5,s2,800021a0 <wait+0xba>
        acquire(&np->lock);
    800021ae:	8526                	mv	a0,s1
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	a20080e7          	jalr	-1504(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    800021b8:	4c9c                	lw	a5,24(s1)
    800021ba:	f94781e3          	beq	a5,s4,8000213c <wait+0x56>
        release(&np->lock);
    800021be:	8526                	mv	a0,s1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	ac4080e7          	jalr	-1340(ra) # 80000c84 <release>
        havekids = 1;
    800021c8:	8756                	mv	a4,s5
    800021ca:	bfd9                	j	800021a0 <wait+0xba>
    if(!havekids || p->killed){
    800021cc:	c701                	beqz	a4,800021d4 <wait+0xee>
    800021ce:	02892783          	lw	a5,40(s2)
    800021d2:	c79d                	beqz	a5,80002200 <wait+0x11a>
      release(&wait_lock);
    800021d4:	0000f517          	auipc	a0,0xf
    800021d8:	0e450513          	addi	a0,a0,228 # 800112b8 <wait_lock>
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	aa8080e7          	jalr	-1368(ra) # 80000c84 <release>
      return -1;
    800021e4:	59fd                	li	s3,-1
}
    800021e6:	854e                	mv	a0,s3
    800021e8:	60a6                	ld	ra,72(sp)
    800021ea:	6406                	ld	s0,64(sp)
    800021ec:	74e2                	ld	s1,56(sp)
    800021ee:	7942                	ld	s2,48(sp)
    800021f0:	79a2                	ld	s3,40(sp)
    800021f2:	7a02                	ld	s4,32(sp)
    800021f4:	6ae2                	ld	s5,24(sp)
    800021f6:	6b42                	ld	s6,16(sp)
    800021f8:	6ba2                	ld	s7,8(sp)
    800021fa:	6c02                	ld	s8,0(sp)
    800021fc:	6161                	addi	sp,sp,80
    800021fe:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002200:	85e2                	mv	a1,s8
    80002202:	854a                	mv	a0,s2
    80002204:	00000097          	auipc	ra,0x0
    80002208:	e7e080e7          	jalr	-386(ra) # 80002082 <sleep>
    havekids = 0;
    8000220c:	b715                	j	80002130 <wait+0x4a>

000000008000220e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000220e:	7139                	addi	sp,sp,-64
    80002210:	fc06                	sd	ra,56(sp)
    80002212:	f822                	sd	s0,48(sp)
    80002214:	f426                	sd	s1,40(sp)
    80002216:	f04a                	sd	s2,32(sp)
    80002218:	ec4e                	sd	s3,24(sp)
    8000221a:	e852                	sd	s4,16(sp)
    8000221c:	e456                	sd	s5,8(sp)
    8000221e:	0080                	addi	s0,sp,64
    80002220:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002222:	0000f497          	auipc	s1,0xf
    80002226:	4ae48493          	addi	s1,s1,1198 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000222a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000222c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000222e:	00015917          	auipc	s2,0x15
    80002232:	4a290913          	addi	s2,s2,1186 # 800176d0 <tickslock>
    80002236:	a811                	j	8000224a <wakeup+0x3c>
      }
      release(&p->lock);
    80002238:	8526                	mv	a0,s1
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	a4a080e7          	jalr	-1462(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002242:	18048493          	addi	s1,s1,384
    80002246:	03248663          	beq	s1,s2,80002272 <wakeup+0x64>
    if(p != myproc()){
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	74c080e7          	jalr	1868(ra) # 80001996 <myproc>
    80002252:	fea488e3          	beq	s1,a0,80002242 <wakeup+0x34>
      acquire(&p->lock);
    80002256:	8526                	mv	a0,s1
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	978080e7          	jalr	-1672(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002260:	4c9c                	lw	a5,24(s1)
    80002262:	fd379be3          	bne	a5,s3,80002238 <wakeup+0x2a>
    80002266:	709c                	ld	a5,32(s1)
    80002268:	fd4798e3          	bne	a5,s4,80002238 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000226c:	0154ac23          	sw	s5,24(s1)
    80002270:	b7e1                	j	80002238 <wakeup+0x2a>
    }
  }
}
    80002272:	70e2                	ld	ra,56(sp)
    80002274:	7442                	ld	s0,48(sp)
    80002276:	74a2                	ld	s1,40(sp)
    80002278:	7902                	ld	s2,32(sp)
    8000227a:	69e2                	ld	s3,24(sp)
    8000227c:	6a42                	ld	s4,16(sp)
    8000227e:	6aa2                	ld	s5,8(sp)
    80002280:	6121                	addi	sp,sp,64
    80002282:	8082                	ret

0000000080002284 <reparent>:
{
    80002284:	7179                	addi	sp,sp,-48
    80002286:	f406                	sd	ra,40(sp)
    80002288:	f022                	sd	s0,32(sp)
    8000228a:	ec26                	sd	s1,24(sp)
    8000228c:	e84a                	sd	s2,16(sp)
    8000228e:	e44e                	sd	s3,8(sp)
    80002290:	e052                	sd	s4,0(sp)
    80002292:	1800                	addi	s0,sp,48
    80002294:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002296:	0000f497          	auipc	s1,0xf
    8000229a:	43a48493          	addi	s1,s1,1082 # 800116d0 <proc>
      pp->parent = initproc;
    8000229e:	00007a17          	auipc	s4,0x7
    800022a2:	d8aa0a13          	addi	s4,s4,-630 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a6:	00015997          	auipc	s3,0x15
    800022aa:	42a98993          	addi	s3,s3,1066 # 800176d0 <tickslock>
    800022ae:	a029                	j	800022b8 <reparent+0x34>
    800022b0:	18048493          	addi	s1,s1,384
    800022b4:	01348d63          	beq	s1,s3,800022ce <reparent+0x4a>
    if(pp->parent == p){
    800022b8:	7c9c                	ld	a5,56(s1)
    800022ba:	ff279be3          	bne	a5,s2,800022b0 <reparent+0x2c>
      pp->parent = initproc;
    800022be:	000a3503          	ld	a0,0(s4)
    800022c2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	f4a080e7          	jalr	-182(ra) # 8000220e <wakeup>
    800022cc:	b7d5                	j	800022b0 <reparent+0x2c>
}
    800022ce:	70a2                	ld	ra,40(sp)
    800022d0:	7402                	ld	s0,32(sp)
    800022d2:	64e2                	ld	s1,24(sp)
    800022d4:	6942                	ld	s2,16(sp)
    800022d6:	69a2                	ld	s3,8(sp)
    800022d8:	6a02                	ld	s4,0(sp)
    800022da:	6145                	addi	sp,sp,48
    800022dc:	8082                	ret

00000000800022de <exit>:
{
    800022de:	7179                	addi	sp,sp,-48
    800022e0:	f406                	sd	ra,40(sp)
    800022e2:	f022                	sd	s0,32(sp)
    800022e4:	ec26                	sd	s1,24(sp)
    800022e6:	e84a                	sd	s2,16(sp)
    800022e8:	e44e                	sd	s3,8(sp)
    800022ea:	e052                	sd	s4,0(sp)
    800022ec:	1800                	addi	s0,sp,48
    800022ee:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	6a6080e7          	jalr	1702(ra) # 80001996 <myproc>
    800022f8:	89aa                	mv	s3,a0
  if(p == initproc)
    800022fa:	00007797          	auipc	a5,0x7
    800022fe:	d2e7b783          	ld	a5,-722(a5) # 80009028 <initproc>
    80002302:	0d050493          	addi	s1,a0,208
    80002306:	15050913          	addi	s2,a0,336
    8000230a:	02a79363          	bne	a5,a0,80002330 <exit+0x52>
    panic("init exiting");
    8000230e:	00006517          	auipc	a0,0x6
    80002312:	f5250513          	addi	a0,a0,-174 # 80008260 <digits+0x220>
    80002316:	ffffe097          	auipc	ra,0xffffe
    8000231a:	224080e7          	jalr	548(ra) # 8000053a <panic>
      fileclose(f);
    8000231e:	00002097          	auipc	ra,0x2
    80002322:	7e8080e7          	jalr	2024(ra) # 80004b06 <fileclose>
      p->ofile[fd] = 0;
    80002326:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000232a:	04a1                	addi	s1,s1,8
    8000232c:	01248563          	beq	s1,s2,80002336 <exit+0x58>
    if(p->ofile[fd]){
    80002330:	6088                	ld	a0,0(s1)
    80002332:	f575                	bnez	a0,8000231e <exit+0x40>
    80002334:	bfdd                	j	8000232a <exit+0x4c>
  begin_op();
    80002336:	00002097          	auipc	ra,0x2
    8000233a:	308080e7          	jalr	776(ra) # 8000463e <begin_op>
  iput(p->cwd);
    8000233e:	1509b503          	ld	a0,336(s3)
    80002342:	00002097          	auipc	ra,0x2
    80002346:	ada080e7          	jalr	-1318(ra) # 80003e1c <iput>
  end_op();
    8000234a:	00002097          	auipc	ra,0x2
    8000234e:	372080e7          	jalr	882(ra) # 800046bc <end_op>
  p->cwd = 0;
    80002352:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002356:	0000f497          	auipc	s1,0xf
    8000235a:	f6248493          	addi	s1,s1,-158 # 800112b8 <wait_lock>
    8000235e:	8526                	mv	a0,s1
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	870080e7          	jalr	-1936(ra) # 80000bd0 <acquire>
  reparent(p);
    80002368:	854e                	mv	a0,s3
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	f1a080e7          	jalr	-230(ra) # 80002284 <reparent>
  wakeup(p->parent);
    80002372:	0389b503          	ld	a0,56(s3)
    80002376:	00000097          	auipc	ra,0x0
    8000237a:	e98080e7          	jalr	-360(ra) # 8000220e <wakeup>
  acquire(&p->lock);
    8000237e:	854e                	mv	a0,s3
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	850080e7          	jalr	-1968(ra) # 80000bd0 <acquire>
  p->xstate = status;
    80002388:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000238c:	4795                	li	a5,5
    8000238e:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002392:	00007797          	auipc	a5,0x7
    80002396:	c9e7e783          	lwu	a5,-866(a5) # 80009030 <ticks>
    8000239a:	16f9bc23          	sd	a5,376(s3)
  release(&wait_lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8e4080e7          	jalr	-1820(ra) # 80000c84 <release>
  sched();
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	bc8080e7          	jalr	-1080(ra) # 80001f70 <sched>
  panic("zombie exit");
    800023b0:	00006517          	auipc	a0,0x6
    800023b4:	ec050513          	addi	a0,a0,-320 # 80008270 <digits+0x230>
    800023b8:	ffffe097          	auipc	ra,0xffffe
    800023bc:	182080e7          	jalr	386(ra) # 8000053a <panic>

00000000800023c0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023c0:	7179                	addi	sp,sp,-48
    800023c2:	f406                	sd	ra,40(sp)
    800023c4:	f022                	sd	s0,32(sp)
    800023c6:	ec26                	sd	s1,24(sp)
    800023c8:	e84a                	sd	s2,16(sp)
    800023ca:	e44e                	sd	s3,8(sp)
    800023cc:	1800                	addi	s0,sp,48
    800023ce:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023d0:	0000f497          	auipc	s1,0xf
    800023d4:	30048493          	addi	s1,s1,768 # 800116d0 <proc>
    800023d8:	00015997          	auipc	s3,0x15
    800023dc:	2f898993          	addi	s3,s3,760 # 800176d0 <tickslock>
    acquire(&p->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	ffffe097          	auipc	ra,0xffffe
    800023e6:	7ee080e7          	jalr	2030(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800023ea:	589c                	lw	a5,48(s1)
    800023ec:	01278d63          	beq	a5,s2,80002406 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	892080e7          	jalr	-1902(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023fa:	18048493          	addi	s1,s1,384
    800023fe:	ff3491e3          	bne	s1,s3,800023e0 <kill+0x20>
  }
  return -1;
    80002402:	557d                	li	a0,-1
    80002404:	a829                	j	8000241e <kill+0x5e>
      p->killed = 1;
    80002406:	4785                	li	a5,1
    80002408:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000240a:	4c98                	lw	a4,24(s1)
    8000240c:	4789                	li	a5,2
    8000240e:	00f70f63          	beq	a4,a5,8000242c <kill+0x6c>
      release(&p->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	870080e7          	jalr	-1936(ra) # 80000c84 <release>
      return 0;
    8000241c:	4501                	li	a0,0
}
    8000241e:	70a2                	ld	ra,40(sp)
    80002420:	7402                	ld	s0,32(sp)
    80002422:	64e2                	ld	s1,24(sp)
    80002424:	6942                	ld	s2,16(sp)
    80002426:	69a2                	ld	s3,8(sp)
    80002428:	6145                	addi	sp,sp,48
    8000242a:	8082                	ret
        p->state = RUNNABLE;
    8000242c:	478d                	li	a5,3
    8000242e:	cc9c                	sw	a5,24(s1)
    80002430:	b7cd                	j	80002412 <kill+0x52>

0000000080002432 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002432:	7179                	addi	sp,sp,-48
    80002434:	f406                	sd	ra,40(sp)
    80002436:	f022                	sd	s0,32(sp)
    80002438:	ec26                	sd	s1,24(sp)
    8000243a:	e84a                	sd	s2,16(sp)
    8000243c:	e44e                	sd	s3,8(sp)
    8000243e:	e052                	sd	s4,0(sp)
    80002440:	1800                	addi	s0,sp,48
    80002442:	84aa                	mv	s1,a0
    80002444:	892e                	mv	s2,a1
    80002446:	89b2                	mv	s3,a2
    80002448:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	54c080e7          	jalr	1356(ra) # 80001996 <myproc>
  if(user_dst){
    80002452:	c08d                	beqz	s1,80002474 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002454:	86d2                	mv	a3,s4
    80002456:	864e                	mv	a2,s3
    80002458:	85ca                	mv	a1,s2
    8000245a:	6928                	ld	a0,80(a0)
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	1fe080e7          	jalr	510(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002464:	70a2                	ld	ra,40(sp)
    80002466:	7402                	ld	s0,32(sp)
    80002468:	64e2                	ld	s1,24(sp)
    8000246a:	6942                	ld	s2,16(sp)
    8000246c:	69a2                	ld	s3,8(sp)
    8000246e:	6a02                	ld	s4,0(sp)
    80002470:	6145                	addi	sp,sp,48
    80002472:	8082                	ret
    memmove((char *)dst, src, len);
    80002474:	000a061b          	sext.w	a2,s4
    80002478:	85ce                	mv	a1,s3
    8000247a:	854a                	mv	a0,s2
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	8ac080e7          	jalr	-1876(ra) # 80000d28 <memmove>
    return 0;
    80002484:	8526                	mv	a0,s1
    80002486:	bff9                	j	80002464 <either_copyout+0x32>

0000000080002488 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002488:	7179                	addi	sp,sp,-48
    8000248a:	f406                	sd	ra,40(sp)
    8000248c:	f022                	sd	s0,32(sp)
    8000248e:	ec26                	sd	s1,24(sp)
    80002490:	e84a                	sd	s2,16(sp)
    80002492:	e44e                	sd	s3,8(sp)
    80002494:	e052                	sd	s4,0(sp)
    80002496:	1800                	addi	s0,sp,48
    80002498:	892a                	mv	s2,a0
    8000249a:	84ae                	mv	s1,a1
    8000249c:	89b2                	mv	s3,a2
    8000249e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	4f6080e7          	jalr	1270(ra) # 80001996 <myproc>
  if(user_src){
    800024a8:	c08d                	beqz	s1,800024ca <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024aa:	86d2                	mv	a3,s4
    800024ac:	864e                	mv	a2,s3
    800024ae:	85ca                	mv	a1,s2
    800024b0:	6928                	ld	a0,80(a0)
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	234080e7          	jalr	564(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024ba:	70a2                	ld	ra,40(sp)
    800024bc:	7402                	ld	s0,32(sp)
    800024be:	64e2                	ld	s1,24(sp)
    800024c0:	6942                	ld	s2,16(sp)
    800024c2:	69a2                	ld	s3,8(sp)
    800024c4:	6a02                	ld	s4,0(sp)
    800024c6:	6145                	addi	sp,sp,48
    800024c8:	8082                	ret
    memmove(dst, (char*)src, len);
    800024ca:	000a061b          	sext.w	a2,s4
    800024ce:	85ce                	mv	a1,s3
    800024d0:	854a                	mv	a0,s2
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	856080e7          	jalr	-1962(ra) # 80000d28 <memmove>
    return 0;
    800024da:	8526                	mv	a0,s1
    800024dc:	bff9                	j	800024ba <either_copyin+0x32>

00000000800024de <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024de:	715d                	addi	sp,sp,-80
    800024e0:	e486                	sd	ra,72(sp)
    800024e2:	e0a2                	sd	s0,64(sp)
    800024e4:	fc26                	sd	s1,56(sp)
    800024e6:	f84a                	sd	s2,48(sp)
    800024e8:	f44e                	sd	s3,40(sp)
    800024ea:	f052                	sd	s4,32(sp)
    800024ec:	ec56                	sd	s5,24(sp)
    800024ee:	e85a                	sd	s6,16(sp)
    800024f0:	e45e                	sd	s7,8(sp)
    800024f2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024f4:	00006517          	auipc	a0,0x6
    800024f8:	bd450513          	addi	a0,a0,-1068 # 800080c8 <digits+0x88>
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	088080e7          	jalr	136(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002504:	0000f497          	auipc	s1,0xf
    80002508:	32448493          	addi	s1,s1,804 # 80011828 <proc+0x158>
    8000250c:	00015917          	auipc	s2,0x15
    80002510:	31c90913          	addi	s2,s2,796 # 80017828 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002514:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002516:	00006997          	auipc	s3,0x6
    8000251a:	d6a98993          	addi	s3,s3,-662 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000251e:	00006a97          	auipc	s5,0x6
    80002522:	d6aa8a93          	addi	s5,s5,-662 # 80008288 <digits+0x248>
    printf("\n");
    80002526:	00006a17          	auipc	s4,0x6
    8000252a:	ba2a0a13          	addi	s4,s4,-1118 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000252e:	00006b97          	auipc	s7,0x6
    80002532:	e22b8b93          	addi	s7,s7,-478 # 80008350 <states.0>
    80002536:	a00d                	j	80002558 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002538:	ed86a583          	lw	a1,-296(a3)
    8000253c:	8556                	mv	a0,s5
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	046080e7          	jalr	70(ra) # 80000584 <printf>
    printf("\n");
    80002546:	8552                	mv	a0,s4
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	03c080e7          	jalr	60(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002550:	18048493          	addi	s1,s1,384
    80002554:	03248263          	beq	s1,s2,80002578 <procdump+0x9a>
    if(p->state == UNUSED)
    80002558:	86a6                	mv	a3,s1
    8000255a:	ec04a783          	lw	a5,-320(s1)
    8000255e:	dbed                	beqz	a5,80002550 <procdump+0x72>
      state = "???";
    80002560:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002562:	fcfb6be3          	bltu	s6,a5,80002538 <procdump+0x5a>
    80002566:	02079713          	slli	a4,a5,0x20
    8000256a:	01d75793          	srli	a5,a4,0x1d
    8000256e:	97de                	add	a5,a5,s7
    80002570:	6390                	ld	a2,0(a5)
    80002572:	f279                	bnez	a2,80002538 <procdump+0x5a>
      state = "???";
    80002574:	864e                	mv	a2,s3
    80002576:	b7c9                	j	80002538 <procdump+0x5a>
  }
}
    80002578:	60a6                	ld	ra,72(sp)
    8000257a:	6406                	ld	s0,64(sp)
    8000257c:	74e2                	ld	s1,56(sp)
    8000257e:	7942                	ld	s2,48(sp)
    80002580:	79a2                	ld	s3,40(sp)
    80002582:	7a02                	ld	s4,32(sp)
    80002584:	6ae2                	ld	s5,24(sp)
    80002586:	6b42                	ld	s6,16(sp)
    80002588:	6ba2                	ld	s7,8(sp)
    8000258a:	6161                	addi	sp,sp,80
    8000258c:	8082                	ret

000000008000258e <forkf>:

int
forkf(uint64 va)
{
    8000258e:	7139                	addi	sp,sp,-64
    80002590:	fc06                	sd	ra,56(sp)
    80002592:	f822                	sd	s0,48(sp)
    80002594:	f426                	sd	s1,40(sp)
    80002596:	f04a                	sd	s2,32(sp)
    80002598:	ec4e                	sd	s3,24(sp)
    8000259a:	e852                	sd	s4,16(sp)
    8000259c:	e456                	sd	s5,8(sp)
    8000259e:	0080                	addi	s0,sp,64
    800025a0:	84aa                	mv	s1,a0
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();
    800025a2:	fffff097          	auipc	ra,0xfffff
    800025a6:	3f4080e7          	jalr	1012(ra) # 80001996 <myproc>
    800025aa:	8aaa                	mv	s5,a0

  // Allocate process.
  if((np = allocproc()) == 0){
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	610080e7          	jalr	1552(ra) # 80001bbc <allocproc>
    800025b4:	12050163          	beqz	a0,800026d6 <forkf+0x148>
    800025b8:	89aa                	mv	s3,a0
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800025ba:	048ab603          	ld	a2,72(s5)
    800025be:	692c                	ld	a1,80(a0)
    800025c0:	050ab503          	ld	a0,80(s5)
    800025c4:	fffff097          	auipc	ra,0xfffff
    800025c8:	f92080e7          	jalr	-110(ra) # 80001556 <uvmcopy>
    800025cc:	04054d63          	bltz	a0,80002626 <forkf+0x98>
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;
    800025d0:	048ab783          	ld	a5,72(s5)
    800025d4:	04f9b423          	sd	a5,72(s3)

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);
    800025d8:	058ab683          	ld	a3,88(s5)
    800025dc:	87b6                	mv	a5,a3
    800025de:	0589b703          	ld	a4,88(s3)
    800025e2:	12068693          	addi	a3,a3,288
    800025e6:	0007b883          	ld	a7,0(a5)
    800025ea:	0087b803          	ld	a6,8(a5)
    800025ee:	6b8c                	ld	a1,16(a5)
    800025f0:	6f90                	ld	a2,24(a5)
    800025f2:	01173023          	sd	a7,0(a4)
    800025f6:	01073423          	sd	a6,8(a4)
    800025fa:	eb0c                	sd	a1,16(a4)
    800025fc:	ef10                	sd	a2,24(a4)
    800025fe:	02078793          	addi	a5,a5,32
    80002602:	02070713          	addi	a4,a4,32
    80002606:	fed790e3          	bne	a5,a3,800025e6 <forkf+0x58>

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;
    8000260a:	0589b783          	ld	a5,88(s3)
    8000260e:	0607b823          	sd	zero,112(a5)
  np->trapframe->epc = va;
    80002612:	0589b783          	ld	a5,88(s3)
    80002616:	ef84                	sd	s1,24(a5)
  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    80002618:	0d0a8493          	addi	s1,s5,208
    8000261c:	0d098913          	addi	s2,s3,208
    80002620:	150a8a13          	addi	s4,s5,336
    80002624:	a00d                	j	80002646 <forkf+0xb8>
    freeproc(np);
    80002626:	854e                	mv	a0,s3
    80002628:	fffff097          	auipc	ra,0xfffff
    8000262c:	53c080e7          	jalr	1340(ra) # 80001b64 <freeproc>
    release(&np->lock);
    80002630:	854e                	mv	a0,s3
    80002632:	ffffe097          	auipc	ra,0xffffe
    80002636:	652080e7          	jalr	1618(ra) # 80000c84 <release>
    return -1;
    8000263a:	597d                	li	s2,-1
    8000263c:	a059                	j	800026c2 <forkf+0x134>
  for(i = 0; i < NOFILE; i++)
    8000263e:	04a1                	addi	s1,s1,8
    80002640:	0921                	addi	s2,s2,8
    80002642:	01448b63          	beq	s1,s4,80002658 <forkf+0xca>
    if(p->ofile[i])
    80002646:	6088                	ld	a0,0(s1)
    80002648:	d97d                	beqz	a0,8000263e <forkf+0xb0>
      np->ofile[i] = filedup(p->ofile[i]);
    8000264a:	00002097          	auipc	ra,0x2
    8000264e:	46a080e7          	jalr	1130(ra) # 80004ab4 <filedup>
    80002652:	00a93023          	sd	a0,0(s2)
    80002656:	b7e5                	j	8000263e <forkf+0xb0>
  np->cwd = idup(p->cwd);
    80002658:	150ab503          	ld	a0,336(s5)
    8000265c:	00001097          	auipc	ra,0x1
    80002660:	5c8080e7          	jalr	1480(ra) # 80003c24 <idup>
    80002664:	14a9b823          	sd	a0,336(s3)

  safestrcpy(np->name, p->name, sizeof(p->name));
    80002668:	4641                	li	a2,16
    8000266a:	158a8593          	addi	a1,s5,344
    8000266e:	15898513          	addi	a0,s3,344
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	7a4080e7          	jalr	1956(ra) # 80000e16 <safestrcpy>

  pid = np->pid;
    8000267a:	0309a903          	lw	s2,48(s3)

  release(&np->lock);
    8000267e:	854e                	mv	a0,s3
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	604080e7          	jalr	1540(ra) # 80000c84 <release>

  acquire(&wait_lock);
    80002688:	0000f497          	auipc	s1,0xf
    8000268c:	c3048493          	addi	s1,s1,-976 # 800112b8 <wait_lock>
    80002690:	8526                	mv	a0,s1
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	53e080e7          	jalr	1342(ra) # 80000bd0 <acquire>
  np->parent = p;
    8000269a:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    8000269e:	8526                	mv	a0,s1
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	5e4080e7          	jalr	1508(ra) # 80000c84 <release>

  acquire(&np->lock);
    800026a8:	854e                	mv	a0,s3
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	526080e7          	jalr	1318(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    800026b2:	478d                	li	a5,3
    800026b4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800026b8:	854e                	mv	a0,s3
    800026ba:	ffffe097          	auipc	ra,0xffffe
    800026be:	5ca080e7          	jalr	1482(ra) # 80000c84 <release>

  return pid;
}
    800026c2:	854a                	mv	a0,s2
    800026c4:	70e2                	ld	ra,56(sp)
    800026c6:	7442                	ld	s0,48(sp)
    800026c8:	74a2                	ld	s1,40(sp)
    800026ca:	7902                	ld	s2,32(sp)
    800026cc:	69e2                	ld	s3,24(sp)
    800026ce:	6a42                	ld	s4,16(sp)
    800026d0:	6aa2                	ld	s5,8(sp)
    800026d2:	6121                	addi	sp,sp,64
    800026d4:	8082                	ret
    return -1;
    800026d6:	597d                	li	s2,-1
    800026d8:	b7ed                	j	800026c2 <forkf+0x134>

00000000800026da <waitpid>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
waitpid(uint64 _pid, uint64 addr)
{
    800026da:	711d                	addi	sp,sp,-96
    800026dc:	ec86                	sd	ra,88(sp)
    800026de:	e8a2                	sd	s0,80(sp)
    800026e0:	e4a6                	sd	s1,72(sp)
    800026e2:	e0ca                	sd	s2,64(sp)
    800026e4:	fc4e                	sd	s3,56(sp)
    800026e6:	f852                	sd	s4,48(sp)
    800026e8:	f456                	sd	s5,40(sp)
    800026ea:	f05a                	sd	s6,32(sp)
    800026ec:	ec5e                	sd	s7,24(sp)
    800026ee:	e862                	sd	s8,16(sp)
    800026f0:	e466                	sd	s9,8(sp)
    800026f2:	1080                	addi	s0,sp,96
    800026f4:	892a                	mv	s2,a0
    800026f6:	8bae                	mv	s7,a1
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800026f8:	fffff097          	auipc	ra,0xfffff
    800026fc:	29e080e7          	jalr	670(ra) # 80001996 <myproc>
    80002700:	8a2a                	mv	s4,a0

  acquire(&wait_lock);
    80002702:	0000f517          	auipc	a0,0xf
    80002706:	bb650513          	addi	a0,a0,-1098 # 800112b8 <wait_lock>
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	4c6080e7          	jalr	1222(ra) # 80000bd0 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    80002712:	4c01                	li	s8,0
      if((np->pid == _pid) && (np->parent == p)){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    80002714:	4a95                	li	s5,5
        havekids = 1;
    80002716:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002718:	00015997          	auipc	s3,0x15
    8000271c:	fb898993          	addi	s3,s3,-72 # 800176d0 <tickslock>
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002720:	0000fc97          	auipc	s9,0xf
    80002724:	b98c8c93          	addi	s9,s9,-1128 # 800112b8 <wait_lock>
    havekids = 0;
    80002728:	8762                	mv	a4,s8
    for(np = proc; np < &proc[NPROC]; np++){
    8000272a:	0000f497          	auipc	s1,0xf
    8000272e:	fa648493          	addi	s1,s1,-90 # 800116d0 <proc>
    80002732:	a0bd                	j	800027a0 <waitpid+0xc6>
          pid = np->pid;
    80002734:	0304a903          	lw	s2,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002738:	000b8e63          	beqz	s7,80002754 <waitpid+0x7a>
    8000273c:	4691                	li	a3,4
    8000273e:	02c48613          	addi	a2,s1,44
    80002742:	85de                	mv	a1,s7
    80002744:	050a3503          	ld	a0,80(s4)
    80002748:	fffff097          	auipc	ra,0xfffff
    8000274c:	f12080e7          	jalr	-238(ra) # 8000165a <copyout>
    80002750:	02054563          	bltz	a0,8000277a <waitpid+0xa0>
          freeproc(np);
    80002754:	8526                	mv	a0,s1
    80002756:	fffff097          	auipc	ra,0xfffff
    8000275a:	40e080e7          	jalr	1038(ra) # 80001b64 <freeproc>
          release(&np->lock);
    8000275e:	8526                	mv	a0,s1
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	524080e7          	jalr	1316(ra) # 80000c84 <release>
          release(&wait_lock);
    80002768:	0000f517          	auipc	a0,0xf
    8000276c:	b5050513          	addi	a0,a0,-1200 # 800112b8 <wait_lock>
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	514080e7          	jalr	1300(ra) # 80000c84 <release>
          return pid;
    80002778:	a0b5                	j	800027e4 <waitpid+0x10a>
            release(&np->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	508080e7          	jalr	1288(ra) # 80000c84 <release>
            release(&wait_lock);
    80002784:	0000f517          	auipc	a0,0xf
    80002788:	b3450513          	addi	a0,a0,-1228 # 800112b8 <wait_lock>
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	4f8080e7          	jalr	1272(ra) # 80000c84 <release>
            return -1;
    80002794:	597d                	li	s2,-1
    80002796:	a0b9                	j	800027e4 <waitpid+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    80002798:	18048493          	addi	s1,s1,384
    8000279c:	03348763          	beq	s1,s3,800027ca <waitpid+0xf0>
      if((np->pid == _pid) && (np->parent == p)){
    800027a0:	589c                	lw	a5,48(s1)
    800027a2:	ff279be3          	bne	a5,s2,80002798 <waitpid+0xbe>
    800027a6:	7c9c                	ld	a5,56(s1)
    800027a8:	ff4798e3          	bne	a5,s4,80002798 <waitpid+0xbe>
        acquire(&np->lock);
    800027ac:	8526                	mv	a0,s1
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	422080e7          	jalr	1058(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    800027b6:	4c9c                	lw	a5,24(s1)
    800027b8:	f7578ee3          	beq	a5,s5,80002734 <waitpid+0x5a>
        release(&np->lock);
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	4c6080e7          	jalr	1222(ra) # 80000c84 <release>
        havekids = 1;
    800027c6:	875a                	mv	a4,s6
    800027c8:	bfc1                	j	80002798 <waitpid+0xbe>
    if(!havekids || p->killed){
    800027ca:	c701                	beqz	a4,800027d2 <waitpid+0xf8>
    800027cc:	028a2783          	lw	a5,40(s4)
    800027d0:	cb85                	beqz	a5,80002800 <waitpid+0x126>
      release(&wait_lock);
    800027d2:	0000f517          	auipc	a0,0xf
    800027d6:	ae650513          	addi	a0,a0,-1306 # 800112b8 <wait_lock>
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	4aa080e7          	jalr	1194(ra) # 80000c84 <release>
      return -1;
    800027e2:	597d                	li	s2,-1
  }
}
    800027e4:	854a                	mv	a0,s2
    800027e6:	60e6                	ld	ra,88(sp)
    800027e8:	6446                	ld	s0,80(sp)
    800027ea:	64a6                	ld	s1,72(sp)
    800027ec:	6906                	ld	s2,64(sp)
    800027ee:	79e2                	ld	s3,56(sp)
    800027f0:	7a42                	ld	s4,48(sp)
    800027f2:	7aa2                	ld	s5,40(sp)
    800027f4:	7b02                	ld	s6,32(sp)
    800027f6:	6be2                	ld	s7,24(sp)
    800027f8:	6c42                	ld	s8,16(sp)
    800027fa:	6ca2                	ld	s9,8(sp)
    800027fc:	6125                	addi	sp,sp,96
    800027fe:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002800:	85e6                	mv	a1,s9
    80002802:	8552                	mv	a0,s4
    80002804:	00000097          	auipc	ra,0x0
    80002808:	87e080e7          	jalr	-1922(ra) # 80002082 <sleep>
    havekids = 0;
    8000280c:	bf31                	j	80002728 <waitpid+0x4e>

000000008000280e <ps>:

void
ps(void)
{
    8000280e:	7175                	addi	sp,sp,-144
    80002810:	e506                	sd	ra,136(sp)
    80002812:	e122                	sd	s0,128(sp)
    80002814:	fca6                	sd	s1,120(sp)
    80002816:	f8ca                	sd	s2,112(sp)
    80002818:	f4ce                	sd	s3,104(sp)
    8000281a:	f0d2                	sd	s4,96(sp)
    8000281c:	ecd6                	sd	s5,88(sp)
    8000281e:	e8da                	sd	s6,80(sp)
    80002820:	e4de                	sd	s7,72(sp)
    80002822:	0900                	addi	s0,sp,144
  struct proc *np;
  char* states[] = { "UNUSED", "USED", "SLEEPING", "RUNNABLE", "RUNNING", "ZOMBIE" };
    80002824:	00006797          	auipc	a5,0x6
    80002828:	b2c78793          	addi	a5,a5,-1236 # 80008350 <states.0>
    8000282c:	7b88                	ld	a0,48(a5)
    8000282e:	7f8c                	ld	a1,56(a5)
    80002830:	63b0                	ld	a2,64(a5)
    80002832:	67b4                	ld	a3,72(a5)
    80002834:	6bb8                	ld	a4,80(a5)
    80002836:	6fbc                	ld	a5,88(a5)
    80002838:	f8a43023          	sd	a0,-128(s0)
    8000283c:	f8b43423          	sd	a1,-120(s0)
    80002840:	f8c43823          	sd	a2,-112(s0)
    80002844:	f8d43c23          	sd	a3,-104(s0)
    80002848:	fae43023          	sd	a4,-96(s0)
    8000284c:	faf43423          	sd	a5,-88(s0)
  // acquire(&wait_lock);

  // for(;;){
    // Scan through table looking for exited children.
    // havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
    80002850:	0000f497          	auipc	s1,0xf
    80002854:	e8048493          	addi	s1,s1,-384 # 800116d0 <proc>
      acquire(&np->lock);
      if(np->state != UNUSED)
        printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%x\n", np->pid, (np->parent) ? np->parent->pid : -1, states[np->state], np->name, np->ctime, np->stime, (np->state == ZOMBIE)? np->etime : ticks - np->stime, np->sz);
    80002858:	5b7d                	li	s6,-1
    8000285a:	4a95                	li	s5,5
    8000285c:	00006a17          	auipc	s4,0x6
    80002860:	a3ca0a13          	addi	s4,s4,-1476 # 80008298 <digits+0x258>
    80002864:	00006b97          	auipc	s7,0x6
    80002868:	7ccb8b93          	addi	s7,s7,1996 # 80009030 <ticks>
    for(np = proc; np < &proc[NPROC]; np++){
    8000286c:	00015997          	auipc	s3,0x15
    80002870:	e6498993          	addi	s3,s3,-412 # 800176d0 <tickslock>
    80002874:	a01d                	j	8000289a <ps+0x8c>
        printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%x\n", np->pid, (np->parent) ? np->parent->pid : -1, states[np->state], np->name, np->ctime, np->stime, (np->state == ZOMBIE)? np->etime : ticks - np->stime, np->sz);
    80002876:	1784b883          	ld	a7,376(s1)
    8000287a:	64a8                	ld	a0,72(s1)
    8000287c:	e02a                	sd	a0,0(sp)
    8000287e:	8552                	mv	a0,s4
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	d04080e7          	jalr	-764(ra) # 80000584 <printf>
      release(&np->lock);
    80002888:	8526                	mv	a0,s1
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	3fa080e7          	jalr	1018(ra) # 80000c84 <release>
    for(np = proc; np < &proc[NPROC]; np++){
    80002892:	18048493          	addi	s1,s1,384
    80002896:	05348563          	beq	s1,s3,800028e0 <ps+0xd2>
      acquire(&np->lock);
    8000289a:	8926                	mv	s2,s1
    8000289c:	8526                	mv	a0,s1
    8000289e:	ffffe097          	auipc	ra,0xffffe
    800028a2:	332080e7          	jalr	818(ra) # 80000bd0 <acquire>
      if(np->state != UNUSED)
    800028a6:	4c88                	lw	a0,24(s1)
    800028a8:	d165                	beqz	a0,80002888 <ps+0x7a>
        printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%x\n", np->pid, (np->parent) ? np->parent->pid : -1, states[np->state], np->name, np->ctime, np->stime, (np->state == ZOMBIE)? np->etime : ticks - np->stime, np->sz);
    800028aa:	588c                	lw	a1,48(s1)
    800028ac:	7c9c                	ld	a5,56(s1)
    800028ae:	865a                	mv	a2,s6
    800028b0:	c391                	beqz	a5,800028b4 <ps+0xa6>
    800028b2:	5b90                	lw	a2,48(a5)
    800028b4:	02051713          	slli	a4,a0,0x20
    800028b8:	01d75793          	srli	a5,a4,0x1d
    800028bc:	fb078793          	addi	a5,a5,-80
    800028c0:	97a2                	add	a5,a5,s0
    800028c2:	fd07b683          	ld	a3,-48(a5)
    800028c6:	15890713          	addi	a4,s2,344
    800028ca:	1684b783          	ld	a5,360(s1)
    800028ce:	1704b803          	ld	a6,368(s1)
    800028d2:	fb5502e3          	beq	a0,s5,80002876 <ps+0x68>
    800028d6:	000be883          	lwu	a7,0(s7)
    800028da:	410888b3          	sub	a7,a7,a6
    800028de:	bf71                	j	8000287a <ps+0x6c>
    }
    return;
  // }
}
    800028e0:	60aa                	ld	ra,136(sp)
    800028e2:	640a                	ld	s0,128(sp)
    800028e4:	74e6                	ld	s1,120(sp)
    800028e6:	7946                	ld	s2,112(sp)
    800028e8:	79a6                	ld	s3,104(sp)
    800028ea:	7a06                	ld	s4,96(sp)
    800028ec:	6ae6                	ld	s5,88(sp)
    800028ee:	6b46                	ld	s6,80(sp)
    800028f0:	6ba6                	ld	s7,72(sp)
    800028f2:	6149                	addi	sp,sp,144
    800028f4:	8082                	ret

00000000800028f6 <pinfo>:

int
pinfo(uint64 pid, struct procstat * prcst){
    800028f6:	7159                	addi	sp,sp,-112
    800028f8:	f486                	sd	ra,104(sp)
    800028fa:	f0a2                	sd	s0,96(sp)
    800028fc:	eca6                	sd	s1,88(sp)
    800028fe:	e8ca                	sd	s2,80(sp)
    80002900:	e4ce                	sd	s3,72(sp)
    80002902:	e0d2                	sd	s4,64(sp)
    80002904:	1880                	addi	s0,sp,112
    80002906:	89aa                	mv	s3,a0
    80002908:	8a2e                	mv	s4,a1
  struct proc *np ;//= (
  // prcst = (struct procstat *)p;
  // printf("%d\n", pc->pid);
  char* states[] = { "UNUSED", "USED", "SLEEPING", "RUNNABLE", "RUNNING", "ZOMBIE" };
    8000290a:	00006797          	auipc	a5,0x6
    8000290e:	a4678793          	addi	a5,a5,-1466 # 80008350 <states.0>
    80002912:	7b88                	ld	a0,48(a5)
    80002914:	7f8c                	ld	a1,56(a5)
    80002916:	63b0                	ld	a2,64(a5)
    80002918:	67b4                	ld	a3,72(a5)
    8000291a:	6bb8                	ld	a4,80(a5)
    8000291c:	6fbc                	ld	a5,88(a5)
    8000291e:	faa43023          	sd	a0,-96(s0)
    80002922:	fab43423          	sd	a1,-88(s0)
    80002926:	fac43823          	sd	a2,-80(s0)
    8000292a:	fad43c23          	sd	a3,-72(s0)
    8000292e:	fce43023          	sd	a4,-64(s0)
    80002932:	fcf43423          	sd	a5,-56(s0)
  for(np = proc; np < &proc[NPROC]; np++){
    80002936:	0000f497          	auipc	s1,0xf
    8000293a:	d9a48493          	addi	s1,s1,-614 # 800116d0 <proc>
    8000293e:	00015917          	auipc	s2,0x15
    80002942:	d9290913          	addi	s2,s2,-622 # 800176d0 <tickslock>
    80002946:	a005                	j	80002966 <pinfo+0x70>
      acquire(&np->lock);
      if((np->state != UNUSED)&&(np->pid == pid)){
        printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%x\n", np->pid, (np->parent) ? np->parent->pid : -1, states[np->state], np->name, np->ctime, np->stime, (np->state == ZOMBIE)? np->etime : ticks - np->stime, np->sz);
    80002948:	1784b883          	ld	a7,376(s1)
    8000294c:	a09d                	j	800029b2 <pinfo+0xbc>
        prcst->ppid = (np->parent) ? np->parent->pid : -1;
        safestrcpy(prcst->state, states[np->state], sizeof(states[np->state]));
        safestrcpy(prcst->command, np->name, sizeof(np->name));
        prcst->ctime = np->ctime;
        prcst->stime = np->stime;
        prcst->etime = (np->state == ZOMBIE)? np->etime : ticks - np->stime;
    8000294e:	1784a783          	lw	a5,376(s1)
    80002952:	a8f1                	j	80002a2e <pinfo+0x138>
        prcst->size = np->sz;
        release(&np->lock);
        return 0;
        }
      release(&np->lock);
    80002954:	8526                	mv	a0,s1
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
  for(np = proc; np < &proc[NPROC]; np++){
    8000295e:	18048493          	addi	s1,s1,384
    80002962:	0f248963          	beq	s1,s2,80002a54 <pinfo+0x15e>
      acquire(&np->lock);
    80002966:	8526                	mv	a0,s1
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	268080e7          	jalr	616(ra) # 80000bd0 <acquire>
      if((np->state != UNUSED)&&(np->pid == pid)){
    80002970:	4c98                	lw	a4,24(s1)
    80002972:	d36d                	beqz	a4,80002954 <pinfo+0x5e>
    80002974:	588c                	lw	a1,48(s1)
    80002976:	fd359fe3          	bne	a1,s3,80002954 <pinfo+0x5e>
        printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%x\n", np->pid, (np->parent) ? np->parent->pid : -1, states[np->state], np->name, np->ctime, np->stime, (np->state == ZOMBIE)? np->etime : ticks - np->stime, np->sz);
    8000297a:	7c9c                	ld	a5,56(s1)
    8000297c:	567d                	li	a2,-1
    8000297e:	c391                	beqz	a5,80002982 <pinfo+0x8c>
    80002980:	5b90                	lw	a2,48(a5)
    80002982:	02071693          	slli	a3,a4,0x20
    80002986:	01d6d793          	srli	a5,a3,0x1d
    8000298a:	fd078793          	addi	a5,a5,-48
    8000298e:	97a2                	add	a5,a5,s0
    80002990:	fd07b683          	ld	a3,-48(a5)
    80002994:	15848913          	addi	s2,s1,344
    80002998:	1684b783          	ld	a5,360(s1)
    8000299c:	1704b803          	ld	a6,368(s1)
    800029a0:	4515                	li	a0,5
    800029a2:	faa703e3          	beq	a4,a0,80002948 <pinfo+0x52>
    800029a6:	00006897          	auipc	a7,0x6
    800029aa:	68a8e883          	lwu	a7,1674(a7) # 80009030 <ticks>
    800029ae:	410888b3          	sub	a7,a7,a6
    800029b2:	64b8                	ld	a4,72(s1)
    800029b4:	e03a                	sd	a4,0(sp)
    800029b6:	874a                	mv	a4,s2
    800029b8:	00006517          	auipc	a0,0x6
    800029bc:	8e050513          	addi	a0,a0,-1824 # 80008298 <digits+0x258>
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	bc4080e7          	jalr	-1084(ra) # 80000584 <printf>
        prcst->pid = np->pid;
    800029c8:	589c                	lw	a5,48(s1)
    800029ca:	00fa2023          	sw	a5,0(s4)
        prcst->ppid = (np->parent) ? np->parent->pid : -1;
    800029ce:	7c98                	ld	a4,56(s1)
    800029d0:	57fd                	li	a5,-1
    800029d2:	c311                	beqz	a4,800029d6 <pinfo+0xe0>
    800029d4:	5b1c                	lw	a5,48(a4)
    800029d6:	00fa2223          	sw	a5,4(s4)
        safestrcpy(prcst->state, states[np->state], sizeof(states[np->state]));
    800029da:	0184e783          	lwu	a5,24(s1)
    800029de:	078e                	slli	a5,a5,0x3
    800029e0:	fd078793          	addi	a5,a5,-48
    800029e4:	97a2                	add	a5,a5,s0
    800029e6:	4621                	li	a2,8
    800029e8:	fd07b583          	ld	a1,-48(a5)
    800029ec:	008a0513          	addi	a0,s4,8
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	426080e7          	jalr	1062(ra) # 80000e16 <safestrcpy>
        safestrcpy(prcst->command, np->name, sizeof(np->name));
    800029f8:	4641                	li	a2,16
    800029fa:	85ca                	mv	a1,s2
    800029fc:	010a0513          	addi	a0,s4,16
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	416080e7          	jalr	1046(ra) # 80000e16 <safestrcpy>
        prcst->ctime = np->ctime;
    80002a08:	1684b783          	ld	a5,360(s1)
    80002a0c:	02fa2023          	sw	a5,32(s4)
        prcst->stime = np->stime;
    80002a10:	1704b783          	ld	a5,368(s1)
    80002a14:	02fa2223          	sw	a5,36(s4)
        prcst->etime = (np->state == ZOMBIE)? np->etime : ticks - np->stime;
    80002a18:	4c98                	lw	a4,24(s1)
    80002a1a:	4795                	li	a5,5
    80002a1c:	f2f709e3          	beq	a4,a5,8000294e <pinfo+0x58>
    80002a20:	1704b703          	ld	a4,368(s1)
    80002a24:	00006797          	auipc	a5,0x6
    80002a28:	60c7a783          	lw	a5,1548(a5) # 80009030 <ticks>
    80002a2c:	9f99                	subw	a5,a5,a4
    80002a2e:	02fa2423          	sw	a5,40(s4)
        prcst->size = np->sz;
    80002a32:	64bc                	ld	a5,72(s1)
    80002a34:	02fa2623          	sw	a5,44(s4)
        release(&np->lock);
    80002a38:	8526                	mv	a0,s1
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	24a080e7          	jalr	586(ra) # 80000c84 <release>
        return 0;
    80002a42:	4501                	li	a0,0
    }
  return -1;
    80002a44:	70a6                	ld	ra,104(sp)
    80002a46:	7406                	ld	s0,96(sp)
    80002a48:	64e6                	ld	s1,88(sp)
    80002a4a:	6946                	ld	s2,80(sp)
    80002a4c:	69a6                	ld	s3,72(sp)
    80002a4e:	6a06                	ld	s4,64(sp)
    80002a50:	6165                	addi	sp,sp,112
    80002a52:	8082                	ret
  return -1;
    80002a54:	557d                	li	a0,-1
    80002a56:	b7fd                	j	80002a44 <pinfo+0x14e>

0000000080002a58 <swtch>:
    80002a58:	00153023          	sd	ra,0(a0)
    80002a5c:	00253423          	sd	sp,8(a0)
    80002a60:	e900                	sd	s0,16(a0)
    80002a62:	ed04                	sd	s1,24(a0)
    80002a64:	03253023          	sd	s2,32(a0)
    80002a68:	03353423          	sd	s3,40(a0)
    80002a6c:	03453823          	sd	s4,48(a0)
    80002a70:	03553c23          	sd	s5,56(a0)
    80002a74:	05653023          	sd	s6,64(a0)
    80002a78:	05753423          	sd	s7,72(a0)
    80002a7c:	05853823          	sd	s8,80(a0)
    80002a80:	05953c23          	sd	s9,88(a0)
    80002a84:	07a53023          	sd	s10,96(a0)
    80002a88:	07b53423          	sd	s11,104(a0)
    80002a8c:	0005b083          	ld	ra,0(a1)
    80002a90:	0085b103          	ld	sp,8(a1)
    80002a94:	6980                	ld	s0,16(a1)
    80002a96:	6d84                	ld	s1,24(a1)
    80002a98:	0205b903          	ld	s2,32(a1)
    80002a9c:	0285b983          	ld	s3,40(a1)
    80002aa0:	0305ba03          	ld	s4,48(a1)
    80002aa4:	0385ba83          	ld	s5,56(a1)
    80002aa8:	0405bb03          	ld	s6,64(a1)
    80002aac:	0485bb83          	ld	s7,72(a1)
    80002ab0:	0505bc03          	ld	s8,80(a1)
    80002ab4:	0585bc83          	ld	s9,88(a1)
    80002ab8:	0605bd03          	ld	s10,96(a1)
    80002abc:	0685bd83          	ld	s11,104(a1)
    80002ac0:	8082                	ret

0000000080002ac2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ac2:	1141                	addi	sp,sp,-16
    80002ac4:	e406                	sd	ra,8(sp)
    80002ac6:	e022                	sd	s0,0(sp)
    80002ac8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002aca:	00006597          	auipc	a1,0x6
    80002ace:	8e658593          	addi	a1,a1,-1818 # 800083b0 <states.0+0x60>
    80002ad2:	00015517          	auipc	a0,0x15
    80002ad6:	bfe50513          	addi	a0,a0,-1026 # 800176d0 <tickslock>
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	066080e7          	jalr	102(ra) # 80000b40 <initlock>
}
    80002ae2:	60a2                	ld	ra,8(sp)
    80002ae4:	6402                	ld	s0,0(sp)
    80002ae6:	0141                	addi	sp,sp,16
    80002ae8:	8082                	ret

0000000080002aea <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002aea:	1141                	addi	sp,sp,-16
    80002aec:	e422                	sd	s0,8(sp)
    80002aee:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002af0:	00003797          	auipc	a5,0x3
    80002af4:	64078793          	addi	a5,a5,1600 # 80006130 <kernelvec>
    80002af8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002afc:	6422                	ld	s0,8(sp)
    80002afe:	0141                	addi	sp,sp,16
    80002b00:	8082                	ret

0000000080002b02 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b02:	1141                	addi	sp,sp,-16
    80002b04:	e406                	sd	ra,8(sp)
    80002b06:	e022                	sd	s0,0(sp)
    80002b08:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b0a:	fffff097          	auipc	ra,0xfffff
    80002b0e:	e8c080e7          	jalr	-372(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b12:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b16:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b18:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002b1c:	00004697          	auipc	a3,0x4
    80002b20:	4e468693          	addi	a3,a3,1252 # 80007000 <_trampoline>
    80002b24:	00004717          	auipc	a4,0x4
    80002b28:	4dc70713          	addi	a4,a4,1244 # 80007000 <_trampoline>
    80002b2c:	8f15                	sub	a4,a4,a3
    80002b2e:	040007b7          	lui	a5,0x4000
    80002b32:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002b34:	07b2                	slli	a5,a5,0xc
    80002b36:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b38:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b3c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b3e:	18002673          	csrr	a2,satp
    80002b42:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b44:	6d30                	ld	a2,88(a0)
    80002b46:	6138                	ld	a4,64(a0)
    80002b48:	6585                	lui	a1,0x1
    80002b4a:	972e                	add	a4,a4,a1
    80002b4c:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b4e:	6d38                	ld	a4,88(a0)
    80002b50:	00000617          	auipc	a2,0x0
    80002b54:	13860613          	addi	a2,a2,312 # 80002c88 <usertrap>
    80002b58:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b5a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b5c:	8612                	mv	a2,tp
    80002b5e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b60:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b64:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b68:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b6c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b70:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b72:	6f18                	ld	a4,24(a4)
    80002b74:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b78:	692c                	ld	a1,80(a0)
    80002b7a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002b7c:	00004717          	auipc	a4,0x4
    80002b80:	51470713          	addi	a4,a4,1300 # 80007090 <userret>
    80002b84:	8f15                	sub	a4,a4,a3
    80002b86:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002b88:	577d                	li	a4,-1
    80002b8a:	177e                	slli	a4,a4,0x3f
    80002b8c:	8dd9                	or	a1,a1,a4
    80002b8e:	02000537          	lui	a0,0x2000
    80002b92:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002b94:	0536                	slli	a0,a0,0xd
    80002b96:	9782                	jalr	a5
}
    80002b98:	60a2                	ld	ra,8(sp)
    80002b9a:	6402                	ld	s0,0(sp)
    80002b9c:	0141                	addi	sp,sp,16
    80002b9e:	8082                	ret

0000000080002ba0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ba0:	1101                	addi	sp,sp,-32
    80002ba2:	ec06                	sd	ra,24(sp)
    80002ba4:	e822                	sd	s0,16(sp)
    80002ba6:	e426                	sd	s1,8(sp)
    80002ba8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002baa:	00015497          	auipc	s1,0x15
    80002bae:	b2648493          	addi	s1,s1,-1242 # 800176d0 <tickslock>
    80002bb2:	8526                	mv	a0,s1
    80002bb4:	ffffe097          	auipc	ra,0xffffe
    80002bb8:	01c080e7          	jalr	28(ra) # 80000bd0 <acquire>
  ticks++;
    80002bbc:	00006517          	auipc	a0,0x6
    80002bc0:	47450513          	addi	a0,a0,1140 # 80009030 <ticks>
    80002bc4:	411c                	lw	a5,0(a0)
    80002bc6:	2785                	addiw	a5,a5,1
    80002bc8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	644080e7          	jalr	1604(ra) # 8000220e <wakeup>
  release(&tickslock);
    80002bd2:	8526                	mv	a0,s1
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	0b0080e7          	jalr	176(ra) # 80000c84 <release>
}
    80002bdc:	60e2                	ld	ra,24(sp)
    80002bde:	6442                	ld	s0,16(sp)
    80002be0:	64a2                	ld	s1,8(sp)
    80002be2:	6105                	addi	sp,sp,32
    80002be4:	8082                	ret

0000000080002be6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002be6:	1101                	addi	sp,sp,-32
    80002be8:	ec06                	sd	ra,24(sp)
    80002bea:	e822                	sd	s0,16(sp)
    80002bec:	e426                	sd	s1,8(sp)
    80002bee:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bf0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002bf4:	00074d63          	bltz	a4,80002c0e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002bf8:	57fd                	li	a5,-1
    80002bfa:	17fe                	slli	a5,a5,0x3f
    80002bfc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002bfe:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c00:	06f70363          	beq	a4,a5,80002c66 <devintr+0x80>
  }
}
    80002c04:	60e2                	ld	ra,24(sp)
    80002c06:	6442                	ld	s0,16(sp)
    80002c08:	64a2                	ld	s1,8(sp)
    80002c0a:	6105                	addi	sp,sp,32
    80002c0c:	8082                	ret
     (scause & 0xff) == 9){
    80002c0e:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002c12:	46a5                	li	a3,9
    80002c14:	fed792e3          	bne	a5,a3,80002bf8 <devintr+0x12>
    int irq = plic_claim();
    80002c18:	00003097          	auipc	ra,0x3
    80002c1c:	620080e7          	jalr	1568(ra) # 80006238 <plic_claim>
    80002c20:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c22:	47a9                	li	a5,10
    80002c24:	02f50763          	beq	a0,a5,80002c52 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002c28:	4785                	li	a5,1
    80002c2a:	02f50963          	beq	a0,a5,80002c5c <devintr+0x76>
    return 1;
    80002c2e:	4505                	li	a0,1
    } else if(irq){
    80002c30:	d8f1                	beqz	s1,80002c04 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c32:	85a6                	mv	a1,s1
    80002c34:	00005517          	auipc	a0,0x5
    80002c38:	78450513          	addi	a0,a0,1924 # 800083b8 <states.0+0x68>
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	948080e7          	jalr	-1720(ra) # 80000584 <printf>
      plic_complete(irq);
    80002c44:	8526                	mv	a0,s1
    80002c46:	00003097          	auipc	ra,0x3
    80002c4a:	616080e7          	jalr	1558(ra) # 8000625c <plic_complete>
    return 1;
    80002c4e:	4505                	li	a0,1
    80002c50:	bf55                	j	80002c04 <devintr+0x1e>
      uartintr();
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	d40080e7          	jalr	-704(ra) # 80000992 <uartintr>
    80002c5a:	b7ed                	j	80002c44 <devintr+0x5e>
      virtio_disk_intr();
    80002c5c:	00004097          	auipc	ra,0x4
    80002c60:	a8c080e7          	jalr	-1396(ra) # 800066e8 <virtio_disk_intr>
    80002c64:	b7c5                	j	80002c44 <devintr+0x5e>
    if(cpuid() == 0){
    80002c66:	fffff097          	auipc	ra,0xfffff
    80002c6a:	d04080e7          	jalr	-764(ra) # 8000196a <cpuid>
    80002c6e:	c901                	beqz	a0,80002c7e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c70:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c74:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c76:	14479073          	csrw	sip,a5
    return 2;
    80002c7a:	4509                	li	a0,2
    80002c7c:	b761                	j	80002c04 <devintr+0x1e>
      clockintr();
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	f22080e7          	jalr	-222(ra) # 80002ba0 <clockintr>
    80002c86:	b7ed                	j	80002c70 <devintr+0x8a>

0000000080002c88 <usertrap>:
{
    80002c88:	1101                	addi	sp,sp,-32
    80002c8a:	ec06                	sd	ra,24(sp)
    80002c8c:	e822                	sd	s0,16(sp)
    80002c8e:	e426                	sd	s1,8(sp)
    80002c90:	e04a                	sd	s2,0(sp)
    80002c92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c94:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c98:	1007f793          	andi	a5,a5,256
    80002c9c:	e3ad                	bnez	a5,80002cfe <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c9e:	00003797          	auipc	a5,0x3
    80002ca2:	49278793          	addi	a5,a5,1170 # 80006130 <kernelvec>
    80002ca6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	cec080e7          	jalr	-788(ra) # 80001996 <myproc>
    80002cb2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002cb4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb6:	14102773          	csrr	a4,sepc
    80002cba:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cbc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002cc0:	47a1                	li	a5,8
    80002cc2:	04f71c63          	bne	a4,a5,80002d1a <usertrap+0x92>
    if(p->killed)
    80002cc6:	551c                	lw	a5,40(a0)
    80002cc8:	e3b9                	bnez	a5,80002d0e <usertrap+0x86>
    p->trapframe->epc += 4;
    80002cca:	6cb8                	ld	a4,88(s1)
    80002ccc:	6f1c                	ld	a5,24(a4)
    80002cce:	0791                	addi	a5,a5,4
    80002cd0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cd6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cda:	10079073          	csrw	sstatus,a5
    syscall();
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	2e0080e7          	jalr	736(ra) # 80002fbe <syscall>
  if(p->killed)
    80002ce6:	549c                	lw	a5,40(s1)
    80002ce8:	ebc1                	bnez	a5,80002d78 <usertrap+0xf0>
  usertrapret();
    80002cea:	00000097          	auipc	ra,0x0
    80002cee:	e18080e7          	jalr	-488(ra) # 80002b02 <usertrapret>
}
    80002cf2:	60e2                	ld	ra,24(sp)
    80002cf4:	6442                	ld	s0,16(sp)
    80002cf6:	64a2                	ld	s1,8(sp)
    80002cf8:	6902                	ld	s2,0(sp)
    80002cfa:	6105                	addi	sp,sp,32
    80002cfc:	8082                	ret
    panic("usertrap: not from user mode");
    80002cfe:	00005517          	auipc	a0,0x5
    80002d02:	6da50513          	addi	a0,a0,1754 # 800083d8 <states.0+0x88>
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	834080e7          	jalr	-1996(ra) # 8000053a <panic>
      exit(-1);
    80002d0e:	557d                	li	a0,-1
    80002d10:	fffff097          	auipc	ra,0xfffff
    80002d14:	5ce080e7          	jalr	1486(ra) # 800022de <exit>
    80002d18:	bf4d                	j	80002cca <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002d1a:	00000097          	auipc	ra,0x0
    80002d1e:	ecc080e7          	jalr	-308(ra) # 80002be6 <devintr>
    80002d22:	892a                	mv	s2,a0
    80002d24:	c501                	beqz	a0,80002d2c <usertrap+0xa4>
  if(p->killed)
    80002d26:	549c                	lw	a5,40(s1)
    80002d28:	c3a1                	beqz	a5,80002d68 <usertrap+0xe0>
    80002d2a:	a815                	j	80002d5e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d2c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d30:	5890                	lw	a2,48(s1)
    80002d32:	00005517          	auipc	a0,0x5
    80002d36:	6c650513          	addi	a0,a0,1734 # 800083f8 <states.0+0xa8>
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	84a080e7          	jalr	-1974(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d42:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d46:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d4a:	00005517          	auipc	a0,0x5
    80002d4e:	6de50513          	addi	a0,a0,1758 # 80008428 <states.0+0xd8>
    80002d52:	ffffe097          	auipc	ra,0xffffe
    80002d56:	832080e7          	jalr	-1998(ra) # 80000584 <printf>
    p->killed = 1;
    80002d5a:	4785                	li	a5,1
    80002d5c:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002d5e:	557d                	li	a0,-1
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	57e080e7          	jalr	1406(ra) # 800022de <exit>
  if(which_dev == 2)
    80002d68:	4789                	li	a5,2
    80002d6a:	f8f910e3          	bne	s2,a5,80002cea <usertrap+0x62>
    yield();
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	2d8080e7          	jalr	728(ra) # 80002046 <yield>
    80002d76:	bf95                	j	80002cea <usertrap+0x62>
  int which_dev = 0;
    80002d78:	4901                	li	s2,0
    80002d7a:	b7d5                	j	80002d5e <usertrap+0xd6>

0000000080002d7c <kerneltrap>:
{
    80002d7c:	7179                	addi	sp,sp,-48
    80002d7e:	f406                	sd	ra,40(sp)
    80002d80:	f022                	sd	s0,32(sp)
    80002d82:	ec26                	sd	s1,24(sp)
    80002d84:	e84a                	sd	s2,16(sp)
    80002d86:	e44e                	sd	s3,8(sp)
    80002d88:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d8a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d8e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d92:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d96:	1004f793          	andi	a5,s1,256
    80002d9a:	cb85                	beqz	a5,80002dca <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d9c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002da0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002da2:	ef85                	bnez	a5,80002dda <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	e42080e7          	jalr	-446(ra) # 80002be6 <devintr>
    80002dac:	cd1d                	beqz	a0,80002dea <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002dae:	4789                	li	a5,2
    80002db0:	06f50a63          	beq	a0,a5,80002e24 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002db4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002db8:	10049073          	csrw	sstatus,s1
}
    80002dbc:	70a2                	ld	ra,40(sp)
    80002dbe:	7402                	ld	s0,32(sp)
    80002dc0:	64e2                	ld	s1,24(sp)
    80002dc2:	6942                	ld	s2,16(sp)
    80002dc4:	69a2                	ld	s3,8(sp)
    80002dc6:	6145                	addi	sp,sp,48
    80002dc8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002dca:	00005517          	auipc	a0,0x5
    80002dce:	67e50513          	addi	a0,a0,1662 # 80008448 <states.0+0xf8>
    80002dd2:	ffffd097          	auipc	ra,0xffffd
    80002dd6:	768080e7          	jalr	1896(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002dda:	00005517          	auipc	a0,0x5
    80002dde:	69650513          	addi	a0,a0,1686 # 80008470 <states.0+0x120>
    80002de2:	ffffd097          	auipc	ra,0xffffd
    80002de6:	758080e7          	jalr	1880(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002dea:	85ce                	mv	a1,s3
    80002dec:	00005517          	auipc	a0,0x5
    80002df0:	6a450513          	addi	a0,a0,1700 # 80008490 <states.0+0x140>
    80002df4:	ffffd097          	auipc	ra,0xffffd
    80002df8:	790080e7          	jalr	1936(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dfc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e00:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e04:	00005517          	auipc	a0,0x5
    80002e08:	69c50513          	addi	a0,a0,1692 # 800084a0 <states.0+0x150>
    80002e0c:	ffffd097          	auipc	ra,0xffffd
    80002e10:	778080e7          	jalr	1912(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002e14:	00005517          	auipc	a0,0x5
    80002e18:	6a450513          	addi	a0,a0,1700 # 800084b8 <states.0+0x168>
    80002e1c:	ffffd097          	auipc	ra,0xffffd
    80002e20:	71e080e7          	jalr	1822(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e24:	fffff097          	auipc	ra,0xfffff
    80002e28:	b72080e7          	jalr	-1166(ra) # 80001996 <myproc>
    80002e2c:	d541                	beqz	a0,80002db4 <kerneltrap+0x38>
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	b68080e7          	jalr	-1176(ra) # 80001996 <myproc>
    80002e36:	4d18                	lw	a4,24(a0)
    80002e38:	4791                	li	a5,4
    80002e3a:	f6f71de3          	bne	a4,a5,80002db4 <kerneltrap+0x38>
    yield();
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	208080e7          	jalr	520(ra) # 80002046 <yield>
    80002e46:	b7bd                	j	80002db4 <kerneltrap+0x38>

0000000080002e48 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e48:	1101                	addi	sp,sp,-32
    80002e4a:	ec06                	sd	ra,24(sp)
    80002e4c:	e822                	sd	s0,16(sp)
    80002e4e:	e426                	sd	s1,8(sp)
    80002e50:	1000                	addi	s0,sp,32
    80002e52:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e54:	fffff097          	auipc	ra,0xfffff
    80002e58:	b42080e7          	jalr	-1214(ra) # 80001996 <myproc>
  switch (n) {
    80002e5c:	4795                	li	a5,5
    80002e5e:	0497e163          	bltu	a5,s1,80002ea0 <argraw+0x58>
    80002e62:	048a                	slli	s1,s1,0x2
    80002e64:	00005717          	auipc	a4,0x5
    80002e68:	68c70713          	addi	a4,a4,1676 # 800084f0 <states.0+0x1a0>
    80002e6c:	94ba                	add	s1,s1,a4
    80002e6e:	409c                	lw	a5,0(s1)
    80002e70:	97ba                	add	a5,a5,a4
    80002e72:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e74:	6d3c                	ld	a5,88(a0)
    80002e76:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e78:	60e2                	ld	ra,24(sp)
    80002e7a:	6442                	ld	s0,16(sp)
    80002e7c:	64a2                	ld	s1,8(sp)
    80002e7e:	6105                	addi	sp,sp,32
    80002e80:	8082                	ret
    return p->trapframe->a1;
    80002e82:	6d3c                	ld	a5,88(a0)
    80002e84:	7fa8                	ld	a0,120(a5)
    80002e86:	bfcd                	j	80002e78 <argraw+0x30>
    return p->trapframe->a2;
    80002e88:	6d3c                	ld	a5,88(a0)
    80002e8a:	63c8                	ld	a0,128(a5)
    80002e8c:	b7f5                	j	80002e78 <argraw+0x30>
    return p->trapframe->a3;
    80002e8e:	6d3c                	ld	a5,88(a0)
    80002e90:	67c8                	ld	a0,136(a5)
    80002e92:	b7dd                	j	80002e78 <argraw+0x30>
    return p->trapframe->a4;
    80002e94:	6d3c                	ld	a5,88(a0)
    80002e96:	6bc8                	ld	a0,144(a5)
    80002e98:	b7c5                	j	80002e78 <argraw+0x30>
    return p->trapframe->a5;
    80002e9a:	6d3c                	ld	a5,88(a0)
    80002e9c:	6fc8                	ld	a0,152(a5)
    80002e9e:	bfe9                	j	80002e78 <argraw+0x30>
  panic("argraw");
    80002ea0:	00005517          	auipc	a0,0x5
    80002ea4:	62850513          	addi	a0,a0,1576 # 800084c8 <states.0+0x178>
    80002ea8:	ffffd097          	auipc	ra,0xffffd
    80002eac:	692080e7          	jalr	1682(ra) # 8000053a <panic>

0000000080002eb0 <fetchaddr>:
{
    80002eb0:	1101                	addi	sp,sp,-32
    80002eb2:	ec06                	sd	ra,24(sp)
    80002eb4:	e822                	sd	s0,16(sp)
    80002eb6:	e426                	sd	s1,8(sp)
    80002eb8:	e04a                	sd	s2,0(sp)
    80002eba:	1000                	addi	s0,sp,32
    80002ebc:	84aa                	mv	s1,a0
    80002ebe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ec0:	fffff097          	auipc	ra,0xfffff
    80002ec4:	ad6080e7          	jalr	-1322(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ec8:	653c                	ld	a5,72(a0)
    80002eca:	02f4f863          	bgeu	s1,a5,80002efa <fetchaddr+0x4a>
    80002ece:	00848713          	addi	a4,s1,8
    80002ed2:	02e7e663          	bltu	a5,a4,80002efe <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ed6:	46a1                	li	a3,8
    80002ed8:	8626                	mv	a2,s1
    80002eda:	85ca                	mv	a1,s2
    80002edc:	6928                	ld	a0,80(a0)
    80002ede:	fffff097          	auipc	ra,0xfffff
    80002ee2:	808080e7          	jalr	-2040(ra) # 800016e6 <copyin>
    80002ee6:	00a03533          	snez	a0,a0
    80002eea:	40a00533          	neg	a0,a0
}
    80002eee:	60e2                	ld	ra,24(sp)
    80002ef0:	6442                	ld	s0,16(sp)
    80002ef2:	64a2                	ld	s1,8(sp)
    80002ef4:	6902                	ld	s2,0(sp)
    80002ef6:	6105                	addi	sp,sp,32
    80002ef8:	8082                	ret
    return -1;
    80002efa:	557d                	li	a0,-1
    80002efc:	bfcd                	j	80002eee <fetchaddr+0x3e>
    80002efe:	557d                	li	a0,-1
    80002f00:	b7fd                	j	80002eee <fetchaddr+0x3e>

0000000080002f02 <fetchstr>:
{
    80002f02:	7179                	addi	sp,sp,-48
    80002f04:	f406                	sd	ra,40(sp)
    80002f06:	f022                	sd	s0,32(sp)
    80002f08:	ec26                	sd	s1,24(sp)
    80002f0a:	e84a                	sd	s2,16(sp)
    80002f0c:	e44e                	sd	s3,8(sp)
    80002f0e:	1800                	addi	s0,sp,48
    80002f10:	892a                	mv	s2,a0
    80002f12:	84ae                	mv	s1,a1
    80002f14:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	a80080e7          	jalr	-1408(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002f1e:	86ce                	mv	a3,s3
    80002f20:	864a                	mv	a2,s2
    80002f22:	85a6                	mv	a1,s1
    80002f24:	6928                	ld	a0,80(a0)
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	84e080e7          	jalr	-1970(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002f2e:	00054763          	bltz	a0,80002f3c <fetchstr+0x3a>
  return strlen(buf);
    80002f32:	8526                	mv	a0,s1
    80002f34:	ffffe097          	auipc	ra,0xffffe
    80002f38:	f14080e7          	jalr	-236(ra) # 80000e48 <strlen>
}
    80002f3c:	70a2                	ld	ra,40(sp)
    80002f3e:	7402                	ld	s0,32(sp)
    80002f40:	64e2                	ld	s1,24(sp)
    80002f42:	6942                	ld	s2,16(sp)
    80002f44:	69a2                	ld	s3,8(sp)
    80002f46:	6145                	addi	sp,sp,48
    80002f48:	8082                	ret

0000000080002f4a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002f4a:	1101                	addi	sp,sp,-32
    80002f4c:	ec06                	sd	ra,24(sp)
    80002f4e:	e822                	sd	s0,16(sp)
    80002f50:	e426                	sd	s1,8(sp)
    80002f52:	1000                	addi	s0,sp,32
    80002f54:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f56:	00000097          	auipc	ra,0x0
    80002f5a:	ef2080e7          	jalr	-270(ra) # 80002e48 <argraw>
    80002f5e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002f60:	4501                	li	a0,0
    80002f62:	60e2                	ld	ra,24(sp)
    80002f64:	6442                	ld	s0,16(sp)
    80002f66:	64a2                	ld	s1,8(sp)
    80002f68:	6105                	addi	sp,sp,32
    80002f6a:	8082                	ret

0000000080002f6c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002f6c:	1101                	addi	sp,sp,-32
    80002f6e:	ec06                	sd	ra,24(sp)
    80002f70:	e822                	sd	s0,16(sp)
    80002f72:	e426                	sd	s1,8(sp)
    80002f74:	1000                	addi	s0,sp,32
    80002f76:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f78:	00000097          	auipc	ra,0x0
    80002f7c:	ed0080e7          	jalr	-304(ra) # 80002e48 <argraw>
    80002f80:	e088                	sd	a0,0(s1)
  return 0;
}
    80002f82:	4501                	li	a0,0
    80002f84:	60e2                	ld	ra,24(sp)
    80002f86:	6442                	ld	s0,16(sp)
    80002f88:	64a2                	ld	s1,8(sp)
    80002f8a:	6105                	addi	sp,sp,32
    80002f8c:	8082                	ret

0000000080002f8e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f8e:	1101                	addi	sp,sp,-32
    80002f90:	ec06                	sd	ra,24(sp)
    80002f92:	e822                	sd	s0,16(sp)
    80002f94:	e426                	sd	s1,8(sp)
    80002f96:	e04a                	sd	s2,0(sp)
    80002f98:	1000                	addi	s0,sp,32
    80002f9a:	84ae                	mv	s1,a1
    80002f9c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f9e:	00000097          	auipc	ra,0x0
    80002fa2:	eaa080e7          	jalr	-342(ra) # 80002e48 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002fa6:	864a                	mv	a2,s2
    80002fa8:	85a6                	mv	a1,s1
    80002faa:	00000097          	auipc	ra,0x0
    80002fae:	f58080e7          	jalr	-168(ra) # 80002f02 <fetchstr>
}
    80002fb2:	60e2                	ld	ra,24(sp)
    80002fb4:	6442                	ld	s0,16(sp)
    80002fb6:	64a2                	ld	s1,8(sp)
    80002fb8:	6902                	ld	s2,0(sp)
    80002fba:	6105                	addi	sp,sp,32
    80002fbc:	8082                	ret

0000000080002fbe <syscall>:
[SYS_pinfo]   sys_pinfo,
};

void
syscall(void)
{
    80002fbe:	1101                	addi	sp,sp,-32
    80002fc0:	ec06                	sd	ra,24(sp)
    80002fc2:	e822                	sd	s0,16(sp)
    80002fc4:	e426                	sd	s1,8(sp)
    80002fc6:	e04a                	sd	s2,0(sp)
    80002fc8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002fca:	fffff097          	auipc	ra,0xfffff
    80002fce:	9cc080e7          	jalr	-1588(ra) # 80001996 <myproc>
    80002fd2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fd4:	05853903          	ld	s2,88(a0)
    80002fd8:	0a893783          	ld	a5,168(s2)
    80002fdc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fe0:	37fd                	addiw	a5,a5,-1
    80002fe2:	476d                	li	a4,27
    80002fe4:	00f76f63          	bltu	a4,a5,80003002 <syscall+0x44>
    80002fe8:	00369713          	slli	a4,a3,0x3
    80002fec:	00005797          	auipc	a5,0x5
    80002ff0:	51c78793          	addi	a5,a5,1308 # 80008508 <syscalls>
    80002ff4:	97ba                	add	a5,a5,a4
    80002ff6:	639c                	ld	a5,0(a5)
    80002ff8:	c789                	beqz	a5,80003002 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ffa:	9782                	jalr	a5
    80002ffc:	06a93823          	sd	a0,112(s2)
    80003000:	a839                	j	8000301e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003002:	15848613          	addi	a2,s1,344
    80003006:	588c                	lw	a1,48(s1)
    80003008:	00005517          	auipc	a0,0x5
    8000300c:	4c850513          	addi	a0,a0,1224 # 800084d0 <states.0+0x180>
    80003010:	ffffd097          	auipc	ra,0xffffd
    80003014:	574080e7          	jalr	1396(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003018:	6cbc                	ld	a5,88(s1)
    8000301a:	577d                	li	a4,-1
    8000301c:	fbb8                	sd	a4,112(a5)
  }
}
    8000301e:	60e2                	ld	ra,24(sp)
    80003020:	6442                	ld	s0,16(sp)
    80003022:	64a2                	ld	s1,8(sp)
    80003024:	6902                	ld	s2,0(sp)
    80003026:	6105                	addi	sp,sp,32
    80003028:	8082                	ret

000000008000302a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000302a:	1101                	addi	sp,sp,-32
    8000302c:	ec06                	sd	ra,24(sp)
    8000302e:	e822                	sd	s0,16(sp)
    80003030:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003032:	fec40593          	addi	a1,s0,-20
    80003036:	4501                	li	a0,0
    80003038:	00000097          	auipc	ra,0x0
    8000303c:	f12080e7          	jalr	-238(ra) # 80002f4a <argint>
    return -1;
    80003040:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003042:	00054963          	bltz	a0,80003054 <sys_exit+0x2a>
  exit(n);
    80003046:	fec42503          	lw	a0,-20(s0)
    8000304a:	fffff097          	auipc	ra,0xfffff
    8000304e:	294080e7          	jalr	660(ra) # 800022de <exit>
  return 0;  // not reached
    80003052:	4781                	li	a5,0
}
    80003054:	853e                	mv	a0,a5
    80003056:	60e2                	ld	ra,24(sp)
    80003058:	6442                	ld	s0,16(sp)
    8000305a:	6105                	addi	sp,sp,32
    8000305c:	8082                	ret

000000008000305e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000305e:	1141                	addi	sp,sp,-16
    80003060:	e406                	sd	ra,8(sp)
    80003062:	e022                	sd	s0,0(sp)
    80003064:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	930080e7          	jalr	-1744(ra) # 80001996 <myproc>
}
    8000306e:	5908                	lw	a0,48(a0)
    80003070:	60a2                	ld	ra,8(sp)
    80003072:	6402                	ld	s0,0(sp)
    80003074:	0141                	addi	sp,sp,16
    80003076:	8082                	ret

0000000080003078 <sys_fork>:

uint64
sys_fork(void)
{
    80003078:	1141                	addi	sp,sp,-16
    8000307a:	e406                	sd	ra,8(sp)
    8000307c:	e022                	sd	s0,0(sp)
    8000307e:	0800                	addi	s0,sp,16
  return fork();
    80003080:	fffff097          	auipc	ra,0xfffff
    80003084:	d10080e7          	jalr	-752(ra) # 80001d90 <fork>
}
    80003088:	60a2                	ld	ra,8(sp)
    8000308a:	6402                	ld	s0,0(sp)
    8000308c:	0141                	addi	sp,sp,16
    8000308e:	8082                	ret

0000000080003090 <sys_wait>:

uint64
sys_wait(void)
{
    80003090:	1101                	addi	sp,sp,-32
    80003092:	ec06                	sd	ra,24(sp)
    80003094:	e822                	sd	s0,16(sp)
    80003096:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003098:	fe840593          	addi	a1,s0,-24
    8000309c:	4501                	li	a0,0
    8000309e:	00000097          	auipc	ra,0x0
    800030a2:	ece080e7          	jalr	-306(ra) # 80002f6c <argaddr>
    800030a6:	87aa                	mv	a5,a0
    return -1;
    800030a8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800030aa:	0007c863          	bltz	a5,800030ba <sys_wait+0x2a>
  return wait(p);
    800030ae:	fe843503          	ld	a0,-24(s0)
    800030b2:	fffff097          	auipc	ra,0xfffff
    800030b6:	034080e7          	jalr	52(ra) # 800020e6 <wait>
}
    800030ba:	60e2                	ld	ra,24(sp)
    800030bc:	6442                	ld	s0,16(sp)
    800030be:	6105                	addi	sp,sp,32
    800030c0:	8082                	ret

00000000800030c2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030c2:	7179                	addi	sp,sp,-48
    800030c4:	f406                	sd	ra,40(sp)
    800030c6:	f022                	sd	s0,32(sp)
    800030c8:	ec26                	sd	s1,24(sp)
    800030ca:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800030cc:	fdc40593          	addi	a1,s0,-36
    800030d0:	4501                	li	a0,0
    800030d2:	00000097          	auipc	ra,0x0
    800030d6:	e78080e7          	jalr	-392(ra) # 80002f4a <argint>
    800030da:	87aa                	mv	a5,a0
    return -1;
    800030dc:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800030de:	0207c063          	bltz	a5,800030fe <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800030e2:	fffff097          	auipc	ra,0xfffff
    800030e6:	8b4080e7          	jalr	-1868(ra) # 80001996 <myproc>
    800030ea:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800030ec:	fdc42503          	lw	a0,-36(s0)
    800030f0:	fffff097          	auipc	ra,0xfffff
    800030f4:	c28080e7          	jalr	-984(ra) # 80001d18 <growproc>
    800030f8:	00054863          	bltz	a0,80003108 <sys_sbrk+0x46>
    return -1;
  return addr;
    800030fc:	8526                	mv	a0,s1
}
    800030fe:	70a2                	ld	ra,40(sp)
    80003100:	7402                	ld	s0,32(sp)
    80003102:	64e2                	ld	s1,24(sp)
    80003104:	6145                	addi	sp,sp,48
    80003106:	8082                	ret
    return -1;
    80003108:	557d                	li	a0,-1
    8000310a:	bfd5                	j	800030fe <sys_sbrk+0x3c>

000000008000310c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000310c:	7139                	addi	sp,sp,-64
    8000310e:	fc06                	sd	ra,56(sp)
    80003110:	f822                	sd	s0,48(sp)
    80003112:	f426                	sd	s1,40(sp)
    80003114:	f04a                	sd	s2,32(sp)
    80003116:	ec4e                	sd	s3,24(sp)
    80003118:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000311a:	fcc40593          	addi	a1,s0,-52
    8000311e:	4501                	li	a0,0
    80003120:	00000097          	auipc	ra,0x0
    80003124:	e2a080e7          	jalr	-470(ra) # 80002f4a <argint>
    return -1;
    80003128:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000312a:	06054563          	bltz	a0,80003194 <sys_sleep+0x88>
  acquire(&tickslock);
    8000312e:	00014517          	auipc	a0,0x14
    80003132:	5a250513          	addi	a0,a0,1442 # 800176d0 <tickslock>
    80003136:	ffffe097          	auipc	ra,0xffffe
    8000313a:	a9a080e7          	jalr	-1382(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    8000313e:	00006917          	auipc	s2,0x6
    80003142:	ef292903          	lw	s2,-270(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003146:	fcc42783          	lw	a5,-52(s0)
    8000314a:	cf85                	beqz	a5,80003182 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000314c:	00014997          	auipc	s3,0x14
    80003150:	58498993          	addi	s3,s3,1412 # 800176d0 <tickslock>
    80003154:	00006497          	auipc	s1,0x6
    80003158:	edc48493          	addi	s1,s1,-292 # 80009030 <ticks>
    if(myproc()->killed){
    8000315c:	fffff097          	auipc	ra,0xfffff
    80003160:	83a080e7          	jalr	-1990(ra) # 80001996 <myproc>
    80003164:	551c                	lw	a5,40(a0)
    80003166:	ef9d                	bnez	a5,800031a4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003168:	85ce                	mv	a1,s3
    8000316a:	8526                	mv	a0,s1
    8000316c:	fffff097          	auipc	ra,0xfffff
    80003170:	f16080e7          	jalr	-234(ra) # 80002082 <sleep>
  while(ticks - ticks0 < n){
    80003174:	409c                	lw	a5,0(s1)
    80003176:	412787bb          	subw	a5,a5,s2
    8000317a:	fcc42703          	lw	a4,-52(s0)
    8000317e:	fce7efe3          	bltu	a5,a4,8000315c <sys_sleep+0x50>
  }
  release(&tickslock);
    80003182:	00014517          	auipc	a0,0x14
    80003186:	54e50513          	addi	a0,a0,1358 # 800176d0 <tickslock>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	afa080e7          	jalr	-1286(ra) # 80000c84 <release>
  return 0;
    80003192:	4781                	li	a5,0
}
    80003194:	853e                	mv	a0,a5
    80003196:	70e2                	ld	ra,56(sp)
    80003198:	7442                	ld	s0,48(sp)
    8000319a:	74a2                	ld	s1,40(sp)
    8000319c:	7902                	ld	s2,32(sp)
    8000319e:	69e2                	ld	s3,24(sp)
    800031a0:	6121                	addi	sp,sp,64
    800031a2:	8082                	ret
      release(&tickslock);
    800031a4:	00014517          	auipc	a0,0x14
    800031a8:	52c50513          	addi	a0,a0,1324 # 800176d0 <tickslock>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	ad8080e7          	jalr	-1320(ra) # 80000c84 <release>
      return -1;
    800031b4:	57fd                	li	a5,-1
    800031b6:	bff9                	j	80003194 <sys_sleep+0x88>

00000000800031b8 <sys_kill>:

uint64
sys_kill(void)
{
    800031b8:	1101                	addi	sp,sp,-32
    800031ba:	ec06                	sd	ra,24(sp)
    800031bc:	e822                	sd	s0,16(sp)
    800031be:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800031c0:	fec40593          	addi	a1,s0,-20
    800031c4:	4501                	li	a0,0
    800031c6:	00000097          	auipc	ra,0x0
    800031ca:	d84080e7          	jalr	-636(ra) # 80002f4a <argint>
    800031ce:	87aa                	mv	a5,a0
    return -1;
    800031d0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800031d2:	0007c863          	bltz	a5,800031e2 <sys_kill+0x2a>
  return kill(pid);
    800031d6:	fec42503          	lw	a0,-20(s0)
    800031da:	fffff097          	auipc	ra,0xfffff
    800031de:	1e6080e7          	jalr	486(ra) # 800023c0 <kill>
}
    800031e2:	60e2                	ld	ra,24(sp)
    800031e4:	6442                	ld	s0,16(sp)
    800031e6:	6105                	addi	sp,sp,32
    800031e8:	8082                	ret

00000000800031ea <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031ea:	1101                	addi	sp,sp,-32
    800031ec:	ec06                	sd	ra,24(sp)
    800031ee:	e822                	sd	s0,16(sp)
    800031f0:	e426                	sd	s1,8(sp)
    800031f2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031f4:	00014517          	auipc	a0,0x14
    800031f8:	4dc50513          	addi	a0,a0,1244 # 800176d0 <tickslock>
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	9d4080e7          	jalr	-1580(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80003204:	00006497          	auipc	s1,0x6
    80003208:	e2c4a483          	lw	s1,-468(s1) # 80009030 <ticks>
  release(&tickslock);
    8000320c:	00014517          	auipc	a0,0x14
    80003210:	4c450513          	addi	a0,a0,1220 # 800176d0 <tickslock>
    80003214:	ffffe097          	auipc	ra,0xffffe
    80003218:	a70080e7          	jalr	-1424(ra) # 80000c84 <release>
  return xticks;
}
    8000321c:	02049513          	slli	a0,s1,0x20
    80003220:	9101                	srli	a0,a0,0x20
    80003222:	60e2                	ld	ra,24(sp)
    80003224:	6442                	ld	s0,16(sp)
    80003226:	64a2                	ld	s1,8(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret

000000008000322c <sys_getppid>:

uint64
sys_getppid(void)
{
    8000322c:	1141                	addi	sp,sp,-16
    8000322e:	e406                	sd	ra,8(sp)
    80003230:	e022                	sd	s0,0(sp)
    80003232:	0800                	addi	s0,sp,16
  struct proc* par_proc = myproc()->parent;
    80003234:	ffffe097          	auipc	ra,0xffffe
    80003238:	762080e7          	jalr	1890(ra) # 80001996 <myproc>
    8000323c:	7d1c                	ld	a5,56(a0)
  if(par_proc) return par_proc->pid;
    8000323e:	c791                	beqz	a5,8000324a <sys_getppid+0x1e>
    80003240:	5b88                	lw	a0,48(a5)
  else return -1;
}
    80003242:	60a2                	ld	ra,8(sp)
    80003244:	6402                	ld	s0,0(sp)
    80003246:	0141                	addi	sp,sp,16
    80003248:	8082                	ret
  else return -1;
    8000324a:	557d                	li	a0,-1
    8000324c:	bfdd                	j	80003242 <sys_getppid+0x16>

000000008000324e <sys_yield>:

uint64
sys_yield(void)
{
    8000324e:	1141                	addi	sp,sp,-16
    80003250:	e406                	sd	ra,8(sp)
    80003252:	e022                	sd	s0,0(sp)
    80003254:	0800                	addi	s0,sp,16
  yield();
    80003256:	fffff097          	auipc	ra,0xfffff
    8000325a:	df0080e7          	jalr	-528(ra) # 80002046 <yield>
  return 0;
}
    8000325e:	4501                	li	a0,0
    80003260:	60a2                	ld	ra,8(sp)
    80003262:	6402                	ld	s0,0(sp)
    80003264:	0141                	addi	sp,sp,16
    80003266:	8082                	ret

0000000080003268 <sys_getpa>:

uint64
sys_getpa(void)
{
    80003268:	1101                	addi	sp,sp,-32
    8000326a:	ec06                	sd	ra,24(sp)
    8000326c:	e822                	sd	s0,16(sp)
    8000326e:	1000                	addi	s0,sp,32
  int va;
  if(argint(0, &va) < 0)
    80003270:	fec40593          	addi	a1,s0,-20
    80003274:	4501                	li	a0,0
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	cd4080e7          	jalr	-812(ra) # 80002f4a <argint>
    8000327e:	87aa                	mv	a5,a0
    return -1;
    80003280:	557d                	li	a0,-1
  if(argint(0, &va) < 0)
    80003282:	0207c263          	bltz	a5,800032a6 <sys_getpa+0x3e>
    
  return walkaddr(myproc()->pagetable, va) + (va & (PGSIZE - 1));
    80003286:	ffffe097          	auipc	ra,0xffffe
    8000328a:	710080e7          	jalr	1808(ra) # 80001996 <myproc>
    8000328e:	fec42583          	lw	a1,-20(s0)
    80003292:	6928                	ld	a0,80(a0)
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	dbe080e7          	jalr	-578(ra) # 80001052 <walkaddr>
    8000329c:	fec42783          	lw	a5,-20(s0)
    800032a0:	17d2                	slli	a5,a5,0x34
    800032a2:	93d1                	srli	a5,a5,0x34
    800032a4:	953e                	add	a0,a0,a5
}
    800032a6:	60e2                	ld	ra,24(sp)
    800032a8:	6442                	ld	s0,16(sp)
    800032aa:	6105                	addi	sp,sp,32
    800032ac:	8082                	ret

00000000800032ae <sys_forkf>:

uint64
sys_forkf(void)
{
    800032ae:	1101                	addi	sp,sp,-32
    800032b0:	ec06                	sd	ra,24(sp)
    800032b2:	e822                	sd	s0,16(sp)
    800032b4:	1000                	addi	s0,sp,32
  uint64 fa;
  if(argaddr(0, &fa) < 0)
    800032b6:	fe840593          	addi	a1,s0,-24
    800032ba:	4501                	li	a0,0
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	cb0080e7          	jalr	-848(ra) # 80002f6c <argaddr>
    800032c4:	87aa                	mv	a5,a0
    return -1;
    800032c6:	557d                	li	a0,-1
  if(argaddr(0, &fa) < 0)
    800032c8:	0007c863          	bltz	a5,800032d8 <sys_forkf+0x2a>
  return forkf(fa);
    800032cc:	fe843503          	ld	a0,-24(s0)
    800032d0:	fffff097          	auipc	ra,0xfffff
    800032d4:	2be080e7          	jalr	702(ra) # 8000258e <forkf>
}
    800032d8:	60e2                	ld	ra,24(sp)
    800032da:	6442                	ld	s0,16(sp)
    800032dc:	6105                	addi	sp,sp,32
    800032de:	8082                	ret

00000000800032e0 <sys_waitpid>:

uint64
sys_waitpid(void)
{
    800032e0:	1101                	addi	sp,sp,-32
    800032e2:	ec06                	sd	ra,24(sp)
    800032e4:	e822                	sd	s0,16(sp)
    800032e6:	1000                	addi	s0,sp,32
  uint64 pid;
  uint64 p;
  if(argaddr(0, &pid) < 0)
    800032e8:	fe840593          	addi	a1,s0,-24
    800032ec:	4501                	li	a0,0
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	c7e080e7          	jalr	-898(ra) # 80002f6c <argaddr>
    800032f6:	87aa                	mv	a5,a0
    return -1;
    800032f8:	557d                	li	a0,-1
  if(argaddr(0, &pid) < 0)
    800032fa:	0207c663          	bltz	a5,80003326 <sys_waitpid+0x46>
  if(argaddr(1, &p) < 0)
    800032fe:	fe040593          	addi	a1,s0,-32
    80003302:	4505                	li	a0,1
    80003304:	00000097          	auipc	ra,0x0
    80003308:	c68080e7          	jalr	-920(ra) # 80002f6c <argaddr>
    8000330c:	02054863          	bltz	a0,8000333c <sys_waitpid+0x5c>
    return -1;
  // printf("%d\n", p);
  if(pid == -1)
    80003310:	fe843503          	ld	a0,-24(s0)
    80003314:	57fd                	li	a5,-1
    80003316:	00f50c63          	beq	a0,a5,8000332e <sys_waitpid+0x4e>
    return wait(p);
  return waitpid(pid, p);
    8000331a:	fe043583          	ld	a1,-32(s0)
    8000331e:	fffff097          	auipc	ra,0xfffff
    80003322:	3bc080e7          	jalr	956(ra) # 800026da <waitpid>
}
    80003326:	60e2                	ld	ra,24(sp)
    80003328:	6442                	ld	s0,16(sp)
    8000332a:	6105                	addi	sp,sp,32
    8000332c:	8082                	ret
    return wait(p);
    8000332e:	fe043503          	ld	a0,-32(s0)
    80003332:	fffff097          	auipc	ra,0xfffff
    80003336:	db4080e7          	jalr	-588(ra) # 800020e6 <wait>
    8000333a:	b7f5                	j	80003326 <sys_waitpid+0x46>
    return -1;
    8000333c:	557d                	li	a0,-1
    8000333e:	b7e5                	j	80003326 <sys_waitpid+0x46>

0000000080003340 <sys_ps>:

uint64
sys_ps(void){
    80003340:	1141                	addi	sp,sp,-16
    80003342:	e406                	sd	ra,8(sp)
    80003344:	e022                	sd	s0,0(sp)
    80003346:	0800                	addi	s0,sp,16
  ps();
    80003348:	fffff097          	auipc	ra,0xfffff
    8000334c:	4c6080e7          	jalr	1222(ra) # 8000280e <ps>
  return 0;
}
    80003350:	4501                	li	a0,0
    80003352:	60a2                	ld	ra,8(sp)
    80003354:	6402                	ld	s0,0(sp)
    80003356:	0141                	addi	sp,sp,16
    80003358:	8082                	ret

000000008000335a <sys_pinfo>:

uint64
sys_pinfo(void){
    8000335a:	1101                	addi	sp,sp,-32
    8000335c:	ec06                	sd	ra,24(sp)
    8000335e:	e822                	sd	s0,16(sp)
    80003360:	1000                	addi	s0,sp,32
  uint64 pid;
  struct procstat *p;
  if(argaddr(0, &pid) < 0)
    80003362:	fe840593          	addi	a1,s0,-24
    80003366:	4501                	li	a0,0
    80003368:	00000097          	auipc	ra,0x0
    8000336c:	c04080e7          	jalr	-1020(ra) # 80002f6c <argaddr>
    80003370:	04054f63          	bltz	a0,800033ce <sys_pinfo+0x74>
    return -1;
  if(pid == -1) 
    80003374:	fe843703          	ld	a4,-24(s0)
    80003378:	57fd                	li	a5,-1
    8000337a:	04f70263          	beq	a4,a5,800033be <sys_pinfo+0x64>
    pid = myproc()->pid;
  if(argaddr(1, (void*)&p))
    8000337e:	fe040593          	addi	a1,s0,-32
    80003382:	4505                	li	a0,1
    80003384:	00000097          	auipc	ra,0x0
    80003388:	be8080e7          	jalr	-1048(ra) # 80002f6c <argaddr>
    8000338c:	87aa                	mv	a5,a0
    return -1;
    8000338e:	557d                	li	a0,-1
  if(argaddr(1, (void*)&p))
    80003390:	e39d                	bnez	a5,800033b6 <sys_pinfo+0x5c>
  p = (struct procstat*)p;
  printf("sysproc: %x\n", p);
    80003392:	fe043583          	ld	a1,-32(s0)
    80003396:	00005517          	auipc	a0,0x5
    8000339a:	25a50513          	addi	a0,a0,602 # 800085f0 <syscalls+0xe8>
    8000339e:	ffffd097          	auipc	ra,0xffffd
    800033a2:	1e6080e7          	jalr	486(ra) # 80000584 <printf>
  return pinfo(pid, p);
    800033a6:	fe043583          	ld	a1,-32(s0)
    800033aa:	fe843503          	ld	a0,-24(s0)
    800033ae:	fffff097          	auipc	ra,0xfffff
    800033b2:	548080e7          	jalr	1352(ra) # 800028f6 <pinfo>
    800033b6:	60e2                	ld	ra,24(sp)
    800033b8:	6442                	ld	s0,16(sp)
    800033ba:	6105                	addi	sp,sp,32
    800033bc:	8082                	ret
    pid = myproc()->pid;
    800033be:	ffffe097          	auipc	ra,0xffffe
    800033c2:	5d8080e7          	jalr	1496(ra) # 80001996 <myproc>
    800033c6:	591c                	lw	a5,48(a0)
    800033c8:	fef43423          	sd	a5,-24(s0)
    800033cc:	bf4d                	j	8000337e <sys_pinfo+0x24>
    return -1;
    800033ce:	557d                	li	a0,-1
    800033d0:	b7dd                	j	800033b6 <sys_pinfo+0x5c>

00000000800033d2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033d2:	7179                	addi	sp,sp,-48
    800033d4:	f406                	sd	ra,40(sp)
    800033d6:	f022                	sd	s0,32(sp)
    800033d8:	ec26                	sd	s1,24(sp)
    800033da:	e84a                	sd	s2,16(sp)
    800033dc:	e44e                	sd	s3,8(sp)
    800033de:	e052                	sd	s4,0(sp)
    800033e0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033e2:	00005597          	auipc	a1,0x5
    800033e6:	21e58593          	addi	a1,a1,542 # 80008600 <syscalls+0xf8>
    800033ea:	00014517          	auipc	a0,0x14
    800033ee:	2fe50513          	addi	a0,a0,766 # 800176e8 <bcache>
    800033f2:	ffffd097          	auipc	ra,0xffffd
    800033f6:	74e080e7          	jalr	1870(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033fa:	0001c797          	auipc	a5,0x1c
    800033fe:	2ee78793          	addi	a5,a5,750 # 8001f6e8 <bcache+0x8000>
    80003402:	0001c717          	auipc	a4,0x1c
    80003406:	54e70713          	addi	a4,a4,1358 # 8001f950 <bcache+0x8268>
    8000340a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000340e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003412:	00014497          	auipc	s1,0x14
    80003416:	2ee48493          	addi	s1,s1,750 # 80017700 <bcache+0x18>
    b->next = bcache.head.next;
    8000341a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000341c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000341e:	00005a17          	auipc	s4,0x5
    80003422:	1eaa0a13          	addi	s4,s4,490 # 80008608 <syscalls+0x100>
    b->next = bcache.head.next;
    80003426:	2b893783          	ld	a5,696(s2)
    8000342a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000342c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003430:	85d2                	mv	a1,s4
    80003432:	01048513          	addi	a0,s1,16
    80003436:	00001097          	auipc	ra,0x1
    8000343a:	4c2080e7          	jalr	1218(ra) # 800048f8 <initsleeplock>
    bcache.head.next->prev = b;
    8000343e:	2b893783          	ld	a5,696(s2)
    80003442:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003444:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003448:	45848493          	addi	s1,s1,1112
    8000344c:	fd349de3          	bne	s1,s3,80003426 <binit+0x54>
  }
}
    80003450:	70a2                	ld	ra,40(sp)
    80003452:	7402                	ld	s0,32(sp)
    80003454:	64e2                	ld	s1,24(sp)
    80003456:	6942                	ld	s2,16(sp)
    80003458:	69a2                	ld	s3,8(sp)
    8000345a:	6a02                	ld	s4,0(sp)
    8000345c:	6145                	addi	sp,sp,48
    8000345e:	8082                	ret

0000000080003460 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003460:	7179                	addi	sp,sp,-48
    80003462:	f406                	sd	ra,40(sp)
    80003464:	f022                	sd	s0,32(sp)
    80003466:	ec26                	sd	s1,24(sp)
    80003468:	e84a                	sd	s2,16(sp)
    8000346a:	e44e                	sd	s3,8(sp)
    8000346c:	1800                	addi	s0,sp,48
    8000346e:	892a                	mv	s2,a0
    80003470:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003472:	00014517          	auipc	a0,0x14
    80003476:	27650513          	addi	a0,a0,630 # 800176e8 <bcache>
    8000347a:	ffffd097          	auipc	ra,0xffffd
    8000347e:	756080e7          	jalr	1878(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003482:	0001c497          	auipc	s1,0x1c
    80003486:	51e4b483          	ld	s1,1310(s1) # 8001f9a0 <bcache+0x82b8>
    8000348a:	0001c797          	auipc	a5,0x1c
    8000348e:	4c678793          	addi	a5,a5,1222 # 8001f950 <bcache+0x8268>
    80003492:	02f48f63          	beq	s1,a5,800034d0 <bread+0x70>
    80003496:	873e                	mv	a4,a5
    80003498:	a021                	j	800034a0 <bread+0x40>
    8000349a:	68a4                	ld	s1,80(s1)
    8000349c:	02e48a63          	beq	s1,a4,800034d0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034a0:	449c                	lw	a5,8(s1)
    800034a2:	ff279ce3          	bne	a5,s2,8000349a <bread+0x3a>
    800034a6:	44dc                	lw	a5,12(s1)
    800034a8:	ff3799e3          	bne	a5,s3,8000349a <bread+0x3a>
      b->refcnt++;
    800034ac:	40bc                	lw	a5,64(s1)
    800034ae:	2785                	addiw	a5,a5,1
    800034b0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034b2:	00014517          	auipc	a0,0x14
    800034b6:	23650513          	addi	a0,a0,566 # 800176e8 <bcache>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	7ca080e7          	jalr	1994(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    800034c2:	01048513          	addi	a0,s1,16
    800034c6:	00001097          	auipc	ra,0x1
    800034ca:	46c080e7          	jalr	1132(ra) # 80004932 <acquiresleep>
      return b;
    800034ce:	a8b9                	j	8000352c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034d0:	0001c497          	auipc	s1,0x1c
    800034d4:	4c84b483          	ld	s1,1224(s1) # 8001f998 <bcache+0x82b0>
    800034d8:	0001c797          	auipc	a5,0x1c
    800034dc:	47878793          	addi	a5,a5,1144 # 8001f950 <bcache+0x8268>
    800034e0:	00f48863          	beq	s1,a5,800034f0 <bread+0x90>
    800034e4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034e6:	40bc                	lw	a5,64(s1)
    800034e8:	cf81                	beqz	a5,80003500 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034ea:	64a4                	ld	s1,72(s1)
    800034ec:	fee49de3          	bne	s1,a4,800034e6 <bread+0x86>
  panic("bget: no buffers");
    800034f0:	00005517          	auipc	a0,0x5
    800034f4:	12050513          	addi	a0,a0,288 # 80008610 <syscalls+0x108>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	042080e7          	jalr	66(ra) # 8000053a <panic>
      b->dev = dev;
    80003500:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003504:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003508:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000350c:	4785                	li	a5,1
    8000350e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003510:	00014517          	auipc	a0,0x14
    80003514:	1d850513          	addi	a0,a0,472 # 800176e8 <bcache>
    80003518:	ffffd097          	auipc	ra,0xffffd
    8000351c:	76c080e7          	jalr	1900(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80003520:	01048513          	addi	a0,s1,16
    80003524:	00001097          	auipc	ra,0x1
    80003528:	40e080e7          	jalr	1038(ra) # 80004932 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000352c:	409c                	lw	a5,0(s1)
    8000352e:	cb89                	beqz	a5,80003540 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003530:	8526                	mv	a0,s1
    80003532:	70a2                	ld	ra,40(sp)
    80003534:	7402                	ld	s0,32(sp)
    80003536:	64e2                	ld	s1,24(sp)
    80003538:	6942                	ld	s2,16(sp)
    8000353a:	69a2                	ld	s3,8(sp)
    8000353c:	6145                	addi	sp,sp,48
    8000353e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003540:	4581                	li	a1,0
    80003542:	8526                	mv	a0,s1
    80003544:	00003097          	auipc	ra,0x3
    80003548:	f1e080e7          	jalr	-226(ra) # 80006462 <virtio_disk_rw>
    b->valid = 1;
    8000354c:	4785                	li	a5,1
    8000354e:	c09c                	sw	a5,0(s1)
  return b;
    80003550:	b7c5                	j	80003530 <bread+0xd0>

0000000080003552 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003552:	1101                	addi	sp,sp,-32
    80003554:	ec06                	sd	ra,24(sp)
    80003556:	e822                	sd	s0,16(sp)
    80003558:	e426                	sd	s1,8(sp)
    8000355a:	1000                	addi	s0,sp,32
    8000355c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000355e:	0541                	addi	a0,a0,16
    80003560:	00001097          	auipc	ra,0x1
    80003564:	46c080e7          	jalr	1132(ra) # 800049cc <holdingsleep>
    80003568:	cd01                	beqz	a0,80003580 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000356a:	4585                	li	a1,1
    8000356c:	8526                	mv	a0,s1
    8000356e:	00003097          	auipc	ra,0x3
    80003572:	ef4080e7          	jalr	-268(ra) # 80006462 <virtio_disk_rw>
}
    80003576:	60e2                	ld	ra,24(sp)
    80003578:	6442                	ld	s0,16(sp)
    8000357a:	64a2                	ld	s1,8(sp)
    8000357c:	6105                	addi	sp,sp,32
    8000357e:	8082                	ret
    panic("bwrite");
    80003580:	00005517          	auipc	a0,0x5
    80003584:	0a850513          	addi	a0,a0,168 # 80008628 <syscalls+0x120>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	fb2080e7          	jalr	-78(ra) # 8000053a <panic>

0000000080003590 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003590:	1101                	addi	sp,sp,-32
    80003592:	ec06                	sd	ra,24(sp)
    80003594:	e822                	sd	s0,16(sp)
    80003596:	e426                	sd	s1,8(sp)
    80003598:	e04a                	sd	s2,0(sp)
    8000359a:	1000                	addi	s0,sp,32
    8000359c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000359e:	01050913          	addi	s2,a0,16
    800035a2:	854a                	mv	a0,s2
    800035a4:	00001097          	auipc	ra,0x1
    800035a8:	428080e7          	jalr	1064(ra) # 800049cc <holdingsleep>
    800035ac:	c92d                	beqz	a0,8000361e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035ae:	854a                	mv	a0,s2
    800035b0:	00001097          	auipc	ra,0x1
    800035b4:	3d8080e7          	jalr	984(ra) # 80004988 <releasesleep>

  acquire(&bcache.lock);
    800035b8:	00014517          	auipc	a0,0x14
    800035bc:	13050513          	addi	a0,a0,304 # 800176e8 <bcache>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	610080e7          	jalr	1552(ra) # 80000bd0 <acquire>
  b->refcnt--;
    800035c8:	40bc                	lw	a5,64(s1)
    800035ca:	37fd                	addiw	a5,a5,-1
    800035cc:	0007871b          	sext.w	a4,a5
    800035d0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035d2:	eb05                	bnez	a4,80003602 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035d4:	68bc                	ld	a5,80(s1)
    800035d6:	64b8                	ld	a4,72(s1)
    800035d8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035da:	64bc                	ld	a5,72(s1)
    800035dc:	68b8                	ld	a4,80(s1)
    800035de:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035e0:	0001c797          	auipc	a5,0x1c
    800035e4:	10878793          	addi	a5,a5,264 # 8001f6e8 <bcache+0x8000>
    800035e8:	2b87b703          	ld	a4,696(a5)
    800035ec:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035ee:	0001c717          	auipc	a4,0x1c
    800035f2:	36270713          	addi	a4,a4,866 # 8001f950 <bcache+0x8268>
    800035f6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035f8:	2b87b703          	ld	a4,696(a5)
    800035fc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035fe:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003602:	00014517          	auipc	a0,0x14
    80003606:	0e650513          	addi	a0,a0,230 # 800176e8 <bcache>
    8000360a:	ffffd097          	auipc	ra,0xffffd
    8000360e:	67a080e7          	jalr	1658(ra) # 80000c84 <release>
}
    80003612:	60e2                	ld	ra,24(sp)
    80003614:	6442                	ld	s0,16(sp)
    80003616:	64a2                	ld	s1,8(sp)
    80003618:	6902                	ld	s2,0(sp)
    8000361a:	6105                	addi	sp,sp,32
    8000361c:	8082                	ret
    panic("brelse");
    8000361e:	00005517          	auipc	a0,0x5
    80003622:	01250513          	addi	a0,a0,18 # 80008630 <syscalls+0x128>
    80003626:	ffffd097          	auipc	ra,0xffffd
    8000362a:	f14080e7          	jalr	-236(ra) # 8000053a <panic>

000000008000362e <bpin>:

void
bpin(struct buf *b) {
    8000362e:	1101                	addi	sp,sp,-32
    80003630:	ec06                	sd	ra,24(sp)
    80003632:	e822                	sd	s0,16(sp)
    80003634:	e426                	sd	s1,8(sp)
    80003636:	1000                	addi	s0,sp,32
    80003638:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000363a:	00014517          	auipc	a0,0x14
    8000363e:	0ae50513          	addi	a0,a0,174 # 800176e8 <bcache>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	58e080e7          	jalr	1422(ra) # 80000bd0 <acquire>
  b->refcnt++;
    8000364a:	40bc                	lw	a5,64(s1)
    8000364c:	2785                	addiw	a5,a5,1
    8000364e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003650:	00014517          	auipc	a0,0x14
    80003654:	09850513          	addi	a0,a0,152 # 800176e8 <bcache>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	62c080e7          	jalr	1580(ra) # 80000c84 <release>
}
    80003660:	60e2                	ld	ra,24(sp)
    80003662:	6442                	ld	s0,16(sp)
    80003664:	64a2                	ld	s1,8(sp)
    80003666:	6105                	addi	sp,sp,32
    80003668:	8082                	ret

000000008000366a <bunpin>:

void
bunpin(struct buf *b) {
    8000366a:	1101                	addi	sp,sp,-32
    8000366c:	ec06                	sd	ra,24(sp)
    8000366e:	e822                	sd	s0,16(sp)
    80003670:	e426                	sd	s1,8(sp)
    80003672:	1000                	addi	s0,sp,32
    80003674:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003676:	00014517          	auipc	a0,0x14
    8000367a:	07250513          	addi	a0,a0,114 # 800176e8 <bcache>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	552080e7          	jalr	1362(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003686:	40bc                	lw	a5,64(s1)
    80003688:	37fd                	addiw	a5,a5,-1
    8000368a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000368c:	00014517          	auipc	a0,0x14
    80003690:	05c50513          	addi	a0,a0,92 # 800176e8 <bcache>
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	5f0080e7          	jalr	1520(ra) # 80000c84 <release>
}
    8000369c:	60e2                	ld	ra,24(sp)
    8000369e:	6442                	ld	s0,16(sp)
    800036a0:	64a2                	ld	s1,8(sp)
    800036a2:	6105                	addi	sp,sp,32
    800036a4:	8082                	ret

00000000800036a6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036a6:	1101                	addi	sp,sp,-32
    800036a8:	ec06                	sd	ra,24(sp)
    800036aa:	e822                	sd	s0,16(sp)
    800036ac:	e426                	sd	s1,8(sp)
    800036ae:	e04a                	sd	s2,0(sp)
    800036b0:	1000                	addi	s0,sp,32
    800036b2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036b4:	00d5d59b          	srliw	a1,a1,0xd
    800036b8:	0001c797          	auipc	a5,0x1c
    800036bc:	70c7a783          	lw	a5,1804(a5) # 8001fdc4 <sb+0x1c>
    800036c0:	9dbd                	addw	a1,a1,a5
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	d9e080e7          	jalr	-610(ra) # 80003460 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036ca:	0074f713          	andi	a4,s1,7
    800036ce:	4785                	li	a5,1
    800036d0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036d4:	14ce                	slli	s1,s1,0x33
    800036d6:	90d9                	srli	s1,s1,0x36
    800036d8:	00950733          	add	a4,a0,s1
    800036dc:	05874703          	lbu	a4,88(a4)
    800036e0:	00e7f6b3          	and	a3,a5,a4
    800036e4:	c69d                	beqz	a3,80003712 <bfree+0x6c>
    800036e6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036e8:	94aa                	add	s1,s1,a0
    800036ea:	fff7c793          	not	a5,a5
    800036ee:	8f7d                	and	a4,a4,a5
    800036f0:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800036f4:	00001097          	auipc	ra,0x1
    800036f8:	120080e7          	jalr	288(ra) # 80004814 <log_write>
  brelse(bp);
    800036fc:	854a                	mv	a0,s2
    800036fe:	00000097          	auipc	ra,0x0
    80003702:	e92080e7          	jalr	-366(ra) # 80003590 <brelse>
}
    80003706:	60e2                	ld	ra,24(sp)
    80003708:	6442                	ld	s0,16(sp)
    8000370a:	64a2                	ld	s1,8(sp)
    8000370c:	6902                	ld	s2,0(sp)
    8000370e:	6105                	addi	sp,sp,32
    80003710:	8082                	ret
    panic("freeing free block");
    80003712:	00005517          	auipc	a0,0x5
    80003716:	f2650513          	addi	a0,a0,-218 # 80008638 <syscalls+0x130>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	e20080e7          	jalr	-480(ra) # 8000053a <panic>

0000000080003722 <balloc>:
{
    80003722:	711d                	addi	sp,sp,-96
    80003724:	ec86                	sd	ra,88(sp)
    80003726:	e8a2                	sd	s0,80(sp)
    80003728:	e4a6                	sd	s1,72(sp)
    8000372a:	e0ca                	sd	s2,64(sp)
    8000372c:	fc4e                	sd	s3,56(sp)
    8000372e:	f852                	sd	s4,48(sp)
    80003730:	f456                	sd	s5,40(sp)
    80003732:	f05a                	sd	s6,32(sp)
    80003734:	ec5e                	sd	s7,24(sp)
    80003736:	e862                	sd	s8,16(sp)
    80003738:	e466                	sd	s9,8(sp)
    8000373a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000373c:	0001c797          	auipc	a5,0x1c
    80003740:	6707a783          	lw	a5,1648(a5) # 8001fdac <sb+0x4>
    80003744:	cbc1                	beqz	a5,800037d4 <balloc+0xb2>
    80003746:	8baa                	mv	s7,a0
    80003748:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000374a:	0001cb17          	auipc	s6,0x1c
    8000374e:	65eb0b13          	addi	s6,s6,1630 # 8001fda8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003752:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003754:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003756:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003758:	6c89                	lui	s9,0x2
    8000375a:	a831                	j	80003776 <balloc+0x54>
    brelse(bp);
    8000375c:	854a                	mv	a0,s2
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	e32080e7          	jalr	-462(ra) # 80003590 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003766:	015c87bb          	addw	a5,s9,s5
    8000376a:	00078a9b          	sext.w	s5,a5
    8000376e:	004b2703          	lw	a4,4(s6)
    80003772:	06eaf163          	bgeu	s5,a4,800037d4 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003776:	41fad79b          	sraiw	a5,s5,0x1f
    8000377a:	0137d79b          	srliw	a5,a5,0x13
    8000377e:	015787bb          	addw	a5,a5,s5
    80003782:	40d7d79b          	sraiw	a5,a5,0xd
    80003786:	01cb2583          	lw	a1,28(s6)
    8000378a:	9dbd                	addw	a1,a1,a5
    8000378c:	855e                	mv	a0,s7
    8000378e:	00000097          	auipc	ra,0x0
    80003792:	cd2080e7          	jalr	-814(ra) # 80003460 <bread>
    80003796:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003798:	004b2503          	lw	a0,4(s6)
    8000379c:	000a849b          	sext.w	s1,s5
    800037a0:	8762                	mv	a4,s8
    800037a2:	faa4fde3          	bgeu	s1,a0,8000375c <balloc+0x3a>
      m = 1 << (bi % 8);
    800037a6:	00777693          	andi	a3,a4,7
    800037aa:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037ae:	41f7579b          	sraiw	a5,a4,0x1f
    800037b2:	01d7d79b          	srliw	a5,a5,0x1d
    800037b6:	9fb9                	addw	a5,a5,a4
    800037b8:	4037d79b          	sraiw	a5,a5,0x3
    800037bc:	00f90633          	add	a2,s2,a5
    800037c0:	05864603          	lbu	a2,88(a2)
    800037c4:	00c6f5b3          	and	a1,a3,a2
    800037c8:	cd91                	beqz	a1,800037e4 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037ca:	2705                	addiw	a4,a4,1
    800037cc:	2485                	addiw	s1,s1,1
    800037ce:	fd471ae3          	bne	a4,s4,800037a2 <balloc+0x80>
    800037d2:	b769                	j	8000375c <balloc+0x3a>
  panic("balloc: out of blocks");
    800037d4:	00005517          	auipc	a0,0x5
    800037d8:	e7c50513          	addi	a0,a0,-388 # 80008650 <syscalls+0x148>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	d5e080e7          	jalr	-674(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037e4:	97ca                	add	a5,a5,s2
    800037e6:	8e55                	or	a2,a2,a3
    800037e8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800037ec:	854a                	mv	a0,s2
    800037ee:	00001097          	auipc	ra,0x1
    800037f2:	026080e7          	jalr	38(ra) # 80004814 <log_write>
        brelse(bp);
    800037f6:	854a                	mv	a0,s2
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	d98080e7          	jalr	-616(ra) # 80003590 <brelse>
  bp = bread(dev, bno);
    80003800:	85a6                	mv	a1,s1
    80003802:	855e                	mv	a0,s7
    80003804:	00000097          	auipc	ra,0x0
    80003808:	c5c080e7          	jalr	-932(ra) # 80003460 <bread>
    8000380c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000380e:	40000613          	li	a2,1024
    80003812:	4581                	li	a1,0
    80003814:	05850513          	addi	a0,a0,88
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	4b4080e7          	jalr	1204(ra) # 80000ccc <memset>
  log_write(bp);
    80003820:	854a                	mv	a0,s2
    80003822:	00001097          	auipc	ra,0x1
    80003826:	ff2080e7          	jalr	-14(ra) # 80004814 <log_write>
  brelse(bp);
    8000382a:	854a                	mv	a0,s2
    8000382c:	00000097          	auipc	ra,0x0
    80003830:	d64080e7          	jalr	-668(ra) # 80003590 <brelse>
}
    80003834:	8526                	mv	a0,s1
    80003836:	60e6                	ld	ra,88(sp)
    80003838:	6446                	ld	s0,80(sp)
    8000383a:	64a6                	ld	s1,72(sp)
    8000383c:	6906                	ld	s2,64(sp)
    8000383e:	79e2                	ld	s3,56(sp)
    80003840:	7a42                	ld	s4,48(sp)
    80003842:	7aa2                	ld	s5,40(sp)
    80003844:	7b02                	ld	s6,32(sp)
    80003846:	6be2                	ld	s7,24(sp)
    80003848:	6c42                	ld	s8,16(sp)
    8000384a:	6ca2                	ld	s9,8(sp)
    8000384c:	6125                	addi	sp,sp,96
    8000384e:	8082                	ret

0000000080003850 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003850:	7179                	addi	sp,sp,-48
    80003852:	f406                	sd	ra,40(sp)
    80003854:	f022                	sd	s0,32(sp)
    80003856:	ec26                	sd	s1,24(sp)
    80003858:	e84a                	sd	s2,16(sp)
    8000385a:	e44e                	sd	s3,8(sp)
    8000385c:	e052                	sd	s4,0(sp)
    8000385e:	1800                	addi	s0,sp,48
    80003860:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003862:	47ad                	li	a5,11
    80003864:	04b7fe63          	bgeu	a5,a1,800038c0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003868:	ff45849b          	addiw	s1,a1,-12
    8000386c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003870:	0ff00793          	li	a5,255
    80003874:	0ae7e463          	bltu	a5,a4,8000391c <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003878:	08052583          	lw	a1,128(a0)
    8000387c:	c5b5                	beqz	a1,800038e8 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000387e:	00092503          	lw	a0,0(s2)
    80003882:	00000097          	auipc	ra,0x0
    80003886:	bde080e7          	jalr	-1058(ra) # 80003460 <bread>
    8000388a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000388c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003890:	02049713          	slli	a4,s1,0x20
    80003894:	01e75593          	srli	a1,a4,0x1e
    80003898:	00b784b3          	add	s1,a5,a1
    8000389c:	0004a983          	lw	s3,0(s1)
    800038a0:	04098e63          	beqz	s3,800038fc <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800038a4:	8552                	mv	a0,s4
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	cea080e7          	jalr	-790(ra) # 80003590 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038ae:	854e                	mv	a0,s3
    800038b0:	70a2                	ld	ra,40(sp)
    800038b2:	7402                	ld	s0,32(sp)
    800038b4:	64e2                	ld	s1,24(sp)
    800038b6:	6942                	ld	s2,16(sp)
    800038b8:	69a2                	ld	s3,8(sp)
    800038ba:	6a02                	ld	s4,0(sp)
    800038bc:	6145                	addi	sp,sp,48
    800038be:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800038c0:	02059793          	slli	a5,a1,0x20
    800038c4:	01e7d593          	srli	a1,a5,0x1e
    800038c8:	00b504b3          	add	s1,a0,a1
    800038cc:	0504a983          	lw	s3,80(s1)
    800038d0:	fc099fe3          	bnez	s3,800038ae <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800038d4:	4108                	lw	a0,0(a0)
    800038d6:	00000097          	auipc	ra,0x0
    800038da:	e4c080e7          	jalr	-436(ra) # 80003722 <balloc>
    800038de:	0005099b          	sext.w	s3,a0
    800038e2:	0534a823          	sw	s3,80(s1)
    800038e6:	b7e1                	j	800038ae <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800038e8:	4108                	lw	a0,0(a0)
    800038ea:	00000097          	auipc	ra,0x0
    800038ee:	e38080e7          	jalr	-456(ra) # 80003722 <balloc>
    800038f2:	0005059b          	sext.w	a1,a0
    800038f6:	08b92023          	sw	a1,128(s2)
    800038fa:	b751                	j	8000387e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800038fc:	00092503          	lw	a0,0(s2)
    80003900:	00000097          	auipc	ra,0x0
    80003904:	e22080e7          	jalr	-478(ra) # 80003722 <balloc>
    80003908:	0005099b          	sext.w	s3,a0
    8000390c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003910:	8552                	mv	a0,s4
    80003912:	00001097          	auipc	ra,0x1
    80003916:	f02080e7          	jalr	-254(ra) # 80004814 <log_write>
    8000391a:	b769                	j	800038a4 <bmap+0x54>
  panic("bmap: out of range");
    8000391c:	00005517          	auipc	a0,0x5
    80003920:	d4c50513          	addi	a0,a0,-692 # 80008668 <syscalls+0x160>
    80003924:	ffffd097          	auipc	ra,0xffffd
    80003928:	c16080e7          	jalr	-1002(ra) # 8000053a <panic>

000000008000392c <iget>:
{
    8000392c:	7179                	addi	sp,sp,-48
    8000392e:	f406                	sd	ra,40(sp)
    80003930:	f022                	sd	s0,32(sp)
    80003932:	ec26                	sd	s1,24(sp)
    80003934:	e84a                	sd	s2,16(sp)
    80003936:	e44e                	sd	s3,8(sp)
    80003938:	e052                	sd	s4,0(sp)
    8000393a:	1800                	addi	s0,sp,48
    8000393c:	89aa                	mv	s3,a0
    8000393e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003940:	0001c517          	auipc	a0,0x1c
    80003944:	48850513          	addi	a0,a0,1160 # 8001fdc8 <itable>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	288080e7          	jalr	648(ra) # 80000bd0 <acquire>
  empty = 0;
    80003950:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003952:	0001c497          	auipc	s1,0x1c
    80003956:	48e48493          	addi	s1,s1,1166 # 8001fde0 <itable+0x18>
    8000395a:	0001e697          	auipc	a3,0x1e
    8000395e:	f1668693          	addi	a3,a3,-234 # 80021870 <log>
    80003962:	a039                	j	80003970 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003964:	02090b63          	beqz	s2,8000399a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003968:	08848493          	addi	s1,s1,136
    8000396c:	02d48a63          	beq	s1,a3,800039a0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003970:	449c                	lw	a5,8(s1)
    80003972:	fef059e3          	blez	a5,80003964 <iget+0x38>
    80003976:	4098                	lw	a4,0(s1)
    80003978:	ff3716e3          	bne	a4,s3,80003964 <iget+0x38>
    8000397c:	40d8                	lw	a4,4(s1)
    8000397e:	ff4713e3          	bne	a4,s4,80003964 <iget+0x38>
      ip->ref++;
    80003982:	2785                	addiw	a5,a5,1
    80003984:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003986:	0001c517          	auipc	a0,0x1c
    8000398a:	44250513          	addi	a0,a0,1090 # 8001fdc8 <itable>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	2f6080e7          	jalr	758(ra) # 80000c84 <release>
      return ip;
    80003996:	8926                	mv	s2,s1
    80003998:	a03d                	j	800039c6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000399a:	f7f9                	bnez	a5,80003968 <iget+0x3c>
    8000399c:	8926                	mv	s2,s1
    8000399e:	b7e9                	j	80003968 <iget+0x3c>
  if(empty == 0)
    800039a0:	02090c63          	beqz	s2,800039d8 <iget+0xac>
  ip->dev = dev;
    800039a4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039a8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039ac:	4785                	li	a5,1
    800039ae:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039b2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039b6:	0001c517          	auipc	a0,0x1c
    800039ba:	41250513          	addi	a0,a0,1042 # 8001fdc8 <itable>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	2c6080e7          	jalr	710(ra) # 80000c84 <release>
}
    800039c6:	854a                	mv	a0,s2
    800039c8:	70a2                	ld	ra,40(sp)
    800039ca:	7402                	ld	s0,32(sp)
    800039cc:	64e2                	ld	s1,24(sp)
    800039ce:	6942                	ld	s2,16(sp)
    800039d0:	69a2                	ld	s3,8(sp)
    800039d2:	6a02                	ld	s4,0(sp)
    800039d4:	6145                	addi	sp,sp,48
    800039d6:	8082                	ret
    panic("iget: no inodes");
    800039d8:	00005517          	auipc	a0,0x5
    800039dc:	ca850513          	addi	a0,a0,-856 # 80008680 <syscalls+0x178>
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	b5a080e7          	jalr	-1190(ra) # 8000053a <panic>

00000000800039e8 <fsinit>:
fsinit(int dev) {
    800039e8:	7179                	addi	sp,sp,-48
    800039ea:	f406                	sd	ra,40(sp)
    800039ec:	f022                	sd	s0,32(sp)
    800039ee:	ec26                	sd	s1,24(sp)
    800039f0:	e84a                	sd	s2,16(sp)
    800039f2:	e44e                	sd	s3,8(sp)
    800039f4:	1800                	addi	s0,sp,48
    800039f6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039f8:	4585                	li	a1,1
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	a66080e7          	jalr	-1434(ra) # 80003460 <bread>
    80003a02:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a04:	0001c997          	auipc	s3,0x1c
    80003a08:	3a498993          	addi	s3,s3,932 # 8001fda8 <sb>
    80003a0c:	02000613          	li	a2,32
    80003a10:	05850593          	addi	a1,a0,88
    80003a14:	854e                	mv	a0,s3
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	312080e7          	jalr	786(ra) # 80000d28 <memmove>
  brelse(bp);
    80003a1e:	8526                	mv	a0,s1
    80003a20:	00000097          	auipc	ra,0x0
    80003a24:	b70080e7          	jalr	-1168(ra) # 80003590 <brelse>
  if(sb.magic != FSMAGIC)
    80003a28:	0009a703          	lw	a4,0(s3)
    80003a2c:	102037b7          	lui	a5,0x10203
    80003a30:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a34:	02f71263          	bne	a4,a5,80003a58 <fsinit+0x70>
  initlog(dev, &sb);
    80003a38:	0001c597          	auipc	a1,0x1c
    80003a3c:	37058593          	addi	a1,a1,880 # 8001fda8 <sb>
    80003a40:	854a                	mv	a0,s2
    80003a42:	00001097          	auipc	ra,0x1
    80003a46:	b56080e7          	jalr	-1194(ra) # 80004598 <initlog>
}
    80003a4a:	70a2                	ld	ra,40(sp)
    80003a4c:	7402                	ld	s0,32(sp)
    80003a4e:	64e2                	ld	s1,24(sp)
    80003a50:	6942                	ld	s2,16(sp)
    80003a52:	69a2                	ld	s3,8(sp)
    80003a54:	6145                	addi	sp,sp,48
    80003a56:	8082                	ret
    panic("invalid file system");
    80003a58:	00005517          	auipc	a0,0x5
    80003a5c:	c3850513          	addi	a0,a0,-968 # 80008690 <syscalls+0x188>
    80003a60:	ffffd097          	auipc	ra,0xffffd
    80003a64:	ada080e7          	jalr	-1318(ra) # 8000053a <panic>

0000000080003a68 <iinit>:
{
    80003a68:	7179                	addi	sp,sp,-48
    80003a6a:	f406                	sd	ra,40(sp)
    80003a6c:	f022                	sd	s0,32(sp)
    80003a6e:	ec26                	sd	s1,24(sp)
    80003a70:	e84a                	sd	s2,16(sp)
    80003a72:	e44e                	sd	s3,8(sp)
    80003a74:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a76:	00005597          	auipc	a1,0x5
    80003a7a:	c3258593          	addi	a1,a1,-974 # 800086a8 <syscalls+0x1a0>
    80003a7e:	0001c517          	auipc	a0,0x1c
    80003a82:	34a50513          	addi	a0,a0,842 # 8001fdc8 <itable>
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	0ba080e7          	jalr	186(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a8e:	0001c497          	auipc	s1,0x1c
    80003a92:	36248493          	addi	s1,s1,866 # 8001fdf0 <itable+0x28>
    80003a96:	0001e997          	auipc	s3,0x1e
    80003a9a:	dea98993          	addi	s3,s3,-534 # 80021880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a9e:	00005917          	auipc	s2,0x5
    80003aa2:	c1290913          	addi	s2,s2,-1006 # 800086b0 <syscalls+0x1a8>
    80003aa6:	85ca                	mv	a1,s2
    80003aa8:	8526                	mv	a0,s1
    80003aaa:	00001097          	auipc	ra,0x1
    80003aae:	e4e080e7          	jalr	-434(ra) # 800048f8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ab2:	08848493          	addi	s1,s1,136
    80003ab6:	ff3498e3          	bne	s1,s3,80003aa6 <iinit+0x3e>
}
    80003aba:	70a2                	ld	ra,40(sp)
    80003abc:	7402                	ld	s0,32(sp)
    80003abe:	64e2                	ld	s1,24(sp)
    80003ac0:	6942                	ld	s2,16(sp)
    80003ac2:	69a2                	ld	s3,8(sp)
    80003ac4:	6145                	addi	sp,sp,48
    80003ac6:	8082                	ret

0000000080003ac8 <ialloc>:
{
    80003ac8:	715d                	addi	sp,sp,-80
    80003aca:	e486                	sd	ra,72(sp)
    80003acc:	e0a2                	sd	s0,64(sp)
    80003ace:	fc26                	sd	s1,56(sp)
    80003ad0:	f84a                	sd	s2,48(sp)
    80003ad2:	f44e                	sd	s3,40(sp)
    80003ad4:	f052                	sd	s4,32(sp)
    80003ad6:	ec56                	sd	s5,24(sp)
    80003ad8:	e85a                	sd	s6,16(sp)
    80003ada:	e45e                	sd	s7,8(sp)
    80003adc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ade:	0001c717          	auipc	a4,0x1c
    80003ae2:	2d672703          	lw	a4,726(a4) # 8001fdb4 <sb+0xc>
    80003ae6:	4785                	li	a5,1
    80003ae8:	04e7fa63          	bgeu	a5,a4,80003b3c <ialloc+0x74>
    80003aec:	8aaa                	mv	s5,a0
    80003aee:	8bae                	mv	s7,a1
    80003af0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003af2:	0001ca17          	auipc	s4,0x1c
    80003af6:	2b6a0a13          	addi	s4,s4,694 # 8001fda8 <sb>
    80003afa:	00048b1b          	sext.w	s6,s1
    80003afe:	0044d593          	srli	a1,s1,0x4
    80003b02:	018a2783          	lw	a5,24(s4)
    80003b06:	9dbd                	addw	a1,a1,a5
    80003b08:	8556                	mv	a0,s5
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	956080e7          	jalr	-1706(ra) # 80003460 <bread>
    80003b12:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b14:	05850993          	addi	s3,a0,88
    80003b18:	00f4f793          	andi	a5,s1,15
    80003b1c:	079a                	slli	a5,a5,0x6
    80003b1e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b20:	00099783          	lh	a5,0(s3)
    80003b24:	c785                	beqz	a5,80003b4c <ialloc+0x84>
    brelse(bp);
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	a6a080e7          	jalr	-1430(ra) # 80003590 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b2e:	0485                	addi	s1,s1,1
    80003b30:	00ca2703          	lw	a4,12(s4)
    80003b34:	0004879b          	sext.w	a5,s1
    80003b38:	fce7e1e3          	bltu	a5,a4,80003afa <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b3c:	00005517          	auipc	a0,0x5
    80003b40:	b7c50513          	addi	a0,a0,-1156 # 800086b8 <syscalls+0x1b0>
    80003b44:	ffffd097          	auipc	ra,0xffffd
    80003b48:	9f6080e7          	jalr	-1546(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003b4c:	04000613          	li	a2,64
    80003b50:	4581                	li	a1,0
    80003b52:	854e                	mv	a0,s3
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	178080e7          	jalr	376(ra) # 80000ccc <memset>
      dip->type = type;
    80003b5c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b60:	854a                	mv	a0,s2
    80003b62:	00001097          	auipc	ra,0x1
    80003b66:	cb2080e7          	jalr	-846(ra) # 80004814 <log_write>
      brelse(bp);
    80003b6a:	854a                	mv	a0,s2
    80003b6c:	00000097          	auipc	ra,0x0
    80003b70:	a24080e7          	jalr	-1500(ra) # 80003590 <brelse>
      return iget(dev, inum);
    80003b74:	85da                	mv	a1,s6
    80003b76:	8556                	mv	a0,s5
    80003b78:	00000097          	auipc	ra,0x0
    80003b7c:	db4080e7          	jalr	-588(ra) # 8000392c <iget>
}
    80003b80:	60a6                	ld	ra,72(sp)
    80003b82:	6406                	ld	s0,64(sp)
    80003b84:	74e2                	ld	s1,56(sp)
    80003b86:	7942                	ld	s2,48(sp)
    80003b88:	79a2                	ld	s3,40(sp)
    80003b8a:	7a02                	ld	s4,32(sp)
    80003b8c:	6ae2                	ld	s5,24(sp)
    80003b8e:	6b42                	ld	s6,16(sp)
    80003b90:	6ba2                	ld	s7,8(sp)
    80003b92:	6161                	addi	sp,sp,80
    80003b94:	8082                	ret

0000000080003b96 <iupdate>:
{
    80003b96:	1101                	addi	sp,sp,-32
    80003b98:	ec06                	sd	ra,24(sp)
    80003b9a:	e822                	sd	s0,16(sp)
    80003b9c:	e426                	sd	s1,8(sp)
    80003b9e:	e04a                	sd	s2,0(sp)
    80003ba0:	1000                	addi	s0,sp,32
    80003ba2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ba4:	415c                	lw	a5,4(a0)
    80003ba6:	0047d79b          	srliw	a5,a5,0x4
    80003baa:	0001c597          	auipc	a1,0x1c
    80003bae:	2165a583          	lw	a1,534(a1) # 8001fdc0 <sb+0x18>
    80003bb2:	9dbd                	addw	a1,a1,a5
    80003bb4:	4108                	lw	a0,0(a0)
    80003bb6:	00000097          	auipc	ra,0x0
    80003bba:	8aa080e7          	jalr	-1878(ra) # 80003460 <bread>
    80003bbe:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bc0:	05850793          	addi	a5,a0,88
    80003bc4:	40d8                	lw	a4,4(s1)
    80003bc6:	8b3d                	andi	a4,a4,15
    80003bc8:	071a                	slli	a4,a4,0x6
    80003bca:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003bcc:	04449703          	lh	a4,68(s1)
    80003bd0:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003bd4:	04649703          	lh	a4,70(s1)
    80003bd8:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003bdc:	04849703          	lh	a4,72(s1)
    80003be0:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003be4:	04a49703          	lh	a4,74(s1)
    80003be8:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003bec:	44f8                	lw	a4,76(s1)
    80003bee:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bf0:	03400613          	li	a2,52
    80003bf4:	05048593          	addi	a1,s1,80
    80003bf8:	00c78513          	addi	a0,a5,12
    80003bfc:	ffffd097          	auipc	ra,0xffffd
    80003c00:	12c080e7          	jalr	300(ra) # 80000d28 <memmove>
  log_write(bp);
    80003c04:	854a                	mv	a0,s2
    80003c06:	00001097          	auipc	ra,0x1
    80003c0a:	c0e080e7          	jalr	-1010(ra) # 80004814 <log_write>
  brelse(bp);
    80003c0e:	854a                	mv	a0,s2
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	980080e7          	jalr	-1664(ra) # 80003590 <brelse>
}
    80003c18:	60e2                	ld	ra,24(sp)
    80003c1a:	6442                	ld	s0,16(sp)
    80003c1c:	64a2                	ld	s1,8(sp)
    80003c1e:	6902                	ld	s2,0(sp)
    80003c20:	6105                	addi	sp,sp,32
    80003c22:	8082                	ret

0000000080003c24 <idup>:
{
    80003c24:	1101                	addi	sp,sp,-32
    80003c26:	ec06                	sd	ra,24(sp)
    80003c28:	e822                	sd	s0,16(sp)
    80003c2a:	e426                	sd	s1,8(sp)
    80003c2c:	1000                	addi	s0,sp,32
    80003c2e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c30:	0001c517          	auipc	a0,0x1c
    80003c34:	19850513          	addi	a0,a0,408 # 8001fdc8 <itable>
    80003c38:	ffffd097          	auipc	ra,0xffffd
    80003c3c:	f98080e7          	jalr	-104(ra) # 80000bd0 <acquire>
  ip->ref++;
    80003c40:	449c                	lw	a5,8(s1)
    80003c42:	2785                	addiw	a5,a5,1
    80003c44:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c46:	0001c517          	auipc	a0,0x1c
    80003c4a:	18250513          	addi	a0,a0,386 # 8001fdc8 <itable>
    80003c4e:	ffffd097          	auipc	ra,0xffffd
    80003c52:	036080e7          	jalr	54(ra) # 80000c84 <release>
}
    80003c56:	8526                	mv	a0,s1
    80003c58:	60e2                	ld	ra,24(sp)
    80003c5a:	6442                	ld	s0,16(sp)
    80003c5c:	64a2                	ld	s1,8(sp)
    80003c5e:	6105                	addi	sp,sp,32
    80003c60:	8082                	ret

0000000080003c62 <ilock>:
{
    80003c62:	1101                	addi	sp,sp,-32
    80003c64:	ec06                	sd	ra,24(sp)
    80003c66:	e822                	sd	s0,16(sp)
    80003c68:	e426                	sd	s1,8(sp)
    80003c6a:	e04a                	sd	s2,0(sp)
    80003c6c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c6e:	c115                	beqz	a0,80003c92 <ilock+0x30>
    80003c70:	84aa                	mv	s1,a0
    80003c72:	451c                	lw	a5,8(a0)
    80003c74:	00f05f63          	blez	a5,80003c92 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c78:	0541                	addi	a0,a0,16
    80003c7a:	00001097          	auipc	ra,0x1
    80003c7e:	cb8080e7          	jalr	-840(ra) # 80004932 <acquiresleep>
  if(ip->valid == 0){
    80003c82:	40bc                	lw	a5,64(s1)
    80003c84:	cf99                	beqz	a5,80003ca2 <ilock+0x40>
}
    80003c86:	60e2                	ld	ra,24(sp)
    80003c88:	6442                	ld	s0,16(sp)
    80003c8a:	64a2                	ld	s1,8(sp)
    80003c8c:	6902                	ld	s2,0(sp)
    80003c8e:	6105                	addi	sp,sp,32
    80003c90:	8082                	ret
    panic("ilock");
    80003c92:	00005517          	auipc	a0,0x5
    80003c96:	a3e50513          	addi	a0,a0,-1474 # 800086d0 <syscalls+0x1c8>
    80003c9a:	ffffd097          	auipc	ra,0xffffd
    80003c9e:	8a0080e7          	jalr	-1888(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ca2:	40dc                	lw	a5,4(s1)
    80003ca4:	0047d79b          	srliw	a5,a5,0x4
    80003ca8:	0001c597          	auipc	a1,0x1c
    80003cac:	1185a583          	lw	a1,280(a1) # 8001fdc0 <sb+0x18>
    80003cb0:	9dbd                	addw	a1,a1,a5
    80003cb2:	4088                	lw	a0,0(s1)
    80003cb4:	fffff097          	auipc	ra,0xfffff
    80003cb8:	7ac080e7          	jalr	1964(ra) # 80003460 <bread>
    80003cbc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cbe:	05850593          	addi	a1,a0,88
    80003cc2:	40dc                	lw	a5,4(s1)
    80003cc4:	8bbd                	andi	a5,a5,15
    80003cc6:	079a                	slli	a5,a5,0x6
    80003cc8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003cca:	00059783          	lh	a5,0(a1)
    80003cce:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cd2:	00259783          	lh	a5,2(a1)
    80003cd6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cda:	00459783          	lh	a5,4(a1)
    80003cde:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ce2:	00659783          	lh	a5,6(a1)
    80003ce6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cea:	459c                	lw	a5,8(a1)
    80003cec:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cee:	03400613          	li	a2,52
    80003cf2:	05b1                	addi	a1,a1,12
    80003cf4:	05048513          	addi	a0,s1,80
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	030080e7          	jalr	48(ra) # 80000d28 <memmove>
    brelse(bp);
    80003d00:	854a                	mv	a0,s2
    80003d02:	00000097          	auipc	ra,0x0
    80003d06:	88e080e7          	jalr	-1906(ra) # 80003590 <brelse>
    ip->valid = 1;
    80003d0a:	4785                	li	a5,1
    80003d0c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d0e:	04449783          	lh	a5,68(s1)
    80003d12:	fbb5                	bnez	a5,80003c86 <ilock+0x24>
      panic("ilock: no type");
    80003d14:	00005517          	auipc	a0,0x5
    80003d18:	9c450513          	addi	a0,a0,-1596 # 800086d8 <syscalls+0x1d0>
    80003d1c:	ffffd097          	auipc	ra,0xffffd
    80003d20:	81e080e7          	jalr	-2018(ra) # 8000053a <panic>

0000000080003d24 <iunlock>:
{
    80003d24:	1101                	addi	sp,sp,-32
    80003d26:	ec06                	sd	ra,24(sp)
    80003d28:	e822                	sd	s0,16(sp)
    80003d2a:	e426                	sd	s1,8(sp)
    80003d2c:	e04a                	sd	s2,0(sp)
    80003d2e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d30:	c905                	beqz	a0,80003d60 <iunlock+0x3c>
    80003d32:	84aa                	mv	s1,a0
    80003d34:	01050913          	addi	s2,a0,16
    80003d38:	854a                	mv	a0,s2
    80003d3a:	00001097          	auipc	ra,0x1
    80003d3e:	c92080e7          	jalr	-878(ra) # 800049cc <holdingsleep>
    80003d42:	cd19                	beqz	a0,80003d60 <iunlock+0x3c>
    80003d44:	449c                	lw	a5,8(s1)
    80003d46:	00f05d63          	blez	a5,80003d60 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d4a:	854a                	mv	a0,s2
    80003d4c:	00001097          	auipc	ra,0x1
    80003d50:	c3c080e7          	jalr	-964(ra) # 80004988 <releasesleep>
}
    80003d54:	60e2                	ld	ra,24(sp)
    80003d56:	6442                	ld	s0,16(sp)
    80003d58:	64a2                	ld	s1,8(sp)
    80003d5a:	6902                	ld	s2,0(sp)
    80003d5c:	6105                	addi	sp,sp,32
    80003d5e:	8082                	ret
    panic("iunlock");
    80003d60:	00005517          	auipc	a0,0x5
    80003d64:	98850513          	addi	a0,a0,-1656 # 800086e8 <syscalls+0x1e0>
    80003d68:	ffffc097          	auipc	ra,0xffffc
    80003d6c:	7d2080e7          	jalr	2002(ra) # 8000053a <panic>

0000000080003d70 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d70:	7179                	addi	sp,sp,-48
    80003d72:	f406                	sd	ra,40(sp)
    80003d74:	f022                	sd	s0,32(sp)
    80003d76:	ec26                	sd	s1,24(sp)
    80003d78:	e84a                	sd	s2,16(sp)
    80003d7a:	e44e                	sd	s3,8(sp)
    80003d7c:	e052                	sd	s4,0(sp)
    80003d7e:	1800                	addi	s0,sp,48
    80003d80:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d82:	05050493          	addi	s1,a0,80
    80003d86:	08050913          	addi	s2,a0,128
    80003d8a:	a021                	j	80003d92 <itrunc+0x22>
    80003d8c:	0491                	addi	s1,s1,4
    80003d8e:	01248d63          	beq	s1,s2,80003da8 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d92:	408c                	lw	a1,0(s1)
    80003d94:	dde5                	beqz	a1,80003d8c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d96:	0009a503          	lw	a0,0(s3)
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	90c080e7          	jalr	-1780(ra) # 800036a6 <bfree>
      ip->addrs[i] = 0;
    80003da2:	0004a023          	sw	zero,0(s1)
    80003da6:	b7dd                	j	80003d8c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003da8:	0809a583          	lw	a1,128(s3)
    80003dac:	e185                	bnez	a1,80003dcc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003dae:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003db2:	854e                	mv	a0,s3
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	de2080e7          	jalr	-542(ra) # 80003b96 <iupdate>
}
    80003dbc:	70a2                	ld	ra,40(sp)
    80003dbe:	7402                	ld	s0,32(sp)
    80003dc0:	64e2                	ld	s1,24(sp)
    80003dc2:	6942                	ld	s2,16(sp)
    80003dc4:	69a2                	ld	s3,8(sp)
    80003dc6:	6a02                	ld	s4,0(sp)
    80003dc8:	6145                	addi	sp,sp,48
    80003dca:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003dcc:	0009a503          	lw	a0,0(s3)
    80003dd0:	fffff097          	auipc	ra,0xfffff
    80003dd4:	690080e7          	jalr	1680(ra) # 80003460 <bread>
    80003dd8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003dda:	05850493          	addi	s1,a0,88
    80003dde:	45850913          	addi	s2,a0,1112
    80003de2:	a021                	j	80003dea <itrunc+0x7a>
    80003de4:	0491                	addi	s1,s1,4
    80003de6:	01248b63          	beq	s1,s2,80003dfc <itrunc+0x8c>
      if(a[j])
    80003dea:	408c                	lw	a1,0(s1)
    80003dec:	dde5                	beqz	a1,80003de4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003dee:	0009a503          	lw	a0,0(s3)
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	8b4080e7          	jalr	-1868(ra) # 800036a6 <bfree>
    80003dfa:	b7ed                	j	80003de4 <itrunc+0x74>
    brelse(bp);
    80003dfc:	8552                	mv	a0,s4
    80003dfe:	fffff097          	auipc	ra,0xfffff
    80003e02:	792080e7          	jalr	1938(ra) # 80003590 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e06:	0809a583          	lw	a1,128(s3)
    80003e0a:	0009a503          	lw	a0,0(s3)
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	898080e7          	jalr	-1896(ra) # 800036a6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e16:	0809a023          	sw	zero,128(s3)
    80003e1a:	bf51                	j	80003dae <itrunc+0x3e>

0000000080003e1c <iput>:
{
    80003e1c:	1101                	addi	sp,sp,-32
    80003e1e:	ec06                	sd	ra,24(sp)
    80003e20:	e822                	sd	s0,16(sp)
    80003e22:	e426                	sd	s1,8(sp)
    80003e24:	e04a                	sd	s2,0(sp)
    80003e26:	1000                	addi	s0,sp,32
    80003e28:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e2a:	0001c517          	auipc	a0,0x1c
    80003e2e:	f9e50513          	addi	a0,a0,-98 # 8001fdc8 <itable>
    80003e32:	ffffd097          	auipc	ra,0xffffd
    80003e36:	d9e080e7          	jalr	-610(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e3a:	4498                	lw	a4,8(s1)
    80003e3c:	4785                	li	a5,1
    80003e3e:	02f70363          	beq	a4,a5,80003e64 <iput+0x48>
  ip->ref--;
    80003e42:	449c                	lw	a5,8(s1)
    80003e44:	37fd                	addiw	a5,a5,-1
    80003e46:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e48:	0001c517          	auipc	a0,0x1c
    80003e4c:	f8050513          	addi	a0,a0,-128 # 8001fdc8 <itable>
    80003e50:	ffffd097          	auipc	ra,0xffffd
    80003e54:	e34080e7          	jalr	-460(ra) # 80000c84 <release>
}
    80003e58:	60e2                	ld	ra,24(sp)
    80003e5a:	6442                	ld	s0,16(sp)
    80003e5c:	64a2                	ld	s1,8(sp)
    80003e5e:	6902                	ld	s2,0(sp)
    80003e60:	6105                	addi	sp,sp,32
    80003e62:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e64:	40bc                	lw	a5,64(s1)
    80003e66:	dff1                	beqz	a5,80003e42 <iput+0x26>
    80003e68:	04a49783          	lh	a5,74(s1)
    80003e6c:	fbf9                	bnez	a5,80003e42 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e6e:	01048913          	addi	s2,s1,16
    80003e72:	854a                	mv	a0,s2
    80003e74:	00001097          	auipc	ra,0x1
    80003e78:	abe080e7          	jalr	-1346(ra) # 80004932 <acquiresleep>
    release(&itable.lock);
    80003e7c:	0001c517          	auipc	a0,0x1c
    80003e80:	f4c50513          	addi	a0,a0,-180 # 8001fdc8 <itable>
    80003e84:	ffffd097          	auipc	ra,0xffffd
    80003e88:	e00080e7          	jalr	-512(ra) # 80000c84 <release>
    itrunc(ip);
    80003e8c:	8526                	mv	a0,s1
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	ee2080e7          	jalr	-286(ra) # 80003d70 <itrunc>
    ip->type = 0;
    80003e96:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e9a:	8526                	mv	a0,s1
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	cfa080e7          	jalr	-774(ra) # 80003b96 <iupdate>
    ip->valid = 0;
    80003ea4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ea8:	854a                	mv	a0,s2
    80003eaa:	00001097          	auipc	ra,0x1
    80003eae:	ade080e7          	jalr	-1314(ra) # 80004988 <releasesleep>
    acquire(&itable.lock);
    80003eb2:	0001c517          	auipc	a0,0x1c
    80003eb6:	f1650513          	addi	a0,a0,-234 # 8001fdc8 <itable>
    80003eba:	ffffd097          	auipc	ra,0xffffd
    80003ebe:	d16080e7          	jalr	-746(ra) # 80000bd0 <acquire>
    80003ec2:	b741                	j	80003e42 <iput+0x26>

0000000080003ec4 <iunlockput>:
{
    80003ec4:	1101                	addi	sp,sp,-32
    80003ec6:	ec06                	sd	ra,24(sp)
    80003ec8:	e822                	sd	s0,16(sp)
    80003eca:	e426                	sd	s1,8(sp)
    80003ecc:	1000                	addi	s0,sp,32
    80003ece:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	e54080e7          	jalr	-428(ra) # 80003d24 <iunlock>
  iput(ip);
    80003ed8:	8526                	mv	a0,s1
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	f42080e7          	jalr	-190(ra) # 80003e1c <iput>
}
    80003ee2:	60e2                	ld	ra,24(sp)
    80003ee4:	6442                	ld	s0,16(sp)
    80003ee6:	64a2                	ld	s1,8(sp)
    80003ee8:	6105                	addi	sp,sp,32
    80003eea:	8082                	ret

0000000080003eec <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003eec:	1141                	addi	sp,sp,-16
    80003eee:	e422                	sd	s0,8(sp)
    80003ef0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ef2:	411c                	lw	a5,0(a0)
    80003ef4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ef6:	415c                	lw	a5,4(a0)
    80003ef8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003efa:	04451783          	lh	a5,68(a0)
    80003efe:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f02:	04a51783          	lh	a5,74(a0)
    80003f06:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f0a:	04c56783          	lwu	a5,76(a0)
    80003f0e:	e99c                	sd	a5,16(a1)
}
    80003f10:	6422                	ld	s0,8(sp)
    80003f12:	0141                	addi	sp,sp,16
    80003f14:	8082                	ret

0000000080003f16 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f16:	457c                	lw	a5,76(a0)
    80003f18:	0ed7e963          	bltu	a5,a3,8000400a <readi+0xf4>
{
    80003f1c:	7159                	addi	sp,sp,-112
    80003f1e:	f486                	sd	ra,104(sp)
    80003f20:	f0a2                	sd	s0,96(sp)
    80003f22:	eca6                	sd	s1,88(sp)
    80003f24:	e8ca                	sd	s2,80(sp)
    80003f26:	e4ce                	sd	s3,72(sp)
    80003f28:	e0d2                	sd	s4,64(sp)
    80003f2a:	fc56                	sd	s5,56(sp)
    80003f2c:	f85a                	sd	s6,48(sp)
    80003f2e:	f45e                	sd	s7,40(sp)
    80003f30:	f062                	sd	s8,32(sp)
    80003f32:	ec66                	sd	s9,24(sp)
    80003f34:	e86a                	sd	s10,16(sp)
    80003f36:	e46e                	sd	s11,8(sp)
    80003f38:	1880                	addi	s0,sp,112
    80003f3a:	8baa                	mv	s7,a0
    80003f3c:	8c2e                	mv	s8,a1
    80003f3e:	8ab2                	mv	s5,a2
    80003f40:	84b6                	mv	s1,a3
    80003f42:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f44:	9f35                	addw	a4,a4,a3
    return 0;
    80003f46:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f48:	0ad76063          	bltu	a4,a3,80003fe8 <readi+0xd2>
  if(off + n > ip->size)
    80003f4c:	00e7f463          	bgeu	a5,a4,80003f54 <readi+0x3e>
    n = ip->size - off;
    80003f50:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f54:	0a0b0963          	beqz	s6,80004006 <readi+0xf0>
    80003f58:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f5a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f5e:	5cfd                	li	s9,-1
    80003f60:	a82d                	j	80003f9a <readi+0x84>
    80003f62:	020a1d93          	slli	s11,s4,0x20
    80003f66:	020ddd93          	srli	s11,s11,0x20
    80003f6a:	05890613          	addi	a2,s2,88
    80003f6e:	86ee                	mv	a3,s11
    80003f70:	963a                	add	a2,a2,a4
    80003f72:	85d6                	mv	a1,s5
    80003f74:	8562                	mv	a0,s8
    80003f76:	ffffe097          	auipc	ra,0xffffe
    80003f7a:	4bc080e7          	jalr	1212(ra) # 80002432 <either_copyout>
    80003f7e:	05950d63          	beq	a0,s9,80003fd8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f82:	854a                	mv	a0,s2
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	60c080e7          	jalr	1548(ra) # 80003590 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f8c:	013a09bb          	addw	s3,s4,s3
    80003f90:	009a04bb          	addw	s1,s4,s1
    80003f94:	9aee                	add	s5,s5,s11
    80003f96:	0569f763          	bgeu	s3,s6,80003fe4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f9a:	000ba903          	lw	s2,0(s7)
    80003f9e:	00a4d59b          	srliw	a1,s1,0xa
    80003fa2:	855e                	mv	a0,s7
    80003fa4:	00000097          	auipc	ra,0x0
    80003fa8:	8ac080e7          	jalr	-1876(ra) # 80003850 <bmap>
    80003fac:	0005059b          	sext.w	a1,a0
    80003fb0:	854a                	mv	a0,s2
    80003fb2:	fffff097          	auipc	ra,0xfffff
    80003fb6:	4ae080e7          	jalr	1198(ra) # 80003460 <bread>
    80003fba:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fbc:	3ff4f713          	andi	a4,s1,1023
    80003fc0:	40ed07bb          	subw	a5,s10,a4
    80003fc4:	413b06bb          	subw	a3,s6,s3
    80003fc8:	8a3e                	mv	s4,a5
    80003fca:	2781                	sext.w	a5,a5
    80003fcc:	0006861b          	sext.w	a2,a3
    80003fd0:	f8f679e3          	bgeu	a2,a5,80003f62 <readi+0x4c>
    80003fd4:	8a36                	mv	s4,a3
    80003fd6:	b771                	j	80003f62 <readi+0x4c>
      brelse(bp);
    80003fd8:	854a                	mv	a0,s2
    80003fda:	fffff097          	auipc	ra,0xfffff
    80003fde:	5b6080e7          	jalr	1462(ra) # 80003590 <brelse>
      tot = -1;
    80003fe2:	59fd                	li	s3,-1
  }
  return tot;
    80003fe4:	0009851b          	sext.w	a0,s3
}
    80003fe8:	70a6                	ld	ra,104(sp)
    80003fea:	7406                	ld	s0,96(sp)
    80003fec:	64e6                	ld	s1,88(sp)
    80003fee:	6946                	ld	s2,80(sp)
    80003ff0:	69a6                	ld	s3,72(sp)
    80003ff2:	6a06                	ld	s4,64(sp)
    80003ff4:	7ae2                	ld	s5,56(sp)
    80003ff6:	7b42                	ld	s6,48(sp)
    80003ff8:	7ba2                	ld	s7,40(sp)
    80003ffa:	7c02                	ld	s8,32(sp)
    80003ffc:	6ce2                	ld	s9,24(sp)
    80003ffe:	6d42                	ld	s10,16(sp)
    80004000:	6da2                	ld	s11,8(sp)
    80004002:	6165                	addi	sp,sp,112
    80004004:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004006:	89da                	mv	s3,s6
    80004008:	bff1                	j	80003fe4 <readi+0xce>
    return 0;
    8000400a:	4501                	li	a0,0
}
    8000400c:	8082                	ret

000000008000400e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000400e:	457c                	lw	a5,76(a0)
    80004010:	10d7e863          	bltu	a5,a3,80004120 <writei+0x112>
{
    80004014:	7159                	addi	sp,sp,-112
    80004016:	f486                	sd	ra,104(sp)
    80004018:	f0a2                	sd	s0,96(sp)
    8000401a:	eca6                	sd	s1,88(sp)
    8000401c:	e8ca                	sd	s2,80(sp)
    8000401e:	e4ce                	sd	s3,72(sp)
    80004020:	e0d2                	sd	s4,64(sp)
    80004022:	fc56                	sd	s5,56(sp)
    80004024:	f85a                	sd	s6,48(sp)
    80004026:	f45e                	sd	s7,40(sp)
    80004028:	f062                	sd	s8,32(sp)
    8000402a:	ec66                	sd	s9,24(sp)
    8000402c:	e86a                	sd	s10,16(sp)
    8000402e:	e46e                	sd	s11,8(sp)
    80004030:	1880                	addi	s0,sp,112
    80004032:	8b2a                	mv	s6,a0
    80004034:	8c2e                	mv	s8,a1
    80004036:	8ab2                	mv	s5,a2
    80004038:	8936                	mv	s2,a3
    8000403a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000403c:	00e687bb          	addw	a5,a3,a4
    80004040:	0ed7e263          	bltu	a5,a3,80004124 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004044:	00043737          	lui	a4,0x43
    80004048:	0ef76063          	bltu	a4,a5,80004128 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000404c:	0c0b8863          	beqz	s7,8000411c <writei+0x10e>
    80004050:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004052:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004056:	5cfd                	li	s9,-1
    80004058:	a091                	j	8000409c <writei+0x8e>
    8000405a:	02099d93          	slli	s11,s3,0x20
    8000405e:	020ddd93          	srli	s11,s11,0x20
    80004062:	05848513          	addi	a0,s1,88
    80004066:	86ee                	mv	a3,s11
    80004068:	8656                	mv	a2,s5
    8000406a:	85e2                	mv	a1,s8
    8000406c:	953a                	add	a0,a0,a4
    8000406e:	ffffe097          	auipc	ra,0xffffe
    80004072:	41a080e7          	jalr	1050(ra) # 80002488 <either_copyin>
    80004076:	07950263          	beq	a0,s9,800040da <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000407a:	8526                	mv	a0,s1
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	798080e7          	jalr	1944(ra) # 80004814 <log_write>
    brelse(bp);
    80004084:	8526                	mv	a0,s1
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	50a080e7          	jalr	1290(ra) # 80003590 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000408e:	01498a3b          	addw	s4,s3,s4
    80004092:	0129893b          	addw	s2,s3,s2
    80004096:	9aee                	add	s5,s5,s11
    80004098:	057a7663          	bgeu	s4,s7,800040e4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000409c:	000b2483          	lw	s1,0(s6)
    800040a0:	00a9559b          	srliw	a1,s2,0xa
    800040a4:	855a                	mv	a0,s6
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	7aa080e7          	jalr	1962(ra) # 80003850 <bmap>
    800040ae:	0005059b          	sext.w	a1,a0
    800040b2:	8526                	mv	a0,s1
    800040b4:	fffff097          	auipc	ra,0xfffff
    800040b8:	3ac080e7          	jalr	940(ra) # 80003460 <bread>
    800040bc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040be:	3ff97713          	andi	a4,s2,1023
    800040c2:	40ed07bb          	subw	a5,s10,a4
    800040c6:	414b86bb          	subw	a3,s7,s4
    800040ca:	89be                	mv	s3,a5
    800040cc:	2781                	sext.w	a5,a5
    800040ce:	0006861b          	sext.w	a2,a3
    800040d2:	f8f674e3          	bgeu	a2,a5,8000405a <writei+0x4c>
    800040d6:	89b6                	mv	s3,a3
    800040d8:	b749                	j	8000405a <writei+0x4c>
      brelse(bp);
    800040da:	8526                	mv	a0,s1
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	4b4080e7          	jalr	1204(ra) # 80003590 <brelse>
  }

  if(off > ip->size)
    800040e4:	04cb2783          	lw	a5,76(s6)
    800040e8:	0127f463          	bgeu	a5,s2,800040f0 <writei+0xe2>
    ip->size = off;
    800040ec:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040f0:	855a                	mv	a0,s6
    800040f2:	00000097          	auipc	ra,0x0
    800040f6:	aa4080e7          	jalr	-1372(ra) # 80003b96 <iupdate>

  return tot;
    800040fa:	000a051b          	sext.w	a0,s4
}
    800040fe:	70a6                	ld	ra,104(sp)
    80004100:	7406                	ld	s0,96(sp)
    80004102:	64e6                	ld	s1,88(sp)
    80004104:	6946                	ld	s2,80(sp)
    80004106:	69a6                	ld	s3,72(sp)
    80004108:	6a06                	ld	s4,64(sp)
    8000410a:	7ae2                	ld	s5,56(sp)
    8000410c:	7b42                	ld	s6,48(sp)
    8000410e:	7ba2                	ld	s7,40(sp)
    80004110:	7c02                	ld	s8,32(sp)
    80004112:	6ce2                	ld	s9,24(sp)
    80004114:	6d42                	ld	s10,16(sp)
    80004116:	6da2                	ld	s11,8(sp)
    80004118:	6165                	addi	sp,sp,112
    8000411a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000411c:	8a5e                	mv	s4,s7
    8000411e:	bfc9                	j	800040f0 <writei+0xe2>
    return -1;
    80004120:	557d                	li	a0,-1
}
    80004122:	8082                	ret
    return -1;
    80004124:	557d                	li	a0,-1
    80004126:	bfe1                	j	800040fe <writei+0xf0>
    return -1;
    80004128:	557d                	li	a0,-1
    8000412a:	bfd1                	j	800040fe <writei+0xf0>

000000008000412c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000412c:	1141                	addi	sp,sp,-16
    8000412e:	e406                	sd	ra,8(sp)
    80004130:	e022                	sd	s0,0(sp)
    80004132:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004134:	4639                	li	a2,14
    80004136:	ffffd097          	auipc	ra,0xffffd
    8000413a:	c66080e7          	jalr	-922(ra) # 80000d9c <strncmp>
}
    8000413e:	60a2                	ld	ra,8(sp)
    80004140:	6402                	ld	s0,0(sp)
    80004142:	0141                	addi	sp,sp,16
    80004144:	8082                	ret

0000000080004146 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004146:	7139                	addi	sp,sp,-64
    80004148:	fc06                	sd	ra,56(sp)
    8000414a:	f822                	sd	s0,48(sp)
    8000414c:	f426                	sd	s1,40(sp)
    8000414e:	f04a                	sd	s2,32(sp)
    80004150:	ec4e                	sd	s3,24(sp)
    80004152:	e852                	sd	s4,16(sp)
    80004154:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004156:	04451703          	lh	a4,68(a0)
    8000415a:	4785                	li	a5,1
    8000415c:	00f71a63          	bne	a4,a5,80004170 <dirlookup+0x2a>
    80004160:	892a                	mv	s2,a0
    80004162:	89ae                	mv	s3,a1
    80004164:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004166:	457c                	lw	a5,76(a0)
    80004168:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000416a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000416c:	e79d                	bnez	a5,8000419a <dirlookup+0x54>
    8000416e:	a8a5                	j	800041e6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004170:	00004517          	auipc	a0,0x4
    80004174:	58050513          	addi	a0,a0,1408 # 800086f0 <syscalls+0x1e8>
    80004178:	ffffc097          	auipc	ra,0xffffc
    8000417c:	3c2080e7          	jalr	962(ra) # 8000053a <panic>
      panic("dirlookup read");
    80004180:	00004517          	auipc	a0,0x4
    80004184:	58850513          	addi	a0,a0,1416 # 80008708 <syscalls+0x200>
    80004188:	ffffc097          	auipc	ra,0xffffc
    8000418c:	3b2080e7          	jalr	946(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004190:	24c1                	addiw	s1,s1,16
    80004192:	04c92783          	lw	a5,76(s2)
    80004196:	04f4f763          	bgeu	s1,a5,800041e4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000419a:	4741                	li	a4,16
    8000419c:	86a6                	mv	a3,s1
    8000419e:	fc040613          	addi	a2,s0,-64
    800041a2:	4581                	li	a1,0
    800041a4:	854a                	mv	a0,s2
    800041a6:	00000097          	auipc	ra,0x0
    800041aa:	d70080e7          	jalr	-656(ra) # 80003f16 <readi>
    800041ae:	47c1                	li	a5,16
    800041b0:	fcf518e3          	bne	a0,a5,80004180 <dirlookup+0x3a>
    if(de.inum == 0)
    800041b4:	fc045783          	lhu	a5,-64(s0)
    800041b8:	dfe1                	beqz	a5,80004190 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041ba:	fc240593          	addi	a1,s0,-62
    800041be:	854e                	mv	a0,s3
    800041c0:	00000097          	auipc	ra,0x0
    800041c4:	f6c080e7          	jalr	-148(ra) # 8000412c <namecmp>
    800041c8:	f561                	bnez	a0,80004190 <dirlookup+0x4a>
      if(poff)
    800041ca:	000a0463          	beqz	s4,800041d2 <dirlookup+0x8c>
        *poff = off;
    800041ce:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041d2:	fc045583          	lhu	a1,-64(s0)
    800041d6:	00092503          	lw	a0,0(s2)
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	752080e7          	jalr	1874(ra) # 8000392c <iget>
    800041e2:	a011                	j	800041e6 <dirlookup+0xa0>
  return 0;
    800041e4:	4501                	li	a0,0
}
    800041e6:	70e2                	ld	ra,56(sp)
    800041e8:	7442                	ld	s0,48(sp)
    800041ea:	74a2                	ld	s1,40(sp)
    800041ec:	7902                	ld	s2,32(sp)
    800041ee:	69e2                	ld	s3,24(sp)
    800041f0:	6a42                	ld	s4,16(sp)
    800041f2:	6121                	addi	sp,sp,64
    800041f4:	8082                	ret

00000000800041f6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041f6:	711d                	addi	sp,sp,-96
    800041f8:	ec86                	sd	ra,88(sp)
    800041fa:	e8a2                	sd	s0,80(sp)
    800041fc:	e4a6                	sd	s1,72(sp)
    800041fe:	e0ca                	sd	s2,64(sp)
    80004200:	fc4e                	sd	s3,56(sp)
    80004202:	f852                	sd	s4,48(sp)
    80004204:	f456                	sd	s5,40(sp)
    80004206:	f05a                	sd	s6,32(sp)
    80004208:	ec5e                	sd	s7,24(sp)
    8000420a:	e862                	sd	s8,16(sp)
    8000420c:	e466                	sd	s9,8(sp)
    8000420e:	e06a                	sd	s10,0(sp)
    80004210:	1080                	addi	s0,sp,96
    80004212:	84aa                	mv	s1,a0
    80004214:	8b2e                	mv	s6,a1
    80004216:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004218:	00054703          	lbu	a4,0(a0)
    8000421c:	02f00793          	li	a5,47
    80004220:	02f70363          	beq	a4,a5,80004246 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	772080e7          	jalr	1906(ra) # 80001996 <myproc>
    8000422c:	15053503          	ld	a0,336(a0)
    80004230:	00000097          	auipc	ra,0x0
    80004234:	9f4080e7          	jalr	-1548(ra) # 80003c24 <idup>
    80004238:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000423a:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000423e:	4cb5                	li	s9,13
  len = path - s;
    80004240:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004242:	4c05                	li	s8,1
    80004244:	a87d                	j	80004302 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004246:	4585                	li	a1,1
    80004248:	4505                	li	a0,1
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	6e2080e7          	jalr	1762(ra) # 8000392c <iget>
    80004252:	8a2a                	mv	s4,a0
    80004254:	b7dd                	j	8000423a <namex+0x44>
      iunlockput(ip);
    80004256:	8552                	mv	a0,s4
    80004258:	00000097          	auipc	ra,0x0
    8000425c:	c6c080e7          	jalr	-916(ra) # 80003ec4 <iunlockput>
      return 0;
    80004260:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004262:	8552                	mv	a0,s4
    80004264:	60e6                	ld	ra,88(sp)
    80004266:	6446                	ld	s0,80(sp)
    80004268:	64a6                	ld	s1,72(sp)
    8000426a:	6906                	ld	s2,64(sp)
    8000426c:	79e2                	ld	s3,56(sp)
    8000426e:	7a42                	ld	s4,48(sp)
    80004270:	7aa2                	ld	s5,40(sp)
    80004272:	7b02                	ld	s6,32(sp)
    80004274:	6be2                	ld	s7,24(sp)
    80004276:	6c42                	ld	s8,16(sp)
    80004278:	6ca2                	ld	s9,8(sp)
    8000427a:	6d02                	ld	s10,0(sp)
    8000427c:	6125                	addi	sp,sp,96
    8000427e:	8082                	ret
      iunlock(ip);
    80004280:	8552                	mv	a0,s4
    80004282:	00000097          	auipc	ra,0x0
    80004286:	aa2080e7          	jalr	-1374(ra) # 80003d24 <iunlock>
      return ip;
    8000428a:	bfe1                	j	80004262 <namex+0x6c>
      iunlockput(ip);
    8000428c:	8552                	mv	a0,s4
    8000428e:	00000097          	auipc	ra,0x0
    80004292:	c36080e7          	jalr	-970(ra) # 80003ec4 <iunlockput>
      return 0;
    80004296:	8a4e                	mv	s4,s3
    80004298:	b7e9                	j	80004262 <namex+0x6c>
  len = path - s;
    8000429a:	40998633          	sub	a2,s3,s1
    8000429e:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    800042a2:	09acd863          	bge	s9,s10,80004332 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    800042a6:	4639                	li	a2,14
    800042a8:	85a6                	mv	a1,s1
    800042aa:	8556                	mv	a0,s5
    800042ac:	ffffd097          	auipc	ra,0xffffd
    800042b0:	a7c080e7          	jalr	-1412(ra) # 80000d28 <memmove>
    800042b4:	84ce                	mv	s1,s3
  while(*path == '/')
    800042b6:	0004c783          	lbu	a5,0(s1)
    800042ba:	01279763          	bne	a5,s2,800042c8 <namex+0xd2>
    path++;
    800042be:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042c0:	0004c783          	lbu	a5,0(s1)
    800042c4:	ff278de3          	beq	a5,s2,800042be <namex+0xc8>
    ilock(ip);
    800042c8:	8552                	mv	a0,s4
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	998080e7          	jalr	-1640(ra) # 80003c62 <ilock>
    if(ip->type != T_DIR){
    800042d2:	044a1783          	lh	a5,68(s4)
    800042d6:	f98790e3          	bne	a5,s8,80004256 <namex+0x60>
    if(nameiparent && *path == '\0'){
    800042da:	000b0563          	beqz	s6,800042e4 <namex+0xee>
    800042de:	0004c783          	lbu	a5,0(s1)
    800042e2:	dfd9                	beqz	a5,80004280 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042e4:	865e                	mv	a2,s7
    800042e6:	85d6                	mv	a1,s5
    800042e8:	8552                	mv	a0,s4
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	e5c080e7          	jalr	-420(ra) # 80004146 <dirlookup>
    800042f2:	89aa                	mv	s3,a0
    800042f4:	dd41                	beqz	a0,8000428c <namex+0x96>
    iunlockput(ip);
    800042f6:	8552                	mv	a0,s4
    800042f8:	00000097          	auipc	ra,0x0
    800042fc:	bcc080e7          	jalr	-1076(ra) # 80003ec4 <iunlockput>
    ip = next;
    80004300:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004302:	0004c783          	lbu	a5,0(s1)
    80004306:	01279763          	bne	a5,s2,80004314 <namex+0x11e>
    path++;
    8000430a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000430c:	0004c783          	lbu	a5,0(s1)
    80004310:	ff278de3          	beq	a5,s2,8000430a <namex+0x114>
  if(*path == 0)
    80004314:	cb9d                	beqz	a5,8000434a <namex+0x154>
  while(*path != '/' && *path != 0)
    80004316:	0004c783          	lbu	a5,0(s1)
    8000431a:	89a6                	mv	s3,s1
  len = path - s;
    8000431c:	8d5e                	mv	s10,s7
    8000431e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004320:	01278963          	beq	a5,s2,80004332 <namex+0x13c>
    80004324:	dbbd                	beqz	a5,8000429a <namex+0xa4>
    path++;
    80004326:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004328:	0009c783          	lbu	a5,0(s3)
    8000432c:	ff279ce3          	bne	a5,s2,80004324 <namex+0x12e>
    80004330:	b7ad                	j	8000429a <namex+0xa4>
    memmove(name, s, len);
    80004332:	2601                	sext.w	a2,a2
    80004334:	85a6                	mv	a1,s1
    80004336:	8556                	mv	a0,s5
    80004338:	ffffd097          	auipc	ra,0xffffd
    8000433c:	9f0080e7          	jalr	-1552(ra) # 80000d28 <memmove>
    name[len] = 0;
    80004340:	9d56                	add	s10,s10,s5
    80004342:	000d0023          	sb	zero,0(s10)
    80004346:	84ce                	mv	s1,s3
    80004348:	b7bd                	j	800042b6 <namex+0xc0>
  if(nameiparent){
    8000434a:	f00b0ce3          	beqz	s6,80004262 <namex+0x6c>
    iput(ip);
    8000434e:	8552                	mv	a0,s4
    80004350:	00000097          	auipc	ra,0x0
    80004354:	acc080e7          	jalr	-1332(ra) # 80003e1c <iput>
    return 0;
    80004358:	4a01                	li	s4,0
    8000435a:	b721                	j	80004262 <namex+0x6c>

000000008000435c <dirlink>:
{
    8000435c:	7139                	addi	sp,sp,-64
    8000435e:	fc06                	sd	ra,56(sp)
    80004360:	f822                	sd	s0,48(sp)
    80004362:	f426                	sd	s1,40(sp)
    80004364:	f04a                	sd	s2,32(sp)
    80004366:	ec4e                	sd	s3,24(sp)
    80004368:	e852                	sd	s4,16(sp)
    8000436a:	0080                	addi	s0,sp,64
    8000436c:	892a                	mv	s2,a0
    8000436e:	8a2e                	mv	s4,a1
    80004370:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004372:	4601                	li	a2,0
    80004374:	00000097          	auipc	ra,0x0
    80004378:	dd2080e7          	jalr	-558(ra) # 80004146 <dirlookup>
    8000437c:	e93d                	bnez	a0,800043f2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000437e:	04c92483          	lw	s1,76(s2)
    80004382:	c49d                	beqz	s1,800043b0 <dirlink+0x54>
    80004384:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004386:	4741                	li	a4,16
    80004388:	86a6                	mv	a3,s1
    8000438a:	fc040613          	addi	a2,s0,-64
    8000438e:	4581                	li	a1,0
    80004390:	854a                	mv	a0,s2
    80004392:	00000097          	auipc	ra,0x0
    80004396:	b84080e7          	jalr	-1148(ra) # 80003f16 <readi>
    8000439a:	47c1                	li	a5,16
    8000439c:	06f51163          	bne	a0,a5,800043fe <dirlink+0xa2>
    if(de.inum == 0)
    800043a0:	fc045783          	lhu	a5,-64(s0)
    800043a4:	c791                	beqz	a5,800043b0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043a6:	24c1                	addiw	s1,s1,16
    800043a8:	04c92783          	lw	a5,76(s2)
    800043ac:	fcf4ede3          	bltu	s1,a5,80004386 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043b0:	4639                	li	a2,14
    800043b2:	85d2                	mv	a1,s4
    800043b4:	fc240513          	addi	a0,s0,-62
    800043b8:	ffffd097          	auipc	ra,0xffffd
    800043bc:	a20080e7          	jalr	-1504(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    800043c0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043c4:	4741                	li	a4,16
    800043c6:	86a6                	mv	a3,s1
    800043c8:	fc040613          	addi	a2,s0,-64
    800043cc:	4581                	li	a1,0
    800043ce:	854a                	mv	a0,s2
    800043d0:	00000097          	auipc	ra,0x0
    800043d4:	c3e080e7          	jalr	-962(ra) # 8000400e <writei>
    800043d8:	872a                	mv	a4,a0
    800043da:	47c1                	li	a5,16
  return 0;
    800043dc:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043de:	02f71863          	bne	a4,a5,8000440e <dirlink+0xb2>
}
    800043e2:	70e2                	ld	ra,56(sp)
    800043e4:	7442                	ld	s0,48(sp)
    800043e6:	74a2                	ld	s1,40(sp)
    800043e8:	7902                	ld	s2,32(sp)
    800043ea:	69e2                	ld	s3,24(sp)
    800043ec:	6a42                	ld	s4,16(sp)
    800043ee:	6121                	addi	sp,sp,64
    800043f0:	8082                	ret
    iput(ip);
    800043f2:	00000097          	auipc	ra,0x0
    800043f6:	a2a080e7          	jalr	-1494(ra) # 80003e1c <iput>
    return -1;
    800043fa:	557d                	li	a0,-1
    800043fc:	b7dd                	j	800043e2 <dirlink+0x86>
      panic("dirlink read");
    800043fe:	00004517          	auipc	a0,0x4
    80004402:	31a50513          	addi	a0,a0,794 # 80008718 <syscalls+0x210>
    80004406:	ffffc097          	auipc	ra,0xffffc
    8000440a:	134080e7          	jalr	308(ra) # 8000053a <panic>
    panic("dirlink");
    8000440e:	00004517          	auipc	a0,0x4
    80004412:	41a50513          	addi	a0,a0,1050 # 80008828 <syscalls+0x320>
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	124080e7          	jalr	292(ra) # 8000053a <panic>

000000008000441e <namei>:

struct inode*
namei(char *path)
{
    8000441e:	1101                	addi	sp,sp,-32
    80004420:	ec06                	sd	ra,24(sp)
    80004422:	e822                	sd	s0,16(sp)
    80004424:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004426:	fe040613          	addi	a2,s0,-32
    8000442a:	4581                	li	a1,0
    8000442c:	00000097          	auipc	ra,0x0
    80004430:	dca080e7          	jalr	-566(ra) # 800041f6 <namex>
}
    80004434:	60e2                	ld	ra,24(sp)
    80004436:	6442                	ld	s0,16(sp)
    80004438:	6105                	addi	sp,sp,32
    8000443a:	8082                	ret

000000008000443c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000443c:	1141                	addi	sp,sp,-16
    8000443e:	e406                	sd	ra,8(sp)
    80004440:	e022                	sd	s0,0(sp)
    80004442:	0800                	addi	s0,sp,16
    80004444:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004446:	4585                	li	a1,1
    80004448:	00000097          	auipc	ra,0x0
    8000444c:	dae080e7          	jalr	-594(ra) # 800041f6 <namex>
}
    80004450:	60a2                	ld	ra,8(sp)
    80004452:	6402                	ld	s0,0(sp)
    80004454:	0141                	addi	sp,sp,16
    80004456:	8082                	ret

0000000080004458 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004458:	1101                	addi	sp,sp,-32
    8000445a:	ec06                	sd	ra,24(sp)
    8000445c:	e822                	sd	s0,16(sp)
    8000445e:	e426                	sd	s1,8(sp)
    80004460:	e04a                	sd	s2,0(sp)
    80004462:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004464:	0001d917          	auipc	s2,0x1d
    80004468:	40c90913          	addi	s2,s2,1036 # 80021870 <log>
    8000446c:	01892583          	lw	a1,24(s2)
    80004470:	02892503          	lw	a0,40(s2)
    80004474:	fffff097          	auipc	ra,0xfffff
    80004478:	fec080e7          	jalr	-20(ra) # 80003460 <bread>
    8000447c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000447e:	02c92683          	lw	a3,44(s2)
    80004482:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004484:	02d05863          	blez	a3,800044b4 <write_head+0x5c>
    80004488:	0001d797          	auipc	a5,0x1d
    8000448c:	41878793          	addi	a5,a5,1048 # 800218a0 <log+0x30>
    80004490:	05c50713          	addi	a4,a0,92
    80004494:	36fd                	addiw	a3,a3,-1
    80004496:	02069613          	slli	a2,a3,0x20
    8000449a:	01e65693          	srli	a3,a2,0x1e
    8000449e:	0001d617          	auipc	a2,0x1d
    800044a2:	40660613          	addi	a2,a2,1030 # 800218a4 <log+0x34>
    800044a6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044a8:	4390                	lw	a2,0(a5)
    800044aa:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044ac:	0791                	addi	a5,a5,4
    800044ae:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800044b0:	fed79ce3          	bne	a5,a3,800044a8 <write_head+0x50>
  }
  bwrite(buf);
    800044b4:	8526                	mv	a0,s1
    800044b6:	fffff097          	auipc	ra,0xfffff
    800044ba:	09c080e7          	jalr	156(ra) # 80003552 <bwrite>
  brelse(buf);
    800044be:	8526                	mv	a0,s1
    800044c0:	fffff097          	auipc	ra,0xfffff
    800044c4:	0d0080e7          	jalr	208(ra) # 80003590 <brelse>
}
    800044c8:	60e2                	ld	ra,24(sp)
    800044ca:	6442                	ld	s0,16(sp)
    800044cc:	64a2                	ld	s1,8(sp)
    800044ce:	6902                	ld	s2,0(sp)
    800044d0:	6105                	addi	sp,sp,32
    800044d2:	8082                	ret

00000000800044d4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d4:	0001d797          	auipc	a5,0x1d
    800044d8:	3c87a783          	lw	a5,968(a5) # 8002189c <log+0x2c>
    800044dc:	0af05d63          	blez	a5,80004596 <install_trans+0xc2>
{
    800044e0:	7139                	addi	sp,sp,-64
    800044e2:	fc06                	sd	ra,56(sp)
    800044e4:	f822                	sd	s0,48(sp)
    800044e6:	f426                	sd	s1,40(sp)
    800044e8:	f04a                	sd	s2,32(sp)
    800044ea:	ec4e                	sd	s3,24(sp)
    800044ec:	e852                	sd	s4,16(sp)
    800044ee:	e456                	sd	s5,8(sp)
    800044f0:	e05a                	sd	s6,0(sp)
    800044f2:	0080                	addi	s0,sp,64
    800044f4:	8b2a                	mv	s6,a0
    800044f6:	0001da97          	auipc	s5,0x1d
    800044fa:	3aaa8a93          	addi	s5,s5,938 # 800218a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044fe:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004500:	0001d997          	auipc	s3,0x1d
    80004504:	37098993          	addi	s3,s3,880 # 80021870 <log>
    80004508:	a00d                	j	8000452a <install_trans+0x56>
    brelse(lbuf);
    8000450a:	854a                	mv	a0,s2
    8000450c:	fffff097          	auipc	ra,0xfffff
    80004510:	084080e7          	jalr	132(ra) # 80003590 <brelse>
    brelse(dbuf);
    80004514:	8526                	mv	a0,s1
    80004516:	fffff097          	auipc	ra,0xfffff
    8000451a:	07a080e7          	jalr	122(ra) # 80003590 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000451e:	2a05                	addiw	s4,s4,1
    80004520:	0a91                	addi	s5,s5,4
    80004522:	02c9a783          	lw	a5,44(s3)
    80004526:	04fa5e63          	bge	s4,a5,80004582 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000452a:	0189a583          	lw	a1,24(s3)
    8000452e:	014585bb          	addw	a1,a1,s4
    80004532:	2585                	addiw	a1,a1,1
    80004534:	0289a503          	lw	a0,40(s3)
    80004538:	fffff097          	auipc	ra,0xfffff
    8000453c:	f28080e7          	jalr	-216(ra) # 80003460 <bread>
    80004540:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004542:	000aa583          	lw	a1,0(s5)
    80004546:	0289a503          	lw	a0,40(s3)
    8000454a:	fffff097          	auipc	ra,0xfffff
    8000454e:	f16080e7          	jalr	-234(ra) # 80003460 <bread>
    80004552:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004554:	40000613          	li	a2,1024
    80004558:	05890593          	addi	a1,s2,88
    8000455c:	05850513          	addi	a0,a0,88
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	7c8080e7          	jalr	1992(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004568:	8526                	mv	a0,s1
    8000456a:	fffff097          	auipc	ra,0xfffff
    8000456e:	fe8080e7          	jalr	-24(ra) # 80003552 <bwrite>
    if(recovering == 0)
    80004572:	f80b1ce3          	bnez	s6,8000450a <install_trans+0x36>
      bunpin(dbuf);
    80004576:	8526                	mv	a0,s1
    80004578:	fffff097          	auipc	ra,0xfffff
    8000457c:	0f2080e7          	jalr	242(ra) # 8000366a <bunpin>
    80004580:	b769                	j	8000450a <install_trans+0x36>
}
    80004582:	70e2                	ld	ra,56(sp)
    80004584:	7442                	ld	s0,48(sp)
    80004586:	74a2                	ld	s1,40(sp)
    80004588:	7902                	ld	s2,32(sp)
    8000458a:	69e2                	ld	s3,24(sp)
    8000458c:	6a42                	ld	s4,16(sp)
    8000458e:	6aa2                	ld	s5,8(sp)
    80004590:	6b02                	ld	s6,0(sp)
    80004592:	6121                	addi	sp,sp,64
    80004594:	8082                	ret
    80004596:	8082                	ret

0000000080004598 <initlog>:
{
    80004598:	7179                	addi	sp,sp,-48
    8000459a:	f406                	sd	ra,40(sp)
    8000459c:	f022                	sd	s0,32(sp)
    8000459e:	ec26                	sd	s1,24(sp)
    800045a0:	e84a                	sd	s2,16(sp)
    800045a2:	e44e                	sd	s3,8(sp)
    800045a4:	1800                	addi	s0,sp,48
    800045a6:	892a                	mv	s2,a0
    800045a8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045aa:	0001d497          	auipc	s1,0x1d
    800045ae:	2c648493          	addi	s1,s1,710 # 80021870 <log>
    800045b2:	00004597          	auipc	a1,0x4
    800045b6:	17658593          	addi	a1,a1,374 # 80008728 <syscalls+0x220>
    800045ba:	8526                	mv	a0,s1
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	584080e7          	jalr	1412(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    800045c4:	0149a583          	lw	a1,20(s3)
    800045c8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045ca:	0109a783          	lw	a5,16(s3)
    800045ce:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045d0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045d4:	854a                	mv	a0,s2
    800045d6:	fffff097          	auipc	ra,0xfffff
    800045da:	e8a080e7          	jalr	-374(ra) # 80003460 <bread>
  log.lh.n = lh->n;
    800045de:	4d34                	lw	a3,88(a0)
    800045e0:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045e2:	02d05663          	blez	a3,8000460e <initlog+0x76>
    800045e6:	05c50793          	addi	a5,a0,92
    800045ea:	0001d717          	auipc	a4,0x1d
    800045ee:	2b670713          	addi	a4,a4,694 # 800218a0 <log+0x30>
    800045f2:	36fd                	addiw	a3,a3,-1
    800045f4:	02069613          	slli	a2,a3,0x20
    800045f8:	01e65693          	srli	a3,a2,0x1e
    800045fc:	06050613          	addi	a2,a0,96
    80004600:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004602:	4390                	lw	a2,0(a5)
    80004604:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004606:	0791                	addi	a5,a5,4
    80004608:	0711                	addi	a4,a4,4
    8000460a:	fed79ce3          	bne	a5,a3,80004602 <initlog+0x6a>
  brelse(buf);
    8000460e:	fffff097          	auipc	ra,0xfffff
    80004612:	f82080e7          	jalr	-126(ra) # 80003590 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004616:	4505                	li	a0,1
    80004618:	00000097          	auipc	ra,0x0
    8000461c:	ebc080e7          	jalr	-324(ra) # 800044d4 <install_trans>
  log.lh.n = 0;
    80004620:	0001d797          	auipc	a5,0x1d
    80004624:	2607ae23          	sw	zero,636(a5) # 8002189c <log+0x2c>
  write_head(); // clear the log
    80004628:	00000097          	auipc	ra,0x0
    8000462c:	e30080e7          	jalr	-464(ra) # 80004458 <write_head>
}
    80004630:	70a2                	ld	ra,40(sp)
    80004632:	7402                	ld	s0,32(sp)
    80004634:	64e2                	ld	s1,24(sp)
    80004636:	6942                	ld	s2,16(sp)
    80004638:	69a2                	ld	s3,8(sp)
    8000463a:	6145                	addi	sp,sp,48
    8000463c:	8082                	ret

000000008000463e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000463e:	1101                	addi	sp,sp,-32
    80004640:	ec06                	sd	ra,24(sp)
    80004642:	e822                	sd	s0,16(sp)
    80004644:	e426                	sd	s1,8(sp)
    80004646:	e04a                	sd	s2,0(sp)
    80004648:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000464a:	0001d517          	auipc	a0,0x1d
    8000464e:	22650513          	addi	a0,a0,550 # 80021870 <log>
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	57e080e7          	jalr	1406(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    8000465a:	0001d497          	auipc	s1,0x1d
    8000465e:	21648493          	addi	s1,s1,534 # 80021870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004662:	4979                	li	s2,30
    80004664:	a039                	j	80004672 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004666:	85a6                	mv	a1,s1
    80004668:	8526                	mv	a0,s1
    8000466a:	ffffe097          	auipc	ra,0xffffe
    8000466e:	a18080e7          	jalr	-1512(ra) # 80002082 <sleep>
    if(log.committing){
    80004672:	50dc                	lw	a5,36(s1)
    80004674:	fbed                	bnez	a5,80004666 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004676:	5098                	lw	a4,32(s1)
    80004678:	2705                	addiw	a4,a4,1
    8000467a:	0007069b          	sext.w	a3,a4
    8000467e:	0027179b          	slliw	a5,a4,0x2
    80004682:	9fb9                	addw	a5,a5,a4
    80004684:	0017979b          	slliw	a5,a5,0x1
    80004688:	54d8                	lw	a4,44(s1)
    8000468a:	9fb9                	addw	a5,a5,a4
    8000468c:	00f95963          	bge	s2,a5,8000469e <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004690:	85a6                	mv	a1,s1
    80004692:	8526                	mv	a0,s1
    80004694:	ffffe097          	auipc	ra,0xffffe
    80004698:	9ee080e7          	jalr	-1554(ra) # 80002082 <sleep>
    8000469c:	bfd9                	j	80004672 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000469e:	0001d517          	auipc	a0,0x1d
    800046a2:	1d250513          	addi	a0,a0,466 # 80021870 <log>
    800046a6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	5dc080e7          	jalr	1500(ra) # 80000c84 <release>
      break;
    }
  }
}
    800046b0:	60e2                	ld	ra,24(sp)
    800046b2:	6442                	ld	s0,16(sp)
    800046b4:	64a2                	ld	s1,8(sp)
    800046b6:	6902                	ld	s2,0(sp)
    800046b8:	6105                	addi	sp,sp,32
    800046ba:	8082                	ret

00000000800046bc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046bc:	7139                	addi	sp,sp,-64
    800046be:	fc06                	sd	ra,56(sp)
    800046c0:	f822                	sd	s0,48(sp)
    800046c2:	f426                	sd	s1,40(sp)
    800046c4:	f04a                	sd	s2,32(sp)
    800046c6:	ec4e                	sd	s3,24(sp)
    800046c8:	e852                	sd	s4,16(sp)
    800046ca:	e456                	sd	s5,8(sp)
    800046cc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046ce:	0001d497          	auipc	s1,0x1d
    800046d2:	1a248493          	addi	s1,s1,418 # 80021870 <log>
    800046d6:	8526                	mv	a0,s1
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	4f8080e7          	jalr	1272(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    800046e0:	509c                	lw	a5,32(s1)
    800046e2:	37fd                	addiw	a5,a5,-1
    800046e4:	0007891b          	sext.w	s2,a5
    800046e8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046ea:	50dc                	lw	a5,36(s1)
    800046ec:	e7b9                	bnez	a5,8000473a <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046ee:	04091e63          	bnez	s2,8000474a <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800046f2:	0001d497          	auipc	s1,0x1d
    800046f6:	17e48493          	addi	s1,s1,382 # 80021870 <log>
    800046fa:	4785                	li	a5,1
    800046fc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046fe:	8526                	mv	a0,s1
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	584080e7          	jalr	1412(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004708:	54dc                	lw	a5,44(s1)
    8000470a:	06f04763          	bgtz	a5,80004778 <end_op+0xbc>
    acquire(&log.lock);
    8000470e:	0001d497          	auipc	s1,0x1d
    80004712:	16248493          	addi	s1,s1,354 # 80021870 <log>
    80004716:	8526                	mv	a0,s1
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	4b8080e7          	jalr	1208(ra) # 80000bd0 <acquire>
    log.committing = 0;
    80004720:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004724:	8526                	mv	a0,s1
    80004726:	ffffe097          	auipc	ra,0xffffe
    8000472a:	ae8080e7          	jalr	-1304(ra) # 8000220e <wakeup>
    release(&log.lock);
    8000472e:	8526                	mv	a0,s1
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	554080e7          	jalr	1364(ra) # 80000c84 <release>
}
    80004738:	a03d                	j	80004766 <end_op+0xaa>
    panic("log.committing");
    8000473a:	00004517          	auipc	a0,0x4
    8000473e:	ff650513          	addi	a0,a0,-10 # 80008730 <syscalls+0x228>
    80004742:	ffffc097          	auipc	ra,0xffffc
    80004746:	df8080e7          	jalr	-520(ra) # 8000053a <panic>
    wakeup(&log);
    8000474a:	0001d497          	auipc	s1,0x1d
    8000474e:	12648493          	addi	s1,s1,294 # 80021870 <log>
    80004752:	8526                	mv	a0,s1
    80004754:	ffffe097          	auipc	ra,0xffffe
    80004758:	aba080e7          	jalr	-1350(ra) # 8000220e <wakeup>
  release(&log.lock);
    8000475c:	8526                	mv	a0,s1
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	526080e7          	jalr	1318(ra) # 80000c84 <release>
}
    80004766:	70e2                	ld	ra,56(sp)
    80004768:	7442                	ld	s0,48(sp)
    8000476a:	74a2                	ld	s1,40(sp)
    8000476c:	7902                	ld	s2,32(sp)
    8000476e:	69e2                	ld	s3,24(sp)
    80004770:	6a42                	ld	s4,16(sp)
    80004772:	6aa2                	ld	s5,8(sp)
    80004774:	6121                	addi	sp,sp,64
    80004776:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004778:	0001da97          	auipc	s5,0x1d
    8000477c:	128a8a93          	addi	s5,s5,296 # 800218a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004780:	0001da17          	auipc	s4,0x1d
    80004784:	0f0a0a13          	addi	s4,s4,240 # 80021870 <log>
    80004788:	018a2583          	lw	a1,24(s4)
    8000478c:	012585bb          	addw	a1,a1,s2
    80004790:	2585                	addiw	a1,a1,1
    80004792:	028a2503          	lw	a0,40(s4)
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	cca080e7          	jalr	-822(ra) # 80003460 <bread>
    8000479e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047a0:	000aa583          	lw	a1,0(s5)
    800047a4:	028a2503          	lw	a0,40(s4)
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	cb8080e7          	jalr	-840(ra) # 80003460 <bread>
    800047b0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047b2:	40000613          	li	a2,1024
    800047b6:	05850593          	addi	a1,a0,88
    800047ba:	05848513          	addi	a0,s1,88
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	56a080e7          	jalr	1386(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    800047c6:	8526                	mv	a0,s1
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	d8a080e7          	jalr	-630(ra) # 80003552 <bwrite>
    brelse(from);
    800047d0:	854e                	mv	a0,s3
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	dbe080e7          	jalr	-578(ra) # 80003590 <brelse>
    brelse(to);
    800047da:	8526                	mv	a0,s1
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	db4080e7          	jalr	-588(ra) # 80003590 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047e4:	2905                	addiw	s2,s2,1
    800047e6:	0a91                	addi	s5,s5,4
    800047e8:	02ca2783          	lw	a5,44(s4)
    800047ec:	f8f94ee3          	blt	s2,a5,80004788 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047f0:	00000097          	auipc	ra,0x0
    800047f4:	c68080e7          	jalr	-920(ra) # 80004458 <write_head>
    install_trans(0); // Now install writes to home locations
    800047f8:	4501                	li	a0,0
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	cda080e7          	jalr	-806(ra) # 800044d4 <install_trans>
    log.lh.n = 0;
    80004802:	0001d797          	auipc	a5,0x1d
    80004806:	0807ad23          	sw	zero,154(a5) # 8002189c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000480a:	00000097          	auipc	ra,0x0
    8000480e:	c4e080e7          	jalr	-946(ra) # 80004458 <write_head>
    80004812:	bdf5                	j	8000470e <end_op+0x52>

0000000080004814 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004814:	1101                	addi	sp,sp,-32
    80004816:	ec06                	sd	ra,24(sp)
    80004818:	e822                	sd	s0,16(sp)
    8000481a:	e426                	sd	s1,8(sp)
    8000481c:	e04a                	sd	s2,0(sp)
    8000481e:	1000                	addi	s0,sp,32
    80004820:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004822:	0001d917          	auipc	s2,0x1d
    80004826:	04e90913          	addi	s2,s2,78 # 80021870 <log>
    8000482a:	854a                	mv	a0,s2
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	3a4080e7          	jalr	932(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004834:	02c92603          	lw	a2,44(s2)
    80004838:	47f5                	li	a5,29
    8000483a:	06c7c563          	blt	a5,a2,800048a4 <log_write+0x90>
    8000483e:	0001d797          	auipc	a5,0x1d
    80004842:	04e7a783          	lw	a5,78(a5) # 8002188c <log+0x1c>
    80004846:	37fd                	addiw	a5,a5,-1
    80004848:	04f65e63          	bge	a2,a5,800048a4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000484c:	0001d797          	auipc	a5,0x1d
    80004850:	0447a783          	lw	a5,68(a5) # 80021890 <log+0x20>
    80004854:	06f05063          	blez	a5,800048b4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004858:	4781                	li	a5,0
    8000485a:	06c05563          	blez	a2,800048c4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000485e:	44cc                	lw	a1,12(s1)
    80004860:	0001d717          	auipc	a4,0x1d
    80004864:	04070713          	addi	a4,a4,64 # 800218a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004868:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000486a:	4314                	lw	a3,0(a4)
    8000486c:	04b68c63          	beq	a3,a1,800048c4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004870:	2785                	addiw	a5,a5,1
    80004872:	0711                	addi	a4,a4,4
    80004874:	fef61be3          	bne	a2,a5,8000486a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004878:	0621                	addi	a2,a2,8
    8000487a:	060a                	slli	a2,a2,0x2
    8000487c:	0001d797          	auipc	a5,0x1d
    80004880:	ff478793          	addi	a5,a5,-12 # 80021870 <log>
    80004884:	97b2                	add	a5,a5,a2
    80004886:	44d8                	lw	a4,12(s1)
    80004888:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000488a:	8526                	mv	a0,s1
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	da2080e7          	jalr	-606(ra) # 8000362e <bpin>
    log.lh.n++;
    80004894:	0001d717          	auipc	a4,0x1d
    80004898:	fdc70713          	addi	a4,a4,-36 # 80021870 <log>
    8000489c:	575c                	lw	a5,44(a4)
    8000489e:	2785                	addiw	a5,a5,1
    800048a0:	d75c                	sw	a5,44(a4)
    800048a2:	a82d                	j	800048dc <log_write+0xc8>
    panic("too big a transaction");
    800048a4:	00004517          	auipc	a0,0x4
    800048a8:	e9c50513          	addi	a0,a0,-356 # 80008740 <syscalls+0x238>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	c8e080e7          	jalr	-882(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    800048b4:	00004517          	auipc	a0,0x4
    800048b8:	ea450513          	addi	a0,a0,-348 # 80008758 <syscalls+0x250>
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	c7e080e7          	jalr	-898(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    800048c4:	00878693          	addi	a3,a5,8
    800048c8:	068a                	slli	a3,a3,0x2
    800048ca:	0001d717          	auipc	a4,0x1d
    800048ce:	fa670713          	addi	a4,a4,-90 # 80021870 <log>
    800048d2:	9736                	add	a4,a4,a3
    800048d4:	44d4                	lw	a3,12(s1)
    800048d6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048d8:	faf609e3          	beq	a2,a5,8000488a <log_write+0x76>
  }
  release(&log.lock);
    800048dc:	0001d517          	auipc	a0,0x1d
    800048e0:	f9450513          	addi	a0,a0,-108 # 80021870 <log>
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	3a0080e7          	jalr	928(ra) # 80000c84 <release>
}
    800048ec:	60e2                	ld	ra,24(sp)
    800048ee:	6442                	ld	s0,16(sp)
    800048f0:	64a2                	ld	s1,8(sp)
    800048f2:	6902                	ld	s2,0(sp)
    800048f4:	6105                	addi	sp,sp,32
    800048f6:	8082                	ret

00000000800048f8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048f8:	1101                	addi	sp,sp,-32
    800048fa:	ec06                	sd	ra,24(sp)
    800048fc:	e822                	sd	s0,16(sp)
    800048fe:	e426                	sd	s1,8(sp)
    80004900:	e04a                	sd	s2,0(sp)
    80004902:	1000                	addi	s0,sp,32
    80004904:	84aa                	mv	s1,a0
    80004906:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004908:	00004597          	auipc	a1,0x4
    8000490c:	e7058593          	addi	a1,a1,-400 # 80008778 <syscalls+0x270>
    80004910:	0521                	addi	a0,a0,8
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	22e080e7          	jalr	558(ra) # 80000b40 <initlock>
  lk->name = name;
    8000491a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000491e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004922:	0204a423          	sw	zero,40(s1)
}
    80004926:	60e2                	ld	ra,24(sp)
    80004928:	6442                	ld	s0,16(sp)
    8000492a:	64a2                	ld	s1,8(sp)
    8000492c:	6902                	ld	s2,0(sp)
    8000492e:	6105                	addi	sp,sp,32
    80004930:	8082                	ret

0000000080004932 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004932:	1101                	addi	sp,sp,-32
    80004934:	ec06                	sd	ra,24(sp)
    80004936:	e822                	sd	s0,16(sp)
    80004938:	e426                	sd	s1,8(sp)
    8000493a:	e04a                	sd	s2,0(sp)
    8000493c:	1000                	addi	s0,sp,32
    8000493e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004940:	00850913          	addi	s2,a0,8
    80004944:	854a                	mv	a0,s2
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	28a080e7          	jalr	650(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    8000494e:	409c                	lw	a5,0(s1)
    80004950:	cb89                	beqz	a5,80004962 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004952:	85ca                	mv	a1,s2
    80004954:	8526                	mv	a0,s1
    80004956:	ffffd097          	auipc	ra,0xffffd
    8000495a:	72c080e7          	jalr	1836(ra) # 80002082 <sleep>
  while (lk->locked) {
    8000495e:	409c                	lw	a5,0(s1)
    80004960:	fbed                	bnez	a5,80004952 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004962:	4785                	li	a5,1
    80004964:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004966:	ffffd097          	auipc	ra,0xffffd
    8000496a:	030080e7          	jalr	48(ra) # 80001996 <myproc>
    8000496e:	591c                	lw	a5,48(a0)
    80004970:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004972:	854a                	mv	a0,s2
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	310080e7          	jalr	784(ra) # 80000c84 <release>
}
    8000497c:	60e2                	ld	ra,24(sp)
    8000497e:	6442                	ld	s0,16(sp)
    80004980:	64a2                	ld	s1,8(sp)
    80004982:	6902                	ld	s2,0(sp)
    80004984:	6105                	addi	sp,sp,32
    80004986:	8082                	ret

0000000080004988 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004988:	1101                	addi	sp,sp,-32
    8000498a:	ec06                	sd	ra,24(sp)
    8000498c:	e822                	sd	s0,16(sp)
    8000498e:	e426                	sd	s1,8(sp)
    80004990:	e04a                	sd	s2,0(sp)
    80004992:	1000                	addi	s0,sp,32
    80004994:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004996:	00850913          	addi	s2,a0,8
    8000499a:	854a                	mv	a0,s2
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	234080e7          	jalr	564(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    800049a4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049a8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049ac:	8526                	mv	a0,s1
    800049ae:	ffffe097          	auipc	ra,0xffffe
    800049b2:	860080e7          	jalr	-1952(ra) # 8000220e <wakeup>
  release(&lk->lk);
    800049b6:	854a                	mv	a0,s2
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	2cc080e7          	jalr	716(ra) # 80000c84 <release>
}
    800049c0:	60e2                	ld	ra,24(sp)
    800049c2:	6442                	ld	s0,16(sp)
    800049c4:	64a2                	ld	s1,8(sp)
    800049c6:	6902                	ld	s2,0(sp)
    800049c8:	6105                	addi	sp,sp,32
    800049ca:	8082                	ret

00000000800049cc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049cc:	7179                	addi	sp,sp,-48
    800049ce:	f406                	sd	ra,40(sp)
    800049d0:	f022                	sd	s0,32(sp)
    800049d2:	ec26                	sd	s1,24(sp)
    800049d4:	e84a                	sd	s2,16(sp)
    800049d6:	e44e                	sd	s3,8(sp)
    800049d8:	1800                	addi	s0,sp,48
    800049da:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049dc:	00850913          	addi	s2,a0,8
    800049e0:	854a                	mv	a0,s2
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	1ee080e7          	jalr	494(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049ea:	409c                	lw	a5,0(s1)
    800049ec:	ef99                	bnez	a5,80004a0a <holdingsleep+0x3e>
    800049ee:	4481                	li	s1,0
  release(&lk->lk);
    800049f0:	854a                	mv	a0,s2
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	292080e7          	jalr	658(ra) # 80000c84 <release>
  return r;
}
    800049fa:	8526                	mv	a0,s1
    800049fc:	70a2                	ld	ra,40(sp)
    800049fe:	7402                	ld	s0,32(sp)
    80004a00:	64e2                	ld	s1,24(sp)
    80004a02:	6942                	ld	s2,16(sp)
    80004a04:	69a2                	ld	s3,8(sp)
    80004a06:	6145                	addi	sp,sp,48
    80004a08:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a0a:	0284a983          	lw	s3,40(s1)
    80004a0e:	ffffd097          	auipc	ra,0xffffd
    80004a12:	f88080e7          	jalr	-120(ra) # 80001996 <myproc>
    80004a16:	5904                	lw	s1,48(a0)
    80004a18:	413484b3          	sub	s1,s1,s3
    80004a1c:	0014b493          	seqz	s1,s1
    80004a20:	bfc1                	j	800049f0 <holdingsleep+0x24>

0000000080004a22 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a22:	1141                	addi	sp,sp,-16
    80004a24:	e406                	sd	ra,8(sp)
    80004a26:	e022                	sd	s0,0(sp)
    80004a28:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a2a:	00004597          	auipc	a1,0x4
    80004a2e:	d5e58593          	addi	a1,a1,-674 # 80008788 <syscalls+0x280>
    80004a32:	0001d517          	auipc	a0,0x1d
    80004a36:	f8650513          	addi	a0,a0,-122 # 800219b8 <ftable>
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	106080e7          	jalr	262(ra) # 80000b40 <initlock>
}
    80004a42:	60a2                	ld	ra,8(sp)
    80004a44:	6402                	ld	s0,0(sp)
    80004a46:	0141                	addi	sp,sp,16
    80004a48:	8082                	ret

0000000080004a4a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a4a:	1101                	addi	sp,sp,-32
    80004a4c:	ec06                	sd	ra,24(sp)
    80004a4e:	e822                	sd	s0,16(sp)
    80004a50:	e426                	sd	s1,8(sp)
    80004a52:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a54:	0001d517          	auipc	a0,0x1d
    80004a58:	f6450513          	addi	a0,a0,-156 # 800219b8 <ftable>
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	174080e7          	jalr	372(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a64:	0001d497          	auipc	s1,0x1d
    80004a68:	f6c48493          	addi	s1,s1,-148 # 800219d0 <ftable+0x18>
    80004a6c:	0001e717          	auipc	a4,0x1e
    80004a70:	f0470713          	addi	a4,a4,-252 # 80022970 <ftable+0xfb8>
    if(f->ref == 0){
    80004a74:	40dc                	lw	a5,4(s1)
    80004a76:	cf99                	beqz	a5,80004a94 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a78:	02848493          	addi	s1,s1,40
    80004a7c:	fee49ce3          	bne	s1,a4,80004a74 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a80:	0001d517          	auipc	a0,0x1d
    80004a84:	f3850513          	addi	a0,a0,-200 # 800219b8 <ftable>
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	1fc080e7          	jalr	508(ra) # 80000c84 <release>
  return 0;
    80004a90:	4481                	li	s1,0
    80004a92:	a819                	j	80004aa8 <filealloc+0x5e>
      f->ref = 1;
    80004a94:	4785                	li	a5,1
    80004a96:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a98:	0001d517          	auipc	a0,0x1d
    80004a9c:	f2050513          	addi	a0,a0,-224 # 800219b8 <ftable>
    80004aa0:	ffffc097          	auipc	ra,0xffffc
    80004aa4:	1e4080e7          	jalr	484(ra) # 80000c84 <release>
}
    80004aa8:	8526                	mv	a0,s1
    80004aaa:	60e2                	ld	ra,24(sp)
    80004aac:	6442                	ld	s0,16(sp)
    80004aae:	64a2                	ld	s1,8(sp)
    80004ab0:	6105                	addi	sp,sp,32
    80004ab2:	8082                	ret

0000000080004ab4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ab4:	1101                	addi	sp,sp,-32
    80004ab6:	ec06                	sd	ra,24(sp)
    80004ab8:	e822                	sd	s0,16(sp)
    80004aba:	e426                	sd	s1,8(sp)
    80004abc:	1000                	addi	s0,sp,32
    80004abe:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ac0:	0001d517          	auipc	a0,0x1d
    80004ac4:	ef850513          	addi	a0,a0,-264 # 800219b8 <ftable>
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	108080e7          	jalr	264(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004ad0:	40dc                	lw	a5,4(s1)
    80004ad2:	02f05263          	blez	a5,80004af6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004ad6:	2785                	addiw	a5,a5,1
    80004ad8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ada:	0001d517          	auipc	a0,0x1d
    80004ade:	ede50513          	addi	a0,a0,-290 # 800219b8 <ftable>
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	1a2080e7          	jalr	418(ra) # 80000c84 <release>
  return f;
}
    80004aea:	8526                	mv	a0,s1
    80004aec:	60e2                	ld	ra,24(sp)
    80004aee:	6442                	ld	s0,16(sp)
    80004af0:	64a2                	ld	s1,8(sp)
    80004af2:	6105                	addi	sp,sp,32
    80004af4:	8082                	ret
    panic("filedup");
    80004af6:	00004517          	auipc	a0,0x4
    80004afa:	c9a50513          	addi	a0,a0,-870 # 80008790 <syscalls+0x288>
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	a3c080e7          	jalr	-1476(ra) # 8000053a <panic>

0000000080004b06 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b06:	7139                	addi	sp,sp,-64
    80004b08:	fc06                	sd	ra,56(sp)
    80004b0a:	f822                	sd	s0,48(sp)
    80004b0c:	f426                	sd	s1,40(sp)
    80004b0e:	f04a                	sd	s2,32(sp)
    80004b10:	ec4e                	sd	s3,24(sp)
    80004b12:	e852                	sd	s4,16(sp)
    80004b14:	e456                	sd	s5,8(sp)
    80004b16:	0080                	addi	s0,sp,64
    80004b18:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b1a:	0001d517          	auipc	a0,0x1d
    80004b1e:	e9e50513          	addi	a0,a0,-354 # 800219b8 <ftable>
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	0ae080e7          	jalr	174(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004b2a:	40dc                	lw	a5,4(s1)
    80004b2c:	06f05163          	blez	a5,80004b8e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b30:	37fd                	addiw	a5,a5,-1
    80004b32:	0007871b          	sext.w	a4,a5
    80004b36:	c0dc                	sw	a5,4(s1)
    80004b38:	06e04363          	bgtz	a4,80004b9e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b3c:	0004a903          	lw	s2,0(s1)
    80004b40:	0094ca83          	lbu	s5,9(s1)
    80004b44:	0104ba03          	ld	s4,16(s1)
    80004b48:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b4c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b50:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b54:	0001d517          	auipc	a0,0x1d
    80004b58:	e6450513          	addi	a0,a0,-412 # 800219b8 <ftable>
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	128080e7          	jalr	296(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    80004b64:	4785                	li	a5,1
    80004b66:	04f90d63          	beq	s2,a5,80004bc0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b6a:	3979                	addiw	s2,s2,-2
    80004b6c:	4785                	li	a5,1
    80004b6e:	0527e063          	bltu	a5,s2,80004bae <fileclose+0xa8>
    begin_op();
    80004b72:	00000097          	auipc	ra,0x0
    80004b76:	acc080e7          	jalr	-1332(ra) # 8000463e <begin_op>
    iput(ff.ip);
    80004b7a:	854e                	mv	a0,s3
    80004b7c:	fffff097          	auipc	ra,0xfffff
    80004b80:	2a0080e7          	jalr	672(ra) # 80003e1c <iput>
    end_op();
    80004b84:	00000097          	auipc	ra,0x0
    80004b88:	b38080e7          	jalr	-1224(ra) # 800046bc <end_op>
    80004b8c:	a00d                	j	80004bae <fileclose+0xa8>
    panic("fileclose");
    80004b8e:	00004517          	auipc	a0,0x4
    80004b92:	c0a50513          	addi	a0,a0,-1014 # 80008798 <syscalls+0x290>
    80004b96:	ffffc097          	auipc	ra,0xffffc
    80004b9a:	9a4080e7          	jalr	-1628(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004b9e:	0001d517          	auipc	a0,0x1d
    80004ba2:	e1a50513          	addi	a0,a0,-486 # 800219b8 <ftable>
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	0de080e7          	jalr	222(ra) # 80000c84 <release>
  }
}
    80004bae:	70e2                	ld	ra,56(sp)
    80004bb0:	7442                	ld	s0,48(sp)
    80004bb2:	74a2                	ld	s1,40(sp)
    80004bb4:	7902                	ld	s2,32(sp)
    80004bb6:	69e2                	ld	s3,24(sp)
    80004bb8:	6a42                	ld	s4,16(sp)
    80004bba:	6aa2                	ld	s5,8(sp)
    80004bbc:	6121                	addi	sp,sp,64
    80004bbe:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004bc0:	85d6                	mv	a1,s5
    80004bc2:	8552                	mv	a0,s4
    80004bc4:	00000097          	auipc	ra,0x0
    80004bc8:	34c080e7          	jalr	844(ra) # 80004f10 <pipeclose>
    80004bcc:	b7cd                	j	80004bae <fileclose+0xa8>

0000000080004bce <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bce:	715d                	addi	sp,sp,-80
    80004bd0:	e486                	sd	ra,72(sp)
    80004bd2:	e0a2                	sd	s0,64(sp)
    80004bd4:	fc26                	sd	s1,56(sp)
    80004bd6:	f84a                	sd	s2,48(sp)
    80004bd8:	f44e                	sd	s3,40(sp)
    80004bda:	0880                	addi	s0,sp,80
    80004bdc:	84aa                	mv	s1,a0
    80004bde:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004be0:	ffffd097          	auipc	ra,0xffffd
    80004be4:	db6080e7          	jalr	-586(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004be8:	409c                	lw	a5,0(s1)
    80004bea:	37f9                	addiw	a5,a5,-2
    80004bec:	4705                	li	a4,1
    80004bee:	04f76763          	bltu	a4,a5,80004c3c <filestat+0x6e>
    80004bf2:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bf4:	6c88                	ld	a0,24(s1)
    80004bf6:	fffff097          	auipc	ra,0xfffff
    80004bfa:	06c080e7          	jalr	108(ra) # 80003c62 <ilock>
    stati(f->ip, &st);
    80004bfe:	fb840593          	addi	a1,s0,-72
    80004c02:	6c88                	ld	a0,24(s1)
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	2e8080e7          	jalr	744(ra) # 80003eec <stati>
    iunlock(f->ip);
    80004c0c:	6c88                	ld	a0,24(s1)
    80004c0e:	fffff097          	auipc	ra,0xfffff
    80004c12:	116080e7          	jalr	278(ra) # 80003d24 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c16:	46e1                	li	a3,24
    80004c18:	fb840613          	addi	a2,s0,-72
    80004c1c:	85ce                	mv	a1,s3
    80004c1e:	05093503          	ld	a0,80(s2)
    80004c22:	ffffd097          	auipc	ra,0xffffd
    80004c26:	a38080e7          	jalr	-1480(ra) # 8000165a <copyout>
    80004c2a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c2e:	60a6                	ld	ra,72(sp)
    80004c30:	6406                	ld	s0,64(sp)
    80004c32:	74e2                	ld	s1,56(sp)
    80004c34:	7942                	ld	s2,48(sp)
    80004c36:	79a2                	ld	s3,40(sp)
    80004c38:	6161                	addi	sp,sp,80
    80004c3a:	8082                	ret
  return -1;
    80004c3c:	557d                	li	a0,-1
    80004c3e:	bfc5                	j	80004c2e <filestat+0x60>

0000000080004c40 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c40:	7179                	addi	sp,sp,-48
    80004c42:	f406                	sd	ra,40(sp)
    80004c44:	f022                	sd	s0,32(sp)
    80004c46:	ec26                	sd	s1,24(sp)
    80004c48:	e84a                	sd	s2,16(sp)
    80004c4a:	e44e                	sd	s3,8(sp)
    80004c4c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c4e:	00854783          	lbu	a5,8(a0)
    80004c52:	c3d5                	beqz	a5,80004cf6 <fileread+0xb6>
    80004c54:	84aa                	mv	s1,a0
    80004c56:	89ae                	mv	s3,a1
    80004c58:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c5a:	411c                	lw	a5,0(a0)
    80004c5c:	4705                	li	a4,1
    80004c5e:	04e78963          	beq	a5,a4,80004cb0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c62:	470d                	li	a4,3
    80004c64:	04e78d63          	beq	a5,a4,80004cbe <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c68:	4709                	li	a4,2
    80004c6a:	06e79e63          	bne	a5,a4,80004ce6 <fileread+0xa6>
    ilock(f->ip);
    80004c6e:	6d08                	ld	a0,24(a0)
    80004c70:	fffff097          	auipc	ra,0xfffff
    80004c74:	ff2080e7          	jalr	-14(ra) # 80003c62 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c78:	874a                	mv	a4,s2
    80004c7a:	5094                	lw	a3,32(s1)
    80004c7c:	864e                	mv	a2,s3
    80004c7e:	4585                	li	a1,1
    80004c80:	6c88                	ld	a0,24(s1)
    80004c82:	fffff097          	auipc	ra,0xfffff
    80004c86:	294080e7          	jalr	660(ra) # 80003f16 <readi>
    80004c8a:	892a                	mv	s2,a0
    80004c8c:	00a05563          	blez	a0,80004c96 <fileread+0x56>
      f->off += r;
    80004c90:	509c                	lw	a5,32(s1)
    80004c92:	9fa9                	addw	a5,a5,a0
    80004c94:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c96:	6c88                	ld	a0,24(s1)
    80004c98:	fffff097          	auipc	ra,0xfffff
    80004c9c:	08c080e7          	jalr	140(ra) # 80003d24 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ca0:	854a                	mv	a0,s2
    80004ca2:	70a2                	ld	ra,40(sp)
    80004ca4:	7402                	ld	s0,32(sp)
    80004ca6:	64e2                	ld	s1,24(sp)
    80004ca8:	6942                	ld	s2,16(sp)
    80004caa:	69a2                	ld	s3,8(sp)
    80004cac:	6145                	addi	sp,sp,48
    80004cae:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004cb0:	6908                	ld	a0,16(a0)
    80004cb2:	00000097          	auipc	ra,0x0
    80004cb6:	3c0080e7          	jalr	960(ra) # 80005072 <piperead>
    80004cba:	892a                	mv	s2,a0
    80004cbc:	b7d5                	j	80004ca0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004cbe:	02451783          	lh	a5,36(a0)
    80004cc2:	03079693          	slli	a3,a5,0x30
    80004cc6:	92c1                	srli	a3,a3,0x30
    80004cc8:	4725                	li	a4,9
    80004cca:	02d76863          	bltu	a4,a3,80004cfa <fileread+0xba>
    80004cce:	0792                	slli	a5,a5,0x4
    80004cd0:	0001d717          	auipc	a4,0x1d
    80004cd4:	c4870713          	addi	a4,a4,-952 # 80021918 <devsw>
    80004cd8:	97ba                	add	a5,a5,a4
    80004cda:	639c                	ld	a5,0(a5)
    80004cdc:	c38d                	beqz	a5,80004cfe <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004cde:	4505                	li	a0,1
    80004ce0:	9782                	jalr	a5
    80004ce2:	892a                	mv	s2,a0
    80004ce4:	bf75                	j	80004ca0 <fileread+0x60>
    panic("fileread");
    80004ce6:	00004517          	auipc	a0,0x4
    80004cea:	ac250513          	addi	a0,a0,-1342 # 800087a8 <syscalls+0x2a0>
    80004cee:	ffffc097          	auipc	ra,0xffffc
    80004cf2:	84c080e7          	jalr	-1972(ra) # 8000053a <panic>
    return -1;
    80004cf6:	597d                	li	s2,-1
    80004cf8:	b765                	j	80004ca0 <fileread+0x60>
      return -1;
    80004cfa:	597d                	li	s2,-1
    80004cfc:	b755                	j	80004ca0 <fileread+0x60>
    80004cfe:	597d                	li	s2,-1
    80004d00:	b745                	j	80004ca0 <fileread+0x60>

0000000080004d02 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d02:	715d                	addi	sp,sp,-80
    80004d04:	e486                	sd	ra,72(sp)
    80004d06:	e0a2                	sd	s0,64(sp)
    80004d08:	fc26                	sd	s1,56(sp)
    80004d0a:	f84a                	sd	s2,48(sp)
    80004d0c:	f44e                	sd	s3,40(sp)
    80004d0e:	f052                	sd	s4,32(sp)
    80004d10:	ec56                	sd	s5,24(sp)
    80004d12:	e85a                	sd	s6,16(sp)
    80004d14:	e45e                	sd	s7,8(sp)
    80004d16:	e062                	sd	s8,0(sp)
    80004d18:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d1a:	00954783          	lbu	a5,9(a0)
    80004d1e:	10078663          	beqz	a5,80004e2a <filewrite+0x128>
    80004d22:	892a                	mv	s2,a0
    80004d24:	8b2e                	mv	s6,a1
    80004d26:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d28:	411c                	lw	a5,0(a0)
    80004d2a:	4705                	li	a4,1
    80004d2c:	02e78263          	beq	a5,a4,80004d50 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d30:	470d                	li	a4,3
    80004d32:	02e78663          	beq	a5,a4,80004d5e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d36:	4709                	li	a4,2
    80004d38:	0ee79163          	bne	a5,a4,80004e1a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d3c:	0ac05d63          	blez	a2,80004df6 <filewrite+0xf4>
    int i = 0;
    80004d40:	4981                	li	s3,0
    80004d42:	6b85                	lui	s7,0x1
    80004d44:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004d48:	6c05                	lui	s8,0x1
    80004d4a:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004d4e:	a861                	j	80004de6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d50:	6908                	ld	a0,16(a0)
    80004d52:	00000097          	auipc	ra,0x0
    80004d56:	22e080e7          	jalr	558(ra) # 80004f80 <pipewrite>
    80004d5a:	8a2a                	mv	s4,a0
    80004d5c:	a045                	j	80004dfc <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d5e:	02451783          	lh	a5,36(a0)
    80004d62:	03079693          	slli	a3,a5,0x30
    80004d66:	92c1                	srli	a3,a3,0x30
    80004d68:	4725                	li	a4,9
    80004d6a:	0cd76263          	bltu	a4,a3,80004e2e <filewrite+0x12c>
    80004d6e:	0792                	slli	a5,a5,0x4
    80004d70:	0001d717          	auipc	a4,0x1d
    80004d74:	ba870713          	addi	a4,a4,-1112 # 80021918 <devsw>
    80004d78:	97ba                	add	a5,a5,a4
    80004d7a:	679c                	ld	a5,8(a5)
    80004d7c:	cbdd                	beqz	a5,80004e32 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d7e:	4505                	li	a0,1
    80004d80:	9782                	jalr	a5
    80004d82:	8a2a                	mv	s4,a0
    80004d84:	a8a5                	j	80004dfc <filewrite+0xfa>
    80004d86:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d8a:	00000097          	auipc	ra,0x0
    80004d8e:	8b4080e7          	jalr	-1868(ra) # 8000463e <begin_op>
      ilock(f->ip);
    80004d92:	01893503          	ld	a0,24(s2)
    80004d96:	fffff097          	auipc	ra,0xfffff
    80004d9a:	ecc080e7          	jalr	-308(ra) # 80003c62 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d9e:	8756                	mv	a4,s5
    80004da0:	02092683          	lw	a3,32(s2)
    80004da4:	01698633          	add	a2,s3,s6
    80004da8:	4585                	li	a1,1
    80004daa:	01893503          	ld	a0,24(s2)
    80004dae:	fffff097          	auipc	ra,0xfffff
    80004db2:	260080e7          	jalr	608(ra) # 8000400e <writei>
    80004db6:	84aa                	mv	s1,a0
    80004db8:	00a05763          	blez	a0,80004dc6 <filewrite+0xc4>
        f->off += r;
    80004dbc:	02092783          	lw	a5,32(s2)
    80004dc0:	9fa9                	addw	a5,a5,a0
    80004dc2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004dc6:	01893503          	ld	a0,24(s2)
    80004dca:	fffff097          	auipc	ra,0xfffff
    80004dce:	f5a080e7          	jalr	-166(ra) # 80003d24 <iunlock>
      end_op();
    80004dd2:	00000097          	auipc	ra,0x0
    80004dd6:	8ea080e7          	jalr	-1814(ra) # 800046bc <end_op>

      if(r != n1){
    80004dda:	009a9f63          	bne	s5,s1,80004df8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004dde:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004de2:	0149db63          	bge	s3,s4,80004df8 <filewrite+0xf6>
      int n1 = n - i;
    80004de6:	413a04bb          	subw	s1,s4,s3
    80004dea:	0004879b          	sext.w	a5,s1
    80004dee:	f8fbdce3          	bge	s7,a5,80004d86 <filewrite+0x84>
    80004df2:	84e2                	mv	s1,s8
    80004df4:	bf49                	j	80004d86 <filewrite+0x84>
    int i = 0;
    80004df6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004df8:	013a1f63          	bne	s4,s3,80004e16 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004dfc:	8552                	mv	a0,s4
    80004dfe:	60a6                	ld	ra,72(sp)
    80004e00:	6406                	ld	s0,64(sp)
    80004e02:	74e2                	ld	s1,56(sp)
    80004e04:	7942                	ld	s2,48(sp)
    80004e06:	79a2                	ld	s3,40(sp)
    80004e08:	7a02                	ld	s4,32(sp)
    80004e0a:	6ae2                	ld	s5,24(sp)
    80004e0c:	6b42                	ld	s6,16(sp)
    80004e0e:	6ba2                	ld	s7,8(sp)
    80004e10:	6c02                	ld	s8,0(sp)
    80004e12:	6161                	addi	sp,sp,80
    80004e14:	8082                	ret
    ret = (i == n ? n : -1);
    80004e16:	5a7d                	li	s4,-1
    80004e18:	b7d5                	j	80004dfc <filewrite+0xfa>
    panic("filewrite");
    80004e1a:	00004517          	auipc	a0,0x4
    80004e1e:	99e50513          	addi	a0,a0,-1634 # 800087b8 <syscalls+0x2b0>
    80004e22:	ffffb097          	auipc	ra,0xffffb
    80004e26:	718080e7          	jalr	1816(ra) # 8000053a <panic>
    return -1;
    80004e2a:	5a7d                	li	s4,-1
    80004e2c:	bfc1                	j	80004dfc <filewrite+0xfa>
      return -1;
    80004e2e:	5a7d                	li	s4,-1
    80004e30:	b7f1                	j	80004dfc <filewrite+0xfa>
    80004e32:	5a7d                	li	s4,-1
    80004e34:	b7e1                	j	80004dfc <filewrite+0xfa>

0000000080004e36 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e36:	7179                	addi	sp,sp,-48
    80004e38:	f406                	sd	ra,40(sp)
    80004e3a:	f022                	sd	s0,32(sp)
    80004e3c:	ec26                	sd	s1,24(sp)
    80004e3e:	e84a                	sd	s2,16(sp)
    80004e40:	e44e                	sd	s3,8(sp)
    80004e42:	e052                	sd	s4,0(sp)
    80004e44:	1800                	addi	s0,sp,48
    80004e46:	84aa                	mv	s1,a0
    80004e48:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e4a:	0005b023          	sd	zero,0(a1)
    80004e4e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e52:	00000097          	auipc	ra,0x0
    80004e56:	bf8080e7          	jalr	-1032(ra) # 80004a4a <filealloc>
    80004e5a:	e088                	sd	a0,0(s1)
    80004e5c:	c551                	beqz	a0,80004ee8 <pipealloc+0xb2>
    80004e5e:	00000097          	auipc	ra,0x0
    80004e62:	bec080e7          	jalr	-1044(ra) # 80004a4a <filealloc>
    80004e66:	00aa3023          	sd	a0,0(s4)
    80004e6a:	c92d                	beqz	a0,80004edc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	c74080e7          	jalr	-908(ra) # 80000ae0 <kalloc>
    80004e74:	892a                	mv	s2,a0
    80004e76:	c125                	beqz	a0,80004ed6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e78:	4985                	li	s3,1
    80004e7a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e7e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e82:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e86:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e8a:	00004597          	auipc	a1,0x4
    80004e8e:	93e58593          	addi	a1,a1,-1730 # 800087c8 <syscalls+0x2c0>
    80004e92:	ffffc097          	auipc	ra,0xffffc
    80004e96:	cae080e7          	jalr	-850(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004e9a:	609c                	ld	a5,0(s1)
    80004e9c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ea0:	609c                	ld	a5,0(s1)
    80004ea2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ea6:	609c                	ld	a5,0(s1)
    80004ea8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004eac:	609c                	ld	a5,0(s1)
    80004eae:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004eb2:	000a3783          	ld	a5,0(s4)
    80004eb6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004eba:	000a3783          	ld	a5,0(s4)
    80004ebe:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ec2:	000a3783          	ld	a5,0(s4)
    80004ec6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004eca:	000a3783          	ld	a5,0(s4)
    80004ece:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ed2:	4501                	li	a0,0
    80004ed4:	a025                	j	80004efc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ed6:	6088                	ld	a0,0(s1)
    80004ed8:	e501                	bnez	a0,80004ee0 <pipealloc+0xaa>
    80004eda:	a039                	j	80004ee8 <pipealloc+0xb2>
    80004edc:	6088                	ld	a0,0(s1)
    80004ede:	c51d                	beqz	a0,80004f0c <pipealloc+0xd6>
    fileclose(*f0);
    80004ee0:	00000097          	auipc	ra,0x0
    80004ee4:	c26080e7          	jalr	-986(ra) # 80004b06 <fileclose>
  if(*f1)
    80004ee8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004eec:	557d                	li	a0,-1
  if(*f1)
    80004eee:	c799                	beqz	a5,80004efc <pipealloc+0xc6>
    fileclose(*f1);
    80004ef0:	853e                	mv	a0,a5
    80004ef2:	00000097          	auipc	ra,0x0
    80004ef6:	c14080e7          	jalr	-1004(ra) # 80004b06 <fileclose>
  return -1;
    80004efa:	557d                	li	a0,-1
}
    80004efc:	70a2                	ld	ra,40(sp)
    80004efe:	7402                	ld	s0,32(sp)
    80004f00:	64e2                	ld	s1,24(sp)
    80004f02:	6942                	ld	s2,16(sp)
    80004f04:	69a2                	ld	s3,8(sp)
    80004f06:	6a02                	ld	s4,0(sp)
    80004f08:	6145                	addi	sp,sp,48
    80004f0a:	8082                	ret
  return -1;
    80004f0c:	557d                	li	a0,-1
    80004f0e:	b7fd                	j	80004efc <pipealloc+0xc6>

0000000080004f10 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f10:	1101                	addi	sp,sp,-32
    80004f12:	ec06                	sd	ra,24(sp)
    80004f14:	e822                	sd	s0,16(sp)
    80004f16:	e426                	sd	s1,8(sp)
    80004f18:	e04a                	sd	s2,0(sp)
    80004f1a:	1000                	addi	s0,sp,32
    80004f1c:	84aa                	mv	s1,a0
    80004f1e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	cb0080e7          	jalr	-848(ra) # 80000bd0 <acquire>
  if(writable){
    80004f28:	02090d63          	beqz	s2,80004f62 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f2c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f30:	21848513          	addi	a0,s1,536
    80004f34:	ffffd097          	auipc	ra,0xffffd
    80004f38:	2da080e7          	jalr	730(ra) # 8000220e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f3c:	2204b783          	ld	a5,544(s1)
    80004f40:	eb95                	bnez	a5,80004f74 <pipeclose+0x64>
    release(&pi->lock);
    80004f42:	8526                	mv	a0,s1
    80004f44:	ffffc097          	auipc	ra,0xffffc
    80004f48:	d40080e7          	jalr	-704(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004f4c:	8526                	mv	a0,s1
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	a94080e7          	jalr	-1388(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004f56:	60e2                	ld	ra,24(sp)
    80004f58:	6442                	ld	s0,16(sp)
    80004f5a:	64a2                	ld	s1,8(sp)
    80004f5c:	6902                	ld	s2,0(sp)
    80004f5e:	6105                	addi	sp,sp,32
    80004f60:	8082                	ret
    pi->readopen = 0;
    80004f62:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f66:	21c48513          	addi	a0,s1,540
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	2a4080e7          	jalr	676(ra) # 8000220e <wakeup>
    80004f72:	b7e9                	j	80004f3c <pipeclose+0x2c>
    release(&pi->lock);
    80004f74:	8526                	mv	a0,s1
    80004f76:	ffffc097          	auipc	ra,0xffffc
    80004f7a:	d0e080e7          	jalr	-754(ra) # 80000c84 <release>
}
    80004f7e:	bfe1                	j	80004f56 <pipeclose+0x46>

0000000080004f80 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f80:	711d                	addi	sp,sp,-96
    80004f82:	ec86                	sd	ra,88(sp)
    80004f84:	e8a2                	sd	s0,80(sp)
    80004f86:	e4a6                	sd	s1,72(sp)
    80004f88:	e0ca                	sd	s2,64(sp)
    80004f8a:	fc4e                	sd	s3,56(sp)
    80004f8c:	f852                	sd	s4,48(sp)
    80004f8e:	f456                	sd	s5,40(sp)
    80004f90:	f05a                	sd	s6,32(sp)
    80004f92:	ec5e                	sd	s7,24(sp)
    80004f94:	e862                	sd	s8,16(sp)
    80004f96:	1080                	addi	s0,sp,96
    80004f98:	84aa                	mv	s1,a0
    80004f9a:	8aae                	mv	s5,a1
    80004f9c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f9e:	ffffd097          	auipc	ra,0xffffd
    80004fa2:	9f8080e7          	jalr	-1544(ra) # 80001996 <myproc>
    80004fa6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fa8:	8526                	mv	a0,s1
    80004faa:	ffffc097          	auipc	ra,0xffffc
    80004fae:	c26080e7          	jalr	-986(ra) # 80000bd0 <acquire>
  while(i < n){
    80004fb2:	0b405363          	blez	s4,80005058 <pipewrite+0xd8>
  int i = 0;
    80004fb6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fb8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fba:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004fbe:	21c48b93          	addi	s7,s1,540
    80004fc2:	a089                	j	80005004 <pipewrite+0x84>
      release(&pi->lock);
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	cbe080e7          	jalr	-834(ra) # 80000c84 <release>
      return -1;
    80004fce:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fd0:	854a                	mv	a0,s2
    80004fd2:	60e6                	ld	ra,88(sp)
    80004fd4:	6446                	ld	s0,80(sp)
    80004fd6:	64a6                	ld	s1,72(sp)
    80004fd8:	6906                	ld	s2,64(sp)
    80004fda:	79e2                	ld	s3,56(sp)
    80004fdc:	7a42                	ld	s4,48(sp)
    80004fde:	7aa2                	ld	s5,40(sp)
    80004fe0:	7b02                	ld	s6,32(sp)
    80004fe2:	6be2                	ld	s7,24(sp)
    80004fe4:	6c42                	ld	s8,16(sp)
    80004fe6:	6125                	addi	sp,sp,96
    80004fe8:	8082                	ret
      wakeup(&pi->nread);
    80004fea:	8562                	mv	a0,s8
    80004fec:	ffffd097          	auipc	ra,0xffffd
    80004ff0:	222080e7          	jalr	546(ra) # 8000220e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ff4:	85a6                	mv	a1,s1
    80004ff6:	855e                	mv	a0,s7
    80004ff8:	ffffd097          	auipc	ra,0xffffd
    80004ffc:	08a080e7          	jalr	138(ra) # 80002082 <sleep>
  while(i < n){
    80005000:	05495d63          	bge	s2,s4,8000505a <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005004:	2204a783          	lw	a5,544(s1)
    80005008:	dfd5                	beqz	a5,80004fc4 <pipewrite+0x44>
    8000500a:	0289a783          	lw	a5,40(s3)
    8000500e:	fbdd                	bnez	a5,80004fc4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005010:	2184a783          	lw	a5,536(s1)
    80005014:	21c4a703          	lw	a4,540(s1)
    80005018:	2007879b          	addiw	a5,a5,512
    8000501c:	fcf707e3          	beq	a4,a5,80004fea <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005020:	4685                	li	a3,1
    80005022:	01590633          	add	a2,s2,s5
    80005026:	faf40593          	addi	a1,s0,-81
    8000502a:	0509b503          	ld	a0,80(s3)
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	6b8080e7          	jalr	1720(ra) # 800016e6 <copyin>
    80005036:	03650263          	beq	a0,s6,8000505a <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000503a:	21c4a783          	lw	a5,540(s1)
    8000503e:	0017871b          	addiw	a4,a5,1
    80005042:	20e4ae23          	sw	a4,540(s1)
    80005046:	1ff7f793          	andi	a5,a5,511
    8000504a:	97a6                	add	a5,a5,s1
    8000504c:	faf44703          	lbu	a4,-81(s0)
    80005050:	00e78c23          	sb	a4,24(a5)
      i++;
    80005054:	2905                	addiw	s2,s2,1
    80005056:	b76d                	j	80005000 <pipewrite+0x80>
  int i = 0;
    80005058:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000505a:	21848513          	addi	a0,s1,536
    8000505e:	ffffd097          	auipc	ra,0xffffd
    80005062:	1b0080e7          	jalr	432(ra) # 8000220e <wakeup>
  release(&pi->lock);
    80005066:	8526                	mv	a0,s1
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	c1c080e7          	jalr	-996(ra) # 80000c84 <release>
  return i;
    80005070:	b785                	j	80004fd0 <pipewrite+0x50>

0000000080005072 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005072:	715d                	addi	sp,sp,-80
    80005074:	e486                	sd	ra,72(sp)
    80005076:	e0a2                	sd	s0,64(sp)
    80005078:	fc26                	sd	s1,56(sp)
    8000507a:	f84a                	sd	s2,48(sp)
    8000507c:	f44e                	sd	s3,40(sp)
    8000507e:	f052                	sd	s4,32(sp)
    80005080:	ec56                	sd	s5,24(sp)
    80005082:	e85a                	sd	s6,16(sp)
    80005084:	0880                	addi	s0,sp,80
    80005086:	84aa                	mv	s1,a0
    80005088:	892e                	mv	s2,a1
    8000508a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	90a080e7          	jalr	-1782(ra) # 80001996 <myproc>
    80005094:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005096:	8526                	mv	a0,s1
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	b38080e7          	jalr	-1224(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050a0:	2184a703          	lw	a4,536(s1)
    800050a4:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050a8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050ac:	02f71463          	bne	a4,a5,800050d4 <piperead+0x62>
    800050b0:	2244a783          	lw	a5,548(s1)
    800050b4:	c385                	beqz	a5,800050d4 <piperead+0x62>
    if(pr->killed){
    800050b6:	028a2783          	lw	a5,40(s4)
    800050ba:	ebc9                	bnez	a5,8000514c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050bc:	85a6                	mv	a1,s1
    800050be:	854e                	mv	a0,s3
    800050c0:	ffffd097          	auipc	ra,0xffffd
    800050c4:	fc2080e7          	jalr	-62(ra) # 80002082 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050c8:	2184a703          	lw	a4,536(s1)
    800050cc:	21c4a783          	lw	a5,540(s1)
    800050d0:	fef700e3          	beq	a4,a5,800050b0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050d4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050d6:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050d8:	05505463          	blez	s5,80005120 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    800050dc:	2184a783          	lw	a5,536(s1)
    800050e0:	21c4a703          	lw	a4,540(s1)
    800050e4:	02f70e63          	beq	a4,a5,80005120 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050e8:	0017871b          	addiw	a4,a5,1
    800050ec:	20e4ac23          	sw	a4,536(s1)
    800050f0:	1ff7f793          	andi	a5,a5,511
    800050f4:	97a6                	add	a5,a5,s1
    800050f6:	0187c783          	lbu	a5,24(a5)
    800050fa:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050fe:	4685                	li	a3,1
    80005100:	fbf40613          	addi	a2,s0,-65
    80005104:	85ca                	mv	a1,s2
    80005106:	050a3503          	ld	a0,80(s4)
    8000510a:	ffffc097          	auipc	ra,0xffffc
    8000510e:	550080e7          	jalr	1360(ra) # 8000165a <copyout>
    80005112:	01650763          	beq	a0,s6,80005120 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005116:	2985                	addiw	s3,s3,1
    80005118:	0905                	addi	s2,s2,1
    8000511a:	fd3a91e3          	bne	s5,s3,800050dc <piperead+0x6a>
    8000511e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005120:	21c48513          	addi	a0,s1,540
    80005124:	ffffd097          	auipc	ra,0xffffd
    80005128:	0ea080e7          	jalr	234(ra) # 8000220e <wakeup>
  release(&pi->lock);
    8000512c:	8526                	mv	a0,s1
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	b56080e7          	jalr	-1194(ra) # 80000c84 <release>
  return i;
}
    80005136:	854e                	mv	a0,s3
    80005138:	60a6                	ld	ra,72(sp)
    8000513a:	6406                	ld	s0,64(sp)
    8000513c:	74e2                	ld	s1,56(sp)
    8000513e:	7942                	ld	s2,48(sp)
    80005140:	79a2                	ld	s3,40(sp)
    80005142:	7a02                	ld	s4,32(sp)
    80005144:	6ae2                	ld	s5,24(sp)
    80005146:	6b42                	ld	s6,16(sp)
    80005148:	6161                	addi	sp,sp,80
    8000514a:	8082                	ret
      release(&pi->lock);
    8000514c:	8526                	mv	a0,s1
    8000514e:	ffffc097          	auipc	ra,0xffffc
    80005152:	b36080e7          	jalr	-1226(ra) # 80000c84 <release>
      return -1;
    80005156:	59fd                	li	s3,-1
    80005158:	bff9                	j	80005136 <piperead+0xc4>

000000008000515a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000515a:	de010113          	addi	sp,sp,-544
    8000515e:	20113c23          	sd	ra,536(sp)
    80005162:	20813823          	sd	s0,528(sp)
    80005166:	20913423          	sd	s1,520(sp)
    8000516a:	21213023          	sd	s2,512(sp)
    8000516e:	ffce                	sd	s3,504(sp)
    80005170:	fbd2                	sd	s4,496(sp)
    80005172:	f7d6                	sd	s5,488(sp)
    80005174:	f3da                	sd	s6,480(sp)
    80005176:	efde                	sd	s7,472(sp)
    80005178:	ebe2                	sd	s8,464(sp)
    8000517a:	e7e6                	sd	s9,456(sp)
    8000517c:	e3ea                	sd	s10,448(sp)
    8000517e:	ff6e                	sd	s11,440(sp)
    80005180:	1400                	addi	s0,sp,544
    80005182:	892a                	mv	s2,a0
    80005184:	dea43423          	sd	a0,-536(s0)
    80005188:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000518c:	ffffd097          	auipc	ra,0xffffd
    80005190:	80a080e7          	jalr	-2038(ra) # 80001996 <myproc>
    80005194:	84aa                	mv	s1,a0

  begin_op();
    80005196:	fffff097          	auipc	ra,0xfffff
    8000519a:	4a8080e7          	jalr	1192(ra) # 8000463e <begin_op>

  if((ip = namei(path)) == 0){
    8000519e:	854a                	mv	a0,s2
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	27e080e7          	jalr	638(ra) # 8000441e <namei>
    800051a8:	c93d                	beqz	a0,8000521e <exec+0xc4>
    800051aa:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	ab6080e7          	jalr	-1354(ra) # 80003c62 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051b4:	04000713          	li	a4,64
    800051b8:	4681                	li	a3,0
    800051ba:	e5040613          	addi	a2,s0,-432
    800051be:	4581                	li	a1,0
    800051c0:	8556                	mv	a0,s5
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	d54080e7          	jalr	-684(ra) # 80003f16 <readi>
    800051ca:	04000793          	li	a5,64
    800051ce:	00f51a63          	bne	a0,a5,800051e2 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800051d2:	e5042703          	lw	a4,-432(s0)
    800051d6:	464c47b7          	lui	a5,0x464c4
    800051da:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051de:	04f70663          	beq	a4,a5,8000522a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051e2:	8556                	mv	a0,s5
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	ce0080e7          	jalr	-800(ra) # 80003ec4 <iunlockput>
    end_op();
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	4d0080e7          	jalr	1232(ra) # 800046bc <end_op>
  }
  return -1;
    800051f4:	557d                	li	a0,-1
}
    800051f6:	21813083          	ld	ra,536(sp)
    800051fa:	21013403          	ld	s0,528(sp)
    800051fe:	20813483          	ld	s1,520(sp)
    80005202:	20013903          	ld	s2,512(sp)
    80005206:	79fe                	ld	s3,504(sp)
    80005208:	7a5e                	ld	s4,496(sp)
    8000520a:	7abe                	ld	s5,488(sp)
    8000520c:	7b1e                	ld	s6,480(sp)
    8000520e:	6bfe                	ld	s7,472(sp)
    80005210:	6c5e                	ld	s8,464(sp)
    80005212:	6cbe                	ld	s9,456(sp)
    80005214:	6d1e                	ld	s10,448(sp)
    80005216:	7dfa                	ld	s11,440(sp)
    80005218:	22010113          	addi	sp,sp,544
    8000521c:	8082                	ret
    end_op();
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	49e080e7          	jalr	1182(ra) # 800046bc <end_op>
    return -1;
    80005226:	557d                	li	a0,-1
    80005228:	b7f9                	j	800051f6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000522a:	8526                	mv	a0,s1
    8000522c:	ffffd097          	auipc	ra,0xffffd
    80005230:	84a080e7          	jalr	-1974(ra) # 80001a76 <proc_pagetable>
    80005234:	8b2a                	mv	s6,a0
    80005236:	d555                	beqz	a0,800051e2 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005238:	e7042783          	lw	a5,-400(s0)
    8000523c:	e8845703          	lhu	a4,-376(s0)
    80005240:	c735                	beqz	a4,800052ac <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005242:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005244:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80005248:	6a05                	lui	s4,0x1
    8000524a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000524e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005252:	6d85                	lui	s11,0x1
    80005254:	7d7d                	lui	s10,0xfffff
    80005256:	ac1d                	j	8000548c <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005258:	00003517          	auipc	a0,0x3
    8000525c:	57850513          	addi	a0,a0,1400 # 800087d0 <syscalls+0x2c8>
    80005260:	ffffb097          	auipc	ra,0xffffb
    80005264:	2da080e7          	jalr	730(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005268:	874a                	mv	a4,s2
    8000526a:	009c86bb          	addw	a3,s9,s1
    8000526e:	4581                	li	a1,0
    80005270:	8556                	mv	a0,s5
    80005272:	fffff097          	auipc	ra,0xfffff
    80005276:	ca4080e7          	jalr	-860(ra) # 80003f16 <readi>
    8000527a:	2501                	sext.w	a0,a0
    8000527c:	1aa91863          	bne	s2,a0,8000542c <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005280:	009d84bb          	addw	s1,s11,s1
    80005284:	013d09bb          	addw	s3,s10,s3
    80005288:	1f74f263          	bgeu	s1,s7,8000546c <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    8000528c:	02049593          	slli	a1,s1,0x20
    80005290:	9181                	srli	a1,a1,0x20
    80005292:	95e2                	add	a1,a1,s8
    80005294:	855a                	mv	a0,s6
    80005296:	ffffc097          	auipc	ra,0xffffc
    8000529a:	dbc080e7          	jalr	-580(ra) # 80001052 <walkaddr>
    8000529e:	862a                	mv	a2,a0
    if(pa == 0)
    800052a0:	dd45                	beqz	a0,80005258 <exec+0xfe>
      n = PGSIZE;
    800052a2:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800052a4:	fd49f2e3          	bgeu	s3,s4,80005268 <exec+0x10e>
      n = sz - i;
    800052a8:	894e                	mv	s2,s3
    800052aa:	bf7d                	j	80005268 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052ac:	4481                	li	s1,0
  iunlockput(ip);
    800052ae:	8556                	mv	a0,s5
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	c14080e7          	jalr	-1004(ra) # 80003ec4 <iunlockput>
  end_op();
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	404080e7          	jalr	1028(ra) # 800046bc <end_op>
  p = myproc();
    800052c0:	ffffc097          	auipc	ra,0xffffc
    800052c4:	6d6080e7          	jalr	1750(ra) # 80001996 <myproc>
    800052c8:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800052ca:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800052ce:	6785                	lui	a5,0x1
    800052d0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800052d2:	97a6                	add	a5,a5,s1
    800052d4:	777d                	lui	a4,0xfffff
    800052d6:	8ff9                	and	a5,a5,a4
    800052d8:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052dc:	6609                	lui	a2,0x2
    800052de:	963e                	add	a2,a2,a5
    800052e0:	85be                	mv	a1,a5
    800052e2:	855a                	mv	a0,s6
    800052e4:	ffffc097          	auipc	ra,0xffffc
    800052e8:	122080e7          	jalr	290(ra) # 80001406 <uvmalloc>
    800052ec:	8c2a                	mv	s8,a0
  ip = 0;
    800052ee:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052f0:	12050e63          	beqz	a0,8000542c <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052f4:	75f9                	lui	a1,0xffffe
    800052f6:	95aa                	add	a1,a1,a0
    800052f8:	855a                	mv	a0,s6
    800052fa:	ffffc097          	auipc	ra,0xffffc
    800052fe:	32e080e7          	jalr	814(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80005302:	7afd                	lui	s5,0xfffff
    80005304:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005306:	df043783          	ld	a5,-528(s0)
    8000530a:	6388                	ld	a0,0(a5)
    8000530c:	c925                	beqz	a0,8000537c <exec+0x222>
    8000530e:	e9040993          	addi	s3,s0,-368
    80005312:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005316:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005318:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000531a:	ffffc097          	auipc	ra,0xffffc
    8000531e:	b2e080e7          	jalr	-1234(ra) # 80000e48 <strlen>
    80005322:	0015079b          	addiw	a5,a0,1
    80005326:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000532a:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000532e:	13596363          	bltu	s2,s5,80005454 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005332:	df043d83          	ld	s11,-528(s0)
    80005336:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000533a:	8552                	mv	a0,s4
    8000533c:	ffffc097          	auipc	ra,0xffffc
    80005340:	b0c080e7          	jalr	-1268(ra) # 80000e48 <strlen>
    80005344:	0015069b          	addiw	a3,a0,1
    80005348:	8652                	mv	a2,s4
    8000534a:	85ca                	mv	a1,s2
    8000534c:	855a                	mv	a0,s6
    8000534e:	ffffc097          	auipc	ra,0xffffc
    80005352:	30c080e7          	jalr	780(ra) # 8000165a <copyout>
    80005356:	10054363          	bltz	a0,8000545c <exec+0x302>
    ustack[argc] = sp;
    8000535a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000535e:	0485                	addi	s1,s1,1
    80005360:	008d8793          	addi	a5,s11,8
    80005364:	def43823          	sd	a5,-528(s0)
    80005368:	008db503          	ld	a0,8(s11)
    8000536c:	c911                	beqz	a0,80005380 <exec+0x226>
    if(argc >= MAXARG)
    8000536e:	09a1                	addi	s3,s3,8
    80005370:	fb3c95e3          	bne	s9,s3,8000531a <exec+0x1c0>
  sz = sz1;
    80005374:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005378:	4a81                	li	s5,0
    8000537a:	a84d                	j	8000542c <exec+0x2d2>
  sp = sz;
    8000537c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000537e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005380:	00349793          	slli	a5,s1,0x3
    80005384:	f9078793          	addi	a5,a5,-112
    80005388:	97a2                	add	a5,a5,s0
    8000538a:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000538e:	00148693          	addi	a3,s1,1
    80005392:	068e                	slli	a3,a3,0x3
    80005394:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005398:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000539c:	01597663          	bgeu	s2,s5,800053a8 <exec+0x24e>
  sz = sz1;
    800053a0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053a4:	4a81                	li	s5,0
    800053a6:	a059                	j	8000542c <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053a8:	e9040613          	addi	a2,s0,-368
    800053ac:	85ca                	mv	a1,s2
    800053ae:	855a                	mv	a0,s6
    800053b0:	ffffc097          	auipc	ra,0xffffc
    800053b4:	2aa080e7          	jalr	682(ra) # 8000165a <copyout>
    800053b8:	0a054663          	bltz	a0,80005464 <exec+0x30a>
  p->trapframe->a1 = sp;
    800053bc:	058bb783          	ld	a5,88(s7)
    800053c0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053c4:	de843783          	ld	a5,-536(s0)
    800053c8:	0007c703          	lbu	a4,0(a5)
    800053cc:	cf11                	beqz	a4,800053e8 <exec+0x28e>
    800053ce:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053d0:	02f00693          	li	a3,47
    800053d4:	a039                	j	800053e2 <exec+0x288>
      last = s+1;
    800053d6:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800053da:	0785                	addi	a5,a5,1
    800053dc:	fff7c703          	lbu	a4,-1(a5)
    800053e0:	c701                	beqz	a4,800053e8 <exec+0x28e>
    if(*s == '/')
    800053e2:	fed71ce3          	bne	a4,a3,800053da <exec+0x280>
    800053e6:	bfc5                	j	800053d6 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800053e8:	4641                	li	a2,16
    800053ea:	de843583          	ld	a1,-536(s0)
    800053ee:	158b8513          	addi	a0,s7,344
    800053f2:	ffffc097          	auipc	ra,0xffffc
    800053f6:	a24080e7          	jalr	-1500(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800053fa:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800053fe:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005402:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005406:	058bb783          	ld	a5,88(s7)
    8000540a:	e6843703          	ld	a4,-408(s0)
    8000540e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005410:	058bb783          	ld	a5,88(s7)
    80005414:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005418:	85ea                	mv	a1,s10
    8000541a:	ffffc097          	auipc	ra,0xffffc
    8000541e:	6f8080e7          	jalr	1784(ra) # 80001b12 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005422:	0004851b          	sext.w	a0,s1
    80005426:	bbc1                	j	800051f6 <exec+0x9c>
    80005428:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000542c:	df843583          	ld	a1,-520(s0)
    80005430:	855a                	mv	a0,s6
    80005432:	ffffc097          	auipc	ra,0xffffc
    80005436:	6e0080e7          	jalr	1760(ra) # 80001b12 <proc_freepagetable>
  if(ip){
    8000543a:	da0a94e3          	bnez	s5,800051e2 <exec+0x88>
  return -1;
    8000543e:	557d                	li	a0,-1
    80005440:	bb5d                	j	800051f6 <exec+0x9c>
    80005442:	de943c23          	sd	s1,-520(s0)
    80005446:	b7dd                	j	8000542c <exec+0x2d2>
    80005448:	de943c23          	sd	s1,-520(s0)
    8000544c:	b7c5                	j	8000542c <exec+0x2d2>
    8000544e:	de943c23          	sd	s1,-520(s0)
    80005452:	bfe9                	j	8000542c <exec+0x2d2>
  sz = sz1;
    80005454:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005458:	4a81                	li	s5,0
    8000545a:	bfc9                	j	8000542c <exec+0x2d2>
  sz = sz1;
    8000545c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005460:	4a81                	li	s5,0
    80005462:	b7e9                	j	8000542c <exec+0x2d2>
  sz = sz1;
    80005464:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005468:	4a81                	li	s5,0
    8000546a:	b7c9                	j	8000542c <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000546c:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005470:	e0843783          	ld	a5,-504(s0)
    80005474:	0017869b          	addiw	a3,a5,1
    80005478:	e0d43423          	sd	a3,-504(s0)
    8000547c:	e0043783          	ld	a5,-512(s0)
    80005480:	0387879b          	addiw	a5,a5,56
    80005484:	e8845703          	lhu	a4,-376(s0)
    80005488:	e2e6d3e3          	bge	a3,a4,800052ae <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000548c:	2781                	sext.w	a5,a5
    8000548e:	e0f43023          	sd	a5,-512(s0)
    80005492:	03800713          	li	a4,56
    80005496:	86be                	mv	a3,a5
    80005498:	e1840613          	addi	a2,s0,-488
    8000549c:	4581                	li	a1,0
    8000549e:	8556                	mv	a0,s5
    800054a0:	fffff097          	auipc	ra,0xfffff
    800054a4:	a76080e7          	jalr	-1418(ra) # 80003f16 <readi>
    800054a8:	03800793          	li	a5,56
    800054ac:	f6f51ee3          	bne	a0,a5,80005428 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800054b0:	e1842783          	lw	a5,-488(s0)
    800054b4:	4705                	li	a4,1
    800054b6:	fae79de3          	bne	a5,a4,80005470 <exec+0x316>
    if(ph.memsz < ph.filesz)
    800054ba:	e4043603          	ld	a2,-448(s0)
    800054be:	e3843783          	ld	a5,-456(s0)
    800054c2:	f8f660e3          	bltu	a2,a5,80005442 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054c6:	e2843783          	ld	a5,-472(s0)
    800054ca:	963e                	add	a2,a2,a5
    800054cc:	f6f66ee3          	bltu	a2,a5,80005448 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054d0:	85a6                	mv	a1,s1
    800054d2:	855a                	mv	a0,s6
    800054d4:	ffffc097          	auipc	ra,0xffffc
    800054d8:	f32080e7          	jalr	-206(ra) # 80001406 <uvmalloc>
    800054dc:	dea43c23          	sd	a0,-520(s0)
    800054e0:	d53d                	beqz	a0,8000544e <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    800054e2:	e2843c03          	ld	s8,-472(s0)
    800054e6:	de043783          	ld	a5,-544(s0)
    800054ea:	00fc77b3          	and	a5,s8,a5
    800054ee:	ff9d                	bnez	a5,8000542c <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054f0:	e2042c83          	lw	s9,-480(s0)
    800054f4:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054f8:	f60b8ae3          	beqz	s7,8000546c <exec+0x312>
    800054fc:	89de                	mv	s3,s7
    800054fe:	4481                	li	s1,0
    80005500:	b371                	j	8000528c <exec+0x132>

0000000080005502 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005502:	7179                	addi	sp,sp,-48
    80005504:	f406                	sd	ra,40(sp)
    80005506:	f022                	sd	s0,32(sp)
    80005508:	ec26                	sd	s1,24(sp)
    8000550a:	e84a                	sd	s2,16(sp)
    8000550c:	1800                	addi	s0,sp,48
    8000550e:	892e                	mv	s2,a1
    80005510:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005512:	fdc40593          	addi	a1,s0,-36
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	a34080e7          	jalr	-1484(ra) # 80002f4a <argint>
    8000551e:	04054063          	bltz	a0,8000555e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005522:	fdc42703          	lw	a4,-36(s0)
    80005526:	47bd                	li	a5,15
    80005528:	02e7ed63          	bltu	a5,a4,80005562 <argfd+0x60>
    8000552c:	ffffc097          	auipc	ra,0xffffc
    80005530:	46a080e7          	jalr	1130(ra) # 80001996 <myproc>
    80005534:	fdc42703          	lw	a4,-36(s0)
    80005538:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    8000553c:	078e                	slli	a5,a5,0x3
    8000553e:	953e                	add	a0,a0,a5
    80005540:	611c                	ld	a5,0(a0)
    80005542:	c395                	beqz	a5,80005566 <argfd+0x64>
    return -1;
  if(pfd)
    80005544:	00090463          	beqz	s2,8000554c <argfd+0x4a>
    *pfd = fd;
    80005548:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000554c:	4501                	li	a0,0
  if(pf)
    8000554e:	c091                	beqz	s1,80005552 <argfd+0x50>
    *pf = f;
    80005550:	e09c                	sd	a5,0(s1)
}
    80005552:	70a2                	ld	ra,40(sp)
    80005554:	7402                	ld	s0,32(sp)
    80005556:	64e2                	ld	s1,24(sp)
    80005558:	6942                	ld	s2,16(sp)
    8000555a:	6145                	addi	sp,sp,48
    8000555c:	8082                	ret
    return -1;
    8000555e:	557d                	li	a0,-1
    80005560:	bfcd                	j	80005552 <argfd+0x50>
    return -1;
    80005562:	557d                	li	a0,-1
    80005564:	b7fd                	j	80005552 <argfd+0x50>
    80005566:	557d                	li	a0,-1
    80005568:	b7ed                	j	80005552 <argfd+0x50>

000000008000556a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000556a:	1101                	addi	sp,sp,-32
    8000556c:	ec06                	sd	ra,24(sp)
    8000556e:	e822                	sd	s0,16(sp)
    80005570:	e426                	sd	s1,8(sp)
    80005572:	1000                	addi	s0,sp,32
    80005574:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005576:	ffffc097          	auipc	ra,0xffffc
    8000557a:	420080e7          	jalr	1056(ra) # 80001996 <myproc>
    8000557e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005580:	0d050793          	addi	a5,a0,208
    80005584:	4501                	li	a0,0
    80005586:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005588:	6398                	ld	a4,0(a5)
    8000558a:	cb19                	beqz	a4,800055a0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000558c:	2505                	addiw	a0,a0,1
    8000558e:	07a1                	addi	a5,a5,8
    80005590:	fed51ce3          	bne	a0,a3,80005588 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005594:	557d                	li	a0,-1
}
    80005596:	60e2                	ld	ra,24(sp)
    80005598:	6442                	ld	s0,16(sp)
    8000559a:	64a2                	ld	s1,8(sp)
    8000559c:	6105                	addi	sp,sp,32
    8000559e:	8082                	ret
      p->ofile[fd] = f;
    800055a0:	01a50793          	addi	a5,a0,26
    800055a4:	078e                	slli	a5,a5,0x3
    800055a6:	963e                	add	a2,a2,a5
    800055a8:	e204                	sd	s1,0(a2)
      return fd;
    800055aa:	b7f5                	j	80005596 <fdalloc+0x2c>

00000000800055ac <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055ac:	715d                	addi	sp,sp,-80
    800055ae:	e486                	sd	ra,72(sp)
    800055b0:	e0a2                	sd	s0,64(sp)
    800055b2:	fc26                	sd	s1,56(sp)
    800055b4:	f84a                	sd	s2,48(sp)
    800055b6:	f44e                	sd	s3,40(sp)
    800055b8:	f052                	sd	s4,32(sp)
    800055ba:	ec56                	sd	s5,24(sp)
    800055bc:	0880                	addi	s0,sp,80
    800055be:	89ae                	mv	s3,a1
    800055c0:	8ab2                	mv	s5,a2
    800055c2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055c4:	fb040593          	addi	a1,s0,-80
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	e74080e7          	jalr	-396(ra) # 8000443c <nameiparent>
    800055d0:	892a                	mv	s2,a0
    800055d2:	12050e63          	beqz	a0,8000570e <create+0x162>
    return 0;

  ilock(dp);
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	68c080e7          	jalr	1676(ra) # 80003c62 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055de:	4601                	li	a2,0
    800055e0:	fb040593          	addi	a1,s0,-80
    800055e4:	854a                	mv	a0,s2
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	b60080e7          	jalr	-1184(ra) # 80004146 <dirlookup>
    800055ee:	84aa                	mv	s1,a0
    800055f0:	c921                	beqz	a0,80005640 <create+0x94>
    iunlockput(dp);
    800055f2:	854a                	mv	a0,s2
    800055f4:	fffff097          	auipc	ra,0xfffff
    800055f8:	8d0080e7          	jalr	-1840(ra) # 80003ec4 <iunlockput>
    ilock(ip);
    800055fc:	8526                	mv	a0,s1
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	664080e7          	jalr	1636(ra) # 80003c62 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005606:	2981                	sext.w	s3,s3
    80005608:	4789                	li	a5,2
    8000560a:	02f99463          	bne	s3,a5,80005632 <create+0x86>
    8000560e:	0444d783          	lhu	a5,68(s1)
    80005612:	37f9                	addiw	a5,a5,-2
    80005614:	17c2                	slli	a5,a5,0x30
    80005616:	93c1                	srli	a5,a5,0x30
    80005618:	4705                	li	a4,1
    8000561a:	00f76c63          	bltu	a4,a5,80005632 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000561e:	8526                	mv	a0,s1
    80005620:	60a6                	ld	ra,72(sp)
    80005622:	6406                	ld	s0,64(sp)
    80005624:	74e2                	ld	s1,56(sp)
    80005626:	7942                	ld	s2,48(sp)
    80005628:	79a2                	ld	s3,40(sp)
    8000562a:	7a02                	ld	s4,32(sp)
    8000562c:	6ae2                	ld	s5,24(sp)
    8000562e:	6161                	addi	sp,sp,80
    80005630:	8082                	ret
    iunlockput(ip);
    80005632:	8526                	mv	a0,s1
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	890080e7          	jalr	-1904(ra) # 80003ec4 <iunlockput>
    return 0;
    8000563c:	4481                	li	s1,0
    8000563e:	b7c5                	j	8000561e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005640:	85ce                	mv	a1,s3
    80005642:	00092503          	lw	a0,0(s2)
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	482080e7          	jalr	1154(ra) # 80003ac8 <ialloc>
    8000564e:	84aa                	mv	s1,a0
    80005650:	c521                	beqz	a0,80005698 <create+0xec>
  ilock(ip);
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	610080e7          	jalr	1552(ra) # 80003c62 <ilock>
  ip->major = major;
    8000565a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000565e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005662:	4a05                	li	s4,1
    80005664:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005668:	8526                	mv	a0,s1
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	52c080e7          	jalr	1324(ra) # 80003b96 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005672:	2981                	sext.w	s3,s3
    80005674:	03498a63          	beq	s3,s4,800056a8 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005678:	40d0                	lw	a2,4(s1)
    8000567a:	fb040593          	addi	a1,s0,-80
    8000567e:	854a                	mv	a0,s2
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	cdc080e7          	jalr	-804(ra) # 8000435c <dirlink>
    80005688:	06054b63          	bltz	a0,800056fe <create+0x152>
  iunlockput(dp);
    8000568c:	854a                	mv	a0,s2
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	836080e7          	jalr	-1994(ra) # 80003ec4 <iunlockput>
  return ip;
    80005696:	b761                	j	8000561e <create+0x72>
    panic("create: ialloc");
    80005698:	00003517          	auipc	a0,0x3
    8000569c:	15850513          	addi	a0,a0,344 # 800087f0 <syscalls+0x2e8>
    800056a0:	ffffb097          	auipc	ra,0xffffb
    800056a4:	e9a080e7          	jalr	-358(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    800056a8:	04a95783          	lhu	a5,74(s2)
    800056ac:	2785                	addiw	a5,a5,1
    800056ae:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800056b2:	854a                	mv	a0,s2
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	4e2080e7          	jalr	1250(ra) # 80003b96 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056bc:	40d0                	lw	a2,4(s1)
    800056be:	00003597          	auipc	a1,0x3
    800056c2:	14258593          	addi	a1,a1,322 # 80008800 <syscalls+0x2f8>
    800056c6:	8526                	mv	a0,s1
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	c94080e7          	jalr	-876(ra) # 8000435c <dirlink>
    800056d0:	00054f63          	bltz	a0,800056ee <create+0x142>
    800056d4:	00492603          	lw	a2,4(s2)
    800056d8:	00003597          	auipc	a1,0x3
    800056dc:	13058593          	addi	a1,a1,304 # 80008808 <syscalls+0x300>
    800056e0:	8526                	mv	a0,s1
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	c7a080e7          	jalr	-902(ra) # 8000435c <dirlink>
    800056ea:	f80557e3          	bgez	a0,80005678 <create+0xcc>
      panic("create dots");
    800056ee:	00003517          	auipc	a0,0x3
    800056f2:	12250513          	addi	a0,a0,290 # 80008810 <syscalls+0x308>
    800056f6:	ffffb097          	auipc	ra,0xffffb
    800056fa:	e44080e7          	jalr	-444(ra) # 8000053a <panic>
    panic("create: dirlink");
    800056fe:	00003517          	auipc	a0,0x3
    80005702:	12250513          	addi	a0,a0,290 # 80008820 <syscalls+0x318>
    80005706:	ffffb097          	auipc	ra,0xffffb
    8000570a:	e34080e7          	jalr	-460(ra) # 8000053a <panic>
    return 0;
    8000570e:	84aa                	mv	s1,a0
    80005710:	b739                	j	8000561e <create+0x72>

0000000080005712 <sys_dup>:
{
    80005712:	7179                	addi	sp,sp,-48
    80005714:	f406                	sd	ra,40(sp)
    80005716:	f022                	sd	s0,32(sp)
    80005718:	ec26                	sd	s1,24(sp)
    8000571a:	e84a                	sd	s2,16(sp)
    8000571c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000571e:	fd840613          	addi	a2,s0,-40
    80005722:	4581                	li	a1,0
    80005724:	4501                	li	a0,0
    80005726:	00000097          	auipc	ra,0x0
    8000572a:	ddc080e7          	jalr	-548(ra) # 80005502 <argfd>
    return -1;
    8000572e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005730:	02054363          	bltz	a0,80005756 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005734:	fd843903          	ld	s2,-40(s0)
    80005738:	854a                	mv	a0,s2
    8000573a:	00000097          	auipc	ra,0x0
    8000573e:	e30080e7          	jalr	-464(ra) # 8000556a <fdalloc>
    80005742:	84aa                	mv	s1,a0
    return -1;
    80005744:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005746:	00054863          	bltz	a0,80005756 <sys_dup+0x44>
  filedup(f);
    8000574a:	854a                	mv	a0,s2
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	368080e7          	jalr	872(ra) # 80004ab4 <filedup>
  return fd;
    80005754:	87a6                	mv	a5,s1
}
    80005756:	853e                	mv	a0,a5
    80005758:	70a2                	ld	ra,40(sp)
    8000575a:	7402                	ld	s0,32(sp)
    8000575c:	64e2                	ld	s1,24(sp)
    8000575e:	6942                	ld	s2,16(sp)
    80005760:	6145                	addi	sp,sp,48
    80005762:	8082                	ret

0000000080005764 <sys_read>:
{
    80005764:	7179                	addi	sp,sp,-48
    80005766:	f406                	sd	ra,40(sp)
    80005768:	f022                	sd	s0,32(sp)
    8000576a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000576c:	fe840613          	addi	a2,s0,-24
    80005770:	4581                	li	a1,0
    80005772:	4501                	li	a0,0
    80005774:	00000097          	auipc	ra,0x0
    80005778:	d8e080e7          	jalr	-626(ra) # 80005502 <argfd>
    return -1;
    8000577c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000577e:	04054163          	bltz	a0,800057c0 <sys_read+0x5c>
    80005782:	fe440593          	addi	a1,s0,-28
    80005786:	4509                	li	a0,2
    80005788:	ffffd097          	auipc	ra,0xffffd
    8000578c:	7c2080e7          	jalr	1986(ra) # 80002f4a <argint>
    return -1;
    80005790:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005792:	02054763          	bltz	a0,800057c0 <sys_read+0x5c>
    80005796:	fd840593          	addi	a1,s0,-40
    8000579a:	4505                	li	a0,1
    8000579c:	ffffd097          	auipc	ra,0xffffd
    800057a0:	7d0080e7          	jalr	2000(ra) # 80002f6c <argaddr>
    return -1;
    800057a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a6:	00054d63          	bltz	a0,800057c0 <sys_read+0x5c>
  return fileread(f, p, n);
    800057aa:	fe442603          	lw	a2,-28(s0)
    800057ae:	fd843583          	ld	a1,-40(s0)
    800057b2:	fe843503          	ld	a0,-24(s0)
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	48a080e7          	jalr	1162(ra) # 80004c40 <fileread>
    800057be:	87aa                	mv	a5,a0
}
    800057c0:	853e                	mv	a0,a5
    800057c2:	70a2                	ld	ra,40(sp)
    800057c4:	7402                	ld	s0,32(sp)
    800057c6:	6145                	addi	sp,sp,48
    800057c8:	8082                	ret

00000000800057ca <sys_write>:
{
    800057ca:	7179                	addi	sp,sp,-48
    800057cc:	f406                	sd	ra,40(sp)
    800057ce:	f022                	sd	s0,32(sp)
    800057d0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057d2:	fe840613          	addi	a2,s0,-24
    800057d6:	4581                	li	a1,0
    800057d8:	4501                	li	a0,0
    800057da:	00000097          	auipc	ra,0x0
    800057de:	d28080e7          	jalr	-728(ra) # 80005502 <argfd>
    return -1;
    800057e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057e4:	04054163          	bltz	a0,80005826 <sys_write+0x5c>
    800057e8:	fe440593          	addi	a1,s0,-28
    800057ec:	4509                	li	a0,2
    800057ee:	ffffd097          	auipc	ra,0xffffd
    800057f2:	75c080e7          	jalr	1884(ra) # 80002f4a <argint>
    return -1;
    800057f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057f8:	02054763          	bltz	a0,80005826 <sys_write+0x5c>
    800057fc:	fd840593          	addi	a1,s0,-40
    80005800:	4505                	li	a0,1
    80005802:	ffffd097          	auipc	ra,0xffffd
    80005806:	76a080e7          	jalr	1898(ra) # 80002f6c <argaddr>
    return -1;
    8000580a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000580c:	00054d63          	bltz	a0,80005826 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005810:	fe442603          	lw	a2,-28(s0)
    80005814:	fd843583          	ld	a1,-40(s0)
    80005818:	fe843503          	ld	a0,-24(s0)
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	4e6080e7          	jalr	1254(ra) # 80004d02 <filewrite>
    80005824:	87aa                	mv	a5,a0
}
    80005826:	853e                	mv	a0,a5
    80005828:	70a2                	ld	ra,40(sp)
    8000582a:	7402                	ld	s0,32(sp)
    8000582c:	6145                	addi	sp,sp,48
    8000582e:	8082                	ret

0000000080005830 <sys_close>:
{
    80005830:	1101                	addi	sp,sp,-32
    80005832:	ec06                	sd	ra,24(sp)
    80005834:	e822                	sd	s0,16(sp)
    80005836:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005838:	fe040613          	addi	a2,s0,-32
    8000583c:	fec40593          	addi	a1,s0,-20
    80005840:	4501                	li	a0,0
    80005842:	00000097          	auipc	ra,0x0
    80005846:	cc0080e7          	jalr	-832(ra) # 80005502 <argfd>
    return -1;
    8000584a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000584c:	02054463          	bltz	a0,80005874 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005850:	ffffc097          	auipc	ra,0xffffc
    80005854:	146080e7          	jalr	326(ra) # 80001996 <myproc>
    80005858:	fec42783          	lw	a5,-20(s0)
    8000585c:	07e9                	addi	a5,a5,26
    8000585e:	078e                	slli	a5,a5,0x3
    80005860:	953e                	add	a0,a0,a5
    80005862:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005866:	fe043503          	ld	a0,-32(s0)
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	29c080e7          	jalr	668(ra) # 80004b06 <fileclose>
  return 0;
    80005872:	4781                	li	a5,0
}
    80005874:	853e                	mv	a0,a5
    80005876:	60e2                	ld	ra,24(sp)
    80005878:	6442                	ld	s0,16(sp)
    8000587a:	6105                	addi	sp,sp,32
    8000587c:	8082                	ret

000000008000587e <sys_fstat>:
{
    8000587e:	1101                	addi	sp,sp,-32
    80005880:	ec06                	sd	ra,24(sp)
    80005882:	e822                	sd	s0,16(sp)
    80005884:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005886:	fe840613          	addi	a2,s0,-24
    8000588a:	4581                	li	a1,0
    8000588c:	4501                	li	a0,0
    8000588e:	00000097          	auipc	ra,0x0
    80005892:	c74080e7          	jalr	-908(ra) # 80005502 <argfd>
    return -1;
    80005896:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005898:	02054563          	bltz	a0,800058c2 <sys_fstat+0x44>
    8000589c:	fe040593          	addi	a1,s0,-32
    800058a0:	4505                	li	a0,1
    800058a2:	ffffd097          	auipc	ra,0xffffd
    800058a6:	6ca080e7          	jalr	1738(ra) # 80002f6c <argaddr>
    return -1;
    800058aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058ac:	00054b63          	bltz	a0,800058c2 <sys_fstat+0x44>
  return filestat(f, st);
    800058b0:	fe043583          	ld	a1,-32(s0)
    800058b4:	fe843503          	ld	a0,-24(s0)
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	316080e7          	jalr	790(ra) # 80004bce <filestat>
    800058c0:	87aa                	mv	a5,a0
}
    800058c2:	853e                	mv	a0,a5
    800058c4:	60e2                	ld	ra,24(sp)
    800058c6:	6442                	ld	s0,16(sp)
    800058c8:	6105                	addi	sp,sp,32
    800058ca:	8082                	ret

00000000800058cc <sys_link>:
{
    800058cc:	7169                	addi	sp,sp,-304
    800058ce:	f606                	sd	ra,296(sp)
    800058d0:	f222                	sd	s0,288(sp)
    800058d2:	ee26                	sd	s1,280(sp)
    800058d4:	ea4a                	sd	s2,272(sp)
    800058d6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058d8:	08000613          	li	a2,128
    800058dc:	ed040593          	addi	a1,s0,-304
    800058e0:	4501                	li	a0,0
    800058e2:	ffffd097          	auipc	ra,0xffffd
    800058e6:	6ac080e7          	jalr	1708(ra) # 80002f8e <argstr>
    return -1;
    800058ea:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058ec:	10054e63          	bltz	a0,80005a08 <sys_link+0x13c>
    800058f0:	08000613          	li	a2,128
    800058f4:	f5040593          	addi	a1,s0,-176
    800058f8:	4505                	li	a0,1
    800058fa:	ffffd097          	auipc	ra,0xffffd
    800058fe:	694080e7          	jalr	1684(ra) # 80002f8e <argstr>
    return -1;
    80005902:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005904:	10054263          	bltz	a0,80005a08 <sys_link+0x13c>
  begin_op();
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	d36080e7          	jalr	-714(ra) # 8000463e <begin_op>
  if((ip = namei(old)) == 0){
    80005910:	ed040513          	addi	a0,s0,-304
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	b0a080e7          	jalr	-1270(ra) # 8000441e <namei>
    8000591c:	84aa                	mv	s1,a0
    8000591e:	c551                	beqz	a0,800059aa <sys_link+0xde>
  ilock(ip);
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	342080e7          	jalr	834(ra) # 80003c62 <ilock>
  if(ip->type == T_DIR){
    80005928:	04449703          	lh	a4,68(s1)
    8000592c:	4785                	li	a5,1
    8000592e:	08f70463          	beq	a4,a5,800059b6 <sys_link+0xea>
  ip->nlink++;
    80005932:	04a4d783          	lhu	a5,74(s1)
    80005936:	2785                	addiw	a5,a5,1
    80005938:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000593c:	8526                	mv	a0,s1
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	258080e7          	jalr	600(ra) # 80003b96 <iupdate>
  iunlock(ip);
    80005946:	8526                	mv	a0,s1
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	3dc080e7          	jalr	988(ra) # 80003d24 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005950:	fd040593          	addi	a1,s0,-48
    80005954:	f5040513          	addi	a0,s0,-176
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	ae4080e7          	jalr	-1308(ra) # 8000443c <nameiparent>
    80005960:	892a                	mv	s2,a0
    80005962:	c935                	beqz	a0,800059d6 <sys_link+0x10a>
  ilock(dp);
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	2fe080e7          	jalr	766(ra) # 80003c62 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000596c:	00092703          	lw	a4,0(s2)
    80005970:	409c                	lw	a5,0(s1)
    80005972:	04f71d63          	bne	a4,a5,800059cc <sys_link+0x100>
    80005976:	40d0                	lw	a2,4(s1)
    80005978:	fd040593          	addi	a1,s0,-48
    8000597c:	854a                	mv	a0,s2
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	9de080e7          	jalr	-1570(ra) # 8000435c <dirlink>
    80005986:	04054363          	bltz	a0,800059cc <sys_link+0x100>
  iunlockput(dp);
    8000598a:	854a                	mv	a0,s2
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	538080e7          	jalr	1336(ra) # 80003ec4 <iunlockput>
  iput(ip);
    80005994:	8526                	mv	a0,s1
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	486080e7          	jalr	1158(ra) # 80003e1c <iput>
  end_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	d1e080e7          	jalr	-738(ra) # 800046bc <end_op>
  return 0;
    800059a6:	4781                	li	a5,0
    800059a8:	a085                	j	80005a08 <sys_link+0x13c>
    end_op();
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	d12080e7          	jalr	-750(ra) # 800046bc <end_op>
    return -1;
    800059b2:	57fd                	li	a5,-1
    800059b4:	a891                	j	80005a08 <sys_link+0x13c>
    iunlockput(ip);
    800059b6:	8526                	mv	a0,s1
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	50c080e7          	jalr	1292(ra) # 80003ec4 <iunlockput>
    end_op();
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	cfc080e7          	jalr	-772(ra) # 800046bc <end_op>
    return -1;
    800059c8:	57fd                	li	a5,-1
    800059ca:	a83d                	j	80005a08 <sys_link+0x13c>
    iunlockput(dp);
    800059cc:	854a                	mv	a0,s2
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	4f6080e7          	jalr	1270(ra) # 80003ec4 <iunlockput>
  ilock(ip);
    800059d6:	8526                	mv	a0,s1
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	28a080e7          	jalr	650(ra) # 80003c62 <ilock>
  ip->nlink--;
    800059e0:	04a4d783          	lhu	a5,74(s1)
    800059e4:	37fd                	addiw	a5,a5,-1
    800059e6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059ea:	8526                	mv	a0,s1
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	1aa080e7          	jalr	426(ra) # 80003b96 <iupdate>
  iunlockput(ip);
    800059f4:	8526                	mv	a0,s1
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	4ce080e7          	jalr	1230(ra) # 80003ec4 <iunlockput>
  end_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	cbe080e7          	jalr	-834(ra) # 800046bc <end_op>
  return -1;
    80005a06:	57fd                	li	a5,-1
}
    80005a08:	853e                	mv	a0,a5
    80005a0a:	70b2                	ld	ra,296(sp)
    80005a0c:	7412                	ld	s0,288(sp)
    80005a0e:	64f2                	ld	s1,280(sp)
    80005a10:	6952                	ld	s2,272(sp)
    80005a12:	6155                	addi	sp,sp,304
    80005a14:	8082                	ret

0000000080005a16 <sys_unlink>:
{
    80005a16:	7151                	addi	sp,sp,-240
    80005a18:	f586                	sd	ra,232(sp)
    80005a1a:	f1a2                	sd	s0,224(sp)
    80005a1c:	eda6                	sd	s1,216(sp)
    80005a1e:	e9ca                	sd	s2,208(sp)
    80005a20:	e5ce                	sd	s3,200(sp)
    80005a22:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a24:	08000613          	li	a2,128
    80005a28:	f3040593          	addi	a1,s0,-208
    80005a2c:	4501                	li	a0,0
    80005a2e:	ffffd097          	auipc	ra,0xffffd
    80005a32:	560080e7          	jalr	1376(ra) # 80002f8e <argstr>
    80005a36:	18054163          	bltz	a0,80005bb8 <sys_unlink+0x1a2>
  begin_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	c04080e7          	jalr	-1020(ra) # 8000463e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a42:	fb040593          	addi	a1,s0,-80
    80005a46:	f3040513          	addi	a0,s0,-208
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	9f2080e7          	jalr	-1550(ra) # 8000443c <nameiparent>
    80005a52:	84aa                	mv	s1,a0
    80005a54:	c979                	beqz	a0,80005b2a <sys_unlink+0x114>
  ilock(dp);
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	20c080e7          	jalr	524(ra) # 80003c62 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a5e:	00003597          	auipc	a1,0x3
    80005a62:	da258593          	addi	a1,a1,-606 # 80008800 <syscalls+0x2f8>
    80005a66:	fb040513          	addi	a0,s0,-80
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	6c2080e7          	jalr	1730(ra) # 8000412c <namecmp>
    80005a72:	14050a63          	beqz	a0,80005bc6 <sys_unlink+0x1b0>
    80005a76:	00003597          	auipc	a1,0x3
    80005a7a:	d9258593          	addi	a1,a1,-622 # 80008808 <syscalls+0x300>
    80005a7e:	fb040513          	addi	a0,s0,-80
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	6aa080e7          	jalr	1706(ra) # 8000412c <namecmp>
    80005a8a:	12050e63          	beqz	a0,80005bc6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a8e:	f2c40613          	addi	a2,s0,-212
    80005a92:	fb040593          	addi	a1,s0,-80
    80005a96:	8526                	mv	a0,s1
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	6ae080e7          	jalr	1710(ra) # 80004146 <dirlookup>
    80005aa0:	892a                	mv	s2,a0
    80005aa2:	12050263          	beqz	a0,80005bc6 <sys_unlink+0x1b0>
  ilock(ip);
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	1bc080e7          	jalr	444(ra) # 80003c62 <ilock>
  if(ip->nlink < 1)
    80005aae:	04a91783          	lh	a5,74(s2)
    80005ab2:	08f05263          	blez	a5,80005b36 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ab6:	04491703          	lh	a4,68(s2)
    80005aba:	4785                	li	a5,1
    80005abc:	08f70563          	beq	a4,a5,80005b46 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ac0:	4641                	li	a2,16
    80005ac2:	4581                	li	a1,0
    80005ac4:	fc040513          	addi	a0,s0,-64
    80005ac8:	ffffb097          	auipc	ra,0xffffb
    80005acc:	204080e7          	jalr	516(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ad0:	4741                	li	a4,16
    80005ad2:	f2c42683          	lw	a3,-212(s0)
    80005ad6:	fc040613          	addi	a2,s0,-64
    80005ada:	4581                	li	a1,0
    80005adc:	8526                	mv	a0,s1
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	530080e7          	jalr	1328(ra) # 8000400e <writei>
    80005ae6:	47c1                	li	a5,16
    80005ae8:	0af51563          	bne	a0,a5,80005b92 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005aec:	04491703          	lh	a4,68(s2)
    80005af0:	4785                	li	a5,1
    80005af2:	0af70863          	beq	a4,a5,80005ba2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005af6:	8526                	mv	a0,s1
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	3cc080e7          	jalr	972(ra) # 80003ec4 <iunlockput>
  ip->nlink--;
    80005b00:	04a95783          	lhu	a5,74(s2)
    80005b04:	37fd                	addiw	a5,a5,-1
    80005b06:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b0a:	854a                	mv	a0,s2
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	08a080e7          	jalr	138(ra) # 80003b96 <iupdate>
  iunlockput(ip);
    80005b14:	854a                	mv	a0,s2
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	3ae080e7          	jalr	942(ra) # 80003ec4 <iunlockput>
  end_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	b9e080e7          	jalr	-1122(ra) # 800046bc <end_op>
  return 0;
    80005b26:	4501                	li	a0,0
    80005b28:	a84d                	j	80005bda <sys_unlink+0x1c4>
    end_op();
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	b92080e7          	jalr	-1134(ra) # 800046bc <end_op>
    return -1;
    80005b32:	557d                	li	a0,-1
    80005b34:	a05d                	j	80005bda <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b36:	00003517          	auipc	a0,0x3
    80005b3a:	cfa50513          	addi	a0,a0,-774 # 80008830 <syscalls+0x328>
    80005b3e:	ffffb097          	auipc	ra,0xffffb
    80005b42:	9fc080e7          	jalr	-1540(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b46:	04c92703          	lw	a4,76(s2)
    80005b4a:	02000793          	li	a5,32
    80005b4e:	f6e7f9e3          	bgeu	a5,a4,80005ac0 <sys_unlink+0xaa>
    80005b52:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b56:	4741                	li	a4,16
    80005b58:	86ce                	mv	a3,s3
    80005b5a:	f1840613          	addi	a2,s0,-232
    80005b5e:	4581                	li	a1,0
    80005b60:	854a                	mv	a0,s2
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	3b4080e7          	jalr	948(ra) # 80003f16 <readi>
    80005b6a:	47c1                	li	a5,16
    80005b6c:	00f51b63          	bne	a0,a5,80005b82 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b70:	f1845783          	lhu	a5,-232(s0)
    80005b74:	e7a1                	bnez	a5,80005bbc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b76:	29c1                	addiw	s3,s3,16
    80005b78:	04c92783          	lw	a5,76(s2)
    80005b7c:	fcf9ede3          	bltu	s3,a5,80005b56 <sys_unlink+0x140>
    80005b80:	b781                	j	80005ac0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b82:	00003517          	auipc	a0,0x3
    80005b86:	cc650513          	addi	a0,a0,-826 # 80008848 <syscalls+0x340>
    80005b8a:	ffffb097          	auipc	ra,0xffffb
    80005b8e:	9b0080e7          	jalr	-1616(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005b92:	00003517          	auipc	a0,0x3
    80005b96:	cce50513          	addi	a0,a0,-818 # 80008860 <syscalls+0x358>
    80005b9a:	ffffb097          	auipc	ra,0xffffb
    80005b9e:	9a0080e7          	jalr	-1632(ra) # 8000053a <panic>
    dp->nlink--;
    80005ba2:	04a4d783          	lhu	a5,74(s1)
    80005ba6:	37fd                	addiw	a5,a5,-1
    80005ba8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bac:	8526                	mv	a0,s1
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	fe8080e7          	jalr	-24(ra) # 80003b96 <iupdate>
    80005bb6:	b781                	j	80005af6 <sys_unlink+0xe0>
    return -1;
    80005bb8:	557d                	li	a0,-1
    80005bba:	a005                	j	80005bda <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bbc:	854a                	mv	a0,s2
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	306080e7          	jalr	774(ra) # 80003ec4 <iunlockput>
  iunlockput(dp);
    80005bc6:	8526                	mv	a0,s1
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	2fc080e7          	jalr	764(ra) # 80003ec4 <iunlockput>
  end_op();
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	aec080e7          	jalr	-1300(ra) # 800046bc <end_op>
  return -1;
    80005bd8:	557d                	li	a0,-1
}
    80005bda:	70ae                	ld	ra,232(sp)
    80005bdc:	740e                	ld	s0,224(sp)
    80005bde:	64ee                	ld	s1,216(sp)
    80005be0:	694e                	ld	s2,208(sp)
    80005be2:	69ae                	ld	s3,200(sp)
    80005be4:	616d                	addi	sp,sp,240
    80005be6:	8082                	ret

0000000080005be8 <sys_open>:

uint64
sys_open(void)
{
    80005be8:	7131                	addi	sp,sp,-192
    80005bea:	fd06                	sd	ra,184(sp)
    80005bec:	f922                	sd	s0,176(sp)
    80005bee:	f526                	sd	s1,168(sp)
    80005bf0:	f14a                	sd	s2,160(sp)
    80005bf2:	ed4e                	sd	s3,152(sp)
    80005bf4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005bf6:	08000613          	li	a2,128
    80005bfa:	f5040593          	addi	a1,s0,-176
    80005bfe:	4501                	li	a0,0
    80005c00:	ffffd097          	auipc	ra,0xffffd
    80005c04:	38e080e7          	jalr	910(ra) # 80002f8e <argstr>
    return -1;
    80005c08:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c0a:	0c054163          	bltz	a0,80005ccc <sys_open+0xe4>
    80005c0e:	f4c40593          	addi	a1,s0,-180
    80005c12:	4505                	li	a0,1
    80005c14:	ffffd097          	auipc	ra,0xffffd
    80005c18:	336080e7          	jalr	822(ra) # 80002f4a <argint>
    80005c1c:	0a054863          	bltz	a0,80005ccc <sys_open+0xe4>

  begin_op();
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	a1e080e7          	jalr	-1506(ra) # 8000463e <begin_op>

  if(omode & O_CREATE){
    80005c28:	f4c42783          	lw	a5,-180(s0)
    80005c2c:	2007f793          	andi	a5,a5,512
    80005c30:	cbdd                	beqz	a5,80005ce6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c32:	4681                	li	a3,0
    80005c34:	4601                	li	a2,0
    80005c36:	4589                	li	a1,2
    80005c38:	f5040513          	addi	a0,s0,-176
    80005c3c:	00000097          	auipc	ra,0x0
    80005c40:	970080e7          	jalr	-1680(ra) # 800055ac <create>
    80005c44:	892a                	mv	s2,a0
    if(ip == 0){
    80005c46:	c959                	beqz	a0,80005cdc <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c48:	04491703          	lh	a4,68(s2)
    80005c4c:	478d                	li	a5,3
    80005c4e:	00f71763          	bne	a4,a5,80005c5c <sys_open+0x74>
    80005c52:	04695703          	lhu	a4,70(s2)
    80005c56:	47a5                	li	a5,9
    80005c58:	0ce7ec63          	bltu	a5,a4,80005d30 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	dee080e7          	jalr	-530(ra) # 80004a4a <filealloc>
    80005c64:	89aa                	mv	s3,a0
    80005c66:	10050263          	beqz	a0,80005d6a <sys_open+0x182>
    80005c6a:	00000097          	auipc	ra,0x0
    80005c6e:	900080e7          	jalr	-1792(ra) # 8000556a <fdalloc>
    80005c72:	84aa                	mv	s1,a0
    80005c74:	0e054663          	bltz	a0,80005d60 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c78:	04491703          	lh	a4,68(s2)
    80005c7c:	478d                	li	a5,3
    80005c7e:	0cf70463          	beq	a4,a5,80005d46 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c82:	4789                	li	a5,2
    80005c84:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c88:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c8c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c90:	f4c42783          	lw	a5,-180(s0)
    80005c94:	0017c713          	xori	a4,a5,1
    80005c98:	8b05                	andi	a4,a4,1
    80005c9a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c9e:	0037f713          	andi	a4,a5,3
    80005ca2:	00e03733          	snez	a4,a4
    80005ca6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005caa:	4007f793          	andi	a5,a5,1024
    80005cae:	c791                	beqz	a5,80005cba <sys_open+0xd2>
    80005cb0:	04491703          	lh	a4,68(s2)
    80005cb4:	4789                	li	a5,2
    80005cb6:	08f70f63          	beq	a4,a5,80005d54 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cba:	854a                	mv	a0,s2
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	068080e7          	jalr	104(ra) # 80003d24 <iunlock>
  end_op();
    80005cc4:	fffff097          	auipc	ra,0xfffff
    80005cc8:	9f8080e7          	jalr	-1544(ra) # 800046bc <end_op>

  return fd;
}
    80005ccc:	8526                	mv	a0,s1
    80005cce:	70ea                	ld	ra,184(sp)
    80005cd0:	744a                	ld	s0,176(sp)
    80005cd2:	74aa                	ld	s1,168(sp)
    80005cd4:	790a                	ld	s2,160(sp)
    80005cd6:	69ea                	ld	s3,152(sp)
    80005cd8:	6129                	addi	sp,sp,192
    80005cda:	8082                	ret
      end_op();
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	9e0080e7          	jalr	-1568(ra) # 800046bc <end_op>
      return -1;
    80005ce4:	b7e5                	j	80005ccc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ce6:	f5040513          	addi	a0,s0,-176
    80005cea:	ffffe097          	auipc	ra,0xffffe
    80005cee:	734080e7          	jalr	1844(ra) # 8000441e <namei>
    80005cf2:	892a                	mv	s2,a0
    80005cf4:	c905                	beqz	a0,80005d24 <sys_open+0x13c>
    ilock(ip);
    80005cf6:	ffffe097          	auipc	ra,0xffffe
    80005cfa:	f6c080e7          	jalr	-148(ra) # 80003c62 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005cfe:	04491703          	lh	a4,68(s2)
    80005d02:	4785                	li	a5,1
    80005d04:	f4f712e3          	bne	a4,a5,80005c48 <sys_open+0x60>
    80005d08:	f4c42783          	lw	a5,-180(s0)
    80005d0c:	dba1                	beqz	a5,80005c5c <sys_open+0x74>
      iunlockput(ip);
    80005d0e:	854a                	mv	a0,s2
    80005d10:	ffffe097          	auipc	ra,0xffffe
    80005d14:	1b4080e7          	jalr	436(ra) # 80003ec4 <iunlockput>
      end_op();
    80005d18:	fffff097          	auipc	ra,0xfffff
    80005d1c:	9a4080e7          	jalr	-1628(ra) # 800046bc <end_op>
      return -1;
    80005d20:	54fd                	li	s1,-1
    80005d22:	b76d                	j	80005ccc <sys_open+0xe4>
      end_op();
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	998080e7          	jalr	-1640(ra) # 800046bc <end_op>
      return -1;
    80005d2c:	54fd                	li	s1,-1
    80005d2e:	bf79                	j	80005ccc <sys_open+0xe4>
    iunlockput(ip);
    80005d30:	854a                	mv	a0,s2
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	192080e7          	jalr	402(ra) # 80003ec4 <iunlockput>
    end_op();
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	982080e7          	jalr	-1662(ra) # 800046bc <end_op>
    return -1;
    80005d42:	54fd                	li	s1,-1
    80005d44:	b761                	j	80005ccc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d46:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d4a:	04691783          	lh	a5,70(s2)
    80005d4e:	02f99223          	sh	a5,36(s3)
    80005d52:	bf2d                	j	80005c8c <sys_open+0xa4>
    itrunc(ip);
    80005d54:	854a                	mv	a0,s2
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	01a080e7          	jalr	26(ra) # 80003d70 <itrunc>
    80005d5e:	bfb1                	j	80005cba <sys_open+0xd2>
      fileclose(f);
    80005d60:	854e                	mv	a0,s3
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	da4080e7          	jalr	-604(ra) # 80004b06 <fileclose>
    iunlockput(ip);
    80005d6a:	854a                	mv	a0,s2
    80005d6c:	ffffe097          	auipc	ra,0xffffe
    80005d70:	158080e7          	jalr	344(ra) # 80003ec4 <iunlockput>
    end_op();
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	948080e7          	jalr	-1720(ra) # 800046bc <end_op>
    return -1;
    80005d7c:	54fd                	li	s1,-1
    80005d7e:	b7b9                	j	80005ccc <sys_open+0xe4>

0000000080005d80 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d80:	7175                	addi	sp,sp,-144
    80005d82:	e506                	sd	ra,136(sp)
    80005d84:	e122                	sd	s0,128(sp)
    80005d86:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d88:	fffff097          	auipc	ra,0xfffff
    80005d8c:	8b6080e7          	jalr	-1866(ra) # 8000463e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d90:	08000613          	li	a2,128
    80005d94:	f7040593          	addi	a1,s0,-144
    80005d98:	4501                	li	a0,0
    80005d9a:	ffffd097          	auipc	ra,0xffffd
    80005d9e:	1f4080e7          	jalr	500(ra) # 80002f8e <argstr>
    80005da2:	02054963          	bltz	a0,80005dd4 <sys_mkdir+0x54>
    80005da6:	4681                	li	a3,0
    80005da8:	4601                	li	a2,0
    80005daa:	4585                	li	a1,1
    80005dac:	f7040513          	addi	a0,s0,-144
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	7fc080e7          	jalr	2044(ra) # 800055ac <create>
    80005db8:	cd11                	beqz	a0,80005dd4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dba:	ffffe097          	auipc	ra,0xffffe
    80005dbe:	10a080e7          	jalr	266(ra) # 80003ec4 <iunlockput>
  end_op();
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	8fa080e7          	jalr	-1798(ra) # 800046bc <end_op>
  return 0;
    80005dca:	4501                	li	a0,0
}
    80005dcc:	60aa                	ld	ra,136(sp)
    80005dce:	640a                	ld	s0,128(sp)
    80005dd0:	6149                	addi	sp,sp,144
    80005dd2:	8082                	ret
    end_op();
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	8e8080e7          	jalr	-1816(ra) # 800046bc <end_op>
    return -1;
    80005ddc:	557d                	li	a0,-1
    80005dde:	b7fd                	j	80005dcc <sys_mkdir+0x4c>

0000000080005de0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005de0:	7135                	addi	sp,sp,-160
    80005de2:	ed06                	sd	ra,152(sp)
    80005de4:	e922                	sd	s0,144(sp)
    80005de6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005de8:	fffff097          	auipc	ra,0xfffff
    80005dec:	856080e7          	jalr	-1962(ra) # 8000463e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005df0:	08000613          	li	a2,128
    80005df4:	f7040593          	addi	a1,s0,-144
    80005df8:	4501                	li	a0,0
    80005dfa:	ffffd097          	auipc	ra,0xffffd
    80005dfe:	194080e7          	jalr	404(ra) # 80002f8e <argstr>
    80005e02:	04054a63          	bltz	a0,80005e56 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e06:	f6c40593          	addi	a1,s0,-148
    80005e0a:	4505                	li	a0,1
    80005e0c:	ffffd097          	auipc	ra,0xffffd
    80005e10:	13e080e7          	jalr	318(ra) # 80002f4a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e14:	04054163          	bltz	a0,80005e56 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e18:	f6840593          	addi	a1,s0,-152
    80005e1c:	4509                	li	a0,2
    80005e1e:	ffffd097          	auipc	ra,0xffffd
    80005e22:	12c080e7          	jalr	300(ra) # 80002f4a <argint>
     argint(1, &major) < 0 ||
    80005e26:	02054863          	bltz	a0,80005e56 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e2a:	f6841683          	lh	a3,-152(s0)
    80005e2e:	f6c41603          	lh	a2,-148(s0)
    80005e32:	458d                	li	a1,3
    80005e34:	f7040513          	addi	a0,s0,-144
    80005e38:	fffff097          	auipc	ra,0xfffff
    80005e3c:	774080e7          	jalr	1908(ra) # 800055ac <create>
     argint(2, &minor) < 0 ||
    80005e40:	c919                	beqz	a0,80005e56 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	082080e7          	jalr	130(ra) # 80003ec4 <iunlockput>
  end_op();
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	872080e7          	jalr	-1934(ra) # 800046bc <end_op>
  return 0;
    80005e52:	4501                	li	a0,0
    80005e54:	a031                	j	80005e60 <sys_mknod+0x80>
    end_op();
    80005e56:	fffff097          	auipc	ra,0xfffff
    80005e5a:	866080e7          	jalr	-1946(ra) # 800046bc <end_op>
    return -1;
    80005e5e:	557d                	li	a0,-1
}
    80005e60:	60ea                	ld	ra,152(sp)
    80005e62:	644a                	ld	s0,144(sp)
    80005e64:	610d                	addi	sp,sp,160
    80005e66:	8082                	ret

0000000080005e68 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e68:	7135                	addi	sp,sp,-160
    80005e6a:	ed06                	sd	ra,152(sp)
    80005e6c:	e922                	sd	s0,144(sp)
    80005e6e:	e526                	sd	s1,136(sp)
    80005e70:	e14a                	sd	s2,128(sp)
    80005e72:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e74:	ffffc097          	auipc	ra,0xffffc
    80005e78:	b22080e7          	jalr	-1246(ra) # 80001996 <myproc>
    80005e7c:	892a                	mv	s2,a0
  
  begin_op();
    80005e7e:	ffffe097          	auipc	ra,0xffffe
    80005e82:	7c0080e7          	jalr	1984(ra) # 8000463e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e86:	08000613          	li	a2,128
    80005e8a:	f6040593          	addi	a1,s0,-160
    80005e8e:	4501                	li	a0,0
    80005e90:	ffffd097          	auipc	ra,0xffffd
    80005e94:	0fe080e7          	jalr	254(ra) # 80002f8e <argstr>
    80005e98:	04054b63          	bltz	a0,80005eee <sys_chdir+0x86>
    80005e9c:	f6040513          	addi	a0,s0,-160
    80005ea0:	ffffe097          	auipc	ra,0xffffe
    80005ea4:	57e080e7          	jalr	1406(ra) # 8000441e <namei>
    80005ea8:	84aa                	mv	s1,a0
    80005eaa:	c131                	beqz	a0,80005eee <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005eac:	ffffe097          	auipc	ra,0xffffe
    80005eb0:	db6080e7          	jalr	-586(ra) # 80003c62 <ilock>
  if(ip->type != T_DIR){
    80005eb4:	04449703          	lh	a4,68(s1)
    80005eb8:	4785                	li	a5,1
    80005eba:	04f71063          	bne	a4,a5,80005efa <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ebe:	8526                	mv	a0,s1
    80005ec0:	ffffe097          	auipc	ra,0xffffe
    80005ec4:	e64080e7          	jalr	-412(ra) # 80003d24 <iunlock>
  iput(p->cwd);
    80005ec8:	15093503          	ld	a0,336(s2)
    80005ecc:	ffffe097          	auipc	ra,0xffffe
    80005ed0:	f50080e7          	jalr	-176(ra) # 80003e1c <iput>
  end_op();
    80005ed4:	ffffe097          	auipc	ra,0xffffe
    80005ed8:	7e8080e7          	jalr	2024(ra) # 800046bc <end_op>
  p->cwd = ip;
    80005edc:	14993823          	sd	s1,336(s2)
  return 0;
    80005ee0:	4501                	li	a0,0
}
    80005ee2:	60ea                	ld	ra,152(sp)
    80005ee4:	644a                	ld	s0,144(sp)
    80005ee6:	64aa                	ld	s1,136(sp)
    80005ee8:	690a                	ld	s2,128(sp)
    80005eea:	610d                	addi	sp,sp,160
    80005eec:	8082                	ret
    end_op();
    80005eee:	ffffe097          	auipc	ra,0xffffe
    80005ef2:	7ce080e7          	jalr	1998(ra) # 800046bc <end_op>
    return -1;
    80005ef6:	557d                	li	a0,-1
    80005ef8:	b7ed                	j	80005ee2 <sys_chdir+0x7a>
    iunlockput(ip);
    80005efa:	8526                	mv	a0,s1
    80005efc:	ffffe097          	auipc	ra,0xffffe
    80005f00:	fc8080e7          	jalr	-56(ra) # 80003ec4 <iunlockput>
    end_op();
    80005f04:	ffffe097          	auipc	ra,0xffffe
    80005f08:	7b8080e7          	jalr	1976(ra) # 800046bc <end_op>
    return -1;
    80005f0c:	557d                	li	a0,-1
    80005f0e:	bfd1                	j	80005ee2 <sys_chdir+0x7a>

0000000080005f10 <sys_exec>:

uint64
sys_exec(void)
{
    80005f10:	7145                	addi	sp,sp,-464
    80005f12:	e786                	sd	ra,456(sp)
    80005f14:	e3a2                	sd	s0,448(sp)
    80005f16:	ff26                	sd	s1,440(sp)
    80005f18:	fb4a                	sd	s2,432(sp)
    80005f1a:	f74e                	sd	s3,424(sp)
    80005f1c:	f352                	sd	s4,416(sp)
    80005f1e:	ef56                	sd	s5,408(sp)
    80005f20:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f22:	08000613          	li	a2,128
    80005f26:	f4040593          	addi	a1,s0,-192
    80005f2a:	4501                	li	a0,0
    80005f2c:	ffffd097          	auipc	ra,0xffffd
    80005f30:	062080e7          	jalr	98(ra) # 80002f8e <argstr>
    return -1;
    80005f34:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f36:	0c054b63          	bltz	a0,8000600c <sys_exec+0xfc>
    80005f3a:	e3840593          	addi	a1,s0,-456
    80005f3e:	4505                	li	a0,1
    80005f40:	ffffd097          	auipc	ra,0xffffd
    80005f44:	02c080e7          	jalr	44(ra) # 80002f6c <argaddr>
    80005f48:	0c054263          	bltz	a0,8000600c <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005f4c:	10000613          	li	a2,256
    80005f50:	4581                	li	a1,0
    80005f52:	e4040513          	addi	a0,s0,-448
    80005f56:	ffffb097          	auipc	ra,0xffffb
    80005f5a:	d76080e7          	jalr	-650(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f5e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f62:	89a6                	mv	s3,s1
    80005f64:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f66:	02000a13          	li	s4,32
    80005f6a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f6e:	00391513          	slli	a0,s2,0x3
    80005f72:	e3040593          	addi	a1,s0,-464
    80005f76:	e3843783          	ld	a5,-456(s0)
    80005f7a:	953e                	add	a0,a0,a5
    80005f7c:	ffffd097          	auipc	ra,0xffffd
    80005f80:	f34080e7          	jalr	-204(ra) # 80002eb0 <fetchaddr>
    80005f84:	02054a63          	bltz	a0,80005fb8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f88:	e3043783          	ld	a5,-464(s0)
    80005f8c:	c3b9                	beqz	a5,80005fd2 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f8e:	ffffb097          	auipc	ra,0xffffb
    80005f92:	b52080e7          	jalr	-1198(ra) # 80000ae0 <kalloc>
    80005f96:	85aa                	mv	a1,a0
    80005f98:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f9c:	cd11                	beqz	a0,80005fb8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f9e:	6605                	lui	a2,0x1
    80005fa0:	e3043503          	ld	a0,-464(s0)
    80005fa4:	ffffd097          	auipc	ra,0xffffd
    80005fa8:	f5e080e7          	jalr	-162(ra) # 80002f02 <fetchstr>
    80005fac:	00054663          	bltz	a0,80005fb8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005fb0:	0905                	addi	s2,s2,1
    80005fb2:	09a1                	addi	s3,s3,8
    80005fb4:	fb491be3          	bne	s2,s4,80005f6a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fb8:	f4040913          	addi	s2,s0,-192
    80005fbc:	6088                	ld	a0,0(s1)
    80005fbe:	c531                	beqz	a0,8000600a <sys_exec+0xfa>
    kfree(argv[i]);
    80005fc0:	ffffb097          	auipc	ra,0xffffb
    80005fc4:	a22080e7          	jalr	-1502(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fc8:	04a1                	addi	s1,s1,8
    80005fca:	ff2499e3          	bne	s1,s2,80005fbc <sys_exec+0xac>
  return -1;
    80005fce:	597d                	li	s2,-1
    80005fd0:	a835                	j	8000600c <sys_exec+0xfc>
      argv[i] = 0;
    80005fd2:	0a8e                	slli	s5,s5,0x3
    80005fd4:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005fd8:	00878ab3          	add	s5,a5,s0
    80005fdc:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fe0:	e4040593          	addi	a1,s0,-448
    80005fe4:	f4040513          	addi	a0,s0,-192
    80005fe8:	fffff097          	auipc	ra,0xfffff
    80005fec:	172080e7          	jalr	370(ra) # 8000515a <exec>
    80005ff0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ff2:	f4040993          	addi	s3,s0,-192
    80005ff6:	6088                	ld	a0,0(s1)
    80005ff8:	c911                	beqz	a0,8000600c <sys_exec+0xfc>
    kfree(argv[i]);
    80005ffa:	ffffb097          	auipc	ra,0xffffb
    80005ffe:	9e8080e7          	jalr	-1560(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006002:	04a1                	addi	s1,s1,8
    80006004:	ff3499e3          	bne	s1,s3,80005ff6 <sys_exec+0xe6>
    80006008:	a011                	j	8000600c <sys_exec+0xfc>
  return -1;
    8000600a:	597d                	li	s2,-1
}
    8000600c:	854a                	mv	a0,s2
    8000600e:	60be                	ld	ra,456(sp)
    80006010:	641e                	ld	s0,448(sp)
    80006012:	74fa                	ld	s1,440(sp)
    80006014:	795a                	ld	s2,432(sp)
    80006016:	79ba                	ld	s3,424(sp)
    80006018:	7a1a                	ld	s4,416(sp)
    8000601a:	6afa                	ld	s5,408(sp)
    8000601c:	6179                	addi	sp,sp,464
    8000601e:	8082                	ret

0000000080006020 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006020:	7139                	addi	sp,sp,-64
    80006022:	fc06                	sd	ra,56(sp)
    80006024:	f822                	sd	s0,48(sp)
    80006026:	f426                	sd	s1,40(sp)
    80006028:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000602a:	ffffc097          	auipc	ra,0xffffc
    8000602e:	96c080e7          	jalr	-1684(ra) # 80001996 <myproc>
    80006032:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006034:	fd840593          	addi	a1,s0,-40
    80006038:	4501                	li	a0,0
    8000603a:	ffffd097          	auipc	ra,0xffffd
    8000603e:	f32080e7          	jalr	-206(ra) # 80002f6c <argaddr>
    return -1;
    80006042:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006044:	0e054063          	bltz	a0,80006124 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006048:	fc840593          	addi	a1,s0,-56
    8000604c:	fd040513          	addi	a0,s0,-48
    80006050:	fffff097          	auipc	ra,0xfffff
    80006054:	de6080e7          	jalr	-538(ra) # 80004e36 <pipealloc>
    return -1;
    80006058:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000605a:	0c054563          	bltz	a0,80006124 <sys_pipe+0x104>
  fd0 = -1;
    8000605e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006062:	fd043503          	ld	a0,-48(s0)
    80006066:	fffff097          	auipc	ra,0xfffff
    8000606a:	504080e7          	jalr	1284(ra) # 8000556a <fdalloc>
    8000606e:	fca42223          	sw	a0,-60(s0)
    80006072:	08054c63          	bltz	a0,8000610a <sys_pipe+0xea>
    80006076:	fc843503          	ld	a0,-56(s0)
    8000607a:	fffff097          	auipc	ra,0xfffff
    8000607e:	4f0080e7          	jalr	1264(ra) # 8000556a <fdalloc>
    80006082:	fca42023          	sw	a0,-64(s0)
    80006086:	06054963          	bltz	a0,800060f8 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000608a:	4691                	li	a3,4
    8000608c:	fc440613          	addi	a2,s0,-60
    80006090:	fd843583          	ld	a1,-40(s0)
    80006094:	68a8                	ld	a0,80(s1)
    80006096:	ffffb097          	auipc	ra,0xffffb
    8000609a:	5c4080e7          	jalr	1476(ra) # 8000165a <copyout>
    8000609e:	02054063          	bltz	a0,800060be <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060a2:	4691                	li	a3,4
    800060a4:	fc040613          	addi	a2,s0,-64
    800060a8:	fd843583          	ld	a1,-40(s0)
    800060ac:	0591                	addi	a1,a1,4
    800060ae:	68a8                	ld	a0,80(s1)
    800060b0:	ffffb097          	auipc	ra,0xffffb
    800060b4:	5aa080e7          	jalr	1450(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060b8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060ba:	06055563          	bgez	a0,80006124 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800060be:	fc442783          	lw	a5,-60(s0)
    800060c2:	07e9                	addi	a5,a5,26
    800060c4:	078e                	slli	a5,a5,0x3
    800060c6:	97a6                	add	a5,a5,s1
    800060c8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060cc:	fc042783          	lw	a5,-64(s0)
    800060d0:	07e9                	addi	a5,a5,26
    800060d2:	078e                	slli	a5,a5,0x3
    800060d4:	00f48533          	add	a0,s1,a5
    800060d8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060dc:	fd043503          	ld	a0,-48(s0)
    800060e0:	fffff097          	auipc	ra,0xfffff
    800060e4:	a26080e7          	jalr	-1498(ra) # 80004b06 <fileclose>
    fileclose(wf);
    800060e8:	fc843503          	ld	a0,-56(s0)
    800060ec:	fffff097          	auipc	ra,0xfffff
    800060f0:	a1a080e7          	jalr	-1510(ra) # 80004b06 <fileclose>
    return -1;
    800060f4:	57fd                	li	a5,-1
    800060f6:	a03d                	j	80006124 <sys_pipe+0x104>
    if(fd0 >= 0)
    800060f8:	fc442783          	lw	a5,-60(s0)
    800060fc:	0007c763          	bltz	a5,8000610a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006100:	07e9                	addi	a5,a5,26
    80006102:	078e                	slli	a5,a5,0x3
    80006104:	97a6                	add	a5,a5,s1
    80006106:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000610a:	fd043503          	ld	a0,-48(s0)
    8000610e:	fffff097          	auipc	ra,0xfffff
    80006112:	9f8080e7          	jalr	-1544(ra) # 80004b06 <fileclose>
    fileclose(wf);
    80006116:	fc843503          	ld	a0,-56(s0)
    8000611a:	fffff097          	auipc	ra,0xfffff
    8000611e:	9ec080e7          	jalr	-1556(ra) # 80004b06 <fileclose>
    return -1;
    80006122:	57fd                	li	a5,-1
}
    80006124:	853e                	mv	a0,a5
    80006126:	70e2                	ld	ra,56(sp)
    80006128:	7442                	ld	s0,48(sp)
    8000612a:	74a2                	ld	s1,40(sp)
    8000612c:	6121                	addi	sp,sp,64
    8000612e:	8082                	ret

0000000080006130 <kernelvec>:
    80006130:	7111                	addi	sp,sp,-256
    80006132:	e006                	sd	ra,0(sp)
    80006134:	e40a                	sd	sp,8(sp)
    80006136:	e80e                	sd	gp,16(sp)
    80006138:	ec12                	sd	tp,24(sp)
    8000613a:	f016                	sd	t0,32(sp)
    8000613c:	f41a                	sd	t1,40(sp)
    8000613e:	f81e                	sd	t2,48(sp)
    80006140:	fc22                	sd	s0,56(sp)
    80006142:	e0a6                	sd	s1,64(sp)
    80006144:	e4aa                	sd	a0,72(sp)
    80006146:	e8ae                	sd	a1,80(sp)
    80006148:	ecb2                	sd	a2,88(sp)
    8000614a:	f0b6                	sd	a3,96(sp)
    8000614c:	f4ba                	sd	a4,104(sp)
    8000614e:	f8be                	sd	a5,112(sp)
    80006150:	fcc2                	sd	a6,120(sp)
    80006152:	e146                	sd	a7,128(sp)
    80006154:	e54a                	sd	s2,136(sp)
    80006156:	e94e                	sd	s3,144(sp)
    80006158:	ed52                	sd	s4,152(sp)
    8000615a:	f156                	sd	s5,160(sp)
    8000615c:	f55a                	sd	s6,168(sp)
    8000615e:	f95e                	sd	s7,176(sp)
    80006160:	fd62                	sd	s8,184(sp)
    80006162:	e1e6                	sd	s9,192(sp)
    80006164:	e5ea                	sd	s10,200(sp)
    80006166:	e9ee                	sd	s11,208(sp)
    80006168:	edf2                	sd	t3,216(sp)
    8000616a:	f1f6                	sd	t4,224(sp)
    8000616c:	f5fa                	sd	t5,232(sp)
    8000616e:	f9fe                	sd	t6,240(sp)
    80006170:	c0dfc0ef          	jal	ra,80002d7c <kerneltrap>
    80006174:	6082                	ld	ra,0(sp)
    80006176:	6122                	ld	sp,8(sp)
    80006178:	61c2                	ld	gp,16(sp)
    8000617a:	7282                	ld	t0,32(sp)
    8000617c:	7322                	ld	t1,40(sp)
    8000617e:	73c2                	ld	t2,48(sp)
    80006180:	7462                	ld	s0,56(sp)
    80006182:	6486                	ld	s1,64(sp)
    80006184:	6526                	ld	a0,72(sp)
    80006186:	65c6                	ld	a1,80(sp)
    80006188:	6666                	ld	a2,88(sp)
    8000618a:	7686                	ld	a3,96(sp)
    8000618c:	7726                	ld	a4,104(sp)
    8000618e:	77c6                	ld	a5,112(sp)
    80006190:	7866                	ld	a6,120(sp)
    80006192:	688a                	ld	a7,128(sp)
    80006194:	692a                	ld	s2,136(sp)
    80006196:	69ca                	ld	s3,144(sp)
    80006198:	6a6a                	ld	s4,152(sp)
    8000619a:	7a8a                	ld	s5,160(sp)
    8000619c:	7b2a                	ld	s6,168(sp)
    8000619e:	7bca                	ld	s7,176(sp)
    800061a0:	7c6a                	ld	s8,184(sp)
    800061a2:	6c8e                	ld	s9,192(sp)
    800061a4:	6d2e                	ld	s10,200(sp)
    800061a6:	6dce                	ld	s11,208(sp)
    800061a8:	6e6e                	ld	t3,216(sp)
    800061aa:	7e8e                	ld	t4,224(sp)
    800061ac:	7f2e                	ld	t5,232(sp)
    800061ae:	7fce                	ld	t6,240(sp)
    800061b0:	6111                	addi	sp,sp,256
    800061b2:	10200073          	sret
    800061b6:	00000013          	nop
    800061ba:	00000013          	nop
    800061be:	0001                	nop

00000000800061c0 <timervec>:
    800061c0:	34051573          	csrrw	a0,mscratch,a0
    800061c4:	e10c                	sd	a1,0(a0)
    800061c6:	e510                	sd	a2,8(a0)
    800061c8:	e914                	sd	a3,16(a0)
    800061ca:	6d0c                	ld	a1,24(a0)
    800061cc:	7110                	ld	a2,32(a0)
    800061ce:	6194                	ld	a3,0(a1)
    800061d0:	96b2                	add	a3,a3,a2
    800061d2:	e194                	sd	a3,0(a1)
    800061d4:	4589                	li	a1,2
    800061d6:	14459073          	csrw	sip,a1
    800061da:	6914                	ld	a3,16(a0)
    800061dc:	6510                	ld	a2,8(a0)
    800061de:	610c                	ld	a1,0(a0)
    800061e0:	34051573          	csrrw	a0,mscratch,a0
    800061e4:	30200073          	mret
	...

00000000800061ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061ea:	1141                	addi	sp,sp,-16
    800061ec:	e422                	sd	s0,8(sp)
    800061ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061f0:	0c0007b7          	lui	a5,0xc000
    800061f4:	4705                	li	a4,1
    800061f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061f8:	c3d8                	sw	a4,4(a5)
}
    800061fa:	6422                	ld	s0,8(sp)
    800061fc:	0141                	addi	sp,sp,16
    800061fe:	8082                	ret

0000000080006200 <plicinithart>:

void
plicinithart(void)
{
    80006200:	1141                	addi	sp,sp,-16
    80006202:	e406                	sd	ra,8(sp)
    80006204:	e022                	sd	s0,0(sp)
    80006206:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006208:	ffffb097          	auipc	ra,0xffffb
    8000620c:	762080e7          	jalr	1890(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006210:	0085171b          	slliw	a4,a0,0x8
    80006214:	0c0027b7          	lui	a5,0xc002
    80006218:	97ba                	add	a5,a5,a4
    8000621a:	40200713          	li	a4,1026
    8000621e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006222:	00d5151b          	slliw	a0,a0,0xd
    80006226:	0c2017b7          	lui	a5,0xc201
    8000622a:	97aa                	add	a5,a5,a0
    8000622c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006230:	60a2                	ld	ra,8(sp)
    80006232:	6402                	ld	s0,0(sp)
    80006234:	0141                	addi	sp,sp,16
    80006236:	8082                	ret

0000000080006238 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006238:	1141                	addi	sp,sp,-16
    8000623a:	e406                	sd	ra,8(sp)
    8000623c:	e022                	sd	s0,0(sp)
    8000623e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006240:	ffffb097          	auipc	ra,0xffffb
    80006244:	72a080e7          	jalr	1834(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006248:	00d5151b          	slliw	a0,a0,0xd
    8000624c:	0c2017b7          	lui	a5,0xc201
    80006250:	97aa                	add	a5,a5,a0
  return irq;
}
    80006252:	43c8                	lw	a0,4(a5)
    80006254:	60a2                	ld	ra,8(sp)
    80006256:	6402                	ld	s0,0(sp)
    80006258:	0141                	addi	sp,sp,16
    8000625a:	8082                	ret

000000008000625c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000625c:	1101                	addi	sp,sp,-32
    8000625e:	ec06                	sd	ra,24(sp)
    80006260:	e822                	sd	s0,16(sp)
    80006262:	e426                	sd	s1,8(sp)
    80006264:	1000                	addi	s0,sp,32
    80006266:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006268:	ffffb097          	auipc	ra,0xffffb
    8000626c:	702080e7          	jalr	1794(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006270:	00d5151b          	slliw	a0,a0,0xd
    80006274:	0c2017b7          	lui	a5,0xc201
    80006278:	97aa                	add	a5,a5,a0
    8000627a:	c3c4                	sw	s1,4(a5)
}
    8000627c:	60e2                	ld	ra,24(sp)
    8000627e:	6442                	ld	s0,16(sp)
    80006280:	64a2                	ld	s1,8(sp)
    80006282:	6105                	addi	sp,sp,32
    80006284:	8082                	ret

0000000080006286 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006286:	1141                	addi	sp,sp,-16
    80006288:	e406                	sd	ra,8(sp)
    8000628a:	e022                	sd	s0,0(sp)
    8000628c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000628e:	479d                	li	a5,7
    80006290:	06a7c863          	blt	a5,a0,80006300 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006294:	0001d717          	auipc	a4,0x1d
    80006298:	d6c70713          	addi	a4,a4,-660 # 80023000 <disk>
    8000629c:	972a                	add	a4,a4,a0
    8000629e:	6789                	lui	a5,0x2
    800062a0:	97ba                	add	a5,a5,a4
    800062a2:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800062a6:	e7ad                	bnez	a5,80006310 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062a8:	00451793          	slli	a5,a0,0x4
    800062ac:	0001f717          	auipc	a4,0x1f
    800062b0:	d5470713          	addi	a4,a4,-684 # 80025000 <disk+0x2000>
    800062b4:	6314                	ld	a3,0(a4)
    800062b6:	96be                	add	a3,a3,a5
    800062b8:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062bc:	6314                	ld	a3,0(a4)
    800062be:	96be                	add	a3,a3,a5
    800062c0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800062c4:	6314                	ld	a3,0(a4)
    800062c6:	96be                	add	a3,a3,a5
    800062c8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800062cc:	6318                	ld	a4,0(a4)
    800062ce:	97ba                	add	a5,a5,a4
    800062d0:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800062d4:	0001d717          	auipc	a4,0x1d
    800062d8:	d2c70713          	addi	a4,a4,-724 # 80023000 <disk>
    800062dc:	972a                	add	a4,a4,a0
    800062de:	6789                	lui	a5,0x2
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	4705                	li	a4,1
    800062e4:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800062e8:	0001f517          	auipc	a0,0x1f
    800062ec:	d3050513          	addi	a0,a0,-720 # 80025018 <disk+0x2018>
    800062f0:	ffffc097          	auipc	ra,0xffffc
    800062f4:	f1e080e7          	jalr	-226(ra) # 8000220e <wakeup>
}
    800062f8:	60a2                	ld	ra,8(sp)
    800062fa:	6402                	ld	s0,0(sp)
    800062fc:	0141                	addi	sp,sp,16
    800062fe:	8082                	ret
    panic("free_desc 1");
    80006300:	00002517          	auipc	a0,0x2
    80006304:	57050513          	addi	a0,a0,1392 # 80008870 <syscalls+0x368>
    80006308:	ffffa097          	auipc	ra,0xffffa
    8000630c:	232080e7          	jalr	562(ra) # 8000053a <panic>
    panic("free_desc 2");
    80006310:	00002517          	auipc	a0,0x2
    80006314:	57050513          	addi	a0,a0,1392 # 80008880 <syscalls+0x378>
    80006318:	ffffa097          	auipc	ra,0xffffa
    8000631c:	222080e7          	jalr	546(ra) # 8000053a <panic>

0000000080006320 <virtio_disk_init>:
{
    80006320:	1101                	addi	sp,sp,-32
    80006322:	ec06                	sd	ra,24(sp)
    80006324:	e822                	sd	s0,16(sp)
    80006326:	e426                	sd	s1,8(sp)
    80006328:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000632a:	00002597          	auipc	a1,0x2
    8000632e:	56658593          	addi	a1,a1,1382 # 80008890 <syscalls+0x388>
    80006332:	0001f517          	auipc	a0,0x1f
    80006336:	df650513          	addi	a0,a0,-522 # 80025128 <disk+0x2128>
    8000633a:	ffffb097          	auipc	ra,0xffffb
    8000633e:	806080e7          	jalr	-2042(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006342:	100017b7          	lui	a5,0x10001
    80006346:	4398                	lw	a4,0(a5)
    80006348:	2701                	sext.w	a4,a4
    8000634a:	747277b7          	lui	a5,0x74727
    8000634e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006352:	0ef71063          	bne	a4,a5,80006432 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006356:	100017b7          	lui	a5,0x10001
    8000635a:	43dc                	lw	a5,4(a5)
    8000635c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000635e:	4705                	li	a4,1
    80006360:	0ce79963          	bne	a5,a4,80006432 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006364:	100017b7          	lui	a5,0x10001
    80006368:	479c                	lw	a5,8(a5)
    8000636a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000636c:	4709                	li	a4,2
    8000636e:	0ce79263          	bne	a5,a4,80006432 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006372:	100017b7          	lui	a5,0x10001
    80006376:	47d8                	lw	a4,12(a5)
    80006378:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000637a:	554d47b7          	lui	a5,0x554d4
    8000637e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006382:	0af71863          	bne	a4,a5,80006432 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006386:	100017b7          	lui	a5,0x10001
    8000638a:	4705                	li	a4,1
    8000638c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000638e:	470d                	li	a4,3
    80006390:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006392:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006394:	c7ffe6b7          	lui	a3,0xc7ffe
    80006398:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000639c:	8f75                	and	a4,a4,a3
    8000639e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063a0:	472d                	li	a4,11
    800063a2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063a4:	473d                	li	a4,15
    800063a6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800063a8:	6705                	lui	a4,0x1
    800063aa:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063ac:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063b0:	5bdc                	lw	a5,52(a5)
    800063b2:	2781                	sext.w	a5,a5
  if(max == 0)
    800063b4:	c7d9                	beqz	a5,80006442 <virtio_disk_init+0x122>
  if(max < NUM)
    800063b6:	471d                	li	a4,7
    800063b8:	08f77d63          	bgeu	a4,a5,80006452 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063bc:	100014b7          	lui	s1,0x10001
    800063c0:	47a1                	li	a5,8
    800063c2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800063c4:	6609                	lui	a2,0x2
    800063c6:	4581                	li	a1,0
    800063c8:	0001d517          	auipc	a0,0x1d
    800063cc:	c3850513          	addi	a0,a0,-968 # 80023000 <disk>
    800063d0:	ffffb097          	auipc	ra,0xffffb
    800063d4:	8fc080e7          	jalr	-1796(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800063d8:	0001d717          	auipc	a4,0x1d
    800063dc:	c2870713          	addi	a4,a4,-984 # 80023000 <disk>
    800063e0:	00c75793          	srli	a5,a4,0xc
    800063e4:	2781                	sext.w	a5,a5
    800063e6:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800063e8:	0001f797          	auipc	a5,0x1f
    800063ec:	c1878793          	addi	a5,a5,-1000 # 80025000 <disk+0x2000>
    800063f0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800063f2:	0001d717          	auipc	a4,0x1d
    800063f6:	c8e70713          	addi	a4,a4,-882 # 80023080 <disk+0x80>
    800063fa:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800063fc:	0001e717          	auipc	a4,0x1e
    80006400:	c0470713          	addi	a4,a4,-1020 # 80024000 <disk+0x1000>
    80006404:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006406:	4705                	li	a4,1
    80006408:	00e78c23          	sb	a4,24(a5)
    8000640c:	00e78ca3          	sb	a4,25(a5)
    80006410:	00e78d23          	sb	a4,26(a5)
    80006414:	00e78da3          	sb	a4,27(a5)
    80006418:	00e78e23          	sb	a4,28(a5)
    8000641c:	00e78ea3          	sb	a4,29(a5)
    80006420:	00e78f23          	sb	a4,30(a5)
    80006424:	00e78fa3          	sb	a4,31(a5)
}
    80006428:	60e2                	ld	ra,24(sp)
    8000642a:	6442                	ld	s0,16(sp)
    8000642c:	64a2                	ld	s1,8(sp)
    8000642e:	6105                	addi	sp,sp,32
    80006430:	8082                	ret
    panic("could not find virtio disk");
    80006432:	00002517          	auipc	a0,0x2
    80006436:	46e50513          	addi	a0,a0,1134 # 800088a0 <syscalls+0x398>
    8000643a:	ffffa097          	auipc	ra,0xffffa
    8000643e:	100080e7          	jalr	256(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80006442:	00002517          	auipc	a0,0x2
    80006446:	47e50513          	addi	a0,a0,1150 # 800088c0 <syscalls+0x3b8>
    8000644a:	ffffa097          	auipc	ra,0xffffa
    8000644e:	0f0080e7          	jalr	240(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80006452:	00002517          	auipc	a0,0x2
    80006456:	48e50513          	addi	a0,a0,1166 # 800088e0 <syscalls+0x3d8>
    8000645a:	ffffa097          	auipc	ra,0xffffa
    8000645e:	0e0080e7          	jalr	224(ra) # 8000053a <panic>

0000000080006462 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006462:	7119                	addi	sp,sp,-128
    80006464:	fc86                	sd	ra,120(sp)
    80006466:	f8a2                	sd	s0,112(sp)
    80006468:	f4a6                	sd	s1,104(sp)
    8000646a:	f0ca                	sd	s2,96(sp)
    8000646c:	ecce                	sd	s3,88(sp)
    8000646e:	e8d2                	sd	s4,80(sp)
    80006470:	e4d6                	sd	s5,72(sp)
    80006472:	e0da                	sd	s6,64(sp)
    80006474:	fc5e                	sd	s7,56(sp)
    80006476:	f862                	sd	s8,48(sp)
    80006478:	f466                	sd	s9,40(sp)
    8000647a:	f06a                	sd	s10,32(sp)
    8000647c:	ec6e                	sd	s11,24(sp)
    8000647e:	0100                	addi	s0,sp,128
    80006480:	8aaa                	mv	s5,a0
    80006482:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006484:	00c52c83          	lw	s9,12(a0)
    80006488:	001c9c9b          	slliw	s9,s9,0x1
    8000648c:	1c82                	slli	s9,s9,0x20
    8000648e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006492:	0001f517          	auipc	a0,0x1f
    80006496:	c9650513          	addi	a0,a0,-874 # 80025128 <disk+0x2128>
    8000649a:	ffffa097          	auipc	ra,0xffffa
    8000649e:	736080e7          	jalr	1846(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    800064a2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064a4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800064a6:	0001dc17          	auipc	s8,0x1d
    800064aa:	b5ac0c13          	addi	s8,s8,-1190 # 80023000 <disk>
    800064ae:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800064b0:	4b0d                	li	s6,3
    800064b2:	a0ad                	j	8000651c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800064b4:	00fc0733          	add	a4,s8,a5
    800064b8:	975e                	add	a4,a4,s7
    800064ba:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800064be:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800064c0:	0207c563          	bltz	a5,800064ea <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800064c4:	2905                	addiw	s2,s2,1
    800064c6:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    800064c8:	19690c63          	beq	s2,s6,80006660 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    800064cc:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800064ce:	0001f717          	auipc	a4,0x1f
    800064d2:	b4a70713          	addi	a4,a4,-1206 # 80025018 <disk+0x2018>
    800064d6:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800064d8:	00074683          	lbu	a3,0(a4)
    800064dc:	fee1                	bnez	a3,800064b4 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800064de:	2785                	addiw	a5,a5,1
    800064e0:	0705                	addi	a4,a4,1
    800064e2:	fe979be3          	bne	a5,s1,800064d8 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800064e6:	57fd                	li	a5,-1
    800064e8:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800064ea:	01205d63          	blez	s2,80006504 <virtio_disk_rw+0xa2>
    800064ee:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800064f0:	000a2503          	lw	a0,0(s4)
    800064f4:	00000097          	auipc	ra,0x0
    800064f8:	d92080e7          	jalr	-622(ra) # 80006286 <free_desc>
      for(int j = 0; j < i; j++)
    800064fc:	2d85                	addiw	s11,s11,1
    800064fe:	0a11                	addi	s4,s4,4
    80006500:	ff2d98e3          	bne	s11,s2,800064f0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006504:	0001f597          	auipc	a1,0x1f
    80006508:	c2458593          	addi	a1,a1,-988 # 80025128 <disk+0x2128>
    8000650c:	0001f517          	auipc	a0,0x1f
    80006510:	b0c50513          	addi	a0,a0,-1268 # 80025018 <disk+0x2018>
    80006514:	ffffc097          	auipc	ra,0xffffc
    80006518:	b6e080e7          	jalr	-1170(ra) # 80002082 <sleep>
  for(int i = 0; i < 3; i++){
    8000651c:	f8040a13          	addi	s4,s0,-128
{
    80006520:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006522:	894e                	mv	s2,s3
    80006524:	b765                	j	800064cc <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006526:	0001f697          	auipc	a3,0x1f
    8000652a:	ada6b683          	ld	a3,-1318(a3) # 80025000 <disk+0x2000>
    8000652e:	96ba                	add	a3,a3,a4
    80006530:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006534:	0001d817          	auipc	a6,0x1d
    80006538:	acc80813          	addi	a6,a6,-1332 # 80023000 <disk>
    8000653c:	0001f697          	auipc	a3,0x1f
    80006540:	ac468693          	addi	a3,a3,-1340 # 80025000 <disk+0x2000>
    80006544:	6290                	ld	a2,0(a3)
    80006546:	963a                	add	a2,a2,a4
    80006548:	00c65583          	lhu	a1,12(a2)
    8000654c:	0015e593          	ori	a1,a1,1
    80006550:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006554:	f8842603          	lw	a2,-120(s0)
    80006558:	628c                	ld	a1,0(a3)
    8000655a:	972e                	add	a4,a4,a1
    8000655c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006560:	20050593          	addi	a1,a0,512
    80006564:	0592                	slli	a1,a1,0x4
    80006566:	95c2                	add	a1,a1,a6
    80006568:	577d                	li	a4,-1
    8000656a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000656e:	00461713          	slli	a4,a2,0x4
    80006572:	6290                	ld	a2,0(a3)
    80006574:	963a                	add	a2,a2,a4
    80006576:	03078793          	addi	a5,a5,48
    8000657a:	97c2                	add	a5,a5,a6
    8000657c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000657e:	629c                	ld	a5,0(a3)
    80006580:	97ba                	add	a5,a5,a4
    80006582:	4605                	li	a2,1
    80006584:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006586:	629c                	ld	a5,0(a3)
    80006588:	97ba                	add	a5,a5,a4
    8000658a:	4809                	li	a6,2
    8000658c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006590:	629c                	ld	a5,0(a3)
    80006592:	97ba                	add	a5,a5,a4
    80006594:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006598:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000659c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065a0:	6698                	ld	a4,8(a3)
    800065a2:	00275783          	lhu	a5,2(a4)
    800065a6:	8b9d                	andi	a5,a5,7
    800065a8:	0786                	slli	a5,a5,0x1
    800065aa:	973e                	add	a4,a4,a5
    800065ac:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    800065b0:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065b4:	6698                	ld	a4,8(a3)
    800065b6:	00275783          	lhu	a5,2(a4)
    800065ba:	2785                	addiw	a5,a5,1
    800065bc:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065c0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065c4:	100017b7          	lui	a5,0x10001
    800065c8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065cc:	004aa783          	lw	a5,4(s5)
    800065d0:	02c79163          	bne	a5,a2,800065f2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800065d4:	0001f917          	auipc	s2,0x1f
    800065d8:	b5490913          	addi	s2,s2,-1196 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800065dc:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065de:	85ca                	mv	a1,s2
    800065e0:	8556                	mv	a0,s5
    800065e2:	ffffc097          	auipc	ra,0xffffc
    800065e6:	aa0080e7          	jalr	-1376(ra) # 80002082 <sleep>
  while(b->disk == 1) {
    800065ea:	004aa783          	lw	a5,4(s5)
    800065ee:	fe9788e3          	beq	a5,s1,800065de <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800065f2:	f8042903          	lw	s2,-128(s0)
    800065f6:	20090713          	addi	a4,s2,512
    800065fa:	0712                	slli	a4,a4,0x4
    800065fc:	0001d797          	auipc	a5,0x1d
    80006600:	a0478793          	addi	a5,a5,-1532 # 80023000 <disk>
    80006604:	97ba                	add	a5,a5,a4
    80006606:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000660a:	0001f997          	auipc	s3,0x1f
    8000660e:	9f698993          	addi	s3,s3,-1546 # 80025000 <disk+0x2000>
    80006612:	00491713          	slli	a4,s2,0x4
    80006616:	0009b783          	ld	a5,0(s3)
    8000661a:	97ba                	add	a5,a5,a4
    8000661c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006620:	854a                	mv	a0,s2
    80006622:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006626:	00000097          	auipc	ra,0x0
    8000662a:	c60080e7          	jalr	-928(ra) # 80006286 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000662e:	8885                	andi	s1,s1,1
    80006630:	f0ed                	bnez	s1,80006612 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006632:	0001f517          	auipc	a0,0x1f
    80006636:	af650513          	addi	a0,a0,-1290 # 80025128 <disk+0x2128>
    8000663a:	ffffa097          	auipc	ra,0xffffa
    8000663e:	64a080e7          	jalr	1610(ra) # 80000c84 <release>
}
    80006642:	70e6                	ld	ra,120(sp)
    80006644:	7446                	ld	s0,112(sp)
    80006646:	74a6                	ld	s1,104(sp)
    80006648:	7906                	ld	s2,96(sp)
    8000664a:	69e6                	ld	s3,88(sp)
    8000664c:	6a46                	ld	s4,80(sp)
    8000664e:	6aa6                	ld	s5,72(sp)
    80006650:	6b06                	ld	s6,64(sp)
    80006652:	7be2                	ld	s7,56(sp)
    80006654:	7c42                	ld	s8,48(sp)
    80006656:	7ca2                	ld	s9,40(sp)
    80006658:	7d02                	ld	s10,32(sp)
    8000665a:	6de2                	ld	s11,24(sp)
    8000665c:	6109                	addi	sp,sp,128
    8000665e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006660:	f8042503          	lw	a0,-128(s0)
    80006664:	20050793          	addi	a5,a0,512
    80006668:	0792                	slli	a5,a5,0x4
  if(write)
    8000666a:	0001d817          	auipc	a6,0x1d
    8000666e:	99680813          	addi	a6,a6,-1642 # 80023000 <disk>
    80006672:	00f80733          	add	a4,a6,a5
    80006676:	01a036b3          	snez	a3,s10
    8000667a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000667e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006682:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006686:	7679                	lui	a2,0xffffe
    80006688:	963e                	add	a2,a2,a5
    8000668a:	0001f697          	auipc	a3,0x1f
    8000668e:	97668693          	addi	a3,a3,-1674 # 80025000 <disk+0x2000>
    80006692:	6298                	ld	a4,0(a3)
    80006694:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006696:	0a878593          	addi	a1,a5,168
    8000669a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000669c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000669e:	6298                	ld	a4,0(a3)
    800066a0:	9732                	add	a4,a4,a2
    800066a2:	45c1                	li	a1,16
    800066a4:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066a6:	6298                	ld	a4,0(a3)
    800066a8:	9732                	add	a4,a4,a2
    800066aa:	4585                	li	a1,1
    800066ac:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800066b0:	f8442703          	lw	a4,-124(s0)
    800066b4:	628c                	ld	a1,0(a3)
    800066b6:	962e                	add	a2,a2,a1
    800066b8:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800066bc:	0712                	slli	a4,a4,0x4
    800066be:	6290                	ld	a2,0(a3)
    800066c0:	963a                	add	a2,a2,a4
    800066c2:	058a8593          	addi	a1,s5,88
    800066c6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800066c8:	6294                	ld	a3,0(a3)
    800066ca:	96ba                	add	a3,a3,a4
    800066cc:	40000613          	li	a2,1024
    800066d0:	c690                	sw	a2,8(a3)
  if(write)
    800066d2:	e40d1ae3          	bnez	s10,80006526 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800066d6:	0001f697          	auipc	a3,0x1f
    800066da:	92a6b683          	ld	a3,-1750(a3) # 80025000 <disk+0x2000>
    800066de:	96ba                	add	a3,a3,a4
    800066e0:	4609                	li	a2,2
    800066e2:	00c69623          	sh	a2,12(a3)
    800066e6:	b5b9                	j	80006534 <virtio_disk_rw+0xd2>

00000000800066e8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066e8:	1101                	addi	sp,sp,-32
    800066ea:	ec06                	sd	ra,24(sp)
    800066ec:	e822                	sd	s0,16(sp)
    800066ee:	e426                	sd	s1,8(sp)
    800066f0:	e04a                	sd	s2,0(sp)
    800066f2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066f4:	0001f517          	auipc	a0,0x1f
    800066f8:	a3450513          	addi	a0,a0,-1484 # 80025128 <disk+0x2128>
    800066fc:	ffffa097          	auipc	ra,0xffffa
    80006700:	4d4080e7          	jalr	1236(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006704:	10001737          	lui	a4,0x10001
    80006708:	533c                	lw	a5,96(a4)
    8000670a:	8b8d                	andi	a5,a5,3
    8000670c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000670e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006712:	0001f797          	auipc	a5,0x1f
    80006716:	8ee78793          	addi	a5,a5,-1810 # 80025000 <disk+0x2000>
    8000671a:	6b94                	ld	a3,16(a5)
    8000671c:	0207d703          	lhu	a4,32(a5)
    80006720:	0026d783          	lhu	a5,2(a3)
    80006724:	06f70163          	beq	a4,a5,80006786 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006728:	0001d917          	auipc	s2,0x1d
    8000672c:	8d890913          	addi	s2,s2,-1832 # 80023000 <disk>
    80006730:	0001f497          	auipc	s1,0x1f
    80006734:	8d048493          	addi	s1,s1,-1840 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006738:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000673c:	6898                	ld	a4,16(s1)
    8000673e:	0204d783          	lhu	a5,32(s1)
    80006742:	8b9d                	andi	a5,a5,7
    80006744:	078e                	slli	a5,a5,0x3
    80006746:	97ba                	add	a5,a5,a4
    80006748:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000674a:	20078713          	addi	a4,a5,512
    8000674e:	0712                	slli	a4,a4,0x4
    80006750:	974a                	add	a4,a4,s2
    80006752:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006756:	e731                	bnez	a4,800067a2 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006758:	20078793          	addi	a5,a5,512
    8000675c:	0792                	slli	a5,a5,0x4
    8000675e:	97ca                	add	a5,a5,s2
    80006760:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006762:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006766:	ffffc097          	auipc	ra,0xffffc
    8000676a:	aa8080e7          	jalr	-1368(ra) # 8000220e <wakeup>

    disk.used_idx += 1;
    8000676e:	0204d783          	lhu	a5,32(s1)
    80006772:	2785                	addiw	a5,a5,1
    80006774:	17c2                	slli	a5,a5,0x30
    80006776:	93c1                	srli	a5,a5,0x30
    80006778:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000677c:	6898                	ld	a4,16(s1)
    8000677e:	00275703          	lhu	a4,2(a4)
    80006782:	faf71be3          	bne	a4,a5,80006738 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006786:	0001f517          	auipc	a0,0x1f
    8000678a:	9a250513          	addi	a0,a0,-1630 # 80025128 <disk+0x2128>
    8000678e:	ffffa097          	auipc	ra,0xffffa
    80006792:	4f6080e7          	jalr	1270(ra) # 80000c84 <release>
}
    80006796:	60e2                	ld	ra,24(sp)
    80006798:	6442                	ld	s0,16(sp)
    8000679a:	64a2                	ld	s1,8(sp)
    8000679c:	6902                	ld	s2,0(sp)
    8000679e:	6105                	addi	sp,sp,32
    800067a0:	8082                	ret
      panic("virtio_disk_intr status");
    800067a2:	00002517          	auipc	a0,0x2
    800067a6:	15e50513          	addi	a0,a0,350 # 80008900 <syscalls+0x3f8>
    800067aa:	ffffa097          	auipc	ra,0xffffa
    800067ae:	d90080e7          	jalr	-624(ra) # 8000053a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
