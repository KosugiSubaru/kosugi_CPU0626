#!/usr/bin/env python3
import sys
import re

# r15 is reserved as an assembler scratch register for conditional long-jump expansion
SCRATCH_REG = 15

def fits_signed(val, bits):
    return -(1 << (bits - 1)) <= val <= (1 << (bits - 1)) - 1

def encode_bits(val, bits):
    return format(val & ((1 << bits) - 1), f'0{bits}b')

def parse_reg(reg_str):
    m = re.match(r'r(\d+)', reg_str.strip().lower())
    if not m:
        print(f"Error: Invalid register '{reg_str}'"); sys.exit(1)
    n = int(m.group(1))
    if not (0 <= n <= 15):
        print(f"Error: Register r{n} out of range"); sys.exit(1)
    return n

def resolve_val(val_str, labels):
    if val_str in labels:
        return labels[val_str]
    try:
        return int(val_str, 0)
    except ValueError:
        print(f"Error: Invalid immediate or label '{val_str}'"); sys.exit(1)

def decompose_pc_relative(offset):
    """Split offset = imm8*256 + imm4_mid*16 + imm4_low.
    imm8 (auipc) and imm4_low (addi) are signed; imm4_mid (asi) is unsigned,
    since the CPU's asi does not sign-extend its immediate.
    Used to represent a pc-relative offset via auipc + asi + addi."""
    imm4_low = ((offset + 8) % 16) - 8  # signed [-8, 7]
    rest = offset - imm4_low            # multiple of 16
    q = rest // 16                      # = imm8*16 + imm4_mid
    imm4_mid = q % 16                   # unsigned [0, 15]
    imm8 = q // 16                      # signed
    if not fits_signed(imm8, 8):
        return None
    return imm8, imm4_mid, imm4_low

BRANCH_OPS = {'blt': '1010', 'ble': '1011', 'bz': '1100'}

def get_branch_offset(pc, args, labels):
    """Return encoded branch offset (relative) for a branch/jump at pc."""
    val_str = args[0]
    if val_str in labels:
        return labels[val_str] - pc - 1
    try:
        return int(val_str, 0)
    except ValueError:
        print(f"Error: Invalid branch target '{val_str}'"); sys.exit(1)

def get_jal_offset(pc, args, labels):
    val_str = args[1]
    if val_str in labels:
        return labels[val_str] - pc - 1
    try:
        return int(val_str, 0)
    except ValueError:
        print(f"Error: Invalid jump target '{val_str}'"); sys.exit(1)

def get_expansion_size(pc, op, args, labels):
    """Return the number of instructions this op expands to (1 if no expansion needed)."""
    if op in BRANCH_OPS:
        if not fits_signed(get_branch_offset(pc, args, labels), 12):
            return 6  # branch_skip + jal_over + auipc + asi + addi + jalr
    elif op == 'jal':
        if not fits_signed(get_jal_offset(pc, args, labels), 8):
            return 4  # auipc + asi + addi + jalr
    return 1

def encode_expanded_branch(pc, op, args, labels):
    """
    Expand a conditional branch that's out of 12-bit range into 6 instructions.
    Uses SCRATCH_REG (r15) to hold the target address.

    Layout at pc:
      +0: branch_op imm=1   -> if taken, jump to pc+2 (auipc); else fall through to +1
      +1: jal r0, imm=4     -> unconditional, jump to pc+6 (past the long-jump sequence)
      +2: auipc r15, imm8   -> r15 = (pc+2) + imm8*256
      +3: asi   r15, r15, imm4_mid
      +4: addi  r15, r15, imm4_low  -> r15 = target
      +5: jalr  r0, r15, 0  -> pc = r15 (jump to target, discard return address)
      +6: (next original instruction)
    """
    op_code = BRANCH_OPS[op]
    scratch = encode_bits(SCRATCH_REG, 4)
    r0 = encode_bits(0, 4)

    auipc_pc = pc + 2
    offset = get_branch_offset(pc, args, labels)
    target_pc = pc + offset  # absolute target address
    decomp = decompose_pc_relative(target_pc - auipc_pc)
    if decomp is None:
        print(f"Error: PC={pc}: branch target offset {target_pc - auipc_pc} out of range for expansion")
        sys.exit(1)
    imm8, imm4_mid, imm4_low = decomp

    return [
        encode_bits(1, 12) + op_code,                           # +0: branch taken -> pc+2
        encode_bits(4, 8) + r0 + "1101",                        # +1: jal r0, 4 -> pc+6
        encode_bits(imm8, 8) + scratch + "1111",                 # +2: auipc r15, imm8
        encode_bits(imm4_mid, 4) + scratch + scratch + "0101",   # +3: asi r15, r15, imm4_mid
        encode_bits(imm4_low, 4) + scratch + scratch + "0100",   # +4: addi r15, r15, imm4_low
        "0000" + scratch + r0 + "1110",                          # +5: jalr r0, r15, 0
    ]

def encode_expanded_jal(pc, args, labels):
    """
    Expand a jal that's out of 8-bit range into 4 instructions.
    If rd is r0 (zero reg, unwritable), uses SCRATCH_REG for address computation.

    Layout at pc:
      +0: auipc addr_reg, imm8
      +1: asi   addr_reg, addr_reg, imm4_mid
      +2: addi  addr_reg, addr_reg, imm4_low  -> addr_reg = target
      +3: jalr  rd, addr_reg, 0               -> rd = pc+4, jump to addr_reg
    """
    rd_num = parse_reg(args[0])
    # r0 can't hold the intermediate address (always reads 0), fall back to scratch
    addr_num = rd_num if rd_num != 0 else SCRATCH_REG

    offset = get_jal_offset(pc, args, labels)
    target_pc = pc  + offset
    decomp = decompose_pc_relative(target_pc - pc)
    if decomp is None:
        print(f"Error: PC={pc}: jal target offset {target_pc - pc} out of range for expansion")
        sys.exit(1)
    imm8, imm4_mid, imm4_low = decomp

    rd = encode_bits(rd_num, 4)
    ar = encode_bits(addr_num, 4)
    return [
        encode_bits(imm8, 8) + ar + "1111",          # auipc addr_reg, imm8
        encode_bits(imm4_mid, 4) + ar + ar + "0101",  # asi addr_reg, addr_reg, imm4_mid
        encode_bits(imm4_low, 4) + ar + ar + "0100",  # addi addr_reg, addr_reg, imm4_low
        "0000" + ar + rd + "1110",                    # jalr rd, addr_reg, 0
    ]

def encode_single(pc, op, args, labels):
    """Encode a single instruction that fits within its immediate range."""
    def reg(r):
        return encode_bits(parse_reg(r), 4)
    def fits_unsigned(val, bits):
        return 0 <= val <= (1 << bits) - 1

    def imm(v, bits, rel=False, signed=True):
        val = resolve_val(v, labels)
        if rel:
            val = val - pc - 1
        if signed:
            if not fits_signed(val, bits):
                raise OverflowError(f"Value {val} out of {bits}-bit signed range")
        else:
            if not fits_unsigned(val, bits):
                raise OverflowError(f"Value {val} out of {bits}-bit unsigned range")
        return encode_bits(val, bits)

    try:
        if op == "add":    return reg(args[2]) + reg(args[1]) + reg(args[0]) + "0000"
        if op == "sub":    return reg(args[2]) + reg(args[1]) + reg(args[0]) + "0001"
        if op == "and":    return reg(args[2]) + reg(args[1]) + reg(args[0]) + "0010"
        if op == "or":     return reg(args[2]) + reg(args[1]) + reg(args[0]) + "0011"
        if op == "addi":   return imm(args[2], 4) + reg(args[1]) + reg(args[0]) + "0100"
        if op == "asi":    return imm(args[2], 4, signed=False) + reg(args[1]) + reg(args[0]) + "0101"
        if op == "loadi":  return imm(args[1], 8) + reg(args[0]) + "0110"
        if op == "lui":    return imm(args[1], 8) + reg(args[0]) + "0111"
        if op == "load":   return imm(args[2], 4) + reg(args[1]) + reg(args[0]) + "1000"
        if op == "store":  return reg(args[2]) + reg(args[1]) + imm(args[0], 4) + "1001"
        if op == "blt":    return imm(args[0], 12, True) + "1010"
        if op == "ble":    return imm(args[0], 12, True) + "1011"
        if op == "bz":     return imm(args[0], 12, True) + "1100"
        if op == "jal":    return imm(args[1], 8, True) + reg(args[0]) + "1101"
        if op == "jalr":   return imm(args[2], 4) + reg(args[1]) + reg(args[0]) + "1110"
        if op == "auipc":  return imm(args[1], 8) + reg(args[0]) + "1111"
        if op == "nop":    return "0000000000000100"
    except IndexError:
        print(f"Error: Missing arguments for '{op}' at PC={pc}"); sys.exit(1)
    print(f"Error: Unknown mnemonic '{op}' at PC={pc}"); sys.exit(1)

def assemble(input_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    # First pass: collect raw instructions and label -> instruction-index mapping
    raw_instrs = []  # list of (op, args)
    raw_labels = {}  # label name -> index into raw_instrs
    for line in lines:
        line = re.sub(r'#.*', '', line).strip()
        if not line:
            continue
        if line.endswith(':'):
            raw_labels[line[:-1]] = len(raw_instrs)
        else:
            parts = re.split(r'[,\s]+', line)
            op = parts[0].lower()
            args = [a for a in parts[1:] if a]
            raw_instrs.append((op, args))

    # Relaxation loop: expand instructions that exceed their immediate range.
    # Sizes can only grow, so this always converges.
    sizes = [1] * len(raw_instrs)
    for _ in range(200):
        # Compute starting PC for each raw instruction from current sizes
        pcs = []
        cur = 0
        for s in sizes:
            pcs.append(cur)
            cur += s

        # Resolve labels to their (possibly expanded) PCs
        labels = {name: pcs[idx] for name, idx in raw_labels.items()}

        new_sizes = [get_expansion_size(pcs[i], op, args, labels)
                     for i, (op, args) in enumerate(raw_instrs)]
        if new_sizes == sizes:
            break
        sizes = new_sizes
    else:
        print("Error: Relaxation did not converge"); sys.exit(1)

    # Final encoding pass
    for i, (op, args) in enumerate(raw_instrs):
        pc_i = pcs[i]
        size = sizes[i]

        if size == 1:
            binary = encode_single(pc_i, op, args, labels)
            print(f"@{pc_i:02x} {binary}")
        elif op in BRANCH_OPS and size == 6:
            for j, b in enumerate(encode_expanded_branch(pc_i, op, args, labels)):
                print(f"@{pc_i+j:02x} {b}")
        elif op == 'jal' and size == 4:
            for j, b in enumerate(encode_expanded_jal(pc_i, args, labels)):
                print(f"@{pc_i+j:02x} {b}")
        else:
            print(f"Error: Unexpected state for '{op}' at PC={pc_i}"); sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 assembler.py <input.asm>")
        sys.exit(1)
    assemble(sys.argv[1])
