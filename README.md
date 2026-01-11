# ZJVM - A JVM Implementation in Zig

A Java Virtual Machine implementation written in Zig, featuring a bytecode interpreter and runtime environment.

## Features

- Java class file parsing
- Bytecode interpreter
- Runtime stack and local variables management
- Support for basic JVM opcodes

## Building

```bash
make build-zjvm
```

Or using Zig directly:

```bash
zig build
```

## Running

```bash
make run
```

This will execute the sample Test.java program.

## Testing

Run the complete test suite:

```bash
make test
```

Or using Zig directly:

```bash
zig build test
```

### Test Coverage

The project includes unit tests for:

- **Value types** (`src/runtime/value_test.zig`): Tests for Int, Float, Long, Double, and Reference types
- **Operand Stack** (`src/runtime/operand_stack_test.zig`): Stack operations, overflow/underflow handling
- **Local Variables** (`src/runtime/local_vars_test.zig`): Variable storage and retrieval
- **Frame** (`src/runtime/frame_test.zig`): Frame initialization and structure
- **Opcodes** (`src/engine/opcode_test.zig`): Opcode enum values and conversions

## Project Structure

```
src/
├── main.zig                 # Entry point
├── root.zig                 # Library root
├── classfile/              # Class file parsing
│   ├── parser.zig
│   ├── constant_pool.zig
│   └── ...
├── engine/                 # Bytecode interpreter
│   ├── interpreter.zig
│   └── opcode.zig
└── runtime/                # Runtime data structures
    ├── frame.zig
    ├── operand_stack.zig
    ├── local_vars.zig
    └── value.zig
```

## Development

### Creating Tests

Tests are written using Zig's built-in testing framework. Add new test files with `_test.zig` suffix and import them in `src/root.zig`:

```zig
test {
    _ = @import("path/to/your_test.zig");
}
```

### Debugging

The Frame structure includes a `dump()` function for debugging:

```zig
frame.dump();  // Prints current frame state
```

This displays:
- Program Counter (PC)
- Local variables with their values and types
- Operand stack state

## Makefile Targets

- `make build-zjvm` - Build the ZJVM executable
- `make test` - Run all unit tests
- `make run` - Build and run ZJVM
- `make clean-zjvm` - Clean build artifacts
- `make build-sample` - Compile sample Java class

## Requirements

- Zig 0.15.2 or later
- JDK (for compiling Java samples)

## License

See LICENSE file for details.
