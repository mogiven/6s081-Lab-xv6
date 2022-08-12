
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	29c78793          	addi	a5,a5,668 # 80006300 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd07ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dd678793          	addi	a5,a5,-554 # 80000e84 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	58e080e7          	jalr	1422(ra) # 800026ac <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	78e080e7          	jalr	1934(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7119                	addi	sp,sp,-128
    80000158:	fc86                	sd	ra,120(sp)
    8000015a:	f8a2                	sd	s0,112(sp)
    8000015c:	f4a6                	sd	s1,104(sp)
    8000015e:	f0ca                	sd	s2,96(sp)
    80000160:	ecce                	sd	s3,88(sp)
    80000162:	e8d2                	sd	s4,80(sp)
    80000164:	e4d6                	sd	s5,72(sp)
    80000166:	e0da                	sd	s6,64(sp)
    80000168:	fc5e                	sd	s7,56(sp)
    8000016a:	f862                	sd	s8,48(sp)
    8000016c:	f466                	sd	s9,40(sp)
    8000016e:	f06a                	sd	s10,32(sp)
    80000170:	ec6e                	sd	s11,24(sp)
    80000172:	0100                	addi	s0,sp,128
    80000174:	8b2a                	mv	s6,a0
    80000176:	8aae                	mv	s5,a1
    80000178:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000017e:	00011517          	auipc	a0,0x11
    80000182:	00250513          	addi	a0,a0,2 # 80011180 <cons>
    80000186:	00001097          	auipc	ra,0x1
    8000018a:	a50080e7          	jalr	-1456(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018e:	00011497          	auipc	s1,0x11
    80000192:	ff248493          	addi	s1,s1,-14 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000196:	89a6                	mv	s3,s1
    80000198:	00011917          	auipc	s2,0x11
    8000019c:	08090913          	addi	s2,s2,128 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001a0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001a2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a4:	4da9                	li	s11,10
  while(n > 0){
    800001a6:	07405863          	blez	s4,80000216 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001aa:	0984a783          	lw	a5,152(s1)
    800001ae:	09c4a703          	lw	a4,156(s1)
    800001b2:	02f71463          	bne	a4,a5,800001da <consoleread+0x84>
      if(myproc()->killed){
    800001b6:	00002097          	auipc	ra,0x2
    800001ba:	83e080e7          	jalr	-1986(ra) # 800019f4 <myproc>
    800001be:	591c                	lw	a5,48(a0)
    800001c0:	e7b5                	bnez	a5,8000022c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001c2:	85ce                	mv	a1,s3
    800001c4:	854a                	mv	a0,s2
    800001c6:	00002097          	auipc	ra,0x2
    800001ca:	22e080e7          	jalr	558(ra) # 800023f4 <sleep>
    while(cons.r == cons.w){
    800001ce:	0984a783          	lw	a5,152(s1)
    800001d2:	09c4a703          	lw	a4,156(s1)
    800001d6:	fef700e3          	beq	a4,a5,800001b6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001da:	0017871b          	addiw	a4,a5,1
    800001de:	08e4ac23          	sw	a4,152(s1)
    800001e2:	07f7f713          	andi	a4,a5,127
    800001e6:	9726                	add	a4,a4,s1
    800001e8:	01874703          	lbu	a4,24(a4)
    800001ec:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001f0:	079c0663          	beq	s8,s9,8000025c <consoleread+0x106>
    cbuf = c;
    800001f4:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f8:	4685                	li	a3,1
    800001fa:	f8f40613          	addi	a2,s0,-113
    800001fe:	85d6                	mv	a1,s5
    80000200:	855a                	mv	a0,s6
    80000202:	00002097          	auipc	ra,0x2
    80000206:	454080e7          	jalr	1108(ra) # 80002656 <either_copyout>
    8000020a:	01a50663          	beq	a0,s10,80000216 <consoleread+0xc0>
    dst++;
    8000020e:	0a85                	addi	s5,s5,1
    --n;
    80000210:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000212:	f9bc1ae3          	bne	s8,s11,800001a6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000216:	00011517          	auipc	a0,0x11
    8000021a:	f6a50513          	addi	a0,a0,-150 # 80011180 <cons>
    8000021e:	00001097          	auipc	ra,0x1
    80000222:	a6c080e7          	jalr	-1428(ra) # 80000c8a <release>

  return target - n;
    80000226:	414b853b          	subw	a0,s7,s4
    8000022a:	a811                	j	8000023e <consoleread+0xe8>
        release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	f5450513          	addi	a0,a0,-172 # 80011180 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	a56080e7          	jalr	-1450(ra) # 80000c8a <release>
        return -1;
    8000023c:	557d                	li	a0,-1
}
    8000023e:	70e6                	ld	ra,120(sp)
    80000240:	7446                	ld	s0,112(sp)
    80000242:	74a6                	ld	s1,104(sp)
    80000244:	7906                	ld	s2,96(sp)
    80000246:	69e6                	ld	s3,88(sp)
    80000248:	6a46                	ld	s4,80(sp)
    8000024a:	6aa6                	ld	s5,72(sp)
    8000024c:	6b06                	ld	s6,64(sp)
    8000024e:	7be2                	ld	s7,56(sp)
    80000250:	7c42                	ld	s8,48(sp)
    80000252:	7ca2                	ld	s9,40(sp)
    80000254:	7d02                	ld	s10,32(sp)
    80000256:	6de2                	ld	s11,24(sp)
    80000258:	6109                	addi	sp,sp,128
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	000a071b          	sext.w	a4,s4
    80000260:	fb777be3          	bgeu	a4,s7,80000216 <consoleread+0xc0>
        cons.r--;
    80000264:	00011717          	auipc	a4,0x11
    80000268:	faf72a23          	sw	a5,-76(a4) # 80011218 <cons+0x98>
    8000026c:	b76d                	j	80000216 <consoleread+0xc0>

000000008000026e <consputc>:
{
    8000026e:	1141                	addi	sp,sp,-16
    80000270:	e406                	sd	ra,8(sp)
    80000272:	e022                	sd	s0,0(sp)
    80000274:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000276:	10000793          	li	a5,256
    8000027a:	00f50a63          	beq	a0,a5,8000028e <consputc+0x20>
    uartputc_sync(c);
    8000027e:	00000097          	auipc	ra,0x0
    80000282:	564080e7          	jalr	1380(ra) # 800007e2 <uartputc_sync>
}
    80000286:	60a2                	ld	ra,8(sp)
    80000288:	6402                	ld	s0,0(sp)
    8000028a:	0141                	addi	sp,sp,16
    8000028c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000028e:	4521                	li	a0,8
    80000290:	00000097          	auipc	ra,0x0
    80000294:	552080e7          	jalr	1362(ra) # 800007e2 <uartputc_sync>
    80000298:	02000513          	li	a0,32
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	546080e7          	jalr	1350(ra) # 800007e2 <uartputc_sync>
    800002a4:	4521                	li	a0,8
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	53c080e7          	jalr	1340(ra) # 800007e2 <uartputc_sync>
    800002ae:	bfe1                	j	80000286 <consputc+0x18>

00000000800002b0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b0:	1101                	addi	sp,sp,-32
    800002b2:	ec06                	sd	ra,24(sp)
    800002b4:	e822                	sd	s0,16(sp)
    800002b6:	e426                	sd	s1,8(sp)
    800002b8:	e04a                	sd	s2,0(sp)
    800002ba:	1000                	addi	s0,sp,32
    800002bc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002be:	00011517          	auipc	a0,0x11
    800002c2:	ec250513          	addi	a0,a0,-318 # 80011180 <cons>
    800002c6:	00001097          	auipc	ra,0x1
    800002ca:	910080e7          	jalr	-1776(ra) # 80000bd6 <acquire>

  switch(c){
    800002ce:	47d5                	li	a5,21
    800002d0:	0af48663          	beq	s1,a5,8000037c <consoleintr+0xcc>
    800002d4:	0297ca63          	blt	a5,s1,80000308 <consoleintr+0x58>
    800002d8:	47a1                	li	a5,8
    800002da:	0ef48763          	beq	s1,a5,800003c8 <consoleintr+0x118>
    800002de:	47c1                	li	a5,16
    800002e0:	10f49a63          	bne	s1,a5,800003f4 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002e4:	00002097          	auipc	ra,0x2
    800002e8:	41e080e7          	jalr	1054(ra) # 80002702 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ec:	00011517          	auipc	a0,0x11
    800002f0:	e9450513          	addi	a0,a0,-364 # 80011180 <cons>
    800002f4:	00001097          	auipc	ra,0x1
    800002f8:	996080e7          	jalr	-1642(ra) # 80000c8a <release>
}
    800002fc:	60e2                	ld	ra,24(sp)
    800002fe:	6442                	ld	s0,16(sp)
    80000300:	64a2                	ld	s1,8(sp)
    80000302:	6902                	ld	s2,0(sp)
    80000304:	6105                	addi	sp,sp,32
    80000306:	8082                	ret
  switch(c){
    80000308:	07f00793          	li	a5,127
    8000030c:	0af48e63          	beq	s1,a5,800003c8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000310:	00011717          	auipc	a4,0x11
    80000314:	e7070713          	addi	a4,a4,-400 # 80011180 <cons>
    80000318:	0a072783          	lw	a5,160(a4)
    8000031c:	09872703          	lw	a4,152(a4)
    80000320:	9f99                	subw	a5,a5,a4
    80000322:	07f00713          	li	a4,127
    80000326:	fcf763e3          	bltu	a4,a5,800002ec <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000032a:	47b5                	li	a5,13
    8000032c:	0cf48763          	beq	s1,a5,800003fa <consoleintr+0x14a>
      consputc(c);
    80000330:	8526                	mv	a0,s1
    80000332:	00000097          	auipc	ra,0x0
    80000336:	f3c080e7          	jalr	-196(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000033a:	00011797          	auipc	a5,0x11
    8000033e:	e4678793          	addi	a5,a5,-442 # 80011180 <cons>
    80000342:	0a07a703          	lw	a4,160(a5)
    80000346:	0017069b          	addiw	a3,a4,1
    8000034a:	0006861b          	sext.w	a2,a3
    8000034e:	0ad7a023          	sw	a3,160(a5)
    80000352:	07f77713          	andi	a4,a4,127
    80000356:	97ba                	add	a5,a5,a4
    80000358:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000035c:	47a9                	li	a5,10
    8000035e:	0cf48563          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000362:	4791                	li	a5,4
    80000364:	0cf48263          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000368:	00011797          	auipc	a5,0x11
    8000036c:	eb07a783          	lw	a5,-336(a5) # 80011218 <cons+0x98>
    80000370:	0807879b          	addiw	a5,a5,128
    80000374:	f6f61ce3          	bne	a2,a5,800002ec <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000378:	863e                	mv	a2,a5
    8000037a:	a07d                	j	80000428 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000037c:	00011717          	auipc	a4,0x11
    80000380:	e0470713          	addi	a4,a4,-508 # 80011180 <cons>
    80000384:	0a072783          	lw	a5,160(a4)
    80000388:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000038c:	00011497          	auipc	s1,0x11
    80000390:	df448493          	addi	s1,s1,-524 # 80011180 <cons>
    while(cons.e != cons.w &&
    80000394:	4929                	li	s2,10
    80000396:	f4f70be3          	beq	a4,a5,800002ec <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	37fd                	addiw	a5,a5,-1
    8000039c:	07f7f713          	andi	a4,a5,127
    800003a0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003a2:	01874703          	lbu	a4,24(a4)
    800003a6:	f52703e3          	beq	a4,s2,800002ec <consoleintr+0x3c>
      cons.e--;
    800003aa:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ae:	10000513          	li	a0,256
    800003b2:	00000097          	auipc	ra,0x0
    800003b6:	ebc080e7          	jalr	-324(ra) # 8000026e <consputc>
    while(cons.e != cons.w &&
    800003ba:	0a04a783          	lw	a5,160(s1)
    800003be:	09c4a703          	lw	a4,156(s1)
    800003c2:	fcf71ce3          	bne	a4,a5,8000039a <consoleintr+0xea>
    800003c6:	b71d                	j	800002ec <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c8:	00011717          	auipc	a4,0x11
    800003cc:	db870713          	addi	a4,a4,-584 # 80011180 <cons>
    800003d0:	0a072783          	lw	a5,160(a4)
    800003d4:	09c72703          	lw	a4,156(a4)
    800003d8:	f0f70ae3          	beq	a4,a5,800002ec <consoleintr+0x3c>
      cons.e--;
    800003dc:	37fd                	addiw	a5,a5,-1
    800003de:	00011717          	auipc	a4,0x11
    800003e2:	e4f72123          	sw	a5,-446(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e6:	10000513          	li	a0,256
    800003ea:	00000097          	auipc	ra,0x0
    800003ee:	e84080e7          	jalr	-380(ra) # 8000026e <consputc>
    800003f2:	bded                	j	800002ec <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003f4:	ee048ce3          	beqz	s1,800002ec <consoleintr+0x3c>
    800003f8:	bf21                	j	80000310 <consoleintr+0x60>
      consputc(c);
    800003fa:	4529                	li	a0,10
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e72080e7          	jalr	-398(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000404:	00011797          	auipc	a5,0x11
    80000408:	d7c78793          	addi	a5,a5,-644 # 80011180 <cons>
    8000040c:	0a07a703          	lw	a4,160(a5)
    80000410:	0017069b          	addiw	a3,a4,1
    80000414:	0006861b          	sext.w	a2,a3
    80000418:	0ad7a023          	sw	a3,160(a5)
    8000041c:	07f77713          	andi	a4,a4,127
    80000420:	97ba                	add	a5,a5,a4
    80000422:	4729                	li	a4,10
    80000424:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000428:	00011797          	auipc	a5,0x11
    8000042c:	dec7aa23          	sw	a2,-524(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000430:	00011517          	auipc	a0,0x11
    80000434:	de850513          	addi	a0,a0,-536 # 80011218 <cons+0x98>
    80000438:	00002097          	auipc	ra,0x2
    8000043c:	142080e7          	jalr	322(ra) # 8000257a <wakeup>
    80000440:	b575                	j	800002ec <consoleintr+0x3c>

0000000080000442 <consoleinit>:

void
consoleinit(void)
{
    80000442:	1141                	addi	sp,sp,-16
    80000444:	e406                	sd	ra,8(sp)
    80000446:	e022                	sd	s0,0(sp)
    80000448:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000044a:	00008597          	auipc	a1,0x8
    8000044e:	bc658593          	addi	a1,a1,-1082 # 80008010 <etext+0x10>
    80000452:	00011517          	auipc	a0,0x11
    80000456:	d2e50513          	addi	a0,a0,-722 # 80011180 <cons>
    8000045a:	00000097          	auipc	ra,0x0
    8000045e:	6ec080e7          	jalr	1772(ra) # 80000b46 <initlock>

  uartinit();
    80000462:	00000097          	auipc	ra,0x0
    80000466:	330080e7          	jalr	816(ra) # 80000792 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000046a:	00029797          	auipc	a5,0x29
    8000046e:	e9678793          	addi	a5,a5,-362 # 80029300 <devsw>
    80000472:	00000717          	auipc	a4,0x0
    80000476:	ce470713          	addi	a4,a4,-796 # 80000156 <consoleread>
    8000047a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	c7870713          	addi	a4,a4,-904 # 800000f4 <consolewrite>
    80000484:	ef98                	sd	a4,24(a5)
}
    80000486:	60a2                	ld	ra,8(sp)
    80000488:	6402                	ld	s0,0(sp)
    8000048a:	0141                	addi	sp,sp,16
    8000048c:	8082                	ret

000000008000048e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000048e:	7179                	addi	sp,sp,-48
    80000490:	f406                	sd	ra,40(sp)
    80000492:	f022                	sd	s0,32(sp)
    80000494:	ec26                	sd	s1,24(sp)
    80000496:	e84a                	sd	s2,16(sp)
    80000498:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000049a:	c219                	beqz	a2,800004a0 <printint+0x12>
    8000049c:	08054663          	bltz	a0,80000528 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a0:	2501                	sext.w	a0,a0
    800004a2:	4881                	li	a7,0
    800004a4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004aa:	2581                	sext.w	a1,a1
    800004ac:	00008617          	auipc	a2,0x8
    800004b0:	b9460613          	addi	a2,a2,-1132 # 80008040 <digits>
    800004b4:	883a                	mv	a6,a4
    800004b6:	2705                	addiw	a4,a4,1
    800004b8:	02b577bb          	remuw	a5,a0,a1
    800004bc:	1782                	slli	a5,a5,0x20
    800004be:	9381                	srli	a5,a5,0x20
    800004c0:	97b2                	add	a5,a5,a2
    800004c2:	0007c783          	lbu	a5,0(a5)
    800004c6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ca:	0005079b          	sext.w	a5,a0
    800004ce:	02b5553b          	divuw	a0,a0,a1
    800004d2:	0685                	addi	a3,a3,1
    800004d4:	feb7f0e3          	bgeu	a5,a1,800004b4 <printint+0x26>

  if(sign)
    800004d8:	00088b63          	beqz	a7,800004ee <printint+0x60>
    buf[i++] = '-';
    800004dc:	fe040793          	addi	a5,s0,-32
    800004e0:	973e                	add	a4,a4,a5
    800004e2:	02d00793          	li	a5,45
    800004e6:	fef70823          	sb	a5,-16(a4)
    800004ea:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004ee:	02e05763          	blez	a4,8000051c <printint+0x8e>
    800004f2:	fd040793          	addi	a5,s0,-48
    800004f6:	00e784b3          	add	s1,a5,a4
    800004fa:	fff78913          	addi	s2,a5,-1
    800004fe:	993a                	add	s2,s2,a4
    80000500:	377d                	addiw	a4,a4,-1
    80000502:	1702                	slli	a4,a4,0x20
    80000504:	9301                	srli	a4,a4,0x20
    80000506:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000050a:	fff4c503          	lbu	a0,-1(s1)
    8000050e:	00000097          	auipc	ra,0x0
    80000512:	d60080e7          	jalr	-672(ra) # 8000026e <consputc>
  while(--i >= 0)
    80000516:	14fd                	addi	s1,s1,-1
    80000518:	ff2499e3          	bne	s1,s2,8000050a <printint+0x7c>
}
    8000051c:	70a2                	ld	ra,40(sp)
    8000051e:	7402                	ld	s0,32(sp)
    80000520:	64e2                	ld	s1,24(sp)
    80000522:	6942                	ld	s2,16(sp)
    80000524:	6145                	addi	sp,sp,48
    80000526:	8082                	ret
    x = -xx;
    80000528:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000052c:	4885                	li	a7,1
    x = -xx;
    8000052e:	bf9d                	j	800004a4 <printint+0x16>

0000000080000530 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000530:	1101                	addi	sp,sp,-32
    80000532:	ec06                	sd	ra,24(sp)
    80000534:	e822                	sd	s0,16(sp)
    80000536:	e426                	sd	s1,8(sp)
    80000538:	1000                	addi	s0,sp,32
    8000053a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000053c:	00011797          	auipc	a5,0x11
    80000540:	d007a223          	sw	zero,-764(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000544:	00008517          	auipc	a0,0x8
    80000548:	ad450513          	addi	a0,a0,-1324 # 80008018 <etext+0x18>
    8000054c:	00000097          	auipc	ra,0x0
    80000550:	02e080e7          	jalr	46(ra) # 8000057a <printf>
  printf(s);
    80000554:	8526                	mv	a0,s1
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	024080e7          	jalr	36(ra) # 8000057a <printf>
  printf("\n");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	b6a50513          	addi	a0,a0,-1174 # 800080c8 <digits+0x88>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	014080e7          	jalr	20(ra) # 8000057a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000056e:	4785                	li	a5,1
    80000570:	00009717          	auipc	a4,0x9
    80000574:	a8f72823          	sw	a5,-1392(a4) # 80009000 <panicked>
  for(;;)
    80000578:	a001                	j	80000578 <panic+0x48>

000000008000057a <printf>:
{
    8000057a:	7131                	addi	sp,sp,-192
    8000057c:	fc86                	sd	ra,120(sp)
    8000057e:	f8a2                	sd	s0,112(sp)
    80000580:	f4a6                	sd	s1,104(sp)
    80000582:	f0ca                	sd	s2,96(sp)
    80000584:	ecce                	sd	s3,88(sp)
    80000586:	e8d2                	sd	s4,80(sp)
    80000588:	e4d6                	sd	s5,72(sp)
    8000058a:	e0da                	sd	s6,64(sp)
    8000058c:	fc5e                	sd	s7,56(sp)
    8000058e:	f862                	sd	s8,48(sp)
    80000590:	f466                	sd	s9,40(sp)
    80000592:	f06a                	sd	s10,32(sp)
    80000594:	ec6e                	sd	s11,24(sp)
    80000596:	0100                	addi	s0,sp,128
    80000598:	8a2a                	mv	s4,a0
    8000059a:	e40c                	sd	a1,8(s0)
    8000059c:	e810                	sd	a2,16(s0)
    8000059e:	ec14                	sd	a3,24(s0)
    800005a0:	f018                	sd	a4,32(s0)
    800005a2:	f41c                	sd	a5,40(s0)
    800005a4:	03043823          	sd	a6,48(s0)
    800005a8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ac:	00011d97          	auipc	s11,0x11
    800005b0:	c94dad83          	lw	s11,-876(s11) # 80011240 <pr+0x18>
  if(locking)
    800005b4:	020d9b63          	bnez	s11,800005ea <printf+0x70>
  if (fmt == 0)
    800005b8:	040a0263          	beqz	s4,800005fc <printf+0x82>
  va_start(ap, fmt);
    800005bc:	00840793          	addi	a5,s0,8
    800005c0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c4:	000a4503          	lbu	a0,0(s4)
    800005c8:	16050263          	beqz	a0,8000072c <printf+0x1b2>
    800005cc:	4481                	li	s1,0
    if(c != '%'){
    800005ce:	02500a93          	li	s5,37
    switch(c){
    800005d2:	07000b13          	li	s6,112
  consputc('x');
    800005d6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008b97          	auipc	s7,0x8
    800005dc:	a68b8b93          	addi	s7,s7,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	06400c13          	li	s8,100
    800005e8:	a82d                	j	80000622 <printf+0xa8>
    acquire(&pr.lock);
    800005ea:	00011517          	auipc	a0,0x11
    800005ee:	c3e50513          	addi	a0,a0,-962 # 80011228 <pr>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
    800005fa:	bf7d                	j	800005b8 <printf+0x3e>
    panic("null fmt");
    800005fc:	00008517          	auipc	a0,0x8
    80000600:	a2c50513          	addi	a0,a0,-1492 # 80008028 <etext+0x28>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	f2c080e7          	jalr	-212(ra) # 80000530 <panic>
      consputc(c);
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	c62080e7          	jalr	-926(ra) # 8000026e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000614:	2485                	addiw	s1,s1,1
    80000616:	009a07b3          	add	a5,s4,s1
    8000061a:	0007c503          	lbu	a0,0(a5)
    8000061e:	10050763          	beqz	a0,8000072c <printf+0x1b2>
    if(c != '%'){
    80000622:	ff5515e3          	bne	a0,s5,8000060c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000626:	2485                	addiw	s1,s1,1
    80000628:	009a07b3          	add	a5,s4,s1
    8000062c:	0007c783          	lbu	a5,0(a5)
    80000630:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000634:	cfe5                	beqz	a5,8000072c <printf+0x1b2>
    switch(c){
    80000636:	05678a63          	beq	a5,s6,8000068a <printf+0x110>
    8000063a:	02fb7663          	bgeu	s6,a5,80000666 <printf+0xec>
    8000063e:	09978963          	beq	a5,s9,800006d0 <printf+0x156>
    80000642:	07800713          	li	a4,120
    80000646:	0ce79863          	bne	a5,a4,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000064a:	f8843783          	ld	a5,-120(s0)
    8000064e:	00878713          	addi	a4,a5,8
    80000652:	f8e43423          	sd	a4,-120(s0)
    80000656:	4605                	li	a2,1
    80000658:	85ea                	mv	a1,s10
    8000065a:	4388                	lw	a0,0(a5)
    8000065c:	00000097          	auipc	ra,0x0
    80000660:	e32080e7          	jalr	-462(ra) # 8000048e <printint>
      break;
    80000664:	bf45                	j	80000614 <printf+0x9a>
    switch(c){
    80000666:	0b578263          	beq	a5,s5,8000070a <printf+0x190>
    8000066a:	0b879663          	bne	a5,s8,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000066e:	f8843783          	ld	a5,-120(s0)
    80000672:	00878713          	addi	a4,a5,8
    80000676:	f8e43423          	sd	a4,-120(s0)
    8000067a:	4605                	li	a2,1
    8000067c:	45a9                	li	a1,10
    8000067e:	4388                	lw	a0,0(a5)
    80000680:	00000097          	auipc	ra,0x0
    80000684:	e0e080e7          	jalr	-498(ra) # 8000048e <printint>
      break;
    80000688:	b771                	j	80000614 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000068a:	f8843783          	ld	a5,-120(s0)
    8000068e:	00878713          	addi	a4,a5,8
    80000692:	f8e43423          	sd	a4,-120(s0)
    80000696:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000069a:	03000513          	li	a0,48
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	bd0080e7          	jalr	-1072(ra) # 8000026e <consputc>
  consputc('x');
    800006a6:	07800513          	li	a0,120
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bc4080e7          	jalr	-1084(ra) # 8000026e <consputc>
    800006b2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006b4:	03c9d793          	srli	a5,s3,0x3c
    800006b8:	97de                	add	a5,a5,s7
    800006ba:	0007c503          	lbu	a0,0(a5)
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bb0080e7          	jalr	-1104(ra) # 8000026e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c6:	0992                	slli	s3,s3,0x4
    800006c8:	397d                	addiw	s2,s2,-1
    800006ca:	fe0915e3          	bnez	s2,800006b4 <printf+0x13a>
    800006ce:	b799                	j	80000614 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d0:	f8843783          	ld	a5,-120(s0)
    800006d4:	00878713          	addi	a4,a5,8
    800006d8:	f8e43423          	sd	a4,-120(s0)
    800006dc:	0007b903          	ld	s2,0(a5)
    800006e0:	00090e63          	beqz	s2,800006fc <printf+0x182>
      for(; *s; s++)
    800006e4:	00094503          	lbu	a0,0(s2)
    800006e8:	d515                	beqz	a0,80000614 <printf+0x9a>
        consputc(*s);
    800006ea:	00000097          	auipc	ra,0x0
    800006ee:	b84080e7          	jalr	-1148(ra) # 8000026e <consputc>
      for(; *s; s++)
    800006f2:	0905                	addi	s2,s2,1
    800006f4:	00094503          	lbu	a0,0(s2)
    800006f8:	f96d                	bnez	a0,800006ea <printf+0x170>
    800006fa:	bf29                	j	80000614 <printf+0x9a>
        s = "(null)";
    800006fc:	00008917          	auipc	s2,0x8
    80000700:	92490913          	addi	s2,s2,-1756 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000704:	02800513          	li	a0,40
    80000708:	b7cd                	j	800006ea <printf+0x170>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b62080e7          	jalr	-1182(ra) # 8000026e <consputc>
      break;
    80000714:	b701                	j	80000614 <printf+0x9a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b56080e7          	jalr	-1194(ra) # 8000026e <consputc>
      consputc(c);
    80000720:	854a                	mv	a0,s2
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b4c080e7          	jalr	-1204(ra) # 8000026e <consputc>
      break;
    8000072a:	b5ed                	j	80000614 <printf+0x9a>
  if(locking)
    8000072c:	020d9163          	bnez	s11,8000074e <printf+0x1d4>
}
    80000730:	70e6                	ld	ra,120(sp)
    80000732:	7446                	ld	s0,112(sp)
    80000734:	74a6                	ld	s1,104(sp)
    80000736:	7906                	ld	s2,96(sp)
    80000738:	69e6                	ld	s3,88(sp)
    8000073a:	6a46                	ld	s4,80(sp)
    8000073c:	6aa6                	ld	s5,72(sp)
    8000073e:	6b06                	ld	s6,64(sp)
    80000740:	7be2                	ld	s7,56(sp)
    80000742:	7c42                	ld	s8,48(sp)
    80000744:	7ca2                	ld	s9,40(sp)
    80000746:	7d02                	ld	s10,32(sp)
    80000748:	6de2                	ld	s11,24(sp)
    8000074a:	6129                	addi	sp,sp,192
    8000074c:	8082                	ret
    release(&pr.lock);
    8000074e:	00011517          	auipc	a0,0x11
    80000752:	ada50513          	addi	a0,a0,-1318 # 80011228 <pr>
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	534080e7          	jalr	1332(ra) # 80000c8a <release>
}
    8000075e:	bfc9                	j	80000730 <printf+0x1b6>

0000000080000760 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000760:	1101                	addi	sp,sp,-32
    80000762:	ec06                	sd	ra,24(sp)
    80000764:	e822                	sd	s0,16(sp)
    80000766:	e426                	sd	s1,8(sp)
    80000768:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076a:	00011497          	auipc	s1,0x11
    8000076e:	abe48493          	addi	s1,s1,-1346 # 80011228 <pr>
    80000772:	00008597          	auipc	a1,0x8
    80000776:	8c658593          	addi	a1,a1,-1850 # 80008038 <etext+0x38>
    8000077a:	8526                	mv	a0,s1
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	3ca080e7          	jalr	970(ra) # 80000b46 <initlock>
  pr.locking = 1;
    80000784:	4785                	li	a5,1
    80000786:	cc9c                	sw	a5,24(s1)
}
    80000788:	60e2                	ld	ra,24(sp)
    8000078a:	6442                	ld	s0,16(sp)
    8000078c:	64a2                	ld	s1,8(sp)
    8000078e:	6105                	addi	sp,sp,32
    80000790:	8082                	ret

0000000080000792 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000792:	1141                	addi	sp,sp,-16
    80000794:	e406                	sd	ra,8(sp)
    80000796:	e022                	sd	s0,0(sp)
    80000798:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079a:	100007b7          	lui	a5,0x10000
    8000079e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a2:	f8000713          	li	a4,-128
    800007a6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007aa:	470d                	li	a4,3
    800007ac:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007b8:	469d                	li	a3,7
    800007ba:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007be:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c2:	00008597          	auipc	a1,0x8
    800007c6:	89658593          	addi	a1,a1,-1898 # 80008058 <digits+0x18>
    800007ca:	00011517          	auipc	a0,0x11
    800007ce:	a7e50513          	addi	a0,a0,-1410 # 80011248 <uart_tx_lock>
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	374080e7          	jalr	884(ra) # 80000b46 <initlock>
}
    800007da:	60a2                	ld	ra,8(sp)
    800007dc:	6402                	ld	s0,0(sp)
    800007de:	0141                	addi	sp,sp,16
    800007e0:	8082                	ret

00000000800007e2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e2:	1101                	addi	sp,sp,-32
    800007e4:	ec06                	sd	ra,24(sp)
    800007e6:	e822                	sd	s0,16(sp)
    800007e8:	e426                	sd	s1,8(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  push_off();
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	39c080e7          	jalr	924(ra) # 80000b8a <push_off>

  if(panicked){
    800007f6:	00009797          	auipc	a5,0x9
    800007fa:	80a7a783          	lw	a5,-2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fe:	10000737          	lui	a4,0x10000
  if(panicked){
    80000802:	c391                	beqz	a5,80000806 <uartputc_sync+0x24>
    for(;;)
    80000804:	a001                	j	80000804 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080a:	0ff7f793          	andi	a5,a5,255
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dbf5                	beqz	a5,80000806 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f793          	andi	a5,s1,255
    80000818:	10000737          	lui	a4,0x10000
    8000081c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	40a080e7          	jalr	1034(ra) # 80000c2a <pop_off>
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
    80000832:	00008717          	auipc	a4,0x8
    80000836:	7d673703          	ld	a4,2006(a4) # 80009008 <uart_tx_r>
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7d67b783          	ld	a5,2006(a5) # 80009010 <uart_tx_w>
    80000842:	06e78c63          	beq	a5,a4,800008ba <uartstart+0x88>
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
    80000874:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	0ff7f793          	andi	a5,a5,255
    8000087c:	0207f793          	andi	a5,a5,32
    80000880:	c785                	beqz	a5,800008a8 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f77793          	andi	a5,a4,31
    80000886:	97d2                	add	a5,a5,s4
    80000888:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000088c:	0705                	addi	a4,a4,1
    8000088e:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	ce8080e7          	jalr	-792(ra) # 8000257a <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	6098                	ld	a4,0(s1)
    800008a0:	0009b783          	ld	a5,0(s3)
    800008a4:	fce798e3          	bne	a5,a4,80000874 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	97a50513          	addi	a0,a0,-1670 # 80011248 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	7227a783          	lw	a5,1826(a5) # 80009000 <panicked>
    800008e6:	c391                	beqz	a5,800008ea <uartputc+0x2e>
    for(;;)
    800008e8:	a001                	j	800008e8 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008797          	auipc	a5,0x8
    800008ee:	7267b783          	ld	a5,1830(a5) # 80009010 <uart_tx_w>
    800008f2:	00008717          	auipc	a4,0x8
    800008f6:	71673703          	ld	a4,1814(a4) # 80009008 <uart_tx_r>
    800008fa:	02070713          	addi	a4,a4,32
    800008fe:	02f71b63          	bne	a4,a5,80000934 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000902:	00011a17          	auipc	s4,0x11
    80000906:	946a0a13          	addi	s4,s4,-1722 # 80011248 <uart_tx_lock>
    8000090a:	00008497          	auipc	s1,0x8
    8000090e:	6fe48493          	addi	s1,s1,1790 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00008917          	auipc	s2,0x8
    80000916:	6fe90913          	addi	s2,s2,1790 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85d2                	mv	a1,s4
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	ad6080e7          	jalr	-1322(ra) # 800023f4 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093783          	ld	a5,0(s2)
    8000092a:	6098                	ld	a4,0(s1)
    8000092c:	02070713          	addi	a4,a4,32
    80000930:	fef705e3          	beq	a4,a5,8000091a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00011497          	auipc	s1,0x11
    80000938:	91448493          	addi	s1,s1,-1772 # 80011248 <uart_tx_lock>
    8000093c:	01f7f713          	andi	a4,a5,31
    80000940:	9726                	add	a4,a4,s1
    80000942:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000946:	0785                	addi	a5,a5,1
    80000948:	00008717          	auipc	a4,0x8
    8000094c:	6cf73423          	sd	a5,1736(a4) # 80009010 <uart_tx_w>
      uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee2080e7          	jalr	-286(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    int c = uartgetc();
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	fcc080e7          	jalr	-52(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009ae:	00950763          	beq	a0,s1,800009bc <uartintr+0x22>
      break;
    consoleintr(c);
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	8fe080e7          	jalr	-1794(ra) # 800002b0 <consoleintr>
  while(1){
    800009ba:	b7f5                	j	800009a6 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	88c48493          	addi	s1,s1,-1908 # 80011248 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e64080e7          	jalr	-412(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	0002d797          	auipc	a5,0x2d
    80000a02:	60278793          	addi	a5,a5,1538 # 8002e000 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00011917          	auipc	s2,0x11
    80000a22:	86290913          	addi	s2,s2,-1950 # 80011280 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ad8080e7          	jalr	-1320(ra) # 80000530 <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	7c650513          	addi	a0,a0,1990 # 80011280 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	0002d517          	auipc	a0,0x2d
    80000ad2:	53250513          	addi	a0,a0,1330 # 8002e000 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	79048493          	addi	s1,s1,1936 # 80011280 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	77850513          	addi	a0,a0,1912 # 80011280 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	74c50513          	addi	a0,a0,1868 # 80011280 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e68080e7          	jalr	-408(ra) # 800019d8 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	e36080e7          	jalr	-458(ra) # 800019d8 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	e2a080e7          	jalr	-470(ra) # 800019d8 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	e12080e7          	jalr	-494(ra) # 800019d8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	dd2080e7          	jalr	-558(ra) # 800019d8 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	90e080e7          	jalr	-1778(ra) # 80000530 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	da6080e7          	jalr	-602(ra) # 800019d8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8be080e7          	jalr	-1858(ra) # 80000530 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8ae080e7          	jalr	-1874(ra) # 80000530 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	866080e7          	jalr	-1946(ra) # 80000530 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ce09                	beqz	a2,80000cf2 <memset+0x20>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	fff6071b          	addiw	a4,a2,-1
    80000ce0:	1702                	slli	a4,a4,0x20
    80000ce2:	9301                	srli	a4,a4,0x20
    80000ce4:	0705                	addi	a4,a4,1
    80000ce6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000ce8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cec:	0785                	addi	a5,a5,1
    80000cee:	fee79de3          	bne	a5,a4,80000ce8 <memset+0x16>
  }
  return dst;
}
    80000cf2:	6422                	ld	s0,8(sp)
    80000cf4:	0141                	addi	sp,sp,16
    80000cf6:	8082                	ret

0000000080000cf8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfe:	ca05                	beqz	a2,80000d2e <memcmp+0x36>
    80000d00:	fff6069b          	addiw	a3,a2,-1
    80000d04:	1682                	slli	a3,a3,0x20
    80000d06:	9281                	srli	a3,a3,0x20
    80000d08:	0685                	addi	a3,a3,1
    80000d0a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d0c:	00054783          	lbu	a5,0(a0)
    80000d10:	0005c703          	lbu	a4,0(a1)
    80000d14:	00e79863          	bne	a5,a4,80000d24 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d18:	0505                	addi	a0,a0,1
    80000d1a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d1c:	fed518e3          	bne	a0,a3,80000d0c <memcmp+0x14>
  }

  return 0;
    80000d20:	4501                	li	a0,0
    80000d22:	a019                	j	80000d28 <memcmp+0x30>
      return *s1 - *s2;
    80000d24:	40e7853b          	subw	a0,a5,a4
}
    80000d28:	6422                	ld	s0,8(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret
  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	bfe5                	j	80000d28 <memcmp+0x30>

0000000080000d32 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d38:	00a5f963          	bgeu	a1,a0,80000d4a <memmove+0x18>
    80000d3c:	02061713          	slli	a4,a2,0x20
    80000d40:	9301                	srli	a4,a4,0x20
    80000d42:	00e587b3          	add	a5,a1,a4
    80000d46:	02f56563          	bltu	a0,a5,80000d70 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d4a:	fff6069b          	addiw	a3,a2,-1
    80000d4e:	ce11                	beqz	a2,80000d6a <memmove+0x38>
    80000d50:	1682                	slli	a3,a3,0x20
    80000d52:	9281                	srli	a3,a3,0x20
    80000d54:	0685                	addi	a3,a3,1
    80000d56:	96ae                	add	a3,a3,a1
    80000d58:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d5a:	0585                	addi	a1,a1,1
    80000d5c:	0785                	addi	a5,a5,1
    80000d5e:	fff5c703          	lbu	a4,-1(a1)
    80000d62:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d66:	fed59ae3          	bne	a1,a3,80000d5a <memmove+0x28>

  return dst;
}
    80000d6a:	6422                	ld	s0,8(sp)
    80000d6c:	0141                	addi	sp,sp,16
    80000d6e:	8082                	ret
    d += n;
    80000d70:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d72:	fff6069b          	addiw	a3,a2,-1
    80000d76:	da75                	beqz	a2,80000d6a <memmove+0x38>
    80000d78:	02069613          	slli	a2,a3,0x20
    80000d7c:	9201                	srli	a2,a2,0x20
    80000d7e:	fff64613          	not	a2,a2
    80000d82:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d84:	17fd                	addi	a5,a5,-1
    80000d86:	177d                	addi	a4,a4,-1
    80000d88:	0007c683          	lbu	a3,0(a5)
    80000d8c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d90:	fec79ae3          	bne	a5,a2,80000d84 <memmove+0x52>
    80000d94:	bfd9                	j	80000d6a <memmove+0x38>

0000000080000d96 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e406                	sd	ra,8(sp)
    80000d9a:	e022                	sd	s0,0(sp)
    80000d9c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d9e:	00000097          	auipc	ra,0x0
    80000da2:	f94080e7          	jalr	-108(ra) # 80000d32 <memmove>
}
    80000da6:	60a2                	ld	ra,8(sp)
    80000da8:	6402                	ld	s0,0(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret

0000000080000dae <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e422                	sd	s0,8(sp)
    80000db2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000db4:	ce11                	beqz	a2,80000dd0 <strncmp+0x22>
    80000db6:	00054783          	lbu	a5,0(a0)
    80000dba:	cf89                	beqz	a5,80000dd4 <strncmp+0x26>
    80000dbc:	0005c703          	lbu	a4,0(a1)
    80000dc0:	00f71a63          	bne	a4,a5,80000dd4 <strncmp+0x26>
    n--, p++, q++;
    80000dc4:	367d                	addiw	a2,a2,-1
    80000dc6:	0505                	addi	a0,a0,1
    80000dc8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dca:	f675                	bnez	a2,80000db6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dcc:	4501                	li	a0,0
    80000dce:	a809                	j	80000de0 <strncmp+0x32>
    80000dd0:	4501                	li	a0,0
    80000dd2:	a039                	j	80000de0 <strncmp+0x32>
  if(n == 0)
    80000dd4:	ca09                	beqz	a2,80000de6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dd6:	00054503          	lbu	a0,0(a0)
    80000dda:	0005c783          	lbu	a5,0(a1)
    80000dde:	9d1d                	subw	a0,a0,a5
}
    80000de0:	6422                	ld	s0,8(sp)
    80000de2:	0141                	addi	sp,sp,16
    80000de4:	8082                	ret
    return 0;
    80000de6:	4501                	li	a0,0
    80000de8:	bfe5                	j	80000de0 <strncmp+0x32>

0000000080000dea <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dea:	1141                	addi	sp,sp,-16
    80000dec:	e422                	sd	s0,8(sp)
    80000dee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000df0:	872a                	mv	a4,a0
    80000df2:	8832                	mv	a6,a2
    80000df4:	367d                	addiw	a2,a2,-1
    80000df6:	01005963          	blez	a6,80000e08 <strncpy+0x1e>
    80000dfa:	0705                	addi	a4,a4,1
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	fef70fa3          	sb	a5,-1(a4)
    80000e04:	0585                	addi	a1,a1,1
    80000e06:	f7f5                	bnez	a5,80000df2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e08:	00c05d63          	blez	a2,80000e22 <strncpy+0x38>
    80000e0c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e0e:	0685                	addi	a3,a3,1
    80000e10:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e14:	fff6c793          	not	a5,a3
    80000e18:	9fb9                	addw	a5,a5,a4
    80000e1a:	010787bb          	addw	a5,a5,a6
    80000e1e:	fef048e3          	bgtz	a5,80000e0e <strncpy+0x24>
  return os;
}
    80000e22:	6422                	ld	s0,8(sp)
    80000e24:	0141                	addi	sp,sp,16
    80000e26:	8082                	ret

0000000080000e28 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e28:	1141                	addi	sp,sp,-16
    80000e2a:	e422                	sd	s0,8(sp)
    80000e2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e2e:	02c05363          	blez	a2,80000e54 <safestrcpy+0x2c>
    80000e32:	fff6069b          	addiw	a3,a2,-1
    80000e36:	1682                	slli	a3,a3,0x20
    80000e38:	9281                	srli	a3,a3,0x20
    80000e3a:	96ae                	add	a3,a3,a1
    80000e3c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e3e:	00d58963          	beq	a1,a3,80000e50 <safestrcpy+0x28>
    80000e42:	0585                	addi	a1,a1,1
    80000e44:	0785                	addi	a5,a5,1
    80000e46:	fff5c703          	lbu	a4,-1(a1)
    80000e4a:	fee78fa3          	sb	a4,-1(a5)
    80000e4e:	fb65                	bnez	a4,80000e3e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e50:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <strlen>:

int
strlen(const char *s)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e60:	00054783          	lbu	a5,0(a0)
    80000e64:	cf91                	beqz	a5,80000e80 <strlen+0x26>
    80000e66:	0505                	addi	a0,a0,1
    80000e68:	87aa                	mv	a5,a0
    80000e6a:	4685                	li	a3,1
    80000e6c:	9e89                	subw	a3,a3,a0
    80000e6e:	00f6853b          	addw	a0,a3,a5
    80000e72:	0785                	addi	a5,a5,1
    80000e74:	fff7c703          	lbu	a4,-1(a5)
    80000e78:	fb7d                	bnez	a4,80000e6e <strlen+0x14>
    ;
  return n;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e80:	4501                	li	a0,0
    80000e82:	bfe5                	j	80000e7a <strlen+0x20>

0000000080000e84 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e84:	1141                	addi	sp,sp,-16
    80000e86:	e406                	sd	ra,8(sp)
    80000e88:	e022                	sd	s0,0(sp)
    80000e8a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e8c:	00001097          	auipc	ra,0x1
    80000e90:	b3c080e7          	jalr	-1220(ra) # 800019c8 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e94:	00008717          	auipc	a4,0x8
    80000e98:	18470713          	addi	a4,a4,388 # 80009018 <started>
  if(cpuid() == 0){
    80000e9c:	c139                	beqz	a0,80000ee2 <main+0x5e>
    while(started == 0)
    80000e9e:	431c                	lw	a5,0(a4)
    80000ea0:	2781                	sext.w	a5,a5
    80000ea2:	dff5                	beqz	a5,80000e9e <main+0x1a>
      ;
    __sync_synchronize();
    80000ea4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ea8:	00001097          	auipc	ra,0x1
    80000eac:	b20080e7          	jalr	-1248(ra) # 800019c8 <cpuid>
    80000eb0:	85aa                	mv	a1,a0
    80000eb2:	00007517          	auipc	a0,0x7
    80000eb6:	20650513          	addi	a0,a0,518 # 800080b8 <digits+0x78>
    80000eba:	fffff097          	auipc	ra,0xfffff
    80000ebe:	6c0080e7          	jalr	1728(ra) # 8000057a <printf>
    kvminithart();    // turn on paging
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	0d8080e7          	jalr	216(ra) # 80000f9a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eca:	00002097          	auipc	ra,0x2
    80000ece:	978080e7          	jalr	-1672(ra) # 80002842 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed2:	00005097          	auipc	ra,0x5
    80000ed6:	46e080e7          	jalr	1134(ra) # 80006340 <plicinithart>
  }

  scheduler();        
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	090080e7          	jalr	144(ra) # 80001f6a <scheduler>
    consoleinit();
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	560080e7          	jalr	1376(ra) # 80000442 <consoleinit>
    printfinit();
    80000eea:	00000097          	auipc	ra,0x0
    80000eee:	876080e7          	jalr	-1930(ra) # 80000760 <printfinit>
    printf("\n");
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	1d650513          	addi	a0,a0,470 # 800080c8 <digits+0x88>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	680080e7          	jalr	1664(ra) # 8000057a <printf>
    printf("xv6 kernel is booting\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	19e50513          	addi	a0,a0,414 # 800080a0 <digits+0x60>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	670080e7          	jalr	1648(ra) # 8000057a <printf>
    printf("\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	1b650513          	addi	a0,a0,438 # 800080c8 <digits+0x88>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	660080e7          	jalr	1632(ra) # 8000057a <printf>
    kinit();         // physical page allocator
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	b88080e7          	jalr	-1144(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	310080e7          	jalr	784(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	068080e7          	jalr	104(ra) # 80000f9a <kvminithart>
    procinit();      // process table
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	9f6080e7          	jalr	-1546(ra) # 80001930 <procinit>
    trapinit();      // trap vectors
    80000f42:	00002097          	auipc	ra,0x2
    80000f46:	8d8080e7          	jalr	-1832(ra) # 8000281a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	8f8080e7          	jalr	-1800(ra) # 80002842 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	3d8080e7          	jalr	984(ra) # 8000632a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	3e6080e7          	jalr	998(ra) # 80006340 <plicinithart>
    binit();         // buffer cache
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	184080e7          	jalr	388(ra) # 800030e6 <binit>
    iinit();         // inode cache
    80000f6a:	00003097          	auipc	ra,0x3
    80000f6e:	814080e7          	jalr	-2028(ra) # 8000377e <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	7c6080e7          	jalr	1990(ra) # 80004738 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	4e8080e7          	jalr	1256(ra) # 80006462 <virtio_disk_init>
    userinit();      // first user process
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	d3c080e7          	jalr	-708(ra) # 80001cbe <userinit>
    __sync_synchronize();
    80000f8a:	0ff0000f          	fence
    started = 1;
    80000f8e:	4785                	li	a5,1
    80000f90:	00008717          	auipc	a4,0x8
    80000f94:	08f72423          	sw	a5,136(a4) # 80009018 <started>
    80000f98:	b789                	j	80000eda <main+0x56>

0000000080000f9a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f9a:	1141                	addi	sp,sp,-16
    80000f9c:	e422                	sd	s0,8(sp)
    80000f9e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa0:	00008797          	auipc	a5,0x8
    80000fa4:	0807b783          	ld	a5,128(a5) # 80009020 <kernel_pagetable>
    80000fa8:	83b1                	srli	a5,a5,0xc
    80000faa:	577d                	li	a4,-1
    80000fac:	177e                	slli	a4,a4,0x3f
    80000fae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fb0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma
  sfence_vma();
}
    80000fb8:	6422                	ld	s0,8(sp)
    80000fba:	0141                	addi	sp,sp,16
    80000fbc:	8082                	ret

0000000080000fbe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fbe:	7139                	addi	sp,sp,-64
    80000fc0:	fc06                	sd	ra,56(sp)
    80000fc2:	f822                	sd	s0,48(sp)
    80000fc4:	f426                	sd	s1,40(sp)
    80000fc6:	f04a                	sd	s2,32(sp)
    80000fc8:	ec4e                	sd	s3,24(sp)
    80000fca:	e852                	sd	s4,16(sp)
    80000fcc:	e456                	sd	s5,8(sp)
    80000fce:	e05a                	sd	s6,0(sp)
    80000fd0:	0080                	addi	s0,sp,64
    80000fd2:	84aa                	mv	s1,a0
    80000fd4:	89ae                	mv	s3,a1
    80000fd6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd8:	57fd                	li	a5,-1
    80000fda:	83e9                	srli	a5,a5,0x1a
    80000fdc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fde:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fe0:	04b7f263          	bgeu	a5,a1,80001024 <walk+0x66>
    panic("walk");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0ec50513          	addi	a0,a0,236 # 800080d0 <digits+0x90>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	544080e7          	jalr	1348(ra) # 80000530 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ff4:	060a8663          	beqz	s5,80001060 <walk+0xa2>
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	aee080e7          	jalr	-1298(ra) # 80000ae6 <kalloc>
    80001000:	84aa                	mv	s1,a0
    80001002:	c529                	beqz	a0,8000104c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001004:	6605                	lui	a2,0x1
    80001006:	4581                	li	a1,0
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	cca080e7          	jalr	-822(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001010:	00c4d793          	srli	a5,s1,0xc
    80001014:	07aa                	slli	a5,a5,0xa
    80001016:	0017e793          	ori	a5,a5,1
    8000101a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000101e:	3a5d                	addiw	s4,s4,-9
    80001020:	036a0063          	beq	s4,s6,80001040 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001024:	0149d933          	srl	s2,s3,s4
    80001028:	1ff97913          	andi	s2,s2,511
    8000102c:	090e                	slli	s2,s2,0x3
    8000102e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001030:	00093483          	ld	s1,0(s2)
    80001034:	0014f793          	andi	a5,s1,1
    80001038:	dfd5                	beqz	a5,80000ff4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000103a:	80a9                	srli	s1,s1,0xa
    8000103c:	04b2                	slli	s1,s1,0xc
    8000103e:	b7c5                	j	8000101e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001040:	00c9d513          	srli	a0,s3,0xc
    80001044:	1ff57513          	andi	a0,a0,511
    80001048:	050e                	slli	a0,a0,0x3
    8000104a:	9526                	add	a0,a0,s1
}
    8000104c:	70e2                	ld	ra,56(sp)
    8000104e:	7442                	ld	s0,48(sp)
    80001050:	74a2                	ld	s1,40(sp)
    80001052:	7902                	ld	s2,32(sp)
    80001054:	69e2                	ld	s3,24(sp)
    80001056:	6a42                	ld	s4,16(sp)
    80001058:	6aa2                	ld	s5,8(sp)
    8000105a:	6b02                	ld	s6,0(sp)
    8000105c:	6121                	addi	sp,sp,64
    8000105e:	8082                	ret
        return 0;
    80001060:	4501                	li	a0,0
    80001062:	b7ed                	j	8000104c <walk+0x8e>

0000000080001064 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	00b7f463          	bgeu	a5,a1,80001070 <walkaddr+0xc>
    return 0;
    8000106c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000106e:	8082                	ret
{
    80001070:	1141                	addi	sp,sp,-16
    80001072:	e406                	sd	ra,8(sp)
    80001074:	e022                	sd	s0,0(sp)
    80001076:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001078:	4601                	li	a2,0
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	f44080e7          	jalr	-188(ra) # 80000fbe <walk>
  if(pte == 0)
    80001082:	c105                	beqz	a0,800010a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001084:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001086:	0117f693          	andi	a3,a5,17
    8000108a:	4745                	li	a4,17
    return 0;
    8000108c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000108e:	00e68663          	beq	a3,a4,8000109a <walkaddr+0x36>
}
    80001092:	60a2                	ld	ra,8(sp)
    80001094:	6402                	ld	s0,0(sp)
    80001096:	0141                	addi	sp,sp,16
    80001098:	8082                	ret
  pa = PTE2PA(*pte);
    8000109a:	00a7d513          	srli	a0,a5,0xa
    8000109e:	0532                	slli	a0,a0,0xc
  return pa;
    800010a0:	bfcd                	j	80001092 <walkaddr+0x2e>
    return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7fd                	j	80001092 <walkaddr+0x2e>

00000000800010a6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010a6:	715d                	addi	sp,sp,-80
    800010a8:	e486                	sd	ra,72(sp)
    800010aa:	e0a2                	sd	s0,64(sp)
    800010ac:	fc26                	sd	s1,56(sp)
    800010ae:	f84a                	sd	s2,48(sp)
    800010b0:	f44e                	sd	s3,40(sp)
    800010b2:	f052                	sd	s4,32(sp)
    800010b4:	ec56                	sd	s5,24(sp)
    800010b6:	e85a                	sd	s6,16(sp)
    800010b8:	e45e                	sd	s7,8(sp)
    800010ba:	0880                	addi	s0,sp,80
    800010bc:	8aaa                	mv	s5,a0
    800010be:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010c0:	777d                	lui	a4,0xfffff
    800010c2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c6:	167d                	addi	a2,a2,-1
    800010c8:	00b609b3          	add	s3,a2,a1
    800010cc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010d0:	893e                	mv	s2,a5
    800010d2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d6:	6b85                	lui	s7,0x1
    800010d8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010dc:	4605                	li	a2,1
    800010de:	85ca                	mv	a1,s2
    800010e0:	8556                	mv	a0,s5
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	edc080e7          	jalr	-292(ra) # 80000fbe <walk>
    800010ea:	c51d                	beqz	a0,80001118 <mappages+0x72>
    if(*pte & PTE_V)
    800010ec:	611c                	ld	a5,0(a0)
    800010ee:	8b85                	andi	a5,a5,1
    800010f0:	ef81                	bnez	a5,80001108 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010f2:	80b1                	srli	s1,s1,0xc
    800010f4:	04aa                	slli	s1,s1,0xa
    800010f6:	0164e4b3          	or	s1,s1,s6
    800010fa:	0014e493          	ori	s1,s1,1
    800010fe:	e104                	sd	s1,0(a0)
    if(a == last)
    80001100:	03390863          	beq	s2,s3,80001130 <mappages+0x8a>
    a += PGSIZE;
    80001104:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001106:	bfc9                	j	800010d8 <mappages+0x32>
      panic("remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fd050513          	addi	a0,a0,-48 # 800080d8 <digits+0x98>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	420080e7          	jalr	1056(ra) # 80000530 <panic>
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
    80001132:	b7e5                	j	8000111a <mappages+0x74>

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
    80001146:	f64080e7          	jalr	-156(ra) # 800010a6 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	f8c50513          	addi	a0,a0,-116 # 800080e0 <digits+0xa0>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3d4080e7          	jalr	980(ra) # 80000530 <panic>

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
    80001174:	976080e7          	jalr	-1674(ra) # 80000ae6 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b54080e7          	jalr	-1196(ra) # 80000cd2 <memset>
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
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	676080e7          	jalr	1654(ra) # 8000189a <proc_mapstacks>
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
    8000127a:	8bb6                	mv	s7,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      //panic("uvmunmap: not mapped");
      continue;
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b05                	li	s6,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6a85                	lui	s5,0x1
    80001286:	0535e963          	bltu	a1,s3,800012d8 <uvmunmap+0x7e>
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
    800012a4:	e4850513          	addi	a0,a0,-440 # 800080e8 <digits+0xa8>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	288080e7          	jalr	648(ra) # 80000530 <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e5050513          	addi	a0,a0,-432 # 80008100 <digits+0xc0>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	278080e7          	jalr	632(ra) # 80000530 <panic>
      uint64 pa = PTE2PA(*pte);
    800012c0:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800012c2:	00c79513          	slli	a0,a5,0xc
    800012c6:	fffff097          	auipc	ra,0xfffff
    800012ca:	724080e7          	jalr	1828(ra) # 800009ea <kfree>
    *pte = 0;
    800012ce:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d2:	9956                	add	s2,s2,s5
    800012d4:	fb397be3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012d8:	4601                	li	a2,0
    800012da:	85ca                	mv	a1,s2
    800012dc:	8552                	mv	a0,s4
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	ce0080e7          	jalr	-800(ra) # 80000fbe <walk>
    800012e6:	84aa                	mv	s1,a0
    800012e8:	d561                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012ea:	611c                	ld	a5,0(a0)
    800012ec:	0017f713          	andi	a4,a5,1
    800012f0:	d36d                	beqz	a4,800012d2 <uvmunmap+0x78>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012f2:	3ff7f713          	andi	a4,a5,1023
    800012f6:	fd670ee3          	beq	a4,s6,800012d2 <uvmunmap+0x78>
    if(do_free){
    800012fa:	fc0b8ae3          	beqz	s7,800012ce <uvmunmap+0x74>
    800012fe:	b7c9                	j	800012c0 <uvmunmap+0x66>

0000000080001300 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001300:	1101                	addi	sp,sp,-32
    80001302:	ec06                	sd	ra,24(sp)
    80001304:	e822                	sd	s0,16(sp)
    80001306:	e426                	sd	s1,8(sp)
    80001308:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	7dc080e7          	jalr	2012(ra) # 80000ae6 <kalloc>
    80001312:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001314:	c519                	beqz	a0,80001322 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001316:	6605                	lui	a2,0x1
    80001318:	4581                	li	a1,0
    8000131a:	00000097          	auipc	ra,0x0
    8000131e:	9b8080e7          	jalr	-1608(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001322:	8526                	mv	a0,s1
    80001324:	60e2                	ld	ra,24(sp)
    80001326:	6442                	ld	s0,16(sp)
    80001328:	64a2                	ld	s1,8(sp)
    8000132a:	6105                	addi	sp,sp,32
    8000132c:	8082                	ret

000000008000132e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000132e:	7179                	addi	sp,sp,-48
    80001330:	f406                	sd	ra,40(sp)
    80001332:	f022                	sd	s0,32(sp)
    80001334:	ec26                	sd	s1,24(sp)
    80001336:	e84a                	sd	s2,16(sp)
    80001338:	e44e                	sd	s3,8(sp)
    8000133a:	e052                	sd	s4,0(sp)
    8000133c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000133e:	6785                	lui	a5,0x1
    80001340:	04f67863          	bgeu	a2,a5,80001390 <uvminit+0x62>
    80001344:	8a2a                	mv	s4,a0
    80001346:	89ae                	mv	s3,a1
    80001348:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	79c080e7          	jalr	1948(ra) # 80000ae6 <kalloc>
    80001352:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001354:	6605                	lui	a2,0x1
    80001356:	4581                	li	a1,0
    80001358:	00000097          	auipc	ra,0x0
    8000135c:	97a080e7          	jalr	-1670(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001360:	4779                	li	a4,30
    80001362:	86ca                	mv	a3,s2
    80001364:	6605                	lui	a2,0x1
    80001366:	4581                	li	a1,0
    80001368:	8552                	mv	a0,s4
    8000136a:	00000097          	auipc	ra,0x0
    8000136e:	d3c080e7          	jalr	-708(ra) # 800010a6 <mappages>
  memmove(mem, src, sz);
    80001372:	8626                	mv	a2,s1
    80001374:	85ce                	mv	a1,s3
    80001376:	854a                	mv	a0,s2
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	9ba080e7          	jalr	-1606(ra) # 80000d32 <memmove>
}
    80001380:	70a2                	ld	ra,40(sp)
    80001382:	7402                	ld	s0,32(sp)
    80001384:	64e2                	ld	s1,24(sp)
    80001386:	6942                	ld	s2,16(sp)
    80001388:	69a2                	ld	s3,8(sp)
    8000138a:	6a02                	ld	s4,0(sp)
    8000138c:	6145                	addi	sp,sp,48
    8000138e:	8082                	ret
    panic("inituvm: more than a page");
    80001390:	00007517          	auipc	a0,0x7
    80001394:	d8050513          	addi	a0,a0,-640 # 80008110 <digits+0xd0>
    80001398:	fffff097          	auipc	ra,0xfffff
    8000139c:	198080e7          	jalr	408(ra) # 80000530 <panic>

00000000800013a0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013a0:	1101                	addi	sp,sp,-32
    800013a2:	ec06                	sd	ra,24(sp)
    800013a4:	e822                	sd	s0,16(sp)
    800013a6:	e426                	sd	s1,8(sp)
    800013a8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013aa:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ac:	00b67d63          	bgeu	a2,a1,800013c6 <uvmdealloc+0x26>
    800013b0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013b2:	6785                	lui	a5,0x1
    800013b4:	17fd                	addi	a5,a5,-1
    800013b6:	00f60733          	add	a4,a2,a5
    800013ba:	767d                	lui	a2,0xfffff
    800013bc:	8f71                	and	a4,a4,a2
    800013be:	97ae                	add	a5,a5,a1
    800013c0:	8ff1                	and	a5,a5,a2
    800013c2:	00f76863          	bltu	a4,a5,800013d2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013c6:	8526                	mv	a0,s1
    800013c8:	60e2                	ld	ra,24(sp)
    800013ca:	6442                	ld	s0,16(sp)
    800013cc:	64a2                	ld	s1,8(sp)
    800013ce:	6105                	addi	sp,sp,32
    800013d0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013d2:	8f99                	sub	a5,a5,a4
    800013d4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013d6:	4685                	li	a3,1
    800013d8:	0007861b          	sext.w	a2,a5
    800013dc:	85ba                	mv	a1,a4
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	e7c080e7          	jalr	-388(ra) # 8000125a <uvmunmap>
    800013e6:	b7c5                	j	800013c6 <uvmdealloc+0x26>

00000000800013e8 <uvmalloc>:
  if(newsz < oldsz)
    800013e8:	0ab66163          	bltu	a2,a1,8000148a <uvmalloc+0xa2>
{
    800013ec:	7139                	addi	sp,sp,-64
    800013ee:	fc06                	sd	ra,56(sp)
    800013f0:	f822                	sd	s0,48(sp)
    800013f2:	f426                	sd	s1,40(sp)
    800013f4:	f04a                	sd	s2,32(sp)
    800013f6:	ec4e                	sd	s3,24(sp)
    800013f8:	e852                	sd	s4,16(sp)
    800013fa:	e456                	sd	s5,8(sp)
    800013fc:	0080                	addi	s0,sp,64
    800013fe:	8aaa                	mv	s5,a0
    80001400:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001402:	6985                	lui	s3,0x1
    80001404:	19fd                	addi	s3,s3,-1
    80001406:	95ce                	add	a1,a1,s3
    80001408:	79fd                	lui	s3,0xfffff
    8000140a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000140e:	08c9f063          	bgeu	s3,a2,8000148e <uvmalloc+0xa6>
    80001412:	894e                	mv	s2,s3
    mem = kalloc();
    80001414:	fffff097          	auipc	ra,0xfffff
    80001418:	6d2080e7          	jalr	1746(ra) # 80000ae6 <kalloc>
    8000141c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000141e:	c51d                	beqz	a0,8000144c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001420:	6605                	lui	a2,0x1
    80001422:	4581                	li	a1,0
    80001424:	00000097          	auipc	ra,0x0
    80001428:	8ae080e7          	jalr	-1874(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000142c:	4779                	li	a4,30
    8000142e:	86a6                	mv	a3,s1
    80001430:	6605                	lui	a2,0x1
    80001432:	85ca                	mv	a1,s2
    80001434:	8556                	mv	a0,s5
    80001436:	00000097          	auipc	ra,0x0
    8000143a:	c70080e7          	jalr	-912(ra) # 800010a6 <mappages>
    8000143e:	e905                	bnez	a0,8000146e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001440:	6785                	lui	a5,0x1
    80001442:	993e                	add	s2,s2,a5
    80001444:	fd4968e3          	bltu	s2,s4,80001414 <uvmalloc+0x2c>
  return newsz;
    80001448:	8552                	mv	a0,s4
    8000144a:	a809                	j	8000145c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000144c:	864e                	mv	a2,s3
    8000144e:	85ca                	mv	a1,s2
    80001450:	8556                	mv	a0,s5
    80001452:	00000097          	auipc	ra,0x0
    80001456:	f4e080e7          	jalr	-178(ra) # 800013a0 <uvmdealloc>
      return 0;
    8000145a:	4501                	li	a0,0
}
    8000145c:	70e2                	ld	ra,56(sp)
    8000145e:	7442                	ld	s0,48(sp)
    80001460:	74a2                	ld	s1,40(sp)
    80001462:	7902                	ld	s2,32(sp)
    80001464:	69e2                	ld	s3,24(sp)
    80001466:	6a42                	ld	s4,16(sp)
    80001468:	6aa2                	ld	s5,8(sp)
    8000146a:	6121                	addi	sp,sp,64
    8000146c:	8082                	ret
      kfree(mem);
    8000146e:	8526                	mv	a0,s1
    80001470:	fffff097          	auipc	ra,0xfffff
    80001474:	57a080e7          	jalr	1402(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001478:	864e                	mv	a2,s3
    8000147a:	85ca                	mv	a1,s2
    8000147c:	8556                	mv	a0,s5
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	f22080e7          	jalr	-222(ra) # 800013a0 <uvmdealloc>
      return 0;
    80001486:	4501                	li	a0,0
    80001488:	bfd1                	j	8000145c <uvmalloc+0x74>
    return oldsz;
    8000148a:	852e                	mv	a0,a1
}
    8000148c:	8082                	ret
  return newsz;
    8000148e:	8532                	mv	a0,a2
    80001490:	b7f1                	j	8000145c <uvmalloc+0x74>

0000000080001492 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001492:	7179                	addi	sp,sp,-48
    80001494:	f406                	sd	ra,40(sp)
    80001496:	f022                	sd	s0,32(sp)
    80001498:	ec26                	sd	s1,24(sp)
    8000149a:	e84a                	sd	s2,16(sp)
    8000149c:	e44e                	sd	s3,8(sp)
    8000149e:	e052                	sd	s4,0(sp)
    800014a0:	1800                	addi	s0,sp,48
    800014a2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014a4:	84aa                	mv	s1,a0
    800014a6:	6905                	lui	s2,0x1
    800014a8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014aa:	4985                	li	s3,1
    800014ac:	a821                	j	800014c4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014ae:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014b0:	0532                	slli	a0,a0,0xc
    800014b2:	00000097          	auipc	ra,0x0
    800014b6:	fe0080e7          	jalr	-32(ra) # 80001492 <freewalk>
      pagetable[i] = 0;
    800014ba:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014be:	04a1                	addi	s1,s1,8
    800014c0:	03248163          	beq	s1,s2,800014e2 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014c4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c6:	00f57793          	andi	a5,a0,15
    800014ca:	ff3782e3          	beq	a5,s3,800014ae <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ce:	8905                	andi	a0,a0,1
    800014d0:	d57d                	beqz	a0,800014be <freewalk+0x2c>
      panic("freewalk: leaf");
    800014d2:	00007517          	auipc	a0,0x7
    800014d6:	c5e50513          	addi	a0,a0,-930 # 80008130 <digits+0xf0>
    800014da:	fffff097          	auipc	ra,0xfffff
    800014de:	056080e7          	jalr	86(ra) # 80000530 <panic>
    }
  }
  kfree((void*)pagetable);
    800014e2:	8552                	mv	a0,s4
    800014e4:	fffff097          	auipc	ra,0xfffff
    800014e8:	506080e7          	jalr	1286(ra) # 800009ea <kfree>
}
    800014ec:	70a2                	ld	ra,40(sp)
    800014ee:	7402                	ld	s0,32(sp)
    800014f0:	64e2                	ld	s1,24(sp)
    800014f2:	6942                	ld	s2,16(sp)
    800014f4:	69a2                	ld	s3,8(sp)
    800014f6:	6a02                	ld	s4,0(sp)
    800014f8:	6145                	addi	sp,sp,48
    800014fa:	8082                	ret

00000000800014fc <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800014fc:	1101                	addi	sp,sp,-32
    800014fe:	ec06                	sd	ra,24(sp)
    80001500:	e822                	sd	s0,16(sp)
    80001502:	e426                	sd	s1,8(sp)
    80001504:	1000                	addi	s0,sp,32
    80001506:	84aa                	mv	s1,a0
  if(sz > 0)
    80001508:	e999                	bnez	a1,8000151e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000150a:	8526                	mv	a0,s1
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	f86080e7          	jalr	-122(ra) # 80001492 <freewalk>
}
    80001514:	60e2                	ld	ra,24(sp)
    80001516:	6442                	ld	s0,16(sp)
    80001518:	64a2                	ld	s1,8(sp)
    8000151a:	6105                	addi	sp,sp,32
    8000151c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000151e:	6605                	lui	a2,0x1
    80001520:	167d                	addi	a2,a2,-1
    80001522:	962e                	add	a2,a2,a1
    80001524:	4685                	li	a3,1
    80001526:	8231                	srli	a2,a2,0xc
    80001528:	4581                	li	a1,0
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	d30080e7          	jalr	-720(ra) # 8000125a <uvmunmap>
    80001532:	bfe1                	j	8000150a <uvmfree+0xe>

0000000080001534 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001534:	c679                	beqz	a2,80001602 <uvmcopy+0xce>
{
    80001536:	715d                	addi	sp,sp,-80
    80001538:	e486                	sd	ra,72(sp)
    8000153a:	e0a2                	sd	s0,64(sp)
    8000153c:	fc26                	sd	s1,56(sp)
    8000153e:	f84a                	sd	s2,48(sp)
    80001540:	f44e                	sd	s3,40(sp)
    80001542:	f052                	sd	s4,32(sp)
    80001544:	ec56                	sd	s5,24(sp)
    80001546:	e85a                	sd	s6,16(sp)
    80001548:	e45e                	sd	s7,8(sp)
    8000154a:	0880                	addi	s0,sp,80
    8000154c:	8b2a                	mv	s6,a0
    8000154e:	8aae                	mv	s5,a1
    80001550:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001552:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001554:	4601                	li	a2,0
    80001556:	85ce                	mv	a1,s3
    80001558:	855a                	mv	a0,s6
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	a64080e7          	jalr	-1436(ra) # 80000fbe <walk>
    80001562:	c531                	beqz	a0,800015ae <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001564:	6118                	ld	a4,0(a0)
    80001566:	00177793          	andi	a5,a4,1
    8000156a:	cbb1                	beqz	a5,800015be <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000156c:	00a75593          	srli	a1,a4,0xa
    80001570:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001574:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001578:	fffff097          	auipc	ra,0xfffff
    8000157c:	56e080e7          	jalr	1390(ra) # 80000ae6 <kalloc>
    80001580:	892a                	mv	s2,a0
    80001582:	c939                	beqz	a0,800015d8 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001584:	6605                	lui	a2,0x1
    80001586:	85de                	mv	a1,s7
    80001588:	fffff097          	auipc	ra,0xfffff
    8000158c:	7aa080e7          	jalr	1962(ra) # 80000d32 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001590:	8726                	mv	a4,s1
    80001592:	86ca                	mv	a3,s2
    80001594:	6605                	lui	a2,0x1
    80001596:	85ce                	mv	a1,s3
    80001598:	8556                	mv	a0,s5
    8000159a:	00000097          	auipc	ra,0x0
    8000159e:	b0c080e7          	jalr	-1268(ra) # 800010a6 <mappages>
    800015a2:	e515                	bnez	a0,800015ce <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015a4:	6785                	lui	a5,0x1
    800015a6:	99be                	add	s3,s3,a5
    800015a8:	fb49e6e3          	bltu	s3,s4,80001554 <uvmcopy+0x20>
    800015ac:	a081                	j	800015ec <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015ae:	00007517          	auipc	a0,0x7
    800015b2:	b9250513          	addi	a0,a0,-1134 # 80008140 <digits+0x100>
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	f7a080e7          	jalr	-134(ra) # 80000530 <panic>
      panic("uvmcopy: page not present");
    800015be:	00007517          	auipc	a0,0x7
    800015c2:	ba250513          	addi	a0,a0,-1118 # 80008160 <digits+0x120>
    800015c6:	fffff097          	auipc	ra,0xfffff
    800015ca:	f6a080e7          	jalr	-150(ra) # 80000530 <panic>
      kfree(mem);
    800015ce:	854a                	mv	a0,s2
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	41a080e7          	jalr	1050(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015d8:	4685                	li	a3,1
    800015da:	00c9d613          	srli	a2,s3,0xc
    800015de:	4581                	li	a1,0
    800015e0:	8556                	mv	a0,s5
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	c78080e7          	jalr	-904(ra) # 8000125a <uvmunmap>
  return -1;
    800015ea:	557d                	li	a0,-1
}
    800015ec:	60a6                	ld	ra,72(sp)
    800015ee:	6406                	ld	s0,64(sp)
    800015f0:	74e2                	ld	s1,56(sp)
    800015f2:	7942                	ld	s2,48(sp)
    800015f4:	79a2                	ld	s3,40(sp)
    800015f6:	7a02                	ld	s4,32(sp)
    800015f8:	6ae2                	ld	s5,24(sp)
    800015fa:	6b42                	ld	s6,16(sp)
    800015fc:	6ba2                	ld	s7,8(sp)
    800015fe:	6161                	addi	sp,sp,80
    80001600:	8082                	ret
  return 0;
    80001602:	4501                	li	a0,0
}
    80001604:	8082                	ret

0000000080001606 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001606:	1141                	addi	sp,sp,-16
    80001608:	e406                	sd	ra,8(sp)
    8000160a:	e022                	sd	s0,0(sp)
    8000160c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000160e:	4601                	li	a2,0
    80001610:	00000097          	auipc	ra,0x0
    80001614:	9ae080e7          	jalr	-1618(ra) # 80000fbe <walk>
  if(pte == 0)
    80001618:	c901                	beqz	a0,80001628 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000161a:	611c                	ld	a5,0(a0)
    8000161c:	9bbd                	andi	a5,a5,-17
    8000161e:	e11c                	sd	a5,0(a0)
}
    80001620:	60a2                	ld	ra,8(sp)
    80001622:	6402                	ld	s0,0(sp)
    80001624:	0141                	addi	sp,sp,16
    80001626:	8082                	ret
    panic("uvmclear");
    80001628:	00007517          	auipc	a0,0x7
    8000162c:	b5850513          	addi	a0,a0,-1192 # 80008180 <digits+0x140>
    80001630:	fffff097          	auipc	ra,0xfffff
    80001634:	f00080e7          	jalr	-256(ra) # 80000530 <panic>

0000000080001638 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001638:	c6bd                	beqz	a3,800016a6 <copyout+0x6e>
{
    8000163a:	715d                	addi	sp,sp,-80
    8000163c:	e486                	sd	ra,72(sp)
    8000163e:	e0a2                	sd	s0,64(sp)
    80001640:	fc26                	sd	s1,56(sp)
    80001642:	f84a                	sd	s2,48(sp)
    80001644:	f44e                	sd	s3,40(sp)
    80001646:	f052                	sd	s4,32(sp)
    80001648:	ec56                	sd	s5,24(sp)
    8000164a:	e85a                	sd	s6,16(sp)
    8000164c:	e45e                	sd	s7,8(sp)
    8000164e:	e062                	sd	s8,0(sp)
    80001650:	0880                	addi	s0,sp,80
    80001652:	8b2a                	mv	s6,a0
    80001654:	8c2e                	mv	s8,a1
    80001656:	8a32                	mv	s4,a2
    80001658:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000165a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000165c:	6a85                	lui	s5,0x1
    8000165e:	a015                	j	80001682 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001660:	9562                	add	a0,a0,s8
    80001662:	0004861b          	sext.w	a2,s1
    80001666:	85d2                	mv	a1,s4
    80001668:	41250533          	sub	a0,a0,s2
    8000166c:	fffff097          	auipc	ra,0xfffff
    80001670:	6c6080e7          	jalr	1734(ra) # 80000d32 <memmove>

    len -= n;
    80001674:	409989b3          	sub	s3,s3,s1
    src += n;
    80001678:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000167a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000167e:	02098263          	beqz	s3,800016a2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001682:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001686:	85ca                	mv	a1,s2
    80001688:	855a                	mv	a0,s6
    8000168a:	00000097          	auipc	ra,0x0
    8000168e:	9da080e7          	jalr	-1574(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    80001692:	cd01                	beqz	a0,800016aa <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001694:	418904b3          	sub	s1,s2,s8
    80001698:	94d6                	add	s1,s1,s5
    if(n > len)
    8000169a:	fc99f3e3          	bgeu	s3,s1,80001660 <copyout+0x28>
    8000169e:	84ce                	mv	s1,s3
    800016a0:	b7c1                	j	80001660 <copyout+0x28>
  }
  return 0;
    800016a2:	4501                	li	a0,0
    800016a4:	a021                	j	800016ac <copyout+0x74>
    800016a6:	4501                	li	a0,0
}
    800016a8:	8082                	ret
      return -1;
    800016aa:	557d                	li	a0,-1
}
    800016ac:	60a6                	ld	ra,72(sp)
    800016ae:	6406                	ld	s0,64(sp)
    800016b0:	74e2                	ld	s1,56(sp)
    800016b2:	7942                	ld	s2,48(sp)
    800016b4:	79a2                	ld	s3,40(sp)
    800016b6:	7a02                	ld	s4,32(sp)
    800016b8:	6ae2                	ld	s5,24(sp)
    800016ba:	6b42                	ld	s6,16(sp)
    800016bc:	6ba2                	ld	s7,8(sp)
    800016be:	6c02                	ld	s8,0(sp)
    800016c0:	6161                	addi	sp,sp,80
    800016c2:	8082                	ret

00000000800016c4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016c4:	c6bd                	beqz	a3,80001732 <copyin+0x6e>
{
    800016c6:	715d                	addi	sp,sp,-80
    800016c8:	e486                	sd	ra,72(sp)
    800016ca:	e0a2                	sd	s0,64(sp)
    800016cc:	fc26                	sd	s1,56(sp)
    800016ce:	f84a                	sd	s2,48(sp)
    800016d0:	f44e                	sd	s3,40(sp)
    800016d2:	f052                	sd	s4,32(sp)
    800016d4:	ec56                	sd	s5,24(sp)
    800016d6:	e85a                	sd	s6,16(sp)
    800016d8:	e45e                	sd	s7,8(sp)
    800016da:	e062                	sd	s8,0(sp)
    800016dc:	0880                	addi	s0,sp,80
    800016de:	8b2a                	mv	s6,a0
    800016e0:	8a2e                	mv	s4,a1
    800016e2:	8c32                	mv	s8,a2
    800016e4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016e6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016e8:	6a85                	lui	s5,0x1
    800016ea:	a015                	j	8000170e <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016ec:	9562                	add	a0,a0,s8
    800016ee:	0004861b          	sext.w	a2,s1
    800016f2:	412505b3          	sub	a1,a0,s2
    800016f6:	8552                	mv	a0,s4
    800016f8:	fffff097          	auipc	ra,0xfffff
    800016fc:	63a080e7          	jalr	1594(ra) # 80000d32 <memmove>

    len -= n;
    80001700:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001704:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001706:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000170a:	02098263          	beqz	s3,8000172e <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000170e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001712:	85ca                	mv	a1,s2
    80001714:	855a                	mv	a0,s6
    80001716:	00000097          	auipc	ra,0x0
    8000171a:	94e080e7          	jalr	-1714(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    8000171e:	cd01                	beqz	a0,80001736 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001720:	418904b3          	sub	s1,s2,s8
    80001724:	94d6                	add	s1,s1,s5
    if(n > len)
    80001726:	fc99f3e3          	bgeu	s3,s1,800016ec <copyin+0x28>
    8000172a:	84ce                	mv	s1,s3
    8000172c:	b7c1                	j	800016ec <copyin+0x28>
  }
  return 0;
    8000172e:	4501                	li	a0,0
    80001730:	a021                	j	80001738 <copyin+0x74>
    80001732:	4501                	li	a0,0
}
    80001734:	8082                	ret
      return -1;
    80001736:	557d                	li	a0,-1
}
    80001738:	60a6                	ld	ra,72(sp)
    8000173a:	6406                	ld	s0,64(sp)
    8000173c:	74e2                	ld	s1,56(sp)
    8000173e:	7942                	ld	s2,48(sp)
    80001740:	79a2                	ld	s3,40(sp)
    80001742:	7a02                	ld	s4,32(sp)
    80001744:	6ae2                	ld	s5,24(sp)
    80001746:	6b42                	ld	s6,16(sp)
    80001748:	6ba2                	ld	s7,8(sp)
    8000174a:	6c02                	ld	s8,0(sp)
    8000174c:	6161                	addi	sp,sp,80
    8000174e:	8082                	ret

0000000080001750 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001750:	c6c5                	beqz	a3,800017f8 <copyinstr+0xa8>
{
    80001752:	715d                	addi	sp,sp,-80
    80001754:	e486                	sd	ra,72(sp)
    80001756:	e0a2                	sd	s0,64(sp)
    80001758:	fc26                	sd	s1,56(sp)
    8000175a:	f84a                	sd	s2,48(sp)
    8000175c:	f44e                	sd	s3,40(sp)
    8000175e:	f052                	sd	s4,32(sp)
    80001760:	ec56                	sd	s5,24(sp)
    80001762:	e85a                	sd	s6,16(sp)
    80001764:	e45e                	sd	s7,8(sp)
    80001766:	0880                	addi	s0,sp,80
    80001768:	8a2a                	mv	s4,a0
    8000176a:	8b2e                	mv	s6,a1
    8000176c:	8bb2                	mv	s7,a2
    8000176e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001770:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001772:	6985                	lui	s3,0x1
    80001774:	a035                	j	800017a0 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001776:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000177a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000177c:	0017b793          	seqz	a5,a5
    80001780:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6161                	addi	sp,sp,80
    80001798:	8082                	ret
    srcva = va0 + PGSIZE;
    8000179a:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000179e:	c8a9                	beqz	s1,800017f0 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017a0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017a4:	85ca                	mv	a1,s2
    800017a6:	8552                	mv	a0,s4
    800017a8:	00000097          	auipc	ra,0x0
    800017ac:	8bc080e7          	jalr	-1860(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800017b0:	c131                	beqz	a0,800017f4 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017b2:	41790833          	sub	a6,s2,s7
    800017b6:	984e                	add	a6,a6,s3
    if(n > max)
    800017b8:	0104f363          	bgeu	s1,a6,800017be <copyinstr+0x6e>
    800017bc:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017be:	955e                	add	a0,a0,s7
    800017c0:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017c4:	fc080be3          	beqz	a6,8000179a <copyinstr+0x4a>
    800017c8:	985a                	add	a6,a6,s6
    800017ca:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017cc:	41650633          	sub	a2,a0,s6
    800017d0:	14fd                	addi	s1,s1,-1
    800017d2:	9b26                	add	s6,s6,s1
    800017d4:	00f60733          	add	a4,a2,a5
    800017d8:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd1000>
    800017dc:	df49                	beqz	a4,80001776 <copyinstr+0x26>
        *dst = *p;
    800017de:	00e78023          	sb	a4,0(a5)
      --max;
    800017e2:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017e6:	0785                	addi	a5,a5,1
    while(n > 0){
    800017e8:	ff0796e3          	bne	a5,a6,800017d4 <copyinstr+0x84>
      dst++;
    800017ec:	8b42                	mv	s6,a6
    800017ee:	b775                	j	8000179a <copyinstr+0x4a>
    800017f0:	4781                	li	a5,0
    800017f2:	b769                	j	8000177c <copyinstr+0x2c>
      return -1;
    800017f4:	557d                	li	a0,-1
    800017f6:	b779                	j	80001784 <copyinstr+0x34>
  int got_null = 0;
    800017f8:	4781                	li	a5,0
  if(got_null){
    800017fa:	0017b793          	seqz	a5,a5
    800017fe:	40f00533          	neg	a0,a5
}
    80001802:	8082                	ret

0000000080001804 <uvmgetdirty>:

// get the dirty flag of the va's PTE - lab10
int uvmgetdirty(pagetable_t pagetable, uint64 va) {
    80001804:	1141                	addi	sp,sp,-16
    80001806:	e406                	sd	ra,8(sp)
    80001808:	e022                	sd	s0,0(sp)
    8000180a:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    8000180c:	4601                	li	a2,0
    8000180e:	fffff097          	auipc	ra,0xfffff
    80001812:	7b0080e7          	jalr	1968(ra) # 80000fbe <walk>
  if(pte == 0) {
    80001816:	c909                	beqz	a0,80001828 <uvmgetdirty+0x24>
    return 0;
  }
  return (*pte & PTE_D);
    80001818:	6108                	ld	a0,0(a0)
    8000181a:	08057513          	andi	a0,a0,128
    8000181e:	2501                	sext.w	a0,a0
}
    80001820:	60a2                	ld	ra,8(sp)
    80001822:	6402                	ld	s0,0(sp)
    80001824:	0141                	addi	sp,sp,16
    80001826:	8082                	ret
    return 0;
    80001828:	4501                	li	a0,0
    8000182a:	bfdd                	j	80001820 <uvmgetdirty+0x1c>

000000008000182c <uvmsetdirtywrite>:

// set the dirty flag and write flag of the va's PTE - lab10
int uvmsetdirtywrite(pagetable_t pagetable, uint64 va) {
    8000182c:	1141                	addi	sp,sp,-16
    8000182e:	e406                	sd	ra,8(sp)
    80001830:	e022                	sd	s0,0(sp)
    80001832:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80001834:	4601                	li	a2,0
    80001836:	fffff097          	auipc	ra,0xfffff
    8000183a:	788080e7          	jalr	1928(ra) # 80000fbe <walk>
  if(pte == 0) {
    8000183e:	c911                	beqz	a0,80001852 <uvmsetdirtywrite+0x26>
    return -1;
  }
  *pte |= PTE_D | PTE_W;
    80001840:	611c                	ld	a5,0(a0)
    80001842:	0847e793          	ori	a5,a5,132
    80001846:	e11c                	sd	a5,0(a0)
  return 0;
    80001848:	4501                	li	a0,0
}
    8000184a:	60a2                	ld	ra,8(sp)
    8000184c:	6402                	ld	s0,0(sp)
    8000184e:	0141                	addi	sp,sp,16
    80001850:	8082                	ret
    return -1;
    80001852:	557d                	li	a0,-1
    80001854:	bfdd                	j	8000184a <uvmsetdirtywrite+0x1e>

0000000080001856 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001856:	1101                	addi	sp,sp,-32
    80001858:	ec06                	sd	ra,24(sp)
    8000185a:	e822                	sd	s0,16(sp)
    8000185c:	e426                	sd	s1,8(sp)
    8000185e:	1000                	addi	s0,sp,32
    80001860:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001862:	fffff097          	auipc	ra,0xfffff
    80001866:	2fa080e7          	jalr	762(ra) # 80000b5c <holding>
    8000186a:	c909                	beqz	a0,8000187c <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    8000186c:	749c                	ld	a5,40(s1)
    8000186e:	00978f63          	beq	a5,s1,8000188c <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001872:	60e2                	ld	ra,24(sp)
    80001874:	6442                	ld	s0,16(sp)
    80001876:	64a2                	ld	s1,8(sp)
    80001878:	6105                	addi	sp,sp,32
    8000187a:	8082                	ret
    panic("wakeup1");
    8000187c:	00007517          	auipc	a0,0x7
    80001880:	91450513          	addi	a0,a0,-1772 # 80008190 <digits+0x150>
    80001884:	fffff097          	auipc	ra,0xfffff
    80001888:	cac080e7          	jalr	-852(ra) # 80000530 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000188c:	4c98                	lw	a4,24(s1)
    8000188e:	4785                	li	a5,1
    80001890:	fef711e3          	bne	a4,a5,80001872 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001894:	4789                	li	a5,2
    80001896:	cc9c                	sw	a5,24(s1)
}
    80001898:	bfe9                	j	80001872 <wakeup1+0x1c>

000000008000189a <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    8000189a:	7139                	addi	sp,sp,-64
    8000189c:	fc06                	sd	ra,56(sp)
    8000189e:	f822                	sd	s0,48(sp)
    800018a0:	f426                	sd	s1,40(sp)
    800018a2:	f04a                	sd	s2,32(sp)
    800018a4:	ec4e                	sd	s3,24(sp)
    800018a6:	e852                	sd	s4,16(sp)
    800018a8:	e456                	sd	s5,8(sp)
    800018aa:	e05a                	sd	s6,0(sp)
    800018ac:	0080                	addi	s0,sp,64
    800018ae:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b0:	00010497          	auipc	s1,0x10
    800018b4:	e0848493          	addi	s1,s1,-504 # 800116b8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    800018b8:	8b26                	mv	s6,s1
    800018ba:	00006a97          	auipc	s5,0x6
    800018be:	746a8a93          	addi	s5,s5,1862 # 80008000 <etext>
    800018c2:	04000937          	lui	s2,0x4000
    800018c6:	197d                	addi	s2,s2,-1
    800018c8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ca:	0001da17          	auipc	s4,0x1d
    800018ce:	7eea0a13          	addi	s4,s4,2030 # 8001f0b8 <tickslock>
    char *pa = kalloc();
    800018d2:	fffff097          	auipc	ra,0xfffff
    800018d6:	214080e7          	jalr	532(ra) # 80000ae6 <kalloc>
    800018da:	862a                	mv	a2,a0
    if(pa == 0)
    800018dc:	c131                	beqz	a0,80001920 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018de:	416485b3          	sub	a1,s1,s6
    800018e2:	858d                	srai	a1,a1,0x3
    800018e4:	000ab783          	ld	a5,0(s5)
    800018e8:	02f585b3          	mul	a1,a1,a5
    800018ec:	2585                	addiw	a1,a1,1
    800018ee:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018f2:	4719                	li	a4,6
    800018f4:	6685                	lui	a3,0x1
    800018f6:	40b905b3          	sub	a1,s2,a1
    800018fa:	854e                	mv	a0,s3
    800018fc:	00000097          	auipc	ra,0x0
    80001900:	838080e7          	jalr	-1992(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001904:	36848493          	addi	s1,s1,872
    80001908:	fd4495e3          	bne	s1,s4,800018d2 <proc_mapstacks+0x38>
}
    8000190c:	70e2                	ld	ra,56(sp)
    8000190e:	7442                	ld	s0,48(sp)
    80001910:	74a2                	ld	s1,40(sp)
    80001912:	7902                	ld	s2,32(sp)
    80001914:	69e2                	ld	s3,24(sp)
    80001916:	6a42                	ld	s4,16(sp)
    80001918:	6aa2                	ld	s5,8(sp)
    8000191a:	6b02                	ld	s6,0(sp)
    8000191c:	6121                	addi	sp,sp,64
    8000191e:	8082                	ret
      panic("kalloc");
    80001920:	00007517          	auipc	a0,0x7
    80001924:	87850513          	addi	a0,a0,-1928 # 80008198 <digits+0x158>
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	c08080e7          	jalr	-1016(ra) # 80000530 <panic>

0000000080001930 <procinit>:
{
    80001930:	7139                	addi	sp,sp,-64
    80001932:	fc06                	sd	ra,56(sp)
    80001934:	f822                	sd	s0,48(sp)
    80001936:	f426                	sd	s1,40(sp)
    80001938:	f04a                	sd	s2,32(sp)
    8000193a:	ec4e                	sd	s3,24(sp)
    8000193c:	e852                	sd	s4,16(sp)
    8000193e:	e456                	sd	s5,8(sp)
    80001940:	e05a                	sd	s6,0(sp)
    80001942:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    80001944:	00007597          	auipc	a1,0x7
    80001948:	85c58593          	addi	a1,a1,-1956 # 800081a0 <digits+0x160>
    8000194c:	00010517          	auipc	a0,0x10
    80001950:	95450513          	addi	a0,a0,-1708 # 800112a0 <pid_lock>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	1f2080e7          	jalr	498(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195c:	00010497          	auipc	s1,0x10
    80001960:	d5c48493          	addi	s1,s1,-676 # 800116b8 <proc>
      initlock(&p->lock, "proc");
    80001964:	00007b17          	auipc	s6,0x7
    80001968:	844b0b13          	addi	s6,s6,-1980 # 800081a8 <digits+0x168>
      p->kstack = KSTACK((int) (p - proc));
    8000196c:	8aa6                	mv	s5,s1
    8000196e:	00006a17          	auipc	s4,0x6
    80001972:	692a0a13          	addi	s4,s4,1682 # 80008000 <etext>
    80001976:	04000937          	lui	s2,0x4000
    8000197a:	197d                	addi	s2,s2,-1
    8000197c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	0001d997          	auipc	s3,0x1d
    80001982:	73a98993          	addi	s3,s3,1850 # 8001f0b8 <tickslock>
      initlock(&p->lock, "proc");
    80001986:	85da                	mv	a1,s6
    80001988:	8526                	mv	a0,s1
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	1bc080e7          	jalr	444(ra) # 80000b46 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001992:	415487b3          	sub	a5,s1,s5
    80001996:	878d                	srai	a5,a5,0x3
    80001998:	000a3703          	ld	a4,0(s4)
    8000199c:	02e787b3          	mul	a5,a5,a4
    800019a0:	2785                	addiw	a5,a5,1
    800019a2:	00d7979b          	slliw	a5,a5,0xd
    800019a6:	40f907b3          	sub	a5,s2,a5
    800019aa:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ac:	36848493          	addi	s1,s1,872
    800019b0:	fd349be3          	bne	s1,s3,80001986 <procinit+0x56>
}
    800019b4:	70e2                	ld	ra,56(sp)
    800019b6:	7442                	ld	s0,48(sp)
    800019b8:	74a2                	ld	s1,40(sp)
    800019ba:	7902                	ld	s2,32(sp)
    800019bc:	69e2                	ld	s3,24(sp)
    800019be:	6a42                	ld	s4,16(sp)
    800019c0:	6aa2                	ld	s5,8(sp)
    800019c2:	6b02                	ld	s6,0(sp)
    800019c4:	6121                	addi	sp,sp,64
    800019c6:	8082                	ret

00000000800019c8 <cpuid>:
{
    800019c8:	1141                	addi	sp,sp,-16
    800019ca:	e422                	sd	s0,8(sp)
    800019cc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019ce:	8512                	mv	a0,tp
}
    800019d0:	2501                	sext.w	a0,a0
    800019d2:	6422                	ld	s0,8(sp)
    800019d4:	0141                	addi	sp,sp,16
    800019d6:	8082                	ret

00000000800019d8 <mycpu>:
mycpu(void) {
    800019d8:	1141                	addi	sp,sp,-16
    800019da:	e422                	sd	s0,8(sp)
    800019dc:	0800                	addi	s0,sp,16
    800019de:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019e0:	2781                	sext.w	a5,a5
    800019e2:	079e                	slli	a5,a5,0x7
}
    800019e4:	00010517          	auipc	a0,0x10
    800019e8:	8d450513          	addi	a0,a0,-1836 # 800112b8 <cpus>
    800019ec:	953e                	add	a0,a0,a5
    800019ee:	6422                	ld	s0,8(sp)
    800019f0:	0141                	addi	sp,sp,16
    800019f2:	8082                	ret

00000000800019f4 <myproc>:
myproc(void) {
    800019f4:	1101                	addi	sp,sp,-32
    800019f6:	ec06                	sd	ra,24(sp)
    800019f8:	e822                	sd	s0,16(sp)
    800019fa:	e426                	sd	s1,8(sp)
    800019fc:	1000                	addi	s0,sp,32
  push_off();
    800019fe:	fffff097          	auipc	ra,0xfffff
    80001a02:	18c080e7          	jalr	396(ra) # 80000b8a <push_off>
    80001a06:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a08:	2781                	sext.w	a5,a5
    80001a0a:	079e                	slli	a5,a5,0x7
    80001a0c:	00010717          	auipc	a4,0x10
    80001a10:	89470713          	addi	a4,a4,-1900 # 800112a0 <pid_lock>
    80001a14:	97ba                	add	a5,a5,a4
    80001a16:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	212080e7          	jalr	530(ra) # 80000c2a <pop_off>
}
    80001a20:	8526                	mv	a0,s1
    80001a22:	60e2                	ld	ra,24(sp)
    80001a24:	6442                	ld	s0,16(sp)
    80001a26:	64a2                	ld	s1,8(sp)
    80001a28:	6105                	addi	sp,sp,32
    80001a2a:	8082                	ret

0000000080001a2c <forkret>:
{
    80001a2c:	1141                	addi	sp,sp,-16
    80001a2e:	e406                	sd	ra,8(sp)
    80001a30:	e022                	sd	s0,0(sp)
    80001a32:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a34:	00000097          	auipc	ra,0x0
    80001a38:	fc0080e7          	jalr	-64(ra) # 800019f4 <myproc>
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
  if (first) {
    80001a44:	00007797          	auipc	a5,0x7
    80001a48:	dbc7a783          	lw	a5,-580(a5) # 80008800 <first.1761>
    80001a4c:	eb89                	bnez	a5,80001a5e <forkret+0x32>
  usertrapret();
    80001a4e:	00001097          	auipc	ra,0x1
    80001a52:	e0c080e7          	jalr	-500(ra) # 8000285a <usertrapret>
}
    80001a56:	60a2                	ld	ra,8(sp)
    80001a58:	6402                	ld	s0,0(sp)
    80001a5a:	0141                	addi	sp,sp,16
    80001a5c:	8082                	ret
    first = 0;
    80001a5e:	00007797          	auipc	a5,0x7
    80001a62:	da07a123          	sw	zero,-606(a5) # 80008800 <first.1761>
    fsinit(ROOTDEV);
    80001a66:	4505                	li	a0,1
    80001a68:	00002097          	auipc	ra,0x2
    80001a6c:	c96080e7          	jalr	-874(ra) # 800036fe <fsinit>
    80001a70:	bff9                	j	80001a4e <forkret+0x22>

0000000080001a72 <allocpid>:
allocpid() {
    80001a72:	1101                	addi	sp,sp,-32
    80001a74:	ec06                	sd	ra,24(sp)
    80001a76:	e822                	sd	s0,16(sp)
    80001a78:	e426                	sd	s1,8(sp)
    80001a7a:	e04a                	sd	s2,0(sp)
    80001a7c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a7e:	00010917          	auipc	s2,0x10
    80001a82:	82290913          	addi	s2,s2,-2014 # 800112a0 <pid_lock>
    80001a86:	854a                	mv	a0,s2
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	14e080e7          	jalr	334(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a90:	00007797          	auipc	a5,0x7
    80001a94:	d7478793          	addi	a5,a5,-652 # 80008804 <nextpid>
    80001a98:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a9a:	0014871b          	addiw	a4,s1,1
    80001a9e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aa0:	854a                	mv	a0,s2
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	1e8080e7          	jalr	488(ra) # 80000c8a <release>
}
    80001aaa:	8526                	mv	a0,s1
    80001aac:	60e2                	ld	ra,24(sp)
    80001aae:	6442                	ld	s0,16(sp)
    80001ab0:	64a2                	ld	s1,8(sp)
    80001ab2:	6902                	ld	s2,0(sp)
    80001ab4:	6105                	addi	sp,sp,32
    80001ab6:	8082                	ret

0000000080001ab8 <proc_pagetable>:
{
    80001ab8:	1101                	addi	sp,sp,-32
    80001aba:	ec06                	sd	ra,24(sp)
    80001abc:	e822                	sd	s0,16(sp)
    80001abe:	e426                	sd	s1,8(sp)
    80001ac0:	e04a                	sd	s2,0(sp)
    80001ac2:	1000                	addi	s0,sp,32
    80001ac4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ac6:	00000097          	auipc	ra,0x0
    80001aca:	83a080e7          	jalr	-1990(ra) # 80001300 <uvmcreate>
    80001ace:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ad0:	c121                	beqz	a0,80001b10 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ad2:	4729                	li	a4,10
    80001ad4:	00005697          	auipc	a3,0x5
    80001ad8:	52c68693          	addi	a3,a3,1324 # 80007000 <_trampoline>
    80001adc:	6605                	lui	a2,0x1
    80001ade:	040005b7          	lui	a1,0x4000
    80001ae2:	15fd                	addi	a1,a1,-1
    80001ae4:	05b2                	slli	a1,a1,0xc
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	5c0080e7          	jalr	1472(ra) # 800010a6 <mappages>
    80001aee:	02054863          	bltz	a0,80001b1e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001af2:	4719                	li	a4,6
    80001af4:	05893683          	ld	a3,88(s2)
    80001af8:	6605                	lui	a2,0x1
    80001afa:	020005b7          	lui	a1,0x2000
    80001afe:	15fd                	addi	a1,a1,-1
    80001b00:	05b6                	slli	a1,a1,0xd
    80001b02:	8526                	mv	a0,s1
    80001b04:	fffff097          	auipc	ra,0xfffff
    80001b08:	5a2080e7          	jalr	1442(ra) # 800010a6 <mappages>
    80001b0c:	02054163          	bltz	a0,80001b2e <proc_pagetable+0x76>
}
    80001b10:	8526                	mv	a0,s1
    80001b12:	60e2                	ld	ra,24(sp)
    80001b14:	6442                	ld	s0,16(sp)
    80001b16:	64a2                	ld	s1,8(sp)
    80001b18:	6902                	ld	s2,0(sp)
    80001b1a:	6105                	addi	sp,sp,32
    80001b1c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b1e:	4581                	li	a1,0
    80001b20:	8526                	mv	a0,s1
    80001b22:	00000097          	auipc	ra,0x0
    80001b26:	9da080e7          	jalr	-1574(ra) # 800014fc <uvmfree>
    return 0;
    80001b2a:	4481                	li	s1,0
    80001b2c:	b7d5                	j	80001b10 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b2e:	4681                	li	a3,0
    80001b30:	4605                	li	a2,1
    80001b32:	040005b7          	lui	a1,0x4000
    80001b36:	15fd                	addi	a1,a1,-1
    80001b38:	05b2                	slli	a1,a1,0xc
    80001b3a:	8526                	mv	a0,s1
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	71e080e7          	jalr	1822(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001b44:	4581                	li	a1,0
    80001b46:	8526                	mv	a0,s1
    80001b48:	00000097          	auipc	ra,0x0
    80001b4c:	9b4080e7          	jalr	-1612(ra) # 800014fc <uvmfree>
    return 0;
    80001b50:	4481                	li	s1,0
    80001b52:	bf7d                	j	80001b10 <proc_pagetable+0x58>

0000000080001b54 <proc_freepagetable>:
{
    80001b54:	1101                	addi	sp,sp,-32
    80001b56:	ec06                	sd	ra,24(sp)
    80001b58:	e822                	sd	s0,16(sp)
    80001b5a:	e426                	sd	s1,8(sp)
    80001b5c:	e04a                	sd	s2,0(sp)
    80001b5e:	1000                	addi	s0,sp,32
    80001b60:	84aa                	mv	s1,a0
    80001b62:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b64:	4681                	li	a3,0
    80001b66:	4605                	li	a2,1
    80001b68:	040005b7          	lui	a1,0x4000
    80001b6c:	15fd                	addi	a1,a1,-1
    80001b6e:	05b2                	slli	a1,a1,0xc
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	6ea080e7          	jalr	1770(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b78:	4681                	li	a3,0
    80001b7a:	4605                	li	a2,1
    80001b7c:	020005b7          	lui	a1,0x2000
    80001b80:	15fd                	addi	a1,a1,-1
    80001b82:	05b6                	slli	a1,a1,0xd
    80001b84:	8526                	mv	a0,s1
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	6d4080e7          	jalr	1748(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b8e:	85ca                	mv	a1,s2
    80001b90:	8526                	mv	a0,s1
    80001b92:	00000097          	auipc	ra,0x0
    80001b96:	96a080e7          	jalr	-1686(ra) # 800014fc <uvmfree>
}
    80001b9a:	60e2                	ld	ra,24(sp)
    80001b9c:	6442                	ld	s0,16(sp)
    80001b9e:	64a2                	ld	s1,8(sp)
    80001ba0:	6902                	ld	s2,0(sp)
    80001ba2:	6105                	addi	sp,sp,32
    80001ba4:	8082                	ret

0000000080001ba6 <freeproc>:
{
    80001ba6:	1101                	addi	sp,sp,-32
    80001ba8:	ec06                	sd	ra,24(sp)
    80001baa:	e822                	sd	s0,16(sp)
    80001bac:	e426                	sd	s1,8(sp)
    80001bae:	1000                	addi	s0,sp,32
    80001bb0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bb2:	6d28                	ld	a0,88(a0)
    80001bb4:	c509                	beqz	a0,80001bbe <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	e34080e7          	jalr	-460(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001bbe:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bc2:	68a8                	ld	a0,80(s1)
    80001bc4:	c511                	beqz	a0,80001bd0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bc6:	64ac                	ld	a1,72(s1)
    80001bc8:	00000097          	auipc	ra,0x0
    80001bcc:	f8c080e7          	jalr	-116(ra) # 80001b54 <proc_freepagetable>
  p->pagetable = 0;
    80001bd0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bd4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bd8:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bdc:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001be0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001be4:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001be8:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bec:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bf0:	0004ac23          	sw	zero,24(s1)
}
    80001bf4:	60e2                	ld	ra,24(sp)
    80001bf6:	6442                	ld	s0,16(sp)
    80001bf8:	64a2                	ld	s1,8(sp)
    80001bfa:	6105                	addi	sp,sp,32
    80001bfc:	8082                	ret

0000000080001bfe <allocproc>:
{
    80001bfe:	1101                	addi	sp,sp,-32
    80001c00:	ec06                	sd	ra,24(sp)
    80001c02:	e822                	sd	s0,16(sp)
    80001c04:	e426                	sd	s1,8(sp)
    80001c06:	e04a                	sd	s2,0(sp)
    80001c08:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0a:	00010497          	auipc	s1,0x10
    80001c0e:	aae48493          	addi	s1,s1,-1362 # 800116b8 <proc>
    80001c12:	0001d917          	auipc	s2,0x1d
    80001c16:	4a690913          	addi	s2,s2,1190 # 8001f0b8 <tickslock>
    acquire(&p->lock);
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	fba080e7          	jalr	-70(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001c24:	4c9c                	lw	a5,24(s1)
    80001c26:	cf81                	beqz	a5,80001c3e <allocproc+0x40>
      release(&p->lock);
    80001c28:	8526                	mv	a0,s1
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	060080e7          	jalr	96(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c32:	36848493          	addi	s1,s1,872
    80001c36:	ff2492e3          	bne	s1,s2,80001c1a <allocproc+0x1c>
  return 0;
    80001c3a:	4481                	li	s1,0
    80001c3c:	a0b9                	j	80001c8a <allocproc+0x8c>
  p->pid = allocpid();
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	e34080e7          	jalr	-460(ra) # 80001a72 <allocpid>
    80001c46:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	e9e080e7          	jalr	-354(ra) # 80000ae6 <kalloc>
    80001c50:	892a                	mv	s2,a0
    80001c52:	eca8                	sd	a0,88(s1)
    80001c54:	c131                	beqz	a0,80001c98 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c56:	8526                	mv	a0,s1
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	e60080e7          	jalr	-416(ra) # 80001ab8 <proc_pagetable>
    80001c60:	892a                	mv	s2,a0
    80001c62:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c64:	c129                	beqz	a0,80001ca6 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c66:	07000613          	li	a2,112
    80001c6a:	4581                	li	a1,0
    80001c6c:	06048513          	addi	a0,s1,96
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	062080e7          	jalr	98(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c78:	00000797          	auipc	a5,0x0
    80001c7c:	db478793          	addi	a5,a5,-588 # 80001a2c <forkret>
    80001c80:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c82:	60bc                	ld	a5,64(s1)
    80001c84:	6705                	lui	a4,0x1
    80001c86:	97ba                	add	a5,a5,a4
    80001c88:	f4bc                	sd	a5,104(s1)
}
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	60e2                	ld	ra,24(sp)
    80001c8e:	6442                	ld	s0,16(sp)
    80001c90:	64a2                	ld	s1,8(sp)
    80001c92:	6902                	ld	s2,0(sp)
    80001c94:	6105                	addi	sp,sp,32
    80001c96:	8082                	ret
    release(&p->lock);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	ff0080e7          	jalr	-16(ra) # 80000c8a <release>
    return 0;
    80001ca2:	84ca                	mv	s1,s2
    80001ca4:	b7dd                	j	80001c8a <allocproc+0x8c>
    freeproc(p);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	efe080e7          	jalr	-258(ra) # 80001ba6 <freeproc>
    release(&p->lock);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	fd8080e7          	jalr	-40(ra) # 80000c8a <release>
    return 0;
    80001cba:	84ca                	mv	s1,s2
    80001cbc:	b7f9                	j	80001c8a <allocproc+0x8c>

0000000080001cbe <userinit>:
{
    80001cbe:	1101                	addi	sp,sp,-32
    80001cc0:	ec06                	sd	ra,24(sp)
    80001cc2:	e822                	sd	s0,16(sp)
    80001cc4:	e426                	sd	s1,8(sp)
    80001cc6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc8:	00000097          	auipc	ra,0x0
    80001ccc:	f36080e7          	jalr	-202(ra) # 80001bfe <allocproc>
    80001cd0:	84aa                	mv	s1,a0
  initproc = p;
    80001cd2:	00007797          	auipc	a5,0x7
    80001cd6:	34a7bb23          	sd	a0,854(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cda:	03400613          	li	a2,52
    80001cde:	00007597          	auipc	a1,0x7
    80001ce2:	b3258593          	addi	a1,a1,-1230 # 80008810 <initcode>
    80001ce6:	6928                	ld	a0,80(a0)
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	646080e7          	jalr	1606(ra) # 8000132e <uvminit>
  p->sz = PGSIZE;
    80001cf0:	6785                	lui	a5,0x1
    80001cf2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cf4:	6cb8                	ld	a4,88(s1)
    80001cf6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cfa:	6cb8                	ld	a4,88(s1)
    80001cfc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cfe:	4641                	li	a2,16
    80001d00:	00006597          	auipc	a1,0x6
    80001d04:	4b058593          	addi	a1,a1,1200 # 800081b0 <digits+0x170>
    80001d08:	15848513          	addi	a0,s1,344
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	11c080e7          	jalr	284(ra) # 80000e28 <safestrcpy>
  p->cwd = namei("/");
    80001d14:	00006517          	auipc	a0,0x6
    80001d18:	4ac50513          	addi	a0,a0,1196 # 800081c0 <digits+0x180>
    80001d1c:	00002097          	auipc	ra,0x2
    80001d20:	410080e7          	jalr	1040(ra) # 8000412c <namei>
    80001d24:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d28:	4789                	li	a5,2
    80001d2a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d2c:	8526                	mv	a0,s1
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	f5c080e7          	jalr	-164(ra) # 80000c8a <release>
}
    80001d36:	60e2                	ld	ra,24(sp)
    80001d38:	6442                	ld	s0,16(sp)
    80001d3a:	64a2                	ld	s1,8(sp)
    80001d3c:	6105                	addi	sp,sp,32
    80001d3e:	8082                	ret

0000000080001d40 <growproc>:
{
    80001d40:	1101                	addi	sp,sp,-32
    80001d42:	ec06                	sd	ra,24(sp)
    80001d44:	e822                	sd	s0,16(sp)
    80001d46:	e426                	sd	s1,8(sp)
    80001d48:	e04a                	sd	s2,0(sp)
    80001d4a:	1000                	addi	s0,sp,32
    80001d4c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	ca6080e7          	jalr	-858(ra) # 800019f4 <myproc>
    80001d56:	892a                	mv	s2,a0
  sz = p->sz;
    80001d58:	652c                	ld	a1,72(a0)
    80001d5a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d5e:	00904f63          	bgtz	s1,80001d7c <growproc+0x3c>
  } else if(n < 0){
    80001d62:	0204cc63          	bltz	s1,80001d9a <growproc+0x5a>
  p->sz = sz;
    80001d66:	1602                	slli	a2,a2,0x20
    80001d68:	9201                	srli	a2,a2,0x20
    80001d6a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d6e:	4501                	li	a0,0
}
    80001d70:	60e2                	ld	ra,24(sp)
    80001d72:	6442                	ld	s0,16(sp)
    80001d74:	64a2                	ld	s1,8(sp)
    80001d76:	6902                	ld	s2,0(sp)
    80001d78:	6105                	addi	sp,sp,32
    80001d7a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d7c:	9e25                	addw	a2,a2,s1
    80001d7e:	1602                	slli	a2,a2,0x20
    80001d80:	9201                	srli	a2,a2,0x20
    80001d82:	1582                	slli	a1,a1,0x20
    80001d84:	9181                	srli	a1,a1,0x20
    80001d86:	6928                	ld	a0,80(a0)
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	660080e7          	jalr	1632(ra) # 800013e8 <uvmalloc>
    80001d90:	0005061b          	sext.w	a2,a0
    80001d94:	fa69                	bnez	a2,80001d66 <growproc+0x26>
      return -1;
    80001d96:	557d                	li	a0,-1
    80001d98:	bfe1                	j	80001d70 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d9a:	9e25                	addw	a2,a2,s1
    80001d9c:	1602                	slli	a2,a2,0x20
    80001d9e:	9201                	srli	a2,a2,0x20
    80001da0:	1582                	slli	a1,a1,0x20
    80001da2:	9181                	srli	a1,a1,0x20
    80001da4:	6928                	ld	a0,80(a0)
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	5fa080e7          	jalr	1530(ra) # 800013a0 <uvmdealloc>
    80001dae:	0005061b          	sext.w	a2,a0
    80001db2:	bf55                	j	80001d66 <growproc+0x26>

0000000080001db4 <fork>:
{
    80001db4:	7139                	addi	sp,sp,-64
    80001db6:	fc06                	sd	ra,56(sp)
    80001db8:	f822                	sd	s0,48(sp)
    80001dba:	f426                	sd	s1,40(sp)
    80001dbc:	f04a                	sd	s2,32(sp)
    80001dbe:	ec4e                	sd	s3,24(sp)
    80001dc0:	e852                	sd	s4,16(sp)
    80001dc2:	e456                	sd	s5,8(sp)
    80001dc4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dc6:	00000097          	auipc	ra,0x0
    80001dca:	c2e080e7          	jalr	-978(ra) # 800019f4 <myproc>
    80001dce:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	e2e080e7          	jalr	-466(ra) # 80001bfe <allocproc>
    80001dd8:	12050463          	beqz	a0,80001f00 <fork+0x14c>
    80001ddc:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dde:	0489b603          	ld	a2,72(s3)
    80001de2:	692c                	ld	a1,80(a0)
    80001de4:	0509b503          	ld	a0,80(s3)
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	74c080e7          	jalr	1868(ra) # 80001534 <uvmcopy>
    80001df0:	04054863          	bltz	a0,80001e40 <fork+0x8c>
  np->sz = p->sz;
    80001df4:	0489b783          	ld	a5,72(s3)
    80001df8:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001dfc:	033a3023          	sd	s3,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e00:	0589b683          	ld	a3,88(s3)
    80001e04:	87b6                	mv	a5,a3
    80001e06:	058a3703          	ld	a4,88(s4)
    80001e0a:	12068693          	addi	a3,a3,288
    80001e0e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e12:	6788                	ld	a0,8(a5)
    80001e14:	6b8c                	ld	a1,16(a5)
    80001e16:	6f90                	ld	a2,24(a5)
    80001e18:	01073023          	sd	a6,0(a4)
    80001e1c:	e708                	sd	a0,8(a4)
    80001e1e:	eb0c                	sd	a1,16(a4)
    80001e20:	ef10                	sd	a2,24(a4)
    80001e22:	02078793          	addi	a5,a5,32
    80001e26:	02070713          	addi	a4,a4,32
    80001e2a:	fed792e3          	bne	a5,a3,80001e0e <fork+0x5a>
  np->trapframe->a0 = 0;
    80001e2e:	058a3783          	ld	a5,88(s4)
    80001e32:	0607b823          	sd	zero,112(a5)
    80001e36:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e3a:	15000913          	li	s2,336
    80001e3e:	a03d                	j	80001e6c <fork+0xb8>
    freeproc(np);
    80001e40:	8552                	mv	a0,s4
    80001e42:	00000097          	auipc	ra,0x0
    80001e46:	d64080e7          	jalr	-668(ra) # 80001ba6 <freeproc>
    release(&np->lock);
    80001e4a:	8552                	mv	a0,s4
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	e3e080e7          	jalr	-450(ra) # 80000c8a <release>
    return -1;
    80001e54:	54fd                	li	s1,-1
    80001e56:	a859                	j	80001eec <fork+0x138>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e58:	00003097          	auipc	ra,0x3
    80001e5c:	972080e7          	jalr	-1678(ra) # 800047ca <filedup>
    80001e60:	009a07b3          	add	a5,s4,s1
    80001e64:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e66:	04a1                	addi	s1,s1,8
    80001e68:	01248763          	beq	s1,s2,80001e76 <fork+0xc2>
    if(p->ofile[i])
    80001e6c:	009987b3          	add	a5,s3,s1
    80001e70:	6388                	ld	a0,0(a5)
    80001e72:	f17d                	bnez	a0,80001e58 <fork+0xa4>
    80001e74:	bfcd                	j	80001e66 <fork+0xb2>
  np->cwd = idup(p->cwd);
    80001e76:	1509b503          	ld	a0,336(s3)
    80001e7a:	00002097          	auipc	ra,0x2
    80001e7e:	abe080e7          	jalr	-1346(ra) # 80003938 <idup>
    80001e82:	14aa3823          	sd	a0,336(s4)
  for (i = 0; i < NVMA; ++i) {
    80001e86:	16898493          	addi	s1,s3,360
    80001e8a:	180a0913          	addi	s2,s4,384
    80001e8e:	36898a93          	addi	s5,s3,872
    80001e92:	a03d                	j	80001ec0 <fork+0x10c>
      np->vma_list[i] = p->vma_list[i];
    80001e94:	86be                	mv	a3,a5
    80001e96:	6498                	ld	a4,8(s1)
    80001e98:	689c                	ld	a5,16(s1)
    80001e9a:	6c88                	ld	a0,24(s1)
    80001e9c:	fed93423          	sd	a3,-24(s2)
    80001ea0:	fee93823          	sd	a4,-16(s2)
    80001ea4:	fef93c23          	sd	a5,-8(s2)
    80001ea8:	00a93023          	sd	a0,0(s2)
      filedup(np->vma_list[i].f);
    80001eac:	00003097          	auipc	ra,0x3
    80001eb0:	91e080e7          	jalr	-1762(ra) # 800047ca <filedup>
  for (i = 0; i < NVMA; ++i) {
    80001eb4:	02048493          	addi	s1,s1,32
    80001eb8:	02090913          	addi	s2,s2,32
    80001ebc:	01548563          	beq	s1,s5,80001ec6 <fork+0x112>
    if (p->vma_list[i].addr) {
    80001ec0:	609c                	ld	a5,0(s1)
    80001ec2:	dbed                	beqz	a5,80001eb4 <fork+0x100>
    80001ec4:	bfc1                	j	80001e94 <fork+0xe0>
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ec6:	4641                	li	a2,16
    80001ec8:	15898593          	addi	a1,s3,344
    80001ecc:	158a0513          	addi	a0,s4,344
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	f58080e7          	jalr	-168(ra) # 80000e28 <safestrcpy>
  pid = np->pid;
    80001ed8:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001edc:	4789                	li	a5,2
    80001ede:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ee2:	8552                	mv	a0,s4
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	da6080e7          	jalr	-602(ra) # 80000c8a <release>
}
    80001eec:	8526                	mv	a0,s1
    80001eee:	70e2                	ld	ra,56(sp)
    80001ef0:	7442                	ld	s0,48(sp)
    80001ef2:	74a2                	ld	s1,40(sp)
    80001ef4:	7902                	ld	s2,32(sp)
    80001ef6:	69e2                	ld	s3,24(sp)
    80001ef8:	6a42                	ld	s4,16(sp)
    80001efa:	6aa2                	ld	s5,8(sp)
    80001efc:	6121                	addi	sp,sp,64
    80001efe:	8082                	ret
    return -1;
    80001f00:	54fd                	li	s1,-1
    80001f02:	b7ed                	j	80001eec <fork+0x138>

0000000080001f04 <reparent>:
{
    80001f04:	7179                	addi	sp,sp,-48
    80001f06:	f406                	sd	ra,40(sp)
    80001f08:	f022                	sd	s0,32(sp)
    80001f0a:	ec26                	sd	s1,24(sp)
    80001f0c:	e84a                	sd	s2,16(sp)
    80001f0e:	e44e                	sd	s3,8(sp)
    80001f10:	e052                	sd	s4,0(sp)
    80001f12:	1800                	addi	s0,sp,48
    80001f14:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f16:	0000f497          	auipc	s1,0xf
    80001f1a:	7a248493          	addi	s1,s1,1954 # 800116b8 <proc>
      pp->parent = initproc;
    80001f1e:	00007a17          	auipc	s4,0x7
    80001f22:	10aa0a13          	addi	s4,s4,266 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f26:	0001d997          	auipc	s3,0x1d
    80001f2a:	19298993          	addi	s3,s3,402 # 8001f0b8 <tickslock>
    80001f2e:	a029                	j	80001f38 <reparent+0x34>
    80001f30:	36848493          	addi	s1,s1,872
    80001f34:	03348363          	beq	s1,s3,80001f5a <reparent+0x56>
    if(pp->parent == p){
    80001f38:	709c                	ld	a5,32(s1)
    80001f3a:	ff279be3          	bne	a5,s2,80001f30 <reparent+0x2c>
      acquire(&pp->lock);
    80001f3e:	8526                	mv	a0,s1
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	c96080e7          	jalr	-874(ra) # 80000bd6 <acquire>
      pp->parent = initproc;
    80001f48:	000a3783          	ld	a5,0(s4)
    80001f4c:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f4e:	8526                	mv	a0,s1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	d3a080e7          	jalr	-710(ra) # 80000c8a <release>
    80001f58:	bfe1                	j	80001f30 <reparent+0x2c>
}
    80001f5a:	70a2                	ld	ra,40(sp)
    80001f5c:	7402                	ld	s0,32(sp)
    80001f5e:	64e2                	ld	s1,24(sp)
    80001f60:	6942                	ld	s2,16(sp)
    80001f62:	69a2                	ld	s3,8(sp)
    80001f64:	6a02                	ld	s4,0(sp)
    80001f66:	6145                	addi	sp,sp,48
    80001f68:	8082                	ret

0000000080001f6a <scheduler>:
{
    80001f6a:	711d                	addi	sp,sp,-96
    80001f6c:	ec86                	sd	ra,88(sp)
    80001f6e:	e8a2                	sd	s0,80(sp)
    80001f70:	e4a6                	sd	s1,72(sp)
    80001f72:	e0ca                	sd	s2,64(sp)
    80001f74:	fc4e                	sd	s3,56(sp)
    80001f76:	f852                	sd	s4,48(sp)
    80001f78:	f456                	sd	s5,40(sp)
    80001f7a:	f05a                	sd	s6,32(sp)
    80001f7c:	ec5e                	sd	s7,24(sp)
    80001f7e:	e862                	sd	s8,16(sp)
    80001f80:	e466                	sd	s9,8(sp)
    80001f82:	1080                	addi	s0,sp,96
    80001f84:	8792                	mv	a5,tp
  int id = r_tp();
    80001f86:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f88:	00779c13          	slli	s8,a5,0x7
    80001f8c:	0000f717          	auipc	a4,0xf
    80001f90:	31470713          	addi	a4,a4,788 # 800112a0 <pid_lock>
    80001f94:	9762                	add	a4,a4,s8
    80001f96:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f9a:	0000f717          	auipc	a4,0xf
    80001f9e:	32670713          	addi	a4,a4,806 # 800112c0 <cpus+0x8>
    80001fa2:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80001fa4:	4a89                	li	s5,2
        c->proc = p;
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000fb17          	auipc	s6,0xf
    80001fac:	2f8b0b13          	addi	s6,s6,760 # 800112a0 <pid_lock>
    80001fb0:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb2:	0001da17          	auipc	s4,0x1d
    80001fb6:	106a0a13          	addi	s4,s4,262 # 8001f0b8 <tickslock>
    int nproc = 0;
    80001fba:	4c81                	li	s9,0
    80001fbc:	a8a1                	j	80002014 <scheduler+0xaa>
        p->state = RUNNING;
    80001fbe:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001fc2:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80001fc6:	06048593          	addi	a1,s1,96
    80001fca:	8562                	mv	a0,s8
    80001fcc:	00000097          	auipc	ra,0x0
    80001fd0:	7e4080e7          	jalr	2020(ra) # 800027b0 <swtch>
        c->proc = 0;
    80001fd4:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80001fd8:	8526                	mv	a0,s1
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	cb0080e7          	jalr	-848(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe2:	36848493          	addi	s1,s1,872
    80001fe6:	01448d63          	beq	s1,s4,80002000 <scheduler+0x96>
      acquire(&p->lock);
    80001fea:	8526                	mv	a0,s1
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	bea080e7          	jalr	-1046(ra) # 80000bd6 <acquire>
      if(p->state != UNUSED) {
    80001ff4:	4c9c                	lw	a5,24(s1)
    80001ff6:	d3ed                	beqz	a5,80001fd8 <scheduler+0x6e>
        nproc++;
    80001ff8:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80001ffa:	fd579fe3          	bne	a5,s5,80001fd8 <scheduler+0x6e>
    80001ffe:	b7c1                	j	80001fbe <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002000:	013aca63          	blt	s5,s3,80002014 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002004:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002008:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000200c:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002010:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002014:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002018:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000201c:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002020:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002022:	0000f497          	auipc	s1,0xf
    80002026:	69648493          	addi	s1,s1,1686 # 800116b8 <proc>
        p->state = RUNNING;
    8000202a:	4b8d                	li	s7,3
    8000202c:	bf7d                	j	80001fea <scheduler+0x80>

000000008000202e <sched>:
{
    8000202e:	7179                	addi	sp,sp,-48
    80002030:	f406                	sd	ra,40(sp)
    80002032:	f022                	sd	s0,32(sp)
    80002034:	ec26                	sd	s1,24(sp)
    80002036:	e84a                	sd	s2,16(sp)
    80002038:	e44e                	sd	s3,8(sp)
    8000203a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000203c:	00000097          	auipc	ra,0x0
    80002040:	9b8080e7          	jalr	-1608(ra) # 800019f4 <myproc>
    80002044:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	b16080e7          	jalr	-1258(ra) # 80000b5c <holding>
    8000204e:	c93d                	beqz	a0,800020c4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002050:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002052:	2781                	sext.w	a5,a5
    80002054:	079e                	slli	a5,a5,0x7
    80002056:	0000f717          	auipc	a4,0xf
    8000205a:	24a70713          	addi	a4,a4,586 # 800112a0 <pid_lock>
    8000205e:	97ba                	add	a5,a5,a4
    80002060:	0907a703          	lw	a4,144(a5)
    80002064:	4785                	li	a5,1
    80002066:	06f71763          	bne	a4,a5,800020d4 <sched+0xa6>
  if(p->state == RUNNING)
    8000206a:	4c98                	lw	a4,24(s1)
    8000206c:	478d                	li	a5,3
    8000206e:	06f70b63          	beq	a4,a5,800020e4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002072:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002076:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002078:	efb5                	bnez	a5,800020f4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000207a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000207c:	0000f917          	auipc	s2,0xf
    80002080:	22490913          	addi	s2,s2,548 # 800112a0 <pid_lock>
    80002084:	2781                	sext.w	a5,a5
    80002086:	079e                	slli	a5,a5,0x7
    80002088:	97ca                	add	a5,a5,s2
    8000208a:	0947a983          	lw	s3,148(a5)
    8000208e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002090:	2781                	sext.w	a5,a5
    80002092:	079e                	slli	a5,a5,0x7
    80002094:	0000f597          	auipc	a1,0xf
    80002098:	22c58593          	addi	a1,a1,556 # 800112c0 <cpus+0x8>
    8000209c:	95be                	add	a1,a1,a5
    8000209e:	06048513          	addi	a0,s1,96
    800020a2:	00000097          	auipc	ra,0x0
    800020a6:	70e080e7          	jalr	1806(ra) # 800027b0 <swtch>
    800020aa:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020ac:	2781                	sext.w	a5,a5
    800020ae:	079e                	slli	a5,a5,0x7
    800020b0:	97ca                	add	a5,a5,s2
    800020b2:	0937aa23          	sw	s3,148(a5)
}
    800020b6:	70a2                	ld	ra,40(sp)
    800020b8:	7402                	ld	s0,32(sp)
    800020ba:	64e2                	ld	s1,24(sp)
    800020bc:	6942                	ld	s2,16(sp)
    800020be:	69a2                	ld	s3,8(sp)
    800020c0:	6145                	addi	sp,sp,48
    800020c2:	8082                	ret
    panic("sched p->lock");
    800020c4:	00006517          	auipc	a0,0x6
    800020c8:	10450513          	addi	a0,a0,260 # 800081c8 <digits+0x188>
    800020cc:	ffffe097          	auipc	ra,0xffffe
    800020d0:	464080e7          	jalr	1124(ra) # 80000530 <panic>
    panic("sched locks");
    800020d4:	00006517          	auipc	a0,0x6
    800020d8:	10450513          	addi	a0,a0,260 # 800081d8 <digits+0x198>
    800020dc:	ffffe097          	auipc	ra,0xffffe
    800020e0:	454080e7          	jalr	1108(ra) # 80000530 <panic>
    panic("sched running");
    800020e4:	00006517          	auipc	a0,0x6
    800020e8:	10450513          	addi	a0,a0,260 # 800081e8 <digits+0x1a8>
    800020ec:	ffffe097          	auipc	ra,0xffffe
    800020f0:	444080e7          	jalr	1092(ra) # 80000530 <panic>
    panic("sched interruptible");
    800020f4:	00006517          	auipc	a0,0x6
    800020f8:	10450513          	addi	a0,a0,260 # 800081f8 <digits+0x1b8>
    800020fc:	ffffe097          	auipc	ra,0xffffe
    80002100:	434080e7          	jalr	1076(ra) # 80000530 <panic>

0000000080002104 <exit>:
{
    80002104:	7135                	addi	sp,sp,-160
    80002106:	ed06                	sd	ra,152(sp)
    80002108:	e922                	sd	s0,144(sp)
    8000210a:	e526                	sd	s1,136(sp)
    8000210c:	e14a                	sd	s2,128(sp)
    8000210e:	fcce                	sd	s3,120(sp)
    80002110:	f8d2                	sd	s4,112(sp)
    80002112:	f4d6                	sd	s5,104(sp)
    80002114:	f0da                	sd	s6,96(sp)
    80002116:	ecde                	sd	s7,88(sp)
    80002118:	e8e2                	sd	s8,80(sp)
    8000211a:	e4e6                	sd	s9,72(sp)
    8000211c:	e0ea                	sd	s10,64(sp)
    8000211e:	fc6e                	sd	s11,56(sp)
    80002120:	1100                	addi	s0,sp,160
    80002122:	f6a43423          	sd	a0,-152(s0)
  struct proc *p = myproc();
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	8ce080e7          	jalr	-1842(ra) # 800019f4 <myproc>
    8000212e:	f6a43c23          	sd	a0,-136(s0)
  if(p == initproc)
    80002132:	00007797          	auipc	a5,0x7
    80002136:	ef67b783          	ld	a5,-266(a5) # 80009028 <initproc>
    8000213a:	f8043023          	sd	zero,-128(s0)
    8000213e:	00a78c63          	beq	a5,a0,80002156 <exit+0x52>
    80002142:	16850c93          	addi	s9,a0,360
          n1 = min(maxsz, n - i);
    80002146:	6785                	lui	a5,0x1
    80002148:	c0078d93          	addi	s11,a5,-1024 # c00 <_entry-0x7ffff400>
    8000214c:	c007879b          	addiw	a5,a5,-1024
    80002150:	f8f42423          	sw	a5,-120(s0)
    80002154:	aa99                	j	800022aa <exit+0x1a6>
    panic("init exiting");
    80002156:	00006517          	auipc	a0,0x6
    8000215a:	0ba50513          	addi	a0,a0,186 # 80008210 <digits+0x1d0>
    8000215e:	ffffe097          	auipc	ra,0xffffe
    80002162:	3d2080e7          	jalr	978(ra) # 80000530 <panic>
          n1 = min(maxsz, n - i);
    80002166:	0009891b          	sext.w	s2,s3
          begin_op();
    8000216a:	00002097          	auipc	ra,0x2
    8000216e:	1de080e7          	jalr	478(ra) # 80004348 <begin_op>
          ilock(vma->f->ip);
    80002172:	6c9c                	ld	a5,24(s1)
    80002174:	6f88                	ld	a0,24(a5)
    80002176:	00002097          	auipc	ra,0x2
    8000217a:	800080e7          	jalr	-2048(ra) # 80003976 <ilock>
          if (writei(vma->f->ip, 1, va + i, va - vma->addr + vma->offset + i, n1) != n1) {
    8000217e:	48d4                	lw	a3,20(s1)
    80002180:	017686bb          	addw	a3,a3,s7
    80002184:	609c                	ld	a5,0(s1)
    80002186:	9e9d                	subw	a3,a3,a5
    80002188:	6c9c                	ld	a5,24(s1)
    8000218a:	874a                	mv	a4,s2
    8000218c:	015686bb          	addw	a3,a3,s5
    80002190:	8662                	mv	a2,s8
    80002192:	4585                	li	a1,1
    80002194:	6f88                	ld	a0,24(a5)
    80002196:	00002097          	auipc	ra,0x2
    8000219a:	b8c080e7          	jalr	-1140(ra) # 80003d22 <writei>
    8000219e:	2501                	sext.w	a0,a0
    800021a0:	03251763          	bne	a0,s2,800021ce <exit+0xca>
          iunlock(vma->f->ip);
    800021a4:	6c9c                	ld	a5,24(s1)
    800021a6:	6f88                	ld	a0,24(a5)
    800021a8:	00002097          	auipc	ra,0x2
    800021ac:	890080e7          	jalr	-1904(ra) # 80003a38 <iunlock>
          end_op();
    800021b0:	00002097          	auipc	ra,0x2
    800021b4:	218080e7          	jalr	536(ra) # 800043c8 <end_op>
        for (r = 0; r < n; r += n1) {
    800021b8:	01498a3b          	addw	s4,s3,s4
    800021bc:	056a7363          	bgeu	s4,s6,80002202 <exit+0xfe>
          n1 = min(maxsz, n - i);
    800021c0:	f8c42983          	lw	s3,-116(s0)
    800021c4:	fbadf1e3          	bgeu	s11,s10,80002166 <exit+0x62>
    800021c8:	f8842983          	lw	s3,-120(s0)
    800021cc:	bf69                	j	80002166 <exit+0x62>
            iunlock(vma->f->ip);
    800021ce:	f7043783          	ld	a5,-144(s0)
    800021d2:	00579513          	slli	a0,a5,0x5
    800021d6:	f7843783          	ld	a5,-136(s0)
    800021da:	953e                	add	a0,a0,a5
    800021dc:	18053783          	ld	a5,384(a0)
    800021e0:	6f88                	ld	a0,24(a5)
    800021e2:	00002097          	auipc	ra,0x2
    800021e6:	856080e7          	jalr	-1962(ra) # 80003a38 <iunlock>
            end_op();
    800021ea:	00002097          	auipc	ra,0x2
    800021ee:	1de080e7          	jalr	478(ra) # 800043c8 <end_op>
            panic("exit: writei failed");
    800021f2:	00006517          	auipc	a0,0x6
    800021f6:	02e50513          	addi	a0,a0,46 # 80008220 <digits+0x1e0>
    800021fa:	ffffe097          	auipc	ra,0xffffe
    800021fe:	336080e7          	jalr	822(ra) # 80000530 <panic>
      for (va = vma->addr; va < vma->addr + vma->len; va += PGSIZE) {
    80002202:	6785                	lui	a5,0x1
    80002204:	9abe                	add	s5,s5,a5
    80002206:	9c3e                	add	s8,s8,a5
    80002208:	449c                	lw	a5,8(s1)
    8000220a:	6098                	ld	a4,0(s1)
    8000220c:	97ba                	add	a5,a5,a4
    8000220e:	04faf063          	bgeu	s5,a5,8000224e <exit+0x14a>
        if (uvmgetdirty(p->pagetable, va) == 0) {
    80002212:	85d6                	mv	a1,s5
    80002214:	f7843783          	ld	a5,-136(s0)
    80002218:	6ba8                	ld	a0,80(a5)
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	5ea080e7          	jalr	1514(ra) # 80001804 <uvmgetdirty>
    80002222:	d165                	beqz	a0,80002202 <exit+0xfe>
        n = min(PGSIZE, vma->addr + vma->len - va);
    80002224:	0084ab03          	lw	s6,8(s1)
    80002228:	609c                	ld	a5,0(s1)
    8000222a:	9b3e                	add	s6,s6,a5
    8000222c:	415b0b33          	sub	s6,s6,s5
    80002230:	6785                	lui	a5,0x1
    80002232:	0167f363          	bgeu	a5,s6,80002238 <exit+0x134>
    80002236:	6b05                	lui	s6,0x1
    80002238:	2b01                	sext.w	s6,s6
        for (r = 0; r < n; r += n1) {
    8000223a:	fc0b04e3          	beqz	s6,80002202 <exit+0xfe>
    8000223e:	4a01                	li	s4,0
          n1 = min(maxsz, n - i);
    80002240:	417b07bb          	subw	a5,s6,s7
    80002244:	f8f42623          	sw	a5,-116(s0)
    80002248:	00078d1b          	sext.w	s10,a5
    8000224c:	bf95                	j	800021c0 <exit+0xbc>
    uvmunmap(p->pagetable, vma->addr, (vma->len - 1) / PGSIZE + 1, 1);
    8000224e:	4490                	lw	a2,8(s1)
    80002250:	fff6079b          	addiw	a5,a2,-1
    80002254:	41f7d61b          	sraiw	a2,a5,0x1f
    80002258:	0146561b          	srliw	a2,a2,0x14
    8000225c:	9e3d                	addw	a2,a2,a5
    8000225e:	40c6561b          	sraiw	a2,a2,0xc
    80002262:	4685                	li	a3,1
    80002264:	2605                	addiw	a2,a2,1
    80002266:	608c                	ld	a1,0(s1)
    80002268:	f7843783          	ld	a5,-136(s0)
    8000226c:	6ba8                	ld	a0,80(a5)
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	fec080e7          	jalr	-20(ra) # 8000125a <uvmunmap>
    vma->addr = 0;
    80002276:	0004b023          	sd	zero,0(s1)
    vma->len = 0;
    8000227a:	0004a423          	sw	zero,8(s1)
    vma->offset = 0;
    8000227e:	0004aa23          	sw	zero,20(s1)
    vma->flags = 0;
    80002282:	0004a823          	sw	zero,16(s1)
    fileclose(vma->f);
    80002286:	6c88                	ld	a0,24(s1)
    80002288:	00002097          	auipc	ra,0x2
    8000228c:	594080e7          	jalr	1428(ra) # 8000481c <fileclose>
    vma->f = 0;
    80002290:	0004bc23          	sd	zero,24(s1)
  for (i = 0; i < NVMA; ++i) {
    80002294:	f8043783          	ld	a5,-128(s0)
    80002298:	0785                	addi	a5,a5,1
    8000229a:	873e                	mv	a4,a5
    8000229c:	f8f43023          	sd	a5,-128(s0)
    800022a0:	020c8c93          	addi	s9,s9,32
    800022a4:	47c1                	li	a5,16
    800022a6:	02f70963          	beq	a4,a5,800022d8 <exit+0x1d4>
    800022aa:	f8043683          	ld	a3,-128(s0)
    800022ae:	00068b9b          	sext.w	s7,a3
    800022b2:	f7743823          	sd	s7,-144(s0)
    if (p->vma_list[i].addr == 0) {
    800022b6:	84e6                	mv	s1,s9
    800022b8:	000cba83          	ld	s5,0(s9)
    800022bc:	fc0a8ce3          	beqz	s5,80002294 <exit+0x190>
    if ((vma->flags & MAP_SHARED)) {
    800022c0:	010ca783          	lw	a5,16(s9)
    800022c4:	8b85                	andi	a5,a5,1
    800022c6:	d7c1                	beqz	a5,8000224e <exit+0x14a>
      for (va = vma->addr; va < vma->addr + vma->len; va += PGSIZE) {
    800022c8:	008ca783          	lw	a5,8(s9)
    800022cc:	97d6                	add	a5,a5,s5
    800022ce:	f8faf0e3          	bgeu	s5,a5,8000224e <exit+0x14a>
    800022d2:	00da8c33          	add	s8,s5,a3
    800022d6:	bf35                	j	80002212 <exit+0x10e>
    800022d8:	f7843783          	ld	a5,-136(s0)
    800022dc:	0d078493          	addi	s1,a5,208 # 10d0 <_entry-0x7fffef30>
    800022e0:	15078913          	addi	s2,a5,336
    800022e4:	a811                	j	800022f8 <exit+0x1f4>
      fileclose(f);
    800022e6:	00002097          	auipc	ra,0x2
    800022ea:	536080e7          	jalr	1334(ra) # 8000481c <fileclose>
      p->ofile[fd] = 0;
    800022ee:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022f2:	04a1                	addi	s1,s1,8
    800022f4:	00990563          	beq	s2,s1,800022fe <exit+0x1fa>
    if(p->ofile[fd]){
    800022f8:	6088                	ld	a0,0(s1)
    800022fa:	f575                	bnez	a0,800022e6 <exit+0x1e2>
    800022fc:	bfdd                	j	800022f2 <exit+0x1ee>
  begin_op();
    800022fe:	00002097          	auipc	ra,0x2
    80002302:	04a080e7          	jalr	74(ra) # 80004348 <begin_op>
  iput(p->cwd);
    80002306:	f7843903          	ld	s2,-136(s0)
    8000230a:	15093503          	ld	a0,336(s2)
    8000230e:	00002097          	auipc	ra,0x2
    80002312:	822080e7          	jalr	-2014(ra) # 80003b30 <iput>
  end_op();
    80002316:	00002097          	auipc	ra,0x2
    8000231a:	0b2080e7          	jalr	178(ra) # 800043c8 <end_op>
  p->cwd = 0;
    8000231e:	14093823          	sd	zero,336(s2)
  acquire(&initproc->lock);
    80002322:	00007497          	auipc	s1,0x7
    80002326:	d0648493          	addi	s1,s1,-762 # 80009028 <initproc>
    8000232a:	6088                	ld	a0,0(s1)
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	8aa080e7          	jalr	-1878(ra) # 80000bd6 <acquire>
  wakeup1(initproc);
    80002334:	6088                	ld	a0,0(s1)
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	520080e7          	jalr	1312(ra) # 80001856 <wakeup1>
  release(&initproc->lock);
    8000233e:	6088                	ld	a0,0(s1)
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	94a080e7          	jalr	-1718(ra) # 80000c8a <release>
  acquire(&p->lock);
    80002348:	854a                	mv	a0,s2
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	88c080e7          	jalr	-1908(ra) # 80000bd6 <acquire>
  struct proc *original_parent = p->parent;
    80002352:	02093483          	ld	s1,32(s2)
  release(&p->lock);
    80002356:	854a                	mv	a0,s2
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	932080e7          	jalr	-1742(ra) # 80000c8a <release>
  acquire(&original_parent->lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	874080e7          	jalr	-1932(ra) # 80000bd6 <acquire>
  acquire(&p->lock);
    8000236a:	854a                	mv	a0,s2
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	86a080e7          	jalr	-1942(ra) # 80000bd6 <acquire>
  reparent(p);
    80002374:	854a                	mv	a0,s2
    80002376:	00000097          	auipc	ra,0x0
    8000237a:	b8e080e7          	jalr	-1138(ra) # 80001f04 <reparent>
  wakeup1(original_parent);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	4d6080e7          	jalr	1238(ra) # 80001856 <wakeup1>
  p->xstate = status;
    80002388:	f6843783          	ld	a5,-152(s0)
    8000238c:	02f92a23          	sw	a5,52(s2)
  p->state = ZOMBIE;
    80002390:	4791                	li	a5,4
    80002392:	00f92c23          	sw	a5,24(s2)
  release(&original_parent->lock);
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	8f2080e7          	jalr	-1806(ra) # 80000c8a <release>
  sched();
    800023a0:	00000097          	auipc	ra,0x0
    800023a4:	c8e080e7          	jalr	-882(ra) # 8000202e <sched>
  panic("zombie exit");
    800023a8:	00006517          	auipc	a0,0x6
    800023ac:	e9050513          	addi	a0,a0,-368 # 80008238 <digits+0x1f8>
    800023b0:	ffffe097          	auipc	ra,0xffffe
    800023b4:	180080e7          	jalr	384(ra) # 80000530 <panic>

00000000800023b8 <yield>:
{
    800023b8:	1101                	addi	sp,sp,-32
    800023ba:	ec06                	sd	ra,24(sp)
    800023bc:	e822                	sd	s0,16(sp)
    800023be:	e426                	sd	s1,8(sp)
    800023c0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	632080e7          	jalr	1586(ra) # 800019f4 <myproc>
    800023ca:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	80a080e7          	jalr	-2038(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800023d4:	4789                	li	a5,2
    800023d6:	cc9c                	sw	a5,24(s1)
  sched();
    800023d8:	00000097          	auipc	ra,0x0
    800023dc:	c56080e7          	jalr	-938(ra) # 8000202e <sched>
  release(&p->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8a8080e7          	jalr	-1880(ra) # 80000c8a <release>
}
    800023ea:	60e2                	ld	ra,24(sp)
    800023ec:	6442                	ld	s0,16(sp)
    800023ee:	64a2                	ld	s1,8(sp)
    800023f0:	6105                	addi	sp,sp,32
    800023f2:	8082                	ret

00000000800023f4 <sleep>:
{
    800023f4:	7179                	addi	sp,sp,-48
    800023f6:	f406                	sd	ra,40(sp)
    800023f8:	f022                	sd	s0,32(sp)
    800023fa:	ec26                	sd	s1,24(sp)
    800023fc:	e84a                	sd	s2,16(sp)
    800023fe:	e44e                	sd	s3,8(sp)
    80002400:	1800                	addi	s0,sp,48
    80002402:	89aa                	mv	s3,a0
    80002404:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	5ee080e7          	jalr	1518(ra) # 800019f4 <myproc>
    8000240e:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002410:	05250663          	beq	a0,s2,8000245c <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002414:	ffffe097          	auipc	ra,0xffffe
    80002418:	7c2080e7          	jalr	1986(ra) # 80000bd6 <acquire>
    release(lk);
    8000241c:	854a                	mv	a0,s2
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	86c080e7          	jalr	-1940(ra) # 80000c8a <release>
  p->chan = chan;
    80002426:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000242a:	4785                	li	a5,1
    8000242c:	cc9c                	sw	a5,24(s1)
  sched();
    8000242e:	00000097          	auipc	ra,0x0
    80002432:	c00080e7          	jalr	-1024(ra) # 8000202e <sched>
  p->chan = 0;
    80002436:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	84e080e7          	jalr	-1970(ra) # 80000c8a <release>
    acquire(lk);
    80002444:	854a                	mv	a0,s2
    80002446:	ffffe097          	auipc	ra,0xffffe
    8000244a:	790080e7          	jalr	1936(ra) # 80000bd6 <acquire>
}
    8000244e:	70a2                	ld	ra,40(sp)
    80002450:	7402                	ld	s0,32(sp)
    80002452:	64e2                	ld	s1,24(sp)
    80002454:	6942                	ld	s2,16(sp)
    80002456:	69a2                	ld	s3,8(sp)
    80002458:	6145                	addi	sp,sp,48
    8000245a:	8082                	ret
  p->chan = chan;
    8000245c:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002460:	4785                	li	a5,1
    80002462:	cd1c                	sw	a5,24(a0)
  sched();
    80002464:	00000097          	auipc	ra,0x0
    80002468:	bca080e7          	jalr	-1078(ra) # 8000202e <sched>
  p->chan = 0;
    8000246c:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002470:	bff9                	j	8000244e <sleep+0x5a>

0000000080002472 <wait>:
{
    80002472:	715d                	addi	sp,sp,-80
    80002474:	e486                	sd	ra,72(sp)
    80002476:	e0a2                	sd	s0,64(sp)
    80002478:	fc26                	sd	s1,56(sp)
    8000247a:	f84a                	sd	s2,48(sp)
    8000247c:	f44e                	sd	s3,40(sp)
    8000247e:	f052                	sd	s4,32(sp)
    80002480:	ec56                	sd	s5,24(sp)
    80002482:	e85a                	sd	s6,16(sp)
    80002484:	e45e                	sd	s7,8(sp)
    80002486:	e062                	sd	s8,0(sp)
    80002488:	0880                	addi	s0,sp,80
    8000248a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	568080e7          	jalr	1384(ra) # 800019f4 <myproc>
    80002494:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002496:	8c2a                	mv	s8,a0
    80002498:	ffffe097          	auipc	ra,0xffffe
    8000249c:	73e080e7          	jalr	1854(ra) # 80000bd6 <acquire>
    havekids = 0;
    800024a0:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800024a2:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800024a4:	0001d997          	auipc	s3,0x1d
    800024a8:	c1498993          	addi	s3,s3,-1004 # 8001f0b8 <tickslock>
        havekids = 1;
    800024ac:	4a85                	li	s5,1
    havekids = 0;
    800024ae:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800024b0:	0000f497          	auipc	s1,0xf
    800024b4:	20848493          	addi	s1,s1,520 # 800116b8 <proc>
    800024b8:	a08d                	j	8000251a <wait+0xa8>
          pid = np->pid;
    800024ba:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024be:	000b0e63          	beqz	s6,800024da <wait+0x68>
    800024c2:	4691                	li	a3,4
    800024c4:	03448613          	addi	a2,s1,52
    800024c8:	85da                	mv	a1,s6
    800024ca:	05093503          	ld	a0,80(s2)
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	16a080e7          	jalr	362(ra) # 80001638 <copyout>
    800024d6:	02054263          	bltz	a0,800024fa <wait+0x88>
          freeproc(np);
    800024da:	8526                	mv	a0,s1
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	6ca080e7          	jalr	1738(ra) # 80001ba6 <freeproc>
          release(&np->lock);
    800024e4:	8526                	mv	a0,s1
    800024e6:	ffffe097          	auipc	ra,0xffffe
    800024ea:	7a4080e7          	jalr	1956(ra) # 80000c8a <release>
          release(&p->lock);
    800024ee:	854a                	mv	a0,s2
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	79a080e7          	jalr	1946(ra) # 80000c8a <release>
          return pid;
    800024f8:	a8a9                	j	80002552 <wait+0xe0>
            release(&np->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	78e080e7          	jalr	1934(ra) # 80000c8a <release>
            release(&p->lock);
    80002504:	854a                	mv	a0,s2
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	784080e7          	jalr	1924(ra) # 80000c8a <release>
            return -1;
    8000250e:	59fd                	li	s3,-1
    80002510:	a089                	j	80002552 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002512:	36848493          	addi	s1,s1,872
    80002516:	03348463          	beq	s1,s3,8000253e <wait+0xcc>
      if(np->parent == p){
    8000251a:	709c                	ld	a5,32(s1)
    8000251c:	ff279be3          	bne	a5,s2,80002512 <wait+0xa0>
        acquire(&np->lock);
    80002520:	8526                	mv	a0,s1
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	6b4080e7          	jalr	1716(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    8000252a:	4c9c                	lw	a5,24(s1)
    8000252c:	f94787e3          	beq	a5,s4,800024ba <wait+0x48>
        release(&np->lock);
    80002530:	8526                	mv	a0,s1
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	758080e7          	jalr	1880(ra) # 80000c8a <release>
        havekids = 1;
    8000253a:	8756                	mv	a4,s5
    8000253c:	bfd9                	j	80002512 <wait+0xa0>
    if(!havekids || p->killed){
    8000253e:	c701                	beqz	a4,80002546 <wait+0xd4>
    80002540:	03092783          	lw	a5,48(s2)
    80002544:	c785                	beqz	a5,8000256c <wait+0xfa>
      release(&p->lock);
    80002546:	854a                	mv	a0,s2
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	742080e7          	jalr	1858(ra) # 80000c8a <release>
      return -1;
    80002550:	59fd                	li	s3,-1
}
    80002552:	854e                	mv	a0,s3
    80002554:	60a6                	ld	ra,72(sp)
    80002556:	6406                	ld	s0,64(sp)
    80002558:	74e2                	ld	s1,56(sp)
    8000255a:	7942                	ld	s2,48(sp)
    8000255c:	79a2                	ld	s3,40(sp)
    8000255e:	7a02                	ld	s4,32(sp)
    80002560:	6ae2                	ld	s5,24(sp)
    80002562:	6b42                	ld	s6,16(sp)
    80002564:	6ba2                	ld	s7,8(sp)
    80002566:	6c02                	ld	s8,0(sp)
    80002568:	6161                	addi	sp,sp,80
    8000256a:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000256c:	85e2                	mv	a1,s8
    8000256e:	854a                	mv	a0,s2
    80002570:	00000097          	auipc	ra,0x0
    80002574:	e84080e7          	jalr	-380(ra) # 800023f4 <sleep>
    havekids = 0;
    80002578:	bf1d                	j	800024ae <wait+0x3c>

000000008000257a <wakeup>:
{
    8000257a:	7139                	addi	sp,sp,-64
    8000257c:	fc06                	sd	ra,56(sp)
    8000257e:	f822                	sd	s0,48(sp)
    80002580:	f426                	sd	s1,40(sp)
    80002582:	f04a                	sd	s2,32(sp)
    80002584:	ec4e                	sd	s3,24(sp)
    80002586:	e852                	sd	s4,16(sp)
    80002588:	e456                	sd	s5,8(sp)
    8000258a:	0080                	addi	s0,sp,64
    8000258c:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000258e:	0000f497          	auipc	s1,0xf
    80002592:	12a48493          	addi	s1,s1,298 # 800116b8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002596:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002598:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000259a:	0001d917          	auipc	s2,0x1d
    8000259e:	b1e90913          	addi	s2,s2,-1250 # 8001f0b8 <tickslock>
    800025a2:	a821                	j	800025ba <wakeup+0x40>
      p->state = RUNNABLE;
    800025a4:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800025a8:	8526                	mv	a0,s1
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	6e0080e7          	jalr	1760(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025b2:	36848493          	addi	s1,s1,872
    800025b6:	01248e63          	beq	s1,s2,800025d2 <wakeup+0x58>
    acquire(&p->lock);
    800025ba:	8526                	mv	a0,s1
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	61a080e7          	jalr	1562(ra) # 80000bd6 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800025c4:	4c9c                	lw	a5,24(s1)
    800025c6:	ff3791e3          	bne	a5,s3,800025a8 <wakeup+0x2e>
    800025ca:	749c                	ld	a5,40(s1)
    800025cc:	fd479ee3          	bne	a5,s4,800025a8 <wakeup+0x2e>
    800025d0:	bfd1                	j	800025a4 <wakeup+0x2a>
}
    800025d2:	70e2                	ld	ra,56(sp)
    800025d4:	7442                	ld	s0,48(sp)
    800025d6:	74a2                	ld	s1,40(sp)
    800025d8:	7902                	ld	s2,32(sp)
    800025da:	69e2                	ld	s3,24(sp)
    800025dc:	6a42                	ld	s4,16(sp)
    800025de:	6aa2                	ld	s5,8(sp)
    800025e0:	6121                	addi	sp,sp,64
    800025e2:	8082                	ret

00000000800025e4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025e4:	7179                	addi	sp,sp,-48
    800025e6:	f406                	sd	ra,40(sp)
    800025e8:	f022                	sd	s0,32(sp)
    800025ea:	ec26                	sd	s1,24(sp)
    800025ec:	e84a                	sd	s2,16(sp)
    800025ee:	e44e                	sd	s3,8(sp)
    800025f0:	1800                	addi	s0,sp,48
    800025f2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025f4:	0000f497          	auipc	s1,0xf
    800025f8:	0c448493          	addi	s1,s1,196 # 800116b8 <proc>
    800025fc:	0001d997          	auipc	s3,0x1d
    80002600:	abc98993          	addi	s3,s3,-1348 # 8001f0b8 <tickslock>
    acquire(&p->lock);
    80002604:	8526                	mv	a0,s1
    80002606:	ffffe097          	auipc	ra,0xffffe
    8000260a:	5d0080e7          	jalr	1488(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    8000260e:	5c9c                	lw	a5,56(s1)
    80002610:	01278d63          	beq	a5,s2,8000262a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002614:	8526                	mv	a0,s1
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	674080e7          	jalr	1652(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000261e:	36848493          	addi	s1,s1,872
    80002622:	ff3491e3          	bne	s1,s3,80002604 <kill+0x20>
  }
  return -1;
    80002626:	557d                	li	a0,-1
    80002628:	a829                	j	80002642 <kill+0x5e>
      p->killed = 1;
    8000262a:	4785                	li	a5,1
    8000262c:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000262e:	4c98                	lw	a4,24(s1)
    80002630:	4785                	li	a5,1
    80002632:	00f70f63          	beq	a4,a5,80002650 <kill+0x6c>
      release(&p->lock);
    80002636:	8526                	mv	a0,s1
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	652080e7          	jalr	1618(ra) # 80000c8a <release>
      return 0;
    80002640:	4501                	li	a0,0
}
    80002642:	70a2                	ld	ra,40(sp)
    80002644:	7402                	ld	s0,32(sp)
    80002646:	64e2                	ld	s1,24(sp)
    80002648:	6942                	ld	s2,16(sp)
    8000264a:	69a2                	ld	s3,8(sp)
    8000264c:	6145                	addi	sp,sp,48
    8000264e:	8082                	ret
        p->state = RUNNABLE;
    80002650:	4789                	li	a5,2
    80002652:	cc9c                	sw	a5,24(s1)
    80002654:	b7cd                	j	80002636 <kill+0x52>

0000000080002656 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002656:	7179                	addi	sp,sp,-48
    80002658:	f406                	sd	ra,40(sp)
    8000265a:	f022                	sd	s0,32(sp)
    8000265c:	ec26                	sd	s1,24(sp)
    8000265e:	e84a                	sd	s2,16(sp)
    80002660:	e44e                	sd	s3,8(sp)
    80002662:	e052                	sd	s4,0(sp)
    80002664:	1800                	addi	s0,sp,48
    80002666:	84aa                	mv	s1,a0
    80002668:	892e                	mv	s2,a1
    8000266a:	89b2                	mv	s3,a2
    8000266c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000266e:	fffff097          	auipc	ra,0xfffff
    80002672:	386080e7          	jalr	902(ra) # 800019f4 <myproc>
  if(user_dst){
    80002676:	c08d                	beqz	s1,80002698 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002678:	86d2                	mv	a3,s4
    8000267a:	864e                	mv	a2,s3
    8000267c:	85ca                	mv	a1,s2
    8000267e:	6928                	ld	a0,80(a0)
    80002680:	fffff097          	auipc	ra,0xfffff
    80002684:	fb8080e7          	jalr	-72(ra) # 80001638 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002688:	70a2                	ld	ra,40(sp)
    8000268a:	7402                	ld	s0,32(sp)
    8000268c:	64e2                	ld	s1,24(sp)
    8000268e:	6942                	ld	s2,16(sp)
    80002690:	69a2                	ld	s3,8(sp)
    80002692:	6a02                	ld	s4,0(sp)
    80002694:	6145                	addi	sp,sp,48
    80002696:	8082                	ret
    memmove((char *)dst, src, len);
    80002698:	000a061b          	sext.w	a2,s4
    8000269c:	85ce                	mv	a1,s3
    8000269e:	854a                	mv	a0,s2
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	692080e7          	jalr	1682(ra) # 80000d32 <memmove>
    return 0;
    800026a8:	8526                	mv	a0,s1
    800026aa:	bff9                	j	80002688 <either_copyout+0x32>

00000000800026ac <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026ac:	7179                	addi	sp,sp,-48
    800026ae:	f406                	sd	ra,40(sp)
    800026b0:	f022                	sd	s0,32(sp)
    800026b2:	ec26                	sd	s1,24(sp)
    800026b4:	e84a                	sd	s2,16(sp)
    800026b6:	e44e                	sd	s3,8(sp)
    800026b8:	e052                	sd	s4,0(sp)
    800026ba:	1800                	addi	s0,sp,48
    800026bc:	892a                	mv	s2,a0
    800026be:	84ae                	mv	s1,a1
    800026c0:	89b2                	mv	s3,a2
    800026c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026c4:	fffff097          	auipc	ra,0xfffff
    800026c8:	330080e7          	jalr	816(ra) # 800019f4 <myproc>
  if(user_src){
    800026cc:	c08d                	beqz	s1,800026ee <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026ce:	86d2                	mv	a3,s4
    800026d0:	864e                	mv	a2,s3
    800026d2:	85ca                	mv	a1,s2
    800026d4:	6928                	ld	a0,80(a0)
    800026d6:	fffff097          	auipc	ra,0xfffff
    800026da:	fee080e7          	jalr	-18(ra) # 800016c4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026de:	70a2                	ld	ra,40(sp)
    800026e0:	7402                	ld	s0,32(sp)
    800026e2:	64e2                	ld	s1,24(sp)
    800026e4:	6942                	ld	s2,16(sp)
    800026e6:	69a2                	ld	s3,8(sp)
    800026e8:	6a02                	ld	s4,0(sp)
    800026ea:	6145                	addi	sp,sp,48
    800026ec:	8082                	ret
    memmove(dst, (char*)src, len);
    800026ee:	000a061b          	sext.w	a2,s4
    800026f2:	85ce                	mv	a1,s3
    800026f4:	854a                	mv	a0,s2
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	63c080e7          	jalr	1596(ra) # 80000d32 <memmove>
    return 0;
    800026fe:	8526                	mv	a0,s1
    80002700:	bff9                	j	800026de <either_copyin+0x32>

0000000080002702 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002702:	715d                	addi	sp,sp,-80
    80002704:	e486                	sd	ra,72(sp)
    80002706:	e0a2                	sd	s0,64(sp)
    80002708:	fc26                	sd	s1,56(sp)
    8000270a:	f84a                	sd	s2,48(sp)
    8000270c:	f44e                	sd	s3,40(sp)
    8000270e:	f052                	sd	s4,32(sp)
    80002710:	ec56                	sd	s5,24(sp)
    80002712:	e85a                	sd	s6,16(sp)
    80002714:	e45e                	sd	s7,8(sp)
    80002716:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002718:	00006517          	auipc	a0,0x6
    8000271c:	9b050513          	addi	a0,a0,-1616 # 800080c8 <digits+0x88>
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	e5a080e7          	jalr	-422(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002728:	0000f497          	auipc	s1,0xf
    8000272c:	0e848493          	addi	s1,s1,232 # 80011810 <proc+0x158>
    80002730:	0001d917          	auipc	s2,0x1d
    80002734:	ae090913          	addi	s2,s2,-1312 # 8001f210 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002738:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000273a:	00006997          	auipc	s3,0x6
    8000273e:	b0e98993          	addi	s3,s3,-1266 # 80008248 <digits+0x208>
    printf("%d %s %s", p->pid, state, p->name);
    80002742:	00006a97          	auipc	s5,0x6
    80002746:	b0ea8a93          	addi	s5,s5,-1266 # 80008250 <digits+0x210>
    printf("\n");
    8000274a:	00006a17          	auipc	s4,0x6
    8000274e:	97ea0a13          	addi	s4,s4,-1666 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002752:	00006b97          	auipc	s7,0x6
    80002756:	b36b8b93          	addi	s7,s7,-1226 # 80008288 <states.1801>
    8000275a:	a00d                	j	8000277c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000275c:	ee06a583          	lw	a1,-288(a3)
    80002760:	8556                	mv	a0,s5
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	e18080e7          	jalr	-488(ra) # 8000057a <printf>
    printf("\n");
    8000276a:	8552                	mv	a0,s4
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	e0e080e7          	jalr	-498(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002774:	36848493          	addi	s1,s1,872
    80002778:	03248163          	beq	s1,s2,8000279a <procdump+0x98>
    if(p->state == UNUSED)
    8000277c:	86a6                	mv	a3,s1
    8000277e:	ec04a783          	lw	a5,-320(s1)
    80002782:	dbed                	beqz	a5,80002774 <procdump+0x72>
      state = "???";
    80002784:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002786:	fcfb6be3          	bltu	s6,a5,8000275c <procdump+0x5a>
    8000278a:	1782                	slli	a5,a5,0x20
    8000278c:	9381                	srli	a5,a5,0x20
    8000278e:	078e                	slli	a5,a5,0x3
    80002790:	97de                	add	a5,a5,s7
    80002792:	6390                	ld	a2,0(a5)
    80002794:	f661                	bnez	a2,8000275c <procdump+0x5a>
      state = "???";
    80002796:	864e                	mv	a2,s3
    80002798:	b7d1                	j	8000275c <procdump+0x5a>
  }
}
    8000279a:	60a6                	ld	ra,72(sp)
    8000279c:	6406                	ld	s0,64(sp)
    8000279e:	74e2                	ld	s1,56(sp)
    800027a0:	7942                	ld	s2,48(sp)
    800027a2:	79a2                	ld	s3,40(sp)
    800027a4:	7a02                	ld	s4,32(sp)
    800027a6:	6ae2                	ld	s5,24(sp)
    800027a8:	6b42                	ld	s6,16(sp)
    800027aa:	6ba2                	ld	s7,8(sp)
    800027ac:	6161                	addi	sp,sp,80
    800027ae:	8082                	ret

00000000800027b0 <swtch>:
    800027b0:	00153023          	sd	ra,0(a0)
    800027b4:	00253423          	sd	sp,8(a0)
    800027b8:	e900                	sd	s0,16(a0)
    800027ba:	ed04                	sd	s1,24(a0)
    800027bc:	03253023          	sd	s2,32(a0)
    800027c0:	03353423          	sd	s3,40(a0)
    800027c4:	03453823          	sd	s4,48(a0)
    800027c8:	03553c23          	sd	s5,56(a0)
    800027cc:	05653023          	sd	s6,64(a0)
    800027d0:	05753423          	sd	s7,72(a0)
    800027d4:	05853823          	sd	s8,80(a0)
    800027d8:	05953c23          	sd	s9,88(a0)
    800027dc:	07a53023          	sd	s10,96(a0)
    800027e0:	07b53423          	sd	s11,104(a0)
    800027e4:	0005b083          	ld	ra,0(a1)
    800027e8:	0085b103          	ld	sp,8(a1)
    800027ec:	6980                	ld	s0,16(a1)
    800027ee:	6d84                	ld	s1,24(a1)
    800027f0:	0205b903          	ld	s2,32(a1)
    800027f4:	0285b983          	ld	s3,40(a1)
    800027f8:	0305ba03          	ld	s4,48(a1)
    800027fc:	0385ba83          	ld	s5,56(a1)
    80002800:	0405bb03          	ld	s6,64(a1)
    80002804:	0485bb83          	ld	s7,72(a1)
    80002808:	0505bc03          	ld	s8,80(a1)
    8000280c:	0585bc83          	ld	s9,88(a1)
    80002810:	0605bd03          	ld	s10,96(a1)
    80002814:	0685bd83          	ld	s11,104(a1)
    80002818:	8082                	ret

000000008000281a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000281a:	1141                	addi	sp,sp,-16
    8000281c:	e406                	sd	ra,8(sp)
    8000281e:	e022                	sd	s0,0(sp)
    80002820:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002822:	00006597          	auipc	a1,0x6
    80002826:	a8e58593          	addi	a1,a1,-1394 # 800082b0 <states.1801+0x28>
    8000282a:	0001d517          	auipc	a0,0x1d
    8000282e:	88e50513          	addi	a0,a0,-1906 # 8001f0b8 <tickslock>
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	314080e7          	jalr	788(ra) # 80000b46 <initlock>
}
    8000283a:	60a2                	ld	ra,8(sp)
    8000283c:	6402                	ld	s0,0(sp)
    8000283e:	0141                	addi	sp,sp,16
    80002840:	8082                	ret

0000000080002842 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002842:	1141                	addi	sp,sp,-16
    80002844:	e422                	sd	s0,8(sp)
    80002846:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002848:	00004797          	auipc	a5,0x4
    8000284c:	a2878793          	addi	a5,a5,-1496 # 80006270 <kernelvec>
    80002850:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002854:	6422                	ld	s0,8(sp)
    80002856:	0141                	addi	sp,sp,16
    80002858:	8082                	ret

000000008000285a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000285a:	1141                	addi	sp,sp,-16
    8000285c:	e406                	sd	ra,8(sp)
    8000285e:	e022                	sd	s0,0(sp)
    80002860:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	192080e7          	jalr	402(ra) # 800019f4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000286a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000286e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002870:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002874:	00004617          	auipc	a2,0x4
    80002878:	78c60613          	addi	a2,a2,1932 # 80007000 <_trampoline>
    8000287c:	00004697          	auipc	a3,0x4
    80002880:	78468693          	addi	a3,a3,1924 # 80007000 <_trampoline>
    80002884:	8e91                	sub	a3,a3,a2
    80002886:	040007b7          	lui	a5,0x4000
    8000288a:	17fd                	addi	a5,a5,-1
    8000288c:	07b2                	slli	a5,a5,0xc
    8000288e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002890:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002894:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002896:	180026f3          	csrr	a3,satp
    8000289a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000289c:	6d38                	ld	a4,88(a0)
    8000289e:	6134                	ld	a3,64(a0)
    800028a0:	6585                	lui	a1,0x1
    800028a2:	96ae                	add	a3,a3,a1
    800028a4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028a6:	6d38                	ld	a4,88(a0)
    800028a8:	00000697          	auipc	a3,0x0
    800028ac:	13868693          	addi	a3,a3,312 # 800029e0 <usertrap>
    800028b0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028b2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028b4:	8692                	mv	a3,tp
    800028b6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028bc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028c0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028c8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ca:	6f18                	ld	a4,24(a4)
    800028cc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028d0:	692c                	ld	a1,80(a0)
    800028d2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028d4:	00004717          	auipc	a4,0x4
    800028d8:	7bc70713          	addi	a4,a4,1980 # 80007090 <userret>
    800028dc:	8f11                	sub	a4,a4,a2
    800028de:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028e0:	577d                	li	a4,-1
    800028e2:	177e                	slli	a4,a4,0x3f
    800028e4:	8dd9                	or	a1,a1,a4
    800028e6:	02000537          	lui	a0,0x2000
    800028ea:	157d                	addi	a0,a0,-1
    800028ec:	0536                	slli	a0,a0,0xd
    800028ee:	9782                	jalr	a5
}
    800028f0:	60a2                	ld	ra,8(sp)
    800028f2:	6402                	ld	s0,0(sp)
    800028f4:	0141                	addi	sp,sp,16
    800028f6:	8082                	ret

00000000800028f8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028f8:	1101                	addi	sp,sp,-32
    800028fa:	ec06                	sd	ra,24(sp)
    800028fc:	e822                	sd	s0,16(sp)
    800028fe:	e426                	sd	s1,8(sp)
    80002900:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002902:	0001c497          	auipc	s1,0x1c
    80002906:	7b648493          	addi	s1,s1,1974 # 8001f0b8 <tickslock>
    8000290a:	8526                	mv	a0,s1
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	2ca080e7          	jalr	714(ra) # 80000bd6 <acquire>
  ticks++;
    80002914:	00006517          	auipc	a0,0x6
    80002918:	71c50513          	addi	a0,a0,1820 # 80009030 <ticks>
    8000291c:	411c                	lw	a5,0(a0)
    8000291e:	2785                	addiw	a5,a5,1
    80002920:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002922:	00000097          	auipc	ra,0x0
    80002926:	c58080e7          	jalr	-936(ra) # 8000257a <wakeup>
  release(&tickslock);
    8000292a:	8526                	mv	a0,s1
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	35e080e7          	jalr	862(ra) # 80000c8a <release>
}
    80002934:	60e2                	ld	ra,24(sp)
    80002936:	6442                	ld	s0,16(sp)
    80002938:	64a2                	ld	s1,8(sp)
    8000293a:	6105                	addi	sp,sp,32
    8000293c:	8082                	ret

000000008000293e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000293e:	1101                	addi	sp,sp,-32
    80002940:	ec06                	sd	ra,24(sp)
    80002942:	e822                	sd	s0,16(sp)
    80002944:	e426                	sd	s1,8(sp)
    80002946:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002948:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000294c:	00074d63          	bltz	a4,80002966 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002950:	57fd                	li	a5,-1
    80002952:	17fe                	slli	a5,a5,0x3f
    80002954:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002956:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002958:	06f70363          	beq	a4,a5,800029be <devintr+0x80>
  }
}
    8000295c:	60e2                	ld	ra,24(sp)
    8000295e:	6442                	ld	s0,16(sp)
    80002960:	64a2                	ld	s1,8(sp)
    80002962:	6105                	addi	sp,sp,32
    80002964:	8082                	ret
     (scause & 0xff) == 9){
    80002966:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000296a:	46a5                	li	a3,9
    8000296c:	fed792e3          	bne	a5,a3,80002950 <devintr+0x12>
    int irq = plic_claim();
    80002970:	00004097          	auipc	ra,0x4
    80002974:	a08080e7          	jalr	-1528(ra) # 80006378 <plic_claim>
    80002978:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000297a:	47a9                	li	a5,10
    8000297c:	02f50763          	beq	a0,a5,800029aa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002980:	4785                	li	a5,1
    80002982:	02f50963          	beq	a0,a5,800029b4 <devintr+0x76>
    return 1;
    80002986:	4505                	li	a0,1
    } else if(irq){
    80002988:	d8f1                	beqz	s1,8000295c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000298a:	85a6                	mv	a1,s1
    8000298c:	00006517          	auipc	a0,0x6
    80002990:	92c50513          	addi	a0,a0,-1748 # 800082b8 <states.1801+0x30>
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	be6080e7          	jalr	-1050(ra) # 8000057a <printf>
      plic_complete(irq);
    8000299c:	8526                	mv	a0,s1
    8000299e:	00004097          	auipc	ra,0x4
    800029a2:	9fe080e7          	jalr	-1538(ra) # 8000639c <plic_complete>
    return 1;
    800029a6:	4505                	li	a0,1
    800029a8:	bf55                	j	8000295c <devintr+0x1e>
      uartintr();
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	ff0080e7          	jalr	-16(ra) # 8000099a <uartintr>
    800029b2:	b7ed                	j	8000299c <devintr+0x5e>
      virtio_disk_intr();
    800029b4:	00004097          	auipc	ra,0x4
    800029b8:	ec8080e7          	jalr	-312(ra) # 8000687c <virtio_disk_intr>
    800029bc:	b7c5                	j	8000299c <devintr+0x5e>
    if(cpuid() == 0){
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	00a080e7          	jalr	10(ra) # 800019c8 <cpuid>
    800029c6:	c901                	beqz	a0,800029d6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029c8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029cc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029ce:	14479073          	csrw	sip,a5
    return 2;
    800029d2:	4509                	li	a0,2
    800029d4:	b761                	j	8000295c <devintr+0x1e>
      clockintr();
    800029d6:	00000097          	auipc	ra,0x0
    800029da:	f22080e7          	jalr	-222(ra) # 800028f8 <clockintr>
    800029de:	b7ed                	j	800029c8 <devintr+0x8a>

00000000800029e0 <usertrap>:
{
    800029e0:	7139                	addi	sp,sp,-64
    800029e2:	fc06                	sd	ra,56(sp)
    800029e4:	f822                	sd	s0,48(sp)
    800029e6:	f426                	sd	s1,40(sp)
    800029e8:	f04a                	sd	s2,32(sp)
    800029ea:	ec4e                	sd	s3,24(sp)
    800029ec:	e852                	sd	s4,16(sp)
    800029ee:	e456                	sd	s5,8(sp)
    800029f0:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029f6:	1007f793          	andi	a5,a5,256
    800029fa:	efb1                	bnez	a5,80002a56 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029fc:	00004797          	auipc	a5,0x4
    80002a00:	87478793          	addi	a5,a5,-1932 # 80006270 <kernelvec>
    80002a04:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a08:	fffff097          	auipc	ra,0xfffff
    80002a0c:	fec080e7          	jalr	-20(ra) # 800019f4 <myproc>
    80002a10:	892a                	mv	s2,a0
  p->trapframe->epc = r_sepc();
    80002a12:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a14:	14102773          	csrr	a4,sepc
    80002a18:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a1a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a1e:	47a1                	li	a5,8
    80002a20:	04f70363          	beq	a4,a5,80002a66 <usertrap+0x86>
    80002a24:	14202773          	csrr	a4,scause
  } else if (r_scause() == 12 || r_scause() == 13
    80002a28:	47b1                	li	a5,12
    80002a2a:	00f70c63          	beq	a4,a5,80002a42 <usertrap+0x62>
    80002a2e:	14202773          	csrr	a4,scause
    80002a32:	47b5                	li	a5,13
    80002a34:	00f70763          	beq	a4,a5,80002a42 <usertrap+0x62>
    80002a38:	14202773          	csrr	a4,scause
             || r_scause() == 15) { // mmap page fault - lab10
    80002a3c:	47bd                	li	a5,15
    80002a3e:	1ef71063          	bne	a4,a5,80002c1e <usertrap+0x23e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a42:	143029f3          	csrr	s3,stval
    uint64 va = PGROUNDDOWN(r_stval());
    80002a46:	77fd                	lui	a5,0xfffff
    80002a48:	00f9f9b3          	and	s3,s3,a5
    for (i = 0; i < NVMA; ++i) {
    80002a4c:	16890793          	addi	a5,s2,360
    80002a50:	4481                	li	s1,0
    80002a52:	4641                	li	a2,16
    80002a54:	a0b5                	j	80002ac0 <usertrap+0xe0>
    panic("usertrap: not from user mode");
    80002a56:	00006517          	auipc	a0,0x6
    80002a5a:	88250513          	addi	a0,a0,-1918 # 800082d8 <states.1801+0x50>
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	ad2080e7          	jalr	-1326(ra) # 80000530 <panic>
    if(p->killed)
    80002a66:	591c                	lw	a5,48(a0)
    80002a68:	e3a9                	bnez	a5,80002aaa <usertrap+0xca>
    p->trapframe->epc += 4;
    80002a6a:	05893703          	ld	a4,88(s2)
    80002a6e:	6f1c                	ld	a5,24(a4)
    80002a70:	0791                	addi	a5,a5,4
    80002a72:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a74:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a78:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a7c:	10079073          	csrw	sstatus,a5
    syscall();
    80002a80:	00000097          	auipc	ra,0x0
    80002a84:	3f8080e7          	jalr	1016(ra) # 80002e78 <syscall>
  if(p->killed)
    80002a88:	03092783          	lw	a5,48(s2)
    80002a8c:	1a079363          	bnez	a5,80002c32 <usertrap+0x252>
  usertrapret();
    80002a90:	00000097          	auipc	ra,0x0
    80002a94:	dca080e7          	jalr	-566(ra) # 8000285a <usertrapret>
}
    80002a98:	70e2                	ld	ra,56(sp)
    80002a9a:	7442                	ld	s0,48(sp)
    80002a9c:	74a2                	ld	s1,40(sp)
    80002a9e:	7902                	ld	s2,32(sp)
    80002aa0:	69e2                	ld	s3,24(sp)
    80002aa2:	6a42                	ld	s4,16(sp)
    80002aa4:	6aa2                	ld	s5,8(sp)
    80002aa6:	6121                	addi	sp,sp,64
    80002aa8:	8082                	ret
      exit(-1);
    80002aaa:	557d                	li	a0,-1
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	658080e7          	jalr	1624(ra) # 80002104 <exit>
    80002ab4:	bf5d                	j	80002a6a <usertrap+0x8a>
    for (i = 0; i < NVMA; ++i) {
    80002ab6:	2485                	addiw	s1,s1,1
    80002ab8:	02078793          	addi	a5,a5,32 # fffffffffffff020 <end+0xffffffff7ffd1020>
    80002abc:	10c48263          	beq	s1,a2,80002bc0 <usertrap+0x1e0>
      if (p->vma_list[i].addr && va >= p->vma_list[i].addr
    80002ac0:	6398                	ld	a4,0(a5)
    80002ac2:	db75                	beqz	a4,80002ab6 <usertrap+0xd6>
    80002ac4:	fee9e9e3          	bltu	s3,a4,80002ab6 <usertrap+0xd6>
          && va < p->vma_list[i].addr + p->vma_list[i].len) {
    80002ac8:	4794                	lw	a3,8(a5)
    80002aca:	9736                	add	a4,a4,a3
    80002acc:	fee9f5e3          	bgeu	s3,a4,80002ab6 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ad0:	14202773          	csrr	a4,scause
    if (r_scause() == 15 && (vma->prot & PROT_WRITE)
    80002ad4:	47bd                	li	a5,15
    80002ad6:	00f71963          	bne	a4,a5,80002ae8 <usertrap+0x108>
    80002ada:	00b48793          	addi	a5,s1,11
    80002ade:	0796                	slli	a5,a5,0x5
    80002ae0:	97ca                	add	a5,a5,s2
    80002ae2:	4bdc                	lw	a5,20(a5)
    80002ae4:	8b89                	andi	a5,a5,2
    80002ae6:	e7c5                	bnez	a5,80002b8e <usertrap+0x1ae>
      if ((pa = kalloc()) == 0) {
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	ffe080e7          	jalr	-2(ra) # 80000ae6 <kalloc>
    80002af0:	8a2a                	mv	s4,a0
    80002af2:	c579                	beqz	a0,80002bc0 <usertrap+0x1e0>
      memset(pa, 0, PGSIZE);
    80002af4:	6605                	lui	a2,0x1
    80002af6:	4581                	li	a1,0
    80002af8:	ffffe097          	auipc	ra,0xffffe
    80002afc:	1da080e7          	jalr	474(ra) # 80000cd2 <memset>
      ilock(vma->f->ip);
    80002b00:	00549a93          	slli	s5,s1,0x5
    80002b04:	9aca                	add	s5,s5,s2
    80002b06:	180ab783          	ld	a5,384(s5)
    80002b0a:	6f88                	ld	a0,24(a5)
    80002b0c:	00001097          	auipc	ra,0x1
    80002b10:	e6a080e7          	jalr	-406(ra) # 80003976 <ilock>
      if (readi(vma->f->ip, 0, (uint64) pa, va - vma->addr + vma->offset, PGSIZE) < 0) {
    80002b14:	17caa783          	lw	a5,380(s5)
    80002b18:	013787bb          	addw	a5,a5,s3
    80002b1c:	168ab683          	ld	a3,360(s5)
    80002b20:	180ab503          	ld	a0,384(s5)
    80002b24:	6705                	lui	a4,0x1
    80002b26:	40d786bb          	subw	a3,a5,a3
    80002b2a:	8652                	mv	a2,s4
    80002b2c:	4581                	li	a1,0
    80002b2e:	6d08                	ld	a0,24(a0)
    80002b30:	00001097          	auipc	ra,0x1
    80002b34:	0fa080e7          	jalr	250(ra) # 80003c2a <readi>
    80002b38:	06054d63          	bltz	a0,80002bb2 <usertrap+0x1d2>
      iunlock(vma->f->ip);
    80002b3c:	0496                	slli	s1,s1,0x5
    80002b3e:	94ca                	add	s1,s1,s2
    80002b40:	1804b783          	ld	a5,384(s1)
    80002b44:	6f88                	ld	a0,24(a5)
    80002b46:	00001097          	auipc	ra,0x1
    80002b4a:	ef2080e7          	jalr	-270(ra) # 80003a38 <iunlock>
      if ((vma->prot & PROT_READ)) {
    80002b4e:	174aa783          	lw	a5,372(s5)
    80002b52:	0017f693          	andi	a3,a5,1
    int flags = PTE_U;
    80002b56:	4741                	li	a4,16
      if ((vma->prot & PROT_READ)) {
    80002b58:	c291                	beqz	a3,80002b5c <usertrap+0x17c>
        flags |= PTE_R;
    80002b5a:	4749                	li	a4,18
    80002b5c:	14202673          	csrr	a2,scause
      if (r_scause() == 15 && (vma->prot & PROT_WRITE)) {
    80002b60:	46bd                	li	a3,15
    80002b62:	0ad60863          	beq	a2,a3,80002c12 <usertrap+0x232>
      if ((vma->prot & PROT_EXEC)) {
    80002b66:	8b91                	andi	a5,a5,4
    80002b68:	c399                	beqz	a5,80002b6e <usertrap+0x18e>
        flags |= PTE_X;
    80002b6a:	00876713          	ori	a4,a4,8
      if (mappages(p->pagetable, va, PGSIZE, (uint64) pa, flags) != 0) {
    80002b6e:	86d2                	mv	a3,s4
    80002b70:	6605                	lui	a2,0x1
    80002b72:	85ce                	mv	a1,s3
    80002b74:	05093503          	ld	a0,80(s2)
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	52e080e7          	jalr	1326(ra) # 800010a6 <mappages>
    80002b80:	d501                	beqz	a0,80002a88 <usertrap+0xa8>
        kfree(pa);
    80002b82:	8552                	mv	a0,s4
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	e66080e7          	jalr	-410(ra) # 800009ea <kfree>
        goto err;
    80002b8c:	a815                	j	80002bc0 <usertrap+0x1e0>
        && walkaddr(p->pagetable, va)) {
    80002b8e:	85ce                	mv	a1,s3
    80002b90:	05093503          	ld	a0,80(s2)
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	4d0080e7          	jalr	1232(ra) # 80001064 <walkaddr>
    80002b9c:	d531                	beqz	a0,80002ae8 <usertrap+0x108>
      if (uvmsetdirtywrite(p->pagetable, va)) {
    80002b9e:	85ce                	mv	a1,s3
    80002ba0:	05093503          	ld	a0,80(s2)
    80002ba4:	fffff097          	auipc	ra,0xfffff
    80002ba8:	c88080e7          	jalr	-888(ra) # 8000182c <uvmsetdirtywrite>
    80002bac:	ec050ee3          	beqz	a0,80002a88 <usertrap+0xa8>
    80002bb0:	a801                	j	80002bc0 <usertrap+0x1e0>
        iunlock(vma->f->ip);
    80002bb2:	180ab783          	ld	a5,384(s5)
    80002bb6:	6f88                	ld	a0,24(a5)
    80002bb8:	00001097          	auipc	ra,0x1
    80002bbc:	e80080e7          	jalr	-384(ra) # 80003a38 <iunlock>
    80002bc0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bc4:	03892603          	lw	a2,56(s2)
    80002bc8:	00005517          	auipc	a0,0x5
    80002bcc:	73050513          	addi	a0,a0,1840 # 800082f8 <states.1801+0x70>
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	9aa080e7          	jalr	-1622(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bdc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002be0:	00005517          	auipc	a0,0x5
    80002be4:	74850513          	addi	a0,a0,1864 # 80008328 <states.1801+0xa0>
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	992080e7          	jalr	-1646(ra) # 8000057a <printf>
    p->killed = 1;
    80002bf0:	4785                	li	a5,1
    80002bf2:	02f92823          	sw	a5,48(s2)
    80002bf6:	4481                	li	s1,0
    exit(-1);
    80002bf8:	557d                	li	a0,-1
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	50a080e7          	jalr	1290(ra) # 80002104 <exit>
  if(which_dev == 2)
    80002c02:	4789                	li	a5,2
    80002c04:	e8f496e3          	bne	s1,a5,80002a90 <usertrap+0xb0>
    yield();
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	7b0080e7          	jalr	1968(ra) # 800023b8 <yield>
    80002c10:	b541                	j	80002a90 <usertrap+0xb0>
      if (r_scause() == 15 && (vma->prot & PROT_WRITE)) {
    80002c12:	0027f693          	andi	a3,a5,2
    80002c16:	daa1                	beqz	a3,80002b66 <usertrap+0x186>
        flags |= PTE_W | PTE_D;
    80002c18:	08476713          	ori	a4,a4,132
    80002c1c:	b7a9                	j	80002b66 <usertrap+0x186>
  }else if((which_dev = devintr()) != 0){
    80002c1e:	00000097          	auipc	ra,0x0
    80002c22:	d20080e7          	jalr	-736(ra) # 8000293e <devintr>
    80002c26:	84aa                	mv	s1,a0
    80002c28:	dd41                	beqz	a0,80002bc0 <usertrap+0x1e0>
  if(p->killed)
    80002c2a:	03092783          	lw	a5,48(s2)
    80002c2e:	dbf1                	beqz	a5,80002c02 <usertrap+0x222>
    80002c30:	b7e1                	j	80002bf8 <usertrap+0x218>
    80002c32:	4481                	li	s1,0
    80002c34:	b7d1                	j	80002bf8 <usertrap+0x218>

0000000080002c36 <kerneltrap>:
{
    80002c36:	7179                	addi	sp,sp,-48
    80002c38:	f406                	sd	ra,40(sp)
    80002c3a:	f022                	sd	s0,32(sp)
    80002c3c:	ec26                	sd	s1,24(sp)
    80002c3e:	e84a                	sd	s2,16(sp)
    80002c40:	e44e                	sd	s3,8(sp)
    80002c42:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c44:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c48:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c4c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c50:	1004f793          	andi	a5,s1,256
    80002c54:	cb85                	beqz	a5,80002c84 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c56:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c5a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c5c:	ef85                	bnez	a5,80002c94 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c5e:	00000097          	auipc	ra,0x0
    80002c62:	ce0080e7          	jalr	-800(ra) # 8000293e <devintr>
    80002c66:	cd1d                	beqz	a0,80002ca4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c68:	4789                	li	a5,2
    80002c6a:	06f50a63          	beq	a0,a5,80002cde <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c6e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c72:	10049073          	csrw	sstatus,s1
}
    80002c76:	70a2                	ld	ra,40(sp)
    80002c78:	7402                	ld	s0,32(sp)
    80002c7a:	64e2                	ld	s1,24(sp)
    80002c7c:	6942                	ld	s2,16(sp)
    80002c7e:	69a2                	ld	s3,8(sp)
    80002c80:	6145                	addi	sp,sp,48
    80002c82:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c84:	00005517          	auipc	a0,0x5
    80002c88:	6c450513          	addi	a0,a0,1732 # 80008348 <states.1801+0xc0>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	8a4080e7          	jalr	-1884(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c94:	00005517          	auipc	a0,0x5
    80002c98:	6dc50513          	addi	a0,a0,1756 # 80008370 <states.1801+0xe8>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	894080e7          	jalr	-1900(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    80002ca4:	85ce                	mv	a1,s3
    80002ca6:	00005517          	auipc	a0,0x5
    80002caa:	6ea50513          	addi	a0,a0,1770 # 80008390 <states.1801+0x108>
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	8cc080e7          	jalr	-1844(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cba:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cbe:	00005517          	auipc	a0,0x5
    80002cc2:	6e250513          	addi	a0,a0,1762 # 800083a0 <states.1801+0x118>
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	8b4080e7          	jalr	-1868(ra) # 8000057a <printf>
    panic("kerneltrap");
    80002cce:	00005517          	auipc	a0,0x5
    80002cd2:	6ea50513          	addi	a0,a0,1770 # 800083b8 <states.1801+0x130>
    80002cd6:	ffffe097          	auipc	ra,0xffffe
    80002cda:	85a080e7          	jalr	-1958(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	d16080e7          	jalr	-746(ra) # 800019f4 <myproc>
    80002ce6:	d541                	beqz	a0,80002c6e <kerneltrap+0x38>
    80002ce8:	fffff097          	auipc	ra,0xfffff
    80002cec:	d0c080e7          	jalr	-756(ra) # 800019f4 <myproc>
    80002cf0:	4d18                	lw	a4,24(a0)
    80002cf2:	478d                	li	a5,3
    80002cf4:	f6f71de3          	bne	a4,a5,80002c6e <kerneltrap+0x38>
    yield();
    80002cf8:	fffff097          	auipc	ra,0xfffff
    80002cfc:	6c0080e7          	jalr	1728(ra) # 800023b8 <yield>
    80002d00:	b7bd                	j	80002c6e <kerneltrap+0x38>

0000000080002d02 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d02:	1101                	addi	sp,sp,-32
    80002d04:	ec06                	sd	ra,24(sp)
    80002d06:	e822                	sd	s0,16(sp)
    80002d08:	e426                	sd	s1,8(sp)
    80002d0a:	1000                	addi	s0,sp,32
    80002d0c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	ce6080e7          	jalr	-794(ra) # 800019f4 <myproc>
  switch (n) {
    80002d16:	4795                	li	a5,5
    80002d18:	0497e163          	bltu	a5,s1,80002d5a <argraw+0x58>
    80002d1c:	048a                	slli	s1,s1,0x2
    80002d1e:	00005717          	auipc	a4,0x5
    80002d22:	6d270713          	addi	a4,a4,1746 # 800083f0 <states.1801+0x168>
    80002d26:	94ba                	add	s1,s1,a4
    80002d28:	409c                	lw	a5,0(s1)
    80002d2a:	97ba                	add	a5,a5,a4
    80002d2c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d2e:	6d3c                	ld	a5,88(a0)
    80002d30:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d32:	60e2                	ld	ra,24(sp)
    80002d34:	6442                	ld	s0,16(sp)
    80002d36:	64a2                	ld	s1,8(sp)
    80002d38:	6105                	addi	sp,sp,32
    80002d3a:	8082                	ret
    return p->trapframe->a1;
    80002d3c:	6d3c                	ld	a5,88(a0)
    80002d3e:	7fa8                	ld	a0,120(a5)
    80002d40:	bfcd                	j	80002d32 <argraw+0x30>
    return p->trapframe->a2;
    80002d42:	6d3c                	ld	a5,88(a0)
    80002d44:	63c8                	ld	a0,128(a5)
    80002d46:	b7f5                	j	80002d32 <argraw+0x30>
    return p->trapframe->a3;
    80002d48:	6d3c                	ld	a5,88(a0)
    80002d4a:	67c8                	ld	a0,136(a5)
    80002d4c:	b7dd                	j	80002d32 <argraw+0x30>
    return p->trapframe->a4;
    80002d4e:	6d3c                	ld	a5,88(a0)
    80002d50:	6bc8                	ld	a0,144(a5)
    80002d52:	b7c5                	j	80002d32 <argraw+0x30>
    return p->trapframe->a5;
    80002d54:	6d3c                	ld	a5,88(a0)
    80002d56:	6fc8                	ld	a0,152(a5)
    80002d58:	bfe9                	j	80002d32 <argraw+0x30>
  panic("argraw");
    80002d5a:	00005517          	auipc	a0,0x5
    80002d5e:	66e50513          	addi	a0,a0,1646 # 800083c8 <states.1801+0x140>
    80002d62:	ffffd097          	auipc	ra,0xffffd
    80002d66:	7ce080e7          	jalr	1998(ra) # 80000530 <panic>

0000000080002d6a <fetchaddr>:
{
    80002d6a:	1101                	addi	sp,sp,-32
    80002d6c:	ec06                	sd	ra,24(sp)
    80002d6e:	e822                	sd	s0,16(sp)
    80002d70:	e426                	sd	s1,8(sp)
    80002d72:	e04a                	sd	s2,0(sp)
    80002d74:	1000                	addi	s0,sp,32
    80002d76:	84aa                	mv	s1,a0
    80002d78:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	c7a080e7          	jalr	-902(ra) # 800019f4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d82:	653c                	ld	a5,72(a0)
    80002d84:	02f4f863          	bgeu	s1,a5,80002db4 <fetchaddr+0x4a>
    80002d88:	00848713          	addi	a4,s1,8
    80002d8c:	02e7e663          	bltu	a5,a4,80002db8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d90:	46a1                	li	a3,8
    80002d92:	8626                	mv	a2,s1
    80002d94:	85ca                	mv	a1,s2
    80002d96:	6928                	ld	a0,80(a0)
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	92c080e7          	jalr	-1748(ra) # 800016c4 <copyin>
    80002da0:	00a03533          	snez	a0,a0
    80002da4:	40a00533          	neg	a0,a0
}
    80002da8:	60e2                	ld	ra,24(sp)
    80002daa:	6442                	ld	s0,16(sp)
    80002dac:	64a2                	ld	s1,8(sp)
    80002dae:	6902                	ld	s2,0(sp)
    80002db0:	6105                	addi	sp,sp,32
    80002db2:	8082                	ret
    return -1;
    80002db4:	557d                	li	a0,-1
    80002db6:	bfcd                	j	80002da8 <fetchaddr+0x3e>
    80002db8:	557d                	li	a0,-1
    80002dba:	b7fd                	j	80002da8 <fetchaddr+0x3e>

0000000080002dbc <fetchstr>:
{
    80002dbc:	7179                	addi	sp,sp,-48
    80002dbe:	f406                	sd	ra,40(sp)
    80002dc0:	f022                	sd	s0,32(sp)
    80002dc2:	ec26                	sd	s1,24(sp)
    80002dc4:	e84a                	sd	s2,16(sp)
    80002dc6:	e44e                	sd	s3,8(sp)
    80002dc8:	1800                	addi	s0,sp,48
    80002dca:	892a                	mv	s2,a0
    80002dcc:	84ae                	mv	s1,a1
    80002dce:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	c24080e7          	jalr	-988(ra) # 800019f4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dd8:	86ce                	mv	a3,s3
    80002dda:	864a                	mv	a2,s2
    80002ddc:	85a6                	mv	a1,s1
    80002dde:	6928                	ld	a0,80(a0)
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	970080e7          	jalr	-1680(ra) # 80001750 <copyinstr>
  if(err < 0)
    80002de8:	00054763          	bltz	a0,80002df6 <fetchstr+0x3a>
  return strlen(buf);
    80002dec:	8526                	mv	a0,s1
    80002dee:	ffffe097          	auipc	ra,0xffffe
    80002df2:	06c080e7          	jalr	108(ra) # 80000e5a <strlen>
}
    80002df6:	70a2                	ld	ra,40(sp)
    80002df8:	7402                	ld	s0,32(sp)
    80002dfa:	64e2                	ld	s1,24(sp)
    80002dfc:	6942                	ld	s2,16(sp)
    80002dfe:	69a2                	ld	s3,8(sp)
    80002e00:	6145                	addi	sp,sp,48
    80002e02:	8082                	ret

0000000080002e04 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e04:	1101                	addi	sp,sp,-32
    80002e06:	ec06                	sd	ra,24(sp)
    80002e08:	e822                	sd	s0,16(sp)
    80002e0a:	e426                	sd	s1,8(sp)
    80002e0c:	1000                	addi	s0,sp,32
    80002e0e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	ef2080e7          	jalr	-270(ra) # 80002d02 <argraw>
    80002e18:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e1a:	4501                	li	a0,0
    80002e1c:	60e2                	ld	ra,24(sp)
    80002e1e:	6442                	ld	s0,16(sp)
    80002e20:	64a2                	ld	s1,8(sp)
    80002e22:	6105                	addi	sp,sp,32
    80002e24:	8082                	ret

0000000080002e26 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	e426                	sd	s1,8(sp)
    80002e2e:	1000                	addi	s0,sp,32
    80002e30:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e32:	00000097          	auipc	ra,0x0
    80002e36:	ed0080e7          	jalr	-304(ra) # 80002d02 <argraw>
    80002e3a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e3c:	4501                	li	a0,0
    80002e3e:	60e2                	ld	ra,24(sp)
    80002e40:	6442                	ld	s0,16(sp)
    80002e42:	64a2                	ld	s1,8(sp)
    80002e44:	6105                	addi	sp,sp,32
    80002e46:	8082                	ret

0000000080002e48 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e48:	1101                	addi	sp,sp,-32
    80002e4a:	ec06                	sd	ra,24(sp)
    80002e4c:	e822                	sd	s0,16(sp)
    80002e4e:	e426                	sd	s1,8(sp)
    80002e50:	e04a                	sd	s2,0(sp)
    80002e52:	1000                	addi	s0,sp,32
    80002e54:	84ae                	mv	s1,a1
    80002e56:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	eaa080e7          	jalr	-342(ra) # 80002d02 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e60:	864a                	mv	a2,s2
    80002e62:	85a6                	mv	a1,s1
    80002e64:	00000097          	auipc	ra,0x0
    80002e68:	f58080e7          	jalr	-168(ra) # 80002dbc <fetchstr>
}
    80002e6c:	60e2                	ld	ra,24(sp)
    80002e6e:	6442                	ld	s0,16(sp)
    80002e70:	64a2                	ld	s1,8(sp)
    80002e72:	6902                	ld	s2,0(sp)
    80002e74:	6105                	addi	sp,sp,32
    80002e76:	8082                	ret

0000000080002e78 <syscall>:
[SYS_munmap]  sys_munmap,
};

void
syscall(void)
{
    80002e78:	1101                	addi	sp,sp,-32
    80002e7a:	ec06                	sd	ra,24(sp)
    80002e7c:	e822                	sd	s0,16(sp)
    80002e7e:	e426                	sd	s1,8(sp)
    80002e80:	e04a                	sd	s2,0(sp)
    80002e82:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	b70080e7          	jalr	-1168(ra) # 800019f4 <myproc>
    80002e8c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e8e:	05853903          	ld	s2,88(a0)
    80002e92:	0a893783          	ld	a5,168(s2)
    80002e96:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e9a:	37fd                	addiw	a5,a5,-1
    80002e9c:	4759                	li	a4,22
    80002e9e:	00f76f63          	bltu	a4,a5,80002ebc <syscall+0x44>
    80002ea2:	00369713          	slli	a4,a3,0x3
    80002ea6:	00005797          	auipc	a5,0x5
    80002eaa:	56278793          	addi	a5,a5,1378 # 80008408 <syscalls>
    80002eae:	97ba                	add	a5,a5,a4
    80002eb0:	639c                	ld	a5,0(a5)
    80002eb2:	c789                	beqz	a5,80002ebc <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002eb4:	9782                	jalr	a5
    80002eb6:	06a93823          	sd	a0,112(s2)
    80002eba:	a839                	j	80002ed8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ebc:	15848613          	addi	a2,s1,344
    80002ec0:	5c8c                	lw	a1,56(s1)
    80002ec2:	00005517          	auipc	a0,0x5
    80002ec6:	50e50513          	addi	a0,a0,1294 # 800083d0 <states.1801+0x148>
    80002eca:	ffffd097          	auipc	ra,0xffffd
    80002ece:	6b0080e7          	jalr	1712(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ed2:	6cbc                	ld	a5,88(s1)
    80002ed4:	577d                	li	a4,-1
    80002ed6:	fbb8                	sd	a4,112(a5)
  }
}
    80002ed8:	60e2                	ld	ra,24(sp)
    80002eda:	6442                	ld	s0,16(sp)
    80002edc:	64a2                	ld	s1,8(sp)
    80002ede:	6902                	ld	s2,0(sp)
    80002ee0:	6105                	addi	sp,sp,32
    80002ee2:	8082                	ret

0000000080002ee4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ee4:	1101                	addi	sp,sp,-32
    80002ee6:	ec06                	sd	ra,24(sp)
    80002ee8:	e822                	sd	s0,16(sp)
    80002eea:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002eec:	fec40593          	addi	a1,s0,-20
    80002ef0:	4501                	li	a0,0
    80002ef2:	00000097          	auipc	ra,0x0
    80002ef6:	f12080e7          	jalr	-238(ra) # 80002e04 <argint>
    return -1;
    80002efa:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002efc:	00054963          	bltz	a0,80002f0e <sys_exit+0x2a>
  exit(n);
    80002f00:	fec42503          	lw	a0,-20(s0)
    80002f04:	fffff097          	auipc	ra,0xfffff
    80002f08:	200080e7          	jalr	512(ra) # 80002104 <exit>
  return 0;  // not reached
    80002f0c:	4781                	li	a5,0
}
    80002f0e:	853e                	mv	a0,a5
    80002f10:	60e2                	ld	ra,24(sp)
    80002f12:	6442                	ld	s0,16(sp)
    80002f14:	6105                	addi	sp,sp,32
    80002f16:	8082                	ret

0000000080002f18 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f18:	1141                	addi	sp,sp,-16
    80002f1a:	e406                	sd	ra,8(sp)
    80002f1c:	e022                	sd	s0,0(sp)
    80002f1e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	ad4080e7          	jalr	-1324(ra) # 800019f4 <myproc>
}
    80002f28:	5d08                	lw	a0,56(a0)
    80002f2a:	60a2                	ld	ra,8(sp)
    80002f2c:	6402                	ld	s0,0(sp)
    80002f2e:	0141                	addi	sp,sp,16
    80002f30:	8082                	ret

0000000080002f32 <sys_fork>:

uint64
sys_fork(void)
{
    80002f32:	1141                	addi	sp,sp,-16
    80002f34:	e406                	sd	ra,8(sp)
    80002f36:	e022                	sd	s0,0(sp)
    80002f38:	0800                	addi	s0,sp,16
  return fork();
    80002f3a:	fffff097          	auipc	ra,0xfffff
    80002f3e:	e7a080e7          	jalr	-390(ra) # 80001db4 <fork>
}
    80002f42:	60a2                	ld	ra,8(sp)
    80002f44:	6402                	ld	s0,0(sp)
    80002f46:	0141                	addi	sp,sp,16
    80002f48:	8082                	ret

0000000080002f4a <sys_wait>:

uint64
sys_wait(void)
{
    80002f4a:	1101                	addi	sp,sp,-32
    80002f4c:	ec06                	sd	ra,24(sp)
    80002f4e:	e822                	sd	s0,16(sp)
    80002f50:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f52:	fe840593          	addi	a1,s0,-24
    80002f56:	4501                	li	a0,0
    80002f58:	00000097          	auipc	ra,0x0
    80002f5c:	ece080e7          	jalr	-306(ra) # 80002e26 <argaddr>
    80002f60:	87aa                	mv	a5,a0
    return -1;
    80002f62:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f64:	0007c863          	bltz	a5,80002f74 <sys_wait+0x2a>
  return wait(p);
    80002f68:	fe843503          	ld	a0,-24(s0)
    80002f6c:	fffff097          	auipc	ra,0xfffff
    80002f70:	506080e7          	jalr	1286(ra) # 80002472 <wait>
}
    80002f74:	60e2                	ld	ra,24(sp)
    80002f76:	6442                	ld	s0,16(sp)
    80002f78:	6105                	addi	sp,sp,32
    80002f7a:	8082                	ret

0000000080002f7c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f7c:	7179                	addi	sp,sp,-48
    80002f7e:	f406                	sd	ra,40(sp)
    80002f80:	f022                	sd	s0,32(sp)
    80002f82:	ec26                	sd	s1,24(sp)
    80002f84:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f86:	fdc40593          	addi	a1,s0,-36
    80002f8a:	4501                	li	a0,0
    80002f8c:	00000097          	auipc	ra,0x0
    80002f90:	e78080e7          	jalr	-392(ra) # 80002e04 <argint>
    80002f94:	87aa                	mv	a5,a0
    return -1;
    80002f96:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f98:	0207c063          	bltz	a5,80002fb8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	a58080e7          	jalr	-1448(ra) # 800019f4 <myproc>
    80002fa4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fa6:	fdc42503          	lw	a0,-36(s0)
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	d96080e7          	jalr	-618(ra) # 80001d40 <growproc>
    80002fb2:	00054863          	bltz	a0,80002fc2 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fb6:	8526                	mv	a0,s1
}
    80002fb8:	70a2                	ld	ra,40(sp)
    80002fba:	7402                	ld	s0,32(sp)
    80002fbc:	64e2                	ld	s1,24(sp)
    80002fbe:	6145                	addi	sp,sp,48
    80002fc0:	8082                	ret
    return -1;
    80002fc2:	557d                	li	a0,-1
    80002fc4:	bfd5                	j	80002fb8 <sys_sbrk+0x3c>

0000000080002fc6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fc6:	7139                	addi	sp,sp,-64
    80002fc8:	fc06                	sd	ra,56(sp)
    80002fca:	f822                	sd	s0,48(sp)
    80002fcc:	f426                	sd	s1,40(sp)
    80002fce:	f04a                	sd	s2,32(sp)
    80002fd0:	ec4e                	sd	s3,24(sp)
    80002fd2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fd4:	fcc40593          	addi	a1,s0,-52
    80002fd8:	4501                	li	a0,0
    80002fda:	00000097          	auipc	ra,0x0
    80002fde:	e2a080e7          	jalr	-470(ra) # 80002e04 <argint>
    return -1;
    80002fe2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fe4:	06054563          	bltz	a0,8000304e <sys_sleep+0x88>
  acquire(&tickslock);
    80002fe8:	0001c517          	auipc	a0,0x1c
    80002fec:	0d050513          	addi	a0,a0,208 # 8001f0b8 <tickslock>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	be6080e7          	jalr	-1050(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002ff8:	00006917          	auipc	s2,0x6
    80002ffc:	03892903          	lw	s2,56(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003000:	fcc42783          	lw	a5,-52(s0)
    80003004:	cf85                	beqz	a5,8000303c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003006:	0001c997          	auipc	s3,0x1c
    8000300a:	0b298993          	addi	s3,s3,178 # 8001f0b8 <tickslock>
    8000300e:	00006497          	auipc	s1,0x6
    80003012:	02248493          	addi	s1,s1,34 # 80009030 <ticks>
    if(myproc()->killed){
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	9de080e7          	jalr	-1570(ra) # 800019f4 <myproc>
    8000301e:	591c                	lw	a5,48(a0)
    80003020:	ef9d                	bnez	a5,8000305e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003022:	85ce                	mv	a1,s3
    80003024:	8526                	mv	a0,s1
    80003026:	fffff097          	auipc	ra,0xfffff
    8000302a:	3ce080e7          	jalr	974(ra) # 800023f4 <sleep>
  while(ticks - ticks0 < n){
    8000302e:	409c                	lw	a5,0(s1)
    80003030:	412787bb          	subw	a5,a5,s2
    80003034:	fcc42703          	lw	a4,-52(s0)
    80003038:	fce7efe3          	bltu	a5,a4,80003016 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000303c:	0001c517          	auipc	a0,0x1c
    80003040:	07c50513          	addi	a0,a0,124 # 8001f0b8 <tickslock>
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	c46080e7          	jalr	-954(ra) # 80000c8a <release>
  return 0;
    8000304c:	4781                	li	a5,0
}
    8000304e:	853e                	mv	a0,a5
    80003050:	70e2                	ld	ra,56(sp)
    80003052:	7442                	ld	s0,48(sp)
    80003054:	74a2                	ld	s1,40(sp)
    80003056:	7902                	ld	s2,32(sp)
    80003058:	69e2                	ld	s3,24(sp)
    8000305a:	6121                	addi	sp,sp,64
    8000305c:	8082                	ret
      release(&tickslock);
    8000305e:	0001c517          	auipc	a0,0x1c
    80003062:	05a50513          	addi	a0,a0,90 # 8001f0b8 <tickslock>
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	c24080e7          	jalr	-988(ra) # 80000c8a <release>
      return -1;
    8000306e:	57fd                	li	a5,-1
    80003070:	bff9                	j	8000304e <sys_sleep+0x88>

0000000080003072 <sys_kill>:

uint64
sys_kill(void)
{
    80003072:	1101                	addi	sp,sp,-32
    80003074:	ec06                	sd	ra,24(sp)
    80003076:	e822                	sd	s0,16(sp)
    80003078:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000307a:	fec40593          	addi	a1,s0,-20
    8000307e:	4501                	li	a0,0
    80003080:	00000097          	auipc	ra,0x0
    80003084:	d84080e7          	jalr	-636(ra) # 80002e04 <argint>
    80003088:	87aa                	mv	a5,a0
    return -1;
    8000308a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000308c:	0007c863          	bltz	a5,8000309c <sys_kill+0x2a>
  return kill(pid);
    80003090:	fec42503          	lw	a0,-20(s0)
    80003094:	fffff097          	auipc	ra,0xfffff
    80003098:	550080e7          	jalr	1360(ra) # 800025e4 <kill>
}
    8000309c:	60e2                	ld	ra,24(sp)
    8000309e:	6442                	ld	s0,16(sp)
    800030a0:	6105                	addi	sp,sp,32
    800030a2:	8082                	ret

00000000800030a4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030a4:	1101                	addi	sp,sp,-32
    800030a6:	ec06                	sd	ra,24(sp)
    800030a8:	e822                	sd	s0,16(sp)
    800030aa:	e426                	sd	s1,8(sp)
    800030ac:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030ae:	0001c517          	auipc	a0,0x1c
    800030b2:	00a50513          	addi	a0,a0,10 # 8001f0b8 <tickslock>
    800030b6:	ffffe097          	auipc	ra,0xffffe
    800030ba:	b20080e7          	jalr	-1248(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800030be:	00006497          	auipc	s1,0x6
    800030c2:	f724a483          	lw	s1,-142(s1) # 80009030 <ticks>
  release(&tickslock);
    800030c6:	0001c517          	auipc	a0,0x1c
    800030ca:	ff250513          	addi	a0,a0,-14 # 8001f0b8 <tickslock>
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	bbc080e7          	jalr	-1092(ra) # 80000c8a <release>
  return xticks;
}
    800030d6:	02049513          	slli	a0,s1,0x20
    800030da:	9101                	srli	a0,a0,0x20
    800030dc:	60e2                	ld	ra,24(sp)
    800030de:	6442                	ld	s0,16(sp)
    800030e0:	64a2                	ld	s1,8(sp)
    800030e2:	6105                	addi	sp,sp,32
    800030e4:	8082                	ret

00000000800030e6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030e6:	7179                	addi	sp,sp,-48
    800030e8:	f406                	sd	ra,40(sp)
    800030ea:	f022                	sd	s0,32(sp)
    800030ec:	ec26                	sd	s1,24(sp)
    800030ee:	e84a                	sd	s2,16(sp)
    800030f0:	e44e                	sd	s3,8(sp)
    800030f2:	e052                	sd	s4,0(sp)
    800030f4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030f6:	00005597          	auipc	a1,0x5
    800030fa:	3d258593          	addi	a1,a1,978 # 800084c8 <syscalls+0xc0>
    800030fe:	0001c517          	auipc	a0,0x1c
    80003102:	fd250513          	addi	a0,a0,-46 # 8001f0d0 <bcache>
    80003106:	ffffe097          	auipc	ra,0xffffe
    8000310a:	a40080e7          	jalr	-1472(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000310e:	00024797          	auipc	a5,0x24
    80003112:	fc278793          	addi	a5,a5,-62 # 800270d0 <bcache+0x8000>
    80003116:	00024717          	auipc	a4,0x24
    8000311a:	22270713          	addi	a4,a4,546 # 80027338 <bcache+0x8268>
    8000311e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003122:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003126:	0001c497          	auipc	s1,0x1c
    8000312a:	fc248493          	addi	s1,s1,-62 # 8001f0e8 <bcache+0x18>
    b->next = bcache.head.next;
    8000312e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003130:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003132:	00005a17          	auipc	s4,0x5
    80003136:	39ea0a13          	addi	s4,s4,926 # 800084d0 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000313a:	2b893783          	ld	a5,696(s2)
    8000313e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003140:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003144:	85d2                	mv	a1,s4
    80003146:	01048513          	addi	a0,s1,16
    8000314a:	00001097          	auipc	ra,0x1
    8000314e:	4c4080e7          	jalr	1220(ra) # 8000460e <initsleeplock>
    bcache.head.next->prev = b;
    80003152:	2b893783          	ld	a5,696(s2)
    80003156:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003158:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000315c:	45848493          	addi	s1,s1,1112
    80003160:	fd349de3          	bne	s1,s3,8000313a <binit+0x54>
  }
}
    80003164:	70a2                	ld	ra,40(sp)
    80003166:	7402                	ld	s0,32(sp)
    80003168:	64e2                	ld	s1,24(sp)
    8000316a:	6942                	ld	s2,16(sp)
    8000316c:	69a2                	ld	s3,8(sp)
    8000316e:	6a02                	ld	s4,0(sp)
    80003170:	6145                	addi	sp,sp,48
    80003172:	8082                	ret

0000000080003174 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003174:	7179                	addi	sp,sp,-48
    80003176:	f406                	sd	ra,40(sp)
    80003178:	f022                	sd	s0,32(sp)
    8000317a:	ec26                	sd	s1,24(sp)
    8000317c:	e84a                	sd	s2,16(sp)
    8000317e:	e44e                	sd	s3,8(sp)
    80003180:	1800                	addi	s0,sp,48
    80003182:	89aa                	mv	s3,a0
    80003184:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003186:	0001c517          	auipc	a0,0x1c
    8000318a:	f4a50513          	addi	a0,a0,-182 # 8001f0d0 <bcache>
    8000318e:	ffffe097          	auipc	ra,0xffffe
    80003192:	a48080e7          	jalr	-1464(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003196:	00024497          	auipc	s1,0x24
    8000319a:	1f24b483          	ld	s1,498(s1) # 80027388 <bcache+0x82b8>
    8000319e:	00024797          	auipc	a5,0x24
    800031a2:	19a78793          	addi	a5,a5,410 # 80027338 <bcache+0x8268>
    800031a6:	02f48f63          	beq	s1,a5,800031e4 <bread+0x70>
    800031aa:	873e                	mv	a4,a5
    800031ac:	a021                	j	800031b4 <bread+0x40>
    800031ae:	68a4                	ld	s1,80(s1)
    800031b0:	02e48a63          	beq	s1,a4,800031e4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031b4:	449c                	lw	a5,8(s1)
    800031b6:	ff379ce3          	bne	a5,s3,800031ae <bread+0x3a>
    800031ba:	44dc                	lw	a5,12(s1)
    800031bc:	ff2799e3          	bne	a5,s2,800031ae <bread+0x3a>
      b->refcnt++;
    800031c0:	40bc                	lw	a5,64(s1)
    800031c2:	2785                	addiw	a5,a5,1
    800031c4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031c6:	0001c517          	auipc	a0,0x1c
    800031ca:	f0a50513          	addi	a0,a0,-246 # 8001f0d0 <bcache>
    800031ce:	ffffe097          	auipc	ra,0xffffe
    800031d2:	abc080e7          	jalr	-1348(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800031d6:	01048513          	addi	a0,s1,16
    800031da:	00001097          	auipc	ra,0x1
    800031de:	46e080e7          	jalr	1134(ra) # 80004648 <acquiresleep>
      return b;
    800031e2:	a8b9                	j	80003240 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031e4:	00024497          	auipc	s1,0x24
    800031e8:	19c4b483          	ld	s1,412(s1) # 80027380 <bcache+0x82b0>
    800031ec:	00024797          	auipc	a5,0x24
    800031f0:	14c78793          	addi	a5,a5,332 # 80027338 <bcache+0x8268>
    800031f4:	00f48863          	beq	s1,a5,80003204 <bread+0x90>
    800031f8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031fa:	40bc                	lw	a5,64(s1)
    800031fc:	cf81                	beqz	a5,80003214 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031fe:	64a4                	ld	s1,72(s1)
    80003200:	fee49de3          	bne	s1,a4,800031fa <bread+0x86>
  panic("bget: no buffers");
    80003204:	00005517          	auipc	a0,0x5
    80003208:	2d450513          	addi	a0,a0,724 # 800084d8 <syscalls+0xd0>
    8000320c:	ffffd097          	auipc	ra,0xffffd
    80003210:	324080e7          	jalr	804(ra) # 80000530 <panic>
      b->dev = dev;
    80003214:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003218:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000321c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003220:	4785                	li	a5,1
    80003222:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003224:	0001c517          	auipc	a0,0x1c
    80003228:	eac50513          	addi	a0,a0,-340 # 8001f0d0 <bcache>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	a5e080e7          	jalr	-1442(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003234:	01048513          	addi	a0,s1,16
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	410080e7          	jalr	1040(ra) # 80004648 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003240:	409c                	lw	a5,0(s1)
    80003242:	cb89                	beqz	a5,80003254 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003244:	8526                	mv	a0,s1
    80003246:	70a2                	ld	ra,40(sp)
    80003248:	7402                	ld	s0,32(sp)
    8000324a:	64e2                	ld	s1,24(sp)
    8000324c:	6942                	ld	s2,16(sp)
    8000324e:	69a2                	ld	s3,8(sp)
    80003250:	6145                	addi	sp,sp,48
    80003252:	8082                	ret
    virtio_disk_rw(b, 0);
    80003254:	4581                	li	a1,0
    80003256:	8526                	mv	a0,s1
    80003258:	00003097          	auipc	ra,0x3
    8000325c:	34e080e7          	jalr	846(ra) # 800065a6 <virtio_disk_rw>
    b->valid = 1;
    80003260:	4785                	li	a5,1
    80003262:	c09c                	sw	a5,0(s1)
  return b;
    80003264:	b7c5                	j	80003244 <bread+0xd0>

0000000080003266 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003266:	1101                	addi	sp,sp,-32
    80003268:	ec06                	sd	ra,24(sp)
    8000326a:	e822                	sd	s0,16(sp)
    8000326c:	e426                	sd	s1,8(sp)
    8000326e:	1000                	addi	s0,sp,32
    80003270:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003272:	0541                	addi	a0,a0,16
    80003274:	00001097          	auipc	ra,0x1
    80003278:	46e080e7          	jalr	1134(ra) # 800046e2 <holdingsleep>
    8000327c:	cd01                	beqz	a0,80003294 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000327e:	4585                	li	a1,1
    80003280:	8526                	mv	a0,s1
    80003282:	00003097          	auipc	ra,0x3
    80003286:	324080e7          	jalr	804(ra) # 800065a6 <virtio_disk_rw>
}
    8000328a:	60e2                	ld	ra,24(sp)
    8000328c:	6442                	ld	s0,16(sp)
    8000328e:	64a2                	ld	s1,8(sp)
    80003290:	6105                	addi	sp,sp,32
    80003292:	8082                	ret
    panic("bwrite");
    80003294:	00005517          	auipc	a0,0x5
    80003298:	25c50513          	addi	a0,a0,604 # 800084f0 <syscalls+0xe8>
    8000329c:	ffffd097          	auipc	ra,0xffffd
    800032a0:	294080e7          	jalr	660(ra) # 80000530 <panic>

00000000800032a4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032a4:	1101                	addi	sp,sp,-32
    800032a6:	ec06                	sd	ra,24(sp)
    800032a8:	e822                	sd	s0,16(sp)
    800032aa:	e426                	sd	s1,8(sp)
    800032ac:	e04a                	sd	s2,0(sp)
    800032ae:	1000                	addi	s0,sp,32
    800032b0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032b2:	01050913          	addi	s2,a0,16
    800032b6:	854a                	mv	a0,s2
    800032b8:	00001097          	auipc	ra,0x1
    800032bc:	42a080e7          	jalr	1066(ra) # 800046e2 <holdingsleep>
    800032c0:	c92d                	beqz	a0,80003332 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032c2:	854a                	mv	a0,s2
    800032c4:	00001097          	auipc	ra,0x1
    800032c8:	3da080e7          	jalr	986(ra) # 8000469e <releasesleep>

  acquire(&bcache.lock);
    800032cc:	0001c517          	auipc	a0,0x1c
    800032d0:	e0450513          	addi	a0,a0,-508 # 8001f0d0 <bcache>
    800032d4:	ffffe097          	auipc	ra,0xffffe
    800032d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800032dc:	40bc                	lw	a5,64(s1)
    800032de:	37fd                	addiw	a5,a5,-1
    800032e0:	0007871b          	sext.w	a4,a5
    800032e4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032e6:	eb05                	bnez	a4,80003316 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032e8:	68bc                	ld	a5,80(s1)
    800032ea:	64b8                	ld	a4,72(s1)
    800032ec:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032ee:	64bc                	ld	a5,72(s1)
    800032f0:	68b8                	ld	a4,80(s1)
    800032f2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032f4:	00024797          	auipc	a5,0x24
    800032f8:	ddc78793          	addi	a5,a5,-548 # 800270d0 <bcache+0x8000>
    800032fc:	2b87b703          	ld	a4,696(a5)
    80003300:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003302:	00024717          	auipc	a4,0x24
    80003306:	03670713          	addi	a4,a4,54 # 80027338 <bcache+0x8268>
    8000330a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000330c:	2b87b703          	ld	a4,696(a5)
    80003310:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003312:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003316:	0001c517          	auipc	a0,0x1c
    8000331a:	dba50513          	addi	a0,a0,-582 # 8001f0d0 <bcache>
    8000331e:	ffffe097          	auipc	ra,0xffffe
    80003322:	96c080e7          	jalr	-1684(ra) # 80000c8a <release>
}
    80003326:	60e2                	ld	ra,24(sp)
    80003328:	6442                	ld	s0,16(sp)
    8000332a:	64a2                	ld	s1,8(sp)
    8000332c:	6902                	ld	s2,0(sp)
    8000332e:	6105                	addi	sp,sp,32
    80003330:	8082                	ret
    panic("brelse");
    80003332:	00005517          	auipc	a0,0x5
    80003336:	1c650513          	addi	a0,a0,454 # 800084f8 <syscalls+0xf0>
    8000333a:	ffffd097          	auipc	ra,0xffffd
    8000333e:	1f6080e7          	jalr	502(ra) # 80000530 <panic>

0000000080003342 <bpin>:

void
bpin(struct buf *b) {
    80003342:	1101                	addi	sp,sp,-32
    80003344:	ec06                	sd	ra,24(sp)
    80003346:	e822                	sd	s0,16(sp)
    80003348:	e426                	sd	s1,8(sp)
    8000334a:	1000                	addi	s0,sp,32
    8000334c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000334e:	0001c517          	auipc	a0,0x1c
    80003352:	d8250513          	addi	a0,a0,-638 # 8001f0d0 <bcache>
    80003356:	ffffe097          	auipc	ra,0xffffe
    8000335a:	880080e7          	jalr	-1920(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000335e:	40bc                	lw	a5,64(s1)
    80003360:	2785                	addiw	a5,a5,1
    80003362:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003364:	0001c517          	auipc	a0,0x1c
    80003368:	d6c50513          	addi	a0,a0,-660 # 8001f0d0 <bcache>
    8000336c:	ffffe097          	auipc	ra,0xffffe
    80003370:	91e080e7          	jalr	-1762(ra) # 80000c8a <release>
}
    80003374:	60e2                	ld	ra,24(sp)
    80003376:	6442                	ld	s0,16(sp)
    80003378:	64a2                	ld	s1,8(sp)
    8000337a:	6105                	addi	sp,sp,32
    8000337c:	8082                	ret

000000008000337e <bunpin>:

void
bunpin(struct buf *b) {
    8000337e:	1101                	addi	sp,sp,-32
    80003380:	ec06                	sd	ra,24(sp)
    80003382:	e822                	sd	s0,16(sp)
    80003384:	e426                	sd	s1,8(sp)
    80003386:	1000                	addi	s0,sp,32
    80003388:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000338a:	0001c517          	auipc	a0,0x1c
    8000338e:	d4650513          	addi	a0,a0,-698 # 8001f0d0 <bcache>
    80003392:	ffffe097          	auipc	ra,0xffffe
    80003396:	844080e7          	jalr	-1980(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000339a:	40bc                	lw	a5,64(s1)
    8000339c:	37fd                	addiw	a5,a5,-1
    8000339e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033a0:	0001c517          	auipc	a0,0x1c
    800033a4:	d3050513          	addi	a0,a0,-720 # 8001f0d0 <bcache>
    800033a8:	ffffe097          	auipc	ra,0xffffe
    800033ac:	8e2080e7          	jalr	-1822(ra) # 80000c8a <release>
}
    800033b0:	60e2                	ld	ra,24(sp)
    800033b2:	6442                	ld	s0,16(sp)
    800033b4:	64a2                	ld	s1,8(sp)
    800033b6:	6105                	addi	sp,sp,32
    800033b8:	8082                	ret

00000000800033ba <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033ba:	1101                	addi	sp,sp,-32
    800033bc:	ec06                	sd	ra,24(sp)
    800033be:	e822                	sd	s0,16(sp)
    800033c0:	e426                	sd	s1,8(sp)
    800033c2:	e04a                	sd	s2,0(sp)
    800033c4:	1000                	addi	s0,sp,32
    800033c6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033c8:	00d5d59b          	srliw	a1,a1,0xd
    800033cc:	00024797          	auipc	a5,0x24
    800033d0:	3e07a783          	lw	a5,992(a5) # 800277ac <sb+0x1c>
    800033d4:	9dbd                	addw	a1,a1,a5
    800033d6:	00000097          	auipc	ra,0x0
    800033da:	d9e080e7          	jalr	-610(ra) # 80003174 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033de:	0074f713          	andi	a4,s1,7
    800033e2:	4785                	li	a5,1
    800033e4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033e8:	14ce                	slli	s1,s1,0x33
    800033ea:	90d9                	srli	s1,s1,0x36
    800033ec:	00950733          	add	a4,a0,s1
    800033f0:	05874703          	lbu	a4,88(a4)
    800033f4:	00e7f6b3          	and	a3,a5,a4
    800033f8:	c69d                	beqz	a3,80003426 <bfree+0x6c>
    800033fa:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033fc:	94aa                	add	s1,s1,a0
    800033fe:	fff7c793          	not	a5,a5
    80003402:	8ff9                	and	a5,a5,a4
    80003404:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003408:	00001097          	auipc	ra,0x1
    8000340c:	118080e7          	jalr	280(ra) # 80004520 <log_write>
  brelse(bp);
    80003410:	854a                	mv	a0,s2
    80003412:	00000097          	auipc	ra,0x0
    80003416:	e92080e7          	jalr	-366(ra) # 800032a4 <brelse>
}
    8000341a:	60e2                	ld	ra,24(sp)
    8000341c:	6442                	ld	s0,16(sp)
    8000341e:	64a2                	ld	s1,8(sp)
    80003420:	6902                	ld	s2,0(sp)
    80003422:	6105                	addi	sp,sp,32
    80003424:	8082                	ret
    panic("freeing free block");
    80003426:	00005517          	auipc	a0,0x5
    8000342a:	0da50513          	addi	a0,a0,218 # 80008500 <syscalls+0xf8>
    8000342e:	ffffd097          	auipc	ra,0xffffd
    80003432:	102080e7          	jalr	258(ra) # 80000530 <panic>

0000000080003436 <balloc>:
{
    80003436:	711d                	addi	sp,sp,-96
    80003438:	ec86                	sd	ra,88(sp)
    8000343a:	e8a2                	sd	s0,80(sp)
    8000343c:	e4a6                	sd	s1,72(sp)
    8000343e:	e0ca                	sd	s2,64(sp)
    80003440:	fc4e                	sd	s3,56(sp)
    80003442:	f852                	sd	s4,48(sp)
    80003444:	f456                	sd	s5,40(sp)
    80003446:	f05a                	sd	s6,32(sp)
    80003448:	ec5e                	sd	s7,24(sp)
    8000344a:	e862                	sd	s8,16(sp)
    8000344c:	e466                	sd	s9,8(sp)
    8000344e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003450:	00024797          	auipc	a5,0x24
    80003454:	3447a783          	lw	a5,836(a5) # 80027794 <sb+0x4>
    80003458:	cbd1                	beqz	a5,800034ec <balloc+0xb6>
    8000345a:	8baa                	mv	s7,a0
    8000345c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000345e:	00024b17          	auipc	s6,0x24
    80003462:	332b0b13          	addi	s6,s6,818 # 80027790 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003466:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003468:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000346a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000346c:	6c89                	lui	s9,0x2
    8000346e:	a831                	j	8000348a <balloc+0x54>
    brelse(bp);
    80003470:	854a                	mv	a0,s2
    80003472:	00000097          	auipc	ra,0x0
    80003476:	e32080e7          	jalr	-462(ra) # 800032a4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000347a:	015c87bb          	addw	a5,s9,s5
    8000347e:	00078a9b          	sext.w	s5,a5
    80003482:	004b2703          	lw	a4,4(s6)
    80003486:	06eaf363          	bgeu	s5,a4,800034ec <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000348a:	41fad79b          	sraiw	a5,s5,0x1f
    8000348e:	0137d79b          	srliw	a5,a5,0x13
    80003492:	015787bb          	addw	a5,a5,s5
    80003496:	40d7d79b          	sraiw	a5,a5,0xd
    8000349a:	01cb2583          	lw	a1,28(s6)
    8000349e:	9dbd                	addw	a1,a1,a5
    800034a0:	855e                	mv	a0,s7
    800034a2:	00000097          	auipc	ra,0x0
    800034a6:	cd2080e7          	jalr	-814(ra) # 80003174 <bread>
    800034aa:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ac:	004b2503          	lw	a0,4(s6)
    800034b0:	000a849b          	sext.w	s1,s5
    800034b4:	8662                	mv	a2,s8
    800034b6:	faa4fde3          	bgeu	s1,a0,80003470 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034ba:	41f6579b          	sraiw	a5,a2,0x1f
    800034be:	01d7d69b          	srliw	a3,a5,0x1d
    800034c2:	00c6873b          	addw	a4,a3,a2
    800034c6:	00777793          	andi	a5,a4,7
    800034ca:	9f95                	subw	a5,a5,a3
    800034cc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034d0:	4037571b          	sraiw	a4,a4,0x3
    800034d4:	00e906b3          	add	a3,s2,a4
    800034d8:	0586c683          	lbu	a3,88(a3)
    800034dc:	00d7f5b3          	and	a1,a5,a3
    800034e0:	cd91                	beqz	a1,800034fc <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034e2:	2605                	addiw	a2,a2,1
    800034e4:	2485                	addiw	s1,s1,1
    800034e6:	fd4618e3          	bne	a2,s4,800034b6 <balloc+0x80>
    800034ea:	b759                	j	80003470 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034ec:	00005517          	auipc	a0,0x5
    800034f0:	02c50513          	addi	a0,a0,44 # 80008518 <syscalls+0x110>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	03c080e7          	jalr	60(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034fc:	974a                	add	a4,a4,s2
    800034fe:	8fd5                	or	a5,a5,a3
    80003500:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003504:	854a                	mv	a0,s2
    80003506:	00001097          	auipc	ra,0x1
    8000350a:	01a080e7          	jalr	26(ra) # 80004520 <log_write>
        brelse(bp);
    8000350e:	854a                	mv	a0,s2
    80003510:	00000097          	auipc	ra,0x0
    80003514:	d94080e7          	jalr	-620(ra) # 800032a4 <brelse>
  bp = bread(dev, bno);
    80003518:	85a6                	mv	a1,s1
    8000351a:	855e                	mv	a0,s7
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	c58080e7          	jalr	-936(ra) # 80003174 <bread>
    80003524:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003526:	40000613          	li	a2,1024
    8000352a:	4581                	li	a1,0
    8000352c:	05850513          	addi	a0,a0,88
    80003530:	ffffd097          	auipc	ra,0xffffd
    80003534:	7a2080e7          	jalr	1954(ra) # 80000cd2 <memset>
  log_write(bp);
    80003538:	854a                	mv	a0,s2
    8000353a:	00001097          	auipc	ra,0x1
    8000353e:	fe6080e7          	jalr	-26(ra) # 80004520 <log_write>
  brelse(bp);
    80003542:	854a                	mv	a0,s2
    80003544:	00000097          	auipc	ra,0x0
    80003548:	d60080e7          	jalr	-672(ra) # 800032a4 <brelse>
}
    8000354c:	8526                	mv	a0,s1
    8000354e:	60e6                	ld	ra,88(sp)
    80003550:	6446                	ld	s0,80(sp)
    80003552:	64a6                	ld	s1,72(sp)
    80003554:	6906                	ld	s2,64(sp)
    80003556:	79e2                	ld	s3,56(sp)
    80003558:	7a42                	ld	s4,48(sp)
    8000355a:	7aa2                	ld	s5,40(sp)
    8000355c:	7b02                	ld	s6,32(sp)
    8000355e:	6be2                	ld	s7,24(sp)
    80003560:	6c42                	ld	s8,16(sp)
    80003562:	6ca2                	ld	s9,8(sp)
    80003564:	6125                	addi	sp,sp,96
    80003566:	8082                	ret

0000000080003568 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003568:	7179                	addi	sp,sp,-48
    8000356a:	f406                	sd	ra,40(sp)
    8000356c:	f022                	sd	s0,32(sp)
    8000356e:	ec26                	sd	s1,24(sp)
    80003570:	e84a                	sd	s2,16(sp)
    80003572:	e44e                	sd	s3,8(sp)
    80003574:	e052                	sd	s4,0(sp)
    80003576:	1800                	addi	s0,sp,48
    80003578:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000357a:	47ad                	li	a5,11
    8000357c:	04b7fe63          	bgeu	a5,a1,800035d8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003580:	ff45849b          	addiw	s1,a1,-12
    80003584:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003588:	0ff00793          	li	a5,255
    8000358c:	0ae7e363          	bltu	a5,a4,80003632 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003590:	08052583          	lw	a1,128(a0)
    80003594:	c5ad                	beqz	a1,800035fe <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003596:	00092503          	lw	a0,0(s2)
    8000359a:	00000097          	auipc	ra,0x0
    8000359e:	bda080e7          	jalr	-1062(ra) # 80003174 <bread>
    800035a2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035a4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035a8:	02049593          	slli	a1,s1,0x20
    800035ac:	9181                	srli	a1,a1,0x20
    800035ae:	058a                	slli	a1,a1,0x2
    800035b0:	00b784b3          	add	s1,a5,a1
    800035b4:	0004a983          	lw	s3,0(s1)
    800035b8:	04098d63          	beqz	s3,80003612 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035bc:	8552                	mv	a0,s4
    800035be:	00000097          	auipc	ra,0x0
    800035c2:	ce6080e7          	jalr	-794(ra) # 800032a4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035c6:	854e                	mv	a0,s3
    800035c8:	70a2                	ld	ra,40(sp)
    800035ca:	7402                	ld	s0,32(sp)
    800035cc:	64e2                	ld	s1,24(sp)
    800035ce:	6942                	ld	s2,16(sp)
    800035d0:	69a2                	ld	s3,8(sp)
    800035d2:	6a02                	ld	s4,0(sp)
    800035d4:	6145                	addi	sp,sp,48
    800035d6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035d8:	02059493          	slli	s1,a1,0x20
    800035dc:	9081                	srli	s1,s1,0x20
    800035de:	048a                	slli	s1,s1,0x2
    800035e0:	94aa                	add	s1,s1,a0
    800035e2:	0504a983          	lw	s3,80(s1)
    800035e6:	fe0990e3          	bnez	s3,800035c6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035ea:	4108                	lw	a0,0(a0)
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	e4a080e7          	jalr	-438(ra) # 80003436 <balloc>
    800035f4:	0005099b          	sext.w	s3,a0
    800035f8:	0534a823          	sw	s3,80(s1)
    800035fc:	b7e9                	j	800035c6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035fe:	4108                	lw	a0,0(a0)
    80003600:	00000097          	auipc	ra,0x0
    80003604:	e36080e7          	jalr	-458(ra) # 80003436 <balloc>
    80003608:	0005059b          	sext.w	a1,a0
    8000360c:	08b92023          	sw	a1,128(s2)
    80003610:	b759                	j	80003596 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003612:	00092503          	lw	a0,0(s2)
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	e20080e7          	jalr	-480(ra) # 80003436 <balloc>
    8000361e:	0005099b          	sext.w	s3,a0
    80003622:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003626:	8552                	mv	a0,s4
    80003628:	00001097          	auipc	ra,0x1
    8000362c:	ef8080e7          	jalr	-264(ra) # 80004520 <log_write>
    80003630:	b771                	j	800035bc <bmap+0x54>
  panic("bmap: out of range");
    80003632:	00005517          	auipc	a0,0x5
    80003636:	efe50513          	addi	a0,a0,-258 # 80008530 <syscalls+0x128>
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	ef6080e7          	jalr	-266(ra) # 80000530 <panic>

0000000080003642 <iget>:
{
    80003642:	7179                	addi	sp,sp,-48
    80003644:	f406                	sd	ra,40(sp)
    80003646:	f022                	sd	s0,32(sp)
    80003648:	ec26                	sd	s1,24(sp)
    8000364a:	e84a                	sd	s2,16(sp)
    8000364c:	e44e                	sd	s3,8(sp)
    8000364e:	e052                	sd	s4,0(sp)
    80003650:	1800                	addi	s0,sp,48
    80003652:	89aa                	mv	s3,a0
    80003654:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003656:	00024517          	auipc	a0,0x24
    8000365a:	15a50513          	addi	a0,a0,346 # 800277b0 <icache>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	578080e7          	jalr	1400(ra) # 80000bd6 <acquire>
  empty = 0;
    80003666:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003668:	00024497          	auipc	s1,0x24
    8000366c:	16048493          	addi	s1,s1,352 # 800277c8 <icache+0x18>
    80003670:	00026697          	auipc	a3,0x26
    80003674:	be868693          	addi	a3,a3,-1048 # 80029258 <log>
    80003678:	a039                	j	80003686 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000367a:	02090b63          	beqz	s2,800036b0 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000367e:	08848493          	addi	s1,s1,136
    80003682:	02d48a63          	beq	s1,a3,800036b6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003686:	449c                	lw	a5,8(s1)
    80003688:	fef059e3          	blez	a5,8000367a <iget+0x38>
    8000368c:	4098                	lw	a4,0(s1)
    8000368e:	ff3716e3          	bne	a4,s3,8000367a <iget+0x38>
    80003692:	40d8                	lw	a4,4(s1)
    80003694:	ff4713e3          	bne	a4,s4,8000367a <iget+0x38>
      ip->ref++;
    80003698:	2785                	addiw	a5,a5,1
    8000369a:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000369c:	00024517          	auipc	a0,0x24
    800036a0:	11450513          	addi	a0,a0,276 # 800277b0 <icache>
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	5e6080e7          	jalr	1510(ra) # 80000c8a <release>
      return ip;
    800036ac:	8926                	mv	s2,s1
    800036ae:	a03d                	j	800036dc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036b0:	f7f9                	bnez	a5,8000367e <iget+0x3c>
    800036b2:	8926                	mv	s2,s1
    800036b4:	b7e9                	j	8000367e <iget+0x3c>
  if(empty == 0)
    800036b6:	02090c63          	beqz	s2,800036ee <iget+0xac>
  ip->dev = dev;
    800036ba:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036be:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036c2:	4785                	li	a5,1
    800036c4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036c8:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036cc:	00024517          	auipc	a0,0x24
    800036d0:	0e450513          	addi	a0,a0,228 # 800277b0 <icache>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	5b6080e7          	jalr	1462(ra) # 80000c8a <release>
}
    800036dc:	854a                	mv	a0,s2
    800036de:	70a2                	ld	ra,40(sp)
    800036e0:	7402                	ld	s0,32(sp)
    800036e2:	64e2                	ld	s1,24(sp)
    800036e4:	6942                	ld	s2,16(sp)
    800036e6:	69a2                	ld	s3,8(sp)
    800036e8:	6a02                	ld	s4,0(sp)
    800036ea:	6145                	addi	sp,sp,48
    800036ec:	8082                	ret
    panic("iget: no inodes");
    800036ee:	00005517          	auipc	a0,0x5
    800036f2:	e5a50513          	addi	a0,a0,-422 # 80008548 <syscalls+0x140>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	e3a080e7          	jalr	-454(ra) # 80000530 <panic>

00000000800036fe <fsinit>:
fsinit(int dev) {
    800036fe:	7179                	addi	sp,sp,-48
    80003700:	f406                	sd	ra,40(sp)
    80003702:	f022                	sd	s0,32(sp)
    80003704:	ec26                	sd	s1,24(sp)
    80003706:	e84a                	sd	s2,16(sp)
    80003708:	e44e                	sd	s3,8(sp)
    8000370a:	1800                	addi	s0,sp,48
    8000370c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000370e:	4585                	li	a1,1
    80003710:	00000097          	auipc	ra,0x0
    80003714:	a64080e7          	jalr	-1436(ra) # 80003174 <bread>
    80003718:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000371a:	00024997          	auipc	s3,0x24
    8000371e:	07698993          	addi	s3,s3,118 # 80027790 <sb>
    80003722:	02000613          	li	a2,32
    80003726:	05850593          	addi	a1,a0,88
    8000372a:	854e                	mv	a0,s3
    8000372c:	ffffd097          	auipc	ra,0xffffd
    80003730:	606080e7          	jalr	1542(ra) # 80000d32 <memmove>
  brelse(bp);
    80003734:	8526                	mv	a0,s1
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	b6e080e7          	jalr	-1170(ra) # 800032a4 <brelse>
  if(sb.magic != FSMAGIC)
    8000373e:	0009a703          	lw	a4,0(s3)
    80003742:	102037b7          	lui	a5,0x10203
    80003746:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000374a:	02f71263          	bne	a4,a5,8000376e <fsinit+0x70>
  initlog(dev, &sb);
    8000374e:	00024597          	auipc	a1,0x24
    80003752:	04258593          	addi	a1,a1,66 # 80027790 <sb>
    80003756:	854a                	mv	a0,s2
    80003758:	00001097          	auipc	ra,0x1
    8000375c:	b4c080e7          	jalr	-1204(ra) # 800042a4 <initlog>
}
    80003760:	70a2                	ld	ra,40(sp)
    80003762:	7402                	ld	s0,32(sp)
    80003764:	64e2                	ld	s1,24(sp)
    80003766:	6942                	ld	s2,16(sp)
    80003768:	69a2                	ld	s3,8(sp)
    8000376a:	6145                	addi	sp,sp,48
    8000376c:	8082                	ret
    panic("invalid file system");
    8000376e:	00005517          	auipc	a0,0x5
    80003772:	dea50513          	addi	a0,a0,-534 # 80008558 <syscalls+0x150>
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	dba080e7          	jalr	-582(ra) # 80000530 <panic>

000000008000377e <iinit>:
{
    8000377e:	7179                	addi	sp,sp,-48
    80003780:	f406                	sd	ra,40(sp)
    80003782:	f022                	sd	s0,32(sp)
    80003784:	ec26                	sd	s1,24(sp)
    80003786:	e84a                	sd	s2,16(sp)
    80003788:	e44e                	sd	s3,8(sp)
    8000378a:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000378c:	00005597          	auipc	a1,0x5
    80003790:	de458593          	addi	a1,a1,-540 # 80008570 <syscalls+0x168>
    80003794:	00024517          	auipc	a0,0x24
    80003798:	01c50513          	addi	a0,a0,28 # 800277b0 <icache>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	3aa080e7          	jalr	938(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037a4:	00024497          	auipc	s1,0x24
    800037a8:	03448493          	addi	s1,s1,52 # 800277d8 <icache+0x28>
    800037ac:	00026997          	auipc	s3,0x26
    800037b0:	abc98993          	addi	s3,s3,-1348 # 80029268 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037b4:	00005917          	auipc	s2,0x5
    800037b8:	dc490913          	addi	s2,s2,-572 # 80008578 <syscalls+0x170>
    800037bc:	85ca                	mv	a1,s2
    800037be:	8526                	mv	a0,s1
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	e4e080e7          	jalr	-434(ra) # 8000460e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037c8:	08848493          	addi	s1,s1,136
    800037cc:	ff3498e3          	bne	s1,s3,800037bc <iinit+0x3e>
}
    800037d0:	70a2                	ld	ra,40(sp)
    800037d2:	7402                	ld	s0,32(sp)
    800037d4:	64e2                	ld	s1,24(sp)
    800037d6:	6942                	ld	s2,16(sp)
    800037d8:	69a2                	ld	s3,8(sp)
    800037da:	6145                	addi	sp,sp,48
    800037dc:	8082                	ret

00000000800037de <ialloc>:
{
    800037de:	715d                	addi	sp,sp,-80
    800037e0:	e486                	sd	ra,72(sp)
    800037e2:	e0a2                	sd	s0,64(sp)
    800037e4:	fc26                	sd	s1,56(sp)
    800037e6:	f84a                	sd	s2,48(sp)
    800037e8:	f44e                	sd	s3,40(sp)
    800037ea:	f052                	sd	s4,32(sp)
    800037ec:	ec56                	sd	s5,24(sp)
    800037ee:	e85a                	sd	s6,16(sp)
    800037f0:	e45e                	sd	s7,8(sp)
    800037f2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037f4:	00024717          	auipc	a4,0x24
    800037f8:	fa872703          	lw	a4,-88(a4) # 8002779c <sb+0xc>
    800037fc:	4785                	li	a5,1
    800037fe:	04e7fa63          	bgeu	a5,a4,80003852 <ialloc+0x74>
    80003802:	8aaa                	mv	s5,a0
    80003804:	8bae                	mv	s7,a1
    80003806:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003808:	00024a17          	auipc	s4,0x24
    8000380c:	f88a0a13          	addi	s4,s4,-120 # 80027790 <sb>
    80003810:	00048b1b          	sext.w	s6,s1
    80003814:	0044d593          	srli	a1,s1,0x4
    80003818:	018a2783          	lw	a5,24(s4)
    8000381c:	9dbd                	addw	a1,a1,a5
    8000381e:	8556                	mv	a0,s5
    80003820:	00000097          	auipc	ra,0x0
    80003824:	954080e7          	jalr	-1708(ra) # 80003174 <bread>
    80003828:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000382a:	05850993          	addi	s3,a0,88
    8000382e:	00f4f793          	andi	a5,s1,15
    80003832:	079a                	slli	a5,a5,0x6
    80003834:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003836:	00099783          	lh	a5,0(s3)
    8000383a:	c785                	beqz	a5,80003862 <ialloc+0x84>
    brelse(bp);
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	a68080e7          	jalr	-1432(ra) # 800032a4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003844:	0485                	addi	s1,s1,1
    80003846:	00ca2703          	lw	a4,12(s4)
    8000384a:	0004879b          	sext.w	a5,s1
    8000384e:	fce7e1e3          	bltu	a5,a4,80003810 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003852:	00005517          	auipc	a0,0x5
    80003856:	d2e50513          	addi	a0,a0,-722 # 80008580 <syscalls+0x178>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	cd6080e7          	jalr	-810(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    80003862:	04000613          	li	a2,64
    80003866:	4581                	li	a1,0
    80003868:	854e                	mv	a0,s3
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	468080e7          	jalr	1128(ra) # 80000cd2 <memset>
      dip->type = type;
    80003872:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003876:	854a                	mv	a0,s2
    80003878:	00001097          	auipc	ra,0x1
    8000387c:	ca8080e7          	jalr	-856(ra) # 80004520 <log_write>
      brelse(bp);
    80003880:	854a                	mv	a0,s2
    80003882:	00000097          	auipc	ra,0x0
    80003886:	a22080e7          	jalr	-1502(ra) # 800032a4 <brelse>
      return iget(dev, inum);
    8000388a:	85da                	mv	a1,s6
    8000388c:	8556                	mv	a0,s5
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	db4080e7          	jalr	-588(ra) # 80003642 <iget>
}
    80003896:	60a6                	ld	ra,72(sp)
    80003898:	6406                	ld	s0,64(sp)
    8000389a:	74e2                	ld	s1,56(sp)
    8000389c:	7942                	ld	s2,48(sp)
    8000389e:	79a2                	ld	s3,40(sp)
    800038a0:	7a02                	ld	s4,32(sp)
    800038a2:	6ae2                	ld	s5,24(sp)
    800038a4:	6b42                	ld	s6,16(sp)
    800038a6:	6ba2                	ld	s7,8(sp)
    800038a8:	6161                	addi	sp,sp,80
    800038aa:	8082                	ret

00000000800038ac <iupdate>:
{
    800038ac:	1101                	addi	sp,sp,-32
    800038ae:	ec06                	sd	ra,24(sp)
    800038b0:	e822                	sd	s0,16(sp)
    800038b2:	e426                	sd	s1,8(sp)
    800038b4:	e04a                	sd	s2,0(sp)
    800038b6:	1000                	addi	s0,sp,32
    800038b8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038ba:	415c                	lw	a5,4(a0)
    800038bc:	0047d79b          	srliw	a5,a5,0x4
    800038c0:	00024597          	auipc	a1,0x24
    800038c4:	ee85a583          	lw	a1,-280(a1) # 800277a8 <sb+0x18>
    800038c8:	9dbd                	addw	a1,a1,a5
    800038ca:	4108                	lw	a0,0(a0)
    800038cc:	00000097          	auipc	ra,0x0
    800038d0:	8a8080e7          	jalr	-1880(ra) # 80003174 <bread>
    800038d4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038d6:	05850793          	addi	a5,a0,88
    800038da:	40c8                	lw	a0,4(s1)
    800038dc:	893d                	andi	a0,a0,15
    800038de:	051a                	slli	a0,a0,0x6
    800038e0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038e2:	04449703          	lh	a4,68(s1)
    800038e6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038ea:	04649703          	lh	a4,70(s1)
    800038ee:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038f2:	04849703          	lh	a4,72(s1)
    800038f6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038fa:	04a49703          	lh	a4,74(s1)
    800038fe:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003902:	44f8                	lw	a4,76(s1)
    80003904:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003906:	03400613          	li	a2,52
    8000390a:	05048593          	addi	a1,s1,80
    8000390e:	0531                	addi	a0,a0,12
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	422080e7          	jalr	1058(ra) # 80000d32 <memmove>
  log_write(bp);
    80003918:	854a                	mv	a0,s2
    8000391a:	00001097          	auipc	ra,0x1
    8000391e:	c06080e7          	jalr	-1018(ra) # 80004520 <log_write>
  brelse(bp);
    80003922:	854a                	mv	a0,s2
    80003924:	00000097          	auipc	ra,0x0
    80003928:	980080e7          	jalr	-1664(ra) # 800032a4 <brelse>
}
    8000392c:	60e2                	ld	ra,24(sp)
    8000392e:	6442                	ld	s0,16(sp)
    80003930:	64a2                	ld	s1,8(sp)
    80003932:	6902                	ld	s2,0(sp)
    80003934:	6105                	addi	sp,sp,32
    80003936:	8082                	ret

0000000080003938 <idup>:
{
    80003938:	1101                	addi	sp,sp,-32
    8000393a:	ec06                	sd	ra,24(sp)
    8000393c:	e822                	sd	s0,16(sp)
    8000393e:	e426                	sd	s1,8(sp)
    80003940:	1000                	addi	s0,sp,32
    80003942:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003944:	00024517          	auipc	a0,0x24
    80003948:	e6c50513          	addi	a0,a0,-404 # 800277b0 <icache>
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	28a080e7          	jalr	650(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003954:	449c                	lw	a5,8(s1)
    80003956:	2785                	addiw	a5,a5,1
    80003958:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000395a:	00024517          	auipc	a0,0x24
    8000395e:	e5650513          	addi	a0,a0,-426 # 800277b0 <icache>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	328080e7          	jalr	808(ra) # 80000c8a <release>
}
    8000396a:	8526                	mv	a0,s1
    8000396c:	60e2                	ld	ra,24(sp)
    8000396e:	6442                	ld	s0,16(sp)
    80003970:	64a2                	ld	s1,8(sp)
    80003972:	6105                	addi	sp,sp,32
    80003974:	8082                	ret

0000000080003976 <ilock>:
{
    80003976:	1101                	addi	sp,sp,-32
    80003978:	ec06                	sd	ra,24(sp)
    8000397a:	e822                	sd	s0,16(sp)
    8000397c:	e426                	sd	s1,8(sp)
    8000397e:	e04a                	sd	s2,0(sp)
    80003980:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003982:	c115                	beqz	a0,800039a6 <ilock+0x30>
    80003984:	84aa                	mv	s1,a0
    80003986:	451c                	lw	a5,8(a0)
    80003988:	00f05f63          	blez	a5,800039a6 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000398c:	0541                	addi	a0,a0,16
    8000398e:	00001097          	auipc	ra,0x1
    80003992:	cba080e7          	jalr	-838(ra) # 80004648 <acquiresleep>
  if(ip->valid == 0){
    80003996:	40bc                	lw	a5,64(s1)
    80003998:	cf99                	beqz	a5,800039b6 <ilock+0x40>
}
    8000399a:	60e2                	ld	ra,24(sp)
    8000399c:	6442                	ld	s0,16(sp)
    8000399e:	64a2                	ld	s1,8(sp)
    800039a0:	6902                	ld	s2,0(sp)
    800039a2:	6105                	addi	sp,sp,32
    800039a4:	8082                	ret
    panic("ilock");
    800039a6:	00005517          	auipc	a0,0x5
    800039aa:	bf250513          	addi	a0,a0,-1038 # 80008598 <syscalls+0x190>
    800039ae:	ffffd097          	auipc	ra,0xffffd
    800039b2:	b82080e7          	jalr	-1150(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039b6:	40dc                	lw	a5,4(s1)
    800039b8:	0047d79b          	srliw	a5,a5,0x4
    800039bc:	00024597          	auipc	a1,0x24
    800039c0:	dec5a583          	lw	a1,-532(a1) # 800277a8 <sb+0x18>
    800039c4:	9dbd                	addw	a1,a1,a5
    800039c6:	4088                	lw	a0,0(s1)
    800039c8:	fffff097          	auipc	ra,0xfffff
    800039cc:	7ac080e7          	jalr	1964(ra) # 80003174 <bread>
    800039d0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039d2:	05850593          	addi	a1,a0,88
    800039d6:	40dc                	lw	a5,4(s1)
    800039d8:	8bbd                	andi	a5,a5,15
    800039da:	079a                	slli	a5,a5,0x6
    800039dc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039de:	00059783          	lh	a5,0(a1)
    800039e2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039e6:	00259783          	lh	a5,2(a1)
    800039ea:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039ee:	00459783          	lh	a5,4(a1)
    800039f2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039f6:	00659783          	lh	a5,6(a1)
    800039fa:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039fe:	459c                	lw	a5,8(a1)
    80003a00:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a02:	03400613          	li	a2,52
    80003a06:	05b1                	addi	a1,a1,12
    80003a08:	05048513          	addi	a0,s1,80
    80003a0c:	ffffd097          	auipc	ra,0xffffd
    80003a10:	326080e7          	jalr	806(ra) # 80000d32 <memmove>
    brelse(bp);
    80003a14:	854a                	mv	a0,s2
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	88e080e7          	jalr	-1906(ra) # 800032a4 <brelse>
    ip->valid = 1;
    80003a1e:	4785                	li	a5,1
    80003a20:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a22:	04449783          	lh	a5,68(s1)
    80003a26:	fbb5                	bnez	a5,8000399a <ilock+0x24>
      panic("ilock: no type");
    80003a28:	00005517          	auipc	a0,0x5
    80003a2c:	b7850513          	addi	a0,a0,-1160 # 800085a0 <syscalls+0x198>
    80003a30:	ffffd097          	auipc	ra,0xffffd
    80003a34:	b00080e7          	jalr	-1280(ra) # 80000530 <panic>

0000000080003a38 <iunlock>:
{
    80003a38:	1101                	addi	sp,sp,-32
    80003a3a:	ec06                	sd	ra,24(sp)
    80003a3c:	e822                	sd	s0,16(sp)
    80003a3e:	e426                	sd	s1,8(sp)
    80003a40:	e04a                	sd	s2,0(sp)
    80003a42:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a44:	c905                	beqz	a0,80003a74 <iunlock+0x3c>
    80003a46:	84aa                	mv	s1,a0
    80003a48:	01050913          	addi	s2,a0,16
    80003a4c:	854a                	mv	a0,s2
    80003a4e:	00001097          	auipc	ra,0x1
    80003a52:	c94080e7          	jalr	-876(ra) # 800046e2 <holdingsleep>
    80003a56:	cd19                	beqz	a0,80003a74 <iunlock+0x3c>
    80003a58:	449c                	lw	a5,8(s1)
    80003a5a:	00f05d63          	blez	a5,80003a74 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a5e:	854a                	mv	a0,s2
    80003a60:	00001097          	auipc	ra,0x1
    80003a64:	c3e080e7          	jalr	-962(ra) # 8000469e <releasesleep>
}
    80003a68:	60e2                	ld	ra,24(sp)
    80003a6a:	6442                	ld	s0,16(sp)
    80003a6c:	64a2                	ld	s1,8(sp)
    80003a6e:	6902                	ld	s2,0(sp)
    80003a70:	6105                	addi	sp,sp,32
    80003a72:	8082                	ret
    panic("iunlock");
    80003a74:	00005517          	auipc	a0,0x5
    80003a78:	b3c50513          	addi	a0,a0,-1220 # 800085b0 <syscalls+0x1a8>
    80003a7c:	ffffd097          	auipc	ra,0xffffd
    80003a80:	ab4080e7          	jalr	-1356(ra) # 80000530 <panic>

0000000080003a84 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a84:	7179                	addi	sp,sp,-48
    80003a86:	f406                	sd	ra,40(sp)
    80003a88:	f022                	sd	s0,32(sp)
    80003a8a:	ec26                	sd	s1,24(sp)
    80003a8c:	e84a                	sd	s2,16(sp)
    80003a8e:	e44e                	sd	s3,8(sp)
    80003a90:	e052                	sd	s4,0(sp)
    80003a92:	1800                	addi	s0,sp,48
    80003a94:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a96:	05050493          	addi	s1,a0,80
    80003a9a:	08050913          	addi	s2,a0,128
    80003a9e:	a021                	j	80003aa6 <itrunc+0x22>
    80003aa0:	0491                	addi	s1,s1,4
    80003aa2:	01248d63          	beq	s1,s2,80003abc <itrunc+0x38>
    if(ip->addrs[i]){
    80003aa6:	408c                	lw	a1,0(s1)
    80003aa8:	dde5                	beqz	a1,80003aa0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003aaa:	0009a503          	lw	a0,0(s3)
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	90c080e7          	jalr	-1780(ra) # 800033ba <bfree>
      ip->addrs[i] = 0;
    80003ab6:	0004a023          	sw	zero,0(s1)
    80003aba:	b7dd                	j	80003aa0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003abc:	0809a583          	lw	a1,128(s3)
    80003ac0:	e185                	bnez	a1,80003ae0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ac2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ac6:	854e                	mv	a0,s3
    80003ac8:	00000097          	auipc	ra,0x0
    80003acc:	de4080e7          	jalr	-540(ra) # 800038ac <iupdate>
}
    80003ad0:	70a2                	ld	ra,40(sp)
    80003ad2:	7402                	ld	s0,32(sp)
    80003ad4:	64e2                	ld	s1,24(sp)
    80003ad6:	6942                	ld	s2,16(sp)
    80003ad8:	69a2                	ld	s3,8(sp)
    80003ada:	6a02                	ld	s4,0(sp)
    80003adc:	6145                	addi	sp,sp,48
    80003ade:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ae0:	0009a503          	lw	a0,0(s3)
    80003ae4:	fffff097          	auipc	ra,0xfffff
    80003ae8:	690080e7          	jalr	1680(ra) # 80003174 <bread>
    80003aec:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003aee:	05850493          	addi	s1,a0,88
    80003af2:	45850913          	addi	s2,a0,1112
    80003af6:	a811                	j	80003b0a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003af8:	0009a503          	lw	a0,0(s3)
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	8be080e7          	jalr	-1858(ra) # 800033ba <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b04:	0491                	addi	s1,s1,4
    80003b06:	01248563          	beq	s1,s2,80003b10 <itrunc+0x8c>
      if(a[j])
    80003b0a:	408c                	lw	a1,0(s1)
    80003b0c:	dde5                	beqz	a1,80003b04 <itrunc+0x80>
    80003b0e:	b7ed                	j	80003af8 <itrunc+0x74>
    brelse(bp);
    80003b10:	8552                	mv	a0,s4
    80003b12:	fffff097          	auipc	ra,0xfffff
    80003b16:	792080e7          	jalr	1938(ra) # 800032a4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b1a:	0809a583          	lw	a1,128(s3)
    80003b1e:	0009a503          	lw	a0,0(s3)
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	898080e7          	jalr	-1896(ra) # 800033ba <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b2a:	0809a023          	sw	zero,128(s3)
    80003b2e:	bf51                	j	80003ac2 <itrunc+0x3e>

0000000080003b30 <iput>:
{
    80003b30:	1101                	addi	sp,sp,-32
    80003b32:	ec06                	sd	ra,24(sp)
    80003b34:	e822                	sd	s0,16(sp)
    80003b36:	e426                	sd	s1,8(sp)
    80003b38:	e04a                	sd	s2,0(sp)
    80003b3a:	1000                	addi	s0,sp,32
    80003b3c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b3e:	00024517          	auipc	a0,0x24
    80003b42:	c7250513          	addi	a0,a0,-910 # 800277b0 <icache>
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	090080e7          	jalr	144(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b4e:	4498                	lw	a4,8(s1)
    80003b50:	4785                	li	a5,1
    80003b52:	02f70363          	beq	a4,a5,80003b78 <iput+0x48>
  ip->ref--;
    80003b56:	449c                	lw	a5,8(s1)
    80003b58:	37fd                	addiw	a5,a5,-1
    80003b5a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b5c:	00024517          	auipc	a0,0x24
    80003b60:	c5450513          	addi	a0,a0,-940 # 800277b0 <icache>
    80003b64:	ffffd097          	auipc	ra,0xffffd
    80003b68:	126080e7          	jalr	294(ra) # 80000c8a <release>
}
    80003b6c:	60e2                	ld	ra,24(sp)
    80003b6e:	6442                	ld	s0,16(sp)
    80003b70:	64a2                	ld	s1,8(sp)
    80003b72:	6902                	ld	s2,0(sp)
    80003b74:	6105                	addi	sp,sp,32
    80003b76:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b78:	40bc                	lw	a5,64(s1)
    80003b7a:	dff1                	beqz	a5,80003b56 <iput+0x26>
    80003b7c:	04a49783          	lh	a5,74(s1)
    80003b80:	fbf9                	bnez	a5,80003b56 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b82:	01048913          	addi	s2,s1,16
    80003b86:	854a                	mv	a0,s2
    80003b88:	00001097          	auipc	ra,0x1
    80003b8c:	ac0080e7          	jalr	-1344(ra) # 80004648 <acquiresleep>
    release(&icache.lock);
    80003b90:	00024517          	auipc	a0,0x24
    80003b94:	c2050513          	addi	a0,a0,-992 # 800277b0 <icache>
    80003b98:	ffffd097          	auipc	ra,0xffffd
    80003b9c:	0f2080e7          	jalr	242(ra) # 80000c8a <release>
    itrunc(ip);
    80003ba0:	8526                	mv	a0,s1
    80003ba2:	00000097          	auipc	ra,0x0
    80003ba6:	ee2080e7          	jalr	-286(ra) # 80003a84 <itrunc>
    ip->type = 0;
    80003baa:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bae:	8526                	mv	a0,s1
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	cfc080e7          	jalr	-772(ra) # 800038ac <iupdate>
    ip->valid = 0;
    80003bb8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bbc:	854a                	mv	a0,s2
    80003bbe:	00001097          	auipc	ra,0x1
    80003bc2:	ae0080e7          	jalr	-1312(ra) # 8000469e <releasesleep>
    acquire(&icache.lock);
    80003bc6:	00024517          	auipc	a0,0x24
    80003bca:	bea50513          	addi	a0,a0,-1046 # 800277b0 <icache>
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	008080e7          	jalr	8(ra) # 80000bd6 <acquire>
    80003bd6:	b741                	j	80003b56 <iput+0x26>

0000000080003bd8 <iunlockput>:
{
    80003bd8:	1101                	addi	sp,sp,-32
    80003bda:	ec06                	sd	ra,24(sp)
    80003bdc:	e822                	sd	s0,16(sp)
    80003bde:	e426                	sd	s1,8(sp)
    80003be0:	1000                	addi	s0,sp,32
    80003be2:	84aa                	mv	s1,a0
  iunlock(ip);
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	e54080e7          	jalr	-428(ra) # 80003a38 <iunlock>
  iput(ip);
    80003bec:	8526                	mv	a0,s1
    80003bee:	00000097          	auipc	ra,0x0
    80003bf2:	f42080e7          	jalr	-190(ra) # 80003b30 <iput>
}
    80003bf6:	60e2                	ld	ra,24(sp)
    80003bf8:	6442                	ld	s0,16(sp)
    80003bfa:	64a2                	ld	s1,8(sp)
    80003bfc:	6105                	addi	sp,sp,32
    80003bfe:	8082                	ret

0000000080003c00 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c00:	1141                	addi	sp,sp,-16
    80003c02:	e422                	sd	s0,8(sp)
    80003c04:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c06:	411c                	lw	a5,0(a0)
    80003c08:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c0a:	415c                	lw	a5,4(a0)
    80003c0c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c0e:	04451783          	lh	a5,68(a0)
    80003c12:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c16:	04a51783          	lh	a5,74(a0)
    80003c1a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c1e:	04c56783          	lwu	a5,76(a0)
    80003c22:	e99c                	sd	a5,16(a1)
}
    80003c24:	6422                	ld	s0,8(sp)
    80003c26:	0141                	addi	sp,sp,16
    80003c28:	8082                	ret

0000000080003c2a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c2a:	457c                	lw	a5,76(a0)
    80003c2c:	0ed7e963          	bltu	a5,a3,80003d1e <readi+0xf4>
{
    80003c30:	7159                	addi	sp,sp,-112
    80003c32:	f486                	sd	ra,104(sp)
    80003c34:	f0a2                	sd	s0,96(sp)
    80003c36:	eca6                	sd	s1,88(sp)
    80003c38:	e8ca                	sd	s2,80(sp)
    80003c3a:	e4ce                	sd	s3,72(sp)
    80003c3c:	e0d2                	sd	s4,64(sp)
    80003c3e:	fc56                	sd	s5,56(sp)
    80003c40:	f85a                	sd	s6,48(sp)
    80003c42:	f45e                	sd	s7,40(sp)
    80003c44:	f062                	sd	s8,32(sp)
    80003c46:	ec66                	sd	s9,24(sp)
    80003c48:	e86a                	sd	s10,16(sp)
    80003c4a:	e46e                	sd	s11,8(sp)
    80003c4c:	1880                	addi	s0,sp,112
    80003c4e:	8baa                	mv	s7,a0
    80003c50:	8c2e                	mv	s8,a1
    80003c52:	8ab2                	mv	s5,a2
    80003c54:	84b6                	mv	s1,a3
    80003c56:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c58:	9f35                	addw	a4,a4,a3
    return 0;
    80003c5a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c5c:	0ad76063          	bltu	a4,a3,80003cfc <readi+0xd2>
  if(off + n > ip->size)
    80003c60:	00e7f463          	bgeu	a5,a4,80003c68 <readi+0x3e>
    n = ip->size - off;
    80003c64:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c68:	0a0b0963          	beqz	s6,80003d1a <readi+0xf0>
    80003c6c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c6e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c72:	5cfd                	li	s9,-1
    80003c74:	a82d                	j	80003cae <readi+0x84>
    80003c76:	020a1d93          	slli	s11,s4,0x20
    80003c7a:	020ddd93          	srli	s11,s11,0x20
    80003c7e:	05890613          	addi	a2,s2,88
    80003c82:	86ee                	mv	a3,s11
    80003c84:	963a                	add	a2,a2,a4
    80003c86:	85d6                	mv	a1,s5
    80003c88:	8562                	mv	a0,s8
    80003c8a:	fffff097          	auipc	ra,0xfffff
    80003c8e:	9cc080e7          	jalr	-1588(ra) # 80002656 <either_copyout>
    80003c92:	05950d63          	beq	a0,s9,80003cec <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c96:	854a                	mv	a0,s2
    80003c98:	fffff097          	auipc	ra,0xfffff
    80003c9c:	60c080e7          	jalr	1548(ra) # 800032a4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca0:	013a09bb          	addw	s3,s4,s3
    80003ca4:	009a04bb          	addw	s1,s4,s1
    80003ca8:	9aee                	add	s5,s5,s11
    80003caa:	0569f763          	bgeu	s3,s6,80003cf8 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cae:	000ba903          	lw	s2,0(s7)
    80003cb2:	00a4d59b          	srliw	a1,s1,0xa
    80003cb6:	855e                	mv	a0,s7
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	8b0080e7          	jalr	-1872(ra) # 80003568 <bmap>
    80003cc0:	0005059b          	sext.w	a1,a0
    80003cc4:	854a                	mv	a0,s2
    80003cc6:	fffff097          	auipc	ra,0xfffff
    80003cca:	4ae080e7          	jalr	1198(ra) # 80003174 <bread>
    80003cce:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd0:	3ff4f713          	andi	a4,s1,1023
    80003cd4:	40ed07bb          	subw	a5,s10,a4
    80003cd8:	413b06bb          	subw	a3,s6,s3
    80003cdc:	8a3e                	mv	s4,a5
    80003cde:	2781                	sext.w	a5,a5
    80003ce0:	0006861b          	sext.w	a2,a3
    80003ce4:	f8f679e3          	bgeu	a2,a5,80003c76 <readi+0x4c>
    80003ce8:	8a36                	mv	s4,a3
    80003cea:	b771                	j	80003c76 <readi+0x4c>
      brelse(bp);
    80003cec:	854a                	mv	a0,s2
    80003cee:	fffff097          	auipc	ra,0xfffff
    80003cf2:	5b6080e7          	jalr	1462(ra) # 800032a4 <brelse>
      tot = -1;
    80003cf6:	59fd                	li	s3,-1
  }
  return tot;
    80003cf8:	0009851b          	sext.w	a0,s3
}
    80003cfc:	70a6                	ld	ra,104(sp)
    80003cfe:	7406                	ld	s0,96(sp)
    80003d00:	64e6                	ld	s1,88(sp)
    80003d02:	6946                	ld	s2,80(sp)
    80003d04:	69a6                	ld	s3,72(sp)
    80003d06:	6a06                	ld	s4,64(sp)
    80003d08:	7ae2                	ld	s5,56(sp)
    80003d0a:	7b42                	ld	s6,48(sp)
    80003d0c:	7ba2                	ld	s7,40(sp)
    80003d0e:	7c02                	ld	s8,32(sp)
    80003d10:	6ce2                	ld	s9,24(sp)
    80003d12:	6d42                	ld	s10,16(sp)
    80003d14:	6da2                	ld	s11,8(sp)
    80003d16:	6165                	addi	sp,sp,112
    80003d18:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d1a:	89da                	mv	s3,s6
    80003d1c:	bff1                	j	80003cf8 <readi+0xce>
    return 0;
    80003d1e:	4501                	li	a0,0
}
    80003d20:	8082                	ret

0000000080003d22 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d22:	457c                	lw	a5,76(a0)
    80003d24:	10d7e863          	bltu	a5,a3,80003e34 <writei+0x112>
{
    80003d28:	7159                	addi	sp,sp,-112
    80003d2a:	f486                	sd	ra,104(sp)
    80003d2c:	f0a2                	sd	s0,96(sp)
    80003d2e:	eca6                	sd	s1,88(sp)
    80003d30:	e8ca                	sd	s2,80(sp)
    80003d32:	e4ce                	sd	s3,72(sp)
    80003d34:	e0d2                	sd	s4,64(sp)
    80003d36:	fc56                	sd	s5,56(sp)
    80003d38:	f85a                	sd	s6,48(sp)
    80003d3a:	f45e                	sd	s7,40(sp)
    80003d3c:	f062                	sd	s8,32(sp)
    80003d3e:	ec66                	sd	s9,24(sp)
    80003d40:	e86a                	sd	s10,16(sp)
    80003d42:	e46e                	sd	s11,8(sp)
    80003d44:	1880                	addi	s0,sp,112
    80003d46:	8b2a                	mv	s6,a0
    80003d48:	8c2e                	mv	s8,a1
    80003d4a:	8ab2                	mv	s5,a2
    80003d4c:	8936                	mv	s2,a3
    80003d4e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d50:	00e687bb          	addw	a5,a3,a4
    80003d54:	0ed7e263          	bltu	a5,a3,80003e38 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d58:	00043737          	lui	a4,0x43
    80003d5c:	0ef76063          	bltu	a4,a5,80003e3c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d60:	0c0b8863          	beqz	s7,80003e30 <writei+0x10e>
    80003d64:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d66:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d6a:	5cfd                	li	s9,-1
    80003d6c:	a091                	j	80003db0 <writei+0x8e>
    80003d6e:	02099d93          	slli	s11,s3,0x20
    80003d72:	020ddd93          	srli	s11,s11,0x20
    80003d76:	05848513          	addi	a0,s1,88
    80003d7a:	86ee                	mv	a3,s11
    80003d7c:	8656                	mv	a2,s5
    80003d7e:	85e2                	mv	a1,s8
    80003d80:	953a                	add	a0,a0,a4
    80003d82:	fffff097          	auipc	ra,0xfffff
    80003d86:	92a080e7          	jalr	-1750(ra) # 800026ac <either_copyin>
    80003d8a:	07950263          	beq	a0,s9,80003dee <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d8e:	8526                	mv	a0,s1
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	790080e7          	jalr	1936(ra) # 80004520 <log_write>
    brelse(bp);
    80003d98:	8526                	mv	a0,s1
    80003d9a:	fffff097          	auipc	ra,0xfffff
    80003d9e:	50a080e7          	jalr	1290(ra) # 800032a4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da2:	01498a3b          	addw	s4,s3,s4
    80003da6:	0129893b          	addw	s2,s3,s2
    80003daa:	9aee                	add	s5,s5,s11
    80003dac:	057a7663          	bgeu	s4,s7,80003df8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003db0:	000b2483          	lw	s1,0(s6)
    80003db4:	00a9559b          	srliw	a1,s2,0xa
    80003db8:	855a                	mv	a0,s6
    80003dba:	fffff097          	auipc	ra,0xfffff
    80003dbe:	7ae080e7          	jalr	1966(ra) # 80003568 <bmap>
    80003dc2:	0005059b          	sext.w	a1,a0
    80003dc6:	8526                	mv	a0,s1
    80003dc8:	fffff097          	auipc	ra,0xfffff
    80003dcc:	3ac080e7          	jalr	940(ra) # 80003174 <bread>
    80003dd0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dd2:	3ff97713          	andi	a4,s2,1023
    80003dd6:	40ed07bb          	subw	a5,s10,a4
    80003dda:	414b86bb          	subw	a3,s7,s4
    80003dde:	89be                	mv	s3,a5
    80003de0:	2781                	sext.w	a5,a5
    80003de2:	0006861b          	sext.w	a2,a3
    80003de6:	f8f674e3          	bgeu	a2,a5,80003d6e <writei+0x4c>
    80003dea:	89b6                	mv	s3,a3
    80003dec:	b749                	j	80003d6e <writei+0x4c>
      brelse(bp);
    80003dee:	8526                	mv	a0,s1
    80003df0:	fffff097          	auipc	ra,0xfffff
    80003df4:	4b4080e7          	jalr	1204(ra) # 800032a4 <brelse>
  }

  if(off > ip->size)
    80003df8:	04cb2783          	lw	a5,76(s6)
    80003dfc:	0127f463          	bgeu	a5,s2,80003e04 <writei+0xe2>
    ip->size = off;
    80003e00:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e04:	855a                	mv	a0,s6
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	aa6080e7          	jalr	-1370(ra) # 800038ac <iupdate>

  return tot;
    80003e0e:	000a051b          	sext.w	a0,s4
}
    80003e12:	70a6                	ld	ra,104(sp)
    80003e14:	7406                	ld	s0,96(sp)
    80003e16:	64e6                	ld	s1,88(sp)
    80003e18:	6946                	ld	s2,80(sp)
    80003e1a:	69a6                	ld	s3,72(sp)
    80003e1c:	6a06                	ld	s4,64(sp)
    80003e1e:	7ae2                	ld	s5,56(sp)
    80003e20:	7b42                	ld	s6,48(sp)
    80003e22:	7ba2                	ld	s7,40(sp)
    80003e24:	7c02                	ld	s8,32(sp)
    80003e26:	6ce2                	ld	s9,24(sp)
    80003e28:	6d42                	ld	s10,16(sp)
    80003e2a:	6da2                	ld	s11,8(sp)
    80003e2c:	6165                	addi	sp,sp,112
    80003e2e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e30:	8a5e                	mv	s4,s7
    80003e32:	bfc9                	j	80003e04 <writei+0xe2>
    return -1;
    80003e34:	557d                	li	a0,-1
}
    80003e36:	8082                	ret
    return -1;
    80003e38:	557d                	li	a0,-1
    80003e3a:	bfe1                	j	80003e12 <writei+0xf0>
    return -1;
    80003e3c:	557d                	li	a0,-1
    80003e3e:	bfd1                	j	80003e12 <writei+0xf0>

0000000080003e40 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e40:	1141                	addi	sp,sp,-16
    80003e42:	e406                	sd	ra,8(sp)
    80003e44:	e022                	sd	s0,0(sp)
    80003e46:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e48:	4639                	li	a2,14
    80003e4a:	ffffd097          	auipc	ra,0xffffd
    80003e4e:	f64080e7          	jalr	-156(ra) # 80000dae <strncmp>
}
    80003e52:	60a2                	ld	ra,8(sp)
    80003e54:	6402                	ld	s0,0(sp)
    80003e56:	0141                	addi	sp,sp,16
    80003e58:	8082                	ret

0000000080003e5a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e5a:	7139                	addi	sp,sp,-64
    80003e5c:	fc06                	sd	ra,56(sp)
    80003e5e:	f822                	sd	s0,48(sp)
    80003e60:	f426                	sd	s1,40(sp)
    80003e62:	f04a                	sd	s2,32(sp)
    80003e64:	ec4e                	sd	s3,24(sp)
    80003e66:	e852                	sd	s4,16(sp)
    80003e68:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e6a:	04451703          	lh	a4,68(a0)
    80003e6e:	4785                	li	a5,1
    80003e70:	00f71a63          	bne	a4,a5,80003e84 <dirlookup+0x2a>
    80003e74:	892a                	mv	s2,a0
    80003e76:	89ae                	mv	s3,a1
    80003e78:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7a:	457c                	lw	a5,76(a0)
    80003e7c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e7e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e80:	e79d                	bnez	a5,80003eae <dirlookup+0x54>
    80003e82:	a8a5                	j	80003efa <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e84:	00004517          	auipc	a0,0x4
    80003e88:	73450513          	addi	a0,a0,1844 # 800085b8 <syscalls+0x1b0>
    80003e8c:	ffffc097          	auipc	ra,0xffffc
    80003e90:	6a4080e7          	jalr	1700(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003e94:	00004517          	auipc	a0,0x4
    80003e98:	73c50513          	addi	a0,a0,1852 # 800085d0 <syscalls+0x1c8>
    80003e9c:	ffffc097          	auipc	ra,0xffffc
    80003ea0:	694080e7          	jalr	1684(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea4:	24c1                	addiw	s1,s1,16
    80003ea6:	04c92783          	lw	a5,76(s2)
    80003eaa:	04f4f763          	bgeu	s1,a5,80003ef8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eae:	4741                	li	a4,16
    80003eb0:	86a6                	mv	a3,s1
    80003eb2:	fc040613          	addi	a2,s0,-64
    80003eb6:	4581                	li	a1,0
    80003eb8:	854a                	mv	a0,s2
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	d70080e7          	jalr	-656(ra) # 80003c2a <readi>
    80003ec2:	47c1                	li	a5,16
    80003ec4:	fcf518e3          	bne	a0,a5,80003e94 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ec8:	fc045783          	lhu	a5,-64(s0)
    80003ecc:	dfe1                	beqz	a5,80003ea4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ece:	fc240593          	addi	a1,s0,-62
    80003ed2:	854e                	mv	a0,s3
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	f6c080e7          	jalr	-148(ra) # 80003e40 <namecmp>
    80003edc:	f561                	bnez	a0,80003ea4 <dirlookup+0x4a>
      if(poff)
    80003ede:	000a0463          	beqz	s4,80003ee6 <dirlookup+0x8c>
        *poff = off;
    80003ee2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ee6:	fc045583          	lhu	a1,-64(s0)
    80003eea:	00092503          	lw	a0,0(s2)
    80003eee:	fffff097          	auipc	ra,0xfffff
    80003ef2:	754080e7          	jalr	1876(ra) # 80003642 <iget>
    80003ef6:	a011                	j	80003efa <dirlookup+0xa0>
  return 0;
    80003ef8:	4501                	li	a0,0
}
    80003efa:	70e2                	ld	ra,56(sp)
    80003efc:	7442                	ld	s0,48(sp)
    80003efe:	74a2                	ld	s1,40(sp)
    80003f00:	7902                	ld	s2,32(sp)
    80003f02:	69e2                	ld	s3,24(sp)
    80003f04:	6a42                	ld	s4,16(sp)
    80003f06:	6121                	addi	sp,sp,64
    80003f08:	8082                	ret

0000000080003f0a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f0a:	711d                	addi	sp,sp,-96
    80003f0c:	ec86                	sd	ra,88(sp)
    80003f0e:	e8a2                	sd	s0,80(sp)
    80003f10:	e4a6                	sd	s1,72(sp)
    80003f12:	e0ca                	sd	s2,64(sp)
    80003f14:	fc4e                	sd	s3,56(sp)
    80003f16:	f852                	sd	s4,48(sp)
    80003f18:	f456                	sd	s5,40(sp)
    80003f1a:	f05a                	sd	s6,32(sp)
    80003f1c:	ec5e                	sd	s7,24(sp)
    80003f1e:	e862                	sd	s8,16(sp)
    80003f20:	e466                	sd	s9,8(sp)
    80003f22:	1080                	addi	s0,sp,96
    80003f24:	84aa                	mv	s1,a0
    80003f26:	8b2e                	mv	s6,a1
    80003f28:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f2a:	00054703          	lbu	a4,0(a0)
    80003f2e:	02f00793          	li	a5,47
    80003f32:	02f70363          	beq	a4,a5,80003f58 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f36:	ffffe097          	auipc	ra,0xffffe
    80003f3a:	abe080e7          	jalr	-1346(ra) # 800019f4 <myproc>
    80003f3e:	15053503          	ld	a0,336(a0)
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	9f6080e7          	jalr	-1546(ra) # 80003938 <idup>
    80003f4a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f4c:	02f00913          	li	s2,47
  len = path - s;
    80003f50:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f52:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f54:	4c05                	li	s8,1
    80003f56:	a865                	j	8000400e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f58:	4585                	li	a1,1
    80003f5a:	4505                	li	a0,1
    80003f5c:	fffff097          	auipc	ra,0xfffff
    80003f60:	6e6080e7          	jalr	1766(ra) # 80003642 <iget>
    80003f64:	89aa                	mv	s3,a0
    80003f66:	b7dd                	j	80003f4c <namex+0x42>
      iunlockput(ip);
    80003f68:	854e                	mv	a0,s3
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	c6e080e7          	jalr	-914(ra) # 80003bd8 <iunlockput>
      return 0;
    80003f72:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f74:	854e                	mv	a0,s3
    80003f76:	60e6                	ld	ra,88(sp)
    80003f78:	6446                	ld	s0,80(sp)
    80003f7a:	64a6                	ld	s1,72(sp)
    80003f7c:	6906                	ld	s2,64(sp)
    80003f7e:	79e2                	ld	s3,56(sp)
    80003f80:	7a42                	ld	s4,48(sp)
    80003f82:	7aa2                	ld	s5,40(sp)
    80003f84:	7b02                	ld	s6,32(sp)
    80003f86:	6be2                	ld	s7,24(sp)
    80003f88:	6c42                	ld	s8,16(sp)
    80003f8a:	6ca2                	ld	s9,8(sp)
    80003f8c:	6125                	addi	sp,sp,96
    80003f8e:	8082                	ret
      iunlock(ip);
    80003f90:	854e                	mv	a0,s3
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	aa6080e7          	jalr	-1370(ra) # 80003a38 <iunlock>
      return ip;
    80003f9a:	bfe9                	j	80003f74 <namex+0x6a>
      iunlockput(ip);
    80003f9c:	854e                	mv	a0,s3
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	c3a080e7          	jalr	-966(ra) # 80003bd8 <iunlockput>
      return 0;
    80003fa6:	89d2                	mv	s3,s4
    80003fa8:	b7f1                	j	80003f74 <namex+0x6a>
  len = path - s;
    80003faa:	40b48633          	sub	a2,s1,a1
    80003fae:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fb2:	094cd463          	bge	s9,s4,8000403a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fb6:	4639                	li	a2,14
    80003fb8:	8556                	mv	a0,s5
    80003fba:	ffffd097          	auipc	ra,0xffffd
    80003fbe:	d78080e7          	jalr	-648(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003fc2:	0004c783          	lbu	a5,0(s1)
    80003fc6:	01279763          	bne	a5,s2,80003fd4 <namex+0xca>
    path++;
    80003fca:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fcc:	0004c783          	lbu	a5,0(s1)
    80003fd0:	ff278de3          	beq	a5,s2,80003fca <namex+0xc0>
    ilock(ip);
    80003fd4:	854e                	mv	a0,s3
    80003fd6:	00000097          	auipc	ra,0x0
    80003fda:	9a0080e7          	jalr	-1632(ra) # 80003976 <ilock>
    if(ip->type != T_DIR){
    80003fde:	04499783          	lh	a5,68(s3)
    80003fe2:	f98793e3          	bne	a5,s8,80003f68 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fe6:	000b0563          	beqz	s6,80003ff0 <namex+0xe6>
    80003fea:	0004c783          	lbu	a5,0(s1)
    80003fee:	d3cd                	beqz	a5,80003f90 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ff0:	865e                	mv	a2,s7
    80003ff2:	85d6                	mv	a1,s5
    80003ff4:	854e                	mv	a0,s3
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	e64080e7          	jalr	-412(ra) # 80003e5a <dirlookup>
    80003ffe:	8a2a                	mv	s4,a0
    80004000:	dd51                	beqz	a0,80003f9c <namex+0x92>
    iunlockput(ip);
    80004002:	854e                	mv	a0,s3
    80004004:	00000097          	auipc	ra,0x0
    80004008:	bd4080e7          	jalr	-1068(ra) # 80003bd8 <iunlockput>
    ip = next;
    8000400c:	89d2                	mv	s3,s4
  while(*path == '/')
    8000400e:	0004c783          	lbu	a5,0(s1)
    80004012:	05279763          	bne	a5,s2,80004060 <namex+0x156>
    path++;
    80004016:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004018:	0004c783          	lbu	a5,0(s1)
    8000401c:	ff278de3          	beq	a5,s2,80004016 <namex+0x10c>
  if(*path == 0)
    80004020:	c79d                	beqz	a5,8000404e <namex+0x144>
    path++;
    80004022:	85a6                	mv	a1,s1
  len = path - s;
    80004024:	8a5e                	mv	s4,s7
    80004026:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004028:	01278963          	beq	a5,s2,8000403a <namex+0x130>
    8000402c:	dfbd                	beqz	a5,80003faa <namex+0xa0>
    path++;
    8000402e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004030:	0004c783          	lbu	a5,0(s1)
    80004034:	ff279ce3          	bne	a5,s2,8000402c <namex+0x122>
    80004038:	bf8d                	j	80003faa <namex+0xa0>
    memmove(name, s, len);
    8000403a:	2601                	sext.w	a2,a2
    8000403c:	8556                	mv	a0,s5
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	cf4080e7          	jalr	-780(ra) # 80000d32 <memmove>
    name[len] = 0;
    80004046:	9a56                	add	s4,s4,s5
    80004048:	000a0023          	sb	zero,0(s4)
    8000404c:	bf9d                	j	80003fc2 <namex+0xb8>
  if(nameiparent){
    8000404e:	f20b03e3          	beqz	s6,80003f74 <namex+0x6a>
    iput(ip);
    80004052:	854e                	mv	a0,s3
    80004054:	00000097          	auipc	ra,0x0
    80004058:	adc080e7          	jalr	-1316(ra) # 80003b30 <iput>
    return 0;
    8000405c:	4981                	li	s3,0
    8000405e:	bf19                	j	80003f74 <namex+0x6a>
  if(*path == 0)
    80004060:	d7fd                	beqz	a5,8000404e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004062:	0004c783          	lbu	a5,0(s1)
    80004066:	85a6                	mv	a1,s1
    80004068:	b7d1                	j	8000402c <namex+0x122>

000000008000406a <dirlink>:
{
    8000406a:	7139                	addi	sp,sp,-64
    8000406c:	fc06                	sd	ra,56(sp)
    8000406e:	f822                	sd	s0,48(sp)
    80004070:	f426                	sd	s1,40(sp)
    80004072:	f04a                	sd	s2,32(sp)
    80004074:	ec4e                	sd	s3,24(sp)
    80004076:	e852                	sd	s4,16(sp)
    80004078:	0080                	addi	s0,sp,64
    8000407a:	892a                	mv	s2,a0
    8000407c:	8a2e                	mv	s4,a1
    8000407e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004080:	4601                	li	a2,0
    80004082:	00000097          	auipc	ra,0x0
    80004086:	dd8080e7          	jalr	-552(ra) # 80003e5a <dirlookup>
    8000408a:	e93d                	bnez	a0,80004100 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000408c:	04c92483          	lw	s1,76(s2)
    80004090:	c49d                	beqz	s1,800040be <dirlink+0x54>
    80004092:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004094:	4741                	li	a4,16
    80004096:	86a6                	mv	a3,s1
    80004098:	fc040613          	addi	a2,s0,-64
    8000409c:	4581                	li	a1,0
    8000409e:	854a                	mv	a0,s2
    800040a0:	00000097          	auipc	ra,0x0
    800040a4:	b8a080e7          	jalr	-1142(ra) # 80003c2a <readi>
    800040a8:	47c1                	li	a5,16
    800040aa:	06f51163          	bne	a0,a5,8000410c <dirlink+0xa2>
    if(de.inum == 0)
    800040ae:	fc045783          	lhu	a5,-64(s0)
    800040b2:	c791                	beqz	a5,800040be <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040b4:	24c1                	addiw	s1,s1,16
    800040b6:	04c92783          	lw	a5,76(s2)
    800040ba:	fcf4ede3          	bltu	s1,a5,80004094 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040be:	4639                	li	a2,14
    800040c0:	85d2                	mv	a1,s4
    800040c2:	fc240513          	addi	a0,s0,-62
    800040c6:	ffffd097          	auipc	ra,0xffffd
    800040ca:	d24080e7          	jalr	-732(ra) # 80000dea <strncpy>
  de.inum = inum;
    800040ce:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d2:	4741                	li	a4,16
    800040d4:	86a6                	mv	a3,s1
    800040d6:	fc040613          	addi	a2,s0,-64
    800040da:	4581                	li	a1,0
    800040dc:	854a                	mv	a0,s2
    800040de:	00000097          	auipc	ra,0x0
    800040e2:	c44080e7          	jalr	-956(ra) # 80003d22 <writei>
    800040e6:	872a                	mv	a4,a0
    800040e8:	47c1                	li	a5,16
  return 0;
    800040ea:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ec:	02f71863          	bne	a4,a5,8000411c <dirlink+0xb2>
}
    800040f0:	70e2                	ld	ra,56(sp)
    800040f2:	7442                	ld	s0,48(sp)
    800040f4:	74a2                	ld	s1,40(sp)
    800040f6:	7902                	ld	s2,32(sp)
    800040f8:	69e2                	ld	s3,24(sp)
    800040fa:	6a42                	ld	s4,16(sp)
    800040fc:	6121                	addi	sp,sp,64
    800040fe:	8082                	ret
    iput(ip);
    80004100:	00000097          	auipc	ra,0x0
    80004104:	a30080e7          	jalr	-1488(ra) # 80003b30 <iput>
    return -1;
    80004108:	557d                	li	a0,-1
    8000410a:	b7dd                	j	800040f0 <dirlink+0x86>
      panic("dirlink read");
    8000410c:	00004517          	auipc	a0,0x4
    80004110:	4d450513          	addi	a0,a0,1236 # 800085e0 <syscalls+0x1d8>
    80004114:	ffffc097          	auipc	ra,0xffffc
    80004118:	41c080e7          	jalr	1052(ra) # 80000530 <panic>
    panic("dirlink");
    8000411c:	00004517          	auipc	a0,0x4
    80004120:	5d450513          	addi	a0,a0,1492 # 800086f0 <syscalls+0x2e8>
    80004124:	ffffc097          	auipc	ra,0xffffc
    80004128:	40c080e7          	jalr	1036(ra) # 80000530 <panic>

000000008000412c <namei>:

struct inode*
namei(char *path)
{
    8000412c:	1101                	addi	sp,sp,-32
    8000412e:	ec06                	sd	ra,24(sp)
    80004130:	e822                	sd	s0,16(sp)
    80004132:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004134:	fe040613          	addi	a2,s0,-32
    80004138:	4581                	li	a1,0
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	dd0080e7          	jalr	-560(ra) # 80003f0a <namex>
}
    80004142:	60e2                	ld	ra,24(sp)
    80004144:	6442                	ld	s0,16(sp)
    80004146:	6105                	addi	sp,sp,32
    80004148:	8082                	ret

000000008000414a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000414a:	1141                	addi	sp,sp,-16
    8000414c:	e406                	sd	ra,8(sp)
    8000414e:	e022                	sd	s0,0(sp)
    80004150:	0800                	addi	s0,sp,16
    80004152:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004154:	4585                	li	a1,1
    80004156:	00000097          	auipc	ra,0x0
    8000415a:	db4080e7          	jalr	-588(ra) # 80003f0a <namex>
}
    8000415e:	60a2                	ld	ra,8(sp)
    80004160:	6402                	ld	s0,0(sp)
    80004162:	0141                	addi	sp,sp,16
    80004164:	8082                	ret

0000000080004166 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004166:	1101                	addi	sp,sp,-32
    80004168:	ec06                	sd	ra,24(sp)
    8000416a:	e822                	sd	s0,16(sp)
    8000416c:	e426                	sd	s1,8(sp)
    8000416e:	e04a                	sd	s2,0(sp)
    80004170:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004172:	00025917          	auipc	s2,0x25
    80004176:	0e690913          	addi	s2,s2,230 # 80029258 <log>
    8000417a:	01892583          	lw	a1,24(s2)
    8000417e:	02892503          	lw	a0,40(s2)
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	ff2080e7          	jalr	-14(ra) # 80003174 <bread>
    8000418a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000418c:	02c92683          	lw	a3,44(s2)
    80004190:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004192:	02d05763          	blez	a3,800041c0 <write_head+0x5a>
    80004196:	00025797          	auipc	a5,0x25
    8000419a:	0f278793          	addi	a5,a5,242 # 80029288 <log+0x30>
    8000419e:	05c50713          	addi	a4,a0,92
    800041a2:	36fd                	addiw	a3,a3,-1
    800041a4:	1682                	slli	a3,a3,0x20
    800041a6:	9281                	srli	a3,a3,0x20
    800041a8:	068a                	slli	a3,a3,0x2
    800041aa:	00025617          	auipc	a2,0x25
    800041ae:	0e260613          	addi	a2,a2,226 # 8002928c <log+0x34>
    800041b2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041b4:	4390                	lw	a2,0(a5)
    800041b6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041b8:	0791                	addi	a5,a5,4
    800041ba:	0711                	addi	a4,a4,4
    800041bc:	fed79ce3          	bne	a5,a3,800041b4 <write_head+0x4e>
  }
  bwrite(buf);
    800041c0:	8526                	mv	a0,s1
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	0a4080e7          	jalr	164(ra) # 80003266 <bwrite>
  brelse(buf);
    800041ca:	8526                	mv	a0,s1
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	0d8080e7          	jalr	216(ra) # 800032a4 <brelse>
}
    800041d4:	60e2                	ld	ra,24(sp)
    800041d6:	6442                	ld	s0,16(sp)
    800041d8:	64a2                	ld	s1,8(sp)
    800041da:	6902                	ld	s2,0(sp)
    800041dc:	6105                	addi	sp,sp,32
    800041de:	8082                	ret

00000000800041e0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e0:	00025797          	auipc	a5,0x25
    800041e4:	0a47a783          	lw	a5,164(a5) # 80029284 <log+0x2c>
    800041e8:	0af05d63          	blez	a5,800042a2 <install_trans+0xc2>
{
    800041ec:	7139                	addi	sp,sp,-64
    800041ee:	fc06                	sd	ra,56(sp)
    800041f0:	f822                	sd	s0,48(sp)
    800041f2:	f426                	sd	s1,40(sp)
    800041f4:	f04a                	sd	s2,32(sp)
    800041f6:	ec4e                	sd	s3,24(sp)
    800041f8:	e852                	sd	s4,16(sp)
    800041fa:	e456                	sd	s5,8(sp)
    800041fc:	e05a                	sd	s6,0(sp)
    800041fe:	0080                	addi	s0,sp,64
    80004200:	8b2a                	mv	s6,a0
    80004202:	00025a97          	auipc	s5,0x25
    80004206:	086a8a93          	addi	s5,s5,134 # 80029288 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000420a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000420c:	00025997          	auipc	s3,0x25
    80004210:	04c98993          	addi	s3,s3,76 # 80029258 <log>
    80004214:	a035                	j	80004240 <install_trans+0x60>
      bunpin(dbuf);
    80004216:	8526                	mv	a0,s1
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	166080e7          	jalr	358(ra) # 8000337e <bunpin>
    brelse(lbuf);
    80004220:	854a                	mv	a0,s2
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	082080e7          	jalr	130(ra) # 800032a4 <brelse>
    brelse(dbuf);
    8000422a:	8526                	mv	a0,s1
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	078080e7          	jalr	120(ra) # 800032a4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004234:	2a05                	addiw	s4,s4,1
    80004236:	0a91                	addi	s5,s5,4
    80004238:	02c9a783          	lw	a5,44(s3)
    8000423c:	04fa5963          	bge	s4,a5,8000428e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004240:	0189a583          	lw	a1,24(s3)
    80004244:	014585bb          	addw	a1,a1,s4
    80004248:	2585                	addiw	a1,a1,1
    8000424a:	0289a503          	lw	a0,40(s3)
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	f26080e7          	jalr	-218(ra) # 80003174 <bread>
    80004256:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004258:	000aa583          	lw	a1,0(s5)
    8000425c:	0289a503          	lw	a0,40(s3)
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	f14080e7          	jalr	-236(ra) # 80003174 <bread>
    80004268:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000426a:	40000613          	li	a2,1024
    8000426e:	05890593          	addi	a1,s2,88
    80004272:	05850513          	addi	a0,a0,88
    80004276:	ffffd097          	auipc	ra,0xffffd
    8000427a:	abc080e7          	jalr	-1348(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000427e:	8526                	mv	a0,s1
    80004280:	fffff097          	auipc	ra,0xfffff
    80004284:	fe6080e7          	jalr	-26(ra) # 80003266 <bwrite>
    if(recovering == 0)
    80004288:	f80b1ce3          	bnez	s6,80004220 <install_trans+0x40>
    8000428c:	b769                	j	80004216 <install_trans+0x36>
}
    8000428e:	70e2                	ld	ra,56(sp)
    80004290:	7442                	ld	s0,48(sp)
    80004292:	74a2                	ld	s1,40(sp)
    80004294:	7902                	ld	s2,32(sp)
    80004296:	69e2                	ld	s3,24(sp)
    80004298:	6a42                	ld	s4,16(sp)
    8000429a:	6aa2                	ld	s5,8(sp)
    8000429c:	6b02                	ld	s6,0(sp)
    8000429e:	6121                	addi	sp,sp,64
    800042a0:	8082                	ret
    800042a2:	8082                	ret

00000000800042a4 <initlog>:
{
    800042a4:	7179                	addi	sp,sp,-48
    800042a6:	f406                	sd	ra,40(sp)
    800042a8:	f022                	sd	s0,32(sp)
    800042aa:	ec26                	sd	s1,24(sp)
    800042ac:	e84a                	sd	s2,16(sp)
    800042ae:	e44e                	sd	s3,8(sp)
    800042b0:	1800                	addi	s0,sp,48
    800042b2:	892a                	mv	s2,a0
    800042b4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042b6:	00025497          	auipc	s1,0x25
    800042ba:	fa248493          	addi	s1,s1,-94 # 80029258 <log>
    800042be:	00004597          	auipc	a1,0x4
    800042c2:	33258593          	addi	a1,a1,818 # 800085f0 <syscalls+0x1e8>
    800042c6:	8526                	mv	a0,s1
    800042c8:	ffffd097          	auipc	ra,0xffffd
    800042cc:	87e080e7          	jalr	-1922(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800042d0:	0149a583          	lw	a1,20(s3)
    800042d4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042d6:	0109a783          	lw	a5,16(s3)
    800042da:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042dc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042e0:	854a                	mv	a0,s2
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	e92080e7          	jalr	-366(ra) # 80003174 <bread>
  log.lh.n = lh->n;
    800042ea:	4d3c                	lw	a5,88(a0)
    800042ec:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042ee:	02f05563          	blez	a5,80004318 <initlog+0x74>
    800042f2:	05c50713          	addi	a4,a0,92
    800042f6:	00025697          	auipc	a3,0x25
    800042fa:	f9268693          	addi	a3,a3,-110 # 80029288 <log+0x30>
    800042fe:	37fd                	addiw	a5,a5,-1
    80004300:	1782                	slli	a5,a5,0x20
    80004302:	9381                	srli	a5,a5,0x20
    80004304:	078a                	slli	a5,a5,0x2
    80004306:	06050613          	addi	a2,a0,96
    8000430a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000430c:	4310                	lw	a2,0(a4)
    8000430e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004310:	0711                	addi	a4,a4,4
    80004312:	0691                	addi	a3,a3,4
    80004314:	fef71ce3          	bne	a4,a5,8000430c <initlog+0x68>
  brelse(buf);
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	f8c080e7          	jalr	-116(ra) # 800032a4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004320:	4505                	li	a0,1
    80004322:	00000097          	auipc	ra,0x0
    80004326:	ebe080e7          	jalr	-322(ra) # 800041e0 <install_trans>
  log.lh.n = 0;
    8000432a:	00025797          	auipc	a5,0x25
    8000432e:	f407ad23          	sw	zero,-166(a5) # 80029284 <log+0x2c>
  write_head(); // clear the log
    80004332:	00000097          	auipc	ra,0x0
    80004336:	e34080e7          	jalr	-460(ra) # 80004166 <write_head>
}
    8000433a:	70a2                	ld	ra,40(sp)
    8000433c:	7402                	ld	s0,32(sp)
    8000433e:	64e2                	ld	s1,24(sp)
    80004340:	6942                	ld	s2,16(sp)
    80004342:	69a2                	ld	s3,8(sp)
    80004344:	6145                	addi	sp,sp,48
    80004346:	8082                	ret

0000000080004348 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004348:	1101                	addi	sp,sp,-32
    8000434a:	ec06                	sd	ra,24(sp)
    8000434c:	e822                	sd	s0,16(sp)
    8000434e:	e426                	sd	s1,8(sp)
    80004350:	e04a                	sd	s2,0(sp)
    80004352:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004354:	00025517          	auipc	a0,0x25
    80004358:	f0450513          	addi	a0,a0,-252 # 80029258 <log>
    8000435c:	ffffd097          	auipc	ra,0xffffd
    80004360:	87a080e7          	jalr	-1926(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004364:	00025497          	auipc	s1,0x25
    80004368:	ef448493          	addi	s1,s1,-268 # 80029258 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000436c:	4979                	li	s2,30
    8000436e:	a039                	j	8000437c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004370:	85a6                	mv	a1,s1
    80004372:	8526                	mv	a0,s1
    80004374:	ffffe097          	auipc	ra,0xffffe
    80004378:	080080e7          	jalr	128(ra) # 800023f4 <sleep>
    if(log.committing){
    8000437c:	50dc                	lw	a5,36(s1)
    8000437e:	fbed                	bnez	a5,80004370 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004380:	509c                	lw	a5,32(s1)
    80004382:	0017871b          	addiw	a4,a5,1
    80004386:	0007069b          	sext.w	a3,a4
    8000438a:	0027179b          	slliw	a5,a4,0x2
    8000438e:	9fb9                	addw	a5,a5,a4
    80004390:	0017979b          	slliw	a5,a5,0x1
    80004394:	54d8                	lw	a4,44(s1)
    80004396:	9fb9                	addw	a5,a5,a4
    80004398:	00f95963          	bge	s2,a5,800043aa <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000439c:	85a6                	mv	a1,s1
    8000439e:	8526                	mv	a0,s1
    800043a0:	ffffe097          	auipc	ra,0xffffe
    800043a4:	054080e7          	jalr	84(ra) # 800023f4 <sleep>
    800043a8:	bfd1                	j	8000437c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043aa:	00025517          	auipc	a0,0x25
    800043ae:	eae50513          	addi	a0,a0,-338 # 80029258 <log>
    800043b2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043b4:	ffffd097          	auipc	ra,0xffffd
    800043b8:	8d6080e7          	jalr	-1834(ra) # 80000c8a <release>
      break;
    }
  }
}
    800043bc:	60e2                	ld	ra,24(sp)
    800043be:	6442                	ld	s0,16(sp)
    800043c0:	64a2                	ld	s1,8(sp)
    800043c2:	6902                	ld	s2,0(sp)
    800043c4:	6105                	addi	sp,sp,32
    800043c6:	8082                	ret

00000000800043c8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043c8:	7139                	addi	sp,sp,-64
    800043ca:	fc06                	sd	ra,56(sp)
    800043cc:	f822                	sd	s0,48(sp)
    800043ce:	f426                	sd	s1,40(sp)
    800043d0:	f04a                	sd	s2,32(sp)
    800043d2:	ec4e                	sd	s3,24(sp)
    800043d4:	e852                	sd	s4,16(sp)
    800043d6:	e456                	sd	s5,8(sp)
    800043d8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043da:	00025497          	auipc	s1,0x25
    800043de:	e7e48493          	addi	s1,s1,-386 # 80029258 <log>
    800043e2:	8526                	mv	a0,s1
    800043e4:	ffffc097          	auipc	ra,0xffffc
    800043e8:	7f2080e7          	jalr	2034(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800043ec:	509c                	lw	a5,32(s1)
    800043ee:	37fd                	addiw	a5,a5,-1
    800043f0:	0007891b          	sext.w	s2,a5
    800043f4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043f6:	50dc                	lw	a5,36(s1)
    800043f8:	efb9                	bnez	a5,80004456 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043fa:	06091663          	bnez	s2,80004466 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043fe:	00025497          	auipc	s1,0x25
    80004402:	e5a48493          	addi	s1,s1,-422 # 80029258 <log>
    80004406:	4785                	li	a5,1
    80004408:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000440a:	8526                	mv	a0,s1
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	87e080e7          	jalr	-1922(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004414:	54dc                	lw	a5,44(s1)
    80004416:	06f04763          	bgtz	a5,80004484 <end_op+0xbc>
    acquire(&log.lock);
    8000441a:	00025497          	auipc	s1,0x25
    8000441e:	e3e48493          	addi	s1,s1,-450 # 80029258 <log>
    80004422:	8526                	mv	a0,s1
    80004424:	ffffc097          	auipc	ra,0xffffc
    80004428:	7b2080e7          	jalr	1970(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000442c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004430:	8526                	mv	a0,s1
    80004432:	ffffe097          	auipc	ra,0xffffe
    80004436:	148080e7          	jalr	328(ra) # 8000257a <wakeup>
    release(&log.lock);
    8000443a:	8526                	mv	a0,s1
    8000443c:	ffffd097          	auipc	ra,0xffffd
    80004440:	84e080e7          	jalr	-1970(ra) # 80000c8a <release>
}
    80004444:	70e2                	ld	ra,56(sp)
    80004446:	7442                	ld	s0,48(sp)
    80004448:	74a2                	ld	s1,40(sp)
    8000444a:	7902                	ld	s2,32(sp)
    8000444c:	69e2                	ld	s3,24(sp)
    8000444e:	6a42                	ld	s4,16(sp)
    80004450:	6aa2                	ld	s5,8(sp)
    80004452:	6121                	addi	sp,sp,64
    80004454:	8082                	ret
    panic("log.committing");
    80004456:	00004517          	auipc	a0,0x4
    8000445a:	1a250513          	addi	a0,a0,418 # 800085f8 <syscalls+0x1f0>
    8000445e:	ffffc097          	auipc	ra,0xffffc
    80004462:	0d2080e7          	jalr	210(ra) # 80000530 <panic>
    wakeup(&log);
    80004466:	00025497          	auipc	s1,0x25
    8000446a:	df248493          	addi	s1,s1,-526 # 80029258 <log>
    8000446e:	8526                	mv	a0,s1
    80004470:	ffffe097          	auipc	ra,0xffffe
    80004474:	10a080e7          	jalr	266(ra) # 8000257a <wakeup>
  release(&log.lock);
    80004478:	8526                	mv	a0,s1
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	810080e7          	jalr	-2032(ra) # 80000c8a <release>
  if(do_commit){
    80004482:	b7c9                	j	80004444 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004484:	00025a97          	auipc	s5,0x25
    80004488:	e04a8a93          	addi	s5,s5,-508 # 80029288 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000448c:	00025a17          	auipc	s4,0x25
    80004490:	dcca0a13          	addi	s4,s4,-564 # 80029258 <log>
    80004494:	018a2583          	lw	a1,24(s4)
    80004498:	012585bb          	addw	a1,a1,s2
    8000449c:	2585                	addiw	a1,a1,1
    8000449e:	028a2503          	lw	a0,40(s4)
    800044a2:	fffff097          	auipc	ra,0xfffff
    800044a6:	cd2080e7          	jalr	-814(ra) # 80003174 <bread>
    800044aa:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044ac:	000aa583          	lw	a1,0(s5)
    800044b0:	028a2503          	lw	a0,40(s4)
    800044b4:	fffff097          	auipc	ra,0xfffff
    800044b8:	cc0080e7          	jalr	-832(ra) # 80003174 <bread>
    800044bc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044be:	40000613          	li	a2,1024
    800044c2:	05850593          	addi	a1,a0,88
    800044c6:	05848513          	addi	a0,s1,88
    800044ca:	ffffd097          	auipc	ra,0xffffd
    800044ce:	868080e7          	jalr	-1944(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    800044d2:	8526                	mv	a0,s1
    800044d4:	fffff097          	auipc	ra,0xfffff
    800044d8:	d92080e7          	jalr	-622(ra) # 80003266 <bwrite>
    brelse(from);
    800044dc:	854e                	mv	a0,s3
    800044de:	fffff097          	auipc	ra,0xfffff
    800044e2:	dc6080e7          	jalr	-570(ra) # 800032a4 <brelse>
    brelse(to);
    800044e6:	8526                	mv	a0,s1
    800044e8:	fffff097          	auipc	ra,0xfffff
    800044ec:	dbc080e7          	jalr	-580(ra) # 800032a4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f0:	2905                	addiw	s2,s2,1
    800044f2:	0a91                	addi	s5,s5,4
    800044f4:	02ca2783          	lw	a5,44(s4)
    800044f8:	f8f94ee3          	blt	s2,a5,80004494 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044fc:	00000097          	auipc	ra,0x0
    80004500:	c6a080e7          	jalr	-918(ra) # 80004166 <write_head>
    install_trans(0); // Now install writes to home locations
    80004504:	4501                	li	a0,0
    80004506:	00000097          	auipc	ra,0x0
    8000450a:	cda080e7          	jalr	-806(ra) # 800041e0 <install_trans>
    log.lh.n = 0;
    8000450e:	00025797          	auipc	a5,0x25
    80004512:	d607ab23          	sw	zero,-650(a5) # 80029284 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004516:	00000097          	auipc	ra,0x0
    8000451a:	c50080e7          	jalr	-944(ra) # 80004166 <write_head>
    8000451e:	bdf5                	j	8000441a <end_op+0x52>

0000000080004520 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004520:	1101                	addi	sp,sp,-32
    80004522:	ec06                	sd	ra,24(sp)
    80004524:	e822                	sd	s0,16(sp)
    80004526:	e426                	sd	s1,8(sp)
    80004528:	e04a                	sd	s2,0(sp)
    8000452a:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000452c:	00025717          	auipc	a4,0x25
    80004530:	d5872703          	lw	a4,-680(a4) # 80029284 <log+0x2c>
    80004534:	47f5                	li	a5,29
    80004536:	08e7c063          	blt	a5,a4,800045b6 <log_write+0x96>
    8000453a:	84aa                	mv	s1,a0
    8000453c:	00025797          	auipc	a5,0x25
    80004540:	d387a783          	lw	a5,-712(a5) # 80029274 <log+0x1c>
    80004544:	37fd                	addiw	a5,a5,-1
    80004546:	06f75863          	bge	a4,a5,800045b6 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000454a:	00025797          	auipc	a5,0x25
    8000454e:	d2e7a783          	lw	a5,-722(a5) # 80029278 <log+0x20>
    80004552:	06f05a63          	blez	a5,800045c6 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004556:	00025917          	auipc	s2,0x25
    8000455a:	d0290913          	addi	s2,s2,-766 # 80029258 <log>
    8000455e:	854a                	mv	a0,s2
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	676080e7          	jalr	1654(ra) # 80000bd6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004568:	02c92603          	lw	a2,44(s2)
    8000456c:	06c05563          	blez	a2,800045d6 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004570:	44cc                	lw	a1,12(s1)
    80004572:	00025717          	auipc	a4,0x25
    80004576:	d1670713          	addi	a4,a4,-746 # 80029288 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000457a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000457c:	4314                	lw	a3,0(a4)
    8000457e:	04b68d63          	beq	a3,a1,800045d8 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004582:	2785                	addiw	a5,a5,1
    80004584:	0711                	addi	a4,a4,4
    80004586:	fec79be3          	bne	a5,a2,8000457c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000458a:	0621                	addi	a2,a2,8
    8000458c:	060a                	slli	a2,a2,0x2
    8000458e:	00025797          	auipc	a5,0x25
    80004592:	cca78793          	addi	a5,a5,-822 # 80029258 <log>
    80004596:	963e                	add	a2,a2,a5
    80004598:	44dc                	lw	a5,12(s1)
    8000459a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000459c:	8526                	mv	a0,s1
    8000459e:	fffff097          	auipc	ra,0xfffff
    800045a2:	da4080e7          	jalr	-604(ra) # 80003342 <bpin>
    log.lh.n++;
    800045a6:	00025717          	auipc	a4,0x25
    800045aa:	cb270713          	addi	a4,a4,-846 # 80029258 <log>
    800045ae:	575c                	lw	a5,44(a4)
    800045b0:	2785                	addiw	a5,a5,1
    800045b2:	d75c                	sw	a5,44(a4)
    800045b4:	a83d                	j	800045f2 <log_write+0xd2>
    panic("too big a transaction");
    800045b6:	00004517          	auipc	a0,0x4
    800045ba:	05250513          	addi	a0,a0,82 # 80008608 <syscalls+0x200>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	f72080e7          	jalr	-142(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    800045c6:	00004517          	auipc	a0,0x4
    800045ca:	05a50513          	addi	a0,a0,90 # 80008620 <syscalls+0x218>
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	f62080e7          	jalr	-158(ra) # 80000530 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045d6:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045d8:	00878713          	addi	a4,a5,8
    800045dc:	00271693          	slli	a3,a4,0x2
    800045e0:	00025717          	auipc	a4,0x25
    800045e4:	c7870713          	addi	a4,a4,-904 # 80029258 <log>
    800045e8:	9736                	add	a4,a4,a3
    800045ea:	44d4                	lw	a3,12(s1)
    800045ec:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045ee:	faf607e3          	beq	a2,a5,8000459c <log_write+0x7c>
  }
  release(&log.lock);
    800045f2:	00025517          	auipc	a0,0x25
    800045f6:	c6650513          	addi	a0,a0,-922 # 80029258 <log>
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	690080e7          	jalr	1680(ra) # 80000c8a <release>
}
    80004602:	60e2                	ld	ra,24(sp)
    80004604:	6442                	ld	s0,16(sp)
    80004606:	64a2                	ld	s1,8(sp)
    80004608:	6902                	ld	s2,0(sp)
    8000460a:	6105                	addi	sp,sp,32
    8000460c:	8082                	ret

000000008000460e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000460e:	1101                	addi	sp,sp,-32
    80004610:	ec06                	sd	ra,24(sp)
    80004612:	e822                	sd	s0,16(sp)
    80004614:	e426                	sd	s1,8(sp)
    80004616:	e04a                	sd	s2,0(sp)
    80004618:	1000                	addi	s0,sp,32
    8000461a:	84aa                	mv	s1,a0
    8000461c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000461e:	00004597          	auipc	a1,0x4
    80004622:	02258593          	addi	a1,a1,34 # 80008640 <syscalls+0x238>
    80004626:	0521                	addi	a0,a0,8
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	51e080e7          	jalr	1310(ra) # 80000b46 <initlock>
  lk->name = name;
    80004630:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004634:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004638:	0204a423          	sw	zero,40(s1)
}
    8000463c:	60e2                	ld	ra,24(sp)
    8000463e:	6442                	ld	s0,16(sp)
    80004640:	64a2                	ld	s1,8(sp)
    80004642:	6902                	ld	s2,0(sp)
    80004644:	6105                	addi	sp,sp,32
    80004646:	8082                	ret

0000000080004648 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004648:	1101                	addi	sp,sp,-32
    8000464a:	ec06                	sd	ra,24(sp)
    8000464c:	e822                	sd	s0,16(sp)
    8000464e:	e426                	sd	s1,8(sp)
    80004650:	e04a                	sd	s2,0(sp)
    80004652:	1000                	addi	s0,sp,32
    80004654:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004656:	00850913          	addi	s2,a0,8
    8000465a:	854a                	mv	a0,s2
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	57a080e7          	jalr	1402(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004664:	409c                	lw	a5,0(s1)
    80004666:	cb89                	beqz	a5,80004678 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004668:	85ca                	mv	a1,s2
    8000466a:	8526                	mv	a0,s1
    8000466c:	ffffe097          	auipc	ra,0xffffe
    80004670:	d88080e7          	jalr	-632(ra) # 800023f4 <sleep>
  while (lk->locked) {
    80004674:	409c                	lw	a5,0(s1)
    80004676:	fbed                	bnez	a5,80004668 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004678:	4785                	li	a5,1
    8000467a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000467c:	ffffd097          	auipc	ra,0xffffd
    80004680:	378080e7          	jalr	888(ra) # 800019f4 <myproc>
    80004684:	5d1c                	lw	a5,56(a0)
    80004686:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004688:	854a                	mv	a0,s2
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	600080e7          	jalr	1536(ra) # 80000c8a <release>
}
    80004692:	60e2                	ld	ra,24(sp)
    80004694:	6442                	ld	s0,16(sp)
    80004696:	64a2                	ld	s1,8(sp)
    80004698:	6902                	ld	s2,0(sp)
    8000469a:	6105                	addi	sp,sp,32
    8000469c:	8082                	ret

000000008000469e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000469e:	1101                	addi	sp,sp,-32
    800046a0:	ec06                	sd	ra,24(sp)
    800046a2:	e822                	sd	s0,16(sp)
    800046a4:	e426                	sd	s1,8(sp)
    800046a6:	e04a                	sd	s2,0(sp)
    800046a8:	1000                	addi	s0,sp,32
    800046aa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046ac:	00850913          	addi	s2,a0,8
    800046b0:	854a                	mv	a0,s2
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	524080e7          	jalr	1316(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800046ba:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046be:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046c2:	8526                	mv	a0,s1
    800046c4:	ffffe097          	auipc	ra,0xffffe
    800046c8:	eb6080e7          	jalr	-330(ra) # 8000257a <wakeup>
  release(&lk->lk);
    800046cc:	854a                	mv	a0,s2
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	5bc080e7          	jalr	1468(ra) # 80000c8a <release>
}
    800046d6:	60e2                	ld	ra,24(sp)
    800046d8:	6442                	ld	s0,16(sp)
    800046da:	64a2                	ld	s1,8(sp)
    800046dc:	6902                	ld	s2,0(sp)
    800046de:	6105                	addi	sp,sp,32
    800046e0:	8082                	ret

00000000800046e2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046e2:	7179                	addi	sp,sp,-48
    800046e4:	f406                	sd	ra,40(sp)
    800046e6:	f022                	sd	s0,32(sp)
    800046e8:	ec26                	sd	s1,24(sp)
    800046ea:	e84a                	sd	s2,16(sp)
    800046ec:	e44e                	sd	s3,8(sp)
    800046ee:	1800                	addi	s0,sp,48
    800046f0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046f2:	00850913          	addi	s2,a0,8
    800046f6:	854a                	mv	a0,s2
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	4de080e7          	jalr	1246(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004700:	409c                	lw	a5,0(s1)
    80004702:	ef99                	bnez	a5,80004720 <holdingsleep+0x3e>
    80004704:	4481                	li	s1,0
  release(&lk->lk);
    80004706:	854a                	mv	a0,s2
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	582080e7          	jalr	1410(ra) # 80000c8a <release>
  return r;
}
    80004710:	8526                	mv	a0,s1
    80004712:	70a2                	ld	ra,40(sp)
    80004714:	7402                	ld	s0,32(sp)
    80004716:	64e2                	ld	s1,24(sp)
    80004718:	6942                	ld	s2,16(sp)
    8000471a:	69a2                	ld	s3,8(sp)
    8000471c:	6145                	addi	sp,sp,48
    8000471e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004720:	0284a983          	lw	s3,40(s1)
    80004724:	ffffd097          	auipc	ra,0xffffd
    80004728:	2d0080e7          	jalr	720(ra) # 800019f4 <myproc>
    8000472c:	5d04                	lw	s1,56(a0)
    8000472e:	413484b3          	sub	s1,s1,s3
    80004732:	0014b493          	seqz	s1,s1
    80004736:	bfc1                	j	80004706 <holdingsleep+0x24>

0000000080004738 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004738:	1141                	addi	sp,sp,-16
    8000473a:	e406                	sd	ra,8(sp)
    8000473c:	e022                	sd	s0,0(sp)
    8000473e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004740:	00004597          	auipc	a1,0x4
    80004744:	f1058593          	addi	a1,a1,-240 # 80008650 <syscalls+0x248>
    80004748:	00025517          	auipc	a0,0x25
    8000474c:	c5850513          	addi	a0,a0,-936 # 800293a0 <ftable>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	3f6080e7          	jalr	1014(ra) # 80000b46 <initlock>
}
    80004758:	60a2                	ld	ra,8(sp)
    8000475a:	6402                	ld	s0,0(sp)
    8000475c:	0141                	addi	sp,sp,16
    8000475e:	8082                	ret

0000000080004760 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004760:	1101                	addi	sp,sp,-32
    80004762:	ec06                	sd	ra,24(sp)
    80004764:	e822                	sd	s0,16(sp)
    80004766:	e426                	sd	s1,8(sp)
    80004768:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000476a:	00025517          	auipc	a0,0x25
    8000476e:	c3650513          	addi	a0,a0,-970 # 800293a0 <ftable>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	464080e7          	jalr	1124(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000477a:	00025497          	auipc	s1,0x25
    8000477e:	c3e48493          	addi	s1,s1,-962 # 800293b8 <ftable+0x18>
    80004782:	00026717          	auipc	a4,0x26
    80004786:	bd670713          	addi	a4,a4,-1066 # 8002a358 <ftable+0xfb8>
    if(f->ref == 0){
    8000478a:	40dc                	lw	a5,4(s1)
    8000478c:	cf99                	beqz	a5,800047aa <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000478e:	02848493          	addi	s1,s1,40
    80004792:	fee49ce3          	bne	s1,a4,8000478a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004796:	00025517          	auipc	a0,0x25
    8000479a:	c0a50513          	addi	a0,a0,-1014 # 800293a0 <ftable>
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	4ec080e7          	jalr	1260(ra) # 80000c8a <release>
  return 0;
    800047a6:	4481                	li	s1,0
    800047a8:	a819                	j	800047be <filealloc+0x5e>
      f->ref = 1;
    800047aa:	4785                	li	a5,1
    800047ac:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047ae:	00025517          	auipc	a0,0x25
    800047b2:	bf250513          	addi	a0,a0,-1038 # 800293a0 <ftable>
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	4d4080e7          	jalr	1236(ra) # 80000c8a <release>
}
    800047be:	8526                	mv	a0,s1
    800047c0:	60e2                	ld	ra,24(sp)
    800047c2:	6442                	ld	s0,16(sp)
    800047c4:	64a2                	ld	s1,8(sp)
    800047c6:	6105                	addi	sp,sp,32
    800047c8:	8082                	ret

00000000800047ca <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047ca:	1101                	addi	sp,sp,-32
    800047cc:	ec06                	sd	ra,24(sp)
    800047ce:	e822                	sd	s0,16(sp)
    800047d0:	e426                	sd	s1,8(sp)
    800047d2:	1000                	addi	s0,sp,32
    800047d4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047d6:	00025517          	auipc	a0,0x25
    800047da:	bca50513          	addi	a0,a0,-1078 # 800293a0 <ftable>
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	3f8080e7          	jalr	1016(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800047e6:	40dc                	lw	a5,4(s1)
    800047e8:	02f05263          	blez	a5,8000480c <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047ec:	2785                	addiw	a5,a5,1
    800047ee:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047f0:	00025517          	auipc	a0,0x25
    800047f4:	bb050513          	addi	a0,a0,-1104 # 800293a0 <ftable>
    800047f8:	ffffc097          	auipc	ra,0xffffc
    800047fc:	492080e7          	jalr	1170(ra) # 80000c8a <release>
  return f;
}
    80004800:	8526                	mv	a0,s1
    80004802:	60e2                	ld	ra,24(sp)
    80004804:	6442                	ld	s0,16(sp)
    80004806:	64a2                	ld	s1,8(sp)
    80004808:	6105                	addi	sp,sp,32
    8000480a:	8082                	ret
    panic("filedup");
    8000480c:	00004517          	auipc	a0,0x4
    80004810:	e4c50513          	addi	a0,a0,-436 # 80008658 <syscalls+0x250>
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	d1c080e7          	jalr	-740(ra) # 80000530 <panic>

000000008000481c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000481c:	7139                	addi	sp,sp,-64
    8000481e:	fc06                	sd	ra,56(sp)
    80004820:	f822                	sd	s0,48(sp)
    80004822:	f426                	sd	s1,40(sp)
    80004824:	f04a                	sd	s2,32(sp)
    80004826:	ec4e                	sd	s3,24(sp)
    80004828:	e852                	sd	s4,16(sp)
    8000482a:	e456                	sd	s5,8(sp)
    8000482c:	0080                	addi	s0,sp,64
    8000482e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004830:	00025517          	auipc	a0,0x25
    80004834:	b7050513          	addi	a0,a0,-1168 # 800293a0 <ftable>
    80004838:	ffffc097          	auipc	ra,0xffffc
    8000483c:	39e080e7          	jalr	926(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004840:	40dc                	lw	a5,4(s1)
    80004842:	06f05163          	blez	a5,800048a4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004846:	37fd                	addiw	a5,a5,-1
    80004848:	0007871b          	sext.w	a4,a5
    8000484c:	c0dc                	sw	a5,4(s1)
    8000484e:	06e04363          	bgtz	a4,800048b4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004852:	0004a903          	lw	s2,0(s1)
    80004856:	0094ca83          	lbu	s5,9(s1)
    8000485a:	0104ba03          	ld	s4,16(s1)
    8000485e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004862:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004866:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000486a:	00025517          	auipc	a0,0x25
    8000486e:	b3650513          	addi	a0,a0,-1226 # 800293a0 <ftable>
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	418080e7          	jalr	1048(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000487a:	4785                	li	a5,1
    8000487c:	04f90d63          	beq	s2,a5,800048d6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004880:	3979                	addiw	s2,s2,-2
    80004882:	4785                	li	a5,1
    80004884:	0527e063          	bltu	a5,s2,800048c4 <fileclose+0xa8>
    begin_op();
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	ac0080e7          	jalr	-1344(ra) # 80004348 <begin_op>
    iput(ff.ip);
    80004890:	854e                	mv	a0,s3
    80004892:	fffff097          	auipc	ra,0xfffff
    80004896:	29e080e7          	jalr	670(ra) # 80003b30 <iput>
    end_op();
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	b2e080e7          	jalr	-1234(ra) # 800043c8 <end_op>
    800048a2:	a00d                	j	800048c4 <fileclose+0xa8>
    panic("fileclose");
    800048a4:	00004517          	auipc	a0,0x4
    800048a8:	dbc50513          	addi	a0,a0,-580 # 80008660 <syscalls+0x258>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	c84080e7          	jalr	-892(ra) # 80000530 <panic>
    release(&ftable.lock);
    800048b4:	00025517          	auipc	a0,0x25
    800048b8:	aec50513          	addi	a0,a0,-1300 # 800293a0 <ftable>
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	3ce080e7          	jalr	974(ra) # 80000c8a <release>
  }
}
    800048c4:	70e2                	ld	ra,56(sp)
    800048c6:	7442                	ld	s0,48(sp)
    800048c8:	74a2                	ld	s1,40(sp)
    800048ca:	7902                	ld	s2,32(sp)
    800048cc:	69e2                	ld	s3,24(sp)
    800048ce:	6a42                	ld	s4,16(sp)
    800048d0:	6aa2                	ld	s5,8(sp)
    800048d2:	6121                	addi	sp,sp,64
    800048d4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048d6:	85d6                	mv	a1,s5
    800048d8:	8552                	mv	a0,s4
    800048da:	00000097          	auipc	ra,0x0
    800048de:	34c080e7          	jalr	844(ra) # 80004c26 <pipeclose>
    800048e2:	b7cd                	j	800048c4 <fileclose+0xa8>

00000000800048e4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048e4:	715d                	addi	sp,sp,-80
    800048e6:	e486                	sd	ra,72(sp)
    800048e8:	e0a2                	sd	s0,64(sp)
    800048ea:	fc26                	sd	s1,56(sp)
    800048ec:	f84a                	sd	s2,48(sp)
    800048ee:	f44e                	sd	s3,40(sp)
    800048f0:	0880                	addi	s0,sp,80
    800048f2:	84aa                	mv	s1,a0
    800048f4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048f6:	ffffd097          	auipc	ra,0xffffd
    800048fa:	0fe080e7          	jalr	254(ra) # 800019f4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048fe:	409c                	lw	a5,0(s1)
    80004900:	37f9                	addiw	a5,a5,-2
    80004902:	4705                	li	a4,1
    80004904:	04f76763          	bltu	a4,a5,80004952 <filestat+0x6e>
    80004908:	892a                	mv	s2,a0
    ilock(f->ip);
    8000490a:	6c88                	ld	a0,24(s1)
    8000490c:	fffff097          	auipc	ra,0xfffff
    80004910:	06a080e7          	jalr	106(ra) # 80003976 <ilock>
    stati(f->ip, &st);
    80004914:	fb840593          	addi	a1,s0,-72
    80004918:	6c88                	ld	a0,24(s1)
    8000491a:	fffff097          	auipc	ra,0xfffff
    8000491e:	2e6080e7          	jalr	742(ra) # 80003c00 <stati>
    iunlock(f->ip);
    80004922:	6c88                	ld	a0,24(s1)
    80004924:	fffff097          	auipc	ra,0xfffff
    80004928:	114080e7          	jalr	276(ra) # 80003a38 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000492c:	46e1                	li	a3,24
    8000492e:	fb840613          	addi	a2,s0,-72
    80004932:	85ce                	mv	a1,s3
    80004934:	05093503          	ld	a0,80(s2)
    80004938:	ffffd097          	auipc	ra,0xffffd
    8000493c:	d00080e7          	jalr	-768(ra) # 80001638 <copyout>
    80004940:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004944:	60a6                	ld	ra,72(sp)
    80004946:	6406                	ld	s0,64(sp)
    80004948:	74e2                	ld	s1,56(sp)
    8000494a:	7942                	ld	s2,48(sp)
    8000494c:	79a2                	ld	s3,40(sp)
    8000494e:	6161                	addi	sp,sp,80
    80004950:	8082                	ret
  return -1;
    80004952:	557d                	li	a0,-1
    80004954:	bfc5                	j	80004944 <filestat+0x60>

0000000080004956 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004956:	7179                	addi	sp,sp,-48
    80004958:	f406                	sd	ra,40(sp)
    8000495a:	f022                	sd	s0,32(sp)
    8000495c:	ec26                	sd	s1,24(sp)
    8000495e:	e84a                	sd	s2,16(sp)
    80004960:	e44e                	sd	s3,8(sp)
    80004962:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004964:	00854783          	lbu	a5,8(a0)
    80004968:	c3d5                	beqz	a5,80004a0c <fileread+0xb6>
    8000496a:	84aa                	mv	s1,a0
    8000496c:	89ae                	mv	s3,a1
    8000496e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004970:	411c                	lw	a5,0(a0)
    80004972:	4705                	li	a4,1
    80004974:	04e78963          	beq	a5,a4,800049c6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004978:	470d                	li	a4,3
    8000497a:	04e78d63          	beq	a5,a4,800049d4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000497e:	4709                	li	a4,2
    80004980:	06e79e63          	bne	a5,a4,800049fc <fileread+0xa6>
    ilock(f->ip);
    80004984:	6d08                	ld	a0,24(a0)
    80004986:	fffff097          	auipc	ra,0xfffff
    8000498a:	ff0080e7          	jalr	-16(ra) # 80003976 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000498e:	874a                	mv	a4,s2
    80004990:	5094                	lw	a3,32(s1)
    80004992:	864e                	mv	a2,s3
    80004994:	4585                	li	a1,1
    80004996:	6c88                	ld	a0,24(s1)
    80004998:	fffff097          	auipc	ra,0xfffff
    8000499c:	292080e7          	jalr	658(ra) # 80003c2a <readi>
    800049a0:	892a                	mv	s2,a0
    800049a2:	00a05563          	blez	a0,800049ac <fileread+0x56>
      f->off += r;
    800049a6:	509c                	lw	a5,32(s1)
    800049a8:	9fa9                	addw	a5,a5,a0
    800049aa:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049ac:	6c88                	ld	a0,24(s1)
    800049ae:	fffff097          	auipc	ra,0xfffff
    800049b2:	08a080e7          	jalr	138(ra) # 80003a38 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049b6:	854a                	mv	a0,s2
    800049b8:	70a2                	ld	ra,40(sp)
    800049ba:	7402                	ld	s0,32(sp)
    800049bc:	64e2                	ld	s1,24(sp)
    800049be:	6942                	ld	s2,16(sp)
    800049c0:	69a2                	ld	s3,8(sp)
    800049c2:	6145                	addi	sp,sp,48
    800049c4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049c6:	6908                	ld	a0,16(a0)
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	3c8080e7          	jalr	968(ra) # 80004d90 <piperead>
    800049d0:	892a                	mv	s2,a0
    800049d2:	b7d5                	j	800049b6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049d4:	02451783          	lh	a5,36(a0)
    800049d8:	03079693          	slli	a3,a5,0x30
    800049dc:	92c1                	srli	a3,a3,0x30
    800049de:	4725                	li	a4,9
    800049e0:	02d76863          	bltu	a4,a3,80004a10 <fileread+0xba>
    800049e4:	0792                	slli	a5,a5,0x4
    800049e6:	00025717          	auipc	a4,0x25
    800049ea:	91a70713          	addi	a4,a4,-1766 # 80029300 <devsw>
    800049ee:	97ba                	add	a5,a5,a4
    800049f0:	639c                	ld	a5,0(a5)
    800049f2:	c38d                	beqz	a5,80004a14 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049f4:	4505                	li	a0,1
    800049f6:	9782                	jalr	a5
    800049f8:	892a                	mv	s2,a0
    800049fa:	bf75                	j	800049b6 <fileread+0x60>
    panic("fileread");
    800049fc:	00004517          	auipc	a0,0x4
    80004a00:	c7450513          	addi	a0,a0,-908 # 80008670 <syscalls+0x268>
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	b2c080e7          	jalr	-1236(ra) # 80000530 <panic>
    return -1;
    80004a0c:	597d                	li	s2,-1
    80004a0e:	b765                	j	800049b6 <fileread+0x60>
      return -1;
    80004a10:	597d                	li	s2,-1
    80004a12:	b755                	j	800049b6 <fileread+0x60>
    80004a14:	597d                	li	s2,-1
    80004a16:	b745                	j	800049b6 <fileread+0x60>

0000000080004a18 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a18:	715d                	addi	sp,sp,-80
    80004a1a:	e486                	sd	ra,72(sp)
    80004a1c:	e0a2                	sd	s0,64(sp)
    80004a1e:	fc26                	sd	s1,56(sp)
    80004a20:	f84a                	sd	s2,48(sp)
    80004a22:	f44e                	sd	s3,40(sp)
    80004a24:	f052                	sd	s4,32(sp)
    80004a26:	ec56                	sd	s5,24(sp)
    80004a28:	e85a                	sd	s6,16(sp)
    80004a2a:	e45e                	sd	s7,8(sp)
    80004a2c:	e062                	sd	s8,0(sp)
    80004a2e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a30:	00954783          	lbu	a5,9(a0)
    80004a34:	10078663          	beqz	a5,80004b40 <filewrite+0x128>
    80004a38:	892a                	mv	s2,a0
    80004a3a:	8aae                	mv	s5,a1
    80004a3c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a3e:	411c                	lw	a5,0(a0)
    80004a40:	4705                	li	a4,1
    80004a42:	02e78263          	beq	a5,a4,80004a66 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a46:	470d                	li	a4,3
    80004a48:	02e78663          	beq	a5,a4,80004a74 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a4c:	4709                	li	a4,2
    80004a4e:	0ee79163          	bne	a5,a4,80004b30 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a52:	0ac05d63          	blez	a2,80004b0c <filewrite+0xf4>
    int i = 0;
    80004a56:	4981                	li	s3,0
    80004a58:	6b05                	lui	s6,0x1
    80004a5a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a5e:	6b85                	lui	s7,0x1
    80004a60:	c00b8b9b          	addiw	s7,s7,-1024
    80004a64:	a861                	j	80004afc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a66:	6908                	ld	a0,16(a0)
    80004a68:	00000097          	auipc	ra,0x0
    80004a6c:	22e080e7          	jalr	558(ra) # 80004c96 <pipewrite>
    80004a70:	8a2a                	mv	s4,a0
    80004a72:	a045                	j	80004b12 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a74:	02451783          	lh	a5,36(a0)
    80004a78:	03079693          	slli	a3,a5,0x30
    80004a7c:	92c1                	srli	a3,a3,0x30
    80004a7e:	4725                	li	a4,9
    80004a80:	0cd76263          	bltu	a4,a3,80004b44 <filewrite+0x12c>
    80004a84:	0792                	slli	a5,a5,0x4
    80004a86:	00025717          	auipc	a4,0x25
    80004a8a:	87a70713          	addi	a4,a4,-1926 # 80029300 <devsw>
    80004a8e:	97ba                	add	a5,a5,a4
    80004a90:	679c                	ld	a5,8(a5)
    80004a92:	cbdd                	beqz	a5,80004b48 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a94:	4505                	li	a0,1
    80004a96:	9782                	jalr	a5
    80004a98:	8a2a                	mv	s4,a0
    80004a9a:	a8a5                	j	80004b12 <filewrite+0xfa>
    80004a9c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004aa0:	00000097          	auipc	ra,0x0
    80004aa4:	8a8080e7          	jalr	-1880(ra) # 80004348 <begin_op>
      ilock(f->ip);
    80004aa8:	01893503          	ld	a0,24(s2)
    80004aac:	fffff097          	auipc	ra,0xfffff
    80004ab0:	eca080e7          	jalr	-310(ra) # 80003976 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ab4:	8762                	mv	a4,s8
    80004ab6:	02092683          	lw	a3,32(s2)
    80004aba:	01598633          	add	a2,s3,s5
    80004abe:	4585                	li	a1,1
    80004ac0:	01893503          	ld	a0,24(s2)
    80004ac4:	fffff097          	auipc	ra,0xfffff
    80004ac8:	25e080e7          	jalr	606(ra) # 80003d22 <writei>
    80004acc:	84aa                	mv	s1,a0
    80004ace:	00a05763          	blez	a0,80004adc <filewrite+0xc4>
        f->off += r;
    80004ad2:	02092783          	lw	a5,32(s2)
    80004ad6:	9fa9                	addw	a5,a5,a0
    80004ad8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004adc:	01893503          	ld	a0,24(s2)
    80004ae0:	fffff097          	auipc	ra,0xfffff
    80004ae4:	f58080e7          	jalr	-168(ra) # 80003a38 <iunlock>
      end_op();
    80004ae8:	00000097          	auipc	ra,0x0
    80004aec:	8e0080e7          	jalr	-1824(ra) # 800043c8 <end_op>

      if(r != n1){
    80004af0:	009c1f63          	bne	s8,s1,80004b0e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004af4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004af8:	0149db63          	bge	s3,s4,80004b0e <filewrite+0xf6>
      int n1 = n - i;
    80004afc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b00:	84be                	mv	s1,a5
    80004b02:	2781                	sext.w	a5,a5
    80004b04:	f8fb5ce3          	bge	s6,a5,80004a9c <filewrite+0x84>
    80004b08:	84de                	mv	s1,s7
    80004b0a:	bf49                	j	80004a9c <filewrite+0x84>
    int i = 0;
    80004b0c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b0e:	013a1f63          	bne	s4,s3,80004b2c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b12:	8552                	mv	a0,s4
    80004b14:	60a6                	ld	ra,72(sp)
    80004b16:	6406                	ld	s0,64(sp)
    80004b18:	74e2                	ld	s1,56(sp)
    80004b1a:	7942                	ld	s2,48(sp)
    80004b1c:	79a2                	ld	s3,40(sp)
    80004b1e:	7a02                	ld	s4,32(sp)
    80004b20:	6ae2                	ld	s5,24(sp)
    80004b22:	6b42                	ld	s6,16(sp)
    80004b24:	6ba2                	ld	s7,8(sp)
    80004b26:	6c02                	ld	s8,0(sp)
    80004b28:	6161                	addi	sp,sp,80
    80004b2a:	8082                	ret
    ret = (i == n ? n : -1);
    80004b2c:	5a7d                	li	s4,-1
    80004b2e:	b7d5                	j	80004b12 <filewrite+0xfa>
    panic("filewrite");
    80004b30:	00004517          	auipc	a0,0x4
    80004b34:	b5050513          	addi	a0,a0,-1200 # 80008680 <syscalls+0x278>
    80004b38:	ffffc097          	auipc	ra,0xffffc
    80004b3c:	9f8080e7          	jalr	-1544(ra) # 80000530 <panic>
    return -1;
    80004b40:	5a7d                	li	s4,-1
    80004b42:	bfc1                	j	80004b12 <filewrite+0xfa>
      return -1;
    80004b44:	5a7d                	li	s4,-1
    80004b46:	b7f1                	j	80004b12 <filewrite+0xfa>
    80004b48:	5a7d                	li	s4,-1
    80004b4a:	b7e1                	j	80004b12 <filewrite+0xfa>

0000000080004b4c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b4c:	7179                	addi	sp,sp,-48
    80004b4e:	f406                	sd	ra,40(sp)
    80004b50:	f022                	sd	s0,32(sp)
    80004b52:	ec26                	sd	s1,24(sp)
    80004b54:	e84a                	sd	s2,16(sp)
    80004b56:	e44e                	sd	s3,8(sp)
    80004b58:	e052                	sd	s4,0(sp)
    80004b5a:	1800                	addi	s0,sp,48
    80004b5c:	84aa                	mv	s1,a0
    80004b5e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b60:	0005b023          	sd	zero,0(a1)
    80004b64:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b68:	00000097          	auipc	ra,0x0
    80004b6c:	bf8080e7          	jalr	-1032(ra) # 80004760 <filealloc>
    80004b70:	e088                	sd	a0,0(s1)
    80004b72:	c551                	beqz	a0,80004bfe <pipealloc+0xb2>
    80004b74:	00000097          	auipc	ra,0x0
    80004b78:	bec080e7          	jalr	-1044(ra) # 80004760 <filealloc>
    80004b7c:	00aa3023          	sd	a0,0(s4)
    80004b80:	c92d                	beqz	a0,80004bf2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	f64080e7          	jalr	-156(ra) # 80000ae6 <kalloc>
    80004b8a:	892a                	mv	s2,a0
    80004b8c:	c125                	beqz	a0,80004bec <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b8e:	4985                	li	s3,1
    80004b90:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b94:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b98:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b9c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ba0:	00004597          	auipc	a1,0x4
    80004ba4:	af058593          	addi	a1,a1,-1296 # 80008690 <syscalls+0x288>
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	f9e080e7          	jalr	-98(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004bb0:	609c                	ld	a5,0(s1)
    80004bb2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bb6:	609c                	ld	a5,0(s1)
    80004bb8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bbc:	609c                	ld	a5,0(s1)
    80004bbe:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bc2:	609c                	ld	a5,0(s1)
    80004bc4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bc8:	000a3783          	ld	a5,0(s4)
    80004bcc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bd0:	000a3783          	ld	a5,0(s4)
    80004bd4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bd8:	000a3783          	ld	a5,0(s4)
    80004bdc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004be0:	000a3783          	ld	a5,0(s4)
    80004be4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004be8:	4501                	li	a0,0
    80004bea:	a025                	j	80004c12 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bec:	6088                	ld	a0,0(s1)
    80004bee:	e501                	bnez	a0,80004bf6 <pipealloc+0xaa>
    80004bf0:	a039                	j	80004bfe <pipealloc+0xb2>
    80004bf2:	6088                	ld	a0,0(s1)
    80004bf4:	c51d                	beqz	a0,80004c22 <pipealloc+0xd6>
    fileclose(*f0);
    80004bf6:	00000097          	auipc	ra,0x0
    80004bfa:	c26080e7          	jalr	-986(ra) # 8000481c <fileclose>
  if(*f1)
    80004bfe:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c02:	557d                	li	a0,-1
  if(*f1)
    80004c04:	c799                	beqz	a5,80004c12 <pipealloc+0xc6>
    fileclose(*f1);
    80004c06:	853e                	mv	a0,a5
    80004c08:	00000097          	auipc	ra,0x0
    80004c0c:	c14080e7          	jalr	-1004(ra) # 8000481c <fileclose>
  return -1;
    80004c10:	557d                	li	a0,-1
}
    80004c12:	70a2                	ld	ra,40(sp)
    80004c14:	7402                	ld	s0,32(sp)
    80004c16:	64e2                	ld	s1,24(sp)
    80004c18:	6942                	ld	s2,16(sp)
    80004c1a:	69a2                	ld	s3,8(sp)
    80004c1c:	6a02                	ld	s4,0(sp)
    80004c1e:	6145                	addi	sp,sp,48
    80004c20:	8082                	ret
  return -1;
    80004c22:	557d                	li	a0,-1
    80004c24:	b7fd                	j	80004c12 <pipealloc+0xc6>

0000000080004c26 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c26:	1101                	addi	sp,sp,-32
    80004c28:	ec06                	sd	ra,24(sp)
    80004c2a:	e822                	sd	s0,16(sp)
    80004c2c:	e426                	sd	s1,8(sp)
    80004c2e:	e04a                	sd	s2,0(sp)
    80004c30:	1000                	addi	s0,sp,32
    80004c32:	84aa                	mv	s1,a0
    80004c34:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	fa0080e7          	jalr	-96(ra) # 80000bd6 <acquire>
  if(writable){
    80004c3e:	02090d63          	beqz	s2,80004c78 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c42:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c46:	21848513          	addi	a0,s1,536
    80004c4a:	ffffe097          	auipc	ra,0xffffe
    80004c4e:	930080e7          	jalr	-1744(ra) # 8000257a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c52:	2204b783          	ld	a5,544(s1)
    80004c56:	eb95                	bnez	a5,80004c8a <pipeclose+0x64>
    release(&pi->lock);
    80004c58:	8526                	mv	a0,s1
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	030080e7          	jalr	48(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004c62:	8526                	mv	a0,s1
    80004c64:	ffffc097          	auipc	ra,0xffffc
    80004c68:	d86080e7          	jalr	-634(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004c6c:	60e2                	ld	ra,24(sp)
    80004c6e:	6442                	ld	s0,16(sp)
    80004c70:	64a2                	ld	s1,8(sp)
    80004c72:	6902                	ld	s2,0(sp)
    80004c74:	6105                	addi	sp,sp,32
    80004c76:	8082                	ret
    pi->readopen = 0;
    80004c78:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c7c:	21c48513          	addi	a0,s1,540
    80004c80:	ffffe097          	auipc	ra,0xffffe
    80004c84:	8fa080e7          	jalr	-1798(ra) # 8000257a <wakeup>
    80004c88:	b7e9                	j	80004c52 <pipeclose+0x2c>
    release(&pi->lock);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	ffe080e7          	jalr	-2(ra) # 80000c8a <release>
}
    80004c94:	bfe1                	j	80004c6c <pipeclose+0x46>

0000000080004c96 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c96:	7159                	addi	sp,sp,-112
    80004c98:	f486                	sd	ra,104(sp)
    80004c9a:	f0a2                	sd	s0,96(sp)
    80004c9c:	eca6                	sd	s1,88(sp)
    80004c9e:	e8ca                	sd	s2,80(sp)
    80004ca0:	e4ce                	sd	s3,72(sp)
    80004ca2:	e0d2                	sd	s4,64(sp)
    80004ca4:	fc56                	sd	s5,56(sp)
    80004ca6:	f85a                	sd	s6,48(sp)
    80004ca8:	f45e                	sd	s7,40(sp)
    80004caa:	f062                	sd	s8,32(sp)
    80004cac:	ec66                	sd	s9,24(sp)
    80004cae:	1880                	addi	s0,sp,112
    80004cb0:	84aa                	mv	s1,a0
    80004cb2:	8aae                	mv	s5,a1
    80004cb4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	d3e080e7          	jalr	-706(ra) # 800019f4 <myproc>
    80004cbe:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cc0:	8526                	mv	a0,s1
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	f14080e7          	jalr	-236(ra) # 80000bd6 <acquire>
  while(i < n){
    80004cca:	0d405163          	blez	s4,80004d8c <pipewrite+0xf6>
    80004cce:	8ba6                	mv	s7,s1
  int i = 0;
    80004cd0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cd2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cd4:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cd8:	21c48c13          	addi	s8,s1,540
    80004cdc:	a08d                	j	80004d3e <pipewrite+0xa8>
      release(&pi->lock);
    80004cde:	8526                	mv	a0,s1
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	faa080e7          	jalr	-86(ra) # 80000c8a <release>
      return -1;
    80004ce8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cea:	854a                	mv	a0,s2
    80004cec:	70a6                	ld	ra,104(sp)
    80004cee:	7406                	ld	s0,96(sp)
    80004cf0:	64e6                	ld	s1,88(sp)
    80004cf2:	6946                	ld	s2,80(sp)
    80004cf4:	69a6                	ld	s3,72(sp)
    80004cf6:	6a06                	ld	s4,64(sp)
    80004cf8:	7ae2                	ld	s5,56(sp)
    80004cfa:	7b42                	ld	s6,48(sp)
    80004cfc:	7ba2                	ld	s7,40(sp)
    80004cfe:	7c02                	ld	s8,32(sp)
    80004d00:	6ce2                	ld	s9,24(sp)
    80004d02:	6165                	addi	sp,sp,112
    80004d04:	8082                	ret
      wakeup(&pi->nread);
    80004d06:	8566                	mv	a0,s9
    80004d08:	ffffe097          	auipc	ra,0xffffe
    80004d0c:	872080e7          	jalr	-1934(ra) # 8000257a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d10:	85de                	mv	a1,s7
    80004d12:	8562                	mv	a0,s8
    80004d14:	ffffd097          	auipc	ra,0xffffd
    80004d18:	6e0080e7          	jalr	1760(ra) # 800023f4 <sleep>
    80004d1c:	a839                	j	80004d3a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d1e:	21c4a783          	lw	a5,540(s1)
    80004d22:	0017871b          	addiw	a4,a5,1
    80004d26:	20e4ae23          	sw	a4,540(s1)
    80004d2a:	1ff7f793          	andi	a5,a5,511
    80004d2e:	97a6                	add	a5,a5,s1
    80004d30:	f9f44703          	lbu	a4,-97(s0)
    80004d34:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d38:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d3a:	03495d63          	bge	s2,s4,80004d74 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d3e:	2204a783          	lw	a5,544(s1)
    80004d42:	dfd1                	beqz	a5,80004cde <pipewrite+0x48>
    80004d44:	0309a783          	lw	a5,48(s3)
    80004d48:	fbd9                	bnez	a5,80004cde <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d4a:	2184a783          	lw	a5,536(s1)
    80004d4e:	21c4a703          	lw	a4,540(s1)
    80004d52:	2007879b          	addiw	a5,a5,512
    80004d56:	faf708e3          	beq	a4,a5,80004d06 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d5a:	4685                	li	a3,1
    80004d5c:	01590633          	add	a2,s2,s5
    80004d60:	f9f40593          	addi	a1,s0,-97
    80004d64:	0509b503          	ld	a0,80(s3)
    80004d68:	ffffd097          	auipc	ra,0xffffd
    80004d6c:	95c080e7          	jalr	-1700(ra) # 800016c4 <copyin>
    80004d70:	fb6517e3          	bne	a0,s6,80004d1e <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d74:	21848513          	addi	a0,s1,536
    80004d78:	ffffe097          	auipc	ra,0xffffe
    80004d7c:	802080e7          	jalr	-2046(ra) # 8000257a <wakeup>
  release(&pi->lock);
    80004d80:	8526                	mv	a0,s1
    80004d82:	ffffc097          	auipc	ra,0xffffc
    80004d86:	f08080e7          	jalr	-248(ra) # 80000c8a <release>
  return i;
    80004d8a:	b785                	j	80004cea <pipewrite+0x54>
  int i = 0;
    80004d8c:	4901                	li	s2,0
    80004d8e:	b7dd                	j	80004d74 <pipewrite+0xde>

0000000080004d90 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d90:	715d                	addi	sp,sp,-80
    80004d92:	e486                	sd	ra,72(sp)
    80004d94:	e0a2                	sd	s0,64(sp)
    80004d96:	fc26                	sd	s1,56(sp)
    80004d98:	f84a                	sd	s2,48(sp)
    80004d9a:	f44e                	sd	s3,40(sp)
    80004d9c:	f052                	sd	s4,32(sp)
    80004d9e:	ec56                	sd	s5,24(sp)
    80004da0:	e85a                	sd	s6,16(sp)
    80004da2:	0880                	addi	s0,sp,80
    80004da4:	84aa                	mv	s1,a0
    80004da6:	892e                	mv	s2,a1
    80004da8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	c4a080e7          	jalr	-950(ra) # 800019f4 <myproc>
    80004db2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004db4:	8b26                	mv	s6,s1
    80004db6:	8526                	mv	a0,s1
    80004db8:	ffffc097          	auipc	ra,0xffffc
    80004dbc:	e1e080e7          	jalr	-482(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dc0:	2184a703          	lw	a4,536(s1)
    80004dc4:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dc8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dcc:	02f71463          	bne	a4,a5,80004df4 <piperead+0x64>
    80004dd0:	2244a783          	lw	a5,548(s1)
    80004dd4:	c385                	beqz	a5,80004df4 <piperead+0x64>
    if(pr->killed){
    80004dd6:	030a2783          	lw	a5,48(s4)
    80004dda:	ebc1                	bnez	a5,80004e6a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ddc:	85da                	mv	a1,s6
    80004dde:	854e                	mv	a0,s3
    80004de0:	ffffd097          	auipc	ra,0xffffd
    80004de4:	614080e7          	jalr	1556(ra) # 800023f4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004de8:	2184a703          	lw	a4,536(s1)
    80004dec:	21c4a783          	lw	a5,540(s1)
    80004df0:	fef700e3          	beq	a4,a5,80004dd0 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004df4:	09505263          	blez	s5,80004e78 <piperead+0xe8>
    80004df8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dfa:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004dfc:	2184a783          	lw	a5,536(s1)
    80004e00:	21c4a703          	lw	a4,540(s1)
    80004e04:	02f70d63          	beq	a4,a5,80004e3e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e08:	0017871b          	addiw	a4,a5,1
    80004e0c:	20e4ac23          	sw	a4,536(s1)
    80004e10:	1ff7f793          	andi	a5,a5,511
    80004e14:	97a6                	add	a5,a5,s1
    80004e16:	0187c783          	lbu	a5,24(a5)
    80004e1a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e1e:	4685                	li	a3,1
    80004e20:	fbf40613          	addi	a2,s0,-65
    80004e24:	85ca                	mv	a1,s2
    80004e26:	050a3503          	ld	a0,80(s4)
    80004e2a:	ffffd097          	auipc	ra,0xffffd
    80004e2e:	80e080e7          	jalr	-2034(ra) # 80001638 <copyout>
    80004e32:	01650663          	beq	a0,s6,80004e3e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e36:	2985                	addiw	s3,s3,1
    80004e38:	0905                	addi	s2,s2,1
    80004e3a:	fd3a91e3          	bne	s5,s3,80004dfc <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e3e:	21c48513          	addi	a0,s1,540
    80004e42:	ffffd097          	auipc	ra,0xffffd
    80004e46:	738080e7          	jalr	1848(ra) # 8000257a <wakeup>
  release(&pi->lock);
    80004e4a:	8526                	mv	a0,s1
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	e3e080e7          	jalr	-450(ra) # 80000c8a <release>
  return i;
}
    80004e54:	854e                	mv	a0,s3
    80004e56:	60a6                	ld	ra,72(sp)
    80004e58:	6406                	ld	s0,64(sp)
    80004e5a:	74e2                	ld	s1,56(sp)
    80004e5c:	7942                	ld	s2,48(sp)
    80004e5e:	79a2                	ld	s3,40(sp)
    80004e60:	7a02                	ld	s4,32(sp)
    80004e62:	6ae2                	ld	s5,24(sp)
    80004e64:	6b42                	ld	s6,16(sp)
    80004e66:	6161                	addi	sp,sp,80
    80004e68:	8082                	ret
      release(&pi->lock);
    80004e6a:	8526                	mv	a0,s1
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	e1e080e7          	jalr	-482(ra) # 80000c8a <release>
      return -1;
    80004e74:	59fd                	li	s3,-1
    80004e76:	bff9                	j	80004e54 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e78:	4981                	li	s3,0
    80004e7a:	b7d1                	j	80004e3e <piperead+0xae>

0000000080004e7c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e7c:	df010113          	addi	sp,sp,-528
    80004e80:	20113423          	sd	ra,520(sp)
    80004e84:	20813023          	sd	s0,512(sp)
    80004e88:	ffa6                	sd	s1,504(sp)
    80004e8a:	fbca                	sd	s2,496(sp)
    80004e8c:	f7ce                	sd	s3,488(sp)
    80004e8e:	f3d2                	sd	s4,480(sp)
    80004e90:	efd6                	sd	s5,472(sp)
    80004e92:	ebda                	sd	s6,464(sp)
    80004e94:	e7de                	sd	s7,456(sp)
    80004e96:	e3e2                	sd	s8,448(sp)
    80004e98:	ff66                	sd	s9,440(sp)
    80004e9a:	fb6a                	sd	s10,432(sp)
    80004e9c:	f76e                	sd	s11,424(sp)
    80004e9e:	0c00                	addi	s0,sp,528
    80004ea0:	84aa                	mv	s1,a0
    80004ea2:	dea43c23          	sd	a0,-520(s0)
    80004ea6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004eaa:	ffffd097          	auipc	ra,0xffffd
    80004eae:	b4a080e7          	jalr	-1206(ra) # 800019f4 <myproc>
    80004eb2:	892a                	mv	s2,a0

  begin_op();
    80004eb4:	fffff097          	auipc	ra,0xfffff
    80004eb8:	494080e7          	jalr	1172(ra) # 80004348 <begin_op>

  if((ip = namei(path)) == 0){
    80004ebc:	8526                	mv	a0,s1
    80004ebe:	fffff097          	auipc	ra,0xfffff
    80004ec2:	26e080e7          	jalr	622(ra) # 8000412c <namei>
    80004ec6:	c92d                	beqz	a0,80004f38 <exec+0xbc>
    80004ec8:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004eca:	fffff097          	auipc	ra,0xfffff
    80004ece:	aac080e7          	jalr	-1364(ra) # 80003976 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ed2:	04000713          	li	a4,64
    80004ed6:	4681                	li	a3,0
    80004ed8:	e4840613          	addi	a2,s0,-440
    80004edc:	4581                	li	a1,0
    80004ede:	8526                	mv	a0,s1
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	d4a080e7          	jalr	-694(ra) # 80003c2a <readi>
    80004ee8:	04000793          	li	a5,64
    80004eec:	00f51a63          	bne	a0,a5,80004f00 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ef0:	e4842703          	lw	a4,-440(s0)
    80004ef4:	464c47b7          	lui	a5,0x464c4
    80004ef8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004efc:	04f70463          	beq	a4,a5,80004f44 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f00:	8526                	mv	a0,s1
    80004f02:	fffff097          	auipc	ra,0xfffff
    80004f06:	cd6080e7          	jalr	-810(ra) # 80003bd8 <iunlockput>
    end_op();
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	4be080e7          	jalr	1214(ra) # 800043c8 <end_op>
  }
  return -1;
    80004f12:	557d                	li	a0,-1
}
    80004f14:	20813083          	ld	ra,520(sp)
    80004f18:	20013403          	ld	s0,512(sp)
    80004f1c:	74fe                	ld	s1,504(sp)
    80004f1e:	795e                	ld	s2,496(sp)
    80004f20:	79be                	ld	s3,488(sp)
    80004f22:	7a1e                	ld	s4,480(sp)
    80004f24:	6afe                	ld	s5,472(sp)
    80004f26:	6b5e                	ld	s6,464(sp)
    80004f28:	6bbe                	ld	s7,456(sp)
    80004f2a:	6c1e                	ld	s8,448(sp)
    80004f2c:	7cfa                	ld	s9,440(sp)
    80004f2e:	7d5a                	ld	s10,432(sp)
    80004f30:	7dba                	ld	s11,424(sp)
    80004f32:	21010113          	addi	sp,sp,528
    80004f36:	8082                	ret
    end_op();
    80004f38:	fffff097          	auipc	ra,0xfffff
    80004f3c:	490080e7          	jalr	1168(ra) # 800043c8 <end_op>
    return -1;
    80004f40:	557d                	li	a0,-1
    80004f42:	bfc9                	j	80004f14 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f44:	854a                	mv	a0,s2
    80004f46:	ffffd097          	auipc	ra,0xffffd
    80004f4a:	b72080e7          	jalr	-1166(ra) # 80001ab8 <proc_pagetable>
    80004f4e:	8baa                	mv	s7,a0
    80004f50:	d945                	beqz	a0,80004f00 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f52:	e6842983          	lw	s3,-408(s0)
    80004f56:	e8045783          	lhu	a5,-384(s0)
    80004f5a:	c7ad                	beqz	a5,80004fc4 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f5c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f5e:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f60:	6c85                	lui	s9,0x1
    80004f62:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f66:	def43823          	sd	a5,-528(s0)
    80004f6a:	a42d                	j	80005194 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f6c:	00003517          	auipc	a0,0x3
    80004f70:	72c50513          	addi	a0,a0,1836 # 80008698 <syscalls+0x290>
    80004f74:	ffffb097          	auipc	ra,0xffffb
    80004f78:	5bc080e7          	jalr	1468(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f7c:	8756                	mv	a4,s5
    80004f7e:	012d86bb          	addw	a3,s11,s2
    80004f82:	4581                	li	a1,0
    80004f84:	8526                	mv	a0,s1
    80004f86:	fffff097          	auipc	ra,0xfffff
    80004f8a:	ca4080e7          	jalr	-860(ra) # 80003c2a <readi>
    80004f8e:	2501                	sext.w	a0,a0
    80004f90:	1aaa9963          	bne	s5,a0,80005142 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f94:	6785                	lui	a5,0x1
    80004f96:	0127893b          	addw	s2,a5,s2
    80004f9a:	77fd                	lui	a5,0xfffff
    80004f9c:	01478a3b          	addw	s4,a5,s4
    80004fa0:	1f897163          	bgeu	s2,s8,80005182 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004fa4:	02091593          	slli	a1,s2,0x20
    80004fa8:	9181                	srli	a1,a1,0x20
    80004faa:	95ea                	add	a1,a1,s10
    80004fac:	855e                	mv	a0,s7
    80004fae:	ffffc097          	auipc	ra,0xffffc
    80004fb2:	0b6080e7          	jalr	182(ra) # 80001064 <walkaddr>
    80004fb6:	862a                	mv	a2,a0
    if(pa == 0)
    80004fb8:	d955                	beqz	a0,80004f6c <exec+0xf0>
      n = PGSIZE;
    80004fba:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004fbc:	fd9a70e3          	bgeu	s4,s9,80004f7c <exec+0x100>
      n = sz - i;
    80004fc0:	8ad2                	mv	s5,s4
    80004fc2:	bf6d                	j	80004f7c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fc4:	4901                	li	s2,0
  iunlockput(ip);
    80004fc6:	8526                	mv	a0,s1
    80004fc8:	fffff097          	auipc	ra,0xfffff
    80004fcc:	c10080e7          	jalr	-1008(ra) # 80003bd8 <iunlockput>
  end_op();
    80004fd0:	fffff097          	auipc	ra,0xfffff
    80004fd4:	3f8080e7          	jalr	1016(ra) # 800043c8 <end_op>
  p = myproc();
    80004fd8:	ffffd097          	auipc	ra,0xffffd
    80004fdc:	a1c080e7          	jalr	-1508(ra) # 800019f4 <myproc>
    80004fe0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fe2:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fe6:	6785                	lui	a5,0x1
    80004fe8:	17fd                	addi	a5,a5,-1
    80004fea:	993e                	add	s2,s2,a5
    80004fec:	757d                	lui	a0,0xfffff
    80004fee:	00a977b3          	and	a5,s2,a0
    80004ff2:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ff6:	6609                	lui	a2,0x2
    80004ff8:	963e                	add	a2,a2,a5
    80004ffa:	85be                	mv	a1,a5
    80004ffc:	855e                	mv	a0,s7
    80004ffe:	ffffc097          	auipc	ra,0xffffc
    80005002:	3ea080e7          	jalr	1002(ra) # 800013e8 <uvmalloc>
    80005006:	8b2a                	mv	s6,a0
  ip = 0;
    80005008:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000500a:	12050c63          	beqz	a0,80005142 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000500e:	75f9                	lui	a1,0xffffe
    80005010:	95aa                	add	a1,a1,a0
    80005012:	855e                	mv	a0,s7
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	5f2080e7          	jalr	1522(ra) # 80001606 <uvmclear>
  stackbase = sp - PGSIZE;
    8000501c:	7c7d                	lui	s8,0xfffff
    8000501e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005020:	e0043783          	ld	a5,-512(s0)
    80005024:	6388                	ld	a0,0(a5)
    80005026:	c535                	beqz	a0,80005092 <exec+0x216>
    80005028:	e8840993          	addi	s3,s0,-376
    8000502c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005030:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	e28080e7          	jalr	-472(ra) # 80000e5a <strlen>
    8000503a:	2505                	addiw	a0,a0,1
    8000503c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005040:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005044:	13896363          	bltu	s2,s8,8000516a <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005048:	e0043d83          	ld	s11,-512(s0)
    8000504c:	000dba03          	ld	s4,0(s11)
    80005050:	8552                	mv	a0,s4
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	e08080e7          	jalr	-504(ra) # 80000e5a <strlen>
    8000505a:	0015069b          	addiw	a3,a0,1
    8000505e:	8652                	mv	a2,s4
    80005060:	85ca                	mv	a1,s2
    80005062:	855e                	mv	a0,s7
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	5d4080e7          	jalr	1492(ra) # 80001638 <copyout>
    8000506c:	10054363          	bltz	a0,80005172 <exec+0x2f6>
    ustack[argc] = sp;
    80005070:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005074:	0485                	addi	s1,s1,1
    80005076:	008d8793          	addi	a5,s11,8
    8000507a:	e0f43023          	sd	a5,-512(s0)
    8000507e:	008db503          	ld	a0,8(s11)
    80005082:	c911                	beqz	a0,80005096 <exec+0x21a>
    if(argc >= MAXARG)
    80005084:	09a1                	addi	s3,s3,8
    80005086:	fb3c96e3          	bne	s9,s3,80005032 <exec+0x1b6>
  sz = sz1;
    8000508a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000508e:	4481                	li	s1,0
    80005090:	a84d                	j	80005142 <exec+0x2c6>
  sp = sz;
    80005092:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005094:	4481                	li	s1,0
  ustack[argc] = 0;
    80005096:	00349793          	slli	a5,s1,0x3
    8000509a:	f9040713          	addi	a4,s0,-112
    8000509e:	97ba                	add	a5,a5,a4
    800050a0:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    800050a4:	00148693          	addi	a3,s1,1
    800050a8:	068e                	slli	a3,a3,0x3
    800050aa:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050ae:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050b2:	01897663          	bgeu	s2,s8,800050be <exec+0x242>
  sz = sz1;
    800050b6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ba:	4481                	li	s1,0
    800050bc:	a059                	j	80005142 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050be:	e8840613          	addi	a2,s0,-376
    800050c2:	85ca                	mv	a1,s2
    800050c4:	855e                	mv	a0,s7
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	572080e7          	jalr	1394(ra) # 80001638 <copyout>
    800050ce:	0a054663          	bltz	a0,8000517a <exec+0x2fe>
  p->trapframe->a1 = sp;
    800050d2:	058ab783          	ld	a5,88(s5)
    800050d6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050da:	df843783          	ld	a5,-520(s0)
    800050de:	0007c703          	lbu	a4,0(a5)
    800050e2:	cf11                	beqz	a4,800050fe <exec+0x282>
    800050e4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050e6:	02f00693          	li	a3,47
    800050ea:	a029                	j	800050f4 <exec+0x278>
  for(last=s=path; *s; s++)
    800050ec:	0785                	addi	a5,a5,1
    800050ee:	fff7c703          	lbu	a4,-1(a5)
    800050f2:	c711                	beqz	a4,800050fe <exec+0x282>
    if(*s == '/')
    800050f4:	fed71ce3          	bne	a4,a3,800050ec <exec+0x270>
      last = s+1;
    800050f8:	def43c23          	sd	a5,-520(s0)
    800050fc:	bfc5                	j	800050ec <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800050fe:	4641                	li	a2,16
    80005100:	df843583          	ld	a1,-520(s0)
    80005104:	158a8513          	addi	a0,s5,344
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	d20080e7          	jalr	-736(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    80005110:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005114:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005118:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000511c:	058ab783          	ld	a5,88(s5)
    80005120:	e6043703          	ld	a4,-416(s0)
    80005124:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005126:	058ab783          	ld	a5,88(s5)
    8000512a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000512e:	85ea                	mv	a1,s10
    80005130:	ffffd097          	auipc	ra,0xffffd
    80005134:	a24080e7          	jalr	-1500(ra) # 80001b54 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005138:	0004851b          	sext.w	a0,s1
    8000513c:	bbe1                	j	80004f14 <exec+0x98>
    8000513e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005142:	e0843583          	ld	a1,-504(s0)
    80005146:	855e                	mv	a0,s7
    80005148:	ffffd097          	auipc	ra,0xffffd
    8000514c:	a0c080e7          	jalr	-1524(ra) # 80001b54 <proc_freepagetable>
  if(ip){
    80005150:	da0498e3          	bnez	s1,80004f00 <exec+0x84>
  return -1;
    80005154:	557d                	li	a0,-1
    80005156:	bb7d                	j	80004f14 <exec+0x98>
    80005158:	e1243423          	sd	s2,-504(s0)
    8000515c:	b7dd                	j	80005142 <exec+0x2c6>
    8000515e:	e1243423          	sd	s2,-504(s0)
    80005162:	b7c5                	j	80005142 <exec+0x2c6>
    80005164:	e1243423          	sd	s2,-504(s0)
    80005168:	bfe9                	j	80005142 <exec+0x2c6>
  sz = sz1;
    8000516a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000516e:	4481                	li	s1,0
    80005170:	bfc9                	j	80005142 <exec+0x2c6>
  sz = sz1;
    80005172:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005176:	4481                	li	s1,0
    80005178:	b7e9                	j	80005142 <exec+0x2c6>
  sz = sz1;
    8000517a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000517e:	4481                	li	s1,0
    80005180:	b7c9                	j	80005142 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005182:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005186:	2b05                	addiw	s6,s6,1
    80005188:	0389899b          	addiw	s3,s3,56
    8000518c:	e8045783          	lhu	a5,-384(s0)
    80005190:	e2fb5be3          	bge	s6,a5,80004fc6 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005194:	2981                	sext.w	s3,s3
    80005196:	03800713          	li	a4,56
    8000519a:	86ce                	mv	a3,s3
    8000519c:	e1040613          	addi	a2,s0,-496
    800051a0:	4581                	li	a1,0
    800051a2:	8526                	mv	a0,s1
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	a86080e7          	jalr	-1402(ra) # 80003c2a <readi>
    800051ac:	03800793          	li	a5,56
    800051b0:	f8f517e3          	bne	a0,a5,8000513e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800051b4:	e1042783          	lw	a5,-496(s0)
    800051b8:	4705                	li	a4,1
    800051ba:	fce796e3          	bne	a5,a4,80005186 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800051be:	e3843603          	ld	a2,-456(s0)
    800051c2:	e3043783          	ld	a5,-464(s0)
    800051c6:	f8f669e3          	bltu	a2,a5,80005158 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051ca:	e2043783          	ld	a5,-480(s0)
    800051ce:	963e                	add	a2,a2,a5
    800051d0:	f8f667e3          	bltu	a2,a5,8000515e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051d4:	85ca                	mv	a1,s2
    800051d6:	855e                	mv	a0,s7
    800051d8:	ffffc097          	auipc	ra,0xffffc
    800051dc:	210080e7          	jalr	528(ra) # 800013e8 <uvmalloc>
    800051e0:	e0a43423          	sd	a0,-504(s0)
    800051e4:	d141                	beqz	a0,80005164 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    800051e6:	e2043d03          	ld	s10,-480(s0)
    800051ea:	df043783          	ld	a5,-528(s0)
    800051ee:	00fd77b3          	and	a5,s10,a5
    800051f2:	fba1                	bnez	a5,80005142 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051f4:	e1842d83          	lw	s11,-488(s0)
    800051f8:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051fc:	f80c03e3          	beqz	s8,80005182 <exec+0x306>
    80005200:	8a62                	mv	s4,s8
    80005202:	4901                	li	s2,0
    80005204:	b345                	j	80004fa4 <exec+0x128>

0000000080005206 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005206:	7179                	addi	sp,sp,-48
    80005208:	f406                	sd	ra,40(sp)
    8000520a:	f022                	sd	s0,32(sp)
    8000520c:	ec26                	sd	s1,24(sp)
    8000520e:	e84a                	sd	s2,16(sp)
    80005210:	1800                	addi	s0,sp,48
    80005212:	892e                	mv	s2,a1
    80005214:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005216:	fdc40593          	addi	a1,s0,-36
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	bea080e7          	jalr	-1046(ra) # 80002e04 <argint>
    80005222:	04054063          	bltz	a0,80005262 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005226:	fdc42703          	lw	a4,-36(s0)
    8000522a:	47bd                	li	a5,15
    8000522c:	02e7ed63          	bltu	a5,a4,80005266 <argfd+0x60>
    80005230:	ffffc097          	auipc	ra,0xffffc
    80005234:	7c4080e7          	jalr	1988(ra) # 800019f4 <myproc>
    80005238:	fdc42703          	lw	a4,-36(s0)
    8000523c:	01a70793          	addi	a5,a4,26
    80005240:	078e                	slli	a5,a5,0x3
    80005242:	953e                	add	a0,a0,a5
    80005244:	611c                	ld	a5,0(a0)
    80005246:	c395                	beqz	a5,8000526a <argfd+0x64>
    return -1;
  if(pfd)
    80005248:	00090463          	beqz	s2,80005250 <argfd+0x4a>
    *pfd = fd;
    8000524c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005250:	4501                	li	a0,0
  if(pf)
    80005252:	c091                	beqz	s1,80005256 <argfd+0x50>
    *pf = f;
    80005254:	e09c                	sd	a5,0(s1)
}
    80005256:	70a2                	ld	ra,40(sp)
    80005258:	7402                	ld	s0,32(sp)
    8000525a:	64e2                	ld	s1,24(sp)
    8000525c:	6942                	ld	s2,16(sp)
    8000525e:	6145                	addi	sp,sp,48
    80005260:	8082                	ret
    return -1;
    80005262:	557d                	li	a0,-1
    80005264:	bfcd                	j	80005256 <argfd+0x50>
    return -1;
    80005266:	557d                	li	a0,-1
    80005268:	b7fd                	j	80005256 <argfd+0x50>
    8000526a:	557d                	li	a0,-1
    8000526c:	b7ed                	j	80005256 <argfd+0x50>

000000008000526e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000526e:	1101                	addi	sp,sp,-32
    80005270:	ec06                	sd	ra,24(sp)
    80005272:	e822                	sd	s0,16(sp)
    80005274:	e426                	sd	s1,8(sp)
    80005276:	1000                	addi	s0,sp,32
    80005278:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	77a080e7          	jalr	1914(ra) # 800019f4 <myproc>
    80005282:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005284:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd10d0>
    80005288:	4501                	li	a0,0
    8000528a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000528c:	6398                	ld	a4,0(a5)
    8000528e:	cb19                	beqz	a4,800052a4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005290:	2505                	addiw	a0,a0,1
    80005292:	07a1                	addi	a5,a5,8
    80005294:	fed51ce3          	bne	a0,a3,8000528c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005298:	557d                	li	a0,-1
}
    8000529a:	60e2                	ld	ra,24(sp)
    8000529c:	6442                	ld	s0,16(sp)
    8000529e:	64a2                	ld	s1,8(sp)
    800052a0:	6105                	addi	sp,sp,32
    800052a2:	8082                	ret
      p->ofile[fd] = f;
    800052a4:	01a50793          	addi	a5,a0,26
    800052a8:	078e                	slli	a5,a5,0x3
    800052aa:	963e                	add	a2,a2,a5
    800052ac:	e204                	sd	s1,0(a2)
      return fd;
    800052ae:	b7f5                	j	8000529a <fdalloc+0x2c>

00000000800052b0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052b0:	715d                	addi	sp,sp,-80
    800052b2:	e486                	sd	ra,72(sp)
    800052b4:	e0a2                	sd	s0,64(sp)
    800052b6:	fc26                	sd	s1,56(sp)
    800052b8:	f84a                	sd	s2,48(sp)
    800052ba:	f44e                	sd	s3,40(sp)
    800052bc:	f052                	sd	s4,32(sp)
    800052be:	ec56                	sd	s5,24(sp)
    800052c0:	0880                	addi	s0,sp,80
    800052c2:	89ae                	mv	s3,a1
    800052c4:	8ab2                	mv	s5,a2
    800052c6:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052c8:	fb040593          	addi	a1,s0,-80
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	e7e080e7          	jalr	-386(ra) # 8000414a <nameiparent>
    800052d4:	892a                	mv	s2,a0
    800052d6:	12050f63          	beqz	a0,80005414 <create+0x164>
    return 0;

  ilock(dp);
    800052da:	ffffe097          	auipc	ra,0xffffe
    800052de:	69c080e7          	jalr	1692(ra) # 80003976 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052e2:	4601                	li	a2,0
    800052e4:	fb040593          	addi	a1,s0,-80
    800052e8:	854a                	mv	a0,s2
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	b70080e7          	jalr	-1168(ra) # 80003e5a <dirlookup>
    800052f2:	84aa                	mv	s1,a0
    800052f4:	c921                	beqz	a0,80005344 <create+0x94>
    iunlockput(dp);
    800052f6:	854a                	mv	a0,s2
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	8e0080e7          	jalr	-1824(ra) # 80003bd8 <iunlockput>
    ilock(ip);
    80005300:	8526                	mv	a0,s1
    80005302:	ffffe097          	auipc	ra,0xffffe
    80005306:	674080e7          	jalr	1652(ra) # 80003976 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000530a:	2981                	sext.w	s3,s3
    8000530c:	4789                	li	a5,2
    8000530e:	02f99463          	bne	s3,a5,80005336 <create+0x86>
    80005312:	0444d783          	lhu	a5,68(s1)
    80005316:	37f9                	addiw	a5,a5,-2
    80005318:	17c2                	slli	a5,a5,0x30
    8000531a:	93c1                	srli	a5,a5,0x30
    8000531c:	4705                	li	a4,1
    8000531e:	00f76c63          	bltu	a4,a5,80005336 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005322:	8526                	mv	a0,s1
    80005324:	60a6                	ld	ra,72(sp)
    80005326:	6406                	ld	s0,64(sp)
    80005328:	74e2                	ld	s1,56(sp)
    8000532a:	7942                	ld	s2,48(sp)
    8000532c:	79a2                	ld	s3,40(sp)
    8000532e:	7a02                	ld	s4,32(sp)
    80005330:	6ae2                	ld	s5,24(sp)
    80005332:	6161                	addi	sp,sp,80
    80005334:	8082                	ret
    iunlockput(ip);
    80005336:	8526                	mv	a0,s1
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	8a0080e7          	jalr	-1888(ra) # 80003bd8 <iunlockput>
    return 0;
    80005340:	4481                	li	s1,0
    80005342:	b7c5                	j	80005322 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005344:	85ce                	mv	a1,s3
    80005346:	00092503          	lw	a0,0(s2)
    8000534a:	ffffe097          	auipc	ra,0xffffe
    8000534e:	494080e7          	jalr	1172(ra) # 800037de <ialloc>
    80005352:	84aa                	mv	s1,a0
    80005354:	c529                	beqz	a0,8000539e <create+0xee>
  ilock(ip);
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	620080e7          	jalr	1568(ra) # 80003976 <ilock>
  ip->major = major;
    8000535e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005362:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005366:	4785                	li	a5,1
    80005368:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000536c:	8526                	mv	a0,s1
    8000536e:	ffffe097          	auipc	ra,0xffffe
    80005372:	53e080e7          	jalr	1342(ra) # 800038ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005376:	2981                	sext.w	s3,s3
    80005378:	4785                	li	a5,1
    8000537a:	02f98a63          	beq	s3,a5,800053ae <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000537e:	40d0                	lw	a2,4(s1)
    80005380:	fb040593          	addi	a1,s0,-80
    80005384:	854a                	mv	a0,s2
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	ce4080e7          	jalr	-796(ra) # 8000406a <dirlink>
    8000538e:	06054b63          	bltz	a0,80005404 <create+0x154>
  iunlockput(dp);
    80005392:	854a                	mv	a0,s2
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	844080e7          	jalr	-1980(ra) # 80003bd8 <iunlockput>
  return ip;
    8000539c:	b759                	j	80005322 <create+0x72>
    panic("create: ialloc");
    8000539e:	00003517          	auipc	a0,0x3
    800053a2:	31a50513          	addi	a0,a0,794 # 800086b8 <syscalls+0x2b0>
    800053a6:	ffffb097          	auipc	ra,0xffffb
    800053aa:	18a080e7          	jalr	394(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    800053ae:	04a95783          	lhu	a5,74(s2)
    800053b2:	2785                	addiw	a5,a5,1
    800053b4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053b8:	854a                	mv	a0,s2
    800053ba:	ffffe097          	auipc	ra,0xffffe
    800053be:	4f2080e7          	jalr	1266(ra) # 800038ac <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053c2:	40d0                	lw	a2,4(s1)
    800053c4:	00003597          	auipc	a1,0x3
    800053c8:	30458593          	addi	a1,a1,772 # 800086c8 <syscalls+0x2c0>
    800053cc:	8526                	mv	a0,s1
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	c9c080e7          	jalr	-868(ra) # 8000406a <dirlink>
    800053d6:	00054f63          	bltz	a0,800053f4 <create+0x144>
    800053da:	00492603          	lw	a2,4(s2)
    800053de:	00003597          	auipc	a1,0x3
    800053e2:	2f258593          	addi	a1,a1,754 # 800086d0 <syscalls+0x2c8>
    800053e6:	8526                	mv	a0,s1
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	c82080e7          	jalr	-894(ra) # 8000406a <dirlink>
    800053f0:	f80557e3          	bgez	a0,8000537e <create+0xce>
      panic("create dots");
    800053f4:	00003517          	auipc	a0,0x3
    800053f8:	2e450513          	addi	a0,a0,740 # 800086d8 <syscalls+0x2d0>
    800053fc:	ffffb097          	auipc	ra,0xffffb
    80005400:	134080e7          	jalr	308(ra) # 80000530 <panic>
    panic("create: dirlink");
    80005404:	00003517          	auipc	a0,0x3
    80005408:	2e450513          	addi	a0,a0,740 # 800086e8 <syscalls+0x2e0>
    8000540c:	ffffb097          	auipc	ra,0xffffb
    80005410:	124080e7          	jalr	292(ra) # 80000530 <panic>
    return 0;
    80005414:	84aa                	mv	s1,a0
    80005416:	b731                	j	80005322 <create+0x72>

0000000080005418 <sys_dup>:
{
    80005418:	7179                	addi	sp,sp,-48
    8000541a:	f406                	sd	ra,40(sp)
    8000541c:	f022                	sd	s0,32(sp)
    8000541e:	ec26                	sd	s1,24(sp)
    80005420:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005422:	fd840613          	addi	a2,s0,-40
    80005426:	4581                	li	a1,0
    80005428:	4501                	li	a0,0
    8000542a:	00000097          	auipc	ra,0x0
    8000542e:	ddc080e7          	jalr	-548(ra) # 80005206 <argfd>
    return -1;
    80005432:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005434:	02054363          	bltz	a0,8000545a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005438:	fd843503          	ld	a0,-40(s0)
    8000543c:	00000097          	auipc	ra,0x0
    80005440:	e32080e7          	jalr	-462(ra) # 8000526e <fdalloc>
    80005444:	84aa                	mv	s1,a0
    return -1;
    80005446:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005448:	00054963          	bltz	a0,8000545a <sys_dup+0x42>
  filedup(f);
    8000544c:	fd843503          	ld	a0,-40(s0)
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	37a080e7          	jalr	890(ra) # 800047ca <filedup>
  return fd;
    80005458:	87a6                	mv	a5,s1
}
    8000545a:	853e                	mv	a0,a5
    8000545c:	70a2                	ld	ra,40(sp)
    8000545e:	7402                	ld	s0,32(sp)
    80005460:	64e2                	ld	s1,24(sp)
    80005462:	6145                	addi	sp,sp,48
    80005464:	8082                	ret

0000000080005466 <sys_read>:
{
    80005466:	7179                	addi	sp,sp,-48
    80005468:	f406                	sd	ra,40(sp)
    8000546a:	f022                	sd	s0,32(sp)
    8000546c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546e:	fe840613          	addi	a2,s0,-24
    80005472:	4581                	li	a1,0
    80005474:	4501                	li	a0,0
    80005476:	00000097          	auipc	ra,0x0
    8000547a:	d90080e7          	jalr	-624(ra) # 80005206 <argfd>
    return -1;
    8000547e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005480:	04054163          	bltz	a0,800054c2 <sys_read+0x5c>
    80005484:	fe440593          	addi	a1,s0,-28
    80005488:	4509                	li	a0,2
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	97a080e7          	jalr	-1670(ra) # 80002e04 <argint>
    return -1;
    80005492:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005494:	02054763          	bltz	a0,800054c2 <sys_read+0x5c>
    80005498:	fd840593          	addi	a1,s0,-40
    8000549c:	4505                	li	a0,1
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	988080e7          	jalr	-1656(ra) # 80002e26 <argaddr>
    return -1;
    800054a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a8:	00054d63          	bltz	a0,800054c2 <sys_read+0x5c>
  return fileread(f, p, n);
    800054ac:	fe442603          	lw	a2,-28(s0)
    800054b0:	fd843583          	ld	a1,-40(s0)
    800054b4:	fe843503          	ld	a0,-24(s0)
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	49e080e7          	jalr	1182(ra) # 80004956 <fileread>
    800054c0:	87aa                	mv	a5,a0
}
    800054c2:	853e                	mv	a0,a5
    800054c4:	70a2                	ld	ra,40(sp)
    800054c6:	7402                	ld	s0,32(sp)
    800054c8:	6145                	addi	sp,sp,48
    800054ca:	8082                	ret

00000000800054cc <sys_write>:
{
    800054cc:	7179                	addi	sp,sp,-48
    800054ce:	f406                	sd	ra,40(sp)
    800054d0:	f022                	sd	s0,32(sp)
    800054d2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d4:	fe840613          	addi	a2,s0,-24
    800054d8:	4581                	li	a1,0
    800054da:	4501                	li	a0,0
    800054dc:	00000097          	auipc	ra,0x0
    800054e0:	d2a080e7          	jalr	-726(ra) # 80005206 <argfd>
    return -1;
    800054e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e6:	04054163          	bltz	a0,80005528 <sys_write+0x5c>
    800054ea:	fe440593          	addi	a1,s0,-28
    800054ee:	4509                	li	a0,2
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	914080e7          	jalr	-1772(ra) # 80002e04 <argint>
    return -1;
    800054f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054fa:	02054763          	bltz	a0,80005528 <sys_write+0x5c>
    800054fe:	fd840593          	addi	a1,s0,-40
    80005502:	4505                	li	a0,1
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	922080e7          	jalr	-1758(ra) # 80002e26 <argaddr>
    return -1;
    8000550c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000550e:	00054d63          	bltz	a0,80005528 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005512:	fe442603          	lw	a2,-28(s0)
    80005516:	fd843583          	ld	a1,-40(s0)
    8000551a:	fe843503          	ld	a0,-24(s0)
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	4fa080e7          	jalr	1274(ra) # 80004a18 <filewrite>
    80005526:	87aa                	mv	a5,a0
}
    80005528:	853e                	mv	a0,a5
    8000552a:	70a2                	ld	ra,40(sp)
    8000552c:	7402                	ld	s0,32(sp)
    8000552e:	6145                	addi	sp,sp,48
    80005530:	8082                	ret

0000000080005532 <sys_close>:
{
    80005532:	1101                	addi	sp,sp,-32
    80005534:	ec06                	sd	ra,24(sp)
    80005536:	e822                	sd	s0,16(sp)
    80005538:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000553a:	fe040613          	addi	a2,s0,-32
    8000553e:	fec40593          	addi	a1,s0,-20
    80005542:	4501                	li	a0,0
    80005544:	00000097          	auipc	ra,0x0
    80005548:	cc2080e7          	jalr	-830(ra) # 80005206 <argfd>
    return -1;
    8000554c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000554e:	02054463          	bltz	a0,80005576 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005552:	ffffc097          	auipc	ra,0xffffc
    80005556:	4a2080e7          	jalr	1186(ra) # 800019f4 <myproc>
    8000555a:	fec42783          	lw	a5,-20(s0)
    8000555e:	07e9                	addi	a5,a5,26
    80005560:	078e                	slli	a5,a5,0x3
    80005562:	97aa                	add	a5,a5,a0
    80005564:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005568:	fe043503          	ld	a0,-32(s0)
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	2b0080e7          	jalr	688(ra) # 8000481c <fileclose>
  return 0;
    80005574:	4781                	li	a5,0
}
    80005576:	853e                	mv	a0,a5
    80005578:	60e2                	ld	ra,24(sp)
    8000557a:	6442                	ld	s0,16(sp)
    8000557c:	6105                	addi	sp,sp,32
    8000557e:	8082                	ret

0000000080005580 <sys_fstat>:
{
    80005580:	1101                	addi	sp,sp,-32
    80005582:	ec06                	sd	ra,24(sp)
    80005584:	e822                	sd	s0,16(sp)
    80005586:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005588:	fe840613          	addi	a2,s0,-24
    8000558c:	4581                	li	a1,0
    8000558e:	4501                	li	a0,0
    80005590:	00000097          	auipc	ra,0x0
    80005594:	c76080e7          	jalr	-906(ra) # 80005206 <argfd>
    return -1;
    80005598:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000559a:	02054563          	bltz	a0,800055c4 <sys_fstat+0x44>
    8000559e:	fe040593          	addi	a1,s0,-32
    800055a2:	4505                	li	a0,1
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	882080e7          	jalr	-1918(ra) # 80002e26 <argaddr>
    return -1;
    800055ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055ae:	00054b63          	bltz	a0,800055c4 <sys_fstat+0x44>
  return filestat(f, st);
    800055b2:	fe043583          	ld	a1,-32(s0)
    800055b6:	fe843503          	ld	a0,-24(s0)
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	32a080e7          	jalr	810(ra) # 800048e4 <filestat>
    800055c2:	87aa                	mv	a5,a0
}
    800055c4:	853e                	mv	a0,a5
    800055c6:	60e2                	ld	ra,24(sp)
    800055c8:	6442                	ld	s0,16(sp)
    800055ca:	6105                	addi	sp,sp,32
    800055cc:	8082                	ret

00000000800055ce <sys_link>:
{
    800055ce:	7169                	addi	sp,sp,-304
    800055d0:	f606                	sd	ra,296(sp)
    800055d2:	f222                	sd	s0,288(sp)
    800055d4:	ee26                	sd	s1,280(sp)
    800055d6:	ea4a                	sd	s2,272(sp)
    800055d8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055da:	08000613          	li	a2,128
    800055de:	ed040593          	addi	a1,s0,-304
    800055e2:	4501                	li	a0,0
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	864080e7          	jalr	-1948(ra) # 80002e48 <argstr>
    return -1;
    800055ec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ee:	10054e63          	bltz	a0,8000570a <sys_link+0x13c>
    800055f2:	08000613          	li	a2,128
    800055f6:	f5040593          	addi	a1,s0,-176
    800055fa:	4505                	li	a0,1
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	84c080e7          	jalr	-1972(ra) # 80002e48 <argstr>
    return -1;
    80005604:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005606:	10054263          	bltz	a0,8000570a <sys_link+0x13c>
  begin_op();
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	d3e080e7          	jalr	-706(ra) # 80004348 <begin_op>
  if((ip = namei(old)) == 0){
    80005612:	ed040513          	addi	a0,s0,-304
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	b16080e7          	jalr	-1258(ra) # 8000412c <namei>
    8000561e:	84aa                	mv	s1,a0
    80005620:	c551                	beqz	a0,800056ac <sys_link+0xde>
  ilock(ip);
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	354080e7          	jalr	852(ra) # 80003976 <ilock>
  if(ip->type == T_DIR){
    8000562a:	04449703          	lh	a4,68(s1)
    8000562e:	4785                	li	a5,1
    80005630:	08f70463          	beq	a4,a5,800056b8 <sys_link+0xea>
  ip->nlink++;
    80005634:	04a4d783          	lhu	a5,74(s1)
    80005638:	2785                	addiw	a5,a5,1
    8000563a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	26c080e7          	jalr	620(ra) # 800038ac <iupdate>
  iunlock(ip);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	3ee080e7          	jalr	1006(ra) # 80003a38 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005652:	fd040593          	addi	a1,s0,-48
    80005656:	f5040513          	addi	a0,s0,-176
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	af0080e7          	jalr	-1296(ra) # 8000414a <nameiparent>
    80005662:	892a                	mv	s2,a0
    80005664:	c935                	beqz	a0,800056d8 <sys_link+0x10a>
  ilock(dp);
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	310080e7          	jalr	784(ra) # 80003976 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000566e:	00092703          	lw	a4,0(s2)
    80005672:	409c                	lw	a5,0(s1)
    80005674:	04f71d63          	bne	a4,a5,800056ce <sys_link+0x100>
    80005678:	40d0                	lw	a2,4(s1)
    8000567a:	fd040593          	addi	a1,s0,-48
    8000567e:	854a                	mv	a0,s2
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	9ea080e7          	jalr	-1558(ra) # 8000406a <dirlink>
    80005688:	04054363          	bltz	a0,800056ce <sys_link+0x100>
  iunlockput(dp);
    8000568c:	854a                	mv	a0,s2
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	54a080e7          	jalr	1354(ra) # 80003bd8 <iunlockput>
  iput(ip);
    80005696:	8526                	mv	a0,s1
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	498080e7          	jalr	1176(ra) # 80003b30 <iput>
  end_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	d28080e7          	jalr	-728(ra) # 800043c8 <end_op>
  return 0;
    800056a8:	4781                	li	a5,0
    800056aa:	a085                	j	8000570a <sys_link+0x13c>
    end_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	d1c080e7          	jalr	-740(ra) # 800043c8 <end_op>
    return -1;
    800056b4:	57fd                	li	a5,-1
    800056b6:	a891                	j	8000570a <sys_link+0x13c>
    iunlockput(ip);
    800056b8:	8526                	mv	a0,s1
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	51e080e7          	jalr	1310(ra) # 80003bd8 <iunlockput>
    end_op();
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	d06080e7          	jalr	-762(ra) # 800043c8 <end_op>
    return -1;
    800056ca:	57fd                	li	a5,-1
    800056cc:	a83d                	j	8000570a <sys_link+0x13c>
    iunlockput(dp);
    800056ce:	854a                	mv	a0,s2
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	508080e7          	jalr	1288(ra) # 80003bd8 <iunlockput>
  ilock(ip);
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	29c080e7          	jalr	668(ra) # 80003976 <ilock>
  ip->nlink--;
    800056e2:	04a4d783          	lhu	a5,74(s1)
    800056e6:	37fd                	addiw	a5,a5,-1
    800056e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ec:	8526                	mv	a0,s1
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	1be080e7          	jalr	446(ra) # 800038ac <iupdate>
  iunlockput(ip);
    800056f6:	8526                	mv	a0,s1
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	4e0080e7          	jalr	1248(ra) # 80003bd8 <iunlockput>
  end_op();
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	cc8080e7          	jalr	-824(ra) # 800043c8 <end_op>
  return -1;
    80005708:	57fd                	li	a5,-1
}
    8000570a:	853e                	mv	a0,a5
    8000570c:	70b2                	ld	ra,296(sp)
    8000570e:	7412                	ld	s0,288(sp)
    80005710:	64f2                	ld	s1,280(sp)
    80005712:	6952                	ld	s2,272(sp)
    80005714:	6155                	addi	sp,sp,304
    80005716:	8082                	ret

0000000080005718 <sys_unlink>:
{
    80005718:	7151                	addi	sp,sp,-240
    8000571a:	f586                	sd	ra,232(sp)
    8000571c:	f1a2                	sd	s0,224(sp)
    8000571e:	eda6                	sd	s1,216(sp)
    80005720:	e9ca                	sd	s2,208(sp)
    80005722:	e5ce                	sd	s3,200(sp)
    80005724:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005726:	08000613          	li	a2,128
    8000572a:	f3040593          	addi	a1,s0,-208
    8000572e:	4501                	li	a0,0
    80005730:	ffffd097          	auipc	ra,0xffffd
    80005734:	718080e7          	jalr	1816(ra) # 80002e48 <argstr>
    80005738:	18054163          	bltz	a0,800058ba <sys_unlink+0x1a2>
  begin_op();
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	c0c080e7          	jalr	-1012(ra) # 80004348 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005744:	fb040593          	addi	a1,s0,-80
    80005748:	f3040513          	addi	a0,s0,-208
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	9fe080e7          	jalr	-1538(ra) # 8000414a <nameiparent>
    80005754:	84aa                	mv	s1,a0
    80005756:	c979                	beqz	a0,8000582c <sys_unlink+0x114>
  ilock(dp);
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	21e080e7          	jalr	542(ra) # 80003976 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005760:	00003597          	auipc	a1,0x3
    80005764:	f6858593          	addi	a1,a1,-152 # 800086c8 <syscalls+0x2c0>
    80005768:	fb040513          	addi	a0,s0,-80
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	6d4080e7          	jalr	1748(ra) # 80003e40 <namecmp>
    80005774:	14050a63          	beqz	a0,800058c8 <sys_unlink+0x1b0>
    80005778:	00003597          	auipc	a1,0x3
    8000577c:	f5858593          	addi	a1,a1,-168 # 800086d0 <syscalls+0x2c8>
    80005780:	fb040513          	addi	a0,s0,-80
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	6bc080e7          	jalr	1724(ra) # 80003e40 <namecmp>
    8000578c:	12050e63          	beqz	a0,800058c8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005790:	f2c40613          	addi	a2,s0,-212
    80005794:	fb040593          	addi	a1,s0,-80
    80005798:	8526                	mv	a0,s1
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	6c0080e7          	jalr	1728(ra) # 80003e5a <dirlookup>
    800057a2:	892a                	mv	s2,a0
    800057a4:	12050263          	beqz	a0,800058c8 <sys_unlink+0x1b0>
  ilock(ip);
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	1ce080e7          	jalr	462(ra) # 80003976 <ilock>
  if(ip->nlink < 1)
    800057b0:	04a91783          	lh	a5,74(s2)
    800057b4:	08f05263          	blez	a5,80005838 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057b8:	04491703          	lh	a4,68(s2)
    800057bc:	4785                	li	a5,1
    800057be:	08f70563          	beq	a4,a5,80005848 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057c2:	4641                	li	a2,16
    800057c4:	4581                	li	a1,0
    800057c6:	fc040513          	addi	a0,s0,-64
    800057ca:	ffffb097          	auipc	ra,0xffffb
    800057ce:	508080e7          	jalr	1288(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057d2:	4741                	li	a4,16
    800057d4:	f2c42683          	lw	a3,-212(s0)
    800057d8:	fc040613          	addi	a2,s0,-64
    800057dc:	4581                	li	a1,0
    800057de:	8526                	mv	a0,s1
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	542080e7          	jalr	1346(ra) # 80003d22 <writei>
    800057e8:	47c1                	li	a5,16
    800057ea:	0af51563          	bne	a0,a5,80005894 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057ee:	04491703          	lh	a4,68(s2)
    800057f2:	4785                	li	a5,1
    800057f4:	0af70863          	beq	a4,a5,800058a4 <sys_unlink+0x18c>
  iunlockput(dp);
    800057f8:	8526                	mv	a0,s1
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	3de080e7          	jalr	990(ra) # 80003bd8 <iunlockput>
  ip->nlink--;
    80005802:	04a95783          	lhu	a5,74(s2)
    80005806:	37fd                	addiw	a5,a5,-1
    80005808:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000580c:	854a                	mv	a0,s2
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	09e080e7          	jalr	158(ra) # 800038ac <iupdate>
  iunlockput(ip);
    80005816:	854a                	mv	a0,s2
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	3c0080e7          	jalr	960(ra) # 80003bd8 <iunlockput>
  end_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	ba8080e7          	jalr	-1112(ra) # 800043c8 <end_op>
  return 0;
    80005828:	4501                	li	a0,0
    8000582a:	a84d                	j	800058dc <sys_unlink+0x1c4>
    end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	b9c080e7          	jalr	-1124(ra) # 800043c8 <end_op>
    return -1;
    80005834:	557d                	li	a0,-1
    80005836:	a05d                	j	800058dc <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005838:	00003517          	auipc	a0,0x3
    8000583c:	ec050513          	addi	a0,a0,-320 # 800086f8 <syscalls+0x2f0>
    80005840:	ffffb097          	auipc	ra,0xffffb
    80005844:	cf0080e7          	jalr	-784(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005848:	04c92703          	lw	a4,76(s2)
    8000584c:	02000793          	li	a5,32
    80005850:	f6e7f9e3          	bgeu	a5,a4,800057c2 <sys_unlink+0xaa>
    80005854:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005858:	4741                	li	a4,16
    8000585a:	86ce                	mv	a3,s3
    8000585c:	f1840613          	addi	a2,s0,-232
    80005860:	4581                	li	a1,0
    80005862:	854a                	mv	a0,s2
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	3c6080e7          	jalr	966(ra) # 80003c2a <readi>
    8000586c:	47c1                	li	a5,16
    8000586e:	00f51b63          	bne	a0,a5,80005884 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005872:	f1845783          	lhu	a5,-232(s0)
    80005876:	e7a1                	bnez	a5,800058be <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005878:	29c1                	addiw	s3,s3,16
    8000587a:	04c92783          	lw	a5,76(s2)
    8000587e:	fcf9ede3          	bltu	s3,a5,80005858 <sys_unlink+0x140>
    80005882:	b781                	j	800057c2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005884:	00003517          	auipc	a0,0x3
    80005888:	e8c50513          	addi	a0,a0,-372 # 80008710 <syscalls+0x308>
    8000588c:	ffffb097          	auipc	ra,0xffffb
    80005890:	ca4080e7          	jalr	-860(ra) # 80000530 <panic>
    panic("unlink: writei");
    80005894:	00003517          	auipc	a0,0x3
    80005898:	e9450513          	addi	a0,a0,-364 # 80008728 <syscalls+0x320>
    8000589c:	ffffb097          	auipc	ra,0xffffb
    800058a0:	c94080e7          	jalr	-876(ra) # 80000530 <panic>
    dp->nlink--;
    800058a4:	04a4d783          	lhu	a5,74(s1)
    800058a8:	37fd                	addiw	a5,a5,-1
    800058aa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058ae:	8526                	mv	a0,s1
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	ffc080e7          	jalr	-4(ra) # 800038ac <iupdate>
    800058b8:	b781                	j	800057f8 <sys_unlink+0xe0>
    return -1;
    800058ba:	557d                	li	a0,-1
    800058bc:	a005                	j	800058dc <sys_unlink+0x1c4>
    iunlockput(ip);
    800058be:	854a                	mv	a0,s2
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	318080e7          	jalr	792(ra) # 80003bd8 <iunlockput>
  iunlockput(dp);
    800058c8:	8526                	mv	a0,s1
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	30e080e7          	jalr	782(ra) # 80003bd8 <iunlockput>
  end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	af6080e7          	jalr	-1290(ra) # 800043c8 <end_op>
  return -1;
    800058da:	557d                	li	a0,-1
}
    800058dc:	70ae                	ld	ra,232(sp)
    800058de:	740e                	ld	s0,224(sp)
    800058e0:	64ee                	ld	s1,216(sp)
    800058e2:	694e                	ld	s2,208(sp)
    800058e4:	69ae                	ld	s3,200(sp)
    800058e6:	616d                	addi	sp,sp,240
    800058e8:	8082                	ret

00000000800058ea <sys_open>:

uint64
sys_open(void)
{
    800058ea:	7131                	addi	sp,sp,-192
    800058ec:	fd06                	sd	ra,184(sp)
    800058ee:	f922                	sd	s0,176(sp)
    800058f0:	f526                	sd	s1,168(sp)
    800058f2:	f14a                	sd	s2,160(sp)
    800058f4:	ed4e                	sd	s3,152(sp)
    800058f6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058f8:	08000613          	li	a2,128
    800058fc:	f5040593          	addi	a1,s0,-176
    80005900:	4501                	li	a0,0
    80005902:	ffffd097          	auipc	ra,0xffffd
    80005906:	546080e7          	jalr	1350(ra) # 80002e48 <argstr>
    return -1;
    8000590a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000590c:	0c054163          	bltz	a0,800059ce <sys_open+0xe4>
    80005910:	f4c40593          	addi	a1,s0,-180
    80005914:	4505                	li	a0,1
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	4ee080e7          	jalr	1262(ra) # 80002e04 <argint>
    8000591e:	0a054863          	bltz	a0,800059ce <sys_open+0xe4>

  begin_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	a26080e7          	jalr	-1498(ra) # 80004348 <begin_op>

  if(omode & O_CREATE){
    8000592a:	f4c42783          	lw	a5,-180(s0)
    8000592e:	2007f793          	andi	a5,a5,512
    80005932:	cbdd                	beqz	a5,800059e8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005934:	4681                	li	a3,0
    80005936:	4601                	li	a2,0
    80005938:	4589                	li	a1,2
    8000593a:	f5040513          	addi	a0,s0,-176
    8000593e:	00000097          	auipc	ra,0x0
    80005942:	972080e7          	jalr	-1678(ra) # 800052b0 <create>
    80005946:	892a                	mv	s2,a0
    if(ip == 0){
    80005948:	c959                	beqz	a0,800059de <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000594a:	04491703          	lh	a4,68(s2)
    8000594e:	478d                	li	a5,3
    80005950:	00f71763          	bne	a4,a5,8000595e <sys_open+0x74>
    80005954:	04695703          	lhu	a4,70(s2)
    80005958:	47a5                	li	a5,9
    8000595a:	0ce7ec63          	bltu	a5,a4,80005a32 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	e02080e7          	jalr	-510(ra) # 80004760 <filealloc>
    80005966:	89aa                	mv	s3,a0
    80005968:	10050263          	beqz	a0,80005a6c <sys_open+0x182>
    8000596c:	00000097          	auipc	ra,0x0
    80005970:	902080e7          	jalr	-1790(ra) # 8000526e <fdalloc>
    80005974:	84aa                	mv	s1,a0
    80005976:	0e054663          	bltz	a0,80005a62 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000597a:	04491703          	lh	a4,68(s2)
    8000597e:	478d                	li	a5,3
    80005980:	0cf70463          	beq	a4,a5,80005a48 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005984:	4789                	li	a5,2
    80005986:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000598a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000598e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005992:	f4c42783          	lw	a5,-180(s0)
    80005996:	0017c713          	xori	a4,a5,1
    8000599a:	8b05                	andi	a4,a4,1
    8000599c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059a0:	0037f713          	andi	a4,a5,3
    800059a4:	00e03733          	snez	a4,a4
    800059a8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059ac:	4007f793          	andi	a5,a5,1024
    800059b0:	c791                	beqz	a5,800059bc <sys_open+0xd2>
    800059b2:	04491703          	lh	a4,68(s2)
    800059b6:	4789                	li	a5,2
    800059b8:	08f70f63          	beq	a4,a5,80005a56 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059bc:	854a                	mv	a0,s2
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	07a080e7          	jalr	122(ra) # 80003a38 <iunlock>
  end_op();
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	a02080e7          	jalr	-1534(ra) # 800043c8 <end_op>

  return fd;
}
    800059ce:	8526                	mv	a0,s1
    800059d0:	70ea                	ld	ra,184(sp)
    800059d2:	744a                	ld	s0,176(sp)
    800059d4:	74aa                	ld	s1,168(sp)
    800059d6:	790a                	ld	s2,160(sp)
    800059d8:	69ea                	ld	s3,152(sp)
    800059da:	6129                	addi	sp,sp,192
    800059dc:	8082                	ret
      end_op();
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	9ea080e7          	jalr	-1558(ra) # 800043c8 <end_op>
      return -1;
    800059e6:	b7e5                	j	800059ce <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059e8:	f5040513          	addi	a0,s0,-176
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	740080e7          	jalr	1856(ra) # 8000412c <namei>
    800059f4:	892a                	mv	s2,a0
    800059f6:	c905                	beqz	a0,80005a26 <sys_open+0x13c>
    ilock(ip);
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	f7e080e7          	jalr	-130(ra) # 80003976 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a00:	04491703          	lh	a4,68(s2)
    80005a04:	4785                	li	a5,1
    80005a06:	f4f712e3          	bne	a4,a5,8000594a <sys_open+0x60>
    80005a0a:	f4c42783          	lw	a5,-180(s0)
    80005a0e:	dba1                	beqz	a5,8000595e <sys_open+0x74>
      iunlockput(ip);
    80005a10:	854a                	mv	a0,s2
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	1c6080e7          	jalr	454(ra) # 80003bd8 <iunlockput>
      end_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	9ae080e7          	jalr	-1618(ra) # 800043c8 <end_op>
      return -1;
    80005a22:	54fd                	li	s1,-1
    80005a24:	b76d                	j	800059ce <sys_open+0xe4>
      end_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	9a2080e7          	jalr	-1630(ra) # 800043c8 <end_op>
      return -1;
    80005a2e:	54fd                	li	s1,-1
    80005a30:	bf79                	j	800059ce <sys_open+0xe4>
    iunlockput(ip);
    80005a32:	854a                	mv	a0,s2
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	1a4080e7          	jalr	420(ra) # 80003bd8 <iunlockput>
    end_op();
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	98c080e7          	jalr	-1652(ra) # 800043c8 <end_op>
    return -1;
    80005a44:	54fd                	li	s1,-1
    80005a46:	b761                	j	800059ce <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a48:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a4c:	04691783          	lh	a5,70(s2)
    80005a50:	02f99223          	sh	a5,36(s3)
    80005a54:	bf2d                	j	8000598e <sys_open+0xa4>
    itrunc(ip);
    80005a56:	854a                	mv	a0,s2
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	02c080e7          	jalr	44(ra) # 80003a84 <itrunc>
    80005a60:	bfb1                	j	800059bc <sys_open+0xd2>
      fileclose(f);
    80005a62:	854e                	mv	a0,s3
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	db8080e7          	jalr	-584(ra) # 8000481c <fileclose>
    iunlockput(ip);
    80005a6c:	854a                	mv	a0,s2
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	16a080e7          	jalr	362(ra) # 80003bd8 <iunlockput>
    end_op();
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	952080e7          	jalr	-1710(ra) # 800043c8 <end_op>
    return -1;
    80005a7e:	54fd                	li	s1,-1
    80005a80:	b7b9                	j	800059ce <sys_open+0xe4>

0000000080005a82 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a82:	7175                	addi	sp,sp,-144
    80005a84:	e506                	sd	ra,136(sp)
    80005a86:	e122                	sd	s0,128(sp)
    80005a88:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	8be080e7          	jalr	-1858(ra) # 80004348 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a92:	08000613          	li	a2,128
    80005a96:	f7040593          	addi	a1,s0,-144
    80005a9a:	4501                	li	a0,0
    80005a9c:	ffffd097          	auipc	ra,0xffffd
    80005aa0:	3ac080e7          	jalr	940(ra) # 80002e48 <argstr>
    80005aa4:	02054963          	bltz	a0,80005ad6 <sys_mkdir+0x54>
    80005aa8:	4681                	li	a3,0
    80005aaa:	4601                	li	a2,0
    80005aac:	4585                	li	a1,1
    80005aae:	f7040513          	addi	a0,s0,-144
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	7fe080e7          	jalr	2046(ra) # 800052b0 <create>
    80005aba:	cd11                	beqz	a0,80005ad6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	11c080e7          	jalr	284(ra) # 80003bd8 <iunlockput>
  end_op();
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	904080e7          	jalr	-1788(ra) # 800043c8 <end_op>
  return 0;
    80005acc:	4501                	li	a0,0
}
    80005ace:	60aa                	ld	ra,136(sp)
    80005ad0:	640a                	ld	s0,128(sp)
    80005ad2:	6149                	addi	sp,sp,144
    80005ad4:	8082                	ret
    end_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	8f2080e7          	jalr	-1806(ra) # 800043c8 <end_op>
    return -1;
    80005ade:	557d                	li	a0,-1
    80005ae0:	b7fd                	j	80005ace <sys_mkdir+0x4c>

0000000080005ae2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ae2:	7135                	addi	sp,sp,-160
    80005ae4:	ed06                	sd	ra,152(sp)
    80005ae6:	e922                	sd	s0,144(sp)
    80005ae8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	85e080e7          	jalr	-1954(ra) # 80004348 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005af2:	08000613          	li	a2,128
    80005af6:	f7040593          	addi	a1,s0,-144
    80005afa:	4501                	li	a0,0
    80005afc:	ffffd097          	auipc	ra,0xffffd
    80005b00:	34c080e7          	jalr	844(ra) # 80002e48 <argstr>
    80005b04:	04054a63          	bltz	a0,80005b58 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b08:	f6c40593          	addi	a1,s0,-148
    80005b0c:	4505                	li	a0,1
    80005b0e:	ffffd097          	auipc	ra,0xffffd
    80005b12:	2f6080e7          	jalr	758(ra) # 80002e04 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b16:	04054163          	bltz	a0,80005b58 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b1a:	f6840593          	addi	a1,s0,-152
    80005b1e:	4509                	li	a0,2
    80005b20:	ffffd097          	auipc	ra,0xffffd
    80005b24:	2e4080e7          	jalr	740(ra) # 80002e04 <argint>
     argint(1, &major) < 0 ||
    80005b28:	02054863          	bltz	a0,80005b58 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b2c:	f6841683          	lh	a3,-152(s0)
    80005b30:	f6c41603          	lh	a2,-148(s0)
    80005b34:	458d                	li	a1,3
    80005b36:	f7040513          	addi	a0,s0,-144
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	776080e7          	jalr	1910(ra) # 800052b0 <create>
     argint(2, &minor) < 0 ||
    80005b42:	c919                	beqz	a0,80005b58 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	094080e7          	jalr	148(ra) # 80003bd8 <iunlockput>
  end_op();
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	87c080e7          	jalr	-1924(ra) # 800043c8 <end_op>
  return 0;
    80005b54:	4501                	li	a0,0
    80005b56:	a031                	j	80005b62 <sys_mknod+0x80>
    end_op();
    80005b58:	fffff097          	auipc	ra,0xfffff
    80005b5c:	870080e7          	jalr	-1936(ra) # 800043c8 <end_op>
    return -1;
    80005b60:	557d                	li	a0,-1
}
    80005b62:	60ea                	ld	ra,152(sp)
    80005b64:	644a                	ld	s0,144(sp)
    80005b66:	610d                	addi	sp,sp,160
    80005b68:	8082                	ret

0000000080005b6a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b6a:	7135                	addi	sp,sp,-160
    80005b6c:	ed06                	sd	ra,152(sp)
    80005b6e:	e922                	sd	s0,144(sp)
    80005b70:	e526                	sd	s1,136(sp)
    80005b72:	e14a                	sd	s2,128(sp)
    80005b74:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b76:	ffffc097          	auipc	ra,0xffffc
    80005b7a:	e7e080e7          	jalr	-386(ra) # 800019f4 <myproc>
    80005b7e:	892a                	mv	s2,a0
  
  begin_op();
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	7c8080e7          	jalr	1992(ra) # 80004348 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b88:	08000613          	li	a2,128
    80005b8c:	f6040593          	addi	a1,s0,-160
    80005b90:	4501                	li	a0,0
    80005b92:	ffffd097          	auipc	ra,0xffffd
    80005b96:	2b6080e7          	jalr	694(ra) # 80002e48 <argstr>
    80005b9a:	04054b63          	bltz	a0,80005bf0 <sys_chdir+0x86>
    80005b9e:	f6040513          	addi	a0,s0,-160
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	58a080e7          	jalr	1418(ra) # 8000412c <namei>
    80005baa:	84aa                	mv	s1,a0
    80005bac:	c131                	beqz	a0,80005bf0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	dc8080e7          	jalr	-568(ra) # 80003976 <ilock>
  if(ip->type != T_DIR){
    80005bb6:	04449703          	lh	a4,68(s1)
    80005bba:	4785                	li	a5,1
    80005bbc:	04f71063          	bne	a4,a5,80005bfc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bc0:	8526                	mv	a0,s1
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	e76080e7          	jalr	-394(ra) # 80003a38 <iunlock>
  iput(p->cwd);
    80005bca:	15093503          	ld	a0,336(s2)
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	f62080e7          	jalr	-158(ra) # 80003b30 <iput>
  end_op();
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	7f2080e7          	jalr	2034(ra) # 800043c8 <end_op>
  p->cwd = ip;
    80005bde:	14993823          	sd	s1,336(s2)
  return 0;
    80005be2:	4501                	li	a0,0
}
    80005be4:	60ea                	ld	ra,152(sp)
    80005be6:	644a                	ld	s0,144(sp)
    80005be8:	64aa                	ld	s1,136(sp)
    80005bea:	690a                	ld	s2,128(sp)
    80005bec:	610d                	addi	sp,sp,160
    80005bee:	8082                	ret
    end_op();
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	7d8080e7          	jalr	2008(ra) # 800043c8 <end_op>
    return -1;
    80005bf8:	557d                	li	a0,-1
    80005bfa:	b7ed                	j	80005be4 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bfc:	8526                	mv	a0,s1
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	fda080e7          	jalr	-38(ra) # 80003bd8 <iunlockput>
    end_op();
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	7c2080e7          	jalr	1986(ra) # 800043c8 <end_op>
    return -1;
    80005c0e:	557d                	li	a0,-1
    80005c10:	bfd1                	j	80005be4 <sys_chdir+0x7a>

0000000080005c12 <sys_exec>:

uint64
sys_exec(void)
{
    80005c12:	7145                	addi	sp,sp,-464
    80005c14:	e786                	sd	ra,456(sp)
    80005c16:	e3a2                	sd	s0,448(sp)
    80005c18:	ff26                	sd	s1,440(sp)
    80005c1a:	fb4a                	sd	s2,432(sp)
    80005c1c:	f74e                	sd	s3,424(sp)
    80005c1e:	f352                	sd	s4,416(sp)
    80005c20:	ef56                	sd	s5,408(sp)
    80005c22:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c24:	08000613          	li	a2,128
    80005c28:	f4040593          	addi	a1,s0,-192
    80005c2c:	4501                	li	a0,0
    80005c2e:	ffffd097          	auipc	ra,0xffffd
    80005c32:	21a080e7          	jalr	538(ra) # 80002e48 <argstr>
    return -1;
    80005c36:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c38:	0c054a63          	bltz	a0,80005d0c <sys_exec+0xfa>
    80005c3c:	e3840593          	addi	a1,s0,-456
    80005c40:	4505                	li	a0,1
    80005c42:	ffffd097          	auipc	ra,0xffffd
    80005c46:	1e4080e7          	jalr	484(ra) # 80002e26 <argaddr>
    80005c4a:	0c054163          	bltz	a0,80005d0c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c4e:	10000613          	li	a2,256
    80005c52:	4581                	li	a1,0
    80005c54:	e4040513          	addi	a0,s0,-448
    80005c58:	ffffb097          	auipc	ra,0xffffb
    80005c5c:	07a080e7          	jalr	122(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c60:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c64:	89a6                	mv	s3,s1
    80005c66:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c68:	02000a13          	li	s4,32
    80005c6c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c70:	00391513          	slli	a0,s2,0x3
    80005c74:	e3040593          	addi	a1,s0,-464
    80005c78:	e3843783          	ld	a5,-456(s0)
    80005c7c:	953e                	add	a0,a0,a5
    80005c7e:	ffffd097          	auipc	ra,0xffffd
    80005c82:	0ec080e7          	jalr	236(ra) # 80002d6a <fetchaddr>
    80005c86:	02054a63          	bltz	a0,80005cba <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c8a:	e3043783          	ld	a5,-464(s0)
    80005c8e:	c3b9                	beqz	a5,80005cd4 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c90:	ffffb097          	auipc	ra,0xffffb
    80005c94:	e56080e7          	jalr	-426(ra) # 80000ae6 <kalloc>
    80005c98:	85aa                	mv	a1,a0
    80005c9a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c9e:	cd11                	beqz	a0,80005cba <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ca0:	6605                	lui	a2,0x1
    80005ca2:	e3043503          	ld	a0,-464(s0)
    80005ca6:	ffffd097          	auipc	ra,0xffffd
    80005caa:	116080e7          	jalr	278(ra) # 80002dbc <fetchstr>
    80005cae:	00054663          	bltz	a0,80005cba <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cb2:	0905                	addi	s2,s2,1
    80005cb4:	09a1                	addi	s3,s3,8
    80005cb6:	fb491be3          	bne	s2,s4,80005c6c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cba:	10048913          	addi	s2,s1,256
    80005cbe:	6088                	ld	a0,0(s1)
    80005cc0:	c529                	beqz	a0,80005d0a <sys_exec+0xf8>
    kfree(argv[i]);
    80005cc2:	ffffb097          	auipc	ra,0xffffb
    80005cc6:	d28080e7          	jalr	-728(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cca:	04a1                	addi	s1,s1,8
    80005ccc:	ff2499e3          	bne	s1,s2,80005cbe <sys_exec+0xac>
  return -1;
    80005cd0:	597d                	li	s2,-1
    80005cd2:	a82d                	j	80005d0c <sys_exec+0xfa>
      argv[i] = 0;
    80005cd4:	0a8e                	slli	s5,s5,0x3
    80005cd6:	fc040793          	addi	a5,s0,-64
    80005cda:	9abe                	add	s5,s5,a5
    80005cdc:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ce0:	e4040593          	addi	a1,s0,-448
    80005ce4:	f4040513          	addi	a0,s0,-192
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	194080e7          	jalr	404(ra) # 80004e7c <exec>
    80005cf0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cf2:	10048993          	addi	s3,s1,256
    80005cf6:	6088                	ld	a0,0(s1)
    80005cf8:	c911                	beqz	a0,80005d0c <sys_exec+0xfa>
    kfree(argv[i]);
    80005cfa:	ffffb097          	auipc	ra,0xffffb
    80005cfe:	cf0080e7          	jalr	-784(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d02:	04a1                	addi	s1,s1,8
    80005d04:	ff3499e3          	bne	s1,s3,80005cf6 <sys_exec+0xe4>
    80005d08:	a011                	j	80005d0c <sys_exec+0xfa>
  return -1;
    80005d0a:	597d                	li	s2,-1
}
    80005d0c:	854a                	mv	a0,s2
    80005d0e:	60be                	ld	ra,456(sp)
    80005d10:	641e                	ld	s0,448(sp)
    80005d12:	74fa                	ld	s1,440(sp)
    80005d14:	795a                	ld	s2,432(sp)
    80005d16:	79ba                	ld	s3,424(sp)
    80005d18:	7a1a                	ld	s4,416(sp)
    80005d1a:	6afa                	ld	s5,408(sp)
    80005d1c:	6179                	addi	sp,sp,464
    80005d1e:	8082                	ret

0000000080005d20 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d20:	7139                	addi	sp,sp,-64
    80005d22:	fc06                	sd	ra,56(sp)
    80005d24:	f822                	sd	s0,48(sp)
    80005d26:	f426                	sd	s1,40(sp)
    80005d28:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d2a:	ffffc097          	auipc	ra,0xffffc
    80005d2e:	cca080e7          	jalr	-822(ra) # 800019f4 <myproc>
    80005d32:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d34:	fd840593          	addi	a1,s0,-40
    80005d38:	4501                	li	a0,0
    80005d3a:	ffffd097          	auipc	ra,0xffffd
    80005d3e:	0ec080e7          	jalr	236(ra) # 80002e26 <argaddr>
    return -1;
    80005d42:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d44:	0e054063          	bltz	a0,80005e24 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d48:	fc840593          	addi	a1,s0,-56
    80005d4c:	fd040513          	addi	a0,s0,-48
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	dfc080e7          	jalr	-516(ra) # 80004b4c <pipealloc>
    return -1;
    80005d58:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d5a:	0c054563          	bltz	a0,80005e24 <sys_pipe+0x104>
  fd0 = -1;
    80005d5e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d62:	fd043503          	ld	a0,-48(s0)
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	508080e7          	jalr	1288(ra) # 8000526e <fdalloc>
    80005d6e:	fca42223          	sw	a0,-60(s0)
    80005d72:	08054c63          	bltz	a0,80005e0a <sys_pipe+0xea>
    80005d76:	fc843503          	ld	a0,-56(s0)
    80005d7a:	fffff097          	auipc	ra,0xfffff
    80005d7e:	4f4080e7          	jalr	1268(ra) # 8000526e <fdalloc>
    80005d82:	fca42023          	sw	a0,-64(s0)
    80005d86:	06054863          	bltz	a0,80005df6 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d8a:	4691                	li	a3,4
    80005d8c:	fc440613          	addi	a2,s0,-60
    80005d90:	fd843583          	ld	a1,-40(s0)
    80005d94:	68a8                	ld	a0,80(s1)
    80005d96:	ffffc097          	auipc	ra,0xffffc
    80005d9a:	8a2080e7          	jalr	-1886(ra) # 80001638 <copyout>
    80005d9e:	02054063          	bltz	a0,80005dbe <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005da2:	4691                	li	a3,4
    80005da4:	fc040613          	addi	a2,s0,-64
    80005da8:	fd843583          	ld	a1,-40(s0)
    80005dac:	0591                	addi	a1,a1,4
    80005dae:	68a8                	ld	a0,80(s1)
    80005db0:	ffffc097          	auipc	ra,0xffffc
    80005db4:	888080e7          	jalr	-1912(ra) # 80001638 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005db8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dba:	06055563          	bgez	a0,80005e24 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005dbe:	fc442783          	lw	a5,-60(s0)
    80005dc2:	07e9                	addi	a5,a5,26
    80005dc4:	078e                	slli	a5,a5,0x3
    80005dc6:	97a6                	add	a5,a5,s1
    80005dc8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005dcc:	fc042503          	lw	a0,-64(s0)
    80005dd0:	0569                	addi	a0,a0,26
    80005dd2:	050e                	slli	a0,a0,0x3
    80005dd4:	9526                	add	a0,a0,s1
    80005dd6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005dda:	fd043503          	ld	a0,-48(s0)
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	a3e080e7          	jalr	-1474(ra) # 8000481c <fileclose>
    fileclose(wf);
    80005de6:	fc843503          	ld	a0,-56(s0)
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	a32080e7          	jalr	-1486(ra) # 8000481c <fileclose>
    return -1;
    80005df2:	57fd                	li	a5,-1
    80005df4:	a805                	j	80005e24 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005df6:	fc442783          	lw	a5,-60(s0)
    80005dfa:	0007c863          	bltz	a5,80005e0a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005dfe:	01a78513          	addi	a0,a5,26
    80005e02:	050e                	slli	a0,a0,0x3
    80005e04:	9526                	add	a0,a0,s1
    80005e06:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e0a:	fd043503          	ld	a0,-48(s0)
    80005e0e:	fffff097          	auipc	ra,0xfffff
    80005e12:	a0e080e7          	jalr	-1522(ra) # 8000481c <fileclose>
    fileclose(wf);
    80005e16:	fc843503          	ld	a0,-56(s0)
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	a02080e7          	jalr	-1534(ra) # 8000481c <fileclose>
    return -1;
    80005e22:	57fd                	li	a5,-1
}
    80005e24:	853e                	mv	a0,a5
    80005e26:	70e2                	ld	ra,56(sp)
    80005e28:	7442                	ld	s0,48(sp)
    80005e2a:	74a2                	ld	s1,40(sp)
    80005e2c:	6121                	addi	sp,sp,64
    80005e2e:	8082                	ret

0000000080005e30 <sys_mmap>:
// the minimum address the mmap can ues - lab10
#define MMAPMINADDR (TRAPFRAME - 10 * PGSIZE)

uint64 
sys_mmap(void) 
{
    80005e30:	7139                	addi	sp,sp,-64
    80005e32:	fc06                	sd	ra,56(sp)
    80005e34:	f822                	sd	s0,48(sp)
    80005e36:	f426                	sd	s1,40(sp)
    80005e38:	0080                	addi	s0,sp,64
  uint64 addr;
  int len, prot, flags, offset;
  struct file *f;
  struct vma *vmarea = 0;
  struct proc *p = myproc();
    80005e3a:	ffffc097          	auipc	ra,0xffffc
    80005e3e:	bba080e7          	jalr	-1094(ra) # 800019f4 <myproc>
    80005e42:	84aa                	mv	s1,a0
  int i;

  if (argaddr(0, &addr) < 0 || argint(1, &len) < 0
    80005e44:	fd840593          	addi	a1,s0,-40
    80005e48:	4501                	li	a0,0
    80005e4a:	ffffd097          	auipc	ra,0xffffd
    80005e4e:	fdc080e7          	jalr	-36(ra) # 80002e26 <argaddr>
      || argint(2, &prot) < 0 || argint(3, &flags) < 0
      || argfd(4, 0, &f) < 0 || argint(5, &offset) < 0) {
    return -1;
    80005e52:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0 || argint(1, &len) < 0
    80005e54:	14054863          	bltz	a0,80005fa4 <sys_mmap+0x174>
    80005e58:	fd440593          	addi	a1,s0,-44
    80005e5c:	4505                	li	a0,1
    80005e5e:	ffffd097          	auipc	ra,0xffffd
    80005e62:	fa6080e7          	jalr	-90(ra) # 80002e04 <argint>
    return -1;
    80005e66:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0 || argint(1, &len) < 0
    80005e68:	12054e63          	bltz	a0,80005fa4 <sys_mmap+0x174>
      || argint(2, &prot) < 0 || argint(3, &flags) < 0
    80005e6c:	fd040593          	addi	a1,s0,-48
    80005e70:	4509                	li	a0,2
    80005e72:	ffffd097          	auipc	ra,0xffffd
    80005e76:	f92080e7          	jalr	-110(ra) # 80002e04 <argint>
    return -1;
    80005e7a:	57fd                	li	a5,-1
      || argint(2, &prot) < 0 || argint(3, &flags) < 0
    80005e7c:	12054463          	bltz	a0,80005fa4 <sys_mmap+0x174>
    80005e80:	fcc40593          	addi	a1,s0,-52
    80005e84:	450d                	li	a0,3
    80005e86:	ffffd097          	auipc	ra,0xffffd
    80005e8a:	f7e080e7          	jalr	-130(ra) # 80002e04 <argint>
    return -1;
    80005e8e:	57fd                	li	a5,-1
      || argint(2, &prot) < 0 || argint(3, &flags) < 0
    80005e90:	10054a63          	bltz	a0,80005fa4 <sys_mmap+0x174>
      || argfd(4, 0, &f) < 0 || argint(5, &offset) < 0) {
    80005e94:	fc040613          	addi	a2,s0,-64
    80005e98:	4581                	li	a1,0
    80005e9a:	4511                	li	a0,4
    80005e9c:	fffff097          	auipc	ra,0xfffff
    80005ea0:	36a080e7          	jalr	874(ra) # 80005206 <argfd>
    return -1;
    80005ea4:	57fd                	li	a5,-1
      || argfd(4, 0, &f) < 0 || argint(5, &offset) < 0) {
    80005ea6:	0e054f63          	bltz	a0,80005fa4 <sys_mmap+0x174>
    80005eaa:	fc840593          	addi	a1,s0,-56
    80005eae:	4515                	li	a0,5
    80005eb0:	ffffd097          	auipc	ra,0xffffd
    80005eb4:	f54080e7          	jalr	-172(ra) # 80002e04 <argint>
    80005eb8:	0e054c63          	bltz	a0,80005fb0 <sys_mmap+0x180>
  }
  if (flags != MAP_SHARED && flags != MAP_PRIVATE) {
    80005ebc:	fcc42883          	lw	a7,-52(s0)
    80005ec0:	fff8869b          	addiw	a3,a7,-1
    80005ec4:	4705                	li	a4,1
    return -1;
    80005ec6:	57fd                	li	a5,-1
  if (flags != MAP_SHARED && flags != MAP_PRIVATE) {
    80005ec8:	0cd76e63          	bltu	a4,a3,80005fa4 <sys_mmap+0x174>
  }
  // the file must be written when flag is MAP_SHARED
  if (flags == MAP_SHARED && f->writable == 0 && (prot & PROT_WRITE)) {
    80005ecc:	4785                	li	a5,1
    80005ece:	02f88c63          	beq	a7,a5,80005f06 <sys_mmap+0xd6>
    return -1;
  }
  // offset must be a multiple of the page size
  if (len < 0 || offset < 0 || offset % PGSIZE) {
    80005ed2:	fd442303          	lw	t1,-44(s0)
    80005ed6:	0c034f63          	bltz	t1,80005fb4 <sys_mmap+0x184>
    80005eda:	fc842e03          	lw	t3,-56(s0)
    80005ede:	0c0e4d63          	bltz	t3,80005fb8 <sys_mmap+0x188>
    80005ee2:	034e1713          	slli	a4,t3,0x34
    return -1;
    80005ee6:	57fd                	li	a5,-1
  if (len < 0 || offset < 0 || offset % PGSIZE) {
    80005ee8:	ef55                	bnez	a4,80005fa4 <sys_mmap+0x174>
    80005eea:	16848793          	addi	a5,s1,360
    80005eee:	873e                	mv	a4,a5
  }

  // allocate a VMA for the mapped memory
  for (i = 0; i < NVMA; ++i) {
    80005ef0:	4601                	li	a2,0
    80005ef2:	45c1                	li	a1,16
    if (!p->vma_list[i].addr) {
    80005ef4:	6314                	ld	a3,0(a4)
    80005ef6:	c29d                	beqz	a3,80005f1c <sys_mmap+0xec>
  for (i = 0; i < NVMA; ++i) {
    80005ef8:	2605                	addiw	a2,a2,1
    80005efa:	02070713          	addi	a4,a4,32
    80005efe:	feb61be3          	bne	a2,a1,80005ef4 <sys_mmap+0xc4>
      vmarea = &p->vma_list[i];
      break;
    }
  }
  if (!vmarea) {
    return -1;
    80005f02:	57fd                	li	a5,-1
    80005f04:	a045                	j	80005fa4 <sys_mmap+0x174>
  if (flags == MAP_SHARED && f->writable == 0 && (prot & PROT_WRITE)) {
    80005f06:	fc043783          	ld	a5,-64(s0)
    80005f0a:	0097c783          	lbu	a5,9(a5)
    80005f0e:	f3f1                	bnez	a5,80005ed2 <sys_mmap+0xa2>
    80005f10:	fd042703          	lw	a4,-48(s0)
    80005f14:	8b09                	andi	a4,a4,2
    return -1;
    80005f16:	57fd                	li	a5,-1
  if (flags == MAP_SHARED && f->writable == 0 && (prot & PROT_WRITE)) {
    80005f18:	df4d                	beqz	a4,80005ed2 <sys_mmap+0xa2>
    80005f1a:	a069                	j	80005fa4 <sys_mmap+0x174>
  }

  // assume that addr will always be 0, the kernel 
  //choose the page-aligned address at which to create
  //the mapping
  addr = MMAPMINADDR;
    80005f1c:	010005b7          	lui	a1,0x1000
    80005f20:	15f5                	addi	a1,a1,-3
    80005f22:	05ba                	slli	a1,a1,0xe
    80005f24:	fcb43c23          	sd	a1,-40(s0)
  for (i = 0; i < NVMA; ++i) {
    80005f28:	36848513          	addi	a0,s1,872
    if (p->vma_list[i].addr) {
      // get the max address of the mapped memory  
      addr = max(addr, p->vma_list[i].addr + p->vma_list[i].len);
    80005f2c:	4805                	li	a6,1
    80005f2e:	a031                	j	80005f3a <sys_mmap+0x10a>
    80005f30:	86c2                	mv	a3,a6
  for (i = 0; i < NVMA; ++i) {
    80005f32:	02078793          	addi	a5,a5,32
    80005f36:	00a78a63          	beq	a5,a0,80005f4a <sys_mmap+0x11a>
    if (p->vma_list[i].addr) {
    80005f3a:	6398                	ld	a4,0(a5)
    80005f3c:	db7d                	beqz	a4,80005f32 <sys_mmap+0x102>
      addr = max(addr, p->vma_list[i].addr + p->vma_list[i].len);
    80005f3e:	4794                	lw	a3,8(a5)
    80005f40:	9736                	add	a4,a4,a3
    80005f42:	fee5f7e3          	bgeu	a1,a4,80005f30 <sys_mmap+0x100>
    80005f46:	85ba                	mv	a1,a4
    80005f48:	b7e5                	j	80005f30 <sys_mmap+0x100>
    80005f4a:	c299                	beqz	a3,80005f50 <sys_mmap+0x120>
    80005f4c:	fcb43c23          	sd	a1,-40(s0)
    }
  }
  addr = PGROUNDUP(addr);
    80005f50:	fd843703          	ld	a4,-40(s0)
    80005f54:	6785                	lui	a5,0x1
    80005f56:	17fd                	addi	a5,a5,-1
    80005f58:	973e                	add	a4,a4,a5
    80005f5a:	77fd                	lui	a5,0xfffff
    80005f5c:	8f7d                	and	a4,a4,a5
    80005f5e:	fce43c23          	sd	a4,-40(s0)
  if (addr + len > TRAPFRAME) {
    80005f62:	00e305b3          	add	a1,t1,a4
    80005f66:	020006b7          	lui	a3,0x2000
    80005f6a:	16fd                	addi	a3,a3,-1
    80005f6c:	06b6                	slli	a3,a3,0xd
    return -1;
    80005f6e:	57fd                	li	a5,-1
  if (addr + len > TRAPFRAME) {
    80005f70:	02b6ea63          	bltu	a3,a1,80005fa4 <sys_mmap+0x174>
  }
  vmarea->addr = addr;   
    80005f74:	0616                	slli	a2,a2,0x5
    80005f76:	9626                	add	a2,a2,s1
    80005f78:	16e63423          	sd	a4,360(a2) # 1168 <_entry-0x7fffee98>
  vmarea->len = len;
    80005f7c:	16662823          	sw	t1,368(a2)
  vmarea->prot = prot;
    80005f80:	fd042783          	lw	a5,-48(s0)
    80005f84:	16f62a23          	sw	a5,372(a2)
  vmarea->flags = flags;
    80005f88:	17162c23          	sw	a7,376(a2)
  vmarea->offset = offset;
    80005f8c:	17c62e23          	sw	t3,380(a2)
  vmarea->f = f;
    80005f90:	fc043503          	ld	a0,-64(s0)
    80005f94:	18a63023          	sd	a0,384(a2)
  filedup(f);     // increase the file's reference count
    80005f98:	fffff097          	auipc	ra,0xfffff
    80005f9c:	832080e7          	jalr	-1998(ra) # 800047ca <filedup>

  return addr;
    80005fa0:	fd843783          	ld	a5,-40(s0)
}
    80005fa4:	853e                	mv	a0,a5
    80005fa6:	70e2                	ld	ra,56(sp)
    80005fa8:	7442                	ld	s0,48(sp)
    80005faa:	74a2                	ld	s1,40(sp)
    80005fac:	6121                	addi	sp,sp,64
    80005fae:	8082                	ret
    return -1;
    80005fb0:	57fd                	li	a5,-1
    80005fb2:	bfcd                	j	80005fa4 <sys_mmap+0x174>
    return -1;
    80005fb4:	57fd                	li	a5,-1
    80005fb6:	b7fd                	j	80005fa4 <sys_mmap+0x174>
    80005fb8:	57fd                	li	a5,-1
    80005fba:	b7ed                	j	80005fa4 <sys_mmap+0x174>

0000000080005fbc <sys_munmap>:



// lab10
uint64 sys_munmap(void) {
    80005fbc:	7175                	addi	sp,sp,-144
    80005fbe:	e506                	sd	ra,136(sp)
    80005fc0:	e122                	sd	s0,128(sp)
    80005fc2:	fca6                	sd	s1,120(sp)
    80005fc4:	f8ca                	sd	s2,112(sp)
    80005fc6:	f4ce                	sd	s3,104(sp)
    80005fc8:	f0d2                	sd	s4,96(sp)
    80005fca:	ecd6                	sd	s5,88(sp)
    80005fcc:	e8da                	sd	s6,80(sp)
    80005fce:	e4de                	sd	s7,72(sp)
    80005fd0:	e0e2                	sd	s8,64(sp)
    80005fd2:	fc66                	sd	s9,56(sp)
    80005fd4:	f86a                	sd	s10,48(sp)
    80005fd6:	f46e                	sd	s11,40(sp)
    80005fd8:	0900                	addi	s0,sp,144
  uint64 addr, va;
  int len;
  struct proc *p = myproc();
    80005fda:	ffffc097          	auipc	ra,0xffffc
    80005fde:	a1a080e7          	jalr	-1510(ra) # 800019f4 <myproc>
    80005fe2:	84aa                	mv	s1,a0
    80005fe4:	f6a43c23          	sd	a0,-136(s0)
  struct vma *vma = 0;
  uint maxsz, n, n1;
  int i;

  if (argaddr(0, &addr) < 0 || argint(1, &len) < 0) {
    80005fe8:	f8840593          	addi	a1,s0,-120
    80005fec:	4501                	li	a0,0
    80005fee:	ffffd097          	auipc	ra,0xffffd
    80005ff2:	e38080e7          	jalr	-456(ra) # 80002e26 <argaddr>
    80005ff6:	26054163          	bltz	a0,80006258 <sys_munmap+0x29c>
    80005ffa:	f8440593          	addi	a1,s0,-124
    80005ffe:	4505                	li	a0,1
    80006000:	ffffd097          	auipc	ra,0xffffd
    80006004:	e04080e7          	jalr	-508(ra) # 80002e04 <argint>
    80006008:	24054a63          	bltz	a0,8000625c <sys_munmap+0x2a0>
    return -1;
  }
  if (addr % PGSIZE || len < 0) {
    8000600c:	f8843a03          	ld	s4,-120(s0)
    80006010:	034a1793          	slli	a5,s4,0x34
    80006014:	0347dd13          	srli	s10,a5,0x34
    80006018:	24079463          	bnez	a5,80006260 <sys_munmap+0x2a4>
    8000601c:	f8442503          	lw	a0,-124(s0)
    80006020:	24054263          	bltz	a0,80006264 <sys_munmap+0x2a8>
    80006024:	16848793          	addi	a5,s1,360
    return -1;
  }

  // find the VMA
  for (i = 0; i < NVMA; ++i) {
    80006028:	4481                	li	s1,0
    if (p->vma_list[i].addr && addr >= p->vma_list[i].addr
        && addr + len <= p->vma_list[i].addr + p->vma_list[i].len) {
    8000602a:	014505b3          	add	a1,a0,s4
  for (i = 0; i < NVMA; ++i) {
    8000602e:	4641                	li	a2,16
    80006030:	a031                	j	8000603c <sys_munmap+0x80>
    80006032:	2485                	addiw	s1,s1,1
    80006034:	02078793          	addi	a5,a5,32 # fffffffffffff020 <end+0xffffffff7ffd1020>
    80006038:	04c48263          	beq	s1,a2,8000607c <sys_munmap+0xc0>
    if (p->vma_list[i].addr && addr >= p->vma_list[i].addr
    8000603c:	6398                	ld	a4,0(a5)
    8000603e:	db75                	beqz	a4,80006032 <sys_munmap+0x76>
    80006040:	feea69e3          	bltu	s4,a4,80006032 <sys_munmap+0x76>
        && addr + len <= p->vma_list[i].addr + p->vma_list[i].len) {
    80006044:	4794                	lw	a3,8(a5)
    80006046:	9736                	add	a4,a4,a3
    80006048:	feb765e3          	bltu	a4,a1,80006032 <sys_munmap+0x76>
  }
  if (!vma) {
    return -1;
  }

  if (len == 0) {
    8000604c:	c90d                	beqz	a0,8000607e <sys_munmap+0xc2>
    return 0;
  }

  if ((vma->flags & MAP_SHARED)) {
    8000604e:	00549793          	slli	a5,s1,0x5
    80006052:	f7843703          	ld	a4,-136(s0)
    80006056:	97ba                	add	a5,a5,a4
    80006058:	1787a783          	lw	a5,376(a5)
    8000605c:	8b85                	andi	a5,a5,1
    8000605e:	12078963          	beqz	a5,80006190 <sys_munmap+0x1d4>
    // the max size once can write to the disk
    maxsz = ((MAXOPBLOCKS - 1 - 1 - 2) / 2) * BSIZE;
    for (va = addr; va < addr + len; va += PGSIZE) {
    80006062:	12ba7763          	bgeu	s4,a1,80006190 <sys_munmap+0x1d4>
        continue;
      }
      // only write the dirty page back to the mapped file
      n = min(PGSIZE, addr + len - va);
      for (i = 0; i < n; i += n1) {
        n1 = min(maxsz, n - i);
    80006066:	6785                	lui	a5,0x1
    80006068:	c0078d93          	addi	s11,a5,-1024 # c00 <_entry-0x7ffff400>
        begin_op();
        ilock(vma->f->ip);
    8000606c:	00549b13          	slli	s6,s1,0x5
    80006070:	9b3a                	add	s6,s6,a4
        if (writei(vma->f->ip, 1, va + i, va - vma->addr + vma->offset + i, n1) != n1) {
    80006072:	00b48c93          	addi	s9,s1,11
    80006076:	0c96                	slli	s9,s9,0x5
    80006078:	9cba                	add	s9,s9,a4
    8000607a:	a8e1                	j	80006152 <sys_munmap+0x196>
    return -1;
    8000607c:	5d7d                	li	s10,-1
    vma->len -= len;
  } else {
    panic("unexpected munmap");
  }
  return 0;
    8000607e:	856a                	mv	a0,s10
    80006080:	60aa                	ld	ra,136(sp)
    80006082:	640a                	ld	s0,128(sp)
    80006084:	74e6                	ld	s1,120(sp)
    80006086:	7946                	ld	s2,112(sp)
    80006088:	79a6                	ld	s3,104(sp)
    8000608a:	7a06                	ld	s4,96(sp)
    8000608c:	6ae6                	ld	s5,88(sp)
    8000608e:	6b46                	ld	s6,80(sp)
    80006090:	6ba6                	ld	s7,72(sp)
    80006092:	6c06                	ld	s8,64(sp)
    80006094:	7ce2                	ld	s9,56(sp)
    80006096:	7d42                	ld	s10,48(sp)
    80006098:	7da2                	ld	s11,40(sp)
    8000609a:	6149                	addi	sp,sp,144
    8000609c:	8082                	ret
        n1 = min(maxsz, n - i);
    8000609e:	0009099b          	sext.w	s3,s2
        begin_op();
    800060a2:	ffffe097          	auipc	ra,0xffffe
    800060a6:	2a6080e7          	jalr	678(ra) # 80004348 <begin_op>
        ilock(vma->f->ip);
    800060aa:	180b3783          	ld	a5,384(s6)
    800060ae:	6f88                	ld	a0,24(a5)
    800060b0:	ffffe097          	auipc	ra,0xffffe
    800060b4:	8c6080e7          	jalr	-1850(ra) # 80003976 <ilock>
        if (writei(vma->f->ip, 1, va + i, va - vma->addr + vma->offset + i, n1) != n1) {
    800060b8:	008cb783          	ld	a5,8(s9)
    800060bc:	17cb2683          	lw	a3,380(s6)
    800060c0:	9e9d                	subw	a3,a3,a5
    800060c2:	014686bb          	addw	a3,a3,s4
    800060c6:	180b3783          	ld	a5,384(s6)
    800060ca:	874e                	mv	a4,s3
    800060cc:	015686bb          	addw	a3,a3,s5
    800060d0:	014c0633          	add	a2,s8,s4
    800060d4:	4585                	li	a1,1
    800060d6:	6f88                	ld	a0,24(a5)
    800060d8:	ffffe097          	auipc	ra,0xffffe
    800060dc:	c4a080e7          	jalr	-950(ra) # 80003d22 <writei>
    800060e0:	2501                	sext.w	a0,a0
    800060e2:	03351d63          	bne	a0,s3,8000611c <sys_munmap+0x160>
        iunlock(vma->f->ip);
    800060e6:	180b3783          	ld	a5,384(s6)
    800060ea:	6f88                	ld	a0,24(a5)
    800060ec:	ffffe097          	auipc	ra,0xffffe
    800060f0:	94c080e7          	jalr	-1716(ra) # 80003a38 <iunlock>
        end_op();
    800060f4:	ffffe097          	auipc	ra,0xffffe
    800060f8:	2d4080e7          	jalr	724(ra) # 800043c8 <end_op>
      for (i = 0; i < n; i += n1) {
    800060fc:	0159093b          	addw	s2,s2,s5
    80006100:	00090a9b          	sext.w	s5,s2
    80006104:	8c56                	mv	s8,s5
    80006106:	037afd63          	bgeu	s5,s7,80006140 <sys_munmap+0x184>
        n1 = min(maxsz, n - i);
    8000610a:	415b893b          	subw	s2,s7,s5
    8000610e:	0009079b          	sext.w	a5,s2
    80006112:	f8fdf6e3          	bgeu	s11,a5,8000609e <sys_munmap+0xe2>
    80006116:	f7442903          	lw	s2,-140(s0)
    8000611a:	b751                	j	8000609e <sys_munmap+0xe2>
          iunlock(vma->f->ip);
    8000611c:	0496                	slli	s1,s1,0x5
    8000611e:	f7843783          	ld	a5,-136(s0)
    80006122:	00978533          	add	a0,a5,s1
    80006126:	18053783          	ld	a5,384(a0)
    8000612a:	6f88                	ld	a0,24(a5)
    8000612c:	ffffe097          	auipc	ra,0xffffe
    80006130:	90c080e7          	jalr	-1780(ra) # 80003a38 <iunlock>
          end_op();
    80006134:	ffffe097          	auipc	ra,0xffffe
    80006138:	294080e7          	jalr	660(ra) # 800043c8 <end_op>
          return -1;
    8000613c:	5d7d                	li	s10,-1
    8000613e:	b781                	j	8000607e <sys_munmap+0xc2>
    for (va = addr; va < addr + len; va += PGSIZE) {
    80006140:	6785                	lui	a5,0x1
    80006142:	9a3e                	add	s4,s4,a5
    80006144:	f8442783          	lw	a5,-124(s0)
    80006148:	f8843703          	ld	a4,-120(s0)
    8000614c:	97ba                	add	a5,a5,a4
    8000614e:	04fa7163          	bgeu	s4,a5,80006190 <sys_munmap+0x1d4>
      if (uvmgetdirty(p->pagetable, va) == 0) {
    80006152:	85d2                	mv	a1,s4
    80006154:	f7843783          	ld	a5,-136(s0)
    80006158:	6ba8                	ld	a0,80(a5)
    8000615a:	ffffb097          	auipc	ra,0xffffb
    8000615e:	6aa080e7          	jalr	1706(ra) # 80001804 <uvmgetdirty>
    80006162:	dd79                	beqz	a0,80006140 <sys_munmap+0x184>
      n = min(PGSIZE, addr + len - va);
    80006164:	f8442b83          	lw	s7,-124(s0)
    80006168:	f8843783          	ld	a5,-120(s0)
    8000616c:	9bbe                	add	s7,s7,a5
    8000616e:	414b8bb3          	sub	s7,s7,s4
    80006172:	6785                	lui	a5,0x1
    80006174:	0177f363          	bgeu	a5,s7,8000617a <sys_munmap+0x1be>
    80006178:	6b85                	lui	s7,0x1
    8000617a:	2b81                	sext.w	s7,s7
      for (i = 0; i < n; i += n1) {
    8000617c:	fc0b82e3          	beqz	s7,80006140 <sys_munmap+0x184>
    80006180:	4c01                	li	s8,0
    80006182:	4a81                	li	s5,0
        n1 = min(maxsz, n - i);
    80006184:	6785                	lui	a5,0x1
    80006186:	c007879b          	addiw	a5,a5,-1024
    8000618a:	f6f42a23          	sw	a5,-140(s0)
    8000618e:	bfb5                	j	8000610a <sys_munmap+0x14e>
  uvmunmap(p->pagetable, addr, (len - 1) / PGSIZE + 1, 1);
    80006190:	f8442603          	lw	a2,-124(s0)
    80006194:	fff6079b          	addiw	a5,a2,-1
    80006198:	41f7d61b          	sraiw	a2,a5,0x1f
    8000619c:	0146561b          	srliw	a2,a2,0x14
    800061a0:	9e3d                	addw	a2,a2,a5
    800061a2:	40c6561b          	sraiw	a2,a2,0xc
    800061a6:	4685                	li	a3,1
    800061a8:	2605                	addiw	a2,a2,1
    800061aa:	f8843583          	ld	a1,-120(s0)
    800061ae:	f7843903          	ld	s2,-136(s0)
    800061b2:	05093503          	ld	a0,80(s2)
    800061b6:	ffffb097          	auipc	ra,0xffffb
    800061ba:	0a4080e7          	jalr	164(ra) # 8000125a <uvmunmap>
  if (addr == vma->addr && len == vma->len) {
    800061be:	00549793          	slli	a5,s1,0x5
    800061c2:	97ca                	add	a5,a5,s2
    800061c4:	1687b703          	ld	a4,360(a5) # 1168 <_entry-0x7fffee98>
    800061c8:	f8843683          	ld	a3,-120(s0)
    800061cc:	00d70e63          	beq	a4,a3,800061e8 <sys_munmap+0x22c>
  } else if (addr + len == vma->addr + vma->len) {
    800061d0:	f8442583          	lw	a1,-124(s0)
    800061d4:	1707a603          	lw	a2,368(a5)
    800061d8:	96ae                	add	a3,a3,a1
    800061da:	9732                	add	a4,a4,a2
    800061dc:	06e69663          	bne	a3,a4,80006248 <sys_munmap+0x28c>
    vma->len -= len;
    800061e0:	9e0d                	subw	a2,a2,a1
    800061e2:	16c7a823          	sw	a2,368(a5)
    800061e6:	bd61                	j	8000607e <sys_munmap+0xc2>
  if (addr == vma->addr && len == vma->len) {
    800061e8:	f8442683          	lw	a3,-124(s0)
    800061ec:	1707a603          	lw	a2,368(a5)
    800061f0:	02d60563          	beq	a2,a3,8000621a <sys_munmap+0x25e>
    vma->addr += len;
    800061f4:	9736                	add	a4,a4,a3
    800061f6:	16e7b423          	sd	a4,360(a5)
    vma->offset += len;
    800061fa:	0496                	slli	s1,s1,0x5
    800061fc:	f7843703          	ld	a4,-136(s0)
    80006200:	94ba                	add	s1,s1,a4
    80006202:	17c4a703          	lw	a4,380(s1)
    80006206:	9f35                	addw	a4,a4,a3
    80006208:	16e4ae23          	sw	a4,380(s1)
    vma->len -= len;
    8000620c:	1707a703          	lw	a4,368(a5)
    80006210:	40d706bb          	subw	a3,a4,a3
    80006214:	16d7a823          	sw	a3,368(a5)
    80006218:	b59d                	j	8000607e <sys_munmap+0xc2>
    vma->addr = 0;
    8000621a:	1607b423          	sd	zero,360(a5)
    vma->len = 0;
    8000621e:	1607a823          	sw	zero,368(a5)
    vma->offset = 0;
    80006222:	0496                	slli	s1,s1,0x5
    80006224:	f7843703          	ld	a4,-136(s0)
    80006228:	94ba                	add	s1,s1,a4
    8000622a:	1604ae23          	sw	zero,380(s1)
    vma->flags = 0;
    8000622e:	1604ac23          	sw	zero,376(s1)
    vma->prot = 0;
    80006232:	1607aa23          	sw	zero,372(a5)
    fileclose(vma->f);
    80006236:	1804b503          	ld	a0,384(s1)
    8000623a:	ffffe097          	auipc	ra,0xffffe
    8000623e:	5e2080e7          	jalr	1506(ra) # 8000481c <fileclose>
    vma->f = 0;
    80006242:	1804b023          	sd	zero,384(s1)
    80006246:	bd25                	j	8000607e <sys_munmap+0xc2>
    panic("unexpected munmap");
    80006248:	00002517          	auipc	a0,0x2
    8000624c:	4f050513          	addi	a0,a0,1264 # 80008738 <syscalls+0x330>
    80006250:	ffffa097          	auipc	ra,0xffffa
    80006254:	2e0080e7          	jalr	736(ra) # 80000530 <panic>
    return -1;
    80006258:	5d7d                	li	s10,-1
    8000625a:	b515                	j	8000607e <sys_munmap+0xc2>
    8000625c:	5d7d                	li	s10,-1
    8000625e:	b505                	j	8000607e <sys_munmap+0xc2>
    return -1;
    80006260:	5d7d                	li	s10,-1
    80006262:	bd31                	j	8000607e <sys_munmap+0xc2>
    80006264:	5d7d                	li	s10,-1
    80006266:	bd21                	j	8000607e <sys_munmap+0xc2>
	...

0000000080006270 <kernelvec>:
    80006270:	7111                	addi	sp,sp,-256
    80006272:	e006                	sd	ra,0(sp)
    80006274:	e40a                	sd	sp,8(sp)
    80006276:	e80e                	sd	gp,16(sp)
    80006278:	ec12                	sd	tp,24(sp)
    8000627a:	f016                	sd	t0,32(sp)
    8000627c:	f41a                	sd	t1,40(sp)
    8000627e:	f81e                	sd	t2,48(sp)
    80006280:	fc22                	sd	s0,56(sp)
    80006282:	e0a6                	sd	s1,64(sp)
    80006284:	e4aa                	sd	a0,72(sp)
    80006286:	e8ae                	sd	a1,80(sp)
    80006288:	ecb2                	sd	a2,88(sp)
    8000628a:	f0b6                	sd	a3,96(sp)
    8000628c:	f4ba                	sd	a4,104(sp)
    8000628e:	f8be                	sd	a5,112(sp)
    80006290:	fcc2                	sd	a6,120(sp)
    80006292:	e146                	sd	a7,128(sp)
    80006294:	e54a                	sd	s2,136(sp)
    80006296:	e94e                	sd	s3,144(sp)
    80006298:	ed52                	sd	s4,152(sp)
    8000629a:	f156                	sd	s5,160(sp)
    8000629c:	f55a                	sd	s6,168(sp)
    8000629e:	f95e                	sd	s7,176(sp)
    800062a0:	fd62                	sd	s8,184(sp)
    800062a2:	e1e6                	sd	s9,192(sp)
    800062a4:	e5ea                	sd	s10,200(sp)
    800062a6:	e9ee                	sd	s11,208(sp)
    800062a8:	edf2                	sd	t3,216(sp)
    800062aa:	f1f6                	sd	t4,224(sp)
    800062ac:	f5fa                	sd	t5,232(sp)
    800062ae:	f9fe                	sd	t6,240(sp)
    800062b0:	987fc0ef          	jal	ra,80002c36 <kerneltrap>
    800062b4:	6082                	ld	ra,0(sp)
    800062b6:	6122                	ld	sp,8(sp)
    800062b8:	61c2                	ld	gp,16(sp)
    800062ba:	7282                	ld	t0,32(sp)
    800062bc:	7322                	ld	t1,40(sp)
    800062be:	73c2                	ld	t2,48(sp)
    800062c0:	7462                	ld	s0,56(sp)
    800062c2:	6486                	ld	s1,64(sp)
    800062c4:	6526                	ld	a0,72(sp)
    800062c6:	65c6                	ld	a1,80(sp)
    800062c8:	6666                	ld	a2,88(sp)
    800062ca:	7686                	ld	a3,96(sp)
    800062cc:	7726                	ld	a4,104(sp)
    800062ce:	77c6                	ld	a5,112(sp)
    800062d0:	7866                	ld	a6,120(sp)
    800062d2:	688a                	ld	a7,128(sp)
    800062d4:	692a                	ld	s2,136(sp)
    800062d6:	69ca                	ld	s3,144(sp)
    800062d8:	6a6a                	ld	s4,152(sp)
    800062da:	7a8a                	ld	s5,160(sp)
    800062dc:	7b2a                	ld	s6,168(sp)
    800062de:	7bca                	ld	s7,176(sp)
    800062e0:	7c6a                	ld	s8,184(sp)
    800062e2:	6c8e                	ld	s9,192(sp)
    800062e4:	6d2e                	ld	s10,200(sp)
    800062e6:	6dce                	ld	s11,208(sp)
    800062e8:	6e6e                	ld	t3,216(sp)
    800062ea:	7e8e                	ld	t4,224(sp)
    800062ec:	7f2e                	ld	t5,232(sp)
    800062ee:	7fce                	ld	t6,240(sp)
    800062f0:	6111                	addi	sp,sp,256
    800062f2:	10200073          	sret
    800062f6:	00000013          	nop
    800062fa:	00000013          	nop
    800062fe:	0001                	nop

0000000080006300 <timervec>:
    80006300:	34051573          	csrrw	a0,mscratch,a0
    80006304:	e10c                	sd	a1,0(a0)
    80006306:	e510                	sd	a2,8(a0)
    80006308:	e914                	sd	a3,16(a0)
    8000630a:	6d0c                	ld	a1,24(a0)
    8000630c:	7110                	ld	a2,32(a0)
    8000630e:	6194                	ld	a3,0(a1)
    80006310:	96b2                	add	a3,a3,a2
    80006312:	e194                	sd	a3,0(a1)
    80006314:	4589                	li	a1,2
    80006316:	14459073          	csrw	sip,a1
    8000631a:	6914                	ld	a3,16(a0)
    8000631c:	6510                	ld	a2,8(a0)
    8000631e:	610c                	ld	a1,0(a0)
    80006320:	34051573          	csrrw	a0,mscratch,a0
    80006324:	30200073          	mret
	...

000000008000632a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000632a:	1141                	addi	sp,sp,-16
    8000632c:	e422                	sd	s0,8(sp)
    8000632e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006330:	0c0007b7          	lui	a5,0xc000
    80006334:	4705                	li	a4,1
    80006336:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006338:	c3d8                	sw	a4,4(a5)
}
    8000633a:	6422                	ld	s0,8(sp)
    8000633c:	0141                	addi	sp,sp,16
    8000633e:	8082                	ret

0000000080006340 <plicinithart>:

void
plicinithart(void)
{
    80006340:	1141                	addi	sp,sp,-16
    80006342:	e406                	sd	ra,8(sp)
    80006344:	e022                	sd	s0,0(sp)
    80006346:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006348:	ffffb097          	auipc	ra,0xffffb
    8000634c:	680080e7          	jalr	1664(ra) # 800019c8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006350:	0085171b          	slliw	a4,a0,0x8
    80006354:	0c0027b7          	lui	a5,0xc002
    80006358:	97ba                	add	a5,a5,a4
    8000635a:	40200713          	li	a4,1026
    8000635e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006362:	00d5151b          	slliw	a0,a0,0xd
    80006366:	0c2017b7          	lui	a5,0xc201
    8000636a:	953e                	add	a0,a0,a5
    8000636c:	00052023          	sw	zero,0(a0)
}
    80006370:	60a2                	ld	ra,8(sp)
    80006372:	6402                	ld	s0,0(sp)
    80006374:	0141                	addi	sp,sp,16
    80006376:	8082                	ret

0000000080006378 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006378:	1141                	addi	sp,sp,-16
    8000637a:	e406                	sd	ra,8(sp)
    8000637c:	e022                	sd	s0,0(sp)
    8000637e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006380:	ffffb097          	auipc	ra,0xffffb
    80006384:	648080e7          	jalr	1608(ra) # 800019c8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006388:	00d5179b          	slliw	a5,a0,0xd
    8000638c:	0c201537          	lui	a0,0xc201
    80006390:	953e                	add	a0,a0,a5
  return irq;
}
    80006392:	4148                	lw	a0,4(a0)
    80006394:	60a2                	ld	ra,8(sp)
    80006396:	6402                	ld	s0,0(sp)
    80006398:	0141                	addi	sp,sp,16
    8000639a:	8082                	ret

000000008000639c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000639c:	1101                	addi	sp,sp,-32
    8000639e:	ec06                	sd	ra,24(sp)
    800063a0:	e822                	sd	s0,16(sp)
    800063a2:	e426                	sd	s1,8(sp)
    800063a4:	1000                	addi	s0,sp,32
    800063a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063a8:	ffffb097          	auipc	ra,0xffffb
    800063ac:	620080e7          	jalr	1568(ra) # 800019c8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063b0:	00d5151b          	slliw	a0,a0,0xd
    800063b4:	0c2017b7          	lui	a5,0xc201
    800063b8:	97aa                	add	a5,a5,a0
    800063ba:	c3c4                	sw	s1,4(a5)
}
    800063bc:	60e2                	ld	ra,24(sp)
    800063be:	6442                	ld	s0,16(sp)
    800063c0:	64a2                	ld	s1,8(sp)
    800063c2:	6105                	addi	sp,sp,32
    800063c4:	8082                	ret

00000000800063c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063c6:	1141                	addi	sp,sp,-16
    800063c8:	e406                	sd	ra,8(sp)
    800063ca:	e022                	sd	s0,0(sp)
    800063cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063ce:	479d                	li	a5,7
    800063d0:	06a7c963          	blt	a5,a0,80006442 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800063d4:	00025797          	auipc	a5,0x25
    800063d8:	c2c78793          	addi	a5,a5,-980 # 8002b000 <disk>
    800063dc:	00a78733          	add	a4,a5,a0
    800063e0:	6789                	lui	a5,0x2
    800063e2:	97ba                	add	a5,a5,a4
    800063e4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800063e8:	e7ad                	bnez	a5,80006452 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800063ea:	00451793          	slli	a5,a0,0x4
    800063ee:	00027717          	auipc	a4,0x27
    800063f2:	c1270713          	addi	a4,a4,-1006 # 8002d000 <disk+0x2000>
    800063f6:	6314                	ld	a3,0(a4)
    800063f8:	96be                	add	a3,a3,a5
    800063fa:	0006b023          	sd	zero,0(a3) # 2000000 <_entry-0x7e000000>
  disk.desc[i].len = 0;
    800063fe:	6314                	ld	a3,0(a4)
    80006400:	96be                	add	a3,a3,a5
    80006402:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006406:	6314                	ld	a3,0(a4)
    80006408:	96be                	add	a3,a3,a5
    8000640a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000640e:	6318                	ld	a4,0(a4)
    80006410:	97ba                	add	a5,a5,a4
    80006412:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006416:	00025797          	auipc	a5,0x25
    8000641a:	bea78793          	addi	a5,a5,-1046 # 8002b000 <disk>
    8000641e:	97aa                	add	a5,a5,a0
    80006420:	6509                	lui	a0,0x2
    80006422:	953e                	add	a0,a0,a5
    80006424:	4785                	li	a5,1
    80006426:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000642a:	00027517          	auipc	a0,0x27
    8000642e:	bee50513          	addi	a0,a0,-1042 # 8002d018 <disk+0x2018>
    80006432:	ffffc097          	auipc	ra,0xffffc
    80006436:	148080e7          	jalr	328(ra) # 8000257a <wakeup>
}
    8000643a:	60a2                	ld	ra,8(sp)
    8000643c:	6402                	ld	s0,0(sp)
    8000643e:	0141                	addi	sp,sp,16
    80006440:	8082                	ret
    panic("free_desc 1");
    80006442:	00002517          	auipc	a0,0x2
    80006446:	30e50513          	addi	a0,a0,782 # 80008750 <syscalls+0x348>
    8000644a:	ffffa097          	auipc	ra,0xffffa
    8000644e:	0e6080e7          	jalr	230(ra) # 80000530 <panic>
    panic("free_desc 2");
    80006452:	00002517          	auipc	a0,0x2
    80006456:	30e50513          	addi	a0,a0,782 # 80008760 <syscalls+0x358>
    8000645a:	ffffa097          	auipc	ra,0xffffa
    8000645e:	0d6080e7          	jalr	214(ra) # 80000530 <panic>

0000000080006462 <virtio_disk_init>:
{
    80006462:	1101                	addi	sp,sp,-32
    80006464:	ec06                	sd	ra,24(sp)
    80006466:	e822                	sd	s0,16(sp)
    80006468:	e426                	sd	s1,8(sp)
    8000646a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000646c:	00002597          	auipc	a1,0x2
    80006470:	30458593          	addi	a1,a1,772 # 80008770 <syscalls+0x368>
    80006474:	00027517          	auipc	a0,0x27
    80006478:	cb450513          	addi	a0,a0,-844 # 8002d128 <disk+0x2128>
    8000647c:	ffffa097          	auipc	ra,0xffffa
    80006480:	6ca080e7          	jalr	1738(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006484:	100017b7          	lui	a5,0x10001
    80006488:	4398                	lw	a4,0(a5)
    8000648a:	2701                	sext.w	a4,a4
    8000648c:	747277b7          	lui	a5,0x74727
    80006490:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006494:	0ef71163          	bne	a4,a5,80006576 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006498:	100017b7          	lui	a5,0x10001
    8000649c:	43dc                	lw	a5,4(a5)
    8000649e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064a0:	4705                	li	a4,1
    800064a2:	0ce79a63          	bne	a5,a4,80006576 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064a6:	100017b7          	lui	a5,0x10001
    800064aa:	479c                	lw	a5,8(a5)
    800064ac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064ae:	4709                	li	a4,2
    800064b0:	0ce79363          	bne	a5,a4,80006576 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064b4:	100017b7          	lui	a5,0x10001
    800064b8:	47d8                	lw	a4,12(a5)
    800064ba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064bc:	554d47b7          	lui	a5,0x554d4
    800064c0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064c4:	0af71963          	bne	a4,a5,80006576 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064c8:	100017b7          	lui	a5,0x10001
    800064cc:	4705                	li	a4,1
    800064ce:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064d0:	470d                	li	a4,3
    800064d2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064d4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800064d6:	c7ffe737          	lui	a4,0xc7ffe
    800064da:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd075f>
    800064de:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800064e0:	2701                	sext.w	a4,a4
    800064e2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064e4:	472d                	li	a4,11
    800064e6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064e8:	473d                	li	a4,15
    800064ea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800064ec:	6705                	lui	a4,0x1
    800064ee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800064f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800064f4:	5bdc                	lw	a5,52(a5)
    800064f6:	2781                	sext.w	a5,a5
  if(max == 0)
    800064f8:	c7d9                	beqz	a5,80006586 <virtio_disk_init+0x124>
  if(max < NUM)
    800064fa:	471d                	li	a4,7
    800064fc:	08f77d63          	bgeu	a4,a5,80006596 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006500:	100014b7          	lui	s1,0x10001
    80006504:	47a1                	li	a5,8
    80006506:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006508:	6609                	lui	a2,0x2
    8000650a:	4581                	li	a1,0
    8000650c:	00025517          	auipc	a0,0x25
    80006510:	af450513          	addi	a0,a0,-1292 # 8002b000 <disk>
    80006514:	ffffa097          	auipc	ra,0xffffa
    80006518:	7be080e7          	jalr	1982(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000651c:	00025717          	auipc	a4,0x25
    80006520:	ae470713          	addi	a4,a4,-1308 # 8002b000 <disk>
    80006524:	00c75793          	srli	a5,a4,0xc
    80006528:	2781                	sext.w	a5,a5
    8000652a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000652c:	00027797          	auipc	a5,0x27
    80006530:	ad478793          	addi	a5,a5,-1324 # 8002d000 <disk+0x2000>
    80006534:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006536:	00025717          	auipc	a4,0x25
    8000653a:	b4a70713          	addi	a4,a4,-1206 # 8002b080 <disk+0x80>
    8000653e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006540:	00026717          	auipc	a4,0x26
    80006544:	ac070713          	addi	a4,a4,-1344 # 8002c000 <disk+0x1000>
    80006548:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000654a:	4705                	li	a4,1
    8000654c:	00e78c23          	sb	a4,24(a5)
    80006550:	00e78ca3          	sb	a4,25(a5)
    80006554:	00e78d23          	sb	a4,26(a5)
    80006558:	00e78da3          	sb	a4,27(a5)
    8000655c:	00e78e23          	sb	a4,28(a5)
    80006560:	00e78ea3          	sb	a4,29(a5)
    80006564:	00e78f23          	sb	a4,30(a5)
    80006568:	00e78fa3          	sb	a4,31(a5)
}
    8000656c:	60e2                	ld	ra,24(sp)
    8000656e:	6442                	ld	s0,16(sp)
    80006570:	64a2                	ld	s1,8(sp)
    80006572:	6105                	addi	sp,sp,32
    80006574:	8082                	ret
    panic("could not find virtio disk");
    80006576:	00002517          	auipc	a0,0x2
    8000657a:	20a50513          	addi	a0,a0,522 # 80008780 <syscalls+0x378>
    8000657e:	ffffa097          	auipc	ra,0xffffa
    80006582:	fb2080e7          	jalr	-78(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    80006586:	00002517          	auipc	a0,0x2
    8000658a:	21a50513          	addi	a0,a0,538 # 800087a0 <syscalls+0x398>
    8000658e:	ffffa097          	auipc	ra,0xffffa
    80006592:	fa2080e7          	jalr	-94(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    80006596:	00002517          	auipc	a0,0x2
    8000659a:	22a50513          	addi	a0,a0,554 # 800087c0 <syscalls+0x3b8>
    8000659e:	ffffa097          	auipc	ra,0xffffa
    800065a2:	f92080e7          	jalr	-110(ra) # 80000530 <panic>

00000000800065a6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065a6:	7159                	addi	sp,sp,-112
    800065a8:	f486                	sd	ra,104(sp)
    800065aa:	f0a2                	sd	s0,96(sp)
    800065ac:	eca6                	sd	s1,88(sp)
    800065ae:	e8ca                	sd	s2,80(sp)
    800065b0:	e4ce                	sd	s3,72(sp)
    800065b2:	e0d2                	sd	s4,64(sp)
    800065b4:	fc56                	sd	s5,56(sp)
    800065b6:	f85a                	sd	s6,48(sp)
    800065b8:	f45e                	sd	s7,40(sp)
    800065ba:	f062                	sd	s8,32(sp)
    800065bc:	ec66                	sd	s9,24(sp)
    800065be:	e86a                	sd	s10,16(sp)
    800065c0:	1880                	addi	s0,sp,112
    800065c2:	892a                	mv	s2,a0
    800065c4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065c6:	00c52c83          	lw	s9,12(a0)
    800065ca:	001c9c9b          	slliw	s9,s9,0x1
    800065ce:	1c82                	slli	s9,s9,0x20
    800065d0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800065d4:	00027517          	auipc	a0,0x27
    800065d8:	b5450513          	addi	a0,a0,-1196 # 8002d128 <disk+0x2128>
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	5fa080e7          	jalr	1530(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800065e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800065e6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800065e8:	00025b97          	auipc	s7,0x25
    800065ec:	a18b8b93          	addi	s7,s7,-1512 # 8002b000 <disk>
    800065f0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800065f2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800065f4:	8a4e                	mv	s4,s3
    800065f6:	a051                	j	8000667a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800065f8:	00fb86b3          	add	a3,s7,a5
    800065fc:	96da                	add	a3,a3,s6
    800065fe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006602:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006604:	0207c563          	bltz	a5,8000662e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006608:	2485                	addiw	s1,s1,1
    8000660a:	0711                	addi	a4,a4,4
    8000660c:	25548063          	beq	s1,s5,8000684c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006610:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006612:	00027697          	auipc	a3,0x27
    80006616:	a0668693          	addi	a3,a3,-1530 # 8002d018 <disk+0x2018>
    8000661a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000661c:	0006c583          	lbu	a1,0(a3)
    80006620:	fde1                	bnez	a1,800065f8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006622:	2785                	addiw	a5,a5,1
    80006624:	0685                	addi	a3,a3,1
    80006626:	ff879be3          	bne	a5,s8,8000661c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000662a:	57fd                	li	a5,-1
    8000662c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000662e:	02905a63          	blez	s1,80006662 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006632:	f9042503          	lw	a0,-112(s0)
    80006636:	00000097          	auipc	ra,0x0
    8000663a:	d90080e7          	jalr	-624(ra) # 800063c6 <free_desc>
      for(int j = 0; j < i; j++)
    8000663e:	4785                	li	a5,1
    80006640:	0297d163          	bge	a5,s1,80006662 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006644:	f9442503          	lw	a0,-108(s0)
    80006648:	00000097          	auipc	ra,0x0
    8000664c:	d7e080e7          	jalr	-642(ra) # 800063c6 <free_desc>
      for(int j = 0; j < i; j++)
    80006650:	4789                	li	a5,2
    80006652:	0097d863          	bge	a5,s1,80006662 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006656:	f9842503          	lw	a0,-104(s0)
    8000665a:	00000097          	auipc	ra,0x0
    8000665e:	d6c080e7          	jalr	-660(ra) # 800063c6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006662:	00027597          	auipc	a1,0x27
    80006666:	ac658593          	addi	a1,a1,-1338 # 8002d128 <disk+0x2128>
    8000666a:	00027517          	auipc	a0,0x27
    8000666e:	9ae50513          	addi	a0,a0,-1618 # 8002d018 <disk+0x2018>
    80006672:	ffffc097          	auipc	ra,0xffffc
    80006676:	d82080e7          	jalr	-638(ra) # 800023f4 <sleep>
  for(int i = 0; i < 3; i++){
    8000667a:	f9040713          	addi	a4,s0,-112
    8000667e:	84ce                	mv	s1,s3
    80006680:	bf41                	j	80006610 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006682:	20058713          	addi	a4,a1,512
    80006686:	00471693          	slli	a3,a4,0x4
    8000668a:	00025717          	auipc	a4,0x25
    8000668e:	97670713          	addi	a4,a4,-1674 # 8002b000 <disk>
    80006692:	9736                	add	a4,a4,a3
    80006694:	4685                	li	a3,1
    80006696:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000669a:	20058713          	addi	a4,a1,512
    8000669e:	00471693          	slli	a3,a4,0x4
    800066a2:	00025717          	auipc	a4,0x25
    800066a6:	95e70713          	addi	a4,a4,-1698 # 8002b000 <disk>
    800066aa:	9736                	add	a4,a4,a3
    800066ac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800066b0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066b4:	7679                	lui	a2,0xffffe
    800066b6:	963e                	add	a2,a2,a5
    800066b8:	00027697          	auipc	a3,0x27
    800066bc:	94868693          	addi	a3,a3,-1720 # 8002d000 <disk+0x2000>
    800066c0:	6298                	ld	a4,0(a3)
    800066c2:	9732                	add	a4,a4,a2
    800066c4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066c6:	6298                	ld	a4,0(a3)
    800066c8:	9732                	add	a4,a4,a2
    800066ca:	4541                	li	a0,16
    800066cc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066ce:	6298                	ld	a4,0(a3)
    800066d0:	9732                	add	a4,a4,a2
    800066d2:	4505                	li	a0,1
    800066d4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800066d8:	f9442703          	lw	a4,-108(s0)
    800066dc:	6288                	ld	a0,0(a3)
    800066de:	962a                	add	a2,a2,a0
    800066e0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd000e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800066e4:	0712                	slli	a4,a4,0x4
    800066e6:	6290                	ld	a2,0(a3)
    800066e8:	963a                	add	a2,a2,a4
    800066ea:	05890513          	addi	a0,s2,88
    800066ee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800066f0:	6294                	ld	a3,0(a3)
    800066f2:	96ba                	add	a3,a3,a4
    800066f4:	40000613          	li	a2,1024
    800066f8:	c690                	sw	a2,8(a3)
  if(write)
    800066fa:	140d0063          	beqz	s10,8000683a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800066fe:	00027697          	auipc	a3,0x27
    80006702:	9026b683          	ld	a3,-1790(a3) # 8002d000 <disk+0x2000>
    80006706:	96ba                	add	a3,a3,a4
    80006708:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000670c:	00025817          	auipc	a6,0x25
    80006710:	8f480813          	addi	a6,a6,-1804 # 8002b000 <disk>
    80006714:	00027517          	auipc	a0,0x27
    80006718:	8ec50513          	addi	a0,a0,-1812 # 8002d000 <disk+0x2000>
    8000671c:	6114                	ld	a3,0(a0)
    8000671e:	96ba                	add	a3,a3,a4
    80006720:	00c6d603          	lhu	a2,12(a3)
    80006724:	00166613          	ori	a2,a2,1
    80006728:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000672c:	f9842683          	lw	a3,-104(s0)
    80006730:	6110                	ld	a2,0(a0)
    80006732:	9732                	add	a4,a4,a2
    80006734:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006738:	20058613          	addi	a2,a1,512
    8000673c:	0612                	slli	a2,a2,0x4
    8000673e:	9642                	add	a2,a2,a6
    80006740:	577d                	li	a4,-1
    80006742:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006746:	00469713          	slli	a4,a3,0x4
    8000674a:	6114                	ld	a3,0(a0)
    8000674c:	96ba                	add	a3,a3,a4
    8000674e:	03078793          	addi	a5,a5,48
    80006752:	97c2                	add	a5,a5,a6
    80006754:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006756:	611c                	ld	a5,0(a0)
    80006758:	97ba                	add	a5,a5,a4
    8000675a:	4685                	li	a3,1
    8000675c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000675e:	611c                	ld	a5,0(a0)
    80006760:	97ba                	add	a5,a5,a4
    80006762:	4809                	li	a6,2
    80006764:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006768:	611c                	ld	a5,0(a0)
    8000676a:	973e                	add	a4,a4,a5
    8000676c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006770:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006774:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006778:	6518                	ld	a4,8(a0)
    8000677a:	00275783          	lhu	a5,2(a4)
    8000677e:	8b9d                	andi	a5,a5,7
    80006780:	0786                	slli	a5,a5,0x1
    80006782:	97ba                	add	a5,a5,a4
    80006784:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006788:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000678c:	6518                	ld	a4,8(a0)
    8000678e:	00275783          	lhu	a5,2(a4)
    80006792:	2785                	addiw	a5,a5,1
    80006794:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006798:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000679c:	100017b7          	lui	a5,0x10001
    800067a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067a4:	00492703          	lw	a4,4(s2)
    800067a8:	4785                	li	a5,1
    800067aa:	02f71163          	bne	a4,a5,800067cc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800067ae:	00027997          	auipc	s3,0x27
    800067b2:	97a98993          	addi	s3,s3,-1670 # 8002d128 <disk+0x2128>
  while(b->disk == 1) {
    800067b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067b8:	85ce                	mv	a1,s3
    800067ba:	854a                	mv	a0,s2
    800067bc:	ffffc097          	auipc	ra,0xffffc
    800067c0:	c38080e7          	jalr	-968(ra) # 800023f4 <sleep>
  while(b->disk == 1) {
    800067c4:	00492783          	lw	a5,4(s2)
    800067c8:	fe9788e3          	beq	a5,s1,800067b8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800067cc:	f9042903          	lw	s2,-112(s0)
    800067d0:	20090793          	addi	a5,s2,512
    800067d4:	00479713          	slli	a4,a5,0x4
    800067d8:	00025797          	auipc	a5,0x25
    800067dc:	82878793          	addi	a5,a5,-2008 # 8002b000 <disk>
    800067e0:	97ba                	add	a5,a5,a4
    800067e2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800067e6:	00027997          	auipc	s3,0x27
    800067ea:	81a98993          	addi	s3,s3,-2022 # 8002d000 <disk+0x2000>
    800067ee:	00491713          	slli	a4,s2,0x4
    800067f2:	0009b783          	ld	a5,0(s3)
    800067f6:	97ba                	add	a5,a5,a4
    800067f8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800067fc:	854a                	mv	a0,s2
    800067fe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006802:	00000097          	auipc	ra,0x0
    80006806:	bc4080e7          	jalr	-1084(ra) # 800063c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000680a:	8885                	andi	s1,s1,1
    8000680c:	f0ed                	bnez	s1,800067ee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000680e:	00027517          	auipc	a0,0x27
    80006812:	91a50513          	addi	a0,a0,-1766 # 8002d128 <disk+0x2128>
    80006816:	ffffa097          	auipc	ra,0xffffa
    8000681a:	474080e7          	jalr	1140(ra) # 80000c8a <release>
}
    8000681e:	70a6                	ld	ra,104(sp)
    80006820:	7406                	ld	s0,96(sp)
    80006822:	64e6                	ld	s1,88(sp)
    80006824:	6946                	ld	s2,80(sp)
    80006826:	69a6                	ld	s3,72(sp)
    80006828:	6a06                	ld	s4,64(sp)
    8000682a:	7ae2                	ld	s5,56(sp)
    8000682c:	7b42                	ld	s6,48(sp)
    8000682e:	7ba2                	ld	s7,40(sp)
    80006830:	7c02                	ld	s8,32(sp)
    80006832:	6ce2                	ld	s9,24(sp)
    80006834:	6d42                	ld	s10,16(sp)
    80006836:	6165                	addi	sp,sp,112
    80006838:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000683a:	00026697          	auipc	a3,0x26
    8000683e:	7c66b683          	ld	a3,1990(a3) # 8002d000 <disk+0x2000>
    80006842:	96ba                	add	a3,a3,a4
    80006844:	4609                	li	a2,2
    80006846:	00c69623          	sh	a2,12(a3)
    8000684a:	b5c9                	j	8000670c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000684c:	f9042583          	lw	a1,-112(s0)
    80006850:	20058793          	addi	a5,a1,512
    80006854:	0792                	slli	a5,a5,0x4
    80006856:	00025517          	auipc	a0,0x25
    8000685a:	85250513          	addi	a0,a0,-1966 # 8002b0a8 <disk+0xa8>
    8000685e:	953e                	add	a0,a0,a5
  if(write)
    80006860:	e20d11e3          	bnez	s10,80006682 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006864:	20058713          	addi	a4,a1,512
    80006868:	00471693          	slli	a3,a4,0x4
    8000686c:	00024717          	auipc	a4,0x24
    80006870:	79470713          	addi	a4,a4,1940 # 8002b000 <disk>
    80006874:	9736                	add	a4,a4,a3
    80006876:	0a072423          	sw	zero,168(a4)
    8000687a:	b505                	j	8000669a <virtio_disk_rw+0xf4>

000000008000687c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000687c:	1101                	addi	sp,sp,-32
    8000687e:	ec06                	sd	ra,24(sp)
    80006880:	e822                	sd	s0,16(sp)
    80006882:	e426                	sd	s1,8(sp)
    80006884:	e04a                	sd	s2,0(sp)
    80006886:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006888:	00027517          	auipc	a0,0x27
    8000688c:	8a050513          	addi	a0,a0,-1888 # 8002d128 <disk+0x2128>
    80006890:	ffffa097          	auipc	ra,0xffffa
    80006894:	346080e7          	jalr	838(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006898:	10001737          	lui	a4,0x10001
    8000689c:	533c                	lw	a5,96(a4)
    8000689e:	8b8d                	andi	a5,a5,3
    800068a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068a6:	00026797          	auipc	a5,0x26
    800068aa:	75a78793          	addi	a5,a5,1882 # 8002d000 <disk+0x2000>
    800068ae:	6b94                	ld	a3,16(a5)
    800068b0:	0207d703          	lhu	a4,32(a5)
    800068b4:	0026d783          	lhu	a5,2(a3)
    800068b8:	06f70163          	beq	a4,a5,8000691a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068bc:	00024917          	auipc	s2,0x24
    800068c0:	74490913          	addi	s2,s2,1860 # 8002b000 <disk>
    800068c4:	00026497          	auipc	s1,0x26
    800068c8:	73c48493          	addi	s1,s1,1852 # 8002d000 <disk+0x2000>
    __sync_synchronize();
    800068cc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068d0:	6898                	ld	a4,16(s1)
    800068d2:	0204d783          	lhu	a5,32(s1)
    800068d6:	8b9d                	andi	a5,a5,7
    800068d8:	078e                	slli	a5,a5,0x3
    800068da:	97ba                	add	a5,a5,a4
    800068dc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068de:	20078713          	addi	a4,a5,512
    800068e2:	0712                	slli	a4,a4,0x4
    800068e4:	974a                	add	a4,a4,s2
    800068e6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800068ea:	e731                	bnez	a4,80006936 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800068ec:	20078793          	addi	a5,a5,512
    800068f0:	0792                	slli	a5,a5,0x4
    800068f2:	97ca                	add	a5,a5,s2
    800068f4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800068f6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800068fa:	ffffc097          	auipc	ra,0xffffc
    800068fe:	c80080e7          	jalr	-896(ra) # 8000257a <wakeup>

    disk.used_idx += 1;
    80006902:	0204d783          	lhu	a5,32(s1)
    80006906:	2785                	addiw	a5,a5,1
    80006908:	17c2                	slli	a5,a5,0x30
    8000690a:	93c1                	srli	a5,a5,0x30
    8000690c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006910:	6898                	ld	a4,16(s1)
    80006912:	00275703          	lhu	a4,2(a4)
    80006916:	faf71be3          	bne	a4,a5,800068cc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000691a:	00027517          	auipc	a0,0x27
    8000691e:	80e50513          	addi	a0,a0,-2034 # 8002d128 <disk+0x2128>
    80006922:	ffffa097          	auipc	ra,0xffffa
    80006926:	368080e7          	jalr	872(ra) # 80000c8a <release>
}
    8000692a:	60e2                	ld	ra,24(sp)
    8000692c:	6442                	ld	s0,16(sp)
    8000692e:	64a2                	ld	s1,8(sp)
    80006930:	6902                	ld	s2,0(sp)
    80006932:	6105                	addi	sp,sp,32
    80006934:	8082                	ret
      panic("virtio_disk_intr status");
    80006936:	00002517          	auipc	a0,0x2
    8000693a:	eaa50513          	addi	a0,a0,-342 # 800087e0 <syscalls+0x3d8>
    8000693e:	ffffa097          	auipc	ra,0xffffa
    80006942:	bf2080e7          	jalr	-1038(ra) # 80000530 <panic>
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
