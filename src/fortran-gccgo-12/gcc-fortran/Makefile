FC=/opt/lcc-1.28/gcc-9.0.0-A.XXX.e2k-v5.5.10/bin/gfortran
FFLAGS=-O3
EXE=nqueen matmul sudoku

all:$(EXE)

matmul:matmul.F90
	$(FC) $(FFLAGS) -o $@ $<

nqueen:nqueen.F90
	$(FC) $(FFLAGS) -o $@ $<

sudoku:sudoku.F90
	$(FC) $(FFLAGS) -o $@ $<

clean:
	rm -f $(EXE) *.mod
