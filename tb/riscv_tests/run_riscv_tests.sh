#!/usr/bin/env bash
set -e

HEX_OUT_DIR="tb/hex/rv32ui"
BUILD_DIR="sim/rv32ui_build"
RISCV_TESTS_DIR="tb/riscv_tests/riscv-tests-src"
FORCE_REBUILD=0

if [ "$1" = "--rebuild" ]; then
    FORCE_REBUILD=1
fi

# The 37 RV32I base instructions + simple sanity test
# (fence_i belongs to Zifencei; ma_data tests misaligned trap handling)
TESTS=(
    simple
    add addi and andi auipc
    beq bge bgeu blt bltu bne
    jal jalr
    lb lbu lh lhu lw
    lui
    or ori
    sb sh sw
    sll slli slt slti sltiu sltu sra srai srl srli sub
    xor xori
)

# Check whether any .hex file is missing
NEED_BUILD=$FORCE_REBUILD
for t in "${TESTS[@]}"; do
    if [ ! -f "$HEX_OUT_DIR/${t}.hex" ]; then
        NEED_BUILD=1
        break
    fi
done

if [ "$NEED_BUILD" -eq 1 ]; then
    # Detect RISC-V GCC prefix
    if command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
        CROSS=riscv64-unknown-elf-
    elif command -v riscv32-unknown-elf-gcc >/dev/null 2>&1; then
        CROSS=riscv32-unknown-elf-
    else
        echo "Error: RISC-V GNU toolchain not found and .hex files need to be built."
        echo "Install it on Ubuntu/Debian with:"
        echo "  sudo apt update && sudo apt install -y gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf"
        exit 1
    fi

    if [ ! -d "$RISCV_TESTS_DIR/isa/rv32ui" ]; then
        echo "Cloning official riscv-tests into $RISCV_TESTS_DIR..."
        git clone --depth 1 https://github.com/riscv-software-src/riscv-tests.git "$RISCV_TESTS_DIR"
    fi

    mkdir -p "$HEX_OUT_DIR" "$BUILD_DIR"

    echo "Compiling RV32UI assembly tests into $HEX_OUT_DIR/*.hex..."
    for t in "${TESTS[@]}"; do
        SRC="$RISCV_TESTS_DIR/isa/rv32ui/${t}.S"
        ELF="$BUILD_DIR/${t}.elf"
        BIN="$BUILD_DIR/${t}.bin"
        HEX="$HEX_OUT_DIR/${t}.hex"

        ${CROSS}gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles \
            -I"tb/riscv_tests" \
            -I"$RISCV_TESTS_DIR/isa/macros/scalar" \
            -T "tb/riscv_tests/link.ld" \
            "$SRC" -o "$ELF"

        ${CROSS}objcopy -O binary "$ELF" "$BIN"
        hexdump -v -e '1/4 "%08x\n"' "$BIN" > "$HEX"
    done
fi

PASSED=0
FAILED=0

echo "=========================================================="
echo " Running Official RV32UI Tests (${#TESTS[@]} tests)"
echo "=========================================================="

for t in "${TESTS[@]}"; do
    HEX="$HEX_OUT_DIR/${t}.hex"

    # Simulate with Icarus Verilog
    iverilog -g2012 -P riscv_tb.PROGRAM_FILE=\"$HEX\" -P riscv_tb.MAX_CYCLES=5000 \
        -o sim/riscv.out rtl/riscv.sv rtl/modules/*.sv tb/riscv_tb.sv 2>/dev/null

    if OUTPUT=$(vvp sim/riscv.out 2>&1) && echo "$OUTPUT" | grep -q "\[PASS\]"; then
        CYCLES=$(echo "$OUTPUT" | grep -oE "[0-9]+ cycles" | head -n 1)
        printf "  [PASS] %-8s (%s)\n" "$t" "$CYCLES"
        PASSED=$((PASSED + 1))
    else
        printf "  [FAIL] %-8s\n" "$t"
        echo "$OUTPUT" | tail -n 6
        FAILED=$((FAILED + 1))
    fi
done

echo "=========================================================="
echo " Summary: $PASSED passed, $FAILED failed (out of ${#TESTS[@]})"
echo "=========================================================="

test "$FAILED" -eq 0
