# Bitmap Game Project
# Author:	Clayton Wiegel
# Created:	Novemeber 2021
# (Created using the MARS IDE)


# Macros
.eqv	WIDTH		64

			.data
# Console output strings
intro:			.asciiz	"WELCOME TO GALACTIC ATTACK! ENTER \"P\" TO PLAY!\n"
enemy_msg:		.asciiz	"SPAWNING ENEMY\n"
gain_point:		.asciiz	"YOU EARNED 1 POINT!\n"
end_message:		.asciiz	"TIME IS UP! THANKS FOR PLAYING!\n"
total_score:		.asciiz	"YOU EARNED A TOTAL OF "
points:			.asciiz	" POINTS!"
easter_egg:		.asciiz	"YOU FOUND AN EASTER EGG!"

# Strings to hold File Paths to find BMP files.
# For each of the strings below, enter in the proper file paths for the BMP files.
# Example path for the ship bmp file: "C:\\Users\\...\\Desktop\\Bitmap Project\\ship.bmp
ship_file:		.asciiz	"C:\\...\\ship.bmp"
enemy_file:		.asciiz	"C:\\...\\enemy.bmp"
explode_file:		.asciiz	"C:\\...\\explosion.bmp"
impos_file:		.asciiz	"C:\\...\\impostor.bmp"

# Color variable for the border color and ship laser
sky_blue:		.word		0x00028BDA

# Variable to keep track of enemies destroyed
score:			.word		0

# Buffer for when program reads from the BMP files for the pixel data
file_buffer:		.space		306

# Memory locations for pixel information for each sprite
			.align		2
ship:			.space		321
			.align		2
enemy:			.space		321
			.align		2
explosion:		.space		321
			.align		2
among_us:		.space		321


			.text
main:	
	# draw border around game screen
	move	$a0, $zero
	move	$a1, $zero
	la	$a2, sky_blue
	jal	draw_border
	
	# read sprite pixel data from each of the BMP files
	la	$a0, ship_file
	la	$a1, ship
	jal	fetch_sprite
	
	la	$a0, enemy_file
	la	$a1, enemy
	jal	fetch_sprite
	
	la	$a0, explode_file
	la	$a1, explosion
	jal	fetch_sprite
	
	la	$a0, impos_file
	la	$a1, among_us
	jal	fetch_sprite
	
	# spawn ship sprite in bottom center of the screen
	li	$a0, 27
	li	$a1, 116
	li	$t6, 27	# store x coordinate of top left pixel of the ship
	li	$t7, 116	# store y coordinate of top left pixel of the ship
	la	$a2, ship	# load in ship's pixel data
	jal	draw_sprite	# draw the ship

	# Welcome user to the game
	# User must enter the letter "p" in the keyboard menu to start the game
	li	$v0, 4
	la	$a0, intro
	syscall

start_position:
	jal	check_input		# check for keyboard input
	beq	$v1, 1, game_loop	# flag to start game
	j	start_position	# loop until user starts game

game_loop:
	jal	check_input		# check for user input
	jal	tick			# keep track of game time
	jal	spawn_enemy
	la	$a2, ship		# load in ship's color data
	jal	update_position	# update player's position
	jal	check_time		# check to see if 25 seconds past
	beq	$v1, 1, exit		# quit game if time is up
	j	game_loop

exit:	li	$v0, 10
	syscall
	
	
#################################################
# Function that checks if 25 seconds have gone by.
# If it has been 25 seconds, the game will end.
check_time:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	beq	$s5, 25000, end_game		# 25 seconds to play game
	
	jr	$ra
	
end_game:
	li	$v0, 32
	li	$a0, 1000	# halt game for 1 second
	syscall
	jal	explosion_sound	# play explosion noise

	move	$a0, $t6
	move	$a1, $t7
	la	$a2, explosion	# load in explosion sprite
	li	$a3, 0
	jal	draw_sprite		# replace player ship with explosion

	li	$v0, 4
	la	$a0, end_message
	syscall			# print that time is up
	
	la	$a0, total_score
	syscall			# tell user how many points they have
	
	li	$v0, 1
	lw	$a0, score
	syscall			# print the points number as an integer
	
	li	$v0, 4
	la	$a0, points
	syscall			# finish printing points string
	
	li	$v1, 1			# flag to tell game loop to end game
	
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	
	jr	$ra


#################################################
# Function to act as a clock for the game.
# Each game tick is equivalent to 0.05 seconds
tick:
	addi	$sp, $sp, -8
	sw	$v0, ($sp)
	sw	$a0, 4($sp)
	
	li	$v0, 32
	li	$a0, 50	# 50 miliseconds
	syscall		# sleep
	
	addi	$s5, $s5, 50	# keep track of how much time has passed overall
	
	lw	$v0, ($sp)
	lw	$a0, 4($sp)
	addi	$sp, $sp, 8
	jr	$ra


#################################################
# Function to spawn an enemy.
spawn_enemy:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	bne	$t3, 0, finish_enemy
	
	li	$t0, 500
	div	$s5, $t0
	mfhi	$t0			# store remainder of total time so far divided by 500
	bne	$t0, 0, finish_enemy # if it hasn't been 10 seconds, don't do anything
	
	li	$v0, 4
	la	$a0, enemy_msg
	syscall			# print that game will spawn an enemy
	
	li	$t3, 1			# flag to say 1 enemy exists, not to spawn any more
	jal	random_position	# compute random position to place enemy
	
	move	$a0, $v0		# retrieve random x value
	move	$a1, $v1		# retrieve random y value
	
	# save position of enemy for collision purposes
	move	$s4, $a0		# enemy x value
	move	$s6, $a1		# enemy y value
	addi	$s6, $s6, 9		# used for collision purposes, more info in "check_collision"	
	
	li	$a3, 0			# tell draw_pixel we will print colored pixels, not black ones
	la	$a2, enemy		# load in enemy color pixel data
	jal	draw_sprite		# print enemy

finish_enemy:
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra


#################################################
# Function to play sound whenever ships explode.
explosion_sound:
	addi	$sp, $sp, -12
	sw	$a3, ($sp)
	sw	$a1, 4($sp)
	sw	$a0, 8($sp)
	
	li	$v0, 31	# MIDI out synchronous
	li	$a0, 36	# pitch
	li	$a1, 10000	# duration in ms
	li	$a2, 127	# instrument
	li	$a3, 127	# volume
	syscall		# play audio
	
	lw	$a3, ($sp)
	lw	$a1, 4($sp)
	lw	$a0, 8($sp)
	addi	$sp, $sp, 12
	
	jr	$ra

#################################################
# This function will use syscall 42 to calculate a random
# (x, y) position to spawn the enemy sprite at.
random_position:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)

	# generate random x coordinate
	li	$v0, 42
	li	$a0, 21		# ID of psuedorandom number generator
	li	$a1, 54		# upper x bound
	syscall
	addi	$sp, $sp, -4
	sw	$a0, ($sp)		# save x value
	
	# generate random y coordiante
	li	$v0, 42
	li	$a0, 22		# ID of psuedorandom number generator
	li	$a1, 112		# upper y bound
	syscall
	addi	$sp, $sp, -4
	sw	$a0, ($sp)		# save y value
	
	# bring the x, y values we saved off stack, return in $v0 and $v1
	lw	$v1, 4($sp)
	lw	$v0, ($sp)
	addi	$sp, $sp, 8
	
	# check to see enemy will spawn within bounds
	beq	$v0, 0, keep_in_bounds
	beq	$v1, 0, keep_in_bounds
	bgt	$v0, 54, keep_in_bounds
	beq	$v1, 112, keep_in_bounds

finish_rand_pos:
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra

keep_in_bounds:
	# any time the random numbers are out of bounds, enemy will spawn at (28, 80)
	# by default
	li	$v0, 28
	li	$v1, 80
	j	finish_rand_pos


#################################################
# This function updates the player's score.
update_score:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	# Load score from memory and add a point.
	lw	$t0, score
	addi	$t0, $t0, 1
	sw	$t0, score
	
	# Print in console that player earned a point
	li	$v0, 4
	la	$a0, gain_point
	syscall

	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra


#################################################
# This function checks for whether the ship's laser
# collides with the enemy sprite.
check_collision:
	addi	$sp, $sp, -12
	sw	$t7, ($sp)
	sw	$t6, 4($sp)
	sw	$ra, 8($sp)
	
	li	$t0, 1
	bne	$a1, $s6, end_col_check	# exit if laser y value isn't equal to the y value
						# at the bottom of the enemy sprite

	# check to see if player's laser lands anywhere between
	# the enemy sprite's leftmost x value and rightmost x value
	# if it isnt, we jump to "end_col_check"
	blt	$a0, $s4, end_col_check
	move	$t0, $s4
	addi	$t0, $t0, 8
	bgt	$a0, $t0, end_col_check	
	
	move	$t6, $s4		# $s4 held enemy sprite's leftmost x value
	addi	$s6, $s6, -8		# $s6 held enemy's bottom most y value
	move	$t7, $s6		# return that y value back to top of the sprite
	li	$a3, 1			# tell "draw_pixel" we will be printing black pixels
	jal	explosion_sound	# play explosion sound
	jal	update_score		# update player's score
	
	# draw explosion sprite
	move	$a0, $t6
	move	$a1, $t7
	la	$a2, explosion
	li	$a3, 0
	jal	draw_sprite
	
	# sleep so explosion stays
	li	$v0, 32
	li	$a0, 600
	syscall
	
	# clear out the explosion sprite
	jal	clear_sprite
	
	li	$t3, 0		# flag to say that there is no longer an enemy sprite
				# (tells program to spawn another enemy)

end_col_check:
	lw	$t7, ($sp)
	lw	$t6, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra


#################################################
# This function fires a laser from the player's ship.
fire_laser:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	# play laser shooting sound
	li	$v0, 31
	li	$a0, 69
	li	$a1, 10000
	li	$a2, 127
	li	$a3, 127
	syscall
	
	# laser will start printing at the middle top of the ship
	move	$a0, $t6
	addi	$a0, $a0, 4
	move	$a1, $t7	
	la	$a2, sky_blue	# laser color
	move	$a3, $zero	# tell "draw_pixel" we are using color, not black
	
bullet_draw:
	addi	$sp, $sp, -4
	sw	$a0, ($sp)
	
	# sleep a little bit so laser is visible and won't flash out instantly
	li	$v0, 32
	li	$a0, 1
	syscall
	
	lw	$a0, ($sp)
	addi	$sp, $sp, 4
	
	
	addi	$a1, $a1, -1		# subtract 1 from y so laser travels up screen
	jal	draw_pixel	
	beq	$a1, $s6, collision	# jump below to collision
	beq	$a1, 1, remove_laser	# if the laser reaches top of screen, delete entire beam
	j	bullet_draw

collision:
	jal	check_collision	# check to see if laser hits an enemy, if no collision, keep drawing
	j	bullet_draw

# initialization before loop to remove laser from screen
remove_laser:
	move	$a0, $t6
	addi	$a0, $a0, 4
	move	$a1, $t7
	move	$a2, $zero
	li	$a3, 1		# tell "draw_pixel" to use black pixels

remove_loop:
	addi	$a1, $a1, -1	# decrement y value so black pixels move up the screen
				# to remove laser beam
	jal	draw_pixel
	beq	$a1, 1, finish_fire	# at top of screen, now exit
	j	remove_loop

finish_fire:
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra


#################################################
# This function is meant to be a goofy easter egg.
# During the game, if the player presses "i", the game will
# halt, print a sprite of a character from the video game
# "Among Us", then play the theme song listed below.
play_impostor_theme:
	# Plays C note, octave above middle C
	li	$v0, 33	# MIDI out synchronous
	li	$a0, 72	# pitch
	li	$a1, 500	# duration in ms
	li	$a2, 1		# instrument
	li	$a3, 127	# volume
	syscall
	
	# Eb
	li	$v0, 33	# MIDI out synchronous
	li	$a0, 75	# pitch
	li	$a1, 500	# duration in ms
	li	$a2, 1		# instrument
	li	$a3, 127	# volume
	syscall
	
	# F
	li	$v0, 33	# MIDI out synchronous
	li	$a0, 77	# pitch
	li	$a1, 500	# duration in ms
	li	$a2, 1		# instrument
	li	$a3, 127	# volume
	syscall
	
	# F#
	li	$v0, 33	# MIDI out synchronous
	li	$a0, 78	# pitch
	li	$a1, 500	# duration in ms
	li	$a2, 1		# instrument
	li	$a3, 127	# volume
	syscall
	
	# F
	li	$v0, 33	# MIDI out synchronous
	li	$a0, 77	# pitch
	li	$a1, 500	# duration in ms
	li	$a2, 1		# instrument
	li	$a3, 127	# volume
	syscall
	
	# Eb
	li	$v0, 33	# MIDI out synchronous
	li	$a0, 75	# pitch
	li	$a1, 500	# duration in ms
	li	$a2, 1		# instrument
	li	$a3, 127	# volume
	syscall
	
	#C5
	li	$v0, 33	# MIDI out synchronous
	li	$a0, 72	# pitch
	li	$a1, 1000	# duration in ms
	li	$a2, 1		# instrument
	li	$a3, 127	# volume
	syscall
	
	# Bb (below C5)
	li	$v0, 33	# MIDI out synchronous
	li	$a0, 70	# pitch
	li	$a1, 250	# duration in ms
	li	$a2, 1		# instrument
	li	$a3, 127	# volume
	syscall
	
	# D
	li	$v0, 33	# MIDI out synchronous
	li	$a0, 74	# pitch
	li	$a1, 250	# duration in ms
	li	$a2, 1		# instrument
	li	$a3, 127	# volume
	syscall
	
	# C5
	li	$v0, 33	# MIDI out synchronous
	li	$a0, 72	# pitch
	li	$a1, 1000	# duration in ms
	li	$a2, 1		# instrument
	li	$a3, 127	# volume
	syscall
	
	jr	$ra


#################################################
# This function checks to see if the user had any
# keyboard input.
check_input:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	lw 	$t5, 0xffff0000  	# check to see if any input
	li	$v0, 0
	li	$v1, 0
	li	$a3, 0
    	beq 	$t5, 0, exit_check   # keep displaying given no input
	
	lw 	$s1, 0xffff0004	# process input
	beq	$s1, 113, exit	# input q (quit)
	beq	$s1, 112, start_game	# input p (play)
	beq	$s1, 97, left  	# input a
	beq	$s1, 100, right	# input d
	beq	$s1, 32, fire		# input space bar
	beq	$s1, 105, impostor	# i for impostor (a part of the easter egg)
	j	exit_check		# process invalid input
	
	### process valid input ###
impostor:
	# will print a sprite in middle of screen, play music,
	# then close the game (part of an easter egg)
	li	$a0, 32
	li	$a1, 64
	la	$a2, among_us
	jal	draw_sprite
	jal	play_impostor_theme
	
	# Tell player that they found an easter egg in console
	li	$v0, 4
	la	$a0, easter_egg
	syscall
	
	# close program
	li	$v0, 10
	syscall

left:	move	$a2, $zero	# make color black
	li	$a3, 1		# prepare "draw_pixel" for using black pixels
	beq	$t6, 3, left_border_check	# allow ship to teleport to right side of screen
	jal	clear_sprite
	addi	$t6, $t6, -3	# move ship to left by 3
	li	$v0, 1
	j	exit_check
	
right:	move	$a2, $zero	# make color black
	li	$a3, 1		# prepare "draw_pixel" for using black pixels
	beq	$t6, 54, right_border_check # allow ship to teleport to left side of screen
	jal	clear_sprite
	addi	$t6, $t6, 3	# move ship to right by 3
	li	$v0, 1
	j	exit_check

fire:	jal	fire_laser
	j	exit_check

start_game:
	# tells main function to start the game
	li	$v1, 1
	j	exit_check

left_border_check:
	jal	clear_sprite
	li	$v0, 1
	addi	$t6, $t6, 51	# if you go too far left, will teleport you to right side
	j	exit_check
	
right_border_check:
	jal	clear_sprite
	li	$v0, 1
	addi	$t6, $t6, -51 # if you go too far right, will teleport you to left side
	j	exit_check

exit_check:
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra


#################################################
# This function updates the position of the player.
# Will draw the player ship sprite where $t6 (x value)
# and $t7 (y value) point to.
update_position:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	beq	$a0, 0, finish_update
	move	$a0, $t6
	move	$a1, $t7
	move	$a3, $zero
	jal	draw_sprite
	
finish_update:
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra


#################################################
# This function will delete a sprite from the screen.
clear_sprite:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	li	$s3, 0		# variable to keep track of number of pixels (9x9, 81 in all)
	li	$t0, 1		# variable to go to next row after every 9 pixels cleared
	move	$a0, $t6
	move	$a1, $t7
clear_loop:
	jal	draw_pixel
	addi	$a0, $a0, 1
	addi	$s3, $s3, 1
	addi	$t0, $t0, 1
	beq	$s3, 81, exit_clear
	beq	$t0, 10, coords_reset	# prepare to move to next row
	j	clear_loop
	
coords_reset:
	addi	$a0, $a0, -9	# go to starting column on left of the sprite being cleared
	addi	$a1, $a1, 1	# go to next row below
	li	$t0, 1		# say we are at the start of a new row
	j	clear_loop
	
exit_clear:
	move	$a0, $t6
	move	$a1, $t7
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra


#################################################
# This function will draw any 9x9 sprite onto the
# screen.
# Sprites have an "origin" where the drawing starts
# at. This origin is at the top left corner of the sprite.
# The algorithm draws from left to right, then moves down
# to the next row.
# $a0 = x initial
# $a1 = y initial
draw_sprite:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	li	$s3, 0
	li	$t0, 1
draw_loop:
	jal	draw_pixel
	addi	$a2, $a2, 4
	addi	$a0, $a0, 1
	addi	$s3, $s3, 1	# keep track of how many pixels have been drawn
	addi	$t0, $t0, 1
	beq	$s3, 81, exit_draw
	beq	$t0, 10, reset_coords	# reset after each row completed
	j	draw_loop
	
reset_coords:
	addi	$a0, $a0, -9	# move to starting column on left
	addi	$a1, $a1, 1	# move down to next row
	li	$t0, 1		# say we are now at starting column
	j	draw_loop

exit_draw:
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra


#################################################
# This function will grab the pixel information for 
# each one of the sprites from the BMP files.
# There are four sprites:
# player ship, enemy ship, explosion, and easter egg
fetch_sprite:
	addi	$sp, $sp, -8
	sw	$ra, 4($sp)
	sw	$a1, ($sp)
	
	# open bmp file
	li	$v0, 13
	li	$a1, 0
	li	$a2, 0
	syscall
	move	$s0, $v0
	
	# read from file into a buffer
	li	$v0, 14
	move	$a0, $s0
	la	$a1, file_buffer
	li	$a2, 306	# buffer limit
	syscall
	
	# close bmp file
	li	$v0, 16
	move	$a0, $s0
	syscall
	
	# load address
	lw	$a1, ($sp)	# retrieve address of the start of where pixel data
				# will be stored from off the stack
	addi	$sp, $sp, 4
	
	move	$s1, $zero	# initialize counter to keep track of how many pixels we have
	la	$a0, file_buffer
	li	$t9, 9		# constant used to divide pixel number and find remainder
	move	$t8, $zero
	addi	$a0, $a0, 54 	# point to the spot in the file buffer where the first pixel is

sort_data:
	lbu	$t2, ($a0) 	# load pixel color data from the buffer
	sb	$t2, ($a1)	# store that data in a new memory location (ex: ship, enemy, explosion, among_us (easter egg))
	addi	$a0, $a0, 1	# move to next byte
	addi	$a1, $a1, 1	# move to next byte
	
	lbu	$t2, ($a0) 	# load pixel color data from the buffer
	sb	$t2, ($a1)	# store that data in a new memory location
	addi	$a0, $a0, 1	# move to next byte
	addi	$a1, $a1, 1	# move to next byte
	
	lbu	$t2, ($a0) 	# load pixel color data from the buffer
	sb	$t2, ($a1)	# store that data in a new memory location
	addi	$a0, $a0, 1	# move to next byte
	addi	$a1, $a1, 1	# move to next byte

	addi	$a1, $a1, 1	# increment by 1 byte (because colors are only 24 bit not 32 bit)
	
	addi	$s1, $s1, 1	# add 1 to pixel count
	
	div	$s1, $t9	# $s1 / 9
	mfhi	$t8	# move the remainder into $t8
	beq	$t8, 0, ignore	# if $s1 / 9 's remainder was zero, branch
	beq	$s1, 80, exit_loop
	j	sort_data

ignore:
	addi	$a0, $a0, 1	# move to next byte in the buffer; I do this because
				# for some reason there is a "dummy" byte every 27 bytes
				# in a bmp file's pixel data
	j	sort_data

exit_loop:
	# load in last bit of data from the file buffer
	lbu	$t2, ($a0)
	sb	$t2, ($a1)
	addi	$a0, $a0, 1
	addi	$a1, $a1, 1
	
	lbu	$t2, ($a0)
	sb	$t2, ($a1)
	addi	$a0, $a0, 1
	addi	$a1, $a1, 1
	
	lbu	$t2, ($a0)
	sb	$t2, ($a1)
	addi	$a0, $a0, 1
	addi	$a1, $a1, 1

	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra


#################################################
# This function draws the blue game border around
# the edges of the screen.
# $a0 = initial x value
# $a1 = initial y value
# $a2 = color
draw_border:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)

border_top:
	jal	draw_pixel
	beq	$a0, 63, border_right
	addi	$a0, $a0, 1
	j	border_top

border_right:
	addi	$a1, $a1, 1
	jal	draw_pixel
	beq	$a1, 127, border_bottom
	j	border_right

border_bottom:
	addi	$a0, $a0, -1
	jal	draw_pixel
	beq	$a0, 0, border_left
	j	border_bottom

border_left:
	addi	$a1, $a1, -1
	jal	draw_pixel
	beq	$a1, 1, border_exit
	j	border_left

border_exit:
	lw	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra


#################################################
# This function draws a pixel to the screen.
# $a0 = X
# $a1 = Y
# $a2 = color
draw_pixel:
	# s1 = address = $gp + 4*(x + y*width)
	mul	$s1, $a1, WIDTH # y * WIDTH
	add	$s1, $s1, $a0	  # add X
	mul	$s1, $s1, 4	  # multiply by 4 to get word offset
	add	$s1, $s1, $gp	  # add to base address
	beq	$a3, 1, set_black	# $a3 is the flag to set $a2 to a word instead of an address
	lw	$s2, ($a2)
store_color:
	sw	$s2, ($s1)	  # store color at memory location
	jr 	$ra

set_black:
	move	$s2, $a2
	j	store_color
