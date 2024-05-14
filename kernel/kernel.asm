
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000056:	8be70713          	addi	a4,a4,-1858 # 80008910 <timer_scratch>
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
    80000068:	bac78793          	addi	a5,a5,-1108 # 80005c10 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc9d7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
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
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	39c080e7          	jalr	924(ra) # 800024c8 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	8c450513          	addi	a0,a0,-1852 # 80010a50 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	8b448493          	addi	s1,s1,-1868 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	94290913          	addi	s2,s2,-1726 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	146080e7          	jalr	326(ra) # 80002312 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	e90080e7          	jalr	-368(ra) # 8000206a <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	25c080e7          	jalr	604(ra) # 80002472 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	82650513          	addi	a0,a0,-2010 # 80010a50 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	81050513          	addi	a0,a0,-2032 # 80010a50 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	86f72823          	sw	a5,-1936(a4) # 80010ae8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00010517          	auipc	a0,0x10
    800002d6:	77e50513          	addi	a0,a0,1918 # 80010a50 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	226080e7          	jalr	550(ra) # 8000251e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	75050513          	addi	a0,a0,1872 # 80010a50 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00010717          	auipc	a4,0x10
    80000328:	72c70713          	addi	a4,a4,1836 # 80010a50 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00010797          	auipc	a5,0x10
    80000352:	70278793          	addi	a5,a5,1794 # 80010a50 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00010797          	auipc	a5,0x10
    80000380:	76c7a783          	lw	a5,1900(a5) # 80010ae8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	6c070713          	addi	a4,a4,1728 # 80010a50 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	6b048493          	addi	s1,s1,1712 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	67470713          	addi	a4,a4,1652 # 80010a50 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	6ef72f23          	sw	a5,1790(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	63878793          	addi	a5,a5,1592 # 80010a50 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00010797          	auipc	a5,0x10
    80000440:	6ac7a823          	sw	a2,1712(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	6a450513          	addi	a0,a0,1700 # 80010ae8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	c82080e7          	jalr	-894(ra) # 800020ce <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	5ea50513          	addi	a0,a0,1514 # 80010a50 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	81278793          	addi	a5,a5,-2030 # 80020c90 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	5c07a023          	sw	zero,1472(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	34f72623          	sw	a5,844(a4) # 800088d0 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	550dad83          	lw	s11,1360(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	4fa50513          	addi	a0,a0,1274 # 80010af8 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	39650513          	addi	a0,a0,918 # 80010af8 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	37a48493          	addi	s1,s1,890 # 80010af8 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	33a50513          	addi	a0,a0,826 # 80010b18 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	0c67a783          	lw	a5,198(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	09273703          	ld	a4,146(a4) # 800088d8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0927b783          	ld	a5,146(a5) # 800088e0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	2a8a0a13          	addi	s4,s4,680 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	06048493          	addi	s1,s1,96 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	06098993          	addi	s3,s3,96 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	828080e7          	jalr	-2008(ra) # 800020ce <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	23650513          	addi	a0,a0,566 # 80010b18 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fde7a783          	lw	a5,-34(a5) # 800088d0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	fe47b783          	ld	a5,-28(a5) # 800088e0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	fd473703          	ld	a4,-44(a4) # 800088d8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	208a0a13          	addi	s4,s4,520 # 80010b18 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	fc048493          	addi	s1,s1,-64 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	fc090913          	addi	s2,s2,-64 # 800088e0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	73a080e7          	jalr	1850(ra) # 8000206a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	1d248493          	addi	s1,s1,466 # 80010b18 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	f8f73323          	sd	a5,-122(a4) # 800088e0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	14848493          	addi	s1,s1,328 # 80010b18 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00021797          	auipc	a5,0x21
    80000a16:	41678793          	addi	a5,a5,1046 # 80021e28 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	11e90913          	addi	s2,s2,286 # 80010b50 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	08250513          	addi	a0,a0,130 # 80010b50 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	34650513          	addi	a0,a0,838 # 80021e28 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	04c48493          	addi	s1,s1,76 # 80010b50 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	03450513          	addi	a0,a0,52 # 80010b50 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	00850513          	addi	a0,a0,8 # 80010b50 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	a4470713          	addi	a4,a4,-1468 # 800088e8 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	784080e7          	jalr	1924(ra) # 8000265e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	d6e080e7          	jalr	-658(ra) # 80005c50 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	fce080e7          	jalr	-50(ra) # 80001eb8 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00001097          	auipc	ra,0x1
    80000f56:	6e4080e7          	jalr	1764(ra) # 80002636 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	704080e7          	jalr	1796(ra) # 8000265e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	cd8080e7          	jalr	-808(ra) # 80005c3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	ce6080e7          	jalr	-794(ra) # 80005c50 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	e9c080e7          	jalr	-356(ra) # 80002e0e <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	540080e7          	jalr	1344(ra) # 800034ba <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	4de080e7          	jalr	1246(ra) # 80004460 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	dce080e7          	jalr	-562(ra) # 80005d58 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d0c080e7          	jalr	-756(ra) # 80001c9e <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	94f72423          	sw	a5,-1720(a4) # 800088e8 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	93c7b783          	ld	a5,-1732(a5) # 800088f0 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00007797          	auipc	a5,0x7
    80001274:	68a7b023          	sd	a0,1664(a5) # 800088f0 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
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
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	0000f497          	auipc	s1,0xf
    8000186a:	73a48493          	addi	s1,s1,1850 # 80010fa0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001880:	00015a17          	auipc	s4,0x15
    80001884:	120a0a13          	addi	s4,s4,288 # 800169a0 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if(pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ba:	16848493          	addi	s1,s1,360
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	26e50513          	addi	a0,a0,622 # 80010b70 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	26e50513          	addi	a0,a0,622 # 80010b88 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	0000f497          	auipc	s1,0xf
    8000192e:	67648493          	addi	s1,s1,1654 # 80010fa0 <proc>
      initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	00015997          	auipc	s3,0x15
    80001950:	05498993          	addi	s3,s3,84 # 800169a0 <tickslock>
      initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	878d                	srai	a5,a5,0x3
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	16848493          	addi	s1,s1,360
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	1ea50513          	addi	a0,a0,490 # 80010ba0 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	19270713          	addi	a4,a4,402 # 80010b70 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first) {
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e4a7a783          	lw	a5,-438(a5) # 80008860 <first.1678>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	c56080e7          	jalr	-938(ra) # 80002676 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	e207a823          	sw	zero,-464(a5) # 80008860 <first.1678>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	a00080e7          	jalr	-1536(ra) # 8000343a <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	12090913          	addi	s2,s2,288 # 80010b70 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	e0278793          	addi	a5,a5,-510 # 80008864 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	05893683          	ld	a3,88(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b84:	6d28                	ld	a0,88(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b90:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b94:	68a8                	ld	a0,80(s1)
    80001b96:	c511                	beqz	a0,80001ba2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b98:	64ac                	ld	a1,72(s1)
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	f8c080e7          	jalr	-116(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001ba2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001baa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bae:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bbe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc2:	0004ac23          	sw	zero,24(s1)
}
    80001bc6:	60e2                	ld	ra,24(sp)
    80001bc8:	6442                	ld	s0,16(sp)
    80001bca:	64a2                	ld	s1,8(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret

0000000080001bd0 <allocproc>:
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	e04a                	sd	s2,0(sp)
    80001bda:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bdc:	0000f497          	auipc	s1,0xf
    80001be0:	3c448493          	addi	s1,s1,964 # 80010fa0 <proc>
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	dbc90913          	addi	s2,s2,-580 # 800169a0 <tickslock>
    acquire(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ffc080e7          	jalr	-4(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001bf6:	4c9c                	lw	a5,24(s1)
    80001bf8:	cf81                	beqz	a5,80001c10 <allocproc+0x40>
      release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0a2080e7          	jalr	162(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c04:	16848493          	addi	s1,s1,360
    80001c08:	ff2492e3          	bne	s1,s2,80001bec <allocproc+0x1c>
  return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	a889                	j	80001c60 <allocproc+0x90>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	edc080e7          	jalr	-292(ra) # 80000afa <kalloc>
    80001c26:	892a                	mv	s2,a0
    80001c28:	eca8                	sd	a0,88(s1)
    80001c2a:	c131                	beqz	a0,80001c6e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	e5c080e7          	jalr	-420(ra) # 80001a8a <proc_pagetable>
    80001c36:	892a                	mv	s2,a0
    80001c38:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c3a:	c531                	beqz	a0,80001c86 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c3c:	07000613          	li	a2,112
    80001c40:	4581                	li	a1,0
    80001c42:	06048513          	addi	a0,s1,96
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	0a0080e7          	jalr	160(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c4e:	00000797          	auipc	a5,0x0
    80001c52:	db078793          	addi	a5,a5,-592 # 800019fe <forkret>
    80001c56:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c58:	60bc                	ld	a5,64(s1)
    80001c5a:	6705                	lui	a4,0x1
    80001c5c:	97ba                	add	a5,a5,a4
    80001c5e:	f4bc                	sd	a5,104(s1)
}
    80001c60:	8526                	mv	a0,s1
    80001c62:	60e2                	ld	ra,24(sp)
    80001c64:	6442                	ld	s0,16(sp)
    80001c66:	64a2                	ld	s1,8(sp)
    80001c68:	6902                	ld	s2,0(sp)
    80001c6a:	6105                	addi	sp,sp,32
    80001c6c:	8082                	ret
    freeproc(p);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	00000097          	auipc	ra,0x0
    80001c74:	f08080e7          	jalr	-248(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	024080e7          	jalr	36(ra) # 80000c9e <release>
    return 0;
    80001c82:	84ca                	mv	s1,s2
    80001c84:	bff1                	j	80001c60 <allocproc+0x90>
    freeproc(p);
    80001c86:	8526                	mv	a0,s1
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	ef0080e7          	jalr	-272(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	00c080e7          	jalr	12(ra) # 80000c9e <release>
    return 0;
    80001c9a:	84ca                	mv	s1,s2
    80001c9c:	b7d1                	j	80001c60 <allocproc+0x90>

0000000080001c9e <userinit>:
{
    80001c9e:	1101                	addi	sp,sp,-32
    80001ca0:	ec06                	sd	ra,24(sp)
    80001ca2:	e822                	sd	s0,16(sp)
    80001ca4:	e426                	sd	s1,8(sp)
    80001ca6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	f28080e7          	jalr	-216(ra) # 80001bd0 <allocproc>
    80001cb0:	84aa                	mv	s1,a0
  initproc = p;
    80001cb2:	00007797          	auipc	a5,0x7
    80001cb6:	c4a7b323          	sd	a0,-954(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cba:	03400613          	li	a2,52
    80001cbe:	00007597          	auipc	a1,0x7
    80001cc2:	bb258593          	addi	a1,a1,-1102 # 80008870 <initcode>
    80001cc6:	6928                	ld	a0,80(a0)
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	6aa080e7          	jalr	1706(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001cd0:	6785                	lui	a5,0x1
    80001cd2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cda:	6cb8                	ld	a4,88(s1)
    80001cdc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cde:	4641                	li	a2,16
    80001ce0:	00006597          	auipc	a1,0x6
    80001ce4:	52058593          	addi	a1,a1,1312 # 80008200 <digits+0x1c0>
    80001ce8:	15848513          	addi	a0,s1,344
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	14c080e7          	jalr	332(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001cf4:	00006517          	auipc	a0,0x6
    80001cf8:	51c50513          	addi	a0,a0,1308 # 80008210 <digits+0x1d0>
    80001cfc:	00002097          	auipc	ra,0x2
    80001d00:	160080e7          	jalr	352(ra) # 80003e5c <namei>
    80001d04:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d08:	478d                	li	a5,3
    80001d0a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	f90080e7          	jalr	-112(ra) # 80000c9e <release>
}
    80001d16:	60e2                	ld	ra,24(sp)
    80001d18:	6442                	ld	s0,16(sp)
    80001d1a:	64a2                	ld	s1,8(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret

0000000080001d20 <growproc>:
{
    80001d20:	1101                	addi	sp,sp,-32
    80001d22:	ec06                	sd	ra,24(sp)
    80001d24:	e822                	sd	s0,16(sp)
    80001d26:	e426                	sd	s1,8(sp)
    80001d28:	e04a                	sd	s2,0(sp)
    80001d2a:	1000                	addi	s0,sp,32
    80001d2c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d2e:	00000097          	auipc	ra,0x0
    80001d32:	c98080e7          	jalr	-872(ra) # 800019c6 <myproc>
    80001d36:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d38:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d3a:	01204c63          	bgtz	s2,80001d52 <growproc+0x32>
  } else if(n < 0){
    80001d3e:	02094663          	bltz	s2,80001d6a <growproc+0x4a>
  p->sz = sz;
    80001d42:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d44:	4501                	li	a0,0
}
    80001d46:	60e2                	ld	ra,24(sp)
    80001d48:	6442                	ld	s0,16(sp)
    80001d4a:	64a2                	ld	s1,8(sp)
    80001d4c:	6902                	ld	s2,0(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d52:	4691                	li	a3,4
    80001d54:	00b90633          	add	a2,s2,a1
    80001d58:	6928                	ld	a0,80(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	6d2080e7          	jalr	1746(ra) # 8000142c <uvmalloc>
    80001d62:	85aa                	mv	a1,a0
    80001d64:	fd79                	bnez	a0,80001d42 <growproc+0x22>
      return -1;
    80001d66:	557d                	li	a0,-1
    80001d68:	bff9                	j	80001d46 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d6a:	00b90633          	add	a2,s2,a1
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	674080e7          	jalr	1652(ra) # 800013e4 <uvmdealloc>
    80001d78:	85aa                	mv	a1,a0
    80001d7a:	b7e1                	j	80001d42 <growproc+0x22>

0000000080001d7c <fork>:
{
    80001d7c:	7179                	addi	sp,sp,-48
    80001d7e:	f406                	sd	ra,40(sp)
    80001d80:	f022                	sd	s0,32(sp)
    80001d82:	ec26                	sd	s1,24(sp)
    80001d84:	e84a                	sd	s2,16(sp)
    80001d86:	e44e                	sd	s3,8(sp)
    80001d88:	e052                	sd	s4,0(sp)
    80001d8a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	c3a080e7          	jalr	-966(ra) # 800019c6 <myproc>
    80001d94:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	e3a080e7          	jalr	-454(ra) # 80001bd0 <allocproc>
    80001d9e:	10050b63          	beqz	a0,80001eb4 <fork+0x138>
    80001da2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da4:	04893603          	ld	a2,72(s2)
    80001da8:	692c                	ld	a1,80(a0)
    80001daa:	05093503          	ld	a0,80(s2)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	7d2080e7          	jalr	2002(ra) # 80001580 <uvmcopy>
    80001db6:	04054663          	bltz	a0,80001e02 <fork+0x86>
  np->sz = p->sz;
    80001dba:	04893783          	ld	a5,72(s2)
    80001dbe:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc2:	05893683          	ld	a3,88(s2)
    80001dc6:	87b6                	mv	a5,a3
    80001dc8:	0589b703          	ld	a4,88(s3)
    80001dcc:	12068693          	addi	a3,a3,288
    80001dd0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd4:	6788                	ld	a0,8(a5)
    80001dd6:	6b8c                	ld	a1,16(a5)
    80001dd8:	6f90                	ld	a2,24(a5)
    80001dda:	01073023          	sd	a6,0(a4)
    80001dde:	e708                	sd	a0,8(a4)
    80001de0:	eb0c                	sd	a1,16(a4)
    80001de2:	ef10                	sd	a2,24(a4)
    80001de4:	02078793          	addi	a5,a5,32
    80001de8:	02070713          	addi	a4,a4,32
    80001dec:	fed792e3          	bne	a5,a3,80001dd0 <fork+0x54>
  np->trapframe->a0 = 0;
    80001df0:	0589b783          	ld	a5,88(s3)
    80001df4:	0607b823          	sd	zero,112(a5)
    80001df8:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dfc:	15000a13          	li	s4,336
    80001e00:	a03d                	j	80001e2e <fork+0xb2>
    freeproc(np);
    80001e02:	854e                	mv	a0,s3
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	d74080e7          	jalr	-652(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e0c:	854e                	mv	a0,s3
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	e90080e7          	jalr	-368(ra) # 80000c9e <release>
    return -1;
    80001e16:	5a7d                	li	s4,-1
    80001e18:	a069                	j	80001ea2 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1a:	00002097          	auipc	ra,0x2
    80001e1e:	6d8080e7          	jalr	1752(ra) # 800044f2 <filedup>
    80001e22:	009987b3          	add	a5,s3,s1
    80001e26:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e28:	04a1                	addi	s1,s1,8
    80001e2a:	01448763          	beq	s1,s4,80001e38 <fork+0xbc>
    if(p->ofile[i])
    80001e2e:	009907b3          	add	a5,s2,s1
    80001e32:	6388                	ld	a0,0(a5)
    80001e34:	f17d                	bnez	a0,80001e1a <fork+0x9e>
    80001e36:	bfcd                	j	80001e28 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e38:	15093503          	ld	a0,336(s2)
    80001e3c:	00002097          	auipc	ra,0x2
    80001e40:	83c080e7          	jalr	-1988(ra) # 80003678 <idup>
    80001e44:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e48:	4641                	li	a2,16
    80001e4a:	15890593          	addi	a1,s2,344
    80001e4e:	15898513          	addi	a0,s3,344
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	fe6080e7          	jalr	-26(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e5a:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e5e:	854e                	mv	a0,s3
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	e3e080e7          	jalr	-450(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e68:	0000f497          	auipc	s1,0xf
    80001e6c:	d2048493          	addi	s1,s1,-736 # 80010b88 <wait_lock>
    80001e70:	8526                	mv	a0,s1
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d78080e7          	jalr	-648(ra) # 80000bea <acquire>
  np->parent = p;
    80001e7a:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e7e:	8526                	mv	a0,s1
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	e1e080e7          	jalr	-482(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001e88:	854e                	mv	a0,s3
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	d60080e7          	jalr	-672(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001e92:	478d                	li	a5,3
    80001e94:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e98:	854e                	mv	a0,s3
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	e04080e7          	jalr	-508(ra) # 80000c9e <release>
}
    80001ea2:	8552                	mv	a0,s4
    80001ea4:	70a2                	ld	ra,40(sp)
    80001ea6:	7402                	ld	s0,32(sp)
    80001ea8:	64e2                	ld	s1,24(sp)
    80001eaa:	6942                	ld	s2,16(sp)
    80001eac:	69a2                	ld	s3,8(sp)
    80001eae:	6a02                	ld	s4,0(sp)
    80001eb0:	6145                	addi	sp,sp,48
    80001eb2:	8082                	ret
    return -1;
    80001eb4:	5a7d                	li	s4,-1
    80001eb6:	b7f5                	j	80001ea2 <fork+0x126>

0000000080001eb8 <scheduler>:
{
    80001eb8:	7139                	addi	sp,sp,-64
    80001eba:	fc06                	sd	ra,56(sp)
    80001ebc:	f822                	sd	s0,48(sp)
    80001ebe:	f426                	sd	s1,40(sp)
    80001ec0:	f04a                	sd	s2,32(sp)
    80001ec2:	ec4e                	sd	s3,24(sp)
    80001ec4:	e852                	sd	s4,16(sp)
    80001ec6:	e456                	sd	s5,8(sp)
    80001ec8:	e05a                	sd	s6,0(sp)
    80001eca:	0080                	addi	s0,sp,64
    80001ecc:	8792                	mv	a5,tp
  int id = r_tp();
    80001ece:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed0:	00779a93          	slli	s5,a5,0x7
    80001ed4:	0000f717          	auipc	a4,0xf
    80001ed8:	c9c70713          	addi	a4,a4,-868 # 80010b70 <pid_lock>
    80001edc:	9756                	add	a4,a4,s5
    80001ede:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ee2:	0000f717          	auipc	a4,0xf
    80001ee6:	cc670713          	addi	a4,a4,-826 # 80010ba8 <cpus+0x8>
    80001eea:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001eec:	498d                	li	s3,3
        p->state = RUNNING;
    80001eee:	4b11                	li	s6,4
        c->proc = p;
    80001ef0:	079e                	slli	a5,a5,0x7
    80001ef2:	0000fa17          	auipc	s4,0xf
    80001ef6:	c7ea0a13          	addi	s4,s4,-898 # 80010b70 <pid_lock>
    80001efa:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001efc:	00015917          	auipc	s2,0x15
    80001f00:	aa490913          	addi	s2,s2,-1372 # 800169a0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f08:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f0c:	10079073          	csrw	sstatus,a5
    80001f10:	0000f497          	auipc	s1,0xf
    80001f14:	09048493          	addi	s1,s1,144 # 80010fa0 <proc>
    80001f18:	a03d                	j	80001f46 <scheduler+0x8e>
        p->state = RUNNING;
    80001f1a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f1e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f22:	06048593          	addi	a1,s1,96
    80001f26:	8556                	mv	a0,s5
    80001f28:	00000097          	auipc	ra,0x0
    80001f2c:	6a4080e7          	jalr	1700(ra) # 800025cc <swtch>
        c->proc = 0;
    80001f30:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	d68080e7          	jalr	-664(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3e:	16848493          	addi	s1,s1,360
    80001f42:	fd2481e3          	beq	s1,s2,80001f04 <scheduler+0x4c>
      acquire(&p->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	ca2080e7          	jalr	-862(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    80001f50:	4c9c                	lw	a5,24(s1)
    80001f52:	ff3791e3          	bne	a5,s3,80001f34 <scheduler+0x7c>
    80001f56:	b7d1                	j	80001f1a <scheduler+0x62>

0000000080001f58 <sched>:
{
    80001f58:	7179                	addi	sp,sp,-48
    80001f5a:	f406                	sd	ra,40(sp)
    80001f5c:	f022                	sd	s0,32(sp)
    80001f5e:	ec26                	sd	s1,24(sp)
    80001f60:	e84a                	sd	s2,16(sp)
    80001f62:	e44e                	sd	s3,8(sp)
    80001f64:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	a60080e7          	jalr	-1440(ra) # 800019c6 <myproc>
    80001f6e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	c00080e7          	jalr	-1024(ra) # 80000b70 <holding>
    80001f78:	c93d                	beqz	a0,80001fee <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f7a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f7c:	2781                	sext.w	a5,a5
    80001f7e:	079e                	slli	a5,a5,0x7
    80001f80:	0000f717          	auipc	a4,0xf
    80001f84:	bf070713          	addi	a4,a4,-1040 # 80010b70 <pid_lock>
    80001f88:	97ba                	add	a5,a5,a4
    80001f8a:	0a87a703          	lw	a4,168(a5)
    80001f8e:	4785                	li	a5,1
    80001f90:	06f71763          	bne	a4,a5,80001ffe <sched+0xa6>
  if(p->state == RUNNING)
    80001f94:	4c98                	lw	a4,24(s1)
    80001f96:	4791                	li	a5,4
    80001f98:	06f70b63          	beq	a4,a5,8000200e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fa0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fa2:	efb5                	bnez	a5,8000201e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa6:	0000f917          	auipc	s2,0xf
    80001faa:	bca90913          	addi	s2,s2,-1078 # 80010b70 <pid_lock>
    80001fae:	2781                	sext.w	a5,a5
    80001fb0:	079e                	slli	a5,a5,0x7
    80001fb2:	97ca                	add	a5,a5,s2
    80001fb4:	0ac7a983          	lw	s3,172(a5)
    80001fb8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fba:	2781                	sext.w	a5,a5
    80001fbc:	079e                	slli	a5,a5,0x7
    80001fbe:	0000f597          	auipc	a1,0xf
    80001fc2:	bea58593          	addi	a1,a1,-1046 # 80010ba8 <cpus+0x8>
    80001fc6:	95be                	add	a1,a1,a5
    80001fc8:	06048513          	addi	a0,s1,96
    80001fcc:	00000097          	auipc	ra,0x0
    80001fd0:	600080e7          	jalr	1536(ra) # 800025cc <swtch>
    80001fd4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd6:	2781                	sext.w	a5,a5
    80001fd8:	079e                	slli	a5,a5,0x7
    80001fda:	97ca                	add	a5,a5,s2
    80001fdc:	0b37a623          	sw	s3,172(a5)
}
    80001fe0:	70a2                	ld	ra,40(sp)
    80001fe2:	7402                	ld	s0,32(sp)
    80001fe4:	64e2                	ld	s1,24(sp)
    80001fe6:	6942                	ld	s2,16(sp)
    80001fe8:	69a2                	ld	s3,8(sp)
    80001fea:	6145                	addi	sp,sp,48
    80001fec:	8082                	ret
    panic("sched p->lock");
    80001fee:	00006517          	auipc	a0,0x6
    80001ff2:	22a50513          	addi	a0,a0,554 # 80008218 <digits+0x1d8>
    80001ff6:	ffffe097          	auipc	ra,0xffffe
    80001ffa:	54e080e7          	jalr	1358(ra) # 80000544 <panic>
    panic("sched locks");
    80001ffe:	00006517          	auipc	a0,0x6
    80002002:	22a50513          	addi	a0,a0,554 # 80008228 <digits+0x1e8>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	53e080e7          	jalr	1342(ra) # 80000544 <panic>
    panic("sched running");
    8000200e:	00006517          	auipc	a0,0x6
    80002012:	22a50513          	addi	a0,a0,554 # 80008238 <digits+0x1f8>
    80002016:	ffffe097          	auipc	ra,0xffffe
    8000201a:	52e080e7          	jalr	1326(ra) # 80000544 <panic>
    panic("sched interruptible");
    8000201e:	00006517          	auipc	a0,0x6
    80002022:	22a50513          	addi	a0,a0,554 # 80008248 <digits+0x208>
    80002026:	ffffe097          	auipc	ra,0xffffe
    8000202a:	51e080e7          	jalr	1310(ra) # 80000544 <panic>

000000008000202e <yield>:
{
    8000202e:	1101                	addi	sp,sp,-32
    80002030:	ec06                	sd	ra,24(sp)
    80002032:	e822                	sd	s0,16(sp)
    80002034:	e426                	sd	s1,8(sp)
    80002036:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	98e080e7          	jalr	-1650(ra) # 800019c6 <myproc>
    80002040:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	ba8080e7          	jalr	-1112(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    8000204a:	478d                	li	a5,3
    8000204c:	cc9c                	sw	a5,24(s1)
  sched();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	f0a080e7          	jalr	-246(ra) # 80001f58 <sched>
  release(&p->lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	c46080e7          	jalr	-954(ra) # 80000c9e <release>
}
    80002060:	60e2                	ld	ra,24(sp)
    80002062:	6442                	ld	s0,16(sp)
    80002064:	64a2                	ld	s1,8(sp)
    80002066:	6105                	addi	sp,sp,32
    80002068:	8082                	ret

000000008000206a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000206a:	7179                	addi	sp,sp,-48
    8000206c:	f406                	sd	ra,40(sp)
    8000206e:	f022                	sd	s0,32(sp)
    80002070:	ec26                	sd	s1,24(sp)
    80002072:	e84a                	sd	s2,16(sp)
    80002074:	e44e                	sd	s3,8(sp)
    80002076:	1800                	addi	s0,sp,48
    80002078:	89aa                	mv	s3,a0
    8000207a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	94a080e7          	jalr	-1718(ra) # 800019c6 <myproc>
    80002084:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b64080e7          	jalr	-1180(ra) # 80000bea <acquire>
  release(lk);
    8000208e:	854a                	mv	a0,s2
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	c0e080e7          	jalr	-1010(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002098:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000209c:	4789                	li	a5,2
    8000209e:	cc9c                	sw	a5,24(s1)

  sched();
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	eb8080e7          	jalr	-328(ra) # 80001f58 <sched>

  // Tidy up.
  p->chan = 0;
    800020a8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	bf0080e7          	jalr	-1040(ra) # 80000c9e <release>
  acquire(lk);
    800020b6:	854a                	mv	a0,s2
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	b32080e7          	jalr	-1230(ra) # 80000bea <acquire>
}
    800020c0:	70a2                	ld	ra,40(sp)
    800020c2:	7402                	ld	s0,32(sp)
    800020c4:	64e2                	ld	s1,24(sp)
    800020c6:	6942                	ld	s2,16(sp)
    800020c8:	69a2                	ld	s3,8(sp)
    800020ca:	6145                	addi	sp,sp,48
    800020cc:	8082                	ret

00000000800020ce <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020ce:	7139                	addi	sp,sp,-64
    800020d0:	fc06                	sd	ra,56(sp)
    800020d2:	f822                	sd	s0,48(sp)
    800020d4:	f426                	sd	s1,40(sp)
    800020d6:	f04a                	sd	s2,32(sp)
    800020d8:	ec4e                	sd	s3,24(sp)
    800020da:	e852                	sd	s4,16(sp)
    800020dc:	e456                	sd	s5,8(sp)
    800020de:	0080                	addi	s0,sp,64
    800020e0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020e2:	0000f497          	auipc	s1,0xf
    800020e6:	ebe48493          	addi	s1,s1,-322 # 80010fa0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020ea:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020ec:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ee:	00015917          	auipc	s2,0x15
    800020f2:	8b290913          	addi	s2,s2,-1870 # 800169a0 <tickslock>
    800020f6:	a821                	j	8000210e <wakeup+0x40>
        p->state = RUNNABLE;
    800020f8:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800020fc:	8526                	mv	a0,s1
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	ba0080e7          	jalr	-1120(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002106:	16848493          	addi	s1,s1,360
    8000210a:	03248463          	beq	s1,s2,80002132 <wakeup+0x64>
    if(p != myproc()){
    8000210e:	00000097          	auipc	ra,0x0
    80002112:	8b8080e7          	jalr	-1864(ra) # 800019c6 <myproc>
    80002116:	fea488e3          	beq	s1,a0,80002106 <wakeup+0x38>
      acquire(&p->lock);
    8000211a:	8526                	mv	a0,s1
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	ace080e7          	jalr	-1330(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002124:	4c9c                	lw	a5,24(s1)
    80002126:	fd379be3          	bne	a5,s3,800020fc <wakeup+0x2e>
    8000212a:	709c                	ld	a5,32(s1)
    8000212c:	fd4798e3          	bne	a5,s4,800020fc <wakeup+0x2e>
    80002130:	b7e1                	j	800020f8 <wakeup+0x2a>
    }
  }
}
    80002132:	70e2                	ld	ra,56(sp)
    80002134:	7442                	ld	s0,48(sp)
    80002136:	74a2                	ld	s1,40(sp)
    80002138:	7902                	ld	s2,32(sp)
    8000213a:	69e2                	ld	s3,24(sp)
    8000213c:	6a42                	ld	s4,16(sp)
    8000213e:	6aa2                	ld	s5,8(sp)
    80002140:	6121                	addi	sp,sp,64
    80002142:	8082                	ret

0000000080002144 <reparent>:
{
    80002144:	7179                	addi	sp,sp,-48
    80002146:	f406                	sd	ra,40(sp)
    80002148:	f022                	sd	s0,32(sp)
    8000214a:	ec26                	sd	s1,24(sp)
    8000214c:	e84a                	sd	s2,16(sp)
    8000214e:	e44e                	sd	s3,8(sp)
    80002150:	e052                	sd	s4,0(sp)
    80002152:	1800                	addi	s0,sp,48
    80002154:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002156:	0000f497          	auipc	s1,0xf
    8000215a:	e4a48493          	addi	s1,s1,-438 # 80010fa0 <proc>
      pp->parent = initproc;
    8000215e:	00006a17          	auipc	s4,0x6
    80002162:	79aa0a13          	addi	s4,s4,1946 # 800088f8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002166:	00015997          	auipc	s3,0x15
    8000216a:	83a98993          	addi	s3,s3,-1990 # 800169a0 <tickslock>
    8000216e:	a029                	j	80002178 <reparent+0x34>
    80002170:	16848493          	addi	s1,s1,360
    80002174:	01348d63          	beq	s1,s3,8000218e <reparent+0x4a>
    if(pp->parent == p){
    80002178:	7c9c                	ld	a5,56(s1)
    8000217a:	ff279be3          	bne	a5,s2,80002170 <reparent+0x2c>
      pp->parent = initproc;
    8000217e:	000a3503          	ld	a0,0(s4)
    80002182:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002184:	00000097          	auipc	ra,0x0
    80002188:	f4a080e7          	jalr	-182(ra) # 800020ce <wakeup>
    8000218c:	b7d5                	j	80002170 <reparent+0x2c>
}
    8000218e:	70a2                	ld	ra,40(sp)
    80002190:	7402                	ld	s0,32(sp)
    80002192:	64e2                	ld	s1,24(sp)
    80002194:	6942                	ld	s2,16(sp)
    80002196:	69a2                	ld	s3,8(sp)
    80002198:	6a02                	ld	s4,0(sp)
    8000219a:	6145                	addi	sp,sp,48
    8000219c:	8082                	ret

000000008000219e <exit>:
{
    8000219e:	7179                	addi	sp,sp,-48
    800021a0:	f406                	sd	ra,40(sp)
    800021a2:	f022                	sd	s0,32(sp)
    800021a4:	ec26                	sd	s1,24(sp)
    800021a6:	e84a                	sd	s2,16(sp)
    800021a8:	e44e                	sd	s3,8(sp)
    800021aa:	e052                	sd	s4,0(sp)
    800021ac:	1800                	addi	s0,sp,48
    800021ae:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021b0:	00000097          	auipc	ra,0x0
    800021b4:	816080e7          	jalr	-2026(ra) # 800019c6 <myproc>
    800021b8:	89aa                	mv	s3,a0
  if(p == initproc)
    800021ba:	00006797          	auipc	a5,0x6
    800021be:	73e7b783          	ld	a5,1854(a5) # 800088f8 <initproc>
    800021c2:	0d050493          	addi	s1,a0,208
    800021c6:	15050913          	addi	s2,a0,336
    800021ca:	02a79363          	bne	a5,a0,800021f0 <exit+0x52>
    panic("init exiting");
    800021ce:	00006517          	auipc	a0,0x6
    800021d2:	09250513          	addi	a0,a0,146 # 80008260 <digits+0x220>
    800021d6:	ffffe097          	auipc	ra,0xffffe
    800021da:	36e080e7          	jalr	878(ra) # 80000544 <panic>
      fileclose(f);
    800021de:	00002097          	auipc	ra,0x2
    800021e2:	366080e7          	jalr	870(ra) # 80004544 <fileclose>
      p->ofile[fd] = 0;
    800021e6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021ea:	04a1                	addi	s1,s1,8
    800021ec:	01248563          	beq	s1,s2,800021f6 <exit+0x58>
    if(p->ofile[fd]){
    800021f0:	6088                	ld	a0,0(s1)
    800021f2:	f575                	bnez	a0,800021de <exit+0x40>
    800021f4:	bfdd                	j	800021ea <exit+0x4c>
  begin_op();
    800021f6:	00002097          	auipc	ra,0x2
    800021fa:	e82080e7          	jalr	-382(ra) # 80004078 <begin_op>
  iput(p->cwd);
    800021fe:	1509b503          	ld	a0,336(s3)
    80002202:	00001097          	auipc	ra,0x1
    80002206:	66e080e7          	jalr	1646(ra) # 80003870 <iput>
  end_op();
    8000220a:	00002097          	auipc	ra,0x2
    8000220e:	eee080e7          	jalr	-274(ra) # 800040f8 <end_op>
  p->cwd = 0;
    80002212:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002216:	0000f497          	auipc	s1,0xf
    8000221a:	97248493          	addi	s1,s1,-1678 # 80010b88 <wait_lock>
    8000221e:	8526                	mv	a0,s1
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	9ca080e7          	jalr	-1590(ra) # 80000bea <acquire>
  reparent(p);
    80002228:	854e                	mv	a0,s3
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	f1a080e7          	jalr	-230(ra) # 80002144 <reparent>
  wakeup(p->parent);
    80002232:	0389b503          	ld	a0,56(s3)
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	e98080e7          	jalr	-360(ra) # 800020ce <wakeup>
  acquire(&p->lock);
    8000223e:	854e                	mv	a0,s3
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	9aa080e7          	jalr	-1622(ra) # 80000bea <acquire>
  p->xstate = status;
    80002248:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000224c:	4795                	li	a5,5
    8000224e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	a4a080e7          	jalr	-1462(ra) # 80000c9e <release>
  sched();
    8000225c:	00000097          	auipc	ra,0x0
    80002260:	cfc080e7          	jalr	-772(ra) # 80001f58 <sched>
  panic("zombie exit");
    80002264:	00006517          	auipc	a0,0x6
    80002268:	00c50513          	addi	a0,a0,12 # 80008270 <digits+0x230>
    8000226c:	ffffe097          	auipc	ra,0xffffe
    80002270:	2d8080e7          	jalr	728(ra) # 80000544 <panic>

0000000080002274 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002274:	7179                	addi	sp,sp,-48
    80002276:	f406                	sd	ra,40(sp)
    80002278:	f022                	sd	s0,32(sp)
    8000227a:	ec26                	sd	s1,24(sp)
    8000227c:	e84a                	sd	s2,16(sp)
    8000227e:	e44e                	sd	s3,8(sp)
    80002280:	1800                	addi	s0,sp,48
    80002282:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002284:	0000f497          	auipc	s1,0xf
    80002288:	d1c48493          	addi	s1,s1,-740 # 80010fa0 <proc>
    8000228c:	00014997          	auipc	s3,0x14
    80002290:	71498993          	addi	s3,s3,1812 # 800169a0 <tickslock>
    acquire(&p->lock);
    80002294:	8526                	mv	a0,s1
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	954080e7          	jalr	-1708(ra) # 80000bea <acquire>
    if(p->pid == pid){
    8000229e:	589c                	lw	a5,48(s1)
    800022a0:	01278d63          	beq	a5,s2,800022ba <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	9f8080e7          	jalr	-1544(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022ae:	16848493          	addi	s1,s1,360
    800022b2:	ff3491e3          	bne	s1,s3,80002294 <kill+0x20>
  }
  return -1;
    800022b6:	557d                	li	a0,-1
    800022b8:	a829                	j	800022d2 <kill+0x5e>
      p->killed = 1;
    800022ba:	4785                	li	a5,1
    800022bc:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022be:	4c98                	lw	a4,24(s1)
    800022c0:	4789                	li	a5,2
    800022c2:	00f70f63          	beq	a4,a5,800022e0 <kill+0x6c>
      release(&p->lock);
    800022c6:	8526                	mv	a0,s1
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	9d6080e7          	jalr	-1578(ra) # 80000c9e <release>
      return 0;
    800022d0:	4501                	li	a0,0
}
    800022d2:	70a2                	ld	ra,40(sp)
    800022d4:	7402                	ld	s0,32(sp)
    800022d6:	64e2                	ld	s1,24(sp)
    800022d8:	6942                	ld	s2,16(sp)
    800022da:	69a2                	ld	s3,8(sp)
    800022dc:	6145                	addi	sp,sp,48
    800022de:	8082                	ret
        p->state = RUNNABLE;
    800022e0:	478d                	li	a5,3
    800022e2:	cc9c                	sw	a5,24(s1)
    800022e4:	b7cd                	j	800022c6 <kill+0x52>

00000000800022e6 <setkilled>:

void
setkilled(struct proc *p)
{
    800022e6:	1101                	addi	sp,sp,-32
    800022e8:	ec06                	sd	ra,24(sp)
    800022ea:	e822                	sd	s0,16(sp)
    800022ec:	e426                	sd	s1,8(sp)
    800022ee:	1000                	addi	s0,sp,32
    800022f0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	8f8080e7          	jalr	-1800(ra) # 80000bea <acquire>
  p->killed = 1;
    800022fa:	4785                	li	a5,1
    800022fc:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022fe:	8526                	mv	a0,s1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	99e080e7          	jalr	-1634(ra) # 80000c9e <release>
}
    80002308:	60e2                	ld	ra,24(sp)
    8000230a:	6442                	ld	s0,16(sp)
    8000230c:	64a2                	ld	s1,8(sp)
    8000230e:	6105                	addi	sp,sp,32
    80002310:	8082                	ret

0000000080002312 <killed>:

int
killed(struct proc *p)
{
    80002312:	1101                	addi	sp,sp,-32
    80002314:	ec06                	sd	ra,24(sp)
    80002316:	e822                	sd	s0,16(sp)
    80002318:	e426                	sd	s1,8(sp)
    8000231a:	e04a                	sd	s2,0(sp)
    8000231c:	1000                	addi	s0,sp,32
    8000231e:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	8ca080e7          	jalr	-1846(ra) # 80000bea <acquire>
  k = p->killed;
    80002328:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	970080e7          	jalr	-1680(ra) # 80000c9e <release>
  return k;
}
    80002336:	854a                	mv	a0,s2
    80002338:	60e2                	ld	ra,24(sp)
    8000233a:	6442                	ld	s0,16(sp)
    8000233c:	64a2                	ld	s1,8(sp)
    8000233e:	6902                	ld	s2,0(sp)
    80002340:	6105                	addi	sp,sp,32
    80002342:	8082                	ret

0000000080002344 <wait>:
{
    80002344:	715d                	addi	sp,sp,-80
    80002346:	e486                	sd	ra,72(sp)
    80002348:	e0a2                	sd	s0,64(sp)
    8000234a:	fc26                	sd	s1,56(sp)
    8000234c:	f84a                	sd	s2,48(sp)
    8000234e:	f44e                	sd	s3,40(sp)
    80002350:	f052                	sd	s4,32(sp)
    80002352:	ec56                	sd	s5,24(sp)
    80002354:	e85a                	sd	s6,16(sp)
    80002356:	e45e                	sd	s7,8(sp)
    80002358:	e062                	sd	s8,0(sp)
    8000235a:	0880                	addi	s0,sp,80
    8000235c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	668080e7          	jalr	1640(ra) # 800019c6 <myproc>
    80002366:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002368:	0000f517          	auipc	a0,0xf
    8000236c:	82050513          	addi	a0,a0,-2016 # 80010b88 <wait_lock>
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	87a080e7          	jalr	-1926(ra) # 80000bea <acquire>
    havekids = 0;
    80002378:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000237a:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237c:	00014997          	auipc	s3,0x14
    80002380:	62498993          	addi	s3,s3,1572 # 800169a0 <tickslock>
        havekids = 1;
    80002384:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002386:	0000fc17          	auipc	s8,0xf
    8000238a:	802c0c13          	addi	s8,s8,-2046 # 80010b88 <wait_lock>
    havekids = 0;
    8000238e:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002390:	0000f497          	auipc	s1,0xf
    80002394:	c1048493          	addi	s1,s1,-1008 # 80010fa0 <proc>
    80002398:	a0bd                	j	80002406 <wait+0xc2>
          pid = pp->pid;
    8000239a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000239e:	000b0e63          	beqz	s6,800023ba <wait+0x76>
    800023a2:	4691                	li	a3,4
    800023a4:	02c48613          	addi	a2,s1,44
    800023a8:	85da                	mv	a1,s6
    800023aa:	05093503          	ld	a0,80(s2)
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	2d6080e7          	jalr	726(ra) # 80001684 <copyout>
    800023b6:	02054563          	bltz	a0,800023e0 <wait+0x9c>
          freeproc(pp);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	7bc080e7          	jalr	1980(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	8d8080e7          	jalr	-1832(ra) # 80000c9e <release>
          release(&wait_lock);
    800023ce:	0000e517          	auipc	a0,0xe
    800023d2:	7ba50513          	addi	a0,a0,1978 # 80010b88 <wait_lock>
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	8c8080e7          	jalr	-1848(ra) # 80000c9e <release>
          return pid;
    800023de:	a0b5                	j	8000244a <wait+0x106>
            release(&pp->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8bc080e7          	jalr	-1860(ra) # 80000c9e <release>
            release(&wait_lock);
    800023ea:	0000e517          	auipc	a0,0xe
    800023ee:	79e50513          	addi	a0,a0,1950 # 80010b88 <wait_lock>
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8ac080e7          	jalr	-1876(ra) # 80000c9e <release>
            return -1;
    800023fa:	59fd                	li	s3,-1
    800023fc:	a0b9                	j	8000244a <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023fe:	16848493          	addi	s1,s1,360
    80002402:	03348463          	beq	s1,s3,8000242a <wait+0xe6>
      if(pp->parent == p){
    80002406:	7c9c                	ld	a5,56(s1)
    80002408:	ff279be3          	bne	a5,s2,800023fe <wait+0xba>
        acquire(&pp->lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	7dc080e7          	jalr	2012(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002416:	4c9c                	lw	a5,24(s1)
    80002418:	f94781e3          	beq	a5,s4,8000239a <wait+0x56>
        release(&pp->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	880080e7          	jalr	-1920(ra) # 80000c9e <release>
        havekids = 1;
    80002426:	8756                	mv	a4,s5
    80002428:	bfd9                	j	800023fe <wait+0xba>
    if(!havekids || killed(p)){
    8000242a:	c719                	beqz	a4,80002438 <wait+0xf4>
    8000242c:	854a                	mv	a0,s2
    8000242e:	00000097          	auipc	ra,0x0
    80002432:	ee4080e7          	jalr	-284(ra) # 80002312 <killed>
    80002436:	c51d                	beqz	a0,80002464 <wait+0x120>
      release(&wait_lock);
    80002438:	0000e517          	auipc	a0,0xe
    8000243c:	75050513          	addi	a0,a0,1872 # 80010b88 <wait_lock>
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	85e080e7          	jalr	-1954(ra) # 80000c9e <release>
      return -1;
    80002448:	59fd                	li	s3,-1
}
    8000244a:	854e                	mv	a0,s3
    8000244c:	60a6                	ld	ra,72(sp)
    8000244e:	6406                	ld	s0,64(sp)
    80002450:	74e2                	ld	s1,56(sp)
    80002452:	7942                	ld	s2,48(sp)
    80002454:	79a2                	ld	s3,40(sp)
    80002456:	7a02                	ld	s4,32(sp)
    80002458:	6ae2                	ld	s5,24(sp)
    8000245a:	6b42                	ld	s6,16(sp)
    8000245c:	6ba2                	ld	s7,8(sp)
    8000245e:	6c02                	ld	s8,0(sp)
    80002460:	6161                	addi	sp,sp,80
    80002462:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002464:	85e2                	mv	a1,s8
    80002466:	854a                	mv	a0,s2
    80002468:	00000097          	auipc	ra,0x0
    8000246c:	c02080e7          	jalr	-1022(ra) # 8000206a <sleep>
    havekids = 0;
    80002470:	bf39                	j	8000238e <wait+0x4a>

0000000080002472 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002472:	7179                	addi	sp,sp,-48
    80002474:	f406                	sd	ra,40(sp)
    80002476:	f022                	sd	s0,32(sp)
    80002478:	ec26                	sd	s1,24(sp)
    8000247a:	e84a                	sd	s2,16(sp)
    8000247c:	e44e                	sd	s3,8(sp)
    8000247e:	e052                	sd	s4,0(sp)
    80002480:	1800                	addi	s0,sp,48
    80002482:	84aa                	mv	s1,a0
    80002484:	892e                	mv	s2,a1
    80002486:	89b2                	mv	s3,a2
    80002488:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	53c080e7          	jalr	1340(ra) # 800019c6 <myproc>
  if(user_dst){
    80002492:	c08d                	beqz	s1,800024b4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002494:	86d2                	mv	a3,s4
    80002496:	864e                	mv	a2,s3
    80002498:	85ca                	mv	a1,s2
    8000249a:	6928                	ld	a0,80(a0)
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	1e8080e7          	jalr	488(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024a4:	70a2                	ld	ra,40(sp)
    800024a6:	7402                	ld	s0,32(sp)
    800024a8:	64e2                	ld	s1,24(sp)
    800024aa:	6942                	ld	s2,16(sp)
    800024ac:	69a2                	ld	s3,8(sp)
    800024ae:	6a02                	ld	s4,0(sp)
    800024b0:	6145                	addi	sp,sp,48
    800024b2:	8082                	ret
    memmove((char *)dst, src, len);
    800024b4:	000a061b          	sext.w	a2,s4
    800024b8:	85ce                	mv	a1,s3
    800024ba:	854a                	mv	a0,s2
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	88a080e7          	jalr	-1910(ra) # 80000d46 <memmove>
    return 0;
    800024c4:	8526                	mv	a0,s1
    800024c6:	bff9                	j	800024a4 <either_copyout+0x32>

00000000800024c8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024c8:	7179                	addi	sp,sp,-48
    800024ca:	f406                	sd	ra,40(sp)
    800024cc:	f022                	sd	s0,32(sp)
    800024ce:	ec26                	sd	s1,24(sp)
    800024d0:	e84a                	sd	s2,16(sp)
    800024d2:	e44e                	sd	s3,8(sp)
    800024d4:	e052                	sd	s4,0(sp)
    800024d6:	1800                	addi	s0,sp,48
    800024d8:	892a                	mv	s2,a0
    800024da:	84ae                	mv	s1,a1
    800024dc:	89b2                	mv	s3,a2
    800024de:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	4e6080e7          	jalr	1254(ra) # 800019c6 <myproc>
  if(user_src){
    800024e8:	c08d                	beqz	s1,8000250a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024ea:	86d2                	mv	a3,s4
    800024ec:	864e                	mv	a2,s3
    800024ee:	85ca                	mv	a1,s2
    800024f0:	6928                	ld	a0,80(a0)
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	21e080e7          	jalr	542(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024fa:	70a2                	ld	ra,40(sp)
    800024fc:	7402                	ld	s0,32(sp)
    800024fe:	64e2                	ld	s1,24(sp)
    80002500:	6942                	ld	s2,16(sp)
    80002502:	69a2                	ld	s3,8(sp)
    80002504:	6a02                	ld	s4,0(sp)
    80002506:	6145                	addi	sp,sp,48
    80002508:	8082                	ret
    memmove(dst, (char*)src, len);
    8000250a:	000a061b          	sext.w	a2,s4
    8000250e:	85ce                	mv	a1,s3
    80002510:	854a                	mv	a0,s2
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	834080e7          	jalr	-1996(ra) # 80000d46 <memmove>
    return 0;
    8000251a:	8526                	mv	a0,s1
    8000251c:	bff9                	j	800024fa <either_copyin+0x32>

000000008000251e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000251e:	715d                	addi	sp,sp,-80
    80002520:	e486                	sd	ra,72(sp)
    80002522:	e0a2                	sd	s0,64(sp)
    80002524:	fc26                	sd	s1,56(sp)
    80002526:	f84a                	sd	s2,48(sp)
    80002528:	f44e                	sd	s3,40(sp)
    8000252a:	f052                	sd	s4,32(sp)
    8000252c:	ec56                	sd	s5,24(sp)
    8000252e:	e85a                	sd	s6,16(sp)
    80002530:	e45e                	sd	s7,8(sp)
    80002532:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002534:	00006517          	auipc	a0,0x6
    80002538:	b9450513          	addi	a0,a0,-1132 # 800080c8 <digits+0x88>
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	052080e7          	jalr	82(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002544:	0000f497          	auipc	s1,0xf
    80002548:	bb448493          	addi	s1,s1,-1100 # 800110f8 <proc+0x158>
    8000254c:	00014917          	auipc	s2,0x14
    80002550:	5ac90913          	addi	s2,s2,1452 # 80016af8 <bcache+0x98>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002554:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002556:	00006997          	auipc	s3,0x6
    8000255a:	d2a98993          	addi	s3,s3,-726 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000255e:	00006a97          	auipc	s5,0x6
    80002562:	d2aa8a93          	addi	s5,s5,-726 # 80008288 <digits+0x248>
    printf("\n");
    80002566:	00006a17          	auipc	s4,0x6
    8000256a:	b62a0a13          	addi	s4,s4,-1182 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000256e:	00006b97          	auipc	s7,0x6
    80002572:	d5ab8b93          	addi	s7,s7,-678 # 800082c8 <states.1722>
    80002576:	a00d                	j	80002598 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002578:	ed86a583          	lw	a1,-296(a3)
    8000257c:	8556                	mv	a0,s5
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	010080e7          	jalr	16(ra) # 8000058e <printf>
    printf("\n");
    80002586:	8552                	mv	a0,s4
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	006080e7          	jalr	6(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002590:	16848493          	addi	s1,s1,360
    80002594:	03248163          	beq	s1,s2,800025b6 <procdump+0x98>
    if(p->state == UNUSED)
    80002598:	86a6                	mv	a3,s1
    8000259a:	ec04a783          	lw	a5,-320(s1)
    8000259e:	dbed                	beqz	a5,80002590 <procdump+0x72>
      state = "???";
    800025a0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a2:	fcfb6be3          	bltu	s6,a5,80002578 <procdump+0x5a>
    800025a6:	1782                	slli	a5,a5,0x20
    800025a8:	9381                	srli	a5,a5,0x20
    800025aa:	078e                	slli	a5,a5,0x3
    800025ac:	97de                	add	a5,a5,s7
    800025ae:	6390                	ld	a2,0(a5)
    800025b0:	f661                	bnez	a2,80002578 <procdump+0x5a>
      state = "???";
    800025b2:	864e                	mv	a2,s3
    800025b4:	b7d1                	j	80002578 <procdump+0x5a>
  }
}
    800025b6:	60a6                	ld	ra,72(sp)
    800025b8:	6406                	ld	s0,64(sp)
    800025ba:	74e2                	ld	s1,56(sp)
    800025bc:	7942                	ld	s2,48(sp)
    800025be:	79a2                	ld	s3,40(sp)
    800025c0:	7a02                	ld	s4,32(sp)
    800025c2:	6ae2                	ld	s5,24(sp)
    800025c4:	6b42                	ld	s6,16(sp)
    800025c6:	6ba2                	ld	s7,8(sp)
    800025c8:	6161                	addi	sp,sp,80
    800025ca:	8082                	ret

00000000800025cc <swtch>:
    800025cc:	00153023          	sd	ra,0(a0)
    800025d0:	00253423          	sd	sp,8(a0)
    800025d4:	e900                	sd	s0,16(a0)
    800025d6:	ed04                	sd	s1,24(a0)
    800025d8:	03253023          	sd	s2,32(a0)
    800025dc:	03353423          	sd	s3,40(a0)
    800025e0:	03453823          	sd	s4,48(a0)
    800025e4:	03553c23          	sd	s5,56(a0)
    800025e8:	05653023          	sd	s6,64(a0)
    800025ec:	05753423          	sd	s7,72(a0)
    800025f0:	05853823          	sd	s8,80(a0)
    800025f4:	05953c23          	sd	s9,88(a0)
    800025f8:	07a53023          	sd	s10,96(a0)
    800025fc:	07b53423          	sd	s11,104(a0)
    80002600:	0005b083          	ld	ra,0(a1)
    80002604:	0085b103          	ld	sp,8(a1)
    80002608:	6980                	ld	s0,16(a1)
    8000260a:	6d84                	ld	s1,24(a1)
    8000260c:	0205b903          	ld	s2,32(a1)
    80002610:	0285b983          	ld	s3,40(a1)
    80002614:	0305ba03          	ld	s4,48(a1)
    80002618:	0385ba83          	ld	s5,56(a1)
    8000261c:	0405bb03          	ld	s6,64(a1)
    80002620:	0485bb83          	ld	s7,72(a1)
    80002624:	0505bc03          	ld	s8,80(a1)
    80002628:	0585bc83          	ld	s9,88(a1)
    8000262c:	0605bd03          	ld	s10,96(a1)
    80002630:	0685bd83          	ld	s11,104(a1)
    80002634:	8082                	ret

0000000080002636 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002636:	1141                	addi	sp,sp,-16
    80002638:	e406                	sd	ra,8(sp)
    8000263a:	e022                	sd	s0,0(sp)
    8000263c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000263e:	00006597          	auipc	a1,0x6
    80002642:	cba58593          	addi	a1,a1,-838 # 800082f8 <states.1722+0x30>
    80002646:	00014517          	auipc	a0,0x14
    8000264a:	35a50513          	addi	a0,a0,858 # 800169a0 <tickslock>
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	50c080e7          	jalr	1292(ra) # 80000b5a <initlock>
}
    80002656:	60a2                	ld	ra,8(sp)
    80002658:	6402                	ld	s0,0(sp)
    8000265a:	0141                	addi	sp,sp,16
    8000265c:	8082                	ret

000000008000265e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000265e:	1141                	addi	sp,sp,-16
    80002660:	e422                	sd	s0,8(sp)
    80002662:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002664:	00003797          	auipc	a5,0x3
    80002668:	51c78793          	addi	a5,a5,1308 # 80005b80 <kernelvec>
    8000266c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002670:	6422                	ld	s0,8(sp)
    80002672:	0141                	addi	sp,sp,16
    80002674:	8082                	ret

0000000080002676 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002676:	1141                	addi	sp,sp,-16
    80002678:	e406                	sd	ra,8(sp)
    8000267a:	e022                	sd	s0,0(sp)
    8000267c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000267e:	fffff097          	auipc	ra,0xfffff
    80002682:	348080e7          	jalr	840(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002686:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000268a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000268c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002690:	00005617          	auipc	a2,0x5
    80002694:	97060613          	addi	a2,a2,-1680 # 80007000 <_trampoline>
    80002698:	00005697          	auipc	a3,0x5
    8000269c:	96868693          	addi	a3,a3,-1688 # 80007000 <_trampoline>
    800026a0:	8e91                	sub	a3,a3,a2
    800026a2:	040007b7          	lui	a5,0x4000
    800026a6:	17fd                	addi	a5,a5,-1
    800026a8:	07b2                	slli	a5,a5,0xc
    800026aa:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ac:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026b0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026b2:	180026f3          	csrr	a3,satp
    800026b6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026b8:	6d38                	ld	a4,88(a0)
    800026ba:	6134                	ld	a3,64(a0)
    800026bc:	6585                	lui	a1,0x1
    800026be:	96ae                	add	a3,a3,a1
    800026c0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026c2:	6d38                	ld	a4,88(a0)
    800026c4:	00000697          	auipc	a3,0x0
    800026c8:	13068693          	addi	a3,a3,304 # 800027f4 <usertrap>
    800026cc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026ce:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026d0:	8692                	mv	a3,tp
    800026d2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026d4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026d8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026dc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026e0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026e4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026e6:	6f18                	ld	a4,24(a4)
    800026e8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026ec:	6928                	ld	a0,80(a0)
    800026ee:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026f0:	00005717          	auipc	a4,0x5
    800026f4:	9ac70713          	addi	a4,a4,-1620 # 8000709c <userret>
    800026f8:	8f11                	sub	a4,a4,a2
    800026fa:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800026fc:	577d                	li	a4,-1
    800026fe:	177e                	slli	a4,a4,0x3f
    80002700:	8d59                	or	a0,a0,a4
    80002702:	9782                	jalr	a5
}
    80002704:	60a2                	ld	ra,8(sp)
    80002706:	6402                	ld	s0,0(sp)
    80002708:	0141                	addi	sp,sp,16
    8000270a:	8082                	ret

000000008000270c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000270c:	1101                	addi	sp,sp,-32
    8000270e:	ec06                	sd	ra,24(sp)
    80002710:	e822                	sd	s0,16(sp)
    80002712:	e426                	sd	s1,8(sp)
    80002714:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002716:	00014497          	auipc	s1,0x14
    8000271a:	28a48493          	addi	s1,s1,650 # 800169a0 <tickslock>
    8000271e:	8526                	mv	a0,s1
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	4ca080e7          	jalr	1226(ra) # 80000bea <acquire>
  ticks++;
    80002728:	00006517          	auipc	a0,0x6
    8000272c:	1d850513          	addi	a0,a0,472 # 80008900 <ticks>
    80002730:	411c                	lw	a5,0(a0)
    80002732:	2785                	addiw	a5,a5,1
    80002734:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002736:	00000097          	auipc	ra,0x0
    8000273a:	998080e7          	jalr	-1640(ra) # 800020ce <wakeup>
  release(&tickslock);
    8000273e:	8526                	mv	a0,s1
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	55e080e7          	jalr	1374(ra) # 80000c9e <release>
}
    80002748:	60e2                	ld	ra,24(sp)
    8000274a:	6442                	ld	s0,16(sp)
    8000274c:	64a2                	ld	s1,8(sp)
    8000274e:	6105                	addi	sp,sp,32
    80002750:	8082                	ret

0000000080002752 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002752:	1101                	addi	sp,sp,-32
    80002754:	ec06                	sd	ra,24(sp)
    80002756:	e822                	sd	s0,16(sp)
    80002758:	e426                	sd	s1,8(sp)
    8000275a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000275c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002760:	00074d63          	bltz	a4,8000277a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002764:	57fd                	li	a5,-1
    80002766:	17fe                	slli	a5,a5,0x3f
    80002768:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000276a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000276c:	06f70363          	beq	a4,a5,800027d2 <devintr+0x80>
  }
}
    80002770:	60e2                	ld	ra,24(sp)
    80002772:	6442                	ld	s0,16(sp)
    80002774:	64a2                	ld	s1,8(sp)
    80002776:	6105                	addi	sp,sp,32
    80002778:	8082                	ret
     (scause & 0xff) == 9){
    8000277a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000277e:	46a5                	li	a3,9
    80002780:	fed792e3          	bne	a5,a3,80002764 <devintr+0x12>
    int irq = plic_claim();
    80002784:	00003097          	auipc	ra,0x3
    80002788:	504080e7          	jalr	1284(ra) # 80005c88 <plic_claim>
    8000278c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000278e:	47a9                	li	a5,10
    80002790:	02f50763          	beq	a0,a5,800027be <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002794:	4785                	li	a5,1
    80002796:	02f50963          	beq	a0,a5,800027c8 <devintr+0x76>
    return 1;
    8000279a:	4505                	li	a0,1
    } else if(irq){
    8000279c:	d8f1                	beqz	s1,80002770 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000279e:	85a6                	mv	a1,s1
    800027a0:	00006517          	auipc	a0,0x6
    800027a4:	b6050513          	addi	a0,a0,-1184 # 80008300 <states.1722+0x38>
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	de6080e7          	jalr	-538(ra) # 8000058e <printf>
      plic_complete(irq);
    800027b0:	8526                	mv	a0,s1
    800027b2:	00003097          	auipc	ra,0x3
    800027b6:	4fa080e7          	jalr	1274(ra) # 80005cac <plic_complete>
    return 1;
    800027ba:	4505                	li	a0,1
    800027bc:	bf55                	j	80002770 <devintr+0x1e>
      uartintr();
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	1f0080e7          	jalr	496(ra) # 800009ae <uartintr>
    800027c6:	b7ed                	j	800027b0 <devintr+0x5e>
      virtio_disk_intr();
    800027c8:	00004097          	auipc	ra,0x4
    800027cc:	a0e080e7          	jalr	-1522(ra) # 800061d6 <virtio_disk_intr>
    800027d0:	b7c5                	j	800027b0 <devintr+0x5e>
    if(cpuid() == 0){
    800027d2:	fffff097          	auipc	ra,0xfffff
    800027d6:	1c8080e7          	jalr	456(ra) # 8000199a <cpuid>
    800027da:	c901                	beqz	a0,800027ea <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027dc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027e0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027e2:	14479073          	csrw	sip,a5
    return 2;
    800027e6:	4509                	li	a0,2
    800027e8:	b761                	j	80002770 <devintr+0x1e>
      clockintr();
    800027ea:	00000097          	auipc	ra,0x0
    800027ee:	f22080e7          	jalr	-222(ra) # 8000270c <clockintr>
    800027f2:	b7ed                	j	800027dc <devintr+0x8a>

00000000800027f4 <usertrap>:
{
    800027f4:	1101                	addi	sp,sp,-32
    800027f6:	ec06                	sd	ra,24(sp)
    800027f8:	e822                	sd	s0,16(sp)
    800027fa:	e426                	sd	s1,8(sp)
    800027fc:	e04a                	sd	s2,0(sp)
    800027fe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002800:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002804:	1007f793          	andi	a5,a5,256
    80002808:	e3b1                	bnez	a5,8000284c <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000280a:	00003797          	auipc	a5,0x3
    8000280e:	37678793          	addi	a5,a5,886 # 80005b80 <kernelvec>
    80002812:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	1b0080e7          	jalr	432(ra) # 800019c6 <myproc>
    8000281e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002820:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002822:	14102773          	csrr	a4,sepc
    80002826:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002828:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000282c:	47a1                	li	a5,8
    8000282e:	02f70763          	beq	a4,a5,8000285c <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002832:	00000097          	auipc	ra,0x0
    80002836:	f20080e7          	jalr	-224(ra) # 80002752 <devintr>
    8000283a:	892a                	mv	s2,a0
    8000283c:	c151                	beqz	a0,800028c0 <usertrap+0xcc>
  if(killed(p))
    8000283e:	8526                	mv	a0,s1
    80002840:	00000097          	auipc	ra,0x0
    80002844:	ad2080e7          	jalr	-1326(ra) # 80002312 <killed>
    80002848:	c929                	beqz	a0,8000289a <usertrap+0xa6>
    8000284a:	a099                	j	80002890 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    8000284c:	00006517          	auipc	a0,0x6
    80002850:	ad450513          	addi	a0,a0,-1324 # 80008320 <states.1722+0x58>
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	cf0080e7          	jalr	-784(ra) # 80000544 <panic>
    if(killed(p))
    8000285c:	00000097          	auipc	ra,0x0
    80002860:	ab6080e7          	jalr	-1354(ra) # 80002312 <killed>
    80002864:	e921                	bnez	a0,800028b4 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002866:	6cb8                	ld	a4,88(s1)
    80002868:	6f1c                	ld	a5,24(a4)
    8000286a:	0791                	addi	a5,a5,4
    8000286c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000286e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002872:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002876:	10079073          	csrw	sstatus,a5
    syscall();
    8000287a:	00000097          	auipc	ra,0x0
    8000287e:	338080e7          	jalr	824(ra) # 80002bb2 <syscall>
  if(killed(p))
    80002882:	8526                	mv	a0,s1
    80002884:	00000097          	auipc	ra,0x0
    80002888:	a8e080e7          	jalr	-1394(ra) # 80002312 <killed>
    8000288c:	c911                	beqz	a0,800028a0 <usertrap+0xac>
    8000288e:	4901                	li	s2,0
    exit(-1);
    80002890:	557d                	li	a0,-1
    80002892:	00000097          	auipc	ra,0x0
    80002896:	90c080e7          	jalr	-1780(ra) # 8000219e <exit>
  if(which_dev == 2)
    8000289a:	4789                	li	a5,2
    8000289c:	04f90f63          	beq	s2,a5,800028fa <usertrap+0x106>
  usertrapret();
    800028a0:	00000097          	auipc	ra,0x0
    800028a4:	dd6080e7          	jalr	-554(ra) # 80002676 <usertrapret>
}
    800028a8:	60e2                	ld	ra,24(sp)
    800028aa:	6442                	ld	s0,16(sp)
    800028ac:	64a2                	ld	s1,8(sp)
    800028ae:	6902                	ld	s2,0(sp)
    800028b0:	6105                	addi	sp,sp,32
    800028b2:	8082                	ret
      exit(-1);
    800028b4:	557d                	li	a0,-1
    800028b6:	00000097          	auipc	ra,0x0
    800028ba:	8e8080e7          	jalr	-1816(ra) # 8000219e <exit>
    800028be:	b765                	j	80002866 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028c4:	5890                	lw	a2,48(s1)
    800028c6:	00006517          	auipc	a0,0x6
    800028ca:	a7a50513          	addi	a0,a0,-1414 # 80008340 <states.1722+0x78>
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	cc0080e7          	jalr	-832(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028d6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028da:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028de:	00006517          	auipc	a0,0x6
    800028e2:	a9250513          	addi	a0,a0,-1390 # 80008370 <states.1722+0xa8>
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	ca8080e7          	jalr	-856(ra) # 8000058e <printf>
    setkilled(p);
    800028ee:	8526                	mv	a0,s1
    800028f0:	00000097          	auipc	ra,0x0
    800028f4:	9f6080e7          	jalr	-1546(ra) # 800022e6 <setkilled>
    800028f8:	b769                	j	80002882 <usertrap+0x8e>
    yield();
    800028fa:	fffff097          	auipc	ra,0xfffff
    800028fe:	734080e7          	jalr	1844(ra) # 8000202e <yield>
    80002902:	bf79                	j	800028a0 <usertrap+0xac>

0000000080002904 <kerneltrap>:
{
    80002904:	7179                	addi	sp,sp,-48
    80002906:	f406                	sd	ra,40(sp)
    80002908:	f022                	sd	s0,32(sp)
    8000290a:	ec26                	sd	s1,24(sp)
    8000290c:	e84a                	sd	s2,16(sp)
    8000290e:	e44e                	sd	s3,8(sp)
    80002910:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002912:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002916:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000291a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000291e:	1004f793          	andi	a5,s1,256
    80002922:	cb85                	beqz	a5,80002952 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002924:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002928:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000292a:	ef85                	bnez	a5,80002962 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	e26080e7          	jalr	-474(ra) # 80002752 <devintr>
    80002934:	cd1d                	beqz	a0,80002972 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002936:	4789                	li	a5,2
    80002938:	06f50a63          	beq	a0,a5,800029ac <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000293c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002940:	10049073          	csrw	sstatus,s1
}
    80002944:	70a2                	ld	ra,40(sp)
    80002946:	7402                	ld	s0,32(sp)
    80002948:	64e2                	ld	s1,24(sp)
    8000294a:	6942                	ld	s2,16(sp)
    8000294c:	69a2                	ld	s3,8(sp)
    8000294e:	6145                	addi	sp,sp,48
    80002950:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002952:	00006517          	auipc	a0,0x6
    80002956:	a3e50513          	addi	a0,a0,-1474 # 80008390 <states.1722+0xc8>
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	bea080e7          	jalr	-1046(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002962:	00006517          	auipc	a0,0x6
    80002966:	a5650513          	addi	a0,a0,-1450 # 800083b8 <states.1722+0xf0>
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	bda080e7          	jalr	-1062(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002972:	85ce                	mv	a1,s3
    80002974:	00006517          	auipc	a0,0x6
    80002978:	a6450513          	addi	a0,a0,-1436 # 800083d8 <states.1722+0x110>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	c12080e7          	jalr	-1006(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002984:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002988:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000298c:	00006517          	auipc	a0,0x6
    80002990:	a5c50513          	addi	a0,a0,-1444 # 800083e8 <states.1722+0x120>
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	bfa080e7          	jalr	-1030(ra) # 8000058e <printf>
    panic("kerneltrap");
    8000299c:	00006517          	auipc	a0,0x6
    800029a0:	a6450513          	addi	a0,a0,-1436 # 80008400 <states.1722+0x138>
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	ba0080e7          	jalr	-1120(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029ac:	fffff097          	auipc	ra,0xfffff
    800029b0:	01a080e7          	jalr	26(ra) # 800019c6 <myproc>
    800029b4:	d541                	beqz	a0,8000293c <kerneltrap+0x38>
    800029b6:	fffff097          	auipc	ra,0xfffff
    800029ba:	010080e7          	jalr	16(ra) # 800019c6 <myproc>
    800029be:	4d18                	lw	a4,24(a0)
    800029c0:	4791                	li	a5,4
    800029c2:	f6f71de3          	bne	a4,a5,8000293c <kerneltrap+0x38>
    yield();
    800029c6:	fffff097          	auipc	ra,0xfffff
    800029ca:	668080e7          	jalr	1640(ra) # 8000202e <yield>
    800029ce:	b7bd                	j	8000293c <kerneltrap+0x38>

00000000800029d0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029d0:	1101                	addi	sp,sp,-32
    800029d2:	ec06                	sd	ra,24(sp)
    800029d4:	e822                	sd	s0,16(sp)
    800029d6:	e426                	sd	s1,8(sp)
    800029d8:	1000                	addi	s0,sp,32
    800029da:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029dc:	fffff097          	auipc	ra,0xfffff
    800029e0:	fea080e7          	jalr	-22(ra) # 800019c6 <myproc>
  switch (n)
    800029e4:	4795                	li	a5,5
    800029e6:	0497e163          	bltu	a5,s1,80002a28 <argraw+0x58>
    800029ea:	048a                	slli	s1,s1,0x2
    800029ec:	00006717          	auipc	a4,0x6
    800029f0:	a6470713          	addi	a4,a4,-1436 # 80008450 <states.1722+0x188>
    800029f4:	94ba                	add	s1,s1,a4
    800029f6:	409c                	lw	a5,0(s1)
    800029f8:	97ba                	add	a5,a5,a4
    800029fa:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    800029fc:	6d3c                	ld	a5,88(a0)
    800029fe:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a00:	60e2                	ld	ra,24(sp)
    80002a02:	6442                	ld	s0,16(sp)
    80002a04:	64a2                	ld	s1,8(sp)
    80002a06:	6105                	addi	sp,sp,32
    80002a08:	8082                	ret
    return p->trapframe->a1;
    80002a0a:	6d3c                	ld	a5,88(a0)
    80002a0c:	7fa8                	ld	a0,120(a5)
    80002a0e:	bfcd                	j	80002a00 <argraw+0x30>
    return p->trapframe->a2;
    80002a10:	6d3c                	ld	a5,88(a0)
    80002a12:	63c8                	ld	a0,128(a5)
    80002a14:	b7f5                	j	80002a00 <argraw+0x30>
    return p->trapframe->a3;
    80002a16:	6d3c                	ld	a5,88(a0)
    80002a18:	67c8                	ld	a0,136(a5)
    80002a1a:	b7dd                	j	80002a00 <argraw+0x30>
    return p->trapframe->a4;
    80002a1c:	6d3c                	ld	a5,88(a0)
    80002a1e:	6bc8                	ld	a0,144(a5)
    80002a20:	b7c5                	j	80002a00 <argraw+0x30>
    return p->trapframe->a5;
    80002a22:	6d3c                	ld	a5,88(a0)
    80002a24:	6fc8                	ld	a0,152(a5)
    80002a26:	bfe9                	j	80002a00 <argraw+0x30>
  panic("argraw");
    80002a28:	00006517          	auipc	a0,0x6
    80002a2c:	9e850513          	addi	a0,a0,-1560 # 80008410 <states.1722+0x148>
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	b14080e7          	jalr	-1260(ra) # 80000544 <panic>

0000000080002a38 <fetchaddr>:
{
    80002a38:	1101                	addi	sp,sp,-32
    80002a3a:	ec06                	sd	ra,24(sp)
    80002a3c:	e822                	sd	s0,16(sp)
    80002a3e:	e426                	sd	s1,8(sp)
    80002a40:	e04a                	sd	s2,0(sp)
    80002a42:	1000                	addi	s0,sp,32
    80002a44:	84aa                	mv	s1,a0
    80002a46:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	f7e080e7          	jalr	-130(ra) # 800019c6 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a50:	653c                	ld	a5,72(a0)
    80002a52:	02f4f863          	bgeu	s1,a5,80002a82 <fetchaddr+0x4a>
    80002a56:	00848713          	addi	a4,s1,8
    80002a5a:	02e7e663          	bltu	a5,a4,80002a86 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a5e:	46a1                	li	a3,8
    80002a60:	8626                	mv	a2,s1
    80002a62:	85ca                	mv	a1,s2
    80002a64:	6928                	ld	a0,80(a0)
    80002a66:	fffff097          	auipc	ra,0xfffff
    80002a6a:	caa080e7          	jalr	-854(ra) # 80001710 <copyin>
    80002a6e:	00a03533          	snez	a0,a0
    80002a72:	40a00533          	neg	a0,a0
}
    80002a76:	60e2                	ld	ra,24(sp)
    80002a78:	6442                	ld	s0,16(sp)
    80002a7a:	64a2                	ld	s1,8(sp)
    80002a7c:	6902                	ld	s2,0(sp)
    80002a7e:	6105                	addi	sp,sp,32
    80002a80:	8082                	ret
    return -1;
    80002a82:	557d                	li	a0,-1
    80002a84:	bfcd                	j	80002a76 <fetchaddr+0x3e>
    80002a86:	557d                	li	a0,-1
    80002a88:	b7fd                	j	80002a76 <fetchaddr+0x3e>

0000000080002a8a <fetchstr>:
{
    80002a8a:	7179                	addi	sp,sp,-48
    80002a8c:	f406                	sd	ra,40(sp)
    80002a8e:	f022                	sd	s0,32(sp)
    80002a90:	ec26                	sd	s1,24(sp)
    80002a92:	e84a                	sd	s2,16(sp)
    80002a94:	e44e                	sd	s3,8(sp)
    80002a96:	1800                	addi	s0,sp,48
    80002a98:	892a                	mv	s2,a0
    80002a9a:	84ae                	mv	s1,a1
    80002a9c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a9e:	fffff097          	auipc	ra,0xfffff
    80002aa2:	f28080e7          	jalr	-216(ra) # 800019c6 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002aa6:	86ce                	mv	a3,s3
    80002aa8:	864a                	mv	a2,s2
    80002aaa:	85a6                	mv	a1,s1
    80002aac:	6928                	ld	a0,80(a0)
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	cee080e7          	jalr	-786(ra) # 8000179c <copyinstr>
    80002ab6:	00054e63          	bltz	a0,80002ad2 <fetchstr+0x48>
  return strlen(buf);
    80002aba:	8526                	mv	a0,s1
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	3ae080e7          	jalr	942(ra) # 80000e6a <strlen>
}
    80002ac4:	70a2                	ld	ra,40(sp)
    80002ac6:	7402                	ld	s0,32(sp)
    80002ac8:	64e2                	ld	s1,24(sp)
    80002aca:	6942                	ld	s2,16(sp)
    80002acc:	69a2                	ld	s3,8(sp)
    80002ace:	6145                	addi	sp,sp,48
    80002ad0:	8082                	ret
    return -1;
    80002ad2:	557d                	li	a0,-1
    80002ad4:	bfc5                	j	80002ac4 <fetchstr+0x3a>

0000000080002ad6 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002ad6:	1101                	addi	sp,sp,-32
    80002ad8:	ec06                	sd	ra,24(sp)
    80002ada:	e822                	sd	s0,16(sp)
    80002adc:	e426                	sd	s1,8(sp)
    80002ade:	1000                	addi	s0,sp,32
    80002ae0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ae2:	00000097          	auipc	ra,0x0
    80002ae6:	eee080e7          	jalr	-274(ra) # 800029d0 <argraw>
    80002aea:	c088                	sw	a0,0(s1)
}
    80002aec:	60e2                	ld	ra,24(sp)
    80002aee:	6442                	ld	s0,16(sp)
    80002af0:	64a2                	ld	s1,8(sp)
    80002af2:	6105                	addi	sp,sp,32
    80002af4:	8082                	ret

0000000080002af6 <sys_getcnt>:
    [SYS_getcnt] = sys_getcnt,
};

uint64
sys_getcnt(void)
{
    80002af6:	1101                	addi	sp,sp,-32
    80002af8:	ec06                	sd	ra,24(sp)
    80002afa:	e822                	sd	s0,16(sp)
    80002afc:	1000                	addi	s0,sp,32
  int calledProc;

  argint(1, &calledProc);
    80002afe:	fec40593          	addi	a1,s0,-20
    80002b02:	4505                	li	a0,1
    80002b04:	00000097          	auipc	ra,0x0
    80002b08:	fd2080e7          	jalr	-46(ra) # 80002ad6 <argint>

  if (calledProc > 0 && calledProc < NELEM(syscalls) && syscalls[calledProc])
    80002b0c:	fec42583          	lw	a1,-20(s0)
    80002b10:	fff5871b          	addiw	a4,a1,-1
    80002b14:	47d5                	li	a5,21
    80002b16:	02e7e863          	bltu	a5,a4,80002b46 <sys_getcnt+0x50>
    80002b1a:	00359713          	slli	a4,a1,0x3
    80002b1e:	00006797          	auipc	a5,0x6
    80002b22:	94a78793          	addi	a5,a5,-1718 # 80008468 <syscalls>
    80002b26:	97ba                	add	a5,a5,a4
    80002b28:	639c                	ld	a5,0(a5)
    80002b2a:	cf91                	beqz	a5,80002b46 <sys_getcnt+0x50>
  {
    uint64 *value = syscallCounter[calledProc-1];
    80002b2c:	35fd                	addiw	a1,a1,-1
    80002b2e:	058e                	slli	a1,a1,0x3
    80002b30:	00014797          	auipc	a5,0x14
    80002b34:	e8878793          	addi	a5,a5,-376 # 800169b8 <syscallCounter>
    80002b38:	95be                	add	a1,a1,a5
    return *value;
    80002b3a:	619c                	ld	a5,0(a1)
    80002b3c:	6388                	ld	a0,0(a5)
  else
  {
    printf("Unknown sys call %d\n", calledProc);
    return -1;
  }
}
    80002b3e:	60e2                	ld	ra,24(sp)
    80002b40:	6442                	ld	s0,16(sp)
    80002b42:	6105                	addi	sp,sp,32
    80002b44:	8082                	ret
    printf("Unknown sys call %d\n", calledProc);
    80002b46:	00006517          	auipc	a0,0x6
    80002b4a:	8d250513          	addi	a0,a0,-1838 # 80008418 <states.1722+0x150>
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	a40080e7          	jalr	-1472(ra) # 8000058e <printf>
    return -1;
    80002b56:	557d                	li	a0,-1
    80002b58:	b7dd                	j	80002b3e <sys_getcnt+0x48>

0000000080002b5a <argaddr>:
{
    80002b5a:	1101                	addi	sp,sp,-32
    80002b5c:	ec06                	sd	ra,24(sp)
    80002b5e:	e822                	sd	s0,16(sp)
    80002b60:	e426                	sd	s1,8(sp)
    80002b62:	1000                	addi	s0,sp,32
    80002b64:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b66:	00000097          	auipc	ra,0x0
    80002b6a:	e6a080e7          	jalr	-406(ra) # 800029d0 <argraw>
    80002b6e:	e088                	sd	a0,0(s1)
}
    80002b70:	60e2                	ld	ra,24(sp)
    80002b72:	6442                	ld	s0,16(sp)
    80002b74:	64a2                	ld	s1,8(sp)
    80002b76:	6105                	addi	sp,sp,32
    80002b78:	8082                	ret

0000000080002b7a <argstr>:
{
    80002b7a:	7179                	addi	sp,sp,-48
    80002b7c:	f406                	sd	ra,40(sp)
    80002b7e:	f022                	sd	s0,32(sp)
    80002b80:	ec26                	sd	s1,24(sp)
    80002b82:	e84a                	sd	s2,16(sp)
    80002b84:	1800                	addi	s0,sp,48
    80002b86:	84ae                	mv	s1,a1
    80002b88:	8932                	mv	s2,a2
  argaddr(n, &addr);
    80002b8a:	fd840593          	addi	a1,s0,-40
    80002b8e:	00000097          	auipc	ra,0x0
    80002b92:	fcc080e7          	jalr	-52(ra) # 80002b5a <argaddr>
  return fetchstr(addr, buf, max);
    80002b96:	864a                	mv	a2,s2
    80002b98:	85a6                	mv	a1,s1
    80002b9a:	fd843503          	ld	a0,-40(s0)
    80002b9e:	00000097          	auipc	ra,0x0
    80002ba2:	eec080e7          	jalr	-276(ra) # 80002a8a <fetchstr>
}
    80002ba6:	70a2                	ld	ra,40(sp)
    80002ba8:	7402                	ld	s0,32(sp)
    80002baa:	64e2                	ld	s1,24(sp)
    80002bac:	6942                	ld	s2,16(sp)
    80002bae:	6145                	addi	sp,sp,48
    80002bb0:	8082                	ret

0000000080002bb2 <syscall>:

void syscall(void)
{
    80002bb2:	1101                	addi	sp,sp,-32
    80002bb4:	ec06                	sd	ra,24(sp)
    80002bb6:	e822                	sd	s0,16(sp)
    80002bb8:	e426                	sd	s1,8(sp)
    80002bba:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	e0a080e7          	jalr	-502(ra) # 800019c6 <myproc>
    80002bc4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bc6:	6d3c                	ld	a5,88(a0)
    80002bc8:	77dc                	ld	a5,168(a5)
    80002bca:	0007869b          	sext.w	a3,a5
  syscallCounter[num-1]++;
    80002bce:	fff7871b          	addiw	a4,a5,-1
    80002bd2:	00371613          	slli	a2,a4,0x3
    80002bd6:	00014717          	auipc	a4,0x14
    80002bda:	de270713          	addi	a4,a4,-542 # 800169b8 <syscallCounter>
    80002bde:	9732                	add	a4,a4,a2
    80002be0:	6310                	ld	a2,0(a4)
    80002be2:	0621                	addi	a2,a2,8
    80002be4:	e310                	sd	a2,0(a4)
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002be6:	37fd                	addiw	a5,a5,-1
    80002be8:	4755                	li	a4,21
    80002bea:	00f76f63          	bltu	a4,a5,80002c08 <syscall+0x56>
    80002bee:	00369713          	slli	a4,a3,0x3
    80002bf2:	00006797          	auipc	a5,0x6
    80002bf6:	87678793          	addi	a5,a5,-1930 # 80008468 <syscalls>
    80002bfa:	97ba                	add	a5,a5,a4
    80002bfc:	639c                	ld	a5,0(a5)
    80002bfe:	c789                	beqz	a5,80002c08 <syscall+0x56>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c00:	6d24                	ld	s1,88(a0)
    80002c02:	9782                	jalr	a5
    80002c04:	f8a8                	sd	a0,112(s1)
    80002c06:	a839                	j	80002c24 <syscall+0x72>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002c08:	15848613          	addi	a2,s1,344
    80002c0c:	588c                	lw	a1,48(s1)
    80002c0e:	00006517          	auipc	a0,0x6
    80002c12:	82250513          	addi	a0,a0,-2014 # 80008430 <states.1722+0x168>
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	978080e7          	jalr	-1672(ra) # 8000058e <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c1e:	6cbc                	ld	a5,88(s1)
    80002c20:	577d                	li	a4,-1
    80002c22:	fbb8                	sd	a4,112(a5)
  }
}
    80002c24:	60e2                	ld	ra,24(sp)
    80002c26:	6442                	ld	s0,16(sp)
    80002c28:	64a2                	ld	s1,8(sp)
    80002c2a:	6105                	addi	sp,sp,32
    80002c2c:	8082                	ret

0000000080002c2e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c2e:	1101                	addi	sp,sp,-32
    80002c30:	ec06                	sd	ra,24(sp)
    80002c32:	e822                	sd	s0,16(sp)
    80002c34:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c36:	fec40593          	addi	a1,s0,-20
    80002c3a:	4501                	li	a0,0
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	e9a080e7          	jalr	-358(ra) # 80002ad6 <argint>
  exit(n);
    80002c44:	fec42503          	lw	a0,-20(s0)
    80002c48:	fffff097          	auipc	ra,0xfffff
    80002c4c:	556080e7          	jalr	1366(ra) # 8000219e <exit>
  return 0;  // not reached
}
    80002c50:	4501                	li	a0,0
    80002c52:	60e2                	ld	ra,24(sp)
    80002c54:	6442                	ld	s0,16(sp)
    80002c56:	6105                	addi	sp,sp,32
    80002c58:	8082                	ret

0000000080002c5a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c5a:	1141                	addi	sp,sp,-16
    80002c5c:	e406                	sd	ra,8(sp)
    80002c5e:	e022                	sd	s0,0(sp)
    80002c60:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	d64080e7          	jalr	-668(ra) # 800019c6 <myproc>
}
    80002c6a:	5908                	lw	a0,48(a0)
    80002c6c:	60a2                	ld	ra,8(sp)
    80002c6e:	6402                	ld	s0,0(sp)
    80002c70:	0141                	addi	sp,sp,16
    80002c72:	8082                	ret

0000000080002c74 <sys_fork>:

uint64
sys_fork(void)
{
    80002c74:	1141                	addi	sp,sp,-16
    80002c76:	e406                	sd	ra,8(sp)
    80002c78:	e022                	sd	s0,0(sp)
    80002c7a:	0800                	addi	s0,sp,16
  return fork();
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	100080e7          	jalr	256(ra) # 80001d7c <fork>
}
    80002c84:	60a2                	ld	ra,8(sp)
    80002c86:	6402                	ld	s0,0(sp)
    80002c88:	0141                	addi	sp,sp,16
    80002c8a:	8082                	ret

0000000080002c8c <sys_wait>:

uint64
sys_wait(void)
{
    80002c8c:	1101                	addi	sp,sp,-32
    80002c8e:	ec06                	sd	ra,24(sp)
    80002c90:	e822                	sd	s0,16(sp)
    80002c92:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c94:	fe840593          	addi	a1,s0,-24
    80002c98:	4501                	li	a0,0
    80002c9a:	00000097          	auipc	ra,0x0
    80002c9e:	ec0080e7          	jalr	-320(ra) # 80002b5a <argaddr>
  return wait(p);
    80002ca2:	fe843503          	ld	a0,-24(s0)
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	69e080e7          	jalr	1694(ra) # 80002344 <wait>
}
    80002cae:	60e2                	ld	ra,24(sp)
    80002cb0:	6442                	ld	s0,16(sp)
    80002cb2:	6105                	addi	sp,sp,32
    80002cb4:	8082                	ret

0000000080002cb6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cb6:	7179                	addi	sp,sp,-48
    80002cb8:	f406                	sd	ra,40(sp)
    80002cba:	f022                	sd	s0,32(sp)
    80002cbc:	ec26                	sd	s1,24(sp)
    80002cbe:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002cc0:	fdc40593          	addi	a1,s0,-36
    80002cc4:	4501                	li	a0,0
    80002cc6:	00000097          	auipc	ra,0x0
    80002cca:	e10080e7          	jalr	-496(ra) # 80002ad6 <argint>
  addr = myproc()->sz;
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	cf8080e7          	jalr	-776(ra) # 800019c6 <myproc>
    80002cd6:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002cd8:	fdc42503          	lw	a0,-36(s0)
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	044080e7          	jalr	68(ra) # 80001d20 <growproc>
    80002ce4:	00054863          	bltz	a0,80002cf4 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002ce8:	8526                	mv	a0,s1
    80002cea:	70a2                	ld	ra,40(sp)
    80002cec:	7402                	ld	s0,32(sp)
    80002cee:	64e2                	ld	s1,24(sp)
    80002cf0:	6145                	addi	sp,sp,48
    80002cf2:	8082                	ret
    return -1;
    80002cf4:	54fd                	li	s1,-1
    80002cf6:	bfcd                	j	80002ce8 <sys_sbrk+0x32>

0000000080002cf8 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cf8:	7139                	addi	sp,sp,-64
    80002cfa:	fc06                	sd	ra,56(sp)
    80002cfc:	f822                	sd	s0,48(sp)
    80002cfe:	f426                	sd	s1,40(sp)
    80002d00:	f04a                	sd	s2,32(sp)
    80002d02:	ec4e                	sd	s3,24(sp)
    80002d04:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d06:	fcc40593          	addi	a1,s0,-52
    80002d0a:	4501                	li	a0,0
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	dca080e7          	jalr	-566(ra) # 80002ad6 <argint>
  acquire(&tickslock);
    80002d14:	00014517          	auipc	a0,0x14
    80002d18:	c8c50513          	addi	a0,a0,-884 # 800169a0 <tickslock>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	ece080e7          	jalr	-306(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002d24:	00006917          	auipc	s2,0x6
    80002d28:	bdc92903          	lw	s2,-1060(s2) # 80008900 <ticks>
  while(ticks - ticks0 < n){
    80002d2c:	fcc42783          	lw	a5,-52(s0)
    80002d30:	cf9d                	beqz	a5,80002d6e <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d32:	00014997          	auipc	s3,0x14
    80002d36:	c6e98993          	addi	s3,s3,-914 # 800169a0 <tickslock>
    80002d3a:	00006497          	auipc	s1,0x6
    80002d3e:	bc648493          	addi	s1,s1,-1082 # 80008900 <ticks>
    if(killed(myproc())){
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	c84080e7          	jalr	-892(ra) # 800019c6 <myproc>
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	5c8080e7          	jalr	1480(ra) # 80002312 <killed>
    80002d52:	ed15                	bnez	a0,80002d8e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d54:	85ce                	mv	a1,s3
    80002d56:	8526                	mv	a0,s1
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	312080e7          	jalr	786(ra) # 8000206a <sleep>
  while(ticks - ticks0 < n){
    80002d60:	409c                	lw	a5,0(s1)
    80002d62:	412787bb          	subw	a5,a5,s2
    80002d66:	fcc42703          	lw	a4,-52(s0)
    80002d6a:	fce7ece3          	bltu	a5,a4,80002d42 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d6e:	00014517          	auipc	a0,0x14
    80002d72:	c3250513          	addi	a0,a0,-974 # 800169a0 <tickslock>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	f28080e7          	jalr	-216(ra) # 80000c9e <release>
  return 0;
    80002d7e:	4501                	li	a0,0
}
    80002d80:	70e2                	ld	ra,56(sp)
    80002d82:	7442                	ld	s0,48(sp)
    80002d84:	74a2                	ld	s1,40(sp)
    80002d86:	7902                	ld	s2,32(sp)
    80002d88:	69e2                	ld	s3,24(sp)
    80002d8a:	6121                	addi	sp,sp,64
    80002d8c:	8082                	ret
      release(&tickslock);
    80002d8e:	00014517          	auipc	a0,0x14
    80002d92:	c1250513          	addi	a0,a0,-1006 # 800169a0 <tickslock>
    80002d96:	ffffe097          	auipc	ra,0xffffe
    80002d9a:	f08080e7          	jalr	-248(ra) # 80000c9e <release>
      return -1;
    80002d9e:	557d                	li	a0,-1
    80002da0:	b7c5                	j	80002d80 <sys_sleep+0x88>

0000000080002da2 <sys_kill>:

uint64
sys_kill(void)
{
    80002da2:	1101                	addi	sp,sp,-32
    80002da4:	ec06                	sd	ra,24(sp)
    80002da6:	e822                	sd	s0,16(sp)
    80002da8:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002daa:	fec40593          	addi	a1,s0,-20
    80002dae:	4501                	li	a0,0
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	d26080e7          	jalr	-730(ra) # 80002ad6 <argint>
  return kill(pid);
    80002db8:	fec42503          	lw	a0,-20(s0)
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	4b8080e7          	jalr	1208(ra) # 80002274 <kill>
}
    80002dc4:	60e2                	ld	ra,24(sp)
    80002dc6:	6442                	ld	s0,16(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret

0000000080002dcc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	e426                	sd	s1,8(sp)
    80002dd4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dd6:	00014517          	auipc	a0,0x14
    80002dda:	bca50513          	addi	a0,a0,-1078 # 800169a0 <tickslock>
    80002dde:	ffffe097          	auipc	ra,0xffffe
    80002de2:	e0c080e7          	jalr	-500(ra) # 80000bea <acquire>
  xticks = ticks;
    80002de6:	00006497          	auipc	s1,0x6
    80002dea:	b1a4a483          	lw	s1,-1254(s1) # 80008900 <ticks>
  release(&tickslock);
    80002dee:	00014517          	auipc	a0,0x14
    80002df2:	bb250513          	addi	a0,a0,-1102 # 800169a0 <tickslock>
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	ea8080e7          	jalr	-344(ra) # 80000c9e <release>
  return xticks;
}
    80002dfe:	02049513          	slli	a0,s1,0x20
    80002e02:	9101                	srli	a0,a0,0x20
    80002e04:	60e2                	ld	ra,24(sp)
    80002e06:	6442                	ld	s0,16(sp)
    80002e08:	64a2                	ld	s1,8(sp)
    80002e0a:	6105                	addi	sp,sp,32
    80002e0c:	8082                	ret

0000000080002e0e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e0e:	7179                	addi	sp,sp,-48
    80002e10:	f406                	sd	ra,40(sp)
    80002e12:	f022                	sd	s0,32(sp)
    80002e14:	ec26                	sd	s1,24(sp)
    80002e16:	e84a                	sd	s2,16(sp)
    80002e18:	e44e                	sd	s3,8(sp)
    80002e1a:	e052                	sd	s4,0(sp)
    80002e1c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e1e:	00005597          	auipc	a1,0x5
    80002e22:	70258593          	addi	a1,a1,1794 # 80008520 <syscalls+0xb8>
    80002e26:	00014517          	auipc	a0,0x14
    80002e2a:	c3a50513          	addi	a0,a0,-966 # 80016a60 <bcache>
    80002e2e:	ffffe097          	auipc	ra,0xffffe
    80002e32:	d2c080e7          	jalr	-724(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e36:	0001c797          	auipc	a5,0x1c
    80002e3a:	c2a78793          	addi	a5,a5,-982 # 8001ea60 <bcache+0x8000>
    80002e3e:	0001c717          	auipc	a4,0x1c
    80002e42:	e8a70713          	addi	a4,a4,-374 # 8001ecc8 <bcache+0x8268>
    80002e46:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e4a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e4e:	00014497          	auipc	s1,0x14
    80002e52:	c2a48493          	addi	s1,s1,-982 # 80016a78 <bcache+0x18>
    b->next = bcache.head.next;
    80002e56:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e58:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e5a:	00005a17          	auipc	s4,0x5
    80002e5e:	6cea0a13          	addi	s4,s4,1742 # 80008528 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002e62:	2b893783          	ld	a5,696(s2)
    80002e66:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e68:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e6c:	85d2                	mv	a1,s4
    80002e6e:	01048513          	addi	a0,s1,16
    80002e72:	00001097          	auipc	ra,0x1
    80002e76:	4c4080e7          	jalr	1220(ra) # 80004336 <initsleeplock>
    bcache.head.next->prev = b;
    80002e7a:	2b893783          	ld	a5,696(s2)
    80002e7e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e80:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e84:	45848493          	addi	s1,s1,1112
    80002e88:	fd349de3          	bne	s1,s3,80002e62 <binit+0x54>
  }
}
    80002e8c:	70a2                	ld	ra,40(sp)
    80002e8e:	7402                	ld	s0,32(sp)
    80002e90:	64e2                	ld	s1,24(sp)
    80002e92:	6942                	ld	s2,16(sp)
    80002e94:	69a2                	ld	s3,8(sp)
    80002e96:	6a02                	ld	s4,0(sp)
    80002e98:	6145                	addi	sp,sp,48
    80002e9a:	8082                	ret

0000000080002e9c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e9c:	7179                	addi	sp,sp,-48
    80002e9e:	f406                	sd	ra,40(sp)
    80002ea0:	f022                	sd	s0,32(sp)
    80002ea2:	ec26                	sd	s1,24(sp)
    80002ea4:	e84a                	sd	s2,16(sp)
    80002ea6:	e44e                	sd	s3,8(sp)
    80002ea8:	1800                	addi	s0,sp,48
    80002eaa:	89aa                	mv	s3,a0
    80002eac:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002eae:	00014517          	auipc	a0,0x14
    80002eb2:	bb250513          	addi	a0,a0,-1102 # 80016a60 <bcache>
    80002eb6:	ffffe097          	auipc	ra,0xffffe
    80002eba:	d34080e7          	jalr	-716(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ebe:	0001c497          	auipc	s1,0x1c
    80002ec2:	e5a4b483          	ld	s1,-422(s1) # 8001ed18 <bcache+0x82b8>
    80002ec6:	0001c797          	auipc	a5,0x1c
    80002eca:	e0278793          	addi	a5,a5,-510 # 8001ecc8 <bcache+0x8268>
    80002ece:	02f48f63          	beq	s1,a5,80002f0c <bread+0x70>
    80002ed2:	873e                	mv	a4,a5
    80002ed4:	a021                	j	80002edc <bread+0x40>
    80002ed6:	68a4                	ld	s1,80(s1)
    80002ed8:	02e48a63          	beq	s1,a4,80002f0c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002edc:	449c                	lw	a5,8(s1)
    80002ede:	ff379ce3          	bne	a5,s3,80002ed6 <bread+0x3a>
    80002ee2:	44dc                	lw	a5,12(s1)
    80002ee4:	ff2799e3          	bne	a5,s2,80002ed6 <bread+0x3a>
      b->refcnt++;
    80002ee8:	40bc                	lw	a5,64(s1)
    80002eea:	2785                	addiw	a5,a5,1
    80002eec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002eee:	00014517          	auipc	a0,0x14
    80002ef2:	b7250513          	addi	a0,a0,-1166 # 80016a60 <bcache>
    80002ef6:	ffffe097          	auipc	ra,0xffffe
    80002efa:	da8080e7          	jalr	-600(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80002efe:	01048513          	addi	a0,s1,16
    80002f02:	00001097          	auipc	ra,0x1
    80002f06:	46e080e7          	jalr	1134(ra) # 80004370 <acquiresleep>
      return b;
    80002f0a:	a8b9                	j	80002f68 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f0c:	0001c497          	auipc	s1,0x1c
    80002f10:	e044b483          	ld	s1,-508(s1) # 8001ed10 <bcache+0x82b0>
    80002f14:	0001c797          	auipc	a5,0x1c
    80002f18:	db478793          	addi	a5,a5,-588 # 8001ecc8 <bcache+0x8268>
    80002f1c:	00f48863          	beq	s1,a5,80002f2c <bread+0x90>
    80002f20:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f22:	40bc                	lw	a5,64(s1)
    80002f24:	cf81                	beqz	a5,80002f3c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f26:	64a4                	ld	s1,72(s1)
    80002f28:	fee49de3          	bne	s1,a4,80002f22 <bread+0x86>
  panic("bget: no buffers");
    80002f2c:	00005517          	auipc	a0,0x5
    80002f30:	60450513          	addi	a0,a0,1540 # 80008530 <syscalls+0xc8>
    80002f34:	ffffd097          	auipc	ra,0xffffd
    80002f38:	610080e7          	jalr	1552(ra) # 80000544 <panic>
      b->dev = dev;
    80002f3c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002f40:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f44:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f48:	4785                	li	a5,1
    80002f4a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f4c:	00014517          	auipc	a0,0x14
    80002f50:	b1450513          	addi	a0,a0,-1260 # 80016a60 <bcache>
    80002f54:	ffffe097          	auipc	ra,0xffffe
    80002f58:	d4a080e7          	jalr	-694(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80002f5c:	01048513          	addi	a0,s1,16
    80002f60:	00001097          	auipc	ra,0x1
    80002f64:	410080e7          	jalr	1040(ra) # 80004370 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f68:	409c                	lw	a5,0(s1)
    80002f6a:	cb89                	beqz	a5,80002f7c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f6c:	8526                	mv	a0,s1
    80002f6e:	70a2                	ld	ra,40(sp)
    80002f70:	7402                	ld	s0,32(sp)
    80002f72:	64e2                	ld	s1,24(sp)
    80002f74:	6942                	ld	s2,16(sp)
    80002f76:	69a2                	ld	s3,8(sp)
    80002f78:	6145                	addi	sp,sp,48
    80002f7a:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f7c:	4581                	li	a1,0
    80002f7e:	8526                	mv	a0,s1
    80002f80:	00003097          	auipc	ra,0x3
    80002f84:	fc8080e7          	jalr	-56(ra) # 80005f48 <virtio_disk_rw>
    b->valid = 1;
    80002f88:	4785                	li	a5,1
    80002f8a:	c09c                	sw	a5,0(s1)
  return b;
    80002f8c:	b7c5                	j	80002f6c <bread+0xd0>

0000000080002f8e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f8e:	1101                	addi	sp,sp,-32
    80002f90:	ec06                	sd	ra,24(sp)
    80002f92:	e822                	sd	s0,16(sp)
    80002f94:	e426                	sd	s1,8(sp)
    80002f96:	1000                	addi	s0,sp,32
    80002f98:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f9a:	0541                	addi	a0,a0,16
    80002f9c:	00001097          	auipc	ra,0x1
    80002fa0:	46e080e7          	jalr	1134(ra) # 8000440a <holdingsleep>
    80002fa4:	cd01                	beqz	a0,80002fbc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fa6:	4585                	li	a1,1
    80002fa8:	8526                	mv	a0,s1
    80002faa:	00003097          	auipc	ra,0x3
    80002fae:	f9e080e7          	jalr	-98(ra) # 80005f48 <virtio_disk_rw>
}
    80002fb2:	60e2                	ld	ra,24(sp)
    80002fb4:	6442                	ld	s0,16(sp)
    80002fb6:	64a2                	ld	s1,8(sp)
    80002fb8:	6105                	addi	sp,sp,32
    80002fba:	8082                	ret
    panic("bwrite");
    80002fbc:	00005517          	auipc	a0,0x5
    80002fc0:	58c50513          	addi	a0,a0,1420 # 80008548 <syscalls+0xe0>
    80002fc4:	ffffd097          	auipc	ra,0xffffd
    80002fc8:	580080e7          	jalr	1408(ra) # 80000544 <panic>

0000000080002fcc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fcc:	1101                	addi	sp,sp,-32
    80002fce:	ec06                	sd	ra,24(sp)
    80002fd0:	e822                	sd	s0,16(sp)
    80002fd2:	e426                	sd	s1,8(sp)
    80002fd4:	e04a                	sd	s2,0(sp)
    80002fd6:	1000                	addi	s0,sp,32
    80002fd8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fda:	01050913          	addi	s2,a0,16
    80002fde:	854a                	mv	a0,s2
    80002fe0:	00001097          	auipc	ra,0x1
    80002fe4:	42a080e7          	jalr	1066(ra) # 8000440a <holdingsleep>
    80002fe8:	c92d                	beqz	a0,8000305a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fea:	854a                	mv	a0,s2
    80002fec:	00001097          	auipc	ra,0x1
    80002ff0:	3da080e7          	jalr	986(ra) # 800043c6 <releasesleep>

  acquire(&bcache.lock);
    80002ff4:	00014517          	auipc	a0,0x14
    80002ff8:	a6c50513          	addi	a0,a0,-1428 # 80016a60 <bcache>
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	bee080e7          	jalr	-1042(ra) # 80000bea <acquire>
  b->refcnt--;
    80003004:	40bc                	lw	a5,64(s1)
    80003006:	37fd                	addiw	a5,a5,-1
    80003008:	0007871b          	sext.w	a4,a5
    8000300c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000300e:	eb05                	bnez	a4,8000303e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003010:	68bc                	ld	a5,80(s1)
    80003012:	64b8                	ld	a4,72(s1)
    80003014:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003016:	64bc                	ld	a5,72(s1)
    80003018:	68b8                	ld	a4,80(s1)
    8000301a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000301c:	0001c797          	auipc	a5,0x1c
    80003020:	a4478793          	addi	a5,a5,-1468 # 8001ea60 <bcache+0x8000>
    80003024:	2b87b703          	ld	a4,696(a5)
    80003028:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000302a:	0001c717          	auipc	a4,0x1c
    8000302e:	c9e70713          	addi	a4,a4,-866 # 8001ecc8 <bcache+0x8268>
    80003032:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003034:	2b87b703          	ld	a4,696(a5)
    80003038:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000303a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000303e:	00014517          	auipc	a0,0x14
    80003042:	a2250513          	addi	a0,a0,-1502 # 80016a60 <bcache>
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	c58080e7          	jalr	-936(ra) # 80000c9e <release>
}
    8000304e:	60e2                	ld	ra,24(sp)
    80003050:	6442                	ld	s0,16(sp)
    80003052:	64a2                	ld	s1,8(sp)
    80003054:	6902                	ld	s2,0(sp)
    80003056:	6105                	addi	sp,sp,32
    80003058:	8082                	ret
    panic("brelse");
    8000305a:	00005517          	auipc	a0,0x5
    8000305e:	4f650513          	addi	a0,a0,1270 # 80008550 <syscalls+0xe8>
    80003062:	ffffd097          	auipc	ra,0xffffd
    80003066:	4e2080e7          	jalr	1250(ra) # 80000544 <panic>

000000008000306a <bpin>:

void
bpin(struct buf *b) {
    8000306a:	1101                	addi	sp,sp,-32
    8000306c:	ec06                	sd	ra,24(sp)
    8000306e:	e822                	sd	s0,16(sp)
    80003070:	e426                	sd	s1,8(sp)
    80003072:	1000                	addi	s0,sp,32
    80003074:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003076:	00014517          	auipc	a0,0x14
    8000307a:	9ea50513          	addi	a0,a0,-1558 # 80016a60 <bcache>
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	b6c080e7          	jalr	-1172(ra) # 80000bea <acquire>
  b->refcnt++;
    80003086:	40bc                	lw	a5,64(s1)
    80003088:	2785                	addiw	a5,a5,1
    8000308a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000308c:	00014517          	auipc	a0,0x14
    80003090:	9d450513          	addi	a0,a0,-1580 # 80016a60 <bcache>
    80003094:	ffffe097          	auipc	ra,0xffffe
    80003098:	c0a080e7          	jalr	-1014(ra) # 80000c9e <release>
}
    8000309c:	60e2                	ld	ra,24(sp)
    8000309e:	6442                	ld	s0,16(sp)
    800030a0:	64a2                	ld	s1,8(sp)
    800030a2:	6105                	addi	sp,sp,32
    800030a4:	8082                	ret

00000000800030a6 <bunpin>:

void
bunpin(struct buf *b) {
    800030a6:	1101                	addi	sp,sp,-32
    800030a8:	ec06                	sd	ra,24(sp)
    800030aa:	e822                	sd	s0,16(sp)
    800030ac:	e426                	sd	s1,8(sp)
    800030ae:	1000                	addi	s0,sp,32
    800030b0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030b2:	00014517          	auipc	a0,0x14
    800030b6:	9ae50513          	addi	a0,a0,-1618 # 80016a60 <bcache>
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	b30080e7          	jalr	-1232(ra) # 80000bea <acquire>
  b->refcnt--;
    800030c2:	40bc                	lw	a5,64(s1)
    800030c4:	37fd                	addiw	a5,a5,-1
    800030c6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030c8:	00014517          	auipc	a0,0x14
    800030cc:	99850513          	addi	a0,a0,-1640 # 80016a60 <bcache>
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	bce080e7          	jalr	-1074(ra) # 80000c9e <release>
}
    800030d8:	60e2                	ld	ra,24(sp)
    800030da:	6442                	ld	s0,16(sp)
    800030dc:	64a2                	ld	s1,8(sp)
    800030de:	6105                	addi	sp,sp,32
    800030e0:	8082                	ret

00000000800030e2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030e2:	1101                	addi	sp,sp,-32
    800030e4:	ec06                	sd	ra,24(sp)
    800030e6:	e822                	sd	s0,16(sp)
    800030e8:	e426                	sd	s1,8(sp)
    800030ea:	e04a                	sd	s2,0(sp)
    800030ec:	1000                	addi	s0,sp,32
    800030ee:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030f0:	00d5d59b          	srliw	a1,a1,0xd
    800030f4:	0001c797          	auipc	a5,0x1c
    800030f8:	0487a783          	lw	a5,72(a5) # 8001f13c <sb+0x1c>
    800030fc:	9dbd                	addw	a1,a1,a5
    800030fe:	00000097          	auipc	ra,0x0
    80003102:	d9e080e7          	jalr	-610(ra) # 80002e9c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003106:	0074f713          	andi	a4,s1,7
    8000310a:	4785                	li	a5,1
    8000310c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003110:	14ce                	slli	s1,s1,0x33
    80003112:	90d9                	srli	s1,s1,0x36
    80003114:	00950733          	add	a4,a0,s1
    80003118:	05874703          	lbu	a4,88(a4)
    8000311c:	00e7f6b3          	and	a3,a5,a4
    80003120:	c69d                	beqz	a3,8000314e <bfree+0x6c>
    80003122:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003124:	94aa                	add	s1,s1,a0
    80003126:	fff7c793          	not	a5,a5
    8000312a:	8ff9                	and	a5,a5,a4
    8000312c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003130:	00001097          	auipc	ra,0x1
    80003134:	120080e7          	jalr	288(ra) # 80004250 <log_write>
  brelse(bp);
    80003138:	854a                	mv	a0,s2
    8000313a:	00000097          	auipc	ra,0x0
    8000313e:	e92080e7          	jalr	-366(ra) # 80002fcc <brelse>
}
    80003142:	60e2                	ld	ra,24(sp)
    80003144:	6442                	ld	s0,16(sp)
    80003146:	64a2                	ld	s1,8(sp)
    80003148:	6902                	ld	s2,0(sp)
    8000314a:	6105                	addi	sp,sp,32
    8000314c:	8082                	ret
    panic("freeing free block");
    8000314e:	00005517          	auipc	a0,0x5
    80003152:	40a50513          	addi	a0,a0,1034 # 80008558 <syscalls+0xf0>
    80003156:	ffffd097          	auipc	ra,0xffffd
    8000315a:	3ee080e7          	jalr	1006(ra) # 80000544 <panic>

000000008000315e <balloc>:
{
    8000315e:	711d                	addi	sp,sp,-96
    80003160:	ec86                	sd	ra,88(sp)
    80003162:	e8a2                	sd	s0,80(sp)
    80003164:	e4a6                	sd	s1,72(sp)
    80003166:	e0ca                	sd	s2,64(sp)
    80003168:	fc4e                	sd	s3,56(sp)
    8000316a:	f852                	sd	s4,48(sp)
    8000316c:	f456                	sd	s5,40(sp)
    8000316e:	f05a                	sd	s6,32(sp)
    80003170:	ec5e                	sd	s7,24(sp)
    80003172:	e862                	sd	s8,16(sp)
    80003174:	e466                	sd	s9,8(sp)
    80003176:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003178:	0001c797          	auipc	a5,0x1c
    8000317c:	fac7a783          	lw	a5,-84(a5) # 8001f124 <sb+0x4>
    80003180:	10078163          	beqz	a5,80003282 <balloc+0x124>
    80003184:	8baa                	mv	s7,a0
    80003186:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003188:	0001cb17          	auipc	s6,0x1c
    8000318c:	f98b0b13          	addi	s6,s6,-104 # 8001f120 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003190:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003192:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003194:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003196:	6c89                	lui	s9,0x2
    80003198:	a061                	j	80003220 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000319a:	974a                	add	a4,a4,s2
    8000319c:	8fd5                	or	a5,a5,a3
    8000319e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800031a2:	854a                	mv	a0,s2
    800031a4:	00001097          	auipc	ra,0x1
    800031a8:	0ac080e7          	jalr	172(ra) # 80004250 <log_write>
        brelse(bp);
    800031ac:	854a                	mv	a0,s2
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	e1e080e7          	jalr	-482(ra) # 80002fcc <brelse>
  bp = bread(dev, bno);
    800031b6:	85a6                	mv	a1,s1
    800031b8:	855e                	mv	a0,s7
    800031ba:	00000097          	auipc	ra,0x0
    800031be:	ce2080e7          	jalr	-798(ra) # 80002e9c <bread>
    800031c2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031c4:	40000613          	li	a2,1024
    800031c8:	4581                	li	a1,0
    800031ca:	05850513          	addi	a0,a0,88
    800031ce:	ffffe097          	auipc	ra,0xffffe
    800031d2:	b18080e7          	jalr	-1256(ra) # 80000ce6 <memset>
  log_write(bp);
    800031d6:	854a                	mv	a0,s2
    800031d8:	00001097          	auipc	ra,0x1
    800031dc:	078080e7          	jalr	120(ra) # 80004250 <log_write>
  brelse(bp);
    800031e0:	854a                	mv	a0,s2
    800031e2:	00000097          	auipc	ra,0x0
    800031e6:	dea080e7          	jalr	-534(ra) # 80002fcc <brelse>
}
    800031ea:	8526                	mv	a0,s1
    800031ec:	60e6                	ld	ra,88(sp)
    800031ee:	6446                	ld	s0,80(sp)
    800031f0:	64a6                	ld	s1,72(sp)
    800031f2:	6906                	ld	s2,64(sp)
    800031f4:	79e2                	ld	s3,56(sp)
    800031f6:	7a42                	ld	s4,48(sp)
    800031f8:	7aa2                	ld	s5,40(sp)
    800031fa:	7b02                	ld	s6,32(sp)
    800031fc:	6be2                	ld	s7,24(sp)
    800031fe:	6c42                	ld	s8,16(sp)
    80003200:	6ca2                	ld	s9,8(sp)
    80003202:	6125                	addi	sp,sp,96
    80003204:	8082                	ret
    brelse(bp);
    80003206:	854a                	mv	a0,s2
    80003208:	00000097          	auipc	ra,0x0
    8000320c:	dc4080e7          	jalr	-572(ra) # 80002fcc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003210:	015c87bb          	addw	a5,s9,s5
    80003214:	00078a9b          	sext.w	s5,a5
    80003218:	004b2703          	lw	a4,4(s6)
    8000321c:	06eaf363          	bgeu	s5,a4,80003282 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003220:	41fad79b          	sraiw	a5,s5,0x1f
    80003224:	0137d79b          	srliw	a5,a5,0x13
    80003228:	015787bb          	addw	a5,a5,s5
    8000322c:	40d7d79b          	sraiw	a5,a5,0xd
    80003230:	01cb2583          	lw	a1,28(s6)
    80003234:	9dbd                	addw	a1,a1,a5
    80003236:	855e                	mv	a0,s7
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	c64080e7          	jalr	-924(ra) # 80002e9c <bread>
    80003240:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003242:	004b2503          	lw	a0,4(s6)
    80003246:	000a849b          	sext.w	s1,s5
    8000324a:	8662                	mv	a2,s8
    8000324c:	faa4fde3          	bgeu	s1,a0,80003206 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003250:	41f6579b          	sraiw	a5,a2,0x1f
    80003254:	01d7d69b          	srliw	a3,a5,0x1d
    80003258:	00c6873b          	addw	a4,a3,a2
    8000325c:	00777793          	andi	a5,a4,7
    80003260:	9f95                	subw	a5,a5,a3
    80003262:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003266:	4037571b          	sraiw	a4,a4,0x3
    8000326a:	00e906b3          	add	a3,s2,a4
    8000326e:	0586c683          	lbu	a3,88(a3)
    80003272:	00d7f5b3          	and	a1,a5,a3
    80003276:	d195                	beqz	a1,8000319a <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003278:	2605                	addiw	a2,a2,1
    8000327a:	2485                	addiw	s1,s1,1
    8000327c:	fd4618e3          	bne	a2,s4,8000324c <balloc+0xee>
    80003280:	b759                	j	80003206 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003282:	00005517          	auipc	a0,0x5
    80003286:	2ee50513          	addi	a0,a0,750 # 80008570 <syscalls+0x108>
    8000328a:	ffffd097          	auipc	ra,0xffffd
    8000328e:	304080e7          	jalr	772(ra) # 8000058e <printf>
  return 0;
    80003292:	4481                	li	s1,0
    80003294:	bf99                	j	800031ea <balloc+0x8c>

0000000080003296 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003296:	7179                	addi	sp,sp,-48
    80003298:	f406                	sd	ra,40(sp)
    8000329a:	f022                	sd	s0,32(sp)
    8000329c:	ec26                	sd	s1,24(sp)
    8000329e:	e84a                	sd	s2,16(sp)
    800032a0:	e44e                	sd	s3,8(sp)
    800032a2:	e052                	sd	s4,0(sp)
    800032a4:	1800                	addi	s0,sp,48
    800032a6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032a8:	47ad                	li	a5,11
    800032aa:	02b7e763          	bltu	a5,a1,800032d8 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800032ae:	02059493          	slli	s1,a1,0x20
    800032b2:	9081                	srli	s1,s1,0x20
    800032b4:	048a                	slli	s1,s1,0x2
    800032b6:	94aa                	add	s1,s1,a0
    800032b8:	0504a903          	lw	s2,80(s1)
    800032bc:	06091e63          	bnez	s2,80003338 <bmap+0xa2>
      addr = balloc(ip->dev);
    800032c0:	4108                	lw	a0,0(a0)
    800032c2:	00000097          	auipc	ra,0x0
    800032c6:	e9c080e7          	jalr	-356(ra) # 8000315e <balloc>
    800032ca:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032ce:	06090563          	beqz	s2,80003338 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800032d2:	0524a823          	sw	s2,80(s1)
    800032d6:	a08d                	j	80003338 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800032d8:	ff45849b          	addiw	s1,a1,-12
    800032dc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032e0:	0ff00793          	li	a5,255
    800032e4:	08e7e563          	bltu	a5,a4,8000336e <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800032e8:	08052903          	lw	s2,128(a0)
    800032ec:	00091d63          	bnez	s2,80003306 <bmap+0x70>
      addr = balloc(ip->dev);
    800032f0:	4108                	lw	a0,0(a0)
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	e6c080e7          	jalr	-404(ra) # 8000315e <balloc>
    800032fa:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032fe:	02090d63          	beqz	s2,80003338 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003302:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003306:	85ca                	mv	a1,s2
    80003308:	0009a503          	lw	a0,0(s3)
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	b90080e7          	jalr	-1136(ra) # 80002e9c <bread>
    80003314:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003316:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000331a:	02049593          	slli	a1,s1,0x20
    8000331e:	9181                	srli	a1,a1,0x20
    80003320:	058a                	slli	a1,a1,0x2
    80003322:	00b784b3          	add	s1,a5,a1
    80003326:	0004a903          	lw	s2,0(s1)
    8000332a:	02090063          	beqz	s2,8000334a <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000332e:	8552                	mv	a0,s4
    80003330:	00000097          	auipc	ra,0x0
    80003334:	c9c080e7          	jalr	-868(ra) # 80002fcc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003338:	854a                	mv	a0,s2
    8000333a:	70a2                	ld	ra,40(sp)
    8000333c:	7402                	ld	s0,32(sp)
    8000333e:	64e2                	ld	s1,24(sp)
    80003340:	6942                	ld	s2,16(sp)
    80003342:	69a2                	ld	s3,8(sp)
    80003344:	6a02                	ld	s4,0(sp)
    80003346:	6145                	addi	sp,sp,48
    80003348:	8082                	ret
      addr = balloc(ip->dev);
    8000334a:	0009a503          	lw	a0,0(s3)
    8000334e:	00000097          	auipc	ra,0x0
    80003352:	e10080e7          	jalr	-496(ra) # 8000315e <balloc>
    80003356:	0005091b          	sext.w	s2,a0
      if(addr){
    8000335a:	fc090ae3          	beqz	s2,8000332e <bmap+0x98>
        a[bn] = addr;
    8000335e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003362:	8552                	mv	a0,s4
    80003364:	00001097          	auipc	ra,0x1
    80003368:	eec080e7          	jalr	-276(ra) # 80004250 <log_write>
    8000336c:	b7c9                	j	8000332e <bmap+0x98>
  panic("bmap: out of range");
    8000336e:	00005517          	auipc	a0,0x5
    80003372:	21a50513          	addi	a0,a0,538 # 80008588 <syscalls+0x120>
    80003376:	ffffd097          	auipc	ra,0xffffd
    8000337a:	1ce080e7          	jalr	462(ra) # 80000544 <panic>

000000008000337e <iget>:
{
    8000337e:	7179                	addi	sp,sp,-48
    80003380:	f406                	sd	ra,40(sp)
    80003382:	f022                	sd	s0,32(sp)
    80003384:	ec26                	sd	s1,24(sp)
    80003386:	e84a                	sd	s2,16(sp)
    80003388:	e44e                	sd	s3,8(sp)
    8000338a:	e052                	sd	s4,0(sp)
    8000338c:	1800                	addi	s0,sp,48
    8000338e:	89aa                	mv	s3,a0
    80003390:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003392:	0001c517          	auipc	a0,0x1c
    80003396:	dae50513          	addi	a0,a0,-594 # 8001f140 <itable>
    8000339a:	ffffe097          	auipc	ra,0xffffe
    8000339e:	850080e7          	jalr	-1968(ra) # 80000bea <acquire>
  empty = 0;
    800033a2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033a4:	0001c497          	auipc	s1,0x1c
    800033a8:	db448493          	addi	s1,s1,-588 # 8001f158 <itable+0x18>
    800033ac:	0001e697          	auipc	a3,0x1e
    800033b0:	83c68693          	addi	a3,a3,-1988 # 80020be8 <log>
    800033b4:	a039                	j	800033c2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033b6:	02090b63          	beqz	s2,800033ec <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033ba:	08848493          	addi	s1,s1,136
    800033be:	02d48a63          	beq	s1,a3,800033f2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033c2:	449c                	lw	a5,8(s1)
    800033c4:	fef059e3          	blez	a5,800033b6 <iget+0x38>
    800033c8:	4098                	lw	a4,0(s1)
    800033ca:	ff3716e3          	bne	a4,s3,800033b6 <iget+0x38>
    800033ce:	40d8                	lw	a4,4(s1)
    800033d0:	ff4713e3          	bne	a4,s4,800033b6 <iget+0x38>
      ip->ref++;
    800033d4:	2785                	addiw	a5,a5,1
    800033d6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033d8:	0001c517          	auipc	a0,0x1c
    800033dc:	d6850513          	addi	a0,a0,-664 # 8001f140 <itable>
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	8be080e7          	jalr	-1858(ra) # 80000c9e <release>
      return ip;
    800033e8:	8926                	mv	s2,s1
    800033ea:	a03d                	j	80003418 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033ec:	f7f9                	bnez	a5,800033ba <iget+0x3c>
    800033ee:	8926                	mv	s2,s1
    800033f0:	b7e9                	j	800033ba <iget+0x3c>
  if(empty == 0)
    800033f2:	02090c63          	beqz	s2,8000342a <iget+0xac>
  ip->dev = dev;
    800033f6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033fa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033fe:	4785                	li	a5,1
    80003400:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003404:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003408:	0001c517          	auipc	a0,0x1c
    8000340c:	d3850513          	addi	a0,a0,-712 # 8001f140 <itable>
    80003410:	ffffe097          	auipc	ra,0xffffe
    80003414:	88e080e7          	jalr	-1906(ra) # 80000c9e <release>
}
    80003418:	854a                	mv	a0,s2
    8000341a:	70a2                	ld	ra,40(sp)
    8000341c:	7402                	ld	s0,32(sp)
    8000341e:	64e2                	ld	s1,24(sp)
    80003420:	6942                	ld	s2,16(sp)
    80003422:	69a2                	ld	s3,8(sp)
    80003424:	6a02                	ld	s4,0(sp)
    80003426:	6145                	addi	sp,sp,48
    80003428:	8082                	ret
    panic("iget: no inodes");
    8000342a:	00005517          	auipc	a0,0x5
    8000342e:	17650513          	addi	a0,a0,374 # 800085a0 <syscalls+0x138>
    80003432:	ffffd097          	auipc	ra,0xffffd
    80003436:	112080e7          	jalr	274(ra) # 80000544 <panic>

000000008000343a <fsinit>:
fsinit(int dev) {
    8000343a:	7179                	addi	sp,sp,-48
    8000343c:	f406                	sd	ra,40(sp)
    8000343e:	f022                	sd	s0,32(sp)
    80003440:	ec26                	sd	s1,24(sp)
    80003442:	e84a                	sd	s2,16(sp)
    80003444:	e44e                	sd	s3,8(sp)
    80003446:	1800                	addi	s0,sp,48
    80003448:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000344a:	4585                	li	a1,1
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	a50080e7          	jalr	-1456(ra) # 80002e9c <bread>
    80003454:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003456:	0001c997          	auipc	s3,0x1c
    8000345a:	cca98993          	addi	s3,s3,-822 # 8001f120 <sb>
    8000345e:	02000613          	li	a2,32
    80003462:	05850593          	addi	a1,a0,88
    80003466:	854e                	mv	a0,s3
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	8de080e7          	jalr	-1826(ra) # 80000d46 <memmove>
  brelse(bp);
    80003470:	8526                	mv	a0,s1
    80003472:	00000097          	auipc	ra,0x0
    80003476:	b5a080e7          	jalr	-1190(ra) # 80002fcc <brelse>
  if(sb.magic != FSMAGIC)
    8000347a:	0009a703          	lw	a4,0(s3)
    8000347e:	102037b7          	lui	a5,0x10203
    80003482:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003486:	02f71263          	bne	a4,a5,800034aa <fsinit+0x70>
  initlog(dev, &sb);
    8000348a:	0001c597          	auipc	a1,0x1c
    8000348e:	c9658593          	addi	a1,a1,-874 # 8001f120 <sb>
    80003492:	854a                	mv	a0,s2
    80003494:	00001097          	auipc	ra,0x1
    80003498:	b40080e7          	jalr	-1216(ra) # 80003fd4 <initlog>
}
    8000349c:	70a2                	ld	ra,40(sp)
    8000349e:	7402                	ld	s0,32(sp)
    800034a0:	64e2                	ld	s1,24(sp)
    800034a2:	6942                	ld	s2,16(sp)
    800034a4:	69a2                	ld	s3,8(sp)
    800034a6:	6145                	addi	sp,sp,48
    800034a8:	8082                	ret
    panic("invalid file system");
    800034aa:	00005517          	auipc	a0,0x5
    800034ae:	10650513          	addi	a0,a0,262 # 800085b0 <syscalls+0x148>
    800034b2:	ffffd097          	auipc	ra,0xffffd
    800034b6:	092080e7          	jalr	146(ra) # 80000544 <panic>

00000000800034ba <iinit>:
{
    800034ba:	7179                	addi	sp,sp,-48
    800034bc:	f406                	sd	ra,40(sp)
    800034be:	f022                	sd	s0,32(sp)
    800034c0:	ec26                	sd	s1,24(sp)
    800034c2:	e84a                	sd	s2,16(sp)
    800034c4:	e44e                	sd	s3,8(sp)
    800034c6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034c8:	00005597          	auipc	a1,0x5
    800034cc:	10058593          	addi	a1,a1,256 # 800085c8 <syscalls+0x160>
    800034d0:	0001c517          	auipc	a0,0x1c
    800034d4:	c7050513          	addi	a0,a0,-912 # 8001f140 <itable>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	682080e7          	jalr	1666(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800034e0:	0001c497          	auipc	s1,0x1c
    800034e4:	c8848493          	addi	s1,s1,-888 # 8001f168 <itable+0x28>
    800034e8:	0001d997          	auipc	s3,0x1d
    800034ec:	71098993          	addi	s3,s3,1808 # 80020bf8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034f0:	00005917          	auipc	s2,0x5
    800034f4:	0e090913          	addi	s2,s2,224 # 800085d0 <syscalls+0x168>
    800034f8:	85ca                	mv	a1,s2
    800034fa:	8526                	mv	a0,s1
    800034fc:	00001097          	auipc	ra,0x1
    80003500:	e3a080e7          	jalr	-454(ra) # 80004336 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003504:	08848493          	addi	s1,s1,136
    80003508:	ff3498e3          	bne	s1,s3,800034f8 <iinit+0x3e>
}
    8000350c:	70a2                	ld	ra,40(sp)
    8000350e:	7402                	ld	s0,32(sp)
    80003510:	64e2                	ld	s1,24(sp)
    80003512:	6942                	ld	s2,16(sp)
    80003514:	69a2                	ld	s3,8(sp)
    80003516:	6145                	addi	sp,sp,48
    80003518:	8082                	ret

000000008000351a <ialloc>:
{
    8000351a:	715d                	addi	sp,sp,-80
    8000351c:	e486                	sd	ra,72(sp)
    8000351e:	e0a2                	sd	s0,64(sp)
    80003520:	fc26                	sd	s1,56(sp)
    80003522:	f84a                	sd	s2,48(sp)
    80003524:	f44e                	sd	s3,40(sp)
    80003526:	f052                	sd	s4,32(sp)
    80003528:	ec56                	sd	s5,24(sp)
    8000352a:	e85a                	sd	s6,16(sp)
    8000352c:	e45e                	sd	s7,8(sp)
    8000352e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003530:	0001c717          	auipc	a4,0x1c
    80003534:	bfc72703          	lw	a4,-1028(a4) # 8001f12c <sb+0xc>
    80003538:	4785                	li	a5,1
    8000353a:	04e7fa63          	bgeu	a5,a4,8000358e <ialloc+0x74>
    8000353e:	8aaa                	mv	s5,a0
    80003540:	8bae                	mv	s7,a1
    80003542:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003544:	0001ca17          	auipc	s4,0x1c
    80003548:	bdca0a13          	addi	s4,s4,-1060 # 8001f120 <sb>
    8000354c:	00048b1b          	sext.w	s6,s1
    80003550:	0044d593          	srli	a1,s1,0x4
    80003554:	018a2783          	lw	a5,24(s4)
    80003558:	9dbd                	addw	a1,a1,a5
    8000355a:	8556                	mv	a0,s5
    8000355c:	00000097          	auipc	ra,0x0
    80003560:	940080e7          	jalr	-1728(ra) # 80002e9c <bread>
    80003564:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003566:	05850993          	addi	s3,a0,88
    8000356a:	00f4f793          	andi	a5,s1,15
    8000356e:	079a                	slli	a5,a5,0x6
    80003570:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003572:	00099783          	lh	a5,0(s3)
    80003576:	c3a1                	beqz	a5,800035b6 <ialloc+0x9c>
    brelse(bp);
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	a54080e7          	jalr	-1452(ra) # 80002fcc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003580:	0485                	addi	s1,s1,1
    80003582:	00ca2703          	lw	a4,12(s4)
    80003586:	0004879b          	sext.w	a5,s1
    8000358a:	fce7e1e3          	bltu	a5,a4,8000354c <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000358e:	00005517          	auipc	a0,0x5
    80003592:	04a50513          	addi	a0,a0,74 # 800085d8 <syscalls+0x170>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	ff8080e7          	jalr	-8(ra) # 8000058e <printf>
  return 0;
    8000359e:	4501                	li	a0,0
}
    800035a0:	60a6                	ld	ra,72(sp)
    800035a2:	6406                	ld	s0,64(sp)
    800035a4:	74e2                	ld	s1,56(sp)
    800035a6:	7942                	ld	s2,48(sp)
    800035a8:	79a2                	ld	s3,40(sp)
    800035aa:	7a02                	ld	s4,32(sp)
    800035ac:	6ae2                	ld	s5,24(sp)
    800035ae:	6b42                	ld	s6,16(sp)
    800035b0:	6ba2                	ld	s7,8(sp)
    800035b2:	6161                	addi	sp,sp,80
    800035b4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800035b6:	04000613          	li	a2,64
    800035ba:	4581                	li	a1,0
    800035bc:	854e                	mv	a0,s3
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	728080e7          	jalr	1832(ra) # 80000ce6 <memset>
      dip->type = type;
    800035c6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035ca:	854a                	mv	a0,s2
    800035cc:	00001097          	auipc	ra,0x1
    800035d0:	c84080e7          	jalr	-892(ra) # 80004250 <log_write>
      brelse(bp);
    800035d4:	854a                	mv	a0,s2
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	9f6080e7          	jalr	-1546(ra) # 80002fcc <brelse>
      return iget(dev, inum);
    800035de:	85da                	mv	a1,s6
    800035e0:	8556                	mv	a0,s5
    800035e2:	00000097          	auipc	ra,0x0
    800035e6:	d9c080e7          	jalr	-612(ra) # 8000337e <iget>
    800035ea:	bf5d                	j	800035a0 <ialloc+0x86>

00000000800035ec <iupdate>:
{
    800035ec:	1101                	addi	sp,sp,-32
    800035ee:	ec06                	sd	ra,24(sp)
    800035f0:	e822                	sd	s0,16(sp)
    800035f2:	e426                	sd	s1,8(sp)
    800035f4:	e04a                	sd	s2,0(sp)
    800035f6:	1000                	addi	s0,sp,32
    800035f8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035fa:	415c                	lw	a5,4(a0)
    800035fc:	0047d79b          	srliw	a5,a5,0x4
    80003600:	0001c597          	auipc	a1,0x1c
    80003604:	b385a583          	lw	a1,-1224(a1) # 8001f138 <sb+0x18>
    80003608:	9dbd                	addw	a1,a1,a5
    8000360a:	4108                	lw	a0,0(a0)
    8000360c:	00000097          	auipc	ra,0x0
    80003610:	890080e7          	jalr	-1904(ra) # 80002e9c <bread>
    80003614:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003616:	05850793          	addi	a5,a0,88
    8000361a:	40c8                	lw	a0,4(s1)
    8000361c:	893d                	andi	a0,a0,15
    8000361e:	051a                	slli	a0,a0,0x6
    80003620:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003622:	04449703          	lh	a4,68(s1)
    80003626:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000362a:	04649703          	lh	a4,70(s1)
    8000362e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003632:	04849703          	lh	a4,72(s1)
    80003636:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000363a:	04a49703          	lh	a4,74(s1)
    8000363e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003642:	44f8                	lw	a4,76(s1)
    80003644:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003646:	03400613          	li	a2,52
    8000364a:	05048593          	addi	a1,s1,80
    8000364e:	0531                	addi	a0,a0,12
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	6f6080e7          	jalr	1782(ra) # 80000d46 <memmove>
  log_write(bp);
    80003658:	854a                	mv	a0,s2
    8000365a:	00001097          	auipc	ra,0x1
    8000365e:	bf6080e7          	jalr	-1034(ra) # 80004250 <log_write>
  brelse(bp);
    80003662:	854a                	mv	a0,s2
    80003664:	00000097          	auipc	ra,0x0
    80003668:	968080e7          	jalr	-1688(ra) # 80002fcc <brelse>
}
    8000366c:	60e2                	ld	ra,24(sp)
    8000366e:	6442                	ld	s0,16(sp)
    80003670:	64a2                	ld	s1,8(sp)
    80003672:	6902                	ld	s2,0(sp)
    80003674:	6105                	addi	sp,sp,32
    80003676:	8082                	ret

0000000080003678 <idup>:
{
    80003678:	1101                	addi	sp,sp,-32
    8000367a:	ec06                	sd	ra,24(sp)
    8000367c:	e822                	sd	s0,16(sp)
    8000367e:	e426                	sd	s1,8(sp)
    80003680:	1000                	addi	s0,sp,32
    80003682:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003684:	0001c517          	auipc	a0,0x1c
    80003688:	abc50513          	addi	a0,a0,-1348 # 8001f140 <itable>
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	55e080e7          	jalr	1374(ra) # 80000bea <acquire>
  ip->ref++;
    80003694:	449c                	lw	a5,8(s1)
    80003696:	2785                	addiw	a5,a5,1
    80003698:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000369a:	0001c517          	auipc	a0,0x1c
    8000369e:	aa650513          	addi	a0,a0,-1370 # 8001f140 <itable>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	5fc080e7          	jalr	1532(ra) # 80000c9e <release>
}
    800036aa:	8526                	mv	a0,s1
    800036ac:	60e2                	ld	ra,24(sp)
    800036ae:	6442                	ld	s0,16(sp)
    800036b0:	64a2                	ld	s1,8(sp)
    800036b2:	6105                	addi	sp,sp,32
    800036b4:	8082                	ret

00000000800036b6 <ilock>:
{
    800036b6:	1101                	addi	sp,sp,-32
    800036b8:	ec06                	sd	ra,24(sp)
    800036ba:	e822                	sd	s0,16(sp)
    800036bc:	e426                	sd	s1,8(sp)
    800036be:	e04a                	sd	s2,0(sp)
    800036c0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036c2:	c115                	beqz	a0,800036e6 <ilock+0x30>
    800036c4:	84aa                	mv	s1,a0
    800036c6:	451c                	lw	a5,8(a0)
    800036c8:	00f05f63          	blez	a5,800036e6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036cc:	0541                	addi	a0,a0,16
    800036ce:	00001097          	auipc	ra,0x1
    800036d2:	ca2080e7          	jalr	-862(ra) # 80004370 <acquiresleep>
  if(ip->valid == 0){
    800036d6:	40bc                	lw	a5,64(s1)
    800036d8:	cf99                	beqz	a5,800036f6 <ilock+0x40>
}
    800036da:	60e2                	ld	ra,24(sp)
    800036dc:	6442                	ld	s0,16(sp)
    800036de:	64a2                	ld	s1,8(sp)
    800036e0:	6902                	ld	s2,0(sp)
    800036e2:	6105                	addi	sp,sp,32
    800036e4:	8082                	ret
    panic("ilock");
    800036e6:	00005517          	auipc	a0,0x5
    800036ea:	f0a50513          	addi	a0,a0,-246 # 800085f0 <syscalls+0x188>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	e56080e7          	jalr	-426(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036f6:	40dc                	lw	a5,4(s1)
    800036f8:	0047d79b          	srliw	a5,a5,0x4
    800036fc:	0001c597          	auipc	a1,0x1c
    80003700:	a3c5a583          	lw	a1,-1476(a1) # 8001f138 <sb+0x18>
    80003704:	9dbd                	addw	a1,a1,a5
    80003706:	4088                	lw	a0,0(s1)
    80003708:	fffff097          	auipc	ra,0xfffff
    8000370c:	794080e7          	jalr	1940(ra) # 80002e9c <bread>
    80003710:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003712:	05850593          	addi	a1,a0,88
    80003716:	40dc                	lw	a5,4(s1)
    80003718:	8bbd                	andi	a5,a5,15
    8000371a:	079a                	slli	a5,a5,0x6
    8000371c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000371e:	00059783          	lh	a5,0(a1)
    80003722:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003726:	00259783          	lh	a5,2(a1)
    8000372a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000372e:	00459783          	lh	a5,4(a1)
    80003732:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003736:	00659783          	lh	a5,6(a1)
    8000373a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000373e:	459c                	lw	a5,8(a1)
    80003740:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003742:	03400613          	li	a2,52
    80003746:	05b1                	addi	a1,a1,12
    80003748:	05048513          	addi	a0,s1,80
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	5fa080e7          	jalr	1530(ra) # 80000d46 <memmove>
    brelse(bp);
    80003754:	854a                	mv	a0,s2
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	876080e7          	jalr	-1930(ra) # 80002fcc <brelse>
    ip->valid = 1;
    8000375e:	4785                	li	a5,1
    80003760:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003762:	04449783          	lh	a5,68(s1)
    80003766:	fbb5                	bnez	a5,800036da <ilock+0x24>
      panic("ilock: no type");
    80003768:	00005517          	auipc	a0,0x5
    8000376c:	e9050513          	addi	a0,a0,-368 # 800085f8 <syscalls+0x190>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	dd4080e7          	jalr	-556(ra) # 80000544 <panic>

0000000080003778 <iunlock>:
{
    80003778:	1101                	addi	sp,sp,-32
    8000377a:	ec06                	sd	ra,24(sp)
    8000377c:	e822                	sd	s0,16(sp)
    8000377e:	e426                	sd	s1,8(sp)
    80003780:	e04a                	sd	s2,0(sp)
    80003782:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003784:	c905                	beqz	a0,800037b4 <iunlock+0x3c>
    80003786:	84aa                	mv	s1,a0
    80003788:	01050913          	addi	s2,a0,16
    8000378c:	854a                	mv	a0,s2
    8000378e:	00001097          	auipc	ra,0x1
    80003792:	c7c080e7          	jalr	-900(ra) # 8000440a <holdingsleep>
    80003796:	cd19                	beqz	a0,800037b4 <iunlock+0x3c>
    80003798:	449c                	lw	a5,8(s1)
    8000379a:	00f05d63          	blez	a5,800037b4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000379e:	854a                	mv	a0,s2
    800037a0:	00001097          	auipc	ra,0x1
    800037a4:	c26080e7          	jalr	-986(ra) # 800043c6 <releasesleep>
}
    800037a8:	60e2                	ld	ra,24(sp)
    800037aa:	6442                	ld	s0,16(sp)
    800037ac:	64a2                	ld	s1,8(sp)
    800037ae:	6902                	ld	s2,0(sp)
    800037b0:	6105                	addi	sp,sp,32
    800037b2:	8082                	ret
    panic("iunlock");
    800037b4:	00005517          	auipc	a0,0x5
    800037b8:	e5450513          	addi	a0,a0,-428 # 80008608 <syscalls+0x1a0>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	d88080e7          	jalr	-632(ra) # 80000544 <panic>

00000000800037c4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037c4:	7179                	addi	sp,sp,-48
    800037c6:	f406                	sd	ra,40(sp)
    800037c8:	f022                	sd	s0,32(sp)
    800037ca:	ec26                	sd	s1,24(sp)
    800037cc:	e84a                	sd	s2,16(sp)
    800037ce:	e44e                	sd	s3,8(sp)
    800037d0:	e052                	sd	s4,0(sp)
    800037d2:	1800                	addi	s0,sp,48
    800037d4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037d6:	05050493          	addi	s1,a0,80
    800037da:	08050913          	addi	s2,a0,128
    800037de:	a021                	j	800037e6 <itrunc+0x22>
    800037e0:	0491                	addi	s1,s1,4
    800037e2:	01248d63          	beq	s1,s2,800037fc <itrunc+0x38>
    if(ip->addrs[i]){
    800037e6:	408c                	lw	a1,0(s1)
    800037e8:	dde5                	beqz	a1,800037e0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037ea:	0009a503          	lw	a0,0(s3)
    800037ee:	00000097          	auipc	ra,0x0
    800037f2:	8f4080e7          	jalr	-1804(ra) # 800030e2 <bfree>
      ip->addrs[i] = 0;
    800037f6:	0004a023          	sw	zero,0(s1)
    800037fa:	b7dd                	j	800037e0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037fc:	0809a583          	lw	a1,128(s3)
    80003800:	e185                	bnez	a1,80003820 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003802:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003806:	854e                	mv	a0,s3
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	de4080e7          	jalr	-540(ra) # 800035ec <iupdate>
}
    80003810:	70a2                	ld	ra,40(sp)
    80003812:	7402                	ld	s0,32(sp)
    80003814:	64e2                	ld	s1,24(sp)
    80003816:	6942                	ld	s2,16(sp)
    80003818:	69a2                	ld	s3,8(sp)
    8000381a:	6a02                	ld	s4,0(sp)
    8000381c:	6145                	addi	sp,sp,48
    8000381e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003820:	0009a503          	lw	a0,0(s3)
    80003824:	fffff097          	auipc	ra,0xfffff
    80003828:	678080e7          	jalr	1656(ra) # 80002e9c <bread>
    8000382c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000382e:	05850493          	addi	s1,a0,88
    80003832:	45850913          	addi	s2,a0,1112
    80003836:	a811                	j	8000384a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003838:	0009a503          	lw	a0,0(s3)
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	8a6080e7          	jalr	-1882(ra) # 800030e2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003844:	0491                	addi	s1,s1,4
    80003846:	01248563          	beq	s1,s2,80003850 <itrunc+0x8c>
      if(a[j])
    8000384a:	408c                	lw	a1,0(s1)
    8000384c:	dde5                	beqz	a1,80003844 <itrunc+0x80>
    8000384e:	b7ed                	j	80003838 <itrunc+0x74>
    brelse(bp);
    80003850:	8552                	mv	a0,s4
    80003852:	fffff097          	auipc	ra,0xfffff
    80003856:	77a080e7          	jalr	1914(ra) # 80002fcc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000385a:	0809a583          	lw	a1,128(s3)
    8000385e:	0009a503          	lw	a0,0(s3)
    80003862:	00000097          	auipc	ra,0x0
    80003866:	880080e7          	jalr	-1920(ra) # 800030e2 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000386a:	0809a023          	sw	zero,128(s3)
    8000386e:	bf51                	j	80003802 <itrunc+0x3e>

0000000080003870 <iput>:
{
    80003870:	1101                	addi	sp,sp,-32
    80003872:	ec06                	sd	ra,24(sp)
    80003874:	e822                	sd	s0,16(sp)
    80003876:	e426                	sd	s1,8(sp)
    80003878:	e04a                	sd	s2,0(sp)
    8000387a:	1000                	addi	s0,sp,32
    8000387c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000387e:	0001c517          	auipc	a0,0x1c
    80003882:	8c250513          	addi	a0,a0,-1854 # 8001f140 <itable>
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	364080e7          	jalr	868(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000388e:	4498                	lw	a4,8(s1)
    80003890:	4785                	li	a5,1
    80003892:	02f70363          	beq	a4,a5,800038b8 <iput+0x48>
  ip->ref--;
    80003896:	449c                	lw	a5,8(s1)
    80003898:	37fd                	addiw	a5,a5,-1
    8000389a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000389c:	0001c517          	auipc	a0,0x1c
    800038a0:	8a450513          	addi	a0,a0,-1884 # 8001f140 <itable>
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	3fa080e7          	jalr	1018(ra) # 80000c9e <release>
}
    800038ac:	60e2                	ld	ra,24(sp)
    800038ae:	6442                	ld	s0,16(sp)
    800038b0:	64a2                	ld	s1,8(sp)
    800038b2:	6902                	ld	s2,0(sp)
    800038b4:	6105                	addi	sp,sp,32
    800038b6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038b8:	40bc                	lw	a5,64(s1)
    800038ba:	dff1                	beqz	a5,80003896 <iput+0x26>
    800038bc:	04a49783          	lh	a5,74(s1)
    800038c0:	fbf9                	bnez	a5,80003896 <iput+0x26>
    acquiresleep(&ip->lock);
    800038c2:	01048913          	addi	s2,s1,16
    800038c6:	854a                	mv	a0,s2
    800038c8:	00001097          	auipc	ra,0x1
    800038cc:	aa8080e7          	jalr	-1368(ra) # 80004370 <acquiresleep>
    release(&itable.lock);
    800038d0:	0001c517          	auipc	a0,0x1c
    800038d4:	87050513          	addi	a0,a0,-1936 # 8001f140 <itable>
    800038d8:	ffffd097          	auipc	ra,0xffffd
    800038dc:	3c6080e7          	jalr	966(ra) # 80000c9e <release>
    itrunc(ip);
    800038e0:	8526                	mv	a0,s1
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	ee2080e7          	jalr	-286(ra) # 800037c4 <itrunc>
    ip->type = 0;
    800038ea:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038ee:	8526                	mv	a0,s1
    800038f0:	00000097          	auipc	ra,0x0
    800038f4:	cfc080e7          	jalr	-772(ra) # 800035ec <iupdate>
    ip->valid = 0;
    800038f8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038fc:	854a                	mv	a0,s2
    800038fe:	00001097          	auipc	ra,0x1
    80003902:	ac8080e7          	jalr	-1336(ra) # 800043c6 <releasesleep>
    acquire(&itable.lock);
    80003906:	0001c517          	auipc	a0,0x1c
    8000390a:	83a50513          	addi	a0,a0,-1990 # 8001f140 <itable>
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	2dc080e7          	jalr	732(ra) # 80000bea <acquire>
    80003916:	b741                	j	80003896 <iput+0x26>

0000000080003918 <iunlockput>:
{
    80003918:	1101                	addi	sp,sp,-32
    8000391a:	ec06                	sd	ra,24(sp)
    8000391c:	e822                	sd	s0,16(sp)
    8000391e:	e426                	sd	s1,8(sp)
    80003920:	1000                	addi	s0,sp,32
    80003922:	84aa                	mv	s1,a0
  iunlock(ip);
    80003924:	00000097          	auipc	ra,0x0
    80003928:	e54080e7          	jalr	-428(ra) # 80003778 <iunlock>
  iput(ip);
    8000392c:	8526                	mv	a0,s1
    8000392e:	00000097          	auipc	ra,0x0
    80003932:	f42080e7          	jalr	-190(ra) # 80003870 <iput>
}
    80003936:	60e2                	ld	ra,24(sp)
    80003938:	6442                	ld	s0,16(sp)
    8000393a:	64a2                	ld	s1,8(sp)
    8000393c:	6105                	addi	sp,sp,32
    8000393e:	8082                	ret

0000000080003940 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003940:	1141                	addi	sp,sp,-16
    80003942:	e422                	sd	s0,8(sp)
    80003944:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003946:	411c                	lw	a5,0(a0)
    80003948:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000394a:	415c                	lw	a5,4(a0)
    8000394c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000394e:	04451783          	lh	a5,68(a0)
    80003952:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003956:	04a51783          	lh	a5,74(a0)
    8000395a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000395e:	04c56783          	lwu	a5,76(a0)
    80003962:	e99c                	sd	a5,16(a1)
}
    80003964:	6422                	ld	s0,8(sp)
    80003966:	0141                	addi	sp,sp,16
    80003968:	8082                	ret

000000008000396a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000396a:	457c                	lw	a5,76(a0)
    8000396c:	0ed7e963          	bltu	a5,a3,80003a5e <readi+0xf4>
{
    80003970:	7159                	addi	sp,sp,-112
    80003972:	f486                	sd	ra,104(sp)
    80003974:	f0a2                	sd	s0,96(sp)
    80003976:	eca6                	sd	s1,88(sp)
    80003978:	e8ca                	sd	s2,80(sp)
    8000397a:	e4ce                	sd	s3,72(sp)
    8000397c:	e0d2                	sd	s4,64(sp)
    8000397e:	fc56                	sd	s5,56(sp)
    80003980:	f85a                	sd	s6,48(sp)
    80003982:	f45e                	sd	s7,40(sp)
    80003984:	f062                	sd	s8,32(sp)
    80003986:	ec66                	sd	s9,24(sp)
    80003988:	e86a                	sd	s10,16(sp)
    8000398a:	e46e                	sd	s11,8(sp)
    8000398c:	1880                	addi	s0,sp,112
    8000398e:	8b2a                	mv	s6,a0
    80003990:	8bae                	mv	s7,a1
    80003992:	8a32                	mv	s4,a2
    80003994:	84b6                	mv	s1,a3
    80003996:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003998:	9f35                	addw	a4,a4,a3
    return 0;
    8000399a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000399c:	0ad76063          	bltu	a4,a3,80003a3c <readi+0xd2>
  if(off + n > ip->size)
    800039a0:	00e7f463          	bgeu	a5,a4,800039a8 <readi+0x3e>
    n = ip->size - off;
    800039a4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039a8:	0a0a8963          	beqz	s5,80003a5a <readi+0xf0>
    800039ac:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800039ae:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039b2:	5c7d                	li	s8,-1
    800039b4:	a82d                	j	800039ee <readi+0x84>
    800039b6:	020d1d93          	slli	s11,s10,0x20
    800039ba:	020ddd93          	srli	s11,s11,0x20
    800039be:	05890613          	addi	a2,s2,88
    800039c2:	86ee                	mv	a3,s11
    800039c4:	963a                	add	a2,a2,a4
    800039c6:	85d2                	mv	a1,s4
    800039c8:	855e                	mv	a0,s7
    800039ca:	fffff097          	auipc	ra,0xfffff
    800039ce:	aa8080e7          	jalr	-1368(ra) # 80002472 <either_copyout>
    800039d2:	05850d63          	beq	a0,s8,80003a2c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800039d6:	854a                	mv	a0,s2
    800039d8:	fffff097          	auipc	ra,0xfffff
    800039dc:	5f4080e7          	jalr	1524(ra) # 80002fcc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039e0:	013d09bb          	addw	s3,s10,s3
    800039e4:	009d04bb          	addw	s1,s10,s1
    800039e8:	9a6e                	add	s4,s4,s11
    800039ea:	0559f763          	bgeu	s3,s5,80003a38 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800039ee:	00a4d59b          	srliw	a1,s1,0xa
    800039f2:	855a                	mv	a0,s6
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	8a2080e7          	jalr	-1886(ra) # 80003296 <bmap>
    800039fc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a00:	cd85                	beqz	a1,80003a38 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a02:	000b2503          	lw	a0,0(s6)
    80003a06:	fffff097          	auipc	ra,0xfffff
    80003a0a:	496080e7          	jalr	1174(ra) # 80002e9c <bread>
    80003a0e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a10:	3ff4f713          	andi	a4,s1,1023
    80003a14:	40ec87bb          	subw	a5,s9,a4
    80003a18:	413a86bb          	subw	a3,s5,s3
    80003a1c:	8d3e                	mv	s10,a5
    80003a1e:	2781                	sext.w	a5,a5
    80003a20:	0006861b          	sext.w	a2,a3
    80003a24:	f8f679e3          	bgeu	a2,a5,800039b6 <readi+0x4c>
    80003a28:	8d36                	mv	s10,a3
    80003a2a:	b771                	j	800039b6 <readi+0x4c>
      brelse(bp);
    80003a2c:	854a                	mv	a0,s2
    80003a2e:	fffff097          	auipc	ra,0xfffff
    80003a32:	59e080e7          	jalr	1438(ra) # 80002fcc <brelse>
      tot = -1;
    80003a36:	59fd                	li	s3,-1
  }
  return tot;
    80003a38:	0009851b          	sext.w	a0,s3
}
    80003a3c:	70a6                	ld	ra,104(sp)
    80003a3e:	7406                	ld	s0,96(sp)
    80003a40:	64e6                	ld	s1,88(sp)
    80003a42:	6946                	ld	s2,80(sp)
    80003a44:	69a6                	ld	s3,72(sp)
    80003a46:	6a06                	ld	s4,64(sp)
    80003a48:	7ae2                	ld	s5,56(sp)
    80003a4a:	7b42                	ld	s6,48(sp)
    80003a4c:	7ba2                	ld	s7,40(sp)
    80003a4e:	7c02                	ld	s8,32(sp)
    80003a50:	6ce2                	ld	s9,24(sp)
    80003a52:	6d42                	ld	s10,16(sp)
    80003a54:	6da2                	ld	s11,8(sp)
    80003a56:	6165                	addi	sp,sp,112
    80003a58:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a5a:	89d6                	mv	s3,s5
    80003a5c:	bff1                	j	80003a38 <readi+0xce>
    return 0;
    80003a5e:	4501                	li	a0,0
}
    80003a60:	8082                	ret

0000000080003a62 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a62:	457c                	lw	a5,76(a0)
    80003a64:	10d7e863          	bltu	a5,a3,80003b74 <writei+0x112>
{
    80003a68:	7159                	addi	sp,sp,-112
    80003a6a:	f486                	sd	ra,104(sp)
    80003a6c:	f0a2                	sd	s0,96(sp)
    80003a6e:	eca6                	sd	s1,88(sp)
    80003a70:	e8ca                	sd	s2,80(sp)
    80003a72:	e4ce                	sd	s3,72(sp)
    80003a74:	e0d2                	sd	s4,64(sp)
    80003a76:	fc56                	sd	s5,56(sp)
    80003a78:	f85a                	sd	s6,48(sp)
    80003a7a:	f45e                	sd	s7,40(sp)
    80003a7c:	f062                	sd	s8,32(sp)
    80003a7e:	ec66                	sd	s9,24(sp)
    80003a80:	e86a                	sd	s10,16(sp)
    80003a82:	e46e                	sd	s11,8(sp)
    80003a84:	1880                	addi	s0,sp,112
    80003a86:	8aaa                	mv	s5,a0
    80003a88:	8bae                	mv	s7,a1
    80003a8a:	8a32                	mv	s4,a2
    80003a8c:	8936                	mv	s2,a3
    80003a8e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a90:	00e687bb          	addw	a5,a3,a4
    80003a94:	0ed7e263          	bltu	a5,a3,80003b78 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a98:	00043737          	lui	a4,0x43
    80003a9c:	0ef76063          	bltu	a4,a5,80003b7c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aa0:	0c0b0863          	beqz	s6,80003b70 <writei+0x10e>
    80003aa4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003aaa:	5c7d                	li	s8,-1
    80003aac:	a091                	j	80003af0 <writei+0x8e>
    80003aae:	020d1d93          	slli	s11,s10,0x20
    80003ab2:	020ddd93          	srli	s11,s11,0x20
    80003ab6:	05848513          	addi	a0,s1,88
    80003aba:	86ee                	mv	a3,s11
    80003abc:	8652                	mv	a2,s4
    80003abe:	85de                	mv	a1,s7
    80003ac0:	953a                	add	a0,a0,a4
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	a06080e7          	jalr	-1530(ra) # 800024c8 <either_copyin>
    80003aca:	07850263          	beq	a0,s8,80003b2e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ace:	8526                	mv	a0,s1
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	780080e7          	jalr	1920(ra) # 80004250 <log_write>
    brelse(bp);
    80003ad8:	8526                	mv	a0,s1
    80003ada:	fffff097          	auipc	ra,0xfffff
    80003ade:	4f2080e7          	jalr	1266(ra) # 80002fcc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ae2:	013d09bb          	addw	s3,s10,s3
    80003ae6:	012d093b          	addw	s2,s10,s2
    80003aea:	9a6e                	add	s4,s4,s11
    80003aec:	0569f663          	bgeu	s3,s6,80003b38 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003af0:	00a9559b          	srliw	a1,s2,0xa
    80003af4:	8556                	mv	a0,s5
    80003af6:	fffff097          	auipc	ra,0xfffff
    80003afa:	7a0080e7          	jalr	1952(ra) # 80003296 <bmap>
    80003afe:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b02:	c99d                	beqz	a1,80003b38 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b04:	000aa503          	lw	a0,0(s5)
    80003b08:	fffff097          	auipc	ra,0xfffff
    80003b0c:	394080e7          	jalr	916(ra) # 80002e9c <bread>
    80003b10:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b12:	3ff97713          	andi	a4,s2,1023
    80003b16:	40ec87bb          	subw	a5,s9,a4
    80003b1a:	413b06bb          	subw	a3,s6,s3
    80003b1e:	8d3e                	mv	s10,a5
    80003b20:	2781                	sext.w	a5,a5
    80003b22:	0006861b          	sext.w	a2,a3
    80003b26:	f8f674e3          	bgeu	a2,a5,80003aae <writei+0x4c>
    80003b2a:	8d36                	mv	s10,a3
    80003b2c:	b749                	j	80003aae <writei+0x4c>
      brelse(bp);
    80003b2e:	8526                	mv	a0,s1
    80003b30:	fffff097          	auipc	ra,0xfffff
    80003b34:	49c080e7          	jalr	1180(ra) # 80002fcc <brelse>
  }

  if(off > ip->size)
    80003b38:	04caa783          	lw	a5,76(s5)
    80003b3c:	0127f463          	bgeu	a5,s2,80003b44 <writei+0xe2>
    ip->size = off;
    80003b40:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b44:	8556                	mv	a0,s5
    80003b46:	00000097          	auipc	ra,0x0
    80003b4a:	aa6080e7          	jalr	-1370(ra) # 800035ec <iupdate>

  return tot;
    80003b4e:	0009851b          	sext.w	a0,s3
}
    80003b52:	70a6                	ld	ra,104(sp)
    80003b54:	7406                	ld	s0,96(sp)
    80003b56:	64e6                	ld	s1,88(sp)
    80003b58:	6946                	ld	s2,80(sp)
    80003b5a:	69a6                	ld	s3,72(sp)
    80003b5c:	6a06                	ld	s4,64(sp)
    80003b5e:	7ae2                	ld	s5,56(sp)
    80003b60:	7b42                	ld	s6,48(sp)
    80003b62:	7ba2                	ld	s7,40(sp)
    80003b64:	7c02                	ld	s8,32(sp)
    80003b66:	6ce2                	ld	s9,24(sp)
    80003b68:	6d42                	ld	s10,16(sp)
    80003b6a:	6da2                	ld	s11,8(sp)
    80003b6c:	6165                	addi	sp,sp,112
    80003b6e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b70:	89da                	mv	s3,s6
    80003b72:	bfc9                	j	80003b44 <writei+0xe2>
    return -1;
    80003b74:	557d                	li	a0,-1
}
    80003b76:	8082                	ret
    return -1;
    80003b78:	557d                	li	a0,-1
    80003b7a:	bfe1                	j	80003b52 <writei+0xf0>
    return -1;
    80003b7c:	557d                	li	a0,-1
    80003b7e:	bfd1                	j	80003b52 <writei+0xf0>

0000000080003b80 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b80:	1141                	addi	sp,sp,-16
    80003b82:	e406                	sd	ra,8(sp)
    80003b84:	e022                	sd	s0,0(sp)
    80003b86:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b88:	4639                	li	a2,14
    80003b8a:	ffffd097          	auipc	ra,0xffffd
    80003b8e:	234080e7          	jalr	564(ra) # 80000dbe <strncmp>
}
    80003b92:	60a2                	ld	ra,8(sp)
    80003b94:	6402                	ld	s0,0(sp)
    80003b96:	0141                	addi	sp,sp,16
    80003b98:	8082                	ret

0000000080003b9a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b9a:	7139                	addi	sp,sp,-64
    80003b9c:	fc06                	sd	ra,56(sp)
    80003b9e:	f822                	sd	s0,48(sp)
    80003ba0:	f426                	sd	s1,40(sp)
    80003ba2:	f04a                	sd	s2,32(sp)
    80003ba4:	ec4e                	sd	s3,24(sp)
    80003ba6:	e852                	sd	s4,16(sp)
    80003ba8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003baa:	04451703          	lh	a4,68(a0)
    80003bae:	4785                	li	a5,1
    80003bb0:	00f71a63          	bne	a4,a5,80003bc4 <dirlookup+0x2a>
    80003bb4:	892a                	mv	s2,a0
    80003bb6:	89ae                	mv	s3,a1
    80003bb8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bba:	457c                	lw	a5,76(a0)
    80003bbc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bbe:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bc0:	e79d                	bnez	a5,80003bee <dirlookup+0x54>
    80003bc2:	a8a5                	j	80003c3a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bc4:	00005517          	auipc	a0,0x5
    80003bc8:	a4c50513          	addi	a0,a0,-1460 # 80008610 <syscalls+0x1a8>
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	978080e7          	jalr	-1672(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003bd4:	00005517          	auipc	a0,0x5
    80003bd8:	a5450513          	addi	a0,a0,-1452 # 80008628 <syscalls+0x1c0>
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	968080e7          	jalr	-1688(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003be4:	24c1                	addiw	s1,s1,16
    80003be6:	04c92783          	lw	a5,76(s2)
    80003bea:	04f4f763          	bgeu	s1,a5,80003c38 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bee:	4741                	li	a4,16
    80003bf0:	86a6                	mv	a3,s1
    80003bf2:	fc040613          	addi	a2,s0,-64
    80003bf6:	4581                	li	a1,0
    80003bf8:	854a                	mv	a0,s2
    80003bfa:	00000097          	auipc	ra,0x0
    80003bfe:	d70080e7          	jalr	-656(ra) # 8000396a <readi>
    80003c02:	47c1                	li	a5,16
    80003c04:	fcf518e3          	bne	a0,a5,80003bd4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c08:	fc045783          	lhu	a5,-64(s0)
    80003c0c:	dfe1                	beqz	a5,80003be4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c0e:	fc240593          	addi	a1,s0,-62
    80003c12:	854e                	mv	a0,s3
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	f6c080e7          	jalr	-148(ra) # 80003b80 <namecmp>
    80003c1c:	f561                	bnez	a0,80003be4 <dirlookup+0x4a>
      if(poff)
    80003c1e:	000a0463          	beqz	s4,80003c26 <dirlookup+0x8c>
        *poff = off;
    80003c22:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c26:	fc045583          	lhu	a1,-64(s0)
    80003c2a:	00092503          	lw	a0,0(s2)
    80003c2e:	fffff097          	auipc	ra,0xfffff
    80003c32:	750080e7          	jalr	1872(ra) # 8000337e <iget>
    80003c36:	a011                	j	80003c3a <dirlookup+0xa0>
  return 0;
    80003c38:	4501                	li	a0,0
}
    80003c3a:	70e2                	ld	ra,56(sp)
    80003c3c:	7442                	ld	s0,48(sp)
    80003c3e:	74a2                	ld	s1,40(sp)
    80003c40:	7902                	ld	s2,32(sp)
    80003c42:	69e2                	ld	s3,24(sp)
    80003c44:	6a42                	ld	s4,16(sp)
    80003c46:	6121                	addi	sp,sp,64
    80003c48:	8082                	ret

0000000080003c4a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c4a:	711d                	addi	sp,sp,-96
    80003c4c:	ec86                	sd	ra,88(sp)
    80003c4e:	e8a2                	sd	s0,80(sp)
    80003c50:	e4a6                	sd	s1,72(sp)
    80003c52:	e0ca                	sd	s2,64(sp)
    80003c54:	fc4e                	sd	s3,56(sp)
    80003c56:	f852                	sd	s4,48(sp)
    80003c58:	f456                	sd	s5,40(sp)
    80003c5a:	f05a                	sd	s6,32(sp)
    80003c5c:	ec5e                	sd	s7,24(sp)
    80003c5e:	e862                	sd	s8,16(sp)
    80003c60:	e466                	sd	s9,8(sp)
    80003c62:	1080                	addi	s0,sp,96
    80003c64:	84aa                	mv	s1,a0
    80003c66:	8b2e                	mv	s6,a1
    80003c68:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c6a:	00054703          	lbu	a4,0(a0)
    80003c6e:	02f00793          	li	a5,47
    80003c72:	02f70363          	beq	a4,a5,80003c98 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c76:	ffffe097          	auipc	ra,0xffffe
    80003c7a:	d50080e7          	jalr	-688(ra) # 800019c6 <myproc>
    80003c7e:	15053503          	ld	a0,336(a0)
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	9f6080e7          	jalr	-1546(ra) # 80003678 <idup>
    80003c8a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c8c:	02f00913          	li	s2,47
  len = path - s;
    80003c90:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c92:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c94:	4c05                	li	s8,1
    80003c96:	a865                	j	80003d4e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c98:	4585                	li	a1,1
    80003c9a:	4505                	li	a0,1
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	6e2080e7          	jalr	1762(ra) # 8000337e <iget>
    80003ca4:	89aa                	mv	s3,a0
    80003ca6:	b7dd                	j	80003c8c <namex+0x42>
      iunlockput(ip);
    80003ca8:	854e                	mv	a0,s3
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	c6e080e7          	jalr	-914(ra) # 80003918 <iunlockput>
      return 0;
    80003cb2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cb4:	854e                	mv	a0,s3
    80003cb6:	60e6                	ld	ra,88(sp)
    80003cb8:	6446                	ld	s0,80(sp)
    80003cba:	64a6                	ld	s1,72(sp)
    80003cbc:	6906                	ld	s2,64(sp)
    80003cbe:	79e2                	ld	s3,56(sp)
    80003cc0:	7a42                	ld	s4,48(sp)
    80003cc2:	7aa2                	ld	s5,40(sp)
    80003cc4:	7b02                	ld	s6,32(sp)
    80003cc6:	6be2                	ld	s7,24(sp)
    80003cc8:	6c42                	ld	s8,16(sp)
    80003cca:	6ca2                	ld	s9,8(sp)
    80003ccc:	6125                	addi	sp,sp,96
    80003cce:	8082                	ret
      iunlock(ip);
    80003cd0:	854e                	mv	a0,s3
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	aa6080e7          	jalr	-1370(ra) # 80003778 <iunlock>
      return ip;
    80003cda:	bfe9                	j	80003cb4 <namex+0x6a>
      iunlockput(ip);
    80003cdc:	854e                	mv	a0,s3
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	c3a080e7          	jalr	-966(ra) # 80003918 <iunlockput>
      return 0;
    80003ce6:	89d2                	mv	s3,s4
    80003ce8:	b7f1                	j	80003cb4 <namex+0x6a>
  len = path - s;
    80003cea:	40b48633          	sub	a2,s1,a1
    80003cee:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003cf2:	094cd463          	bge	s9,s4,80003d7a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cf6:	4639                	li	a2,14
    80003cf8:	8556                	mv	a0,s5
    80003cfa:	ffffd097          	auipc	ra,0xffffd
    80003cfe:	04c080e7          	jalr	76(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003d02:	0004c783          	lbu	a5,0(s1)
    80003d06:	01279763          	bne	a5,s2,80003d14 <namex+0xca>
    path++;
    80003d0a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d0c:	0004c783          	lbu	a5,0(s1)
    80003d10:	ff278de3          	beq	a5,s2,80003d0a <namex+0xc0>
    ilock(ip);
    80003d14:	854e                	mv	a0,s3
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	9a0080e7          	jalr	-1632(ra) # 800036b6 <ilock>
    if(ip->type != T_DIR){
    80003d1e:	04499783          	lh	a5,68(s3)
    80003d22:	f98793e3          	bne	a5,s8,80003ca8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d26:	000b0563          	beqz	s6,80003d30 <namex+0xe6>
    80003d2a:	0004c783          	lbu	a5,0(s1)
    80003d2e:	d3cd                	beqz	a5,80003cd0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d30:	865e                	mv	a2,s7
    80003d32:	85d6                	mv	a1,s5
    80003d34:	854e                	mv	a0,s3
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	e64080e7          	jalr	-412(ra) # 80003b9a <dirlookup>
    80003d3e:	8a2a                	mv	s4,a0
    80003d40:	dd51                	beqz	a0,80003cdc <namex+0x92>
    iunlockput(ip);
    80003d42:	854e                	mv	a0,s3
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	bd4080e7          	jalr	-1068(ra) # 80003918 <iunlockput>
    ip = next;
    80003d4c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d4e:	0004c783          	lbu	a5,0(s1)
    80003d52:	05279763          	bne	a5,s2,80003da0 <namex+0x156>
    path++;
    80003d56:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d58:	0004c783          	lbu	a5,0(s1)
    80003d5c:	ff278de3          	beq	a5,s2,80003d56 <namex+0x10c>
  if(*path == 0)
    80003d60:	c79d                	beqz	a5,80003d8e <namex+0x144>
    path++;
    80003d62:	85a6                	mv	a1,s1
  len = path - s;
    80003d64:	8a5e                	mv	s4,s7
    80003d66:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d68:	01278963          	beq	a5,s2,80003d7a <namex+0x130>
    80003d6c:	dfbd                	beqz	a5,80003cea <namex+0xa0>
    path++;
    80003d6e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d70:	0004c783          	lbu	a5,0(s1)
    80003d74:	ff279ce3          	bne	a5,s2,80003d6c <namex+0x122>
    80003d78:	bf8d                	j	80003cea <namex+0xa0>
    memmove(name, s, len);
    80003d7a:	2601                	sext.w	a2,a2
    80003d7c:	8556                	mv	a0,s5
    80003d7e:	ffffd097          	auipc	ra,0xffffd
    80003d82:	fc8080e7          	jalr	-56(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003d86:	9a56                	add	s4,s4,s5
    80003d88:	000a0023          	sb	zero,0(s4)
    80003d8c:	bf9d                	j	80003d02 <namex+0xb8>
  if(nameiparent){
    80003d8e:	f20b03e3          	beqz	s6,80003cb4 <namex+0x6a>
    iput(ip);
    80003d92:	854e                	mv	a0,s3
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	adc080e7          	jalr	-1316(ra) # 80003870 <iput>
    return 0;
    80003d9c:	4981                	li	s3,0
    80003d9e:	bf19                	j	80003cb4 <namex+0x6a>
  if(*path == 0)
    80003da0:	d7fd                	beqz	a5,80003d8e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003da2:	0004c783          	lbu	a5,0(s1)
    80003da6:	85a6                	mv	a1,s1
    80003da8:	b7d1                	j	80003d6c <namex+0x122>

0000000080003daa <dirlink>:
{
    80003daa:	7139                	addi	sp,sp,-64
    80003dac:	fc06                	sd	ra,56(sp)
    80003dae:	f822                	sd	s0,48(sp)
    80003db0:	f426                	sd	s1,40(sp)
    80003db2:	f04a                	sd	s2,32(sp)
    80003db4:	ec4e                	sd	s3,24(sp)
    80003db6:	e852                	sd	s4,16(sp)
    80003db8:	0080                	addi	s0,sp,64
    80003dba:	892a                	mv	s2,a0
    80003dbc:	8a2e                	mv	s4,a1
    80003dbe:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003dc0:	4601                	li	a2,0
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	dd8080e7          	jalr	-552(ra) # 80003b9a <dirlookup>
    80003dca:	e93d                	bnez	a0,80003e40 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dcc:	04c92483          	lw	s1,76(s2)
    80003dd0:	c49d                	beqz	s1,80003dfe <dirlink+0x54>
    80003dd2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dd4:	4741                	li	a4,16
    80003dd6:	86a6                	mv	a3,s1
    80003dd8:	fc040613          	addi	a2,s0,-64
    80003ddc:	4581                	li	a1,0
    80003dde:	854a                	mv	a0,s2
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	b8a080e7          	jalr	-1142(ra) # 8000396a <readi>
    80003de8:	47c1                	li	a5,16
    80003dea:	06f51163          	bne	a0,a5,80003e4c <dirlink+0xa2>
    if(de.inum == 0)
    80003dee:	fc045783          	lhu	a5,-64(s0)
    80003df2:	c791                	beqz	a5,80003dfe <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003df4:	24c1                	addiw	s1,s1,16
    80003df6:	04c92783          	lw	a5,76(s2)
    80003dfa:	fcf4ede3          	bltu	s1,a5,80003dd4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003dfe:	4639                	li	a2,14
    80003e00:	85d2                	mv	a1,s4
    80003e02:	fc240513          	addi	a0,s0,-62
    80003e06:	ffffd097          	auipc	ra,0xffffd
    80003e0a:	ff4080e7          	jalr	-12(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003e0e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e12:	4741                	li	a4,16
    80003e14:	86a6                	mv	a3,s1
    80003e16:	fc040613          	addi	a2,s0,-64
    80003e1a:	4581                	li	a1,0
    80003e1c:	854a                	mv	a0,s2
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	c44080e7          	jalr	-956(ra) # 80003a62 <writei>
    80003e26:	1541                	addi	a0,a0,-16
    80003e28:	00a03533          	snez	a0,a0
    80003e2c:	40a00533          	neg	a0,a0
}
    80003e30:	70e2                	ld	ra,56(sp)
    80003e32:	7442                	ld	s0,48(sp)
    80003e34:	74a2                	ld	s1,40(sp)
    80003e36:	7902                	ld	s2,32(sp)
    80003e38:	69e2                	ld	s3,24(sp)
    80003e3a:	6a42                	ld	s4,16(sp)
    80003e3c:	6121                	addi	sp,sp,64
    80003e3e:	8082                	ret
    iput(ip);
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	a30080e7          	jalr	-1488(ra) # 80003870 <iput>
    return -1;
    80003e48:	557d                	li	a0,-1
    80003e4a:	b7dd                	j	80003e30 <dirlink+0x86>
      panic("dirlink read");
    80003e4c:	00004517          	auipc	a0,0x4
    80003e50:	7ec50513          	addi	a0,a0,2028 # 80008638 <syscalls+0x1d0>
    80003e54:	ffffc097          	auipc	ra,0xffffc
    80003e58:	6f0080e7          	jalr	1776(ra) # 80000544 <panic>

0000000080003e5c <namei>:

struct inode*
namei(char *path)
{
    80003e5c:	1101                	addi	sp,sp,-32
    80003e5e:	ec06                	sd	ra,24(sp)
    80003e60:	e822                	sd	s0,16(sp)
    80003e62:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e64:	fe040613          	addi	a2,s0,-32
    80003e68:	4581                	li	a1,0
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	de0080e7          	jalr	-544(ra) # 80003c4a <namex>
}
    80003e72:	60e2                	ld	ra,24(sp)
    80003e74:	6442                	ld	s0,16(sp)
    80003e76:	6105                	addi	sp,sp,32
    80003e78:	8082                	ret

0000000080003e7a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e7a:	1141                	addi	sp,sp,-16
    80003e7c:	e406                	sd	ra,8(sp)
    80003e7e:	e022                	sd	s0,0(sp)
    80003e80:	0800                	addi	s0,sp,16
    80003e82:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e84:	4585                	li	a1,1
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	dc4080e7          	jalr	-572(ra) # 80003c4a <namex>
}
    80003e8e:	60a2                	ld	ra,8(sp)
    80003e90:	6402                	ld	s0,0(sp)
    80003e92:	0141                	addi	sp,sp,16
    80003e94:	8082                	ret

0000000080003e96 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e96:	1101                	addi	sp,sp,-32
    80003e98:	ec06                	sd	ra,24(sp)
    80003e9a:	e822                	sd	s0,16(sp)
    80003e9c:	e426                	sd	s1,8(sp)
    80003e9e:	e04a                	sd	s2,0(sp)
    80003ea0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ea2:	0001d917          	auipc	s2,0x1d
    80003ea6:	d4690913          	addi	s2,s2,-698 # 80020be8 <log>
    80003eaa:	01892583          	lw	a1,24(s2)
    80003eae:	02892503          	lw	a0,40(s2)
    80003eb2:	fffff097          	auipc	ra,0xfffff
    80003eb6:	fea080e7          	jalr	-22(ra) # 80002e9c <bread>
    80003eba:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ebc:	02c92683          	lw	a3,44(s2)
    80003ec0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ec2:	02d05763          	blez	a3,80003ef0 <write_head+0x5a>
    80003ec6:	0001d797          	auipc	a5,0x1d
    80003eca:	d5278793          	addi	a5,a5,-686 # 80020c18 <log+0x30>
    80003ece:	05c50713          	addi	a4,a0,92
    80003ed2:	36fd                	addiw	a3,a3,-1
    80003ed4:	1682                	slli	a3,a3,0x20
    80003ed6:	9281                	srli	a3,a3,0x20
    80003ed8:	068a                	slli	a3,a3,0x2
    80003eda:	0001d617          	auipc	a2,0x1d
    80003ede:	d4260613          	addi	a2,a2,-702 # 80020c1c <log+0x34>
    80003ee2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ee4:	4390                	lw	a2,0(a5)
    80003ee6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ee8:	0791                	addi	a5,a5,4
    80003eea:	0711                	addi	a4,a4,4
    80003eec:	fed79ce3          	bne	a5,a3,80003ee4 <write_head+0x4e>
  }
  bwrite(buf);
    80003ef0:	8526                	mv	a0,s1
    80003ef2:	fffff097          	auipc	ra,0xfffff
    80003ef6:	09c080e7          	jalr	156(ra) # 80002f8e <bwrite>
  brelse(buf);
    80003efa:	8526                	mv	a0,s1
    80003efc:	fffff097          	auipc	ra,0xfffff
    80003f00:	0d0080e7          	jalr	208(ra) # 80002fcc <brelse>
}
    80003f04:	60e2                	ld	ra,24(sp)
    80003f06:	6442                	ld	s0,16(sp)
    80003f08:	64a2                	ld	s1,8(sp)
    80003f0a:	6902                	ld	s2,0(sp)
    80003f0c:	6105                	addi	sp,sp,32
    80003f0e:	8082                	ret

0000000080003f10 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f10:	0001d797          	auipc	a5,0x1d
    80003f14:	d047a783          	lw	a5,-764(a5) # 80020c14 <log+0x2c>
    80003f18:	0af05d63          	blez	a5,80003fd2 <install_trans+0xc2>
{
    80003f1c:	7139                	addi	sp,sp,-64
    80003f1e:	fc06                	sd	ra,56(sp)
    80003f20:	f822                	sd	s0,48(sp)
    80003f22:	f426                	sd	s1,40(sp)
    80003f24:	f04a                	sd	s2,32(sp)
    80003f26:	ec4e                	sd	s3,24(sp)
    80003f28:	e852                	sd	s4,16(sp)
    80003f2a:	e456                	sd	s5,8(sp)
    80003f2c:	e05a                	sd	s6,0(sp)
    80003f2e:	0080                	addi	s0,sp,64
    80003f30:	8b2a                	mv	s6,a0
    80003f32:	0001da97          	auipc	s5,0x1d
    80003f36:	ce6a8a93          	addi	s5,s5,-794 # 80020c18 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f3a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f3c:	0001d997          	auipc	s3,0x1d
    80003f40:	cac98993          	addi	s3,s3,-852 # 80020be8 <log>
    80003f44:	a035                	j	80003f70 <install_trans+0x60>
      bunpin(dbuf);
    80003f46:	8526                	mv	a0,s1
    80003f48:	fffff097          	auipc	ra,0xfffff
    80003f4c:	15e080e7          	jalr	350(ra) # 800030a6 <bunpin>
    brelse(lbuf);
    80003f50:	854a                	mv	a0,s2
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	07a080e7          	jalr	122(ra) # 80002fcc <brelse>
    brelse(dbuf);
    80003f5a:	8526                	mv	a0,s1
    80003f5c:	fffff097          	auipc	ra,0xfffff
    80003f60:	070080e7          	jalr	112(ra) # 80002fcc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f64:	2a05                	addiw	s4,s4,1
    80003f66:	0a91                	addi	s5,s5,4
    80003f68:	02c9a783          	lw	a5,44(s3)
    80003f6c:	04fa5963          	bge	s4,a5,80003fbe <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f70:	0189a583          	lw	a1,24(s3)
    80003f74:	014585bb          	addw	a1,a1,s4
    80003f78:	2585                	addiw	a1,a1,1
    80003f7a:	0289a503          	lw	a0,40(s3)
    80003f7e:	fffff097          	auipc	ra,0xfffff
    80003f82:	f1e080e7          	jalr	-226(ra) # 80002e9c <bread>
    80003f86:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f88:	000aa583          	lw	a1,0(s5)
    80003f8c:	0289a503          	lw	a0,40(s3)
    80003f90:	fffff097          	auipc	ra,0xfffff
    80003f94:	f0c080e7          	jalr	-244(ra) # 80002e9c <bread>
    80003f98:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f9a:	40000613          	li	a2,1024
    80003f9e:	05890593          	addi	a1,s2,88
    80003fa2:	05850513          	addi	a0,a0,88
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	da0080e7          	jalr	-608(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fae:	8526                	mv	a0,s1
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	fde080e7          	jalr	-34(ra) # 80002f8e <bwrite>
    if(recovering == 0)
    80003fb8:	f80b1ce3          	bnez	s6,80003f50 <install_trans+0x40>
    80003fbc:	b769                	j	80003f46 <install_trans+0x36>
}
    80003fbe:	70e2                	ld	ra,56(sp)
    80003fc0:	7442                	ld	s0,48(sp)
    80003fc2:	74a2                	ld	s1,40(sp)
    80003fc4:	7902                	ld	s2,32(sp)
    80003fc6:	69e2                	ld	s3,24(sp)
    80003fc8:	6a42                	ld	s4,16(sp)
    80003fca:	6aa2                	ld	s5,8(sp)
    80003fcc:	6b02                	ld	s6,0(sp)
    80003fce:	6121                	addi	sp,sp,64
    80003fd0:	8082                	ret
    80003fd2:	8082                	ret

0000000080003fd4 <initlog>:
{
    80003fd4:	7179                	addi	sp,sp,-48
    80003fd6:	f406                	sd	ra,40(sp)
    80003fd8:	f022                	sd	s0,32(sp)
    80003fda:	ec26                	sd	s1,24(sp)
    80003fdc:	e84a                	sd	s2,16(sp)
    80003fde:	e44e                	sd	s3,8(sp)
    80003fe0:	1800                	addi	s0,sp,48
    80003fe2:	892a                	mv	s2,a0
    80003fe4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fe6:	0001d497          	auipc	s1,0x1d
    80003fea:	c0248493          	addi	s1,s1,-1022 # 80020be8 <log>
    80003fee:	00004597          	auipc	a1,0x4
    80003ff2:	65a58593          	addi	a1,a1,1626 # 80008648 <syscalls+0x1e0>
    80003ff6:	8526                	mv	a0,s1
    80003ff8:	ffffd097          	auipc	ra,0xffffd
    80003ffc:	b62080e7          	jalr	-1182(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004000:	0149a583          	lw	a1,20(s3)
    80004004:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004006:	0109a783          	lw	a5,16(s3)
    8000400a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000400c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004010:	854a                	mv	a0,s2
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	e8a080e7          	jalr	-374(ra) # 80002e9c <bread>
  log.lh.n = lh->n;
    8000401a:	4d3c                	lw	a5,88(a0)
    8000401c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000401e:	02f05563          	blez	a5,80004048 <initlog+0x74>
    80004022:	05c50713          	addi	a4,a0,92
    80004026:	0001d697          	auipc	a3,0x1d
    8000402a:	bf268693          	addi	a3,a3,-1038 # 80020c18 <log+0x30>
    8000402e:	37fd                	addiw	a5,a5,-1
    80004030:	1782                	slli	a5,a5,0x20
    80004032:	9381                	srli	a5,a5,0x20
    80004034:	078a                	slli	a5,a5,0x2
    80004036:	06050613          	addi	a2,a0,96
    8000403a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000403c:	4310                	lw	a2,0(a4)
    8000403e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004040:	0711                	addi	a4,a4,4
    80004042:	0691                	addi	a3,a3,4
    80004044:	fef71ce3          	bne	a4,a5,8000403c <initlog+0x68>
  brelse(buf);
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	f84080e7          	jalr	-124(ra) # 80002fcc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004050:	4505                	li	a0,1
    80004052:	00000097          	auipc	ra,0x0
    80004056:	ebe080e7          	jalr	-322(ra) # 80003f10 <install_trans>
  log.lh.n = 0;
    8000405a:	0001d797          	auipc	a5,0x1d
    8000405e:	ba07ad23          	sw	zero,-1094(a5) # 80020c14 <log+0x2c>
  write_head(); // clear the log
    80004062:	00000097          	auipc	ra,0x0
    80004066:	e34080e7          	jalr	-460(ra) # 80003e96 <write_head>
}
    8000406a:	70a2                	ld	ra,40(sp)
    8000406c:	7402                	ld	s0,32(sp)
    8000406e:	64e2                	ld	s1,24(sp)
    80004070:	6942                	ld	s2,16(sp)
    80004072:	69a2                	ld	s3,8(sp)
    80004074:	6145                	addi	sp,sp,48
    80004076:	8082                	ret

0000000080004078 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004078:	1101                	addi	sp,sp,-32
    8000407a:	ec06                	sd	ra,24(sp)
    8000407c:	e822                	sd	s0,16(sp)
    8000407e:	e426                	sd	s1,8(sp)
    80004080:	e04a                	sd	s2,0(sp)
    80004082:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004084:	0001d517          	auipc	a0,0x1d
    80004088:	b6450513          	addi	a0,a0,-1180 # 80020be8 <log>
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	b5e080e7          	jalr	-1186(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004094:	0001d497          	auipc	s1,0x1d
    80004098:	b5448493          	addi	s1,s1,-1196 # 80020be8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000409c:	4979                	li	s2,30
    8000409e:	a039                	j	800040ac <begin_op+0x34>
      sleep(&log, &log.lock);
    800040a0:	85a6                	mv	a1,s1
    800040a2:	8526                	mv	a0,s1
    800040a4:	ffffe097          	auipc	ra,0xffffe
    800040a8:	fc6080e7          	jalr	-58(ra) # 8000206a <sleep>
    if(log.committing){
    800040ac:	50dc                	lw	a5,36(s1)
    800040ae:	fbed                	bnez	a5,800040a0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040b0:	509c                	lw	a5,32(s1)
    800040b2:	0017871b          	addiw	a4,a5,1
    800040b6:	0007069b          	sext.w	a3,a4
    800040ba:	0027179b          	slliw	a5,a4,0x2
    800040be:	9fb9                	addw	a5,a5,a4
    800040c0:	0017979b          	slliw	a5,a5,0x1
    800040c4:	54d8                	lw	a4,44(s1)
    800040c6:	9fb9                	addw	a5,a5,a4
    800040c8:	00f95963          	bge	s2,a5,800040da <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040cc:	85a6                	mv	a1,s1
    800040ce:	8526                	mv	a0,s1
    800040d0:	ffffe097          	auipc	ra,0xffffe
    800040d4:	f9a080e7          	jalr	-102(ra) # 8000206a <sleep>
    800040d8:	bfd1                	j	800040ac <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040da:	0001d517          	auipc	a0,0x1d
    800040de:	b0e50513          	addi	a0,a0,-1266 # 80020be8 <log>
    800040e2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040e4:	ffffd097          	auipc	ra,0xffffd
    800040e8:	bba080e7          	jalr	-1094(ra) # 80000c9e <release>
      break;
    }
  }
}
    800040ec:	60e2                	ld	ra,24(sp)
    800040ee:	6442                	ld	s0,16(sp)
    800040f0:	64a2                	ld	s1,8(sp)
    800040f2:	6902                	ld	s2,0(sp)
    800040f4:	6105                	addi	sp,sp,32
    800040f6:	8082                	ret

00000000800040f8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040f8:	7139                	addi	sp,sp,-64
    800040fa:	fc06                	sd	ra,56(sp)
    800040fc:	f822                	sd	s0,48(sp)
    800040fe:	f426                	sd	s1,40(sp)
    80004100:	f04a                	sd	s2,32(sp)
    80004102:	ec4e                	sd	s3,24(sp)
    80004104:	e852                	sd	s4,16(sp)
    80004106:	e456                	sd	s5,8(sp)
    80004108:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000410a:	0001d497          	auipc	s1,0x1d
    8000410e:	ade48493          	addi	s1,s1,-1314 # 80020be8 <log>
    80004112:	8526                	mv	a0,s1
    80004114:	ffffd097          	auipc	ra,0xffffd
    80004118:	ad6080e7          	jalr	-1322(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    8000411c:	509c                	lw	a5,32(s1)
    8000411e:	37fd                	addiw	a5,a5,-1
    80004120:	0007891b          	sext.w	s2,a5
    80004124:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004126:	50dc                	lw	a5,36(s1)
    80004128:	efb9                	bnez	a5,80004186 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000412a:	06091663          	bnez	s2,80004196 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000412e:	0001d497          	auipc	s1,0x1d
    80004132:	aba48493          	addi	s1,s1,-1350 # 80020be8 <log>
    80004136:	4785                	li	a5,1
    80004138:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000413a:	8526                	mv	a0,s1
    8000413c:	ffffd097          	auipc	ra,0xffffd
    80004140:	b62080e7          	jalr	-1182(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004144:	54dc                	lw	a5,44(s1)
    80004146:	06f04763          	bgtz	a5,800041b4 <end_op+0xbc>
    acquire(&log.lock);
    8000414a:	0001d497          	auipc	s1,0x1d
    8000414e:	a9e48493          	addi	s1,s1,-1378 # 80020be8 <log>
    80004152:	8526                	mv	a0,s1
    80004154:	ffffd097          	auipc	ra,0xffffd
    80004158:	a96080e7          	jalr	-1386(ra) # 80000bea <acquire>
    log.committing = 0;
    8000415c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004160:	8526                	mv	a0,s1
    80004162:	ffffe097          	auipc	ra,0xffffe
    80004166:	f6c080e7          	jalr	-148(ra) # 800020ce <wakeup>
    release(&log.lock);
    8000416a:	8526                	mv	a0,s1
    8000416c:	ffffd097          	auipc	ra,0xffffd
    80004170:	b32080e7          	jalr	-1230(ra) # 80000c9e <release>
}
    80004174:	70e2                	ld	ra,56(sp)
    80004176:	7442                	ld	s0,48(sp)
    80004178:	74a2                	ld	s1,40(sp)
    8000417a:	7902                	ld	s2,32(sp)
    8000417c:	69e2                	ld	s3,24(sp)
    8000417e:	6a42                	ld	s4,16(sp)
    80004180:	6aa2                	ld	s5,8(sp)
    80004182:	6121                	addi	sp,sp,64
    80004184:	8082                	ret
    panic("log.committing");
    80004186:	00004517          	auipc	a0,0x4
    8000418a:	4ca50513          	addi	a0,a0,1226 # 80008650 <syscalls+0x1e8>
    8000418e:	ffffc097          	auipc	ra,0xffffc
    80004192:	3b6080e7          	jalr	950(ra) # 80000544 <panic>
    wakeup(&log);
    80004196:	0001d497          	auipc	s1,0x1d
    8000419a:	a5248493          	addi	s1,s1,-1454 # 80020be8 <log>
    8000419e:	8526                	mv	a0,s1
    800041a0:	ffffe097          	auipc	ra,0xffffe
    800041a4:	f2e080e7          	jalr	-210(ra) # 800020ce <wakeup>
  release(&log.lock);
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	af4080e7          	jalr	-1292(ra) # 80000c9e <release>
  if(do_commit){
    800041b2:	b7c9                	j	80004174 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041b4:	0001da97          	auipc	s5,0x1d
    800041b8:	a64a8a93          	addi	s5,s5,-1436 # 80020c18 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041bc:	0001da17          	auipc	s4,0x1d
    800041c0:	a2ca0a13          	addi	s4,s4,-1492 # 80020be8 <log>
    800041c4:	018a2583          	lw	a1,24(s4)
    800041c8:	012585bb          	addw	a1,a1,s2
    800041cc:	2585                	addiw	a1,a1,1
    800041ce:	028a2503          	lw	a0,40(s4)
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	cca080e7          	jalr	-822(ra) # 80002e9c <bread>
    800041da:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041dc:	000aa583          	lw	a1,0(s5)
    800041e0:	028a2503          	lw	a0,40(s4)
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	cb8080e7          	jalr	-840(ra) # 80002e9c <bread>
    800041ec:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041ee:	40000613          	li	a2,1024
    800041f2:	05850593          	addi	a1,a0,88
    800041f6:	05848513          	addi	a0,s1,88
    800041fa:	ffffd097          	auipc	ra,0xffffd
    800041fe:	b4c080e7          	jalr	-1204(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004202:	8526                	mv	a0,s1
    80004204:	fffff097          	auipc	ra,0xfffff
    80004208:	d8a080e7          	jalr	-630(ra) # 80002f8e <bwrite>
    brelse(from);
    8000420c:	854e                	mv	a0,s3
    8000420e:	fffff097          	auipc	ra,0xfffff
    80004212:	dbe080e7          	jalr	-578(ra) # 80002fcc <brelse>
    brelse(to);
    80004216:	8526                	mv	a0,s1
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	db4080e7          	jalr	-588(ra) # 80002fcc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004220:	2905                	addiw	s2,s2,1
    80004222:	0a91                	addi	s5,s5,4
    80004224:	02ca2783          	lw	a5,44(s4)
    80004228:	f8f94ee3          	blt	s2,a5,800041c4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000422c:	00000097          	auipc	ra,0x0
    80004230:	c6a080e7          	jalr	-918(ra) # 80003e96 <write_head>
    install_trans(0); // Now install writes to home locations
    80004234:	4501                	li	a0,0
    80004236:	00000097          	auipc	ra,0x0
    8000423a:	cda080e7          	jalr	-806(ra) # 80003f10 <install_trans>
    log.lh.n = 0;
    8000423e:	0001d797          	auipc	a5,0x1d
    80004242:	9c07ab23          	sw	zero,-1578(a5) # 80020c14 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	c50080e7          	jalr	-944(ra) # 80003e96 <write_head>
    8000424e:	bdf5                	j	8000414a <end_op+0x52>

0000000080004250 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004250:	1101                	addi	sp,sp,-32
    80004252:	ec06                	sd	ra,24(sp)
    80004254:	e822                	sd	s0,16(sp)
    80004256:	e426                	sd	s1,8(sp)
    80004258:	e04a                	sd	s2,0(sp)
    8000425a:	1000                	addi	s0,sp,32
    8000425c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000425e:	0001d917          	auipc	s2,0x1d
    80004262:	98a90913          	addi	s2,s2,-1654 # 80020be8 <log>
    80004266:	854a                	mv	a0,s2
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	982080e7          	jalr	-1662(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004270:	02c92603          	lw	a2,44(s2)
    80004274:	47f5                	li	a5,29
    80004276:	06c7c563          	blt	a5,a2,800042e0 <log_write+0x90>
    8000427a:	0001d797          	auipc	a5,0x1d
    8000427e:	98a7a783          	lw	a5,-1654(a5) # 80020c04 <log+0x1c>
    80004282:	37fd                	addiw	a5,a5,-1
    80004284:	04f65e63          	bge	a2,a5,800042e0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004288:	0001d797          	auipc	a5,0x1d
    8000428c:	9807a783          	lw	a5,-1664(a5) # 80020c08 <log+0x20>
    80004290:	06f05063          	blez	a5,800042f0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004294:	4781                	li	a5,0
    80004296:	06c05563          	blez	a2,80004300 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000429a:	44cc                	lw	a1,12(s1)
    8000429c:	0001d717          	auipc	a4,0x1d
    800042a0:	97c70713          	addi	a4,a4,-1668 # 80020c18 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042a4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042a6:	4314                	lw	a3,0(a4)
    800042a8:	04b68c63          	beq	a3,a1,80004300 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042ac:	2785                	addiw	a5,a5,1
    800042ae:	0711                	addi	a4,a4,4
    800042b0:	fef61be3          	bne	a2,a5,800042a6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042b4:	0621                	addi	a2,a2,8
    800042b6:	060a                	slli	a2,a2,0x2
    800042b8:	0001d797          	auipc	a5,0x1d
    800042bc:	93078793          	addi	a5,a5,-1744 # 80020be8 <log>
    800042c0:	963e                	add	a2,a2,a5
    800042c2:	44dc                	lw	a5,12(s1)
    800042c4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042c6:	8526                	mv	a0,s1
    800042c8:	fffff097          	auipc	ra,0xfffff
    800042cc:	da2080e7          	jalr	-606(ra) # 8000306a <bpin>
    log.lh.n++;
    800042d0:	0001d717          	auipc	a4,0x1d
    800042d4:	91870713          	addi	a4,a4,-1768 # 80020be8 <log>
    800042d8:	575c                	lw	a5,44(a4)
    800042da:	2785                	addiw	a5,a5,1
    800042dc:	d75c                	sw	a5,44(a4)
    800042de:	a835                	j	8000431a <log_write+0xca>
    panic("too big a transaction");
    800042e0:	00004517          	auipc	a0,0x4
    800042e4:	38050513          	addi	a0,a0,896 # 80008660 <syscalls+0x1f8>
    800042e8:	ffffc097          	auipc	ra,0xffffc
    800042ec:	25c080e7          	jalr	604(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800042f0:	00004517          	auipc	a0,0x4
    800042f4:	38850513          	addi	a0,a0,904 # 80008678 <syscalls+0x210>
    800042f8:	ffffc097          	auipc	ra,0xffffc
    800042fc:	24c080e7          	jalr	588(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004300:	00878713          	addi	a4,a5,8
    80004304:	00271693          	slli	a3,a4,0x2
    80004308:	0001d717          	auipc	a4,0x1d
    8000430c:	8e070713          	addi	a4,a4,-1824 # 80020be8 <log>
    80004310:	9736                	add	a4,a4,a3
    80004312:	44d4                	lw	a3,12(s1)
    80004314:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004316:	faf608e3          	beq	a2,a5,800042c6 <log_write+0x76>
  }
  release(&log.lock);
    8000431a:	0001d517          	auipc	a0,0x1d
    8000431e:	8ce50513          	addi	a0,a0,-1842 # 80020be8 <log>
    80004322:	ffffd097          	auipc	ra,0xffffd
    80004326:	97c080e7          	jalr	-1668(ra) # 80000c9e <release>
}
    8000432a:	60e2                	ld	ra,24(sp)
    8000432c:	6442                	ld	s0,16(sp)
    8000432e:	64a2                	ld	s1,8(sp)
    80004330:	6902                	ld	s2,0(sp)
    80004332:	6105                	addi	sp,sp,32
    80004334:	8082                	ret

0000000080004336 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004336:	1101                	addi	sp,sp,-32
    80004338:	ec06                	sd	ra,24(sp)
    8000433a:	e822                	sd	s0,16(sp)
    8000433c:	e426                	sd	s1,8(sp)
    8000433e:	e04a                	sd	s2,0(sp)
    80004340:	1000                	addi	s0,sp,32
    80004342:	84aa                	mv	s1,a0
    80004344:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004346:	00004597          	auipc	a1,0x4
    8000434a:	35258593          	addi	a1,a1,850 # 80008698 <syscalls+0x230>
    8000434e:	0521                	addi	a0,a0,8
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	80a080e7          	jalr	-2038(ra) # 80000b5a <initlock>
  lk->name = name;
    80004358:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000435c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004360:	0204a423          	sw	zero,40(s1)
}
    80004364:	60e2                	ld	ra,24(sp)
    80004366:	6442                	ld	s0,16(sp)
    80004368:	64a2                	ld	s1,8(sp)
    8000436a:	6902                	ld	s2,0(sp)
    8000436c:	6105                	addi	sp,sp,32
    8000436e:	8082                	ret

0000000080004370 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004370:	1101                	addi	sp,sp,-32
    80004372:	ec06                	sd	ra,24(sp)
    80004374:	e822                	sd	s0,16(sp)
    80004376:	e426                	sd	s1,8(sp)
    80004378:	e04a                	sd	s2,0(sp)
    8000437a:	1000                	addi	s0,sp,32
    8000437c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000437e:	00850913          	addi	s2,a0,8
    80004382:	854a                	mv	a0,s2
    80004384:	ffffd097          	auipc	ra,0xffffd
    80004388:	866080e7          	jalr	-1946(ra) # 80000bea <acquire>
  while (lk->locked) {
    8000438c:	409c                	lw	a5,0(s1)
    8000438e:	cb89                	beqz	a5,800043a0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004390:	85ca                	mv	a1,s2
    80004392:	8526                	mv	a0,s1
    80004394:	ffffe097          	auipc	ra,0xffffe
    80004398:	cd6080e7          	jalr	-810(ra) # 8000206a <sleep>
  while (lk->locked) {
    8000439c:	409c                	lw	a5,0(s1)
    8000439e:	fbed                	bnez	a5,80004390 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043a0:	4785                	li	a5,1
    800043a2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043a4:	ffffd097          	auipc	ra,0xffffd
    800043a8:	622080e7          	jalr	1570(ra) # 800019c6 <myproc>
    800043ac:	591c                	lw	a5,48(a0)
    800043ae:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043b0:	854a                	mv	a0,s2
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	8ec080e7          	jalr	-1812(ra) # 80000c9e <release>
}
    800043ba:	60e2                	ld	ra,24(sp)
    800043bc:	6442                	ld	s0,16(sp)
    800043be:	64a2                	ld	s1,8(sp)
    800043c0:	6902                	ld	s2,0(sp)
    800043c2:	6105                	addi	sp,sp,32
    800043c4:	8082                	ret

00000000800043c6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043c6:	1101                	addi	sp,sp,-32
    800043c8:	ec06                	sd	ra,24(sp)
    800043ca:	e822                	sd	s0,16(sp)
    800043cc:	e426                	sd	s1,8(sp)
    800043ce:	e04a                	sd	s2,0(sp)
    800043d0:	1000                	addi	s0,sp,32
    800043d2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043d4:	00850913          	addi	s2,a0,8
    800043d8:	854a                	mv	a0,s2
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	810080e7          	jalr	-2032(ra) # 80000bea <acquire>
  lk->locked = 0;
    800043e2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043e6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043ea:	8526                	mv	a0,s1
    800043ec:	ffffe097          	auipc	ra,0xffffe
    800043f0:	ce2080e7          	jalr	-798(ra) # 800020ce <wakeup>
  release(&lk->lk);
    800043f4:	854a                	mv	a0,s2
    800043f6:	ffffd097          	auipc	ra,0xffffd
    800043fa:	8a8080e7          	jalr	-1880(ra) # 80000c9e <release>
}
    800043fe:	60e2                	ld	ra,24(sp)
    80004400:	6442                	ld	s0,16(sp)
    80004402:	64a2                	ld	s1,8(sp)
    80004404:	6902                	ld	s2,0(sp)
    80004406:	6105                	addi	sp,sp,32
    80004408:	8082                	ret

000000008000440a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000440a:	7179                	addi	sp,sp,-48
    8000440c:	f406                	sd	ra,40(sp)
    8000440e:	f022                	sd	s0,32(sp)
    80004410:	ec26                	sd	s1,24(sp)
    80004412:	e84a                	sd	s2,16(sp)
    80004414:	e44e                	sd	s3,8(sp)
    80004416:	1800                	addi	s0,sp,48
    80004418:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000441a:	00850913          	addi	s2,a0,8
    8000441e:	854a                	mv	a0,s2
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	7ca080e7          	jalr	1994(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004428:	409c                	lw	a5,0(s1)
    8000442a:	ef99                	bnez	a5,80004448 <holdingsleep+0x3e>
    8000442c:	4481                	li	s1,0
  release(&lk->lk);
    8000442e:	854a                	mv	a0,s2
    80004430:	ffffd097          	auipc	ra,0xffffd
    80004434:	86e080e7          	jalr	-1938(ra) # 80000c9e <release>
  return r;
}
    80004438:	8526                	mv	a0,s1
    8000443a:	70a2                	ld	ra,40(sp)
    8000443c:	7402                	ld	s0,32(sp)
    8000443e:	64e2                	ld	s1,24(sp)
    80004440:	6942                	ld	s2,16(sp)
    80004442:	69a2                	ld	s3,8(sp)
    80004444:	6145                	addi	sp,sp,48
    80004446:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004448:	0284a983          	lw	s3,40(s1)
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	57a080e7          	jalr	1402(ra) # 800019c6 <myproc>
    80004454:	5904                	lw	s1,48(a0)
    80004456:	413484b3          	sub	s1,s1,s3
    8000445a:	0014b493          	seqz	s1,s1
    8000445e:	bfc1                	j	8000442e <holdingsleep+0x24>

0000000080004460 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004460:	1141                	addi	sp,sp,-16
    80004462:	e406                	sd	ra,8(sp)
    80004464:	e022                	sd	s0,0(sp)
    80004466:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004468:	00004597          	auipc	a1,0x4
    8000446c:	24058593          	addi	a1,a1,576 # 800086a8 <syscalls+0x240>
    80004470:	0001d517          	auipc	a0,0x1d
    80004474:	8c050513          	addi	a0,a0,-1856 # 80020d30 <ftable>
    80004478:	ffffc097          	auipc	ra,0xffffc
    8000447c:	6e2080e7          	jalr	1762(ra) # 80000b5a <initlock>
}
    80004480:	60a2                	ld	ra,8(sp)
    80004482:	6402                	ld	s0,0(sp)
    80004484:	0141                	addi	sp,sp,16
    80004486:	8082                	ret

0000000080004488 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004488:	1101                	addi	sp,sp,-32
    8000448a:	ec06                	sd	ra,24(sp)
    8000448c:	e822                	sd	s0,16(sp)
    8000448e:	e426                	sd	s1,8(sp)
    80004490:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004492:	0001d517          	auipc	a0,0x1d
    80004496:	89e50513          	addi	a0,a0,-1890 # 80020d30 <ftable>
    8000449a:	ffffc097          	auipc	ra,0xffffc
    8000449e:	750080e7          	jalr	1872(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044a2:	0001d497          	auipc	s1,0x1d
    800044a6:	8a648493          	addi	s1,s1,-1882 # 80020d48 <ftable+0x18>
    800044aa:	0001e717          	auipc	a4,0x1e
    800044ae:	83e70713          	addi	a4,a4,-1986 # 80021ce8 <disk>
    if(f->ref == 0){
    800044b2:	40dc                	lw	a5,4(s1)
    800044b4:	cf99                	beqz	a5,800044d2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044b6:	02848493          	addi	s1,s1,40
    800044ba:	fee49ce3          	bne	s1,a4,800044b2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044be:	0001d517          	auipc	a0,0x1d
    800044c2:	87250513          	addi	a0,a0,-1934 # 80020d30 <ftable>
    800044c6:	ffffc097          	auipc	ra,0xffffc
    800044ca:	7d8080e7          	jalr	2008(ra) # 80000c9e <release>
  return 0;
    800044ce:	4481                	li	s1,0
    800044d0:	a819                	j	800044e6 <filealloc+0x5e>
      f->ref = 1;
    800044d2:	4785                	li	a5,1
    800044d4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044d6:	0001d517          	auipc	a0,0x1d
    800044da:	85a50513          	addi	a0,a0,-1958 # 80020d30 <ftable>
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	7c0080e7          	jalr	1984(ra) # 80000c9e <release>
}
    800044e6:	8526                	mv	a0,s1
    800044e8:	60e2                	ld	ra,24(sp)
    800044ea:	6442                	ld	s0,16(sp)
    800044ec:	64a2                	ld	s1,8(sp)
    800044ee:	6105                	addi	sp,sp,32
    800044f0:	8082                	ret

00000000800044f2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044f2:	1101                	addi	sp,sp,-32
    800044f4:	ec06                	sd	ra,24(sp)
    800044f6:	e822                	sd	s0,16(sp)
    800044f8:	e426                	sd	s1,8(sp)
    800044fa:	1000                	addi	s0,sp,32
    800044fc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044fe:	0001d517          	auipc	a0,0x1d
    80004502:	83250513          	addi	a0,a0,-1998 # 80020d30 <ftable>
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	6e4080e7          	jalr	1764(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000450e:	40dc                	lw	a5,4(s1)
    80004510:	02f05263          	blez	a5,80004534 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004514:	2785                	addiw	a5,a5,1
    80004516:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004518:	0001d517          	auipc	a0,0x1d
    8000451c:	81850513          	addi	a0,a0,-2024 # 80020d30 <ftable>
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	77e080e7          	jalr	1918(ra) # 80000c9e <release>
  return f;
}
    80004528:	8526                	mv	a0,s1
    8000452a:	60e2                	ld	ra,24(sp)
    8000452c:	6442                	ld	s0,16(sp)
    8000452e:	64a2                	ld	s1,8(sp)
    80004530:	6105                	addi	sp,sp,32
    80004532:	8082                	ret
    panic("filedup");
    80004534:	00004517          	auipc	a0,0x4
    80004538:	17c50513          	addi	a0,a0,380 # 800086b0 <syscalls+0x248>
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	008080e7          	jalr	8(ra) # 80000544 <panic>

0000000080004544 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004544:	7139                	addi	sp,sp,-64
    80004546:	fc06                	sd	ra,56(sp)
    80004548:	f822                	sd	s0,48(sp)
    8000454a:	f426                	sd	s1,40(sp)
    8000454c:	f04a                	sd	s2,32(sp)
    8000454e:	ec4e                	sd	s3,24(sp)
    80004550:	e852                	sd	s4,16(sp)
    80004552:	e456                	sd	s5,8(sp)
    80004554:	0080                	addi	s0,sp,64
    80004556:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004558:	0001c517          	auipc	a0,0x1c
    8000455c:	7d850513          	addi	a0,a0,2008 # 80020d30 <ftable>
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	68a080e7          	jalr	1674(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004568:	40dc                	lw	a5,4(s1)
    8000456a:	06f05163          	blez	a5,800045cc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000456e:	37fd                	addiw	a5,a5,-1
    80004570:	0007871b          	sext.w	a4,a5
    80004574:	c0dc                	sw	a5,4(s1)
    80004576:	06e04363          	bgtz	a4,800045dc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000457a:	0004a903          	lw	s2,0(s1)
    8000457e:	0094ca83          	lbu	s5,9(s1)
    80004582:	0104ba03          	ld	s4,16(s1)
    80004586:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000458a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000458e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004592:	0001c517          	auipc	a0,0x1c
    80004596:	79e50513          	addi	a0,a0,1950 # 80020d30 <ftable>
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	704080e7          	jalr	1796(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    800045a2:	4785                	li	a5,1
    800045a4:	04f90d63          	beq	s2,a5,800045fe <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045a8:	3979                	addiw	s2,s2,-2
    800045aa:	4785                	li	a5,1
    800045ac:	0527e063          	bltu	a5,s2,800045ec <fileclose+0xa8>
    begin_op();
    800045b0:	00000097          	auipc	ra,0x0
    800045b4:	ac8080e7          	jalr	-1336(ra) # 80004078 <begin_op>
    iput(ff.ip);
    800045b8:	854e                	mv	a0,s3
    800045ba:	fffff097          	auipc	ra,0xfffff
    800045be:	2b6080e7          	jalr	694(ra) # 80003870 <iput>
    end_op();
    800045c2:	00000097          	auipc	ra,0x0
    800045c6:	b36080e7          	jalr	-1226(ra) # 800040f8 <end_op>
    800045ca:	a00d                	j	800045ec <fileclose+0xa8>
    panic("fileclose");
    800045cc:	00004517          	auipc	a0,0x4
    800045d0:	0ec50513          	addi	a0,a0,236 # 800086b8 <syscalls+0x250>
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	f70080e7          	jalr	-144(ra) # 80000544 <panic>
    release(&ftable.lock);
    800045dc:	0001c517          	auipc	a0,0x1c
    800045e0:	75450513          	addi	a0,a0,1876 # 80020d30 <ftable>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	6ba080e7          	jalr	1722(ra) # 80000c9e <release>
  }
}
    800045ec:	70e2                	ld	ra,56(sp)
    800045ee:	7442                	ld	s0,48(sp)
    800045f0:	74a2                	ld	s1,40(sp)
    800045f2:	7902                	ld	s2,32(sp)
    800045f4:	69e2                	ld	s3,24(sp)
    800045f6:	6a42                	ld	s4,16(sp)
    800045f8:	6aa2                	ld	s5,8(sp)
    800045fa:	6121                	addi	sp,sp,64
    800045fc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045fe:	85d6                	mv	a1,s5
    80004600:	8552                	mv	a0,s4
    80004602:	00000097          	auipc	ra,0x0
    80004606:	34c080e7          	jalr	844(ra) # 8000494e <pipeclose>
    8000460a:	b7cd                	j	800045ec <fileclose+0xa8>

000000008000460c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000460c:	715d                	addi	sp,sp,-80
    8000460e:	e486                	sd	ra,72(sp)
    80004610:	e0a2                	sd	s0,64(sp)
    80004612:	fc26                	sd	s1,56(sp)
    80004614:	f84a                	sd	s2,48(sp)
    80004616:	f44e                	sd	s3,40(sp)
    80004618:	0880                	addi	s0,sp,80
    8000461a:	84aa                	mv	s1,a0
    8000461c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000461e:	ffffd097          	auipc	ra,0xffffd
    80004622:	3a8080e7          	jalr	936(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004626:	409c                	lw	a5,0(s1)
    80004628:	37f9                	addiw	a5,a5,-2
    8000462a:	4705                	li	a4,1
    8000462c:	04f76763          	bltu	a4,a5,8000467a <filestat+0x6e>
    80004630:	892a                	mv	s2,a0
    ilock(f->ip);
    80004632:	6c88                	ld	a0,24(s1)
    80004634:	fffff097          	auipc	ra,0xfffff
    80004638:	082080e7          	jalr	130(ra) # 800036b6 <ilock>
    stati(f->ip, &st);
    8000463c:	fb840593          	addi	a1,s0,-72
    80004640:	6c88                	ld	a0,24(s1)
    80004642:	fffff097          	auipc	ra,0xfffff
    80004646:	2fe080e7          	jalr	766(ra) # 80003940 <stati>
    iunlock(f->ip);
    8000464a:	6c88                	ld	a0,24(s1)
    8000464c:	fffff097          	auipc	ra,0xfffff
    80004650:	12c080e7          	jalr	300(ra) # 80003778 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004654:	46e1                	li	a3,24
    80004656:	fb840613          	addi	a2,s0,-72
    8000465a:	85ce                	mv	a1,s3
    8000465c:	05093503          	ld	a0,80(s2)
    80004660:	ffffd097          	auipc	ra,0xffffd
    80004664:	024080e7          	jalr	36(ra) # 80001684 <copyout>
    80004668:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000466c:	60a6                	ld	ra,72(sp)
    8000466e:	6406                	ld	s0,64(sp)
    80004670:	74e2                	ld	s1,56(sp)
    80004672:	7942                	ld	s2,48(sp)
    80004674:	79a2                	ld	s3,40(sp)
    80004676:	6161                	addi	sp,sp,80
    80004678:	8082                	ret
  return -1;
    8000467a:	557d                	li	a0,-1
    8000467c:	bfc5                	j	8000466c <filestat+0x60>

000000008000467e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000467e:	7179                	addi	sp,sp,-48
    80004680:	f406                	sd	ra,40(sp)
    80004682:	f022                	sd	s0,32(sp)
    80004684:	ec26                	sd	s1,24(sp)
    80004686:	e84a                	sd	s2,16(sp)
    80004688:	e44e                	sd	s3,8(sp)
    8000468a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000468c:	00854783          	lbu	a5,8(a0)
    80004690:	c3d5                	beqz	a5,80004734 <fileread+0xb6>
    80004692:	84aa                	mv	s1,a0
    80004694:	89ae                	mv	s3,a1
    80004696:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004698:	411c                	lw	a5,0(a0)
    8000469a:	4705                	li	a4,1
    8000469c:	04e78963          	beq	a5,a4,800046ee <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046a0:	470d                	li	a4,3
    800046a2:	04e78d63          	beq	a5,a4,800046fc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046a6:	4709                	li	a4,2
    800046a8:	06e79e63          	bne	a5,a4,80004724 <fileread+0xa6>
    ilock(f->ip);
    800046ac:	6d08                	ld	a0,24(a0)
    800046ae:	fffff097          	auipc	ra,0xfffff
    800046b2:	008080e7          	jalr	8(ra) # 800036b6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046b6:	874a                	mv	a4,s2
    800046b8:	5094                	lw	a3,32(s1)
    800046ba:	864e                	mv	a2,s3
    800046bc:	4585                	li	a1,1
    800046be:	6c88                	ld	a0,24(s1)
    800046c0:	fffff097          	auipc	ra,0xfffff
    800046c4:	2aa080e7          	jalr	682(ra) # 8000396a <readi>
    800046c8:	892a                	mv	s2,a0
    800046ca:	00a05563          	blez	a0,800046d4 <fileread+0x56>
      f->off += r;
    800046ce:	509c                	lw	a5,32(s1)
    800046d0:	9fa9                	addw	a5,a5,a0
    800046d2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046d4:	6c88                	ld	a0,24(s1)
    800046d6:	fffff097          	auipc	ra,0xfffff
    800046da:	0a2080e7          	jalr	162(ra) # 80003778 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046de:	854a                	mv	a0,s2
    800046e0:	70a2                	ld	ra,40(sp)
    800046e2:	7402                	ld	s0,32(sp)
    800046e4:	64e2                	ld	s1,24(sp)
    800046e6:	6942                	ld	s2,16(sp)
    800046e8:	69a2                	ld	s3,8(sp)
    800046ea:	6145                	addi	sp,sp,48
    800046ec:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046ee:	6908                	ld	a0,16(a0)
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	3ce080e7          	jalr	974(ra) # 80004abe <piperead>
    800046f8:	892a                	mv	s2,a0
    800046fa:	b7d5                	j	800046de <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046fc:	02451783          	lh	a5,36(a0)
    80004700:	03079693          	slli	a3,a5,0x30
    80004704:	92c1                	srli	a3,a3,0x30
    80004706:	4725                	li	a4,9
    80004708:	02d76863          	bltu	a4,a3,80004738 <fileread+0xba>
    8000470c:	0792                	slli	a5,a5,0x4
    8000470e:	0001c717          	auipc	a4,0x1c
    80004712:	58270713          	addi	a4,a4,1410 # 80020c90 <devsw>
    80004716:	97ba                	add	a5,a5,a4
    80004718:	639c                	ld	a5,0(a5)
    8000471a:	c38d                	beqz	a5,8000473c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000471c:	4505                	li	a0,1
    8000471e:	9782                	jalr	a5
    80004720:	892a                	mv	s2,a0
    80004722:	bf75                	j	800046de <fileread+0x60>
    panic("fileread");
    80004724:	00004517          	auipc	a0,0x4
    80004728:	fa450513          	addi	a0,a0,-92 # 800086c8 <syscalls+0x260>
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	e18080e7          	jalr	-488(ra) # 80000544 <panic>
    return -1;
    80004734:	597d                	li	s2,-1
    80004736:	b765                	j	800046de <fileread+0x60>
      return -1;
    80004738:	597d                	li	s2,-1
    8000473a:	b755                	j	800046de <fileread+0x60>
    8000473c:	597d                	li	s2,-1
    8000473e:	b745                	j	800046de <fileread+0x60>

0000000080004740 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004740:	715d                	addi	sp,sp,-80
    80004742:	e486                	sd	ra,72(sp)
    80004744:	e0a2                	sd	s0,64(sp)
    80004746:	fc26                	sd	s1,56(sp)
    80004748:	f84a                	sd	s2,48(sp)
    8000474a:	f44e                	sd	s3,40(sp)
    8000474c:	f052                	sd	s4,32(sp)
    8000474e:	ec56                	sd	s5,24(sp)
    80004750:	e85a                	sd	s6,16(sp)
    80004752:	e45e                	sd	s7,8(sp)
    80004754:	e062                	sd	s8,0(sp)
    80004756:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004758:	00954783          	lbu	a5,9(a0)
    8000475c:	10078663          	beqz	a5,80004868 <filewrite+0x128>
    80004760:	892a                	mv	s2,a0
    80004762:	8aae                	mv	s5,a1
    80004764:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004766:	411c                	lw	a5,0(a0)
    80004768:	4705                	li	a4,1
    8000476a:	02e78263          	beq	a5,a4,8000478e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000476e:	470d                	li	a4,3
    80004770:	02e78663          	beq	a5,a4,8000479c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004774:	4709                	li	a4,2
    80004776:	0ee79163          	bne	a5,a4,80004858 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000477a:	0ac05d63          	blez	a2,80004834 <filewrite+0xf4>
    int i = 0;
    8000477e:	4981                	li	s3,0
    80004780:	6b05                	lui	s6,0x1
    80004782:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004786:	6b85                	lui	s7,0x1
    80004788:	c00b8b9b          	addiw	s7,s7,-1024
    8000478c:	a861                	j	80004824 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000478e:	6908                	ld	a0,16(a0)
    80004790:	00000097          	auipc	ra,0x0
    80004794:	22e080e7          	jalr	558(ra) # 800049be <pipewrite>
    80004798:	8a2a                	mv	s4,a0
    8000479a:	a045                	j	8000483a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000479c:	02451783          	lh	a5,36(a0)
    800047a0:	03079693          	slli	a3,a5,0x30
    800047a4:	92c1                	srli	a3,a3,0x30
    800047a6:	4725                	li	a4,9
    800047a8:	0cd76263          	bltu	a4,a3,8000486c <filewrite+0x12c>
    800047ac:	0792                	slli	a5,a5,0x4
    800047ae:	0001c717          	auipc	a4,0x1c
    800047b2:	4e270713          	addi	a4,a4,1250 # 80020c90 <devsw>
    800047b6:	97ba                	add	a5,a5,a4
    800047b8:	679c                	ld	a5,8(a5)
    800047ba:	cbdd                	beqz	a5,80004870 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047bc:	4505                	li	a0,1
    800047be:	9782                	jalr	a5
    800047c0:	8a2a                	mv	s4,a0
    800047c2:	a8a5                	j	8000483a <filewrite+0xfa>
    800047c4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047c8:	00000097          	auipc	ra,0x0
    800047cc:	8b0080e7          	jalr	-1872(ra) # 80004078 <begin_op>
      ilock(f->ip);
    800047d0:	01893503          	ld	a0,24(s2)
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	ee2080e7          	jalr	-286(ra) # 800036b6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047dc:	8762                	mv	a4,s8
    800047de:	02092683          	lw	a3,32(s2)
    800047e2:	01598633          	add	a2,s3,s5
    800047e6:	4585                	li	a1,1
    800047e8:	01893503          	ld	a0,24(s2)
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	276080e7          	jalr	630(ra) # 80003a62 <writei>
    800047f4:	84aa                	mv	s1,a0
    800047f6:	00a05763          	blez	a0,80004804 <filewrite+0xc4>
        f->off += r;
    800047fa:	02092783          	lw	a5,32(s2)
    800047fe:	9fa9                	addw	a5,a5,a0
    80004800:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004804:	01893503          	ld	a0,24(s2)
    80004808:	fffff097          	auipc	ra,0xfffff
    8000480c:	f70080e7          	jalr	-144(ra) # 80003778 <iunlock>
      end_op();
    80004810:	00000097          	auipc	ra,0x0
    80004814:	8e8080e7          	jalr	-1816(ra) # 800040f8 <end_op>

      if(r != n1){
    80004818:	009c1f63          	bne	s8,s1,80004836 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000481c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004820:	0149db63          	bge	s3,s4,80004836 <filewrite+0xf6>
      int n1 = n - i;
    80004824:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004828:	84be                	mv	s1,a5
    8000482a:	2781                	sext.w	a5,a5
    8000482c:	f8fb5ce3          	bge	s6,a5,800047c4 <filewrite+0x84>
    80004830:	84de                	mv	s1,s7
    80004832:	bf49                	j	800047c4 <filewrite+0x84>
    int i = 0;
    80004834:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004836:	013a1f63          	bne	s4,s3,80004854 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000483a:	8552                	mv	a0,s4
    8000483c:	60a6                	ld	ra,72(sp)
    8000483e:	6406                	ld	s0,64(sp)
    80004840:	74e2                	ld	s1,56(sp)
    80004842:	7942                	ld	s2,48(sp)
    80004844:	79a2                	ld	s3,40(sp)
    80004846:	7a02                	ld	s4,32(sp)
    80004848:	6ae2                	ld	s5,24(sp)
    8000484a:	6b42                	ld	s6,16(sp)
    8000484c:	6ba2                	ld	s7,8(sp)
    8000484e:	6c02                	ld	s8,0(sp)
    80004850:	6161                	addi	sp,sp,80
    80004852:	8082                	ret
    ret = (i == n ? n : -1);
    80004854:	5a7d                	li	s4,-1
    80004856:	b7d5                	j	8000483a <filewrite+0xfa>
    panic("filewrite");
    80004858:	00004517          	auipc	a0,0x4
    8000485c:	e8050513          	addi	a0,a0,-384 # 800086d8 <syscalls+0x270>
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	ce4080e7          	jalr	-796(ra) # 80000544 <panic>
    return -1;
    80004868:	5a7d                	li	s4,-1
    8000486a:	bfc1                	j	8000483a <filewrite+0xfa>
      return -1;
    8000486c:	5a7d                	li	s4,-1
    8000486e:	b7f1                	j	8000483a <filewrite+0xfa>
    80004870:	5a7d                	li	s4,-1
    80004872:	b7e1                	j	8000483a <filewrite+0xfa>

0000000080004874 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004874:	7179                	addi	sp,sp,-48
    80004876:	f406                	sd	ra,40(sp)
    80004878:	f022                	sd	s0,32(sp)
    8000487a:	ec26                	sd	s1,24(sp)
    8000487c:	e84a                	sd	s2,16(sp)
    8000487e:	e44e                	sd	s3,8(sp)
    80004880:	e052                	sd	s4,0(sp)
    80004882:	1800                	addi	s0,sp,48
    80004884:	84aa                	mv	s1,a0
    80004886:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004888:	0005b023          	sd	zero,0(a1)
    8000488c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004890:	00000097          	auipc	ra,0x0
    80004894:	bf8080e7          	jalr	-1032(ra) # 80004488 <filealloc>
    80004898:	e088                	sd	a0,0(s1)
    8000489a:	c551                	beqz	a0,80004926 <pipealloc+0xb2>
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	bec080e7          	jalr	-1044(ra) # 80004488 <filealloc>
    800048a4:	00aa3023          	sd	a0,0(s4)
    800048a8:	c92d                	beqz	a0,8000491a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	250080e7          	jalr	592(ra) # 80000afa <kalloc>
    800048b2:	892a                	mv	s2,a0
    800048b4:	c125                	beqz	a0,80004914 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048b6:	4985                	li	s3,1
    800048b8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048bc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048c0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048c4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048c8:	00004597          	auipc	a1,0x4
    800048cc:	e2058593          	addi	a1,a1,-480 # 800086e8 <syscalls+0x280>
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	28a080e7          	jalr	650(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800048d8:	609c                	ld	a5,0(s1)
    800048da:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048de:	609c                	ld	a5,0(s1)
    800048e0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048e4:	609c                	ld	a5,0(s1)
    800048e6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048ea:	609c                	ld	a5,0(s1)
    800048ec:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048f0:	000a3783          	ld	a5,0(s4)
    800048f4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048f8:	000a3783          	ld	a5,0(s4)
    800048fc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004900:	000a3783          	ld	a5,0(s4)
    80004904:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004908:	000a3783          	ld	a5,0(s4)
    8000490c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004910:	4501                	li	a0,0
    80004912:	a025                	j	8000493a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004914:	6088                	ld	a0,0(s1)
    80004916:	e501                	bnez	a0,8000491e <pipealloc+0xaa>
    80004918:	a039                	j	80004926 <pipealloc+0xb2>
    8000491a:	6088                	ld	a0,0(s1)
    8000491c:	c51d                	beqz	a0,8000494a <pipealloc+0xd6>
    fileclose(*f0);
    8000491e:	00000097          	auipc	ra,0x0
    80004922:	c26080e7          	jalr	-986(ra) # 80004544 <fileclose>
  if(*f1)
    80004926:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000492a:	557d                	li	a0,-1
  if(*f1)
    8000492c:	c799                	beqz	a5,8000493a <pipealloc+0xc6>
    fileclose(*f1);
    8000492e:	853e                	mv	a0,a5
    80004930:	00000097          	auipc	ra,0x0
    80004934:	c14080e7          	jalr	-1004(ra) # 80004544 <fileclose>
  return -1;
    80004938:	557d                	li	a0,-1
}
    8000493a:	70a2                	ld	ra,40(sp)
    8000493c:	7402                	ld	s0,32(sp)
    8000493e:	64e2                	ld	s1,24(sp)
    80004940:	6942                	ld	s2,16(sp)
    80004942:	69a2                	ld	s3,8(sp)
    80004944:	6a02                	ld	s4,0(sp)
    80004946:	6145                	addi	sp,sp,48
    80004948:	8082                	ret
  return -1;
    8000494a:	557d                	li	a0,-1
    8000494c:	b7fd                	j	8000493a <pipealloc+0xc6>

000000008000494e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000494e:	1101                	addi	sp,sp,-32
    80004950:	ec06                	sd	ra,24(sp)
    80004952:	e822                	sd	s0,16(sp)
    80004954:	e426                	sd	s1,8(sp)
    80004956:	e04a                	sd	s2,0(sp)
    80004958:	1000                	addi	s0,sp,32
    8000495a:	84aa                	mv	s1,a0
    8000495c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	28c080e7          	jalr	652(ra) # 80000bea <acquire>
  if(writable){
    80004966:	02090d63          	beqz	s2,800049a0 <pipeclose+0x52>
    pi->writeopen = 0;
    8000496a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000496e:	21848513          	addi	a0,s1,536
    80004972:	ffffd097          	auipc	ra,0xffffd
    80004976:	75c080e7          	jalr	1884(ra) # 800020ce <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000497a:	2204b783          	ld	a5,544(s1)
    8000497e:	eb95                	bnez	a5,800049b2 <pipeclose+0x64>
    release(&pi->lock);
    80004980:	8526                	mv	a0,s1
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	31c080e7          	jalr	796(ra) # 80000c9e <release>
    kfree((char*)pi);
    8000498a:	8526                	mv	a0,s1
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	072080e7          	jalr	114(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004994:	60e2                	ld	ra,24(sp)
    80004996:	6442                	ld	s0,16(sp)
    80004998:	64a2                	ld	s1,8(sp)
    8000499a:	6902                	ld	s2,0(sp)
    8000499c:	6105                	addi	sp,sp,32
    8000499e:	8082                	ret
    pi->readopen = 0;
    800049a0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049a4:	21c48513          	addi	a0,s1,540
    800049a8:	ffffd097          	auipc	ra,0xffffd
    800049ac:	726080e7          	jalr	1830(ra) # 800020ce <wakeup>
    800049b0:	b7e9                	j	8000497a <pipeclose+0x2c>
    release(&pi->lock);
    800049b2:	8526                	mv	a0,s1
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	2ea080e7          	jalr	746(ra) # 80000c9e <release>
}
    800049bc:	bfe1                	j	80004994 <pipeclose+0x46>

00000000800049be <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049be:	7159                	addi	sp,sp,-112
    800049c0:	f486                	sd	ra,104(sp)
    800049c2:	f0a2                	sd	s0,96(sp)
    800049c4:	eca6                	sd	s1,88(sp)
    800049c6:	e8ca                	sd	s2,80(sp)
    800049c8:	e4ce                	sd	s3,72(sp)
    800049ca:	e0d2                	sd	s4,64(sp)
    800049cc:	fc56                	sd	s5,56(sp)
    800049ce:	f85a                	sd	s6,48(sp)
    800049d0:	f45e                	sd	s7,40(sp)
    800049d2:	f062                	sd	s8,32(sp)
    800049d4:	ec66                	sd	s9,24(sp)
    800049d6:	1880                	addi	s0,sp,112
    800049d8:	84aa                	mv	s1,a0
    800049da:	8aae                	mv	s5,a1
    800049dc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800049de:	ffffd097          	auipc	ra,0xffffd
    800049e2:	fe8080e7          	jalr	-24(ra) # 800019c6 <myproc>
    800049e6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800049e8:	8526                	mv	a0,s1
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	200080e7          	jalr	512(ra) # 80000bea <acquire>
  while(i < n){
    800049f2:	0d405463          	blez	s4,80004aba <pipewrite+0xfc>
    800049f6:	8ba6                	mv	s7,s1
  int i = 0;
    800049f8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049fa:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049fc:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a00:	21c48c13          	addi	s8,s1,540
    80004a04:	a08d                	j	80004a66 <pipewrite+0xa8>
      release(&pi->lock);
    80004a06:	8526                	mv	a0,s1
    80004a08:	ffffc097          	auipc	ra,0xffffc
    80004a0c:	296080e7          	jalr	662(ra) # 80000c9e <release>
      return -1;
    80004a10:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a12:	854a                	mv	a0,s2
    80004a14:	70a6                	ld	ra,104(sp)
    80004a16:	7406                	ld	s0,96(sp)
    80004a18:	64e6                	ld	s1,88(sp)
    80004a1a:	6946                	ld	s2,80(sp)
    80004a1c:	69a6                	ld	s3,72(sp)
    80004a1e:	6a06                	ld	s4,64(sp)
    80004a20:	7ae2                	ld	s5,56(sp)
    80004a22:	7b42                	ld	s6,48(sp)
    80004a24:	7ba2                	ld	s7,40(sp)
    80004a26:	7c02                	ld	s8,32(sp)
    80004a28:	6ce2                	ld	s9,24(sp)
    80004a2a:	6165                	addi	sp,sp,112
    80004a2c:	8082                	ret
      wakeup(&pi->nread);
    80004a2e:	8566                	mv	a0,s9
    80004a30:	ffffd097          	auipc	ra,0xffffd
    80004a34:	69e080e7          	jalr	1694(ra) # 800020ce <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a38:	85de                	mv	a1,s7
    80004a3a:	8562                	mv	a0,s8
    80004a3c:	ffffd097          	auipc	ra,0xffffd
    80004a40:	62e080e7          	jalr	1582(ra) # 8000206a <sleep>
    80004a44:	a839                	j	80004a62 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a46:	21c4a783          	lw	a5,540(s1)
    80004a4a:	0017871b          	addiw	a4,a5,1
    80004a4e:	20e4ae23          	sw	a4,540(s1)
    80004a52:	1ff7f793          	andi	a5,a5,511
    80004a56:	97a6                	add	a5,a5,s1
    80004a58:	f9f44703          	lbu	a4,-97(s0)
    80004a5c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a60:	2905                	addiw	s2,s2,1
  while(i < n){
    80004a62:	05495063          	bge	s2,s4,80004aa2 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004a66:	2204a783          	lw	a5,544(s1)
    80004a6a:	dfd1                	beqz	a5,80004a06 <pipewrite+0x48>
    80004a6c:	854e                	mv	a0,s3
    80004a6e:	ffffe097          	auipc	ra,0xffffe
    80004a72:	8a4080e7          	jalr	-1884(ra) # 80002312 <killed>
    80004a76:	f941                	bnez	a0,80004a06 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a78:	2184a783          	lw	a5,536(s1)
    80004a7c:	21c4a703          	lw	a4,540(s1)
    80004a80:	2007879b          	addiw	a5,a5,512
    80004a84:	faf705e3          	beq	a4,a5,80004a2e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a88:	4685                	li	a3,1
    80004a8a:	01590633          	add	a2,s2,s5
    80004a8e:	f9f40593          	addi	a1,s0,-97
    80004a92:	0509b503          	ld	a0,80(s3)
    80004a96:	ffffd097          	auipc	ra,0xffffd
    80004a9a:	c7a080e7          	jalr	-902(ra) # 80001710 <copyin>
    80004a9e:	fb6514e3          	bne	a0,s6,80004a46 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004aa2:	21848513          	addi	a0,s1,536
    80004aa6:	ffffd097          	auipc	ra,0xffffd
    80004aaa:	628080e7          	jalr	1576(ra) # 800020ce <wakeup>
  release(&pi->lock);
    80004aae:	8526                	mv	a0,s1
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	1ee080e7          	jalr	494(ra) # 80000c9e <release>
  return i;
    80004ab8:	bfa9                	j	80004a12 <pipewrite+0x54>
  int i = 0;
    80004aba:	4901                	li	s2,0
    80004abc:	b7dd                	j	80004aa2 <pipewrite+0xe4>

0000000080004abe <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004abe:	715d                	addi	sp,sp,-80
    80004ac0:	e486                	sd	ra,72(sp)
    80004ac2:	e0a2                	sd	s0,64(sp)
    80004ac4:	fc26                	sd	s1,56(sp)
    80004ac6:	f84a                	sd	s2,48(sp)
    80004ac8:	f44e                	sd	s3,40(sp)
    80004aca:	f052                	sd	s4,32(sp)
    80004acc:	ec56                	sd	s5,24(sp)
    80004ace:	e85a                	sd	s6,16(sp)
    80004ad0:	0880                	addi	s0,sp,80
    80004ad2:	84aa                	mv	s1,a0
    80004ad4:	892e                	mv	s2,a1
    80004ad6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ad8:	ffffd097          	auipc	ra,0xffffd
    80004adc:	eee080e7          	jalr	-274(ra) # 800019c6 <myproc>
    80004ae0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ae2:	8b26                	mv	s6,s1
    80004ae4:	8526                	mv	a0,s1
    80004ae6:	ffffc097          	auipc	ra,0xffffc
    80004aea:	104080e7          	jalr	260(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aee:	2184a703          	lw	a4,536(s1)
    80004af2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004af6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004afa:	02f71763          	bne	a4,a5,80004b28 <piperead+0x6a>
    80004afe:	2244a783          	lw	a5,548(s1)
    80004b02:	c39d                	beqz	a5,80004b28 <piperead+0x6a>
    if(killed(pr)){
    80004b04:	8552                	mv	a0,s4
    80004b06:	ffffe097          	auipc	ra,0xffffe
    80004b0a:	80c080e7          	jalr	-2036(ra) # 80002312 <killed>
    80004b0e:	e941                	bnez	a0,80004b9e <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b10:	85da                	mv	a1,s6
    80004b12:	854e                	mv	a0,s3
    80004b14:	ffffd097          	auipc	ra,0xffffd
    80004b18:	556080e7          	jalr	1366(ra) # 8000206a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b1c:	2184a703          	lw	a4,536(s1)
    80004b20:	21c4a783          	lw	a5,540(s1)
    80004b24:	fcf70de3          	beq	a4,a5,80004afe <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b28:	09505263          	blez	s5,80004bac <piperead+0xee>
    80004b2c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b2e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b30:	2184a783          	lw	a5,536(s1)
    80004b34:	21c4a703          	lw	a4,540(s1)
    80004b38:	02f70d63          	beq	a4,a5,80004b72 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b3c:	0017871b          	addiw	a4,a5,1
    80004b40:	20e4ac23          	sw	a4,536(s1)
    80004b44:	1ff7f793          	andi	a5,a5,511
    80004b48:	97a6                	add	a5,a5,s1
    80004b4a:	0187c783          	lbu	a5,24(a5)
    80004b4e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b52:	4685                	li	a3,1
    80004b54:	fbf40613          	addi	a2,s0,-65
    80004b58:	85ca                	mv	a1,s2
    80004b5a:	050a3503          	ld	a0,80(s4)
    80004b5e:	ffffd097          	auipc	ra,0xffffd
    80004b62:	b26080e7          	jalr	-1242(ra) # 80001684 <copyout>
    80004b66:	01650663          	beq	a0,s6,80004b72 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b6a:	2985                	addiw	s3,s3,1
    80004b6c:	0905                	addi	s2,s2,1
    80004b6e:	fd3a91e3          	bne	s5,s3,80004b30 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b72:	21c48513          	addi	a0,s1,540
    80004b76:	ffffd097          	auipc	ra,0xffffd
    80004b7a:	558080e7          	jalr	1368(ra) # 800020ce <wakeup>
  release(&pi->lock);
    80004b7e:	8526                	mv	a0,s1
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	11e080e7          	jalr	286(ra) # 80000c9e <release>
  return i;
}
    80004b88:	854e                	mv	a0,s3
    80004b8a:	60a6                	ld	ra,72(sp)
    80004b8c:	6406                	ld	s0,64(sp)
    80004b8e:	74e2                	ld	s1,56(sp)
    80004b90:	7942                	ld	s2,48(sp)
    80004b92:	79a2                	ld	s3,40(sp)
    80004b94:	7a02                	ld	s4,32(sp)
    80004b96:	6ae2                	ld	s5,24(sp)
    80004b98:	6b42                	ld	s6,16(sp)
    80004b9a:	6161                	addi	sp,sp,80
    80004b9c:	8082                	ret
      release(&pi->lock);
    80004b9e:	8526                	mv	a0,s1
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	0fe080e7          	jalr	254(ra) # 80000c9e <release>
      return -1;
    80004ba8:	59fd                	li	s3,-1
    80004baa:	bff9                	j	80004b88 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bac:	4981                	li	s3,0
    80004bae:	b7d1                	j	80004b72 <piperead+0xb4>

0000000080004bb0 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004bb0:	1141                	addi	sp,sp,-16
    80004bb2:	e422                	sd	s0,8(sp)
    80004bb4:	0800                	addi	s0,sp,16
    80004bb6:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004bb8:	8905                	andi	a0,a0,1
    80004bba:	c111                	beqz	a0,80004bbe <flags2perm+0xe>
      perm = PTE_X;
    80004bbc:	4521                	li	a0,8
    if(flags & 0x2)
    80004bbe:	8b89                	andi	a5,a5,2
    80004bc0:	c399                	beqz	a5,80004bc6 <flags2perm+0x16>
      perm |= PTE_W;
    80004bc2:	00456513          	ori	a0,a0,4
    return perm;
}
    80004bc6:	6422                	ld	s0,8(sp)
    80004bc8:	0141                	addi	sp,sp,16
    80004bca:	8082                	ret

0000000080004bcc <exec>:

int
exec(char *path, char **argv)
{
    80004bcc:	df010113          	addi	sp,sp,-528
    80004bd0:	20113423          	sd	ra,520(sp)
    80004bd4:	20813023          	sd	s0,512(sp)
    80004bd8:	ffa6                	sd	s1,504(sp)
    80004bda:	fbca                	sd	s2,496(sp)
    80004bdc:	f7ce                	sd	s3,488(sp)
    80004bde:	f3d2                	sd	s4,480(sp)
    80004be0:	efd6                	sd	s5,472(sp)
    80004be2:	ebda                	sd	s6,464(sp)
    80004be4:	e7de                	sd	s7,456(sp)
    80004be6:	e3e2                	sd	s8,448(sp)
    80004be8:	ff66                	sd	s9,440(sp)
    80004bea:	fb6a                	sd	s10,432(sp)
    80004bec:	f76e                	sd	s11,424(sp)
    80004bee:	0c00                	addi	s0,sp,528
    80004bf0:	84aa                	mv	s1,a0
    80004bf2:	dea43c23          	sd	a0,-520(s0)
    80004bf6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bfa:	ffffd097          	auipc	ra,0xffffd
    80004bfe:	dcc080e7          	jalr	-564(ra) # 800019c6 <myproc>
    80004c02:	892a                	mv	s2,a0

  begin_op();
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	474080e7          	jalr	1140(ra) # 80004078 <begin_op>

  if((ip = namei(path)) == 0){
    80004c0c:	8526                	mv	a0,s1
    80004c0e:	fffff097          	auipc	ra,0xfffff
    80004c12:	24e080e7          	jalr	590(ra) # 80003e5c <namei>
    80004c16:	c92d                	beqz	a0,80004c88 <exec+0xbc>
    80004c18:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c1a:	fffff097          	auipc	ra,0xfffff
    80004c1e:	a9c080e7          	jalr	-1380(ra) # 800036b6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c22:	04000713          	li	a4,64
    80004c26:	4681                	li	a3,0
    80004c28:	e5040613          	addi	a2,s0,-432
    80004c2c:	4581                	li	a1,0
    80004c2e:	8526                	mv	a0,s1
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	d3a080e7          	jalr	-710(ra) # 8000396a <readi>
    80004c38:	04000793          	li	a5,64
    80004c3c:	00f51a63          	bne	a0,a5,80004c50 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c40:	e5042703          	lw	a4,-432(s0)
    80004c44:	464c47b7          	lui	a5,0x464c4
    80004c48:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c4c:	04f70463          	beq	a4,a5,80004c94 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c50:	8526                	mv	a0,s1
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	cc6080e7          	jalr	-826(ra) # 80003918 <iunlockput>
    end_op();
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	49e080e7          	jalr	1182(ra) # 800040f8 <end_op>
  }
  return -1;
    80004c62:	557d                	li	a0,-1
}
    80004c64:	20813083          	ld	ra,520(sp)
    80004c68:	20013403          	ld	s0,512(sp)
    80004c6c:	74fe                	ld	s1,504(sp)
    80004c6e:	795e                	ld	s2,496(sp)
    80004c70:	79be                	ld	s3,488(sp)
    80004c72:	7a1e                	ld	s4,480(sp)
    80004c74:	6afe                	ld	s5,472(sp)
    80004c76:	6b5e                	ld	s6,464(sp)
    80004c78:	6bbe                	ld	s7,456(sp)
    80004c7a:	6c1e                	ld	s8,448(sp)
    80004c7c:	7cfa                	ld	s9,440(sp)
    80004c7e:	7d5a                	ld	s10,432(sp)
    80004c80:	7dba                	ld	s11,424(sp)
    80004c82:	21010113          	addi	sp,sp,528
    80004c86:	8082                	ret
    end_op();
    80004c88:	fffff097          	auipc	ra,0xfffff
    80004c8c:	470080e7          	jalr	1136(ra) # 800040f8 <end_op>
    return -1;
    80004c90:	557d                	li	a0,-1
    80004c92:	bfc9                	j	80004c64 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c94:	854a                	mv	a0,s2
    80004c96:	ffffd097          	auipc	ra,0xffffd
    80004c9a:	df4080e7          	jalr	-524(ra) # 80001a8a <proc_pagetable>
    80004c9e:	8baa                	mv	s7,a0
    80004ca0:	d945                	beqz	a0,80004c50 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ca2:	e7042983          	lw	s3,-400(s0)
    80004ca6:	e8845783          	lhu	a5,-376(s0)
    80004caa:	c7ad                	beqz	a5,80004d14 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cac:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cae:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004cb0:	6c85                	lui	s9,0x1
    80004cb2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004cb6:	def43823          	sd	a5,-528(s0)
    80004cba:	ac0d                	j	80004eec <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cbc:	00004517          	auipc	a0,0x4
    80004cc0:	a3450513          	addi	a0,a0,-1484 # 800086f0 <syscalls+0x288>
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	880080e7          	jalr	-1920(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ccc:	8756                	mv	a4,s5
    80004cce:	012d86bb          	addw	a3,s11,s2
    80004cd2:	4581                	li	a1,0
    80004cd4:	8526                	mv	a0,s1
    80004cd6:	fffff097          	auipc	ra,0xfffff
    80004cda:	c94080e7          	jalr	-876(ra) # 8000396a <readi>
    80004cde:	2501                	sext.w	a0,a0
    80004ce0:	1aaa9a63          	bne	s5,a0,80004e94 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004ce4:	6785                	lui	a5,0x1
    80004ce6:	0127893b          	addw	s2,a5,s2
    80004cea:	77fd                	lui	a5,0xfffff
    80004cec:	01478a3b          	addw	s4,a5,s4
    80004cf0:	1f897563          	bgeu	s2,s8,80004eda <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004cf4:	02091593          	slli	a1,s2,0x20
    80004cf8:	9181                	srli	a1,a1,0x20
    80004cfa:	95ea                	add	a1,a1,s10
    80004cfc:	855e                	mv	a0,s7
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	37a080e7          	jalr	890(ra) # 80001078 <walkaddr>
    80004d06:	862a                	mv	a2,a0
    if(pa == 0)
    80004d08:	d955                	beqz	a0,80004cbc <exec+0xf0>
      n = PGSIZE;
    80004d0a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d0c:	fd9a70e3          	bgeu	s4,s9,80004ccc <exec+0x100>
      n = sz - i;
    80004d10:	8ad2                	mv	s5,s4
    80004d12:	bf6d                	j	80004ccc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d14:	4a01                	li	s4,0
  iunlockput(ip);
    80004d16:	8526                	mv	a0,s1
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	c00080e7          	jalr	-1024(ra) # 80003918 <iunlockput>
  end_op();
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	3d8080e7          	jalr	984(ra) # 800040f8 <end_op>
  p = myproc();
    80004d28:	ffffd097          	auipc	ra,0xffffd
    80004d2c:	c9e080e7          	jalr	-866(ra) # 800019c6 <myproc>
    80004d30:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d32:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d36:	6785                	lui	a5,0x1
    80004d38:	17fd                	addi	a5,a5,-1
    80004d3a:	9a3e                	add	s4,s4,a5
    80004d3c:	757d                	lui	a0,0xfffff
    80004d3e:	00aa77b3          	and	a5,s4,a0
    80004d42:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d46:	4691                	li	a3,4
    80004d48:	6609                	lui	a2,0x2
    80004d4a:	963e                	add	a2,a2,a5
    80004d4c:	85be                	mv	a1,a5
    80004d4e:	855e                	mv	a0,s7
    80004d50:	ffffc097          	auipc	ra,0xffffc
    80004d54:	6dc080e7          	jalr	1756(ra) # 8000142c <uvmalloc>
    80004d58:	8b2a                	mv	s6,a0
  ip = 0;
    80004d5a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d5c:	12050c63          	beqz	a0,80004e94 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d60:	75f9                	lui	a1,0xffffe
    80004d62:	95aa                	add	a1,a1,a0
    80004d64:	855e                	mv	a0,s7
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	8ec080e7          	jalr	-1812(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d6e:	7c7d                	lui	s8,0xfffff
    80004d70:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d72:	e0043783          	ld	a5,-512(s0)
    80004d76:	6388                	ld	a0,0(a5)
    80004d78:	c535                	beqz	a0,80004de4 <exec+0x218>
    80004d7a:	e9040993          	addi	s3,s0,-368
    80004d7e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d82:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	0e6080e7          	jalr	230(ra) # 80000e6a <strlen>
    80004d8c:	2505                	addiw	a0,a0,1
    80004d8e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d92:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d96:	13896663          	bltu	s2,s8,80004ec2 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d9a:	e0043d83          	ld	s11,-512(s0)
    80004d9e:	000dba03          	ld	s4,0(s11)
    80004da2:	8552                	mv	a0,s4
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	0c6080e7          	jalr	198(ra) # 80000e6a <strlen>
    80004dac:	0015069b          	addiw	a3,a0,1
    80004db0:	8652                	mv	a2,s4
    80004db2:	85ca                	mv	a1,s2
    80004db4:	855e                	mv	a0,s7
    80004db6:	ffffd097          	auipc	ra,0xffffd
    80004dba:	8ce080e7          	jalr	-1842(ra) # 80001684 <copyout>
    80004dbe:	10054663          	bltz	a0,80004eca <exec+0x2fe>
    ustack[argc] = sp;
    80004dc2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dc6:	0485                	addi	s1,s1,1
    80004dc8:	008d8793          	addi	a5,s11,8
    80004dcc:	e0f43023          	sd	a5,-512(s0)
    80004dd0:	008db503          	ld	a0,8(s11)
    80004dd4:	c911                	beqz	a0,80004de8 <exec+0x21c>
    if(argc >= MAXARG)
    80004dd6:	09a1                	addi	s3,s3,8
    80004dd8:	fb3c96e3          	bne	s9,s3,80004d84 <exec+0x1b8>
  sz = sz1;
    80004ddc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004de0:	4481                	li	s1,0
    80004de2:	a84d                	j	80004e94 <exec+0x2c8>
  sp = sz;
    80004de4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004de6:	4481                	li	s1,0
  ustack[argc] = 0;
    80004de8:	00349793          	slli	a5,s1,0x3
    80004dec:	f9040713          	addi	a4,s0,-112
    80004df0:	97ba                	add	a5,a5,a4
    80004df2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004df6:	00148693          	addi	a3,s1,1
    80004dfa:	068e                	slli	a3,a3,0x3
    80004dfc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e00:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e04:	01897663          	bgeu	s2,s8,80004e10 <exec+0x244>
  sz = sz1;
    80004e08:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e0c:	4481                	li	s1,0
    80004e0e:	a059                	j	80004e94 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e10:	e9040613          	addi	a2,s0,-368
    80004e14:	85ca                	mv	a1,s2
    80004e16:	855e                	mv	a0,s7
    80004e18:	ffffd097          	auipc	ra,0xffffd
    80004e1c:	86c080e7          	jalr	-1940(ra) # 80001684 <copyout>
    80004e20:	0a054963          	bltz	a0,80004ed2 <exec+0x306>
  p->trapframe->a1 = sp;
    80004e24:	058ab783          	ld	a5,88(s5)
    80004e28:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e2c:	df843783          	ld	a5,-520(s0)
    80004e30:	0007c703          	lbu	a4,0(a5)
    80004e34:	cf11                	beqz	a4,80004e50 <exec+0x284>
    80004e36:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e38:	02f00693          	li	a3,47
    80004e3c:	a039                	j	80004e4a <exec+0x27e>
      last = s+1;
    80004e3e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e42:	0785                	addi	a5,a5,1
    80004e44:	fff7c703          	lbu	a4,-1(a5)
    80004e48:	c701                	beqz	a4,80004e50 <exec+0x284>
    if(*s == '/')
    80004e4a:	fed71ce3          	bne	a4,a3,80004e42 <exec+0x276>
    80004e4e:	bfc5                	j	80004e3e <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e50:	4641                	li	a2,16
    80004e52:	df843583          	ld	a1,-520(s0)
    80004e56:	158a8513          	addi	a0,s5,344
    80004e5a:	ffffc097          	auipc	ra,0xffffc
    80004e5e:	fde080e7          	jalr	-34(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e62:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e66:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004e6a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e6e:	058ab783          	ld	a5,88(s5)
    80004e72:	e6843703          	ld	a4,-408(s0)
    80004e76:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e78:	058ab783          	ld	a5,88(s5)
    80004e7c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e80:	85ea                	mv	a1,s10
    80004e82:	ffffd097          	auipc	ra,0xffffd
    80004e86:	ca4080e7          	jalr	-860(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e8a:	0004851b          	sext.w	a0,s1
    80004e8e:	bbd9                	j	80004c64 <exec+0x98>
    80004e90:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e94:	e0843583          	ld	a1,-504(s0)
    80004e98:	855e                	mv	a0,s7
    80004e9a:	ffffd097          	auipc	ra,0xffffd
    80004e9e:	c8c080e7          	jalr	-884(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80004ea2:	da0497e3          	bnez	s1,80004c50 <exec+0x84>
  return -1;
    80004ea6:	557d                	li	a0,-1
    80004ea8:	bb75                	j	80004c64 <exec+0x98>
    80004eaa:	e1443423          	sd	s4,-504(s0)
    80004eae:	b7dd                	j	80004e94 <exec+0x2c8>
    80004eb0:	e1443423          	sd	s4,-504(s0)
    80004eb4:	b7c5                	j	80004e94 <exec+0x2c8>
    80004eb6:	e1443423          	sd	s4,-504(s0)
    80004eba:	bfe9                	j	80004e94 <exec+0x2c8>
    80004ebc:	e1443423          	sd	s4,-504(s0)
    80004ec0:	bfd1                	j	80004e94 <exec+0x2c8>
  sz = sz1;
    80004ec2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ec6:	4481                	li	s1,0
    80004ec8:	b7f1                	j	80004e94 <exec+0x2c8>
  sz = sz1;
    80004eca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ece:	4481                	li	s1,0
    80004ed0:	b7d1                	j	80004e94 <exec+0x2c8>
  sz = sz1;
    80004ed2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ed6:	4481                	li	s1,0
    80004ed8:	bf75                	j	80004e94 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004eda:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ede:	2b05                	addiw	s6,s6,1
    80004ee0:	0389899b          	addiw	s3,s3,56
    80004ee4:	e8845783          	lhu	a5,-376(s0)
    80004ee8:	e2fb57e3          	bge	s6,a5,80004d16 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004eec:	2981                	sext.w	s3,s3
    80004eee:	03800713          	li	a4,56
    80004ef2:	86ce                	mv	a3,s3
    80004ef4:	e1840613          	addi	a2,s0,-488
    80004ef8:	4581                	li	a1,0
    80004efa:	8526                	mv	a0,s1
    80004efc:	fffff097          	auipc	ra,0xfffff
    80004f00:	a6e080e7          	jalr	-1426(ra) # 8000396a <readi>
    80004f04:	03800793          	li	a5,56
    80004f08:	f8f514e3          	bne	a0,a5,80004e90 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80004f0c:	e1842783          	lw	a5,-488(s0)
    80004f10:	4705                	li	a4,1
    80004f12:	fce796e3          	bne	a5,a4,80004ede <exec+0x312>
    if(ph.memsz < ph.filesz)
    80004f16:	e4043903          	ld	s2,-448(s0)
    80004f1a:	e3843783          	ld	a5,-456(s0)
    80004f1e:	f8f966e3          	bltu	s2,a5,80004eaa <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f22:	e2843783          	ld	a5,-472(s0)
    80004f26:	993e                	add	s2,s2,a5
    80004f28:	f8f964e3          	bltu	s2,a5,80004eb0 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80004f2c:	df043703          	ld	a4,-528(s0)
    80004f30:	8ff9                	and	a5,a5,a4
    80004f32:	f3d1                	bnez	a5,80004eb6 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f34:	e1c42503          	lw	a0,-484(s0)
    80004f38:	00000097          	auipc	ra,0x0
    80004f3c:	c78080e7          	jalr	-904(ra) # 80004bb0 <flags2perm>
    80004f40:	86aa                	mv	a3,a0
    80004f42:	864a                	mv	a2,s2
    80004f44:	85d2                	mv	a1,s4
    80004f46:	855e                	mv	a0,s7
    80004f48:	ffffc097          	auipc	ra,0xffffc
    80004f4c:	4e4080e7          	jalr	1252(ra) # 8000142c <uvmalloc>
    80004f50:	e0a43423          	sd	a0,-504(s0)
    80004f54:	d525                	beqz	a0,80004ebc <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f56:	e2843d03          	ld	s10,-472(s0)
    80004f5a:	e2042d83          	lw	s11,-480(s0)
    80004f5e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f62:	f60c0ce3          	beqz	s8,80004eda <exec+0x30e>
    80004f66:	8a62                	mv	s4,s8
    80004f68:	4901                	li	s2,0
    80004f6a:	b369                	j	80004cf4 <exec+0x128>

0000000080004f6c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f6c:	7179                	addi	sp,sp,-48
    80004f6e:	f406                	sd	ra,40(sp)
    80004f70:	f022                	sd	s0,32(sp)
    80004f72:	ec26                	sd	s1,24(sp)
    80004f74:	e84a                	sd	s2,16(sp)
    80004f76:	1800                	addi	s0,sp,48
    80004f78:	892e                	mv	s2,a1
    80004f7a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004f7c:	fdc40593          	addi	a1,s0,-36
    80004f80:	ffffe097          	auipc	ra,0xffffe
    80004f84:	b56080e7          	jalr	-1194(ra) # 80002ad6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f88:	fdc42703          	lw	a4,-36(s0)
    80004f8c:	47bd                	li	a5,15
    80004f8e:	02e7eb63          	bltu	a5,a4,80004fc4 <argfd+0x58>
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	a34080e7          	jalr	-1484(ra) # 800019c6 <myproc>
    80004f9a:	fdc42703          	lw	a4,-36(s0)
    80004f9e:	01a70793          	addi	a5,a4,26
    80004fa2:	078e                	slli	a5,a5,0x3
    80004fa4:	953e                	add	a0,a0,a5
    80004fa6:	611c                	ld	a5,0(a0)
    80004fa8:	c385                	beqz	a5,80004fc8 <argfd+0x5c>
    return -1;
  if(pfd)
    80004faa:	00090463          	beqz	s2,80004fb2 <argfd+0x46>
    *pfd = fd;
    80004fae:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fb2:	4501                	li	a0,0
  if(pf)
    80004fb4:	c091                	beqz	s1,80004fb8 <argfd+0x4c>
    *pf = f;
    80004fb6:	e09c                	sd	a5,0(s1)
}
    80004fb8:	70a2                	ld	ra,40(sp)
    80004fba:	7402                	ld	s0,32(sp)
    80004fbc:	64e2                	ld	s1,24(sp)
    80004fbe:	6942                	ld	s2,16(sp)
    80004fc0:	6145                	addi	sp,sp,48
    80004fc2:	8082                	ret
    return -1;
    80004fc4:	557d                	li	a0,-1
    80004fc6:	bfcd                	j	80004fb8 <argfd+0x4c>
    80004fc8:	557d                	li	a0,-1
    80004fca:	b7fd                	j	80004fb8 <argfd+0x4c>

0000000080004fcc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fcc:	1101                	addi	sp,sp,-32
    80004fce:	ec06                	sd	ra,24(sp)
    80004fd0:	e822                	sd	s0,16(sp)
    80004fd2:	e426                	sd	s1,8(sp)
    80004fd4:	1000                	addi	s0,sp,32
    80004fd6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fd8:	ffffd097          	auipc	ra,0xffffd
    80004fdc:	9ee080e7          	jalr	-1554(ra) # 800019c6 <myproc>
    80004fe0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fe2:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdd2a8>
    80004fe6:	4501                	li	a0,0
    80004fe8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fea:	6398                	ld	a4,0(a5)
    80004fec:	cb19                	beqz	a4,80005002 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fee:	2505                	addiw	a0,a0,1
    80004ff0:	07a1                	addi	a5,a5,8
    80004ff2:	fed51ce3          	bne	a0,a3,80004fea <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004ff6:	557d                	li	a0,-1
}
    80004ff8:	60e2                	ld	ra,24(sp)
    80004ffa:	6442                	ld	s0,16(sp)
    80004ffc:	64a2                	ld	s1,8(sp)
    80004ffe:	6105                	addi	sp,sp,32
    80005000:	8082                	ret
      p->ofile[fd] = f;
    80005002:	01a50793          	addi	a5,a0,26
    80005006:	078e                	slli	a5,a5,0x3
    80005008:	963e                	add	a2,a2,a5
    8000500a:	e204                	sd	s1,0(a2)
      return fd;
    8000500c:	b7f5                	j	80004ff8 <fdalloc+0x2c>

000000008000500e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000500e:	715d                	addi	sp,sp,-80
    80005010:	e486                	sd	ra,72(sp)
    80005012:	e0a2                	sd	s0,64(sp)
    80005014:	fc26                	sd	s1,56(sp)
    80005016:	f84a                	sd	s2,48(sp)
    80005018:	f44e                	sd	s3,40(sp)
    8000501a:	f052                	sd	s4,32(sp)
    8000501c:	ec56                	sd	s5,24(sp)
    8000501e:	e85a                	sd	s6,16(sp)
    80005020:	0880                	addi	s0,sp,80
    80005022:	8b2e                	mv	s6,a1
    80005024:	89b2                	mv	s3,a2
    80005026:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005028:	fb040593          	addi	a1,s0,-80
    8000502c:	fffff097          	auipc	ra,0xfffff
    80005030:	e4e080e7          	jalr	-434(ra) # 80003e7a <nameiparent>
    80005034:	84aa                	mv	s1,a0
    80005036:	16050063          	beqz	a0,80005196 <create+0x188>
    return 0;

  ilock(dp);
    8000503a:	ffffe097          	auipc	ra,0xffffe
    8000503e:	67c080e7          	jalr	1660(ra) # 800036b6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005042:	4601                	li	a2,0
    80005044:	fb040593          	addi	a1,s0,-80
    80005048:	8526                	mv	a0,s1
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	b50080e7          	jalr	-1200(ra) # 80003b9a <dirlookup>
    80005052:	8aaa                	mv	s5,a0
    80005054:	c931                	beqz	a0,800050a8 <create+0x9a>
    iunlockput(dp);
    80005056:	8526                	mv	a0,s1
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	8c0080e7          	jalr	-1856(ra) # 80003918 <iunlockput>
    ilock(ip);
    80005060:	8556                	mv	a0,s5
    80005062:	ffffe097          	auipc	ra,0xffffe
    80005066:	654080e7          	jalr	1620(ra) # 800036b6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000506a:	000b059b          	sext.w	a1,s6
    8000506e:	4789                	li	a5,2
    80005070:	02f59563          	bne	a1,a5,8000509a <create+0x8c>
    80005074:	044ad783          	lhu	a5,68(s5)
    80005078:	37f9                	addiw	a5,a5,-2
    8000507a:	17c2                	slli	a5,a5,0x30
    8000507c:	93c1                	srli	a5,a5,0x30
    8000507e:	4705                	li	a4,1
    80005080:	00f76d63          	bltu	a4,a5,8000509a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005084:	8556                	mv	a0,s5
    80005086:	60a6                	ld	ra,72(sp)
    80005088:	6406                	ld	s0,64(sp)
    8000508a:	74e2                	ld	s1,56(sp)
    8000508c:	7942                	ld	s2,48(sp)
    8000508e:	79a2                	ld	s3,40(sp)
    80005090:	7a02                	ld	s4,32(sp)
    80005092:	6ae2                	ld	s5,24(sp)
    80005094:	6b42                	ld	s6,16(sp)
    80005096:	6161                	addi	sp,sp,80
    80005098:	8082                	ret
    iunlockput(ip);
    8000509a:	8556                	mv	a0,s5
    8000509c:	fffff097          	auipc	ra,0xfffff
    800050a0:	87c080e7          	jalr	-1924(ra) # 80003918 <iunlockput>
    return 0;
    800050a4:	4a81                	li	s5,0
    800050a6:	bff9                	j	80005084 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800050a8:	85da                	mv	a1,s6
    800050aa:	4088                	lw	a0,0(s1)
    800050ac:	ffffe097          	auipc	ra,0xffffe
    800050b0:	46e080e7          	jalr	1134(ra) # 8000351a <ialloc>
    800050b4:	8a2a                	mv	s4,a0
    800050b6:	c921                	beqz	a0,80005106 <create+0xf8>
  ilock(ip);
    800050b8:	ffffe097          	auipc	ra,0xffffe
    800050bc:	5fe080e7          	jalr	1534(ra) # 800036b6 <ilock>
  ip->major = major;
    800050c0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800050c4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800050c8:	4785                	li	a5,1
    800050ca:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800050ce:	8552                	mv	a0,s4
    800050d0:	ffffe097          	auipc	ra,0xffffe
    800050d4:	51c080e7          	jalr	1308(ra) # 800035ec <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050d8:	000b059b          	sext.w	a1,s6
    800050dc:	4785                	li	a5,1
    800050de:	02f58b63          	beq	a1,a5,80005114 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800050e2:	004a2603          	lw	a2,4(s4)
    800050e6:	fb040593          	addi	a1,s0,-80
    800050ea:	8526                	mv	a0,s1
    800050ec:	fffff097          	auipc	ra,0xfffff
    800050f0:	cbe080e7          	jalr	-834(ra) # 80003daa <dirlink>
    800050f4:	06054f63          	bltz	a0,80005172 <create+0x164>
  iunlockput(dp);
    800050f8:	8526                	mv	a0,s1
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	81e080e7          	jalr	-2018(ra) # 80003918 <iunlockput>
  return ip;
    80005102:	8ad2                	mv	s5,s4
    80005104:	b741                	j	80005084 <create+0x76>
    iunlockput(dp);
    80005106:	8526                	mv	a0,s1
    80005108:	fffff097          	auipc	ra,0xfffff
    8000510c:	810080e7          	jalr	-2032(ra) # 80003918 <iunlockput>
    return 0;
    80005110:	8ad2                	mv	s5,s4
    80005112:	bf8d                	j	80005084 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005114:	004a2603          	lw	a2,4(s4)
    80005118:	00003597          	auipc	a1,0x3
    8000511c:	5f858593          	addi	a1,a1,1528 # 80008710 <syscalls+0x2a8>
    80005120:	8552                	mv	a0,s4
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	c88080e7          	jalr	-888(ra) # 80003daa <dirlink>
    8000512a:	04054463          	bltz	a0,80005172 <create+0x164>
    8000512e:	40d0                	lw	a2,4(s1)
    80005130:	00003597          	auipc	a1,0x3
    80005134:	5e858593          	addi	a1,a1,1512 # 80008718 <syscalls+0x2b0>
    80005138:	8552                	mv	a0,s4
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	c70080e7          	jalr	-912(ra) # 80003daa <dirlink>
    80005142:	02054863          	bltz	a0,80005172 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005146:	004a2603          	lw	a2,4(s4)
    8000514a:	fb040593          	addi	a1,s0,-80
    8000514e:	8526                	mv	a0,s1
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	c5a080e7          	jalr	-934(ra) # 80003daa <dirlink>
    80005158:	00054d63          	bltz	a0,80005172 <create+0x164>
    dp->nlink++;  // for ".."
    8000515c:	04a4d783          	lhu	a5,74(s1)
    80005160:	2785                	addiw	a5,a5,1
    80005162:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005166:	8526                	mv	a0,s1
    80005168:	ffffe097          	auipc	ra,0xffffe
    8000516c:	484080e7          	jalr	1156(ra) # 800035ec <iupdate>
    80005170:	b761                	j	800050f8 <create+0xea>
  ip->nlink = 0;
    80005172:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005176:	8552                	mv	a0,s4
    80005178:	ffffe097          	auipc	ra,0xffffe
    8000517c:	474080e7          	jalr	1140(ra) # 800035ec <iupdate>
  iunlockput(ip);
    80005180:	8552                	mv	a0,s4
    80005182:	ffffe097          	auipc	ra,0xffffe
    80005186:	796080e7          	jalr	1942(ra) # 80003918 <iunlockput>
  iunlockput(dp);
    8000518a:	8526                	mv	a0,s1
    8000518c:	ffffe097          	auipc	ra,0xffffe
    80005190:	78c080e7          	jalr	1932(ra) # 80003918 <iunlockput>
  return 0;
    80005194:	bdc5                	j	80005084 <create+0x76>
    return 0;
    80005196:	8aaa                	mv	s5,a0
    80005198:	b5f5                	j	80005084 <create+0x76>

000000008000519a <sys_dup>:
{
    8000519a:	7179                	addi	sp,sp,-48
    8000519c:	f406                	sd	ra,40(sp)
    8000519e:	f022                	sd	s0,32(sp)
    800051a0:	ec26                	sd	s1,24(sp)
    800051a2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051a4:	fd840613          	addi	a2,s0,-40
    800051a8:	4581                	li	a1,0
    800051aa:	4501                	li	a0,0
    800051ac:	00000097          	auipc	ra,0x0
    800051b0:	dc0080e7          	jalr	-576(ra) # 80004f6c <argfd>
    return -1;
    800051b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051b6:	02054363          	bltz	a0,800051dc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051ba:	fd843503          	ld	a0,-40(s0)
    800051be:	00000097          	auipc	ra,0x0
    800051c2:	e0e080e7          	jalr	-498(ra) # 80004fcc <fdalloc>
    800051c6:	84aa                	mv	s1,a0
    return -1;
    800051c8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051ca:	00054963          	bltz	a0,800051dc <sys_dup+0x42>
  filedup(f);
    800051ce:	fd843503          	ld	a0,-40(s0)
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	320080e7          	jalr	800(ra) # 800044f2 <filedup>
  return fd;
    800051da:	87a6                	mv	a5,s1
}
    800051dc:	853e                	mv	a0,a5
    800051de:	70a2                	ld	ra,40(sp)
    800051e0:	7402                	ld	s0,32(sp)
    800051e2:	64e2                	ld	s1,24(sp)
    800051e4:	6145                	addi	sp,sp,48
    800051e6:	8082                	ret

00000000800051e8 <sys_read>:
{
    800051e8:	7179                	addi	sp,sp,-48
    800051ea:	f406                	sd	ra,40(sp)
    800051ec:	f022                	sd	s0,32(sp)
    800051ee:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800051f0:	fd840593          	addi	a1,s0,-40
    800051f4:	4505                	li	a0,1
    800051f6:	ffffe097          	auipc	ra,0xffffe
    800051fa:	964080e7          	jalr	-1692(ra) # 80002b5a <argaddr>
  argint(2, &n);
    800051fe:	fe440593          	addi	a1,s0,-28
    80005202:	4509                	li	a0,2
    80005204:	ffffe097          	auipc	ra,0xffffe
    80005208:	8d2080e7          	jalr	-1838(ra) # 80002ad6 <argint>
  if(argfd(0, 0, &f) < 0)
    8000520c:	fe840613          	addi	a2,s0,-24
    80005210:	4581                	li	a1,0
    80005212:	4501                	li	a0,0
    80005214:	00000097          	auipc	ra,0x0
    80005218:	d58080e7          	jalr	-680(ra) # 80004f6c <argfd>
    8000521c:	87aa                	mv	a5,a0
    return -1;
    8000521e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005220:	0007cc63          	bltz	a5,80005238 <sys_read+0x50>
  return fileread(f, p, n);
    80005224:	fe442603          	lw	a2,-28(s0)
    80005228:	fd843583          	ld	a1,-40(s0)
    8000522c:	fe843503          	ld	a0,-24(s0)
    80005230:	fffff097          	auipc	ra,0xfffff
    80005234:	44e080e7          	jalr	1102(ra) # 8000467e <fileread>
}
    80005238:	70a2                	ld	ra,40(sp)
    8000523a:	7402                	ld	s0,32(sp)
    8000523c:	6145                	addi	sp,sp,48
    8000523e:	8082                	ret

0000000080005240 <sys_write>:
{
    80005240:	7179                	addi	sp,sp,-48
    80005242:	f406                	sd	ra,40(sp)
    80005244:	f022                	sd	s0,32(sp)
    80005246:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005248:	fd840593          	addi	a1,s0,-40
    8000524c:	4505                	li	a0,1
    8000524e:	ffffe097          	auipc	ra,0xffffe
    80005252:	90c080e7          	jalr	-1780(ra) # 80002b5a <argaddr>
  argint(2, &n);
    80005256:	fe440593          	addi	a1,s0,-28
    8000525a:	4509                	li	a0,2
    8000525c:	ffffe097          	auipc	ra,0xffffe
    80005260:	87a080e7          	jalr	-1926(ra) # 80002ad6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005264:	fe840613          	addi	a2,s0,-24
    80005268:	4581                	li	a1,0
    8000526a:	4501                	li	a0,0
    8000526c:	00000097          	auipc	ra,0x0
    80005270:	d00080e7          	jalr	-768(ra) # 80004f6c <argfd>
    80005274:	87aa                	mv	a5,a0
    return -1;
    80005276:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005278:	0007cc63          	bltz	a5,80005290 <sys_write+0x50>
  return filewrite(f, p, n);
    8000527c:	fe442603          	lw	a2,-28(s0)
    80005280:	fd843583          	ld	a1,-40(s0)
    80005284:	fe843503          	ld	a0,-24(s0)
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	4b8080e7          	jalr	1208(ra) # 80004740 <filewrite>
}
    80005290:	70a2                	ld	ra,40(sp)
    80005292:	7402                	ld	s0,32(sp)
    80005294:	6145                	addi	sp,sp,48
    80005296:	8082                	ret

0000000080005298 <sys_close>:
{
    80005298:	1101                	addi	sp,sp,-32
    8000529a:	ec06                	sd	ra,24(sp)
    8000529c:	e822                	sd	s0,16(sp)
    8000529e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052a0:	fe040613          	addi	a2,s0,-32
    800052a4:	fec40593          	addi	a1,s0,-20
    800052a8:	4501                	li	a0,0
    800052aa:	00000097          	auipc	ra,0x0
    800052ae:	cc2080e7          	jalr	-830(ra) # 80004f6c <argfd>
    return -1;
    800052b2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052b4:	02054463          	bltz	a0,800052dc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	70e080e7          	jalr	1806(ra) # 800019c6 <myproc>
    800052c0:	fec42783          	lw	a5,-20(s0)
    800052c4:	07e9                	addi	a5,a5,26
    800052c6:	078e                	slli	a5,a5,0x3
    800052c8:	97aa                	add	a5,a5,a0
    800052ca:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052ce:	fe043503          	ld	a0,-32(s0)
    800052d2:	fffff097          	auipc	ra,0xfffff
    800052d6:	272080e7          	jalr	626(ra) # 80004544 <fileclose>
  return 0;
    800052da:	4781                	li	a5,0
}
    800052dc:	853e                	mv	a0,a5
    800052de:	60e2                	ld	ra,24(sp)
    800052e0:	6442                	ld	s0,16(sp)
    800052e2:	6105                	addi	sp,sp,32
    800052e4:	8082                	ret

00000000800052e6 <sys_fstat>:
{
    800052e6:	1101                	addi	sp,sp,-32
    800052e8:	ec06                	sd	ra,24(sp)
    800052ea:	e822                	sd	s0,16(sp)
    800052ec:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800052ee:	fe040593          	addi	a1,s0,-32
    800052f2:	4505                	li	a0,1
    800052f4:	ffffe097          	auipc	ra,0xffffe
    800052f8:	866080e7          	jalr	-1946(ra) # 80002b5a <argaddr>
  if(argfd(0, 0, &f) < 0)
    800052fc:	fe840613          	addi	a2,s0,-24
    80005300:	4581                	li	a1,0
    80005302:	4501                	li	a0,0
    80005304:	00000097          	auipc	ra,0x0
    80005308:	c68080e7          	jalr	-920(ra) # 80004f6c <argfd>
    8000530c:	87aa                	mv	a5,a0
    return -1;
    8000530e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005310:	0007ca63          	bltz	a5,80005324 <sys_fstat+0x3e>
  return filestat(f, st);
    80005314:	fe043583          	ld	a1,-32(s0)
    80005318:	fe843503          	ld	a0,-24(s0)
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	2f0080e7          	jalr	752(ra) # 8000460c <filestat>
}
    80005324:	60e2                	ld	ra,24(sp)
    80005326:	6442                	ld	s0,16(sp)
    80005328:	6105                	addi	sp,sp,32
    8000532a:	8082                	ret

000000008000532c <sys_link>:
{
    8000532c:	7169                	addi	sp,sp,-304
    8000532e:	f606                	sd	ra,296(sp)
    80005330:	f222                	sd	s0,288(sp)
    80005332:	ee26                	sd	s1,280(sp)
    80005334:	ea4a                	sd	s2,272(sp)
    80005336:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005338:	08000613          	li	a2,128
    8000533c:	ed040593          	addi	a1,s0,-304
    80005340:	4501                	li	a0,0
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	838080e7          	jalr	-1992(ra) # 80002b7a <argstr>
    return -1;
    8000534a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000534c:	10054e63          	bltz	a0,80005468 <sys_link+0x13c>
    80005350:	08000613          	li	a2,128
    80005354:	f5040593          	addi	a1,s0,-176
    80005358:	4505                	li	a0,1
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	820080e7          	jalr	-2016(ra) # 80002b7a <argstr>
    return -1;
    80005362:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005364:	10054263          	bltz	a0,80005468 <sys_link+0x13c>
  begin_op();
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	d10080e7          	jalr	-752(ra) # 80004078 <begin_op>
  if((ip = namei(old)) == 0){
    80005370:	ed040513          	addi	a0,s0,-304
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	ae8080e7          	jalr	-1304(ra) # 80003e5c <namei>
    8000537c:	84aa                	mv	s1,a0
    8000537e:	c551                	beqz	a0,8000540a <sys_link+0xde>
  ilock(ip);
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	336080e7          	jalr	822(ra) # 800036b6 <ilock>
  if(ip->type == T_DIR){
    80005388:	04449703          	lh	a4,68(s1)
    8000538c:	4785                	li	a5,1
    8000538e:	08f70463          	beq	a4,a5,80005416 <sys_link+0xea>
  ip->nlink++;
    80005392:	04a4d783          	lhu	a5,74(s1)
    80005396:	2785                	addiw	a5,a5,1
    80005398:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000539c:	8526                	mv	a0,s1
    8000539e:	ffffe097          	auipc	ra,0xffffe
    800053a2:	24e080e7          	jalr	590(ra) # 800035ec <iupdate>
  iunlock(ip);
    800053a6:	8526                	mv	a0,s1
    800053a8:	ffffe097          	auipc	ra,0xffffe
    800053ac:	3d0080e7          	jalr	976(ra) # 80003778 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053b0:	fd040593          	addi	a1,s0,-48
    800053b4:	f5040513          	addi	a0,s0,-176
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	ac2080e7          	jalr	-1342(ra) # 80003e7a <nameiparent>
    800053c0:	892a                	mv	s2,a0
    800053c2:	c935                	beqz	a0,80005436 <sys_link+0x10a>
  ilock(dp);
    800053c4:	ffffe097          	auipc	ra,0xffffe
    800053c8:	2f2080e7          	jalr	754(ra) # 800036b6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053cc:	00092703          	lw	a4,0(s2)
    800053d0:	409c                	lw	a5,0(s1)
    800053d2:	04f71d63          	bne	a4,a5,8000542c <sys_link+0x100>
    800053d6:	40d0                	lw	a2,4(s1)
    800053d8:	fd040593          	addi	a1,s0,-48
    800053dc:	854a                	mv	a0,s2
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	9cc080e7          	jalr	-1588(ra) # 80003daa <dirlink>
    800053e6:	04054363          	bltz	a0,8000542c <sys_link+0x100>
  iunlockput(dp);
    800053ea:	854a                	mv	a0,s2
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	52c080e7          	jalr	1324(ra) # 80003918 <iunlockput>
  iput(ip);
    800053f4:	8526                	mv	a0,s1
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	47a080e7          	jalr	1146(ra) # 80003870 <iput>
  end_op();
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	cfa080e7          	jalr	-774(ra) # 800040f8 <end_op>
  return 0;
    80005406:	4781                	li	a5,0
    80005408:	a085                	j	80005468 <sys_link+0x13c>
    end_op();
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	cee080e7          	jalr	-786(ra) # 800040f8 <end_op>
    return -1;
    80005412:	57fd                	li	a5,-1
    80005414:	a891                	j	80005468 <sys_link+0x13c>
    iunlockput(ip);
    80005416:	8526                	mv	a0,s1
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	500080e7          	jalr	1280(ra) # 80003918 <iunlockput>
    end_op();
    80005420:	fffff097          	auipc	ra,0xfffff
    80005424:	cd8080e7          	jalr	-808(ra) # 800040f8 <end_op>
    return -1;
    80005428:	57fd                	li	a5,-1
    8000542a:	a83d                	j	80005468 <sys_link+0x13c>
    iunlockput(dp);
    8000542c:	854a                	mv	a0,s2
    8000542e:	ffffe097          	auipc	ra,0xffffe
    80005432:	4ea080e7          	jalr	1258(ra) # 80003918 <iunlockput>
  ilock(ip);
    80005436:	8526                	mv	a0,s1
    80005438:	ffffe097          	auipc	ra,0xffffe
    8000543c:	27e080e7          	jalr	638(ra) # 800036b6 <ilock>
  ip->nlink--;
    80005440:	04a4d783          	lhu	a5,74(s1)
    80005444:	37fd                	addiw	a5,a5,-1
    80005446:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000544a:	8526                	mv	a0,s1
    8000544c:	ffffe097          	auipc	ra,0xffffe
    80005450:	1a0080e7          	jalr	416(ra) # 800035ec <iupdate>
  iunlockput(ip);
    80005454:	8526                	mv	a0,s1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	4c2080e7          	jalr	1218(ra) # 80003918 <iunlockput>
  end_op();
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	c9a080e7          	jalr	-870(ra) # 800040f8 <end_op>
  return -1;
    80005466:	57fd                	li	a5,-1
}
    80005468:	853e                	mv	a0,a5
    8000546a:	70b2                	ld	ra,296(sp)
    8000546c:	7412                	ld	s0,288(sp)
    8000546e:	64f2                	ld	s1,280(sp)
    80005470:	6952                	ld	s2,272(sp)
    80005472:	6155                	addi	sp,sp,304
    80005474:	8082                	ret

0000000080005476 <sys_unlink>:
{
    80005476:	7151                	addi	sp,sp,-240
    80005478:	f586                	sd	ra,232(sp)
    8000547a:	f1a2                	sd	s0,224(sp)
    8000547c:	eda6                	sd	s1,216(sp)
    8000547e:	e9ca                	sd	s2,208(sp)
    80005480:	e5ce                	sd	s3,200(sp)
    80005482:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005484:	08000613          	li	a2,128
    80005488:	f3040593          	addi	a1,s0,-208
    8000548c:	4501                	li	a0,0
    8000548e:	ffffd097          	auipc	ra,0xffffd
    80005492:	6ec080e7          	jalr	1772(ra) # 80002b7a <argstr>
    80005496:	18054163          	bltz	a0,80005618 <sys_unlink+0x1a2>
  begin_op();
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	bde080e7          	jalr	-1058(ra) # 80004078 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054a2:	fb040593          	addi	a1,s0,-80
    800054a6:	f3040513          	addi	a0,s0,-208
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	9d0080e7          	jalr	-1584(ra) # 80003e7a <nameiparent>
    800054b2:	84aa                	mv	s1,a0
    800054b4:	c979                	beqz	a0,8000558a <sys_unlink+0x114>
  ilock(dp);
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	200080e7          	jalr	512(ra) # 800036b6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054be:	00003597          	auipc	a1,0x3
    800054c2:	25258593          	addi	a1,a1,594 # 80008710 <syscalls+0x2a8>
    800054c6:	fb040513          	addi	a0,s0,-80
    800054ca:	ffffe097          	auipc	ra,0xffffe
    800054ce:	6b6080e7          	jalr	1718(ra) # 80003b80 <namecmp>
    800054d2:	14050a63          	beqz	a0,80005626 <sys_unlink+0x1b0>
    800054d6:	00003597          	auipc	a1,0x3
    800054da:	24258593          	addi	a1,a1,578 # 80008718 <syscalls+0x2b0>
    800054de:	fb040513          	addi	a0,s0,-80
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	69e080e7          	jalr	1694(ra) # 80003b80 <namecmp>
    800054ea:	12050e63          	beqz	a0,80005626 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054ee:	f2c40613          	addi	a2,s0,-212
    800054f2:	fb040593          	addi	a1,s0,-80
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	6a2080e7          	jalr	1698(ra) # 80003b9a <dirlookup>
    80005500:	892a                	mv	s2,a0
    80005502:	12050263          	beqz	a0,80005626 <sys_unlink+0x1b0>
  ilock(ip);
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	1b0080e7          	jalr	432(ra) # 800036b6 <ilock>
  if(ip->nlink < 1)
    8000550e:	04a91783          	lh	a5,74(s2)
    80005512:	08f05263          	blez	a5,80005596 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005516:	04491703          	lh	a4,68(s2)
    8000551a:	4785                	li	a5,1
    8000551c:	08f70563          	beq	a4,a5,800055a6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005520:	4641                	li	a2,16
    80005522:	4581                	li	a1,0
    80005524:	fc040513          	addi	a0,s0,-64
    80005528:	ffffb097          	auipc	ra,0xffffb
    8000552c:	7be080e7          	jalr	1982(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005530:	4741                	li	a4,16
    80005532:	f2c42683          	lw	a3,-212(s0)
    80005536:	fc040613          	addi	a2,s0,-64
    8000553a:	4581                	li	a1,0
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	524080e7          	jalr	1316(ra) # 80003a62 <writei>
    80005546:	47c1                	li	a5,16
    80005548:	0af51563          	bne	a0,a5,800055f2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000554c:	04491703          	lh	a4,68(s2)
    80005550:	4785                	li	a5,1
    80005552:	0af70863          	beq	a4,a5,80005602 <sys_unlink+0x18c>
  iunlockput(dp);
    80005556:	8526                	mv	a0,s1
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	3c0080e7          	jalr	960(ra) # 80003918 <iunlockput>
  ip->nlink--;
    80005560:	04a95783          	lhu	a5,74(s2)
    80005564:	37fd                	addiw	a5,a5,-1
    80005566:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000556a:	854a                	mv	a0,s2
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	080080e7          	jalr	128(ra) # 800035ec <iupdate>
  iunlockput(ip);
    80005574:	854a                	mv	a0,s2
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	3a2080e7          	jalr	930(ra) # 80003918 <iunlockput>
  end_op();
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	b7a080e7          	jalr	-1158(ra) # 800040f8 <end_op>
  return 0;
    80005586:	4501                	li	a0,0
    80005588:	a84d                	j	8000563a <sys_unlink+0x1c4>
    end_op();
    8000558a:	fffff097          	auipc	ra,0xfffff
    8000558e:	b6e080e7          	jalr	-1170(ra) # 800040f8 <end_op>
    return -1;
    80005592:	557d                	li	a0,-1
    80005594:	a05d                	j	8000563a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005596:	00003517          	auipc	a0,0x3
    8000559a:	18a50513          	addi	a0,a0,394 # 80008720 <syscalls+0x2b8>
    8000559e:	ffffb097          	auipc	ra,0xffffb
    800055a2:	fa6080e7          	jalr	-90(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055a6:	04c92703          	lw	a4,76(s2)
    800055aa:	02000793          	li	a5,32
    800055ae:	f6e7f9e3          	bgeu	a5,a4,80005520 <sys_unlink+0xaa>
    800055b2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055b6:	4741                	li	a4,16
    800055b8:	86ce                	mv	a3,s3
    800055ba:	f1840613          	addi	a2,s0,-232
    800055be:	4581                	li	a1,0
    800055c0:	854a                	mv	a0,s2
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	3a8080e7          	jalr	936(ra) # 8000396a <readi>
    800055ca:	47c1                	li	a5,16
    800055cc:	00f51b63          	bne	a0,a5,800055e2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055d0:	f1845783          	lhu	a5,-232(s0)
    800055d4:	e7a1                	bnez	a5,8000561c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055d6:	29c1                	addiw	s3,s3,16
    800055d8:	04c92783          	lw	a5,76(s2)
    800055dc:	fcf9ede3          	bltu	s3,a5,800055b6 <sys_unlink+0x140>
    800055e0:	b781                	j	80005520 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055e2:	00003517          	auipc	a0,0x3
    800055e6:	15650513          	addi	a0,a0,342 # 80008738 <syscalls+0x2d0>
    800055ea:	ffffb097          	auipc	ra,0xffffb
    800055ee:	f5a080e7          	jalr	-166(ra) # 80000544 <panic>
    panic("unlink: writei");
    800055f2:	00003517          	auipc	a0,0x3
    800055f6:	15e50513          	addi	a0,a0,350 # 80008750 <syscalls+0x2e8>
    800055fa:	ffffb097          	auipc	ra,0xffffb
    800055fe:	f4a080e7          	jalr	-182(ra) # 80000544 <panic>
    dp->nlink--;
    80005602:	04a4d783          	lhu	a5,74(s1)
    80005606:	37fd                	addiw	a5,a5,-1
    80005608:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	fde080e7          	jalr	-34(ra) # 800035ec <iupdate>
    80005616:	b781                	j	80005556 <sys_unlink+0xe0>
    return -1;
    80005618:	557d                	li	a0,-1
    8000561a:	a005                	j	8000563a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000561c:	854a                	mv	a0,s2
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	2fa080e7          	jalr	762(ra) # 80003918 <iunlockput>
  iunlockput(dp);
    80005626:	8526                	mv	a0,s1
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	2f0080e7          	jalr	752(ra) # 80003918 <iunlockput>
  end_op();
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	ac8080e7          	jalr	-1336(ra) # 800040f8 <end_op>
  return -1;
    80005638:	557d                	li	a0,-1
}
    8000563a:	70ae                	ld	ra,232(sp)
    8000563c:	740e                	ld	s0,224(sp)
    8000563e:	64ee                	ld	s1,216(sp)
    80005640:	694e                	ld	s2,208(sp)
    80005642:	69ae                	ld	s3,200(sp)
    80005644:	616d                	addi	sp,sp,240
    80005646:	8082                	ret

0000000080005648 <sys_open>:

uint64
sys_open(void)
{
    80005648:	7131                	addi	sp,sp,-192
    8000564a:	fd06                	sd	ra,184(sp)
    8000564c:	f922                	sd	s0,176(sp)
    8000564e:	f526                	sd	s1,168(sp)
    80005650:	f14a                	sd	s2,160(sp)
    80005652:	ed4e                	sd	s3,152(sp)
    80005654:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005656:	f4c40593          	addi	a1,s0,-180
    8000565a:	4505                	li	a0,1
    8000565c:	ffffd097          	auipc	ra,0xffffd
    80005660:	47a080e7          	jalr	1146(ra) # 80002ad6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005664:	08000613          	li	a2,128
    80005668:	f5040593          	addi	a1,s0,-176
    8000566c:	4501                	li	a0,0
    8000566e:	ffffd097          	auipc	ra,0xffffd
    80005672:	50c080e7          	jalr	1292(ra) # 80002b7a <argstr>
    80005676:	87aa                	mv	a5,a0
    return -1;
    80005678:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000567a:	0a07c963          	bltz	a5,8000572c <sys_open+0xe4>

  begin_op();
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	9fa080e7          	jalr	-1542(ra) # 80004078 <begin_op>

  if(omode & O_CREATE){
    80005686:	f4c42783          	lw	a5,-180(s0)
    8000568a:	2007f793          	andi	a5,a5,512
    8000568e:	cfc5                	beqz	a5,80005746 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005690:	4681                	li	a3,0
    80005692:	4601                	li	a2,0
    80005694:	4589                	li	a1,2
    80005696:	f5040513          	addi	a0,s0,-176
    8000569a:	00000097          	auipc	ra,0x0
    8000569e:	974080e7          	jalr	-1676(ra) # 8000500e <create>
    800056a2:	84aa                	mv	s1,a0
    if(ip == 0){
    800056a4:	c959                	beqz	a0,8000573a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056a6:	04449703          	lh	a4,68(s1)
    800056aa:	478d                	li	a5,3
    800056ac:	00f71763          	bne	a4,a5,800056ba <sys_open+0x72>
    800056b0:	0464d703          	lhu	a4,70(s1)
    800056b4:	47a5                	li	a5,9
    800056b6:	0ce7ed63          	bltu	a5,a4,80005790 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056ba:	fffff097          	auipc	ra,0xfffff
    800056be:	dce080e7          	jalr	-562(ra) # 80004488 <filealloc>
    800056c2:	89aa                	mv	s3,a0
    800056c4:	10050363          	beqz	a0,800057ca <sys_open+0x182>
    800056c8:	00000097          	auipc	ra,0x0
    800056cc:	904080e7          	jalr	-1788(ra) # 80004fcc <fdalloc>
    800056d0:	892a                	mv	s2,a0
    800056d2:	0e054763          	bltz	a0,800057c0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056d6:	04449703          	lh	a4,68(s1)
    800056da:	478d                	li	a5,3
    800056dc:	0cf70563          	beq	a4,a5,800057a6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056e0:	4789                	li	a5,2
    800056e2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056e6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056ea:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056ee:	f4c42783          	lw	a5,-180(s0)
    800056f2:	0017c713          	xori	a4,a5,1
    800056f6:	8b05                	andi	a4,a4,1
    800056f8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056fc:	0037f713          	andi	a4,a5,3
    80005700:	00e03733          	snez	a4,a4
    80005704:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005708:	4007f793          	andi	a5,a5,1024
    8000570c:	c791                	beqz	a5,80005718 <sys_open+0xd0>
    8000570e:	04449703          	lh	a4,68(s1)
    80005712:	4789                	li	a5,2
    80005714:	0af70063          	beq	a4,a5,800057b4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005718:	8526                	mv	a0,s1
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	05e080e7          	jalr	94(ra) # 80003778 <iunlock>
  end_op();
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	9d6080e7          	jalr	-1578(ra) # 800040f8 <end_op>

  return fd;
    8000572a:	854a                	mv	a0,s2
}
    8000572c:	70ea                	ld	ra,184(sp)
    8000572e:	744a                	ld	s0,176(sp)
    80005730:	74aa                	ld	s1,168(sp)
    80005732:	790a                	ld	s2,160(sp)
    80005734:	69ea                	ld	s3,152(sp)
    80005736:	6129                	addi	sp,sp,192
    80005738:	8082                	ret
      end_op();
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	9be080e7          	jalr	-1602(ra) # 800040f8 <end_op>
      return -1;
    80005742:	557d                	li	a0,-1
    80005744:	b7e5                	j	8000572c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005746:	f5040513          	addi	a0,s0,-176
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	712080e7          	jalr	1810(ra) # 80003e5c <namei>
    80005752:	84aa                	mv	s1,a0
    80005754:	c905                	beqz	a0,80005784 <sys_open+0x13c>
    ilock(ip);
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	f60080e7          	jalr	-160(ra) # 800036b6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000575e:	04449703          	lh	a4,68(s1)
    80005762:	4785                	li	a5,1
    80005764:	f4f711e3          	bne	a4,a5,800056a6 <sys_open+0x5e>
    80005768:	f4c42783          	lw	a5,-180(s0)
    8000576c:	d7b9                	beqz	a5,800056ba <sys_open+0x72>
      iunlockput(ip);
    8000576e:	8526                	mv	a0,s1
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	1a8080e7          	jalr	424(ra) # 80003918 <iunlockput>
      end_op();
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	980080e7          	jalr	-1664(ra) # 800040f8 <end_op>
      return -1;
    80005780:	557d                	li	a0,-1
    80005782:	b76d                	j	8000572c <sys_open+0xe4>
      end_op();
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	974080e7          	jalr	-1676(ra) # 800040f8 <end_op>
      return -1;
    8000578c:	557d                	li	a0,-1
    8000578e:	bf79                	j	8000572c <sys_open+0xe4>
    iunlockput(ip);
    80005790:	8526                	mv	a0,s1
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	186080e7          	jalr	390(ra) # 80003918 <iunlockput>
    end_op();
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	95e080e7          	jalr	-1698(ra) # 800040f8 <end_op>
    return -1;
    800057a2:	557d                	li	a0,-1
    800057a4:	b761                	j	8000572c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057a6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057aa:	04649783          	lh	a5,70(s1)
    800057ae:	02f99223          	sh	a5,36(s3)
    800057b2:	bf25                	j	800056ea <sys_open+0xa2>
    itrunc(ip);
    800057b4:	8526                	mv	a0,s1
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	00e080e7          	jalr	14(ra) # 800037c4 <itrunc>
    800057be:	bfa9                	j	80005718 <sys_open+0xd0>
      fileclose(f);
    800057c0:	854e                	mv	a0,s3
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	d82080e7          	jalr	-638(ra) # 80004544 <fileclose>
    iunlockput(ip);
    800057ca:	8526                	mv	a0,s1
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	14c080e7          	jalr	332(ra) # 80003918 <iunlockput>
    end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	924080e7          	jalr	-1756(ra) # 800040f8 <end_op>
    return -1;
    800057dc:	557d                	li	a0,-1
    800057de:	b7b9                	j	8000572c <sys_open+0xe4>

00000000800057e0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057e0:	7175                	addi	sp,sp,-144
    800057e2:	e506                	sd	ra,136(sp)
    800057e4:	e122                	sd	s0,128(sp)
    800057e6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	890080e7          	jalr	-1904(ra) # 80004078 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057f0:	08000613          	li	a2,128
    800057f4:	f7040593          	addi	a1,s0,-144
    800057f8:	4501                	li	a0,0
    800057fa:	ffffd097          	auipc	ra,0xffffd
    800057fe:	380080e7          	jalr	896(ra) # 80002b7a <argstr>
    80005802:	02054963          	bltz	a0,80005834 <sys_mkdir+0x54>
    80005806:	4681                	li	a3,0
    80005808:	4601                	li	a2,0
    8000580a:	4585                	li	a1,1
    8000580c:	f7040513          	addi	a0,s0,-144
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	7fe080e7          	jalr	2046(ra) # 8000500e <create>
    80005818:	cd11                	beqz	a0,80005834 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	0fe080e7          	jalr	254(ra) # 80003918 <iunlockput>
  end_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	8d6080e7          	jalr	-1834(ra) # 800040f8 <end_op>
  return 0;
    8000582a:	4501                	li	a0,0
}
    8000582c:	60aa                	ld	ra,136(sp)
    8000582e:	640a                	ld	s0,128(sp)
    80005830:	6149                	addi	sp,sp,144
    80005832:	8082                	ret
    end_op();
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	8c4080e7          	jalr	-1852(ra) # 800040f8 <end_op>
    return -1;
    8000583c:	557d                	li	a0,-1
    8000583e:	b7fd                	j	8000582c <sys_mkdir+0x4c>

0000000080005840 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005840:	7135                	addi	sp,sp,-160
    80005842:	ed06                	sd	ra,152(sp)
    80005844:	e922                	sd	s0,144(sp)
    80005846:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	830080e7          	jalr	-2000(ra) # 80004078 <begin_op>
  argint(1, &major);
    80005850:	f6c40593          	addi	a1,s0,-148
    80005854:	4505                	li	a0,1
    80005856:	ffffd097          	auipc	ra,0xffffd
    8000585a:	280080e7          	jalr	640(ra) # 80002ad6 <argint>
  argint(2, &minor);
    8000585e:	f6840593          	addi	a1,s0,-152
    80005862:	4509                	li	a0,2
    80005864:	ffffd097          	auipc	ra,0xffffd
    80005868:	272080e7          	jalr	626(ra) # 80002ad6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000586c:	08000613          	li	a2,128
    80005870:	f7040593          	addi	a1,s0,-144
    80005874:	4501                	li	a0,0
    80005876:	ffffd097          	auipc	ra,0xffffd
    8000587a:	304080e7          	jalr	772(ra) # 80002b7a <argstr>
    8000587e:	02054b63          	bltz	a0,800058b4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005882:	f6841683          	lh	a3,-152(s0)
    80005886:	f6c41603          	lh	a2,-148(s0)
    8000588a:	458d                	li	a1,3
    8000588c:	f7040513          	addi	a0,s0,-144
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	77e080e7          	jalr	1918(ra) # 8000500e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005898:	cd11                	beqz	a0,800058b4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	07e080e7          	jalr	126(ra) # 80003918 <iunlockput>
  end_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	856080e7          	jalr	-1962(ra) # 800040f8 <end_op>
  return 0;
    800058aa:	4501                	li	a0,0
}
    800058ac:	60ea                	ld	ra,152(sp)
    800058ae:	644a                	ld	s0,144(sp)
    800058b0:	610d                	addi	sp,sp,160
    800058b2:	8082                	ret
    end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	844080e7          	jalr	-1980(ra) # 800040f8 <end_op>
    return -1;
    800058bc:	557d                	li	a0,-1
    800058be:	b7fd                	j	800058ac <sys_mknod+0x6c>

00000000800058c0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058c0:	7135                	addi	sp,sp,-160
    800058c2:	ed06                	sd	ra,152(sp)
    800058c4:	e922                	sd	s0,144(sp)
    800058c6:	e526                	sd	s1,136(sp)
    800058c8:	e14a                	sd	s2,128(sp)
    800058ca:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058cc:	ffffc097          	auipc	ra,0xffffc
    800058d0:	0fa080e7          	jalr	250(ra) # 800019c6 <myproc>
    800058d4:	892a                	mv	s2,a0
  
  begin_op();
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	7a2080e7          	jalr	1954(ra) # 80004078 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058de:	08000613          	li	a2,128
    800058e2:	f6040593          	addi	a1,s0,-160
    800058e6:	4501                	li	a0,0
    800058e8:	ffffd097          	auipc	ra,0xffffd
    800058ec:	292080e7          	jalr	658(ra) # 80002b7a <argstr>
    800058f0:	04054b63          	bltz	a0,80005946 <sys_chdir+0x86>
    800058f4:	f6040513          	addi	a0,s0,-160
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	564080e7          	jalr	1380(ra) # 80003e5c <namei>
    80005900:	84aa                	mv	s1,a0
    80005902:	c131                	beqz	a0,80005946 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	db2080e7          	jalr	-590(ra) # 800036b6 <ilock>
  if(ip->type != T_DIR){
    8000590c:	04449703          	lh	a4,68(s1)
    80005910:	4785                	li	a5,1
    80005912:	04f71063          	bne	a4,a5,80005952 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005916:	8526                	mv	a0,s1
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	e60080e7          	jalr	-416(ra) # 80003778 <iunlock>
  iput(p->cwd);
    80005920:	15093503          	ld	a0,336(s2)
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	f4c080e7          	jalr	-180(ra) # 80003870 <iput>
  end_op();
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	7cc080e7          	jalr	1996(ra) # 800040f8 <end_op>
  p->cwd = ip;
    80005934:	14993823          	sd	s1,336(s2)
  return 0;
    80005938:	4501                	li	a0,0
}
    8000593a:	60ea                	ld	ra,152(sp)
    8000593c:	644a                	ld	s0,144(sp)
    8000593e:	64aa                	ld	s1,136(sp)
    80005940:	690a                	ld	s2,128(sp)
    80005942:	610d                	addi	sp,sp,160
    80005944:	8082                	ret
    end_op();
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	7b2080e7          	jalr	1970(ra) # 800040f8 <end_op>
    return -1;
    8000594e:	557d                	li	a0,-1
    80005950:	b7ed                	j	8000593a <sys_chdir+0x7a>
    iunlockput(ip);
    80005952:	8526                	mv	a0,s1
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	fc4080e7          	jalr	-60(ra) # 80003918 <iunlockput>
    end_op();
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	79c080e7          	jalr	1948(ra) # 800040f8 <end_op>
    return -1;
    80005964:	557d                	li	a0,-1
    80005966:	bfd1                	j	8000593a <sys_chdir+0x7a>

0000000080005968 <sys_exec>:

uint64
sys_exec(void)
{
    80005968:	7145                	addi	sp,sp,-464
    8000596a:	e786                	sd	ra,456(sp)
    8000596c:	e3a2                	sd	s0,448(sp)
    8000596e:	ff26                	sd	s1,440(sp)
    80005970:	fb4a                	sd	s2,432(sp)
    80005972:	f74e                	sd	s3,424(sp)
    80005974:	f352                	sd	s4,416(sp)
    80005976:	ef56                	sd	s5,408(sp)
    80005978:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000597a:	e3840593          	addi	a1,s0,-456
    8000597e:	4505                	li	a0,1
    80005980:	ffffd097          	auipc	ra,0xffffd
    80005984:	1da080e7          	jalr	474(ra) # 80002b5a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005988:	08000613          	li	a2,128
    8000598c:	f4040593          	addi	a1,s0,-192
    80005990:	4501                	li	a0,0
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	1e8080e7          	jalr	488(ra) # 80002b7a <argstr>
    8000599a:	87aa                	mv	a5,a0
    return -1;
    8000599c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000599e:	0c07c263          	bltz	a5,80005a62 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059a2:	10000613          	li	a2,256
    800059a6:	4581                	li	a1,0
    800059a8:	e4040513          	addi	a0,s0,-448
    800059ac:	ffffb097          	auipc	ra,0xffffb
    800059b0:	33a080e7          	jalr	826(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059b4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059b8:	89a6                	mv	s3,s1
    800059ba:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059bc:	02000a13          	li	s4,32
    800059c0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059c4:	00391513          	slli	a0,s2,0x3
    800059c8:	e3040593          	addi	a1,s0,-464
    800059cc:	e3843783          	ld	a5,-456(s0)
    800059d0:	953e                	add	a0,a0,a5
    800059d2:	ffffd097          	auipc	ra,0xffffd
    800059d6:	066080e7          	jalr	102(ra) # 80002a38 <fetchaddr>
    800059da:	02054a63          	bltz	a0,80005a0e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800059de:	e3043783          	ld	a5,-464(s0)
    800059e2:	c3b9                	beqz	a5,80005a28 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059e4:	ffffb097          	auipc	ra,0xffffb
    800059e8:	116080e7          	jalr	278(ra) # 80000afa <kalloc>
    800059ec:	85aa                	mv	a1,a0
    800059ee:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059f2:	cd11                	beqz	a0,80005a0e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059f4:	6605                	lui	a2,0x1
    800059f6:	e3043503          	ld	a0,-464(s0)
    800059fa:	ffffd097          	auipc	ra,0xffffd
    800059fe:	090080e7          	jalr	144(ra) # 80002a8a <fetchstr>
    80005a02:	00054663          	bltz	a0,80005a0e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005a06:	0905                	addi	s2,s2,1
    80005a08:	09a1                	addi	s3,s3,8
    80005a0a:	fb491be3          	bne	s2,s4,800059c0 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a0e:	10048913          	addi	s2,s1,256
    80005a12:	6088                	ld	a0,0(s1)
    80005a14:	c531                	beqz	a0,80005a60 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a16:	ffffb097          	auipc	ra,0xffffb
    80005a1a:	fe8080e7          	jalr	-24(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a1e:	04a1                	addi	s1,s1,8
    80005a20:	ff2499e3          	bne	s1,s2,80005a12 <sys_exec+0xaa>
  return -1;
    80005a24:	557d                	li	a0,-1
    80005a26:	a835                	j	80005a62 <sys_exec+0xfa>
      argv[i] = 0;
    80005a28:	0a8e                	slli	s5,s5,0x3
    80005a2a:	fc040793          	addi	a5,s0,-64
    80005a2e:	9abe                	add	s5,s5,a5
    80005a30:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a34:	e4040593          	addi	a1,s0,-448
    80005a38:	f4040513          	addi	a0,s0,-192
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	190080e7          	jalr	400(ra) # 80004bcc <exec>
    80005a44:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a46:	10048993          	addi	s3,s1,256
    80005a4a:	6088                	ld	a0,0(s1)
    80005a4c:	c901                	beqz	a0,80005a5c <sys_exec+0xf4>
    kfree(argv[i]);
    80005a4e:	ffffb097          	auipc	ra,0xffffb
    80005a52:	fb0080e7          	jalr	-80(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a56:	04a1                	addi	s1,s1,8
    80005a58:	ff3499e3          	bne	s1,s3,80005a4a <sys_exec+0xe2>
  return ret;
    80005a5c:	854a                	mv	a0,s2
    80005a5e:	a011                	j	80005a62 <sys_exec+0xfa>
  return -1;
    80005a60:	557d                	li	a0,-1
}
    80005a62:	60be                	ld	ra,456(sp)
    80005a64:	641e                	ld	s0,448(sp)
    80005a66:	74fa                	ld	s1,440(sp)
    80005a68:	795a                	ld	s2,432(sp)
    80005a6a:	79ba                	ld	s3,424(sp)
    80005a6c:	7a1a                	ld	s4,416(sp)
    80005a6e:	6afa                	ld	s5,408(sp)
    80005a70:	6179                	addi	sp,sp,464
    80005a72:	8082                	ret

0000000080005a74 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a74:	7139                	addi	sp,sp,-64
    80005a76:	fc06                	sd	ra,56(sp)
    80005a78:	f822                	sd	s0,48(sp)
    80005a7a:	f426                	sd	s1,40(sp)
    80005a7c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a7e:	ffffc097          	auipc	ra,0xffffc
    80005a82:	f48080e7          	jalr	-184(ra) # 800019c6 <myproc>
    80005a86:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005a88:	fd840593          	addi	a1,s0,-40
    80005a8c:	4501                	li	a0,0
    80005a8e:	ffffd097          	auipc	ra,0xffffd
    80005a92:	0cc080e7          	jalr	204(ra) # 80002b5a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005a96:	fc840593          	addi	a1,s0,-56
    80005a9a:	fd040513          	addi	a0,s0,-48
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	dd6080e7          	jalr	-554(ra) # 80004874 <pipealloc>
    return -1;
    80005aa6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005aa8:	0c054463          	bltz	a0,80005b70 <sys_pipe+0xfc>
  fd0 = -1;
    80005aac:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ab0:	fd043503          	ld	a0,-48(s0)
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	518080e7          	jalr	1304(ra) # 80004fcc <fdalloc>
    80005abc:	fca42223          	sw	a0,-60(s0)
    80005ac0:	08054b63          	bltz	a0,80005b56 <sys_pipe+0xe2>
    80005ac4:	fc843503          	ld	a0,-56(s0)
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	504080e7          	jalr	1284(ra) # 80004fcc <fdalloc>
    80005ad0:	fca42023          	sw	a0,-64(s0)
    80005ad4:	06054863          	bltz	a0,80005b44 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ad8:	4691                	li	a3,4
    80005ada:	fc440613          	addi	a2,s0,-60
    80005ade:	fd843583          	ld	a1,-40(s0)
    80005ae2:	68a8                	ld	a0,80(s1)
    80005ae4:	ffffc097          	auipc	ra,0xffffc
    80005ae8:	ba0080e7          	jalr	-1120(ra) # 80001684 <copyout>
    80005aec:	02054063          	bltz	a0,80005b0c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005af0:	4691                	li	a3,4
    80005af2:	fc040613          	addi	a2,s0,-64
    80005af6:	fd843583          	ld	a1,-40(s0)
    80005afa:	0591                	addi	a1,a1,4
    80005afc:	68a8                	ld	a0,80(s1)
    80005afe:	ffffc097          	auipc	ra,0xffffc
    80005b02:	b86080e7          	jalr	-1146(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b06:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b08:	06055463          	bgez	a0,80005b70 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005b0c:	fc442783          	lw	a5,-60(s0)
    80005b10:	07e9                	addi	a5,a5,26
    80005b12:	078e                	slli	a5,a5,0x3
    80005b14:	97a6                	add	a5,a5,s1
    80005b16:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b1a:	fc042503          	lw	a0,-64(s0)
    80005b1e:	0569                	addi	a0,a0,26
    80005b20:	050e                	slli	a0,a0,0x3
    80005b22:	94aa                	add	s1,s1,a0
    80005b24:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b28:	fd043503          	ld	a0,-48(s0)
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	a18080e7          	jalr	-1512(ra) # 80004544 <fileclose>
    fileclose(wf);
    80005b34:	fc843503          	ld	a0,-56(s0)
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	a0c080e7          	jalr	-1524(ra) # 80004544 <fileclose>
    return -1;
    80005b40:	57fd                	li	a5,-1
    80005b42:	a03d                	j	80005b70 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005b44:	fc442783          	lw	a5,-60(s0)
    80005b48:	0007c763          	bltz	a5,80005b56 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005b4c:	07e9                	addi	a5,a5,26
    80005b4e:	078e                	slli	a5,a5,0x3
    80005b50:	94be                	add	s1,s1,a5
    80005b52:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b56:	fd043503          	ld	a0,-48(s0)
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	9ea080e7          	jalr	-1558(ra) # 80004544 <fileclose>
    fileclose(wf);
    80005b62:	fc843503          	ld	a0,-56(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	9de080e7          	jalr	-1570(ra) # 80004544 <fileclose>
    return -1;
    80005b6e:	57fd                	li	a5,-1
    80005b70:	853e                	mv	a0,a5
    80005b72:	70e2                	ld	ra,56(sp)
    80005b74:	7442                	ld	s0,48(sp)
    80005b76:	74a2                	ld	s1,40(sp)
    80005b78:	6121                	addi	sp,sp,64
    80005b7a:	8082                	ret
    80005b7c:	0000                	unimp
	...

0000000080005b80 <kernelvec>:
    80005b80:	7111                	addi	sp,sp,-256
    80005b82:	e006                	sd	ra,0(sp)
    80005b84:	e40a                	sd	sp,8(sp)
    80005b86:	e80e                	sd	gp,16(sp)
    80005b88:	ec12                	sd	tp,24(sp)
    80005b8a:	f016                	sd	t0,32(sp)
    80005b8c:	f41a                	sd	t1,40(sp)
    80005b8e:	f81e                	sd	t2,48(sp)
    80005b90:	fc22                	sd	s0,56(sp)
    80005b92:	e0a6                	sd	s1,64(sp)
    80005b94:	e4aa                	sd	a0,72(sp)
    80005b96:	e8ae                	sd	a1,80(sp)
    80005b98:	ecb2                	sd	a2,88(sp)
    80005b9a:	f0b6                	sd	a3,96(sp)
    80005b9c:	f4ba                	sd	a4,104(sp)
    80005b9e:	f8be                	sd	a5,112(sp)
    80005ba0:	fcc2                	sd	a6,120(sp)
    80005ba2:	e146                	sd	a7,128(sp)
    80005ba4:	e54a                	sd	s2,136(sp)
    80005ba6:	e94e                	sd	s3,144(sp)
    80005ba8:	ed52                	sd	s4,152(sp)
    80005baa:	f156                	sd	s5,160(sp)
    80005bac:	f55a                	sd	s6,168(sp)
    80005bae:	f95e                	sd	s7,176(sp)
    80005bb0:	fd62                	sd	s8,184(sp)
    80005bb2:	e1e6                	sd	s9,192(sp)
    80005bb4:	e5ea                	sd	s10,200(sp)
    80005bb6:	e9ee                	sd	s11,208(sp)
    80005bb8:	edf2                	sd	t3,216(sp)
    80005bba:	f1f6                	sd	t4,224(sp)
    80005bbc:	f5fa                	sd	t5,232(sp)
    80005bbe:	f9fe                	sd	t6,240(sp)
    80005bc0:	d45fc0ef          	jal	ra,80002904 <kerneltrap>
    80005bc4:	6082                	ld	ra,0(sp)
    80005bc6:	6122                	ld	sp,8(sp)
    80005bc8:	61c2                	ld	gp,16(sp)
    80005bca:	7282                	ld	t0,32(sp)
    80005bcc:	7322                	ld	t1,40(sp)
    80005bce:	73c2                	ld	t2,48(sp)
    80005bd0:	7462                	ld	s0,56(sp)
    80005bd2:	6486                	ld	s1,64(sp)
    80005bd4:	6526                	ld	a0,72(sp)
    80005bd6:	65c6                	ld	a1,80(sp)
    80005bd8:	6666                	ld	a2,88(sp)
    80005bda:	7686                	ld	a3,96(sp)
    80005bdc:	7726                	ld	a4,104(sp)
    80005bde:	77c6                	ld	a5,112(sp)
    80005be0:	7866                	ld	a6,120(sp)
    80005be2:	688a                	ld	a7,128(sp)
    80005be4:	692a                	ld	s2,136(sp)
    80005be6:	69ca                	ld	s3,144(sp)
    80005be8:	6a6a                	ld	s4,152(sp)
    80005bea:	7a8a                	ld	s5,160(sp)
    80005bec:	7b2a                	ld	s6,168(sp)
    80005bee:	7bca                	ld	s7,176(sp)
    80005bf0:	7c6a                	ld	s8,184(sp)
    80005bf2:	6c8e                	ld	s9,192(sp)
    80005bf4:	6d2e                	ld	s10,200(sp)
    80005bf6:	6dce                	ld	s11,208(sp)
    80005bf8:	6e6e                	ld	t3,216(sp)
    80005bfa:	7e8e                	ld	t4,224(sp)
    80005bfc:	7f2e                	ld	t5,232(sp)
    80005bfe:	7fce                	ld	t6,240(sp)
    80005c00:	6111                	addi	sp,sp,256
    80005c02:	10200073          	sret
    80005c06:	00000013          	nop
    80005c0a:	00000013          	nop
    80005c0e:	0001                	nop

0000000080005c10 <timervec>:
    80005c10:	34051573          	csrrw	a0,mscratch,a0
    80005c14:	e10c                	sd	a1,0(a0)
    80005c16:	e510                	sd	a2,8(a0)
    80005c18:	e914                	sd	a3,16(a0)
    80005c1a:	6d0c                	ld	a1,24(a0)
    80005c1c:	7110                	ld	a2,32(a0)
    80005c1e:	6194                	ld	a3,0(a1)
    80005c20:	96b2                	add	a3,a3,a2
    80005c22:	e194                	sd	a3,0(a1)
    80005c24:	4589                	li	a1,2
    80005c26:	14459073          	csrw	sip,a1
    80005c2a:	6914                	ld	a3,16(a0)
    80005c2c:	6510                	ld	a2,8(a0)
    80005c2e:	610c                	ld	a1,0(a0)
    80005c30:	34051573          	csrrw	a0,mscratch,a0
    80005c34:	30200073          	mret
	...

0000000080005c3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c3a:	1141                	addi	sp,sp,-16
    80005c3c:	e422                	sd	s0,8(sp)
    80005c3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c40:	0c0007b7          	lui	a5,0xc000
    80005c44:	4705                	li	a4,1
    80005c46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c48:	c3d8                	sw	a4,4(a5)
}
    80005c4a:	6422                	ld	s0,8(sp)
    80005c4c:	0141                	addi	sp,sp,16
    80005c4e:	8082                	ret

0000000080005c50 <plicinithart>:

void
plicinithart(void)
{
    80005c50:	1141                	addi	sp,sp,-16
    80005c52:	e406                	sd	ra,8(sp)
    80005c54:	e022                	sd	s0,0(sp)
    80005c56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	d42080e7          	jalr	-702(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c60:	0085171b          	slliw	a4,a0,0x8
    80005c64:	0c0027b7          	lui	a5,0xc002
    80005c68:	97ba                	add	a5,a5,a4
    80005c6a:	40200713          	li	a4,1026
    80005c6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c72:	00d5151b          	slliw	a0,a0,0xd
    80005c76:	0c2017b7          	lui	a5,0xc201
    80005c7a:	953e                	add	a0,a0,a5
    80005c7c:	00052023          	sw	zero,0(a0)
}
    80005c80:	60a2                	ld	ra,8(sp)
    80005c82:	6402                	ld	s0,0(sp)
    80005c84:	0141                	addi	sp,sp,16
    80005c86:	8082                	ret

0000000080005c88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c88:	1141                	addi	sp,sp,-16
    80005c8a:	e406                	sd	ra,8(sp)
    80005c8c:	e022                	sd	s0,0(sp)
    80005c8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c90:	ffffc097          	auipc	ra,0xffffc
    80005c94:	d0a080e7          	jalr	-758(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c98:	00d5179b          	slliw	a5,a0,0xd
    80005c9c:	0c201537          	lui	a0,0xc201
    80005ca0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ca2:	4148                	lw	a0,4(a0)
    80005ca4:	60a2                	ld	ra,8(sp)
    80005ca6:	6402                	ld	s0,0(sp)
    80005ca8:	0141                	addi	sp,sp,16
    80005caa:	8082                	ret

0000000080005cac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cac:	1101                	addi	sp,sp,-32
    80005cae:	ec06                	sd	ra,24(sp)
    80005cb0:	e822                	sd	s0,16(sp)
    80005cb2:	e426                	sd	s1,8(sp)
    80005cb4:	1000                	addi	s0,sp,32
    80005cb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cb8:	ffffc097          	auipc	ra,0xffffc
    80005cbc:	ce2080e7          	jalr	-798(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cc0:	00d5151b          	slliw	a0,a0,0xd
    80005cc4:	0c2017b7          	lui	a5,0xc201
    80005cc8:	97aa                	add	a5,a5,a0
    80005cca:	c3c4                	sw	s1,4(a5)
}
    80005ccc:	60e2                	ld	ra,24(sp)
    80005cce:	6442                	ld	s0,16(sp)
    80005cd0:	64a2                	ld	s1,8(sp)
    80005cd2:	6105                	addi	sp,sp,32
    80005cd4:	8082                	ret

0000000080005cd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cd6:	1141                	addi	sp,sp,-16
    80005cd8:	e406                	sd	ra,8(sp)
    80005cda:	e022                	sd	s0,0(sp)
    80005cdc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cde:	479d                	li	a5,7
    80005ce0:	04a7cc63          	blt	a5,a0,80005d38 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005ce4:	0001c797          	auipc	a5,0x1c
    80005ce8:	00478793          	addi	a5,a5,4 # 80021ce8 <disk>
    80005cec:	97aa                	add	a5,a5,a0
    80005cee:	0187c783          	lbu	a5,24(a5)
    80005cf2:	ebb9                	bnez	a5,80005d48 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005cf4:	00451613          	slli	a2,a0,0x4
    80005cf8:	0001c797          	auipc	a5,0x1c
    80005cfc:	ff078793          	addi	a5,a5,-16 # 80021ce8 <disk>
    80005d00:	6394                	ld	a3,0(a5)
    80005d02:	96b2                	add	a3,a3,a2
    80005d04:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d08:	6398                	ld	a4,0(a5)
    80005d0a:	9732                	add	a4,a4,a2
    80005d0c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005d10:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005d14:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005d18:	953e                	add	a0,a0,a5
    80005d1a:	4785                	li	a5,1
    80005d1c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005d20:	0001c517          	auipc	a0,0x1c
    80005d24:	fe050513          	addi	a0,a0,-32 # 80021d00 <disk+0x18>
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	3a6080e7          	jalr	934(ra) # 800020ce <wakeup>
}
    80005d30:	60a2                	ld	ra,8(sp)
    80005d32:	6402                	ld	s0,0(sp)
    80005d34:	0141                	addi	sp,sp,16
    80005d36:	8082                	ret
    panic("free_desc 1");
    80005d38:	00003517          	auipc	a0,0x3
    80005d3c:	a2850513          	addi	a0,a0,-1496 # 80008760 <syscalls+0x2f8>
    80005d40:	ffffb097          	auipc	ra,0xffffb
    80005d44:	804080e7          	jalr	-2044(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005d48:	00003517          	auipc	a0,0x3
    80005d4c:	a2850513          	addi	a0,a0,-1496 # 80008770 <syscalls+0x308>
    80005d50:	ffffa097          	auipc	ra,0xffffa
    80005d54:	7f4080e7          	jalr	2036(ra) # 80000544 <panic>

0000000080005d58 <virtio_disk_init>:
{
    80005d58:	1101                	addi	sp,sp,-32
    80005d5a:	ec06                	sd	ra,24(sp)
    80005d5c:	e822                	sd	s0,16(sp)
    80005d5e:	e426                	sd	s1,8(sp)
    80005d60:	e04a                	sd	s2,0(sp)
    80005d62:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d64:	00003597          	auipc	a1,0x3
    80005d68:	a1c58593          	addi	a1,a1,-1508 # 80008780 <syscalls+0x318>
    80005d6c:	0001c517          	auipc	a0,0x1c
    80005d70:	0a450513          	addi	a0,a0,164 # 80021e10 <disk+0x128>
    80005d74:	ffffb097          	auipc	ra,0xffffb
    80005d78:	de6080e7          	jalr	-538(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d7c:	100017b7          	lui	a5,0x10001
    80005d80:	4398                	lw	a4,0(a5)
    80005d82:	2701                	sext.w	a4,a4
    80005d84:	747277b7          	lui	a5,0x74727
    80005d88:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d8c:	14f71e63          	bne	a4,a5,80005ee8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005d90:	100017b7          	lui	a5,0x10001
    80005d94:	43dc                	lw	a5,4(a5)
    80005d96:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d98:	4709                	li	a4,2
    80005d9a:	14e79763          	bne	a5,a4,80005ee8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d9e:	100017b7          	lui	a5,0x10001
    80005da2:	479c                	lw	a5,8(a5)
    80005da4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005da6:	14e79163          	bne	a5,a4,80005ee8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005daa:	100017b7          	lui	a5,0x10001
    80005dae:	47d8                	lw	a4,12(a5)
    80005db0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005db2:	554d47b7          	lui	a5,0x554d4
    80005db6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005dba:	12f71763          	bne	a4,a5,80005ee8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dbe:	100017b7          	lui	a5,0x10001
    80005dc2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dc6:	4705                	li	a4,1
    80005dc8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dca:	470d                	li	a4,3
    80005dcc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dce:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005dd0:	c7ffe737          	lui	a4,0xc7ffe
    80005dd4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc937>
    80005dd8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005dda:	2701                	sext.w	a4,a4
    80005ddc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dde:	472d                	li	a4,11
    80005de0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005de2:	0707a903          	lw	s2,112(a5)
    80005de6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005de8:	00897793          	andi	a5,s2,8
    80005dec:	10078663          	beqz	a5,80005ef8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005df0:	100017b7          	lui	a5,0x10001
    80005df4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005df8:	43fc                	lw	a5,68(a5)
    80005dfa:	2781                	sext.w	a5,a5
    80005dfc:	10079663          	bnez	a5,80005f08 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e00:	100017b7          	lui	a5,0x10001
    80005e04:	5bdc                	lw	a5,52(a5)
    80005e06:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e08:	10078863          	beqz	a5,80005f18 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005e0c:	471d                	li	a4,7
    80005e0e:	10f77d63          	bgeu	a4,a5,80005f28 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005e12:	ffffb097          	auipc	ra,0xffffb
    80005e16:	ce8080e7          	jalr	-792(ra) # 80000afa <kalloc>
    80005e1a:	0001c497          	auipc	s1,0x1c
    80005e1e:	ece48493          	addi	s1,s1,-306 # 80021ce8 <disk>
    80005e22:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005e24:	ffffb097          	auipc	ra,0xffffb
    80005e28:	cd6080e7          	jalr	-810(ra) # 80000afa <kalloc>
    80005e2c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005e2e:	ffffb097          	auipc	ra,0xffffb
    80005e32:	ccc080e7          	jalr	-820(ra) # 80000afa <kalloc>
    80005e36:	87aa                	mv	a5,a0
    80005e38:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005e3a:	6088                	ld	a0,0(s1)
    80005e3c:	cd75                	beqz	a0,80005f38 <virtio_disk_init+0x1e0>
    80005e3e:	0001c717          	auipc	a4,0x1c
    80005e42:	eb273703          	ld	a4,-334(a4) # 80021cf0 <disk+0x8>
    80005e46:	cb6d                	beqz	a4,80005f38 <virtio_disk_init+0x1e0>
    80005e48:	cbe5                	beqz	a5,80005f38 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005e4a:	6605                	lui	a2,0x1
    80005e4c:	4581                	li	a1,0
    80005e4e:	ffffb097          	auipc	ra,0xffffb
    80005e52:	e98080e7          	jalr	-360(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005e56:	0001c497          	auipc	s1,0x1c
    80005e5a:	e9248493          	addi	s1,s1,-366 # 80021ce8 <disk>
    80005e5e:	6605                	lui	a2,0x1
    80005e60:	4581                	li	a1,0
    80005e62:	6488                	ld	a0,8(s1)
    80005e64:	ffffb097          	auipc	ra,0xffffb
    80005e68:	e82080e7          	jalr	-382(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005e6c:	6605                	lui	a2,0x1
    80005e6e:	4581                	li	a1,0
    80005e70:	6888                	ld	a0,16(s1)
    80005e72:	ffffb097          	auipc	ra,0xffffb
    80005e76:	e74080e7          	jalr	-396(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e7a:	100017b7          	lui	a5,0x10001
    80005e7e:	4721                	li	a4,8
    80005e80:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005e82:	4098                	lw	a4,0(s1)
    80005e84:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005e88:	40d8                	lw	a4,4(s1)
    80005e8a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005e8e:	6498                	ld	a4,8(s1)
    80005e90:	0007069b          	sext.w	a3,a4
    80005e94:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005e98:	9701                	srai	a4,a4,0x20
    80005e9a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005e9e:	6898                	ld	a4,16(s1)
    80005ea0:	0007069b          	sext.w	a3,a4
    80005ea4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005ea8:	9701                	srai	a4,a4,0x20
    80005eaa:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005eae:	4685                	li	a3,1
    80005eb0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80005eb2:	4705                	li	a4,1
    80005eb4:	00d48c23          	sb	a3,24(s1)
    80005eb8:	00e48ca3          	sb	a4,25(s1)
    80005ebc:	00e48d23          	sb	a4,26(s1)
    80005ec0:	00e48da3          	sb	a4,27(s1)
    80005ec4:	00e48e23          	sb	a4,28(s1)
    80005ec8:	00e48ea3          	sb	a4,29(s1)
    80005ecc:	00e48f23          	sb	a4,30(s1)
    80005ed0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005ed4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed8:	0727a823          	sw	s2,112(a5)
}
    80005edc:	60e2                	ld	ra,24(sp)
    80005ede:	6442                	ld	s0,16(sp)
    80005ee0:	64a2                	ld	s1,8(sp)
    80005ee2:	6902                	ld	s2,0(sp)
    80005ee4:	6105                	addi	sp,sp,32
    80005ee6:	8082                	ret
    panic("could not find virtio disk");
    80005ee8:	00003517          	auipc	a0,0x3
    80005eec:	8a850513          	addi	a0,a0,-1880 # 80008790 <syscalls+0x328>
    80005ef0:	ffffa097          	auipc	ra,0xffffa
    80005ef4:	654080e7          	jalr	1620(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005ef8:	00003517          	auipc	a0,0x3
    80005efc:	8b850513          	addi	a0,a0,-1864 # 800087b0 <syscalls+0x348>
    80005f00:	ffffa097          	auipc	ra,0xffffa
    80005f04:	644080e7          	jalr	1604(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80005f08:	00003517          	auipc	a0,0x3
    80005f0c:	8c850513          	addi	a0,a0,-1848 # 800087d0 <syscalls+0x368>
    80005f10:	ffffa097          	auipc	ra,0xffffa
    80005f14:	634080e7          	jalr	1588(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80005f18:	00003517          	auipc	a0,0x3
    80005f1c:	8d850513          	addi	a0,a0,-1832 # 800087f0 <syscalls+0x388>
    80005f20:	ffffa097          	auipc	ra,0xffffa
    80005f24:	624080e7          	jalr	1572(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80005f28:	00003517          	auipc	a0,0x3
    80005f2c:	8e850513          	addi	a0,a0,-1816 # 80008810 <syscalls+0x3a8>
    80005f30:	ffffa097          	auipc	ra,0xffffa
    80005f34:	614080e7          	jalr	1556(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80005f38:	00003517          	auipc	a0,0x3
    80005f3c:	8f850513          	addi	a0,a0,-1800 # 80008830 <syscalls+0x3c8>
    80005f40:	ffffa097          	auipc	ra,0xffffa
    80005f44:	604080e7          	jalr	1540(ra) # 80000544 <panic>

0000000080005f48 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f48:	7159                	addi	sp,sp,-112
    80005f4a:	f486                	sd	ra,104(sp)
    80005f4c:	f0a2                	sd	s0,96(sp)
    80005f4e:	eca6                	sd	s1,88(sp)
    80005f50:	e8ca                	sd	s2,80(sp)
    80005f52:	e4ce                	sd	s3,72(sp)
    80005f54:	e0d2                	sd	s4,64(sp)
    80005f56:	fc56                	sd	s5,56(sp)
    80005f58:	f85a                	sd	s6,48(sp)
    80005f5a:	f45e                	sd	s7,40(sp)
    80005f5c:	f062                	sd	s8,32(sp)
    80005f5e:	ec66                	sd	s9,24(sp)
    80005f60:	e86a                	sd	s10,16(sp)
    80005f62:	1880                	addi	s0,sp,112
    80005f64:	892a                	mv	s2,a0
    80005f66:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f68:	00c52c83          	lw	s9,12(a0)
    80005f6c:	001c9c9b          	slliw	s9,s9,0x1
    80005f70:	1c82                	slli	s9,s9,0x20
    80005f72:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f76:	0001c517          	auipc	a0,0x1c
    80005f7a:	e9a50513          	addi	a0,a0,-358 # 80021e10 <disk+0x128>
    80005f7e:	ffffb097          	auipc	ra,0xffffb
    80005f82:	c6c080e7          	jalr	-916(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80005f86:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f88:	4ba1                	li	s7,8
      disk.free[i] = 0;
    80005f8a:	0001cb17          	auipc	s6,0x1c
    80005f8e:	d5eb0b13          	addi	s6,s6,-674 # 80021ce8 <disk>
  for(int i = 0; i < 3; i++){
    80005f92:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f94:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f96:	0001cc17          	auipc	s8,0x1c
    80005f9a:	e7ac0c13          	addi	s8,s8,-390 # 80021e10 <disk+0x128>
    80005f9e:	a8b5                	j	8000601a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80005fa0:	00fb06b3          	add	a3,s6,a5
    80005fa4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fa8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005faa:	0207c563          	bltz	a5,80005fd4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80005fae:	2485                	addiw	s1,s1,1
    80005fb0:	0711                	addi	a4,a4,4
    80005fb2:	1f548a63          	beq	s1,s5,800061a6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80005fb6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fb8:	0001c697          	auipc	a3,0x1c
    80005fbc:	d3068693          	addi	a3,a3,-720 # 80021ce8 <disk>
    80005fc0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fc2:	0186c583          	lbu	a1,24(a3)
    80005fc6:	fde9                	bnez	a1,80005fa0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80005fc8:	2785                	addiw	a5,a5,1
    80005fca:	0685                	addi	a3,a3,1
    80005fcc:	ff779be3          	bne	a5,s7,80005fc2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80005fd0:	57fd                	li	a5,-1
    80005fd2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fd4:	02905a63          	blez	s1,80006008 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80005fd8:	f9042503          	lw	a0,-112(s0)
    80005fdc:	00000097          	auipc	ra,0x0
    80005fe0:	cfa080e7          	jalr	-774(ra) # 80005cd6 <free_desc>
      for(int j = 0; j < i; j++)
    80005fe4:	4785                	li	a5,1
    80005fe6:	0297d163          	bge	a5,s1,80006008 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80005fea:	f9442503          	lw	a0,-108(s0)
    80005fee:	00000097          	auipc	ra,0x0
    80005ff2:	ce8080e7          	jalr	-792(ra) # 80005cd6 <free_desc>
      for(int j = 0; j < i; j++)
    80005ff6:	4789                	li	a5,2
    80005ff8:	0097d863          	bge	a5,s1,80006008 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80005ffc:	f9842503          	lw	a0,-104(s0)
    80006000:	00000097          	auipc	ra,0x0
    80006004:	cd6080e7          	jalr	-810(ra) # 80005cd6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006008:	85e2                	mv	a1,s8
    8000600a:	0001c517          	auipc	a0,0x1c
    8000600e:	cf650513          	addi	a0,a0,-778 # 80021d00 <disk+0x18>
    80006012:	ffffc097          	auipc	ra,0xffffc
    80006016:	058080e7          	jalr	88(ra) # 8000206a <sleep>
  for(int i = 0; i < 3; i++){
    8000601a:	f9040713          	addi	a4,s0,-112
    8000601e:	84ce                	mv	s1,s3
    80006020:	bf59                	j	80005fb6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006022:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006026:	00479693          	slli	a3,a5,0x4
    8000602a:	0001c797          	auipc	a5,0x1c
    8000602e:	cbe78793          	addi	a5,a5,-834 # 80021ce8 <disk>
    80006032:	97b6                	add	a5,a5,a3
    80006034:	4685                	li	a3,1
    80006036:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006038:	0001c597          	auipc	a1,0x1c
    8000603c:	cb058593          	addi	a1,a1,-848 # 80021ce8 <disk>
    80006040:	00a60793          	addi	a5,a2,10
    80006044:	0792                	slli	a5,a5,0x4
    80006046:	97ae                	add	a5,a5,a1
    80006048:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000604c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006050:	f6070693          	addi	a3,a4,-160
    80006054:	619c                	ld	a5,0(a1)
    80006056:	97b6                	add	a5,a5,a3
    80006058:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000605a:	6188                	ld	a0,0(a1)
    8000605c:	96aa                	add	a3,a3,a0
    8000605e:	47c1                	li	a5,16
    80006060:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006062:	4785                	li	a5,1
    80006064:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006068:	f9442783          	lw	a5,-108(s0)
    8000606c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006070:	0792                	slli	a5,a5,0x4
    80006072:	953e                	add	a0,a0,a5
    80006074:	05890693          	addi	a3,s2,88
    80006078:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000607a:	6188                	ld	a0,0(a1)
    8000607c:	97aa                	add	a5,a5,a0
    8000607e:	40000693          	li	a3,1024
    80006082:	c794                	sw	a3,8(a5)
  if(write)
    80006084:	100d0d63          	beqz	s10,8000619e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006088:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000608c:	00c7d683          	lhu	a3,12(a5)
    80006090:	0016e693          	ori	a3,a3,1
    80006094:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006098:	f9842583          	lw	a1,-104(s0)
    8000609c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060a0:	0001c697          	auipc	a3,0x1c
    800060a4:	c4868693          	addi	a3,a3,-952 # 80021ce8 <disk>
    800060a8:	00260793          	addi	a5,a2,2
    800060ac:	0792                	slli	a5,a5,0x4
    800060ae:	97b6                	add	a5,a5,a3
    800060b0:	587d                	li	a6,-1
    800060b2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060b6:	0592                	slli	a1,a1,0x4
    800060b8:	952e                	add	a0,a0,a1
    800060ba:	f9070713          	addi	a4,a4,-112
    800060be:	9736                	add	a4,a4,a3
    800060c0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800060c2:	6298                	ld	a4,0(a3)
    800060c4:	972e                	add	a4,a4,a1
    800060c6:	4585                	li	a1,1
    800060c8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060ca:	4509                	li	a0,2
    800060cc:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800060d0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060d4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800060d8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060dc:	6698                	ld	a4,8(a3)
    800060de:	00275783          	lhu	a5,2(a4)
    800060e2:	8b9d                	andi	a5,a5,7
    800060e4:	0786                	slli	a5,a5,0x1
    800060e6:	97ba                	add	a5,a5,a4
    800060e8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800060ec:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060f0:	6698                	ld	a4,8(a3)
    800060f2:	00275783          	lhu	a5,2(a4)
    800060f6:	2785                	addiw	a5,a5,1
    800060f8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060fc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006100:	100017b7          	lui	a5,0x10001
    80006104:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006108:	00492703          	lw	a4,4(s2)
    8000610c:	4785                	li	a5,1
    8000610e:	02f71163          	bne	a4,a5,80006130 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006112:	0001c997          	auipc	s3,0x1c
    80006116:	cfe98993          	addi	s3,s3,-770 # 80021e10 <disk+0x128>
  while(b->disk == 1) {
    8000611a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000611c:	85ce                	mv	a1,s3
    8000611e:	854a                	mv	a0,s2
    80006120:	ffffc097          	auipc	ra,0xffffc
    80006124:	f4a080e7          	jalr	-182(ra) # 8000206a <sleep>
  while(b->disk == 1) {
    80006128:	00492783          	lw	a5,4(s2)
    8000612c:	fe9788e3          	beq	a5,s1,8000611c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006130:	f9042903          	lw	s2,-112(s0)
    80006134:	00290793          	addi	a5,s2,2
    80006138:	00479713          	slli	a4,a5,0x4
    8000613c:	0001c797          	auipc	a5,0x1c
    80006140:	bac78793          	addi	a5,a5,-1108 # 80021ce8 <disk>
    80006144:	97ba                	add	a5,a5,a4
    80006146:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000614a:	0001c997          	auipc	s3,0x1c
    8000614e:	b9e98993          	addi	s3,s3,-1122 # 80021ce8 <disk>
    80006152:	00491713          	slli	a4,s2,0x4
    80006156:	0009b783          	ld	a5,0(s3)
    8000615a:	97ba                	add	a5,a5,a4
    8000615c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006160:	854a                	mv	a0,s2
    80006162:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006166:	00000097          	auipc	ra,0x0
    8000616a:	b70080e7          	jalr	-1168(ra) # 80005cd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000616e:	8885                	andi	s1,s1,1
    80006170:	f0ed                	bnez	s1,80006152 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006172:	0001c517          	auipc	a0,0x1c
    80006176:	c9e50513          	addi	a0,a0,-866 # 80021e10 <disk+0x128>
    8000617a:	ffffb097          	auipc	ra,0xffffb
    8000617e:	b24080e7          	jalr	-1244(ra) # 80000c9e <release>
}
    80006182:	70a6                	ld	ra,104(sp)
    80006184:	7406                	ld	s0,96(sp)
    80006186:	64e6                	ld	s1,88(sp)
    80006188:	6946                	ld	s2,80(sp)
    8000618a:	69a6                	ld	s3,72(sp)
    8000618c:	6a06                	ld	s4,64(sp)
    8000618e:	7ae2                	ld	s5,56(sp)
    80006190:	7b42                	ld	s6,48(sp)
    80006192:	7ba2                	ld	s7,40(sp)
    80006194:	7c02                	ld	s8,32(sp)
    80006196:	6ce2                	ld	s9,24(sp)
    80006198:	6d42                	ld	s10,16(sp)
    8000619a:	6165                	addi	sp,sp,112
    8000619c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000619e:	4689                	li	a3,2
    800061a0:	00d79623          	sh	a3,12(a5)
    800061a4:	b5e5                	j	8000608c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061a6:	f9042603          	lw	a2,-112(s0)
    800061aa:	00a60713          	addi	a4,a2,10
    800061ae:	0712                	slli	a4,a4,0x4
    800061b0:	0001c517          	auipc	a0,0x1c
    800061b4:	b4050513          	addi	a0,a0,-1216 # 80021cf0 <disk+0x8>
    800061b8:	953a                	add	a0,a0,a4
  if(write)
    800061ba:	e60d14e3          	bnez	s10,80006022 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800061be:	00a60793          	addi	a5,a2,10
    800061c2:	00479693          	slli	a3,a5,0x4
    800061c6:	0001c797          	auipc	a5,0x1c
    800061ca:	b2278793          	addi	a5,a5,-1246 # 80021ce8 <disk>
    800061ce:	97b6                	add	a5,a5,a3
    800061d0:	0007a423          	sw	zero,8(a5)
    800061d4:	b595                	j	80006038 <virtio_disk_rw+0xf0>

00000000800061d6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061d6:	1101                	addi	sp,sp,-32
    800061d8:	ec06                	sd	ra,24(sp)
    800061da:	e822                	sd	s0,16(sp)
    800061dc:	e426                	sd	s1,8(sp)
    800061de:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061e0:	0001c497          	auipc	s1,0x1c
    800061e4:	b0848493          	addi	s1,s1,-1272 # 80021ce8 <disk>
    800061e8:	0001c517          	auipc	a0,0x1c
    800061ec:	c2850513          	addi	a0,a0,-984 # 80021e10 <disk+0x128>
    800061f0:	ffffb097          	auipc	ra,0xffffb
    800061f4:	9fa080e7          	jalr	-1542(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061f8:	10001737          	lui	a4,0x10001
    800061fc:	533c                	lw	a5,96(a4)
    800061fe:	8b8d                	andi	a5,a5,3
    80006200:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006202:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006206:	689c                	ld	a5,16(s1)
    80006208:	0204d703          	lhu	a4,32(s1)
    8000620c:	0027d783          	lhu	a5,2(a5)
    80006210:	04f70863          	beq	a4,a5,80006260 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006214:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006218:	6898                	ld	a4,16(s1)
    8000621a:	0204d783          	lhu	a5,32(s1)
    8000621e:	8b9d                	andi	a5,a5,7
    80006220:	078e                	slli	a5,a5,0x3
    80006222:	97ba                	add	a5,a5,a4
    80006224:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006226:	00278713          	addi	a4,a5,2
    8000622a:	0712                	slli	a4,a4,0x4
    8000622c:	9726                	add	a4,a4,s1
    8000622e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006232:	e721                	bnez	a4,8000627a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006234:	0789                	addi	a5,a5,2
    80006236:	0792                	slli	a5,a5,0x4
    80006238:	97a6                	add	a5,a5,s1
    8000623a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000623c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006240:	ffffc097          	auipc	ra,0xffffc
    80006244:	e8e080e7          	jalr	-370(ra) # 800020ce <wakeup>

    disk.used_idx += 1;
    80006248:	0204d783          	lhu	a5,32(s1)
    8000624c:	2785                	addiw	a5,a5,1
    8000624e:	17c2                	slli	a5,a5,0x30
    80006250:	93c1                	srli	a5,a5,0x30
    80006252:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006256:	6898                	ld	a4,16(s1)
    80006258:	00275703          	lhu	a4,2(a4)
    8000625c:	faf71ce3          	bne	a4,a5,80006214 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006260:	0001c517          	auipc	a0,0x1c
    80006264:	bb050513          	addi	a0,a0,-1104 # 80021e10 <disk+0x128>
    80006268:	ffffb097          	auipc	ra,0xffffb
    8000626c:	a36080e7          	jalr	-1482(ra) # 80000c9e <release>
}
    80006270:	60e2                	ld	ra,24(sp)
    80006272:	6442                	ld	s0,16(sp)
    80006274:	64a2                	ld	s1,8(sp)
    80006276:	6105                	addi	sp,sp,32
    80006278:	8082                	ret
      panic("virtio_disk_intr status");
    8000627a:	00002517          	auipc	a0,0x2
    8000627e:	5ce50513          	addi	a0,a0,1486 # 80008848 <syscalls+0x3e0>
    80006282:	ffffa097          	auipc	ra,0xffffa
    80006286:	2c2080e7          	jalr	706(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
