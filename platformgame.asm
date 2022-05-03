##################################################################### 
# 
# In order to run this game, you need to apply the following to the bitmap display:
#
# Bitmap Display Configuration: 
# - Unit width in pixels: 8  
# - Unit height in pixels: 8
# - Display width in pixels: 256 
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp) 
##################################################################### 


.data
CHAR_POS:	.word	3388
PLATFORM_ARRAY:	.word	3900, 3160, 2216, 1360, 544
MUSHROOM_ARRAY:	.word	2904, 1960, 1104, -1, -1, -1, 0, 0, 0
JUMP_HEIGHT:	.word	8
SLEEP_TIME:	.word	250
SCORE:		.word	0

.text
.globl main

.eqv BASE_ADDRESS	0x10008000
.eqv PEACH		0xffe5b4
.eqv BLUE		0x0000ff
.eqv BLACK		0x000000
.eqv BROWN		0x964B00
.eqv YELLOW		0xffff00
.eqv GREEN		0x00ff00
.eqv BLOOD_ORANGE 	0xd1001c
.eqv RED		0xff0000
.eqv PURPLE		0x6a0dad
.eqv PINK		0xffc0cb
.eqv WHITE		0xffffff

main:

START:
 	# Initialize the game
 	
 	# Initialize the score
 	jal INITIALIZE_SCORE
 	
 START_WITH_SCORE:	
 	# Initialize the array
 	jal INITIALIZE_ARRAY
 	
  	# Clear the screen
 	jal CLEAR_SCREEN

 	# Create the player
	jal CREATE_CHAR
	
	# Create the platforms
	li $a0, BROWN # set the first argument to be the colour BROWN
	li $a1, YELLOW # set the second argument to be the colour YELLOW
	jal CREATE_PLATFORM
	
	# Create the mushrooms
	jal CREATE_MUSHROOMS
	
	# Create the lava
	jal CREATE_LAVA

 	# Game's main loop
GAMELOOP:
	 # Sleep
 	li $v0, 32 
 	la $t0, SLEEP_TIME
 	lw $t0, 0($t0)
	addi $a0, $t0, 0   
	syscall
	
	# Display the score
	jal CREATE_SCORE
	
	# Check if the game has been won, aka the score is => 32
	jal CHECK_WIN
	
	# Check if the player collieded with the platform
	li $a0, BROWN # pass the argument of colour brown before calling function
	jal PLAYER_COLLISION
	beq $v0, 1, LOSE_SCREEN # if the player collided with the platform than game ends and jump to lose screen
	li $a0, BLOOD_ORANGE # pass the argument of colour blood orange before calling function
	jal PLAYER_COLLISION
	beq $v0, 1, LOSE_SCREEN # if the player collided with the platform than game ends
	
	# Check if the player collieded with the victory sign at the end
	li $a0, YELLOW # pass the argument of colour yellow before calling function
	jal PLAYER_COLLISION
	beq $v0, 1, GAME_VICTORY # if the player collided with the victory sign than branch to GAME_VICTORY
	
	# Check if the player has eaten all of one of the mushroom
	jal MUSHROOM_COLLISION	
	
	# Check if the player is jumping
	bgt $t3, 0, RESPOND_TO_W
	
	# Check if the player is on a platform
	jal PLAYER_ON_PLATFORM
	beq $v0, 1, GAMELOOP_ALLOW_JUMP # if return value = 1, aka player is on a platform, branch to GAMELOOP_ALLOW_JUMP
	li $t4, -1 # To not allow jumping while falling
	j PLAYER_FALL
	
GAMELOOP_ALLOW_JUMP:
	li $t4, 0 # To allow player jumping
	
GAMELOOP_CONT:	
	# Check for keyboard input, if yes then branch to KEYPRESS_HAPPENED
 	li $t9, 0xffff0000
 	lw $t8, 0($t9)
 	beq $t8, 1, KEYPRESS_HAPPENED
 	
 	# Move the platforms
	j UPDATE_PLATFORM
 	
 	j GAMELOOP # jump to GAMELOOP
 	
KEYPRESS_HAPPENED:
	# load the value of the keypress onto $t2
	lw $t2, 4($t9)

	# Check if a was pressed, if yes then branch to RESPOND_TO_A
 	beq $t2, 97, RESPOND_TO_A
 	
  	# Check if d was pressed, if yes then branch to RESPOND_TO_D
 	beq $t2, 100, RESPOND_TO_D
 	
 	# Check if w was pressed, if not then branch to KEYPRESS_HAPPENED_CONT
 	bne $t2, 119, KEYPRESS_HAPPENED_CONT
 	# Check if we are already jumping, if so then branch to KEYPRESS_HAPPENED_CONT
 	bgt $t3, 0, KEYPRESS_HAPPENED_CONT
 	# Check if we are falling, if so then branch to KEYPRESS_HAPPENED_CONT
 	beq $t4, -1, KEYPRESS_HAPPENED_CONT
 	la $t0, JUMP_HEIGHT
 	lw $t0, 0($t0)
 	addi $t3, $t0, 0
 	j RESPOND_TO_W
 	
KEYPRESS_HAPPENED_CONT:
 	# Check if q was pressed, if yes then branch to RESPOND_TO_Q
 	beq $t2, 113, RESPOND_TO_Q
 	
 	 # Check if p was pressed, if yes then branch to RESPOND_TO_P
 	beq $t2, 112, RESPOND_TO_P
 	
KEYPRESS_HAPPENED_END:
	 # Move the platforms
	j UPDATE_PLATFORM
 	j GAMELOOP # jump back to the game loop

RESPOND_TO_A:
	# Check if we are on the left edge
	la $a0, CHAR_POS
	lw $a0, 0($a0)
	jal CAN_MOVE_LEFT # jump and link to CAN_MOVE_LEFT
	beq $v0, 0, KEYPRESS_HAPPENED_END # if the return value = 0, then branch to KEYPRESS_HAPPENED_END
	
	# Create the character of moving to the left
	jal ERASE_CHAR # Erase the previous character
	
	# Update the position of the character
	la $t8, CHAR_POS 
	lw $t0, 0($t8)
	addi $t0, $t0, -4
	sw $t0, 0($t8)
	
	jal CREATE_CHAR # Create the new character with its new position

	j KEYPRESS_HAPPENED_END # jump back 
	
RESPOND_TO_D:
	# Check if we are on the right edge
	la $a0, CHAR_POS
	lw $a0, 0($a0)
	jal CAN_MOVE_RIGHT # jump and link to CAN_MOVE_RIGHT
	beq $v0, 0, KEYPRESS_HAPPENED_END # if the return value = 0, then branch to KEYPRESS_HAPPENED_END
	
	# Create the character of moving to the right
	jal ERASE_CHAR # Erase the previous character
	
	# Update the position of the character
	la $t8, CHAR_POS 
	lw $t0, 0($t8)
	addi $t0, $t0, 4
	sw $t0, 0($t8)
	
	jal CREATE_CHAR # Create the new character with its new position
	
	j KEYPRESS_HAPPENED_END # jump back
	
RESPOND_TO_W:
	addi $t3, $t3, -1 # Decrement $t3

	# Create the character of moving up
	jal ERASE_CHAR # Erase the previous character
	
	# Update the position of the character
	la $t8, CHAR_POS 
	lw $t0, 0($t8)
	addi $t0, $t0, -128
	sw $t0, 0($t8)
	
	jal CREATE_CHAR # Create the new character with its new position
	
	j GAMELOOP_CONT # jump back

RESPOND_TO_Q:
	j END # jump to end

RESPOND_TO_P:
	j START # jump to the start


CHECK_WIN:
	
	la $s0, SCORE
	lw $s1, 0($s0) # $s1 stores the value from SCORE
	
	bge $s1, 32, CHECK_WIN_IF # branch to CHECK_WIN_IF if the value of score is >= 32
	j CHECK_WIN_END
	
CHECK_WIN_IF:
	j WIN_SCREEN

CHECK_WIN_END:
	jr $ra # jump back to caller

LOSE_SCREEN:

	li $s0, WHITE # $s0 stores the colour white

	# Display a lose screen message
	li $s1, BASE_ADDRESS # $s1 stores the base address for display
	addi $s1, $s1, 1536
	addi $s1, $s1, 20
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	
	addi $s1, $s1, 8
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -4
	sw $s0, 0($s1)
	addi $s1, $s1, -4
	sw $s0, 0($s1)
	addi $s1, $s1, -4
	sw $s0, 0($s1)
	addi $s1, $s1, -4
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	
	addi $s1, $s1, 24
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -4
	sw $s0, 0($s1)
	addi $s1, $s1, -4
	sw $s0, 0($s1)
	addi $s1, $s1, -4
	sw $s0, 0($s1)
	addi $s1, $s1, -4
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	
	addi $s1, $s1, 8
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, -8
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)

	j FINISH_SCREEN # jump to FINISH_SCREEN
	
WIN_SCREEN:

	li $s0, WHITE # $s0 stores the colour white

	# Display a win screen message
	li $s1, BASE_ADDRESS # $s1 stores the base address for display
	addi $s1, $s1, 1536
	addi $s1, $s1, 24
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, 512
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, 4
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	
	addi $s1, $s1, 8
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	addi $s1, $s1, 128
	sw $s0, 0($s1)
	
	addi $s1, $s1, 8
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, 132
	sw $s0, 0($s1)
	addi $s1, $s1, 132
	sw $s0, 0($s1)
	addi $s1, $s1, 132
	sw $s0, 0($s1)
	addi $s1, $s1, 132
	sw $s0, 0($s1)
	addi $s1, $s1, 132
	sw $s0, 0($s1)
	addi $s1, $s1, 132
	sw $s0, 0($s1)
	addi $s1, $s1, 132
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)
	addi $s1, $s1, -128
	sw $s0, 0($s1)

	j FINISH_SCREEN # jump to FINISH_SCREEN
	
FINISH_SCREEN:
	
FINISH_SCREEN_LOOP:
	# Sleep
	li $v0, 32 
	li $a0, 1000
	syscall
	
	# Check for keyboard input, if yes then branch to KEYPRESS_HAPPENED
 	li $t9, 0xffff0000
 	lw $t8, 0($t9)
 	beq $t8, 1, CHECK_KEY
	
	j FINISH_SCREEN_LOOP
	
CHECK_KEY:
	# load the value of the keypress onto $t2
	lw $t2, 4($t9)
 	# Check if q was pressed, if yes then branch to RESPOND_TO_Q
 	beq $t2, 113, RESPOND_TO_Q
 	 # Check if p was pressed, if yes then branch to RESPOND_TO_P
 	beq $t2, 112, RESPOND_TO_P
 	
 	j FINISH_SCREEN_LOOP
	

INITIALIZE_ARRAY:
	
	# Initialize CHAR_POS
	la $t0, CHAR_POS
	li $t1, 3388
	sw $t1, 0($t0)
	
	# Initialize PLATFORM_ARRAY
	la $t0, PLATFORM_ARRAY
	li $t1, 3900
	sw $t1, 0($t0)
	li $t1, 3160
	sw $t1, 4($t0)
	li $t1, 2216
	sw $t1, 8($t0)
	li $t1, 1360
	sw $t1, 12($t0)
	li $t1, 544
	sw $t1, 16($t0)
	
	# Initialize MUSHROOM_ARRAY
	la $t0, MUSHROOM_ARRAY
	li $t1, 2904
	sw $t1, 0($t0)
	li $t1, 1960
	sw $t1, 4($t0)	
	li $t1, 1104
	sw $t1, 8($t0)	
	li $t1, -1
	sw $t1, 12($t0)		
	li $t1, -1
	sw $t1, 16($t0)	
	li $t1, -1
	sw $t1, 20($t0)	
	li $t1, 0
	sw $t1, 24($t0)	
	li $t1, 0
	sw $t1, 28($t0)	
	li $t1, 0
	sw $t1, 32($t0)	
	
	# Initialize JUMP_HEIGHT
	la $t0, JUMP_HEIGHT
	li $t1, 8
	sw $t1, 0($t0)
	
	# Initialize SLEEP_TIME
	la $t0, SLEEP_TIME
	li $t1, 250
	sw $t1, 0($t0)
	
	# Initalize that the character can jump and is not falling
	li $t3, 0
	li $t4, 0
	
	jr $ra # jump back to caller
	
INITIALIZE_SCORE:

	# Initialize SCORE
	la $t0, SCORE
	li $t1, 28
	sw $t1, 0($t0)
	
	jr $ra # jump back to caller

CLEAR_SCREEN:

	li $s4, BLACK # $s4 stores the colour black

	# Use a for loop to clear the screen
	li $s1, 0
SCREEN_LOOP:
	beq $s1, 1024, SCREEN_END # if $s1 = 1024, branch to SCREEN_END
	
	li $s2, BASE_ADDRESS # $s2 stores the base address of the display
	sll $s3, $s1, 2 # $s3 = $s1 * 4
	add $s2, $s2, $s3
	sw $s4, 0($s2)
	
	addi $s1, $s1, 1
	j SCREEN_LOOP	

SCREEN_END:
	jr $ra # jump back to caller	
		
CREATE_SCORE:

	li $s4, PINK # $s4 stores the colour pink
	
	# load the value of store onto $s0
	la $s0, SCORE
	lw $s0, 0($s0)
	
	li $s1, 0
	
SCORE_LOOP:	
	# Use a for loop to create the display
	beq $s1, $s0, SCORE_END # if $$s1 = $s0 then branch to SCORE_END
	
	li $s2, BASE_ADDRESS # $s2 stores the base address of the display
	sll $s3, $s1, 2 # $s3 = $s1 * 4
	add $s2, $s2, $s3
	sw $s4, 0($s2)
	
	addi $s1, $s1, 1
	j SCORE_LOOP
	
SCORE_END:	
	jr $ra # jump back to caller				
				
GAME_VICTORY:

	# Add 8 points to the score
	la $s0, SCORE
	lw $s1, 0($s0)
	addi $s1, $s1, 8
	sw $s1, 0($s0)
	j START_WITH_SCORE # Go to end the game			

MUSHROOM_COLLISION:
	
	# Loop through the mushroom array
	li $s0, 0
	
MUSHROOM_COLLISION_LOOP:
	beq $s0, 3, MUSHROOM_COLLISION_END # branch to MUSHROOM_COLLISION_END if $s0 = 3

	la $s1, MUSHROOM_ARRAY # load address of MUSHROOM_ARRAY[0] onto $s1
	sll $s2, $s0, 2 # $s2 = $s0 * 4
	add $s1, $s1, $s2 # $s1 = address of MUSHROOM_ARRAY[i]
	lw $s3, 24($s1) # $s3 = MUSHROOM_ARRAY[i+6]
	
	# Check if the ith mushroom has already been eaten, if so branch to MUSHROOM_COLLISION_UPDATE
	beq $s3, 1, MUSHROOM_COLLISION_UPDATE
	
	# Check if the ith mushroom has been eaten completely, aka there is no trace of it left anymore
	lw $s4, 0($s1) # get the position of the ith mushroom, $s4 = MUSHROOM_ARRAY[i]
	lw $s5, 12($s1) # get the colour of the ith mushrooms, $s5 = MUSHROOM_ARRAY[i+3]
	
	# Check if the mushroom colour is red, if so branch to MUSHROOM_COLLISION_RED
	beq $s5, 0, MUSHROOM_COLLISION_RED
	# Check if the mushroom colour is green, if so branch to MUSHROOM_COLLISION_GREEN
	beq $s5, 1, MUSHROOM_COLLISION_GREEN
	
MUSHROOM_COLLISION_PURPLE:	
	li $s6, PURPLE # $s6 stores the colour purple
	
	# Check if the mushroom has been eaten completely
	li $s7, BASE_ADDRESS
	add $s7, $s7, $s4
	lw $s4, 0($s7) # store the colour of the mushroom pixel onto $s4
	beq $s4, $s6, MUSHROOM_COLLISION_UPDATE # if the pixel has not been eaten yet, then branch to MUSHROOM_COLLISION_UPDATE
	addi $s7, $s7, -128
	lw $s4, 0($s7) # store the colour of the mushroom pixel onto $s4
	beq $s4, $s6, MUSHROOM_COLLISION_UPDATE # if the pixel has not been eaten yet, then branch to MUSHROOM_COLLISION_UPDATE
	addi $s7, $s7, -4
	lw $s4, 0($s7) # store the colour of the mushroom pixel onto $s4
	beq $s4, $s6, MUSHROOM_COLLISION_UPDATE # if the pixel has not been eaten yet, then branch to MUSHROOM_COLLISION_UPDATE
	addi $s7, $s7, 8
	lw $s4, 0($s7) # store the colour of the mushroom pixel onto $s4
	beq $s4, $s6, MUSHROOM_COLLISION_UPDATE # if the pixel has not been eaten yet, then branch to MUSHROOM_COLLISION_UPDATE
	
	# If we got to here, then the mushroom has been eaten completely
	# Since the mushroom is purple, we increase the jumping height
	la $s5, JUMP_HEIGHT
	lw $s4, 0($s5)
	addi $s4, $s4, 2
	sw $s4, 0($s5)
	
	# Set the array to tell that the ith mushroom has been eaten
	li $s4, 1
	sw $s4, 24($s1)
	
	j MUSHROOM_COLLISION_UPDATE
	
MUSHROOM_COLLISION_RED:
	li $s6, RED # $s6 stores the colour red
	
	# Check if the mushroom has been eaten completely
	li $s7, BASE_ADDRESS
	add $s7, $s7, $s4
	lw $s4, 0($s7) # store the colour of the mushroom pixel onto $s4
	beq $s4, $s6, MUSHROOM_COLLISION_UPDATE # if the pixel has not been eaten yet, then branch to MUSHROOM_COLLISION_UPDATE
	addi $s7, $s7, -128
	lw $s4, 0($s7) # store the colour of the mushroom pixel onto $s4
	beq $s4, $s6, MUSHROOM_COLLISION_UPDATE # if the pixel has not been eaten yet, then branch to MUSHROOM_COLLISION_UPDATE
	addi $s7, $s7, -4
	lw $s4, 0($s7) # store the colour of the mushroom pixel onto $s4
	beq $s4, $s6, MUSHROOM_COLLISION_UPDATE # if the pixel has not been eaten yet, then branch to MUSHROOM_COLLISION_UPDATE
	addi $s7, $s7, 8
	lw $s4, 0($s7) # store the colour of the mushroom pixel onto $s4
	beq $s4, $s6, MUSHROOM_COLLISION_UPDATE # if the pixel has not been eaten yet, then branch to MUSHROOM_COLLISION_UPDATE
	
	# If we got to here, then the mushroom has been eaten completely
	# Since the mushroom is red, we increase the sleeping time
	la $s5, SLEEP_TIME
	lw $s4, 0($s5)
	addi $s4, $s4, 250
	sw $s4, 0($s5)
	
	# Set the array to tell that the ith mushroom has been eaten
	li $s4, 1
	sw $s4, 24($s1)
		
	j MUSHROOM_COLLISION_UPDATE

MUSHROOM_COLLISION_GREEN:
	li $s6, GREEN # $s6 stores the colour green
	
	# Check if the mushroom has been eaten completely
	li $s7, BASE_ADDRESS
	add $s7, $s7, $s4
	lw $s4, 0($s7) # store the colour of the mushroom pixel onto $s4
	beq $s4, $s6, MUSHROOM_COLLISION_UPDATE # if the pixel has not been eaten yet, then branch to MUSHROOM_COLLISION_UPDATE
	addi $s7, $s7, -128
	lw $s4, 0($s7) # store the colour of the mushroom pixel onto $s4
	beq $s4, $s6, MUSHROOM_COLLISION_UPDATE # if the pixel has not been eaten yet, then branch to MUSHROOM_COLLISION_UPDATE
	addi $s7, $s7, -4
	lw $s4, 0($s7) # store the colour of the mushroom pixel onto $s4
	beq $s4, $s6, MUSHROOM_COLLISION_UPDATE # if the pixel has not been eaten yet, then branch to MUSHROOM_COLLISION_UPDATE
	addi $s7, $s7, 8
	lw $s4, 0($s7) # store the colour of the mushroom pixel onto $s4
	beq $s4, $s6, MUSHROOM_COLLISION_UPDATE # if the pixel has not been eaten yet, then branch to MUSHROOM_COLLISION_UPDATE
	
	# If we got to here, then the mushroom has been eaten completely
	# Since the mushroom is green, we increase the player's score by 4
	la $s5, SCORE
	lw $s4, 0($s5)
	addi $s4, $s4, 4
	sw $s4, 0($s5)
	
	# Set the array to tell that the ith mushroom has been eaten
	li $s4, 1
	sw $s4, 24($s1)
	
MUSHROOM_COLLISION_UPDATE:
	addi $s0, $s0, 1
	j MUSHROOM_COLLISION_LOOP	
	
MUSHROOM_COLLISION_END:
	jr $ra # jump back to caller

CREATE_LAVA:
	li $s1, BLOOD_ORANGE # $s1 stores the colour blood orange
	
	# Create the lava platform at the bottom
	# Use a for loop to create the lava platform
	li $s3, 0
	
LAVA_LOOP:
	beq $s3, 32, LAVA_END # branch to LAVA_END if $s3 = 32
	li $s0, BASE_ADDRESS # %s0 stores the base address for display
	addi $s0, $s0, 3968
	sll $s4, $s3, 2 # $s4 = $s3 * 4
	add $s0, $s0, $s4
	sw $s1, 0($s0)
	addi $s3, $s3, 1
	j LAVA_LOOP
	
LAVA_END:
	jr $ra # jump back to caller
	
									
PLAYER_COLLISION:
	li $s0, BASE_ADDRESS # %s0 stores the base address for display
	addi $s1, $a0, 0 # $s1 stores the colour brown
	
	# Get the position of the character
	la $s3, CHAR_POS # load address of CHAR_POS onto $s3
	lw $s4, 0($s3) # $s4 = CHAR_POS
	
	add $s0, $s0, $s4
	
	# Check if the head collided with the platform
	lw $s5, 0($s0) # $s5 stores the colour of the pixel of where the player head should be
	beq $s5, $s1, PLAYER_COLLISION_IF
	addi $s0, $s0, 128
	lw $s5, 0($s0) # $s5 stores the colour of the pixel of where the first body should be
	beq $s5, $s1, PLAYER_COLLISION_IF
	addi $s0, $s0, -4
	lw $s5, 0($s0) # $s5 stores the colour of the pixel of where the left arm should be
	beq $s5, $s1, PLAYER_COLLISION_IF
	addi $s0, $s0, 8
	lw $s5, 0($s0) # $s5 stores the colour of the pixel of where the right arm should be
	beq $s5, $s1, PLAYER_COLLISION_IF
	addi $s0, $s0, 124
	lw $s5, 0($s0) # $s5 stores the colour of the pixel of where the second body should be
	beq $s5, $s1, PLAYER_COLLISION_IF
	addi $s0, $s0, 124
	lw $s5, 0($s0) # $s5 stores the colour of the pixel of where the left foot should be
	beq $s5, $s1, PLAYER_COLLISION_IF
	addi $s0, $s0, 8
	lw $s5, 0($s0) # $s5 stores the colour of the pixel of where the right foot should be
	beq $s5, $s1, PLAYER_COLLISION_IF
	addi $v0, $zero, 0 # return value = 0 if player didn't collided with an object
	j PLAYER_COLLISION_END
	
PLAYER_COLLISION_IF:
	addi $v0, $zero, 1 # return value = 1 if player collided with the object

PLAYER_COLLISION_END:	
	jr $ra # jump back to caller
																																																						
PLAYER_FALL:
	# Create the character of falling down
	jal ERASE_CHAR # Erase the previous character
	
	# Update the position of the character
	la $s7, CHAR_POS 
	lw $s0, 0($s7)
	addi $s0, $s0, 128
	sw $s0, 0($s7)
	
	jal CREATE_CHAR # Create the new character with its new position
	
	jal CREATE_LAVA # Recreate the lava platform that might have been lost by the player
	
	j GAMELOOP_CONT # jump back to game loop

PLAYER_ON_PLATFORM:
	li $s0, BASE_ADDRESS # %s0 stores the base address for display
	li $s1, BROWN # $s1 stores the colour brown

	# Get the position of the character
	la $s3, CHAR_POS # load address of CHAR_POS onto $s3
	lw $s4, 0($s3) # $s4 = CHAR_POS
	
	add $s0, $s0, $s4
	addi $s0 $s0, 508
	lw $s5, 0($s0) # $s5 stores the colour of the pixel below the left foot
	addi $s0 $s0, 8
	lw $s6, 0($s0) # $s6 stores the colour of the pixel below the right foot
	
	# Check if $s5 and $s6 is brown, aka if the player is on the platform
	beq $s5, $s1, PLAYER_ON_PLATFORM_IF
	beq $s6, $s1, PLAYER_ON_PLATFORM_IF
	addi $v0, $zero, 0 # Player is not on platform so send return value = 0
	j PLAYER_ON_PLATFORM_END 
	
PLAYER_ON_PLATFORM_IF:
	addi $v0, $zero, 1 # Player is on platform so send return value = 1
	
PLAYER_ON_PLATFORM_END:		
	jr $ra # jump back to caller

CREATE_MUSHROOMS:
	li $s5, 0
	# Loop thorugh the mushhroom array
MUSHROOMS_LOOP:
	beq $s5, 3, MUSHROOMS_END # if $s5 = 3, branch to MUSHROOMS_END	
	
	la $s3, MUSHROOM_ARRAY # load address of MUSHROOM_ARRAY[0] onto $s3
	sll $s6, $s5, 2 # $s6 = $s5 * 4
	add $s3, $s3, $s6 # $s3 = address of MUSHROOM_ARRAY[i]
	lw $s4, 0($s3) # $s4 = MUSHROOM_ARRAY[i]
	
	# Get a random number between 0 - 2 and store it in $s2
	li $v0, 42 
	li $a0, 0 
	li $a1, 3 
	syscall
	addi $s2, $a0, 0
	
	# If the random number = 0, make a red mushroom, if # = 1 make a green mushroom, if # = 2 make a purple mushroom
	sw $s2, 12($s3) # store the value of the random number onto MUSHROOM_ARRAY[i+3]
	beq $s2, 0, RED_MUSHROOM
	beq $s2, 1, GREEN_MUSHROOM
	li $s1, PURPLE
	j CREATE_MUSHROOMS_CONT

RED_MUSHROOM:
	li $s1, RED
	j CREATE_MUSHROOMS_CONT
	
GREEN_MUSHROOM:
	li $s1, GREEN
	
CREATE_MUSHROOMS_CONT:	
	# Create the mushroom
	li $s0, BASE_ADDRESS # %s0 stores the base address for display
	add $s0, $s0, $s4
	sw $s1, 0($s0)
	addi $s0, $s0, -128
	sw $s1, 0($s0)
	addi $s0, $s0, -4
	sw $s1, 0($s0)
	addi $s0, $s0, 8
	sw $s1, 0($s0)
	
	addi $s5, $s5, 1
	j MUSHROOMS_LOOP
MUSHROOMS_END:
	jr $ra # jump back to caller

UPDATE_PLATFORM:

	# Erase the platforms
	li $a0, BLACK # set the first argument to be colour black
	li $a1, BLACK # set the second argument to be colour black
	jal CREATE_PLATFORM
	
	# Make the platform move
	li $s1, 0
	
	# Loop through all the platforms
UPDATE_PLATFORM_LOOP:
	beq $s1, 5, UPDATE_PLATFORM_END
	la $s2, PLATFORM_ARRAY # $s2 = address of PLATFFORM_ARRAY[0]
	sll $s3, $s1, 2 # $s3 = $s1 * 4
	add $s3, $s3, $s2 # $s3 = address of PLATFORM_ARRAY[i]
	lw $s4, 0($s3) # $s4 = PLATFORM_ARRAY[i]
	
	# Get a random number between 0 - 1 and store it in $s5
	li $v0, 42 
	li $a0, 0 
	li $a1, 2
	syscall
	addi $s5, $a0, 0
	
	# Move the current platform to the right if $s5=1, otherwise move to the left, only if it is allowed to do that
	beq $s5, 1, UPDATE_PLATFORM_IF
	
	# Push all our variables onto the stack before calling the function
	addi $sp, $sp, -4 # push address of $s1 onto the stack
	sw $s1, 0($sp)
	addi $sp, $sp, -4 # push address of $s2 onto the stack
	sw $s2, 0($sp)
	addi $sp, $sp, -4 # push address of $s3 onto the stack
	sw $s3, 0($sp)
	addi $sp, $sp, -4 # push address of $s2 onto the stack
	sw $s4, 0($sp)
	addi $sp, $sp, -4 # push address of $s2 onto the stack
	sw $s5, 0($sp)
	
	# Check if the platform is on the left edge
	addi $a0, $s4, 0
	addi $a0, $a0, -4
	jal CAN_MOVE_LEFT
	
	# Pop all of our variables
	lw $s5, 0($sp) # pop $s5 off the stack
	addi $sp, $sp, 4
	lw $s4, 0($sp) # pop $s4 off the stack
	addi $sp, $sp, 4
	lw $s3, 0($sp) # pop $s3 off the stack
	addi $sp, $sp, 4
	lw $s2, 0($sp) # pop $s2 off the stack
	addi $sp, $sp, 4
	lw $s1, 0($sp) # pop $s1 off the stack
	addi $sp, $sp, 4
	
	beq $v0, 0, UPDATE_PLATFORM_IF # if return value = 0, then branch to UPDATE_PLATFORM_IF
UPDATE_PLATFORM_ELSE:
	addi $s4, $s4, -4
	sw $s4, 0($s3)
	j UPDATE_PLATFORM_UPDATE
	
UPDATE_PLATFORM_IF:
	# Push all our variables onto the stack before calling the function
	addi $sp, $sp, -4 # push address of $s1 onto the stack
	sw $s1, 0($sp)
	addi $sp, $sp, -4 # push address of $s2 onto the stack
	sw $s2, 0($sp)
	addi $sp, $sp, -4 # push address of $s3 onto the stack
	sw $s3, 0($sp)
	addi $sp, $sp, -4 # push address of $s2 onto the stack
	sw $s4, 0($sp)
	addi $sp, $sp, -4 # push address of $s2 onto the stack
	sw $s5, 0($sp)
	
	# Check if the platform is on the right edge
	addi $a0, $s4, 0
	addi $a0, $a0, 4
	jal CAN_MOVE_RIGHT
	
	# Pop all of our variables
	lw $s5, 0($sp) # pop $s5 off the stack
	addi $sp, $sp, 4
	lw $s4, 0($sp) # pop $s4 off the stack
	addi $sp, $sp, 4
	lw $s3, 0($sp) # pop $s3 off the stack
	addi $sp, $sp, 4
	lw $s2, 0($sp) # pop $s2 off the stack
	addi $sp, $sp, 4
	lw $s1, 0($sp) # pop $s1 off the stack
	addi $sp, $sp, 4
	
	beq $v0, 0, UPDATE_PLATFORM_ELSE # if return value = 0, then branch to UPDATE_PLATFORM_IF

	addi $s4, $s4, 4
	sw $s4, 0($s3)
	
UPDATE_PLATFORM_UPDATE:
	addi $s1, $s1, 1
	j UPDATE_PLATFORM_LOOP
	
UPDATE_PLATFORM_END:
	li $a0, BROWN # set the argument to be colour brown
	li $a1, YELLOW # set the second argument to be colour black
	jal CREATE_PLATFORM
	j GAMELOOP

CAN_MOVE_RIGHT:

	# Get the position of the object
	addi $s4, $a0, 0 # Get the argument and store it in $s4
	addi $s4, $s4, 8 # Get the rightmost position of out object + 4
	
CAN_MOVE_RIGHT_LOOP:
	beq $s4, 0, CAN_MOVE_RIGHT_IF # if $s4=0, then branch to CAN_MOVE_RIGHT_IF
	blt $s4, 0, CAN_MOVE_RIGHT_ELSE # if $s4<0, then branch to CAN_MOVE_RIGHT_ELSE
	addi $s4, $s4, -128 # $s4 -= 128	
	j CAN_MOVE_RIGHT_LOOP # jump back to the top of the loop
	
CAN_MOVE_RIGHT_IF:
	addi $v0, $zero, 0 # set return value = 0
	jr $ra # jump back to caller

CAN_MOVE_RIGHT_ELSE:
	addi $v0, $zero, 1 # set return value = 1
	jr $ra # jump back to caller


CAN_MOVE_LEFT:
	
	# Get the position of the object
	addi $s4, $a0, 0 # Get the argument and store it in $s4
	addi $s4, $s4, -4 # Get the leftmost position of out object
	
CAN_MOVE_LEFT_LOOP:
	beq $s4, 0, CAN_MOVE_LEFT_IF # if $s4=0, then branch to CAN_MOVE_LEFT_IF
	blt $s4, 0, CAN_MOVE_LEFT_ELSE # if $s4<0, then branch to CAN_MOVE_LEFT_ELSE
	addi $s4, $s4, -128 # $s4 -= 128	
	j CAN_MOVE_LEFT_LOOP # jump back to the top of the loop
	
CAN_MOVE_LEFT_IF:
	addi $v0, $zero, 0 # set return value = 0
	jr $ra # jump back to caller

CAN_MOVE_LEFT_ELSE:
	addi $v0, $zero, 1 # set return value = 1
	jr $ra # jump back to caller

CREATE_CHAR:
	li $s0, BASE_ADDRESS # %s0 stores the base address for display
	li $s1, PEACH # $s1 stores the colour of peach
	li $s2, BLUE # $s2 stores the colour of blue

	# Get the position of the character
	la $s3, CHAR_POS # load address of CHAR_POS onto $s3
	lw $s4, 0($s3) # $s4 = CHAR_POS
	
	# Create the character
	add $s0, $s0, $s4 
	sw $s1, 0($s0)
	addi $s0, $s0, 128
	sw $s2, 0($s0)
	subi $s0, $s0, 4
	sw $s1, 0($s0)
	addi $s0, $s0, 4
	addi $s0, $s0, 4
	sw $s1, 0($s0)
	addi $s0, $s0, 128
	subi $s0, $s0, 4
	sw $s2, 0($s0)
	addi $s0, $s0, 128
	subi $s0, $s0, 4
	sw $s1, 0($s0)
	addi $s0, $s0, 4
	addi $s0, $s0, 4
	sw $s1, 0($s0)
	
	jr $ra # jump back to caller
	
ERASE_CHAR:
	li $s0, BASE_ADDRESS # %s0 stores the base address for display
	li $s1, BLACK # $s1 stores the colour black

	# Get the position of the character
	la $s3, CHAR_POS # load address of CHAR_POS onto $s3
	lw $s4, 0($s3) # $s4 = CHAR_POS
	
	# Erase the character
	add $s0, $s0, $s4 
	sw $s1, 0($s0)
	addi $s0, $s0, 128
	sw $s1, 0($s0)
	subi $s0, $s0, 4
	sw $s1, 0($s0)
	addi $s0, $s0, 4
	addi $s0, $s0, 4
	sw $s1, 0($s0)
	addi $s0, $s0, 128
	subi $s0, $s0, 4
	sw $s1, 0($s0)
	addi $s0, $s0, 128
	subi $s0, $s0, 4
	sw $s1, 0($s0)
	addi $s0, $s0, 4
	addi $s0, $s0, 4
	sw $s1, 0($s0)
	
	jr $ra # jump back to caller
	
CREATE_PLATFORM:
	li $s0, BASE_ADDRESS # %s0 stores the base address for display
	addi $s1, $a0, 0 # $s1 stores the colour of the first argument
	addi $s2, $a1, 0 # $s1 stores the colour of the second argument
	
	# Create the initial platform
	# Get the position of the platform
	la $s3, PLATFORM_ARRAY # load address of PLATFORM_ARRAY[0] onto $s3
	lw $s4, 0($s3) # $s4 = PLATFORM_ARRAY[0]
	
	# Create the first platform
	add $s0, $s0, $s4 
	sw $s1, 0($s0)
	addi $s0, $s0, -4
	sw $s1, 0($s0)
	addi $s0, $s0, -4
	sw $s1, 0($s0)
	addi $s0, $s0, 12
	sw $s1, 0($s0)
	addi $s0, $s0, 4
	sw $s1, 0($s0)
	
	addi $s0, $s0, -8 # turn the $s0 back to the center of the platform
	
	# Create 4 more platforms using a for loop
	li $s5, 1

PLATFORM_LOOP:	
	beq $s5, 5, PLATFORM_END # branch to PLATFORM_END if $s5 = 5
	
	sll $s6, $s5, 2 # Multiply $s5 * 4 and store it in $s6
	la $s3, PLATFORM_ARRAY # load address of PLATFORM_ARRAY[0] onto $s3
	add $s3, $s3, $s6 # $s3 = address of PLATFORM_ARRAY[i]
	li $s0, BASE_ADDRESS # %s0 stores the base address for display
	lw $s4, 0($s3) # $s0 = PLATFORM_ARRAY[i]
	
PLATFORM_CONTINUE:
	# Create the platform
	add $s0, $s0, $s4
	sw $s1, 0($s0)
	addi $s0, $s0, -4
	sw $s1, 0($s0)
	addi $s0, $s0, -4
	sw $s1, 0($s0)
	addi $s0, $s0, 12
	sw $s1, 0($s0)
	addi $s0, $s0, 4
	sw $s1, 0($s0)
	
	addi $s0, $s0, -8 # turn the $s0 back to be the center of the platform

PLATFORM_UPDATE:	
	addi $s5, $s5, 1 # $s5++
	j PLATFORM_LOOP
	
PLATFORM_END:
	# Add a victory object at the last platform
	addi $s0, $s0, -128
	sw $s2, 0($s0)
	addi $s0, $s0, -132
	sw $s2, 0($s0)
	addi $s0, $s0, 8
	sw $s2, 0($s0)
	addi $s0, $s0, -124
	sw $s2, 0($s0)
	addi $s0, $s0, -16
	sw $s2, 0($s0)

	jr $ra # jump back to caller

END: 	
	li $v0, 10 # terminate the program
 	syscall
