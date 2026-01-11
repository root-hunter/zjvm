# ZJVM - Java Virtual Machine in Zig

A Java Virtual Machine (JVM) implementation written in Zig, featuring a complete bytecode interpreter and runtime environment.

## 🚀 Features

- **Complete Class File Parser**: Reads and interprets compiled Java `.class` files
- **Bytecode Interpreter**: Direct execution of Java bytecode
- **Runtime Environment**: 
  - Operand stack with overflow/underflow handling
  - Typed local variables
  - Frame stack for method calls
  - Primitive type support (Int, Float, Long, Double, Reference)
- **Opcode Support**: 
  - Arithmetic operations (iadd, isub, imul, idiv, irem)
  - Local variable load/store (iload, istore)
  - Constants (iconst, bipush, sipush)
  - Control flow (goto, if_icmpge, if_icmple)
  - Method calls (invokestatic)
  - Returns (return, ireturn)
- **Debugging Tools**: Frame dump for runtime inspection
- **Complete Test Suite**: Unit tests for all critical components

## 📋 Requirements

- **Zig** 0.15.2 or higher
- **JDK** 11+ (for compiling Java samples)
- **Make** (optional, for convenience)

## 🔨 Building

### Using Make
```bash
make build-zjvm
```

### Using Zig directly
```bash
zig build
```

The executable will be generated in `zig-out/bin/zjvm`.

## ▶️ Running

### Run the sample program
```bash
make build-samples
make run ARGS=samples/TestSuite1.class
```

This will compile and execute `samples/TestSuite1.class`.

### Run a specific .class file

Edit `src/main.zig` to specify the file:
```zig
var file = try std.fs.cwd().openFile("samples/YourFile.class", .{ .mode = .read_only });
```

## 🧪 Testing

### Run all tests
```bash
make test
```

### Using Zig directly
```bash
zig build test
```

### Test Suite

The project includes comprehensive tests for:

| Module | File | Coverage |
|--------|------|----------|
| **Value Types** | `src/runtime/value_test.zig` | Creation and access of Int, Float, Long, Double, Reference types |
| **Operand Stack** | `src/runtime/operand_stack_test.zig` | Push/pop, overflow, underflow, capacity, mixed types |
| **Local Variables** | `src/runtime/local_vars_test.zig` | Set/get, initialization, boundary conditions |
| **Frame** | `src/runtime/frame_test.zig` | Initialization, PC management, code reference |
| **Opcodes** | `src/engine/opcode_test.zig` | Enum values, conversions, bytecode mapping |

## 📁 Project Structure

```
zjvm/
├── src/
│   ├── main.zig                    # Application entry point
│   ├── root.zig                    # Library module root
│   │
│   ├── classfile/                  # Java .class file parsing
│   │   ├── parser.zig              # Main parser
│   │   ├── constant_pool.zig       # Constant pool management
│   │   ├── methods.zig             # Method parsing
│   │   ├── fields.zig              # Field parsing
│   │   ├── attributes.zig          # Attribute parsing
│   │   ├── code.zig                # Code attribute
│   │   ├── access_flags.zig        # Access flags
│   │   ├── types.zig               # Java types
│   │   └── utils.zig               # Utilities (Cursor, etc.)
│   │
│   ├── engine/                     # Execution engine
│   │   ├── interpreter.zig         # Bytecode interpreter
│   │   ├── vm.zig                  # Virtual Machine (frame stack)
│   │   └── opcode.zig              # Opcode definitions
│   │
│   └── runtime/                    # Runtime data structures
│       ├── frame.zig               # Execution frame
│       ├── operand_stack.zig       # Operand stack
│       ├── local_vars.zig          # Local variables
│       ├── value.zig               # Typed Value union
│       ├── jvm_stack.zig           # Frame stack
│       └── *_test.zig              # Unit tests
│
├── samples/                        # Sample Java programs
│   ├── TestSuite1.java             # Simple arithmetic operations
│   ├── TestSuite2.java             # Method calls
│   ├── TestSuite3-7.java           # Various tests
│   └── *.class                     # Compiled files
│
├── build.zig                       # Build configuration
├── build.zig.zon                   # Dependencies
├── Makefile                        # Build automation
├── LICENSE
└── README.md
```

## 🎯 Usage Examples

### Example 1: Arithmetic Operations

**TestSuite1.java:**
```java
public class TestSuite1 {
    public static void main(String[] args) {
        var s = 32 + 1;        // bipush, iadd
        var g = 100;           // bipush
        var l = 50 + s;        // bipush, iload, iadd
        var s2 = 20 + l + g;   // multiple calculations
    }
}
```

**Compilation and Execution:**
```bash
javac samples/TestSuite1.java
./zig-out/bin/zjvm  # Make sure main.zig points to TestSuite1.class
```

### Example 2: With Debugging

Enable frame dump in the interpreter to see step-by-step execution:

**Example output:**
```
=== Frame Dump ===
PC: 10
Code Length: 46
Local Variables (7):
  [0] = 0 (Int)
  [1] = 33 (Int)
  [2] = 100 (Int)
  [3] = 83 (Int)
  [4] = 203 (Int)
  [5] = 403 (Int)
  [6] = 799 (Int)
Operand Stack:
  Size: 0/2
==================
```

## 🛠️ Development

### Adding New Tests

1. Create a `*_test.zig` file in the appropriate module
2. Write tests using `std.testing`
3. Import the file in `src/root.zig`:

```zig
test {
    _ = @import("path/to/your_test.zig");
}
```

### Adding New Opcodes

1. Add the opcode in `src/engine/opcode.zig`:
```zig
pub const OpcodeEnum = enum(u8) {
    YourOpcode = 0xXX,
    // ...
};
```

2. Implement execution in `src/engine/interpreter.zig`:
```zig
OpcodeEnum.YourOpcode => {
    // Implementation
},
```

3. Add tests in `src/engine/opcode_test.zig`

### Debugging the Interpreter

The `Frame` structure includes `dump()` for detailed debugging:

```zig
frame.dump();  // Prints complete frame state
```

Displays:
- **Program Counter (PC)**: Current position in bytecode
- **Local Variables**: All variables with type and value
- **Operand Stack**: Current size and capacity

## 📝 Makefile Targets

| Target | Description |
|--------|-------------|
| `make build-zjvm` | Build the ZJVM executable |
| `make test` | Run all unit tests |
| `make run` | Build and run ZJVM |
| `make clean-zjvm` | Clean build artifacts |
| `make build-sample` | Compile Java sample files |

## 🔍 Supported Opcodes

### Constants
- `nop` (0x00) - No operation
- `iconst_m1` - `iconst_5` (0x02-0x08) - Push integer constant
- `bipush` (0x10) - Push byte as int
- `sipush` (0x11) - Push short as int

### Load/Store
- `iload`, `iload_0-3` (0x15, 0x1A-0x1D) - Load int from local
- `istore`, `istore_0-3` (0x36, 0x3B-0x3E) - Store int to local

### Arithmetic
- `iadd` (0x60) - Integer addition
- `isub` (0x64) - Integer subtraction
- `imul` (0x68) - Integer multiplication
- `idiv` (0x6C) - Integer division
- `irem` (0x70) - Integer remainder
- `iinc` (0x84) - Increment local variable

### Control Flow
- `if_icmpge` (0xA2) - Branch if >=
- `if_icmple` (0xA4) - Branch if <=
- `goto` (0xA7) - Unconditional branch

### Methods
- `invokestatic` (0xB8) - Invoke static method
- `return` (0xB1) - Return void
- `ireturn` (0xAC) - Return int

## 🐛 Troubleshooting

### Error: "integer does not fit in destination type"
This was a bug fixed in the handling of negative branch offsets. Make sure you have the latest version of the code.

### Error: "switch on corrupt value"
Local variables were not initialized. This has been fixed by initializing all variables to `Int: 0`.

### Class file not found
Make sure the path in `src/main.zig` points correctly to the `.class` file:
```zig
var file = try std.fs.cwd().openFile("samples/FileName.class", .{ .mode = .read_only });
```

## 🚧 Roadmap

- [ ] Support for more types (long, float, double)
- [ ] Virtual method calls implementation
- [ ] Garbage collection
- [ ] Array support
- [ ] Exception handling support
- [ ] Performance optimizations
- [ ] JIT compilation
- [ ] Java standard library support

## 📄 License

See the `LICENSE` file for details.

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Make sure all tests pass with `make test` before opening a PR.

---

**Note**: This is an educational project to understand how the JVM works. It is not intended for production use.
