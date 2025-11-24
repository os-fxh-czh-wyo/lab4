
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49e60613          	addi	a2,a2,1182 # ffffffffc020d4f0 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0207ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	611030ef          	jal	ffffffffc0203e72 <memset>
    dtb_init();
ffffffffc0200066:	4c2000ef          	jal	ffffffffc0200528 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	44c000ef          	jal	ffffffffc02004b6 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	e5258593          	addi	a1,a1,-430 # ffffffffc0203ec0 <etext>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e6a50513          	addi	a0,a0,-406 # ffffffffc0203ee0 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	158000ef          	jal	ffffffffc02001da <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	0c0020ef          	jal	ffffffffc0202146 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	7f0000ef          	jal	ffffffffc020087a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	7ee000ef          	jal	ffffffffc020087c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	631020ef          	jal	ffffffffc0202ec2 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	5a4030ef          	jal	ffffffffc020363a <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	3ca000ef          	jal	ffffffffc0200464 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	7d0000ef          	jal	ffffffffc020086e <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	7f0030ef          	jal	ffffffffc0203892 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	7179                	addi	sp,sp,-48
ffffffffc02000a8:	f406                	sd	ra,40(sp)
ffffffffc02000aa:	f022                	sd	s0,32(sp)
ffffffffc02000ac:	ec26                	sd	s1,24(sp)
ffffffffc02000ae:	e84a                	sd	s2,16(sp)
ffffffffc02000b0:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc02000b2:	c901                	beqz	a0,ffffffffc02000c2 <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc02000b4:	85aa                	mv	a1,a0
ffffffffc02000b6:	00004517          	auipc	a0,0x4
ffffffffc02000ba:	e3250513          	addi	a0,a0,-462 # ffffffffc0203ee8 <etext+0x28>
ffffffffc02000be:	0d6000ef          	jal	ffffffffc0200194 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000c2:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c4:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc02000c6:	00009997          	auipc	s3,0x9
ffffffffc02000ca:	f6a98993          	addi	s3,s3,-150 # ffffffffc0209030 <buf>
        c = getchar();
ffffffffc02000ce:	0fc000ef          	jal	ffffffffc02001ca <getchar>
ffffffffc02000d2:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d4:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d8:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000dc:	ff650693          	addi	a3,a0,-10
ffffffffc02000e0:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc02000e4:	02054963          	bltz	a0,ffffffffc0200116 <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e8:	02a95f63          	bge	s2,a0,ffffffffc0200126 <readline+0x80>
ffffffffc02000ec:	cf0d                	beqz	a4,ffffffffc0200126 <readline+0x80>
            cputchar(c);
ffffffffc02000ee:	0da000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i ++] = c;
ffffffffc02000f2:	009987b3          	add	a5,s3,s1
ffffffffc02000f6:	00878023          	sb	s0,0(a5)
ffffffffc02000fa:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc02000fc:	0ce000ef          	jal	ffffffffc02001ca <getchar>
ffffffffc0200100:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0200102:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200106:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc020010a:	ff650693          	addi	a3,a0,-10
ffffffffc020010e:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0200112:	fc055be3          	bgez	a0,ffffffffc02000e8 <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc0200116:	70a2                	ld	ra,40(sp)
ffffffffc0200118:	7402                	ld	s0,32(sp)
ffffffffc020011a:	64e2                	ld	s1,24(sp)
ffffffffc020011c:	6942                	ld	s2,16(sp)
ffffffffc020011e:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0200120:	4501                	li	a0,0
}
ffffffffc0200122:	6145                	addi	sp,sp,48
ffffffffc0200124:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc0200126:	eb81                	bnez	a5,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc0200128:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc020012a:	00905663          	blez	s1,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc020012e:	09a000ef          	jal	ffffffffc02001c8 <cputchar>
            i --;
ffffffffc0200132:	34fd                	addiw	s1,s1,-1
ffffffffc0200134:	bf69                	j	ffffffffc02000ce <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc0200136:	c291                	beqz	a3,ffffffffc020013a <readline+0x94>
ffffffffc0200138:	fa59                	bnez	a2,ffffffffc02000ce <readline+0x28>
            cputchar(c);
ffffffffc020013a:	8522                	mv	a0,s0
ffffffffc020013c:	08c000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i] = '\0';
ffffffffc0200140:	00009517          	auipc	a0,0x9
ffffffffc0200144:	ef050513          	addi	a0,a0,-272 # ffffffffc0209030 <buf>
ffffffffc0200148:	94aa                	add	s1,s1,a0
ffffffffc020014a:	00048023          	sb	zero,0(s1)
}
ffffffffc020014e:	70a2                	ld	ra,40(sp)
ffffffffc0200150:	7402                	ld	s0,32(sp)
ffffffffc0200152:	64e2                	ld	s1,24(sp)
ffffffffc0200154:	6942                	ld	s2,16(sp)
ffffffffc0200156:	69a2                	ld	s3,8(sp)
ffffffffc0200158:	6145                	addi	sp,sp,48
ffffffffc020015a:	8082                	ret

ffffffffc020015c <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015c:	1101                	addi	sp,sp,-32
ffffffffc020015e:	ec06                	sd	ra,24(sp)
ffffffffc0200160:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200162:	356000ef          	jal	ffffffffc02004b8 <cons_putc>
    (*cnt)++;
ffffffffc0200166:	65a2                	ld	a1,8(sp)
}
ffffffffc0200168:	60e2                	ld	ra,24(sp)
    (*cnt)++;
ffffffffc020016a:	419c                	lw	a5,0(a1)
ffffffffc020016c:	2785                	addiw	a5,a5,1
ffffffffc020016e:	c19c                	sw	a5,0(a1)
}
ffffffffc0200170:	6105                	addi	sp,sp,32
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe250513          	addi	a0,a0,-30 # ffffffffc020015c <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	0d1030ef          	jal	ffffffffc0203a58 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40
{
ffffffffc020019a:	f42e                	sd	a1,40(sp)
ffffffffc020019c:	f832                	sd	a2,48(sp)
ffffffffc020019e:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a0:	862a                	mv	a2,a0
ffffffffc02001a2:	004c                	addi	a1,sp,4
ffffffffc02001a4:	00000517          	auipc	a0,0x0
ffffffffc02001a8:	fb850513          	addi	a0,a0,-72 # ffffffffc020015c <cputch>
ffffffffc02001ac:	869a                	mv	a3,t1
{
ffffffffc02001ae:	ec06                	sd	ra,24(sp)
ffffffffc02001b0:	e0ba                	sd	a4,64(sp)
ffffffffc02001b2:	e4be                	sd	a5,72(sp)
ffffffffc02001b4:	e8c2                	sd	a6,80(sp)
ffffffffc02001b6:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02001b8:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001bc:	09d030ef          	jal	ffffffffc0203a58 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c0:	60e2                	ld	ra,24(sp)
ffffffffc02001c2:	4512                	lw	a0,4(sp)
ffffffffc02001c4:	6125                	addi	sp,sp,96
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001c8:	acc5                	j	ffffffffc02004b8 <cons_putc>

ffffffffc02001ca <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001ca:	1141                	addi	sp,sp,-16
ffffffffc02001cc:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001ce:	31e000ef          	jal	ffffffffc02004ec <cons_getc>
ffffffffc02001d2:	dd75                	beqz	a0,ffffffffc02001ce <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d4:	60a2                	ld	ra,8(sp)
ffffffffc02001d6:	0141                	addi	sp,sp,16
ffffffffc02001d8:	8082                	ret

ffffffffc02001da <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001da:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001dc:	00004517          	auipc	a0,0x4
ffffffffc02001e0:	d1450513          	addi	a0,a0,-748 # ffffffffc0203ef0 <etext+0x30>
{
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e6:	fafff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ea:	00000597          	auipc	a1,0x0
ffffffffc02001ee:	e6058593          	addi	a1,a1,-416 # ffffffffc020004a <kern_init>
ffffffffc02001f2:	00004517          	auipc	a0,0x4
ffffffffc02001f6:	d1e50513          	addi	a0,a0,-738 # ffffffffc0203f10 <etext+0x50>
ffffffffc02001fa:	f9bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02001fe:	00004597          	auipc	a1,0x4
ffffffffc0200202:	cc258593          	addi	a1,a1,-830 # ffffffffc0203ec0 <etext>
ffffffffc0200206:	00004517          	auipc	a0,0x4
ffffffffc020020a:	d2a50513          	addi	a0,a0,-726 # ffffffffc0203f30 <etext+0x70>
ffffffffc020020e:	f87ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200212:	00009597          	auipc	a1,0x9
ffffffffc0200216:	e1e58593          	addi	a1,a1,-482 # ffffffffc0209030 <buf>
ffffffffc020021a:	00004517          	auipc	a0,0x4
ffffffffc020021e:	d3650513          	addi	a0,a0,-714 # ffffffffc0203f50 <etext+0x90>
ffffffffc0200222:	f73ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200226:	0000d597          	auipc	a1,0xd
ffffffffc020022a:	2ca58593          	addi	a1,a1,714 # ffffffffc020d4f0 <end>
ffffffffc020022e:	00004517          	auipc	a0,0x4
ffffffffc0200232:	d4250513          	addi	a0,a0,-702 # ffffffffc0203f70 <etext+0xb0>
ffffffffc0200236:	f5fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023a:	00000717          	auipc	a4,0x0
ffffffffc020023e:	e1070713          	addi	a4,a4,-496 # ffffffffc020004a <kern_init>
ffffffffc0200242:	0000d797          	auipc	a5,0xd
ffffffffc0200246:	6ad78793          	addi	a5,a5,1709 # ffffffffc020d8ef <end+0x3ff>
ffffffffc020024a:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020024c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200250:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200252:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200256:	95be                	add	a1,a1,a5
ffffffffc0200258:	85a9                	srai	a1,a1,0xa
ffffffffc020025a:	00004517          	auipc	a0,0x4
ffffffffc020025e:	d3650513          	addi	a0,a0,-714 # ffffffffc0203f90 <etext+0xd0>
}
ffffffffc0200262:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200264:	bf05                	j	ffffffffc0200194 <cprintf>

ffffffffc0200266 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc0200266:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200268:	00004617          	auipc	a2,0x4
ffffffffc020026c:	d5860613          	addi	a2,a2,-680 # ffffffffc0203fc0 <etext+0x100>
ffffffffc0200270:	04900593          	li	a1,73
ffffffffc0200274:	00004517          	auipc	a0,0x4
ffffffffc0200278:	d6450513          	addi	a0,a0,-668 # ffffffffc0203fd8 <etext+0x118>
{
ffffffffc020027c:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020027e:	188000ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0200282 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200282:	1101                	addi	sp,sp,-32
ffffffffc0200284:	e822                	sd	s0,16(sp)
ffffffffc0200286:	e426                	sd	s1,8(sp)
ffffffffc0200288:	ec06                	sd	ra,24(sp)
ffffffffc020028a:	00005417          	auipc	s0,0x5
ffffffffc020028e:	50640413          	addi	s0,s0,1286 # ffffffffc0205790 <commands>
ffffffffc0200292:	00005497          	auipc	s1,0x5
ffffffffc0200296:	54648493          	addi	s1,s1,1350 # ffffffffc02057d8 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020029a:	6410                	ld	a2,8(s0)
ffffffffc020029c:	600c                	ld	a1,0(s0)
ffffffffc020029e:	00004517          	auipc	a0,0x4
ffffffffc02002a2:	d5250513          	addi	a0,a0,-686 # ffffffffc0203ff0 <etext+0x130>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002a6:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a8:	eedff0ef          	jal	ffffffffc0200194 <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ac:	fe9417e3          	bne	s0,s1,ffffffffc020029a <mon_help+0x18>
    }
    return 0;
}
ffffffffc02002b0:	60e2                	ld	ra,24(sp)
ffffffffc02002b2:	6442                	ld	s0,16(sp)
ffffffffc02002b4:	64a2                	ld	s1,8(sp)
ffffffffc02002b6:	4501                	li	a0,0
ffffffffc02002b8:	6105                	addi	sp,sp,32
ffffffffc02002ba:	8082                	ret

ffffffffc02002bc <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002bc:	1141                	addi	sp,sp,-16
ffffffffc02002be:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002c0:	f1bff0ef          	jal	ffffffffc02001da <print_kerninfo>
    return 0;
}
ffffffffc02002c4:	60a2                	ld	ra,8(sp)
ffffffffc02002c6:	4501                	li	a0,0
ffffffffc02002c8:	0141                	addi	sp,sp,16
ffffffffc02002ca:	8082                	ret

ffffffffc02002cc <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002cc:	1141                	addi	sp,sp,-16
ffffffffc02002ce:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002d0:	f97ff0ef          	jal	ffffffffc0200266 <print_stackframe>
    return 0;
}
ffffffffc02002d4:	60a2                	ld	ra,8(sp)
ffffffffc02002d6:	4501                	li	a0,0
ffffffffc02002d8:	0141                	addi	sp,sp,16
ffffffffc02002da:	8082                	ret

ffffffffc02002dc <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002dc:	7131                	addi	sp,sp,-192
ffffffffc02002de:	e952                	sd	s4,144(sp)
ffffffffc02002e0:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002e2:	00004517          	auipc	a0,0x4
ffffffffc02002e6:	d1e50513          	addi	a0,a0,-738 # ffffffffc0204000 <etext+0x140>
kmonitor(struct trapframe *tf) {
ffffffffc02002ea:	fd06                	sd	ra,184(sp)
ffffffffc02002ec:	f922                	sd	s0,176(sp)
ffffffffc02002ee:	f526                	sd	s1,168(sp)
ffffffffc02002f0:	f14a                	sd	s2,160(sp)
ffffffffc02002f2:	e556                	sd	s5,136(sp)
ffffffffc02002f4:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002f6:	e9fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002fa:	00004517          	auipc	a0,0x4
ffffffffc02002fe:	d2e50513          	addi	a0,a0,-722 # ffffffffc0204028 <etext+0x168>
ffffffffc0200302:	e93ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc0200306:	000a0563          	beqz	s4,ffffffffc0200310 <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc020030a:	8552                	mv	a0,s4
ffffffffc020030c:	758000ef          	jal	ffffffffc0200a64 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200310:	4501                	li	a0,0
ffffffffc0200312:	4581                	li	a1,0
ffffffffc0200314:	4601                	li	a2,0
ffffffffc0200316:	48a1                	li	a7,8
ffffffffc0200318:	00000073          	ecall
ffffffffc020031c:	00005a97          	auipc	s5,0x5
ffffffffc0200320:	474a8a93          	addi	s5,s5,1140 # ffffffffc0205790 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc0200324:	493d                	li	s2,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200326:	00004517          	auipc	a0,0x4
ffffffffc020032a:	d2a50513          	addi	a0,a0,-726 # ffffffffc0204050 <etext+0x190>
ffffffffc020032e:	d79ff0ef          	jal	ffffffffc02000a6 <readline>
ffffffffc0200332:	842a                	mv	s0,a0
ffffffffc0200334:	d96d                	beqz	a0,ffffffffc0200326 <kmonitor+0x4a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200336:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020033a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020033c:	e99d                	bnez	a1,ffffffffc0200372 <kmonitor+0x96>
    int argc = 0;
ffffffffc020033e:	8b26                	mv	s6,s1
    if (argc == 0) {
ffffffffc0200340:	fe0b03e3          	beqz	s6,ffffffffc0200326 <kmonitor+0x4a>
ffffffffc0200344:	00005497          	auipc	s1,0x5
ffffffffc0200348:	44c48493          	addi	s1,s1,1100 # ffffffffc0205790 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020034e:	6582                	ld	a1,0(sp)
ffffffffc0200350:	6088                	ld	a0,0(s1)
ffffffffc0200352:	2b3030ef          	jal	ffffffffc0203e04 <strcmp>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200356:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200358:	c149                	beqz	a0,ffffffffc02003da <kmonitor+0xfe>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020035a:	2405                	addiw	s0,s0,1
ffffffffc020035c:	04e1                	addi	s1,s1,24
ffffffffc020035e:	fef418e3          	bne	s0,a5,ffffffffc020034e <kmonitor+0x72>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200362:	6582                	ld	a1,0(sp)
ffffffffc0200364:	00004517          	auipc	a0,0x4
ffffffffc0200368:	d1c50513          	addi	a0,a0,-740 # ffffffffc0204080 <etext+0x1c0>
ffffffffc020036c:	e29ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200370:	bf5d                	j	ffffffffc0200326 <kmonitor+0x4a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200372:	00004517          	auipc	a0,0x4
ffffffffc0200376:	ce650513          	addi	a0,a0,-794 # ffffffffc0204058 <etext+0x198>
ffffffffc020037a:	2e7030ef          	jal	ffffffffc0203e60 <strchr>
ffffffffc020037e:	c901                	beqz	a0,ffffffffc020038e <kmonitor+0xb2>
ffffffffc0200380:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200384:	00040023          	sb	zero,0(s0)
ffffffffc0200388:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	d9d5                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc020038c:	b7dd                	j	ffffffffc0200372 <kmonitor+0x96>
        if (*buf == '\0') {
ffffffffc020038e:	00044783          	lbu	a5,0(s0)
ffffffffc0200392:	d7d5                	beqz	a5,ffffffffc020033e <kmonitor+0x62>
        if (argc == MAXARGS - 1) {
ffffffffc0200394:	03248b63          	beq	s1,s2,ffffffffc02003ca <kmonitor+0xee>
        argv[argc ++] = buf;
ffffffffc0200398:	00349793          	slli	a5,s1,0x3
ffffffffc020039c:	978a                	add	a5,a5,sp
ffffffffc020039e:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a0:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003a4:	2485                	addiw	s1,s1,1
ffffffffc02003a6:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a8:	e591                	bnez	a1,ffffffffc02003b4 <kmonitor+0xd8>
ffffffffc02003aa:	bf59                	j	ffffffffc0200340 <kmonitor+0x64>
ffffffffc02003ac:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003b0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003b2:	d5d1                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc02003b4:	00004517          	auipc	a0,0x4
ffffffffc02003b8:	ca450513          	addi	a0,a0,-860 # ffffffffc0204058 <etext+0x198>
ffffffffc02003bc:	2a5030ef          	jal	ffffffffc0203e60 <strchr>
ffffffffc02003c0:	d575                	beqz	a0,ffffffffc02003ac <kmonitor+0xd0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c2:	00044583          	lbu	a1,0(s0)
ffffffffc02003c6:	dda5                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc02003c8:	b76d                	j	ffffffffc0200372 <kmonitor+0x96>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003ca:	45c1                	li	a1,16
ffffffffc02003cc:	00004517          	auipc	a0,0x4
ffffffffc02003d0:	c9450513          	addi	a0,a0,-876 # ffffffffc0204060 <etext+0x1a0>
ffffffffc02003d4:	dc1ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc02003d8:	b7c1                	j	ffffffffc0200398 <kmonitor+0xbc>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003da:	00141793          	slli	a5,s0,0x1
ffffffffc02003de:	97a2                	add	a5,a5,s0
ffffffffc02003e0:	078e                	slli	a5,a5,0x3
ffffffffc02003e2:	97d6                	add	a5,a5,s5
ffffffffc02003e4:	6b9c                	ld	a5,16(a5)
ffffffffc02003e6:	fffb051b          	addiw	a0,s6,-1
ffffffffc02003ea:	8652                	mv	a2,s4
ffffffffc02003ec:	002c                	addi	a1,sp,8
ffffffffc02003ee:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003f0:	f2055be3          	bgez	a0,ffffffffc0200326 <kmonitor+0x4a>
}
ffffffffc02003f4:	70ea                	ld	ra,184(sp)
ffffffffc02003f6:	744a                	ld	s0,176(sp)
ffffffffc02003f8:	74aa                	ld	s1,168(sp)
ffffffffc02003fa:	790a                	ld	s2,160(sp)
ffffffffc02003fc:	6a4a                	ld	s4,144(sp)
ffffffffc02003fe:	6aaa                	ld	s5,136(sp)
ffffffffc0200400:	6b0a                	ld	s6,128(sp)
ffffffffc0200402:	6129                	addi	sp,sp,192
ffffffffc0200404:	8082                	ret

ffffffffc0200406 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200406:	0000d317          	auipc	t1,0xd
ffffffffc020040a:	06232303          	lw	t1,98(t1) # ffffffffc020d468 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020040e:	715d                	addi	sp,sp,-80
ffffffffc0200410:	ec06                	sd	ra,24(sp)
ffffffffc0200412:	f436                	sd	a3,40(sp)
ffffffffc0200414:	f83a                	sd	a4,48(sp)
ffffffffc0200416:	fc3e                	sd	a5,56(sp)
ffffffffc0200418:	e0c2                	sd	a6,64(sp)
ffffffffc020041a:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020041c:	02031e63          	bnez	t1,ffffffffc0200458 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200420:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200422:	103c                	addi	a5,sp,40
ffffffffc0200424:	e822                	sd	s0,16(sp)
ffffffffc0200426:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200428:	862e                	mv	a2,a1
ffffffffc020042a:	85aa                	mv	a1,a0
ffffffffc020042c:	00004517          	auipc	a0,0x4
ffffffffc0200430:	cfc50513          	addi	a0,a0,-772 # ffffffffc0204128 <etext+0x268>
    is_panic = 1;
ffffffffc0200434:	0000d697          	auipc	a3,0xd
ffffffffc0200438:	02e6aa23          	sw	a4,52(a3) # ffffffffc020d468 <is_panic>
    va_start(ap, fmt);
ffffffffc020043c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020043e:	d57ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200442:	65a2                	ld	a1,8(sp)
ffffffffc0200444:	8522                	mv	a0,s0
ffffffffc0200446:	d2fff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020044a:	00004517          	auipc	a0,0x4
ffffffffc020044e:	cfe50513          	addi	a0,a0,-770 # ffffffffc0204148 <etext+0x288>
ffffffffc0200452:	d43ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200456:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200458:	41c000ef          	jal	ffffffffc0200874 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020045c:	4501                	li	a0,0
ffffffffc020045e:	e7fff0ef          	jal	ffffffffc02002dc <kmonitor>
    while (1) {
ffffffffc0200462:	bfed                	j	ffffffffc020045c <__panic+0x56>

ffffffffc0200464 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046a:	0000d717          	auipc	a4,0xd
ffffffffc020046e:	00f73323          	sd	a5,6(a4) # ffffffffc020d470 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200472:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200476:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200478:	953e                	add	a0,a0,a5
ffffffffc020047a:	4601                	li	a2,0
ffffffffc020047c:	4881                	li	a7,0
ffffffffc020047e:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200482:	02000793          	li	a5,32
ffffffffc0200486:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020048a:	00004517          	auipc	a0,0x4
ffffffffc020048e:	cc650513          	addi	a0,a0,-826 # ffffffffc0204150 <etext+0x290>
    ticks = 0;
ffffffffc0200492:	0000d797          	auipc	a5,0xd
ffffffffc0200496:	fe07b323          	sd	zero,-26(a5) # ffffffffc020d478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020049a:	b9ed                	j	ffffffffc0200194 <cprintf>

ffffffffc020049c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020049c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004a0:	0000d797          	auipc	a5,0xd
ffffffffc02004a4:	fd07b783          	ld	a5,-48(a5) # ffffffffc020d470 <timebase>
ffffffffc02004a8:	4581                	li	a1,0
ffffffffc02004aa:	4601                	li	a2,0
ffffffffc02004ac:	953e                	add	a0,a0,a5
ffffffffc02004ae:	4881                	li	a7,0
ffffffffc02004b0:	00000073          	ecall
ffffffffc02004b4:	8082                	ret

ffffffffc02004b6 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004b6:	8082                	ret

ffffffffc02004b8 <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004b8:	100027f3          	csrr	a5,sstatus
ffffffffc02004bc:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02004be:	0ff57513          	zext.b	a0,a0
ffffffffc02004c2:	e799                	bnez	a5,ffffffffc02004d0 <cons_putc+0x18>
ffffffffc02004c4:	4581                	li	a1,0
ffffffffc02004c6:	4601                	li	a2,0
ffffffffc02004c8:	4885                	li	a7,1
ffffffffc02004ca:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02004ce:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02004d0:	1101                	addi	sp,sp,-32
ffffffffc02004d2:	ec06                	sd	ra,24(sp)
ffffffffc02004d4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02004d6:	39e000ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02004da:	6522                	ld	a0,8(sp)
ffffffffc02004dc:	4581                	li	a1,0
ffffffffc02004de:	4601                	li	a2,0
ffffffffc02004e0:	4885                	li	a7,1
ffffffffc02004e2:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02004e6:	60e2                	ld	ra,24(sp)
ffffffffc02004e8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02004ea:	a651                	j	ffffffffc020086e <intr_enable>

ffffffffc02004ec <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004ec:	100027f3          	csrr	a5,sstatus
ffffffffc02004f0:	8b89                	andi	a5,a5,2
ffffffffc02004f2:	eb89                	bnez	a5,ffffffffc0200504 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02004f4:	4501                	li	a0,0
ffffffffc02004f6:	4581                	li	a1,0
ffffffffc02004f8:	4601                	li	a2,0
ffffffffc02004fa:	4889                	li	a7,2
ffffffffc02004fc:	00000073          	ecall
ffffffffc0200500:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200502:	8082                	ret
int cons_getc(void) {
ffffffffc0200504:	1101                	addi	sp,sp,-32
ffffffffc0200506:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200508:	36c000ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc020050c:	4501                	li	a0,0
ffffffffc020050e:	4581                	li	a1,0
ffffffffc0200510:	4601                	li	a2,0
ffffffffc0200512:	4889                	li	a7,2
ffffffffc0200514:	00000073          	ecall
ffffffffc0200518:	2501                	sext.w	a0,a0
ffffffffc020051a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020051c:	352000ef          	jal	ffffffffc020086e <intr_enable>
}
ffffffffc0200520:	60e2                	ld	ra,24(sp)
ffffffffc0200522:	6522                	ld	a0,8(sp)
ffffffffc0200524:	6105                	addi	sp,sp,32
ffffffffc0200526:	8082                	ret

ffffffffc0200528 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200528:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020052a:	00004517          	auipc	a0,0x4
ffffffffc020052e:	c4650513          	addi	a0,a0,-954 # ffffffffc0204170 <etext+0x2b0>
void dtb_init(void) {
ffffffffc0200532:	f406                	sd	ra,40(sp)
ffffffffc0200534:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200536:	c5fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020053a:	00009597          	auipc	a1,0x9
ffffffffc020053e:	ac65b583          	ld	a1,-1338(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc0200542:	00004517          	auipc	a0,0x4
ffffffffc0200546:	c3e50513          	addi	a0,a0,-962 # ffffffffc0204180 <etext+0x2c0>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020054a:	00009417          	auipc	s0,0x9
ffffffffc020054e:	abe40413          	addi	s0,s0,-1346 # ffffffffc0209008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200552:	c43ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200556:	600c                	ld	a1,0(s0)
ffffffffc0200558:	00004517          	auipc	a0,0x4
ffffffffc020055c:	c3850513          	addi	a0,a0,-968 # ffffffffc0204190 <etext+0x2d0>
ffffffffc0200560:	c35ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200564:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200566:	00004517          	auipc	a0,0x4
ffffffffc020056a:	c4250513          	addi	a0,a0,-958 # ffffffffc02041a8 <etext+0x2e8>
    if (boot_dtb == 0) {
ffffffffc020056e:	10070163          	beqz	a4,ffffffffc0200670 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200572:	57f5                	li	a5,-3
ffffffffc0200574:	07fa                	slli	a5,a5,0x1e
ffffffffc0200576:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200578:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020057a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020057e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed29fd>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200582:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200586:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200592:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200596:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200598:	8e49                	or	a2,a2,a0
ffffffffc020059a:	0ff7f793          	zext.b	a5,a5
ffffffffc020059e:	8dd1                	or	a1,a1,a2
ffffffffc02005a0:	07a2                	slli	a5,a5,0x8
ffffffffc02005a2:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a4:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02005a8:	0cd59863          	bne	a1,a3,ffffffffc0200678 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02005ac:	4710                	lw	a2,8(a4)
ffffffffc02005ae:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b0:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02005b6:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02005be:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02005c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02005ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ce:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005d2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02005da:	01c56533          	or	a0,a0,t3
ffffffffc02005de:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e2:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005e6:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ea:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02005f2:	8c49                	or	s0,s0,a0
ffffffffc02005f4:	0622                	slli	a2,a2,0x8
ffffffffc02005f6:	8fcd                	or	a5,a5,a1
ffffffffc02005f8:	06a2                	slli	a3,a3,0x8
ffffffffc02005fa:	8c51                	or	s0,s0,a2
ffffffffc02005fc:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005fe:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200600:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200602:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200604:	9381                	srli	a5,a5,0x20
ffffffffc0200606:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200608:	4301                	li	t1,0
        switch (token) {
ffffffffc020060a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020060c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020060e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200612:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200614:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200616:	0087579b          	srliw	a5,a4,0x8
ffffffffc020061a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200622:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200626:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020062a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020062e:	8ed1                	or	a3,a3,a2
ffffffffc0200630:	0ff77713          	zext.b	a4,a4
ffffffffc0200634:	8fd5                	or	a5,a5,a3
ffffffffc0200636:	0722                	slli	a4,a4,0x8
ffffffffc0200638:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020063a:	05178763          	beq	a5,a7,ffffffffc0200688 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020063e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200640:	00f8e963          	bltu	a7,a5,ffffffffc0200652 <dtb_init+0x12a>
ffffffffc0200644:	07c78d63          	beq	a5,t3,ffffffffc02006be <dtb_init+0x196>
ffffffffc0200648:	4709                	li	a4,2
ffffffffc020064a:	00e79763          	bne	a5,a4,ffffffffc0200658 <dtb_init+0x130>
ffffffffc020064e:	4301                	li	t1,0
ffffffffc0200650:	b7d1                	j	ffffffffc0200614 <dtb_init+0xec>
ffffffffc0200652:	4711                	li	a4,4
ffffffffc0200654:	fce780e3          	beq	a5,a4,ffffffffc0200614 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200658:	00004517          	auipc	a0,0x4
ffffffffc020065c:	c1850513          	addi	a0,a0,-1000 # ffffffffc0204270 <etext+0x3b0>
ffffffffc0200660:	b35ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200664:	64e2                	ld	s1,24(sp)
ffffffffc0200666:	6942                	ld	s2,16(sp)
ffffffffc0200668:	00004517          	auipc	a0,0x4
ffffffffc020066c:	c4050513          	addi	a0,a0,-960 # ffffffffc02042a8 <etext+0x3e8>
}
ffffffffc0200670:	7402                	ld	s0,32(sp)
ffffffffc0200672:	70a2                	ld	ra,40(sp)
ffffffffc0200674:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200676:	be39                	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200678:	7402                	ld	s0,32(sp)
ffffffffc020067a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020067c:	00004517          	auipc	a0,0x4
ffffffffc0200680:	b4c50513          	addi	a0,a0,-1204 # ffffffffc02041c8 <etext+0x308>
}
ffffffffc0200684:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200686:	b639                	j	ffffffffc0200194 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200688:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020068e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200692:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200696:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a2:	8ed1                	or	a3,a3,a2
ffffffffc02006a4:	0ff77713          	zext.b	a4,a4
ffffffffc02006a8:	8fd5                	or	a5,a5,a3
ffffffffc02006aa:	0722                	slli	a4,a4,0x8
ffffffffc02006ac:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ae:	04031463          	bnez	t1,ffffffffc02006f6 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006b2:	1782                	slli	a5,a5,0x20
ffffffffc02006b4:	9381                	srli	a5,a5,0x20
ffffffffc02006b6:	043d                	addi	s0,s0,15
ffffffffc02006b8:	943e                	add	s0,s0,a5
ffffffffc02006ba:	9871                	andi	s0,s0,-4
                break;
ffffffffc02006bc:	bfa1                	j	ffffffffc0200614 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02006be:	8522                	mv	a0,s0
ffffffffc02006c0:	e01a                	sd	t1,0(sp)
ffffffffc02006c2:	6fc030ef          	jal	ffffffffc0203dbe <strlen>
ffffffffc02006c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006c8:	4619                	li	a2,6
ffffffffc02006ca:	8522                	mv	a0,s0
ffffffffc02006cc:	00004597          	auipc	a1,0x4
ffffffffc02006d0:	b2458593          	addi	a1,a1,-1244 # ffffffffc02041f0 <etext+0x330>
ffffffffc02006d4:	764030ef          	jal	ffffffffc0203e38 <strncmp>
ffffffffc02006d8:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006da:	0411                	addi	s0,s0,4
ffffffffc02006dc:	0004879b          	sext.w	a5,s1
ffffffffc02006e0:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006e2:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006e6:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006e8:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02006ec:	00ff0837          	lui	a6,0xff0
ffffffffc02006f0:	488d                	li	a7,3
ffffffffc02006f2:	4e05                	li	t3,1
ffffffffc02006f4:	b705                	j	ffffffffc0200614 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006f6:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f8:	00004597          	auipc	a1,0x4
ffffffffc02006fc:	b0058593          	addi	a1,a1,-1280 # ffffffffc02041f8 <etext+0x338>
ffffffffc0200700:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200706:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020070e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200712:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200716:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071a:	8ed1                	or	a3,a3,a2
ffffffffc020071c:	0ff77713          	zext.b	a4,a4
ffffffffc0200720:	0722                	slli	a4,a4,0x8
ffffffffc0200722:	8d55                	or	a0,a0,a3
ffffffffc0200724:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200726:	1502                	slli	a0,a0,0x20
ffffffffc0200728:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020072a:	954a                	add	a0,a0,s2
ffffffffc020072c:	e01a                	sd	t1,0(sp)
ffffffffc020072e:	6d6030ef          	jal	ffffffffc0203e04 <strcmp>
ffffffffc0200732:	67a2                	ld	a5,8(sp)
ffffffffc0200734:	473d                	li	a4,15
ffffffffc0200736:	6302                	ld	t1,0(sp)
ffffffffc0200738:	00ff0837          	lui	a6,0xff0
ffffffffc020073c:	488d                	li	a7,3
ffffffffc020073e:	4e05                	li	t3,1
ffffffffc0200740:	f6f779e3          	bgeu	a4,a5,ffffffffc02006b2 <dtb_init+0x18a>
ffffffffc0200744:	f53d                	bnez	a0,ffffffffc02006b2 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200746:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020074a:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020074e:	00004517          	auipc	a0,0x4
ffffffffc0200752:	ab250513          	addi	a0,a0,-1358 # ffffffffc0204200 <etext+0x340>
           fdt32_to_cpu(x >> 32);
ffffffffc0200756:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020075a:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020075e:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200762:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200766:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076a:	0187959b          	slliw	a1,a5,0x18
ffffffffc020076e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200772:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200776:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020077a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077e:	01037333          	and	t1,t1,a6
ffffffffc0200782:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200786:	01e5e5b3          	or	a1,a1,t5
ffffffffc020078a:	0ff7f793          	zext.b	a5,a5
ffffffffc020078e:	01de6e33          	or	t3,t3,t4
ffffffffc0200792:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200796:	01067633          	and	a2,a2,a6
ffffffffc020079a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020079e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	07a2                	slli	a5,a5,0x8
ffffffffc02007a4:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02007a8:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02007ac:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02007b0:	8ddd                	or	a1,a1,a5
ffffffffc02007b2:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007b6:	0186979b          	slliw	a5,a3,0x18
ffffffffc02007ba:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007be:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ce:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d2:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d6:	08a2                	slli	a7,a7,0x8
ffffffffc02007d8:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007dc:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007e0:	0ff6f693          	zext.b	a3,a3
ffffffffc02007e4:	01de6833          	or	a6,t3,t4
ffffffffc02007e8:	0ff77713          	zext.b	a4,a4
ffffffffc02007ec:	01166633          	or	a2,a2,a7
ffffffffc02007f0:	0067e7b3          	or	a5,a5,t1
ffffffffc02007f4:	06a2                	slli	a3,a3,0x8
ffffffffc02007f6:	01046433          	or	s0,s0,a6
ffffffffc02007fa:	0722                	slli	a4,a4,0x8
ffffffffc02007fc:	8fd5                	or	a5,a5,a3
ffffffffc02007fe:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200800:	1582                	slli	a1,a1,0x20
ffffffffc0200802:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200804:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200806:	9201                	srli	a2,a2,0x20
ffffffffc0200808:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020080a:	1402                	slli	s0,s0,0x20
ffffffffc020080c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200810:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200812:	983ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200816:	85a6                	mv	a1,s1
ffffffffc0200818:	00004517          	auipc	a0,0x4
ffffffffc020081c:	a0850513          	addi	a0,a0,-1528 # ffffffffc0204220 <etext+0x360>
ffffffffc0200820:	975ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200824:	01445613          	srli	a2,s0,0x14
ffffffffc0200828:	85a2                	mv	a1,s0
ffffffffc020082a:	00004517          	auipc	a0,0x4
ffffffffc020082e:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0204238 <etext+0x378>
ffffffffc0200832:	963ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200836:	009405b3          	add	a1,s0,s1
ffffffffc020083a:	15fd                	addi	a1,a1,-1
ffffffffc020083c:	00004517          	auipc	a0,0x4
ffffffffc0200840:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0204258 <etext+0x398>
ffffffffc0200844:	951ff0ef          	jal	ffffffffc0200194 <cprintf>
        memory_base = mem_base;
ffffffffc0200848:	0000d797          	auipc	a5,0xd
ffffffffc020084c:	c497b023          	sd	s1,-960(a5) # ffffffffc020d488 <memory_base>
        memory_size = mem_size;
ffffffffc0200850:	0000d797          	auipc	a5,0xd
ffffffffc0200854:	c287b823          	sd	s0,-976(a5) # ffffffffc020d480 <memory_size>
ffffffffc0200858:	b531                	j	ffffffffc0200664 <dtb_init+0x13c>

ffffffffc020085a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020085a:	0000d517          	auipc	a0,0xd
ffffffffc020085e:	c2e53503          	ld	a0,-978(a0) # ffffffffc020d488 <memory_base>
ffffffffc0200862:	8082                	ret

ffffffffc0200864 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200864:	0000d517          	auipc	a0,0xd
ffffffffc0200868:	c1c53503          	ld	a0,-996(a0) # ffffffffc020d480 <memory_size>
ffffffffc020086c:	8082                	ret

ffffffffc020086e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020086e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200872:	8082                	ret

ffffffffc0200874 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200874:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200878:	8082                	ret

ffffffffc020087a <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020087a:	8082                	ret

ffffffffc020087c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020087c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200880:	00000797          	auipc	a5,0x0
ffffffffc0200884:	3ec78793          	addi	a5,a5,1004 # ffffffffc0200c6c <__alltraps>
ffffffffc0200888:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020088c:	000407b7          	lui	a5,0x40
ffffffffc0200890:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200894:	8082                	ret

ffffffffc0200896 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200896:	610c                	ld	a1,0(a0)
{
ffffffffc0200898:	1141                	addi	sp,sp,-16
ffffffffc020089a:	e022                	sd	s0,0(sp)
ffffffffc020089c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020089e:	00004517          	auipc	a0,0x4
ffffffffc02008a2:	a2250513          	addi	a0,a0,-1502 # ffffffffc02042c0 <etext+0x400>
{
ffffffffc02008a6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02008a8:	8edff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02008ac:	640c                	ld	a1,8(s0)
ffffffffc02008ae:	00004517          	auipc	a0,0x4
ffffffffc02008b2:	a2a50513          	addi	a0,a0,-1494 # ffffffffc02042d8 <etext+0x418>
ffffffffc02008b6:	8dfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02008ba:	680c                	ld	a1,16(s0)
ffffffffc02008bc:	00004517          	auipc	a0,0x4
ffffffffc02008c0:	a3450513          	addi	a0,a0,-1484 # ffffffffc02042f0 <etext+0x430>
ffffffffc02008c4:	8d1ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02008c8:	6c0c                	ld	a1,24(s0)
ffffffffc02008ca:	00004517          	auipc	a0,0x4
ffffffffc02008ce:	a3e50513          	addi	a0,a0,-1474 # ffffffffc0204308 <etext+0x448>
ffffffffc02008d2:	8c3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02008d6:	700c                	ld	a1,32(s0)
ffffffffc02008d8:	00004517          	auipc	a0,0x4
ffffffffc02008dc:	a4850513          	addi	a0,a0,-1464 # ffffffffc0204320 <etext+0x460>
ffffffffc02008e0:	8b5ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008e4:	740c                	ld	a1,40(s0)
ffffffffc02008e6:	00004517          	auipc	a0,0x4
ffffffffc02008ea:	a5250513          	addi	a0,a0,-1454 # ffffffffc0204338 <etext+0x478>
ffffffffc02008ee:	8a7ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008f2:	780c                	ld	a1,48(s0)
ffffffffc02008f4:	00004517          	auipc	a0,0x4
ffffffffc02008f8:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0204350 <etext+0x490>
ffffffffc02008fc:	899ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200900:	7c0c                	ld	a1,56(s0)
ffffffffc0200902:	00004517          	auipc	a0,0x4
ffffffffc0200906:	a6650513          	addi	a0,a0,-1434 # ffffffffc0204368 <etext+0x4a8>
ffffffffc020090a:	88bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020090e:	602c                	ld	a1,64(s0)
ffffffffc0200910:	00004517          	auipc	a0,0x4
ffffffffc0200914:	a7050513          	addi	a0,a0,-1424 # ffffffffc0204380 <etext+0x4c0>
ffffffffc0200918:	87dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc020091c:	642c                	ld	a1,72(s0)
ffffffffc020091e:	00004517          	auipc	a0,0x4
ffffffffc0200922:	a7a50513          	addi	a0,a0,-1414 # ffffffffc0204398 <etext+0x4d8>
ffffffffc0200926:	86fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020092a:	682c                	ld	a1,80(s0)
ffffffffc020092c:	00004517          	auipc	a0,0x4
ffffffffc0200930:	a8450513          	addi	a0,a0,-1404 # ffffffffc02043b0 <etext+0x4f0>
ffffffffc0200934:	861ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200938:	6c2c                	ld	a1,88(s0)
ffffffffc020093a:	00004517          	auipc	a0,0x4
ffffffffc020093e:	a8e50513          	addi	a0,a0,-1394 # ffffffffc02043c8 <etext+0x508>
ffffffffc0200942:	853ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200946:	702c                	ld	a1,96(s0)
ffffffffc0200948:	00004517          	auipc	a0,0x4
ffffffffc020094c:	a9850513          	addi	a0,a0,-1384 # ffffffffc02043e0 <etext+0x520>
ffffffffc0200950:	845ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200954:	742c                	ld	a1,104(s0)
ffffffffc0200956:	00004517          	auipc	a0,0x4
ffffffffc020095a:	aa250513          	addi	a0,a0,-1374 # ffffffffc02043f8 <etext+0x538>
ffffffffc020095e:	837ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200962:	782c                	ld	a1,112(s0)
ffffffffc0200964:	00004517          	auipc	a0,0x4
ffffffffc0200968:	aac50513          	addi	a0,a0,-1364 # ffffffffc0204410 <etext+0x550>
ffffffffc020096c:	829ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200970:	7c2c                	ld	a1,120(s0)
ffffffffc0200972:	00004517          	auipc	a0,0x4
ffffffffc0200976:	ab650513          	addi	a0,a0,-1354 # ffffffffc0204428 <etext+0x568>
ffffffffc020097a:	81bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020097e:	604c                	ld	a1,128(s0)
ffffffffc0200980:	00004517          	auipc	a0,0x4
ffffffffc0200984:	ac050513          	addi	a0,a0,-1344 # ffffffffc0204440 <etext+0x580>
ffffffffc0200988:	80dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020098c:	644c                	ld	a1,136(s0)
ffffffffc020098e:	00004517          	auipc	a0,0x4
ffffffffc0200992:	aca50513          	addi	a0,a0,-1334 # ffffffffc0204458 <etext+0x598>
ffffffffc0200996:	ffeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020099a:	684c                	ld	a1,144(s0)
ffffffffc020099c:	00004517          	auipc	a0,0x4
ffffffffc02009a0:	ad450513          	addi	a0,a0,-1324 # ffffffffc0204470 <etext+0x5b0>
ffffffffc02009a4:	ff0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02009a8:	6c4c                	ld	a1,152(s0)
ffffffffc02009aa:	00004517          	auipc	a0,0x4
ffffffffc02009ae:	ade50513          	addi	a0,a0,-1314 # ffffffffc0204488 <etext+0x5c8>
ffffffffc02009b2:	fe2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02009b6:	704c                	ld	a1,160(s0)
ffffffffc02009b8:	00004517          	auipc	a0,0x4
ffffffffc02009bc:	ae850513          	addi	a0,a0,-1304 # ffffffffc02044a0 <etext+0x5e0>
ffffffffc02009c0:	fd4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02009c4:	744c                	ld	a1,168(s0)
ffffffffc02009c6:	00004517          	auipc	a0,0x4
ffffffffc02009ca:	af250513          	addi	a0,a0,-1294 # ffffffffc02044b8 <etext+0x5f8>
ffffffffc02009ce:	fc6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02009d2:	784c                	ld	a1,176(s0)
ffffffffc02009d4:	00004517          	auipc	a0,0x4
ffffffffc02009d8:	afc50513          	addi	a0,a0,-1284 # ffffffffc02044d0 <etext+0x610>
ffffffffc02009dc:	fb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009e0:	7c4c                	ld	a1,184(s0)
ffffffffc02009e2:	00004517          	auipc	a0,0x4
ffffffffc02009e6:	b0650513          	addi	a0,a0,-1274 # ffffffffc02044e8 <etext+0x628>
ffffffffc02009ea:	faaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009ee:	606c                	ld	a1,192(s0)
ffffffffc02009f0:	00004517          	auipc	a0,0x4
ffffffffc02009f4:	b1050513          	addi	a0,a0,-1264 # ffffffffc0204500 <etext+0x640>
ffffffffc02009f8:	f9cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009fc:	646c                	ld	a1,200(s0)
ffffffffc02009fe:	00004517          	auipc	a0,0x4
ffffffffc0200a02:	b1a50513          	addi	a0,a0,-1254 # ffffffffc0204518 <etext+0x658>
ffffffffc0200a06:	f8eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a0a:	686c                	ld	a1,208(s0)
ffffffffc0200a0c:	00004517          	auipc	a0,0x4
ffffffffc0200a10:	b2450513          	addi	a0,a0,-1244 # ffffffffc0204530 <etext+0x670>
ffffffffc0200a14:	f80ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200a18:	6c6c                	ld	a1,216(s0)
ffffffffc0200a1a:	00004517          	auipc	a0,0x4
ffffffffc0200a1e:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0204548 <etext+0x688>
ffffffffc0200a22:	f72ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200a26:	706c                	ld	a1,224(s0)
ffffffffc0200a28:	00004517          	auipc	a0,0x4
ffffffffc0200a2c:	b3850513          	addi	a0,a0,-1224 # ffffffffc0204560 <etext+0x6a0>
ffffffffc0200a30:	f64ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200a34:	746c                	ld	a1,232(s0)
ffffffffc0200a36:	00004517          	auipc	a0,0x4
ffffffffc0200a3a:	b4250513          	addi	a0,a0,-1214 # ffffffffc0204578 <etext+0x6b8>
ffffffffc0200a3e:	f56ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a42:	786c                	ld	a1,240(s0)
ffffffffc0200a44:	00004517          	auipc	a0,0x4
ffffffffc0200a48:	b4c50513          	addi	a0,a0,-1204 # ffffffffc0204590 <etext+0x6d0>
ffffffffc0200a4c:	f48ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a50:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a52:	6402                	ld	s0,0(sp)
ffffffffc0200a54:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a56:	00004517          	auipc	a0,0x4
ffffffffc0200a5a:	b5250513          	addi	a0,a0,-1198 # ffffffffc02045a8 <etext+0x6e8>
}
ffffffffc0200a5e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a60:	f34ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200a64 <print_trapframe>:
{
ffffffffc0200a64:	1141                	addi	sp,sp,-16
ffffffffc0200a66:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a68:	85aa                	mv	a1,a0
{
ffffffffc0200a6a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a6c:	00004517          	auipc	a0,0x4
ffffffffc0200a70:	b5450513          	addi	a0,a0,-1196 # ffffffffc02045c0 <etext+0x700>
{
ffffffffc0200a74:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a76:	f1eff0ef          	jal	ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a7a:	8522                	mv	a0,s0
ffffffffc0200a7c:	e1bff0ef          	jal	ffffffffc0200896 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a80:	10043583          	ld	a1,256(s0)
ffffffffc0200a84:	00004517          	auipc	a0,0x4
ffffffffc0200a88:	b5450513          	addi	a0,a0,-1196 # ffffffffc02045d8 <etext+0x718>
ffffffffc0200a8c:	f08ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a90:	10843583          	ld	a1,264(s0)
ffffffffc0200a94:	00004517          	auipc	a0,0x4
ffffffffc0200a98:	b5c50513          	addi	a0,a0,-1188 # ffffffffc02045f0 <etext+0x730>
ffffffffc0200a9c:	ef8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200aa0:	11043583          	ld	a1,272(s0)
ffffffffc0200aa4:	00004517          	auipc	a0,0x4
ffffffffc0200aa8:	b6450513          	addi	a0,a0,-1180 # ffffffffc0204608 <etext+0x748>
ffffffffc0200aac:	ee8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200ab4:	6402                	ld	s0,0(sp)
ffffffffc0200ab6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab8:	00004517          	auipc	a0,0x4
ffffffffc0200abc:	b6850513          	addi	a0,a0,-1176 # ffffffffc0204620 <etext+0x760>
}
ffffffffc0200ac0:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ac2:	ed2ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ac6 <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200ac6:	11853783          	ld	a5,280(a0)
ffffffffc0200aca:	472d                	li	a4,11
ffffffffc0200acc:	0786                	slli	a5,a5,0x1
ffffffffc0200ace:	8385                	srli	a5,a5,0x1
ffffffffc0200ad0:	08f76963          	bltu	a4,a5,ffffffffc0200b62 <interrupt_handler+0x9c>
ffffffffc0200ad4:	00005717          	auipc	a4,0x5
ffffffffc0200ad8:	d0470713          	addi	a4,a4,-764 # ffffffffc02057d8 <commands+0x48>
ffffffffc0200adc:	078a                	slli	a5,a5,0x2
ffffffffc0200ade:	97ba                	add	a5,a5,a4
ffffffffc0200ae0:	439c                	lw	a5,0(a5)
ffffffffc0200ae2:	97ba                	add	a5,a5,a4
ffffffffc0200ae4:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ae6:	00004517          	auipc	a0,0x4
ffffffffc0200aea:	bb250513          	addi	a0,a0,-1102 # ffffffffc0204698 <etext+0x7d8>
ffffffffc0200aee:	ea6ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200af2:	00004517          	auipc	a0,0x4
ffffffffc0200af6:	b8650513          	addi	a0,a0,-1146 # ffffffffc0204678 <etext+0x7b8>
ffffffffc0200afa:	e9aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200afe:	00004517          	auipc	a0,0x4
ffffffffc0200b02:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0204638 <etext+0x778>
ffffffffc0200b06:	e8eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b0a:	00004517          	auipc	a0,0x4
ffffffffc0200b0e:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0204658 <etext+0x798>
ffffffffc0200b12:	e82ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200b16:	1141                	addi	sp,sp,-16
ffffffffc0200b18:	e406                	sd	ra,8(sp)
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 请补充你在lab3中的代码 */ 
        clock_set_next_event();
ffffffffc0200b1a:	983ff0ef          	jal	ffffffffc020049c <clock_set_next_event>
        ticks++;
ffffffffc0200b1e:	0000d797          	auipc	a5,0xd
ffffffffc0200b22:	95a78793          	addi	a5,a5,-1702 # ffffffffc020d478 <ticks>
ffffffffc0200b26:	6398                	ld	a4,0(a5)
        static int num=0;
        if(ticks==TICK_NUM){
ffffffffc0200b28:	06400693          	li	a3,100
        ticks++;
ffffffffc0200b2c:	0705                	addi	a4,a4,1
ffffffffc0200b2e:	e398                	sd	a4,0(a5)
        if(ticks==TICK_NUM){
ffffffffc0200b30:	638c                	ld	a1,0(a5)
ffffffffc0200b32:	02d58963          	beq	a1,a3,ffffffffc0200b64 <interrupt_handler+0x9e>
            print_ticks();
            num++;
            ticks=0;
        }
        if(num==10){
ffffffffc0200b36:	0000d797          	auipc	a5,0xd
ffffffffc0200b3a:	95a7a783          	lw	a5,-1702(a5) # ffffffffc020d490 <num.0>
ffffffffc0200b3e:	4729                	li	a4,10
ffffffffc0200b40:	00e79863          	bne	a5,a4,ffffffffc0200b50 <interrupt_handler+0x8a>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200b44:	4501                	li	a0,0
ffffffffc0200b46:	4581                	li	a1,0
ffffffffc0200b48:	4601                	li	a2,0
ffffffffc0200b4a:	48a1                	li	a7,8
ffffffffc0200b4c:	00000073          	ecall
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200b50:	60a2                	ld	ra,8(sp)
ffffffffc0200b52:	0141                	addi	sp,sp,16
ffffffffc0200b54:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200b56:	00004517          	auipc	a0,0x4
ffffffffc0200b5a:	b7250513          	addi	a0,a0,-1166 # ffffffffc02046c8 <etext+0x808>
ffffffffc0200b5e:	e36ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200b62:	b709                	j	ffffffffc0200a64 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b64:	00004517          	auipc	a0,0x4
ffffffffc0200b68:	b5450513          	addi	a0,a0,-1196 # ffffffffc02046b8 <etext+0x7f8>
ffffffffc0200b6c:	e28ff0ef          	jal	ffffffffc0200194 <cprintf>
            num++;
ffffffffc0200b70:	0000d797          	auipc	a5,0xd
ffffffffc0200b74:	9207a783          	lw	a5,-1760(a5) # ffffffffc020d490 <num.0>
            ticks=0;
ffffffffc0200b78:	0000d717          	auipc	a4,0xd
ffffffffc0200b7c:	90073023          	sd	zero,-1792(a4) # ffffffffc020d478 <ticks>
            num++;
ffffffffc0200b80:	2785                	addiw	a5,a5,1
ffffffffc0200b82:	0000d717          	auipc	a4,0xd
ffffffffc0200b86:	90f72723          	sw	a5,-1778(a4) # ffffffffc020d490 <num.0>
            ticks=0;
ffffffffc0200b8a:	bf55                	j	ffffffffc0200b3e <interrupt_handler+0x78>

ffffffffc0200b8c <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200b8c:	11853783          	ld	a5,280(a0)
ffffffffc0200b90:	473d                	li	a4,15
ffffffffc0200b92:	0cf76563          	bltu	a4,a5,ffffffffc0200c5c <exception_handler+0xd0>
ffffffffc0200b96:	00005717          	auipc	a4,0x5
ffffffffc0200b9a:	c7270713          	addi	a4,a4,-910 # ffffffffc0205808 <commands+0x78>
ffffffffc0200b9e:	078a                	slli	a5,a5,0x2
ffffffffc0200ba0:	97ba                	add	a5,a5,a4
ffffffffc0200ba2:	439c                	lw	a5,0(a5)
ffffffffc0200ba4:	97ba                	add	a5,a5,a4
ffffffffc0200ba6:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200ba8:	00004517          	auipc	a0,0x4
ffffffffc0200bac:	cc050513          	addi	a0,a0,-832 # ffffffffc0204868 <etext+0x9a8>
ffffffffc0200bb0:	de4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200bb4:	00004517          	auipc	a0,0x4
ffffffffc0200bb8:	b3450513          	addi	a0,a0,-1228 # ffffffffc02046e8 <etext+0x828>
ffffffffc0200bbc:	dd8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200bc0:	00004517          	auipc	a0,0x4
ffffffffc0200bc4:	b4850513          	addi	a0,a0,-1208 # ffffffffc0204708 <etext+0x848>
ffffffffc0200bc8:	dccff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200bcc:	00004517          	auipc	a0,0x4
ffffffffc0200bd0:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0204728 <etext+0x868>
ffffffffc0200bd4:	dc0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200bd8:	00004517          	auipc	a0,0x4
ffffffffc0200bdc:	b6850513          	addi	a0,a0,-1176 # ffffffffc0204740 <etext+0x880>
ffffffffc0200be0:	db4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200be4:	00004517          	auipc	a0,0x4
ffffffffc0200be8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0204750 <etext+0x890>
ffffffffc0200bec:	da8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200bf0:	00004517          	auipc	a0,0x4
ffffffffc0200bf4:	b8050513          	addi	a0,a0,-1152 # ffffffffc0204770 <etext+0x8b0>
ffffffffc0200bf8:	d9cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200bfc:	00004517          	auipc	a0,0x4
ffffffffc0200c00:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0204788 <etext+0x8c8>
ffffffffc0200c04:	d90ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200c08:	00004517          	auipc	a0,0x4
ffffffffc0200c0c:	b9850513          	addi	a0,a0,-1128 # ffffffffc02047a0 <etext+0x8e0>
ffffffffc0200c10:	d84ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200c14:	00004517          	auipc	a0,0x4
ffffffffc0200c18:	ba450513          	addi	a0,a0,-1116 # ffffffffc02047b8 <etext+0x8f8>
ffffffffc0200c1c:	d78ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200c20:	00004517          	auipc	a0,0x4
ffffffffc0200c24:	bb850513          	addi	a0,a0,-1096 # ffffffffc02047d8 <etext+0x918>
ffffffffc0200c28:	d6cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200c2c:	00004517          	auipc	a0,0x4
ffffffffc0200c30:	bcc50513          	addi	a0,a0,-1076 # ffffffffc02047f8 <etext+0x938>
ffffffffc0200c34:	d60ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200c38:	00004517          	auipc	a0,0x4
ffffffffc0200c3c:	be050513          	addi	a0,a0,-1056 # ffffffffc0204818 <etext+0x958>
ffffffffc0200c40:	d54ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200c44:	00004517          	auipc	a0,0x4
ffffffffc0200c48:	bf450513          	addi	a0,a0,-1036 # ffffffffc0204838 <etext+0x978>
ffffffffc0200c4c:	d48ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200c50:	00004517          	auipc	a0,0x4
ffffffffc0200c54:	c0050513          	addi	a0,a0,-1024 # ffffffffc0204850 <etext+0x990>
ffffffffc0200c58:	d3cff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200c5c:	b521                	j	ffffffffc0200a64 <print_trapframe>

ffffffffc0200c5e <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200c5e:	11853783          	ld	a5,280(a0)
ffffffffc0200c62:	0007c363          	bltz	a5,ffffffffc0200c68 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200c66:	b71d                	j	ffffffffc0200b8c <exception_handler>
        interrupt_handler(tf);
ffffffffc0200c68:	bdb9                	j	ffffffffc0200ac6 <interrupt_handler>
	...

ffffffffc0200c6c <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200c6c:	14011073          	csrw	sscratch,sp
ffffffffc0200c70:	712d                	addi	sp,sp,-288
ffffffffc0200c72:	e406                	sd	ra,8(sp)
ffffffffc0200c74:	ec0e                	sd	gp,24(sp)
ffffffffc0200c76:	f012                	sd	tp,32(sp)
ffffffffc0200c78:	f416                	sd	t0,40(sp)
ffffffffc0200c7a:	f81a                	sd	t1,48(sp)
ffffffffc0200c7c:	fc1e                	sd	t2,56(sp)
ffffffffc0200c7e:	e0a2                	sd	s0,64(sp)
ffffffffc0200c80:	e4a6                	sd	s1,72(sp)
ffffffffc0200c82:	e8aa                	sd	a0,80(sp)
ffffffffc0200c84:	ecae                	sd	a1,88(sp)
ffffffffc0200c86:	f0b2                	sd	a2,96(sp)
ffffffffc0200c88:	f4b6                	sd	a3,104(sp)
ffffffffc0200c8a:	f8ba                	sd	a4,112(sp)
ffffffffc0200c8c:	fcbe                	sd	a5,120(sp)
ffffffffc0200c8e:	e142                	sd	a6,128(sp)
ffffffffc0200c90:	e546                	sd	a7,136(sp)
ffffffffc0200c92:	e94a                	sd	s2,144(sp)
ffffffffc0200c94:	ed4e                	sd	s3,152(sp)
ffffffffc0200c96:	f152                	sd	s4,160(sp)
ffffffffc0200c98:	f556                	sd	s5,168(sp)
ffffffffc0200c9a:	f95a                	sd	s6,176(sp)
ffffffffc0200c9c:	fd5e                	sd	s7,184(sp)
ffffffffc0200c9e:	e1e2                	sd	s8,192(sp)
ffffffffc0200ca0:	e5e6                	sd	s9,200(sp)
ffffffffc0200ca2:	e9ea                	sd	s10,208(sp)
ffffffffc0200ca4:	edee                	sd	s11,216(sp)
ffffffffc0200ca6:	f1f2                	sd	t3,224(sp)
ffffffffc0200ca8:	f5f6                	sd	t4,232(sp)
ffffffffc0200caa:	f9fa                	sd	t5,240(sp)
ffffffffc0200cac:	fdfe                	sd	t6,248(sp)
ffffffffc0200cae:	14002473          	csrr	s0,sscratch
ffffffffc0200cb2:	100024f3          	csrr	s1,sstatus
ffffffffc0200cb6:	14102973          	csrr	s2,sepc
ffffffffc0200cba:	143029f3          	csrr	s3,stval
ffffffffc0200cbe:	14202a73          	csrr	s4,scause
ffffffffc0200cc2:	e822                	sd	s0,16(sp)
ffffffffc0200cc4:	e226                	sd	s1,256(sp)
ffffffffc0200cc6:	e64a                	sd	s2,264(sp)
ffffffffc0200cc8:	ea4e                	sd	s3,272(sp)
ffffffffc0200cca:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200ccc:	850a                	mv	a0,sp
    jal trap
ffffffffc0200cce:	f91ff0ef          	jal	ffffffffc0200c5e <trap>

ffffffffc0200cd2 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200cd2:	6492                	ld	s1,256(sp)
ffffffffc0200cd4:	6932                	ld	s2,264(sp)
ffffffffc0200cd6:	10049073          	csrw	sstatus,s1
ffffffffc0200cda:	14191073          	csrw	sepc,s2
ffffffffc0200cde:	60a2                	ld	ra,8(sp)
ffffffffc0200ce0:	61e2                	ld	gp,24(sp)
ffffffffc0200ce2:	7202                	ld	tp,32(sp)
ffffffffc0200ce4:	72a2                	ld	t0,40(sp)
ffffffffc0200ce6:	7342                	ld	t1,48(sp)
ffffffffc0200ce8:	73e2                	ld	t2,56(sp)
ffffffffc0200cea:	6406                	ld	s0,64(sp)
ffffffffc0200cec:	64a6                	ld	s1,72(sp)
ffffffffc0200cee:	6546                	ld	a0,80(sp)
ffffffffc0200cf0:	65e6                	ld	a1,88(sp)
ffffffffc0200cf2:	7606                	ld	a2,96(sp)
ffffffffc0200cf4:	76a6                	ld	a3,104(sp)
ffffffffc0200cf6:	7746                	ld	a4,112(sp)
ffffffffc0200cf8:	77e6                	ld	a5,120(sp)
ffffffffc0200cfa:	680a                	ld	a6,128(sp)
ffffffffc0200cfc:	68aa                	ld	a7,136(sp)
ffffffffc0200cfe:	694a                	ld	s2,144(sp)
ffffffffc0200d00:	69ea                	ld	s3,152(sp)
ffffffffc0200d02:	7a0a                	ld	s4,160(sp)
ffffffffc0200d04:	7aaa                	ld	s5,168(sp)
ffffffffc0200d06:	7b4a                	ld	s6,176(sp)
ffffffffc0200d08:	7bea                	ld	s7,184(sp)
ffffffffc0200d0a:	6c0e                	ld	s8,192(sp)
ffffffffc0200d0c:	6cae                	ld	s9,200(sp)
ffffffffc0200d0e:	6d4e                	ld	s10,208(sp)
ffffffffc0200d10:	6dee                	ld	s11,216(sp)
ffffffffc0200d12:	7e0e                	ld	t3,224(sp)
ffffffffc0200d14:	7eae                	ld	t4,232(sp)
ffffffffc0200d16:	7f4e                	ld	t5,240(sp)
ffffffffc0200d18:	7fee                	ld	t6,248(sp)
ffffffffc0200d1a:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200d1c:	10200073          	sret

ffffffffc0200d20 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d20:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d22:	bf45                	j	ffffffffc0200cd2 <__trapret>
ffffffffc0200d24:	0001                	nop

ffffffffc0200d26 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200d26:	00008797          	auipc	a5,0x8
ffffffffc0200d2a:	70a78793          	addi	a5,a5,1802 # ffffffffc0209430 <free_area>
ffffffffc0200d2e:	e79c                	sd	a5,8(a5)
ffffffffc0200d30:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200d32:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200d36:	8082                	ret

ffffffffc0200d38 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200d38:	00008517          	auipc	a0,0x8
ffffffffc0200d3c:	70856503          	lwu	a0,1800(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200d40:	8082                	ret

ffffffffc0200d42 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200d42:	711d                	addi	sp,sp,-96
ffffffffc0200d44:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200d46:	00008917          	auipc	s2,0x8
ffffffffc0200d4a:	6ea90913          	addi	s2,s2,1770 # ffffffffc0209430 <free_area>
ffffffffc0200d4e:	00893783          	ld	a5,8(s2)
ffffffffc0200d52:	ec86                	sd	ra,88(sp)
ffffffffc0200d54:	e8a2                	sd	s0,80(sp)
ffffffffc0200d56:	e4a6                	sd	s1,72(sp)
ffffffffc0200d58:	fc4e                	sd	s3,56(sp)
ffffffffc0200d5a:	f852                	sd	s4,48(sp)
ffffffffc0200d5c:	f456                	sd	s5,40(sp)
ffffffffc0200d5e:	f05a                	sd	s6,32(sp)
ffffffffc0200d60:	ec5e                	sd	s7,24(sp)
ffffffffc0200d62:	e862                	sd	s8,16(sp)
ffffffffc0200d64:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d66:	2f278763          	beq	a5,s2,ffffffffc0201054 <default_check+0x312>
    int count = 0, total = 0;
ffffffffc0200d6a:	4401                	li	s0,0
ffffffffc0200d6c:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d6e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d72:	8b09                	andi	a4,a4,2
ffffffffc0200d74:	2e070463          	beqz	a4,ffffffffc020105c <default_check+0x31a>
        count ++, total += p->property;
ffffffffc0200d78:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d7c:	679c                	ld	a5,8(a5)
ffffffffc0200d7e:	2485                	addiw	s1,s1,1
ffffffffc0200d80:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d82:	ff2796e3          	bne	a5,s2,ffffffffc0200d6e <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200d86:	89a2                	mv	s3,s0
ffffffffc0200d88:	745000ef          	jal	ffffffffc0201ccc <nr_free_pages>
ffffffffc0200d8c:	73351863          	bne	a0,s3,ffffffffc02014bc <default_check+0x77a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d90:	4505                	li	a0,1
ffffffffc0200d92:	6c9000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200d96:	8a2a                	mv	s4,a0
ffffffffc0200d98:	46050263          	beqz	a0,ffffffffc02011fc <default_check+0x4ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d9c:	4505                	li	a0,1
ffffffffc0200d9e:	6bd000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200da2:	89aa                	mv	s3,a0
ffffffffc0200da4:	72050c63          	beqz	a0,ffffffffc02014dc <default_check+0x79a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200da8:	4505                	li	a0,1
ffffffffc0200daa:	6b1000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200dae:	8aaa                	mv	s5,a0
ffffffffc0200db0:	4c050663          	beqz	a0,ffffffffc020127c <default_check+0x53a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200db4:	40aa07b3          	sub	a5,s4,a0
ffffffffc0200db8:	40a98733          	sub	a4,s3,a0
ffffffffc0200dbc:	0017b793          	seqz	a5,a5
ffffffffc0200dc0:	00173713          	seqz	a4,a4
ffffffffc0200dc4:	8fd9                	or	a5,a5,a4
ffffffffc0200dc6:	30079b63          	bnez	a5,ffffffffc02010dc <default_check+0x39a>
ffffffffc0200dca:	313a0963          	beq	s4,s3,ffffffffc02010dc <default_check+0x39a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200dce:	000a2783          	lw	a5,0(s4)
ffffffffc0200dd2:	2a079563          	bnez	a5,ffffffffc020107c <default_check+0x33a>
ffffffffc0200dd6:	0009a783          	lw	a5,0(s3)
ffffffffc0200dda:	2a079163          	bnez	a5,ffffffffc020107c <default_check+0x33a>
ffffffffc0200dde:	411c                	lw	a5,0(a0)
ffffffffc0200de0:	28079e63          	bnez	a5,ffffffffc020107c <default_check+0x33a>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200de4:	0000c797          	auipc	a5,0xc
ffffffffc0200de8:	6e47b783          	ld	a5,1764(a5) # ffffffffc020d4c8 <pages>
ffffffffc0200dec:	00005617          	auipc	a2,0x5
ffffffffc0200df0:	c2463603          	ld	a2,-988(a2) # ffffffffc0205a10 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200df4:	0000c697          	auipc	a3,0xc
ffffffffc0200df8:	6cc6b683          	ld	a3,1740(a3) # ffffffffc020d4c0 <npage>
ffffffffc0200dfc:	40fa0733          	sub	a4,s4,a5
ffffffffc0200e00:	8719                	srai	a4,a4,0x6
ffffffffc0200e02:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e04:	0732                	slli	a4,a4,0xc
ffffffffc0200e06:	06b2                	slli	a3,a3,0xc
ffffffffc0200e08:	2ad77a63          	bgeu	a4,a3,ffffffffc02010bc <default_check+0x37a>
    return page - pages + nbase;
ffffffffc0200e0c:	40f98733          	sub	a4,s3,a5
ffffffffc0200e10:	8719                	srai	a4,a4,0x6
ffffffffc0200e12:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e14:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e16:	4ed77363          	bgeu	a4,a3,ffffffffc02012fc <default_check+0x5ba>
    return page - pages + nbase;
ffffffffc0200e1a:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e1e:	8799                	srai	a5,a5,0x6
ffffffffc0200e20:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e22:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e24:	32d7fc63          	bgeu	a5,a3,ffffffffc020115c <default_check+0x41a>
    assert(alloc_page() == NULL);
ffffffffc0200e28:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e2a:	00093c03          	ld	s8,0(s2)
ffffffffc0200e2e:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e32:	00008b17          	auipc	s6,0x8
ffffffffc0200e36:	60eb2b03          	lw	s6,1550(s6) # ffffffffc0209440 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200e3a:	01293023          	sd	s2,0(s2)
ffffffffc0200e3e:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200e42:	00008797          	auipc	a5,0x8
ffffffffc0200e46:	5e07af23          	sw	zero,1534(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e4a:	611000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200e4e:	2e051763          	bnez	a0,ffffffffc020113c <default_check+0x3fa>
    free_page(p0);
ffffffffc0200e52:	8552                	mv	a0,s4
ffffffffc0200e54:	4585                	li	a1,1
ffffffffc0200e56:	63f000ef          	jal	ffffffffc0201c94 <free_pages>
    free_page(p1);
ffffffffc0200e5a:	854e                	mv	a0,s3
ffffffffc0200e5c:	4585                	li	a1,1
ffffffffc0200e5e:	637000ef          	jal	ffffffffc0201c94 <free_pages>
    free_page(p2);
ffffffffc0200e62:	8556                	mv	a0,s5
ffffffffc0200e64:	4585                	li	a1,1
ffffffffc0200e66:	62f000ef          	jal	ffffffffc0201c94 <free_pages>
    assert(nr_free == 3);
ffffffffc0200e6a:	00008717          	auipc	a4,0x8
ffffffffc0200e6e:	5d672703          	lw	a4,1494(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200e72:	478d                	li	a5,3
ffffffffc0200e74:	2af71463          	bne	a4,a5,ffffffffc020111c <default_check+0x3da>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e78:	4505                	li	a0,1
ffffffffc0200e7a:	5e1000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200e7e:	89aa                	mv	s3,a0
ffffffffc0200e80:	26050e63          	beqz	a0,ffffffffc02010fc <default_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e84:	4505                	li	a0,1
ffffffffc0200e86:	5d5000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200e8a:	8aaa                	mv	s5,a0
ffffffffc0200e8c:	3c050863          	beqz	a0,ffffffffc020125c <default_check+0x51a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e90:	4505                	li	a0,1
ffffffffc0200e92:	5c9000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200e96:	8a2a                	mv	s4,a0
ffffffffc0200e98:	3a050263          	beqz	a0,ffffffffc020123c <default_check+0x4fa>
    assert(alloc_page() == NULL);
ffffffffc0200e9c:	4505                	li	a0,1
ffffffffc0200e9e:	5bd000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200ea2:	36051d63          	bnez	a0,ffffffffc020121c <default_check+0x4da>
    free_page(p0);
ffffffffc0200ea6:	4585                	li	a1,1
ffffffffc0200ea8:	854e                	mv	a0,s3
ffffffffc0200eaa:	5eb000ef          	jal	ffffffffc0201c94 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200eae:	00893783          	ld	a5,8(s2)
ffffffffc0200eb2:	1f278563          	beq	a5,s2,ffffffffc020109c <default_check+0x35a>
    assert((p = alloc_page()) == p0);
ffffffffc0200eb6:	4505                	li	a0,1
ffffffffc0200eb8:	5a3000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200ebc:	8caa                	mv	s9,a0
ffffffffc0200ebe:	30a99f63          	bne	s3,a0,ffffffffc02011dc <default_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc0200ec2:	4505                	li	a0,1
ffffffffc0200ec4:	597000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200ec8:	2e051a63          	bnez	a0,ffffffffc02011bc <default_check+0x47a>
    assert(nr_free == 0);
ffffffffc0200ecc:	00008797          	auipc	a5,0x8
ffffffffc0200ed0:	5747a783          	lw	a5,1396(a5) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200ed4:	2c079463          	bnez	a5,ffffffffc020119c <default_check+0x45a>
    free_page(p);
ffffffffc0200ed8:	8566                	mv	a0,s9
ffffffffc0200eda:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200edc:	01893023          	sd	s8,0(s2)
ffffffffc0200ee0:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200ee4:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200ee8:	5ad000ef          	jal	ffffffffc0201c94 <free_pages>
    free_page(p1);
ffffffffc0200eec:	8556                	mv	a0,s5
ffffffffc0200eee:	4585                	li	a1,1
ffffffffc0200ef0:	5a5000ef          	jal	ffffffffc0201c94 <free_pages>
    free_page(p2);
ffffffffc0200ef4:	8552                	mv	a0,s4
ffffffffc0200ef6:	4585                	li	a1,1
ffffffffc0200ef8:	59d000ef          	jal	ffffffffc0201c94 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200efc:	4515                	li	a0,5
ffffffffc0200efe:	55d000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200f02:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f04:	26050c63          	beqz	a0,ffffffffc020117c <default_check+0x43a>
ffffffffc0200f08:	651c                	ld	a5,8(a0)
ffffffffc0200f0a:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f0c:	8b85                	andi	a5,a5,1
ffffffffc0200f0e:	54079763          	bnez	a5,ffffffffc020145c <default_check+0x71a>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f12:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f14:	00093b83          	ld	s7,0(s2)
ffffffffc0200f18:	00893b03          	ld	s6,8(s2)
ffffffffc0200f1c:	01293023          	sd	s2,0(s2)
ffffffffc0200f20:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200f24:	537000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200f28:	50051a63          	bnez	a0,ffffffffc020143c <default_check+0x6fa>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200f2c:	08098a13          	addi	s4,s3,128
ffffffffc0200f30:	8552                	mv	a0,s4
ffffffffc0200f32:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200f34:	00008c17          	auipc	s8,0x8
ffffffffc0200f38:	50cc2c03          	lw	s8,1292(s8) # ffffffffc0209440 <free_area+0x10>
    nr_free = 0;
ffffffffc0200f3c:	00008797          	auipc	a5,0x8
ffffffffc0200f40:	5007a223          	sw	zero,1284(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200f44:	551000ef          	jal	ffffffffc0201c94 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f48:	4511                	li	a0,4
ffffffffc0200f4a:	511000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200f4e:	4c051763          	bnez	a0,ffffffffc020141c <default_check+0x6da>
ffffffffc0200f52:	0889b783          	ld	a5,136(s3)
ffffffffc0200f56:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200f58:	8b85                	andi	a5,a5,1
ffffffffc0200f5a:	4a078163          	beqz	a5,ffffffffc02013fc <default_check+0x6ba>
ffffffffc0200f5e:	0909a503          	lw	a0,144(s3)
ffffffffc0200f62:	478d                	li	a5,3
ffffffffc0200f64:	48f51c63          	bne	a0,a5,ffffffffc02013fc <default_check+0x6ba>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200f68:	4f3000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200f6c:	8aaa                	mv	s5,a0
ffffffffc0200f6e:	46050763          	beqz	a0,ffffffffc02013dc <default_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc0200f72:	4505                	li	a0,1
ffffffffc0200f74:	4e7000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200f78:	44051263          	bnez	a0,ffffffffc02013bc <default_check+0x67a>
    assert(p0 + 2 == p1);
ffffffffc0200f7c:	435a1063          	bne	s4,s5,ffffffffc020139c <default_check+0x65a>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200f80:	4585                	li	a1,1
ffffffffc0200f82:	854e                	mv	a0,s3
ffffffffc0200f84:	511000ef          	jal	ffffffffc0201c94 <free_pages>
    free_pages(p1, 3);
ffffffffc0200f88:	8552                	mv	a0,s4
ffffffffc0200f8a:	458d                	li	a1,3
ffffffffc0200f8c:	509000ef          	jal	ffffffffc0201c94 <free_pages>
ffffffffc0200f90:	0089b783          	ld	a5,8(s3)
ffffffffc0200f94:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200f96:	8b85                	andi	a5,a5,1
ffffffffc0200f98:	3e078263          	beqz	a5,ffffffffc020137c <default_check+0x63a>
ffffffffc0200f9c:	0109aa83          	lw	s5,16(s3)
ffffffffc0200fa0:	4785                	li	a5,1
ffffffffc0200fa2:	3cfa9d63          	bne	s5,a5,ffffffffc020137c <default_check+0x63a>
ffffffffc0200fa6:	008a3783          	ld	a5,8(s4)
ffffffffc0200faa:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200fac:	8b85                	andi	a5,a5,1
ffffffffc0200fae:	3a078763          	beqz	a5,ffffffffc020135c <default_check+0x61a>
ffffffffc0200fb2:	010a2703          	lw	a4,16(s4)
ffffffffc0200fb6:	478d                	li	a5,3
ffffffffc0200fb8:	3af71263          	bne	a4,a5,ffffffffc020135c <default_check+0x61a>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200fbc:	8556                	mv	a0,s5
ffffffffc0200fbe:	49d000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200fc2:	36a99d63          	bne	s3,a0,ffffffffc020133c <default_check+0x5fa>
    free_page(p0);
ffffffffc0200fc6:	85d6                	mv	a1,s5
ffffffffc0200fc8:	4cd000ef          	jal	ffffffffc0201c94 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200fcc:	4509                	li	a0,2
ffffffffc0200fce:	48d000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200fd2:	34aa1563          	bne	s4,a0,ffffffffc020131c <default_check+0x5da>

    free_pages(p0, 2);
ffffffffc0200fd6:	4589                	li	a1,2
ffffffffc0200fd8:	4bd000ef          	jal	ffffffffc0201c94 <free_pages>
    free_page(p2);
ffffffffc0200fdc:	04098513          	addi	a0,s3,64
ffffffffc0200fe0:	85d6                	mv	a1,s5
ffffffffc0200fe2:	4b3000ef          	jal	ffffffffc0201c94 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200fe6:	4515                	li	a0,5
ffffffffc0200fe8:	473000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200fec:	89aa                	mv	s3,a0
ffffffffc0200fee:	48050763          	beqz	a0,ffffffffc020147c <default_check+0x73a>
    assert(alloc_page() == NULL);
ffffffffc0200ff2:	8556                	mv	a0,s5
ffffffffc0200ff4:	467000ef          	jal	ffffffffc0201c5a <alloc_pages>
ffffffffc0200ff8:	2e051263          	bnez	a0,ffffffffc02012dc <default_check+0x59a>

    assert(nr_free == 0);
ffffffffc0200ffc:	00008797          	auipc	a5,0x8
ffffffffc0201000:	4447a783          	lw	a5,1092(a5) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201004:	2a079c63          	bnez	a5,ffffffffc02012bc <default_check+0x57a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201008:	854e                	mv	a0,s3
ffffffffc020100a:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc020100c:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0201010:	01793023          	sd	s7,0(s2)
ffffffffc0201014:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0201018:	47d000ef          	jal	ffffffffc0201c94 <free_pages>
    return listelm->next;
ffffffffc020101c:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201020:	01278963          	beq	a5,s2,ffffffffc0201032 <default_check+0x2f0>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201024:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201028:	679c                	ld	a5,8(a5)
ffffffffc020102a:	34fd                	addiw	s1,s1,-1
ffffffffc020102c:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020102e:	ff279be3          	bne	a5,s2,ffffffffc0201024 <default_check+0x2e2>
    }
    assert(count == 0);
ffffffffc0201032:	26049563          	bnez	s1,ffffffffc020129c <default_check+0x55a>
    assert(total == 0);
ffffffffc0201036:	46041363          	bnez	s0,ffffffffc020149c <default_check+0x75a>
}
ffffffffc020103a:	60e6                	ld	ra,88(sp)
ffffffffc020103c:	6446                	ld	s0,80(sp)
ffffffffc020103e:	64a6                	ld	s1,72(sp)
ffffffffc0201040:	6906                	ld	s2,64(sp)
ffffffffc0201042:	79e2                	ld	s3,56(sp)
ffffffffc0201044:	7a42                	ld	s4,48(sp)
ffffffffc0201046:	7aa2                	ld	s5,40(sp)
ffffffffc0201048:	7b02                	ld	s6,32(sp)
ffffffffc020104a:	6be2                	ld	s7,24(sp)
ffffffffc020104c:	6c42                	ld	s8,16(sp)
ffffffffc020104e:	6ca2                	ld	s9,8(sp)
ffffffffc0201050:	6125                	addi	sp,sp,96
ffffffffc0201052:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201054:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201056:	4401                	li	s0,0
ffffffffc0201058:	4481                	li	s1,0
ffffffffc020105a:	b33d                	j	ffffffffc0200d88 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc020105c:	00004697          	auipc	a3,0x4
ffffffffc0201060:	82468693          	addi	a3,a3,-2012 # ffffffffc0204880 <etext+0x9c0>
ffffffffc0201064:	00004617          	auipc	a2,0x4
ffffffffc0201068:	82c60613          	addi	a2,a2,-2004 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020106c:	0f000593          	li	a1,240
ffffffffc0201070:	00004517          	auipc	a0,0x4
ffffffffc0201074:	83850513          	addi	a0,a0,-1992 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201078:	b8eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020107c:	00004697          	auipc	a3,0x4
ffffffffc0201080:	8ec68693          	addi	a3,a3,-1812 # ffffffffc0204968 <etext+0xaa8>
ffffffffc0201084:	00004617          	auipc	a2,0x4
ffffffffc0201088:	80c60613          	addi	a2,a2,-2036 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020108c:	0be00593          	li	a1,190
ffffffffc0201090:	00004517          	auipc	a0,0x4
ffffffffc0201094:	81850513          	addi	a0,a0,-2024 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201098:	b6eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(!list_empty(&free_list));
ffffffffc020109c:	00004697          	auipc	a3,0x4
ffffffffc02010a0:	99468693          	addi	a3,a3,-1644 # ffffffffc0204a30 <etext+0xb70>
ffffffffc02010a4:	00003617          	auipc	a2,0x3
ffffffffc02010a8:	7ec60613          	addi	a2,a2,2028 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02010ac:	0d900593          	li	a1,217
ffffffffc02010b0:	00003517          	auipc	a0,0x3
ffffffffc02010b4:	7f850513          	addi	a0,a0,2040 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02010b8:	b4eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010bc:	00004697          	auipc	a3,0x4
ffffffffc02010c0:	8ec68693          	addi	a3,a3,-1812 # ffffffffc02049a8 <etext+0xae8>
ffffffffc02010c4:	00003617          	auipc	a2,0x3
ffffffffc02010c8:	7cc60613          	addi	a2,a2,1996 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02010cc:	0c000593          	li	a1,192
ffffffffc02010d0:	00003517          	auipc	a0,0x3
ffffffffc02010d4:	7d850513          	addi	a0,a0,2008 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02010d8:	b2eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010dc:	00004697          	auipc	a3,0x4
ffffffffc02010e0:	86468693          	addi	a3,a3,-1948 # ffffffffc0204940 <etext+0xa80>
ffffffffc02010e4:	00003617          	auipc	a2,0x3
ffffffffc02010e8:	7ac60613          	addi	a2,a2,1964 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02010ec:	0bd00593          	li	a1,189
ffffffffc02010f0:	00003517          	auipc	a0,0x3
ffffffffc02010f4:	7b850513          	addi	a0,a0,1976 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02010f8:	b0eff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010fc:	00003697          	auipc	a3,0x3
ffffffffc0201100:	7e468693          	addi	a3,a3,2020 # ffffffffc02048e0 <etext+0xa20>
ffffffffc0201104:	00003617          	auipc	a2,0x3
ffffffffc0201108:	78c60613          	addi	a2,a2,1932 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020110c:	0d200593          	li	a1,210
ffffffffc0201110:	00003517          	auipc	a0,0x3
ffffffffc0201114:	79850513          	addi	a0,a0,1944 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201118:	aeeff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 3);
ffffffffc020111c:	00004697          	auipc	a3,0x4
ffffffffc0201120:	90468693          	addi	a3,a3,-1788 # ffffffffc0204a20 <etext+0xb60>
ffffffffc0201124:	00003617          	auipc	a2,0x3
ffffffffc0201128:	76c60613          	addi	a2,a2,1900 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020112c:	0d000593          	li	a1,208
ffffffffc0201130:	00003517          	auipc	a0,0x3
ffffffffc0201134:	77850513          	addi	a0,a0,1912 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201138:	aceff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020113c:	00004697          	auipc	a3,0x4
ffffffffc0201140:	8cc68693          	addi	a3,a3,-1844 # ffffffffc0204a08 <etext+0xb48>
ffffffffc0201144:	00003617          	auipc	a2,0x3
ffffffffc0201148:	74c60613          	addi	a2,a2,1868 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020114c:	0cb00593          	li	a1,203
ffffffffc0201150:	00003517          	auipc	a0,0x3
ffffffffc0201154:	75850513          	addi	a0,a0,1880 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201158:	aaeff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020115c:	00004697          	auipc	a3,0x4
ffffffffc0201160:	88c68693          	addi	a3,a3,-1908 # ffffffffc02049e8 <etext+0xb28>
ffffffffc0201164:	00003617          	auipc	a2,0x3
ffffffffc0201168:	72c60613          	addi	a2,a2,1836 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020116c:	0c200593          	li	a1,194
ffffffffc0201170:	00003517          	auipc	a0,0x3
ffffffffc0201174:	73850513          	addi	a0,a0,1848 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201178:	a8eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 != NULL);
ffffffffc020117c:	00004697          	auipc	a3,0x4
ffffffffc0201180:	8fc68693          	addi	a3,a3,-1796 # ffffffffc0204a78 <etext+0xbb8>
ffffffffc0201184:	00003617          	auipc	a2,0x3
ffffffffc0201188:	70c60613          	addi	a2,a2,1804 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020118c:	0f800593          	li	a1,248
ffffffffc0201190:	00003517          	auipc	a0,0x3
ffffffffc0201194:	71850513          	addi	a0,a0,1816 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201198:	a6eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 0);
ffffffffc020119c:	00004697          	auipc	a3,0x4
ffffffffc02011a0:	8cc68693          	addi	a3,a3,-1844 # ffffffffc0204a68 <etext+0xba8>
ffffffffc02011a4:	00003617          	auipc	a2,0x3
ffffffffc02011a8:	6ec60613          	addi	a2,a2,1772 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02011ac:	0df00593          	li	a1,223
ffffffffc02011b0:	00003517          	auipc	a0,0x3
ffffffffc02011b4:	6f850513          	addi	a0,a0,1784 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02011b8:	a4eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011bc:	00004697          	auipc	a3,0x4
ffffffffc02011c0:	84c68693          	addi	a3,a3,-1972 # ffffffffc0204a08 <etext+0xb48>
ffffffffc02011c4:	00003617          	auipc	a2,0x3
ffffffffc02011c8:	6cc60613          	addi	a2,a2,1740 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02011cc:	0dd00593          	li	a1,221
ffffffffc02011d0:	00003517          	auipc	a0,0x3
ffffffffc02011d4:	6d850513          	addi	a0,a0,1752 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02011d8:	a2eff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02011dc:	00004697          	auipc	a3,0x4
ffffffffc02011e0:	86c68693          	addi	a3,a3,-1940 # ffffffffc0204a48 <etext+0xb88>
ffffffffc02011e4:	00003617          	auipc	a2,0x3
ffffffffc02011e8:	6ac60613          	addi	a2,a2,1708 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02011ec:	0dc00593          	li	a1,220
ffffffffc02011f0:	00003517          	auipc	a0,0x3
ffffffffc02011f4:	6b850513          	addi	a0,a0,1720 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02011f8:	a0eff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011fc:	00003697          	auipc	a3,0x3
ffffffffc0201200:	6e468693          	addi	a3,a3,1764 # ffffffffc02048e0 <etext+0xa20>
ffffffffc0201204:	00003617          	auipc	a2,0x3
ffffffffc0201208:	68c60613          	addi	a2,a2,1676 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020120c:	0b900593          	li	a1,185
ffffffffc0201210:	00003517          	auipc	a0,0x3
ffffffffc0201214:	69850513          	addi	a0,a0,1688 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201218:	9eeff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020121c:	00003697          	auipc	a3,0x3
ffffffffc0201220:	7ec68693          	addi	a3,a3,2028 # ffffffffc0204a08 <etext+0xb48>
ffffffffc0201224:	00003617          	auipc	a2,0x3
ffffffffc0201228:	66c60613          	addi	a2,a2,1644 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020122c:	0d600593          	li	a1,214
ffffffffc0201230:	00003517          	auipc	a0,0x3
ffffffffc0201234:	67850513          	addi	a0,a0,1656 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201238:	9ceff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020123c:	00003697          	auipc	a3,0x3
ffffffffc0201240:	6e468693          	addi	a3,a3,1764 # ffffffffc0204920 <etext+0xa60>
ffffffffc0201244:	00003617          	auipc	a2,0x3
ffffffffc0201248:	64c60613          	addi	a2,a2,1612 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020124c:	0d400593          	li	a1,212
ffffffffc0201250:	00003517          	auipc	a0,0x3
ffffffffc0201254:	65850513          	addi	a0,a0,1624 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201258:	9aeff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020125c:	00003697          	auipc	a3,0x3
ffffffffc0201260:	6a468693          	addi	a3,a3,1700 # ffffffffc0204900 <etext+0xa40>
ffffffffc0201264:	00003617          	auipc	a2,0x3
ffffffffc0201268:	62c60613          	addi	a2,a2,1580 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020126c:	0d300593          	li	a1,211
ffffffffc0201270:	00003517          	auipc	a0,0x3
ffffffffc0201274:	63850513          	addi	a0,a0,1592 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201278:	98eff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020127c:	00003697          	auipc	a3,0x3
ffffffffc0201280:	6a468693          	addi	a3,a3,1700 # ffffffffc0204920 <etext+0xa60>
ffffffffc0201284:	00003617          	auipc	a2,0x3
ffffffffc0201288:	60c60613          	addi	a2,a2,1548 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020128c:	0bb00593          	li	a1,187
ffffffffc0201290:	00003517          	auipc	a0,0x3
ffffffffc0201294:	61850513          	addi	a0,a0,1560 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201298:	96eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(count == 0);
ffffffffc020129c:	00004697          	auipc	a3,0x4
ffffffffc02012a0:	92c68693          	addi	a3,a3,-1748 # ffffffffc0204bc8 <etext+0xd08>
ffffffffc02012a4:	00003617          	auipc	a2,0x3
ffffffffc02012a8:	5ec60613          	addi	a2,a2,1516 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02012ac:	12500593          	li	a1,293
ffffffffc02012b0:	00003517          	auipc	a0,0x3
ffffffffc02012b4:	5f850513          	addi	a0,a0,1528 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02012b8:	94eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 0);
ffffffffc02012bc:	00003697          	auipc	a3,0x3
ffffffffc02012c0:	7ac68693          	addi	a3,a3,1964 # ffffffffc0204a68 <etext+0xba8>
ffffffffc02012c4:	00003617          	auipc	a2,0x3
ffffffffc02012c8:	5cc60613          	addi	a2,a2,1484 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02012cc:	11a00593          	li	a1,282
ffffffffc02012d0:	00003517          	auipc	a0,0x3
ffffffffc02012d4:	5d850513          	addi	a0,a0,1496 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02012d8:	92eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012dc:	00003697          	auipc	a3,0x3
ffffffffc02012e0:	72c68693          	addi	a3,a3,1836 # ffffffffc0204a08 <etext+0xb48>
ffffffffc02012e4:	00003617          	auipc	a2,0x3
ffffffffc02012e8:	5ac60613          	addi	a2,a2,1452 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02012ec:	11800593          	li	a1,280
ffffffffc02012f0:	00003517          	auipc	a0,0x3
ffffffffc02012f4:	5b850513          	addi	a0,a0,1464 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02012f8:	90eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02012fc:	00003697          	auipc	a3,0x3
ffffffffc0201300:	6cc68693          	addi	a3,a3,1740 # ffffffffc02049c8 <etext+0xb08>
ffffffffc0201304:	00003617          	auipc	a2,0x3
ffffffffc0201308:	58c60613          	addi	a2,a2,1420 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020130c:	0c100593          	li	a1,193
ffffffffc0201310:	00003517          	auipc	a0,0x3
ffffffffc0201314:	59850513          	addi	a0,a0,1432 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201318:	8eeff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020131c:	00004697          	auipc	a3,0x4
ffffffffc0201320:	86c68693          	addi	a3,a3,-1940 # ffffffffc0204b88 <etext+0xcc8>
ffffffffc0201324:	00003617          	auipc	a2,0x3
ffffffffc0201328:	56c60613          	addi	a2,a2,1388 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020132c:	11200593          	li	a1,274
ffffffffc0201330:	00003517          	auipc	a0,0x3
ffffffffc0201334:	57850513          	addi	a0,a0,1400 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201338:	8ceff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020133c:	00004697          	auipc	a3,0x4
ffffffffc0201340:	82c68693          	addi	a3,a3,-2004 # ffffffffc0204b68 <etext+0xca8>
ffffffffc0201344:	00003617          	auipc	a2,0x3
ffffffffc0201348:	54c60613          	addi	a2,a2,1356 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020134c:	11000593          	li	a1,272
ffffffffc0201350:	00003517          	auipc	a0,0x3
ffffffffc0201354:	55850513          	addi	a0,a0,1368 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201358:	8aeff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020135c:	00003697          	auipc	a3,0x3
ffffffffc0201360:	7e468693          	addi	a3,a3,2020 # ffffffffc0204b40 <etext+0xc80>
ffffffffc0201364:	00003617          	auipc	a2,0x3
ffffffffc0201368:	52c60613          	addi	a2,a2,1324 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020136c:	10e00593          	li	a1,270
ffffffffc0201370:	00003517          	auipc	a0,0x3
ffffffffc0201374:	53850513          	addi	a0,a0,1336 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201378:	88eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020137c:	00003697          	auipc	a3,0x3
ffffffffc0201380:	79c68693          	addi	a3,a3,1948 # ffffffffc0204b18 <etext+0xc58>
ffffffffc0201384:	00003617          	auipc	a2,0x3
ffffffffc0201388:	50c60613          	addi	a2,a2,1292 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020138c:	10d00593          	li	a1,269
ffffffffc0201390:	00003517          	auipc	a0,0x3
ffffffffc0201394:	51850513          	addi	a0,a0,1304 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201398:	86eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 + 2 == p1);
ffffffffc020139c:	00003697          	auipc	a3,0x3
ffffffffc02013a0:	76c68693          	addi	a3,a3,1900 # ffffffffc0204b08 <etext+0xc48>
ffffffffc02013a4:	00003617          	auipc	a2,0x3
ffffffffc02013a8:	4ec60613          	addi	a2,a2,1260 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02013ac:	10800593          	li	a1,264
ffffffffc02013b0:	00003517          	auipc	a0,0x3
ffffffffc02013b4:	4f850513          	addi	a0,a0,1272 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02013b8:	84eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013bc:	00003697          	auipc	a3,0x3
ffffffffc02013c0:	64c68693          	addi	a3,a3,1612 # ffffffffc0204a08 <etext+0xb48>
ffffffffc02013c4:	00003617          	auipc	a2,0x3
ffffffffc02013c8:	4cc60613          	addi	a2,a2,1228 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02013cc:	10700593          	li	a1,263
ffffffffc02013d0:	00003517          	auipc	a0,0x3
ffffffffc02013d4:	4d850513          	addi	a0,a0,1240 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02013d8:	82eff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02013dc:	00003697          	auipc	a3,0x3
ffffffffc02013e0:	70c68693          	addi	a3,a3,1804 # ffffffffc0204ae8 <etext+0xc28>
ffffffffc02013e4:	00003617          	auipc	a2,0x3
ffffffffc02013e8:	4ac60613          	addi	a2,a2,1196 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02013ec:	10600593          	li	a1,262
ffffffffc02013f0:	00003517          	auipc	a0,0x3
ffffffffc02013f4:	4b850513          	addi	a0,a0,1208 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02013f8:	80eff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02013fc:	00003697          	auipc	a3,0x3
ffffffffc0201400:	6bc68693          	addi	a3,a3,1724 # ffffffffc0204ab8 <etext+0xbf8>
ffffffffc0201404:	00003617          	auipc	a2,0x3
ffffffffc0201408:	48c60613          	addi	a2,a2,1164 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020140c:	10500593          	li	a1,261
ffffffffc0201410:	00003517          	auipc	a0,0x3
ffffffffc0201414:	49850513          	addi	a0,a0,1176 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201418:	feffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020141c:	00003697          	auipc	a3,0x3
ffffffffc0201420:	68468693          	addi	a3,a3,1668 # ffffffffc0204aa0 <etext+0xbe0>
ffffffffc0201424:	00003617          	auipc	a2,0x3
ffffffffc0201428:	46c60613          	addi	a2,a2,1132 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020142c:	10400593          	li	a1,260
ffffffffc0201430:	00003517          	auipc	a0,0x3
ffffffffc0201434:	47850513          	addi	a0,a0,1144 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201438:	fcffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020143c:	00003697          	auipc	a3,0x3
ffffffffc0201440:	5cc68693          	addi	a3,a3,1484 # ffffffffc0204a08 <etext+0xb48>
ffffffffc0201444:	00003617          	auipc	a2,0x3
ffffffffc0201448:	44c60613          	addi	a2,a2,1100 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020144c:	0fe00593          	li	a1,254
ffffffffc0201450:	00003517          	auipc	a0,0x3
ffffffffc0201454:	45850513          	addi	a0,a0,1112 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201458:	faffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(!PageProperty(p0));
ffffffffc020145c:	00003697          	auipc	a3,0x3
ffffffffc0201460:	62c68693          	addi	a3,a3,1580 # ffffffffc0204a88 <etext+0xbc8>
ffffffffc0201464:	00003617          	auipc	a2,0x3
ffffffffc0201468:	42c60613          	addi	a2,a2,1068 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020146c:	0f900593          	li	a1,249
ffffffffc0201470:	00003517          	auipc	a0,0x3
ffffffffc0201474:	43850513          	addi	a0,a0,1080 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201478:	f8ffe0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020147c:	00003697          	auipc	a3,0x3
ffffffffc0201480:	72c68693          	addi	a3,a3,1836 # ffffffffc0204ba8 <etext+0xce8>
ffffffffc0201484:	00003617          	auipc	a2,0x3
ffffffffc0201488:	40c60613          	addi	a2,a2,1036 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020148c:	11700593          	li	a1,279
ffffffffc0201490:	00003517          	auipc	a0,0x3
ffffffffc0201494:	41850513          	addi	a0,a0,1048 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201498:	f6ffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(total == 0);
ffffffffc020149c:	00003697          	auipc	a3,0x3
ffffffffc02014a0:	73c68693          	addi	a3,a3,1852 # ffffffffc0204bd8 <etext+0xd18>
ffffffffc02014a4:	00003617          	auipc	a2,0x3
ffffffffc02014a8:	3ec60613          	addi	a2,a2,1004 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02014ac:	12600593          	li	a1,294
ffffffffc02014b0:	00003517          	auipc	a0,0x3
ffffffffc02014b4:	3f850513          	addi	a0,a0,1016 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02014b8:	f4ffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(total == nr_free_pages());
ffffffffc02014bc:	00003697          	auipc	a3,0x3
ffffffffc02014c0:	40468693          	addi	a3,a3,1028 # ffffffffc02048c0 <etext+0xa00>
ffffffffc02014c4:	00003617          	auipc	a2,0x3
ffffffffc02014c8:	3cc60613          	addi	a2,a2,972 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02014cc:	0f300593          	li	a1,243
ffffffffc02014d0:	00003517          	auipc	a0,0x3
ffffffffc02014d4:	3d850513          	addi	a0,a0,984 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02014d8:	f2ffe0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014dc:	00003697          	auipc	a3,0x3
ffffffffc02014e0:	42468693          	addi	a3,a3,1060 # ffffffffc0204900 <etext+0xa40>
ffffffffc02014e4:	00003617          	auipc	a2,0x3
ffffffffc02014e8:	3ac60613          	addi	a2,a2,940 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02014ec:	0ba00593          	li	a1,186
ffffffffc02014f0:	00003517          	auipc	a0,0x3
ffffffffc02014f4:	3b850513          	addi	a0,a0,952 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02014f8:	f0ffe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc02014fc <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02014fc:	1141                	addi	sp,sp,-16
ffffffffc02014fe:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201500:	14058663          	beqz	a1,ffffffffc020164c <default_free_pages+0x150>
    for (; p != base + n; p ++) {
ffffffffc0201504:	00659713          	slli	a4,a1,0x6
ffffffffc0201508:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020150c:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020150e:	c30d                	beqz	a4,ffffffffc0201530 <default_free_pages+0x34>
ffffffffc0201510:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201512:	8b05                	andi	a4,a4,1
ffffffffc0201514:	10071c63          	bnez	a4,ffffffffc020162c <default_free_pages+0x130>
ffffffffc0201518:	6798                	ld	a4,8(a5)
ffffffffc020151a:	8b09                	andi	a4,a4,2
ffffffffc020151c:	10071863          	bnez	a4,ffffffffc020162c <default_free_pages+0x130>
        p->flags = 0;
ffffffffc0201520:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201524:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201528:	04078793          	addi	a5,a5,64
ffffffffc020152c:	fed792e3          	bne	a5,a3,ffffffffc0201510 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201530:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201532:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201536:	4789                	li	a5,2
ffffffffc0201538:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020153c:	00008717          	auipc	a4,0x8
ffffffffc0201540:	f0472703          	lw	a4,-252(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201544:	00008697          	auipc	a3,0x8
ffffffffc0201548:	eec68693          	addi	a3,a3,-276 # ffffffffc0209430 <free_area>
    return list->next == list;
ffffffffc020154c:	669c                	ld	a5,8(a3)
ffffffffc020154e:	9f2d                	addw	a4,a4,a1
ffffffffc0201550:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201552:	0ad78163          	beq	a5,a3,ffffffffc02015f4 <default_free_pages+0xf8>
            struct Page* page = le2page(le, page_link);
ffffffffc0201556:	fe878713          	addi	a4,a5,-24
ffffffffc020155a:	4581                	li	a1,0
ffffffffc020155c:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201560:	00e56a63          	bltu	a0,a4,ffffffffc0201574 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201564:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201566:	04d70c63          	beq	a4,a3,ffffffffc02015be <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc020156a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020156c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201570:	fee57ae3          	bgeu	a0,a4,ffffffffc0201564 <default_free_pages+0x68>
ffffffffc0201574:	c199                	beqz	a1,ffffffffc020157a <default_free_pages+0x7e>
ffffffffc0201576:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020157a:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020157c:	e390                	sd	a2,0(a5)
ffffffffc020157e:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc0201580:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201582:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201584:	00d70d63          	beq	a4,a3,ffffffffc020159e <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0201588:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc020158c:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0201590:	02059813          	slli	a6,a1,0x20
ffffffffc0201594:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201598:	97b2                	add	a5,a5,a2
ffffffffc020159a:	02f50c63          	beq	a0,a5,ffffffffc02015d2 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020159e:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02015a0:	00d78c63          	beq	a5,a3,ffffffffc02015b8 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc02015a4:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02015a6:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc02015aa:	02061593          	slli	a1,a2,0x20
ffffffffc02015ae:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02015b2:	972a                	add	a4,a4,a0
ffffffffc02015b4:	04e68c63          	beq	a3,a4,ffffffffc020160c <default_free_pages+0x110>
}
ffffffffc02015b8:	60a2                	ld	ra,8(sp)
ffffffffc02015ba:	0141                	addi	sp,sp,16
ffffffffc02015bc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015be:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015c0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02015c2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015c4:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02015c6:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015c8:	02d70f63          	beq	a4,a3,ffffffffc0201606 <default_free_pages+0x10a>
ffffffffc02015cc:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02015ce:	87ba                	mv	a5,a4
ffffffffc02015d0:	bf71                	j	ffffffffc020156c <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02015d2:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02015d4:	5875                	li	a6,-3
ffffffffc02015d6:	9fad                	addw	a5,a5,a1
ffffffffc02015d8:	fef72c23          	sw	a5,-8(a4)
ffffffffc02015dc:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015e0:	01853803          	ld	a6,24(a0)
ffffffffc02015e4:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02015e6:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02015e8:	00b83423          	sd	a1,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    return listelm->next;
ffffffffc02015ec:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02015ee:	0105b023          	sd	a6,0(a1)
ffffffffc02015f2:	b77d                	j	ffffffffc02015a0 <default_free_pages+0xa4>
}
ffffffffc02015f4:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02015f6:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02015fa:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015fc:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02015fe:	e398                	sd	a4,0(a5)
ffffffffc0201600:	e798                	sd	a4,8(a5)
}
ffffffffc0201602:	0141                	addi	sp,sp,16
ffffffffc0201604:	8082                	ret
ffffffffc0201606:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201608:	873e                	mv	a4,a5
ffffffffc020160a:	bfad                	j	ffffffffc0201584 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc020160c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201610:	56f5                	li	a3,-3
ffffffffc0201612:	9f31                	addw	a4,a4,a2
ffffffffc0201614:	c918                	sw	a4,16(a0)
ffffffffc0201616:	ff078713          	addi	a4,a5,-16
ffffffffc020161a:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc020161e:	6398                	ld	a4,0(a5)
ffffffffc0201620:	679c                	ld	a5,8(a5)
}
ffffffffc0201622:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201624:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201626:	e398                	sd	a4,0(a5)
ffffffffc0201628:	0141                	addi	sp,sp,16
ffffffffc020162a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020162c:	00003697          	auipc	a3,0x3
ffffffffc0201630:	5c468693          	addi	a3,a3,1476 # ffffffffc0204bf0 <etext+0xd30>
ffffffffc0201634:	00003617          	auipc	a2,0x3
ffffffffc0201638:	25c60613          	addi	a2,a2,604 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020163c:	08300593          	li	a1,131
ffffffffc0201640:	00003517          	auipc	a0,0x3
ffffffffc0201644:	26850513          	addi	a0,a0,616 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201648:	dbffe0ef          	jal	ffffffffc0200406 <__panic>
    assert(n > 0);
ffffffffc020164c:	00003697          	auipc	a3,0x3
ffffffffc0201650:	59c68693          	addi	a3,a3,1436 # ffffffffc0204be8 <etext+0xd28>
ffffffffc0201654:	00003617          	auipc	a2,0x3
ffffffffc0201658:	23c60613          	addi	a2,a2,572 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020165c:	08000593          	li	a1,128
ffffffffc0201660:	00003517          	auipc	a0,0x3
ffffffffc0201664:	24850513          	addi	a0,a0,584 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201668:	d9ffe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020166c <default_alloc_pages>:
    assert(n > 0);
ffffffffc020166c:	c951                	beqz	a0,ffffffffc0201700 <default_alloc_pages+0x94>
    if (n > nr_free) {
ffffffffc020166e:	00008597          	auipc	a1,0x8
ffffffffc0201672:	dd25a583          	lw	a1,-558(a1) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201676:	86aa                	mv	a3,a0
ffffffffc0201678:	02059793          	slli	a5,a1,0x20
ffffffffc020167c:	9381                	srli	a5,a5,0x20
ffffffffc020167e:	00a7ef63          	bltu	a5,a0,ffffffffc020169c <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc0201682:	00008617          	auipc	a2,0x8
ffffffffc0201686:	dae60613          	addi	a2,a2,-594 # ffffffffc0209430 <free_area>
ffffffffc020168a:	87b2                	mv	a5,a2
ffffffffc020168c:	a029                	j	ffffffffc0201696 <default_alloc_pages+0x2a>
        if (p->property >= n) {
ffffffffc020168e:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0201692:	00d77763          	bgeu	a4,a3,ffffffffc02016a0 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc0201696:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201698:	fec79be3          	bne	a5,a2,ffffffffc020168e <default_alloc_pages+0x22>
        return NULL;
ffffffffc020169c:	4501                	li	a0,0
}
ffffffffc020169e:	8082                	ret
        if (page->property > n) {
ffffffffc02016a0:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02016a4:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016a8:	6798                	ld	a4,8(a5)
ffffffffc02016aa:	02089313          	slli	t1,a7,0x20
ffffffffc02016ae:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc02016b2:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02016b6:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc02016ba:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc02016be:	0266fa63          	bgeu	a3,t1,ffffffffc02016f2 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02016c2:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc02016c6:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc02016ca:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02016cc:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016d0:	00870313          	addi	t1,a4,8
ffffffffc02016d4:	4889                	li	a7,2
ffffffffc02016d6:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02016da:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc02016de:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc02016e2:	0068b023          	sd	t1,0(a7)
ffffffffc02016e6:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc02016ea:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc02016ee:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc02016f2:	9d95                	subw	a1,a1,a3
ffffffffc02016f4:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02016f6:	5775                	li	a4,-3
ffffffffc02016f8:	17c1                	addi	a5,a5,-16
ffffffffc02016fa:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02016fe:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201700:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201702:	00003697          	auipc	a3,0x3
ffffffffc0201706:	4e668693          	addi	a3,a3,1254 # ffffffffc0204be8 <etext+0xd28>
ffffffffc020170a:	00003617          	auipc	a2,0x3
ffffffffc020170e:	18660613          	addi	a2,a2,390 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0201712:	06200593          	li	a1,98
ffffffffc0201716:	00003517          	auipc	a0,0x3
ffffffffc020171a:	19250513          	addi	a0,a0,402 # ffffffffc02048a8 <etext+0x9e8>
default_alloc_pages(size_t n) {
ffffffffc020171e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201720:	ce7fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201724 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201724:	1141                	addi	sp,sp,-16
ffffffffc0201726:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201728:	c9e1                	beqz	a1,ffffffffc02017f8 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc020172a:	00659713          	slli	a4,a1,0x6
ffffffffc020172e:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201732:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201734:	cf11                	beqz	a4,ffffffffc0201750 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201736:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201738:	8b05                	andi	a4,a4,1
ffffffffc020173a:	cf59                	beqz	a4,ffffffffc02017d8 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc020173c:	0007a823          	sw	zero,16(a5)
ffffffffc0201740:	0007b423          	sd	zero,8(a5)
ffffffffc0201744:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201748:	04078793          	addi	a5,a5,64
ffffffffc020174c:	fed795e3          	bne	a5,a3,ffffffffc0201736 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201750:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201752:	4789                	li	a5,2
ffffffffc0201754:	00850713          	addi	a4,a0,8
ffffffffc0201758:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020175c:	00008717          	auipc	a4,0x8
ffffffffc0201760:	ce472703          	lw	a4,-796(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201764:	00008697          	auipc	a3,0x8
ffffffffc0201768:	ccc68693          	addi	a3,a3,-820 # ffffffffc0209430 <free_area>
    return list->next == list;
ffffffffc020176c:	669c                	ld	a5,8(a3)
ffffffffc020176e:	9f2d                	addw	a4,a4,a1
ffffffffc0201770:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201772:	04d78663          	beq	a5,a3,ffffffffc02017be <default_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201776:	fe878713          	addi	a4,a5,-24
ffffffffc020177a:	4581                	li	a1,0
ffffffffc020177c:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201780:	00e56a63          	bltu	a0,a4,ffffffffc0201794 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201784:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201786:	02d70263          	beq	a4,a3,ffffffffc02017aa <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc020178a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020178c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201790:	fee57ae3          	bgeu	a0,a4,ffffffffc0201784 <default_init_memmap+0x60>
ffffffffc0201794:	c199                	beqz	a1,ffffffffc020179a <default_init_memmap+0x76>
ffffffffc0201796:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020179a:	6398                	ld	a4,0(a5)
}
ffffffffc020179c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020179e:	e390                	sd	a2,0(a5)
ffffffffc02017a0:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02017a2:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02017a4:	f11c                	sd	a5,32(a0)
ffffffffc02017a6:	0141                	addi	sp,sp,16
ffffffffc02017a8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017aa:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017ac:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017ae:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017b0:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02017b2:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02017b4:	00d70e63          	beq	a4,a3,ffffffffc02017d0 <default_init_memmap+0xac>
ffffffffc02017b8:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02017ba:	87ba                	mv	a5,a4
ffffffffc02017bc:	bfc1                	j	ffffffffc020178c <default_init_memmap+0x68>
}
ffffffffc02017be:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02017c0:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02017c4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017c6:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02017c8:	e398                	sd	a4,0(a5)
ffffffffc02017ca:	e798                	sd	a4,8(a5)
}
ffffffffc02017cc:	0141                	addi	sp,sp,16
ffffffffc02017ce:	8082                	ret
ffffffffc02017d0:	60a2                	ld	ra,8(sp)
ffffffffc02017d2:	e290                	sd	a2,0(a3)
ffffffffc02017d4:	0141                	addi	sp,sp,16
ffffffffc02017d6:	8082                	ret
        assert(PageReserved(p));
ffffffffc02017d8:	00003697          	auipc	a3,0x3
ffffffffc02017dc:	44068693          	addi	a3,a3,1088 # ffffffffc0204c18 <etext+0xd58>
ffffffffc02017e0:	00003617          	auipc	a2,0x3
ffffffffc02017e4:	0b060613          	addi	a2,a2,176 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02017e8:	04900593          	li	a1,73
ffffffffc02017ec:	00003517          	auipc	a0,0x3
ffffffffc02017f0:	0bc50513          	addi	a0,a0,188 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc02017f4:	c13fe0ef          	jal	ffffffffc0200406 <__panic>
    assert(n > 0);
ffffffffc02017f8:	00003697          	auipc	a3,0x3
ffffffffc02017fc:	3f068693          	addi	a3,a3,1008 # ffffffffc0204be8 <etext+0xd28>
ffffffffc0201800:	00003617          	auipc	a2,0x3
ffffffffc0201804:	09060613          	addi	a2,a2,144 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0201808:	04600593          	li	a1,70
ffffffffc020180c:	00003517          	auipc	a0,0x3
ffffffffc0201810:	09c50513          	addi	a0,a0,156 # ffffffffc02048a8 <etext+0x9e8>
ffffffffc0201814:	bf3fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201818 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201818:	c531                	beqz	a0,ffffffffc0201864 <slob_free+0x4c>
		return;

	if (size)
ffffffffc020181a:	e9b9                	bnez	a1,ffffffffc0201870 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020181c:	100027f3          	csrr	a5,sstatus
ffffffffc0201820:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201822:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201824:	efb1                	bnez	a5,ffffffffc0201880 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201826:	00007797          	auipc	a5,0x7
ffffffffc020182a:	7fa7b783          	ld	a5,2042(a5) # ffffffffc0209020 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020182e:	873e                	mv	a4,a5
ffffffffc0201830:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201832:	02a77a63          	bgeu	a4,a0,ffffffffc0201866 <slob_free+0x4e>
ffffffffc0201836:	00f56463          	bltu	a0,a5,ffffffffc020183e <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020183a:	fef76ae3          	bltu	a4,a5,ffffffffc020182e <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc020183e:	4110                	lw	a2,0(a0)
ffffffffc0201840:	00461693          	slli	a3,a2,0x4
ffffffffc0201844:	96aa                	add	a3,a3,a0
ffffffffc0201846:	0ad78463          	beq	a5,a3,ffffffffc02018ee <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc020184a:	4310                	lw	a2,0(a4)
ffffffffc020184c:	e51c                	sd	a5,8(a0)
ffffffffc020184e:	00461693          	slli	a3,a2,0x4
ffffffffc0201852:	96ba                	add	a3,a3,a4
ffffffffc0201854:	08d50163          	beq	a0,a3,ffffffffc02018d6 <slob_free+0xbe>
ffffffffc0201858:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc020185a:	00007797          	auipc	a5,0x7
ffffffffc020185e:	7ce7b323          	sd	a4,1990(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc0201862:	e9a5                	bnez	a1,ffffffffc02018d2 <slob_free+0xba>
ffffffffc0201864:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201866:	fcf574e3          	bgeu	a0,a5,ffffffffc020182e <slob_free+0x16>
ffffffffc020186a:	fcf762e3          	bltu	a4,a5,ffffffffc020182e <slob_free+0x16>
ffffffffc020186e:	bfc1                	j	ffffffffc020183e <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201870:	25bd                	addiw	a1,a1,15
ffffffffc0201872:	8191                	srli	a1,a1,0x4
ffffffffc0201874:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201876:	100027f3          	csrr	a5,sstatus
ffffffffc020187a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020187c:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020187e:	d7c5                	beqz	a5,ffffffffc0201826 <slob_free+0xe>
{
ffffffffc0201880:	1101                	addi	sp,sp,-32
ffffffffc0201882:	e42a                	sd	a0,8(sp)
ffffffffc0201884:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201886:	feffe0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc020188a:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020188c:	00007797          	auipc	a5,0x7
ffffffffc0201890:	7947b783          	ld	a5,1940(a5) # ffffffffc0209020 <slobfree>
ffffffffc0201894:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201896:	873e                	mv	a4,a5
ffffffffc0201898:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020189a:	06a77663          	bgeu	a4,a0,ffffffffc0201906 <slob_free+0xee>
ffffffffc020189e:	00f56463          	bltu	a0,a5,ffffffffc02018a6 <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018a2:	fef76ae3          	bltu	a4,a5,ffffffffc0201896 <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc02018a6:	4110                	lw	a2,0(a0)
ffffffffc02018a8:	00461693          	slli	a3,a2,0x4
ffffffffc02018ac:	96aa                	add	a3,a3,a0
ffffffffc02018ae:	06d78363          	beq	a5,a3,ffffffffc0201914 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc02018b2:	4310                	lw	a2,0(a4)
ffffffffc02018b4:	e51c                	sd	a5,8(a0)
ffffffffc02018b6:	00461693          	slli	a3,a2,0x4
ffffffffc02018ba:	96ba                	add	a3,a3,a4
ffffffffc02018bc:	06d50163          	beq	a0,a3,ffffffffc020191e <slob_free+0x106>
ffffffffc02018c0:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc02018c2:	00007797          	auipc	a5,0x7
ffffffffc02018c6:	74e7bf23          	sd	a4,1886(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc02018ca:	e1a9                	bnez	a1,ffffffffc020190c <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02018cc:	60e2                	ld	ra,24(sp)
ffffffffc02018ce:	6105                	addi	sp,sp,32
ffffffffc02018d0:	8082                	ret
        intr_enable();
ffffffffc02018d2:	f9dfe06f          	j	ffffffffc020086e <intr_enable>
		cur->units += b->units;
ffffffffc02018d6:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc02018d8:	853e                	mv	a0,a5
ffffffffc02018da:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc02018dc:	00c687bb          	addw	a5,a3,a2
ffffffffc02018e0:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc02018e2:	00007797          	auipc	a5,0x7
ffffffffc02018e6:	72e7bf23          	sd	a4,1854(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc02018ea:	ddad                	beqz	a1,ffffffffc0201864 <slob_free+0x4c>
ffffffffc02018ec:	b7dd                	j	ffffffffc02018d2 <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc02018ee:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02018f0:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02018f2:	9eb1                	addw	a3,a3,a2
ffffffffc02018f4:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc02018f6:	4310                	lw	a2,0(a4)
ffffffffc02018f8:	e51c                	sd	a5,8(a0)
ffffffffc02018fa:	00461693          	slli	a3,a2,0x4
ffffffffc02018fe:	96ba                	add	a3,a3,a4
ffffffffc0201900:	f4d51ce3          	bne	a0,a3,ffffffffc0201858 <slob_free+0x40>
ffffffffc0201904:	bfc9                	j	ffffffffc02018d6 <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201906:	f8f56ee3          	bltu	a0,a5,ffffffffc02018a2 <slob_free+0x8a>
ffffffffc020190a:	b771                	j	ffffffffc0201896 <slob_free+0x7e>
}
ffffffffc020190c:	60e2                	ld	ra,24(sp)
ffffffffc020190e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201910:	f5ffe06f          	j	ffffffffc020086e <intr_enable>
		b->units += cur->next->units;
ffffffffc0201914:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201916:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201918:	9eb1                	addw	a3,a3,a2
ffffffffc020191a:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc020191c:	bf59                	j	ffffffffc02018b2 <slob_free+0x9a>
		cur->units += b->units;
ffffffffc020191e:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201920:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201922:	00c687bb          	addw	a5,a3,a2
ffffffffc0201926:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201928:	bf61                	j	ffffffffc02018c0 <slob_free+0xa8>

ffffffffc020192a <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc020192a:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020192c:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc020192e:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201932:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201934:	326000ef          	jal	ffffffffc0201c5a <alloc_pages>
	if (!page)
ffffffffc0201938:	c91d                	beqz	a0,ffffffffc020196e <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc020193a:	0000c697          	auipc	a3,0xc
ffffffffc020193e:	b8e6b683          	ld	a3,-1138(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201942:	00004797          	auipc	a5,0x4
ffffffffc0201946:	0ce7b783          	ld	a5,206(a5) # ffffffffc0205a10 <nbase>
    return KADDR(page2pa(page));
ffffffffc020194a:	0000c717          	auipc	a4,0xc
ffffffffc020194e:	b7673703          	ld	a4,-1162(a4) # ffffffffc020d4c0 <npage>
    return page - pages + nbase;
ffffffffc0201952:	8d15                	sub	a0,a0,a3
ffffffffc0201954:	8519                	srai	a0,a0,0x6
ffffffffc0201956:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201958:	00c51793          	slli	a5,a0,0xc
ffffffffc020195c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020195e:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201960:	00e7fa63          	bgeu	a5,a4,ffffffffc0201974 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201964:	0000c797          	auipc	a5,0xc
ffffffffc0201968:	b547b783          	ld	a5,-1196(a5) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc020196c:	953e                	add	a0,a0,a5
}
ffffffffc020196e:	60a2                	ld	ra,8(sp)
ffffffffc0201970:	0141                	addi	sp,sp,16
ffffffffc0201972:	8082                	ret
ffffffffc0201974:	86aa                	mv	a3,a0
ffffffffc0201976:	00003617          	auipc	a2,0x3
ffffffffc020197a:	2ca60613          	addi	a2,a2,714 # ffffffffc0204c40 <etext+0xd80>
ffffffffc020197e:	07100593          	li	a1,113
ffffffffc0201982:	00003517          	auipc	a0,0x3
ffffffffc0201986:	2e650513          	addi	a0,a0,742 # ffffffffc0204c68 <etext+0xda8>
ffffffffc020198a:	a7dfe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020198e <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc020198e:	7179                	addi	sp,sp,-48
ffffffffc0201990:	f406                	sd	ra,40(sp)
ffffffffc0201992:	f022                	sd	s0,32(sp)
ffffffffc0201994:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201996:	01050713          	addi	a4,a0,16
ffffffffc020199a:	6785                	lui	a5,0x1
ffffffffc020199c:	0af77e63          	bgeu	a4,a5,ffffffffc0201a58 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019a0:	00f50413          	addi	s0,a0,15
ffffffffc02019a4:	8011                	srli	s0,s0,0x4
ffffffffc02019a6:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019a8:	100025f3          	csrr	a1,sstatus
ffffffffc02019ac:	8989                	andi	a1,a1,2
ffffffffc02019ae:	edd1                	bnez	a1,ffffffffc0201a4a <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc02019b0:	00007497          	auipc	s1,0x7
ffffffffc02019b4:	67048493          	addi	s1,s1,1648 # ffffffffc0209020 <slobfree>
ffffffffc02019b8:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019ba:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc02019bc:	4314                	lw	a3,0(a4)
ffffffffc02019be:	0886da63          	bge	a3,s0,ffffffffc0201a52 <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc02019c2:	00e60a63          	beq	a2,a4,ffffffffc02019d6 <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019c6:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc02019c8:	4394                	lw	a3,0(a5)
ffffffffc02019ca:	0286d863          	bge	a3,s0,ffffffffc02019fa <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc02019ce:	6090                	ld	a2,0(s1)
ffffffffc02019d0:	873e                	mv	a4,a5
ffffffffc02019d2:	fee61ae3          	bne	a2,a4,ffffffffc02019c6 <slob_alloc.constprop.0+0x38>
    if (flag) {
ffffffffc02019d6:	e9b1                	bnez	a1,ffffffffc0201a2a <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02019d8:	4501                	li	a0,0
ffffffffc02019da:	f51ff0ef          	jal	ffffffffc020192a <__slob_get_free_pages.constprop.0>
ffffffffc02019de:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc02019e0:	c915                	beqz	a0,ffffffffc0201a14 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc02019e2:	6585                	lui	a1,0x1
ffffffffc02019e4:	e35ff0ef          	jal	ffffffffc0201818 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019e8:	100025f3          	csrr	a1,sstatus
ffffffffc02019ec:	8989                	andi	a1,a1,2
ffffffffc02019ee:	e98d                	bnez	a1,ffffffffc0201a20 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc02019f0:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019f2:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc02019f4:	4394                	lw	a3,0(a5)
ffffffffc02019f6:	fc86cce3          	blt	a3,s0,ffffffffc02019ce <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc02019fa:	04d40563          	beq	s0,a3,ffffffffc0201a44 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc02019fe:	00441613          	slli	a2,s0,0x4
ffffffffc0201a02:	963e                	add	a2,a2,a5
ffffffffc0201a04:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201a06:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201a08:	9e81                	subw	a3,a3,s0
ffffffffc0201a0a:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201a0c:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201a0e:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201a10:	e098                	sd	a4,0(s1)
    if (flag) {
ffffffffc0201a12:	ed99                	bnez	a1,ffffffffc0201a30 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201a14:	70a2                	ld	ra,40(sp)
ffffffffc0201a16:	7402                	ld	s0,32(sp)
ffffffffc0201a18:	64e2                	ld	s1,24(sp)
ffffffffc0201a1a:	853e                	mv	a0,a5
ffffffffc0201a1c:	6145                	addi	sp,sp,48
ffffffffc0201a1e:	8082                	ret
        intr_disable();
ffffffffc0201a20:	e55fe0ef          	jal	ffffffffc0200874 <intr_disable>
			cur = slobfree;
ffffffffc0201a24:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201a26:	4585                	li	a1,1
ffffffffc0201a28:	b7e9                	j	ffffffffc02019f2 <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201a2a:	e45fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201a2e:	b76d                	j	ffffffffc02019d8 <slob_alloc.constprop.0+0x4a>
ffffffffc0201a30:	e43e                	sd	a5,8(sp)
ffffffffc0201a32:	e3dfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201a36:	67a2                	ld	a5,8(sp)
}
ffffffffc0201a38:	70a2                	ld	ra,40(sp)
ffffffffc0201a3a:	7402                	ld	s0,32(sp)
ffffffffc0201a3c:	64e2                	ld	s1,24(sp)
ffffffffc0201a3e:	853e                	mv	a0,a5
ffffffffc0201a40:	6145                	addi	sp,sp,48
ffffffffc0201a42:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a44:	6794                	ld	a3,8(a5)
ffffffffc0201a46:	e714                	sd	a3,8(a4)
ffffffffc0201a48:	b7e1                	j	ffffffffc0201a10 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201a4a:	e2bfe0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc0201a4e:	4585                	li	a1,1
ffffffffc0201a50:	b785                	j	ffffffffc02019b0 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a52:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201a54:	8732                	mv	a4,a2
ffffffffc0201a56:	b755                	j	ffffffffc02019fa <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a58:	00003697          	auipc	a3,0x3
ffffffffc0201a5c:	22068693          	addi	a3,a3,544 # ffffffffc0204c78 <etext+0xdb8>
ffffffffc0201a60:	00003617          	auipc	a2,0x3
ffffffffc0201a64:	e3060613          	addi	a2,a2,-464 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0201a68:	06400593          	li	a1,100
ffffffffc0201a6c:	00003517          	auipc	a0,0x3
ffffffffc0201a70:	22c50513          	addi	a0,a0,556 # ffffffffc0204c98 <etext+0xdd8>
ffffffffc0201a74:	993fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201a78 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201a78:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201a7a:	00003517          	auipc	a0,0x3
ffffffffc0201a7e:	23650513          	addi	a0,a0,566 # ffffffffc0204cb0 <etext+0xdf0>
{
ffffffffc0201a82:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201a84:	f10fe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201a88:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a8a:	00003517          	auipc	a0,0x3
ffffffffc0201a8e:	23e50513          	addi	a0,a0,574 # ffffffffc0204cc8 <etext+0xe08>
}
ffffffffc0201a92:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a94:	f00fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201a98 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201a98:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a9a:	6685                	lui	a3,0x1
{
ffffffffc0201a9c:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a9e:	16bd                	addi	a3,a3,-17 # fef <kern_entry-0xffffffffc01ff011>
ffffffffc0201aa0:	04a6f963          	bgeu	a3,a0,ffffffffc0201af2 <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201aa4:	e42a                	sd	a0,8(sp)
ffffffffc0201aa6:	4561                	li	a0,24
ffffffffc0201aa8:	e822                	sd	s0,16(sp)
ffffffffc0201aaa:	ee5ff0ef          	jal	ffffffffc020198e <slob_alloc.constprop.0>
ffffffffc0201aae:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201ab0:	c541                	beqz	a0,ffffffffc0201b38 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201ab2:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201ab4:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201ab6:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ab8:	00f75763          	bge	a4,a5,ffffffffc0201ac6 <kmalloc+0x2e>
ffffffffc0201abc:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201ac0:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201ac2:	fef74de3          	blt	a4,a5,ffffffffc0201abc <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201ac6:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201ac8:	e63ff0ef          	jal	ffffffffc020192a <__slob_get_free_pages.constprop.0>
ffffffffc0201acc:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201ace:	cd31                	beqz	a0,ffffffffc0201b2a <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ad0:	100027f3          	csrr	a5,sstatus
ffffffffc0201ad4:	8b89                	andi	a5,a5,2
ffffffffc0201ad6:	eb85                	bnez	a5,ffffffffc0201b06 <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201ad8:	0000c797          	auipc	a5,0xc
ffffffffc0201adc:	9c07b783          	ld	a5,-1600(a5) # ffffffffc020d498 <bigblocks>
		bigblocks = bb;
ffffffffc0201ae0:	0000c717          	auipc	a4,0xc
ffffffffc0201ae4:	9a873c23          	sd	s0,-1608(a4) # ffffffffc020d498 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201ae8:	e81c                	sd	a5,16(s0)
    if (flag) {
ffffffffc0201aea:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201aec:	60e2                	ld	ra,24(sp)
ffffffffc0201aee:	6105                	addi	sp,sp,32
ffffffffc0201af0:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201af2:	0541                	addi	a0,a0,16
ffffffffc0201af4:	e9bff0ef          	jal	ffffffffc020198e <slob_alloc.constprop.0>
ffffffffc0201af8:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201afa:	0541                	addi	a0,a0,16
ffffffffc0201afc:	fbe5                	bnez	a5,ffffffffc0201aec <kmalloc+0x54>
		return 0;
ffffffffc0201afe:	4501                	li	a0,0
}
ffffffffc0201b00:	60e2                	ld	ra,24(sp)
ffffffffc0201b02:	6105                	addi	sp,sp,32
ffffffffc0201b04:	8082                	ret
        intr_disable();
ffffffffc0201b06:	d6ffe0ef          	jal	ffffffffc0200874 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b0a:	0000c797          	auipc	a5,0xc
ffffffffc0201b0e:	98e7b783          	ld	a5,-1650(a5) # ffffffffc020d498 <bigblocks>
		bigblocks = bb;
ffffffffc0201b12:	0000c717          	auipc	a4,0xc
ffffffffc0201b16:	98873323          	sd	s0,-1658(a4) # ffffffffc020d498 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201b1a:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201b1c:	d53fe0ef          	jal	ffffffffc020086e <intr_enable>
		return bb->pages;
ffffffffc0201b20:	6408                	ld	a0,8(s0)
}
ffffffffc0201b22:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201b24:	6442                	ld	s0,16(sp)
}
ffffffffc0201b26:	6105                	addi	sp,sp,32
ffffffffc0201b28:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b2a:	8522                	mv	a0,s0
ffffffffc0201b2c:	45e1                	li	a1,24
ffffffffc0201b2e:	cebff0ef          	jal	ffffffffc0201818 <slob_free>
		return 0;
ffffffffc0201b32:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b34:	6442                	ld	s0,16(sp)
ffffffffc0201b36:	b7e9                	j	ffffffffc0201b00 <kmalloc+0x68>
ffffffffc0201b38:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201b3a:	4501                	li	a0,0
ffffffffc0201b3c:	b7d1                	j	ffffffffc0201b00 <kmalloc+0x68>

ffffffffc0201b3e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b3e:	c571                	beqz	a0,ffffffffc0201c0a <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201b40:	03451793          	slli	a5,a0,0x34
ffffffffc0201b44:	e3e1                	bnez	a5,ffffffffc0201c04 <kfree+0xc6>
{
ffffffffc0201b46:	1101                	addi	sp,sp,-32
ffffffffc0201b48:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b4a:	100027f3          	csrr	a5,sstatus
ffffffffc0201b4e:	8b89                	andi	a5,a5,2
ffffffffc0201b50:	e7c1                	bnez	a5,ffffffffc0201bd8 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b52:	0000c797          	auipc	a5,0xc
ffffffffc0201b56:	9467b783          	ld	a5,-1722(a5) # ffffffffc020d498 <bigblocks>
    return 0;
ffffffffc0201b5a:	4581                	li	a1,0
ffffffffc0201b5c:	cbad                	beqz	a5,ffffffffc0201bce <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b5e:	0000c617          	auipc	a2,0xc
ffffffffc0201b62:	93a60613          	addi	a2,a2,-1734 # ffffffffc020d498 <bigblocks>
ffffffffc0201b66:	a021                	j	ffffffffc0201b6e <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b68:	01070613          	addi	a2,a4,16
ffffffffc0201b6c:	c3a5                	beqz	a5,ffffffffc0201bcc <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201b6e:	6794                	ld	a3,8(a5)
ffffffffc0201b70:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201b72:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201b74:	fea69ae3          	bne	a3,a0,ffffffffc0201b68 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201b78:	e21c                	sd	a5,0(a2)
    if (flag) {
ffffffffc0201b7a:	edb5                	bnez	a1,ffffffffc0201bf6 <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201b7c:	c02007b7          	lui	a5,0xc0200
ffffffffc0201b80:	0af56263          	bltu	a0,a5,ffffffffc0201c24 <kfree+0xe6>
ffffffffc0201b84:	0000c797          	auipc	a5,0xc
ffffffffc0201b88:	9347b783          	ld	a5,-1740(a5) # ffffffffc020d4b8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201b8c:	0000c697          	auipc	a3,0xc
ffffffffc0201b90:	9346b683          	ld	a3,-1740(a3) # ffffffffc020d4c0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201b94:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201b96:	00c55793          	srli	a5,a0,0xc
ffffffffc0201b9a:	06d7f963          	bgeu	a5,a3,ffffffffc0201c0c <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b9e:	00004617          	auipc	a2,0x4
ffffffffc0201ba2:	e7263603          	ld	a2,-398(a2) # ffffffffc0205a10 <nbase>
ffffffffc0201ba6:	0000c517          	auipc	a0,0xc
ffffffffc0201baa:	92253503          	ld	a0,-1758(a0) # ffffffffc020d4c8 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201bae:	4314                	lw	a3,0(a4)
ffffffffc0201bb0:	8f91                	sub	a5,a5,a2
ffffffffc0201bb2:	079a                	slli	a5,a5,0x6
ffffffffc0201bb4:	4585                	li	a1,1
ffffffffc0201bb6:	953e                	add	a0,a0,a5
ffffffffc0201bb8:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201bbc:	e03a                	sd	a4,0(sp)
ffffffffc0201bbe:	0d6000ef          	jal	ffffffffc0201c94 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bc2:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201bc4:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bc6:	45e1                	li	a1,24
}
ffffffffc0201bc8:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bca:	b1b9                	j	ffffffffc0201818 <slob_free>
ffffffffc0201bcc:	e185                	bnez	a1,ffffffffc0201bec <kfree+0xae>
}
ffffffffc0201bce:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201bd0:	1541                	addi	a0,a0,-16
ffffffffc0201bd2:	4581                	li	a1,0
}
ffffffffc0201bd4:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201bd6:	b189                	j	ffffffffc0201818 <slob_free>
        intr_disable();
ffffffffc0201bd8:	e02a                	sd	a0,0(sp)
ffffffffc0201bda:	c9bfe0ef          	jal	ffffffffc0200874 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201bde:	0000c797          	auipc	a5,0xc
ffffffffc0201be2:	8ba7b783          	ld	a5,-1862(a5) # ffffffffc020d498 <bigblocks>
ffffffffc0201be6:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201be8:	4585                	li	a1,1
ffffffffc0201bea:	fbb5                	bnez	a5,ffffffffc0201b5e <kfree+0x20>
ffffffffc0201bec:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201bee:	c81fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201bf2:	6502                	ld	a0,0(sp)
ffffffffc0201bf4:	bfe9                	j	ffffffffc0201bce <kfree+0x90>
ffffffffc0201bf6:	e42a                	sd	a0,8(sp)
ffffffffc0201bf8:	e03a                	sd	a4,0(sp)
ffffffffc0201bfa:	c75fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201bfe:	6522                	ld	a0,8(sp)
ffffffffc0201c00:	6702                	ld	a4,0(sp)
ffffffffc0201c02:	bfad                	j	ffffffffc0201b7c <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c04:	1541                	addi	a0,a0,-16
ffffffffc0201c06:	4581                	li	a1,0
ffffffffc0201c08:	b901                	j	ffffffffc0201818 <slob_free>
ffffffffc0201c0a:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c0c:	00003617          	auipc	a2,0x3
ffffffffc0201c10:	10460613          	addi	a2,a2,260 # ffffffffc0204d10 <etext+0xe50>
ffffffffc0201c14:	06900593          	li	a1,105
ffffffffc0201c18:	00003517          	auipc	a0,0x3
ffffffffc0201c1c:	05050513          	addi	a0,a0,80 # ffffffffc0204c68 <etext+0xda8>
ffffffffc0201c20:	fe6fe0ef          	jal	ffffffffc0200406 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c24:	86aa                	mv	a3,a0
ffffffffc0201c26:	00003617          	auipc	a2,0x3
ffffffffc0201c2a:	0c260613          	addi	a2,a2,194 # ffffffffc0204ce8 <etext+0xe28>
ffffffffc0201c2e:	07700593          	li	a1,119
ffffffffc0201c32:	00003517          	auipc	a0,0x3
ffffffffc0201c36:	03650513          	addi	a0,a0,54 # ffffffffc0204c68 <etext+0xda8>
ffffffffc0201c3a:	fccfe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201c3e <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201c3e:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c40:	00003617          	auipc	a2,0x3
ffffffffc0201c44:	0d060613          	addi	a2,a2,208 # ffffffffc0204d10 <etext+0xe50>
ffffffffc0201c48:	06900593          	li	a1,105
ffffffffc0201c4c:	00003517          	auipc	a0,0x3
ffffffffc0201c50:	01c50513          	addi	a0,a0,28 # ffffffffc0204c68 <etext+0xda8>
pa2page(uintptr_t pa)
ffffffffc0201c54:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c56:	fb0fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201c5a <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c5a:	100027f3          	csrr	a5,sstatus
ffffffffc0201c5e:	8b89                	andi	a5,a5,2
ffffffffc0201c60:	e799                	bnez	a5,ffffffffc0201c6e <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c62:	0000c797          	auipc	a5,0xc
ffffffffc0201c66:	83e7b783          	ld	a5,-1986(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201c6a:	6f9c                	ld	a5,24(a5)
ffffffffc0201c6c:	8782                	jr	a5
{
ffffffffc0201c6e:	1101                	addi	sp,sp,-32
ffffffffc0201c70:	ec06                	sd	ra,24(sp)
ffffffffc0201c72:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201c74:	c01fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c78:	0000c797          	auipc	a5,0xc
ffffffffc0201c7c:	8287b783          	ld	a5,-2008(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201c80:	6522                	ld	a0,8(sp)
ffffffffc0201c82:	6f9c                	ld	a5,24(a5)
ffffffffc0201c84:	9782                	jalr	a5
ffffffffc0201c86:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201c88:	be7fe0ef          	jal	ffffffffc020086e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201c8c:	60e2                	ld	ra,24(sp)
ffffffffc0201c8e:	6522                	ld	a0,8(sp)
ffffffffc0201c90:	6105                	addi	sp,sp,32
ffffffffc0201c92:	8082                	ret

ffffffffc0201c94 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c94:	100027f3          	csrr	a5,sstatus
ffffffffc0201c98:	8b89                	andi	a5,a5,2
ffffffffc0201c9a:	e799                	bnez	a5,ffffffffc0201ca8 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201c9c:	0000c797          	auipc	a5,0xc
ffffffffc0201ca0:	8047b783          	ld	a5,-2044(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201ca4:	739c                	ld	a5,32(a5)
ffffffffc0201ca6:	8782                	jr	a5
{
ffffffffc0201ca8:	1101                	addi	sp,sp,-32
ffffffffc0201caa:	ec06                	sd	ra,24(sp)
ffffffffc0201cac:	e42e                	sd	a1,8(sp)
ffffffffc0201cae:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201cb0:	bc5fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201cb4:	0000b797          	auipc	a5,0xb
ffffffffc0201cb8:	7ec7b783          	ld	a5,2028(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cbc:	65a2                	ld	a1,8(sp)
ffffffffc0201cbe:	6502                	ld	a0,0(sp)
ffffffffc0201cc0:	739c                	ld	a5,32(a5)
ffffffffc0201cc2:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201cc4:	60e2                	ld	ra,24(sp)
ffffffffc0201cc6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201cc8:	ba7fe06f          	j	ffffffffc020086e <intr_enable>

ffffffffc0201ccc <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ccc:	100027f3          	csrr	a5,sstatus
ffffffffc0201cd0:	8b89                	andi	a5,a5,2
ffffffffc0201cd2:	e799                	bnez	a5,ffffffffc0201ce0 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201cd4:	0000b797          	auipc	a5,0xb
ffffffffc0201cd8:	7cc7b783          	ld	a5,1996(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cdc:	779c                	ld	a5,40(a5)
ffffffffc0201cde:	8782                	jr	a5
{
ffffffffc0201ce0:	1101                	addi	sp,sp,-32
ffffffffc0201ce2:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201ce4:	b91fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ce8:	0000b797          	auipc	a5,0xb
ffffffffc0201cec:	7b87b783          	ld	a5,1976(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201cf0:	779c                	ld	a5,40(a5)
ffffffffc0201cf2:	9782                	jalr	a5
ffffffffc0201cf4:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201cf6:	b79fe0ef          	jal	ffffffffc020086e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201cfa:	60e2                	ld	ra,24(sp)
ffffffffc0201cfc:	6522                	ld	a0,8(sp)
ffffffffc0201cfe:	6105                	addi	sp,sp,32
ffffffffc0201d00:	8082                	ret

ffffffffc0201d02 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d02:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201d06:	1ff7f793          	andi	a5,a5,511
ffffffffc0201d0a:	078e                	slli	a5,a5,0x3
ffffffffc0201d0c:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201d10:	6314                	ld	a3,0(a4)
{
ffffffffc0201d12:	7139                	addi	sp,sp,-64
ffffffffc0201d14:	f822                	sd	s0,48(sp)
ffffffffc0201d16:	f426                	sd	s1,40(sp)
ffffffffc0201d18:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201d1a:	0016f793          	andi	a5,a3,1
{
ffffffffc0201d1e:	842e                	mv	s0,a1
ffffffffc0201d20:	8832                	mv	a6,a2
ffffffffc0201d22:	0000b497          	auipc	s1,0xb
ffffffffc0201d26:	79e48493          	addi	s1,s1,1950 # ffffffffc020d4c0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201d2a:	ebd1                	bnez	a5,ffffffffc0201dbe <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d2c:	16060d63          	beqz	a2,ffffffffc0201ea6 <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d30:	100027f3          	csrr	a5,sstatus
ffffffffc0201d34:	8b89                	andi	a5,a5,2
ffffffffc0201d36:	16079e63          	bnez	a5,ffffffffc0201eb2 <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d3a:	0000b797          	auipc	a5,0xb
ffffffffc0201d3e:	7667b783          	ld	a5,1894(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201d42:	4505                	li	a0,1
ffffffffc0201d44:	e43a                	sd	a4,8(sp)
ffffffffc0201d46:	6f9c                	ld	a5,24(a5)
ffffffffc0201d48:	e832                	sd	a2,16(sp)
ffffffffc0201d4a:	9782                	jalr	a5
ffffffffc0201d4c:	6722                	ld	a4,8(sp)
ffffffffc0201d4e:	6842                	ld	a6,16(sp)
ffffffffc0201d50:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d52:	14078a63          	beqz	a5,ffffffffc0201ea6 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201d56:	0000b517          	auipc	a0,0xb
ffffffffc0201d5a:	77253503          	ld	a0,1906(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201d5e:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201d62:	0000b497          	auipc	s1,0xb
ffffffffc0201d66:	75e48493          	addi	s1,s1,1886 # ffffffffc020d4c0 <npage>
ffffffffc0201d6a:	40a78533          	sub	a0,a5,a0
ffffffffc0201d6e:	8519                	srai	a0,a0,0x6
ffffffffc0201d70:	9546                	add	a0,a0,a7
ffffffffc0201d72:	6090                	ld	a2,0(s1)
ffffffffc0201d74:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201d78:	4585                	li	a1,1
ffffffffc0201d7a:	82b1                	srli	a3,a3,0xc
ffffffffc0201d7c:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d7e:	0532                	slli	a0,a0,0xc
ffffffffc0201d80:	1ac6f763          	bgeu	a3,a2,ffffffffc0201f2e <get_pte+0x22c>
ffffffffc0201d84:	0000b697          	auipc	a3,0xb
ffffffffc0201d88:	7346b683          	ld	a3,1844(a3) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201d8c:	6605                	lui	a2,0x1
ffffffffc0201d8e:	4581                	li	a1,0
ffffffffc0201d90:	9536                	add	a0,a0,a3
ffffffffc0201d92:	ec42                	sd	a6,24(sp)
ffffffffc0201d94:	e83e                	sd	a5,16(sp)
ffffffffc0201d96:	e43a                	sd	a4,8(sp)
ffffffffc0201d98:	0da020ef          	jal	ffffffffc0203e72 <memset>
    return page - pages + nbase;
ffffffffc0201d9c:	0000b697          	auipc	a3,0xb
ffffffffc0201da0:	72c6b683          	ld	a3,1836(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201da4:	67c2                	ld	a5,16(sp)
ffffffffc0201da6:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201daa:	6722                	ld	a4,8(sp)
ffffffffc0201dac:	40d786b3          	sub	a3,a5,a3
ffffffffc0201db0:	8699                	srai	a3,a3,0x6
ffffffffc0201db2:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201db4:	06aa                	slli	a3,a3,0xa
ffffffffc0201db6:	6862                	ld	a6,24(sp)
ffffffffc0201db8:	0116e693          	ori	a3,a3,17
ffffffffc0201dbc:	e314                	sd	a3,0(a4)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201dbe:	c006f693          	andi	a3,a3,-1024
ffffffffc0201dc2:	6098                	ld	a4,0(s1)
ffffffffc0201dc4:	068a                	slli	a3,a3,0x2
ffffffffc0201dc6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201dca:	14e7f663          	bgeu	a5,a4,ffffffffc0201f16 <get_pte+0x214>
ffffffffc0201dce:	0000b897          	auipc	a7,0xb
ffffffffc0201dd2:	6ea88893          	addi	a7,a7,1770 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201dd6:	0008b603          	ld	a2,0(a7)
ffffffffc0201dda:	01545793          	srli	a5,s0,0x15
ffffffffc0201dde:	1ff7f793          	andi	a5,a5,511
ffffffffc0201de2:	96b2                	add	a3,a3,a2
ffffffffc0201de4:	078e                	slli	a5,a5,0x3
ffffffffc0201de6:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201de8:	6394                	ld	a3,0(a5)
ffffffffc0201dea:	0016f613          	andi	a2,a3,1
ffffffffc0201dee:	e659                	bnez	a2,ffffffffc0201e7c <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201df0:	0a080b63          	beqz	a6,ffffffffc0201ea6 <get_pte+0x1a4>
ffffffffc0201df4:	10002773          	csrr	a4,sstatus
ffffffffc0201df8:	8b09                	andi	a4,a4,2
ffffffffc0201dfa:	ef71                	bnez	a4,ffffffffc0201ed6 <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201dfc:	0000b717          	auipc	a4,0xb
ffffffffc0201e00:	6a473703          	ld	a4,1700(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201e04:	4505                	li	a0,1
ffffffffc0201e06:	e43e                	sd	a5,8(sp)
ffffffffc0201e08:	6f18                	ld	a4,24(a4)
ffffffffc0201e0a:	9702                	jalr	a4
ffffffffc0201e0c:	67a2                	ld	a5,8(sp)
ffffffffc0201e0e:	872a                	mv	a4,a0
ffffffffc0201e10:	0000b897          	auipc	a7,0xb
ffffffffc0201e14:	6a888893          	addi	a7,a7,1704 # ffffffffc020d4b8 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e18:	c759                	beqz	a4,ffffffffc0201ea6 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201e1a:	0000b697          	auipc	a3,0xb
ffffffffc0201e1e:	6ae6b683          	ld	a3,1710(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201e22:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e26:	608c                	ld	a1,0(s1)
ffffffffc0201e28:	40d706b3          	sub	a3,a4,a3
ffffffffc0201e2c:	8699                	srai	a3,a3,0x6
ffffffffc0201e2e:	96c2                	add	a3,a3,a6
ffffffffc0201e30:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0201e34:	4505                	li	a0,1
ffffffffc0201e36:	8231                	srli	a2,a2,0xc
ffffffffc0201e38:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e3a:	06b2                	slli	a3,a3,0xc
ffffffffc0201e3c:	10b67663          	bgeu	a2,a1,ffffffffc0201f48 <get_pte+0x246>
ffffffffc0201e40:	0008b503          	ld	a0,0(a7)
ffffffffc0201e44:	6605                	lui	a2,0x1
ffffffffc0201e46:	4581                	li	a1,0
ffffffffc0201e48:	9536                	add	a0,a0,a3
ffffffffc0201e4a:	e83a                	sd	a4,16(sp)
ffffffffc0201e4c:	e43e                	sd	a5,8(sp)
ffffffffc0201e4e:	024020ef          	jal	ffffffffc0203e72 <memset>
    return page - pages + nbase;
ffffffffc0201e52:	0000b697          	auipc	a3,0xb
ffffffffc0201e56:	6766b683          	ld	a3,1654(a3) # ffffffffc020d4c8 <pages>
ffffffffc0201e5a:	6742                	ld	a4,16(sp)
ffffffffc0201e5c:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e60:	67a2                	ld	a5,8(sp)
ffffffffc0201e62:	40d706b3          	sub	a3,a4,a3
ffffffffc0201e66:	8699                	srai	a3,a3,0x6
ffffffffc0201e68:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e6a:	06aa                	slli	a3,a3,0xa
ffffffffc0201e6c:	0116e693          	ori	a3,a3,17
ffffffffc0201e70:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e72:	6098                	ld	a4,0(s1)
ffffffffc0201e74:	0000b897          	auipc	a7,0xb
ffffffffc0201e78:	64488893          	addi	a7,a7,1604 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201e7c:	c006f693          	andi	a3,a3,-1024
ffffffffc0201e80:	068a                	slli	a3,a3,0x2
ffffffffc0201e82:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e86:	06e7fc63          	bgeu	a5,a4,ffffffffc0201efe <get_pte+0x1fc>
ffffffffc0201e8a:	0008b783          	ld	a5,0(a7)
ffffffffc0201e8e:	8031                	srli	s0,s0,0xc
ffffffffc0201e90:	1ff47413          	andi	s0,s0,511
ffffffffc0201e94:	040e                	slli	s0,s0,0x3
ffffffffc0201e96:	96be                	add	a3,a3,a5
}
ffffffffc0201e98:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e9a:	00868533          	add	a0,a3,s0
}
ffffffffc0201e9e:	7442                	ld	s0,48(sp)
ffffffffc0201ea0:	74a2                	ld	s1,40(sp)
ffffffffc0201ea2:	6121                	addi	sp,sp,64
ffffffffc0201ea4:	8082                	ret
ffffffffc0201ea6:	70e2                	ld	ra,56(sp)
ffffffffc0201ea8:	7442                	ld	s0,48(sp)
ffffffffc0201eaa:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc0201eac:	4501                	li	a0,0
}
ffffffffc0201eae:	6121                	addi	sp,sp,64
ffffffffc0201eb0:	8082                	ret
        intr_disable();
ffffffffc0201eb2:	e83a                	sd	a4,16(sp)
ffffffffc0201eb4:	ec32                	sd	a2,24(sp)
ffffffffc0201eb6:	9bffe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eba:	0000b797          	auipc	a5,0xb
ffffffffc0201ebe:	5e67b783          	ld	a5,1510(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201ec2:	4505                	li	a0,1
ffffffffc0201ec4:	6f9c                	ld	a5,24(a5)
ffffffffc0201ec6:	9782                	jalr	a5
ffffffffc0201ec8:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201eca:	9a5fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201ece:	6862                	ld	a6,24(sp)
ffffffffc0201ed0:	6742                	ld	a4,16(sp)
ffffffffc0201ed2:	67a2                	ld	a5,8(sp)
ffffffffc0201ed4:	bdbd                	j	ffffffffc0201d52 <get_pte+0x50>
        intr_disable();
ffffffffc0201ed6:	e83e                	sd	a5,16(sp)
ffffffffc0201ed8:	99dfe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0201edc:	0000b717          	auipc	a4,0xb
ffffffffc0201ee0:	5c473703          	ld	a4,1476(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0201ee4:	4505                	li	a0,1
ffffffffc0201ee6:	6f18                	ld	a4,24(a4)
ffffffffc0201ee8:	9702                	jalr	a4
ffffffffc0201eea:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201eec:	983fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201ef0:	6722                	ld	a4,8(sp)
ffffffffc0201ef2:	67c2                	ld	a5,16(sp)
ffffffffc0201ef4:	0000b897          	auipc	a7,0xb
ffffffffc0201ef8:	5c488893          	addi	a7,a7,1476 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0201efc:	bf31                	j	ffffffffc0201e18 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201efe:	00003617          	auipc	a2,0x3
ffffffffc0201f02:	d4260613          	addi	a2,a2,-702 # ffffffffc0204c40 <etext+0xd80>
ffffffffc0201f06:	0fb00593          	li	a1,251
ffffffffc0201f0a:	00003517          	auipc	a0,0x3
ffffffffc0201f0e:	e2650513          	addi	a0,a0,-474 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0201f12:	cf4fe0ef          	jal	ffffffffc0200406 <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f16:	00003617          	auipc	a2,0x3
ffffffffc0201f1a:	d2a60613          	addi	a2,a2,-726 # ffffffffc0204c40 <etext+0xd80>
ffffffffc0201f1e:	0ee00593          	li	a1,238
ffffffffc0201f22:	00003517          	auipc	a0,0x3
ffffffffc0201f26:	e0e50513          	addi	a0,a0,-498 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0201f2a:	cdcfe0ef          	jal	ffffffffc0200406 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f2e:	86aa                	mv	a3,a0
ffffffffc0201f30:	00003617          	auipc	a2,0x3
ffffffffc0201f34:	d1060613          	addi	a2,a2,-752 # ffffffffc0204c40 <etext+0xd80>
ffffffffc0201f38:	0eb00593          	li	a1,235
ffffffffc0201f3c:	00003517          	auipc	a0,0x3
ffffffffc0201f40:	df450513          	addi	a0,a0,-524 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0201f44:	cc2fe0ef          	jal	ffffffffc0200406 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f48:	00003617          	auipc	a2,0x3
ffffffffc0201f4c:	cf860613          	addi	a2,a2,-776 # ffffffffc0204c40 <etext+0xd80>
ffffffffc0201f50:	0f800593          	li	a1,248
ffffffffc0201f54:	00003517          	auipc	a0,0x3
ffffffffc0201f58:	ddc50513          	addi	a0,a0,-548 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0201f5c:	caafe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201f60 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201f60:	1141                	addi	sp,sp,-16
ffffffffc0201f62:	e022                	sd	s0,0(sp)
ffffffffc0201f64:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f66:	4601                	li	a2,0
{
ffffffffc0201f68:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f6a:	d99ff0ef          	jal	ffffffffc0201d02 <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f6e:	c011                	beqz	s0,ffffffffc0201f72 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f70:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f72:	c511                	beqz	a0,ffffffffc0201f7e <get_page+0x1e>
ffffffffc0201f74:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f76:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f78:	0017f713          	andi	a4,a5,1
ffffffffc0201f7c:	e709                	bnez	a4,ffffffffc0201f86 <get_page+0x26>
}
ffffffffc0201f7e:	60a2                	ld	ra,8(sp)
ffffffffc0201f80:	6402                	ld	s0,0(sp)
ffffffffc0201f82:	0141                	addi	sp,sp,16
ffffffffc0201f84:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0201f86:	0000b717          	auipc	a4,0xb
ffffffffc0201f8a:	53a73703          	ld	a4,1338(a4) # ffffffffc020d4c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f8e:	078a                	slli	a5,a5,0x2
ffffffffc0201f90:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201f92:	00e7ff63          	bgeu	a5,a4,ffffffffc0201fb0 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f96:	0000b517          	auipc	a0,0xb
ffffffffc0201f9a:	53253503          	ld	a0,1330(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201f9e:	60a2                	ld	ra,8(sp)
ffffffffc0201fa0:	6402                	ld	s0,0(sp)
ffffffffc0201fa2:	079a                	slli	a5,a5,0x6
ffffffffc0201fa4:	fe000737          	lui	a4,0xfe000
ffffffffc0201fa8:	97ba                	add	a5,a5,a4
ffffffffc0201faa:	953e                	add	a0,a0,a5
ffffffffc0201fac:	0141                	addi	sp,sp,16
ffffffffc0201fae:	8082                	ret
ffffffffc0201fb0:	c8fff0ef          	jal	ffffffffc0201c3e <pa2page.part.0>

ffffffffc0201fb4 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201fb4:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fb6:	4601                	li	a2,0
{
ffffffffc0201fb8:	e822                	sd	s0,16(sp)
ffffffffc0201fba:	ec06                	sd	ra,24(sp)
ffffffffc0201fbc:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fbe:	d45ff0ef          	jal	ffffffffc0201d02 <get_pte>
    if (ptep != NULL)
ffffffffc0201fc2:	c511                	beqz	a0,ffffffffc0201fce <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc0201fc4:	6118                	ld	a4,0(a0)
ffffffffc0201fc6:	87aa                	mv	a5,a0
ffffffffc0201fc8:	00177693          	andi	a3,a4,1
ffffffffc0201fcc:	e689                	bnez	a3,ffffffffc0201fd6 <page_remove+0x22>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201fce:	60e2                	ld	ra,24(sp)
ffffffffc0201fd0:	6442                	ld	s0,16(sp)
ffffffffc0201fd2:	6105                	addi	sp,sp,32
ffffffffc0201fd4:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0201fd6:	0000b697          	auipc	a3,0xb
ffffffffc0201fda:	4ea6b683          	ld	a3,1258(a3) # ffffffffc020d4c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fde:	070a                	slli	a4,a4,0x2
ffffffffc0201fe0:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0201fe2:	06d77563          	bgeu	a4,a3,ffffffffc020204c <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201fe6:	0000b517          	auipc	a0,0xb
ffffffffc0201fea:	4e253503          	ld	a0,1250(a0) # ffffffffc020d4c8 <pages>
ffffffffc0201fee:	071a                	slli	a4,a4,0x6
ffffffffc0201ff0:	fe0006b7          	lui	a3,0xfe000
ffffffffc0201ff4:	9736                	add	a4,a4,a3
ffffffffc0201ff6:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0201ff8:	4118                	lw	a4,0(a0)
ffffffffc0201ffa:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3ddf2b0f>
ffffffffc0201ffc:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201ffe:	cb09                	beqz	a4,ffffffffc0202010 <page_remove+0x5c>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202000:	0007b023          	sd	zero,0(a5)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202004:	12040073          	sfence.vma	s0
}
ffffffffc0202008:	60e2                	ld	ra,24(sp)
ffffffffc020200a:	6442                	ld	s0,16(sp)
ffffffffc020200c:	6105                	addi	sp,sp,32
ffffffffc020200e:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202010:	10002773          	csrr	a4,sstatus
ffffffffc0202014:	8b09                	andi	a4,a4,2
ffffffffc0202016:	eb19                	bnez	a4,ffffffffc020202c <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc0202018:	0000b717          	auipc	a4,0xb
ffffffffc020201c:	48873703          	ld	a4,1160(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0202020:	4585                	li	a1,1
ffffffffc0202022:	e03e                	sd	a5,0(sp)
ffffffffc0202024:	7318                	ld	a4,32(a4)
ffffffffc0202026:	9702                	jalr	a4
    if (flag) {
ffffffffc0202028:	6782                	ld	a5,0(sp)
ffffffffc020202a:	bfd9                	j	ffffffffc0202000 <page_remove+0x4c>
        intr_disable();
ffffffffc020202c:	e43e                	sd	a5,8(sp)
ffffffffc020202e:	e02a                	sd	a0,0(sp)
ffffffffc0202030:	845fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0202034:	0000b717          	auipc	a4,0xb
ffffffffc0202038:	46c73703          	ld	a4,1132(a4) # ffffffffc020d4a0 <pmm_manager>
ffffffffc020203c:	6502                	ld	a0,0(sp)
ffffffffc020203e:	4585                	li	a1,1
ffffffffc0202040:	7318                	ld	a4,32(a4)
ffffffffc0202042:	9702                	jalr	a4
        intr_enable();
ffffffffc0202044:	82bfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202048:	67a2                	ld	a5,8(sp)
ffffffffc020204a:	bf5d                	j	ffffffffc0202000 <page_remove+0x4c>
ffffffffc020204c:	bf3ff0ef          	jal	ffffffffc0201c3e <pa2page.part.0>

ffffffffc0202050 <page_insert>:
{
ffffffffc0202050:	7139                	addi	sp,sp,-64
ffffffffc0202052:	f426                	sd	s1,40(sp)
ffffffffc0202054:	84b2                	mv	s1,a2
ffffffffc0202056:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202058:	4605                	li	a2,1
{
ffffffffc020205a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020205c:	85a6                	mv	a1,s1
{
ffffffffc020205e:	fc06                	sd	ra,56(sp)
ffffffffc0202060:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202062:	ca1ff0ef          	jal	ffffffffc0201d02 <get_pte>
    if (ptep == NULL)
ffffffffc0202066:	cd61                	beqz	a0,ffffffffc020213e <page_insert+0xee>
    page->ref += 1;
ffffffffc0202068:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc020206a:	611c                	ld	a5,0(a0)
ffffffffc020206c:	66a2                	ld	a3,8(sp)
ffffffffc020206e:	0015861b          	addiw	a2,a1,1 # 1001 <kern_entry-0xffffffffc01fefff>
ffffffffc0202072:	c010                	sw	a2,0(s0)
ffffffffc0202074:	0017f613          	andi	a2,a5,1
ffffffffc0202078:	872a                	mv	a4,a0
ffffffffc020207a:	e61d                	bnez	a2,ffffffffc02020a8 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc020207c:	0000b617          	auipc	a2,0xb
ffffffffc0202080:	44c63603          	ld	a2,1100(a2) # ffffffffc020d4c8 <pages>
    return page - pages + nbase;
ffffffffc0202084:	8c11                	sub	s0,s0,a2
ffffffffc0202086:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202088:	200007b7          	lui	a5,0x20000
ffffffffc020208c:	042a                	slli	s0,s0,0xa
ffffffffc020208e:	943e                	add	s0,s0,a5
ffffffffc0202090:	8ec1                	or	a3,a3,s0
ffffffffc0202092:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202096:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202098:	12048073          	sfence.vma	s1
    return 0;
ffffffffc020209c:	4501                	li	a0,0
}
ffffffffc020209e:	70e2                	ld	ra,56(sp)
ffffffffc02020a0:	7442                	ld	s0,48(sp)
ffffffffc02020a2:	74a2                	ld	s1,40(sp)
ffffffffc02020a4:	6121                	addi	sp,sp,64
ffffffffc02020a6:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02020a8:	0000b617          	auipc	a2,0xb
ffffffffc02020ac:	41863603          	ld	a2,1048(a2) # ffffffffc020d4c0 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02020b0:	078a                	slli	a5,a5,0x2
ffffffffc02020b2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020b4:	08c7f763          	bgeu	a5,a2,ffffffffc0202142 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02020b8:	0000b617          	auipc	a2,0xb
ffffffffc02020bc:	41063603          	ld	a2,1040(a2) # ffffffffc020d4c8 <pages>
ffffffffc02020c0:	fe000537          	lui	a0,0xfe000
ffffffffc02020c4:	079a                	slli	a5,a5,0x6
ffffffffc02020c6:	97aa                	add	a5,a5,a0
ffffffffc02020c8:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc02020cc:	00a40963          	beq	s0,a0,ffffffffc02020de <page_insert+0x8e>
    page->ref -= 1;
ffffffffc02020d0:	411c                	lw	a5,0(a0)
ffffffffc02020d2:	37fd                	addiw	a5,a5,-1 # 1fffffff <kern_entry-0xffffffffa0200001>
ffffffffc02020d4:	c11c                	sw	a5,0(a0)
        if (page_ref(page) ==
ffffffffc02020d6:	c791                	beqz	a5,ffffffffc02020e2 <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020d8:	12048073          	sfence.vma	s1
}
ffffffffc02020dc:	b765                	j	ffffffffc0202084 <page_insert+0x34>
ffffffffc02020de:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc02020e0:	b755                	j	ffffffffc0202084 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02020e2:	100027f3          	csrr	a5,sstatus
ffffffffc02020e6:	8b89                	andi	a5,a5,2
ffffffffc02020e8:	e39d                	bnez	a5,ffffffffc020210e <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc02020ea:	0000b797          	auipc	a5,0xb
ffffffffc02020ee:	3b67b783          	ld	a5,950(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc02020f2:	4585                	li	a1,1
ffffffffc02020f4:	e83a                	sd	a4,16(sp)
ffffffffc02020f6:	739c                	ld	a5,32(a5)
ffffffffc02020f8:	e436                	sd	a3,8(sp)
ffffffffc02020fa:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02020fc:	0000b617          	auipc	a2,0xb
ffffffffc0202100:	3cc63603          	ld	a2,972(a2) # ffffffffc020d4c8 <pages>
ffffffffc0202104:	66a2                	ld	a3,8(sp)
ffffffffc0202106:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202108:	12048073          	sfence.vma	s1
ffffffffc020210c:	bfa5                	j	ffffffffc0202084 <page_insert+0x34>
        intr_disable();
ffffffffc020210e:	ec3a                	sd	a4,24(sp)
ffffffffc0202110:	e836                	sd	a3,16(sp)
ffffffffc0202112:	e42a                	sd	a0,8(sp)
ffffffffc0202114:	f60fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202118:	0000b797          	auipc	a5,0xb
ffffffffc020211c:	3887b783          	ld	a5,904(a5) # ffffffffc020d4a0 <pmm_manager>
ffffffffc0202120:	6522                	ld	a0,8(sp)
ffffffffc0202122:	4585                	li	a1,1
ffffffffc0202124:	739c                	ld	a5,32(a5)
ffffffffc0202126:	9782                	jalr	a5
        intr_enable();
ffffffffc0202128:	f46fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020212c:	0000b617          	auipc	a2,0xb
ffffffffc0202130:	39c63603          	ld	a2,924(a2) # ffffffffc020d4c8 <pages>
ffffffffc0202134:	6762                	ld	a4,24(sp)
ffffffffc0202136:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202138:	12048073          	sfence.vma	s1
ffffffffc020213c:	b7a1                	j	ffffffffc0202084 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc020213e:	5571                	li	a0,-4
ffffffffc0202140:	bfb9                	j	ffffffffc020209e <page_insert+0x4e>
ffffffffc0202142:	afdff0ef          	jal	ffffffffc0201c3e <pa2page.part.0>

ffffffffc0202146 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202146:	00003797          	auipc	a5,0x3
ffffffffc020214a:	70278793          	addi	a5,a5,1794 # ffffffffc0205848 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020214e:	638c                	ld	a1,0(a5)
{
ffffffffc0202150:	7159                	addi	sp,sp,-112
ffffffffc0202152:	f486                	sd	ra,104(sp)
ffffffffc0202154:	e8ca                	sd	s2,80(sp)
ffffffffc0202156:	e4ce                	sd	s3,72(sp)
ffffffffc0202158:	f85a                	sd	s6,48(sp)
ffffffffc020215a:	f0a2                	sd	s0,96(sp)
ffffffffc020215c:	eca6                	sd	s1,88(sp)
ffffffffc020215e:	e0d2                	sd	s4,64(sp)
ffffffffc0202160:	fc56                	sd	s5,56(sp)
ffffffffc0202162:	f45e                	sd	s7,40(sp)
ffffffffc0202164:	f062                	sd	s8,32(sp)
ffffffffc0202166:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202168:	0000bb17          	auipc	s6,0xb
ffffffffc020216c:	338b0b13          	addi	s6,s6,824 # ffffffffc020d4a0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202170:	00003517          	auipc	a0,0x3
ffffffffc0202174:	bd050513          	addi	a0,a0,-1072 # ffffffffc0204d40 <etext+0xe80>
    pmm_manager = &default_pmm_manager;
ffffffffc0202178:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020217c:	818fe0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202180:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202184:	0000b997          	auipc	s3,0xb
ffffffffc0202188:	33498993          	addi	s3,s3,820 # ffffffffc020d4b8 <va_pa_offset>
    pmm_manager->init();
ffffffffc020218c:	679c                	ld	a5,8(a5)
ffffffffc020218e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202190:	57f5                	li	a5,-3
ffffffffc0202192:	07fa                	slli	a5,a5,0x1e
ffffffffc0202194:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202198:	ec2fe0ef          	jal	ffffffffc020085a <get_memory_base>
ffffffffc020219c:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020219e:	ec6fe0ef          	jal	ffffffffc0200864 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02021a2:	70050e63          	beqz	a0,ffffffffc02028be <pmm_init+0x778>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021a6:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02021a8:	00003517          	auipc	a0,0x3
ffffffffc02021ac:	bd050513          	addi	a0,a0,-1072 # ffffffffc0204d78 <etext+0xeb8>
ffffffffc02021b0:	fe5fd0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021b4:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02021b8:	864a                	mv	a2,s2
ffffffffc02021ba:	85a6                	mv	a1,s1
ffffffffc02021bc:	fff40693          	addi	a3,s0,-1
ffffffffc02021c0:	00003517          	auipc	a0,0x3
ffffffffc02021c4:	bd050513          	addi	a0,a0,-1072 # ffffffffc0204d90 <etext+0xed0>
ffffffffc02021c8:	fcdfd0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc02021cc:	c80007b7          	lui	a5,0xc8000
ffffffffc02021d0:	8522                	mv	a0,s0
ffffffffc02021d2:	5287ed63          	bltu	a5,s0,ffffffffc020270c <pmm_init+0x5c6>
ffffffffc02021d6:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021d8:	0000c617          	auipc	a2,0xc
ffffffffc02021dc:	31760613          	addi	a2,a2,791 # ffffffffc020e4ef <end+0xfff>
ffffffffc02021e0:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc02021e2:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021e4:	0000bb97          	auipc	s7,0xb
ffffffffc02021e8:	2e4b8b93          	addi	s7,s7,740 # ffffffffc020d4c8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02021ec:	0000b497          	auipc	s1,0xb
ffffffffc02021f0:	2d448493          	addi	s1,s1,724 # ffffffffc020d4c0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021f4:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc02021f8:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021fa:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021fe:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202200:	02f50763          	beq	a0,a5,ffffffffc020222e <pmm_init+0xe8>
ffffffffc0202204:	4701                	li	a4,0
ffffffffc0202206:	4585                	li	a1,1
ffffffffc0202208:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020220c:	00671793          	slli	a5,a4,0x6
ffffffffc0202210:	97b2                	add	a5,a5,a2
ffffffffc0202212:	07a1                	addi	a5,a5,8 # 80008 <kern_entry-0xffffffffc017fff8>
ffffffffc0202214:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202218:	6088                	ld	a0,0(s1)
ffffffffc020221a:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020221c:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202220:	00d507b3          	add	a5,a0,a3
ffffffffc0202224:	fef764e3          	bltu	a4,a5,ffffffffc020220c <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202228:	079a                	slli	a5,a5,0x6
ffffffffc020222a:	00f606b3          	add	a3,a2,a5
ffffffffc020222e:	c02007b7          	lui	a5,0xc0200
ffffffffc0202232:	16f6eee3          	bltu	a3,a5,ffffffffc0202bae <pmm_init+0xa68>
ffffffffc0202236:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020223a:	77fd                	lui	a5,0xfffff
ffffffffc020223c:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020223e:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202240:	4e86ed63          	bltu	a3,s0,ffffffffc020273a <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202244:	00003517          	auipc	a0,0x3
ffffffffc0202248:	b7450513          	addi	a0,a0,-1164 # ffffffffc0204db8 <etext+0xef8>
ffffffffc020224c:	f49fd0ef          	jal	ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202250:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202254:	0000b917          	auipc	s2,0xb
ffffffffc0202258:	25c90913          	addi	s2,s2,604 # ffffffffc020d4b0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020225c:	7b9c                	ld	a5,48(a5)
ffffffffc020225e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202260:	00003517          	auipc	a0,0x3
ffffffffc0202264:	b7050513          	addi	a0,a0,-1168 # ffffffffc0204dd0 <etext+0xf10>
ffffffffc0202268:	f2dfd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020226c:	00006697          	auipc	a3,0x6
ffffffffc0202270:	d9468693          	addi	a3,a3,-620 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0202274:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202278:	c02007b7          	lui	a5,0xc0200
ffffffffc020227c:	2af6eee3          	bltu	a3,a5,ffffffffc0202d38 <pmm_init+0xbf2>
ffffffffc0202280:	0009b783          	ld	a5,0(s3)
ffffffffc0202284:	8e9d                	sub	a3,a3,a5
ffffffffc0202286:	0000b797          	auipc	a5,0xb
ffffffffc020228a:	22d7b123          	sd	a3,546(a5) # ffffffffc020d4a8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020228e:	100027f3          	csrr	a5,sstatus
ffffffffc0202292:	8b89                	andi	a5,a5,2
ffffffffc0202294:	48079963          	bnez	a5,ffffffffc0202726 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202298:	000b3783          	ld	a5,0(s6)
ffffffffc020229c:	779c                	ld	a5,40(a5)
ffffffffc020229e:	9782                	jalr	a5
ffffffffc02022a0:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02022a2:	6098                	ld	a4,0(s1)
ffffffffc02022a4:	c80007b7          	lui	a5,0xc8000
ffffffffc02022a8:	83b1                	srli	a5,a5,0xc
ffffffffc02022aa:	66e7e663          	bltu	a5,a4,ffffffffc0202916 <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02022ae:	00093503          	ld	a0,0(s2)
ffffffffc02022b2:	64050263          	beqz	a0,ffffffffc02028f6 <pmm_init+0x7b0>
ffffffffc02022b6:	03451793          	slli	a5,a0,0x34
ffffffffc02022ba:	62079e63          	bnez	a5,ffffffffc02028f6 <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02022be:	4601                	li	a2,0
ffffffffc02022c0:	4581                	li	a1,0
ffffffffc02022c2:	c9fff0ef          	jal	ffffffffc0201f60 <get_page>
ffffffffc02022c6:	240519e3          	bnez	a0,ffffffffc0202d18 <pmm_init+0xbd2>
ffffffffc02022ca:	100027f3          	csrr	a5,sstatus
ffffffffc02022ce:	8b89                	andi	a5,a5,2
ffffffffc02022d0:	44079063          	bnez	a5,ffffffffc0202710 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022d4:	000b3783          	ld	a5,0(s6)
ffffffffc02022d8:	4505                	li	a0,1
ffffffffc02022da:	6f9c                	ld	a5,24(a5)
ffffffffc02022dc:	9782                	jalr	a5
ffffffffc02022de:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02022e0:	00093503          	ld	a0,0(s2)
ffffffffc02022e4:	4681                	li	a3,0
ffffffffc02022e6:	4601                	li	a2,0
ffffffffc02022e8:	85d2                	mv	a1,s4
ffffffffc02022ea:	d67ff0ef          	jal	ffffffffc0202050 <page_insert>
ffffffffc02022ee:	280511e3          	bnez	a0,ffffffffc0202d70 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02022f2:	00093503          	ld	a0,0(s2)
ffffffffc02022f6:	4601                	li	a2,0
ffffffffc02022f8:	4581                	li	a1,0
ffffffffc02022fa:	a09ff0ef          	jal	ffffffffc0201d02 <get_pte>
ffffffffc02022fe:	240509e3          	beqz	a0,ffffffffc0202d50 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc0202302:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202304:	0017f713          	andi	a4,a5,1
ffffffffc0202308:	58070f63          	beqz	a4,ffffffffc02028a6 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc020230c:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020230e:	078a                	slli	a5,a5,0x2
ffffffffc0202310:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202312:	58e7f863          	bgeu	a5,a4,ffffffffc02028a2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202316:	000bb683          	ld	a3,0(s7)
ffffffffc020231a:	079a                	slli	a5,a5,0x6
ffffffffc020231c:	fe000637          	lui	a2,0xfe000
ffffffffc0202320:	97b2                	add	a5,a5,a2
ffffffffc0202322:	97b6                	add	a5,a5,a3
ffffffffc0202324:	14fa1ae3          	bne	s4,a5,ffffffffc0202c78 <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc0202328:	000a2683          	lw	a3,0(s4)
ffffffffc020232c:	4785                	li	a5,1
ffffffffc020232e:	12f695e3          	bne	a3,a5,ffffffffc0202c58 <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202332:	00093503          	ld	a0,0(s2)
ffffffffc0202336:	77fd                	lui	a5,0xfffff
ffffffffc0202338:	6114                	ld	a3,0(a0)
ffffffffc020233a:	068a                	slli	a3,a3,0x2
ffffffffc020233c:	8efd                	and	a3,a3,a5
ffffffffc020233e:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202342:	0ee67fe3          	bgeu	a2,a4,ffffffffc0202c40 <pmm_init+0xafa>
ffffffffc0202346:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020234a:	96e2                	add	a3,a3,s8
ffffffffc020234c:	0006ba83          	ld	s5,0(a3)
ffffffffc0202350:	0a8a                	slli	s5,s5,0x2
ffffffffc0202352:	00fafab3          	and	s5,s5,a5
ffffffffc0202356:	00cad793          	srli	a5,s5,0xc
ffffffffc020235a:	0ce7f6e3          	bgeu	a5,a4,ffffffffc0202c26 <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020235e:	4601                	li	a2,0
ffffffffc0202360:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202362:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202364:	99fff0ef          	jal	ffffffffc0201d02 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202368:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020236a:	05851ee3          	bne	a0,s8,ffffffffc0202bc6 <pmm_init+0xa80>
ffffffffc020236e:	100027f3          	csrr	a5,sstatus
ffffffffc0202372:	8b89                	andi	a5,a5,2
ffffffffc0202374:	3e079b63          	bnez	a5,ffffffffc020276a <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202378:	000b3783          	ld	a5,0(s6)
ffffffffc020237c:	4505                	li	a0,1
ffffffffc020237e:	6f9c                	ld	a5,24(a5)
ffffffffc0202380:	9782                	jalr	a5
ffffffffc0202382:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202384:	00093503          	ld	a0,0(s2)
ffffffffc0202388:	46d1                	li	a3,20
ffffffffc020238a:	6605                	lui	a2,0x1
ffffffffc020238c:	85e2                	mv	a1,s8
ffffffffc020238e:	cc3ff0ef          	jal	ffffffffc0202050 <page_insert>
ffffffffc0202392:	06051ae3          	bnez	a0,ffffffffc0202c06 <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202396:	00093503          	ld	a0,0(s2)
ffffffffc020239a:	4601                	li	a2,0
ffffffffc020239c:	6585                	lui	a1,0x1
ffffffffc020239e:	965ff0ef          	jal	ffffffffc0201d02 <get_pte>
ffffffffc02023a2:	040502e3          	beqz	a0,ffffffffc0202be6 <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc02023a6:	611c                	ld	a5,0(a0)
ffffffffc02023a8:	0107f713          	andi	a4,a5,16
ffffffffc02023ac:	7e070163          	beqz	a4,ffffffffc0202b8e <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc02023b0:	8b91                	andi	a5,a5,4
ffffffffc02023b2:	7a078e63          	beqz	a5,ffffffffc0202b6e <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02023b6:	00093503          	ld	a0,0(s2)
ffffffffc02023ba:	611c                	ld	a5,0(a0)
ffffffffc02023bc:	8bc1                	andi	a5,a5,16
ffffffffc02023be:	78078863          	beqz	a5,ffffffffc0202b4e <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc02023c2:	000c2703          	lw	a4,0(s8)
ffffffffc02023c6:	4785                	li	a5,1
ffffffffc02023c8:	76f71363          	bne	a4,a5,ffffffffc0202b2e <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02023cc:	4681                	li	a3,0
ffffffffc02023ce:	6605                	lui	a2,0x1
ffffffffc02023d0:	85d2                	mv	a1,s4
ffffffffc02023d2:	c7fff0ef          	jal	ffffffffc0202050 <page_insert>
ffffffffc02023d6:	72051c63          	bnez	a0,ffffffffc0202b0e <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc02023da:	000a2703          	lw	a4,0(s4)
ffffffffc02023de:	4789                	li	a5,2
ffffffffc02023e0:	70f71763          	bne	a4,a5,ffffffffc0202aee <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc02023e4:	000c2783          	lw	a5,0(s8)
ffffffffc02023e8:	6e079363          	bnez	a5,ffffffffc0202ace <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023ec:	00093503          	ld	a0,0(s2)
ffffffffc02023f0:	4601                	li	a2,0
ffffffffc02023f2:	6585                	lui	a1,0x1
ffffffffc02023f4:	90fff0ef          	jal	ffffffffc0201d02 <get_pte>
ffffffffc02023f8:	6a050b63          	beqz	a0,ffffffffc0202aae <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc02023fc:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02023fe:	00177793          	andi	a5,a4,1
ffffffffc0202402:	4a078263          	beqz	a5,ffffffffc02028a6 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202406:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202408:	00271793          	slli	a5,a4,0x2
ffffffffc020240c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020240e:	48d7fa63          	bgeu	a5,a3,ffffffffc02028a2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202412:	000bb683          	ld	a3,0(s7)
ffffffffc0202416:	fff80ab7          	lui	s5,0xfff80
ffffffffc020241a:	97d6                	add	a5,a5,s5
ffffffffc020241c:	079a                	slli	a5,a5,0x6
ffffffffc020241e:	97b6                	add	a5,a5,a3
ffffffffc0202420:	66fa1763          	bne	s4,a5,ffffffffc0202a8e <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202424:	8b41                	andi	a4,a4,16
ffffffffc0202426:	64071463          	bnez	a4,ffffffffc0202a6e <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc020242a:	00093503          	ld	a0,0(s2)
ffffffffc020242e:	4581                	li	a1,0
ffffffffc0202430:	b85ff0ef          	jal	ffffffffc0201fb4 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202434:	000a2c83          	lw	s9,0(s4)
ffffffffc0202438:	4785                	li	a5,1
ffffffffc020243a:	60fc9a63          	bne	s9,a5,ffffffffc0202a4e <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc020243e:	000c2783          	lw	a5,0(s8)
ffffffffc0202442:	5e079663          	bnez	a5,ffffffffc0202a2e <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202446:	00093503          	ld	a0,0(s2)
ffffffffc020244a:	6585                	lui	a1,0x1
ffffffffc020244c:	b69ff0ef          	jal	ffffffffc0201fb4 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202450:	000a2783          	lw	a5,0(s4)
ffffffffc0202454:	52079d63          	bnez	a5,ffffffffc020298e <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202458:	000c2783          	lw	a5,0(s8)
ffffffffc020245c:	50079963          	bnez	a5,ffffffffc020296e <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202460:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202464:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202466:	000a3783          	ld	a5,0(s4)
ffffffffc020246a:	078a                	slli	a5,a5,0x2
ffffffffc020246c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020246e:	42e7fa63          	bgeu	a5,a4,ffffffffc02028a2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202472:	000bb503          	ld	a0,0(s7)
ffffffffc0202476:	97d6                	add	a5,a5,s5
ffffffffc0202478:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc020247a:	00f506b3          	add	a3,a0,a5
ffffffffc020247e:	4294                	lw	a3,0(a3)
ffffffffc0202480:	4d969763          	bne	a3,s9,ffffffffc020294e <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202484:	8799                	srai	a5,a5,0x6
ffffffffc0202486:	00080637          	lui	a2,0x80
ffffffffc020248a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020248c:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202490:	4ae7f363          	bgeu	a5,a4,ffffffffc0202936 <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202494:	0009b783          	ld	a5,0(s3)
ffffffffc0202498:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc020249a:	639c                	ld	a5,0(a5)
ffffffffc020249c:	078a                	slli	a5,a5,0x2
ffffffffc020249e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024a0:	40e7f163          	bgeu	a5,a4,ffffffffc02028a2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02024a4:	8f91                	sub	a5,a5,a2
ffffffffc02024a6:	079a                	slli	a5,a5,0x6
ffffffffc02024a8:	953e                	add	a0,a0,a5
ffffffffc02024aa:	100027f3          	csrr	a5,sstatus
ffffffffc02024ae:	8b89                	andi	a5,a5,2
ffffffffc02024b0:	30079863          	bnez	a5,ffffffffc02027c0 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc02024b4:	000b3783          	ld	a5,0(s6)
ffffffffc02024b8:	4585                	li	a1,1
ffffffffc02024ba:	739c                	ld	a5,32(a5)
ffffffffc02024bc:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02024be:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02024c2:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024c4:	078a                	slli	a5,a5,0x2
ffffffffc02024c6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024c8:	3ce7fd63          	bgeu	a5,a4,ffffffffc02028a2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02024cc:	000bb503          	ld	a0,0(s7)
ffffffffc02024d0:	fe000737          	lui	a4,0xfe000
ffffffffc02024d4:	079a                	slli	a5,a5,0x6
ffffffffc02024d6:	97ba                	add	a5,a5,a4
ffffffffc02024d8:	953e                	add	a0,a0,a5
ffffffffc02024da:	100027f3          	csrr	a5,sstatus
ffffffffc02024de:	8b89                	andi	a5,a5,2
ffffffffc02024e0:	2c079463          	bnez	a5,ffffffffc02027a8 <pmm_init+0x662>
ffffffffc02024e4:	000b3783          	ld	a5,0(s6)
ffffffffc02024e8:	4585                	li	a1,1
ffffffffc02024ea:	739c                	ld	a5,32(a5)
ffffffffc02024ec:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02024ee:	00093783          	ld	a5,0(s2)
ffffffffc02024f2:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b10>
    asm volatile("sfence.vma");
ffffffffc02024f6:	12000073          	sfence.vma
ffffffffc02024fa:	100027f3          	csrr	a5,sstatus
ffffffffc02024fe:	8b89                	andi	a5,a5,2
ffffffffc0202500:	28079a63          	bnez	a5,ffffffffc0202794 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202504:	000b3783          	ld	a5,0(s6)
ffffffffc0202508:	779c                	ld	a5,40(a5)
ffffffffc020250a:	9782                	jalr	a5
ffffffffc020250c:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc020250e:	4d441063          	bne	s0,s4,ffffffffc02029ce <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202512:	00003517          	auipc	a0,0x3
ffffffffc0202516:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0205120 <etext+0x1260>
ffffffffc020251a:	c7bfd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc020251e:	100027f3          	csrr	a5,sstatus
ffffffffc0202522:	8b89                	andi	a5,a5,2
ffffffffc0202524:	24079e63          	bnez	a5,ffffffffc0202780 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202528:	000b3783          	ld	a5,0(s6)
ffffffffc020252c:	779c                	ld	a5,40(a5)
ffffffffc020252e:	9782                	jalr	a5
ffffffffc0202530:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202532:	609c                	ld	a5,0(s1)
ffffffffc0202534:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202538:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020253a:	00c79713          	slli	a4,a5,0xc
ffffffffc020253e:	6a85                	lui	s5,0x1
ffffffffc0202540:	02e47c63          	bgeu	s0,a4,ffffffffc0202578 <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202544:	00c45713          	srli	a4,s0,0xc
ffffffffc0202548:	30f77063          	bgeu	a4,a5,ffffffffc0202848 <pmm_init+0x702>
ffffffffc020254c:	0009b583          	ld	a1,0(s3)
ffffffffc0202550:	00093503          	ld	a0,0(s2)
ffffffffc0202554:	4601                	li	a2,0
ffffffffc0202556:	95a2                	add	a1,a1,s0
ffffffffc0202558:	faaff0ef          	jal	ffffffffc0201d02 <get_pte>
ffffffffc020255c:	32050363          	beqz	a0,ffffffffc0202882 <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202560:	611c                	ld	a5,0(a0)
ffffffffc0202562:	078a                	slli	a5,a5,0x2
ffffffffc0202564:	0147f7b3          	and	a5,a5,s4
ffffffffc0202568:	2e879d63          	bne	a5,s0,ffffffffc0202862 <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020256c:	609c                	ld	a5,0(s1)
ffffffffc020256e:	9456                	add	s0,s0,s5
ffffffffc0202570:	00c79713          	slli	a4,a5,0xc
ffffffffc0202574:	fce468e3          	bltu	s0,a4,ffffffffc0202544 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202578:	00093783          	ld	a5,0(s2)
ffffffffc020257c:	639c                	ld	a5,0(a5)
ffffffffc020257e:	42079863          	bnez	a5,ffffffffc02029ae <pmm_init+0x868>
ffffffffc0202582:	100027f3          	csrr	a5,sstatus
ffffffffc0202586:	8b89                	andi	a5,a5,2
ffffffffc0202588:	24079863          	bnez	a5,ffffffffc02027d8 <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc020258c:	000b3783          	ld	a5,0(s6)
ffffffffc0202590:	4505                	li	a0,1
ffffffffc0202592:	6f9c                	ld	a5,24(a5)
ffffffffc0202594:	9782                	jalr	a5
ffffffffc0202596:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202598:	00093503          	ld	a0,0(s2)
ffffffffc020259c:	4699                	li	a3,6
ffffffffc020259e:	10000613          	li	a2,256
ffffffffc02025a2:	85a2                	mv	a1,s0
ffffffffc02025a4:	aadff0ef          	jal	ffffffffc0202050 <page_insert>
ffffffffc02025a8:	46051363          	bnez	a0,ffffffffc0202a0e <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc02025ac:	4018                	lw	a4,0(s0)
ffffffffc02025ae:	4785                	li	a5,1
ffffffffc02025b0:	42f71f63          	bne	a4,a5,ffffffffc02029ee <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025b4:	00093503          	ld	a0,0(s2)
ffffffffc02025b8:	6605                	lui	a2,0x1
ffffffffc02025ba:	10060613          	addi	a2,a2,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025be:	4699                	li	a3,6
ffffffffc02025c0:	85a2                	mv	a1,s0
ffffffffc02025c2:	a8fff0ef          	jal	ffffffffc0202050 <page_insert>
ffffffffc02025c6:	72051963          	bnez	a0,ffffffffc0202cf8 <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc02025ca:	4018                	lw	a4,0(s0)
ffffffffc02025cc:	4789                	li	a5,2
ffffffffc02025ce:	70f71563          	bne	a4,a5,ffffffffc0202cd8 <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02025d2:	00003597          	auipc	a1,0x3
ffffffffc02025d6:	c9658593          	addi	a1,a1,-874 # ffffffffc0205268 <etext+0x13a8>
ffffffffc02025da:	10000513          	li	a0,256
ffffffffc02025de:	015010ef          	jal	ffffffffc0203df2 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02025e2:	6585                	lui	a1,0x1
ffffffffc02025e4:	10058593          	addi	a1,a1,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025e8:	10000513          	li	a0,256
ffffffffc02025ec:	019010ef          	jal	ffffffffc0203e04 <strcmp>
ffffffffc02025f0:	6c051463          	bnez	a0,ffffffffc0202cb8 <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc02025f4:	000bb683          	ld	a3,0(s7)
ffffffffc02025f8:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc02025fc:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc02025fe:	40d406b3          	sub	a3,s0,a3
ffffffffc0202602:	8699                	srai	a3,a3,0x6
ffffffffc0202604:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202606:	00c69793          	slli	a5,a3,0xc
ffffffffc020260a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020260c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020260e:	32e7f463          	bgeu	a5,a4,ffffffffc0202936 <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202612:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202616:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020261a:	97b6                	add	a5,a5,a3
ffffffffc020261c:	10078023          	sb	zero,256(a5) # 80100 <kern_entry-0xffffffffc017ff00>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202620:	79e010ef          	jal	ffffffffc0203dbe <strlen>
ffffffffc0202624:	66051a63          	bnez	a0,ffffffffc0202c98 <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202628:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc020262c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020262e:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fdf1b10>
ffffffffc0202632:	078a                	slli	a5,a5,0x2
ffffffffc0202634:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202636:	26e7f663          	bgeu	a5,a4,ffffffffc02028a2 <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc020263a:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020263e:	2ee7fc63          	bgeu	a5,a4,ffffffffc0202936 <pmm_init+0x7f0>
ffffffffc0202642:	0009b783          	ld	a5,0(s3)
ffffffffc0202646:	00f689b3          	add	s3,a3,a5
ffffffffc020264a:	100027f3          	csrr	a5,sstatus
ffffffffc020264e:	8b89                	andi	a5,a5,2
ffffffffc0202650:	1e079163          	bnez	a5,ffffffffc0202832 <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202654:	000b3783          	ld	a5,0(s6)
ffffffffc0202658:	8522                	mv	a0,s0
ffffffffc020265a:	4585                	li	a1,1
ffffffffc020265c:	739c                	ld	a5,32(a5)
ffffffffc020265e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202660:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202664:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202666:	078a                	slli	a5,a5,0x2
ffffffffc0202668:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020266a:	22e7fc63          	bgeu	a5,a4,ffffffffc02028a2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020266e:	000bb503          	ld	a0,0(s7)
ffffffffc0202672:	fe000737          	lui	a4,0xfe000
ffffffffc0202676:	079a                	slli	a5,a5,0x6
ffffffffc0202678:	97ba                	add	a5,a5,a4
ffffffffc020267a:	953e                	add	a0,a0,a5
ffffffffc020267c:	100027f3          	csrr	a5,sstatus
ffffffffc0202680:	8b89                	andi	a5,a5,2
ffffffffc0202682:	18079c63          	bnez	a5,ffffffffc020281a <pmm_init+0x6d4>
ffffffffc0202686:	000b3783          	ld	a5,0(s6)
ffffffffc020268a:	4585                	li	a1,1
ffffffffc020268c:	739c                	ld	a5,32(a5)
ffffffffc020268e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202690:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202694:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202696:	078a                	slli	a5,a5,0x2
ffffffffc0202698:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020269a:	20e7f463          	bgeu	a5,a4,ffffffffc02028a2 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020269e:	000bb503          	ld	a0,0(s7)
ffffffffc02026a2:	fe000737          	lui	a4,0xfe000
ffffffffc02026a6:	079a                	slli	a5,a5,0x6
ffffffffc02026a8:	97ba                	add	a5,a5,a4
ffffffffc02026aa:	953e                	add	a0,a0,a5
ffffffffc02026ac:	100027f3          	csrr	a5,sstatus
ffffffffc02026b0:	8b89                	andi	a5,a5,2
ffffffffc02026b2:	14079863          	bnez	a5,ffffffffc0202802 <pmm_init+0x6bc>
ffffffffc02026b6:	000b3783          	ld	a5,0(s6)
ffffffffc02026ba:	4585                	li	a1,1
ffffffffc02026bc:	739c                	ld	a5,32(a5)
ffffffffc02026be:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02026c0:	00093783          	ld	a5,0(s2)
ffffffffc02026c4:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc02026c8:	12000073          	sfence.vma
ffffffffc02026cc:	100027f3          	csrr	a5,sstatus
ffffffffc02026d0:	8b89                	andi	a5,a5,2
ffffffffc02026d2:	10079e63          	bnez	a5,ffffffffc02027ee <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026d6:	000b3783          	ld	a5,0(s6)
ffffffffc02026da:	779c                	ld	a5,40(a5)
ffffffffc02026dc:	9782                	jalr	a5
ffffffffc02026de:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02026e0:	1e8c1b63          	bne	s8,s0,ffffffffc02028d6 <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02026e4:	00003517          	auipc	a0,0x3
ffffffffc02026e8:	bfc50513          	addi	a0,a0,-1028 # ffffffffc02052e0 <etext+0x1420>
ffffffffc02026ec:	aa9fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc02026f0:	7406                	ld	s0,96(sp)
ffffffffc02026f2:	70a6                	ld	ra,104(sp)
ffffffffc02026f4:	64e6                	ld	s1,88(sp)
ffffffffc02026f6:	6946                	ld	s2,80(sp)
ffffffffc02026f8:	69a6                	ld	s3,72(sp)
ffffffffc02026fa:	6a06                	ld	s4,64(sp)
ffffffffc02026fc:	7ae2                	ld	s5,56(sp)
ffffffffc02026fe:	7b42                	ld	s6,48(sp)
ffffffffc0202700:	7ba2                	ld	s7,40(sp)
ffffffffc0202702:	7c02                	ld	s8,32(sp)
ffffffffc0202704:	6ce2                	ld	s9,24(sp)
ffffffffc0202706:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202708:	b70ff06f          	j	ffffffffc0201a78 <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc020270c:	853e                	mv	a0,a5
ffffffffc020270e:	b4e1                	j	ffffffffc02021d6 <pmm_init+0x90>
        intr_disable();
ffffffffc0202710:	964fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202714:	000b3783          	ld	a5,0(s6)
ffffffffc0202718:	4505                	li	a0,1
ffffffffc020271a:	6f9c                	ld	a5,24(a5)
ffffffffc020271c:	9782                	jalr	a5
ffffffffc020271e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202720:	94efe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202724:	be75                	j	ffffffffc02022e0 <pmm_init+0x19a>
        intr_disable();
ffffffffc0202726:	94efe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020272a:	000b3783          	ld	a5,0(s6)
ffffffffc020272e:	779c                	ld	a5,40(a5)
ffffffffc0202730:	9782                	jalr	a5
ffffffffc0202732:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202734:	93afe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202738:	b6ad                	j	ffffffffc02022a2 <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020273a:	6705                	lui	a4,0x1
ffffffffc020273c:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020273e:	96ba                	add	a3,a3,a4
ffffffffc0202740:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202742:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202746:	14a77e63          	bgeu	a4,a0,ffffffffc02028a2 <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc020274a:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020274e:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202750:	071a                	slli	a4,a4,0x6
ffffffffc0202752:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202756:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202758:	6a9c                	ld	a5,16(a3)
ffffffffc020275a:	00c45593          	srli	a1,s0,0xc
ffffffffc020275e:	00e60533          	add	a0,a2,a4
ffffffffc0202762:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202764:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202768:	bcf1                	j	ffffffffc0202244 <pmm_init+0xfe>
        intr_disable();
ffffffffc020276a:	90afe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020276e:	000b3783          	ld	a5,0(s6)
ffffffffc0202772:	4505                	li	a0,1
ffffffffc0202774:	6f9c                	ld	a5,24(a5)
ffffffffc0202776:	9782                	jalr	a5
ffffffffc0202778:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020277a:	8f4fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020277e:	b119                	j	ffffffffc0202384 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202780:	8f4fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202784:	000b3783          	ld	a5,0(s6)
ffffffffc0202788:	779c                	ld	a5,40(a5)
ffffffffc020278a:	9782                	jalr	a5
ffffffffc020278c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020278e:	8e0fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202792:	b345                	j	ffffffffc0202532 <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202794:	8e0fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0202798:	000b3783          	ld	a5,0(s6)
ffffffffc020279c:	779c                	ld	a5,40(a5)
ffffffffc020279e:	9782                	jalr	a5
ffffffffc02027a0:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027a2:	8ccfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027a6:	b3a5                	j	ffffffffc020250e <pmm_init+0x3c8>
ffffffffc02027a8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027aa:	8cafe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027ae:	000b3783          	ld	a5,0(s6)
ffffffffc02027b2:	6522                	ld	a0,8(sp)
ffffffffc02027b4:	4585                	li	a1,1
ffffffffc02027b6:	739c                	ld	a5,32(a5)
ffffffffc02027b8:	9782                	jalr	a5
        intr_enable();
ffffffffc02027ba:	8b4fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027be:	bb05                	j	ffffffffc02024ee <pmm_init+0x3a8>
ffffffffc02027c0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027c2:	8b2fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02027c6:	000b3783          	ld	a5,0(s6)
ffffffffc02027ca:	6522                	ld	a0,8(sp)
ffffffffc02027cc:	4585                	li	a1,1
ffffffffc02027ce:	739c                	ld	a5,32(a5)
ffffffffc02027d0:	9782                	jalr	a5
        intr_enable();
ffffffffc02027d2:	89cfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027d6:	b1e5                	j	ffffffffc02024be <pmm_init+0x378>
        intr_disable();
ffffffffc02027d8:	89cfe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027dc:	000b3783          	ld	a5,0(s6)
ffffffffc02027e0:	4505                	li	a0,1
ffffffffc02027e2:	6f9c                	ld	a5,24(a5)
ffffffffc02027e4:	9782                	jalr	a5
ffffffffc02027e6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02027e8:	886fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027ec:	b375                	j	ffffffffc0202598 <pmm_init+0x452>
        intr_disable();
ffffffffc02027ee:	886fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02027f2:	000b3783          	ld	a5,0(s6)
ffffffffc02027f6:	779c                	ld	a5,40(a5)
ffffffffc02027f8:	9782                	jalr	a5
ffffffffc02027fa:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02027fc:	872fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202800:	b5c5                	j	ffffffffc02026e0 <pmm_init+0x59a>
ffffffffc0202802:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202804:	870fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202808:	000b3783          	ld	a5,0(s6)
ffffffffc020280c:	6522                	ld	a0,8(sp)
ffffffffc020280e:	4585                	li	a1,1
ffffffffc0202810:	739c                	ld	a5,32(a5)
ffffffffc0202812:	9782                	jalr	a5
        intr_enable();
ffffffffc0202814:	85afe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202818:	b565                	j	ffffffffc02026c0 <pmm_init+0x57a>
ffffffffc020281a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020281c:	858fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0202820:	000b3783          	ld	a5,0(s6)
ffffffffc0202824:	6522                	ld	a0,8(sp)
ffffffffc0202826:	4585                	li	a1,1
ffffffffc0202828:	739c                	ld	a5,32(a5)
ffffffffc020282a:	9782                	jalr	a5
        intr_enable();
ffffffffc020282c:	842fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202830:	b585                	j	ffffffffc0202690 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202832:	842fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0202836:	000b3783          	ld	a5,0(s6)
ffffffffc020283a:	8522                	mv	a0,s0
ffffffffc020283c:	4585                	li	a1,1
ffffffffc020283e:	739c                	ld	a5,32(a5)
ffffffffc0202840:	9782                	jalr	a5
        intr_enable();
ffffffffc0202842:	82cfe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202846:	bd29                	j	ffffffffc0202660 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202848:	86a2                	mv	a3,s0
ffffffffc020284a:	00002617          	auipc	a2,0x2
ffffffffc020284e:	3f660613          	addi	a2,a2,1014 # ffffffffc0204c40 <etext+0xd80>
ffffffffc0202852:	1a400593          	li	a1,420
ffffffffc0202856:	00002517          	auipc	a0,0x2
ffffffffc020285a:	4da50513          	addi	a0,a0,1242 # ffffffffc0204d30 <etext+0xe70>
ffffffffc020285e:	ba9fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202862:	00003697          	auipc	a3,0x3
ffffffffc0202866:	91e68693          	addi	a3,a3,-1762 # ffffffffc0205180 <etext+0x12c0>
ffffffffc020286a:	00002617          	auipc	a2,0x2
ffffffffc020286e:	02660613          	addi	a2,a2,38 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202872:	1a500593          	li	a1,421
ffffffffc0202876:	00002517          	auipc	a0,0x2
ffffffffc020287a:	4ba50513          	addi	a0,a0,1210 # ffffffffc0204d30 <etext+0xe70>
ffffffffc020287e:	b89fd0ef          	jal	ffffffffc0200406 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202882:	00003697          	auipc	a3,0x3
ffffffffc0202886:	8be68693          	addi	a3,a3,-1858 # ffffffffc0205140 <etext+0x1280>
ffffffffc020288a:	00002617          	auipc	a2,0x2
ffffffffc020288e:	00660613          	addi	a2,a2,6 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202892:	1a400593          	li	a1,420
ffffffffc0202896:	00002517          	auipc	a0,0x2
ffffffffc020289a:	49a50513          	addi	a0,a0,1178 # ffffffffc0204d30 <etext+0xe70>
ffffffffc020289e:	b69fd0ef          	jal	ffffffffc0200406 <__panic>
ffffffffc02028a2:	b9cff0ef          	jal	ffffffffc0201c3e <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc02028a6:	00002617          	auipc	a2,0x2
ffffffffc02028aa:	63a60613          	addi	a2,a2,1594 # ffffffffc0204ee0 <etext+0x1020>
ffffffffc02028ae:	07f00593          	li	a1,127
ffffffffc02028b2:	00002517          	auipc	a0,0x2
ffffffffc02028b6:	3b650513          	addi	a0,a0,950 # ffffffffc0204c68 <etext+0xda8>
ffffffffc02028ba:	b4dfd0ef          	jal	ffffffffc0200406 <__panic>
        panic("DTB memory info not available");
ffffffffc02028be:	00002617          	auipc	a2,0x2
ffffffffc02028c2:	49a60613          	addi	a2,a2,1178 # ffffffffc0204d58 <etext+0xe98>
ffffffffc02028c6:	06400593          	li	a1,100
ffffffffc02028ca:	00002517          	auipc	a0,0x2
ffffffffc02028ce:	46650513          	addi	a0,a0,1126 # ffffffffc0204d30 <etext+0xe70>
ffffffffc02028d2:	b35fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02028d6:	00003697          	auipc	a3,0x3
ffffffffc02028da:	82268693          	addi	a3,a3,-2014 # ffffffffc02050f8 <etext+0x1238>
ffffffffc02028de:	00002617          	auipc	a2,0x2
ffffffffc02028e2:	fb260613          	addi	a2,a2,-78 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02028e6:	1bf00593          	li	a1,447
ffffffffc02028ea:	00002517          	auipc	a0,0x2
ffffffffc02028ee:	44650513          	addi	a0,a0,1094 # ffffffffc0204d30 <etext+0xe70>
ffffffffc02028f2:	b15fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028f6:	00002697          	auipc	a3,0x2
ffffffffc02028fa:	51a68693          	addi	a3,a3,1306 # ffffffffc0204e10 <etext+0xf50>
ffffffffc02028fe:	00002617          	auipc	a2,0x2
ffffffffc0202902:	f9260613          	addi	a2,a2,-110 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202906:	16600593          	li	a1,358
ffffffffc020290a:	00002517          	auipc	a0,0x2
ffffffffc020290e:	42650513          	addi	a0,a0,1062 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202912:	af5fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202916:	00002697          	auipc	a3,0x2
ffffffffc020291a:	4da68693          	addi	a3,a3,1242 # ffffffffc0204df0 <etext+0xf30>
ffffffffc020291e:	00002617          	auipc	a2,0x2
ffffffffc0202922:	f7260613          	addi	a2,a2,-142 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202926:	16500593          	li	a1,357
ffffffffc020292a:	00002517          	auipc	a0,0x2
ffffffffc020292e:	40650513          	addi	a0,a0,1030 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202932:	ad5fd0ef          	jal	ffffffffc0200406 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202936:	00002617          	auipc	a2,0x2
ffffffffc020293a:	30a60613          	addi	a2,a2,778 # ffffffffc0204c40 <etext+0xd80>
ffffffffc020293e:	07100593          	li	a1,113
ffffffffc0202942:	00002517          	auipc	a0,0x2
ffffffffc0202946:	32650513          	addi	a0,a0,806 # ffffffffc0204c68 <etext+0xda8>
ffffffffc020294a:	abdfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc020294e:	00002697          	auipc	a3,0x2
ffffffffc0202952:	77a68693          	addi	a3,a3,1914 # ffffffffc02050c8 <etext+0x1208>
ffffffffc0202956:	00002617          	auipc	a2,0x2
ffffffffc020295a:	f3a60613          	addi	a2,a2,-198 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020295e:	18d00593          	li	a1,397
ffffffffc0202962:	00002517          	auipc	a0,0x2
ffffffffc0202966:	3ce50513          	addi	a0,a0,974 # ffffffffc0204d30 <etext+0xe70>
ffffffffc020296a:	a9dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020296e:	00002697          	auipc	a3,0x2
ffffffffc0202972:	71268693          	addi	a3,a3,1810 # ffffffffc0205080 <etext+0x11c0>
ffffffffc0202976:	00002617          	auipc	a2,0x2
ffffffffc020297a:	f1a60613          	addi	a2,a2,-230 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020297e:	18b00593          	li	a1,395
ffffffffc0202982:	00002517          	auipc	a0,0x2
ffffffffc0202986:	3ae50513          	addi	a0,a0,942 # ffffffffc0204d30 <etext+0xe70>
ffffffffc020298a:	a7dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020298e:	00002697          	auipc	a3,0x2
ffffffffc0202992:	72268693          	addi	a3,a3,1826 # ffffffffc02050b0 <etext+0x11f0>
ffffffffc0202996:	00002617          	auipc	a2,0x2
ffffffffc020299a:	efa60613          	addi	a2,a2,-262 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020299e:	18a00593          	li	a1,394
ffffffffc02029a2:	00002517          	auipc	a0,0x2
ffffffffc02029a6:	38e50513          	addi	a0,a0,910 # ffffffffc0204d30 <etext+0xe70>
ffffffffc02029aa:	a5dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02029ae:	00002697          	auipc	a3,0x2
ffffffffc02029b2:	7ea68693          	addi	a3,a3,2026 # ffffffffc0205198 <etext+0x12d8>
ffffffffc02029b6:	00002617          	auipc	a2,0x2
ffffffffc02029ba:	eda60613          	addi	a2,a2,-294 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02029be:	1a800593          	li	a1,424
ffffffffc02029c2:	00002517          	auipc	a0,0x2
ffffffffc02029c6:	36e50513          	addi	a0,a0,878 # ffffffffc0204d30 <etext+0xe70>
ffffffffc02029ca:	a3dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02029ce:	00002697          	auipc	a3,0x2
ffffffffc02029d2:	72a68693          	addi	a3,a3,1834 # ffffffffc02050f8 <etext+0x1238>
ffffffffc02029d6:	00002617          	auipc	a2,0x2
ffffffffc02029da:	eba60613          	addi	a2,a2,-326 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02029de:	19500593          	li	a1,405
ffffffffc02029e2:	00002517          	auipc	a0,0x2
ffffffffc02029e6:	34e50513          	addi	a0,a0,846 # ffffffffc0204d30 <etext+0xe70>
ffffffffc02029ea:	a1dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p) == 1);
ffffffffc02029ee:	00003697          	auipc	a3,0x3
ffffffffc02029f2:	80268693          	addi	a3,a3,-2046 # ffffffffc02051f0 <etext+0x1330>
ffffffffc02029f6:	00002617          	auipc	a2,0x2
ffffffffc02029fa:	e9a60613          	addi	a2,a2,-358 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02029fe:	1ad00593          	li	a1,429
ffffffffc0202a02:	00002517          	auipc	a0,0x2
ffffffffc0202a06:	32e50513          	addi	a0,a0,814 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202a0a:	9fdfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a0e:	00002697          	auipc	a3,0x2
ffffffffc0202a12:	7a268693          	addi	a3,a3,1954 # ffffffffc02051b0 <etext+0x12f0>
ffffffffc0202a16:	00002617          	auipc	a2,0x2
ffffffffc0202a1a:	e7a60613          	addi	a2,a2,-390 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202a1e:	1ac00593          	li	a1,428
ffffffffc0202a22:	00002517          	auipc	a0,0x2
ffffffffc0202a26:	30e50513          	addi	a0,a0,782 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202a2a:	9ddfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a2e:	00002697          	auipc	a3,0x2
ffffffffc0202a32:	65268693          	addi	a3,a3,1618 # ffffffffc0205080 <etext+0x11c0>
ffffffffc0202a36:	00002617          	auipc	a2,0x2
ffffffffc0202a3a:	e5a60613          	addi	a2,a2,-422 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202a3e:	18700593          	li	a1,391
ffffffffc0202a42:	00002517          	auipc	a0,0x2
ffffffffc0202a46:	2ee50513          	addi	a0,a0,750 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202a4a:	9bdfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202a4e:	00002697          	auipc	a3,0x2
ffffffffc0202a52:	4d268693          	addi	a3,a3,1234 # ffffffffc0204f20 <etext+0x1060>
ffffffffc0202a56:	00002617          	auipc	a2,0x2
ffffffffc0202a5a:	e3a60613          	addi	a2,a2,-454 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202a5e:	18600593          	li	a1,390
ffffffffc0202a62:	00002517          	auipc	a0,0x2
ffffffffc0202a66:	2ce50513          	addi	a0,a0,718 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202a6a:	99dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a6e:	00002697          	auipc	a3,0x2
ffffffffc0202a72:	62a68693          	addi	a3,a3,1578 # ffffffffc0205098 <etext+0x11d8>
ffffffffc0202a76:	00002617          	auipc	a2,0x2
ffffffffc0202a7a:	e1a60613          	addi	a2,a2,-486 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202a7e:	18300593          	li	a1,387
ffffffffc0202a82:	00002517          	auipc	a0,0x2
ffffffffc0202a86:	2ae50513          	addi	a0,a0,686 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202a8a:	97dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a8e:	00002697          	auipc	a3,0x2
ffffffffc0202a92:	47a68693          	addi	a3,a3,1146 # ffffffffc0204f08 <etext+0x1048>
ffffffffc0202a96:	00002617          	auipc	a2,0x2
ffffffffc0202a9a:	dfa60613          	addi	a2,a2,-518 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202a9e:	18200593          	li	a1,386
ffffffffc0202aa2:	00002517          	auipc	a0,0x2
ffffffffc0202aa6:	28e50513          	addi	a0,a0,654 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202aaa:	95dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202aae:	00002697          	auipc	a3,0x2
ffffffffc0202ab2:	4fa68693          	addi	a3,a3,1274 # ffffffffc0204fa8 <etext+0x10e8>
ffffffffc0202ab6:	00002617          	auipc	a2,0x2
ffffffffc0202aba:	dda60613          	addi	a2,a2,-550 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202abe:	18100593          	li	a1,385
ffffffffc0202ac2:	00002517          	auipc	a0,0x2
ffffffffc0202ac6:	26e50513          	addi	a0,a0,622 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202aca:	93dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202ace:	00002697          	auipc	a3,0x2
ffffffffc0202ad2:	5b268693          	addi	a3,a3,1458 # ffffffffc0205080 <etext+0x11c0>
ffffffffc0202ad6:	00002617          	auipc	a2,0x2
ffffffffc0202ada:	dba60613          	addi	a2,a2,-582 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202ade:	18000593          	li	a1,384
ffffffffc0202ae2:	00002517          	auipc	a0,0x2
ffffffffc0202ae6:	24e50513          	addi	a0,a0,590 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202aea:	91dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202aee:	00002697          	auipc	a3,0x2
ffffffffc0202af2:	57a68693          	addi	a3,a3,1402 # ffffffffc0205068 <etext+0x11a8>
ffffffffc0202af6:	00002617          	auipc	a2,0x2
ffffffffc0202afa:	d9a60613          	addi	a2,a2,-614 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202afe:	17f00593          	li	a1,383
ffffffffc0202b02:	00002517          	auipc	a0,0x2
ffffffffc0202b06:	22e50513          	addi	a0,a0,558 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202b0a:	8fdfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202b0e:	00002697          	auipc	a3,0x2
ffffffffc0202b12:	52a68693          	addi	a3,a3,1322 # ffffffffc0205038 <etext+0x1178>
ffffffffc0202b16:	00002617          	auipc	a2,0x2
ffffffffc0202b1a:	d7a60613          	addi	a2,a2,-646 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202b1e:	17e00593          	li	a1,382
ffffffffc0202b22:	00002517          	auipc	a0,0x2
ffffffffc0202b26:	20e50513          	addi	a0,a0,526 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202b2a:	8ddfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202b2e:	00002697          	auipc	a3,0x2
ffffffffc0202b32:	4f268693          	addi	a3,a3,1266 # ffffffffc0205020 <etext+0x1160>
ffffffffc0202b36:	00002617          	auipc	a2,0x2
ffffffffc0202b3a:	d5a60613          	addi	a2,a2,-678 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202b3e:	17c00593          	li	a1,380
ffffffffc0202b42:	00002517          	auipc	a0,0x2
ffffffffc0202b46:	1ee50513          	addi	a0,a0,494 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202b4a:	8bdfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b4e:	00002697          	auipc	a3,0x2
ffffffffc0202b52:	4b268693          	addi	a3,a3,1202 # ffffffffc0205000 <etext+0x1140>
ffffffffc0202b56:	00002617          	auipc	a2,0x2
ffffffffc0202b5a:	d3a60613          	addi	a2,a2,-710 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202b5e:	17b00593          	li	a1,379
ffffffffc0202b62:	00002517          	auipc	a0,0x2
ffffffffc0202b66:	1ce50513          	addi	a0,a0,462 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202b6a:	89dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b6e:	00002697          	auipc	a3,0x2
ffffffffc0202b72:	48268693          	addi	a3,a3,1154 # ffffffffc0204ff0 <etext+0x1130>
ffffffffc0202b76:	00002617          	auipc	a2,0x2
ffffffffc0202b7a:	d1a60613          	addi	a2,a2,-742 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202b7e:	17a00593          	li	a1,378
ffffffffc0202b82:	00002517          	auipc	a0,0x2
ffffffffc0202b86:	1ae50513          	addi	a0,a0,430 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202b8a:	87dfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202b8e:	00002697          	auipc	a3,0x2
ffffffffc0202b92:	45268693          	addi	a3,a3,1106 # ffffffffc0204fe0 <etext+0x1120>
ffffffffc0202b96:	00002617          	auipc	a2,0x2
ffffffffc0202b9a:	cfa60613          	addi	a2,a2,-774 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202b9e:	17900593          	li	a1,377
ffffffffc0202ba2:	00002517          	auipc	a0,0x2
ffffffffc0202ba6:	18e50513          	addi	a0,a0,398 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202baa:	85dfd0ef          	jal	ffffffffc0200406 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202bae:	00002617          	auipc	a2,0x2
ffffffffc0202bb2:	13a60613          	addi	a2,a2,314 # ffffffffc0204ce8 <etext+0xe28>
ffffffffc0202bb6:	08000593          	li	a1,128
ffffffffc0202bba:	00002517          	auipc	a0,0x2
ffffffffc0202bbe:	17650513          	addi	a0,a0,374 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202bc2:	845fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202bc6:	00002697          	auipc	a3,0x2
ffffffffc0202bca:	37268693          	addi	a3,a3,882 # ffffffffc0204f38 <etext+0x1078>
ffffffffc0202bce:	00002617          	auipc	a2,0x2
ffffffffc0202bd2:	cc260613          	addi	a2,a2,-830 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202bd6:	17400593          	li	a1,372
ffffffffc0202bda:	00002517          	auipc	a0,0x2
ffffffffc0202bde:	15650513          	addi	a0,a0,342 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202be2:	825fd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202be6:	00002697          	auipc	a3,0x2
ffffffffc0202bea:	3c268693          	addi	a3,a3,962 # ffffffffc0204fa8 <etext+0x10e8>
ffffffffc0202bee:	00002617          	auipc	a2,0x2
ffffffffc0202bf2:	ca260613          	addi	a2,a2,-862 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202bf6:	17800593          	li	a1,376
ffffffffc0202bfa:	00002517          	auipc	a0,0x2
ffffffffc0202bfe:	13650513          	addi	a0,a0,310 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202c02:	805fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202c06:	00002697          	auipc	a3,0x2
ffffffffc0202c0a:	36268693          	addi	a3,a3,866 # ffffffffc0204f68 <etext+0x10a8>
ffffffffc0202c0e:	00002617          	auipc	a2,0x2
ffffffffc0202c12:	c8260613          	addi	a2,a2,-894 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202c16:	17700593          	li	a1,375
ffffffffc0202c1a:	00002517          	auipc	a0,0x2
ffffffffc0202c1e:	11650513          	addi	a0,a0,278 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202c22:	fe4fd0ef          	jal	ffffffffc0200406 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202c26:	86d6                	mv	a3,s5
ffffffffc0202c28:	00002617          	auipc	a2,0x2
ffffffffc0202c2c:	01860613          	addi	a2,a2,24 # ffffffffc0204c40 <etext+0xd80>
ffffffffc0202c30:	17300593          	li	a1,371
ffffffffc0202c34:	00002517          	auipc	a0,0x2
ffffffffc0202c38:	0fc50513          	addi	a0,a0,252 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202c3c:	fcafd0ef          	jal	ffffffffc0200406 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202c40:	00002617          	auipc	a2,0x2
ffffffffc0202c44:	00060613          	mv	a2,a2
ffffffffc0202c48:	17200593          	li	a1,370
ffffffffc0202c4c:	00002517          	auipc	a0,0x2
ffffffffc0202c50:	0e450513          	addi	a0,a0,228 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202c54:	fb2fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202c58:	00002697          	auipc	a3,0x2
ffffffffc0202c5c:	2c868693          	addi	a3,a3,712 # ffffffffc0204f20 <etext+0x1060>
ffffffffc0202c60:	00002617          	auipc	a2,0x2
ffffffffc0202c64:	c3060613          	addi	a2,a2,-976 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202c68:	17000593          	li	a1,368
ffffffffc0202c6c:	00002517          	auipc	a0,0x2
ffffffffc0202c70:	0c450513          	addi	a0,a0,196 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202c74:	f92fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c78:	00002697          	auipc	a3,0x2
ffffffffc0202c7c:	29068693          	addi	a3,a3,656 # ffffffffc0204f08 <etext+0x1048>
ffffffffc0202c80:	00002617          	auipc	a2,0x2
ffffffffc0202c84:	c1060613          	addi	a2,a2,-1008 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202c88:	16f00593          	li	a1,367
ffffffffc0202c8c:	00002517          	auipc	a0,0x2
ffffffffc0202c90:	0a450513          	addi	a0,a0,164 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202c94:	f72fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c98:	00002697          	auipc	a3,0x2
ffffffffc0202c9c:	62068693          	addi	a3,a3,1568 # ffffffffc02052b8 <etext+0x13f8>
ffffffffc0202ca0:	00002617          	auipc	a2,0x2
ffffffffc0202ca4:	bf060613          	addi	a2,a2,-1040 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202ca8:	1b600593          	li	a1,438
ffffffffc0202cac:	00002517          	auipc	a0,0x2
ffffffffc0202cb0:	08450513          	addi	a0,a0,132 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202cb4:	f52fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202cb8:	00002697          	auipc	a3,0x2
ffffffffc0202cbc:	5c868693          	addi	a3,a3,1480 # ffffffffc0205280 <etext+0x13c0>
ffffffffc0202cc0:	00002617          	auipc	a2,0x2
ffffffffc0202cc4:	bd060613          	addi	a2,a2,-1072 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202cc8:	1b300593          	li	a1,435
ffffffffc0202ccc:	00002517          	auipc	a0,0x2
ffffffffc0202cd0:	06450513          	addi	a0,a0,100 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202cd4:	f32fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202cd8:	00002697          	auipc	a3,0x2
ffffffffc0202cdc:	57868693          	addi	a3,a3,1400 # ffffffffc0205250 <etext+0x1390>
ffffffffc0202ce0:	00002617          	auipc	a2,0x2
ffffffffc0202ce4:	bb060613          	addi	a2,a2,-1104 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202ce8:	1af00593          	li	a1,431
ffffffffc0202cec:	00002517          	auipc	a0,0x2
ffffffffc0202cf0:	04450513          	addi	a0,a0,68 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202cf4:	f12fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202cf8:	00002697          	auipc	a3,0x2
ffffffffc0202cfc:	51068693          	addi	a3,a3,1296 # ffffffffc0205208 <etext+0x1348>
ffffffffc0202d00:	00002617          	auipc	a2,0x2
ffffffffc0202d04:	b9060613          	addi	a2,a2,-1136 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202d08:	1ae00593          	li	a1,430
ffffffffc0202d0c:	00002517          	auipc	a0,0x2
ffffffffc0202d10:	02450513          	addi	a0,a0,36 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202d14:	ef2fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202d18:	00002697          	auipc	a3,0x2
ffffffffc0202d1c:	13868693          	addi	a3,a3,312 # ffffffffc0204e50 <etext+0xf90>
ffffffffc0202d20:	00002617          	auipc	a2,0x2
ffffffffc0202d24:	b7060613          	addi	a2,a2,-1168 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202d28:	16700593          	li	a1,359
ffffffffc0202d2c:	00002517          	auipc	a0,0x2
ffffffffc0202d30:	00450513          	addi	a0,a0,4 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202d34:	ed2fd0ef          	jal	ffffffffc0200406 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202d38:	00002617          	auipc	a2,0x2
ffffffffc0202d3c:	fb060613          	addi	a2,a2,-80 # ffffffffc0204ce8 <etext+0xe28>
ffffffffc0202d40:	0cb00593          	li	a1,203
ffffffffc0202d44:	00002517          	auipc	a0,0x2
ffffffffc0202d48:	fec50513          	addi	a0,a0,-20 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202d4c:	ebafd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202d50:	00002697          	auipc	a3,0x2
ffffffffc0202d54:	16068693          	addi	a3,a3,352 # ffffffffc0204eb0 <etext+0xff0>
ffffffffc0202d58:	00002617          	auipc	a2,0x2
ffffffffc0202d5c:	b3860613          	addi	a2,a2,-1224 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202d60:	16e00593          	li	a1,366
ffffffffc0202d64:	00002517          	auipc	a0,0x2
ffffffffc0202d68:	fcc50513          	addi	a0,a0,-52 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202d6c:	e9afd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d70:	00002697          	auipc	a3,0x2
ffffffffc0202d74:	11068693          	addi	a3,a3,272 # ffffffffc0204e80 <etext+0xfc0>
ffffffffc0202d78:	00002617          	auipc	a2,0x2
ffffffffc0202d7c:	b1860613          	addi	a2,a2,-1256 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202d80:	16b00593          	li	a1,363
ffffffffc0202d84:	00002517          	auipc	a0,0x2
ffffffffc0202d88:	fac50513          	addi	a0,a0,-84 # ffffffffc0204d30 <etext+0xe70>
ffffffffc0202d8c:	e7afd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202d90 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d90:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202d92:	00002697          	auipc	a3,0x2
ffffffffc0202d96:	56e68693          	addi	a3,a3,1390 # ffffffffc0205300 <etext+0x1440>
ffffffffc0202d9a:	00002617          	auipc	a2,0x2
ffffffffc0202d9e:	af660613          	addi	a2,a2,-1290 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202da2:	08800593          	li	a1,136
ffffffffc0202da6:	00002517          	auipc	a0,0x2
ffffffffc0202daa:	57a50513          	addi	a0,a0,1402 # ffffffffc0205320 <etext+0x1460>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202dae:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202db0:	e56fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202db4 <find_vma>:
    if (mm != NULL)
ffffffffc0202db4:	c505                	beqz	a0,ffffffffc0202ddc <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc0202db6:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202db8:	c781                	beqz	a5,ffffffffc0202dc0 <find_vma+0xc>
ffffffffc0202dba:	6798                	ld	a4,8(a5)
ffffffffc0202dbc:	02e5f363          	bgeu	a1,a4,ffffffffc0202de2 <find_vma+0x2e>
    return listelm->next;
ffffffffc0202dc0:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc0202dc2:	00f50d63          	beq	a0,a5,ffffffffc0202ddc <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202dc6:	fe87b703          	ld	a4,-24(a5) # fffffffffdffffe8 <end+0x3ddf2af8>
ffffffffc0202dca:	00e5e663          	bltu	a1,a4,ffffffffc0202dd6 <find_vma+0x22>
ffffffffc0202dce:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202dd2:	00e5ee63          	bltu	a1,a4,ffffffffc0202dee <find_vma+0x3a>
ffffffffc0202dd6:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202dd8:	fef517e3          	bne	a0,a5,ffffffffc0202dc6 <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc0202ddc:	4781                	li	a5,0
}
ffffffffc0202dde:	853e                	mv	a0,a5
ffffffffc0202de0:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202de2:	6b98                	ld	a4,16(a5)
ffffffffc0202de4:	fce5fee3          	bgeu	a1,a4,ffffffffc0202dc0 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0202de8:	e91c                	sd	a5,16(a0)
}
ffffffffc0202dea:	853e                	mv	a0,a5
ffffffffc0202dec:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202dee:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202df0:	e91c                	sd	a5,16(a0)
ffffffffc0202df2:	bfe5                	j	ffffffffc0202dea <find_vma+0x36>

ffffffffc0202df4 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202df4:	6590                	ld	a2,8(a1)
ffffffffc0202df6:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202dfa:	1141                	addi	sp,sp,-16
ffffffffc0202dfc:	e406                	sd	ra,8(sp)
ffffffffc0202dfe:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e00:	01066763          	bltu	a2,a6,ffffffffc0202e0e <insert_vma_struct+0x1a>
ffffffffc0202e04:	a8b9                	j	ffffffffc0202e62 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e06:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202e0a:	04e66763          	bltu	a2,a4,ffffffffc0202e58 <insert_vma_struct+0x64>
ffffffffc0202e0e:	86be                	mv	a3,a5
ffffffffc0202e10:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202e12:	fef51ae3          	bne	a0,a5,ffffffffc0202e06 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202e16:	02a68463          	beq	a3,a0,ffffffffc0202e3e <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202e1a:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e1e:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202e22:	08e8f063          	bgeu	a7,a4,ffffffffc0202ea2 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e26:	04e66e63          	bltu	a2,a4,ffffffffc0202e82 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc0202e2a:	00f50a63          	beq	a0,a5,ffffffffc0202e3e <insert_vma_struct+0x4a>
ffffffffc0202e2e:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e32:	05076863          	bltu	a4,a6,ffffffffc0202e82 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0202e36:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202e3a:	02c77263          	bgeu	a4,a2,ffffffffc0202e5e <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202e3e:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202e40:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202e42:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202e46:	e390                	sd	a2,0(a5)
ffffffffc0202e48:	e690                	sd	a2,8(a3)
}
ffffffffc0202e4a:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202e4c:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202e4e:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202e50:	2705                	addiw	a4,a4,1
ffffffffc0202e52:	d118                	sw	a4,32(a0)
}
ffffffffc0202e54:	0141                	addi	sp,sp,16
ffffffffc0202e56:	8082                	ret
    if (le_prev != list)
ffffffffc0202e58:	fca691e3          	bne	a3,a0,ffffffffc0202e1a <insert_vma_struct+0x26>
ffffffffc0202e5c:	bfd9                	j	ffffffffc0202e32 <insert_vma_struct+0x3e>
ffffffffc0202e5e:	f33ff0ef          	jal	ffffffffc0202d90 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e62:	00002697          	auipc	a3,0x2
ffffffffc0202e66:	4ce68693          	addi	a3,a3,1230 # ffffffffc0205330 <etext+0x1470>
ffffffffc0202e6a:	00002617          	auipc	a2,0x2
ffffffffc0202e6e:	a2660613          	addi	a2,a2,-1498 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202e72:	08e00593          	li	a1,142
ffffffffc0202e76:	00002517          	auipc	a0,0x2
ffffffffc0202e7a:	4aa50513          	addi	a0,a0,1194 # ffffffffc0205320 <etext+0x1460>
ffffffffc0202e7e:	d88fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e82:	00002697          	auipc	a3,0x2
ffffffffc0202e86:	4ee68693          	addi	a3,a3,1262 # ffffffffc0205370 <etext+0x14b0>
ffffffffc0202e8a:	00002617          	auipc	a2,0x2
ffffffffc0202e8e:	a0660613          	addi	a2,a2,-1530 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202e92:	08700593          	li	a1,135
ffffffffc0202e96:	00002517          	auipc	a0,0x2
ffffffffc0202e9a:	48a50513          	addi	a0,a0,1162 # ffffffffc0205320 <etext+0x1460>
ffffffffc0202e9e:	d68fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202ea2:	00002697          	auipc	a3,0x2
ffffffffc0202ea6:	4ae68693          	addi	a3,a3,1198 # ffffffffc0205350 <etext+0x1490>
ffffffffc0202eaa:	00002617          	auipc	a2,0x2
ffffffffc0202eae:	9e660613          	addi	a2,a2,-1562 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0202eb2:	08600593          	li	a1,134
ffffffffc0202eb6:	00002517          	auipc	a0,0x2
ffffffffc0202eba:	46a50513          	addi	a0,a0,1130 # ffffffffc0205320 <etext+0x1460>
ffffffffc0202ebe:	d48fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202ec2 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202ec2:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ec4:	03000513          	li	a0,48
{
ffffffffc0202ec8:	fc06                	sd	ra,56(sp)
ffffffffc0202eca:	f822                	sd	s0,48(sp)
ffffffffc0202ecc:	f426                	sd	s1,40(sp)
ffffffffc0202ece:	f04a                	sd	s2,32(sp)
ffffffffc0202ed0:	ec4e                	sd	s3,24(sp)
ffffffffc0202ed2:	e852                	sd	s4,16(sp)
ffffffffc0202ed4:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ed6:	bc3fe0ef          	jal	ffffffffc0201a98 <kmalloc>
    if (mm != NULL)
ffffffffc0202eda:	18050a63          	beqz	a0,ffffffffc020306e <vmm_init+0x1ac>
ffffffffc0202ede:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0202ee0:	e508                	sd	a0,8(a0)
ffffffffc0202ee2:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202ee4:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202ee8:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202eec:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202ef0:	02053423          	sd	zero,40(a0)
ffffffffc0202ef4:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202ef8:	03000513          	li	a0,48
ffffffffc0202efc:	b9dfe0ef          	jal	ffffffffc0201a98 <kmalloc>
    if (vma != NULL)
ffffffffc0202f00:	14050763          	beqz	a0,ffffffffc020304e <vmm_init+0x18c>
        vma->vm_end = vm_end;
ffffffffc0202f04:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0202f08:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f0a:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0202f0e:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f10:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0202f12:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0202f14:	8522                	mv	a0,s0
ffffffffc0202f16:	edfff0ef          	jal	ffffffffc0202df4 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202f1a:	fcf9                	bnez	s1,ffffffffc0202ef8 <vmm_init+0x36>
ffffffffc0202f1c:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f20:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f24:	03000513          	li	a0,48
ffffffffc0202f28:	b71fe0ef          	jal	ffffffffc0201a98 <kmalloc>
    if (vma != NULL)
ffffffffc0202f2c:	16050163          	beqz	a0,ffffffffc020308e <vmm_init+0x1cc>
        vma->vm_end = vm_end;
ffffffffc0202f30:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0202f34:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f36:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0202f3a:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f3c:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f3e:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0202f40:	8522                	mv	a0,s0
ffffffffc0202f42:	eb3ff0ef          	jal	ffffffffc0202df4 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f46:	fd249fe3          	bne	s1,s2,ffffffffc0202f24 <vmm_init+0x62>
    return listelm->next;
ffffffffc0202f4a:	641c                	ld	a5,8(s0)
ffffffffc0202f4c:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202f4e:	1fb00593          	li	a1,507
ffffffffc0202f52:	8abe                	mv	s5,a5
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202f54:	20f40d63          	beq	s0,a5,ffffffffc020316e <vmm_init+0x2ac>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202f58:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202f5c:	ffe70693          	addi	a3,a4,-2
ffffffffc0202f60:	14d61763          	bne	a2,a3,ffffffffc02030ae <vmm_init+0x1ec>
ffffffffc0202f64:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202f68:	14e69363          	bne	a3,a4,ffffffffc02030ae <vmm_init+0x1ec>
    for (i = 1; i <= step2; i++)
ffffffffc0202f6c:	0715                	addi	a4,a4,5
ffffffffc0202f6e:	679c                	ld	a5,8(a5)
ffffffffc0202f70:	feb712e3          	bne	a4,a1,ffffffffc0202f54 <vmm_init+0x92>
ffffffffc0202f74:	491d                	li	s2,7
ffffffffc0202f76:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202f78:	85a6                	mv	a1,s1
ffffffffc0202f7a:	8522                	mv	a0,s0
ffffffffc0202f7c:	e39ff0ef          	jal	ffffffffc0202db4 <find_vma>
ffffffffc0202f80:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0202f82:	22050663          	beqz	a0,ffffffffc02031ae <vmm_init+0x2ec>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202f86:	00148593          	addi	a1,s1,1
ffffffffc0202f8a:	8522                	mv	a0,s0
ffffffffc0202f8c:	e29ff0ef          	jal	ffffffffc0202db4 <find_vma>
ffffffffc0202f90:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202f92:	1e050e63          	beqz	a0,ffffffffc020318e <vmm_init+0x2cc>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202f96:	85ca                	mv	a1,s2
ffffffffc0202f98:	8522                	mv	a0,s0
ffffffffc0202f9a:	e1bff0ef          	jal	ffffffffc0202db4 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202f9e:	1a051863          	bnez	a0,ffffffffc020314e <vmm_init+0x28c>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202fa2:	00348593          	addi	a1,s1,3
ffffffffc0202fa6:	8522                	mv	a0,s0
ffffffffc0202fa8:	e0dff0ef          	jal	ffffffffc0202db4 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202fac:	18051163          	bnez	a0,ffffffffc020312e <vmm_init+0x26c>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202fb0:	00448593          	addi	a1,s1,4
ffffffffc0202fb4:	8522                	mv	a0,s0
ffffffffc0202fb6:	dffff0ef          	jal	ffffffffc0202db4 <find_vma>
        assert(vma5 == NULL);
ffffffffc0202fba:	14051a63          	bnez	a0,ffffffffc020310e <vmm_init+0x24c>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202fbe:	008a3783          	ld	a5,8(s4)
ffffffffc0202fc2:	12979663          	bne	a5,s1,ffffffffc02030ee <vmm_init+0x22c>
ffffffffc0202fc6:	010a3783          	ld	a5,16(s4)
ffffffffc0202fca:	13279263          	bne	a5,s2,ffffffffc02030ee <vmm_init+0x22c>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202fce:	0089b783          	ld	a5,8(s3)
ffffffffc0202fd2:	0e979e63          	bne	a5,s1,ffffffffc02030ce <vmm_init+0x20c>
ffffffffc0202fd6:	0109b783          	ld	a5,16(s3)
ffffffffc0202fda:	0f279a63          	bne	a5,s2,ffffffffc02030ce <vmm_init+0x20c>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202fde:	0495                	addi	s1,s1,5
ffffffffc0202fe0:	1f900793          	li	a5,505
ffffffffc0202fe4:	0915                	addi	s2,s2,5
ffffffffc0202fe6:	f8f499e3          	bne	s1,a5,ffffffffc0202f78 <vmm_init+0xb6>
ffffffffc0202fea:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0202fec:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0202fee:	85a6                	mv	a1,s1
ffffffffc0202ff0:	8522                	mv	a0,s0
ffffffffc0202ff2:	dc3ff0ef          	jal	ffffffffc0202db4 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0202ff6:	1c051c63          	bnez	a0,ffffffffc02031ce <vmm_init+0x30c>
    for (i = 4; i >= 0; i--)
ffffffffc0202ffa:	14fd                	addi	s1,s1,-1
ffffffffc0202ffc:	ff2499e3          	bne	s1,s2,ffffffffc0202fee <vmm_init+0x12c>
    while ((le = list_next(list)) != list)
ffffffffc0203000:	028a8063          	beq	s5,s0,ffffffffc0203020 <vmm_init+0x15e>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203004:	008ab783          	ld	a5,8(s5) # 1008 <kern_entry-0xffffffffc01feff8>
ffffffffc0203008:	000ab703          	ld	a4,0(s5)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020300c:	fe0a8513          	addi	a0,s5,-32
    prev->next = next;
ffffffffc0203010:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203012:	e398                	sd	a4,0(a5)
ffffffffc0203014:	b2bfe0ef          	jal	ffffffffc0201b3e <kfree>
    return listelm->next;
ffffffffc0203018:	641c                	ld	a5,8(s0)
ffffffffc020301a:	8abe                	mv	s5,a5
    while ((le = list_next(list)) != list)
ffffffffc020301c:	fef414e3          	bne	s0,a5,ffffffffc0203004 <vmm_init+0x142>
    kfree(mm); // kfree mm
ffffffffc0203020:	8522                	mv	a0,s0
ffffffffc0203022:	b1dfe0ef          	jal	ffffffffc0201b3e <kfree>
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203026:	00002517          	auipc	a0,0x2
ffffffffc020302a:	4ca50513          	addi	a0,a0,1226 # ffffffffc02054f0 <etext+0x1630>
ffffffffc020302e:	966fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0203032:	7442                	ld	s0,48(sp)
ffffffffc0203034:	70e2                	ld	ra,56(sp)
ffffffffc0203036:	74a2                	ld	s1,40(sp)
ffffffffc0203038:	7902                	ld	s2,32(sp)
ffffffffc020303a:	69e2                	ld	s3,24(sp)
ffffffffc020303c:	6a42                	ld	s4,16(sp)
ffffffffc020303e:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203040:	00002517          	auipc	a0,0x2
ffffffffc0203044:	4d050513          	addi	a0,a0,1232 # ffffffffc0205510 <etext+0x1650>
}
ffffffffc0203048:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc020304a:	94afd06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc020304e:	00002697          	auipc	a3,0x2
ffffffffc0203052:	35268693          	addi	a3,a3,850 # ffffffffc02053a0 <etext+0x14e0>
ffffffffc0203056:	00002617          	auipc	a2,0x2
ffffffffc020305a:	83a60613          	addi	a2,a2,-1990 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020305e:	0da00593          	li	a1,218
ffffffffc0203062:	00002517          	auipc	a0,0x2
ffffffffc0203066:	2be50513          	addi	a0,a0,702 # ffffffffc0205320 <etext+0x1460>
ffffffffc020306a:	b9cfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(mm != NULL);
ffffffffc020306e:	00002697          	auipc	a3,0x2
ffffffffc0203072:	32268693          	addi	a3,a3,802 # ffffffffc0205390 <etext+0x14d0>
ffffffffc0203076:	00002617          	auipc	a2,0x2
ffffffffc020307a:	81a60613          	addi	a2,a2,-2022 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020307e:	0d200593          	li	a1,210
ffffffffc0203082:	00002517          	auipc	a0,0x2
ffffffffc0203086:	29e50513          	addi	a0,a0,670 # ffffffffc0205320 <etext+0x1460>
ffffffffc020308a:	b7cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma != NULL);
ffffffffc020308e:	00002697          	auipc	a3,0x2
ffffffffc0203092:	31268693          	addi	a3,a3,786 # ffffffffc02053a0 <etext+0x14e0>
ffffffffc0203096:	00001617          	auipc	a2,0x1
ffffffffc020309a:	7fa60613          	addi	a2,a2,2042 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020309e:	0e100593          	li	a1,225
ffffffffc02030a2:	00002517          	auipc	a0,0x2
ffffffffc02030a6:	27e50513          	addi	a0,a0,638 # ffffffffc0205320 <etext+0x1460>
ffffffffc02030aa:	b5cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02030ae:	00002697          	auipc	a3,0x2
ffffffffc02030b2:	31a68693          	addi	a3,a3,794 # ffffffffc02053c8 <etext+0x1508>
ffffffffc02030b6:	00001617          	auipc	a2,0x1
ffffffffc02030ba:	7da60613          	addi	a2,a2,2010 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02030be:	0eb00593          	li	a1,235
ffffffffc02030c2:	00002517          	auipc	a0,0x2
ffffffffc02030c6:	25e50513          	addi	a0,a0,606 # ffffffffc0205320 <etext+0x1460>
ffffffffc02030ca:	b3cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02030ce:	00002697          	auipc	a3,0x2
ffffffffc02030d2:	3b268693          	addi	a3,a3,946 # ffffffffc0205480 <etext+0x15c0>
ffffffffc02030d6:	00001617          	auipc	a2,0x1
ffffffffc02030da:	7ba60613          	addi	a2,a2,1978 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02030de:	0fd00593          	li	a1,253
ffffffffc02030e2:	00002517          	auipc	a0,0x2
ffffffffc02030e6:	23e50513          	addi	a0,a0,574 # ffffffffc0205320 <etext+0x1460>
ffffffffc02030ea:	b1cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02030ee:	00002697          	auipc	a3,0x2
ffffffffc02030f2:	36268693          	addi	a3,a3,866 # ffffffffc0205450 <etext+0x1590>
ffffffffc02030f6:	00001617          	auipc	a2,0x1
ffffffffc02030fa:	79a60613          	addi	a2,a2,1946 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02030fe:	0fc00593          	li	a1,252
ffffffffc0203102:	00002517          	auipc	a0,0x2
ffffffffc0203106:	21e50513          	addi	a0,a0,542 # ffffffffc0205320 <etext+0x1460>
ffffffffc020310a:	afcfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma5 == NULL);
ffffffffc020310e:	00002697          	auipc	a3,0x2
ffffffffc0203112:	33268693          	addi	a3,a3,818 # ffffffffc0205440 <etext+0x1580>
ffffffffc0203116:	00001617          	auipc	a2,0x1
ffffffffc020311a:	77a60613          	addi	a2,a2,1914 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020311e:	0fa00593          	li	a1,250
ffffffffc0203122:	00002517          	auipc	a0,0x2
ffffffffc0203126:	1fe50513          	addi	a0,a0,510 # ffffffffc0205320 <etext+0x1460>
ffffffffc020312a:	adcfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma4 == NULL);
ffffffffc020312e:	00002697          	auipc	a3,0x2
ffffffffc0203132:	30268693          	addi	a3,a3,770 # ffffffffc0205430 <etext+0x1570>
ffffffffc0203136:	00001617          	auipc	a2,0x1
ffffffffc020313a:	75a60613          	addi	a2,a2,1882 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020313e:	0f800593          	li	a1,248
ffffffffc0203142:	00002517          	auipc	a0,0x2
ffffffffc0203146:	1de50513          	addi	a0,a0,478 # ffffffffc0205320 <etext+0x1460>
ffffffffc020314a:	abcfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma3 == NULL);
ffffffffc020314e:	00002697          	auipc	a3,0x2
ffffffffc0203152:	2d268693          	addi	a3,a3,722 # ffffffffc0205420 <etext+0x1560>
ffffffffc0203156:	00001617          	auipc	a2,0x1
ffffffffc020315a:	73a60613          	addi	a2,a2,1850 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020315e:	0f600593          	li	a1,246
ffffffffc0203162:	00002517          	auipc	a0,0x2
ffffffffc0203166:	1be50513          	addi	a0,a0,446 # ffffffffc0205320 <etext+0x1460>
ffffffffc020316a:	a9cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020316e:	00002697          	auipc	a3,0x2
ffffffffc0203172:	24268693          	addi	a3,a3,578 # ffffffffc02053b0 <etext+0x14f0>
ffffffffc0203176:	00001617          	auipc	a2,0x1
ffffffffc020317a:	71a60613          	addi	a2,a2,1818 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020317e:	0e900593          	li	a1,233
ffffffffc0203182:	00002517          	auipc	a0,0x2
ffffffffc0203186:	19e50513          	addi	a0,a0,414 # ffffffffc0205320 <etext+0x1460>
ffffffffc020318a:	a7cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma2 != NULL);
ffffffffc020318e:	00002697          	auipc	a3,0x2
ffffffffc0203192:	28268693          	addi	a3,a3,642 # ffffffffc0205410 <etext+0x1550>
ffffffffc0203196:	00001617          	auipc	a2,0x1
ffffffffc020319a:	6fa60613          	addi	a2,a2,1786 # ffffffffc0204890 <etext+0x9d0>
ffffffffc020319e:	0f400593          	li	a1,244
ffffffffc02031a2:	00002517          	auipc	a0,0x2
ffffffffc02031a6:	17e50513          	addi	a0,a0,382 # ffffffffc0205320 <etext+0x1460>
ffffffffc02031aa:	a5cfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma1 != NULL);
ffffffffc02031ae:	00002697          	auipc	a3,0x2
ffffffffc02031b2:	25268693          	addi	a3,a3,594 # ffffffffc0205400 <etext+0x1540>
ffffffffc02031b6:	00001617          	auipc	a2,0x1
ffffffffc02031ba:	6da60613          	addi	a2,a2,1754 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02031be:	0f200593          	li	a1,242
ffffffffc02031c2:	00002517          	auipc	a0,0x2
ffffffffc02031c6:	15e50513          	addi	a0,a0,350 # ffffffffc0205320 <etext+0x1460>
ffffffffc02031ca:	a3cfd0ef          	jal	ffffffffc0200406 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc02031ce:	6914                	ld	a3,16(a0)
ffffffffc02031d0:	6510                	ld	a2,8(a0)
ffffffffc02031d2:	0004859b          	sext.w	a1,s1
ffffffffc02031d6:	00002517          	auipc	a0,0x2
ffffffffc02031da:	2da50513          	addi	a0,a0,730 # ffffffffc02054b0 <etext+0x15f0>
ffffffffc02031de:	fb7fc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc02031e2:	00002697          	auipc	a3,0x2
ffffffffc02031e6:	2f668693          	addi	a3,a3,758 # ffffffffc02054d8 <etext+0x1618>
ffffffffc02031ea:	00001617          	auipc	a2,0x1
ffffffffc02031ee:	6a660613          	addi	a2,a2,1702 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02031f2:	10700593          	li	a1,263
ffffffffc02031f6:	00002517          	auipc	a0,0x2
ffffffffc02031fa:	12a50513          	addi	a0,a0,298 # ffffffffc0205320 <etext+0x1460>
ffffffffc02031fe:	a08fd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0203202 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203202:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203204:	9402                	jalr	s0

	jal do_exit
ffffffffc0203206:	418000ef          	jal	ffffffffc020361e <do_exit>

ffffffffc020320a <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc020320a:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020320c:	0e800513          	li	a0,232
{
ffffffffc0203210:	e022                	sd	s0,0(sp)
ffffffffc0203212:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203214:	885fe0ef          	jal	ffffffffc0201a98 <kmalloc>
ffffffffc0203218:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc020321a:	c521                	beqz	a0,ffffffffc0203262 <alloc_proc+0x58>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;
ffffffffc020321c:	57fd                	li	a5,-1
ffffffffc020321e:	1782                	slli	a5,a5,0x20
ffffffffc0203220:	e11c                	sd	a5,0(a0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc0203222:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0203226:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc020322a:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;
ffffffffc020322e:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203232:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203236:	07000613          	li	a2,112
ffffffffc020323a:	4581                	li	a1,0
ffffffffc020323c:	03050513          	addi	a0,a0,48
ffffffffc0203240:	433000ef          	jal	ffffffffc0203e72 <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203244:	0000a797          	auipc	a5,0xa
ffffffffc0203248:	2647b783          	ld	a5,612(a5) # ffffffffc020d4a8 <boot_pgdir_pa>
        proc->tf = NULL;
ffffffffc020324c:	0a043023          	sd	zero,160(s0) # ffffffffc02000a0 <kern_init+0x56>
        proc->flags = 0;
ffffffffc0203250:	0a042823          	sw	zero,176(s0)
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203254:	f45c                	sd	a5,168(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203256:	0b440513          	addi	a0,s0,180
ffffffffc020325a:	4641                	li	a2,16
ffffffffc020325c:	4581                	li	a1,0
ffffffffc020325e:	415000ef          	jal	ffffffffc0203e72 <memset>
    }
    return proc;
}
ffffffffc0203262:	60a2                	ld	ra,8(sp)
ffffffffc0203264:	8522                	mv	a0,s0
ffffffffc0203266:	6402                	ld	s0,0(sp)
ffffffffc0203268:	0141                	addi	sp,sp,16
ffffffffc020326a:	8082                	ret

ffffffffc020326c <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc020326c:	0000a797          	auipc	a5,0xa
ffffffffc0203270:	26c7b783          	ld	a5,620(a5) # ffffffffc020d4d8 <current>
ffffffffc0203274:	73c8                	ld	a0,160(a5)
ffffffffc0203276:	aabfd06f          	j	ffffffffc0200d20 <forkrets>

ffffffffc020327a <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc020327a:	1101                	addi	sp,sp,-32
ffffffffc020327c:	e822                	sd	s0,16(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020327e:	0000a417          	auipc	s0,0xa
ffffffffc0203282:	25a43403          	ld	s0,602(s0) # ffffffffc020d4d8 <current>
{
ffffffffc0203286:	e04a                	sd	s2,0(sp)
    memset(name, 0, sizeof(name));
ffffffffc0203288:	4641                	li	a2,16
{
ffffffffc020328a:	892a                	mv	s2,a0
    memset(name, 0, sizeof(name));
ffffffffc020328c:	4581                	li	a1,0
ffffffffc020328e:	00006517          	auipc	a0,0x6
ffffffffc0203292:	1ba50513          	addi	a0,a0,442 # ffffffffc0209448 <name.2>
{
ffffffffc0203296:	ec06                	sd	ra,24(sp)
ffffffffc0203298:	e426                	sd	s1,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020329a:	4044                	lw	s1,4(s0)
    memset(name, 0, sizeof(name));
ffffffffc020329c:	3d7000ef          	jal	ffffffffc0203e72 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02032a0:	0b440593          	addi	a1,s0,180
ffffffffc02032a4:	463d                	li	a2,15
ffffffffc02032a6:	00006517          	auipc	a0,0x6
ffffffffc02032aa:	1a250513          	addi	a0,a0,418 # ffffffffc0209448 <name.2>
ffffffffc02032ae:	3d7000ef          	jal	ffffffffc0203e84 <memcpy>
ffffffffc02032b2:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032b4:	85a6                	mv	a1,s1
ffffffffc02032b6:	00002517          	auipc	a0,0x2
ffffffffc02032ba:	27250513          	addi	a0,a0,626 # ffffffffc0205528 <etext+0x1668>
ffffffffc02032be:	ed7fc0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc02032c2:	85ca                	mv	a1,s2
ffffffffc02032c4:	00002517          	auipc	a0,0x2
ffffffffc02032c8:	28c50513          	addi	a0,a0,652 # ffffffffc0205550 <etext+0x1690>
ffffffffc02032cc:	ec9fc0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02032d0:	00002517          	auipc	a0,0x2
ffffffffc02032d4:	29050513          	addi	a0,a0,656 # ffffffffc0205560 <etext+0x16a0>
ffffffffc02032d8:	ebdfc0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02032dc:	60e2                	ld	ra,24(sp)
ffffffffc02032de:	6442                	ld	s0,16(sp)
ffffffffc02032e0:	64a2                	ld	s1,8(sp)
ffffffffc02032e2:	6902                	ld	s2,0(sp)
ffffffffc02032e4:	4501                	li	a0,0
ffffffffc02032e6:	6105                	addi	sp,sp,32
ffffffffc02032e8:	8082                	ret

ffffffffc02032ea <proc_run>:
    if (proc != current)
ffffffffc02032ea:	0000a697          	auipc	a3,0xa
ffffffffc02032ee:	1ee68693          	addi	a3,a3,494 # ffffffffc020d4d8 <current>
ffffffffc02032f2:	6298                	ld	a4,0(a3)
ffffffffc02032f4:	06a70363          	beq	a4,a0,ffffffffc020335a <proc_run+0x70>
{
ffffffffc02032f8:	1101                	addi	sp,sp,-32
ffffffffc02032fa:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02032fc:	100027f3          	csrr	a5,sstatus
ffffffffc0203300:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203302:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203304:	eb9d                	bnez	a5,ffffffffc020333a <proc_run+0x50>
        lsatp(proc->pgdir); // 切换页表
ffffffffc0203306:	755c                	ld	a5,168(a0)
        current=proc; // 切换进程
ffffffffc0203308:	e288                	sd	a0,0(a3)
        proc->runs++; // 更新进程相关状态
ffffffffc020330a:	4514                	lw	a3,8(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc020330c:	800005b7          	lui	a1,0x80000
ffffffffc0203310:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc0203314:	2685                	addiw	a3,a3,1
ffffffffc0203316:	e432                	sd	a2,8(sp)
        current->need_resched = 0; // 不需要调度
ffffffffc0203318:	00052c23          	sw	zero,24(a0)
        proc->runs++; // 更新进程相关状态
ffffffffc020331c:	c514                	sw	a3,8(a0)
ffffffffc020331e:	8fcd                	or	a5,a5,a1
ffffffffc0203320:	18079073          	csrw	satp,a5
        switch_to(&old->context,&proc->context); // 上下文切换
ffffffffc0203324:	03050593          	addi	a1,a0,48
ffffffffc0203328:	03070513          	addi	a0,a4,48
ffffffffc020332c:	580000ef          	jal	ffffffffc02038ac <switch_to>
    if (flag) {
ffffffffc0203330:	6622                	ld	a2,8(sp)
ffffffffc0203332:	e205                	bnez	a2,ffffffffc0203352 <proc_run+0x68>
}
ffffffffc0203334:	60e2                	ld	ra,24(sp)
ffffffffc0203336:	6105                	addi	sp,sp,32
ffffffffc0203338:	8082                	ret
ffffffffc020333a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020333c:	d38fd0ef          	jal	ffffffffc0200874 <intr_disable>
        if (proc == current) {
ffffffffc0203340:	0000a697          	auipc	a3,0xa
ffffffffc0203344:	19868693          	addi	a3,a3,408 # ffffffffc020d4d8 <current>
ffffffffc0203348:	6298                	ld	a4,0(a3)
ffffffffc020334a:	6522                	ld	a0,8(sp)
        return 1;
ffffffffc020334c:	4605                	li	a2,1
ffffffffc020334e:	fae51ce3          	bne	a0,a4,ffffffffc0203306 <proc_run+0x1c>
}
ffffffffc0203352:	60e2                	ld	ra,24(sp)
ffffffffc0203354:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203356:	d18fd06f          	j	ffffffffc020086e <intr_enable>
ffffffffc020335a:	8082                	ret

ffffffffc020335c <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc020335c:	0000a717          	auipc	a4,0xa
ffffffffc0203360:	17472703          	lw	a4,372(a4) # ffffffffc020d4d0 <nr_process>
ffffffffc0203364:	6785                	lui	a5,0x1
ffffffffc0203366:	22f75663          	bge	a4,a5,ffffffffc0203592 <do_fork+0x236>
{
ffffffffc020336a:	7179                	addi	sp,sp,-48
ffffffffc020336c:	f022                	sd	s0,32(sp)
ffffffffc020336e:	ec26                	sd	s1,24(sp)
ffffffffc0203370:	e84a                	sd	s2,16(sp)
ffffffffc0203372:	f406                	sd	ra,40(sp)
ffffffffc0203374:	892e                	mv	s2,a1
ffffffffc0203376:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL)
ffffffffc0203378:	e93ff0ef          	jal	ffffffffc020320a <alloc_proc>
ffffffffc020337c:	84aa                	mv	s1,a0
ffffffffc020337e:	20050863          	beqz	a0,ffffffffc020358e <do_fork+0x232>
ffffffffc0203382:	e44e                	sd	s3,8(sp)
    proc->parent = current;
ffffffffc0203384:	0000a997          	auipc	s3,0xa
ffffffffc0203388:	15498993          	addi	s3,s3,340 # ffffffffc020d4d8 <current>
ffffffffc020338c:	0009b783          	ld	a5,0(s3)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203390:	4509                	li	a0,2
    proc->parent = current;
ffffffffc0203392:	f09c                	sd	a5,32(s1)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203394:	8c7fe0ef          	jal	ffffffffc0201c5a <alloc_pages>
    if (page != NULL)
ffffffffc0203398:	1e050763          	beqz	a0,ffffffffc0203586 <do_fork+0x22a>
    return page - pages + nbase;
ffffffffc020339c:	0000a697          	auipc	a3,0xa
ffffffffc02033a0:	12c6b683          	ld	a3,300(a3) # ffffffffc020d4c8 <pages>
ffffffffc02033a4:	00002797          	auipc	a5,0x2
ffffffffc02033a8:	66c7b783          	ld	a5,1644(a5) # ffffffffc0205a10 <nbase>
    return KADDR(page2pa(page));
ffffffffc02033ac:	0000a717          	auipc	a4,0xa
ffffffffc02033b0:	11473703          	ld	a4,276(a4) # ffffffffc020d4c0 <npage>
    return page - pages + nbase;
ffffffffc02033b4:	40d506b3          	sub	a3,a0,a3
ffffffffc02033b8:	8699                	srai	a3,a3,0x6
ffffffffc02033ba:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02033bc:	00c69793          	slli	a5,a3,0xc
ffffffffc02033c0:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02033c2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033c4:	1ee7f963          	bgeu	a5,a4,ffffffffc02035b6 <do_fork+0x25a>
    assert(current->mm == NULL);
ffffffffc02033c8:	0009b783          	ld	a5,0(s3)
ffffffffc02033cc:	0000a717          	auipc	a4,0xa
ffffffffc02033d0:	0ec73703          	ld	a4,236(a4) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc02033d4:	779c                	ld	a5,40(a5)
ffffffffc02033d6:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02033d8:	e894                	sd	a3,16(s1)
    assert(current->mm == NULL);
ffffffffc02033da:	1a079e63          	bnez	a5,ffffffffc0203596 <do_fork+0x23a>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033de:	6789                	lui	a5,0x2
ffffffffc02033e0:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc02033e4:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02033e6:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033e8:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc02033ea:	87b6                	mv	a5,a3
ffffffffc02033ec:	12040713          	addi	a4,s0,288
ffffffffc02033f0:	6a0c                	ld	a1,16(a2)
ffffffffc02033f2:	00063803          	ld	a6,0(a2)
ffffffffc02033f6:	6608                	ld	a0,8(a2)
ffffffffc02033f8:	eb8c                	sd	a1,16(a5)
ffffffffc02033fa:	0107b023          	sd	a6,0(a5)
ffffffffc02033fe:	e788                	sd	a0,8(a5)
ffffffffc0203400:	6e0c                	ld	a1,24(a2)
ffffffffc0203402:	02060613          	addi	a2,a2,32
ffffffffc0203406:	02078793          	addi	a5,a5,32
ffffffffc020340a:	feb7bc23          	sd	a1,-8(a5)
ffffffffc020340e:	fee611e3          	bne	a2,a4,ffffffffc02033f0 <do_fork+0x94>
    proc->tf->gpr.a0 = 0;
ffffffffc0203412:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203416:	10090b63          	beqz	s2,ffffffffc020352c <do_fork+0x1d0>
ffffffffc020341a:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020341e:	00000797          	auipc	a5,0x0
ffffffffc0203422:	e4e78793          	addi	a5,a5,-434 # ffffffffc020326c <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203426:	fc94                	sd	a3,56(s1)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203428:	f89c                	sd	a5,48(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020342a:	100027f3          	csrr	a5,sstatus
ffffffffc020342e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203430:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203432:	10079c63          	bnez	a5,ffffffffc020354a <do_fork+0x1ee>
    if (++last_pid >= MAX_PID)
ffffffffc0203436:	00006517          	auipc	a0,0x6
ffffffffc020343a:	bf652503          	lw	a0,-1034(a0) # ffffffffc020902c <last_pid.1>
ffffffffc020343e:	6789                	lui	a5,0x2
ffffffffc0203440:	2505                	addiw	a0,a0,1
ffffffffc0203442:	00006717          	auipc	a4,0x6
ffffffffc0203446:	bea72523          	sw	a0,-1046(a4) # ffffffffc020902c <last_pid.1>
ffffffffc020344a:	10f55f63          	bge	a0,a5,ffffffffc0203568 <do_fork+0x20c>
    if (last_pid >= next_safe)
ffffffffc020344e:	00006797          	auipc	a5,0x6
ffffffffc0203452:	bda7a783          	lw	a5,-1062(a5) # ffffffffc0209028 <next_safe.0>
ffffffffc0203456:	0000a417          	auipc	s0,0xa
ffffffffc020345a:	00240413          	addi	s0,s0,2 # ffffffffc020d458 <proc_list>
ffffffffc020345e:	06f54563          	blt	a0,a5,ffffffffc02034c8 <do_fork+0x16c>
ffffffffc0203462:	0000a417          	auipc	s0,0xa
ffffffffc0203466:	ff640413          	addi	s0,s0,-10 # ffffffffc020d458 <proc_list>
ffffffffc020346a:	00843883          	ld	a7,8(s0)
        next_safe = MAX_PID;
ffffffffc020346e:	6789                	lui	a5,0x2
ffffffffc0203470:	00006717          	auipc	a4,0x6
ffffffffc0203474:	baf72c23          	sw	a5,-1096(a4) # ffffffffc0209028 <next_safe.0>
ffffffffc0203478:	86aa                	mv	a3,a0
ffffffffc020347a:	4581                	li	a1,0
        while ((le = list_next(le)) != list) // 遍历所有进程
ffffffffc020347c:	04888063          	beq	a7,s0,ffffffffc02034bc <do_fork+0x160>
ffffffffc0203480:	882e                	mv	a6,a1
ffffffffc0203482:	87c6                	mv	a5,a7
ffffffffc0203484:	6609                	lui	a2,0x2
ffffffffc0203486:	a811                	j	ffffffffc020349a <do_fork+0x13e>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203488:	00e6d663          	bge	a3,a4,ffffffffc0203494 <do_fork+0x138>
ffffffffc020348c:	00c75463          	bge	a4,a2,ffffffffc0203494 <do_fork+0x138>
                next_safe = proc->pid;
ffffffffc0203490:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203492:	4805                	li	a6,1
ffffffffc0203494:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) // 遍历所有进程
ffffffffc0203496:	00878d63          	beq	a5,s0,ffffffffc02034b0 <do_fork+0x154>
            if (proc->pid == last_pid)
ffffffffc020349a:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc020349e:	fed715e3          	bne	a4,a3,ffffffffc0203488 <do_fork+0x12c>
                if (++last_pid >= next_safe)
ffffffffc02034a2:	2685                	addiw	a3,a3,1
ffffffffc02034a4:	0cc6db63          	bge	a3,a2,ffffffffc020357a <do_fork+0x21e>
ffffffffc02034a8:	679c                	ld	a5,8(a5)
ffffffffc02034aa:	4585                	li	a1,1
        while ((le = list_next(le)) != list) // 遍历所有进程
ffffffffc02034ac:	fe8797e3          	bne	a5,s0,ffffffffc020349a <do_fork+0x13e>
ffffffffc02034b0:	00080663          	beqz	a6,ffffffffc02034bc <do_fork+0x160>
ffffffffc02034b4:	00006797          	auipc	a5,0x6
ffffffffc02034b8:	b6c7aa23          	sw	a2,-1164(a5) # ffffffffc0209028 <next_safe.0>
ffffffffc02034bc:	c591                	beqz	a1,ffffffffc02034c8 <do_fork+0x16c>
ffffffffc02034be:	00006797          	auipc	a5,0x6
ffffffffc02034c2:	b6d7a723          	sw	a3,-1170(a5) # ffffffffc020902c <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02034c6:	8536                	mv	a0,a3
        proc->pid = get_pid();
ffffffffc02034c8:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02034ca:	45a9                	li	a1,10
ffffffffc02034cc:	510000ef          	jal	ffffffffc02039dc <hash32>
ffffffffc02034d0:	02051793          	slli	a5,a0,0x20
ffffffffc02034d4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02034d8:	00006797          	auipc	a5,0x6
ffffffffc02034dc:	f8078793          	addi	a5,a5,-128 # ffffffffc0209458 <hash_list>
ffffffffc02034e0:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02034e2:	6510                	ld	a2,8(a0)
ffffffffc02034e4:	0d848793          	addi	a5,s1,216
ffffffffc02034e8:	6414                	ld	a3,8(s0)
        nr_process++;
ffffffffc02034ea:	0000a717          	auipc	a4,0xa
ffffffffc02034ee:	fe672703          	lw	a4,-26(a4) # ffffffffc020d4d0 <nr_process>
    prev->next = next->prev = elm;
ffffffffc02034f2:	e21c                	sd	a5,0(a2)
ffffffffc02034f4:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc02034f6:	f0f0                	sd	a2,224(s1)
    elm->prev = prev;
ffffffffc02034f8:	ece8                	sd	a0,216(s1)
        list_add(&proc_list, &(proc->list_link));
ffffffffc02034fa:	0c848613          	addi	a2,s1,200
    prev->next = next->prev = elm;
ffffffffc02034fe:	e290                	sd	a2,0(a3)
        nr_process++;
ffffffffc0203500:	0017079b          	addiw	a5,a4,1
ffffffffc0203504:	e410                	sd	a2,8(s0)
    elm->next = next;
ffffffffc0203506:	e8f4                	sd	a3,208(s1)
    elm->prev = prev;
ffffffffc0203508:	e4e0                	sd	s0,200(s1)
ffffffffc020350a:	0000a717          	auipc	a4,0xa
ffffffffc020350e:	fcf72323          	sw	a5,-58(a4) # ffffffffc020d4d0 <nr_process>
    if (flag) {
ffffffffc0203512:	06091163          	bnez	s2,ffffffffc0203574 <do_fork+0x218>
    wakeup_proc(proc);
ffffffffc0203516:	8526                	mv	a0,s1
ffffffffc0203518:	3fe000ef          	jal	ffffffffc0203916 <wakeup_proc>
    ret = proc->pid;
ffffffffc020351c:	40c8                	lw	a0,4(s1)
ffffffffc020351e:	69a2                	ld	s3,8(sp)
}
ffffffffc0203520:	70a2                	ld	ra,40(sp)
ffffffffc0203522:	7402                	ld	s0,32(sp)
ffffffffc0203524:	64e2                	ld	s1,24(sp)
ffffffffc0203526:	6942                	ld	s2,16(sp)
ffffffffc0203528:	6145                	addi	sp,sp,48
ffffffffc020352a:	8082                	ret
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020352c:	8936                	mv	s2,a3
ffffffffc020352e:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203532:	00000797          	auipc	a5,0x0
ffffffffc0203536:	d3a78793          	addi	a5,a5,-710 # ffffffffc020326c <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020353a:	fc94                	sd	a3,56(s1)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020353c:	f89c                	sd	a5,48(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020353e:	100027f3          	csrr	a5,sstatus
ffffffffc0203542:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203544:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203546:	ee0788e3          	beqz	a5,ffffffffc0203436 <do_fork+0xda>
        intr_disable();
ffffffffc020354a:	b2afd0ef          	jal	ffffffffc0200874 <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc020354e:	00006517          	auipc	a0,0x6
ffffffffc0203552:	ade52503          	lw	a0,-1314(a0) # ffffffffc020902c <last_pid.1>
ffffffffc0203556:	6789                	lui	a5,0x2
        return 1;
ffffffffc0203558:	4905                	li	s2,1
ffffffffc020355a:	2505                	addiw	a0,a0,1
ffffffffc020355c:	00006717          	auipc	a4,0x6
ffffffffc0203560:	aca72823          	sw	a0,-1328(a4) # ffffffffc020902c <last_pid.1>
ffffffffc0203564:	eef545e3          	blt	a0,a5,ffffffffc020344e <do_fork+0xf2>
        last_pid = 1; // 回绕到 1
ffffffffc0203568:	4505                	li	a0,1
ffffffffc020356a:	00006797          	auipc	a5,0x6
ffffffffc020356e:	aca7a123          	sw	a0,-1342(a5) # ffffffffc020902c <last_pid.1>
        goto inside;  // 跳转到检查逻辑
ffffffffc0203572:	bdc5                	j	ffffffffc0203462 <do_fork+0x106>
        intr_enable();
ffffffffc0203574:	afafd0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0203578:	bf79                	j	ffffffffc0203516 <do_fork+0x1ba>
                    if (last_pid >= MAX_PID)
ffffffffc020357a:	6789                	lui	a5,0x2
ffffffffc020357c:	00f6c363          	blt	a3,a5,ffffffffc0203582 <do_fork+0x226>
                        last_pid = 1;
ffffffffc0203580:	4685                	li	a3,1
                    goto repeat;
ffffffffc0203582:	4585                	li	a1,1
ffffffffc0203584:	bde5                	j	ffffffffc020347c <do_fork+0x120>
    kfree(proc);
ffffffffc0203586:	8526                	mv	a0,s1
ffffffffc0203588:	db6fe0ef          	jal	ffffffffc0201b3e <kfree>
ffffffffc020358c:	69a2                	ld	s3,8(sp)
    ret = -E_NO_MEM;
ffffffffc020358e:	5571                	li	a0,-4
ffffffffc0203590:	bf41                	j	ffffffffc0203520 <do_fork+0x1c4>
    int ret = -E_NO_FREE_PROC;
ffffffffc0203592:	556d                	li	a0,-5
}
ffffffffc0203594:	8082                	ret
    assert(current->mm == NULL);
ffffffffc0203596:	00002697          	auipc	a3,0x2
ffffffffc020359a:	fea68693          	addi	a3,a3,-22 # ffffffffc0205580 <etext+0x16c0>
ffffffffc020359e:	00001617          	auipc	a2,0x1
ffffffffc02035a2:	2f260613          	addi	a2,a2,754 # ffffffffc0204890 <etext+0x9d0>
ffffffffc02035a6:	12500593          	li	a1,293
ffffffffc02035aa:	00002517          	auipc	a0,0x2
ffffffffc02035ae:	fee50513          	addi	a0,a0,-18 # ffffffffc0205598 <etext+0x16d8>
ffffffffc02035b2:	e55fc0ef          	jal	ffffffffc0200406 <__panic>
ffffffffc02035b6:	00001617          	auipc	a2,0x1
ffffffffc02035ba:	68a60613          	addi	a2,a2,1674 # ffffffffc0204c40 <etext+0xd80>
ffffffffc02035be:	07100593          	li	a1,113
ffffffffc02035c2:	00001517          	auipc	a0,0x1
ffffffffc02035c6:	6a650513          	addi	a0,a0,1702 # ffffffffc0204c68 <etext+0xda8>
ffffffffc02035ca:	e3dfc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc02035ce <kernel_thread>:
{
ffffffffc02035ce:	7129                	addi	sp,sp,-320
ffffffffc02035d0:	fa22                	sd	s0,304(sp)
ffffffffc02035d2:	f626                	sd	s1,296(sp)
ffffffffc02035d4:	f24a                	sd	s2,288(sp)
ffffffffc02035d6:	842a                	mv	s0,a0
ffffffffc02035d8:	84ae                	mv	s1,a1
ffffffffc02035da:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035dc:	850a                	mv	a0,sp
ffffffffc02035de:	12000613          	li	a2,288
ffffffffc02035e2:	4581                	li	a1,0
{
ffffffffc02035e4:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035e6:	08d000ef          	jal	ffffffffc0203e72 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02035ea:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02035ec:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02035ee:	100027f3          	csrr	a5,sstatus
ffffffffc02035f2:	edd7f793          	andi	a5,a5,-291
ffffffffc02035f6:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035fa:	860a                	mv	a2,sp
ffffffffc02035fc:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0203600:	00000717          	auipc	a4,0x0
ffffffffc0203604:	c0270713          	addi	a4,a4,-1022 # ffffffffc0203202 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203608:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020360a:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020360c:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020360e:	d4fff0ef          	jal	ffffffffc020335c <do_fork>
}
ffffffffc0203612:	70f2                	ld	ra,312(sp)
ffffffffc0203614:	7452                	ld	s0,304(sp)
ffffffffc0203616:	74b2                	ld	s1,296(sp)
ffffffffc0203618:	7912                	ld	s2,288(sp)
ffffffffc020361a:	6131                	addi	sp,sp,320
ffffffffc020361c:	8082                	ret

ffffffffc020361e <do_exit>:
{
ffffffffc020361e:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc0203620:	00002617          	auipc	a2,0x2
ffffffffc0203624:	f9060613          	addi	a2,a2,-112 # ffffffffc02055b0 <etext+0x16f0>
ffffffffc0203628:	19e00593          	li	a1,414
ffffffffc020362c:	00002517          	auipc	a0,0x2
ffffffffc0203630:	f6c50513          	addi	a0,a0,-148 # ffffffffc0205598 <etext+0x16d8>
{
ffffffffc0203634:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc0203636:	dd1fc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020363a <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc020363a:	7179                	addi	sp,sp,-48
ffffffffc020363c:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc020363e:	0000a797          	auipc	a5,0xa
ffffffffc0203642:	e1a78793          	addi	a5,a5,-486 # ffffffffc020d458 <proc_list>
ffffffffc0203646:	f406                	sd	ra,40(sp)
ffffffffc0203648:	f022                	sd	s0,32(sp)
ffffffffc020364a:	e84a                	sd	s2,16(sp)
ffffffffc020364c:	e44e                	sd	s3,8(sp)
ffffffffc020364e:	00006497          	auipc	s1,0x6
ffffffffc0203652:	e0a48493          	addi	s1,s1,-502 # ffffffffc0209458 <hash_list>
ffffffffc0203656:	e79c                	sd	a5,8(a5)
ffffffffc0203658:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc020365a:	0000a717          	auipc	a4,0xa
ffffffffc020365e:	dfe70713          	addi	a4,a4,-514 # ffffffffc020d458 <proc_list>
ffffffffc0203662:	87a6                	mv	a5,s1
ffffffffc0203664:	e79c                	sd	a5,8(a5)
ffffffffc0203666:	e39c                	sd	a5,0(a5)
ffffffffc0203668:	07c1                	addi	a5,a5,16
ffffffffc020366a:	fee79de3          	bne	a5,a4,ffffffffc0203664 <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc020366e:	b9dff0ef          	jal	ffffffffc020320a <alloc_proc>
ffffffffc0203672:	0000a917          	auipc	s2,0xa
ffffffffc0203676:	e7690913          	addi	s2,s2,-394 # ffffffffc020d4e8 <idleproc>
ffffffffc020367a:	00a93023          	sd	a0,0(s2)
ffffffffc020367e:	1a050263          	beqz	a0,ffffffffc0203822 <proc_init+0x1e8>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203682:	07000513          	li	a0,112
ffffffffc0203686:	c12fe0ef          	jal	ffffffffc0201a98 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc020368a:	07000613          	li	a2,112
ffffffffc020368e:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203690:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203692:	7e0000ef          	jal	ffffffffc0203e72 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc0203696:	00093503          	ld	a0,0(s2)
ffffffffc020369a:	85a2                	mv	a1,s0
ffffffffc020369c:	07000613          	li	a2,112
ffffffffc02036a0:	03050513          	addi	a0,a0,48
ffffffffc02036a4:	7f8000ef          	jal	ffffffffc0203e9c <memcmp>
ffffffffc02036a8:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02036aa:	453d                	li	a0,15
ffffffffc02036ac:	becfe0ef          	jal	ffffffffc0201a98 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02036b0:	463d                	li	a2,15
ffffffffc02036b2:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02036b4:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02036b6:	7bc000ef          	jal	ffffffffc0203e72 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc02036ba:	00093503          	ld	a0,0(s2)
ffffffffc02036be:	85a2                	mv	a1,s0
ffffffffc02036c0:	463d                	li	a2,15
ffffffffc02036c2:	0b450513          	addi	a0,a0,180
ffffffffc02036c6:	7d6000ef          	jal	ffffffffc0203e9c <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02036ca:	00093783          	ld	a5,0(s2)
ffffffffc02036ce:	0000a717          	auipc	a4,0xa
ffffffffc02036d2:	dda73703          	ld	a4,-550(a4) # ffffffffc020d4a8 <boot_pgdir_pa>
ffffffffc02036d6:	77d4                	ld	a3,168(a5)
ffffffffc02036d8:	0ee68863          	beq	a3,a4,ffffffffc02037c8 <proc_init+0x18e>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02036dc:	4709                	li	a4,2
ffffffffc02036de:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036e0:	00003717          	auipc	a4,0x3
ffffffffc02036e4:	92070713          	addi	a4,a4,-1760 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036e8:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036ec:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc02036ee:	4705                	li	a4,1
ffffffffc02036f0:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036f2:	8522                	mv	a0,s0
ffffffffc02036f4:	4641                	li	a2,16
ffffffffc02036f6:	4581                	li	a1,0
ffffffffc02036f8:	77a000ef          	jal	ffffffffc0203e72 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02036fc:	8522                	mv	a0,s0
ffffffffc02036fe:	463d                	li	a2,15
ffffffffc0203700:	00002597          	auipc	a1,0x2
ffffffffc0203704:	ef858593          	addi	a1,a1,-264 # ffffffffc02055f8 <etext+0x1738>
ffffffffc0203708:	77c000ef          	jal	ffffffffc0203e84 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc020370c:	0000a797          	auipc	a5,0xa
ffffffffc0203710:	dc47a783          	lw	a5,-572(a5) # ffffffffc020d4d0 <nr_process>

    current = idleproc;
ffffffffc0203714:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203718:	4601                	li	a2,0
    nr_process++;
ffffffffc020371a:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020371c:	00002597          	auipc	a1,0x2
ffffffffc0203720:	ee458593          	addi	a1,a1,-284 # ffffffffc0205600 <etext+0x1740>
ffffffffc0203724:	00000517          	auipc	a0,0x0
ffffffffc0203728:	b5650513          	addi	a0,a0,-1194 # ffffffffc020327a <init_main>
    current = idleproc;
ffffffffc020372c:	0000a697          	auipc	a3,0xa
ffffffffc0203730:	dae6b623          	sd	a4,-596(a3) # ffffffffc020d4d8 <current>
    nr_process++;
ffffffffc0203734:	0000a717          	auipc	a4,0xa
ffffffffc0203738:	d8f72e23          	sw	a5,-612(a4) # ffffffffc020d4d0 <nr_process>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020373c:	e93ff0ef          	jal	ffffffffc02035ce <kernel_thread>
ffffffffc0203740:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0203742:	0ea05c63          	blez	a0,ffffffffc020383a <proc_init+0x200>
    if (0 < pid && pid < MAX_PID)
ffffffffc0203746:	6789                	lui	a5,0x2
ffffffffc0203748:	17f9                	addi	a5,a5,-2 # 1ffe <kern_entry-0xffffffffc01fe002>
ffffffffc020374a:	fff5071b          	addiw	a4,a0,-1
ffffffffc020374e:	02e7e463          	bltu	a5,a4,ffffffffc0203776 <proc_init+0x13c>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0203752:	45a9                	li	a1,10
ffffffffc0203754:	288000ef          	jal	ffffffffc02039dc <hash32>
ffffffffc0203758:	02051713          	slli	a4,a0,0x20
ffffffffc020375c:	01c75793          	srli	a5,a4,0x1c
ffffffffc0203760:	00f486b3          	add	a3,s1,a5
ffffffffc0203764:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0203766:	a029                	j	ffffffffc0203770 <proc_init+0x136>
            if (proc->pid == pid)
ffffffffc0203768:	f2c7a703          	lw	a4,-212(a5)
ffffffffc020376c:	0a870863          	beq	a4,s0,ffffffffc020381c <proc_init+0x1e2>
    return listelm->next;
ffffffffc0203770:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203772:	fef69be3          	bne	a3,a5,ffffffffc0203768 <proc_init+0x12e>
    return NULL;
ffffffffc0203776:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203778:	0b478413          	addi	s0,a5,180
ffffffffc020377c:	4641                	li	a2,16
ffffffffc020377e:	4581                	li	a1,0
ffffffffc0203780:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0203782:	0000a717          	auipc	a4,0xa
ffffffffc0203786:	d4f73f23          	sd	a5,-674(a4) # ffffffffc020d4e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020378a:	6e8000ef          	jal	ffffffffc0203e72 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020378e:	8522                	mv	a0,s0
ffffffffc0203790:	463d                	li	a2,15
ffffffffc0203792:	00002597          	auipc	a1,0x2
ffffffffc0203796:	e9e58593          	addi	a1,a1,-354 # ffffffffc0205630 <etext+0x1770>
ffffffffc020379a:	6ea000ef          	jal	ffffffffc0203e84 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020379e:	00093783          	ld	a5,0(s2)
ffffffffc02037a2:	cbe1                	beqz	a5,ffffffffc0203872 <proc_init+0x238>
ffffffffc02037a4:	43dc                	lw	a5,4(a5)
ffffffffc02037a6:	e7f1                	bnez	a5,ffffffffc0203872 <proc_init+0x238>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02037a8:	0000a797          	auipc	a5,0xa
ffffffffc02037ac:	d387b783          	ld	a5,-712(a5) # ffffffffc020d4e0 <initproc>
ffffffffc02037b0:	c3cd                	beqz	a5,ffffffffc0203852 <proc_init+0x218>
ffffffffc02037b2:	43d8                	lw	a4,4(a5)
ffffffffc02037b4:	4785                	li	a5,1
ffffffffc02037b6:	08f71e63          	bne	a4,a5,ffffffffc0203852 <proc_init+0x218>
}
ffffffffc02037ba:	70a2                	ld	ra,40(sp)
ffffffffc02037bc:	7402                	ld	s0,32(sp)
ffffffffc02037be:	64e2                	ld	s1,24(sp)
ffffffffc02037c0:	6942                	ld	s2,16(sp)
ffffffffc02037c2:	69a2                	ld	s3,8(sp)
ffffffffc02037c4:	6145                	addi	sp,sp,48
ffffffffc02037c6:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02037c8:	73d8                	ld	a4,160(a5)
ffffffffc02037ca:	f00719e3          	bnez	a4,ffffffffc02036dc <proc_init+0xa2>
ffffffffc02037ce:	f00997e3          	bnez	s3,ffffffffc02036dc <proc_init+0xa2>
ffffffffc02037d2:	4398                	lw	a4,0(a5)
ffffffffc02037d4:	f00714e3          	bnez	a4,ffffffffc02036dc <proc_init+0xa2>
ffffffffc02037d8:	43d4                	lw	a3,4(a5)
ffffffffc02037da:	577d                	li	a4,-1
ffffffffc02037dc:	f0e690e3          	bne	a3,a4,ffffffffc02036dc <proc_init+0xa2>
ffffffffc02037e0:	4798                	lw	a4,8(a5)
ffffffffc02037e2:	ee071de3          	bnez	a4,ffffffffc02036dc <proc_init+0xa2>
ffffffffc02037e6:	6b98                	ld	a4,16(a5)
ffffffffc02037e8:	ee071ae3          	bnez	a4,ffffffffc02036dc <proc_init+0xa2>
ffffffffc02037ec:	4f98                	lw	a4,24(a5)
ffffffffc02037ee:	ee0717e3          	bnez	a4,ffffffffc02036dc <proc_init+0xa2>
ffffffffc02037f2:	7398                	ld	a4,32(a5)
ffffffffc02037f4:	ee0714e3          	bnez	a4,ffffffffc02036dc <proc_init+0xa2>
ffffffffc02037f8:	7798                	ld	a4,40(a5)
ffffffffc02037fa:	ee0711e3          	bnez	a4,ffffffffc02036dc <proc_init+0xa2>
ffffffffc02037fe:	0b07a703          	lw	a4,176(a5)
ffffffffc0203802:	8f49                	or	a4,a4,a0
ffffffffc0203804:	2701                	sext.w	a4,a4
ffffffffc0203806:	ec071be3          	bnez	a4,ffffffffc02036dc <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc020380a:	00002517          	auipc	a0,0x2
ffffffffc020380e:	dd650513          	addi	a0,a0,-554 # ffffffffc02055e0 <etext+0x1720>
ffffffffc0203812:	983fc0ef          	jal	ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc0203816:	00093783          	ld	a5,0(s2)
ffffffffc020381a:	b5c9                	j	ffffffffc02036dc <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020381c:	f2878793          	addi	a5,a5,-216
ffffffffc0203820:	bfa1                	j	ffffffffc0203778 <proc_init+0x13e>
        panic("cannot alloc idleproc.\n");
ffffffffc0203822:	00002617          	auipc	a2,0x2
ffffffffc0203826:	da660613          	addi	a2,a2,-602 # ffffffffc02055c8 <etext+0x1708>
ffffffffc020382a:	1b900593          	li	a1,441
ffffffffc020382e:	00002517          	auipc	a0,0x2
ffffffffc0203832:	d6a50513          	addi	a0,a0,-662 # ffffffffc0205598 <etext+0x16d8>
ffffffffc0203836:	bd1fc0ef          	jal	ffffffffc0200406 <__panic>
        panic("create init_main failed.\n");
ffffffffc020383a:	00002617          	auipc	a2,0x2
ffffffffc020383e:	dd660613          	addi	a2,a2,-554 # ffffffffc0205610 <etext+0x1750>
ffffffffc0203842:	1d600593          	li	a1,470
ffffffffc0203846:	00002517          	auipc	a0,0x2
ffffffffc020384a:	d5250513          	addi	a0,a0,-686 # ffffffffc0205598 <etext+0x16d8>
ffffffffc020384e:	bb9fc0ef          	jal	ffffffffc0200406 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203852:	00002697          	auipc	a3,0x2
ffffffffc0203856:	e0e68693          	addi	a3,a3,-498 # ffffffffc0205660 <etext+0x17a0>
ffffffffc020385a:	00001617          	auipc	a2,0x1
ffffffffc020385e:	03660613          	addi	a2,a2,54 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0203862:	1dd00593          	li	a1,477
ffffffffc0203866:	00002517          	auipc	a0,0x2
ffffffffc020386a:	d3250513          	addi	a0,a0,-718 # ffffffffc0205598 <etext+0x16d8>
ffffffffc020386e:	b99fc0ef          	jal	ffffffffc0200406 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203872:	00002697          	auipc	a3,0x2
ffffffffc0203876:	dc668693          	addi	a3,a3,-570 # ffffffffc0205638 <etext+0x1778>
ffffffffc020387a:	00001617          	auipc	a2,0x1
ffffffffc020387e:	01660613          	addi	a2,a2,22 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0203882:	1dc00593          	li	a1,476
ffffffffc0203886:	00002517          	auipc	a0,0x2
ffffffffc020388a:	d1250513          	addi	a0,a0,-750 # ffffffffc0205598 <etext+0x16d8>
ffffffffc020388e:	b79fc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0203892 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0203892:	1141                	addi	sp,sp,-16
ffffffffc0203894:	e022                	sd	s0,0(sp)
ffffffffc0203896:	e406                	sd	ra,8(sp)
ffffffffc0203898:	0000a417          	auipc	s0,0xa
ffffffffc020389c:	c4040413          	addi	s0,s0,-960 # ffffffffc020d4d8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02038a0:	6018                	ld	a4,0(s0)
ffffffffc02038a2:	4f1c                	lw	a5,24(a4)
ffffffffc02038a4:	dffd                	beqz	a5,ffffffffc02038a2 <cpu_idle+0x10>
        {
            schedule();
ffffffffc02038a6:	0a2000ef          	jal	ffffffffc0203948 <schedule>
ffffffffc02038aa:	bfdd                	j	ffffffffc02038a0 <cpu_idle+0xe>

ffffffffc02038ac <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02038ac:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02038b0:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02038b4:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02038b6:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02038b8:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02038bc:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02038c0:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02038c4:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02038c8:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02038cc:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02038d0:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02038d4:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02038d8:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02038dc:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02038e0:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02038e4:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02038e8:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02038ea:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02038ec:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02038f0:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02038f4:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02038f8:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02038fc:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0203900:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0203904:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0203908:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020390c:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0203910:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0203914:	8082                	ret

ffffffffc0203916 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203916:	411c                	lw	a5,0(a0)
ffffffffc0203918:	4705                	li	a4,1
ffffffffc020391a:	37f9                	addiw	a5,a5,-2
ffffffffc020391c:	00f77563          	bgeu	a4,a5,ffffffffc0203926 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc0203920:	4789                	li	a5,2
ffffffffc0203922:	c11c                	sw	a5,0(a0)
ffffffffc0203924:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203926:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203928:	00002697          	auipc	a3,0x2
ffffffffc020392c:	d6068693          	addi	a3,a3,-672 # ffffffffc0205688 <etext+0x17c8>
ffffffffc0203930:	00001617          	auipc	a2,0x1
ffffffffc0203934:	f6060613          	addi	a2,a2,-160 # ffffffffc0204890 <etext+0x9d0>
ffffffffc0203938:	45a5                	li	a1,9
ffffffffc020393a:	00002517          	auipc	a0,0x2
ffffffffc020393e:	d8e50513          	addi	a0,a0,-626 # ffffffffc02056c8 <etext+0x1808>
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203942:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203944:	ac3fc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0203948 <schedule>:
}

void
schedule(void) {
ffffffffc0203948:	1101                	addi	sp,sp,-32
ffffffffc020394a:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020394c:	100027f3          	csrr	a5,sstatus
ffffffffc0203950:	8b89                	andi	a5,a5,2
ffffffffc0203952:	4301                	li	t1,0
ffffffffc0203954:	e3c1                	bnez	a5,ffffffffc02039d4 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0203956:	0000a897          	auipc	a7,0xa
ffffffffc020395a:	b828b883          	ld	a7,-1150(a7) # ffffffffc020d4d8 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020395e:	0000a517          	auipc	a0,0xa
ffffffffc0203962:	b8a53503          	ld	a0,-1142(a0) # ffffffffc020d4e8 <idleproc>
        current->need_resched = 0;
ffffffffc0203966:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020396a:	04a88f63          	beq	a7,a0,ffffffffc02039c8 <schedule+0x80>
ffffffffc020396e:	0c888693          	addi	a3,a7,200
ffffffffc0203972:	0000a617          	auipc	a2,0xa
ffffffffc0203976:	ae660613          	addi	a2,a2,-1306 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc020397a:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020397c:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc020397e:	4809                	li	a6,2
ffffffffc0203980:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0203982:	00c78863          	beq	a5,a2,ffffffffc0203992 <schedule+0x4a>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203986:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020398a:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc020398e:	03070363          	beq	a4,a6,ffffffffc02039b4 <schedule+0x6c>
                    break;
                }
            }
        } while (le != last);
ffffffffc0203992:	fef697e3          	bne	a3,a5,ffffffffc0203980 <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203996:	ed99                	bnez	a1,ffffffffc02039b4 <schedule+0x6c>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0203998:	451c                	lw	a5,8(a0)
ffffffffc020399a:	2785                	addiw	a5,a5,1
ffffffffc020399c:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc020399e:	00a88663          	beq	a7,a0,ffffffffc02039aa <schedule+0x62>
ffffffffc02039a2:	e41a                	sd	t1,8(sp)
            proc_run(next);
ffffffffc02039a4:	947ff0ef          	jal	ffffffffc02032ea <proc_run>
ffffffffc02039a8:	6322                	ld	t1,8(sp)
    if (flag) {
ffffffffc02039aa:	00031b63          	bnez	t1,ffffffffc02039c0 <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02039ae:	60e2                	ld	ra,24(sp)
ffffffffc02039b0:	6105                	addi	sp,sp,32
ffffffffc02039b2:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02039b4:	4198                	lw	a4,0(a1)
ffffffffc02039b6:	4789                	li	a5,2
ffffffffc02039b8:	fef710e3          	bne	a4,a5,ffffffffc0203998 <schedule+0x50>
ffffffffc02039bc:	852e                	mv	a0,a1
ffffffffc02039be:	bfe9                	j	ffffffffc0203998 <schedule+0x50>
}
ffffffffc02039c0:	60e2                	ld	ra,24(sp)
ffffffffc02039c2:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02039c4:	eabfc06f          	j	ffffffffc020086e <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02039c8:	0000a617          	auipc	a2,0xa
ffffffffc02039cc:	a9060613          	addi	a2,a2,-1392 # ffffffffc020d458 <proc_list>
ffffffffc02039d0:	86b2                	mv	a3,a2
ffffffffc02039d2:	b765                	j	ffffffffc020397a <schedule+0x32>
        intr_disable();
ffffffffc02039d4:	ea1fc0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc02039d8:	4305                	li	t1,1
ffffffffc02039da:	bfb5                	j	ffffffffc0203956 <schedule+0xe>

ffffffffc02039dc <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02039dc:	9e3707b7          	lui	a5,0x9e370
ffffffffc02039e0:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <kern_entry-0x21e8ffff>
ffffffffc02039e2:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc02039e6:	02000513          	li	a0,32
ffffffffc02039ea:	9d0d                	subw	a0,a0,a1
}
ffffffffc02039ec:	00a7d53b          	srlw	a0,a5,a0
ffffffffc02039f0:	8082                	ret

ffffffffc02039f2 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039f2:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02039f4:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039f8:	f022                	sd	s0,32(sp)
ffffffffc02039fa:	ec26                	sd	s1,24(sp)
ffffffffc02039fc:	e84a                	sd	s2,16(sp)
ffffffffc02039fe:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203a00:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a04:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203a06:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203a0a:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203a0e:	84aa                	mv	s1,a0
ffffffffc0203a10:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0203a12:	03067d63          	bgeu	a2,a6,ffffffffc0203a4c <printnum+0x5a>
ffffffffc0203a16:	e44e                	sd	s3,8(sp)
ffffffffc0203a18:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203a1a:	4785                	li	a5,1
ffffffffc0203a1c:	00e7d763          	bge	a5,a4,ffffffffc0203a2a <printnum+0x38>
            putch(padc, putdat);
ffffffffc0203a20:	85ca                	mv	a1,s2
ffffffffc0203a22:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0203a24:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203a26:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203a28:	fc65                	bnez	s0,ffffffffc0203a20 <printnum+0x2e>
ffffffffc0203a2a:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a2c:	00002797          	auipc	a5,0x2
ffffffffc0203a30:	cb478793          	addi	a5,a5,-844 # ffffffffc02056e0 <etext+0x1820>
ffffffffc0203a34:	97d2                	add	a5,a5,s4
}
ffffffffc0203a36:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a38:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0203a3c:	70a2                	ld	ra,40(sp)
ffffffffc0203a3e:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a40:	85ca                	mv	a1,s2
ffffffffc0203a42:	87a6                	mv	a5,s1
}
ffffffffc0203a44:	6942                	ld	s2,16(sp)
ffffffffc0203a46:	64e2                	ld	s1,24(sp)
ffffffffc0203a48:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a4a:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203a4c:	03065633          	divu	a2,a2,a6
ffffffffc0203a50:	8722                	mv	a4,s0
ffffffffc0203a52:	fa1ff0ef          	jal	ffffffffc02039f2 <printnum>
ffffffffc0203a56:	bfd9                	j	ffffffffc0203a2c <printnum+0x3a>

ffffffffc0203a58 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203a58:	7119                	addi	sp,sp,-128
ffffffffc0203a5a:	f4a6                	sd	s1,104(sp)
ffffffffc0203a5c:	f0ca                	sd	s2,96(sp)
ffffffffc0203a5e:	ecce                	sd	s3,88(sp)
ffffffffc0203a60:	e8d2                	sd	s4,80(sp)
ffffffffc0203a62:	e4d6                	sd	s5,72(sp)
ffffffffc0203a64:	e0da                	sd	s6,64(sp)
ffffffffc0203a66:	f862                	sd	s8,48(sp)
ffffffffc0203a68:	fc86                	sd	ra,120(sp)
ffffffffc0203a6a:	f8a2                	sd	s0,112(sp)
ffffffffc0203a6c:	fc5e                	sd	s7,56(sp)
ffffffffc0203a6e:	f466                	sd	s9,40(sp)
ffffffffc0203a70:	f06a                	sd	s10,32(sp)
ffffffffc0203a72:	ec6e                	sd	s11,24(sp)
ffffffffc0203a74:	84aa                	mv	s1,a0
ffffffffc0203a76:	8c32                	mv	s8,a2
ffffffffc0203a78:	8a36                	mv	s4,a3
ffffffffc0203a7a:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a7c:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a80:	05500b13          	li	s6,85
ffffffffc0203a84:	00002a97          	auipc	s5,0x2
ffffffffc0203a88:	dfca8a93          	addi	s5,s5,-516 # ffffffffc0205880 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a8c:	000c4503          	lbu	a0,0(s8)
ffffffffc0203a90:	001c0413          	addi	s0,s8,1
ffffffffc0203a94:	01350a63          	beq	a0,s3,ffffffffc0203aa8 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0203a98:	cd0d                	beqz	a0,ffffffffc0203ad2 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0203a9a:	85ca                	mv	a1,s2
ffffffffc0203a9c:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a9e:	00044503          	lbu	a0,0(s0)
ffffffffc0203aa2:	0405                	addi	s0,s0,1
ffffffffc0203aa4:	ff351ae3          	bne	a0,s3,ffffffffc0203a98 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0203aa8:	5cfd                	li	s9,-1
ffffffffc0203aaa:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0203aac:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0203ab0:	4b81                	li	s7,0
ffffffffc0203ab2:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ab4:	00044683          	lbu	a3,0(s0)
ffffffffc0203ab8:	00140c13          	addi	s8,s0,1
ffffffffc0203abc:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0203ac0:	0ff5f593          	zext.b	a1,a1
ffffffffc0203ac4:	02bb6663          	bltu	s6,a1,ffffffffc0203af0 <vprintfmt+0x98>
ffffffffc0203ac8:	058a                	slli	a1,a1,0x2
ffffffffc0203aca:	95d6                	add	a1,a1,s5
ffffffffc0203acc:	4198                	lw	a4,0(a1)
ffffffffc0203ace:	9756                	add	a4,a4,s5
ffffffffc0203ad0:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203ad2:	70e6                	ld	ra,120(sp)
ffffffffc0203ad4:	7446                	ld	s0,112(sp)
ffffffffc0203ad6:	74a6                	ld	s1,104(sp)
ffffffffc0203ad8:	7906                	ld	s2,96(sp)
ffffffffc0203ada:	69e6                	ld	s3,88(sp)
ffffffffc0203adc:	6a46                	ld	s4,80(sp)
ffffffffc0203ade:	6aa6                	ld	s5,72(sp)
ffffffffc0203ae0:	6b06                	ld	s6,64(sp)
ffffffffc0203ae2:	7be2                	ld	s7,56(sp)
ffffffffc0203ae4:	7c42                	ld	s8,48(sp)
ffffffffc0203ae6:	7ca2                	ld	s9,40(sp)
ffffffffc0203ae8:	7d02                	ld	s10,32(sp)
ffffffffc0203aea:	6de2                	ld	s11,24(sp)
ffffffffc0203aec:	6109                	addi	sp,sp,128
ffffffffc0203aee:	8082                	ret
            putch('%', putdat);
ffffffffc0203af0:	85ca                	mv	a1,s2
ffffffffc0203af2:	02500513          	li	a0,37
ffffffffc0203af6:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203af8:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203afc:	02500713          	li	a4,37
ffffffffc0203b00:	8c22                	mv	s8,s0
ffffffffc0203b02:	f8e785e3          	beq	a5,a4,ffffffffc0203a8c <vprintfmt+0x34>
ffffffffc0203b06:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0203b0a:	1c7d                	addi	s8,s8,-1
ffffffffc0203b0c:	fee79de3          	bne	a5,a4,ffffffffc0203b06 <vprintfmt+0xae>
ffffffffc0203b10:	bfb5                	j	ffffffffc0203a8c <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0203b12:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0203b16:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0203b18:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0203b1c:	fd06071b          	addiw	a4,a2,-48
ffffffffc0203b20:	24e56a63          	bltu	a0,a4,ffffffffc0203d74 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0203b24:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b26:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0203b28:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0203b2c:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203b30:	0197073b          	addw	a4,a4,s9
ffffffffc0203b34:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203b38:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b3a:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203b3e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203b40:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0203b44:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0203b48:	feb570e3          	bgeu	a0,a1,ffffffffc0203b28 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0203b4c:	f60d54e3          	bgez	s10,ffffffffc0203ab4 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0203b50:	8d66                	mv	s10,s9
ffffffffc0203b52:	5cfd                	li	s9,-1
ffffffffc0203b54:	b785                	j	ffffffffc0203ab4 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b56:	8db6                	mv	s11,a3
ffffffffc0203b58:	8462                	mv	s0,s8
ffffffffc0203b5a:	bfa9                	j	ffffffffc0203ab4 <vprintfmt+0x5c>
ffffffffc0203b5c:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0203b5e:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0203b60:	bf91                	j	ffffffffc0203ab4 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0203b62:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b64:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b68:	00f74463          	blt	a4,a5,ffffffffc0203b70 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0203b6c:	1a078763          	beqz	a5,ffffffffc0203d1a <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0203b70:	000a3603          	ld	a2,0(s4)
ffffffffc0203b74:	46c1                	li	a3,16
ffffffffc0203b76:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203b78:	000d879b          	sext.w	a5,s11
ffffffffc0203b7c:	876a                	mv	a4,s10
ffffffffc0203b7e:	85ca                	mv	a1,s2
ffffffffc0203b80:	8526                	mv	a0,s1
ffffffffc0203b82:	e71ff0ef          	jal	ffffffffc02039f2 <printnum>
            break;
ffffffffc0203b86:	b719                	j	ffffffffc0203a8c <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0203b88:	000a2503          	lw	a0,0(s4)
ffffffffc0203b8c:	85ca                	mv	a1,s2
ffffffffc0203b8e:	0a21                	addi	s4,s4,8
ffffffffc0203b90:	9482                	jalr	s1
            break;
ffffffffc0203b92:	bded                	j	ffffffffc0203a8c <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203b94:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b96:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b9a:	00f74463          	blt	a4,a5,ffffffffc0203ba2 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0203b9e:	16078963          	beqz	a5,ffffffffc0203d10 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0203ba2:	000a3603          	ld	a2,0(s4)
ffffffffc0203ba6:	46a9                	li	a3,10
ffffffffc0203ba8:	8a2e                	mv	s4,a1
ffffffffc0203baa:	b7f9                	j	ffffffffc0203b78 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0203bac:	85ca                	mv	a1,s2
ffffffffc0203bae:	03000513          	li	a0,48
ffffffffc0203bb2:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0203bb4:	85ca                	mv	a1,s2
ffffffffc0203bb6:	07800513          	li	a0,120
ffffffffc0203bba:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203bbc:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0203bc0:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203bc2:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203bc4:	bf55                	j	ffffffffc0203b78 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0203bc6:	85ca                	mv	a1,s2
ffffffffc0203bc8:	02500513          	li	a0,37
ffffffffc0203bcc:	9482                	jalr	s1
            break;
ffffffffc0203bce:	bd7d                	j	ffffffffc0203a8c <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0203bd0:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bd4:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0203bd6:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0203bd8:	bf95                	j	ffffffffc0203b4c <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0203bda:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203bdc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203be0:	00f74463          	blt	a4,a5,ffffffffc0203be8 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0203be4:	12078163          	beqz	a5,ffffffffc0203d06 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0203be8:	000a3603          	ld	a2,0(s4)
ffffffffc0203bec:	46a1                	li	a3,8
ffffffffc0203bee:	8a2e                	mv	s4,a1
ffffffffc0203bf0:	b761                	j	ffffffffc0203b78 <vprintfmt+0x120>
            if (width < 0)
ffffffffc0203bf2:	876a                	mv	a4,s10
ffffffffc0203bf4:	000d5363          	bgez	s10,ffffffffc0203bfa <vprintfmt+0x1a2>
ffffffffc0203bf8:	4701                	li	a4,0
ffffffffc0203bfa:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bfe:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203c00:	bd55                	j	ffffffffc0203ab4 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0203c02:	000d841b          	sext.w	s0,s11
ffffffffc0203c06:	fd340793          	addi	a5,s0,-45
ffffffffc0203c0a:	00f037b3          	snez	a5,a5
ffffffffc0203c0e:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c12:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0203c16:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c18:	008a0793          	addi	a5,s4,8
ffffffffc0203c1c:	e43e                	sd	a5,8(sp)
ffffffffc0203c1e:	100d8c63          	beqz	s11,ffffffffc0203d36 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0203c22:	12071363          	bnez	a4,ffffffffc0203d48 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c26:	000dc783          	lbu	a5,0(s11)
ffffffffc0203c2a:	0007851b          	sext.w	a0,a5
ffffffffc0203c2e:	c78d                	beqz	a5,ffffffffc0203c58 <vprintfmt+0x200>
ffffffffc0203c30:	0d85                	addi	s11,s11,1
ffffffffc0203c32:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c34:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c38:	000cc563          	bltz	s9,ffffffffc0203c42 <vprintfmt+0x1ea>
ffffffffc0203c3c:	3cfd                	addiw	s9,s9,-1
ffffffffc0203c3e:	008c8d63          	beq	s9,s0,ffffffffc0203c58 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c42:	020b9663          	bnez	s7,ffffffffc0203c6e <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0203c46:	85ca                	mv	a1,s2
ffffffffc0203c48:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c4a:	000dc783          	lbu	a5,0(s11)
ffffffffc0203c4e:	0d85                	addi	s11,s11,1
ffffffffc0203c50:	3d7d                	addiw	s10,s10,-1
ffffffffc0203c52:	0007851b          	sext.w	a0,a5
ffffffffc0203c56:	f3ed                	bnez	a5,ffffffffc0203c38 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0203c58:	01a05963          	blez	s10,ffffffffc0203c6a <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0203c5c:	85ca                	mv	a1,s2
ffffffffc0203c5e:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0203c62:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0203c64:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0203c66:	fe0d1be3          	bnez	s10,ffffffffc0203c5c <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c6a:	6a22                	ld	s4,8(sp)
ffffffffc0203c6c:	b505                	j	ffffffffc0203a8c <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c6e:	3781                	addiw	a5,a5,-32
ffffffffc0203c70:	fcfa7be3          	bgeu	s4,a5,ffffffffc0203c46 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0203c74:	03f00513          	li	a0,63
ffffffffc0203c78:	85ca                	mv	a1,s2
ffffffffc0203c7a:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c7c:	000dc783          	lbu	a5,0(s11)
ffffffffc0203c80:	0d85                	addi	s11,s11,1
ffffffffc0203c82:	3d7d                	addiw	s10,s10,-1
ffffffffc0203c84:	0007851b          	sext.w	a0,a5
ffffffffc0203c88:	dbe1                	beqz	a5,ffffffffc0203c58 <vprintfmt+0x200>
ffffffffc0203c8a:	fa0cd9e3          	bgez	s9,ffffffffc0203c3c <vprintfmt+0x1e4>
ffffffffc0203c8e:	b7c5                	j	ffffffffc0203c6e <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0203c90:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c94:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0203c96:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203c98:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0203c9c:	8fb9                	xor	a5,a5,a4
ffffffffc0203c9e:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203ca2:	02d64563          	blt	a2,a3,ffffffffc0203ccc <vprintfmt+0x274>
ffffffffc0203ca6:	00002797          	auipc	a5,0x2
ffffffffc0203caa:	d3278793          	addi	a5,a5,-718 # ffffffffc02059d8 <error_string>
ffffffffc0203cae:	00369713          	slli	a4,a3,0x3
ffffffffc0203cb2:	97ba                	add	a5,a5,a4
ffffffffc0203cb4:	639c                	ld	a5,0(a5)
ffffffffc0203cb6:	cb99                	beqz	a5,ffffffffc0203ccc <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203cb8:	86be                	mv	a3,a5
ffffffffc0203cba:	00000617          	auipc	a2,0x0
ffffffffc0203cbe:	22e60613          	addi	a2,a2,558 # ffffffffc0203ee8 <etext+0x28>
ffffffffc0203cc2:	85ca                	mv	a1,s2
ffffffffc0203cc4:	8526                	mv	a0,s1
ffffffffc0203cc6:	0d8000ef          	jal	ffffffffc0203d9e <printfmt>
ffffffffc0203cca:	b3c9                	j	ffffffffc0203a8c <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203ccc:	00002617          	auipc	a2,0x2
ffffffffc0203cd0:	a3460613          	addi	a2,a2,-1484 # ffffffffc0205700 <etext+0x1840>
ffffffffc0203cd4:	85ca                	mv	a1,s2
ffffffffc0203cd6:	8526                	mv	a0,s1
ffffffffc0203cd8:	0c6000ef          	jal	ffffffffc0203d9e <printfmt>
ffffffffc0203cdc:	bb45                	j	ffffffffc0203a8c <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203cde:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203ce0:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0203ce4:	00f74363          	blt	a4,a5,ffffffffc0203cea <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0203ce8:	cf81                	beqz	a5,ffffffffc0203d00 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0203cea:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203cee:	02044b63          	bltz	s0,ffffffffc0203d24 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0203cf2:	8622                	mv	a2,s0
ffffffffc0203cf4:	8a5e                	mv	s4,s7
ffffffffc0203cf6:	46a9                	li	a3,10
ffffffffc0203cf8:	b541                	j	ffffffffc0203b78 <vprintfmt+0x120>
            lflag ++;
ffffffffc0203cfa:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203cfc:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203cfe:	bb5d                	j	ffffffffc0203ab4 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0203d00:	000a2403          	lw	s0,0(s4)
ffffffffc0203d04:	b7ed                	j	ffffffffc0203cee <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0203d06:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d0a:	46a1                	li	a3,8
ffffffffc0203d0c:	8a2e                	mv	s4,a1
ffffffffc0203d0e:	b5ad                	j	ffffffffc0203b78 <vprintfmt+0x120>
ffffffffc0203d10:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d14:	46a9                	li	a3,10
ffffffffc0203d16:	8a2e                	mv	s4,a1
ffffffffc0203d18:	b585                	j	ffffffffc0203b78 <vprintfmt+0x120>
ffffffffc0203d1a:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d1e:	46c1                	li	a3,16
ffffffffc0203d20:	8a2e                	mv	s4,a1
ffffffffc0203d22:	bd99                	j	ffffffffc0203b78 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0203d24:	85ca                	mv	a1,s2
ffffffffc0203d26:	02d00513          	li	a0,45
ffffffffc0203d2a:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0203d2c:	40800633          	neg	a2,s0
ffffffffc0203d30:	8a5e                	mv	s4,s7
ffffffffc0203d32:	46a9                	li	a3,10
ffffffffc0203d34:	b591                	j	ffffffffc0203b78 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0203d36:	e329                	bnez	a4,ffffffffc0203d78 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d38:	02800793          	li	a5,40
ffffffffc0203d3c:	853e                	mv	a0,a5
ffffffffc0203d3e:	00002d97          	auipc	s11,0x2
ffffffffc0203d42:	9bbd8d93          	addi	s11,s11,-1605 # ffffffffc02056f9 <etext+0x1839>
ffffffffc0203d46:	b5f5                	j	ffffffffc0203c32 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d48:	85e6                	mv	a1,s9
ffffffffc0203d4a:	856e                	mv	a0,s11
ffffffffc0203d4c:	08a000ef          	jal	ffffffffc0203dd6 <strnlen>
ffffffffc0203d50:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0203d54:	01a05863          	blez	s10,ffffffffc0203d64 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0203d58:	85ca                	mv	a1,s2
ffffffffc0203d5a:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d5c:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0203d5e:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d60:	fe0d1ce3          	bnez	s10,ffffffffc0203d58 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d64:	000dc783          	lbu	a5,0(s11)
ffffffffc0203d68:	0007851b          	sext.w	a0,a5
ffffffffc0203d6c:	ec0792e3          	bnez	a5,ffffffffc0203c30 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203d70:	6a22                	ld	s4,8(sp)
ffffffffc0203d72:	bb29                	j	ffffffffc0203a8c <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203d74:	8462                	mv	s0,s8
ffffffffc0203d76:	bbd9                	j	ffffffffc0203b4c <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d78:	85e6                	mv	a1,s9
ffffffffc0203d7a:	00002517          	auipc	a0,0x2
ffffffffc0203d7e:	97e50513          	addi	a0,a0,-1666 # ffffffffc02056f8 <etext+0x1838>
ffffffffc0203d82:	054000ef          	jal	ffffffffc0203dd6 <strnlen>
ffffffffc0203d86:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d8a:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0203d8e:	00002d97          	auipc	s11,0x2
ffffffffc0203d92:	96ad8d93          	addi	s11,s11,-1686 # ffffffffc02056f8 <etext+0x1838>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d96:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d98:	fda040e3          	bgtz	s10,ffffffffc0203d58 <vprintfmt+0x300>
ffffffffc0203d9c:	bd51                	j	ffffffffc0203c30 <vprintfmt+0x1d8>

ffffffffc0203d9e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d9e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203da0:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203da4:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203da6:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203da8:	ec06                	sd	ra,24(sp)
ffffffffc0203daa:	f83a                	sd	a4,48(sp)
ffffffffc0203dac:	fc3e                	sd	a5,56(sp)
ffffffffc0203dae:	e0c2                	sd	a6,64(sp)
ffffffffc0203db0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203db2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203db4:	ca5ff0ef          	jal	ffffffffc0203a58 <vprintfmt>
}
ffffffffc0203db8:	60e2                	ld	ra,24(sp)
ffffffffc0203dba:	6161                	addi	sp,sp,80
ffffffffc0203dbc:	8082                	ret

ffffffffc0203dbe <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203dbe:	00054783          	lbu	a5,0(a0)
ffffffffc0203dc2:	cb81                	beqz	a5,ffffffffc0203dd2 <strlen+0x14>
    size_t cnt = 0;
ffffffffc0203dc4:	4781                	li	a5,0
        cnt ++;
ffffffffc0203dc6:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0203dc8:	00f50733          	add	a4,a0,a5
ffffffffc0203dcc:	00074703          	lbu	a4,0(a4)
ffffffffc0203dd0:	fb7d                	bnez	a4,ffffffffc0203dc6 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0203dd2:	853e                	mv	a0,a5
ffffffffc0203dd4:	8082                	ret

ffffffffc0203dd6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203dd6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203dd8:	e589                	bnez	a1,ffffffffc0203de2 <strnlen+0xc>
ffffffffc0203dda:	a811                	j	ffffffffc0203dee <strnlen+0x18>
        cnt ++;
ffffffffc0203ddc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203dde:	00f58863          	beq	a1,a5,ffffffffc0203dee <strnlen+0x18>
ffffffffc0203de2:	00f50733          	add	a4,a0,a5
ffffffffc0203de6:	00074703          	lbu	a4,0(a4)
ffffffffc0203dea:	fb6d                	bnez	a4,ffffffffc0203ddc <strnlen+0x6>
ffffffffc0203dec:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203dee:	852e                	mv	a0,a1
ffffffffc0203df0:	8082                	ret

ffffffffc0203df2 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203df2:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203df4:	0005c703          	lbu	a4,0(a1)
ffffffffc0203df8:	0585                	addi	a1,a1,1
ffffffffc0203dfa:	0785                	addi	a5,a5,1
ffffffffc0203dfc:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203e00:	fb75                	bnez	a4,ffffffffc0203df4 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203e02:	8082                	ret

ffffffffc0203e04 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e04:	00054783          	lbu	a5,0(a0)
ffffffffc0203e08:	e791                	bnez	a5,ffffffffc0203e14 <strcmp+0x10>
ffffffffc0203e0a:	a01d                	j	ffffffffc0203e30 <strcmp+0x2c>
ffffffffc0203e0c:	00054783          	lbu	a5,0(a0)
ffffffffc0203e10:	cb99                	beqz	a5,ffffffffc0203e26 <strcmp+0x22>
ffffffffc0203e12:	0585                	addi	a1,a1,1
ffffffffc0203e14:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0203e18:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e1a:	fef709e3          	beq	a4,a5,ffffffffc0203e0c <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e1e:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203e22:	9d19                	subw	a0,a0,a4
ffffffffc0203e24:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e26:	0015c703          	lbu	a4,1(a1)
ffffffffc0203e2a:	4501                	li	a0,0
}
ffffffffc0203e2c:	9d19                	subw	a0,a0,a4
ffffffffc0203e2e:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e30:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e34:	4501                	li	a0,0
ffffffffc0203e36:	b7f5                	j	ffffffffc0203e22 <strcmp+0x1e>

ffffffffc0203e38 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e38:	ce01                	beqz	a2,ffffffffc0203e50 <strncmp+0x18>
ffffffffc0203e3a:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203e3e:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e40:	cb91                	beqz	a5,ffffffffc0203e54 <strncmp+0x1c>
ffffffffc0203e42:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e46:	00f71763          	bne	a4,a5,ffffffffc0203e54 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0203e4a:	0505                	addi	a0,a0,1
ffffffffc0203e4c:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e4e:	f675                	bnez	a2,ffffffffc0203e3a <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e50:	4501                	li	a0,0
ffffffffc0203e52:	8082                	ret
ffffffffc0203e54:	00054503          	lbu	a0,0(a0)
ffffffffc0203e58:	0005c783          	lbu	a5,0(a1)
ffffffffc0203e5c:	9d1d                	subw	a0,a0,a5
}
ffffffffc0203e5e:	8082                	ret

ffffffffc0203e60 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203e60:	a021                	j	ffffffffc0203e68 <strchr+0x8>
        if (*s == c) {
ffffffffc0203e62:	00f58763          	beq	a1,a5,ffffffffc0203e70 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0203e66:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e68:	00054783          	lbu	a5,0(a0)
ffffffffc0203e6c:	fbfd                	bnez	a5,ffffffffc0203e62 <strchr+0x2>
    }
    return NULL;
ffffffffc0203e6e:	4501                	li	a0,0
}
ffffffffc0203e70:	8082                	ret

ffffffffc0203e72 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e72:	ca01                	beqz	a2,ffffffffc0203e82 <memset+0x10>
ffffffffc0203e74:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e76:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e78:	0785                	addi	a5,a5,1
ffffffffc0203e7a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e7e:	fef61de3          	bne	a2,a5,ffffffffc0203e78 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203e82:	8082                	ret

ffffffffc0203e84 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203e84:	ca19                	beqz	a2,ffffffffc0203e9a <memcpy+0x16>
ffffffffc0203e86:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203e88:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203e8a:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e8e:	0585                	addi	a1,a1,1
ffffffffc0203e90:	0785                	addi	a5,a5,1
ffffffffc0203e92:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203e96:	feb61ae3          	bne	a2,a1,ffffffffc0203e8a <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203e9a:	8082                	ret

ffffffffc0203e9c <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203e9c:	c205                	beqz	a2,ffffffffc0203ebc <memcmp+0x20>
ffffffffc0203e9e:	962a                	add	a2,a2,a0
ffffffffc0203ea0:	a019                	j	ffffffffc0203ea6 <memcmp+0xa>
ffffffffc0203ea2:	00c50d63          	beq	a0,a2,ffffffffc0203ebc <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203ea6:	00054783          	lbu	a5,0(a0)
ffffffffc0203eaa:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203eae:	0505                	addi	a0,a0,1
ffffffffc0203eb0:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203eb2:	fee788e3          	beq	a5,a4,ffffffffc0203ea2 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203eb6:	40e7853b          	subw	a0,a5,a4
ffffffffc0203eba:	8082                	ret
    }
    return 0;
ffffffffc0203ebc:	4501                	li	a0,0
}
ffffffffc0203ebe:	8082                	ret
