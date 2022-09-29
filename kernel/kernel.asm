
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
    80000066:	0ce78793          	addi	a5,a5,206 # 80006130 <timervec>
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
    80000ebc:	ba8080e7          	jalr	-1112(ra) # 80002a60 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	2b0080e7          	jalr	688(ra) # 80006170 <plicinithart>
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
    80000f34:	b08080e7          	jalr	-1272(ra) # 80002a38 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	b28080e7          	jalr	-1240(ra) # 80002a60 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	21a080e7          	jalr	538(ra) # 8000615a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	228080e7          	jalr	552(ra) # 80006170 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	3e6080e7          	jalr	998(ra) # 80003336 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	a74080e7          	jalr	-1420(ra) # 800039cc <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	a26080e7          	jalr	-1498(ra) # 80004986 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	328080e7          	jalr	808(ra) # 80006290 <virtio_disk_init>
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
    800019ec:	f187a783          	lw	a5,-232(a5) # 80008900 <first.3>
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
    80001a0e:	06e080e7          	jalr	110(ra) # 80002a78 <usertrapret>
}
    80001a12:	60e2                	ld	ra,24(sp)
    80001a14:	6442                	ld	s0,16(sp)
    80001a16:	64a2                	ld	s1,8(sp)
    80001a18:	6105                	addi	sp,sp,32
    80001a1a:	8082                	ret
    first = 0;
    80001a1c:	00007797          	auipc	a5,0x7
    80001a20:	ee07a223          	sw	zero,-284(a5) # 80008900 <first.3>
    fsinit(ROOTDEV);
    80001a24:	4505                	li	a0,1
    80001a26:	00002097          	auipc	ra,0x2
    80001a2a:	f26080e7          	jalr	-218(ra) # 8000394c <fsinit>
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
    80001cf8:	68e080e7          	jalr	1678(ra) # 80004382 <namei>
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
    80001e44:	bd8080e7          	jalr	-1064(ra) # 80004a18 <filedup>
    80001e48:	00a93023          	sd	a0,0(s2)
    80001e4c:	b7e5                	j	80001e34 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e4e:	150ab503          	ld	a0,336(s5)
    80001e52:	00002097          	auipc	ra,0x2
    80001e56:	d36080e7          	jalr	-714(ra) # 80003b88 <idup>
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
    80001f66:	a6c080e7          	jalr	-1428(ra) # 800029ce <swtch>
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
    80001fe8:	9ea080e7          	jalr	-1558(ra) # 800029ce <swtch>
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
    80002322:	74c080e7          	jalr	1868(ra) # 80004a6a <fileclose>
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
    8000233a:	26c080e7          	jalr	620(ra) # 800045a2 <begin_op>
  iput(p->cwd);
    8000233e:	1509b503          	ld	a0,336(s3)
    80002342:	00002097          	auipc	ra,0x2
    80002346:	a3e080e7          	jalr	-1474(ra) # 80003d80 <iput>
  end_op();
    8000234a:	00002097          	auipc	ra,0x2
    8000234e:	2d6080e7          	jalr	726(ra) # 80004620 <end_op>
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
    80002532:	de2b8b93          	addi	s7,s7,-542 # 80008310 <states.2>
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
    8000264e:	3ce080e7          	jalr	974(ra) # 80004a18 <filedup>
    80002652:	00a93023          	sd	a0,0(s2)
    80002656:	b7e5                	j	8000263e <forkf+0xb0>
  np->cwd = idup(p->cwd);
    80002658:	150ab503          	ld	a0,336(s5)
    8000265c:	00001097          	auipc	ra,0x1
    80002660:	52c080e7          	jalr	1324(ra) # 80003b88 <idup>
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
    8000280e:	711d                	addi	sp,sp,-96
    80002810:	ec86                	sd	ra,88(sp)
    80002812:	e8a2                	sd	s0,80(sp)
    80002814:	e4a6                	sd	s1,72(sp)
    80002816:	e0ca                	sd	s2,64(sp)
    80002818:	fc4e                	sd	s3,56(sp)
    8000281a:	f852                	sd	s4,48(sp)
    8000281c:	f456                	sd	s5,40(sp)
    8000281e:	f05a                	sd	s6,32(sp)
    80002820:	ec5e                	sd	s7,24(sp)
    80002822:	e862                	sd	s8,16(sp)
    80002824:	1080                	addi	s0,sp,96
  };  // acquire(&wait_lock);

  // for(;;){
    // Scan through table looking for exited children.
    // havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
    80002826:	0000f497          	auipc	s1,0xf
    8000282a:	eaa48493          	addi	s1,s1,-342 # 800116d0 <proc>
      acquire(&np->lock);
      if(np->state != UNUSED)
        printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%p\n", np->pid, (np->parent) ? np->parent->pid : -1, states[np->state], np->name, np->ctime, np->stime, (np->state == ZOMBIE)? np->etime : ticks - np->stime, np->sz);
    8000282e:	5bfd                	li	s7,-1
    80002830:	00006b17          	auipc	s6,0x6
    80002834:	ae0b0b13          	addi	s6,s6,-1312 # 80008310 <states.2>
    80002838:	4a95                	li	s5,5
    8000283a:	00006a17          	auipc	s4,0x6
    8000283e:	a5ea0a13          	addi	s4,s4,-1442 # 80008298 <digits+0x258>
    80002842:	00006c17          	auipc	s8,0x6
    80002846:	7eec0c13          	addi	s8,s8,2030 # 80009030 <ticks>
    for(np = proc; np < &proc[NPROC]; np++){
    8000284a:	00015997          	auipc	s3,0x15
    8000284e:	e8698993          	addi	s3,s3,-378 # 800176d0 <tickslock>
    80002852:	a01d                	j	80002878 <ps+0x6a>
        printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%p\n", np->pid, (np->parent) ? np->parent->pid : -1, states[np->state], np->name, np->ctime, np->stime, (np->state == ZOMBIE)? np->etime : ticks - np->stime, np->sz);
    80002854:	1784b883          	ld	a7,376(s1)
    80002858:	64a8                	ld	a0,72(s1)
    8000285a:	e02a                	sd	a0,0(sp)
    8000285c:	8552                	mv	a0,s4
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	d26080e7          	jalr	-730(ra) # 80000584 <printf>
      release(&np->lock);
    80002866:	8526                	mv	a0,s1
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	41c080e7          	jalr	1052(ra) # 80000c84 <release>
    for(np = proc; np < &proc[NPROC]; np++){
    80002870:	18048493          	addi	s1,s1,384
    80002874:	05348263          	beq	s1,s3,800028b8 <ps+0xaa>
      acquire(&np->lock);
    80002878:	8926                	mv	s2,s1
    8000287a:	8526                	mv	a0,s1
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	354080e7          	jalr	852(ra) # 80000bd0 <acquire>
      if(np->state != UNUSED)
    80002884:	4c88                	lw	a0,24(s1)
    80002886:	d165                	beqz	a0,80002866 <ps+0x58>
        printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%p\n", np->pid, (np->parent) ? np->parent->pid : -1, states[np->state], np->name, np->ctime, np->stime, (np->state == ZOMBIE)? np->etime : ticks - np->stime, np->sz);
    80002888:	588c                	lw	a1,48(s1)
    8000288a:	7c9c                	ld	a5,56(s1)
    8000288c:	865e                	mv	a2,s7
    8000288e:	c391                	beqz	a5,80002892 <ps+0x84>
    80002890:	5b90                	lw	a2,48(a5)
    80002892:	02051713          	slli	a4,a0,0x20
    80002896:	01d75793          	srli	a5,a4,0x1d
    8000289a:	97da                	add	a5,a5,s6
    8000289c:	7b94                	ld	a3,48(a5)
    8000289e:	15890713          	addi	a4,s2,344
    800028a2:	1684b783          	ld	a5,360(s1)
    800028a6:	1704b803          	ld	a6,368(s1)
    800028aa:	fb5505e3          	beq	a0,s5,80002854 <ps+0x46>
    800028ae:	000c6883          	lwu	a7,0(s8)
    800028b2:	410888b3          	sub	a7,a7,a6
    800028b6:	b74d                	j	80002858 <ps+0x4a>
    }
    return;
  // }
}
    800028b8:	60e6                	ld	ra,88(sp)
    800028ba:	6446                	ld	s0,80(sp)
    800028bc:	64a6                	ld	s1,72(sp)
    800028be:	6906                	ld	s2,64(sp)
    800028c0:	79e2                	ld	s3,56(sp)
    800028c2:	7a42                	ld	s4,48(sp)
    800028c4:	7aa2                	ld	s5,40(sp)
    800028c6:	7b02                	ld	s6,32(sp)
    800028c8:	6be2                	ld	s7,24(sp)
    800028ca:	6c42                	ld	s8,16(sp)
    800028cc:	6125                	addi	sp,sp,96
    800028ce:	8082                	ret

00000000800028d0 <pinfo>:

int
pinfo(uint64 pid, uint64 p){
    800028d0:	711d                	addi	sp,sp,-96
    800028d2:	ec86                	sd	ra,88(sp)
    800028d4:	e8a2                	sd	s0,80(sp)
    800028d6:	e4a6                	sd	s1,72(sp)
    800028d8:	e0ca                	sd	s2,64(sp)
    800028da:	fc4e                	sd	s3,56(sp)
    800028dc:	f852                	sd	s4,48(sp)
    800028de:	1080                	addi	s0,sp,96
    800028e0:	89aa                	mv	s3,a0
    800028e2:	8a2e                	mv	s4,a1
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
    for(np = proc; np < &proc[NPROC]; np++){
    800028e4:	0000f497          	auipc	s1,0xf
    800028e8:	dec48493          	addi	s1,s1,-532 # 800116d0 <proc>
    800028ec:	00015917          	auipc	s2,0x15
    800028f0:	de490913          	addi	s2,s2,-540 # 800176d0 <tickslock>
    800028f4:	a829                	j	8000290e <pinfo+0x3e>
        prcst->ppid = (np->parent) ? np->parent->pid : -1;
        safestrcpy(prcst->state, states[np->state], sizeof(states[np->state]));
        safestrcpy(prcst->command, np->name, sizeof(np->name));
        prcst->ctime = np->ctime;
        prcst->stime = np->stime;
        prcst->etime = (np->state == ZOMBIE)? np->etime : ticks - np->stime;
    800028f6:	1784a783          	lw	a5,376(s1)
    800028fa:	a079                	j	80002988 <pinfo+0xb8>
        prcst->size = np->sz;
        copyout(myproc()->pagetable, p, (char *)prcst, sizeof(*prcst));
        release(&np->lock);
        return 0;
        }
      release(&np->lock);
    800028fc:	8526                	mv	a0,s1
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	386080e7          	jalr	902(ra) # 80000c84 <release>
    for(np = proc; np < &proc[NPROC]; np++){
    80002906:	18048493          	addi	s1,s1,384
    8000290a:	0d248063          	beq	s1,s2,800029ca <pinfo+0xfa>
      acquire(&np->lock);
    8000290e:	8526                	mv	a0,s1
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	2c0080e7          	jalr	704(ra) # 80000bd0 <acquire>
      if((np->state != UNUSED)&&(np->pid == pid)){
    80002918:	4c9c                	lw	a5,24(s1)
    8000291a:	d3ed                	beqz	a5,800028fc <pinfo+0x2c>
    8000291c:	5898                	lw	a4,48(s1)
    8000291e:	fd371fe3          	bne	a4,s3,800028fc <pinfo+0x2c>
        prcst->pid = np->pid;
    80002922:	fae42023          	sw	a4,-96(s0)
        prcst->ppid = (np->parent) ? np->parent->pid : -1;
    80002926:	7c94                	ld	a3,56(s1)
    80002928:	577d                	li	a4,-1
    8000292a:	c291                	beqz	a3,8000292e <pinfo+0x5e>
    8000292c:	5a98                	lw	a4,48(a3)
    8000292e:	fae42223          	sw	a4,-92(s0)
        safestrcpy(prcst->state, states[np->state], sizeof(states[np->state]));
    80002932:	02079713          	slli	a4,a5,0x20
    80002936:	01d75793          	srli	a5,a4,0x1d
    8000293a:	00006717          	auipc	a4,0x6
    8000293e:	9d670713          	addi	a4,a4,-1578 # 80008310 <states.2>
    80002942:	97ba                	add	a5,a5,a4
    80002944:	4621                	li	a2,8
    80002946:	73ac                	ld	a1,96(a5)
    80002948:	fa840513          	addi	a0,s0,-88
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	4ca080e7          	jalr	1226(ra) # 80000e16 <safestrcpy>
        safestrcpy(prcst->command, np->name, sizeof(np->name));
    80002954:	4641                	li	a2,16
    80002956:	15848593          	addi	a1,s1,344
    8000295a:	fb040513          	addi	a0,s0,-80
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	4b8080e7          	jalr	1208(ra) # 80000e16 <safestrcpy>
        prcst->ctime = np->ctime;
    80002966:	1684b783          	ld	a5,360(s1)
    8000296a:	fcf42023          	sw	a5,-64(s0)
        prcst->stime = np->stime;
    8000296e:	1704b703          	ld	a4,368(s1)
    80002972:	fce42223          	sw	a4,-60(s0)
        prcst->etime = (np->state == ZOMBIE)? np->etime : ticks - np->stime;
    80002976:	4c94                	lw	a3,24(s1)
    80002978:	4795                	li	a5,5
    8000297a:	f6f68ee3          	beq	a3,a5,800028f6 <pinfo+0x26>
    8000297e:	00006797          	auipc	a5,0x6
    80002982:	6b27a783          	lw	a5,1714(a5) # 80009030 <ticks>
    80002986:	9f99                	subw	a5,a5,a4
    80002988:	fcf42423          	sw	a5,-56(s0)
        prcst->size = np->sz;
    8000298c:	64bc                	ld	a5,72(s1)
    8000298e:	fcf42623          	sw	a5,-52(s0)
        copyout(myproc()->pagetable, p, (char *)prcst, sizeof(*prcst));
    80002992:	fffff097          	auipc	ra,0xfffff
    80002996:	004080e7          	jalr	4(ra) # 80001996 <myproc>
    8000299a:	03000693          	li	a3,48
    8000299e:	fa040613          	addi	a2,s0,-96
    800029a2:	85d2                	mv	a1,s4
    800029a4:	6928                	ld	a0,80(a0)
    800029a6:	fffff097          	auipc	ra,0xfffff
    800029aa:	cb4080e7          	jalr	-844(ra) # 8000165a <copyout>
        release(&np->lock);
    800029ae:	8526                	mv	a0,s1
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	2d4080e7          	jalr	724(ra) # 80000c84 <release>
        return 0;
    800029b8:	4501                	li	a0,0
    }
  return -1;
    800029ba:	60e6                	ld	ra,88(sp)
    800029bc:	6446                	ld	s0,80(sp)
    800029be:	64a6                	ld	s1,72(sp)
    800029c0:	6906                	ld	s2,64(sp)
    800029c2:	79e2                	ld	s3,56(sp)
    800029c4:	7a42                	ld	s4,48(sp)
    800029c6:	6125                	addi	sp,sp,96
    800029c8:	8082                	ret
  return -1;
    800029ca:	557d                	li	a0,-1
    800029cc:	b7fd                	j	800029ba <pinfo+0xea>

00000000800029ce <swtch>:
    800029ce:	00153023          	sd	ra,0(a0)
    800029d2:	00253423          	sd	sp,8(a0)
    800029d6:	e900                	sd	s0,16(a0)
    800029d8:	ed04                	sd	s1,24(a0)
    800029da:	03253023          	sd	s2,32(a0)
    800029de:	03353423          	sd	s3,40(a0)
    800029e2:	03453823          	sd	s4,48(a0)
    800029e6:	03553c23          	sd	s5,56(a0)
    800029ea:	05653023          	sd	s6,64(a0)
    800029ee:	05753423          	sd	s7,72(a0)
    800029f2:	05853823          	sd	s8,80(a0)
    800029f6:	05953c23          	sd	s9,88(a0)
    800029fa:	07a53023          	sd	s10,96(a0)
    800029fe:	07b53423          	sd	s11,104(a0)
    80002a02:	0005b083          	ld	ra,0(a1)
    80002a06:	0085b103          	ld	sp,8(a1)
    80002a0a:	6980                	ld	s0,16(a1)
    80002a0c:	6d84                	ld	s1,24(a1)
    80002a0e:	0205b903          	ld	s2,32(a1)
    80002a12:	0285b983          	ld	s3,40(a1)
    80002a16:	0305ba03          	ld	s4,48(a1)
    80002a1a:	0385ba83          	ld	s5,56(a1)
    80002a1e:	0405bb03          	ld	s6,64(a1)
    80002a22:	0485bb83          	ld	s7,72(a1)
    80002a26:	0505bc03          	ld	s8,80(a1)
    80002a2a:	0585bc83          	ld	s9,88(a1)
    80002a2e:	0605bd03          	ld	s10,96(a1)
    80002a32:	0685bd83          	ld	s11,104(a1)
    80002a36:	8082                	ret

0000000080002a38 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a38:	1141                	addi	sp,sp,-16
    80002a3a:	e406                	sd	ra,8(sp)
    80002a3c:	e022                	sd	s0,0(sp)
    80002a3e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a40:	00006597          	auipc	a1,0x6
    80002a44:	96058593          	addi	a1,a1,-1696 # 800083a0 <states.0+0x30>
    80002a48:	00015517          	auipc	a0,0x15
    80002a4c:	c8850513          	addi	a0,a0,-888 # 800176d0 <tickslock>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	0f0080e7          	jalr	240(ra) # 80000b40 <initlock>
}
    80002a58:	60a2                	ld	ra,8(sp)
    80002a5a:	6402                	ld	s0,0(sp)
    80002a5c:	0141                	addi	sp,sp,16
    80002a5e:	8082                	ret

0000000080002a60 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a60:	1141                	addi	sp,sp,-16
    80002a62:	e422                	sd	s0,8(sp)
    80002a64:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a66:	00003797          	auipc	a5,0x3
    80002a6a:	63a78793          	addi	a5,a5,1594 # 800060a0 <kernelvec>
    80002a6e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a72:	6422                	ld	s0,8(sp)
    80002a74:	0141                	addi	sp,sp,16
    80002a76:	8082                	ret

0000000080002a78 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a78:	1141                	addi	sp,sp,-16
    80002a7a:	e406                	sd	ra,8(sp)
    80002a7c:	e022                	sd	s0,0(sp)
    80002a7e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a80:	fffff097          	auipc	ra,0xfffff
    80002a84:	f16080e7          	jalr	-234(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a88:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a8c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a8e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a92:	00004697          	auipc	a3,0x4
    80002a96:	56e68693          	addi	a3,a3,1390 # 80007000 <_trampoline>
    80002a9a:	00004717          	auipc	a4,0x4
    80002a9e:	56670713          	addi	a4,a4,1382 # 80007000 <_trampoline>
    80002aa2:	8f15                	sub	a4,a4,a3
    80002aa4:	040007b7          	lui	a5,0x4000
    80002aa8:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002aaa:	07b2                	slli	a5,a5,0xc
    80002aac:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aae:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ab2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ab4:	18002673          	csrr	a2,satp
    80002ab8:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002aba:	6d30                	ld	a2,88(a0)
    80002abc:	6138                	ld	a4,64(a0)
    80002abe:	6585                	lui	a1,0x1
    80002ac0:	972e                	add	a4,a4,a1
    80002ac2:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ac4:	6d38                	ld	a4,88(a0)
    80002ac6:	00000617          	auipc	a2,0x0
    80002aca:	13860613          	addi	a2,a2,312 # 80002bfe <usertrap>
    80002ace:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ad0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ad2:	8612                	mv	a2,tp
    80002ad4:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad6:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ada:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ade:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae2:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ae6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ae8:	6f18                	ld	a4,24(a4)
    80002aea:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002aee:	692c                	ld	a1,80(a0)
    80002af0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002af2:	00004717          	auipc	a4,0x4
    80002af6:	59e70713          	addi	a4,a4,1438 # 80007090 <userret>
    80002afa:	8f15                	sub	a4,a4,a3
    80002afc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002afe:	577d                	li	a4,-1
    80002b00:	177e                	slli	a4,a4,0x3f
    80002b02:	8dd9                	or	a1,a1,a4
    80002b04:	02000537          	lui	a0,0x2000
    80002b08:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002b0a:	0536                	slli	a0,a0,0xd
    80002b0c:	9782                	jalr	a5
}
    80002b0e:	60a2                	ld	ra,8(sp)
    80002b10:	6402                	ld	s0,0(sp)
    80002b12:	0141                	addi	sp,sp,16
    80002b14:	8082                	ret

0000000080002b16 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b20:	00015497          	auipc	s1,0x15
    80002b24:	bb048493          	addi	s1,s1,-1104 # 800176d0 <tickslock>
    80002b28:	8526                	mv	a0,s1
    80002b2a:	ffffe097          	auipc	ra,0xffffe
    80002b2e:	0a6080e7          	jalr	166(ra) # 80000bd0 <acquire>
  ticks++;
    80002b32:	00006517          	auipc	a0,0x6
    80002b36:	4fe50513          	addi	a0,a0,1278 # 80009030 <ticks>
    80002b3a:	411c                	lw	a5,0(a0)
    80002b3c:	2785                	addiw	a5,a5,1
    80002b3e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b40:	fffff097          	auipc	ra,0xfffff
    80002b44:	6ce080e7          	jalr	1742(ra) # 8000220e <wakeup>
  release(&tickslock);
    80002b48:	8526                	mv	a0,s1
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	13a080e7          	jalr	314(ra) # 80000c84 <release>
}
    80002b52:	60e2                	ld	ra,24(sp)
    80002b54:	6442                	ld	s0,16(sp)
    80002b56:	64a2                	ld	s1,8(sp)
    80002b58:	6105                	addi	sp,sp,32
    80002b5a:	8082                	ret

0000000080002b5c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b5c:	1101                	addi	sp,sp,-32
    80002b5e:	ec06                	sd	ra,24(sp)
    80002b60:	e822                	sd	s0,16(sp)
    80002b62:	e426                	sd	s1,8(sp)
    80002b64:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b66:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b6a:	00074d63          	bltz	a4,80002b84 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b6e:	57fd                	li	a5,-1
    80002b70:	17fe                	slli	a5,a5,0x3f
    80002b72:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b74:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b76:	06f70363          	beq	a4,a5,80002bdc <devintr+0x80>
  }
}
    80002b7a:	60e2                	ld	ra,24(sp)
    80002b7c:	6442                	ld	s0,16(sp)
    80002b7e:	64a2                	ld	s1,8(sp)
    80002b80:	6105                	addi	sp,sp,32
    80002b82:	8082                	ret
     (scause & 0xff) == 9){
    80002b84:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002b88:	46a5                	li	a3,9
    80002b8a:	fed792e3          	bne	a5,a3,80002b6e <devintr+0x12>
    int irq = plic_claim();
    80002b8e:	00003097          	auipc	ra,0x3
    80002b92:	61a080e7          	jalr	1562(ra) # 800061a8 <plic_claim>
    80002b96:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b98:	47a9                	li	a5,10
    80002b9a:	02f50763          	beq	a0,a5,80002bc8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b9e:	4785                	li	a5,1
    80002ba0:	02f50963          	beq	a0,a5,80002bd2 <devintr+0x76>
    return 1;
    80002ba4:	4505                	li	a0,1
    } else if(irq){
    80002ba6:	d8f1                	beqz	s1,80002b7a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ba8:	85a6                	mv	a1,s1
    80002baa:	00005517          	auipc	a0,0x5
    80002bae:	7fe50513          	addi	a0,a0,2046 # 800083a8 <states.0+0x38>
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	9d2080e7          	jalr	-1582(ra) # 80000584 <printf>
      plic_complete(irq);
    80002bba:	8526                	mv	a0,s1
    80002bbc:	00003097          	auipc	ra,0x3
    80002bc0:	610080e7          	jalr	1552(ra) # 800061cc <plic_complete>
    return 1;
    80002bc4:	4505                	li	a0,1
    80002bc6:	bf55                	j	80002b7a <devintr+0x1e>
      uartintr();
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	dca080e7          	jalr	-566(ra) # 80000992 <uartintr>
    80002bd0:	b7ed                	j	80002bba <devintr+0x5e>
      virtio_disk_intr();
    80002bd2:	00004097          	auipc	ra,0x4
    80002bd6:	a86080e7          	jalr	-1402(ra) # 80006658 <virtio_disk_intr>
    80002bda:	b7c5                	j	80002bba <devintr+0x5e>
    if(cpuid() == 0){
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	d8e080e7          	jalr	-626(ra) # 8000196a <cpuid>
    80002be4:	c901                	beqz	a0,80002bf4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002be6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bec:	14479073          	csrw	sip,a5
    return 2;
    80002bf0:	4509                	li	a0,2
    80002bf2:	b761                	j	80002b7a <devintr+0x1e>
      clockintr();
    80002bf4:	00000097          	auipc	ra,0x0
    80002bf8:	f22080e7          	jalr	-222(ra) # 80002b16 <clockintr>
    80002bfc:	b7ed                	j	80002be6 <devintr+0x8a>

0000000080002bfe <usertrap>:
{
    80002bfe:	1101                	addi	sp,sp,-32
    80002c00:	ec06                	sd	ra,24(sp)
    80002c02:	e822                	sd	s0,16(sp)
    80002c04:	e426                	sd	s1,8(sp)
    80002c06:	e04a                	sd	s2,0(sp)
    80002c08:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c0a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c0e:	1007f793          	andi	a5,a5,256
    80002c12:	e3ad                	bnez	a5,80002c74 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c14:	00003797          	auipc	a5,0x3
    80002c18:	48c78793          	addi	a5,a5,1164 # 800060a0 <kernelvec>
    80002c1c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	d76080e7          	jalr	-650(ra) # 80001996 <myproc>
    80002c28:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c2a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2c:	14102773          	csrr	a4,sepc
    80002c30:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c32:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c36:	47a1                	li	a5,8
    80002c38:	04f71c63          	bne	a4,a5,80002c90 <usertrap+0x92>
    if(p->killed)
    80002c3c:	551c                	lw	a5,40(a0)
    80002c3e:	e3b9                	bnez	a5,80002c84 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002c40:	6cb8                	ld	a4,88(s1)
    80002c42:	6f1c                	ld	a5,24(a4)
    80002c44:	0791                	addi	a5,a5,4
    80002c46:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c4c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c50:	10079073          	csrw	sstatus,a5
    syscall();
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	2e0080e7          	jalr	736(ra) # 80002f34 <syscall>
  if(p->killed)
    80002c5c:	549c                	lw	a5,40(s1)
    80002c5e:	ebc1                	bnez	a5,80002cee <usertrap+0xf0>
  usertrapret();
    80002c60:	00000097          	auipc	ra,0x0
    80002c64:	e18080e7          	jalr	-488(ra) # 80002a78 <usertrapret>
}
    80002c68:	60e2                	ld	ra,24(sp)
    80002c6a:	6442                	ld	s0,16(sp)
    80002c6c:	64a2                	ld	s1,8(sp)
    80002c6e:	6902                	ld	s2,0(sp)
    80002c70:	6105                	addi	sp,sp,32
    80002c72:	8082                	ret
    panic("usertrap: not from user mode");
    80002c74:	00005517          	auipc	a0,0x5
    80002c78:	75450513          	addi	a0,a0,1876 # 800083c8 <states.0+0x58>
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>
      exit(-1);
    80002c84:	557d                	li	a0,-1
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	658080e7          	jalr	1624(ra) # 800022de <exit>
    80002c8e:	bf4d                	j	80002c40 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002c90:	00000097          	auipc	ra,0x0
    80002c94:	ecc080e7          	jalr	-308(ra) # 80002b5c <devintr>
    80002c98:	892a                	mv	s2,a0
    80002c9a:	c501                	beqz	a0,80002ca2 <usertrap+0xa4>
  if(p->killed)
    80002c9c:	549c                	lw	a5,40(s1)
    80002c9e:	c3a1                	beqz	a5,80002cde <usertrap+0xe0>
    80002ca0:	a815                	j	80002cd4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ca6:	5890                	lw	a2,48(s1)
    80002ca8:	00005517          	auipc	a0,0x5
    80002cac:	74050513          	addi	a0,a0,1856 # 800083e8 <states.0+0x78>
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	8d4080e7          	jalr	-1836(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cbc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cc0:	00005517          	auipc	a0,0x5
    80002cc4:	75850513          	addi	a0,a0,1880 # 80008418 <states.0+0xa8>
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	8bc080e7          	jalr	-1860(ra) # 80000584 <printf>
    p->killed = 1;
    80002cd0:	4785                	li	a5,1
    80002cd2:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002cd4:	557d                	li	a0,-1
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	608080e7          	jalr	1544(ra) # 800022de <exit>
  if(which_dev == 2)
    80002cde:	4789                	li	a5,2
    80002ce0:	f8f910e3          	bne	s2,a5,80002c60 <usertrap+0x62>
    yield();
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	362080e7          	jalr	866(ra) # 80002046 <yield>
    80002cec:	bf95                	j	80002c60 <usertrap+0x62>
  int which_dev = 0;
    80002cee:	4901                	li	s2,0
    80002cf0:	b7d5                	j	80002cd4 <usertrap+0xd6>

0000000080002cf2 <kerneltrap>:
{
    80002cf2:	7179                	addi	sp,sp,-48
    80002cf4:	f406                	sd	ra,40(sp)
    80002cf6:	f022                	sd	s0,32(sp)
    80002cf8:	ec26                	sd	s1,24(sp)
    80002cfa:	e84a                	sd	s2,16(sp)
    80002cfc:	e44e                	sd	s3,8(sp)
    80002cfe:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d00:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d04:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d08:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d0c:	1004f793          	andi	a5,s1,256
    80002d10:	cb85                	beqz	a5,80002d40 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d12:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d16:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d18:	ef85                	bnez	a5,80002d50 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d1a:	00000097          	auipc	ra,0x0
    80002d1e:	e42080e7          	jalr	-446(ra) # 80002b5c <devintr>
    80002d22:	cd1d                	beqz	a0,80002d60 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d24:	4789                	li	a5,2
    80002d26:	06f50a63          	beq	a0,a5,80002d9a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d2a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d2e:	10049073          	csrw	sstatus,s1
}
    80002d32:	70a2                	ld	ra,40(sp)
    80002d34:	7402                	ld	s0,32(sp)
    80002d36:	64e2                	ld	s1,24(sp)
    80002d38:	6942                	ld	s2,16(sp)
    80002d3a:	69a2                	ld	s3,8(sp)
    80002d3c:	6145                	addi	sp,sp,48
    80002d3e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d40:	00005517          	auipc	a0,0x5
    80002d44:	6f850513          	addi	a0,a0,1784 # 80008438 <states.0+0xc8>
    80002d48:	ffffd097          	auipc	ra,0xffffd
    80002d4c:	7f2080e7          	jalr	2034(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002d50:	00005517          	auipc	a0,0x5
    80002d54:	71050513          	addi	a0,a0,1808 # 80008460 <states.0+0xf0>
    80002d58:	ffffd097          	auipc	ra,0xffffd
    80002d5c:	7e2080e7          	jalr	2018(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002d60:	85ce                	mv	a1,s3
    80002d62:	00005517          	auipc	a0,0x5
    80002d66:	71e50513          	addi	a0,a0,1822 # 80008480 <states.0+0x110>
    80002d6a:	ffffe097          	auipc	ra,0xffffe
    80002d6e:	81a080e7          	jalr	-2022(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d72:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d76:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d7a:	00005517          	auipc	a0,0x5
    80002d7e:	71650513          	addi	a0,a0,1814 # 80008490 <states.0+0x120>
    80002d82:	ffffe097          	auipc	ra,0xffffe
    80002d86:	802080e7          	jalr	-2046(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002d8a:	00005517          	auipc	a0,0x5
    80002d8e:	71e50513          	addi	a0,a0,1822 # 800084a8 <states.0+0x138>
    80002d92:	ffffd097          	auipc	ra,0xffffd
    80002d96:	7a8080e7          	jalr	1960(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	bfc080e7          	jalr	-1028(ra) # 80001996 <myproc>
    80002da2:	d541                	beqz	a0,80002d2a <kerneltrap+0x38>
    80002da4:	fffff097          	auipc	ra,0xfffff
    80002da8:	bf2080e7          	jalr	-1038(ra) # 80001996 <myproc>
    80002dac:	4d18                	lw	a4,24(a0)
    80002dae:	4791                	li	a5,4
    80002db0:	f6f71de3          	bne	a4,a5,80002d2a <kerneltrap+0x38>
    yield();
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	292080e7          	jalr	658(ra) # 80002046 <yield>
    80002dbc:	b7bd                	j	80002d2a <kerneltrap+0x38>

0000000080002dbe <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002dbe:	1101                	addi	sp,sp,-32
    80002dc0:	ec06                	sd	ra,24(sp)
    80002dc2:	e822                	sd	s0,16(sp)
    80002dc4:	e426                	sd	s1,8(sp)
    80002dc6:	1000                	addi	s0,sp,32
    80002dc8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	bcc080e7          	jalr	-1076(ra) # 80001996 <myproc>
  switch (n) {
    80002dd2:	4795                	li	a5,5
    80002dd4:	0497e163          	bltu	a5,s1,80002e16 <argraw+0x58>
    80002dd8:	048a                	slli	s1,s1,0x2
    80002dda:	00005717          	auipc	a4,0x5
    80002dde:	70670713          	addi	a4,a4,1798 # 800084e0 <states.0+0x170>
    80002de2:	94ba                	add	s1,s1,a4
    80002de4:	409c                	lw	a5,0(s1)
    80002de6:	97ba                	add	a5,a5,a4
    80002de8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002dea:	6d3c                	ld	a5,88(a0)
    80002dec:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002dee:	60e2                	ld	ra,24(sp)
    80002df0:	6442                	ld	s0,16(sp)
    80002df2:	64a2                	ld	s1,8(sp)
    80002df4:	6105                	addi	sp,sp,32
    80002df6:	8082                	ret
    return p->trapframe->a1;
    80002df8:	6d3c                	ld	a5,88(a0)
    80002dfa:	7fa8                	ld	a0,120(a5)
    80002dfc:	bfcd                	j	80002dee <argraw+0x30>
    return p->trapframe->a2;
    80002dfe:	6d3c                	ld	a5,88(a0)
    80002e00:	63c8                	ld	a0,128(a5)
    80002e02:	b7f5                	j	80002dee <argraw+0x30>
    return p->trapframe->a3;
    80002e04:	6d3c                	ld	a5,88(a0)
    80002e06:	67c8                	ld	a0,136(a5)
    80002e08:	b7dd                	j	80002dee <argraw+0x30>
    return p->trapframe->a4;
    80002e0a:	6d3c                	ld	a5,88(a0)
    80002e0c:	6bc8                	ld	a0,144(a5)
    80002e0e:	b7c5                	j	80002dee <argraw+0x30>
    return p->trapframe->a5;
    80002e10:	6d3c                	ld	a5,88(a0)
    80002e12:	6fc8                	ld	a0,152(a5)
    80002e14:	bfe9                	j	80002dee <argraw+0x30>
  panic("argraw");
    80002e16:	00005517          	auipc	a0,0x5
    80002e1a:	6a250513          	addi	a0,a0,1698 # 800084b8 <states.0+0x148>
    80002e1e:	ffffd097          	auipc	ra,0xffffd
    80002e22:	71c080e7          	jalr	1820(ra) # 8000053a <panic>

0000000080002e26 <fetchaddr>:
{
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	e426                	sd	s1,8(sp)
    80002e2e:	e04a                	sd	s2,0(sp)
    80002e30:	1000                	addi	s0,sp,32
    80002e32:	84aa                	mv	s1,a0
    80002e34:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	b60080e7          	jalr	-1184(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002e3e:	653c                	ld	a5,72(a0)
    80002e40:	02f4f863          	bgeu	s1,a5,80002e70 <fetchaddr+0x4a>
    80002e44:	00848713          	addi	a4,s1,8
    80002e48:	02e7e663          	bltu	a5,a4,80002e74 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e4c:	46a1                	li	a3,8
    80002e4e:	8626                	mv	a2,s1
    80002e50:	85ca                	mv	a1,s2
    80002e52:	6928                	ld	a0,80(a0)
    80002e54:	fffff097          	auipc	ra,0xfffff
    80002e58:	892080e7          	jalr	-1902(ra) # 800016e6 <copyin>
    80002e5c:	00a03533          	snez	a0,a0
    80002e60:	40a00533          	neg	a0,a0
}
    80002e64:	60e2                	ld	ra,24(sp)
    80002e66:	6442                	ld	s0,16(sp)
    80002e68:	64a2                	ld	s1,8(sp)
    80002e6a:	6902                	ld	s2,0(sp)
    80002e6c:	6105                	addi	sp,sp,32
    80002e6e:	8082                	ret
    return -1;
    80002e70:	557d                	li	a0,-1
    80002e72:	bfcd                	j	80002e64 <fetchaddr+0x3e>
    80002e74:	557d                	li	a0,-1
    80002e76:	b7fd                	j	80002e64 <fetchaddr+0x3e>

0000000080002e78 <fetchstr>:
{
    80002e78:	7179                	addi	sp,sp,-48
    80002e7a:	f406                	sd	ra,40(sp)
    80002e7c:	f022                	sd	s0,32(sp)
    80002e7e:	ec26                	sd	s1,24(sp)
    80002e80:	e84a                	sd	s2,16(sp)
    80002e82:	e44e                	sd	s3,8(sp)
    80002e84:	1800                	addi	s0,sp,48
    80002e86:	892a                	mv	s2,a0
    80002e88:	84ae                	mv	s1,a1
    80002e8a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	b0a080e7          	jalr	-1270(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e94:	86ce                	mv	a3,s3
    80002e96:	864a                	mv	a2,s2
    80002e98:	85a6                	mv	a1,s1
    80002e9a:	6928                	ld	a0,80(a0)
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	8d8080e7          	jalr	-1832(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002ea4:	00054763          	bltz	a0,80002eb2 <fetchstr+0x3a>
  return strlen(buf);
    80002ea8:	8526                	mv	a0,s1
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	f9e080e7          	jalr	-98(ra) # 80000e48 <strlen>
}
    80002eb2:	70a2                	ld	ra,40(sp)
    80002eb4:	7402                	ld	s0,32(sp)
    80002eb6:	64e2                	ld	s1,24(sp)
    80002eb8:	6942                	ld	s2,16(sp)
    80002eba:	69a2                	ld	s3,8(sp)
    80002ebc:	6145                	addi	sp,sp,48
    80002ebe:	8082                	ret

0000000080002ec0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ec0:	1101                	addi	sp,sp,-32
    80002ec2:	ec06                	sd	ra,24(sp)
    80002ec4:	e822                	sd	s0,16(sp)
    80002ec6:	e426                	sd	s1,8(sp)
    80002ec8:	1000                	addi	s0,sp,32
    80002eca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ecc:	00000097          	auipc	ra,0x0
    80002ed0:	ef2080e7          	jalr	-270(ra) # 80002dbe <argraw>
    80002ed4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ed6:	4501                	li	a0,0
    80002ed8:	60e2                	ld	ra,24(sp)
    80002eda:	6442                	ld	s0,16(sp)
    80002edc:	64a2                	ld	s1,8(sp)
    80002ede:	6105                	addi	sp,sp,32
    80002ee0:	8082                	ret

0000000080002ee2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ee2:	1101                	addi	sp,sp,-32
    80002ee4:	ec06                	sd	ra,24(sp)
    80002ee6:	e822                	sd	s0,16(sp)
    80002ee8:	e426                	sd	s1,8(sp)
    80002eea:	1000                	addi	s0,sp,32
    80002eec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002eee:	00000097          	auipc	ra,0x0
    80002ef2:	ed0080e7          	jalr	-304(ra) # 80002dbe <argraw>
    80002ef6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ef8:	4501                	li	a0,0
    80002efa:	60e2                	ld	ra,24(sp)
    80002efc:	6442                	ld	s0,16(sp)
    80002efe:	64a2                	ld	s1,8(sp)
    80002f00:	6105                	addi	sp,sp,32
    80002f02:	8082                	ret

0000000080002f04 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f04:	1101                	addi	sp,sp,-32
    80002f06:	ec06                	sd	ra,24(sp)
    80002f08:	e822                	sd	s0,16(sp)
    80002f0a:	e426                	sd	s1,8(sp)
    80002f0c:	e04a                	sd	s2,0(sp)
    80002f0e:	1000                	addi	s0,sp,32
    80002f10:	84ae                	mv	s1,a1
    80002f12:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f14:	00000097          	auipc	ra,0x0
    80002f18:	eaa080e7          	jalr	-342(ra) # 80002dbe <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f1c:	864a                	mv	a2,s2
    80002f1e:	85a6                	mv	a1,s1
    80002f20:	00000097          	auipc	ra,0x0
    80002f24:	f58080e7          	jalr	-168(ra) # 80002e78 <fetchstr>
}
    80002f28:	60e2                	ld	ra,24(sp)
    80002f2a:	6442                	ld	s0,16(sp)
    80002f2c:	64a2                	ld	s1,8(sp)
    80002f2e:	6902                	ld	s2,0(sp)
    80002f30:	6105                	addi	sp,sp,32
    80002f32:	8082                	ret

0000000080002f34 <syscall>:
[SYS_pinfo]   sys_pinfo,
};

void
syscall(void)
{
    80002f34:	1101                	addi	sp,sp,-32
    80002f36:	ec06                	sd	ra,24(sp)
    80002f38:	e822                	sd	s0,16(sp)
    80002f3a:	e426                	sd	s1,8(sp)
    80002f3c:	e04a                	sd	s2,0(sp)
    80002f3e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f40:	fffff097          	auipc	ra,0xfffff
    80002f44:	a56080e7          	jalr	-1450(ra) # 80001996 <myproc>
    80002f48:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f4a:	05853903          	ld	s2,88(a0)
    80002f4e:	0a893783          	ld	a5,168(s2)
    80002f52:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f56:	37fd                	addiw	a5,a5,-1
    80002f58:	476d                	li	a4,27
    80002f5a:	00f76f63          	bltu	a4,a5,80002f78 <syscall+0x44>
    80002f5e:	00369713          	slli	a4,a3,0x3
    80002f62:	00005797          	auipc	a5,0x5
    80002f66:	59678793          	addi	a5,a5,1430 # 800084f8 <syscalls>
    80002f6a:	97ba                	add	a5,a5,a4
    80002f6c:	639c                	ld	a5,0(a5)
    80002f6e:	c789                	beqz	a5,80002f78 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002f70:	9782                	jalr	a5
    80002f72:	06a93823          	sd	a0,112(s2)
    80002f76:	a839                	j	80002f94 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f78:	15848613          	addi	a2,s1,344
    80002f7c:	588c                	lw	a1,48(s1)
    80002f7e:	00005517          	auipc	a0,0x5
    80002f82:	54250513          	addi	a0,a0,1346 # 800084c0 <states.0+0x150>
    80002f86:	ffffd097          	auipc	ra,0xffffd
    80002f8a:	5fe080e7          	jalr	1534(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f8e:	6cbc                	ld	a5,88(s1)
    80002f90:	577d                	li	a4,-1
    80002f92:	fbb8                	sd	a4,112(a5)
  }
}
    80002f94:	60e2                	ld	ra,24(sp)
    80002f96:	6442                	ld	s0,16(sp)
    80002f98:	64a2                	ld	s1,8(sp)
    80002f9a:	6902                	ld	s2,0(sp)
    80002f9c:	6105                	addi	sp,sp,32
    80002f9e:	8082                	ret

0000000080002fa0 <sys_exit>:
#include "proc.h"
#include "procstat.h"

uint64
sys_exit(void)
{
    80002fa0:	1101                	addi	sp,sp,-32
    80002fa2:	ec06                	sd	ra,24(sp)
    80002fa4:	e822                	sd	s0,16(sp)
    80002fa6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002fa8:	fec40593          	addi	a1,s0,-20
    80002fac:	4501                	li	a0,0
    80002fae:	00000097          	auipc	ra,0x0
    80002fb2:	f12080e7          	jalr	-238(ra) # 80002ec0 <argint>
    return -1;
    80002fb6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fb8:	00054963          	bltz	a0,80002fca <sys_exit+0x2a>
  exit(n);
    80002fbc:	fec42503          	lw	a0,-20(s0)
    80002fc0:	fffff097          	auipc	ra,0xfffff
    80002fc4:	31e080e7          	jalr	798(ra) # 800022de <exit>
  return 0;  // not reached
    80002fc8:	4781                	li	a5,0
}
    80002fca:	853e                	mv	a0,a5
    80002fcc:	60e2                	ld	ra,24(sp)
    80002fce:	6442                	ld	s0,16(sp)
    80002fd0:	6105                	addi	sp,sp,32
    80002fd2:	8082                	ret

0000000080002fd4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002fd4:	1141                	addi	sp,sp,-16
    80002fd6:	e406                	sd	ra,8(sp)
    80002fd8:	e022                	sd	s0,0(sp)
    80002fda:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002fdc:	fffff097          	auipc	ra,0xfffff
    80002fe0:	9ba080e7          	jalr	-1606(ra) # 80001996 <myproc>
}
    80002fe4:	5908                	lw	a0,48(a0)
    80002fe6:	60a2                	ld	ra,8(sp)
    80002fe8:	6402                	ld	s0,0(sp)
    80002fea:	0141                	addi	sp,sp,16
    80002fec:	8082                	ret

0000000080002fee <sys_fork>:

uint64
sys_fork(void)
{
    80002fee:	1141                	addi	sp,sp,-16
    80002ff0:	e406                	sd	ra,8(sp)
    80002ff2:	e022                	sd	s0,0(sp)
    80002ff4:	0800                	addi	s0,sp,16
  return fork();
    80002ff6:	fffff097          	auipc	ra,0xfffff
    80002ffa:	d9a080e7          	jalr	-614(ra) # 80001d90 <fork>
}
    80002ffe:	60a2                	ld	ra,8(sp)
    80003000:	6402                	ld	s0,0(sp)
    80003002:	0141                	addi	sp,sp,16
    80003004:	8082                	ret

0000000080003006 <sys_wait>:

uint64
sys_wait(void)
{
    80003006:	1101                	addi	sp,sp,-32
    80003008:	ec06                	sd	ra,24(sp)
    8000300a:	e822                	sd	s0,16(sp)
    8000300c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000300e:	fe840593          	addi	a1,s0,-24
    80003012:	4501                	li	a0,0
    80003014:	00000097          	auipc	ra,0x0
    80003018:	ece080e7          	jalr	-306(ra) # 80002ee2 <argaddr>
    8000301c:	87aa                	mv	a5,a0
    return -1;
    8000301e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003020:	0007c863          	bltz	a5,80003030 <sys_wait+0x2a>
  return wait(p);
    80003024:	fe843503          	ld	a0,-24(s0)
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	0be080e7          	jalr	190(ra) # 800020e6 <wait>
}
    80003030:	60e2                	ld	ra,24(sp)
    80003032:	6442                	ld	s0,16(sp)
    80003034:	6105                	addi	sp,sp,32
    80003036:	8082                	ret

0000000080003038 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003038:	7179                	addi	sp,sp,-48
    8000303a:	f406                	sd	ra,40(sp)
    8000303c:	f022                	sd	s0,32(sp)
    8000303e:	ec26                	sd	s1,24(sp)
    80003040:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003042:	fdc40593          	addi	a1,s0,-36
    80003046:	4501                	li	a0,0
    80003048:	00000097          	auipc	ra,0x0
    8000304c:	e78080e7          	jalr	-392(ra) # 80002ec0 <argint>
    80003050:	87aa                	mv	a5,a0
    return -1;
    80003052:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003054:	0207c063          	bltz	a5,80003074 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003058:	fffff097          	auipc	ra,0xfffff
    8000305c:	93e080e7          	jalr	-1730(ra) # 80001996 <myproc>
    80003060:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003062:	fdc42503          	lw	a0,-36(s0)
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	cb2080e7          	jalr	-846(ra) # 80001d18 <growproc>
    8000306e:	00054863          	bltz	a0,8000307e <sys_sbrk+0x46>
    return -1;
  return addr;
    80003072:	8526                	mv	a0,s1
}
    80003074:	70a2                	ld	ra,40(sp)
    80003076:	7402                	ld	s0,32(sp)
    80003078:	64e2                	ld	s1,24(sp)
    8000307a:	6145                	addi	sp,sp,48
    8000307c:	8082                	ret
    return -1;
    8000307e:	557d                	li	a0,-1
    80003080:	bfd5                	j	80003074 <sys_sbrk+0x3c>

0000000080003082 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003082:	7139                	addi	sp,sp,-64
    80003084:	fc06                	sd	ra,56(sp)
    80003086:	f822                	sd	s0,48(sp)
    80003088:	f426                	sd	s1,40(sp)
    8000308a:	f04a                	sd	s2,32(sp)
    8000308c:	ec4e                	sd	s3,24(sp)
    8000308e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003090:	fcc40593          	addi	a1,s0,-52
    80003094:	4501                	li	a0,0
    80003096:	00000097          	auipc	ra,0x0
    8000309a:	e2a080e7          	jalr	-470(ra) # 80002ec0 <argint>
    return -1;
    8000309e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030a0:	06054563          	bltz	a0,8000310a <sys_sleep+0x88>
  acquire(&tickslock);
    800030a4:	00014517          	auipc	a0,0x14
    800030a8:	62c50513          	addi	a0,a0,1580 # 800176d0 <tickslock>
    800030ac:	ffffe097          	auipc	ra,0xffffe
    800030b0:	b24080e7          	jalr	-1244(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    800030b4:	00006917          	auipc	s2,0x6
    800030b8:	f7c92903          	lw	s2,-132(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800030bc:	fcc42783          	lw	a5,-52(s0)
    800030c0:	cf85                	beqz	a5,800030f8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030c2:	00014997          	auipc	s3,0x14
    800030c6:	60e98993          	addi	s3,s3,1550 # 800176d0 <tickslock>
    800030ca:	00006497          	auipc	s1,0x6
    800030ce:	f6648493          	addi	s1,s1,-154 # 80009030 <ticks>
    if(myproc()->killed){
    800030d2:	fffff097          	auipc	ra,0xfffff
    800030d6:	8c4080e7          	jalr	-1852(ra) # 80001996 <myproc>
    800030da:	551c                	lw	a5,40(a0)
    800030dc:	ef9d                	bnez	a5,8000311a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800030de:	85ce                	mv	a1,s3
    800030e0:	8526                	mv	a0,s1
    800030e2:	fffff097          	auipc	ra,0xfffff
    800030e6:	fa0080e7          	jalr	-96(ra) # 80002082 <sleep>
  while(ticks - ticks0 < n){
    800030ea:	409c                	lw	a5,0(s1)
    800030ec:	412787bb          	subw	a5,a5,s2
    800030f0:	fcc42703          	lw	a4,-52(s0)
    800030f4:	fce7efe3          	bltu	a5,a4,800030d2 <sys_sleep+0x50>
  }
  release(&tickslock);
    800030f8:	00014517          	auipc	a0,0x14
    800030fc:	5d850513          	addi	a0,a0,1496 # 800176d0 <tickslock>
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	b84080e7          	jalr	-1148(ra) # 80000c84 <release>
  return 0;
    80003108:	4781                	li	a5,0
}
    8000310a:	853e                	mv	a0,a5
    8000310c:	70e2                	ld	ra,56(sp)
    8000310e:	7442                	ld	s0,48(sp)
    80003110:	74a2                	ld	s1,40(sp)
    80003112:	7902                	ld	s2,32(sp)
    80003114:	69e2                	ld	s3,24(sp)
    80003116:	6121                	addi	sp,sp,64
    80003118:	8082                	ret
      release(&tickslock);
    8000311a:	00014517          	auipc	a0,0x14
    8000311e:	5b650513          	addi	a0,a0,1462 # 800176d0 <tickslock>
    80003122:	ffffe097          	auipc	ra,0xffffe
    80003126:	b62080e7          	jalr	-1182(ra) # 80000c84 <release>
      return -1;
    8000312a:	57fd                	li	a5,-1
    8000312c:	bff9                	j	8000310a <sys_sleep+0x88>

000000008000312e <sys_kill>:

uint64
sys_kill(void)
{
    8000312e:	1101                	addi	sp,sp,-32
    80003130:	ec06                	sd	ra,24(sp)
    80003132:	e822                	sd	s0,16(sp)
    80003134:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003136:	fec40593          	addi	a1,s0,-20
    8000313a:	4501                	li	a0,0
    8000313c:	00000097          	auipc	ra,0x0
    80003140:	d84080e7          	jalr	-636(ra) # 80002ec0 <argint>
    80003144:	87aa                	mv	a5,a0
    return -1;
    80003146:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003148:	0007c863          	bltz	a5,80003158 <sys_kill+0x2a>
  return kill(pid);
    8000314c:	fec42503          	lw	a0,-20(s0)
    80003150:	fffff097          	auipc	ra,0xfffff
    80003154:	270080e7          	jalr	624(ra) # 800023c0 <kill>
}
    80003158:	60e2                	ld	ra,24(sp)
    8000315a:	6442                	ld	s0,16(sp)
    8000315c:	6105                	addi	sp,sp,32
    8000315e:	8082                	ret

0000000080003160 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003160:	1101                	addi	sp,sp,-32
    80003162:	ec06                	sd	ra,24(sp)
    80003164:	e822                	sd	s0,16(sp)
    80003166:	e426                	sd	s1,8(sp)
    80003168:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000316a:	00014517          	auipc	a0,0x14
    8000316e:	56650513          	addi	a0,a0,1382 # 800176d0 <tickslock>
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	a5e080e7          	jalr	-1442(ra) # 80000bd0 <acquire>
  xticks = ticks;
    8000317a:	00006497          	auipc	s1,0x6
    8000317e:	eb64a483          	lw	s1,-330(s1) # 80009030 <ticks>
  release(&tickslock);
    80003182:	00014517          	auipc	a0,0x14
    80003186:	54e50513          	addi	a0,a0,1358 # 800176d0 <tickslock>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	afa080e7          	jalr	-1286(ra) # 80000c84 <release>
  return xticks;
}
    80003192:	02049513          	slli	a0,s1,0x20
    80003196:	9101                	srli	a0,a0,0x20
    80003198:	60e2                	ld	ra,24(sp)
    8000319a:	6442                	ld	s0,16(sp)
    8000319c:	64a2                	ld	s1,8(sp)
    8000319e:	6105                	addi	sp,sp,32
    800031a0:	8082                	ret

00000000800031a2 <sys_getppid>:

uint64
sys_getppid(void)
{
    800031a2:	1141                	addi	sp,sp,-16
    800031a4:	e406                	sd	ra,8(sp)
    800031a6:	e022                	sd	s0,0(sp)
    800031a8:	0800                	addi	s0,sp,16
  struct proc* par_proc = myproc()->parent;
    800031aa:	ffffe097          	auipc	ra,0xffffe
    800031ae:	7ec080e7          	jalr	2028(ra) # 80001996 <myproc>
    800031b2:	7d1c                	ld	a5,56(a0)
  if(par_proc) return par_proc->pid;
    800031b4:	c791                	beqz	a5,800031c0 <sys_getppid+0x1e>
    800031b6:	5b88                	lw	a0,48(a5)
  else return -1;
}
    800031b8:	60a2                	ld	ra,8(sp)
    800031ba:	6402                	ld	s0,0(sp)
    800031bc:	0141                	addi	sp,sp,16
    800031be:	8082                	ret
  else return -1;
    800031c0:	557d                	li	a0,-1
    800031c2:	bfdd                	j	800031b8 <sys_getppid+0x16>

00000000800031c4 <sys_yield>:

uint64
sys_yield(void)
{
    800031c4:	1141                	addi	sp,sp,-16
    800031c6:	e406                	sd	ra,8(sp)
    800031c8:	e022                	sd	s0,0(sp)
    800031ca:	0800                	addi	s0,sp,16
  yield();
    800031cc:	fffff097          	auipc	ra,0xfffff
    800031d0:	e7a080e7          	jalr	-390(ra) # 80002046 <yield>
  return 0;
}
    800031d4:	4501                	li	a0,0
    800031d6:	60a2                	ld	ra,8(sp)
    800031d8:	6402                	ld	s0,0(sp)
    800031da:	0141                	addi	sp,sp,16
    800031dc:	8082                	ret

00000000800031de <sys_getpa>:

uint64
sys_getpa(void)
{
    800031de:	1101                	addi	sp,sp,-32
    800031e0:	ec06                	sd	ra,24(sp)
    800031e2:	e822                	sd	s0,16(sp)
    800031e4:	1000                	addi	s0,sp,32
  uint64 va;
  if(argaddr(0, &va) < 0)
    800031e6:	fe840593          	addi	a1,s0,-24
    800031ea:	4501                	li	a0,0
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	cf6080e7          	jalr	-778(ra) # 80002ee2 <argaddr>
    800031f4:	87aa                	mv	a5,a0
    return -1;
    800031f6:	557d                	li	a0,-1
  if(argaddr(0, &va) < 0)
    800031f8:	0207c263          	bltz	a5,8000321c <sys_getpa+0x3e>
    
  return walkaddr(myproc()->pagetable, va) + (va & (PGSIZE - 1));
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	79a080e7          	jalr	1946(ra) # 80001996 <myproc>
    80003204:	fe843583          	ld	a1,-24(s0)
    80003208:	6928                	ld	a0,80(a0)
    8000320a:	ffffe097          	auipc	ra,0xffffe
    8000320e:	e48080e7          	jalr	-440(ra) # 80001052 <walkaddr>
    80003212:	fe843783          	ld	a5,-24(s0)
    80003216:	17d2                	slli	a5,a5,0x34
    80003218:	93d1                	srli	a5,a5,0x34
    8000321a:	953e                	add	a0,a0,a5
}
    8000321c:	60e2                	ld	ra,24(sp)
    8000321e:	6442                	ld	s0,16(sp)
    80003220:	6105                	addi	sp,sp,32
    80003222:	8082                	ret

0000000080003224 <sys_forkf>:

uint64
sys_forkf(void)
{
    80003224:	1101                	addi	sp,sp,-32
    80003226:	ec06                	sd	ra,24(sp)
    80003228:	e822                	sd	s0,16(sp)
    8000322a:	1000                	addi	s0,sp,32
  uint64 fa;
  if(argaddr(0, &fa) < 0)
    8000322c:	fe840593          	addi	a1,s0,-24
    80003230:	4501                	li	a0,0
    80003232:	00000097          	auipc	ra,0x0
    80003236:	cb0080e7          	jalr	-848(ra) # 80002ee2 <argaddr>
    8000323a:	87aa                	mv	a5,a0
    return -1;
    8000323c:	557d                	li	a0,-1
  if(argaddr(0, &fa) < 0)
    8000323e:	0007c863          	bltz	a5,8000324e <sys_forkf+0x2a>
  return forkf(fa);
    80003242:	fe843503          	ld	a0,-24(s0)
    80003246:	fffff097          	auipc	ra,0xfffff
    8000324a:	348080e7          	jalr	840(ra) # 8000258e <forkf>
}
    8000324e:	60e2                	ld	ra,24(sp)
    80003250:	6442                	ld	s0,16(sp)
    80003252:	6105                	addi	sp,sp,32
    80003254:	8082                	ret

0000000080003256 <sys_waitpid>:

uint64
sys_waitpid(void)
{
    80003256:	1101                	addi	sp,sp,-32
    80003258:	ec06                	sd	ra,24(sp)
    8000325a:	e822                	sd	s0,16(sp)
    8000325c:	1000                	addi	s0,sp,32
  uint64 pid;
  uint64 p;
  if(argaddr(0, &pid) < 0)
    8000325e:	fe840593          	addi	a1,s0,-24
    80003262:	4501                	li	a0,0
    80003264:	00000097          	auipc	ra,0x0
    80003268:	c7e080e7          	jalr	-898(ra) # 80002ee2 <argaddr>
    8000326c:	87aa                	mv	a5,a0
    return -1;
    8000326e:	557d                	li	a0,-1
  if(argaddr(0, &pid) < 0)
    80003270:	0207c663          	bltz	a5,8000329c <sys_waitpid+0x46>
  if(argaddr(1, &p) < 0)
    80003274:	fe040593          	addi	a1,s0,-32
    80003278:	4505                	li	a0,1
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	c68080e7          	jalr	-920(ra) # 80002ee2 <argaddr>
    80003282:	02054863          	bltz	a0,800032b2 <sys_waitpid+0x5c>
    return -1;
  // printf("%d\n", p);
  if(pid == -1)
    80003286:	fe843503          	ld	a0,-24(s0)
    8000328a:	57fd                	li	a5,-1
    8000328c:	00f50c63          	beq	a0,a5,800032a4 <sys_waitpid+0x4e>
    return wait(p);
  return waitpid(pid, p);
    80003290:	fe043583          	ld	a1,-32(s0)
    80003294:	fffff097          	auipc	ra,0xfffff
    80003298:	446080e7          	jalr	1094(ra) # 800026da <waitpid>
}
    8000329c:	60e2                	ld	ra,24(sp)
    8000329e:	6442                	ld	s0,16(sp)
    800032a0:	6105                	addi	sp,sp,32
    800032a2:	8082                	ret
    return wait(p);
    800032a4:	fe043503          	ld	a0,-32(s0)
    800032a8:	fffff097          	auipc	ra,0xfffff
    800032ac:	e3e080e7          	jalr	-450(ra) # 800020e6 <wait>
    800032b0:	b7f5                	j	8000329c <sys_waitpid+0x46>
    return -1;
    800032b2:	557d                	li	a0,-1
    800032b4:	b7e5                	j	8000329c <sys_waitpid+0x46>

00000000800032b6 <sys_ps>:

uint64
sys_ps(void){
    800032b6:	1141                	addi	sp,sp,-16
    800032b8:	e406                	sd	ra,8(sp)
    800032ba:	e022                	sd	s0,0(sp)
    800032bc:	0800                	addi	s0,sp,16
  ps();
    800032be:	fffff097          	auipc	ra,0xfffff
    800032c2:	550080e7          	jalr	1360(ra) # 8000280e <ps>
  return 0;
}
    800032c6:	4501                	li	a0,0
    800032c8:	60a2                	ld	ra,8(sp)
    800032ca:	6402                	ld	s0,0(sp)
    800032cc:	0141                	addi	sp,sp,16
    800032ce:	8082                	ret

00000000800032d0 <sys_pinfo>:

uint64
sys_pinfo(void){
    800032d0:	1101                	addi	sp,sp,-32
    800032d2:	ec06                	sd	ra,24(sp)
    800032d4:	e822                	sd	s0,16(sp)
    800032d6:	1000                	addi	s0,sp,32
  uint64 pid;
  uint64 p;
  if(argaddr(0, &pid) < 0)
    800032d8:	fe840593          	addi	a1,s0,-24
    800032dc:	4501                	li	a0,0
    800032de:	00000097          	auipc	ra,0x0
    800032e2:	c04080e7          	jalr	-1020(ra) # 80002ee2 <argaddr>
    800032e6:	04054663          	bltz	a0,80003332 <sys_pinfo+0x62>
    return -1;
  if(pid == -1) 
    800032ea:	fe843703          	ld	a4,-24(s0)
    800032ee:	57fd                	li	a5,-1
    800032f0:	02f70963          	beq	a4,a5,80003322 <sys_pinfo+0x52>
    pid = myproc()->pid;
  if(argaddr(1, &p) < 0)
    800032f4:	fe040593          	addi	a1,s0,-32
    800032f8:	4505                	li	a0,1
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	be8080e7          	jalr	-1048(ra) # 80002ee2 <argaddr>
    80003302:	87aa                	mv	a5,a0
    return -1;
    80003304:	557d                	li	a0,-1
  if(argaddr(1, &p) < 0)
    80003306:	0007ca63          	bltz	a5,8000331a <sys_pinfo+0x4a>
  // p = (struct procstat*)p;
  // printf("sysproc: %s\n", p->pid);
  return pinfo(pid, p);
    8000330a:	fe043583          	ld	a1,-32(s0)
    8000330e:	fe843503          	ld	a0,-24(s0)
    80003312:	fffff097          	auipc	ra,0xfffff
    80003316:	5be080e7          	jalr	1470(ra) # 800028d0 <pinfo>
    8000331a:	60e2                	ld	ra,24(sp)
    8000331c:	6442                	ld	s0,16(sp)
    8000331e:	6105                	addi	sp,sp,32
    80003320:	8082                	ret
    pid = myproc()->pid;
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	674080e7          	jalr	1652(ra) # 80001996 <myproc>
    8000332a:	591c                	lw	a5,48(a0)
    8000332c:	fef43423          	sd	a5,-24(s0)
    80003330:	b7d1                	j	800032f4 <sys_pinfo+0x24>
    return -1;
    80003332:	557d                	li	a0,-1
    80003334:	b7dd                	j	8000331a <sys_pinfo+0x4a>

0000000080003336 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003336:	7179                	addi	sp,sp,-48
    80003338:	f406                	sd	ra,40(sp)
    8000333a:	f022                	sd	s0,32(sp)
    8000333c:	ec26                	sd	s1,24(sp)
    8000333e:	e84a                	sd	s2,16(sp)
    80003340:	e44e                	sd	s3,8(sp)
    80003342:	e052                	sd	s4,0(sp)
    80003344:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003346:	00005597          	auipc	a1,0x5
    8000334a:	29a58593          	addi	a1,a1,666 # 800085e0 <syscalls+0xe8>
    8000334e:	00014517          	auipc	a0,0x14
    80003352:	39a50513          	addi	a0,a0,922 # 800176e8 <bcache>
    80003356:	ffffd097          	auipc	ra,0xffffd
    8000335a:	7ea080e7          	jalr	2026(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000335e:	0001c797          	auipc	a5,0x1c
    80003362:	38a78793          	addi	a5,a5,906 # 8001f6e8 <bcache+0x8000>
    80003366:	0001c717          	auipc	a4,0x1c
    8000336a:	5ea70713          	addi	a4,a4,1514 # 8001f950 <bcache+0x8268>
    8000336e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003372:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003376:	00014497          	auipc	s1,0x14
    8000337a:	38a48493          	addi	s1,s1,906 # 80017700 <bcache+0x18>
    b->next = bcache.head.next;
    8000337e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003380:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003382:	00005a17          	auipc	s4,0x5
    80003386:	266a0a13          	addi	s4,s4,614 # 800085e8 <syscalls+0xf0>
    b->next = bcache.head.next;
    8000338a:	2b893783          	ld	a5,696(s2)
    8000338e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003390:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003394:	85d2                	mv	a1,s4
    80003396:	01048513          	addi	a0,s1,16
    8000339a:	00001097          	auipc	ra,0x1
    8000339e:	4c2080e7          	jalr	1218(ra) # 8000485c <initsleeplock>
    bcache.head.next->prev = b;
    800033a2:	2b893783          	ld	a5,696(s2)
    800033a6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033a8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033ac:	45848493          	addi	s1,s1,1112
    800033b0:	fd349de3          	bne	s1,s3,8000338a <binit+0x54>
  }
}
    800033b4:	70a2                	ld	ra,40(sp)
    800033b6:	7402                	ld	s0,32(sp)
    800033b8:	64e2                	ld	s1,24(sp)
    800033ba:	6942                	ld	s2,16(sp)
    800033bc:	69a2                	ld	s3,8(sp)
    800033be:	6a02                	ld	s4,0(sp)
    800033c0:	6145                	addi	sp,sp,48
    800033c2:	8082                	ret

00000000800033c4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033c4:	7179                	addi	sp,sp,-48
    800033c6:	f406                	sd	ra,40(sp)
    800033c8:	f022                	sd	s0,32(sp)
    800033ca:	ec26                	sd	s1,24(sp)
    800033cc:	e84a                	sd	s2,16(sp)
    800033ce:	e44e                	sd	s3,8(sp)
    800033d0:	1800                	addi	s0,sp,48
    800033d2:	892a                	mv	s2,a0
    800033d4:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800033d6:	00014517          	auipc	a0,0x14
    800033da:	31250513          	addi	a0,a0,786 # 800176e8 <bcache>
    800033de:	ffffd097          	auipc	ra,0xffffd
    800033e2:	7f2080e7          	jalr	2034(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033e6:	0001c497          	auipc	s1,0x1c
    800033ea:	5ba4b483          	ld	s1,1466(s1) # 8001f9a0 <bcache+0x82b8>
    800033ee:	0001c797          	auipc	a5,0x1c
    800033f2:	56278793          	addi	a5,a5,1378 # 8001f950 <bcache+0x8268>
    800033f6:	02f48f63          	beq	s1,a5,80003434 <bread+0x70>
    800033fa:	873e                	mv	a4,a5
    800033fc:	a021                	j	80003404 <bread+0x40>
    800033fe:	68a4                	ld	s1,80(s1)
    80003400:	02e48a63          	beq	s1,a4,80003434 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003404:	449c                	lw	a5,8(s1)
    80003406:	ff279ce3          	bne	a5,s2,800033fe <bread+0x3a>
    8000340a:	44dc                	lw	a5,12(s1)
    8000340c:	ff3799e3          	bne	a5,s3,800033fe <bread+0x3a>
      b->refcnt++;
    80003410:	40bc                	lw	a5,64(s1)
    80003412:	2785                	addiw	a5,a5,1
    80003414:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003416:	00014517          	auipc	a0,0x14
    8000341a:	2d250513          	addi	a0,a0,722 # 800176e8 <bcache>
    8000341e:	ffffe097          	auipc	ra,0xffffe
    80003422:	866080e7          	jalr	-1946(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80003426:	01048513          	addi	a0,s1,16
    8000342a:	00001097          	auipc	ra,0x1
    8000342e:	46c080e7          	jalr	1132(ra) # 80004896 <acquiresleep>
      return b;
    80003432:	a8b9                	j	80003490 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003434:	0001c497          	auipc	s1,0x1c
    80003438:	5644b483          	ld	s1,1380(s1) # 8001f998 <bcache+0x82b0>
    8000343c:	0001c797          	auipc	a5,0x1c
    80003440:	51478793          	addi	a5,a5,1300 # 8001f950 <bcache+0x8268>
    80003444:	00f48863          	beq	s1,a5,80003454 <bread+0x90>
    80003448:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000344a:	40bc                	lw	a5,64(s1)
    8000344c:	cf81                	beqz	a5,80003464 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000344e:	64a4                	ld	s1,72(s1)
    80003450:	fee49de3          	bne	s1,a4,8000344a <bread+0x86>
  panic("bget: no buffers");
    80003454:	00005517          	auipc	a0,0x5
    80003458:	19c50513          	addi	a0,a0,412 # 800085f0 <syscalls+0xf8>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	0de080e7          	jalr	222(ra) # 8000053a <panic>
      b->dev = dev;
    80003464:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003468:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000346c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003470:	4785                	li	a5,1
    80003472:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003474:	00014517          	auipc	a0,0x14
    80003478:	27450513          	addi	a0,a0,628 # 800176e8 <bcache>
    8000347c:	ffffe097          	auipc	ra,0xffffe
    80003480:	808080e7          	jalr	-2040(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80003484:	01048513          	addi	a0,s1,16
    80003488:	00001097          	auipc	ra,0x1
    8000348c:	40e080e7          	jalr	1038(ra) # 80004896 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003490:	409c                	lw	a5,0(s1)
    80003492:	cb89                	beqz	a5,800034a4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003494:	8526                	mv	a0,s1
    80003496:	70a2                	ld	ra,40(sp)
    80003498:	7402                	ld	s0,32(sp)
    8000349a:	64e2                	ld	s1,24(sp)
    8000349c:	6942                	ld	s2,16(sp)
    8000349e:	69a2                	ld	s3,8(sp)
    800034a0:	6145                	addi	sp,sp,48
    800034a2:	8082                	ret
    virtio_disk_rw(b, 0);
    800034a4:	4581                	li	a1,0
    800034a6:	8526                	mv	a0,s1
    800034a8:	00003097          	auipc	ra,0x3
    800034ac:	f2a080e7          	jalr	-214(ra) # 800063d2 <virtio_disk_rw>
    b->valid = 1;
    800034b0:	4785                	li	a5,1
    800034b2:	c09c                	sw	a5,0(s1)
  return b;
    800034b4:	b7c5                	j	80003494 <bread+0xd0>

00000000800034b6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034b6:	1101                	addi	sp,sp,-32
    800034b8:	ec06                	sd	ra,24(sp)
    800034ba:	e822                	sd	s0,16(sp)
    800034bc:	e426                	sd	s1,8(sp)
    800034be:	1000                	addi	s0,sp,32
    800034c0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034c2:	0541                	addi	a0,a0,16
    800034c4:	00001097          	auipc	ra,0x1
    800034c8:	46c080e7          	jalr	1132(ra) # 80004930 <holdingsleep>
    800034cc:	cd01                	beqz	a0,800034e4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034ce:	4585                	li	a1,1
    800034d0:	8526                	mv	a0,s1
    800034d2:	00003097          	auipc	ra,0x3
    800034d6:	f00080e7          	jalr	-256(ra) # 800063d2 <virtio_disk_rw>
}
    800034da:	60e2                	ld	ra,24(sp)
    800034dc:	6442                	ld	s0,16(sp)
    800034de:	64a2                	ld	s1,8(sp)
    800034e0:	6105                	addi	sp,sp,32
    800034e2:	8082                	ret
    panic("bwrite");
    800034e4:	00005517          	auipc	a0,0x5
    800034e8:	12450513          	addi	a0,a0,292 # 80008608 <syscalls+0x110>
    800034ec:	ffffd097          	auipc	ra,0xffffd
    800034f0:	04e080e7          	jalr	78(ra) # 8000053a <panic>

00000000800034f4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034f4:	1101                	addi	sp,sp,-32
    800034f6:	ec06                	sd	ra,24(sp)
    800034f8:	e822                	sd	s0,16(sp)
    800034fa:	e426                	sd	s1,8(sp)
    800034fc:	e04a                	sd	s2,0(sp)
    800034fe:	1000                	addi	s0,sp,32
    80003500:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003502:	01050913          	addi	s2,a0,16
    80003506:	854a                	mv	a0,s2
    80003508:	00001097          	auipc	ra,0x1
    8000350c:	428080e7          	jalr	1064(ra) # 80004930 <holdingsleep>
    80003510:	c92d                	beqz	a0,80003582 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003512:	854a                	mv	a0,s2
    80003514:	00001097          	auipc	ra,0x1
    80003518:	3d8080e7          	jalr	984(ra) # 800048ec <releasesleep>

  acquire(&bcache.lock);
    8000351c:	00014517          	auipc	a0,0x14
    80003520:	1cc50513          	addi	a0,a0,460 # 800176e8 <bcache>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	6ac080e7          	jalr	1708(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000352c:	40bc                	lw	a5,64(s1)
    8000352e:	37fd                	addiw	a5,a5,-1
    80003530:	0007871b          	sext.w	a4,a5
    80003534:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003536:	eb05                	bnez	a4,80003566 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003538:	68bc                	ld	a5,80(s1)
    8000353a:	64b8                	ld	a4,72(s1)
    8000353c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000353e:	64bc                	ld	a5,72(s1)
    80003540:	68b8                	ld	a4,80(s1)
    80003542:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003544:	0001c797          	auipc	a5,0x1c
    80003548:	1a478793          	addi	a5,a5,420 # 8001f6e8 <bcache+0x8000>
    8000354c:	2b87b703          	ld	a4,696(a5)
    80003550:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003552:	0001c717          	auipc	a4,0x1c
    80003556:	3fe70713          	addi	a4,a4,1022 # 8001f950 <bcache+0x8268>
    8000355a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000355c:	2b87b703          	ld	a4,696(a5)
    80003560:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003562:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003566:	00014517          	auipc	a0,0x14
    8000356a:	18250513          	addi	a0,a0,386 # 800176e8 <bcache>
    8000356e:	ffffd097          	auipc	ra,0xffffd
    80003572:	716080e7          	jalr	1814(ra) # 80000c84 <release>
}
    80003576:	60e2                	ld	ra,24(sp)
    80003578:	6442                	ld	s0,16(sp)
    8000357a:	64a2                	ld	s1,8(sp)
    8000357c:	6902                	ld	s2,0(sp)
    8000357e:	6105                	addi	sp,sp,32
    80003580:	8082                	ret
    panic("brelse");
    80003582:	00005517          	auipc	a0,0x5
    80003586:	08e50513          	addi	a0,a0,142 # 80008610 <syscalls+0x118>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	fb0080e7          	jalr	-80(ra) # 8000053a <panic>

0000000080003592 <bpin>:

void
bpin(struct buf *b) {
    80003592:	1101                	addi	sp,sp,-32
    80003594:	ec06                	sd	ra,24(sp)
    80003596:	e822                	sd	s0,16(sp)
    80003598:	e426                	sd	s1,8(sp)
    8000359a:	1000                	addi	s0,sp,32
    8000359c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000359e:	00014517          	auipc	a0,0x14
    800035a2:	14a50513          	addi	a0,a0,330 # 800176e8 <bcache>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	62a080e7          	jalr	1578(ra) # 80000bd0 <acquire>
  b->refcnt++;
    800035ae:	40bc                	lw	a5,64(s1)
    800035b0:	2785                	addiw	a5,a5,1
    800035b2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035b4:	00014517          	auipc	a0,0x14
    800035b8:	13450513          	addi	a0,a0,308 # 800176e8 <bcache>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	6c8080e7          	jalr	1736(ra) # 80000c84 <release>
}
    800035c4:	60e2                	ld	ra,24(sp)
    800035c6:	6442                	ld	s0,16(sp)
    800035c8:	64a2                	ld	s1,8(sp)
    800035ca:	6105                	addi	sp,sp,32
    800035cc:	8082                	ret

00000000800035ce <bunpin>:

void
bunpin(struct buf *b) {
    800035ce:	1101                	addi	sp,sp,-32
    800035d0:	ec06                	sd	ra,24(sp)
    800035d2:	e822                	sd	s0,16(sp)
    800035d4:	e426                	sd	s1,8(sp)
    800035d6:	1000                	addi	s0,sp,32
    800035d8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035da:	00014517          	auipc	a0,0x14
    800035de:	10e50513          	addi	a0,a0,270 # 800176e8 <bcache>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	5ee080e7          	jalr	1518(ra) # 80000bd0 <acquire>
  b->refcnt--;
    800035ea:	40bc                	lw	a5,64(s1)
    800035ec:	37fd                	addiw	a5,a5,-1
    800035ee:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035f0:	00014517          	auipc	a0,0x14
    800035f4:	0f850513          	addi	a0,a0,248 # 800176e8 <bcache>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	68c080e7          	jalr	1676(ra) # 80000c84 <release>
}
    80003600:	60e2                	ld	ra,24(sp)
    80003602:	6442                	ld	s0,16(sp)
    80003604:	64a2                	ld	s1,8(sp)
    80003606:	6105                	addi	sp,sp,32
    80003608:	8082                	ret

000000008000360a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000360a:	1101                	addi	sp,sp,-32
    8000360c:	ec06                	sd	ra,24(sp)
    8000360e:	e822                	sd	s0,16(sp)
    80003610:	e426                	sd	s1,8(sp)
    80003612:	e04a                	sd	s2,0(sp)
    80003614:	1000                	addi	s0,sp,32
    80003616:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003618:	00d5d59b          	srliw	a1,a1,0xd
    8000361c:	0001c797          	auipc	a5,0x1c
    80003620:	7a87a783          	lw	a5,1960(a5) # 8001fdc4 <sb+0x1c>
    80003624:	9dbd                	addw	a1,a1,a5
    80003626:	00000097          	auipc	ra,0x0
    8000362a:	d9e080e7          	jalr	-610(ra) # 800033c4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000362e:	0074f713          	andi	a4,s1,7
    80003632:	4785                	li	a5,1
    80003634:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003638:	14ce                	slli	s1,s1,0x33
    8000363a:	90d9                	srli	s1,s1,0x36
    8000363c:	00950733          	add	a4,a0,s1
    80003640:	05874703          	lbu	a4,88(a4)
    80003644:	00e7f6b3          	and	a3,a5,a4
    80003648:	c69d                	beqz	a3,80003676 <bfree+0x6c>
    8000364a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000364c:	94aa                	add	s1,s1,a0
    8000364e:	fff7c793          	not	a5,a5
    80003652:	8f7d                	and	a4,a4,a5
    80003654:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003658:	00001097          	auipc	ra,0x1
    8000365c:	120080e7          	jalr	288(ra) # 80004778 <log_write>
  brelse(bp);
    80003660:	854a                	mv	a0,s2
    80003662:	00000097          	auipc	ra,0x0
    80003666:	e92080e7          	jalr	-366(ra) # 800034f4 <brelse>
}
    8000366a:	60e2                	ld	ra,24(sp)
    8000366c:	6442                	ld	s0,16(sp)
    8000366e:	64a2                	ld	s1,8(sp)
    80003670:	6902                	ld	s2,0(sp)
    80003672:	6105                	addi	sp,sp,32
    80003674:	8082                	ret
    panic("freeing free block");
    80003676:	00005517          	auipc	a0,0x5
    8000367a:	fa250513          	addi	a0,a0,-94 # 80008618 <syscalls+0x120>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	ebc080e7          	jalr	-324(ra) # 8000053a <panic>

0000000080003686 <balloc>:
{
    80003686:	711d                	addi	sp,sp,-96
    80003688:	ec86                	sd	ra,88(sp)
    8000368a:	e8a2                	sd	s0,80(sp)
    8000368c:	e4a6                	sd	s1,72(sp)
    8000368e:	e0ca                	sd	s2,64(sp)
    80003690:	fc4e                	sd	s3,56(sp)
    80003692:	f852                	sd	s4,48(sp)
    80003694:	f456                	sd	s5,40(sp)
    80003696:	f05a                	sd	s6,32(sp)
    80003698:	ec5e                	sd	s7,24(sp)
    8000369a:	e862                	sd	s8,16(sp)
    8000369c:	e466                	sd	s9,8(sp)
    8000369e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036a0:	0001c797          	auipc	a5,0x1c
    800036a4:	70c7a783          	lw	a5,1804(a5) # 8001fdac <sb+0x4>
    800036a8:	cbc1                	beqz	a5,80003738 <balloc+0xb2>
    800036aa:	8baa                	mv	s7,a0
    800036ac:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036ae:	0001cb17          	auipc	s6,0x1c
    800036b2:	6fab0b13          	addi	s6,s6,1786 # 8001fda8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036b8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ba:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036bc:	6c89                	lui	s9,0x2
    800036be:	a831                	j	800036da <balloc+0x54>
    brelse(bp);
    800036c0:	854a                	mv	a0,s2
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	e32080e7          	jalr	-462(ra) # 800034f4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036ca:	015c87bb          	addw	a5,s9,s5
    800036ce:	00078a9b          	sext.w	s5,a5
    800036d2:	004b2703          	lw	a4,4(s6)
    800036d6:	06eaf163          	bgeu	s5,a4,80003738 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800036da:	41fad79b          	sraiw	a5,s5,0x1f
    800036de:	0137d79b          	srliw	a5,a5,0x13
    800036e2:	015787bb          	addw	a5,a5,s5
    800036e6:	40d7d79b          	sraiw	a5,a5,0xd
    800036ea:	01cb2583          	lw	a1,28(s6)
    800036ee:	9dbd                	addw	a1,a1,a5
    800036f0:	855e                	mv	a0,s7
    800036f2:	00000097          	auipc	ra,0x0
    800036f6:	cd2080e7          	jalr	-814(ra) # 800033c4 <bread>
    800036fa:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036fc:	004b2503          	lw	a0,4(s6)
    80003700:	000a849b          	sext.w	s1,s5
    80003704:	8762                	mv	a4,s8
    80003706:	faa4fde3          	bgeu	s1,a0,800036c0 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000370a:	00777693          	andi	a3,a4,7
    8000370e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003712:	41f7579b          	sraiw	a5,a4,0x1f
    80003716:	01d7d79b          	srliw	a5,a5,0x1d
    8000371a:	9fb9                	addw	a5,a5,a4
    8000371c:	4037d79b          	sraiw	a5,a5,0x3
    80003720:	00f90633          	add	a2,s2,a5
    80003724:	05864603          	lbu	a2,88(a2)
    80003728:	00c6f5b3          	and	a1,a3,a2
    8000372c:	cd91                	beqz	a1,80003748 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000372e:	2705                	addiw	a4,a4,1
    80003730:	2485                	addiw	s1,s1,1
    80003732:	fd471ae3          	bne	a4,s4,80003706 <balloc+0x80>
    80003736:	b769                	j	800036c0 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003738:	00005517          	auipc	a0,0x5
    8000373c:	ef850513          	addi	a0,a0,-264 # 80008630 <syscalls+0x138>
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	dfa080e7          	jalr	-518(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003748:	97ca                	add	a5,a5,s2
    8000374a:	8e55                	or	a2,a2,a3
    8000374c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003750:	854a                	mv	a0,s2
    80003752:	00001097          	auipc	ra,0x1
    80003756:	026080e7          	jalr	38(ra) # 80004778 <log_write>
        brelse(bp);
    8000375a:	854a                	mv	a0,s2
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	d98080e7          	jalr	-616(ra) # 800034f4 <brelse>
  bp = bread(dev, bno);
    80003764:	85a6                	mv	a1,s1
    80003766:	855e                	mv	a0,s7
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	c5c080e7          	jalr	-932(ra) # 800033c4 <bread>
    80003770:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003772:	40000613          	li	a2,1024
    80003776:	4581                	li	a1,0
    80003778:	05850513          	addi	a0,a0,88
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	550080e7          	jalr	1360(ra) # 80000ccc <memset>
  log_write(bp);
    80003784:	854a                	mv	a0,s2
    80003786:	00001097          	auipc	ra,0x1
    8000378a:	ff2080e7          	jalr	-14(ra) # 80004778 <log_write>
  brelse(bp);
    8000378e:	854a                	mv	a0,s2
    80003790:	00000097          	auipc	ra,0x0
    80003794:	d64080e7          	jalr	-668(ra) # 800034f4 <brelse>
}
    80003798:	8526                	mv	a0,s1
    8000379a:	60e6                	ld	ra,88(sp)
    8000379c:	6446                	ld	s0,80(sp)
    8000379e:	64a6                	ld	s1,72(sp)
    800037a0:	6906                	ld	s2,64(sp)
    800037a2:	79e2                	ld	s3,56(sp)
    800037a4:	7a42                	ld	s4,48(sp)
    800037a6:	7aa2                	ld	s5,40(sp)
    800037a8:	7b02                	ld	s6,32(sp)
    800037aa:	6be2                	ld	s7,24(sp)
    800037ac:	6c42                	ld	s8,16(sp)
    800037ae:	6ca2                	ld	s9,8(sp)
    800037b0:	6125                	addi	sp,sp,96
    800037b2:	8082                	ret

00000000800037b4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800037b4:	7179                	addi	sp,sp,-48
    800037b6:	f406                	sd	ra,40(sp)
    800037b8:	f022                	sd	s0,32(sp)
    800037ba:	ec26                	sd	s1,24(sp)
    800037bc:	e84a                	sd	s2,16(sp)
    800037be:	e44e                	sd	s3,8(sp)
    800037c0:	e052                	sd	s4,0(sp)
    800037c2:	1800                	addi	s0,sp,48
    800037c4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037c6:	47ad                	li	a5,11
    800037c8:	04b7fe63          	bgeu	a5,a1,80003824 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800037cc:	ff45849b          	addiw	s1,a1,-12
    800037d0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037d4:	0ff00793          	li	a5,255
    800037d8:	0ae7e463          	bltu	a5,a4,80003880 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800037dc:	08052583          	lw	a1,128(a0)
    800037e0:	c5b5                	beqz	a1,8000384c <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800037e2:	00092503          	lw	a0,0(s2)
    800037e6:	00000097          	auipc	ra,0x0
    800037ea:	bde080e7          	jalr	-1058(ra) # 800033c4 <bread>
    800037ee:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037f0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037f4:	02049713          	slli	a4,s1,0x20
    800037f8:	01e75593          	srli	a1,a4,0x1e
    800037fc:	00b784b3          	add	s1,a5,a1
    80003800:	0004a983          	lw	s3,0(s1)
    80003804:	04098e63          	beqz	s3,80003860 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003808:	8552                	mv	a0,s4
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	cea080e7          	jalr	-790(ra) # 800034f4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003812:	854e                	mv	a0,s3
    80003814:	70a2                	ld	ra,40(sp)
    80003816:	7402                	ld	s0,32(sp)
    80003818:	64e2                	ld	s1,24(sp)
    8000381a:	6942                	ld	s2,16(sp)
    8000381c:	69a2                	ld	s3,8(sp)
    8000381e:	6a02                	ld	s4,0(sp)
    80003820:	6145                	addi	sp,sp,48
    80003822:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003824:	02059793          	slli	a5,a1,0x20
    80003828:	01e7d593          	srli	a1,a5,0x1e
    8000382c:	00b504b3          	add	s1,a0,a1
    80003830:	0504a983          	lw	s3,80(s1)
    80003834:	fc099fe3          	bnez	s3,80003812 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003838:	4108                	lw	a0,0(a0)
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	e4c080e7          	jalr	-436(ra) # 80003686 <balloc>
    80003842:	0005099b          	sext.w	s3,a0
    80003846:	0534a823          	sw	s3,80(s1)
    8000384a:	b7e1                	j	80003812 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000384c:	4108                	lw	a0,0(a0)
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	e38080e7          	jalr	-456(ra) # 80003686 <balloc>
    80003856:	0005059b          	sext.w	a1,a0
    8000385a:	08b92023          	sw	a1,128(s2)
    8000385e:	b751                	j	800037e2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003860:	00092503          	lw	a0,0(s2)
    80003864:	00000097          	auipc	ra,0x0
    80003868:	e22080e7          	jalr	-478(ra) # 80003686 <balloc>
    8000386c:	0005099b          	sext.w	s3,a0
    80003870:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003874:	8552                	mv	a0,s4
    80003876:	00001097          	auipc	ra,0x1
    8000387a:	f02080e7          	jalr	-254(ra) # 80004778 <log_write>
    8000387e:	b769                	j	80003808 <bmap+0x54>
  panic("bmap: out of range");
    80003880:	00005517          	auipc	a0,0x5
    80003884:	dc850513          	addi	a0,a0,-568 # 80008648 <syscalls+0x150>
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	cb2080e7          	jalr	-846(ra) # 8000053a <panic>

0000000080003890 <iget>:
{
    80003890:	7179                	addi	sp,sp,-48
    80003892:	f406                	sd	ra,40(sp)
    80003894:	f022                	sd	s0,32(sp)
    80003896:	ec26                	sd	s1,24(sp)
    80003898:	e84a                	sd	s2,16(sp)
    8000389a:	e44e                	sd	s3,8(sp)
    8000389c:	e052                	sd	s4,0(sp)
    8000389e:	1800                	addi	s0,sp,48
    800038a0:	89aa                	mv	s3,a0
    800038a2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038a4:	0001c517          	auipc	a0,0x1c
    800038a8:	52450513          	addi	a0,a0,1316 # 8001fdc8 <itable>
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	324080e7          	jalr	804(ra) # 80000bd0 <acquire>
  empty = 0;
    800038b4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038b6:	0001c497          	auipc	s1,0x1c
    800038ba:	52a48493          	addi	s1,s1,1322 # 8001fde0 <itable+0x18>
    800038be:	0001e697          	auipc	a3,0x1e
    800038c2:	fb268693          	addi	a3,a3,-78 # 80021870 <log>
    800038c6:	a039                	j	800038d4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038c8:	02090b63          	beqz	s2,800038fe <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038cc:	08848493          	addi	s1,s1,136
    800038d0:	02d48a63          	beq	s1,a3,80003904 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038d4:	449c                	lw	a5,8(s1)
    800038d6:	fef059e3          	blez	a5,800038c8 <iget+0x38>
    800038da:	4098                	lw	a4,0(s1)
    800038dc:	ff3716e3          	bne	a4,s3,800038c8 <iget+0x38>
    800038e0:	40d8                	lw	a4,4(s1)
    800038e2:	ff4713e3          	bne	a4,s4,800038c8 <iget+0x38>
      ip->ref++;
    800038e6:	2785                	addiw	a5,a5,1
    800038e8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038ea:	0001c517          	auipc	a0,0x1c
    800038ee:	4de50513          	addi	a0,a0,1246 # 8001fdc8 <itable>
    800038f2:	ffffd097          	auipc	ra,0xffffd
    800038f6:	392080e7          	jalr	914(ra) # 80000c84 <release>
      return ip;
    800038fa:	8926                	mv	s2,s1
    800038fc:	a03d                	j	8000392a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038fe:	f7f9                	bnez	a5,800038cc <iget+0x3c>
    80003900:	8926                	mv	s2,s1
    80003902:	b7e9                	j	800038cc <iget+0x3c>
  if(empty == 0)
    80003904:	02090c63          	beqz	s2,8000393c <iget+0xac>
  ip->dev = dev;
    80003908:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000390c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003910:	4785                	li	a5,1
    80003912:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003916:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000391a:	0001c517          	auipc	a0,0x1c
    8000391e:	4ae50513          	addi	a0,a0,1198 # 8001fdc8 <itable>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	362080e7          	jalr	866(ra) # 80000c84 <release>
}
    8000392a:	854a                	mv	a0,s2
    8000392c:	70a2                	ld	ra,40(sp)
    8000392e:	7402                	ld	s0,32(sp)
    80003930:	64e2                	ld	s1,24(sp)
    80003932:	6942                	ld	s2,16(sp)
    80003934:	69a2                	ld	s3,8(sp)
    80003936:	6a02                	ld	s4,0(sp)
    80003938:	6145                	addi	sp,sp,48
    8000393a:	8082                	ret
    panic("iget: no inodes");
    8000393c:	00005517          	auipc	a0,0x5
    80003940:	d2450513          	addi	a0,a0,-732 # 80008660 <syscalls+0x168>
    80003944:	ffffd097          	auipc	ra,0xffffd
    80003948:	bf6080e7          	jalr	-1034(ra) # 8000053a <panic>

000000008000394c <fsinit>:
fsinit(int dev) {
    8000394c:	7179                	addi	sp,sp,-48
    8000394e:	f406                	sd	ra,40(sp)
    80003950:	f022                	sd	s0,32(sp)
    80003952:	ec26                	sd	s1,24(sp)
    80003954:	e84a                	sd	s2,16(sp)
    80003956:	e44e                	sd	s3,8(sp)
    80003958:	1800                	addi	s0,sp,48
    8000395a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000395c:	4585                	li	a1,1
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	a66080e7          	jalr	-1434(ra) # 800033c4 <bread>
    80003966:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003968:	0001c997          	auipc	s3,0x1c
    8000396c:	44098993          	addi	s3,s3,1088 # 8001fda8 <sb>
    80003970:	02000613          	li	a2,32
    80003974:	05850593          	addi	a1,a0,88
    80003978:	854e                	mv	a0,s3
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	3ae080e7          	jalr	942(ra) # 80000d28 <memmove>
  brelse(bp);
    80003982:	8526                	mv	a0,s1
    80003984:	00000097          	auipc	ra,0x0
    80003988:	b70080e7          	jalr	-1168(ra) # 800034f4 <brelse>
  if(sb.magic != FSMAGIC)
    8000398c:	0009a703          	lw	a4,0(s3)
    80003990:	102037b7          	lui	a5,0x10203
    80003994:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003998:	02f71263          	bne	a4,a5,800039bc <fsinit+0x70>
  initlog(dev, &sb);
    8000399c:	0001c597          	auipc	a1,0x1c
    800039a0:	40c58593          	addi	a1,a1,1036 # 8001fda8 <sb>
    800039a4:	854a                	mv	a0,s2
    800039a6:	00001097          	auipc	ra,0x1
    800039aa:	b56080e7          	jalr	-1194(ra) # 800044fc <initlog>
}
    800039ae:	70a2                	ld	ra,40(sp)
    800039b0:	7402                	ld	s0,32(sp)
    800039b2:	64e2                	ld	s1,24(sp)
    800039b4:	6942                	ld	s2,16(sp)
    800039b6:	69a2                	ld	s3,8(sp)
    800039b8:	6145                	addi	sp,sp,48
    800039ba:	8082                	ret
    panic("invalid file system");
    800039bc:	00005517          	auipc	a0,0x5
    800039c0:	cb450513          	addi	a0,a0,-844 # 80008670 <syscalls+0x178>
    800039c4:	ffffd097          	auipc	ra,0xffffd
    800039c8:	b76080e7          	jalr	-1162(ra) # 8000053a <panic>

00000000800039cc <iinit>:
{
    800039cc:	7179                	addi	sp,sp,-48
    800039ce:	f406                	sd	ra,40(sp)
    800039d0:	f022                	sd	s0,32(sp)
    800039d2:	ec26                	sd	s1,24(sp)
    800039d4:	e84a                	sd	s2,16(sp)
    800039d6:	e44e                	sd	s3,8(sp)
    800039d8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039da:	00005597          	auipc	a1,0x5
    800039de:	cae58593          	addi	a1,a1,-850 # 80008688 <syscalls+0x190>
    800039e2:	0001c517          	auipc	a0,0x1c
    800039e6:	3e650513          	addi	a0,a0,998 # 8001fdc8 <itable>
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	156080e7          	jalr	342(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039f2:	0001c497          	auipc	s1,0x1c
    800039f6:	3fe48493          	addi	s1,s1,1022 # 8001fdf0 <itable+0x28>
    800039fa:	0001e997          	auipc	s3,0x1e
    800039fe:	e8698993          	addi	s3,s3,-378 # 80021880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a02:	00005917          	auipc	s2,0x5
    80003a06:	c8e90913          	addi	s2,s2,-882 # 80008690 <syscalls+0x198>
    80003a0a:	85ca                	mv	a1,s2
    80003a0c:	8526                	mv	a0,s1
    80003a0e:	00001097          	auipc	ra,0x1
    80003a12:	e4e080e7          	jalr	-434(ra) # 8000485c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a16:	08848493          	addi	s1,s1,136
    80003a1a:	ff3498e3          	bne	s1,s3,80003a0a <iinit+0x3e>
}
    80003a1e:	70a2                	ld	ra,40(sp)
    80003a20:	7402                	ld	s0,32(sp)
    80003a22:	64e2                	ld	s1,24(sp)
    80003a24:	6942                	ld	s2,16(sp)
    80003a26:	69a2                	ld	s3,8(sp)
    80003a28:	6145                	addi	sp,sp,48
    80003a2a:	8082                	ret

0000000080003a2c <ialloc>:
{
    80003a2c:	715d                	addi	sp,sp,-80
    80003a2e:	e486                	sd	ra,72(sp)
    80003a30:	e0a2                	sd	s0,64(sp)
    80003a32:	fc26                	sd	s1,56(sp)
    80003a34:	f84a                	sd	s2,48(sp)
    80003a36:	f44e                	sd	s3,40(sp)
    80003a38:	f052                	sd	s4,32(sp)
    80003a3a:	ec56                	sd	s5,24(sp)
    80003a3c:	e85a                	sd	s6,16(sp)
    80003a3e:	e45e                	sd	s7,8(sp)
    80003a40:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a42:	0001c717          	auipc	a4,0x1c
    80003a46:	37272703          	lw	a4,882(a4) # 8001fdb4 <sb+0xc>
    80003a4a:	4785                	li	a5,1
    80003a4c:	04e7fa63          	bgeu	a5,a4,80003aa0 <ialloc+0x74>
    80003a50:	8aaa                	mv	s5,a0
    80003a52:	8bae                	mv	s7,a1
    80003a54:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a56:	0001ca17          	auipc	s4,0x1c
    80003a5a:	352a0a13          	addi	s4,s4,850 # 8001fda8 <sb>
    80003a5e:	00048b1b          	sext.w	s6,s1
    80003a62:	0044d593          	srli	a1,s1,0x4
    80003a66:	018a2783          	lw	a5,24(s4)
    80003a6a:	9dbd                	addw	a1,a1,a5
    80003a6c:	8556                	mv	a0,s5
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	956080e7          	jalr	-1706(ra) # 800033c4 <bread>
    80003a76:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a78:	05850993          	addi	s3,a0,88
    80003a7c:	00f4f793          	andi	a5,s1,15
    80003a80:	079a                	slli	a5,a5,0x6
    80003a82:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a84:	00099783          	lh	a5,0(s3)
    80003a88:	c785                	beqz	a5,80003ab0 <ialloc+0x84>
    brelse(bp);
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	a6a080e7          	jalr	-1430(ra) # 800034f4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a92:	0485                	addi	s1,s1,1
    80003a94:	00ca2703          	lw	a4,12(s4)
    80003a98:	0004879b          	sext.w	a5,s1
    80003a9c:	fce7e1e3          	bltu	a5,a4,80003a5e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003aa0:	00005517          	auipc	a0,0x5
    80003aa4:	bf850513          	addi	a0,a0,-1032 # 80008698 <syscalls+0x1a0>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	a92080e7          	jalr	-1390(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    80003ab0:	04000613          	li	a2,64
    80003ab4:	4581                	li	a1,0
    80003ab6:	854e                	mv	a0,s3
    80003ab8:	ffffd097          	auipc	ra,0xffffd
    80003abc:	214080e7          	jalr	532(ra) # 80000ccc <memset>
      dip->type = type;
    80003ac0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ac4:	854a                	mv	a0,s2
    80003ac6:	00001097          	auipc	ra,0x1
    80003aca:	cb2080e7          	jalr	-846(ra) # 80004778 <log_write>
      brelse(bp);
    80003ace:	854a                	mv	a0,s2
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	a24080e7          	jalr	-1500(ra) # 800034f4 <brelse>
      return iget(dev, inum);
    80003ad8:	85da                	mv	a1,s6
    80003ada:	8556                	mv	a0,s5
    80003adc:	00000097          	auipc	ra,0x0
    80003ae0:	db4080e7          	jalr	-588(ra) # 80003890 <iget>
}
    80003ae4:	60a6                	ld	ra,72(sp)
    80003ae6:	6406                	ld	s0,64(sp)
    80003ae8:	74e2                	ld	s1,56(sp)
    80003aea:	7942                	ld	s2,48(sp)
    80003aec:	79a2                	ld	s3,40(sp)
    80003aee:	7a02                	ld	s4,32(sp)
    80003af0:	6ae2                	ld	s5,24(sp)
    80003af2:	6b42                	ld	s6,16(sp)
    80003af4:	6ba2                	ld	s7,8(sp)
    80003af6:	6161                	addi	sp,sp,80
    80003af8:	8082                	ret

0000000080003afa <iupdate>:
{
    80003afa:	1101                	addi	sp,sp,-32
    80003afc:	ec06                	sd	ra,24(sp)
    80003afe:	e822                	sd	s0,16(sp)
    80003b00:	e426                	sd	s1,8(sp)
    80003b02:	e04a                	sd	s2,0(sp)
    80003b04:	1000                	addi	s0,sp,32
    80003b06:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b08:	415c                	lw	a5,4(a0)
    80003b0a:	0047d79b          	srliw	a5,a5,0x4
    80003b0e:	0001c597          	auipc	a1,0x1c
    80003b12:	2b25a583          	lw	a1,690(a1) # 8001fdc0 <sb+0x18>
    80003b16:	9dbd                	addw	a1,a1,a5
    80003b18:	4108                	lw	a0,0(a0)
    80003b1a:	00000097          	auipc	ra,0x0
    80003b1e:	8aa080e7          	jalr	-1878(ra) # 800033c4 <bread>
    80003b22:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b24:	05850793          	addi	a5,a0,88
    80003b28:	40d8                	lw	a4,4(s1)
    80003b2a:	8b3d                	andi	a4,a4,15
    80003b2c:	071a                	slli	a4,a4,0x6
    80003b2e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003b30:	04449703          	lh	a4,68(s1)
    80003b34:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003b38:	04649703          	lh	a4,70(s1)
    80003b3c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003b40:	04849703          	lh	a4,72(s1)
    80003b44:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003b48:	04a49703          	lh	a4,74(s1)
    80003b4c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003b50:	44f8                	lw	a4,76(s1)
    80003b52:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b54:	03400613          	li	a2,52
    80003b58:	05048593          	addi	a1,s1,80
    80003b5c:	00c78513          	addi	a0,a5,12
    80003b60:	ffffd097          	auipc	ra,0xffffd
    80003b64:	1c8080e7          	jalr	456(ra) # 80000d28 <memmove>
  log_write(bp);
    80003b68:	854a                	mv	a0,s2
    80003b6a:	00001097          	auipc	ra,0x1
    80003b6e:	c0e080e7          	jalr	-1010(ra) # 80004778 <log_write>
  brelse(bp);
    80003b72:	854a                	mv	a0,s2
    80003b74:	00000097          	auipc	ra,0x0
    80003b78:	980080e7          	jalr	-1664(ra) # 800034f4 <brelse>
}
    80003b7c:	60e2                	ld	ra,24(sp)
    80003b7e:	6442                	ld	s0,16(sp)
    80003b80:	64a2                	ld	s1,8(sp)
    80003b82:	6902                	ld	s2,0(sp)
    80003b84:	6105                	addi	sp,sp,32
    80003b86:	8082                	ret

0000000080003b88 <idup>:
{
    80003b88:	1101                	addi	sp,sp,-32
    80003b8a:	ec06                	sd	ra,24(sp)
    80003b8c:	e822                	sd	s0,16(sp)
    80003b8e:	e426                	sd	s1,8(sp)
    80003b90:	1000                	addi	s0,sp,32
    80003b92:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b94:	0001c517          	auipc	a0,0x1c
    80003b98:	23450513          	addi	a0,a0,564 # 8001fdc8 <itable>
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	034080e7          	jalr	52(ra) # 80000bd0 <acquire>
  ip->ref++;
    80003ba4:	449c                	lw	a5,8(s1)
    80003ba6:	2785                	addiw	a5,a5,1
    80003ba8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003baa:	0001c517          	auipc	a0,0x1c
    80003bae:	21e50513          	addi	a0,a0,542 # 8001fdc8 <itable>
    80003bb2:	ffffd097          	auipc	ra,0xffffd
    80003bb6:	0d2080e7          	jalr	210(ra) # 80000c84 <release>
}
    80003bba:	8526                	mv	a0,s1
    80003bbc:	60e2                	ld	ra,24(sp)
    80003bbe:	6442                	ld	s0,16(sp)
    80003bc0:	64a2                	ld	s1,8(sp)
    80003bc2:	6105                	addi	sp,sp,32
    80003bc4:	8082                	ret

0000000080003bc6 <ilock>:
{
    80003bc6:	1101                	addi	sp,sp,-32
    80003bc8:	ec06                	sd	ra,24(sp)
    80003bca:	e822                	sd	s0,16(sp)
    80003bcc:	e426                	sd	s1,8(sp)
    80003bce:	e04a                	sd	s2,0(sp)
    80003bd0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bd2:	c115                	beqz	a0,80003bf6 <ilock+0x30>
    80003bd4:	84aa                	mv	s1,a0
    80003bd6:	451c                	lw	a5,8(a0)
    80003bd8:	00f05f63          	blez	a5,80003bf6 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003bdc:	0541                	addi	a0,a0,16
    80003bde:	00001097          	auipc	ra,0x1
    80003be2:	cb8080e7          	jalr	-840(ra) # 80004896 <acquiresleep>
  if(ip->valid == 0){
    80003be6:	40bc                	lw	a5,64(s1)
    80003be8:	cf99                	beqz	a5,80003c06 <ilock+0x40>
}
    80003bea:	60e2                	ld	ra,24(sp)
    80003bec:	6442                	ld	s0,16(sp)
    80003bee:	64a2                	ld	s1,8(sp)
    80003bf0:	6902                	ld	s2,0(sp)
    80003bf2:	6105                	addi	sp,sp,32
    80003bf4:	8082                	ret
    panic("ilock");
    80003bf6:	00005517          	auipc	a0,0x5
    80003bfa:	aba50513          	addi	a0,a0,-1350 # 800086b0 <syscalls+0x1b8>
    80003bfe:	ffffd097          	auipc	ra,0xffffd
    80003c02:	93c080e7          	jalr	-1732(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c06:	40dc                	lw	a5,4(s1)
    80003c08:	0047d79b          	srliw	a5,a5,0x4
    80003c0c:	0001c597          	auipc	a1,0x1c
    80003c10:	1b45a583          	lw	a1,436(a1) # 8001fdc0 <sb+0x18>
    80003c14:	9dbd                	addw	a1,a1,a5
    80003c16:	4088                	lw	a0,0(s1)
    80003c18:	fffff097          	auipc	ra,0xfffff
    80003c1c:	7ac080e7          	jalr	1964(ra) # 800033c4 <bread>
    80003c20:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c22:	05850593          	addi	a1,a0,88
    80003c26:	40dc                	lw	a5,4(s1)
    80003c28:	8bbd                	andi	a5,a5,15
    80003c2a:	079a                	slli	a5,a5,0x6
    80003c2c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c2e:	00059783          	lh	a5,0(a1)
    80003c32:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c36:	00259783          	lh	a5,2(a1)
    80003c3a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c3e:	00459783          	lh	a5,4(a1)
    80003c42:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c46:	00659783          	lh	a5,6(a1)
    80003c4a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c4e:	459c                	lw	a5,8(a1)
    80003c50:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c52:	03400613          	li	a2,52
    80003c56:	05b1                	addi	a1,a1,12
    80003c58:	05048513          	addi	a0,s1,80
    80003c5c:	ffffd097          	auipc	ra,0xffffd
    80003c60:	0cc080e7          	jalr	204(ra) # 80000d28 <memmove>
    brelse(bp);
    80003c64:	854a                	mv	a0,s2
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	88e080e7          	jalr	-1906(ra) # 800034f4 <brelse>
    ip->valid = 1;
    80003c6e:	4785                	li	a5,1
    80003c70:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c72:	04449783          	lh	a5,68(s1)
    80003c76:	fbb5                	bnez	a5,80003bea <ilock+0x24>
      panic("ilock: no type");
    80003c78:	00005517          	auipc	a0,0x5
    80003c7c:	a4050513          	addi	a0,a0,-1472 # 800086b8 <syscalls+0x1c0>
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	8ba080e7          	jalr	-1862(ra) # 8000053a <panic>

0000000080003c88 <iunlock>:
{
    80003c88:	1101                	addi	sp,sp,-32
    80003c8a:	ec06                	sd	ra,24(sp)
    80003c8c:	e822                	sd	s0,16(sp)
    80003c8e:	e426                	sd	s1,8(sp)
    80003c90:	e04a                	sd	s2,0(sp)
    80003c92:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c94:	c905                	beqz	a0,80003cc4 <iunlock+0x3c>
    80003c96:	84aa                	mv	s1,a0
    80003c98:	01050913          	addi	s2,a0,16
    80003c9c:	854a                	mv	a0,s2
    80003c9e:	00001097          	auipc	ra,0x1
    80003ca2:	c92080e7          	jalr	-878(ra) # 80004930 <holdingsleep>
    80003ca6:	cd19                	beqz	a0,80003cc4 <iunlock+0x3c>
    80003ca8:	449c                	lw	a5,8(s1)
    80003caa:	00f05d63          	blez	a5,80003cc4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cae:	854a                	mv	a0,s2
    80003cb0:	00001097          	auipc	ra,0x1
    80003cb4:	c3c080e7          	jalr	-964(ra) # 800048ec <releasesleep>
}
    80003cb8:	60e2                	ld	ra,24(sp)
    80003cba:	6442                	ld	s0,16(sp)
    80003cbc:	64a2                	ld	s1,8(sp)
    80003cbe:	6902                	ld	s2,0(sp)
    80003cc0:	6105                	addi	sp,sp,32
    80003cc2:	8082                	ret
    panic("iunlock");
    80003cc4:	00005517          	auipc	a0,0x5
    80003cc8:	a0450513          	addi	a0,a0,-1532 # 800086c8 <syscalls+0x1d0>
    80003ccc:	ffffd097          	auipc	ra,0xffffd
    80003cd0:	86e080e7          	jalr	-1938(ra) # 8000053a <panic>

0000000080003cd4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cd4:	7179                	addi	sp,sp,-48
    80003cd6:	f406                	sd	ra,40(sp)
    80003cd8:	f022                	sd	s0,32(sp)
    80003cda:	ec26                	sd	s1,24(sp)
    80003cdc:	e84a                	sd	s2,16(sp)
    80003cde:	e44e                	sd	s3,8(sp)
    80003ce0:	e052                	sd	s4,0(sp)
    80003ce2:	1800                	addi	s0,sp,48
    80003ce4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ce6:	05050493          	addi	s1,a0,80
    80003cea:	08050913          	addi	s2,a0,128
    80003cee:	a021                	j	80003cf6 <itrunc+0x22>
    80003cf0:	0491                	addi	s1,s1,4
    80003cf2:	01248d63          	beq	s1,s2,80003d0c <itrunc+0x38>
    if(ip->addrs[i]){
    80003cf6:	408c                	lw	a1,0(s1)
    80003cf8:	dde5                	beqz	a1,80003cf0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cfa:	0009a503          	lw	a0,0(s3)
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	90c080e7          	jalr	-1780(ra) # 8000360a <bfree>
      ip->addrs[i] = 0;
    80003d06:	0004a023          	sw	zero,0(s1)
    80003d0a:	b7dd                	j	80003cf0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d0c:	0809a583          	lw	a1,128(s3)
    80003d10:	e185                	bnez	a1,80003d30 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d12:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d16:	854e                	mv	a0,s3
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	de2080e7          	jalr	-542(ra) # 80003afa <iupdate>
}
    80003d20:	70a2                	ld	ra,40(sp)
    80003d22:	7402                	ld	s0,32(sp)
    80003d24:	64e2                	ld	s1,24(sp)
    80003d26:	6942                	ld	s2,16(sp)
    80003d28:	69a2                	ld	s3,8(sp)
    80003d2a:	6a02                	ld	s4,0(sp)
    80003d2c:	6145                	addi	sp,sp,48
    80003d2e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d30:	0009a503          	lw	a0,0(s3)
    80003d34:	fffff097          	auipc	ra,0xfffff
    80003d38:	690080e7          	jalr	1680(ra) # 800033c4 <bread>
    80003d3c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d3e:	05850493          	addi	s1,a0,88
    80003d42:	45850913          	addi	s2,a0,1112
    80003d46:	a021                	j	80003d4e <itrunc+0x7a>
    80003d48:	0491                	addi	s1,s1,4
    80003d4a:	01248b63          	beq	s1,s2,80003d60 <itrunc+0x8c>
      if(a[j])
    80003d4e:	408c                	lw	a1,0(s1)
    80003d50:	dde5                	beqz	a1,80003d48 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d52:	0009a503          	lw	a0,0(s3)
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	8b4080e7          	jalr	-1868(ra) # 8000360a <bfree>
    80003d5e:	b7ed                	j	80003d48 <itrunc+0x74>
    brelse(bp);
    80003d60:	8552                	mv	a0,s4
    80003d62:	fffff097          	auipc	ra,0xfffff
    80003d66:	792080e7          	jalr	1938(ra) # 800034f4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d6a:	0809a583          	lw	a1,128(s3)
    80003d6e:	0009a503          	lw	a0,0(s3)
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	898080e7          	jalr	-1896(ra) # 8000360a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d7a:	0809a023          	sw	zero,128(s3)
    80003d7e:	bf51                	j	80003d12 <itrunc+0x3e>

0000000080003d80 <iput>:
{
    80003d80:	1101                	addi	sp,sp,-32
    80003d82:	ec06                	sd	ra,24(sp)
    80003d84:	e822                	sd	s0,16(sp)
    80003d86:	e426                	sd	s1,8(sp)
    80003d88:	e04a                	sd	s2,0(sp)
    80003d8a:	1000                	addi	s0,sp,32
    80003d8c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d8e:	0001c517          	auipc	a0,0x1c
    80003d92:	03a50513          	addi	a0,a0,58 # 8001fdc8 <itable>
    80003d96:	ffffd097          	auipc	ra,0xffffd
    80003d9a:	e3a080e7          	jalr	-454(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d9e:	4498                	lw	a4,8(s1)
    80003da0:	4785                	li	a5,1
    80003da2:	02f70363          	beq	a4,a5,80003dc8 <iput+0x48>
  ip->ref--;
    80003da6:	449c                	lw	a5,8(s1)
    80003da8:	37fd                	addiw	a5,a5,-1
    80003daa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dac:	0001c517          	auipc	a0,0x1c
    80003db0:	01c50513          	addi	a0,a0,28 # 8001fdc8 <itable>
    80003db4:	ffffd097          	auipc	ra,0xffffd
    80003db8:	ed0080e7          	jalr	-304(ra) # 80000c84 <release>
}
    80003dbc:	60e2                	ld	ra,24(sp)
    80003dbe:	6442                	ld	s0,16(sp)
    80003dc0:	64a2                	ld	s1,8(sp)
    80003dc2:	6902                	ld	s2,0(sp)
    80003dc4:	6105                	addi	sp,sp,32
    80003dc6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dc8:	40bc                	lw	a5,64(s1)
    80003dca:	dff1                	beqz	a5,80003da6 <iput+0x26>
    80003dcc:	04a49783          	lh	a5,74(s1)
    80003dd0:	fbf9                	bnez	a5,80003da6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003dd2:	01048913          	addi	s2,s1,16
    80003dd6:	854a                	mv	a0,s2
    80003dd8:	00001097          	auipc	ra,0x1
    80003ddc:	abe080e7          	jalr	-1346(ra) # 80004896 <acquiresleep>
    release(&itable.lock);
    80003de0:	0001c517          	auipc	a0,0x1c
    80003de4:	fe850513          	addi	a0,a0,-24 # 8001fdc8 <itable>
    80003de8:	ffffd097          	auipc	ra,0xffffd
    80003dec:	e9c080e7          	jalr	-356(ra) # 80000c84 <release>
    itrunc(ip);
    80003df0:	8526                	mv	a0,s1
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	ee2080e7          	jalr	-286(ra) # 80003cd4 <itrunc>
    ip->type = 0;
    80003dfa:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003dfe:	8526                	mv	a0,s1
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	cfa080e7          	jalr	-774(ra) # 80003afa <iupdate>
    ip->valid = 0;
    80003e08:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e0c:	854a                	mv	a0,s2
    80003e0e:	00001097          	auipc	ra,0x1
    80003e12:	ade080e7          	jalr	-1314(ra) # 800048ec <releasesleep>
    acquire(&itable.lock);
    80003e16:	0001c517          	auipc	a0,0x1c
    80003e1a:	fb250513          	addi	a0,a0,-78 # 8001fdc8 <itable>
    80003e1e:	ffffd097          	auipc	ra,0xffffd
    80003e22:	db2080e7          	jalr	-590(ra) # 80000bd0 <acquire>
    80003e26:	b741                	j	80003da6 <iput+0x26>

0000000080003e28 <iunlockput>:
{
    80003e28:	1101                	addi	sp,sp,-32
    80003e2a:	ec06                	sd	ra,24(sp)
    80003e2c:	e822                	sd	s0,16(sp)
    80003e2e:	e426                	sd	s1,8(sp)
    80003e30:	1000                	addi	s0,sp,32
    80003e32:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	e54080e7          	jalr	-428(ra) # 80003c88 <iunlock>
  iput(ip);
    80003e3c:	8526                	mv	a0,s1
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	f42080e7          	jalr	-190(ra) # 80003d80 <iput>
}
    80003e46:	60e2                	ld	ra,24(sp)
    80003e48:	6442                	ld	s0,16(sp)
    80003e4a:	64a2                	ld	s1,8(sp)
    80003e4c:	6105                	addi	sp,sp,32
    80003e4e:	8082                	ret

0000000080003e50 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e50:	1141                	addi	sp,sp,-16
    80003e52:	e422                	sd	s0,8(sp)
    80003e54:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e56:	411c                	lw	a5,0(a0)
    80003e58:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e5a:	415c                	lw	a5,4(a0)
    80003e5c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e5e:	04451783          	lh	a5,68(a0)
    80003e62:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e66:	04a51783          	lh	a5,74(a0)
    80003e6a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e6e:	04c56783          	lwu	a5,76(a0)
    80003e72:	e99c                	sd	a5,16(a1)
}
    80003e74:	6422                	ld	s0,8(sp)
    80003e76:	0141                	addi	sp,sp,16
    80003e78:	8082                	ret

0000000080003e7a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e7a:	457c                	lw	a5,76(a0)
    80003e7c:	0ed7e963          	bltu	a5,a3,80003f6e <readi+0xf4>
{
    80003e80:	7159                	addi	sp,sp,-112
    80003e82:	f486                	sd	ra,104(sp)
    80003e84:	f0a2                	sd	s0,96(sp)
    80003e86:	eca6                	sd	s1,88(sp)
    80003e88:	e8ca                	sd	s2,80(sp)
    80003e8a:	e4ce                	sd	s3,72(sp)
    80003e8c:	e0d2                	sd	s4,64(sp)
    80003e8e:	fc56                	sd	s5,56(sp)
    80003e90:	f85a                	sd	s6,48(sp)
    80003e92:	f45e                	sd	s7,40(sp)
    80003e94:	f062                	sd	s8,32(sp)
    80003e96:	ec66                	sd	s9,24(sp)
    80003e98:	e86a                	sd	s10,16(sp)
    80003e9a:	e46e                	sd	s11,8(sp)
    80003e9c:	1880                	addi	s0,sp,112
    80003e9e:	8baa                	mv	s7,a0
    80003ea0:	8c2e                	mv	s8,a1
    80003ea2:	8ab2                	mv	s5,a2
    80003ea4:	84b6                	mv	s1,a3
    80003ea6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ea8:	9f35                	addw	a4,a4,a3
    return 0;
    80003eaa:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003eac:	0ad76063          	bltu	a4,a3,80003f4c <readi+0xd2>
  if(off + n > ip->size)
    80003eb0:	00e7f463          	bgeu	a5,a4,80003eb8 <readi+0x3e>
    n = ip->size - off;
    80003eb4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eb8:	0a0b0963          	beqz	s6,80003f6a <readi+0xf0>
    80003ebc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ebe:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ec2:	5cfd                	li	s9,-1
    80003ec4:	a82d                	j	80003efe <readi+0x84>
    80003ec6:	020a1d93          	slli	s11,s4,0x20
    80003eca:	020ddd93          	srli	s11,s11,0x20
    80003ece:	05890613          	addi	a2,s2,88
    80003ed2:	86ee                	mv	a3,s11
    80003ed4:	963a                	add	a2,a2,a4
    80003ed6:	85d6                	mv	a1,s5
    80003ed8:	8562                	mv	a0,s8
    80003eda:	ffffe097          	auipc	ra,0xffffe
    80003ede:	558080e7          	jalr	1368(ra) # 80002432 <either_copyout>
    80003ee2:	05950d63          	beq	a0,s9,80003f3c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ee6:	854a                	mv	a0,s2
    80003ee8:	fffff097          	auipc	ra,0xfffff
    80003eec:	60c080e7          	jalr	1548(ra) # 800034f4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ef0:	013a09bb          	addw	s3,s4,s3
    80003ef4:	009a04bb          	addw	s1,s4,s1
    80003ef8:	9aee                	add	s5,s5,s11
    80003efa:	0569f763          	bgeu	s3,s6,80003f48 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003efe:	000ba903          	lw	s2,0(s7)
    80003f02:	00a4d59b          	srliw	a1,s1,0xa
    80003f06:	855e                	mv	a0,s7
    80003f08:	00000097          	auipc	ra,0x0
    80003f0c:	8ac080e7          	jalr	-1876(ra) # 800037b4 <bmap>
    80003f10:	0005059b          	sext.w	a1,a0
    80003f14:	854a                	mv	a0,s2
    80003f16:	fffff097          	auipc	ra,0xfffff
    80003f1a:	4ae080e7          	jalr	1198(ra) # 800033c4 <bread>
    80003f1e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f20:	3ff4f713          	andi	a4,s1,1023
    80003f24:	40ed07bb          	subw	a5,s10,a4
    80003f28:	413b06bb          	subw	a3,s6,s3
    80003f2c:	8a3e                	mv	s4,a5
    80003f2e:	2781                	sext.w	a5,a5
    80003f30:	0006861b          	sext.w	a2,a3
    80003f34:	f8f679e3          	bgeu	a2,a5,80003ec6 <readi+0x4c>
    80003f38:	8a36                	mv	s4,a3
    80003f3a:	b771                	j	80003ec6 <readi+0x4c>
      brelse(bp);
    80003f3c:	854a                	mv	a0,s2
    80003f3e:	fffff097          	auipc	ra,0xfffff
    80003f42:	5b6080e7          	jalr	1462(ra) # 800034f4 <brelse>
      tot = -1;
    80003f46:	59fd                	li	s3,-1
  }
  return tot;
    80003f48:	0009851b          	sext.w	a0,s3
}
    80003f4c:	70a6                	ld	ra,104(sp)
    80003f4e:	7406                	ld	s0,96(sp)
    80003f50:	64e6                	ld	s1,88(sp)
    80003f52:	6946                	ld	s2,80(sp)
    80003f54:	69a6                	ld	s3,72(sp)
    80003f56:	6a06                	ld	s4,64(sp)
    80003f58:	7ae2                	ld	s5,56(sp)
    80003f5a:	7b42                	ld	s6,48(sp)
    80003f5c:	7ba2                	ld	s7,40(sp)
    80003f5e:	7c02                	ld	s8,32(sp)
    80003f60:	6ce2                	ld	s9,24(sp)
    80003f62:	6d42                	ld	s10,16(sp)
    80003f64:	6da2                	ld	s11,8(sp)
    80003f66:	6165                	addi	sp,sp,112
    80003f68:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f6a:	89da                	mv	s3,s6
    80003f6c:	bff1                	j	80003f48 <readi+0xce>
    return 0;
    80003f6e:	4501                	li	a0,0
}
    80003f70:	8082                	ret

0000000080003f72 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f72:	457c                	lw	a5,76(a0)
    80003f74:	10d7e863          	bltu	a5,a3,80004084 <writei+0x112>
{
    80003f78:	7159                	addi	sp,sp,-112
    80003f7a:	f486                	sd	ra,104(sp)
    80003f7c:	f0a2                	sd	s0,96(sp)
    80003f7e:	eca6                	sd	s1,88(sp)
    80003f80:	e8ca                	sd	s2,80(sp)
    80003f82:	e4ce                	sd	s3,72(sp)
    80003f84:	e0d2                	sd	s4,64(sp)
    80003f86:	fc56                	sd	s5,56(sp)
    80003f88:	f85a                	sd	s6,48(sp)
    80003f8a:	f45e                	sd	s7,40(sp)
    80003f8c:	f062                	sd	s8,32(sp)
    80003f8e:	ec66                	sd	s9,24(sp)
    80003f90:	e86a                	sd	s10,16(sp)
    80003f92:	e46e                	sd	s11,8(sp)
    80003f94:	1880                	addi	s0,sp,112
    80003f96:	8b2a                	mv	s6,a0
    80003f98:	8c2e                	mv	s8,a1
    80003f9a:	8ab2                	mv	s5,a2
    80003f9c:	8936                	mv	s2,a3
    80003f9e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003fa0:	00e687bb          	addw	a5,a3,a4
    80003fa4:	0ed7e263          	bltu	a5,a3,80004088 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fa8:	00043737          	lui	a4,0x43
    80003fac:	0ef76063          	bltu	a4,a5,8000408c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fb0:	0c0b8863          	beqz	s7,80004080 <writei+0x10e>
    80003fb4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fb6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fba:	5cfd                	li	s9,-1
    80003fbc:	a091                	j	80004000 <writei+0x8e>
    80003fbe:	02099d93          	slli	s11,s3,0x20
    80003fc2:	020ddd93          	srli	s11,s11,0x20
    80003fc6:	05848513          	addi	a0,s1,88
    80003fca:	86ee                	mv	a3,s11
    80003fcc:	8656                	mv	a2,s5
    80003fce:	85e2                	mv	a1,s8
    80003fd0:	953a                	add	a0,a0,a4
    80003fd2:	ffffe097          	auipc	ra,0xffffe
    80003fd6:	4b6080e7          	jalr	1206(ra) # 80002488 <either_copyin>
    80003fda:	07950263          	beq	a0,s9,8000403e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fde:	8526                	mv	a0,s1
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	798080e7          	jalr	1944(ra) # 80004778 <log_write>
    brelse(bp);
    80003fe8:	8526                	mv	a0,s1
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	50a080e7          	jalr	1290(ra) # 800034f4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ff2:	01498a3b          	addw	s4,s3,s4
    80003ff6:	0129893b          	addw	s2,s3,s2
    80003ffa:	9aee                	add	s5,s5,s11
    80003ffc:	057a7663          	bgeu	s4,s7,80004048 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004000:	000b2483          	lw	s1,0(s6)
    80004004:	00a9559b          	srliw	a1,s2,0xa
    80004008:	855a                	mv	a0,s6
    8000400a:	fffff097          	auipc	ra,0xfffff
    8000400e:	7aa080e7          	jalr	1962(ra) # 800037b4 <bmap>
    80004012:	0005059b          	sext.w	a1,a0
    80004016:	8526                	mv	a0,s1
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	3ac080e7          	jalr	940(ra) # 800033c4 <bread>
    80004020:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004022:	3ff97713          	andi	a4,s2,1023
    80004026:	40ed07bb          	subw	a5,s10,a4
    8000402a:	414b86bb          	subw	a3,s7,s4
    8000402e:	89be                	mv	s3,a5
    80004030:	2781                	sext.w	a5,a5
    80004032:	0006861b          	sext.w	a2,a3
    80004036:	f8f674e3          	bgeu	a2,a5,80003fbe <writei+0x4c>
    8000403a:	89b6                	mv	s3,a3
    8000403c:	b749                	j	80003fbe <writei+0x4c>
      brelse(bp);
    8000403e:	8526                	mv	a0,s1
    80004040:	fffff097          	auipc	ra,0xfffff
    80004044:	4b4080e7          	jalr	1204(ra) # 800034f4 <brelse>
  }

  if(off > ip->size)
    80004048:	04cb2783          	lw	a5,76(s6)
    8000404c:	0127f463          	bgeu	a5,s2,80004054 <writei+0xe2>
    ip->size = off;
    80004050:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004054:	855a                	mv	a0,s6
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	aa4080e7          	jalr	-1372(ra) # 80003afa <iupdate>

  return tot;
    8000405e:	000a051b          	sext.w	a0,s4
}
    80004062:	70a6                	ld	ra,104(sp)
    80004064:	7406                	ld	s0,96(sp)
    80004066:	64e6                	ld	s1,88(sp)
    80004068:	6946                	ld	s2,80(sp)
    8000406a:	69a6                	ld	s3,72(sp)
    8000406c:	6a06                	ld	s4,64(sp)
    8000406e:	7ae2                	ld	s5,56(sp)
    80004070:	7b42                	ld	s6,48(sp)
    80004072:	7ba2                	ld	s7,40(sp)
    80004074:	7c02                	ld	s8,32(sp)
    80004076:	6ce2                	ld	s9,24(sp)
    80004078:	6d42                	ld	s10,16(sp)
    8000407a:	6da2                	ld	s11,8(sp)
    8000407c:	6165                	addi	sp,sp,112
    8000407e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004080:	8a5e                	mv	s4,s7
    80004082:	bfc9                	j	80004054 <writei+0xe2>
    return -1;
    80004084:	557d                	li	a0,-1
}
    80004086:	8082                	ret
    return -1;
    80004088:	557d                	li	a0,-1
    8000408a:	bfe1                	j	80004062 <writei+0xf0>
    return -1;
    8000408c:	557d                	li	a0,-1
    8000408e:	bfd1                	j	80004062 <writei+0xf0>

0000000080004090 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004090:	1141                	addi	sp,sp,-16
    80004092:	e406                	sd	ra,8(sp)
    80004094:	e022                	sd	s0,0(sp)
    80004096:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004098:	4639                	li	a2,14
    8000409a:	ffffd097          	auipc	ra,0xffffd
    8000409e:	d02080e7          	jalr	-766(ra) # 80000d9c <strncmp>
}
    800040a2:	60a2                	ld	ra,8(sp)
    800040a4:	6402                	ld	s0,0(sp)
    800040a6:	0141                	addi	sp,sp,16
    800040a8:	8082                	ret

00000000800040aa <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040aa:	7139                	addi	sp,sp,-64
    800040ac:	fc06                	sd	ra,56(sp)
    800040ae:	f822                	sd	s0,48(sp)
    800040b0:	f426                	sd	s1,40(sp)
    800040b2:	f04a                	sd	s2,32(sp)
    800040b4:	ec4e                	sd	s3,24(sp)
    800040b6:	e852                	sd	s4,16(sp)
    800040b8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040ba:	04451703          	lh	a4,68(a0)
    800040be:	4785                	li	a5,1
    800040c0:	00f71a63          	bne	a4,a5,800040d4 <dirlookup+0x2a>
    800040c4:	892a                	mv	s2,a0
    800040c6:	89ae                	mv	s3,a1
    800040c8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ca:	457c                	lw	a5,76(a0)
    800040cc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040ce:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040d0:	e79d                	bnez	a5,800040fe <dirlookup+0x54>
    800040d2:	a8a5                	j	8000414a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040d4:	00004517          	auipc	a0,0x4
    800040d8:	5fc50513          	addi	a0,a0,1532 # 800086d0 <syscalls+0x1d8>
    800040dc:	ffffc097          	auipc	ra,0xffffc
    800040e0:	45e080e7          	jalr	1118(ra) # 8000053a <panic>
      panic("dirlookup read");
    800040e4:	00004517          	auipc	a0,0x4
    800040e8:	60450513          	addi	a0,a0,1540 # 800086e8 <syscalls+0x1f0>
    800040ec:	ffffc097          	auipc	ra,0xffffc
    800040f0:	44e080e7          	jalr	1102(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040f4:	24c1                	addiw	s1,s1,16
    800040f6:	04c92783          	lw	a5,76(s2)
    800040fa:	04f4f763          	bgeu	s1,a5,80004148 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040fe:	4741                	li	a4,16
    80004100:	86a6                	mv	a3,s1
    80004102:	fc040613          	addi	a2,s0,-64
    80004106:	4581                	li	a1,0
    80004108:	854a                	mv	a0,s2
    8000410a:	00000097          	auipc	ra,0x0
    8000410e:	d70080e7          	jalr	-656(ra) # 80003e7a <readi>
    80004112:	47c1                	li	a5,16
    80004114:	fcf518e3          	bne	a0,a5,800040e4 <dirlookup+0x3a>
    if(de.inum == 0)
    80004118:	fc045783          	lhu	a5,-64(s0)
    8000411c:	dfe1                	beqz	a5,800040f4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000411e:	fc240593          	addi	a1,s0,-62
    80004122:	854e                	mv	a0,s3
    80004124:	00000097          	auipc	ra,0x0
    80004128:	f6c080e7          	jalr	-148(ra) # 80004090 <namecmp>
    8000412c:	f561                	bnez	a0,800040f4 <dirlookup+0x4a>
      if(poff)
    8000412e:	000a0463          	beqz	s4,80004136 <dirlookup+0x8c>
        *poff = off;
    80004132:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004136:	fc045583          	lhu	a1,-64(s0)
    8000413a:	00092503          	lw	a0,0(s2)
    8000413e:	fffff097          	auipc	ra,0xfffff
    80004142:	752080e7          	jalr	1874(ra) # 80003890 <iget>
    80004146:	a011                	j	8000414a <dirlookup+0xa0>
  return 0;
    80004148:	4501                	li	a0,0
}
    8000414a:	70e2                	ld	ra,56(sp)
    8000414c:	7442                	ld	s0,48(sp)
    8000414e:	74a2                	ld	s1,40(sp)
    80004150:	7902                	ld	s2,32(sp)
    80004152:	69e2                	ld	s3,24(sp)
    80004154:	6a42                	ld	s4,16(sp)
    80004156:	6121                	addi	sp,sp,64
    80004158:	8082                	ret

000000008000415a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000415a:	711d                	addi	sp,sp,-96
    8000415c:	ec86                	sd	ra,88(sp)
    8000415e:	e8a2                	sd	s0,80(sp)
    80004160:	e4a6                	sd	s1,72(sp)
    80004162:	e0ca                	sd	s2,64(sp)
    80004164:	fc4e                	sd	s3,56(sp)
    80004166:	f852                	sd	s4,48(sp)
    80004168:	f456                	sd	s5,40(sp)
    8000416a:	f05a                	sd	s6,32(sp)
    8000416c:	ec5e                	sd	s7,24(sp)
    8000416e:	e862                	sd	s8,16(sp)
    80004170:	e466                	sd	s9,8(sp)
    80004172:	e06a                	sd	s10,0(sp)
    80004174:	1080                	addi	s0,sp,96
    80004176:	84aa                	mv	s1,a0
    80004178:	8b2e                	mv	s6,a1
    8000417a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000417c:	00054703          	lbu	a4,0(a0)
    80004180:	02f00793          	li	a5,47
    80004184:	02f70363          	beq	a4,a5,800041aa <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004188:	ffffe097          	auipc	ra,0xffffe
    8000418c:	80e080e7          	jalr	-2034(ra) # 80001996 <myproc>
    80004190:	15053503          	ld	a0,336(a0)
    80004194:	00000097          	auipc	ra,0x0
    80004198:	9f4080e7          	jalr	-1548(ra) # 80003b88 <idup>
    8000419c:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000419e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800041a2:	4cb5                	li	s9,13
  len = path - s;
    800041a4:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041a6:	4c05                	li	s8,1
    800041a8:	a87d                	j	80004266 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800041aa:	4585                	li	a1,1
    800041ac:	4505                	li	a0,1
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	6e2080e7          	jalr	1762(ra) # 80003890 <iget>
    800041b6:	8a2a                	mv	s4,a0
    800041b8:	b7dd                	j	8000419e <namex+0x44>
      iunlockput(ip);
    800041ba:	8552                	mv	a0,s4
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	c6c080e7          	jalr	-916(ra) # 80003e28 <iunlockput>
      return 0;
    800041c4:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041c6:	8552                	mv	a0,s4
    800041c8:	60e6                	ld	ra,88(sp)
    800041ca:	6446                	ld	s0,80(sp)
    800041cc:	64a6                	ld	s1,72(sp)
    800041ce:	6906                	ld	s2,64(sp)
    800041d0:	79e2                	ld	s3,56(sp)
    800041d2:	7a42                	ld	s4,48(sp)
    800041d4:	7aa2                	ld	s5,40(sp)
    800041d6:	7b02                	ld	s6,32(sp)
    800041d8:	6be2                	ld	s7,24(sp)
    800041da:	6c42                	ld	s8,16(sp)
    800041dc:	6ca2                	ld	s9,8(sp)
    800041de:	6d02                	ld	s10,0(sp)
    800041e0:	6125                	addi	sp,sp,96
    800041e2:	8082                	ret
      iunlock(ip);
    800041e4:	8552                	mv	a0,s4
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	aa2080e7          	jalr	-1374(ra) # 80003c88 <iunlock>
      return ip;
    800041ee:	bfe1                	j	800041c6 <namex+0x6c>
      iunlockput(ip);
    800041f0:	8552                	mv	a0,s4
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	c36080e7          	jalr	-970(ra) # 80003e28 <iunlockput>
      return 0;
    800041fa:	8a4e                	mv	s4,s3
    800041fc:	b7e9                	j	800041c6 <namex+0x6c>
  len = path - s;
    800041fe:	40998633          	sub	a2,s3,s1
    80004202:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004206:	09acd863          	bge	s9,s10,80004296 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000420a:	4639                	li	a2,14
    8000420c:	85a6                	mv	a1,s1
    8000420e:	8556                	mv	a0,s5
    80004210:	ffffd097          	auipc	ra,0xffffd
    80004214:	b18080e7          	jalr	-1256(ra) # 80000d28 <memmove>
    80004218:	84ce                	mv	s1,s3
  while(*path == '/')
    8000421a:	0004c783          	lbu	a5,0(s1)
    8000421e:	01279763          	bne	a5,s2,8000422c <namex+0xd2>
    path++;
    80004222:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004224:	0004c783          	lbu	a5,0(s1)
    80004228:	ff278de3          	beq	a5,s2,80004222 <namex+0xc8>
    ilock(ip);
    8000422c:	8552                	mv	a0,s4
    8000422e:	00000097          	auipc	ra,0x0
    80004232:	998080e7          	jalr	-1640(ra) # 80003bc6 <ilock>
    if(ip->type != T_DIR){
    80004236:	044a1783          	lh	a5,68(s4)
    8000423a:	f98790e3          	bne	a5,s8,800041ba <namex+0x60>
    if(nameiparent && *path == '\0'){
    8000423e:	000b0563          	beqz	s6,80004248 <namex+0xee>
    80004242:	0004c783          	lbu	a5,0(s1)
    80004246:	dfd9                	beqz	a5,800041e4 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004248:	865e                	mv	a2,s7
    8000424a:	85d6                	mv	a1,s5
    8000424c:	8552                	mv	a0,s4
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	e5c080e7          	jalr	-420(ra) # 800040aa <dirlookup>
    80004256:	89aa                	mv	s3,a0
    80004258:	dd41                	beqz	a0,800041f0 <namex+0x96>
    iunlockput(ip);
    8000425a:	8552                	mv	a0,s4
    8000425c:	00000097          	auipc	ra,0x0
    80004260:	bcc080e7          	jalr	-1076(ra) # 80003e28 <iunlockput>
    ip = next;
    80004264:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004266:	0004c783          	lbu	a5,0(s1)
    8000426a:	01279763          	bne	a5,s2,80004278 <namex+0x11e>
    path++;
    8000426e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004270:	0004c783          	lbu	a5,0(s1)
    80004274:	ff278de3          	beq	a5,s2,8000426e <namex+0x114>
  if(*path == 0)
    80004278:	cb9d                	beqz	a5,800042ae <namex+0x154>
  while(*path != '/' && *path != 0)
    8000427a:	0004c783          	lbu	a5,0(s1)
    8000427e:	89a6                	mv	s3,s1
  len = path - s;
    80004280:	8d5e                	mv	s10,s7
    80004282:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004284:	01278963          	beq	a5,s2,80004296 <namex+0x13c>
    80004288:	dbbd                	beqz	a5,800041fe <namex+0xa4>
    path++;
    8000428a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000428c:	0009c783          	lbu	a5,0(s3)
    80004290:	ff279ce3          	bne	a5,s2,80004288 <namex+0x12e>
    80004294:	b7ad                	j	800041fe <namex+0xa4>
    memmove(name, s, len);
    80004296:	2601                	sext.w	a2,a2
    80004298:	85a6                	mv	a1,s1
    8000429a:	8556                	mv	a0,s5
    8000429c:	ffffd097          	auipc	ra,0xffffd
    800042a0:	a8c080e7          	jalr	-1396(ra) # 80000d28 <memmove>
    name[len] = 0;
    800042a4:	9d56                	add	s10,s10,s5
    800042a6:	000d0023          	sb	zero,0(s10)
    800042aa:	84ce                	mv	s1,s3
    800042ac:	b7bd                	j	8000421a <namex+0xc0>
  if(nameiparent){
    800042ae:	f00b0ce3          	beqz	s6,800041c6 <namex+0x6c>
    iput(ip);
    800042b2:	8552                	mv	a0,s4
    800042b4:	00000097          	auipc	ra,0x0
    800042b8:	acc080e7          	jalr	-1332(ra) # 80003d80 <iput>
    return 0;
    800042bc:	4a01                	li	s4,0
    800042be:	b721                	j	800041c6 <namex+0x6c>

00000000800042c0 <dirlink>:
{
    800042c0:	7139                	addi	sp,sp,-64
    800042c2:	fc06                	sd	ra,56(sp)
    800042c4:	f822                	sd	s0,48(sp)
    800042c6:	f426                	sd	s1,40(sp)
    800042c8:	f04a                	sd	s2,32(sp)
    800042ca:	ec4e                	sd	s3,24(sp)
    800042cc:	e852                	sd	s4,16(sp)
    800042ce:	0080                	addi	s0,sp,64
    800042d0:	892a                	mv	s2,a0
    800042d2:	8a2e                	mv	s4,a1
    800042d4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042d6:	4601                	li	a2,0
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	dd2080e7          	jalr	-558(ra) # 800040aa <dirlookup>
    800042e0:	e93d                	bnez	a0,80004356 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042e2:	04c92483          	lw	s1,76(s2)
    800042e6:	c49d                	beqz	s1,80004314 <dirlink+0x54>
    800042e8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ea:	4741                	li	a4,16
    800042ec:	86a6                	mv	a3,s1
    800042ee:	fc040613          	addi	a2,s0,-64
    800042f2:	4581                	li	a1,0
    800042f4:	854a                	mv	a0,s2
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	b84080e7          	jalr	-1148(ra) # 80003e7a <readi>
    800042fe:	47c1                	li	a5,16
    80004300:	06f51163          	bne	a0,a5,80004362 <dirlink+0xa2>
    if(de.inum == 0)
    80004304:	fc045783          	lhu	a5,-64(s0)
    80004308:	c791                	beqz	a5,80004314 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000430a:	24c1                	addiw	s1,s1,16
    8000430c:	04c92783          	lw	a5,76(s2)
    80004310:	fcf4ede3          	bltu	s1,a5,800042ea <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004314:	4639                	li	a2,14
    80004316:	85d2                	mv	a1,s4
    80004318:	fc240513          	addi	a0,s0,-62
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	abc080e7          	jalr	-1348(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80004324:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004328:	4741                	li	a4,16
    8000432a:	86a6                	mv	a3,s1
    8000432c:	fc040613          	addi	a2,s0,-64
    80004330:	4581                	li	a1,0
    80004332:	854a                	mv	a0,s2
    80004334:	00000097          	auipc	ra,0x0
    80004338:	c3e080e7          	jalr	-962(ra) # 80003f72 <writei>
    8000433c:	872a                	mv	a4,a0
    8000433e:	47c1                	li	a5,16
  return 0;
    80004340:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004342:	02f71863          	bne	a4,a5,80004372 <dirlink+0xb2>
}
    80004346:	70e2                	ld	ra,56(sp)
    80004348:	7442                	ld	s0,48(sp)
    8000434a:	74a2                	ld	s1,40(sp)
    8000434c:	7902                	ld	s2,32(sp)
    8000434e:	69e2                	ld	s3,24(sp)
    80004350:	6a42                	ld	s4,16(sp)
    80004352:	6121                	addi	sp,sp,64
    80004354:	8082                	ret
    iput(ip);
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	a2a080e7          	jalr	-1494(ra) # 80003d80 <iput>
    return -1;
    8000435e:	557d                	li	a0,-1
    80004360:	b7dd                	j	80004346 <dirlink+0x86>
      panic("dirlink read");
    80004362:	00004517          	auipc	a0,0x4
    80004366:	39650513          	addi	a0,a0,918 # 800086f8 <syscalls+0x200>
    8000436a:	ffffc097          	auipc	ra,0xffffc
    8000436e:	1d0080e7          	jalr	464(ra) # 8000053a <panic>
    panic("dirlink");
    80004372:	00004517          	auipc	a0,0x4
    80004376:	49650513          	addi	a0,a0,1174 # 80008808 <syscalls+0x310>
    8000437a:	ffffc097          	auipc	ra,0xffffc
    8000437e:	1c0080e7          	jalr	448(ra) # 8000053a <panic>

0000000080004382 <namei>:

struct inode*
namei(char *path)
{
    80004382:	1101                	addi	sp,sp,-32
    80004384:	ec06                	sd	ra,24(sp)
    80004386:	e822                	sd	s0,16(sp)
    80004388:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000438a:	fe040613          	addi	a2,s0,-32
    8000438e:	4581                	li	a1,0
    80004390:	00000097          	auipc	ra,0x0
    80004394:	dca080e7          	jalr	-566(ra) # 8000415a <namex>
}
    80004398:	60e2                	ld	ra,24(sp)
    8000439a:	6442                	ld	s0,16(sp)
    8000439c:	6105                	addi	sp,sp,32
    8000439e:	8082                	ret

00000000800043a0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043a0:	1141                	addi	sp,sp,-16
    800043a2:	e406                	sd	ra,8(sp)
    800043a4:	e022                	sd	s0,0(sp)
    800043a6:	0800                	addi	s0,sp,16
    800043a8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043aa:	4585                	li	a1,1
    800043ac:	00000097          	auipc	ra,0x0
    800043b0:	dae080e7          	jalr	-594(ra) # 8000415a <namex>
}
    800043b4:	60a2                	ld	ra,8(sp)
    800043b6:	6402                	ld	s0,0(sp)
    800043b8:	0141                	addi	sp,sp,16
    800043ba:	8082                	ret

00000000800043bc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043bc:	1101                	addi	sp,sp,-32
    800043be:	ec06                	sd	ra,24(sp)
    800043c0:	e822                	sd	s0,16(sp)
    800043c2:	e426                	sd	s1,8(sp)
    800043c4:	e04a                	sd	s2,0(sp)
    800043c6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043c8:	0001d917          	auipc	s2,0x1d
    800043cc:	4a890913          	addi	s2,s2,1192 # 80021870 <log>
    800043d0:	01892583          	lw	a1,24(s2)
    800043d4:	02892503          	lw	a0,40(s2)
    800043d8:	fffff097          	auipc	ra,0xfffff
    800043dc:	fec080e7          	jalr	-20(ra) # 800033c4 <bread>
    800043e0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043e2:	02c92683          	lw	a3,44(s2)
    800043e6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043e8:	02d05863          	blez	a3,80004418 <write_head+0x5c>
    800043ec:	0001d797          	auipc	a5,0x1d
    800043f0:	4b478793          	addi	a5,a5,1204 # 800218a0 <log+0x30>
    800043f4:	05c50713          	addi	a4,a0,92
    800043f8:	36fd                	addiw	a3,a3,-1
    800043fa:	02069613          	slli	a2,a3,0x20
    800043fe:	01e65693          	srli	a3,a2,0x1e
    80004402:	0001d617          	auipc	a2,0x1d
    80004406:	4a260613          	addi	a2,a2,1186 # 800218a4 <log+0x34>
    8000440a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000440c:	4390                	lw	a2,0(a5)
    8000440e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004410:	0791                	addi	a5,a5,4
    80004412:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004414:	fed79ce3          	bne	a5,a3,8000440c <write_head+0x50>
  }
  bwrite(buf);
    80004418:	8526                	mv	a0,s1
    8000441a:	fffff097          	auipc	ra,0xfffff
    8000441e:	09c080e7          	jalr	156(ra) # 800034b6 <bwrite>
  brelse(buf);
    80004422:	8526                	mv	a0,s1
    80004424:	fffff097          	auipc	ra,0xfffff
    80004428:	0d0080e7          	jalr	208(ra) # 800034f4 <brelse>
}
    8000442c:	60e2                	ld	ra,24(sp)
    8000442e:	6442                	ld	s0,16(sp)
    80004430:	64a2                	ld	s1,8(sp)
    80004432:	6902                	ld	s2,0(sp)
    80004434:	6105                	addi	sp,sp,32
    80004436:	8082                	ret

0000000080004438 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004438:	0001d797          	auipc	a5,0x1d
    8000443c:	4647a783          	lw	a5,1124(a5) # 8002189c <log+0x2c>
    80004440:	0af05d63          	blez	a5,800044fa <install_trans+0xc2>
{
    80004444:	7139                	addi	sp,sp,-64
    80004446:	fc06                	sd	ra,56(sp)
    80004448:	f822                	sd	s0,48(sp)
    8000444a:	f426                	sd	s1,40(sp)
    8000444c:	f04a                	sd	s2,32(sp)
    8000444e:	ec4e                	sd	s3,24(sp)
    80004450:	e852                	sd	s4,16(sp)
    80004452:	e456                	sd	s5,8(sp)
    80004454:	e05a                	sd	s6,0(sp)
    80004456:	0080                	addi	s0,sp,64
    80004458:	8b2a                	mv	s6,a0
    8000445a:	0001da97          	auipc	s5,0x1d
    8000445e:	446a8a93          	addi	s5,s5,1094 # 800218a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004462:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004464:	0001d997          	auipc	s3,0x1d
    80004468:	40c98993          	addi	s3,s3,1036 # 80021870 <log>
    8000446c:	a00d                	j	8000448e <install_trans+0x56>
    brelse(lbuf);
    8000446e:	854a                	mv	a0,s2
    80004470:	fffff097          	auipc	ra,0xfffff
    80004474:	084080e7          	jalr	132(ra) # 800034f4 <brelse>
    brelse(dbuf);
    80004478:	8526                	mv	a0,s1
    8000447a:	fffff097          	auipc	ra,0xfffff
    8000447e:	07a080e7          	jalr	122(ra) # 800034f4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004482:	2a05                	addiw	s4,s4,1
    80004484:	0a91                	addi	s5,s5,4
    80004486:	02c9a783          	lw	a5,44(s3)
    8000448a:	04fa5e63          	bge	s4,a5,800044e6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000448e:	0189a583          	lw	a1,24(s3)
    80004492:	014585bb          	addw	a1,a1,s4
    80004496:	2585                	addiw	a1,a1,1
    80004498:	0289a503          	lw	a0,40(s3)
    8000449c:	fffff097          	auipc	ra,0xfffff
    800044a0:	f28080e7          	jalr	-216(ra) # 800033c4 <bread>
    800044a4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044a6:	000aa583          	lw	a1,0(s5)
    800044aa:	0289a503          	lw	a0,40(s3)
    800044ae:	fffff097          	auipc	ra,0xfffff
    800044b2:	f16080e7          	jalr	-234(ra) # 800033c4 <bread>
    800044b6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044b8:	40000613          	li	a2,1024
    800044bc:	05890593          	addi	a1,s2,88
    800044c0:	05850513          	addi	a0,a0,88
    800044c4:	ffffd097          	auipc	ra,0xffffd
    800044c8:	864080e7          	jalr	-1948(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    800044cc:	8526                	mv	a0,s1
    800044ce:	fffff097          	auipc	ra,0xfffff
    800044d2:	fe8080e7          	jalr	-24(ra) # 800034b6 <bwrite>
    if(recovering == 0)
    800044d6:	f80b1ce3          	bnez	s6,8000446e <install_trans+0x36>
      bunpin(dbuf);
    800044da:	8526                	mv	a0,s1
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	0f2080e7          	jalr	242(ra) # 800035ce <bunpin>
    800044e4:	b769                	j	8000446e <install_trans+0x36>
}
    800044e6:	70e2                	ld	ra,56(sp)
    800044e8:	7442                	ld	s0,48(sp)
    800044ea:	74a2                	ld	s1,40(sp)
    800044ec:	7902                	ld	s2,32(sp)
    800044ee:	69e2                	ld	s3,24(sp)
    800044f0:	6a42                	ld	s4,16(sp)
    800044f2:	6aa2                	ld	s5,8(sp)
    800044f4:	6b02                	ld	s6,0(sp)
    800044f6:	6121                	addi	sp,sp,64
    800044f8:	8082                	ret
    800044fa:	8082                	ret

00000000800044fc <initlog>:
{
    800044fc:	7179                	addi	sp,sp,-48
    800044fe:	f406                	sd	ra,40(sp)
    80004500:	f022                	sd	s0,32(sp)
    80004502:	ec26                	sd	s1,24(sp)
    80004504:	e84a                	sd	s2,16(sp)
    80004506:	e44e                	sd	s3,8(sp)
    80004508:	1800                	addi	s0,sp,48
    8000450a:	892a                	mv	s2,a0
    8000450c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000450e:	0001d497          	auipc	s1,0x1d
    80004512:	36248493          	addi	s1,s1,866 # 80021870 <log>
    80004516:	00004597          	auipc	a1,0x4
    8000451a:	1f258593          	addi	a1,a1,498 # 80008708 <syscalls+0x210>
    8000451e:	8526                	mv	a0,s1
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	620080e7          	jalr	1568(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80004528:	0149a583          	lw	a1,20(s3)
    8000452c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000452e:	0109a783          	lw	a5,16(s3)
    80004532:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004534:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004538:	854a                	mv	a0,s2
    8000453a:	fffff097          	auipc	ra,0xfffff
    8000453e:	e8a080e7          	jalr	-374(ra) # 800033c4 <bread>
  log.lh.n = lh->n;
    80004542:	4d34                	lw	a3,88(a0)
    80004544:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004546:	02d05663          	blez	a3,80004572 <initlog+0x76>
    8000454a:	05c50793          	addi	a5,a0,92
    8000454e:	0001d717          	auipc	a4,0x1d
    80004552:	35270713          	addi	a4,a4,850 # 800218a0 <log+0x30>
    80004556:	36fd                	addiw	a3,a3,-1
    80004558:	02069613          	slli	a2,a3,0x20
    8000455c:	01e65693          	srli	a3,a2,0x1e
    80004560:	06050613          	addi	a2,a0,96
    80004564:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004566:	4390                	lw	a2,0(a5)
    80004568:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000456a:	0791                	addi	a5,a5,4
    8000456c:	0711                	addi	a4,a4,4
    8000456e:	fed79ce3          	bne	a5,a3,80004566 <initlog+0x6a>
  brelse(buf);
    80004572:	fffff097          	auipc	ra,0xfffff
    80004576:	f82080e7          	jalr	-126(ra) # 800034f4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000457a:	4505                	li	a0,1
    8000457c:	00000097          	auipc	ra,0x0
    80004580:	ebc080e7          	jalr	-324(ra) # 80004438 <install_trans>
  log.lh.n = 0;
    80004584:	0001d797          	auipc	a5,0x1d
    80004588:	3007ac23          	sw	zero,792(a5) # 8002189c <log+0x2c>
  write_head(); // clear the log
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	e30080e7          	jalr	-464(ra) # 800043bc <write_head>
}
    80004594:	70a2                	ld	ra,40(sp)
    80004596:	7402                	ld	s0,32(sp)
    80004598:	64e2                	ld	s1,24(sp)
    8000459a:	6942                	ld	s2,16(sp)
    8000459c:	69a2                	ld	s3,8(sp)
    8000459e:	6145                	addi	sp,sp,48
    800045a0:	8082                	ret

00000000800045a2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045a2:	1101                	addi	sp,sp,-32
    800045a4:	ec06                	sd	ra,24(sp)
    800045a6:	e822                	sd	s0,16(sp)
    800045a8:	e426                	sd	s1,8(sp)
    800045aa:	e04a                	sd	s2,0(sp)
    800045ac:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045ae:	0001d517          	auipc	a0,0x1d
    800045b2:	2c250513          	addi	a0,a0,706 # 80021870 <log>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	61a080e7          	jalr	1562(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    800045be:	0001d497          	auipc	s1,0x1d
    800045c2:	2b248493          	addi	s1,s1,690 # 80021870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045c6:	4979                	li	s2,30
    800045c8:	a039                	j	800045d6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800045ca:	85a6                	mv	a1,s1
    800045cc:	8526                	mv	a0,s1
    800045ce:	ffffe097          	auipc	ra,0xffffe
    800045d2:	ab4080e7          	jalr	-1356(ra) # 80002082 <sleep>
    if(log.committing){
    800045d6:	50dc                	lw	a5,36(s1)
    800045d8:	fbed                	bnez	a5,800045ca <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045da:	5098                	lw	a4,32(s1)
    800045dc:	2705                	addiw	a4,a4,1
    800045de:	0007069b          	sext.w	a3,a4
    800045e2:	0027179b          	slliw	a5,a4,0x2
    800045e6:	9fb9                	addw	a5,a5,a4
    800045e8:	0017979b          	slliw	a5,a5,0x1
    800045ec:	54d8                	lw	a4,44(s1)
    800045ee:	9fb9                	addw	a5,a5,a4
    800045f0:	00f95963          	bge	s2,a5,80004602 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045f4:	85a6                	mv	a1,s1
    800045f6:	8526                	mv	a0,s1
    800045f8:	ffffe097          	auipc	ra,0xffffe
    800045fc:	a8a080e7          	jalr	-1398(ra) # 80002082 <sleep>
    80004600:	bfd9                	j	800045d6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004602:	0001d517          	auipc	a0,0x1d
    80004606:	26e50513          	addi	a0,a0,622 # 80021870 <log>
    8000460a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	678080e7          	jalr	1656(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004614:	60e2                	ld	ra,24(sp)
    80004616:	6442                	ld	s0,16(sp)
    80004618:	64a2                	ld	s1,8(sp)
    8000461a:	6902                	ld	s2,0(sp)
    8000461c:	6105                	addi	sp,sp,32
    8000461e:	8082                	ret

0000000080004620 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004620:	7139                	addi	sp,sp,-64
    80004622:	fc06                	sd	ra,56(sp)
    80004624:	f822                	sd	s0,48(sp)
    80004626:	f426                	sd	s1,40(sp)
    80004628:	f04a                	sd	s2,32(sp)
    8000462a:	ec4e                	sd	s3,24(sp)
    8000462c:	e852                	sd	s4,16(sp)
    8000462e:	e456                	sd	s5,8(sp)
    80004630:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004632:	0001d497          	auipc	s1,0x1d
    80004636:	23e48493          	addi	s1,s1,574 # 80021870 <log>
    8000463a:	8526                	mv	a0,s1
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	594080e7          	jalr	1428(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    80004644:	509c                	lw	a5,32(s1)
    80004646:	37fd                	addiw	a5,a5,-1
    80004648:	0007891b          	sext.w	s2,a5
    8000464c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000464e:	50dc                	lw	a5,36(s1)
    80004650:	e7b9                	bnez	a5,8000469e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004652:	04091e63          	bnez	s2,800046ae <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004656:	0001d497          	auipc	s1,0x1d
    8000465a:	21a48493          	addi	s1,s1,538 # 80021870 <log>
    8000465e:	4785                	li	a5,1
    80004660:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004662:	8526                	mv	a0,s1
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	620080e7          	jalr	1568(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000466c:	54dc                	lw	a5,44(s1)
    8000466e:	06f04763          	bgtz	a5,800046dc <end_op+0xbc>
    acquire(&log.lock);
    80004672:	0001d497          	auipc	s1,0x1d
    80004676:	1fe48493          	addi	s1,s1,510 # 80021870 <log>
    8000467a:	8526                	mv	a0,s1
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	554080e7          	jalr	1364(ra) # 80000bd0 <acquire>
    log.committing = 0;
    80004684:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004688:	8526                	mv	a0,s1
    8000468a:	ffffe097          	auipc	ra,0xffffe
    8000468e:	b84080e7          	jalr	-1148(ra) # 8000220e <wakeup>
    release(&log.lock);
    80004692:	8526                	mv	a0,s1
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	5f0080e7          	jalr	1520(ra) # 80000c84 <release>
}
    8000469c:	a03d                	j	800046ca <end_op+0xaa>
    panic("log.committing");
    8000469e:	00004517          	auipc	a0,0x4
    800046a2:	07250513          	addi	a0,a0,114 # 80008710 <syscalls+0x218>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	e94080e7          	jalr	-364(ra) # 8000053a <panic>
    wakeup(&log);
    800046ae:	0001d497          	auipc	s1,0x1d
    800046b2:	1c248493          	addi	s1,s1,450 # 80021870 <log>
    800046b6:	8526                	mv	a0,s1
    800046b8:	ffffe097          	auipc	ra,0xffffe
    800046bc:	b56080e7          	jalr	-1194(ra) # 8000220e <wakeup>
  release(&log.lock);
    800046c0:	8526                	mv	a0,s1
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	5c2080e7          	jalr	1474(ra) # 80000c84 <release>
}
    800046ca:	70e2                	ld	ra,56(sp)
    800046cc:	7442                	ld	s0,48(sp)
    800046ce:	74a2                	ld	s1,40(sp)
    800046d0:	7902                	ld	s2,32(sp)
    800046d2:	69e2                	ld	s3,24(sp)
    800046d4:	6a42                	ld	s4,16(sp)
    800046d6:	6aa2                	ld	s5,8(sp)
    800046d8:	6121                	addi	sp,sp,64
    800046da:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800046dc:	0001da97          	auipc	s5,0x1d
    800046e0:	1c4a8a93          	addi	s5,s5,452 # 800218a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046e4:	0001da17          	auipc	s4,0x1d
    800046e8:	18ca0a13          	addi	s4,s4,396 # 80021870 <log>
    800046ec:	018a2583          	lw	a1,24(s4)
    800046f0:	012585bb          	addw	a1,a1,s2
    800046f4:	2585                	addiw	a1,a1,1
    800046f6:	028a2503          	lw	a0,40(s4)
    800046fa:	fffff097          	auipc	ra,0xfffff
    800046fe:	cca080e7          	jalr	-822(ra) # 800033c4 <bread>
    80004702:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004704:	000aa583          	lw	a1,0(s5)
    80004708:	028a2503          	lw	a0,40(s4)
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	cb8080e7          	jalr	-840(ra) # 800033c4 <bread>
    80004714:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004716:	40000613          	li	a2,1024
    8000471a:	05850593          	addi	a1,a0,88
    8000471e:	05848513          	addi	a0,s1,88
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	606080e7          	jalr	1542(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    8000472a:	8526                	mv	a0,s1
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	d8a080e7          	jalr	-630(ra) # 800034b6 <bwrite>
    brelse(from);
    80004734:	854e                	mv	a0,s3
    80004736:	fffff097          	auipc	ra,0xfffff
    8000473a:	dbe080e7          	jalr	-578(ra) # 800034f4 <brelse>
    brelse(to);
    8000473e:	8526                	mv	a0,s1
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	db4080e7          	jalr	-588(ra) # 800034f4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004748:	2905                	addiw	s2,s2,1
    8000474a:	0a91                	addi	s5,s5,4
    8000474c:	02ca2783          	lw	a5,44(s4)
    80004750:	f8f94ee3          	blt	s2,a5,800046ec <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004754:	00000097          	auipc	ra,0x0
    80004758:	c68080e7          	jalr	-920(ra) # 800043bc <write_head>
    install_trans(0); // Now install writes to home locations
    8000475c:	4501                	li	a0,0
    8000475e:	00000097          	auipc	ra,0x0
    80004762:	cda080e7          	jalr	-806(ra) # 80004438 <install_trans>
    log.lh.n = 0;
    80004766:	0001d797          	auipc	a5,0x1d
    8000476a:	1207ab23          	sw	zero,310(a5) # 8002189c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000476e:	00000097          	auipc	ra,0x0
    80004772:	c4e080e7          	jalr	-946(ra) # 800043bc <write_head>
    80004776:	bdf5                	j	80004672 <end_op+0x52>

0000000080004778 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004778:	1101                	addi	sp,sp,-32
    8000477a:	ec06                	sd	ra,24(sp)
    8000477c:	e822                	sd	s0,16(sp)
    8000477e:	e426                	sd	s1,8(sp)
    80004780:	e04a                	sd	s2,0(sp)
    80004782:	1000                	addi	s0,sp,32
    80004784:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004786:	0001d917          	auipc	s2,0x1d
    8000478a:	0ea90913          	addi	s2,s2,234 # 80021870 <log>
    8000478e:	854a                	mv	a0,s2
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	440080e7          	jalr	1088(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004798:	02c92603          	lw	a2,44(s2)
    8000479c:	47f5                	li	a5,29
    8000479e:	06c7c563          	blt	a5,a2,80004808 <log_write+0x90>
    800047a2:	0001d797          	auipc	a5,0x1d
    800047a6:	0ea7a783          	lw	a5,234(a5) # 8002188c <log+0x1c>
    800047aa:	37fd                	addiw	a5,a5,-1
    800047ac:	04f65e63          	bge	a2,a5,80004808 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047b0:	0001d797          	auipc	a5,0x1d
    800047b4:	0e07a783          	lw	a5,224(a5) # 80021890 <log+0x20>
    800047b8:	06f05063          	blez	a5,80004818 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047bc:	4781                	li	a5,0
    800047be:	06c05563          	blez	a2,80004828 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047c2:	44cc                	lw	a1,12(s1)
    800047c4:	0001d717          	auipc	a4,0x1d
    800047c8:	0dc70713          	addi	a4,a4,220 # 800218a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047cc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047ce:	4314                	lw	a3,0(a4)
    800047d0:	04b68c63          	beq	a3,a1,80004828 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047d4:	2785                	addiw	a5,a5,1
    800047d6:	0711                	addi	a4,a4,4
    800047d8:	fef61be3          	bne	a2,a5,800047ce <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047dc:	0621                	addi	a2,a2,8
    800047de:	060a                	slli	a2,a2,0x2
    800047e0:	0001d797          	auipc	a5,0x1d
    800047e4:	09078793          	addi	a5,a5,144 # 80021870 <log>
    800047e8:	97b2                	add	a5,a5,a2
    800047ea:	44d8                	lw	a4,12(s1)
    800047ec:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047ee:	8526                	mv	a0,s1
    800047f0:	fffff097          	auipc	ra,0xfffff
    800047f4:	da2080e7          	jalr	-606(ra) # 80003592 <bpin>
    log.lh.n++;
    800047f8:	0001d717          	auipc	a4,0x1d
    800047fc:	07870713          	addi	a4,a4,120 # 80021870 <log>
    80004800:	575c                	lw	a5,44(a4)
    80004802:	2785                	addiw	a5,a5,1
    80004804:	d75c                	sw	a5,44(a4)
    80004806:	a82d                	j	80004840 <log_write+0xc8>
    panic("too big a transaction");
    80004808:	00004517          	auipc	a0,0x4
    8000480c:	f1850513          	addi	a0,a0,-232 # 80008720 <syscalls+0x228>
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	d2a080e7          	jalr	-726(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004818:	00004517          	auipc	a0,0x4
    8000481c:	f2050513          	addi	a0,a0,-224 # 80008738 <syscalls+0x240>
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	d1a080e7          	jalr	-742(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004828:	00878693          	addi	a3,a5,8
    8000482c:	068a                	slli	a3,a3,0x2
    8000482e:	0001d717          	auipc	a4,0x1d
    80004832:	04270713          	addi	a4,a4,66 # 80021870 <log>
    80004836:	9736                	add	a4,a4,a3
    80004838:	44d4                	lw	a3,12(s1)
    8000483a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000483c:	faf609e3          	beq	a2,a5,800047ee <log_write+0x76>
  }
  release(&log.lock);
    80004840:	0001d517          	auipc	a0,0x1d
    80004844:	03050513          	addi	a0,a0,48 # 80021870 <log>
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	43c080e7          	jalr	1084(ra) # 80000c84 <release>
}
    80004850:	60e2                	ld	ra,24(sp)
    80004852:	6442                	ld	s0,16(sp)
    80004854:	64a2                	ld	s1,8(sp)
    80004856:	6902                	ld	s2,0(sp)
    80004858:	6105                	addi	sp,sp,32
    8000485a:	8082                	ret

000000008000485c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000485c:	1101                	addi	sp,sp,-32
    8000485e:	ec06                	sd	ra,24(sp)
    80004860:	e822                	sd	s0,16(sp)
    80004862:	e426                	sd	s1,8(sp)
    80004864:	e04a                	sd	s2,0(sp)
    80004866:	1000                	addi	s0,sp,32
    80004868:	84aa                	mv	s1,a0
    8000486a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000486c:	00004597          	auipc	a1,0x4
    80004870:	eec58593          	addi	a1,a1,-276 # 80008758 <syscalls+0x260>
    80004874:	0521                	addi	a0,a0,8
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	2ca080e7          	jalr	714(ra) # 80000b40 <initlock>
  lk->name = name;
    8000487e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004882:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004886:	0204a423          	sw	zero,40(s1)
}
    8000488a:	60e2                	ld	ra,24(sp)
    8000488c:	6442                	ld	s0,16(sp)
    8000488e:	64a2                	ld	s1,8(sp)
    80004890:	6902                	ld	s2,0(sp)
    80004892:	6105                	addi	sp,sp,32
    80004894:	8082                	ret

0000000080004896 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004896:	1101                	addi	sp,sp,-32
    80004898:	ec06                	sd	ra,24(sp)
    8000489a:	e822                	sd	s0,16(sp)
    8000489c:	e426                	sd	s1,8(sp)
    8000489e:	e04a                	sd	s2,0(sp)
    800048a0:	1000                	addi	s0,sp,32
    800048a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048a4:	00850913          	addi	s2,a0,8
    800048a8:	854a                	mv	a0,s2
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	326080e7          	jalr	806(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    800048b2:	409c                	lw	a5,0(s1)
    800048b4:	cb89                	beqz	a5,800048c6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048b6:	85ca                	mv	a1,s2
    800048b8:	8526                	mv	a0,s1
    800048ba:	ffffd097          	auipc	ra,0xffffd
    800048be:	7c8080e7          	jalr	1992(ra) # 80002082 <sleep>
  while (lk->locked) {
    800048c2:	409c                	lw	a5,0(s1)
    800048c4:	fbed                	bnez	a5,800048b6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048c6:	4785                	li	a5,1
    800048c8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048ca:	ffffd097          	auipc	ra,0xffffd
    800048ce:	0cc080e7          	jalr	204(ra) # 80001996 <myproc>
    800048d2:	591c                	lw	a5,48(a0)
    800048d4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048d6:	854a                	mv	a0,s2
    800048d8:	ffffc097          	auipc	ra,0xffffc
    800048dc:	3ac080e7          	jalr	940(ra) # 80000c84 <release>
}
    800048e0:	60e2                	ld	ra,24(sp)
    800048e2:	6442                	ld	s0,16(sp)
    800048e4:	64a2                	ld	s1,8(sp)
    800048e6:	6902                	ld	s2,0(sp)
    800048e8:	6105                	addi	sp,sp,32
    800048ea:	8082                	ret

00000000800048ec <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048ec:	1101                	addi	sp,sp,-32
    800048ee:	ec06                	sd	ra,24(sp)
    800048f0:	e822                	sd	s0,16(sp)
    800048f2:	e426                	sd	s1,8(sp)
    800048f4:	e04a                	sd	s2,0(sp)
    800048f6:	1000                	addi	s0,sp,32
    800048f8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048fa:	00850913          	addi	s2,a0,8
    800048fe:	854a                	mv	a0,s2
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	2d0080e7          	jalr	720(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    80004908:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000490c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004910:	8526                	mv	a0,s1
    80004912:	ffffe097          	auipc	ra,0xffffe
    80004916:	8fc080e7          	jalr	-1796(ra) # 8000220e <wakeup>
  release(&lk->lk);
    8000491a:	854a                	mv	a0,s2
    8000491c:	ffffc097          	auipc	ra,0xffffc
    80004920:	368080e7          	jalr	872(ra) # 80000c84 <release>
}
    80004924:	60e2                	ld	ra,24(sp)
    80004926:	6442                	ld	s0,16(sp)
    80004928:	64a2                	ld	s1,8(sp)
    8000492a:	6902                	ld	s2,0(sp)
    8000492c:	6105                	addi	sp,sp,32
    8000492e:	8082                	ret

0000000080004930 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004930:	7179                	addi	sp,sp,-48
    80004932:	f406                	sd	ra,40(sp)
    80004934:	f022                	sd	s0,32(sp)
    80004936:	ec26                	sd	s1,24(sp)
    80004938:	e84a                	sd	s2,16(sp)
    8000493a:	e44e                	sd	s3,8(sp)
    8000493c:	1800                	addi	s0,sp,48
    8000493e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004940:	00850913          	addi	s2,a0,8
    80004944:	854a                	mv	a0,s2
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	28a080e7          	jalr	650(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000494e:	409c                	lw	a5,0(s1)
    80004950:	ef99                	bnez	a5,8000496e <holdingsleep+0x3e>
    80004952:	4481                	li	s1,0
  release(&lk->lk);
    80004954:	854a                	mv	a0,s2
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
  return r;
}
    8000495e:	8526                	mv	a0,s1
    80004960:	70a2                	ld	ra,40(sp)
    80004962:	7402                	ld	s0,32(sp)
    80004964:	64e2                	ld	s1,24(sp)
    80004966:	6942                	ld	s2,16(sp)
    80004968:	69a2                	ld	s3,8(sp)
    8000496a:	6145                	addi	sp,sp,48
    8000496c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000496e:	0284a983          	lw	s3,40(s1)
    80004972:	ffffd097          	auipc	ra,0xffffd
    80004976:	024080e7          	jalr	36(ra) # 80001996 <myproc>
    8000497a:	5904                	lw	s1,48(a0)
    8000497c:	413484b3          	sub	s1,s1,s3
    80004980:	0014b493          	seqz	s1,s1
    80004984:	bfc1                	j	80004954 <holdingsleep+0x24>

0000000080004986 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004986:	1141                	addi	sp,sp,-16
    80004988:	e406                	sd	ra,8(sp)
    8000498a:	e022                	sd	s0,0(sp)
    8000498c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000498e:	00004597          	auipc	a1,0x4
    80004992:	dda58593          	addi	a1,a1,-550 # 80008768 <syscalls+0x270>
    80004996:	0001d517          	auipc	a0,0x1d
    8000499a:	02250513          	addi	a0,a0,34 # 800219b8 <ftable>
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	1a2080e7          	jalr	418(ra) # 80000b40 <initlock>
}
    800049a6:	60a2                	ld	ra,8(sp)
    800049a8:	6402                	ld	s0,0(sp)
    800049aa:	0141                	addi	sp,sp,16
    800049ac:	8082                	ret

00000000800049ae <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049ae:	1101                	addi	sp,sp,-32
    800049b0:	ec06                	sd	ra,24(sp)
    800049b2:	e822                	sd	s0,16(sp)
    800049b4:	e426                	sd	s1,8(sp)
    800049b6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049b8:	0001d517          	auipc	a0,0x1d
    800049bc:	00050513          	mv	a0,a0
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	210080e7          	jalr	528(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049c8:	0001d497          	auipc	s1,0x1d
    800049cc:	00848493          	addi	s1,s1,8 # 800219d0 <ftable+0x18>
    800049d0:	0001e717          	auipc	a4,0x1e
    800049d4:	fa070713          	addi	a4,a4,-96 # 80022970 <ftable+0xfb8>
    if(f->ref == 0){
    800049d8:	40dc                	lw	a5,4(s1)
    800049da:	cf99                	beqz	a5,800049f8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049dc:	02848493          	addi	s1,s1,40
    800049e0:	fee49ce3          	bne	s1,a4,800049d8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049e4:	0001d517          	auipc	a0,0x1d
    800049e8:	fd450513          	addi	a0,a0,-44 # 800219b8 <ftable>
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	298080e7          	jalr	664(ra) # 80000c84 <release>
  return 0;
    800049f4:	4481                	li	s1,0
    800049f6:	a819                	j	80004a0c <filealloc+0x5e>
      f->ref = 1;
    800049f8:	4785                	li	a5,1
    800049fa:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049fc:	0001d517          	auipc	a0,0x1d
    80004a00:	fbc50513          	addi	a0,a0,-68 # 800219b8 <ftable>
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	280080e7          	jalr	640(ra) # 80000c84 <release>
}
    80004a0c:	8526                	mv	a0,s1
    80004a0e:	60e2                	ld	ra,24(sp)
    80004a10:	6442                	ld	s0,16(sp)
    80004a12:	64a2                	ld	s1,8(sp)
    80004a14:	6105                	addi	sp,sp,32
    80004a16:	8082                	ret

0000000080004a18 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a18:	1101                	addi	sp,sp,-32
    80004a1a:	ec06                	sd	ra,24(sp)
    80004a1c:	e822                	sd	s0,16(sp)
    80004a1e:	e426                	sd	s1,8(sp)
    80004a20:	1000                	addi	s0,sp,32
    80004a22:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a24:	0001d517          	auipc	a0,0x1d
    80004a28:	f9450513          	addi	a0,a0,-108 # 800219b8 <ftable>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	1a4080e7          	jalr	420(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004a34:	40dc                	lw	a5,4(s1)
    80004a36:	02f05263          	blez	a5,80004a5a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a3a:	2785                	addiw	a5,a5,1
    80004a3c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a3e:	0001d517          	auipc	a0,0x1d
    80004a42:	f7a50513          	addi	a0,a0,-134 # 800219b8 <ftable>
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	23e080e7          	jalr	574(ra) # 80000c84 <release>
  return f;
}
    80004a4e:	8526                	mv	a0,s1
    80004a50:	60e2                	ld	ra,24(sp)
    80004a52:	6442                	ld	s0,16(sp)
    80004a54:	64a2                	ld	s1,8(sp)
    80004a56:	6105                	addi	sp,sp,32
    80004a58:	8082                	ret
    panic("filedup");
    80004a5a:	00004517          	auipc	a0,0x4
    80004a5e:	d1650513          	addi	a0,a0,-746 # 80008770 <syscalls+0x278>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	ad8080e7          	jalr	-1320(ra) # 8000053a <panic>

0000000080004a6a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a6a:	7139                	addi	sp,sp,-64
    80004a6c:	fc06                	sd	ra,56(sp)
    80004a6e:	f822                	sd	s0,48(sp)
    80004a70:	f426                	sd	s1,40(sp)
    80004a72:	f04a                	sd	s2,32(sp)
    80004a74:	ec4e                	sd	s3,24(sp)
    80004a76:	e852                	sd	s4,16(sp)
    80004a78:	e456                	sd	s5,8(sp)
    80004a7a:	0080                	addi	s0,sp,64
    80004a7c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a7e:	0001d517          	auipc	a0,0x1d
    80004a82:	f3a50513          	addi	a0,a0,-198 # 800219b8 <ftable>
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	14a080e7          	jalr	330(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004a8e:	40dc                	lw	a5,4(s1)
    80004a90:	06f05163          	blez	a5,80004af2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a94:	37fd                	addiw	a5,a5,-1
    80004a96:	0007871b          	sext.w	a4,a5
    80004a9a:	c0dc                	sw	a5,4(s1)
    80004a9c:	06e04363          	bgtz	a4,80004b02 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004aa0:	0004a903          	lw	s2,0(s1)
    80004aa4:	0094ca83          	lbu	s5,9(s1)
    80004aa8:	0104ba03          	ld	s4,16(s1)
    80004aac:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ab0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004ab4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ab8:	0001d517          	auipc	a0,0x1d
    80004abc:	f0050513          	addi	a0,a0,-256 # 800219b8 <ftable>
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	1c4080e7          	jalr	452(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    80004ac8:	4785                	li	a5,1
    80004aca:	04f90d63          	beq	s2,a5,80004b24 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ace:	3979                	addiw	s2,s2,-2
    80004ad0:	4785                	li	a5,1
    80004ad2:	0527e063          	bltu	a5,s2,80004b12 <fileclose+0xa8>
    begin_op();
    80004ad6:	00000097          	auipc	ra,0x0
    80004ada:	acc080e7          	jalr	-1332(ra) # 800045a2 <begin_op>
    iput(ff.ip);
    80004ade:	854e                	mv	a0,s3
    80004ae0:	fffff097          	auipc	ra,0xfffff
    80004ae4:	2a0080e7          	jalr	672(ra) # 80003d80 <iput>
    end_op();
    80004ae8:	00000097          	auipc	ra,0x0
    80004aec:	b38080e7          	jalr	-1224(ra) # 80004620 <end_op>
    80004af0:	a00d                	j	80004b12 <fileclose+0xa8>
    panic("fileclose");
    80004af2:	00004517          	auipc	a0,0x4
    80004af6:	c8650513          	addi	a0,a0,-890 # 80008778 <syscalls+0x280>
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	a40080e7          	jalr	-1472(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004b02:	0001d517          	auipc	a0,0x1d
    80004b06:	eb650513          	addi	a0,a0,-330 # 800219b8 <ftable>
    80004b0a:	ffffc097          	auipc	ra,0xffffc
    80004b0e:	17a080e7          	jalr	378(ra) # 80000c84 <release>
  }
}
    80004b12:	70e2                	ld	ra,56(sp)
    80004b14:	7442                	ld	s0,48(sp)
    80004b16:	74a2                	ld	s1,40(sp)
    80004b18:	7902                	ld	s2,32(sp)
    80004b1a:	69e2                	ld	s3,24(sp)
    80004b1c:	6a42                	ld	s4,16(sp)
    80004b1e:	6aa2                	ld	s5,8(sp)
    80004b20:	6121                	addi	sp,sp,64
    80004b22:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b24:	85d6                	mv	a1,s5
    80004b26:	8552                	mv	a0,s4
    80004b28:	00000097          	auipc	ra,0x0
    80004b2c:	34c080e7          	jalr	844(ra) # 80004e74 <pipeclose>
    80004b30:	b7cd                	j	80004b12 <fileclose+0xa8>

0000000080004b32 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b32:	715d                	addi	sp,sp,-80
    80004b34:	e486                	sd	ra,72(sp)
    80004b36:	e0a2                	sd	s0,64(sp)
    80004b38:	fc26                	sd	s1,56(sp)
    80004b3a:	f84a                	sd	s2,48(sp)
    80004b3c:	f44e                	sd	s3,40(sp)
    80004b3e:	0880                	addi	s0,sp,80
    80004b40:	84aa                	mv	s1,a0
    80004b42:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b44:	ffffd097          	auipc	ra,0xffffd
    80004b48:	e52080e7          	jalr	-430(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b4c:	409c                	lw	a5,0(s1)
    80004b4e:	37f9                	addiw	a5,a5,-2
    80004b50:	4705                	li	a4,1
    80004b52:	04f76763          	bltu	a4,a5,80004ba0 <filestat+0x6e>
    80004b56:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b58:	6c88                	ld	a0,24(s1)
    80004b5a:	fffff097          	auipc	ra,0xfffff
    80004b5e:	06c080e7          	jalr	108(ra) # 80003bc6 <ilock>
    stati(f->ip, &st);
    80004b62:	fb840593          	addi	a1,s0,-72
    80004b66:	6c88                	ld	a0,24(s1)
    80004b68:	fffff097          	auipc	ra,0xfffff
    80004b6c:	2e8080e7          	jalr	744(ra) # 80003e50 <stati>
    iunlock(f->ip);
    80004b70:	6c88                	ld	a0,24(s1)
    80004b72:	fffff097          	auipc	ra,0xfffff
    80004b76:	116080e7          	jalr	278(ra) # 80003c88 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b7a:	46e1                	li	a3,24
    80004b7c:	fb840613          	addi	a2,s0,-72
    80004b80:	85ce                	mv	a1,s3
    80004b82:	05093503          	ld	a0,80(s2)
    80004b86:	ffffd097          	auipc	ra,0xffffd
    80004b8a:	ad4080e7          	jalr	-1324(ra) # 8000165a <copyout>
    80004b8e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b92:	60a6                	ld	ra,72(sp)
    80004b94:	6406                	ld	s0,64(sp)
    80004b96:	74e2                	ld	s1,56(sp)
    80004b98:	7942                	ld	s2,48(sp)
    80004b9a:	79a2                	ld	s3,40(sp)
    80004b9c:	6161                	addi	sp,sp,80
    80004b9e:	8082                	ret
  return -1;
    80004ba0:	557d                	li	a0,-1
    80004ba2:	bfc5                	j	80004b92 <filestat+0x60>

0000000080004ba4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ba4:	7179                	addi	sp,sp,-48
    80004ba6:	f406                	sd	ra,40(sp)
    80004ba8:	f022                	sd	s0,32(sp)
    80004baa:	ec26                	sd	s1,24(sp)
    80004bac:	e84a                	sd	s2,16(sp)
    80004bae:	e44e                	sd	s3,8(sp)
    80004bb0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bb2:	00854783          	lbu	a5,8(a0)
    80004bb6:	c3d5                	beqz	a5,80004c5a <fileread+0xb6>
    80004bb8:	84aa                	mv	s1,a0
    80004bba:	89ae                	mv	s3,a1
    80004bbc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bbe:	411c                	lw	a5,0(a0)
    80004bc0:	4705                	li	a4,1
    80004bc2:	04e78963          	beq	a5,a4,80004c14 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bc6:	470d                	li	a4,3
    80004bc8:	04e78d63          	beq	a5,a4,80004c22 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bcc:	4709                	li	a4,2
    80004bce:	06e79e63          	bne	a5,a4,80004c4a <fileread+0xa6>
    ilock(f->ip);
    80004bd2:	6d08                	ld	a0,24(a0)
    80004bd4:	fffff097          	auipc	ra,0xfffff
    80004bd8:	ff2080e7          	jalr	-14(ra) # 80003bc6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004bdc:	874a                	mv	a4,s2
    80004bde:	5094                	lw	a3,32(s1)
    80004be0:	864e                	mv	a2,s3
    80004be2:	4585                	li	a1,1
    80004be4:	6c88                	ld	a0,24(s1)
    80004be6:	fffff097          	auipc	ra,0xfffff
    80004bea:	294080e7          	jalr	660(ra) # 80003e7a <readi>
    80004bee:	892a                	mv	s2,a0
    80004bf0:	00a05563          	blez	a0,80004bfa <fileread+0x56>
      f->off += r;
    80004bf4:	509c                	lw	a5,32(s1)
    80004bf6:	9fa9                	addw	a5,a5,a0
    80004bf8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bfa:	6c88                	ld	a0,24(s1)
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	08c080e7          	jalr	140(ra) # 80003c88 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c04:	854a                	mv	a0,s2
    80004c06:	70a2                	ld	ra,40(sp)
    80004c08:	7402                	ld	s0,32(sp)
    80004c0a:	64e2                	ld	s1,24(sp)
    80004c0c:	6942                	ld	s2,16(sp)
    80004c0e:	69a2                	ld	s3,8(sp)
    80004c10:	6145                	addi	sp,sp,48
    80004c12:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c14:	6908                	ld	a0,16(a0)
    80004c16:	00000097          	auipc	ra,0x0
    80004c1a:	3c0080e7          	jalr	960(ra) # 80004fd6 <piperead>
    80004c1e:	892a                	mv	s2,a0
    80004c20:	b7d5                	j	80004c04 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c22:	02451783          	lh	a5,36(a0)
    80004c26:	03079693          	slli	a3,a5,0x30
    80004c2a:	92c1                	srli	a3,a3,0x30
    80004c2c:	4725                	li	a4,9
    80004c2e:	02d76863          	bltu	a4,a3,80004c5e <fileread+0xba>
    80004c32:	0792                	slli	a5,a5,0x4
    80004c34:	0001d717          	auipc	a4,0x1d
    80004c38:	ce470713          	addi	a4,a4,-796 # 80021918 <devsw>
    80004c3c:	97ba                	add	a5,a5,a4
    80004c3e:	639c                	ld	a5,0(a5)
    80004c40:	c38d                	beqz	a5,80004c62 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c42:	4505                	li	a0,1
    80004c44:	9782                	jalr	a5
    80004c46:	892a                	mv	s2,a0
    80004c48:	bf75                	j	80004c04 <fileread+0x60>
    panic("fileread");
    80004c4a:	00004517          	auipc	a0,0x4
    80004c4e:	b3e50513          	addi	a0,a0,-1218 # 80008788 <syscalls+0x290>
    80004c52:	ffffc097          	auipc	ra,0xffffc
    80004c56:	8e8080e7          	jalr	-1816(ra) # 8000053a <panic>
    return -1;
    80004c5a:	597d                	li	s2,-1
    80004c5c:	b765                	j	80004c04 <fileread+0x60>
      return -1;
    80004c5e:	597d                	li	s2,-1
    80004c60:	b755                	j	80004c04 <fileread+0x60>
    80004c62:	597d                	li	s2,-1
    80004c64:	b745                	j	80004c04 <fileread+0x60>

0000000080004c66 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c66:	715d                	addi	sp,sp,-80
    80004c68:	e486                	sd	ra,72(sp)
    80004c6a:	e0a2                	sd	s0,64(sp)
    80004c6c:	fc26                	sd	s1,56(sp)
    80004c6e:	f84a                	sd	s2,48(sp)
    80004c70:	f44e                	sd	s3,40(sp)
    80004c72:	f052                	sd	s4,32(sp)
    80004c74:	ec56                	sd	s5,24(sp)
    80004c76:	e85a                	sd	s6,16(sp)
    80004c78:	e45e                	sd	s7,8(sp)
    80004c7a:	e062                	sd	s8,0(sp)
    80004c7c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c7e:	00954783          	lbu	a5,9(a0)
    80004c82:	10078663          	beqz	a5,80004d8e <filewrite+0x128>
    80004c86:	892a                	mv	s2,a0
    80004c88:	8b2e                	mv	s6,a1
    80004c8a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c8c:	411c                	lw	a5,0(a0)
    80004c8e:	4705                	li	a4,1
    80004c90:	02e78263          	beq	a5,a4,80004cb4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c94:	470d                	li	a4,3
    80004c96:	02e78663          	beq	a5,a4,80004cc2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c9a:	4709                	li	a4,2
    80004c9c:	0ee79163          	bne	a5,a4,80004d7e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ca0:	0ac05d63          	blez	a2,80004d5a <filewrite+0xf4>
    int i = 0;
    80004ca4:	4981                	li	s3,0
    80004ca6:	6b85                	lui	s7,0x1
    80004ca8:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004cac:	6c05                	lui	s8,0x1
    80004cae:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004cb2:	a861                	j	80004d4a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cb4:	6908                	ld	a0,16(a0)
    80004cb6:	00000097          	auipc	ra,0x0
    80004cba:	22e080e7          	jalr	558(ra) # 80004ee4 <pipewrite>
    80004cbe:	8a2a                	mv	s4,a0
    80004cc0:	a045                	j	80004d60 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cc2:	02451783          	lh	a5,36(a0)
    80004cc6:	03079693          	slli	a3,a5,0x30
    80004cca:	92c1                	srli	a3,a3,0x30
    80004ccc:	4725                	li	a4,9
    80004cce:	0cd76263          	bltu	a4,a3,80004d92 <filewrite+0x12c>
    80004cd2:	0792                	slli	a5,a5,0x4
    80004cd4:	0001d717          	auipc	a4,0x1d
    80004cd8:	c4470713          	addi	a4,a4,-956 # 80021918 <devsw>
    80004cdc:	97ba                	add	a5,a5,a4
    80004cde:	679c                	ld	a5,8(a5)
    80004ce0:	cbdd                	beqz	a5,80004d96 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ce2:	4505                	li	a0,1
    80004ce4:	9782                	jalr	a5
    80004ce6:	8a2a                	mv	s4,a0
    80004ce8:	a8a5                	j	80004d60 <filewrite+0xfa>
    80004cea:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004cee:	00000097          	auipc	ra,0x0
    80004cf2:	8b4080e7          	jalr	-1868(ra) # 800045a2 <begin_op>
      ilock(f->ip);
    80004cf6:	01893503          	ld	a0,24(s2)
    80004cfa:	fffff097          	auipc	ra,0xfffff
    80004cfe:	ecc080e7          	jalr	-308(ra) # 80003bc6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d02:	8756                	mv	a4,s5
    80004d04:	02092683          	lw	a3,32(s2)
    80004d08:	01698633          	add	a2,s3,s6
    80004d0c:	4585                	li	a1,1
    80004d0e:	01893503          	ld	a0,24(s2)
    80004d12:	fffff097          	auipc	ra,0xfffff
    80004d16:	260080e7          	jalr	608(ra) # 80003f72 <writei>
    80004d1a:	84aa                	mv	s1,a0
    80004d1c:	00a05763          	blez	a0,80004d2a <filewrite+0xc4>
        f->off += r;
    80004d20:	02092783          	lw	a5,32(s2)
    80004d24:	9fa9                	addw	a5,a5,a0
    80004d26:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d2a:	01893503          	ld	a0,24(s2)
    80004d2e:	fffff097          	auipc	ra,0xfffff
    80004d32:	f5a080e7          	jalr	-166(ra) # 80003c88 <iunlock>
      end_op();
    80004d36:	00000097          	auipc	ra,0x0
    80004d3a:	8ea080e7          	jalr	-1814(ra) # 80004620 <end_op>

      if(r != n1){
    80004d3e:	009a9f63          	bne	s5,s1,80004d5c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d42:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d46:	0149db63          	bge	s3,s4,80004d5c <filewrite+0xf6>
      int n1 = n - i;
    80004d4a:	413a04bb          	subw	s1,s4,s3
    80004d4e:	0004879b          	sext.w	a5,s1
    80004d52:	f8fbdce3          	bge	s7,a5,80004cea <filewrite+0x84>
    80004d56:	84e2                	mv	s1,s8
    80004d58:	bf49                	j	80004cea <filewrite+0x84>
    int i = 0;
    80004d5a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d5c:	013a1f63          	bne	s4,s3,80004d7a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d60:	8552                	mv	a0,s4
    80004d62:	60a6                	ld	ra,72(sp)
    80004d64:	6406                	ld	s0,64(sp)
    80004d66:	74e2                	ld	s1,56(sp)
    80004d68:	7942                	ld	s2,48(sp)
    80004d6a:	79a2                	ld	s3,40(sp)
    80004d6c:	7a02                	ld	s4,32(sp)
    80004d6e:	6ae2                	ld	s5,24(sp)
    80004d70:	6b42                	ld	s6,16(sp)
    80004d72:	6ba2                	ld	s7,8(sp)
    80004d74:	6c02                	ld	s8,0(sp)
    80004d76:	6161                	addi	sp,sp,80
    80004d78:	8082                	ret
    ret = (i == n ? n : -1);
    80004d7a:	5a7d                	li	s4,-1
    80004d7c:	b7d5                	j	80004d60 <filewrite+0xfa>
    panic("filewrite");
    80004d7e:	00004517          	auipc	a0,0x4
    80004d82:	a1a50513          	addi	a0,a0,-1510 # 80008798 <syscalls+0x2a0>
    80004d86:	ffffb097          	auipc	ra,0xffffb
    80004d8a:	7b4080e7          	jalr	1972(ra) # 8000053a <panic>
    return -1;
    80004d8e:	5a7d                	li	s4,-1
    80004d90:	bfc1                	j	80004d60 <filewrite+0xfa>
      return -1;
    80004d92:	5a7d                	li	s4,-1
    80004d94:	b7f1                	j	80004d60 <filewrite+0xfa>
    80004d96:	5a7d                	li	s4,-1
    80004d98:	b7e1                	j	80004d60 <filewrite+0xfa>

0000000080004d9a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d9a:	7179                	addi	sp,sp,-48
    80004d9c:	f406                	sd	ra,40(sp)
    80004d9e:	f022                	sd	s0,32(sp)
    80004da0:	ec26                	sd	s1,24(sp)
    80004da2:	e84a                	sd	s2,16(sp)
    80004da4:	e44e                	sd	s3,8(sp)
    80004da6:	e052                	sd	s4,0(sp)
    80004da8:	1800                	addi	s0,sp,48
    80004daa:	84aa                	mv	s1,a0
    80004dac:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004dae:	0005b023          	sd	zero,0(a1)
    80004db2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004db6:	00000097          	auipc	ra,0x0
    80004dba:	bf8080e7          	jalr	-1032(ra) # 800049ae <filealloc>
    80004dbe:	e088                	sd	a0,0(s1)
    80004dc0:	c551                	beqz	a0,80004e4c <pipealloc+0xb2>
    80004dc2:	00000097          	auipc	ra,0x0
    80004dc6:	bec080e7          	jalr	-1044(ra) # 800049ae <filealloc>
    80004dca:	00aa3023          	sd	a0,0(s4)
    80004dce:	c92d                	beqz	a0,80004e40 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	d10080e7          	jalr	-752(ra) # 80000ae0 <kalloc>
    80004dd8:	892a                	mv	s2,a0
    80004dda:	c125                	beqz	a0,80004e3a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ddc:	4985                	li	s3,1
    80004dde:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004de2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004de6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004dea:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004dee:	00004597          	auipc	a1,0x4
    80004df2:	9ba58593          	addi	a1,a1,-1606 # 800087a8 <syscalls+0x2b0>
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	d4a080e7          	jalr	-694(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004dfe:	609c                	ld	a5,0(s1)
    80004e00:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e04:	609c                	ld	a5,0(s1)
    80004e06:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e0a:	609c                	ld	a5,0(s1)
    80004e0c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e10:	609c                	ld	a5,0(s1)
    80004e12:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e16:	000a3783          	ld	a5,0(s4)
    80004e1a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e1e:	000a3783          	ld	a5,0(s4)
    80004e22:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e26:	000a3783          	ld	a5,0(s4)
    80004e2a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e2e:	000a3783          	ld	a5,0(s4)
    80004e32:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e36:	4501                	li	a0,0
    80004e38:	a025                	j	80004e60 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e3a:	6088                	ld	a0,0(s1)
    80004e3c:	e501                	bnez	a0,80004e44 <pipealloc+0xaa>
    80004e3e:	a039                	j	80004e4c <pipealloc+0xb2>
    80004e40:	6088                	ld	a0,0(s1)
    80004e42:	c51d                	beqz	a0,80004e70 <pipealloc+0xd6>
    fileclose(*f0);
    80004e44:	00000097          	auipc	ra,0x0
    80004e48:	c26080e7          	jalr	-986(ra) # 80004a6a <fileclose>
  if(*f1)
    80004e4c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e50:	557d                	li	a0,-1
  if(*f1)
    80004e52:	c799                	beqz	a5,80004e60 <pipealloc+0xc6>
    fileclose(*f1);
    80004e54:	853e                	mv	a0,a5
    80004e56:	00000097          	auipc	ra,0x0
    80004e5a:	c14080e7          	jalr	-1004(ra) # 80004a6a <fileclose>
  return -1;
    80004e5e:	557d                	li	a0,-1
}
    80004e60:	70a2                	ld	ra,40(sp)
    80004e62:	7402                	ld	s0,32(sp)
    80004e64:	64e2                	ld	s1,24(sp)
    80004e66:	6942                	ld	s2,16(sp)
    80004e68:	69a2                	ld	s3,8(sp)
    80004e6a:	6a02                	ld	s4,0(sp)
    80004e6c:	6145                	addi	sp,sp,48
    80004e6e:	8082                	ret
  return -1;
    80004e70:	557d                	li	a0,-1
    80004e72:	b7fd                	j	80004e60 <pipealloc+0xc6>

0000000080004e74 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e74:	1101                	addi	sp,sp,-32
    80004e76:	ec06                	sd	ra,24(sp)
    80004e78:	e822                	sd	s0,16(sp)
    80004e7a:	e426                	sd	s1,8(sp)
    80004e7c:	e04a                	sd	s2,0(sp)
    80004e7e:	1000                	addi	s0,sp,32
    80004e80:	84aa                	mv	s1,a0
    80004e82:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	d4c080e7          	jalr	-692(ra) # 80000bd0 <acquire>
  if(writable){
    80004e8c:	02090d63          	beqz	s2,80004ec6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e90:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e94:	21848513          	addi	a0,s1,536
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	376080e7          	jalr	886(ra) # 8000220e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ea0:	2204b783          	ld	a5,544(s1)
    80004ea4:	eb95                	bnez	a5,80004ed8 <pipeclose+0x64>
    release(&pi->lock);
    80004ea6:	8526                	mv	a0,s1
    80004ea8:	ffffc097          	auipc	ra,0xffffc
    80004eac:	ddc080e7          	jalr	-548(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004eb0:	8526                	mv	a0,s1
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	b30080e7          	jalr	-1232(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004eba:	60e2                	ld	ra,24(sp)
    80004ebc:	6442                	ld	s0,16(sp)
    80004ebe:	64a2                	ld	s1,8(sp)
    80004ec0:	6902                	ld	s2,0(sp)
    80004ec2:	6105                	addi	sp,sp,32
    80004ec4:	8082                	ret
    pi->readopen = 0;
    80004ec6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004eca:	21c48513          	addi	a0,s1,540
    80004ece:	ffffd097          	auipc	ra,0xffffd
    80004ed2:	340080e7          	jalr	832(ra) # 8000220e <wakeup>
    80004ed6:	b7e9                	j	80004ea0 <pipeclose+0x2c>
    release(&pi->lock);
    80004ed8:	8526                	mv	a0,s1
    80004eda:	ffffc097          	auipc	ra,0xffffc
    80004ede:	daa080e7          	jalr	-598(ra) # 80000c84 <release>
}
    80004ee2:	bfe1                	j	80004eba <pipeclose+0x46>

0000000080004ee4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ee4:	711d                	addi	sp,sp,-96
    80004ee6:	ec86                	sd	ra,88(sp)
    80004ee8:	e8a2                	sd	s0,80(sp)
    80004eea:	e4a6                	sd	s1,72(sp)
    80004eec:	e0ca                	sd	s2,64(sp)
    80004eee:	fc4e                	sd	s3,56(sp)
    80004ef0:	f852                	sd	s4,48(sp)
    80004ef2:	f456                	sd	s5,40(sp)
    80004ef4:	f05a                	sd	s6,32(sp)
    80004ef6:	ec5e                	sd	s7,24(sp)
    80004ef8:	e862                	sd	s8,16(sp)
    80004efa:	1080                	addi	s0,sp,96
    80004efc:	84aa                	mv	s1,a0
    80004efe:	8aae                	mv	s5,a1
    80004f00:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f02:	ffffd097          	auipc	ra,0xffffd
    80004f06:	a94080e7          	jalr	-1388(ra) # 80001996 <myproc>
    80004f0a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f0c:	8526                	mv	a0,s1
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	cc2080e7          	jalr	-830(ra) # 80000bd0 <acquire>
  while(i < n){
    80004f16:	0b405363          	blez	s4,80004fbc <pipewrite+0xd8>
  int i = 0;
    80004f1a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f1c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f1e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f22:	21c48b93          	addi	s7,s1,540
    80004f26:	a089                	j	80004f68 <pipewrite+0x84>
      release(&pi->lock);
    80004f28:	8526                	mv	a0,s1
    80004f2a:	ffffc097          	auipc	ra,0xffffc
    80004f2e:	d5a080e7          	jalr	-678(ra) # 80000c84 <release>
      return -1;
    80004f32:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f34:	854a                	mv	a0,s2
    80004f36:	60e6                	ld	ra,88(sp)
    80004f38:	6446                	ld	s0,80(sp)
    80004f3a:	64a6                	ld	s1,72(sp)
    80004f3c:	6906                	ld	s2,64(sp)
    80004f3e:	79e2                	ld	s3,56(sp)
    80004f40:	7a42                	ld	s4,48(sp)
    80004f42:	7aa2                	ld	s5,40(sp)
    80004f44:	7b02                	ld	s6,32(sp)
    80004f46:	6be2                	ld	s7,24(sp)
    80004f48:	6c42                	ld	s8,16(sp)
    80004f4a:	6125                	addi	sp,sp,96
    80004f4c:	8082                	ret
      wakeup(&pi->nread);
    80004f4e:	8562                	mv	a0,s8
    80004f50:	ffffd097          	auipc	ra,0xffffd
    80004f54:	2be080e7          	jalr	702(ra) # 8000220e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f58:	85a6                	mv	a1,s1
    80004f5a:	855e                	mv	a0,s7
    80004f5c:	ffffd097          	auipc	ra,0xffffd
    80004f60:	126080e7          	jalr	294(ra) # 80002082 <sleep>
  while(i < n){
    80004f64:	05495d63          	bge	s2,s4,80004fbe <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004f68:	2204a783          	lw	a5,544(s1)
    80004f6c:	dfd5                	beqz	a5,80004f28 <pipewrite+0x44>
    80004f6e:	0289a783          	lw	a5,40(s3)
    80004f72:	fbdd                	bnez	a5,80004f28 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f74:	2184a783          	lw	a5,536(s1)
    80004f78:	21c4a703          	lw	a4,540(s1)
    80004f7c:	2007879b          	addiw	a5,a5,512
    80004f80:	fcf707e3          	beq	a4,a5,80004f4e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f84:	4685                	li	a3,1
    80004f86:	01590633          	add	a2,s2,s5
    80004f8a:	faf40593          	addi	a1,s0,-81
    80004f8e:	0509b503          	ld	a0,80(s3)
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	754080e7          	jalr	1876(ra) # 800016e6 <copyin>
    80004f9a:	03650263          	beq	a0,s6,80004fbe <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f9e:	21c4a783          	lw	a5,540(s1)
    80004fa2:	0017871b          	addiw	a4,a5,1
    80004fa6:	20e4ae23          	sw	a4,540(s1)
    80004faa:	1ff7f793          	andi	a5,a5,511
    80004fae:	97a6                	add	a5,a5,s1
    80004fb0:	faf44703          	lbu	a4,-81(s0)
    80004fb4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fb8:	2905                	addiw	s2,s2,1
    80004fba:	b76d                	j	80004f64 <pipewrite+0x80>
  int i = 0;
    80004fbc:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004fbe:	21848513          	addi	a0,s1,536
    80004fc2:	ffffd097          	auipc	ra,0xffffd
    80004fc6:	24c080e7          	jalr	588(ra) # 8000220e <wakeup>
  release(&pi->lock);
    80004fca:	8526                	mv	a0,s1
    80004fcc:	ffffc097          	auipc	ra,0xffffc
    80004fd0:	cb8080e7          	jalr	-840(ra) # 80000c84 <release>
  return i;
    80004fd4:	b785                	j	80004f34 <pipewrite+0x50>

0000000080004fd6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fd6:	715d                	addi	sp,sp,-80
    80004fd8:	e486                	sd	ra,72(sp)
    80004fda:	e0a2                	sd	s0,64(sp)
    80004fdc:	fc26                	sd	s1,56(sp)
    80004fde:	f84a                	sd	s2,48(sp)
    80004fe0:	f44e                	sd	s3,40(sp)
    80004fe2:	f052                	sd	s4,32(sp)
    80004fe4:	ec56                	sd	s5,24(sp)
    80004fe6:	e85a                	sd	s6,16(sp)
    80004fe8:	0880                	addi	s0,sp,80
    80004fea:	84aa                	mv	s1,a0
    80004fec:	892e                	mv	s2,a1
    80004fee:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ff0:	ffffd097          	auipc	ra,0xffffd
    80004ff4:	9a6080e7          	jalr	-1626(ra) # 80001996 <myproc>
    80004ff8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ffa:	8526                	mv	a0,s1
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	bd4080e7          	jalr	-1068(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005004:	2184a703          	lw	a4,536(s1)
    80005008:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000500c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005010:	02f71463          	bne	a4,a5,80005038 <piperead+0x62>
    80005014:	2244a783          	lw	a5,548(s1)
    80005018:	c385                	beqz	a5,80005038 <piperead+0x62>
    if(pr->killed){
    8000501a:	028a2783          	lw	a5,40(s4)
    8000501e:	ebc9                	bnez	a5,800050b0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005020:	85a6                	mv	a1,s1
    80005022:	854e                	mv	a0,s3
    80005024:	ffffd097          	auipc	ra,0xffffd
    80005028:	05e080e7          	jalr	94(ra) # 80002082 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000502c:	2184a703          	lw	a4,536(s1)
    80005030:	21c4a783          	lw	a5,540(s1)
    80005034:	fef700e3          	beq	a4,a5,80005014 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005038:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000503a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000503c:	05505463          	blez	s5,80005084 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80005040:	2184a783          	lw	a5,536(s1)
    80005044:	21c4a703          	lw	a4,540(s1)
    80005048:	02f70e63          	beq	a4,a5,80005084 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000504c:	0017871b          	addiw	a4,a5,1
    80005050:	20e4ac23          	sw	a4,536(s1)
    80005054:	1ff7f793          	andi	a5,a5,511
    80005058:	97a6                	add	a5,a5,s1
    8000505a:	0187c783          	lbu	a5,24(a5)
    8000505e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005062:	4685                	li	a3,1
    80005064:	fbf40613          	addi	a2,s0,-65
    80005068:	85ca                	mv	a1,s2
    8000506a:	050a3503          	ld	a0,80(s4)
    8000506e:	ffffc097          	auipc	ra,0xffffc
    80005072:	5ec080e7          	jalr	1516(ra) # 8000165a <copyout>
    80005076:	01650763          	beq	a0,s6,80005084 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000507a:	2985                	addiw	s3,s3,1
    8000507c:	0905                	addi	s2,s2,1
    8000507e:	fd3a91e3          	bne	s5,s3,80005040 <piperead+0x6a>
    80005082:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005084:	21c48513          	addi	a0,s1,540
    80005088:	ffffd097          	auipc	ra,0xffffd
    8000508c:	186080e7          	jalr	390(ra) # 8000220e <wakeup>
  release(&pi->lock);
    80005090:	8526                	mv	a0,s1
    80005092:	ffffc097          	auipc	ra,0xffffc
    80005096:	bf2080e7          	jalr	-1038(ra) # 80000c84 <release>
  return i;
}
    8000509a:	854e                	mv	a0,s3
    8000509c:	60a6                	ld	ra,72(sp)
    8000509e:	6406                	ld	s0,64(sp)
    800050a0:	74e2                	ld	s1,56(sp)
    800050a2:	7942                	ld	s2,48(sp)
    800050a4:	79a2                	ld	s3,40(sp)
    800050a6:	7a02                	ld	s4,32(sp)
    800050a8:	6ae2                	ld	s5,24(sp)
    800050aa:	6b42                	ld	s6,16(sp)
    800050ac:	6161                	addi	sp,sp,80
    800050ae:	8082                	ret
      release(&pi->lock);
    800050b0:	8526                	mv	a0,s1
    800050b2:	ffffc097          	auipc	ra,0xffffc
    800050b6:	bd2080e7          	jalr	-1070(ra) # 80000c84 <release>
      return -1;
    800050ba:	59fd                	li	s3,-1
    800050bc:	bff9                	j	8000509a <piperead+0xc4>

00000000800050be <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800050be:	de010113          	addi	sp,sp,-544
    800050c2:	20113c23          	sd	ra,536(sp)
    800050c6:	20813823          	sd	s0,528(sp)
    800050ca:	20913423          	sd	s1,520(sp)
    800050ce:	21213023          	sd	s2,512(sp)
    800050d2:	ffce                	sd	s3,504(sp)
    800050d4:	fbd2                	sd	s4,496(sp)
    800050d6:	f7d6                	sd	s5,488(sp)
    800050d8:	f3da                	sd	s6,480(sp)
    800050da:	efde                	sd	s7,472(sp)
    800050dc:	ebe2                	sd	s8,464(sp)
    800050de:	e7e6                	sd	s9,456(sp)
    800050e0:	e3ea                	sd	s10,448(sp)
    800050e2:	ff6e                	sd	s11,440(sp)
    800050e4:	1400                	addi	s0,sp,544
    800050e6:	892a                	mv	s2,a0
    800050e8:	dea43423          	sd	a0,-536(s0)
    800050ec:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050f0:	ffffd097          	auipc	ra,0xffffd
    800050f4:	8a6080e7          	jalr	-1882(ra) # 80001996 <myproc>
    800050f8:	84aa                	mv	s1,a0

  begin_op();
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	4a8080e7          	jalr	1192(ra) # 800045a2 <begin_op>

  if((ip = namei(path)) == 0){
    80005102:	854a                	mv	a0,s2
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	27e080e7          	jalr	638(ra) # 80004382 <namei>
    8000510c:	c93d                	beqz	a0,80005182 <exec+0xc4>
    8000510e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	ab6080e7          	jalr	-1354(ra) # 80003bc6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005118:	04000713          	li	a4,64
    8000511c:	4681                	li	a3,0
    8000511e:	e5040613          	addi	a2,s0,-432
    80005122:	4581                	li	a1,0
    80005124:	8556                	mv	a0,s5
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	d54080e7          	jalr	-684(ra) # 80003e7a <readi>
    8000512e:	04000793          	li	a5,64
    80005132:	00f51a63          	bne	a0,a5,80005146 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005136:	e5042703          	lw	a4,-432(s0)
    8000513a:	464c47b7          	lui	a5,0x464c4
    8000513e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005142:	04f70663          	beq	a4,a5,8000518e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005146:	8556                	mv	a0,s5
    80005148:	fffff097          	auipc	ra,0xfffff
    8000514c:	ce0080e7          	jalr	-800(ra) # 80003e28 <iunlockput>
    end_op();
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	4d0080e7          	jalr	1232(ra) # 80004620 <end_op>
  }
  return -1;
    80005158:	557d                	li	a0,-1
}
    8000515a:	21813083          	ld	ra,536(sp)
    8000515e:	21013403          	ld	s0,528(sp)
    80005162:	20813483          	ld	s1,520(sp)
    80005166:	20013903          	ld	s2,512(sp)
    8000516a:	79fe                	ld	s3,504(sp)
    8000516c:	7a5e                	ld	s4,496(sp)
    8000516e:	7abe                	ld	s5,488(sp)
    80005170:	7b1e                	ld	s6,480(sp)
    80005172:	6bfe                	ld	s7,472(sp)
    80005174:	6c5e                	ld	s8,464(sp)
    80005176:	6cbe                	ld	s9,456(sp)
    80005178:	6d1e                	ld	s10,448(sp)
    8000517a:	7dfa                	ld	s11,440(sp)
    8000517c:	22010113          	addi	sp,sp,544
    80005180:	8082                	ret
    end_op();
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	49e080e7          	jalr	1182(ra) # 80004620 <end_op>
    return -1;
    8000518a:	557d                	li	a0,-1
    8000518c:	b7f9                	j	8000515a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000518e:	8526                	mv	a0,s1
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	8e6080e7          	jalr	-1818(ra) # 80001a76 <proc_pagetable>
    80005198:	8b2a                	mv	s6,a0
    8000519a:	d555                	beqz	a0,80005146 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000519c:	e7042783          	lw	a5,-400(s0)
    800051a0:	e8845703          	lhu	a4,-376(s0)
    800051a4:	c735                	beqz	a4,80005210 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051a6:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051a8:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    800051ac:	6a05                	lui	s4,0x1
    800051ae:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800051b2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800051b6:	6d85                	lui	s11,0x1
    800051b8:	7d7d                	lui	s10,0xfffff
    800051ba:	ac1d                	j	800053f0 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051bc:	00003517          	auipc	a0,0x3
    800051c0:	5f450513          	addi	a0,a0,1524 # 800087b0 <syscalls+0x2b8>
    800051c4:	ffffb097          	auipc	ra,0xffffb
    800051c8:	376080e7          	jalr	886(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051cc:	874a                	mv	a4,s2
    800051ce:	009c86bb          	addw	a3,s9,s1
    800051d2:	4581                	li	a1,0
    800051d4:	8556                	mv	a0,s5
    800051d6:	fffff097          	auipc	ra,0xfffff
    800051da:	ca4080e7          	jalr	-860(ra) # 80003e7a <readi>
    800051de:	2501                	sext.w	a0,a0
    800051e0:	1aa91863          	bne	s2,a0,80005390 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    800051e4:	009d84bb          	addw	s1,s11,s1
    800051e8:	013d09bb          	addw	s3,s10,s3
    800051ec:	1f74f263          	bgeu	s1,s7,800053d0 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    800051f0:	02049593          	slli	a1,s1,0x20
    800051f4:	9181                	srli	a1,a1,0x20
    800051f6:	95e2                	add	a1,a1,s8
    800051f8:	855a                	mv	a0,s6
    800051fa:	ffffc097          	auipc	ra,0xffffc
    800051fe:	e58080e7          	jalr	-424(ra) # 80001052 <walkaddr>
    80005202:	862a                	mv	a2,a0
    if(pa == 0)
    80005204:	dd45                	beqz	a0,800051bc <exec+0xfe>
      n = PGSIZE;
    80005206:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005208:	fd49f2e3          	bgeu	s3,s4,800051cc <exec+0x10e>
      n = sz - i;
    8000520c:	894e                	mv	s2,s3
    8000520e:	bf7d                	j	800051cc <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005210:	4481                	li	s1,0
  iunlockput(ip);
    80005212:	8556                	mv	a0,s5
    80005214:	fffff097          	auipc	ra,0xfffff
    80005218:	c14080e7          	jalr	-1004(ra) # 80003e28 <iunlockput>
  end_op();
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	404080e7          	jalr	1028(ra) # 80004620 <end_op>
  p = myproc();
    80005224:	ffffc097          	auipc	ra,0xffffc
    80005228:	772080e7          	jalr	1906(ra) # 80001996 <myproc>
    8000522c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000522e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005232:	6785                	lui	a5,0x1
    80005234:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005236:	97a6                	add	a5,a5,s1
    80005238:	777d                	lui	a4,0xfffff
    8000523a:	8ff9                	and	a5,a5,a4
    8000523c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005240:	6609                	lui	a2,0x2
    80005242:	963e                	add	a2,a2,a5
    80005244:	85be                	mv	a1,a5
    80005246:	855a                	mv	a0,s6
    80005248:	ffffc097          	auipc	ra,0xffffc
    8000524c:	1be080e7          	jalr	446(ra) # 80001406 <uvmalloc>
    80005250:	8c2a                	mv	s8,a0
  ip = 0;
    80005252:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005254:	12050e63          	beqz	a0,80005390 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005258:	75f9                	lui	a1,0xffffe
    8000525a:	95aa                	add	a1,a1,a0
    8000525c:	855a                	mv	a0,s6
    8000525e:	ffffc097          	auipc	ra,0xffffc
    80005262:	3ca080e7          	jalr	970(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80005266:	7afd                	lui	s5,0xfffff
    80005268:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000526a:	df043783          	ld	a5,-528(s0)
    8000526e:	6388                	ld	a0,0(a5)
    80005270:	c925                	beqz	a0,800052e0 <exec+0x222>
    80005272:	e9040993          	addi	s3,s0,-368
    80005276:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000527a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000527c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	bca080e7          	jalr	-1078(ra) # 80000e48 <strlen>
    80005286:	0015079b          	addiw	a5,a0,1
    8000528a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000528e:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005292:	13596363          	bltu	s2,s5,800053b8 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005296:	df043d83          	ld	s11,-528(s0)
    8000529a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000529e:	8552                	mv	a0,s4
    800052a0:	ffffc097          	auipc	ra,0xffffc
    800052a4:	ba8080e7          	jalr	-1112(ra) # 80000e48 <strlen>
    800052a8:	0015069b          	addiw	a3,a0,1
    800052ac:	8652                	mv	a2,s4
    800052ae:	85ca                	mv	a1,s2
    800052b0:	855a                	mv	a0,s6
    800052b2:	ffffc097          	auipc	ra,0xffffc
    800052b6:	3a8080e7          	jalr	936(ra) # 8000165a <copyout>
    800052ba:	10054363          	bltz	a0,800053c0 <exec+0x302>
    ustack[argc] = sp;
    800052be:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052c2:	0485                	addi	s1,s1,1
    800052c4:	008d8793          	addi	a5,s11,8
    800052c8:	def43823          	sd	a5,-528(s0)
    800052cc:	008db503          	ld	a0,8(s11)
    800052d0:	c911                	beqz	a0,800052e4 <exec+0x226>
    if(argc >= MAXARG)
    800052d2:	09a1                	addi	s3,s3,8
    800052d4:	fb3c95e3          	bne	s9,s3,8000527e <exec+0x1c0>
  sz = sz1;
    800052d8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052dc:	4a81                	li	s5,0
    800052de:	a84d                	j	80005390 <exec+0x2d2>
  sp = sz;
    800052e0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800052e2:	4481                	li	s1,0
  ustack[argc] = 0;
    800052e4:	00349793          	slli	a5,s1,0x3
    800052e8:	f9078793          	addi	a5,a5,-112
    800052ec:	97a2                	add	a5,a5,s0
    800052ee:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800052f2:	00148693          	addi	a3,s1,1
    800052f6:	068e                	slli	a3,a3,0x3
    800052f8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052fc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005300:	01597663          	bgeu	s2,s5,8000530c <exec+0x24e>
  sz = sz1;
    80005304:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005308:	4a81                	li	s5,0
    8000530a:	a059                	j	80005390 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000530c:	e9040613          	addi	a2,s0,-368
    80005310:	85ca                	mv	a1,s2
    80005312:	855a                	mv	a0,s6
    80005314:	ffffc097          	auipc	ra,0xffffc
    80005318:	346080e7          	jalr	838(ra) # 8000165a <copyout>
    8000531c:	0a054663          	bltz	a0,800053c8 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005320:	058bb783          	ld	a5,88(s7)
    80005324:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005328:	de843783          	ld	a5,-536(s0)
    8000532c:	0007c703          	lbu	a4,0(a5)
    80005330:	cf11                	beqz	a4,8000534c <exec+0x28e>
    80005332:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005334:	02f00693          	li	a3,47
    80005338:	a039                	j	80005346 <exec+0x288>
      last = s+1;
    8000533a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000533e:	0785                	addi	a5,a5,1
    80005340:	fff7c703          	lbu	a4,-1(a5)
    80005344:	c701                	beqz	a4,8000534c <exec+0x28e>
    if(*s == '/')
    80005346:	fed71ce3          	bne	a4,a3,8000533e <exec+0x280>
    8000534a:	bfc5                	j	8000533a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000534c:	4641                	li	a2,16
    8000534e:	de843583          	ld	a1,-536(s0)
    80005352:	158b8513          	addi	a0,s7,344
    80005356:	ffffc097          	auipc	ra,0xffffc
    8000535a:	ac0080e7          	jalr	-1344(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    8000535e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005362:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005366:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000536a:	058bb783          	ld	a5,88(s7)
    8000536e:	e6843703          	ld	a4,-408(s0)
    80005372:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005374:	058bb783          	ld	a5,88(s7)
    80005378:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000537c:	85ea                	mv	a1,s10
    8000537e:	ffffc097          	auipc	ra,0xffffc
    80005382:	794080e7          	jalr	1940(ra) # 80001b12 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005386:	0004851b          	sext.w	a0,s1
    8000538a:	bbc1                	j	8000515a <exec+0x9c>
    8000538c:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005390:	df843583          	ld	a1,-520(s0)
    80005394:	855a                	mv	a0,s6
    80005396:	ffffc097          	auipc	ra,0xffffc
    8000539a:	77c080e7          	jalr	1916(ra) # 80001b12 <proc_freepagetable>
  if(ip){
    8000539e:	da0a94e3          	bnez	s5,80005146 <exec+0x88>
  return -1;
    800053a2:	557d                	li	a0,-1
    800053a4:	bb5d                	j	8000515a <exec+0x9c>
    800053a6:	de943c23          	sd	s1,-520(s0)
    800053aa:	b7dd                	j	80005390 <exec+0x2d2>
    800053ac:	de943c23          	sd	s1,-520(s0)
    800053b0:	b7c5                	j	80005390 <exec+0x2d2>
    800053b2:	de943c23          	sd	s1,-520(s0)
    800053b6:	bfe9                	j	80005390 <exec+0x2d2>
  sz = sz1;
    800053b8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053bc:	4a81                	li	s5,0
    800053be:	bfc9                	j	80005390 <exec+0x2d2>
  sz = sz1;
    800053c0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053c4:	4a81                	li	s5,0
    800053c6:	b7e9                	j	80005390 <exec+0x2d2>
  sz = sz1;
    800053c8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053cc:	4a81                	li	s5,0
    800053ce:	b7c9                	j	80005390 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053d0:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053d4:	e0843783          	ld	a5,-504(s0)
    800053d8:	0017869b          	addiw	a3,a5,1
    800053dc:	e0d43423          	sd	a3,-504(s0)
    800053e0:	e0043783          	ld	a5,-512(s0)
    800053e4:	0387879b          	addiw	a5,a5,56
    800053e8:	e8845703          	lhu	a4,-376(s0)
    800053ec:	e2e6d3e3          	bge	a3,a4,80005212 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053f0:	2781                	sext.w	a5,a5
    800053f2:	e0f43023          	sd	a5,-512(s0)
    800053f6:	03800713          	li	a4,56
    800053fa:	86be                	mv	a3,a5
    800053fc:	e1840613          	addi	a2,s0,-488
    80005400:	4581                	li	a1,0
    80005402:	8556                	mv	a0,s5
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	a76080e7          	jalr	-1418(ra) # 80003e7a <readi>
    8000540c:	03800793          	li	a5,56
    80005410:	f6f51ee3          	bne	a0,a5,8000538c <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005414:	e1842783          	lw	a5,-488(s0)
    80005418:	4705                	li	a4,1
    8000541a:	fae79de3          	bne	a5,a4,800053d4 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000541e:	e4043603          	ld	a2,-448(s0)
    80005422:	e3843783          	ld	a5,-456(s0)
    80005426:	f8f660e3          	bltu	a2,a5,800053a6 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000542a:	e2843783          	ld	a5,-472(s0)
    8000542e:	963e                	add	a2,a2,a5
    80005430:	f6f66ee3          	bltu	a2,a5,800053ac <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005434:	85a6                	mv	a1,s1
    80005436:	855a                	mv	a0,s6
    80005438:	ffffc097          	auipc	ra,0xffffc
    8000543c:	fce080e7          	jalr	-50(ra) # 80001406 <uvmalloc>
    80005440:	dea43c23          	sd	a0,-520(s0)
    80005444:	d53d                	beqz	a0,800053b2 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80005446:	e2843c03          	ld	s8,-472(s0)
    8000544a:	de043783          	ld	a5,-544(s0)
    8000544e:	00fc77b3          	and	a5,s8,a5
    80005452:	ff9d                	bnez	a5,80005390 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005454:	e2042c83          	lw	s9,-480(s0)
    80005458:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000545c:	f60b8ae3          	beqz	s7,800053d0 <exec+0x312>
    80005460:	89de                	mv	s3,s7
    80005462:	4481                	li	s1,0
    80005464:	b371                	j	800051f0 <exec+0x132>

0000000080005466 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005466:	7179                	addi	sp,sp,-48
    80005468:	f406                	sd	ra,40(sp)
    8000546a:	f022                	sd	s0,32(sp)
    8000546c:	ec26                	sd	s1,24(sp)
    8000546e:	e84a                	sd	s2,16(sp)
    80005470:	1800                	addi	s0,sp,48
    80005472:	892e                	mv	s2,a1
    80005474:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005476:	fdc40593          	addi	a1,s0,-36
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	a46080e7          	jalr	-1466(ra) # 80002ec0 <argint>
    80005482:	04054063          	bltz	a0,800054c2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005486:	fdc42703          	lw	a4,-36(s0)
    8000548a:	47bd                	li	a5,15
    8000548c:	02e7ed63          	bltu	a5,a4,800054c6 <argfd+0x60>
    80005490:	ffffc097          	auipc	ra,0xffffc
    80005494:	506080e7          	jalr	1286(ra) # 80001996 <myproc>
    80005498:	fdc42703          	lw	a4,-36(s0)
    8000549c:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    800054a0:	078e                	slli	a5,a5,0x3
    800054a2:	953e                	add	a0,a0,a5
    800054a4:	611c                	ld	a5,0(a0)
    800054a6:	c395                	beqz	a5,800054ca <argfd+0x64>
    return -1;
  if(pfd)
    800054a8:	00090463          	beqz	s2,800054b0 <argfd+0x4a>
    *pfd = fd;
    800054ac:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054b0:	4501                	li	a0,0
  if(pf)
    800054b2:	c091                	beqz	s1,800054b6 <argfd+0x50>
    *pf = f;
    800054b4:	e09c                	sd	a5,0(s1)
}
    800054b6:	70a2                	ld	ra,40(sp)
    800054b8:	7402                	ld	s0,32(sp)
    800054ba:	64e2                	ld	s1,24(sp)
    800054bc:	6942                	ld	s2,16(sp)
    800054be:	6145                	addi	sp,sp,48
    800054c0:	8082                	ret
    return -1;
    800054c2:	557d                	li	a0,-1
    800054c4:	bfcd                	j	800054b6 <argfd+0x50>
    return -1;
    800054c6:	557d                	li	a0,-1
    800054c8:	b7fd                	j	800054b6 <argfd+0x50>
    800054ca:	557d                	li	a0,-1
    800054cc:	b7ed                	j	800054b6 <argfd+0x50>

00000000800054ce <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054ce:	1101                	addi	sp,sp,-32
    800054d0:	ec06                	sd	ra,24(sp)
    800054d2:	e822                	sd	s0,16(sp)
    800054d4:	e426                	sd	s1,8(sp)
    800054d6:	1000                	addi	s0,sp,32
    800054d8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054da:	ffffc097          	auipc	ra,0xffffc
    800054de:	4bc080e7          	jalr	1212(ra) # 80001996 <myproc>
    800054e2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054e4:	0d050793          	addi	a5,a0,208
    800054e8:	4501                	li	a0,0
    800054ea:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054ec:	6398                	ld	a4,0(a5)
    800054ee:	cb19                	beqz	a4,80005504 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054f0:	2505                	addiw	a0,a0,1
    800054f2:	07a1                	addi	a5,a5,8
    800054f4:	fed51ce3          	bne	a0,a3,800054ec <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054f8:	557d                	li	a0,-1
}
    800054fa:	60e2                	ld	ra,24(sp)
    800054fc:	6442                	ld	s0,16(sp)
    800054fe:	64a2                	ld	s1,8(sp)
    80005500:	6105                	addi	sp,sp,32
    80005502:	8082                	ret
      p->ofile[fd] = f;
    80005504:	01a50793          	addi	a5,a0,26
    80005508:	078e                	slli	a5,a5,0x3
    8000550a:	963e                	add	a2,a2,a5
    8000550c:	e204                	sd	s1,0(a2)
      return fd;
    8000550e:	b7f5                	j	800054fa <fdalloc+0x2c>

0000000080005510 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005510:	715d                	addi	sp,sp,-80
    80005512:	e486                	sd	ra,72(sp)
    80005514:	e0a2                	sd	s0,64(sp)
    80005516:	fc26                	sd	s1,56(sp)
    80005518:	f84a                	sd	s2,48(sp)
    8000551a:	f44e                	sd	s3,40(sp)
    8000551c:	f052                	sd	s4,32(sp)
    8000551e:	ec56                	sd	s5,24(sp)
    80005520:	0880                	addi	s0,sp,80
    80005522:	89ae                	mv	s3,a1
    80005524:	8ab2                	mv	s5,a2
    80005526:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005528:	fb040593          	addi	a1,s0,-80
    8000552c:	fffff097          	auipc	ra,0xfffff
    80005530:	e74080e7          	jalr	-396(ra) # 800043a0 <nameiparent>
    80005534:	892a                	mv	s2,a0
    80005536:	12050e63          	beqz	a0,80005672 <create+0x162>
    return 0;

  ilock(dp);
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	68c080e7          	jalr	1676(ra) # 80003bc6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005542:	4601                	li	a2,0
    80005544:	fb040593          	addi	a1,s0,-80
    80005548:	854a                	mv	a0,s2
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	b60080e7          	jalr	-1184(ra) # 800040aa <dirlookup>
    80005552:	84aa                	mv	s1,a0
    80005554:	c921                	beqz	a0,800055a4 <create+0x94>
    iunlockput(dp);
    80005556:	854a                	mv	a0,s2
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	8d0080e7          	jalr	-1840(ra) # 80003e28 <iunlockput>
    ilock(ip);
    80005560:	8526                	mv	a0,s1
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	664080e7          	jalr	1636(ra) # 80003bc6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000556a:	2981                	sext.w	s3,s3
    8000556c:	4789                	li	a5,2
    8000556e:	02f99463          	bne	s3,a5,80005596 <create+0x86>
    80005572:	0444d783          	lhu	a5,68(s1)
    80005576:	37f9                	addiw	a5,a5,-2
    80005578:	17c2                	slli	a5,a5,0x30
    8000557a:	93c1                	srli	a5,a5,0x30
    8000557c:	4705                	li	a4,1
    8000557e:	00f76c63          	bltu	a4,a5,80005596 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005582:	8526                	mv	a0,s1
    80005584:	60a6                	ld	ra,72(sp)
    80005586:	6406                	ld	s0,64(sp)
    80005588:	74e2                	ld	s1,56(sp)
    8000558a:	7942                	ld	s2,48(sp)
    8000558c:	79a2                	ld	s3,40(sp)
    8000558e:	7a02                	ld	s4,32(sp)
    80005590:	6ae2                	ld	s5,24(sp)
    80005592:	6161                	addi	sp,sp,80
    80005594:	8082                	ret
    iunlockput(ip);
    80005596:	8526                	mv	a0,s1
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	890080e7          	jalr	-1904(ra) # 80003e28 <iunlockput>
    return 0;
    800055a0:	4481                	li	s1,0
    800055a2:	b7c5                	j	80005582 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055a4:	85ce                	mv	a1,s3
    800055a6:	00092503          	lw	a0,0(s2)
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	482080e7          	jalr	1154(ra) # 80003a2c <ialloc>
    800055b2:	84aa                	mv	s1,a0
    800055b4:	c521                	beqz	a0,800055fc <create+0xec>
  ilock(ip);
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	610080e7          	jalr	1552(ra) # 80003bc6 <ilock>
  ip->major = major;
    800055be:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800055c2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800055c6:	4a05                	li	s4,1
    800055c8:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800055cc:	8526                	mv	a0,s1
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	52c080e7          	jalr	1324(ra) # 80003afa <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055d6:	2981                	sext.w	s3,s3
    800055d8:	03498a63          	beq	s3,s4,8000560c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800055dc:	40d0                	lw	a2,4(s1)
    800055de:	fb040593          	addi	a1,s0,-80
    800055e2:	854a                	mv	a0,s2
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	cdc080e7          	jalr	-804(ra) # 800042c0 <dirlink>
    800055ec:	06054b63          	bltz	a0,80005662 <create+0x152>
  iunlockput(dp);
    800055f0:	854a                	mv	a0,s2
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	836080e7          	jalr	-1994(ra) # 80003e28 <iunlockput>
  return ip;
    800055fa:	b761                	j	80005582 <create+0x72>
    panic("create: ialloc");
    800055fc:	00003517          	auipc	a0,0x3
    80005600:	1d450513          	addi	a0,a0,468 # 800087d0 <syscalls+0x2d8>
    80005604:	ffffb097          	auipc	ra,0xffffb
    80005608:	f36080e7          	jalr	-202(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    8000560c:	04a95783          	lhu	a5,74(s2)
    80005610:	2785                	addiw	a5,a5,1
    80005612:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005616:	854a                	mv	a0,s2
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	4e2080e7          	jalr	1250(ra) # 80003afa <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005620:	40d0                	lw	a2,4(s1)
    80005622:	00003597          	auipc	a1,0x3
    80005626:	1be58593          	addi	a1,a1,446 # 800087e0 <syscalls+0x2e8>
    8000562a:	8526                	mv	a0,s1
    8000562c:	fffff097          	auipc	ra,0xfffff
    80005630:	c94080e7          	jalr	-876(ra) # 800042c0 <dirlink>
    80005634:	00054f63          	bltz	a0,80005652 <create+0x142>
    80005638:	00492603          	lw	a2,4(s2)
    8000563c:	00003597          	auipc	a1,0x3
    80005640:	1ac58593          	addi	a1,a1,428 # 800087e8 <syscalls+0x2f0>
    80005644:	8526                	mv	a0,s1
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	c7a080e7          	jalr	-902(ra) # 800042c0 <dirlink>
    8000564e:	f80557e3          	bgez	a0,800055dc <create+0xcc>
      panic("create dots");
    80005652:	00003517          	auipc	a0,0x3
    80005656:	19e50513          	addi	a0,a0,414 # 800087f0 <syscalls+0x2f8>
    8000565a:	ffffb097          	auipc	ra,0xffffb
    8000565e:	ee0080e7          	jalr	-288(ra) # 8000053a <panic>
    panic("create: dirlink");
    80005662:	00003517          	auipc	a0,0x3
    80005666:	19e50513          	addi	a0,a0,414 # 80008800 <syscalls+0x308>
    8000566a:	ffffb097          	auipc	ra,0xffffb
    8000566e:	ed0080e7          	jalr	-304(ra) # 8000053a <panic>
    return 0;
    80005672:	84aa                	mv	s1,a0
    80005674:	b739                	j	80005582 <create+0x72>

0000000080005676 <sys_dup>:
{
    80005676:	7179                	addi	sp,sp,-48
    80005678:	f406                	sd	ra,40(sp)
    8000567a:	f022                	sd	s0,32(sp)
    8000567c:	ec26                	sd	s1,24(sp)
    8000567e:	e84a                	sd	s2,16(sp)
    80005680:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005682:	fd840613          	addi	a2,s0,-40
    80005686:	4581                	li	a1,0
    80005688:	4501                	li	a0,0
    8000568a:	00000097          	auipc	ra,0x0
    8000568e:	ddc080e7          	jalr	-548(ra) # 80005466 <argfd>
    return -1;
    80005692:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005694:	02054363          	bltz	a0,800056ba <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005698:	fd843903          	ld	s2,-40(s0)
    8000569c:	854a                	mv	a0,s2
    8000569e:	00000097          	auipc	ra,0x0
    800056a2:	e30080e7          	jalr	-464(ra) # 800054ce <fdalloc>
    800056a6:	84aa                	mv	s1,a0
    return -1;
    800056a8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056aa:	00054863          	bltz	a0,800056ba <sys_dup+0x44>
  filedup(f);
    800056ae:	854a                	mv	a0,s2
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	368080e7          	jalr	872(ra) # 80004a18 <filedup>
  return fd;
    800056b8:	87a6                	mv	a5,s1
}
    800056ba:	853e                	mv	a0,a5
    800056bc:	70a2                	ld	ra,40(sp)
    800056be:	7402                	ld	s0,32(sp)
    800056c0:	64e2                	ld	s1,24(sp)
    800056c2:	6942                	ld	s2,16(sp)
    800056c4:	6145                	addi	sp,sp,48
    800056c6:	8082                	ret

00000000800056c8 <sys_read>:
{
    800056c8:	7179                	addi	sp,sp,-48
    800056ca:	f406                	sd	ra,40(sp)
    800056cc:	f022                	sd	s0,32(sp)
    800056ce:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056d0:	fe840613          	addi	a2,s0,-24
    800056d4:	4581                	li	a1,0
    800056d6:	4501                	li	a0,0
    800056d8:	00000097          	auipc	ra,0x0
    800056dc:	d8e080e7          	jalr	-626(ra) # 80005466 <argfd>
    return -1;
    800056e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e2:	04054163          	bltz	a0,80005724 <sys_read+0x5c>
    800056e6:	fe440593          	addi	a1,s0,-28
    800056ea:	4509                	li	a0,2
    800056ec:	ffffd097          	auipc	ra,0xffffd
    800056f0:	7d4080e7          	jalr	2004(ra) # 80002ec0 <argint>
    return -1;
    800056f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f6:	02054763          	bltz	a0,80005724 <sys_read+0x5c>
    800056fa:	fd840593          	addi	a1,s0,-40
    800056fe:	4505                	li	a0,1
    80005700:	ffffd097          	auipc	ra,0xffffd
    80005704:	7e2080e7          	jalr	2018(ra) # 80002ee2 <argaddr>
    return -1;
    80005708:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000570a:	00054d63          	bltz	a0,80005724 <sys_read+0x5c>
  return fileread(f, p, n);
    8000570e:	fe442603          	lw	a2,-28(s0)
    80005712:	fd843583          	ld	a1,-40(s0)
    80005716:	fe843503          	ld	a0,-24(s0)
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	48a080e7          	jalr	1162(ra) # 80004ba4 <fileread>
    80005722:	87aa                	mv	a5,a0
}
    80005724:	853e                	mv	a0,a5
    80005726:	70a2                	ld	ra,40(sp)
    80005728:	7402                	ld	s0,32(sp)
    8000572a:	6145                	addi	sp,sp,48
    8000572c:	8082                	ret

000000008000572e <sys_write>:
{
    8000572e:	7179                	addi	sp,sp,-48
    80005730:	f406                	sd	ra,40(sp)
    80005732:	f022                	sd	s0,32(sp)
    80005734:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005736:	fe840613          	addi	a2,s0,-24
    8000573a:	4581                	li	a1,0
    8000573c:	4501                	li	a0,0
    8000573e:	00000097          	auipc	ra,0x0
    80005742:	d28080e7          	jalr	-728(ra) # 80005466 <argfd>
    return -1;
    80005746:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005748:	04054163          	bltz	a0,8000578a <sys_write+0x5c>
    8000574c:	fe440593          	addi	a1,s0,-28
    80005750:	4509                	li	a0,2
    80005752:	ffffd097          	auipc	ra,0xffffd
    80005756:	76e080e7          	jalr	1902(ra) # 80002ec0 <argint>
    return -1;
    8000575a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000575c:	02054763          	bltz	a0,8000578a <sys_write+0x5c>
    80005760:	fd840593          	addi	a1,s0,-40
    80005764:	4505                	li	a0,1
    80005766:	ffffd097          	auipc	ra,0xffffd
    8000576a:	77c080e7          	jalr	1916(ra) # 80002ee2 <argaddr>
    return -1;
    8000576e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005770:	00054d63          	bltz	a0,8000578a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005774:	fe442603          	lw	a2,-28(s0)
    80005778:	fd843583          	ld	a1,-40(s0)
    8000577c:	fe843503          	ld	a0,-24(s0)
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	4e6080e7          	jalr	1254(ra) # 80004c66 <filewrite>
    80005788:	87aa                	mv	a5,a0
}
    8000578a:	853e                	mv	a0,a5
    8000578c:	70a2                	ld	ra,40(sp)
    8000578e:	7402                	ld	s0,32(sp)
    80005790:	6145                	addi	sp,sp,48
    80005792:	8082                	ret

0000000080005794 <sys_close>:
{
    80005794:	1101                	addi	sp,sp,-32
    80005796:	ec06                	sd	ra,24(sp)
    80005798:	e822                	sd	s0,16(sp)
    8000579a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000579c:	fe040613          	addi	a2,s0,-32
    800057a0:	fec40593          	addi	a1,s0,-20
    800057a4:	4501                	li	a0,0
    800057a6:	00000097          	auipc	ra,0x0
    800057aa:	cc0080e7          	jalr	-832(ra) # 80005466 <argfd>
    return -1;
    800057ae:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057b0:	02054463          	bltz	a0,800057d8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057b4:	ffffc097          	auipc	ra,0xffffc
    800057b8:	1e2080e7          	jalr	482(ra) # 80001996 <myproc>
    800057bc:	fec42783          	lw	a5,-20(s0)
    800057c0:	07e9                	addi	a5,a5,26
    800057c2:	078e                	slli	a5,a5,0x3
    800057c4:	953e                	add	a0,a0,a5
    800057c6:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800057ca:	fe043503          	ld	a0,-32(s0)
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	29c080e7          	jalr	668(ra) # 80004a6a <fileclose>
  return 0;
    800057d6:	4781                	li	a5,0
}
    800057d8:	853e                	mv	a0,a5
    800057da:	60e2                	ld	ra,24(sp)
    800057dc:	6442                	ld	s0,16(sp)
    800057de:	6105                	addi	sp,sp,32
    800057e0:	8082                	ret

00000000800057e2 <sys_fstat>:
{
    800057e2:	1101                	addi	sp,sp,-32
    800057e4:	ec06                	sd	ra,24(sp)
    800057e6:	e822                	sd	s0,16(sp)
    800057e8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057ea:	fe840613          	addi	a2,s0,-24
    800057ee:	4581                	li	a1,0
    800057f0:	4501                	li	a0,0
    800057f2:	00000097          	auipc	ra,0x0
    800057f6:	c74080e7          	jalr	-908(ra) # 80005466 <argfd>
    return -1;
    800057fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057fc:	02054563          	bltz	a0,80005826 <sys_fstat+0x44>
    80005800:	fe040593          	addi	a1,s0,-32
    80005804:	4505                	li	a0,1
    80005806:	ffffd097          	auipc	ra,0xffffd
    8000580a:	6dc080e7          	jalr	1756(ra) # 80002ee2 <argaddr>
    return -1;
    8000580e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005810:	00054b63          	bltz	a0,80005826 <sys_fstat+0x44>
  return filestat(f, st);
    80005814:	fe043583          	ld	a1,-32(s0)
    80005818:	fe843503          	ld	a0,-24(s0)
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	316080e7          	jalr	790(ra) # 80004b32 <filestat>
    80005824:	87aa                	mv	a5,a0
}
    80005826:	853e                	mv	a0,a5
    80005828:	60e2                	ld	ra,24(sp)
    8000582a:	6442                	ld	s0,16(sp)
    8000582c:	6105                	addi	sp,sp,32
    8000582e:	8082                	ret

0000000080005830 <sys_link>:
{
    80005830:	7169                	addi	sp,sp,-304
    80005832:	f606                	sd	ra,296(sp)
    80005834:	f222                	sd	s0,288(sp)
    80005836:	ee26                	sd	s1,280(sp)
    80005838:	ea4a                	sd	s2,272(sp)
    8000583a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000583c:	08000613          	li	a2,128
    80005840:	ed040593          	addi	a1,s0,-304
    80005844:	4501                	li	a0,0
    80005846:	ffffd097          	auipc	ra,0xffffd
    8000584a:	6be080e7          	jalr	1726(ra) # 80002f04 <argstr>
    return -1;
    8000584e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005850:	10054e63          	bltz	a0,8000596c <sys_link+0x13c>
    80005854:	08000613          	li	a2,128
    80005858:	f5040593          	addi	a1,s0,-176
    8000585c:	4505                	li	a0,1
    8000585e:	ffffd097          	auipc	ra,0xffffd
    80005862:	6a6080e7          	jalr	1702(ra) # 80002f04 <argstr>
    return -1;
    80005866:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005868:	10054263          	bltz	a0,8000596c <sys_link+0x13c>
  begin_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	d36080e7          	jalr	-714(ra) # 800045a2 <begin_op>
  if((ip = namei(old)) == 0){
    80005874:	ed040513          	addi	a0,s0,-304
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	b0a080e7          	jalr	-1270(ra) # 80004382 <namei>
    80005880:	84aa                	mv	s1,a0
    80005882:	c551                	beqz	a0,8000590e <sys_link+0xde>
  ilock(ip);
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	342080e7          	jalr	834(ra) # 80003bc6 <ilock>
  if(ip->type == T_DIR){
    8000588c:	04449703          	lh	a4,68(s1)
    80005890:	4785                	li	a5,1
    80005892:	08f70463          	beq	a4,a5,8000591a <sys_link+0xea>
  ip->nlink++;
    80005896:	04a4d783          	lhu	a5,74(s1)
    8000589a:	2785                	addiw	a5,a5,1
    8000589c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058a0:	8526                	mv	a0,s1
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	258080e7          	jalr	600(ra) # 80003afa <iupdate>
  iunlock(ip);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	3dc080e7          	jalr	988(ra) # 80003c88 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058b4:	fd040593          	addi	a1,s0,-48
    800058b8:	f5040513          	addi	a0,s0,-176
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	ae4080e7          	jalr	-1308(ra) # 800043a0 <nameiparent>
    800058c4:	892a                	mv	s2,a0
    800058c6:	c935                	beqz	a0,8000593a <sys_link+0x10a>
  ilock(dp);
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	2fe080e7          	jalr	766(ra) # 80003bc6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058d0:	00092703          	lw	a4,0(s2)
    800058d4:	409c                	lw	a5,0(s1)
    800058d6:	04f71d63          	bne	a4,a5,80005930 <sys_link+0x100>
    800058da:	40d0                	lw	a2,4(s1)
    800058dc:	fd040593          	addi	a1,s0,-48
    800058e0:	854a                	mv	a0,s2
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	9de080e7          	jalr	-1570(ra) # 800042c0 <dirlink>
    800058ea:	04054363          	bltz	a0,80005930 <sys_link+0x100>
  iunlockput(dp);
    800058ee:	854a                	mv	a0,s2
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	538080e7          	jalr	1336(ra) # 80003e28 <iunlockput>
  iput(ip);
    800058f8:	8526                	mv	a0,s1
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	486080e7          	jalr	1158(ra) # 80003d80 <iput>
  end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	d1e080e7          	jalr	-738(ra) # 80004620 <end_op>
  return 0;
    8000590a:	4781                	li	a5,0
    8000590c:	a085                	j	8000596c <sys_link+0x13c>
    end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	d12080e7          	jalr	-750(ra) # 80004620 <end_op>
    return -1;
    80005916:	57fd                	li	a5,-1
    80005918:	a891                	j	8000596c <sys_link+0x13c>
    iunlockput(ip);
    8000591a:	8526                	mv	a0,s1
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	50c080e7          	jalr	1292(ra) # 80003e28 <iunlockput>
    end_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	cfc080e7          	jalr	-772(ra) # 80004620 <end_op>
    return -1;
    8000592c:	57fd                	li	a5,-1
    8000592e:	a83d                	j	8000596c <sys_link+0x13c>
    iunlockput(dp);
    80005930:	854a                	mv	a0,s2
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	4f6080e7          	jalr	1270(ra) # 80003e28 <iunlockput>
  ilock(ip);
    8000593a:	8526                	mv	a0,s1
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	28a080e7          	jalr	650(ra) # 80003bc6 <ilock>
  ip->nlink--;
    80005944:	04a4d783          	lhu	a5,74(s1)
    80005948:	37fd                	addiw	a5,a5,-1
    8000594a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	1aa080e7          	jalr	426(ra) # 80003afa <iupdate>
  iunlockput(ip);
    80005958:	8526                	mv	a0,s1
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	4ce080e7          	jalr	1230(ra) # 80003e28 <iunlockput>
  end_op();
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	cbe080e7          	jalr	-834(ra) # 80004620 <end_op>
  return -1;
    8000596a:	57fd                	li	a5,-1
}
    8000596c:	853e                	mv	a0,a5
    8000596e:	70b2                	ld	ra,296(sp)
    80005970:	7412                	ld	s0,288(sp)
    80005972:	64f2                	ld	s1,280(sp)
    80005974:	6952                	ld	s2,272(sp)
    80005976:	6155                	addi	sp,sp,304
    80005978:	8082                	ret

000000008000597a <sys_unlink>:
{
    8000597a:	7151                	addi	sp,sp,-240
    8000597c:	f586                	sd	ra,232(sp)
    8000597e:	f1a2                	sd	s0,224(sp)
    80005980:	eda6                	sd	s1,216(sp)
    80005982:	e9ca                	sd	s2,208(sp)
    80005984:	e5ce                	sd	s3,200(sp)
    80005986:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005988:	08000613          	li	a2,128
    8000598c:	f3040593          	addi	a1,s0,-208
    80005990:	4501                	li	a0,0
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	572080e7          	jalr	1394(ra) # 80002f04 <argstr>
    8000599a:	18054163          	bltz	a0,80005b1c <sys_unlink+0x1a2>
  begin_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	c04080e7          	jalr	-1020(ra) # 800045a2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059a6:	fb040593          	addi	a1,s0,-80
    800059aa:	f3040513          	addi	a0,s0,-208
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	9f2080e7          	jalr	-1550(ra) # 800043a0 <nameiparent>
    800059b6:	84aa                	mv	s1,a0
    800059b8:	c979                	beqz	a0,80005a8e <sys_unlink+0x114>
  ilock(dp);
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	20c080e7          	jalr	524(ra) # 80003bc6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059c2:	00003597          	auipc	a1,0x3
    800059c6:	e1e58593          	addi	a1,a1,-482 # 800087e0 <syscalls+0x2e8>
    800059ca:	fb040513          	addi	a0,s0,-80
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	6c2080e7          	jalr	1730(ra) # 80004090 <namecmp>
    800059d6:	14050a63          	beqz	a0,80005b2a <sys_unlink+0x1b0>
    800059da:	00003597          	auipc	a1,0x3
    800059de:	e0e58593          	addi	a1,a1,-498 # 800087e8 <syscalls+0x2f0>
    800059e2:	fb040513          	addi	a0,s0,-80
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	6aa080e7          	jalr	1706(ra) # 80004090 <namecmp>
    800059ee:	12050e63          	beqz	a0,80005b2a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059f2:	f2c40613          	addi	a2,s0,-212
    800059f6:	fb040593          	addi	a1,s0,-80
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	6ae080e7          	jalr	1710(ra) # 800040aa <dirlookup>
    80005a04:	892a                	mv	s2,a0
    80005a06:	12050263          	beqz	a0,80005b2a <sys_unlink+0x1b0>
  ilock(ip);
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	1bc080e7          	jalr	444(ra) # 80003bc6 <ilock>
  if(ip->nlink < 1)
    80005a12:	04a91783          	lh	a5,74(s2)
    80005a16:	08f05263          	blez	a5,80005a9a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a1a:	04491703          	lh	a4,68(s2)
    80005a1e:	4785                	li	a5,1
    80005a20:	08f70563          	beq	a4,a5,80005aaa <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a24:	4641                	li	a2,16
    80005a26:	4581                	li	a1,0
    80005a28:	fc040513          	addi	a0,s0,-64
    80005a2c:	ffffb097          	auipc	ra,0xffffb
    80005a30:	2a0080e7          	jalr	672(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a34:	4741                	li	a4,16
    80005a36:	f2c42683          	lw	a3,-212(s0)
    80005a3a:	fc040613          	addi	a2,s0,-64
    80005a3e:	4581                	li	a1,0
    80005a40:	8526                	mv	a0,s1
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	530080e7          	jalr	1328(ra) # 80003f72 <writei>
    80005a4a:	47c1                	li	a5,16
    80005a4c:	0af51563          	bne	a0,a5,80005af6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a50:	04491703          	lh	a4,68(s2)
    80005a54:	4785                	li	a5,1
    80005a56:	0af70863          	beq	a4,a5,80005b06 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a5a:	8526                	mv	a0,s1
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	3cc080e7          	jalr	972(ra) # 80003e28 <iunlockput>
  ip->nlink--;
    80005a64:	04a95783          	lhu	a5,74(s2)
    80005a68:	37fd                	addiw	a5,a5,-1
    80005a6a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a6e:	854a                	mv	a0,s2
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	08a080e7          	jalr	138(ra) # 80003afa <iupdate>
  iunlockput(ip);
    80005a78:	854a                	mv	a0,s2
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	3ae080e7          	jalr	942(ra) # 80003e28 <iunlockput>
  end_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	b9e080e7          	jalr	-1122(ra) # 80004620 <end_op>
  return 0;
    80005a8a:	4501                	li	a0,0
    80005a8c:	a84d                	j	80005b3e <sys_unlink+0x1c4>
    end_op();
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	b92080e7          	jalr	-1134(ra) # 80004620 <end_op>
    return -1;
    80005a96:	557d                	li	a0,-1
    80005a98:	a05d                	j	80005b3e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a9a:	00003517          	auipc	a0,0x3
    80005a9e:	d7650513          	addi	a0,a0,-650 # 80008810 <syscalls+0x318>
    80005aa2:	ffffb097          	auipc	ra,0xffffb
    80005aa6:	a98080e7          	jalr	-1384(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aaa:	04c92703          	lw	a4,76(s2)
    80005aae:	02000793          	li	a5,32
    80005ab2:	f6e7f9e3          	bgeu	a5,a4,80005a24 <sys_unlink+0xaa>
    80005ab6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005aba:	4741                	li	a4,16
    80005abc:	86ce                	mv	a3,s3
    80005abe:	f1840613          	addi	a2,s0,-232
    80005ac2:	4581                	li	a1,0
    80005ac4:	854a                	mv	a0,s2
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	3b4080e7          	jalr	948(ra) # 80003e7a <readi>
    80005ace:	47c1                	li	a5,16
    80005ad0:	00f51b63          	bne	a0,a5,80005ae6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ad4:	f1845783          	lhu	a5,-232(s0)
    80005ad8:	e7a1                	bnez	a5,80005b20 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ada:	29c1                	addiw	s3,s3,16
    80005adc:	04c92783          	lw	a5,76(s2)
    80005ae0:	fcf9ede3          	bltu	s3,a5,80005aba <sys_unlink+0x140>
    80005ae4:	b781                	j	80005a24 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ae6:	00003517          	auipc	a0,0x3
    80005aea:	d4250513          	addi	a0,a0,-702 # 80008828 <syscalls+0x330>
    80005aee:	ffffb097          	auipc	ra,0xffffb
    80005af2:	a4c080e7          	jalr	-1460(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005af6:	00003517          	auipc	a0,0x3
    80005afa:	d4a50513          	addi	a0,a0,-694 # 80008840 <syscalls+0x348>
    80005afe:	ffffb097          	auipc	ra,0xffffb
    80005b02:	a3c080e7          	jalr	-1476(ra) # 8000053a <panic>
    dp->nlink--;
    80005b06:	04a4d783          	lhu	a5,74(s1)
    80005b0a:	37fd                	addiw	a5,a5,-1
    80005b0c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b10:	8526                	mv	a0,s1
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	fe8080e7          	jalr	-24(ra) # 80003afa <iupdate>
    80005b1a:	b781                	j	80005a5a <sys_unlink+0xe0>
    return -1;
    80005b1c:	557d                	li	a0,-1
    80005b1e:	a005                	j	80005b3e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b20:	854a                	mv	a0,s2
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	306080e7          	jalr	774(ra) # 80003e28 <iunlockput>
  iunlockput(dp);
    80005b2a:	8526                	mv	a0,s1
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	2fc080e7          	jalr	764(ra) # 80003e28 <iunlockput>
  end_op();
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	aec080e7          	jalr	-1300(ra) # 80004620 <end_op>
  return -1;
    80005b3c:	557d                	li	a0,-1
}
    80005b3e:	70ae                	ld	ra,232(sp)
    80005b40:	740e                	ld	s0,224(sp)
    80005b42:	64ee                	ld	s1,216(sp)
    80005b44:	694e                	ld	s2,208(sp)
    80005b46:	69ae                	ld	s3,200(sp)
    80005b48:	616d                	addi	sp,sp,240
    80005b4a:	8082                	ret

0000000080005b4c <sys_open>:

uint64
sys_open(void)
{
    80005b4c:	7131                	addi	sp,sp,-192
    80005b4e:	fd06                	sd	ra,184(sp)
    80005b50:	f922                	sd	s0,176(sp)
    80005b52:	f526                	sd	s1,168(sp)
    80005b54:	f14a                	sd	s2,160(sp)
    80005b56:	ed4e                	sd	s3,152(sp)
    80005b58:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b5a:	08000613          	li	a2,128
    80005b5e:	f5040593          	addi	a1,s0,-176
    80005b62:	4501                	li	a0,0
    80005b64:	ffffd097          	auipc	ra,0xffffd
    80005b68:	3a0080e7          	jalr	928(ra) # 80002f04 <argstr>
    return -1;
    80005b6c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b6e:	0c054163          	bltz	a0,80005c30 <sys_open+0xe4>
    80005b72:	f4c40593          	addi	a1,s0,-180
    80005b76:	4505                	li	a0,1
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	348080e7          	jalr	840(ra) # 80002ec0 <argint>
    80005b80:	0a054863          	bltz	a0,80005c30 <sys_open+0xe4>

  begin_op();
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	a1e080e7          	jalr	-1506(ra) # 800045a2 <begin_op>

  if(omode & O_CREATE){
    80005b8c:	f4c42783          	lw	a5,-180(s0)
    80005b90:	2007f793          	andi	a5,a5,512
    80005b94:	cbdd                	beqz	a5,80005c4a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b96:	4681                	li	a3,0
    80005b98:	4601                	li	a2,0
    80005b9a:	4589                	li	a1,2
    80005b9c:	f5040513          	addi	a0,s0,-176
    80005ba0:	00000097          	auipc	ra,0x0
    80005ba4:	970080e7          	jalr	-1680(ra) # 80005510 <create>
    80005ba8:	892a                	mv	s2,a0
    if(ip == 0){
    80005baa:	c959                	beqz	a0,80005c40 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bac:	04491703          	lh	a4,68(s2)
    80005bb0:	478d                	li	a5,3
    80005bb2:	00f71763          	bne	a4,a5,80005bc0 <sys_open+0x74>
    80005bb6:	04695703          	lhu	a4,70(s2)
    80005bba:	47a5                	li	a5,9
    80005bbc:	0ce7ec63          	bltu	a5,a4,80005c94 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	dee080e7          	jalr	-530(ra) # 800049ae <filealloc>
    80005bc8:	89aa                	mv	s3,a0
    80005bca:	10050263          	beqz	a0,80005cce <sys_open+0x182>
    80005bce:	00000097          	auipc	ra,0x0
    80005bd2:	900080e7          	jalr	-1792(ra) # 800054ce <fdalloc>
    80005bd6:	84aa                	mv	s1,a0
    80005bd8:	0e054663          	bltz	a0,80005cc4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bdc:	04491703          	lh	a4,68(s2)
    80005be0:	478d                	li	a5,3
    80005be2:	0cf70463          	beq	a4,a5,80005caa <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005be6:	4789                	li	a5,2
    80005be8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005bec:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005bf0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005bf4:	f4c42783          	lw	a5,-180(s0)
    80005bf8:	0017c713          	xori	a4,a5,1
    80005bfc:	8b05                	andi	a4,a4,1
    80005bfe:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c02:	0037f713          	andi	a4,a5,3
    80005c06:	00e03733          	snez	a4,a4
    80005c0a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c0e:	4007f793          	andi	a5,a5,1024
    80005c12:	c791                	beqz	a5,80005c1e <sys_open+0xd2>
    80005c14:	04491703          	lh	a4,68(s2)
    80005c18:	4789                	li	a5,2
    80005c1a:	08f70f63          	beq	a4,a5,80005cb8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c1e:	854a                	mv	a0,s2
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	068080e7          	jalr	104(ra) # 80003c88 <iunlock>
  end_op();
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	9f8080e7          	jalr	-1544(ra) # 80004620 <end_op>

  return fd;
}
    80005c30:	8526                	mv	a0,s1
    80005c32:	70ea                	ld	ra,184(sp)
    80005c34:	744a                	ld	s0,176(sp)
    80005c36:	74aa                	ld	s1,168(sp)
    80005c38:	790a                	ld	s2,160(sp)
    80005c3a:	69ea                	ld	s3,152(sp)
    80005c3c:	6129                	addi	sp,sp,192
    80005c3e:	8082                	ret
      end_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	9e0080e7          	jalr	-1568(ra) # 80004620 <end_op>
      return -1;
    80005c48:	b7e5                	j	80005c30 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c4a:	f5040513          	addi	a0,s0,-176
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	734080e7          	jalr	1844(ra) # 80004382 <namei>
    80005c56:	892a                	mv	s2,a0
    80005c58:	c905                	beqz	a0,80005c88 <sys_open+0x13c>
    ilock(ip);
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	f6c080e7          	jalr	-148(ra) # 80003bc6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c62:	04491703          	lh	a4,68(s2)
    80005c66:	4785                	li	a5,1
    80005c68:	f4f712e3          	bne	a4,a5,80005bac <sys_open+0x60>
    80005c6c:	f4c42783          	lw	a5,-180(s0)
    80005c70:	dba1                	beqz	a5,80005bc0 <sys_open+0x74>
      iunlockput(ip);
    80005c72:	854a                	mv	a0,s2
    80005c74:	ffffe097          	auipc	ra,0xffffe
    80005c78:	1b4080e7          	jalr	436(ra) # 80003e28 <iunlockput>
      end_op();
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	9a4080e7          	jalr	-1628(ra) # 80004620 <end_op>
      return -1;
    80005c84:	54fd                	li	s1,-1
    80005c86:	b76d                	j	80005c30 <sys_open+0xe4>
      end_op();
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	998080e7          	jalr	-1640(ra) # 80004620 <end_op>
      return -1;
    80005c90:	54fd                	li	s1,-1
    80005c92:	bf79                	j	80005c30 <sys_open+0xe4>
    iunlockput(ip);
    80005c94:	854a                	mv	a0,s2
    80005c96:	ffffe097          	auipc	ra,0xffffe
    80005c9a:	192080e7          	jalr	402(ra) # 80003e28 <iunlockput>
    end_op();
    80005c9e:	fffff097          	auipc	ra,0xfffff
    80005ca2:	982080e7          	jalr	-1662(ra) # 80004620 <end_op>
    return -1;
    80005ca6:	54fd                	li	s1,-1
    80005ca8:	b761                	j	80005c30 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005caa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005cae:	04691783          	lh	a5,70(s2)
    80005cb2:	02f99223          	sh	a5,36(s3)
    80005cb6:	bf2d                	j	80005bf0 <sys_open+0xa4>
    itrunc(ip);
    80005cb8:	854a                	mv	a0,s2
    80005cba:	ffffe097          	auipc	ra,0xffffe
    80005cbe:	01a080e7          	jalr	26(ra) # 80003cd4 <itrunc>
    80005cc2:	bfb1                	j	80005c1e <sys_open+0xd2>
      fileclose(f);
    80005cc4:	854e                	mv	a0,s3
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	da4080e7          	jalr	-604(ra) # 80004a6a <fileclose>
    iunlockput(ip);
    80005cce:	854a                	mv	a0,s2
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	158080e7          	jalr	344(ra) # 80003e28 <iunlockput>
    end_op();
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	948080e7          	jalr	-1720(ra) # 80004620 <end_op>
    return -1;
    80005ce0:	54fd                	li	s1,-1
    80005ce2:	b7b9                	j	80005c30 <sys_open+0xe4>

0000000080005ce4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ce4:	7175                	addi	sp,sp,-144
    80005ce6:	e506                	sd	ra,136(sp)
    80005ce8:	e122                	sd	s0,128(sp)
    80005cea:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	8b6080e7          	jalr	-1866(ra) # 800045a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cf4:	08000613          	li	a2,128
    80005cf8:	f7040593          	addi	a1,s0,-144
    80005cfc:	4501                	li	a0,0
    80005cfe:	ffffd097          	auipc	ra,0xffffd
    80005d02:	206080e7          	jalr	518(ra) # 80002f04 <argstr>
    80005d06:	02054963          	bltz	a0,80005d38 <sys_mkdir+0x54>
    80005d0a:	4681                	li	a3,0
    80005d0c:	4601                	li	a2,0
    80005d0e:	4585                	li	a1,1
    80005d10:	f7040513          	addi	a0,s0,-144
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	7fc080e7          	jalr	2044(ra) # 80005510 <create>
    80005d1c:	cd11                	beqz	a0,80005d38 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	10a080e7          	jalr	266(ra) # 80003e28 <iunlockput>
  end_op();
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	8fa080e7          	jalr	-1798(ra) # 80004620 <end_op>
  return 0;
    80005d2e:	4501                	li	a0,0
}
    80005d30:	60aa                	ld	ra,136(sp)
    80005d32:	640a                	ld	s0,128(sp)
    80005d34:	6149                	addi	sp,sp,144
    80005d36:	8082                	ret
    end_op();
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	8e8080e7          	jalr	-1816(ra) # 80004620 <end_op>
    return -1;
    80005d40:	557d                	li	a0,-1
    80005d42:	b7fd                	j	80005d30 <sys_mkdir+0x4c>

0000000080005d44 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d44:	7135                	addi	sp,sp,-160
    80005d46:	ed06                	sd	ra,152(sp)
    80005d48:	e922                	sd	s0,144(sp)
    80005d4a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d4c:	fffff097          	auipc	ra,0xfffff
    80005d50:	856080e7          	jalr	-1962(ra) # 800045a2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d54:	08000613          	li	a2,128
    80005d58:	f7040593          	addi	a1,s0,-144
    80005d5c:	4501                	li	a0,0
    80005d5e:	ffffd097          	auipc	ra,0xffffd
    80005d62:	1a6080e7          	jalr	422(ra) # 80002f04 <argstr>
    80005d66:	04054a63          	bltz	a0,80005dba <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d6a:	f6c40593          	addi	a1,s0,-148
    80005d6e:	4505                	li	a0,1
    80005d70:	ffffd097          	auipc	ra,0xffffd
    80005d74:	150080e7          	jalr	336(ra) # 80002ec0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d78:	04054163          	bltz	a0,80005dba <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d7c:	f6840593          	addi	a1,s0,-152
    80005d80:	4509                	li	a0,2
    80005d82:	ffffd097          	auipc	ra,0xffffd
    80005d86:	13e080e7          	jalr	318(ra) # 80002ec0 <argint>
     argint(1, &major) < 0 ||
    80005d8a:	02054863          	bltz	a0,80005dba <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d8e:	f6841683          	lh	a3,-152(s0)
    80005d92:	f6c41603          	lh	a2,-148(s0)
    80005d96:	458d                	li	a1,3
    80005d98:	f7040513          	addi	a0,s0,-144
    80005d9c:	fffff097          	auipc	ra,0xfffff
    80005da0:	774080e7          	jalr	1908(ra) # 80005510 <create>
     argint(2, &minor) < 0 ||
    80005da4:	c919                	beqz	a0,80005dba <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	082080e7          	jalr	130(ra) # 80003e28 <iunlockput>
  end_op();
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	872080e7          	jalr	-1934(ra) # 80004620 <end_op>
  return 0;
    80005db6:	4501                	li	a0,0
    80005db8:	a031                	j	80005dc4 <sys_mknod+0x80>
    end_op();
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	866080e7          	jalr	-1946(ra) # 80004620 <end_op>
    return -1;
    80005dc2:	557d                	li	a0,-1
}
    80005dc4:	60ea                	ld	ra,152(sp)
    80005dc6:	644a                	ld	s0,144(sp)
    80005dc8:	610d                	addi	sp,sp,160
    80005dca:	8082                	ret

0000000080005dcc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dcc:	7135                	addi	sp,sp,-160
    80005dce:	ed06                	sd	ra,152(sp)
    80005dd0:	e922                	sd	s0,144(sp)
    80005dd2:	e526                	sd	s1,136(sp)
    80005dd4:	e14a                	sd	s2,128(sp)
    80005dd6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	bbe080e7          	jalr	-1090(ra) # 80001996 <myproc>
    80005de0:	892a                	mv	s2,a0
  
  begin_op();
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	7c0080e7          	jalr	1984(ra) # 800045a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dea:	08000613          	li	a2,128
    80005dee:	f6040593          	addi	a1,s0,-160
    80005df2:	4501                	li	a0,0
    80005df4:	ffffd097          	auipc	ra,0xffffd
    80005df8:	110080e7          	jalr	272(ra) # 80002f04 <argstr>
    80005dfc:	04054b63          	bltz	a0,80005e52 <sys_chdir+0x86>
    80005e00:	f6040513          	addi	a0,s0,-160
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	57e080e7          	jalr	1406(ra) # 80004382 <namei>
    80005e0c:	84aa                	mv	s1,a0
    80005e0e:	c131                	beqz	a0,80005e52 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e10:	ffffe097          	auipc	ra,0xffffe
    80005e14:	db6080e7          	jalr	-586(ra) # 80003bc6 <ilock>
  if(ip->type != T_DIR){
    80005e18:	04449703          	lh	a4,68(s1)
    80005e1c:	4785                	li	a5,1
    80005e1e:	04f71063          	bne	a4,a5,80005e5e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e22:	8526                	mv	a0,s1
    80005e24:	ffffe097          	auipc	ra,0xffffe
    80005e28:	e64080e7          	jalr	-412(ra) # 80003c88 <iunlock>
  iput(p->cwd);
    80005e2c:	15093503          	ld	a0,336(s2)
    80005e30:	ffffe097          	auipc	ra,0xffffe
    80005e34:	f50080e7          	jalr	-176(ra) # 80003d80 <iput>
  end_op();
    80005e38:	ffffe097          	auipc	ra,0xffffe
    80005e3c:	7e8080e7          	jalr	2024(ra) # 80004620 <end_op>
  p->cwd = ip;
    80005e40:	14993823          	sd	s1,336(s2)
  return 0;
    80005e44:	4501                	li	a0,0
}
    80005e46:	60ea                	ld	ra,152(sp)
    80005e48:	644a                	ld	s0,144(sp)
    80005e4a:	64aa                	ld	s1,136(sp)
    80005e4c:	690a                	ld	s2,128(sp)
    80005e4e:	610d                	addi	sp,sp,160
    80005e50:	8082                	ret
    end_op();
    80005e52:	ffffe097          	auipc	ra,0xffffe
    80005e56:	7ce080e7          	jalr	1998(ra) # 80004620 <end_op>
    return -1;
    80005e5a:	557d                	li	a0,-1
    80005e5c:	b7ed                	j	80005e46 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e5e:	8526                	mv	a0,s1
    80005e60:	ffffe097          	auipc	ra,0xffffe
    80005e64:	fc8080e7          	jalr	-56(ra) # 80003e28 <iunlockput>
    end_op();
    80005e68:	ffffe097          	auipc	ra,0xffffe
    80005e6c:	7b8080e7          	jalr	1976(ra) # 80004620 <end_op>
    return -1;
    80005e70:	557d                	li	a0,-1
    80005e72:	bfd1                	j	80005e46 <sys_chdir+0x7a>

0000000080005e74 <sys_exec>:

uint64
sys_exec(void)
{
    80005e74:	7145                	addi	sp,sp,-464
    80005e76:	e786                	sd	ra,456(sp)
    80005e78:	e3a2                	sd	s0,448(sp)
    80005e7a:	ff26                	sd	s1,440(sp)
    80005e7c:	fb4a                	sd	s2,432(sp)
    80005e7e:	f74e                	sd	s3,424(sp)
    80005e80:	f352                	sd	s4,416(sp)
    80005e82:	ef56                	sd	s5,408(sp)
    80005e84:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e86:	08000613          	li	a2,128
    80005e8a:	f4040593          	addi	a1,s0,-192
    80005e8e:	4501                	li	a0,0
    80005e90:	ffffd097          	auipc	ra,0xffffd
    80005e94:	074080e7          	jalr	116(ra) # 80002f04 <argstr>
    return -1;
    80005e98:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e9a:	0c054b63          	bltz	a0,80005f70 <sys_exec+0xfc>
    80005e9e:	e3840593          	addi	a1,s0,-456
    80005ea2:	4505                	li	a0,1
    80005ea4:	ffffd097          	auipc	ra,0xffffd
    80005ea8:	03e080e7          	jalr	62(ra) # 80002ee2 <argaddr>
    80005eac:	0c054263          	bltz	a0,80005f70 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005eb0:	10000613          	li	a2,256
    80005eb4:	4581                	li	a1,0
    80005eb6:	e4040513          	addi	a0,s0,-448
    80005eba:	ffffb097          	auipc	ra,0xffffb
    80005ebe:	e12080e7          	jalr	-494(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ec2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ec6:	89a6                	mv	s3,s1
    80005ec8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005eca:	02000a13          	li	s4,32
    80005ece:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ed2:	00391513          	slli	a0,s2,0x3
    80005ed6:	e3040593          	addi	a1,s0,-464
    80005eda:	e3843783          	ld	a5,-456(s0)
    80005ede:	953e                	add	a0,a0,a5
    80005ee0:	ffffd097          	auipc	ra,0xffffd
    80005ee4:	f46080e7          	jalr	-186(ra) # 80002e26 <fetchaddr>
    80005ee8:	02054a63          	bltz	a0,80005f1c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005eec:	e3043783          	ld	a5,-464(s0)
    80005ef0:	c3b9                	beqz	a5,80005f36 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ef2:	ffffb097          	auipc	ra,0xffffb
    80005ef6:	bee080e7          	jalr	-1042(ra) # 80000ae0 <kalloc>
    80005efa:	85aa                	mv	a1,a0
    80005efc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f00:	cd11                	beqz	a0,80005f1c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f02:	6605                	lui	a2,0x1
    80005f04:	e3043503          	ld	a0,-464(s0)
    80005f08:	ffffd097          	auipc	ra,0xffffd
    80005f0c:	f70080e7          	jalr	-144(ra) # 80002e78 <fetchstr>
    80005f10:	00054663          	bltz	a0,80005f1c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f14:	0905                	addi	s2,s2,1
    80005f16:	09a1                	addi	s3,s3,8
    80005f18:	fb491be3          	bne	s2,s4,80005ece <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f1c:	f4040913          	addi	s2,s0,-192
    80005f20:	6088                	ld	a0,0(s1)
    80005f22:	c531                	beqz	a0,80005f6e <sys_exec+0xfa>
    kfree(argv[i]);
    80005f24:	ffffb097          	auipc	ra,0xffffb
    80005f28:	abe080e7          	jalr	-1346(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f2c:	04a1                	addi	s1,s1,8
    80005f2e:	ff2499e3          	bne	s1,s2,80005f20 <sys_exec+0xac>
  return -1;
    80005f32:	597d                	li	s2,-1
    80005f34:	a835                	j	80005f70 <sys_exec+0xfc>
      argv[i] = 0;
    80005f36:	0a8e                	slli	s5,s5,0x3
    80005f38:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005f3c:	00878ab3          	add	s5,a5,s0
    80005f40:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f44:	e4040593          	addi	a1,s0,-448
    80005f48:	f4040513          	addi	a0,s0,-192
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	172080e7          	jalr	370(ra) # 800050be <exec>
    80005f54:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f56:	f4040993          	addi	s3,s0,-192
    80005f5a:	6088                	ld	a0,0(s1)
    80005f5c:	c911                	beqz	a0,80005f70 <sys_exec+0xfc>
    kfree(argv[i]);
    80005f5e:	ffffb097          	auipc	ra,0xffffb
    80005f62:	a84080e7          	jalr	-1404(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f66:	04a1                	addi	s1,s1,8
    80005f68:	ff3499e3          	bne	s1,s3,80005f5a <sys_exec+0xe6>
    80005f6c:	a011                	j	80005f70 <sys_exec+0xfc>
  return -1;
    80005f6e:	597d                	li	s2,-1
}
    80005f70:	854a                	mv	a0,s2
    80005f72:	60be                	ld	ra,456(sp)
    80005f74:	641e                	ld	s0,448(sp)
    80005f76:	74fa                	ld	s1,440(sp)
    80005f78:	795a                	ld	s2,432(sp)
    80005f7a:	79ba                	ld	s3,424(sp)
    80005f7c:	7a1a                	ld	s4,416(sp)
    80005f7e:	6afa                	ld	s5,408(sp)
    80005f80:	6179                	addi	sp,sp,464
    80005f82:	8082                	ret

0000000080005f84 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f84:	7139                	addi	sp,sp,-64
    80005f86:	fc06                	sd	ra,56(sp)
    80005f88:	f822                	sd	s0,48(sp)
    80005f8a:	f426                	sd	s1,40(sp)
    80005f8c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f8e:	ffffc097          	auipc	ra,0xffffc
    80005f92:	a08080e7          	jalr	-1528(ra) # 80001996 <myproc>
    80005f96:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f98:	fd840593          	addi	a1,s0,-40
    80005f9c:	4501                	li	a0,0
    80005f9e:	ffffd097          	auipc	ra,0xffffd
    80005fa2:	f44080e7          	jalr	-188(ra) # 80002ee2 <argaddr>
    return -1;
    80005fa6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005fa8:	0e054063          	bltz	a0,80006088 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005fac:	fc840593          	addi	a1,s0,-56
    80005fb0:	fd040513          	addi	a0,s0,-48
    80005fb4:	fffff097          	auipc	ra,0xfffff
    80005fb8:	de6080e7          	jalr	-538(ra) # 80004d9a <pipealloc>
    return -1;
    80005fbc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fbe:	0c054563          	bltz	a0,80006088 <sys_pipe+0x104>
  fd0 = -1;
    80005fc2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005fc6:	fd043503          	ld	a0,-48(s0)
    80005fca:	fffff097          	auipc	ra,0xfffff
    80005fce:	504080e7          	jalr	1284(ra) # 800054ce <fdalloc>
    80005fd2:	fca42223          	sw	a0,-60(s0)
    80005fd6:	08054c63          	bltz	a0,8000606e <sys_pipe+0xea>
    80005fda:	fc843503          	ld	a0,-56(s0)
    80005fde:	fffff097          	auipc	ra,0xfffff
    80005fe2:	4f0080e7          	jalr	1264(ra) # 800054ce <fdalloc>
    80005fe6:	fca42023          	sw	a0,-64(s0)
    80005fea:	06054963          	bltz	a0,8000605c <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fee:	4691                	li	a3,4
    80005ff0:	fc440613          	addi	a2,s0,-60
    80005ff4:	fd843583          	ld	a1,-40(s0)
    80005ff8:	68a8                	ld	a0,80(s1)
    80005ffa:	ffffb097          	auipc	ra,0xffffb
    80005ffe:	660080e7          	jalr	1632(ra) # 8000165a <copyout>
    80006002:	02054063          	bltz	a0,80006022 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006006:	4691                	li	a3,4
    80006008:	fc040613          	addi	a2,s0,-64
    8000600c:	fd843583          	ld	a1,-40(s0)
    80006010:	0591                	addi	a1,a1,4
    80006012:	68a8                	ld	a0,80(s1)
    80006014:	ffffb097          	auipc	ra,0xffffb
    80006018:	646080e7          	jalr	1606(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000601c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000601e:	06055563          	bgez	a0,80006088 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006022:	fc442783          	lw	a5,-60(s0)
    80006026:	07e9                	addi	a5,a5,26
    80006028:	078e                	slli	a5,a5,0x3
    8000602a:	97a6                	add	a5,a5,s1
    8000602c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006030:	fc042783          	lw	a5,-64(s0)
    80006034:	07e9                	addi	a5,a5,26
    80006036:	078e                	slli	a5,a5,0x3
    80006038:	00f48533          	add	a0,s1,a5
    8000603c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006040:	fd043503          	ld	a0,-48(s0)
    80006044:	fffff097          	auipc	ra,0xfffff
    80006048:	a26080e7          	jalr	-1498(ra) # 80004a6a <fileclose>
    fileclose(wf);
    8000604c:	fc843503          	ld	a0,-56(s0)
    80006050:	fffff097          	auipc	ra,0xfffff
    80006054:	a1a080e7          	jalr	-1510(ra) # 80004a6a <fileclose>
    return -1;
    80006058:	57fd                	li	a5,-1
    8000605a:	a03d                	j	80006088 <sys_pipe+0x104>
    if(fd0 >= 0)
    8000605c:	fc442783          	lw	a5,-60(s0)
    80006060:	0007c763          	bltz	a5,8000606e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006064:	07e9                	addi	a5,a5,26
    80006066:	078e                	slli	a5,a5,0x3
    80006068:	97a6                	add	a5,a5,s1
    8000606a:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000606e:	fd043503          	ld	a0,-48(s0)
    80006072:	fffff097          	auipc	ra,0xfffff
    80006076:	9f8080e7          	jalr	-1544(ra) # 80004a6a <fileclose>
    fileclose(wf);
    8000607a:	fc843503          	ld	a0,-56(s0)
    8000607e:	fffff097          	auipc	ra,0xfffff
    80006082:	9ec080e7          	jalr	-1556(ra) # 80004a6a <fileclose>
    return -1;
    80006086:	57fd                	li	a5,-1
}
    80006088:	853e                	mv	a0,a5
    8000608a:	70e2                	ld	ra,56(sp)
    8000608c:	7442                	ld	s0,48(sp)
    8000608e:	74a2                	ld	s1,40(sp)
    80006090:	6121                	addi	sp,sp,64
    80006092:	8082                	ret
	...

00000000800060a0 <kernelvec>:
    800060a0:	7111                	addi	sp,sp,-256
    800060a2:	e006                	sd	ra,0(sp)
    800060a4:	e40a                	sd	sp,8(sp)
    800060a6:	e80e                	sd	gp,16(sp)
    800060a8:	ec12                	sd	tp,24(sp)
    800060aa:	f016                	sd	t0,32(sp)
    800060ac:	f41a                	sd	t1,40(sp)
    800060ae:	f81e                	sd	t2,48(sp)
    800060b0:	fc22                	sd	s0,56(sp)
    800060b2:	e0a6                	sd	s1,64(sp)
    800060b4:	e4aa                	sd	a0,72(sp)
    800060b6:	e8ae                	sd	a1,80(sp)
    800060b8:	ecb2                	sd	a2,88(sp)
    800060ba:	f0b6                	sd	a3,96(sp)
    800060bc:	f4ba                	sd	a4,104(sp)
    800060be:	f8be                	sd	a5,112(sp)
    800060c0:	fcc2                	sd	a6,120(sp)
    800060c2:	e146                	sd	a7,128(sp)
    800060c4:	e54a                	sd	s2,136(sp)
    800060c6:	e94e                	sd	s3,144(sp)
    800060c8:	ed52                	sd	s4,152(sp)
    800060ca:	f156                	sd	s5,160(sp)
    800060cc:	f55a                	sd	s6,168(sp)
    800060ce:	f95e                	sd	s7,176(sp)
    800060d0:	fd62                	sd	s8,184(sp)
    800060d2:	e1e6                	sd	s9,192(sp)
    800060d4:	e5ea                	sd	s10,200(sp)
    800060d6:	e9ee                	sd	s11,208(sp)
    800060d8:	edf2                	sd	t3,216(sp)
    800060da:	f1f6                	sd	t4,224(sp)
    800060dc:	f5fa                	sd	t5,232(sp)
    800060de:	f9fe                	sd	t6,240(sp)
    800060e0:	c13fc0ef          	jal	ra,80002cf2 <kerneltrap>
    800060e4:	6082                	ld	ra,0(sp)
    800060e6:	6122                	ld	sp,8(sp)
    800060e8:	61c2                	ld	gp,16(sp)
    800060ea:	7282                	ld	t0,32(sp)
    800060ec:	7322                	ld	t1,40(sp)
    800060ee:	73c2                	ld	t2,48(sp)
    800060f0:	7462                	ld	s0,56(sp)
    800060f2:	6486                	ld	s1,64(sp)
    800060f4:	6526                	ld	a0,72(sp)
    800060f6:	65c6                	ld	a1,80(sp)
    800060f8:	6666                	ld	a2,88(sp)
    800060fa:	7686                	ld	a3,96(sp)
    800060fc:	7726                	ld	a4,104(sp)
    800060fe:	77c6                	ld	a5,112(sp)
    80006100:	7866                	ld	a6,120(sp)
    80006102:	688a                	ld	a7,128(sp)
    80006104:	692a                	ld	s2,136(sp)
    80006106:	69ca                	ld	s3,144(sp)
    80006108:	6a6a                	ld	s4,152(sp)
    8000610a:	7a8a                	ld	s5,160(sp)
    8000610c:	7b2a                	ld	s6,168(sp)
    8000610e:	7bca                	ld	s7,176(sp)
    80006110:	7c6a                	ld	s8,184(sp)
    80006112:	6c8e                	ld	s9,192(sp)
    80006114:	6d2e                	ld	s10,200(sp)
    80006116:	6dce                	ld	s11,208(sp)
    80006118:	6e6e                	ld	t3,216(sp)
    8000611a:	7e8e                	ld	t4,224(sp)
    8000611c:	7f2e                	ld	t5,232(sp)
    8000611e:	7fce                	ld	t6,240(sp)
    80006120:	6111                	addi	sp,sp,256
    80006122:	10200073          	sret
    80006126:	00000013          	nop
    8000612a:	00000013          	nop
    8000612e:	0001                	nop

0000000080006130 <timervec>:
    80006130:	34051573          	csrrw	a0,mscratch,a0
    80006134:	e10c                	sd	a1,0(a0)
    80006136:	e510                	sd	a2,8(a0)
    80006138:	e914                	sd	a3,16(a0)
    8000613a:	6d0c                	ld	a1,24(a0)
    8000613c:	7110                	ld	a2,32(a0)
    8000613e:	6194                	ld	a3,0(a1)
    80006140:	96b2                	add	a3,a3,a2
    80006142:	e194                	sd	a3,0(a1)
    80006144:	4589                	li	a1,2
    80006146:	14459073          	csrw	sip,a1
    8000614a:	6914                	ld	a3,16(a0)
    8000614c:	6510                	ld	a2,8(a0)
    8000614e:	610c                	ld	a1,0(a0)
    80006150:	34051573          	csrrw	a0,mscratch,a0
    80006154:	30200073          	mret
	...

000000008000615a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000615a:	1141                	addi	sp,sp,-16
    8000615c:	e422                	sd	s0,8(sp)
    8000615e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006160:	0c0007b7          	lui	a5,0xc000
    80006164:	4705                	li	a4,1
    80006166:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006168:	c3d8                	sw	a4,4(a5)
}
    8000616a:	6422                	ld	s0,8(sp)
    8000616c:	0141                	addi	sp,sp,16
    8000616e:	8082                	ret

0000000080006170 <plicinithart>:

void
plicinithart(void)
{
    80006170:	1141                	addi	sp,sp,-16
    80006172:	e406                	sd	ra,8(sp)
    80006174:	e022                	sd	s0,0(sp)
    80006176:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006178:	ffffb097          	auipc	ra,0xffffb
    8000617c:	7f2080e7          	jalr	2034(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006180:	0085171b          	slliw	a4,a0,0x8
    80006184:	0c0027b7          	lui	a5,0xc002
    80006188:	97ba                	add	a5,a5,a4
    8000618a:	40200713          	li	a4,1026
    8000618e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006192:	00d5151b          	slliw	a0,a0,0xd
    80006196:	0c2017b7          	lui	a5,0xc201
    8000619a:	97aa                	add	a5,a5,a0
    8000619c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800061a0:	60a2                	ld	ra,8(sp)
    800061a2:	6402                	ld	s0,0(sp)
    800061a4:	0141                	addi	sp,sp,16
    800061a6:	8082                	ret

00000000800061a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061a8:	1141                	addi	sp,sp,-16
    800061aa:	e406                	sd	ra,8(sp)
    800061ac:	e022                	sd	s0,0(sp)
    800061ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061b0:	ffffb097          	auipc	ra,0xffffb
    800061b4:	7ba080e7          	jalr	1978(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061b8:	00d5151b          	slliw	a0,a0,0xd
    800061bc:	0c2017b7          	lui	a5,0xc201
    800061c0:	97aa                	add	a5,a5,a0
  return irq;
}
    800061c2:	43c8                	lw	a0,4(a5)
    800061c4:	60a2                	ld	ra,8(sp)
    800061c6:	6402                	ld	s0,0(sp)
    800061c8:	0141                	addi	sp,sp,16
    800061ca:	8082                	ret

00000000800061cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061cc:	1101                	addi	sp,sp,-32
    800061ce:	ec06                	sd	ra,24(sp)
    800061d0:	e822                	sd	s0,16(sp)
    800061d2:	e426                	sd	s1,8(sp)
    800061d4:	1000                	addi	s0,sp,32
    800061d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061d8:	ffffb097          	auipc	ra,0xffffb
    800061dc:	792080e7          	jalr	1938(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061e0:	00d5151b          	slliw	a0,a0,0xd
    800061e4:	0c2017b7          	lui	a5,0xc201
    800061e8:	97aa                	add	a5,a5,a0
    800061ea:	c3c4                	sw	s1,4(a5)
}
    800061ec:	60e2                	ld	ra,24(sp)
    800061ee:	6442                	ld	s0,16(sp)
    800061f0:	64a2                	ld	s1,8(sp)
    800061f2:	6105                	addi	sp,sp,32
    800061f4:	8082                	ret

00000000800061f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061f6:	1141                	addi	sp,sp,-16
    800061f8:	e406                	sd	ra,8(sp)
    800061fa:	e022                	sd	s0,0(sp)
    800061fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061fe:	479d                	li	a5,7
    80006200:	06a7c863          	blt	a5,a0,80006270 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006204:	0001d717          	auipc	a4,0x1d
    80006208:	dfc70713          	addi	a4,a4,-516 # 80023000 <disk>
    8000620c:	972a                	add	a4,a4,a0
    8000620e:	6789                	lui	a5,0x2
    80006210:	97ba                	add	a5,a5,a4
    80006212:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006216:	e7ad                	bnez	a5,80006280 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006218:	00451793          	slli	a5,a0,0x4
    8000621c:	0001f717          	auipc	a4,0x1f
    80006220:	de470713          	addi	a4,a4,-540 # 80025000 <disk+0x2000>
    80006224:	6314                	ld	a3,0(a4)
    80006226:	96be                	add	a3,a3,a5
    80006228:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000622c:	6314                	ld	a3,0(a4)
    8000622e:	96be                	add	a3,a3,a5
    80006230:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006234:	6314                	ld	a3,0(a4)
    80006236:	96be                	add	a3,a3,a5
    80006238:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000623c:	6318                	ld	a4,0(a4)
    8000623e:	97ba                	add	a5,a5,a4
    80006240:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006244:	0001d717          	auipc	a4,0x1d
    80006248:	dbc70713          	addi	a4,a4,-580 # 80023000 <disk>
    8000624c:	972a                	add	a4,a4,a0
    8000624e:	6789                	lui	a5,0x2
    80006250:	97ba                	add	a5,a5,a4
    80006252:	4705                	li	a4,1
    80006254:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006258:	0001f517          	auipc	a0,0x1f
    8000625c:	dc050513          	addi	a0,a0,-576 # 80025018 <disk+0x2018>
    80006260:	ffffc097          	auipc	ra,0xffffc
    80006264:	fae080e7          	jalr	-82(ra) # 8000220e <wakeup>
}
    80006268:	60a2                	ld	ra,8(sp)
    8000626a:	6402                	ld	s0,0(sp)
    8000626c:	0141                	addi	sp,sp,16
    8000626e:	8082                	ret
    panic("free_desc 1");
    80006270:	00002517          	auipc	a0,0x2
    80006274:	5e050513          	addi	a0,a0,1504 # 80008850 <syscalls+0x358>
    80006278:	ffffa097          	auipc	ra,0xffffa
    8000627c:	2c2080e7          	jalr	706(ra) # 8000053a <panic>
    panic("free_desc 2");
    80006280:	00002517          	auipc	a0,0x2
    80006284:	5e050513          	addi	a0,a0,1504 # 80008860 <syscalls+0x368>
    80006288:	ffffa097          	auipc	ra,0xffffa
    8000628c:	2b2080e7          	jalr	690(ra) # 8000053a <panic>

0000000080006290 <virtio_disk_init>:
{
    80006290:	1101                	addi	sp,sp,-32
    80006292:	ec06                	sd	ra,24(sp)
    80006294:	e822                	sd	s0,16(sp)
    80006296:	e426                	sd	s1,8(sp)
    80006298:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000629a:	00002597          	auipc	a1,0x2
    8000629e:	5d658593          	addi	a1,a1,1494 # 80008870 <syscalls+0x378>
    800062a2:	0001f517          	auipc	a0,0x1f
    800062a6:	e8650513          	addi	a0,a0,-378 # 80025128 <disk+0x2128>
    800062aa:	ffffb097          	auipc	ra,0xffffb
    800062ae:	896080e7          	jalr	-1898(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062b2:	100017b7          	lui	a5,0x10001
    800062b6:	4398                	lw	a4,0(a5)
    800062b8:	2701                	sext.w	a4,a4
    800062ba:	747277b7          	lui	a5,0x74727
    800062be:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062c2:	0ef71063          	bne	a4,a5,800063a2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062c6:	100017b7          	lui	a5,0x10001
    800062ca:	43dc                	lw	a5,4(a5)
    800062cc:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062ce:	4705                	li	a4,1
    800062d0:	0ce79963          	bne	a5,a4,800063a2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062d4:	100017b7          	lui	a5,0x10001
    800062d8:	479c                	lw	a5,8(a5)
    800062da:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062dc:	4709                	li	a4,2
    800062de:	0ce79263          	bne	a5,a4,800063a2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062e2:	100017b7          	lui	a5,0x10001
    800062e6:	47d8                	lw	a4,12(a5)
    800062e8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062ea:	554d47b7          	lui	a5,0x554d4
    800062ee:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062f2:	0af71863          	bne	a4,a5,800063a2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062f6:	100017b7          	lui	a5,0x10001
    800062fa:	4705                	li	a4,1
    800062fc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062fe:	470d                	li	a4,3
    80006300:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006302:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006304:	c7ffe6b7          	lui	a3,0xc7ffe
    80006308:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000630c:	8f75                	and	a4,a4,a3
    8000630e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006310:	472d                	li	a4,11
    80006312:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006314:	473d                	li	a4,15
    80006316:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006318:	6705                	lui	a4,0x1
    8000631a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000631c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006320:	5bdc                	lw	a5,52(a5)
    80006322:	2781                	sext.w	a5,a5
  if(max == 0)
    80006324:	c7d9                	beqz	a5,800063b2 <virtio_disk_init+0x122>
  if(max < NUM)
    80006326:	471d                	li	a4,7
    80006328:	08f77d63          	bgeu	a4,a5,800063c2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000632c:	100014b7          	lui	s1,0x10001
    80006330:	47a1                	li	a5,8
    80006332:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006334:	6609                	lui	a2,0x2
    80006336:	4581                	li	a1,0
    80006338:	0001d517          	auipc	a0,0x1d
    8000633c:	cc850513          	addi	a0,a0,-824 # 80023000 <disk>
    80006340:	ffffb097          	auipc	ra,0xffffb
    80006344:	98c080e7          	jalr	-1652(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006348:	0001d717          	auipc	a4,0x1d
    8000634c:	cb870713          	addi	a4,a4,-840 # 80023000 <disk>
    80006350:	00c75793          	srli	a5,a4,0xc
    80006354:	2781                	sext.w	a5,a5
    80006356:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006358:	0001f797          	auipc	a5,0x1f
    8000635c:	ca878793          	addi	a5,a5,-856 # 80025000 <disk+0x2000>
    80006360:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006362:	0001d717          	auipc	a4,0x1d
    80006366:	d1e70713          	addi	a4,a4,-738 # 80023080 <disk+0x80>
    8000636a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    8000636c:	0001e717          	auipc	a4,0x1e
    80006370:	c9470713          	addi	a4,a4,-876 # 80024000 <disk+0x1000>
    80006374:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006376:	4705                	li	a4,1
    80006378:	00e78c23          	sb	a4,24(a5)
    8000637c:	00e78ca3          	sb	a4,25(a5)
    80006380:	00e78d23          	sb	a4,26(a5)
    80006384:	00e78da3          	sb	a4,27(a5)
    80006388:	00e78e23          	sb	a4,28(a5)
    8000638c:	00e78ea3          	sb	a4,29(a5)
    80006390:	00e78f23          	sb	a4,30(a5)
    80006394:	00e78fa3          	sb	a4,31(a5)
}
    80006398:	60e2                	ld	ra,24(sp)
    8000639a:	6442                	ld	s0,16(sp)
    8000639c:	64a2                	ld	s1,8(sp)
    8000639e:	6105                	addi	sp,sp,32
    800063a0:	8082                	ret
    panic("could not find virtio disk");
    800063a2:	00002517          	auipc	a0,0x2
    800063a6:	4de50513          	addi	a0,a0,1246 # 80008880 <syscalls+0x388>
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	190080e7          	jalr	400(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    800063b2:	00002517          	auipc	a0,0x2
    800063b6:	4ee50513          	addi	a0,a0,1262 # 800088a0 <syscalls+0x3a8>
    800063ba:	ffffa097          	auipc	ra,0xffffa
    800063be:	180080e7          	jalr	384(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    800063c2:	00002517          	auipc	a0,0x2
    800063c6:	4fe50513          	addi	a0,a0,1278 # 800088c0 <syscalls+0x3c8>
    800063ca:	ffffa097          	auipc	ra,0xffffa
    800063ce:	170080e7          	jalr	368(ra) # 8000053a <panic>

00000000800063d2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063d2:	7119                	addi	sp,sp,-128
    800063d4:	fc86                	sd	ra,120(sp)
    800063d6:	f8a2                	sd	s0,112(sp)
    800063d8:	f4a6                	sd	s1,104(sp)
    800063da:	f0ca                	sd	s2,96(sp)
    800063dc:	ecce                	sd	s3,88(sp)
    800063de:	e8d2                	sd	s4,80(sp)
    800063e0:	e4d6                	sd	s5,72(sp)
    800063e2:	e0da                	sd	s6,64(sp)
    800063e4:	fc5e                	sd	s7,56(sp)
    800063e6:	f862                	sd	s8,48(sp)
    800063e8:	f466                	sd	s9,40(sp)
    800063ea:	f06a                	sd	s10,32(sp)
    800063ec:	ec6e                	sd	s11,24(sp)
    800063ee:	0100                	addi	s0,sp,128
    800063f0:	8aaa                	mv	s5,a0
    800063f2:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063f4:	00c52c83          	lw	s9,12(a0)
    800063f8:	001c9c9b          	slliw	s9,s9,0x1
    800063fc:	1c82                	slli	s9,s9,0x20
    800063fe:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006402:	0001f517          	auipc	a0,0x1f
    80006406:	d2650513          	addi	a0,a0,-730 # 80025128 <disk+0x2128>
    8000640a:	ffffa097          	auipc	ra,0xffffa
    8000640e:	7c6080e7          	jalr	1990(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80006412:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006414:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006416:	0001dc17          	auipc	s8,0x1d
    8000641a:	beac0c13          	addi	s8,s8,-1046 # 80023000 <disk>
    8000641e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006420:	4b0d                	li	s6,3
    80006422:	a0ad                	j	8000648c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006424:	00fc0733          	add	a4,s8,a5
    80006428:	975e                	add	a4,a4,s7
    8000642a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000642e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006430:	0207c563          	bltz	a5,8000645a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006434:	2905                	addiw	s2,s2,1
    80006436:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006438:	19690c63          	beq	s2,s6,800065d0 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000643c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000643e:	0001f717          	auipc	a4,0x1f
    80006442:	bda70713          	addi	a4,a4,-1062 # 80025018 <disk+0x2018>
    80006446:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006448:	00074683          	lbu	a3,0(a4)
    8000644c:	fee1                	bnez	a3,80006424 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000644e:	2785                	addiw	a5,a5,1
    80006450:	0705                	addi	a4,a4,1
    80006452:	fe979be3          	bne	a5,s1,80006448 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006456:	57fd                	li	a5,-1
    80006458:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000645a:	01205d63          	blez	s2,80006474 <virtio_disk_rw+0xa2>
    8000645e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006460:	000a2503          	lw	a0,0(s4)
    80006464:	00000097          	auipc	ra,0x0
    80006468:	d92080e7          	jalr	-622(ra) # 800061f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000646c:	2d85                	addiw	s11,s11,1
    8000646e:	0a11                	addi	s4,s4,4
    80006470:	ff2d98e3          	bne	s11,s2,80006460 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006474:	0001f597          	auipc	a1,0x1f
    80006478:	cb458593          	addi	a1,a1,-844 # 80025128 <disk+0x2128>
    8000647c:	0001f517          	auipc	a0,0x1f
    80006480:	b9c50513          	addi	a0,a0,-1124 # 80025018 <disk+0x2018>
    80006484:	ffffc097          	auipc	ra,0xffffc
    80006488:	bfe080e7          	jalr	-1026(ra) # 80002082 <sleep>
  for(int i = 0; i < 3; i++){
    8000648c:	f8040a13          	addi	s4,s0,-128
{
    80006490:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006492:	894e                	mv	s2,s3
    80006494:	b765                	j	8000643c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006496:	0001f697          	auipc	a3,0x1f
    8000649a:	b6a6b683          	ld	a3,-1174(a3) # 80025000 <disk+0x2000>
    8000649e:	96ba                	add	a3,a3,a4
    800064a0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064a4:	0001d817          	auipc	a6,0x1d
    800064a8:	b5c80813          	addi	a6,a6,-1188 # 80023000 <disk>
    800064ac:	0001f697          	auipc	a3,0x1f
    800064b0:	b5468693          	addi	a3,a3,-1196 # 80025000 <disk+0x2000>
    800064b4:	6290                	ld	a2,0(a3)
    800064b6:	963a                	add	a2,a2,a4
    800064b8:	00c65583          	lhu	a1,12(a2)
    800064bc:	0015e593          	ori	a1,a1,1
    800064c0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800064c4:	f8842603          	lw	a2,-120(s0)
    800064c8:	628c                	ld	a1,0(a3)
    800064ca:	972e                	add	a4,a4,a1
    800064cc:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064d0:	20050593          	addi	a1,a0,512
    800064d4:	0592                	slli	a1,a1,0x4
    800064d6:	95c2                	add	a1,a1,a6
    800064d8:	577d                	li	a4,-1
    800064da:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064de:	00461713          	slli	a4,a2,0x4
    800064e2:	6290                	ld	a2,0(a3)
    800064e4:	963a                	add	a2,a2,a4
    800064e6:	03078793          	addi	a5,a5,48
    800064ea:	97c2                	add	a5,a5,a6
    800064ec:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800064ee:	629c                	ld	a5,0(a3)
    800064f0:	97ba                	add	a5,a5,a4
    800064f2:	4605                	li	a2,1
    800064f4:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064f6:	629c                	ld	a5,0(a3)
    800064f8:	97ba                	add	a5,a5,a4
    800064fa:	4809                	li	a6,2
    800064fc:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006500:	629c                	ld	a5,0(a3)
    80006502:	97ba                	add	a5,a5,a4
    80006504:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006508:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000650c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006510:	6698                	ld	a4,8(a3)
    80006512:	00275783          	lhu	a5,2(a4)
    80006516:	8b9d                	andi	a5,a5,7
    80006518:	0786                	slli	a5,a5,0x1
    8000651a:	973e                	add	a4,a4,a5
    8000651c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006520:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006524:	6698                	ld	a4,8(a3)
    80006526:	00275783          	lhu	a5,2(a4)
    8000652a:	2785                	addiw	a5,a5,1
    8000652c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006530:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006534:	100017b7          	lui	a5,0x10001
    80006538:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000653c:	004aa783          	lw	a5,4(s5)
    80006540:	02c79163          	bne	a5,a2,80006562 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006544:	0001f917          	auipc	s2,0x1f
    80006548:	be490913          	addi	s2,s2,-1052 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000654c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000654e:	85ca                	mv	a1,s2
    80006550:	8556                	mv	a0,s5
    80006552:	ffffc097          	auipc	ra,0xffffc
    80006556:	b30080e7          	jalr	-1232(ra) # 80002082 <sleep>
  while(b->disk == 1) {
    8000655a:	004aa783          	lw	a5,4(s5)
    8000655e:	fe9788e3          	beq	a5,s1,8000654e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006562:	f8042903          	lw	s2,-128(s0)
    80006566:	20090713          	addi	a4,s2,512
    8000656a:	0712                	slli	a4,a4,0x4
    8000656c:	0001d797          	auipc	a5,0x1d
    80006570:	a9478793          	addi	a5,a5,-1388 # 80023000 <disk>
    80006574:	97ba                	add	a5,a5,a4
    80006576:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000657a:	0001f997          	auipc	s3,0x1f
    8000657e:	a8698993          	addi	s3,s3,-1402 # 80025000 <disk+0x2000>
    80006582:	00491713          	slli	a4,s2,0x4
    80006586:	0009b783          	ld	a5,0(s3)
    8000658a:	97ba                	add	a5,a5,a4
    8000658c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006590:	854a                	mv	a0,s2
    80006592:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006596:	00000097          	auipc	ra,0x0
    8000659a:	c60080e7          	jalr	-928(ra) # 800061f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000659e:	8885                	andi	s1,s1,1
    800065a0:	f0ed                	bnez	s1,80006582 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065a2:	0001f517          	auipc	a0,0x1f
    800065a6:	b8650513          	addi	a0,a0,-1146 # 80025128 <disk+0x2128>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	6da080e7          	jalr	1754(ra) # 80000c84 <release>
}
    800065b2:	70e6                	ld	ra,120(sp)
    800065b4:	7446                	ld	s0,112(sp)
    800065b6:	74a6                	ld	s1,104(sp)
    800065b8:	7906                	ld	s2,96(sp)
    800065ba:	69e6                	ld	s3,88(sp)
    800065bc:	6a46                	ld	s4,80(sp)
    800065be:	6aa6                	ld	s5,72(sp)
    800065c0:	6b06                	ld	s6,64(sp)
    800065c2:	7be2                	ld	s7,56(sp)
    800065c4:	7c42                	ld	s8,48(sp)
    800065c6:	7ca2                	ld	s9,40(sp)
    800065c8:	7d02                	ld	s10,32(sp)
    800065ca:	6de2                	ld	s11,24(sp)
    800065cc:	6109                	addi	sp,sp,128
    800065ce:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065d0:	f8042503          	lw	a0,-128(s0)
    800065d4:	20050793          	addi	a5,a0,512
    800065d8:	0792                	slli	a5,a5,0x4
  if(write)
    800065da:	0001d817          	auipc	a6,0x1d
    800065de:	a2680813          	addi	a6,a6,-1498 # 80023000 <disk>
    800065e2:	00f80733          	add	a4,a6,a5
    800065e6:	01a036b3          	snez	a3,s10
    800065ea:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800065ee:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800065f2:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800065f6:	7679                	lui	a2,0xffffe
    800065f8:	963e                	add	a2,a2,a5
    800065fa:	0001f697          	auipc	a3,0x1f
    800065fe:	a0668693          	addi	a3,a3,-1530 # 80025000 <disk+0x2000>
    80006602:	6298                	ld	a4,0(a3)
    80006604:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006606:	0a878593          	addi	a1,a5,168
    8000660a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000660c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000660e:	6298                	ld	a4,0(a3)
    80006610:	9732                	add	a4,a4,a2
    80006612:	45c1                	li	a1,16
    80006614:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006616:	6298                	ld	a4,0(a3)
    80006618:	9732                	add	a4,a4,a2
    8000661a:	4585                	li	a1,1
    8000661c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006620:	f8442703          	lw	a4,-124(s0)
    80006624:	628c                	ld	a1,0(a3)
    80006626:	962e                	add	a2,a2,a1
    80006628:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000662c:	0712                	slli	a4,a4,0x4
    8000662e:	6290                	ld	a2,0(a3)
    80006630:	963a                	add	a2,a2,a4
    80006632:	058a8593          	addi	a1,s5,88
    80006636:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006638:	6294                	ld	a3,0(a3)
    8000663a:	96ba                	add	a3,a3,a4
    8000663c:	40000613          	li	a2,1024
    80006640:	c690                	sw	a2,8(a3)
  if(write)
    80006642:	e40d1ae3          	bnez	s10,80006496 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006646:	0001f697          	auipc	a3,0x1f
    8000664a:	9ba6b683          	ld	a3,-1606(a3) # 80025000 <disk+0x2000>
    8000664e:	96ba                	add	a3,a3,a4
    80006650:	4609                	li	a2,2
    80006652:	00c69623          	sh	a2,12(a3)
    80006656:	b5b9                	j	800064a4 <virtio_disk_rw+0xd2>

0000000080006658 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006658:	1101                	addi	sp,sp,-32
    8000665a:	ec06                	sd	ra,24(sp)
    8000665c:	e822                	sd	s0,16(sp)
    8000665e:	e426                	sd	s1,8(sp)
    80006660:	e04a                	sd	s2,0(sp)
    80006662:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006664:	0001f517          	auipc	a0,0x1f
    80006668:	ac450513          	addi	a0,a0,-1340 # 80025128 <disk+0x2128>
    8000666c:	ffffa097          	auipc	ra,0xffffa
    80006670:	564080e7          	jalr	1380(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006674:	10001737          	lui	a4,0x10001
    80006678:	533c                	lw	a5,96(a4)
    8000667a:	8b8d                	andi	a5,a5,3
    8000667c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000667e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006682:	0001f797          	auipc	a5,0x1f
    80006686:	97e78793          	addi	a5,a5,-1666 # 80025000 <disk+0x2000>
    8000668a:	6b94                	ld	a3,16(a5)
    8000668c:	0207d703          	lhu	a4,32(a5)
    80006690:	0026d783          	lhu	a5,2(a3)
    80006694:	06f70163          	beq	a4,a5,800066f6 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006698:	0001d917          	auipc	s2,0x1d
    8000669c:	96890913          	addi	s2,s2,-1688 # 80023000 <disk>
    800066a0:	0001f497          	auipc	s1,0x1f
    800066a4:	96048493          	addi	s1,s1,-1696 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800066a8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066ac:	6898                	ld	a4,16(s1)
    800066ae:	0204d783          	lhu	a5,32(s1)
    800066b2:	8b9d                	andi	a5,a5,7
    800066b4:	078e                	slli	a5,a5,0x3
    800066b6:	97ba                	add	a5,a5,a4
    800066b8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066ba:	20078713          	addi	a4,a5,512
    800066be:	0712                	slli	a4,a4,0x4
    800066c0:	974a                	add	a4,a4,s2
    800066c2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800066c6:	e731                	bnez	a4,80006712 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066c8:	20078793          	addi	a5,a5,512
    800066cc:	0792                	slli	a5,a5,0x4
    800066ce:	97ca                	add	a5,a5,s2
    800066d0:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800066d2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066d6:	ffffc097          	auipc	ra,0xffffc
    800066da:	b38080e7          	jalr	-1224(ra) # 8000220e <wakeup>

    disk.used_idx += 1;
    800066de:	0204d783          	lhu	a5,32(s1)
    800066e2:	2785                	addiw	a5,a5,1
    800066e4:	17c2                	slli	a5,a5,0x30
    800066e6:	93c1                	srli	a5,a5,0x30
    800066e8:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066ec:	6898                	ld	a4,16(s1)
    800066ee:	00275703          	lhu	a4,2(a4)
    800066f2:	faf71be3          	bne	a4,a5,800066a8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800066f6:	0001f517          	auipc	a0,0x1f
    800066fa:	a3250513          	addi	a0,a0,-1486 # 80025128 <disk+0x2128>
    800066fe:	ffffa097          	auipc	ra,0xffffa
    80006702:	586080e7          	jalr	1414(ra) # 80000c84 <release>
}
    80006706:	60e2                	ld	ra,24(sp)
    80006708:	6442                	ld	s0,16(sp)
    8000670a:	64a2                	ld	s1,8(sp)
    8000670c:	6902                	ld	s2,0(sp)
    8000670e:	6105                	addi	sp,sp,32
    80006710:	8082                	ret
      panic("virtio_disk_intr status");
    80006712:	00002517          	auipc	a0,0x2
    80006716:	1ce50513          	addi	a0,a0,462 # 800088e0 <syscalls+0x3e8>
    8000671a:	ffffa097          	auipc	ra,0xffffa
    8000671e:	e20080e7          	jalr	-480(ra) # 8000053a <panic>
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
