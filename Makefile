build-sample:
	@echo "Building sample Java class files..."
	javac samples/*.java
	@echo "Sample Java class files build complete."

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

push: build-zjvm test
	@echo "Pushing ZJVM to remote repository..."
	git add .
	git commit -m "Update ZJVM"
	git push origin main
	@echo "ZJVM pushed to remote repository."