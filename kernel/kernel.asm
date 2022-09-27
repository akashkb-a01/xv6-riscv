
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	87013103          	ld	sp,-1936(sp) # 80008870 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000066:	b0e78793          	addi	a5,a5,-1266 # 80005b70 <timervec>
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
    80000ec4:	cf0080e7          	jalr	-784(ra) # 80005bb0 <plicinithart>
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
    80000f44:	c5a080e7          	jalr	-934(ra) # 80005b9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	c68080e7          	jalr	-920(ra) # 80005bb0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	e26080e7          	jalr	-474(ra) # 80002d76 <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	4b4080e7          	jalr	1204(ra) # 8000340c <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	466080e7          	jalr	1126(ra) # 800043c6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	d68080e7          	jalr	-664(ra) # 80005cd0 <virtio_disk_init>
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
    800019ea:	e3a7a783          	lw	a5,-454(a5) # 80008820 <first.1>
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
    80001a04:	e207a023          	sw	zero,-480(a5) # 80008820 <first.1>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	982080e7          	jalr	-1662(ra) # 8000338c <fsinit>
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
    80001a36:	df278793          	addi	a5,a5,-526 # 80008824 <nextpid>
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
    80001c92:	ba258593          	addi	a1,a1,-1118 # 80008830 <initcode>
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
    80001cd0:	0f6080e7          	jalr	246(ra) # 80003dc2 <namei>
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
    80001e1c:	640080e7          	jalr	1600(ra) # 80004458 <filedup>
    80001e20:	00a93023          	sd	a0,0(s2)
    80001e24:	b7e5                	j	80001e0c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e26:	150ab503          	ld	a0,336(s5)
    80001e2a:	00001097          	auipc	ra,0x1
    80001e2e:	79e080e7          	jalr	1950(ra) # 800035c8 <idup>
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
    800022fa:	1b4080e7          	jalr	436(ra) # 800044aa <fileclose>
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
    80002312:	cd4080e7          	jalr	-812(ra) # 80003fe2 <begin_op>
  iput(p->cwd);
    80002316:	1509b503          	ld	a0,336(s3)
    8000231a:	00001097          	auipc	ra,0x1
    8000231e:	4a6080e7          	jalr	1190(ra) # 800037c0 <iput>
  end_op();
    80002322:	00002097          	auipc	ra,0x2
    80002326:	d3e080e7          	jalr	-706(ra) # 80004060 <end_op>
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
    800025f6:	4ee78793          	addi	a5,a5,1262 # 80005ae0 <kernelvec>
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
    8000271e:	4ce080e7          	jalr	1230(ra) # 80005be8 <plic_claim>
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
    8000274c:	4c4080e7          	jalr	1220(ra) # 80005c0c <plic_complete>
    return 1;
    80002750:	4505                	li	a0,1
    80002752:	bf55                	j	80002706 <devintr+0x1e>
      uartintr();
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	23e080e7          	jalr	574(ra) # 80000992 <uartintr>
    8000275c:	b7ed                	j	80002746 <devintr+0x5e>
      virtio_disk_intr();
    8000275e:	00004097          	auipc	ra,0x4
    80002762:	93a080e7          	jalr	-1734(ra) # 80006098 <virtio_disk_intr>
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
    800027a4:	34078793          	addi	a5,a5,832 # 80005ae0 <kernelvec>
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
[SYS_yield]   sys_yield,
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
    80002ae4:	4759                	li	a4,22
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
    80002d6c:	4501                	li	a0,0
    80002d6e:	60a2                	ld	ra,8(sp)
    80002d70:	6402                	ld	s0,0(sp)
    80002d72:	0141                	addi	sp,sp,16
    80002d74:	8082                	ret

0000000080002d76 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d76:	7179                	addi	sp,sp,-48
    80002d78:	f406                	sd	ra,40(sp)
    80002d7a:	f022                	sd	s0,32(sp)
    80002d7c:	ec26                	sd	s1,24(sp)
    80002d7e:	e84a                	sd	s2,16(sp)
    80002d80:	e44e                	sd	s3,8(sp)
    80002d82:	e052                	sd	s4,0(sp)
    80002d84:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d86:	00005597          	auipc	a1,0x5
    80002d8a:	78258593          	addi	a1,a1,1922 # 80008508 <syscalls+0xc0>
    80002d8e:	00014517          	auipc	a0,0x14
    80002d92:	35a50513          	addi	a0,a0,858 # 800170e8 <bcache>
    80002d96:	ffffe097          	auipc	ra,0xffffe
    80002d9a:	daa080e7          	jalr	-598(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d9e:	0001c797          	auipc	a5,0x1c
    80002da2:	34a78793          	addi	a5,a5,842 # 8001f0e8 <bcache+0x8000>
    80002da6:	0001c717          	auipc	a4,0x1c
    80002daa:	5aa70713          	addi	a4,a4,1450 # 8001f350 <bcache+0x8268>
    80002dae:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002db2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002db6:	00014497          	auipc	s1,0x14
    80002dba:	34a48493          	addi	s1,s1,842 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002dbe:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002dc0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002dc2:	00005a17          	auipc	s4,0x5
    80002dc6:	74ea0a13          	addi	s4,s4,1870 # 80008510 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002dca:	2b893783          	ld	a5,696(s2)
    80002dce:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002dd0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002dd4:	85d2                	mv	a1,s4
    80002dd6:	01048513          	addi	a0,s1,16
    80002dda:	00001097          	auipc	ra,0x1
    80002dde:	4c2080e7          	jalr	1218(ra) # 8000429c <initsleeplock>
    bcache.head.next->prev = b;
    80002de2:	2b893783          	ld	a5,696(s2)
    80002de6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002de8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dec:	45848493          	addi	s1,s1,1112
    80002df0:	fd349de3          	bne	s1,s3,80002dca <binit+0x54>
  }
}
    80002df4:	70a2                	ld	ra,40(sp)
    80002df6:	7402                	ld	s0,32(sp)
    80002df8:	64e2                	ld	s1,24(sp)
    80002dfa:	6942                	ld	s2,16(sp)
    80002dfc:	69a2                	ld	s3,8(sp)
    80002dfe:	6a02                	ld	s4,0(sp)
    80002e00:	6145                	addi	sp,sp,48
    80002e02:	8082                	ret

0000000080002e04 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e04:	7179                	addi	sp,sp,-48
    80002e06:	f406                	sd	ra,40(sp)
    80002e08:	f022                	sd	s0,32(sp)
    80002e0a:	ec26                	sd	s1,24(sp)
    80002e0c:	e84a                	sd	s2,16(sp)
    80002e0e:	e44e                	sd	s3,8(sp)
    80002e10:	1800                	addi	s0,sp,48
    80002e12:	892a                	mv	s2,a0
    80002e14:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e16:	00014517          	auipc	a0,0x14
    80002e1a:	2d250513          	addi	a0,a0,722 # 800170e8 <bcache>
    80002e1e:	ffffe097          	auipc	ra,0xffffe
    80002e22:	db2080e7          	jalr	-590(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e26:	0001c497          	auipc	s1,0x1c
    80002e2a:	57a4b483          	ld	s1,1402(s1) # 8001f3a0 <bcache+0x82b8>
    80002e2e:	0001c797          	auipc	a5,0x1c
    80002e32:	52278793          	addi	a5,a5,1314 # 8001f350 <bcache+0x8268>
    80002e36:	02f48f63          	beq	s1,a5,80002e74 <bread+0x70>
    80002e3a:	873e                	mv	a4,a5
    80002e3c:	a021                	j	80002e44 <bread+0x40>
    80002e3e:	68a4                	ld	s1,80(s1)
    80002e40:	02e48a63          	beq	s1,a4,80002e74 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e44:	449c                	lw	a5,8(s1)
    80002e46:	ff279ce3          	bne	a5,s2,80002e3e <bread+0x3a>
    80002e4a:	44dc                	lw	a5,12(s1)
    80002e4c:	ff3799e3          	bne	a5,s3,80002e3e <bread+0x3a>
      b->refcnt++;
    80002e50:	40bc                	lw	a5,64(s1)
    80002e52:	2785                	addiw	a5,a5,1
    80002e54:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e56:	00014517          	auipc	a0,0x14
    80002e5a:	29250513          	addi	a0,a0,658 # 800170e8 <bcache>
    80002e5e:	ffffe097          	auipc	ra,0xffffe
    80002e62:	e26080e7          	jalr	-474(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002e66:	01048513          	addi	a0,s1,16
    80002e6a:	00001097          	auipc	ra,0x1
    80002e6e:	46c080e7          	jalr	1132(ra) # 800042d6 <acquiresleep>
      return b;
    80002e72:	a8b9                	j	80002ed0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e74:	0001c497          	auipc	s1,0x1c
    80002e78:	5244b483          	ld	s1,1316(s1) # 8001f398 <bcache+0x82b0>
    80002e7c:	0001c797          	auipc	a5,0x1c
    80002e80:	4d478793          	addi	a5,a5,1236 # 8001f350 <bcache+0x8268>
    80002e84:	00f48863          	beq	s1,a5,80002e94 <bread+0x90>
    80002e88:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e8a:	40bc                	lw	a5,64(s1)
    80002e8c:	cf81                	beqz	a5,80002ea4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e8e:	64a4                	ld	s1,72(s1)
    80002e90:	fee49de3          	bne	s1,a4,80002e8a <bread+0x86>
  panic("bget: no buffers");
    80002e94:	00005517          	auipc	a0,0x5
    80002e98:	68450513          	addi	a0,a0,1668 # 80008518 <syscalls+0xd0>
    80002e9c:	ffffd097          	auipc	ra,0xffffd
    80002ea0:	69e080e7          	jalr	1694(ra) # 8000053a <panic>
      b->dev = dev;
    80002ea4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002ea8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002eac:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002eb0:	4785                	li	a5,1
    80002eb2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002eb4:	00014517          	auipc	a0,0x14
    80002eb8:	23450513          	addi	a0,a0,564 # 800170e8 <bcache>
    80002ebc:	ffffe097          	auipc	ra,0xffffe
    80002ec0:	dc8080e7          	jalr	-568(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002ec4:	01048513          	addi	a0,s1,16
    80002ec8:	00001097          	auipc	ra,0x1
    80002ecc:	40e080e7          	jalr	1038(ra) # 800042d6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ed0:	409c                	lw	a5,0(s1)
    80002ed2:	cb89                	beqz	a5,80002ee4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ed4:	8526                	mv	a0,s1
    80002ed6:	70a2                	ld	ra,40(sp)
    80002ed8:	7402                	ld	s0,32(sp)
    80002eda:	64e2                	ld	s1,24(sp)
    80002edc:	6942                	ld	s2,16(sp)
    80002ede:	69a2                	ld	s3,8(sp)
    80002ee0:	6145                	addi	sp,sp,48
    80002ee2:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ee4:	4581                	li	a1,0
    80002ee6:	8526                	mv	a0,s1
    80002ee8:	00003097          	auipc	ra,0x3
    80002eec:	f2a080e7          	jalr	-214(ra) # 80005e12 <virtio_disk_rw>
    b->valid = 1;
    80002ef0:	4785                	li	a5,1
    80002ef2:	c09c                	sw	a5,0(s1)
  return b;
    80002ef4:	b7c5                	j	80002ed4 <bread+0xd0>

0000000080002ef6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ef6:	1101                	addi	sp,sp,-32
    80002ef8:	ec06                	sd	ra,24(sp)
    80002efa:	e822                	sd	s0,16(sp)
    80002efc:	e426                	sd	s1,8(sp)
    80002efe:	1000                	addi	s0,sp,32
    80002f00:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f02:	0541                	addi	a0,a0,16
    80002f04:	00001097          	auipc	ra,0x1
    80002f08:	46c080e7          	jalr	1132(ra) # 80004370 <holdingsleep>
    80002f0c:	cd01                	beqz	a0,80002f24 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f0e:	4585                	li	a1,1
    80002f10:	8526                	mv	a0,s1
    80002f12:	00003097          	auipc	ra,0x3
    80002f16:	f00080e7          	jalr	-256(ra) # 80005e12 <virtio_disk_rw>
}
    80002f1a:	60e2                	ld	ra,24(sp)
    80002f1c:	6442                	ld	s0,16(sp)
    80002f1e:	64a2                	ld	s1,8(sp)
    80002f20:	6105                	addi	sp,sp,32
    80002f22:	8082                	ret
    panic("bwrite");
    80002f24:	00005517          	auipc	a0,0x5
    80002f28:	60c50513          	addi	a0,a0,1548 # 80008530 <syscalls+0xe8>
    80002f2c:	ffffd097          	auipc	ra,0xffffd
    80002f30:	60e080e7          	jalr	1550(ra) # 8000053a <panic>

0000000080002f34 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f34:	1101                	addi	sp,sp,-32
    80002f36:	ec06                	sd	ra,24(sp)
    80002f38:	e822                	sd	s0,16(sp)
    80002f3a:	e426                	sd	s1,8(sp)
    80002f3c:	e04a                	sd	s2,0(sp)
    80002f3e:	1000                	addi	s0,sp,32
    80002f40:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f42:	01050913          	addi	s2,a0,16
    80002f46:	854a                	mv	a0,s2
    80002f48:	00001097          	auipc	ra,0x1
    80002f4c:	428080e7          	jalr	1064(ra) # 80004370 <holdingsleep>
    80002f50:	c92d                	beqz	a0,80002fc2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f52:	854a                	mv	a0,s2
    80002f54:	00001097          	auipc	ra,0x1
    80002f58:	3d8080e7          	jalr	984(ra) # 8000432c <releasesleep>

  acquire(&bcache.lock);
    80002f5c:	00014517          	auipc	a0,0x14
    80002f60:	18c50513          	addi	a0,a0,396 # 800170e8 <bcache>
    80002f64:	ffffe097          	auipc	ra,0xffffe
    80002f68:	c6c080e7          	jalr	-916(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80002f6c:	40bc                	lw	a5,64(s1)
    80002f6e:	37fd                	addiw	a5,a5,-1
    80002f70:	0007871b          	sext.w	a4,a5
    80002f74:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f76:	eb05                	bnez	a4,80002fa6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f78:	68bc                	ld	a5,80(s1)
    80002f7a:	64b8                	ld	a4,72(s1)
    80002f7c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f7e:	64bc                	ld	a5,72(s1)
    80002f80:	68b8                	ld	a4,80(s1)
    80002f82:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f84:	0001c797          	auipc	a5,0x1c
    80002f88:	16478793          	addi	a5,a5,356 # 8001f0e8 <bcache+0x8000>
    80002f8c:	2b87b703          	ld	a4,696(a5)
    80002f90:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f92:	0001c717          	auipc	a4,0x1c
    80002f96:	3be70713          	addi	a4,a4,958 # 8001f350 <bcache+0x8268>
    80002f9a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f9c:	2b87b703          	ld	a4,696(a5)
    80002fa0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fa2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fa6:	00014517          	auipc	a0,0x14
    80002faa:	14250513          	addi	a0,a0,322 # 800170e8 <bcache>
    80002fae:	ffffe097          	auipc	ra,0xffffe
    80002fb2:	cd6080e7          	jalr	-810(ra) # 80000c84 <release>
}
    80002fb6:	60e2                	ld	ra,24(sp)
    80002fb8:	6442                	ld	s0,16(sp)
    80002fba:	64a2                	ld	s1,8(sp)
    80002fbc:	6902                	ld	s2,0(sp)
    80002fbe:	6105                	addi	sp,sp,32
    80002fc0:	8082                	ret
    panic("brelse");
    80002fc2:	00005517          	auipc	a0,0x5
    80002fc6:	57650513          	addi	a0,a0,1398 # 80008538 <syscalls+0xf0>
    80002fca:	ffffd097          	auipc	ra,0xffffd
    80002fce:	570080e7          	jalr	1392(ra) # 8000053a <panic>

0000000080002fd2 <bpin>:

void
bpin(struct buf *b) {
    80002fd2:	1101                	addi	sp,sp,-32
    80002fd4:	ec06                	sd	ra,24(sp)
    80002fd6:	e822                	sd	s0,16(sp)
    80002fd8:	e426                	sd	s1,8(sp)
    80002fda:	1000                	addi	s0,sp,32
    80002fdc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fde:	00014517          	auipc	a0,0x14
    80002fe2:	10a50513          	addi	a0,a0,266 # 800170e8 <bcache>
    80002fe6:	ffffe097          	auipc	ra,0xffffe
    80002fea:	bea080e7          	jalr	-1046(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80002fee:	40bc                	lw	a5,64(s1)
    80002ff0:	2785                	addiw	a5,a5,1
    80002ff2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002ff4:	00014517          	auipc	a0,0x14
    80002ff8:	0f450513          	addi	a0,a0,244 # 800170e8 <bcache>
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	c88080e7          	jalr	-888(ra) # 80000c84 <release>
}
    80003004:	60e2                	ld	ra,24(sp)
    80003006:	6442                	ld	s0,16(sp)
    80003008:	64a2                	ld	s1,8(sp)
    8000300a:	6105                	addi	sp,sp,32
    8000300c:	8082                	ret

000000008000300e <bunpin>:

void
bunpin(struct buf *b) {
    8000300e:	1101                	addi	sp,sp,-32
    80003010:	ec06                	sd	ra,24(sp)
    80003012:	e822                	sd	s0,16(sp)
    80003014:	e426                	sd	s1,8(sp)
    80003016:	1000                	addi	s0,sp,32
    80003018:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000301a:	00014517          	auipc	a0,0x14
    8000301e:	0ce50513          	addi	a0,a0,206 # 800170e8 <bcache>
    80003022:	ffffe097          	auipc	ra,0xffffe
    80003026:	bae080e7          	jalr	-1106(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000302a:	40bc                	lw	a5,64(s1)
    8000302c:	37fd                	addiw	a5,a5,-1
    8000302e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003030:	00014517          	auipc	a0,0x14
    80003034:	0b850513          	addi	a0,a0,184 # 800170e8 <bcache>
    80003038:	ffffe097          	auipc	ra,0xffffe
    8000303c:	c4c080e7          	jalr	-948(ra) # 80000c84 <release>
}
    80003040:	60e2                	ld	ra,24(sp)
    80003042:	6442                	ld	s0,16(sp)
    80003044:	64a2                	ld	s1,8(sp)
    80003046:	6105                	addi	sp,sp,32
    80003048:	8082                	ret

000000008000304a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000304a:	1101                	addi	sp,sp,-32
    8000304c:	ec06                	sd	ra,24(sp)
    8000304e:	e822                	sd	s0,16(sp)
    80003050:	e426                	sd	s1,8(sp)
    80003052:	e04a                	sd	s2,0(sp)
    80003054:	1000                	addi	s0,sp,32
    80003056:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003058:	00d5d59b          	srliw	a1,a1,0xd
    8000305c:	0001c797          	auipc	a5,0x1c
    80003060:	7687a783          	lw	a5,1896(a5) # 8001f7c4 <sb+0x1c>
    80003064:	9dbd                	addw	a1,a1,a5
    80003066:	00000097          	auipc	ra,0x0
    8000306a:	d9e080e7          	jalr	-610(ra) # 80002e04 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000306e:	0074f713          	andi	a4,s1,7
    80003072:	4785                	li	a5,1
    80003074:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003078:	14ce                	slli	s1,s1,0x33
    8000307a:	90d9                	srli	s1,s1,0x36
    8000307c:	00950733          	add	a4,a0,s1
    80003080:	05874703          	lbu	a4,88(a4)
    80003084:	00e7f6b3          	and	a3,a5,a4
    80003088:	c69d                	beqz	a3,800030b6 <bfree+0x6c>
    8000308a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000308c:	94aa                	add	s1,s1,a0
    8000308e:	fff7c793          	not	a5,a5
    80003092:	8f7d                	and	a4,a4,a5
    80003094:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003098:	00001097          	auipc	ra,0x1
    8000309c:	120080e7          	jalr	288(ra) # 800041b8 <log_write>
  brelse(bp);
    800030a0:	854a                	mv	a0,s2
    800030a2:	00000097          	auipc	ra,0x0
    800030a6:	e92080e7          	jalr	-366(ra) # 80002f34 <brelse>
}
    800030aa:	60e2                	ld	ra,24(sp)
    800030ac:	6442                	ld	s0,16(sp)
    800030ae:	64a2                	ld	s1,8(sp)
    800030b0:	6902                	ld	s2,0(sp)
    800030b2:	6105                	addi	sp,sp,32
    800030b4:	8082                	ret
    panic("freeing free block");
    800030b6:	00005517          	auipc	a0,0x5
    800030ba:	48a50513          	addi	a0,a0,1162 # 80008540 <syscalls+0xf8>
    800030be:	ffffd097          	auipc	ra,0xffffd
    800030c2:	47c080e7          	jalr	1148(ra) # 8000053a <panic>

00000000800030c6 <balloc>:
{
    800030c6:	711d                	addi	sp,sp,-96
    800030c8:	ec86                	sd	ra,88(sp)
    800030ca:	e8a2                	sd	s0,80(sp)
    800030cc:	e4a6                	sd	s1,72(sp)
    800030ce:	e0ca                	sd	s2,64(sp)
    800030d0:	fc4e                	sd	s3,56(sp)
    800030d2:	f852                	sd	s4,48(sp)
    800030d4:	f456                	sd	s5,40(sp)
    800030d6:	f05a                	sd	s6,32(sp)
    800030d8:	ec5e                	sd	s7,24(sp)
    800030da:	e862                	sd	s8,16(sp)
    800030dc:	e466                	sd	s9,8(sp)
    800030de:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030e0:	0001c797          	auipc	a5,0x1c
    800030e4:	6cc7a783          	lw	a5,1740(a5) # 8001f7ac <sb+0x4>
    800030e8:	cbc1                	beqz	a5,80003178 <balloc+0xb2>
    800030ea:	8baa                	mv	s7,a0
    800030ec:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030ee:	0001cb17          	auipc	s6,0x1c
    800030f2:	6bab0b13          	addi	s6,s6,1722 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030f6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030f8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030fa:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030fc:	6c89                	lui	s9,0x2
    800030fe:	a831                	j	8000311a <balloc+0x54>
    brelse(bp);
    80003100:	854a                	mv	a0,s2
    80003102:	00000097          	auipc	ra,0x0
    80003106:	e32080e7          	jalr	-462(ra) # 80002f34 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000310a:	015c87bb          	addw	a5,s9,s5
    8000310e:	00078a9b          	sext.w	s5,a5
    80003112:	004b2703          	lw	a4,4(s6)
    80003116:	06eaf163          	bgeu	s5,a4,80003178 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000311a:	41fad79b          	sraiw	a5,s5,0x1f
    8000311e:	0137d79b          	srliw	a5,a5,0x13
    80003122:	015787bb          	addw	a5,a5,s5
    80003126:	40d7d79b          	sraiw	a5,a5,0xd
    8000312a:	01cb2583          	lw	a1,28(s6)
    8000312e:	9dbd                	addw	a1,a1,a5
    80003130:	855e                	mv	a0,s7
    80003132:	00000097          	auipc	ra,0x0
    80003136:	cd2080e7          	jalr	-814(ra) # 80002e04 <bread>
    8000313a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000313c:	004b2503          	lw	a0,4(s6)
    80003140:	000a849b          	sext.w	s1,s5
    80003144:	8762                	mv	a4,s8
    80003146:	faa4fde3          	bgeu	s1,a0,80003100 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000314a:	00777693          	andi	a3,a4,7
    8000314e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003152:	41f7579b          	sraiw	a5,a4,0x1f
    80003156:	01d7d79b          	srliw	a5,a5,0x1d
    8000315a:	9fb9                	addw	a5,a5,a4
    8000315c:	4037d79b          	sraiw	a5,a5,0x3
    80003160:	00f90633          	add	a2,s2,a5
    80003164:	05864603          	lbu	a2,88(a2)
    80003168:	00c6f5b3          	and	a1,a3,a2
    8000316c:	cd91                	beqz	a1,80003188 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000316e:	2705                	addiw	a4,a4,1
    80003170:	2485                	addiw	s1,s1,1
    80003172:	fd471ae3          	bne	a4,s4,80003146 <balloc+0x80>
    80003176:	b769                	j	80003100 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003178:	00005517          	auipc	a0,0x5
    8000317c:	3e050513          	addi	a0,a0,992 # 80008558 <syscalls+0x110>
    80003180:	ffffd097          	auipc	ra,0xffffd
    80003184:	3ba080e7          	jalr	954(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003188:	97ca                	add	a5,a5,s2
    8000318a:	8e55                	or	a2,a2,a3
    8000318c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003190:	854a                	mv	a0,s2
    80003192:	00001097          	auipc	ra,0x1
    80003196:	026080e7          	jalr	38(ra) # 800041b8 <log_write>
        brelse(bp);
    8000319a:	854a                	mv	a0,s2
    8000319c:	00000097          	auipc	ra,0x0
    800031a0:	d98080e7          	jalr	-616(ra) # 80002f34 <brelse>
  bp = bread(dev, bno);
    800031a4:	85a6                	mv	a1,s1
    800031a6:	855e                	mv	a0,s7
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	c5c080e7          	jalr	-932(ra) # 80002e04 <bread>
    800031b0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031b2:	40000613          	li	a2,1024
    800031b6:	4581                	li	a1,0
    800031b8:	05850513          	addi	a0,a0,88
    800031bc:	ffffe097          	auipc	ra,0xffffe
    800031c0:	b10080e7          	jalr	-1264(ra) # 80000ccc <memset>
  log_write(bp);
    800031c4:	854a                	mv	a0,s2
    800031c6:	00001097          	auipc	ra,0x1
    800031ca:	ff2080e7          	jalr	-14(ra) # 800041b8 <log_write>
  brelse(bp);
    800031ce:	854a                	mv	a0,s2
    800031d0:	00000097          	auipc	ra,0x0
    800031d4:	d64080e7          	jalr	-668(ra) # 80002f34 <brelse>
}
    800031d8:	8526                	mv	a0,s1
    800031da:	60e6                	ld	ra,88(sp)
    800031dc:	6446                	ld	s0,80(sp)
    800031de:	64a6                	ld	s1,72(sp)
    800031e0:	6906                	ld	s2,64(sp)
    800031e2:	79e2                	ld	s3,56(sp)
    800031e4:	7a42                	ld	s4,48(sp)
    800031e6:	7aa2                	ld	s5,40(sp)
    800031e8:	7b02                	ld	s6,32(sp)
    800031ea:	6be2                	ld	s7,24(sp)
    800031ec:	6c42                	ld	s8,16(sp)
    800031ee:	6ca2                	ld	s9,8(sp)
    800031f0:	6125                	addi	sp,sp,96
    800031f2:	8082                	ret

00000000800031f4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031f4:	7179                	addi	sp,sp,-48
    800031f6:	f406                	sd	ra,40(sp)
    800031f8:	f022                	sd	s0,32(sp)
    800031fa:	ec26                	sd	s1,24(sp)
    800031fc:	e84a                	sd	s2,16(sp)
    800031fe:	e44e                	sd	s3,8(sp)
    80003200:	e052                	sd	s4,0(sp)
    80003202:	1800                	addi	s0,sp,48
    80003204:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003206:	47ad                	li	a5,11
    80003208:	04b7fe63          	bgeu	a5,a1,80003264 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000320c:	ff45849b          	addiw	s1,a1,-12
    80003210:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003214:	0ff00793          	li	a5,255
    80003218:	0ae7e463          	bltu	a5,a4,800032c0 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000321c:	08052583          	lw	a1,128(a0)
    80003220:	c5b5                	beqz	a1,8000328c <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003222:	00092503          	lw	a0,0(s2)
    80003226:	00000097          	auipc	ra,0x0
    8000322a:	bde080e7          	jalr	-1058(ra) # 80002e04 <bread>
    8000322e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003230:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003234:	02049713          	slli	a4,s1,0x20
    80003238:	01e75593          	srli	a1,a4,0x1e
    8000323c:	00b784b3          	add	s1,a5,a1
    80003240:	0004a983          	lw	s3,0(s1)
    80003244:	04098e63          	beqz	s3,800032a0 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003248:	8552                	mv	a0,s4
    8000324a:	00000097          	auipc	ra,0x0
    8000324e:	cea080e7          	jalr	-790(ra) # 80002f34 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003252:	854e                	mv	a0,s3
    80003254:	70a2                	ld	ra,40(sp)
    80003256:	7402                	ld	s0,32(sp)
    80003258:	64e2                	ld	s1,24(sp)
    8000325a:	6942                	ld	s2,16(sp)
    8000325c:	69a2                	ld	s3,8(sp)
    8000325e:	6a02                	ld	s4,0(sp)
    80003260:	6145                	addi	sp,sp,48
    80003262:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003264:	02059793          	slli	a5,a1,0x20
    80003268:	01e7d593          	srli	a1,a5,0x1e
    8000326c:	00b504b3          	add	s1,a0,a1
    80003270:	0504a983          	lw	s3,80(s1)
    80003274:	fc099fe3          	bnez	s3,80003252 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003278:	4108                	lw	a0,0(a0)
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	e4c080e7          	jalr	-436(ra) # 800030c6 <balloc>
    80003282:	0005099b          	sext.w	s3,a0
    80003286:	0534a823          	sw	s3,80(s1)
    8000328a:	b7e1                	j	80003252 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000328c:	4108                	lw	a0,0(a0)
    8000328e:	00000097          	auipc	ra,0x0
    80003292:	e38080e7          	jalr	-456(ra) # 800030c6 <balloc>
    80003296:	0005059b          	sext.w	a1,a0
    8000329a:	08b92023          	sw	a1,128(s2)
    8000329e:	b751                	j	80003222 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032a0:	00092503          	lw	a0,0(s2)
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	e22080e7          	jalr	-478(ra) # 800030c6 <balloc>
    800032ac:	0005099b          	sext.w	s3,a0
    800032b0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032b4:	8552                	mv	a0,s4
    800032b6:	00001097          	auipc	ra,0x1
    800032ba:	f02080e7          	jalr	-254(ra) # 800041b8 <log_write>
    800032be:	b769                	j	80003248 <bmap+0x54>
  panic("bmap: out of range");
    800032c0:	00005517          	auipc	a0,0x5
    800032c4:	2b050513          	addi	a0,a0,688 # 80008570 <syscalls+0x128>
    800032c8:	ffffd097          	auipc	ra,0xffffd
    800032cc:	272080e7          	jalr	626(ra) # 8000053a <panic>

00000000800032d0 <iget>:
{
    800032d0:	7179                	addi	sp,sp,-48
    800032d2:	f406                	sd	ra,40(sp)
    800032d4:	f022                	sd	s0,32(sp)
    800032d6:	ec26                	sd	s1,24(sp)
    800032d8:	e84a                	sd	s2,16(sp)
    800032da:	e44e                	sd	s3,8(sp)
    800032dc:	e052                	sd	s4,0(sp)
    800032de:	1800                	addi	s0,sp,48
    800032e0:	89aa                	mv	s3,a0
    800032e2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800032e4:	0001c517          	auipc	a0,0x1c
    800032e8:	4e450513          	addi	a0,a0,1252 # 8001f7c8 <itable>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	8e4080e7          	jalr	-1820(ra) # 80000bd0 <acquire>
  empty = 0;
    800032f4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032f6:	0001c497          	auipc	s1,0x1c
    800032fa:	4ea48493          	addi	s1,s1,1258 # 8001f7e0 <itable+0x18>
    800032fe:	0001e697          	auipc	a3,0x1e
    80003302:	f7268693          	addi	a3,a3,-142 # 80021270 <log>
    80003306:	a039                	j	80003314 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003308:	02090b63          	beqz	s2,8000333e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000330c:	08848493          	addi	s1,s1,136
    80003310:	02d48a63          	beq	s1,a3,80003344 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003314:	449c                	lw	a5,8(s1)
    80003316:	fef059e3          	blez	a5,80003308 <iget+0x38>
    8000331a:	4098                	lw	a4,0(s1)
    8000331c:	ff3716e3          	bne	a4,s3,80003308 <iget+0x38>
    80003320:	40d8                	lw	a4,4(s1)
    80003322:	ff4713e3          	bne	a4,s4,80003308 <iget+0x38>
      ip->ref++;
    80003326:	2785                	addiw	a5,a5,1
    80003328:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000332a:	0001c517          	auipc	a0,0x1c
    8000332e:	49e50513          	addi	a0,a0,1182 # 8001f7c8 <itable>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	952080e7          	jalr	-1710(ra) # 80000c84 <release>
      return ip;
    8000333a:	8926                	mv	s2,s1
    8000333c:	a03d                	j	8000336a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000333e:	f7f9                	bnez	a5,8000330c <iget+0x3c>
    80003340:	8926                	mv	s2,s1
    80003342:	b7e9                	j	8000330c <iget+0x3c>
  if(empty == 0)
    80003344:	02090c63          	beqz	s2,8000337c <iget+0xac>
  ip->dev = dev;
    80003348:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000334c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003350:	4785                	li	a5,1
    80003352:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003356:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000335a:	0001c517          	auipc	a0,0x1c
    8000335e:	46e50513          	addi	a0,a0,1134 # 8001f7c8 <itable>
    80003362:	ffffe097          	auipc	ra,0xffffe
    80003366:	922080e7          	jalr	-1758(ra) # 80000c84 <release>
}
    8000336a:	854a                	mv	a0,s2
    8000336c:	70a2                	ld	ra,40(sp)
    8000336e:	7402                	ld	s0,32(sp)
    80003370:	64e2                	ld	s1,24(sp)
    80003372:	6942                	ld	s2,16(sp)
    80003374:	69a2                	ld	s3,8(sp)
    80003376:	6a02                	ld	s4,0(sp)
    80003378:	6145                	addi	sp,sp,48
    8000337a:	8082                	ret
    panic("iget: no inodes");
    8000337c:	00005517          	auipc	a0,0x5
    80003380:	20c50513          	addi	a0,a0,524 # 80008588 <syscalls+0x140>
    80003384:	ffffd097          	auipc	ra,0xffffd
    80003388:	1b6080e7          	jalr	438(ra) # 8000053a <panic>

000000008000338c <fsinit>:
fsinit(int dev) {
    8000338c:	7179                	addi	sp,sp,-48
    8000338e:	f406                	sd	ra,40(sp)
    80003390:	f022                	sd	s0,32(sp)
    80003392:	ec26                	sd	s1,24(sp)
    80003394:	e84a                	sd	s2,16(sp)
    80003396:	e44e                	sd	s3,8(sp)
    80003398:	1800                	addi	s0,sp,48
    8000339a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000339c:	4585                	li	a1,1
    8000339e:	00000097          	auipc	ra,0x0
    800033a2:	a66080e7          	jalr	-1434(ra) # 80002e04 <bread>
    800033a6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033a8:	0001c997          	auipc	s3,0x1c
    800033ac:	40098993          	addi	s3,s3,1024 # 8001f7a8 <sb>
    800033b0:	02000613          	li	a2,32
    800033b4:	05850593          	addi	a1,a0,88
    800033b8:	854e                	mv	a0,s3
    800033ba:	ffffe097          	auipc	ra,0xffffe
    800033be:	96e080e7          	jalr	-1682(ra) # 80000d28 <memmove>
  brelse(bp);
    800033c2:	8526                	mv	a0,s1
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	b70080e7          	jalr	-1168(ra) # 80002f34 <brelse>
  if(sb.magic != FSMAGIC)
    800033cc:	0009a703          	lw	a4,0(s3)
    800033d0:	102037b7          	lui	a5,0x10203
    800033d4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033d8:	02f71263          	bne	a4,a5,800033fc <fsinit+0x70>
  initlog(dev, &sb);
    800033dc:	0001c597          	auipc	a1,0x1c
    800033e0:	3cc58593          	addi	a1,a1,972 # 8001f7a8 <sb>
    800033e4:	854a                	mv	a0,s2
    800033e6:	00001097          	auipc	ra,0x1
    800033ea:	b56080e7          	jalr	-1194(ra) # 80003f3c <initlog>
}
    800033ee:	70a2                	ld	ra,40(sp)
    800033f0:	7402                	ld	s0,32(sp)
    800033f2:	64e2                	ld	s1,24(sp)
    800033f4:	6942                	ld	s2,16(sp)
    800033f6:	69a2                	ld	s3,8(sp)
    800033f8:	6145                	addi	sp,sp,48
    800033fa:	8082                	ret
    panic("invalid file system");
    800033fc:	00005517          	auipc	a0,0x5
    80003400:	19c50513          	addi	a0,a0,412 # 80008598 <syscalls+0x150>
    80003404:	ffffd097          	auipc	ra,0xffffd
    80003408:	136080e7          	jalr	310(ra) # 8000053a <panic>

000000008000340c <iinit>:
{
    8000340c:	7179                	addi	sp,sp,-48
    8000340e:	f406                	sd	ra,40(sp)
    80003410:	f022                	sd	s0,32(sp)
    80003412:	ec26                	sd	s1,24(sp)
    80003414:	e84a                	sd	s2,16(sp)
    80003416:	e44e                	sd	s3,8(sp)
    80003418:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000341a:	00005597          	auipc	a1,0x5
    8000341e:	19658593          	addi	a1,a1,406 # 800085b0 <syscalls+0x168>
    80003422:	0001c517          	auipc	a0,0x1c
    80003426:	3a650513          	addi	a0,a0,934 # 8001f7c8 <itable>
    8000342a:	ffffd097          	auipc	ra,0xffffd
    8000342e:	716080e7          	jalr	1814(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003432:	0001c497          	auipc	s1,0x1c
    80003436:	3be48493          	addi	s1,s1,958 # 8001f7f0 <itable+0x28>
    8000343a:	0001e997          	auipc	s3,0x1e
    8000343e:	e4698993          	addi	s3,s3,-442 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003442:	00005917          	auipc	s2,0x5
    80003446:	17690913          	addi	s2,s2,374 # 800085b8 <syscalls+0x170>
    8000344a:	85ca                	mv	a1,s2
    8000344c:	8526                	mv	a0,s1
    8000344e:	00001097          	auipc	ra,0x1
    80003452:	e4e080e7          	jalr	-434(ra) # 8000429c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003456:	08848493          	addi	s1,s1,136
    8000345a:	ff3498e3          	bne	s1,s3,8000344a <iinit+0x3e>
}
    8000345e:	70a2                	ld	ra,40(sp)
    80003460:	7402                	ld	s0,32(sp)
    80003462:	64e2                	ld	s1,24(sp)
    80003464:	6942                	ld	s2,16(sp)
    80003466:	69a2                	ld	s3,8(sp)
    80003468:	6145                	addi	sp,sp,48
    8000346a:	8082                	ret

000000008000346c <ialloc>:
{
    8000346c:	715d                	addi	sp,sp,-80
    8000346e:	e486                	sd	ra,72(sp)
    80003470:	e0a2                	sd	s0,64(sp)
    80003472:	fc26                	sd	s1,56(sp)
    80003474:	f84a                	sd	s2,48(sp)
    80003476:	f44e                	sd	s3,40(sp)
    80003478:	f052                	sd	s4,32(sp)
    8000347a:	ec56                	sd	s5,24(sp)
    8000347c:	e85a                	sd	s6,16(sp)
    8000347e:	e45e                	sd	s7,8(sp)
    80003480:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003482:	0001c717          	auipc	a4,0x1c
    80003486:	33272703          	lw	a4,818(a4) # 8001f7b4 <sb+0xc>
    8000348a:	4785                	li	a5,1
    8000348c:	04e7fa63          	bgeu	a5,a4,800034e0 <ialloc+0x74>
    80003490:	8aaa                	mv	s5,a0
    80003492:	8bae                	mv	s7,a1
    80003494:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003496:	0001ca17          	auipc	s4,0x1c
    8000349a:	312a0a13          	addi	s4,s4,786 # 8001f7a8 <sb>
    8000349e:	00048b1b          	sext.w	s6,s1
    800034a2:	0044d593          	srli	a1,s1,0x4
    800034a6:	018a2783          	lw	a5,24(s4)
    800034aa:	9dbd                	addw	a1,a1,a5
    800034ac:	8556                	mv	a0,s5
    800034ae:	00000097          	auipc	ra,0x0
    800034b2:	956080e7          	jalr	-1706(ra) # 80002e04 <bread>
    800034b6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034b8:	05850993          	addi	s3,a0,88
    800034bc:	00f4f793          	andi	a5,s1,15
    800034c0:	079a                	slli	a5,a5,0x6
    800034c2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034c4:	00099783          	lh	a5,0(s3)
    800034c8:	c785                	beqz	a5,800034f0 <ialloc+0x84>
    brelse(bp);
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	a6a080e7          	jalr	-1430(ra) # 80002f34 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034d2:	0485                	addi	s1,s1,1
    800034d4:	00ca2703          	lw	a4,12(s4)
    800034d8:	0004879b          	sext.w	a5,s1
    800034dc:	fce7e1e3          	bltu	a5,a4,8000349e <ialloc+0x32>
  panic("ialloc: no inodes");
    800034e0:	00005517          	auipc	a0,0x5
    800034e4:	0e050513          	addi	a0,a0,224 # 800085c0 <syscalls+0x178>
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	052080e7          	jalr	82(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    800034f0:	04000613          	li	a2,64
    800034f4:	4581                	li	a1,0
    800034f6:	854e                	mv	a0,s3
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	7d4080e7          	jalr	2004(ra) # 80000ccc <memset>
      dip->type = type;
    80003500:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003504:	854a                	mv	a0,s2
    80003506:	00001097          	auipc	ra,0x1
    8000350a:	cb2080e7          	jalr	-846(ra) # 800041b8 <log_write>
      brelse(bp);
    8000350e:	854a                	mv	a0,s2
    80003510:	00000097          	auipc	ra,0x0
    80003514:	a24080e7          	jalr	-1500(ra) # 80002f34 <brelse>
      return iget(dev, inum);
    80003518:	85da                	mv	a1,s6
    8000351a:	8556                	mv	a0,s5
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	db4080e7          	jalr	-588(ra) # 800032d0 <iget>
}
    80003524:	60a6                	ld	ra,72(sp)
    80003526:	6406                	ld	s0,64(sp)
    80003528:	74e2                	ld	s1,56(sp)
    8000352a:	7942                	ld	s2,48(sp)
    8000352c:	79a2                	ld	s3,40(sp)
    8000352e:	7a02                	ld	s4,32(sp)
    80003530:	6ae2                	ld	s5,24(sp)
    80003532:	6b42                	ld	s6,16(sp)
    80003534:	6ba2                	ld	s7,8(sp)
    80003536:	6161                	addi	sp,sp,80
    80003538:	8082                	ret

000000008000353a <iupdate>:
{
    8000353a:	1101                	addi	sp,sp,-32
    8000353c:	ec06                	sd	ra,24(sp)
    8000353e:	e822                	sd	s0,16(sp)
    80003540:	e426                	sd	s1,8(sp)
    80003542:	e04a                	sd	s2,0(sp)
    80003544:	1000                	addi	s0,sp,32
    80003546:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003548:	415c                	lw	a5,4(a0)
    8000354a:	0047d79b          	srliw	a5,a5,0x4
    8000354e:	0001c597          	auipc	a1,0x1c
    80003552:	2725a583          	lw	a1,626(a1) # 8001f7c0 <sb+0x18>
    80003556:	9dbd                	addw	a1,a1,a5
    80003558:	4108                	lw	a0,0(a0)
    8000355a:	00000097          	auipc	ra,0x0
    8000355e:	8aa080e7          	jalr	-1878(ra) # 80002e04 <bread>
    80003562:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003564:	05850793          	addi	a5,a0,88
    80003568:	40d8                	lw	a4,4(s1)
    8000356a:	8b3d                	andi	a4,a4,15
    8000356c:	071a                	slli	a4,a4,0x6
    8000356e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003570:	04449703          	lh	a4,68(s1)
    80003574:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003578:	04649703          	lh	a4,70(s1)
    8000357c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003580:	04849703          	lh	a4,72(s1)
    80003584:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003588:	04a49703          	lh	a4,74(s1)
    8000358c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003590:	44f8                	lw	a4,76(s1)
    80003592:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003594:	03400613          	li	a2,52
    80003598:	05048593          	addi	a1,s1,80
    8000359c:	00c78513          	addi	a0,a5,12
    800035a0:	ffffd097          	auipc	ra,0xffffd
    800035a4:	788080e7          	jalr	1928(ra) # 80000d28 <memmove>
  log_write(bp);
    800035a8:	854a                	mv	a0,s2
    800035aa:	00001097          	auipc	ra,0x1
    800035ae:	c0e080e7          	jalr	-1010(ra) # 800041b8 <log_write>
  brelse(bp);
    800035b2:	854a                	mv	a0,s2
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	980080e7          	jalr	-1664(ra) # 80002f34 <brelse>
}
    800035bc:	60e2                	ld	ra,24(sp)
    800035be:	6442                	ld	s0,16(sp)
    800035c0:	64a2                	ld	s1,8(sp)
    800035c2:	6902                	ld	s2,0(sp)
    800035c4:	6105                	addi	sp,sp,32
    800035c6:	8082                	ret

00000000800035c8 <idup>:
{
    800035c8:	1101                	addi	sp,sp,-32
    800035ca:	ec06                	sd	ra,24(sp)
    800035cc:	e822                	sd	s0,16(sp)
    800035ce:	e426                	sd	s1,8(sp)
    800035d0:	1000                	addi	s0,sp,32
    800035d2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035d4:	0001c517          	auipc	a0,0x1c
    800035d8:	1f450513          	addi	a0,a0,500 # 8001f7c8 <itable>
    800035dc:	ffffd097          	auipc	ra,0xffffd
    800035e0:	5f4080e7          	jalr	1524(ra) # 80000bd0 <acquire>
  ip->ref++;
    800035e4:	449c                	lw	a5,8(s1)
    800035e6:	2785                	addiw	a5,a5,1
    800035e8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800035ea:	0001c517          	auipc	a0,0x1c
    800035ee:	1de50513          	addi	a0,a0,478 # 8001f7c8 <itable>
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	692080e7          	jalr	1682(ra) # 80000c84 <release>
}
    800035fa:	8526                	mv	a0,s1
    800035fc:	60e2                	ld	ra,24(sp)
    800035fe:	6442                	ld	s0,16(sp)
    80003600:	64a2                	ld	s1,8(sp)
    80003602:	6105                	addi	sp,sp,32
    80003604:	8082                	ret

0000000080003606 <ilock>:
{
    80003606:	1101                	addi	sp,sp,-32
    80003608:	ec06                	sd	ra,24(sp)
    8000360a:	e822                	sd	s0,16(sp)
    8000360c:	e426                	sd	s1,8(sp)
    8000360e:	e04a                	sd	s2,0(sp)
    80003610:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003612:	c115                	beqz	a0,80003636 <ilock+0x30>
    80003614:	84aa                	mv	s1,a0
    80003616:	451c                	lw	a5,8(a0)
    80003618:	00f05f63          	blez	a5,80003636 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000361c:	0541                	addi	a0,a0,16
    8000361e:	00001097          	auipc	ra,0x1
    80003622:	cb8080e7          	jalr	-840(ra) # 800042d6 <acquiresleep>
  if(ip->valid == 0){
    80003626:	40bc                	lw	a5,64(s1)
    80003628:	cf99                	beqz	a5,80003646 <ilock+0x40>
}
    8000362a:	60e2                	ld	ra,24(sp)
    8000362c:	6442                	ld	s0,16(sp)
    8000362e:	64a2                	ld	s1,8(sp)
    80003630:	6902                	ld	s2,0(sp)
    80003632:	6105                	addi	sp,sp,32
    80003634:	8082                	ret
    panic("ilock");
    80003636:	00005517          	auipc	a0,0x5
    8000363a:	fa250513          	addi	a0,a0,-94 # 800085d8 <syscalls+0x190>
    8000363e:	ffffd097          	auipc	ra,0xffffd
    80003642:	efc080e7          	jalr	-260(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003646:	40dc                	lw	a5,4(s1)
    80003648:	0047d79b          	srliw	a5,a5,0x4
    8000364c:	0001c597          	auipc	a1,0x1c
    80003650:	1745a583          	lw	a1,372(a1) # 8001f7c0 <sb+0x18>
    80003654:	9dbd                	addw	a1,a1,a5
    80003656:	4088                	lw	a0,0(s1)
    80003658:	fffff097          	auipc	ra,0xfffff
    8000365c:	7ac080e7          	jalr	1964(ra) # 80002e04 <bread>
    80003660:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003662:	05850593          	addi	a1,a0,88
    80003666:	40dc                	lw	a5,4(s1)
    80003668:	8bbd                	andi	a5,a5,15
    8000366a:	079a                	slli	a5,a5,0x6
    8000366c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000366e:	00059783          	lh	a5,0(a1)
    80003672:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003676:	00259783          	lh	a5,2(a1)
    8000367a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000367e:	00459783          	lh	a5,4(a1)
    80003682:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003686:	00659783          	lh	a5,6(a1)
    8000368a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000368e:	459c                	lw	a5,8(a1)
    80003690:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003692:	03400613          	li	a2,52
    80003696:	05b1                	addi	a1,a1,12
    80003698:	05048513          	addi	a0,s1,80
    8000369c:	ffffd097          	auipc	ra,0xffffd
    800036a0:	68c080e7          	jalr	1676(ra) # 80000d28 <memmove>
    brelse(bp);
    800036a4:	854a                	mv	a0,s2
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	88e080e7          	jalr	-1906(ra) # 80002f34 <brelse>
    ip->valid = 1;
    800036ae:	4785                	li	a5,1
    800036b0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036b2:	04449783          	lh	a5,68(s1)
    800036b6:	fbb5                	bnez	a5,8000362a <ilock+0x24>
      panic("ilock: no type");
    800036b8:	00005517          	auipc	a0,0x5
    800036bc:	f2850513          	addi	a0,a0,-216 # 800085e0 <syscalls+0x198>
    800036c0:	ffffd097          	auipc	ra,0xffffd
    800036c4:	e7a080e7          	jalr	-390(ra) # 8000053a <panic>

00000000800036c8 <iunlock>:
{
    800036c8:	1101                	addi	sp,sp,-32
    800036ca:	ec06                	sd	ra,24(sp)
    800036cc:	e822                	sd	s0,16(sp)
    800036ce:	e426                	sd	s1,8(sp)
    800036d0:	e04a                	sd	s2,0(sp)
    800036d2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036d4:	c905                	beqz	a0,80003704 <iunlock+0x3c>
    800036d6:	84aa                	mv	s1,a0
    800036d8:	01050913          	addi	s2,a0,16
    800036dc:	854a                	mv	a0,s2
    800036de:	00001097          	auipc	ra,0x1
    800036e2:	c92080e7          	jalr	-878(ra) # 80004370 <holdingsleep>
    800036e6:	cd19                	beqz	a0,80003704 <iunlock+0x3c>
    800036e8:	449c                	lw	a5,8(s1)
    800036ea:	00f05d63          	blez	a5,80003704 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036ee:	854a                	mv	a0,s2
    800036f0:	00001097          	auipc	ra,0x1
    800036f4:	c3c080e7          	jalr	-964(ra) # 8000432c <releasesleep>
}
    800036f8:	60e2                	ld	ra,24(sp)
    800036fa:	6442                	ld	s0,16(sp)
    800036fc:	64a2                	ld	s1,8(sp)
    800036fe:	6902                	ld	s2,0(sp)
    80003700:	6105                	addi	sp,sp,32
    80003702:	8082                	ret
    panic("iunlock");
    80003704:	00005517          	auipc	a0,0x5
    80003708:	eec50513          	addi	a0,a0,-276 # 800085f0 <syscalls+0x1a8>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	e2e080e7          	jalr	-466(ra) # 8000053a <panic>

0000000080003714 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003714:	7179                	addi	sp,sp,-48
    80003716:	f406                	sd	ra,40(sp)
    80003718:	f022                	sd	s0,32(sp)
    8000371a:	ec26                	sd	s1,24(sp)
    8000371c:	e84a                	sd	s2,16(sp)
    8000371e:	e44e                	sd	s3,8(sp)
    80003720:	e052                	sd	s4,0(sp)
    80003722:	1800                	addi	s0,sp,48
    80003724:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003726:	05050493          	addi	s1,a0,80
    8000372a:	08050913          	addi	s2,a0,128
    8000372e:	a021                	j	80003736 <itrunc+0x22>
    80003730:	0491                	addi	s1,s1,4
    80003732:	01248d63          	beq	s1,s2,8000374c <itrunc+0x38>
    if(ip->addrs[i]){
    80003736:	408c                	lw	a1,0(s1)
    80003738:	dde5                	beqz	a1,80003730 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000373a:	0009a503          	lw	a0,0(s3)
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	90c080e7          	jalr	-1780(ra) # 8000304a <bfree>
      ip->addrs[i] = 0;
    80003746:	0004a023          	sw	zero,0(s1)
    8000374a:	b7dd                	j	80003730 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000374c:	0809a583          	lw	a1,128(s3)
    80003750:	e185                	bnez	a1,80003770 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003752:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003756:	854e                	mv	a0,s3
    80003758:	00000097          	auipc	ra,0x0
    8000375c:	de2080e7          	jalr	-542(ra) # 8000353a <iupdate>
}
    80003760:	70a2                	ld	ra,40(sp)
    80003762:	7402                	ld	s0,32(sp)
    80003764:	64e2                	ld	s1,24(sp)
    80003766:	6942                	ld	s2,16(sp)
    80003768:	69a2                	ld	s3,8(sp)
    8000376a:	6a02                	ld	s4,0(sp)
    8000376c:	6145                	addi	sp,sp,48
    8000376e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003770:	0009a503          	lw	a0,0(s3)
    80003774:	fffff097          	auipc	ra,0xfffff
    80003778:	690080e7          	jalr	1680(ra) # 80002e04 <bread>
    8000377c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000377e:	05850493          	addi	s1,a0,88
    80003782:	45850913          	addi	s2,a0,1112
    80003786:	a021                	j	8000378e <itrunc+0x7a>
    80003788:	0491                	addi	s1,s1,4
    8000378a:	01248b63          	beq	s1,s2,800037a0 <itrunc+0x8c>
      if(a[j])
    8000378e:	408c                	lw	a1,0(s1)
    80003790:	dde5                	beqz	a1,80003788 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003792:	0009a503          	lw	a0,0(s3)
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	8b4080e7          	jalr	-1868(ra) # 8000304a <bfree>
    8000379e:	b7ed                	j	80003788 <itrunc+0x74>
    brelse(bp);
    800037a0:	8552                	mv	a0,s4
    800037a2:	fffff097          	auipc	ra,0xfffff
    800037a6:	792080e7          	jalr	1938(ra) # 80002f34 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037aa:	0809a583          	lw	a1,128(s3)
    800037ae:	0009a503          	lw	a0,0(s3)
    800037b2:	00000097          	auipc	ra,0x0
    800037b6:	898080e7          	jalr	-1896(ra) # 8000304a <bfree>
    ip->addrs[NDIRECT] = 0;
    800037ba:	0809a023          	sw	zero,128(s3)
    800037be:	bf51                	j	80003752 <itrunc+0x3e>

00000000800037c0 <iput>:
{
    800037c0:	1101                	addi	sp,sp,-32
    800037c2:	ec06                	sd	ra,24(sp)
    800037c4:	e822                	sd	s0,16(sp)
    800037c6:	e426                	sd	s1,8(sp)
    800037c8:	e04a                	sd	s2,0(sp)
    800037ca:	1000                	addi	s0,sp,32
    800037cc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037ce:	0001c517          	auipc	a0,0x1c
    800037d2:	ffa50513          	addi	a0,a0,-6 # 8001f7c8 <itable>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	3fa080e7          	jalr	1018(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037de:	4498                	lw	a4,8(s1)
    800037e0:	4785                	li	a5,1
    800037e2:	02f70363          	beq	a4,a5,80003808 <iput+0x48>
  ip->ref--;
    800037e6:	449c                	lw	a5,8(s1)
    800037e8:	37fd                	addiw	a5,a5,-1
    800037ea:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037ec:	0001c517          	auipc	a0,0x1c
    800037f0:	fdc50513          	addi	a0,a0,-36 # 8001f7c8 <itable>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	490080e7          	jalr	1168(ra) # 80000c84 <release>
}
    800037fc:	60e2                	ld	ra,24(sp)
    800037fe:	6442                	ld	s0,16(sp)
    80003800:	64a2                	ld	s1,8(sp)
    80003802:	6902                	ld	s2,0(sp)
    80003804:	6105                	addi	sp,sp,32
    80003806:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003808:	40bc                	lw	a5,64(s1)
    8000380a:	dff1                	beqz	a5,800037e6 <iput+0x26>
    8000380c:	04a49783          	lh	a5,74(s1)
    80003810:	fbf9                	bnez	a5,800037e6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003812:	01048913          	addi	s2,s1,16
    80003816:	854a                	mv	a0,s2
    80003818:	00001097          	auipc	ra,0x1
    8000381c:	abe080e7          	jalr	-1346(ra) # 800042d6 <acquiresleep>
    release(&itable.lock);
    80003820:	0001c517          	auipc	a0,0x1c
    80003824:	fa850513          	addi	a0,a0,-88 # 8001f7c8 <itable>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	45c080e7          	jalr	1116(ra) # 80000c84 <release>
    itrunc(ip);
    80003830:	8526                	mv	a0,s1
    80003832:	00000097          	auipc	ra,0x0
    80003836:	ee2080e7          	jalr	-286(ra) # 80003714 <itrunc>
    ip->type = 0;
    8000383a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000383e:	8526                	mv	a0,s1
    80003840:	00000097          	auipc	ra,0x0
    80003844:	cfa080e7          	jalr	-774(ra) # 8000353a <iupdate>
    ip->valid = 0;
    80003848:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000384c:	854a                	mv	a0,s2
    8000384e:	00001097          	auipc	ra,0x1
    80003852:	ade080e7          	jalr	-1314(ra) # 8000432c <releasesleep>
    acquire(&itable.lock);
    80003856:	0001c517          	auipc	a0,0x1c
    8000385a:	f7250513          	addi	a0,a0,-142 # 8001f7c8 <itable>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	372080e7          	jalr	882(ra) # 80000bd0 <acquire>
    80003866:	b741                	j	800037e6 <iput+0x26>

0000000080003868 <iunlockput>:
{
    80003868:	1101                	addi	sp,sp,-32
    8000386a:	ec06                	sd	ra,24(sp)
    8000386c:	e822                	sd	s0,16(sp)
    8000386e:	e426                	sd	s1,8(sp)
    80003870:	1000                	addi	s0,sp,32
    80003872:	84aa                	mv	s1,a0
  iunlock(ip);
    80003874:	00000097          	auipc	ra,0x0
    80003878:	e54080e7          	jalr	-428(ra) # 800036c8 <iunlock>
  iput(ip);
    8000387c:	8526                	mv	a0,s1
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	f42080e7          	jalr	-190(ra) # 800037c0 <iput>
}
    80003886:	60e2                	ld	ra,24(sp)
    80003888:	6442                	ld	s0,16(sp)
    8000388a:	64a2                	ld	s1,8(sp)
    8000388c:	6105                	addi	sp,sp,32
    8000388e:	8082                	ret

0000000080003890 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003890:	1141                	addi	sp,sp,-16
    80003892:	e422                	sd	s0,8(sp)
    80003894:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003896:	411c                	lw	a5,0(a0)
    80003898:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000389a:	415c                	lw	a5,4(a0)
    8000389c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000389e:	04451783          	lh	a5,68(a0)
    800038a2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038a6:	04a51783          	lh	a5,74(a0)
    800038aa:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038ae:	04c56783          	lwu	a5,76(a0)
    800038b2:	e99c                	sd	a5,16(a1)
}
    800038b4:	6422                	ld	s0,8(sp)
    800038b6:	0141                	addi	sp,sp,16
    800038b8:	8082                	ret

00000000800038ba <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038ba:	457c                	lw	a5,76(a0)
    800038bc:	0ed7e963          	bltu	a5,a3,800039ae <readi+0xf4>
{
    800038c0:	7159                	addi	sp,sp,-112
    800038c2:	f486                	sd	ra,104(sp)
    800038c4:	f0a2                	sd	s0,96(sp)
    800038c6:	eca6                	sd	s1,88(sp)
    800038c8:	e8ca                	sd	s2,80(sp)
    800038ca:	e4ce                	sd	s3,72(sp)
    800038cc:	e0d2                	sd	s4,64(sp)
    800038ce:	fc56                	sd	s5,56(sp)
    800038d0:	f85a                	sd	s6,48(sp)
    800038d2:	f45e                	sd	s7,40(sp)
    800038d4:	f062                	sd	s8,32(sp)
    800038d6:	ec66                	sd	s9,24(sp)
    800038d8:	e86a                	sd	s10,16(sp)
    800038da:	e46e                	sd	s11,8(sp)
    800038dc:	1880                	addi	s0,sp,112
    800038de:	8baa                	mv	s7,a0
    800038e0:	8c2e                	mv	s8,a1
    800038e2:	8ab2                	mv	s5,a2
    800038e4:	84b6                	mv	s1,a3
    800038e6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038e8:	9f35                	addw	a4,a4,a3
    return 0;
    800038ea:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038ec:	0ad76063          	bltu	a4,a3,8000398c <readi+0xd2>
  if(off + n > ip->size)
    800038f0:	00e7f463          	bgeu	a5,a4,800038f8 <readi+0x3e>
    n = ip->size - off;
    800038f4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038f8:	0a0b0963          	beqz	s6,800039aa <readi+0xf0>
    800038fc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800038fe:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003902:	5cfd                	li	s9,-1
    80003904:	a82d                	j	8000393e <readi+0x84>
    80003906:	020a1d93          	slli	s11,s4,0x20
    8000390a:	020ddd93          	srli	s11,s11,0x20
    8000390e:	05890613          	addi	a2,s2,88
    80003912:	86ee                	mv	a3,s11
    80003914:	963a                	add	a2,a2,a4
    80003916:	85d6                	mv	a1,s5
    80003918:	8562                	mv	a0,s8
    8000391a:	fffff097          	auipc	ra,0xfffff
    8000391e:	ae4080e7          	jalr	-1308(ra) # 800023fe <either_copyout>
    80003922:	05950d63          	beq	a0,s9,8000397c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003926:	854a                	mv	a0,s2
    80003928:	fffff097          	auipc	ra,0xfffff
    8000392c:	60c080e7          	jalr	1548(ra) # 80002f34 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003930:	013a09bb          	addw	s3,s4,s3
    80003934:	009a04bb          	addw	s1,s4,s1
    80003938:	9aee                	add	s5,s5,s11
    8000393a:	0569f763          	bgeu	s3,s6,80003988 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000393e:	000ba903          	lw	s2,0(s7)
    80003942:	00a4d59b          	srliw	a1,s1,0xa
    80003946:	855e                	mv	a0,s7
    80003948:	00000097          	auipc	ra,0x0
    8000394c:	8ac080e7          	jalr	-1876(ra) # 800031f4 <bmap>
    80003950:	0005059b          	sext.w	a1,a0
    80003954:	854a                	mv	a0,s2
    80003956:	fffff097          	auipc	ra,0xfffff
    8000395a:	4ae080e7          	jalr	1198(ra) # 80002e04 <bread>
    8000395e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003960:	3ff4f713          	andi	a4,s1,1023
    80003964:	40ed07bb          	subw	a5,s10,a4
    80003968:	413b06bb          	subw	a3,s6,s3
    8000396c:	8a3e                	mv	s4,a5
    8000396e:	2781                	sext.w	a5,a5
    80003970:	0006861b          	sext.w	a2,a3
    80003974:	f8f679e3          	bgeu	a2,a5,80003906 <readi+0x4c>
    80003978:	8a36                	mv	s4,a3
    8000397a:	b771                	j	80003906 <readi+0x4c>
      brelse(bp);
    8000397c:	854a                	mv	a0,s2
    8000397e:	fffff097          	auipc	ra,0xfffff
    80003982:	5b6080e7          	jalr	1462(ra) # 80002f34 <brelse>
      tot = -1;
    80003986:	59fd                	li	s3,-1
  }
  return tot;
    80003988:	0009851b          	sext.w	a0,s3
}
    8000398c:	70a6                	ld	ra,104(sp)
    8000398e:	7406                	ld	s0,96(sp)
    80003990:	64e6                	ld	s1,88(sp)
    80003992:	6946                	ld	s2,80(sp)
    80003994:	69a6                	ld	s3,72(sp)
    80003996:	6a06                	ld	s4,64(sp)
    80003998:	7ae2                	ld	s5,56(sp)
    8000399a:	7b42                	ld	s6,48(sp)
    8000399c:	7ba2                	ld	s7,40(sp)
    8000399e:	7c02                	ld	s8,32(sp)
    800039a0:	6ce2                	ld	s9,24(sp)
    800039a2:	6d42                	ld	s10,16(sp)
    800039a4:	6da2                	ld	s11,8(sp)
    800039a6:	6165                	addi	sp,sp,112
    800039a8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039aa:	89da                	mv	s3,s6
    800039ac:	bff1                	j	80003988 <readi+0xce>
    return 0;
    800039ae:	4501                	li	a0,0
}
    800039b0:	8082                	ret

00000000800039b2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039b2:	457c                	lw	a5,76(a0)
    800039b4:	10d7e863          	bltu	a5,a3,80003ac4 <writei+0x112>
{
    800039b8:	7159                	addi	sp,sp,-112
    800039ba:	f486                	sd	ra,104(sp)
    800039bc:	f0a2                	sd	s0,96(sp)
    800039be:	eca6                	sd	s1,88(sp)
    800039c0:	e8ca                	sd	s2,80(sp)
    800039c2:	e4ce                	sd	s3,72(sp)
    800039c4:	e0d2                	sd	s4,64(sp)
    800039c6:	fc56                	sd	s5,56(sp)
    800039c8:	f85a                	sd	s6,48(sp)
    800039ca:	f45e                	sd	s7,40(sp)
    800039cc:	f062                	sd	s8,32(sp)
    800039ce:	ec66                	sd	s9,24(sp)
    800039d0:	e86a                	sd	s10,16(sp)
    800039d2:	e46e                	sd	s11,8(sp)
    800039d4:	1880                	addi	s0,sp,112
    800039d6:	8b2a                	mv	s6,a0
    800039d8:	8c2e                	mv	s8,a1
    800039da:	8ab2                	mv	s5,a2
    800039dc:	8936                	mv	s2,a3
    800039de:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800039e0:	00e687bb          	addw	a5,a3,a4
    800039e4:	0ed7e263          	bltu	a5,a3,80003ac8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039e8:	00043737          	lui	a4,0x43
    800039ec:	0ef76063          	bltu	a4,a5,80003acc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039f0:	0c0b8863          	beqz	s7,80003ac0 <writei+0x10e>
    800039f4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039f6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800039fa:	5cfd                	li	s9,-1
    800039fc:	a091                	j	80003a40 <writei+0x8e>
    800039fe:	02099d93          	slli	s11,s3,0x20
    80003a02:	020ddd93          	srli	s11,s11,0x20
    80003a06:	05848513          	addi	a0,s1,88
    80003a0a:	86ee                	mv	a3,s11
    80003a0c:	8656                	mv	a2,s5
    80003a0e:	85e2                	mv	a1,s8
    80003a10:	953a                	add	a0,a0,a4
    80003a12:	fffff097          	auipc	ra,0xfffff
    80003a16:	a42080e7          	jalr	-1470(ra) # 80002454 <either_copyin>
    80003a1a:	07950263          	beq	a0,s9,80003a7e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a1e:	8526                	mv	a0,s1
    80003a20:	00000097          	auipc	ra,0x0
    80003a24:	798080e7          	jalr	1944(ra) # 800041b8 <log_write>
    brelse(bp);
    80003a28:	8526                	mv	a0,s1
    80003a2a:	fffff097          	auipc	ra,0xfffff
    80003a2e:	50a080e7          	jalr	1290(ra) # 80002f34 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a32:	01498a3b          	addw	s4,s3,s4
    80003a36:	0129893b          	addw	s2,s3,s2
    80003a3a:	9aee                	add	s5,s5,s11
    80003a3c:	057a7663          	bgeu	s4,s7,80003a88 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a40:	000b2483          	lw	s1,0(s6)
    80003a44:	00a9559b          	srliw	a1,s2,0xa
    80003a48:	855a                	mv	a0,s6
    80003a4a:	fffff097          	auipc	ra,0xfffff
    80003a4e:	7aa080e7          	jalr	1962(ra) # 800031f4 <bmap>
    80003a52:	0005059b          	sext.w	a1,a0
    80003a56:	8526                	mv	a0,s1
    80003a58:	fffff097          	auipc	ra,0xfffff
    80003a5c:	3ac080e7          	jalr	940(ra) # 80002e04 <bread>
    80003a60:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a62:	3ff97713          	andi	a4,s2,1023
    80003a66:	40ed07bb          	subw	a5,s10,a4
    80003a6a:	414b86bb          	subw	a3,s7,s4
    80003a6e:	89be                	mv	s3,a5
    80003a70:	2781                	sext.w	a5,a5
    80003a72:	0006861b          	sext.w	a2,a3
    80003a76:	f8f674e3          	bgeu	a2,a5,800039fe <writei+0x4c>
    80003a7a:	89b6                	mv	s3,a3
    80003a7c:	b749                	j	800039fe <writei+0x4c>
      brelse(bp);
    80003a7e:	8526                	mv	a0,s1
    80003a80:	fffff097          	auipc	ra,0xfffff
    80003a84:	4b4080e7          	jalr	1204(ra) # 80002f34 <brelse>
  }

  if(off > ip->size)
    80003a88:	04cb2783          	lw	a5,76(s6)
    80003a8c:	0127f463          	bgeu	a5,s2,80003a94 <writei+0xe2>
    ip->size = off;
    80003a90:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003a94:	855a                	mv	a0,s6
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	aa4080e7          	jalr	-1372(ra) # 8000353a <iupdate>

  return tot;
    80003a9e:	000a051b          	sext.w	a0,s4
}
    80003aa2:	70a6                	ld	ra,104(sp)
    80003aa4:	7406                	ld	s0,96(sp)
    80003aa6:	64e6                	ld	s1,88(sp)
    80003aa8:	6946                	ld	s2,80(sp)
    80003aaa:	69a6                	ld	s3,72(sp)
    80003aac:	6a06                	ld	s4,64(sp)
    80003aae:	7ae2                	ld	s5,56(sp)
    80003ab0:	7b42                	ld	s6,48(sp)
    80003ab2:	7ba2                	ld	s7,40(sp)
    80003ab4:	7c02                	ld	s8,32(sp)
    80003ab6:	6ce2                	ld	s9,24(sp)
    80003ab8:	6d42                	ld	s10,16(sp)
    80003aba:	6da2                	ld	s11,8(sp)
    80003abc:	6165                	addi	sp,sp,112
    80003abe:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ac0:	8a5e                	mv	s4,s7
    80003ac2:	bfc9                	j	80003a94 <writei+0xe2>
    return -1;
    80003ac4:	557d                	li	a0,-1
}
    80003ac6:	8082                	ret
    return -1;
    80003ac8:	557d                	li	a0,-1
    80003aca:	bfe1                	j	80003aa2 <writei+0xf0>
    return -1;
    80003acc:	557d                	li	a0,-1
    80003ace:	bfd1                	j	80003aa2 <writei+0xf0>

0000000080003ad0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ad0:	1141                	addi	sp,sp,-16
    80003ad2:	e406                	sd	ra,8(sp)
    80003ad4:	e022                	sd	s0,0(sp)
    80003ad6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ad8:	4639                	li	a2,14
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	2c2080e7          	jalr	706(ra) # 80000d9c <strncmp>
}
    80003ae2:	60a2                	ld	ra,8(sp)
    80003ae4:	6402                	ld	s0,0(sp)
    80003ae6:	0141                	addi	sp,sp,16
    80003ae8:	8082                	ret

0000000080003aea <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003aea:	7139                	addi	sp,sp,-64
    80003aec:	fc06                	sd	ra,56(sp)
    80003aee:	f822                	sd	s0,48(sp)
    80003af0:	f426                	sd	s1,40(sp)
    80003af2:	f04a                	sd	s2,32(sp)
    80003af4:	ec4e                	sd	s3,24(sp)
    80003af6:	e852                	sd	s4,16(sp)
    80003af8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003afa:	04451703          	lh	a4,68(a0)
    80003afe:	4785                	li	a5,1
    80003b00:	00f71a63          	bne	a4,a5,80003b14 <dirlookup+0x2a>
    80003b04:	892a                	mv	s2,a0
    80003b06:	89ae                	mv	s3,a1
    80003b08:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b0a:	457c                	lw	a5,76(a0)
    80003b0c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b0e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b10:	e79d                	bnez	a5,80003b3e <dirlookup+0x54>
    80003b12:	a8a5                	j	80003b8a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b14:	00005517          	auipc	a0,0x5
    80003b18:	ae450513          	addi	a0,a0,-1308 # 800085f8 <syscalls+0x1b0>
    80003b1c:	ffffd097          	auipc	ra,0xffffd
    80003b20:	a1e080e7          	jalr	-1506(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003b24:	00005517          	auipc	a0,0x5
    80003b28:	aec50513          	addi	a0,a0,-1300 # 80008610 <syscalls+0x1c8>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	a0e080e7          	jalr	-1522(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b34:	24c1                	addiw	s1,s1,16
    80003b36:	04c92783          	lw	a5,76(s2)
    80003b3a:	04f4f763          	bgeu	s1,a5,80003b88 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b3e:	4741                	li	a4,16
    80003b40:	86a6                	mv	a3,s1
    80003b42:	fc040613          	addi	a2,s0,-64
    80003b46:	4581                	li	a1,0
    80003b48:	854a                	mv	a0,s2
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	d70080e7          	jalr	-656(ra) # 800038ba <readi>
    80003b52:	47c1                	li	a5,16
    80003b54:	fcf518e3          	bne	a0,a5,80003b24 <dirlookup+0x3a>
    if(de.inum == 0)
    80003b58:	fc045783          	lhu	a5,-64(s0)
    80003b5c:	dfe1                	beqz	a5,80003b34 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b5e:	fc240593          	addi	a1,s0,-62
    80003b62:	854e                	mv	a0,s3
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	f6c080e7          	jalr	-148(ra) # 80003ad0 <namecmp>
    80003b6c:	f561                	bnez	a0,80003b34 <dirlookup+0x4a>
      if(poff)
    80003b6e:	000a0463          	beqz	s4,80003b76 <dirlookup+0x8c>
        *poff = off;
    80003b72:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b76:	fc045583          	lhu	a1,-64(s0)
    80003b7a:	00092503          	lw	a0,0(s2)
    80003b7e:	fffff097          	auipc	ra,0xfffff
    80003b82:	752080e7          	jalr	1874(ra) # 800032d0 <iget>
    80003b86:	a011                	j	80003b8a <dirlookup+0xa0>
  return 0;
    80003b88:	4501                	li	a0,0
}
    80003b8a:	70e2                	ld	ra,56(sp)
    80003b8c:	7442                	ld	s0,48(sp)
    80003b8e:	74a2                	ld	s1,40(sp)
    80003b90:	7902                	ld	s2,32(sp)
    80003b92:	69e2                	ld	s3,24(sp)
    80003b94:	6a42                	ld	s4,16(sp)
    80003b96:	6121                	addi	sp,sp,64
    80003b98:	8082                	ret

0000000080003b9a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003b9a:	711d                	addi	sp,sp,-96
    80003b9c:	ec86                	sd	ra,88(sp)
    80003b9e:	e8a2                	sd	s0,80(sp)
    80003ba0:	e4a6                	sd	s1,72(sp)
    80003ba2:	e0ca                	sd	s2,64(sp)
    80003ba4:	fc4e                	sd	s3,56(sp)
    80003ba6:	f852                	sd	s4,48(sp)
    80003ba8:	f456                	sd	s5,40(sp)
    80003baa:	f05a                	sd	s6,32(sp)
    80003bac:	ec5e                	sd	s7,24(sp)
    80003bae:	e862                	sd	s8,16(sp)
    80003bb0:	e466                	sd	s9,8(sp)
    80003bb2:	e06a                	sd	s10,0(sp)
    80003bb4:	1080                	addi	s0,sp,96
    80003bb6:	84aa                	mv	s1,a0
    80003bb8:	8b2e                	mv	s6,a1
    80003bba:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003bbc:	00054703          	lbu	a4,0(a0)
    80003bc0:	02f00793          	li	a5,47
    80003bc4:	02f70363          	beq	a4,a5,80003bea <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bc8:	ffffe097          	auipc	ra,0xffffe
    80003bcc:	dce080e7          	jalr	-562(ra) # 80001996 <myproc>
    80003bd0:	15053503          	ld	a0,336(a0)
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	9f4080e7          	jalr	-1548(ra) # 800035c8 <idup>
    80003bdc:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003bde:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003be2:	4cb5                	li	s9,13
  len = path - s;
    80003be4:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003be6:	4c05                	li	s8,1
    80003be8:	a87d                	j	80003ca6 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003bea:	4585                	li	a1,1
    80003bec:	4505                	li	a0,1
    80003bee:	fffff097          	auipc	ra,0xfffff
    80003bf2:	6e2080e7          	jalr	1762(ra) # 800032d0 <iget>
    80003bf6:	8a2a                	mv	s4,a0
    80003bf8:	b7dd                	j	80003bde <namex+0x44>
      iunlockput(ip);
    80003bfa:	8552                	mv	a0,s4
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	c6c080e7          	jalr	-916(ra) # 80003868 <iunlockput>
      return 0;
    80003c04:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c06:	8552                	mv	a0,s4
    80003c08:	60e6                	ld	ra,88(sp)
    80003c0a:	6446                	ld	s0,80(sp)
    80003c0c:	64a6                	ld	s1,72(sp)
    80003c0e:	6906                	ld	s2,64(sp)
    80003c10:	79e2                	ld	s3,56(sp)
    80003c12:	7a42                	ld	s4,48(sp)
    80003c14:	7aa2                	ld	s5,40(sp)
    80003c16:	7b02                	ld	s6,32(sp)
    80003c18:	6be2                	ld	s7,24(sp)
    80003c1a:	6c42                	ld	s8,16(sp)
    80003c1c:	6ca2                	ld	s9,8(sp)
    80003c1e:	6d02                	ld	s10,0(sp)
    80003c20:	6125                	addi	sp,sp,96
    80003c22:	8082                	ret
      iunlock(ip);
    80003c24:	8552                	mv	a0,s4
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	aa2080e7          	jalr	-1374(ra) # 800036c8 <iunlock>
      return ip;
    80003c2e:	bfe1                	j	80003c06 <namex+0x6c>
      iunlockput(ip);
    80003c30:	8552                	mv	a0,s4
    80003c32:	00000097          	auipc	ra,0x0
    80003c36:	c36080e7          	jalr	-970(ra) # 80003868 <iunlockput>
      return 0;
    80003c3a:	8a4e                	mv	s4,s3
    80003c3c:	b7e9                	j	80003c06 <namex+0x6c>
  len = path - s;
    80003c3e:	40998633          	sub	a2,s3,s1
    80003c42:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003c46:	09acd863          	bge	s9,s10,80003cd6 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003c4a:	4639                	li	a2,14
    80003c4c:	85a6                	mv	a1,s1
    80003c4e:	8556                	mv	a0,s5
    80003c50:	ffffd097          	auipc	ra,0xffffd
    80003c54:	0d8080e7          	jalr	216(ra) # 80000d28 <memmove>
    80003c58:	84ce                	mv	s1,s3
  while(*path == '/')
    80003c5a:	0004c783          	lbu	a5,0(s1)
    80003c5e:	01279763          	bne	a5,s2,80003c6c <namex+0xd2>
    path++;
    80003c62:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c64:	0004c783          	lbu	a5,0(s1)
    80003c68:	ff278de3          	beq	a5,s2,80003c62 <namex+0xc8>
    ilock(ip);
    80003c6c:	8552                	mv	a0,s4
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	998080e7          	jalr	-1640(ra) # 80003606 <ilock>
    if(ip->type != T_DIR){
    80003c76:	044a1783          	lh	a5,68(s4)
    80003c7a:	f98790e3          	bne	a5,s8,80003bfa <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003c7e:	000b0563          	beqz	s6,80003c88 <namex+0xee>
    80003c82:	0004c783          	lbu	a5,0(s1)
    80003c86:	dfd9                	beqz	a5,80003c24 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c88:	865e                	mv	a2,s7
    80003c8a:	85d6                	mv	a1,s5
    80003c8c:	8552                	mv	a0,s4
    80003c8e:	00000097          	auipc	ra,0x0
    80003c92:	e5c080e7          	jalr	-420(ra) # 80003aea <dirlookup>
    80003c96:	89aa                	mv	s3,a0
    80003c98:	dd41                	beqz	a0,80003c30 <namex+0x96>
    iunlockput(ip);
    80003c9a:	8552                	mv	a0,s4
    80003c9c:	00000097          	auipc	ra,0x0
    80003ca0:	bcc080e7          	jalr	-1076(ra) # 80003868 <iunlockput>
    ip = next;
    80003ca4:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003ca6:	0004c783          	lbu	a5,0(s1)
    80003caa:	01279763          	bne	a5,s2,80003cb8 <namex+0x11e>
    path++;
    80003cae:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cb0:	0004c783          	lbu	a5,0(s1)
    80003cb4:	ff278de3          	beq	a5,s2,80003cae <namex+0x114>
  if(*path == 0)
    80003cb8:	cb9d                	beqz	a5,80003cee <namex+0x154>
  while(*path != '/' && *path != 0)
    80003cba:	0004c783          	lbu	a5,0(s1)
    80003cbe:	89a6                	mv	s3,s1
  len = path - s;
    80003cc0:	8d5e                	mv	s10,s7
    80003cc2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003cc4:	01278963          	beq	a5,s2,80003cd6 <namex+0x13c>
    80003cc8:	dbbd                	beqz	a5,80003c3e <namex+0xa4>
    path++;
    80003cca:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003ccc:	0009c783          	lbu	a5,0(s3)
    80003cd0:	ff279ce3          	bne	a5,s2,80003cc8 <namex+0x12e>
    80003cd4:	b7ad                	j	80003c3e <namex+0xa4>
    memmove(name, s, len);
    80003cd6:	2601                	sext.w	a2,a2
    80003cd8:	85a6                	mv	a1,s1
    80003cda:	8556                	mv	a0,s5
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	04c080e7          	jalr	76(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003ce4:	9d56                	add	s10,s10,s5
    80003ce6:	000d0023          	sb	zero,0(s10)
    80003cea:	84ce                	mv	s1,s3
    80003cec:	b7bd                	j	80003c5a <namex+0xc0>
  if(nameiparent){
    80003cee:	f00b0ce3          	beqz	s6,80003c06 <namex+0x6c>
    iput(ip);
    80003cf2:	8552                	mv	a0,s4
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	acc080e7          	jalr	-1332(ra) # 800037c0 <iput>
    return 0;
    80003cfc:	4a01                	li	s4,0
    80003cfe:	b721                	j	80003c06 <namex+0x6c>

0000000080003d00 <dirlink>:
{
    80003d00:	7139                	addi	sp,sp,-64
    80003d02:	fc06                	sd	ra,56(sp)
    80003d04:	f822                	sd	s0,48(sp)
    80003d06:	f426                	sd	s1,40(sp)
    80003d08:	f04a                	sd	s2,32(sp)
    80003d0a:	ec4e                	sd	s3,24(sp)
    80003d0c:	e852                	sd	s4,16(sp)
    80003d0e:	0080                	addi	s0,sp,64
    80003d10:	892a                	mv	s2,a0
    80003d12:	8a2e                	mv	s4,a1
    80003d14:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d16:	4601                	li	a2,0
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	dd2080e7          	jalr	-558(ra) # 80003aea <dirlookup>
    80003d20:	e93d                	bnez	a0,80003d96 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d22:	04c92483          	lw	s1,76(s2)
    80003d26:	c49d                	beqz	s1,80003d54 <dirlink+0x54>
    80003d28:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d2a:	4741                	li	a4,16
    80003d2c:	86a6                	mv	a3,s1
    80003d2e:	fc040613          	addi	a2,s0,-64
    80003d32:	4581                	li	a1,0
    80003d34:	854a                	mv	a0,s2
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	b84080e7          	jalr	-1148(ra) # 800038ba <readi>
    80003d3e:	47c1                	li	a5,16
    80003d40:	06f51163          	bne	a0,a5,80003da2 <dirlink+0xa2>
    if(de.inum == 0)
    80003d44:	fc045783          	lhu	a5,-64(s0)
    80003d48:	c791                	beqz	a5,80003d54 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d4a:	24c1                	addiw	s1,s1,16
    80003d4c:	04c92783          	lw	a5,76(s2)
    80003d50:	fcf4ede3          	bltu	s1,a5,80003d2a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d54:	4639                	li	a2,14
    80003d56:	85d2                	mv	a1,s4
    80003d58:	fc240513          	addi	a0,s0,-62
    80003d5c:	ffffd097          	auipc	ra,0xffffd
    80003d60:	07c080e7          	jalr	124(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003d64:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d68:	4741                	li	a4,16
    80003d6a:	86a6                	mv	a3,s1
    80003d6c:	fc040613          	addi	a2,s0,-64
    80003d70:	4581                	li	a1,0
    80003d72:	854a                	mv	a0,s2
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	c3e080e7          	jalr	-962(ra) # 800039b2 <writei>
    80003d7c:	872a                	mv	a4,a0
    80003d7e:	47c1                	li	a5,16
  return 0;
    80003d80:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d82:	02f71863          	bne	a4,a5,80003db2 <dirlink+0xb2>
}
    80003d86:	70e2                	ld	ra,56(sp)
    80003d88:	7442                	ld	s0,48(sp)
    80003d8a:	74a2                	ld	s1,40(sp)
    80003d8c:	7902                	ld	s2,32(sp)
    80003d8e:	69e2                	ld	s3,24(sp)
    80003d90:	6a42                	ld	s4,16(sp)
    80003d92:	6121                	addi	sp,sp,64
    80003d94:	8082                	ret
    iput(ip);
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	a2a080e7          	jalr	-1494(ra) # 800037c0 <iput>
    return -1;
    80003d9e:	557d                	li	a0,-1
    80003da0:	b7dd                	j	80003d86 <dirlink+0x86>
      panic("dirlink read");
    80003da2:	00005517          	auipc	a0,0x5
    80003da6:	87e50513          	addi	a0,a0,-1922 # 80008620 <syscalls+0x1d8>
    80003daa:	ffffc097          	auipc	ra,0xffffc
    80003dae:	790080e7          	jalr	1936(ra) # 8000053a <panic>
    panic("dirlink");
    80003db2:	00005517          	auipc	a0,0x5
    80003db6:	97e50513          	addi	a0,a0,-1666 # 80008730 <syscalls+0x2e8>
    80003dba:	ffffc097          	auipc	ra,0xffffc
    80003dbe:	780080e7          	jalr	1920(ra) # 8000053a <panic>

0000000080003dc2 <namei>:

struct inode*
namei(char *path)
{
    80003dc2:	1101                	addi	sp,sp,-32
    80003dc4:	ec06                	sd	ra,24(sp)
    80003dc6:	e822                	sd	s0,16(sp)
    80003dc8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dca:	fe040613          	addi	a2,s0,-32
    80003dce:	4581                	li	a1,0
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	dca080e7          	jalr	-566(ra) # 80003b9a <namex>
}
    80003dd8:	60e2                	ld	ra,24(sp)
    80003dda:	6442                	ld	s0,16(sp)
    80003ddc:	6105                	addi	sp,sp,32
    80003dde:	8082                	ret

0000000080003de0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003de0:	1141                	addi	sp,sp,-16
    80003de2:	e406                	sd	ra,8(sp)
    80003de4:	e022                	sd	s0,0(sp)
    80003de6:	0800                	addi	s0,sp,16
    80003de8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dea:	4585                	li	a1,1
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	dae080e7          	jalr	-594(ra) # 80003b9a <namex>
}
    80003df4:	60a2                	ld	ra,8(sp)
    80003df6:	6402                	ld	s0,0(sp)
    80003df8:	0141                	addi	sp,sp,16
    80003dfa:	8082                	ret

0000000080003dfc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003dfc:	1101                	addi	sp,sp,-32
    80003dfe:	ec06                	sd	ra,24(sp)
    80003e00:	e822                	sd	s0,16(sp)
    80003e02:	e426                	sd	s1,8(sp)
    80003e04:	e04a                	sd	s2,0(sp)
    80003e06:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e08:	0001d917          	auipc	s2,0x1d
    80003e0c:	46890913          	addi	s2,s2,1128 # 80021270 <log>
    80003e10:	01892583          	lw	a1,24(s2)
    80003e14:	02892503          	lw	a0,40(s2)
    80003e18:	fffff097          	auipc	ra,0xfffff
    80003e1c:	fec080e7          	jalr	-20(ra) # 80002e04 <bread>
    80003e20:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e22:	02c92683          	lw	a3,44(s2)
    80003e26:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e28:	02d05863          	blez	a3,80003e58 <write_head+0x5c>
    80003e2c:	0001d797          	auipc	a5,0x1d
    80003e30:	47478793          	addi	a5,a5,1140 # 800212a0 <log+0x30>
    80003e34:	05c50713          	addi	a4,a0,92
    80003e38:	36fd                	addiw	a3,a3,-1
    80003e3a:	02069613          	slli	a2,a3,0x20
    80003e3e:	01e65693          	srli	a3,a2,0x1e
    80003e42:	0001d617          	auipc	a2,0x1d
    80003e46:	46260613          	addi	a2,a2,1122 # 800212a4 <log+0x34>
    80003e4a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e4c:	4390                	lw	a2,0(a5)
    80003e4e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e50:	0791                	addi	a5,a5,4
    80003e52:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003e54:	fed79ce3          	bne	a5,a3,80003e4c <write_head+0x50>
  }
  bwrite(buf);
    80003e58:	8526                	mv	a0,s1
    80003e5a:	fffff097          	auipc	ra,0xfffff
    80003e5e:	09c080e7          	jalr	156(ra) # 80002ef6 <bwrite>
  brelse(buf);
    80003e62:	8526                	mv	a0,s1
    80003e64:	fffff097          	auipc	ra,0xfffff
    80003e68:	0d0080e7          	jalr	208(ra) # 80002f34 <brelse>
}
    80003e6c:	60e2                	ld	ra,24(sp)
    80003e6e:	6442                	ld	s0,16(sp)
    80003e70:	64a2                	ld	s1,8(sp)
    80003e72:	6902                	ld	s2,0(sp)
    80003e74:	6105                	addi	sp,sp,32
    80003e76:	8082                	ret

0000000080003e78 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e78:	0001d797          	auipc	a5,0x1d
    80003e7c:	4247a783          	lw	a5,1060(a5) # 8002129c <log+0x2c>
    80003e80:	0af05d63          	blez	a5,80003f3a <install_trans+0xc2>
{
    80003e84:	7139                	addi	sp,sp,-64
    80003e86:	fc06                	sd	ra,56(sp)
    80003e88:	f822                	sd	s0,48(sp)
    80003e8a:	f426                	sd	s1,40(sp)
    80003e8c:	f04a                	sd	s2,32(sp)
    80003e8e:	ec4e                	sd	s3,24(sp)
    80003e90:	e852                	sd	s4,16(sp)
    80003e92:	e456                	sd	s5,8(sp)
    80003e94:	e05a                	sd	s6,0(sp)
    80003e96:	0080                	addi	s0,sp,64
    80003e98:	8b2a                	mv	s6,a0
    80003e9a:	0001da97          	auipc	s5,0x1d
    80003e9e:	406a8a93          	addi	s5,s5,1030 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ea2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ea4:	0001d997          	auipc	s3,0x1d
    80003ea8:	3cc98993          	addi	s3,s3,972 # 80021270 <log>
    80003eac:	a00d                	j	80003ece <install_trans+0x56>
    brelse(lbuf);
    80003eae:	854a                	mv	a0,s2
    80003eb0:	fffff097          	auipc	ra,0xfffff
    80003eb4:	084080e7          	jalr	132(ra) # 80002f34 <brelse>
    brelse(dbuf);
    80003eb8:	8526                	mv	a0,s1
    80003eba:	fffff097          	auipc	ra,0xfffff
    80003ebe:	07a080e7          	jalr	122(ra) # 80002f34 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ec2:	2a05                	addiw	s4,s4,1
    80003ec4:	0a91                	addi	s5,s5,4
    80003ec6:	02c9a783          	lw	a5,44(s3)
    80003eca:	04fa5e63          	bge	s4,a5,80003f26 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ece:	0189a583          	lw	a1,24(s3)
    80003ed2:	014585bb          	addw	a1,a1,s4
    80003ed6:	2585                	addiw	a1,a1,1
    80003ed8:	0289a503          	lw	a0,40(s3)
    80003edc:	fffff097          	auipc	ra,0xfffff
    80003ee0:	f28080e7          	jalr	-216(ra) # 80002e04 <bread>
    80003ee4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ee6:	000aa583          	lw	a1,0(s5)
    80003eea:	0289a503          	lw	a0,40(s3)
    80003eee:	fffff097          	auipc	ra,0xfffff
    80003ef2:	f16080e7          	jalr	-234(ra) # 80002e04 <bread>
    80003ef6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ef8:	40000613          	li	a2,1024
    80003efc:	05890593          	addi	a1,s2,88
    80003f00:	05850513          	addi	a0,a0,88
    80003f04:	ffffd097          	auipc	ra,0xffffd
    80003f08:	e24080e7          	jalr	-476(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f0c:	8526                	mv	a0,s1
    80003f0e:	fffff097          	auipc	ra,0xfffff
    80003f12:	fe8080e7          	jalr	-24(ra) # 80002ef6 <bwrite>
    if(recovering == 0)
    80003f16:	f80b1ce3          	bnez	s6,80003eae <install_trans+0x36>
      bunpin(dbuf);
    80003f1a:	8526                	mv	a0,s1
    80003f1c:	fffff097          	auipc	ra,0xfffff
    80003f20:	0f2080e7          	jalr	242(ra) # 8000300e <bunpin>
    80003f24:	b769                	j	80003eae <install_trans+0x36>
}
    80003f26:	70e2                	ld	ra,56(sp)
    80003f28:	7442                	ld	s0,48(sp)
    80003f2a:	74a2                	ld	s1,40(sp)
    80003f2c:	7902                	ld	s2,32(sp)
    80003f2e:	69e2                	ld	s3,24(sp)
    80003f30:	6a42                	ld	s4,16(sp)
    80003f32:	6aa2                	ld	s5,8(sp)
    80003f34:	6b02                	ld	s6,0(sp)
    80003f36:	6121                	addi	sp,sp,64
    80003f38:	8082                	ret
    80003f3a:	8082                	ret

0000000080003f3c <initlog>:
{
    80003f3c:	7179                	addi	sp,sp,-48
    80003f3e:	f406                	sd	ra,40(sp)
    80003f40:	f022                	sd	s0,32(sp)
    80003f42:	ec26                	sd	s1,24(sp)
    80003f44:	e84a                	sd	s2,16(sp)
    80003f46:	e44e                	sd	s3,8(sp)
    80003f48:	1800                	addi	s0,sp,48
    80003f4a:	892a                	mv	s2,a0
    80003f4c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f4e:	0001d497          	auipc	s1,0x1d
    80003f52:	32248493          	addi	s1,s1,802 # 80021270 <log>
    80003f56:	00004597          	auipc	a1,0x4
    80003f5a:	6da58593          	addi	a1,a1,1754 # 80008630 <syscalls+0x1e8>
    80003f5e:	8526                	mv	a0,s1
    80003f60:	ffffd097          	auipc	ra,0xffffd
    80003f64:	be0080e7          	jalr	-1056(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80003f68:	0149a583          	lw	a1,20(s3)
    80003f6c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f6e:	0109a783          	lw	a5,16(s3)
    80003f72:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f74:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f78:	854a                	mv	a0,s2
    80003f7a:	fffff097          	auipc	ra,0xfffff
    80003f7e:	e8a080e7          	jalr	-374(ra) # 80002e04 <bread>
  log.lh.n = lh->n;
    80003f82:	4d34                	lw	a3,88(a0)
    80003f84:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f86:	02d05663          	blez	a3,80003fb2 <initlog+0x76>
    80003f8a:	05c50793          	addi	a5,a0,92
    80003f8e:	0001d717          	auipc	a4,0x1d
    80003f92:	31270713          	addi	a4,a4,786 # 800212a0 <log+0x30>
    80003f96:	36fd                	addiw	a3,a3,-1
    80003f98:	02069613          	slli	a2,a3,0x20
    80003f9c:	01e65693          	srli	a3,a2,0x1e
    80003fa0:	06050613          	addi	a2,a0,96
    80003fa4:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003fa6:	4390                	lw	a2,0(a5)
    80003fa8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003faa:	0791                	addi	a5,a5,4
    80003fac:	0711                	addi	a4,a4,4
    80003fae:	fed79ce3          	bne	a5,a3,80003fa6 <initlog+0x6a>
  brelse(buf);
    80003fb2:	fffff097          	auipc	ra,0xfffff
    80003fb6:	f82080e7          	jalr	-126(ra) # 80002f34 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003fba:	4505                	li	a0,1
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	ebc080e7          	jalr	-324(ra) # 80003e78 <install_trans>
  log.lh.n = 0;
    80003fc4:	0001d797          	auipc	a5,0x1d
    80003fc8:	2c07ac23          	sw	zero,728(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	e30080e7          	jalr	-464(ra) # 80003dfc <write_head>
}
    80003fd4:	70a2                	ld	ra,40(sp)
    80003fd6:	7402                	ld	s0,32(sp)
    80003fd8:	64e2                	ld	s1,24(sp)
    80003fda:	6942                	ld	s2,16(sp)
    80003fdc:	69a2                	ld	s3,8(sp)
    80003fde:	6145                	addi	sp,sp,48
    80003fe0:	8082                	ret

0000000080003fe2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fe2:	1101                	addi	sp,sp,-32
    80003fe4:	ec06                	sd	ra,24(sp)
    80003fe6:	e822                	sd	s0,16(sp)
    80003fe8:	e426                	sd	s1,8(sp)
    80003fea:	e04a                	sd	s2,0(sp)
    80003fec:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fee:	0001d517          	auipc	a0,0x1d
    80003ff2:	28250513          	addi	a0,a0,642 # 80021270 <log>
    80003ff6:	ffffd097          	auipc	ra,0xffffd
    80003ffa:	bda080e7          	jalr	-1062(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80003ffe:	0001d497          	auipc	s1,0x1d
    80004002:	27248493          	addi	s1,s1,626 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004006:	4979                	li	s2,30
    80004008:	a039                	j	80004016 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000400a:	85a6                	mv	a1,s1
    8000400c:	8526                	mv	a0,s1
    8000400e:	ffffe097          	auipc	ra,0xffffe
    80004012:	04c080e7          	jalr	76(ra) # 8000205a <sleep>
    if(log.committing){
    80004016:	50dc                	lw	a5,36(s1)
    80004018:	fbed                	bnez	a5,8000400a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000401a:	5098                	lw	a4,32(s1)
    8000401c:	2705                	addiw	a4,a4,1
    8000401e:	0007069b          	sext.w	a3,a4
    80004022:	0027179b          	slliw	a5,a4,0x2
    80004026:	9fb9                	addw	a5,a5,a4
    80004028:	0017979b          	slliw	a5,a5,0x1
    8000402c:	54d8                	lw	a4,44(s1)
    8000402e:	9fb9                	addw	a5,a5,a4
    80004030:	00f95963          	bge	s2,a5,80004042 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004034:	85a6                	mv	a1,s1
    80004036:	8526                	mv	a0,s1
    80004038:	ffffe097          	auipc	ra,0xffffe
    8000403c:	022080e7          	jalr	34(ra) # 8000205a <sleep>
    80004040:	bfd9                	j	80004016 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004042:	0001d517          	auipc	a0,0x1d
    80004046:	22e50513          	addi	a0,a0,558 # 80021270 <log>
    8000404a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000404c:	ffffd097          	auipc	ra,0xffffd
    80004050:	c38080e7          	jalr	-968(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004054:	60e2                	ld	ra,24(sp)
    80004056:	6442                	ld	s0,16(sp)
    80004058:	64a2                	ld	s1,8(sp)
    8000405a:	6902                	ld	s2,0(sp)
    8000405c:	6105                	addi	sp,sp,32
    8000405e:	8082                	ret

0000000080004060 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004060:	7139                	addi	sp,sp,-64
    80004062:	fc06                	sd	ra,56(sp)
    80004064:	f822                	sd	s0,48(sp)
    80004066:	f426                	sd	s1,40(sp)
    80004068:	f04a                	sd	s2,32(sp)
    8000406a:	ec4e                	sd	s3,24(sp)
    8000406c:	e852                	sd	s4,16(sp)
    8000406e:	e456                	sd	s5,8(sp)
    80004070:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004072:	0001d497          	auipc	s1,0x1d
    80004076:	1fe48493          	addi	s1,s1,510 # 80021270 <log>
    8000407a:	8526                	mv	a0,s1
    8000407c:	ffffd097          	auipc	ra,0xffffd
    80004080:	b54080e7          	jalr	-1196(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    80004084:	509c                	lw	a5,32(s1)
    80004086:	37fd                	addiw	a5,a5,-1
    80004088:	0007891b          	sext.w	s2,a5
    8000408c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000408e:	50dc                	lw	a5,36(s1)
    80004090:	e7b9                	bnez	a5,800040de <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004092:	04091e63          	bnez	s2,800040ee <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004096:	0001d497          	auipc	s1,0x1d
    8000409a:	1da48493          	addi	s1,s1,474 # 80021270 <log>
    8000409e:	4785                	li	a5,1
    800040a0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040a2:	8526                	mv	a0,s1
    800040a4:	ffffd097          	auipc	ra,0xffffd
    800040a8:	be0080e7          	jalr	-1056(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040ac:	54dc                	lw	a5,44(s1)
    800040ae:	06f04763          	bgtz	a5,8000411c <end_op+0xbc>
    acquire(&log.lock);
    800040b2:	0001d497          	auipc	s1,0x1d
    800040b6:	1be48493          	addi	s1,s1,446 # 80021270 <log>
    800040ba:	8526                	mv	a0,s1
    800040bc:	ffffd097          	auipc	ra,0xffffd
    800040c0:	b14080e7          	jalr	-1260(ra) # 80000bd0 <acquire>
    log.committing = 0;
    800040c4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040c8:	8526                	mv	a0,s1
    800040ca:	ffffe097          	auipc	ra,0xffffe
    800040ce:	11c080e7          	jalr	284(ra) # 800021e6 <wakeup>
    release(&log.lock);
    800040d2:	8526                	mv	a0,s1
    800040d4:	ffffd097          	auipc	ra,0xffffd
    800040d8:	bb0080e7          	jalr	-1104(ra) # 80000c84 <release>
}
    800040dc:	a03d                	j	8000410a <end_op+0xaa>
    panic("log.committing");
    800040de:	00004517          	auipc	a0,0x4
    800040e2:	55a50513          	addi	a0,a0,1370 # 80008638 <syscalls+0x1f0>
    800040e6:	ffffc097          	auipc	ra,0xffffc
    800040ea:	454080e7          	jalr	1108(ra) # 8000053a <panic>
    wakeup(&log);
    800040ee:	0001d497          	auipc	s1,0x1d
    800040f2:	18248493          	addi	s1,s1,386 # 80021270 <log>
    800040f6:	8526                	mv	a0,s1
    800040f8:	ffffe097          	auipc	ra,0xffffe
    800040fc:	0ee080e7          	jalr	238(ra) # 800021e6 <wakeup>
  release(&log.lock);
    80004100:	8526                	mv	a0,s1
    80004102:	ffffd097          	auipc	ra,0xffffd
    80004106:	b82080e7          	jalr	-1150(ra) # 80000c84 <release>
}
    8000410a:	70e2                	ld	ra,56(sp)
    8000410c:	7442                	ld	s0,48(sp)
    8000410e:	74a2                	ld	s1,40(sp)
    80004110:	7902                	ld	s2,32(sp)
    80004112:	69e2                	ld	s3,24(sp)
    80004114:	6a42                	ld	s4,16(sp)
    80004116:	6aa2                	ld	s5,8(sp)
    80004118:	6121                	addi	sp,sp,64
    8000411a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000411c:	0001da97          	auipc	s5,0x1d
    80004120:	184a8a93          	addi	s5,s5,388 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004124:	0001da17          	auipc	s4,0x1d
    80004128:	14ca0a13          	addi	s4,s4,332 # 80021270 <log>
    8000412c:	018a2583          	lw	a1,24(s4)
    80004130:	012585bb          	addw	a1,a1,s2
    80004134:	2585                	addiw	a1,a1,1
    80004136:	028a2503          	lw	a0,40(s4)
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	cca080e7          	jalr	-822(ra) # 80002e04 <bread>
    80004142:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004144:	000aa583          	lw	a1,0(s5)
    80004148:	028a2503          	lw	a0,40(s4)
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	cb8080e7          	jalr	-840(ra) # 80002e04 <bread>
    80004154:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004156:	40000613          	li	a2,1024
    8000415a:	05850593          	addi	a1,a0,88
    8000415e:	05848513          	addi	a0,s1,88
    80004162:	ffffd097          	auipc	ra,0xffffd
    80004166:	bc6080e7          	jalr	-1082(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    8000416a:	8526                	mv	a0,s1
    8000416c:	fffff097          	auipc	ra,0xfffff
    80004170:	d8a080e7          	jalr	-630(ra) # 80002ef6 <bwrite>
    brelse(from);
    80004174:	854e                	mv	a0,s3
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	dbe080e7          	jalr	-578(ra) # 80002f34 <brelse>
    brelse(to);
    8000417e:	8526                	mv	a0,s1
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	db4080e7          	jalr	-588(ra) # 80002f34 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004188:	2905                	addiw	s2,s2,1
    8000418a:	0a91                	addi	s5,s5,4
    8000418c:	02ca2783          	lw	a5,44(s4)
    80004190:	f8f94ee3          	blt	s2,a5,8000412c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004194:	00000097          	auipc	ra,0x0
    80004198:	c68080e7          	jalr	-920(ra) # 80003dfc <write_head>
    install_trans(0); // Now install writes to home locations
    8000419c:	4501                	li	a0,0
    8000419e:	00000097          	auipc	ra,0x0
    800041a2:	cda080e7          	jalr	-806(ra) # 80003e78 <install_trans>
    log.lh.n = 0;
    800041a6:	0001d797          	auipc	a5,0x1d
    800041aa:	0e07ab23          	sw	zero,246(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041ae:	00000097          	auipc	ra,0x0
    800041b2:	c4e080e7          	jalr	-946(ra) # 80003dfc <write_head>
    800041b6:	bdf5                	j	800040b2 <end_op+0x52>

00000000800041b8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041b8:	1101                	addi	sp,sp,-32
    800041ba:	ec06                	sd	ra,24(sp)
    800041bc:	e822                	sd	s0,16(sp)
    800041be:	e426                	sd	s1,8(sp)
    800041c0:	e04a                	sd	s2,0(sp)
    800041c2:	1000                	addi	s0,sp,32
    800041c4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041c6:	0001d917          	auipc	s2,0x1d
    800041ca:	0aa90913          	addi	s2,s2,170 # 80021270 <log>
    800041ce:	854a                	mv	a0,s2
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	a00080e7          	jalr	-1536(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041d8:	02c92603          	lw	a2,44(s2)
    800041dc:	47f5                	li	a5,29
    800041de:	06c7c563          	blt	a5,a2,80004248 <log_write+0x90>
    800041e2:	0001d797          	auipc	a5,0x1d
    800041e6:	0aa7a783          	lw	a5,170(a5) # 8002128c <log+0x1c>
    800041ea:	37fd                	addiw	a5,a5,-1
    800041ec:	04f65e63          	bge	a2,a5,80004248 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041f0:	0001d797          	auipc	a5,0x1d
    800041f4:	0a07a783          	lw	a5,160(a5) # 80021290 <log+0x20>
    800041f8:	06f05063          	blez	a5,80004258 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800041fc:	4781                	li	a5,0
    800041fe:	06c05563          	blez	a2,80004268 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004202:	44cc                	lw	a1,12(s1)
    80004204:	0001d717          	auipc	a4,0x1d
    80004208:	09c70713          	addi	a4,a4,156 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000420c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000420e:	4314                	lw	a3,0(a4)
    80004210:	04b68c63          	beq	a3,a1,80004268 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004214:	2785                	addiw	a5,a5,1
    80004216:	0711                	addi	a4,a4,4
    80004218:	fef61be3          	bne	a2,a5,8000420e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000421c:	0621                	addi	a2,a2,8
    8000421e:	060a                	slli	a2,a2,0x2
    80004220:	0001d797          	auipc	a5,0x1d
    80004224:	05078793          	addi	a5,a5,80 # 80021270 <log>
    80004228:	97b2                	add	a5,a5,a2
    8000422a:	44d8                	lw	a4,12(s1)
    8000422c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000422e:	8526                	mv	a0,s1
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	da2080e7          	jalr	-606(ra) # 80002fd2 <bpin>
    log.lh.n++;
    80004238:	0001d717          	auipc	a4,0x1d
    8000423c:	03870713          	addi	a4,a4,56 # 80021270 <log>
    80004240:	575c                	lw	a5,44(a4)
    80004242:	2785                	addiw	a5,a5,1
    80004244:	d75c                	sw	a5,44(a4)
    80004246:	a82d                	j	80004280 <log_write+0xc8>
    panic("too big a transaction");
    80004248:	00004517          	auipc	a0,0x4
    8000424c:	40050513          	addi	a0,a0,1024 # 80008648 <syscalls+0x200>
    80004250:	ffffc097          	auipc	ra,0xffffc
    80004254:	2ea080e7          	jalr	746(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004258:	00004517          	auipc	a0,0x4
    8000425c:	40850513          	addi	a0,a0,1032 # 80008660 <syscalls+0x218>
    80004260:	ffffc097          	auipc	ra,0xffffc
    80004264:	2da080e7          	jalr	730(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004268:	00878693          	addi	a3,a5,8
    8000426c:	068a                	slli	a3,a3,0x2
    8000426e:	0001d717          	auipc	a4,0x1d
    80004272:	00270713          	addi	a4,a4,2 # 80021270 <log>
    80004276:	9736                	add	a4,a4,a3
    80004278:	44d4                	lw	a3,12(s1)
    8000427a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000427c:	faf609e3          	beq	a2,a5,8000422e <log_write+0x76>
  }
  release(&log.lock);
    80004280:	0001d517          	auipc	a0,0x1d
    80004284:	ff050513          	addi	a0,a0,-16 # 80021270 <log>
    80004288:	ffffd097          	auipc	ra,0xffffd
    8000428c:	9fc080e7          	jalr	-1540(ra) # 80000c84 <release>
}
    80004290:	60e2                	ld	ra,24(sp)
    80004292:	6442                	ld	s0,16(sp)
    80004294:	64a2                	ld	s1,8(sp)
    80004296:	6902                	ld	s2,0(sp)
    80004298:	6105                	addi	sp,sp,32
    8000429a:	8082                	ret

000000008000429c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000429c:	1101                	addi	sp,sp,-32
    8000429e:	ec06                	sd	ra,24(sp)
    800042a0:	e822                	sd	s0,16(sp)
    800042a2:	e426                	sd	s1,8(sp)
    800042a4:	e04a                	sd	s2,0(sp)
    800042a6:	1000                	addi	s0,sp,32
    800042a8:	84aa                	mv	s1,a0
    800042aa:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042ac:	00004597          	auipc	a1,0x4
    800042b0:	3d458593          	addi	a1,a1,980 # 80008680 <syscalls+0x238>
    800042b4:	0521                	addi	a0,a0,8
    800042b6:	ffffd097          	auipc	ra,0xffffd
    800042ba:	88a080e7          	jalr	-1910(ra) # 80000b40 <initlock>
  lk->name = name;
    800042be:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042c2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042c6:	0204a423          	sw	zero,40(s1)
}
    800042ca:	60e2                	ld	ra,24(sp)
    800042cc:	6442                	ld	s0,16(sp)
    800042ce:	64a2                	ld	s1,8(sp)
    800042d0:	6902                	ld	s2,0(sp)
    800042d2:	6105                	addi	sp,sp,32
    800042d4:	8082                	ret

00000000800042d6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042d6:	1101                	addi	sp,sp,-32
    800042d8:	ec06                	sd	ra,24(sp)
    800042da:	e822                	sd	s0,16(sp)
    800042dc:	e426                	sd	s1,8(sp)
    800042de:	e04a                	sd	s2,0(sp)
    800042e0:	1000                	addi	s0,sp,32
    800042e2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042e4:	00850913          	addi	s2,a0,8
    800042e8:	854a                	mv	a0,s2
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	8e6080e7          	jalr	-1818(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    800042f2:	409c                	lw	a5,0(s1)
    800042f4:	cb89                	beqz	a5,80004306 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042f6:	85ca                	mv	a1,s2
    800042f8:	8526                	mv	a0,s1
    800042fa:	ffffe097          	auipc	ra,0xffffe
    800042fe:	d60080e7          	jalr	-672(ra) # 8000205a <sleep>
  while (lk->locked) {
    80004302:	409c                	lw	a5,0(s1)
    80004304:	fbed                	bnez	a5,800042f6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004306:	4785                	li	a5,1
    80004308:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000430a:	ffffd097          	auipc	ra,0xffffd
    8000430e:	68c080e7          	jalr	1676(ra) # 80001996 <myproc>
    80004312:	591c                	lw	a5,48(a0)
    80004314:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004316:	854a                	mv	a0,s2
    80004318:	ffffd097          	auipc	ra,0xffffd
    8000431c:	96c080e7          	jalr	-1684(ra) # 80000c84 <release>
}
    80004320:	60e2                	ld	ra,24(sp)
    80004322:	6442                	ld	s0,16(sp)
    80004324:	64a2                	ld	s1,8(sp)
    80004326:	6902                	ld	s2,0(sp)
    80004328:	6105                	addi	sp,sp,32
    8000432a:	8082                	ret

000000008000432c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000432c:	1101                	addi	sp,sp,-32
    8000432e:	ec06                	sd	ra,24(sp)
    80004330:	e822                	sd	s0,16(sp)
    80004332:	e426                	sd	s1,8(sp)
    80004334:	e04a                	sd	s2,0(sp)
    80004336:	1000                	addi	s0,sp,32
    80004338:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000433a:	00850913          	addi	s2,a0,8
    8000433e:	854a                	mv	a0,s2
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	890080e7          	jalr	-1904(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    80004348:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000434c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004350:	8526                	mv	a0,s1
    80004352:	ffffe097          	auipc	ra,0xffffe
    80004356:	e94080e7          	jalr	-364(ra) # 800021e6 <wakeup>
  release(&lk->lk);
    8000435a:	854a                	mv	a0,s2
    8000435c:	ffffd097          	auipc	ra,0xffffd
    80004360:	928080e7          	jalr	-1752(ra) # 80000c84 <release>
}
    80004364:	60e2                	ld	ra,24(sp)
    80004366:	6442                	ld	s0,16(sp)
    80004368:	64a2                	ld	s1,8(sp)
    8000436a:	6902                	ld	s2,0(sp)
    8000436c:	6105                	addi	sp,sp,32
    8000436e:	8082                	ret

0000000080004370 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004370:	7179                	addi	sp,sp,-48
    80004372:	f406                	sd	ra,40(sp)
    80004374:	f022                	sd	s0,32(sp)
    80004376:	ec26                	sd	s1,24(sp)
    80004378:	e84a                	sd	s2,16(sp)
    8000437a:	e44e                	sd	s3,8(sp)
    8000437c:	1800                	addi	s0,sp,48
    8000437e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004380:	00850913          	addi	s2,a0,8
    80004384:	854a                	mv	a0,s2
    80004386:	ffffd097          	auipc	ra,0xffffd
    8000438a:	84a080e7          	jalr	-1974(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000438e:	409c                	lw	a5,0(s1)
    80004390:	ef99                	bnez	a5,800043ae <holdingsleep+0x3e>
    80004392:	4481                	li	s1,0
  release(&lk->lk);
    80004394:	854a                	mv	a0,s2
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	8ee080e7          	jalr	-1810(ra) # 80000c84 <release>
  return r;
}
    8000439e:	8526                	mv	a0,s1
    800043a0:	70a2                	ld	ra,40(sp)
    800043a2:	7402                	ld	s0,32(sp)
    800043a4:	64e2                	ld	s1,24(sp)
    800043a6:	6942                	ld	s2,16(sp)
    800043a8:	69a2                	ld	s3,8(sp)
    800043aa:	6145                	addi	sp,sp,48
    800043ac:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043ae:	0284a983          	lw	s3,40(s1)
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	5e4080e7          	jalr	1508(ra) # 80001996 <myproc>
    800043ba:	5904                	lw	s1,48(a0)
    800043bc:	413484b3          	sub	s1,s1,s3
    800043c0:	0014b493          	seqz	s1,s1
    800043c4:	bfc1                	j	80004394 <holdingsleep+0x24>

00000000800043c6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043c6:	1141                	addi	sp,sp,-16
    800043c8:	e406                	sd	ra,8(sp)
    800043ca:	e022                	sd	s0,0(sp)
    800043cc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043ce:	00004597          	auipc	a1,0x4
    800043d2:	2c258593          	addi	a1,a1,706 # 80008690 <syscalls+0x248>
    800043d6:	0001d517          	auipc	a0,0x1d
    800043da:	fe250513          	addi	a0,a0,-30 # 800213b8 <ftable>
    800043de:	ffffc097          	auipc	ra,0xffffc
    800043e2:	762080e7          	jalr	1890(ra) # 80000b40 <initlock>
}
    800043e6:	60a2                	ld	ra,8(sp)
    800043e8:	6402                	ld	s0,0(sp)
    800043ea:	0141                	addi	sp,sp,16
    800043ec:	8082                	ret

00000000800043ee <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043ee:	1101                	addi	sp,sp,-32
    800043f0:	ec06                	sd	ra,24(sp)
    800043f2:	e822                	sd	s0,16(sp)
    800043f4:	e426                	sd	s1,8(sp)
    800043f6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043f8:	0001d517          	auipc	a0,0x1d
    800043fc:	fc050513          	addi	a0,a0,-64 # 800213b8 <ftable>
    80004400:	ffffc097          	auipc	ra,0xffffc
    80004404:	7d0080e7          	jalr	2000(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004408:	0001d497          	auipc	s1,0x1d
    8000440c:	fc848493          	addi	s1,s1,-56 # 800213d0 <ftable+0x18>
    80004410:	0001e717          	auipc	a4,0x1e
    80004414:	f6070713          	addi	a4,a4,-160 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004418:	40dc                	lw	a5,4(s1)
    8000441a:	cf99                	beqz	a5,80004438 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000441c:	02848493          	addi	s1,s1,40
    80004420:	fee49ce3          	bne	s1,a4,80004418 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004424:	0001d517          	auipc	a0,0x1d
    80004428:	f9450513          	addi	a0,a0,-108 # 800213b8 <ftable>
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	858080e7          	jalr	-1960(ra) # 80000c84 <release>
  return 0;
    80004434:	4481                	li	s1,0
    80004436:	a819                	j	8000444c <filealloc+0x5e>
      f->ref = 1;
    80004438:	4785                	li	a5,1
    8000443a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000443c:	0001d517          	auipc	a0,0x1d
    80004440:	f7c50513          	addi	a0,a0,-132 # 800213b8 <ftable>
    80004444:	ffffd097          	auipc	ra,0xffffd
    80004448:	840080e7          	jalr	-1984(ra) # 80000c84 <release>
}
    8000444c:	8526                	mv	a0,s1
    8000444e:	60e2                	ld	ra,24(sp)
    80004450:	6442                	ld	s0,16(sp)
    80004452:	64a2                	ld	s1,8(sp)
    80004454:	6105                	addi	sp,sp,32
    80004456:	8082                	ret

0000000080004458 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004458:	1101                	addi	sp,sp,-32
    8000445a:	ec06                	sd	ra,24(sp)
    8000445c:	e822                	sd	s0,16(sp)
    8000445e:	e426                	sd	s1,8(sp)
    80004460:	1000                	addi	s0,sp,32
    80004462:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004464:	0001d517          	auipc	a0,0x1d
    80004468:	f5450513          	addi	a0,a0,-172 # 800213b8 <ftable>
    8000446c:	ffffc097          	auipc	ra,0xffffc
    80004470:	764080e7          	jalr	1892(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004474:	40dc                	lw	a5,4(s1)
    80004476:	02f05263          	blez	a5,8000449a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000447a:	2785                	addiw	a5,a5,1
    8000447c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000447e:	0001d517          	auipc	a0,0x1d
    80004482:	f3a50513          	addi	a0,a0,-198 # 800213b8 <ftable>
    80004486:	ffffc097          	auipc	ra,0xffffc
    8000448a:	7fe080e7          	jalr	2046(ra) # 80000c84 <release>
  return f;
}
    8000448e:	8526                	mv	a0,s1
    80004490:	60e2                	ld	ra,24(sp)
    80004492:	6442                	ld	s0,16(sp)
    80004494:	64a2                	ld	s1,8(sp)
    80004496:	6105                	addi	sp,sp,32
    80004498:	8082                	ret
    panic("filedup");
    8000449a:	00004517          	auipc	a0,0x4
    8000449e:	1fe50513          	addi	a0,a0,510 # 80008698 <syscalls+0x250>
    800044a2:	ffffc097          	auipc	ra,0xffffc
    800044a6:	098080e7          	jalr	152(ra) # 8000053a <panic>

00000000800044aa <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044aa:	7139                	addi	sp,sp,-64
    800044ac:	fc06                	sd	ra,56(sp)
    800044ae:	f822                	sd	s0,48(sp)
    800044b0:	f426                	sd	s1,40(sp)
    800044b2:	f04a                	sd	s2,32(sp)
    800044b4:	ec4e                	sd	s3,24(sp)
    800044b6:	e852                	sd	s4,16(sp)
    800044b8:	e456                	sd	s5,8(sp)
    800044ba:	0080                	addi	s0,sp,64
    800044bc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800044be:	0001d517          	auipc	a0,0x1d
    800044c2:	efa50513          	addi	a0,a0,-262 # 800213b8 <ftable>
    800044c6:	ffffc097          	auipc	ra,0xffffc
    800044ca:	70a080e7          	jalr	1802(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800044ce:	40dc                	lw	a5,4(s1)
    800044d0:	06f05163          	blez	a5,80004532 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044d4:	37fd                	addiw	a5,a5,-1
    800044d6:	0007871b          	sext.w	a4,a5
    800044da:	c0dc                	sw	a5,4(s1)
    800044dc:	06e04363          	bgtz	a4,80004542 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044e0:	0004a903          	lw	s2,0(s1)
    800044e4:	0094ca83          	lbu	s5,9(s1)
    800044e8:	0104ba03          	ld	s4,16(s1)
    800044ec:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044f0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044f4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044f8:	0001d517          	auipc	a0,0x1d
    800044fc:	ec050513          	addi	a0,a0,-320 # 800213b8 <ftable>
    80004500:	ffffc097          	auipc	ra,0xffffc
    80004504:	784080e7          	jalr	1924(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    80004508:	4785                	li	a5,1
    8000450a:	04f90d63          	beq	s2,a5,80004564 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000450e:	3979                	addiw	s2,s2,-2
    80004510:	4785                	li	a5,1
    80004512:	0527e063          	bltu	a5,s2,80004552 <fileclose+0xa8>
    begin_op();
    80004516:	00000097          	auipc	ra,0x0
    8000451a:	acc080e7          	jalr	-1332(ra) # 80003fe2 <begin_op>
    iput(ff.ip);
    8000451e:	854e                	mv	a0,s3
    80004520:	fffff097          	auipc	ra,0xfffff
    80004524:	2a0080e7          	jalr	672(ra) # 800037c0 <iput>
    end_op();
    80004528:	00000097          	auipc	ra,0x0
    8000452c:	b38080e7          	jalr	-1224(ra) # 80004060 <end_op>
    80004530:	a00d                	j	80004552 <fileclose+0xa8>
    panic("fileclose");
    80004532:	00004517          	auipc	a0,0x4
    80004536:	16e50513          	addi	a0,a0,366 # 800086a0 <syscalls+0x258>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	000080e7          	jalr	ra # 8000053a <panic>
    release(&ftable.lock);
    80004542:	0001d517          	auipc	a0,0x1d
    80004546:	e7650513          	addi	a0,a0,-394 # 800213b8 <ftable>
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	73a080e7          	jalr	1850(ra) # 80000c84 <release>
  }
}
    80004552:	70e2                	ld	ra,56(sp)
    80004554:	7442                	ld	s0,48(sp)
    80004556:	74a2                	ld	s1,40(sp)
    80004558:	7902                	ld	s2,32(sp)
    8000455a:	69e2                	ld	s3,24(sp)
    8000455c:	6a42                	ld	s4,16(sp)
    8000455e:	6aa2                	ld	s5,8(sp)
    80004560:	6121                	addi	sp,sp,64
    80004562:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004564:	85d6                	mv	a1,s5
    80004566:	8552                	mv	a0,s4
    80004568:	00000097          	auipc	ra,0x0
    8000456c:	34c080e7          	jalr	844(ra) # 800048b4 <pipeclose>
    80004570:	b7cd                	j	80004552 <fileclose+0xa8>

0000000080004572 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004572:	715d                	addi	sp,sp,-80
    80004574:	e486                	sd	ra,72(sp)
    80004576:	e0a2                	sd	s0,64(sp)
    80004578:	fc26                	sd	s1,56(sp)
    8000457a:	f84a                	sd	s2,48(sp)
    8000457c:	f44e                	sd	s3,40(sp)
    8000457e:	0880                	addi	s0,sp,80
    80004580:	84aa                	mv	s1,a0
    80004582:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004584:	ffffd097          	auipc	ra,0xffffd
    80004588:	412080e7          	jalr	1042(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000458c:	409c                	lw	a5,0(s1)
    8000458e:	37f9                	addiw	a5,a5,-2
    80004590:	4705                	li	a4,1
    80004592:	04f76763          	bltu	a4,a5,800045e0 <filestat+0x6e>
    80004596:	892a                	mv	s2,a0
    ilock(f->ip);
    80004598:	6c88                	ld	a0,24(s1)
    8000459a:	fffff097          	auipc	ra,0xfffff
    8000459e:	06c080e7          	jalr	108(ra) # 80003606 <ilock>
    stati(f->ip, &st);
    800045a2:	fb840593          	addi	a1,s0,-72
    800045a6:	6c88                	ld	a0,24(s1)
    800045a8:	fffff097          	auipc	ra,0xfffff
    800045ac:	2e8080e7          	jalr	744(ra) # 80003890 <stati>
    iunlock(f->ip);
    800045b0:	6c88                	ld	a0,24(s1)
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	116080e7          	jalr	278(ra) # 800036c8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045ba:	46e1                	li	a3,24
    800045bc:	fb840613          	addi	a2,s0,-72
    800045c0:	85ce                	mv	a1,s3
    800045c2:	05093503          	ld	a0,80(s2)
    800045c6:	ffffd097          	auipc	ra,0xffffd
    800045ca:	094080e7          	jalr	148(ra) # 8000165a <copyout>
    800045ce:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045d2:	60a6                	ld	ra,72(sp)
    800045d4:	6406                	ld	s0,64(sp)
    800045d6:	74e2                	ld	s1,56(sp)
    800045d8:	7942                	ld	s2,48(sp)
    800045da:	79a2                	ld	s3,40(sp)
    800045dc:	6161                	addi	sp,sp,80
    800045de:	8082                	ret
  return -1;
    800045e0:	557d                	li	a0,-1
    800045e2:	bfc5                	j	800045d2 <filestat+0x60>

00000000800045e4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045e4:	7179                	addi	sp,sp,-48
    800045e6:	f406                	sd	ra,40(sp)
    800045e8:	f022                	sd	s0,32(sp)
    800045ea:	ec26                	sd	s1,24(sp)
    800045ec:	e84a                	sd	s2,16(sp)
    800045ee:	e44e                	sd	s3,8(sp)
    800045f0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045f2:	00854783          	lbu	a5,8(a0)
    800045f6:	c3d5                	beqz	a5,8000469a <fileread+0xb6>
    800045f8:	84aa                	mv	s1,a0
    800045fa:	89ae                	mv	s3,a1
    800045fc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045fe:	411c                	lw	a5,0(a0)
    80004600:	4705                	li	a4,1
    80004602:	04e78963          	beq	a5,a4,80004654 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004606:	470d                	li	a4,3
    80004608:	04e78d63          	beq	a5,a4,80004662 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000460c:	4709                	li	a4,2
    8000460e:	06e79e63          	bne	a5,a4,8000468a <fileread+0xa6>
    ilock(f->ip);
    80004612:	6d08                	ld	a0,24(a0)
    80004614:	fffff097          	auipc	ra,0xfffff
    80004618:	ff2080e7          	jalr	-14(ra) # 80003606 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000461c:	874a                	mv	a4,s2
    8000461e:	5094                	lw	a3,32(s1)
    80004620:	864e                	mv	a2,s3
    80004622:	4585                	li	a1,1
    80004624:	6c88                	ld	a0,24(s1)
    80004626:	fffff097          	auipc	ra,0xfffff
    8000462a:	294080e7          	jalr	660(ra) # 800038ba <readi>
    8000462e:	892a                	mv	s2,a0
    80004630:	00a05563          	blez	a0,8000463a <fileread+0x56>
      f->off += r;
    80004634:	509c                	lw	a5,32(s1)
    80004636:	9fa9                	addw	a5,a5,a0
    80004638:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000463a:	6c88                	ld	a0,24(s1)
    8000463c:	fffff097          	auipc	ra,0xfffff
    80004640:	08c080e7          	jalr	140(ra) # 800036c8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004644:	854a                	mv	a0,s2
    80004646:	70a2                	ld	ra,40(sp)
    80004648:	7402                	ld	s0,32(sp)
    8000464a:	64e2                	ld	s1,24(sp)
    8000464c:	6942                	ld	s2,16(sp)
    8000464e:	69a2                	ld	s3,8(sp)
    80004650:	6145                	addi	sp,sp,48
    80004652:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004654:	6908                	ld	a0,16(a0)
    80004656:	00000097          	auipc	ra,0x0
    8000465a:	3c0080e7          	jalr	960(ra) # 80004a16 <piperead>
    8000465e:	892a                	mv	s2,a0
    80004660:	b7d5                	j	80004644 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004662:	02451783          	lh	a5,36(a0)
    80004666:	03079693          	slli	a3,a5,0x30
    8000466a:	92c1                	srli	a3,a3,0x30
    8000466c:	4725                	li	a4,9
    8000466e:	02d76863          	bltu	a4,a3,8000469e <fileread+0xba>
    80004672:	0792                	slli	a5,a5,0x4
    80004674:	0001d717          	auipc	a4,0x1d
    80004678:	ca470713          	addi	a4,a4,-860 # 80021318 <devsw>
    8000467c:	97ba                	add	a5,a5,a4
    8000467e:	639c                	ld	a5,0(a5)
    80004680:	c38d                	beqz	a5,800046a2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004682:	4505                	li	a0,1
    80004684:	9782                	jalr	a5
    80004686:	892a                	mv	s2,a0
    80004688:	bf75                	j	80004644 <fileread+0x60>
    panic("fileread");
    8000468a:	00004517          	auipc	a0,0x4
    8000468e:	02650513          	addi	a0,a0,38 # 800086b0 <syscalls+0x268>
    80004692:	ffffc097          	auipc	ra,0xffffc
    80004696:	ea8080e7          	jalr	-344(ra) # 8000053a <panic>
    return -1;
    8000469a:	597d                	li	s2,-1
    8000469c:	b765                	j	80004644 <fileread+0x60>
      return -1;
    8000469e:	597d                	li	s2,-1
    800046a0:	b755                	j	80004644 <fileread+0x60>
    800046a2:	597d                	li	s2,-1
    800046a4:	b745                	j	80004644 <fileread+0x60>

00000000800046a6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046a6:	715d                	addi	sp,sp,-80
    800046a8:	e486                	sd	ra,72(sp)
    800046aa:	e0a2                	sd	s0,64(sp)
    800046ac:	fc26                	sd	s1,56(sp)
    800046ae:	f84a                	sd	s2,48(sp)
    800046b0:	f44e                	sd	s3,40(sp)
    800046b2:	f052                	sd	s4,32(sp)
    800046b4:	ec56                	sd	s5,24(sp)
    800046b6:	e85a                	sd	s6,16(sp)
    800046b8:	e45e                	sd	s7,8(sp)
    800046ba:	e062                	sd	s8,0(sp)
    800046bc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800046be:	00954783          	lbu	a5,9(a0)
    800046c2:	10078663          	beqz	a5,800047ce <filewrite+0x128>
    800046c6:	892a                	mv	s2,a0
    800046c8:	8b2e                	mv	s6,a1
    800046ca:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800046cc:	411c                	lw	a5,0(a0)
    800046ce:	4705                	li	a4,1
    800046d0:	02e78263          	beq	a5,a4,800046f4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046d4:	470d                	li	a4,3
    800046d6:	02e78663          	beq	a5,a4,80004702 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046da:	4709                	li	a4,2
    800046dc:	0ee79163          	bne	a5,a4,800047be <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046e0:	0ac05d63          	blez	a2,8000479a <filewrite+0xf4>
    int i = 0;
    800046e4:	4981                	li	s3,0
    800046e6:	6b85                	lui	s7,0x1
    800046e8:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800046ec:	6c05                	lui	s8,0x1
    800046ee:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800046f2:	a861                	j	8000478a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800046f4:	6908                	ld	a0,16(a0)
    800046f6:	00000097          	auipc	ra,0x0
    800046fa:	22e080e7          	jalr	558(ra) # 80004924 <pipewrite>
    800046fe:	8a2a                	mv	s4,a0
    80004700:	a045                	j	800047a0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004702:	02451783          	lh	a5,36(a0)
    80004706:	03079693          	slli	a3,a5,0x30
    8000470a:	92c1                	srli	a3,a3,0x30
    8000470c:	4725                	li	a4,9
    8000470e:	0cd76263          	bltu	a4,a3,800047d2 <filewrite+0x12c>
    80004712:	0792                	slli	a5,a5,0x4
    80004714:	0001d717          	auipc	a4,0x1d
    80004718:	c0470713          	addi	a4,a4,-1020 # 80021318 <devsw>
    8000471c:	97ba                	add	a5,a5,a4
    8000471e:	679c                	ld	a5,8(a5)
    80004720:	cbdd                	beqz	a5,800047d6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004722:	4505                	li	a0,1
    80004724:	9782                	jalr	a5
    80004726:	8a2a                	mv	s4,a0
    80004728:	a8a5                	j	800047a0 <filewrite+0xfa>
    8000472a:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000472e:	00000097          	auipc	ra,0x0
    80004732:	8b4080e7          	jalr	-1868(ra) # 80003fe2 <begin_op>
      ilock(f->ip);
    80004736:	01893503          	ld	a0,24(s2)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	ecc080e7          	jalr	-308(ra) # 80003606 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004742:	8756                	mv	a4,s5
    80004744:	02092683          	lw	a3,32(s2)
    80004748:	01698633          	add	a2,s3,s6
    8000474c:	4585                	li	a1,1
    8000474e:	01893503          	ld	a0,24(s2)
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	260080e7          	jalr	608(ra) # 800039b2 <writei>
    8000475a:	84aa                	mv	s1,a0
    8000475c:	00a05763          	blez	a0,8000476a <filewrite+0xc4>
        f->off += r;
    80004760:	02092783          	lw	a5,32(s2)
    80004764:	9fa9                	addw	a5,a5,a0
    80004766:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000476a:	01893503          	ld	a0,24(s2)
    8000476e:	fffff097          	auipc	ra,0xfffff
    80004772:	f5a080e7          	jalr	-166(ra) # 800036c8 <iunlock>
      end_op();
    80004776:	00000097          	auipc	ra,0x0
    8000477a:	8ea080e7          	jalr	-1814(ra) # 80004060 <end_op>

      if(r != n1){
    8000477e:	009a9f63          	bne	s5,s1,8000479c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004782:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004786:	0149db63          	bge	s3,s4,8000479c <filewrite+0xf6>
      int n1 = n - i;
    8000478a:	413a04bb          	subw	s1,s4,s3
    8000478e:	0004879b          	sext.w	a5,s1
    80004792:	f8fbdce3          	bge	s7,a5,8000472a <filewrite+0x84>
    80004796:	84e2                	mv	s1,s8
    80004798:	bf49                	j	8000472a <filewrite+0x84>
    int i = 0;
    8000479a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000479c:	013a1f63          	bne	s4,s3,800047ba <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047a0:	8552                	mv	a0,s4
    800047a2:	60a6                	ld	ra,72(sp)
    800047a4:	6406                	ld	s0,64(sp)
    800047a6:	74e2                	ld	s1,56(sp)
    800047a8:	7942                	ld	s2,48(sp)
    800047aa:	79a2                	ld	s3,40(sp)
    800047ac:	7a02                	ld	s4,32(sp)
    800047ae:	6ae2                	ld	s5,24(sp)
    800047b0:	6b42                	ld	s6,16(sp)
    800047b2:	6ba2                	ld	s7,8(sp)
    800047b4:	6c02                	ld	s8,0(sp)
    800047b6:	6161                	addi	sp,sp,80
    800047b8:	8082                	ret
    ret = (i == n ? n : -1);
    800047ba:	5a7d                	li	s4,-1
    800047bc:	b7d5                	j	800047a0 <filewrite+0xfa>
    panic("filewrite");
    800047be:	00004517          	auipc	a0,0x4
    800047c2:	f0250513          	addi	a0,a0,-254 # 800086c0 <syscalls+0x278>
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	d74080e7          	jalr	-652(ra) # 8000053a <panic>
    return -1;
    800047ce:	5a7d                	li	s4,-1
    800047d0:	bfc1                	j	800047a0 <filewrite+0xfa>
      return -1;
    800047d2:	5a7d                	li	s4,-1
    800047d4:	b7f1                	j	800047a0 <filewrite+0xfa>
    800047d6:	5a7d                	li	s4,-1
    800047d8:	b7e1                	j	800047a0 <filewrite+0xfa>

00000000800047da <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047da:	7179                	addi	sp,sp,-48
    800047dc:	f406                	sd	ra,40(sp)
    800047de:	f022                	sd	s0,32(sp)
    800047e0:	ec26                	sd	s1,24(sp)
    800047e2:	e84a                	sd	s2,16(sp)
    800047e4:	e44e                	sd	s3,8(sp)
    800047e6:	e052                	sd	s4,0(sp)
    800047e8:	1800                	addi	s0,sp,48
    800047ea:	84aa                	mv	s1,a0
    800047ec:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047ee:	0005b023          	sd	zero,0(a1)
    800047f2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047f6:	00000097          	auipc	ra,0x0
    800047fa:	bf8080e7          	jalr	-1032(ra) # 800043ee <filealloc>
    800047fe:	e088                	sd	a0,0(s1)
    80004800:	c551                	beqz	a0,8000488c <pipealloc+0xb2>
    80004802:	00000097          	auipc	ra,0x0
    80004806:	bec080e7          	jalr	-1044(ra) # 800043ee <filealloc>
    8000480a:	00aa3023          	sd	a0,0(s4)
    8000480e:	c92d                	beqz	a0,80004880 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	2d0080e7          	jalr	720(ra) # 80000ae0 <kalloc>
    80004818:	892a                	mv	s2,a0
    8000481a:	c125                	beqz	a0,8000487a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000481c:	4985                	li	s3,1
    8000481e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004822:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004826:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000482a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000482e:	00004597          	auipc	a1,0x4
    80004832:	ea258593          	addi	a1,a1,-350 # 800086d0 <syscalls+0x288>
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	30a080e7          	jalr	778(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    8000483e:	609c                	ld	a5,0(s1)
    80004840:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004844:	609c                	ld	a5,0(s1)
    80004846:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000484a:	609c                	ld	a5,0(s1)
    8000484c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004850:	609c                	ld	a5,0(s1)
    80004852:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004856:	000a3783          	ld	a5,0(s4)
    8000485a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000485e:	000a3783          	ld	a5,0(s4)
    80004862:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004866:	000a3783          	ld	a5,0(s4)
    8000486a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000486e:	000a3783          	ld	a5,0(s4)
    80004872:	0127b823          	sd	s2,16(a5)
  return 0;
    80004876:	4501                	li	a0,0
    80004878:	a025                	j	800048a0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000487a:	6088                	ld	a0,0(s1)
    8000487c:	e501                	bnez	a0,80004884 <pipealloc+0xaa>
    8000487e:	a039                	j	8000488c <pipealloc+0xb2>
    80004880:	6088                	ld	a0,0(s1)
    80004882:	c51d                	beqz	a0,800048b0 <pipealloc+0xd6>
    fileclose(*f0);
    80004884:	00000097          	auipc	ra,0x0
    80004888:	c26080e7          	jalr	-986(ra) # 800044aa <fileclose>
  if(*f1)
    8000488c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004890:	557d                	li	a0,-1
  if(*f1)
    80004892:	c799                	beqz	a5,800048a0 <pipealloc+0xc6>
    fileclose(*f1);
    80004894:	853e                	mv	a0,a5
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	c14080e7          	jalr	-1004(ra) # 800044aa <fileclose>
  return -1;
    8000489e:	557d                	li	a0,-1
}
    800048a0:	70a2                	ld	ra,40(sp)
    800048a2:	7402                	ld	s0,32(sp)
    800048a4:	64e2                	ld	s1,24(sp)
    800048a6:	6942                	ld	s2,16(sp)
    800048a8:	69a2                	ld	s3,8(sp)
    800048aa:	6a02                	ld	s4,0(sp)
    800048ac:	6145                	addi	sp,sp,48
    800048ae:	8082                	ret
  return -1;
    800048b0:	557d                	li	a0,-1
    800048b2:	b7fd                	j	800048a0 <pipealloc+0xc6>

00000000800048b4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048b4:	1101                	addi	sp,sp,-32
    800048b6:	ec06                	sd	ra,24(sp)
    800048b8:	e822                	sd	s0,16(sp)
    800048ba:	e426                	sd	s1,8(sp)
    800048bc:	e04a                	sd	s2,0(sp)
    800048be:	1000                	addi	s0,sp,32
    800048c0:	84aa                	mv	s1,a0
    800048c2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	30c080e7          	jalr	780(ra) # 80000bd0 <acquire>
  if(writable){
    800048cc:	02090d63          	beqz	s2,80004906 <pipeclose+0x52>
    pi->writeopen = 0;
    800048d0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048d4:	21848513          	addi	a0,s1,536
    800048d8:	ffffe097          	auipc	ra,0xffffe
    800048dc:	90e080e7          	jalr	-1778(ra) # 800021e6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048e0:	2204b783          	ld	a5,544(s1)
    800048e4:	eb95                	bnez	a5,80004918 <pipeclose+0x64>
    release(&pi->lock);
    800048e6:	8526                	mv	a0,s1
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	39c080e7          	jalr	924(ra) # 80000c84 <release>
    kfree((char*)pi);
    800048f0:	8526                	mv	a0,s1
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	0f0080e7          	jalr	240(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    800048fa:	60e2                	ld	ra,24(sp)
    800048fc:	6442                	ld	s0,16(sp)
    800048fe:	64a2                	ld	s1,8(sp)
    80004900:	6902                	ld	s2,0(sp)
    80004902:	6105                	addi	sp,sp,32
    80004904:	8082                	ret
    pi->readopen = 0;
    80004906:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000490a:	21c48513          	addi	a0,s1,540
    8000490e:	ffffe097          	auipc	ra,0xffffe
    80004912:	8d8080e7          	jalr	-1832(ra) # 800021e6 <wakeup>
    80004916:	b7e9                	j	800048e0 <pipeclose+0x2c>
    release(&pi->lock);
    80004918:	8526                	mv	a0,s1
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	36a080e7          	jalr	874(ra) # 80000c84 <release>
}
    80004922:	bfe1                	j	800048fa <pipeclose+0x46>

0000000080004924 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004924:	711d                	addi	sp,sp,-96
    80004926:	ec86                	sd	ra,88(sp)
    80004928:	e8a2                	sd	s0,80(sp)
    8000492a:	e4a6                	sd	s1,72(sp)
    8000492c:	e0ca                	sd	s2,64(sp)
    8000492e:	fc4e                	sd	s3,56(sp)
    80004930:	f852                	sd	s4,48(sp)
    80004932:	f456                	sd	s5,40(sp)
    80004934:	f05a                	sd	s6,32(sp)
    80004936:	ec5e                	sd	s7,24(sp)
    80004938:	e862                	sd	s8,16(sp)
    8000493a:	1080                	addi	s0,sp,96
    8000493c:	84aa                	mv	s1,a0
    8000493e:	8aae                	mv	s5,a1
    80004940:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004942:	ffffd097          	auipc	ra,0xffffd
    80004946:	054080e7          	jalr	84(ra) # 80001996 <myproc>
    8000494a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000494c:	8526                	mv	a0,s1
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	282080e7          	jalr	642(ra) # 80000bd0 <acquire>
  while(i < n){
    80004956:	0b405363          	blez	s4,800049fc <pipewrite+0xd8>
  int i = 0;
    8000495a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000495c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000495e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004962:	21c48b93          	addi	s7,s1,540
    80004966:	a089                	j	800049a8 <pipewrite+0x84>
      release(&pi->lock);
    80004968:	8526                	mv	a0,s1
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	31a080e7          	jalr	794(ra) # 80000c84 <release>
      return -1;
    80004972:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004974:	854a                	mv	a0,s2
    80004976:	60e6                	ld	ra,88(sp)
    80004978:	6446                	ld	s0,80(sp)
    8000497a:	64a6                	ld	s1,72(sp)
    8000497c:	6906                	ld	s2,64(sp)
    8000497e:	79e2                	ld	s3,56(sp)
    80004980:	7a42                	ld	s4,48(sp)
    80004982:	7aa2                	ld	s5,40(sp)
    80004984:	7b02                	ld	s6,32(sp)
    80004986:	6be2                	ld	s7,24(sp)
    80004988:	6c42                	ld	s8,16(sp)
    8000498a:	6125                	addi	sp,sp,96
    8000498c:	8082                	ret
      wakeup(&pi->nread);
    8000498e:	8562                	mv	a0,s8
    80004990:	ffffe097          	auipc	ra,0xffffe
    80004994:	856080e7          	jalr	-1962(ra) # 800021e6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004998:	85a6                	mv	a1,s1
    8000499a:	855e                	mv	a0,s7
    8000499c:	ffffd097          	auipc	ra,0xffffd
    800049a0:	6be080e7          	jalr	1726(ra) # 8000205a <sleep>
  while(i < n){
    800049a4:	05495d63          	bge	s2,s4,800049fe <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    800049a8:	2204a783          	lw	a5,544(s1)
    800049ac:	dfd5                	beqz	a5,80004968 <pipewrite+0x44>
    800049ae:	0289a783          	lw	a5,40(s3)
    800049b2:	fbdd                	bnez	a5,80004968 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800049b4:	2184a783          	lw	a5,536(s1)
    800049b8:	21c4a703          	lw	a4,540(s1)
    800049bc:	2007879b          	addiw	a5,a5,512
    800049c0:	fcf707e3          	beq	a4,a5,8000498e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049c4:	4685                	li	a3,1
    800049c6:	01590633          	add	a2,s2,s5
    800049ca:	faf40593          	addi	a1,s0,-81
    800049ce:	0509b503          	ld	a0,80(s3)
    800049d2:	ffffd097          	auipc	ra,0xffffd
    800049d6:	d14080e7          	jalr	-748(ra) # 800016e6 <copyin>
    800049da:	03650263          	beq	a0,s6,800049fe <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049de:	21c4a783          	lw	a5,540(s1)
    800049e2:	0017871b          	addiw	a4,a5,1
    800049e6:	20e4ae23          	sw	a4,540(s1)
    800049ea:	1ff7f793          	andi	a5,a5,511
    800049ee:	97a6                	add	a5,a5,s1
    800049f0:	faf44703          	lbu	a4,-81(s0)
    800049f4:	00e78c23          	sb	a4,24(a5)
      i++;
    800049f8:	2905                	addiw	s2,s2,1
    800049fa:	b76d                	j	800049a4 <pipewrite+0x80>
  int i = 0;
    800049fc:	4901                	li	s2,0
  wakeup(&pi->nread);
    800049fe:	21848513          	addi	a0,s1,536
    80004a02:	ffffd097          	auipc	ra,0xffffd
    80004a06:	7e4080e7          	jalr	2020(ra) # 800021e6 <wakeup>
  release(&pi->lock);
    80004a0a:	8526                	mv	a0,s1
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	278080e7          	jalr	632(ra) # 80000c84 <release>
  return i;
    80004a14:	b785                	j	80004974 <pipewrite+0x50>

0000000080004a16 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a16:	715d                	addi	sp,sp,-80
    80004a18:	e486                	sd	ra,72(sp)
    80004a1a:	e0a2                	sd	s0,64(sp)
    80004a1c:	fc26                	sd	s1,56(sp)
    80004a1e:	f84a                	sd	s2,48(sp)
    80004a20:	f44e                	sd	s3,40(sp)
    80004a22:	f052                	sd	s4,32(sp)
    80004a24:	ec56                	sd	s5,24(sp)
    80004a26:	e85a                	sd	s6,16(sp)
    80004a28:	0880                	addi	s0,sp,80
    80004a2a:	84aa                	mv	s1,a0
    80004a2c:	892e                	mv	s2,a1
    80004a2e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a30:	ffffd097          	auipc	ra,0xffffd
    80004a34:	f66080e7          	jalr	-154(ra) # 80001996 <myproc>
    80004a38:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a3a:	8526                	mv	a0,s1
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	194080e7          	jalr	404(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a44:	2184a703          	lw	a4,536(s1)
    80004a48:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a4c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a50:	02f71463          	bne	a4,a5,80004a78 <piperead+0x62>
    80004a54:	2244a783          	lw	a5,548(s1)
    80004a58:	c385                	beqz	a5,80004a78 <piperead+0x62>
    if(pr->killed){
    80004a5a:	028a2783          	lw	a5,40(s4)
    80004a5e:	ebc9                	bnez	a5,80004af0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a60:	85a6                	mv	a1,s1
    80004a62:	854e                	mv	a0,s3
    80004a64:	ffffd097          	auipc	ra,0xffffd
    80004a68:	5f6080e7          	jalr	1526(ra) # 8000205a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a6c:	2184a703          	lw	a4,536(s1)
    80004a70:	21c4a783          	lw	a5,540(s1)
    80004a74:	fef700e3          	beq	a4,a5,80004a54 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a78:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a7a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a7c:	05505463          	blez	s5,80004ac4 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004a80:	2184a783          	lw	a5,536(s1)
    80004a84:	21c4a703          	lw	a4,540(s1)
    80004a88:	02f70e63          	beq	a4,a5,80004ac4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a8c:	0017871b          	addiw	a4,a5,1
    80004a90:	20e4ac23          	sw	a4,536(s1)
    80004a94:	1ff7f793          	andi	a5,a5,511
    80004a98:	97a6                	add	a5,a5,s1
    80004a9a:	0187c783          	lbu	a5,24(a5)
    80004a9e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004aa2:	4685                	li	a3,1
    80004aa4:	fbf40613          	addi	a2,s0,-65
    80004aa8:	85ca                	mv	a1,s2
    80004aaa:	050a3503          	ld	a0,80(s4)
    80004aae:	ffffd097          	auipc	ra,0xffffd
    80004ab2:	bac080e7          	jalr	-1108(ra) # 8000165a <copyout>
    80004ab6:	01650763          	beq	a0,s6,80004ac4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aba:	2985                	addiw	s3,s3,1
    80004abc:	0905                	addi	s2,s2,1
    80004abe:	fd3a91e3          	bne	s5,s3,80004a80 <piperead+0x6a>
    80004ac2:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ac4:	21c48513          	addi	a0,s1,540
    80004ac8:	ffffd097          	auipc	ra,0xffffd
    80004acc:	71e080e7          	jalr	1822(ra) # 800021e6 <wakeup>
  release(&pi->lock);
    80004ad0:	8526                	mv	a0,s1
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	1b2080e7          	jalr	434(ra) # 80000c84 <release>
  return i;
}
    80004ada:	854e                	mv	a0,s3
    80004adc:	60a6                	ld	ra,72(sp)
    80004ade:	6406                	ld	s0,64(sp)
    80004ae0:	74e2                	ld	s1,56(sp)
    80004ae2:	7942                	ld	s2,48(sp)
    80004ae4:	79a2                	ld	s3,40(sp)
    80004ae6:	7a02                	ld	s4,32(sp)
    80004ae8:	6ae2                	ld	s5,24(sp)
    80004aea:	6b42                	ld	s6,16(sp)
    80004aec:	6161                	addi	sp,sp,80
    80004aee:	8082                	ret
      release(&pi->lock);
    80004af0:	8526                	mv	a0,s1
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	192080e7          	jalr	402(ra) # 80000c84 <release>
      return -1;
    80004afa:	59fd                	li	s3,-1
    80004afc:	bff9                	j	80004ada <piperead+0xc4>

0000000080004afe <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004afe:	de010113          	addi	sp,sp,-544
    80004b02:	20113c23          	sd	ra,536(sp)
    80004b06:	20813823          	sd	s0,528(sp)
    80004b0a:	20913423          	sd	s1,520(sp)
    80004b0e:	21213023          	sd	s2,512(sp)
    80004b12:	ffce                	sd	s3,504(sp)
    80004b14:	fbd2                	sd	s4,496(sp)
    80004b16:	f7d6                	sd	s5,488(sp)
    80004b18:	f3da                	sd	s6,480(sp)
    80004b1a:	efde                	sd	s7,472(sp)
    80004b1c:	ebe2                	sd	s8,464(sp)
    80004b1e:	e7e6                	sd	s9,456(sp)
    80004b20:	e3ea                	sd	s10,448(sp)
    80004b22:	ff6e                	sd	s11,440(sp)
    80004b24:	1400                	addi	s0,sp,544
    80004b26:	892a                	mv	s2,a0
    80004b28:	dea43423          	sd	a0,-536(s0)
    80004b2c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b30:	ffffd097          	auipc	ra,0xffffd
    80004b34:	e66080e7          	jalr	-410(ra) # 80001996 <myproc>
    80004b38:	84aa                	mv	s1,a0

  begin_op();
    80004b3a:	fffff097          	auipc	ra,0xfffff
    80004b3e:	4a8080e7          	jalr	1192(ra) # 80003fe2 <begin_op>

  if((ip = namei(path)) == 0){
    80004b42:	854a                	mv	a0,s2
    80004b44:	fffff097          	auipc	ra,0xfffff
    80004b48:	27e080e7          	jalr	638(ra) # 80003dc2 <namei>
    80004b4c:	c93d                	beqz	a0,80004bc2 <exec+0xc4>
    80004b4e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b50:	fffff097          	auipc	ra,0xfffff
    80004b54:	ab6080e7          	jalr	-1354(ra) # 80003606 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b58:	04000713          	li	a4,64
    80004b5c:	4681                	li	a3,0
    80004b5e:	e5040613          	addi	a2,s0,-432
    80004b62:	4581                	li	a1,0
    80004b64:	8556                	mv	a0,s5
    80004b66:	fffff097          	auipc	ra,0xfffff
    80004b6a:	d54080e7          	jalr	-684(ra) # 800038ba <readi>
    80004b6e:	04000793          	li	a5,64
    80004b72:	00f51a63          	bne	a0,a5,80004b86 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b76:	e5042703          	lw	a4,-432(s0)
    80004b7a:	464c47b7          	lui	a5,0x464c4
    80004b7e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b82:	04f70663          	beq	a4,a5,80004bce <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b86:	8556                	mv	a0,s5
    80004b88:	fffff097          	auipc	ra,0xfffff
    80004b8c:	ce0080e7          	jalr	-800(ra) # 80003868 <iunlockput>
    end_op();
    80004b90:	fffff097          	auipc	ra,0xfffff
    80004b94:	4d0080e7          	jalr	1232(ra) # 80004060 <end_op>
  }
  return -1;
    80004b98:	557d                	li	a0,-1
}
    80004b9a:	21813083          	ld	ra,536(sp)
    80004b9e:	21013403          	ld	s0,528(sp)
    80004ba2:	20813483          	ld	s1,520(sp)
    80004ba6:	20013903          	ld	s2,512(sp)
    80004baa:	79fe                	ld	s3,504(sp)
    80004bac:	7a5e                	ld	s4,496(sp)
    80004bae:	7abe                	ld	s5,488(sp)
    80004bb0:	7b1e                	ld	s6,480(sp)
    80004bb2:	6bfe                	ld	s7,472(sp)
    80004bb4:	6c5e                	ld	s8,464(sp)
    80004bb6:	6cbe                	ld	s9,456(sp)
    80004bb8:	6d1e                	ld	s10,448(sp)
    80004bba:	7dfa                	ld	s11,440(sp)
    80004bbc:	22010113          	addi	sp,sp,544
    80004bc0:	8082                	ret
    end_op();
    80004bc2:	fffff097          	auipc	ra,0xfffff
    80004bc6:	49e080e7          	jalr	1182(ra) # 80004060 <end_op>
    return -1;
    80004bca:	557d                	li	a0,-1
    80004bcc:	b7f9                	j	80004b9a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bce:	8526                	mv	a0,s1
    80004bd0:	ffffd097          	auipc	ra,0xffffd
    80004bd4:	e8a080e7          	jalr	-374(ra) # 80001a5a <proc_pagetable>
    80004bd8:	8b2a                	mv	s6,a0
    80004bda:	d555                	beqz	a0,80004b86 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bdc:	e7042783          	lw	a5,-400(s0)
    80004be0:	e8845703          	lhu	a4,-376(s0)
    80004be4:	c735                	beqz	a4,80004c50 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004be6:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004be8:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80004bec:	6a05                	lui	s4,0x1
    80004bee:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004bf2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004bf6:	6d85                	lui	s11,0x1
    80004bf8:	7d7d                	lui	s10,0xfffff
    80004bfa:	ac1d                	j	80004e30 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004bfc:	00004517          	auipc	a0,0x4
    80004c00:	adc50513          	addi	a0,a0,-1316 # 800086d8 <syscalls+0x290>
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	936080e7          	jalr	-1738(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c0c:	874a                	mv	a4,s2
    80004c0e:	009c86bb          	addw	a3,s9,s1
    80004c12:	4581                	li	a1,0
    80004c14:	8556                	mv	a0,s5
    80004c16:	fffff097          	auipc	ra,0xfffff
    80004c1a:	ca4080e7          	jalr	-860(ra) # 800038ba <readi>
    80004c1e:	2501                	sext.w	a0,a0
    80004c20:	1aa91863          	bne	s2,a0,80004dd0 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004c24:	009d84bb          	addw	s1,s11,s1
    80004c28:	013d09bb          	addw	s3,s10,s3
    80004c2c:	1f74f263          	bgeu	s1,s7,80004e10 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004c30:	02049593          	slli	a1,s1,0x20
    80004c34:	9181                	srli	a1,a1,0x20
    80004c36:	95e2                	add	a1,a1,s8
    80004c38:	855a                	mv	a0,s6
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	418080e7          	jalr	1048(ra) # 80001052 <walkaddr>
    80004c42:	862a                	mv	a2,a0
    if(pa == 0)
    80004c44:	dd45                	beqz	a0,80004bfc <exec+0xfe>
      n = PGSIZE;
    80004c46:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004c48:	fd49f2e3          	bgeu	s3,s4,80004c0c <exec+0x10e>
      n = sz - i;
    80004c4c:	894e                	mv	s2,s3
    80004c4e:	bf7d                	j	80004c0c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c50:	4481                	li	s1,0
  iunlockput(ip);
    80004c52:	8556                	mv	a0,s5
    80004c54:	fffff097          	auipc	ra,0xfffff
    80004c58:	c14080e7          	jalr	-1004(ra) # 80003868 <iunlockput>
  end_op();
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	404080e7          	jalr	1028(ra) # 80004060 <end_op>
  p = myproc();
    80004c64:	ffffd097          	auipc	ra,0xffffd
    80004c68:	d32080e7          	jalr	-718(ra) # 80001996 <myproc>
    80004c6c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004c6e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c72:	6785                	lui	a5,0x1
    80004c74:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004c76:	97a6                	add	a5,a5,s1
    80004c78:	777d                	lui	a4,0xfffff
    80004c7a:	8ff9                	and	a5,a5,a4
    80004c7c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c80:	6609                	lui	a2,0x2
    80004c82:	963e                	add	a2,a2,a5
    80004c84:	85be                	mv	a1,a5
    80004c86:	855a                	mv	a0,s6
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	77e080e7          	jalr	1918(ra) # 80001406 <uvmalloc>
    80004c90:	8c2a                	mv	s8,a0
  ip = 0;
    80004c92:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c94:	12050e63          	beqz	a0,80004dd0 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004c98:	75f9                	lui	a1,0xffffe
    80004c9a:	95aa                	add	a1,a1,a0
    80004c9c:	855a                	mv	a0,s6
    80004c9e:	ffffd097          	auipc	ra,0xffffd
    80004ca2:	98a080e7          	jalr	-1654(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ca6:	7afd                	lui	s5,0xfffff
    80004ca8:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004caa:	df043783          	ld	a5,-528(s0)
    80004cae:	6388                	ld	a0,0(a5)
    80004cb0:	c925                	beqz	a0,80004d20 <exec+0x222>
    80004cb2:	e9040993          	addi	s3,s0,-368
    80004cb6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004cba:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004cbc:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	18a080e7          	jalr	394(ra) # 80000e48 <strlen>
    80004cc6:	0015079b          	addiw	a5,a0,1
    80004cca:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004cce:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004cd2:	13596363          	bltu	s2,s5,80004df8 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004cd6:	df043d83          	ld	s11,-528(s0)
    80004cda:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004cde:	8552                	mv	a0,s4
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	168080e7          	jalr	360(ra) # 80000e48 <strlen>
    80004ce8:	0015069b          	addiw	a3,a0,1
    80004cec:	8652                	mv	a2,s4
    80004cee:	85ca                	mv	a1,s2
    80004cf0:	855a                	mv	a0,s6
    80004cf2:	ffffd097          	auipc	ra,0xffffd
    80004cf6:	968080e7          	jalr	-1688(ra) # 8000165a <copyout>
    80004cfa:	10054363          	bltz	a0,80004e00 <exec+0x302>
    ustack[argc] = sp;
    80004cfe:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d02:	0485                	addi	s1,s1,1
    80004d04:	008d8793          	addi	a5,s11,8
    80004d08:	def43823          	sd	a5,-528(s0)
    80004d0c:	008db503          	ld	a0,8(s11)
    80004d10:	c911                	beqz	a0,80004d24 <exec+0x226>
    if(argc >= MAXARG)
    80004d12:	09a1                	addi	s3,s3,8
    80004d14:	fb3c95e3          	bne	s9,s3,80004cbe <exec+0x1c0>
  sz = sz1;
    80004d18:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d1c:	4a81                	li	s5,0
    80004d1e:	a84d                	j	80004dd0 <exec+0x2d2>
  sp = sz;
    80004d20:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d22:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d24:	00349793          	slli	a5,s1,0x3
    80004d28:	f9078793          	addi	a5,a5,-112
    80004d2c:	97a2                	add	a5,a5,s0
    80004d2e:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004d32:	00148693          	addi	a3,s1,1
    80004d36:	068e                	slli	a3,a3,0x3
    80004d38:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d3c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d40:	01597663          	bgeu	s2,s5,80004d4c <exec+0x24e>
  sz = sz1;
    80004d44:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d48:	4a81                	li	s5,0
    80004d4a:	a059                	j	80004dd0 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d4c:	e9040613          	addi	a2,s0,-368
    80004d50:	85ca                	mv	a1,s2
    80004d52:	855a                	mv	a0,s6
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	906080e7          	jalr	-1786(ra) # 8000165a <copyout>
    80004d5c:	0a054663          	bltz	a0,80004e08 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004d60:	058bb783          	ld	a5,88(s7)
    80004d64:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004d68:	de843783          	ld	a5,-536(s0)
    80004d6c:	0007c703          	lbu	a4,0(a5)
    80004d70:	cf11                	beqz	a4,80004d8c <exec+0x28e>
    80004d72:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d74:	02f00693          	li	a3,47
    80004d78:	a039                	j	80004d86 <exec+0x288>
      last = s+1;
    80004d7a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004d7e:	0785                	addi	a5,a5,1
    80004d80:	fff7c703          	lbu	a4,-1(a5)
    80004d84:	c701                	beqz	a4,80004d8c <exec+0x28e>
    if(*s == '/')
    80004d86:	fed71ce3          	bne	a4,a3,80004d7e <exec+0x280>
    80004d8a:	bfc5                	j	80004d7a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d8c:	4641                	li	a2,16
    80004d8e:	de843583          	ld	a1,-536(s0)
    80004d92:	158b8513          	addi	a0,s7,344
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	080080e7          	jalr	128(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004d9e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004da2:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004da6:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004daa:	058bb783          	ld	a5,88(s7)
    80004dae:	e6843703          	ld	a4,-408(s0)
    80004db2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004db4:	058bb783          	ld	a5,88(s7)
    80004db8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004dbc:	85ea                	mv	a1,s10
    80004dbe:	ffffd097          	auipc	ra,0xffffd
    80004dc2:	d38080e7          	jalr	-712(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004dc6:	0004851b          	sext.w	a0,s1
    80004dca:	bbc1                	j	80004b9a <exec+0x9c>
    80004dcc:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004dd0:	df843583          	ld	a1,-520(s0)
    80004dd4:	855a                	mv	a0,s6
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	d20080e7          	jalr	-736(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    80004dde:	da0a94e3          	bnez	s5,80004b86 <exec+0x88>
  return -1;
    80004de2:	557d                	li	a0,-1
    80004de4:	bb5d                	j	80004b9a <exec+0x9c>
    80004de6:	de943c23          	sd	s1,-520(s0)
    80004dea:	b7dd                	j	80004dd0 <exec+0x2d2>
    80004dec:	de943c23          	sd	s1,-520(s0)
    80004df0:	b7c5                	j	80004dd0 <exec+0x2d2>
    80004df2:	de943c23          	sd	s1,-520(s0)
    80004df6:	bfe9                	j	80004dd0 <exec+0x2d2>
  sz = sz1;
    80004df8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dfc:	4a81                	li	s5,0
    80004dfe:	bfc9                	j	80004dd0 <exec+0x2d2>
  sz = sz1;
    80004e00:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e04:	4a81                	li	s5,0
    80004e06:	b7e9                	j	80004dd0 <exec+0x2d2>
  sz = sz1;
    80004e08:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e0c:	4a81                	li	s5,0
    80004e0e:	b7c9                	j	80004dd0 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e10:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e14:	e0843783          	ld	a5,-504(s0)
    80004e18:	0017869b          	addiw	a3,a5,1
    80004e1c:	e0d43423          	sd	a3,-504(s0)
    80004e20:	e0043783          	ld	a5,-512(s0)
    80004e24:	0387879b          	addiw	a5,a5,56
    80004e28:	e8845703          	lhu	a4,-376(s0)
    80004e2c:	e2e6d3e3          	bge	a3,a4,80004c52 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e30:	2781                	sext.w	a5,a5
    80004e32:	e0f43023          	sd	a5,-512(s0)
    80004e36:	03800713          	li	a4,56
    80004e3a:	86be                	mv	a3,a5
    80004e3c:	e1840613          	addi	a2,s0,-488
    80004e40:	4581                	li	a1,0
    80004e42:	8556                	mv	a0,s5
    80004e44:	fffff097          	auipc	ra,0xfffff
    80004e48:	a76080e7          	jalr	-1418(ra) # 800038ba <readi>
    80004e4c:	03800793          	li	a5,56
    80004e50:	f6f51ee3          	bne	a0,a5,80004dcc <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004e54:	e1842783          	lw	a5,-488(s0)
    80004e58:	4705                	li	a4,1
    80004e5a:	fae79de3          	bne	a5,a4,80004e14 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004e5e:	e4043603          	ld	a2,-448(s0)
    80004e62:	e3843783          	ld	a5,-456(s0)
    80004e66:	f8f660e3          	bltu	a2,a5,80004de6 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e6a:	e2843783          	ld	a5,-472(s0)
    80004e6e:	963e                	add	a2,a2,a5
    80004e70:	f6f66ee3          	bltu	a2,a5,80004dec <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e74:	85a6                	mv	a1,s1
    80004e76:	855a                	mv	a0,s6
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	58e080e7          	jalr	1422(ra) # 80001406 <uvmalloc>
    80004e80:	dea43c23          	sd	a0,-520(s0)
    80004e84:	d53d                	beqz	a0,80004df2 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80004e86:	e2843c03          	ld	s8,-472(s0)
    80004e8a:	de043783          	ld	a5,-544(s0)
    80004e8e:	00fc77b3          	and	a5,s8,a5
    80004e92:	ff9d                	bnez	a5,80004dd0 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e94:	e2042c83          	lw	s9,-480(s0)
    80004e98:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e9c:	f60b8ae3          	beqz	s7,80004e10 <exec+0x312>
    80004ea0:	89de                	mv	s3,s7
    80004ea2:	4481                	li	s1,0
    80004ea4:	b371                	j	80004c30 <exec+0x132>

0000000080004ea6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ea6:	7179                	addi	sp,sp,-48
    80004ea8:	f406                	sd	ra,40(sp)
    80004eaa:	f022                	sd	s0,32(sp)
    80004eac:	ec26                	sd	s1,24(sp)
    80004eae:	e84a                	sd	s2,16(sp)
    80004eb0:	1800                	addi	s0,sp,48
    80004eb2:	892e                	mv	s2,a1
    80004eb4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004eb6:	fdc40593          	addi	a1,s0,-36
    80004eba:	ffffe097          	auipc	ra,0xffffe
    80004ebe:	b92080e7          	jalr	-1134(ra) # 80002a4c <argint>
    80004ec2:	04054063          	bltz	a0,80004f02 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ec6:	fdc42703          	lw	a4,-36(s0)
    80004eca:	47bd                	li	a5,15
    80004ecc:	02e7ed63          	bltu	a5,a4,80004f06 <argfd+0x60>
    80004ed0:	ffffd097          	auipc	ra,0xffffd
    80004ed4:	ac6080e7          	jalr	-1338(ra) # 80001996 <myproc>
    80004ed8:	fdc42703          	lw	a4,-36(s0)
    80004edc:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80004ee0:	078e                	slli	a5,a5,0x3
    80004ee2:	953e                	add	a0,a0,a5
    80004ee4:	611c                	ld	a5,0(a0)
    80004ee6:	c395                	beqz	a5,80004f0a <argfd+0x64>
    return -1;
  if(pfd)
    80004ee8:	00090463          	beqz	s2,80004ef0 <argfd+0x4a>
    *pfd = fd;
    80004eec:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ef0:	4501                	li	a0,0
  if(pf)
    80004ef2:	c091                	beqz	s1,80004ef6 <argfd+0x50>
    *pf = f;
    80004ef4:	e09c                	sd	a5,0(s1)
}
    80004ef6:	70a2                	ld	ra,40(sp)
    80004ef8:	7402                	ld	s0,32(sp)
    80004efa:	64e2                	ld	s1,24(sp)
    80004efc:	6942                	ld	s2,16(sp)
    80004efe:	6145                	addi	sp,sp,48
    80004f00:	8082                	ret
    return -1;
    80004f02:	557d                	li	a0,-1
    80004f04:	bfcd                	j	80004ef6 <argfd+0x50>
    return -1;
    80004f06:	557d                	li	a0,-1
    80004f08:	b7fd                	j	80004ef6 <argfd+0x50>
    80004f0a:	557d                	li	a0,-1
    80004f0c:	b7ed                	j	80004ef6 <argfd+0x50>

0000000080004f0e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f0e:	1101                	addi	sp,sp,-32
    80004f10:	ec06                	sd	ra,24(sp)
    80004f12:	e822                	sd	s0,16(sp)
    80004f14:	e426                	sd	s1,8(sp)
    80004f16:	1000                	addi	s0,sp,32
    80004f18:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f1a:	ffffd097          	auipc	ra,0xffffd
    80004f1e:	a7c080e7          	jalr	-1412(ra) # 80001996 <myproc>
    80004f22:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f24:	0d050793          	addi	a5,a0,208
    80004f28:	4501                	li	a0,0
    80004f2a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f2c:	6398                	ld	a4,0(a5)
    80004f2e:	cb19                	beqz	a4,80004f44 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f30:	2505                	addiw	a0,a0,1
    80004f32:	07a1                	addi	a5,a5,8
    80004f34:	fed51ce3          	bne	a0,a3,80004f2c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f38:	557d                	li	a0,-1
}
    80004f3a:	60e2                	ld	ra,24(sp)
    80004f3c:	6442                	ld	s0,16(sp)
    80004f3e:	64a2                	ld	s1,8(sp)
    80004f40:	6105                	addi	sp,sp,32
    80004f42:	8082                	ret
      p->ofile[fd] = f;
    80004f44:	01a50793          	addi	a5,a0,26
    80004f48:	078e                	slli	a5,a5,0x3
    80004f4a:	963e                	add	a2,a2,a5
    80004f4c:	e204                	sd	s1,0(a2)
      return fd;
    80004f4e:	b7f5                	j	80004f3a <fdalloc+0x2c>

0000000080004f50 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f50:	715d                	addi	sp,sp,-80
    80004f52:	e486                	sd	ra,72(sp)
    80004f54:	e0a2                	sd	s0,64(sp)
    80004f56:	fc26                	sd	s1,56(sp)
    80004f58:	f84a                	sd	s2,48(sp)
    80004f5a:	f44e                	sd	s3,40(sp)
    80004f5c:	f052                	sd	s4,32(sp)
    80004f5e:	ec56                	sd	s5,24(sp)
    80004f60:	0880                	addi	s0,sp,80
    80004f62:	89ae                	mv	s3,a1
    80004f64:	8ab2                	mv	s5,a2
    80004f66:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f68:	fb040593          	addi	a1,s0,-80
    80004f6c:	fffff097          	auipc	ra,0xfffff
    80004f70:	e74080e7          	jalr	-396(ra) # 80003de0 <nameiparent>
    80004f74:	892a                	mv	s2,a0
    80004f76:	12050e63          	beqz	a0,800050b2 <create+0x162>
    return 0;

  ilock(dp);
    80004f7a:	ffffe097          	auipc	ra,0xffffe
    80004f7e:	68c080e7          	jalr	1676(ra) # 80003606 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f82:	4601                	li	a2,0
    80004f84:	fb040593          	addi	a1,s0,-80
    80004f88:	854a                	mv	a0,s2
    80004f8a:	fffff097          	auipc	ra,0xfffff
    80004f8e:	b60080e7          	jalr	-1184(ra) # 80003aea <dirlookup>
    80004f92:	84aa                	mv	s1,a0
    80004f94:	c921                	beqz	a0,80004fe4 <create+0x94>
    iunlockput(dp);
    80004f96:	854a                	mv	a0,s2
    80004f98:	fffff097          	auipc	ra,0xfffff
    80004f9c:	8d0080e7          	jalr	-1840(ra) # 80003868 <iunlockput>
    ilock(ip);
    80004fa0:	8526                	mv	a0,s1
    80004fa2:	ffffe097          	auipc	ra,0xffffe
    80004fa6:	664080e7          	jalr	1636(ra) # 80003606 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004faa:	2981                	sext.w	s3,s3
    80004fac:	4789                	li	a5,2
    80004fae:	02f99463          	bne	s3,a5,80004fd6 <create+0x86>
    80004fb2:	0444d783          	lhu	a5,68(s1)
    80004fb6:	37f9                	addiw	a5,a5,-2
    80004fb8:	17c2                	slli	a5,a5,0x30
    80004fba:	93c1                	srli	a5,a5,0x30
    80004fbc:	4705                	li	a4,1
    80004fbe:	00f76c63          	bltu	a4,a5,80004fd6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004fc2:	8526                	mv	a0,s1
    80004fc4:	60a6                	ld	ra,72(sp)
    80004fc6:	6406                	ld	s0,64(sp)
    80004fc8:	74e2                	ld	s1,56(sp)
    80004fca:	7942                	ld	s2,48(sp)
    80004fcc:	79a2                	ld	s3,40(sp)
    80004fce:	7a02                	ld	s4,32(sp)
    80004fd0:	6ae2                	ld	s5,24(sp)
    80004fd2:	6161                	addi	sp,sp,80
    80004fd4:	8082                	ret
    iunlockput(ip);
    80004fd6:	8526                	mv	a0,s1
    80004fd8:	fffff097          	auipc	ra,0xfffff
    80004fdc:	890080e7          	jalr	-1904(ra) # 80003868 <iunlockput>
    return 0;
    80004fe0:	4481                	li	s1,0
    80004fe2:	b7c5                	j	80004fc2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004fe4:	85ce                	mv	a1,s3
    80004fe6:	00092503          	lw	a0,0(s2)
    80004fea:	ffffe097          	auipc	ra,0xffffe
    80004fee:	482080e7          	jalr	1154(ra) # 8000346c <ialloc>
    80004ff2:	84aa                	mv	s1,a0
    80004ff4:	c521                	beqz	a0,8000503c <create+0xec>
  ilock(ip);
    80004ff6:	ffffe097          	auipc	ra,0xffffe
    80004ffa:	610080e7          	jalr	1552(ra) # 80003606 <ilock>
  ip->major = major;
    80004ffe:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005002:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005006:	4a05                	li	s4,1
    80005008:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000500c:	8526                	mv	a0,s1
    8000500e:	ffffe097          	auipc	ra,0xffffe
    80005012:	52c080e7          	jalr	1324(ra) # 8000353a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005016:	2981                	sext.w	s3,s3
    80005018:	03498a63          	beq	s3,s4,8000504c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000501c:	40d0                	lw	a2,4(s1)
    8000501e:	fb040593          	addi	a1,s0,-80
    80005022:	854a                	mv	a0,s2
    80005024:	fffff097          	auipc	ra,0xfffff
    80005028:	cdc080e7          	jalr	-804(ra) # 80003d00 <dirlink>
    8000502c:	06054b63          	bltz	a0,800050a2 <create+0x152>
  iunlockput(dp);
    80005030:	854a                	mv	a0,s2
    80005032:	fffff097          	auipc	ra,0xfffff
    80005036:	836080e7          	jalr	-1994(ra) # 80003868 <iunlockput>
  return ip;
    8000503a:	b761                	j	80004fc2 <create+0x72>
    panic("create: ialloc");
    8000503c:	00003517          	auipc	a0,0x3
    80005040:	6bc50513          	addi	a0,a0,1724 # 800086f8 <syscalls+0x2b0>
    80005044:	ffffb097          	auipc	ra,0xffffb
    80005048:	4f6080e7          	jalr	1270(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    8000504c:	04a95783          	lhu	a5,74(s2)
    80005050:	2785                	addiw	a5,a5,1
    80005052:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005056:	854a                	mv	a0,s2
    80005058:	ffffe097          	auipc	ra,0xffffe
    8000505c:	4e2080e7          	jalr	1250(ra) # 8000353a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005060:	40d0                	lw	a2,4(s1)
    80005062:	00003597          	auipc	a1,0x3
    80005066:	6a658593          	addi	a1,a1,1702 # 80008708 <syscalls+0x2c0>
    8000506a:	8526                	mv	a0,s1
    8000506c:	fffff097          	auipc	ra,0xfffff
    80005070:	c94080e7          	jalr	-876(ra) # 80003d00 <dirlink>
    80005074:	00054f63          	bltz	a0,80005092 <create+0x142>
    80005078:	00492603          	lw	a2,4(s2)
    8000507c:	00003597          	auipc	a1,0x3
    80005080:	69458593          	addi	a1,a1,1684 # 80008710 <syscalls+0x2c8>
    80005084:	8526                	mv	a0,s1
    80005086:	fffff097          	auipc	ra,0xfffff
    8000508a:	c7a080e7          	jalr	-902(ra) # 80003d00 <dirlink>
    8000508e:	f80557e3          	bgez	a0,8000501c <create+0xcc>
      panic("create dots");
    80005092:	00003517          	auipc	a0,0x3
    80005096:	68650513          	addi	a0,a0,1670 # 80008718 <syscalls+0x2d0>
    8000509a:	ffffb097          	auipc	ra,0xffffb
    8000509e:	4a0080e7          	jalr	1184(ra) # 8000053a <panic>
    panic("create: dirlink");
    800050a2:	00003517          	auipc	a0,0x3
    800050a6:	68650513          	addi	a0,a0,1670 # 80008728 <syscalls+0x2e0>
    800050aa:	ffffb097          	auipc	ra,0xffffb
    800050ae:	490080e7          	jalr	1168(ra) # 8000053a <panic>
    return 0;
    800050b2:	84aa                	mv	s1,a0
    800050b4:	b739                	j	80004fc2 <create+0x72>

00000000800050b6 <sys_dup>:
{
    800050b6:	7179                	addi	sp,sp,-48
    800050b8:	f406                	sd	ra,40(sp)
    800050ba:	f022                	sd	s0,32(sp)
    800050bc:	ec26                	sd	s1,24(sp)
    800050be:	e84a                	sd	s2,16(sp)
    800050c0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050c2:	fd840613          	addi	a2,s0,-40
    800050c6:	4581                	li	a1,0
    800050c8:	4501                	li	a0,0
    800050ca:	00000097          	auipc	ra,0x0
    800050ce:	ddc080e7          	jalr	-548(ra) # 80004ea6 <argfd>
    return -1;
    800050d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050d4:	02054363          	bltz	a0,800050fa <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800050d8:	fd843903          	ld	s2,-40(s0)
    800050dc:	854a                	mv	a0,s2
    800050de:	00000097          	auipc	ra,0x0
    800050e2:	e30080e7          	jalr	-464(ra) # 80004f0e <fdalloc>
    800050e6:	84aa                	mv	s1,a0
    return -1;
    800050e8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050ea:	00054863          	bltz	a0,800050fa <sys_dup+0x44>
  filedup(f);
    800050ee:	854a                	mv	a0,s2
    800050f0:	fffff097          	auipc	ra,0xfffff
    800050f4:	368080e7          	jalr	872(ra) # 80004458 <filedup>
  return fd;
    800050f8:	87a6                	mv	a5,s1
}
    800050fa:	853e                	mv	a0,a5
    800050fc:	70a2                	ld	ra,40(sp)
    800050fe:	7402                	ld	s0,32(sp)
    80005100:	64e2                	ld	s1,24(sp)
    80005102:	6942                	ld	s2,16(sp)
    80005104:	6145                	addi	sp,sp,48
    80005106:	8082                	ret

0000000080005108 <sys_read>:
{
    80005108:	7179                	addi	sp,sp,-48
    8000510a:	f406                	sd	ra,40(sp)
    8000510c:	f022                	sd	s0,32(sp)
    8000510e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005110:	fe840613          	addi	a2,s0,-24
    80005114:	4581                	li	a1,0
    80005116:	4501                	li	a0,0
    80005118:	00000097          	auipc	ra,0x0
    8000511c:	d8e080e7          	jalr	-626(ra) # 80004ea6 <argfd>
    return -1;
    80005120:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005122:	04054163          	bltz	a0,80005164 <sys_read+0x5c>
    80005126:	fe440593          	addi	a1,s0,-28
    8000512a:	4509                	li	a0,2
    8000512c:	ffffe097          	auipc	ra,0xffffe
    80005130:	920080e7          	jalr	-1760(ra) # 80002a4c <argint>
    return -1;
    80005134:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005136:	02054763          	bltz	a0,80005164 <sys_read+0x5c>
    8000513a:	fd840593          	addi	a1,s0,-40
    8000513e:	4505                	li	a0,1
    80005140:	ffffe097          	auipc	ra,0xffffe
    80005144:	92e080e7          	jalr	-1746(ra) # 80002a6e <argaddr>
    return -1;
    80005148:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000514a:	00054d63          	bltz	a0,80005164 <sys_read+0x5c>
  return fileread(f, p, n);
    8000514e:	fe442603          	lw	a2,-28(s0)
    80005152:	fd843583          	ld	a1,-40(s0)
    80005156:	fe843503          	ld	a0,-24(s0)
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	48a080e7          	jalr	1162(ra) # 800045e4 <fileread>
    80005162:	87aa                	mv	a5,a0
}
    80005164:	853e                	mv	a0,a5
    80005166:	70a2                	ld	ra,40(sp)
    80005168:	7402                	ld	s0,32(sp)
    8000516a:	6145                	addi	sp,sp,48
    8000516c:	8082                	ret

000000008000516e <sys_write>:
{
    8000516e:	7179                	addi	sp,sp,-48
    80005170:	f406                	sd	ra,40(sp)
    80005172:	f022                	sd	s0,32(sp)
    80005174:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005176:	fe840613          	addi	a2,s0,-24
    8000517a:	4581                	li	a1,0
    8000517c:	4501                	li	a0,0
    8000517e:	00000097          	auipc	ra,0x0
    80005182:	d28080e7          	jalr	-728(ra) # 80004ea6 <argfd>
    return -1;
    80005186:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005188:	04054163          	bltz	a0,800051ca <sys_write+0x5c>
    8000518c:	fe440593          	addi	a1,s0,-28
    80005190:	4509                	li	a0,2
    80005192:	ffffe097          	auipc	ra,0xffffe
    80005196:	8ba080e7          	jalr	-1862(ra) # 80002a4c <argint>
    return -1;
    8000519a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000519c:	02054763          	bltz	a0,800051ca <sys_write+0x5c>
    800051a0:	fd840593          	addi	a1,s0,-40
    800051a4:	4505                	li	a0,1
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	8c8080e7          	jalr	-1848(ra) # 80002a6e <argaddr>
    return -1;
    800051ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051b0:	00054d63          	bltz	a0,800051ca <sys_write+0x5c>
  return filewrite(f, p, n);
    800051b4:	fe442603          	lw	a2,-28(s0)
    800051b8:	fd843583          	ld	a1,-40(s0)
    800051bc:	fe843503          	ld	a0,-24(s0)
    800051c0:	fffff097          	auipc	ra,0xfffff
    800051c4:	4e6080e7          	jalr	1254(ra) # 800046a6 <filewrite>
    800051c8:	87aa                	mv	a5,a0
}
    800051ca:	853e                	mv	a0,a5
    800051cc:	70a2                	ld	ra,40(sp)
    800051ce:	7402                	ld	s0,32(sp)
    800051d0:	6145                	addi	sp,sp,48
    800051d2:	8082                	ret

00000000800051d4 <sys_close>:
{
    800051d4:	1101                	addi	sp,sp,-32
    800051d6:	ec06                	sd	ra,24(sp)
    800051d8:	e822                	sd	s0,16(sp)
    800051da:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051dc:	fe040613          	addi	a2,s0,-32
    800051e0:	fec40593          	addi	a1,s0,-20
    800051e4:	4501                	li	a0,0
    800051e6:	00000097          	auipc	ra,0x0
    800051ea:	cc0080e7          	jalr	-832(ra) # 80004ea6 <argfd>
    return -1;
    800051ee:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051f0:	02054463          	bltz	a0,80005218 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051f4:	ffffc097          	auipc	ra,0xffffc
    800051f8:	7a2080e7          	jalr	1954(ra) # 80001996 <myproc>
    800051fc:	fec42783          	lw	a5,-20(s0)
    80005200:	07e9                	addi	a5,a5,26
    80005202:	078e                	slli	a5,a5,0x3
    80005204:	953e                	add	a0,a0,a5
    80005206:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000520a:	fe043503          	ld	a0,-32(s0)
    8000520e:	fffff097          	auipc	ra,0xfffff
    80005212:	29c080e7          	jalr	668(ra) # 800044aa <fileclose>
  return 0;
    80005216:	4781                	li	a5,0
}
    80005218:	853e                	mv	a0,a5
    8000521a:	60e2                	ld	ra,24(sp)
    8000521c:	6442                	ld	s0,16(sp)
    8000521e:	6105                	addi	sp,sp,32
    80005220:	8082                	ret

0000000080005222 <sys_fstat>:
{
    80005222:	1101                	addi	sp,sp,-32
    80005224:	ec06                	sd	ra,24(sp)
    80005226:	e822                	sd	s0,16(sp)
    80005228:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000522a:	fe840613          	addi	a2,s0,-24
    8000522e:	4581                	li	a1,0
    80005230:	4501                	li	a0,0
    80005232:	00000097          	auipc	ra,0x0
    80005236:	c74080e7          	jalr	-908(ra) # 80004ea6 <argfd>
    return -1;
    8000523a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000523c:	02054563          	bltz	a0,80005266 <sys_fstat+0x44>
    80005240:	fe040593          	addi	a1,s0,-32
    80005244:	4505                	li	a0,1
    80005246:	ffffe097          	auipc	ra,0xffffe
    8000524a:	828080e7          	jalr	-2008(ra) # 80002a6e <argaddr>
    return -1;
    8000524e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005250:	00054b63          	bltz	a0,80005266 <sys_fstat+0x44>
  return filestat(f, st);
    80005254:	fe043583          	ld	a1,-32(s0)
    80005258:	fe843503          	ld	a0,-24(s0)
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	316080e7          	jalr	790(ra) # 80004572 <filestat>
    80005264:	87aa                	mv	a5,a0
}
    80005266:	853e                	mv	a0,a5
    80005268:	60e2                	ld	ra,24(sp)
    8000526a:	6442                	ld	s0,16(sp)
    8000526c:	6105                	addi	sp,sp,32
    8000526e:	8082                	ret

0000000080005270 <sys_link>:
{
    80005270:	7169                	addi	sp,sp,-304
    80005272:	f606                	sd	ra,296(sp)
    80005274:	f222                	sd	s0,288(sp)
    80005276:	ee26                	sd	s1,280(sp)
    80005278:	ea4a                	sd	s2,272(sp)
    8000527a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000527c:	08000613          	li	a2,128
    80005280:	ed040593          	addi	a1,s0,-304
    80005284:	4501                	li	a0,0
    80005286:	ffffe097          	auipc	ra,0xffffe
    8000528a:	80a080e7          	jalr	-2038(ra) # 80002a90 <argstr>
    return -1;
    8000528e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005290:	10054e63          	bltz	a0,800053ac <sys_link+0x13c>
    80005294:	08000613          	li	a2,128
    80005298:	f5040593          	addi	a1,s0,-176
    8000529c:	4505                	li	a0,1
    8000529e:	ffffd097          	auipc	ra,0xffffd
    800052a2:	7f2080e7          	jalr	2034(ra) # 80002a90 <argstr>
    return -1;
    800052a6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052a8:	10054263          	bltz	a0,800053ac <sys_link+0x13c>
  begin_op();
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	d36080e7          	jalr	-714(ra) # 80003fe2 <begin_op>
  if((ip = namei(old)) == 0){
    800052b4:	ed040513          	addi	a0,s0,-304
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	b0a080e7          	jalr	-1270(ra) # 80003dc2 <namei>
    800052c0:	84aa                	mv	s1,a0
    800052c2:	c551                	beqz	a0,8000534e <sys_link+0xde>
  ilock(ip);
    800052c4:	ffffe097          	auipc	ra,0xffffe
    800052c8:	342080e7          	jalr	834(ra) # 80003606 <ilock>
  if(ip->type == T_DIR){
    800052cc:	04449703          	lh	a4,68(s1)
    800052d0:	4785                	li	a5,1
    800052d2:	08f70463          	beq	a4,a5,8000535a <sys_link+0xea>
  ip->nlink++;
    800052d6:	04a4d783          	lhu	a5,74(s1)
    800052da:	2785                	addiw	a5,a5,1
    800052dc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052e0:	8526                	mv	a0,s1
    800052e2:	ffffe097          	auipc	ra,0xffffe
    800052e6:	258080e7          	jalr	600(ra) # 8000353a <iupdate>
  iunlock(ip);
    800052ea:	8526                	mv	a0,s1
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	3dc080e7          	jalr	988(ra) # 800036c8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052f4:	fd040593          	addi	a1,s0,-48
    800052f8:	f5040513          	addi	a0,s0,-176
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	ae4080e7          	jalr	-1308(ra) # 80003de0 <nameiparent>
    80005304:	892a                	mv	s2,a0
    80005306:	c935                	beqz	a0,8000537a <sys_link+0x10a>
  ilock(dp);
    80005308:	ffffe097          	auipc	ra,0xffffe
    8000530c:	2fe080e7          	jalr	766(ra) # 80003606 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005310:	00092703          	lw	a4,0(s2)
    80005314:	409c                	lw	a5,0(s1)
    80005316:	04f71d63          	bne	a4,a5,80005370 <sys_link+0x100>
    8000531a:	40d0                	lw	a2,4(s1)
    8000531c:	fd040593          	addi	a1,s0,-48
    80005320:	854a                	mv	a0,s2
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	9de080e7          	jalr	-1570(ra) # 80003d00 <dirlink>
    8000532a:	04054363          	bltz	a0,80005370 <sys_link+0x100>
  iunlockput(dp);
    8000532e:	854a                	mv	a0,s2
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	538080e7          	jalr	1336(ra) # 80003868 <iunlockput>
  iput(ip);
    80005338:	8526                	mv	a0,s1
    8000533a:	ffffe097          	auipc	ra,0xffffe
    8000533e:	486080e7          	jalr	1158(ra) # 800037c0 <iput>
  end_op();
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	d1e080e7          	jalr	-738(ra) # 80004060 <end_op>
  return 0;
    8000534a:	4781                	li	a5,0
    8000534c:	a085                	j	800053ac <sys_link+0x13c>
    end_op();
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	d12080e7          	jalr	-750(ra) # 80004060 <end_op>
    return -1;
    80005356:	57fd                	li	a5,-1
    80005358:	a891                	j	800053ac <sys_link+0x13c>
    iunlockput(ip);
    8000535a:	8526                	mv	a0,s1
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	50c080e7          	jalr	1292(ra) # 80003868 <iunlockput>
    end_op();
    80005364:	fffff097          	auipc	ra,0xfffff
    80005368:	cfc080e7          	jalr	-772(ra) # 80004060 <end_op>
    return -1;
    8000536c:	57fd                	li	a5,-1
    8000536e:	a83d                	j	800053ac <sys_link+0x13c>
    iunlockput(dp);
    80005370:	854a                	mv	a0,s2
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	4f6080e7          	jalr	1270(ra) # 80003868 <iunlockput>
  ilock(ip);
    8000537a:	8526                	mv	a0,s1
    8000537c:	ffffe097          	auipc	ra,0xffffe
    80005380:	28a080e7          	jalr	650(ra) # 80003606 <ilock>
  ip->nlink--;
    80005384:	04a4d783          	lhu	a5,74(s1)
    80005388:	37fd                	addiw	a5,a5,-1
    8000538a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000538e:	8526                	mv	a0,s1
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	1aa080e7          	jalr	426(ra) # 8000353a <iupdate>
  iunlockput(ip);
    80005398:	8526                	mv	a0,s1
    8000539a:	ffffe097          	auipc	ra,0xffffe
    8000539e:	4ce080e7          	jalr	1230(ra) # 80003868 <iunlockput>
  end_op();
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	cbe080e7          	jalr	-834(ra) # 80004060 <end_op>
  return -1;
    800053aa:	57fd                	li	a5,-1
}
    800053ac:	853e                	mv	a0,a5
    800053ae:	70b2                	ld	ra,296(sp)
    800053b0:	7412                	ld	s0,288(sp)
    800053b2:	64f2                	ld	s1,280(sp)
    800053b4:	6952                	ld	s2,272(sp)
    800053b6:	6155                	addi	sp,sp,304
    800053b8:	8082                	ret

00000000800053ba <sys_unlink>:
{
    800053ba:	7151                	addi	sp,sp,-240
    800053bc:	f586                	sd	ra,232(sp)
    800053be:	f1a2                	sd	s0,224(sp)
    800053c0:	eda6                	sd	s1,216(sp)
    800053c2:	e9ca                	sd	s2,208(sp)
    800053c4:	e5ce                	sd	s3,200(sp)
    800053c6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800053c8:	08000613          	li	a2,128
    800053cc:	f3040593          	addi	a1,s0,-208
    800053d0:	4501                	li	a0,0
    800053d2:	ffffd097          	auipc	ra,0xffffd
    800053d6:	6be080e7          	jalr	1726(ra) # 80002a90 <argstr>
    800053da:	18054163          	bltz	a0,8000555c <sys_unlink+0x1a2>
  begin_op();
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	c04080e7          	jalr	-1020(ra) # 80003fe2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053e6:	fb040593          	addi	a1,s0,-80
    800053ea:	f3040513          	addi	a0,s0,-208
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	9f2080e7          	jalr	-1550(ra) # 80003de0 <nameiparent>
    800053f6:	84aa                	mv	s1,a0
    800053f8:	c979                	beqz	a0,800054ce <sys_unlink+0x114>
  ilock(dp);
    800053fa:	ffffe097          	auipc	ra,0xffffe
    800053fe:	20c080e7          	jalr	524(ra) # 80003606 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005402:	00003597          	auipc	a1,0x3
    80005406:	30658593          	addi	a1,a1,774 # 80008708 <syscalls+0x2c0>
    8000540a:	fb040513          	addi	a0,s0,-80
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	6c2080e7          	jalr	1730(ra) # 80003ad0 <namecmp>
    80005416:	14050a63          	beqz	a0,8000556a <sys_unlink+0x1b0>
    8000541a:	00003597          	auipc	a1,0x3
    8000541e:	2f658593          	addi	a1,a1,758 # 80008710 <syscalls+0x2c8>
    80005422:	fb040513          	addi	a0,s0,-80
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	6aa080e7          	jalr	1706(ra) # 80003ad0 <namecmp>
    8000542e:	12050e63          	beqz	a0,8000556a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005432:	f2c40613          	addi	a2,s0,-212
    80005436:	fb040593          	addi	a1,s0,-80
    8000543a:	8526                	mv	a0,s1
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	6ae080e7          	jalr	1710(ra) # 80003aea <dirlookup>
    80005444:	892a                	mv	s2,a0
    80005446:	12050263          	beqz	a0,8000556a <sys_unlink+0x1b0>
  ilock(ip);
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	1bc080e7          	jalr	444(ra) # 80003606 <ilock>
  if(ip->nlink < 1)
    80005452:	04a91783          	lh	a5,74(s2)
    80005456:	08f05263          	blez	a5,800054da <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000545a:	04491703          	lh	a4,68(s2)
    8000545e:	4785                	li	a5,1
    80005460:	08f70563          	beq	a4,a5,800054ea <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005464:	4641                	li	a2,16
    80005466:	4581                	li	a1,0
    80005468:	fc040513          	addi	a0,s0,-64
    8000546c:	ffffc097          	auipc	ra,0xffffc
    80005470:	860080e7          	jalr	-1952(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005474:	4741                	li	a4,16
    80005476:	f2c42683          	lw	a3,-212(s0)
    8000547a:	fc040613          	addi	a2,s0,-64
    8000547e:	4581                	li	a1,0
    80005480:	8526                	mv	a0,s1
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	530080e7          	jalr	1328(ra) # 800039b2 <writei>
    8000548a:	47c1                	li	a5,16
    8000548c:	0af51563          	bne	a0,a5,80005536 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005490:	04491703          	lh	a4,68(s2)
    80005494:	4785                	li	a5,1
    80005496:	0af70863          	beq	a4,a5,80005546 <sys_unlink+0x18c>
  iunlockput(dp);
    8000549a:	8526                	mv	a0,s1
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	3cc080e7          	jalr	972(ra) # 80003868 <iunlockput>
  ip->nlink--;
    800054a4:	04a95783          	lhu	a5,74(s2)
    800054a8:	37fd                	addiw	a5,a5,-1
    800054aa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800054ae:	854a                	mv	a0,s2
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	08a080e7          	jalr	138(ra) # 8000353a <iupdate>
  iunlockput(ip);
    800054b8:	854a                	mv	a0,s2
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	3ae080e7          	jalr	942(ra) # 80003868 <iunlockput>
  end_op();
    800054c2:	fffff097          	auipc	ra,0xfffff
    800054c6:	b9e080e7          	jalr	-1122(ra) # 80004060 <end_op>
  return 0;
    800054ca:	4501                	li	a0,0
    800054cc:	a84d                	j	8000557e <sys_unlink+0x1c4>
    end_op();
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	b92080e7          	jalr	-1134(ra) # 80004060 <end_op>
    return -1;
    800054d6:	557d                	li	a0,-1
    800054d8:	a05d                	j	8000557e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054da:	00003517          	auipc	a0,0x3
    800054de:	25e50513          	addi	a0,a0,606 # 80008738 <syscalls+0x2f0>
    800054e2:	ffffb097          	auipc	ra,0xffffb
    800054e6:	058080e7          	jalr	88(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054ea:	04c92703          	lw	a4,76(s2)
    800054ee:	02000793          	li	a5,32
    800054f2:	f6e7f9e3          	bgeu	a5,a4,80005464 <sys_unlink+0xaa>
    800054f6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054fa:	4741                	li	a4,16
    800054fc:	86ce                	mv	a3,s3
    800054fe:	f1840613          	addi	a2,s0,-232
    80005502:	4581                	li	a1,0
    80005504:	854a                	mv	a0,s2
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	3b4080e7          	jalr	948(ra) # 800038ba <readi>
    8000550e:	47c1                	li	a5,16
    80005510:	00f51b63          	bne	a0,a5,80005526 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005514:	f1845783          	lhu	a5,-232(s0)
    80005518:	e7a1                	bnez	a5,80005560 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000551a:	29c1                	addiw	s3,s3,16
    8000551c:	04c92783          	lw	a5,76(s2)
    80005520:	fcf9ede3          	bltu	s3,a5,800054fa <sys_unlink+0x140>
    80005524:	b781                	j	80005464 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005526:	00003517          	auipc	a0,0x3
    8000552a:	22a50513          	addi	a0,a0,554 # 80008750 <syscalls+0x308>
    8000552e:	ffffb097          	auipc	ra,0xffffb
    80005532:	00c080e7          	jalr	12(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005536:	00003517          	auipc	a0,0x3
    8000553a:	23250513          	addi	a0,a0,562 # 80008768 <syscalls+0x320>
    8000553e:	ffffb097          	auipc	ra,0xffffb
    80005542:	ffc080e7          	jalr	-4(ra) # 8000053a <panic>
    dp->nlink--;
    80005546:	04a4d783          	lhu	a5,74(s1)
    8000554a:	37fd                	addiw	a5,a5,-1
    8000554c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005550:	8526                	mv	a0,s1
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	fe8080e7          	jalr	-24(ra) # 8000353a <iupdate>
    8000555a:	b781                	j	8000549a <sys_unlink+0xe0>
    return -1;
    8000555c:	557d                	li	a0,-1
    8000555e:	a005                	j	8000557e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005560:	854a                	mv	a0,s2
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	306080e7          	jalr	774(ra) # 80003868 <iunlockput>
  iunlockput(dp);
    8000556a:	8526                	mv	a0,s1
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	2fc080e7          	jalr	764(ra) # 80003868 <iunlockput>
  end_op();
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	aec080e7          	jalr	-1300(ra) # 80004060 <end_op>
  return -1;
    8000557c:	557d                	li	a0,-1
}
    8000557e:	70ae                	ld	ra,232(sp)
    80005580:	740e                	ld	s0,224(sp)
    80005582:	64ee                	ld	s1,216(sp)
    80005584:	694e                	ld	s2,208(sp)
    80005586:	69ae                	ld	s3,200(sp)
    80005588:	616d                	addi	sp,sp,240
    8000558a:	8082                	ret

000000008000558c <sys_open>:

uint64
sys_open(void)
{
    8000558c:	7131                	addi	sp,sp,-192
    8000558e:	fd06                	sd	ra,184(sp)
    80005590:	f922                	sd	s0,176(sp)
    80005592:	f526                	sd	s1,168(sp)
    80005594:	f14a                	sd	s2,160(sp)
    80005596:	ed4e                	sd	s3,152(sp)
    80005598:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000559a:	08000613          	li	a2,128
    8000559e:	f5040593          	addi	a1,s0,-176
    800055a2:	4501                	li	a0,0
    800055a4:	ffffd097          	auipc	ra,0xffffd
    800055a8:	4ec080e7          	jalr	1260(ra) # 80002a90 <argstr>
    return -1;
    800055ac:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055ae:	0c054163          	bltz	a0,80005670 <sys_open+0xe4>
    800055b2:	f4c40593          	addi	a1,s0,-180
    800055b6:	4505                	li	a0,1
    800055b8:	ffffd097          	auipc	ra,0xffffd
    800055bc:	494080e7          	jalr	1172(ra) # 80002a4c <argint>
    800055c0:	0a054863          	bltz	a0,80005670 <sys_open+0xe4>

  begin_op();
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	a1e080e7          	jalr	-1506(ra) # 80003fe2 <begin_op>

  if(omode & O_CREATE){
    800055cc:	f4c42783          	lw	a5,-180(s0)
    800055d0:	2007f793          	andi	a5,a5,512
    800055d4:	cbdd                	beqz	a5,8000568a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800055d6:	4681                	li	a3,0
    800055d8:	4601                	li	a2,0
    800055da:	4589                	li	a1,2
    800055dc:	f5040513          	addi	a0,s0,-176
    800055e0:	00000097          	auipc	ra,0x0
    800055e4:	970080e7          	jalr	-1680(ra) # 80004f50 <create>
    800055e8:	892a                	mv	s2,a0
    if(ip == 0){
    800055ea:	c959                	beqz	a0,80005680 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055ec:	04491703          	lh	a4,68(s2)
    800055f0:	478d                	li	a5,3
    800055f2:	00f71763          	bne	a4,a5,80005600 <sys_open+0x74>
    800055f6:	04695703          	lhu	a4,70(s2)
    800055fa:	47a5                	li	a5,9
    800055fc:	0ce7ec63          	bltu	a5,a4,800056d4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	dee080e7          	jalr	-530(ra) # 800043ee <filealloc>
    80005608:	89aa                	mv	s3,a0
    8000560a:	10050263          	beqz	a0,8000570e <sys_open+0x182>
    8000560e:	00000097          	auipc	ra,0x0
    80005612:	900080e7          	jalr	-1792(ra) # 80004f0e <fdalloc>
    80005616:	84aa                	mv	s1,a0
    80005618:	0e054663          	bltz	a0,80005704 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000561c:	04491703          	lh	a4,68(s2)
    80005620:	478d                	li	a5,3
    80005622:	0cf70463          	beq	a4,a5,800056ea <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005626:	4789                	li	a5,2
    80005628:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000562c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005630:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005634:	f4c42783          	lw	a5,-180(s0)
    80005638:	0017c713          	xori	a4,a5,1
    8000563c:	8b05                	andi	a4,a4,1
    8000563e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005642:	0037f713          	andi	a4,a5,3
    80005646:	00e03733          	snez	a4,a4
    8000564a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000564e:	4007f793          	andi	a5,a5,1024
    80005652:	c791                	beqz	a5,8000565e <sys_open+0xd2>
    80005654:	04491703          	lh	a4,68(s2)
    80005658:	4789                	li	a5,2
    8000565a:	08f70f63          	beq	a4,a5,800056f8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000565e:	854a                	mv	a0,s2
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	068080e7          	jalr	104(ra) # 800036c8 <iunlock>
  end_op();
    80005668:	fffff097          	auipc	ra,0xfffff
    8000566c:	9f8080e7          	jalr	-1544(ra) # 80004060 <end_op>

  return fd;
}
    80005670:	8526                	mv	a0,s1
    80005672:	70ea                	ld	ra,184(sp)
    80005674:	744a                	ld	s0,176(sp)
    80005676:	74aa                	ld	s1,168(sp)
    80005678:	790a                	ld	s2,160(sp)
    8000567a:	69ea                	ld	s3,152(sp)
    8000567c:	6129                	addi	sp,sp,192
    8000567e:	8082                	ret
      end_op();
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	9e0080e7          	jalr	-1568(ra) # 80004060 <end_op>
      return -1;
    80005688:	b7e5                	j	80005670 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000568a:	f5040513          	addi	a0,s0,-176
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	734080e7          	jalr	1844(ra) # 80003dc2 <namei>
    80005696:	892a                	mv	s2,a0
    80005698:	c905                	beqz	a0,800056c8 <sys_open+0x13c>
    ilock(ip);
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	f6c080e7          	jalr	-148(ra) # 80003606 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800056a2:	04491703          	lh	a4,68(s2)
    800056a6:	4785                	li	a5,1
    800056a8:	f4f712e3          	bne	a4,a5,800055ec <sys_open+0x60>
    800056ac:	f4c42783          	lw	a5,-180(s0)
    800056b0:	dba1                	beqz	a5,80005600 <sys_open+0x74>
      iunlockput(ip);
    800056b2:	854a                	mv	a0,s2
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	1b4080e7          	jalr	436(ra) # 80003868 <iunlockput>
      end_op();
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	9a4080e7          	jalr	-1628(ra) # 80004060 <end_op>
      return -1;
    800056c4:	54fd                	li	s1,-1
    800056c6:	b76d                	j	80005670 <sys_open+0xe4>
      end_op();
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	998080e7          	jalr	-1640(ra) # 80004060 <end_op>
      return -1;
    800056d0:	54fd                	li	s1,-1
    800056d2:	bf79                	j	80005670 <sys_open+0xe4>
    iunlockput(ip);
    800056d4:	854a                	mv	a0,s2
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	192080e7          	jalr	402(ra) # 80003868 <iunlockput>
    end_op();
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	982080e7          	jalr	-1662(ra) # 80004060 <end_op>
    return -1;
    800056e6:	54fd                	li	s1,-1
    800056e8:	b761                	j	80005670 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800056ea:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056ee:	04691783          	lh	a5,70(s2)
    800056f2:	02f99223          	sh	a5,36(s3)
    800056f6:	bf2d                	j	80005630 <sys_open+0xa4>
    itrunc(ip);
    800056f8:	854a                	mv	a0,s2
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	01a080e7          	jalr	26(ra) # 80003714 <itrunc>
    80005702:	bfb1                	j	8000565e <sys_open+0xd2>
      fileclose(f);
    80005704:	854e                	mv	a0,s3
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	da4080e7          	jalr	-604(ra) # 800044aa <fileclose>
    iunlockput(ip);
    8000570e:	854a                	mv	a0,s2
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	158080e7          	jalr	344(ra) # 80003868 <iunlockput>
    end_op();
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	948080e7          	jalr	-1720(ra) # 80004060 <end_op>
    return -1;
    80005720:	54fd                	li	s1,-1
    80005722:	b7b9                	j	80005670 <sys_open+0xe4>

0000000080005724 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005724:	7175                	addi	sp,sp,-144
    80005726:	e506                	sd	ra,136(sp)
    80005728:	e122                	sd	s0,128(sp)
    8000572a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	8b6080e7          	jalr	-1866(ra) # 80003fe2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005734:	08000613          	li	a2,128
    80005738:	f7040593          	addi	a1,s0,-144
    8000573c:	4501                	li	a0,0
    8000573e:	ffffd097          	auipc	ra,0xffffd
    80005742:	352080e7          	jalr	850(ra) # 80002a90 <argstr>
    80005746:	02054963          	bltz	a0,80005778 <sys_mkdir+0x54>
    8000574a:	4681                	li	a3,0
    8000574c:	4601                	li	a2,0
    8000574e:	4585                	li	a1,1
    80005750:	f7040513          	addi	a0,s0,-144
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	7fc080e7          	jalr	2044(ra) # 80004f50 <create>
    8000575c:	cd11                	beqz	a0,80005778 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	10a080e7          	jalr	266(ra) # 80003868 <iunlockput>
  end_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	8fa080e7          	jalr	-1798(ra) # 80004060 <end_op>
  return 0;
    8000576e:	4501                	li	a0,0
}
    80005770:	60aa                	ld	ra,136(sp)
    80005772:	640a                	ld	s0,128(sp)
    80005774:	6149                	addi	sp,sp,144
    80005776:	8082                	ret
    end_op();
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	8e8080e7          	jalr	-1816(ra) # 80004060 <end_op>
    return -1;
    80005780:	557d                	li	a0,-1
    80005782:	b7fd                	j	80005770 <sys_mkdir+0x4c>

0000000080005784 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005784:	7135                	addi	sp,sp,-160
    80005786:	ed06                	sd	ra,152(sp)
    80005788:	e922                	sd	s0,144(sp)
    8000578a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	856080e7          	jalr	-1962(ra) # 80003fe2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005794:	08000613          	li	a2,128
    80005798:	f7040593          	addi	a1,s0,-144
    8000579c:	4501                	li	a0,0
    8000579e:	ffffd097          	auipc	ra,0xffffd
    800057a2:	2f2080e7          	jalr	754(ra) # 80002a90 <argstr>
    800057a6:	04054a63          	bltz	a0,800057fa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800057aa:	f6c40593          	addi	a1,s0,-148
    800057ae:	4505                	li	a0,1
    800057b0:	ffffd097          	auipc	ra,0xffffd
    800057b4:	29c080e7          	jalr	668(ra) # 80002a4c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057b8:	04054163          	bltz	a0,800057fa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800057bc:	f6840593          	addi	a1,s0,-152
    800057c0:	4509                	li	a0,2
    800057c2:	ffffd097          	auipc	ra,0xffffd
    800057c6:	28a080e7          	jalr	650(ra) # 80002a4c <argint>
     argint(1, &major) < 0 ||
    800057ca:	02054863          	bltz	a0,800057fa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057ce:	f6841683          	lh	a3,-152(s0)
    800057d2:	f6c41603          	lh	a2,-148(s0)
    800057d6:	458d                	li	a1,3
    800057d8:	f7040513          	addi	a0,s0,-144
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	774080e7          	jalr	1908(ra) # 80004f50 <create>
     argint(2, &minor) < 0 ||
    800057e4:	c919                	beqz	a0,800057fa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	082080e7          	jalr	130(ra) # 80003868 <iunlockput>
  end_op();
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	872080e7          	jalr	-1934(ra) # 80004060 <end_op>
  return 0;
    800057f6:	4501                	li	a0,0
    800057f8:	a031                	j	80005804 <sys_mknod+0x80>
    end_op();
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	866080e7          	jalr	-1946(ra) # 80004060 <end_op>
    return -1;
    80005802:	557d                	li	a0,-1
}
    80005804:	60ea                	ld	ra,152(sp)
    80005806:	644a                	ld	s0,144(sp)
    80005808:	610d                	addi	sp,sp,160
    8000580a:	8082                	ret

000000008000580c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000580c:	7135                	addi	sp,sp,-160
    8000580e:	ed06                	sd	ra,152(sp)
    80005810:	e922                	sd	s0,144(sp)
    80005812:	e526                	sd	s1,136(sp)
    80005814:	e14a                	sd	s2,128(sp)
    80005816:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005818:	ffffc097          	auipc	ra,0xffffc
    8000581c:	17e080e7          	jalr	382(ra) # 80001996 <myproc>
    80005820:	892a                	mv	s2,a0
  
  begin_op();
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	7c0080e7          	jalr	1984(ra) # 80003fe2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000582a:	08000613          	li	a2,128
    8000582e:	f6040593          	addi	a1,s0,-160
    80005832:	4501                	li	a0,0
    80005834:	ffffd097          	auipc	ra,0xffffd
    80005838:	25c080e7          	jalr	604(ra) # 80002a90 <argstr>
    8000583c:	04054b63          	bltz	a0,80005892 <sys_chdir+0x86>
    80005840:	f6040513          	addi	a0,s0,-160
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	57e080e7          	jalr	1406(ra) # 80003dc2 <namei>
    8000584c:	84aa                	mv	s1,a0
    8000584e:	c131                	beqz	a0,80005892 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	db6080e7          	jalr	-586(ra) # 80003606 <ilock>
  if(ip->type != T_DIR){
    80005858:	04449703          	lh	a4,68(s1)
    8000585c:	4785                	li	a5,1
    8000585e:	04f71063          	bne	a4,a5,8000589e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005862:	8526                	mv	a0,s1
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	e64080e7          	jalr	-412(ra) # 800036c8 <iunlock>
  iput(p->cwd);
    8000586c:	15093503          	ld	a0,336(s2)
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	f50080e7          	jalr	-176(ra) # 800037c0 <iput>
  end_op();
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	7e8080e7          	jalr	2024(ra) # 80004060 <end_op>
  p->cwd = ip;
    80005880:	14993823          	sd	s1,336(s2)
  return 0;
    80005884:	4501                	li	a0,0
}
    80005886:	60ea                	ld	ra,152(sp)
    80005888:	644a                	ld	s0,144(sp)
    8000588a:	64aa                	ld	s1,136(sp)
    8000588c:	690a                	ld	s2,128(sp)
    8000588e:	610d                	addi	sp,sp,160
    80005890:	8082                	ret
    end_op();
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	7ce080e7          	jalr	1998(ra) # 80004060 <end_op>
    return -1;
    8000589a:	557d                	li	a0,-1
    8000589c:	b7ed                	j	80005886 <sys_chdir+0x7a>
    iunlockput(ip);
    8000589e:	8526                	mv	a0,s1
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	fc8080e7          	jalr	-56(ra) # 80003868 <iunlockput>
    end_op();
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	7b8080e7          	jalr	1976(ra) # 80004060 <end_op>
    return -1;
    800058b0:	557d                	li	a0,-1
    800058b2:	bfd1                	j	80005886 <sys_chdir+0x7a>

00000000800058b4 <sys_exec>:

uint64
sys_exec(void)
{
    800058b4:	7145                	addi	sp,sp,-464
    800058b6:	e786                	sd	ra,456(sp)
    800058b8:	e3a2                	sd	s0,448(sp)
    800058ba:	ff26                	sd	s1,440(sp)
    800058bc:	fb4a                	sd	s2,432(sp)
    800058be:	f74e                	sd	s3,424(sp)
    800058c0:	f352                	sd	s4,416(sp)
    800058c2:	ef56                	sd	s5,408(sp)
    800058c4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058c6:	08000613          	li	a2,128
    800058ca:	f4040593          	addi	a1,s0,-192
    800058ce:	4501                	li	a0,0
    800058d0:	ffffd097          	auipc	ra,0xffffd
    800058d4:	1c0080e7          	jalr	448(ra) # 80002a90 <argstr>
    return -1;
    800058d8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058da:	0c054b63          	bltz	a0,800059b0 <sys_exec+0xfc>
    800058de:	e3840593          	addi	a1,s0,-456
    800058e2:	4505                	li	a0,1
    800058e4:	ffffd097          	auipc	ra,0xffffd
    800058e8:	18a080e7          	jalr	394(ra) # 80002a6e <argaddr>
    800058ec:	0c054263          	bltz	a0,800059b0 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800058f0:	10000613          	li	a2,256
    800058f4:	4581                	li	a1,0
    800058f6:	e4040513          	addi	a0,s0,-448
    800058fa:	ffffb097          	auipc	ra,0xffffb
    800058fe:	3d2080e7          	jalr	978(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005902:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005906:	89a6                	mv	s3,s1
    80005908:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000590a:	02000a13          	li	s4,32
    8000590e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005912:	00391513          	slli	a0,s2,0x3
    80005916:	e3040593          	addi	a1,s0,-464
    8000591a:	e3843783          	ld	a5,-456(s0)
    8000591e:	953e                	add	a0,a0,a5
    80005920:	ffffd097          	auipc	ra,0xffffd
    80005924:	092080e7          	jalr	146(ra) # 800029b2 <fetchaddr>
    80005928:	02054a63          	bltz	a0,8000595c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000592c:	e3043783          	ld	a5,-464(s0)
    80005930:	c3b9                	beqz	a5,80005976 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005932:	ffffb097          	auipc	ra,0xffffb
    80005936:	1ae080e7          	jalr	430(ra) # 80000ae0 <kalloc>
    8000593a:	85aa                	mv	a1,a0
    8000593c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005940:	cd11                	beqz	a0,8000595c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005942:	6605                	lui	a2,0x1
    80005944:	e3043503          	ld	a0,-464(s0)
    80005948:	ffffd097          	auipc	ra,0xffffd
    8000594c:	0bc080e7          	jalr	188(ra) # 80002a04 <fetchstr>
    80005950:	00054663          	bltz	a0,8000595c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005954:	0905                	addi	s2,s2,1
    80005956:	09a1                	addi	s3,s3,8
    80005958:	fb491be3          	bne	s2,s4,8000590e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000595c:	f4040913          	addi	s2,s0,-192
    80005960:	6088                	ld	a0,0(s1)
    80005962:	c531                	beqz	a0,800059ae <sys_exec+0xfa>
    kfree(argv[i]);
    80005964:	ffffb097          	auipc	ra,0xffffb
    80005968:	07e080e7          	jalr	126(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000596c:	04a1                	addi	s1,s1,8
    8000596e:	ff2499e3          	bne	s1,s2,80005960 <sys_exec+0xac>
  return -1;
    80005972:	597d                	li	s2,-1
    80005974:	a835                	j	800059b0 <sys_exec+0xfc>
      argv[i] = 0;
    80005976:	0a8e                	slli	s5,s5,0x3
    80005978:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    8000597c:	00878ab3          	add	s5,a5,s0
    80005980:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005984:	e4040593          	addi	a1,s0,-448
    80005988:	f4040513          	addi	a0,s0,-192
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	172080e7          	jalr	370(ra) # 80004afe <exec>
    80005994:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005996:	f4040993          	addi	s3,s0,-192
    8000599a:	6088                	ld	a0,0(s1)
    8000599c:	c911                	beqz	a0,800059b0 <sys_exec+0xfc>
    kfree(argv[i]);
    8000599e:	ffffb097          	auipc	ra,0xffffb
    800059a2:	044080e7          	jalr	68(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059a6:	04a1                	addi	s1,s1,8
    800059a8:	ff3499e3          	bne	s1,s3,8000599a <sys_exec+0xe6>
    800059ac:	a011                	j	800059b0 <sys_exec+0xfc>
  return -1;
    800059ae:	597d                	li	s2,-1
}
    800059b0:	854a                	mv	a0,s2
    800059b2:	60be                	ld	ra,456(sp)
    800059b4:	641e                	ld	s0,448(sp)
    800059b6:	74fa                	ld	s1,440(sp)
    800059b8:	795a                	ld	s2,432(sp)
    800059ba:	79ba                	ld	s3,424(sp)
    800059bc:	7a1a                	ld	s4,416(sp)
    800059be:	6afa                	ld	s5,408(sp)
    800059c0:	6179                	addi	sp,sp,464
    800059c2:	8082                	ret

00000000800059c4 <sys_pipe>:

uint64
sys_pipe(void)
{
    800059c4:	7139                	addi	sp,sp,-64
    800059c6:	fc06                	sd	ra,56(sp)
    800059c8:	f822                	sd	s0,48(sp)
    800059ca:	f426                	sd	s1,40(sp)
    800059cc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800059ce:	ffffc097          	auipc	ra,0xffffc
    800059d2:	fc8080e7          	jalr	-56(ra) # 80001996 <myproc>
    800059d6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800059d8:	fd840593          	addi	a1,s0,-40
    800059dc:	4501                	li	a0,0
    800059de:	ffffd097          	auipc	ra,0xffffd
    800059e2:	090080e7          	jalr	144(ra) # 80002a6e <argaddr>
    return -1;
    800059e6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800059e8:	0e054063          	bltz	a0,80005ac8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800059ec:	fc840593          	addi	a1,s0,-56
    800059f0:	fd040513          	addi	a0,s0,-48
    800059f4:	fffff097          	auipc	ra,0xfffff
    800059f8:	de6080e7          	jalr	-538(ra) # 800047da <pipealloc>
    return -1;
    800059fc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059fe:	0c054563          	bltz	a0,80005ac8 <sys_pipe+0x104>
  fd0 = -1;
    80005a02:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a06:	fd043503          	ld	a0,-48(s0)
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	504080e7          	jalr	1284(ra) # 80004f0e <fdalloc>
    80005a12:	fca42223          	sw	a0,-60(s0)
    80005a16:	08054c63          	bltz	a0,80005aae <sys_pipe+0xea>
    80005a1a:	fc843503          	ld	a0,-56(s0)
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	4f0080e7          	jalr	1264(ra) # 80004f0e <fdalloc>
    80005a26:	fca42023          	sw	a0,-64(s0)
    80005a2a:	06054963          	bltz	a0,80005a9c <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a2e:	4691                	li	a3,4
    80005a30:	fc440613          	addi	a2,s0,-60
    80005a34:	fd843583          	ld	a1,-40(s0)
    80005a38:	68a8                	ld	a0,80(s1)
    80005a3a:	ffffc097          	auipc	ra,0xffffc
    80005a3e:	c20080e7          	jalr	-992(ra) # 8000165a <copyout>
    80005a42:	02054063          	bltz	a0,80005a62 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a46:	4691                	li	a3,4
    80005a48:	fc040613          	addi	a2,s0,-64
    80005a4c:	fd843583          	ld	a1,-40(s0)
    80005a50:	0591                	addi	a1,a1,4
    80005a52:	68a8                	ld	a0,80(s1)
    80005a54:	ffffc097          	auipc	ra,0xffffc
    80005a58:	c06080e7          	jalr	-1018(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a5c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a5e:	06055563          	bgez	a0,80005ac8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a62:	fc442783          	lw	a5,-60(s0)
    80005a66:	07e9                	addi	a5,a5,26
    80005a68:	078e                	slli	a5,a5,0x3
    80005a6a:	97a6                	add	a5,a5,s1
    80005a6c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a70:	fc042783          	lw	a5,-64(s0)
    80005a74:	07e9                	addi	a5,a5,26
    80005a76:	078e                	slli	a5,a5,0x3
    80005a78:	00f48533          	add	a0,s1,a5
    80005a7c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a80:	fd043503          	ld	a0,-48(s0)
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	a26080e7          	jalr	-1498(ra) # 800044aa <fileclose>
    fileclose(wf);
    80005a8c:	fc843503          	ld	a0,-56(s0)
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	a1a080e7          	jalr	-1510(ra) # 800044aa <fileclose>
    return -1;
    80005a98:	57fd                	li	a5,-1
    80005a9a:	a03d                	j	80005ac8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a9c:	fc442783          	lw	a5,-60(s0)
    80005aa0:	0007c763          	bltz	a5,80005aae <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005aa4:	07e9                	addi	a5,a5,26
    80005aa6:	078e                	slli	a5,a5,0x3
    80005aa8:	97a6                	add	a5,a5,s1
    80005aaa:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005aae:	fd043503          	ld	a0,-48(s0)
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	9f8080e7          	jalr	-1544(ra) # 800044aa <fileclose>
    fileclose(wf);
    80005aba:	fc843503          	ld	a0,-56(s0)
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	9ec080e7          	jalr	-1556(ra) # 800044aa <fileclose>
    return -1;
    80005ac6:	57fd                	li	a5,-1
}
    80005ac8:	853e                	mv	a0,a5
    80005aca:	70e2                	ld	ra,56(sp)
    80005acc:	7442                	ld	s0,48(sp)
    80005ace:	74a2                	ld	s1,40(sp)
    80005ad0:	6121                	addi	sp,sp,64
    80005ad2:	8082                	ret
	...

0000000080005ae0 <kernelvec>:
    80005ae0:	7111                	addi	sp,sp,-256
    80005ae2:	e006                	sd	ra,0(sp)
    80005ae4:	e40a                	sd	sp,8(sp)
    80005ae6:	e80e                	sd	gp,16(sp)
    80005ae8:	ec12                	sd	tp,24(sp)
    80005aea:	f016                	sd	t0,32(sp)
    80005aec:	f41a                	sd	t1,40(sp)
    80005aee:	f81e                	sd	t2,48(sp)
    80005af0:	fc22                	sd	s0,56(sp)
    80005af2:	e0a6                	sd	s1,64(sp)
    80005af4:	e4aa                	sd	a0,72(sp)
    80005af6:	e8ae                	sd	a1,80(sp)
    80005af8:	ecb2                	sd	a2,88(sp)
    80005afa:	f0b6                	sd	a3,96(sp)
    80005afc:	f4ba                	sd	a4,104(sp)
    80005afe:	f8be                	sd	a5,112(sp)
    80005b00:	fcc2                	sd	a6,120(sp)
    80005b02:	e146                	sd	a7,128(sp)
    80005b04:	e54a                	sd	s2,136(sp)
    80005b06:	e94e                	sd	s3,144(sp)
    80005b08:	ed52                	sd	s4,152(sp)
    80005b0a:	f156                	sd	s5,160(sp)
    80005b0c:	f55a                	sd	s6,168(sp)
    80005b0e:	f95e                	sd	s7,176(sp)
    80005b10:	fd62                	sd	s8,184(sp)
    80005b12:	e1e6                	sd	s9,192(sp)
    80005b14:	e5ea                	sd	s10,200(sp)
    80005b16:	e9ee                	sd	s11,208(sp)
    80005b18:	edf2                	sd	t3,216(sp)
    80005b1a:	f1f6                	sd	t4,224(sp)
    80005b1c:	f5fa                	sd	t5,232(sp)
    80005b1e:	f9fe                	sd	t6,240(sp)
    80005b20:	d5ffc0ef          	jal	ra,8000287e <kerneltrap>
    80005b24:	6082                	ld	ra,0(sp)
    80005b26:	6122                	ld	sp,8(sp)
    80005b28:	61c2                	ld	gp,16(sp)
    80005b2a:	7282                	ld	t0,32(sp)
    80005b2c:	7322                	ld	t1,40(sp)
    80005b2e:	73c2                	ld	t2,48(sp)
    80005b30:	7462                	ld	s0,56(sp)
    80005b32:	6486                	ld	s1,64(sp)
    80005b34:	6526                	ld	a0,72(sp)
    80005b36:	65c6                	ld	a1,80(sp)
    80005b38:	6666                	ld	a2,88(sp)
    80005b3a:	7686                	ld	a3,96(sp)
    80005b3c:	7726                	ld	a4,104(sp)
    80005b3e:	77c6                	ld	a5,112(sp)
    80005b40:	7866                	ld	a6,120(sp)
    80005b42:	688a                	ld	a7,128(sp)
    80005b44:	692a                	ld	s2,136(sp)
    80005b46:	69ca                	ld	s3,144(sp)
    80005b48:	6a6a                	ld	s4,152(sp)
    80005b4a:	7a8a                	ld	s5,160(sp)
    80005b4c:	7b2a                	ld	s6,168(sp)
    80005b4e:	7bca                	ld	s7,176(sp)
    80005b50:	7c6a                	ld	s8,184(sp)
    80005b52:	6c8e                	ld	s9,192(sp)
    80005b54:	6d2e                	ld	s10,200(sp)
    80005b56:	6dce                	ld	s11,208(sp)
    80005b58:	6e6e                	ld	t3,216(sp)
    80005b5a:	7e8e                	ld	t4,224(sp)
    80005b5c:	7f2e                	ld	t5,232(sp)
    80005b5e:	7fce                	ld	t6,240(sp)
    80005b60:	6111                	addi	sp,sp,256
    80005b62:	10200073          	sret
    80005b66:	00000013          	nop
    80005b6a:	00000013          	nop
    80005b6e:	0001                	nop

0000000080005b70 <timervec>:
    80005b70:	34051573          	csrrw	a0,mscratch,a0
    80005b74:	e10c                	sd	a1,0(a0)
    80005b76:	e510                	sd	a2,8(a0)
    80005b78:	e914                	sd	a3,16(a0)
    80005b7a:	6d0c                	ld	a1,24(a0)
    80005b7c:	7110                	ld	a2,32(a0)
    80005b7e:	6194                	ld	a3,0(a1)
    80005b80:	96b2                	add	a3,a3,a2
    80005b82:	e194                	sd	a3,0(a1)
    80005b84:	4589                	li	a1,2
    80005b86:	14459073          	csrw	sip,a1
    80005b8a:	6914                	ld	a3,16(a0)
    80005b8c:	6510                	ld	a2,8(a0)
    80005b8e:	610c                	ld	a1,0(a0)
    80005b90:	34051573          	csrrw	a0,mscratch,a0
    80005b94:	30200073          	mret
	...

0000000080005b9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b9a:	1141                	addi	sp,sp,-16
    80005b9c:	e422                	sd	s0,8(sp)
    80005b9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ba0:	0c0007b7          	lui	a5,0xc000
    80005ba4:	4705                	li	a4,1
    80005ba6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ba8:	c3d8                	sw	a4,4(a5)
}
    80005baa:	6422                	ld	s0,8(sp)
    80005bac:	0141                	addi	sp,sp,16
    80005bae:	8082                	ret

0000000080005bb0 <plicinithart>:

void
plicinithart(void)
{
    80005bb0:	1141                	addi	sp,sp,-16
    80005bb2:	e406                	sd	ra,8(sp)
    80005bb4:	e022                	sd	s0,0(sp)
    80005bb6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bb8:	ffffc097          	auipc	ra,0xffffc
    80005bbc:	db2080e7          	jalr	-590(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005bc0:	0085171b          	slliw	a4,a0,0x8
    80005bc4:	0c0027b7          	lui	a5,0xc002
    80005bc8:	97ba                	add	a5,a5,a4
    80005bca:	40200713          	li	a4,1026
    80005bce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005bd2:	00d5151b          	slliw	a0,a0,0xd
    80005bd6:	0c2017b7          	lui	a5,0xc201
    80005bda:	97aa                	add	a5,a5,a0
    80005bdc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005be0:	60a2                	ld	ra,8(sp)
    80005be2:	6402                	ld	s0,0(sp)
    80005be4:	0141                	addi	sp,sp,16
    80005be6:	8082                	ret

0000000080005be8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005be8:	1141                	addi	sp,sp,-16
    80005bea:	e406                	sd	ra,8(sp)
    80005bec:	e022                	sd	s0,0(sp)
    80005bee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bf0:	ffffc097          	auipc	ra,0xffffc
    80005bf4:	d7a080e7          	jalr	-646(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005bf8:	00d5151b          	slliw	a0,a0,0xd
    80005bfc:	0c2017b7          	lui	a5,0xc201
    80005c00:	97aa                	add	a5,a5,a0
  return irq;
}
    80005c02:	43c8                	lw	a0,4(a5)
    80005c04:	60a2                	ld	ra,8(sp)
    80005c06:	6402                	ld	s0,0(sp)
    80005c08:	0141                	addi	sp,sp,16
    80005c0a:	8082                	ret

0000000080005c0c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c0c:	1101                	addi	sp,sp,-32
    80005c0e:	ec06                	sd	ra,24(sp)
    80005c10:	e822                	sd	s0,16(sp)
    80005c12:	e426                	sd	s1,8(sp)
    80005c14:	1000                	addi	s0,sp,32
    80005c16:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c18:	ffffc097          	auipc	ra,0xffffc
    80005c1c:	d52080e7          	jalr	-686(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c20:	00d5151b          	slliw	a0,a0,0xd
    80005c24:	0c2017b7          	lui	a5,0xc201
    80005c28:	97aa                	add	a5,a5,a0
    80005c2a:	c3c4                	sw	s1,4(a5)
}
    80005c2c:	60e2                	ld	ra,24(sp)
    80005c2e:	6442                	ld	s0,16(sp)
    80005c30:	64a2                	ld	s1,8(sp)
    80005c32:	6105                	addi	sp,sp,32
    80005c34:	8082                	ret

0000000080005c36 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c36:	1141                	addi	sp,sp,-16
    80005c38:	e406                	sd	ra,8(sp)
    80005c3a:	e022                	sd	s0,0(sp)
    80005c3c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c3e:	479d                	li	a5,7
    80005c40:	06a7c863          	blt	a5,a0,80005cb0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005c44:	0001d717          	auipc	a4,0x1d
    80005c48:	3bc70713          	addi	a4,a4,956 # 80023000 <disk>
    80005c4c:	972a                	add	a4,a4,a0
    80005c4e:	6789                	lui	a5,0x2
    80005c50:	97ba                	add	a5,a5,a4
    80005c52:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c56:	e7ad                	bnez	a5,80005cc0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c58:	00451793          	slli	a5,a0,0x4
    80005c5c:	0001f717          	auipc	a4,0x1f
    80005c60:	3a470713          	addi	a4,a4,932 # 80025000 <disk+0x2000>
    80005c64:	6314                	ld	a3,0(a4)
    80005c66:	96be                	add	a3,a3,a5
    80005c68:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c6c:	6314                	ld	a3,0(a4)
    80005c6e:	96be                	add	a3,a3,a5
    80005c70:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005c74:	6314                	ld	a3,0(a4)
    80005c76:	96be                	add	a3,a3,a5
    80005c78:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005c7c:	6318                	ld	a4,0(a4)
    80005c7e:	97ba                	add	a5,a5,a4
    80005c80:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005c84:	0001d717          	auipc	a4,0x1d
    80005c88:	37c70713          	addi	a4,a4,892 # 80023000 <disk>
    80005c8c:	972a                	add	a4,a4,a0
    80005c8e:	6789                	lui	a5,0x2
    80005c90:	97ba                	add	a5,a5,a4
    80005c92:	4705                	li	a4,1
    80005c94:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005c98:	0001f517          	auipc	a0,0x1f
    80005c9c:	38050513          	addi	a0,a0,896 # 80025018 <disk+0x2018>
    80005ca0:	ffffc097          	auipc	ra,0xffffc
    80005ca4:	546080e7          	jalr	1350(ra) # 800021e6 <wakeup>
}
    80005ca8:	60a2                	ld	ra,8(sp)
    80005caa:	6402                	ld	s0,0(sp)
    80005cac:	0141                	addi	sp,sp,16
    80005cae:	8082                	ret
    panic("free_desc 1");
    80005cb0:	00003517          	auipc	a0,0x3
    80005cb4:	ac850513          	addi	a0,a0,-1336 # 80008778 <syscalls+0x330>
    80005cb8:	ffffb097          	auipc	ra,0xffffb
    80005cbc:	882080e7          	jalr	-1918(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005cc0:	00003517          	auipc	a0,0x3
    80005cc4:	ac850513          	addi	a0,a0,-1336 # 80008788 <syscalls+0x340>
    80005cc8:	ffffb097          	auipc	ra,0xffffb
    80005ccc:	872080e7          	jalr	-1934(ra) # 8000053a <panic>

0000000080005cd0 <virtio_disk_init>:
{
    80005cd0:	1101                	addi	sp,sp,-32
    80005cd2:	ec06                	sd	ra,24(sp)
    80005cd4:	e822                	sd	s0,16(sp)
    80005cd6:	e426                	sd	s1,8(sp)
    80005cd8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005cda:	00003597          	auipc	a1,0x3
    80005cde:	abe58593          	addi	a1,a1,-1346 # 80008798 <syscalls+0x350>
    80005ce2:	0001f517          	auipc	a0,0x1f
    80005ce6:	44650513          	addi	a0,a0,1094 # 80025128 <disk+0x2128>
    80005cea:	ffffb097          	auipc	ra,0xffffb
    80005cee:	e56080e7          	jalr	-426(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cf2:	100017b7          	lui	a5,0x10001
    80005cf6:	4398                	lw	a4,0(a5)
    80005cf8:	2701                	sext.w	a4,a4
    80005cfa:	747277b7          	lui	a5,0x74727
    80005cfe:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d02:	0ef71063          	bne	a4,a5,80005de2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d06:	100017b7          	lui	a5,0x10001
    80005d0a:	43dc                	lw	a5,4(a5)
    80005d0c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d0e:	4705                	li	a4,1
    80005d10:	0ce79963          	bne	a5,a4,80005de2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d14:	100017b7          	lui	a5,0x10001
    80005d18:	479c                	lw	a5,8(a5)
    80005d1a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d1c:	4709                	li	a4,2
    80005d1e:	0ce79263          	bne	a5,a4,80005de2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d22:	100017b7          	lui	a5,0x10001
    80005d26:	47d8                	lw	a4,12(a5)
    80005d28:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d2a:	554d47b7          	lui	a5,0x554d4
    80005d2e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d32:	0af71863          	bne	a4,a5,80005de2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d36:	100017b7          	lui	a5,0x10001
    80005d3a:	4705                	li	a4,1
    80005d3c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d3e:	470d                	li	a4,3
    80005d40:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d42:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d44:	c7ffe6b7          	lui	a3,0xc7ffe
    80005d48:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d4c:	8f75                	and	a4,a4,a3
    80005d4e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d50:	472d                	li	a4,11
    80005d52:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d54:	473d                	li	a4,15
    80005d56:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d58:	6705                	lui	a4,0x1
    80005d5a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d5c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d60:	5bdc                	lw	a5,52(a5)
    80005d62:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d64:	c7d9                	beqz	a5,80005df2 <virtio_disk_init+0x122>
  if(max < NUM)
    80005d66:	471d                	li	a4,7
    80005d68:	08f77d63          	bgeu	a4,a5,80005e02 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d6c:	100014b7          	lui	s1,0x10001
    80005d70:	47a1                	li	a5,8
    80005d72:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d74:	6609                	lui	a2,0x2
    80005d76:	4581                	li	a1,0
    80005d78:	0001d517          	auipc	a0,0x1d
    80005d7c:	28850513          	addi	a0,a0,648 # 80023000 <disk>
    80005d80:	ffffb097          	auipc	ra,0xffffb
    80005d84:	f4c080e7          	jalr	-180(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005d88:	0001d717          	auipc	a4,0x1d
    80005d8c:	27870713          	addi	a4,a4,632 # 80023000 <disk>
    80005d90:	00c75793          	srli	a5,a4,0xc
    80005d94:	2781                	sext.w	a5,a5
    80005d96:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005d98:	0001f797          	auipc	a5,0x1f
    80005d9c:	26878793          	addi	a5,a5,616 # 80025000 <disk+0x2000>
    80005da0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005da2:	0001d717          	auipc	a4,0x1d
    80005da6:	2de70713          	addi	a4,a4,734 # 80023080 <disk+0x80>
    80005daa:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005dac:	0001e717          	auipc	a4,0x1e
    80005db0:	25470713          	addi	a4,a4,596 # 80024000 <disk+0x1000>
    80005db4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005db6:	4705                	li	a4,1
    80005db8:	00e78c23          	sb	a4,24(a5)
    80005dbc:	00e78ca3          	sb	a4,25(a5)
    80005dc0:	00e78d23          	sb	a4,26(a5)
    80005dc4:	00e78da3          	sb	a4,27(a5)
    80005dc8:	00e78e23          	sb	a4,28(a5)
    80005dcc:	00e78ea3          	sb	a4,29(a5)
    80005dd0:	00e78f23          	sb	a4,30(a5)
    80005dd4:	00e78fa3          	sb	a4,31(a5)
}
    80005dd8:	60e2                	ld	ra,24(sp)
    80005dda:	6442                	ld	s0,16(sp)
    80005ddc:	64a2                	ld	s1,8(sp)
    80005dde:	6105                	addi	sp,sp,32
    80005de0:	8082                	ret
    panic("could not find virtio disk");
    80005de2:	00003517          	auipc	a0,0x3
    80005de6:	9c650513          	addi	a0,a0,-1594 # 800087a8 <syscalls+0x360>
    80005dea:	ffffa097          	auipc	ra,0xffffa
    80005dee:	750080e7          	jalr	1872(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005df2:	00003517          	auipc	a0,0x3
    80005df6:	9d650513          	addi	a0,a0,-1578 # 800087c8 <syscalls+0x380>
    80005dfa:	ffffa097          	auipc	ra,0xffffa
    80005dfe:	740080e7          	jalr	1856(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005e02:	00003517          	auipc	a0,0x3
    80005e06:	9e650513          	addi	a0,a0,-1562 # 800087e8 <syscalls+0x3a0>
    80005e0a:	ffffa097          	auipc	ra,0xffffa
    80005e0e:	730080e7          	jalr	1840(ra) # 8000053a <panic>

0000000080005e12 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e12:	7119                	addi	sp,sp,-128
    80005e14:	fc86                	sd	ra,120(sp)
    80005e16:	f8a2                	sd	s0,112(sp)
    80005e18:	f4a6                	sd	s1,104(sp)
    80005e1a:	f0ca                	sd	s2,96(sp)
    80005e1c:	ecce                	sd	s3,88(sp)
    80005e1e:	e8d2                	sd	s4,80(sp)
    80005e20:	e4d6                	sd	s5,72(sp)
    80005e22:	e0da                	sd	s6,64(sp)
    80005e24:	fc5e                	sd	s7,56(sp)
    80005e26:	f862                	sd	s8,48(sp)
    80005e28:	f466                	sd	s9,40(sp)
    80005e2a:	f06a                	sd	s10,32(sp)
    80005e2c:	ec6e                	sd	s11,24(sp)
    80005e2e:	0100                	addi	s0,sp,128
    80005e30:	8aaa                	mv	s5,a0
    80005e32:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e34:	00c52c83          	lw	s9,12(a0)
    80005e38:	001c9c9b          	slliw	s9,s9,0x1
    80005e3c:	1c82                	slli	s9,s9,0x20
    80005e3e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e42:	0001f517          	auipc	a0,0x1f
    80005e46:	2e650513          	addi	a0,a0,742 # 80025128 <disk+0x2128>
    80005e4a:	ffffb097          	auipc	ra,0xffffb
    80005e4e:	d86080e7          	jalr	-634(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80005e52:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e54:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005e56:	0001dc17          	auipc	s8,0x1d
    80005e5a:	1aac0c13          	addi	s8,s8,426 # 80023000 <disk>
    80005e5e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005e60:	4b0d                	li	s6,3
    80005e62:	a0ad                	j	80005ecc <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005e64:	00fc0733          	add	a4,s8,a5
    80005e68:	975e                	add	a4,a4,s7
    80005e6a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005e6e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005e70:	0207c563          	bltz	a5,80005e9a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e74:	2905                	addiw	s2,s2,1
    80005e76:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005e78:	19690c63          	beq	s2,s6,80006010 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005e7c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005e7e:	0001f717          	auipc	a4,0x1f
    80005e82:	19a70713          	addi	a4,a4,410 # 80025018 <disk+0x2018>
    80005e86:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005e88:	00074683          	lbu	a3,0(a4)
    80005e8c:	fee1                	bnez	a3,80005e64 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005e8e:	2785                	addiw	a5,a5,1
    80005e90:	0705                	addi	a4,a4,1
    80005e92:	fe979be3          	bne	a5,s1,80005e88 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005e96:	57fd                	li	a5,-1
    80005e98:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005e9a:	01205d63          	blez	s2,80005eb4 <virtio_disk_rw+0xa2>
    80005e9e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005ea0:	000a2503          	lw	a0,0(s4)
    80005ea4:	00000097          	auipc	ra,0x0
    80005ea8:	d92080e7          	jalr	-622(ra) # 80005c36 <free_desc>
      for(int j = 0; j < i; j++)
    80005eac:	2d85                	addiw	s11,s11,1
    80005eae:	0a11                	addi	s4,s4,4
    80005eb0:	ff2d98e3          	bne	s11,s2,80005ea0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005eb4:	0001f597          	auipc	a1,0x1f
    80005eb8:	27458593          	addi	a1,a1,628 # 80025128 <disk+0x2128>
    80005ebc:	0001f517          	auipc	a0,0x1f
    80005ec0:	15c50513          	addi	a0,a0,348 # 80025018 <disk+0x2018>
    80005ec4:	ffffc097          	auipc	ra,0xffffc
    80005ec8:	196080e7          	jalr	406(ra) # 8000205a <sleep>
  for(int i = 0; i < 3; i++){
    80005ecc:	f8040a13          	addi	s4,s0,-128
{
    80005ed0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005ed2:	894e                	mv	s2,s3
    80005ed4:	b765                	j	80005e7c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005ed6:	0001f697          	auipc	a3,0x1f
    80005eda:	12a6b683          	ld	a3,298(a3) # 80025000 <disk+0x2000>
    80005ede:	96ba                	add	a3,a3,a4
    80005ee0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005ee4:	0001d817          	auipc	a6,0x1d
    80005ee8:	11c80813          	addi	a6,a6,284 # 80023000 <disk>
    80005eec:	0001f697          	auipc	a3,0x1f
    80005ef0:	11468693          	addi	a3,a3,276 # 80025000 <disk+0x2000>
    80005ef4:	6290                	ld	a2,0(a3)
    80005ef6:	963a                	add	a2,a2,a4
    80005ef8:	00c65583          	lhu	a1,12(a2)
    80005efc:	0015e593          	ori	a1,a1,1
    80005f00:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005f04:	f8842603          	lw	a2,-120(s0)
    80005f08:	628c                	ld	a1,0(a3)
    80005f0a:	972e                	add	a4,a4,a1
    80005f0c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005f10:	20050593          	addi	a1,a0,512
    80005f14:	0592                	slli	a1,a1,0x4
    80005f16:	95c2                	add	a1,a1,a6
    80005f18:	577d                	li	a4,-1
    80005f1a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005f1e:	00461713          	slli	a4,a2,0x4
    80005f22:	6290                	ld	a2,0(a3)
    80005f24:	963a                	add	a2,a2,a4
    80005f26:	03078793          	addi	a5,a5,48
    80005f2a:	97c2                	add	a5,a5,a6
    80005f2c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80005f2e:	629c                	ld	a5,0(a3)
    80005f30:	97ba                	add	a5,a5,a4
    80005f32:	4605                	li	a2,1
    80005f34:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005f36:	629c                	ld	a5,0(a3)
    80005f38:	97ba                	add	a5,a5,a4
    80005f3a:	4809                	li	a6,2
    80005f3c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005f40:	629c                	ld	a5,0(a3)
    80005f42:	97ba                	add	a5,a5,a4
    80005f44:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005f48:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80005f4c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005f50:	6698                	ld	a4,8(a3)
    80005f52:	00275783          	lhu	a5,2(a4)
    80005f56:	8b9d                	andi	a5,a5,7
    80005f58:	0786                	slli	a5,a5,0x1
    80005f5a:	973e                	add	a4,a4,a5
    80005f5c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80005f60:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005f64:	6698                	ld	a4,8(a3)
    80005f66:	00275783          	lhu	a5,2(a4)
    80005f6a:	2785                	addiw	a5,a5,1
    80005f6c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005f70:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005f74:	100017b7          	lui	a5,0x10001
    80005f78:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005f7c:	004aa783          	lw	a5,4(s5)
    80005f80:	02c79163          	bne	a5,a2,80005fa2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80005f84:	0001f917          	auipc	s2,0x1f
    80005f88:	1a490913          	addi	s2,s2,420 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80005f8c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005f8e:	85ca                	mv	a1,s2
    80005f90:	8556                	mv	a0,s5
    80005f92:	ffffc097          	auipc	ra,0xffffc
    80005f96:	0c8080e7          	jalr	200(ra) # 8000205a <sleep>
  while(b->disk == 1) {
    80005f9a:	004aa783          	lw	a5,4(s5)
    80005f9e:	fe9788e3          	beq	a5,s1,80005f8e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80005fa2:	f8042903          	lw	s2,-128(s0)
    80005fa6:	20090713          	addi	a4,s2,512
    80005faa:	0712                	slli	a4,a4,0x4
    80005fac:	0001d797          	auipc	a5,0x1d
    80005fb0:	05478793          	addi	a5,a5,84 # 80023000 <disk>
    80005fb4:	97ba                	add	a5,a5,a4
    80005fb6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80005fba:	0001f997          	auipc	s3,0x1f
    80005fbe:	04698993          	addi	s3,s3,70 # 80025000 <disk+0x2000>
    80005fc2:	00491713          	slli	a4,s2,0x4
    80005fc6:	0009b783          	ld	a5,0(s3)
    80005fca:	97ba                	add	a5,a5,a4
    80005fcc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005fd0:	854a                	mv	a0,s2
    80005fd2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005fd6:	00000097          	auipc	ra,0x0
    80005fda:	c60080e7          	jalr	-928(ra) # 80005c36 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005fde:	8885                	andi	s1,s1,1
    80005fe0:	f0ed                	bnez	s1,80005fc2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005fe2:	0001f517          	auipc	a0,0x1f
    80005fe6:	14650513          	addi	a0,a0,326 # 80025128 <disk+0x2128>
    80005fea:	ffffb097          	auipc	ra,0xffffb
    80005fee:	c9a080e7          	jalr	-870(ra) # 80000c84 <release>
}
    80005ff2:	70e6                	ld	ra,120(sp)
    80005ff4:	7446                	ld	s0,112(sp)
    80005ff6:	74a6                	ld	s1,104(sp)
    80005ff8:	7906                	ld	s2,96(sp)
    80005ffa:	69e6                	ld	s3,88(sp)
    80005ffc:	6a46                	ld	s4,80(sp)
    80005ffe:	6aa6                	ld	s5,72(sp)
    80006000:	6b06                	ld	s6,64(sp)
    80006002:	7be2                	ld	s7,56(sp)
    80006004:	7c42                	ld	s8,48(sp)
    80006006:	7ca2                	ld	s9,40(sp)
    80006008:	7d02                	ld	s10,32(sp)
    8000600a:	6de2                	ld	s11,24(sp)
    8000600c:	6109                	addi	sp,sp,128
    8000600e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006010:	f8042503          	lw	a0,-128(s0)
    80006014:	20050793          	addi	a5,a0,512
    80006018:	0792                	slli	a5,a5,0x4
  if(write)
    8000601a:	0001d817          	auipc	a6,0x1d
    8000601e:	fe680813          	addi	a6,a6,-26 # 80023000 <disk>
    80006022:	00f80733          	add	a4,a6,a5
    80006026:	01a036b3          	snez	a3,s10
    8000602a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000602e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006032:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006036:	7679                	lui	a2,0xffffe
    80006038:	963e                	add	a2,a2,a5
    8000603a:	0001f697          	auipc	a3,0x1f
    8000603e:	fc668693          	addi	a3,a3,-58 # 80025000 <disk+0x2000>
    80006042:	6298                	ld	a4,0(a3)
    80006044:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006046:	0a878593          	addi	a1,a5,168
    8000604a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000604c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000604e:	6298                	ld	a4,0(a3)
    80006050:	9732                	add	a4,a4,a2
    80006052:	45c1                	li	a1,16
    80006054:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006056:	6298                	ld	a4,0(a3)
    80006058:	9732                	add	a4,a4,a2
    8000605a:	4585                	li	a1,1
    8000605c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006060:	f8442703          	lw	a4,-124(s0)
    80006064:	628c                	ld	a1,0(a3)
    80006066:	962e                	add	a2,a2,a1
    80006068:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000606c:	0712                	slli	a4,a4,0x4
    8000606e:	6290                	ld	a2,0(a3)
    80006070:	963a                	add	a2,a2,a4
    80006072:	058a8593          	addi	a1,s5,88
    80006076:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006078:	6294                	ld	a3,0(a3)
    8000607a:	96ba                	add	a3,a3,a4
    8000607c:	40000613          	li	a2,1024
    80006080:	c690                	sw	a2,8(a3)
  if(write)
    80006082:	e40d1ae3          	bnez	s10,80005ed6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006086:	0001f697          	auipc	a3,0x1f
    8000608a:	f7a6b683          	ld	a3,-134(a3) # 80025000 <disk+0x2000>
    8000608e:	96ba                	add	a3,a3,a4
    80006090:	4609                	li	a2,2
    80006092:	00c69623          	sh	a2,12(a3)
    80006096:	b5b9                	j	80005ee4 <virtio_disk_rw+0xd2>

0000000080006098 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006098:	1101                	addi	sp,sp,-32
    8000609a:	ec06                	sd	ra,24(sp)
    8000609c:	e822                	sd	s0,16(sp)
    8000609e:	e426                	sd	s1,8(sp)
    800060a0:	e04a                	sd	s2,0(sp)
    800060a2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800060a4:	0001f517          	auipc	a0,0x1f
    800060a8:	08450513          	addi	a0,a0,132 # 80025128 <disk+0x2128>
    800060ac:	ffffb097          	auipc	ra,0xffffb
    800060b0:	b24080e7          	jalr	-1244(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800060b4:	10001737          	lui	a4,0x10001
    800060b8:	533c                	lw	a5,96(a4)
    800060ba:	8b8d                	andi	a5,a5,3
    800060bc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800060be:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800060c2:	0001f797          	auipc	a5,0x1f
    800060c6:	f3e78793          	addi	a5,a5,-194 # 80025000 <disk+0x2000>
    800060ca:	6b94                	ld	a3,16(a5)
    800060cc:	0207d703          	lhu	a4,32(a5)
    800060d0:	0026d783          	lhu	a5,2(a3)
    800060d4:	06f70163          	beq	a4,a5,80006136 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060d8:	0001d917          	auipc	s2,0x1d
    800060dc:	f2890913          	addi	s2,s2,-216 # 80023000 <disk>
    800060e0:	0001f497          	auipc	s1,0x1f
    800060e4:	f2048493          	addi	s1,s1,-224 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800060e8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060ec:	6898                	ld	a4,16(s1)
    800060ee:	0204d783          	lhu	a5,32(s1)
    800060f2:	8b9d                	andi	a5,a5,7
    800060f4:	078e                	slli	a5,a5,0x3
    800060f6:	97ba                	add	a5,a5,a4
    800060f8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800060fa:	20078713          	addi	a4,a5,512
    800060fe:	0712                	slli	a4,a4,0x4
    80006100:	974a                	add	a4,a4,s2
    80006102:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006106:	e731                	bnez	a4,80006152 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006108:	20078793          	addi	a5,a5,512
    8000610c:	0792                	slli	a5,a5,0x4
    8000610e:	97ca                	add	a5,a5,s2
    80006110:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006112:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006116:	ffffc097          	auipc	ra,0xffffc
    8000611a:	0d0080e7          	jalr	208(ra) # 800021e6 <wakeup>

    disk.used_idx += 1;
    8000611e:	0204d783          	lhu	a5,32(s1)
    80006122:	2785                	addiw	a5,a5,1
    80006124:	17c2                	slli	a5,a5,0x30
    80006126:	93c1                	srli	a5,a5,0x30
    80006128:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000612c:	6898                	ld	a4,16(s1)
    8000612e:	00275703          	lhu	a4,2(a4)
    80006132:	faf71be3          	bne	a4,a5,800060e8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006136:	0001f517          	auipc	a0,0x1f
    8000613a:	ff250513          	addi	a0,a0,-14 # 80025128 <disk+0x2128>
    8000613e:	ffffb097          	auipc	ra,0xffffb
    80006142:	b46080e7          	jalr	-1210(ra) # 80000c84 <release>
}
    80006146:	60e2                	ld	ra,24(sp)
    80006148:	6442                	ld	s0,16(sp)
    8000614a:	64a2                	ld	s1,8(sp)
    8000614c:	6902                	ld	s2,0(sp)
    8000614e:	6105                	addi	sp,sp,32
    80006150:	8082                	ret
      panic("virtio_disk_intr status");
    80006152:	00002517          	auipc	a0,0x2
    80006156:	6b650513          	addi	a0,a0,1718 # 80008808 <syscalls+0x3c0>
    8000615a:	ffffa097          	auipc	ra,0xffffa
    8000615e:	3e0080e7          	jalr	992(ra) # 8000053a <panic>
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
