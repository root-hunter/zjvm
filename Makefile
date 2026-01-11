build-zjvm:
	@echo "Building ZJVM..."
	zig build
	@echo "ZJVM build complete."

test:
	@echo "Running ZJVM tests..."
	zig build test
	@echo "All tests passed!"

clean-zjvm:
	@echo "Cleaning ZJVM build artifacts..."
	zig clean
	@echo "ZJVM clean complete."

run: build-zjvm
	@echo "Running ZJVM..."
	./zig-out/bin/zjvm

build-sample:
	@echo "Building sample Java class file..."
	javac samples/TestSuite1.java
	@echo "Sample Java class file build complete."