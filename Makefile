build-zjvm:
	@echo "Building ZJVM..."
	zig build
	@echo "ZJVM build complete."

clean-zjvm:
	@echo "Cleaning ZJVM build artifacts..."
	zig clean
	@echo "ZJVM clean complete."

run: build-zjvm
	@echo "Running ZJVM..."
	./zig-out/bin/zjvm