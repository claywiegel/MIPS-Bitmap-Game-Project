# MIPS-Bitmap-Game-Project
A Galaga-esque game created in the MIPS assembly language.

INSTRUCTIONS TO LAUNCH
For this program, there are five files in total: one assembly file with all the code and four bmp files. For convenience, I recommend placing all the files into one folder. Next, open the “Bitmap Project.asm” file in MARS. Starting at line 23, fill in the file paths in each of the four strings (ship_file, enemy_file, explode_file, impos_file). For example, on my computer, for ship_file my string was “C:\\Users\\cwieg\\Desktop\\Bitmap Project\\ship.bmp". Put in the file path for your computer, and make sure to use double backward slashes. Do exactly this for all four strings.
The next thing to do is the setup the Bitmap Display. For that, the settings are:

- Unit Width in Pixels: 4
- Unit Height in Pixels: 4
- Display Width in Pixels: 256
- Display Height in Pixels: 512
- Base address for display: 0x10008000 ($gp)

Finally, open the Keyboard Simulator and connect it to MIPS. Start the program. Once the blue border and player ship appear on the bitmap, type a single lowercase “p” into the keyboard simulator. This will start the game!
