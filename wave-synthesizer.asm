.data
    outputFile: .space 100      # Space for output file path

.text 
main:
    # Get file path from the user
    li $v0, 8
    la $a0, outputFile
    syscall

    # Get tone frequency
    li $v0, 5
    syscall
    move $s1, $v0               # Tone frequency

    # Get sample frequency
    li $v0, 5
    syscall
    move $s2, $v0               # Sample frequency

    # Get length of the tone (in seconds)
    li $v0, 5
    syscall
    move $s3, $v0               # Tone length

    jal remove_newline           # Remove newline from file path

    #######################
    # $s1 = tone frequency
    # $s2 = sample frequency
    # $s3 = length of the tone
    #######################

    # Calculate total size (sample freq * length + 44 bytes for header)
    mul $t0, $s2, $s3           # sample freq * length
    addi $t0, $t0, 44           # Add header size (44 bytes)
    move $t8, $t0               # Store total file size in $t8

    # Allocate heap memory for the entire file (including header)
    li $v0, 9
    move $a0, $t0
    syscall
    move $s0, $v0               # Address of allocated heap memory

    #######################
    # $s0 = heap address
    # $s1 = tone frequency
    # $s2 = sample frequency
    # $t8 = total file size
    # $s3 = length of the tone
    #######################

    # Write zeros for the header (44 bytes)
    move $t0, $s0               # Pointer to heap (for writing zeros)
    li $t1, 44                  # Header size (44 bytes)

write_header:
    sb $zero, 0($t0)            # Store 0 at current address
    addi $t0, $t0, 1            # Move to the next byte
    sub $t1, $t1, 1             # Decrement byte counter
    bnez $t1, write_header      # Repeat until 44 bytes are written

    # Sample calculation for high/low values (16-bit)
    li $s6, 32767               # High value (0x7FFF)
    li $s7, -32768              # Low value (0x8000)

    # Calculate how many times each high/low appears in a row
    mul $t0, $s1, 2             # Tone * 2 (for high and low cycle)
    div $s2, $t0
    mflo $s4                    # Number of times high/low appear in a row

    # Calculate the number of data bytes after header
    mul $s5, $s2, $s3           # Sample frequency * length

    #######################
    # $s0 = heap address
    # $s1 = tone frequency
    # $s2 = sample frequency
    # $t8 = total file size
    # $s3 = length of the tone
    # $s4 = num of times each high/low appears in a row
    # $s5 = number of bytes after header
    #######################

    # Initialize the outer loop counter for writing audio data
    move $t3, $s5               # Number of bytes after header

outer_loop:
    beqz $t3, write_to_outFile  # If $t3 is 0, done writing, go to file output
    move $t0, $s0               
    addi $t0, $t0, 44           # Start from heap address (after header)

    # Write high and low values to heap
    move $t1, $s4               # Set counter for high values
    move $t2, $s4               # Set counter for low values

write_high:
    beqz $t1, write_low         # If done writing high values, go to low
    # Store high value in little-endian format (least significant byte first)
    andi $t4, $s6, 0xFF         # Extract lower byte
    sb $t4, 0($t0)
    addi $t0, $t0, 1
    sra $t4, $s6, 8             # Extract higher byte
    sb $t4, 0($t0)
    addi $t0, $t0, 1
    sub $t1, $t1, 1             # Decrement counter
    sub $t3, $t3, 2             # Decrease outer loop counter by 2 bytes
    j write_high                # Repeat for remaining high values

write_low:
    beqz $t2, outer_loop        # If done writing low values, loop back
    # Store low value in little-endian format (least significant byte first)
    andi $t4, $s7, 0xFF         # Extract lower byte
    sb $t4, 0($t0)
    addi $t0, $t0, 1
    sra $t4, $s7, 8             # Extract higher byte
    sb $t4, 0($t0)
    addi $t0, $t0, 1
    sub $t2, $t2, 1             # Decrement counter
    sub $t3, $t3, 2             # Decrease outer loop counter by 2 bytes
    j write_low                 # Repeat for remaining low values

# Write buffer to output file
write_to_outFile:
    # Open the output file
    li $v0, 13                  # sys_open
    la $a0, outputFile           # File name
    li $a1, 0x41                # Flags (O_WRONLY | O_CREAT)
    li $a2, 0x1FF               # Mode (rw-rw-rw-)
    syscall
    move $a0, $v0               # Store file descriptor in $a0

    # Write the buffer to the file
    li $v0, 15                  # sys_write
    move $a1, $s0               # Buffer pointer (starting from heap)
    move $a2, $t8               # Total size (header + data)
    syscall

    # Exit program
    li $v0, 10
    syscall

# Subroutine to remove newline character from the file path
remove_newline:
    la $t0, outputFile           # Load the address of outputFile

find_newline:
    lb $t1, 0($t0)               # Load the current byte
    beqz $t1, removed            # If it's a null byte, done
    beq $t1, 0x0A, remove_it     # If it's a newline, remove it
    addi $t0, $t0, 1             # Move to the next byte
    j find_newline

remove_it:
    sb $zero, 0($t0)             # Replace newline with null byte
    jr $ra

removed:
    jr $ra
