build-sample:
	@echo "Building sample Java class file..."
	javac samples/TestSuite1.java
	javac samples/TestSuite2.java
	javac samples/TestSuite3.java
	@echo "Sample Java class file build complete."

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