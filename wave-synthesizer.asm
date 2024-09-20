.data
        filename:        .space 100        # Buffer for file path input
        header:          .space 44         # Buffer for WAVE header
        high_value:      .half 32767       # Positive amplitude
        low_value:       .half -32768      # Negative amplitude
 
.text
.globl main
 
main:
  
    li $v0, 8                   # Input string syscall
    la $a0, filename             # Pointer to buffer
    li $a1, 100                  # Max size for input
    syscall
 
    # Strip newline character from input
    la $s0, filename
loop_filename:
        lb $s1, 0($s0)
        beq $s1, 0xA, remove_newline   # If newline, remove it
        beq $s1, 0, filename_done      # Stop at null terminator
        addi $s0, $s0, 1
        b loop_filename
remove_newline:
        sb $zero, 0($s0)
filename_done:
 
    # Open file with write permissions
    li $v0, 13                  
    la $a0, filename             # File path pointer
    li $a1, 577                  # Flags for writing and creating
    li $a2, 420                  # File mode
    syscall
    move $s0, $v0                # Store file descriptor
 
    # Write WAVE header
    li $v0, 15                  
    move $a0, $s0               # File descriptor
    la $a1, header              # Pointer to header
    li $a2, 44                  # Size of header
    syscall
 
    li $v0, 5                   # Input frequency (tone)
    syscall
    move $s1, $v0               # Store tone frequency
 
    li $v0, 5                   # Input sample rate
    syscall
    move $s2, $v0               # Store sample frequency
 
    li $v0, 5                   # Input tone duration
    syscall
    move $s3, $v0               # Store tone duration
 
    # Calculate total number of samples
    mul $s4, $s2, $s3
 
    # Calculate samples per period
    div $s2, $s1                # Divide sample rate by tone frequency
    mflo $s5                    # Get quotient
 
    # Begin wave generation
    li $s6, 32767               # High value
    li $s7, -32768              # Low value
 
    move $s8, $s4               # Total samples counter
 
write_wave_loop:
    blez $s8, finish            # End if no more samples
 
    # Write positive half of wave
    move $t0, $s5               # Half of period
    sra $t0, $t0, 1             # Divide by 2
 
write_high:
    blez $t0, write_low         # If half-period is done, switch to low
    li $v0, 15                  # Write syscall
    move $a0, $s0               # File descriptor
    la $a1, high_value          # Positive value
    li $a2, 2                   # Write 16-bit sample
    syscall
 
    sub $t0, $t0, 1             # Decrease half-period counter
    sub $s8, $s8, 1             # Decrease total sample counter
    b write_high
 
write_low:
    move $t0, $s5               # Half of period
    sra $t0, $t0, 1             # Divide by 2
 
write_low_loop:
    blez $t0, write_wave_loop   # If half-period done, go back
    li $v0, 15                  # Write syscall
    move $a0, $s0               # File descriptor
    la $a1, low_value           # Negative value
    li $a2, 2                   # Write 16-bit sample
    syscall
 
    sub $t0, $t0, 1             # Decrease half-period counter
    sub $s8, $s8, 1             # Decrease total sample counter
    b write_low_loop
 
finish:
    # Close the file
    li $v0, 16                  # Close syscall
    move $a0, $s0               # File descriptor
    syscall
 
    # Exit program
    li $v0, 10                  # Exit syscall
    syscall
