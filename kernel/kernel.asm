
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	88013103          	ld	sp,-1920(sp) # 80008880 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000066:	cde78793          	addi	a5,a5,-802 # 80005d40 <timervec>
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
    8000012e:	32a080e7          	jalr	810(ra) # 80002454 <either_copyin>
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
    800001d4:	e8a080e7          	jalr	-374(ra) # 8000205a <sleep>
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
    80000210:	1f2080e7          	jalr	498(ra) # 800023fe <either_copyout>
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
    800002f0:	1be080e7          	jalr	446(ra) # 800024aa <procdump>
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
    80000444:	da6080e7          	jalr	-602(ra) # 800021e6 <wakeup>
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
    80000476:	ea678793          	addi	a5,a5,-346 # 80021318 <devsw>
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
    80000892:	958080e7          	jalr	-1704(ra) # 800021e6 <wakeup>
    
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
    8000091e:	740080e7          	jalr	1856(ra) # 8000205a <sleep>
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
    80000ebc:	868080e7          	jalr	-1944(ra) # 80002720 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	ec0080e7          	jalr	-320(ra) # 80005d80 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	fe0080e7          	jalr	-32(ra) # 80001ea8 <scheduler>
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
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	7c8080e7          	jalr	1992(ra) # 800026f8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	7e8080e7          	jalr	2024(ra) # 80002720 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	e2a080e7          	jalr	-470(ra) # 80005d6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	e38080e7          	jalr	-456(ra) # 80005d80 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	000080e7          	jalr	ra # 80002f50 <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	68e080e7          	jalr	1678(ra) # 800035e6 <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	640080e7          	jalr	1600(ra) # 800045a0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	f38080e7          	jalr	-200(ra) # 80005ea0 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	cfe080e7          	jalr	-770(ra) # 80001c6e <userinit>
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
    80001858:	87ca0a13          	addi	s4,s4,-1924 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if(pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	858d                	srai	a1,a1,0x3
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
    8000188e:	16848493          	addi	s1,s1,360
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
    80001920:	00015997          	auipc	s3,0x15
    80001924:	7b098993          	addi	s3,s3,1968 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	878d                	srai	a5,a5,0x3
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	16848493          	addi	s1,s1,360
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
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e406                	sd	ra,8(sp)
    800019d2:	e022                	sd	s0,0(sp)
    800019d4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	fc0080e7          	jalr	-64(ra) # 80001996 <myproc>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>

  if (first) {
    800019e6:	00007797          	auipc	a5,0x7
    800019ea:	e4a7a783          	lw	a5,-438(a5) # 80008830 <first.1>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	d48080e7          	jalr	-696(ra) # 80002738 <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e207a823          	sw	zero,-464(a5) # 80008830 <first.1>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	b5c080e7          	jalr	-1188(ra) # 80003566 <fsinit>
    80001a12:	bff9                	j	800019f0 <forkret+0x22>

0000000080001a14 <allocpid>:
allocpid() {
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a20:	00010917          	auipc	s2,0x10
    80001a24:	88090913          	addi	s2,s2,-1920 # 800112a0 <pid_lock>
    80001a28:	854a                	mv	a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	1a6080e7          	jalr	422(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	e0278793          	addi	a5,a5,-510 # 80008834 <nextpid>
    80001a3a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3c:	0014871b          	addiw	a4,s1,1
    80001a40:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	240080e7          	jalr	576(ra) # 80000c84 <release>
}
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	60e2                	ld	ra,24(sp)
    80001a50:	6442                	ld	s0,16(sp)
    80001a52:	64a2                	ld	s1,8(sp)
    80001a54:	6902                	ld	s2,0(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <proc_pagetable>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	8b6080e7          	jalr	-1866(ra) # 8000131e <uvmcreate>
    80001a70:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a72:	c121                	beqz	a0,80001ab2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a74:	4729                	li	a4,10
    80001a76:	00005697          	auipc	a3,0x5
    80001a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80001a7e:	6605                	lui	a2,0x1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	60c080e7          	jalr	1548(ra) # 80001094 <mappages>
    80001a90:	02054863          	bltz	a0,80001ac0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a94:	4719                	li	a4,6
    80001a96:	05893683          	ld	a3,88(s2)
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	020005b7          	lui	a1,0x2000
    80001aa0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001aa2:	05b6                	slli	a1,a1,0xd
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5ee080e7          	jalr	1518(ra) # 80001094 <mappages>
    80001aae:	02054163          	bltz	a0,80001ad0 <proc_pagetable+0x76>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a58080e7          	jalr	-1448(ra) # 8000151c <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	b7d5                	j	80001ab2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad0:	4681                	li	a3,0
    80001ad2:	4605                	li	a2,1
    80001ad4:	040005b7          	lui	a1,0x4000
    80001ad8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ada:	05b2                	slli	a1,a1,0xc
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	77c080e7          	jalr	1916(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a32080e7          	jalr	-1486(ra) # 8000151c <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	bf7d                	j	80001ab2 <proc_pagetable+0x58>

0000000080001af6 <proc_freepagetable>:
{
    80001af6:	1101                	addi	sp,sp,-32
    80001af8:	ec06                	sd	ra,24(sp)
    80001afa:	e822                	sd	s0,16(sp)
    80001afc:	e426                	sd	s1,8(sp)
    80001afe:	e04a                	sd	s2,0(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
    80001b04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	748080e7          	jalr	1864(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	020005b7          	lui	a1,0x2000
    80001b22:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b24:	05b6                	slli	a1,a1,0xd
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	732080e7          	jalr	1842(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b30:	85ca                	mv	a1,s2
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	9e8080e7          	jalr	-1560(ra) # 8000151c <uvmfree>
}
    80001b3c:	60e2                	ld	ra,24(sp)
    80001b3e:	6442                	ld	s0,16(sp)
    80001b40:	64a2                	ld	s1,8(sp)
    80001b42:	6902                	ld	s2,0(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freeproc>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b54:	6d28                	ld	a0,88(a0)
    80001b56:	c509                	beqz	a0,80001b60 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	e8a080e7          	jalr	-374(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b60:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b64:	68a8                	ld	a0,80(s1)
    80001b66:	c511                	beqz	a0,80001b72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b68:	64ac                	ld	a1,72(s1)
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f8c080e7          	jalr	-116(ra) # 80001af6 <proc_freepagetable>
  p->pagetable = 0;
    80001b72:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b76:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b82:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b92:	0004ac23          	sw	zero,24(s1)
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <allocproc>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bac:	00010497          	auipc	s1,0x10
    80001bb0:	b2448493          	addi	s1,s1,-1244 # 800116d0 <proc>
    80001bb4:	00015917          	auipc	s2,0x15
    80001bb8:	51c90913          	addi	s2,s2,1308 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	012080e7          	jalr	18(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001bc6:	4c9c                	lw	a5,24(s1)
    80001bc8:	cf81                	beqz	a5,80001be0 <allocproc+0x40>
      release(&p->lock);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0b8080e7          	jalr	184(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd4:	16848493          	addi	s1,s1,360
    80001bd8:	ff2492e3          	bne	s1,s2,80001bbc <allocproc+0x1c>
  return 0;
    80001bdc:	4481                	li	s1,0
    80001bde:	a889                	j	80001c30 <allocproc+0x90>
  p->pid = allocpid();
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	e34080e7          	jalr	-460(ra) # 80001a14 <allocpid>
    80001be8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bea:	4785                	li	a5,1
    80001bec:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ef2080e7          	jalr	-270(ra) # 80000ae0 <kalloc>
    80001bf6:	892a                	mv	s2,a0
    80001bf8:	eca8                	sd	a0,88(s1)
    80001bfa:	c131                	beqz	a0,80001c3e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	e5c080e7          	jalr	-420(ra) # 80001a5a <proc_pagetable>
    80001c06:	892a                	mv	s2,a0
    80001c08:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c0a:	c531                	beqz	a0,80001c56 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c0c:	07000613          	li	a2,112
    80001c10:	4581                	li	a1,0
    80001c12:	06048513          	addi	a0,s1,96
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	0b6080e7          	jalr	182(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c1e:	00000797          	auipc	a5,0x0
    80001c22:	db078793          	addi	a5,a5,-592 # 800019ce <forkret>
    80001c26:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c28:	60bc                	ld	a5,64(s1)
    80001c2a:	6705                	lui	a4,0x1
    80001c2c:	97ba                	add	a5,a5,a4
    80001c2e:	f4bc                	sd	a5,104(s1)
}
    80001c30:	8526                	mv	a0,s1
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6902                	ld	s2,0(sp)
    80001c3a:	6105                	addi	sp,sp,32
    80001c3c:	8082                	ret
    freeproc(p);
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	f08080e7          	jalr	-248(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	03a080e7          	jalr	58(ra) # 80000c84 <release>
    return 0;
    80001c52:	84ca                	mv	s1,s2
    80001c54:	bff1                	j	80001c30 <allocproc+0x90>
    freeproc(p);
    80001c56:	8526                	mv	a0,s1
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	ef0080e7          	jalr	-272(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	022080e7          	jalr	34(ra) # 80000c84 <release>
    return 0;
    80001c6a:	84ca                	mv	s1,s2
    80001c6c:	b7d1                	j	80001c30 <allocproc+0x90>

0000000080001c6e <userinit>:
{
    80001c6e:	1101                	addi	sp,sp,-32
    80001c70:	ec06                	sd	ra,24(sp)
    80001c72:	e822                	sd	s0,16(sp)
    80001c74:	e426                	sd	s1,8(sp)
    80001c76:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	f28080e7          	jalr	-216(ra) # 80001ba0 <allocproc>
    80001c80:	84aa                	mv	s1,a0
  initproc = p;
    80001c82:	00007797          	auipc	a5,0x7
    80001c86:	3aa7b323          	sd	a0,934(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c8a:	03400613          	li	a2,52
    80001c8e:	00007597          	auipc	a1,0x7
    80001c92:	bb258593          	addi	a1,a1,-1102 # 80008840 <initcode>
    80001c96:	6928                	ld	a0,80(a0)
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	6b4080e7          	jalr	1716(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001ca0:	6785                	lui	a5,0x1
    80001ca2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ca4:	6cb8                	ld	a4,88(s1)
    80001ca6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001caa:	6cb8                	ld	a4,88(s1)
    80001cac:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cae:	4641                	li	a2,16
    80001cb0:	00006597          	auipc	a1,0x6
    80001cb4:	55058593          	addi	a1,a1,1360 # 80008200 <digits+0x1c0>
    80001cb8:	15848513          	addi	a0,s1,344
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	15a080e7          	jalr	346(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cc4:	00006517          	auipc	a0,0x6
    80001cc8:	54c50513          	addi	a0,a0,1356 # 80008210 <digits+0x1d0>
    80001ccc:	00002097          	auipc	ra,0x2
    80001cd0:	2d0080e7          	jalr	720(ra) # 80003f9c <namei>
    80001cd4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cd8:	478d                	li	a5,3
    80001cda:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fa6080e7          	jalr	-90(ra) # 80000c84 <release>
}
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6105                	addi	sp,sp,32
    80001cee:	8082                	ret

0000000080001cf0 <growproc>:
{
    80001cf0:	1101                	addi	sp,sp,-32
    80001cf2:	ec06                	sd	ra,24(sp)
    80001cf4:	e822                	sd	s0,16(sp)
    80001cf6:	e426                	sd	s1,8(sp)
    80001cf8:	e04a                	sd	s2,0(sp)
    80001cfa:	1000                	addi	s0,sp,32
    80001cfc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	c98080e7          	jalr	-872(ra) # 80001996 <myproc>
    80001d06:	892a                	mv	s2,a0
  sz = p->sz;
    80001d08:	652c                	ld	a1,72(a0)
    80001d0a:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d0e:	00904f63          	bgtz	s1,80001d2c <growproc+0x3c>
  } else if(n < 0){
    80001d12:	0204cd63          	bltz	s1,80001d4c <growproc+0x5c>
  p->sz = sz;
    80001d16:	1782                	slli	a5,a5,0x20
    80001d18:	9381                	srli	a5,a5,0x20
    80001d1a:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d1e:	4501                	li	a0,0
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6902                	ld	s2,0(sp)
    80001d28:	6105                	addi	sp,sp,32
    80001d2a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d2c:	00f4863b          	addw	a2,s1,a5
    80001d30:	1602                	slli	a2,a2,0x20
    80001d32:	9201                	srli	a2,a2,0x20
    80001d34:	1582                	slli	a1,a1,0x20
    80001d36:	9181                	srli	a1,a1,0x20
    80001d38:	6928                	ld	a0,80(a0)
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	6cc080e7          	jalr	1740(ra) # 80001406 <uvmalloc>
    80001d42:	0005079b          	sext.w	a5,a0
    80001d46:	fbe1                	bnez	a5,80001d16 <growproc+0x26>
      return -1;
    80001d48:	557d                	li	a0,-1
    80001d4a:	bfd9                	j	80001d20 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d4c:	00f4863b          	addw	a2,s1,a5
    80001d50:	1602                	slli	a2,a2,0x20
    80001d52:	9201                	srli	a2,a2,0x20
    80001d54:	1582                	slli	a1,a1,0x20
    80001d56:	9181                	srli	a1,a1,0x20
    80001d58:	6928                	ld	a0,80(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	664080e7          	jalr	1636(ra) # 800013be <uvmdealloc>
    80001d62:	0005079b          	sext.w	a5,a0
    80001d66:	bf45                	j	80001d16 <growproc+0x26>

0000000080001d68 <fork>:
{
    80001d68:	7139                	addi	sp,sp,-64
    80001d6a:	fc06                	sd	ra,56(sp)
    80001d6c:	f822                	sd	s0,48(sp)
    80001d6e:	f426                	sd	s1,40(sp)
    80001d70:	f04a                	sd	s2,32(sp)
    80001d72:	ec4e                	sd	s3,24(sp)
    80001d74:	e852                	sd	s4,16(sp)
    80001d76:	e456                	sd	s5,8(sp)
    80001d78:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	c1c080e7          	jalr	-996(ra) # 80001996 <myproc>
    80001d82:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d84:	00000097          	auipc	ra,0x0
    80001d88:	e1c080e7          	jalr	-484(ra) # 80001ba0 <allocproc>
    80001d8c:	10050c63          	beqz	a0,80001ea4 <fork+0x13c>
    80001d90:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d92:	048ab603          	ld	a2,72(s5)
    80001d96:	692c                	ld	a1,80(a0)
    80001d98:	050ab503          	ld	a0,80(s5)
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	7ba080e7          	jalr	1978(ra) # 80001556 <uvmcopy>
    80001da4:	04054863          	bltz	a0,80001df4 <fork+0x8c>
  np->sz = p->sz;
    80001da8:	048ab783          	ld	a5,72(s5)
    80001dac:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001db0:	058ab683          	ld	a3,88(s5)
    80001db4:	87b6                	mv	a5,a3
    80001db6:	058a3703          	ld	a4,88(s4)
    80001dba:	12068693          	addi	a3,a3,288
    80001dbe:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dc2:	6788                	ld	a0,8(a5)
    80001dc4:	6b8c                	ld	a1,16(a5)
    80001dc6:	6f90                	ld	a2,24(a5)
    80001dc8:	01073023          	sd	a6,0(a4)
    80001dcc:	e708                	sd	a0,8(a4)
    80001dce:	eb0c                	sd	a1,16(a4)
    80001dd0:	ef10                	sd	a2,24(a4)
    80001dd2:	02078793          	addi	a5,a5,32
    80001dd6:	02070713          	addi	a4,a4,32
    80001dda:	fed792e3          	bne	a5,a3,80001dbe <fork+0x56>
  np->trapframe->a0 = 0;
    80001dde:	058a3783          	ld	a5,88(s4)
    80001de2:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de6:	0d0a8493          	addi	s1,s5,208
    80001dea:	0d0a0913          	addi	s2,s4,208
    80001dee:	150a8993          	addi	s3,s5,336
    80001df2:	a00d                	j	80001e14 <fork+0xac>
    freeproc(np);
    80001df4:	8552                	mv	a0,s4
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	d52080e7          	jalr	-686(ra) # 80001b48 <freeproc>
    release(&np->lock);
    80001dfe:	8552                	mv	a0,s4
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	e84080e7          	jalr	-380(ra) # 80000c84 <release>
    return -1;
    80001e08:	597d                	li	s2,-1
    80001e0a:	a059                	j	80001e90 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e0c:	04a1                	addi	s1,s1,8
    80001e0e:	0921                	addi	s2,s2,8
    80001e10:	01348b63          	beq	s1,s3,80001e26 <fork+0xbe>
    if(p->ofile[i])
    80001e14:	6088                	ld	a0,0(s1)
    80001e16:	d97d                	beqz	a0,80001e0c <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e18:	00003097          	auipc	ra,0x3
    80001e1c:	81a080e7          	jalr	-2022(ra) # 80004632 <filedup>
    80001e20:	00a93023          	sd	a0,0(s2)
    80001e24:	b7e5                	j	80001e0c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e26:	150ab503          	ld	a0,336(s5)
    80001e2a:	00002097          	auipc	ra,0x2
    80001e2e:	978080e7          	jalr	-1672(ra) # 800037a2 <idup>
    80001e32:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e36:	4641                	li	a2,16
    80001e38:	158a8593          	addi	a1,s5,344
    80001e3c:	158a0513          	addi	a0,s4,344
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	fd6080e7          	jalr	-42(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e48:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e4c:	8552                	mv	a0,s4
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	e36080e7          	jalr	-458(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e56:	0000f497          	auipc	s1,0xf
    80001e5a:	46248493          	addi	s1,s1,1122 # 800112b8 <wait_lock>
    80001e5e:	8526                	mv	a0,s1
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	d70080e7          	jalr	-656(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001e68:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e16080e7          	jalr	-490(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001e76:	8552                	mv	a0,s4
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	d58080e7          	jalr	-680(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001e80:	478d                	li	a5,3
    80001e82:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e86:	8552                	mv	a0,s4
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	dfc080e7          	jalr	-516(ra) # 80000c84 <release>
}
    80001e90:	854a                	mv	a0,s2
    80001e92:	70e2                	ld	ra,56(sp)
    80001e94:	7442                	ld	s0,48(sp)
    80001e96:	74a2                	ld	s1,40(sp)
    80001e98:	7902                	ld	s2,32(sp)
    80001e9a:	69e2                	ld	s3,24(sp)
    80001e9c:	6a42                	ld	s4,16(sp)
    80001e9e:	6aa2                	ld	s5,8(sp)
    80001ea0:	6121                	addi	sp,sp,64
    80001ea2:	8082                	ret
    return -1;
    80001ea4:	597d                	li	s2,-1
    80001ea6:	b7ed                	j	80001e90 <fork+0x128>

0000000080001ea8 <scheduler>:
{
    80001ea8:	7139                	addi	sp,sp,-64
    80001eaa:	fc06                	sd	ra,56(sp)
    80001eac:	f822                	sd	s0,48(sp)
    80001eae:	f426                	sd	s1,40(sp)
    80001eb0:	f04a                	sd	s2,32(sp)
    80001eb2:	ec4e                	sd	s3,24(sp)
    80001eb4:	e852                	sd	s4,16(sp)
    80001eb6:	e456                	sd	s5,8(sp)
    80001eb8:	e05a                	sd	s6,0(sp)
    80001eba:	0080                	addi	s0,sp,64
    80001ebc:	8792                	mv	a5,tp
  int id = r_tp();
    80001ebe:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ec0:	00779a93          	slli	s5,a5,0x7
    80001ec4:	0000f717          	auipc	a4,0xf
    80001ec8:	3dc70713          	addi	a4,a4,988 # 800112a0 <pid_lock>
    80001ecc:	9756                	add	a4,a4,s5
    80001ece:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ed2:	0000f717          	auipc	a4,0xf
    80001ed6:	40670713          	addi	a4,a4,1030 # 800112d8 <cpus+0x8>
    80001eda:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001edc:	498d                	li	s3,3
        p->state = RUNNING;
    80001ede:	4b11                	li	s6,4
        c->proc = p;
    80001ee0:	079e                	slli	a5,a5,0x7
    80001ee2:	0000fa17          	auipc	s4,0xf
    80001ee6:	3bea0a13          	addi	s4,s4,958 # 800112a0 <pid_lock>
    80001eea:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eec:	00015917          	auipc	s2,0x15
    80001ef0:	1e490913          	addi	s2,s2,484 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001efc:	10079073          	csrw	sstatus,a5
    80001f00:	0000f497          	auipc	s1,0xf
    80001f04:	7d048493          	addi	s1,s1,2000 # 800116d0 <proc>
    80001f08:	a811                	j	80001f1c <scheduler+0x74>
      release(&p->lock);
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	d78080e7          	jalr	-648(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f14:	16848493          	addi	s1,s1,360
    80001f18:	fd248ee3          	beq	s1,s2,80001ef4 <scheduler+0x4c>
      acquire(&p->lock);
    80001f1c:	8526                	mv	a0,s1
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	cb2080e7          	jalr	-846(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80001f26:	4c9c                	lw	a5,24(s1)
    80001f28:	ff3791e3          	bne	a5,s3,80001f0a <scheduler+0x62>
        p->state = RUNNING;
    80001f2c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f30:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f34:	06048593          	addi	a1,s1,96
    80001f38:	8556                	mv	a0,s5
    80001f3a:	00000097          	auipc	ra,0x0
    80001f3e:	754080e7          	jalr	1876(ra) # 8000268e <swtch>
        c->proc = 0;
    80001f42:	020a3823          	sd	zero,48(s4)
    80001f46:	b7d1                	j	80001f0a <scheduler+0x62>

0000000080001f48 <sched>:
{
    80001f48:	7179                	addi	sp,sp,-48
    80001f4a:	f406                	sd	ra,40(sp)
    80001f4c:	f022                	sd	s0,32(sp)
    80001f4e:	ec26                	sd	s1,24(sp)
    80001f50:	e84a                	sd	s2,16(sp)
    80001f52:	e44e                	sd	s3,8(sp)
    80001f54:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f56:	00000097          	auipc	ra,0x0
    80001f5a:	a40080e7          	jalr	-1472(ra) # 80001996 <myproc>
    80001f5e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	bf6080e7          	jalr	-1034(ra) # 80000b56 <holding>
    80001f68:	c93d                	beqz	a0,80001fde <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f6a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f6c:	2781                	sext.w	a5,a5
    80001f6e:	079e                	slli	a5,a5,0x7
    80001f70:	0000f717          	auipc	a4,0xf
    80001f74:	33070713          	addi	a4,a4,816 # 800112a0 <pid_lock>
    80001f78:	97ba                	add	a5,a5,a4
    80001f7a:	0a87a703          	lw	a4,168(a5)
    80001f7e:	4785                	li	a5,1
    80001f80:	06f71763          	bne	a4,a5,80001fee <sched+0xa6>
  if(p->state == RUNNING)
    80001f84:	4c98                	lw	a4,24(s1)
    80001f86:	4791                	li	a5,4
    80001f88:	06f70b63          	beq	a4,a5,80001ffe <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f8c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f90:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f92:	efb5                	bnez	a5,8000200e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f94:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f96:	0000f917          	auipc	s2,0xf
    80001f9a:	30a90913          	addi	s2,s2,778 # 800112a0 <pid_lock>
    80001f9e:	2781                	sext.w	a5,a5
    80001fa0:	079e                	slli	a5,a5,0x7
    80001fa2:	97ca                	add	a5,a5,s2
    80001fa4:	0ac7a983          	lw	s3,172(a5)
    80001fa8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001faa:	2781                	sext.w	a5,a5
    80001fac:	079e                	slli	a5,a5,0x7
    80001fae:	0000f597          	auipc	a1,0xf
    80001fb2:	32a58593          	addi	a1,a1,810 # 800112d8 <cpus+0x8>
    80001fb6:	95be                	add	a1,a1,a5
    80001fb8:	06048513          	addi	a0,s1,96
    80001fbc:	00000097          	auipc	ra,0x0
    80001fc0:	6d2080e7          	jalr	1746(ra) # 8000268e <swtch>
    80001fc4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc6:	2781                	sext.w	a5,a5
    80001fc8:	079e                	slli	a5,a5,0x7
    80001fca:	993e                	add	s2,s2,a5
    80001fcc:	0b392623          	sw	s3,172(s2)
}
    80001fd0:	70a2                	ld	ra,40(sp)
    80001fd2:	7402                	ld	s0,32(sp)
    80001fd4:	64e2                	ld	s1,24(sp)
    80001fd6:	6942                	ld	s2,16(sp)
    80001fd8:	69a2                	ld	s3,8(sp)
    80001fda:	6145                	addi	sp,sp,48
    80001fdc:	8082                	ret
    panic("sched p->lock");
    80001fde:	00006517          	auipc	a0,0x6
    80001fe2:	23a50513          	addi	a0,a0,570 # 80008218 <digits+0x1d8>
    80001fe6:	ffffe097          	auipc	ra,0xffffe
    80001fea:	554080e7          	jalr	1364(ra) # 8000053a <panic>
    panic("sched locks");
    80001fee:	00006517          	auipc	a0,0x6
    80001ff2:	23a50513          	addi	a0,a0,570 # 80008228 <digits+0x1e8>
    80001ff6:	ffffe097          	auipc	ra,0xffffe
    80001ffa:	544080e7          	jalr	1348(ra) # 8000053a <panic>
    panic("sched running");
    80001ffe:	00006517          	auipc	a0,0x6
    80002002:	23a50513          	addi	a0,a0,570 # 80008238 <digits+0x1f8>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	534080e7          	jalr	1332(ra) # 8000053a <panic>
    panic("sched interruptible");
    8000200e:	00006517          	auipc	a0,0x6
    80002012:	23a50513          	addi	a0,a0,570 # 80008248 <digits+0x208>
    80002016:	ffffe097          	auipc	ra,0xffffe
    8000201a:	524080e7          	jalr	1316(ra) # 8000053a <panic>

000000008000201e <yield>:
{
    8000201e:	1101                	addi	sp,sp,-32
    80002020:	ec06                	sd	ra,24(sp)
    80002022:	e822                	sd	s0,16(sp)
    80002024:	e426                	sd	s1,8(sp)
    80002026:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	96e080e7          	jalr	-1682(ra) # 80001996 <myproc>
    80002030:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	b9e080e7          	jalr	-1122(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    8000203a:	478d                	li	a5,3
    8000203c:	cc9c                	sw	a5,24(s1)
  sched();
    8000203e:	00000097          	auipc	ra,0x0
    80002042:	f0a080e7          	jalr	-246(ra) # 80001f48 <sched>
  release(&p->lock);
    80002046:	8526                	mv	a0,s1
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	c3c080e7          	jalr	-964(ra) # 80000c84 <release>
}
    80002050:	60e2                	ld	ra,24(sp)
    80002052:	6442                	ld	s0,16(sp)
    80002054:	64a2                	ld	s1,8(sp)
    80002056:	6105                	addi	sp,sp,32
    80002058:	8082                	ret

000000008000205a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000205a:	7179                	addi	sp,sp,-48
    8000205c:	f406                	sd	ra,40(sp)
    8000205e:	f022                	sd	s0,32(sp)
    80002060:	ec26                	sd	s1,24(sp)
    80002062:	e84a                	sd	s2,16(sp)
    80002064:	e44e                	sd	s3,8(sp)
    80002066:	1800                	addi	s0,sp,48
    80002068:	89aa                	mv	s3,a0
    8000206a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000206c:	00000097          	auipc	ra,0x0
    80002070:	92a080e7          	jalr	-1750(ra) # 80001996 <myproc>
    80002074:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	b5a080e7          	jalr	-1190(ra) # 80000bd0 <acquire>
  release(lk);
    8000207e:	854a                	mv	a0,s2
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	c04080e7          	jalr	-1020(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    80002088:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000208c:	4789                	li	a5,2
    8000208e:	cc9c                	sw	a5,24(s1)

  sched();
    80002090:	00000097          	auipc	ra,0x0
    80002094:	eb8080e7          	jalr	-328(ra) # 80001f48 <sched>

  // Tidy up.
  p->chan = 0;
    80002098:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000209c:	8526                	mv	a0,s1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	be6080e7          	jalr	-1050(ra) # 80000c84 <release>
  acquire(lk);
    800020a6:	854a                	mv	a0,s2
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	b28080e7          	jalr	-1240(ra) # 80000bd0 <acquire>
}
    800020b0:	70a2                	ld	ra,40(sp)
    800020b2:	7402                	ld	s0,32(sp)
    800020b4:	64e2                	ld	s1,24(sp)
    800020b6:	6942                	ld	s2,16(sp)
    800020b8:	69a2                	ld	s3,8(sp)
    800020ba:	6145                	addi	sp,sp,48
    800020bc:	8082                	ret

00000000800020be <wait>:
{
    800020be:	715d                	addi	sp,sp,-80
    800020c0:	e486                	sd	ra,72(sp)
    800020c2:	e0a2                	sd	s0,64(sp)
    800020c4:	fc26                	sd	s1,56(sp)
    800020c6:	f84a                	sd	s2,48(sp)
    800020c8:	f44e                	sd	s3,40(sp)
    800020ca:	f052                	sd	s4,32(sp)
    800020cc:	ec56                	sd	s5,24(sp)
    800020ce:	e85a                	sd	s6,16(sp)
    800020d0:	e45e                	sd	s7,8(sp)
    800020d2:	e062                	sd	s8,0(sp)
    800020d4:	0880                	addi	s0,sp,80
    800020d6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	8be080e7          	jalr	-1858(ra) # 80001996 <myproc>
    800020e0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020e2:	0000f517          	auipc	a0,0xf
    800020e6:	1d650513          	addi	a0,a0,470 # 800112b8 <wait_lock>
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	ae6080e7          	jalr	-1306(ra) # 80000bd0 <acquire>
    havekids = 0;
    800020f2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020f4:	4a15                	li	s4,5
        havekids = 1;
    800020f6:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800020f8:	00015997          	auipc	s3,0x15
    800020fc:	fd898993          	addi	s3,s3,-40 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002100:	0000fc17          	auipc	s8,0xf
    80002104:	1b8c0c13          	addi	s8,s8,440 # 800112b8 <wait_lock>
    havekids = 0;
    80002108:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000210a:	0000f497          	auipc	s1,0xf
    8000210e:	5c648493          	addi	s1,s1,1478 # 800116d0 <proc>
    80002112:	a0bd                	j	80002180 <wait+0xc2>
          pid = np->pid;
    80002114:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002118:	000b0e63          	beqz	s6,80002134 <wait+0x76>
    8000211c:	4691                	li	a3,4
    8000211e:	02c48613          	addi	a2,s1,44
    80002122:	85da                	mv	a1,s6
    80002124:	05093503          	ld	a0,80(s2)
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	532080e7          	jalr	1330(ra) # 8000165a <copyout>
    80002130:	02054563          	bltz	a0,8000215a <wait+0x9c>
          freeproc(np);
    80002134:	8526                	mv	a0,s1
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	a12080e7          	jalr	-1518(ra) # 80001b48 <freeproc>
          release(&np->lock);
    8000213e:	8526                	mv	a0,s1
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b44080e7          	jalr	-1212(ra) # 80000c84 <release>
          release(&wait_lock);
    80002148:	0000f517          	auipc	a0,0xf
    8000214c:	17050513          	addi	a0,a0,368 # 800112b8 <wait_lock>
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	b34080e7          	jalr	-1228(ra) # 80000c84 <release>
          return pid;
    80002158:	a09d                	j	800021be <wait+0x100>
            release(&np->lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b28080e7          	jalr	-1240(ra) # 80000c84 <release>
            release(&wait_lock);
    80002164:	0000f517          	auipc	a0,0xf
    80002168:	15450513          	addi	a0,a0,340 # 800112b8 <wait_lock>
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	b18080e7          	jalr	-1256(ra) # 80000c84 <release>
            return -1;
    80002174:	59fd                	li	s3,-1
    80002176:	a0a1                	j	800021be <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002178:	16848493          	addi	s1,s1,360
    8000217c:	03348463          	beq	s1,s3,800021a4 <wait+0xe6>
      if(np->parent == p){
    80002180:	7c9c                	ld	a5,56(s1)
    80002182:	ff279be3          	bne	a5,s2,80002178 <wait+0xba>
        acquire(&np->lock);
    80002186:	8526                	mv	a0,s1
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	a48080e7          	jalr	-1464(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002190:	4c9c                	lw	a5,24(s1)
    80002192:	f94781e3          	beq	a5,s4,80002114 <wait+0x56>
        release(&np->lock);
    80002196:	8526                	mv	a0,s1
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	aec080e7          	jalr	-1300(ra) # 80000c84 <release>
        havekids = 1;
    800021a0:	8756                	mv	a4,s5
    800021a2:	bfd9                	j	80002178 <wait+0xba>
    if(!havekids || p->killed){
    800021a4:	c701                	beqz	a4,800021ac <wait+0xee>
    800021a6:	02892783          	lw	a5,40(s2)
    800021aa:	c79d                	beqz	a5,800021d8 <wait+0x11a>
      release(&wait_lock);
    800021ac:	0000f517          	auipc	a0,0xf
    800021b0:	10c50513          	addi	a0,a0,268 # 800112b8 <wait_lock>
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	ad0080e7          	jalr	-1328(ra) # 80000c84 <release>
      return -1;
    800021bc:	59fd                	li	s3,-1
}
    800021be:	854e                	mv	a0,s3
    800021c0:	60a6                	ld	ra,72(sp)
    800021c2:	6406                	ld	s0,64(sp)
    800021c4:	74e2                	ld	s1,56(sp)
    800021c6:	7942                	ld	s2,48(sp)
    800021c8:	79a2                	ld	s3,40(sp)
    800021ca:	7a02                	ld	s4,32(sp)
    800021cc:	6ae2                	ld	s5,24(sp)
    800021ce:	6b42                	ld	s6,16(sp)
    800021d0:	6ba2                	ld	s7,8(sp)
    800021d2:	6c02                	ld	s8,0(sp)
    800021d4:	6161                	addi	sp,sp,80
    800021d6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021d8:	85e2                	mv	a1,s8
    800021da:	854a                	mv	a0,s2
    800021dc:	00000097          	auipc	ra,0x0
    800021e0:	e7e080e7          	jalr	-386(ra) # 8000205a <sleep>
    havekids = 0;
    800021e4:	b715                	j	80002108 <wait+0x4a>

00000000800021e6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021e6:	7139                	addi	sp,sp,-64
    800021e8:	fc06                	sd	ra,56(sp)
    800021ea:	f822                	sd	s0,48(sp)
    800021ec:	f426                	sd	s1,40(sp)
    800021ee:	f04a                	sd	s2,32(sp)
    800021f0:	ec4e                	sd	s3,24(sp)
    800021f2:	e852                	sd	s4,16(sp)
    800021f4:	e456                	sd	s5,8(sp)
    800021f6:	0080                	addi	s0,sp,64
    800021f8:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021fa:	0000f497          	auipc	s1,0xf
    800021fe:	4d648493          	addi	s1,s1,1238 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002202:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002204:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002206:	00015917          	auipc	s2,0x15
    8000220a:	eca90913          	addi	s2,s2,-310 # 800170d0 <tickslock>
    8000220e:	a811                	j	80002222 <wakeup+0x3c>
      }
      release(&p->lock);
    80002210:	8526                	mv	a0,s1
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a72080e7          	jalr	-1422(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000221a:	16848493          	addi	s1,s1,360
    8000221e:	03248663          	beq	s1,s2,8000224a <wakeup+0x64>
    if(p != myproc()){
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	774080e7          	jalr	1908(ra) # 80001996 <myproc>
    8000222a:	fea488e3          	beq	s1,a0,8000221a <wakeup+0x34>
      acquire(&p->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	9a0080e7          	jalr	-1632(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002238:	4c9c                	lw	a5,24(s1)
    8000223a:	fd379be3          	bne	a5,s3,80002210 <wakeup+0x2a>
    8000223e:	709c                	ld	a5,32(s1)
    80002240:	fd4798e3          	bne	a5,s4,80002210 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002244:	0154ac23          	sw	s5,24(s1)
    80002248:	b7e1                	j	80002210 <wakeup+0x2a>
    }
  }
}
    8000224a:	70e2                	ld	ra,56(sp)
    8000224c:	7442                	ld	s0,48(sp)
    8000224e:	74a2                	ld	s1,40(sp)
    80002250:	7902                	ld	s2,32(sp)
    80002252:	69e2                	ld	s3,24(sp)
    80002254:	6a42                	ld	s4,16(sp)
    80002256:	6aa2                	ld	s5,8(sp)
    80002258:	6121                	addi	sp,sp,64
    8000225a:	8082                	ret

000000008000225c <reparent>:
{
    8000225c:	7179                	addi	sp,sp,-48
    8000225e:	f406                	sd	ra,40(sp)
    80002260:	f022                	sd	s0,32(sp)
    80002262:	ec26                	sd	s1,24(sp)
    80002264:	e84a                	sd	s2,16(sp)
    80002266:	e44e                	sd	s3,8(sp)
    80002268:	e052                	sd	s4,0(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	46248493          	addi	s1,s1,1122 # 800116d0 <proc>
      pp->parent = initproc;
    80002276:	00007a17          	auipc	s4,0x7
    8000227a:	db2a0a13          	addi	s4,s4,-590 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227e:	00015997          	auipc	s3,0x15
    80002282:	e5298993          	addi	s3,s3,-430 # 800170d0 <tickslock>
    80002286:	a029                	j	80002290 <reparent+0x34>
    80002288:	16848493          	addi	s1,s1,360
    8000228c:	01348d63          	beq	s1,s3,800022a6 <reparent+0x4a>
    if(pp->parent == p){
    80002290:	7c9c                	ld	a5,56(s1)
    80002292:	ff279be3          	bne	a5,s2,80002288 <reparent+0x2c>
      pp->parent = initproc;
    80002296:	000a3503          	ld	a0,0(s4)
    8000229a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000229c:	00000097          	auipc	ra,0x0
    800022a0:	f4a080e7          	jalr	-182(ra) # 800021e6 <wakeup>
    800022a4:	b7d5                	j	80002288 <reparent+0x2c>
}
    800022a6:	70a2                	ld	ra,40(sp)
    800022a8:	7402                	ld	s0,32(sp)
    800022aa:	64e2                	ld	s1,24(sp)
    800022ac:	6942                	ld	s2,16(sp)
    800022ae:	69a2                	ld	s3,8(sp)
    800022b0:	6a02                	ld	s4,0(sp)
    800022b2:	6145                	addi	sp,sp,48
    800022b4:	8082                	ret

00000000800022b6 <exit>:
{
    800022b6:	7179                	addi	sp,sp,-48
    800022b8:	f406                	sd	ra,40(sp)
    800022ba:	f022                	sd	s0,32(sp)
    800022bc:	ec26                	sd	s1,24(sp)
    800022be:	e84a                	sd	s2,16(sp)
    800022c0:	e44e                	sd	s3,8(sp)
    800022c2:	e052                	sd	s4,0(sp)
    800022c4:	1800                	addi	s0,sp,48
    800022c6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	6ce080e7          	jalr	1742(ra) # 80001996 <myproc>
    800022d0:	89aa                	mv	s3,a0
  if(p == initproc)
    800022d2:	00007797          	auipc	a5,0x7
    800022d6:	d567b783          	ld	a5,-682(a5) # 80009028 <initproc>
    800022da:	0d050493          	addi	s1,a0,208
    800022de:	15050913          	addi	s2,a0,336
    800022e2:	02a79363          	bne	a5,a0,80002308 <exit+0x52>
    panic("init exiting");
    800022e6:	00006517          	auipc	a0,0x6
    800022ea:	f7a50513          	addi	a0,a0,-134 # 80008260 <digits+0x220>
    800022ee:	ffffe097          	auipc	ra,0xffffe
    800022f2:	24c080e7          	jalr	588(ra) # 8000053a <panic>
      fileclose(f);
    800022f6:	00002097          	auipc	ra,0x2
    800022fa:	38e080e7          	jalr	910(ra) # 80004684 <fileclose>
      p->ofile[fd] = 0;
    800022fe:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002302:	04a1                	addi	s1,s1,8
    80002304:	01248563          	beq	s1,s2,8000230e <exit+0x58>
    if(p->ofile[fd]){
    80002308:	6088                	ld	a0,0(s1)
    8000230a:	f575                	bnez	a0,800022f6 <exit+0x40>
    8000230c:	bfdd                	j	80002302 <exit+0x4c>
  begin_op();
    8000230e:	00002097          	auipc	ra,0x2
    80002312:	eae080e7          	jalr	-338(ra) # 800041bc <begin_op>
  iput(p->cwd);
    80002316:	1509b503          	ld	a0,336(s3)
    8000231a:	00001097          	auipc	ra,0x1
    8000231e:	680080e7          	jalr	1664(ra) # 8000399a <iput>
  end_op();
    80002322:	00002097          	auipc	ra,0x2
    80002326:	f18080e7          	jalr	-232(ra) # 8000423a <end_op>
  p->cwd = 0;
    8000232a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000232e:	0000f497          	auipc	s1,0xf
    80002332:	f8a48493          	addi	s1,s1,-118 # 800112b8 <wait_lock>
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	898080e7          	jalr	-1896(ra) # 80000bd0 <acquire>
  reparent(p);
    80002340:	854e                	mv	a0,s3
    80002342:	00000097          	auipc	ra,0x0
    80002346:	f1a080e7          	jalr	-230(ra) # 8000225c <reparent>
  wakeup(p->parent);
    8000234a:	0389b503          	ld	a0,56(s3)
    8000234e:	00000097          	auipc	ra,0x0
    80002352:	e98080e7          	jalr	-360(ra) # 800021e6 <wakeup>
  acquire(&p->lock);
    80002356:	854e                	mv	a0,s3
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	878080e7          	jalr	-1928(ra) # 80000bd0 <acquire>
  p->xstate = status;
    80002360:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002364:	4795                	li	a5,5
    80002366:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	918080e7          	jalr	-1768(ra) # 80000c84 <release>
  sched();
    80002374:	00000097          	auipc	ra,0x0
    80002378:	bd4080e7          	jalr	-1068(ra) # 80001f48 <sched>
  panic("zombie exit");
    8000237c:	00006517          	auipc	a0,0x6
    80002380:	ef450513          	addi	a0,a0,-268 # 80008270 <digits+0x230>
    80002384:	ffffe097          	auipc	ra,0xffffe
    80002388:	1b6080e7          	jalr	438(ra) # 8000053a <panic>

000000008000238c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000238c:	7179                	addi	sp,sp,-48
    8000238e:	f406                	sd	ra,40(sp)
    80002390:	f022                	sd	s0,32(sp)
    80002392:	ec26                	sd	s1,24(sp)
    80002394:	e84a                	sd	s2,16(sp)
    80002396:	e44e                	sd	s3,8(sp)
    80002398:	1800                	addi	s0,sp,48
    8000239a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000239c:	0000f497          	auipc	s1,0xf
    800023a0:	33448493          	addi	s1,s1,820 # 800116d0 <proc>
    800023a4:	00015997          	auipc	s3,0x15
    800023a8:	d2c98993          	addi	s3,s3,-724 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023ac:	8526                	mv	a0,s1
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	822080e7          	jalr	-2014(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800023b6:	589c                	lw	a5,48(s1)
    800023b8:	01278d63          	beq	a5,s2,800023d2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	8c6080e7          	jalr	-1850(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023c6:	16848493          	addi	s1,s1,360
    800023ca:	ff3491e3          	bne	s1,s3,800023ac <kill+0x20>
  }
  return -1;
    800023ce:	557d                	li	a0,-1
    800023d0:	a829                	j	800023ea <kill+0x5e>
      p->killed = 1;
    800023d2:	4785                	li	a5,1
    800023d4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023d6:	4c98                	lw	a4,24(s1)
    800023d8:	4789                	li	a5,2
    800023da:	00f70f63          	beq	a4,a5,800023f8 <kill+0x6c>
      release(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8a4080e7          	jalr	-1884(ra) # 80000c84 <release>
      return 0;
    800023e8:	4501                	li	a0,0
}
    800023ea:	70a2                	ld	ra,40(sp)
    800023ec:	7402                	ld	s0,32(sp)
    800023ee:	64e2                	ld	s1,24(sp)
    800023f0:	6942                	ld	s2,16(sp)
    800023f2:	69a2                	ld	s3,8(sp)
    800023f4:	6145                	addi	sp,sp,48
    800023f6:	8082                	ret
        p->state = RUNNABLE;
    800023f8:	478d                	li	a5,3
    800023fa:	cc9c                	sw	a5,24(s1)
    800023fc:	b7cd                	j	800023de <kill+0x52>

00000000800023fe <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023fe:	7179                	addi	sp,sp,-48
    80002400:	f406                	sd	ra,40(sp)
    80002402:	f022                	sd	s0,32(sp)
    80002404:	ec26                	sd	s1,24(sp)
    80002406:	e84a                	sd	s2,16(sp)
    80002408:	e44e                	sd	s3,8(sp)
    8000240a:	e052                	sd	s4,0(sp)
    8000240c:	1800                	addi	s0,sp,48
    8000240e:	84aa                	mv	s1,a0
    80002410:	892e                	mv	s2,a1
    80002412:	89b2                	mv	s3,a2
    80002414:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	580080e7          	jalr	1408(ra) # 80001996 <myproc>
  if(user_dst){
    8000241e:	c08d                	beqz	s1,80002440 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002420:	86d2                	mv	a3,s4
    80002422:	864e                	mv	a2,s3
    80002424:	85ca                	mv	a1,s2
    80002426:	6928                	ld	a0,80(a0)
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	232080e7          	jalr	562(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002430:	70a2                	ld	ra,40(sp)
    80002432:	7402                	ld	s0,32(sp)
    80002434:	64e2                	ld	s1,24(sp)
    80002436:	6942                	ld	s2,16(sp)
    80002438:	69a2                	ld	s3,8(sp)
    8000243a:	6a02                	ld	s4,0(sp)
    8000243c:	6145                	addi	sp,sp,48
    8000243e:	8082                	ret
    memmove((char *)dst, src, len);
    80002440:	000a061b          	sext.w	a2,s4
    80002444:	85ce                	mv	a1,s3
    80002446:	854a                	mv	a0,s2
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	8e0080e7          	jalr	-1824(ra) # 80000d28 <memmove>
    return 0;
    80002450:	8526                	mv	a0,s1
    80002452:	bff9                	j	80002430 <either_copyout+0x32>

0000000080002454 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002454:	7179                	addi	sp,sp,-48
    80002456:	f406                	sd	ra,40(sp)
    80002458:	f022                	sd	s0,32(sp)
    8000245a:	ec26                	sd	s1,24(sp)
    8000245c:	e84a                	sd	s2,16(sp)
    8000245e:	e44e                	sd	s3,8(sp)
    80002460:	e052                	sd	s4,0(sp)
    80002462:	1800                	addi	s0,sp,48
    80002464:	892a                	mv	s2,a0
    80002466:	84ae                	mv	s1,a1
    80002468:	89b2                	mv	s3,a2
    8000246a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	52a080e7          	jalr	1322(ra) # 80001996 <myproc>
  if(user_src){
    80002474:	c08d                	beqz	s1,80002496 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002476:	86d2                	mv	a3,s4
    80002478:	864e                	mv	a2,s3
    8000247a:	85ca                	mv	a1,s2
    8000247c:	6928                	ld	a0,80(a0)
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	268080e7          	jalr	616(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002486:	70a2                	ld	ra,40(sp)
    80002488:	7402                	ld	s0,32(sp)
    8000248a:	64e2                	ld	s1,24(sp)
    8000248c:	6942                	ld	s2,16(sp)
    8000248e:	69a2                	ld	s3,8(sp)
    80002490:	6a02                	ld	s4,0(sp)
    80002492:	6145                	addi	sp,sp,48
    80002494:	8082                	ret
    memmove(dst, (char*)src, len);
    80002496:	000a061b          	sext.w	a2,s4
    8000249a:	85ce                	mv	a1,s3
    8000249c:	854a                	mv	a0,s2
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	88a080e7          	jalr	-1910(ra) # 80000d28 <memmove>
    return 0;
    800024a6:	8526                	mv	a0,s1
    800024a8:	bff9                	j	80002486 <either_copyin+0x32>

00000000800024aa <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024aa:	715d                	addi	sp,sp,-80
    800024ac:	e486                	sd	ra,72(sp)
    800024ae:	e0a2                	sd	s0,64(sp)
    800024b0:	fc26                	sd	s1,56(sp)
    800024b2:	f84a                	sd	s2,48(sp)
    800024b4:	f44e                	sd	s3,40(sp)
    800024b6:	f052                	sd	s4,32(sp)
    800024b8:	ec56                	sd	s5,24(sp)
    800024ba:	e85a                	sd	s6,16(sp)
    800024bc:	e45e                	sd	s7,8(sp)
    800024be:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024c0:	00006517          	auipc	a0,0x6
    800024c4:	c0850513          	addi	a0,a0,-1016 # 800080c8 <digits+0x88>
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	0bc080e7          	jalr	188(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024d0:	0000f497          	auipc	s1,0xf
    800024d4:	35848493          	addi	s1,s1,856 # 80011828 <proc+0x158>
    800024d8:	00015917          	auipc	s2,0x15
    800024dc:	d5090913          	addi	s2,s2,-688 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024e0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024e2:	00006997          	auipc	s3,0x6
    800024e6:	d9e98993          	addi	s3,s3,-610 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800024ea:	00006a97          	auipc	s5,0x6
    800024ee:	d9ea8a93          	addi	s5,s5,-610 # 80008288 <digits+0x248>
    printf("\n");
    800024f2:	00006a17          	auipc	s4,0x6
    800024f6:	bd6a0a13          	addi	s4,s4,-1066 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024fa:	00006b97          	auipc	s7,0x6
    800024fe:	dc6b8b93          	addi	s7,s7,-570 # 800082c0 <states.0>
    80002502:	a00d                	j	80002524 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002504:	ed86a583          	lw	a1,-296(a3)
    80002508:	8556                	mv	a0,s5
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	07a080e7          	jalr	122(ra) # 80000584 <printf>
    printf("\n");
    80002512:	8552                	mv	a0,s4
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	070080e7          	jalr	112(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000251c:	16848493          	addi	s1,s1,360
    80002520:	03248263          	beq	s1,s2,80002544 <procdump+0x9a>
    if(p->state == UNUSED)
    80002524:	86a6                	mv	a3,s1
    80002526:	ec04a783          	lw	a5,-320(s1)
    8000252a:	dbed                	beqz	a5,8000251c <procdump+0x72>
      state = "???";
    8000252c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000252e:	fcfb6be3          	bltu	s6,a5,80002504 <procdump+0x5a>
    80002532:	02079713          	slli	a4,a5,0x20
    80002536:	01d75793          	srli	a5,a4,0x1d
    8000253a:	97de                	add	a5,a5,s7
    8000253c:	6390                	ld	a2,0(a5)
    8000253e:	f279                	bnez	a2,80002504 <procdump+0x5a>
      state = "???";
    80002540:	864e                	mv	a2,s3
    80002542:	b7c9                	j	80002504 <procdump+0x5a>
  }
}
    80002544:	60a6                	ld	ra,72(sp)
    80002546:	6406                	ld	s0,64(sp)
    80002548:	74e2                	ld	s1,56(sp)
    8000254a:	7942                	ld	s2,48(sp)
    8000254c:	79a2                	ld	s3,40(sp)
    8000254e:	7a02                	ld	s4,32(sp)
    80002550:	6ae2                	ld	s5,24(sp)
    80002552:	6b42                	ld	s6,16(sp)
    80002554:	6ba2                	ld	s7,8(sp)
    80002556:	6161                	addi	sp,sp,80
    80002558:	8082                	ret

000000008000255a <waitpid>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
waitpid(uint64 _pid, uint64 addr)
{
    8000255a:	711d                	addi	sp,sp,-96
    8000255c:	ec86                	sd	ra,88(sp)
    8000255e:	e8a2                	sd	s0,80(sp)
    80002560:	e4a6                	sd	s1,72(sp)
    80002562:	e0ca                	sd	s2,64(sp)
    80002564:	fc4e                	sd	s3,56(sp)
    80002566:	f852                	sd	s4,48(sp)
    80002568:	f456                	sd	s5,40(sp)
    8000256a:	f05a                	sd	s6,32(sp)
    8000256c:	ec5e                	sd	s7,24(sp)
    8000256e:	e862                	sd	s8,16(sp)
    80002570:	e466                	sd	s9,8(sp)
    80002572:	1080                	addi	s0,sp,96
    80002574:	892a                	mv	s2,a0
    80002576:	8bae                	mv	s7,a1
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002578:	fffff097          	auipc	ra,0xfffff
    8000257c:	41e080e7          	jalr	1054(ra) # 80001996 <myproc>
    80002580:	8a2a                	mv	s4,a0

  acquire(&wait_lock);
    80002582:	0000f517          	auipc	a0,0xf
    80002586:	d3650513          	addi	a0,a0,-714 # 800112b8 <wait_lock>
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	646080e7          	jalr	1606(ra) # 80000bd0 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    80002592:	4c01                	li	s8,0
      if((np->pid == _pid) && (np->parent == p)){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    80002594:	4a95                	li	s5,5
        havekids = 1;
    80002596:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002598:	00015997          	auipc	s3,0x15
    8000259c:	b3898993          	addi	s3,s3,-1224 # 800170d0 <tickslock>
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025a0:	0000fc97          	auipc	s9,0xf
    800025a4:	d18c8c93          	addi	s9,s9,-744 # 800112b8 <wait_lock>
    havekids = 0;
    800025a8:	8762                	mv	a4,s8
    for(np = proc; np < &proc[NPROC]; np++){
    800025aa:	0000f497          	auipc	s1,0xf
    800025ae:	12648493          	addi	s1,s1,294 # 800116d0 <proc>
    800025b2:	a0bd                	j	80002620 <waitpid+0xc6>
          pid = np->pid;
    800025b4:	0304a903          	lw	s2,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025b8:	000b8e63          	beqz	s7,800025d4 <waitpid+0x7a>
    800025bc:	4691                	li	a3,4
    800025be:	02c48613          	addi	a2,s1,44
    800025c2:	85de                	mv	a1,s7
    800025c4:	050a3503          	ld	a0,80(s4)
    800025c8:	fffff097          	auipc	ra,0xfffff
    800025cc:	092080e7          	jalr	146(ra) # 8000165a <copyout>
    800025d0:	02054563          	bltz	a0,800025fa <waitpid+0xa0>
          freeproc(np);
    800025d4:	8526                	mv	a0,s1
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	572080e7          	jalr	1394(ra) # 80001b48 <freeproc>
          release(&np->lock);
    800025de:	8526                	mv	a0,s1
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	6a4080e7          	jalr	1700(ra) # 80000c84 <release>
          release(&wait_lock);
    800025e8:	0000f517          	auipc	a0,0xf
    800025ec:	cd050513          	addi	a0,a0,-816 # 800112b8 <wait_lock>
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	694080e7          	jalr	1684(ra) # 80000c84 <release>
          return pid;
    800025f8:	a0b5                	j	80002664 <waitpid+0x10a>
            release(&np->lock);
    800025fa:	8526                	mv	a0,s1
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	688080e7          	jalr	1672(ra) # 80000c84 <release>
            release(&wait_lock);
    80002604:	0000f517          	auipc	a0,0xf
    80002608:	cb450513          	addi	a0,a0,-844 # 800112b8 <wait_lock>
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	678080e7          	jalr	1656(ra) # 80000c84 <release>
            return -1;
    80002614:	597d                	li	s2,-1
    80002616:	a0b9                	j	80002664 <waitpid+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    80002618:	16848493          	addi	s1,s1,360
    8000261c:	03348763          	beq	s1,s3,8000264a <waitpid+0xf0>
      if((np->pid == _pid) && (np->parent == p)){
    80002620:	589c                	lw	a5,48(s1)
    80002622:	ff279be3          	bne	a5,s2,80002618 <waitpid+0xbe>
    80002626:	7c9c                	ld	a5,56(s1)
    80002628:	ff4798e3          	bne	a5,s4,80002618 <waitpid+0xbe>
        acquire(&np->lock);
    8000262c:	8526                	mv	a0,s1
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	5a2080e7          	jalr	1442(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002636:	4c9c                	lw	a5,24(s1)
    80002638:	f7578ee3          	beq	a5,s5,800025b4 <waitpid+0x5a>
        release(&np->lock);
    8000263c:	8526                	mv	a0,s1
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	646080e7          	jalr	1606(ra) # 80000c84 <release>
        havekids = 1;
    80002646:	875a                	mv	a4,s6
    80002648:	bfc1                	j	80002618 <waitpid+0xbe>
    if(!havekids || p->killed){
    8000264a:	c701                	beqz	a4,80002652 <waitpid+0xf8>
    8000264c:	028a2783          	lw	a5,40(s4)
    80002650:	cb85                	beqz	a5,80002680 <waitpid+0x126>
      release(&wait_lock);
    80002652:	0000f517          	auipc	a0,0xf
    80002656:	c6650513          	addi	a0,a0,-922 # 800112b8 <wait_lock>
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	62a080e7          	jalr	1578(ra) # 80000c84 <release>
      return -1;
    80002662:	597d                	li	s2,-1
  }
}
    80002664:	854a                	mv	a0,s2
    80002666:	60e6                	ld	ra,88(sp)
    80002668:	6446                	ld	s0,80(sp)
    8000266a:	64a6                	ld	s1,72(sp)
    8000266c:	6906                	ld	s2,64(sp)
    8000266e:	79e2                	ld	s3,56(sp)
    80002670:	7a42                	ld	s4,48(sp)
    80002672:	7aa2                	ld	s5,40(sp)
    80002674:	7b02                	ld	s6,32(sp)
    80002676:	6be2                	ld	s7,24(sp)
    80002678:	6c42                	ld	s8,16(sp)
    8000267a:	6ca2                	ld	s9,8(sp)
    8000267c:	6125                	addi	sp,sp,96
    8000267e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002680:	85e6                	mv	a1,s9
    80002682:	8552                	mv	a0,s4
    80002684:	00000097          	auipc	ra,0x0
    80002688:	9d6080e7          	jalr	-1578(ra) # 8000205a <sleep>
    havekids = 0;
    8000268c:	bf31                	j	800025a8 <waitpid+0x4e>

000000008000268e <swtch>:
    8000268e:	00153023          	sd	ra,0(a0)
    80002692:	00253423          	sd	sp,8(a0)
    80002696:	e900                	sd	s0,16(a0)
    80002698:	ed04                	sd	s1,24(a0)
    8000269a:	03253023          	sd	s2,32(a0)
    8000269e:	03353423          	sd	s3,40(a0)
    800026a2:	03453823          	sd	s4,48(a0)
    800026a6:	03553c23          	sd	s5,56(a0)
    800026aa:	05653023          	sd	s6,64(a0)
    800026ae:	05753423          	sd	s7,72(a0)
    800026b2:	05853823          	sd	s8,80(a0)
    800026b6:	05953c23          	sd	s9,88(a0)
    800026ba:	07a53023          	sd	s10,96(a0)
    800026be:	07b53423          	sd	s11,104(a0)
    800026c2:	0005b083          	ld	ra,0(a1)
    800026c6:	0085b103          	ld	sp,8(a1)
    800026ca:	6980                	ld	s0,16(a1)
    800026cc:	6d84                	ld	s1,24(a1)
    800026ce:	0205b903          	ld	s2,32(a1)
    800026d2:	0285b983          	ld	s3,40(a1)
    800026d6:	0305ba03          	ld	s4,48(a1)
    800026da:	0385ba83          	ld	s5,56(a1)
    800026de:	0405bb03          	ld	s6,64(a1)
    800026e2:	0485bb83          	ld	s7,72(a1)
    800026e6:	0505bc03          	ld	s8,80(a1)
    800026ea:	0585bc83          	ld	s9,88(a1)
    800026ee:	0605bd03          	ld	s10,96(a1)
    800026f2:	0685bd83          	ld	s11,104(a1)
    800026f6:	8082                	ret

00000000800026f8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f8:	1141                	addi	sp,sp,-16
    800026fa:	e406                	sd	ra,8(sp)
    800026fc:	e022                	sd	s0,0(sp)
    800026fe:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002700:	00006597          	auipc	a1,0x6
    80002704:	bf058593          	addi	a1,a1,-1040 # 800082f0 <states.0+0x30>
    80002708:	00015517          	auipc	a0,0x15
    8000270c:	9c850513          	addi	a0,a0,-1592 # 800170d0 <tickslock>
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	430080e7          	jalr	1072(ra) # 80000b40 <initlock>
}
    80002718:	60a2                	ld	ra,8(sp)
    8000271a:	6402                	ld	s0,0(sp)
    8000271c:	0141                	addi	sp,sp,16
    8000271e:	8082                	ret

0000000080002720 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002720:	1141                	addi	sp,sp,-16
    80002722:	e422                	sd	s0,8(sp)
    80002724:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002726:	00003797          	auipc	a5,0x3
    8000272a:	58a78793          	addi	a5,a5,1418 # 80005cb0 <kernelvec>
    8000272e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002732:	6422                	ld	s0,8(sp)
    80002734:	0141                	addi	sp,sp,16
    80002736:	8082                	ret

0000000080002738 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002738:	1141                	addi	sp,sp,-16
    8000273a:	e406                	sd	ra,8(sp)
    8000273c:	e022                	sd	s0,0(sp)
    8000273e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002740:	fffff097          	auipc	ra,0xfffff
    80002744:	256080e7          	jalr	598(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002748:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000274c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000274e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002752:	00005697          	auipc	a3,0x5
    80002756:	8ae68693          	addi	a3,a3,-1874 # 80007000 <_trampoline>
    8000275a:	00005717          	auipc	a4,0x5
    8000275e:	8a670713          	addi	a4,a4,-1882 # 80007000 <_trampoline>
    80002762:	8f15                	sub	a4,a4,a3
    80002764:	040007b7          	lui	a5,0x4000
    80002768:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000276a:	07b2                	slli	a5,a5,0xc
    8000276c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000276e:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002772:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002774:	18002673          	csrr	a2,satp
    80002778:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000277a:	6d30                	ld	a2,88(a0)
    8000277c:	6138                	ld	a4,64(a0)
    8000277e:	6585                	lui	a1,0x1
    80002780:	972e                	add	a4,a4,a1
    80002782:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002784:	6d38                	ld	a4,88(a0)
    80002786:	00000617          	auipc	a2,0x0
    8000278a:	13860613          	addi	a2,a2,312 # 800028be <usertrap>
    8000278e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002790:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002792:	8612                	mv	a2,tp
    80002794:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002796:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000279a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000279e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027a2:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a8:	6f18                	ld	a4,24(a4)
    800027aa:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027ae:	692c                	ld	a1,80(a0)
    800027b0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027b2:	00005717          	auipc	a4,0x5
    800027b6:	8de70713          	addi	a4,a4,-1826 # 80007090 <userret>
    800027ba:	8f15                	sub	a4,a4,a3
    800027bc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027be:	577d                	li	a4,-1
    800027c0:	177e                	slli	a4,a4,0x3f
    800027c2:	8dd9                	or	a1,a1,a4
    800027c4:	02000537          	lui	a0,0x2000
    800027c8:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800027ca:	0536                	slli	a0,a0,0xd
    800027cc:	9782                	jalr	a5
}
    800027ce:	60a2                	ld	ra,8(sp)
    800027d0:	6402                	ld	s0,0(sp)
    800027d2:	0141                	addi	sp,sp,16
    800027d4:	8082                	ret

00000000800027d6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027d6:	1101                	addi	sp,sp,-32
    800027d8:	ec06                	sd	ra,24(sp)
    800027da:	e822                	sd	s0,16(sp)
    800027dc:	e426                	sd	s1,8(sp)
    800027de:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027e0:	00015497          	auipc	s1,0x15
    800027e4:	8f048493          	addi	s1,s1,-1808 # 800170d0 <tickslock>
    800027e8:	8526                	mv	a0,s1
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	3e6080e7          	jalr	998(ra) # 80000bd0 <acquire>
  ticks++;
    800027f2:	00007517          	auipc	a0,0x7
    800027f6:	83e50513          	addi	a0,a0,-1986 # 80009030 <ticks>
    800027fa:	411c                	lw	a5,0(a0)
    800027fc:	2785                	addiw	a5,a5,1
    800027fe:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002800:	00000097          	auipc	ra,0x0
    80002804:	9e6080e7          	jalr	-1562(ra) # 800021e6 <wakeup>
  release(&tickslock);
    80002808:	8526                	mv	a0,s1
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	47a080e7          	jalr	1146(ra) # 80000c84 <release>
}
    80002812:	60e2                	ld	ra,24(sp)
    80002814:	6442                	ld	s0,16(sp)
    80002816:	64a2                	ld	s1,8(sp)
    80002818:	6105                	addi	sp,sp,32
    8000281a:	8082                	ret

000000008000281c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000281c:	1101                	addi	sp,sp,-32
    8000281e:	ec06                	sd	ra,24(sp)
    80002820:	e822                	sd	s0,16(sp)
    80002822:	e426                	sd	s1,8(sp)
    80002824:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002826:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000282a:	00074d63          	bltz	a4,80002844 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000282e:	57fd                	li	a5,-1
    80002830:	17fe                	slli	a5,a5,0x3f
    80002832:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002834:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002836:	06f70363          	beq	a4,a5,8000289c <devintr+0x80>
  }
}
    8000283a:	60e2                	ld	ra,24(sp)
    8000283c:	6442                	ld	s0,16(sp)
    8000283e:	64a2                	ld	s1,8(sp)
    80002840:	6105                	addi	sp,sp,32
    80002842:	8082                	ret
     (scause & 0xff) == 9){
    80002844:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002848:	46a5                	li	a3,9
    8000284a:	fed792e3          	bne	a5,a3,8000282e <devintr+0x12>
    int irq = plic_claim();
    8000284e:	00003097          	auipc	ra,0x3
    80002852:	56a080e7          	jalr	1386(ra) # 80005db8 <plic_claim>
    80002856:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002858:	47a9                	li	a5,10
    8000285a:	02f50763          	beq	a0,a5,80002888 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000285e:	4785                	li	a5,1
    80002860:	02f50963          	beq	a0,a5,80002892 <devintr+0x76>
    return 1;
    80002864:	4505                	li	a0,1
    } else if(irq){
    80002866:	d8f1                	beqz	s1,8000283a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002868:	85a6                	mv	a1,s1
    8000286a:	00006517          	auipc	a0,0x6
    8000286e:	a8e50513          	addi	a0,a0,-1394 # 800082f8 <states.0+0x38>
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	d12080e7          	jalr	-750(ra) # 80000584 <printf>
      plic_complete(irq);
    8000287a:	8526                	mv	a0,s1
    8000287c:	00003097          	auipc	ra,0x3
    80002880:	560080e7          	jalr	1376(ra) # 80005ddc <plic_complete>
    return 1;
    80002884:	4505                	li	a0,1
    80002886:	bf55                	j	8000283a <devintr+0x1e>
      uartintr();
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	10a080e7          	jalr	266(ra) # 80000992 <uartintr>
    80002890:	b7ed                	j	8000287a <devintr+0x5e>
      virtio_disk_intr();
    80002892:	00004097          	auipc	ra,0x4
    80002896:	9d6080e7          	jalr	-1578(ra) # 80006268 <virtio_disk_intr>
    8000289a:	b7c5                	j	8000287a <devintr+0x5e>
    if(cpuid() == 0){
    8000289c:	fffff097          	auipc	ra,0xfffff
    800028a0:	0ce080e7          	jalr	206(ra) # 8000196a <cpuid>
    800028a4:	c901                	beqz	a0,800028b4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028a6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028aa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028ac:	14479073          	csrw	sip,a5
    return 2;
    800028b0:	4509                	li	a0,2
    800028b2:	b761                	j	8000283a <devintr+0x1e>
      clockintr();
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	f22080e7          	jalr	-222(ra) # 800027d6 <clockintr>
    800028bc:	b7ed                	j	800028a6 <devintr+0x8a>

00000000800028be <usertrap>:
{
    800028be:	1101                	addi	sp,sp,-32
    800028c0:	ec06                	sd	ra,24(sp)
    800028c2:	e822                	sd	s0,16(sp)
    800028c4:	e426                	sd	s1,8(sp)
    800028c6:	e04a                	sd	s2,0(sp)
    800028c8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ca:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028ce:	1007f793          	andi	a5,a5,256
    800028d2:	e3ad                	bnez	a5,80002934 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d4:	00003797          	auipc	a5,0x3
    800028d8:	3dc78793          	addi	a5,a5,988 # 80005cb0 <kernelvec>
    800028dc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028e0:	fffff097          	auipc	ra,0xfffff
    800028e4:	0b6080e7          	jalr	182(ra) # 80001996 <myproc>
    800028e8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ea:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ec:	14102773          	csrr	a4,sepc
    800028f0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028f6:	47a1                	li	a5,8
    800028f8:	04f71c63          	bne	a4,a5,80002950 <usertrap+0x92>
    if(p->killed)
    800028fc:	551c                	lw	a5,40(a0)
    800028fe:	e3b9                	bnez	a5,80002944 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002900:	6cb8                	ld	a4,88(s1)
    80002902:	6f1c                	ld	a5,24(a4)
    80002904:	0791                	addi	a5,a5,4
    80002906:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002908:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002910:	10079073          	csrw	sstatus,a5
    syscall();
    80002914:	00000097          	auipc	ra,0x0
    80002918:	2e0080e7          	jalr	736(ra) # 80002bf4 <syscall>
  if(p->killed)
    8000291c:	549c                	lw	a5,40(s1)
    8000291e:	ebc1                	bnez	a5,800029ae <usertrap+0xf0>
  usertrapret();
    80002920:	00000097          	auipc	ra,0x0
    80002924:	e18080e7          	jalr	-488(ra) # 80002738 <usertrapret>
}
    80002928:	60e2                	ld	ra,24(sp)
    8000292a:	6442                	ld	s0,16(sp)
    8000292c:	64a2                	ld	s1,8(sp)
    8000292e:	6902                	ld	s2,0(sp)
    80002930:	6105                	addi	sp,sp,32
    80002932:	8082                	ret
    panic("usertrap: not from user mode");
    80002934:	00006517          	auipc	a0,0x6
    80002938:	9e450513          	addi	a0,a0,-1564 # 80008318 <states.0+0x58>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	bfe080e7          	jalr	-1026(ra) # 8000053a <panic>
      exit(-1);
    80002944:	557d                	li	a0,-1
    80002946:	00000097          	auipc	ra,0x0
    8000294a:	970080e7          	jalr	-1680(ra) # 800022b6 <exit>
    8000294e:	bf4d                	j	80002900 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002950:	00000097          	auipc	ra,0x0
    80002954:	ecc080e7          	jalr	-308(ra) # 8000281c <devintr>
    80002958:	892a                	mv	s2,a0
    8000295a:	c501                	beqz	a0,80002962 <usertrap+0xa4>
  if(p->killed)
    8000295c:	549c                	lw	a5,40(s1)
    8000295e:	c3a1                	beqz	a5,8000299e <usertrap+0xe0>
    80002960:	a815                	j	80002994 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002962:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002966:	5890                	lw	a2,48(s1)
    80002968:	00006517          	auipc	a0,0x6
    8000296c:	9d050513          	addi	a0,a0,-1584 # 80008338 <states.0+0x78>
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	c14080e7          	jalr	-1004(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002978:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000297c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002980:	00006517          	auipc	a0,0x6
    80002984:	9e850513          	addi	a0,a0,-1560 # 80008368 <states.0+0xa8>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	bfc080e7          	jalr	-1028(ra) # 80000584 <printf>
    p->killed = 1;
    80002990:	4785                	li	a5,1
    80002992:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002994:	557d                	li	a0,-1
    80002996:	00000097          	auipc	ra,0x0
    8000299a:	920080e7          	jalr	-1760(ra) # 800022b6 <exit>
  if(which_dev == 2)
    8000299e:	4789                	li	a5,2
    800029a0:	f8f910e3          	bne	s2,a5,80002920 <usertrap+0x62>
    yield();
    800029a4:	fffff097          	auipc	ra,0xfffff
    800029a8:	67a080e7          	jalr	1658(ra) # 8000201e <yield>
    800029ac:	bf95                	j	80002920 <usertrap+0x62>
  int which_dev = 0;
    800029ae:	4901                	li	s2,0
    800029b0:	b7d5                	j	80002994 <usertrap+0xd6>

00000000800029b2 <kerneltrap>:
{
    800029b2:	7179                	addi	sp,sp,-48
    800029b4:	f406                	sd	ra,40(sp)
    800029b6:	f022                	sd	s0,32(sp)
    800029b8:	ec26                	sd	s1,24(sp)
    800029ba:	e84a                	sd	s2,16(sp)
    800029bc:	e44e                	sd	s3,8(sp)
    800029be:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029c0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029cc:	1004f793          	andi	a5,s1,256
    800029d0:	cb85                	beqz	a5,80002a00 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029d6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029d8:	ef85                	bnez	a5,80002a10 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029da:	00000097          	auipc	ra,0x0
    800029de:	e42080e7          	jalr	-446(ra) # 8000281c <devintr>
    800029e2:	cd1d                	beqz	a0,80002a20 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029e4:	4789                	li	a5,2
    800029e6:	06f50a63          	beq	a0,a5,80002a5a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029ea:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ee:	10049073          	csrw	sstatus,s1
}
    800029f2:	70a2                	ld	ra,40(sp)
    800029f4:	7402                	ld	s0,32(sp)
    800029f6:	64e2                	ld	s1,24(sp)
    800029f8:	6942                	ld	s2,16(sp)
    800029fa:	69a2                	ld	s3,8(sp)
    800029fc:	6145                	addi	sp,sp,48
    800029fe:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a00:	00006517          	auipc	a0,0x6
    80002a04:	98850513          	addi	a0,a0,-1656 # 80008388 <states.0+0xc8>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	b32080e7          	jalr	-1230(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002a10:	00006517          	auipc	a0,0x6
    80002a14:	9a050513          	addi	a0,a0,-1632 # 800083b0 <states.0+0xf0>
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	b22080e7          	jalr	-1246(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002a20:	85ce                	mv	a1,s3
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	9ae50513          	addi	a0,a0,-1618 # 800083d0 <states.0+0x110>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	b5a080e7          	jalr	-1190(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a32:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a36:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	9a650513          	addi	a0,a0,-1626 # 800083e0 <states.0+0x120>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b42080e7          	jalr	-1214(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002a4a:	00006517          	auipc	a0,0x6
    80002a4e:	9ae50513          	addi	a0,a0,-1618 # 800083f8 <states.0+0x138>
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	ae8080e7          	jalr	-1304(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a5a:	fffff097          	auipc	ra,0xfffff
    80002a5e:	f3c080e7          	jalr	-196(ra) # 80001996 <myproc>
    80002a62:	d541                	beqz	a0,800029ea <kerneltrap+0x38>
    80002a64:	fffff097          	auipc	ra,0xfffff
    80002a68:	f32080e7          	jalr	-206(ra) # 80001996 <myproc>
    80002a6c:	4d18                	lw	a4,24(a0)
    80002a6e:	4791                	li	a5,4
    80002a70:	f6f71de3          	bne	a4,a5,800029ea <kerneltrap+0x38>
    yield();
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	5aa080e7          	jalr	1450(ra) # 8000201e <yield>
    80002a7c:	b7bd                	j	800029ea <kerneltrap+0x38>

0000000080002a7e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a7e:	1101                	addi	sp,sp,-32
    80002a80:	ec06                	sd	ra,24(sp)
    80002a82:	e822                	sd	s0,16(sp)
    80002a84:	e426                	sd	s1,8(sp)
    80002a86:	1000                	addi	s0,sp,32
    80002a88:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	f0c080e7          	jalr	-244(ra) # 80001996 <myproc>
  switch (n) {
    80002a92:	4795                	li	a5,5
    80002a94:	0497e163          	bltu	a5,s1,80002ad6 <argraw+0x58>
    80002a98:	048a                	slli	s1,s1,0x2
    80002a9a:	00006717          	auipc	a4,0x6
    80002a9e:	99670713          	addi	a4,a4,-1642 # 80008430 <states.0+0x170>
    80002aa2:	94ba                	add	s1,s1,a4
    80002aa4:	409c                	lw	a5,0(s1)
    80002aa6:	97ba                	add	a5,a5,a4
    80002aa8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aaa:	6d3c                	ld	a5,88(a0)
    80002aac:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aae:	60e2                	ld	ra,24(sp)
    80002ab0:	6442                	ld	s0,16(sp)
    80002ab2:	64a2                	ld	s1,8(sp)
    80002ab4:	6105                	addi	sp,sp,32
    80002ab6:	8082                	ret
    return p->trapframe->a1;
    80002ab8:	6d3c                	ld	a5,88(a0)
    80002aba:	7fa8                	ld	a0,120(a5)
    80002abc:	bfcd                	j	80002aae <argraw+0x30>
    return p->trapframe->a2;
    80002abe:	6d3c                	ld	a5,88(a0)
    80002ac0:	63c8                	ld	a0,128(a5)
    80002ac2:	b7f5                	j	80002aae <argraw+0x30>
    return p->trapframe->a3;
    80002ac4:	6d3c                	ld	a5,88(a0)
    80002ac6:	67c8                	ld	a0,136(a5)
    80002ac8:	b7dd                	j	80002aae <argraw+0x30>
    return p->trapframe->a4;
    80002aca:	6d3c                	ld	a5,88(a0)
    80002acc:	6bc8                	ld	a0,144(a5)
    80002ace:	b7c5                	j	80002aae <argraw+0x30>
    return p->trapframe->a5;
    80002ad0:	6d3c                	ld	a5,88(a0)
    80002ad2:	6fc8                	ld	a0,152(a5)
    80002ad4:	bfe9                	j	80002aae <argraw+0x30>
  panic("argraw");
    80002ad6:	00006517          	auipc	a0,0x6
    80002ada:	93250513          	addi	a0,a0,-1742 # 80008408 <states.0+0x148>
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	a5c080e7          	jalr	-1444(ra) # 8000053a <panic>

0000000080002ae6 <fetchaddr>:
{
    80002ae6:	1101                	addi	sp,sp,-32
    80002ae8:	ec06                	sd	ra,24(sp)
    80002aea:	e822                	sd	s0,16(sp)
    80002aec:	e426                	sd	s1,8(sp)
    80002aee:	e04a                	sd	s2,0(sp)
    80002af0:	1000                	addi	s0,sp,32
    80002af2:	84aa                	mv	s1,a0
    80002af4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	ea0080e7          	jalr	-352(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002afe:	653c                	ld	a5,72(a0)
    80002b00:	02f4f863          	bgeu	s1,a5,80002b30 <fetchaddr+0x4a>
    80002b04:	00848713          	addi	a4,s1,8
    80002b08:	02e7e663          	bltu	a5,a4,80002b34 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b0c:	46a1                	li	a3,8
    80002b0e:	8626                	mv	a2,s1
    80002b10:	85ca                	mv	a1,s2
    80002b12:	6928                	ld	a0,80(a0)
    80002b14:	fffff097          	auipc	ra,0xfffff
    80002b18:	bd2080e7          	jalr	-1070(ra) # 800016e6 <copyin>
    80002b1c:	00a03533          	snez	a0,a0
    80002b20:	40a00533          	neg	a0,a0
}
    80002b24:	60e2                	ld	ra,24(sp)
    80002b26:	6442                	ld	s0,16(sp)
    80002b28:	64a2                	ld	s1,8(sp)
    80002b2a:	6902                	ld	s2,0(sp)
    80002b2c:	6105                	addi	sp,sp,32
    80002b2e:	8082                	ret
    return -1;
    80002b30:	557d                	li	a0,-1
    80002b32:	bfcd                	j	80002b24 <fetchaddr+0x3e>
    80002b34:	557d                	li	a0,-1
    80002b36:	b7fd                	j	80002b24 <fetchaddr+0x3e>

0000000080002b38 <fetchstr>:
{
    80002b38:	7179                	addi	sp,sp,-48
    80002b3a:	f406                	sd	ra,40(sp)
    80002b3c:	f022                	sd	s0,32(sp)
    80002b3e:	ec26                	sd	s1,24(sp)
    80002b40:	e84a                	sd	s2,16(sp)
    80002b42:	e44e                	sd	s3,8(sp)
    80002b44:	1800                	addi	s0,sp,48
    80002b46:	892a                	mv	s2,a0
    80002b48:	84ae                	mv	s1,a1
    80002b4a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	e4a080e7          	jalr	-438(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b54:	86ce                	mv	a3,s3
    80002b56:	864a                	mv	a2,s2
    80002b58:	85a6                	mv	a1,s1
    80002b5a:	6928                	ld	a0,80(a0)
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	c18080e7          	jalr	-1000(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002b64:	00054763          	bltz	a0,80002b72 <fetchstr+0x3a>
  return strlen(buf);
    80002b68:	8526                	mv	a0,s1
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	2de080e7          	jalr	734(ra) # 80000e48 <strlen>
}
    80002b72:	70a2                	ld	ra,40(sp)
    80002b74:	7402                	ld	s0,32(sp)
    80002b76:	64e2                	ld	s1,24(sp)
    80002b78:	6942                	ld	s2,16(sp)
    80002b7a:	69a2                	ld	s3,8(sp)
    80002b7c:	6145                	addi	sp,sp,48
    80002b7e:	8082                	ret

0000000080002b80 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b80:	1101                	addi	sp,sp,-32
    80002b82:	ec06                	sd	ra,24(sp)
    80002b84:	e822                	sd	s0,16(sp)
    80002b86:	e426                	sd	s1,8(sp)
    80002b88:	1000                	addi	s0,sp,32
    80002b8a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	ef2080e7          	jalr	-270(ra) # 80002a7e <argraw>
    80002b94:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b96:	4501                	li	a0,0
    80002b98:	60e2                	ld	ra,24(sp)
    80002b9a:	6442                	ld	s0,16(sp)
    80002b9c:	64a2                	ld	s1,8(sp)
    80002b9e:	6105                	addi	sp,sp,32
    80002ba0:	8082                	ret

0000000080002ba2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ba2:	1101                	addi	sp,sp,-32
    80002ba4:	ec06                	sd	ra,24(sp)
    80002ba6:	e822                	sd	s0,16(sp)
    80002ba8:	e426                	sd	s1,8(sp)
    80002baa:	1000                	addi	s0,sp,32
    80002bac:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	ed0080e7          	jalr	-304(ra) # 80002a7e <argraw>
    80002bb6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bb8:	4501                	li	a0,0
    80002bba:	60e2                	ld	ra,24(sp)
    80002bbc:	6442                	ld	s0,16(sp)
    80002bbe:	64a2                	ld	s1,8(sp)
    80002bc0:	6105                	addi	sp,sp,32
    80002bc2:	8082                	ret

0000000080002bc4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bc4:	1101                	addi	sp,sp,-32
    80002bc6:	ec06                	sd	ra,24(sp)
    80002bc8:	e822                	sd	s0,16(sp)
    80002bca:	e426                	sd	s1,8(sp)
    80002bcc:	e04a                	sd	s2,0(sp)
    80002bce:	1000                	addi	s0,sp,32
    80002bd0:	84ae                	mv	s1,a1
    80002bd2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	eaa080e7          	jalr	-342(ra) # 80002a7e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bdc:	864a                	mv	a2,s2
    80002bde:	85a6                	mv	a1,s1
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	f58080e7          	jalr	-168(ra) # 80002b38 <fetchstr>
}
    80002be8:	60e2                	ld	ra,24(sp)
    80002bea:	6442                	ld	s0,16(sp)
    80002bec:	64a2                	ld	s1,8(sp)
    80002bee:	6902                	ld	s2,0(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret

0000000080002bf4 <syscall>:
[SYS_waitpid] sys_waitpid,
};

void
syscall(void)
{
    80002bf4:	1101                	addi	sp,sp,-32
    80002bf6:	ec06                	sd	ra,24(sp)
    80002bf8:	e822                	sd	s0,16(sp)
    80002bfa:	e426                	sd	s1,8(sp)
    80002bfc:	e04a                	sd	s2,0(sp)
    80002bfe:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	d96080e7          	jalr	-618(ra) # 80001996 <myproc>
    80002c08:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c0a:	05853903          	ld	s2,88(a0)
    80002c0e:	0a893783          	ld	a5,168(s2)
    80002c12:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c16:	37fd                	addiw	a5,a5,-1
    80002c18:	4761                	li	a4,24
    80002c1a:	00f76f63          	bltu	a4,a5,80002c38 <syscall+0x44>
    80002c1e:	00369713          	slli	a4,a3,0x3
    80002c22:	00006797          	auipc	a5,0x6
    80002c26:	82678793          	addi	a5,a5,-2010 # 80008448 <syscalls>
    80002c2a:	97ba                	add	a5,a5,a4
    80002c2c:	639c                	ld	a5,0(a5)
    80002c2e:	c789                	beqz	a5,80002c38 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c30:	9782                	jalr	a5
    80002c32:	06a93823          	sd	a0,112(s2)
    80002c36:	a839                	j	80002c54 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c38:	15848613          	addi	a2,s1,344
    80002c3c:	588c                	lw	a1,48(s1)
    80002c3e:	00005517          	auipc	a0,0x5
    80002c42:	7d250513          	addi	a0,a0,2002 # 80008410 <states.0+0x150>
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	93e080e7          	jalr	-1730(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c4e:	6cbc                	ld	a5,88(s1)
    80002c50:	577d                	li	a4,-1
    80002c52:	fbb8                	sd	a4,112(a5)
  }
}
    80002c54:	60e2                	ld	ra,24(sp)
    80002c56:	6442                	ld	s0,16(sp)
    80002c58:	64a2                	ld	s1,8(sp)
    80002c5a:	6902                	ld	s2,0(sp)
    80002c5c:	6105                	addi	sp,sp,32
    80002c5e:	8082                	ret

0000000080002c60 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c60:	1101                	addi	sp,sp,-32
    80002c62:	ec06                	sd	ra,24(sp)
    80002c64:	e822                	sd	s0,16(sp)
    80002c66:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c68:	fec40593          	addi	a1,s0,-20
    80002c6c:	4501                	li	a0,0
    80002c6e:	00000097          	auipc	ra,0x0
    80002c72:	f12080e7          	jalr	-238(ra) # 80002b80 <argint>
    return -1;
    80002c76:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c78:	00054963          	bltz	a0,80002c8a <sys_exit+0x2a>
  exit(n);
    80002c7c:	fec42503          	lw	a0,-20(s0)
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	636080e7          	jalr	1590(ra) # 800022b6 <exit>
  return 0;  // not reached
    80002c88:	4781                	li	a5,0
}
    80002c8a:	853e                	mv	a0,a5
    80002c8c:	60e2                	ld	ra,24(sp)
    80002c8e:	6442                	ld	s0,16(sp)
    80002c90:	6105                	addi	sp,sp,32
    80002c92:	8082                	ret

0000000080002c94 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c94:	1141                	addi	sp,sp,-16
    80002c96:	e406                	sd	ra,8(sp)
    80002c98:	e022                	sd	s0,0(sp)
    80002c9a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	cfa080e7          	jalr	-774(ra) # 80001996 <myproc>
}
    80002ca4:	5908                	lw	a0,48(a0)
    80002ca6:	60a2                	ld	ra,8(sp)
    80002ca8:	6402                	ld	s0,0(sp)
    80002caa:	0141                	addi	sp,sp,16
    80002cac:	8082                	ret

0000000080002cae <sys_fork>:

uint64
sys_fork(void)
{
    80002cae:	1141                	addi	sp,sp,-16
    80002cb0:	e406                	sd	ra,8(sp)
    80002cb2:	e022                	sd	s0,0(sp)
    80002cb4:	0800                	addi	s0,sp,16
  return fork();
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	0b2080e7          	jalr	178(ra) # 80001d68 <fork>
}
    80002cbe:	60a2                	ld	ra,8(sp)
    80002cc0:	6402                	ld	s0,0(sp)
    80002cc2:	0141                	addi	sp,sp,16
    80002cc4:	8082                	ret

0000000080002cc6 <sys_wait>:

uint64
sys_wait(void)
{
    80002cc6:	1101                	addi	sp,sp,-32
    80002cc8:	ec06                	sd	ra,24(sp)
    80002cca:	e822                	sd	s0,16(sp)
    80002ccc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cce:	fe840593          	addi	a1,s0,-24
    80002cd2:	4501                	li	a0,0
    80002cd4:	00000097          	auipc	ra,0x0
    80002cd8:	ece080e7          	jalr	-306(ra) # 80002ba2 <argaddr>
    80002cdc:	87aa                	mv	a5,a0
    return -1;
    80002cde:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ce0:	0007c863          	bltz	a5,80002cf0 <sys_wait+0x2a>
  return wait(p);
    80002ce4:	fe843503          	ld	a0,-24(s0)
    80002ce8:	fffff097          	auipc	ra,0xfffff
    80002cec:	3d6080e7          	jalr	982(ra) # 800020be <wait>
}
    80002cf0:	60e2                	ld	ra,24(sp)
    80002cf2:	6442                	ld	s0,16(sp)
    80002cf4:	6105                	addi	sp,sp,32
    80002cf6:	8082                	ret

0000000080002cf8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cf8:	7179                	addi	sp,sp,-48
    80002cfa:	f406                	sd	ra,40(sp)
    80002cfc:	f022                	sd	s0,32(sp)
    80002cfe:	ec26                	sd	s1,24(sp)
    80002d00:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d02:	fdc40593          	addi	a1,s0,-36
    80002d06:	4501                	li	a0,0
    80002d08:	00000097          	auipc	ra,0x0
    80002d0c:	e78080e7          	jalr	-392(ra) # 80002b80 <argint>
    80002d10:	87aa                	mv	a5,a0
    return -1;
    80002d12:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d14:	0207c063          	bltz	a5,80002d34 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	c7e080e7          	jalr	-898(ra) # 80001996 <myproc>
    80002d20:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d22:	fdc42503          	lw	a0,-36(s0)
    80002d26:	fffff097          	auipc	ra,0xfffff
    80002d2a:	fca080e7          	jalr	-54(ra) # 80001cf0 <growproc>
    80002d2e:	00054863          	bltz	a0,80002d3e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d32:	8526                	mv	a0,s1
}
    80002d34:	70a2                	ld	ra,40(sp)
    80002d36:	7402                	ld	s0,32(sp)
    80002d38:	64e2                	ld	s1,24(sp)
    80002d3a:	6145                	addi	sp,sp,48
    80002d3c:	8082                	ret
    return -1;
    80002d3e:	557d                	li	a0,-1
    80002d40:	bfd5                	j	80002d34 <sys_sbrk+0x3c>

0000000080002d42 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d42:	7139                	addi	sp,sp,-64
    80002d44:	fc06                	sd	ra,56(sp)
    80002d46:	f822                	sd	s0,48(sp)
    80002d48:	f426                	sd	s1,40(sp)
    80002d4a:	f04a                	sd	s2,32(sp)
    80002d4c:	ec4e                	sd	s3,24(sp)
    80002d4e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d50:	fcc40593          	addi	a1,s0,-52
    80002d54:	4501                	li	a0,0
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	e2a080e7          	jalr	-470(ra) # 80002b80 <argint>
    return -1;
    80002d5e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d60:	06054563          	bltz	a0,80002dca <sys_sleep+0x88>
  acquire(&tickslock);
    80002d64:	00014517          	auipc	a0,0x14
    80002d68:	36c50513          	addi	a0,a0,876 # 800170d0 <tickslock>
    80002d6c:	ffffe097          	auipc	ra,0xffffe
    80002d70:	e64080e7          	jalr	-412(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002d74:	00006917          	auipc	s2,0x6
    80002d78:	2bc92903          	lw	s2,700(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d7c:	fcc42783          	lw	a5,-52(s0)
    80002d80:	cf85                	beqz	a5,80002db8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d82:	00014997          	auipc	s3,0x14
    80002d86:	34e98993          	addi	s3,s3,846 # 800170d0 <tickslock>
    80002d8a:	00006497          	auipc	s1,0x6
    80002d8e:	2a648493          	addi	s1,s1,678 # 80009030 <ticks>
    if(myproc()->killed){
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	c04080e7          	jalr	-1020(ra) # 80001996 <myproc>
    80002d9a:	551c                	lw	a5,40(a0)
    80002d9c:	ef9d                	bnez	a5,80002dda <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d9e:	85ce                	mv	a1,s3
    80002da0:	8526                	mv	a0,s1
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	2b8080e7          	jalr	696(ra) # 8000205a <sleep>
  while(ticks - ticks0 < n){
    80002daa:	409c                	lw	a5,0(s1)
    80002dac:	412787bb          	subw	a5,a5,s2
    80002db0:	fcc42703          	lw	a4,-52(s0)
    80002db4:	fce7efe3          	bltu	a5,a4,80002d92 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002db8:	00014517          	auipc	a0,0x14
    80002dbc:	31850513          	addi	a0,a0,792 # 800170d0 <tickslock>
    80002dc0:	ffffe097          	auipc	ra,0xffffe
    80002dc4:	ec4080e7          	jalr	-316(ra) # 80000c84 <release>
  return 0;
    80002dc8:	4781                	li	a5,0
}
    80002dca:	853e                	mv	a0,a5
    80002dcc:	70e2                	ld	ra,56(sp)
    80002dce:	7442                	ld	s0,48(sp)
    80002dd0:	74a2                	ld	s1,40(sp)
    80002dd2:	7902                	ld	s2,32(sp)
    80002dd4:	69e2                	ld	s3,24(sp)
    80002dd6:	6121                	addi	sp,sp,64
    80002dd8:	8082                	ret
      release(&tickslock);
    80002dda:	00014517          	auipc	a0,0x14
    80002dde:	2f650513          	addi	a0,a0,758 # 800170d0 <tickslock>
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	ea2080e7          	jalr	-350(ra) # 80000c84 <release>
      return -1;
    80002dea:	57fd                	li	a5,-1
    80002dec:	bff9                	j	80002dca <sys_sleep+0x88>

0000000080002dee <sys_kill>:

uint64
sys_kill(void)
{
    80002dee:	1101                	addi	sp,sp,-32
    80002df0:	ec06                	sd	ra,24(sp)
    80002df2:	e822                	sd	s0,16(sp)
    80002df4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002df6:	fec40593          	addi	a1,s0,-20
    80002dfa:	4501                	li	a0,0
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	d84080e7          	jalr	-636(ra) # 80002b80 <argint>
    80002e04:	87aa                	mv	a5,a0
    return -1;
    80002e06:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e08:	0007c863          	bltz	a5,80002e18 <sys_kill+0x2a>
  return kill(pid);
    80002e0c:	fec42503          	lw	a0,-20(s0)
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	57c080e7          	jalr	1404(ra) # 8000238c <kill>
}
    80002e18:	60e2                	ld	ra,24(sp)
    80002e1a:	6442                	ld	s0,16(sp)
    80002e1c:	6105                	addi	sp,sp,32
    80002e1e:	8082                	ret

0000000080002e20 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e20:	1101                	addi	sp,sp,-32
    80002e22:	ec06                	sd	ra,24(sp)
    80002e24:	e822                	sd	s0,16(sp)
    80002e26:	e426                	sd	s1,8(sp)
    80002e28:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e2a:	00014517          	auipc	a0,0x14
    80002e2e:	2a650513          	addi	a0,a0,678 # 800170d0 <tickslock>
    80002e32:	ffffe097          	auipc	ra,0xffffe
    80002e36:	d9e080e7          	jalr	-610(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002e3a:	00006497          	auipc	s1,0x6
    80002e3e:	1f64a483          	lw	s1,502(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e42:	00014517          	auipc	a0,0x14
    80002e46:	28e50513          	addi	a0,a0,654 # 800170d0 <tickslock>
    80002e4a:	ffffe097          	auipc	ra,0xffffe
    80002e4e:	e3a080e7          	jalr	-454(ra) # 80000c84 <release>
  return xticks;
}
    80002e52:	02049513          	slli	a0,s1,0x20
    80002e56:	9101                	srli	a0,a0,0x20
    80002e58:	60e2                	ld	ra,24(sp)
    80002e5a:	6442                	ld	s0,16(sp)
    80002e5c:	64a2                	ld	s1,8(sp)
    80002e5e:	6105                	addi	sp,sp,32
    80002e60:	8082                	ret

0000000080002e62 <sys_getppid>:

uint64
sys_getppid(void)
{
    80002e62:	1141                	addi	sp,sp,-16
    80002e64:	e406                	sd	ra,8(sp)
    80002e66:	e022                	sd	s0,0(sp)
    80002e68:	0800                	addi	s0,sp,16
  struct proc* par_proc = myproc()->parent->parent->parent;
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	b2c080e7          	jalr	-1236(ra) # 80001996 <myproc>
    80002e72:	7d1c                	ld	a5,56(a0)
    80002e74:	7f9c                	ld	a5,56(a5)
  if(par_proc) return myproc()->parent->pid;
    80002e76:	7f9c                	ld	a5,56(a5)
  else return -1;
    80002e78:	557d                	li	a0,-1
  if(par_proc) return myproc()->parent->pid;
    80002e7a:	c799                	beqz	a5,80002e88 <sys_getppid+0x26>
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	b1a080e7          	jalr	-1254(ra) # 80001996 <myproc>
    80002e84:	7d1c                	ld	a5,56(a0)
    80002e86:	5b88                	lw	a0,48(a5)
}
    80002e88:	60a2                	ld	ra,8(sp)
    80002e8a:	6402                	ld	s0,0(sp)
    80002e8c:	0141                	addi	sp,sp,16
    80002e8e:	8082                	ret

0000000080002e90 <sys_yield>:

uint64
sys_yield(void)
{
    80002e90:	1141                	addi	sp,sp,-16
    80002e92:	e406                	sd	ra,8(sp)
    80002e94:	e022                	sd	s0,0(sp)
    80002e96:	0800                	addi	s0,sp,16
  yield();
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	186080e7          	jalr	390(ra) # 8000201e <yield>
  return 0;
}
    80002ea0:	4501                	li	a0,0
    80002ea2:	60a2                	ld	ra,8(sp)
    80002ea4:	6402                	ld	s0,0(sp)
    80002ea6:	0141                	addi	sp,sp,16
    80002ea8:	8082                	ret

0000000080002eaa <sys_getpa>:

uint64
sys_getpa(void)
{
    80002eaa:	1101                	addi	sp,sp,-32
    80002eac:	ec06                	sd	ra,24(sp)
    80002eae:	e822                	sd	s0,16(sp)
    80002eb0:	1000                	addi	s0,sp,32
  int va;
  if(argint(0, &va) < 0)
    80002eb2:	fec40593          	addi	a1,s0,-20
    80002eb6:	4501                	li	a0,0
    80002eb8:	00000097          	auipc	ra,0x0
    80002ebc:	cc8080e7          	jalr	-824(ra) # 80002b80 <argint>
    80002ec0:	87aa                	mv	a5,a0
    return -1;
    80002ec2:	557d                	li	a0,-1
  if(argint(0, &va) < 0)
    80002ec4:	0207c263          	bltz	a5,80002ee8 <sys_getpa+0x3e>
    
  return walkaddr(myproc()->pagetable, va) + (va & (PGSIZE - 1));
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	ace080e7          	jalr	-1330(ra) # 80001996 <myproc>
    80002ed0:	fec42583          	lw	a1,-20(s0)
    80002ed4:	6928                	ld	a0,80(a0)
    80002ed6:	ffffe097          	auipc	ra,0xffffe
    80002eda:	17c080e7          	jalr	380(ra) # 80001052 <walkaddr>
    80002ede:	fec42783          	lw	a5,-20(s0)
    80002ee2:	17d2                	slli	a5,a5,0x34
    80002ee4:	93d1                	srli	a5,a5,0x34
    80002ee6:	953e                	add	a0,a0,a5
}
    80002ee8:	60e2                	ld	ra,24(sp)
    80002eea:	6442                	ld	s0,16(sp)
    80002eec:	6105                	addi	sp,sp,32
    80002eee:	8082                	ret

0000000080002ef0 <sys_waitpid>:

uint64
sys_waitpid(void)
{
    80002ef0:	1101                	addi	sp,sp,-32
    80002ef2:	ec06                	sd	ra,24(sp)
    80002ef4:	e822                	sd	s0,16(sp)
    80002ef6:	1000                	addi	s0,sp,32
  uint64 pid;
  uint64 p;
  if(argaddr(0, &pid) < 0)
    80002ef8:	fe840593          	addi	a1,s0,-24
    80002efc:	4501                	li	a0,0
    80002efe:	00000097          	auipc	ra,0x0
    80002f02:	ca4080e7          	jalr	-860(ra) # 80002ba2 <argaddr>
    80002f06:	87aa                	mv	a5,a0
    return -1;
    80002f08:	557d                	li	a0,-1
  if(argaddr(0, &pid) < 0)
    80002f0a:	0207c663          	bltz	a5,80002f36 <sys_waitpid+0x46>
  if(argaddr(1, &p) < 0)
    80002f0e:	fe040593          	addi	a1,s0,-32
    80002f12:	4505                	li	a0,1
    80002f14:	00000097          	auipc	ra,0x0
    80002f18:	c8e080e7          	jalr	-882(ra) # 80002ba2 <argaddr>
    80002f1c:	02054863          	bltz	a0,80002f4c <sys_waitpid+0x5c>
    return -1;
  // printf("%d\n", p);
  if(pid == -1)
    80002f20:	fe843503          	ld	a0,-24(s0)
    80002f24:	57fd                	li	a5,-1
    80002f26:	00f50c63          	beq	a0,a5,80002f3e <sys_waitpid+0x4e>
    return wait(p);
  return waitpid(pid, p);
    80002f2a:	fe043583          	ld	a1,-32(s0)
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	62c080e7          	jalr	1580(ra) # 8000255a <waitpid>
    80002f36:	60e2                	ld	ra,24(sp)
    80002f38:	6442                	ld	s0,16(sp)
    80002f3a:	6105                	addi	sp,sp,32
    80002f3c:	8082                	ret
    return wait(p);
    80002f3e:	fe043503          	ld	a0,-32(s0)
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	17c080e7          	jalr	380(ra) # 800020be <wait>
    80002f4a:	b7f5                	j	80002f36 <sys_waitpid+0x46>
    return -1;
    80002f4c:	557d                	li	a0,-1
    80002f4e:	b7e5                	j	80002f36 <sys_waitpid+0x46>

0000000080002f50 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f50:	7179                	addi	sp,sp,-48
    80002f52:	f406                	sd	ra,40(sp)
    80002f54:	f022                	sd	s0,32(sp)
    80002f56:	ec26                	sd	s1,24(sp)
    80002f58:	e84a                	sd	s2,16(sp)
    80002f5a:	e44e                	sd	s3,8(sp)
    80002f5c:	e052                	sd	s4,0(sp)
    80002f5e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f60:	00005597          	auipc	a1,0x5
    80002f64:	5b858593          	addi	a1,a1,1464 # 80008518 <syscalls+0xd0>
    80002f68:	00014517          	auipc	a0,0x14
    80002f6c:	18050513          	addi	a0,a0,384 # 800170e8 <bcache>
    80002f70:	ffffe097          	auipc	ra,0xffffe
    80002f74:	bd0080e7          	jalr	-1072(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f78:	0001c797          	auipc	a5,0x1c
    80002f7c:	17078793          	addi	a5,a5,368 # 8001f0e8 <bcache+0x8000>
    80002f80:	0001c717          	auipc	a4,0x1c
    80002f84:	3d070713          	addi	a4,a4,976 # 8001f350 <bcache+0x8268>
    80002f88:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f8c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f90:	00014497          	auipc	s1,0x14
    80002f94:	17048493          	addi	s1,s1,368 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002f98:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f9a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f9c:	00005a17          	auipc	s4,0x5
    80002fa0:	584a0a13          	addi	s4,s4,1412 # 80008520 <syscalls+0xd8>
    b->next = bcache.head.next;
    80002fa4:	2b893783          	ld	a5,696(s2)
    80002fa8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002faa:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fae:	85d2                	mv	a1,s4
    80002fb0:	01048513          	addi	a0,s1,16
    80002fb4:	00001097          	auipc	ra,0x1
    80002fb8:	4c2080e7          	jalr	1218(ra) # 80004476 <initsleeplock>
    bcache.head.next->prev = b;
    80002fbc:	2b893783          	ld	a5,696(s2)
    80002fc0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fc2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fc6:	45848493          	addi	s1,s1,1112
    80002fca:	fd349de3          	bne	s1,s3,80002fa4 <binit+0x54>
  }
}
    80002fce:	70a2                	ld	ra,40(sp)
    80002fd0:	7402                	ld	s0,32(sp)
    80002fd2:	64e2                	ld	s1,24(sp)
    80002fd4:	6942                	ld	s2,16(sp)
    80002fd6:	69a2                	ld	s3,8(sp)
    80002fd8:	6a02                	ld	s4,0(sp)
    80002fda:	6145                	addi	sp,sp,48
    80002fdc:	8082                	ret

0000000080002fde <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fde:	7179                	addi	sp,sp,-48
    80002fe0:	f406                	sd	ra,40(sp)
    80002fe2:	f022                	sd	s0,32(sp)
    80002fe4:	ec26                	sd	s1,24(sp)
    80002fe6:	e84a                	sd	s2,16(sp)
    80002fe8:	e44e                	sd	s3,8(sp)
    80002fea:	1800                	addi	s0,sp,48
    80002fec:	892a                	mv	s2,a0
    80002fee:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ff0:	00014517          	auipc	a0,0x14
    80002ff4:	0f850513          	addi	a0,a0,248 # 800170e8 <bcache>
    80002ff8:	ffffe097          	auipc	ra,0xffffe
    80002ffc:	bd8080e7          	jalr	-1064(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003000:	0001c497          	auipc	s1,0x1c
    80003004:	3a04b483          	ld	s1,928(s1) # 8001f3a0 <bcache+0x82b8>
    80003008:	0001c797          	auipc	a5,0x1c
    8000300c:	34878793          	addi	a5,a5,840 # 8001f350 <bcache+0x8268>
    80003010:	02f48f63          	beq	s1,a5,8000304e <bread+0x70>
    80003014:	873e                	mv	a4,a5
    80003016:	a021                	j	8000301e <bread+0x40>
    80003018:	68a4                	ld	s1,80(s1)
    8000301a:	02e48a63          	beq	s1,a4,8000304e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000301e:	449c                	lw	a5,8(s1)
    80003020:	ff279ce3          	bne	a5,s2,80003018 <bread+0x3a>
    80003024:	44dc                	lw	a5,12(s1)
    80003026:	ff3799e3          	bne	a5,s3,80003018 <bread+0x3a>
      b->refcnt++;
    8000302a:	40bc                	lw	a5,64(s1)
    8000302c:	2785                	addiw	a5,a5,1
    8000302e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003030:	00014517          	auipc	a0,0x14
    80003034:	0b850513          	addi	a0,a0,184 # 800170e8 <bcache>
    80003038:	ffffe097          	auipc	ra,0xffffe
    8000303c:	c4c080e7          	jalr	-948(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80003040:	01048513          	addi	a0,s1,16
    80003044:	00001097          	auipc	ra,0x1
    80003048:	46c080e7          	jalr	1132(ra) # 800044b0 <acquiresleep>
      return b;
    8000304c:	a8b9                	j	800030aa <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000304e:	0001c497          	auipc	s1,0x1c
    80003052:	34a4b483          	ld	s1,842(s1) # 8001f398 <bcache+0x82b0>
    80003056:	0001c797          	auipc	a5,0x1c
    8000305a:	2fa78793          	addi	a5,a5,762 # 8001f350 <bcache+0x8268>
    8000305e:	00f48863          	beq	s1,a5,8000306e <bread+0x90>
    80003062:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003064:	40bc                	lw	a5,64(s1)
    80003066:	cf81                	beqz	a5,8000307e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003068:	64a4                	ld	s1,72(s1)
    8000306a:	fee49de3          	bne	s1,a4,80003064 <bread+0x86>
  panic("bget: no buffers");
    8000306e:	00005517          	auipc	a0,0x5
    80003072:	4ba50513          	addi	a0,a0,1210 # 80008528 <syscalls+0xe0>
    80003076:	ffffd097          	auipc	ra,0xffffd
    8000307a:	4c4080e7          	jalr	1220(ra) # 8000053a <panic>
      b->dev = dev;
    8000307e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003082:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003086:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000308a:	4785                	li	a5,1
    8000308c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000308e:	00014517          	auipc	a0,0x14
    80003092:	05a50513          	addi	a0,a0,90 # 800170e8 <bcache>
    80003096:	ffffe097          	auipc	ra,0xffffe
    8000309a:	bee080e7          	jalr	-1042(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    8000309e:	01048513          	addi	a0,s1,16
    800030a2:	00001097          	auipc	ra,0x1
    800030a6:	40e080e7          	jalr	1038(ra) # 800044b0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030aa:	409c                	lw	a5,0(s1)
    800030ac:	cb89                	beqz	a5,800030be <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030ae:	8526                	mv	a0,s1
    800030b0:	70a2                	ld	ra,40(sp)
    800030b2:	7402                	ld	s0,32(sp)
    800030b4:	64e2                	ld	s1,24(sp)
    800030b6:	6942                	ld	s2,16(sp)
    800030b8:	69a2                	ld	s3,8(sp)
    800030ba:	6145                	addi	sp,sp,48
    800030bc:	8082                	ret
    virtio_disk_rw(b, 0);
    800030be:	4581                	li	a1,0
    800030c0:	8526                	mv	a0,s1
    800030c2:	00003097          	auipc	ra,0x3
    800030c6:	f20080e7          	jalr	-224(ra) # 80005fe2 <virtio_disk_rw>
    b->valid = 1;
    800030ca:	4785                	li	a5,1
    800030cc:	c09c                	sw	a5,0(s1)
  return b;
    800030ce:	b7c5                	j	800030ae <bread+0xd0>

00000000800030d0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030d0:	1101                	addi	sp,sp,-32
    800030d2:	ec06                	sd	ra,24(sp)
    800030d4:	e822                	sd	s0,16(sp)
    800030d6:	e426                	sd	s1,8(sp)
    800030d8:	1000                	addi	s0,sp,32
    800030da:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030dc:	0541                	addi	a0,a0,16
    800030de:	00001097          	auipc	ra,0x1
    800030e2:	46c080e7          	jalr	1132(ra) # 8000454a <holdingsleep>
    800030e6:	cd01                	beqz	a0,800030fe <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030e8:	4585                	li	a1,1
    800030ea:	8526                	mv	a0,s1
    800030ec:	00003097          	auipc	ra,0x3
    800030f0:	ef6080e7          	jalr	-266(ra) # 80005fe2 <virtio_disk_rw>
}
    800030f4:	60e2                	ld	ra,24(sp)
    800030f6:	6442                	ld	s0,16(sp)
    800030f8:	64a2                	ld	s1,8(sp)
    800030fa:	6105                	addi	sp,sp,32
    800030fc:	8082                	ret
    panic("bwrite");
    800030fe:	00005517          	auipc	a0,0x5
    80003102:	44250513          	addi	a0,a0,1090 # 80008540 <syscalls+0xf8>
    80003106:	ffffd097          	auipc	ra,0xffffd
    8000310a:	434080e7          	jalr	1076(ra) # 8000053a <panic>

000000008000310e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000310e:	1101                	addi	sp,sp,-32
    80003110:	ec06                	sd	ra,24(sp)
    80003112:	e822                	sd	s0,16(sp)
    80003114:	e426                	sd	s1,8(sp)
    80003116:	e04a                	sd	s2,0(sp)
    80003118:	1000                	addi	s0,sp,32
    8000311a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000311c:	01050913          	addi	s2,a0,16
    80003120:	854a                	mv	a0,s2
    80003122:	00001097          	auipc	ra,0x1
    80003126:	428080e7          	jalr	1064(ra) # 8000454a <holdingsleep>
    8000312a:	c92d                	beqz	a0,8000319c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000312c:	854a                	mv	a0,s2
    8000312e:	00001097          	auipc	ra,0x1
    80003132:	3d8080e7          	jalr	984(ra) # 80004506 <releasesleep>

  acquire(&bcache.lock);
    80003136:	00014517          	auipc	a0,0x14
    8000313a:	fb250513          	addi	a0,a0,-78 # 800170e8 <bcache>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	a92080e7          	jalr	-1390(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003146:	40bc                	lw	a5,64(s1)
    80003148:	37fd                	addiw	a5,a5,-1
    8000314a:	0007871b          	sext.w	a4,a5
    8000314e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003150:	eb05                	bnez	a4,80003180 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003152:	68bc                	ld	a5,80(s1)
    80003154:	64b8                	ld	a4,72(s1)
    80003156:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003158:	64bc                	ld	a5,72(s1)
    8000315a:	68b8                	ld	a4,80(s1)
    8000315c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000315e:	0001c797          	auipc	a5,0x1c
    80003162:	f8a78793          	addi	a5,a5,-118 # 8001f0e8 <bcache+0x8000>
    80003166:	2b87b703          	ld	a4,696(a5)
    8000316a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000316c:	0001c717          	auipc	a4,0x1c
    80003170:	1e470713          	addi	a4,a4,484 # 8001f350 <bcache+0x8268>
    80003174:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003176:	2b87b703          	ld	a4,696(a5)
    8000317a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000317c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003180:	00014517          	auipc	a0,0x14
    80003184:	f6850513          	addi	a0,a0,-152 # 800170e8 <bcache>
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	afc080e7          	jalr	-1284(ra) # 80000c84 <release>
}
    80003190:	60e2                	ld	ra,24(sp)
    80003192:	6442                	ld	s0,16(sp)
    80003194:	64a2                	ld	s1,8(sp)
    80003196:	6902                	ld	s2,0(sp)
    80003198:	6105                	addi	sp,sp,32
    8000319a:	8082                	ret
    panic("brelse");
    8000319c:	00005517          	auipc	a0,0x5
    800031a0:	3ac50513          	addi	a0,a0,940 # 80008548 <syscalls+0x100>
    800031a4:	ffffd097          	auipc	ra,0xffffd
    800031a8:	396080e7          	jalr	918(ra) # 8000053a <panic>

00000000800031ac <bpin>:

void
bpin(struct buf *b) {
    800031ac:	1101                	addi	sp,sp,-32
    800031ae:	ec06                	sd	ra,24(sp)
    800031b0:	e822                	sd	s0,16(sp)
    800031b2:	e426                	sd	s1,8(sp)
    800031b4:	1000                	addi	s0,sp,32
    800031b6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031b8:	00014517          	auipc	a0,0x14
    800031bc:	f3050513          	addi	a0,a0,-208 # 800170e8 <bcache>
    800031c0:	ffffe097          	auipc	ra,0xffffe
    800031c4:	a10080e7          	jalr	-1520(ra) # 80000bd0 <acquire>
  b->refcnt++;
    800031c8:	40bc                	lw	a5,64(s1)
    800031ca:	2785                	addiw	a5,a5,1
    800031cc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031ce:	00014517          	auipc	a0,0x14
    800031d2:	f1a50513          	addi	a0,a0,-230 # 800170e8 <bcache>
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	aae080e7          	jalr	-1362(ra) # 80000c84 <release>
}
    800031de:	60e2                	ld	ra,24(sp)
    800031e0:	6442                	ld	s0,16(sp)
    800031e2:	64a2                	ld	s1,8(sp)
    800031e4:	6105                	addi	sp,sp,32
    800031e6:	8082                	ret

00000000800031e8 <bunpin>:

void
bunpin(struct buf *b) {
    800031e8:	1101                	addi	sp,sp,-32
    800031ea:	ec06                	sd	ra,24(sp)
    800031ec:	e822                	sd	s0,16(sp)
    800031ee:	e426                	sd	s1,8(sp)
    800031f0:	1000                	addi	s0,sp,32
    800031f2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031f4:	00014517          	auipc	a0,0x14
    800031f8:	ef450513          	addi	a0,a0,-268 # 800170e8 <bcache>
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	9d4080e7          	jalr	-1580(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003204:	40bc                	lw	a5,64(s1)
    80003206:	37fd                	addiw	a5,a5,-1
    80003208:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000320a:	00014517          	auipc	a0,0x14
    8000320e:	ede50513          	addi	a0,a0,-290 # 800170e8 <bcache>
    80003212:	ffffe097          	auipc	ra,0xffffe
    80003216:	a72080e7          	jalr	-1422(ra) # 80000c84 <release>
}
    8000321a:	60e2                	ld	ra,24(sp)
    8000321c:	6442                	ld	s0,16(sp)
    8000321e:	64a2                	ld	s1,8(sp)
    80003220:	6105                	addi	sp,sp,32
    80003222:	8082                	ret

0000000080003224 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003224:	1101                	addi	sp,sp,-32
    80003226:	ec06                	sd	ra,24(sp)
    80003228:	e822                	sd	s0,16(sp)
    8000322a:	e426                	sd	s1,8(sp)
    8000322c:	e04a                	sd	s2,0(sp)
    8000322e:	1000                	addi	s0,sp,32
    80003230:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003232:	00d5d59b          	srliw	a1,a1,0xd
    80003236:	0001c797          	auipc	a5,0x1c
    8000323a:	58e7a783          	lw	a5,1422(a5) # 8001f7c4 <sb+0x1c>
    8000323e:	9dbd                	addw	a1,a1,a5
    80003240:	00000097          	auipc	ra,0x0
    80003244:	d9e080e7          	jalr	-610(ra) # 80002fde <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003248:	0074f713          	andi	a4,s1,7
    8000324c:	4785                	li	a5,1
    8000324e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003252:	14ce                	slli	s1,s1,0x33
    80003254:	90d9                	srli	s1,s1,0x36
    80003256:	00950733          	add	a4,a0,s1
    8000325a:	05874703          	lbu	a4,88(a4)
    8000325e:	00e7f6b3          	and	a3,a5,a4
    80003262:	c69d                	beqz	a3,80003290 <bfree+0x6c>
    80003264:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003266:	94aa                	add	s1,s1,a0
    80003268:	fff7c793          	not	a5,a5
    8000326c:	8f7d                	and	a4,a4,a5
    8000326e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003272:	00001097          	auipc	ra,0x1
    80003276:	120080e7          	jalr	288(ra) # 80004392 <log_write>
  brelse(bp);
    8000327a:	854a                	mv	a0,s2
    8000327c:	00000097          	auipc	ra,0x0
    80003280:	e92080e7          	jalr	-366(ra) # 8000310e <brelse>
}
    80003284:	60e2                	ld	ra,24(sp)
    80003286:	6442                	ld	s0,16(sp)
    80003288:	64a2                	ld	s1,8(sp)
    8000328a:	6902                	ld	s2,0(sp)
    8000328c:	6105                	addi	sp,sp,32
    8000328e:	8082                	ret
    panic("freeing free block");
    80003290:	00005517          	auipc	a0,0x5
    80003294:	2c050513          	addi	a0,a0,704 # 80008550 <syscalls+0x108>
    80003298:	ffffd097          	auipc	ra,0xffffd
    8000329c:	2a2080e7          	jalr	674(ra) # 8000053a <panic>

00000000800032a0 <balloc>:
{
    800032a0:	711d                	addi	sp,sp,-96
    800032a2:	ec86                	sd	ra,88(sp)
    800032a4:	e8a2                	sd	s0,80(sp)
    800032a6:	e4a6                	sd	s1,72(sp)
    800032a8:	e0ca                	sd	s2,64(sp)
    800032aa:	fc4e                	sd	s3,56(sp)
    800032ac:	f852                	sd	s4,48(sp)
    800032ae:	f456                	sd	s5,40(sp)
    800032b0:	f05a                	sd	s6,32(sp)
    800032b2:	ec5e                	sd	s7,24(sp)
    800032b4:	e862                	sd	s8,16(sp)
    800032b6:	e466                	sd	s9,8(sp)
    800032b8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032ba:	0001c797          	auipc	a5,0x1c
    800032be:	4f27a783          	lw	a5,1266(a5) # 8001f7ac <sb+0x4>
    800032c2:	cbc1                	beqz	a5,80003352 <balloc+0xb2>
    800032c4:	8baa                	mv	s7,a0
    800032c6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032c8:	0001cb17          	auipc	s6,0x1c
    800032cc:	4e0b0b13          	addi	s6,s6,1248 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032d2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032d6:	6c89                	lui	s9,0x2
    800032d8:	a831                	j	800032f4 <balloc+0x54>
    brelse(bp);
    800032da:	854a                	mv	a0,s2
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	e32080e7          	jalr	-462(ra) # 8000310e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032e4:	015c87bb          	addw	a5,s9,s5
    800032e8:	00078a9b          	sext.w	s5,a5
    800032ec:	004b2703          	lw	a4,4(s6)
    800032f0:	06eaf163          	bgeu	s5,a4,80003352 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800032f4:	41fad79b          	sraiw	a5,s5,0x1f
    800032f8:	0137d79b          	srliw	a5,a5,0x13
    800032fc:	015787bb          	addw	a5,a5,s5
    80003300:	40d7d79b          	sraiw	a5,a5,0xd
    80003304:	01cb2583          	lw	a1,28(s6)
    80003308:	9dbd                	addw	a1,a1,a5
    8000330a:	855e                	mv	a0,s7
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	cd2080e7          	jalr	-814(ra) # 80002fde <bread>
    80003314:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003316:	004b2503          	lw	a0,4(s6)
    8000331a:	000a849b          	sext.w	s1,s5
    8000331e:	8762                	mv	a4,s8
    80003320:	faa4fde3          	bgeu	s1,a0,800032da <balloc+0x3a>
      m = 1 << (bi % 8);
    80003324:	00777693          	andi	a3,a4,7
    80003328:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000332c:	41f7579b          	sraiw	a5,a4,0x1f
    80003330:	01d7d79b          	srliw	a5,a5,0x1d
    80003334:	9fb9                	addw	a5,a5,a4
    80003336:	4037d79b          	sraiw	a5,a5,0x3
    8000333a:	00f90633          	add	a2,s2,a5
    8000333e:	05864603          	lbu	a2,88(a2)
    80003342:	00c6f5b3          	and	a1,a3,a2
    80003346:	cd91                	beqz	a1,80003362 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003348:	2705                	addiw	a4,a4,1
    8000334a:	2485                	addiw	s1,s1,1
    8000334c:	fd471ae3          	bne	a4,s4,80003320 <balloc+0x80>
    80003350:	b769                	j	800032da <balloc+0x3a>
  panic("balloc: out of blocks");
    80003352:	00005517          	auipc	a0,0x5
    80003356:	21650513          	addi	a0,a0,534 # 80008568 <syscalls+0x120>
    8000335a:	ffffd097          	auipc	ra,0xffffd
    8000335e:	1e0080e7          	jalr	480(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003362:	97ca                	add	a5,a5,s2
    80003364:	8e55                	or	a2,a2,a3
    80003366:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000336a:	854a                	mv	a0,s2
    8000336c:	00001097          	auipc	ra,0x1
    80003370:	026080e7          	jalr	38(ra) # 80004392 <log_write>
        brelse(bp);
    80003374:	854a                	mv	a0,s2
    80003376:	00000097          	auipc	ra,0x0
    8000337a:	d98080e7          	jalr	-616(ra) # 8000310e <brelse>
  bp = bread(dev, bno);
    8000337e:	85a6                	mv	a1,s1
    80003380:	855e                	mv	a0,s7
    80003382:	00000097          	auipc	ra,0x0
    80003386:	c5c080e7          	jalr	-932(ra) # 80002fde <bread>
    8000338a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000338c:	40000613          	li	a2,1024
    80003390:	4581                	li	a1,0
    80003392:	05850513          	addi	a0,a0,88
    80003396:	ffffe097          	auipc	ra,0xffffe
    8000339a:	936080e7          	jalr	-1738(ra) # 80000ccc <memset>
  log_write(bp);
    8000339e:	854a                	mv	a0,s2
    800033a0:	00001097          	auipc	ra,0x1
    800033a4:	ff2080e7          	jalr	-14(ra) # 80004392 <log_write>
  brelse(bp);
    800033a8:	854a                	mv	a0,s2
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	d64080e7          	jalr	-668(ra) # 8000310e <brelse>
}
    800033b2:	8526                	mv	a0,s1
    800033b4:	60e6                	ld	ra,88(sp)
    800033b6:	6446                	ld	s0,80(sp)
    800033b8:	64a6                	ld	s1,72(sp)
    800033ba:	6906                	ld	s2,64(sp)
    800033bc:	79e2                	ld	s3,56(sp)
    800033be:	7a42                	ld	s4,48(sp)
    800033c0:	7aa2                	ld	s5,40(sp)
    800033c2:	7b02                	ld	s6,32(sp)
    800033c4:	6be2                	ld	s7,24(sp)
    800033c6:	6c42                	ld	s8,16(sp)
    800033c8:	6ca2                	ld	s9,8(sp)
    800033ca:	6125                	addi	sp,sp,96
    800033cc:	8082                	ret

00000000800033ce <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033ce:	7179                	addi	sp,sp,-48
    800033d0:	f406                	sd	ra,40(sp)
    800033d2:	f022                	sd	s0,32(sp)
    800033d4:	ec26                	sd	s1,24(sp)
    800033d6:	e84a                	sd	s2,16(sp)
    800033d8:	e44e                	sd	s3,8(sp)
    800033da:	e052                	sd	s4,0(sp)
    800033dc:	1800                	addi	s0,sp,48
    800033de:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033e0:	47ad                	li	a5,11
    800033e2:	04b7fe63          	bgeu	a5,a1,8000343e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033e6:	ff45849b          	addiw	s1,a1,-12
    800033ea:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033ee:	0ff00793          	li	a5,255
    800033f2:	0ae7e463          	bltu	a5,a4,8000349a <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033f6:	08052583          	lw	a1,128(a0)
    800033fa:	c5b5                	beqz	a1,80003466 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033fc:	00092503          	lw	a0,0(s2)
    80003400:	00000097          	auipc	ra,0x0
    80003404:	bde080e7          	jalr	-1058(ra) # 80002fde <bread>
    80003408:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000340a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000340e:	02049713          	slli	a4,s1,0x20
    80003412:	01e75593          	srli	a1,a4,0x1e
    80003416:	00b784b3          	add	s1,a5,a1
    8000341a:	0004a983          	lw	s3,0(s1)
    8000341e:	04098e63          	beqz	s3,8000347a <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003422:	8552                	mv	a0,s4
    80003424:	00000097          	auipc	ra,0x0
    80003428:	cea080e7          	jalr	-790(ra) # 8000310e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000342c:	854e                	mv	a0,s3
    8000342e:	70a2                	ld	ra,40(sp)
    80003430:	7402                	ld	s0,32(sp)
    80003432:	64e2                	ld	s1,24(sp)
    80003434:	6942                	ld	s2,16(sp)
    80003436:	69a2                	ld	s3,8(sp)
    80003438:	6a02                	ld	s4,0(sp)
    8000343a:	6145                	addi	sp,sp,48
    8000343c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000343e:	02059793          	slli	a5,a1,0x20
    80003442:	01e7d593          	srli	a1,a5,0x1e
    80003446:	00b504b3          	add	s1,a0,a1
    8000344a:	0504a983          	lw	s3,80(s1)
    8000344e:	fc099fe3          	bnez	s3,8000342c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003452:	4108                	lw	a0,0(a0)
    80003454:	00000097          	auipc	ra,0x0
    80003458:	e4c080e7          	jalr	-436(ra) # 800032a0 <balloc>
    8000345c:	0005099b          	sext.w	s3,a0
    80003460:	0534a823          	sw	s3,80(s1)
    80003464:	b7e1                	j	8000342c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003466:	4108                	lw	a0,0(a0)
    80003468:	00000097          	auipc	ra,0x0
    8000346c:	e38080e7          	jalr	-456(ra) # 800032a0 <balloc>
    80003470:	0005059b          	sext.w	a1,a0
    80003474:	08b92023          	sw	a1,128(s2)
    80003478:	b751                	j	800033fc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000347a:	00092503          	lw	a0,0(s2)
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	e22080e7          	jalr	-478(ra) # 800032a0 <balloc>
    80003486:	0005099b          	sext.w	s3,a0
    8000348a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000348e:	8552                	mv	a0,s4
    80003490:	00001097          	auipc	ra,0x1
    80003494:	f02080e7          	jalr	-254(ra) # 80004392 <log_write>
    80003498:	b769                	j	80003422 <bmap+0x54>
  panic("bmap: out of range");
    8000349a:	00005517          	auipc	a0,0x5
    8000349e:	0e650513          	addi	a0,a0,230 # 80008580 <syscalls+0x138>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	098080e7          	jalr	152(ra) # 8000053a <panic>

00000000800034aa <iget>:
{
    800034aa:	7179                	addi	sp,sp,-48
    800034ac:	f406                	sd	ra,40(sp)
    800034ae:	f022                	sd	s0,32(sp)
    800034b0:	ec26                	sd	s1,24(sp)
    800034b2:	e84a                	sd	s2,16(sp)
    800034b4:	e44e                	sd	s3,8(sp)
    800034b6:	e052                	sd	s4,0(sp)
    800034b8:	1800                	addi	s0,sp,48
    800034ba:	89aa                	mv	s3,a0
    800034bc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034be:	0001c517          	auipc	a0,0x1c
    800034c2:	30a50513          	addi	a0,a0,778 # 8001f7c8 <itable>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	70a080e7          	jalr	1802(ra) # 80000bd0 <acquire>
  empty = 0;
    800034ce:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034d0:	0001c497          	auipc	s1,0x1c
    800034d4:	31048493          	addi	s1,s1,784 # 8001f7e0 <itable+0x18>
    800034d8:	0001e697          	auipc	a3,0x1e
    800034dc:	d9868693          	addi	a3,a3,-616 # 80021270 <log>
    800034e0:	a039                	j	800034ee <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034e2:	02090b63          	beqz	s2,80003518 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034e6:	08848493          	addi	s1,s1,136
    800034ea:	02d48a63          	beq	s1,a3,8000351e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034ee:	449c                	lw	a5,8(s1)
    800034f0:	fef059e3          	blez	a5,800034e2 <iget+0x38>
    800034f4:	4098                	lw	a4,0(s1)
    800034f6:	ff3716e3          	bne	a4,s3,800034e2 <iget+0x38>
    800034fa:	40d8                	lw	a4,4(s1)
    800034fc:	ff4713e3          	bne	a4,s4,800034e2 <iget+0x38>
      ip->ref++;
    80003500:	2785                	addiw	a5,a5,1
    80003502:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003504:	0001c517          	auipc	a0,0x1c
    80003508:	2c450513          	addi	a0,a0,708 # 8001f7c8 <itable>
    8000350c:	ffffd097          	auipc	ra,0xffffd
    80003510:	778080e7          	jalr	1912(ra) # 80000c84 <release>
      return ip;
    80003514:	8926                	mv	s2,s1
    80003516:	a03d                	j	80003544 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003518:	f7f9                	bnez	a5,800034e6 <iget+0x3c>
    8000351a:	8926                	mv	s2,s1
    8000351c:	b7e9                	j	800034e6 <iget+0x3c>
  if(empty == 0)
    8000351e:	02090c63          	beqz	s2,80003556 <iget+0xac>
  ip->dev = dev;
    80003522:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003526:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000352a:	4785                	li	a5,1
    8000352c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003530:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003534:	0001c517          	auipc	a0,0x1c
    80003538:	29450513          	addi	a0,a0,660 # 8001f7c8 <itable>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	748080e7          	jalr	1864(ra) # 80000c84 <release>
}
    80003544:	854a                	mv	a0,s2
    80003546:	70a2                	ld	ra,40(sp)
    80003548:	7402                	ld	s0,32(sp)
    8000354a:	64e2                	ld	s1,24(sp)
    8000354c:	6942                	ld	s2,16(sp)
    8000354e:	69a2                	ld	s3,8(sp)
    80003550:	6a02                	ld	s4,0(sp)
    80003552:	6145                	addi	sp,sp,48
    80003554:	8082                	ret
    panic("iget: no inodes");
    80003556:	00005517          	auipc	a0,0x5
    8000355a:	04250513          	addi	a0,a0,66 # 80008598 <syscalls+0x150>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	fdc080e7          	jalr	-36(ra) # 8000053a <panic>

0000000080003566 <fsinit>:
fsinit(int dev) {
    80003566:	7179                	addi	sp,sp,-48
    80003568:	f406                	sd	ra,40(sp)
    8000356a:	f022                	sd	s0,32(sp)
    8000356c:	ec26                	sd	s1,24(sp)
    8000356e:	e84a                	sd	s2,16(sp)
    80003570:	e44e                	sd	s3,8(sp)
    80003572:	1800                	addi	s0,sp,48
    80003574:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003576:	4585                	li	a1,1
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	a66080e7          	jalr	-1434(ra) # 80002fde <bread>
    80003580:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003582:	0001c997          	auipc	s3,0x1c
    80003586:	22698993          	addi	s3,s3,550 # 8001f7a8 <sb>
    8000358a:	02000613          	li	a2,32
    8000358e:	05850593          	addi	a1,a0,88
    80003592:	854e                	mv	a0,s3
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	794080e7          	jalr	1940(ra) # 80000d28 <memmove>
  brelse(bp);
    8000359c:	8526                	mv	a0,s1
    8000359e:	00000097          	auipc	ra,0x0
    800035a2:	b70080e7          	jalr	-1168(ra) # 8000310e <brelse>
  if(sb.magic != FSMAGIC)
    800035a6:	0009a703          	lw	a4,0(s3)
    800035aa:	102037b7          	lui	a5,0x10203
    800035ae:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035b2:	02f71263          	bne	a4,a5,800035d6 <fsinit+0x70>
  initlog(dev, &sb);
    800035b6:	0001c597          	auipc	a1,0x1c
    800035ba:	1f258593          	addi	a1,a1,498 # 8001f7a8 <sb>
    800035be:	854a                	mv	a0,s2
    800035c0:	00001097          	auipc	ra,0x1
    800035c4:	b56080e7          	jalr	-1194(ra) # 80004116 <initlog>
}
    800035c8:	70a2                	ld	ra,40(sp)
    800035ca:	7402                	ld	s0,32(sp)
    800035cc:	64e2                	ld	s1,24(sp)
    800035ce:	6942                	ld	s2,16(sp)
    800035d0:	69a2                	ld	s3,8(sp)
    800035d2:	6145                	addi	sp,sp,48
    800035d4:	8082                	ret
    panic("invalid file system");
    800035d6:	00005517          	auipc	a0,0x5
    800035da:	fd250513          	addi	a0,a0,-46 # 800085a8 <syscalls+0x160>
    800035de:	ffffd097          	auipc	ra,0xffffd
    800035e2:	f5c080e7          	jalr	-164(ra) # 8000053a <panic>

00000000800035e6 <iinit>:
{
    800035e6:	7179                	addi	sp,sp,-48
    800035e8:	f406                	sd	ra,40(sp)
    800035ea:	f022                	sd	s0,32(sp)
    800035ec:	ec26                	sd	s1,24(sp)
    800035ee:	e84a                	sd	s2,16(sp)
    800035f0:	e44e                	sd	s3,8(sp)
    800035f2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035f4:	00005597          	auipc	a1,0x5
    800035f8:	fcc58593          	addi	a1,a1,-52 # 800085c0 <syscalls+0x178>
    800035fc:	0001c517          	auipc	a0,0x1c
    80003600:	1cc50513          	addi	a0,a0,460 # 8001f7c8 <itable>
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	53c080e7          	jalr	1340(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000360c:	0001c497          	auipc	s1,0x1c
    80003610:	1e448493          	addi	s1,s1,484 # 8001f7f0 <itable+0x28>
    80003614:	0001e997          	auipc	s3,0x1e
    80003618:	c6c98993          	addi	s3,s3,-916 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000361c:	00005917          	auipc	s2,0x5
    80003620:	fac90913          	addi	s2,s2,-84 # 800085c8 <syscalls+0x180>
    80003624:	85ca                	mv	a1,s2
    80003626:	8526                	mv	a0,s1
    80003628:	00001097          	auipc	ra,0x1
    8000362c:	e4e080e7          	jalr	-434(ra) # 80004476 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003630:	08848493          	addi	s1,s1,136
    80003634:	ff3498e3          	bne	s1,s3,80003624 <iinit+0x3e>
}
    80003638:	70a2                	ld	ra,40(sp)
    8000363a:	7402                	ld	s0,32(sp)
    8000363c:	64e2                	ld	s1,24(sp)
    8000363e:	6942                	ld	s2,16(sp)
    80003640:	69a2                	ld	s3,8(sp)
    80003642:	6145                	addi	sp,sp,48
    80003644:	8082                	ret

0000000080003646 <ialloc>:
{
    80003646:	715d                	addi	sp,sp,-80
    80003648:	e486                	sd	ra,72(sp)
    8000364a:	e0a2                	sd	s0,64(sp)
    8000364c:	fc26                	sd	s1,56(sp)
    8000364e:	f84a                	sd	s2,48(sp)
    80003650:	f44e                	sd	s3,40(sp)
    80003652:	f052                	sd	s4,32(sp)
    80003654:	ec56                	sd	s5,24(sp)
    80003656:	e85a                	sd	s6,16(sp)
    80003658:	e45e                	sd	s7,8(sp)
    8000365a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000365c:	0001c717          	auipc	a4,0x1c
    80003660:	15872703          	lw	a4,344(a4) # 8001f7b4 <sb+0xc>
    80003664:	4785                	li	a5,1
    80003666:	04e7fa63          	bgeu	a5,a4,800036ba <ialloc+0x74>
    8000366a:	8aaa                	mv	s5,a0
    8000366c:	8bae                	mv	s7,a1
    8000366e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003670:	0001ca17          	auipc	s4,0x1c
    80003674:	138a0a13          	addi	s4,s4,312 # 8001f7a8 <sb>
    80003678:	00048b1b          	sext.w	s6,s1
    8000367c:	0044d593          	srli	a1,s1,0x4
    80003680:	018a2783          	lw	a5,24(s4)
    80003684:	9dbd                	addw	a1,a1,a5
    80003686:	8556                	mv	a0,s5
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	956080e7          	jalr	-1706(ra) # 80002fde <bread>
    80003690:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003692:	05850993          	addi	s3,a0,88
    80003696:	00f4f793          	andi	a5,s1,15
    8000369a:	079a                	slli	a5,a5,0x6
    8000369c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000369e:	00099783          	lh	a5,0(s3)
    800036a2:	c785                	beqz	a5,800036ca <ialloc+0x84>
    brelse(bp);
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	a6a080e7          	jalr	-1430(ra) # 8000310e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036ac:	0485                	addi	s1,s1,1
    800036ae:	00ca2703          	lw	a4,12(s4)
    800036b2:	0004879b          	sext.w	a5,s1
    800036b6:	fce7e1e3          	bltu	a5,a4,80003678 <ialloc+0x32>
  panic("ialloc: no inodes");
    800036ba:	00005517          	auipc	a0,0x5
    800036be:	f1650513          	addi	a0,a0,-234 # 800085d0 <syscalls+0x188>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	e78080e7          	jalr	-392(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    800036ca:	04000613          	li	a2,64
    800036ce:	4581                	li	a1,0
    800036d0:	854e                	mv	a0,s3
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	5fa080e7          	jalr	1530(ra) # 80000ccc <memset>
      dip->type = type;
    800036da:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036de:	854a                	mv	a0,s2
    800036e0:	00001097          	auipc	ra,0x1
    800036e4:	cb2080e7          	jalr	-846(ra) # 80004392 <log_write>
      brelse(bp);
    800036e8:	854a                	mv	a0,s2
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	a24080e7          	jalr	-1500(ra) # 8000310e <brelse>
      return iget(dev, inum);
    800036f2:	85da                	mv	a1,s6
    800036f4:	8556                	mv	a0,s5
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	db4080e7          	jalr	-588(ra) # 800034aa <iget>
}
    800036fe:	60a6                	ld	ra,72(sp)
    80003700:	6406                	ld	s0,64(sp)
    80003702:	74e2                	ld	s1,56(sp)
    80003704:	7942                	ld	s2,48(sp)
    80003706:	79a2                	ld	s3,40(sp)
    80003708:	7a02                	ld	s4,32(sp)
    8000370a:	6ae2                	ld	s5,24(sp)
    8000370c:	6b42                	ld	s6,16(sp)
    8000370e:	6ba2                	ld	s7,8(sp)
    80003710:	6161                	addi	sp,sp,80
    80003712:	8082                	ret

0000000080003714 <iupdate>:
{
    80003714:	1101                	addi	sp,sp,-32
    80003716:	ec06                	sd	ra,24(sp)
    80003718:	e822                	sd	s0,16(sp)
    8000371a:	e426                	sd	s1,8(sp)
    8000371c:	e04a                	sd	s2,0(sp)
    8000371e:	1000                	addi	s0,sp,32
    80003720:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003722:	415c                	lw	a5,4(a0)
    80003724:	0047d79b          	srliw	a5,a5,0x4
    80003728:	0001c597          	auipc	a1,0x1c
    8000372c:	0985a583          	lw	a1,152(a1) # 8001f7c0 <sb+0x18>
    80003730:	9dbd                	addw	a1,a1,a5
    80003732:	4108                	lw	a0,0(a0)
    80003734:	00000097          	auipc	ra,0x0
    80003738:	8aa080e7          	jalr	-1878(ra) # 80002fde <bread>
    8000373c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000373e:	05850793          	addi	a5,a0,88
    80003742:	40d8                	lw	a4,4(s1)
    80003744:	8b3d                	andi	a4,a4,15
    80003746:	071a                	slli	a4,a4,0x6
    80003748:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000374a:	04449703          	lh	a4,68(s1)
    8000374e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003752:	04649703          	lh	a4,70(s1)
    80003756:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000375a:	04849703          	lh	a4,72(s1)
    8000375e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003762:	04a49703          	lh	a4,74(s1)
    80003766:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000376a:	44f8                	lw	a4,76(s1)
    8000376c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000376e:	03400613          	li	a2,52
    80003772:	05048593          	addi	a1,s1,80
    80003776:	00c78513          	addi	a0,a5,12
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	5ae080e7          	jalr	1454(ra) # 80000d28 <memmove>
  log_write(bp);
    80003782:	854a                	mv	a0,s2
    80003784:	00001097          	auipc	ra,0x1
    80003788:	c0e080e7          	jalr	-1010(ra) # 80004392 <log_write>
  brelse(bp);
    8000378c:	854a                	mv	a0,s2
    8000378e:	00000097          	auipc	ra,0x0
    80003792:	980080e7          	jalr	-1664(ra) # 8000310e <brelse>
}
    80003796:	60e2                	ld	ra,24(sp)
    80003798:	6442                	ld	s0,16(sp)
    8000379a:	64a2                	ld	s1,8(sp)
    8000379c:	6902                	ld	s2,0(sp)
    8000379e:	6105                	addi	sp,sp,32
    800037a0:	8082                	ret

00000000800037a2 <idup>:
{
    800037a2:	1101                	addi	sp,sp,-32
    800037a4:	ec06                	sd	ra,24(sp)
    800037a6:	e822                	sd	s0,16(sp)
    800037a8:	e426                	sd	s1,8(sp)
    800037aa:	1000                	addi	s0,sp,32
    800037ac:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037ae:	0001c517          	auipc	a0,0x1c
    800037b2:	01a50513          	addi	a0,a0,26 # 8001f7c8 <itable>
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	41a080e7          	jalr	1050(ra) # 80000bd0 <acquire>
  ip->ref++;
    800037be:	449c                	lw	a5,8(s1)
    800037c0:	2785                	addiw	a5,a5,1
    800037c2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037c4:	0001c517          	auipc	a0,0x1c
    800037c8:	00450513          	addi	a0,a0,4 # 8001f7c8 <itable>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	4b8080e7          	jalr	1208(ra) # 80000c84 <release>
}
    800037d4:	8526                	mv	a0,s1
    800037d6:	60e2                	ld	ra,24(sp)
    800037d8:	6442                	ld	s0,16(sp)
    800037da:	64a2                	ld	s1,8(sp)
    800037dc:	6105                	addi	sp,sp,32
    800037de:	8082                	ret

00000000800037e0 <ilock>:
{
    800037e0:	1101                	addi	sp,sp,-32
    800037e2:	ec06                	sd	ra,24(sp)
    800037e4:	e822                	sd	s0,16(sp)
    800037e6:	e426                	sd	s1,8(sp)
    800037e8:	e04a                	sd	s2,0(sp)
    800037ea:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037ec:	c115                	beqz	a0,80003810 <ilock+0x30>
    800037ee:	84aa                	mv	s1,a0
    800037f0:	451c                	lw	a5,8(a0)
    800037f2:	00f05f63          	blez	a5,80003810 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037f6:	0541                	addi	a0,a0,16
    800037f8:	00001097          	auipc	ra,0x1
    800037fc:	cb8080e7          	jalr	-840(ra) # 800044b0 <acquiresleep>
  if(ip->valid == 0){
    80003800:	40bc                	lw	a5,64(s1)
    80003802:	cf99                	beqz	a5,80003820 <ilock+0x40>
}
    80003804:	60e2                	ld	ra,24(sp)
    80003806:	6442                	ld	s0,16(sp)
    80003808:	64a2                	ld	s1,8(sp)
    8000380a:	6902                	ld	s2,0(sp)
    8000380c:	6105                	addi	sp,sp,32
    8000380e:	8082                	ret
    panic("ilock");
    80003810:	00005517          	auipc	a0,0x5
    80003814:	dd850513          	addi	a0,a0,-552 # 800085e8 <syscalls+0x1a0>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	d22080e7          	jalr	-734(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003820:	40dc                	lw	a5,4(s1)
    80003822:	0047d79b          	srliw	a5,a5,0x4
    80003826:	0001c597          	auipc	a1,0x1c
    8000382a:	f9a5a583          	lw	a1,-102(a1) # 8001f7c0 <sb+0x18>
    8000382e:	9dbd                	addw	a1,a1,a5
    80003830:	4088                	lw	a0,0(s1)
    80003832:	fffff097          	auipc	ra,0xfffff
    80003836:	7ac080e7          	jalr	1964(ra) # 80002fde <bread>
    8000383a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000383c:	05850593          	addi	a1,a0,88
    80003840:	40dc                	lw	a5,4(s1)
    80003842:	8bbd                	andi	a5,a5,15
    80003844:	079a                	slli	a5,a5,0x6
    80003846:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003848:	00059783          	lh	a5,0(a1)
    8000384c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003850:	00259783          	lh	a5,2(a1)
    80003854:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003858:	00459783          	lh	a5,4(a1)
    8000385c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003860:	00659783          	lh	a5,6(a1)
    80003864:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003868:	459c                	lw	a5,8(a1)
    8000386a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000386c:	03400613          	li	a2,52
    80003870:	05b1                	addi	a1,a1,12
    80003872:	05048513          	addi	a0,s1,80
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	4b2080e7          	jalr	1202(ra) # 80000d28 <memmove>
    brelse(bp);
    8000387e:	854a                	mv	a0,s2
    80003880:	00000097          	auipc	ra,0x0
    80003884:	88e080e7          	jalr	-1906(ra) # 8000310e <brelse>
    ip->valid = 1;
    80003888:	4785                	li	a5,1
    8000388a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000388c:	04449783          	lh	a5,68(s1)
    80003890:	fbb5                	bnez	a5,80003804 <ilock+0x24>
      panic("ilock: no type");
    80003892:	00005517          	auipc	a0,0x5
    80003896:	d5e50513          	addi	a0,a0,-674 # 800085f0 <syscalls+0x1a8>
    8000389a:	ffffd097          	auipc	ra,0xffffd
    8000389e:	ca0080e7          	jalr	-864(ra) # 8000053a <panic>

00000000800038a2 <iunlock>:
{
    800038a2:	1101                	addi	sp,sp,-32
    800038a4:	ec06                	sd	ra,24(sp)
    800038a6:	e822                	sd	s0,16(sp)
    800038a8:	e426                	sd	s1,8(sp)
    800038aa:	e04a                	sd	s2,0(sp)
    800038ac:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038ae:	c905                	beqz	a0,800038de <iunlock+0x3c>
    800038b0:	84aa                	mv	s1,a0
    800038b2:	01050913          	addi	s2,a0,16
    800038b6:	854a                	mv	a0,s2
    800038b8:	00001097          	auipc	ra,0x1
    800038bc:	c92080e7          	jalr	-878(ra) # 8000454a <holdingsleep>
    800038c0:	cd19                	beqz	a0,800038de <iunlock+0x3c>
    800038c2:	449c                	lw	a5,8(s1)
    800038c4:	00f05d63          	blez	a5,800038de <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038c8:	854a                	mv	a0,s2
    800038ca:	00001097          	auipc	ra,0x1
    800038ce:	c3c080e7          	jalr	-964(ra) # 80004506 <releasesleep>
}
    800038d2:	60e2                	ld	ra,24(sp)
    800038d4:	6442                	ld	s0,16(sp)
    800038d6:	64a2                	ld	s1,8(sp)
    800038d8:	6902                	ld	s2,0(sp)
    800038da:	6105                	addi	sp,sp,32
    800038dc:	8082                	ret
    panic("iunlock");
    800038de:	00005517          	auipc	a0,0x5
    800038e2:	d2250513          	addi	a0,a0,-734 # 80008600 <syscalls+0x1b8>
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	c54080e7          	jalr	-940(ra) # 8000053a <panic>

00000000800038ee <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038ee:	7179                	addi	sp,sp,-48
    800038f0:	f406                	sd	ra,40(sp)
    800038f2:	f022                	sd	s0,32(sp)
    800038f4:	ec26                	sd	s1,24(sp)
    800038f6:	e84a                	sd	s2,16(sp)
    800038f8:	e44e                	sd	s3,8(sp)
    800038fa:	e052                	sd	s4,0(sp)
    800038fc:	1800                	addi	s0,sp,48
    800038fe:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003900:	05050493          	addi	s1,a0,80
    80003904:	08050913          	addi	s2,a0,128
    80003908:	a021                	j	80003910 <itrunc+0x22>
    8000390a:	0491                	addi	s1,s1,4
    8000390c:	01248d63          	beq	s1,s2,80003926 <itrunc+0x38>
    if(ip->addrs[i]){
    80003910:	408c                	lw	a1,0(s1)
    80003912:	dde5                	beqz	a1,8000390a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003914:	0009a503          	lw	a0,0(s3)
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	90c080e7          	jalr	-1780(ra) # 80003224 <bfree>
      ip->addrs[i] = 0;
    80003920:	0004a023          	sw	zero,0(s1)
    80003924:	b7dd                	j	8000390a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003926:	0809a583          	lw	a1,128(s3)
    8000392a:	e185                	bnez	a1,8000394a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000392c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003930:	854e                	mv	a0,s3
    80003932:	00000097          	auipc	ra,0x0
    80003936:	de2080e7          	jalr	-542(ra) # 80003714 <iupdate>
}
    8000393a:	70a2                	ld	ra,40(sp)
    8000393c:	7402                	ld	s0,32(sp)
    8000393e:	64e2                	ld	s1,24(sp)
    80003940:	6942                	ld	s2,16(sp)
    80003942:	69a2                	ld	s3,8(sp)
    80003944:	6a02                	ld	s4,0(sp)
    80003946:	6145                	addi	sp,sp,48
    80003948:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000394a:	0009a503          	lw	a0,0(s3)
    8000394e:	fffff097          	auipc	ra,0xfffff
    80003952:	690080e7          	jalr	1680(ra) # 80002fde <bread>
    80003956:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003958:	05850493          	addi	s1,a0,88
    8000395c:	45850913          	addi	s2,a0,1112
    80003960:	a021                	j	80003968 <itrunc+0x7a>
    80003962:	0491                	addi	s1,s1,4
    80003964:	01248b63          	beq	s1,s2,8000397a <itrunc+0x8c>
      if(a[j])
    80003968:	408c                	lw	a1,0(s1)
    8000396a:	dde5                	beqz	a1,80003962 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000396c:	0009a503          	lw	a0,0(s3)
    80003970:	00000097          	auipc	ra,0x0
    80003974:	8b4080e7          	jalr	-1868(ra) # 80003224 <bfree>
    80003978:	b7ed                	j	80003962 <itrunc+0x74>
    brelse(bp);
    8000397a:	8552                	mv	a0,s4
    8000397c:	fffff097          	auipc	ra,0xfffff
    80003980:	792080e7          	jalr	1938(ra) # 8000310e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003984:	0809a583          	lw	a1,128(s3)
    80003988:	0009a503          	lw	a0,0(s3)
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	898080e7          	jalr	-1896(ra) # 80003224 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003994:	0809a023          	sw	zero,128(s3)
    80003998:	bf51                	j	8000392c <itrunc+0x3e>

000000008000399a <iput>:
{
    8000399a:	1101                	addi	sp,sp,-32
    8000399c:	ec06                	sd	ra,24(sp)
    8000399e:	e822                	sd	s0,16(sp)
    800039a0:	e426                	sd	s1,8(sp)
    800039a2:	e04a                	sd	s2,0(sp)
    800039a4:	1000                	addi	s0,sp,32
    800039a6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039a8:	0001c517          	auipc	a0,0x1c
    800039ac:	e2050513          	addi	a0,a0,-480 # 8001f7c8 <itable>
    800039b0:	ffffd097          	auipc	ra,0xffffd
    800039b4:	220080e7          	jalr	544(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039b8:	4498                	lw	a4,8(s1)
    800039ba:	4785                	li	a5,1
    800039bc:	02f70363          	beq	a4,a5,800039e2 <iput+0x48>
  ip->ref--;
    800039c0:	449c                	lw	a5,8(s1)
    800039c2:	37fd                	addiw	a5,a5,-1
    800039c4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039c6:	0001c517          	auipc	a0,0x1c
    800039ca:	e0250513          	addi	a0,a0,-510 # 8001f7c8 <itable>
    800039ce:	ffffd097          	auipc	ra,0xffffd
    800039d2:	2b6080e7          	jalr	694(ra) # 80000c84 <release>
}
    800039d6:	60e2                	ld	ra,24(sp)
    800039d8:	6442                	ld	s0,16(sp)
    800039da:	64a2                	ld	s1,8(sp)
    800039dc:	6902                	ld	s2,0(sp)
    800039de:	6105                	addi	sp,sp,32
    800039e0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039e2:	40bc                	lw	a5,64(s1)
    800039e4:	dff1                	beqz	a5,800039c0 <iput+0x26>
    800039e6:	04a49783          	lh	a5,74(s1)
    800039ea:	fbf9                	bnez	a5,800039c0 <iput+0x26>
    acquiresleep(&ip->lock);
    800039ec:	01048913          	addi	s2,s1,16
    800039f0:	854a                	mv	a0,s2
    800039f2:	00001097          	auipc	ra,0x1
    800039f6:	abe080e7          	jalr	-1346(ra) # 800044b0 <acquiresleep>
    release(&itable.lock);
    800039fa:	0001c517          	auipc	a0,0x1c
    800039fe:	dce50513          	addi	a0,a0,-562 # 8001f7c8 <itable>
    80003a02:	ffffd097          	auipc	ra,0xffffd
    80003a06:	282080e7          	jalr	642(ra) # 80000c84 <release>
    itrunc(ip);
    80003a0a:	8526                	mv	a0,s1
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	ee2080e7          	jalr	-286(ra) # 800038ee <itrunc>
    ip->type = 0;
    80003a14:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a18:	8526                	mv	a0,s1
    80003a1a:	00000097          	auipc	ra,0x0
    80003a1e:	cfa080e7          	jalr	-774(ra) # 80003714 <iupdate>
    ip->valid = 0;
    80003a22:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a26:	854a                	mv	a0,s2
    80003a28:	00001097          	auipc	ra,0x1
    80003a2c:	ade080e7          	jalr	-1314(ra) # 80004506 <releasesleep>
    acquire(&itable.lock);
    80003a30:	0001c517          	auipc	a0,0x1c
    80003a34:	d9850513          	addi	a0,a0,-616 # 8001f7c8 <itable>
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	198080e7          	jalr	408(ra) # 80000bd0 <acquire>
    80003a40:	b741                	j	800039c0 <iput+0x26>

0000000080003a42 <iunlockput>:
{
    80003a42:	1101                	addi	sp,sp,-32
    80003a44:	ec06                	sd	ra,24(sp)
    80003a46:	e822                	sd	s0,16(sp)
    80003a48:	e426                	sd	s1,8(sp)
    80003a4a:	1000                	addi	s0,sp,32
    80003a4c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	e54080e7          	jalr	-428(ra) # 800038a2 <iunlock>
  iput(ip);
    80003a56:	8526                	mv	a0,s1
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	f42080e7          	jalr	-190(ra) # 8000399a <iput>
}
    80003a60:	60e2                	ld	ra,24(sp)
    80003a62:	6442                	ld	s0,16(sp)
    80003a64:	64a2                	ld	s1,8(sp)
    80003a66:	6105                	addi	sp,sp,32
    80003a68:	8082                	ret

0000000080003a6a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a6a:	1141                	addi	sp,sp,-16
    80003a6c:	e422                	sd	s0,8(sp)
    80003a6e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a70:	411c                	lw	a5,0(a0)
    80003a72:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a74:	415c                	lw	a5,4(a0)
    80003a76:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a78:	04451783          	lh	a5,68(a0)
    80003a7c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a80:	04a51783          	lh	a5,74(a0)
    80003a84:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a88:	04c56783          	lwu	a5,76(a0)
    80003a8c:	e99c                	sd	a5,16(a1)
}
    80003a8e:	6422                	ld	s0,8(sp)
    80003a90:	0141                	addi	sp,sp,16
    80003a92:	8082                	ret

0000000080003a94 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a94:	457c                	lw	a5,76(a0)
    80003a96:	0ed7e963          	bltu	a5,a3,80003b88 <readi+0xf4>
{
    80003a9a:	7159                	addi	sp,sp,-112
    80003a9c:	f486                	sd	ra,104(sp)
    80003a9e:	f0a2                	sd	s0,96(sp)
    80003aa0:	eca6                	sd	s1,88(sp)
    80003aa2:	e8ca                	sd	s2,80(sp)
    80003aa4:	e4ce                	sd	s3,72(sp)
    80003aa6:	e0d2                	sd	s4,64(sp)
    80003aa8:	fc56                	sd	s5,56(sp)
    80003aaa:	f85a                	sd	s6,48(sp)
    80003aac:	f45e                	sd	s7,40(sp)
    80003aae:	f062                	sd	s8,32(sp)
    80003ab0:	ec66                	sd	s9,24(sp)
    80003ab2:	e86a                	sd	s10,16(sp)
    80003ab4:	e46e                	sd	s11,8(sp)
    80003ab6:	1880                	addi	s0,sp,112
    80003ab8:	8baa                	mv	s7,a0
    80003aba:	8c2e                	mv	s8,a1
    80003abc:	8ab2                	mv	s5,a2
    80003abe:	84b6                	mv	s1,a3
    80003ac0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ac2:	9f35                	addw	a4,a4,a3
    return 0;
    80003ac4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ac6:	0ad76063          	bltu	a4,a3,80003b66 <readi+0xd2>
  if(off + n > ip->size)
    80003aca:	00e7f463          	bgeu	a5,a4,80003ad2 <readi+0x3e>
    n = ip->size - off;
    80003ace:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad2:	0a0b0963          	beqz	s6,80003b84 <readi+0xf0>
    80003ad6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ad8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003adc:	5cfd                	li	s9,-1
    80003ade:	a82d                	j	80003b18 <readi+0x84>
    80003ae0:	020a1d93          	slli	s11,s4,0x20
    80003ae4:	020ddd93          	srli	s11,s11,0x20
    80003ae8:	05890613          	addi	a2,s2,88
    80003aec:	86ee                	mv	a3,s11
    80003aee:	963a                	add	a2,a2,a4
    80003af0:	85d6                	mv	a1,s5
    80003af2:	8562                	mv	a0,s8
    80003af4:	fffff097          	auipc	ra,0xfffff
    80003af8:	90a080e7          	jalr	-1782(ra) # 800023fe <either_copyout>
    80003afc:	05950d63          	beq	a0,s9,80003b56 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b00:	854a                	mv	a0,s2
    80003b02:	fffff097          	auipc	ra,0xfffff
    80003b06:	60c080e7          	jalr	1548(ra) # 8000310e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b0a:	013a09bb          	addw	s3,s4,s3
    80003b0e:	009a04bb          	addw	s1,s4,s1
    80003b12:	9aee                	add	s5,s5,s11
    80003b14:	0569f763          	bgeu	s3,s6,80003b62 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b18:	000ba903          	lw	s2,0(s7)
    80003b1c:	00a4d59b          	srliw	a1,s1,0xa
    80003b20:	855e                	mv	a0,s7
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	8ac080e7          	jalr	-1876(ra) # 800033ce <bmap>
    80003b2a:	0005059b          	sext.w	a1,a0
    80003b2e:	854a                	mv	a0,s2
    80003b30:	fffff097          	auipc	ra,0xfffff
    80003b34:	4ae080e7          	jalr	1198(ra) # 80002fde <bread>
    80003b38:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b3a:	3ff4f713          	andi	a4,s1,1023
    80003b3e:	40ed07bb          	subw	a5,s10,a4
    80003b42:	413b06bb          	subw	a3,s6,s3
    80003b46:	8a3e                	mv	s4,a5
    80003b48:	2781                	sext.w	a5,a5
    80003b4a:	0006861b          	sext.w	a2,a3
    80003b4e:	f8f679e3          	bgeu	a2,a5,80003ae0 <readi+0x4c>
    80003b52:	8a36                	mv	s4,a3
    80003b54:	b771                	j	80003ae0 <readi+0x4c>
      brelse(bp);
    80003b56:	854a                	mv	a0,s2
    80003b58:	fffff097          	auipc	ra,0xfffff
    80003b5c:	5b6080e7          	jalr	1462(ra) # 8000310e <brelse>
      tot = -1;
    80003b60:	59fd                	li	s3,-1
  }
  return tot;
    80003b62:	0009851b          	sext.w	a0,s3
}
    80003b66:	70a6                	ld	ra,104(sp)
    80003b68:	7406                	ld	s0,96(sp)
    80003b6a:	64e6                	ld	s1,88(sp)
    80003b6c:	6946                	ld	s2,80(sp)
    80003b6e:	69a6                	ld	s3,72(sp)
    80003b70:	6a06                	ld	s4,64(sp)
    80003b72:	7ae2                	ld	s5,56(sp)
    80003b74:	7b42                	ld	s6,48(sp)
    80003b76:	7ba2                	ld	s7,40(sp)
    80003b78:	7c02                	ld	s8,32(sp)
    80003b7a:	6ce2                	ld	s9,24(sp)
    80003b7c:	6d42                	ld	s10,16(sp)
    80003b7e:	6da2                	ld	s11,8(sp)
    80003b80:	6165                	addi	sp,sp,112
    80003b82:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b84:	89da                	mv	s3,s6
    80003b86:	bff1                	j	80003b62 <readi+0xce>
    return 0;
    80003b88:	4501                	li	a0,0
}
    80003b8a:	8082                	ret

0000000080003b8c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b8c:	457c                	lw	a5,76(a0)
    80003b8e:	10d7e863          	bltu	a5,a3,80003c9e <writei+0x112>
{
    80003b92:	7159                	addi	sp,sp,-112
    80003b94:	f486                	sd	ra,104(sp)
    80003b96:	f0a2                	sd	s0,96(sp)
    80003b98:	eca6                	sd	s1,88(sp)
    80003b9a:	e8ca                	sd	s2,80(sp)
    80003b9c:	e4ce                	sd	s3,72(sp)
    80003b9e:	e0d2                	sd	s4,64(sp)
    80003ba0:	fc56                	sd	s5,56(sp)
    80003ba2:	f85a                	sd	s6,48(sp)
    80003ba4:	f45e                	sd	s7,40(sp)
    80003ba6:	f062                	sd	s8,32(sp)
    80003ba8:	ec66                	sd	s9,24(sp)
    80003baa:	e86a                	sd	s10,16(sp)
    80003bac:	e46e                	sd	s11,8(sp)
    80003bae:	1880                	addi	s0,sp,112
    80003bb0:	8b2a                	mv	s6,a0
    80003bb2:	8c2e                	mv	s8,a1
    80003bb4:	8ab2                	mv	s5,a2
    80003bb6:	8936                	mv	s2,a3
    80003bb8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003bba:	00e687bb          	addw	a5,a3,a4
    80003bbe:	0ed7e263          	bltu	a5,a3,80003ca2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bc2:	00043737          	lui	a4,0x43
    80003bc6:	0ef76063          	bltu	a4,a5,80003ca6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bca:	0c0b8863          	beqz	s7,80003c9a <writei+0x10e>
    80003bce:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bd4:	5cfd                	li	s9,-1
    80003bd6:	a091                	j	80003c1a <writei+0x8e>
    80003bd8:	02099d93          	slli	s11,s3,0x20
    80003bdc:	020ddd93          	srli	s11,s11,0x20
    80003be0:	05848513          	addi	a0,s1,88
    80003be4:	86ee                	mv	a3,s11
    80003be6:	8656                	mv	a2,s5
    80003be8:	85e2                	mv	a1,s8
    80003bea:	953a                	add	a0,a0,a4
    80003bec:	fffff097          	auipc	ra,0xfffff
    80003bf0:	868080e7          	jalr	-1944(ra) # 80002454 <either_copyin>
    80003bf4:	07950263          	beq	a0,s9,80003c58 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bf8:	8526                	mv	a0,s1
    80003bfa:	00000097          	auipc	ra,0x0
    80003bfe:	798080e7          	jalr	1944(ra) # 80004392 <log_write>
    brelse(bp);
    80003c02:	8526                	mv	a0,s1
    80003c04:	fffff097          	auipc	ra,0xfffff
    80003c08:	50a080e7          	jalr	1290(ra) # 8000310e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c0c:	01498a3b          	addw	s4,s3,s4
    80003c10:	0129893b          	addw	s2,s3,s2
    80003c14:	9aee                	add	s5,s5,s11
    80003c16:	057a7663          	bgeu	s4,s7,80003c62 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c1a:	000b2483          	lw	s1,0(s6)
    80003c1e:	00a9559b          	srliw	a1,s2,0xa
    80003c22:	855a                	mv	a0,s6
    80003c24:	fffff097          	auipc	ra,0xfffff
    80003c28:	7aa080e7          	jalr	1962(ra) # 800033ce <bmap>
    80003c2c:	0005059b          	sext.w	a1,a0
    80003c30:	8526                	mv	a0,s1
    80003c32:	fffff097          	auipc	ra,0xfffff
    80003c36:	3ac080e7          	jalr	940(ra) # 80002fde <bread>
    80003c3a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c3c:	3ff97713          	andi	a4,s2,1023
    80003c40:	40ed07bb          	subw	a5,s10,a4
    80003c44:	414b86bb          	subw	a3,s7,s4
    80003c48:	89be                	mv	s3,a5
    80003c4a:	2781                	sext.w	a5,a5
    80003c4c:	0006861b          	sext.w	a2,a3
    80003c50:	f8f674e3          	bgeu	a2,a5,80003bd8 <writei+0x4c>
    80003c54:	89b6                	mv	s3,a3
    80003c56:	b749                	j	80003bd8 <writei+0x4c>
      brelse(bp);
    80003c58:	8526                	mv	a0,s1
    80003c5a:	fffff097          	auipc	ra,0xfffff
    80003c5e:	4b4080e7          	jalr	1204(ra) # 8000310e <brelse>
  }

  if(off > ip->size)
    80003c62:	04cb2783          	lw	a5,76(s6)
    80003c66:	0127f463          	bgeu	a5,s2,80003c6e <writei+0xe2>
    ip->size = off;
    80003c6a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c6e:	855a                	mv	a0,s6
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	aa4080e7          	jalr	-1372(ra) # 80003714 <iupdate>

  return tot;
    80003c78:	000a051b          	sext.w	a0,s4
}
    80003c7c:	70a6                	ld	ra,104(sp)
    80003c7e:	7406                	ld	s0,96(sp)
    80003c80:	64e6                	ld	s1,88(sp)
    80003c82:	6946                	ld	s2,80(sp)
    80003c84:	69a6                	ld	s3,72(sp)
    80003c86:	6a06                	ld	s4,64(sp)
    80003c88:	7ae2                	ld	s5,56(sp)
    80003c8a:	7b42                	ld	s6,48(sp)
    80003c8c:	7ba2                	ld	s7,40(sp)
    80003c8e:	7c02                	ld	s8,32(sp)
    80003c90:	6ce2                	ld	s9,24(sp)
    80003c92:	6d42                	ld	s10,16(sp)
    80003c94:	6da2                	ld	s11,8(sp)
    80003c96:	6165                	addi	sp,sp,112
    80003c98:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c9a:	8a5e                	mv	s4,s7
    80003c9c:	bfc9                	j	80003c6e <writei+0xe2>
    return -1;
    80003c9e:	557d                	li	a0,-1
}
    80003ca0:	8082                	ret
    return -1;
    80003ca2:	557d                	li	a0,-1
    80003ca4:	bfe1                	j	80003c7c <writei+0xf0>
    return -1;
    80003ca6:	557d                	li	a0,-1
    80003ca8:	bfd1                	j	80003c7c <writei+0xf0>

0000000080003caa <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003caa:	1141                	addi	sp,sp,-16
    80003cac:	e406                	sd	ra,8(sp)
    80003cae:	e022                	sd	s0,0(sp)
    80003cb0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cb2:	4639                	li	a2,14
    80003cb4:	ffffd097          	auipc	ra,0xffffd
    80003cb8:	0e8080e7          	jalr	232(ra) # 80000d9c <strncmp>
}
    80003cbc:	60a2                	ld	ra,8(sp)
    80003cbe:	6402                	ld	s0,0(sp)
    80003cc0:	0141                	addi	sp,sp,16
    80003cc2:	8082                	ret

0000000080003cc4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cc4:	7139                	addi	sp,sp,-64
    80003cc6:	fc06                	sd	ra,56(sp)
    80003cc8:	f822                	sd	s0,48(sp)
    80003cca:	f426                	sd	s1,40(sp)
    80003ccc:	f04a                	sd	s2,32(sp)
    80003cce:	ec4e                	sd	s3,24(sp)
    80003cd0:	e852                	sd	s4,16(sp)
    80003cd2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cd4:	04451703          	lh	a4,68(a0)
    80003cd8:	4785                	li	a5,1
    80003cda:	00f71a63          	bne	a4,a5,80003cee <dirlookup+0x2a>
    80003cde:	892a                	mv	s2,a0
    80003ce0:	89ae                	mv	s3,a1
    80003ce2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce4:	457c                	lw	a5,76(a0)
    80003ce6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ce8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cea:	e79d                	bnez	a5,80003d18 <dirlookup+0x54>
    80003cec:	a8a5                	j	80003d64 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cee:	00005517          	auipc	a0,0x5
    80003cf2:	91a50513          	addi	a0,a0,-1766 # 80008608 <syscalls+0x1c0>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	844080e7          	jalr	-1980(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003cfe:	00005517          	auipc	a0,0x5
    80003d02:	92250513          	addi	a0,a0,-1758 # 80008620 <syscalls+0x1d8>
    80003d06:	ffffd097          	auipc	ra,0xffffd
    80003d0a:	834080e7          	jalr	-1996(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d0e:	24c1                	addiw	s1,s1,16
    80003d10:	04c92783          	lw	a5,76(s2)
    80003d14:	04f4f763          	bgeu	s1,a5,80003d62 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d18:	4741                	li	a4,16
    80003d1a:	86a6                	mv	a3,s1
    80003d1c:	fc040613          	addi	a2,s0,-64
    80003d20:	4581                	li	a1,0
    80003d22:	854a                	mv	a0,s2
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	d70080e7          	jalr	-656(ra) # 80003a94 <readi>
    80003d2c:	47c1                	li	a5,16
    80003d2e:	fcf518e3          	bne	a0,a5,80003cfe <dirlookup+0x3a>
    if(de.inum == 0)
    80003d32:	fc045783          	lhu	a5,-64(s0)
    80003d36:	dfe1                	beqz	a5,80003d0e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d38:	fc240593          	addi	a1,s0,-62
    80003d3c:	854e                	mv	a0,s3
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	f6c080e7          	jalr	-148(ra) # 80003caa <namecmp>
    80003d46:	f561                	bnez	a0,80003d0e <dirlookup+0x4a>
      if(poff)
    80003d48:	000a0463          	beqz	s4,80003d50 <dirlookup+0x8c>
        *poff = off;
    80003d4c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d50:	fc045583          	lhu	a1,-64(s0)
    80003d54:	00092503          	lw	a0,0(s2)
    80003d58:	fffff097          	auipc	ra,0xfffff
    80003d5c:	752080e7          	jalr	1874(ra) # 800034aa <iget>
    80003d60:	a011                	j	80003d64 <dirlookup+0xa0>
  return 0;
    80003d62:	4501                	li	a0,0
}
    80003d64:	70e2                	ld	ra,56(sp)
    80003d66:	7442                	ld	s0,48(sp)
    80003d68:	74a2                	ld	s1,40(sp)
    80003d6a:	7902                	ld	s2,32(sp)
    80003d6c:	69e2                	ld	s3,24(sp)
    80003d6e:	6a42                	ld	s4,16(sp)
    80003d70:	6121                	addi	sp,sp,64
    80003d72:	8082                	ret

0000000080003d74 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d74:	711d                	addi	sp,sp,-96
    80003d76:	ec86                	sd	ra,88(sp)
    80003d78:	e8a2                	sd	s0,80(sp)
    80003d7a:	e4a6                	sd	s1,72(sp)
    80003d7c:	e0ca                	sd	s2,64(sp)
    80003d7e:	fc4e                	sd	s3,56(sp)
    80003d80:	f852                	sd	s4,48(sp)
    80003d82:	f456                	sd	s5,40(sp)
    80003d84:	f05a                	sd	s6,32(sp)
    80003d86:	ec5e                	sd	s7,24(sp)
    80003d88:	e862                	sd	s8,16(sp)
    80003d8a:	e466                	sd	s9,8(sp)
    80003d8c:	e06a                	sd	s10,0(sp)
    80003d8e:	1080                	addi	s0,sp,96
    80003d90:	84aa                	mv	s1,a0
    80003d92:	8b2e                	mv	s6,a1
    80003d94:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d96:	00054703          	lbu	a4,0(a0)
    80003d9a:	02f00793          	li	a5,47
    80003d9e:	02f70363          	beq	a4,a5,80003dc4 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003da2:	ffffe097          	auipc	ra,0xffffe
    80003da6:	bf4080e7          	jalr	-1036(ra) # 80001996 <myproc>
    80003daa:	15053503          	ld	a0,336(a0)
    80003dae:	00000097          	auipc	ra,0x0
    80003db2:	9f4080e7          	jalr	-1548(ra) # 800037a2 <idup>
    80003db6:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003db8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003dbc:	4cb5                	li	s9,13
  len = path - s;
    80003dbe:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dc0:	4c05                	li	s8,1
    80003dc2:	a87d                	j	80003e80 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003dc4:	4585                	li	a1,1
    80003dc6:	4505                	li	a0,1
    80003dc8:	fffff097          	auipc	ra,0xfffff
    80003dcc:	6e2080e7          	jalr	1762(ra) # 800034aa <iget>
    80003dd0:	8a2a                	mv	s4,a0
    80003dd2:	b7dd                	j	80003db8 <namex+0x44>
      iunlockput(ip);
    80003dd4:	8552                	mv	a0,s4
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	c6c080e7          	jalr	-916(ra) # 80003a42 <iunlockput>
      return 0;
    80003dde:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003de0:	8552                	mv	a0,s4
    80003de2:	60e6                	ld	ra,88(sp)
    80003de4:	6446                	ld	s0,80(sp)
    80003de6:	64a6                	ld	s1,72(sp)
    80003de8:	6906                	ld	s2,64(sp)
    80003dea:	79e2                	ld	s3,56(sp)
    80003dec:	7a42                	ld	s4,48(sp)
    80003dee:	7aa2                	ld	s5,40(sp)
    80003df0:	7b02                	ld	s6,32(sp)
    80003df2:	6be2                	ld	s7,24(sp)
    80003df4:	6c42                	ld	s8,16(sp)
    80003df6:	6ca2                	ld	s9,8(sp)
    80003df8:	6d02                	ld	s10,0(sp)
    80003dfa:	6125                	addi	sp,sp,96
    80003dfc:	8082                	ret
      iunlock(ip);
    80003dfe:	8552                	mv	a0,s4
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	aa2080e7          	jalr	-1374(ra) # 800038a2 <iunlock>
      return ip;
    80003e08:	bfe1                	j	80003de0 <namex+0x6c>
      iunlockput(ip);
    80003e0a:	8552                	mv	a0,s4
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	c36080e7          	jalr	-970(ra) # 80003a42 <iunlockput>
      return 0;
    80003e14:	8a4e                	mv	s4,s3
    80003e16:	b7e9                	j	80003de0 <namex+0x6c>
  len = path - s;
    80003e18:	40998633          	sub	a2,s3,s1
    80003e1c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003e20:	09acd863          	bge	s9,s10,80003eb0 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003e24:	4639                	li	a2,14
    80003e26:	85a6                	mv	a1,s1
    80003e28:	8556                	mv	a0,s5
    80003e2a:	ffffd097          	auipc	ra,0xffffd
    80003e2e:	efe080e7          	jalr	-258(ra) # 80000d28 <memmove>
    80003e32:	84ce                	mv	s1,s3
  while(*path == '/')
    80003e34:	0004c783          	lbu	a5,0(s1)
    80003e38:	01279763          	bne	a5,s2,80003e46 <namex+0xd2>
    path++;
    80003e3c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e3e:	0004c783          	lbu	a5,0(s1)
    80003e42:	ff278de3          	beq	a5,s2,80003e3c <namex+0xc8>
    ilock(ip);
    80003e46:	8552                	mv	a0,s4
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	998080e7          	jalr	-1640(ra) # 800037e0 <ilock>
    if(ip->type != T_DIR){
    80003e50:	044a1783          	lh	a5,68(s4)
    80003e54:	f98790e3          	bne	a5,s8,80003dd4 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003e58:	000b0563          	beqz	s6,80003e62 <namex+0xee>
    80003e5c:	0004c783          	lbu	a5,0(s1)
    80003e60:	dfd9                	beqz	a5,80003dfe <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e62:	865e                	mv	a2,s7
    80003e64:	85d6                	mv	a1,s5
    80003e66:	8552                	mv	a0,s4
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	e5c080e7          	jalr	-420(ra) # 80003cc4 <dirlookup>
    80003e70:	89aa                	mv	s3,a0
    80003e72:	dd41                	beqz	a0,80003e0a <namex+0x96>
    iunlockput(ip);
    80003e74:	8552                	mv	a0,s4
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	bcc080e7          	jalr	-1076(ra) # 80003a42 <iunlockput>
    ip = next;
    80003e7e:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e80:	0004c783          	lbu	a5,0(s1)
    80003e84:	01279763          	bne	a5,s2,80003e92 <namex+0x11e>
    path++;
    80003e88:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e8a:	0004c783          	lbu	a5,0(s1)
    80003e8e:	ff278de3          	beq	a5,s2,80003e88 <namex+0x114>
  if(*path == 0)
    80003e92:	cb9d                	beqz	a5,80003ec8 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003e94:	0004c783          	lbu	a5,0(s1)
    80003e98:	89a6                	mv	s3,s1
  len = path - s;
    80003e9a:	8d5e                	mv	s10,s7
    80003e9c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e9e:	01278963          	beq	a5,s2,80003eb0 <namex+0x13c>
    80003ea2:	dbbd                	beqz	a5,80003e18 <namex+0xa4>
    path++;
    80003ea4:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003ea6:	0009c783          	lbu	a5,0(s3)
    80003eaa:	ff279ce3          	bne	a5,s2,80003ea2 <namex+0x12e>
    80003eae:	b7ad                	j	80003e18 <namex+0xa4>
    memmove(name, s, len);
    80003eb0:	2601                	sext.w	a2,a2
    80003eb2:	85a6                	mv	a1,s1
    80003eb4:	8556                	mv	a0,s5
    80003eb6:	ffffd097          	auipc	ra,0xffffd
    80003eba:	e72080e7          	jalr	-398(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003ebe:	9d56                	add	s10,s10,s5
    80003ec0:	000d0023          	sb	zero,0(s10)
    80003ec4:	84ce                	mv	s1,s3
    80003ec6:	b7bd                	j	80003e34 <namex+0xc0>
  if(nameiparent){
    80003ec8:	f00b0ce3          	beqz	s6,80003de0 <namex+0x6c>
    iput(ip);
    80003ecc:	8552                	mv	a0,s4
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	acc080e7          	jalr	-1332(ra) # 8000399a <iput>
    return 0;
    80003ed6:	4a01                	li	s4,0
    80003ed8:	b721                	j	80003de0 <namex+0x6c>

0000000080003eda <dirlink>:
{
    80003eda:	7139                	addi	sp,sp,-64
    80003edc:	fc06                	sd	ra,56(sp)
    80003ede:	f822                	sd	s0,48(sp)
    80003ee0:	f426                	sd	s1,40(sp)
    80003ee2:	f04a                	sd	s2,32(sp)
    80003ee4:	ec4e                	sd	s3,24(sp)
    80003ee6:	e852                	sd	s4,16(sp)
    80003ee8:	0080                	addi	s0,sp,64
    80003eea:	892a                	mv	s2,a0
    80003eec:	8a2e                	mv	s4,a1
    80003eee:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ef0:	4601                	li	a2,0
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	dd2080e7          	jalr	-558(ra) # 80003cc4 <dirlookup>
    80003efa:	e93d                	bnez	a0,80003f70 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003efc:	04c92483          	lw	s1,76(s2)
    80003f00:	c49d                	beqz	s1,80003f2e <dirlink+0x54>
    80003f02:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f04:	4741                	li	a4,16
    80003f06:	86a6                	mv	a3,s1
    80003f08:	fc040613          	addi	a2,s0,-64
    80003f0c:	4581                	li	a1,0
    80003f0e:	854a                	mv	a0,s2
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	b84080e7          	jalr	-1148(ra) # 80003a94 <readi>
    80003f18:	47c1                	li	a5,16
    80003f1a:	06f51163          	bne	a0,a5,80003f7c <dirlink+0xa2>
    if(de.inum == 0)
    80003f1e:	fc045783          	lhu	a5,-64(s0)
    80003f22:	c791                	beqz	a5,80003f2e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f24:	24c1                	addiw	s1,s1,16
    80003f26:	04c92783          	lw	a5,76(s2)
    80003f2a:	fcf4ede3          	bltu	s1,a5,80003f04 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f2e:	4639                	li	a2,14
    80003f30:	85d2                	mv	a1,s4
    80003f32:	fc240513          	addi	a0,s0,-62
    80003f36:	ffffd097          	auipc	ra,0xffffd
    80003f3a:	ea2080e7          	jalr	-350(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003f3e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f42:	4741                	li	a4,16
    80003f44:	86a6                	mv	a3,s1
    80003f46:	fc040613          	addi	a2,s0,-64
    80003f4a:	4581                	li	a1,0
    80003f4c:	854a                	mv	a0,s2
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	c3e080e7          	jalr	-962(ra) # 80003b8c <writei>
    80003f56:	872a                	mv	a4,a0
    80003f58:	47c1                	li	a5,16
  return 0;
    80003f5a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f5c:	02f71863          	bne	a4,a5,80003f8c <dirlink+0xb2>
}
    80003f60:	70e2                	ld	ra,56(sp)
    80003f62:	7442                	ld	s0,48(sp)
    80003f64:	74a2                	ld	s1,40(sp)
    80003f66:	7902                	ld	s2,32(sp)
    80003f68:	69e2                	ld	s3,24(sp)
    80003f6a:	6a42                	ld	s4,16(sp)
    80003f6c:	6121                	addi	sp,sp,64
    80003f6e:	8082                	ret
    iput(ip);
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	a2a080e7          	jalr	-1494(ra) # 8000399a <iput>
    return -1;
    80003f78:	557d                	li	a0,-1
    80003f7a:	b7dd                	j	80003f60 <dirlink+0x86>
      panic("dirlink read");
    80003f7c:	00004517          	auipc	a0,0x4
    80003f80:	6b450513          	addi	a0,a0,1716 # 80008630 <syscalls+0x1e8>
    80003f84:	ffffc097          	auipc	ra,0xffffc
    80003f88:	5b6080e7          	jalr	1462(ra) # 8000053a <panic>
    panic("dirlink");
    80003f8c:	00004517          	auipc	a0,0x4
    80003f90:	7b450513          	addi	a0,a0,1972 # 80008740 <syscalls+0x2f8>
    80003f94:	ffffc097          	auipc	ra,0xffffc
    80003f98:	5a6080e7          	jalr	1446(ra) # 8000053a <panic>

0000000080003f9c <namei>:

struct inode*
namei(char *path)
{
    80003f9c:	1101                	addi	sp,sp,-32
    80003f9e:	ec06                	sd	ra,24(sp)
    80003fa0:	e822                	sd	s0,16(sp)
    80003fa2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fa4:	fe040613          	addi	a2,s0,-32
    80003fa8:	4581                	li	a1,0
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	dca080e7          	jalr	-566(ra) # 80003d74 <namex>
}
    80003fb2:	60e2                	ld	ra,24(sp)
    80003fb4:	6442                	ld	s0,16(sp)
    80003fb6:	6105                	addi	sp,sp,32
    80003fb8:	8082                	ret

0000000080003fba <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fba:	1141                	addi	sp,sp,-16
    80003fbc:	e406                	sd	ra,8(sp)
    80003fbe:	e022                	sd	s0,0(sp)
    80003fc0:	0800                	addi	s0,sp,16
    80003fc2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fc4:	4585                	li	a1,1
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	dae080e7          	jalr	-594(ra) # 80003d74 <namex>
}
    80003fce:	60a2                	ld	ra,8(sp)
    80003fd0:	6402                	ld	s0,0(sp)
    80003fd2:	0141                	addi	sp,sp,16
    80003fd4:	8082                	ret

0000000080003fd6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fd6:	1101                	addi	sp,sp,-32
    80003fd8:	ec06                	sd	ra,24(sp)
    80003fda:	e822                	sd	s0,16(sp)
    80003fdc:	e426                	sd	s1,8(sp)
    80003fde:	e04a                	sd	s2,0(sp)
    80003fe0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fe2:	0001d917          	auipc	s2,0x1d
    80003fe6:	28e90913          	addi	s2,s2,654 # 80021270 <log>
    80003fea:	01892583          	lw	a1,24(s2)
    80003fee:	02892503          	lw	a0,40(s2)
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	fec080e7          	jalr	-20(ra) # 80002fde <bread>
    80003ffa:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ffc:	02c92683          	lw	a3,44(s2)
    80004000:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004002:	02d05863          	blez	a3,80004032 <write_head+0x5c>
    80004006:	0001d797          	auipc	a5,0x1d
    8000400a:	29a78793          	addi	a5,a5,666 # 800212a0 <log+0x30>
    8000400e:	05c50713          	addi	a4,a0,92
    80004012:	36fd                	addiw	a3,a3,-1
    80004014:	02069613          	slli	a2,a3,0x20
    80004018:	01e65693          	srli	a3,a2,0x1e
    8000401c:	0001d617          	auipc	a2,0x1d
    80004020:	28860613          	addi	a2,a2,648 # 800212a4 <log+0x34>
    80004024:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004026:	4390                	lw	a2,0(a5)
    80004028:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000402a:	0791                	addi	a5,a5,4
    8000402c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000402e:	fed79ce3          	bne	a5,a3,80004026 <write_head+0x50>
  }
  bwrite(buf);
    80004032:	8526                	mv	a0,s1
    80004034:	fffff097          	auipc	ra,0xfffff
    80004038:	09c080e7          	jalr	156(ra) # 800030d0 <bwrite>
  brelse(buf);
    8000403c:	8526                	mv	a0,s1
    8000403e:	fffff097          	auipc	ra,0xfffff
    80004042:	0d0080e7          	jalr	208(ra) # 8000310e <brelse>
}
    80004046:	60e2                	ld	ra,24(sp)
    80004048:	6442                	ld	s0,16(sp)
    8000404a:	64a2                	ld	s1,8(sp)
    8000404c:	6902                	ld	s2,0(sp)
    8000404e:	6105                	addi	sp,sp,32
    80004050:	8082                	ret

0000000080004052 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004052:	0001d797          	auipc	a5,0x1d
    80004056:	24a7a783          	lw	a5,586(a5) # 8002129c <log+0x2c>
    8000405a:	0af05d63          	blez	a5,80004114 <install_trans+0xc2>
{
    8000405e:	7139                	addi	sp,sp,-64
    80004060:	fc06                	sd	ra,56(sp)
    80004062:	f822                	sd	s0,48(sp)
    80004064:	f426                	sd	s1,40(sp)
    80004066:	f04a                	sd	s2,32(sp)
    80004068:	ec4e                	sd	s3,24(sp)
    8000406a:	e852                	sd	s4,16(sp)
    8000406c:	e456                	sd	s5,8(sp)
    8000406e:	e05a                	sd	s6,0(sp)
    80004070:	0080                	addi	s0,sp,64
    80004072:	8b2a                	mv	s6,a0
    80004074:	0001da97          	auipc	s5,0x1d
    80004078:	22ca8a93          	addi	s5,s5,556 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000407c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000407e:	0001d997          	auipc	s3,0x1d
    80004082:	1f298993          	addi	s3,s3,498 # 80021270 <log>
    80004086:	a00d                	j	800040a8 <install_trans+0x56>
    brelse(lbuf);
    80004088:	854a                	mv	a0,s2
    8000408a:	fffff097          	auipc	ra,0xfffff
    8000408e:	084080e7          	jalr	132(ra) # 8000310e <brelse>
    brelse(dbuf);
    80004092:	8526                	mv	a0,s1
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	07a080e7          	jalr	122(ra) # 8000310e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000409c:	2a05                	addiw	s4,s4,1
    8000409e:	0a91                	addi	s5,s5,4
    800040a0:	02c9a783          	lw	a5,44(s3)
    800040a4:	04fa5e63          	bge	s4,a5,80004100 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040a8:	0189a583          	lw	a1,24(s3)
    800040ac:	014585bb          	addw	a1,a1,s4
    800040b0:	2585                	addiw	a1,a1,1
    800040b2:	0289a503          	lw	a0,40(s3)
    800040b6:	fffff097          	auipc	ra,0xfffff
    800040ba:	f28080e7          	jalr	-216(ra) # 80002fde <bread>
    800040be:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040c0:	000aa583          	lw	a1,0(s5)
    800040c4:	0289a503          	lw	a0,40(s3)
    800040c8:	fffff097          	auipc	ra,0xfffff
    800040cc:	f16080e7          	jalr	-234(ra) # 80002fde <bread>
    800040d0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040d2:	40000613          	li	a2,1024
    800040d6:	05890593          	addi	a1,s2,88
    800040da:	05850513          	addi	a0,a0,88
    800040de:	ffffd097          	auipc	ra,0xffffd
    800040e2:	c4a080e7          	jalr	-950(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040e6:	8526                	mv	a0,s1
    800040e8:	fffff097          	auipc	ra,0xfffff
    800040ec:	fe8080e7          	jalr	-24(ra) # 800030d0 <bwrite>
    if(recovering == 0)
    800040f0:	f80b1ce3          	bnez	s6,80004088 <install_trans+0x36>
      bunpin(dbuf);
    800040f4:	8526                	mv	a0,s1
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	0f2080e7          	jalr	242(ra) # 800031e8 <bunpin>
    800040fe:	b769                	j	80004088 <install_trans+0x36>
}
    80004100:	70e2                	ld	ra,56(sp)
    80004102:	7442                	ld	s0,48(sp)
    80004104:	74a2                	ld	s1,40(sp)
    80004106:	7902                	ld	s2,32(sp)
    80004108:	69e2                	ld	s3,24(sp)
    8000410a:	6a42                	ld	s4,16(sp)
    8000410c:	6aa2                	ld	s5,8(sp)
    8000410e:	6b02                	ld	s6,0(sp)
    80004110:	6121                	addi	sp,sp,64
    80004112:	8082                	ret
    80004114:	8082                	ret

0000000080004116 <initlog>:
{
    80004116:	7179                	addi	sp,sp,-48
    80004118:	f406                	sd	ra,40(sp)
    8000411a:	f022                	sd	s0,32(sp)
    8000411c:	ec26                	sd	s1,24(sp)
    8000411e:	e84a                	sd	s2,16(sp)
    80004120:	e44e                	sd	s3,8(sp)
    80004122:	1800                	addi	s0,sp,48
    80004124:	892a                	mv	s2,a0
    80004126:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004128:	0001d497          	auipc	s1,0x1d
    8000412c:	14848493          	addi	s1,s1,328 # 80021270 <log>
    80004130:	00004597          	auipc	a1,0x4
    80004134:	51058593          	addi	a1,a1,1296 # 80008640 <syscalls+0x1f8>
    80004138:	8526                	mv	a0,s1
    8000413a:	ffffd097          	auipc	ra,0xffffd
    8000413e:	a06080e7          	jalr	-1530(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80004142:	0149a583          	lw	a1,20(s3)
    80004146:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004148:	0109a783          	lw	a5,16(s3)
    8000414c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000414e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004152:	854a                	mv	a0,s2
    80004154:	fffff097          	auipc	ra,0xfffff
    80004158:	e8a080e7          	jalr	-374(ra) # 80002fde <bread>
  log.lh.n = lh->n;
    8000415c:	4d34                	lw	a3,88(a0)
    8000415e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004160:	02d05663          	blez	a3,8000418c <initlog+0x76>
    80004164:	05c50793          	addi	a5,a0,92
    80004168:	0001d717          	auipc	a4,0x1d
    8000416c:	13870713          	addi	a4,a4,312 # 800212a0 <log+0x30>
    80004170:	36fd                	addiw	a3,a3,-1
    80004172:	02069613          	slli	a2,a3,0x20
    80004176:	01e65693          	srli	a3,a2,0x1e
    8000417a:	06050613          	addi	a2,a0,96
    8000417e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004180:	4390                	lw	a2,0(a5)
    80004182:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004184:	0791                	addi	a5,a5,4
    80004186:	0711                	addi	a4,a4,4
    80004188:	fed79ce3          	bne	a5,a3,80004180 <initlog+0x6a>
  brelse(buf);
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	f82080e7          	jalr	-126(ra) # 8000310e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004194:	4505                	li	a0,1
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	ebc080e7          	jalr	-324(ra) # 80004052 <install_trans>
  log.lh.n = 0;
    8000419e:	0001d797          	auipc	a5,0x1d
    800041a2:	0e07af23          	sw	zero,254(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800041a6:	00000097          	auipc	ra,0x0
    800041aa:	e30080e7          	jalr	-464(ra) # 80003fd6 <write_head>
}
    800041ae:	70a2                	ld	ra,40(sp)
    800041b0:	7402                	ld	s0,32(sp)
    800041b2:	64e2                	ld	s1,24(sp)
    800041b4:	6942                	ld	s2,16(sp)
    800041b6:	69a2                	ld	s3,8(sp)
    800041b8:	6145                	addi	sp,sp,48
    800041ba:	8082                	ret

00000000800041bc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041bc:	1101                	addi	sp,sp,-32
    800041be:	ec06                	sd	ra,24(sp)
    800041c0:	e822                	sd	s0,16(sp)
    800041c2:	e426                	sd	s1,8(sp)
    800041c4:	e04a                	sd	s2,0(sp)
    800041c6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041c8:	0001d517          	auipc	a0,0x1d
    800041cc:	0a850513          	addi	a0,a0,168 # 80021270 <log>
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	a00080e7          	jalr	-1536(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    800041d8:	0001d497          	auipc	s1,0x1d
    800041dc:	09848493          	addi	s1,s1,152 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041e0:	4979                	li	s2,30
    800041e2:	a039                	j	800041f0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041e4:	85a6                	mv	a1,s1
    800041e6:	8526                	mv	a0,s1
    800041e8:	ffffe097          	auipc	ra,0xffffe
    800041ec:	e72080e7          	jalr	-398(ra) # 8000205a <sleep>
    if(log.committing){
    800041f0:	50dc                	lw	a5,36(s1)
    800041f2:	fbed                	bnez	a5,800041e4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041f4:	5098                	lw	a4,32(s1)
    800041f6:	2705                	addiw	a4,a4,1
    800041f8:	0007069b          	sext.w	a3,a4
    800041fc:	0027179b          	slliw	a5,a4,0x2
    80004200:	9fb9                	addw	a5,a5,a4
    80004202:	0017979b          	slliw	a5,a5,0x1
    80004206:	54d8                	lw	a4,44(s1)
    80004208:	9fb9                	addw	a5,a5,a4
    8000420a:	00f95963          	bge	s2,a5,8000421c <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000420e:	85a6                	mv	a1,s1
    80004210:	8526                	mv	a0,s1
    80004212:	ffffe097          	auipc	ra,0xffffe
    80004216:	e48080e7          	jalr	-440(ra) # 8000205a <sleep>
    8000421a:	bfd9                	j	800041f0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000421c:	0001d517          	auipc	a0,0x1d
    80004220:	05450513          	addi	a0,a0,84 # 80021270 <log>
    80004224:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	a5e080e7          	jalr	-1442(ra) # 80000c84 <release>
      break;
    }
  }
}
    8000422e:	60e2                	ld	ra,24(sp)
    80004230:	6442                	ld	s0,16(sp)
    80004232:	64a2                	ld	s1,8(sp)
    80004234:	6902                	ld	s2,0(sp)
    80004236:	6105                	addi	sp,sp,32
    80004238:	8082                	ret

000000008000423a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000423a:	7139                	addi	sp,sp,-64
    8000423c:	fc06                	sd	ra,56(sp)
    8000423e:	f822                	sd	s0,48(sp)
    80004240:	f426                	sd	s1,40(sp)
    80004242:	f04a                	sd	s2,32(sp)
    80004244:	ec4e                	sd	s3,24(sp)
    80004246:	e852                	sd	s4,16(sp)
    80004248:	e456                	sd	s5,8(sp)
    8000424a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000424c:	0001d497          	auipc	s1,0x1d
    80004250:	02448493          	addi	s1,s1,36 # 80021270 <log>
    80004254:	8526                	mv	a0,s1
    80004256:	ffffd097          	auipc	ra,0xffffd
    8000425a:	97a080e7          	jalr	-1670(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    8000425e:	509c                	lw	a5,32(s1)
    80004260:	37fd                	addiw	a5,a5,-1
    80004262:	0007891b          	sext.w	s2,a5
    80004266:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004268:	50dc                	lw	a5,36(s1)
    8000426a:	e7b9                	bnez	a5,800042b8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000426c:	04091e63          	bnez	s2,800042c8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004270:	0001d497          	auipc	s1,0x1d
    80004274:	00048493          	mv	s1,s1
    80004278:	4785                	li	a5,1
    8000427a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000427c:	8526                	mv	a0,s1
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	a06080e7          	jalr	-1530(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004286:	54dc                	lw	a5,44(s1)
    80004288:	06f04763          	bgtz	a5,800042f6 <end_op+0xbc>
    acquire(&log.lock);
    8000428c:	0001d497          	auipc	s1,0x1d
    80004290:	fe448493          	addi	s1,s1,-28 # 80021270 <log>
    80004294:	8526                	mv	a0,s1
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	93a080e7          	jalr	-1734(ra) # 80000bd0 <acquire>
    log.committing = 0;
    8000429e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042a2:	8526                	mv	a0,s1
    800042a4:	ffffe097          	auipc	ra,0xffffe
    800042a8:	f42080e7          	jalr	-190(ra) # 800021e6 <wakeup>
    release(&log.lock);
    800042ac:	8526                	mv	a0,s1
    800042ae:	ffffd097          	auipc	ra,0xffffd
    800042b2:	9d6080e7          	jalr	-1578(ra) # 80000c84 <release>
}
    800042b6:	a03d                	j	800042e4 <end_op+0xaa>
    panic("log.committing");
    800042b8:	00004517          	auipc	a0,0x4
    800042bc:	39050513          	addi	a0,a0,912 # 80008648 <syscalls+0x200>
    800042c0:	ffffc097          	auipc	ra,0xffffc
    800042c4:	27a080e7          	jalr	634(ra) # 8000053a <panic>
    wakeup(&log);
    800042c8:	0001d497          	auipc	s1,0x1d
    800042cc:	fa848493          	addi	s1,s1,-88 # 80021270 <log>
    800042d0:	8526                	mv	a0,s1
    800042d2:	ffffe097          	auipc	ra,0xffffe
    800042d6:	f14080e7          	jalr	-236(ra) # 800021e6 <wakeup>
  release(&log.lock);
    800042da:	8526                	mv	a0,s1
    800042dc:	ffffd097          	auipc	ra,0xffffd
    800042e0:	9a8080e7          	jalr	-1624(ra) # 80000c84 <release>
}
    800042e4:	70e2                	ld	ra,56(sp)
    800042e6:	7442                	ld	s0,48(sp)
    800042e8:	74a2                	ld	s1,40(sp)
    800042ea:	7902                	ld	s2,32(sp)
    800042ec:	69e2                	ld	s3,24(sp)
    800042ee:	6a42                	ld	s4,16(sp)
    800042f0:	6aa2                	ld	s5,8(sp)
    800042f2:	6121                	addi	sp,sp,64
    800042f4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042f6:	0001da97          	auipc	s5,0x1d
    800042fa:	faaa8a93          	addi	s5,s5,-86 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042fe:	0001da17          	auipc	s4,0x1d
    80004302:	f72a0a13          	addi	s4,s4,-142 # 80021270 <log>
    80004306:	018a2583          	lw	a1,24(s4)
    8000430a:	012585bb          	addw	a1,a1,s2
    8000430e:	2585                	addiw	a1,a1,1
    80004310:	028a2503          	lw	a0,40(s4)
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	cca080e7          	jalr	-822(ra) # 80002fde <bread>
    8000431c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000431e:	000aa583          	lw	a1,0(s5)
    80004322:	028a2503          	lw	a0,40(s4)
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	cb8080e7          	jalr	-840(ra) # 80002fde <bread>
    8000432e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004330:	40000613          	li	a2,1024
    80004334:	05850593          	addi	a1,a0,88
    80004338:	05848513          	addi	a0,s1,88
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	9ec080e7          	jalr	-1556(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    80004344:	8526                	mv	a0,s1
    80004346:	fffff097          	auipc	ra,0xfffff
    8000434a:	d8a080e7          	jalr	-630(ra) # 800030d0 <bwrite>
    brelse(from);
    8000434e:	854e                	mv	a0,s3
    80004350:	fffff097          	auipc	ra,0xfffff
    80004354:	dbe080e7          	jalr	-578(ra) # 8000310e <brelse>
    brelse(to);
    80004358:	8526                	mv	a0,s1
    8000435a:	fffff097          	auipc	ra,0xfffff
    8000435e:	db4080e7          	jalr	-588(ra) # 8000310e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004362:	2905                	addiw	s2,s2,1
    80004364:	0a91                	addi	s5,s5,4
    80004366:	02ca2783          	lw	a5,44(s4)
    8000436a:	f8f94ee3          	blt	s2,a5,80004306 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000436e:	00000097          	auipc	ra,0x0
    80004372:	c68080e7          	jalr	-920(ra) # 80003fd6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004376:	4501                	li	a0,0
    80004378:	00000097          	auipc	ra,0x0
    8000437c:	cda080e7          	jalr	-806(ra) # 80004052 <install_trans>
    log.lh.n = 0;
    80004380:	0001d797          	auipc	a5,0x1d
    80004384:	f007ae23          	sw	zero,-228(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004388:	00000097          	auipc	ra,0x0
    8000438c:	c4e080e7          	jalr	-946(ra) # 80003fd6 <write_head>
    80004390:	bdf5                	j	8000428c <end_op+0x52>

0000000080004392 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004392:	1101                	addi	sp,sp,-32
    80004394:	ec06                	sd	ra,24(sp)
    80004396:	e822                	sd	s0,16(sp)
    80004398:	e426                	sd	s1,8(sp)
    8000439a:	e04a                	sd	s2,0(sp)
    8000439c:	1000                	addi	s0,sp,32
    8000439e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043a0:	0001d917          	auipc	s2,0x1d
    800043a4:	ed090913          	addi	s2,s2,-304 # 80021270 <log>
    800043a8:	854a                	mv	a0,s2
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	826080e7          	jalr	-2010(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043b2:	02c92603          	lw	a2,44(s2)
    800043b6:	47f5                	li	a5,29
    800043b8:	06c7c563          	blt	a5,a2,80004422 <log_write+0x90>
    800043bc:	0001d797          	auipc	a5,0x1d
    800043c0:	ed07a783          	lw	a5,-304(a5) # 8002128c <log+0x1c>
    800043c4:	37fd                	addiw	a5,a5,-1
    800043c6:	04f65e63          	bge	a2,a5,80004422 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043ca:	0001d797          	auipc	a5,0x1d
    800043ce:	ec67a783          	lw	a5,-314(a5) # 80021290 <log+0x20>
    800043d2:	06f05063          	blez	a5,80004432 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043d6:	4781                	li	a5,0
    800043d8:	06c05563          	blez	a2,80004442 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043dc:	44cc                	lw	a1,12(s1)
    800043de:	0001d717          	auipc	a4,0x1d
    800043e2:	ec270713          	addi	a4,a4,-318 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043e6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043e8:	4314                	lw	a3,0(a4)
    800043ea:	04b68c63          	beq	a3,a1,80004442 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043ee:	2785                	addiw	a5,a5,1
    800043f0:	0711                	addi	a4,a4,4
    800043f2:	fef61be3          	bne	a2,a5,800043e8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043f6:	0621                	addi	a2,a2,8
    800043f8:	060a                	slli	a2,a2,0x2
    800043fa:	0001d797          	auipc	a5,0x1d
    800043fe:	e7678793          	addi	a5,a5,-394 # 80021270 <log>
    80004402:	97b2                	add	a5,a5,a2
    80004404:	44d8                	lw	a4,12(s1)
    80004406:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004408:	8526                	mv	a0,s1
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	da2080e7          	jalr	-606(ra) # 800031ac <bpin>
    log.lh.n++;
    80004412:	0001d717          	auipc	a4,0x1d
    80004416:	e5e70713          	addi	a4,a4,-418 # 80021270 <log>
    8000441a:	575c                	lw	a5,44(a4)
    8000441c:	2785                	addiw	a5,a5,1
    8000441e:	d75c                	sw	a5,44(a4)
    80004420:	a82d                	j	8000445a <log_write+0xc8>
    panic("too big a transaction");
    80004422:	00004517          	auipc	a0,0x4
    80004426:	23650513          	addi	a0,a0,566 # 80008658 <syscalls+0x210>
    8000442a:	ffffc097          	auipc	ra,0xffffc
    8000442e:	110080e7          	jalr	272(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004432:	00004517          	auipc	a0,0x4
    80004436:	23e50513          	addi	a0,a0,574 # 80008670 <syscalls+0x228>
    8000443a:	ffffc097          	auipc	ra,0xffffc
    8000443e:	100080e7          	jalr	256(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004442:	00878693          	addi	a3,a5,8
    80004446:	068a                	slli	a3,a3,0x2
    80004448:	0001d717          	auipc	a4,0x1d
    8000444c:	e2870713          	addi	a4,a4,-472 # 80021270 <log>
    80004450:	9736                	add	a4,a4,a3
    80004452:	44d4                	lw	a3,12(s1)
    80004454:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004456:	faf609e3          	beq	a2,a5,80004408 <log_write+0x76>
  }
  release(&log.lock);
    8000445a:	0001d517          	auipc	a0,0x1d
    8000445e:	e1650513          	addi	a0,a0,-490 # 80021270 <log>
    80004462:	ffffd097          	auipc	ra,0xffffd
    80004466:	822080e7          	jalr	-2014(ra) # 80000c84 <release>
}
    8000446a:	60e2                	ld	ra,24(sp)
    8000446c:	6442                	ld	s0,16(sp)
    8000446e:	64a2                	ld	s1,8(sp)
    80004470:	6902                	ld	s2,0(sp)
    80004472:	6105                	addi	sp,sp,32
    80004474:	8082                	ret

0000000080004476 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004476:	1101                	addi	sp,sp,-32
    80004478:	ec06                	sd	ra,24(sp)
    8000447a:	e822                	sd	s0,16(sp)
    8000447c:	e426                	sd	s1,8(sp)
    8000447e:	e04a                	sd	s2,0(sp)
    80004480:	1000                	addi	s0,sp,32
    80004482:	84aa                	mv	s1,a0
    80004484:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004486:	00004597          	auipc	a1,0x4
    8000448a:	20a58593          	addi	a1,a1,522 # 80008690 <syscalls+0x248>
    8000448e:	0521                	addi	a0,a0,8
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	6b0080e7          	jalr	1712(ra) # 80000b40 <initlock>
  lk->name = name;
    80004498:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000449c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044a0:	0204a423          	sw	zero,40(s1)
}
    800044a4:	60e2                	ld	ra,24(sp)
    800044a6:	6442                	ld	s0,16(sp)
    800044a8:	64a2                	ld	s1,8(sp)
    800044aa:	6902                	ld	s2,0(sp)
    800044ac:	6105                	addi	sp,sp,32
    800044ae:	8082                	ret

00000000800044b0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044b0:	1101                	addi	sp,sp,-32
    800044b2:	ec06                	sd	ra,24(sp)
    800044b4:	e822                	sd	s0,16(sp)
    800044b6:	e426                	sd	s1,8(sp)
    800044b8:	e04a                	sd	s2,0(sp)
    800044ba:	1000                	addi	s0,sp,32
    800044bc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044be:	00850913          	addi	s2,a0,8
    800044c2:	854a                	mv	a0,s2
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	70c080e7          	jalr	1804(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    800044cc:	409c                	lw	a5,0(s1)
    800044ce:	cb89                	beqz	a5,800044e0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044d0:	85ca                	mv	a1,s2
    800044d2:	8526                	mv	a0,s1
    800044d4:	ffffe097          	auipc	ra,0xffffe
    800044d8:	b86080e7          	jalr	-1146(ra) # 8000205a <sleep>
  while (lk->locked) {
    800044dc:	409c                	lw	a5,0(s1)
    800044de:	fbed                	bnez	a5,800044d0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044e0:	4785                	li	a5,1
    800044e2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044e4:	ffffd097          	auipc	ra,0xffffd
    800044e8:	4b2080e7          	jalr	1202(ra) # 80001996 <myproc>
    800044ec:	591c                	lw	a5,48(a0)
    800044ee:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044f0:	854a                	mv	a0,s2
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	792080e7          	jalr	1938(ra) # 80000c84 <release>
}
    800044fa:	60e2                	ld	ra,24(sp)
    800044fc:	6442                	ld	s0,16(sp)
    800044fe:	64a2                	ld	s1,8(sp)
    80004500:	6902                	ld	s2,0(sp)
    80004502:	6105                	addi	sp,sp,32
    80004504:	8082                	ret

0000000080004506 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004506:	1101                	addi	sp,sp,-32
    80004508:	ec06                	sd	ra,24(sp)
    8000450a:	e822                	sd	s0,16(sp)
    8000450c:	e426                	sd	s1,8(sp)
    8000450e:	e04a                	sd	s2,0(sp)
    80004510:	1000                	addi	s0,sp,32
    80004512:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004514:	00850913          	addi	s2,a0,8
    80004518:	854a                	mv	a0,s2
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	6b6080e7          	jalr	1718(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    80004522:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004526:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000452a:	8526                	mv	a0,s1
    8000452c:	ffffe097          	auipc	ra,0xffffe
    80004530:	cba080e7          	jalr	-838(ra) # 800021e6 <wakeup>
  release(&lk->lk);
    80004534:	854a                	mv	a0,s2
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	74e080e7          	jalr	1870(ra) # 80000c84 <release>
}
    8000453e:	60e2                	ld	ra,24(sp)
    80004540:	6442                	ld	s0,16(sp)
    80004542:	64a2                	ld	s1,8(sp)
    80004544:	6902                	ld	s2,0(sp)
    80004546:	6105                	addi	sp,sp,32
    80004548:	8082                	ret

000000008000454a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000454a:	7179                	addi	sp,sp,-48
    8000454c:	f406                	sd	ra,40(sp)
    8000454e:	f022                	sd	s0,32(sp)
    80004550:	ec26                	sd	s1,24(sp)
    80004552:	e84a                	sd	s2,16(sp)
    80004554:	e44e                	sd	s3,8(sp)
    80004556:	1800                	addi	s0,sp,48
    80004558:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000455a:	00850913          	addi	s2,a0,8
    8000455e:	854a                	mv	a0,s2
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	670080e7          	jalr	1648(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004568:	409c                	lw	a5,0(s1)
    8000456a:	ef99                	bnez	a5,80004588 <holdingsleep+0x3e>
    8000456c:	4481                	li	s1,0
  release(&lk->lk);
    8000456e:	854a                	mv	a0,s2
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	714080e7          	jalr	1812(ra) # 80000c84 <release>
  return r;
}
    80004578:	8526                	mv	a0,s1
    8000457a:	70a2                	ld	ra,40(sp)
    8000457c:	7402                	ld	s0,32(sp)
    8000457e:	64e2                	ld	s1,24(sp)
    80004580:	6942                	ld	s2,16(sp)
    80004582:	69a2                	ld	s3,8(sp)
    80004584:	6145                	addi	sp,sp,48
    80004586:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004588:	0284a983          	lw	s3,40(s1)
    8000458c:	ffffd097          	auipc	ra,0xffffd
    80004590:	40a080e7          	jalr	1034(ra) # 80001996 <myproc>
    80004594:	5904                	lw	s1,48(a0)
    80004596:	413484b3          	sub	s1,s1,s3
    8000459a:	0014b493          	seqz	s1,s1
    8000459e:	bfc1                	j	8000456e <holdingsleep+0x24>

00000000800045a0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045a0:	1141                	addi	sp,sp,-16
    800045a2:	e406                	sd	ra,8(sp)
    800045a4:	e022                	sd	s0,0(sp)
    800045a6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045a8:	00004597          	auipc	a1,0x4
    800045ac:	0f858593          	addi	a1,a1,248 # 800086a0 <syscalls+0x258>
    800045b0:	0001d517          	auipc	a0,0x1d
    800045b4:	e0850513          	addi	a0,a0,-504 # 800213b8 <ftable>
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	588080e7          	jalr	1416(ra) # 80000b40 <initlock>
}
    800045c0:	60a2                	ld	ra,8(sp)
    800045c2:	6402                	ld	s0,0(sp)
    800045c4:	0141                	addi	sp,sp,16
    800045c6:	8082                	ret

00000000800045c8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045c8:	1101                	addi	sp,sp,-32
    800045ca:	ec06                	sd	ra,24(sp)
    800045cc:	e822                	sd	s0,16(sp)
    800045ce:	e426                	sd	s1,8(sp)
    800045d0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045d2:	0001d517          	auipc	a0,0x1d
    800045d6:	de650513          	addi	a0,a0,-538 # 800213b8 <ftable>
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	5f6080e7          	jalr	1526(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045e2:	0001d497          	auipc	s1,0x1d
    800045e6:	dee48493          	addi	s1,s1,-530 # 800213d0 <ftable+0x18>
    800045ea:	0001e717          	auipc	a4,0x1e
    800045ee:	d8670713          	addi	a4,a4,-634 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800045f2:	40dc                	lw	a5,4(s1)
    800045f4:	cf99                	beqz	a5,80004612 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045f6:	02848493          	addi	s1,s1,40
    800045fa:	fee49ce3          	bne	s1,a4,800045f2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045fe:	0001d517          	auipc	a0,0x1d
    80004602:	dba50513          	addi	a0,a0,-582 # 800213b8 <ftable>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	67e080e7          	jalr	1662(ra) # 80000c84 <release>
  return 0;
    8000460e:	4481                	li	s1,0
    80004610:	a819                	j	80004626 <filealloc+0x5e>
      f->ref = 1;
    80004612:	4785                	li	a5,1
    80004614:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004616:	0001d517          	auipc	a0,0x1d
    8000461a:	da250513          	addi	a0,a0,-606 # 800213b8 <ftable>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	666080e7          	jalr	1638(ra) # 80000c84 <release>
}
    80004626:	8526                	mv	a0,s1
    80004628:	60e2                	ld	ra,24(sp)
    8000462a:	6442                	ld	s0,16(sp)
    8000462c:	64a2                	ld	s1,8(sp)
    8000462e:	6105                	addi	sp,sp,32
    80004630:	8082                	ret

0000000080004632 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004632:	1101                	addi	sp,sp,-32
    80004634:	ec06                	sd	ra,24(sp)
    80004636:	e822                	sd	s0,16(sp)
    80004638:	e426                	sd	s1,8(sp)
    8000463a:	1000                	addi	s0,sp,32
    8000463c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000463e:	0001d517          	auipc	a0,0x1d
    80004642:	d7a50513          	addi	a0,a0,-646 # 800213b8 <ftable>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	58a080e7          	jalr	1418(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    8000464e:	40dc                	lw	a5,4(s1)
    80004650:	02f05263          	blez	a5,80004674 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004654:	2785                	addiw	a5,a5,1
    80004656:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004658:	0001d517          	auipc	a0,0x1d
    8000465c:	d6050513          	addi	a0,a0,-672 # 800213b8 <ftable>
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	624080e7          	jalr	1572(ra) # 80000c84 <release>
  return f;
}
    80004668:	8526                	mv	a0,s1
    8000466a:	60e2                	ld	ra,24(sp)
    8000466c:	6442                	ld	s0,16(sp)
    8000466e:	64a2                	ld	s1,8(sp)
    80004670:	6105                	addi	sp,sp,32
    80004672:	8082                	ret
    panic("filedup");
    80004674:	00004517          	auipc	a0,0x4
    80004678:	03450513          	addi	a0,a0,52 # 800086a8 <syscalls+0x260>
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	ebe080e7          	jalr	-322(ra) # 8000053a <panic>

0000000080004684 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004684:	7139                	addi	sp,sp,-64
    80004686:	fc06                	sd	ra,56(sp)
    80004688:	f822                	sd	s0,48(sp)
    8000468a:	f426                	sd	s1,40(sp)
    8000468c:	f04a                	sd	s2,32(sp)
    8000468e:	ec4e                	sd	s3,24(sp)
    80004690:	e852                	sd	s4,16(sp)
    80004692:	e456                	sd	s5,8(sp)
    80004694:	0080                	addi	s0,sp,64
    80004696:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004698:	0001d517          	auipc	a0,0x1d
    8000469c:	d2050513          	addi	a0,a0,-736 # 800213b8 <ftable>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	530080e7          	jalr	1328(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800046a8:	40dc                	lw	a5,4(s1)
    800046aa:	06f05163          	blez	a5,8000470c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046ae:	37fd                	addiw	a5,a5,-1
    800046b0:	0007871b          	sext.w	a4,a5
    800046b4:	c0dc                	sw	a5,4(s1)
    800046b6:	06e04363          	bgtz	a4,8000471c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046ba:	0004a903          	lw	s2,0(s1)
    800046be:	0094ca83          	lbu	s5,9(s1)
    800046c2:	0104ba03          	ld	s4,16(s1)
    800046c6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046ca:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046ce:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046d2:	0001d517          	auipc	a0,0x1d
    800046d6:	ce650513          	addi	a0,a0,-794 # 800213b8 <ftable>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	5aa080e7          	jalr	1450(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    800046e2:	4785                	li	a5,1
    800046e4:	04f90d63          	beq	s2,a5,8000473e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046e8:	3979                	addiw	s2,s2,-2
    800046ea:	4785                	li	a5,1
    800046ec:	0527e063          	bltu	a5,s2,8000472c <fileclose+0xa8>
    begin_op();
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	acc080e7          	jalr	-1332(ra) # 800041bc <begin_op>
    iput(ff.ip);
    800046f8:	854e                	mv	a0,s3
    800046fa:	fffff097          	auipc	ra,0xfffff
    800046fe:	2a0080e7          	jalr	672(ra) # 8000399a <iput>
    end_op();
    80004702:	00000097          	auipc	ra,0x0
    80004706:	b38080e7          	jalr	-1224(ra) # 8000423a <end_op>
    8000470a:	a00d                	j	8000472c <fileclose+0xa8>
    panic("fileclose");
    8000470c:	00004517          	auipc	a0,0x4
    80004710:	fa450513          	addi	a0,a0,-92 # 800086b0 <syscalls+0x268>
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	e26080e7          	jalr	-474(ra) # 8000053a <panic>
    release(&ftable.lock);
    8000471c:	0001d517          	auipc	a0,0x1d
    80004720:	c9c50513          	addi	a0,a0,-868 # 800213b8 <ftable>
    80004724:	ffffc097          	auipc	ra,0xffffc
    80004728:	560080e7          	jalr	1376(ra) # 80000c84 <release>
  }
}
    8000472c:	70e2                	ld	ra,56(sp)
    8000472e:	7442                	ld	s0,48(sp)
    80004730:	74a2                	ld	s1,40(sp)
    80004732:	7902                	ld	s2,32(sp)
    80004734:	69e2                	ld	s3,24(sp)
    80004736:	6a42                	ld	s4,16(sp)
    80004738:	6aa2                	ld	s5,8(sp)
    8000473a:	6121                	addi	sp,sp,64
    8000473c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000473e:	85d6                	mv	a1,s5
    80004740:	8552                	mv	a0,s4
    80004742:	00000097          	auipc	ra,0x0
    80004746:	34c080e7          	jalr	844(ra) # 80004a8e <pipeclose>
    8000474a:	b7cd                	j	8000472c <fileclose+0xa8>

000000008000474c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000474c:	715d                	addi	sp,sp,-80
    8000474e:	e486                	sd	ra,72(sp)
    80004750:	e0a2                	sd	s0,64(sp)
    80004752:	fc26                	sd	s1,56(sp)
    80004754:	f84a                	sd	s2,48(sp)
    80004756:	f44e                	sd	s3,40(sp)
    80004758:	0880                	addi	s0,sp,80
    8000475a:	84aa                	mv	s1,a0
    8000475c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000475e:	ffffd097          	auipc	ra,0xffffd
    80004762:	238080e7          	jalr	568(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004766:	409c                	lw	a5,0(s1)
    80004768:	37f9                	addiw	a5,a5,-2
    8000476a:	4705                	li	a4,1
    8000476c:	04f76763          	bltu	a4,a5,800047ba <filestat+0x6e>
    80004770:	892a                	mv	s2,a0
    ilock(f->ip);
    80004772:	6c88                	ld	a0,24(s1)
    80004774:	fffff097          	auipc	ra,0xfffff
    80004778:	06c080e7          	jalr	108(ra) # 800037e0 <ilock>
    stati(f->ip, &st);
    8000477c:	fb840593          	addi	a1,s0,-72
    80004780:	6c88                	ld	a0,24(s1)
    80004782:	fffff097          	auipc	ra,0xfffff
    80004786:	2e8080e7          	jalr	744(ra) # 80003a6a <stati>
    iunlock(f->ip);
    8000478a:	6c88                	ld	a0,24(s1)
    8000478c:	fffff097          	auipc	ra,0xfffff
    80004790:	116080e7          	jalr	278(ra) # 800038a2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004794:	46e1                	li	a3,24
    80004796:	fb840613          	addi	a2,s0,-72
    8000479a:	85ce                	mv	a1,s3
    8000479c:	05093503          	ld	a0,80(s2)
    800047a0:	ffffd097          	auipc	ra,0xffffd
    800047a4:	eba080e7          	jalr	-326(ra) # 8000165a <copyout>
    800047a8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047ac:	60a6                	ld	ra,72(sp)
    800047ae:	6406                	ld	s0,64(sp)
    800047b0:	74e2                	ld	s1,56(sp)
    800047b2:	7942                	ld	s2,48(sp)
    800047b4:	79a2                	ld	s3,40(sp)
    800047b6:	6161                	addi	sp,sp,80
    800047b8:	8082                	ret
  return -1;
    800047ba:	557d                	li	a0,-1
    800047bc:	bfc5                	j	800047ac <filestat+0x60>

00000000800047be <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047be:	7179                	addi	sp,sp,-48
    800047c0:	f406                	sd	ra,40(sp)
    800047c2:	f022                	sd	s0,32(sp)
    800047c4:	ec26                	sd	s1,24(sp)
    800047c6:	e84a                	sd	s2,16(sp)
    800047c8:	e44e                	sd	s3,8(sp)
    800047ca:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047cc:	00854783          	lbu	a5,8(a0)
    800047d0:	c3d5                	beqz	a5,80004874 <fileread+0xb6>
    800047d2:	84aa                	mv	s1,a0
    800047d4:	89ae                	mv	s3,a1
    800047d6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047d8:	411c                	lw	a5,0(a0)
    800047da:	4705                	li	a4,1
    800047dc:	04e78963          	beq	a5,a4,8000482e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047e0:	470d                	li	a4,3
    800047e2:	04e78d63          	beq	a5,a4,8000483c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047e6:	4709                	li	a4,2
    800047e8:	06e79e63          	bne	a5,a4,80004864 <fileread+0xa6>
    ilock(f->ip);
    800047ec:	6d08                	ld	a0,24(a0)
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	ff2080e7          	jalr	-14(ra) # 800037e0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047f6:	874a                	mv	a4,s2
    800047f8:	5094                	lw	a3,32(s1)
    800047fa:	864e                	mv	a2,s3
    800047fc:	4585                	li	a1,1
    800047fe:	6c88                	ld	a0,24(s1)
    80004800:	fffff097          	auipc	ra,0xfffff
    80004804:	294080e7          	jalr	660(ra) # 80003a94 <readi>
    80004808:	892a                	mv	s2,a0
    8000480a:	00a05563          	blez	a0,80004814 <fileread+0x56>
      f->off += r;
    8000480e:	509c                	lw	a5,32(s1)
    80004810:	9fa9                	addw	a5,a5,a0
    80004812:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004814:	6c88                	ld	a0,24(s1)
    80004816:	fffff097          	auipc	ra,0xfffff
    8000481a:	08c080e7          	jalr	140(ra) # 800038a2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000481e:	854a                	mv	a0,s2
    80004820:	70a2                	ld	ra,40(sp)
    80004822:	7402                	ld	s0,32(sp)
    80004824:	64e2                	ld	s1,24(sp)
    80004826:	6942                	ld	s2,16(sp)
    80004828:	69a2                	ld	s3,8(sp)
    8000482a:	6145                	addi	sp,sp,48
    8000482c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000482e:	6908                	ld	a0,16(a0)
    80004830:	00000097          	auipc	ra,0x0
    80004834:	3c0080e7          	jalr	960(ra) # 80004bf0 <piperead>
    80004838:	892a                	mv	s2,a0
    8000483a:	b7d5                	j	8000481e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000483c:	02451783          	lh	a5,36(a0)
    80004840:	03079693          	slli	a3,a5,0x30
    80004844:	92c1                	srli	a3,a3,0x30
    80004846:	4725                	li	a4,9
    80004848:	02d76863          	bltu	a4,a3,80004878 <fileread+0xba>
    8000484c:	0792                	slli	a5,a5,0x4
    8000484e:	0001d717          	auipc	a4,0x1d
    80004852:	aca70713          	addi	a4,a4,-1334 # 80021318 <devsw>
    80004856:	97ba                	add	a5,a5,a4
    80004858:	639c                	ld	a5,0(a5)
    8000485a:	c38d                	beqz	a5,8000487c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000485c:	4505                	li	a0,1
    8000485e:	9782                	jalr	a5
    80004860:	892a                	mv	s2,a0
    80004862:	bf75                	j	8000481e <fileread+0x60>
    panic("fileread");
    80004864:	00004517          	auipc	a0,0x4
    80004868:	e5c50513          	addi	a0,a0,-420 # 800086c0 <syscalls+0x278>
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	cce080e7          	jalr	-818(ra) # 8000053a <panic>
    return -1;
    80004874:	597d                	li	s2,-1
    80004876:	b765                	j	8000481e <fileread+0x60>
      return -1;
    80004878:	597d                	li	s2,-1
    8000487a:	b755                	j	8000481e <fileread+0x60>
    8000487c:	597d                	li	s2,-1
    8000487e:	b745                	j	8000481e <fileread+0x60>

0000000080004880 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004880:	715d                	addi	sp,sp,-80
    80004882:	e486                	sd	ra,72(sp)
    80004884:	e0a2                	sd	s0,64(sp)
    80004886:	fc26                	sd	s1,56(sp)
    80004888:	f84a                	sd	s2,48(sp)
    8000488a:	f44e                	sd	s3,40(sp)
    8000488c:	f052                	sd	s4,32(sp)
    8000488e:	ec56                	sd	s5,24(sp)
    80004890:	e85a                	sd	s6,16(sp)
    80004892:	e45e                	sd	s7,8(sp)
    80004894:	e062                	sd	s8,0(sp)
    80004896:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004898:	00954783          	lbu	a5,9(a0)
    8000489c:	10078663          	beqz	a5,800049a8 <filewrite+0x128>
    800048a0:	892a                	mv	s2,a0
    800048a2:	8b2e                	mv	s6,a1
    800048a4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048a6:	411c                	lw	a5,0(a0)
    800048a8:	4705                	li	a4,1
    800048aa:	02e78263          	beq	a5,a4,800048ce <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ae:	470d                	li	a4,3
    800048b0:	02e78663          	beq	a5,a4,800048dc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048b4:	4709                	li	a4,2
    800048b6:	0ee79163          	bne	a5,a4,80004998 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048ba:	0ac05d63          	blez	a2,80004974 <filewrite+0xf4>
    int i = 0;
    800048be:	4981                	li	s3,0
    800048c0:	6b85                	lui	s7,0x1
    800048c2:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800048c6:	6c05                	lui	s8,0x1
    800048c8:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800048cc:	a861                	j	80004964 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048ce:	6908                	ld	a0,16(a0)
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	22e080e7          	jalr	558(ra) # 80004afe <pipewrite>
    800048d8:	8a2a                	mv	s4,a0
    800048da:	a045                	j	8000497a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048dc:	02451783          	lh	a5,36(a0)
    800048e0:	03079693          	slli	a3,a5,0x30
    800048e4:	92c1                	srli	a3,a3,0x30
    800048e6:	4725                	li	a4,9
    800048e8:	0cd76263          	bltu	a4,a3,800049ac <filewrite+0x12c>
    800048ec:	0792                	slli	a5,a5,0x4
    800048ee:	0001d717          	auipc	a4,0x1d
    800048f2:	a2a70713          	addi	a4,a4,-1494 # 80021318 <devsw>
    800048f6:	97ba                	add	a5,a5,a4
    800048f8:	679c                	ld	a5,8(a5)
    800048fa:	cbdd                	beqz	a5,800049b0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048fc:	4505                	li	a0,1
    800048fe:	9782                	jalr	a5
    80004900:	8a2a                	mv	s4,a0
    80004902:	a8a5                	j	8000497a <filewrite+0xfa>
    80004904:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004908:	00000097          	auipc	ra,0x0
    8000490c:	8b4080e7          	jalr	-1868(ra) # 800041bc <begin_op>
      ilock(f->ip);
    80004910:	01893503          	ld	a0,24(s2)
    80004914:	fffff097          	auipc	ra,0xfffff
    80004918:	ecc080e7          	jalr	-308(ra) # 800037e0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000491c:	8756                	mv	a4,s5
    8000491e:	02092683          	lw	a3,32(s2)
    80004922:	01698633          	add	a2,s3,s6
    80004926:	4585                	li	a1,1
    80004928:	01893503          	ld	a0,24(s2)
    8000492c:	fffff097          	auipc	ra,0xfffff
    80004930:	260080e7          	jalr	608(ra) # 80003b8c <writei>
    80004934:	84aa                	mv	s1,a0
    80004936:	00a05763          	blez	a0,80004944 <filewrite+0xc4>
        f->off += r;
    8000493a:	02092783          	lw	a5,32(s2)
    8000493e:	9fa9                	addw	a5,a5,a0
    80004940:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004944:	01893503          	ld	a0,24(s2)
    80004948:	fffff097          	auipc	ra,0xfffff
    8000494c:	f5a080e7          	jalr	-166(ra) # 800038a2 <iunlock>
      end_op();
    80004950:	00000097          	auipc	ra,0x0
    80004954:	8ea080e7          	jalr	-1814(ra) # 8000423a <end_op>

      if(r != n1){
    80004958:	009a9f63          	bne	s5,s1,80004976 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000495c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004960:	0149db63          	bge	s3,s4,80004976 <filewrite+0xf6>
      int n1 = n - i;
    80004964:	413a04bb          	subw	s1,s4,s3
    80004968:	0004879b          	sext.w	a5,s1
    8000496c:	f8fbdce3          	bge	s7,a5,80004904 <filewrite+0x84>
    80004970:	84e2                	mv	s1,s8
    80004972:	bf49                	j	80004904 <filewrite+0x84>
    int i = 0;
    80004974:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004976:	013a1f63          	bne	s4,s3,80004994 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000497a:	8552                	mv	a0,s4
    8000497c:	60a6                	ld	ra,72(sp)
    8000497e:	6406                	ld	s0,64(sp)
    80004980:	74e2                	ld	s1,56(sp)
    80004982:	7942                	ld	s2,48(sp)
    80004984:	79a2                	ld	s3,40(sp)
    80004986:	7a02                	ld	s4,32(sp)
    80004988:	6ae2                	ld	s5,24(sp)
    8000498a:	6b42                	ld	s6,16(sp)
    8000498c:	6ba2                	ld	s7,8(sp)
    8000498e:	6c02                	ld	s8,0(sp)
    80004990:	6161                	addi	sp,sp,80
    80004992:	8082                	ret
    ret = (i == n ? n : -1);
    80004994:	5a7d                	li	s4,-1
    80004996:	b7d5                	j	8000497a <filewrite+0xfa>
    panic("filewrite");
    80004998:	00004517          	auipc	a0,0x4
    8000499c:	d3850513          	addi	a0,a0,-712 # 800086d0 <syscalls+0x288>
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	b9a080e7          	jalr	-1126(ra) # 8000053a <panic>
    return -1;
    800049a8:	5a7d                	li	s4,-1
    800049aa:	bfc1                	j	8000497a <filewrite+0xfa>
      return -1;
    800049ac:	5a7d                	li	s4,-1
    800049ae:	b7f1                	j	8000497a <filewrite+0xfa>
    800049b0:	5a7d                	li	s4,-1
    800049b2:	b7e1                	j	8000497a <filewrite+0xfa>

00000000800049b4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049b4:	7179                	addi	sp,sp,-48
    800049b6:	f406                	sd	ra,40(sp)
    800049b8:	f022                	sd	s0,32(sp)
    800049ba:	ec26                	sd	s1,24(sp)
    800049bc:	e84a                	sd	s2,16(sp)
    800049be:	e44e                	sd	s3,8(sp)
    800049c0:	e052                	sd	s4,0(sp)
    800049c2:	1800                	addi	s0,sp,48
    800049c4:	84aa                	mv	s1,a0
    800049c6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049c8:	0005b023          	sd	zero,0(a1)
    800049cc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049d0:	00000097          	auipc	ra,0x0
    800049d4:	bf8080e7          	jalr	-1032(ra) # 800045c8 <filealloc>
    800049d8:	e088                	sd	a0,0(s1)
    800049da:	c551                	beqz	a0,80004a66 <pipealloc+0xb2>
    800049dc:	00000097          	auipc	ra,0x0
    800049e0:	bec080e7          	jalr	-1044(ra) # 800045c8 <filealloc>
    800049e4:	00aa3023          	sd	a0,0(s4)
    800049e8:	c92d                	beqz	a0,80004a5a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	0f6080e7          	jalr	246(ra) # 80000ae0 <kalloc>
    800049f2:	892a                	mv	s2,a0
    800049f4:	c125                	beqz	a0,80004a54 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049f6:	4985                	li	s3,1
    800049f8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049fc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a00:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a04:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a08:	00004597          	auipc	a1,0x4
    80004a0c:	cd858593          	addi	a1,a1,-808 # 800086e0 <syscalls+0x298>
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	130080e7          	jalr	304(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004a18:	609c                	ld	a5,0(s1)
    80004a1a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a1e:	609c                	ld	a5,0(s1)
    80004a20:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a24:	609c                	ld	a5,0(s1)
    80004a26:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a2a:	609c                	ld	a5,0(s1)
    80004a2c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a30:	000a3783          	ld	a5,0(s4)
    80004a34:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a38:	000a3783          	ld	a5,0(s4)
    80004a3c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a40:	000a3783          	ld	a5,0(s4)
    80004a44:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a48:	000a3783          	ld	a5,0(s4)
    80004a4c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a50:	4501                	li	a0,0
    80004a52:	a025                	j	80004a7a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a54:	6088                	ld	a0,0(s1)
    80004a56:	e501                	bnez	a0,80004a5e <pipealloc+0xaa>
    80004a58:	a039                	j	80004a66 <pipealloc+0xb2>
    80004a5a:	6088                	ld	a0,0(s1)
    80004a5c:	c51d                	beqz	a0,80004a8a <pipealloc+0xd6>
    fileclose(*f0);
    80004a5e:	00000097          	auipc	ra,0x0
    80004a62:	c26080e7          	jalr	-986(ra) # 80004684 <fileclose>
  if(*f1)
    80004a66:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a6a:	557d                	li	a0,-1
  if(*f1)
    80004a6c:	c799                	beqz	a5,80004a7a <pipealloc+0xc6>
    fileclose(*f1);
    80004a6e:	853e                	mv	a0,a5
    80004a70:	00000097          	auipc	ra,0x0
    80004a74:	c14080e7          	jalr	-1004(ra) # 80004684 <fileclose>
  return -1;
    80004a78:	557d                	li	a0,-1
}
    80004a7a:	70a2                	ld	ra,40(sp)
    80004a7c:	7402                	ld	s0,32(sp)
    80004a7e:	64e2                	ld	s1,24(sp)
    80004a80:	6942                	ld	s2,16(sp)
    80004a82:	69a2                	ld	s3,8(sp)
    80004a84:	6a02                	ld	s4,0(sp)
    80004a86:	6145                	addi	sp,sp,48
    80004a88:	8082                	ret
  return -1;
    80004a8a:	557d                	li	a0,-1
    80004a8c:	b7fd                	j	80004a7a <pipealloc+0xc6>

0000000080004a8e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a8e:	1101                	addi	sp,sp,-32
    80004a90:	ec06                	sd	ra,24(sp)
    80004a92:	e822                	sd	s0,16(sp)
    80004a94:	e426                	sd	s1,8(sp)
    80004a96:	e04a                	sd	s2,0(sp)
    80004a98:	1000                	addi	s0,sp,32
    80004a9a:	84aa                	mv	s1,a0
    80004a9c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	132080e7          	jalr	306(ra) # 80000bd0 <acquire>
  if(writable){
    80004aa6:	02090d63          	beqz	s2,80004ae0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004aaa:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004aae:	21848513          	addi	a0,s1,536
    80004ab2:	ffffd097          	auipc	ra,0xffffd
    80004ab6:	734080e7          	jalr	1844(ra) # 800021e6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004aba:	2204b783          	ld	a5,544(s1)
    80004abe:	eb95                	bnez	a5,80004af2 <pipeclose+0x64>
    release(&pi->lock);
    80004ac0:	8526                	mv	a0,s1
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	1c2080e7          	jalr	450(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004aca:	8526                	mv	a0,s1
    80004acc:	ffffc097          	auipc	ra,0xffffc
    80004ad0:	f16080e7          	jalr	-234(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004ad4:	60e2                	ld	ra,24(sp)
    80004ad6:	6442                	ld	s0,16(sp)
    80004ad8:	64a2                	ld	s1,8(sp)
    80004ada:	6902                	ld	s2,0(sp)
    80004adc:	6105                	addi	sp,sp,32
    80004ade:	8082                	ret
    pi->readopen = 0;
    80004ae0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ae4:	21c48513          	addi	a0,s1,540
    80004ae8:	ffffd097          	auipc	ra,0xffffd
    80004aec:	6fe080e7          	jalr	1790(ra) # 800021e6 <wakeup>
    80004af0:	b7e9                	j	80004aba <pipeclose+0x2c>
    release(&pi->lock);
    80004af2:	8526                	mv	a0,s1
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	190080e7          	jalr	400(ra) # 80000c84 <release>
}
    80004afc:	bfe1                	j	80004ad4 <pipeclose+0x46>

0000000080004afe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004afe:	711d                	addi	sp,sp,-96
    80004b00:	ec86                	sd	ra,88(sp)
    80004b02:	e8a2                	sd	s0,80(sp)
    80004b04:	e4a6                	sd	s1,72(sp)
    80004b06:	e0ca                	sd	s2,64(sp)
    80004b08:	fc4e                	sd	s3,56(sp)
    80004b0a:	f852                	sd	s4,48(sp)
    80004b0c:	f456                	sd	s5,40(sp)
    80004b0e:	f05a                	sd	s6,32(sp)
    80004b10:	ec5e                	sd	s7,24(sp)
    80004b12:	e862                	sd	s8,16(sp)
    80004b14:	1080                	addi	s0,sp,96
    80004b16:	84aa                	mv	s1,a0
    80004b18:	8aae                	mv	s5,a1
    80004b1a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b1c:	ffffd097          	auipc	ra,0xffffd
    80004b20:	e7a080e7          	jalr	-390(ra) # 80001996 <myproc>
    80004b24:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b26:	8526                	mv	a0,s1
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	0a8080e7          	jalr	168(ra) # 80000bd0 <acquire>
  while(i < n){
    80004b30:	0b405363          	blez	s4,80004bd6 <pipewrite+0xd8>
  int i = 0;
    80004b34:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b36:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b38:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b3c:	21c48b93          	addi	s7,s1,540
    80004b40:	a089                	j	80004b82 <pipewrite+0x84>
      release(&pi->lock);
    80004b42:	8526                	mv	a0,s1
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	140080e7          	jalr	320(ra) # 80000c84 <release>
      return -1;
    80004b4c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b4e:	854a                	mv	a0,s2
    80004b50:	60e6                	ld	ra,88(sp)
    80004b52:	6446                	ld	s0,80(sp)
    80004b54:	64a6                	ld	s1,72(sp)
    80004b56:	6906                	ld	s2,64(sp)
    80004b58:	79e2                	ld	s3,56(sp)
    80004b5a:	7a42                	ld	s4,48(sp)
    80004b5c:	7aa2                	ld	s5,40(sp)
    80004b5e:	7b02                	ld	s6,32(sp)
    80004b60:	6be2                	ld	s7,24(sp)
    80004b62:	6c42                	ld	s8,16(sp)
    80004b64:	6125                	addi	sp,sp,96
    80004b66:	8082                	ret
      wakeup(&pi->nread);
    80004b68:	8562                	mv	a0,s8
    80004b6a:	ffffd097          	auipc	ra,0xffffd
    80004b6e:	67c080e7          	jalr	1660(ra) # 800021e6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b72:	85a6                	mv	a1,s1
    80004b74:	855e                	mv	a0,s7
    80004b76:	ffffd097          	auipc	ra,0xffffd
    80004b7a:	4e4080e7          	jalr	1252(ra) # 8000205a <sleep>
  while(i < n){
    80004b7e:	05495d63          	bge	s2,s4,80004bd8 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004b82:	2204a783          	lw	a5,544(s1)
    80004b86:	dfd5                	beqz	a5,80004b42 <pipewrite+0x44>
    80004b88:	0289a783          	lw	a5,40(s3)
    80004b8c:	fbdd                	bnez	a5,80004b42 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b8e:	2184a783          	lw	a5,536(s1)
    80004b92:	21c4a703          	lw	a4,540(s1)
    80004b96:	2007879b          	addiw	a5,a5,512
    80004b9a:	fcf707e3          	beq	a4,a5,80004b68 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b9e:	4685                	li	a3,1
    80004ba0:	01590633          	add	a2,s2,s5
    80004ba4:	faf40593          	addi	a1,s0,-81
    80004ba8:	0509b503          	ld	a0,80(s3)
    80004bac:	ffffd097          	auipc	ra,0xffffd
    80004bb0:	b3a080e7          	jalr	-1222(ra) # 800016e6 <copyin>
    80004bb4:	03650263          	beq	a0,s6,80004bd8 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bb8:	21c4a783          	lw	a5,540(s1)
    80004bbc:	0017871b          	addiw	a4,a5,1
    80004bc0:	20e4ae23          	sw	a4,540(s1)
    80004bc4:	1ff7f793          	andi	a5,a5,511
    80004bc8:	97a6                	add	a5,a5,s1
    80004bca:	faf44703          	lbu	a4,-81(s0)
    80004bce:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bd2:	2905                	addiw	s2,s2,1
    80004bd4:	b76d                	j	80004b7e <pipewrite+0x80>
  int i = 0;
    80004bd6:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004bd8:	21848513          	addi	a0,s1,536
    80004bdc:	ffffd097          	auipc	ra,0xffffd
    80004be0:	60a080e7          	jalr	1546(ra) # 800021e6 <wakeup>
  release(&pi->lock);
    80004be4:	8526                	mv	a0,s1
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	09e080e7          	jalr	158(ra) # 80000c84 <release>
  return i;
    80004bee:	b785                	j	80004b4e <pipewrite+0x50>

0000000080004bf0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bf0:	715d                	addi	sp,sp,-80
    80004bf2:	e486                	sd	ra,72(sp)
    80004bf4:	e0a2                	sd	s0,64(sp)
    80004bf6:	fc26                	sd	s1,56(sp)
    80004bf8:	f84a                	sd	s2,48(sp)
    80004bfa:	f44e                	sd	s3,40(sp)
    80004bfc:	f052                	sd	s4,32(sp)
    80004bfe:	ec56                	sd	s5,24(sp)
    80004c00:	e85a                	sd	s6,16(sp)
    80004c02:	0880                	addi	s0,sp,80
    80004c04:	84aa                	mv	s1,a0
    80004c06:	892e                	mv	s2,a1
    80004c08:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c0a:	ffffd097          	auipc	ra,0xffffd
    80004c0e:	d8c080e7          	jalr	-628(ra) # 80001996 <myproc>
    80004c12:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c14:	8526                	mv	a0,s1
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	fba080e7          	jalr	-70(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c1e:	2184a703          	lw	a4,536(s1)
    80004c22:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c26:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c2a:	02f71463          	bne	a4,a5,80004c52 <piperead+0x62>
    80004c2e:	2244a783          	lw	a5,548(s1)
    80004c32:	c385                	beqz	a5,80004c52 <piperead+0x62>
    if(pr->killed){
    80004c34:	028a2783          	lw	a5,40(s4)
    80004c38:	ebc9                	bnez	a5,80004cca <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c3a:	85a6                	mv	a1,s1
    80004c3c:	854e                	mv	a0,s3
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	41c080e7          	jalr	1052(ra) # 8000205a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c46:	2184a703          	lw	a4,536(s1)
    80004c4a:	21c4a783          	lw	a5,540(s1)
    80004c4e:	fef700e3          	beq	a4,a5,80004c2e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c52:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c54:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c56:	05505463          	blez	s5,80004c9e <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004c5a:	2184a783          	lw	a5,536(s1)
    80004c5e:	21c4a703          	lw	a4,540(s1)
    80004c62:	02f70e63          	beq	a4,a5,80004c9e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c66:	0017871b          	addiw	a4,a5,1
    80004c6a:	20e4ac23          	sw	a4,536(s1)
    80004c6e:	1ff7f793          	andi	a5,a5,511
    80004c72:	97a6                	add	a5,a5,s1
    80004c74:	0187c783          	lbu	a5,24(a5)
    80004c78:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c7c:	4685                	li	a3,1
    80004c7e:	fbf40613          	addi	a2,s0,-65
    80004c82:	85ca                	mv	a1,s2
    80004c84:	050a3503          	ld	a0,80(s4)
    80004c88:	ffffd097          	auipc	ra,0xffffd
    80004c8c:	9d2080e7          	jalr	-1582(ra) # 8000165a <copyout>
    80004c90:	01650763          	beq	a0,s6,80004c9e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c94:	2985                	addiw	s3,s3,1
    80004c96:	0905                	addi	s2,s2,1
    80004c98:	fd3a91e3          	bne	s5,s3,80004c5a <piperead+0x6a>
    80004c9c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c9e:	21c48513          	addi	a0,s1,540
    80004ca2:	ffffd097          	auipc	ra,0xffffd
    80004ca6:	544080e7          	jalr	1348(ra) # 800021e6 <wakeup>
  release(&pi->lock);
    80004caa:	8526                	mv	a0,s1
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	fd8080e7          	jalr	-40(ra) # 80000c84 <release>
  return i;
}
    80004cb4:	854e                	mv	a0,s3
    80004cb6:	60a6                	ld	ra,72(sp)
    80004cb8:	6406                	ld	s0,64(sp)
    80004cba:	74e2                	ld	s1,56(sp)
    80004cbc:	7942                	ld	s2,48(sp)
    80004cbe:	79a2                	ld	s3,40(sp)
    80004cc0:	7a02                	ld	s4,32(sp)
    80004cc2:	6ae2                	ld	s5,24(sp)
    80004cc4:	6b42                	ld	s6,16(sp)
    80004cc6:	6161                	addi	sp,sp,80
    80004cc8:	8082                	ret
      release(&pi->lock);
    80004cca:	8526                	mv	a0,s1
    80004ccc:	ffffc097          	auipc	ra,0xffffc
    80004cd0:	fb8080e7          	jalr	-72(ra) # 80000c84 <release>
      return -1;
    80004cd4:	59fd                	li	s3,-1
    80004cd6:	bff9                	j	80004cb4 <piperead+0xc4>

0000000080004cd8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cd8:	de010113          	addi	sp,sp,-544
    80004cdc:	20113c23          	sd	ra,536(sp)
    80004ce0:	20813823          	sd	s0,528(sp)
    80004ce4:	20913423          	sd	s1,520(sp)
    80004ce8:	21213023          	sd	s2,512(sp)
    80004cec:	ffce                	sd	s3,504(sp)
    80004cee:	fbd2                	sd	s4,496(sp)
    80004cf0:	f7d6                	sd	s5,488(sp)
    80004cf2:	f3da                	sd	s6,480(sp)
    80004cf4:	efde                	sd	s7,472(sp)
    80004cf6:	ebe2                	sd	s8,464(sp)
    80004cf8:	e7e6                	sd	s9,456(sp)
    80004cfa:	e3ea                	sd	s10,448(sp)
    80004cfc:	ff6e                	sd	s11,440(sp)
    80004cfe:	1400                	addi	s0,sp,544
    80004d00:	892a                	mv	s2,a0
    80004d02:	dea43423          	sd	a0,-536(s0)
    80004d06:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d0a:	ffffd097          	auipc	ra,0xffffd
    80004d0e:	c8c080e7          	jalr	-884(ra) # 80001996 <myproc>
    80004d12:	84aa                	mv	s1,a0

  begin_op();
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	4a8080e7          	jalr	1192(ra) # 800041bc <begin_op>

  if((ip = namei(path)) == 0){
    80004d1c:	854a                	mv	a0,s2
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	27e080e7          	jalr	638(ra) # 80003f9c <namei>
    80004d26:	c93d                	beqz	a0,80004d9c <exec+0xc4>
    80004d28:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	ab6080e7          	jalr	-1354(ra) # 800037e0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d32:	04000713          	li	a4,64
    80004d36:	4681                	li	a3,0
    80004d38:	e5040613          	addi	a2,s0,-432
    80004d3c:	4581                	li	a1,0
    80004d3e:	8556                	mv	a0,s5
    80004d40:	fffff097          	auipc	ra,0xfffff
    80004d44:	d54080e7          	jalr	-684(ra) # 80003a94 <readi>
    80004d48:	04000793          	li	a5,64
    80004d4c:	00f51a63          	bne	a0,a5,80004d60 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d50:	e5042703          	lw	a4,-432(s0)
    80004d54:	464c47b7          	lui	a5,0x464c4
    80004d58:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d5c:	04f70663          	beq	a4,a5,80004da8 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d60:	8556                	mv	a0,s5
    80004d62:	fffff097          	auipc	ra,0xfffff
    80004d66:	ce0080e7          	jalr	-800(ra) # 80003a42 <iunlockput>
    end_op();
    80004d6a:	fffff097          	auipc	ra,0xfffff
    80004d6e:	4d0080e7          	jalr	1232(ra) # 8000423a <end_op>
  }
  return -1;
    80004d72:	557d                	li	a0,-1
}
    80004d74:	21813083          	ld	ra,536(sp)
    80004d78:	21013403          	ld	s0,528(sp)
    80004d7c:	20813483          	ld	s1,520(sp)
    80004d80:	20013903          	ld	s2,512(sp)
    80004d84:	79fe                	ld	s3,504(sp)
    80004d86:	7a5e                	ld	s4,496(sp)
    80004d88:	7abe                	ld	s5,488(sp)
    80004d8a:	7b1e                	ld	s6,480(sp)
    80004d8c:	6bfe                	ld	s7,472(sp)
    80004d8e:	6c5e                	ld	s8,464(sp)
    80004d90:	6cbe                	ld	s9,456(sp)
    80004d92:	6d1e                	ld	s10,448(sp)
    80004d94:	7dfa                	ld	s11,440(sp)
    80004d96:	22010113          	addi	sp,sp,544
    80004d9a:	8082                	ret
    end_op();
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	49e080e7          	jalr	1182(ra) # 8000423a <end_op>
    return -1;
    80004da4:	557d                	li	a0,-1
    80004da6:	b7f9                	j	80004d74 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004da8:	8526                	mv	a0,s1
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	cb0080e7          	jalr	-848(ra) # 80001a5a <proc_pagetable>
    80004db2:	8b2a                	mv	s6,a0
    80004db4:	d555                	beqz	a0,80004d60 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004db6:	e7042783          	lw	a5,-400(s0)
    80004dba:	e8845703          	lhu	a4,-376(s0)
    80004dbe:	c735                	beqz	a4,80004e2a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dc0:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dc2:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004dc6:	6a05                	lui	s4,0x1
    80004dc8:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004dcc:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004dd0:	6d85                	lui	s11,0x1
    80004dd2:	7d7d                	lui	s10,0xfffff
    80004dd4:	ac1d                	j	8000500a <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dd6:	00004517          	auipc	a0,0x4
    80004dda:	91250513          	addi	a0,a0,-1774 # 800086e8 <syscalls+0x2a0>
    80004dde:	ffffb097          	auipc	ra,0xffffb
    80004de2:	75c080e7          	jalr	1884(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004de6:	874a                	mv	a4,s2
    80004de8:	009c86bb          	addw	a3,s9,s1
    80004dec:	4581                	li	a1,0
    80004dee:	8556                	mv	a0,s5
    80004df0:	fffff097          	auipc	ra,0xfffff
    80004df4:	ca4080e7          	jalr	-860(ra) # 80003a94 <readi>
    80004df8:	2501                	sext.w	a0,a0
    80004dfa:	1aa91863          	bne	s2,a0,80004faa <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004dfe:	009d84bb          	addw	s1,s11,s1
    80004e02:	013d09bb          	addw	s3,s10,s3
    80004e06:	1f74f263          	bgeu	s1,s7,80004fea <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004e0a:	02049593          	slli	a1,s1,0x20
    80004e0e:	9181                	srli	a1,a1,0x20
    80004e10:	95e2                	add	a1,a1,s8
    80004e12:	855a                	mv	a0,s6
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	23e080e7          	jalr	574(ra) # 80001052 <walkaddr>
    80004e1c:	862a                	mv	a2,a0
    if(pa == 0)
    80004e1e:	dd45                	beqz	a0,80004dd6 <exec+0xfe>
      n = PGSIZE;
    80004e20:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e22:	fd49f2e3          	bgeu	s3,s4,80004de6 <exec+0x10e>
      n = sz - i;
    80004e26:	894e                	mv	s2,s3
    80004e28:	bf7d                	j	80004de6 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e2a:	4481                	li	s1,0
  iunlockput(ip);
    80004e2c:	8556                	mv	a0,s5
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	c14080e7          	jalr	-1004(ra) # 80003a42 <iunlockput>
  end_op();
    80004e36:	fffff097          	auipc	ra,0xfffff
    80004e3a:	404080e7          	jalr	1028(ra) # 8000423a <end_op>
  p = myproc();
    80004e3e:	ffffd097          	auipc	ra,0xffffd
    80004e42:	b58080e7          	jalr	-1192(ra) # 80001996 <myproc>
    80004e46:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e48:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e4c:	6785                	lui	a5,0x1
    80004e4e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004e50:	97a6                	add	a5,a5,s1
    80004e52:	777d                	lui	a4,0xfffff
    80004e54:	8ff9                	and	a5,a5,a4
    80004e56:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e5a:	6609                	lui	a2,0x2
    80004e5c:	963e                	add	a2,a2,a5
    80004e5e:	85be                	mv	a1,a5
    80004e60:	855a                	mv	a0,s6
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	5a4080e7          	jalr	1444(ra) # 80001406 <uvmalloc>
    80004e6a:	8c2a                	mv	s8,a0
  ip = 0;
    80004e6c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e6e:	12050e63          	beqz	a0,80004faa <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e72:	75f9                	lui	a1,0xffffe
    80004e74:	95aa                	add	a1,a1,a0
    80004e76:	855a                	mv	a0,s6
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	7b0080e7          	jalr	1968(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e80:	7afd                	lui	s5,0xfffff
    80004e82:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e84:	df043783          	ld	a5,-528(s0)
    80004e88:	6388                	ld	a0,0(a5)
    80004e8a:	c925                	beqz	a0,80004efa <exec+0x222>
    80004e8c:	e9040993          	addi	s3,s0,-368
    80004e90:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e94:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e96:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	fb0080e7          	jalr	-80(ra) # 80000e48 <strlen>
    80004ea0:	0015079b          	addiw	a5,a0,1
    80004ea4:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ea8:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004eac:	13596363          	bltu	s2,s5,80004fd2 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eb0:	df043d83          	ld	s11,-528(s0)
    80004eb4:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004eb8:	8552                	mv	a0,s4
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	f8e080e7          	jalr	-114(ra) # 80000e48 <strlen>
    80004ec2:	0015069b          	addiw	a3,a0,1
    80004ec6:	8652                	mv	a2,s4
    80004ec8:	85ca                	mv	a1,s2
    80004eca:	855a                	mv	a0,s6
    80004ecc:	ffffc097          	auipc	ra,0xffffc
    80004ed0:	78e080e7          	jalr	1934(ra) # 8000165a <copyout>
    80004ed4:	10054363          	bltz	a0,80004fda <exec+0x302>
    ustack[argc] = sp;
    80004ed8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004edc:	0485                	addi	s1,s1,1
    80004ede:	008d8793          	addi	a5,s11,8
    80004ee2:	def43823          	sd	a5,-528(s0)
    80004ee6:	008db503          	ld	a0,8(s11)
    80004eea:	c911                	beqz	a0,80004efe <exec+0x226>
    if(argc >= MAXARG)
    80004eec:	09a1                	addi	s3,s3,8
    80004eee:	fb3c95e3          	bne	s9,s3,80004e98 <exec+0x1c0>
  sz = sz1;
    80004ef2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ef6:	4a81                	li	s5,0
    80004ef8:	a84d                	j	80004faa <exec+0x2d2>
  sp = sz;
    80004efa:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004efc:	4481                	li	s1,0
  ustack[argc] = 0;
    80004efe:	00349793          	slli	a5,s1,0x3
    80004f02:	f9078793          	addi	a5,a5,-112
    80004f06:	97a2                	add	a5,a5,s0
    80004f08:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004f0c:	00148693          	addi	a3,s1,1
    80004f10:	068e                	slli	a3,a3,0x3
    80004f12:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f16:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f1a:	01597663          	bgeu	s2,s5,80004f26 <exec+0x24e>
  sz = sz1;
    80004f1e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f22:	4a81                	li	s5,0
    80004f24:	a059                	j	80004faa <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f26:	e9040613          	addi	a2,s0,-368
    80004f2a:	85ca                	mv	a1,s2
    80004f2c:	855a                	mv	a0,s6
    80004f2e:	ffffc097          	auipc	ra,0xffffc
    80004f32:	72c080e7          	jalr	1836(ra) # 8000165a <copyout>
    80004f36:	0a054663          	bltz	a0,80004fe2 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004f3a:	058bb783          	ld	a5,88(s7)
    80004f3e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f42:	de843783          	ld	a5,-536(s0)
    80004f46:	0007c703          	lbu	a4,0(a5)
    80004f4a:	cf11                	beqz	a4,80004f66 <exec+0x28e>
    80004f4c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f4e:	02f00693          	li	a3,47
    80004f52:	a039                	j	80004f60 <exec+0x288>
      last = s+1;
    80004f54:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f58:	0785                	addi	a5,a5,1
    80004f5a:	fff7c703          	lbu	a4,-1(a5)
    80004f5e:	c701                	beqz	a4,80004f66 <exec+0x28e>
    if(*s == '/')
    80004f60:	fed71ce3          	bne	a4,a3,80004f58 <exec+0x280>
    80004f64:	bfc5                	j	80004f54 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f66:	4641                	li	a2,16
    80004f68:	de843583          	ld	a1,-536(s0)
    80004f6c:	158b8513          	addi	a0,s7,344
    80004f70:	ffffc097          	auipc	ra,0xffffc
    80004f74:	ea6080e7          	jalr	-346(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f78:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f7c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f80:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f84:	058bb783          	ld	a5,88(s7)
    80004f88:	e6843703          	ld	a4,-408(s0)
    80004f8c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f8e:	058bb783          	ld	a5,88(s7)
    80004f92:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f96:	85ea                	mv	a1,s10
    80004f98:	ffffd097          	auipc	ra,0xffffd
    80004f9c:	b5e080e7          	jalr	-1186(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fa0:	0004851b          	sext.w	a0,s1
    80004fa4:	bbc1                	j	80004d74 <exec+0x9c>
    80004fa6:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004faa:	df843583          	ld	a1,-520(s0)
    80004fae:	855a                	mv	a0,s6
    80004fb0:	ffffd097          	auipc	ra,0xffffd
    80004fb4:	b46080e7          	jalr	-1210(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    80004fb8:	da0a94e3          	bnez	s5,80004d60 <exec+0x88>
  return -1;
    80004fbc:	557d                	li	a0,-1
    80004fbe:	bb5d                	j	80004d74 <exec+0x9c>
    80004fc0:	de943c23          	sd	s1,-520(s0)
    80004fc4:	b7dd                	j	80004faa <exec+0x2d2>
    80004fc6:	de943c23          	sd	s1,-520(s0)
    80004fca:	b7c5                	j	80004faa <exec+0x2d2>
    80004fcc:	de943c23          	sd	s1,-520(s0)
    80004fd0:	bfe9                	j	80004faa <exec+0x2d2>
  sz = sz1;
    80004fd2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fd6:	4a81                	li	s5,0
    80004fd8:	bfc9                	j	80004faa <exec+0x2d2>
  sz = sz1;
    80004fda:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fde:	4a81                	li	s5,0
    80004fe0:	b7e9                	j	80004faa <exec+0x2d2>
  sz = sz1;
    80004fe2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fe6:	4a81                	li	s5,0
    80004fe8:	b7c9                	j	80004faa <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fea:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fee:	e0843783          	ld	a5,-504(s0)
    80004ff2:	0017869b          	addiw	a3,a5,1
    80004ff6:	e0d43423          	sd	a3,-504(s0)
    80004ffa:	e0043783          	ld	a5,-512(s0)
    80004ffe:	0387879b          	addiw	a5,a5,56
    80005002:	e8845703          	lhu	a4,-376(s0)
    80005006:	e2e6d3e3          	bge	a3,a4,80004e2c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000500a:	2781                	sext.w	a5,a5
    8000500c:	e0f43023          	sd	a5,-512(s0)
    80005010:	03800713          	li	a4,56
    80005014:	86be                	mv	a3,a5
    80005016:	e1840613          	addi	a2,s0,-488
    8000501a:	4581                	li	a1,0
    8000501c:	8556                	mv	a0,s5
    8000501e:	fffff097          	auipc	ra,0xfffff
    80005022:	a76080e7          	jalr	-1418(ra) # 80003a94 <readi>
    80005026:	03800793          	li	a5,56
    8000502a:	f6f51ee3          	bne	a0,a5,80004fa6 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000502e:	e1842783          	lw	a5,-488(s0)
    80005032:	4705                	li	a4,1
    80005034:	fae79de3          	bne	a5,a4,80004fee <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005038:	e4043603          	ld	a2,-448(s0)
    8000503c:	e3843783          	ld	a5,-456(s0)
    80005040:	f8f660e3          	bltu	a2,a5,80004fc0 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005044:	e2843783          	ld	a5,-472(s0)
    80005048:	963e                	add	a2,a2,a5
    8000504a:	f6f66ee3          	bltu	a2,a5,80004fc6 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000504e:	85a6                	mv	a1,s1
    80005050:	855a                	mv	a0,s6
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	3b4080e7          	jalr	948(ra) # 80001406 <uvmalloc>
    8000505a:	dea43c23          	sd	a0,-520(s0)
    8000505e:	d53d                	beqz	a0,80004fcc <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80005060:	e2843c03          	ld	s8,-472(s0)
    80005064:	de043783          	ld	a5,-544(s0)
    80005068:	00fc77b3          	and	a5,s8,a5
    8000506c:	ff9d                	bnez	a5,80004faa <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000506e:	e2042c83          	lw	s9,-480(s0)
    80005072:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005076:	f60b8ae3          	beqz	s7,80004fea <exec+0x312>
    8000507a:	89de                	mv	s3,s7
    8000507c:	4481                	li	s1,0
    8000507e:	b371                	j	80004e0a <exec+0x132>

0000000080005080 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005080:	7179                	addi	sp,sp,-48
    80005082:	f406                	sd	ra,40(sp)
    80005084:	f022                	sd	s0,32(sp)
    80005086:	ec26                	sd	s1,24(sp)
    80005088:	e84a                	sd	s2,16(sp)
    8000508a:	1800                	addi	s0,sp,48
    8000508c:	892e                	mv	s2,a1
    8000508e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005090:	fdc40593          	addi	a1,s0,-36
    80005094:	ffffe097          	auipc	ra,0xffffe
    80005098:	aec080e7          	jalr	-1300(ra) # 80002b80 <argint>
    8000509c:	04054063          	bltz	a0,800050dc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050a0:	fdc42703          	lw	a4,-36(s0)
    800050a4:	47bd                	li	a5,15
    800050a6:	02e7ed63          	bltu	a5,a4,800050e0 <argfd+0x60>
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	8ec080e7          	jalr	-1812(ra) # 80001996 <myproc>
    800050b2:	fdc42703          	lw	a4,-36(s0)
    800050b6:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    800050ba:	078e                	slli	a5,a5,0x3
    800050bc:	953e                	add	a0,a0,a5
    800050be:	611c                	ld	a5,0(a0)
    800050c0:	c395                	beqz	a5,800050e4 <argfd+0x64>
    return -1;
  if(pfd)
    800050c2:	00090463          	beqz	s2,800050ca <argfd+0x4a>
    *pfd = fd;
    800050c6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050ca:	4501                	li	a0,0
  if(pf)
    800050cc:	c091                	beqz	s1,800050d0 <argfd+0x50>
    *pf = f;
    800050ce:	e09c                	sd	a5,0(s1)
}
    800050d0:	70a2                	ld	ra,40(sp)
    800050d2:	7402                	ld	s0,32(sp)
    800050d4:	64e2                	ld	s1,24(sp)
    800050d6:	6942                	ld	s2,16(sp)
    800050d8:	6145                	addi	sp,sp,48
    800050da:	8082                	ret
    return -1;
    800050dc:	557d                	li	a0,-1
    800050de:	bfcd                	j	800050d0 <argfd+0x50>
    return -1;
    800050e0:	557d                	li	a0,-1
    800050e2:	b7fd                	j	800050d0 <argfd+0x50>
    800050e4:	557d                	li	a0,-1
    800050e6:	b7ed                	j	800050d0 <argfd+0x50>

00000000800050e8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050e8:	1101                	addi	sp,sp,-32
    800050ea:	ec06                	sd	ra,24(sp)
    800050ec:	e822                	sd	s0,16(sp)
    800050ee:	e426                	sd	s1,8(sp)
    800050f0:	1000                	addi	s0,sp,32
    800050f2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050f4:	ffffd097          	auipc	ra,0xffffd
    800050f8:	8a2080e7          	jalr	-1886(ra) # 80001996 <myproc>
    800050fc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050fe:	0d050793          	addi	a5,a0,208
    80005102:	4501                	li	a0,0
    80005104:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005106:	6398                	ld	a4,0(a5)
    80005108:	cb19                	beqz	a4,8000511e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000510a:	2505                	addiw	a0,a0,1
    8000510c:	07a1                	addi	a5,a5,8
    8000510e:	fed51ce3          	bne	a0,a3,80005106 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005112:	557d                	li	a0,-1
}
    80005114:	60e2                	ld	ra,24(sp)
    80005116:	6442                	ld	s0,16(sp)
    80005118:	64a2                	ld	s1,8(sp)
    8000511a:	6105                	addi	sp,sp,32
    8000511c:	8082                	ret
      p->ofile[fd] = f;
    8000511e:	01a50793          	addi	a5,a0,26
    80005122:	078e                	slli	a5,a5,0x3
    80005124:	963e                	add	a2,a2,a5
    80005126:	e204                	sd	s1,0(a2)
      return fd;
    80005128:	b7f5                	j	80005114 <fdalloc+0x2c>

000000008000512a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000512a:	715d                	addi	sp,sp,-80
    8000512c:	e486                	sd	ra,72(sp)
    8000512e:	e0a2                	sd	s0,64(sp)
    80005130:	fc26                	sd	s1,56(sp)
    80005132:	f84a                	sd	s2,48(sp)
    80005134:	f44e                	sd	s3,40(sp)
    80005136:	f052                	sd	s4,32(sp)
    80005138:	ec56                	sd	s5,24(sp)
    8000513a:	0880                	addi	s0,sp,80
    8000513c:	89ae                	mv	s3,a1
    8000513e:	8ab2                	mv	s5,a2
    80005140:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005142:	fb040593          	addi	a1,s0,-80
    80005146:	fffff097          	auipc	ra,0xfffff
    8000514a:	e74080e7          	jalr	-396(ra) # 80003fba <nameiparent>
    8000514e:	892a                	mv	s2,a0
    80005150:	12050e63          	beqz	a0,8000528c <create+0x162>
    return 0;

  ilock(dp);
    80005154:	ffffe097          	auipc	ra,0xffffe
    80005158:	68c080e7          	jalr	1676(ra) # 800037e0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000515c:	4601                	li	a2,0
    8000515e:	fb040593          	addi	a1,s0,-80
    80005162:	854a                	mv	a0,s2
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	b60080e7          	jalr	-1184(ra) # 80003cc4 <dirlookup>
    8000516c:	84aa                	mv	s1,a0
    8000516e:	c921                	beqz	a0,800051be <create+0x94>
    iunlockput(dp);
    80005170:	854a                	mv	a0,s2
    80005172:	fffff097          	auipc	ra,0xfffff
    80005176:	8d0080e7          	jalr	-1840(ra) # 80003a42 <iunlockput>
    ilock(ip);
    8000517a:	8526                	mv	a0,s1
    8000517c:	ffffe097          	auipc	ra,0xffffe
    80005180:	664080e7          	jalr	1636(ra) # 800037e0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005184:	2981                	sext.w	s3,s3
    80005186:	4789                	li	a5,2
    80005188:	02f99463          	bne	s3,a5,800051b0 <create+0x86>
    8000518c:	0444d783          	lhu	a5,68(s1)
    80005190:	37f9                	addiw	a5,a5,-2
    80005192:	17c2                	slli	a5,a5,0x30
    80005194:	93c1                	srli	a5,a5,0x30
    80005196:	4705                	li	a4,1
    80005198:	00f76c63          	bltu	a4,a5,800051b0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000519c:	8526                	mv	a0,s1
    8000519e:	60a6                	ld	ra,72(sp)
    800051a0:	6406                	ld	s0,64(sp)
    800051a2:	74e2                	ld	s1,56(sp)
    800051a4:	7942                	ld	s2,48(sp)
    800051a6:	79a2                	ld	s3,40(sp)
    800051a8:	7a02                	ld	s4,32(sp)
    800051aa:	6ae2                	ld	s5,24(sp)
    800051ac:	6161                	addi	sp,sp,80
    800051ae:	8082                	ret
    iunlockput(ip);
    800051b0:	8526                	mv	a0,s1
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	890080e7          	jalr	-1904(ra) # 80003a42 <iunlockput>
    return 0;
    800051ba:	4481                	li	s1,0
    800051bc:	b7c5                	j	8000519c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051be:	85ce                	mv	a1,s3
    800051c0:	00092503          	lw	a0,0(s2)
    800051c4:	ffffe097          	auipc	ra,0xffffe
    800051c8:	482080e7          	jalr	1154(ra) # 80003646 <ialloc>
    800051cc:	84aa                	mv	s1,a0
    800051ce:	c521                	beqz	a0,80005216 <create+0xec>
  ilock(ip);
    800051d0:	ffffe097          	auipc	ra,0xffffe
    800051d4:	610080e7          	jalr	1552(ra) # 800037e0 <ilock>
  ip->major = major;
    800051d8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051dc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051e0:	4a05                	li	s4,1
    800051e2:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800051e6:	8526                	mv	a0,s1
    800051e8:	ffffe097          	auipc	ra,0xffffe
    800051ec:	52c080e7          	jalr	1324(ra) # 80003714 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051f0:	2981                	sext.w	s3,s3
    800051f2:	03498a63          	beq	s3,s4,80005226 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800051f6:	40d0                	lw	a2,4(s1)
    800051f8:	fb040593          	addi	a1,s0,-80
    800051fc:	854a                	mv	a0,s2
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	cdc080e7          	jalr	-804(ra) # 80003eda <dirlink>
    80005206:	06054b63          	bltz	a0,8000527c <create+0x152>
  iunlockput(dp);
    8000520a:	854a                	mv	a0,s2
    8000520c:	fffff097          	auipc	ra,0xfffff
    80005210:	836080e7          	jalr	-1994(ra) # 80003a42 <iunlockput>
  return ip;
    80005214:	b761                	j	8000519c <create+0x72>
    panic("create: ialloc");
    80005216:	00003517          	auipc	a0,0x3
    8000521a:	4f250513          	addi	a0,a0,1266 # 80008708 <syscalls+0x2c0>
    8000521e:	ffffb097          	auipc	ra,0xffffb
    80005222:	31c080e7          	jalr	796(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    80005226:	04a95783          	lhu	a5,74(s2)
    8000522a:	2785                	addiw	a5,a5,1
    8000522c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005230:	854a                	mv	a0,s2
    80005232:	ffffe097          	auipc	ra,0xffffe
    80005236:	4e2080e7          	jalr	1250(ra) # 80003714 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000523a:	40d0                	lw	a2,4(s1)
    8000523c:	00003597          	auipc	a1,0x3
    80005240:	4dc58593          	addi	a1,a1,1244 # 80008718 <syscalls+0x2d0>
    80005244:	8526                	mv	a0,s1
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	c94080e7          	jalr	-876(ra) # 80003eda <dirlink>
    8000524e:	00054f63          	bltz	a0,8000526c <create+0x142>
    80005252:	00492603          	lw	a2,4(s2)
    80005256:	00003597          	auipc	a1,0x3
    8000525a:	4ca58593          	addi	a1,a1,1226 # 80008720 <syscalls+0x2d8>
    8000525e:	8526                	mv	a0,s1
    80005260:	fffff097          	auipc	ra,0xfffff
    80005264:	c7a080e7          	jalr	-902(ra) # 80003eda <dirlink>
    80005268:	f80557e3          	bgez	a0,800051f6 <create+0xcc>
      panic("create dots");
    8000526c:	00003517          	auipc	a0,0x3
    80005270:	4bc50513          	addi	a0,a0,1212 # 80008728 <syscalls+0x2e0>
    80005274:	ffffb097          	auipc	ra,0xffffb
    80005278:	2c6080e7          	jalr	710(ra) # 8000053a <panic>
    panic("create: dirlink");
    8000527c:	00003517          	auipc	a0,0x3
    80005280:	4bc50513          	addi	a0,a0,1212 # 80008738 <syscalls+0x2f0>
    80005284:	ffffb097          	auipc	ra,0xffffb
    80005288:	2b6080e7          	jalr	694(ra) # 8000053a <panic>
    return 0;
    8000528c:	84aa                	mv	s1,a0
    8000528e:	b739                	j	8000519c <create+0x72>

0000000080005290 <sys_dup>:
{
    80005290:	7179                	addi	sp,sp,-48
    80005292:	f406                	sd	ra,40(sp)
    80005294:	f022                	sd	s0,32(sp)
    80005296:	ec26                	sd	s1,24(sp)
    80005298:	e84a                	sd	s2,16(sp)
    8000529a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000529c:	fd840613          	addi	a2,s0,-40
    800052a0:	4581                	li	a1,0
    800052a2:	4501                	li	a0,0
    800052a4:	00000097          	auipc	ra,0x0
    800052a8:	ddc080e7          	jalr	-548(ra) # 80005080 <argfd>
    return -1;
    800052ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052ae:	02054363          	bltz	a0,800052d4 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800052b2:	fd843903          	ld	s2,-40(s0)
    800052b6:	854a                	mv	a0,s2
    800052b8:	00000097          	auipc	ra,0x0
    800052bc:	e30080e7          	jalr	-464(ra) # 800050e8 <fdalloc>
    800052c0:	84aa                	mv	s1,a0
    return -1;
    800052c2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052c4:	00054863          	bltz	a0,800052d4 <sys_dup+0x44>
  filedup(f);
    800052c8:	854a                	mv	a0,s2
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	368080e7          	jalr	872(ra) # 80004632 <filedup>
  return fd;
    800052d2:	87a6                	mv	a5,s1
}
    800052d4:	853e                	mv	a0,a5
    800052d6:	70a2                	ld	ra,40(sp)
    800052d8:	7402                	ld	s0,32(sp)
    800052da:	64e2                	ld	s1,24(sp)
    800052dc:	6942                	ld	s2,16(sp)
    800052de:	6145                	addi	sp,sp,48
    800052e0:	8082                	ret

00000000800052e2 <sys_read>:
{
    800052e2:	7179                	addi	sp,sp,-48
    800052e4:	f406                	sd	ra,40(sp)
    800052e6:	f022                	sd	s0,32(sp)
    800052e8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ea:	fe840613          	addi	a2,s0,-24
    800052ee:	4581                	li	a1,0
    800052f0:	4501                	li	a0,0
    800052f2:	00000097          	auipc	ra,0x0
    800052f6:	d8e080e7          	jalr	-626(ra) # 80005080 <argfd>
    return -1;
    800052fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fc:	04054163          	bltz	a0,8000533e <sys_read+0x5c>
    80005300:	fe440593          	addi	a1,s0,-28
    80005304:	4509                	li	a0,2
    80005306:	ffffe097          	auipc	ra,0xffffe
    8000530a:	87a080e7          	jalr	-1926(ra) # 80002b80 <argint>
    return -1;
    8000530e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005310:	02054763          	bltz	a0,8000533e <sys_read+0x5c>
    80005314:	fd840593          	addi	a1,s0,-40
    80005318:	4505                	li	a0,1
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	888080e7          	jalr	-1912(ra) # 80002ba2 <argaddr>
    return -1;
    80005322:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005324:	00054d63          	bltz	a0,8000533e <sys_read+0x5c>
  return fileread(f, p, n);
    80005328:	fe442603          	lw	a2,-28(s0)
    8000532c:	fd843583          	ld	a1,-40(s0)
    80005330:	fe843503          	ld	a0,-24(s0)
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	48a080e7          	jalr	1162(ra) # 800047be <fileread>
    8000533c:	87aa                	mv	a5,a0
}
    8000533e:	853e                	mv	a0,a5
    80005340:	70a2                	ld	ra,40(sp)
    80005342:	7402                	ld	s0,32(sp)
    80005344:	6145                	addi	sp,sp,48
    80005346:	8082                	ret

0000000080005348 <sys_write>:
{
    80005348:	7179                	addi	sp,sp,-48
    8000534a:	f406                	sd	ra,40(sp)
    8000534c:	f022                	sd	s0,32(sp)
    8000534e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005350:	fe840613          	addi	a2,s0,-24
    80005354:	4581                	li	a1,0
    80005356:	4501                	li	a0,0
    80005358:	00000097          	auipc	ra,0x0
    8000535c:	d28080e7          	jalr	-728(ra) # 80005080 <argfd>
    return -1;
    80005360:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005362:	04054163          	bltz	a0,800053a4 <sys_write+0x5c>
    80005366:	fe440593          	addi	a1,s0,-28
    8000536a:	4509                	li	a0,2
    8000536c:	ffffe097          	auipc	ra,0xffffe
    80005370:	814080e7          	jalr	-2028(ra) # 80002b80 <argint>
    return -1;
    80005374:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005376:	02054763          	bltz	a0,800053a4 <sys_write+0x5c>
    8000537a:	fd840593          	addi	a1,s0,-40
    8000537e:	4505                	li	a0,1
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	822080e7          	jalr	-2014(ra) # 80002ba2 <argaddr>
    return -1;
    80005388:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000538a:	00054d63          	bltz	a0,800053a4 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000538e:	fe442603          	lw	a2,-28(s0)
    80005392:	fd843583          	ld	a1,-40(s0)
    80005396:	fe843503          	ld	a0,-24(s0)
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	4e6080e7          	jalr	1254(ra) # 80004880 <filewrite>
    800053a2:	87aa                	mv	a5,a0
}
    800053a4:	853e                	mv	a0,a5
    800053a6:	70a2                	ld	ra,40(sp)
    800053a8:	7402                	ld	s0,32(sp)
    800053aa:	6145                	addi	sp,sp,48
    800053ac:	8082                	ret

00000000800053ae <sys_close>:
{
    800053ae:	1101                	addi	sp,sp,-32
    800053b0:	ec06                	sd	ra,24(sp)
    800053b2:	e822                	sd	s0,16(sp)
    800053b4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053b6:	fe040613          	addi	a2,s0,-32
    800053ba:	fec40593          	addi	a1,s0,-20
    800053be:	4501                	li	a0,0
    800053c0:	00000097          	auipc	ra,0x0
    800053c4:	cc0080e7          	jalr	-832(ra) # 80005080 <argfd>
    return -1;
    800053c8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053ca:	02054463          	bltz	a0,800053f2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053ce:	ffffc097          	auipc	ra,0xffffc
    800053d2:	5c8080e7          	jalr	1480(ra) # 80001996 <myproc>
    800053d6:	fec42783          	lw	a5,-20(s0)
    800053da:	07e9                	addi	a5,a5,26
    800053dc:	078e                	slli	a5,a5,0x3
    800053de:	953e                	add	a0,a0,a5
    800053e0:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800053e4:	fe043503          	ld	a0,-32(s0)
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	29c080e7          	jalr	668(ra) # 80004684 <fileclose>
  return 0;
    800053f0:	4781                	li	a5,0
}
    800053f2:	853e                	mv	a0,a5
    800053f4:	60e2                	ld	ra,24(sp)
    800053f6:	6442                	ld	s0,16(sp)
    800053f8:	6105                	addi	sp,sp,32
    800053fa:	8082                	ret

00000000800053fc <sys_fstat>:
{
    800053fc:	1101                	addi	sp,sp,-32
    800053fe:	ec06                	sd	ra,24(sp)
    80005400:	e822                	sd	s0,16(sp)
    80005402:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005404:	fe840613          	addi	a2,s0,-24
    80005408:	4581                	li	a1,0
    8000540a:	4501                	li	a0,0
    8000540c:	00000097          	auipc	ra,0x0
    80005410:	c74080e7          	jalr	-908(ra) # 80005080 <argfd>
    return -1;
    80005414:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005416:	02054563          	bltz	a0,80005440 <sys_fstat+0x44>
    8000541a:	fe040593          	addi	a1,s0,-32
    8000541e:	4505                	li	a0,1
    80005420:	ffffd097          	auipc	ra,0xffffd
    80005424:	782080e7          	jalr	1922(ra) # 80002ba2 <argaddr>
    return -1;
    80005428:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000542a:	00054b63          	bltz	a0,80005440 <sys_fstat+0x44>
  return filestat(f, st);
    8000542e:	fe043583          	ld	a1,-32(s0)
    80005432:	fe843503          	ld	a0,-24(s0)
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	316080e7          	jalr	790(ra) # 8000474c <filestat>
    8000543e:	87aa                	mv	a5,a0
}
    80005440:	853e                	mv	a0,a5
    80005442:	60e2                	ld	ra,24(sp)
    80005444:	6442                	ld	s0,16(sp)
    80005446:	6105                	addi	sp,sp,32
    80005448:	8082                	ret

000000008000544a <sys_link>:
{
    8000544a:	7169                	addi	sp,sp,-304
    8000544c:	f606                	sd	ra,296(sp)
    8000544e:	f222                	sd	s0,288(sp)
    80005450:	ee26                	sd	s1,280(sp)
    80005452:	ea4a                	sd	s2,272(sp)
    80005454:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005456:	08000613          	li	a2,128
    8000545a:	ed040593          	addi	a1,s0,-304
    8000545e:	4501                	li	a0,0
    80005460:	ffffd097          	auipc	ra,0xffffd
    80005464:	764080e7          	jalr	1892(ra) # 80002bc4 <argstr>
    return -1;
    80005468:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000546a:	10054e63          	bltz	a0,80005586 <sys_link+0x13c>
    8000546e:	08000613          	li	a2,128
    80005472:	f5040593          	addi	a1,s0,-176
    80005476:	4505                	li	a0,1
    80005478:	ffffd097          	auipc	ra,0xffffd
    8000547c:	74c080e7          	jalr	1868(ra) # 80002bc4 <argstr>
    return -1;
    80005480:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005482:	10054263          	bltz	a0,80005586 <sys_link+0x13c>
  begin_op();
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	d36080e7          	jalr	-714(ra) # 800041bc <begin_op>
  if((ip = namei(old)) == 0){
    8000548e:	ed040513          	addi	a0,s0,-304
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	b0a080e7          	jalr	-1270(ra) # 80003f9c <namei>
    8000549a:	84aa                	mv	s1,a0
    8000549c:	c551                	beqz	a0,80005528 <sys_link+0xde>
  ilock(ip);
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	342080e7          	jalr	834(ra) # 800037e0 <ilock>
  if(ip->type == T_DIR){
    800054a6:	04449703          	lh	a4,68(s1)
    800054aa:	4785                	li	a5,1
    800054ac:	08f70463          	beq	a4,a5,80005534 <sys_link+0xea>
  ip->nlink++;
    800054b0:	04a4d783          	lhu	a5,74(s1)
    800054b4:	2785                	addiw	a5,a5,1
    800054b6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ba:	8526                	mv	a0,s1
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	258080e7          	jalr	600(ra) # 80003714 <iupdate>
  iunlock(ip);
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	3dc080e7          	jalr	988(ra) # 800038a2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054ce:	fd040593          	addi	a1,s0,-48
    800054d2:	f5040513          	addi	a0,s0,-176
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	ae4080e7          	jalr	-1308(ra) # 80003fba <nameiparent>
    800054de:	892a                	mv	s2,a0
    800054e0:	c935                	beqz	a0,80005554 <sys_link+0x10a>
  ilock(dp);
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	2fe080e7          	jalr	766(ra) # 800037e0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054ea:	00092703          	lw	a4,0(s2)
    800054ee:	409c                	lw	a5,0(s1)
    800054f0:	04f71d63          	bne	a4,a5,8000554a <sys_link+0x100>
    800054f4:	40d0                	lw	a2,4(s1)
    800054f6:	fd040593          	addi	a1,s0,-48
    800054fa:	854a                	mv	a0,s2
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	9de080e7          	jalr	-1570(ra) # 80003eda <dirlink>
    80005504:	04054363          	bltz	a0,8000554a <sys_link+0x100>
  iunlockput(dp);
    80005508:	854a                	mv	a0,s2
    8000550a:	ffffe097          	auipc	ra,0xffffe
    8000550e:	538080e7          	jalr	1336(ra) # 80003a42 <iunlockput>
  iput(ip);
    80005512:	8526                	mv	a0,s1
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	486080e7          	jalr	1158(ra) # 8000399a <iput>
  end_op();
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	d1e080e7          	jalr	-738(ra) # 8000423a <end_op>
  return 0;
    80005524:	4781                	li	a5,0
    80005526:	a085                	j	80005586 <sys_link+0x13c>
    end_op();
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	d12080e7          	jalr	-750(ra) # 8000423a <end_op>
    return -1;
    80005530:	57fd                	li	a5,-1
    80005532:	a891                	j	80005586 <sys_link+0x13c>
    iunlockput(ip);
    80005534:	8526                	mv	a0,s1
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	50c080e7          	jalr	1292(ra) # 80003a42 <iunlockput>
    end_op();
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	cfc080e7          	jalr	-772(ra) # 8000423a <end_op>
    return -1;
    80005546:	57fd                	li	a5,-1
    80005548:	a83d                	j	80005586 <sys_link+0x13c>
    iunlockput(dp);
    8000554a:	854a                	mv	a0,s2
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	4f6080e7          	jalr	1270(ra) # 80003a42 <iunlockput>
  ilock(ip);
    80005554:	8526                	mv	a0,s1
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	28a080e7          	jalr	650(ra) # 800037e0 <ilock>
  ip->nlink--;
    8000555e:	04a4d783          	lhu	a5,74(s1)
    80005562:	37fd                	addiw	a5,a5,-1
    80005564:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005568:	8526                	mv	a0,s1
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	1aa080e7          	jalr	426(ra) # 80003714 <iupdate>
  iunlockput(ip);
    80005572:	8526                	mv	a0,s1
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	4ce080e7          	jalr	1230(ra) # 80003a42 <iunlockput>
  end_op();
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	cbe080e7          	jalr	-834(ra) # 8000423a <end_op>
  return -1;
    80005584:	57fd                	li	a5,-1
}
    80005586:	853e                	mv	a0,a5
    80005588:	70b2                	ld	ra,296(sp)
    8000558a:	7412                	ld	s0,288(sp)
    8000558c:	64f2                	ld	s1,280(sp)
    8000558e:	6952                	ld	s2,272(sp)
    80005590:	6155                	addi	sp,sp,304
    80005592:	8082                	ret

0000000080005594 <sys_unlink>:
{
    80005594:	7151                	addi	sp,sp,-240
    80005596:	f586                	sd	ra,232(sp)
    80005598:	f1a2                	sd	s0,224(sp)
    8000559a:	eda6                	sd	s1,216(sp)
    8000559c:	e9ca                	sd	s2,208(sp)
    8000559e:	e5ce                	sd	s3,200(sp)
    800055a0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055a2:	08000613          	li	a2,128
    800055a6:	f3040593          	addi	a1,s0,-208
    800055aa:	4501                	li	a0,0
    800055ac:	ffffd097          	auipc	ra,0xffffd
    800055b0:	618080e7          	jalr	1560(ra) # 80002bc4 <argstr>
    800055b4:	18054163          	bltz	a0,80005736 <sys_unlink+0x1a2>
  begin_op();
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	c04080e7          	jalr	-1020(ra) # 800041bc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055c0:	fb040593          	addi	a1,s0,-80
    800055c4:	f3040513          	addi	a0,s0,-208
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	9f2080e7          	jalr	-1550(ra) # 80003fba <nameiparent>
    800055d0:	84aa                	mv	s1,a0
    800055d2:	c979                	beqz	a0,800056a8 <sys_unlink+0x114>
  ilock(dp);
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	20c080e7          	jalr	524(ra) # 800037e0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055dc:	00003597          	auipc	a1,0x3
    800055e0:	13c58593          	addi	a1,a1,316 # 80008718 <syscalls+0x2d0>
    800055e4:	fb040513          	addi	a0,s0,-80
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	6c2080e7          	jalr	1730(ra) # 80003caa <namecmp>
    800055f0:	14050a63          	beqz	a0,80005744 <sys_unlink+0x1b0>
    800055f4:	00003597          	auipc	a1,0x3
    800055f8:	12c58593          	addi	a1,a1,300 # 80008720 <syscalls+0x2d8>
    800055fc:	fb040513          	addi	a0,s0,-80
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	6aa080e7          	jalr	1706(ra) # 80003caa <namecmp>
    80005608:	12050e63          	beqz	a0,80005744 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000560c:	f2c40613          	addi	a2,s0,-212
    80005610:	fb040593          	addi	a1,s0,-80
    80005614:	8526                	mv	a0,s1
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	6ae080e7          	jalr	1710(ra) # 80003cc4 <dirlookup>
    8000561e:	892a                	mv	s2,a0
    80005620:	12050263          	beqz	a0,80005744 <sys_unlink+0x1b0>
  ilock(ip);
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	1bc080e7          	jalr	444(ra) # 800037e0 <ilock>
  if(ip->nlink < 1)
    8000562c:	04a91783          	lh	a5,74(s2)
    80005630:	08f05263          	blez	a5,800056b4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005634:	04491703          	lh	a4,68(s2)
    80005638:	4785                	li	a5,1
    8000563a:	08f70563          	beq	a4,a5,800056c4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000563e:	4641                	li	a2,16
    80005640:	4581                	li	a1,0
    80005642:	fc040513          	addi	a0,s0,-64
    80005646:	ffffb097          	auipc	ra,0xffffb
    8000564a:	686080e7          	jalr	1670(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000564e:	4741                	li	a4,16
    80005650:	f2c42683          	lw	a3,-212(s0)
    80005654:	fc040613          	addi	a2,s0,-64
    80005658:	4581                	li	a1,0
    8000565a:	8526                	mv	a0,s1
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	530080e7          	jalr	1328(ra) # 80003b8c <writei>
    80005664:	47c1                	li	a5,16
    80005666:	0af51563          	bne	a0,a5,80005710 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000566a:	04491703          	lh	a4,68(s2)
    8000566e:	4785                	li	a5,1
    80005670:	0af70863          	beq	a4,a5,80005720 <sys_unlink+0x18c>
  iunlockput(dp);
    80005674:	8526                	mv	a0,s1
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	3cc080e7          	jalr	972(ra) # 80003a42 <iunlockput>
  ip->nlink--;
    8000567e:	04a95783          	lhu	a5,74(s2)
    80005682:	37fd                	addiw	a5,a5,-1
    80005684:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005688:	854a                	mv	a0,s2
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	08a080e7          	jalr	138(ra) # 80003714 <iupdate>
  iunlockput(ip);
    80005692:	854a                	mv	a0,s2
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	3ae080e7          	jalr	942(ra) # 80003a42 <iunlockput>
  end_op();
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	b9e080e7          	jalr	-1122(ra) # 8000423a <end_op>
  return 0;
    800056a4:	4501                	li	a0,0
    800056a6:	a84d                	j	80005758 <sys_unlink+0x1c4>
    end_op();
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	b92080e7          	jalr	-1134(ra) # 8000423a <end_op>
    return -1;
    800056b0:	557d                	li	a0,-1
    800056b2:	a05d                	j	80005758 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056b4:	00003517          	auipc	a0,0x3
    800056b8:	09450513          	addi	a0,a0,148 # 80008748 <syscalls+0x300>
    800056bc:	ffffb097          	auipc	ra,0xffffb
    800056c0:	e7e080e7          	jalr	-386(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056c4:	04c92703          	lw	a4,76(s2)
    800056c8:	02000793          	li	a5,32
    800056cc:	f6e7f9e3          	bgeu	a5,a4,8000563e <sys_unlink+0xaa>
    800056d0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056d4:	4741                	li	a4,16
    800056d6:	86ce                	mv	a3,s3
    800056d8:	f1840613          	addi	a2,s0,-232
    800056dc:	4581                	li	a1,0
    800056de:	854a                	mv	a0,s2
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	3b4080e7          	jalr	948(ra) # 80003a94 <readi>
    800056e8:	47c1                	li	a5,16
    800056ea:	00f51b63          	bne	a0,a5,80005700 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056ee:	f1845783          	lhu	a5,-232(s0)
    800056f2:	e7a1                	bnez	a5,8000573a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056f4:	29c1                	addiw	s3,s3,16
    800056f6:	04c92783          	lw	a5,76(s2)
    800056fa:	fcf9ede3          	bltu	s3,a5,800056d4 <sys_unlink+0x140>
    800056fe:	b781                	j	8000563e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005700:	00003517          	auipc	a0,0x3
    80005704:	06050513          	addi	a0,a0,96 # 80008760 <syscalls+0x318>
    80005708:	ffffb097          	auipc	ra,0xffffb
    8000570c:	e32080e7          	jalr	-462(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005710:	00003517          	auipc	a0,0x3
    80005714:	06850513          	addi	a0,a0,104 # 80008778 <syscalls+0x330>
    80005718:	ffffb097          	auipc	ra,0xffffb
    8000571c:	e22080e7          	jalr	-478(ra) # 8000053a <panic>
    dp->nlink--;
    80005720:	04a4d783          	lhu	a5,74(s1)
    80005724:	37fd                	addiw	a5,a5,-1
    80005726:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	fe8080e7          	jalr	-24(ra) # 80003714 <iupdate>
    80005734:	b781                	j	80005674 <sys_unlink+0xe0>
    return -1;
    80005736:	557d                	li	a0,-1
    80005738:	a005                	j	80005758 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000573a:	854a                	mv	a0,s2
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	306080e7          	jalr	774(ra) # 80003a42 <iunlockput>
  iunlockput(dp);
    80005744:	8526                	mv	a0,s1
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	2fc080e7          	jalr	764(ra) # 80003a42 <iunlockput>
  end_op();
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	aec080e7          	jalr	-1300(ra) # 8000423a <end_op>
  return -1;
    80005756:	557d                	li	a0,-1
}
    80005758:	70ae                	ld	ra,232(sp)
    8000575a:	740e                	ld	s0,224(sp)
    8000575c:	64ee                	ld	s1,216(sp)
    8000575e:	694e                	ld	s2,208(sp)
    80005760:	69ae                	ld	s3,200(sp)
    80005762:	616d                	addi	sp,sp,240
    80005764:	8082                	ret

0000000080005766 <sys_open>:

uint64
sys_open(void)
{
    80005766:	7131                	addi	sp,sp,-192
    80005768:	fd06                	sd	ra,184(sp)
    8000576a:	f922                	sd	s0,176(sp)
    8000576c:	f526                	sd	s1,168(sp)
    8000576e:	f14a                	sd	s2,160(sp)
    80005770:	ed4e                	sd	s3,152(sp)
    80005772:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005774:	08000613          	li	a2,128
    80005778:	f5040593          	addi	a1,s0,-176
    8000577c:	4501                	li	a0,0
    8000577e:	ffffd097          	auipc	ra,0xffffd
    80005782:	446080e7          	jalr	1094(ra) # 80002bc4 <argstr>
    return -1;
    80005786:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005788:	0c054163          	bltz	a0,8000584a <sys_open+0xe4>
    8000578c:	f4c40593          	addi	a1,s0,-180
    80005790:	4505                	li	a0,1
    80005792:	ffffd097          	auipc	ra,0xffffd
    80005796:	3ee080e7          	jalr	1006(ra) # 80002b80 <argint>
    8000579a:	0a054863          	bltz	a0,8000584a <sys_open+0xe4>

  begin_op();
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	a1e080e7          	jalr	-1506(ra) # 800041bc <begin_op>

  if(omode & O_CREATE){
    800057a6:	f4c42783          	lw	a5,-180(s0)
    800057aa:	2007f793          	andi	a5,a5,512
    800057ae:	cbdd                	beqz	a5,80005864 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057b0:	4681                	li	a3,0
    800057b2:	4601                	li	a2,0
    800057b4:	4589                	li	a1,2
    800057b6:	f5040513          	addi	a0,s0,-176
    800057ba:	00000097          	auipc	ra,0x0
    800057be:	970080e7          	jalr	-1680(ra) # 8000512a <create>
    800057c2:	892a                	mv	s2,a0
    if(ip == 0){
    800057c4:	c959                	beqz	a0,8000585a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057c6:	04491703          	lh	a4,68(s2)
    800057ca:	478d                	li	a5,3
    800057cc:	00f71763          	bne	a4,a5,800057da <sys_open+0x74>
    800057d0:	04695703          	lhu	a4,70(s2)
    800057d4:	47a5                	li	a5,9
    800057d6:	0ce7ec63          	bltu	a5,a4,800058ae <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	dee080e7          	jalr	-530(ra) # 800045c8 <filealloc>
    800057e2:	89aa                	mv	s3,a0
    800057e4:	10050263          	beqz	a0,800058e8 <sys_open+0x182>
    800057e8:	00000097          	auipc	ra,0x0
    800057ec:	900080e7          	jalr	-1792(ra) # 800050e8 <fdalloc>
    800057f0:	84aa                	mv	s1,a0
    800057f2:	0e054663          	bltz	a0,800058de <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057f6:	04491703          	lh	a4,68(s2)
    800057fa:	478d                	li	a5,3
    800057fc:	0cf70463          	beq	a4,a5,800058c4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005800:	4789                	li	a5,2
    80005802:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005806:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000580a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000580e:	f4c42783          	lw	a5,-180(s0)
    80005812:	0017c713          	xori	a4,a5,1
    80005816:	8b05                	andi	a4,a4,1
    80005818:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000581c:	0037f713          	andi	a4,a5,3
    80005820:	00e03733          	snez	a4,a4
    80005824:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005828:	4007f793          	andi	a5,a5,1024
    8000582c:	c791                	beqz	a5,80005838 <sys_open+0xd2>
    8000582e:	04491703          	lh	a4,68(s2)
    80005832:	4789                	li	a5,2
    80005834:	08f70f63          	beq	a4,a5,800058d2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005838:	854a                	mv	a0,s2
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	068080e7          	jalr	104(ra) # 800038a2 <iunlock>
  end_op();
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	9f8080e7          	jalr	-1544(ra) # 8000423a <end_op>

  return fd;
}
    8000584a:	8526                	mv	a0,s1
    8000584c:	70ea                	ld	ra,184(sp)
    8000584e:	744a                	ld	s0,176(sp)
    80005850:	74aa                	ld	s1,168(sp)
    80005852:	790a                	ld	s2,160(sp)
    80005854:	69ea                	ld	s3,152(sp)
    80005856:	6129                	addi	sp,sp,192
    80005858:	8082                	ret
      end_op();
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	9e0080e7          	jalr	-1568(ra) # 8000423a <end_op>
      return -1;
    80005862:	b7e5                	j	8000584a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005864:	f5040513          	addi	a0,s0,-176
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	734080e7          	jalr	1844(ra) # 80003f9c <namei>
    80005870:	892a                	mv	s2,a0
    80005872:	c905                	beqz	a0,800058a2 <sys_open+0x13c>
    ilock(ip);
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	f6c080e7          	jalr	-148(ra) # 800037e0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000587c:	04491703          	lh	a4,68(s2)
    80005880:	4785                	li	a5,1
    80005882:	f4f712e3          	bne	a4,a5,800057c6 <sys_open+0x60>
    80005886:	f4c42783          	lw	a5,-180(s0)
    8000588a:	dba1                	beqz	a5,800057da <sys_open+0x74>
      iunlockput(ip);
    8000588c:	854a                	mv	a0,s2
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	1b4080e7          	jalr	436(ra) # 80003a42 <iunlockput>
      end_op();
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	9a4080e7          	jalr	-1628(ra) # 8000423a <end_op>
      return -1;
    8000589e:	54fd                	li	s1,-1
    800058a0:	b76d                	j	8000584a <sys_open+0xe4>
      end_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	998080e7          	jalr	-1640(ra) # 8000423a <end_op>
      return -1;
    800058aa:	54fd                	li	s1,-1
    800058ac:	bf79                	j	8000584a <sys_open+0xe4>
    iunlockput(ip);
    800058ae:	854a                	mv	a0,s2
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	192080e7          	jalr	402(ra) # 80003a42 <iunlockput>
    end_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	982080e7          	jalr	-1662(ra) # 8000423a <end_op>
    return -1;
    800058c0:	54fd                	li	s1,-1
    800058c2:	b761                	j	8000584a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058c4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058c8:	04691783          	lh	a5,70(s2)
    800058cc:	02f99223          	sh	a5,36(s3)
    800058d0:	bf2d                	j	8000580a <sys_open+0xa4>
    itrunc(ip);
    800058d2:	854a                	mv	a0,s2
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	01a080e7          	jalr	26(ra) # 800038ee <itrunc>
    800058dc:	bfb1                	j	80005838 <sys_open+0xd2>
      fileclose(f);
    800058de:	854e                	mv	a0,s3
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	da4080e7          	jalr	-604(ra) # 80004684 <fileclose>
    iunlockput(ip);
    800058e8:	854a                	mv	a0,s2
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	158080e7          	jalr	344(ra) # 80003a42 <iunlockput>
    end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	948080e7          	jalr	-1720(ra) # 8000423a <end_op>
    return -1;
    800058fa:	54fd                	li	s1,-1
    800058fc:	b7b9                	j	8000584a <sys_open+0xe4>

00000000800058fe <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058fe:	7175                	addi	sp,sp,-144
    80005900:	e506                	sd	ra,136(sp)
    80005902:	e122                	sd	s0,128(sp)
    80005904:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	8b6080e7          	jalr	-1866(ra) # 800041bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000590e:	08000613          	li	a2,128
    80005912:	f7040593          	addi	a1,s0,-144
    80005916:	4501                	li	a0,0
    80005918:	ffffd097          	auipc	ra,0xffffd
    8000591c:	2ac080e7          	jalr	684(ra) # 80002bc4 <argstr>
    80005920:	02054963          	bltz	a0,80005952 <sys_mkdir+0x54>
    80005924:	4681                	li	a3,0
    80005926:	4601                	li	a2,0
    80005928:	4585                	li	a1,1
    8000592a:	f7040513          	addi	a0,s0,-144
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	7fc080e7          	jalr	2044(ra) # 8000512a <create>
    80005936:	cd11                	beqz	a0,80005952 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	10a080e7          	jalr	266(ra) # 80003a42 <iunlockput>
  end_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	8fa080e7          	jalr	-1798(ra) # 8000423a <end_op>
  return 0;
    80005948:	4501                	li	a0,0
}
    8000594a:	60aa                	ld	ra,136(sp)
    8000594c:	640a                	ld	s0,128(sp)
    8000594e:	6149                	addi	sp,sp,144
    80005950:	8082                	ret
    end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	8e8080e7          	jalr	-1816(ra) # 8000423a <end_op>
    return -1;
    8000595a:	557d                	li	a0,-1
    8000595c:	b7fd                	j	8000594a <sys_mkdir+0x4c>

000000008000595e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000595e:	7135                	addi	sp,sp,-160
    80005960:	ed06                	sd	ra,152(sp)
    80005962:	e922                	sd	s0,144(sp)
    80005964:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	856080e7          	jalr	-1962(ra) # 800041bc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000596e:	08000613          	li	a2,128
    80005972:	f7040593          	addi	a1,s0,-144
    80005976:	4501                	li	a0,0
    80005978:	ffffd097          	auipc	ra,0xffffd
    8000597c:	24c080e7          	jalr	588(ra) # 80002bc4 <argstr>
    80005980:	04054a63          	bltz	a0,800059d4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005984:	f6c40593          	addi	a1,s0,-148
    80005988:	4505                	li	a0,1
    8000598a:	ffffd097          	auipc	ra,0xffffd
    8000598e:	1f6080e7          	jalr	502(ra) # 80002b80 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005992:	04054163          	bltz	a0,800059d4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005996:	f6840593          	addi	a1,s0,-152
    8000599a:	4509                	li	a0,2
    8000599c:	ffffd097          	auipc	ra,0xffffd
    800059a0:	1e4080e7          	jalr	484(ra) # 80002b80 <argint>
     argint(1, &major) < 0 ||
    800059a4:	02054863          	bltz	a0,800059d4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059a8:	f6841683          	lh	a3,-152(s0)
    800059ac:	f6c41603          	lh	a2,-148(s0)
    800059b0:	458d                	li	a1,3
    800059b2:	f7040513          	addi	a0,s0,-144
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	774080e7          	jalr	1908(ra) # 8000512a <create>
     argint(2, &minor) < 0 ||
    800059be:	c919                	beqz	a0,800059d4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	082080e7          	jalr	130(ra) # 80003a42 <iunlockput>
  end_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	872080e7          	jalr	-1934(ra) # 8000423a <end_op>
  return 0;
    800059d0:	4501                	li	a0,0
    800059d2:	a031                	j	800059de <sys_mknod+0x80>
    end_op();
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	866080e7          	jalr	-1946(ra) # 8000423a <end_op>
    return -1;
    800059dc:	557d                	li	a0,-1
}
    800059de:	60ea                	ld	ra,152(sp)
    800059e0:	644a                	ld	s0,144(sp)
    800059e2:	610d                	addi	sp,sp,160
    800059e4:	8082                	ret

00000000800059e6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059e6:	7135                	addi	sp,sp,-160
    800059e8:	ed06                	sd	ra,152(sp)
    800059ea:	e922                	sd	s0,144(sp)
    800059ec:	e526                	sd	s1,136(sp)
    800059ee:	e14a                	sd	s2,128(sp)
    800059f0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059f2:	ffffc097          	auipc	ra,0xffffc
    800059f6:	fa4080e7          	jalr	-92(ra) # 80001996 <myproc>
    800059fa:	892a                	mv	s2,a0
  
  begin_op();
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	7c0080e7          	jalr	1984(ra) # 800041bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a04:	08000613          	li	a2,128
    80005a08:	f6040593          	addi	a1,s0,-160
    80005a0c:	4501                	li	a0,0
    80005a0e:	ffffd097          	auipc	ra,0xffffd
    80005a12:	1b6080e7          	jalr	438(ra) # 80002bc4 <argstr>
    80005a16:	04054b63          	bltz	a0,80005a6c <sys_chdir+0x86>
    80005a1a:	f6040513          	addi	a0,s0,-160
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	57e080e7          	jalr	1406(ra) # 80003f9c <namei>
    80005a26:	84aa                	mv	s1,a0
    80005a28:	c131                	beqz	a0,80005a6c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	db6080e7          	jalr	-586(ra) # 800037e0 <ilock>
  if(ip->type != T_DIR){
    80005a32:	04449703          	lh	a4,68(s1)
    80005a36:	4785                	li	a5,1
    80005a38:	04f71063          	bne	a4,a5,80005a78 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a3c:	8526                	mv	a0,s1
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	e64080e7          	jalr	-412(ra) # 800038a2 <iunlock>
  iput(p->cwd);
    80005a46:	15093503          	ld	a0,336(s2)
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	f50080e7          	jalr	-176(ra) # 8000399a <iput>
  end_op();
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	7e8080e7          	jalr	2024(ra) # 8000423a <end_op>
  p->cwd = ip;
    80005a5a:	14993823          	sd	s1,336(s2)
  return 0;
    80005a5e:	4501                	li	a0,0
}
    80005a60:	60ea                	ld	ra,152(sp)
    80005a62:	644a                	ld	s0,144(sp)
    80005a64:	64aa                	ld	s1,136(sp)
    80005a66:	690a                	ld	s2,128(sp)
    80005a68:	610d                	addi	sp,sp,160
    80005a6a:	8082                	ret
    end_op();
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	7ce080e7          	jalr	1998(ra) # 8000423a <end_op>
    return -1;
    80005a74:	557d                	li	a0,-1
    80005a76:	b7ed                	j	80005a60 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a78:	8526                	mv	a0,s1
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	fc8080e7          	jalr	-56(ra) # 80003a42 <iunlockput>
    end_op();
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	7b8080e7          	jalr	1976(ra) # 8000423a <end_op>
    return -1;
    80005a8a:	557d                	li	a0,-1
    80005a8c:	bfd1                	j	80005a60 <sys_chdir+0x7a>

0000000080005a8e <sys_exec>:

uint64
sys_exec(void)
{
    80005a8e:	7145                	addi	sp,sp,-464
    80005a90:	e786                	sd	ra,456(sp)
    80005a92:	e3a2                	sd	s0,448(sp)
    80005a94:	ff26                	sd	s1,440(sp)
    80005a96:	fb4a                	sd	s2,432(sp)
    80005a98:	f74e                	sd	s3,424(sp)
    80005a9a:	f352                	sd	s4,416(sp)
    80005a9c:	ef56                	sd	s5,408(sp)
    80005a9e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005aa0:	08000613          	li	a2,128
    80005aa4:	f4040593          	addi	a1,s0,-192
    80005aa8:	4501                	li	a0,0
    80005aaa:	ffffd097          	auipc	ra,0xffffd
    80005aae:	11a080e7          	jalr	282(ra) # 80002bc4 <argstr>
    return -1;
    80005ab2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ab4:	0c054b63          	bltz	a0,80005b8a <sys_exec+0xfc>
    80005ab8:	e3840593          	addi	a1,s0,-456
    80005abc:	4505                	li	a0,1
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	0e4080e7          	jalr	228(ra) # 80002ba2 <argaddr>
    80005ac6:	0c054263          	bltz	a0,80005b8a <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005aca:	10000613          	li	a2,256
    80005ace:	4581                	li	a1,0
    80005ad0:	e4040513          	addi	a0,s0,-448
    80005ad4:	ffffb097          	auipc	ra,0xffffb
    80005ad8:	1f8080e7          	jalr	504(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005adc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ae0:	89a6                	mv	s3,s1
    80005ae2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ae4:	02000a13          	li	s4,32
    80005ae8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aec:	00391513          	slli	a0,s2,0x3
    80005af0:	e3040593          	addi	a1,s0,-464
    80005af4:	e3843783          	ld	a5,-456(s0)
    80005af8:	953e                	add	a0,a0,a5
    80005afa:	ffffd097          	auipc	ra,0xffffd
    80005afe:	fec080e7          	jalr	-20(ra) # 80002ae6 <fetchaddr>
    80005b02:	02054a63          	bltz	a0,80005b36 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b06:	e3043783          	ld	a5,-464(s0)
    80005b0a:	c3b9                	beqz	a5,80005b50 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b0c:	ffffb097          	auipc	ra,0xffffb
    80005b10:	fd4080e7          	jalr	-44(ra) # 80000ae0 <kalloc>
    80005b14:	85aa                	mv	a1,a0
    80005b16:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b1a:	cd11                	beqz	a0,80005b36 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b1c:	6605                	lui	a2,0x1
    80005b1e:	e3043503          	ld	a0,-464(s0)
    80005b22:	ffffd097          	auipc	ra,0xffffd
    80005b26:	016080e7          	jalr	22(ra) # 80002b38 <fetchstr>
    80005b2a:	00054663          	bltz	a0,80005b36 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b2e:	0905                	addi	s2,s2,1
    80005b30:	09a1                	addi	s3,s3,8
    80005b32:	fb491be3          	bne	s2,s4,80005ae8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b36:	f4040913          	addi	s2,s0,-192
    80005b3a:	6088                	ld	a0,0(s1)
    80005b3c:	c531                	beqz	a0,80005b88 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b3e:	ffffb097          	auipc	ra,0xffffb
    80005b42:	ea4080e7          	jalr	-348(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b46:	04a1                	addi	s1,s1,8
    80005b48:	ff2499e3          	bne	s1,s2,80005b3a <sys_exec+0xac>
  return -1;
    80005b4c:	597d                	li	s2,-1
    80005b4e:	a835                	j	80005b8a <sys_exec+0xfc>
      argv[i] = 0;
    80005b50:	0a8e                	slli	s5,s5,0x3
    80005b52:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005b56:	00878ab3          	add	s5,a5,s0
    80005b5a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b5e:	e4040593          	addi	a1,s0,-448
    80005b62:	f4040513          	addi	a0,s0,-192
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	172080e7          	jalr	370(ra) # 80004cd8 <exec>
    80005b6e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b70:	f4040993          	addi	s3,s0,-192
    80005b74:	6088                	ld	a0,0(s1)
    80005b76:	c911                	beqz	a0,80005b8a <sys_exec+0xfc>
    kfree(argv[i]);
    80005b78:	ffffb097          	auipc	ra,0xffffb
    80005b7c:	e6a080e7          	jalr	-406(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b80:	04a1                	addi	s1,s1,8
    80005b82:	ff3499e3          	bne	s1,s3,80005b74 <sys_exec+0xe6>
    80005b86:	a011                	j	80005b8a <sys_exec+0xfc>
  return -1;
    80005b88:	597d                	li	s2,-1
}
    80005b8a:	854a                	mv	a0,s2
    80005b8c:	60be                	ld	ra,456(sp)
    80005b8e:	641e                	ld	s0,448(sp)
    80005b90:	74fa                	ld	s1,440(sp)
    80005b92:	795a                	ld	s2,432(sp)
    80005b94:	79ba                	ld	s3,424(sp)
    80005b96:	7a1a                	ld	s4,416(sp)
    80005b98:	6afa                	ld	s5,408(sp)
    80005b9a:	6179                	addi	sp,sp,464
    80005b9c:	8082                	ret

0000000080005b9e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b9e:	7139                	addi	sp,sp,-64
    80005ba0:	fc06                	sd	ra,56(sp)
    80005ba2:	f822                	sd	s0,48(sp)
    80005ba4:	f426                	sd	s1,40(sp)
    80005ba6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ba8:	ffffc097          	auipc	ra,0xffffc
    80005bac:	dee080e7          	jalr	-530(ra) # 80001996 <myproc>
    80005bb0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bb2:	fd840593          	addi	a1,s0,-40
    80005bb6:	4501                	li	a0,0
    80005bb8:	ffffd097          	auipc	ra,0xffffd
    80005bbc:	fea080e7          	jalr	-22(ra) # 80002ba2 <argaddr>
    return -1;
    80005bc0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bc2:	0e054063          	bltz	a0,80005ca2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bc6:	fc840593          	addi	a1,s0,-56
    80005bca:	fd040513          	addi	a0,s0,-48
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	de6080e7          	jalr	-538(ra) # 800049b4 <pipealloc>
    return -1;
    80005bd6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bd8:	0c054563          	bltz	a0,80005ca2 <sys_pipe+0x104>
  fd0 = -1;
    80005bdc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005be0:	fd043503          	ld	a0,-48(s0)
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	504080e7          	jalr	1284(ra) # 800050e8 <fdalloc>
    80005bec:	fca42223          	sw	a0,-60(s0)
    80005bf0:	08054c63          	bltz	a0,80005c88 <sys_pipe+0xea>
    80005bf4:	fc843503          	ld	a0,-56(s0)
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	4f0080e7          	jalr	1264(ra) # 800050e8 <fdalloc>
    80005c00:	fca42023          	sw	a0,-64(s0)
    80005c04:	06054963          	bltz	a0,80005c76 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c08:	4691                	li	a3,4
    80005c0a:	fc440613          	addi	a2,s0,-60
    80005c0e:	fd843583          	ld	a1,-40(s0)
    80005c12:	68a8                	ld	a0,80(s1)
    80005c14:	ffffc097          	auipc	ra,0xffffc
    80005c18:	a46080e7          	jalr	-1466(ra) # 8000165a <copyout>
    80005c1c:	02054063          	bltz	a0,80005c3c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c20:	4691                	li	a3,4
    80005c22:	fc040613          	addi	a2,s0,-64
    80005c26:	fd843583          	ld	a1,-40(s0)
    80005c2a:	0591                	addi	a1,a1,4
    80005c2c:	68a8                	ld	a0,80(s1)
    80005c2e:	ffffc097          	auipc	ra,0xffffc
    80005c32:	a2c080e7          	jalr	-1492(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c36:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c38:	06055563          	bgez	a0,80005ca2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c3c:	fc442783          	lw	a5,-60(s0)
    80005c40:	07e9                	addi	a5,a5,26
    80005c42:	078e                	slli	a5,a5,0x3
    80005c44:	97a6                	add	a5,a5,s1
    80005c46:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c4a:	fc042783          	lw	a5,-64(s0)
    80005c4e:	07e9                	addi	a5,a5,26
    80005c50:	078e                	slli	a5,a5,0x3
    80005c52:	00f48533          	add	a0,s1,a5
    80005c56:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c5a:	fd043503          	ld	a0,-48(s0)
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	a26080e7          	jalr	-1498(ra) # 80004684 <fileclose>
    fileclose(wf);
    80005c66:	fc843503          	ld	a0,-56(s0)
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	a1a080e7          	jalr	-1510(ra) # 80004684 <fileclose>
    return -1;
    80005c72:	57fd                	li	a5,-1
    80005c74:	a03d                	j	80005ca2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c76:	fc442783          	lw	a5,-60(s0)
    80005c7a:	0007c763          	bltz	a5,80005c88 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c7e:	07e9                	addi	a5,a5,26
    80005c80:	078e                	slli	a5,a5,0x3
    80005c82:	97a6                	add	a5,a5,s1
    80005c84:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c88:	fd043503          	ld	a0,-48(s0)
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	9f8080e7          	jalr	-1544(ra) # 80004684 <fileclose>
    fileclose(wf);
    80005c94:	fc843503          	ld	a0,-56(s0)
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	9ec080e7          	jalr	-1556(ra) # 80004684 <fileclose>
    return -1;
    80005ca0:	57fd                	li	a5,-1
}
    80005ca2:	853e                	mv	a0,a5
    80005ca4:	70e2                	ld	ra,56(sp)
    80005ca6:	7442                	ld	s0,48(sp)
    80005ca8:	74a2                	ld	s1,40(sp)
    80005caa:	6121                	addi	sp,sp,64
    80005cac:	8082                	ret
	...

0000000080005cb0 <kernelvec>:
    80005cb0:	7111                	addi	sp,sp,-256
    80005cb2:	e006                	sd	ra,0(sp)
    80005cb4:	e40a                	sd	sp,8(sp)
    80005cb6:	e80e                	sd	gp,16(sp)
    80005cb8:	ec12                	sd	tp,24(sp)
    80005cba:	f016                	sd	t0,32(sp)
    80005cbc:	f41a                	sd	t1,40(sp)
    80005cbe:	f81e                	sd	t2,48(sp)
    80005cc0:	fc22                	sd	s0,56(sp)
    80005cc2:	e0a6                	sd	s1,64(sp)
    80005cc4:	e4aa                	sd	a0,72(sp)
    80005cc6:	e8ae                	sd	a1,80(sp)
    80005cc8:	ecb2                	sd	a2,88(sp)
    80005cca:	f0b6                	sd	a3,96(sp)
    80005ccc:	f4ba                	sd	a4,104(sp)
    80005cce:	f8be                	sd	a5,112(sp)
    80005cd0:	fcc2                	sd	a6,120(sp)
    80005cd2:	e146                	sd	a7,128(sp)
    80005cd4:	e54a                	sd	s2,136(sp)
    80005cd6:	e94e                	sd	s3,144(sp)
    80005cd8:	ed52                	sd	s4,152(sp)
    80005cda:	f156                	sd	s5,160(sp)
    80005cdc:	f55a                	sd	s6,168(sp)
    80005cde:	f95e                	sd	s7,176(sp)
    80005ce0:	fd62                	sd	s8,184(sp)
    80005ce2:	e1e6                	sd	s9,192(sp)
    80005ce4:	e5ea                	sd	s10,200(sp)
    80005ce6:	e9ee                	sd	s11,208(sp)
    80005ce8:	edf2                	sd	t3,216(sp)
    80005cea:	f1f6                	sd	t4,224(sp)
    80005cec:	f5fa                	sd	t5,232(sp)
    80005cee:	f9fe                	sd	t6,240(sp)
    80005cf0:	cc3fc0ef          	jal	ra,800029b2 <kerneltrap>
    80005cf4:	6082                	ld	ra,0(sp)
    80005cf6:	6122                	ld	sp,8(sp)
    80005cf8:	61c2                	ld	gp,16(sp)
    80005cfa:	7282                	ld	t0,32(sp)
    80005cfc:	7322                	ld	t1,40(sp)
    80005cfe:	73c2                	ld	t2,48(sp)
    80005d00:	7462                	ld	s0,56(sp)
    80005d02:	6486                	ld	s1,64(sp)
    80005d04:	6526                	ld	a0,72(sp)
    80005d06:	65c6                	ld	a1,80(sp)
    80005d08:	6666                	ld	a2,88(sp)
    80005d0a:	7686                	ld	a3,96(sp)
    80005d0c:	7726                	ld	a4,104(sp)
    80005d0e:	77c6                	ld	a5,112(sp)
    80005d10:	7866                	ld	a6,120(sp)
    80005d12:	688a                	ld	a7,128(sp)
    80005d14:	692a                	ld	s2,136(sp)
    80005d16:	69ca                	ld	s3,144(sp)
    80005d18:	6a6a                	ld	s4,152(sp)
    80005d1a:	7a8a                	ld	s5,160(sp)
    80005d1c:	7b2a                	ld	s6,168(sp)
    80005d1e:	7bca                	ld	s7,176(sp)
    80005d20:	7c6a                	ld	s8,184(sp)
    80005d22:	6c8e                	ld	s9,192(sp)
    80005d24:	6d2e                	ld	s10,200(sp)
    80005d26:	6dce                	ld	s11,208(sp)
    80005d28:	6e6e                	ld	t3,216(sp)
    80005d2a:	7e8e                	ld	t4,224(sp)
    80005d2c:	7f2e                	ld	t5,232(sp)
    80005d2e:	7fce                	ld	t6,240(sp)
    80005d30:	6111                	addi	sp,sp,256
    80005d32:	10200073          	sret
    80005d36:	00000013          	nop
    80005d3a:	00000013          	nop
    80005d3e:	0001                	nop

0000000080005d40 <timervec>:
    80005d40:	34051573          	csrrw	a0,mscratch,a0
    80005d44:	e10c                	sd	a1,0(a0)
    80005d46:	e510                	sd	a2,8(a0)
    80005d48:	e914                	sd	a3,16(a0)
    80005d4a:	6d0c                	ld	a1,24(a0)
    80005d4c:	7110                	ld	a2,32(a0)
    80005d4e:	6194                	ld	a3,0(a1)
    80005d50:	96b2                	add	a3,a3,a2
    80005d52:	e194                	sd	a3,0(a1)
    80005d54:	4589                	li	a1,2
    80005d56:	14459073          	csrw	sip,a1
    80005d5a:	6914                	ld	a3,16(a0)
    80005d5c:	6510                	ld	a2,8(a0)
    80005d5e:	610c                	ld	a1,0(a0)
    80005d60:	34051573          	csrrw	a0,mscratch,a0
    80005d64:	30200073          	mret
	...

0000000080005d6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d6a:	1141                	addi	sp,sp,-16
    80005d6c:	e422                	sd	s0,8(sp)
    80005d6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d70:	0c0007b7          	lui	a5,0xc000
    80005d74:	4705                	li	a4,1
    80005d76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d78:	c3d8                	sw	a4,4(a5)
}
    80005d7a:	6422                	ld	s0,8(sp)
    80005d7c:	0141                	addi	sp,sp,16
    80005d7e:	8082                	ret

0000000080005d80 <plicinithart>:

void
plicinithart(void)
{
    80005d80:	1141                	addi	sp,sp,-16
    80005d82:	e406                	sd	ra,8(sp)
    80005d84:	e022                	sd	s0,0(sp)
    80005d86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d88:	ffffc097          	auipc	ra,0xffffc
    80005d8c:	be2080e7          	jalr	-1054(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d90:	0085171b          	slliw	a4,a0,0x8
    80005d94:	0c0027b7          	lui	a5,0xc002
    80005d98:	97ba                	add	a5,a5,a4
    80005d9a:	40200713          	li	a4,1026
    80005d9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005da2:	00d5151b          	slliw	a0,a0,0xd
    80005da6:	0c2017b7          	lui	a5,0xc201
    80005daa:	97aa                	add	a5,a5,a0
    80005dac:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005db0:	60a2                	ld	ra,8(sp)
    80005db2:	6402                	ld	s0,0(sp)
    80005db4:	0141                	addi	sp,sp,16
    80005db6:	8082                	ret

0000000080005db8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005db8:	1141                	addi	sp,sp,-16
    80005dba:	e406                	sd	ra,8(sp)
    80005dbc:	e022                	sd	s0,0(sp)
    80005dbe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dc0:	ffffc097          	auipc	ra,0xffffc
    80005dc4:	baa080e7          	jalr	-1110(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005dc8:	00d5151b          	slliw	a0,a0,0xd
    80005dcc:	0c2017b7          	lui	a5,0xc201
    80005dd0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005dd2:	43c8                	lw	a0,4(a5)
    80005dd4:	60a2                	ld	ra,8(sp)
    80005dd6:	6402                	ld	s0,0(sp)
    80005dd8:	0141                	addi	sp,sp,16
    80005dda:	8082                	ret

0000000080005ddc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ddc:	1101                	addi	sp,sp,-32
    80005dde:	ec06                	sd	ra,24(sp)
    80005de0:	e822                	sd	s0,16(sp)
    80005de2:	e426                	sd	s1,8(sp)
    80005de4:	1000                	addi	s0,sp,32
    80005de6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	b82080e7          	jalr	-1150(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005df0:	00d5151b          	slliw	a0,a0,0xd
    80005df4:	0c2017b7          	lui	a5,0xc201
    80005df8:	97aa                	add	a5,a5,a0
    80005dfa:	c3c4                	sw	s1,4(a5)
}
    80005dfc:	60e2                	ld	ra,24(sp)
    80005dfe:	6442                	ld	s0,16(sp)
    80005e00:	64a2                	ld	s1,8(sp)
    80005e02:	6105                	addi	sp,sp,32
    80005e04:	8082                	ret

0000000080005e06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e06:	1141                	addi	sp,sp,-16
    80005e08:	e406                	sd	ra,8(sp)
    80005e0a:	e022                	sd	s0,0(sp)
    80005e0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e0e:	479d                	li	a5,7
    80005e10:	06a7c863          	blt	a5,a0,80005e80 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005e14:	0001d717          	auipc	a4,0x1d
    80005e18:	1ec70713          	addi	a4,a4,492 # 80023000 <disk>
    80005e1c:	972a                	add	a4,a4,a0
    80005e1e:	6789                	lui	a5,0x2
    80005e20:	97ba                	add	a5,a5,a4
    80005e22:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e26:	e7ad                	bnez	a5,80005e90 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e28:	00451793          	slli	a5,a0,0x4
    80005e2c:	0001f717          	auipc	a4,0x1f
    80005e30:	1d470713          	addi	a4,a4,468 # 80025000 <disk+0x2000>
    80005e34:	6314                	ld	a3,0(a4)
    80005e36:	96be                	add	a3,a3,a5
    80005e38:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e3c:	6314                	ld	a3,0(a4)
    80005e3e:	96be                	add	a3,a3,a5
    80005e40:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e44:	6314                	ld	a3,0(a4)
    80005e46:	96be                	add	a3,a3,a5
    80005e48:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e4c:	6318                	ld	a4,0(a4)
    80005e4e:	97ba                	add	a5,a5,a4
    80005e50:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e54:	0001d717          	auipc	a4,0x1d
    80005e58:	1ac70713          	addi	a4,a4,428 # 80023000 <disk>
    80005e5c:	972a                	add	a4,a4,a0
    80005e5e:	6789                	lui	a5,0x2
    80005e60:	97ba                	add	a5,a5,a4
    80005e62:	4705                	li	a4,1
    80005e64:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e68:	0001f517          	auipc	a0,0x1f
    80005e6c:	1b050513          	addi	a0,a0,432 # 80025018 <disk+0x2018>
    80005e70:	ffffc097          	auipc	ra,0xffffc
    80005e74:	376080e7          	jalr	886(ra) # 800021e6 <wakeup>
}
    80005e78:	60a2                	ld	ra,8(sp)
    80005e7a:	6402                	ld	s0,0(sp)
    80005e7c:	0141                	addi	sp,sp,16
    80005e7e:	8082                	ret
    panic("free_desc 1");
    80005e80:	00003517          	auipc	a0,0x3
    80005e84:	90850513          	addi	a0,a0,-1784 # 80008788 <syscalls+0x340>
    80005e88:	ffffa097          	auipc	ra,0xffffa
    80005e8c:	6b2080e7          	jalr	1714(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005e90:	00003517          	auipc	a0,0x3
    80005e94:	90850513          	addi	a0,a0,-1784 # 80008798 <syscalls+0x350>
    80005e98:	ffffa097          	auipc	ra,0xffffa
    80005e9c:	6a2080e7          	jalr	1698(ra) # 8000053a <panic>

0000000080005ea0 <virtio_disk_init>:
{
    80005ea0:	1101                	addi	sp,sp,-32
    80005ea2:	ec06                	sd	ra,24(sp)
    80005ea4:	e822                	sd	s0,16(sp)
    80005ea6:	e426                	sd	s1,8(sp)
    80005ea8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005eaa:	00003597          	auipc	a1,0x3
    80005eae:	8fe58593          	addi	a1,a1,-1794 # 800087a8 <syscalls+0x360>
    80005eb2:	0001f517          	auipc	a0,0x1f
    80005eb6:	27650513          	addi	a0,a0,630 # 80025128 <disk+0x2128>
    80005eba:	ffffb097          	auipc	ra,0xffffb
    80005ebe:	c86080e7          	jalr	-890(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ec2:	100017b7          	lui	a5,0x10001
    80005ec6:	4398                	lw	a4,0(a5)
    80005ec8:	2701                	sext.w	a4,a4
    80005eca:	747277b7          	lui	a5,0x74727
    80005ece:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ed2:	0ef71063          	bne	a4,a5,80005fb2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ed6:	100017b7          	lui	a5,0x10001
    80005eda:	43dc                	lw	a5,4(a5)
    80005edc:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ede:	4705                	li	a4,1
    80005ee0:	0ce79963          	bne	a5,a4,80005fb2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ee4:	100017b7          	lui	a5,0x10001
    80005ee8:	479c                	lw	a5,8(a5)
    80005eea:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005eec:	4709                	li	a4,2
    80005eee:	0ce79263          	bne	a5,a4,80005fb2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ef2:	100017b7          	lui	a5,0x10001
    80005ef6:	47d8                	lw	a4,12(a5)
    80005ef8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005efa:	554d47b7          	lui	a5,0x554d4
    80005efe:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f02:	0af71863          	bne	a4,a5,80005fb2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f06:	100017b7          	lui	a5,0x10001
    80005f0a:	4705                	li	a4,1
    80005f0c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f0e:	470d                	li	a4,3
    80005f10:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f12:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f14:	c7ffe6b7          	lui	a3,0xc7ffe
    80005f18:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f1c:	8f75                	and	a4,a4,a3
    80005f1e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f20:	472d                	li	a4,11
    80005f22:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f24:	473d                	li	a4,15
    80005f26:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f28:	6705                	lui	a4,0x1
    80005f2a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f2c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f30:	5bdc                	lw	a5,52(a5)
    80005f32:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f34:	c7d9                	beqz	a5,80005fc2 <virtio_disk_init+0x122>
  if(max < NUM)
    80005f36:	471d                	li	a4,7
    80005f38:	08f77d63          	bgeu	a4,a5,80005fd2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f3c:	100014b7          	lui	s1,0x10001
    80005f40:	47a1                	li	a5,8
    80005f42:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f44:	6609                	lui	a2,0x2
    80005f46:	4581                	li	a1,0
    80005f48:	0001d517          	auipc	a0,0x1d
    80005f4c:	0b850513          	addi	a0,a0,184 # 80023000 <disk>
    80005f50:	ffffb097          	auipc	ra,0xffffb
    80005f54:	d7c080e7          	jalr	-644(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f58:	0001d717          	auipc	a4,0x1d
    80005f5c:	0a870713          	addi	a4,a4,168 # 80023000 <disk>
    80005f60:	00c75793          	srli	a5,a4,0xc
    80005f64:	2781                	sext.w	a5,a5
    80005f66:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f68:	0001f797          	auipc	a5,0x1f
    80005f6c:	09878793          	addi	a5,a5,152 # 80025000 <disk+0x2000>
    80005f70:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f72:	0001d717          	auipc	a4,0x1d
    80005f76:	10e70713          	addi	a4,a4,270 # 80023080 <disk+0x80>
    80005f7a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f7c:	0001e717          	auipc	a4,0x1e
    80005f80:	08470713          	addi	a4,a4,132 # 80024000 <disk+0x1000>
    80005f84:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f86:	4705                	li	a4,1
    80005f88:	00e78c23          	sb	a4,24(a5)
    80005f8c:	00e78ca3          	sb	a4,25(a5)
    80005f90:	00e78d23          	sb	a4,26(a5)
    80005f94:	00e78da3          	sb	a4,27(a5)
    80005f98:	00e78e23          	sb	a4,28(a5)
    80005f9c:	00e78ea3          	sb	a4,29(a5)
    80005fa0:	00e78f23          	sb	a4,30(a5)
    80005fa4:	00e78fa3          	sb	a4,31(a5)
}
    80005fa8:	60e2                	ld	ra,24(sp)
    80005faa:	6442                	ld	s0,16(sp)
    80005fac:	64a2                	ld	s1,8(sp)
    80005fae:	6105                	addi	sp,sp,32
    80005fb0:	8082                	ret
    panic("could not find virtio disk");
    80005fb2:	00003517          	auipc	a0,0x3
    80005fb6:	80650513          	addi	a0,a0,-2042 # 800087b8 <syscalls+0x370>
    80005fba:	ffffa097          	auipc	ra,0xffffa
    80005fbe:	580080e7          	jalr	1408(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005fc2:	00003517          	auipc	a0,0x3
    80005fc6:	81650513          	addi	a0,a0,-2026 # 800087d8 <syscalls+0x390>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	570080e7          	jalr	1392(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005fd2:	00003517          	auipc	a0,0x3
    80005fd6:	82650513          	addi	a0,a0,-2010 # 800087f8 <syscalls+0x3b0>
    80005fda:	ffffa097          	auipc	ra,0xffffa
    80005fde:	560080e7          	jalr	1376(ra) # 8000053a <panic>

0000000080005fe2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fe2:	7119                	addi	sp,sp,-128
    80005fe4:	fc86                	sd	ra,120(sp)
    80005fe6:	f8a2                	sd	s0,112(sp)
    80005fe8:	f4a6                	sd	s1,104(sp)
    80005fea:	f0ca                	sd	s2,96(sp)
    80005fec:	ecce                	sd	s3,88(sp)
    80005fee:	e8d2                	sd	s4,80(sp)
    80005ff0:	e4d6                	sd	s5,72(sp)
    80005ff2:	e0da                	sd	s6,64(sp)
    80005ff4:	fc5e                	sd	s7,56(sp)
    80005ff6:	f862                	sd	s8,48(sp)
    80005ff8:	f466                	sd	s9,40(sp)
    80005ffa:	f06a                	sd	s10,32(sp)
    80005ffc:	ec6e                	sd	s11,24(sp)
    80005ffe:	0100                	addi	s0,sp,128
    80006000:	8aaa                	mv	s5,a0
    80006002:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006004:	00c52c83          	lw	s9,12(a0)
    80006008:	001c9c9b          	slliw	s9,s9,0x1
    8000600c:	1c82                	slli	s9,s9,0x20
    8000600e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006012:	0001f517          	auipc	a0,0x1f
    80006016:	11650513          	addi	a0,a0,278 # 80025128 <disk+0x2128>
    8000601a:	ffffb097          	auipc	ra,0xffffb
    8000601e:	bb6080e7          	jalr	-1098(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80006022:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006024:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006026:	0001dc17          	auipc	s8,0x1d
    8000602a:	fdac0c13          	addi	s8,s8,-38 # 80023000 <disk>
    8000602e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006030:	4b0d                	li	s6,3
    80006032:	a0ad                	j	8000609c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006034:	00fc0733          	add	a4,s8,a5
    80006038:	975e                	add	a4,a4,s7
    8000603a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000603e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006040:	0207c563          	bltz	a5,8000606a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006044:	2905                	addiw	s2,s2,1
    80006046:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006048:	19690c63          	beq	s2,s6,800061e0 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000604c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000604e:	0001f717          	auipc	a4,0x1f
    80006052:	fca70713          	addi	a4,a4,-54 # 80025018 <disk+0x2018>
    80006056:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006058:	00074683          	lbu	a3,0(a4)
    8000605c:	fee1                	bnez	a3,80006034 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000605e:	2785                	addiw	a5,a5,1
    80006060:	0705                	addi	a4,a4,1
    80006062:	fe979be3          	bne	a5,s1,80006058 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006066:	57fd                	li	a5,-1
    80006068:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000606a:	01205d63          	blez	s2,80006084 <virtio_disk_rw+0xa2>
    8000606e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006070:	000a2503          	lw	a0,0(s4)
    80006074:	00000097          	auipc	ra,0x0
    80006078:	d92080e7          	jalr	-622(ra) # 80005e06 <free_desc>
      for(int j = 0; j < i; j++)
    8000607c:	2d85                	addiw	s11,s11,1
    8000607e:	0a11                	addi	s4,s4,4
    80006080:	ff2d98e3          	bne	s11,s2,80006070 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006084:	0001f597          	auipc	a1,0x1f
    80006088:	0a458593          	addi	a1,a1,164 # 80025128 <disk+0x2128>
    8000608c:	0001f517          	auipc	a0,0x1f
    80006090:	f8c50513          	addi	a0,a0,-116 # 80025018 <disk+0x2018>
    80006094:	ffffc097          	auipc	ra,0xffffc
    80006098:	fc6080e7          	jalr	-58(ra) # 8000205a <sleep>
  for(int i = 0; i < 3; i++){
    8000609c:	f8040a13          	addi	s4,s0,-128
{
    800060a0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800060a2:	894e                	mv	s2,s3
    800060a4:	b765                	j	8000604c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060a6:	0001f697          	auipc	a3,0x1f
    800060aa:	f5a6b683          	ld	a3,-166(a3) # 80025000 <disk+0x2000>
    800060ae:	96ba                	add	a3,a3,a4
    800060b0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060b4:	0001d817          	auipc	a6,0x1d
    800060b8:	f4c80813          	addi	a6,a6,-180 # 80023000 <disk>
    800060bc:	0001f697          	auipc	a3,0x1f
    800060c0:	f4468693          	addi	a3,a3,-188 # 80025000 <disk+0x2000>
    800060c4:	6290                	ld	a2,0(a3)
    800060c6:	963a                	add	a2,a2,a4
    800060c8:	00c65583          	lhu	a1,12(a2)
    800060cc:	0015e593          	ori	a1,a1,1
    800060d0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800060d4:	f8842603          	lw	a2,-120(s0)
    800060d8:	628c                	ld	a1,0(a3)
    800060da:	972e                	add	a4,a4,a1
    800060dc:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060e0:	20050593          	addi	a1,a0,512
    800060e4:	0592                	slli	a1,a1,0x4
    800060e6:	95c2                	add	a1,a1,a6
    800060e8:	577d                	li	a4,-1
    800060ea:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060ee:	00461713          	slli	a4,a2,0x4
    800060f2:	6290                	ld	a2,0(a3)
    800060f4:	963a                	add	a2,a2,a4
    800060f6:	03078793          	addi	a5,a5,48
    800060fa:	97c2                	add	a5,a5,a6
    800060fc:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800060fe:	629c                	ld	a5,0(a3)
    80006100:	97ba                	add	a5,a5,a4
    80006102:	4605                	li	a2,1
    80006104:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006106:	629c                	ld	a5,0(a3)
    80006108:	97ba                	add	a5,a5,a4
    8000610a:	4809                	li	a6,2
    8000610c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006110:	629c                	ld	a5,0(a3)
    80006112:	97ba                	add	a5,a5,a4
    80006114:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006118:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000611c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006120:	6698                	ld	a4,8(a3)
    80006122:	00275783          	lhu	a5,2(a4)
    80006126:	8b9d                	andi	a5,a5,7
    80006128:	0786                	slli	a5,a5,0x1
    8000612a:	973e                	add	a4,a4,a5
    8000612c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006130:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006134:	6698                	ld	a4,8(a3)
    80006136:	00275783          	lhu	a5,2(a4)
    8000613a:	2785                	addiw	a5,a5,1
    8000613c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006140:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006144:	100017b7          	lui	a5,0x10001
    80006148:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000614c:	004aa783          	lw	a5,4(s5)
    80006150:	02c79163          	bne	a5,a2,80006172 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006154:	0001f917          	auipc	s2,0x1f
    80006158:	fd490913          	addi	s2,s2,-44 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000615c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000615e:	85ca                	mv	a1,s2
    80006160:	8556                	mv	a0,s5
    80006162:	ffffc097          	auipc	ra,0xffffc
    80006166:	ef8080e7          	jalr	-264(ra) # 8000205a <sleep>
  while(b->disk == 1) {
    8000616a:	004aa783          	lw	a5,4(s5)
    8000616e:	fe9788e3          	beq	a5,s1,8000615e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006172:	f8042903          	lw	s2,-128(s0)
    80006176:	20090713          	addi	a4,s2,512
    8000617a:	0712                	slli	a4,a4,0x4
    8000617c:	0001d797          	auipc	a5,0x1d
    80006180:	e8478793          	addi	a5,a5,-380 # 80023000 <disk>
    80006184:	97ba                	add	a5,a5,a4
    80006186:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000618a:	0001f997          	auipc	s3,0x1f
    8000618e:	e7698993          	addi	s3,s3,-394 # 80025000 <disk+0x2000>
    80006192:	00491713          	slli	a4,s2,0x4
    80006196:	0009b783          	ld	a5,0(s3)
    8000619a:	97ba                	add	a5,a5,a4
    8000619c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061a0:	854a                	mv	a0,s2
    800061a2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061a6:	00000097          	auipc	ra,0x0
    800061aa:	c60080e7          	jalr	-928(ra) # 80005e06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061ae:	8885                	andi	s1,s1,1
    800061b0:	f0ed                	bnez	s1,80006192 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061b2:	0001f517          	auipc	a0,0x1f
    800061b6:	f7650513          	addi	a0,a0,-138 # 80025128 <disk+0x2128>
    800061ba:	ffffb097          	auipc	ra,0xffffb
    800061be:	aca080e7          	jalr	-1334(ra) # 80000c84 <release>
}
    800061c2:	70e6                	ld	ra,120(sp)
    800061c4:	7446                	ld	s0,112(sp)
    800061c6:	74a6                	ld	s1,104(sp)
    800061c8:	7906                	ld	s2,96(sp)
    800061ca:	69e6                	ld	s3,88(sp)
    800061cc:	6a46                	ld	s4,80(sp)
    800061ce:	6aa6                	ld	s5,72(sp)
    800061d0:	6b06                	ld	s6,64(sp)
    800061d2:	7be2                	ld	s7,56(sp)
    800061d4:	7c42                	ld	s8,48(sp)
    800061d6:	7ca2                	ld	s9,40(sp)
    800061d8:	7d02                	ld	s10,32(sp)
    800061da:	6de2                	ld	s11,24(sp)
    800061dc:	6109                	addi	sp,sp,128
    800061de:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061e0:	f8042503          	lw	a0,-128(s0)
    800061e4:	20050793          	addi	a5,a0,512
    800061e8:	0792                	slli	a5,a5,0x4
  if(write)
    800061ea:	0001d817          	auipc	a6,0x1d
    800061ee:	e1680813          	addi	a6,a6,-490 # 80023000 <disk>
    800061f2:	00f80733          	add	a4,a6,a5
    800061f6:	01a036b3          	snez	a3,s10
    800061fa:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800061fe:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006202:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006206:	7679                	lui	a2,0xffffe
    80006208:	963e                	add	a2,a2,a5
    8000620a:	0001f697          	auipc	a3,0x1f
    8000620e:	df668693          	addi	a3,a3,-522 # 80025000 <disk+0x2000>
    80006212:	6298                	ld	a4,0(a3)
    80006214:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006216:	0a878593          	addi	a1,a5,168
    8000621a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000621c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000621e:	6298                	ld	a4,0(a3)
    80006220:	9732                	add	a4,a4,a2
    80006222:	45c1                	li	a1,16
    80006224:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006226:	6298                	ld	a4,0(a3)
    80006228:	9732                	add	a4,a4,a2
    8000622a:	4585                	li	a1,1
    8000622c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006230:	f8442703          	lw	a4,-124(s0)
    80006234:	628c                	ld	a1,0(a3)
    80006236:	962e                	add	a2,a2,a1
    80006238:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000623c:	0712                	slli	a4,a4,0x4
    8000623e:	6290                	ld	a2,0(a3)
    80006240:	963a                	add	a2,a2,a4
    80006242:	058a8593          	addi	a1,s5,88
    80006246:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006248:	6294                	ld	a3,0(a3)
    8000624a:	96ba                	add	a3,a3,a4
    8000624c:	40000613          	li	a2,1024
    80006250:	c690                	sw	a2,8(a3)
  if(write)
    80006252:	e40d1ae3          	bnez	s10,800060a6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006256:	0001f697          	auipc	a3,0x1f
    8000625a:	daa6b683          	ld	a3,-598(a3) # 80025000 <disk+0x2000>
    8000625e:	96ba                	add	a3,a3,a4
    80006260:	4609                	li	a2,2
    80006262:	00c69623          	sh	a2,12(a3)
    80006266:	b5b9                	j	800060b4 <virtio_disk_rw+0xd2>

0000000080006268 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006268:	1101                	addi	sp,sp,-32
    8000626a:	ec06                	sd	ra,24(sp)
    8000626c:	e822                	sd	s0,16(sp)
    8000626e:	e426                	sd	s1,8(sp)
    80006270:	e04a                	sd	s2,0(sp)
    80006272:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006274:	0001f517          	auipc	a0,0x1f
    80006278:	eb450513          	addi	a0,a0,-332 # 80025128 <disk+0x2128>
    8000627c:	ffffb097          	auipc	ra,0xffffb
    80006280:	954080e7          	jalr	-1708(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006284:	10001737          	lui	a4,0x10001
    80006288:	533c                	lw	a5,96(a4)
    8000628a:	8b8d                	andi	a5,a5,3
    8000628c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000628e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006292:	0001f797          	auipc	a5,0x1f
    80006296:	d6e78793          	addi	a5,a5,-658 # 80025000 <disk+0x2000>
    8000629a:	6b94                	ld	a3,16(a5)
    8000629c:	0207d703          	lhu	a4,32(a5)
    800062a0:	0026d783          	lhu	a5,2(a3)
    800062a4:	06f70163          	beq	a4,a5,80006306 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062a8:	0001d917          	auipc	s2,0x1d
    800062ac:	d5890913          	addi	s2,s2,-680 # 80023000 <disk>
    800062b0:	0001f497          	auipc	s1,0x1f
    800062b4:	d5048493          	addi	s1,s1,-688 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800062b8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062bc:	6898                	ld	a4,16(s1)
    800062be:	0204d783          	lhu	a5,32(s1)
    800062c2:	8b9d                	andi	a5,a5,7
    800062c4:	078e                	slli	a5,a5,0x3
    800062c6:	97ba                	add	a5,a5,a4
    800062c8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062ca:	20078713          	addi	a4,a5,512
    800062ce:	0712                	slli	a4,a4,0x4
    800062d0:	974a                	add	a4,a4,s2
    800062d2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800062d6:	e731                	bnez	a4,80006322 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062d8:	20078793          	addi	a5,a5,512
    800062dc:	0792                	slli	a5,a5,0x4
    800062de:	97ca                	add	a5,a5,s2
    800062e0:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800062e2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062e6:	ffffc097          	auipc	ra,0xffffc
    800062ea:	f00080e7          	jalr	-256(ra) # 800021e6 <wakeup>

    disk.used_idx += 1;
    800062ee:	0204d783          	lhu	a5,32(s1)
    800062f2:	2785                	addiw	a5,a5,1
    800062f4:	17c2                	slli	a5,a5,0x30
    800062f6:	93c1                	srli	a5,a5,0x30
    800062f8:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062fc:	6898                	ld	a4,16(s1)
    800062fe:	00275703          	lhu	a4,2(a4)
    80006302:	faf71be3          	bne	a4,a5,800062b8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006306:	0001f517          	auipc	a0,0x1f
    8000630a:	e2250513          	addi	a0,a0,-478 # 80025128 <disk+0x2128>
    8000630e:	ffffb097          	auipc	ra,0xffffb
    80006312:	976080e7          	jalr	-1674(ra) # 80000c84 <release>
}
    80006316:	60e2                	ld	ra,24(sp)
    80006318:	6442                	ld	s0,16(sp)
    8000631a:	64a2                	ld	s1,8(sp)
    8000631c:	6902                	ld	s2,0(sp)
    8000631e:	6105                	addi	sp,sp,32
    80006320:	8082                	ret
      panic("virtio_disk_intr status");
    80006322:	00002517          	auipc	a0,0x2
    80006326:	4f650513          	addi	a0,a0,1270 # 80008818 <syscalls+0x3d0>
    8000632a:	ffffa097          	auipc	ra,0xffffa
    8000632e:	210080e7          	jalr	528(ra) # 8000053a <panic>
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
