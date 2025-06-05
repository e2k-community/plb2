JAVAC=/usr/lib/jvm/java-8-openjdk-e2k/bin/javac
EXE=nqueen.class matmul.class sudoku.class bedcov.class

all:$(EXE)

nqueen.class:nqueen.java
	$(JAVAC) $<

matmul.class:matmul.java
	$(JAVAC) $<

sudoku.class:sudoku.java
	$(JAVAC) $<

bedcov.class:bedcov.java
	$(JAVAC) $<

clean:
	rm -f $(EXE) *.class
