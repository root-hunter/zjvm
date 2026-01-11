RELEASE_VERSION = v0.1.7
RELEASE_MODE ?= safe

build-samples:
	@echo "Building sample Java class files..."
	javac samples/*.java
	@echo "Sample Java class files build complete."

build-zjvm:
	@echo "Building ZJVM..."
	zig build
	@echo "ZJVM build complete."

build-zjvm-release:
	@echo "Building ZJVM in release mode..."
	zig build --release=$(RELEASE_MODE)
	@echo "ZJVM release build complete."

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
	./zig-out/bin/zjvm $(ARGS)
	@echo "Finished"

run-release: build-zjvm-release
	@echo "Running ZJVM in release mode..."
	./zig-out/bin/zjvm $(ARGS)
	@echo "Finished"

publish-release: build-zjvm test
	@echo "Pushing ZJVM to remote repository..."
	git add .
	git tag -a "$(RELEASE_VERSION)" -m "Release version $(RELEASE_VERSION)"
	git commit -m "Update ZJVM to version $(RELEASE_VERSION)"
	git push origin ${RELEASE_VERSION}
	@echo "ZJVM pushed to remote repository."