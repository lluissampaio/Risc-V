# Single-Cycle RV32I Processor in SystemVerilog

**Technical Report**

| | |
|---|---|
| **Author** | Luís Sampaio |
| **Language** | SystemVerilog (IEEE 1800-2012) |
| **Architecture** | Single-Cycle RV32I |
| **Date** | October 2026 |

---

## 1. Introduction

This report describes the design, implementation, and verification of a single-cycle processor that implements the RISC-V **RV32I** base integer instruction set, written in SystemVerilog. The design is modular and structural: each hardware block (ALU, register file, memories, control unit, immediate generator, multiplexers, program counter, and next-PC logic) is implemented as an independent module, and a top-level module ([`riscv.sv`](rtl/riscv.sv)) interconnects them.

Since the moment I took the FSC course, I have always had a strong desire to implement a RISC-V processor. However, two years ago, I knew almost nothing about the subject and did not even know what SystemVerilog was. As I became more interested in hardware description languages, I realized I wanted to build my own RISC-V processor, and I did it!

The processor executes one complete instruction per clock cycle. It supports all 37 arithmetic, logic, shift, comparison, load, store, branch, jump, and upper-immediate instructions of the RV32I reference card, allowing machine-code programs compiled or assembled for the `rv32i` target to run directly from instruction memory.

## 2. Objectives

- Understand in detail how RV32I instructions are fetched, decoded, and executed in hardware.
- Practice synthesizable and behavioral SystemVerilog constructs: `always_ff`, `always_comb`, parameters, `case` statements, signed/unsigned arithmetic, byte-addressable memory arrays, and structural modeling.
- Establish a clean, well-verified baseline architecture that serves as the foundation for future microarchitectural evolutions (such as a 5-stage pipelined processor and a multi-cycle implementation).
- Verify each hardware block individually with dedicated unit testbenches and validate the complete processor using end-to-end machine-code test programs.

## 3. Supported Instructions

The reference for the instruction set is the *RISC-V Reference Card* from the FSC course (December 2024).

| Type | Opcode | Instructions |
|---|---|---|
| R | `0110011` | `add` `sub` `and` `or` `xor` `sll` `srl` `sra` `slt` `sltu` |
| I (ALU) | `0010011` | `addi` `andi` `ori` `xori` `slli` `srli` `srai` `slti` `sltiu` |
| I (load) | `0000011` | `lb` `lh` `lw` `lbu` `lhu` |
| S | `0100011` | `sb` `sh` `sw` |
| B | `1100011` | `beq` `bne` `blt` `bge` `bltu` `bgeu` |
| J | `1101111` | `jal` |
| I (jump) | `1100111` | `jalr` |
| U | `0110111` | `lui` |
| U | `0010111` | `auipc` |

**Total: 37 distinct instructions.**

**Not supported in this version:**

- M extension (integer multiplication and division)
- `fence`, `ecall`, `ebreak`, and CSR instructions (treated safely as `nop` because the control unit deasserts all write enables on unknown opcodes)
- Compressed instructions (C extension)
- Misaligned word/half-word memory accesses (accesses are assumed naturally aligned)
- Exceptions and interrupts

## 4. Architecture Overview

In a single-cycle processor, all five logical phases of instruction execution (Fetch, Decode, Execute, Memory, and Write-Back) complete within the **same clock cycle** through combinational paths. Architectural state updates occur synchronously on the rising edge of the clock (`posedge clk`): updating the Program Counter (`PC`), writing to the Register File, and writing to Data Memory.

```text
        pc    +-----------+  instr
  +----+----->| instr_mem |----+------------------+
  | PC |      +-----------+    |                  |
  +----+                       v                  v
    ^                   +--------------+   +---------------+
    |                   | control_unit |   | imm_generator |
    |                   +--------------+   +---------------+
    |                     | control signals       | imm
    |                     v                       v
    |   +---------+ rd1 +-------+  regB    +---------------+
    |   | regfile |---->|       |<---------| mux2 (AluSrc) |
    |   |         | rd2 |  ALU  |          |   rd2 / imm   |
    |   |         |---->|       |          +---------------+
    |   +---------+     +-------+
    |        ^            | result, zero
    |        |            v
    |        |      +-----------+
    |        |      | data_mem  |--> read_data
    |        |      +-----------+
    |        |            |
    |        +---- mux5 (WriteBack): result / read_data / pc+4 / pc+imm / imm
    |
    +--- jump_module <-- pc+4, pc+imm, result, zero, funct3, jump
         (outputs pc_next)
```

**Main design choices:**

- **Separation of control and datapath:** [`control_unit.sv`](rtl/modules/control_unit.sv) decodes the instruction fields and generates control signals, while datapath modules only route and compute data.
- **Dedicated PC adders:** In addition to the main ALU, two combinational adders compute `pc_4 = pc + 4` and `pc_imm = pc + imm`.
  - `pc_4` is reused as the link address written back to `rd` by `jal` and `jalr`.
  - `pc_imm` is reused both as the branch/jump target and as the value written back to `rd` by `auipc`.
- **ALU reuse for branch evaluation:** Conditional branches (`B-type`) use the main ALU (`SUB`, `SLT`, or `SLTU`) together with `funct3` and the ALU `zero` flag inside [`jump_module.sv`](rtl/modules/jump_module.sv) to resolve all six branch conditions without extra comparator hardware.
- The main architectural decisions are explained in `Sections 5.8 and 5.9`, where the next-PC logic and the top-level integration are described in detail.

## 5. Module Description

### 5.1 `program_counter` ([`rtl/modules/program_counter.sv`](rtl/modules/program_counter.sv))

A 32-bit register with synchronous active-high reset. On each rising clock edge, it resets `pc` to `0` if `reset` is asserted, or latches `pc_next` otherwise. Because RISC-V uses byte addressing and instructions are 32-bit aligned, instruction memory is indexed using `pc[31:2]`.

### 5.2 `instr_mem` ([`rtl/modules/instr_mem.sv`](rtl/modules/instr_mem.sv))

A 256-word (1 KB) read-only instruction memory initialized at simulation start from a hexadecimal file via `$readmemh(PROGRAM_FILE, mem)`. Reads are purely combinational (`instr = mem[addr[31:2]]`).

### 5.3 `control_unit` ([`rtl/modules/control_unit.sv`](rtl/modules/control_unit.sv))

Purely combinational instruction decoder. Inputs are `opcode` (`instr[6:0]`), `funct3` (`instr[14:12]`), and bit 30 of the instruction (`funct7_5`, `instr[30]`). The ALU decoder is integrated directly into this unit, outputting a 4-bit `alu_op` rather than using an intermediate 2-bit `ALUOp` signal.

| Output | Width | Meaning |
|---|---|---|
| `reg_write` | 1 | Enables writing `wd` to `rd` in the register file |
| `mem_write` | 1 | Enables synchronous write to data memory |
| `mem_read` | 1 | Enables combinational read from data memory |
| `jump` | 2 | Next-PC mode: `00` sequential (`pc+4`), `01` B-type branch, `10` `jal`, `11` `jalr` |
| `alu_op` | 4 | Selects the ALU operation (see Section 5.4) |
| `alu_src` | 1 | ALU second operand (`regB`): `0` = `rd2`, `1` = `imm` |
| `write_back` | 3 | Selects data written to `rd`: `000` ALU, `001` memory, `010` `pc+4`, `011` `pc+imm`, `100` `imm` |

Bit 30 (`funct7_5`) is inspected only when required by the RV32I encoding: R-type (`add`/`sub`, `srl`/`sra`) and I-type shift immediates (`srli`/`srai`). For other I-type instructions (such as `addi`), bit 30 is part of the 12-bit immediate and is ignored by the decoder.

### 5.4 `alu` ([`rtl/modules/alu.sv`](rtl/modules/alu.sv))

32-bit combinational Arithmetic and Logic Unit. It receives operands `regA` and `regB` along with `alu_op`, and produces `res` and `zero_flag` (`1` when `res == 0`).

| `alu_op` | Operation | Description |
|---|---|---|
| `0000` | `ADD` | `regA + regB` |
| `0001` | `SUB` | `regA - regB` |
| `0010` | `AND` | `regA & regB` |
| `0011` | `OR` | `regA \| regB` |
| `0100` | `XOR` | `regA ^ regB` |
| `0101` | `SLL` | Logical left shift by `regB[4:0]` |
| `0110` | `SRL` | Logical right shift by `regB[4:0]` |
| `0111` | `SRA` | Arithmetic right shift (`$signed(regA) >>> regB[4:0]`) |
| `1000` | `SLT` | Signed set less than (`$signed(regA) < $signed(regB)`) |
| `1001` | `SLTU` | Unsigned set less than (`regA < regB`) |

### 5.5 `regfile` ([`rtl/modules/regfile.sv`](rtl/modules/regfile.sv))

32 general-purpose 32-bit registers (`x0`–`x31`) with two asynchronous read ports (`rs1`, `rs2` -> `rd1`, `rd2`), one synchronous write port (`rd`, `wd`, `we`), and synchronous reset. Register `x0` is hardwired to `0`: reads from address `0` always return `32'd0` and writes to `rd == 0` are ignored.

### 5.6 `data_mem` ([`rtl/modules/data_mem.sv`](rtl/modules/data_mem.sv))

A 1024-word (4 KB) byte-addressable RAM. Reads are combinational (gated by `mem_read`) and writes are synchronous on `posedge clk` (gated by `mem_write`). `funct3` determines the access width and sign/zero extension:

| `funct3` | Load | Store | Behavior |
|---|---|---|---|
| `000` | `lb` | `sb` | Byte access; loads are sign-extended to 32 bits |
| `001` | `lh` | `sh` | Half-word access; loads are sign-extended to 32 bits |
| `010` | `lw` | `sw` | 32-bit word access |
| `100` | `lbu` | — | Byte load, zero-extended to 32 bits |
| `101` | `lhu` | — | Half-word load, zero-extended to 32 bits |

The byte offset `addr[1:0]` selects the target byte or half-word within `mem[addr[31:2]]`. Partial stores (`sb`, `sh`) update only the targeted bytes while preserving the rest of the 32-bit word.

### 5.7 `imm_generator` ([`rtl/modules/imm_generator.sv`](rtl/modules/imm_generator.sv))

Extracts and sign-extends the 32-bit immediate value from `instr[31:7]` based on the instruction format (`opcode`):

| Format | Opcodes | Immediate Construction |
|---|---|---|
| I | `0010011`, `0000011`, `1100111` | `{{20{instr[31]}}, instr[31:20]}` |
| S | `0100011` | `{{20{instr[31]}}, instr[31:25], instr[11:7]}` |
| B | `1100011` | `{{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}` |
| U | `0110111`, `0010111` | `{instr[31:12], 12'b0}` |
| J | `1101111` | `{{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}` |

### 5.8 `jump_module` ([`rtl/modules/jump_module.sv`](rtl/modules/jump_module.sv))

Determines `pc_next` from three candidate targets (`pc_4`, `pc_imm`, and `alu_result`) using `funct3`, `flag_zero`, and the 2-bit `jump_control` signal:
- **`2'b00` (Sequential):** `pc_next = pc_4` (all non-control-flow instructions).
- **`2'b01` (B-Type Branch):** Selects between `pc_imm` (taken) and `pc_4` (not taken) depending on `funct3` and `flag_zero`.
- **`2'b10` :** `pc_next = pc_imm` (unconditional PC-relative jump).
- **`2'b11` (`jalr`):** `pc_next = {alu_result[31:1], 1'b0}` (unconditional register-relative jump with the least significant bit cleared, as required by the RV32I specification).

| Branch Instruction | `funct3` | ALU Operation | Branch Taken Condition (`pc_next = pc_imm`) |
|---|---|---|---|
| `beq` | `000` | `SUB` | `flag_zero == 1` (`rs1 == rs2`) |
| `bne` | `001` | `SUB` | `flag_zero == 0` (`rs1 != rs2`) |
| `blt` | `100` | `SLT` | `flag_zero == 0` (ALU result is `1`, meaning `rs1 < rs2` signed) |
| `bge` | `101` | `SLT` | `flag_zero == 1` (ALU result is `0`, meaning `rs1 >= rs2` signed) |
| `bltu` | `110` | `SLTU` | `flag_zero == 0` (ALU result is `1`, meaning `rs1 < rs2` unsigned) |
| `bgeu` | `111` | `SLTU` | `flag_zero == 1` (ALU result is `0`, meaning `rs1 >= rs2` unsigned) |

One of the key design decisions in this project was the definition of the next-PC logic. Initially, the reference diagram suggested a simple branch structure that was only sufficient for a limited case, such as `beq`, and could not naturally support the full set of RV32I control-flow instructions, including jumps and the remaining branch conditions. Because this is a single-cycle processor, the ALU is only allowed to perform one operation per clock cycle, so the control-flow decision could not be handled by a single `mux2` based on a single comparison.

I therefore decided that the next-PC signal needed a more capable selection scheme, where `pc_next` could choose among three distinct targets—`pc + 4`, `pc + imm`, and the `ALU result`—depending on the instruction type and the ALU output. This separation between arithmetic computation and control-flow resolution was crucial to support jumps, branches, and returns while preserving the single-cycle execution model. Moving this selection into [`jump_module.sv`](rtl/modules/jump_module.sv) also eliminated the external `PCSrc` 2-to-1 multiplexer.

### 5.9 `riscv` Top-Level ([`rtl/riscv.sv`](rtl/riscv.sv))

The top-level module instantiates all the modules above and interconnects them with wires. I initially followed the reference diagram provided by the professor, but it quickly became clear that this structure was not sufficient to support all 37 RV32I instructions. The initial course reference diagram used simple 2-to-1 multiplexers (`PCSrc` and `MemtoReg`) designed around a basic subset of instructions (`add`, `sub`, `lw`, `sw`, `beq`). Supporting the complete RV32I instruction set required two structural upgrades in the top-level datapath.

As explained above, the first upgrade was removing the external `PCSrc` mux in favor of the dedicated [`jump_module.sv`](rtl/modules/jump_module.sv). Similarly, the original memory-to-register selection logic had to be extended from a simple 2-input multiplexer into a wider **5-input Write-Back Multiplexer ([`mux5.sv`](rtl/modules/mux5.sv))**, so that the register file could receive data from the `ALU`, `memory`, `pc + 4`, `pc + imm`, or an `immediate value`. The module therefore keeps the same external interface (`clk` and `reset`), while adapting the internal datapath to support the full RV32I instruction set.

## 6. Verification and Testing

### 6.1 Methodology

Verification was conducted at two levels using **Icarus Verilog 12.0**:

1. **Unit-Level Verification (`tb/modules/*_tb.sv`):** Each hardware module was verified in isolation with self-checking SystemVerilog testbenches before top-level integration. Notably, [`control_unit_tb.sv`](tb/modules/control_unit_tb.sv) performs 86 automated assertions covering all 37 RV32I instructions plus invalid/`nop` opcodes.
2. **System-Level Verification ([`tb/riscv_tb.sv`](tb/riscv_tb.sv)):** The top-level testbench loads a machine-code `.hex` program into instruction memory via the `PROGRAM_FILE` parameter, asserts `reset` for two clock cycles, runs the processor for 30 clock cycles, and dumps the final architectural state (`x0`–`x31`, `mem[0]`–`mem[3]`, and `PC`) to verify against expected execution results.

### 6.2 System Test Programs

#### 1. [`tb/hex/program1.hex`](tb/hex/program1.hex) (24 instructions) — ALU & Data Memory
Tests R-type and I-type arithmetic, bitwise logic, logical/arithmetic shifts (`slli`, `srli`, `srai`), signed/unsigned comparisons (`slt`, `sltu`), word/half-word/byte stores (`sw`, `sh`, `sb`), and sign/zero-extended loads (`lw`, `lh`, `lhu`, `lb`, `lbu`).

Final register and memory state:

| Register | Value | Register | Value | Register | Value |
|---|---|---|---|---|---|
| `x1` | `0000000A` | `x8` | `FFFFFFFF` | `x15` | `FFFFFFFF` |
| `x2` | `00000014` | `x9` | `000000A0` | `x16` | `000000FF` |
| `x3` | `0000001E` | `x10` | `0000000F` | `x17` | `00A0140A` |
| `x4` | `0000000A` | `x11` | `FFFFFFFF` | `x18` | `000000A0` |
| `x5` | `00000000` | `x12` | `00000001` | `x0` | `00000000` |
| `x6` | `0000001E` | `x13` | `00000000` | `PC` | `00000078` |
| `x7` | `0000001E` | `x14` | `0000001E` | | |

Data memory: `mem[0] = 0000001E`, `mem[1] = FFFFFFFF`, `mem[2] = 00A0140A`.

#### 2. [`tb/hex/program2.hex`](tb/hex/program2.hex) (15 instructions) — Conditional Branch & Loop
Tests forward and backward `beq` branches (taken and not taken) and a bounded loop counter (`x8` incrementing up to `x9 = 3`), parking at `PC = 00000038` after writing `42` (`0x2A`) to `x10`.

Final state: `x1 = 00000005`, `x2 = 00000005`, `x3 = 00000000`, `x4 = 00000001`, `x5 = 00000007`, `x6 = 00000002`, `x8 = 00000003`, `x9 = 00000003`, `x10 = 0000002A`, `PC = 00000038`.

#### 3. [`tb/hex/program3.hex`](tb/hex/program3.hex) (26 instructions) — Full Control Flow & Upper Immediates
Covers all 6 conditional branches (`beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu` — both taken and not taken, signed and unsigned), `jal`, `jalr`, `lui`, and `auipc`. Skipped instructions attempt to write `99` (`0x63`) to `x20`, so any faulty branch or jump is immediately caught if `x20 != 0`.

Final state:

| Register | Value | Meaning |
|---|---|---|
| `x1` | `FFFFFFFF` | `-1` (`0xFFFFFFFF`) used for signed vs. unsigned branch tests |
| `x2` | `00000001` | `+1` |
| `x3` | `00000001` | Reached after `blt`/`bltu` verification |
| `x4` | `00000002` | Reached after `bge`/`bgeu` verification |
| `x5` | `00000048` | Return address (`pc + 4`) saved by `jal` |
| `x6` | `12345000` | Loaded via `lui x6, 0x12345` |
| `x7` | `00001050` | Computed via `auipc x7, 1` (`0x50 + 0x1000`) |
| `x9` | `00000054` | Base PC captured via `auipc x9, 0` |
| `x10` | `0000005C` | Return address (`pc + 4`) saved by `jalr` |
| `x11` | `00000007` | Executed at `jalr` target (`x9 + 12`) |
| `x20` | `00000000` | Error sentinel (`0` confirms no wrong branch/jump occurred) |
| `PC` | `00000064` | Parked on infinite loop (`jal x0, 0`) |

### 6.3 Results Summary

| Test Suite / Program | Target | Result |
|---|---|---|
| `alu_tb`, `control_unit_tb` (86 checks), `data_mem_tb`, `imm_generator_tb`, `jump_module_tb`, `program_counter_tb`, `regfile_tb` | Unit modules | **PASS** |
| [`tb/hex/program1.hex`](tb/hex/program1.hex) | System (`riscv_tb`) — ALU & Load/Store | **PASS** |
| [`tb/hex/program2.hex`](tb/hex/program2.hex) | System (`riscv_tb`) — Branches & Loop | **PASS** |
| [`tb/hex/program3.hex`](tb/hex/program3.hex) | System (`riscv_tb`) — All Branches, `jal`, `jalr`, `lui`, `auipc` | **PASS** |
| **Simulator** | Icarus Verilog (`iverilog`) 12.0 (`-g2012`) | — |

### 6.4 Bugs Found and Fixed During Development

- **Duplicate case labels in branch decoding:** Initially, `bltu` and `bgeu` in `control_unit` and `jump_module` mistakenly repeated the `funct3` encodings of `blt` and `bge` (`100` and `101`) instead of `110` and `111`. Detected with [`program3.hex`](tb/hex/program3.hex).
- **Missing default assignments in `always_comb`:** Inferred latches and unknown (`x`) PC propagation occurred when certain control paths lacked default values. Fixed by initializing all combinational outputs at the top of every `always_comb` block.

## 7. How to Build and Run

Using **Icarus Verilog** from the repository root:

```bash
# Run default test program (tb/hex/program1.hex)
iverilog -g2012 -o sim/riscv.out rtl/riscv.sv rtl/modules/*.sv tb/riscv_tb.sv
vvp sim/riscv.out

# Run program2.hex (branch & loop test)
iverilog -g2012 -P riscv_tb.PROGRAM_FILE=\"tb/hex/program2.hex\" -o sim/riscv.out rtl/riscv.sv rtl/modules/*.sv tb/riscv_tb.sv
vvp sim/riscv.out

# Run program3.hex (full control-flow & upper-immediate test)
iverilog -g2012 -P riscv_tb.PROGRAM_FILE=\"tb/hex/program3.hex\" -o sim/riscv.out rtl/riscv.sv rtl/modules/*.sv tb/riscv_tb.sv
vvp sim/riscv.out

# Run a unit testbench (example: control_unit)
iverilog -g2012 -o sim/control_unit.out rtl/modules/control_unit.sv tb/modules/control_unit_tb.sv
vvp sim/control_unit.out
```

## 8. Repository Structure

```text
Risc-V/
├── README.md
├── report.md
├── docs/
│   ├── CPU_RiscV_ReferenceCard_2024.pdf
│   └── RiscV_ReferenceCard_2024.pdf
├── rtl/
│   ├── riscv.sv
│   └── modules/
│       ├── alu.sv
│       ├── control_unit.sv
│       ├── data_mem.sv
│       ├── imm_generator.sv
│       ├── instr_mem.sv
│       ├── jump_module.sv
│       ├── mux2.sv
│       ├── mux5.sv
│       ├── program_counter.sv
│       └── regfile.sv
├── tb/
│   ├── riscv_tb.sv
│   ├── hex/
│   │   ├── program1.hex
│   │   ├── program2.hex
│   │   └── program3.hex
│   └── modules/
│       ├── alu_tb.sv
│       ├── control_unit_tb.sv
│       ├── data_mem_tb.sv
│       ├── imm_generator_tb.sv
│       ├── instr_mem_tb.sv
│       ├── jump_module_tb.sv
│       ├── program_counter_tb.sv
│       └── regfile_tb.sv
└── sim/
```

## 9. Future Work

- **5-Stage Pipelined Processor:** Evolve the repository into a modular structure sharing common datapath blocks (`alu`, `regfile`, `imm_generator`, memories) alongside a 5-stage pipeline (`IF`, `ID`, `EX`, `MEM`, `WB`) with data forwarding and hazard detection units.
- **Multi-Cycle Processor:** Implement a finite-state machine (FSM) controller sharing functional units across cycles.
- **Official RISC-V Compliance Suite & C Toolchain:** Compile C programs using `riscv32-unknown-elf-gcc` (`-march=rv32i -mabi=ilp32`) and run the `rv32ui` test suite.
- **M Extension & FPGA Synthesis:** Add hardware multiplication/division and synthesize the core onto an FPGA board.

## 10. References

1. *RISC-V Reference Card*, FSC L.EIC004, FEUP, December 2024.
2. *The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA*, RISC-V International.
3. D. Patterson and J. Hennessy, *Computer Organization and Design: RISC-V Edition*.

## 11. Usage of AI

AI tools were used as a support mechanism during the development of this project, mainly to accelerate the creation of verification code and to refine the structure of the testbenches. In particular, they were helpful for writing repetitive SystemVerilog test patterns, checking syntax details, and improving the clarity of the test descriptions. However, the core logic of the processor design was not delegated to AI: the architectural decisions, the datapath organization, the control-flow strategy, and the overall implementation were based on the course reference card and on the design choices made throughout the project.

The use of AI was therefore limited to small implementation details and auxiliary support, such as debugging wording, validating test structure, and helping to organize the verification flow. The logic itself remained driven by the reference material, by the understanding of the RV32I instruction set, and by the design decisions taken for the single-cycle processor. In that sense, AI was used as an assistant rather than as the origin of the architectural reasoning.
