# Single-Cycle RV32I Processor in SystemVerilog

**Technical Report**

| | |
|---|---|
| **Author** | Luís Sampaio |
| **Language** | SystemVerilog |
| **Branch** | `single-cycle` |
| **Date** | October 2026 |

---

## 1. Introduction

This report describes the design, implementation and verification of a single-cycle processor that implements the RISC-V **RV32I** base integer instruction set, written in SystemVerilog. The design is modular and structural: each hardware block (ALU, register file, memories, control unit, immediate generator, program counter and next-PC logic) is an independent module, and a top-level module connects them.

Since the moment I took the FSC course, I have always had a strong desire to implement a RISC-V processor. However, two years ago, I knew almost nothing about the subject and did not even know what SystemVerilog was. As I became more interested in hardware description languages, I realized I wanted to build my own RISC-V processor, and I did it!

The processor executes one complete instruction per clock cycle. It supports the arithmetic, logic, shift, comparison, load, store, branch and jump instructions of RV32I that appear on the course reference card, so programs compiled for the `rv32i` target can be loaded into its instruction memory.

## 2. Objectives

- Understand how a RISC-V instruction is decoded and executed in hardware.
- Practice SystemVerilog: `always_ff`, `always_comb`, parameters, `case` statements, signed/unsigned arithmetic, memory arrays and structural modeling.
- Build a processor that can be extended later (multi-cycle and 5-stage pipelined versions are planned in other branches).
- Verify each module and the complete processor with test programs.

## 3. Supported Instructions

The reference is the *RISC-V Reference Card* of the FSC course (December 2024).

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

- M extension (multiply / divide)
- `fence`, `ecall`, `ebreak` and CSR instructions (treated as no operation, because the control unit uses safe default values for unknown opcodes)
- Compressed instructions (C extension)
- Misaligned memory accesses (assumed aligned)
- Exceptions and interrupts

## 4. Architecture Overview

In a single-cycle processor all five logical stages (fetch, decode, execute, memory, write-back) happen in the **same clock cycle**, connected by combinational logic. State changes only at the rising clock edge: the program counter, the register file write and the data memory write.

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
    |   +---------+ rd1 +-------+  alu_b   +---------+
    |   | regfile |---->|       |<---------| mux     |
    |   |         | rd2 |  ALU  |          | rs2/imm |
    |   |         |---->|       |          +---------+
    |   +---------+     +-------+
    |        ^            | alu_result, zero
    |        |            v
    |        |      +-----------+
    |        |      | data_mem  |--> mem_data
    |        |      +-----------+
    |        |            |
    |        +---- write-back mux: ALU / memory / pc+4 / pc+imm / imm
    |
    +--- jump_module <-- pc+4, pc+imm, alu_result, zero, funct3
         (outputs pc_next)
```

**Main design choices**

- Control decisions are separated from the datapath: the control unit produces small control signals, and the datapath modules only move and compute data.
- The main architectural decisions are explained in Sections 5.8 and 5.9, where the next-PC logic and the top-level integration are described in detail.
- As the diagram of the RISC-V CPU reference card shows, besides the ALU there are two additional adders: `pc + 4` and `pc + imm`.
- The `pc + 4` adder is reused for the `jal` and `jalr` instructions.
- The `pc + imm` adder is reused for the `auipc` instruction.
- For B-type branch conditions, the ALU is reused so that only the `zero_flag` is needed to determine whether the branch is taken.

## 5. Module Description

### 5.1 `program_counter`

A 32-bit register with synchronous reset. At each rising edge it stores `pc_next`. It does not compute anything. The PC counts bytes, so the instruction memory is indexed with `pc[31:2]`.

### 5.2 `instr_mem`

Instruction memory (ROM) loaded from a `.hex` file with `$readmemh`, one 32-bit word per line. The read is combinational.

### 5.3 `control_unit`

Purely combinational. Inputs: `opcode`, `funct3` and bit 30 of the instruction (`funct7_5`). The ALU decoder is merged into this module, so it outputs a 4-bit `alu_op` directly instead of using a 2-bit `ALUOp` plus a second decoder as in the sheet design.

| Output | Width | Meaning |
|---|---|---|
| `reg_write` | 1 | Enables the write to the register file |
| `mem_write` | 1 | Enables the write to data memory |
| `mem_read` | 1 | Marks a load instruction |
| `jump` | 2 | Next-PC control: `00` sequential, `01` conditional branch, `10` jal, `11` jalr |
| `alu_op` | 4 | ALU operation (see 5.4) |
| `alu_src` | 1 | ALU operand B: `0` = rs2, `1` = immediate |
| `write_back` | 3 | Value written to `rd`: `000` ALU, `001` memory, `010` pc+4, `011` pc+imm, `100` imm |

Bit 30 of the instruction is used only where it is part of the opcode encoding: R-type (`add`/`sub`, `srl`/`sra`) and the shift immediates (`srli`/`srai`). For `addi` and the other I-type operations it is ignored, because there it belongs to the immediate.

### 5.4 `alu`

32-bit arithmetic and logic unit. Inputs: two operands and `alu_op`. Outputs: `result` and a `zero` flag (1 when the result is 0).

| `alu_op` | Operation |
|---|---|
| `0000` | ADD |
| `0001` | SUB |
| `0010` | AND |
| `0011` | OR |
| `0100` | XOR |
| `0101` | SLL (shift left logical) |
| `0110` | SRL (shift right logical) |
| `0111` | SRA (shift right arithmetic) |
| `1000` | SLT (signed compare, result 0 or 1) |
| `1001` | SLTU (unsigned compare, result 0 or 1) |

Shifts use only the lower 5 bits of operand B.

### 5.5 `regfile`

32 registers of 32 bits, with two asynchronous read ports and one synchronous write port. Register `x0` is hardwired to zero: writes to `x0` are ignored.

### 5.6 `data_mem`

Data memory (RAM) organized in words. Reads are combinational and writes are synchronous. `funct3` selects the access size and the extension:

| `funct3` | Load | Store | Behaviour |
|---|---|---|---|
| `000` | `lb` | `sb` | byte; loads are sign-extended |
| `001` | `lh` | `sh` | half-word; loads are sign-extended |
| `010` | `lw` | `sw` | word |
| `100` | `lbu` | n/a | byte, zero-extended |
| `101` | `lhu` | n/a | half-word, zero-extended |

`addr[1:0]` selects the byte inside the word. A store modifies only the selected bytes.

### 5.7 `imm_generator`

Extracts and sign-extends the immediate according to the opcode:

| Type | Immediate |
|---|---|
| I | `{{20{instr[31]}}, instr[31:20]}` |
| S | `{{20{instr[31]}}, instr[31:25], instr[11:7]}` |
| B | `{{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}` |
| U | `{instr[31:12], 12'b0}` |
| J | `{{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}` |

### 5.8 `jump_module`

Chooses `pc_next` from `pc + 4`, `pc + imm` and the ALU result, using the `jump` control signal, `funct3` and the ALU zero flag.

| Instruction | ALU op | Branch taken when |
|---|---|---|
| `beq` | SUB | `zero = 1` |
| `bne` | SUB | `zero = 0` |
| `blt` | SLT | `zero = 0` (result 1 means "less than") |
| `bge` | SLT | `zero = 1` |
| `bltu` | SLTU | `zero = 0` |
| `bgeu` | SLTU | `zero = 1` |

One of the key design decisions in this project was the definition of the next-PC logic. Initially, the reference diagram suggested a simple branch structure that was only sufficient for a limited case, such as beq, and it could not naturally support the full set of RV32I control-flow instructions, including jumps and the remaining branch conditions. Because this is a single-cycle processor, the ALU is only allowed to perform one operation per clock cycle, so the control-flow decision could not be handled by a single mux2 based only on one comparison. I therefore decided that the next-PC signal needed a more intelligent selection scheme, where pc_next could choose among three distinct targets—pc + 4, pc + imm, and the ALU result—depending on the instruction type and the ALU output. This separation between arithmetic computation and control-flow decision was crucial to support jumps, branches and returns while preserving the single-cycle execution model.


### 5.9 `riscv` (top level)

The top-level module instantiates all the modules above and connects them with wires. I initially followed the reference diagram provided by the professor, but it quickly became clear that this structure was not sufficient to support all the RV32I instructions, especially the different jump and branch cases. In a single-cycle processor, the ALU can only perform one operation per cycle, so a simple mux2-based PC selection was not enough to cover the full control-flow logic. For that reason, I had to replace the original PC-source selection with a more capable pc_next decision block, able to choose among pc + 4, pc + imm, and the ALU result depending on the instruction type and the ALU output. Similarly, the original memory-to-register selection logic had to be extended from a simple two-input multiplexer into a wider write-back multiplexer, so that the register file could receive data from the ALU, memory, pc + 4, pc + imm, or an immediate value. The module therefore keeps the same external inputs, clk and reset, but the internal datapath is adapted to support the full RV32I instruction set.


## 6. Verification

### 6.1 Method

A testbench (`riscv_tb.sv`) clears both memories, loads `prog.hex` into the instruction memory, applies reset, runs 30 clock cycles and prints all registers, the first data memory words and the final PC. The results are compared with values computed independently by a Python model of the instruction set.

### 6.2 Test programs

**`prog_alu_mem.hex`** (29 instructions): ALU and memory. It covers all 10 R-type, 9 I-type ALU, 5 load and 3 store instructions, including signed and unsigned comparison, logical and arithmetic shifts, sign and zero extension on loads, partial stores (`sb`, `sh`) and the rule that writes to `x0` are ignored.

Expected final state:

| Register | Value | Register | Value | Register | Value |
|---|---|---|---|---|---|
| x1 | `FFFFFFF8` | x10 | `FFFFFFFF` | x19 | `00000001` |
| x2 | `00000003` | x11 | `00000001` | x20 | `00000000` |
| x3 | `FFFFFFFB` | x12 | `00000000` | x21 | `C0000000` |
| x4 | `FFFFFFF5` | x13 | `00000056` | x22 | `FFFFFFF8` |
| x5 | `00000000` | x14 | `00000073` | x23 | `0000FFF8` |
| x6 | `FFFFFFFB` | x15 | `000000F8` | x24 | `00000003` |
| x7 | `FFFFFFFB` | x16 | `C0000000` | x25 | `000000F8` |
| x8 | `00000018` | x17 | `0C000000` | x0 | `00000000` |
| x9 | `1FFFFFFF` | x18 | `FC000000` | | |

Memory: `mem[0] = C0000000`, `mem[1] = 0003FFF8`.

**`prog_branch_jump.hex`** (26 instructions): control flow. It covers the 6 branches (taken and not taken, signed and unsigned), `jal`, `jalr`, `lui` and `auipc`. Skipped instructions write 99 to `x20`, so a wrong jump is detected immediately.

Expected final state:

| Register | Value |
|---|---|
| x1 | `FFFFFFFF` |
| x2 | `00000001` |
| x3 | `00000001` |
| x4 | `00000002` |
| x5 | `00000048` |
| x6 | `12345000` |
| x7 | `00001050` |
| x9 | `00000054` |
| x10 | `0000005C` |
| x11 | `00000007` |
| x20 | `00000000` |
| PC | `00000064` (parked on `jal x0, 0`) |

### 6.3 Results

> Fill in after running the tests.

| Test | Result |
|---|---|
| `prog_alu_mem` | [PASS / FAIL] |
| `prog_branch_jump` | [PASS / FAIL] |
| Simulator | [e.g. Icarus Verilog, ModelSim, Vivado xsim] |

### 6.4 Bugs found during development

- **Duplicate case labels** in the control unit and in `jump_module`: `bltu` and `bgeu` used the `funct3` values of `blt` and `bge` (`100` and `101`) instead of `110` and `111`. Found with the branch test program.
- **Missing default assignment** in an `always_comb` block, which caused a latch or an unknown PC. Fixed by assigning a default value at the start of the block.

## 7. How to Build and Run

> Adapt the commands to your simulator and file names.

Example with Icarus Verilog:

```bash
iverilog -g2012 -o sim src/*.sv tb/riscv_tb.sv
vvp sim
```

Place `prog.hex` in the simulation working directory. To run another test, change the file name in the `$readmemh` call of the testbench.

## 8. Repository Structure

```text
riscv-processor/
├── README.md
├── src/
│   ├── alu.sv
│   ├── control_unit.sv
│   ├── data_mem.sv
│   ├── instr_mem.sv
│   ├── imm_generator.sv
│   ├── jump_module.sv
│   ├── program_counter.sv
│   ├── regfile.sv
│   └── riscv.sv
├── tb/
│   └── riscv_tb.sv
├── tests/
│   ├── prog_alu_mem.hex
│   └── prog_branch_jump.hex
└── docs/
    └── report.md
```

| Branch | Content |
|---|---|
| `main` | Documentation and overview |
| `single-cycle` | This design |
| `multi-cycle` | Planned |
| `pipeline` | Planned (5 stages, forwarding, hazard detection) |

## 9. Future Work

- Run the official `riscv-tests` suite (`rv32ui`) for formal verification.
- Compile C programs with `riscv32-unknown-elf-gcc` (`-march=rv32i -mabi=ilp32`) and run them on the processor.
- Multi-cycle version with an FSM and shared functional units.
- 5-stage pipeline with forwarding and hazard detection.
- M extension (multiplication and division).
- Branch prediction, caches and FPGA deployment.

## 10. References

1. *RISC-V Reference Card*, FSC L.EIC004, FEUP, December 2024.
2. *The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA*, RISC-V International.
3. D. Patterson and J. Hennessy, *Computer Organization and Design: RISC-V Edition*.

## 11. Usage of AI

AI tools were used as a support mechanism during the development of this project, mainly to accelerate the creation of verification code and to refine the structure of the testbenches. In particular, they were helpful for writing repetitive SystemVerilog test patterns, checking syntax details, and improving the clarity of the test descriptions. However, the core logic of the processor design was not delegated to AI: the architectural decisions, the datapath organization, the control-flow strategy, and the overall implementation were based on the course reference card and on the design choices made throughout the project.

The use of AI was therefore limited to small implementation details and auxiliary support, such as debugging wording, validating test structure, and helping to organize the verification flow. The logic itself remained driven by the reference material, by the understanding of the RV32I instruction set, and by the design decisions taken for the single-cycle processor. In that sense, AI was used as an assistant rather than as the origin of the architectural reasoning.