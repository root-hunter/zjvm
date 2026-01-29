# Extract version from build.zig.zon
RELEASE_VERSION = $(shell grep -oP '\.version = "\K[^"]+' build.zig.zon)
RELEASE_MODE ?= safe

build-debug:
	@echo "Building ZJVM in debug mode with LLVM backend..."
	rm -rf zig-out/zjvm-debug
	zig build-exe -fllvm src/main.zig -femit-bin=zig-out/zjvm-debug -Doptimize=Debug
	@echo "ZJVM debug build complete."

build-examples:
	@echo "Building Java test class files..."
	for file in examples/**/*.java ; do \
		echo "Compiling $$file" ; \
		javac $$file ; \
	done
	@echo "Java test class files build complete."

build:
	@echo "Building ZJVM..."
	zig build -Doptimize=Debug
	@echo "ZJVM build complete."

build-release:
	@echo "Building ZJVM in release mode..."
	zig build --release=$(RELEASE_MODE)
	@echo "ZJVM release build complete."

test:
	@echo "Running ZJVM tests..."
	zig build test
	@echo "All tests passed!"

clean:
	@echo "Cleaning ZJVM build artifacts..."
	rm -rf zig-out
	@echo "ZJVM clean complete."

run: build
	@echo "Running ZJVM..."
	./zig-out/bin/zjvm $(ARGS)
	@echo "Finished"

run-release: build-release
	@echo "Running ZJVM in release mode..."
	./zig-out/bin/zjvm $(ARGS)
	@echo "Finished"

publish-release: build-release test
	@echo "Pushing ZJVM to remote repository..."
	git add .
	git tag -a "v$(RELEASE_VERSION)" -m "Release version v$(RELEASE_VERSION)"
	git commit -m "Update ZJVM to version v$(RELEASE_VERSION)"
	git push origin v$(RELEASE_VERSION)
	git push origin main
	@echo "ZJVM pushed to remote repository."

print-version:
	@echo "ZJVM Version: $(RELEASE_VERSION)"

.PHONY: build-samples build build-release test clean run run-release publish-release print-version