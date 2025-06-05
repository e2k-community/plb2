CC=/opt/lcc-1.27/gcc-9.0.0-A.XXX.e2k-v5.5.10/bin/gcc
CXX=/opt/lcc-1.27/gcc-9.0.0-A.XXX.e2k-v5.5.10/bin/g++

CFLAGS=-O3 -fwrapv -flto
EXE=sudoku nqueen matmul bedcov

all:$(EXE)

matmul:matmul.c
	$(CC) $(CFLAGS) -o $@ $<

sudoku:sudoku.c
	$(CC) $(CFLAGS) -o $@ $<

nqueen:nqueen.c
	$(CC) $(CFLAGS) -o $@ $<

bedcov:bedcov.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(EXE)
