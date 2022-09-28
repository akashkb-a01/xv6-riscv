
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	95013103          	ld	sp,-1712(sp) # 80008950 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000066:	e0e78793          	addi	a5,a5,-498 # 80005e70 <timervec>
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
    80000ebc:	984080e7          	jalr	-1660(ra) # 8000283c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	ff0080e7          	jalr	-16(ra) # 80005eb0 <plicinithart>
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
    80000f34:	8e4080e7          	jalr	-1820(ra) # 80002814 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	904080e7          	jalr	-1788(ra) # 8000283c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	f5a080e7          	jalr	-166(ra) # 80005e9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	f68080e7          	jalr	-152(ra) # 80005eb0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	12a080e7          	jalr	298(ra) # 8000307a <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	7b8080e7          	jalr	1976(ra) # 80003710 <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	76a080e7          	jalr	1898(ra) # 800046ca <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	068080e7          	jalr	104(ra) # 80005fd0 <virtio_disk_init>
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
    800019ec:	f187a783          	lw	a5,-232(a5) # 80008900 <first.1>
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
    80001a0e:	e4a080e7          	jalr	-438(ra) # 80002854 <usertrapret>
}
    80001a12:	60e2                	ld	ra,24(sp)
    80001a14:	6442                	ld	s0,16(sp)
    80001a16:	64a2                	ld	s1,8(sp)
    80001a18:	6105                	addi	sp,sp,32
    80001a1a:	8082                	ret
    first = 0;
    80001a1c:	00007797          	auipc	a5,0x7
    80001a20:	ee07a223          	sw	zero,-284(a5) # 80008900 <first.1>
    fsinit(ROOTDEV);
    80001a24:	4505                	li	a0,1
    80001a26:	00002097          	auipc	ra,0x2
    80001a2a:	c6a080e7          	jalr	-918(ra) # 80003690 <fsinit>
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
    80001a52:	eb678793          	addi	a5,a5,-330 # 80008904 <nextpid>
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
    80001cba:	c5a58593          	addi	a1,a1,-934 # 80008910 <initcode>
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
    80001cf8:	3d2080e7          	jalr	978(ra) # 800040c6 <namei>
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
    80001e44:	91c080e7          	jalr	-1764(ra) # 8000475c <filedup>
    80001e48:	00a93023          	sd	a0,0(s2)
    80001e4c:	b7e5                	j	80001e34 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e4e:	150ab503          	ld	a0,336(s5)
    80001e52:	00002097          	auipc	ra,0x2
    80001e56:	a7a080e7          	jalr	-1414(ra) # 800038cc <idup>
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
    80001f66:	848080e7          	jalr	-1976(ra) # 800027aa <swtch>
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
    80001fe4:	00000097          	auipc	ra,0x0
    80001fe8:	7c6080e7          	jalr	1990(ra) # 800027aa <swtch>
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
    80002322:	490080e7          	jalr	1168(ra) # 800047ae <fileclose>
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
    8000233a:	fb0080e7          	jalr	-80(ra) # 800042e6 <begin_op>
  iput(p->cwd);
    8000233e:	1509b503          	ld	a0,336(s3)
    80002342:	00001097          	auipc	ra,0x1
    80002346:	782080e7          	jalr	1922(ra) # 80003ac4 <iput>
  end_op();
    8000234a:	00002097          	auipc	ra,0x2
    8000234e:	01a080e7          	jalr	26(ra) # 80004364 <end_op>
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

000000008000258e <waitpid>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
waitpid(uint64 _pid, uint64 addr)
{
    8000258e:	711d                	addi	sp,sp,-96
    80002590:	ec86                	sd	ra,88(sp)
    80002592:	e8a2                	sd	s0,80(sp)
    80002594:	e4a6                	sd	s1,72(sp)
    80002596:	e0ca                	sd	s2,64(sp)
    80002598:	fc4e                	sd	s3,56(sp)
    8000259a:	f852                	sd	s4,48(sp)
    8000259c:	f456                	sd	s5,40(sp)
    8000259e:	f05a                	sd	s6,32(sp)
    800025a0:	ec5e                	sd	s7,24(sp)
    800025a2:	e862                	sd	s8,16(sp)
    800025a4:	e466                	sd	s9,8(sp)
    800025a6:	1080                	addi	s0,sp,96
    800025a8:	892a                	mv	s2,a0
    800025aa:	8bae                	mv	s7,a1
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	3ea080e7          	jalr	1002(ra) # 80001996 <myproc>
    800025b4:	8a2a                	mv	s4,a0

  acquire(&wait_lock);
    800025b6:	0000f517          	auipc	a0,0xf
    800025ba:	d0250513          	addi	a0,a0,-766 # 800112b8 <wait_lock>
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	612080e7          	jalr	1554(ra) # 80000bd0 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    800025c6:	4c01                	li	s8,0
      if((np->pid == _pid) && (np->parent == p)){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    800025c8:	4a95                	li	s5,5
        havekids = 1;
    800025ca:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    800025cc:	00015997          	auipc	s3,0x15
    800025d0:	10498993          	addi	s3,s3,260 # 800176d0 <tickslock>
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025d4:	0000fc97          	auipc	s9,0xf
    800025d8:	ce4c8c93          	addi	s9,s9,-796 # 800112b8 <wait_lock>
    havekids = 0;
    800025dc:	8762                	mv	a4,s8
    for(np = proc; np < &proc[NPROC]; np++){
    800025de:	0000f497          	auipc	s1,0xf
    800025e2:	0f248493          	addi	s1,s1,242 # 800116d0 <proc>
    800025e6:	a0bd                	j	80002654 <waitpid+0xc6>
          pid = np->pid;
    800025e8:	0304a903          	lw	s2,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025ec:	000b8e63          	beqz	s7,80002608 <waitpid+0x7a>
    800025f0:	4691                	li	a3,4
    800025f2:	02c48613          	addi	a2,s1,44
    800025f6:	85de                	mv	a1,s7
    800025f8:	050a3503          	ld	a0,80(s4)
    800025fc:	fffff097          	auipc	ra,0xfffff
    80002600:	05e080e7          	jalr	94(ra) # 8000165a <copyout>
    80002604:	02054563          	bltz	a0,8000262e <waitpid+0xa0>
          freeproc(np);
    80002608:	8526                	mv	a0,s1
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	55a080e7          	jalr	1370(ra) # 80001b64 <freeproc>
          release(&np->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	670080e7          	jalr	1648(ra) # 80000c84 <release>
          release(&wait_lock);
    8000261c:	0000f517          	auipc	a0,0xf
    80002620:	c9c50513          	addi	a0,a0,-868 # 800112b8 <wait_lock>
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	660080e7          	jalr	1632(ra) # 80000c84 <release>
          return pid;
    8000262c:	a0b5                	j	80002698 <waitpid+0x10a>
            release(&np->lock);
    8000262e:	8526                	mv	a0,s1
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	654080e7          	jalr	1620(ra) # 80000c84 <release>
            release(&wait_lock);
    80002638:	0000f517          	auipc	a0,0xf
    8000263c:	c8050513          	addi	a0,a0,-896 # 800112b8 <wait_lock>
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	644080e7          	jalr	1604(ra) # 80000c84 <release>
            return -1;
    80002648:	597d                	li	s2,-1
    8000264a:	a0b9                	j	80002698 <waitpid+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    8000264c:	18048493          	addi	s1,s1,384
    80002650:	03348763          	beq	s1,s3,8000267e <waitpid+0xf0>
      if((np->pid == _pid) && (np->parent == p)){
    80002654:	589c                	lw	a5,48(s1)
    80002656:	ff279be3          	bne	a5,s2,8000264c <waitpid+0xbe>
    8000265a:	7c9c                	ld	a5,56(s1)
    8000265c:	ff4798e3          	bne	a5,s4,8000264c <waitpid+0xbe>
        acquire(&np->lock);
    80002660:	8526                	mv	a0,s1
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	56e080e7          	jalr	1390(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    8000266a:	4c9c                	lw	a5,24(s1)
    8000266c:	f7578ee3          	beq	a5,s5,800025e8 <waitpid+0x5a>
        release(&np->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	612080e7          	jalr	1554(ra) # 80000c84 <release>
        havekids = 1;
    8000267a:	875a                	mv	a4,s6
    8000267c:	bfc1                	j	8000264c <waitpid+0xbe>
    if(!havekids || p->killed){
    8000267e:	c701                	beqz	a4,80002686 <waitpid+0xf8>
    80002680:	028a2783          	lw	a5,40(s4)
    80002684:	cb85                	beqz	a5,800026b4 <waitpid+0x126>
      release(&wait_lock);
    80002686:	0000f517          	auipc	a0,0xf
    8000268a:	c3250513          	addi	a0,a0,-974 # 800112b8 <wait_lock>
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	5f6080e7          	jalr	1526(ra) # 80000c84 <release>
      return -1;
    80002696:	597d                	li	s2,-1
  }
}
    80002698:	854a                	mv	a0,s2
    8000269a:	60e6                	ld	ra,88(sp)
    8000269c:	6446                	ld	s0,80(sp)
    8000269e:	64a6                	ld	s1,72(sp)
    800026a0:	6906                	ld	s2,64(sp)
    800026a2:	79e2                	ld	s3,56(sp)
    800026a4:	7a42                	ld	s4,48(sp)
    800026a6:	7aa2                	ld	s5,40(sp)
    800026a8:	7b02                	ld	s6,32(sp)
    800026aa:	6be2                	ld	s7,24(sp)
    800026ac:	6c42                	ld	s8,16(sp)
    800026ae:	6ca2                	ld	s9,8(sp)
    800026b0:	6125                	addi	sp,sp,96
    800026b2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026b4:	85e6                	mv	a1,s9
    800026b6:	8552                	mv	a0,s4
    800026b8:	00000097          	auipc	ra,0x0
    800026bc:	9ca080e7          	jalr	-1590(ra) # 80002082 <sleep>
    havekids = 0;
    800026c0:	bf31                	j	800025dc <waitpid+0x4e>

00000000800026c2 <ps>:

void
ps(void)
{
    800026c2:	7175                	addi	sp,sp,-144
    800026c4:	e506                	sd	ra,136(sp)
    800026c6:	e122                	sd	s0,128(sp)
    800026c8:	fca6                	sd	s1,120(sp)
    800026ca:	f8ca                	sd	s2,112(sp)
    800026cc:	f4ce                	sd	s3,104(sp)
    800026ce:	f0d2                	sd	s4,96(sp)
    800026d0:	ecd6                	sd	s5,88(sp)
    800026d2:	e8da                	sd	s6,80(sp)
    800026d4:	e4de                	sd	s7,72(sp)
    800026d6:	0900                	addi	s0,sp,144
  struct proc *np;
  char* states[] = { "UNUSED", "USED", "SLEEPING", "RUNNABLE", "RUNNING", "ZOMBIE" };
    800026d8:	00006797          	auipc	a5,0x6
    800026dc:	c7878793          	addi	a5,a5,-904 # 80008350 <states.0>
    800026e0:	7b88                	ld	a0,48(a5)
    800026e2:	7f8c                	ld	a1,56(a5)
    800026e4:	63b0                	ld	a2,64(a5)
    800026e6:	67b4                	ld	a3,72(a5)
    800026e8:	6bb8                	ld	a4,80(a5)
    800026ea:	6fbc                	ld	a5,88(a5)
    800026ec:	f8a43023          	sd	a0,-128(s0)
    800026f0:	f8b43423          	sd	a1,-120(s0)
    800026f4:	f8c43823          	sd	a2,-112(s0)
    800026f8:	f8d43c23          	sd	a3,-104(s0)
    800026fc:	fae43023          	sd	a4,-96(s0)
    80002700:	faf43423          	sd	a5,-88(s0)
  // acquire(&wait_lock);

  // for(;;){
    // Scan through table looking for exited children.
    // havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
    80002704:	0000f497          	auipc	s1,0xf
    80002708:	fcc48493          	addi	s1,s1,-52 # 800116d0 <proc>
      acquire(&np->lock);
      if(np->state != UNUSED)
        printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%x\n", np->pid, (np->parent) ? np->parent->pid : -1, states[np->state], np->name, np->ctime, np->stime, (np->state == ZOMBIE)? np->etime : ticks - np->stime, np->sz);
    8000270c:	5b7d                	li	s6,-1
    8000270e:	4a95                	li	s5,5
    80002710:	00006a17          	auipc	s4,0x6
    80002714:	b88a0a13          	addi	s4,s4,-1144 # 80008298 <digits+0x258>
    80002718:	00007b97          	auipc	s7,0x7
    8000271c:	918b8b93          	addi	s7,s7,-1768 # 80009030 <ticks>
    for(np = proc; np < &proc[NPROC]; np++){
    80002720:	00015997          	auipc	s3,0x15
    80002724:	fb098993          	addi	s3,s3,-80 # 800176d0 <tickslock>
    80002728:	a01d                	j	8000274e <ps+0x8c>
        printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%x\n", np->pid, (np->parent) ? np->parent->pid : -1, states[np->state], np->name, np->ctime, np->stime, (np->state == ZOMBIE)? np->etime : ticks - np->stime, np->sz);
    8000272a:	1784b883          	ld	a7,376(s1)
    8000272e:	64a8                	ld	a0,72(s1)
    80002730:	e02a                	sd	a0,0(sp)
    80002732:	8552                	mv	a0,s4
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	e50080e7          	jalr	-432(ra) # 80000584 <printf>
      release(&np->lock);
    8000273c:	8526                	mv	a0,s1
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	546080e7          	jalr	1350(ra) # 80000c84 <release>
    for(np = proc; np < &proc[NPROC]; np++){
    80002746:	18048493          	addi	s1,s1,384
    8000274a:	05348563          	beq	s1,s3,80002794 <ps+0xd2>
      acquire(&np->lock);
    8000274e:	8926                	mv	s2,s1
    80002750:	8526                	mv	a0,s1
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	47e080e7          	jalr	1150(ra) # 80000bd0 <acquire>
      if(np->state != UNUSED)
    8000275a:	4c88                	lw	a0,24(s1)
    8000275c:	d165                	beqz	a0,8000273c <ps+0x7a>
        printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%x\n", np->pid, (np->parent) ? np->parent->pid : -1, states[np->state], np->name, np->ctime, np->stime, (np->state == ZOMBIE)? np->etime : ticks - np->stime, np->sz);
    8000275e:	588c                	lw	a1,48(s1)
    80002760:	7c9c                	ld	a5,56(s1)
    80002762:	865a                	mv	a2,s6
    80002764:	c391                	beqz	a5,80002768 <ps+0xa6>
    80002766:	5b90                	lw	a2,48(a5)
    80002768:	02051713          	slli	a4,a0,0x20
    8000276c:	01d75793          	srli	a5,a4,0x1d
    80002770:	fb078793          	addi	a5,a5,-80
    80002774:	97a2                	add	a5,a5,s0
    80002776:	fd07b683          	ld	a3,-48(a5)
    8000277a:	15890713          	addi	a4,s2,344
    8000277e:	1684b783          	ld	a5,360(s1)
    80002782:	1704b803          	ld	a6,368(s1)
    80002786:	fb5502e3          	beq	a0,s5,8000272a <ps+0x68>
    8000278a:	000be883          	lwu	a7,0(s7)
    8000278e:	410888b3          	sub	a7,a7,a6
    80002792:	bf71                	j	8000272e <ps+0x6c>
    }
    return;
  // }
    80002794:	60aa                	ld	ra,136(sp)
    80002796:	640a                	ld	s0,128(sp)
    80002798:	74e6                	ld	s1,120(sp)
    8000279a:	7946                	ld	s2,112(sp)
    8000279c:	79a6                	ld	s3,104(sp)
    8000279e:	7a06                	ld	s4,96(sp)
    800027a0:	6ae6                	ld	s5,88(sp)
    800027a2:	6b46                	ld	s6,80(sp)
    800027a4:	6ba6                	ld	s7,72(sp)
    800027a6:	6149                	addi	sp,sp,144
    800027a8:	8082                	ret

00000000800027aa <swtch>:
    800027aa:	00153023          	sd	ra,0(a0)
    800027ae:	00253423          	sd	sp,8(a0)
    800027b2:	e900                	sd	s0,16(a0)
    800027b4:	ed04                	sd	s1,24(a0)
    800027b6:	03253023          	sd	s2,32(a0)
    800027ba:	03353423          	sd	s3,40(a0)
    800027be:	03453823          	sd	s4,48(a0)
    800027c2:	03553c23          	sd	s5,56(a0)
    800027c6:	05653023          	sd	s6,64(a0)
    800027ca:	05753423          	sd	s7,72(a0)
    800027ce:	05853823          	sd	s8,80(a0)
    800027d2:	05953c23          	sd	s9,88(a0)
    800027d6:	07a53023          	sd	s10,96(a0)
    800027da:	07b53423          	sd	s11,104(a0)
    800027de:	0005b083          	ld	ra,0(a1)
    800027e2:	0085b103          	ld	sp,8(a1)
    800027e6:	6980                	ld	s0,16(a1)
    800027e8:	6d84                	ld	s1,24(a1)
    800027ea:	0205b903          	ld	s2,32(a1)
    800027ee:	0285b983          	ld	s3,40(a1)
    800027f2:	0305ba03          	ld	s4,48(a1)
    800027f6:	0385ba83          	ld	s5,56(a1)
    800027fa:	0405bb03          	ld	s6,64(a1)
    800027fe:	0485bb83          	ld	s7,72(a1)
    80002802:	0505bc03          	ld	s8,80(a1)
    80002806:	0585bc83          	ld	s9,88(a1)
    8000280a:	0605bd03          	ld	s10,96(a1)
    8000280e:	0685bd83          	ld	s11,104(a1)
    80002812:	8082                	ret

0000000080002814 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002814:	1141                	addi	sp,sp,-16
    80002816:	e406                	sd	ra,8(sp)
    80002818:	e022                	sd	s0,0(sp)
    8000281a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000281c:	00006597          	auipc	a1,0x6
    80002820:	b9458593          	addi	a1,a1,-1132 # 800083b0 <states.0+0x60>
    80002824:	00015517          	auipc	a0,0x15
    80002828:	eac50513          	addi	a0,a0,-340 # 800176d0 <tickslock>
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	314080e7          	jalr	788(ra) # 80000b40 <initlock>
}
    80002834:	60a2                	ld	ra,8(sp)
    80002836:	6402                	ld	s0,0(sp)
    80002838:	0141                	addi	sp,sp,16
    8000283a:	8082                	ret

000000008000283c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000283c:	1141                	addi	sp,sp,-16
    8000283e:	e422                	sd	s0,8(sp)
    80002840:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002842:	00003797          	auipc	a5,0x3
    80002846:	59e78793          	addi	a5,a5,1438 # 80005de0 <kernelvec>
    8000284a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000284e:	6422                	ld	s0,8(sp)
    80002850:	0141                	addi	sp,sp,16
    80002852:	8082                	ret

0000000080002854 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002854:	1141                	addi	sp,sp,-16
    80002856:	e406                	sd	ra,8(sp)
    80002858:	e022                	sd	s0,0(sp)
    8000285a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000285c:	fffff097          	auipc	ra,0xfffff
    80002860:	13a080e7          	jalr	314(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002864:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002868:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000286a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000286e:	00004697          	auipc	a3,0x4
    80002872:	79268693          	addi	a3,a3,1938 # 80007000 <_trampoline>
    80002876:	00004717          	auipc	a4,0x4
    8000287a:	78a70713          	addi	a4,a4,1930 # 80007000 <_trampoline>
    8000287e:	8f15                	sub	a4,a4,a3
    80002880:	040007b7          	lui	a5,0x4000
    80002884:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002886:	07b2                	slli	a5,a5,0xc
    80002888:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000288a:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000288e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002890:	18002673          	csrr	a2,satp
    80002894:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002896:	6d30                	ld	a2,88(a0)
    80002898:	6138                	ld	a4,64(a0)
    8000289a:	6585                	lui	a1,0x1
    8000289c:	972e                	add	a4,a4,a1
    8000289e:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028a0:	6d38                	ld	a4,88(a0)
    800028a2:	00000617          	auipc	a2,0x0
    800028a6:	13860613          	addi	a2,a2,312 # 800029da <usertrap>
    800028aa:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028ac:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028ae:	8612                	mv	a2,tp
    800028b0:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b2:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028b6:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028ba:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028be:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028c2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028c4:	6f18                	ld	a4,24(a4)
    800028c6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028ca:	692c                	ld	a1,80(a0)
    800028cc:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028ce:	00004717          	auipc	a4,0x4
    800028d2:	7c270713          	addi	a4,a4,1986 # 80007090 <userret>
    800028d6:	8f15                	sub	a4,a4,a3
    800028d8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028da:	577d                	li	a4,-1
    800028dc:	177e                	slli	a4,a4,0x3f
    800028de:	8dd9                	or	a1,a1,a4
    800028e0:	02000537          	lui	a0,0x2000
    800028e4:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800028e6:	0536                	slli	a0,a0,0xd
    800028e8:	9782                	jalr	a5
}
    800028ea:	60a2                	ld	ra,8(sp)
    800028ec:	6402                	ld	s0,0(sp)
    800028ee:	0141                	addi	sp,sp,16
    800028f0:	8082                	ret

00000000800028f2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028f2:	1101                	addi	sp,sp,-32
    800028f4:	ec06                	sd	ra,24(sp)
    800028f6:	e822                	sd	s0,16(sp)
    800028f8:	e426                	sd	s1,8(sp)
    800028fa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028fc:	00015497          	auipc	s1,0x15
    80002900:	dd448493          	addi	s1,s1,-556 # 800176d0 <tickslock>
    80002904:	8526                	mv	a0,s1
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	2ca080e7          	jalr	714(ra) # 80000bd0 <acquire>
  ticks++;
    8000290e:	00006517          	auipc	a0,0x6
    80002912:	72250513          	addi	a0,a0,1826 # 80009030 <ticks>
    80002916:	411c                	lw	a5,0(a0)
    80002918:	2785                	addiw	a5,a5,1
    8000291a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000291c:	00000097          	auipc	ra,0x0
    80002920:	8f2080e7          	jalr	-1806(ra) # 8000220e <wakeup>
  release(&tickslock);
    80002924:	8526                	mv	a0,s1
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	35e080e7          	jalr	862(ra) # 80000c84 <release>
}
    8000292e:	60e2                	ld	ra,24(sp)
    80002930:	6442                	ld	s0,16(sp)
    80002932:	64a2                	ld	s1,8(sp)
    80002934:	6105                	addi	sp,sp,32
    80002936:	8082                	ret

0000000080002938 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002938:	1101                	addi	sp,sp,-32
    8000293a:	ec06                	sd	ra,24(sp)
    8000293c:	e822                	sd	s0,16(sp)
    8000293e:	e426                	sd	s1,8(sp)
    80002940:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002942:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002946:	00074d63          	bltz	a4,80002960 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000294a:	57fd                	li	a5,-1
    8000294c:	17fe                	slli	a5,a5,0x3f
    8000294e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002950:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002952:	06f70363          	beq	a4,a5,800029b8 <devintr+0x80>
  }
}
    80002956:	60e2                	ld	ra,24(sp)
    80002958:	6442                	ld	s0,16(sp)
    8000295a:	64a2                	ld	s1,8(sp)
    8000295c:	6105                	addi	sp,sp,32
    8000295e:	8082                	ret
     (scause & 0xff) == 9){
    80002960:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002964:	46a5                	li	a3,9
    80002966:	fed792e3          	bne	a5,a3,8000294a <devintr+0x12>
    int irq = plic_claim();
    8000296a:	00003097          	auipc	ra,0x3
    8000296e:	57e080e7          	jalr	1406(ra) # 80005ee8 <plic_claim>
    80002972:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002974:	47a9                	li	a5,10
    80002976:	02f50763          	beq	a0,a5,800029a4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000297a:	4785                	li	a5,1
    8000297c:	02f50963          	beq	a0,a5,800029ae <devintr+0x76>
    return 1;
    80002980:	4505                	li	a0,1
    } else if(irq){
    80002982:	d8f1                	beqz	s1,80002956 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002984:	85a6                	mv	a1,s1
    80002986:	00006517          	auipc	a0,0x6
    8000298a:	a3250513          	addi	a0,a0,-1486 # 800083b8 <states.0+0x68>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	bf6080e7          	jalr	-1034(ra) # 80000584 <printf>
      plic_complete(irq);
    80002996:	8526                	mv	a0,s1
    80002998:	00003097          	auipc	ra,0x3
    8000299c:	574080e7          	jalr	1396(ra) # 80005f0c <plic_complete>
    return 1;
    800029a0:	4505                	li	a0,1
    800029a2:	bf55                	j	80002956 <devintr+0x1e>
      uartintr();
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	fee080e7          	jalr	-18(ra) # 80000992 <uartintr>
    800029ac:	b7ed                	j	80002996 <devintr+0x5e>
      virtio_disk_intr();
    800029ae:	00004097          	auipc	ra,0x4
    800029b2:	9ea080e7          	jalr	-1558(ra) # 80006398 <virtio_disk_intr>
    800029b6:	b7c5                	j	80002996 <devintr+0x5e>
    if(cpuid() == 0){
    800029b8:	fffff097          	auipc	ra,0xfffff
    800029bc:	fb2080e7          	jalr	-78(ra) # 8000196a <cpuid>
    800029c0:	c901                	beqz	a0,800029d0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029c2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029c6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029c8:	14479073          	csrw	sip,a5
    return 2;
    800029cc:	4509                	li	a0,2
    800029ce:	b761                	j	80002956 <devintr+0x1e>
      clockintr();
    800029d0:	00000097          	auipc	ra,0x0
    800029d4:	f22080e7          	jalr	-222(ra) # 800028f2 <clockintr>
    800029d8:	b7ed                	j	800029c2 <devintr+0x8a>

00000000800029da <usertrap>:
{
    800029da:	1101                	addi	sp,sp,-32
    800029dc:	ec06                	sd	ra,24(sp)
    800029de:	e822                	sd	s0,16(sp)
    800029e0:	e426                	sd	s1,8(sp)
    800029e2:	e04a                	sd	s2,0(sp)
    800029e4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029ea:	1007f793          	andi	a5,a5,256
    800029ee:	e3ad                	bnez	a5,80002a50 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029f0:	00003797          	auipc	a5,0x3
    800029f4:	3f078793          	addi	a5,a5,1008 # 80005de0 <kernelvec>
    800029f8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029fc:	fffff097          	auipc	ra,0xfffff
    80002a00:	f9a080e7          	jalr	-102(ra) # 80001996 <myproc>
    80002a04:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a06:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a08:	14102773          	csrr	a4,sepc
    80002a0c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a12:	47a1                	li	a5,8
    80002a14:	04f71c63          	bne	a4,a5,80002a6c <usertrap+0x92>
    if(p->killed)
    80002a18:	551c                	lw	a5,40(a0)
    80002a1a:	e3b9                	bnez	a5,80002a60 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a1c:	6cb8                	ld	a4,88(s1)
    80002a1e:	6f1c                	ld	a5,24(a4)
    80002a20:	0791                	addi	a5,a5,4
    80002a22:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a24:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a28:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a2c:	10079073          	csrw	sstatus,a5
    syscall();
    80002a30:	00000097          	auipc	ra,0x0
    80002a34:	2e0080e7          	jalr	736(ra) # 80002d10 <syscall>
  if(p->killed)
    80002a38:	549c                	lw	a5,40(s1)
    80002a3a:	ebc1                	bnez	a5,80002aca <usertrap+0xf0>
  usertrapret();
    80002a3c:	00000097          	auipc	ra,0x0
    80002a40:	e18080e7          	jalr	-488(ra) # 80002854 <usertrapret>
}
    80002a44:	60e2                	ld	ra,24(sp)
    80002a46:	6442                	ld	s0,16(sp)
    80002a48:	64a2                	ld	s1,8(sp)
    80002a4a:	6902                	ld	s2,0(sp)
    80002a4c:	6105                	addi	sp,sp,32
    80002a4e:	8082                	ret
    panic("usertrap: not from user mode");
    80002a50:	00006517          	auipc	a0,0x6
    80002a54:	98850513          	addi	a0,a0,-1656 # 800083d8 <states.0+0x88>
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	ae2080e7          	jalr	-1310(ra) # 8000053a <panic>
      exit(-1);
    80002a60:	557d                	li	a0,-1
    80002a62:	00000097          	auipc	ra,0x0
    80002a66:	87c080e7          	jalr	-1924(ra) # 800022de <exit>
    80002a6a:	bf4d                	j	80002a1c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a6c:	00000097          	auipc	ra,0x0
    80002a70:	ecc080e7          	jalr	-308(ra) # 80002938 <devintr>
    80002a74:	892a                	mv	s2,a0
    80002a76:	c501                	beqz	a0,80002a7e <usertrap+0xa4>
  if(p->killed)
    80002a78:	549c                	lw	a5,40(s1)
    80002a7a:	c3a1                	beqz	a5,80002aba <usertrap+0xe0>
    80002a7c:	a815                	j	80002ab0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a7e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a82:	5890                	lw	a2,48(s1)
    80002a84:	00006517          	auipc	a0,0x6
    80002a88:	97450513          	addi	a0,a0,-1676 # 800083f8 <states.0+0xa8>
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	af8080e7          	jalr	-1288(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a94:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a98:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a9c:	00006517          	auipc	a0,0x6
    80002aa0:	98c50513          	addi	a0,a0,-1652 # 80008428 <states.0+0xd8>
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	ae0080e7          	jalr	-1312(ra) # 80000584 <printf>
    p->killed = 1;
    80002aac:	4785                	li	a5,1
    80002aae:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ab0:	557d                	li	a0,-1
    80002ab2:	00000097          	auipc	ra,0x0
    80002ab6:	82c080e7          	jalr	-2004(ra) # 800022de <exit>
  if(which_dev == 2)
    80002aba:	4789                	li	a5,2
    80002abc:	f8f910e3          	bne	s2,a5,80002a3c <usertrap+0x62>
    yield();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	586080e7          	jalr	1414(ra) # 80002046 <yield>
    80002ac8:	bf95                	j	80002a3c <usertrap+0x62>
  int which_dev = 0;
    80002aca:	4901                	li	s2,0
    80002acc:	b7d5                	j	80002ab0 <usertrap+0xd6>

0000000080002ace <kerneltrap>:
{
    80002ace:	7179                	addi	sp,sp,-48
    80002ad0:	f406                	sd	ra,40(sp)
    80002ad2:	f022                	sd	s0,32(sp)
    80002ad4:	ec26                	sd	s1,24(sp)
    80002ad6:	e84a                	sd	s2,16(sp)
    80002ad8:	e44e                	sd	s3,8(sp)
    80002ada:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002adc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ae8:	1004f793          	andi	a5,s1,256
    80002aec:	cb85                	beqz	a5,80002b1c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aee:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002af2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002af4:	ef85                	bnez	a5,80002b2c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002af6:	00000097          	auipc	ra,0x0
    80002afa:	e42080e7          	jalr	-446(ra) # 80002938 <devintr>
    80002afe:	cd1d                	beqz	a0,80002b3c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b00:	4789                	li	a5,2
    80002b02:	06f50a63          	beq	a0,a5,80002b76 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b06:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b0a:	10049073          	csrw	sstatus,s1
}
    80002b0e:	70a2                	ld	ra,40(sp)
    80002b10:	7402                	ld	s0,32(sp)
    80002b12:	64e2                	ld	s1,24(sp)
    80002b14:	6942                	ld	s2,16(sp)
    80002b16:	69a2                	ld	s3,8(sp)
    80002b18:	6145                	addi	sp,sp,48
    80002b1a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b1c:	00006517          	auipc	a0,0x6
    80002b20:	92c50513          	addi	a0,a0,-1748 # 80008448 <states.0+0xf8>
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	a16080e7          	jalr	-1514(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002b2c:	00006517          	auipc	a0,0x6
    80002b30:	94450513          	addi	a0,a0,-1724 # 80008470 <states.0+0x120>
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	a06080e7          	jalr	-1530(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002b3c:	85ce                	mv	a1,s3
    80002b3e:	00006517          	auipc	a0,0x6
    80002b42:	95250513          	addi	a0,a0,-1710 # 80008490 <states.0+0x140>
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	a3e080e7          	jalr	-1474(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b4e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b52:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b56:	00006517          	auipc	a0,0x6
    80002b5a:	94a50513          	addi	a0,a0,-1718 # 800084a0 <states.0+0x150>
    80002b5e:	ffffe097          	auipc	ra,0xffffe
    80002b62:	a26080e7          	jalr	-1498(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002b66:	00006517          	auipc	a0,0x6
    80002b6a:	95250513          	addi	a0,a0,-1710 # 800084b8 <states.0+0x168>
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	9cc080e7          	jalr	-1588(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b76:	fffff097          	auipc	ra,0xfffff
    80002b7a:	e20080e7          	jalr	-480(ra) # 80001996 <myproc>
    80002b7e:	d541                	beqz	a0,80002b06 <kerneltrap+0x38>
    80002b80:	fffff097          	auipc	ra,0xfffff
    80002b84:	e16080e7          	jalr	-490(ra) # 80001996 <myproc>
    80002b88:	4d18                	lw	a4,24(a0)
    80002b8a:	4791                	li	a5,4
    80002b8c:	f6f71de3          	bne	a4,a5,80002b06 <kerneltrap+0x38>
    yield();
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	4b6080e7          	jalr	1206(ra) # 80002046 <yield>
    80002b98:	b7bd                	j	80002b06 <kerneltrap+0x38>

0000000080002b9a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b9a:	1101                	addi	sp,sp,-32
    80002b9c:	ec06                	sd	ra,24(sp)
    80002b9e:	e822                	sd	s0,16(sp)
    80002ba0:	e426                	sd	s1,8(sp)
    80002ba2:	1000                	addi	s0,sp,32
    80002ba4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	df0080e7          	jalr	-528(ra) # 80001996 <myproc>
  switch (n) {
    80002bae:	4795                	li	a5,5
    80002bb0:	0497e163          	bltu	a5,s1,80002bf2 <argraw+0x58>
    80002bb4:	048a                	slli	s1,s1,0x2
    80002bb6:	00006717          	auipc	a4,0x6
    80002bba:	93a70713          	addi	a4,a4,-1734 # 800084f0 <states.0+0x1a0>
    80002bbe:	94ba                	add	s1,s1,a4
    80002bc0:	409c                	lw	a5,0(s1)
    80002bc2:	97ba                	add	a5,a5,a4
    80002bc4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bc6:	6d3c                	ld	a5,88(a0)
    80002bc8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bca:	60e2                	ld	ra,24(sp)
    80002bcc:	6442                	ld	s0,16(sp)
    80002bce:	64a2                	ld	s1,8(sp)
    80002bd0:	6105                	addi	sp,sp,32
    80002bd2:	8082                	ret
    return p->trapframe->a1;
    80002bd4:	6d3c                	ld	a5,88(a0)
    80002bd6:	7fa8                	ld	a0,120(a5)
    80002bd8:	bfcd                	j	80002bca <argraw+0x30>
    return p->trapframe->a2;
    80002bda:	6d3c                	ld	a5,88(a0)
    80002bdc:	63c8                	ld	a0,128(a5)
    80002bde:	b7f5                	j	80002bca <argraw+0x30>
    return p->trapframe->a3;
    80002be0:	6d3c                	ld	a5,88(a0)
    80002be2:	67c8                	ld	a0,136(a5)
    80002be4:	b7dd                	j	80002bca <argraw+0x30>
    return p->trapframe->a4;
    80002be6:	6d3c                	ld	a5,88(a0)
    80002be8:	6bc8                	ld	a0,144(a5)
    80002bea:	b7c5                	j	80002bca <argraw+0x30>
    return p->trapframe->a5;
    80002bec:	6d3c                	ld	a5,88(a0)
    80002bee:	6fc8                	ld	a0,152(a5)
    80002bf0:	bfe9                	j	80002bca <argraw+0x30>
  panic("argraw");
    80002bf2:	00006517          	auipc	a0,0x6
    80002bf6:	8d650513          	addi	a0,a0,-1834 # 800084c8 <states.0+0x178>
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	940080e7          	jalr	-1728(ra) # 8000053a <panic>

0000000080002c02 <fetchaddr>:
{
    80002c02:	1101                	addi	sp,sp,-32
    80002c04:	ec06                	sd	ra,24(sp)
    80002c06:	e822                	sd	s0,16(sp)
    80002c08:	e426                	sd	s1,8(sp)
    80002c0a:	e04a                	sd	s2,0(sp)
    80002c0c:	1000                	addi	s0,sp,32
    80002c0e:	84aa                	mv	s1,a0
    80002c10:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	d84080e7          	jalr	-636(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c1a:	653c                	ld	a5,72(a0)
    80002c1c:	02f4f863          	bgeu	s1,a5,80002c4c <fetchaddr+0x4a>
    80002c20:	00848713          	addi	a4,s1,8
    80002c24:	02e7e663          	bltu	a5,a4,80002c50 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c28:	46a1                	li	a3,8
    80002c2a:	8626                	mv	a2,s1
    80002c2c:	85ca                	mv	a1,s2
    80002c2e:	6928                	ld	a0,80(a0)
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	ab6080e7          	jalr	-1354(ra) # 800016e6 <copyin>
    80002c38:	00a03533          	snez	a0,a0
    80002c3c:	40a00533          	neg	a0,a0
}
    80002c40:	60e2                	ld	ra,24(sp)
    80002c42:	6442                	ld	s0,16(sp)
    80002c44:	64a2                	ld	s1,8(sp)
    80002c46:	6902                	ld	s2,0(sp)
    80002c48:	6105                	addi	sp,sp,32
    80002c4a:	8082                	ret
    return -1;
    80002c4c:	557d                	li	a0,-1
    80002c4e:	bfcd                	j	80002c40 <fetchaddr+0x3e>
    80002c50:	557d                	li	a0,-1
    80002c52:	b7fd                	j	80002c40 <fetchaddr+0x3e>

0000000080002c54 <fetchstr>:
{
    80002c54:	7179                	addi	sp,sp,-48
    80002c56:	f406                	sd	ra,40(sp)
    80002c58:	f022                	sd	s0,32(sp)
    80002c5a:	ec26                	sd	s1,24(sp)
    80002c5c:	e84a                	sd	s2,16(sp)
    80002c5e:	e44e                	sd	s3,8(sp)
    80002c60:	1800                	addi	s0,sp,48
    80002c62:	892a                	mv	s2,a0
    80002c64:	84ae                	mv	s1,a1
    80002c66:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	d2e080e7          	jalr	-722(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c70:	86ce                	mv	a3,s3
    80002c72:	864a                	mv	a2,s2
    80002c74:	85a6                	mv	a1,s1
    80002c76:	6928                	ld	a0,80(a0)
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	afc080e7          	jalr	-1284(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002c80:	00054763          	bltz	a0,80002c8e <fetchstr+0x3a>
  return strlen(buf);
    80002c84:	8526                	mv	a0,s1
    80002c86:	ffffe097          	auipc	ra,0xffffe
    80002c8a:	1c2080e7          	jalr	450(ra) # 80000e48 <strlen>
}
    80002c8e:	70a2                	ld	ra,40(sp)
    80002c90:	7402                	ld	s0,32(sp)
    80002c92:	64e2                	ld	s1,24(sp)
    80002c94:	6942                	ld	s2,16(sp)
    80002c96:	69a2                	ld	s3,8(sp)
    80002c98:	6145                	addi	sp,sp,48
    80002c9a:	8082                	ret

0000000080002c9c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c9c:	1101                	addi	sp,sp,-32
    80002c9e:	ec06                	sd	ra,24(sp)
    80002ca0:	e822                	sd	s0,16(sp)
    80002ca2:	e426                	sd	s1,8(sp)
    80002ca4:	1000                	addi	s0,sp,32
    80002ca6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ca8:	00000097          	auipc	ra,0x0
    80002cac:	ef2080e7          	jalr	-270(ra) # 80002b9a <argraw>
    80002cb0:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cb2:	4501                	li	a0,0
    80002cb4:	60e2                	ld	ra,24(sp)
    80002cb6:	6442                	ld	s0,16(sp)
    80002cb8:	64a2                	ld	s1,8(sp)
    80002cba:	6105                	addi	sp,sp,32
    80002cbc:	8082                	ret

0000000080002cbe <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cbe:	1101                	addi	sp,sp,-32
    80002cc0:	ec06                	sd	ra,24(sp)
    80002cc2:	e822                	sd	s0,16(sp)
    80002cc4:	e426                	sd	s1,8(sp)
    80002cc6:	1000                	addi	s0,sp,32
    80002cc8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cca:	00000097          	auipc	ra,0x0
    80002cce:	ed0080e7          	jalr	-304(ra) # 80002b9a <argraw>
    80002cd2:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cd4:	4501                	li	a0,0
    80002cd6:	60e2                	ld	ra,24(sp)
    80002cd8:	6442                	ld	s0,16(sp)
    80002cda:	64a2                	ld	s1,8(sp)
    80002cdc:	6105                	addi	sp,sp,32
    80002cde:	8082                	ret

0000000080002ce0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ce0:	1101                	addi	sp,sp,-32
    80002ce2:	ec06                	sd	ra,24(sp)
    80002ce4:	e822                	sd	s0,16(sp)
    80002ce6:	e426                	sd	s1,8(sp)
    80002ce8:	e04a                	sd	s2,0(sp)
    80002cea:	1000                	addi	s0,sp,32
    80002cec:	84ae                	mv	s1,a1
    80002cee:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cf0:	00000097          	auipc	ra,0x0
    80002cf4:	eaa080e7          	jalr	-342(ra) # 80002b9a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cf8:	864a                	mv	a2,s2
    80002cfa:	85a6                	mv	a1,s1
    80002cfc:	00000097          	auipc	ra,0x0
    80002d00:	f58080e7          	jalr	-168(ra) # 80002c54 <fetchstr>
}
    80002d04:	60e2                	ld	ra,24(sp)
    80002d06:	6442                	ld	s0,16(sp)
    80002d08:	64a2                	ld	s1,8(sp)
    80002d0a:	6902                	ld	s2,0(sp)
    80002d0c:	6105                	addi	sp,sp,32
    80002d0e:	8082                	ret

0000000080002d10 <syscall>:
[SYS_ps]      sys_ps,
};

void
syscall(void)
{
    80002d10:	1101                	addi	sp,sp,-32
    80002d12:	ec06                	sd	ra,24(sp)
    80002d14:	e822                	sd	s0,16(sp)
    80002d16:	e426                	sd	s1,8(sp)
    80002d18:	e04a                	sd	s2,0(sp)
    80002d1a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	c7a080e7          	jalr	-902(ra) # 80001996 <myproc>
    80002d24:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d26:	05853903          	ld	s2,88(a0)
    80002d2a:	0a893783          	ld	a5,168(s2)
    80002d2e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d32:	37fd                	addiw	a5,a5,-1
    80002d34:	4765                	li	a4,25
    80002d36:	00f76f63          	bltu	a4,a5,80002d54 <syscall+0x44>
    80002d3a:	00369713          	slli	a4,a3,0x3
    80002d3e:	00005797          	auipc	a5,0x5
    80002d42:	7ca78793          	addi	a5,a5,1994 # 80008508 <syscalls>
    80002d46:	97ba                	add	a5,a5,a4
    80002d48:	639c                	ld	a5,0(a5)
    80002d4a:	c789                	beqz	a5,80002d54 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d4c:	9782                	jalr	a5
    80002d4e:	06a93823          	sd	a0,112(s2)
    80002d52:	a839                	j	80002d70 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d54:	15848613          	addi	a2,s1,344
    80002d58:	588c                	lw	a1,48(s1)
    80002d5a:	00005517          	auipc	a0,0x5
    80002d5e:	77650513          	addi	a0,a0,1910 # 800084d0 <states.0+0x180>
    80002d62:	ffffe097          	auipc	ra,0xffffe
    80002d66:	822080e7          	jalr	-2014(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d6a:	6cbc                	ld	a5,88(s1)
    80002d6c:	577d                	li	a4,-1
    80002d6e:	fbb8                	sd	a4,112(a5)
  }
}
    80002d70:	60e2                	ld	ra,24(sp)
    80002d72:	6442                	ld	s0,16(sp)
    80002d74:	64a2                	ld	s1,8(sp)
    80002d76:	6902                	ld	s2,0(sp)
    80002d78:	6105                	addi	sp,sp,32
    80002d7a:	8082                	ret

0000000080002d7c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d7c:	1101                	addi	sp,sp,-32
    80002d7e:	ec06                	sd	ra,24(sp)
    80002d80:	e822                	sd	s0,16(sp)
    80002d82:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d84:	fec40593          	addi	a1,s0,-20
    80002d88:	4501                	li	a0,0
    80002d8a:	00000097          	auipc	ra,0x0
    80002d8e:	f12080e7          	jalr	-238(ra) # 80002c9c <argint>
    return -1;
    80002d92:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d94:	00054963          	bltz	a0,80002da6 <sys_exit+0x2a>
  exit(n);
    80002d98:	fec42503          	lw	a0,-20(s0)
    80002d9c:	fffff097          	auipc	ra,0xfffff
    80002da0:	542080e7          	jalr	1346(ra) # 800022de <exit>
  return 0;  // not reached
    80002da4:	4781                	li	a5,0
}
    80002da6:	853e                	mv	a0,a5
    80002da8:	60e2                	ld	ra,24(sp)
    80002daa:	6442                	ld	s0,16(sp)
    80002dac:	6105                	addi	sp,sp,32
    80002dae:	8082                	ret

0000000080002db0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002db0:	1141                	addi	sp,sp,-16
    80002db2:	e406                	sd	ra,8(sp)
    80002db4:	e022                	sd	s0,0(sp)
    80002db6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	bde080e7          	jalr	-1058(ra) # 80001996 <myproc>
}
    80002dc0:	5908                	lw	a0,48(a0)
    80002dc2:	60a2                	ld	ra,8(sp)
    80002dc4:	6402                	ld	s0,0(sp)
    80002dc6:	0141                	addi	sp,sp,16
    80002dc8:	8082                	ret

0000000080002dca <sys_fork>:

uint64
sys_fork(void)
{
    80002dca:	1141                	addi	sp,sp,-16
    80002dcc:	e406                	sd	ra,8(sp)
    80002dce:	e022                	sd	s0,0(sp)
    80002dd0:	0800                	addi	s0,sp,16
  return fork();
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	fbe080e7          	jalr	-66(ra) # 80001d90 <fork>
}
    80002dda:	60a2                	ld	ra,8(sp)
    80002ddc:	6402                	ld	s0,0(sp)
    80002dde:	0141                	addi	sp,sp,16
    80002de0:	8082                	ret

0000000080002de2 <sys_wait>:

uint64
sys_wait(void)
{
    80002de2:	1101                	addi	sp,sp,-32
    80002de4:	ec06                	sd	ra,24(sp)
    80002de6:	e822                	sd	s0,16(sp)
    80002de8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002dea:	fe840593          	addi	a1,s0,-24
    80002dee:	4501                	li	a0,0
    80002df0:	00000097          	auipc	ra,0x0
    80002df4:	ece080e7          	jalr	-306(ra) # 80002cbe <argaddr>
    80002df8:	87aa                	mv	a5,a0
    return -1;
    80002dfa:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dfc:	0007c863          	bltz	a5,80002e0c <sys_wait+0x2a>
  return wait(p);
    80002e00:	fe843503          	ld	a0,-24(s0)
    80002e04:	fffff097          	auipc	ra,0xfffff
    80002e08:	2e2080e7          	jalr	738(ra) # 800020e6 <wait>
}
    80002e0c:	60e2                	ld	ra,24(sp)
    80002e0e:	6442                	ld	s0,16(sp)
    80002e10:	6105                	addi	sp,sp,32
    80002e12:	8082                	ret

0000000080002e14 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e14:	7179                	addi	sp,sp,-48
    80002e16:	f406                	sd	ra,40(sp)
    80002e18:	f022                	sd	s0,32(sp)
    80002e1a:	ec26                	sd	s1,24(sp)
    80002e1c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e1e:	fdc40593          	addi	a1,s0,-36
    80002e22:	4501                	li	a0,0
    80002e24:	00000097          	auipc	ra,0x0
    80002e28:	e78080e7          	jalr	-392(ra) # 80002c9c <argint>
    80002e2c:	87aa                	mv	a5,a0
    return -1;
    80002e2e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e30:	0207c063          	bltz	a5,80002e50 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	b62080e7          	jalr	-1182(ra) # 80001996 <myproc>
    80002e3c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e3e:	fdc42503          	lw	a0,-36(s0)
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	ed6080e7          	jalr	-298(ra) # 80001d18 <growproc>
    80002e4a:	00054863          	bltz	a0,80002e5a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e4e:	8526                	mv	a0,s1
}
    80002e50:	70a2                	ld	ra,40(sp)
    80002e52:	7402                	ld	s0,32(sp)
    80002e54:	64e2                	ld	s1,24(sp)
    80002e56:	6145                	addi	sp,sp,48
    80002e58:	8082                	ret
    return -1;
    80002e5a:	557d                	li	a0,-1
    80002e5c:	bfd5                	j	80002e50 <sys_sbrk+0x3c>

0000000080002e5e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e5e:	7139                	addi	sp,sp,-64
    80002e60:	fc06                	sd	ra,56(sp)
    80002e62:	f822                	sd	s0,48(sp)
    80002e64:	f426                	sd	s1,40(sp)
    80002e66:	f04a                	sd	s2,32(sp)
    80002e68:	ec4e                	sd	s3,24(sp)
    80002e6a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e6c:	fcc40593          	addi	a1,s0,-52
    80002e70:	4501                	li	a0,0
    80002e72:	00000097          	auipc	ra,0x0
    80002e76:	e2a080e7          	jalr	-470(ra) # 80002c9c <argint>
    return -1;
    80002e7a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e7c:	06054563          	bltz	a0,80002ee6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e80:	00015517          	auipc	a0,0x15
    80002e84:	85050513          	addi	a0,a0,-1968 # 800176d0 <tickslock>
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	d48080e7          	jalr	-696(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002e90:	00006917          	auipc	s2,0x6
    80002e94:	1a092903          	lw	s2,416(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e98:	fcc42783          	lw	a5,-52(s0)
    80002e9c:	cf85                	beqz	a5,80002ed4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e9e:	00015997          	auipc	s3,0x15
    80002ea2:	83298993          	addi	s3,s3,-1998 # 800176d0 <tickslock>
    80002ea6:	00006497          	auipc	s1,0x6
    80002eaa:	18a48493          	addi	s1,s1,394 # 80009030 <ticks>
    if(myproc()->killed){
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	ae8080e7          	jalr	-1304(ra) # 80001996 <myproc>
    80002eb6:	551c                	lw	a5,40(a0)
    80002eb8:	ef9d                	bnez	a5,80002ef6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002eba:	85ce                	mv	a1,s3
    80002ebc:	8526                	mv	a0,s1
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	1c4080e7          	jalr	452(ra) # 80002082 <sleep>
  while(ticks - ticks0 < n){
    80002ec6:	409c                	lw	a5,0(s1)
    80002ec8:	412787bb          	subw	a5,a5,s2
    80002ecc:	fcc42703          	lw	a4,-52(s0)
    80002ed0:	fce7efe3          	bltu	a5,a4,80002eae <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ed4:	00014517          	auipc	a0,0x14
    80002ed8:	7fc50513          	addi	a0,a0,2044 # 800176d0 <tickslock>
    80002edc:	ffffe097          	auipc	ra,0xffffe
    80002ee0:	da8080e7          	jalr	-600(ra) # 80000c84 <release>
  return 0;
    80002ee4:	4781                	li	a5,0
}
    80002ee6:	853e                	mv	a0,a5
    80002ee8:	70e2                	ld	ra,56(sp)
    80002eea:	7442                	ld	s0,48(sp)
    80002eec:	74a2                	ld	s1,40(sp)
    80002eee:	7902                	ld	s2,32(sp)
    80002ef0:	69e2                	ld	s3,24(sp)
    80002ef2:	6121                	addi	sp,sp,64
    80002ef4:	8082                	ret
      release(&tickslock);
    80002ef6:	00014517          	auipc	a0,0x14
    80002efa:	7da50513          	addi	a0,a0,2010 # 800176d0 <tickslock>
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	d86080e7          	jalr	-634(ra) # 80000c84 <release>
      return -1;
    80002f06:	57fd                	li	a5,-1
    80002f08:	bff9                	j	80002ee6 <sys_sleep+0x88>

0000000080002f0a <sys_kill>:

uint64
sys_kill(void)
{
    80002f0a:	1101                	addi	sp,sp,-32
    80002f0c:	ec06                	sd	ra,24(sp)
    80002f0e:	e822                	sd	s0,16(sp)
    80002f10:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f12:	fec40593          	addi	a1,s0,-20
    80002f16:	4501                	li	a0,0
    80002f18:	00000097          	auipc	ra,0x0
    80002f1c:	d84080e7          	jalr	-636(ra) # 80002c9c <argint>
    80002f20:	87aa                	mv	a5,a0
    return -1;
    80002f22:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f24:	0007c863          	bltz	a5,80002f34 <sys_kill+0x2a>
  return kill(pid);
    80002f28:	fec42503          	lw	a0,-20(s0)
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	494080e7          	jalr	1172(ra) # 800023c0 <kill>
}
    80002f34:	60e2                	ld	ra,24(sp)
    80002f36:	6442                	ld	s0,16(sp)
    80002f38:	6105                	addi	sp,sp,32
    80002f3a:	8082                	ret

0000000080002f3c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f3c:	1101                	addi	sp,sp,-32
    80002f3e:	ec06                	sd	ra,24(sp)
    80002f40:	e822                	sd	s0,16(sp)
    80002f42:	e426                	sd	s1,8(sp)
    80002f44:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f46:	00014517          	auipc	a0,0x14
    80002f4a:	78a50513          	addi	a0,a0,1930 # 800176d0 <tickslock>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	c82080e7          	jalr	-894(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002f56:	00006497          	auipc	s1,0x6
    80002f5a:	0da4a483          	lw	s1,218(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f5e:	00014517          	auipc	a0,0x14
    80002f62:	77250513          	addi	a0,a0,1906 # 800176d0 <tickslock>
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	d1e080e7          	jalr	-738(ra) # 80000c84 <release>
  return xticks;
}
    80002f6e:	02049513          	slli	a0,s1,0x20
    80002f72:	9101                	srli	a0,a0,0x20
    80002f74:	60e2                	ld	ra,24(sp)
    80002f76:	6442                	ld	s0,16(sp)
    80002f78:	64a2                	ld	s1,8(sp)
    80002f7a:	6105                	addi	sp,sp,32
    80002f7c:	8082                	ret

0000000080002f7e <sys_getppid>:

uint64
sys_getppid(void)
{
    80002f7e:	1141                	addi	sp,sp,-16
    80002f80:	e406                	sd	ra,8(sp)
    80002f82:	e022                	sd	s0,0(sp)
    80002f84:	0800                	addi	s0,sp,16
  struct proc* par_proc = myproc()->parent;
    80002f86:	fffff097          	auipc	ra,0xfffff
    80002f8a:	a10080e7          	jalr	-1520(ra) # 80001996 <myproc>
    80002f8e:	7d1c                	ld	a5,56(a0)
  if(par_proc) return par_proc->pid;
    80002f90:	c791                	beqz	a5,80002f9c <sys_getppid+0x1e>
    80002f92:	5b88                	lw	a0,48(a5)
  else return -1;
}
    80002f94:	60a2                	ld	ra,8(sp)
    80002f96:	6402                	ld	s0,0(sp)
    80002f98:	0141                	addi	sp,sp,16
    80002f9a:	8082                	ret
  else return -1;
    80002f9c:	557d                	li	a0,-1
    80002f9e:	bfdd                	j	80002f94 <sys_getppid+0x16>

0000000080002fa0 <sys_yield>:

uint64
sys_yield(void)
{
    80002fa0:	1141                	addi	sp,sp,-16
    80002fa2:	e406                	sd	ra,8(sp)
    80002fa4:	e022                	sd	s0,0(sp)
    80002fa6:	0800                	addi	s0,sp,16
  yield();
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	09e080e7          	jalr	158(ra) # 80002046 <yield>
  return 0;
}
    80002fb0:	4501                	li	a0,0
    80002fb2:	60a2                	ld	ra,8(sp)
    80002fb4:	6402                	ld	s0,0(sp)
    80002fb6:	0141                	addi	sp,sp,16
    80002fb8:	8082                	ret

0000000080002fba <sys_getpa>:

uint64
sys_getpa(void)
{
    80002fba:	1101                	addi	sp,sp,-32
    80002fbc:	ec06                	sd	ra,24(sp)
    80002fbe:	e822                	sd	s0,16(sp)
    80002fc0:	1000                	addi	s0,sp,32
  int va;
  if(argint(0, &va) < 0)
    80002fc2:	fec40593          	addi	a1,s0,-20
    80002fc6:	4501                	li	a0,0
    80002fc8:	00000097          	auipc	ra,0x0
    80002fcc:	cd4080e7          	jalr	-812(ra) # 80002c9c <argint>
    80002fd0:	87aa                	mv	a5,a0
    return -1;
    80002fd2:	557d                	li	a0,-1
  if(argint(0, &va) < 0)
    80002fd4:	0207c263          	bltz	a5,80002ff8 <sys_getpa+0x3e>
    
  return walkaddr(myproc()->pagetable, va) + (va & (PGSIZE - 1));
    80002fd8:	fffff097          	auipc	ra,0xfffff
    80002fdc:	9be080e7          	jalr	-1602(ra) # 80001996 <myproc>
    80002fe0:	fec42583          	lw	a1,-20(s0)
    80002fe4:	6928                	ld	a0,80(a0)
    80002fe6:	ffffe097          	auipc	ra,0xffffe
    80002fea:	06c080e7          	jalr	108(ra) # 80001052 <walkaddr>
    80002fee:	fec42783          	lw	a5,-20(s0)
    80002ff2:	17d2                	slli	a5,a5,0x34
    80002ff4:	93d1                	srli	a5,a5,0x34
    80002ff6:	953e                	add	a0,a0,a5
}
    80002ff8:	60e2                	ld	ra,24(sp)
    80002ffa:	6442                	ld	s0,16(sp)
    80002ffc:	6105                	addi	sp,sp,32
    80002ffe:	8082                	ret

0000000080003000 <sys_waitpid>:

uint64
sys_waitpid(void)
{
    80003000:	1101                	addi	sp,sp,-32
    80003002:	ec06                	sd	ra,24(sp)
    80003004:	e822                	sd	s0,16(sp)
    80003006:	1000                	addi	s0,sp,32
  uint64 pid;
  uint64 p;
  if(argaddr(0, &pid) < 0)
    80003008:	fe840593          	addi	a1,s0,-24
    8000300c:	4501                	li	a0,0
    8000300e:	00000097          	auipc	ra,0x0
    80003012:	cb0080e7          	jalr	-848(ra) # 80002cbe <argaddr>
    80003016:	87aa                	mv	a5,a0
    return -1;
    80003018:	557d                	li	a0,-1
  if(argaddr(0, &pid) < 0)
    8000301a:	0207c663          	bltz	a5,80003046 <sys_waitpid+0x46>
  if(argaddr(1, &p) < 0)
    8000301e:	fe040593          	addi	a1,s0,-32
    80003022:	4505                	li	a0,1
    80003024:	00000097          	auipc	ra,0x0
    80003028:	c9a080e7          	jalr	-870(ra) # 80002cbe <argaddr>
    8000302c:	02054863          	bltz	a0,8000305c <sys_waitpid+0x5c>
    return -1;
  // printf("%d\n", p);
  if(pid == -1)
    80003030:	fe843503          	ld	a0,-24(s0)
    80003034:	57fd                	li	a5,-1
    80003036:	00f50c63          	beq	a0,a5,8000304e <sys_waitpid+0x4e>
    return wait(p);
  return waitpid(pid, p);
    8000303a:	fe043583          	ld	a1,-32(s0)
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	550080e7          	jalr	1360(ra) # 8000258e <waitpid>
}
    80003046:	60e2                	ld	ra,24(sp)
    80003048:	6442                	ld	s0,16(sp)
    8000304a:	6105                	addi	sp,sp,32
    8000304c:	8082                	ret
    return wait(p);
    8000304e:	fe043503          	ld	a0,-32(s0)
    80003052:	fffff097          	auipc	ra,0xfffff
    80003056:	094080e7          	jalr	148(ra) # 800020e6 <wait>
    8000305a:	b7f5                	j	80003046 <sys_waitpid+0x46>
    return -1;
    8000305c:	557d                	li	a0,-1
    8000305e:	b7e5                	j	80003046 <sys_waitpid+0x46>

0000000080003060 <sys_ps>:

uint64
sys_ps(void){
    80003060:	1141                	addi	sp,sp,-16
    80003062:	e406                	sd	ra,8(sp)
    80003064:	e022                	sd	s0,0(sp)
    80003066:	0800                	addi	s0,sp,16
  ps();
    80003068:	fffff097          	auipc	ra,0xfffff
    8000306c:	65a080e7          	jalr	1626(ra) # 800026c2 <ps>
  return 0;
    80003070:	4501                	li	a0,0
    80003072:	60a2                	ld	ra,8(sp)
    80003074:	6402                	ld	s0,0(sp)
    80003076:	0141                	addi	sp,sp,16
    80003078:	8082                	ret

000000008000307a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000307a:	7179                	addi	sp,sp,-48
    8000307c:	f406                	sd	ra,40(sp)
    8000307e:	f022                	sd	s0,32(sp)
    80003080:	ec26                	sd	s1,24(sp)
    80003082:	e84a                	sd	s2,16(sp)
    80003084:	e44e                	sd	s3,8(sp)
    80003086:	e052                	sd	s4,0(sp)
    80003088:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000308a:	00005597          	auipc	a1,0x5
    8000308e:	55658593          	addi	a1,a1,1366 # 800085e0 <syscalls+0xd8>
    80003092:	00014517          	auipc	a0,0x14
    80003096:	65650513          	addi	a0,a0,1622 # 800176e8 <bcache>
    8000309a:	ffffe097          	auipc	ra,0xffffe
    8000309e:	aa6080e7          	jalr	-1370(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030a2:	0001c797          	auipc	a5,0x1c
    800030a6:	64678793          	addi	a5,a5,1606 # 8001f6e8 <bcache+0x8000>
    800030aa:	0001d717          	auipc	a4,0x1d
    800030ae:	8a670713          	addi	a4,a4,-1882 # 8001f950 <bcache+0x8268>
    800030b2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030b6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030ba:	00014497          	auipc	s1,0x14
    800030be:	64648493          	addi	s1,s1,1606 # 80017700 <bcache+0x18>
    b->next = bcache.head.next;
    800030c2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030c4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030c6:	00005a17          	auipc	s4,0x5
    800030ca:	522a0a13          	addi	s4,s4,1314 # 800085e8 <syscalls+0xe0>
    b->next = bcache.head.next;
    800030ce:	2b893783          	ld	a5,696(s2)
    800030d2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030d4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030d8:	85d2                	mv	a1,s4
    800030da:	01048513          	addi	a0,s1,16
    800030de:	00001097          	auipc	ra,0x1
    800030e2:	4c2080e7          	jalr	1218(ra) # 800045a0 <initsleeplock>
    bcache.head.next->prev = b;
    800030e6:	2b893783          	ld	a5,696(s2)
    800030ea:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030ec:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030f0:	45848493          	addi	s1,s1,1112
    800030f4:	fd349de3          	bne	s1,s3,800030ce <binit+0x54>
  }
}
    800030f8:	70a2                	ld	ra,40(sp)
    800030fa:	7402                	ld	s0,32(sp)
    800030fc:	64e2                	ld	s1,24(sp)
    800030fe:	6942                	ld	s2,16(sp)
    80003100:	69a2                	ld	s3,8(sp)
    80003102:	6a02                	ld	s4,0(sp)
    80003104:	6145                	addi	sp,sp,48
    80003106:	8082                	ret

0000000080003108 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003108:	7179                	addi	sp,sp,-48
    8000310a:	f406                	sd	ra,40(sp)
    8000310c:	f022                	sd	s0,32(sp)
    8000310e:	ec26                	sd	s1,24(sp)
    80003110:	e84a                	sd	s2,16(sp)
    80003112:	e44e                	sd	s3,8(sp)
    80003114:	1800                	addi	s0,sp,48
    80003116:	892a                	mv	s2,a0
    80003118:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000311a:	00014517          	auipc	a0,0x14
    8000311e:	5ce50513          	addi	a0,a0,1486 # 800176e8 <bcache>
    80003122:	ffffe097          	auipc	ra,0xffffe
    80003126:	aae080e7          	jalr	-1362(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000312a:	0001d497          	auipc	s1,0x1d
    8000312e:	8764b483          	ld	s1,-1930(s1) # 8001f9a0 <bcache+0x82b8>
    80003132:	0001d797          	auipc	a5,0x1d
    80003136:	81e78793          	addi	a5,a5,-2018 # 8001f950 <bcache+0x8268>
    8000313a:	02f48f63          	beq	s1,a5,80003178 <bread+0x70>
    8000313e:	873e                	mv	a4,a5
    80003140:	a021                	j	80003148 <bread+0x40>
    80003142:	68a4                	ld	s1,80(s1)
    80003144:	02e48a63          	beq	s1,a4,80003178 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003148:	449c                	lw	a5,8(s1)
    8000314a:	ff279ce3          	bne	a5,s2,80003142 <bread+0x3a>
    8000314e:	44dc                	lw	a5,12(s1)
    80003150:	ff3799e3          	bne	a5,s3,80003142 <bread+0x3a>
      b->refcnt++;
    80003154:	40bc                	lw	a5,64(s1)
    80003156:	2785                	addiw	a5,a5,1
    80003158:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000315a:	00014517          	auipc	a0,0x14
    8000315e:	58e50513          	addi	a0,a0,1422 # 800176e8 <bcache>
    80003162:	ffffe097          	auipc	ra,0xffffe
    80003166:	b22080e7          	jalr	-1246(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    8000316a:	01048513          	addi	a0,s1,16
    8000316e:	00001097          	auipc	ra,0x1
    80003172:	46c080e7          	jalr	1132(ra) # 800045da <acquiresleep>
      return b;
    80003176:	a8b9                	j	800031d4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003178:	0001d497          	auipc	s1,0x1d
    8000317c:	8204b483          	ld	s1,-2016(s1) # 8001f998 <bcache+0x82b0>
    80003180:	0001c797          	auipc	a5,0x1c
    80003184:	7d078793          	addi	a5,a5,2000 # 8001f950 <bcache+0x8268>
    80003188:	00f48863          	beq	s1,a5,80003198 <bread+0x90>
    8000318c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000318e:	40bc                	lw	a5,64(s1)
    80003190:	cf81                	beqz	a5,800031a8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003192:	64a4                	ld	s1,72(s1)
    80003194:	fee49de3          	bne	s1,a4,8000318e <bread+0x86>
  panic("bget: no buffers");
    80003198:	00005517          	auipc	a0,0x5
    8000319c:	45850513          	addi	a0,a0,1112 # 800085f0 <syscalls+0xe8>
    800031a0:	ffffd097          	auipc	ra,0xffffd
    800031a4:	39a080e7          	jalr	922(ra) # 8000053a <panic>
      b->dev = dev;
    800031a8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800031ac:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031b0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031b4:	4785                	li	a5,1
    800031b6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031b8:	00014517          	auipc	a0,0x14
    800031bc:	53050513          	addi	a0,a0,1328 # 800176e8 <bcache>
    800031c0:	ffffe097          	auipc	ra,0xffffe
    800031c4:	ac4080e7          	jalr	-1340(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    800031c8:	01048513          	addi	a0,s1,16
    800031cc:	00001097          	auipc	ra,0x1
    800031d0:	40e080e7          	jalr	1038(ra) # 800045da <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031d4:	409c                	lw	a5,0(s1)
    800031d6:	cb89                	beqz	a5,800031e8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031d8:	8526                	mv	a0,s1
    800031da:	70a2                	ld	ra,40(sp)
    800031dc:	7402                	ld	s0,32(sp)
    800031de:	64e2                	ld	s1,24(sp)
    800031e0:	6942                	ld	s2,16(sp)
    800031e2:	69a2                	ld	s3,8(sp)
    800031e4:	6145                	addi	sp,sp,48
    800031e6:	8082                	ret
    virtio_disk_rw(b, 0);
    800031e8:	4581                	li	a1,0
    800031ea:	8526                	mv	a0,s1
    800031ec:	00003097          	auipc	ra,0x3
    800031f0:	f26080e7          	jalr	-218(ra) # 80006112 <virtio_disk_rw>
    b->valid = 1;
    800031f4:	4785                	li	a5,1
    800031f6:	c09c                	sw	a5,0(s1)
  return b;
    800031f8:	b7c5                	j	800031d8 <bread+0xd0>

00000000800031fa <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031fa:	1101                	addi	sp,sp,-32
    800031fc:	ec06                	sd	ra,24(sp)
    800031fe:	e822                	sd	s0,16(sp)
    80003200:	e426                	sd	s1,8(sp)
    80003202:	1000                	addi	s0,sp,32
    80003204:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003206:	0541                	addi	a0,a0,16
    80003208:	00001097          	auipc	ra,0x1
    8000320c:	46c080e7          	jalr	1132(ra) # 80004674 <holdingsleep>
    80003210:	cd01                	beqz	a0,80003228 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003212:	4585                	li	a1,1
    80003214:	8526                	mv	a0,s1
    80003216:	00003097          	auipc	ra,0x3
    8000321a:	efc080e7          	jalr	-260(ra) # 80006112 <virtio_disk_rw>
}
    8000321e:	60e2                	ld	ra,24(sp)
    80003220:	6442                	ld	s0,16(sp)
    80003222:	64a2                	ld	s1,8(sp)
    80003224:	6105                	addi	sp,sp,32
    80003226:	8082                	ret
    panic("bwrite");
    80003228:	00005517          	auipc	a0,0x5
    8000322c:	3e050513          	addi	a0,a0,992 # 80008608 <syscalls+0x100>
    80003230:	ffffd097          	auipc	ra,0xffffd
    80003234:	30a080e7          	jalr	778(ra) # 8000053a <panic>

0000000080003238 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003238:	1101                	addi	sp,sp,-32
    8000323a:	ec06                	sd	ra,24(sp)
    8000323c:	e822                	sd	s0,16(sp)
    8000323e:	e426                	sd	s1,8(sp)
    80003240:	e04a                	sd	s2,0(sp)
    80003242:	1000                	addi	s0,sp,32
    80003244:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003246:	01050913          	addi	s2,a0,16
    8000324a:	854a                	mv	a0,s2
    8000324c:	00001097          	auipc	ra,0x1
    80003250:	428080e7          	jalr	1064(ra) # 80004674 <holdingsleep>
    80003254:	c92d                	beqz	a0,800032c6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003256:	854a                	mv	a0,s2
    80003258:	00001097          	auipc	ra,0x1
    8000325c:	3d8080e7          	jalr	984(ra) # 80004630 <releasesleep>

  acquire(&bcache.lock);
    80003260:	00014517          	auipc	a0,0x14
    80003264:	48850513          	addi	a0,a0,1160 # 800176e8 <bcache>
    80003268:	ffffe097          	auipc	ra,0xffffe
    8000326c:	968080e7          	jalr	-1688(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003270:	40bc                	lw	a5,64(s1)
    80003272:	37fd                	addiw	a5,a5,-1
    80003274:	0007871b          	sext.w	a4,a5
    80003278:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000327a:	eb05                	bnez	a4,800032aa <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000327c:	68bc                	ld	a5,80(s1)
    8000327e:	64b8                	ld	a4,72(s1)
    80003280:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003282:	64bc                	ld	a5,72(s1)
    80003284:	68b8                	ld	a4,80(s1)
    80003286:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003288:	0001c797          	auipc	a5,0x1c
    8000328c:	46078793          	addi	a5,a5,1120 # 8001f6e8 <bcache+0x8000>
    80003290:	2b87b703          	ld	a4,696(a5)
    80003294:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003296:	0001c717          	auipc	a4,0x1c
    8000329a:	6ba70713          	addi	a4,a4,1722 # 8001f950 <bcache+0x8268>
    8000329e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032a0:	2b87b703          	ld	a4,696(a5)
    800032a4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032a6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032aa:	00014517          	auipc	a0,0x14
    800032ae:	43e50513          	addi	a0,a0,1086 # 800176e8 <bcache>
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	9d2080e7          	jalr	-1582(ra) # 80000c84 <release>
}
    800032ba:	60e2                	ld	ra,24(sp)
    800032bc:	6442                	ld	s0,16(sp)
    800032be:	64a2                	ld	s1,8(sp)
    800032c0:	6902                	ld	s2,0(sp)
    800032c2:	6105                	addi	sp,sp,32
    800032c4:	8082                	ret
    panic("brelse");
    800032c6:	00005517          	auipc	a0,0x5
    800032ca:	34a50513          	addi	a0,a0,842 # 80008610 <syscalls+0x108>
    800032ce:	ffffd097          	auipc	ra,0xffffd
    800032d2:	26c080e7          	jalr	620(ra) # 8000053a <panic>

00000000800032d6 <bpin>:

void
bpin(struct buf *b) {
    800032d6:	1101                	addi	sp,sp,-32
    800032d8:	ec06                	sd	ra,24(sp)
    800032da:	e822                	sd	s0,16(sp)
    800032dc:	e426                	sd	s1,8(sp)
    800032de:	1000                	addi	s0,sp,32
    800032e0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032e2:	00014517          	auipc	a0,0x14
    800032e6:	40650513          	addi	a0,a0,1030 # 800176e8 <bcache>
    800032ea:	ffffe097          	auipc	ra,0xffffe
    800032ee:	8e6080e7          	jalr	-1818(ra) # 80000bd0 <acquire>
  b->refcnt++;
    800032f2:	40bc                	lw	a5,64(s1)
    800032f4:	2785                	addiw	a5,a5,1
    800032f6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032f8:	00014517          	auipc	a0,0x14
    800032fc:	3f050513          	addi	a0,a0,1008 # 800176e8 <bcache>
    80003300:	ffffe097          	auipc	ra,0xffffe
    80003304:	984080e7          	jalr	-1660(ra) # 80000c84 <release>
}
    80003308:	60e2                	ld	ra,24(sp)
    8000330a:	6442                	ld	s0,16(sp)
    8000330c:	64a2                	ld	s1,8(sp)
    8000330e:	6105                	addi	sp,sp,32
    80003310:	8082                	ret

0000000080003312 <bunpin>:

void
bunpin(struct buf *b) {
    80003312:	1101                	addi	sp,sp,-32
    80003314:	ec06                	sd	ra,24(sp)
    80003316:	e822                	sd	s0,16(sp)
    80003318:	e426                	sd	s1,8(sp)
    8000331a:	1000                	addi	s0,sp,32
    8000331c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000331e:	00014517          	auipc	a0,0x14
    80003322:	3ca50513          	addi	a0,a0,970 # 800176e8 <bcache>
    80003326:	ffffe097          	auipc	ra,0xffffe
    8000332a:	8aa080e7          	jalr	-1878(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000332e:	40bc                	lw	a5,64(s1)
    80003330:	37fd                	addiw	a5,a5,-1
    80003332:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003334:	00014517          	auipc	a0,0x14
    80003338:	3b450513          	addi	a0,a0,948 # 800176e8 <bcache>
    8000333c:	ffffe097          	auipc	ra,0xffffe
    80003340:	948080e7          	jalr	-1720(ra) # 80000c84 <release>
}
    80003344:	60e2                	ld	ra,24(sp)
    80003346:	6442                	ld	s0,16(sp)
    80003348:	64a2                	ld	s1,8(sp)
    8000334a:	6105                	addi	sp,sp,32
    8000334c:	8082                	ret

000000008000334e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000334e:	1101                	addi	sp,sp,-32
    80003350:	ec06                	sd	ra,24(sp)
    80003352:	e822                	sd	s0,16(sp)
    80003354:	e426                	sd	s1,8(sp)
    80003356:	e04a                	sd	s2,0(sp)
    80003358:	1000                	addi	s0,sp,32
    8000335a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000335c:	00d5d59b          	srliw	a1,a1,0xd
    80003360:	0001d797          	auipc	a5,0x1d
    80003364:	a647a783          	lw	a5,-1436(a5) # 8001fdc4 <sb+0x1c>
    80003368:	9dbd                	addw	a1,a1,a5
    8000336a:	00000097          	auipc	ra,0x0
    8000336e:	d9e080e7          	jalr	-610(ra) # 80003108 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003372:	0074f713          	andi	a4,s1,7
    80003376:	4785                	li	a5,1
    80003378:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000337c:	14ce                	slli	s1,s1,0x33
    8000337e:	90d9                	srli	s1,s1,0x36
    80003380:	00950733          	add	a4,a0,s1
    80003384:	05874703          	lbu	a4,88(a4)
    80003388:	00e7f6b3          	and	a3,a5,a4
    8000338c:	c69d                	beqz	a3,800033ba <bfree+0x6c>
    8000338e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003390:	94aa                	add	s1,s1,a0
    80003392:	fff7c793          	not	a5,a5
    80003396:	8f7d                	and	a4,a4,a5
    80003398:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000339c:	00001097          	auipc	ra,0x1
    800033a0:	120080e7          	jalr	288(ra) # 800044bc <log_write>
  brelse(bp);
    800033a4:	854a                	mv	a0,s2
    800033a6:	00000097          	auipc	ra,0x0
    800033aa:	e92080e7          	jalr	-366(ra) # 80003238 <brelse>
}
    800033ae:	60e2                	ld	ra,24(sp)
    800033b0:	6442                	ld	s0,16(sp)
    800033b2:	64a2                	ld	s1,8(sp)
    800033b4:	6902                	ld	s2,0(sp)
    800033b6:	6105                	addi	sp,sp,32
    800033b8:	8082                	ret
    panic("freeing free block");
    800033ba:	00005517          	auipc	a0,0x5
    800033be:	25e50513          	addi	a0,a0,606 # 80008618 <syscalls+0x110>
    800033c2:	ffffd097          	auipc	ra,0xffffd
    800033c6:	178080e7          	jalr	376(ra) # 8000053a <panic>

00000000800033ca <balloc>:
{
    800033ca:	711d                	addi	sp,sp,-96
    800033cc:	ec86                	sd	ra,88(sp)
    800033ce:	e8a2                	sd	s0,80(sp)
    800033d0:	e4a6                	sd	s1,72(sp)
    800033d2:	e0ca                	sd	s2,64(sp)
    800033d4:	fc4e                	sd	s3,56(sp)
    800033d6:	f852                	sd	s4,48(sp)
    800033d8:	f456                	sd	s5,40(sp)
    800033da:	f05a                	sd	s6,32(sp)
    800033dc:	ec5e                	sd	s7,24(sp)
    800033de:	e862                	sd	s8,16(sp)
    800033e0:	e466                	sd	s9,8(sp)
    800033e2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033e4:	0001d797          	auipc	a5,0x1d
    800033e8:	9c87a783          	lw	a5,-1592(a5) # 8001fdac <sb+0x4>
    800033ec:	cbc1                	beqz	a5,8000347c <balloc+0xb2>
    800033ee:	8baa                	mv	s7,a0
    800033f0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033f2:	0001db17          	auipc	s6,0x1d
    800033f6:	9b6b0b13          	addi	s6,s6,-1610 # 8001fda8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033fa:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033fc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033fe:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003400:	6c89                	lui	s9,0x2
    80003402:	a831                	j	8000341e <balloc+0x54>
    brelse(bp);
    80003404:	854a                	mv	a0,s2
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	e32080e7          	jalr	-462(ra) # 80003238 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000340e:	015c87bb          	addw	a5,s9,s5
    80003412:	00078a9b          	sext.w	s5,a5
    80003416:	004b2703          	lw	a4,4(s6)
    8000341a:	06eaf163          	bgeu	s5,a4,8000347c <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000341e:	41fad79b          	sraiw	a5,s5,0x1f
    80003422:	0137d79b          	srliw	a5,a5,0x13
    80003426:	015787bb          	addw	a5,a5,s5
    8000342a:	40d7d79b          	sraiw	a5,a5,0xd
    8000342e:	01cb2583          	lw	a1,28(s6)
    80003432:	9dbd                	addw	a1,a1,a5
    80003434:	855e                	mv	a0,s7
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	cd2080e7          	jalr	-814(ra) # 80003108 <bread>
    8000343e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003440:	004b2503          	lw	a0,4(s6)
    80003444:	000a849b          	sext.w	s1,s5
    80003448:	8762                	mv	a4,s8
    8000344a:	faa4fde3          	bgeu	s1,a0,80003404 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000344e:	00777693          	andi	a3,a4,7
    80003452:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003456:	41f7579b          	sraiw	a5,a4,0x1f
    8000345a:	01d7d79b          	srliw	a5,a5,0x1d
    8000345e:	9fb9                	addw	a5,a5,a4
    80003460:	4037d79b          	sraiw	a5,a5,0x3
    80003464:	00f90633          	add	a2,s2,a5
    80003468:	05864603          	lbu	a2,88(a2)
    8000346c:	00c6f5b3          	and	a1,a3,a2
    80003470:	cd91                	beqz	a1,8000348c <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003472:	2705                	addiw	a4,a4,1
    80003474:	2485                	addiw	s1,s1,1
    80003476:	fd471ae3          	bne	a4,s4,8000344a <balloc+0x80>
    8000347a:	b769                	j	80003404 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000347c:	00005517          	auipc	a0,0x5
    80003480:	1b450513          	addi	a0,a0,436 # 80008630 <syscalls+0x128>
    80003484:	ffffd097          	auipc	ra,0xffffd
    80003488:	0b6080e7          	jalr	182(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000348c:	97ca                	add	a5,a5,s2
    8000348e:	8e55                	or	a2,a2,a3
    80003490:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003494:	854a                	mv	a0,s2
    80003496:	00001097          	auipc	ra,0x1
    8000349a:	026080e7          	jalr	38(ra) # 800044bc <log_write>
        brelse(bp);
    8000349e:	854a                	mv	a0,s2
    800034a0:	00000097          	auipc	ra,0x0
    800034a4:	d98080e7          	jalr	-616(ra) # 80003238 <brelse>
  bp = bread(dev, bno);
    800034a8:	85a6                	mv	a1,s1
    800034aa:	855e                	mv	a0,s7
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	c5c080e7          	jalr	-932(ra) # 80003108 <bread>
    800034b4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034b6:	40000613          	li	a2,1024
    800034ba:	4581                	li	a1,0
    800034bc:	05850513          	addi	a0,a0,88
    800034c0:	ffffe097          	auipc	ra,0xffffe
    800034c4:	80c080e7          	jalr	-2036(ra) # 80000ccc <memset>
  log_write(bp);
    800034c8:	854a                	mv	a0,s2
    800034ca:	00001097          	auipc	ra,0x1
    800034ce:	ff2080e7          	jalr	-14(ra) # 800044bc <log_write>
  brelse(bp);
    800034d2:	854a                	mv	a0,s2
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	d64080e7          	jalr	-668(ra) # 80003238 <brelse>
}
    800034dc:	8526                	mv	a0,s1
    800034de:	60e6                	ld	ra,88(sp)
    800034e0:	6446                	ld	s0,80(sp)
    800034e2:	64a6                	ld	s1,72(sp)
    800034e4:	6906                	ld	s2,64(sp)
    800034e6:	79e2                	ld	s3,56(sp)
    800034e8:	7a42                	ld	s4,48(sp)
    800034ea:	7aa2                	ld	s5,40(sp)
    800034ec:	7b02                	ld	s6,32(sp)
    800034ee:	6be2                	ld	s7,24(sp)
    800034f0:	6c42                	ld	s8,16(sp)
    800034f2:	6ca2                	ld	s9,8(sp)
    800034f4:	6125                	addi	sp,sp,96
    800034f6:	8082                	ret

00000000800034f8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034f8:	7179                	addi	sp,sp,-48
    800034fa:	f406                	sd	ra,40(sp)
    800034fc:	f022                	sd	s0,32(sp)
    800034fe:	ec26                	sd	s1,24(sp)
    80003500:	e84a                	sd	s2,16(sp)
    80003502:	e44e                	sd	s3,8(sp)
    80003504:	e052                	sd	s4,0(sp)
    80003506:	1800                	addi	s0,sp,48
    80003508:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000350a:	47ad                	li	a5,11
    8000350c:	04b7fe63          	bgeu	a5,a1,80003568 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003510:	ff45849b          	addiw	s1,a1,-12
    80003514:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003518:	0ff00793          	li	a5,255
    8000351c:	0ae7e463          	bltu	a5,a4,800035c4 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003520:	08052583          	lw	a1,128(a0)
    80003524:	c5b5                	beqz	a1,80003590 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003526:	00092503          	lw	a0,0(s2)
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	bde080e7          	jalr	-1058(ra) # 80003108 <bread>
    80003532:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003534:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003538:	02049713          	slli	a4,s1,0x20
    8000353c:	01e75593          	srli	a1,a4,0x1e
    80003540:	00b784b3          	add	s1,a5,a1
    80003544:	0004a983          	lw	s3,0(s1)
    80003548:	04098e63          	beqz	s3,800035a4 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000354c:	8552                	mv	a0,s4
    8000354e:	00000097          	auipc	ra,0x0
    80003552:	cea080e7          	jalr	-790(ra) # 80003238 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003556:	854e                	mv	a0,s3
    80003558:	70a2                	ld	ra,40(sp)
    8000355a:	7402                	ld	s0,32(sp)
    8000355c:	64e2                	ld	s1,24(sp)
    8000355e:	6942                	ld	s2,16(sp)
    80003560:	69a2                	ld	s3,8(sp)
    80003562:	6a02                	ld	s4,0(sp)
    80003564:	6145                	addi	sp,sp,48
    80003566:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003568:	02059793          	slli	a5,a1,0x20
    8000356c:	01e7d593          	srli	a1,a5,0x1e
    80003570:	00b504b3          	add	s1,a0,a1
    80003574:	0504a983          	lw	s3,80(s1)
    80003578:	fc099fe3          	bnez	s3,80003556 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000357c:	4108                	lw	a0,0(a0)
    8000357e:	00000097          	auipc	ra,0x0
    80003582:	e4c080e7          	jalr	-436(ra) # 800033ca <balloc>
    80003586:	0005099b          	sext.w	s3,a0
    8000358a:	0534a823          	sw	s3,80(s1)
    8000358e:	b7e1                	j	80003556 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003590:	4108                	lw	a0,0(a0)
    80003592:	00000097          	auipc	ra,0x0
    80003596:	e38080e7          	jalr	-456(ra) # 800033ca <balloc>
    8000359a:	0005059b          	sext.w	a1,a0
    8000359e:	08b92023          	sw	a1,128(s2)
    800035a2:	b751                	j	80003526 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035a4:	00092503          	lw	a0,0(s2)
    800035a8:	00000097          	auipc	ra,0x0
    800035ac:	e22080e7          	jalr	-478(ra) # 800033ca <balloc>
    800035b0:	0005099b          	sext.w	s3,a0
    800035b4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035b8:	8552                	mv	a0,s4
    800035ba:	00001097          	auipc	ra,0x1
    800035be:	f02080e7          	jalr	-254(ra) # 800044bc <log_write>
    800035c2:	b769                	j	8000354c <bmap+0x54>
  panic("bmap: out of range");
    800035c4:	00005517          	auipc	a0,0x5
    800035c8:	08450513          	addi	a0,a0,132 # 80008648 <syscalls+0x140>
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	f6e080e7          	jalr	-146(ra) # 8000053a <panic>

00000000800035d4 <iget>:
{
    800035d4:	7179                	addi	sp,sp,-48
    800035d6:	f406                	sd	ra,40(sp)
    800035d8:	f022                	sd	s0,32(sp)
    800035da:	ec26                	sd	s1,24(sp)
    800035dc:	e84a                	sd	s2,16(sp)
    800035de:	e44e                	sd	s3,8(sp)
    800035e0:	e052                	sd	s4,0(sp)
    800035e2:	1800                	addi	s0,sp,48
    800035e4:	89aa                	mv	s3,a0
    800035e6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035e8:	0001c517          	auipc	a0,0x1c
    800035ec:	7e050513          	addi	a0,a0,2016 # 8001fdc8 <itable>
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	5e0080e7          	jalr	1504(ra) # 80000bd0 <acquire>
  empty = 0;
    800035f8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035fa:	0001c497          	auipc	s1,0x1c
    800035fe:	7e648493          	addi	s1,s1,2022 # 8001fde0 <itable+0x18>
    80003602:	0001e697          	auipc	a3,0x1e
    80003606:	26e68693          	addi	a3,a3,622 # 80021870 <log>
    8000360a:	a039                	j	80003618 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000360c:	02090b63          	beqz	s2,80003642 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003610:	08848493          	addi	s1,s1,136
    80003614:	02d48a63          	beq	s1,a3,80003648 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003618:	449c                	lw	a5,8(s1)
    8000361a:	fef059e3          	blez	a5,8000360c <iget+0x38>
    8000361e:	4098                	lw	a4,0(s1)
    80003620:	ff3716e3          	bne	a4,s3,8000360c <iget+0x38>
    80003624:	40d8                	lw	a4,4(s1)
    80003626:	ff4713e3          	bne	a4,s4,8000360c <iget+0x38>
      ip->ref++;
    8000362a:	2785                	addiw	a5,a5,1
    8000362c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000362e:	0001c517          	auipc	a0,0x1c
    80003632:	79a50513          	addi	a0,a0,1946 # 8001fdc8 <itable>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	64e080e7          	jalr	1614(ra) # 80000c84 <release>
      return ip;
    8000363e:	8926                	mv	s2,s1
    80003640:	a03d                	j	8000366e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003642:	f7f9                	bnez	a5,80003610 <iget+0x3c>
    80003644:	8926                	mv	s2,s1
    80003646:	b7e9                	j	80003610 <iget+0x3c>
  if(empty == 0)
    80003648:	02090c63          	beqz	s2,80003680 <iget+0xac>
  ip->dev = dev;
    8000364c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003650:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003654:	4785                	li	a5,1
    80003656:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000365a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000365e:	0001c517          	auipc	a0,0x1c
    80003662:	76a50513          	addi	a0,a0,1898 # 8001fdc8 <itable>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	61e080e7          	jalr	1566(ra) # 80000c84 <release>
}
    8000366e:	854a                	mv	a0,s2
    80003670:	70a2                	ld	ra,40(sp)
    80003672:	7402                	ld	s0,32(sp)
    80003674:	64e2                	ld	s1,24(sp)
    80003676:	6942                	ld	s2,16(sp)
    80003678:	69a2                	ld	s3,8(sp)
    8000367a:	6a02                	ld	s4,0(sp)
    8000367c:	6145                	addi	sp,sp,48
    8000367e:	8082                	ret
    panic("iget: no inodes");
    80003680:	00005517          	auipc	a0,0x5
    80003684:	fe050513          	addi	a0,a0,-32 # 80008660 <syscalls+0x158>
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	eb2080e7          	jalr	-334(ra) # 8000053a <panic>

0000000080003690 <fsinit>:
fsinit(int dev) {
    80003690:	7179                	addi	sp,sp,-48
    80003692:	f406                	sd	ra,40(sp)
    80003694:	f022                	sd	s0,32(sp)
    80003696:	ec26                	sd	s1,24(sp)
    80003698:	e84a                	sd	s2,16(sp)
    8000369a:	e44e                	sd	s3,8(sp)
    8000369c:	1800                	addi	s0,sp,48
    8000369e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036a0:	4585                	li	a1,1
    800036a2:	00000097          	auipc	ra,0x0
    800036a6:	a66080e7          	jalr	-1434(ra) # 80003108 <bread>
    800036aa:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036ac:	0001c997          	auipc	s3,0x1c
    800036b0:	6fc98993          	addi	s3,s3,1788 # 8001fda8 <sb>
    800036b4:	02000613          	li	a2,32
    800036b8:	05850593          	addi	a1,a0,88
    800036bc:	854e                	mv	a0,s3
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	66a080e7          	jalr	1642(ra) # 80000d28 <memmove>
  brelse(bp);
    800036c6:	8526                	mv	a0,s1
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	b70080e7          	jalr	-1168(ra) # 80003238 <brelse>
  if(sb.magic != FSMAGIC)
    800036d0:	0009a703          	lw	a4,0(s3)
    800036d4:	102037b7          	lui	a5,0x10203
    800036d8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036dc:	02f71263          	bne	a4,a5,80003700 <fsinit+0x70>
  initlog(dev, &sb);
    800036e0:	0001c597          	auipc	a1,0x1c
    800036e4:	6c858593          	addi	a1,a1,1736 # 8001fda8 <sb>
    800036e8:	854a                	mv	a0,s2
    800036ea:	00001097          	auipc	ra,0x1
    800036ee:	b56080e7          	jalr	-1194(ra) # 80004240 <initlog>
}
    800036f2:	70a2                	ld	ra,40(sp)
    800036f4:	7402                	ld	s0,32(sp)
    800036f6:	64e2                	ld	s1,24(sp)
    800036f8:	6942                	ld	s2,16(sp)
    800036fa:	69a2                	ld	s3,8(sp)
    800036fc:	6145                	addi	sp,sp,48
    800036fe:	8082                	ret
    panic("invalid file system");
    80003700:	00005517          	auipc	a0,0x5
    80003704:	f7050513          	addi	a0,a0,-144 # 80008670 <syscalls+0x168>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	e32080e7          	jalr	-462(ra) # 8000053a <panic>

0000000080003710 <iinit>:
{
    80003710:	7179                	addi	sp,sp,-48
    80003712:	f406                	sd	ra,40(sp)
    80003714:	f022                	sd	s0,32(sp)
    80003716:	ec26                	sd	s1,24(sp)
    80003718:	e84a                	sd	s2,16(sp)
    8000371a:	e44e                	sd	s3,8(sp)
    8000371c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000371e:	00005597          	auipc	a1,0x5
    80003722:	f6a58593          	addi	a1,a1,-150 # 80008688 <syscalls+0x180>
    80003726:	0001c517          	auipc	a0,0x1c
    8000372a:	6a250513          	addi	a0,a0,1698 # 8001fdc8 <itable>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	412080e7          	jalr	1042(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003736:	0001c497          	auipc	s1,0x1c
    8000373a:	6ba48493          	addi	s1,s1,1722 # 8001fdf0 <itable+0x28>
    8000373e:	0001e997          	auipc	s3,0x1e
    80003742:	14298993          	addi	s3,s3,322 # 80021880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003746:	00005917          	auipc	s2,0x5
    8000374a:	f4a90913          	addi	s2,s2,-182 # 80008690 <syscalls+0x188>
    8000374e:	85ca                	mv	a1,s2
    80003750:	8526                	mv	a0,s1
    80003752:	00001097          	auipc	ra,0x1
    80003756:	e4e080e7          	jalr	-434(ra) # 800045a0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000375a:	08848493          	addi	s1,s1,136
    8000375e:	ff3498e3          	bne	s1,s3,8000374e <iinit+0x3e>
}
    80003762:	70a2                	ld	ra,40(sp)
    80003764:	7402                	ld	s0,32(sp)
    80003766:	64e2                	ld	s1,24(sp)
    80003768:	6942                	ld	s2,16(sp)
    8000376a:	69a2                	ld	s3,8(sp)
    8000376c:	6145                	addi	sp,sp,48
    8000376e:	8082                	ret

0000000080003770 <ialloc>:
{
    80003770:	715d                	addi	sp,sp,-80
    80003772:	e486                	sd	ra,72(sp)
    80003774:	e0a2                	sd	s0,64(sp)
    80003776:	fc26                	sd	s1,56(sp)
    80003778:	f84a                	sd	s2,48(sp)
    8000377a:	f44e                	sd	s3,40(sp)
    8000377c:	f052                	sd	s4,32(sp)
    8000377e:	ec56                	sd	s5,24(sp)
    80003780:	e85a                	sd	s6,16(sp)
    80003782:	e45e                	sd	s7,8(sp)
    80003784:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003786:	0001c717          	auipc	a4,0x1c
    8000378a:	62e72703          	lw	a4,1582(a4) # 8001fdb4 <sb+0xc>
    8000378e:	4785                	li	a5,1
    80003790:	04e7fa63          	bgeu	a5,a4,800037e4 <ialloc+0x74>
    80003794:	8aaa                	mv	s5,a0
    80003796:	8bae                	mv	s7,a1
    80003798:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000379a:	0001ca17          	auipc	s4,0x1c
    8000379e:	60ea0a13          	addi	s4,s4,1550 # 8001fda8 <sb>
    800037a2:	00048b1b          	sext.w	s6,s1
    800037a6:	0044d593          	srli	a1,s1,0x4
    800037aa:	018a2783          	lw	a5,24(s4)
    800037ae:	9dbd                	addw	a1,a1,a5
    800037b0:	8556                	mv	a0,s5
    800037b2:	00000097          	auipc	ra,0x0
    800037b6:	956080e7          	jalr	-1706(ra) # 80003108 <bread>
    800037ba:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037bc:	05850993          	addi	s3,a0,88
    800037c0:	00f4f793          	andi	a5,s1,15
    800037c4:	079a                	slli	a5,a5,0x6
    800037c6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037c8:	00099783          	lh	a5,0(s3)
    800037cc:	c785                	beqz	a5,800037f4 <ialloc+0x84>
    brelse(bp);
    800037ce:	00000097          	auipc	ra,0x0
    800037d2:	a6a080e7          	jalr	-1430(ra) # 80003238 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037d6:	0485                	addi	s1,s1,1
    800037d8:	00ca2703          	lw	a4,12(s4)
    800037dc:	0004879b          	sext.w	a5,s1
    800037e0:	fce7e1e3          	bltu	a5,a4,800037a2 <ialloc+0x32>
  panic("ialloc: no inodes");
    800037e4:	00005517          	auipc	a0,0x5
    800037e8:	eb450513          	addi	a0,a0,-332 # 80008698 <syscalls+0x190>
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	d4e080e7          	jalr	-690(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    800037f4:	04000613          	li	a2,64
    800037f8:	4581                	li	a1,0
    800037fa:	854e                	mv	a0,s3
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	4d0080e7          	jalr	1232(ra) # 80000ccc <memset>
      dip->type = type;
    80003804:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003808:	854a                	mv	a0,s2
    8000380a:	00001097          	auipc	ra,0x1
    8000380e:	cb2080e7          	jalr	-846(ra) # 800044bc <log_write>
      brelse(bp);
    80003812:	854a                	mv	a0,s2
    80003814:	00000097          	auipc	ra,0x0
    80003818:	a24080e7          	jalr	-1500(ra) # 80003238 <brelse>
      return iget(dev, inum);
    8000381c:	85da                	mv	a1,s6
    8000381e:	8556                	mv	a0,s5
    80003820:	00000097          	auipc	ra,0x0
    80003824:	db4080e7          	jalr	-588(ra) # 800035d4 <iget>
}
    80003828:	60a6                	ld	ra,72(sp)
    8000382a:	6406                	ld	s0,64(sp)
    8000382c:	74e2                	ld	s1,56(sp)
    8000382e:	7942                	ld	s2,48(sp)
    80003830:	79a2                	ld	s3,40(sp)
    80003832:	7a02                	ld	s4,32(sp)
    80003834:	6ae2                	ld	s5,24(sp)
    80003836:	6b42                	ld	s6,16(sp)
    80003838:	6ba2                	ld	s7,8(sp)
    8000383a:	6161                	addi	sp,sp,80
    8000383c:	8082                	ret

000000008000383e <iupdate>:
{
    8000383e:	1101                	addi	sp,sp,-32
    80003840:	ec06                	sd	ra,24(sp)
    80003842:	e822                	sd	s0,16(sp)
    80003844:	e426                	sd	s1,8(sp)
    80003846:	e04a                	sd	s2,0(sp)
    80003848:	1000                	addi	s0,sp,32
    8000384a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000384c:	415c                	lw	a5,4(a0)
    8000384e:	0047d79b          	srliw	a5,a5,0x4
    80003852:	0001c597          	auipc	a1,0x1c
    80003856:	56e5a583          	lw	a1,1390(a1) # 8001fdc0 <sb+0x18>
    8000385a:	9dbd                	addw	a1,a1,a5
    8000385c:	4108                	lw	a0,0(a0)
    8000385e:	00000097          	auipc	ra,0x0
    80003862:	8aa080e7          	jalr	-1878(ra) # 80003108 <bread>
    80003866:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003868:	05850793          	addi	a5,a0,88
    8000386c:	40d8                	lw	a4,4(s1)
    8000386e:	8b3d                	andi	a4,a4,15
    80003870:	071a                	slli	a4,a4,0x6
    80003872:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003874:	04449703          	lh	a4,68(s1)
    80003878:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000387c:	04649703          	lh	a4,70(s1)
    80003880:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003884:	04849703          	lh	a4,72(s1)
    80003888:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000388c:	04a49703          	lh	a4,74(s1)
    80003890:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003894:	44f8                	lw	a4,76(s1)
    80003896:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003898:	03400613          	li	a2,52
    8000389c:	05048593          	addi	a1,s1,80
    800038a0:	00c78513          	addi	a0,a5,12
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	484080e7          	jalr	1156(ra) # 80000d28 <memmove>
  log_write(bp);
    800038ac:	854a                	mv	a0,s2
    800038ae:	00001097          	auipc	ra,0x1
    800038b2:	c0e080e7          	jalr	-1010(ra) # 800044bc <log_write>
  brelse(bp);
    800038b6:	854a                	mv	a0,s2
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	980080e7          	jalr	-1664(ra) # 80003238 <brelse>
}
    800038c0:	60e2                	ld	ra,24(sp)
    800038c2:	6442                	ld	s0,16(sp)
    800038c4:	64a2                	ld	s1,8(sp)
    800038c6:	6902                	ld	s2,0(sp)
    800038c8:	6105                	addi	sp,sp,32
    800038ca:	8082                	ret

00000000800038cc <idup>:
{
    800038cc:	1101                	addi	sp,sp,-32
    800038ce:	ec06                	sd	ra,24(sp)
    800038d0:	e822                	sd	s0,16(sp)
    800038d2:	e426                	sd	s1,8(sp)
    800038d4:	1000                	addi	s0,sp,32
    800038d6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038d8:	0001c517          	auipc	a0,0x1c
    800038dc:	4f050513          	addi	a0,a0,1264 # 8001fdc8 <itable>
    800038e0:	ffffd097          	auipc	ra,0xffffd
    800038e4:	2f0080e7          	jalr	752(ra) # 80000bd0 <acquire>
  ip->ref++;
    800038e8:	449c                	lw	a5,8(s1)
    800038ea:	2785                	addiw	a5,a5,1
    800038ec:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038ee:	0001c517          	auipc	a0,0x1c
    800038f2:	4da50513          	addi	a0,a0,1242 # 8001fdc8 <itable>
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	38e080e7          	jalr	910(ra) # 80000c84 <release>
}
    800038fe:	8526                	mv	a0,s1
    80003900:	60e2                	ld	ra,24(sp)
    80003902:	6442                	ld	s0,16(sp)
    80003904:	64a2                	ld	s1,8(sp)
    80003906:	6105                	addi	sp,sp,32
    80003908:	8082                	ret

000000008000390a <ilock>:
{
    8000390a:	1101                	addi	sp,sp,-32
    8000390c:	ec06                	sd	ra,24(sp)
    8000390e:	e822                	sd	s0,16(sp)
    80003910:	e426                	sd	s1,8(sp)
    80003912:	e04a                	sd	s2,0(sp)
    80003914:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003916:	c115                	beqz	a0,8000393a <ilock+0x30>
    80003918:	84aa                	mv	s1,a0
    8000391a:	451c                	lw	a5,8(a0)
    8000391c:	00f05f63          	blez	a5,8000393a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003920:	0541                	addi	a0,a0,16
    80003922:	00001097          	auipc	ra,0x1
    80003926:	cb8080e7          	jalr	-840(ra) # 800045da <acquiresleep>
  if(ip->valid == 0){
    8000392a:	40bc                	lw	a5,64(s1)
    8000392c:	cf99                	beqz	a5,8000394a <ilock+0x40>
}
    8000392e:	60e2                	ld	ra,24(sp)
    80003930:	6442                	ld	s0,16(sp)
    80003932:	64a2                	ld	s1,8(sp)
    80003934:	6902                	ld	s2,0(sp)
    80003936:	6105                	addi	sp,sp,32
    80003938:	8082                	ret
    panic("ilock");
    8000393a:	00005517          	auipc	a0,0x5
    8000393e:	d7650513          	addi	a0,a0,-650 # 800086b0 <syscalls+0x1a8>
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	bf8080e7          	jalr	-1032(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000394a:	40dc                	lw	a5,4(s1)
    8000394c:	0047d79b          	srliw	a5,a5,0x4
    80003950:	0001c597          	auipc	a1,0x1c
    80003954:	4705a583          	lw	a1,1136(a1) # 8001fdc0 <sb+0x18>
    80003958:	9dbd                	addw	a1,a1,a5
    8000395a:	4088                	lw	a0,0(s1)
    8000395c:	fffff097          	auipc	ra,0xfffff
    80003960:	7ac080e7          	jalr	1964(ra) # 80003108 <bread>
    80003964:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003966:	05850593          	addi	a1,a0,88
    8000396a:	40dc                	lw	a5,4(s1)
    8000396c:	8bbd                	andi	a5,a5,15
    8000396e:	079a                	slli	a5,a5,0x6
    80003970:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003972:	00059783          	lh	a5,0(a1)
    80003976:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000397a:	00259783          	lh	a5,2(a1)
    8000397e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003982:	00459783          	lh	a5,4(a1)
    80003986:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000398a:	00659783          	lh	a5,6(a1)
    8000398e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003992:	459c                	lw	a5,8(a1)
    80003994:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003996:	03400613          	li	a2,52
    8000399a:	05b1                	addi	a1,a1,12
    8000399c:	05048513          	addi	a0,s1,80
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	388080e7          	jalr	904(ra) # 80000d28 <memmove>
    brelse(bp);
    800039a8:	854a                	mv	a0,s2
    800039aa:	00000097          	auipc	ra,0x0
    800039ae:	88e080e7          	jalr	-1906(ra) # 80003238 <brelse>
    ip->valid = 1;
    800039b2:	4785                	li	a5,1
    800039b4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039b6:	04449783          	lh	a5,68(s1)
    800039ba:	fbb5                	bnez	a5,8000392e <ilock+0x24>
      panic("ilock: no type");
    800039bc:	00005517          	auipc	a0,0x5
    800039c0:	cfc50513          	addi	a0,a0,-772 # 800086b8 <syscalls+0x1b0>
    800039c4:	ffffd097          	auipc	ra,0xffffd
    800039c8:	b76080e7          	jalr	-1162(ra) # 8000053a <panic>

00000000800039cc <iunlock>:
{
    800039cc:	1101                	addi	sp,sp,-32
    800039ce:	ec06                	sd	ra,24(sp)
    800039d0:	e822                	sd	s0,16(sp)
    800039d2:	e426                	sd	s1,8(sp)
    800039d4:	e04a                	sd	s2,0(sp)
    800039d6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039d8:	c905                	beqz	a0,80003a08 <iunlock+0x3c>
    800039da:	84aa                	mv	s1,a0
    800039dc:	01050913          	addi	s2,a0,16
    800039e0:	854a                	mv	a0,s2
    800039e2:	00001097          	auipc	ra,0x1
    800039e6:	c92080e7          	jalr	-878(ra) # 80004674 <holdingsleep>
    800039ea:	cd19                	beqz	a0,80003a08 <iunlock+0x3c>
    800039ec:	449c                	lw	a5,8(s1)
    800039ee:	00f05d63          	blez	a5,80003a08 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039f2:	854a                	mv	a0,s2
    800039f4:	00001097          	auipc	ra,0x1
    800039f8:	c3c080e7          	jalr	-964(ra) # 80004630 <releasesleep>
}
    800039fc:	60e2                	ld	ra,24(sp)
    800039fe:	6442                	ld	s0,16(sp)
    80003a00:	64a2                	ld	s1,8(sp)
    80003a02:	6902                	ld	s2,0(sp)
    80003a04:	6105                	addi	sp,sp,32
    80003a06:	8082                	ret
    panic("iunlock");
    80003a08:	00005517          	auipc	a0,0x5
    80003a0c:	cc050513          	addi	a0,a0,-832 # 800086c8 <syscalls+0x1c0>
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	b2a080e7          	jalr	-1238(ra) # 8000053a <panic>

0000000080003a18 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a18:	7179                	addi	sp,sp,-48
    80003a1a:	f406                	sd	ra,40(sp)
    80003a1c:	f022                	sd	s0,32(sp)
    80003a1e:	ec26                	sd	s1,24(sp)
    80003a20:	e84a                	sd	s2,16(sp)
    80003a22:	e44e                	sd	s3,8(sp)
    80003a24:	e052                	sd	s4,0(sp)
    80003a26:	1800                	addi	s0,sp,48
    80003a28:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a2a:	05050493          	addi	s1,a0,80
    80003a2e:	08050913          	addi	s2,a0,128
    80003a32:	a021                	j	80003a3a <itrunc+0x22>
    80003a34:	0491                	addi	s1,s1,4
    80003a36:	01248d63          	beq	s1,s2,80003a50 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a3a:	408c                	lw	a1,0(s1)
    80003a3c:	dde5                	beqz	a1,80003a34 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a3e:	0009a503          	lw	a0,0(s3)
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	90c080e7          	jalr	-1780(ra) # 8000334e <bfree>
      ip->addrs[i] = 0;
    80003a4a:	0004a023          	sw	zero,0(s1)
    80003a4e:	b7dd                	j	80003a34 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a50:	0809a583          	lw	a1,128(s3)
    80003a54:	e185                	bnez	a1,80003a74 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a56:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a5a:	854e                	mv	a0,s3
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	de2080e7          	jalr	-542(ra) # 8000383e <iupdate>
}
    80003a64:	70a2                	ld	ra,40(sp)
    80003a66:	7402                	ld	s0,32(sp)
    80003a68:	64e2                	ld	s1,24(sp)
    80003a6a:	6942                	ld	s2,16(sp)
    80003a6c:	69a2                	ld	s3,8(sp)
    80003a6e:	6a02                	ld	s4,0(sp)
    80003a70:	6145                	addi	sp,sp,48
    80003a72:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a74:	0009a503          	lw	a0,0(s3)
    80003a78:	fffff097          	auipc	ra,0xfffff
    80003a7c:	690080e7          	jalr	1680(ra) # 80003108 <bread>
    80003a80:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a82:	05850493          	addi	s1,a0,88
    80003a86:	45850913          	addi	s2,a0,1112
    80003a8a:	a021                	j	80003a92 <itrunc+0x7a>
    80003a8c:	0491                	addi	s1,s1,4
    80003a8e:	01248b63          	beq	s1,s2,80003aa4 <itrunc+0x8c>
      if(a[j])
    80003a92:	408c                	lw	a1,0(s1)
    80003a94:	dde5                	beqz	a1,80003a8c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a96:	0009a503          	lw	a0,0(s3)
    80003a9a:	00000097          	auipc	ra,0x0
    80003a9e:	8b4080e7          	jalr	-1868(ra) # 8000334e <bfree>
    80003aa2:	b7ed                	j	80003a8c <itrunc+0x74>
    brelse(bp);
    80003aa4:	8552                	mv	a0,s4
    80003aa6:	fffff097          	auipc	ra,0xfffff
    80003aaa:	792080e7          	jalr	1938(ra) # 80003238 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003aae:	0809a583          	lw	a1,128(s3)
    80003ab2:	0009a503          	lw	a0,0(s3)
    80003ab6:	00000097          	auipc	ra,0x0
    80003aba:	898080e7          	jalr	-1896(ra) # 8000334e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003abe:	0809a023          	sw	zero,128(s3)
    80003ac2:	bf51                	j	80003a56 <itrunc+0x3e>

0000000080003ac4 <iput>:
{
    80003ac4:	1101                	addi	sp,sp,-32
    80003ac6:	ec06                	sd	ra,24(sp)
    80003ac8:	e822                	sd	s0,16(sp)
    80003aca:	e426                	sd	s1,8(sp)
    80003acc:	e04a                	sd	s2,0(sp)
    80003ace:	1000                	addi	s0,sp,32
    80003ad0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ad2:	0001c517          	auipc	a0,0x1c
    80003ad6:	2f650513          	addi	a0,a0,758 # 8001fdc8 <itable>
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	0f6080e7          	jalr	246(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ae2:	4498                	lw	a4,8(s1)
    80003ae4:	4785                	li	a5,1
    80003ae6:	02f70363          	beq	a4,a5,80003b0c <iput+0x48>
  ip->ref--;
    80003aea:	449c                	lw	a5,8(s1)
    80003aec:	37fd                	addiw	a5,a5,-1
    80003aee:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003af0:	0001c517          	auipc	a0,0x1c
    80003af4:	2d850513          	addi	a0,a0,728 # 8001fdc8 <itable>
    80003af8:	ffffd097          	auipc	ra,0xffffd
    80003afc:	18c080e7          	jalr	396(ra) # 80000c84 <release>
}
    80003b00:	60e2                	ld	ra,24(sp)
    80003b02:	6442                	ld	s0,16(sp)
    80003b04:	64a2                	ld	s1,8(sp)
    80003b06:	6902                	ld	s2,0(sp)
    80003b08:	6105                	addi	sp,sp,32
    80003b0a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b0c:	40bc                	lw	a5,64(s1)
    80003b0e:	dff1                	beqz	a5,80003aea <iput+0x26>
    80003b10:	04a49783          	lh	a5,74(s1)
    80003b14:	fbf9                	bnez	a5,80003aea <iput+0x26>
    acquiresleep(&ip->lock);
    80003b16:	01048913          	addi	s2,s1,16
    80003b1a:	854a                	mv	a0,s2
    80003b1c:	00001097          	auipc	ra,0x1
    80003b20:	abe080e7          	jalr	-1346(ra) # 800045da <acquiresleep>
    release(&itable.lock);
    80003b24:	0001c517          	auipc	a0,0x1c
    80003b28:	2a450513          	addi	a0,a0,676 # 8001fdc8 <itable>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	158080e7          	jalr	344(ra) # 80000c84 <release>
    itrunc(ip);
    80003b34:	8526                	mv	a0,s1
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	ee2080e7          	jalr	-286(ra) # 80003a18 <itrunc>
    ip->type = 0;
    80003b3e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b42:	8526                	mv	a0,s1
    80003b44:	00000097          	auipc	ra,0x0
    80003b48:	cfa080e7          	jalr	-774(ra) # 8000383e <iupdate>
    ip->valid = 0;
    80003b4c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b50:	854a                	mv	a0,s2
    80003b52:	00001097          	auipc	ra,0x1
    80003b56:	ade080e7          	jalr	-1314(ra) # 80004630 <releasesleep>
    acquire(&itable.lock);
    80003b5a:	0001c517          	auipc	a0,0x1c
    80003b5e:	26e50513          	addi	a0,a0,622 # 8001fdc8 <itable>
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	06e080e7          	jalr	110(ra) # 80000bd0 <acquire>
    80003b6a:	b741                	j	80003aea <iput+0x26>

0000000080003b6c <iunlockput>:
{
    80003b6c:	1101                	addi	sp,sp,-32
    80003b6e:	ec06                	sd	ra,24(sp)
    80003b70:	e822                	sd	s0,16(sp)
    80003b72:	e426                	sd	s1,8(sp)
    80003b74:	1000                	addi	s0,sp,32
    80003b76:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b78:	00000097          	auipc	ra,0x0
    80003b7c:	e54080e7          	jalr	-428(ra) # 800039cc <iunlock>
  iput(ip);
    80003b80:	8526                	mv	a0,s1
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	f42080e7          	jalr	-190(ra) # 80003ac4 <iput>
}
    80003b8a:	60e2                	ld	ra,24(sp)
    80003b8c:	6442                	ld	s0,16(sp)
    80003b8e:	64a2                	ld	s1,8(sp)
    80003b90:	6105                	addi	sp,sp,32
    80003b92:	8082                	ret

0000000080003b94 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b94:	1141                	addi	sp,sp,-16
    80003b96:	e422                	sd	s0,8(sp)
    80003b98:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b9a:	411c                	lw	a5,0(a0)
    80003b9c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b9e:	415c                	lw	a5,4(a0)
    80003ba0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ba2:	04451783          	lh	a5,68(a0)
    80003ba6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003baa:	04a51783          	lh	a5,74(a0)
    80003bae:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bb2:	04c56783          	lwu	a5,76(a0)
    80003bb6:	e99c                	sd	a5,16(a1)
}
    80003bb8:	6422                	ld	s0,8(sp)
    80003bba:	0141                	addi	sp,sp,16
    80003bbc:	8082                	ret

0000000080003bbe <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bbe:	457c                	lw	a5,76(a0)
    80003bc0:	0ed7e963          	bltu	a5,a3,80003cb2 <readi+0xf4>
{
    80003bc4:	7159                	addi	sp,sp,-112
    80003bc6:	f486                	sd	ra,104(sp)
    80003bc8:	f0a2                	sd	s0,96(sp)
    80003bca:	eca6                	sd	s1,88(sp)
    80003bcc:	e8ca                	sd	s2,80(sp)
    80003bce:	e4ce                	sd	s3,72(sp)
    80003bd0:	e0d2                	sd	s4,64(sp)
    80003bd2:	fc56                	sd	s5,56(sp)
    80003bd4:	f85a                	sd	s6,48(sp)
    80003bd6:	f45e                	sd	s7,40(sp)
    80003bd8:	f062                	sd	s8,32(sp)
    80003bda:	ec66                	sd	s9,24(sp)
    80003bdc:	e86a                	sd	s10,16(sp)
    80003bde:	e46e                	sd	s11,8(sp)
    80003be0:	1880                	addi	s0,sp,112
    80003be2:	8baa                	mv	s7,a0
    80003be4:	8c2e                	mv	s8,a1
    80003be6:	8ab2                	mv	s5,a2
    80003be8:	84b6                	mv	s1,a3
    80003bea:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bec:	9f35                	addw	a4,a4,a3
    return 0;
    80003bee:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bf0:	0ad76063          	bltu	a4,a3,80003c90 <readi+0xd2>
  if(off + n > ip->size)
    80003bf4:	00e7f463          	bgeu	a5,a4,80003bfc <readi+0x3e>
    n = ip->size - off;
    80003bf8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bfc:	0a0b0963          	beqz	s6,80003cae <readi+0xf0>
    80003c00:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c02:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c06:	5cfd                	li	s9,-1
    80003c08:	a82d                	j	80003c42 <readi+0x84>
    80003c0a:	020a1d93          	slli	s11,s4,0x20
    80003c0e:	020ddd93          	srli	s11,s11,0x20
    80003c12:	05890613          	addi	a2,s2,88
    80003c16:	86ee                	mv	a3,s11
    80003c18:	963a                	add	a2,a2,a4
    80003c1a:	85d6                	mv	a1,s5
    80003c1c:	8562                	mv	a0,s8
    80003c1e:	fffff097          	auipc	ra,0xfffff
    80003c22:	814080e7          	jalr	-2028(ra) # 80002432 <either_copyout>
    80003c26:	05950d63          	beq	a0,s9,80003c80 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c2a:	854a                	mv	a0,s2
    80003c2c:	fffff097          	auipc	ra,0xfffff
    80003c30:	60c080e7          	jalr	1548(ra) # 80003238 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c34:	013a09bb          	addw	s3,s4,s3
    80003c38:	009a04bb          	addw	s1,s4,s1
    80003c3c:	9aee                	add	s5,s5,s11
    80003c3e:	0569f763          	bgeu	s3,s6,80003c8c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c42:	000ba903          	lw	s2,0(s7)
    80003c46:	00a4d59b          	srliw	a1,s1,0xa
    80003c4a:	855e                	mv	a0,s7
    80003c4c:	00000097          	auipc	ra,0x0
    80003c50:	8ac080e7          	jalr	-1876(ra) # 800034f8 <bmap>
    80003c54:	0005059b          	sext.w	a1,a0
    80003c58:	854a                	mv	a0,s2
    80003c5a:	fffff097          	auipc	ra,0xfffff
    80003c5e:	4ae080e7          	jalr	1198(ra) # 80003108 <bread>
    80003c62:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c64:	3ff4f713          	andi	a4,s1,1023
    80003c68:	40ed07bb          	subw	a5,s10,a4
    80003c6c:	413b06bb          	subw	a3,s6,s3
    80003c70:	8a3e                	mv	s4,a5
    80003c72:	2781                	sext.w	a5,a5
    80003c74:	0006861b          	sext.w	a2,a3
    80003c78:	f8f679e3          	bgeu	a2,a5,80003c0a <readi+0x4c>
    80003c7c:	8a36                	mv	s4,a3
    80003c7e:	b771                	j	80003c0a <readi+0x4c>
      brelse(bp);
    80003c80:	854a                	mv	a0,s2
    80003c82:	fffff097          	auipc	ra,0xfffff
    80003c86:	5b6080e7          	jalr	1462(ra) # 80003238 <brelse>
      tot = -1;
    80003c8a:	59fd                	li	s3,-1
  }
  return tot;
    80003c8c:	0009851b          	sext.w	a0,s3
}
    80003c90:	70a6                	ld	ra,104(sp)
    80003c92:	7406                	ld	s0,96(sp)
    80003c94:	64e6                	ld	s1,88(sp)
    80003c96:	6946                	ld	s2,80(sp)
    80003c98:	69a6                	ld	s3,72(sp)
    80003c9a:	6a06                	ld	s4,64(sp)
    80003c9c:	7ae2                	ld	s5,56(sp)
    80003c9e:	7b42                	ld	s6,48(sp)
    80003ca0:	7ba2                	ld	s7,40(sp)
    80003ca2:	7c02                	ld	s8,32(sp)
    80003ca4:	6ce2                	ld	s9,24(sp)
    80003ca6:	6d42                	ld	s10,16(sp)
    80003ca8:	6da2                	ld	s11,8(sp)
    80003caa:	6165                	addi	sp,sp,112
    80003cac:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cae:	89da                	mv	s3,s6
    80003cb0:	bff1                	j	80003c8c <readi+0xce>
    return 0;
    80003cb2:	4501                	li	a0,0
}
    80003cb4:	8082                	ret

0000000080003cb6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cb6:	457c                	lw	a5,76(a0)
    80003cb8:	10d7e863          	bltu	a5,a3,80003dc8 <writei+0x112>
{
    80003cbc:	7159                	addi	sp,sp,-112
    80003cbe:	f486                	sd	ra,104(sp)
    80003cc0:	f0a2                	sd	s0,96(sp)
    80003cc2:	eca6                	sd	s1,88(sp)
    80003cc4:	e8ca                	sd	s2,80(sp)
    80003cc6:	e4ce                	sd	s3,72(sp)
    80003cc8:	e0d2                	sd	s4,64(sp)
    80003cca:	fc56                	sd	s5,56(sp)
    80003ccc:	f85a                	sd	s6,48(sp)
    80003cce:	f45e                	sd	s7,40(sp)
    80003cd0:	f062                	sd	s8,32(sp)
    80003cd2:	ec66                	sd	s9,24(sp)
    80003cd4:	e86a                	sd	s10,16(sp)
    80003cd6:	e46e                	sd	s11,8(sp)
    80003cd8:	1880                	addi	s0,sp,112
    80003cda:	8b2a                	mv	s6,a0
    80003cdc:	8c2e                	mv	s8,a1
    80003cde:	8ab2                	mv	s5,a2
    80003ce0:	8936                	mv	s2,a3
    80003ce2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ce4:	00e687bb          	addw	a5,a3,a4
    80003ce8:	0ed7e263          	bltu	a5,a3,80003dcc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cec:	00043737          	lui	a4,0x43
    80003cf0:	0ef76063          	bltu	a4,a5,80003dd0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cf4:	0c0b8863          	beqz	s7,80003dc4 <writei+0x10e>
    80003cf8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cfa:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cfe:	5cfd                	li	s9,-1
    80003d00:	a091                	j	80003d44 <writei+0x8e>
    80003d02:	02099d93          	slli	s11,s3,0x20
    80003d06:	020ddd93          	srli	s11,s11,0x20
    80003d0a:	05848513          	addi	a0,s1,88
    80003d0e:	86ee                	mv	a3,s11
    80003d10:	8656                	mv	a2,s5
    80003d12:	85e2                	mv	a1,s8
    80003d14:	953a                	add	a0,a0,a4
    80003d16:	ffffe097          	auipc	ra,0xffffe
    80003d1a:	772080e7          	jalr	1906(ra) # 80002488 <either_copyin>
    80003d1e:	07950263          	beq	a0,s9,80003d82 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d22:	8526                	mv	a0,s1
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	798080e7          	jalr	1944(ra) # 800044bc <log_write>
    brelse(bp);
    80003d2c:	8526                	mv	a0,s1
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	50a080e7          	jalr	1290(ra) # 80003238 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d36:	01498a3b          	addw	s4,s3,s4
    80003d3a:	0129893b          	addw	s2,s3,s2
    80003d3e:	9aee                	add	s5,s5,s11
    80003d40:	057a7663          	bgeu	s4,s7,80003d8c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d44:	000b2483          	lw	s1,0(s6)
    80003d48:	00a9559b          	srliw	a1,s2,0xa
    80003d4c:	855a                	mv	a0,s6
    80003d4e:	fffff097          	auipc	ra,0xfffff
    80003d52:	7aa080e7          	jalr	1962(ra) # 800034f8 <bmap>
    80003d56:	0005059b          	sext.w	a1,a0
    80003d5a:	8526                	mv	a0,s1
    80003d5c:	fffff097          	auipc	ra,0xfffff
    80003d60:	3ac080e7          	jalr	940(ra) # 80003108 <bread>
    80003d64:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d66:	3ff97713          	andi	a4,s2,1023
    80003d6a:	40ed07bb          	subw	a5,s10,a4
    80003d6e:	414b86bb          	subw	a3,s7,s4
    80003d72:	89be                	mv	s3,a5
    80003d74:	2781                	sext.w	a5,a5
    80003d76:	0006861b          	sext.w	a2,a3
    80003d7a:	f8f674e3          	bgeu	a2,a5,80003d02 <writei+0x4c>
    80003d7e:	89b6                	mv	s3,a3
    80003d80:	b749                	j	80003d02 <writei+0x4c>
      brelse(bp);
    80003d82:	8526                	mv	a0,s1
    80003d84:	fffff097          	auipc	ra,0xfffff
    80003d88:	4b4080e7          	jalr	1204(ra) # 80003238 <brelse>
  }

  if(off > ip->size)
    80003d8c:	04cb2783          	lw	a5,76(s6)
    80003d90:	0127f463          	bgeu	a5,s2,80003d98 <writei+0xe2>
    ip->size = off;
    80003d94:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d98:	855a                	mv	a0,s6
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	aa4080e7          	jalr	-1372(ra) # 8000383e <iupdate>

  return tot;
    80003da2:	000a051b          	sext.w	a0,s4
}
    80003da6:	70a6                	ld	ra,104(sp)
    80003da8:	7406                	ld	s0,96(sp)
    80003daa:	64e6                	ld	s1,88(sp)
    80003dac:	6946                	ld	s2,80(sp)
    80003dae:	69a6                	ld	s3,72(sp)
    80003db0:	6a06                	ld	s4,64(sp)
    80003db2:	7ae2                	ld	s5,56(sp)
    80003db4:	7b42                	ld	s6,48(sp)
    80003db6:	7ba2                	ld	s7,40(sp)
    80003db8:	7c02                	ld	s8,32(sp)
    80003dba:	6ce2                	ld	s9,24(sp)
    80003dbc:	6d42                	ld	s10,16(sp)
    80003dbe:	6da2                	ld	s11,8(sp)
    80003dc0:	6165                	addi	sp,sp,112
    80003dc2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dc4:	8a5e                	mv	s4,s7
    80003dc6:	bfc9                	j	80003d98 <writei+0xe2>
    return -1;
    80003dc8:	557d                	li	a0,-1
}
    80003dca:	8082                	ret
    return -1;
    80003dcc:	557d                	li	a0,-1
    80003dce:	bfe1                	j	80003da6 <writei+0xf0>
    return -1;
    80003dd0:	557d                	li	a0,-1
    80003dd2:	bfd1                	j	80003da6 <writei+0xf0>

0000000080003dd4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dd4:	1141                	addi	sp,sp,-16
    80003dd6:	e406                	sd	ra,8(sp)
    80003dd8:	e022                	sd	s0,0(sp)
    80003dda:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ddc:	4639                	li	a2,14
    80003dde:	ffffd097          	auipc	ra,0xffffd
    80003de2:	fbe080e7          	jalr	-66(ra) # 80000d9c <strncmp>
}
    80003de6:	60a2                	ld	ra,8(sp)
    80003de8:	6402                	ld	s0,0(sp)
    80003dea:	0141                	addi	sp,sp,16
    80003dec:	8082                	ret

0000000080003dee <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dee:	7139                	addi	sp,sp,-64
    80003df0:	fc06                	sd	ra,56(sp)
    80003df2:	f822                	sd	s0,48(sp)
    80003df4:	f426                	sd	s1,40(sp)
    80003df6:	f04a                	sd	s2,32(sp)
    80003df8:	ec4e                	sd	s3,24(sp)
    80003dfa:	e852                	sd	s4,16(sp)
    80003dfc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dfe:	04451703          	lh	a4,68(a0)
    80003e02:	4785                	li	a5,1
    80003e04:	00f71a63          	bne	a4,a5,80003e18 <dirlookup+0x2a>
    80003e08:	892a                	mv	s2,a0
    80003e0a:	89ae                	mv	s3,a1
    80003e0c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e0e:	457c                	lw	a5,76(a0)
    80003e10:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e12:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e14:	e79d                	bnez	a5,80003e42 <dirlookup+0x54>
    80003e16:	a8a5                	j	80003e8e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e18:	00005517          	auipc	a0,0x5
    80003e1c:	8b850513          	addi	a0,a0,-1864 # 800086d0 <syscalls+0x1c8>
    80003e20:	ffffc097          	auipc	ra,0xffffc
    80003e24:	71a080e7          	jalr	1818(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003e28:	00005517          	auipc	a0,0x5
    80003e2c:	8c050513          	addi	a0,a0,-1856 # 800086e8 <syscalls+0x1e0>
    80003e30:	ffffc097          	auipc	ra,0xffffc
    80003e34:	70a080e7          	jalr	1802(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e38:	24c1                	addiw	s1,s1,16
    80003e3a:	04c92783          	lw	a5,76(s2)
    80003e3e:	04f4f763          	bgeu	s1,a5,80003e8c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e42:	4741                	li	a4,16
    80003e44:	86a6                	mv	a3,s1
    80003e46:	fc040613          	addi	a2,s0,-64
    80003e4a:	4581                	li	a1,0
    80003e4c:	854a                	mv	a0,s2
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	d70080e7          	jalr	-656(ra) # 80003bbe <readi>
    80003e56:	47c1                	li	a5,16
    80003e58:	fcf518e3          	bne	a0,a5,80003e28 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e5c:	fc045783          	lhu	a5,-64(s0)
    80003e60:	dfe1                	beqz	a5,80003e38 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e62:	fc240593          	addi	a1,s0,-62
    80003e66:	854e                	mv	a0,s3
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	f6c080e7          	jalr	-148(ra) # 80003dd4 <namecmp>
    80003e70:	f561                	bnez	a0,80003e38 <dirlookup+0x4a>
      if(poff)
    80003e72:	000a0463          	beqz	s4,80003e7a <dirlookup+0x8c>
        *poff = off;
    80003e76:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e7a:	fc045583          	lhu	a1,-64(s0)
    80003e7e:	00092503          	lw	a0,0(s2)
    80003e82:	fffff097          	auipc	ra,0xfffff
    80003e86:	752080e7          	jalr	1874(ra) # 800035d4 <iget>
    80003e8a:	a011                	j	80003e8e <dirlookup+0xa0>
  return 0;
    80003e8c:	4501                	li	a0,0
}
    80003e8e:	70e2                	ld	ra,56(sp)
    80003e90:	7442                	ld	s0,48(sp)
    80003e92:	74a2                	ld	s1,40(sp)
    80003e94:	7902                	ld	s2,32(sp)
    80003e96:	69e2                	ld	s3,24(sp)
    80003e98:	6a42                	ld	s4,16(sp)
    80003e9a:	6121                	addi	sp,sp,64
    80003e9c:	8082                	ret

0000000080003e9e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e9e:	711d                	addi	sp,sp,-96
    80003ea0:	ec86                	sd	ra,88(sp)
    80003ea2:	e8a2                	sd	s0,80(sp)
    80003ea4:	e4a6                	sd	s1,72(sp)
    80003ea6:	e0ca                	sd	s2,64(sp)
    80003ea8:	fc4e                	sd	s3,56(sp)
    80003eaa:	f852                	sd	s4,48(sp)
    80003eac:	f456                	sd	s5,40(sp)
    80003eae:	f05a                	sd	s6,32(sp)
    80003eb0:	ec5e                	sd	s7,24(sp)
    80003eb2:	e862                	sd	s8,16(sp)
    80003eb4:	e466                	sd	s9,8(sp)
    80003eb6:	e06a                	sd	s10,0(sp)
    80003eb8:	1080                	addi	s0,sp,96
    80003eba:	84aa                	mv	s1,a0
    80003ebc:	8b2e                	mv	s6,a1
    80003ebe:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ec0:	00054703          	lbu	a4,0(a0)
    80003ec4:	02f00793          	li	a5,47
    80003ec8:	02f70363          	beq	a4,a5,80003eee <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ecc:	ffffe097          	auipc	ra,0xffffe
    80003ed0:	aca080e7          	jalr	-1334(ra) # 80001996 <myproc>
    80003ed4:	15053503          	ld	a0,336(a0)
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	9f4080e7          	jalr	-1548(ra) # 800038cc <idup>
    80003ee0:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003ee2:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003ee6:	4cb5                	li	s9,13
  len = path - s;
    80003ee8:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003eea:	4c05                	li	s8,1
    80003eec:	a87d                	j	80003faa <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003eee:	4585                	li	a1,1
    80003ef0:	4505                	li	a0,1
    80003ef2:	fffff097          	auipc	ra,0xfffff
    80003ef6:	6e2080e7          	jalr	1762(ra) # 800035d4 <iget>
    80003efa:	8a2a                	mv	s4,a0
    80003efc:	b7dd                	j	80003ee2 <namex+0x44>
      iunlockput(ip);
    80003efe:	8552                	mv	a0,s4
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	c6c080e7          	jalr	-916(ra) # 80003b6c <iunlockput>
      return 0;
    80003f08:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f0a:	8552                	mv	a0,s4
    80003f0c:	60e6                	ld	ra,88(sp)
    80003f0e:	6446                	ld	s0,80(sp)
    80003f10:	64a6                	ld	s1,72(sp)
    80003f12:	6906                	ld	s2,64(sp)
    80003f14:	79e2                	ld	s3,56(sp)
    80003f16:	7a42                	ld	s4,48(sp)
    80003f18:	7aa2                	ld	s5,40(sp)
    80003f1a:	7b02                	ld	s6,32(sp)
    80003f1c:	6be2                	ld	s7,24(sp)
    80003f1e:	6c42                	ld	s8,16(sp)
    80003f20:	6ca2                	ld	s9,8(sp)
    80003f22:	6d02                	ld	s10,0(sp)
    80003f24:	6125                	addi	sp,sp,96
    80003f26:	8082                	ret
      iunlock(ip);
    80003f28:	8552                	mv	a0,s4
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	aa2080e7          	jalr	-1374(ra) # 800039cc <iunlock>
      return ip;
    80003f32:	bfe1                	j	80003f0a <namex+0x6c>
      iunlockput(ip);
    80003f34:	8552                	mv	a0,s4
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	c36080e7          	jalr	-970(ra) # 80003b6c <iunlockput>
      return 0;
    80003f3e:	8a4e                	mv	s4,s3
    80003f40:	b7e9                	j	80003f0a <namex+0x6c>
  len = path - s;
    80003f42:	40998633          	sub	a2,s3,s1
    80003f46:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003f4a:	09acd863          	bge	s9,s10,80003fda <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003f4e:	4639                	li	a2,14
    80003f50:	85a6                	mv	a1,s1
    80003f52:	8556                	mv	a0,s5
    80003f54:	ffffd097          	auipc	ra,0xffffd
    80003f58:	dd4080e7          	jalr	-556(ra) # 80000d28 <memmove>
    80003f5c:	84ce                	mv	s1,s3
  while(*path == '/')
    80003f5e:	0004c783          	lbu	a5,0(s1)
    80003f62:	01279763          	bne	a5,s2,80003f70 <namex+0xd2>
    path++;
    80003f66:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f68:	0004c783          	lbu	a5,0(s1)
    80003f6c:	ff278de3          	beq	a5,s2,80003f66 <namex+0xc8>
    ilock(ip);
    80003f70:	8552                	mv	a0,s4
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	998080e7          	jalr	-1640(ra) # 8000390a <ilock>
    if(ip->type != T_DIR){
    80003f7a:	044a1783          	lh	a5,68(s4)
    80003f7e:	f98790e3          	bne	a5,s8,80003efe <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003f82:	000b0563          	beqz	s6,80003f8c <namex+0xee>
    80003f86:	0004c783          	lbu	a5,0(s1)
    80003f8a:	dfd9                	beqz	a5,80003f28 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f8c:	865e                	mv	a2,s7
    80003f8e:	85d6                	mv	a1,s5
    80003f90:	8552                	mv	a0,s4
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	e5c080e7          	jalr	-420(ra) # 80003dee <dirlookup>
    80003f9a:	89aa                	mv	s3,a0
    80003f9c:	dd41                	beqz	a0,80003f34 <namex+0x96>
    iunlockput(ip);
    80003f9e:	8552                	mv	a0,s4
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	bcc080e7          	jalr	-1076(ra) # 80003b6c <iunlockput>
    ip = next;
    80003fa8:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003faa:	0004c783          	lbu	a5,0(s1)
    80003fae:	01279763          	bne	a5,s2,80003fbc <namex+0x11e>
    path++;
    80003fb2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fb4:	0004c783          	lbu	a5,0(s1)
    80003fb8:	ff278de3          	beq	a5,s2,80003fb2 <namex+0x114>
  if(*path == 0)
    80003fbc:	cb9d                	beqz	a5,80003ff2 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003fbe:	0004c783          	lbu	a5,0(s1)
    80003fc2:	89a6                	mv	s3,s1
  len = path - s;
    80003fc4:	8d5e                	mv	s10,s7
    80003fc6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003fc8:	01278963          	beq	a5,s2,80003fda <namex+0x13c>
    80003fcc:	dbbd                	beqz	a5,80003f42 <namex+0xa4>
    path++;
    80003fce:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003fd0:	0009c783          	lbu	a5,0(s3)
    80003fd4:	ff279ce3          	bne	a5,s2,80003fcc <namex+0x12e>
    80003fd8:	b7ad                	j	80003f42 <namex+0xa4>
    memmove(name, s, len);
    80003fda:	2601                	sext.w	a2,a2
    80003fdc:	85a6                	mv	a1,s1
    80003fde:	8556                	mv	a0,s5
    80003fe0:	ffffd097          	auipc	ra,0xffffd
    80003fe4:	d48080e7          	jalr	-696(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003fe8:	9d56                	add	s10,s10,s5
    80003fea:	000d0023          	sb	zero,0(s10)
    80003fee:	84ce                	mv	s1,s3
    80003ff0:	b7bd                	j	80003f5e <namex+0xc0>
  if(nameiparent){
    80003ff2:	f00b0ce3          	beqz	s6,80003f0a <namex+0x6c>
    iput(ip);
    80003ff6:	8552                	mv	a0,s4
    80003ff8:	00000097          	auipc	ra,0x0
    80003ffc:	acc080e7          	jalr	-1332(ra) # 80003ac4 <iput>
    return 0;
    80004000:	4a01                	li	s4,0
    80004002:	b721                	j	80003f0a <namex+0x6c>

0000000080004004 <dirlink>:
{
    80004004:	7139                	addi	sp,sp,-64
    80004006:	fc06                	sd	ra,56(sp)
    80004008:	f822                	sd	s0,48(sp)
    8000400a:	f426                	sd	s1,40(sp)
    8000400c:	f04a                	sd	s2,32(sp)
    8000400e:	ec4e                	sd	s3,24(sp)
    80004010:	e852                	sd	s4,16(sp)
    80004012:	0080                	addi	s0,sp,64
    80004014:	892a                	mv	s2,a0
    80004016:	8a2e                	mv	s4,a1
    80004018:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000401a:	4601                	li	a2,0
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	dd2080e7          	jalr	-558(ra) # 80003dee <dirlookup>
    80004024:	e93d                	bnez	a0,8000409a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004026:	04c92483          	lw	s1,76(s2)
    8000402a:	c49d                	beqz	s1,80004058 <dirlink+0x54>
    8000402c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000402e:	4741                	li	a4,16
    80004030:	86a6                	mv	a3,s1
    80004032:	fc040613          	addi	a2,s0,-64
    80004036:	4581                	li	a1,0
    80004038:	854a                	mv	a0,s2
    8000403a:	00000097          	auipc	ra,0x0
    8000403e:	b84080e7          	jalr	-1148(ra) # 80003bbe <readi>
    80004042:	47c1                	li	a5,16
    80004044:	06f51163          	bne	a0,a5,800040a6 <dirlink+0xa2>
    if(de.inum == 0)
    80004048:	fc045783          	lhu	a5,-64(s0)
    8000404c:	c791                	beqz	a5,80004058 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000404e:	24c1                	addiw	s1,s1,16
    80004050:	04c92783          	lw	a5,76(s2)
    80004054:	fcf4ede3          	bltu	s1,a5,8000402e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004058:	4639                	li	a2,14
    8000405a:	85d2                	mv	a1,s4
    8000405c:	fc240513          	addi	a0,s0,-62
    80004060:	ffffd097          	auipc	ra,0xffffd
    80004064:	d78080e7          	jalr	-648(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80004068:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000406c:	4741                	li	a4,16
    8000406e:	86a6                	mv	a3,s1
    80004070:	fc040613          	addi	a2,s0,-64
    80004074:	4581                	li	a1,0
    80004076:	854a                	mv	a0,s2
    80004078:	00000097          	auipc	ra,0x0
    8000407c:	c3e080e7          	jalr	-962(ra) # 80003cb6 <writei>
    80004080:	872a                	mv	a4,a0
    80004082:	47c1                	li	a5,16
  return 0;
    80004084:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004086:	02f71863          	bne	a4,a5,800040b6 <dirlink+0xb2>
}
    8000408a:	70e2                	ld	ra,56(sp)
    8000408c:	7442                	ld	s0,48(sp)
    8000408e:	74a2                	ld	s1,40(sp)
    80004090:	7902                	ld	s2,32(sp)
    80004092:	69e2                	ld	s3,24(sp)
    80004094:	6a42                	ld	s4,16(sp)
    80004096:	6121                	addi	sp,sp,64
    80004098:	8082                	ret
    iput(ip);
    8000409a:	00000097          	auipc	ra,0x0
    8000409e:	a2a080e7          	jalr	-1494(ra) # 80003ac4 <iput>
    return -1;
    800040a2:	557d                	li	a0,-1
    800040a4:	b7dd                	j	8000408a <dirlink+0x86>
      panic("dirlink read");
    800040a6:	00004517          	auipc	a0,0x4
    800040aa:	65250513          	addi	a0,a0,1618 # 800086f8 <syscalls+0x1f0>
    800040ae:	ffffc097          	auipc	ra,0xffffc
    800040b2:	48c080e7          	jalr	1164(ra) # 8000053a <panic>
    panic("dirlink");
    800040b6:	00004517          	auipc	a0,0x4
    800040ba:	75250513          	addi	a0,a0,1874 # 80008808 <syscalls+0x300>
    800040be:	ffffc097          	auipc	ra,0xffffc
    800040c2:	47c080e7          	jalr	1148(ra) # 8000053a <panic>

00000000800040c6 <namei>:

struct inode*
namei(char *path)
{
    800040c6:	1101                	addi	sp,sp,-32
    800040c8:	ec06                	sd	ra,24(sp)
    800040ca:	e822                	sd	s0,16(sp)
    800040cc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040ce:	fe040613          	addi	a2,s0,-32
    800040d2:	4581                	li	a1,0
    800040d4:	00000097          	auipc	ra,0x0
    800040d8:	dca080e7          	jalr	-566(ra) # 80003e9e <namex>
}
    800040dc:	60e2                	ld	ra,24(sp)
    800040de:	6442                	ld	s0,16(sp)
    800040e0:	6105                	addi	sp,sp,32
    800040e2:	8082                	ret

00000000800040e4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040e4:	1141                	addi	sp,sp,-16
    800040e6:	e406                	sd	ra,8(sp)
    800040e8:	e022                	sd	s0,0(sp)
    800040ea:	0800                	addi	s0,sp,16
    800040ec:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040ee:	4585                	li	a1,1
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	dae080e7          	jalr	-594(ra) # 80003e9e <namex>
}
    800040f8:	60a2                	ld	ra,8(sp)
    800040fa:	6402                	ld	s0,0(sp)
    800040fc:	0141                	addi	sp,sp,16
    800040fe:	8082                	ret

0000000080004100 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004100:	1101                	addi	sp,sp,-32
    80004102:	ec06                	sd	ra,24(sp)
    80004104:	e822                	sd	s0,16(sp)
    80004106:	e426                	sd	s1,8(sp)
    80004108:	e04a                	sd	s2,0(sp)
    8000410a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000410c:	0001d917          	auipc	s2,0x1d
    80004110:	76490913          	addi	s2,s2,1892 # 80021870 <log>
    80004114:	01892583          	lw	a1,24(s2)
    80004118:	02892503          	lw	a0,40(s2)
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	fec080e7          	jalr	-20(ra) # 80003108 <bread>
    80004124:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004126:	02c92683          	lw	a3,44(s2)
    8000412a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000412c:	02d05863          	blez	a3,8000415c <write_head+0x5c>
    80004130:	0001d797          	auipc	a5,0x1d
    80004134:	77078793          	addi	a5,a5,1904 # 800218a0 <log+0x30>
    80004138:	05c50713          	addi	a4,a0,92
    8000413c:	36fd                	addiw	a3,a3,-1
    8000413e:	02069613          	slli	a2,a3,0x20
    80004142:	01e65693          	srli	a3,a2,0x1e
    80004146:	0001d617          	auipc	a2,0x1d
    8000414a:	75e60613          	addi	a2,a2,1886 # 800218a4 <log+0x34>
    8000414e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004150:	4390                	lw	a2,0(a5)
    80004152:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004154:	0791                	addi	a5,a5,4
    80004156:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004158:	fed79ce3          	bne	a5,a3,80004150 <write_head+0x50>
  }
  bwrite(buf);
    8000415c:	8526                	mv	a0,s1
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	09c080e7          	jalr	156(ra) # 800031fa <bwrite>
  brelse(buf);
    80004166:	8526                	mv	a0,s1
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	0d0080e7          	jalr	208(ra) # 80003238 <brelse>
}
    80004170:	60e2                	ld	ra,24(sp)
    80004172:	6442                	ld	s0,16(sp)
    80004174:	64a2                	ld	s1,8(sp)
    80004176:	6902                	ld	s2,0(sp)
    80004178:	6105                	addi	sp,sp,32
    8000417a:	8082                	ret

000000008000417c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000417c:	0001d797          	auipc	a5,0x1d
    80004180:	7207a783          	lw	a5,1824(a5) # 8002189c <log+0x2c>
    80004184:	0af05d63          	blez	a5,8000423e <install_trans+0xc2>
{
    80004188:	7139                	addi	sp,sp,-64
    8000418a:	fc06                	sd	ra,56(sp)
    8000418c:	f822                	sd	s0,48(sp)
    8000418e:	f426                	sd	s1,40(sp)
    80004190:	f04a                	sd	s2,32(sp)
    80004192:	ec4e                	sd	s3,24(sp)
    80004194:	e852                	sd	s4,16(sp)
    80004196:	e456                	sd	s5,8(sp)
    80004198:	e05a                	sd	s6,0(sp)
    8000419a:	0080                	addi	s0,sp,64
    8000419c:	8b2a                	mv	s6,a0
    8000419e:	0001da97          	auipc	s5,0x1d
    800041a2:	702a8a93          	addi	s5,s5,1794 # 800218a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041a8:	0001d997          	auipc	s3,0x1d
    800041ac:	6c898993          	addi	s3,s3,1736 # 80021870 <log>
    800041b0:	a00d                	j	800041d2 <install_trans+0x56>
    brelse(lbuf);
    800041b2:	854a                	mv	a0,s2
    800041b4:	fffff097          	auipc	ra,0xfffff
    800041b8:	084080e7          	jalr	132(ra) # 80003238 <brelse>
    brelse(dbuf);
    800041bc:	8526                	mv	a0,s1
    800041be:	fffff097          	auipc	ra,0xfffff
    800041c2:	07a080e7          	jalr	122(ra) # 80003238 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c6:	2a05                	addiw	s4,s4,1
    800041c8:	0a91                	addi	s5,s5,4
    800041ca:	02c9a783          	lw	a5,44(s3)
    800041ce:	04fa5e63          	bge	s4,a5,8000422a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041d2:	0189a583          	lw	a1,24(s3)
    800041d6:	014585bb          	addw	a1,a1,s4
    800041da:	2585                	addiw	a1,a1,1
    800041dc:	0289a503          	lw	a0,40(s3)
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	f28080e7          	jalr	-216(ra) # 80003108 <bread>
    800041e8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041ea:	000aa583          	lw	a1,0(s5)
    800041ee:	0289a503          	lw	a0,40(s3)
    800041f2:	fffff097          	auipc	ra,0xfffff
    800041f6:	f16080e7          	jalr	-234(ra) # 80003108 <bread>
    800041fa:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041fc:	40000613          	li	a2,1024
    80004200:	05890593          	addi	a1,s2,88
    80004204:	05850513          	addi	a0,a0,88
    80004208:	ffffd097          	auipc	ra,0xffffd
    8000420c:	b20080e7          	jalr	-1248(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004210:	8526                	mv	a0,s1
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	fe8080e7          	jalr	-24(ra) # 800031fa <bwrite>
    if(recovering == 0)
    8000421a:	f80b1ce3          	bnez	s6,800041b2 <install_trans+0x36>
      bunpin(dbuf);
    8000421e:	8526                	mv	a0,s1
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	0f2080e7          	jalr	242(ra) # 80003312 <bunpin>
    80004228:	b769                	j	800041b2 <install_trans+0x36>
}
    8000422a:	70e2                	ld	ra,56(sp)
    8000422c:	7442                	ld	s0,48(sp)
    8000422e:	74a2                	ld	s1,40(sp)
    80004230:	7902                	ld	s2,32(sp)
    80004232:	69e2                	ld	s3,24(sp)
    80004234:	6a42                	ld	s4,16(sp)
    80004236:	6aa2                	ld	s5,8(sp)
    80004238:	6b02                	ld	s6,0(sp)
    8000423a:	6121                	addi	sp,sp,64
    8000423c:	8082                	ret
    8000423e:	8082                	ret

0000000080004240 <initlog>:
{
    80004240:	7179                	addi	sp,sp,-48
    80004242:	f406                	sd	ra,40(sp)
    80004244:	f022                	sd	s0,32(sp)
    80004246:	ec26                	sd	s1,24(sp)
    80004248:	e84a                	sd	s2,16(sp)
    8000424a:	e44e                	sd	s3,8(sp)
    8000424c:	1800                	addi	s0,sp,48
    8000424e:	892a                	mv	s2,a0
    80004250:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004252:	0001d497          	auipc	s1,0x1d
    80004256:	61e48493          	addi	s1,s1,1566 # 80021870 <log>
    8000425a:	00004597          	auipc	a1,0x4
    8000425e:	4ae58593          	addi	a1,a1,1198 # 80008708 <syscalls+0x200>
    80004262:	8526                	mv	a0,s1
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	8dc080e7          	jalr	-1828(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    8000426c:	0149a583          	lw	a1,20(s3)
    80004270:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004272:	0109a783          	lw	a5,16(s3)
    80004276:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004278:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000427c:	854a                	mv	a0,s2
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	e8a080e7          	jalr	-374(ra) # 80003108 <bread>
  log.lh.n = lh->n;
    80004286:	4d34                	lw	a3,88(a0)
    80004288:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000428a:	02d05663          	blez	a3,800042b6 <initlog+0x76>
    8000428e:	05c50793          	addi	a5,a0,92
    80004292:	0001d717          	auipc	a4,0x1d
    80004296:	60e70713          	addi	a4,a4,1550 # 800218a0 <log+0x30>
    8000429a:	36fd                	addiw	a3,a3,-1
    8000429c:	02069613          	slli	a2,a3,0x20
    800042a0:	01e65693          	srli	a3,a2,0x1e
    800042a4:	06050613          	addi	a2,a0,96
    800042a8:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800042aa:	4390                	lw	a2,0(a5)
    800042ac:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042ae:	0791                	addi	a5,a5,4
    800042b0:	0711                	addi	a4,a4,4
    800042b2:	fed79ce3          	bne	a5,a3,800042aa <initlog+0x6a>
  brelse(buf);
    800042b6:	fffff097          	auipc	ra,0xfffff
    800042ba:	f82080e7          	jalr	-126(ra) # 80003238 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042be:	4505                	li	a0,1
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	ebc080e7          	jalr	-324(ra) # 8000417c <install_trans>
  log.lh.n = 0;
    800042c8:	0001d797          	auipc	a5,0x1d
    800042cc:	5c07aa23          	sw	zero,1492(a5) # 8002189c <log+0x2c>
  write_head(); // clear the log
    800042d0:	00000097          	auipc	ra,0x0
    800042d4:	e30080e7          	jalr	-464(ra) # 80004100 <write_head>
}
    800042d8:	70a2                	ld	ra,40(sp)
    800042da:	7402                	ld	s0,32(sp)
    800042dc:	64e2                	ld	s1,24(sp)
    800042de:	6942                	ld	s2,16(sp)
    800042e0:	69a2                	ld	s3,8(sp)
    800042e2:	6145                	addi	sp,sp,48
    800042e4:	8082                	ret

00000000800042e6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042e6:	1101                	addi	sp,sp,-32
    800042e8:	ec06                	sd	ra,24(sp)
    800042ea:	e822                	sd	s0,16(sp)
    800042ec:	e426                	sd	s1,8(sp)
    800042ee:	e04a                	sd	s2,0(sp)
    800042f0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042f2:	0001d517          	auipc	a0,0x1d
    800042f6:	57e50513          	addi	a0,a0,1406 # 80021870 <log>
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	8d6080e7          	jalr	-1834(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80004302:	0001d497          	auipc	s1,0x1d
    80004306:	56e48493          	addi	s1,s1,1390 # 80021870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000430a:	4979                	li	s2,30
    8000430c:	a039                	j	8000431a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000430e:	85a6                	mv	a1,s1
    80004310:	8526                	mv	a0,s1
    80004312:	ffffe097          	auipc	ra,0xffffe
    80004316:	d70080e7          	jalr	-656(ra) # 80002082 <sleep>
    if(log.committing){
    8000431a:	50dc                	lw	a5,36(s1)
    8000431c:	fbed                	bnez	a5,8000430e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000431e:	5098                	lw	a4,32(s1)
    80004320:	2705                	addiw	a4,a4,1
    80004322:	0007069b          	sext.w	a3,a4
    80004326:	0027179b          	slliw	a5,a4,0x2
    8000432a:	9fb9                	addw	a5,a5,a4
    8000432c:	0017979b          	slliw	a5,a5,0x1
    80004330:	54d8                	lw	a4,44(s1)
    80004332:	9fb9                	addw	a5,a5,a4
    80004334:	00f95963          	bge	s2,a5,80004346 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004338:	85a6                	mv	a1,s1
    8000433a:	8526                	mv	a0,s1
    8000433c:	ffffe097          	auipc	ra,0xffffe
    80004340:	d46080e7          	jalr	-698(ra) # 80002082 <sleep>
    80004344:	bfd9                	j	8000431a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004346:	0001d517          	auipc	a0,0x1d
    8000434a:	52a50513          	addi	a0,a0,1322 # 80021870 <log>
    8000434e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	934080e7          	jalr	-1740(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004358:	60e2                	ld	ra,24(sp)
    8000435a:	6442                	ld	s0,16(sp)
    8000435c:	64a2                	ld	s1,8(sp)
    8000435e:	6902                	ld	s2,0(sp)
    80004360:	6105                	addi	sp,sp,32
    80004362:	8082                	ret

0000000080004364 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004364:	7139                	addi	sp,sp,-64
    80004366:	fc06                	sd	ra,56(sp)
    80004368:	f822                	sd	s0,48(sp)
    8000436a:	f426                	sd	s1,40(sp)
    8000436c:	f04a                	sd	s2,32(sp)
    8000436e:	ec4e                	sd	s3,24(sp)
    80004370:	e852                	sd	s4,16(sp)
    80004372:	e456                	sd	s5,8(sp)
    80004374:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004376:	0001d497          	auipc	s1,0x1d
    8000437a:	4fa48493          	addi	s1,s1,1274 # 80021870 <log>
    8000437e:	8526                	mv	a0,s1
    80004380:	ffffd097          	auipc	ra,0xffffd
    80004384:	850080e7          	jalr	-1968(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    80004388:	509c                	lw	a5,32(s1)
    8000438a:	37fd                	addiw	a5,a5,-1
    8000438c:	0007891b          	sext.w	s2,a5
    80004390:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004392:	50dc                	lw	a5,36(s1)
    80004394:	e7b9                	bnez	a5,800043e2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004396:	04091e63          	bnez	s2,800043f2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000439a:	0001d497          	auipc	s1,0x1d
    8000439e:	4d648493          	addi	s1,s1,1238 # 80021870 <log>
    800043a2:	4785                	li	a5,1
    800043a4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043a6:	8526                	mv	a0,s1
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	8dc080e7          	jalr	-1828(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043b0:	54dc                	lw	a5,44(s1)
    800043b2:	06f04763          	bgtz	a5,80004420 <end_op+0xbc>
    acquire(&log.lock);
    800043b6:	0001d497          	auipc	s1,0x1d
    800043ba:	4ba48493          	addi	s1,s1,1210 # 80021870 <log>
    800043be:	8526                	mv	a0,s1
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	810080e7          	jalr	-2032(ra) # 80000bd0 <acquire>
    log.committing = 0;
    800043c8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043cc:	8526                	mv	a0,s1
    800043ce:	ffffe097          	auipc	ra,0xffffe
    800043d2:	e40080e7          	jalr	-448(ra) # 8000220e <wakeup>
    release(&log.lock);
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffd097          	auipc	ra,0xffffd
    800043dc:	8ac080e7          	jalr	-1876(ra) # 80000c84 <release>
}
    800043e0:	a03d                	j	8000440e <end_op+0xaa>
    panic("log.committing");
    800043e2:	00004517          	auipc	a0,0x4
    800043e6:	32e50513          	addi	a0,a0,814 # 80008710 <syscalls+0x208>
    800043ea:	ffffc097          	auipc	ra,0xffffc
    800043ee:	150080e7          	jalr	336(ra) # 8000053a <panic>
    wakeup(&log);
    800043f2:	0001d497          	auipc	s1,0x1d
    800043f6:	47e48493          	addi	s1,s1,1150 # 80021870 <log>
    800043fa:	8526                	mv	a0,s1
    800043fc:	ffffe097          	auipc	ra,0xffffe
    80004400:	e12080e7          	jalr	-494(ra) # 8000220e <wakeup>
  release(&log.lock);
    80004404:	8526                	mv	a0,s1
    80004406:	ffffd097          	auipc	ra,0xffffd
    8000440a:	87e080e7          	jalr	-1922(ra) # 80000c84 <release>
}
    8000440e:	70e2                	ld	ra,56(sp)
    80004410:	7442                	ld	s0,48(sp)
    80004412:	74a2                	ld	s1,40(sp)
    80004414:	7902                	ld	s2,32(sp)
    80004416:	69e2                	ld	s3,24(sp)
    80004418:	6a42                	ld	s4,16(sp)
    8000441a:	6aa2                	ld	s5,8(sp)
    8000441c:	6121                	addi	sp,sp,64
    8000441e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004420:	0001da97          	auipc	s5,0x1d
    80004424:	480a8a93          	addi	s5,s5,1152 # 800218a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004428:	0001da17          	auipc	s4,0x1d
    8000442c:	448a0a13          	addi	s4,s4,1096 # 80021870 <log>
    80004430:	018a2583          	lw	a1,24(s4)
    80004434:	012585bb          	addw	a1,a1,s2
    80004438:	2585                	addiw	a1,a1,1
    8000443a:	028a2503          	lw	a0,40(s4)
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	cca080e7          	jalr	-822(ra) # 80003108 <bread>
    80004446:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004448:	000aa583          	lw	a1,0(s5)
    8000444c:	028a2503          	lw	a0,40(s4)
    80004450:	fffff097          	auipc	ra,0xfffff
    80004454:	cb8080e7          	jalr	-840(ra) # 80003108 <bread>
    80004458:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000445a:	40000613          	li	a2,1024
    8000445e:	05850593          	addi	a1,a0,88
    80004462:	05848513          	addi	a0,s1,88
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	8c2080e7          	jalr	-1854(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    8000446e:	8526                	mv	a0,s1
    80004470:	fffff097          	auipc	ra,0xfffff
    80004474:	d8a080e7          	jalr	-630(ra) # 800031fa <bwrite>
    brelse(from);
    80004478:	854e                	mv	a0,s3
    8000447a:	fffff097          	auipc	ra,0xfffff
    8000447e:	dbe080e7          	jalr	-578(ra) # 80003238 <brelse>
    brelse(to);
    80004482:	8526                	mv	a0,s1
    80004484:	fffff097          	auipc	ra,0xfffff
    80004488:	db4080e7          	jalr	-588(ra) # 80003238 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000448c:	2905                	addiw	s2,s2,1
    8000448e:	0a91                	addi	s5,s5,4
    80004490:	02ca2783          	lw	a5,44(s4)
    80004494:	f8f94ee3          	blt	s2,a5,80004430 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004498:	00000097          	auipc	ra,0x0
    8000449c:	c68080e7          	jalr	-920(ra) # 80004100 <write_head>
    install_trans(0); // Now install writes to home locations
    800044a0:	4501                	li	a0,0
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	cda080e7          	jalr	-806(ra) # 8000417c <install_trans>
    log.lh.n = 0;
    800044aa:	0001d797          	auipc	a5,0x1d
    800044ae:	3e07a923          	sw	zero,1010(a5) # 8002189c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044b2:	00000097          	auipc	ra,0x0
    800044b6:	c4e080e7          	jalr	-946(ra) # 80004100 <write_head>
    800044ba:	bdf5                	j	800043b6 <end_op+0x52>

00000000800044bc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044bc:	1101                	addi	sp,sp,-32
    800044be:	ec06                	sd	ra,24(sp)
    800044c0:	e822                	sd	s0,16(sp)
    800044c2:	e426                	sd	s1,8(sp)
    800044c4:	e04a                	sd	s2,0(sp)
    800044c6:	1000                	addi	s0,sp,32
    800044c8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044ca:	0001d917          	auipc	s2,0x1d
    800044ce:	3a690913          	addi	s2,s2,934 # 80021870 <log>
    800044d2:	854a                	mv	a0,s2
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	6fc080e7          	jalr	1788(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044dc:	02c92603          	lw	a2,44(s2)
    800044e0:	47f5                	li	a5,29
    800044e2:	06c7c563          	blt	a5,a2,8000454c <log_write+0x90>
    800044e6:	0001d797          	auipc	a5,0x1d
    800044ea:	3a67a783          	lw	a5,934(a5) # 8002188c <log+0x1c>
    800044ee:	37fd                	addiw	a5,a5,-1
    800044f0:	04f65e63          	bge	a2,a5,8000454c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044f4:	0001d797          	auipc	a5,0x1d
    800044f8:	39c7a783          	lw	a5,924(a5) # 80021890 <log+0x20>
    800044fc:	06f05063          	blez	a5,8000455c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004500:	4781                	li	a5,0
    80004502:	06c05563          	blez	a2,8000456c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004506:	44cc                	lw	a1,12(s1)
    80004508:	0001d717          	auipc	a4,0x1d
    8000450c:	39870713          	addi	a4,a4,920 # 800218a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004510:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004512:	4314                	lw	a3,0(a4)
    80004514:	04b68c63          	beq	a3,a1,8000456c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004518:	2785                	addiw	a5,a5,1
    8000451a:	0711                	addi	a4,a4,4
    8000451c:	fef61be3          	bne	a2,a5,80004512 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004520:	0621                	addi	a2,a2,8
    80004522:	060a                	slli	a2,a2,0x2
    80004524:	0001d797          	auipc	a5,0x1d
    80004528:	34c78793          	addi	a5,a5,844 # 80021870 <log>
    8000452c:	97b2                	add	a5,a5,a2
    8000452e:	44d8                	lw	a4,12(s1)
    80004530:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004532:	8526                	mv	a0,s1
    80004534:	fffff097          	auipc	ra,0xfffff
    80004538:	da2080e7          	jalr	-606(ra) # 800032d6 <bpin>
    log.lh.n++;
    8000453c:	0001d717          	auipc	a4,0x1d
    80004540:	33470713          	addi	a4,a4,820 # 80021870 <log>
    80004544:	575c                	lw	a5,44(a4)
    80004546:	2785                	addiw	a5,a5,1
    80004548:	d75c                	sw	a5,44(a4)
    8000454a:	a82d                	j	80004584 <log_write+0xc8>
    panic("too big a transaction");
    8000454c:	00004517          	auipc	a0,0x4
    80004550:	1d450513          	addi	a0,a0,468 # 80008720 <syscalls+0x218>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	fe6080e7          	jalr	-26(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    8000455c:	00004517          	auipc	a0,0x4
    80004560:	1dc50513          	addi	a0,a0,476 # 80008738 <syscalls+0x230>
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	fd6080e7          	jalr	-42(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    8000456c:	00878693          	addi	a3,a5,8
    80004570:	068a                	slli	a3,a3,0x2
    80004572:	0001d717          	auipc	a4,0x1d
    80004576:	2fe70713          	addi	a4,a4,766 # 80021870 <log>
    8000457a:	9736                	add	a4,a4,a3
    8000457c:	44d4                	lw	a3,12(s1)
    8000457e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004580:	faf609e3          	beq	a2,a5,80004532 <log_write+0x76>
  }
  release(&log.lock);
    80004584:	0001d517          	auipc	a0,0x1d
    80004588:	2ec50513          	addi	a0,a0,748 # 80021870 <log>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	6f8080e7          	jalr	1784(ra) # 80000c84 <release>
}
    80004594:	60e2                	ld	ra,24(sp)
    80004596:	6442                	ld	s0,16(sp)
    80004598:	64a2                	ld	s1,8(sp)
    8000459a:	6902                	ld	s2,0(sp)
    8000459c:	6105                	addi	sp,sp,32
    8000459e:	8082                	ret

00000000800045a0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045a0:	1101                	addi	sp,sp,-32
    800045a2:	ec06                	sd	ra,24(sp)
    800045a4:	e822                	sd	s0,16(sp)
    800045a6:	e426                	sd	s1,8(sp)
    800045a8:	e04a                	sd	s2,0(sp)
    800045aa:	1000                	addi	s0,sp,32
    800045ac:	84aa                	mv	s1,a0
    800045ae:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045b0:	00004597          	auipc	a1,0x4
    800045b4:	1a858593          	addi	a1,a1,424 # 80008758 <syscalls+0x250>
    800045b8:	0521                	addi	a0,a0,8
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	586080e7          	jalr	1414(ra) # 80000b40 <initlock>
  lk->name = name;
    800045c2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045ca:	0204a423          	sw	zero,40(s1)
}
    800045ce:	60e2                	ld	ra,24(sp)
    800045d0:	6442                	ld	s0,16(sp)
    800045d2:	64a2                	ld	s1,8(sp)
    800045d4:	6902                	ld	s2,0(sp)
    800045d6:	6105                	addi	sp,sp,32
    800045d8:	8082                	ret

00000000800045da <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045da:	1101                	addi	sp,sp,-32
    800045dc:	ec06                	sd	ra,24(sp)
    800045de:	e822                	sd	s0,16(sp)
    800045e0:	e426                	sd	s1,8(sp)
    800045e2:	e04a                	sd	s2,0(sp)
    800045e4:	1000                	addi	s0,sp,32
    800045e6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045e8:	00850913          	addi	s2,a0,8
    800045ec:	854a                	mv	a0,s2
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	5e2080e7          	jalr	1506(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    800045f6:	409c                	lw	a5,0(s1)
    800045f8:	cb89                	beqz	a5,8000460a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045fa:	85ca                	mv	a1,s2
    800045fc:	8526                	mv	a0,s1
    800045fe:	ffffe097          	auipc	ra,0xffffe
    80004602:	a84080e7          	jalr	-1404(ra) # 80002082 <sleep>
  while (lk->locked) {
    80004606:	409c                	lw	a5,0(s1)
    80004608:	fbed                	bnez	a5,800045fa <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000460a:	4785                	li	a5,1
    8000460c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000460e:	ffffd097          	auipc	ra,0xffffd
    80004612:	388080e7          	jalr	904(ra) # 80001996 <myproc>
    80004616:	591c                	lw	a5,48(a0)
    80004618:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000461a:	854a                	mv	a0,s2
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	668080e7          	jalr	1640(ra) # 80000c84 <release>
}
    80004624:	60e2                	ld	ra,24(sp)
    80004626:	6442                	ld	s0,16(sp)
    80004628:	64a2                	ld	s1,8(sp)
    8000462a:	6902                	ld	s2,0(sp)
    8000462c:	6105                	addi	sp,sp,32
    8000462e:	8082                	ret

0000000080004630 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004630:	1101                	addi	sp,sp,-32
    80004632:	ec06                	sd	ra,24(sp)
    80004634:	e822                	sd	s0,16(sp)
    80004636:	e426                	sd	s1,8(sp)
    80004638:	e04a                	sd	s2,0(sp)
    8000463a:	1000                	addi	s0,sp,32
    8000463c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000463e:	00850913          	addi	s2,a0,8
    80004642:	854a                	mv	a0,s2
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	58c080e7          	jalr	1420(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    8000464c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004650:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004654:	8526                	mv	a0,s1
    80004656:	ffffe097          	auipc	ra,0xffffe
    8000465a:	bb8080e7          	jalr	-1096(ra) # 8000220e <wakeup>
  release(&lk->lk);
    8000465e:	854a                	mv	a0,s2
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	624080e7          	jalr	1572(ra) # 80000c84 <release>
}
    80004668:	60e2                	ld	ra,24(sp)
    8000466a:	6442                	ld	s0,16(sp)
    8000466c:	64a2                	ld	s1,8(sp)
    8000466e:	6902                	ld	s2,0(sp)
    80004670:	6105                	addi	sp,sp,32
    80004672:	8082                	ret

0000000080004674 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004674:	7179                	addi	sp,sp,-48
    80004676:	f406                	sd	ra,40(sp)
    80004678:	f022                	sd	s0,32(sp)
    8000467a:	ec26                	sd	s1,24(sp)
    8000467c:	e84a                	sd	s2,16(sp)
    8000467e:	e44e                	sd	s3,8(sp)
    80004680:	1800                	addi	s0,sp,48
    80004682:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004684:	00850913          	addi	s2,a0,8
    80004688:	854a                	mv	a0,s2
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	546080e7          	jalr	1350(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004692:	409c                	lw	a5,0(s1)
    80004694:	ef99                	bnez	a5,800046b2 <holdingsleep+0x3e>
    80004696:	4481                	li	s1,0
  release(&lk->lk);
    80004698:	854a                	mv	a0,s2
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	5ea080e7          	jalr	1514(ra) # 80000c84 <release>
  return r;
}
    800046a2:	8526                	mv	a0,s1
    800046a4:	70a2                	ld	ra,40(sp)
    800046a6:	7402                	ld	s0,32(sp)
    800046a8:	64e2                	ld	s1,24(sp)
    800046aa:	6942                	ld	s2,16(sp)
    800046ac:	69a2                	ld	s3,8(sp)
    800046ae:	6145                	addi	sp,sp,48
    800046b0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046b2:	0284a983          	lw	s3,40(s1)
    800046b6:	ffffd097          	auipc	ra,0xffffd
    800046ba:	2e0080e7          	jalr	736(ra) # 80001996 <myproc>
    800046be:	5904                	lw	s1,48(a0)
    800046c0:	413484b3          	sub	s1,s1,s3
    800046c4:	0014b493          	seqz	s1,s1
    800046c8:	bfc1                	j	80004698 <holdingsleep+0x24>

00000000800046ca <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046ca:	1141                	addi	sp,sp,-16
    800046cc:	e406                	sd	ra,8(sp)
    800046ce:	e022                	sd	s0,0(sp)
    800046d0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046d2:	00004597          	auipc	a1,0x4
    800046d6:	09658593          	addi	a1,a1,150 # 80008768 <syscalls+0x260>
    800046da:	0001d517          	auipc	a0,0x1d
    800046de:	2de50513          	addi	a0,a0,734 # 800219b8 <ftable>
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	45e080e7          	jalr	1118(ra) # 80000b40 <initlock>
}
    800046ea:	60a2                	ld	ra,8(sp)
    800046ec:	6402                	ld	s0,0(sp)
    800046ee:	0141                	addi	sp,sp,16
    800046f0:	8082                	ret

00000000800046f2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046f2:	1101                	addi	sp,sp,-32
    800046f4:	ec06                	sd	ra,24(sp)
    800046f6:	e822                	sd	s0,16(sp)
    800046f8:	e426                	sd	s1,8(sp)
    800046fa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046fc:	0001d517          	auipc	a0,0x1d
    80004700:	2bc50513          	addi	a0,a0,700 # 800219b8 <ftable>
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	4cc080e7          	jalr	1228(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000470c:	0001d497          	auipc	s1,0x1d
    80004710:	2c448493          	addi	s1,s1,708 # 800219d0 <ftable+0x18>
    80004714:	0001e717          	auipc	a4,0x1e
    80004718:	25c70713          	addi	a4,a4,604 # 80022970 <ftable+0xfb8>
    if(f->ref == 0){
    8000471c:	40dc                	lw	a5,4(s1)
    8000471e:	cf99                	beqz	a5,8000473c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004720:	02848493          	addi	s1,s1,40
    80004724:	fee49ce3          	bne	s1,a4,8000471c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004728:	0001d517          	auipc	a0,0x1d
    8000472c:	29050513          	addi	a0,a0,656 # 800219b8 <ftable>
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	554080e7          	jalr	1364(ra) # 80000c84 <release>
  return 0;
    80004738:	4481                	li	s1,0
    8000473a:	a819                	j	80004750 <filealloc+0x5e>
      f->ref = 1;
    8000473c:	4785                	li	a5,1
    8000473e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004740:	0001d517          	auipc	a0,0x1d
    80004744:	27850513          	addi	a0,a0,632 # 800219b8 <ftable>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	53c080e7          	jalr	1340(ra) # 80000c84 <release>
}
    80004750:	8526                	mv	a0,s1
    80004752:	60e2                	ld	ra,24(sp)
    80004754:	6442                	ld	s0,16(sp)
    80004756:	64a2                	ld	s1,8(sp)
    80004758:	6105                	addi	sp,sp,32
    8000475a:	8082                	ret

000000008000475c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000475c:	1101                	addi	sp,sp,-32
    8000475e:	ec06                	sd	ra,24(sp)
    80004760:	e822                	sd	s0,16(sp)
    80004762:	e426                	sd	s1,8(sp)
    80004764:	1000                	addi	s0,sp,32
    80004766:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004768:	0001d517          	auipc	a0,0x1d
    8000476c:	25050513          	addi	a0,a0,592 # 800219b8 <ftable>
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	460080e7          	jalr	1120(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004778:	40dc                	lw	a5,4(s1)
    8000477a:	02f05263          	blez	a5,8000479e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000477e:	2785                	addiw	a5,a5,1
    80004780:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004782:	0001d517          	auipc	a0,0x1d
    80004786:	23650513          	addi	a0,a0,566 # 800219b8 <ftable>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	4fa080e7          	jalr	1274(ra) # 80000c84 <release>
  return f;
}
    80004792:	8526                	mv	a0,s1
    80004794:	60e2                	ld	ra,24(sp)
    80004796:	6442                	ld	s0,16(sp)
    80004798:	64a2                	ld	s1,8(sp)
    8000479a:	6105                	addi	sp,sp,32
    8000479c:	8082                	ret
    panic("filedup");
    8000479e:	00004517          	auipc	a0,0x4
    800047a2:	fd250513          	addi	a0,a0,-46 # 80008770 <syscalls+0x268>
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	d94080e7          	jalr	-620(ra) # 8000053a <panic>

00000000800047ae <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047ae:	7139                	addi	sp,sp,-64
    800047b0:	fc06                	sd	ra,56(sp)
    800047b2:	f822                	sd	s0,48(sp)
    800047b4:	f426                	sd	s1,40(sp)
    800047b6:	f04a                	sd	s2,32(sp)
    800047b8:	ec4e                	sd	s3,24(sp)
    800047ba:	e852                	sd	s4,16(sp)
    800047bc:	e456                	sd	s5,8(sp)
    800047be:	0080                	addi	s0,sp,64
    800047c0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047c2:	0001d517          	auipc	a0,0x1d
    800047c6:	1f650513          	addi	a0,a0,502 # 800219b8 <ftable>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	406080e7          	jalr	1030(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800047d2:	40dc                	lw	a5,4(s1)
    800047d4:	06f05163          	blez	a5,80004836 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047d8:	37fd                	addiw	a5,a5,-1
    800047da:	0007871b          	sext.w	a4,a5
    800047de:	c0dc                	sw	a5,4(s1)
    800047e0:	06e04363          	bgtz	a4,80004846 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047e4:	0004a903          	lw	s2,0(s1)
    800047e8:	0094ca83          	lbu	s5,9(s1)
    800047ec:	0104ba03          	ld	s4,16(s1)
    800047f0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047f4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047f8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047fc:	0001d517          	auipc	a0,0x1d
    80004800:	1bc50513          	addi	a0,a0,444 # 800219b8 <ftable>
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	480080e7          	jalr	1152(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    8000480c:	4785                	li	a5,1
    8000480e:	04f90d63          	beq	s2,a5,80004868 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004812:	3979                	addiw	s2,s2,-2
    80004814:	4785                	li	a5,1
    80004816:	0527e063          	bltu	a5,s2,80004856 <fileclose+0xa8>
    begin_op();
    8000481a:	00000097          	auipc	ra,0x0
    8000481e:	acc080e7          	jalr	-1332(ra) # 800042e6 <begin_op>
    iput(ff.ip);
    80004822:	854e                	mv	a0,s3
    80004824:	fffff097          	auipc	ra,0xfffff
    80004828:	2a0080e7          	jalr	672(ra) # 80003ac4 <iput>
    end_op();
    8000482c:	00000097          	auipc	ra,0x0
    80004830:	b38080e7          	jalr	-1224(ra) # 80004364 <end_op>
    80004834:	a00d                	j	80004856 <fileclose+0xa8>
    panic("fileclose");
    80004836:	00004517          	auipc	a0,0x4
    8000483a:	f4250513          	addi	a0,a0,-190 # 80008778 <syscalls+0x270>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	cfc080e7          	jalr	-772(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004846:	0001d517          	auipc	a0,0x1d
    8000484a:	17250513          	addi	a0,a0,370 # 800219b8 <ftable>
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	436080e7          	jalr	1078(ra) # 80000c84 <release>
  }
}
    80004856:	70e2                	ld	ra,56(sp)
    80004858:	7442                	ld	s0,48(sp)
    8000485a:	74a2                	ld	s1,40(sp)
    8000485c:	7902                	ld	s2,32(sp)
    8000485e:	69e2                	ld	s3,24(sp)
    80004860:	6a42                	ld	s4,16(sp)
    80004862:	6aa2                	ld	s5,8(sp)
    80004864:	6121                	addi	sp,sp,64
    80004866:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004868:	85d6                	mv	a1,s5
    8000486a:	8552                	mv	a0,s4
    8000486c:	00000097          	auipc	ra,0x0
    80004870:	34c080e7          	jalr	844(ra) # 80004bb8 <pipeclose>
    80004874:	b7cd                	j	80004856 <fileclose+0xa8>

0000000080004876 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004876:	715d                	addi	sp,sp,-80
    80004878:	e486                	sd	ra,72(sp)
    8000487a:	e0a2                	sd	s0,64(sp)
    8000487c:	fc26                	sd	s1,56(sp)
    8000487e:	f84a                	sd	s2,48(sp)
    80004880:	f44e                	sd	s3,40(sp)
    80004882:	0880                	addi	s0,sp,80
    80004884:	84aa                	mv	s1,a0
    80004886:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004888:	ffffd097          	auipc	ra,0xffffd
    8000488c:	10e080e7          	jalr	270(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004890:	409c                	lw	a5,0(s1)
    80004892:	37f9                	addiw	a5,a5,-2
    80004894:	4705                	li	a4,1
    80004896:	04f76763          	bltu	a4,a5,800048e4 <filestat+0x6e>
    8000489a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000489c:	6c88                	ld	a0,24(s1)
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	06c080e7          	jalr	108(ra) # 8000390a <ilock>
    stati(f->ip, &st);
    800048a6:	fb840593          	addi	a1,s0,-72
    800048aa:	6c88                	ld	a0,24(s1)
    800048ac:	fffff097          	auipc	ra,0xfffff
    800048b0:	2e8080e7          	jalr	744(ra) # 80003b94 <stati>
    iunlock(f->ip);
    800048b4:	6c88                	ld	a0,24(s1)
    800048b6:	fffff097          	auipc	ra,0xfffff
    800048ba:	116080e7          	jalr	278(ra) # 800039cc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048be:	46e1                	li	a3,24
    800048c0:	fb840613          	addi	a2,s0,-72
    800048c4:	85ce                	mv	a1,s3
    800048c6:	05093503          	ld	a0,80(s2)
    800048ca:	ffffd097          	auipc	ra,0xffffd
    800048ce:	d90080e7          	jalr	-624(ra) # 8000165a <copyout>
    800048d2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048d6:	60a6                	ld	ra,72(sp)
    800048d8:	6406                	ld	s0,64(sp)
    800048da:	74e2                	ld	s1,56(sp)
    800048dc:	7942                	ld	s2,48(sp)
    800048de:	79a2                	ld	s3,40(sp)
    800048e0:	6161                	addi	sp,sp,80
    800048e2:	8082                	ret
  return -1;
    800048e4:	557d                	li	a0,-1
    800048e6:	bfc5                	j	800048d6 <filestat+0x60>

00000000800048e8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048e8:	7179                	addi	sp,sp,-48
    800048ea:	f406                	sd	ra,40(sp)
    800048ec:	f022                	sd	s0,32(sp)
    800048ee:	ec26                	sd	s1,24(sp)
    800048f0:	e84a                	sd	s2,16(sp)
    800048f2:	e44e                	sd	s3,8(sp)
    800048f4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048f6:	00854783          	lbu	a5,8(a0)
    800048fa:	c3d5                	beqz	a5,8000499e <fileread+0xb6>
    800048fc:	84aa                	mv	s1,a0
    800048fe:	89ae                	mv	s3,a1
    80004900:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004902:	411c                	lw	a5,0(a0)
    80004904:	4705                	li	a4,1
    80004906:	04e78963          	beq	a5,a4,80004958 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000490a:	470d                	li	a4,3
    8000490c:	04e78d63          	beq	a5,a4,80004966 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004910:	4709                	li	a4,2
    80004912:	06e79e63          	bne	a5,a4,8000498e <fileread+0xa6>
    ilock(f->ip);
    80004916:	6d08                	ld	a0,24(a0)
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	ff2080e7          	jalr	-14(ra) # 8000390a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004920:	874a                	mv	a4,s2
    80004922:	5094                	lw	a3,32(s1)
    80004924:	864e                	mv	a2,s3
    80004926:	4585                	li	a1,1
    80004928:	6c88                	ld	a0,24(s1)
    8000492a:	fffff097          	auipc	ra,0xfffff
    8000492e:	294080e7          	jalr	660(ra) # 80003bbe <readi>
    80004932:	892a                	mv	s2,a0
    80004934:	00a05563          	blez	a0,8000493e <fileread+0x56>
      f->off += r;
    80004938:	509c                	lw	a5,32(s1)
    8000493a:	9fa9                	addw	a5,a5,a0
    8000493c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000493e:	6c88                	ld	a0,24(s1)
    80004940:	fffff097          	auipc	ra,0xfffff
    80004944:	08c080e7          	jalr	140(ra) # 800039cc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004948:	854a                	mv	a0,s2
    8000494a:	70a2                	ld	ra,40(sp)
    8000494c:	7402                	ld	s0,32(sp)
    8000494e:	64e2                	ld	s1,24(sp)
    80004950:	6942                	ld	s2,16(sp)
    80004952:	69a2                	ld	s3,8(sp)
    80004954:	6145                	addi	sp,sp,48
    80004956:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004958:	6908                	ld	a0,16(a0)
    8000495a:	00000097          	auipc	ra,0x0
    8000495e:	3c0080e7          	jalr	960(ra) # 80004d1a <piperead>
    80004962:	892a                	mv	s2,a0
    80004964:	b7d5                	j	80004948 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004966:	02451783          	lh	a5,36(a0)
    8000496a:	03079693          	slli	a3,a5,0x30
    8000496e:	92c1                	srli	a3,a3,0x30
    80004970:	4725                	li	a4,9
    80004972:	02d76863          	bltu	a4,a3,800049a2 <fileread+0xba>
    80004976:	0792                	slli	a5,a5,0x4
    80004978:	0001d717          	auipc	a4,0x1d
    8000497c:	fa070713          	addi	a4,a4,-96 # 80021918 <devsw>
    80004980:	97ba                	add	a5,a5,a4
    80004982:	639c                	ld	a5,0(a5)
    80004984:	c38d                	beqz	a5,800049a6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004986:	4505                	li	a0,1
    80004988:	9782                	jalr	a5
    8000498a:	892a                	mv	s2,a0
    8000498c:	bf75                	j	80004948 <fileread+0x60>
    panic("fileread");
    8000498e:	00004517          	auipc	a0,0x4
    80004992:	dfa50513          	addi	a0,a0,-518 # 80008788 <syscalls+0x280>
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	ba4080e7          	jalr	-1116(ra) # 8000053a <panic>
    return -1;
    8000499e:	597d                	li	s2,-1
    800049a0:	b765                	j	80004948 <fileread+0x60>
      return -1;
    800049a2:	597d                	li	s2,-1
    800049a4:	b755                	j	80004948 <fileread+0x60>
    800049a6:	597d                	li	s2,-1
    800049a8:	b745                	j	80004948 <fileread+0x60>

00000000800049aa <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049aa:	715d                	addi	sp,sp,-80
    800049ac:	e486                	sd	ra,72(sp)
    800049ae:	e0a2                	sd	s0,64(sp)
    800049b0:	fc26                	sd	s1,56(sp)
    800049b2:	f84a                	sd	s2,48(sp)
    800049b4:	f44e                	sd	s3,40(sp)
    800049b6:	f052                	sd	s4,32(sp)
    800049b8:	ec56                	sd	s5,24(sp)
    800049ba:	e85a                	sd	s6,16(sp)
    800049bc:	e45e                	sd	s7,8(sp)
    800049be:	e062                	sd	s8,0(sp)
    800049c0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049c2:	00954783          	lbu	a5,9(a0)
    800049c6:	10078663          	beqz	a5,80004ad2 <filewrite+0x128>
    800049ca:	892a                	mv	s2,a0
    800049cc:	8b2e                	mv	s6,a1
    800049ce:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049d0:	411c                	lw	a5,0(a0)
    800049d2:	4705                	li	a4,1
    800049d4:	02e78263          	beq	a5,a4,800049f8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049d8:	470d                	li	a4,3
    800049da:	02e78663          	beq	a5,a4,80004a06 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049de:	4709                	li	a4,2
    800049e0:	0ee79163          	bne	a5,a4,80004ac2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049e4:	0ac05d63          	blez	a2,80004a9e <filewrite+0xf4>
    int i = 0;
    800049e8:	4981                	li	s3,0
    800049ea:	6b85                	lui	s7,0x1
    800049ec:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800049f0:	6c05                	lui	s8,0x1
    800049f2:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800049f6:	a861                	j	80004a8e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049f8:	6908                	ld	a0,16(a0)
    800049fa:	00000097          	auipc	ra,0x0
    800049fe:	22e080e7          	jalr	558(ra) # 80004c28 <pipewrite>
    80004a02:	8a2a                	mv	s4,a0
    80004a04:	a045                	j	80004aa4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a06:	02451783          	lh	a5,36(a0)
    80004a0a:	03079693          	slli	a3,a5,0x30
    80004a0e:	92c1                	srli	a3,a3,0x30
    80004a10:	4725                	li	a4,9
    80004a12:	0cd76263          	bltu	a4,a3,80004ad6 <filewrite+0x12c>
    80004a16:	0792                	slli	a5,a5,0x4
    80004a18:	0001d717          	auipc	a4,0x1d
    80004a1c:	f0070713          	addi	a4,a4,-256 # 80021918 <devsw>
    80004a20:	97ba                	add	a5,a5,a4
    80004a22:	679c                	ld	a5,8(a5)
    80004a24:	cbdd                	beqz	a5,80004ada <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a26:	4505                	li	a0,1
    80004a28:	9782                	jalr	a5
    80004a2a:	8a2a                	mv	s4,a0
    80004a2c:	a8a5                	j	80004aa4 <filewrite+0xfa>
    80004a2e:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a32:	00000097          	auipc	ra,0x0
    80004a36:	8b4080e7          	jalr	-1868(ra) # 800042e6 <begin_op>
      ilock(f->ip);
    80004a3a:	01893503          	ld	a0,24(s2)
    80004a3e:	fffff097          	auipc	ra,0xfffff
    80004a42:	ecc080e7          	jalr	-308(ra) # 8000390a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a46:	8756                	mv	a4,s5
    80004a48:	02092683          	lw	a3,32(s2)
    80004a4c:	01698633          	add	a2,s3,s6
    80004a50:	4585                	li	a1,1
    80004a52:	01893503          	ld	a0,24(s2)
    80004a56:	fffff097          	auipc	ra,0xfffff
    80004a5a:	260080e7          	jalr	608(ra) # 80003cb6 <writei>
    80004a5e:	84aa                	mv	s1,a0
    80004a60:	00a05763          	blez	a0,80004a6e <filewrite+0xc4>
        f->off += r;
    80004a64:	02092783          	lw	a5,32(s2)
    80004a68:	9fa9                	addw	a5,a5,a0
    80004a6a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a6e:	01893503          	ld	a0,24(s2)
    80004a72:	fffff097          	auipc	ra,0xfffff
    80004a76:	f5a080e7          	jalr	-166(ra) # 800039cc <iunlock>
      end_op();
    80004a7a:	00000097          	auipc	ra,0x0
    80004a7e:	8ea080e7          	jalr	-1814(ra) # 80004364 <end_op>

      if(r != n1){
    80004a82:	009a9f63          	bne	s5,s1,80004aa0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a86:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a8a:	0149db63          	bge	s3,s4,80004aa0 <filewrite+0xf6>
      int n1 = n - i;
    80004a8e:	413a04bb          	subw	s1,s4,s3
    80004a92:	0004879b          	sext.w	a5,s1
    80004a96:	f8fbdce3          	bge	s7,a5,80004a2e <filewrite+0x84>
    80004a9a:	84e2                	mv	s1,s8
    80004a9c:	bf49                	j	80004a2e <filewrite+0x84>
    int i = 0;
    80004a9e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004aa0:	013a1f63          	bne	s4,s3,80004abe <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004aa4:	8552                	mv	a0,s4
    80004aa6:	60a6                	ld	ra,72(sp)
    80004aa8:	6406                	ld	s0,64(sp)
    80004aaa:	74e2                	ld	s1,56(sp)
    80004aac:	7942                	ld	s2,48(sp)
    80004aae:	79a2                	ld	s3,40(sp)
    80004ab0:	7a02                	ld	s4,32(sp)
    80004ab2:	6ae2                	ld	s5,24(sp)
    80004ab4:	6b42                	ld	s6,16(sp)
    80004ab6:	6ba2                	ld	s7,8(sp)
    80004ab8:	6c02                	ld	s8,0(sp)
    80004aba:	6161                	addi	sp,sp,80
    80004abc:	8082                	ret
    ret = (i == n ? n : -1);
    80004abe:	5a7d                	li	s4,-1
    80004ac0:	b7d5                	j	80004aa4 <filewrite+0xfa>
    panic("filewrite");
    80004ac2:	00004517          	auipc	a0,0x4
    80004ac6:	cd650513          	addi	a0,a0,-810 # 80008798 <syscalls+0x290>
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	a70080e7          	jalr	-1424(ra) # 8000053a <panic>
    return -1;
    80004ad2:	5a7d                	li	s4,-1
    80004ad4:	bfc1                	j	80004aa4 <filewrite+0xfa>
      return -1;
    80004ad6:	5a7d                	li	s4,-1
    80004ad8:	b7f1                	j	80004aa4 <filewrite+0xfa>
    80004ada:	5a7d                	li	s4,-1
    80004adc:	b7e1                	j	80004aa4 <filewrite+0xfa>

0000000080004ade <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ade:	7179                	addi	sp,sp,-48
    80004ae0:	f406                	sd	ra,40(sp)
    80004ae2:	f022                	sd	s0,32(sp)
    80004ae4:	ec26                	sd	s1,24(sp)
    80004ae6:	e84a                	sd	s2,16(sp)
    80004ae8:	e44e                	sd	s3,8(sp)
    80004aea:	e052                	sd	s4,0(sp)
    80004aec:	1800                	addi	s0,sp,48
    80004aee:	84aa                	mv	s1,a0
    80004af0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004af2:	0005b023          	sd	zero,0(a1)
    80004af6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004afa:	00000097          	auipc	ra,0x0
    80004afe:	bf8080e7          	jalr	-1032(ra) # 800046f2 <filealloc>
    80004b02:	e088                	sd	a0,0(s1)
    80004b04:	c551                	beqz	a0,80004b90 <pipealloc+0xb2>
    80004b06:	00000097          	auipc	ra,0x0
    80004b0a:	bec080e7          	jalr	-1044(ra) # 800046f2 <filealloc>
    80004b0e:	00aa3023          	sd	a0,0(s4)
    80004b12:	c92d                	beqz	a0,80004b84 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	fcc080e7          	jalr	-52(ra) # 80000ae0 <kalloc>
    80004b1c:	892a                	mv	s2,a0
    80004b1e:	c125                	beqz	a0,80004b7e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b20:	4985                	li	s3,1
    80004b22:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b26:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b2a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b2e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b32:	00004597          	auipc	a1,0x4
    80004b36:	c7658593          	addi	a1,a1,-906 # 800087a8 <syscalls+0x2a0>
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	006080e7          	jalr	6(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004b42:	609c                	ld	a5,0(s1)
    80004b44:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b48:	609c                	ld	a5,0(s1)
    80004b4a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b4e:	609c                	ld	a5,0(s1)
    80004b50:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b54:	609c                	ld	a5,0(s1)
    80004b56:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b5a:	000a3783          	ld	a5,0(s4)
    80004b5e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b62:	000a3783          	ld	a5,0(s4)
    80004b66:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b6a:	000a3783          	ld	a5,0(s4)
    80004b6e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b72:	000a3783          	ld	a5,0(s4)
    80004b76:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b7a:	4501                	li	a0,0
    80004b7c:	a025                	j	80004ba4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b7e:	6088                	ld	a0,0(s1)
    80004b80:	e501                	bnez	a0,80004b88 <pipealloc+0xaa>
    80004b82:	a039                	j	80004b90 <pipealloc+0xb2>
    80004b84:	6088                	ld	a0,0(s1)
    80004b86:	c51d                	beqz	a0,80004bb4 <pipealloc+0xd6>
    fileclose(*f0);
    80004b88:	00000097          	auipc	ra,0x0
    80004b8c:	c26080e7          	jalr	-986(ra) # 800047ae <fileclose>
  if(*f1)
    80004b90:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b94:	557d                	li	a0,-1
  if(*f1)
    80004b96:	c799                	beqz	a5,80004ba4 <pipealloc+0xc6>
    fileclose(*f1);
    80004b98:	853e                	mv	a0,a5
    80004b9a:	00000097          	auipc	ra,0x0
    80004b9e:	c14080e7          	jalr	-1004(ra) # 800047ae <fileclose>
  return -1;
    80004ba2:	557d                	li	a0,-1
}
    80004ba4:	70a2                	ld	ra,40(sp)
    80004ba6:	7402                	ld	s0,32(sp)
    80004ba8:	64e2                	ld	s1,24(sp)
    80004baa:	6942                	ld	s2,16(sp)
    80004bac:	69a2                	ld	s3,8(sp)
    80004bae:	6a02                	ld	s4,0(sp)
    80004bb0:	6145                	addi	sp,sp,48
    80004bb2:	8082                	ret
  return -1;
    80004bb4:	557d                	li	a0,-1
    80004bb6:	b7fd                	j	80004ba4 <pipealloc+0xc6>

0000000080004bb8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bb8:	1101                	addi	sp,sp,-32
    80004bba:	ec06                	sd	ra,24(sp)
    80004bbc:	e822                	sd	s0,16(sp)
    80004bbe:	e426                	sd	s1,8(sp)
    80004bc0:	e04a                	sd	s2,0(sp)
    80004bc2:	1000                	addi	s0,sp,32
    80004bc4:	84aa                	mv	s1,a0
    80004bc6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	008080e7          	jalr	8(ra) # 80000bd0 <acquire>
  if(writable){
    80004bd0:	02090d63          	beqz	s2,80004c0a <pipeclose+0x52>
    pi->writeopen = 0;
    80004bd4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bd8:	21848513          	addi	a0,s1,536
    80004bdc:	ffffd097          	auipc	ra,0xffffd
    80004be0:	632080e7          	jalr	1586(ra) # 8000220e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004be4:	2204b783          	ld	a5,544(s1)
    80004be8:	eb95                	bnez	a5,80004c1c <pipeclose+0x64>
    release(&pi->lock);
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	098080e7          	jalr	152(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	dec080e7          	jalr	-532(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004bfe:	60e2                	ld	ra,24(sp)
    80004c00:	6442                	ld	s0,16(sp)
    80004c02:	64a2                	ld	s1,8(sp)
    80004c04:	6902                	ld	s2,0(sp)
    80004c06:	6105                	addi	sp,sp,32
    80004c08:	8082                	ret
    pi->readopen = 0;
    80004c0a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c0e:	21c48513          	addi	a0,s1,540
    80004c12:	ffffd097          	auipc	ra,0xffffd
    80004c16:	5fc080e7          	jalr	1532(ra) # 8000220e <wakeup>
    80004c1a:	b7e9                	j	80004be4 <pipeclose+0x2c>
    release(&pi->lock);
    80004c1c:	8526                	mv	a0,s1
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	066080e7          	jalr	102(ra) # 80000c84 <release>
}
    80004c26:	bfe1                	j	80004bfe <pipeclose+0x46>

0000000080004c28 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c28:	711d                	addi	sp,sp,-96
    80004c2a:	ec86                	sd	ra,88(sp)
    80004c2c:	e8a2                	sd	s0,80(sp)
    80004c2e:	e4a6                	sd	s1,72(sp)
    80004c30:	e0ca                	sd	s2,64(sp)
    80004c32:	fc4e                	sd	s3,56(sp)
    80004c34:	f852                	sd	s4,48(sp)
    80004c36:	f456                	sd	s5,40(sp)
    80004c38:	f05a                	sd	s6,32(sp)
    80004c3a:	ec5e                	sd	s7,24(sp)
    80004c3c:	e862                	sd	s8,16(sp)
    80004c3e:	1080                	addi	s0,sp,96
    80004c40:	84aa                	mv	s1,a0
    80004c42:	8aae                	mv	s5,a1
    80004c44:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	d50080e7          	jalr	-688(ra) # 80001996 <myproc>
    80004c4e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c50:	8526                	mv	a0,s1
    80004c52:	ffffc097          	auipc	ra,0xffffc
    80004c56:	f7e080e7          	jalr	-130(ra) # 80000bd0 <acquire>
  while(i < n){
    80004c5a:	0b405363          	blez	s4,80004d00 <pipewrite+0xd8>
  int i = 0;
    80004c5e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c60:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c62:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c66:	21c48b93          	addi	s7,s1,540
    80004c6a:	a089                	j	80004cac <pipewrite+0x84>
      release(&pi->lock);
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	016080e7          	jalr	22(ra) # 80000c84 <release>
      return -1;
    80004c76:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c78:	854a                	mv	a0,s2
    80004c7a:	60e6                	ld	ra,88(sp)
    80004c7c:	6446                	ld	s0,80(sp)
    80004c7e:	64a6                	ld	s1,72(sp)
    80004c80:	6906                	ld	s2,64(sp)
    80004c82:	79e2                	ld	s3,56(sp)
    80004c84:	7a42                	ld	s4,48(sp)
    80004c86:	7aa2                	ld	s5,40(sp)
    80004c88:	7b02                	ld	s6,32(sp)
    80004c8a:	6be2                	ld	s7,24(sp)
    80004c8c:	6c42                	ld	s8,16(sp)
    80004c8e:	6125                	addi	sp,sp,96
    80004c90:	8082                	ret
      wakeup(&pi->nread);
    80004c92:	8562                	mv	a0,s8
    80004c94:	ffffd097          	auipc	ra,0xffffd
    80004c98:	57a080e7          	jalr	1402(ra) # 8000220e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c9c:	85a6                	mv	a1,s1
    80004c9e:	855e                	mv	a0,s7
    80004ca0:	ffffd097          	auipc	ra,0xffffd
    80004ca4:	3e2080e7          	jalr	994(ra) # 80002082 <sleep>
  while(i < n){
    80004ca8:	05495d63          	bge	s2,s4,80004d02 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004cac:	2204a783          	lw	a5,544(s1)
    80004cb0:	dfd5                	beqz	a5,80004c6c <pipewrite+0x44>
    80004cb2:	0289a783          	lw	a5,40(s3)
    80004cb6:	fbdd                	bnez	a5,80004c6c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004cb8:	2184a783          	lw	a5,536(s1)
    80004cbc:	21c4a703          	lw	a4,540(s1)
    80004cc0:	2007879b          	addiw	a5,a5,512
    80004cc4:	fcf707e3          	beq	a4,a5,80004c92 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cc8:	4685                	li	a3,1
    80004cca:	01590633          	add	a2,s2,s5
    80004cce:	faf40593          	addi	a1,s0,-81
    80004cd2:	0509b503          	ld	a0,80(s3)
    80004cd6:	ffffd097          	auipc	ra,0xffffd
    80004cda:	a10080e7          	jalr	-1520(ra) # 800016e6 <copyin>
    80004cde:	03650263          	beq	a0,s6,80004d02 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ce2:	21c4a783          	lw	a5,540(s1)
    80004ce6:	0017871b          	addiw	a4,a5,1
    80004cea:	20e4ae23          	sw	a4,540(s1)
    80004cee:	1ff7f793          	andi	a5,a5,511
    80004cf2:	97a6                	add	a5,a5,s1
    80004cf4:	faf44703          	lbu	a4,-81(s0)
    80004cf8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cfc:	2905                	addiw	s2,s2,1
    80004cfe:	b76d                	j	80004ca8 <pipewrite+0x80>
  int i = 0;
    80004d00:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004d02:	21848513          	addi	a0,s1,536
    80004d06:	ffffd097          	auipc	ra,0xffffd
    80004d0a:	508080e7          	jalr	1288(ra) # 8000220e <wakeup>
  release(&pi->lock);
    80004d0e:	8526                	mv	a0,s1
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	f74080e7          	jalr	-140(ra) # 80000c84 <release>
  return i;
    80004d18:	b785                	j	80004c78 <pipewrite+0x50>

0000000080004d1a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d1a:	715d                	addi	sp,sp,-80
    80004d1c:	e486                	sd	ra,72(sp)
    80004d1e:	e0a2                	sd	s0,64(sp)
    80004d20:	fc26                	sd	s1,56(sp)
    80004d22:	f84a                	sd	s2,48(sp)
    80004d24:	f44e                	sd	s3,40(sp)
    80004d26:	f052                	sd	s4,32(sp)
    80004d28:	ec56                	sd	s5,24(sp)
    80004d2a:	e85a                	sd	s6,16(sp)
    80004d2c:	0880                	addi	s0,sp,80
    80004d2e:	84aa                	mv	s1,a0
    80004d30:	892e                	mv	s2,a1
    80004d32:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	c62080e7          	jalr	-926(ra) # 80001996 <myproc>
    80004d3c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d3e:	8526                	mv	a0,s1
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	e90080e7          	jalr	-368(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d48:	2184a703          	lw	a4,536(s1)
    80004d4c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d50:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d54:	02f71463          	bne	a4,a5,80004d7c <piperead+0x62>
    80004d58:	2244a783          	lw	a5,548(s1)
    80004d5c:	c385                	beqz	a5,80004d7c <piperead+0x62>
    if(pr->killed){
    80004d5e:	028a2783          	lw	a5,40(s4)
    80004d62:	ebc9                	bnez	a5,80004df4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d64:	85a6                	mv	a1,s1
    80004d66:	854e                	mv	a0,s3
    80004d68:	ffffd097          	auipc	ra,0xffffd
    80004d6c:	31a080e7          	jalr	794(ra) # 80002082 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d70:	2184a703          	lw	a4,536(s1)
    80004d74:	21c4a783          	lw	a5,540(s1)
    80004d78:	fef700e3          	beq	a4,a5,80004d58 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d7c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d7e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d80:	05505463          	blez	s5,80004dc8 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004d84:	2184a783          	lw	a5,536(s1)
    80004d88:	21c4a703          	lw	a4,540(s1)
    80004d8c:	02f70e63          	beq	a4,a5,80004dc8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d90:	0017871b          	addiw	a4,a5,1
    80004d94:	20e4ac23          	sw	a4,536(s1)
    80004d98:	1ff7f793          	andi	a5,a5,511
    80004d9c:	97a6                	add	a5,a5,s1
    80004d9e:	0187c783          	lbu	a5,24(a5)
    80004da2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004da6:	4685                	li	a3,1
    80004da8:	fbf40613          	addi	a2,s0,-65
    80004dac:	85ca                	mv	a1,s2
    80004dae:	050a3503          	ld	a0,80(s4)
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	8a8080e7          	jalr	-1880(ra) # 8000165a <copyout>
    80004dba:	01650763          	beq	a0,s6,80004dc8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dbe:	2985                	addiw	s3,s3,1
    80004dc0:	0905                	addi	s2,s2,1
    80004dc2:	fd3a91e3          	bne	s5,s3,80004d84 <piperead+0x6a>
    80004dc6:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004dc8:	21c48513          	addi	a0,s1,540
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	442080e7          	jalr	1090(ra) # 8000220e <wakeup>
  release(&pi->lock);
    80004dd4:	8526                	mv	a0,s1
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	eae080e7          	jalr	-338(ra) # 80000c84 <release>
  return i;
}
    80004dde:	854e                	mv	a0,s3
    80004de0:	60a6                	ld	ra,72(sp)
    80004de2:	6406                	ld	s0,64(sp)
    80004de4:	74e2                	ld	s1,56(sp)
    80004de6:	7942                	ld	s2,48(sp)
    80004de8:	79a2                	ld	s3,40(sp)
    80004dea:	7a02                	ld	s4,32(sp)
    80004dec:	6ae2                	ld	s5,24(sp)
    80004dee:	6b42                	ld	s6,16(sp)
    80004df0:	6161                	addi	sp,sp,80
    80004df2:	8082                	ret
      release(&pi->lock);
    80004df4:	8526                	mv	a0,s1
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	e8e080e7          	jalr	-370(ra) # 80000c84 <release>
      return -1;
    80004dfe:	59fd                	li	s3,-1
    80004e00:	bff9                	j	80004dde <piperead+0xc4>

0000000080004e02 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e02:	de010113          	addi	sp,sp,-544
    80004e06:	20113c23          	sd	ra,536(sp)
    80004e0a:	20813823          	sd	s0,528(sp)
    80004e0e:	20913423          	sd	s1,520(sp)
    80004e12:	21213023          	sd	s2,512(sp)
    80004e16:	ffce                	sd	s3,504(sp)
    80004e18:	fbd2                	sd	s4,496(sp)
    80004e1a:	f7d6                	sd	s5,488(sp)
    80004e1c:	f3da                	sd	s6,480(sp)
    80004e1e:	efde                	sd	s7,472(sp)
    80004e20:	ebe2                	sd	s8,464(sp)
    80004e22:	e7e6                	sd	s9,456(sp)
    80004e24:	e3ea                	sd	s10,448(sp)
    80004e26:	ff6e                	sd	s11,440(sp)
    80004e28:	1400                	addi	s0,sp,544
    80004e2a:	892a                	mv	s2,a0
    80004e2c:	dea43423          	sd	a0,-536(s0)
    80004e30:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	b62080e7          	jalr	-1182(ra) # 80001996 <myproc>
    80004e3c:	84aa                	mv	s1,a0

  begin_op();
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	4a8080e7          	jalr	1192(ra) # 800042e6 <begin_op>

  if((ip = namei(path)) == 0){
    80004e46:	854a                	mv	a0,s2
    80004e48:	fffff097          	auipc	ra,0xfffff
    80004e4c:	27e080e7          	jalr	638(ra) # 800040c6 <namei>
    80004e50:	c93d                	beqz	a0,80004ec6 <exec+0xc4>
    80004e52:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	ab6080e7          	jalr	-1354(ra) # 8000390a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e5c:	04000713          	li	a4,64
    80004e60:	4681                	li	a3,0
    80004e62:	e5040613          	addi	a2,s0,-432
    80004e66:	4581                	li	a1,0
    80004e68:	8556                	mv	a0,s5
    80004e6a:	fffff097          	auipc	ra,0xfffff
    80004e6e:	d54080e7          	jalr	-684(ra) # 80003bbe <readi>
    80004e72:	04000793          	li	a5,64
    80004e76:	00f51a63          	bne	a0,a5,80004e8a <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e7a:	e5042703          	lw	a4,-432(s0)
    80004e7e:	464c47b7          	lui	a5,0x464c4
    80004e82:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e86:	04f70663          	beq	a4,a5,80004ed2 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e8a:	8556                	mv	a0,s5
    80004e8c:	fffff097          	auipc	ra,0xfffff
    80004e90:	ce0080e7          	jalr	-800(ra) # 80003b6c <iunlockput>
    end_op();
    80004e94:	fffff097          	auipc	ra,0xfffff
    80004e98:	4d0080e7          	jalr	1232(ra) # 80004364 <end_op>
  }
  return -1;
    80004e9c:	557d                	li	a0,-1
}
    80004e9e:	21813083          	ld	ra,536(sp)
    80004ea2:	21013403          	ld	s0,528(sp)
    80004ea6:	20813483          	ld	s1,520(sp)
    80004eaa:	20013903          	ld	s2,512(sp)
    80004eae:	79fe                	ld	s3,504(sp)
    80004eb0:	7a5e                	ld	s4,496(sp)
    80004eb2:	7abe                	ld	s5,488(sp)
    80004eb4:	7b1e                	ld	s6,480(sp)
    80004eb6:	6bfe                	ld	s7,472(sp)
    80004eb8:	6c5e                	ld	s8,464(sp)
    80004eba:	6cbe                	ld	s9,456(sp)
    80004ebc:	6d1e                	ld	s10,448(sp)
    80004ebe:	7dfa                	ld	s11,440(sp)
    80004ec0:	22010113          	addi	sp,sp,544
    80004ec4:	8082                	ret
    end_op();
    80004ec6:	fffff097          	auipc	ra,0xfffff
    80004eca:	49e080e7          	jalr	1182(ra) # 80004364 <end_op>
    return -1;
    80004ece:	557d                	li	a0,-1
    80004ed0:	b7f9                	j	80004e9e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ed2:	8526                	mv	a0,s1
    80004ed4:	ffffd097          	auipc	ra,0xffffd
    80004ed8:	ba2080e7          	jalr	-1118(ra) # 80001a76 <proc_pagetable>
    80004edc:	8b2a                	mv	s6,a0
    80004ede:	d555                	beqz	a0,80004e8a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ee0:	e7042783          	lw	a5,-400(s0)
    80004ee4:	e8845703          	lhu	a4,-376(s0)
    80004ee8:	c735                	beqz	a4,80004f54 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eea:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eec:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004ef0:	6a05                	lui	s4,0x1
    80004ef2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ef6:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004efa:	6d85                	lui	s11,0x1
    80004efc:	7d7d                	lui	s10,0xfffff
    80004efe:	ac1d                	j	80005134 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f00:	00004517          	auipc	a0,0x4
    80004f04:	8b050513          	addi	a0,a0,-1872 # 800087b0 <syscalls+0x2a8>
    80004f08:	ffffb097          	auipc	ra,0xffffb
    80004f0c:	632080e7          	jalr	1586(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f10:	874a                	mv	a4,s2
    80004f12:	009c86bb          	addw	a3,s9,s1
    80004f16:	4581                	li	a1,0
    80004f18:	8556                	mv	a0,s5
    80004f1a:	fffff097          	auipc	ra,0xfffff
    80004f1e:	ca4080e7          	jalr	-860(ra) # 80003bbe <readi>
    80004f22:	2501                	sext.w	a0,a0
    80004f24:	1aa91863          	bne	s2,a0,800050d4 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004f28:	009d84bb          	addw	s1,s11,s1
    80004f2c:	013d09bb          	addw	s3,s10,s3
    80004f30:	1f74f263          	bgeu	s1,s7,80005114 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004f34:	02049593          	slli	a1,s1,0x20
    80004f38:	9181                	srli	a1,a1,0x20
    80004f3a:	95e2                	add	a1,a1,s8
    80004f3c:	855a                	mv	a0,s6
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	114080e7          	jalr	276(ra) # 80001052 <walkaddr>
    80004f46:	862a                	mv	a2,a0
    if(pa == 0)
    80004f48:	dd45                	beqz	a0,80004f00 <exec+0xfe>
      n = PGSIZE;
    80004f4a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f4c:	fd49f2e3          	bgeu	s3,s4,80004f10 <exec+0x10e>
      n = sz - i;
    80004f50:	894e                	mv	s2,s3
    80004f52:	bf7d                	j	80004f10 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f54:	4481                	li	s1,0
  iunlockput(ip);
    80004f56:	8556                	mv	a0,s5
    80004f58:	fffff097          	auipc	ra,0xfffff
    80004f5c:	c14080e7          	jalr	-1004(ra) # 80003b6c <iunlockput>
  end_op();
    80004f60:	fffff097          	auipc	ra,0xfffff
    80004f64:	404080e7          	jalr	1028(ra) # 80004364 <end_op>
  p = myproc();
    80004f68:	ffffd097          	auipc	ra,0xffffd
    80004f6c:	a2e080e7          	jalr	-1490(ra) # 80001996 <myproc>
    80004f70:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f72:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f76:	6785                	lui	a5,0x1
    80004f78:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004f7a:	97a6                	add	a5,a5,s1
    80004f7c:	777d                	lui	a4,0xfffff
    80004f7e:	8ff9                	and	a5,a5,a4
    80004f80:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f84:	6609                	lui	a2,0x2
    80004f86:	963e                	add	a2,a2,a5
    80004f88:	85be                	mv	a1,a5
    80004f8a:	855a                	mv	a0,s6
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	47a080e7          	jalr	1146(ra) # 80001406 <uvmalloc>
    80004f94:	8c2a                	mv	s8,a0
  ip = 0;
    80004f96:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f98:	12050e63          	beqz	a0,800050d4 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f9c:	75f9                	lui	a1,0xffffe
    80004f9e:	95aa                	add	a1,a1,a0
    80004fa0:	855a                	mv	a0,s6
    80004fa2:	ffffc097          	auipc	ra,0xffffc
    80004fa6:	686080e7          	jalr	1670(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80004faa:	7afd                	lui	s5,0xfffff
    80004fac:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fae:	df043783          	ld	a5,-528(s0)
    80004fb2:	6388                	ld	a0,0(a5)
    80004fb4:	c925                	beqz	a0,80005024 <exec+0x222>
    80004fb6:	e9040993          	addi	s3,s0,-368
    80004fba:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004fbe:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fc0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	e86080e7          	jalr	-378(ra) # 80000e48 <strlen>
    80004fca:	0015079b          	addiw	a5,a0,1
    80004fce:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fd2:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004fd6:	13596363          	bltu	s2,s5,800050fc <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fda:	df043d83          	ld	s11,-528(s0)
    80004fde:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004fe2:	8552                	mv	a0,s4
    80004fe4:	ffffc097          	auipc	ra,0xffffc
    80004fe8:	e64080e7          	jalr	-412(ra) # 80000e48 <strlen>
    80004fec:	0015069b          	addiw	a3,a0,1
    80004ff0:	8652                	mv	a2,s4
    80004ff2:	85ca                	mv	a1,s2
    80004ff4:	855a                	mv	a0,s6
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	664080e7          	jalr	1636(ra) # 8000165a <copyout>
    80004ffe:	10054363          	bltz	a0,80005104 <exec+0x302>
    ustack[argc] = sp;
    80005002:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005006:	0485                	addi	s1,s1,1
    80005008:	008d8793          	addi	a5,s11,8
    8000500c:	def43823          	sd	a5,-528(s0)
    80005010:	008db503          	ld	a0,8(s11)
    80005014:	c911                	beqz	a0,80005028 <exec+0x226>
    if(argc >= MAXARG)
    80005016:	09a1                	addi	s3,s3,8
    80005018:	fb3c95e3          	bne	s9,s3,80004fc2 <exec+0x1c0>
  sz = sz1;
    8000501c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005020:	4a81                	li	s5,0
    80005022:	a84d                	j	800050d4 <exec+0x2d2>
  sp = sz;
    80005024:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005026:	4481                	li	s1,0
  ustack[argc] = 0;
    80005028:	00349793          	slli	a5,s1,0x3
    8000502c:	f9078793          	addi	a5,a5,-112
    80005030:	97a2                	add	a5,a5,s0
    80005032:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005036:	00148693          	addi	a3,s1,1
    8000503a:	068e                	slli	a3,a3,0x3
    8000503c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005040:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005044:	01597663          	bgeu	s2,s5,80005050 <exec+0x24e>
  sz = sz1;
    80005048:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000504c:	4a81                	li	s5,0
    8000504e:	a059                	j	800050d4 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005050:	e9040613          	addi	a2,s0,-368
    80005054:	85ca                	mv	a1,s2
    80005056:	855a                	mv	a0,s6
    80005058:	ffffc097          	auipc	ra,0xffffc
    8000505c:	602080e7          	jalr	1538(ra) # 8000165a <copyout>
    80005060:	0a054663          	bltz	a0,8000510c <exec+0x30a>
  p->trapframe->a1 = sp;
    80005064:	058bb783          	ld	a5,88(s7)
    80005068:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000506c:	de843783          	ld	a5,-536(s0)
    80005070:	0007c703          	lbu	a4,0(a5)
    80005074:	cf11                	beqz	a4,80005090 <exec+0x28e>
    80005076:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005078:	02f00693          	li	a3,47
    8000507c:	a039                	j	8000508a <exec+0x288>
      last = s+1;
    8000507e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005082:	0785                	addi	a5,a5,1
    80005084:	fff7c703          	lbu	a4,-1(a5)
    80005088:	c701                	beqz	a4,80005090 <exec+0x28e>
    if(*s == '/')
    8000508a:	fed71ce3          	bne	a4,a3,80005082 <exec+0x280>
    8000508e:	bfc5                	j	8000507e <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005090:	4641                	li	a2,16
    80005092:	de843583          	ld	a1,-536(s0)
    80005096:	158b8513          	addi	a0,s7,344
    8000509a:	ffffc097          	auipc	ra,0xffffc
    8000509e:	d7c080e7          	jalr	-644(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800050a2:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800050a6:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800050aa:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050ae:	058bb783          	ld	a5,88(s7)
    800050b2:	e6843703          	ld	a4,-408(s0)
    800050b6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050b8:	058bb783          	ld	a5,88(s7)
    800050bc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050c0:	85ea                	mv	a1,s10
    800050c2:	ffffd097          	auipc	ra,0xffffd
    800050c6:	a50080e7          	jalr	-1456(ra) # 80001b12 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050ca:	0004851b          	sext.w	a0,s1
    800050ce:	bbc1                	j	80004e9e <exec+0x9c>
    800050d0:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800050d4:	df843583          	ld	a1,-520(s0)
    800050d8:	855a                	mv	a0,s6
    800050da:	ffffd097          	auipc	ra,0xffffd
    800050de:	a38080e7          	jalr	-1480(ra) # 80001b12 <proc_freepagetable>
  if(ip){
    800050e2:	da0a94e3          	bnez	s5,80004e8a <exec+0x88>
  return -1;
    800050e6:	557d                	li	a0,-1
    800050e8:	bb5d                	j	80004e9e <exec+0x9c>
    800050ea:	de943c23          	sd	s1,-520(s0)
    800050ee:	b7dd                	j	800050d4 <exec+0x2d2>
    800050f0:	de943c23          	sd	s1,-520(s0)
    800050f4:	b7c5                	j	800050d4 <exec+0x2d2>
    800050f6:	de943c23          	sd	s1,-520(s0)
    800050fa:	bfe9                	j	800050d4 <exec+0x2d2>
  sz = sz1;
    800050fc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005100:	4a81                	li	s5,0
    80005102:	bfc9                	j	800050d4 <exec+0x2d2>
  sz = sz1;
    80005104:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005108:	4a81                	li	s5,0
    8000510a:	b7e9                	j	800050d4 <exec+0x2d2>
  sz = sz1;
    8000510c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005110:	4a81                	li	s5,0
    80005112:	b7c9                	j	800050d4 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005114:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005118:	e0843783          	ld	a5,-504(s0)
    8000511c:	0017869b          	addiw	a3,a5,1
    80005120:	e0d43423          	sd	a3,-504(s0)
    80005124:	e0043783          	ld	a5,-512(s0)
    80005128:	0387879b          	addiw	a5,a5,56
    8000512c:	e8845703          	lhu	a4,-376(s0)
    80005130:	e2e6d3e3          	bge	a3,a4,80004f56 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005134:	2781                	sext.w	a5,a5
    80005136:	e0f43023          	sd	a5,-512(s0)
    8000513a:	03800713          	li	a4,56
    8000513e:	86be                	mv	a3,a5
    80005140:	e1840613          	addi	a2,s0,-488
    80005144:	4581                	li	a1,0
    80005146:	8556                	mv	a0,s5
    80005148:	fffff097          	auipc	ra,0xfffff
    8000514c:	a76080e7          	jalr	-1418(ra) # 80003bbe <readi>
    80005150:	03800793          	li	a5,56
    80005154:	f6f51ee3          	bne	a0,a5,800050d0 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005158:	e1842783          	lw	a5,-488(s0)
    8000515c:	4705                	li	a4,1
    8000515e:	fae79de3          	bne	a5,a4,80005118 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005162:	e4043603          	ld	a2,-448(s0)
    80005166:	e3843783          	ld	a5,-456(s0)
    8000516a:	f8f660e3          	bltu	a2,a5,800050ea <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000516e:	e2843783          	ld	a5,-472(s0)
    80005172:	963e                	add	a2,a2,a5
    80005174:	f6f66ee3          	bltu	a2,a5,800050f0 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005178:	85a6                	mv	a1,s1
    8000517a:	855a                	mv	a0,s6
    8000517c:	ffffc097          	auipc	ra,0xffffc
    80005180:	28a080e7          	jalr	650(ra) # 80001406 <uvmalloc>
    80005184:	dea43c23          	sd	a0,-520(s0)
    80005188:	d53d                	beqz	a0,800050f6 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    8000518a:	e2843c03          	ld	s8,-472(s0)
    8000518e:	de043783          	ld	a5,-544(s0)
    80005192:	00fc77b3          	and	a5,s8,a5
    80005196:	ff9d                	bnez	a5,800050d4 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005198:	e2042c83          	lw	s9,-480(s0)
    8000519c:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051a0:	f60b8ae3          	beqz	s7,80005114 <exec+0x312>
    800051a4:	89de                	mv	s3,s7
    800051a6:	4481                	li	s1,0
    800051a8:	b371                	j	80004f34 <exec+0x132>

00000000800051aa <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051aa:	7179                	addi	sp,sp,-48
    800051ac:	f406                	sd	ra,40(sp)
    800051ae:	f022                	sd	s0,32(sp)
    800051b0:	ec26                	sd	s1,24(sp)
    800051b2:	e84a                	sd	s2,16(sp)
    800051b4:	1800                	addi	s0,sp,48
    800051b6:	892e                	mv	s2,a1
    800051b8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051ba:	fdc40593          	addi	a1,s0,-36
    800051be:	ffffe097          	auipc	ra,0xffffe
    800051c2:	ade080e7          	jalr	-1314(ra) # 80002c9c <argint>
    800051c6:	04054063          	bltz	a0,80005206 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051ca:	fdc42703          	lw	a4,-36(s0)
    800051ce:	47bd                	li	a5,15
    800051d0:	02e7ed63          	bltu	a5,a4,8000520a <argfd+0x60>
    800051d4:	ffffc097          	auipc	ra,0xffffc
    800051d8:	7c2080e7          	jalr	1986(ra) # 80001996 <myproc>
    800051dc:	fdc42703          	lw	a4,-36(s0)
    800051e0:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    800051e4:	078e                	slli	a5,a5,0x3
    800051e6:	953e                	add	a0,a0,a5
    800051e8:	611c                	ld	a5,0(a0)
    800051ea:	c395                	beqz	a5,8000520e <argfd+0x64>
    return -1;
  if(pfd)
    800051ec:	00090463          	beqz	s2,800051f4 <argfd+0x4a>
    *pfd = fd;
    800051f0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051f4:	4501                	li	a0,0
  if(pf)
    800051f6:	c091                	beqz	s1,800051fa <argfd+0x50>
    *pf = f;
    800051f8:	e09c                	sd	a5,0(s1)
}
    800051fa:	70a2                	ld	ra,40(sp)
    800051fc:	7402                	ld	s0,32(sp)
    800051fe:	64e2                	ld	s1,24(sp)
    80005200:	6942                	ld	s2,16(sp)
    80005202:	6145                	addi	sp,sp,48
    80005204:	8082                	ret
    return -1;
    80005206:	557d                	li	a0,-1
    80005208:	bfcd                	j	800051fa <argfd+0x50>
    return -1;
    8000520a:	557d                	li	a0,-1
    8000520c:	b7fd                	j	800051fa <argfd+0x50>
    8000520e:	557d                	li	a0,-1
    80005210:	b7ed                	j	800051fa <argfd+0x50>

0000000080005212 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005212:	1101                	addi	sp,sp,-32
    80005214:	ec06                	sd	ra,24(sp)
    80005216:	e822                	sd	s0,16(sp)
    80005218:	e426                	sd	s1,8(sp)
    8000521a:	1000                	addi	s0,sp,32
    8000521c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000521e:	ffffc097          	auipc	ra,0xffffc
    80005222:	778080e7          	jalr	1912(ra) # 80001996 <myproc>
    80005226:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005228:	0d050793          	addi	a5,a0,208
    8000522c:	4501                	li	a0,0
    8000522e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005230:	6398                	ld	a4,0(a5)
    80005232:	cb19                	beqz	a4,80005248 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005234:	2505                	addiw	a0,a0,1
    80005236:	07a1                	addi	a5,a5,8
    80005238:	fed51ce3          	bne	a0,a3,80005230 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000523c:	557d                	li	a0,-1
}
    8000523e:	60e2                	ld	ra,24(sp)
    80005240:	6442                	ld	s0,16(sp)
    80005242:	64a2                	ld	s1,8(sp)
    80005244:	6105                	addi	sp,sp,32
    80005246:	8082                	ret
      p->ofile[fd] = f;
    80005248:	01a50793          	addi	a5,a0,26
    8000524c:	078e                	slli	a5,a5,0x3
    8000524e:	963e                	add	a2,a2,a5
    80005250:	e204                	sd	s1,0(a2)
      return fd;
    80005252:	b7f5                	j	8000523e <fdalloc+0x2c>

0000000080005254 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005254:	715d                	addi	sp,sp,-80
    80005256:	e486                	sd	ra,72(sp)
    80005258:	e0a2                	sd	s0,64(sp)
    8000525a:	fc26                	sd	s1,56(sp)
    8000525c:	f84a                	sd	s2,48(sp)
    8000525e:	f44e                	sd	s3,40(sp)
    80005260:	f052                	sd	s4,32(sp)
    80005262:	ec56                	sd	s5,24(sp)
    80005264:	0880                	addi	s0,sp,80
    80005266:	89ae                	mv	s3,a1
    80005268:	8ab2                	mv	s5,a2
    8000526a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000526c:	fb040593          	addi	a1,s0,-80
    80005270:	fffff097          	auipc	ra,0xfffff
    80005274:	e74080e7          	jalr	-396(ra) # 800040e4 <nameiparent>
    80005278:	892a                	mv	s2,a0
    8000527a:	12050e63          	beqz	a0,800053b6 <create+0x162>
    return 0;

  ilock(dp);
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	68c080e7          	jalr	1676(ra) # 8000390a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005286:	4601                	li	a2,0
    80005288:	fb040593          	addi	a1,s0,-80
    8000528c:	854a                	mv	a0,s2
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	b60080e7          	jalr	-1184(ra) # 80003dee <dirlookup>
    80005296:	84aa                	mv	s1,a0
    80005298:	c921                	beqz	a0,800052e8 <create+0x94>
    iunlockput(dp);
    8000529a:	854a                	mv	a0,s2
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	8d0080e7          	jalr	-1840(ra) # 80003b6c <iunlockput>
    ilock(ip);
    800052a4:	8526                	mv	a0,s1
    800052a6:	ffffe097          	auipc	ra,0xffffe
    800052aa:	664080e7          	jalr	1636(ra) # 8000390a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052ae:	2981                	sext.w	s3,s3
    800052b0:	4789                	li	a5,2
    800052b2:	02f99463          	bne	s3,a5,800052da <create+0x86>
    800052b6:	0444d783          	lhu	a5,68(s1)
    800052ba:	37f9                	addiw	a5,a5,-2
    800052bc:	17c2                	slli	a5,a5,0x30
    800052be:	93c1                	srli	a5,a5,0x30
    800052c0:	4705                	li	a4,1
    800052c2:	00f76c63          	bltu	a4,a5,800052da <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052c6:	8526                	mv	a0,s1
    800052c8:	60a6                	ld	ra,72(sp)
    800052ca:	6406                	ld	s0,64(sp)
    800052cc:	74e2                	ld	s1,56(sp)
    800052ce:	7942                	ld	s2,48(sp)
    800052d0:	79a2                	ld	s3,40(sp)
    800052d2:	7a02                	ld	s4,32(sp)
    800052d4:	6ae2                	ld	s5,24(sp)
    800052d6:	6161                	addi	sp,sp,80
    800052d8:	8082                	ret
    iunlockput(ip);
    800052da:	8526                	mv	a0,s1
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	890080e7          	jalr	-1904(ra) # 80003b6c <iunlockput>
    return 0;
    800052e4:	4481                	li	s1,0
    800052e6:	b7c5                	j	800052c6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052e8:	85ce                	mv	a1,s3
    800052ea:	00092503          	lw	a0,0(s2)
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	482080e7          	jalr	1154(ra) # 80003770 <ialloc>
    800052f6:	84aa                	mv	s1,a0
    800052f8:	c521                	beqz	a0,80005340 <create+0xec>
  ilock(ip);
    800052fa:	ffffe097          	auipc	ra,0xffffe
    800052fe:	610080e7          	jalr	1552(ra) # 8000390a <ilock>
  ip->major = major;
    80005302:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005306:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000530a:	4a05                	li	s4,1
    8000530c:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005310:	8526                	mv	a0,s1
    80005312:	ffffe097          	auipc	ra,0xffffe
    80005316:	52c080e7          	jalr	1324(ra) # 8000383e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000531a:	2981                	sext.w	s3,s3
    8000531c:	03498a63          	beq	s3,s4,80005350 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005320:	40d0                	lw	a2,4(s1)
    80005322:	fb040593          	addi	a1,s0,-80
    80005326:	854a                	mv	a0,s2
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	cdc080e7          	jalr	-804(ra) # 80004004 <dirlink>
    80005330:	06054b63          	bltz	a0,800053a6 <create+0x152>
  iunlockput(dp);
    80005334:	854a                	mv	a0,s2
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	836080e7          	jalr	-1994(ra) # 80003b6c <iunlockput>
  return ip;
    8000533e:	b761                	j	800052c6 <create+0x72>
    panic("create: ialloc");
    80005340:	00003517          	auipc	a0,0x3
    80005344:	49050513          	addi	a0,a0,1168 # 800087d0 <syscalls+0x2c8>
    80005348:	ffffb097          	auipc	ra,0xffffb
    8000534c:	1f2080e7          	jalr	498(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    80005350:	04a95783          	lhu	a5,74(s2)
    80005354:	2785                	addiw	a5,a5,1
    80005356:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000535a:	854a                	mv	a0,s2
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	4e2080e7          	jalr	1250(ra) # 8000383e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005364:	40d0                	lw	a2,4(s1)
    80005366:	00003597          	auipc	a1,0x3
    8000536a:	47a58593          	addi	a1,a1,1146 # 800087e0 <syscalls+0x2d8>
    8000536e:	8526                	mv	a0,s1
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	c94080e7          	jalr	-876(ra) # 80004004 <dirlink>
    80005378:	00054f63          	bltz	a0,80005396 <create+0x142>
    8000537c:	00492603          	lw	a2,4(s2)
    80005380:	00003597          	auipc	a1,0x3
    80005384:	46858593          	addi	a1,a1,1128 # 800087e8 <syscalls+0x2e0>
    80005388:	8526                	mv	a0,s1
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	c7a080e7          	jalr	-902(ra) # 80004004 <dirlink>
    80005392:	f80557e3          	bgez	a0,80005320 <create+0xcc>
      panic("create dots");
    80005396:	00003517          	auipc	a0,0x3
    8000539a:	45a50513          	addi	a0,a0,1114 # 800087f0 <syscalls+0x2e8>
    8000539e:	ffffb097          	auipc	ra,0xffffb
    800053a2:	19c080e7          	jalr	412(ra) # 8000053a <panic>
    panic("create: dirlink");
    800053a6:	00003517          	auipc	a0,0x3
    800053aa:	45a50513          	addi	a0,a0,1114 # 80008800 <syscalls+0x2f8>
    800053ae:	ffffb097          	auipc	ra,0xffffb
    800053b2:	18c080e7          	jalr	396(ra) # 8000053a <panic>
    return 0;
    800053b6:	84aa                	mv	s1,a0
    800053b8:	b739                	j	800052c6 <create+0x72>

00000000800053ba <sys_dup>:
{
    800053ba:	7179                	addi	sp,sp,-48
    800053bc:	f406                	sd	ra,40(sp)
    800053be:	f022                	sd	s0,32(sp)
    800053c0:	ec26                	sd	s1,24(sp)
    800053c2:	e84a                	sd	s2,16(sp)
    800053c4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053c6:	fd840613          	addi	a2,s0,-40
    800053ca:	4581                	li	a1,0
    800053cc:	4501                	li	a0,0
    800053ce:	00000097          	auipc	ra,0x0
    800053d2:	ddc080e7          	jalr	-548(ra) # 800051aa <argfd>
    return -1;
    800053d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053d8:	02054363          	bltz	a0,800053fe <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800053dc:	fd843903          	ld	s2,-40(s0)
    800053e0:	854a                	mv	a0,s2
    800053e2:	00000097          	auipc	ra,0x0
    800053e6:	e30080e7          	jalr	-464(ra) # 80005212 <fdalloc>
    800053ea:	84aa                	mv	s1,a0
    return -1;
    800053ec:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053ee:	00054863          	bltz	a0,800053fe <sys_dup+0x44>
  filedup(f);
    800053f2:	854a                	mv	a0,s2
    800053f4:	fffff097          	auipc	ra,0xfffff
    800053f8:	368080e7          	jalr	872(ra) # 8000475c <filedup>
  return fd;
    800053fc:	87a6                	mv	a5,s1
}
    800053fe:	853e                	mv	a0,a5
    80005400:	70a2                	ld	ra,40(sp)
    80005402:	7402                	ld	s0,32(sp)
    80005404:	64e2                	ld	s1,24(sp)
    80005406:	6942                	ld	s2,16(sp)
    80005408:	6145                	addi	sp,sp,48
    8000540a:	8082                	ret

000000008000540c <sys_read>:
{
    8000540c:	7179                	addi	sp,sp,-48
    8000540e:	f406                	sd	ra,40(sp)
    80005410:	f022                	sd	s0,32(sp)
    80005412:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005414:	fe840613          	addi	a2,s0,-24
    80005418:	4581                	li	a1,0
    8000541a:	4501                	li	a0,0
    8000541c:	00000097          	auipc	ra,0x0
    80005420:	d8e080e7          	jalr	-626(ra) # 800051aa <argfd>
    return -1;
    80005424:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005426:	04054163          	bltz	a0,80005468 <sys_read+0x5c>
    8000542a:	fe440593          	addi	a1,s0,-28
    8000542e:	4509                	li	a0,2
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	86c080e7          	jalr	-1940(ra) # 80002c9c <argint>
    return -1;
    80005438:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000543a:	02054763          	bltz	a0,80005468 <sys_read+0x5c>
    8000543e:	fd840593          	addi	a1,s0,-40
    80005442:	4505                	li	a0,1
    80005444:	ffffe097          	auipc	ra,0xffffe
    80005448:	87a080e7          	jalr	-1926(ra) # 80002cbe <argaddr>
    return -1;
    8000544c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544e:	00054d63          	bltz	a0,80005468 <sys_read+0x5c>
  return fileread(f, p, n);
    80005452:	fe442603          	lw	a2,-28(s0)
    80005456:	fd843583          	ld	a1,-40(s0)
    8000545a:	fe843503          	ld	a0,-24(s0)
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	48a080e7          	jalr	1162(ra) # 800048e8 <fileread>
    80005466:	87aa                	mv	a5,a0
}
    80005468:	853e                	mv	a0,a5
    8000546a:	70a2                	ld	ra,40(sp)
    8000546c:	7402                	ld	s0,32(sp)
    8000546e:	6145                	addi	sp,sp,48
    80005470:	8082                	ret

0000000080005472 <sys_write>:
{
    80005472:	7179                	addi	sp,sp,-48
    80005474:	f406                	sd	ra,40(sp)
    80005476:	f022                	sd	s0,32(sp)
    80005478:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547a:	fe840613          	addi	a2,s0,-24
    8000547e:	4581                	li	a1,0
    80005480:	4501                	li	a0,0
    80005482:	00000097          	auipc	ra,0x0
    80005486:	d28080e7          	jalr	-728(ra) # 800051aa <argfd>
    return -1;
    8000548a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000548c:	04054163          	bltz	a0,800054ce <sys_write+0x5c>
    80005490:	fe440593          	addi	a1,s0,-28
    80005494:	4509                	li	a0,2
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	806080e7          	jalr	-2042(ra) # 80002c9c <argint>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a0:	02054763          	bltz	a0,800054ce <sys_write+0x5c>
    800054a4:	fd840593          	addi	a1,s0,-40
    800054a8:	4505                	li	a0,1
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	814080e7          	jalr	-2028(ra) # 80002cbe <argaddr>
    return -1;
    800054b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b4:	00054d63          	bltz	a0,800054ce <sys_write+0x5c>
  return filewrite(f, p, n);
    800054b8:	fe442603          	lw	a2,-28(s0)
    800054bc:	fd843583          	ld	a1,-40(s0)
    800054c0:	fe843503          	ld	a0,-24(s0)
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	4e6080e7          	jalr	1254(ra) # 800049aa <filewrite>
    800054cc:	87aa                	mv	a5,a0
}
    800054ce:	853e                	mv	a0,a5
    800054d0:	70a2                	ld	ra,40(sp)
    800054d2:	7402                	ld	s0,32(sp)
    800054d4:	6145                	addi	sp,sp,48
    800054d6:	8082                	ret

00000000800054d8 <sys_close>:
{
    800054d8:	1101                	addi	sp,sp,-32
    800054da:	ec06                	sd	ra,24(sp)
    800054dc:	e822                	sd	s0,16(sp)
    800054de:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054e0:	fe040613          	addi	a2,s0,-32
    800054e4:	fec40593          	addi	a1,s0,-20
    800054e8:	4501                	li	a0,0
    800054ea:	00000097          	auipc	ra,0x0
    800054ee:	cc0080e7          	jalr	-832(ra) # 800051aa <argfd>
    return -1;
    800054f2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054f4:	02054463          	bltz	a0,8000551c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054f8:	ffffc097          	auipc	ra,0xffffc
    800054fc:	49e080e7          	jalr	1182(ra) # 80001996 <myproc>
    80005500:	fec42783          	lw	a5,-20(s0)
    80005504:	07e9                	addi	a5,a5,26
    80005506:	078e                	slli	a5,a5,0x3
    80005508:	953e                	add	a0,a0,a5
    8000550a:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000550e:	fe043503          	ld	a0,-32(s0)
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	29c080e7          	jalr	668(ra) # 800047ae <fileclose>
  return 0;
    8000551a:	4781                	li	a5,0
}
    8000551c:	853e                	mv	a0,a5
    8000551e:	60e2                	ld	ra,24(sp)
    80005520:	6442                	ld	s0,16(sp)
    80005522:	6105                	addi	sp,sp,32
    80005524:	8082                	ret

0000000080005526 <sys_fstat>:
{
    80005526:	1101                	addi	sp,sp,-32
    80005528:	ec06                	sd	ra,24(sp)
    8000552a:	e822                	sd	s0,16(sp)
    8000552c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000552e:	fe840613          	addi	a2,s0,-24
    80005532:	4581                	li	a1,0
    80005534:	4501                	li	a0,0
    80005536:	00000097          	auipc	ra,0x0
    8000553a:	c74080e7          	jalr	-908(ra) # 800051aa <argfd>
    return -1;
    8000553e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005540:	02054563          	bltz	a0,8000556a <sys_fstat+0x44>
    80005544:	fe040593          	addi	a1,s0,-32
    80005548:	4505                	li	a0,1
    8000554a:	ffffd097          	auipc	ra,0xffffd
    8000554e:	774080e7          	jalr	1908(ra) # 80002cbe <argaddr>
    return -1;
    80005552:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005554:	00054b63          	bltz	a0,8000556a <sys_fstat+0x44>
  return filestat(f, st);
    80005558:	fe043583          	ld	a1,-32(s0)
    8000555c:	fe843503          	ld	a0,-24(s0)
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	316080e7          	jalr	790(ra) # 80004876 <filestat>
    80005568:	87aa                	mv	a5,a0
}
    8000556a:	853e                	mv	a0,a5
    8000556c:	60e2                	ld	ra,24(sp)
    8000556e:	6442                	ld	s0,16(sp)
    80005570:	6105                	addi	sp,sp,32
    80005572:	8082                	ret

0000000080005574 <sys_link>:
{
    80005574:	7169                	addi	sp,sp,-304
    80005576:	f606                	sd	ra,296(sp)
    80005578:	f222                	sd	s0,288(sp)
    8000557a:	ee26                	sd	s1,280(sp)
    8000557c:	ea4a                	sd	s2,272(sp)
    8000557e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005580:	08000613          	li	a2,128
    80005584:	ed040593          	addi	a1,s0,-304
    80005588:	4501                	li	a0,0
    8000558a:	ffffd097          	auipc	ra,0xffffd
    8000558e:	756080e7          	jalr	1878(ra) # 80002ce0 <argstr>
    return -1;
    80005592:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005594:	10054e63          	bltz	a0,800056b0 <sys_link+0x13c>
    80005598:	08000613          	li	a2,128
    8000559c:	f5040593          	addi	a1,s0,-176
    800055a0:	4505                	li	a0,1
    800055a2:	ffffd097          	auipc	ra,0xffffd
    800055a6:	73e080e7          	jalr	1854(ra) # 80002ce0 <argstr>
    return -1;
    800055aa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ac:	10054263          	bltz	a0,800056b0 <sys_link+0x13c>
  begin_op();
    800055b0:	fffff097          	auipc	ra,0xfffff
    800055b4:	d36080e7          	jalr	-714(ra) # 800042e6 <begin_op>
  if((ip = namei(old)) == 0){
    800055b8:	ed040513          	addi	a0,s0,-304
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	b0a080e7          	jalr	-1270(ra) # 800040c6 <namei>
    800055c4:	84aa                	mv	s1,a0
    800055c6:	c551                	beqz	a0,80005652 <sys_link+0xde>
  ilock(ip);
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	342080e7          	jalr	834(ra) # 8000390a <ilock>
  if(ip->type == T_DIR){
    800055d0:	04449703          	lh	a4,68(s1)
    800055d4:	4785                	li	a5,1
    800055d6:	08f70463          	beq	a4,a5,8000565e <sys_link+0xea>
  ip->nlink++;
    800055da:	04a4d783          	lhu	a5,74(s1)
    800055de:	2785                	addiw	a5,a5,1
    800055e0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055e4:	8526                	mv	a0,s1
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	258080e7          	jalr	600(ra) # 8000383e <iupdate>
  iunlock(ip);
    800055ee:	8526                	mv	a0,s1
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	3dc080e7          	jalr	988(ra) # 800039cc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055f8:	fd040593          	addi	a1,s0,-48
    800055fc:	f5040513          	addi	a0,s0,-176
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	ae4080e7          	jalr	-1308(ra) # 800040e4 <nameiparent>
    80005608:	892a                	mv	s2,a0
    8000560a:	c935                	beqz	a0,8000567e <sys_link+0x10a>
  ilock(dp);
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	2fe080e7          	jalr	766(ra) # 8000390a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005614:	00092703          	lw	a4,0(s2)
    80005618:	409c                	lw	a5,0(s1)
    8000561a:	04f71d63          	bne	a4,a5,80005674 <sys_link+0x100>
    8000561e:	40d0                	lw	a2,4(s1)
    80005620:	fd040593          	addi	a1,s0,-48
    80005624:	854a                	mv	a0,s2
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	9de080e7          	jalr	-1570(ra) # 80004004 <dirlink>
    8000562e:	04054363          	bltz	a0,80005674 <sys_link+0x100>
  iunlockput(dp);
    80005632:	854a                	mv	a0,s2
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	538080e7          	jalr	1336(ra) # 80003b6c <iunlockput>
  iput(ip);
    8000563c:	8526                	mv	a0,s1
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	486080e7          	jalr	1158(ra) # 80003ac4 <iput>
  end_op();
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	d1e080e7          	jalr	-738(ra) # 80004364 <end_op>
  return 0;
    8000564e:	4781                	li	a5,0
    80005650:	a085                	j	800056b0 <sys_link+0x13c>
    end_op();
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	d12080e7          	jalr	-750(ra) # 80004364 <end_op>
    return -1;
    8000565a:	57fd                	li	a5,-1
    8000565c:	a891                	j	800056b0 <sys_link+0x13c>
    iunlockput(ip);
    8000565e:	8526                	mv	a0,s1
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	50c080e7          	jalr	1292(ra) # 80003b6c <iunlockput>
    end_op();
    80005668:	fffff097          	auipc	ra,0xfffff
    8000566c:	cfc080e7          	jalr	-772(ra) # 80004364 <end_op>
    return -1;
    80005670:	57fd                	li	a5,-1
    80005672:	a83d                	j	800056b0 <sys_link+0x13c>
    iunlockput(dp);
    80005674:	854a                	mv	a0,s2
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	4f6080e7          	jalr	1270(ra) # 80003b6c <iunlockput>
  ilock(ip);
    8000567e:	8526                	mv	a0,s1
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	28a080e7          	jalr	650(ra) # 8000390a <ilock>
  ip->nlink--;
    80005688:	04a4d783          	lhu	a5,74(s1)
    8000568c:	37fd                	addiw	a5,a5,-1
    8000568e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005692:	8526                	mv	a0,s1
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	1aa080e7          	jalr	426(ra) # 8000383e <iupdate>
  iunlockput(ip);
    8000569c:	8526                	mv	a0,s1
    8000569e:	ffffe097          	auipc	ra,0xffffe
    800056a2:	4ce080e7          	jalr	1230(ra) # 80003b6c <iunlockput>
  end_op();
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	cbe080e7          	jalr	-834(ra) # 80004364 <end_op>
  return -1;
    800056ae:	57fd                	li	a5,-1
}
    800056b0:	853e                	mv	a0,a5
    800056b2:	70b2                	ld	ra,296(sp)
    800056b4:	7412                	ld	s0,288(sp)
    800056b6:	64f2                	ld	s1,280(sp)
    800056b8:	6952                	ld	s2,272(sp)
    800056ba:	6155                	addi	sp,sp,304
    800056bc:	8082                	ret

00000000800056be <sys_unlink>:
{
    800056be:	7151                	addi	sp,sp,-240
    800056c0:	f586                	sd	ra,232(sp)
    800056c2:	f1a2                	sd	s0,224(sp)
    800056c4:	eda6                	sd	s1,216(sp)
    800056c6:	e9ca                	sd	s2,208(sp)
    800056c8:	e5ce                	sd	s3,200(sp)
    800056ca:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056cc:	08000613          	li	a2,128
    800056d0:	f3040593          	addi	a1,s0,-208
    800056d4:	4501                	li	a0,0
    800056d6:	ffffd097          	auipc	ra,0xffffd
    800056da:	60a080e7          	jalr	1546(ra) # 80002ce0 <argstr>
    800056de:	18054163          	bltz	a0,80005860 <sys_unlink+0x1a2>
  begin_op();
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	c04080e7          	jalr	-1020(ra) # 800042e6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056ea:	fb040593          	addi	a1,s0,-80
    800056ee:	f3040513          	addi	a0,s0,-208
    800056f2:	fffff097          	auipc	ra,0xfffff
    800056f6:	9f2080e7          	jalr	-1550(ra) # 800040e4 <nameiparent>
    800056fa:	84aa                	mv	s1,a0
    800056fc:	c979                	beqz	a0,800057d2 <sys_unlink+0x114>
  ilock(dp);
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	20c080e7          	jalr	524(ra) # 8000390a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005706:	00003597          	auipc	a1,0x3
    8000570a:	0da58593          	addi	a1,a1,218 # 800087e0 <syscalls+0x2d8>
    8000570e:	fb040513          	addi	a0,s0,-80
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	6c2080e7          	jalr	1730(ra) # 80003dd4 <namecmp>
    8000571a:	14050a63          	beqz	a0,8000586e <sys_unlink+0x1b0>
    8000571e:	00003597          	auipc	a1,0x3
    80005722:	0ca58593          	addi	a1,a1,202 # 800087e8 <syscalls+0x2e0>
    80005726:	fb040513          	addi	a0,s0,-80
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	6aa080e7          	jalr	1706(ra) # 80003dd4 <namecmp>
    80005732:	12050e63          	beqz	a0,8000586e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005736:	f2c40613          	addi	a2,s0,-212
    8000573a:	fb040593          	addi	a1,s0,-80
    8000573e:	8526                	mv	a0,s1
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	6ae080e7          	jalr	1710(ra) # 80003dee <dirlookup>
    80005748:	892a                	mv	s2,a0
    8000574a:	12050263          	beqz	a0,8000586e <sys_unlink+0x1b0>
  ilock(ip);
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	1bc080e7          	jalr	444(ra) # 8000390a <ilock>
  if(ip->nlink < 1)
    80005756:	04a91783          	lh	a5,74(s2)
    8000575a:	08f05263          	blez	a5,800057de <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000575e:	04491703          	lh	a4,68(s2)
    80005762:	4785                	li	a5,1
    80005764:	08f70563          	beq	a4,a5,800057ee <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005768:	4641                	li	a2,16
    8000576a:	4581                	li	a1,0
    8000576c:	fc040513          	addi	a0,s0,-64
    80005770:	ffffb097          	auipc	ra,0xffffb
    80005774:	55c080e7          	jalr	1372(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005778:	4741                	li	a4,16
    8000577a:	f2c42683          	lw	a3,-212(s0)
    8000577e:	fc040613          	addi	a2,s0,-64
    80005782:	4581                	li	a1,0
    80005784:	8526                	mv	a0,s1
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	530080e7          	jalr	1328(ra) # 80003cb6 <writei>
    8000578e:	47c1                	li	a5,16
    80005790:	0af51563          	bne	a0,a5,8000583a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005794:	04491703          	lh	a4,68(s2)
    80005798:	4785                	li	a5,1
    8000579a:	0af70863          	beq	a4,a5,8000584a <sys_unlink+0x18c>
  iunlockput(dp);
    8000579e:	8526                	mv	a0,s1
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	3cc080e7          	jalr	972(ra) # 80003b6c <iunlockput>
  ip->nlink--;
    800057a8:	04a95783          	lhu	a5,74(s2)
    800057ac:	37fd                	addiw	a5,a5,-1
    800057ae:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057b2:	854a                	mv	a0,s2
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	08a080e7          	jalr	138(ra) # 8000383e <iupdate>
  iunlockput(ip);
    800057bc:	854a                	mv	a0,s2
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	3ae080e7          	jalr	942(ra) # 80003b6c <iunlockput>
  end_op();
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	b9e080e7          	jalr	-1122(ra) # 80004364 <end_op>
  return 0;
    800057ce:	4501                	li	a0,0
    800057d0:	a84d                	j	80005882 <sys_unlink+0x1c4>
    end_op();
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	b92080e7          	jalr	-1134(ra) # 80004364 <end_op>
    return -1;
    800057da:	557d                	li	a0,-1
    800057dc:	a05d                	j	80005882 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057de:	00003517          	auipc	a0,0x3
    800057e2:	03250513          	addi	a0,a0,50 # 80008810 <syscalls+0x308>
    800057e6:	ffffb097          	auipc	ra,0xffffb
    800057ea:	d54080e7          	jalr	-684(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ee:	04c92703          	lw	a4,76(s2)
    800057f2:	02000793          	li	a5,32
    800057f6:	f6e7f9e3          	bgeu	a5,a4,80005768 <sys_unlink+0xaa>
    800057fa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057fe:	4741                	li	a4,16
    80005800:	86ce                	mv	a3,s3
    80005802:	f1840613          	addi	a2,s0,-232
    80005806:	4581                	li	a1,0
    80005808:	854a                	mv	a0,s2
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	3b4080e7          	jalr	948(ra) # 80003bbe <readi>
    80005812:	47c1                	li	a5,16
    80005814:	00f51b63          	bne	a0,a5,8000582a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005818:	f1845783          	lhu	a5,-232(s0)
    8000581c:	e7a1                	bnez	a5,80005864 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000581e:	29c1                	addiw	s3,s3,16
    80005820:	04c92783          	lw	a5,76(s2)
    80005824:	fcf9ede3          	bltu	s3,a5,800057fe <sys_unlink+0x140>
    80005828:	b781                	j	80005768 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000582a:	00003517          	auipc	a0,0x3
    8000582e:	ffe50513          	addi	a0,a0,-2 # 80008828 <syscalls+0x320>
    80005832:	ffffb097          	auipc	ra,0xffffb
    80005836:	d08080e7          	jalr	-760(ra) # 8000053a <panic>
    panic("unlink: writei");
    8000583a:	00003517          	auipc	a0,0x3
    8000583e:	00650513          	addi	a0,a0,6 # 80008840 <syscalls+0x338>
    80005842:	ffffb097          	auipc	ra,0xffffb
    80005846:	cf8080e7          	jalr	-776(ra) # 8000053a <panic>
    dp->nlink--;
    8000584a:	04a4d783          	lhu	a5,74(s1)
    8000584e:	37fd                	addiw	a5,a5,-1
    80005850:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005854:	8526                	mv	a0,s1
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	fe8080e7          	jalr	-24(ra) # 8000383e <iupdate>
    8000585e:	b781                	j	8000579e <sys_unlink+0xe0>
    return -1;
    80005860:	557d                	li	a0,-1
    80005862:	a005                	j	80005882 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005864:	854a                	mv	a0,s2
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	306080e7          	jalr	774(ra) # 80003b6c <iunlockput>
  iunlockput(dp);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	2fc080e7          	jalr	764(ra) # 80003b6c <iunlockput>
  end_op();
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	aec080e7          	jalr	-1300(ra) # 80004364 <end_op>
  return -1;
    80005880:	557d                	li	a0,-1
}
    80005882:	70ae                	ld	ra,232(sp)
    80005884:	740e                	ld	s0,224(sp)
    80005886:	64ee                	ld	s1,216(sp)
    80005888:	694e                	ld	s2,208(sp)
    8000588a:	69ae                	ld	s3,200(sp)
    8000588c:	616d                	addi	sp,sp,240
    8000588e:	8082                	ret

0000000080005890 <sys_open>:

uint64
sys_open(void)
{
    80005890:	7131                	addi	sp,sp,-192
    80005892:	fd06                	sd	ra,184(sp)
    80005894:	f922                	sd	s0,176(sp)
    80005896:	f526                	sd	s1,168(sp)
    80005898:	f14a                	sd	s2,160(sp)
    8000589a:	ed4e                	sd	s3,152(sp)
    8000589c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000589e:	08000613          	li	a2,128
    800058a2:	f5040593          	addi	a1,s0,-176
    800058a6:	4501                	li	a0,0
    800058a8:	ffffd097          	auipc	ra,0xffffd
    800058ac:	438080e7          	jalr	1080(ra) # 80002ce0 <argstr>
    return -1;
    800058b0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058b2:	0c054163          	bltz	a0,80005974 <sys_open+0xe4>
    800058b6:	f4c40593          	addi	a1,s0,-180
    800058ba:	4505                	li	a0,1
    800058bc:	ffffd097          	auipc	ra,0xffffd
    800058c0:	3e0080e7          	jalr	992(ra) # 80002c9c <argint>
    800058c4:	0a054863          	bltz	a0,80005974 <sys_open+0xe4>

  begin_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	a1e080e7          	jalr	-1506(ra) # 800042e6 <begin_op>

  if(omode & O_CREATE){
    800058d0:	f4c42783          	lw	a5,-180(s0)
    800058d4:	2007f793          	andi	a5,a5,512
    800058d8:	cbdd                	beqz	a5,8000598e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058da:	4681                	li	a3,0
    800058dc:	4601                	li	a2,0
    800058de:	4589                	li	a1,2
    800058e0:	f5040513          	addi	a0,s0,-176
    800058e4:	00000097          	auipc	ra,0x0
    800058e8:	970080e7          	jalr	-1680(ra) # 80005254 <create>
    800058ec:	892a                	mv	s2,a0
    if(ip == 0){
    800058ee:	c959                	beqz	a0,80005984 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058f0:	04491703          	lh	a4,68(s2)
    800058f4:	478d                	li	a5,3
    800058f6:	00f71763          	bne	a4,a5,80005904 <sys_open+0x74>
    800058fa:	04695703          	lhu	a4,70(s2)
    800058fe:	47a5                	li	a5,9
    80005900:	0ce7ec63          	bltu	a5,a4,800059d8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	dee080e7          	jalr	-530(ra) # 800046f2 <filealloc>
    8000590c:	89aa                	mv	s3,a0
    8000590e:	10050263          	beqz	a0,80005a12 <sys_open+0x182>
    80005912:	00000097          	auipc	ra,0x0
    80005916:	900080e7          	jalr	-1792(ra) # 80005212 <fdalloc>
    8000591a:	84aa                	mv	s1,a0
    8000591c:	0e054663          	bltz	a0,80005a08 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005920:	04491703          	lh	a4,68(s2)
    80005924:	478d                	li	a5,3
    80005926:	0cf70463          	beq	a4,a5,800059ee <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000592a:	4789                	li	a5,2
    8000592c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005930:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005934:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005938:	f4c42783          	lw	a5,-180(s0)
    8000593c:	0017c713          	xori	a4,a5,1
    80005940:	8b05                	andi	a4,a4,1
    80005942:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005946:	0037f713          	andi	a4,a5,3
    8000594a:	00e03733          	snez	a4,a4
    8000594e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005952:	4007f793          	andi	a5,a5,1024
    80005956:	c791                	beqz	a5,80005962 <sys_open+0xd2>
    80005958:	04491703          	lh	a4,68(s2)
    8000595c:	4789                	li	a5,2
    8000595e:	08f70f63          	beq	a4,a5,800059fc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005962:	854a                	mv	a0,s2
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	068080e7          	jalr	104(ra) # 800039cc <iunlock>
  end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	9f8080e7          	jalr	-1544(ra) # 80004364 <end_op>

  return fd;
}
    80005974:	8526                	mv	a0,s1
    80005976:	70ea                	ld	ra,184(sp)
    80005978:	744a                	ld	s0,176(sp)
    8000597a:	74aa                	ld	s1,168(sp)
    8000597c:	790a                	ld	s2,160(sp)
    8000597e:	69ea                	ld	s3,152(sp)
    80005980:	6129                	addi	sp,sp,192
    80005982:	8082                	ret
      end_op();
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	9e0080e7          	jalr	-1568(ra) # 80004364 <end_op>
      return -1;
    8000598c:	b7e5                	j	80005974 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000598e:	f5040513          	addi	a0,s0,-176
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	734080e7          	jalr	1844(ra) # 800040c6 <namei>
    8000599a:	892a                	mv	s2,a0
    8000599c:	c905                	beqz	a0,800059cc <sys_open+0x13c>
    ilock(ip);
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	f6c080e7          	jalr	-148(ra) # 8000390a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059a6:	04491703          	lh	a4,68(s2)
    800059aa:	4785                	li	a5,1
    800059ac:	f4f712e3          	bne	a4,a5,800058f0 <sys_open+0x60>
    800059b0:	f4c42783          	lw	a5,-180(s0)
    800059b4:	dba1                	beqz	a5,80005904 <sys_open+0x74>
      iunlockput(ip);
    800059b6:	854a                	mv	a0,s2
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	1b4080e7          	jalr	436(ra) # 80003b6c <iunlockput>
      end_op();
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	9a4080e7          	jalr	-1628(ra) # 80004364 <end_op>
      return -1;
    800059c8:	54fd                	li	s1,-1
    800059ca:	b76d                	j	80005974 <sys_open+0xe4>
      end_op();
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	998080e7          	jalr	-1640(ra) # 80004364 <end_op>
      return -1;
    800059d4:	54fd                	li	s1,-1
    800059d6:	bf79                	j	80005974 <sys_open+0xe4>
    iunlockput(ip);
    800059d8:	854a                	mv	a0,s2
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	192080e7          	jalr	402(ra) # 80003b6c <iunlockput>
    end_op();
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	982080e7          	jalr	-1662(ra) # 80004364 <end_op>
    return -1;
    800059ea:	54fd                	li	s1,-1
    800059ec:	b761                	j	80005974 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059ee:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059f2:	04691783          	lh	a5,70(s2)
    800059f6:	02f99223          	sh	a5,36(s3)
    800059fa:	bf2d                	j	80005934 <sys_open+0xa4>
    itrunc(ip);
    800059fc:	854a                	mv	a0,s2
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	01a080e7          	jalr	26(ra) # 80003a18 <itrunc>
    80005a06:	bfb1                	j	80005962 <sys_open+0xd2>
      fileclose(f);
    80005a08:	854e                	mv	a0,s3
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	da4080e7          	jalr	-604(ra) # 800047ae <fileclose>
    iunlockput(ip);
    80005a12:	854a                	mv	a0,s2
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	158080e7          	jalr	344(ra) # 80003b6c <iunlockput>
    end_op();
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	948080e7          	jalr	-1720(ra) # 80004364 <end_op>
    return -1;
    80005a24:	54fd                	li	s1,-1
    80005a26:	b7b9                	j	80005974 <sys_open+0xe4>

0000000080005a28 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a28:	7175                	addi	sp,sp,-144
    80005a2a:	e506                	sd	ra,136(sp)
    80005a2c:	e122                	sd	s0,128(sp)
    80005a2e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	8b6080e7          	jalr	-1866(ra) # 800042e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a38:	08000613          	li	a2,128
    80005a3c:	f7040593          	addi	a1,s0,-144
    80005a40:	4501                	li	a0,0
    80005a42:	ffffd097          	auipc	ra,0xffffd
    80005a46:	29e080e7          	jalr	670(ra) # 80002ce0 <argstr>
    80005a4a:	02054963          	bltz	a0,80005a7c <sys_mkdir+0x54>
    80005a4e:	4681                	li	a3,0
    80005a50:	4601                	li	a2,0
    80005a52:	4585                	li	a1,1
    80005a54:	f7040513          	addi	a0,s0,-144
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	7fc080e7          	jalr	2044(ra) # 80005254 <create>
    80005a60:	cd11                	beqz	a0,80005a7c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	10a080e7          	jalr	266(ra) # 80003b6c <iunlockput>
  end_op();
    80005a6a:	fffff097          	auipc	ra,0xfffff
    80005a6e:	8fa080e7          	jalr	-1798(ra) # 80004364 <end_op>
  return 0;
    80005a72:	4501                	li	a0,0
}
    80005a74:	60aa                	ld	ra,136(sp)
    80005a76:	640a                	ld	s0,128(sp)
    80005a78:	6149                	addi	sp,sp,144
    80005a7a:	8082                	ret
    end_op();
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	8e8080e7          	jalr	-1816(ra) # 80004364 <end_op>
    return -1;
    80005a84:	557d                	li	a0,-1
    80005a86:	b7fd                	j	80005a74 <sys_mkdir+0x4c>

0000000080005a88 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a88:	7135                	addi	sp,sp,-160
    80005a8a:	ed06                	sd	ra,152(sp)
    80005a8c:	e922                	sd	s0,144(sp)
    80005a8e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	856080e7          	jalr	-1962(ra) # 800042e6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a98:	08000613          	li	a2,128
    80005a9c:	f7040593          	addi	a1,s0,-144
    80005aa0:	4501                	li	a0,0
    80005aa2:	ffffd097          	auipc	ra,0xffffd
    80005aa6:	23e080e7          	jalr	574(ra) # 80002ce0 <argstr>
    80005aaa:	04054a63          	bltz	a0,80005afe <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005aae:	f6c40593          	addi	a1,s0,-148
    80005ab2:	4505                	li	a0,1
    80005ab4:	ffffd097          	auipc	ra,0xffffd
    80005ab8:	1e8080e7          	jalr	488(ra) # 80002c9c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005abc:	04054163          	bltz	a0,80005afe <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ac0:	f6840593          	addi	a1,s0,-152
    80005ac4:	4509                	li	a0,2
    80005ac6:	ffffd097          	auipc	ra,0xffffd
    80005aca:	1d6080e7          	jalr	470(ra) # 80002c9c <argint>
     argint(1, &major) < 0 ||
    80005ace:	02054863          	bltz	a0,80005afe <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ad2:	f6841683          	lh	a3,-152(s0)
    80005ad6:	f6c41603          	lh	a2,-148(s0)
    80005ada:	458d                	li	a1,3
    80005adc:	f7040513          	addi	a0,s0,-144
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	774080e7          	jalr	1908(ra) # 80005254 <create>
     argint(2, &minor) < 0 ||
    80005ae8:	c919                	beqz	a0,80005afe <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	082080e7          	jalr	130(ra) # 80003b6c <iunlockput>
  end_op();
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	872080e7          	jalr	-1934(ra) # 80004364 <end_op>
  return 0;
    80005afa:	4501                	li	a0,0
    80005afc:	a031                	j	80005b08 <sys_mknod+0x80>
    end_op();
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	866080e7          	jalr	-1946(ra) # 80004364 <end_op>
    return -1;
    80005b06:	557d                	li	a0,-1
}
    80005b08:	60ea                	ld	ra,152(sp)
    80005b0a:	644a                	ld	s0,144(sp)
    80005b0c:	610d                	addi	sp,sp,160
    80005b0e:	8082                	ret

0000000080005b10 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b10:	7135                	addi	sp,sp,-160
    80005b12:	ed06                	sd	ra,152(sp)
    80005b14:	e922                	sd	s0,144(sp)
    80005b16:	e526                	sd	s1,136(sp)
    80005b18:	e14a                	sd	s2,128(sp)
    80005b1a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b1c:	ffffc097          	auipc	ra,0xffffc
    80005b20:	e7a080e7          	jalr	-390(ra) # 80001996 <myproc>
    80005b24:	892a                	mv	s2,a0
  
  begin_op();
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	7c0080e7          	jalr	1984(ra) # 800042e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b2e:	08000613          	li	a2,128
    80005b32:	f6040593          	addi	a1,s0,-160
    80005b36:	4501                	li	a0,0
    80005b38:	ffffd097          	auipc	ra,0xffffd
    80005b3c:	1a8080e7          	jalr	424(ra) # 80002ce0 <argstr>
    80005b40:	04054b63          	bltz	a0,80005b96 <sys_chdir+0x86>
    80005b44:	f6040513          	addi	a0,s0,-160
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	57e080e7          	jalr	1406(ra) # 800040c6 <namei>
    80005b50:	84aa                	mv	s1,a0
    80005b52:	c131                	beqz	a0,80005b96 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	db6080e7          	jalr	-586(ra) # 8000390a <ilock>
  if(ip->type != T_DIR){
    80005b5c:	04449703          	lh	a4,68(s1)
    80005b60:	4785                	li	a5,1
    80005b62:	04f71063          	bne	a4,a5,80005ba2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b66:	8526                	mv	a0,s1
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	e64080e7          	jalr	-412(ra) # 800039cc <iunlock>
  iput(p->cwd);
    80005b70:	15093503          	ld	a0,336(s2)
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	f50080e7          	jalr	-176(ra) # 80003ac4 <iput>
  end_op();
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	7e8080e7          	jalr	2024(ra) # 80004364 <end_op>
  p->cwd = ip;
    80005b84:	14993823          	sd	s1,336(s2)
  return 0;
    80005b88:	4501                	li	a0,0
}
    80005b8a:	60ea                	ld	ra,152(sp)
    80005b8c:	644a                	ld	s0,144(sp)
    80005b8e:	64aa                	ld	s1,136(sp)
    80005b90:	690a                	ld	s2,128(sp)
    80005b92:	610d                	addi	sp,sp,160
    80005b94:	8082                	ret
    end_op();
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	7ce080e7          	jalr	1998(ra) # 80004364 <end_op>
    return -1;
    80005b9e:	557d                	li	a0,-1
    80005ba0:	b7ed                	j	80005b8a <sys_chdir+0x7a>
    iunlockput(ip);
    80005ba2:	8526                	mv	a0,s1
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	fc8080e7          	jalr	-56(ra) # 80003b6c <iunlockput>
    end_op();
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	7b8080e7          	jalr	1976(ra) # 80004364 <end_op>
    return -1;
    80005bb4:	557d                	li	a0,-1
    80005bb6:	bfd1                	j	80005b8a <sys_chdir+0x7a>

0000000080005bb8 <sys_exec>:

uint64
sys_exec(void)
{
    80005bb8:	7145                	addi	sp,sp,-464
    80005bba:	e786                	sd	ra,456(sp)
    80005bbc:	e3a2                	sd	s0,448(sp)
    80005bbe:	ff26                	sd	s1,440(sp)
    80005bc0:	fb4a                	sd	s2,432(sp)
    80005bc2:	f74e                	sd	s3,424(sp)
    80005bc4:	f352                	sd	s4,416(sp)
    80005bc6:	ef56                	sd	s5,408(sp)
    80005bc8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bca:	08000613          	li	a2,128
    80005bce:	f4040593          	addi	a1,s0,-192
    80005bd2:	4501                	li	a0,0
    80005bd4:	ffffd097          	auipc	ra,0xffffd
    80005bd8:	10c080e7          	jalr	268(ra) # 80002ce0 <argstr>
    return -1;
    80005bdc:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bde:	0c054b63          	bltz	a0,80005cb4 <sys_exec+0xfc>
    80005be2:	e3840593          	addi	a1,s0,-456
    80005be6:	4505                	li	a0,1
    80005be8:	ffffd097          	auipc	ra,0xffffd
    80005bec:	0d6080e7          	jalr	214(ra) # 80002cbe <argaddr>
    80005bf0:	0c054263          	bltz	a0,80005cb4 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005bf4:	10000613          	li	a2,256
    80005bf8:	4581                	li	a1,0
    80005bfa:	e4040513          	addi	a0,s0,-448
    80005bfe:	ffffb097          	auipc	ra,0xffffb
    80005c02:	0ce080e7          	jalr	206(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c06:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c0a:	89a6                	mv	s3,s1
    80005c0c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c0e:	02000a13          	li	s4,32
    80005c12:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c16:	00391513          	slli	a0,s2,0x3
    80005c1a:	e3040593          	addi	a1,s0,-464
    80005c1e:	e3843783          	ld	a5,-456(s0)
    80005c22:	953e                	add	a0,a0,a5
    80005c24:	ffffd097          	auipc	ra,0xffffd
    80005c28:	fde080e7          	jalr	-34(ra) # 80002c02 <fetchaddr>
    80005c2c:	02054a63          	bltz	a0,80005c60 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c30:	e3043783          	ld	a5,-464(s0)
    80005c34:	c3b9                	beqz	a5,80005c7a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c36:	ffffb097          	auipc	ra,0xffffb
    80005c3a:	eaa080e7          	jalr	-342(ra) # 80000ae0 <kalloc>
    80005c3e:	85aa                	mv	a1,a0
    80005c40:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c44:	cd11                	beqz	a0,80005c60 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c46:	6605                	lui	a2,0x1
    80005c48:	e3043503          	ld	a0,-464(s0)
    80005c4c:	ffffd097          	auipc	ra,0xffffd
    80005c50:	008080e7          	jalr	8(ra) # 80002c54 <fetchstr>
    80005c54:	00054663          	bltz	a0,80005c60 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c58:	0905                	addi	s2,s2,1
    80005c5a:	09a1                	addi	s3,s3,8
    80005c5c:	fb491be3          	bne	s2,s4,80005c12 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c60:	f4040913          	addi	s2,s0,-192
    80005c64:	6088                	ld	a0,0(s1)
    80005c66:	c531                	beqz	a0,80005cb2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c68:	ffffb097          	auipc	ra,0xffffb
    80005c6c:	d7a080e7          	jalr	-646(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c70:	04a1                	addi	s1,s1,8
    80005c72:	ff2499e3          	bne	s1,s2,80005c64 <sys_exec+0xac>
  return -1;
    80005c76:	597d                	li	s2,-1
    80005c78:	a835                	j	80005cb4 <sys_exec+0xfc>
      argv[i] = 0;
    80005c7a:	0a8e                	slli	s5,s5,0x3
    80005c7c:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005c80:	00878ab3          	add	s5,a5,s0
    80005c84:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c88:	e4040593          	addi	a1,s0,-448
    80005c8c:	f4040513          	addi	a0,s0,-192
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	172080e7          	jalr	370(ra) # 80004e02 <exec>
    80005c98:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c9a:	f4040993          	addi	s3,s0,-192
    80005c9e:	6088                	ld	a0,0(s1)
    80005ca0:	c911                	beqz	a0,80005cb4 <sys_exec+0xfc>
    kfree(argv[i]);
    80005ca2:	ffffb097          	auipc	ra,0xffffb
    80005ca6:	d40080e7          	jalr	-704(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005caa:	04a1                	addi	s1,s1,8
    80005cac:	ff3499e3          	bne	s1,s3,80005c9e <sys_exec+0xe6>
    80005cb0:	a011                	j	80005cb4 <sys_exec+0xfc>
  return -1;
    80005cb2:	597d                	li	s2,-1
}
    80005cb4:	854a                	mv	a0,s2
    80005cb6:	60be                	ld	ra,456(sp)
    80005cb8:	641e                	ld	s0,448(sp)
    80005cba:	74fa                	ld	s1,440(sp)
    80005cbc:	795a                	ld	s2,432(sp)
    80005cbe:	79ba                	ld	s3,424(sp)
    80005cc0:	7a1a                	ld	s4,416(sp)
    80005cc2:	6afa                	ld	s5,408(sp)
    80005cc4:	6179                	addi	sp,sp,464
    80005cc6:	8082                	ret

0000000080005cc8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cc8:	7139                	addi	sp,sp,-64
    80005cca:	fc06                	sd	ra,56(sp)
    80005ccc:	f822                	sd	s0,48(sp)
    80005cce:	f426                	sd	s1,40(sp)
    80005cd0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cd2:	ffffc097          	auipc	ra,0xffffc
    80005cd6:	cc4080e7          	jalr	-828(ra) # 80001996 <myproc>
    80005cda:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005cdc:	fd840593          	addi	a1,s0,-40
    80005ce0:	4501                	li	a0,0
    80005ce2:	ffffd097          	auipc	ra,0xffffd
    80005ce6:	fdc080e7          	jalr	-36(ra) # 80002cbe <argaddr>
    return -1;
    80005cea:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cec:	0e054063          	bltz	a0,80005dcc <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cf0:	fc840593          	addi	a1,s0,-56
    80005cf4:	fd040513          	addi	a0,s0,-48
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	de6080e7          	jalr	-538(ra) # 80004ade <pipealloc>
    return -1;
    80005d00:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d02:	0c054563          	bltz	a0,80005dcc <sys_pipe+0x104>
  fd0 = -1;
    80005d06:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d0a:	fd043503          	ld	a0,-48(s0)
    80005d0e:	fffff097          	auipc	ra,0xfffff
    80005d12:	504080e7          	jalr	1284(ra) # 80005212 <fdalloc>
    80005d16:	fca42223          	sw	a0,-60(s0)
    80005d1a:	08054c63          	bltz	a0,80005db2 <sys_pipe+0xea>
    80005d1e:	fc843503          	ld	a0,-56(s0)
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	4f0080e7          	jalr	1264(ra) # 80005212 <fdalloc>
    80005d2a:	fca42023          	sw	a0,-64(s0)
    80005d2e:	06054963          	bltz	a0,80005da0 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d32:	4691                	li	a3,4
    80005d34:	fc440613          	addi	a2,s0,-60
    80005d38:	fd843583          	ld	a1,-40(s0)
    80005d3c:	68a8                	ld	a0,80(s1)
    80005d3e:	ffffc097          	auipc	ra,0xffffc
    80005d42:	91c080e7          	jalr	-1764(ra) # 8000165a <copyout>
    80005d46:	02054063          	bltz	a0,80005d66 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d4a:	4691                	li	a3,4
    80005d4c:	fc040613          	addi	a2,s0,-64
    80005d50:	fd843583          	ld	a1,-40(s0)
    80005d54:	0591                	addi	a1,a1,4
    80005d56:	68a8                	ld	a0,80(s1)
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	902080e7          	jalr	-1790(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d60:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d62:	06055563          	bgez	a0,80005dcc <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d66:	fc442783          	lw	a5,-60(s0)
    80005d6a:	07e9                	addi	a5,a5,26
    80005d6c:	078e                	slli	a5,a5,0x3
    80005d6e:	97a6                	add	a5,a5,s1
    80005d70:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d74:	fc042783          	lw	a5,-64(s0)
    80005d78:	07e9                	addi	a5,a5,26
    80005d7a:	078e                	slli	a5,a5,0x3
    80005d7c:	00f48533          	add	a0,s1,a5
    80005d80:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d84:	fd043503          	ld	a0,-48(s0)
    80005d88:	fffff097          	auipc	ra,0xfffff
    80005d8c:	a26080e7          	jalr	-1498(ra) # 800047ae <fileclose>
    fileclose(wf);
    80005d90:	fc843503          	ld	a0,-56(s0)
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	a1a080e7          	jalr	-1510(ra) # 800047ae <fileclose>
    return -1;
    80005d9c:	57fd                	li	a5,-1
    80005d9e:	a03d                	j	80005dcc <sys_pipe+0x104>
    if(fd0 >= 0)
    80005da0:	fc442783          	lw	a5,-60(s0)
    80005da4:	0007c763          	bltz	a5,80005db2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005da8:	07e9                	addi	a5,a5,26
    80005daa:	078e                	slli	a5,a5,0x3
    80005dac:	97a6                	add	a5,a5,s1
    80005dae:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005db2:	fd043503          	ld	a0,-48(s0)
    80005db6:	fffff097          	auipc	ra,0xfffff
    80005dba:	9f8080e7          	jalr	-1544(ra) # 800047ae <fileclose>
    fileclose(wf);
    80005dbe:	fc843503          	ld	a0,-56(s0)
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	9ec080e7          	jalr	-1556(ra) # 800047ae <fileclose>
    return -1;
    80005dca:	57fd                	li	a5,-1
}
    80005dcc:	853e                	mv	a0,a5
    80005dce:	70e2                	ld	ra,56(sp)
    80005dd0:	7442                	ld	s0,48(sp)
    80005dd2:	74a2                	ld	s1,40(sp)
    80005dd4:	6121                	addi	sp,sp,64
    80005dd6:	8082                	ret
	...

0000000080005de0 <kernelvec>:
    80005de0:	7111                	addi	sp,sp,-256
    80005de2:	e006                	sd	ra,0(sp)
    80005de4:	e40a                	sd	sp,8(sp)
    80005de6:	e80e                	sd	gp,16(sp)
    80005de8:	ec12                	sd	tp,24(sp)
    80005dea:	f016                	sd	t0,32(sp)
    80005dec:	f41a                	sd	t1,40(sp)
    80005dee:	f81e                	sd	t2,48(sp)
    80005df0:	fc22                	sd	s0,56(sp)
    80005df2:	e0a6                	sd	s1,64(sp)
    80005df4:	e4aa                	sd	a0,72(sp)
    80005df6:	e8ae                	sd	a1,80(sp)
    80005df8:	ecb2                	sd	a2,88(sp)
    80005dfa:	f0b6                	sd	a3,96(sp)
    80005dfc:	f4ba                	sd	a4,104(sp)
    80005dfe:	f8be                	sd	a5,112(sp)
    80005e00:	fcc2                	sd	a6,120(sp)
    80005e02:	e146                	sd	a7,128(sp)
    80005e04:	e54a                	sd	s2,136(sp)
    80005e06:	e94e                	sd	s3,144(sp)
    80005e08:	ed52                	sd	s4,152(sp)
    80005e0a:	f156                	sd	s5,160(sp)
    80005e0c:	f55a                	sd	s6,168(sp)
    80005e0e:	f95e                	sd	s7,176(sp)
    80005e10:	fd62                	sd	s8,184(sp)
    80005e12:	e1e6                	sd	s9,192(sp)
    80005e14:	e5ea                	sd	s10,200(sp)
    80005e16:	e9ee                	sd	s11,208(sp)
    80005e18:	edf2                	sd	t3,216(sp)
    80005e1a:	f1f6                	sd	t4,224(sp)
    80005e1c:	f5fa                	sd	t5,232(sp)
    80005e1e:	f9fe                	sd	t6,240(sp)
    80005e20:	caffc0ef          	jal	ra,80002ace <kerneltrap>
    80005e24:	6082                	ld	ra,0(sp)
    80005e26:	6122                	ld	sp,8(sp)
    80005e28:	61c2                	ld	gp,16(sp)
    80005e2a:	7282                	ld	t0,32(sp)
    80005e2c:	7322                	ld	t1,40(sp)
    80005e2e:	73c2                	ld	t2,48(sp)
    80005e30:	7462                	ld	s0,56(sp)
    80005e32:	6486                	ld	s1,64(sp)
    80005e34:	6526                	ld	a0,72(sp)
    80005e36:	65c6                	ld	a1,80(sp)
    80005e38:	6666                	ld	a2,88(sp)
    80005e3a:	7686                	ld	a3,96(sp)
    80005e3c:	7726                	ld	a4,104(sp)
    80005e3e:	77c6                	ld	a5,112(sp)
    80005e40:	7866                	ld	a6,120(sp)
    80005e42:	688a                	ld	a7,128(sp)
    80005e44:	692a                	ld	s2,136(sp)
    80005e46:	69ca                	ld	s3,144(sp)
    80005e48:	6a6a                	ld	s4,152(sp)
    80005e4a:	7a8a                	ld	s5,160(sp)
    80005e4c:	7b2a                	ld	s6,168(sp)
    80005e4e:	7bca                	ld	s7,176(sp)
    80005e50:	7c6a                	ld	s8,184(sp)
    80005e52:	6c8e                	ld	s9,192(sp)
    80005e54:	6d2e                	ld	s10,200(sp)
    80005e56:	6dce                	ld	s11,208(sp)
    80005e58:	6e6e                	ld	t3,216(sp)
    80005e5a:	7e8e                	ld	t4,224(sp)
    80005e5c:	7f2e                	ld	t5,232(sp)
    80005e5e:	7fce                	ld	t6,240(sp)
    80005e60:	6111                	addi	sp,sp,256
    80005e62:	10200073          	sret
    80005e66:	00000013          	nop
    80005e6a:	00000013          	nop
    80005e6e:	0001                	nop

0000000080005e70 <timervec>:
    80005e70:	34051573          	csrrw	a0,mscratch,a0
    80005e74:	e10c                	sd	a1,0(a0)
    80005e76:	e510                	sd	a2,8(a0)
    80005e78:	e914                	sd	a3,16(a0)
    80005e7a:	6d0c                	ld	a1,24(a0)
    80005e7c:	7110                	ld	a2,32(a0)
    80005e7e:	6194                	ld	a3,0(a1)
    80005e80:	96b2                	add	a3,a3,a2
    80005e82:	e194                	sd	a3,0(a1)
    80005e84:	4589                	li	a1,2
    80005e86:	14459073          	csrw	sip,a1
    80005e8a:	6914                	ld	a3,16(a0)
    80005e8c:	6510                	ld	a2,8(a0)
    80005e8e:	610c                	ld	a1,0(a0)
    80005e90:	34051573          	csrrw	a0,mscratch,a0
    80005e94:	30200073          	mret
	...

0000000080005e9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e9a:	1141                	addi	sp,sp,-16
    80005e9c:	e422                	sd	s0,8(sp)
    80005e9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ea0:	0c0007b7          	lui	a5,0xc000
    80005ea4:	4705                	li	a4,1
    80005ea6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ea8:	c3d8                	sw	a4,4(a5)
}
    80005eaa:	6422                	ld	s0,8(sp)
    80005eac:	0141                	addi	sp,sp,16
    80005eae:	8082                	ret

0000000080005eb0 <plicinithart>:

void
plicinithart(void)
{
    80005eb0:	1141                	addi	sp,sp,-16
    80005eb2:	e406                	sd	ra,8(sp)
    80005eb4:	e022                	sd	s0,0(sp)
    80005eb6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005eb8:	ffffc097          	auipc	ra,0xffffc
    80005ebc:	ab2080e7          	jalr	-1358(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ec0:	0085171b          	slliw	a4,a0,0x8
    80005ec4:	0c0027b7          	lui	a5,0xc002
    80005ec8:	97ba                	add	a5,a5,a4
    80005eca:	40200713          	li	a4,1026
    80005ece:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ed2:	00d5151b          	slliw	a0,a0,0xd
    80005ed6:	0c2017b7          	lui	a5,0xc201
    80005eda:	97aa                	add	a5,a5,a0
    80005edc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005ee0:	60a2                	ld	ra,8(sp)
    80005ee2:	6402                	ld	s0,0(sp)
    80005ee4:	0141                	addi	sp,sp,16
    80005ee6:	8082                	ret

0000000080005ee8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ee8:	1141                	addi	sp,sp,-16
    80005eea:	e406                	sd	ra,8(sp)
    80005eec:	e022                	sd	s0,0(sp)
    80005eee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ef0:	ffffc097          	auipc	ra,0xffffc
    80005ef4:	a7a080e7          	jalr	-1414(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ef8:	00d5151b          	slliw	a0,a0,0xd
    80005efc:	0c2017b7          	lui	a5,0xc201
    80005f00:	97aa                	add	a5,a5,a0
  return irq;
}
    80005f02:	43c8                	lw	a0,4(a5)
    80005f04:	60a2                	ld	ra,8(sp)
    80005f06:	6402                	ld	s0,0(sp)
    80005f08:	0141                	addi	sp,sp,16
    80005f0a:	8082                	ret

0000000080005f0c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f0c:	1101                	addi	sp,sp,-32
    80005f0e:	ec06                	sd	ra,24(sp)
    80005f10:	e822                	sd	s0,16(sp)
    80005f12:	e426                	sd	s1,8(sp)
    80005f14:	1000                	addi	s0,sp,32
    80005f16:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f18:	ffffc097          	auipc	ra,0xffffc
    80005f1c:	a52080e7          	jalr	-1454(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f20:	00d5151b          	slliw	a0,a0,0xd
    80005f24:	0c2017b7          	lui	a5,0xc201
    80005f28:	97aa                	add	a5,a5,a0
    80005f2a:	c3c4                	sw	s1,4(a5)
}
    80005f2c:	60e2                	ld	ra,24(sp)
    80005f2e:	6442                	ld	s0,16(sp)
    80005f30:	64a2                	ld	s1,8(sp)
    80005f32:	6105                	addi	sp,sp,32
    80005f34:	8082                	ret

0000000080005f36 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f36:	1141                	addi	sp,sp,-16
    80005f38:	e406                	sd	ra,8(sp)
    80005f3a:	e022                	sd	s0,0(sp)
    80005f3c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f3e:	479d                	li	a5,7
    80005f40:	06a7c863          	blt	a5,a0,80005fb0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005f44:	0001d717          	auipc	a4,0x1d
    80005f48:	0bc70713          	addi	a4,a4,188 # 80023000 <disk>
    80005f4c:	972a                	add	a4,a4,a0
    80005f4e:	6789                	lui	a5,0x2
    80005f50:	97ba                	add	a5,a5,a4
    80005f52:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f56:	e7ad                	bnez	a5,80005fc0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f58:	00451793          	slli	a5,a0,0x4
    80005f5c:	0001f717          	auipc	a4,0x1f
    80005f60:	0a470713          	addi	a4,a4,164 # 80025000 <disk+0x2000>
    80005f64:	6314                	ld	a3,0(a4)
    80005f66:	96be                	add	a3,a3,a5
    80005f68:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f6c:	6314                	ld	a3,0(a4)
    80005f6e:	96be                	add	a3,a3,a5
    80005f70:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f74:	6314                	ld	a3,0(a4)
    80005f76:	96be                	add	a3,a3,a5
    80005f78:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f7c:	6318                	ld	a4,0(a4)
    80005f7e:	97ba                	add	a5,a5,a4
    80005f80:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f84:	0001d717          	auipc	a4,0x1d
    80005f88:	07c70713          	addi	a4,a4,124 # 80023000 <disk>
    80005f8c:	972a                	add	a4,a4,a0
    80005f8e:	6789                	lui	a5,0x2
    80005f90:	97ba                	add	a5,a5,a4
    80005f92:	4705                	li	a4,1
    80005f94:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f98:	0001f517          	auipc	a0,0x1f
    80005f9c:	08050513          	addi	a0,a0,128 # 80025018 <disk+0x2018>
    80005fa0:	ffffc097          	auipc	ra,0xffffc
    80005fa4:	26e080e7          	jalr	622(ra) # 8000220e <wakeup>
}
    80005fa8:	60a2                	ld	ra,8(sp)
    80005faa:	6402                	ld	s0,0(sp)
    80005fac:	0141                	addi	sp,sp,16
    80005fae:	8082                	ret
    panic("free_desc 1");
    80005fb0:	00003517          	auipc	a0,0x3
    80005fb4:	8a050513          	addi	a0,a0,-1888 # 80008850 <syscalls+0x348>
    80005fb8:	ffffa097          	auipc	ra,0xffffa
    80005fbc:	582080e7          	jalr	1410(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005fc0:	00003517          	auipc	a0,0x3
    80005fc4:	8a050513          	addi	a0,a0,-1888 # 80008860 <syscalls+0x358>
    80005fc8:	ffffa097          	auipc	ra,0xffffa
    80005fcc:	572080e7          	jalr	1394(ra) # 8000053a <panic>

0000000080005fd0 <virtio_disk_init>:
{
    80005fd0:	1101                	addi	sp,sp,-32
    80005fd2:	ec06                	sd	ra,24(sp)
    80005fd4:	e822                	sd	s0,16(sp)
    80005fd6:	e426                	sd	s1,8(sp)
    80005fd8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fda:	00003597          	auipc	a1,0x3
    80005fde:	89658593          	addi	a1,a1,-1898 # 80008870 <syscalls+0x368>
    80005fe2:	0001f517          	auipc	a0,0x1f
    80005fe6:	14650513          	addi	a0,a0,326 # 80025128 <disk+0x2128>
    80005fea:	ffffb097          	auipc	ra,0xffffb
    80005fee:	b56080e7          	jalr	-1194(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ff2:	100017b7          	lui	a5,0x10001
    80005ff6:	4398                	lw	a4,0(a5)
    80005ff8:	2701                	sext.w	a4,a4
    80005ffa:	747277b7          	lui	a5,0x74727
    80005ffe:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006002:	0ef71063          	bne	a4,a5,800060e2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006006:	100017b7          	lui	a5,0x10001
    8000600a:	43dc                	lw	a5,4(a5)
    8000600c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000600e:	4705                	li	a4,1
    80006010:	0ce79963          	bne	a5,a4,800060e2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006014:	100017b7          	lui	a5,0x10001
    80006018:	479c                	lw	a5,8(a5)
    8000601a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000601c:	4709                	li	a4,2
    8000601e:	0ce79263          	bne	a5,a4,800060e2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006022:	100017b7          	lui	a5,0x10001
    80006026:	47d8                	lw	a4,12(a5)
    80006028:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000602a:	554d47b7          	lui	a5,0x554d4
    8000602e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006032:	0af71863          	bne	a4,a5,800060e2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006036:	100017b7          	lui	a5,0x10001
    8000603a:	4705                	li	a4,1
    8000603c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000603e:	470d                	li	a4,3
    80006040:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006042:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006044:	c7ffe6b7          	lui	a3,0xc7ffe
    80006048:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000604c:	8f75                	and	a4,a4,a3
    8000604e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006050:	472d                	li	a4,11
    80006052:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006054:	473d                	li	a4,15
    80006056:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006058:	6705                	lui	a4,0x1
    8000605a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000605c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006060:	5bdc                	lw	a5,52(a5)
    80006062:	2781                	sext.w	a5,a5
  if(max == 0)
    80006064:	c7d9                	beqz	a5,800060f2 <virtio_disk_init+0x122>
  if(max < NUM)
    80006066:	471d                	li	a4,7
    80006068:	08f77d63          	bgeu	a4,a5,80006102 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000606c:	100014b7          	lui	s1,0x10001
    80006070:	47a1                	li	a5,8
    80006072:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006074:	6609                	lui	a2,0x2
    80006076:	4581                	li	a1,0
    80006078:	0001d517          	auipc	a0,0x1d
    8000607c:	f8850513          	addi	a0,a0,-120 # 80023000 <disk>
    80006080:	ffffb097          	auipc	ra,0xffffb
    80006084:	c4c080e7          	jalr	-948(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006088:	0001d717          	auipc	a4,0x1d
    8000608c:	f7870713          	addi	a4,a4,-136 # 80023000 <disk>
    80006090:	00c75793          	srli	a5,a4,0xc
    80006094:	2781                	sext.w	a5,a5
    80006096:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006098:	0001f797          	auipc	a5,0x1f
    8000609c:	f6878793          	addi	a5,a5,-152 # 80025000 <disk+0x2000>
    800060a0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800060a2:	0001d717          	auipc	a4,0x1d
    800060a6:	fde70713          	addi	a4,a4,-34 # 80023080 <disk+0x80>
    800060aa:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800060ac:	0001e717          	auipc	a4,0x1e
    800060b0:	f5470713          	addi	a4,a4,-172 # 80024000 <disk+0x1000>
    800060b4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060b6:	4705                	li	a4,1
    800060b8:	00e78c23          	sb	a4,24(a5)
    800060bc:	00e78ca3          	sb	a4,25(a5)
    800060c0:	00e78d23          	sb	a4,26(a5)
    800060c4:	00e78da3          	sb	a4,27(a5)
    800060c8:	00e78e23          	sb	a4,28(a5)
    800060cc:	00e78ea3          	sb	a4,29(a5)
    800060d0:	00e78f23          	sb	a4,30(a5)
    800060d4:	00e78fa3          	sb	a4,31(a5)
}
    800060d8:	60e2                	ld	ra,24(sp)
    800060da:	6442                	ld	s0,16(sp)
    800060dc:	64a2                	ld	s1,8(sp)
    800060de:	6105                	addi	sp,sp,32
    800060e0:	8082                	ret
    panic("could not find virtio disk");
    800060e2:	00002517          	auipc	a0,0x2
    800060e6:	79e50513          	addi	a0,a0,1950 # 80008880 <syscalls+0x378>
    800060ea:	ffffa097          	auipc	ra,0xffffa
    800060ee:	450080e7          	jalr	1104(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    800060f2:	00002517          	auipc	a0,0x2
    800060f6:	7ae50513          	addi	a0,a0,1966 # 800088a0 <syscalls+0x398>
    800060fa:	ffffa097          	auipc	ra,0xffffa
    800060fe:	440080e7          	jalr	1088(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80006102:	00002517          	auipc	a0,0x2
    80006106:	7be50513          	addi	a0,a0,1982 # 800088c0 <syscalls+0x3b8>
    8000610a:	ffffa097          	auipc	ra,0xffffa
    8000610e:	430080e7          	jalr	1072(ra) # 8000053a <panic>

0000000080006112 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006112:	7119                	addi	sp,sp,-128
    80006114:	fc86                	sd	ra,120(sp)
    80006116:	f8a2                	sd	s0,112(sp)
    80006118:	f4a6                	sd	s1,104(sp)
    8000611a:	f0ca                	sd	s2,96(sp)
    8000611c:	ecce                	sd	s3,88(sp)
    8000611e:	e8d2                	sd	s4,80(sp)
    80006120:	e4d6                	sd	s5,72(sp)
    80006122:	e0da                	sd	s6,64(sp)
    80006124:	fc5e                	sd	s7,56(sp)
    80006126:	f862                	sd	s8,48(sp)
    80006128:	f466                	sd	s9,40(sp)
    8000612a:	f06a                	sd	s10,32(sp)
    8000612c:	ec6e                	sd	s11,24(sp)
    8000612e:	0100                	addi	s0,sp,128
    80006130:	8aaa                	mv	s5,a0
    80006132:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006134:	00c52c83          	lw	s9,12(a0)
    80006138:	001c9c9b          	slliw	s9,s9,0x1
    8000613c:	1c82                	slli	s9,s9,0x20
    8000613e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006142:	0001f517          	auipc	a0,0x1f
    80006146:	fe650513          	addi	a0,a0,-26 # 80025128 <disk+0x2128>
    8000614a:	ffffb097          	auipc	ra,0xffffb
    8000614e:	a86080e7          	jalr	-1402(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80006152:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006154:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006156:	0001dc17          	auipc	s8,0x1d
    8000615a:	eaac0c13          	addi	s8,s8,-342 # 80023000 <disk>
    8000615e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006160:	4b0d                	li	s6,3
    80006162:	a0ad                	j	800061cc <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006164:	00fc0733          	add	a4,s8,a5
    80006168:	975e                	add	a4,a4,s7
    8000616a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000616e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006170:	0207c563          	bltz	a5,8000619a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006174:	2905                	addiw	s2,s2,1
    80006176:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006178:	19690c63          	beq	s2,s6,80006310 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000617c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000617e:	0001f717          	auipc	a4,0x1f
    80006182:	e9a70713          	addi	a4,a4,-358 # 80025018 <disk+0x2018>
    80006186:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006188:	00074683          	lbu	a3,0(a4)
    8000618c:	fee1                	bnez	a3,80006164 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000618e:	2785                	addiw	a5,a5,1
    80006190:	0705                	addi	a4,a4,1
    80006192:	fe979be3          	bne	a5,s1,80006188 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006196:	57fd                	li	a5,-1
    80006198:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000619a:	01205d63          	blez	s2,800061b4 <virtio_disk_rw+0xa2>
    8000619e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800061a0:	000a2503          	lw	a0,0(s4)
    800061a4:	00000097          	auipc	ra,0x0
    800061a8:	d92080e7          	jalr	-622(ra) # 80005f36 <free_desc>
      for(int j = 0; j < i; j++)
    800061ac:	2d85                	addiw	s11,s11,1
    800061ae:	0a11                	addi	s4,s4,4
    800061b0:	ff2d98e3          	bne	s11,s2,800061a0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061b4:	0001f597          	auipc	a1,0x1f
    800061b8:	f7458593          	addi	a1,a1,-140 # 80025128 <disk+0x2128>
    800061bc:	0001f517          	auipc	a0,0x1f
    800061c0:	e5c50513          	addi	a0,a0,-420 # 80025018 <disk+0x2018>
    800061c4:	ffffc097          	auipc	ra,0xffffc
    800061c8:	ebe080e7          	jalr	-322(ra) # 80002082 <sleep>
  for(int i = 0; i < 3; i++){
    800061cc:	f8040a13          	addi	s4,s0,-128
{
    800061d0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800061d2:	894e                	mv	s2,s3
    800061d4:	b765                	j	8000617c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061d6:	0001f697          	auipc	a3,0x1f
    800061da:	e2a6b683          	ld	a3,-470(a3) # 80025000 <disk+0x2000>
    800061de:	96ba                	add	a3,a3,a4
    800061e0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061e4:	0001d817          	auipc	a6,0x1d
    800061e8:	e1c80813          	addi	a6,a6,-484 # 80023000 <disk>
    800061ec:	0001f697          	auipc	a3,0x1f
    800061f0:	e1468693          	addi	a3,a3,-492 # 80025000 <disk+0x2000>
    800061f4:	6290                	ld	a2,0(a3)
    800061f6:	963a                	add	a2,a2,a4
    800061f8:	00c65583          	lhu	a1,12(a2)
    800061fc:	0015e593          	ori	a1,a1,1
    80006200:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006204:	f8842603          	lw	a2,-120(s0)
    80006208:	628c                	ld	a1,0(a3)
    8000620a:	972e                	add	a4,a4,a1
    8000620c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006210:	20050593          	addi	a1,a0,512
    80006214:	0592                	slli	a1,a1,0x4
    80006216:	95c2                	add	a1,a1,a6
    80006218:	577d                	li	a4,-1
    8000621a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000621e:	00461713          	slli	a4,a2,0x4
    80006222:	6290                	ld	a2,0(a3)
    80006224:	963a                	add	a2,a2,a4
    80006226:	03078793          	addi	a5,a5,48
    8000622a:	97c2                	add	a5,a5,a6
    8000622c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000622e:	629c                	ld	a5,0(a3)
    80006230:	97ba                	add	a5,a5,a4
    80006232:	4605                	li	a2,1
    80006234:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006236:	629c                	ld	a5,0(a3)
    80006238:	97ba                	add	a5,a5,a4
    8000623a:	4809                	li	a6,2
    8000623c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006240:	629c                	ld	a5,0(a3)
    80006242:	97ba                	add	a5,a5,a4
    80006244:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006248:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000624c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006250:	6698                	ld	a4,8(a3)
    80006252:	00275783          	lhu	a5,2(a4)
    80006256:	8b9d                	andi	a5,a5,7
    80006258:	0786                	slli	a5,a5,0x1
    8000625a:	973e                	add	a4,a4,a5
    8000625c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006260:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006264:	6698                	ld	a4,8(a3)
    80006266:	00275783          	lhu	a5,2(a4)
    8000626a:	2785                	addiw	a5,a5,1
    8000626c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006270:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006274:	100017b7          	lui	a5,0x10001
    80006278:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000627c:	004aa783          	lw	a5,4(s5)
    80006280:	02c79163          	bne	a5,a2,800062a2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006284:	0001f917          	auipc	s2,0x1f
    80006288:	ea490913          	addi	s2,s2,-348 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000628c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000628e:	85ca                	mv	a1,s2
    80006290:	8556                	mv	a0,s5
    80006292:	ffffc097          	auipc	ra,0xffffc
    80006296:	df0080e7          	jalr	-528(ra) # 80002082 <sleep>
  while(b->disk == 1) {
    8000629a:	004aa783          	lw	a5,4(s5)
    8000629e:	fe9788e3          	beq	a5,s1,8000628e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800062a2:	f8042903          	lw	s2,-128(s0)
    800062a6:	20090713          	addi	a4,s2,512
    800062aa:	0712                	slli	a4,a4,0x4
    800062ac:	0001d797          	auipc	a5,0x1d
    800062b0:	d5478793          	addi	a5,a5,-684 # 80023000 <disk>
    800062b4:	97ba                	add	a5,a5,a4
    800062b6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800062ba:	0001f997          	auipc	s3,0x1f
    800062be:	d4698993          	addi	s3,s3,-698 # 80025000 <disk+0x2000>
    800062c2:	00491713          	slli	a4,s2,0x4
    800062c6:	0009b783          	ld	a5,0(s3)
    800062ca:	97ba                	add	a5,a5,a4
    800062cc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062d0:	854a                	mv	a0,s2
    800062d2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062d6:	00000097          	auipc	ra,0x0
    800062da:	c60080e7          	jalr	-928(ra) # 80005f36 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062de:	8885                	andi	s1,s1,1
    800062e0:	f0ed                	bnez	s1,800062c2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062e2:	0001f517          	auipc	a0,0x1f
    800062e6:	e4650513          	addi	a0,a0,-442 # 80025128 <disk+0x2128>
    800062ea:	ffffb097          	auipc	ra,0xffffb
    800062ee:	99a080e7          	jalr	-1638(ra) # 80000c84 <release>
}
    800062f2:	70e6                	ld	ra,120(sp)
    800062f4:	7446                	ld	s0,112(sp)
    800062f6:	74a6                	ld	s1,104(sp)
    800062f8:	7906                	ld	s2,96(sp)
    800062fa:	69e6                	ld	s3,88(sp)
    800062fc:	6a46                	ld	s4,80(sp)
    800062fe:	6aa6                	ld	s5,72(sp)
    80006300:	6b06                	ld	s6,64(sp)
    80006302:	7be2                	ld	s7,56(sp)
    80006304:	7c42                	ld	s8,48(sp)
    80006306:	7ca2                	ld	s9,40(sp)
    80006308:	7d02                	ld	s10,32(sp)
    8000630a:	6de2                	ld	s11,24(sp)
    8000630c:	6109                	addi	sp,sp,128
    8000630e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006310:	f8042503          	lw	a0,-128(s0)
    80006314:	20050793          	addi	a5,a0,512
    80006318:	0792                	slli	a5,a5,0x4
  if(write)
    8000631a:	0001d817          	auipc	a6,0x1d
    8000631e:	ce680813          	addi	a6,a6,-794 # 80023000 <disk>
    80006322:	00f80733          	add	a4,a6,a5
    80006326:	01a036b3          	snez	a3,s10
    8000632a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000632e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006332:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006336:	7679                	lui	a2,0xffffe
    80006338:	963e                	add	a2,a2,a5
    8000633a:	0001f697          	auipc	a3,0x1f
    8000633e:	cc668693          	addi	a3,a3,-826 # 80025000 <disk+0x2000>
    80006342:	6298                	ld	a4,0(a3)
    80006344:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006346:	0a878593          	addi	a1,a5,168
    8000634a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000634c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000634e:	6298                	ld	a4,0(a3)
    80006350:	9732                	add	a4,a4,a2
    80006352:	45c1                	li	a1,16
    80006354:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006356:	6298                	ld	a4,0(a3)
    80006358:	9732                	add	a4,a4,a2
    8000635a:	4585                	li	a1,1
    8000635c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006360:	f8442703          	lw	a4,-124(s0)
    80006364:	628c                	ld	a1,0(a3)
    80006366:	962e                	add	a2,a2,a1
    80006368:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000636c:	0712                	slli	a4,a4,0x4
    8000636e:	6290                	ld	a2,0(a3)
    80006370:	963a                	add	a2,a2,a4
    80006372:	058a8593          	addi	a1,s5,88
    80006376:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006378:	6294                	ld	a3,0(a3)
    8000637a:	96ba                	add	a3,a3,a4
    8000637c:	40000613          	li	a2,1024
    80006380:	c690                	sw	a2,8(a3)
  if(write)
    80006382:	e40d1ae3          	bnez	s10,800061d6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006386:	0001f697          	auipc	a3,0x1f
    8000638a:	c7a6b683          	ld	a3,-902(a3) # 80025000 <disk+0x2000>
    8000638e:	96ba                	add	a3,a3,a4
    80006390:	4609                	li	a2,2
    80006392:	00c69623          	sh	a2,12(a3)
    80006396:	b5b9                	j	800061e4 <virtio_disk_rw+0xd2>

0000000080006398 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006398:	1101                	addi	sp,sp,-32
    8000639a:	ec06                	sd	ra,24(sp)
    8000639c:	e822                	sd	s0,16(sp)
    8000639e:	e426                	sd	s1,8(sp)
    800063a0:	e04a                	sd	s2,0(sp)
    800063a2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063a4:	0001f517          	auipc	a0,0x1f
    800063a8:	d8450513          	addi	a0,a0,-636 # 80025128 <disk+0x2128>
    800063ac:	ffffb097          	auipc	ra,0xffffb
    800063b0:	824080e7          	jalr	-2012(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063b4:	10001737          	lui	a4,0x10001
    800063b8:	533c                	lw	a5,96(a4)
    800063ba:	8b8d                	andi	a5,a5,3
    800063bc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063be:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063c2:	0001f797          	auipc	a5,0x1f
    800063c6:	c3e78793          	addi	a5,a5,-962 # 80025000 <disk+0x2000>
    800063ca:	6b94                	ld	a3,16(a5)
    800063cc:	0207d703          	lhu	a4,32(a5)
    800063d0:	0026d783          	lhu	a5,2(a3)
    800063d4:	06f70163          	beq	a4,a5,80006436 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063d8:	0001d917          	auipc	s2,0x1d
    800063dc:	c2890913          	addi	s2,s2,-984 # 80023000 <disk>
    800063e0:	0001f497          	auipc	s1,0x1f
    800063e4:	c2048493          	addi	s1,s1,-992 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800063e8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063ec:	6898                	ld	a4,16(s1)
    800063ee:	0204d783          	lhu	a5,32(s1)
    800063f2:	8b9d                	andi	a5,a5,7
    800063f4:	078e                	slli	a5,a5,0x3
    800063f6:	97ba                	add	a5,a5,a4
    800063f8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063fa:	20078713          	addi	a4,a5,512
    800063fe:	0712                	slli	a4,a4,0x4
    80006400:	974a                	add	a4,a4,s2
    80006402:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006406:	e731                	bnez	a4,80006452 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006408:	20078793          	addi	a5,a5,512
    8000640c:	0792                	slli	a5,a5,0x4
    8000640e:	97ca                	add	a5,a5,s2
    80006410:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006412:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006416:	ffffc097          	auipc	ra,0xffffc
    8000641a:	df8080e7          	jalr	-520(ra) # 8000220e <wakeup>

    disk.used_idx += 1;
    8000641e:	0204d783          	lhu	a5,32(s1)
    80006422:	2785                	addiw	a5,a5,1
    80006424:	17c2                	slli	a5,a5,0x30
    80006426:	93c1                	srli	a5,a5,0x30
    80006428:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000642c:	6898                	ld	a4,16(s1)
    8000642e:	00275703          	lhu	a4,2(a4)
    80006432:	faf71be3          	bne	a4,a5,800063e8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006436:	0001f517          	auipc	a0,0x1f
    8000643a:	cf250513          	addi	a0,a0,-782 # 80025128 <disk+0x2128>
    8000643e:	ffffb097          	auipc	ra,0xffffb
    80006442:	846080e7          	jalr	-1978(ra) # 80000c84 <release>
}
    80006446:	60e2                	ld	ra,24(sp)
    80006448:	6442                	ld	s0,16(sp)
    8000644a:	64a2                	ld	s1,8(sp)
    8000644c:	6902                	ld	s2,0(sp)
    8000644e:	6105                	addi	sp,sp,32
    80006450:	8082                	ret
      panic("virtio_disk_intr status");
    80006452:	00002517          	auipc	a0,0x2
    80006456:	48e50513          	addi	a0,a0,1166 # 800088e0 <syscalls+0x3d8>
    8000645a:	ffffa097          	auipc	ra,0xffffa
    8000645e:	0e0080e7          	jalr	224(ra) # 8000053a <panic>
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
