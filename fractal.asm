.data 0x10000000 ##!
  display: 	.space 65536
  		.align 2
  redPrompt:	.asciiz "Enter a RED color value for the background (integer in range 0-255):\n"
  greenPrompt:	.asciiz "Enter a GREEN color value for the background (integer in range 0-255):\n"
  bluePrompt:	.asciiz "Enter a BLUE color value for the background (integer in range 0-255):\n"
  redSquarePrompt:	.asciiz "Enter a RED color value for the squares (integer in range 0-255):\n"
  greenSquarePrompt:	.asciiz "Enter a GREEN color value for the squares (integer in range 0-255):\n"
  blueSquarePrompt:	.asciiz "Enter a BLUE color value for the squares (integer in range 0-255):\n"
  shiftPrompt:	.asciiz "Enter a Value to shift the square color by (0-31):\n"
  sizePrompt:	.asciiz "Enter the width in pixels of the first square (Integer power of 2 in the set {1, 2, 4, 8, 16, 32, 64):\n"
  
.text 0x00400000 ##!
main:

	addi	$v0, $0, 4  			# system call 4 is for printing a string
	la 	$a0, redPrompt 		# address of columnPrompt is in $a0
	syscall           			# print the string
	# read in the R value
	addi	$v0, $0, 5			# system call 5 is for reading an integer
	syscall 				# integer value read is in $v0
 	add	$s0, $0, $v0			# copy N into $s0
 	
 	addi	$v0, $0, 4  			# system call 4 is for printing a string
	la 	$a0, greenPrompt 		# address of columnPrompt is in $a0
	syscall           			# print the string
	# read in the G value
	addi	$v0, $0, 5			# system call 5 is for reading an integer
	syscall 				# integer value read is in $v0
 	add	$s1, $0, $v0			# copy N into $s1
 	
 	addi	$v0, $0, 4  			# system call 4 is for printing a string
	la 	$a0, bluePrompt 		# address of columnPrompt is in $a0
	syscall           			# print the string
	# read in the B value
	addi	$v0, $0, 5			# system call 5 is for reading an integer
	syscall 				# integer value read is in $v0
 	add	$s2, $0, $v0			# copy N into $s2
 	
	sll $s0, $s0, 16
	sll $s1, $s1, 8
	or $t1, $s0, $s1
	or $t1, $t1, $s2
	li $s5, 16384
	
	j drawDisplay
	
# Exit from the program
exit:
  ori $v0, $0, 10       		# system call code 10 for exit
  syscall               		# exit the program
	
drawDisplay:
	mul $t3, $t0, 4
	sw $t1, display($t3)
	addi $t0, $t0, 1
	bne $t0, $s5, drawDisplay
	
	
readSquareColors:
	addi	$v0, $0, 4  	
	la 	$a0, redSquarePrompt 
	syscall           	
	# read in the R value
	addi	$v0, $0, 5	
	syscall 		
 	add	$s0, $0, $v0	
 	
 	
 	addi	$v0, $0, 4  			
	la 	$a0, greenSquarePrompt 		
	syscall           			
	# read in the G value
	addi	$v0, $0, 5			
	syscall 				
 	add	$s1, $0, $v0			
 	
 	
 	addi	$v0, $0, 4  		
	la 	$a0, blueSquarePrompt 	
	syscall           		
	# read in the B value
	addi	$v0, $0, 5		
	syscall 			
 	add	$s2, $0, $v0	
 	
	sll $s0, $s0, 16
	sll $s1, $s1, 8
	or $t1, $s0, $s1
	or $s7, $t1, $s2
	
readShift:
	addi	$v0, $0, 4  			
	la 	$a0, shiftPrompt 		
	syscall           			
	# read in the shift value
	addi	$v0, $0, 5			
	syscall 				
 	add	$s6, $0, $v0
 	add	$t0, $0, $s6
 	sll	$s6, $s6, 8
 	or	$s6, $s6, $t0
 	sll	$s6, $s6, 8
 	or	$s6, $s6, $t0			
	
	
readSize:
	addi	$v0, $0, 4  	
	la 	$a0, sizePrompt
	syscall           	
	addi	$v0, $0, 5	
	syscall 		
 	add	$s0, $0, $v0	
 	
 	li $s1, 128
 	sub $s1, $s1, $s0
 	div $s1, $s1, 2
 	add $s2, $s1, $0 # s2 = s1 on first square
 	add $s3, $v0, 4
 	
 	beq $s0, 1, initialWidthOne# EDGE CASE
	
	jal drawSquare
	j exit
	
 drawSquare:	# Do not change this label
 	
 	beq $s0, 1, restoreReg
 
 	# registers
 	# s0: width, 
 	# s1: starting x cord, 
 	# s2: starting y cord
 	# s3: Called from
 	
 	# s5: 16384 const number of pixels in the grid
 	# s6: shiftAmount
 	# s7: pixelColor (Not changed across calls so not saved)
 
 	# save sequence
	addi $sp, $sp, -8
    	sw $ra, 4($sp) 	# Save $ra
    	sw $fp, 0($sp) 	# Save $fp
    	addi $fp, $sp, 4 	# Set $fp
    	
    	addi $sp, $sp, -16 	# room for $s0-$s1
    	sw $s0, 12($sp) 		# Save $s0
    	sw $s1, 8($sp) 		# Save $s1
    	sw $s2, 4($sp)		# Save $s2
    	sw $s3, 0($sp)		# Save $s3
	
	# in leaf case jump straight to restoreReg
	
branchCase: 	# width >= 4
		# t0 = counter, #t1 = t0 * 4
	
	ble $s7, $s6, colorUnderFlow
	sub $s7, $s7, $s6
	j colorDone
	
colorUnderFlow:
	add $s7, $s7, $s6
	add $s7, $s7, $s6
	add $s7, $s7, $s6
	add $s7, $s7, $s6
	add $s7, $s7, $s6
	add $s7, $s7, $s6
	add $s7, $s7, $s6
	add $s7, $s7, $s6
colorDone:
	sll $s7, $s7, 8
	srl $s7, $s7, 8
	
	# t2 = lowerbound
	add $t2, $s1, $0
	# t3 = upperbound
	add $t3, $t2, $s0
	# t4 = lowerbound * 128
	mul $t4, $s2, 128
	# t5 = upperbound * 128
	mul $t5, $s0, 128
	add $t5, $t5, $t4
	
	add $t0, $t4, $0
	add $t1, $t4, $0
	
	
	printLoop:
		sll $t1, $t0, 2
		
		#vert condition
		blt $t0, $t4, dontColor
		bgt $t0, $t5, dontColor
		
		# horz condition $t6 = modulo
		div $t6, $t0, 128 
		mfhi $t6
		blt $t6, $t2, dontColor
		bge $t6, $t3, dontColor
		
		color:
			sw $s7, display($t1)
		dontColor:
			addi $t0, $t0, 1
			bne $t0, $t5, printLoop
		
		# recursive sequence
	# jal drawSqr top left x - w/4, y - w/4
	beq $s3, 3, skip0
	
	div $s0, $s0, 2
	div $t1, $s0, 2
	sub $s1, $s1, $t1
	sub $s2, $s2, $t1
	
	addi $s3, $0, 0
	jal drawSquare
	
	lw $s0, -8($fp) 	# restore $s0
    	lw $s1, -12($fp) 	# restore $s1
    	lw $s2, -16($fp)	# restore $s2
    	lw $s3, -20($fp)	# restore $s3
skip0:
	
	
	# jal drawSqr top right x + 3w/4, y - w/4
	beq $s3, 2, skip1
	
	div $s0, $s0, 2
	div $t1, $s0, 2
	mul $t2, $t1, 3
	add $s1, $s1, $t2
	sub $s2, $s2, $t1
	
	addi $s3, $0, 1
	jal drawSquare
	
	lw $s0, -8($fp) 	# restore $s0
    	lw $s1, -12($fp) 	# restore $s1
    	lw $s2, -16($fp)	# restore $s2
    	lw $s3, -20($fp)	# restore $s3
skip1:
	

	# jal drawSqr bottom left: x - w/4, y + 3w/4
	beq $s3, 1, skip2
	div $s0, $s0, 2
	div $t1, $s0, 2
	mul $t2, $t1, 3
	sub $s1, $s1, $t1
	add $s2, $s2, $t2
	
	addi $s3, $0, 2
	jal drawSquare
	
	lw $s0, -8($fp) 	# restore $s0
    	lw $s1, -12($fp) 	# restore $s1
    	lw $s2, -16($fp)	# restore $s2
    	lw $s3, -20($fp)	# restore $s3
skip2:
	
	
	# jal drawSqr bottom right: x + 3w/4, y + 3w/4
	beq $s3, 0, skip3
	
	div $s0, $s0, 2
	div $t1, $s0, 2
	mul $t2, $t1, 3
	add $s1, $s1, $t2
	add $s2, $s2, $t2
	
	addi $s3, $0, 3
	jal drawSquare
	
	lw $s0, -8($fp) 	# restore $s0
    	lw $s1, -12($fp) 	# restore $s1
    	lw $s2, -16($fp)	# restore $s2
    	lw $s3, -20($fp)	# restore $s3
skip3:
	

restoreReg:
	# restore sequence
	lw $s0, -8($fp) 	# restore $s0
    	lw $s1, -12($fp) 	# restore $s1
    	lw $s2, -16($fp)	# restore $s2
    	lw $s3, -20($fp)	# restore $s3
	
	addi $sp, $fp, 4 	# Restore $sp
    	lw $ra, 0($fp) 		# Restore $ra
   	lw $fp, -4($fp) 	# Restore $fp

	jr $ra 
	
initialWidthOne: # edge cases when initial width is one, program will try to recall a value that has not been saved
	li $t1, 32508 # location of pixel at 63, 63
	sw $s7, display($t1)
	j exit
