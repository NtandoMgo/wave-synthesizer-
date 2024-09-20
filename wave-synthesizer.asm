.data
    outputFile: .space 100
.text 
main:
# get file path
    li $v0, 8
    la $a0, outputFile
    syscall
# get tone frequency
    li $v0, 5
    syscall
    move $s1, $v0               #tone

# get sample grequencey
    li $v0, 5
    syscall
    move $s2, $v0               #freq

# get length of the tone
    li $v0, 5
    syscall
    move $s2, $v0               #len

    jal remove_newline

    #######################
    # $s1 = tone frequency
    # $s2 = sample frequencey
    # $s3 = length of the tone
    #######################

    # calc size of heap
    mul $t0, $s2, $s3       #sample fre * length
    addi $t0, $t0, 44       #add header - 44 bytes
    move $t8, $t0           #copy total size

    # allocate heap memory
    li $v0, 9
    move $a0, $t0
    syscall
    move $s0, $v0

    #######################
    # $s0 = heap address
    # $s1 = tone frequency
    # $s2 = sample frequencey
    # $t8 = total file size
    # $s3 = length of the tone
    #######################

    # write header to heap as zeros
    move $t0, $s0           #temporal pointer to store zeros
    li $t1, 44

write_header:
    sb $zero, 0($t0)
    addi $t0, $t0, 1
    sub $t1, $t1, 1
    bnez $t1, write_header

# Somple calc to for writing low and high
    li $s6, 32767       #high value (0x7fff in hexadecimal)
    li $s7, -32765      #low value (0x8000 in hexadecimal)

# num of times each either high/low apears in a row
    mul $t0, $s1, 2     # tone * 2
    div $s2, $t0
    mflo $s4            # num of times each either high/low apears in a row

    mul $s5, $s2, $s3   # or $0 minize 44

    #######################
    # $s0 = heap address
    # $s1 = tone frequency
    # $s2 = sample frequencey
    # $t8 = total file size
    # $s3 = length of the tone

    # $s4 = num of times each either high/low apears in a row
    # $s5 = number of bytes after header
    #######################

# write high and low to header
    

    move $t3, $s3       #how many times to reapeat outer loop

outer_loop:
    beqz $t3, write_to_outFile
    move $t0, $s0       #heap adress

inner_loop:
    move $t1, $s4       #num of times to write high
    move $t1, $s4       #num of times to write low
    sub $t0, $t0, 1    # satrt when address is 43
    write_high:
        addi $t0, $t0, 1        #now start storing @44th
        sb $s6, 0($t0)
        sub $t1, $t1, 1
        bnez $t1, write_high
    
    write_low:
        addi $t0, $t0, 1    # start where last high stored + 1
        sb  $s7, 0($t0)
        sub $t2, $t2, 1
        bnez $t2, write_low

    sub $t3, $t3, 1         # decrement for outer loop
    j outer_loop

# write to output file, first open/create it
write_to_outFile:
    open_outFile:
        li $v0, 13
        la $a0, outputFile
        li $a1, 0x41
        li $a2, 0x1ff
        syscall
        move $a0, $v0       #output file descriptor

#write to output file
    li $v0, 15
    move $a1, $s0
    move $a2, $t8
    syscall

    li $v0, 10
    syscall
    

remove_newline:
    la $t0, outputFile

find_newline:
    lb $t1, 0($t0)

    beqz $t1, removed

    beq $t1, 0x0A remove_it
    addi $t0, $t0, 1
    j find_newline

remove_it:
    sb $zero, 0($t0)

removed:
    jr $ra