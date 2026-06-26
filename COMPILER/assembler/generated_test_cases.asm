# --- 1. Immediate Load & PC Operations ---
# loadi: r1 = 10 (8-bit imm: -128 to 127)
loadi r1, 10
# lui: r2 = 256 (1 << 8) (8-bit imm)
lui r2, 1
# auipc: r3 = PC + 0 (8-bit imm)
auipc r3, 0

# --- 2. ALU Operations ---
# add: r4 = 10 + 256 = 266
add r4, r1, r2
# sub: r5 = 10 - 256 = -246
sub r5, r1, r2
# and: r6 = 10 & 266
and r6, r1, r4
# or: r7 = 10 | 266
or r7, r1, r4

# --- 3. ALU Immediate Operations ---
# addi: r8 = 10 + 7 = 17 (4-bit imm: -8 to 7)
addi r8, r1, 7
# asi: r9 = 10 + (2 << 4) = 42 (4-bit imm)
asi r9, r1, 2

# --- 4. Memory Operations ---
# loadi: r10 = 0 (Base address)
loadi r10, 0
# store: Mem[0 + 4] = r8(17) (4-bit imm: -8 to 7)
store 4, r10, r8
# load: r11 = Mem[0 + 4] (4-bit imm)
load r11, r10, 4

# --- 5. Branch Operations (Flag dependencies) ---
# sub: r0(zero) = r1 - r1 (Sets Z=1)
sub r0, r1, r1
# bz: Branch if Z=1 (12-bit imm: -2048 to 2047)
bz L_BZ_TARGET
nop
addi r1, r0, 1        # Skip this
L_BZ_TARGET:

# sub: r0 = -5 - 10 (Sets N=1)
loadi r12, -5
sub r0, r12, r1
# blt: Branch if N^V=1
blt L_BLT_TARGET
nop
addi r1, r0, 2        # Skip this
L_BLT_TARGET:

# sub: r0 = 0 - 0 (Sets Z=1)
sub r0, r0, r0
# ble: Branch if (N^V)|Z=1
ble L_BLE_TARGET
nop
addi r1, r0, 3        # Skip this
L_BLE_TARGET:

# --- 6. Jump Operations ---
# jal: r13 = PC + 1, Jump to L_JAL (8-bit imm: -128 to 127)
jal r13, L_JAL_TARGET
nop
addi r1, r0, 4        # Skip this
L_JAL_TARGET:

# jalr: r14 = PC + 1, Jump to r13 + 3 (4-bit imm: -8 to 7)
# r13はjal直後のnopのアドレスを指しているため、+3でL_ENDへ
jalr r14, r13, 3
nop
addi r1, r0, 5        # Skip this
L_END:

# Termination
sub r0, r0, r0