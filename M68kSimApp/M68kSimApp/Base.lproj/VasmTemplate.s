

	public start	;Make the entry point public
	org $2000		;Place the origin at $2000


start:
	;  YOUR CODE HERE
	;Instructions must be indented by at least one space,
	;otherwise the assembler will misinterpret them as labels.
	
	;Then, to terminate the program, spin forever. You can set
	;a breakpoint to the next instruction to be notified of
	;the program's termination.
forever:
	bra forever


