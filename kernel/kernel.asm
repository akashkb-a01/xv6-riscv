
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
    80000066:	b4e78793          	addi	a5,a5,-1202 # 80005bb0 <timervec>
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
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	734080e7          	jalr	1844(ra) # 800025ec <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	d30080e7          	jalr	-720(ra) # 80005bf0 <plicinithart>
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
    80000f34:	694080e7          	jalr	1684(ra) # 800025c4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	6b4080e7          	jalr	1716(ra) # 800025ec <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	c9a080e7          	jalr	-870(ra) # 80005bda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	ca8080e7          	jalr	-856(ra) # 80005bf0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	e6c080e7          	jalr	-404(ra) # 80002dbc <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	4fa080e7          	jalr	1274(ra) # 80003452 <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	4ac080e7          	jalr	1196(ra) # 8000440c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	da8080e7          	jalr	-600(ra) # 80005d10 <virtio_disk_init>
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
    800019f4:	c14080e7          	jalr	-1004(ra) # 80002604 <usertrapret>
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
    80001a0e:	9c8080e7          	jalr	-1592(ra) # 800033d2 <fsinit>
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
    80001cd0:	13c080e7          	jalr	316(ra) # 80003e08 <namei>
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
    80001e18:	00002097          	auipc	ra,0x2
    80001e1c:	686080e7          	jalr	1670(ra) # 8000449e <filedup>
    80001e20:	00a93023          	sd	a0,0(s2)
    80001e24:	b7e5                	j	80001e0c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e26:	150ab503          	ld	a0,336(s5)
    80001e2a:	00001097          	auipc	ra,0x1
    80001e2e:	7e4080e7          	jalr	2020(ra) # 8000360e <idup>
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
    80001f3e:	620080e7          	jalr	1568(ra) # 8000255a <swtch>
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
    80001fc0:	59e080e7          	jalr	1438(ra) # 8000255a <swtch>
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
    800022fa:	1fa080e7          	jalr	506(ra) # 800044f0 <fileclose>
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
    80002312:	d1a080e7          	jalr	-742(ra) # 80004028 <begin_op>
  iput(p->cwd);
    80002316:	1509b503          	ld	a0,336(s3)
    8000231a:	00001097          	auipc	ra,0x1
    8000231e:	4ec080e7          	jalr	1260(ra) # 80003806 <iput>
  end_op();
    80002322:	00002097          	auipc	ra,0x2
    80002326:	d84080e7          	jalr	-636(ra) # 800040a6 <end_op>
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

000000008000255a <swtch>:
    8000255a:	00153023          	sd	ra,0(a0)
    8000255e:	00253423          	sd	sp,8(a0)
    80002562:	e900                	sd	s0,16(a0)
    80002564:	ed04                	sd	s1,24(a0)
    80002566:	03253023          	sd	s2,32(a0)
    8000256a:	03353423          	sd	s3,40(a0)
    8000256e:	03453823          	sd	s4,48(a0)
    80002572:	03553c23          	sd	s5,56(a0)
    80002576:	05653023          	sd	s6,64(a0)
    8000257a:	05753423          	sd	s7,72(a0)
    8000257e:	05853823          	sd	s8,80(a0)
    80002582:	05953c23          	sd	s9,88(a0)
    80002586:	07a53023          	sd	s10,96(a0)
    8000258a:	07b53423          	sd	s11,104(a0)
    8000258e:	0005b083          	ld	ra,0(a1)
    80002592:	0085b103          	ld	sp,8(a1)
    80002596:	6980                	ld	s0,16(a1)
    80002598:	6d84                	ld	s1,24(a1)
    8000259a:	0205b903          	ld	s2,32(a1)
    8000259e:	0285b983          	ld	s3,40(a1)
    800025a2:	0305ba03          	ld	s4,48(a1)
    800025a6:	0385ba83          	ld	s5,56(a1)
    800025aa:	0405bb03          	ld	s6,64(a1)
    800025ae:	0485bb83          	ld	s7,72(a1)
    800025b2:	0505bc03          	ld	s8,80(a1)
    800025b6:	0585bc83          	ld	s9,88(a1)
    800025ba:	0605bd03          	ld	s10,96(a1)
    800025be:	0685bd83          	ld	s11,104(a1)
    800025c2:	8082                	ret

00000000800025c4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025c4:	1141                	addi	sp,sp,-16
    800025c6:	e406                	sd	ra,8(sp)
    800025c8:	e022                	sd	s0,0(sp)
    800025ca:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025cc:	00006597          	auipc	a1,0x6
    800025d0:	d2458593          	addi	a1,a1,-732 # 800082f0 <states.0+0x30>
    800025d4:	00015517          	auipc	a0,0x15
    800025d8:	afc50513          	addi	a0,a0,-1284 # 800170d0 <tickslock>
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	564080e7          	jalr	1380(ra) # 80000b40 <initlock>
}
    800025e4:	60a2                	ld	ra,8(sp)
    800025e6:	6402                	ld	s0,0(sp)
    800025e8:	0141                	addi	sp,sp,16
    800025ea:	8082                	ret

00000000800025ec <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025ec:	1141                	addi	sp,sp,-16
    800025ee:	e422                	sd	s0,8(sp)
    800025f0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025f2:	00003797          	auipc	a5,0x3
    800025f6:	52e78793          	addi	a5,a5,1326 # 80005b20 <kernelvec>
    800025fa:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800025fe:	6422                	ld	s0,8(sp)
    80002600:	0141                	addi	sp,sp,16
    80002602:	8082                	ret

0000000080002604 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002604:	1141                	addi	sp,sp,-16
    80002606:	e406                	sd	ra,8(sp)
    80002608:	e022                	sd	s0,0(sp)
    8000260a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000260c:	fffff097          	auipc	ra,0xfffff
    80002610:	38a080e7          	jalr	906(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002614:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002618:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000261a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000261e:	00005697          	auipc	a3,0x5
    80002622:	9e268693          	addi	a3,a3,-1566 # 80007000 <_trampoline>
    80002626:	00005717          	auipc	a4,0x5
    8000262a:	9da70713          	addi	a4,a4,-1574 # 80007000 <_trampoline>
    8000262e:	8f15                	sub	a4,a4,a3
    80002630:	040007b7          	lui	a5,0x4000
    80002634:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002636:	07b2                	slli	a5,a5,0xc
    80002638:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000263a:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000263e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002640:	18002673          	csrr	a2,satp
    80002644:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002646:	6d30                	ld	a2,88(a0)
    80002648:	6138                	ld	a4,64(a0)
    8000264a:	6585                	lui	a1,0x1
    8000264c:	972e                	add	a4,a4,a1
    8000264e:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002650:	6d38                	ld	a4,88(a0)
    80002652:	00000617          	auipc	a2,0x0
    80002656:	13860613          	addi	a2,a2,312 # 8000278a <usertrap>
    8000265a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000265c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000265e:	8612                	mv	a2,tp
    80002660:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002662:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002666:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000266a:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000266e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002672:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002674:	6f18                	ld	a4,24(a4)
    80002676:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000267a:	692c                	ld	a1,80(a0)
    8000267c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000267e:	00005717          	auipc	a4,0x5
    80002682:	a1270713          	addi	a4,a4,-1518 # 80007090 <userret>
    80002686:	8f15                	sub	a4,a4,a3
    80002688:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000268a:	577d                	li	a4,-1
    8000268c:	177e                	slli	a4,a4,0x3f
    8000268e:	8dd9                	or	a1,a1,a4
    80002690:	02000537          	lui	a0,0x2000
    80002694:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002696:	0536                	slli	a0,a0,0xd
    80002698:	9782                	jalr	a5
}
    8000269a:	60a2                	ld	ra,8(sp)
    8000269c:	6402                	ld	s0,0(sp)
    8000269e:	0141                	addi	sp,sp,16
    800026a0:	8082                	ret

00000000800026a2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026a2:	1101                	addi	sp,sp,-32
    800026a4:	ec06                	sd	ra,24(sp)
    800026a6:	e822                	sd	s0,16(sp)
    800026a8:	e426                	sd	s1,8(sp)
    800026aa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026ac:	00015497          	auipc	s1,0x15
    800026b0:	a2448493          	addi	s1,s1,-1500 # 800170d0 <tickslock>
    800026b4:	8526                	mv	a0,s1
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	51a080e7          	jalr	1306(ra) # 80000bd0 <acquire>
  ticks++;
    800026be:	00007517          	auipc	a0,0x7
    800026c2:	97250513          	addi	a0,a0,-1678 # 80009030 <ticks>
    800026c6:	411c                	lw	a5,0(a0)
    800026c8:	2785                	addiw	a5,a5,1
    800026ca:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026cc:	00000097          	auipc	ra,0x0
    800026d0:	b1a080e7          	jalr	-1254(ra) # 800021e6 <wakeup>
  release(&tickslock);
    800026d4:	8526                	mv	a0,s1
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	5ae080e7          	jalr	1454(ra) # 80000c84 <release>
}
    800026de:	60e2                	ld	ra,24(sp)
    800026e0:	6442                	ld	s0,16(sp)
    800026e2:	64a2                	ld	s1,8(sp)
    800026e4:	6105                	addi	sp,sp,32
    800026e6:	8082                	ret

00000000800026e8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026e8:	1101                	addi	sp,sp,-32
    800026ea:	ec06                	sd	ra,24(sp)
    800026ec:	e822                	sd	s0,16(sp)
    800026ee:	e426                	sd	s1,8(sp)
    800026f0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026f2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800026f6:	00074d63          	bltz	a4,80002710 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800026fa:	57fd                	li	a5,-1
    800026fc:	17fe                	slli	a5,a5,0x3f
    800026fe:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002700:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002702:	06f70363          	beq	a4,a5,80002768 <devintr+0x80>
  }
}
    80002706:	60e2                	ld	ra,24(sp)
    80002708:	6442                	ld	s0,16(sp)
    8000270a:	64a2                	ld	s1,8(sp)
    8000270c:	6105                	addi	sp,sp,32
    8000270e:	8082                	ret
     (scause & 0xff) == 9){
    80002710:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002714:	46a5                	li	a3,9
    80002716:	fed792e3          	bne	a5,a3,800026fa <devintr+0x12>
    int irq = plic_claim();
    8000271a:	00003097          	auipc	ra,0x3
    8000271e:	50e080e7          	jalr	1294(ra) # 80005c28 <plic_claim>
    80002722:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002724:	47a9                	li	a5,10
    80002726:	02f50763          	beq	a0,a5,80002754 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000272a:	4785                	li	a5,1
    8000272c:	02f50963          	beq	a0,a5,8000275e <devintr+0x76>
    return 1;
    80002730:	4505                	li	a0,1
    } else if(irq){
    80002732:	d8f1                	beqz	s1,80002706 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002734:	85a6                	mv	a1,s1
    80002736:	00006517          	auipc	a0,0x6
    8000273a:	bc250513          	addi	a0,a0,-1086 # 800082f8 <states.0+0x38>
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	e46080e7          	jalr	-442(ra) # 80000584 <printf>
      plic_complete(irq);
    80002746:	8526                	mv	a0,s1
    80002748:	00003097          	auipc	ra,0x3
    8000274c:	504080e7          	jalr	1284(ra) # 80005c4c <plic_complete>
    return 1;
    80002750:	4505                	li	a0,1
    80002752:	bf55                	j	80002706 <devintr+0x1e>
      uartintr();
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	23e080e7          	jalr	574(ra) # 80000992 <uartintr>
    8000275c:	b7ed                	j	80002746 <devintr+0x5e>
      virtio_disk_intr();
    8000275e:	00004097          	auipc	ra,0x4
    80002762:	97a080e7          	jalr	-1670(ra) # 800060d8 <virtio_disk_intr>
    80002766:	b7c5                	j	80002746 <devintr+0x5e>
    if(cpuid() == 0){
    80002768:	fffff097          	auipc	ra,0xfffff
    8000276c:	202080e7          	jalr	514(ra) # 8000196a <cpuid>
    80002770:	c901                	beqz	a0,80002780 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002772:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002776:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002778:	14479073          	csrw	sip,a5
    return 2;
    8000277c:	4509                	li	a0,2
    8000277e:	b761                	j	80002706 <devintr+0x1e>
      clockintr();
    80002780:	00000097          	auipc	ra,0x0
    80002784:	f22080e7          	jalr	-222(ra) # 800026a2 <clockintr>
    80002788:	b7ed                	j	80002772 <devintr+0x8a>

000000008000278a <usertrap>:
{
    8000278a:	1101                	addi	sp,sp,-32
    8000278c:	ec06                	sd	ra,24(sp)
    8000278e:	e822                	sd	s0,16(sp)
    80002790:	e426                	sd	s1,8(sp)
    80002792:	e04a                	sd	s2,0(sp)
    80002794:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002796:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000279a:	1007f793          	andi	a5,a5,256
    8000279e:	e3ad                	bnez	a5,80002800 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a0:	00003797          	auipc	a5,0x3
    800027a4:	38078793          	addi	a5,a5,896 # 80005b20 <kernelvec>
    800027a8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027ac:	fffff097          	auipc	ra,0xfffff
    800027b0:	1ea080e7          	jalr	490(ra) # 80001996 <myproc>
    800027b4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027b6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027b8:	14102773          	csrr	a4,sepc
    800027bc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027be:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027c2:	47a1                	li	a5,8
    800027c4:	04f71c63          	bne	a4,a5,8000281c <usertrap+0x92>
    if(p->killed)
    800027c8:	551c                	lw	a5,40(a0)
    800027ca:	e3b9                	bnez	a5,80002810 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027cc:	6cb8                	ld	a4,88(s1)
    800027ce:	6f1c                	ld	a5,24(a4)
    800027d0:	0791                	addi	a5,a5,4
    800027d2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027d8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027dc:	10079073          	csrw	sstatus,a5
    syscall();
    800027e0:	00000097          	auipc	ra,0x0
    800027e4:	2e0080e7          	jalr	736(ra) # 80002ac0 <syscall>
  if(p->killed)
    800027e8:	549c                	lw	a5,40(s1)
    800027ea:	ebc1                	bnez	a5,8000287a <usertrap+0xf0>
  usertrapret();
    800027ec:	00000097          	auipc	ra,0x0
    800027f0:	e18080e7          	jalr	-488(ra) # 80002604 <usertrapret>
}
    800027f4:	60e2                	ld	ra,24(sp)
    800027f6:	6442                	ld	s0,16(sp)
    800027f8:	64a2                	ld	s1,8(sp)
    800027fa:	6902                	ld	s2,0(sp)
    800027fc:	6105                	addi	sp,sp,32
    800027fe:	8082                	ret
    panic("usertrap: not from user mode");
    80002800:	00006517          	auipc	a0,0x6
    80002804:	b1850513          	addi	a0,a0,-1256 # 80008318 <states.0+0x58>
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	d32080e7          	jalr	-718(ra) # 8000053a <panic>
      exit(-1);
    80002810:	557d                	li	a0,-1
    80002812:	00000097          	auipc	ra,0x0
    80002816:	aa4080e7          	jalr	-1372(ra) # 800022b6 <exit>
    8000281a:	bf4d                	j	800027cc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000281c:	00000097          	auipc	ra,0x0
    80002820:	ecc080e7          	jalr	-308(ra) # 800026e8 <devintr>
    80002824:	892a                	mv	s2,a0
    80002826:	c501                	beqz	a0,8000282e <usertrap+0xa4>
  if(p->killed)
    80002828:	549c                	lw	a5,40(s1)
    8000282a:	c3a1                	beqz	a5,8000286a <usertrap+0xe0>
    8000282c:	a815                	j	80002860 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000282e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002832:	5890                	lw	a2,48(s1)
    80002834:	00006517          	auipc	a0,0x6
    80002838:	b0450513          	addi	a0,a0,-1276 # 80008338 <states.0+0x78>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	d48080e7          	jalr	-696(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002844:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002848:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000284c:	00006517          	auipc	a0,0x6
    80002850:	b1c50513          	addi	a0,a0,-1252 # 80008368 <states.0+0xa8>
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	d30080e7          	jalr	-720(ra) # 80000584 <printf>
    p->killed = 1;
    8000285c:	4785                	li	a5,1
    8000285e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002860:	557d                	li	a0,-1
    80002862:	00000097          	auipc	ra,0x0
    80002866:	a54080e7          	jalr	-1452(ra) # 800022b6 <exit>
  if(which_dev == 2)
    8000286a:	4789                	li	a5,2
    8000286c:	f8f910e3          	bne	s2,a5,800027ec <usertrap+0x62>
    yield();
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	7ae080e7          	jalr	1966(ra) # 8000201e <yield>
    80002878:	bf95                	j	800027ec <usertrap+0x62>
  int which_dev = 0;
    8000287a:	4901                	li	s2,0
    8000287c:	b7d5                	j	80002860 <usertrap+0xd6>

000000008000287e <kerneltrap>:
{
    8000287e:	7179                	addi	sp,sp,-48
    80002880:	f406                	sd	ra,40(sp)
    80002882:	f022                	sd	s0,32(sp)
    80002884:	ec26                	sd	s1,24(sp)
    80002886:	e84a                	sd	s2,16(sp)
    80002888:	e44e                	sd	s3,8(sp)
    8000288a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000288c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002890:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002894:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002898:	1004f793          	andi	a5,s1,256
    8000289c:	cb85                	beqz	a5,800028cc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028a2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028a4:	ef85                	bnez	a5,800028dc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028a6:	00000097          	auipc	ra,0x0
    800028aa:	e42080e7          	jalr	-446(ra) # 800026e8 <devintr>
    800028ae:	cd1d                	beqz	a0,800028ec <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028b0:	4789                	li	a5,2
    800028b2:	06f50a63          	beq	a0,a5,80002926 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028b6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ba:	10049073          	csrw	sstatus,s1
}
    800028be:	70a2                	ld	ra,40(sp)
    800028c0:	7402                	ld	s0,32(sp)
    800028c2:	64e2                	ld	s1,24(sp)
    800028c4:	6942                	ld	s2,16(sp)
    800028c6:	69a2                	ld	s3,8(sp)
    800028c8:	6145                	addi	sp,sp,48
    800028ca:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028cc:	00006517          	auipc	a0,0x6
    800028d0:	abc50513          	addi	a0,a0,-1348 # 80008388 <states.0+0xc8>
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	c66080e7          	jalr	-922(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	ad450513          	addi	a0,a0,-1324 # 800083b0 <states.0+0xf0>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	c56080e7          	jalr	-938(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    800028ec:	85ce                	mv	a1,s3
    800028ee:	00006517          	auipc	a0,0x6
    800028f2:	ae250513          	addi	a0,a0,-1310 # 800083d0 <states.0+0x110>
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	c8e080e7          	jalr	-882(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002902:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002906:	00006517          	auipc	a0,0x6
    8000290a:	ada50513          	addi	a0,a0,-1318 # 800083e0 <states.0+0x120>
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	c76080e7          	jalr	-906(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	ae250513          	addi	a0,a0,-1310 # 800083f8 <states.0+0x138>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c1c080e7          	jalr	-996(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002926:	fffff097          	auipc	ra,0xfffff
    8000292a:	070080e7          	jalr	112(ra) # 80001996 <myproc>
    8000292e:	d541                	beqz	a0,800028b6 <kerneltrap+0x38>
    80002930:	fffff097          	auipc	ra,0xfffff
    80002934:	066080e7          	jalr	102(ra) # 80001996 <myproc>
    80002938:	4d18                	lw	a4,24(a0)
    8000293a:	4791                	li	a5,4
    8000293c:	f6f71de3          	bne	a4,a5,800028b6 <kerneltrap+0x38>
    yield();
    80002940:	fffff097          	auipc	ra,0xfffff
    80002944:	6de080e7          	jalr	1758(ra) # 8000201e <yield>
    80002948:	b7bd                	j	800028b6 <kerneltrap+0x38>

000000008000294a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000294a:	1101                	addi	sp,sp,-32
    8000294c:	ec06                	sd	ra,24(sp)
    8000294e:	e822                	sd	s0,16(sp)
    80002950:	e426                	sd	s1,8(sp)
    80002952:	1000                	addi	s0,sp,32
    80002954:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002956:	fffff097          	auipc	ra,0xfffff
    8000295a:	040080e7          	jalr	64(ra) # 80001996 <myproc>
  switch (n) {
    8000295e:	4795                	li	a5,5
    80002960:	0497e163          	bltu	a5,s1,800029a2 <argraw+0x58>
    80002964:	048a                	slli	s1,s1,0x2
    80002966:	00006717          	auipc	a4,0x6
    8000296a:	aca70713          	addi	a4,a4,-1334 # 80008430 <states.0+0x170>
    8000296e:	94ba                	add	s1,s1,a4
    80002970:	409c                	lw	a5,0(s1)
    80002972:	97ba                	add	a5,a5,a4
    80002974:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002976:	6d3c                	ld	a5,88(a0)
    80002978:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000297a:	60e2                	ld	ra,24(sp)
    8000297c:	6442                	ld	s0,16(sp)
    8000297e:	64a2                	ld	s1,8(sp)
    80002980:	6105                	addi	sp,sp,32
    80002982:	8082                	ret
    return p->trapframe->a1;
    80002984:	6d3c                	ld	a5,88(a0)
    80002986:	7fa8                	ld	a0,120(a5)
    80002988:	bfcd                	j	8000297a <argraw+0x30>
    return p->trapframe->a2;
    8000298a:	6d3c                	ld	a5,88(a0)
    8000298c:	63c8                	ld	a0,128(a5)
    8000298e:	b7f5                	j	8000297a <argraw+0x30>
    return p->trapframe->a3;
    80002990:	6d3c                	ld	a5,88(a0)
    80002992:	67c8                	ld	a0,136(a5)
    80002994:	b7dd                	j	8000297a <argraw+0x30>
    return p->trapframe->a4;
    80002996:	6d3c                	ld	a5,88(a0)
    80002998:	6bc8                	ld	a0,144(a5)
    8000299a:	b7c5                	j	8000297a <argraw+0x30>
    return p->trapframe->a5;
    8000299c:	6d3c                	ld	a5,88(a0)
    8000299e:	6fc8                	ld	a0,152(a5)
    800029a0:	bfe9                	j	8000297a <argraw+0x30>
  panic("argraw");
    800029a2:	00006517          	auipc	a0,0x6
    800029a6:	a6650513          	addi	a0,a0,-1434 # 80008408 <states.0+0x148>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	b90080e7          	jalr	-1136(ra) # 8000053a <panic>

00000000800029b2 <fetchaddr>:
{
    800029b2:	1101                	addi	sp,sp,-32
    800029b4:	ec06                	sd	ra,24(sp)
    800029b6:	e822                	sd	s0,16(sp)
    800029b8:	e426                	sd	s1,8(sp)
    800029ba:	e04a                	sd	s2,0(sp)
    800029bc:	1000                	addi	s0,sp,32
    800029be:	84aa                	mv	s1,a0
    800029c0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	fd4080e7          	jalr	-44(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029ca:	653c                	ld	a5,72(a0)
    800029cc:	02f4f863          	bgeu	s1,a5,800029fc <fetchaddr+0x4a>
    800029d0:	00848713          	addi	a4,s1,8
    800029d4:	02e7e663          	bltu	a5,a4,80002a00 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029d8:	46a1                	li	a3,8
    800029da:	8626                	mv	a2,s1
    800029dc:	85ca                	mv	a1,s2
    800029de:	6928                	ld	a0,80(a0)
    800029e0:	fffff097          	auipc	ra,0xfffff
    800029e4:	d06080e7          	jalr	-762(ra) # 800016e6 <copyin>
    800029e8:	00a03533          	snez	a0,a0
    800029ec:	40a00533          	neg	a0,a0
}
    800029f0:	60e2                	ld	ra,24(sp)
    800029f2:	6442                	ld	s0,16(sp)
    800029f4:	64a2                	ld	s1,8(sp)
    800029f6:	6902                	ld	s2,0(sp)
    800029f8:	6105                	addi	sp,sp,32
    800029fa:	8082                	ret
    return -1;
    800029fc:	557d                	li	a0,-1
    800029fe:	bfcd                	j	800029f0 <fetchaddr+0x3e>
    80002a00:	557d                	li	a0,-1
    80002a02:	b7fd                	j	800029f0 <fetchaddr+0x3e>

0000000080002a04 <fetchstr>:
{
    80002a04:	7179                	addi	sp,sp,-48
    80002a06:	f406                	sd	ra,40(sp)
    80002a08:	f022                	sd	s0,32(sp)
    80002a0a:	ec26                	sd	s1,24(sp)
    80002a0c:	e84a                	sd	s2,16(sp)
    80002a0e:	e44e                	sd	s3,8(sp)
    80002a10:	1800                	addi	s0,sp,48
    80002a12:	892a                	mv	s2,a0
    80002a14:	84ae                	mv	s1,a1
    80002a16:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	f7e080e7          	jalr	-130(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a20:	86ce                	mv	a3,s3
    80002a22:	864a                	mv	a2,s2
    80002a24:	85a6                	mv	a1,s1
    80002a26:	6928                	ld	a0,80(a0)
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	d4c080e7          	jalr	-692(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002a30:	00054763          	bltz	a0,80002a3e <fetchstr+0x3a>
  return strlen(buf);
    80002a34:	8526                	mv	a0,s1
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	412080e7          	jalr	1042(ra) # 80000e48 <strlen>
}
    80002a3e:	70a2                	ld	ra,40(sp)
    80002a40:	7402                	ld	s0,32(sp)
    80002a42:	64e2                	ld	s1,24(sp)
    80002a44:	6942                	ld	s2,16(sp)
    80002a46:	69a2                	ld	s3,8(sp)
    80002a48:	6145                	addi	sp,sp,48
    80002a4a:	8082                	ret

0000000080002a4c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a4c:	1101                	addi	sp,sp,-32
    80002a4e:	ec06                	sd	ra,24(sp)
    80002a50:	e822                	sd	s0,16(sp)
    80002a52:	e426                	sd	s1,8(sp)
    80002a54:	1000                	addi	s0,sp,32
    80002a56:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a58:	00000097          	auipc	ra,0x0
    80002a5c:	ef2080e7          	jalr	-270(ra) # 8000294a <argraw>
    80002a60:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a62:	4501                	li	a0,0
    80002a64:	60e2                	ld	ra,24(sp)
    80002a66:	6442                	ld	s0,16(sp)
    80002a68:	64a2                	ld	s1,8(sp)
    80002a6a:	6105                	addi	sp,sp,32
    80002a6c:	8082                	ret

0000000080002a6e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a6e:	1101                	addi	sp,sp,-32
    80002a70:	ec06                	sd	ra,24(sp)
    80002a72:	e822                	sd	s0,16(sp)
    80002a74:	e426                	sd	s1,8(sp)
    80002a76:	1000                	addi	s0,sp,32
    80002a78:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a7a:	00000097          	auipc	ra,0x0
    80002a7e:	ed0080e7          	jalr	-304(ra) # 8000294a <argraw>
    80002a82:	e088                	sd	a0,0(s1)
  return 0;
}
    80002a84:	4501                	li	a0,0
    80002a86:	60e2                	ld	ra,24(sp)
    80002a88:	6442                	ld	s0,16(sp)
    80002a8a:	64a2                	ld	s1,8(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret

0000000080002a90 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002a90:	1101                	addi	sp,sp,-32
    80002a92:	ec06                	sd	ra,24(sp)
    80002a94:	e822                	sd	s0,16(sp)
    80002a96:	e426                	sd	s1,8(sp)
    80002a98:	e04a                	sd	s2,0(sp)
    80002a9a:	1000                	addi	s0,sp,32
    80002a9c:	84ae                	mv	s1,a1
    80002a9e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002aa0:	00000097          	auipc	ra,0x0
    80002aa4:	eaa080e7          	jalr	-342(ra) # 8000294a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002aa8:	864a                	mv	a2,s2
    80002aaa:	85a6                	mv	a1,s1
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	f58080e7          	jalr	-168(ra) # 80002a04 <fetchstr>
}
    80002ab4:	60e2                	ld	ra,24(sp)
    80002ab6:	6442                	ld	s0,16(sp)
    80002ab8:	64a2                	ld	s1,8(sp)
    80002aba:	6902                	ld	s2,0(sp)
    80002abc:	6105                	addi	sp,sp,32
    80002abe:	8082                	ret

0000000080002ac0 <syscall>:
[SYS_getpa]   sys_getpa,
};

void
syscall(void)
{
    80002ac0:	1101                	addi	sp,sp,-32
    80002ac2:	ec06                	sd	ra,24(sp)
    80002ac4:	e822                	sd	s0,16(sp)
    80002ac6:	e426                	sd	s1,8(sp)
    80002ac8:	e04a                	sd	s2,0(sp)
    80002aca:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002acc:	fffff097          	auipc	ra,0xfffff
    80002ad0:	eca080e7          	jalr	-310(ra) # 80001996 <myproc>
    80002ad4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ad6:	05853903          	ld	s2,88(a0)
    80002ada:	0a893783          	ld	a5,168(s2)
    80002ade:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ae2:	37fd                	addiw	a5,a5,-1
    80002ae4:	475d                	li	a4,23
    80002ae6:	00f76f63          	bltu	a4,a5,80002b04 <syscall+0x44>
    80002aea:	00369713          	slli	a4,a3,0x3
    80002aee:	00006797          	auipc	a5,0x6
    80002af2:	95a78793          	addi	a5,a5,-1702 # 80008448 <syscalls>
    80002af6:	97ba                	add	a5,a5,a4
    80002af8:	639c                	ld	a5,0(a5)
    80002afa:	c789                	beqz	a5,80002b04 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002afc:	9782                	jalr	a5
    80002afe:	06a93823          	sd	a0,112(s2)
    80002b02:	a839                	j	80002b20 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b04:	15848613          	addi	a2,s1,344
    80002b08:	588c                	lw	a1,48(s1)
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	90650513          	addi	a0,a0,-1786 # 80008410 <states.0+0x150>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a72080e7          	jalr	-1422(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b1a:	6cbc                	ld	a5,88(s1)
    80002b1c:	577d                	li	a4,-1
    80002b1e:	fbb8                	sd	a4,112(a5)
  }
}
    80002b20:	60e2                	ld	ra,24(sp)
    80002b22:	6442                	ld	s0,16(sp)
    80002b24:	64a2                	ld	s1,8(sp)
    80002b26:	6902                	ld	s2,0(sp)
    80002b28:	6105                	addi	sp,sp,32
    80002b2a:	8082                	ret

0000000080002b2c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b2c:	1101                	addi	sp,sp,-32
    80002b2e:	ec06                	sd	ra,24(sp)
    80002b30:	e822                	sd	s0,16(sp)
    80002b32:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b34:	fec40593          	addi	a1,s0,-20
    80002b38:	4501                	li	a0,0
    80002b3a:	00000097          	auipc	ra,0x0
    80002b3e:	f12080e7          	jalr	-238(ra) # 80002a4c <argint>
    return -1;
    80002b42:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b44:	00054963          	bltz	a0,80002b56 <sys_exit+0x2a>
  exit(n);
    80002b48:	fec42503          	lw	a0,-20(s0)
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	76a080e7          	jalr	1898(ra) # 800022b6 <exit>
  return 0;  // not reached
    80002b54:	4781                	li	a5,0
}
    80002b56:	853e                	mv	a0,a5
    80002b58:	60e2                	ld	ra,24(sp)
    80002b5a:	6442                	ld	s0,16(sp)
    80002b5c:	6105                	addi	sp,sp,32
    80002b5e:	8082                	ret

0000000080002b60 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b60:	1141                	addi	sp,sp,-16
    80002b62:	e406                	sd	ra,8(sp)
    80002b64:	e022                	sd	s0,0(sp)
    80002b66:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	e2e080e7          	jalr	-466(ra) # 80001996 <myproc>
}
    80002b70:	5908                	lw	a0,48(a0)
    80002b72:	60a2                	ld	ra,8(sp)
    80002b74:	6402                	ld	s0,0(sp)
    80002b76:	0141                	addi	sp,sp,16
    80002b78:	8082                	ret

0000000080002b7a <sys_fork>:

uint64
sys_fork(void)
{
    80002b7a:	1141                	addi	sp,sp,-16
    80002b7c:	e406                	sd	ra,8(sp)
    80002b7e:	e022                	sd	s0,0(sp)
    80002b80:	0800                	addi	s0,sp,16
  return fork();
    80002b82:	fffff097          	auipc	ra,0xfffff
    80002b86:	1e6080e7          	jalr	486(ra) # 80001d68 <fork>
}
    80002b8a:	60a2                	ld	ra,8(sp)
    80002b8c:	6402                	ld	s0,0(sp)
    80002b8e:	0141                	addi	sp,sp,16
    80002b90:	8082                	ret

0000000080002b92 <sys_wait>:

uint64
sys_wait(void)
{
    80002b92:	1101                	addi	sp,sp,-32
    80002b94:	ec06                	sd	ra,24(sp)
    80002b96:	e822                	sd	s0,16(sp)
    80002b98:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002b9a:	fe840593          	addi	a1,s0,-24
    80002b9e:	4501                	li	a0,0
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	ece080e7          	jalr	-306(ra) # 80002a6e <argaddr>
    80002ba8:	87aa                	mv	a5,a0
    return -1;
    80002baa:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bac:	0007c863          	bltz	a5,80002bbc <sys_wait+0x2a>
  return wait(p);
    80002bb0:	fe843503          	ld	a0,-24(s0)
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	50a080e7          	jalr	1290(ra) # 800020be <wait>
}
    80002bbc:	60e2                	ld	ra,24(sp)
    80002bbe:	6442                	ld	s0,16(sp)
    80002bc0:	6105                	addi	sp,sp,32
    80002bc2:	8082                	ret

0000000080002bc4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002bc4:	7179                	addi	sp,sp,-48
    80002bc6:	f406                	sd	ra,40(sp)
    80002bc8:	f022                	sd	s0,32(sp)
    80002bca:	ec26                	sd	s1,24(sp)
    80002bcc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002bce:	fdc40593          	addi	a1,s0,-36
    80002bd2:	4501                	li	a0,0
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	e78080e7          	jalr	-392(ra) # 80002a4c <argint>
    80002bdc:	87aa                	mv	a5,a0
    return -1;
    80002bde:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002be0:	0207c063          	bltz	a5,80002c00 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	db2080e7          	jalr	-590(ra) # 80001996 <myproc>
    80002bec:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002bee:	fdc42503          	lw	a0,-36(s0)
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	0fe080e7          	jalr	254(ra) # 80001cf0 <growproc>
    80002bfa:	00054863          	bltz	a0,80002c0a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002bfe:	8526                	mv	a0,s1
}
    80002c00:	70a2                	ld	ra,40(sp)
    80002c02:	7402                	ld	s0,32(sp)
    80002c04:	64e2                	ld	s1,24(sp)
    80002c06:	6145                	addi	sp,sp,48
    80002c08:	8082                	ret
    return -1;
    80002c0a:	557d                	li	a0,-1
    80002c0c:	bfd5                	j	80002c00 <sys_sbrk+0x3c>

0000000080002c0e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c0e:	7139                	addi	sp,sp,-64
    80002c10:	fc06                	sd	ra,56(sp)
    80002c12:	f822                	sd	s0,48(sp)
    80002c14:	f426                	sd	s1,40(sp)
    80002c16:	f04a                	sd	s2,32(sp)
    80002c18:	ec4e                	sd	s3,24(sp)
    80002c1a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c1c:	fcc40593          	addi	a1,s0,-52
    80002c20:	4501                	li	a0,0
    80002c22:	00000097          	auipc	ra,0x0
    80002c26:	e2a080e7          	jalr	-470(ra) # 80002a4c <argint>
    return -1;
    80002c2a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c2c:	06054563          	bltz	a0,80002c96 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c30:	00014517          	auipc	a0,0x14
    80002c34:	4a050513          	addi	a0,a0,1184 # 800170d0 <tickslock>
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	f98080e7          	jalr	-104(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002c40:	00006917          	auipc	s2,0x6
    80002c44:	3f092903          	lw	s2,1008(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c48:	fcc42783          	lw	a5,-52(s0)
    80002c4c:	cf85                	beqz	a5,80002c84 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c4e:	00014997          	auipc	s3,0x14
    80002c52:	48298993          	addi	s3,s3,1154 # 800170d0 <tickslock>
    80002c56:	00006497          	auipc	s1,0x6
    80002c5a:	3da48493          	addi	s1,s1,986 # 80009030 <ticks>
    if(myproc()->killed){
    80002c5e:	fffff097          	auipc	ra,0xfffff
    80002c62:	d38080e7          	jalr	-712(ra) # 80001996 <myproc>
    80002c66:	551c                	lw	a5,40(a0)
    80002c68:	ef9d                	bnez	a5,80002ca6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c6a:	85ce                	mv	a1,s3
    80002c6c:	8526                	mv	a0,s1
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	3ec080e7          	jalr	1004(ra) # 8000205a <sleep>
  while(ticks - ticks0 < n){
    80002c76:	409c                	lw	a5,0(s1)
    80002c78:	412787bb          	subw	a5,a5,s2
    80002c7c:	fcc42703          	lw	a4,-52(s0)
    80002c80:	fce7efe3          	bltu	a5,a4,80002c5e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002c84:	00014517          	auipc	a0,0x14
    80002c88:	44c50513          	addi	a0,a0,1100 # 800170d0 <tickslock>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	ff8080e7          	jalr	-8(ra) # 80000c84 <release>
  return 0;
    80002c94:	4781                	li	a5,0
}
    80002c96:	853e                	mv	a0,a5
    80002c98:	70e2                	ld	ra,56(sp)
    80002c9a:	7442                	ld	s0,48(sp)
    80002c9c:	74a2                	ld	s1,40(sp)
    80002c9e:	7902                	ld	s2,32(sp)
    80002ca0:	69e2                	ld	s3,24(sp)
    80002ca2:	6121                	addi	sp,sp,64
    80002ca4:	8082                	ret
      release(&tickslock);
    80002ca6:	00014517          	auipc	a0,0x14
    80002caa:	42a50513          	addi	a0,a0,1066 # 800170d0 <tickslock>
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	fd6080e7          	jalr	-42(ra) # 80000c84 <release>
      return -1;
    80002cb6:	57fd                	li	a5,-1
    80002cb8:	bff9                	j	80002c96 <sys_sleep+0x88>

0000000080002cba <sys_kill>:

uint64
sys_kill(void)
{
    80002cba:	1101                	addi	sp,sp,-32
    80002cbc:	ec06                	sd	ra,24(sp)
    80002cbe:	e822                	sd	s0,16(sp)
    80002cc0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002cc2:	fec40593          	addi	a1,s0,-20
    80002cc6:	4501                	li	a0,0
    80002cc8:	00000097          	auipc	ra,0x0
    80002ccc:	d84080e7          	jalr	-636(ra) # 80002a4c <argint>
    80002cd0:	87aa                	mv	a5,a0
    return -1;
    80002cd2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002cd4:	0007c863          	bltz	a5,80002ce4 <sys_kill+0x2a>
  return kill(pid);
    80002cd8:	fec42503          	lw	a0,-20(s0)
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	6b0080e7          	jalr	1712(ra) # 8000238c <kill>
}
    80002ce4:	60e2                	ld	ra,24(sp)
    80002ce6:	6442                	ld	s0,16(sp)
    80002ce8:	6105                	addi	sp,sp,32
    80002cea:	8082                	ret

0000000080002cec <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002cec:	1101                	addi	sp,sp,-32
    80002cee:	ec06                	sd	ra,24(sp)
    80002cf0:	e822                	sd	s0,16(sp)
    80002cf2:	e426                	sd	s1,8(sp)
    80002cf4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002cf6:	00014517          	auipc	a0,0x14
    80002cfa:	3da50513          	addi	a0,a0,986 # 800170d0 <tickslock>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	ed2080e7          	jalr	-302(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002d06:	00006497          	auipc	s1,0x6
    80002d0a:	32a4a483          	lw	s1,810(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d0e:	00014517          	auipc	a0,0x14
    80002d12:	3c250513          	addi	a0,a0,962 # 800170d0 <tickslock>
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	f6e080e7          	jalr	-146(ra) # 80000c84 <release>
  return xticks;
}
    80002d1e:	02049513          	slli	a0,s1,0x20
    80002d22:	9101                	srli	a0,a0,0x20
    80002d24:	60e2                	ld	ra,24(sp)
    80002d26:	6442                	ld	s0,16(sp)
    80002d28:	64a2                	ld	s1,8(sp)
    80002d2a:	6105                	addi	sp,sp,32
    80002d2c:	8082                	ret

0000000080002d2e <sys_getppid>:

uint64
sys_getppid(void)
{
    80002d2e:	1141                	addi	sp,sp,-16
    80002d30:	e406                	sd	ra,8(sp)
    80002d32:	e022                	sd	s0,0(sp)
    80002d34:	0800                	addi	s0,sp,16
  struct proc* par_proc = myproc()->parent->parent->parent;
    80002d36:	fffff097          	auipc	ra,0xfffff
    80002d3a:	c60080e7          	jalr	-928(ra) # 80001996 <myproc>
    80002d3e:	7d1c                	ld	a5,56(a0)
    80002d40:	7f9c                	ld	a5,56(a5)
  if(par_proc) return myproc()->parent->pid;
    80002d42:	7f9c                	ld	a5,56(a5)
  else return -1;
    80002d44:	557d                	li	a0,-1
  if(par_proc) return myproc()->parent->pid;
    80002d46:	c799                	beqz	a5,80002d54 <sys_getppid+0x26>
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	c4e080e7          	jalr	-946(ra) # 80001996 <myproc>
    80002d50:	7d1c                	ld	a5,56(a0)
    80002d52:	5b88                	lw	a0,48(a5)
}
    80002d54:	60a2                	ld	ra,8(sp)
    80002d56:	6402                	ld	s0,0(sp)
    80002d58:	0141                	addi	sp,sp,16
    80002d5a:	8082                	ret

0000000080002d5c <sys_yield>:

uint64
sys_yield(void)
{
    80002d5c:	1141                	addi	sp,sp,-16
    80002d5e:	e406                	sd	ra,8(sp)
    80002d60:	e022                	sd	s0,0(sp)
    80002d62:	0800                	addi	s0,sp,16
  yield();
    80002d64:	fffff097          	auipc	ra,0xfffff
    80002d68:	2ba080e7          	jalr	698(ra) # 8000201e <yield>
  return 0;
}
    80002d6c:	4501                	li	a0,0
    80002d6e:	60a2                	ld	ra,8(sp)
    80002d70:	6402                	ld	s0,0(sp)
    80002d72:	0141                	addi	sp,sp,16
    80002d74:	8082                	ret

0000000080002d76 <sys_getpa>:

uint64
sys_getpa(void)
{
    80002d76:	1101                	addi	sp,sp,-32
    80002d78:	ec06                	sd	ra,24(sp)
    80002d7a:	e822                	sd	s0,16(sp)
    80002d7c:	1000                	addi	s0,sp,32
  int va;
  if(argint(0, &va) < 0)
    80002d7e:	fec40593          	addi	a1,s0,-20
    80002d82:	4501                	li	a0,0
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	cc8080e7          	jalr	-824(ra) # 80002a4c <argint>
    80002d8c:	87aa                	mv	a5,a0
    return -1;
    80002d8e:	557d                	li	a0,-1
  if(argint(0, &va) < 0)
    80002d90:	0207c263          	bltz	a5,80002db4 <sys_getpa+0x3e>
  // printf("%d\n", va);
  // printf("%d\n",walkaddr(myproc()->pagetable, va));
  return walkaddr(myproc()->pagetable, va) + (va & (PGSIZE - 1));
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	c02080e7          	jalr	-1022(ra) # 80001996 <myproc>
    80002d9c:	fec42583          	lw	a1,-20(s0)
    80002da0:	6928                	ld	a0,80(a0)
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	2b0080e7          	jalr	688(ra) # 80001052 <walkaddr>
    80002daa:	fec42783          	lw	a5,-20(s0)
    80002dae:	17d2                	slli	a5,a5,0x34
    80002db0:	93d1                	srli	a5,a5,0x34
    80002db2:	953e                	add	a0,a0,a5
    80002db4:	60e2                	ld	ra,24(sp)
    80002db6:	6442                	ld	s0,16(sp)
    80002db8:	6105                	addi	sp,sp,32
    80002dba:	8082                	ret

0000000080002dbc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002dbc:	7179                	addi	sp,sp,-48
    80002dbe:	f406                	sd	ra,40(sp)
    80002dc0:	f022                	sd	s0,32(sp)
    80002dc2:	ec26                	sd	s1,24(sp)
    80002dc4:	e84a                	sd	s2,16(sp)
    80002dc6:	e44e                	sd	s3,8(sp)
    80002dc8:	e052                	sd	s4,0(sp)
    80002dca:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002dcc:	00005597          	auipc	a1,0x5
    80002dd0:	74458593          	addi	a1,a1,1860 # 80008510 <syscalls+0xc8>
    80002dd4:	00014517          	auipc	a0,0x14
    80002dd8:	31450513          	addi	a0,a0,788 # 800170e8 <bcache>
    80002ddc:	ffffe097          	auipc	ra,0xffffe
    80002de0:	d64080e7          	jalr	-668(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002de4:	0001c797          	auipc	a5,0x1c
    80002de8:	30478793          	addi	a5,a5,772 # 8001f0e8 <bcache+0x8000>
    80002dec:	0001c717          	auipc	a4,0x1c
    80002df0:	56470713          	addi	a4,a4,1380 # 8001f350 <bcache+0x8268>
    80002df4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002df8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dfc:	00014497          	auipc	s1,0x14
    80002e00:	30448493          	addi	s1,s1,772 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002e04:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e06:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e08:	00005a17          	auipc	s4,0x5
    80002e0c:	710a0a13          	addi	s4,s4,1808 # 80008518 <syscalls+0xd0>
    b->next = bcache.head.next;
    80002e10:	2b893783          	ld	a5,696(s2)
    80002e14:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e16:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e1a:	85d2                	mv	a1,s4
    80002e1c:	01048513          	addi	a0,s1,16
    80002e20:	00001097          	auipc	ra,0x1
    80002e24:	4c2080e7          	jalr	1218(ra) # 800042e2 <initsleeplock>
    bcache.head.next->prev = b;
    80002e28:	2b893783          	ld	a5,696(s2)
    80002e2c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e2e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e32:	45848493          	addi	s1,s1,1112
    80002e36:	fd349de3          	bne	s1,s3,80002e10 <binit+0x54>
  }
}
    80002e3a:	70a2                	ld	ra,40(sp)
    80002e3c:	7402                	ld	s0,32(sp)
    80002e3e:	64e2                	ld	s1,24(sp)
    80002e40:	6942                	ld	s2,16(sp)
    80002e42:	69a2                	ld	s3,8(sp)
    80002e44:	6a02                	ld	s4,0(sp)
    80002e46:	6145                	addi	sp,sp,48
    80002e48:	8082                	ret

0000000080002e4a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e4a:	7179                	addi	sp,sp,-48
    80002e4c:	f406                	sd	ra,40(sp)
    80002e4e:	f022                	sd	s0,32(sp)
    80002e50:	ec26                	sd	s1,24(sp)
    80002e52:	e84a                	sd	s2,16(sp)
    80002e54:	e44e                	sd	s3,8(sp)
    80002e56:	1800                	addi	s0,sp,48
    80002e58:	892a                	mv	s2,a0
    80002e5a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e5c:	00014517          	auipc	a0,0x14
    80002e60:	28c50513          	addi	a0,a0,652 # 800170e8 <bcache>
    80002e64:	ffffe097          	auipc	ra,0xffffe
    80002e68:	d6c080e7          	jalr	-660(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e6c:	0001c497          	auipc	s1,0x1c
    80002e70:	5344b483          	ld	s1,1332(s1) # 8001f3a0 <bcache+0x82b8>
    80002e74:	0001c797          	auipc	a5,0x1c
    80002e78:	4dc78793          	addi	a5,a5,1244 # 8001f350 <bcache+0x8268>
    80002e7c:	02f48f63          	beq	s1,a5,80002eba <bread+0x70>
    80002e80:	873e                	mv	a4,a5
    80002e82:	a021                	j	80002e8a <bread+0x40>
    80002e84:	68a4                	ld	s1,80(s1)
    80002e86:	02e48a63          	beq	s1,a4,80002eba <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e8a:	449c                	lw	a5,8(s1)
    80002e8c:	ff279ce3          	bne	a5,s2,80002e84 <bread+0x3a>
    80002e90:	44dc                	lw	a5,12(s1)
    80002e92:	ff3799e3          	bne	a5,s3,80002e84 <bread+0x3a>
      b->refcnt++;
    80002e96:	40bc                	lw	a5,64(s1)
    80002e98:	2785                	addiw	a5,a5,1
    80002e9a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e9c:	00014517          	auipc	a0,0x14
    80002ea0:	24c50513          	addi	a0,a0,588 # 800170e8 <bcache>
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	de0080e7          	jalr	-544(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002eac:	01048513          	addi	a0,s1,16
    80002eb0:	00001097          	auipc	ra,0x1
    80002eb4:	46c080e7          	jalr	1132(ra) # 8000431c <acquiresleep>
      return b;
    80002eb8:	a8b9                	j	80002f16 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002eba:	0001c497          	auipc	s1,0x1c
    80002ebe:	4de4b483          	ld	s1,1246(s1) # 8001f398 <bcache+0x82b0>
    80002ec2:	0001c797          	auipc	a5,0x1c
    80002ec6:	48e78793          	addi	a5,a5,1166 # 8001f350 <bcache+0x8268>
    80002eca:	00f48863          	beq	s1,a5,80002eda <bread+0x90>
    80002ece:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ed0:	40bc                	lw	a5,64(s1)
    80002ed2:	cf81                	beqz	a5,80002eea <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ed4:	64a4                	ld	s1,72(s1)
    80002ed6:	fee49de3          	bne	s1,a4,80002ed0 <bread+0x86>
  panic("bget: no buffers");
    80002eda:	00005517          	auipc	a0,0x5
    80002ede:	64650513          	addi	a0,a0,1606 # 80008520 <syscalls+0xd8>
    80002ee2:	ffffd097          	auipc	ra,0xffffd
    80002ee6:	658080e7          	jalr	1624(ra) # 8000053a <panic>
      b->dev = dev;
    80002eea:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002eee:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002ef2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ef6:	4785                	li	a5,1
    80002ef8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002efa:	00014517          	auipc	a0,0x14
    80002efe:	1ee50513          	addi	a0,a0,494 # 800170e8 <bcache>
    80002f02:	ffffe097          	auipc	ra,0xffffe
    80002f06:	d82080e7          	jalr	-638(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002f0a:	01048513          	addi	a0,s1,16
    80002f0e:	00001097          	auipc	ra,0x1
    80002f12:	40e080e7          	jalr	1038(ra) # 8000431c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f16:	409c                	lw	a5,0(s1)
    80002f18:	cb89                	beqz	a5,80002f2a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f1a:	8526                	mv	a0,s1
    80002f1c:	70a2                	ld	ra,40(sp)
    80002f1e:	7402                	ld	s0,32(sp)
    80002f20:	64e2                	ld	s1,24(sp)
    80002f22:	6942                	ld	s2,16(sp)
    80002f24:	69a2                	ld	s3,8(sp)
    80002f26:	6145                	addi	sp,sp,48
    80002f28:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f2a:	4581                	li	a1,0
    80002f2c:	8526                	mv	a0,s1
    80002f2e:	00003097          	auipc	ra,0x3
    80002f32:	f24080e7          	jalr	-220(ra) # 80005e52 <virtio_disk_rw>
    b->valid = 1;
    80002f36:	4785                	li	a5,1
    80002f38:	c09c                	sw	a5,0(s1)
  return b;
    80002f3a:	b7c5                	j	80002f1a <bread+0xd0>

0000000080002f3c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f3c:	1101                	addi	sp,sp,-32
    80002f3e:	ec06                	sd	ra,24(sp)
    80002f40:	e822                	sd	s0,16(sp)
    80002f42:	e426                	sd	s1,8(sp)
    80002f44:	1000                	addi	s0,sp,32
    80002f46:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f48:	0541                	addi	a0,a0,16
    80002f4a:	00001097          	auipc	ra,0x1
    80002f4e:	46c080e7          	jalr	1132(ra) # 800043b6 <holdingsleep>
    80002f52:	cd01                	beqz	a0,80002f6a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f54:	4585                	li	a1,1
    80002f56:	8526                	mv	a0,s1
    80002f58:	00003097          	auipc	ra,0x3
    80002f5c:	efa080e7          	jalr	-262(ra) # 80005e52 <virtio_disk_rw>
}
    80002f60:	60e2                	ld	ra,24(sp)
    80002f62:	6442                	ld	s0,16(sp)
    80002f64:	64a2                	ld	s1,8(sp)
    80002f66:	6105                	addi	sp,sp,32
    80002f68:	8082                	ret
    panic("bwrite");
    80002f6a:	00005517          	auipc	a0,0x5
    80002f6e:	5ce50513          	addi	a0,a0,1486 # 80008538 <syscalls+0xf0>
    80002f72:	ffffd097          	auipc	ra,0xffffd
    80002f76:	5c8080e7          	jalr	1480(ra) # 8000053a <panic>

0000000080002f7a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f7a:	1101                	addi	sp,sp,-32
    80002f7c:	ec06                	sd	ra,24(sp)
    80002f7e:	e822                	sd	s0,16(sp)
    80002f80:	e426                	sd	s1,8(sp)
    80002f82:	e04a                	sd	s2,0(sp)
    80002f84:	1000                	addi	s0,sp,32
    80002f86:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f88:	01050913          	addi	s2,a0,16
    80002f8c:	854a                	mv	a0,s2
    80002f8e:	00001097          	auipc	ra,0x1
    80002f92:	428080e7          	jalr	1064(ra) # 800043b6 <holdingsleep>
    80002f96:	c92d                	beqz	a0,80003008 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f98:	854a                	mv	a0,s2
    80002f9a:	00001097          	auipc	ra,0x1
    80002f9e:	3d8080e7          	jalr	984(ra) # 80004372 <releasesleep>

  acquire(&bcache.lock);
    80002fa2:	00014517          	auipc	a0,0x14
    80002fa6:	14650513          	addi	a0,a0,326 # 800170e8 <bcache>
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	c26080e7          	jalr	-986(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80002fb2:	40bc                	lw	a5,64(s1)
    80002fb4:	37fd                	addiw	a5,a5,-1
    80002fb6:	0007871b          	sext.w	a4,a5
    80002fba:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fbc:	eb05                	bnez	a4,80002fec <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fbe:	68bc                	ld	a5,80(s1)
    80002fc0:	64b8                	ld	a4,72(s1)
    80002fc2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fc4:	64bc                	ld	a5,72(s1)
    80002fc6:	68b8                	ld	a4,80(s1)
    80002fc8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fca:	0001c797          	auipc	a5,0x1c
    80002fce:	11e78793          	addi	a5,a5,286 # 8001f0e8 <bcache+0x8000>
    80002fd2:	2b87b703          	ld	a4,696(a5)
    80002fd6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fd8:	0001c717          	auipc	a4,0x1c
    80002fdc:	37870713          	addi	a4,a4,888 # 8001f350 <bcache+0x8268>
    80002fe0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fe2:	2b87b703          	ld	a4,696(a5)
    80002fe6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fe8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fec:	00014517          	auipc	a0,0x14
    80002ff0:	0fc50513          	addi	a0,a0,252 # 800170e8 <bcache>
    80002ff4:	ffffe097          	auipc	ra,0xffffe
    80002ff8:	c90080e7          	jalr	-880(ra) # 80000c84 <release>
}
    80002ffc:	60e2                	ld	ra,24(sp)
    80002ffe:	6442                	ld	s0,16(sp)
    80003000:	64a2                	ld	s1,8(sp)
    80003002:	6902                	ld	s2,0(sp)
    80003004:	6105                	addi	sp,sp,32
    80003006:	8082                	ret
    panic("brelse");
    80003008:	00005517          	auipc	a0,0x5
    8000300c:	53850513          	addi	a0,a0,1336 # 80008540 <syscalls+0xf8>
    80003010:	ffffd097          	auipc	ra,0xffffd
    80003014:	52a080e7          	jalr	1322(ra) # 8000053a <panic>

0000000080003018 <bpin>:

void
bpin(struct buf *b) {
    80003018:	1101                	addi	sp,sp,-32
    8000301a:	ec06                	sd	ra,24(sp)
    8000301c:	e822                	sd	s0,16(sp)
    8000301e:	e426                	sd	s1,8(sp)
    80003020:	1000                	addi	s0,sp,32
    80003022:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003024:	00014517          	auipc	a0,0x14
    80003028:	0c450513          	addi	a0,a0,196 # 800170e8 <bcache>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	ba4080e7          	jalr	-1116(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80003034:	40bc                	lw	a5,64(s1)
    80003036:	2785                	addiw	a5,a5,1
    80003038:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000303a:	00014517          	auipc	a0,0x14
    8000303e:	0ae50513          	addi	a0,a0,174 # 800170e8 <bcache>
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	c42080e7          	jalr	-958(ra) # 80000c84 <release>
}
    8000304a:	60e2                	ld	ra,24(sp)
    8000304c:	6442                	ld	s0,16(sp)
    8000304e:	64a2                	ld	s1,8(sp)
    80003050:	6105                	addi	sp,sp,32
    80003052:	8082                	ret

0000000080003054 <bunpin>:

void
bunpin(struct buf *b) {
    80003054:	1101                	addi	sp,sp,-32
    80003056:	ec06                	sd	ra,24(sp)
    80003058:	e822                	sd	s0,16(sp)
    8000305a:	e426                	sd	s1,8(sp)
    8000305c:	1000                	addi	s0,sp,32
    8000305e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003060:	00014517          	auipc	a0,0x14
    80003064:	08850513          	addi	a0,a0,136 # 800170e8 <bcache>
    80003068:	ffffe097          	auipc	ra,0xffffe
    8000306c:	b68080e7          	jalr	-1176(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003070:	40bc                	lw	a5,64(s1)
    80003072:	37fd                	addiw	a5,a5,-1
    80003074:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003076:	00014517          	auipc	a0,0x14
    8000307a:	07250513          	addi	a0,a0,114 # 800170e8 <bcache>
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	c06080e7          	jalr	-1018(ra) # 80000c84 <release>
}
    80003086:	60e2                	ld	ra,24(sp)
    80003088:	6442                	ld	s0,16(sp)
    8000308a:	64a2                	ld	s1,8(sp)
    8000308c:	6105                	addi	sp,sp,32
    8000308e:	8082                	ret

0000000080003090 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003090:	1101                	addi	sp,sp,-32
    80003092:	ec06                	sd	ra,24(sp)
    80003094:	e822                	sd	s0,16(sp)
    80003096:	e426                	sd	s1,8(sp)
    80003098:	e04a                	sd	s2,0(sp)
    8000309a:	1000                	addi	s0,sp,32
    8000309c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000309e:	00d5d59b          	srliw	a1,a1,0xd
    800030a2:	0001c797          	auipc	a5,0x1c
    800030a6:	7227a783          	lw	a5,1826(a5) # 8001f7c4 <sb+0x1c>
    800030aa:	9dbd                	addw	a1,a1,a5
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	d9e080e7          	jalr	-610(ra) # 80002e4a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030b4:	0074f713          	andi	a4,s1,7
    800030b8:	4785                	li	a5,1
    800030ba:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030be:	14ce                	slli	s1,s1,0x33
    800030c0:	90d9                	srli	s1,s1,0x36
    800030c2:	00950733          	add	a4,a0,s1
    800030c6:	05874703          	lbu	a4,88(a4)
    800030ca:	00e7f6b3          	and	a3,a5,a4
    800030ce:	c69d                	beqz	a3,800030fc <bfree+0x6c>
    800030d0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030d2:	94aa                	add	s1,s1,a0
    800030d4:	fff7c793          	not	a5,a5
    800030d8:	8f7d                	and	a4,a4,a5
    800030da:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800030de:	00001097          	auipc	ra,0x1
    800030e2:	120080e7          	jalr	288(ra) # 800041fe <log_write>
  brelse(bp);
    800030e6:	854a                	mv	a0,s2
    800030e8:	00000097          	auipc	ra,0x0
    800030ec:	e92080e7          	jalr	-366(ra) # 80002f7a <brelse>
}
    800030f0:	60e2                	ld	ra,24(sp)
    800030f2:	6442                	ld	s0,16(sp)
    800030f4:	64a2                	ld	s1,8(sp)
    800030f6:	6902                	ld	s2,0(sp)
    800030f8:	6105                	addi	sp,sp,32
    800030fa:	8082                	ret
    panic("freeing free block");
    800030fc:	00005517          	auipc	a0,0x5
    80003100:	44c50513          	addi	a0,a0,1100 # 80008548 <syscalls+0x100>
    80003104:	ffffd097          	auipc	ra,0xffffd
    80003108:	436080e7          	jalr	1078(ra) # 8000053a <panic>

000000008000310c <balloc>:
{
    8000310c:	711d                	addi	sp,sp,-96
    8000310e:	ec86                	sd	ra,88(sp)
    80003110:	e8a2                	sd	s0,80(sp)
    80003112:	e4a6                	sd	s1,72(sp)
    80003114:	e0ca                	sd	s2,64(sp)
    80003116:	fc4e                	sd	s3,56(sp)
    80003118:	f852                	sd	s4,48(sp)
    8000311a:	f456                	sd	s5,40(sp)
    8000311c:	f05a                	sd	s6,32(sp)
    8000311e:	ec5e                	sd	s7,24(sp)
    80003120:	e862                	sd	s8,16(sp)
    80003122:	e466                	sd	s9,8(sp)
    80003124:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003126:	0001c797          	auipc	a5,0x1c
    8000312a:	6867a783          	lw	a5,1670(a5) # 8001f7ac <sb+0x4>
    8000312e:	cbc1                	beqz	a5,800031be <balloc+0xb2>
    80003130:	8baa                	mv	s7,a0
    80003132:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003134:	0001cb17          	auipc	s6,0x1c
    80003138:	674b0b13          	addi	s6,s6,1652 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000313c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000313e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003140:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003142:	6c89                	lui	s9,0x2
    80003144:	a831                	j	80003160 <balloc+0x54>
    brelse(bp);
    80003146:	854a                	mv	a0,s2
    80003148:	00000097          	auipc	ra,0x0
    8000314c:	e32080e7          	jalr	-462(ra) # 80002f7a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003150:	015c87bb          	addw	a5,s9,s5
    80003154:	00078a9b          	sext.w	s5,a5
    80003158:	004b2703          	lw	a4,4(s6)
    8000315c:	06eaf163          	bgeu	s5,a4,800031be <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003160:	41fad79b          	sraiw	a5,s5,0x1f
    80003164:	0137d79b          	srliw	a5,a5,0x13
    80003168:	015787bb          	addw	a5,a5,s5
    8000316c:	40d7d79b          	sraiw	a5,a5,0xd
    80003170:	01cb2583          	lw	a1,28(s6)
    80003174:	9dbd                	addw	a1,a1,a5
    80003176:	855e                	mv	a0,s7
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	cd2080e7          	jalr	-814(ra) # 80002e4a <bread>
    80003180:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003182:	004b2503          	lw	a0,4(s6)
    80003186:	000a849b          	sext.w	s1,s5
    8000318a:	8762                	mv	a4,s8
    8000318c:	faa4fde3          	bgeu	s1,a0,80003146 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003190:	00777693          	andi	a3,a4,7
    80003194:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003198:	41f7579b          	sraiw	a5,a4,0x1f
    8000319c:	01d7d79b          	srliw	a5,a5,0x1d
    800031a0:	9fb9                	addw	a5,a5,a4
    800031a2:	4037d79b          	sraiw	a5,a5,0x3
    800031a6:	00f90633          	add	a2,s2,a5
    800031aa:	05864603          	lbu	a2,88(a2)
    800031ae:	00c6f5b3          	and	a1,a3,a2
    800031b2:	cd91                	beqz	a1,800031ce <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031b4:	2705                	addiw	a4,a4,1
    800031b6:	2485                	addiw	s1,s1,1
    800031b8:	fd471ae3          	bne	a4,s4,8000318c <balloc+0x80>
    800031bc:	b769                	j	80003146 <balloc+0x3a>
  panic("balloc: out of blocks");
    800031be:	00005517          	auipc	a0,0x5
    800031c2:	3a250513          	addi	a0,a0,930 # 80008560 <syscalls+0x118>
    800031c6:	ffffd097          	auipc	ra,0xffffd
    800031ca:	374080e7          	jalr	884(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031ce:	97ca                	add	a5,a5,s2
    800031d0:	8e55                	or	a2,a2,a3
    800031d2:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800031d6:	854a                	mv	a0,s2
    800031d8:	00001097          	auipc	ra,0x1
    800031dc:	026080e7          	jalr	38(ra) # 800041fe <log_write>
        brelse(bp);
    800031e0:	854a                	mv	a0,s2
    800031e2:	00000097          	auipc	ra,0x0
    800031e6:	d98080e7          	jalr	-616(ra) # 80002f7a <brelse>
  bp = bread(dev, bno);
    800031ea:	85a6                	mv	a1,s1
    800031ec:	855e                	mv	a0,s7
    800031ee:	00000097          	auipc	ra,0x0
    800031f2:	c5c080e7          	jalr	-932(ra) # 80002e4a <bread>
    800031f6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031f8:	40000613          	li	a2,1024
    800031fc:	4581                	li	a1,0
    800031fe:	05850513          	addi	a0,a0,88
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	aca080e7          	jalr	-1334(ra) # 80000ccc <memset>
  log_write(bp);
    8000320a:	854a                	mv	a0,s2
    8000320c:	00001097          	auipc	ra,0x1
    80003210:	ff2080e7          	jalr	-14(ra) # 800041fe <log_write>
  brelse(bp);
    80003214:	854a                	mv	a0,s2
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	d64080e7          	jalr	-668(ra) # 80002f7a <brelse>
}
    8000321e:	8526                	mv	a0,s1
    80003220:	60e6                	ld	ra,88(sp)
    80003222:	6446                	ld	s0,80(sp)
    80003224:	64a6                	ld	s1,72(sp)
    80003226:	6906                	ld	s2,64(sp)
    80003228:	79e2                	ld	s3,56(sp)
    8000322a:	7a42                	ld	s4,48(sp)
    8000322c:	7aa2                	ld	s5,40(sp)
    8000322e:	7b02                	ld	s6,32(sp)
    80003230:	6be2                	ld	s7,24(sp)
    80003232:	6c42                	ld	s8,16(sp)
    80003234:	6ca2                	ld	s9,8(sp)
    80003236:	6125                	addi	sp,sp,96
    80003238:	8082                	ret

000000008000323a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000323a:	7179                	addi	sp,sp,-48
    8000323c:	f406                	sd	ra,40(sp)
    8000323e:	f022                	sd	s0,32(sp)
    80003240:	ec26                	sd	s1,24(sp)
    80003242:	e84a                	sd	s2,16(sp)
    80003244:	e44e                	sd	s3,8(sp)
    80003246:	e052                	sd	s4,0(sp)
    80003248:	1800                	addi	s0,sp,48
    8000324a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000324c:	47ad                	li	a5,11
    8000324e:	04b7fe63          	bgeu	a5,a1,800032aa <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003252:	ff45849b          	addiw	s1,a1,-12
    80003256:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000325a:	0ff00793          	li	a5,255
    8000325e:	0ae7e463          	bltu	a5,a4,80003306 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003262:	08052583          	lw	a1,128(a0)
    80003266:	c5b5                	beqz	a1,800032d2 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003268:	00092503          	lw	a0,0(s2)
    8000326c:	00000097          	auipc	ra,0x0
    80003270:	bde080e7          	jalr	-1058(ra) # 80002e4a <bread>
    80003274:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003276:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000327a:	02049713          	slli	a4,s1,0x20
    8000327e:	01e75593          	srli	a1,a4,0x1e
    80003282:	00b784b3          	add	s1,a5,a1
    80003286:	0004a983          	lw	s3,0(s1)
    8000328a:	04098e63          	beqz	s3,800032e6 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000328e:	8552                	mv	a0,s4
    80003290:	00000097          	auipc	ra,0x0
    80003294:	cea080e7          	jalr	-790(ra) # 80002f7a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003298:	854e                	mv	a0,s3
    8000329a:	70a2                	ld	ra,40(sp)
    8000329c:	7402                	ld	s0,32(sp)
    8000329e:	64e2                	ld	s1,24(sp)
    800032a0:	6942                	ld	s2,16(sp)
    800032a2:	69a2                	ld	s3,8(sp)
    800032a4:	6a02                	ld	s4,0(sp)
    800032a6:	6145                	addi	sp,sp,48
    800032a8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032aa:	02059793          	slli	a5,a1,0x20
    800032ae:	01e7d593          	srli	a1,a5,0x1e
    800032b2:	00b504b3          	add	s1,a0,a1
    800032b6:	0504a983          	lw	s3,80(s1)
    800032ba:	fc099fe3          	bnez	s3,80003298 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032be:	4108                	lw	a0,0(a0)
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	e4c080e7          	jalr	-436(ra) # 8000310c <balloc>
    800032c8:	0005099b          	sext.w	s3,a0
    800032cc:	0534a823          	sw	s3,80(s1)
    800032d0:	b7e1                	j	80003298 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032d2:	4108                	lw	a0,0(a0)
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	e38080e7          	jalr	-456(ra) # 8000310c <balloc>
    800032dc:	0005059b          	sext.w	a1,a0
    800032e0:	08b92023          	sw	a1,128(s2)
    800032e4:	b751                	j	80003268 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032e6:	00092503          	lw	a0,0(s2)
    800032ea:	00000097          	auipc	ra,0x0
    800032ee:	e22080e7          	jalr	-478(ra) # 8000310c <balloc>
    800032f2:	0005099b          	sext.w	s3,a0
    800032f6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032fa:	8552                	mv	a0,s4
    800032fc:	00001097          	auipc	ra,0x1
    80003300:	f02080e7          	jalr	-254(ra) # 800041fe <log_write>
    80003304:	b769                	j	8000328e <bmap+0x54>
  panic("bmap: out of range");
    80003306:	00005517          	auipc	a0,0x5
    8000330a:	27250513          	addi	a0,a0,626 # 80008578 <syscalls+0x130>
    8000330e:	ffffd097          	auipc	ra,0xffffd
    80003312:	22c080e7          	jalr	556(ra) # 8000053a <panic>

0000000080003316 <iget>:
{
    80003316:	7179                	addi	sp,sp,-48
    80003318:	f406                	sd	ra,40(sp)
    8000331a:	f022                	sd	s0,32(sp)
    8000331c:	ec26                	sd	s1,24(sp)
    8000331e:	e84a                	sd	s2,16(sp)
    80003320:	e44e                	sd	s3,8(sp)
    80003322:	e052                	sd	s4,0(sp)
    80003324:	1800                	addi	s0,sp,48
    80003326:	89aa                	mv	s3,a0
    80003328:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000332a:	0001c517          	auipc	a0,0x1c
    8000332e:	49e50513          	addi	a0,a0,1182 # 8001f7c8 <itable>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	89e080e7          	jalr	-1890(ra) # 80000bd0 <acquire>
  empty = 0;
    8000333a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000333c:	0001c497          	auipc	s1,0x1c
    80003340:	4a448493          	addi	s1,s1,1188 # 8001f7e0 <itable+0x18>
    80003344:	0001e697          	auipc	a3,0x1e
    80003348:	f2c68693          	addi	a3,a3,-212 # 80021270 <log>
    8000334c:	a039                	j	8000335a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000334e:	02090b63          	beqz	s2,80003384 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003352:	08848493          	addi	s1,s1,136
    80003356:	02d48a63          	beq	s1,a3,8000338a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000335a:	449c                	lw	a5,8(s1)
    8000335c:	fef059e3          	blez	a5,8000334e <iget+0x38>
    80003360:	4098                	lw	a4,0(s1)
    80003362:	ff3716e3          	bne	a4,s3,8000334e <iget+0x38>
    80003366:	40d8                	lw	a4,4(s1)
    80003368:	ff4713e3          	bne	a4,s4,8000334e <iget+0x38>
      ip->ref++;
    8000336c:	2785                	addiw	a5,a5,1
    8000336e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003370:	0001c517          	auipc	a0,0x1c
    80003374:	45850513          	addi	a0,a0,1112 # 8001f7c8 <itable>
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	90c080e7          	jalr	-1780(ra) # 80000c84 <release>
      return ip;
    80003380:	8926                	mv	s2,s1
    80003382:	a03d                	j	800033b0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003384:	f7f9                	bnez	a5,80003352 <iget+0x3c>
    80003386:	8926                	mv	s2,s1
    80003388:	b7e9                	j	80003352 <iget+0x3c>
  if(empty == 0)
    8000338a:	02090c63          	beqz	s2,800033c2 <iget+0xac>
  ip->dev = dev;
    8000338e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003392:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003396:	4785                	li	a5,1
    80003398:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000339c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033a0:	0001c517          	auipc	a0,0x1c
    800033a4:	42850513          	addi	a0,a0,1064 # 8001f7c8 <itable>
    800033a8:	ffffe097          	auipc	ra,0xffffe
    800033ac:	8dc080e7          	jalr	-1828(ra) # 80000c84 <release>
}
    800033b0:	854a                	mv	a0,s2
    800033b2:	70a2                	ld	ra,40(sp)
    800033b4:	7402                	ld	s0,32(sp)
    800033b6:	64e2                	ld	s1,24(sp)
    800033b8:	6942                	ld	s2,16(sp)
    800033ba:	69a2                	ld	s3,8(sp)
    800033bc:	6a02                	ld	s4,0(sp)
    800033be:	6145                	addi	sp,sp,48
    800033c0:	8082                	ret
    panic("iget: no inodes");
    800033c2:	00005517          	auipc	a0,0x5
    800033c6:	1ce50513          	addi	a0,a0,462 # 80008590 <syscalls+0x148>
    800033ca:	ffffd097          	auipc	ra,0xffffd
    800033ce:	170080e7          	jalr	368(ra) # 8000053a <panic>

00000000800033d2 <fsinit>:
fsinit(int dev) {
    800033d2:	7179                	addi	sp,sp,-48
    800033d4:	f406                	sd	ra,40(sp)
    800033d6:	f022                	sd	s0,32(sp)
    800033d8:	ec26                	sd	s1,24(sp)
    800033da:	e84a                	sd	s2,16(sp)
    800033dc:	e44e                	sd	s3,8(sp)
    800033de:	1800                	addi	s0,sp,48
    800033e0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033e2:	4585                	li	a1,1
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	a66080e7          	jalr	-1434(ra) # 80002e4a <bread>
    800033ec:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033ee:	0001c997          	auipc	s3,0x1c
    800033f2:	3ba98993          	addi	s3,s3,954 # 8001f7a8 <sb>
    800033f6:	02000613          	li	a2,32
    800033fa:	05850593          	addi	a1,a0,88
    800033fe:	854e                	mv	a0,s3
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	928080e7          	jalr	-1752(ra) # 80000d28 <memmove>
  brelse(bp);
    80003408:	8526                	mv	a0,s1
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	b70080e7          	jalr	-1168(ra) # 80002f7a <brelse>
  if(sb.magic != FSMAGIC)
    80003412:	0009a703          	lw	a4,0(s3)
    80003416:	102037b7          	lui	a5,0x10203
    8000341a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000341e:	02f71263          	bne	a4,a5,80003442 <fsinit+0x70>
  initlog(dev, &sb);
    80003422:	0001c597          	auipc	a1,0x1c
    80003426:	38658593          	addi	a1,a1,902 # 8001f7a8 <sb>
    8000342a:	854a                	mv	a0,s2
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	b56080e7          	jalr	-1194(ra) # 80003f82 <initlog>
}
    80003434:	70a2                	ld	ra,40(sp)
    80003436:	7402                	ld	s0,32(sp)
    80003438:	64e2                	ld	s1,24(sp)
    8000343a:	6942                	ld	s2,16(sp)
    8000343c:	69a2                	ld	s3,8(sp)
    8000343e:	6145                	addi	sp,sp,48
    80003440:	8082                	ret
    panic("invalid file system");
    80003442:	00005517          	auipc	a0,0x5
    80003446:	15e50513          	addi	a0,a0,350 # 800085a0 <syscalls+0x158>
    8000344a:	ffffd097          	auipc	ra,0xffffd
    8000344e:	0f0080e7          	jalr	240(ra) # 8000053a <panic>

0000000080003452 <iinit>:
{
    80003452:	7179                	addi	sp,sp,-48
    80003454:	f406                	sd	ra,40(sp)
    80003456:	f022                	sd	s0,32(sp)
    80003458:	ec26                	sd	s1,24(sp)
    8000345a:	e84a                	sd	s2,16(sp)
    8000345c:	e44e                	sd	s3,8(sp)
    8000345e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003460:	00005597          	auipc	a1,0x5
    80003464:	15858593          	addi	a1,a1,344 # 800085b8 <syscalls+0x170>
    80003468:	0001c517          	auipc	a0,0x1c
    8000346c:	36050513          	addi	a0,a0,864 # 8001f7c8 <itable>
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	6d0080e7          	jalr	1744(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003478:	0001c497          	auipc	s1,0x1c
    8000347c:	37848493          	addi	s1,s1,888 # 8001f7f0 <itable+0x28>
    80003480:	0001e997          	auipc	s3,0x1e
    80003484:	e0098993          	addi	s3,s3,-512 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003488:	00005917          	auipc	s2,0x5
    8000348c:	13890913          	addi	s2,s2,312 # 800085c0 <syscalls+0x178>
    80003490:	85ca                	mv	a1,s2
    80003492:	8526                	mv	a0,s1
    80003494:	00001097          	auipc	ra,0x1
    80003498:	e4e080e7          	jalr	-434(ra) # 800042e2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000349c:	08848493          	addi	s1,s1,136
    800034a0:	ff3498e3          	bne	s1,s3,80003490 <iinit+0x3e>
}
    800034a4:	70a2                	ld	ra,40(sp)
    800034a6:	7402                	ld	s0,32(sp)
    800034a8:	64e2                	ld	s1,24(sp)
    800034aa:	6942                	ld	s2,16(sp)
    800034ac:	69a2                	ld	s3,8(sp)
    800034ae:	6145                	addi	sp,sp,48
    800034b0:	8082                	ret

00000000800034b2 <ialloc>:
{
    800034b2:	715d                	addi	sp,sp,-80
    800034b4:	e486                	sd	ra,72(sp)
    800034b6:	e0a2                	sd	s0,64(sp)
    800034b8:	fc26                	sd	s1,56(sp)
    800034ba:	f84a                	sd	s2,48(sp)
    800034bc:	f44e                	sd	s3,40(sp)
    800034be:	f052                	sd	s4,32(sp)
    800034c0:	ec56                	sd	s5,24(sp)
    800034c2:	e85a                	sd	s6,16(sp)
    800034c4:	e45e                	sd	s7,8(sp)
    800034c6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034c8:	0001c717          	auipc	a4,0x1c
    800034cc:	2ec72703          	lw	a4,748(a4) # 8001f7b4 <sb+0xc>
    800034d0:	4785                	li	a5,1
    800034d2:	04e7fa63          	bgeu	a5,a4,80003526 <ialloc+0x74>
    800034d6:	8aaa                	mv	s5,a0
    800034d8:	8bae                	mv	s7,a1
    800034da:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034dc:	0001ca17          	auipc	s4,0x1c
    800034e0:	2cca0a13          	addi	s4,s4,716 # 8001f7a8 <sb>
    800034e4:	00048b1b          	sext.w	s6,s1
    800034e8:	0044d593          	srli	a1,s1,0x4
    800034ec:	018a2783          	lw	a5,24(s4)
    800034f0:	9dbd                	addw	a1,a1,a5
    800034f2:	8556                	mv	a0,s5
    800034f4:	00000097          	auipc	ra,0x0
    800034f8:	956080e7          	jalr	-1706(ra) # 80002e4a <bread>
    800034fc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034fe:	05850993          	addi	s3,a0,88
    80003502:	00f4f793          	andi	a5,s1,15
    80003506:	079a                	slli	a5,a5,0x6
    80003508:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000350a:	00099783          	lh	a5,0(s3)
    8000350e:	c785                	beqz	a5,80003536 <ialloc+0x84>
    brelse(bp);
    80003510:	00000097          	auipc	ra,0x0
    80003514:	a6a080e7          	jalr	-1430(ra) # 80002f7a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003518:	0485                	addi	s1,s1,1
    8000351a:	00ca2703          	lw	a4,12(s4)
    8000351e:	0004879b          	sext.w	a5,s1
    80003522:	fce7e1e3          	bltu	a5,a4,800034e4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003526:	00005517          	auipc	a0,0x5
    8000352a:	0a250513          	addi	a0,a0,162 # 800085c8 <syscalls+0x180>
    8000352e:	ffffd097          	auipc	ra,0xffffd
    80003532:	00c080e7          	jalr	12(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003536:	04000613          	li	a2,64
    8000353a:	4581                	li	a1,0
    8000353c:	854e                	mv	a0,s3
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	78e080e7          	jalr	1934(ra) # 80000ccc <memset>
      dip->type = type;
    80003546:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000354a:	854a                	mv	a0,s2
    8000354c:	00001097          	auipc	ra,0x1
    80003550:	cb2080e7          	jalr	-846(ra) # 800041fe <log_write>
      brelse(bp);
    80003554:	854a                	mv	a0,s2
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	a24080e7          	jalr	-1500(ra) # 80002f7a <brelse>
      return iget(dev, inum);
    8000355e:	85da                	mv	a1,s6
    80003560:	8556                	mv	a0,s5
    80003562:	00000097          	auipc	ra,0x0
    80003566:	db4080e7          	jalr	-588(ra) # 80003316 <iget>
}
    8000356a:	60a6                	ld	ra,72(sp)
    8000356c:	6406                	ld	s0,64(sp)
    8000356e:	74e2                	ld	s1,56(sp)
    80003570:	7942                	ld	s2,48(sp)
    80003572:	79a2                	ld	s3,40(sp)
    80003574:	7a02                	ld	s4,32(sp)
    80003576:	6ae2                	ld	s5,24(sp)
    80003578:	6b42                	ld	s6,16(sp)
    8000357a:	6ba2                	ld	s7,8(sp)
    8000357c:	6161                	addi	sp,sp,80
    8000357e:	8082                	ret

0000000080003580 <iupdate>:
{
    80003580:	1101                	addi	sp,sp,-32
    80003582:	ec06                	sd	ra,24(sp)
    80003584:	e822                	sd	s0,16(sp)
    80003586:	e426                	sd	s1,8(sp)
    80003588:	e04a                	sd	s2,0(sp)
    8000358a:	1000                	addi	s0,sp,32
    8000358c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000358e:	415c                	lw	a5,4(a0)
    80003590:	0047d79b          	srliw	a5,a5,0x4
    80003594:	0001c597          	auipc	a1,0x1c
    80003598:	22c5a583          	lw	a1,556(a1) # 8001f7c0 <sb+0x18>
    8000359c:	9dbd                	addw	a1,a1,a5
    8000359e:	4108                	lw	a0,0(a0)
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	8aa080e7          	jalr	-1878(ra) # 80002e4a <bread>
    800035a8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035aa:	05850793          	addi	a5,a0,88
    800035ae:	40d8                	lw	a4,4(s1)
    800035b0:	8b3d                	andi	a4,a4,15
    800035b2:	071a                	slli	a4,a4,0x6
    800035b4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800035b6:	04449703          	lh	a4,68(s1)
    800035ba:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800035be:	04649703          	lh	a4,70(s1)
    800035c2:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800035c6:	04849703          	lh	a4,72(s1)
    800035ca:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800035ce:	04a49703          	lh	a4,74(s1)
    800035d2:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800035d6:	44f8                	lw	a4,76(s1)
    800035d8:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035da:	03400613          	li	a2,52
    800035de:	05048593          	addi	a1,s1,80
    800035e2:	00c78513          	addi	a0,a5,12
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	742080e7          	jalr	1858(ra) # 80000d28 <memmove>
  log_write(bp);
    800035ee:	854a                	mv	a0,s2
    800035f0:	00001097          	auipc	ra,0x1
    800035f4:	c0e080e7          	jalr	-1010(ra) # 800041fe <log_write>
  brelse(bp);
    800035f8:	854a                	mv	a0,s2
    800035fa:	00000097          	auipc	ra,0x0
    800035fe:	980080e7          	jalr	-1664(ra) # 80002f7a <brelse>
}
    80003602:	60e2                	ld	ra,24(sp)
    80003604:	6442                	ld	s0,16(sp)
    80003606:	64a2                	ld	s1,8(sp)
    80003608:	6902                	ld	s2,0(sp)
    8000360a:	6105                	addi	sp,sp,32
    8000360c:	8082                	ret

000000008000360e <idup>:
{
    8000360e:	1101                	addi	sp,sp,-32
    80003610:	ec06                	sd	ra,24(sp)
    80003612:	e822                	sd	s0,16(sp)
    80003614:	e426                	sd	s1,8(sp)
    80003616:	1000                	addi	s0,sp,32
    80003618:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000361a:	0001c517          	auipc	a0,0x1c
    8000361e:	1ae50513          	addi	a0,a0,430 # 8001f7c8 <itable>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	5ae080e7          	jalr	1454(ra) # 80000bd0 <acquire>
  ip->ref++;
    8000362a:	449c                	lw	a5,8(s1)
    8000362c:	2785                	addiw	a5,a5,1
    8000362e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003630:	0001c517          	auipc	a0,0x1c
    80003634:	19850513          	addi	a0,a0,408 # 8001f7c8 <itable>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	64c080e7          	jalr	1612(ra) # 80000c84 <release>
}
    80003640:	8526                	mv	a0,s1
    80003642:	60e2                	ld	ra,24(sp)
    80003644:	6442                	ld	s0,16(sp)
    80003646:	64a2                	ld	s1,8(sp)
    80003648:	6105                	addi	sp,sp,32
    8000364a:	8082                	ret

000000008000364c <ilock>:
{
    8000364c:	1101                	addi	sp,sp,-32
    8000364e:	ec06                	sd	ra,24(sp)
    80003650:	e822                	sd	s0,16(sp)
    80003652:	e426                	sd	s1,8(sp)
    80003654:	e04a                	sd	s2,0(sp)
    80003656:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003658:	c115                	beqz	a0,8000367c <ilock+0x30>
    8000365a:	84aa                	mv	s1,a0
    8000365c:	451c                	lw	a5,8(a0)
    8000365e:	00f05f63          	blez	a5,8000367c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003662:	0541                	addi	a0,a0,16
    80003664:	00001097          	auipc	ra,0x1
    80003668:	cb8080e7          	jalr	-840(ra) # 8000431c <acquiresleep>
  if(ip->valid == 0){
    8000366c:	40bc                	lw	a5,64(s1)
    8000366e:	cf99                	beqz	a5,8000368c <ilock+0x40>
}
    80003670:	60e2                	ld	ra,24(sp)
    80003672:	6442                	ld	s0,16(sp)
    80003674:	64a2                	ld	s1,8(sp)
    80003676:	6902                	ld	s2,0(sp)
    80003678:	6105                	addi	sp,sp,32
    8000367a:	8082                	ret
    panic("ilock");
    8000367c:	00005517          	auipc	a0,0x5
    80003680:	f6450513          	addi	a0,a0,-156 # 800085e0 <syscalls+0x198>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	eb6080e7          	jalr	-330(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000368c:	40dc                	lw	a5,4(s1)
    8000368e:	0047d79b          	srliw	a5,a5,0x4
    80003692:	0001c597          	auipc	a1,0x1c
    80003696:	12e5a583          	lw	a1,302(a1) # 8001f7c0 <sb+0x18>
    8000369a:	9dbd                	addw	a1,a1,a5
    8000369c:	4088                	lw	a0,0(s1)
    8000369e:	fffff097          	auipc	ra,0xfffff
    800036a2:	7ac080e7          	jalr	1964(ra) # 80002e4a <bread>
    800036a6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036a8:	05850593          	addi	a1,a0,88
    800036ac:	40dc                	lw	a5,4(s1)
    800036ae:	8bbd                	andi	a5,a5,15
    800036b0:	079a                	slli	a5,a5,0x6
    800036b2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036b4:	00059783          	lh	a5,0(a1)
    800036b8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036bc:	00259783          	lh	a5,2(a1)
    800036c0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036c4:	00459783          	lh	a5,4(a1)
    800036c8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036cc:	00659783          	lh	a5,6(a1)
    800036d0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036d4:	459c                	lw	a5,8(a1)
    800036d6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036d8:	03400613          	li	a2,52
    800036dc:	05b1                	addi	a1,a1,12
    800036de:	05048513          	addi	a0,s1,80
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	646080e7          	jalr	1606(ra) # 80000d28 <memmove>
    brelse(bp);
    800036ea:	854a                	mv	a0,s2
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	88e080e7          	jalr	-1906(ra) # 80002f7a <brelse>
    ip->valid = 1;
    800036f4:	4785                	li	a5,1
    800036f6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036f8:	04449783          	lh	a5,68(s1)
    800036fc:	fbb5                	bnez	a5,80003670 <ilock+0x24>
      panic("ilock: no type");
    800036fe:	00005517          	auipc	a0,0x5
    80003702:	eea50513          	addi	a0,a0,-278 # 800085e8 <syscalls+0x1a0>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	e34080e7          	jalr	-460(ra) # 8000053a <panic>

000000008000370e <iunlock>:
{
    8000370e:	1101                	addi	sp,sp,-32
    80003710:	ec06                	sd	ra,24(sp)
    80003712:	e822                	sd	s0,16(sp)
    80003714:	e426                	sd	s1,8(sp)
    80003716:	e04a                	sd	s2,0(sp)
    80003718:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000371a:	c905                	beqz	a0,8000374a <iunlock+0x3c>
    8000371c:	84aa                	mv	s1,a0
    8000371e:	01050913          	addi	s2,a0,16
    80003722:	854a                	mv	a0,s2
    80003724:	00001097          	auipc	ra,0x1
    80003728:	c92080e7          	jalr	-878(ra) # 800043b6 <holdingsleep>
    8000372c:	cd19                	beqz	a0,8000374a <iunlock+0x3c>
    8000372e:	449c                	lw	a5,8(s1)
    80003730:	00f05d63          	blez	a5,8000374a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003734:	854a                	mv	a0,s2
    80003736:	00001097          	auipc	ra,0x1
    8000373a:	c3c080e7          	jalr	-964(ra) # 80004372 <releasesleep>
}
    8000373e:	60e2                	ld	ra,24(sp)
    80003740:	6442                	ld	s0,16(sp)
    80003742:	64a2                	ld	s1,8(sp)
    80003744:	6902                	ld	s2,0(sp)
    80003746:	6105                	addi	sp,sp,32
    80003748:	8082                	ret
    panic("iunlock");
    8000374a:	00005517          	auipc	a0,0x5
    8000374e:	eae50513          	addi	a0,a0,-338 # 800085f8 <syscalls+0x1b0>
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	de8080e7          	jalr	-536(ra) # 8000053a <panic>

000000008000375a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000375a:	7179                	addi	sp,sp,-48
    8000375c:	f406                	sd	ra,40(sp)
    8000375e:	f022                	sd	s0,32(sp)
    80003760:	ec26                	sd	s1,24(sp)
    80003762:	e84a                	sd	s2,16(sp)
    80003764:	e44e                	sd	s3,8(sp)
    80003766:	e052                	sd	s4,0(sp)
    80003768:	1800                	addi	s0,sp,48
    8000376a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000376c:	05050493          	addi	s1,a0,80
    80003770:	08050913          	addi	s2,a0,128
    80003774:	a021                	j	8000377c <itrunc+0x22>
    80003776:	0491                	addi	s1,s1,4
    80003778:	01248d63          	beq	s1,s2,80003792 <itrunc+0x38>
    if(ip->addrs[i]){
    8000377c:	408c                	lw	a1,0(s1)
    8000377e:	dde5                	beqz	a1,80003776 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003780:	0009a503          	lw	a0,0(s3)
    80003784:	00000097          	auipc	ra,0x0
    80003788:	90c080e7          	jalr	-1780(ra) # 80003090 <bfree>
      ip->addrs[i] = 0;
    8000378c:	0004a023          	sw	zero,0(s1)
    80003790:	b7dd                	j	80003776 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003792:	0809a583          	lw	a1,128(s3)
    80003796:	e185                	bnez	a1,800037b6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003798:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000379c:	854e                	mv	a0,s3
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	de2080e7          	jalr	-542(ra) # 80003580 <iupdate>
}
    800037a6:	70a2                	ld	ra,40(sp)
    800037a8:	7402                	ld	s0,32(sp)
    800037aa:	64e2                	ld	s1,24(sp)
    800037ac:	6942                	ld	s2,16(sp)
    800037ae:	69a2                	ld	s3,8(sp)
    800037b0:	6a02                	ld	s4,0(sp)
    800037b2:	6145                	addi	sp,sp,48
    800037b4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037b6:	0009a503          	lw	a0,0(s3)
    800037ba:	fffff097          	auipc	ra,0xfffff
    800037be:	690080e7          	jalr	1680(ra) # 80002e4a <bread>
    800037c2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037c4:	05850493          	addi	s1,a0,88
    800037c8:	45850913          	addi	s2,a0,1112
    800037cc:	a021                	j	800037d4 <itrunc+0x7a>
    800037ce:	0491                	addi	s1,s1,4
    800037d0:	01248b63          	beq	s1,s2,800037e6 <itrunc+0x8c>
      if(a[j])
    800037d4:	408c                	lw	a1,0(s1)
    800037d6:	dde5                	beqz	a1,800037ce <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800037d8:	0009a503          	lw	a0,0(s3)
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	8b4080e7          	jalr	-1868(ra) # 80003090 <bfree>
    800037e4:	b7ed                	j	800037ce <itrunc+0x74>
    brelse(bp);
    800037e6:	8552                	mv	a0,s4
    800037e8:	fffff097          	auipc	ra,0xfffff
    800037ec:	792080e7          	jalr	1938(ra) # 80002f7a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037f0:	0809a583          	lw	a1,128(s3)
    800037f4:	0009a503          	lw	a0,0(s3)
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	898080e7          	jalr	-1896(ra) # 80003090 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003800:	0809a023          	sw	zero,128(s3)
    80003804:	bf51                	j	80003798 <itrunc+0x3e>

0000000080003806 <iput>:
{
    80003806:	1101                	addi	sp,sp,-32
    80003808:	ec06                	sd	ra,24(sp)
    8000380a:	e822                	sd	s0,16(sp)
    8000380c:	e426                	sd	s1,8(sp)
    8000380e:	e04a                	sd	s2,0(sp)
    80003810:	1000                	addi	s0,sp,32
    80003812:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003814:	0001c517          	auipc	a0,0x1c
    80003818:	fb450513          	addi	a0,a0,-76 # 8001f7c8 <itable>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	3b4080e7          	jalr	948(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003824:	4498                	lw	a4,8(s1)
    80003826:	4785                	li	a5,1
    80003828:	02f70363          	beq	a4,a5,8000384e <iput+0x48>
  ip->ref--;
    8000382c:	449c                	lw	a5,8(s1)
    8000382e:	37fd                	addiw	a5,a5,-1
    80003830:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003832:	0001c517          	auipc	a0,0x1c
    80003836:	f9650513          	addi	a0,a0,-106 # 8001f7c8 <itable>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	44a080e7          	jalr	1098(ra) # 80000c84 <release>
}
    80003842:	60e2                	ld	ra,24(sp)
    80003844:	6442                	ld	s0,16(sp)
    80003846:	64a2                	ld	s1,8(sp)
    80003848:	6902                	ld	s2,0(sp)
    8000384a:	6105                	addi	sp,sp,32
    8000384c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000384e:	40bc                	lw	a5,64(s1)
    80003850:	dff1                	beqz	a5,8000382c <iput+0x26>
    80003852:	04a49783          	lh	a5,74(s1)
    80003856:	fbf9                	bnez	a5,8000382c <iput+0x26>
    acquiresleep(&ip->lock);
    80003858:	01048913          	addi	s2,s1,16
    8000385c:	854a                	mv	a0,s2
    8000385e:	00001097          	auipc	ra,0x1
    80003862:	abe080e7          	jalr	-1346(ra) # 8000431c <acquiresleep>
    release(&itable.lock);
    80003866:	0001c517          	auipc	a0,0x1c
    8000386a:	f6250513          	addi	a0,a0,-158 # 8001f7c8 <itable>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	416080e7          	jalr	1046(ra) # 80000c84 <release>
    itrunc(ip);
    80003876:	8526                	mv	a0,s1
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	ee2080e7          	jalr	-286(ra) # 8000375a <itrunc>
    ip->type = 0;
    80003880:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003884:	8526                	mv	a0,s1
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	cfa080e7          	jalr	-774(ra) # 80003580 <iupdate>
    ip->valid = 0;
    8000388e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003892:	854a                	mv	a0,s2
    80003894:	00001097          	auipc	ra,0x1
    80003898:	ade080e7          	jalr	-1314(ra) # 80004372 <releasesleep>
    acquire(&itable.lock);
    8000389c:	0001c517          	auipc	a0,0x1c
    800038a0:	f2c50513          	addi	a0,a0,-212 # 8001f7c8 <itable>
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	32c080e7          	jalr	812(ra) # 80000bd0 <acquire>
    800038ac:	b741                	j	8000382c <iput+0x26>

00000000800038ae <iunlockput>:
{
    800038ae:	1101                	addi	sp,sp,-32
    800038b0:	ec06                	sd	ra,24(sp)
    800038b2:	e822                	sd	s0,16(sp)
    800038b4:	e426                	sd	s1,8(sp)
    800038b6:	1000                	addi	s0,sp,32
    800038b8:	84aa                	mv	s1,a0
  iunlock(ip);
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	e54080e7          	jalr	-428(ra) # 8000370e <iunlock>
  iput(ip);
    800038c2:	8526                	mv	a0,s1
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	f42080e7          	jalr	-190(ra) # 80003806 <iput>
}
    800038cc:	60e2                	ld	ra,24(sp)
    800038ce:	6442                	ld	s0,16(sp)
    800038d0:	64a2                	ld	s1,8(sp)
    800038d2:	6105                	addi	sp,sp,32
    800038d4:	8082                	ret

00000000800038d6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038d6:	1141                	addi	sp,sp,-16
    800038d8:	e422                	sd	s0,8(sp)
    800038da:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038dc:	411c                	lw	a5,0(a0)
    800038de:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038e0:	415c                	lw	a5,4(a0)
    800038e2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038e4:	04451783          	lh	a5,68(a0)
    800038e8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038ec:	04a51783          	lh	a5,74(a0)
    800038f0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038f4:	04c56783          	lwu	a5,76(a0)
    800038f8:	e99c                	sd	a5,16(a1)
}
    800038fa:	6422                	ld	s0,8(sp)
    800038fc:	0141                	addi	sp,sp,16
    800038fe:	8082                	ret

0000000080003900 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003900:	457c                	lw	a5,76(a0)
    80003902:	0ed7e963          	bltu	a5,a3,800039f4 <readi+0xf4>
{
    80003906:	7159                	addi	sp,sp,-112
    80003908:	f486                	sd	ra,104(sp)
    8000390a:	f0a2                	sd	s0,96(sp)
    8000390c:	eca6                	sd	s1,88(sp)
    8000390e:	e8ca                	sd	s2,80(sp)
    80003910:	e4ce                	sd	s3,72(sp)
    80003912:	e0d2                	sd	s4,64(sp)
    80003914:	fc56                	sd	s5,56(sp)
    80003916:	f85a                	sd	s6,48(sp)
    80003918:	f45e                	sd	s7,40(sp)
    8000391a:	f062                	sd	s8,32(sp)
    8000391c:	ec66                	sd	s9,24(sp)
    8000391e:	e86a                	sd	s10,16(sp)
    80003920:	e46e                	sd	s11,8(sp)
    80003922:	1880                	addi	s0,sp,112
    80003924:	8baa                	mv	s7,a0
    80003926:	8c2e                	mv	s8,a1
    80003928:	8ab2                	mv	s5,a2
    8000392a:	84b6                	mv	s1,a3
    8000392c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000392e:	9f35                	addw	a4,a4,a3
    return 0;
    80003930:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003932:	0ad76063          	bltu	a4,a3,800039d2 <readi+0xd2>
  if(off + n > ip->size)
    80003936:	00e7f463          	bgeu	a5,a4,8000393e <readi+0x3e>
    n = ip->size - off;
    8000393a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000393e:	0a0b0963          	beqz	s6,800039f0 <readi+0xf0>
    80003942:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003944:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003948:	5cfd                	li	s9,-1
    8000394a:	a82d                	j	80003984 <readi+0x84>
    8000394c:	020a1d93          	slli	s11,s4,0x20
    80003950:	020ddd93          	srli	s11,s11,0x20
    80003954:	05890613          	addi	a2,s2,88
    80003958:	86ee                	mv	a3,s11
    8000395a:	963a                	add	a2,a2,a4
    8000395c:	85d6                	mv	a1,s5
    8000395e:	8562                	mv	a0,s8
    80003960:	fffff097          	auipc	ra,0xfffff
    80003964:	a9e080e7          	jalr	-1378(ra) # 800023fe <either_copyout>
    80003968:	05950d63          	beq	a0,s9,800039c2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000396c:	854a                	mv	a0,s2
    8000396e:	fffff097          	auipc	ra,0xfffff
    80003972:	60c080e7          	jalr	1548(ra) # 80002f7a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003976:	013a09bb          	addw	s3,s4,s3
    8000397a:	009a04bb          	addw	s1,s4,s1
    8000397e:	9aee                	add	s5,s5,s11
    80003980:	0569f763          	bgeu	s3,s6,800039ce <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003984:	000ba903          	lw	s2,0(s7)
    80003988:	00a4d59b          	srliw	a1,s1,0xa
    8000398c:	855e                	mv	a0,s7
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	8ac080e7          	jalr	-1876(ra) # 8000323a <bmap>
    80003996:	0005059b          	sext.w	a1,a0
    8000399a:	854a                	mv	a0,s2
    8000399c:	fffff097          	auipc	ra,0xfffff
    800039a0:	4ae080e7          	jalr	1198(ra) # 80002e4a <bread>
    800039a4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039a6:	3ff4f713          	andi	a4,s1,1023
    800039aa:	40ed07bb          	subw	a5,s10,a4
    800039ae:	413b06bb          	subw	a3,s6,s3
    800039b2:	8a3e                	mv	s4,a5
    800039b4:	2781                	sext.w	a5,a5
    800039b6:	0006861b          	sext.w	a2,a3
    800039ba:	f8f679e3          	bgeu	a2,a5,8000394c <readi+0x4c>
    800039be:	8a36                	mv	s4,a3
    800039c0:	b771                	j	8000394c <readi+0x4c>
      brelse(bp);
    800039c2:	854a                	mv	a0,s2
    800039c4:	fffff097          	auipc	ra,0xfffff
    800039c8:	5b6080e7          	jalr	1462(ra) # 80002f7a <brelse>
      tot = -1;
    800039cc:	59fd                	li	s3,-1
  }
  return tot;
    800039ce:	0009851b          	sext.w	a0,s3
}
    800039d2:	70a6                	ld	ra,104(sp)
    800039d4:	7406                	ld	s0,96(sp)
    800039d6:	64e6                	ld	s1,88(sp)
    800039d8:	6946                	ld	s2,80(sp)
    800039da:	69a6                	ld	s3,72(sp)
    800039dc:	6a06                	ld	s4,64(sp)
    800039de:	7ae2                	ld	s5,56(sp)
    800039e0:	7b42                	ld	s6,48(sp)
    800039e2:	7ba2                	ld	s7,40(sp)
    800039e4:	7c02                	ld	s8,32(sp)
    800039e6:	6ce2                	ld	s9,24(sp)
    800039e8:	6d42                	ld	s10,16(sp)
    800039ea:	6da2                	ld	s11,8(sp)
    800039ec:	6165                	addi	sp,sp,112
    800039ee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039f0:	89da                	mv	s3,s6
    800039f2:	bff1                	j	800039ce <readi+0xce>
    return 0;
    800039f4:	4501                	li	a0,0
}
    800039f6:	8082                	ret

00000000800039f8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039f8:	457c                	lw	a5,76(a0)
    800039fa:	10d7e863          	bltu	a5,a3,80003b0a <writei+0x112>
{
    800039fe:	7159                	addi	sp,sp,-112
    80003a00:	f486                	sd	ra,104(sp)
    80003a02:	f0a2                	sd	s0,96(sp)
    80003a04:	eca6                	sd	s1,88(sp)
    80003a06:	e8ca                	sd	s2,80(sp)
    80003a08:	e4ce                	sd	s3,72(sp)
    80003a0a:	e0d2                	sd	s4,64(sp)
    80003a0c:	fc56                	sd	s5,56(sp)
    80003a0e:	f85a                	sd	s6,48(sp)
    80003a10:	f45e                	sd	s7,40(sp)
    80003a12:	f062                	sd	s8,32(sp)
    80003a14:	ec66                	sd	s9,24(sp)
    80003a16:	e86a                	sd	s10,16(sp)
    80003a18:	e46e                	sd	s11,8(sp)
    80003a1a:	1880                	addi	s0,sp,112
    80003a1c:	8b2a                	mv	s6,a0
    80003a1e:	8c2e                	mv	s8,a1
    80003a20:	8ab2                	mv	s5,a2
    80003a22:	8936                	mv	s2,a3
    80003a24:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a26:	00e687bb          	addw	a5,a3,a4
    80003a2a:	0ed7e263          	bltu	a5,a3,80003b0e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a2e:	00043737          	lui	a4,0x43
    80003a32:	0ef76063          	bltu	a4,a5,80003b12 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a36:	0c0b8863          	beqz	s7,80003b06 <writei+0x10e>
    80003a3a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a3c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a40:	5cfd                	li	s9,-1
    80003a42:	a091                	j	80003a86 <writei+0x8e>
    80003a44:	02099d93          	slli	s11,s3,0x20
    80003a48:	020ddd93          	srli	s11,s11,0x20
    80003a4c:	05848513          	addi	a0,s1,88
    80003a50:	86ee                	mv	a3,s11
    80003a52:	8656                	mv	a2,s5
    80003a54:	85e2                	mv	a1,s8
    80003a56:	953a                	add	a0,a0,a4
    80003a58:	fffff097          	auipc	ra,0xfffff
    80003a5c:	9fc080e7          	jalr	-1540(ra) # 80002454 <either_copyin>
    80003a60:	07950263          	beq	a0,s9,80003ac4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a64:	8526                	mv	a0,s1
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	798080e7          	jalr	1944(ra) # 800041fe <log_write>
    brelse(bp);
    80003a6e:	8526                	mv	a0,s1
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	50a080e7          	jalr	1290(ra) # 80002f7a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a78:	01498a3b          	addw	s4,s3,s4
    80003a7c:	0129893b          	addw	s2,s3,s2
    80003a80:	9aee                	add	s5,s5,s11
    80003a82:	057a7663          	bgeu	s4,s7,80003ace <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a86:	000b2483          	lw	s1,0(s6)
    80003a8a:	00a9559b          	srliw	a1,s2,0xa
    80003a8e:	855a                	mv	a0,s6
    80003a90:	fffff097          	auipc	ra,0xfffff
    80003a94:	7aa080e7          	jalr	1962(ra) # 8000323a <bmap>
    80003a98:	0005059b          	sext.w	a1,a0
    80003a9c:	8526                	mv	a0,s1
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	3ac080e7          	jalr	940(ra) # 80002e4a <bread>
    80003aa6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa8:	3ff97713          	andi	a4,s2,1023
    80003aac:	40ed07bb          	subw	a5,s10,a4
    80003ab0:	414b86bb          	subw	a3,s7,s4
    80003ab4:	89be                	mv	s3,a5
    80003ab6:	2781                	sext.w	a5,a5
    80003ab8:	0006861b          	sext.w	a2,a3
    80003abc:	f8f674e3          	bgeu	a2,a5,80003a44 <writei+0x4c>
    80003ac0:	89b6                	mv	s3,a3
    80003ac2:	b749                	j	80003a44 <writei+0x4c>
      brelse(bp);
    80003ac4:	8526                	mv	a0,s1
    80003ac6:	fffff097          	auipc	ra,0xfffff
    80003aca:	4b4080e7          	jalr	1204(ra) # 80002f7a <brelse>
  }

  if(off > ip->size)
    80003ace:	04cb2783          	lw	a5,76(s6)
    80003ad2:	0127f463          	bgeu	a5,s2,80003ada <writei+0xe2>
    ip->size = off;
    80003ad6:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ada:	855a                	mv	a0,s6
    80003adc:	00000097          	auipc	ra,0x0
    80003ae0:	aa4080e7          	jalr	-1372(ra) # 80003580 <iupdate>

  return tot;
    80003ae4:	000a051b          	sext.w	a0,s4
}
    80003ae8:	70a6                	ld	ra,104(sp)
    80003aea:	7406                	ld	s0,96(sp)
    80003aec:	64e6                	ld	s1,88(sp)
    80003aee:	6946                	ld	s2,80(sp)
    80003af0:	69a6                	ld	s3,72(sp)
    80003af2:	6a06                	ld	s4,64(sp)
    80003af4:	7ae2                	ld	s5,56(sp)
    80003af6:	7b42                	ld	s6,48(sp)
    80003af8:	7ba2                	ld	s7,40(sp)
    80003afa:	7c02                	ld	s8,32(sp)
    80003afc:	6ce2                	ld	s9,24(sp)
    80003afe:	6d42                	ld	s10,16(sp)
    80003b00:	6da2                	ld	s11,8(sp)
    80003b02:	6165                	addi	sp,sp,112
    80003b04:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b06:	8a5e                	mv	s4,s7
    80003b08:	bfc9                	j	80003ada <writei+0xe2>
    return -1;
    80003b0a:	557d                	li	a0,-1
}
    80003b0c:	8082                	ret
    return -1;
    80003b0e:	557d                	li	a0,-1
    80003b10:	bfe1                	j	80003ae8 <writei+0xf0>
    return -1;
    80003b12:	557d                	li	a0,-1
    80003b14:	bfd1                	j	80003ae8 <writei+0xf0>

0000000080003b16 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b16:	1141                	addi	sp,sp,-16
    80003b18:	e406                	sd	ra,8(sp)
    80003b1a:	e022                	sd	s0,0(sp)
    80003b1c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b1e:	4639                	li	a2,14
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	27c080e7          	jalr	636(ra) # 80000d9c <strncmp>
}
    80003b28:	60a2                	ld	ra,8(sp)
    80003b2a:	6402                	ld	s0,0(sp)
    80003b2c:	0141                	addi	sp,sp,16
    80003b2e:	8082                	ret

0000000080003b30 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b30:	7139                	addi	sp,sp,-64
    80003b32:	fc06                	sd	ra,56(sp)
    80003b34:	f822                	sd	s0,48(sp)
    80003b36:	f426                	sd	s1,40(sp)
    80003b38:	f04a                	sd	s2,32(sp)
    80003b3a:	ec4e                	sd	s3,24(sp)
    80003b3c:	e852                	sd	s4,16(sp)
    80003b3e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b40:	04451703          	lh	a4,68(a0)
    80003b44:	4785                	li	a5,1
    80003b46:	00f71a63          	bne	a4,a5,80003b5a <dirlookup+0x2a>
    80003b4a:	892a                	mv	s2,a0
    80003b4c:	89ae                	mv	s3,a1
    80003b4e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b50:	457c                	lw	a5,76(a0)
    80003b52:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b54:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b56:	e79d                	bnez	a5,80003b84 <dirlookup+0x54>
    80003b58:	a8a5                	j	80003bd0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b5a:	00005517          	auipc	a0,0x5
    80003b5e:	aa650513          	addi	a0,a0,-1370 # 80008600 <syscalls+0x1b8>
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	9d8080e7          	jalr	-1576(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003b6a:	00005517          	auipc	a0,0x5
    80003b6e:	aae50513          	addi	a0,a0,-1362 # 80008618 <syscalls+0x1d0>
    80003b72:	ffffd097          	auipc	ra,0xffffd
    80003b76:	9c8080e7          	jalr	-1592(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b7a:	24c1                	addiw	s1,s1,16
    80003b7c:	04c92783          	lw	a5,76(s2)
    80003b80:	04f4f763          	bgeu	s1,a5,80003bce <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b84:	4741                	li	a4,16
    80003b86:	86a6                	mv	a3,s1
    80003b88:	fc040613          	addi	a2,s0,-64
    80003b8c:	4581                	li	a1,0
    80003b8e:	854a                	mv	a0,s2
    80003b90:	00000097          	auipc	ra,0x0
    80003b94:	d70080e7          	jalr	-656(ra) # 80003900 <readi>
    80003b98:	47c1                	li	a5,16
    80003b9a:	fcf518e3          	bne	a0,a5,80003b6a <dirlookup+0x3a>
    if(de.inum == 0)
    80003b9e:	fc045783          	lhu	a5,-64(s0)
    80003ba2:	dfe1                	beqz	a5,80003b7a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ba4:	fc240593          	addi	a1,s0,-62
    80003ba8:	854e                	mv	a0,s3
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	f6c080e7          	jalr	-148(ra) # 80003b16 <namecmp>
    80003bb2:	f561                	bnez	a0,80003b7a <dirlookup+0x4a>
      if(poff)
    80003bb4:	000a0463          	beqz	s4,80003bbc <dirlookup+0x8c>
        *poff = off;
    80003bb8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bbc:	fc045583          	lhu	a1,-64(s0)
    80003bc0:	00092503          	lw	a0,0(s2)
    80003bc4:	fffff097          	auipc	ra,0xfffff
    80003bc8:	752080e7          	jalr	1874(ra) # 80003316 <iget>
    80003bcc:	a011                	j	80003bd0 <dirlookup+0xa0>
  return 0;
    80003bce:	4501                	li	a0,0
}
    80003bd0:	70e2                	ld	ra,56(sp)
    80003bd2:	7442                	ld	s0,48(sp)
    80003bd4:	74a2                	ld	s1,40(sp)
    80003bd6:	7902                	ld	s2,32(sp)
    80003bd8:	69e2                	ld	s3,24(sp)
    80003bda:	6a42                	ld	s4,16(sp)
    80003bdc:	6121                	addi	sp,sp,64
    80003bde:	8082                	ret

0000000080003be0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003be0:	711d                	addi	sp,sp,-96
    80003be2:	ec86                	sd	ra,88(sp)
    80003be4:	e8a2                	sd	s0,80(sp)
    80003be6:	e4a6                	sd	s1,72(sp)
    80003be8:	e0ca                	sd	s2,64(sp)
    80003bea:	fc4e                	sd	s3,56(sp)
    80003bec:	f852                	sd	s4,48(sp)
    80003bee:	f456                	sd	s5,40(sp)
    80003bf0:	f05a                	sd	s6,32(sp)
    80003bf2:	ec5e                	sd	s7,24(sp)
    80003bf4:	e862                	sd	s8,16(sp)
    80003bf6:	e466                	sd	s9,8(sp)
    80003bf8:	e06a                	sd	s10,0(sp)
    80003bfa:	1080                	addi	s0,sp,96
    80003bfc:	84aa                	mv	s1,a0
    80003bfe:	8b2e                	mv	s6,a1
    80003c00:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c02:	00054703          	lbu	a4,0(a0)
    80003c06:	02f00793          	li	a5,47
    80003c0a:	02f70363          	beq	a4,a5,80003c30 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c0e:	ffffe097          	auipc	ra,0xffffe
    80003c12:	d88080e7          	jalr	-632(ra) # 80001996 <myproc>
    80003c16:	15053503          	ld	a0,336(a0)
    80003c1a:	00000097          	auipc	ra,0x0
    80003c1e:	9f4080e7          	jalr	-1548(ra) # 8000360e <idup>
    80003c22:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c24:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c28:	4cb5                	li	s9,13
  len = path - s;
    80003c2a:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c2c:	4c05                	li	s8,1
    80003c2e:	a87d                	j	80003cec <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003c30:	4585                	li	a1,1
    80003c32:	4505                	li	a0,1
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	6e2080e7          	jalr	1762(ra) # 80003316 <iget>
    80003c3c:	8a2a                	mv	s4,a0
    80003c3e:	b7dd                	j	80003c24 <namex+0x44>
      iunlockput(ip);
    80003c40:	8552                	mv	a0,s4
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	c6c080e7          	jalr	-916(ra) # 800038ae <iunlockput>
      return 0;
    80003c4a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c4c:	8552                	mv	a0,s4
    80003c4e:	60e6                	ld	ra,88(sp)
    80003c50:	6446                	ld	s0,80(sp)
    80003c52:	64a6                	ld	s1,72(sp)
    80003c54:	6906                	ld	s2,64(sp)
    80003c56:	79e2                	ld	s3,56(sp)
    80003c58:	7a42                	ld	s4,48(sp)
    80003c5a:	7aa2                	ld	s5,40(sp)
    80003c5c:	7b02                	ld	s6,32(sp)
    80003c5e:	6be2                	ld	s7,24(sp)
    80003c60:	6c42                	ld	s8,16(sp)
    80003c62:	6ca2                	ld	s9,8(sp)
    80003c64:	6d02                	ld	s10,0(sp)
    80003c66:	6125                	addi	sp,sp,96
    80003c68:	8082                	ret
      iunlock(ip);
    80003c6a:	8552                	mv	a0,s4
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	aa2080e7          	jalr	-1374(ra) # 8000370e <iunlock>
      return ip;
    80003c74:	bfe1                	j	80003c4c <namex+0x6c>
      iunlockput(ip);
    80003c76:	8552                	mv	a0,s4
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	c36080e7          	jalr	-970(ra) # 800038ae <iunlockput>
      return 0;
    80003c80:	8a4e                	mv	s4,s3
    80003c82:	b7e9                	j	80003c4c <namex+0x6c>
  len = path - s;
    80003c84:	40998633          	sub	a2,s3,s1
    80003c88:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003c8c:	09acd863          	bge	s9,s10,80003d1c <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003c90:	4639                	li	a2,14
    80003c92:	85a6                	mv	a1,s1
    80003c94:	8556                	mv	a0,s5
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	092080e7          	jalr	146(ra) # 80000d28 <memmove>
    80003c9e:	84ce                	mv	s1,s3
  while(*path == '/')
    80003ca0:	0004c783          	lbu	a5,0(s1)
    80003ca4:	01279763          	bne	a5,s2,80003cb2 <namex+0xd2>
    path++;
    80003ca8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003caa:	0004c783          	lbu	a5,0(s1)
    80003cae:	ff278de3          	beq	a5,s2,80003ca8 <namex+0xc8>
    ilock(ip);
    80003cb2:	8552                	mv	a0,s4
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	998080e7          	jalr	-1640(ra) # 8000364c <ilock>
    if(ip->type != T_DIR){
    80003cbc:	044a1783          	lh	a5,68(s4)
    80003cc0:	f98790e3          	bne	a5,s8,80003c40 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003cc4:	000b0563          	beqz	s6,80003cce <namex+0xee>
    80003cc8:	0004c783          	lbu	a5,0(s1)
    80003ccc:	dfd9                	beqz	a5,80003c6a <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cce:	865e                	mv	a2,s7
    80003cd0:	85d6                	mv	a1,s5
    80003cd2:	8552                	mv	a0,s4
    80003cd4:	00000097          	auipc	ra,0x0
    80003cd8:	e5c080e7          	jalr	-420(ra) # 80003b30 <dirlookup>
    80003cdc:	89aa                	mv	s3,a0
    80003cde:	dd41                	beqz	a0,80003c76 <namex+0x96>
    iunlockput(ip);
    80003ce0:	8552                	mv	a0,s4
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	bcc080e7          	jalr	-1076(ra) # 800038ae <iunlockput>
    ip = next;
    80003cea:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003cec:	0004c783          	lbu	a5,0(s1)
    80003cf0:	01279763          	bne	a5,s2,80003cfe <namex+0x11e>
    path++;
    80003cf4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cf6:	0004c783          	lbu	a5,0(s1)
    80003cfa:	ff278de3          	beq	a5,s2,80003cf4 <namex+0x114>
  if(*path == 0)
    80003cfe:	cb9d                	beqz	a5,80003d34 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003d00:	0004c783          	lbu	a5,0(s1)
    80003d04:	89a6                	mv	s3,s1
  len = path - s;
    80003d06:	8d5e                	mv	s10,s7
    80003d08:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d0a:	01278963          	beq	a5,s2,80003d1c <namex+0x13c>
    80003d0e:	dbbd                	beqz	a5,80003c84 <namex+0xa4>
    path++;
    80003d10:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003d12:	0009c783          	lbu	a5,0(s3)
    80003d16:	ff279ce3          	bne	a5,s2,80003d0e <namex+0x12e>
    80003d1a:	b7ad                	j	80003c84 <namex+0xa4>
    memmove(name, s, len);
    80003d1c:	2601                	sext.w	a2,a2
    80003d1e:	85a6                	mv	a1,s1
    80003d20:	8556                	mv	a0,s5
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	006080e7          	jalr	6(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003d2a:	9d56                	add	s10,s10,s5
    80003d2c:	000d0023          	sb	zero,0(s10)
    80003d30:	84ce                	mv	s1,s3
    80003d32:	b7bd                	j	80003ca0 <namex+0xc0>
  if(nameiparent){
    80003d34:	f00b0ce3          	beqz	s6,80003c4c <namex+0x6c>
    iput(ip);
    80003d38:	8552                	mv	a0,s4
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	acc080e7          	jalr	-1332(ra) # 80003806 <iput>
    return 0;
    80003d42:	4a01                	li	s4,0
    80003d44:	b721                	j	80003c4c <namex+0x6c>

0000000080003d46 <dirlink>:
{
    80003d46:	7139                	addi	sp,sp,-64
    80003d48:	fc06                	sd	ra,56(sp)
    80003d4a:	f822                	sd	s0,48(sp)
    80003d4c:	f426                	sd	s1,40(sp)
    80003d4e:	f04a                	sd	s2,32(sp)
    80003d50:	ec4e                	sd	s3,24(sp)
    80003d52:	e852                	sd	s4,16(sp)
    80003d54:	0080                	addi	s0,sp,64
    80003d56:	892a                	mv	s2,a0
    80003d58:	8a2e                	mv	s4,a1
    80003d5a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d5c:	4601                	li	a2,0
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	dd2080e7          	jalr	-558(ra) # 80003b30 <dirlookup>
    80003d66:	e93d                	bnez	a0,80003ddc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d68:	04c92483          	lw	s1,76(s2)
    80003d6c:	c49d                	beqz	s1,80003d9a <dirlink+0x54>
    80003d6e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d70:	4741                	li	a4,16
    80003d72:	86a6                	mv	a3,s1
    80003d74:	fc040613          	addi	a2,s0,-64
    80003d78:	4581                	li	a1,0
    80003d7a:	854a                	mv	a0,s2
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	b84080e7          	jalr	-1148(ra) # 80003900 <readi>
    80003d84:	47c1                	li	a5,16
    80003d86:	06f51163          	bne	a0,a5,80003de8 <dirlink+0xa2>
    if(de.inum == 0)
    80003d8a:	fc045783          	lhu	a5,-64(s0)
    80003d8e:	c791                	beqz	a5,80003d9a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d90:	24c1                	addiw	s1,s1,16
    80003d92:	04c92783          	lw	a5,76(s2)
    80003d96:	fcf4ede3          	bltu	s1,a5,80003d70 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d9a:	4639                	li	a2,14
    80003d9c:	85d2                	mv	a1,s4
    80003d9e:	fc240513          	addi	a0,s0,-62
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	036080e7          	jalr	54(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003daa:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dae:	4741                	li	a4,16
    80003db0:	86a6                	mv	a3,s1
    80003db2:	fc040613          	addi	a2,s0,-64
    80003db6:	4581                	li	a1,0
    80003db8:	854a                	mv	a0,s2
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	c3e080e7          	jalr	-962(ra) # 800039f8 <writei>
    80003dc2:	872a                	mv	a4,a0
    80003dc4:	47c1                	li	a5,16
  return 0;
    80003dc6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dc8:	02f71863          	bne	a4,a5,80003df8 <dirlink+0xb2>
}
    80003dcc:	70e2                	ld	ra,56(sp)
    80003dce:	7442                	ld	s0,48(sp)
    80003dd0:	74a2                	ld	s1,40(sp)
    80003dd2:	7902                	ld	s2,32(sp)
    80003dd4:	69e2                	ld	s3,24(sp)
    80003dd6:	6a42                	ld	s4,16(sp)
    80003dd8:	6121                	addi	sp,sp,64
    80003dda:	8082                	ret
    iput(ip);
    80003ddc:	00000097          	auipc	ra,0x0
    80003de0:	a2a080e7          	jalr	-1494(ra) # 80003806 <iput>
    return -1;
    80003de4:	557d                	li	a0,-1
    80003de6:	b7dd                	j	80003dcc <dirlink+0x86>
      panic("dirlink read");
    80003de8:	00005517          	auipc	a0,0x5
    80003dec:	84050513          	addi	a0,a0,-1984 # 80008628 <syscalls+0x1e0>
    80003df0:	ffffc097          	auipc	ra,0xffffc
    80003df4:	74a080e7          	jalr	1866(ra) # 8000053a <panic>
    panic("dirlink");
    80003df8:	00005517          	auipc	a0,0x5
    80003dfc:	94050513          	addi	a0,a0,-1728 # 80008738 <syscalls+0x2f0>
    80003e00:	ffffc097          	auipc	ra,0xffffc
    80003e04:	73a080e7          	jalr	1850(ra) # 8000053a <panic>

0000000080003e08 <namei>:

struct inode*
namei(char *path)
{
    80003e08:	1101                	addi	sp,sp,-32
    80003e0a:	ec06                	sd	ra,24(sp)
    80003e0c:	e822                	sd	s0,16(sp)
    80003e0e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e10:	fe040613          	addi	a2,s0,-32
    80003e14:	4581                	li	a1,0
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	dca080e7          	jalr	-566(ra) # 80003be0 <namex>
}
    80003e1e:	60e2                	ld	ra,24(sp)
    80003e20:	6442                	ld	s0,16(sp)
    80003e22:	6105                	addi	sp,sp,32
    80003e24:	8082                	ret

0000000080003e26 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e26:	1141                	addi	sp,sp,-16
    80003e28:	e406                	sd	ra,8(sp)
    80003e2a:	e022                	sd	s0,0(sp)
    80003e2c:	0800                	addi	s0,sp,16
    80003e2e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e30:	4585                	li	a1,1
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	dae080e7          	jalr	-594(ra) # 80003be0 <namex>
}
    80003e3a:	60a2                	ld	ra,8(sp)
    80003e3c:	6402                	ld	s0,0(sp)
    80003e3e:	0141                	addi	sp,sp,16
    80003e40:	8082                	ret

0000000080003e42 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e42:	1101                	addi	sp,sp,-32
    80003e44:	ec06                	sd	ra,24(sp)
    80003e46:	e822                	sd	s0,16(sp)
    80003e48:	e426                	sd	s1,8(sp)
    80003e4a:	e04a                	sd	s2,0(sp)
    80003e4c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e4e:	0001d917          	auipc	s2,0x1d
    80003e52:	42290913          	addi	s2,s2,1058 # 80021270 <log>
    80003e56:	01892583          	lw	a1,24(s2)
    80003e5a:	02892503          	lw	a0,40(s2)
    80003e5e:	fffff097          	auipc	ra,0xfffff
    80003e62:	fec080e7          	jalr	-20(ra) # 80002e4a <bread>
    80003e66:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e68:	02c92683          	lw	a3,44(s2)
    80003e6c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e6e:	02d05863          	blez	a3,80003e9e <write_head+0x5c>
    80003e72:	0001d797          	auipc	a5,0x1d
    80003e76:	42e78793          	addi	a5,a5,1070 # 800212a0 <log+0x30>
    80003e7a:	05c50713          	addi	a4,a0,92
    80003e7e:	36fd                	addiw	a3,a3,-1
    80003e80:	02069613          	slli	a2,a3,0x20
    80003e84:	01e65693          	srli	a3,a2,0x1e
    80003e88:	0001d617          	auipc	a2,0x1d
    80003e8c:	41c60613          	addi	a2,a2,1052 # 800212a4 <log+0x34>
    80003e90:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e92:	4390                	lw	a2,0(a5)
    80003e94:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e96:	0791                	addi	a5,a5,4
    80003e98:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003e9a:	fed79ce3          	bne	a5,a3,80003e92 <write_head+0x50>
  }
  bwrite(buf);
    80003e9e:	8526                	mv	a0,s1
    80003ea0:	fffff097          	auipc	ra,0xfffff
    80003ea4:	09c080e7          	jalr	156(ra) # 80002f3c <bwrite>
  brelse(buf);
    80003ea8:	8526                	mv	a0,s1
    80003eaa:	fffff097          	auipc	ra,0xfffff
    80003eae:	0d0080e7          	jalr	208(ra) # 80002f7a <brelse>
}
    80003eb2:	60e2                	ld	ra,24(sp)
    80003eb4:	6442                	ld	s0,16(sp)
    80003eb6:	64a2                	ld	s1,8(sp)
    80003eb8:	6902                	ld	s2,0(sp)
    80003eba:	6105                	addi	sp,sp,32
    80003ebc:	8082                	ret

0000000080003ebe <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ebe:	0001d797          	auipc	a5,0x1d
    80003ec2:	3de7a783          	lw	a5,990(a5) # 8002129c <log+0x2c>
    80003ec6:	0af05d63          	blez	a5,80003f80 <install_trans+0xc2>
{
    80003eca:	7139                	addi	sp,sp,-64
    80003ecc:	fc06                	sd	ra,56(sp)
    80003ece:	f822                	sd	s0,48(sp)
    80003ed0:	f426                	sd	s1,40(sp)
    80003ed2:	f04a                	sd	s2,32(sp)
    80003ed4:	ec4e                	sd	s3,24(sp)
    80003ed6:	e852                	sd	s4,16(sp)
    80003ed8:	e456                	sd	s5,8(sp)
    80003eda:	e05a                	sd	s6,0(sp)
    80003edc:	0080                	addi	s0,sp,64
    80003ede:	8b2a                	mv	s6,a0
    80003ee0:	0001da97          	auipc	s5,0x1d
    80003ee4:	3c0a8a93          	addi	s5,s5,960 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ee8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003eea:	0001d997          	auipc	s3,0x1d
    80003eee:	38698993          	addi	s3,s3,902 # 80021270 <log>
    80003ef2:	a00d                	j	80003f14 <install_trans+0x56>
    brelse(lbuf);
    80003ef4:	854a                	mv	a0,s2
    80003ef6:	fffff097          	auipc	ra,0xfffff
    80003efa:	084080e7          	jalr	132(ra) # 80002f7a <brelse>
    brelse(dbuf);
    80003efe:	8526                	mv	a0,s1
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	07a080e7          	jalr	122(ra) # 80002f7a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f08:	2a05                	addiw	s4,s4,1
    80003f0a:	0a91                	addi	s5,s5,4
    80003f0c:	02c9a783          	lw	a5,44(s3)
    80003f10:	04fa5e63          	bge	s4,a5,80003f6c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f14:	0189a583          	lw	a1,24(s3)
    80003f18:	014585bb          	addw	a1,a1,s4
    80003f1c:	2585                	addiw	a1,a1,1
    80003f1e:	0289a503          	lw	a0,40(s3)
    80003f22:	fffff097          	auipc	ra,0xfffff
    80003f26:	f28080e7          	jalr	-216(ra) # 80002e4a <bread>
    80003f2a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f2c:	000aa583          	lw	a1,0(s5)
    80003f30:	0289a503          	lw	a0,40(s3)
    80003f34:	fffff097          	auipc	ra,0xfffff
    80003f38:	f16080e7          	jalr	-234(ra) # 80002e4a <bread>
    80003f3c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f3e:	40000613          	li	a2,1024
    80003f42:	05890593          	addi	a1,s2,88
    80003f46:	05850513          	addi	a0,a0,88
    80003f4a:	ffffd097          	auipc	ra,0xffffd
    80003f4e:	dde080e7          	jalr	-546(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f52:	8526                	mv	a0,s1
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	fe8080e7          	jalr	-24(ra) # 80002f3c <bwrite>
    if(recovering == 0)
    80003f5c:	f80b1ce3          	bnez	s6,80003ef4 <install_trans+0x36>
      bunpin(dbuf);
    80003f60:	8526                	mv	a0,s1
    80003f62:	fffff097          	auipc	ra,0xfffff
    80003f66:	0f2080e7          	jalr	242(ra) # 80003054 <bunpin>
    80003f6a:	b769                	j	80003ef4 <install_trans+0x36>
}
    80003f6c:	70e2                	ld	ra,56(sp)
    80003f6e:	7442                	ld	s0,48(sp)
    80003f70:	74a2                	ld	s1,40(sp)
    80003f72:	7902                	ld	s2,32(sp)
    80003f74:	69e2                	ld	s3,24(sp)
    80003f76:	6a42                	ld	s4,16(sp)
    80003f78:	6aa2                	ld	s5,8(sp)
    80003f7a:	6b02                	ld	s6,0(sp)
    80003f7c:	6121                	addi	sp,sp,64
    80003f7e:	8082                	ret
    80003f80:	8082                	ret

0000000080003f82 <initlog>:
{
    80003f82:	7179                	addi	sp,sp,-48
    80003f84:	f406                	sd	ra,40(sp)
    80003f86:	f022                	sd	s0,32(sp)
    80003f88:	ec26                	sd	s1,24(sp)
    80003f8a:	e84a                	sd	s2,16(sp)
    80003f8c:	e44e                	sd	s3,8(sp)
    80003f8e:	1800                	addi	s0,sp,48
    80003f90:	892a                	mv	s2,a0
    80003f92:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f94:	0001d497          	auipc	s1,0x1d
    80003f98:	2dc48493          	addi	s1,s1,732 # 80021270 <log>
    80003f9c:	00004597          	auipc	a1,0x4
    80003fa0:	69c58593          	addi	a1,a1,1692 # 80008638 <syscalls+0x1f0>
    80003fa4:	8526                	mv	a0,s1
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	b9a080e7          	jalr	-1126(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80003fae:	0149a583          	lw	a1,20(s3)
    80003fb2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fb4:	0109a783          	lw	a5,16(s3)
    80003fb8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fba:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fbe:	854a                	mv	a0,s2
    80003fc0:	fffff097          	auipc	ra,0xfffff
    80003fc4:	e8a080e7          	jalr	-374(ra) # 80002e4a <bread>
  log.lh.n = lh->n;
    80003fc8:	4d34                	lw	a3,88(a0)
    80003fca:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fcc:	02d05663          	blez	a3,80003ff8 <initlog+0x76>
    80003fd0:	05c50793          	addi	a5,a0,92
    80003fd4:	0001d717          	auipc	a4,0x1d
    80003fd8:	2cc70713          	addi	a4,a4,716 # 800212a0 <log+0x30>
    80003fdc:	36fd                	addiw	a3,a3,-1
    80003fde:	02069613          	slli	a2,a3,0x20
    80003fe2:	01e65693          	srli	a3,a2,0x1e
    80003fe6:	06050613          	addi	a2,a0,96
    80003fea:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003fec:	4390                	lw	a2,0(a5)
    80003fee:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ff0:	0791                	addi	a5,a5,4
    80003ff2:	0711                	addi	a4,a4,4
    80003ff4:	fed79ce3          	bne	a5,a3,80003fec <initlog+0x6a>
  brelse(buf);
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	f82080e7          	jalr	-126(ra) # 80002f7a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004000:	4505                	li	a0,1
    80004002:	00000097          	auipc	ra,0x0
    80004006:	ebc080e7          	jalr	-324(ra) # 80003ebe <install_trans>
  log.lh.n = 0;
    8000400a:	0001d797          	auipc	a5,0x1d
    8000400e:	2807a923          	sw	zero,658(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004012:	00000097          	auipc	ra,0x0
    80004016:	e30080e7          	jalr	-464(ra) # 80003e42 <write_head>
}
    8000401a:	70a2                	ld	ra,40(sp)
    8000401c:	7402                	ld	s0,32(sp)
    8000401e:	64e2                	ld	s1,24(sp)
    80004020:	6942                	ld	s2,16(sp)
    80004022:	69a2                	ld	s3,8(sp)
    80004024:	6145                	addi	sp,sp,48
    80004026:	8082                	ret

0000000080004028 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004028:	1101                	addi	sp,sp,-32
    8000402a:	ec06                	sd	ra,24(sp)
    8000402c:	e822                	sd	s0,16(sp)
    8000402e:	e426                	sd	s1,8(sp)
    80004030:	e04a                	sd	s2,0(sp)
    80004032:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004034:	0001d517          	auipc	a0,0x1d
    80004038:	23c50513          	addi	a0,a0,572 # 80021270 <log>
    8000403c:	ffffd097          	auipc	ra,0xffffd
    80004040:	b94080e7          	jalr	-1132(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80004044:	0001d497          	auipc	s1,0x1d
    80004048:	22c48493          	addi	s1,s1,556 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000404c:	4979                	li	s2,30
    8000404e:	a039                	j	8000405c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004050:	85a6                	mv	a1,s1
    80004052:	8526                	mv	a0,s1
    80004054:	ffffe097          	auipc	ra,0xffffe
    80004058:	006080e7          	jalr	6(ra) # 8000205a <sleep>
    if(log.committing){
    8000405c:	50dc                	lw	a5,36(s1)
    8000405e:	fbed                	bnez	a5,80004050 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004060:	5098                	lw	a4,32(s1)
    80004062:	2705                	addiw	a4,a4,1
    80004064:	0007069b          	sext.w	a3,a4
    80004068:	0027179b          	slliw	a5,a4,0x2
    8000406c:	9fb9                	addw	a5,a5,a4
    8000406e:	0017979b          	slliw	a5,a5,0x1
    80004072:	54d8                	lw	a4,44(s1)
    80004074:	9fb9                	addw	a5,a5,a4
    80004076:	00f95963          	bge	s2,a5,80004088 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000407a:	85a6                	mv	a1,s1
    8000407c:	8526                	mv	a0,s1
    8000407e:	ffffe097          	auipc	ra,0xffffe
    80004082:	fdc080e7          	jalr	-36(ra) # 8000205a <sleep>
    80004086:	bfd9                	j	8000405c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004088:	0001d517          	auipc	a0,0x1d
    8000408c:	1e850513          	addi	a0,a0,488 # 80021270 <log>
    80004090:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004092:	ffffd097          	auipc	ra,0xffffd
    80004096:	bf2080e7          	jalr	-1038(ra) # 80000c84 <release>
      break;
    }
  }
}
    8000409a:	60e2                	ld	ra,24(sp)
    8000409c:	6442                	ld	s0,16(sp)
    8000409e:	64a2                	ld	s1,8(sp)
    800040a0:	6902                	ld	s2,0(sp)
    800040a2:	6105                	addi	sp,sp,32
    800040a4:	8082                	ret

00000000800040a6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040a6:	7139                	addi	sp,sp,-64
    800040a8:	fc06                	sd	ra,56(sp)
    800040aa:	f822                	sd	s0,48(sp)
    800040ac:	f426                	sd	s1,40(sp)
    800040ae:	f04a                	sd	s2,32(sp)
    800040b0:	ec4e                	sd	s3,24(sp)
    800040b2:	e852                	sd	s4,16(sp)
    800040b4:	e456                	sd	s5,8(sp)
    800040b6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040b8:	0001d497          	auipc	s1,0x1d
    800040bc:	1b848493          	addi	s1,s1,440 # 80021270 <log>
    800040c0:	8526                	mv	a0,s1
    800040c2:	ffffd097          	auipc	ra,0xffffd
    800040c6:	b0e080e7          	jalr	-1266(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    800040ca:	509c                	lw	a5,32(s1)
    800040cc:	37fd                	addiw	a5,a5,-1
    800040ce:	0007891b          	sext.w	s2,a5
    800040d2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040d4:	50dc                	lw	a5,36(s1)
    800040d6:	e7b9                	bnez	a5,80004124 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040d8:	04091e63          	bnez	s2,80004134 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800040dc:	0001d497          	auipc	s1,0x1d
    800040e0:	19448493          	addi	s1,s1,404 # 80021270 <log>
    800040e4:	4785                	li	a5,1
    800040e6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040e8:	8526                	mv	a0,s1
    800040ea:	ffffd097          	auipc	ra,0xffffd
    800040ee:	b9a080e7          	jalr	-1126(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040f2:	54dc                	lw	a5,44(s1)
    800040f4:	06f04763          	bgtz	a5,80004162 <end_op+0xbc>
    acquire(&log.lock);
    800040f8:	0001d497          	auipc	s1,0x1d
    800040fc:	17848493          	addi	s1,s1,376 # 80021270 <log>
    80004100:	8526                	mv	a0,s1
    80004102:	ffffd097          	auipc	ra,0xffffd
    80004106:	ace080e7          	jalr	-1330(ra) # 80000bd0 <acquire>
    log.committing = 0;
    8000410a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000410e:	8526                	mv	a0,s1
    80004110:	ffffe097          	auipc	ra,0xffffe
    80004114:	0d6080e7          	jalr	214(ra) # 800021e6 <wakeup>
    release(&log.lock);
    80004118:	8526                	mv	a0,s1
    8000411a:	ffffd097          	auipc	ra,0xffffd
    8000411e:	b6a080e7          	jalr	-1174(ra) # 80000c84 <release>
}
    80004122:	a03d                	j	80004150 <end_op+0xaa>
    panic("log.committing");
    80004124:	00004517          	auipc	a0,0x4
    80004128:	51c50513          	addi	a0,a0,1308 # 80008640 <syscalls+0x1f8>
    8000412c:	ffffc097          	auipc	ra,0xffffc
    80004130:	40e080e7          	jalr	1038(ra) # 8000053a <panic>
    wakeup(&log);
    80004134:	0001d497          	auipc	s1,0x1d
    80004138:	13c48493          	addi	s1,s1,316 # 80021270 <log>
    8000413c:	8526                	mv	a0,s1
    8000413e:	ffffe097          	auipc	ra,0xffffe
    80004142:	0a8080e7          	jalr	168(ra) # 800021e6 <wakeup>
  release(&log.lock);
    80004146:	8526                	mv	a0,s1
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	b3c080e7          	jalr	-1220(ra) # 80000c84 <release>
}
    80004150:	70e2                	ld	ra,56(sp)
    80004152:	7442                	ld	s0,48(sp)
    80004154:	74a2                	ld	s1,40(sp)
    80004156:	7902                	ld	s2,32(sp)
    80004158:	69e2                	ld	s3,24(sp)
    8000415a:	6a42                	ld	s4,16(sp)
    8000415c:	6aa2                	ld	s5,8(sp)
    8000415e:	6121                	addi	sp,sp,64
    80004160:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004162:	0001da97          	auipc	s5,0x1d
    80004166:	13ea8a93          	addi	s5,s5,318 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000416a:	0001da17          	auipc	s4,0x1d
    8000416e:	106a0a13          	addi	s4,s4,262 # 80021270 <log>
    80004172:	018a2583          	lw	a1,24(s4)
    80004176:	012585bb          	addw	a1,a1,s2
    8000417a:	2585                	addiw	a1,a1,1
    8000417c:	028a2503          	lw	a0,40(s4)
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	cca080e7          	jalr	-822(ra) # 80002e4a <bread>
    80004188:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000418a:	000aa583          	lw	a1,0(s5)
    8000418e:	028a2503          	lw	a0,40(s4)
    80004192:	fffff097          	auipc	ra,0xfffff
    80004196:	cb8080e7          	jalr	-840(ra) # 80002e4a <bread>
    8000419a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000419c:	40000613          	li	a2,1024
    800041a0:	05850593          	addi	a1,a0,88
    800041a4:	05848513          	addi	a0,s1,88
    800041a8:	ffffd097          	auipc	ra,0xffffd
    800041ac:	b80080e7          	jalr	-1152(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    800041b0:	8526                	mv	a0,s1
    800041b2:	fffff097          	auipc	ra,0xfffff
    800041b6:	d8a080e7          	jalr	-630(ra) # 80002f3c <bwrite>
    brelse(from);
    800041ba:	854e                	mv	a0,s3
    800041bc:	fffff097          	auipc	ra,0xfffff
    800041c0:	dbe080e7          	jalr	-578(ra) # 80002f7a <brelse>
    brelse(to);
    800041c4:	8526                	mv	a0,s1
    800041c6:	fffff097          	auipc	ra,0xfffff
    800041ca:	db4080e7          	jalr	-588(ra) # 80002f7a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ce:	2905                	addiw	s2,s2,1
    800041d0:	0a91                	addi	s5,s5,4
    800041d2:	02ca2783          	lw	a5,44(s4)
    800041d6:	f8f94ee3          	blt	s2,a5,80004172 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041da:	00000097          	auipc	ra,0x0
    800041de:	c68080e7          	jalr	-920(ra) # 80003e42 <write_head>
    install_trans(0); // Now install writes to home locations
    800041e2:	4501                	li	a0,0
    800041e4:	00000097          	auipc	ra,0x0
    800041e8:	cda080e7          	jalr	-806(ra) # 80003ebe <install_trans>
    log.lh.n = 0;
    800041ec:	0001d797          	auipc	a5,0x1d
    800041f0:	0a07a823          	sw	zero,176(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041f4:	00000097          	auipc	ra,0x0
    800041f8:	c4e080e7          	jalr	-946(ra) # 80003e42 <write_head>
    800041fc:	bdf5                	j	800040f8 <end_op+0x52>

00000000800041fe <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041fe:	1101                	addi	sp,sp,-32
    80004200:	ec06                	sd	ra,24(sp)
    80004202:	e822                	sd	s0,16(sp)
    80004204:	e426                	sd	s1,8(sp)
    80004206:	e04a                	sd	s2,0(sp)
    80004208:	1000                	addi	s0,sp,32
    8000420a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000420c:	0001d917          	auipc	s2,0x1d
    80004210:	06490913          	addi	s2,s2,100 # 80021270 <log>
    80004214:	854a                	mv	a0,s2
    80004216:	ffffd097          	auipc	ra,0xffffd
    8000421a:	9ba080e7          	jalr	-1606(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000421e:	02c92603          	lw	a2,44(s2)
    80004222:	47f5                	li	a5,29
    80004224:	06c7c563          	blt	a5,a2,8000428e <log_write+0x90>
    80004228:	0001d797          	auipc	a5,0x1d
    8000422c:	0647a783          	lw	a5,100(a5) # 8002128c <log+0x1c>
    80004230:	37fd                	addiw	a5,a5,-1
    80004232:	04f65e63          	bge	a2,a5,8000428e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004236:	0001d797          	auipc	a5,0x1d
    8000423a:	05a7a783          	lw	a5,90(a5) # 80021290 <log+0x20>
    8000423e:	06f05063          	blez	a5,8000429e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004242:	4781                	li	a5,0
    80004244:	06c05563          	blez	a2,800042ae <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004248:	44cc                	lw	a1,12(s1)
    8000424a:	0001d717          	auipc	a4,0x1d
    8000424e:	05670713          	addi	a4,a4,86 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004252:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004254:	4314                	lw	a3,0(a4)
    80004256:	04b68c63          	beq	a3,a1,800042ae <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000425a:	2785                	addiw	a5,a5,1
    8000425c:	0711                	addi	a4,a4,4
    8000425e:	fef61be3          	bne	a2,a5,80004254 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004262:	0621                	addi	a2,a2,8
    80004264:	060a                	slli	a2,a2,0x2
    80004266:	0001d797          	auipc	a5,0x1d
    8000426a:	00a78793          	addi	a5,a5,10 # 80021270 <log>
    8000426e:	97b2                	add	a5,a5,a2
    80004270:	44d8                	lw	a4,12(s1)
    80004272:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004274:	8526                	mv	a0,s1
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	da2080e7          	jalr	-606(ra) # 80003018 <bpin>
    log.lh.n++;
    8000427e:	0001d717          	auipc	a4,0x1d
    80004282:	ff270713          	addi	a4,a4,-14 # 80021270 <log>
    80004286:	575c                	lw	a5,44(a4)
    80004288:	2785                	addiw	a5,a5,1
    8000428a:	d75c                	sw	a5,44(a4)
    8000428c:	a82d                	j	800042c6 <log_write+0xc8>
    panic("too big a transaction");
    8000428e:	00004517          	auipc	a0,0x4
    80004292:	3c250513          	addi	a0,a0,962 # 80008650 <syscalls+0x208>
    80004296:	ffffc097          	auipc	ra,0xffffc
    8000429a:	2a4080e7          	jalr	676(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    8000429e:	00004517          	auipc	a0,0x4
    800042a2:	3ca50513          	addi	a0,a0,970 # 80008668 <syscalls+0x220>
    800042a6:	ffffc097          	auipc	ra,0xffffc
    800042aa:	294080e7          	jalr	660(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    800042ae:	00878693          	addi	a3,a5,8
    800042b2:	068a                	slli	a3,a3,0x2
    800042b4:	0001d717          	auipc	a4,0x1d
    800042b8:	fbc70713          	addi	a4,a4,-68 # 80021270 <log>
    800042bc:	9736                	add	a4,a4,a3
    800042be:	44d4                	lw	a3,12(s1)
    800042c0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042c2:	faf609e3          	beq	a2,a5,80004274 <log_write+0x76>
  }
  release(&log.lock);
    800042c6:	0001d517          	auipc	a0,0x1d
    800042ca:	faa50513          	addi	a0,a0,-86 # 80021270 <log>
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	9b6080e7          	jalr	-1610(ra) # 80000c84 <release>
}
    800042d6:	60e2                	ld	ra,24(sp)
    800042d8:	6442                	ld	s0,16(sp)
    800042da:	64a2                	ld	s1,8(sp)
    800042dc:	6902                	ld	s2,0(sp)
    800042de:	6105                	addi	sp,sp,32
    800042e0:	8082                	ret

00000000800042e2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042e2:	1101                	addi	sp,sp,-32
    800042e4:	ec06                	sd	ra,24(sp)
    800042e6:	e822                	sd	s0,16(sp)
    800042e8:	e426                	sd	s1,8(sp)
    800042ea:	e04a                	sd	s2,0(sp)
    800042ec:	1000                	addi	s0,sp,32
    800042ee:	84aa                	mv	s1,a0
    800042f0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042f2:	00004597          	auipc	a1,0x4
    800042f6:	39658593          	addi	a1,a1,918 # 80008688 <syscalls+0x240>
    800042fa:	0521                	addi	a0,a0,8
    800042fc:	ffffd097          	auipc	ra,0xffffd
    80004300:	844080e7          	jalr	-1980(ra) # 80000b40 <initlock>
  lk->name = name;
    80004304:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004308:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000430c:	0204a423          	sw	zero,40(s1)
}
    80004310:	60e2                	ld	ra,24(sp)
    80004312:	6442                	ld	s0,16(sp)
    80004314:	64a2                	ld	s1,8(sp)
    80004316:	6902                	ld	s2,0(sp)
    80004318:	6105                	addi	sp,sp,32
    8000431a:	8082                	ret

000000008000431c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000431c:	1101                	addi	sp,sp,-32
    8000431e:	ec06                	sd	ra,24(sp)
    80004320:	e822                	sd	s0,16(sp)
    80004322:	e426                	sd	s1,8(sp)
    80004324:	e04a                	sd	s2,0(sp)
    80004326:	1000                	addi	s0,sp,32
    80004328:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000432a:	00850913          	addi	s2,a0,8
    8000432e:	854a                	mv	a0,s2
    80004330:	ffffd097          	auipc	ra,0xffffd
    80004334:	8a0080e7          	jalr	-1888(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    80004338:	409c                	lw	a5,0(s1)
    8000433a:	cb89                	beqz	a5,8000434c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000433c:	85ca                	mv	a1,s2
    8000433e:	8526                	mv	a0,s1
    80004340:	ffffe097          	auipc	ra,0xffffe
    80004344:	d1a080e7          	jalr	-742(ra) # 8000205a <sleep>
  while (lk->locked) {
    80004348:	409c                	lw	a5,0(s1)
    8000434a:	fbed                	bnez	a5,8000433c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000434c:	4785                	li	a5,1
    8000434e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	646080e7          	jalr	1606(ra) # 80001996 <myproc>
    80004358:	591c                	lw	a5,48(a0)
    8000435a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000435c:	854a                	mv	a0,s2
    8000435e:	ffffd097          	auipc	ra,0xffffd
    80004362:	926080e7          	jalr	-1754(ra) # 80000c84 <release>
}
    80004366:	60e2                	ld	ra,24(sp)
    80004368:	6442                	ld	s0,16(sp)
    8000436a:	64a2                	ld	s1,8(sp)
    8000436c:	6902                	ld	s2,0(sp)
    8000436e:	6105                	addi	sp,sp,32
    80004370:	8082                	ret

0000000080004372 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004372:	1101                	addi	sp,sp,-32
    80004374:	ec06                	sd	ra,24(sp)
    80004376:	e822                	sd	s0,16(sp)
    80004378:	e426                	sd	s1,8(sp)
    8000437a:	e04a                	sd	s2,0(sp)
    8000437c:	1000                	addi	s0,sp,32
    8000437e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004380:	00850913          	addi	s2,a0,8
    80004384:	854a                	mv	a0,s2
    80004386:	ffffd097          	auipc	ra,0xffffd
    8000438a:	84a080e7          	jalr	-1974(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    8000438e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004392:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004396:	8526                	mv	a0,s1
    80004398:	ffffe097          	auipc	ra,0xffffe
    8000439c:	e4e080e7          	jalr	-434(ra) # 800021e6 <wakeup>
  release(&lk->lk);
    800043a0:	854a                	mv	a0,s2
    800043a2:	ffffd097          	auipc	ra,0xffffd
    800043a6:	8e2080e7          	jalr	-1822(ra) # 80000c84 <release>
}
    800043aa:	60e2                	ld	ra,24(sp)
    800043ac:	6442                	ld	s0,16(sp)
    800043ae:	64a2                	ld	s1,8(sp)
    800043b0:	6902                	ld	s2,0(sp)
    800043b2:	6105                	addi	sp,sp,32
    800043b4:	8082                	ret

00000000800043b6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043b6:	7179                	addi	sp,sp,-48
    800043b8:	f406                	sd	ra,40(sp)
    800043ba:	f022                	sd	s0,32(sp)
    800043bc:	ec26                	sd	s1,24(sp)
    800043be:	e84a                	sd	s2,16(sp)
    800043c0:	e44e                	sd	s3,8(sp)
    800043c2:	1800                	addi	s0,sp,48
    800043c4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043c6:	00850913          	addi	s2,a0,8
    800043ca:	854a                	mv	a0,s2
    800043cc:	ffffd097          	auipc	ra,0xffffd
    800043d0:	804080e7          	jalr	-2044(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043d4:	409c                	lw	a5,0(s1)
    800043d6:	ef99                	bnez	a5,800043f4 <holdingsleep+0x3e>
    800043d8:	4481                	li	s1,0
  release(&lk->lk);
    800043da:	854a                	mv	a0,s2
    800043dc:	ffffd097          	auipc	ra,0xffffd
    800043e0:	8a8080e7          	jalr	-1880(ra) # 80000c84 <release>
  return r;
}
    800043e4:	8526                	mv	a0,s1
    800043e6:	70a2                	ld	ra,40(sp)
    800043e8:	7402                	ld	s0,32(sp)
    800043ea:	64e2                	ld	s1,24(sp)
    800043ec:	6942                	ld	s2,16(sp)
    800043ee:	69a2                	ld	s3,8(sp)
    800043f0:	6145                	addi	sp,sp,48
    800043f2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043f4:	0284a983          	lw	s3,40(s1)
    800043f8:	ffffd097          	auipc	ra,0xffffd
    800043fc:	59e080e7          	jalr	1438(ra) # 80001996 <myproc>
    80004400:	5904                	lw	s1,48(a0)
    80004402:	413484b3          	sub	s1,s1,s3
    80004406:	0014b493          	seqz	s1,s1
    8000440a:	bfc1                	j	800043da <holdingsleep+0x24>

000000008000440c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000440c:	1141                	addi	sp,sp,-16
    8000440e:	e406                	sd	ra,8(sp)
    80004410:	e022                	sd	s0,0(sp)
    80004412:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004414:	00004597          	auipc	a1,0x4
    80004418:	28458593          	addi	a1,a1,644 # 80008698 <syscalls+0x250>
    8000441c:	0001d517          	auipc	a0,0x1d
    80004420:	f9c50513          	addi	a0,a0,-100 # 800213b8 <ftable>
    80004424:	ffffc097          	auipc	ra,0xffffc
    80004428:	71c080e7          	jalr	1820(ra) # 80000b40 <initlock>
}
    8000442c:	60a2                	ld	ra,8(sp)
    8000442e:	6402                	ld	s0,0(sp)
    80004430:	0141                	addi	sp,sp,16
    80004432:	8082                	ret

0000000080004434 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004434:	1101                	addi	sp,sp,-32
    80004436:	ec06                	sd	ra,24(sp)
    80004438:	e822                	sd	s0,16(sp)
    8000443a:	e426                	sd	s1,8(sp)
    8000443c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000443e:	0001d517          	auipc	a0,0x1d
    80004442:	f7a50513          	addi	a0,a0,-134 # 800213b8 <ftable>
    80004446:	ffffc097          	auipc	ra,0xffffc
    8000444a:	78a080e7          	jalr	1930(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000444e:	0001d497          	auipc	s1,0x1d
    80004452:	f8248493          	addi	s1,s1,-126 # 800213d0 <ftable+0x18>
    80004456:	0001e717          	auipc	a4,0x1e
    8000445a:	f1a70713          	addi	a4,a4,-230 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    8000445e:	40dc                	lw	a5,4(s1)
    80004460:	cf99                	beqz	a5,8000447e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004462:	02848493          	addi	s1,s1,40
    80004466:	fee49ce3          	bne	s1,a4,8000445e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000446a:	0001d517          	auipc	a0,0x1d
    8000446e:	f4e50513          	addi	a0,a0,-178 # 800213b8 <ftable>
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	812080e7          	jalr	-2030(ra) # 80000c84 <release>
  return 0;
    8000447a:	4481                	li	s1,0
    8000447c:	a819                	j	80004492 <filealloc+0x5e>
      f->ref = 1;
    8000447e:	4785                	li	a5,1
    80004480:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004482:	0001d517          	auipc	a0,0x1d
    80004486:	f3650513          	addi	a0,a0,-202 # 800213b8 <ftable>
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	7fa080e7          	jalr	2042(ra) # 80000c84 <release>
}
    80004492:	8526                	mv	a0,s1
    80004494:	60e2                	ld	ra,24(sp)
    80004496:	6442                	ld	s0,16(sp)
    80004498:	64a2                	ld	s1,8(sp)
    8000449a:	6105                	addi	sp,sp,32
    8000449c:	8082                	ret

000000008000449e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000449e:	1101                	addi	sp,sp,-32
    800044a0:	ec06                	sd	ra,24(sp)
    800044a2:	e822                	sd	s0,16(sp)
    800044a4:	e426                	sd	s1,8(sp)
    800044a6:	1000                	addi	s0,sp,32
    800044a8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044aa:	0001d517          	auipc	a0,0x1d
    800044ae:	f0e50513          	addi	a0,a0,-242 # 800213b8 <ftable>
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	71e080e7          	jalr	1822(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800044ba:	40dc                	lw	a5,4(s1)
    800044bc:	02f05263          	blez	a5,800044e0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044c0:	2785                	addiw	a5,a5,1
    800044c2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044c4:	0001d517          	auipc	a0,0x1d
    800044c8:	ef450513          	addi	a0,a0,-268 # 800213b8 <ftable>
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	7b8080e7          	jalr	1976(ra) # 80000c84 <release>
  return f;
}
    800044d4:	8526                	mv	a0,s1
    800044d6:	60e2                	ld	ra,24(sp)
    800044d8:	6442                	ld	s0,16(sp)
    800044da:	64a2                	ld	s1,8(sp)
    800044dc:	6105                	addi	sp,sp,32
    800044de:	8082                	ret
    panic("filedup");
    800044e0:	00004517          	auipc	a0,0x4
    800044e4:	1c050513          	addi	a0,a0,448 # 800086a0 <syscalls+0x258>
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	052080e7          	jalr	82(ra) # 8000053a <panic>

00000000800044f0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044f0:	7139                	addi	sp,sp,-64
    800044f2:	fc06                	sd	ra,56(sp)
    800044f4:	f822                	sd	s0,48(sp)
    800044f6:	f426                	sd	s1,40(sp)
    800044f8:	f04a                	sd	s2,32(sp)
    800044fa:	ec4e                	sd	s3,24(sp)
    800044fc:	e852                	sd	s4,16(sp)
    800044fe:	e456                	sd	s5,8(sp)
    80004500:	0080                	addi	s0,sp,64
    80004502:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004504:	0001d517          	auipc	a0,0x1d
    80004508:	eb450513          	addi	a0,a0,-332 # 800213b8 <ftable>
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	6c4080e7          	jalr	1732(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004514:	40dc                	lw	a5,4(s1)
    80004516:	06f05163          	blez	a5,80004578 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000451a:	37fd                	addiw	a5,a5,-1
    8000451c:	0007871b          	sext.w	a4,a5
    80004520:	c0dc                	sw	a5,4(s1)
    80004522:	06e04363          	bgtz	a4,80004588 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004526:	0004a903          	lw	s2,0(s1)
    8000452a:	0094ca83          	lbu	s5,9(s1)
    8000452e:	0104ba03          	ld	s4,16(s1)
    80004532:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004536:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000453a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000453e:	0001d517          	auipc	a0,0x1d
    80004542:	e7a50513          	addi	a0,a0,-390 # 800213b8 <ftable>
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	73e080e7          	jalr	1854(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    8000454e:	4785                	li	a5,1
    80004550:	04f90d63          	beq	s2,a5,800045aa <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004554:	3979                	addiw	s2,s2,-2
    80004556:	4785                	li	a5,1
    80004558:	0527e063          	bltu	a5,s2,80004598 <fileclose+0xa8>
    begin_op();
    8000455c:	00000097          	auipc	ra,0x0
    80004560:	acc080e7          	jalr	-1332(ra) # 80004028 <begin_op>
    iput(ff.ip);
    80004564:	854e                	mv	a0,s3
    80004566:	fffff097          	auipc	ra,0xfffff
    8000456a:	2a0080e7          	jalr	672(ra) # 80003806 <iput>
    end_op();
    8000456e:	00000097          	auipc	ra,0x0
    80004572:	b38080e7          	jalr	-1224(ra) # 800040a6 <end_op>
    80004576:	a00d                	j	80004598 <fileclose+0xa8>
    panic("fileclose");
    80004578:	00004517          	auipc	a0,0x4
    8000457c:	13050513          	addi	a0,a0,304 # 800086a8 <syscalls+0x260>
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	fba080e7          	jalr	-70(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004588:	0001d517          	auipc	a0,0x1d
    8000458c:	e3050513          	addi	a0,a0,-464 # 800213b8 <ftable>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	6f4080e7          	jalr	1780(ra) # 80000c84 <release>
  }
}
    80004598:	70e2                	ld	ra,56(sp)
    8000459a:	7442                	ld	s0,48(sp)
    8000459c:	74a2                	ld	s1,40(sp)
    8000459e:	7902                	ld	s2,32(sp)
    800045a0:	69e2                	ld	s3,24(sp)
    800045a2:	6a42                	ld	s4,16(sp)
    800045a4:	6aa2                	ld	s5,8(sp)
    800045a6:	6121                	addi	sp,sp,64
    800045a8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045aa:	85d6                	mv	a1,s5
    800045ac:	8552                	mv	a0,s4
    800045ae:	00000097          	auipc	ra,0x0
    800045b2:	34c080e7          	jalr	844(ra) # 800048fa <pipeclose>
    800045b6:	b7cd                	j	80004598 <fileclose+0xa8>

00000000800045b8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045b8:	715d                	addi	sp,sp,-80
    800045ba:	e486                	sd	ra,72(sp)
    800045bc:	e0a2                	sd	s0,64(sp)
    800045be:	fc26                	sd	s1,56(sp)
    800045c0:	f84a                	sd	s2,48(sp)
    800045c2:	f44e                	sd	s3,40(sp)
    800045c4:	0880                	addi	s0,sp,80
    800045c6:	84aa                	mv	s1,a0
    800045c8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045ca:	ffffd097          	auipc	ra,0xffffd
    800045ce:	3cc080e7          	jalr	972(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045d2:	409c                	lw	a5,0(s1)
    800045d4:	37f9                	addiw	a5,a5,-2
    800045d6:	4705                	li	a4,1
    800045d8:	04f76763          	bltu	a4,a5,80004626 <filestat+0x6e>
    800045dc:	892a                	mv	s2,a0
    ilock(f->ip);
    800045de:	6c88                	ld	a0,24(s1)
    800045e0:	fffff097          	auipc	ra,0xfffff
    800045e4:	06c080e7          	jalr	108(ra) # 8000364c <ilock>
    stati(f->ip, &st);
    800045e8:	fb840593          	addi	a1,s0,-72
    800045ec:	6c88                	ld	a0,24(s1)
    800045ee:	fffff097          	auipc	ra,0xfffff
    800045f2:	2e8080e7          	jalr	744(ra) # 800038d6 <stati>
    iunlock(f->ip);
    800045f6:	6c88                	ld	a0,24(s1)
    800045f8:	fffff097          	auipc	ra,0xfffff
    800045fc:	116080e7          	jalr	278(ra) # 8000370e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004600:	46e1                	li	a3,24
    80004602:	fb840613          	addi	a2,s0,-72
    80004606:	85ce                	mv	a1,s3
    80004608:	05093503          	ld	a0,80(s2)
    8000460c:	ffffd097          	auipc	ra,0xffffd
    80004610:	04e080e7          	jalr	78(ra) # 8000165a <copyout>
    80004614:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004618:	60a6                	ld	ra,72(sp)
    8000461a:	6406                	ld	s0,64(sp)
    8000461c:	74e2                	ld	s1,56(sp)
    8000461e:	7942                	ld	s2,48(sp)
    80004620:	79a2                	ld	s3,40(sp)
    80004622:	6161                	addi	sp,sp,80
    80004624:	8082                	ret
  return -1;
    80004626:	557d                	li	a0,-1
    80004628:	bfc5                	j	80004618 <filestat+0x60>

000000008000462a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000462a:	7179                	addi	sp,sp,-48
    8000462c:	f406                	sd	ra,40(sp)
    8000462e:	f022                	sd	s0,32(sp)
    80004630:	ec26                	sd	s1,24(sp)
    80004632:	e84a                	sd	s2,16(sp)
    80004634:	e44e                	sd	s3,8(sp)
    80004636:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004638:	00854783          	lbu	a5,8(a0)
    8000463c:	c3d5                	beqz	a5,800046e0 <fileread+0xb6>
    8000463e:	84aa                	mv	s1,a0
    80004640:	89ae                	mv	s3,a1
    80004642:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004644:	411c                	lw	a5,0(a0)
    80004646:	4705                	li	a4,1
    80004648:	04e78963          	beq	a5,a4,8000469a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000464c:	470d                	li	a4,3
    8000464e:	04e78d63          	beq	a5,a4,800046a8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004652:	4709                	li	a4,2
    80004654:	06e79e63          	bne	a5,a4,800046d0 <fileread+0xa6>
    ilock(f->ip);
    80004658:	6d08                	ld	a0,24(a0)
    8000465a:	fffff097          	auipc	ra,0xfffff
    8000465e:	ff2080e7          	jalr	-14(ra) # 8000364c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004662:	874a                	mv	a4,s2
    80004664:	5094                	lw	a3,32(s1)
    80004666:	864e                	mv	a2,s3
    80004668:	4585                	li	a1,1
    8000466a:	6c88                	ld	a0,24(s1)
    8000466c:	fffff097          	auipc	ra,0xfffff
    80004670:	294080e7          	jalr	660(ra) # 80003900 <readi>
    80004674:	892a                	mv	s2,a0
    80004676:	00a05563          	blez	a0,80004680 <fileread+0x56>
      f->off += r;
    8000467a:	509c                	lw	a5,32(s1)
    8000467c:	9fa9                	addw	a5,a5,a0
    8000467e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004680:	6c88                	ld	a0,24(s1)
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	08c080e7          	jalr	140(ra) # 8000370e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000468a:	854a                	mv	a0,s2
    8000468c:	70a2                	ld	ra,40(sp)
    8000468e:	7402                	ld	s0,32(sp)
    80004690:	64e2                	ld	s1,24(sp)
    80004692:	6942                	ld	s2,16(sp)
    80004694:	69a2                	ld	s3,8(sp)
    80004696:	6145                	addi	sp,sp,48
    80004698:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000469a:	6908                	ld	a0,16(a0)
    8000469c:	00000097          	auipc	ra,0x0
    800046a0:	3c0080e7          	jalr	960(ra) # 80004a5c <piperead>
    800046a4:	892a                	mv	s2,a0
    800046a6:	b7d5                	j	8000468a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046a8:	02451783          	lh	a5,36(a0)
    800046ac:	03079693          	slli	a3,a5,0x30
    800046b0:	92c1                	srli	a3,a3,0x30
    800046b2:	4725                	li	a4,9
    800046b4:	02d76863          	bltu	a4,a3,800046e4 <fileread+0xba>
    800046b8:	0792                	slli	a5,a5,0x4
    800046ba:	0001d717          	auipc	a4,0x1d
    800046be:	c5e70713          	addi	a4,a4,-930 # 80021318 <devsw>
    800046c2:	97ba                	add	a5,a5,a4
    800046c4:	639c                	ld	a5,0(a5)
    800046c6:	c38d                	beqz	a5,800046e8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046c8:	4505                	li	a0,1
    800046ca:	9782                	jalr	a5
    800046cc:	892a                	mv	s2,a0
    800046ce:	bf75                	j	8000468a <fileread+0x60>
    panic("fileread");
    800046d0:	00004517          	auipc	a0,0x4
    800046d4:	fe850513          	addi	a0,a0,-24 # 800086b8 <syscalls+0x270>
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	e62080e7          	jalr	-414(ra) # 8000053a <panic>
    return -1;
    800046e0:	597d                	li	s2,-1
    800046e2:	b765                	j	8000468a <fileread+0x60>
      return -1;
    800046e4:	597d                	li	s2,-1
    800046e6:	b755                	j	8000468a <fileread+0x60>
    800046e8:	597d                	li	s2,-1
    800046ea:	b745                	j	8000468a <fileread+0x60>

00000000800046ec <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046ec:	715d                	addi	sp,sp,-80
    800046ee:	e486                	sd	ra,72(sp)
    800046f0:	e0a2                	sd	s0,64(sp)
    800046f2:	fc26                	sd	s1,56(sp)
    800046f4:	f84a                	sd	s2,48(sp)
    800046f6:	f44e                	sd	s3,40(sp)
    800046f8:	f052                	sd	s4,32(sp)
    800046fa:	ec56                	sd	s5,24(sp)
    800046fc:	e85a                	sd	s6,16(sp)
    800046fe:	e45e                	sd	s7,8(sp)
    80004700:	e062                	sd	s8,0(sp)
    80004702:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004704:	00954783          	lbu	a5,9(a0)
    80004708:	10078663          	beqz	a5,80004814 <filewrite+0x128>
    8000470c:	892a                	mv	s2,a0
    8000470e:	8b2e                	mv	s6,a1
    80004710:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004712:	411c                	lw	a5,0(a0)
    80004714:	4705                	li	a4,1
    80004716:	02e78263          	beq	a5,a4,8000473a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000471a:	470d                	li	a4,3
    8000471c:	02e78663          	beq	a5,a4,80004748 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004720:	4709                	li	a4,2
    80004722:	0ee79163          	bne	a5,a4,80004804 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004726:	0ac05d63          	blez	a2,800047e0 <filewrite+0xf4>
    int i = 0;
    8000472a:	4981                	li	s3,0
    8000472c:	6b85                	lui	s7,0x1
    8000472e:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004732:	6c05                	lui	s8,0x1
    80004734:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004738:	a861                	j	800047d0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000473a:	6908                	ld	a0,16(a0)
    8000473c:	00000097          	auipc	ra,0x0
    80004740:	22e080e7          	jalr	558(ra) # 8000496a <pipewrite>
    80004744:	8a2a                	mv	s4,a0
    80004746:	a045                	j	800047e6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004748:	02451783          	lh	a5,36(a0)
    8000474c:	03079693          	slli	a3,a5,0x30
    80004750:	92c1                	srli	a3,a3,0x30
    80004752:	4725                	li	a4,9
    80004754:	0cd76263          	bltu	a4,a3,80004818 <filewrite+0x12c>
    80004758:	0792                	slli	a5,a5,0x4
    8000475a:	0001d717          	auipc	a4,0x1d
    8000475e:	bbe70713          	addi	a4,a4,-1090 # 80021318 <devsw>
    80004762:	97ba                	add	a5,a5,a4
    80004764:	679c                	ld	a5,8(a5)
    80004766:	cbdd                	beqz	a5,8000481c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004768:	4505                	li	a0,1
    8000476a:	9782                	jalr	a5
    8000476c:	8a2a                	mv	s4,a0
    8000476e:	a8a5                	j	800047e6 <filewrite+0xfa>
    80004770:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004774:	00000097          	auipc	ra,0x0
    80004778:	8b4080e7          	jalr	-1868(ra) # 80004028 <begin_op>
      ilock(f->ip);
    8000477c:	01893503          	ld	a0,24(s2)
    80004780:	fffff097          	auipc	ra,0xfffff
    80004784:	ecc080e7          	jalr	-308(ra) # 8000364c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004788:	8756                	mv	a4,s5
    8000478a:	02092683          	lw	a3,32(s2)
    8000478e:	01698633          	add	a2,s3,s6
    80004792:	4585                	li	a1,1
    80004794:	01893503          	ld	a0,24(s2)
    80004798:	fffff097          	auipc	ra,0xfffff
    8000479c:	260080e7          	jalr	608(ra) # 800039f8 <writei>
    800047a0:	84aa                	mv	s1,a0
    800047a2:	00a05763          	blez	a0,800047b0 <filewrite+0xc4>
        f->off += r;
    800047a6:	02092783          	lw	a5,32(s2)
    800047aa:	9fa9                	addw	a5,a5,a0
    800047ac:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047b0:	01893503          	ld	a0,24(s2)
    800047b4:	fffff097          	auipc	ra,0xfffff
    800047b8:	f5a080e7          	jalr	-166(ra) # 8000370e <iunlock>
      end_op();
    800047bc:	00000097          	auipc	ra,0x0
    800047c0:	8ea080e7          	jalr	-1814(ra) # 800040a6 <end_op>

      if(r != n1){
    800047c4:	009a9f63          	bne	s5,s1,800047e2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047c8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047cc:	0149db63          	bge	s3,s4,800047e2 <filewrite+0xf6>
      int n1 = n - i;
    800047d0:	413a04bb          	subw	s1,s4,s3
    800047d4:	0004879b          	sext.w	a5,s1
    800047d8:	f8fbdce3          	bge	s7,a5,80004770 <filewrite+0x84>
    800047dc:	84e2                	mv	s1,s8
    800047de:	bf49                	j	80004770 <filewrite+0x84>
    int i = 0;
    800047e0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047e2:	013a1f63          	bne	s4,s3,80004800 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047e6:	8552                	mv	a0,s4
    800047e8:	60a6                	ld	ra,72(sp)
    800047ea:	6406                	ld	s0,64(sp)
    800047ec:	74e2                	ld	s1,56(sp)
    800047ee:	7942                	ld	s2,48(sp)
    800047f0:	79a2                	ld	s3,40(sp)
    800047f2:	7a02                	ld	s4,32(sp)
    800047f4:	6ae2                	ld	s5,24(sp)
    800047f6:	6b42                	ld	s6,16(sp)
    800047f8:	6ba2                	ld	s7,8(sp)
    800047fa:	6c02                	ld	s8,0(sp)
    800047fc:	6161                	addi	sp,sp,80
    800047fe:	8082                	ret
    ret = (i == n ? n : -1);
    80004800:	5a7d                	li	s4,-1
    80004802:	b7d5                	j	800047e6 <filewrite+0xfa>
    panic("filewrite");
    80004804:	00004517          	auipc	a0,0x4
    80004808:	ec450513          	addi	a0,a0,-316 # 800086c8 <syscalls+0x280>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	d2e080e7          	jalr	-722(ra) # 8000053a <panic>
    return -1;
    80004814:	5a7d                	li	s4,-1
    80004816:	bfc1                	j	800047e6 <filewrite+0xfa>
      return -1;
    80004818:	5a7d                	li	s4,-1
    8000481a:	b7f1                	j	800047e6 <filewrite+0xfa>
    8000481c:	5a7d                	li	s4,-1
    8000481e:	b7e1                	j	800047e6 <filewrite+0xfa>

0000000080004820 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004820:	7179                	addi	sp,sp,-48
    80004822:	f406                	sd	ra,40(sp)
    80004824:	f022                	sd	s0,32(sp)
    80004826:	ec26                	sd	s1,24(sp)
    80004828:	e84a                	sd	s2,16(sp)
    8000482a:	e44e                	sd	s3,8(sp)
    8000482c:	e052                	sd	s4,0(sp)
    8000482e:	1800                	addi	s0,sp,48
    80004830:	84aa                	mv	s1,a0
    80004832:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004834:	0005b023          	sd	zero,0(a1)
    80004838:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000483c:	00000097          	auipc	ra,0x0
    80004840:	bf8080e7          	jalr	-1032(ra) # 80004434 <filealloc>
    80004844:	e088                	sd	a0,0(s1)
    80004846:	c551                	beqz	a0,800048d2 <pipealloc+0xb2>
    80004848:	00000097          	auipc	ra,0x0
    8000484c:	bec080e7          	jalr	-1044(ra) # 80004434 <filealloc>
    80004850:	00aa3023          	sd	a0,0(s4)
    80004854:	c92d                	beqz	a0,800048c6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	28a080e7          	jalr	650(ra) # 80000ae0 <kalloc>
    8000485e:	892a                	mv	s2,a0
    80004860:	c125                	beqz	a0,800048c0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004862:	4985                	li	s3,1
    80004864:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004868:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000486c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004870:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004874:	00004597          	auipc	a1,0x4
    80004878:	e6458593          	addi	a1,a1,-412 # 800086d8 <syscalls+0x290>
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	2c4080e7          	jalr	708(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004884:	609c                	ld	a5,0(s1)
    80004886:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000488a:	609c                	ld	a5,0(s1)
    8000488c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004890:	609c                	ld	a5,0(s1)
    80004892:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004896:	609c                	ld	a5,0(s1)
    80004898:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000489c:	000a3783          	ld	a5,0(s4)
    800048a0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048a4:	000a3783          	ld	a5,0(s4)
    800048a8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048ac:	000a3783          	ld	a5,0(s4)
    800048b0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048b4:	000a3783          	ld	a5,0(s4)
    800048b8:	0127b823          	sd	s2,16(a5)
  return 0;
    800048bc:	4501                	li	a0,0
    800048be:	a025                	j	800048e6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048c0:	6088                	ld	a0,0(s1)
    800048c2:	e501                	bnez	a0,800048ca <pipealloc+0xaa>
    800048c4:	a039                	j	800048d2 <pipealloc+0xb2>
    800048c6:	6088                	ld	a0,0(s1)
    800048c8:	c51d                	beqz	a0,800048f6 <pipealloc+0xd6>
    fileclose(*f0);
    800048ca:	00000097          	auipc	ra,0x0
    800048ce:	c26080e7          	jalr	-986(ra) # 800044f0 <fileclose>
  if(*f1)
    800048d2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800048d6:	557d                	li	a0,-1
  if(*f1)
    800048d8:	c799                	beqz	a5,800048e6 <pipealloc+0xc6>
    fileclose(*f1);
    800048da:	853e                	mv	a0,a5
    800048dc:	00000097          	auipc	ra,0x0
    800048e0:	c14080e7          	jalr	-1004(ra) # 800044f0 <fileclose>
  return -1;
    800048e4:	557d                	li	a0,-1
}
    800048e6:	70a2                	ld	ra,40(sp)
    800048e8:	7402                	ld	s0,32(sp)
    800048ea:	64e2                	ld	s1,24(sp)
    800048ec:	6942                	ld	s2,16(sp)
    800048ee:	69a2                	ld	s3,8(sp)
    800048f0:	6a02                	ld	s4,0(sp)
    800048f2:	6145                	addi	sp,sp,48
    800048f4:	8082                	ret
  return -1;
    800048f6:	557d                	li	a0,-1
    800048f8:	b7fd                	j	800048e6 <pipealloc+0xc6>

00000000800048fa <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048fa:	1101                	addi	sp,sp,-32
    800048fc:	ec06                	sd	ra,24(sp)
    800048fe:	e822                	sd	s0,16(sp)
    80004900:	e426                	sd	s1,8(sp)
    80004902:	e04a                	sd	s2,0(sp)
    80004904:	1000                	addi	s0,sp,32
    80004906:	84aa                	mv	s1,a0
    80004908:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	2c6080e7          	jalr	710(ra) # 80000bd0 <acquire>
  if(writable){
    80004912:	02090d63          	beqz	s2,8000494c <pipeclose+0x52>
    pi->writeopen = 0;
    80004916:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000491a:	21848513          	addi	a0,s1,536
    8000491e:	ffffe097          	auipc	ra,0xffffe
    80004922:	8c8080e7          	jalr	-1848(ra) # 800021e6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004926:	2204b783          	ld	a5,544(s1)
    8000492a:	eb95                	bnez	a5,8000495e <pipeclose+0x64>
    release(&pi->lock);
    8000492c:	8526                	mv	a0,s1
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	356080e7          	jalr	854(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004936:	8526                	mv	a0,s1
    80004938:	ffffc097          	auipc	ra,0xffffc
    8000493c:	0aa080e7          	jalr	170(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004940:	60e2                	ld	ra,24(sp)
    80004942:	6442                	ld	s0,16(sp)
    80004944:	64a2                	ld	s1,8(sp)
    80004946:	6902                	ld	s2,0(sp)
    80004948:	6105                	addi	sp,sp,32
    8000494a:	8082                	ret
    pi->readopen = 0;
    8000494c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004950:	21c48513          	addi	a0,s1,540
    80004954:	ffffe097          	auipc	ra,0xffffe
    80004958:	892080e7          	jalr	-1902(ra) # 800021e6 <wakeup>
    8000495c:	b7e9                	j	80004926 <pipeclose+0x2c>
    release(&pi->lock);
    8000495e:	8526                	mv	a0,s1
    80004960:	ffffc097          	auipc	ra,0xffffc
    80004964:	324080e7          	jalr	804(ra) # 80000c84 <release>
}
    80004968:	bfe1                	j	80004940 <pipeclose+0x46>

000000008000496a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000496a:	711d                	addi	sp,sp,-96
    8000496c:	ec86                	sd	ra,88(sp)
    8000496e:	e8a2                	sd	s0,80(sp)
    80004970:	e4a6                	sd	s1,72(sp)
    80004972:	e0ca                	sd	s2,64(sp)
    80004974:	fc4e                	sd	s3,56(sp)
    80004976:	f852                	sd	s4,48(sp)
    80004978:	f456                	sd	s5,40(sp)
    8000497a:	f05a                	sd	s6,32(sp)
    8000497c:	ec5e                	sd	s7,24(sp)
    8000497e:	e862                	sd	s8,16(sp)
    80004980:	1080                	addi	s0,sp,96
    80004982:	84aa                	mv	s1,a0
    80004984:	8aae                	mv	s5,a1
    80004986:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004988:	ffffd097          	auipc	ra,0xffffd
    8000498c:	00e080e7          	jalr	14(ra) # 80001996 <myproc>
    80004990:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004992:	8526                	mv	a0,s1
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	23c080e7          	jalr	572(ra) # 80000bd0 <acquire>
  while(i < n){
    8000499c:	0b405363          	blez	s4,80004a42 <pipewrite+0xd8>
  int i = 0;
    800049a0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049a2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049a4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049a8:	21c48b93          	addi	s7,s1,540
    800049ac:	a089                	j	800049ee <pipewrite+0x84>
      release(&pi->lock);
    800049ae:	8526                	mv	a0,s1
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	2d4080e7          	jalr	724(ra) # 80000c84 <release>
      return -1;
    800049b8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049ba:	854a                	mv	a0,s2
    800049bc:	60e6                	ld	ra,88(sp)
    800049be:	6446                	ld	s0,80(sp)
    800049c0:	64a6                	ld	s1,72(sp)
    800049c2:	6906                	ld	s2,64(sp)
    800049c4:	79e2                	ld	s3,56(sp)
    800049c6:	7a42                	ld	s4,48(sp)
    800049c8:	7aa2                	ld	s5,40(sp)
    800049ca:	7b02                	ld	s6,32(sp)
    800049cc:	6be2                	ld	s7,24(sp)
    800049ce:	6c42                	ld	s8,16(sp)
    800049d0:	6125                	addi	sp,sp,96
    800049d2:	8082                	ret
      wakeup(&pi->nread);
    800049d4:	8562                	mv	a0,s8
    800049d6:	ffffe097          	auipc	ra,0xffffe
    800049da:	810080e7          	jalr	-2032(ra) # 800021e6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049de:	85a6                	mv	a1,s1
    800049e0:	855e                	mv	a0,s7
    800049e2:	ffffd097          	auipc	ra,0xffffd
    800049e6:	678080e7          	jalr	1656(ra) # 8000205a <sleep>
  while(i < n){
    800049ea:	05495d63          	bge	s2,s4,80004a44 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    800049ee:	2204a783          	lw	a5,544(s1)
    800049f2:	dfd5                	beqz	a5,800049ae <pipewrite+0x44>
    800049f4:	0289a783          	lw	a5,40(s3)
    800049f8:	fbdd                	bnez	a5,800049ae <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800049fa:	2184a783          	lw	a5,536(s1)
    800049fe:	21c4a703          	lw	a4,540(s1)
    80004a02:	2007879b          	addiw	a5,a5,512
    80004a06:	fcf707e3          	beq	a4,a5,800049d4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a0a:	4685                	li	a3,1
    80004a0c:	01590633          	add	a2,s2,s5
    80004a10:	faf40593          	addi	a1,s0,-81
    80004a14:	0509b503          	ld	a0,80(s3)
    80004a18:	ffffd097          	auipc	ra,0xffffd
    80004a1c:	cce080e7          	jalr	-818(ra) # 800016e6 <copyin>
    80004a20:	03650263          	beq	a0,s6,80004a44 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a24:	21c4a783          	lw	a5,540(s1)
    80004a28:	0017871b          	addiw	a4,a5,1
    80004a2c:	20e4ae23          	sw	a4,540(s1)
    80004a30:	1ff7f793          	andi	a5,a5,511
    80004a34:	97a6                	add	a5,a5,s1
    80004a36:	faf44703          	lbu	a4,-81(s0)
    80004a3a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a3e:	2905                	addiw	s2,s2,1
    80004a40:	b76d                	j	800049ea <pipewrite+0x80>
  int i = 0;
    80004a42:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004a44:	21848513          	addi	a0,s1,536
    80004a48:	ffffd097          	auipc	ra,0xffffd
    80004a4c:	79e080e7          	jalr	1950(ra) # 800021e6 <wakeup>
  release(&pi->lock);
    80004a50:	8526                	mv	a0,s1
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	232080e7          	jalr	562(ra) # 80000c84 <release>
  return i;
    80004a5a:	b785                	j	800049ba <pipewrite+0x50>

0000000080004a5c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a5c:	715d                	addi	sp,sp,-80
    80004a5e:	e486                	sd	ra,72(sp)
    80004a60:	e0a2                	sd	s0,64(sp)
    80004a62:	fc26                	sd	s1,56(sp)
    80004a64:	f84a                	sd	s2,48(sp)
    80004a66:	f44e                	sd	s3,40(sp)
    80004a68:	f052                	sd	s4,32(sp)
    80004a6a:	ec56                	sd	s5,24(sp)
    80004a6c:	e85a                	sd	s6,16(sp)
    80004a6e:	0880                	addi	s0,sp,80
    80004a70:	84aa                	mv	s1,a0
    80004a72:	892e                	mv	s2,a1
    80004a74:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a76:	ffffd097          	auipc	ra,0xffffd
    80004a7a:	f20080e7          	jalr	-224(ra) # 80001996 <myproc>
    80004a7e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a80:	8526                	mv	a0,s1
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	14e080e7          	jalr	334(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a8a:	2184a703          	lw	a4,536(s1)
    80004a8e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a92:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a96:	02f71463          	bne	a4,a5,80004abe <piperead+0x62>
    80004a9a:	2244a783          	lw	a5,548(s1)
    80004a9e:	c385                	beqz	a5,80004abe <piperead+0x62>
    if(pr->killed){
    80004aa0:	028a2783          	lw	a5,40(s4)
    80004aa4:	ebc9                	bnez	a5,80004b36 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aa6:	85a6                	mv	a1,s1
    80004aa8:	854e                	mv	a0,s3
    80004aaa:	ffffd097          	auipc	ra,0xffffd
    80004aae:	5b0080e7          	jalr	1456(ra) # 8000205a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ab2:	2184a703          	lw	a4,536(s1)
    80004ab6:	21c4a783          	lw	a5,540(s1)
    80004aba:	fef700e3          	beq	a4,a5,80004a9a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004abe:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ac0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ac2:	05505463          	blez	s5,80004b0a <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004ac6:	2184a783          	lw	a5,536(s1)
    80004aca:	21c4a703          	lw	a4,540(s1)
    80004ace:	02f70e63          	beq	a4,a5,80004b0a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ad2:	0017871b          	addiw	a4,a5,1
    80004ad6:	20e4ac23          	sw	a4,536(s1)
    80004ada:	1ff7f793          	andi	a5,a5,511
    80004ade:	97a6                	add	a5,a5,s1
    80004ae0:	0187c783          	lbu	a5,24(a5)
    80004ae4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ae8:	4685                	li	a3,1
    80004aea:	fbf40613          	addi	a2,s0,-65
    80004aee:	85ca                	mv	a1,s2
    80004af0:	050a3503          	ld	a0,80(s4)
    80004af4:	ffffd097          	auipc	ra,0xffffd
    80004af8:	b66080e7          	jalr	-1178(ra) # 8000165a <copyout>
    80004afc:	01650763          	beq	a0,s6,80004b0a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b00:	2985                	addiw	s3,s3,1
    80004b02:	0905                	addi	s2,s2,1
    80004b04:	fd3a91e3          	bne	s5,s3,80004ac6 <piperead+0x6a>
    80004b08:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b0a:	21c48513          	addi	a0,s1,540
    80004b0e:	ffffd097          	auipc	ra,0xffffd
    80004b12:	6d8080e7          	jalr	1752(ra) # 800021e6 <wakeup>
  release(&pi->lock);
    80004b16:	8526                	mv	a0,s1
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	16c080e7          	jalr	364(ra) # 80000c84 <release>
  return i;
}
    80004b20:	854e                	mv	a0,s3
    80004b22:	60a6                	ld	ra,72(sp)
    80004b24:	6406                	ld	s0,64(sp)
    80004b26:	74e2                	ld	s1,56(sp)
    80004b28:	7942                	ld	s2,48(sp)
    80004b2a:	79a2                	ld	s3,40(sp)
    80004b2c:	7a02                	ld	s4,32(sp)
    80004b2e:	6ae2                	ld	s5,24(sp)
    80004b30:	6b42                	ld	s6,16(sp)
    80004b32:	6161                	addi	sp,sp,80
    80004b34:	8082                	ret
      release(&pi->lock);
    80004b36:	8526                	mv	a0,s1
    80004b38:	ffffc097          	auipc	ra,0xffffc
    80004b3c:	14c080e7          	jalr	332(ra) # 80000c84 <release>
      return -1;
    80004b40:	59fd                	li	s3,-1
    80004b42:	bff9                	j	80004b20 <piperead+0xc4>

0000000080004b44 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b44:	de010113          	addi	sp,sp,-544
    80004b48:	20113c23          	sd	ra,536(sp)
    80004b4c:	20813823          	sd	s0,528(sp)
    80004b50:	20913423          	sd	s1,520(sp)
    80004b54:	21213023          	sd	s2,512(sp)
    80004b58:	ffce                	sd	s3,504(sp)
    80004b5a:	fbd2                	sd	s4,496(sp)
    80004b5c:	f7d6                	sd	s5,488(sp)
    80004b5e:	f3da                	sd	s6,480(sp)
    80004b60:	efde                	sd	s7,472(sp)
    80004b62:	ebe2                	sd	s8,464(sp)
    80004b64:	e7e6                	sd	s9,456(sp)
    80004b66:	e3ea                	sd	s10,448(sp)
    80004b68:	ff6e                	sd	s11,440(sp)
    80004b6a:	1400                	addi	s0,sp,544
    80004b6c:	892a                	mv	s2,a0
    80004b6e:	dea43423          	sd	a0,-536(s0)
    80004b72:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b76:	ffffd097          	auipc	ra,0xffffd
    80004b7a:	e20080e7          	jalr	-480(ra) # 80001996 <myproc>
    80004b7e:	84aa                	mv	s1,a0

  begin_op();
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	4a8080e7          	jalr	1192(ra) # 80004028 <begin_op>

  if((ip = namei(path)) == 0){
    80004b88:	854a                	mv	a0,s2
    80004b8a:	fffff097          	auipc	ra,0xfffff
    80004b8e:	27e080e7          	jalr	638(ra) # 80003e08 <namei>
    80004b92:	c93d                	beqz	a0,80004c08 <exec+0xc4>
    80004b94:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b96:	fffff097          	auipc	ra,0xfffff
    80004b9a:	ab6080e7          	jalr	-1354(ra) # 8000364c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b9e:	04000713          	li	a4,64
    80004ba2:	4681                	li	a3,0
    80004ba4:	e5040613          	addi	a2,s0,-432
    80004ba8:	4581                	li	a1,0
    80004baa:	8556                	mv	a0,s5
    80004bac:	fffff097          	auipc	ra,0xfffff
    80004bb0:	d54080e7          	jalr	-684(ra) # 80003900 <readi>
    80004bb4:	04000793          	li	a5,64
    80004bb8:	00f51a63          	bne	a0,a5,80004bcc <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004bbc:	e5042703          	lw	a4,-432(s0)
    80004bc0:	464c47b7          	lui	a5,0x464c4
    80004bc4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004bc8:	04f70663          	beq	a4,a5,80004c14 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004bcc:	8556                	mv	a0,s5
    80004bce:	fffff097          	auipc	ra,0xfffff
    80004bd2:	ce0080e7          	jalr	-800(ra) # 800038ae <iunlockput>
    end_op();
    80004bd6:	fffff097          	auipc	ra,0xfffff
    80004bda:	4d0080e7          	jalr	1232(ra) # 800040a6 <end_op>
  }
  return -1;
    80004bde:	557d                	li	a0,-1
}
    80004be0:	21813083          	ld	ra,536(sp)
    80004be4:	21013403          	ld	s0,528(sp)
    80004be8:	20813483          	ld	s1,520(sp)
    80004bec:	20013903          	ld	s2,512(sp)
    80004bf0:	79fe                	ld	s3,504(sp)
    80004bf2:	7a5e                	ld	s4,496(sp)
    80004bf4:	7abe                	ld	s5,488(sp)
    80004bf6:	7b1e                	ld	s6,480(sp)
    80004bf8:	6bfe                	ld	s7,472(sp)
    80004bfa:	6c5e                	ld	s8,464(sp)
    80004bfc:	6cbe                	ld	s9,456(sp)
    80004bfe:	6d1e                	ld	s10,448(sp)
    80004c00:	7dfa                	ld	s11,440(sp)
    80004c02:	22010113          	addi	sp,sp,544
    80004c06:	8082                	ret
    end_op();
    80004c08:	fffff097          	auipc	ra,0xfffff
    80004c0c:	49e080e7          	jalr	1182(ra) # 800040a6 <end_op>
    return -1;
    80004c10:	557d                	li	a0,-1
    80004c12:	b7f9                	j	80004be0 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c14:	8526                	mv	a0,s1
    80004c16:	ffffd097          	auipc	ra,0xffffd
    80004c1a:	e44080e7          	jalr	-444(ra) # 80001a5a <proc_pagetable>
    80004c1e:	8b2a                	mv	s6,a0
    80004c20:	d555                	beqz	a0,80004bcc <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c22:	e7042783          	lw	a5,-400(s0)
    80004c26:	e8845703          	lhu	a4,-376(s0)
    80004c2a:	c735                	beqz	a4,80004c96 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c2c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c2e:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004c32:	6a05                	lui	s4,0x1
    80004c34:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004c38:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004c3c:	6d85                	lui	s11,0x1
    80004c3e:	7d7d                	lui	s10,0xfffff
    80004c40:	ac1d                	j	80004e76 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c42:	00004517          	auipc	a0,0x4
    80004c46:	a9e50513          	addi	a0,a0,-1378 # 800086e0 <syscalls+0x298>
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	8f0080e7          	jalr	-1808(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c52:	874a                	mv	a4,s2
    80004c54:	009c86bb          	addw	a3,s9,s1
    80004c58:	4581                	li	a1,0
    80004c5a:	8556                	mv	a0,s5
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	ca4080e7          	jalr	-860(ra) # 80003900 <readi>
    80004c64:	2501                	sext.w	a0,a0
    80004c66:	1aa91863          	bne	s2,a0,80004e16 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004c6a:	009d84bb          	addw	s1,s11,s1
    80004c6e:	013d09bb          	addw	s3,s10,s3
    80004c72:	1f74f263          	bgeu	s1,s7,80004e56 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004c76:	02049593          	slli	a1,s1,0x20
    80004c7a:	9181                	srli	a1,a1,0x20
    80004c7c:	95e2                	add	a1,a1,s8
    80004c7e:	855a                	mv	a0,s6
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	3d2080e7          	jalr	978(ra) # 80001052 <walkaddr>
    80004c88:	862a                	mv	a2,a0
    if(pa == 0)
    80004c8a:	dd45                	beqz	a0,80004c42 <exec+0xfe>
      n = PGSIZE;
    80004c8c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004c8e:	fd49f2e3          	bgeu	s3,s4,80004c52 <exec+0x10e>
      n = sz - i;
    80004c92:	894e                	mv	s2,s3
    80004c94:	bf7d                	j	80004c52 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c96:	4481                	li	s1,0
  iunlockput(ip);
    80004c98:	8556                	mv	a0,s5
    80004c9a:	fffff097          	auipc	ra,0xfffff
    80004c9e:	c14080e7          	jalr	-1004(ra) # 800038ae <iunlockput>
  end_op();
    80004ca2:	fffff097          	auipc	ra,0xfffff
    80004ca6:	404080e7          	jalr	1028(ra) # 800040a6 <end_op>
  p = myproc();
    80004caa:	ffffd097          	auipc	ra,0xffffd
    80004cae:	cec080e7          	jalr	-788(ra) # 80001996 <myproc>
    80004cb2:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004cb4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004cb8:	6785                	lui	a5,0x1
    80004cba:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004cbc:	97a6                	add	a5,a5,s1
    80004cbe:	777d                	lui	a4,0xfffff
    80004cc0:	8ff9                	and	a5,a5,a4
    80004cc2:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cc6:	6609                	lui	a2,0x2
    80004cc8:	963e                	add	a2,a2,a5
    80004cca:	85be                	mv	a1,a5
    80004ccc:	855a                	mv	a0,s6
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	738080e7          	jalr	1848(ra) # 80001406 <uvmalloc>
    80004cd6:	8c2a                	mv	s8,a0
  ip = 0;
    80004cd8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cda:	12050e63          	beqz	a0,80004e16 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004cde:	75f9                	lui	a1,0xffffe
    80004ce0:	95aa                	add	a1,a1,a0
    80004ce2:	855a                	mv	a0,s6
    80004ce4:	ffffd097          	auipc	ra,0xffffd
    80004ce8:	944080e7          	jalr	-1724(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80004cec:	7afd                	lui	s5,0xfffff
    80004cee:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004cf0:	df043783          	ld	a5,-528(s0)
    80004cf4:	6388                	ld	a0,0(a5)
    80004cf6:	c925                	beqz	a0,80004d66 <exec+0x222>
    80004cf8:	e9040993          	addi	s3,s0,-368
    80004cfc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d00:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d02:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d04:	ffffc097          	auipc	ra,0xffffc
    80004d08:	144080e7          	jalr	324(ra) # 80000e48 <strlen>
    80004d0c:	0015079b          	addiw	a5,a0,1
    80004d10:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d14:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004d18:	13596363          	bltu	s2,s5,80004e3e <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d1c:	df043d83          	ld	s11,-528(s0)
    80004d20:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004d24:	8552                	mv	a0,s4
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	122080e7          	jalr	290(ra) # 80000e48 <strlen>
    80004d2e:	0015069b          	addiw	a3,a0,1
    80004d32:	8652                	mv	a2,s4
    80004d34:	85ca                	mv	a1,s2
    80004d36:	855a                	mv	a0,s6
    80004d38:	ffffd097          	auipc	ra,0xffffd
    80004d3c:	922080e7          	jalr	-1758(ra) # 8000165a <copyout>
    80004d40:	10054363          	bltz	a0,80004e46 <exec+0x302>
    ustack[argc] = sp;
    80004d44:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d48:	0485                	addi	s1,s1,1
    80004d4a:	008d8793          	addi	a5,s11,8
    80004d4e:	def43823          	sd	a5,-528(s0)
    80004d52:	008db503          	ld	a0,8(s11)
    80004d56:	c911                	beqz	a0,80004d6a <exec+0x226>
    if(argc >= MAXARG)
    80004d58:	09a1                	addi	s3,s3,8
    80004d5a:	fb3c95e3          	bne	s9,s3,80004d04 <exec+0x1c0>
  sz = sz1;
    80004d5e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d62:	4a81                	li	s5,0
    80004d64:	a84d                	j	80004e16 <exec+0x2d2>
  sp = sz;
    80004d66:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d68:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d6a:	00349793          	slli	a5,s1,0x3
    80004d6e:	f9078793          	addi	a5,a5,-112
    80004d72:	97a2                	add	a5,a5,s0
    80004d74:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004d78:	00148693          	addi	a3,s1,1
    80004d7c:	068e                	slli	a3,a3,0x3
    80004d7e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d82:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d86:	01597663          	bgeu	s2,s5,80004d92 <exec+0x24e>
  sz = sz1;
    80004d8a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d8e:	4a81                	li	s5,0
    80004d90:	a059                	j	80004e16 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d92:	e9040613          	addi	a2,s0,-368
    80004d96:	85ca                	mv	a1,s2
    80004d98:	855a                	mv	a0,s6
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	8c0080e7          	jalr	-1856(ra) # 8000165a <copyout>
    80004da2:	0a054663          	bltz	a0,80004e4e <exec+0x30a>
  p->trapframe->a1 = sp;
    80004da6:	058bb783          	ld	a5,88(s7)
    80004daa:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004dae:	de843783          	ld	a5,-536(s0)
    80004db2:	0007c703          	lbu	a4,0(a5)
    80004db6:	cf11                	beqz	a4,80004dd2 <exec+0x28e>
    80004db8:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004dba:	02f00693          	li	a3,47
    80004dbe:	a039                	j	80004dcc <exec+0x288>
      last = s+1;
    80004dc0:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004dc4:	0785                	addi	a5,a5,1
    80004dc6:	fff7c703          	lbu	a4,-1(a5)
    80004dca:	c701                	beqz	a4,80004dd2 <exec+0x28e>
    if(*s == '/')
    80004dcc:	fed71ce3          	bne	a4,a3,80004dc4 <exec+0x280>
    80004dd0:	bfc5                	j	80004dc0 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004dd2:	4641                	li	a2,16
    80004dd4:	de843583          	ld	a1,-536(s0)
    80004dd8:	158b8513          	addi	a0,s7,344
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	03a080e7          	jalr	58(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004de4:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004de8:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004dec:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004df0:	058bb783          	ld	a5,88(s7)
    80004df4:	e6843703          	ld	a4,-408(s0)
    80004df8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004dfa:	058bb783          	ld	a5,88(s7)
    80004dfe:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e02:	85ea                	mv	a1,s10
    80004e04:	ffffd097          	auipc	ra,0xffffd
    80004e08:	cf2080e7          	jalr	-782(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e0c:	0004851b          	sext.w	a0,s1
    80004e10:	bbc1                	j	80004be0 <exec+0x9c>
    80004e12:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e16:	df843583          	ld	a1,-520(s0)
    80004e1a:	855a                	mv	a0,s6
    80004e1c:	ffffd097          	auipc	ra,0xffffd
    80004e20:	cda080e7          	jalr	-806(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    80004e24:	da0a94e3          	bnez	s5,80004bcc <exec+0x88>
  return -1;
    80004e28:	557d                	li	a0,-1
    80004e2a:	bb5d                	j	80004be0 <exec+0x9c>
    80004e2c:	de943c23          	sd	s1,-520(s0)
    80004e30:	b7dd                	j	80004e16 <exec+0x2d2>
    80004e32:	de943c23          	sd	s1,-520(s0)
    80004e36:	b7c5                	j	80004e16 <exec+0x2d2>
    80004e38:	de943c23          	sd	s1,-520(s0)
    80004e3c:	bfe9                	j	80004e16 <exec+0x2d2>
  sz = sz1;
    80004e3e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e42:	4a81                	li	s5,0
    80004e44:	bfc9                	j	80004e16 <exec+0x2d2>
  sz = sz1;
    80004e46:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e4a:	4a81                	li	s5,0
    80004e4c:	b7e9                	j	80004e16 <exec+0x2d2>
  sz = sz1;
    80004e4e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e52:	4a81                	li	s5,0
    80004e54:	b7c9                	j	80004e16 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e56:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e5a:	e0843783          	ld	a5,-504(s0)
    80004e5e:	0017869b          	addiw	a3,a5,1
    80004e62:	e0d43423          	sd	a3,-504(s0)
    80004e66:	e0043783          	ld	a5,-512(s0)
    80004e6a:	0387879b          	addiw	a5,a5,56
    80004e6e:	e8845703          	lhu	a4,-376(s0)
    80004e72:	e2e6d3e3          	bge	a3,a4,80004c98 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e76:	2781                	sext.w	a5,a5
    80004e78:	e0f43023          	sd	a5,-512(s0)
    80004e7c:	03800713          	li	a4,56
    80004e80:	86be                	mv	a3,a5
    80004e82:	e1840613          	addi	a2,s0,-488
    80004e86:	4581                	li	a1,0
    80004e88:	8556                	mv	a0,s5
    80004e8a:	fffff097          	auipc	ra,0xfffff
    80004e8e:	a76080e7          	jalr	-1418(ra) # 80003900 <readi>
    80004e92:	03800793          	li	a5,56
    80004e96:	f6f51ee3          	bne	a0,a5,80004e12 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004e9a:	e1842783          	lw	a5,-488(s0)
    80004e9e:	4705                	li	a4,1
    80004ea0:	fae79de3          	bne	a5,a4,80004e5a <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004ea4:	e4043603          	ld	a2,-448(s0)
    80004ea8:	e3843783          	ld	a5,-456(s0)
    80004eac:	f8f660e3          	bltu	a2,a5,80004e2c <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004eb0:	e2843783          	ld	a5,-472(s0)
    80004eb4:	963e                	add	a2,a2,a5
    80004eb6:	f6f66ee3          	bltu	a2,a5,80004e32 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004eba:	85a6                	mv	a1,s1
    80004ebc:	855a                	mv	a0,s6
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	548080e7          	jalr	1352(ra) # 80001406 <uvmalloc>
    80004ec6:	dea43c23          	sd	a0,-520(s0)
    80004eca:	d53d                	beqz	a0,80004e38 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80004ecc:	e2843c03          	ld	s8,-472(s0)
    80004ed0:	de043783          	ld	a5,-544(s0)
    80004ed4:	00fc77b3          	and	a5,s8,a5
    80004ed8:	ff9d                	bnez	a5,80004e16 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004eda:	e2042c83          	lw	s9,-480(s0)
    80004ede:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ee2:	f60b8ae3          	beqz	s7,80004e56 <exec+0x312>
    80004ee6:	89de                	mv	s3,s7
    80004ee8:	4481                	li	s1,0
    80004eea:	b371                	j	80004c76 <exec+0x132>

0000000080004eec <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004eec:	7179                	addi	sp,sp,-48
    80004eee:	f406                	sd	ra,40(sp)
    80004ef0:	f022                	sd	s0,32(sp)
    80004ef2:	ec26                	sd	s1,24(sp)
    80004ef4:	e84a                	sd	s2,16(sp)
    80004ef6:	1800                	addi	s0,sp,48
    80004ef8:	892e                	mv	s2,a1
    80004efa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004efc:	fdc40593          	addi	a1,s0,-36
    80004f00:	ffffe097          	auipc	ra,0xffffe
    80004f04:	b4c080e7          	jalr	-1204(ra) # 80002a4c <argint>
    80004f08:	04054063          	bltz	a0,80004f48 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f0c:	fdc42703          	lw	a4,-36(s0)
    80004f10:	47bd                	li	a5,15
    80004f12:	02e7ed63          	bltu	a5,a4,80004f4c <argfd+0x60>
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	a80080e7          	jalr	-1408(ra) # 80001996 <myproc>
    80004f1e:	fdc42703          	lw	a4,-36(s0)
    80004f22:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80004f26:	078e                	slli	a5,a5,0x3
    80004f28:	953e                	add	a0,a0,a5
    80004f2a:	611c                	ld	a5,0(a0)
    80004f2c:	c395                	beqz	a5,80004f50 <argfd+0x64>
    return -1;
  if(pfd)
    80004f2e:	00090463          	beqz	s2,80004f36 <argfd+0x4a>
    *pfd = fd;
    80004f32:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f36:	4501                	li	a0,0
  if(pf)
    80004f38:	c091                	beqz	s1,80004f3c <argfd+0x50>
    *pf = f;
    80004f3a:	e09c                	sd	a5,0(s1)
}
    80004f3c:	70a2                	ld	ra,40(sp)
    80004f3e:	7402                	ld	s0,32(sp)
    80004f40:	64e2                	ld	s1,24(sp)
    80004f42:	6942                	ld	s2,16(sp)
    80004f44:	6145                	addi	sp,sp,48
    80004f46:	8082                	ret
    return -1;
    80004f48:	557d                	li	a0,-1
    80004f4a:	bfcd                	j	80004f3c <argfd+0x50>
    return -1;
    80004f4c:	557d                	li	a0,-1
    80004f4e:	b7fd                	j	80004f3c <argfd+0x50>
    80004f50:	557d                	li	a0,-1
    80004f52:	b7ed                	j	80004f3c <argfd+0x50>

0000000080004f54 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f54:	1101                	addi	sp,sp,-32
    80004f56:	ec06                	sd	ra,24(sp)
    80004f58:	e822                	sd	s0,16(sp)
    80004f5a:	e426                	sd	s1,8(sp)
    80004f5c:	1000                	addi	s0,sp,32
    80004f5e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f60:	ffffd097          	auipc	ra,0xffffd
    80004f64:	a36080e7          	jalr	-1482(ra) # 80001996 <myproc>
    80004f68:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f6a:	0d050793          	addi	a5,a0,208
    80004f6e:	4501                	li	a0,0
    80004f70:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f72:	6398                	ld	a4,0(a5)
    80004f74:	cb19                	beqz	a4,80004f8a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f76:	2505                	addiw	a0,a0,1
    80004f78:	07a1                	addi	a5,a5,8
    80004f7a:	fed51ce3          	bne	a0,a3,80004f72 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f7e:	557d                	li	a0,-1
}
    80004f80:	60e2                	ld	ra,24(sp)
    80004f82:	6442                	ld	s0,16(sp)
    80004f84:	64a2                	ld	s1,8(sp)
    80004f86:	6105                	addi	sp,sp,32
    80004f88:	8082                	ret
      p->ofile[fd] = f;
    80004f8a:	01a50793          	addi	a5,a0,26
    80004f8e:	078e                	slli	a5,a5,0x3
    80004f90:	963e                	add	a2,a2,a5
    80004f92:	e204                	sd	s1,0(a2)
      return fd;
    80004f94:	b7f5                	j	80004f80 <fdalloc+0x2c>

0000000080004f96 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f96:	715d                	addi	sp,sp,-80
    80004f98:	e486                	sd	ra,72(sp)
    80004f9a:	e0a2                	sd	s0,64(sp)
    80004f9c:	fc26                	sd	s1,56(sp)
    80004f9e:	f84a                	sd	s2,48(sp)
    80004fa0:	f44e                	sd	s3,40(sp)
    80004fa2:	f052                	sd	s4,32(sp)
    80004fa4:	ec56                	sd	s5,24(sp)
    80004fa6:	0880                	addi	s0,sp,80
    80004fa8:	89ae                	mv	s3,a1
    80004faa:	8ab2                	mv	s5,a2
    80004fac:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004fae:	fb040593          	addi	a1,s0,-80
    80004fb2:	fffff097          	auipc	ra,0xfffff
    80004fb6:	e74080e7          	jalr	-396(ra) # 80003e26 <nameiparent>
    80004fba:	892a                	mv	s2,a0
    80004fbc:	12050e63          	beqz	a0,800050f8 <create+0x162>
    return 0;

  ilock(dp);
    80004fc0:	ffffe097          	auipc	ra,0xffffe
    80004fc4:	68c080e7          	jalr	1676(ra) # 8000364c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004fc8:	4601                	li	a2,0
    80004fca:	fb040593          	addi	a1,s0,-80
    80004fce:	854a                	mv	a0,s2
    80004fd0:	fffff097          	auipc	ra,0xfffff
    80004fd4:	b60080e7          	jalr	-1184(ra) # 80003b30 <dirlookup>
    80004fd8:	84aa                	mv	s1,a0
    80004fda:	c921                	beqz	a0,8000502a <create+0x94>
    iunlockput(dp);
    80004fdc:	854a                	mv	a0,s2
    80004fde:	fffff097          	auipc	ra,0xfffff
    80004fe2:	8d0080e7          	jalr	-1840(ra) # 800038ae <iunlockput>
    ilock(ip);
    80004fe6:	8526                	mv	a0,s1
    80004fe8:	ffffe097          	auipc	ra,0xffffe
    80004fec:	664080e7          	jalr	1636(ra) # 8000364c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004ff0:	2981                	sext.w	s3,s3
    80004ff2:	4789                	li	a5,2
    80004ff4:	02f99463          	bne	s3,a5,8000501c <create+0x86>
    80004ff8:	0444d783          	lhu	a5,68(s1)
    80004ffc:	37f9                	addiw	a5,a5,-2
    80004ffe:	17c2                	slli	a5,a5,0x30
    80005000:	93c1                	srli	a5,a5,0x30
    80005002:	4705                	li	a4,1
    80005004:	00f76c63          	bltu	a4,a5,8000501c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005008:	8526                	mv	a0,s1
    8000500a:	60a6                	ld	ra,72(sp)
    8000500c:	6406                	ld	s0,64(sp)
    8000500e:	74e2                	ld	s1,56(sp)
    80005010:	7942                	ld	s2,48(sp)
    80005012:	79a2                	ld	s3,40(sp)
    80005014:	7a02                	ld	s4,32(sp)
    80005016:	6ae2                	ld	s5,24(sp)
    80005018:	6161                	addi	sp,sp,80
    8000501a:	8082                	ret
    iunlockput(ip);
    8000501c:	8526                	mv	a0,s1
    8000501e:	fffff097          	auipc	ra,0xfffff
    80005022:	890080e7          	jalr	-1904(ra) # 800038ae <iunlockput>
    return 0;
    80005026:	4481                	li	s1,0
    80005028:	b7c5                	j	80005008 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000502a:	85ce                	mv	a1,s3
    8000502c:	00092503          	lw	a0,0(s2)
    80005030:	ffffe097          	auipc	ra,0xffffe
    80005034:	482080e7          	jalr	1154(ra) # 800034b2 <ialloc>
    80005038:	84aa                	mv	s1,a0
    8000503a:	c521                	beqz	a0,80005082 <create+0xec>
  ilock(ip);
    8000503c:	ffffe097          	auipc	ra,0xffffe
    80005040:	610080e7          	jalr	1552(ra) # 8000364c <ilock>
  ip->major = major;
    80005044:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005048:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000504c:	4a05                	li	s4,1
    8000504e:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005052:	8526                	mv	a0,s1
    80005054:	ffffe097          	auipc	ra,0xffffe
    80005058:	52c080e7          	jalr	1324(ra) # 80003580 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000505c:	2981                	sext.w	s3,s3
    8000505e:	03498a63          	beq	s3,s4,80005092 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005062:	40d0                	lw	a2,4(s1)
    80005064:	fb040593          	addi	a1,s0,-80
    80005068:	854a                	mv	a0,s2
    8000506a:	fffff097          	auipc	ra,0xfffff
    8000506e:	cdc080e7          	jalr	-804(ra) # 80003d46 <dirlink>
    80005072:	06054b63          	bltz	a0,800050e8 <create+0x152>
  iunlockput(dp);
    80005076:	854a                	mv	a0,s2
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	836080e7          	jalr	-1994(ra) # 800038ae <iunlockput>
  return ip;
    80005080:	b761                	j	80005008 <create+0x72>
    panic("create: ialloc");
    80005082:	00003517          	auipc	a0,0x3
    80005086:	67e50513          	addi	a0,a0,1662 # 80008700 <syscalls+0x2b8>
    8000508a:	ffffb097          	auipc	ra,0xffffb
    8000508e:	4b0080e7          	jalr	1200(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    80005092:	04a95783          	lhu	a5,74(s2)
    80005096:	2785                	addiw	a5,a5,1
    80005098:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000509c:	854a                	mv	a0,s2
    8000509e:	ffffe097          	auipc	ra,0xffffe
    800050a2:	4e2080e7          	jalr	1250(ra) # 80003580 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050a6:	40d0                	lw	a2,4(s1)
    800050a8:	00003597          	auipc	a1,0x3
    800050ac:	66858593          	addi	a1,a1,1640 # 80008710 <syscalls+0x2c8>
    800050b0:	8526                	mv	a0,s1
    800050b2:	fffff097          	auipc	ra,0xfffff
    800050b6:	c94080e7          	jalr	-876(ra) # 80003d46 <dirlink>
    800050ba:	00054f63          	bltz	a0,800050d8 <create+0x142>
    800050be:	00492603          	lw	a2,4(s2)
    800050c2:	00003597          	auipc	a1,0x3
    800050c6:	65658593          	addi	a1,a1,1622 # 80008718 <syscalls+0x2d0>
    800050ca:	8526                	mv	a0,s1
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	c7a080e7          	jalr	-902(ra) # 80003d46 <dirlink>
    800050d4:	f80557e3          	bgez	a0,80005062 <create+0xcc>
      panic("create dots");
    800050d8:	00003517          	auipc	a0,0x3
    800050dc:	64850513          	addi	a0,a0,1608 # 80008720 <syscalls+0x2d8>
    800050e0:	ffffb097          	auipc	ra,0xffffb
    800050e4:	45a080e7          	jalr	1114(ra) # 8000053a <panic>
    panic("create: dirlink");
    800050e8:	00003517          	auipc	a0,0x3
    800050ec:	64850513          	addi	a0,a0,1608 # 80008730 <syscalls+0x2e8>
    800050f0:	ffffb097          	auipc	ra,0xffffb
    800050f4:	44a080e7          	jalr	1098(ra) # 8000053a <panic>
    return 0;
    800050f8:	84aa                	mv	s1,a0
    800050fa:	b739                	j	80005008 <create+0x72>

00000000800050fc <sys_dup>:
{
    800050fc:	7179                	addi	sp,sp,-48
    800050fe:	f406                	sd	ra,40(sp)
    80005100:	f022                	sd	s0,32(sp)
    80005102:	ec26                	sd	s1,24(sp)
    80005104:	e84a                	sd	s2,16(sp)
    80005106:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005108:	fd840613          	addi	a2,s0,-40
    8000510c:	4581                	li	a1,0
    8000510e:	4501                	li	a0,0
    80005110:	00000097          	auipc	ra,0x0
    80005114:	ddc080e7          	jalr	-548(ra) # 80004eec <argfd>
    return -1;
    80005118:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000511a:	02054363          	bltz	a0,80005140 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000511e:	fd843903          	ld	s2,-40(s0)
    80005122:	854a                	mv	a0,s2
    80005124:	00000097          	auipc	ra,0x0
    80005128:	e30080e7          	jalr	-464(ra) # 80004f54 <fdalloc>
    8000512c:	84aa                	mv	s1,a0
    return -1;
    8000512e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005130:	00054863          	bltz	a0,80005140 <sys_dup+0x44>
  filedup(f);
    80005134:	854a                	mv	a0,s2
    80005136:	fffff097          	auipc	ra,0xfffff
    8000513a:	368080e7          	jalr	872(ra) # 8000449e <filedup>
  return fd;
    8000513e:	87a6                	mv	a5,s1
}
    80005140:	853e                	mv	a0,a5
    80005142:	70a2                	ld	ra,40(sp)
    80005144:	7402                	ld	s0,32(sp)
    80005146:	64e2                	ld	s1,24(sp)
    80005148:	6942                	ld	s2,16(sp)
    8000514a:	6145                	addi	sp,sp,48
    8000514c:	8082                	ret

000000008000514e <sys_read>:
{
    8000514e:	7179                	addi	sp,sp,-48
    80005150:	f406                	sd	ra,40(sp)
    80005152:	f022                	sd	s0,32(sp)
    80005154:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005156:	fe840613          	addi	a2,s0,-24
    8000515a:	4581                	li	a1,0
    8000515c:	4501                	li	a0,0
    8000515e:	00000097          	auipc	ra,0x0
    80005162:	d8e080e7          	jalr	-626(ra) # 80004eec <argfd>
    return -1;
    80005166:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005168:	04054163          	bltz	a0,800051aa <sys_read+0x5c>
    8000516c:	fe440593          	addi	a1,s0,-28
    80005170:	4509                	li	a0,2
    80005172:	ffffe097          	auipc	ra,0xffffe
    80005176:	8da080e7          	jalr	-1830(ra) # 80002a4c <argint>
    return -1;
    8000517a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000517c:	02054763          	bltz	a0,800051aa <sys_read+0x5c>
    80005180:	fd840593          	addi	a1,s0,-40
    80005184:	4505                	li	a0,1
    80005186:	ffffe097          	auipc	ra,0xffffe
    8000518a:	8e8080e7          	jalr	-1816(ra) # 80002a6e <argaddr>
    return -1;
    8000518e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005190:	00054d63          	bltz	a0,800051aa <sys_read+0x5c>
  return fileread(f, p, n);
    80005194:	fe442603          	lw	a2,-28(s0)
    80005198:	fd843583          	ld	a1,-40(s0)
    8000519c:	fe843503          	ld	a0,-24(s0)
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	48a080e7          	jalr	1162(ra) # 8000462a <fileread>
    800051a8:	87aa                	mv	a5,a0
}
    800051aa:	853e                	mv	a0,a5
    800051ac:	70a2                	ld	ra,40(sp)
    800051ae:	7402                	ld	s0,32(sp)
    800051b0:	6145                	addi	sp,sp,48
    800051b2:	8082                	ret

00000000800051b4 <sys_write>:
{
    800051b4:	7179                	addi	sp,sp,-48
    800051b6:	f406                	sd	ra,40(sp)
    800051b8:	f022                	sd	s0,32(sp)
    800051ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051bc:	fe840613          	addi	a2,s0,-24
    800051c0:	4581                	li	a1,0
    800051c2:	4501                	li	a0,0
    800051c4:	00000097          	auipc	ra,0x0
    800051c8:	d28080e7          	jalr	-728(ra) # 80004eec <argfd>
    return -1;
    800051cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ce:	04054163          	bltz	a0,80005210 <sys_write+0x5c>
    800051d2:	fe440593          	addi	a1,s0,-28
    800051d6:	4509                	li	a0,2
    800051d8:	ffffe097          	auipc	ra,0xffffe
    800051dc:	874080e7          	jalr	-1932(ra) # 80002a4c <argint>
    return -1;
    800051e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051e2:	02054763          	bltz	a0,80005210 <sys_write+0x5c>
    800051e6:	fd840593          	addi	a1,s0,-40
    800051ea:	4505                	li	a0,1
    800051ec:	ffffe097          	auipc	ra,0xffffe
    800051f0:	882080e7          	jalr	-1918(ra) # 80002a6e <argaddr>
    return -1;
    800051f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051f6:	00054d63          	bltz	a0,80005210 <sys_write+0x5c>
  return filewrite(f, p, n);
    800051fa:	fe442603          	lw	a2,-28(s0)
    800051fe:	fd843583          	ld	a1,-40(s0)
    80005202:	fe843503          	ld	a0,-24(s0)
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	4e6080e7          	jalr	1254(ra) # 800046ec <filewrite>
    8000520e:	87aa                	mv	a5,a0
}
    80005210:	853e                	mv	a0,a5
    80005212:	70a2                	ld	ra,40(sp)
    80005214:	7402                	ld	s0,32(sp)
    80005216:	6145                	addi	sp,sp,48
    80005218:	8082                	ret

000000008000521a <sys_close>:
{
    8000521a:	1101                	addi	sp,sp,-32
    8000521c:	ec06                	sd	ra,24(sp)
    8000521e:	e822                	sd	s0,16(sp)
    80005220:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005222:	fe040613          	addi	a2,s0,-32
    80005226:	fec40593          	addi	a1,s0,-20
    8000522a:	4501                	li	a0,0
    8000522c:	00000097          	auipc	ra,0x0
    80005230:	cc0080e7          	jalr	-832(ra) # 80004eec <argfd>
    return -1;
    80005234:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005236:	02054463          	bltz	a0,8000525e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000523a:	ffffc097          	auipc	ra,0xffffc
    8000523e:	75c080e7          	jalr	1884(ra) # 80001996 <myproc>
    80005242:	fec42783          	lw	a5,-20(s0)
    80005246:	07e9                	addi	a5,a5,26
    80005248:	078e                	slli	a5,a5,0x3
    8000524a:	953e                	add	a0,a0,a5
    8000524c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005250:	fe043503          	ld	a0,-32(s0)
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	29c080e7          	jalr	668(ra) # 800044f0 <fileclose>
  return 0;
    8000525c:	4781                	li	a5,0
}
    8000525e:	853e                	mv	a0,a5
    80005260:	60e2                	ld	ra,24(sp)
    80005262:	6442                	ld	s0,16(sp)
    80005264:	6105                	addi	sp,sp,32
    80005266:	8082                	ret

0000000080005268 <sys_fstat>:
{
    80005268:	1101                	addi	sp,sp,-32
    8000526a:	ec06                	sd	ra,24(sp)
    8000526c:	e822                	sd	s0,16(sp)
    8000526e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005270:	fe840613          	addi	a2,s0,-24
    80005274:	4581                	li	a1,0
    80005276:	4501                	li	a0,0
    80005278:	00000097          	auipc	ra,0x0
    8000527c:	c74080e7          	jalr	-908(ra) # 80004eec <argfd>
    return -1;
    80005280:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005282:	02054563          	bltz	a0,800052ac <sys_fstat+0x44>
    80005286:	fe040593          	addi	a1,s0,-32
    8000528a:	4505                	li	a0,1
    8000528c:	ffffd097          	auipc	ra,0xffffd
    80005290:	7e2080e7          	jalr	2018(ra) # 80002a6e <argaddr>
    return -1;
    80005294:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005296:	00054b63          	bltz	a0,800052ac <sys_fstat+0x44>
  return filestat(f, st);
    8000529a:	fe043583          	ld	a1,-32(s0)
    8000529e:	fe843503          	ld	a0,-24(s0)
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	316080e7          	jalr	790(ra) # 800045b8 <filestat>
    800052aa:	87aa                	mv	a5,a0
}
    800052ac:	853e                	mv	a0,a5
    800052ae:	60e2                	ld	ra,24(sp)
    800052b0:	6442                	ld	s0,16(sp)
    800052b2:	6105                	addi	sp,sp,32
    800052b4:	8082                	ret

00000000800052b6 <sys_link>:
{
    800052b6:	7169                	addi	sp,sp,-304
    800052b8:	f606                	sd	ra,296(sp)
    800052ba:	f222                	sd	s0,288(sp)
    800052bc:	ee26                	sd	s1,280(sp)
    800052be:	ea4a                	sd	s2,272(sp)
    800052c0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052c2:	08000613          	li	a2,128
    800052c6:	ed040593          	addi	a1,s0,-304
    800052ca:	4501                	li	a0,0
    800052cc:	ffffd097          	auipc	ra,0xffffd
    800052d0:	7c4080e7          	jalr	1988(ra) # 80002a90 <argstr>
    return -1;
    800052d4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052d6:	10054e63          	bltz	a0,800053f2 <sys_link+0x13c>
    800052da:	08000613          	li	a2,128
    800052de:	f5040593          	addi	a1,s0,-176
    800052e2:	4505                	li	a0,1
    800052e4:	ffffd097          	auipc	ra,0xffffd
    800052e8:	7ac080e7          	jalr	1964(ra) # 80002a90 <argstr>
    return -1;
    800052ec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052ee:	10054263          	bltz	a0,800053f2 <sys_link+0x13c>
  begin_op();
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	d36080e7          	jalr	-714(ra) # 80004028 <begin_op>
  if((ip = namei(old)) == 0){
    800052fa:	ed040513          	addi	a0,s0,-304
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	b0a080e7          	jalr	-1270(ra) # 80003e08 <namei>
    80005306:	84aa                	mv	s1,a0
    80005308:	c551                	beqz	a0,80005394 <sys_link+0xde>
  ilock(ip);
    8000530a:	ffffe097          	auipc	ra,0xffffe
    8000530e:	342080e7          	jalr	834(ra) # 8000364c <ilock>
  if(ip->type == T_DIR){
    80005312:	04449703          	lh	a4,68(s1)
    80005316:	4785                	li	a5,1
    80005318:	08f70463          	beq	a4,a5,800053a0 <sys_link+0xea>
  ip->nlink++;
    8000531c:	04a4d783          	lhu	a5,74(s1)
    80005320:	2785                	addiw	a5,a5,1
    80005322:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005326:	8526                	mv	a0,s1
    80005328:	ffffe097          	auipc	ra,0xffffe
    8000532c:	258080e7          	jalr	600(ra) # 80003580 <iupdate>
  iunlock(ip);
    80005330:	8526                	mv	a0,s1
    80005332:	ffffe097          	auipc	ra,0xffffe
    80005336:	3dc080e7          	jalr	988(ra) # 8000370e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000533a:	fd040593          	addi	a1,s0,-48
    8000533e:	f5040513          	addi	a0,s0,-176
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	ae4080e7          	jalr	-1308(ra) # 80003e26 <nameiparent>
    8000534a:	892a                	mv	s2,a0
    8000534c:	c935                	beqz	a0,800053c0 <sys_link+0x10a>
  ilock(dp);
    8000534e:	ffffe097          	auipc	ra,0xffffe
    80005352:	2fe080e7          	jalr	766(ra) # 8000364c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005356:	00092703          	lw	a4,0(s2)
    8000535a:	409c                	lw	a5,0(s1)
    8000535c:	04f71d63          	bne	a4,a5,800053b6 <sys_link+0x100>
    80005360:	40d0                	lw	a2,4(s1)
    80005362:	fd040593          	addi	a1,s0,-48
    80005366:	854a                	mv	a0,s2
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	9de080e7          	jalr	-1570(ra) # 80003d46 <dirlink>
    80005370:	04054363          	bltz	a0,800053b6 <sys_link+0x100>
  iunlockput(dp);
    80005374:	854a                	mv	a0,s2
    80005376:	ffffe097          	auipc	ra,0xffffe
    8000537a:	538080e7          	jalr	1336(ra) # 800038ae <iunlockput>
  iput(ip);
    8000537e:	8526                	mv	a0,s1
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	486080e7          	jalr	1158(ra) # 80003806 <iput>
  end_op();
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	d1e080e7          	jalr	-738(ra) # 800040a6 <end_op>
  return 0;
    80005390:	4781                	li	a5,0
    80005392:	a085                	j	800053f2 <sys_link+0x13c>
    end_op();
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	d12080e7          	jalr	-750(ra) # 800040a6 <end_op>
    return -1;
    8000539c:	57fd                	li	a5,-1
    8000539e:	a891                	j	800053f2 <sys_link+0x13c>
    iunlockput(ip);
    800053a0:	8526                	mv	a0,s1
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	50c080e7          	jalr	1292(ra) # 800038ae <iunlockput>
    end_op();
    800053aa:	fffff097          	auipc	ra,0xfffff
    800053ae:	cfc080e7          	jalr	-772(ra) # 800040a6 <end_op>
    return -1;
    800053b2:	57fd                	li	a5,-1
    800053b4:	a83d                	j	800053f2 <sys_link+0x13c>
    iunlockput(dp);
    800053b6:	854a                	mv	a0,s2
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	4f6080e7          	jalr	1270(ra) # 800038ae <iunlockput>
  ilock(ip);
    800053c0:	8526                	mv	a0,s1
    800053c2:	ffffe097          	auipc	ra,0xffffe
    800053c6:	28a080e7          	jalr	650(ra) # 8000364c <ilock>
  ip->nlink--;
    800053ca:	04a4d783          	lhu	a5,74(s1)
    800053ce:	37fd                	addiw	a5,a5,-1
    800053d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053d4:	8526                	mv	a0,s1
    800053d6:	ffffe097          	auipc	ra,0xffffe
    800053da:	1aa080e7          	jalr	426(ra) # 80003580 <iupdate>
  iunlockput(ip);
    800053de:	8526                	mv	a0,s1
    800053e0:	ffffe097          	auipc	ra,0xffffe
    800053e4:	4ce080e7          	jalr	1230(ra) # 800038ae <iunlockput>
  end_op();
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	cbe080e7          	jalr	-834(ra) # 800040a6 <end_op>
  return -1;
    800053f0:	57fd                	li	a5,-1
}
    800053f2:	853e                	mv	a0,a5
    800053f4:	70b2                	ld	ra,296(sp)
    800053f6:	7412                	ld	s0,288(sp)
    800053f8:	64f2                	ld	s1,280(sp)
    800053fa:	6952                	ld	s2,272(sp)
    800053fc:	6155                	addi	sp,sp,304
    800053fe:	8082                	ret

0000000080005400 <sys_unlink>:
{
    80005400:	7151                	addi	sp,sp,-240
    80005402:	f586                	sd	ra,232(sp)
    80005404:	f1a2                	sd	s0,224(sp)
    80005406:	eda6                	sd	s1,216(sp)
    80005408:	e9ca                	sd	s2,208(sp)
    8000540a:	e5ce                	sd	s3,200(sp)
    8000540c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000540e:	08000613          	li	a2,128
    80005412:	f3040593          	addi	a1,s0,-208
    80005416:	4501                	li	a0,0
    80005418:	ffffd097          	auipc	ra,0xffffd
    8000541c:	678080e7          	jalr	1656(ra) # 80002a90 <argstr>
    80005420:	18054163          	bltz	a0,800055a2 <sys_unlink+0x1a2>
  begin_op();
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	c04080e7          	jalr	-1020(ra) # 80004028 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000542c:	fb040593          	addi	a1,s0,-80
    80005430:	f3040513          	addi	a0,s0,-208
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	9f2080e7          	jalr	-1550(ra) # 80003e26 <nameiparent>
    8000543c:	84aa                	mv	s1,a0
    8000543e:	c979                	beqz	a0,80005514 <sys_unlink+0x114>
  ilock(dp);
    80005440:	ffffe097          	auipc	ra,0xffffe
    80005444:	20c080e7          	jalr	524(ra) # 8000364c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005448:	00003597          	auipc	a1,0x3
    8000544c:	2c858593          	addi	a1,a1,712 # 80008710 <syscalls+0x2c8>
    80005450:	fb040513          	addi	a0,s0,-80
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	6c2080e7          	jalr	1730(ra) # 80003b16 <namecmp>
    8000545c:	14050a63          	beqz	a0,800055b0 <sys_unlink+0x1b0>
    80005460:	00003597          	auipc	a1,0x3
    80005464:	2b858593          	addi	a1,a1,696 # 80008718 <syscalls+0x2d0>
    80005468:	fb040513          	addi	a0,s0,-80
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	6aa080e7          	jalr	1706(ra) # 80003b16 <namecmp>
    80005474:	12050e63          	beqz	a0,800055b0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005478:	f2c40613          	addi	a2,s0,-212
    8000547c:	fb040593          	addi	a1,s0,-80
    80005480:	8526                	mv	a0,s1
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	6ae080e7          	jalr	1710(ra) # 80003b30 <dirlookup>
    8000548a:	892a                	mv	s2,a0
    8000548c:	12050263          	beqz	a0,800055b0 <sys_unlink+0x1b0>
  ilock(ip);
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	1bc080e7          	jalr	444(ra) # 8000364c <ilock>
  if(ip->nlink < 1)
    80005498:	04a91783          	lh	a5,74(s2)
    8000549c:	08f05263          	blez	a5,80005520 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800054a0:	04491703          	lh	a4,68(s2)
    800054a4:	4785                	li	a5,1
    800054a6:	08f70563          	beq	a4,a5,80005530 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054aa:	4641                	li	a2,16
    800054ac:	4581                	li	a1,0
    800054ae:	fc040513          	addi	a0,s0,-64
    800054b2:	ffffc097          	auipc	ra,0xffffc
    800054b6:	81a080e7          	jalr	-2022(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ba:	4741                	li	a4,16
    800054bc:	f2c42683          	lw	a3,-212(s0)
    800054c0:	fc040613          	addi	a2,s0,-64
    800054c4:	4581                	li	a1,0
    800054c6:	8526                	mv	a0,s1
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	530080e7          	jalr	1328(ra) # 800039f8 <writei>
    800054d0:	47c1                	li	a5,16
    800054d2:	0af51563          	bne	a0,a5,8000557c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800054d6:	04491703          	lh	a4,68(s2)
    800054da:	4785                	li	a5,1
    800054dc:	0af70863          	beq	a4,a5,8000558c <sys_unlink+0x18c>
  iunlockput(dp);
    800054e0:	8526                	mv	a0,s1
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	3cc080e7          	jalr	972(ra) # 800038ae <iunlockput>
  ip->nlink--;
    800054ea:	04a95783          	lhu	a5,74(s2)
    800054ee:	37fd                	addiw	a5,a5,-1
    800054f0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800054f4:	854a                	mv	a0,s2
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	08a080e7          	jalr	138(ra) # 80003580 <iupdate>
  iunlockput(ip);
    800054fe:	854a                	mv	a0,s2
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	3ae080e7          	jalr	942(ra) # 800038ae <iunlockput>
  end_op();
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	b9e080e7          	jalr	-1122(ra) # 800040a6 <end_op>
  return 0;
    80005510:	4501                	li	a0,0
    80005512:	a84d                	j	800055c4 <sys_unlink+0x1c4>
    end_op();
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	b92080e7          	jalr	-1134(ra) # 800040a6 <end_op>
    return -1;
    8000551c:	557d                	li	a0,-1
    8000551e:	a05d                	j	800055c4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005520:	00003517          	auipc	a0,0x3
    80005524:	22050513          	addi	a0,a0,544 # 80008740 <syscalls+0x2f8>
    80005528:	ffffb097          	auipc	ra,0xffffb
    8000552c:	012080e7          	jalr	18(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005530:	04c92703          	lw	a4,76(s2)
    80005534:	02000793          	li	a5,32
    80005538:	f6e7f9e3          	bgeu	a5,a4,800054aa <sys_unlink+0xaa>
    8000553c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005540:	4741                	li	a4,16
    80005542:	86ce                	mv	a3,s3
    80005544:	f1840613          	addi	a2,s0,-232
    80005548:	4581                	li	a1,0
    8000554a:	854a                	mv	a0,s2
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	3b4080e7          	jalr	948(ra) # 80003900 <readi>
    80005554:	47c1                	li	a5,16
    80005556:	00f51b63          	bne	a0,a5,8000556c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000555a:	f1845783          	lhu	a5,-232(s0)
    8000555e:	e7a1                	bnez	a5,800055a6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005560:	29c1                	addiw	s3,s3,16
    80005562:	04c92783          	lw	a5,76(s2)
    80005566:	fcf9ede3          	bltu	s3,a5,80005540 <sys_unlink+0x140>
    8000556a:	b781                	j	800054aa <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000556c:	00003517          	auipc	a0,0x3
    80005570:	1ec50513          	addi	a0,a0,492 # 80008758 <syscalls+0x310>
    80005574:	ffffb097          	auipc	ra,0xffffb
    80005578:	fc6080e7          	jalr	-58(ra) # 8000053a <panic>
    panic("unlink: writei");
    8000557c:	00003517          	auipc	a0,0x3
    80005580:	1f450513          	addi	a0,a0,500 # 80008770 <syscalls+0x328>
    80005584:	ffffb097          	auipc	ra,0xffffb
    80005588:	fb6080e7          	jalr	-74(ra) # 8000053a <panic>
    dp->nlink--;
    8000558c:	04a4d783          	lhu	a5,74(s1)
    80005590:	37fd                	addiw	a5,a5,-1
    80005592:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005596:	8526                	mv	a0,s1
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	fe8080e7          	jalr	-24(ra) # 80003580 <iupdate>
    800055a0:	b781                	j	800054e0 <sys_unlink+0xe0>
    return -1;
    800055a2:	557d                	li	a0,-1
    800055a4:	a005                	j	800055c4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800055a6:	854a                	mv	a0,s2
    800055a8:	ffffe097          	auipc	ra,0xffffe
    800055ac:	306080e7          	jalr	774(ra) # 800038ae <iunlockput>
  iunlockput(dp);
    800055b0:	8526                	mv	a0,s1
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	2fc080e7          	jalr	764(ra) # 800038ae <iunlockput>
  end_op();
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	aec080e7          	jalr	-1300(ra) # 800040a6 <end_op>
  return -1;
    800055c2:	557d                	li	a0,-1
}
    800055c4:	70ae                	ld	ra,232(sp)
    800055c6:	740e                	ld	s0,224(sp)
    800055c8:	64ee                	ld	s1,216(sp)
    800055ca:	694e                	ld	s2,208(sp)
    800055cc:	69ae                	ld	s3,200(sp)
    800055ce:	616d                	addi	sp,sp,240
    800055d0:	8082                	ret

00000000800055d2 <sys_open>:

uint64
sys_open(void)
{
    800055d2:	7131                	addi	sp,sp,-192
    800055d4:	fd06                	sd	ra,184(sp)
    800055d6:	f922                	sd	s0,176(sp)
    800055d8:	f526                	sd	s1,168(sp)
    800055da:	f14a                	sd	s2,160(sp)
    800055dc:	ed4e                	sd	s3,152(sp)
    800055de:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055e0:	08000613          	li	a2,128
    800055e4:	f5040593          	addi	a1,s0,-176
    800055e8:	4501                	li	a0,0
    800055ea:	ffffd097          	auipc	ra,0xffffd
    800055ee:	4a6080e7          	jalr	1190(ra) # 80002a90 <argstr>
    return -1;
    800055f2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055f4:	0c054163          	bltz	a0,800056b6 <sys_open+0xe4>
    800055f8:	f4c40593          	addi	a1,s0,-180
    800055fc:	4505                	li	a0,1
    800055fe:	ffffd097          	auipc	ra,0xffffd
    80005602:	44e080e7          	jalr	1102(ra) # 80002a4c <argint>
    80005606:	0a054863          	bltz	a0,800056b6 <sys_open+0xe4>

  begin_op();
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	a1e080e7          	jalr	-1506(ra) # 80004028 <begin_op>

  if(omode & O_CREATE){
    80005612:	f4c42783          	lw	a5,-180(s0)
    80005616:	2007f793          	andi	a5,a5,512
    8000561a:	cbdd                	beqz	a5,800056d0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000561c:	4681                	li	a3,0
    8000561e:	4601                	li	a2,0
    80005620:	4589                	li	a1,2
    80005622:	f5040513          	addi	a0,s0,-176
    80005626:	00000097          	auipc	ra,0x0
    8000562a:	970080e7          	jalr	-1680(ra) # 80004f96 <create>
    8000562e:	892a                	mv	s2,a0
    if(ip == 0){
    80005630:	c959                	beqz	a0,800056c6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005632:	04491703          	lh	a4,68(s2)
    80005636:	478d                	li	a5,3
    80005638:	00f71763          	bne	a4,a5,80005646 <sys_open+0x74>
    8000563c:	04695703          	lhu	a4,70(s2)
    80005640:	47a5                	li	a5,9
    80005642:	0ce7ec63          	bltu	a5,a4,8000571a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	dee080e7          	jalr	-530(ra) # 80004434 <filealloc>
    8000564e:	89aa                	mv	s3,a0
    80005650:	10050263          	beqz	a0,80005754 <sys_open+0x182>
    80005654:	00000097          	auipc	ra,0x0
    80005658:	900080e7          	jalr	-1792(ra) # 80004f54 <fdalloc>
    8000565c:	84aa                	mv	s1,a0
    8000565e:	0e054663          	bltz	a0,8000574a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005662:	04491703          	lh	a4,68(s2)
    80005666:	478d                	li	a5,3
    80005668:	0cf70463          	beq	a4,a5,80005730 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000566c:	4789                	li	a5,2
    8000566e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005672:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005676:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000567a:	f4c42783          	lw	a5,-180(s0)
    8000567e:	0017c713          	xori	a4,a5,1
    80005682:	8b05                	andi	a4,a4,1
    80005684:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005688:	0037f713          	andi	a4,a5,3
    8000568c:	00e03733          	snez	a4,a4
    80005690:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005694:	4007f793          	andi	a5,a5,1024
    80005698:	c791                	beqz	a5,800056a4 <sys_open+0xd2>
    8000569a:	04491703          	lh	a4,68(s2)
    8000569e:	4789                	li	a5,2
    800056a0:	08f70f63          	beq	a4,a5,8000573e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800056a4:	854a                	mv	a0,s2
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	068080e7          	jalr	104(ra) # 8000370e <iunlock>
  end_op();
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	9f8080e7          	jalr	-1544(ra) # 800040a6 <end_op>

  return fd;
}
    800056b6:	8526                	mv	a0,s1
    800056b8:	70ea                	ld	ra,184(sp)
    800056ba:	744a                	ld	s0,176(sp)
    800056bc:	74aa                	ld	s1,168(sp)
    800056be:	790a                	ld	s2,160(sp)
    800056c0:	69ea                	ld	s3,152(sp)
    800056c2:	6129                	addi	sp,sp,192
    800056c4:	8082                	ret
      end_op();
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	9e0080e7          	jalr	-1568(ra) # 800040a6 <end_op>
      return -1;
    800056ce:	b7e5                	j	800056b6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800056d0:	f5040513          	addi	a0,s0,-176
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	734080e7          	jalr	1844(ra) # 80003e08 <namei>
    800056dc:	892a                	mv	s2,a0
    800056de:	c905                	beqz	a0,8000570e <sys_open+0x13c>
    ilock(ip);
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	f6c080e7          	jalr	-148(ra) # 8000364c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800056e8:	04491703          	lh	a4,68(s2)
    800056ec:	4785                	li	a5,1
    800056ee:	f4f712e3          	bne	a4,a5,80005632 <sys_open+0x60>
    800056f2:	f4c42783          	lw	a5,-180(s0)
    800056f6:	dba1                	beqz	a5,80005646 <sys_open+0x74>
      iunlockput(ip);
    800056f8:	854a                	mv	a0,s2
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	1b4080e7          	jalr	436(ra) # 800038ae <iunlockput>
      end_op();
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	9a4080e7          	jalr	-1628(ra) # 800040a6 <end_op>
      return -1;
    8000570a:	54fd                	li	s1,-1
    8000570c:	b76d                	j	800056b6 <sys_open+0xe4>
      end_op();
    8000570e:	fffff097          	auipc	ra,0xfffff
    80005712:	998080e7          	jalr	-1640(ra) # 800040a6 <end_op>
      return -1;
    80005716:	54fd                	li	s1,-1
    80005718:	bf79                	j	800056b6 <sys_open+0xe4>
    iunlockput(ip);
    8000571a:	854a                	mv	a0,s2
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	192080e7          	jalr	402(ra) # 800038ae <iunlockput>
    end_op();
    80005724:	fffff097          	auipc	ra,0xfffff
    80005728:	982080e7          	jalr	-1662(ra) # 800040a6 <end_op>
    return -1;
    8000572c:	54fd                	li	s1,-1
    8000572e:	b761                	j	800056b6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005730:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005734:	04691783          	lh	a5,70(s2)
    80005738:	02f99223          	sh	a5,36(s3)
    8000573c:	bf2d                	j	80005676 <sys_open+0xa4>
    itrunc(ip);
    8000573e:	854a                	mv	a0,s2
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	01a080e7          	jalr	26(ra) # 8000375a <itrunc>
    80005748:	bfb1                	j	800056a4 <sys_open+0xd2>
      fileclose(f);
    8000574a:	854e                	mv	a0,s3
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	da4080e7          	jalr	-604(ra) # 800044f0 <fileclose>
    iunlockput(ip);
    80005754:	854a                	mv	a0,s2
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	158080e7          	jalr	344(ra) # 800038ae <iunlockput>
    end_op();
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	948080e7          	jalr	-1720(ra) # 800040a6 <end_op>
    return -1;
    80005766:	54fd                	li	s1,-1
    80005768:	b7b9                	j	800056b6 <sys_open+0xe4>

000000008000576a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000576a:	7175                	addi	sp,sp,-144
    8000576c:	e506                	sd	ra,136(sp)
    8000576e:	e122                	sd	s0,128(sp)
    80005770:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	8b6080e7          	jalr	-1866(ra) # 80004028 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000577a:	08000613          	li	a2,128
    8000577e:	f7040593          	addi	a1,s0,-144
    80005782:	4501                	li	a0,0
    80005784:	ffffd097          	auipc	ra,0xffffd
    80005788:	30c080e7          	jalr	780(ra) # 80002a90 <argstr>
    8000578c:	02054963          	bltz	a0,800057be <sys_mkdir+0x54>
    80005790:	4681                	li	a3,0
    80005792:	4601                	li	a2,0
    80005794:	4585                	li	a1,1
    80005796:	f7040513          	addi	a0,s0,-144
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	7fc080e7          	jalr	2044(ra) # 80004f96 <create>
    800057a2:	cd11                	beqz	a0,800057be <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	10a080e7          	jalr	266(ra) # 800038ae <iunlockput>
  end_op();
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	8fa080e7          	jalr	-1798(ra) # 800040a6 <end_op>
  return 0;
    800057b4:	4501                	li	a0,0
}
    800057b6:	60aa                	ld	ra,136(sp)
    800057b8:	640a                	ld	s0,128(sp)
    800057ba:	6149                	addi	sp,sp,144
    800057bc:	8082                	ret
    end_op();
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	8e8080e7          	jalr	-1816(ra) # 800040a6 <end_op>
    return -1;
    800057c6:	557d                	li	a0,-1
    800057c8:	b7fd                	j	800057b6 <sys_mkdir+0x4c>

00000000800057ca <sys_mknod>:

uint64
sys_mknod(void)
{
    800057ca:	7135                	addi	sp,sp,-160
    800057cc:	ed06                	sd	ra,152(sp)
    800057ce:	e922                	sd	s0,144(sp)
    800057d0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	856080e7          	jalr	-1962(ra) # 80004028 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057da:	08000613          	li	a2,128
    800057de:	f7040593          	addi	a1,s0,-144
    800057e2:	4501                	li	a0,0
    800057e4:	ffffd097          	auipc	ra,0xffffd
    800057e8:	2ac080e7          	jalr	684(ra) # 80002a90 <argstr>
    800057ec:	04054a63          	bltz	a0,80005840 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800057f0:	f6c40593          	addi	a1,s0,-148
    800057f4:	4505                	li	a0,1
    800057f6:	ffffd097          	auipc	ra,0xffffd
    800057fa:	256080e7          	jalr	598(ra) # 80002a4c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057fe:	04054163          	bltz	a0,80005840 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005802:	f6840593          	addi	a1,s0,-152
    80005806:	4509                	li	a0,2
    80005808:	ffffd097          	auipc	ra,0xffffd
    8000580c:	244080e7          	jalr	580(ra) # 80002a4c <argint>
     argint(1, &major) < 0 ||
    80005810:	02054863          	bltz	a0,80005840 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005814:	f6841683          	lh	a3,-152(s0)
    80005818:	f6c41603          	lh	a2,-148(s0)
    8000581c:	458d                	li	a1,3
    8000581e:	f7040513          	addi	a0,s0,-144
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	774080e7          	jalr	1908(ra) # 80004f96 <create>
     argint(2, &minor) < 0 ||
    8000582a:	c919                	beqz	a0,80005840 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	082080e7          	jalr	130(ra) # 800038ae <iunlockput>
  end_op();
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	872080e7          	jalr	-1934(ra) # 800040a6 <end_op>
  return 0;
    8000583c:	4501                	li	a0,0
    8000583e:	a031                	j	8000584a <sys_mknod+0x80>
    end_op();
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	866080e7          	jalr	-1946(ra) # 800040a6 <end_op>
    return -1;
    80005848:	557d                	li	a0,-1
}
    8000584a:	60ea                	ld	ra,152(sp)
    8000584c:	644a                	ld	s0,144(sp)
    8000584e:	610d                	addi	sp,sp,160
    80005850:	8082                	ret

0000000080005852 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005852:	7135                	addi	sp,sp,-160
    80005854:	ed06                	sd	ra,152(sp)
    80005856:	e922                	sd	s0,144(sp)
    80005858:	e526                	sd	s1,136(sp)
    8000585a:	e14a                	sd	s2,128(sp)
    8000585c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000585e:	ffffc097          	auipc	ra,0xffffc
    80005862:	138080e7          	jalr	312(ra) # 80001996 <myproc>
    80005866:	892a                	mv	s2,a0
  
  begin_op();
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	7c0080e7          	jalr	1984(ra) # 80004028 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005870:	08000613          	li	a2,128
    80005874:	f6040593          	addi	a1,s0,-160
    80005878:	4501                	li	a0,0
    8000587a:	ffffd097          	auipc	ra,0xffffd
    8000587e:	216080e7          	jalr	534(ra) # 80002a90 <argstr>
    80005882:	04054b63          	bltz	a0,800058d8 <sys_chdir+0x86>
    80005886:	f6040513          	addi	a0,s0,-160
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	57e080e7          	jalr	1406(ra) # 80003e08 <namei>
    80005892:	84aa                	mv	s1,a0
    80005894:	c131                	beqz	a0,800058d8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	db6080e7          	jalr	-586(ra) # 8000364c <ilock>
  if(ip->type != T_DIR){
    8000589e:	04449703          	lh	a4,68(s1)
    800058a2:	4785                	li	a5,1
    800058a4:	04f71063          	bne	a4,a5,800058e4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800058a8:	8526                	mv	a0,s1
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	e64080e7          	jalr	-412(ra) # 8000370e <iunlock>
  iput(p->cwd);
    800058b2:	15093503          	ld	a0,336(s2)
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	f50080e7          	jalr	-176(ra) # 80003806 <iput>
  end_op();
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	7e8080e7          	jalr	2024(ra) # 800040a6 <end_op>
  p->cwd = ip;
    800058c6:	14993823          	sd	s1,336(s2)
  return 0;
    800058ca:	4501                	li	a0,0
}
    800058cc:	60ea                	ld	ra,152(sp)
    800058ce:	644a                	ld	s0,144(sp)
    800058d0:	64aa                	ld	s1,136(sp)
    800058d2:	690a                	ld	s2,128(sp)
    800058d4:	610d                	addi	sp,sp,160
    800058d6:	8082                	ret
    end_op();
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	7ce080e7          	jalr	1998(ra) # 800040a6 <end_op>
    return -1;
    800058e0:	557d                	li	a0,-1
    800058e2:	b7ed                	j	800058cc <sys_chdir+0x7a>
    iunlockput(ip);
    800058e4:	8526                	mv	a0,s1
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	fc8080e7          	jalr	-56(ra) # 800038ae <iunlockput>
    end_op();
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	7b8080e7          	jalr	1976(ra) # 800040a6 <end_op>
    return -1;
    800058f6:	557d                	li	a0,-1
    800058f8:	bfd1                	j	800058cc <sys_chdir+0x7a>

00000000800058fa <sys_exec>:

uint64
sys_exec(void)
{
    800058fa:	7145                	addi	sp,sp,-464
    800058fc:	e786                	sd	ra,456(sp)
    800058fe:	e3a2                	sd	s0,448(sp)
    80005900:	ff26                	sd	s1,440(sp)
    80005902:	fb4a                	sd	s2,432(sp)
    80005904:	f74e                	sd	s3,424(sp)
    80005906:	f352                	sd	s4,416(sp)
    80005908:	ef56                	sd	s5,408(sp)
    8000590a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000590c:	08000613          	li	a2,128
    80005910:	f4040593          	addi	a1,s0,-192
    80005914:	4501                	li	a0,0
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	17a080e7          	jalr	378(ra) # 80002a90 <argstr>
    return -1;
    8000591e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005920:	0c054b63          	bltz	a0,800059f6 <sys_exec+0xfc>
    80005924:	e3840593          	addi	a1,s0,-456
    80005928:	4505                	li	a0,1
    8000592a:	ffffd097          	auipc	ra,0xffffd
    8000592e:	144080e7          	jalr	324(ra) # 80002a6e <argaddr>
    80005932:	0c054263          	bltz	a0,800059f6 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005936:	10000613          	li	a2,256
    8000593a:	4581                	li	a1,0
    8000593c:	e4040513          	addi	a0,s0,-448
    80005940:	ffffb097          	auipc	ra,0xffffb
    80005944:	38c080e7          	jalr	908(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005948:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000594c:	89a6                	mv	s3,s1
    8000594e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005950:	02000a13          	li	s4,32
    80005954:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005958:	00391513          	slli	a0,s2,0x3
    8000595c:	e3040593          	addi	a1,s0,-464
    80005960:	e3843783          	ld	a5,-456(s0)
    80005964:	953e                	add	a0,a0,a5
    80005966:	ffffd097          	auipc	ra,0xffffd
    8000596a:	04c080e7          	jalr	76(ra) # 800029b2 <fetchaddr>
    8000596e:	02054a63          	bltz	a0,800059a2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005972:	e3043783          	ld	a5,-464(s0)
    80005976:	c3b9                	beqz	a5,800059bc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005978:	ffffb097          	auipc	ra,0xffffb
    8000597c:	168080e7          	jalr	360(ra) # 80000ae0 <kalloc>
    80005980:	85aa                	mv	a1,a0
    80005982:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005986:	cd11                	beqz	a0,800059a2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005988:	6605                	lui	a2,0x1
    8000598a:	e3043503          	ld	a0,-464(s0)
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	076080e7          	jalr	118(ra) # 80002a04 <fetchstr>
    80005996:	00054663          	bltz	a0,800059a2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000599a:	0905                	addi	s2,s2,1
    8000599c:	09a1                	addi	s3,s3,8
    8000599e:	fb491be3          	bne	s2,s4,80005954 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059a2:	f4040913          	addi	s2,s0,-192
    800059a6:	6088                	ld	a0,0(s1)
    800059a8:	c531                	beqz	a0,800059f4 <sys_exec+0xfa>
    kfree(argv[i]);
    800059aa:	ffffb097          	auipc	ra,0xffffb
    800059ae:	038080e7          	jalr	56(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059b2:	04a1                	addi	s1,s1,8
    800059b4:	ff2499e3          	bne	s1,s2,800059a6 <sys_exec+0xac>
  return -1;
    800059b8:	597d                	li	s2,-1
    800059ba:	a835                	j	800059f6 <sys_exec+0xfc>
      argv[i] = 0;
    800059bc:	0a8e                	slli	s5,s5,0x3
    800059be:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    800059c2:	00878ab3          	add	s5,a5,s0
    800059c6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800059ca:	e4040593          	addi	a1,s0,-448
    800059ce:	f4040513          	addi	a0,s0,-192
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	172080e7          	jalr	370(ra) # 80004b44 <exec>
    800059da:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059dc:	f4040993          	addi	s3,s0,-192
    800059e0:	6088                	ld	a0,0(s1)
    800059e2:	c911                	beqz	a0,800059f6 <sys_exec+0xfc>
    kfree(argv[i]);
    800059e4:	ffffb097          	auipc	ra,0xffffb
    800059e8:	ffe080e7          	jalr	-2(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059ec:	04a1                	addi	s1,s1,8
    800059ee:	ff3499e3          	bne	s1,s3,800059e0 <sys_exec+0xe6>
    800059f2:	a011                	j	800059f6 <sys_exec+0xfc>
  return -1;
    800059f4:	597d                	li	s2,-1
}
    800059f6:	854a                	mv	a0,s2
    800059f8:	60be                	ld	ra,456(sp)
    800059fa:	641e                	ld	s0,448(sp)
    800059fc:	74fa                	ld	s1,440(sp)
    800059fe:	795a                	ld	s2,432(sp)
    80005a00:	79ba                	ld	s3,424(sp)
    80005a02:	7a1a                	ld	s4,416(sp)
    80005a04:	6afa                	ld	s5,408(sp)
    80005a06:	6179                	addi	sp,sp,464
    80005a08:	8082                	ret

0000000080005a0a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a0a:	7139                	addi	sp,sp,-64
    80005a0c:	fc06                	sd	ra,56(sp)
    80005a0e:	f822                	sd	s0,48(sp)
    80005a10:	f426                	sd	s1,40(sp)
    80005a12:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a14:	ffffc097          	auipc	ra,0xffffc
    80005a18:	f82080e7          	jalr	-126(ra) # 80001996 <myproc>
    80005a1c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a1e:	fd840593          	addi	a1,s0,-40
    80005a22:	4501                	li	a0,0
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	04a080e7          	jalr	74(ra) # 80002a6e <argaddr>
    return -1;
    80005a2c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a2e:	0e054063          	bltz	a0,80005b0e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a32:	fc840593          	addi	a1,s0,-56
    80005a36:	fd040513          	addi	a0,s0,-48
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	de6080e7          	jalr	-538(ra) # 80004820 <pipealloc>
    return -1;
    80005a42:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a44:	0c054563          	bltz	a0,80005b0e <sys_pipe+0x104>
  fd0 = -1;
    80005a48:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a4c:	fd043503          	ld	a0,-48(s0)
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	504080e7          	jalr	1284(ra) # 80004f54 <fdalloc>
    80005a58:	fca42223          	sw	a0,-60(s0)
    80005a5c:	08054c63          	bltz	a0,80005af4 <sys_pipe+0xea>
    80005a60:	fc843503          	ld	a0,-56(s0)
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	4f0080e7          	jalr	1264(ra) # 80004f54 <fdalloc>
    80005a6c:	fca42023          	sw	a0,-64(s0)
    80005a70:	06054963          	bltz	a0,80005ae2 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a74:	4691                	li	a3,4
    80005a76:	fc440613          	addi	a2,s0,-60
    80005a7a:	fd843583          	ld	a1,-40(s0)
    80005a7e:	68a8                	ld	a0,80(s1)
    80005a80:	ffffc097          	auipc	ra,0xffffc
    80005a84:	bda080e7          	jalr	-1062(ra) # 8000165a <copyout>
    80005a88:	02054063          	bltz	a0,80005aa8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a8c:	4691                	li	a3,4
    80005a8e:	fc040613          	addi	a2,s0,-64
    80005a92:	fd843583          	ld	a1,-40(s0)
    80005a96:	0591                	addi	a1,a1,4
    80005a98:	68a8                	ld	a0,80(s1)
    80005a9a:	ffffc097          	auipc	ra,0xffffc
    80005a9e:	bc0080e7          	jalr	-1088(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005aa2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005aa4:	06055563          	bgez	a0,80005b0e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005aa8:	fc442783          	lw	a5,-60(s0)
    80005aac:	07e9                	addi	a5,a5,26
    80005aae:	078e                	slli	a5,a5,0x3
    80005ab0:	97a6                	add	a5,a5,s1
    80005ab2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ab6:	fc042783          	lw	a5,-64(s0)
    80005aba:	07e9                	addi	a5,a5,26
    80005abc:	078e                	slli	a5,a5,0x3
    80005abe:	00f48533          	add	a0,s1,a5
    80005ac2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ac6:	fd043503          	ld	a0,-48(s0)
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	a26080e7          	jalr	-1498(ra) # 800044f0 <fileclose>
    fileclose(wf);
    80005ad2:	fc843503          	ld	a0,-56(s0)
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	a1a080e7          	jalr	-1510(ra) # 800044f0 <fileclose>
    return -1;
    80005ade:	57fd                	li	a5,-1
    80005ae0:	a03d                	j	80005b0e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ae2:	fc442783          	lw	a5,-60(s0)
    80005ae6:	0007c763          	bltz	a5,80005af4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005aea:	07e9                	addi	a5,a5,26
    80005aec:	078e                	slli	a5,a5,0x3
    80005aee:	97a6                	add	a5,a5,s1
    80005af0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005af4:	fd043503          	ld	a0,-48(s0)
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	9f8080e7          	jalr	-1544(ra) # 800044f0 <fileclose>
    fileclose(wf);
    80005b00:	fc843503          	ld	a0,-56(s0)
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	9ec080e7          	jalr	-1556(ra) # 800044f0 <fileclose>
    return -1;
    80005b0c:	57fd                	li	a5,-1
}
    80005b0e:	853e                	mv	a0,a5
    80005b10:	70e2                	ld	ra,56(sp)
    80005b12:	7442                	ld	s0,48(sp)
    80005b14:	74a2                	ld	s1,40(sp)
    80005b16:	6121                	addi	sp,sp,64
    80005b18:	8082                	ret
    80005b1a:	0000                	unimp
    80005b1c:	0000                	unimp
	...

0000000080005b20 <kernelvec>:
    80005b20:	7111                	addi	sp,sp,-256
    80005b22:	e006                	sd	ra,0(sp)
    80005b24:	e40a                	sd	sp,8(sp)
    80005b26:	e80e                	sd	gp,16(sp)
    80005b28:	ec12                	sd	tp,24(sp)
    80005b2a:	f016                	sd	t0,32(sp)
    80005b2c:	f41a                	sd	t1,40(sp)
    80005b2e:	f81e                	sd	t2,48(sp)
    80005b30:	fc22                	sd	s0,56(sp)
    80005b32:	e0a6                	sd	s1,64(sp)
    80005b34:	e4aa                	sd	a0,72(sp)
    80005b36:	e8ae                	sd	a1,80(sp)
    80005b38:	ecb2                	sd	a2,88(sp)
    80005b3a:	f0b6                	sd	a3,96(sp)
    80005b3c:	f4ba                	sd	a4,104(sp)
    80005b3e:	f8be                	sd	a5,112(sp)
    80005b40:	fcc2                	sd	a6,120(sp)
    80005b42:	e146                	sd	a7,128(sp)
    80005b44:	e54a                	sd	s2,136(sp)
    80005b46:	e94e                	sd	s3,144(sp)
    80005b48:	ed52                	sd	s4,152(sp)
    80005b4a:	f156                	sd	s5,160(sp)
    80005b4c:	f55a                	sd	s6,168(sp)
    80005b4e:	f95e                	sd	s7,176(sp)
    80005b50:	fd62                	sd	s8,184(sp)
    80005b52:	e1e6                	sd	s9,192(sp)
    80005b54:	e5ea                	sd	s10,200(sp)
    80005b56:	e9ee                	sd	s11,208(sp)
    80005b58:	edf2                	sd	t3,216(sp)
    80005b5a:	f1f6                	sd	t4,224(sp)
    80005b5c:	f5fa                	sd	t5,232(sp)
    80005b5e:	f9fe                	sd	t6,240(sp)
    80005b60:	d1ffc0ef          	jal	ra,8000287e <kerneltrap>
    80005b64:	6082                	ld	ra,0(sp)
    80005b66:	6122                	ld	sp,8(sp)
    80005b68:	61c2                	ld	gp,16(sp)
    80005b6a:	7282                	ld	t0,32(sp)
    80005b6c:	7322                	ld	t1,40(sp)
    80005b6e:	73c2                	ld	t2,48(sp)
    80005b70:	7462                	ld	s0,56(sp)
    80005b72:	6486                	ld	s1,64(sp)
    80005b74:	6526                	ld	a0,72(sp)
    80005b76:	65c6                	ld	a1,80(sp)
    80005b78:	6666                	ld	a2,88(sp)
    80005b7a:	7686                	ld	a3,96(sp)
    80005b7c:	7726                	ld	a4,104(sp)
    80005b7e:	77c6                	ld	a5,112(sp)
    80005b80:	7866                	ld	a6,120(sp)
    80005b82:	688a                	ld	a7,128(sp)
    80005b84:	692a                	ld	s2,136(sp)
    80005b86:	69ca                	ld	s3,144(sp)
    80005b88:	6a6a                	ld	s4,152(sp)
    80005b8a:	7a8a                	ld	s5,160(sp)
    80005b8c:	7b2a                	ld	s6,168(sp)
    80005b8e:	7bca                	ld	s7,176(sp)
    80005b90:	7c6a                	ld	s8,184(sp)
    80005b92:	6c8e                	ld	s9,192(sp)
    80005b94:	6d2e                	ld	s10,200(sp)
    80005b96:	6dce                	ld	s11,208(sp)
    80005b98:	6e6e                	ld	t3,216(sp)
    80005b9a:	7e8e                	ld	t4,224(sp)
    80005b9c:	7f2e                	ld	t5,232(sp)
    80005b9e:	7fce                	ld	t6,240(sp)
    80005ba0:	6111                	addi	sp,sp,256
    80005ba2:	10200073          	sret
    80005ba6:	00000013          	nop
    80005baa:	00000013          	nop
    80005bae:	0001                	nop

0000000080005bb0 <timervec>:
    80005bb0:	34051573          	csrrw	a0,mscratch,a0
    80005bb4:	e10c                	sd	a1,0(a0)
    80005bb6:	e510                	sd	a2,8(a0)
    80005bb8:	e914                	sd	a3,16(a0)
    80005bba:	6d0c                	ld	a1,24(a0)
    80005bbc:	7110                	ld	a2,32(a0)
    80005bbe:	6194                	ld	a3,0(a1)
    80005bc0:	96b2                	add	a3,a3,a2
    80005bc2:	e194                	sd	a3,0(a1)
    80005bc4:	4589                	li	a1,2
    80005bc6:	14459073          	csrw	sip,a1
    80005bca:	6914                	ld	a3,16(a0)
    80005bcc:	6510                	ld	a2,8(a0)
    80005bce:	610c                	ld	a1,0(a0)
    80005bd0:	34051573          	csrrw	a0,mscratch,a0
    80005bd4:	30200073          	mret
	...

0000000080005bda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005bda:	1141                	addi	sp,sp,-16
    80005bdc:	e422                	sd	s0,8(sp)
    80005bde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005be0:	0c0007b7          	lui	a5,0xc000
    80005be4:	4705                	li	a4,1
    80005be6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005be8:	c3d8                	sw	a4,4(a5)
}
    80005bea:	6422                	ld	s0,8(sp)
    80005bec:	0141                	addi	sp,sp,16
    80005bee:	8082                	ret

0000000080005bf0 <plicinithart>:

void
plicinithart(void)
{
    80005bf0:	1141                	addi	sp,sp,-16
    80005bf2:	e406                	sd	ra,8(sp)
    80005bf4:	e022                	sd	s0,0(sp)
    80005bf6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bf8:	ffffc097          	auipc	ra,0xffffc
    80005bfc:	d72080e7          	jalr	-654(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c00:	0085171b          	slliw	a4,a0,0x8
    80005c04:	0c0027b7          	lui	a5,0xc002
    80005c08:	97ba                	add	a5,a5,a4
    80005c0a:	40200713          	li	a4,1026
    80005c0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c12:	00d5151b          	slliw	a0,a0,0xd
    80005c16:	0c2017b7          	lui	a5,0xc201
    80005c1a:	97aa                	add	a5,a5,a0
    80005c1c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005c20:	60a2                	ld	ra,8(sp)
    80005c22:	6402                	ld	s0,0(sp)
    80005c24:	0141                	addi	sp,sp,16
    80005c26:	8082                	ret

0000000080005c28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c28:	1141                	addi	sp,sp,-16
    80005c2a:	e406                	sd	ra,8(sp)
    80005c2c:	e022                	sd	s0,0(sp)
    80005c2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c30:	ffffc097          	auipc	ra,0xffffc
    80005c34:	d3a080e7          	jalr	-710(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c38:	00d5151b          	slliw	a0,a0,0xd
    80005c3c:	0c2017b7          	lui	a5,0xc201
    80005c40:	97aa                	add	a5,a5,a0
  return irq;
}
    80005c42:	43c8                	lw	a0,4(a5)
    80005c44:	60a2                	ld	ra,8(sp)
    80005c46:	6402                	ld	s0,0(sp)
    80005c48:	0141                	addi	sp,sp,16
    80005c4a:	8082                	ret

0000000080005c4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c4c:	1101                	addi	sp,sp,-32
    80005c4e:	ec06                	sd	ra,24(sp)
    80005c50:	e822                	sd	s0,16(sp)
    80005c52:	e426                	sd	s1,8(sp)
    80005c54:	1000                	addi	s0,sp,32
    80005c56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	d12080e7          	jalr	-750(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c60:	00d5151b          	slliw	a0,a0,0xd
    80005c64:	0c2017b7          	lui	a5,0xc201
    80005c68:	97aa                	add	a5,a5,a0
    80005c6a:	c3c4                	sw	s1,4(a5)
}
    80005c6c:	60e2                	ld	ra,24(sp)
    80005c6e:	6442                	ld	s0,16(sp)
    80005c70:	64a2                	ld	s1,8(sp)
    80005c72:	6105                	addi	sp,sp,32
    80005c74:	8082                	ret

0000000080005c76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c76:	1141                	addi	sp,sp,-16
    80005c78:	e406                	sd	ra,8(sp)
    80005c7a:	e022                	sd	s0,0(sp)
    80005c7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c7e:	479d                	li	a5,7
    80005c80:	06a7c863          	blt	a5,a0,80005cf0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005c84:	0001d717          	auipc	a4,0x1d
    80005c88:	37c70713          	addi	a4,a4,892 # 80023000 <disk>
    80005c8c:	972a                	add	a4,a4,a0
    80005c8e:	6789                	lui	a5,0x2
    80005c90:	97ba                	add	a5,a5,a4
    80005c92:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c96:	e7ad                	bnez	a5,80005d00 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c98:	00451793          	slli	a5,a0,0x4
    80005c9c:	0001f717          	auipc	a4,0x1f
    80005ca0:	36470713          	addi	a4,a4,868 # 80025000 <disk+0x2000>
    80005ca4:	6314                	ld	a3,0(a4)
    80005ca6:	96be                	add	a3,a3,a5
    80005ca8:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005cac:	6314                	ld	a3,0(a4)
    80005cae:	96be                	add	a3,a3,a5
    80005cb0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005cb4:	6314                	ld	a3,0(a4)
    80005cb6:	96be                	add	a3,a3,a5
    80005cb8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005cbc:	6318                	ld	a4,0(a4)
    80005cbe:	97ba                	add	a5,a5,a4
    80005cc0:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005cc4:	0001d717          	auipc	a4,0x1d
    80005cc8:	33c70713          	addi	a4,a4,828 # 80023000 <disk>
    80005ccc:	972a                	add	a4,a4,a0
    80005cce:	6789                	lui	a5,0x2
    80005cd0:	97ba                	add	a5,a5,a4
    80005cd2:	4705                	li	a4,1
    80005cd4:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005cd8:	0001f517          	auipc	a0,0x1f
    80005cdc:	34050513          	addi	a0,a0,832 # 80025018 <disk+0x2018>
    80005ce0:	ffffc097          	auipc	ra,0xffffc
    80005ce4:	506080e7          	jalr	1286(ra) # 800021e6 <wakeup>
}
    80005ce8:	60a2                	ld	ra,8(sp)
    80005cea:	6402                	ld	s0,0(sp)
    80005cec:	0141                	addi	sp,sp,16
    80005cee:	8082                	ret
    panic("free_desc 1");
    80005cf0:	00003517          	auipc	a0,0x3
    80005cf4:	a9050513          	addi	a0,a0,-1392 # 80008780 <syscalls+0x338>
    80005cf8:	ffffb097          	auipc	ra,0xffffb
    80005cfc:	842080e7          	jalr	-1982(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005d00:	00003517          	auipc	a0,0x3
    80005d04:	a9050513          	addi	a0,a0,-1392 # 80008790 <syscalls+0x348>
    80005d08:	ffffb097          	auipc	ra,0xffffb
    80005d0c:	832080e7          	jalr	-1998(ra) # 8000053a <panic>

0000000080005d10 <virtio_disk_init>:
{
    80005d10:	1101                	addi	sp,sp,-32
    80005d12:	ec06                	sd	ra,24(sp)
    80005d14:	e822                	sd	s0,16(sp)
    80005d16:	e426                	sd	s1,8(sp)
    80005d18:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d1a:	00003597          	auipc	a1,0x3
    80005d1e:	a8658593          	addi	a1,a1,-1402 # 800087a0 <syscalls+0x358>
    80005d22:	0001f517          	auipc	a0,0x1f
    80005d26:	40650513          	addi	a0,a0,1030 # 80025128 <disk+0x2128>
    80005d2a:	ffffb097          	auipc	ra,0xffffb
    80005d2e:	e16080e7          	jalr	-490(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d32:	100017b7          	lui	a5,0x10001
    80005d36:	4398                	lw	a4,0(a5)
    80005d38:	2701                	sext.w	a4,a4
    80005d3a:	747277b7          	lui	a5,0x74727
    80005d3e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d42:	0ef71063          	bne	a4,a5,80005e22 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d46:	100017b7          	lui	a5,0x10001
    80005d4a:	43dc                	lw	a5,4(a5)
    80005d4c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d4e:	4705                	li	a4,1
    80005d50:	0ce79963          	bne	a5,a4,80005e22 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d54:	100017b7          	lui	a5,0x10001
    80005d58:	479c                	lw	a5,8(a5)
    80005d5a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d5c:	4709                	li	a4,2
    80005d5e:	0ce79263          	bne	a5,a4,80005e22 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d62:	100017b7          	lui	a5,0x10001
    80005d66:	47d8                	lw	a4,12(a5)
    80005d68:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d6a:	554d47b7          	lui	a5,0x554d4
    80005d6e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d72:	0af71863          	bne	a4,a5,80005e22 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d76:	100017b7          	lui	a5,0x10001
    80005d7a:	4705                	li	a4,1
    80005d7c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d7e:	470d                	li	a4,3
    80005d80:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d82:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d84:	c7ffe6b7          	lui	a3,0xc7ffe
    80005d88:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d8c:	8f75                	and	a4,a4,a3
    80005d8e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d90:	472d                	li	a4,11
    80005d92:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d94:	473d                	li	a4,15
    80005d96:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d98:	6705                	lui	a4,0x1
    80005d9a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d9c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005da0:	5bdc                	lw	a5,52(a5)
    80005da2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005da4:	c7d9                	beqz	a5,80005e32 <virtio_disk_init+0x122>
  if(max < NUM)
    80005da6:	471d                	li	a4,7
    80005da8:	08f77d63          	bgeu	a4,a5,80005e42 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005dac:	100014b7          	lui	s1,0x10001
    80005db0:	47a1                	li	a5,8
    80005db2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005db4:	6609                	lui	a2,0x2
    80005db6:	4581                	li	a1,0
    80005db8:	0001d517          	auipc	a0,0x1d
    80005dbc:	24850513          	addi	a0,a0,584 # 80023000 <disk>
    80005dc0:	ffffb097          	auipc	ra,0xffffb
    80005dc4:	f0c080e7          	jalr	-244(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005dc8:	0001d717          	auipc	a4,0x1d
    80005dcc:	23870713          	addi	a4,a4,568 # 80023000 <disk>
    80005dd0:	00c75793          	srli	a5,a4,0xc
    80005dd4:	2781                	sext.w	a5,a5
    80005dd6:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005dd8:	0001f797          	auipc	a5,0x1f
    80005ddc:	22878793          	addi	a5,a5,552 # 80025000 <disk+0x2000>
    80005de0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005de2:	0001d717          	auipc	a4,0x1d
    80005de6:	29e70713          	addi	a4,a4,670 # 80023080 <disk+0x80>
    80005dea:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005dec:	0001e717          	auipc	a4,0x1e
    80005df0:	21470713          	addi	a4,a4,532 # 80024000 <disk+0x1000>
    80005df4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005df6:	4705                	li	a4,1
    80005df8:	00e78c23          	sb	a4,24(a5)
    80005dfc:	00e78ca3          	sb	a4,25(a5)
    80005e00:	00e78d23          	sb	a4,26(a5)
    80005e04:	00e78da3          	sb	a4,27(a5)
    80005e08:	00e78e23          	sb	a4,28(a5)
    80005e0c:	00e78ea3          	sb	a4,29(a5)
    80005e10:	00e78f23          	sb	a4,30(a5)
    80005e14:	00e78fa3          	sb	a4,31(a5)
}
    80005e18:	60e2                	ld	ra,24(sp)
    80005e1a:	6442                	ld	s0,16(sp)
    80005e1c:	64a2                	ld	s1,8(sp)
    80005e1e:	6105                	addi	sp,sp,32
    80005e20:	8082                	ret
    panic("could not find virtio disk");
    80005e22:	00003517          	auipc	a0,0x3
    80005e26:	98e50513          	addi	a0,a0,-1650 # 800087b0 <syscalls+0x368>
    80005e2a:	ffffa097          	auipc	ra,0xffffa
    80005e2e:	710080e7          	jalr	1808(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005e32:	00003517          	auipc	a0,0x3
    80005e36:	99e50513          	addi	a0,a0,-1634 # 800087d0 <syscalls+0x388>
    80005e3a:	ffffa097          	auipc	ra,0xffffa
    80005e3e:	700080e7          	jalr	1792(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005e42:	00003517          	auipc	a0,0x3
    80005e46:	9ae50513          	addi	a0,a0,-1618 # 800087f0 <syscalls+0x3a8>
    80005e4a:	ffffa097          	auipc	ra,0xffffa
    80005e4e:	6f0080e7          	jalr	1776(ra) # 8000053a <panic>

0000000080005e52 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e52:	7119                	addi	sp,sp,-128
    80005e54:	fc86                	sd	ra,120(sp)
    80005e56:	f8a2                	sd	s0,112(sp)
    80005e58:	f4a6                	sd	s1,104(sp)
    80005e5a:	f0ca                	sd	s2,96(sp)
    80005e5c:	ecce                	sd	s3,88(sp)
    80005e5e:	e8d2                	sd	s4,80(sp)
    80005e60:	e4d6                	sd	s5,72(sp)
    80005e62:	e0da                	sd	s6,64(sp)
    80005e64:	fc5e                	sd	s7,56(sp)
    80005e66:	f862                	sd	s8,48(sp)
    80005e68:	f466                	sd	s9,40(sp)
    80005e6a:	f06a                	sd	s10,32(sp)
    80005e6c:	ec6e                	sd	s11,24(sp)
    80005e6e:	0100                	addi	s0,sp,128
    80005e70:	8aaa                	mv	s5,a0
    80005e72:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e74:	00c52c83          	lw	s9,12(a0)
    80005e78:	001c9c9b          	slliw	s9,s9,0x1
    80005e7c:	1c82                	slli	s9,s9,0x20
    80005e7e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e82:	0001f517          	auipc	a0,0x1f
    80005e86:	2a650513          	addi	a0,a0,678 # 80025128 <disk+0x2128>
    80005e8a:	ffffb097          	auipc	ra,0xffffb
    80005e8e:	d46080e7          	jalr	-698(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80005e92:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e94:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005e96:	0001dc17          	auipc	s8,0x1d
    80005e9a:	16ac0c13          	addi	s8,s8,362 # 80023000 <disk>
    80005e9e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005ea0:	4b0d                	li	s6,3
    80005ea2:	a0ad                	j	80005f0c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005ea4:	00fc0733          	add	a4,s8,a5
    80005ea8:	975e                	add	a4,a4,s7
    80005eaa:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005eae:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005eb0:	0207c563          	bltz	a5,80005eda <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005eb4:	2905                	addiw	s2,s2,1
    80005eb6:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005eb8:	19690c63          	beq	s2,s6,80006050 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005ebc:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005ebe:	0001f717          	auipc	a4,0x1f
    80005ec2:	15a70713          	addi	a4,a4,346 # 80025018 <disk+0x2018>
    80005ec6:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005ec8:	00074683          	lbu	a3,0(a4)
    80005ecc:	fee1                	bnez	a3,80005ea4 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005ece:	2785                	addiw	a5,a5,1
    80005ed0:	0705                	addi	a4,a4,1
    80005ed2:	fe979be3          	bne	a5,s1,80005ec8 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005ed6:	57fd                	li	a5,-1
    80005ed8:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005eda:	01205d63          	blez	s2,80005ef4 <virtio_disk_rw+0xa2>
    80005ede:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005ee0:	000a2503          	lw	a0,0(s4)
    80005ee4:	00000097          	auipc	ra,0x0
    80005ee8:	d92080e7          	jalr	-622(ra) # 80005c76 <free_desc>
      for(int j = 0; j < i; j++)
    80005eec:	2d85                	addiw	s11,s11,1
    80005eee:	0a11                	addi	s4,s4,4
    80005ef0:	ff2d98e3          	bne	s11,s2,80005ee0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ef4:	0001f597          	auipc	a1,0x1f
    80005ef8:	23458593          	addi	a1,a1,564 # 80025128 <disk+0x2128>
    80005efc:	0001f517          	auipc	a0,0x1f
    80005f00:	11c50513          	addi	a0,a0,284 # 80025018 <disk+0x2018>
    80005f04:	ffffc097          	auipc	ra,0xffffc
    80005f08:	156080e7          	jalr	342(ra) # 8000205a <sleep>
  for(int i = 0; i < 3; i++){
    80005f0c:	f8040a13          	addi	s4,s0,-128
{
    80005f10:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005f12:	894e                	mv	s2,s3
    80005f14:	b765                	j	80005ebc <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f16:	0001f697          	auipc	a3,0x1f
    80005f1a:	0ea6b683          	ld	a3,234(a3) # 80025000 <disk+0x2000>
    80005f1e:	96ba                	add	a3,a3,a4
    80005f20:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f24:	0001d817          	auipc	a6,0x1d
    80005f28:	0dc80813          	addi	a6,a6,220 # 80023000 <disk>
    80005f2c:	0001f697          	auipc	a3,0x1f
    80005f30:	0d468693          	addi	a3,a3,212 # 80025000 <disk+0x2000>
    80005f34:	6290                	ld	a2,0(a3)
    80005f36:	963a                	add	a2,a2,a4
    80005f38:	00c65583          	lhu	a1,12(a2)
    80005f3c:	0015e593          	ori	a1,a1,1
    80005f40:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005f44:	f8842603          	lw	a2,-120(s0)
    80005f48:	628c                	ld	a1,0(a3)
    80005f4a:	972e                	add	a4,a4,a1
    80005f4c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005f50:	20050593          	addi	a1,a0,512
    80005f54:	0592                	slli	a1,a1,0x4
    80005f56:	95c2                	add	a1,a1,a6
    80005f58:	577d                	li	a4,-1
    80005f5a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005f5e:	00461713          	slli	a4,a2,0x4
    80005f62:	6290                	ld	a2,0(a3)
    80005f64:	963a                	add	a2,a2,a4
    80005f66:	03078793          	addi	a5,a5,48
    80005f6a:	97c2                	add	a5,a5,a6
    80005f6c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80005f6e:	629c                	ld	a5,0(a3)
    80005f70:	97ba                	add	a5,a5,a4
    80005f72:	4605                	li	a2,1
    80005f74:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005f76:	629c                	ld	a5,0(a3)
    80005f78:	97ba                	add	a5,a5,a4
    80005f7a:	4809                	li	a6,2
    80005f7c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005f80:	629c                	ld	a5,0(a3)
    80005f82:	97ba                	add	a5,a5,a4
    80005f84:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005f88:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80005f8c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005f90:	6698                	ld	a4,8(a3)
    80005f92:	00275783          	lhu	a5,2(a4)
    80005f96:	8b9d                	andi	a5,a5,7
    80005f98:	0786                	slli	a5,a5,0x1
    80005f9a:	973e                	add	a4,a4,a5
    80005f9c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80005fa0:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005fa4:	6698                	ld	a4,8(a3)
    80005fa6:	00275783          	lhu	a5,2(a4)
    80005faa:	2785                	addiw	a5,a5,1
    80005fac:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005fb0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005fb4:	100017b7          	lui	a5,0x10001
    80005fb8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005fbc:	004aa783          	lw	a5,4(s5)
    80005fc0:	02c79163          	bne	a5,a2,80005fe2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80005fc4:	0001f917          	auipc	s2,0x1f
    80005fc8:	16490913          	addi	s2,s2,356 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80005fcc:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005fce:	85ca                	mv	a1,s2
    80005fd0:	8556                	mv	a0,s5
    80005fd2:	ffffc097          	auipc	ra,0xffffc
    80005fd6:	088080e7          	jalr	136(ra) # 8000205a <sleep>
  while(b->disk == 1) {
    80005fda:	004aa783          	lw	a5,4(s5)
    80005fde:	fe9788e3          	beq	a5,s1,80005fce <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80005fe2:	f8042903          	lw	s2,-128(s0)
    80005fe6:	20090713          	addi	a4,s2,512
    80005fea:	0712                	slli	a4,a4,0x4
    80005fec:	0001d797          	auipc	a5,0x1d
    80005ff0:	01478793          	addi	a5,a5,20 # 80023000 <disk>
    80005ff4:	97ba                	add	a5,a5,a4
    80005ff6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80005ffa:	0001f997          	auipc	s3,0x1f
    80005ffe:	00698993          	addi	s3,s3,6 # 80025000 <disk+0x2000>
    80006002:	00491713          	slli	a4,s2,0x4
    80006006:	0009b783          	ld	a5,0(s3)
    8000600a:	97ba                	add	a5,a5,a4
    8000600c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006010:	854a                	mv	a0,s2
    80006012:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006016:	00000097          	auipc	ra,0x0
    8000601a:	c60080e7          	jalr	-928(ra) # 80005c76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000601e:	8885                	andi	s1,s1,1
    80006020:	f0ed                	bnez	s1,80006002 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006022:	0001f517          	auipc	a0,0x1f
    80006026:	10650513          	addi	a0,a0,262 # 80025128 <disk+0x2128>
    8000602a:	ffffb097          	auipc	ra,0xffffb
    8000602e:	c5a080e7          	jalr	-934(ra) # 80000c84 <release>
}
    80006032:	70e6                	ld	ra,120(sp)
    80006034:	7446                	ld	s0,112(sp)
    80006036:	74a6                	ld	s1,104(sp)
    80006038:	7906                	ld	s2,96(sp)
    8000603a:	69e6                	ld	s3,88(sp)
    8000603c:	6a46                	ld	s4,80(sp)
    8000603e:	6aa6                	ld	s5,72(sp)
    80006040:	6b06                	ld	s6,64(sp)
    80006042:	7be2                	ld	s7,56(sp)
    80006044:	7c42                	ld	s8,48(sp)
    80006046:	7ca2                	ld	s9,40(sp)
    80006048:	7d02                	ld	s10,32(sp)
    8000604a:	6de2                	ld	s11,24(sp)
    8000604c:	6109                	addi	sp,sp,128
    8000604e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006050:	f8042503          	lw	a0,-128(s0)
    80006054:	20050793          	addi	a5,a0,512
    80006058:	0792                	slli	a5,a5,0x4
  if(write)
    8000605a:	0001d817          	auipc	a6,0x1d
    8000605e:	fa680813          	addi	a6,a6,-90 # 80023000 <disk>
    80006062:	00f80733          	add	a4,a6,a5
    80006066:	01a036b3          	snez	a3,s10
    8000606a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000606e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006072:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006076:	7679                	lui	a2,0xffffe
    80006078:	963e                	add	a2,a2,a5
    8000607a:	0001f697          	auipc	a3,0x1f
    8000607e:	f8668693          	addi	a3,a3,-122 # 80025000 <disk+0x2000>
    80006082:	6298                	ld	a4,0(a3)
    80006084:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006086:	0a878593          	addi	a1,a5,168
    8000608a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000608c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000608e:	6298                	ld	a4,0(a3)
    80006090:	9732                	add	a4,a4,a2
    80006092:	45c1                	li	a1,16
    80006094:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006096:	6298                	ld	a4,0(a3)
    80006098:	9732                	add	a4,a4,a2
    8000609a:	4585                	li	a1,1
    8000609c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800060a0:	f8442703          	lw	a4,-124(s0)
    800060a4:	628c                	ld	a1,0(a3)
    800060a6:	962e                	add	a2,a2,a1
    800060a8:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800060ac:	0712                	slli	a4,a4,0x4
    800060ae:	6290                	ld	a2,0(a3)
    800060b0:	963a                	add	a2,a2,a4
    800060b2:	058a8593          	addi	a1,s5,88
    800060b6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800060b8:	6294                	ld	a3,0(a3)
    800060ba:	96ba                	add	a3,a3,a4
    800060bc:	40000613          	li	a2,1024
    800060c0:	c690                	sw	a2,8(a3)
  if(write)
    800060c2:	e40d1ae3          	bnez	s10,80005f16 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060c6:	0001f697          	auipc	a3,0x1f
    800060ca:	f3a6b683          	ld	a3,-198(a3) # 80025000 <disk+0x2000>
    800060ce:	96ba                	add	a3,a3,a4
    800060d0:	4609                	li	a2,2
    800060d2:	00c69623          	sh	a2,12(a3)
    800060d6:	b5b9                	j	80005f24 <virtio_disk_rw+0xd2>

00000000800060d8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800060d8:	1101                	addi	sp,sp,-32
    800060da:	ec06                	sd	ra,24(sp)
    800060dc:	e822                	sd	s0,16(sp)
    800060de:	e426                	sd	s1,8(sp)
    800060e0:	e04a                	sd	s2,0(sp)
    800060e2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800060e4:	0001f517          	auipc	a0,0x1f
    800060e8:	04450513          	addi	a0,a0,68 # 80025128 <disk+0x2128>
    800060ec:	ffffb097          	auipc	ra,0xffffb
    800060f0:	ae4080e7          	jalr	-1308(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800060f4:	10001737          	lui	a4,0x10001
    800060f8:	533c                	lw	a5,96(a4)
    800060fa:	8b8d                	andi	a5,a5,3
    800060fc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800060fe:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006102:	0001f797          	auipc	a5,0x1f
    80006106:	efe78793          	addi	a5,a5,-258 # 80025000 <disk+0x2000>
    8000610a:	6b94                	ld	a3,16(a5)
    8000610c:	0207d703          	lhu	a4,32(a5)
    80006110:	0026d783          	lhu	a5,2(a3)
    80006114:	06f70163          	beq	a4,a5,80006176 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006118:	0001d917          	auipc	s2,0x1d
    8000611c:	ee890913          	addi	s2,s2,-280 # 80023000 <disk>
    80006120:	0001f497          	auipc	s1,0x1f
    80006124:	ee048493          	addi	s1,s1,-288 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006128:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000612c:	6898                	ld	a4,16(s1)
    8000612e:	0204d783          	lhu	a5,32(s1)
    80006132:	8b9d                	andi	a5,a5,7
    80006134:	078e                	slli	a5,a5,0x3
    80006136:	97ba                	add	a5,a5,a4
    80006138:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000613a:	20078713          	addi	a4,a5,512
    8000613e:	0712                	slli	a4,a4,0x4
    80006140:	974a                	add	a4,a4,s2
    80006142:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006146:	e731                	bnez	a4,80006192 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006148:	20078793          	addi	a5,a5,512
    8000614c:	0792                	slli	a5,a5,0x4
    8000614e:	97ca                	add	a5,a5,s2
    80006150:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006152:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006156:	ffffc097          	auipc	ra,0xffffc
    8000615a:	090080e7          	jalr	144(ra) # 800021e6 <wakeup>

    disk.used_idx += 1;
    8000615e:	0204d783          	lhu	a5,32(s1)
    80006162:	2785                	addiw	a5,a5,1
    80006164:	17c2                	slli	a5,a5,0x30
    80006166:	93c1                	srli	a5,a5,0x30
    80006168:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000616c:	6898                	ld	a4,16(s1)
    8000616e:	00275703          	lhu	a4,2(a4)
    80006172:	faf71be3          	bne	a4,a5,80006128 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006176:	0001f517          	auipc	a0,0x1f
    8000617a:	fb250513          	addi	a0,a0,-78 # 80025128 <disk+0x2128>
    8000617e:	ffffb097          	auipc	ra,0xffffb
    80006182:	b06080e7          	jalr	-1274(ra) # 80000c84 <release>
}
    80006186:	60e2                	ld	ra,24(sp)
    80006188:	6442                	ld	s0,16(sp)
    8000618a:	64a2                	ld	s1,8(sp)
    8000618c:	6902                	ld	s2,0(sp)
    8000618e:	6105                	addi	sp,sp,32
    80006190:	8082                	ret
      panic("virtio_disk_intr status");
    80006192:	00002517          	auipc	a0,0x2
    80006196:	67e50513          	addi	a0,a0,1662 # 80008810 <syscalls+0x3c8>
    8000619a:	ffffa097          	auipc	ra,0xffffa
    8000619e:	3a0080e7          	jalr	928(ra) # 8000053a <panic>
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
