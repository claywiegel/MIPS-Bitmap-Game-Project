# MIPS-Bitmap-Game-Project
"Galactic Attack" is a Galaga-esque game created in the MIPS assembly language.

INSTRUCTIONS TO LAUNCH

For this program, there are five files in total: one assembly file with all the code and four bmp files. For convenience, I recommend placing all the files into one folder. Next, open the “Bitmap Project.asm” file in MARS. Starting at line 23, fill in the file paths in each of the four strings (ship_file, enemy_file, explode_file, impos_file). For example, on my computer, for ship_file my string was “C:\\...\Desktop\Bitmap Project\ship.bmp". Put in the file path for your computer, and make sure to use double backward slashes. Do exactly this for all four strings.
The next thing to do is the setup the Bitmap Display. For that, the settings are:

- Unit Width in Pixels: 4
- Unit Height in Pixels: 4
- Display Width in Pixels: 256
- Display Height in Pixels: 512
- Base address for display: 0x10008000 ($gp)

Finally, open the Keyboard Simulator and connect it to MIPS. Start the program. Once the blue border and player ship appear on the bitmap, type a single lowercase “p” into the keyboard simulator. This will start the game!

ADDITIONAL INFORMATION

My program uses bitmap image files. I wanted to use this file format because I wanted my sprites to be modular. In theory, if you have any 9x9 sprite stored in a bmp file, my program should be able to open it up, parse its data, store the pixel colors in memory, and display the sprites to the screen. A fair warning: sprite designs should be stored in the bmp file upside down. My program reads the pixel data from the bottom up, so that is why all of my sprites (the ship, for example) are upside down.

WARNINGS

During playtesting, I never had MARS seize up to where I needed Task Manager to close the IDE. However, this may happen when holding down an input key in the Keyboard Simulator.
Another thing is that there is an easter egg. While the game is running, if you enter in a lowercase “i", it will trigger the easter egg. The game will then draw a character from the popular video game Among Us onto the screen and play the theme song through the speakers. Once that’s done, the program will deliberately end. It’s an incredibly silly easter egg, but I thought it would be fun to have at least one easter egg in the game.
