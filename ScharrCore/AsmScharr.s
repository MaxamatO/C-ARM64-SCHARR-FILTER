// Assembler program to print "Hello World!"
// to stdout.
//
// X0-X2 - parameters to linux function services
// X16 - linux function number
//
.global _hello             // Provide program starting address to linker
.p2align 3 // Feedback from Peter

// Setup the parameters to print hello world
// and then call Linux to do it.

_hello: mov X0, #1     // 1 = StdOut
adr X1, helloworld // string to print
mov X2, #13     // length of our string
mov X16, #4     // MacOS write system call
svc 0     // Call linux to output the string

ret

helloworld:      .ascii  "Hello World!\n"
