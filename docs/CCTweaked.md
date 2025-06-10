# Comprehensive CC:Tweaked Documentation

**Base URL:** https://tweaked.cc/

## 🚨 CRITICAL DEVELOPMENT REQUIREMENTS 🚨

### **1. Always Check Official Documentation**
**NEVER implement CC:Tweaked functionality without consulting the official docs first.**

### **2. Lua Version Compatibility** 
**CC:Tweaked uses Lua 5.2 with select Lua 5.3 features.**
- **Compatibility Guide**: https://tweaked.cc/reference/feature_compat.html
- **MUST VERIFY** any advanced Lua syntax before using
- **Available Lua 5.3 features**: UTF-8 basics, integer division (//), bitwise operators (&, |, ~, <<, >>)
- **NOT available**: Full UTF-8 library, some string patterns, certain metamethods

### **3. Breaking Changes Awareness**
- **Version Differences**: https://tweaked.cc/reference/breaking_changes.html
- **Check compatibility** when targeting specific CC:Tweaked versions

---

# Global APIs/Modules

## Core System APIs

### **_G** - Global Environment Functions
Functions in the global environment, defined in bios.lua. This does not include standard Lua functions.

#### Functions:

**`sleep(time)`**
- **Description**: Pauses execution for the specified number of seconds
- **Parameters**: `time` (number) - The number of seconds to sleep for, rounded up to the nearest multiple of 0.05
- **Notes**: 
  - Uses timers internally, can prevent "Too long without yielding" errors
  - Minimum sleep time is 0.05 seconds
  - Only pauses current thread in parallel environments
  - Discards any events that occur while sleeping

**`write(text)`**
- **Description**: Writes a line of text to the screen without a newline at the end, wrapping text if necessary
- **Parameters**: `text` (string) - The text to write to the string
- **Returns**: `number` - The number of lines written

**`print(...)`**
- **Description**: Prints the specified values to the screen separated by spaces, wrapping if necessary. After printing, the cursor is moved to the next line
- **Parameters**: `...` - The values to print on the screen
- **Returns**: `number` - The number of lines written

**`printError(...)`**
- **Description**: Prints the specified values to the screen in red, separated by spaces, wrapping if necessary
- **Parameters**: `...` - The values to print on the screen

**`read([replaceChar [, history [, completeFn [, default]]]])`**
- **Description**: Reads user input from the terminal with support for history, completion, and character replacement
- **Parameters**:
  - `replaceChar?` (string) - A character to replace each typed character with (e.g., "*" for passwords)
  - `history?` (table) - A table holding history items for scrollback
  - `completeFn?` (function) - A function for auto-completion
  - `default?` (string) - Default text to pre-fill
- **Returns**: `string` - The text typed in

#### Constants:

**`_HOST`**
- **Description**: Stores the current ComputerCraft and Minecraft versions
- **Example**: "ComputerCraft 1.93.0 (Minecraft 1.15.2)"

**`_CC_DEFAULT_SETTINGS`**
- **Description**: The default computer settings as defined in the ComputerCraft configuration
- **Example**: "shell.autocomplete=false,lua.autocomplete=false,edit.autocomplete=false"

---

### **os** - Operating System API
The os API allows interacting with the current computer, including event handling, timers, and computer information.

#### System Management:

**`os.version()`**
- **Description**: Get the current CraftOS version
- **Returns**: `string` - The current CraftOS version (e.g., "CraftOS 1.9")

**`os.getComputerID()` / `os.computerID()`**
- **Description**: Returns the ID of the computer
- **Returns**: `number` - The ID of the computer

**`os.getComputerLabel()` / `os.computerLabel()`**
- **Description**: Returns the label of the computer, or nil if none is set
- **Returns**: `string | nil` - The label of the computer

**`os.setComputerLabel([label])`**
- **Description**: Set the label of this computer
- **Parameters**: `label?` (string) - The new label. May be nil to clear it

**`os.shutdown()`**
- **Description**: Shuts down the computer immediately

**`os.reboot()`**
- **Description**: Reboots the computer immediately

#### Event Handling:

**`os.pullEvent([filter])`**
- **Description**: Pause execution and wait for events matching filter. Terminates on "terminate" event
- **Parameters**: `filter?` (string) - Event to filter for
- **Returns**: `string, ...` - Event name and optional additional parameters

**`os.pullEventRaw([filter])`**
- **Description**: Like pullEvent, but doesn't terminate on "terminate" event
- **Parameters**: `filter?` (string) - Event to filter for
- **Returns**: `string, ...` - Event name and optional additional parameters

**`os.queueEvent(name, ...)`**
- **Description**: Adds an event to the event queue
- **Parameters**: 
  - `name` (string) - The name of the event to queue
  - `...` - The parameters of the event

#### Timers and Alarms:

**`os.startTimer(time)`**
- **Description**: Starts a timer that will run for the specified number of seconds
- **Parameters**: `time` (number) - The number of seconds until the timer fires
- **Returns**: `number` - The ID of the new timer
- **Notes**: Time rounded up to nearest 0.05 seconds

**`os.cancelTimer(token)`**
- **Description**: Cancels a timer previously started with startTimer
- **Parameters**: `token` (number) - The ID of the timer to cancel

**`os.setAlarm(time)`**
- **Description**: Sets an alarm that will fire at the specified in-game time
- **Parameters**: `time` (number) - The time at which to fire the alarm, in the range [0.0, 24.0)
- **Returns**: `number` - The ID of the new alarm

**`os.cancelAlarm(token)`**
- **Description**: Cancels an alarm previously started with setAlarm
- **Parameters**: `token` (number) - The ID of the alarm to cancel

#### Time Functions:

**`os.clock()`**
- **Description**: Returns the number of seconds that the computer has been running
- **Returns**: `number` - The computer's uptime

**`os.time([locale])`**
- **Description**: Returns the current time depending on the string passed in
- **Parameters**: `locale?` (string | table) - The locale of the time ("ingame", "utc", "local")
- **Returns**: `any` - The hour of the selected locale
- **Notes**: Always in range [0.0, 24.0)

**`os.day([args])`**
- **Description**: Returns the day depending on the locale specified
- **Parameters**: `args?` (string) - The locale to get the day for
- **Returns**: `number` - The day depending on the selected locale

**`os.epoch([args])`**
- **Description**: Returns the number of milliseconds since an epoch depending on the locale
- **Parameters**: `args?` (string) - The locale to get the milliseconds for
- **Returns**: `number` - The milliseconds since the epoch

**`os.date([format [, time]])`**
- **Description**: Returns a date string (or table) using a specified format string
- **Parameters**: 
  - `format?` (string) - The format of the string to return
  - `time?` (number) - The timestamp to convert to a string
- **Returns**: `any` - The resulting formatted string, or table

#### Program Execution:

**`os.run(env, path, ...)`**
- **Description**: Run the program at the given path with the specified environment and arguments
- **Parameters**: 
  - `env` (table) - The environment to run the program with
  - `path` (string) - The exact path of the program to run
  - `...` - The arguments to pass to the program
- **Returns**: `boolean` - Whether or not the program ran successfully

#### Deprecated Functions:

**`os.loadAPI(path)`** *(Deprecated)*
- **Description**: Loads the given API into the global environment
- **Note**: Use `require` instead

**`os.unloadAPI(name)`** *(Deprecated)*
- **Description**: Unloads an API which was loaded by os.loadAPI
- **Note**: See os.loadAPI for why this is deprecated

---

### **term** - Terminal API
Interact with a computer's terminal or monitors, writing text and drawing ASCII graphics.

#### Basic Text Operations:

**`term.write(text)`**
- **Description**: Write text at the current cursor position, moving the cursor to the end of the text
- **Parameters**: `text` (string) - The text to write
- **Notes**: Does not wrap text or add newlines

**`term.scroll(y)`**
- **Description**: Move all positions up (or down) by y pixels
- **Parameters**: `y` (number) - The number of lines to move up by (negative for down)

#### Cursor Management:

**`term.getCursorPos()`**
- **Description**: Get the position of the cursor
- **Returns**: `number, number` - The x position and y position of the cursor

**`term.setCursorPos(x, y)`**
- **Description**: Set the position of the cursor
- **Parameters**: 
  - `x` (number) - The new x position of the cursor
  - `y` (number) - The new y position of the cursor

**`term.getCursorBlink()`**
- **Description**: Checks if the cursor is currently blinking
- **Returns**: `boolean` - If the cursor is blinking

**`term.setCursorBlink(blink)`**
- **Description**: Sets whether the cursor should be visible (and blinking)
- **Parameters**: `blink` (boolean) - Whether the cursor should blink

#### Display Management:

**`term.getSize()`**
- **Description**: Get the size of the terminal
- **Returns**: `number, number` - The terminal's width and height

**`term.clear()`**
- **Description**: Clears the terminal, filling it with the current background colour

**`term.clearLine()`**
- **Description**: Clears the line the cursor is currently on, filling it with the current background colour

#### Color Functions:

**`term.getTextColour()` / `term.getTextColor()`**
- **Description**: Return the colour that new text will be written as
- **Returns**: `number` - The current text colour

**`term.setTextColour(colour)` / `term.setTextColor(colour)`**
- **Description**: Set the colour that new text will be written as
- **Parameters**: `colour` (number) - The new text colour

**`term.getBackgroundColour()` / `term.getBackgroundColor()`**
- **Description**: Return the current background colour
- **Returns**: `number` - The current background colour

**`term.setBackgroundColour(colour)` / `term.setBackgroundColor(colour)`**
- **Description**: Set the current background colour
- **Parameters**: `colour` (number) - The new background colour

**`term.isColour()` / `term.isColor()`**
- **Description**: Determine if this terminal supports colour
- **Returns**: `boolean` - Whether this terminal supports colour

#### Advanced Text Functions:

**`term.blit(text, textColour, backgroundColour)`**
- **Description**: Writes text to the terminal with specific foreground and background colours
- **Parameters**: 
  - `text` (string) - The text to write
  - `textColour` (string) - The corresponding text colours (hex string)
  - `backgroundColour` (string) - The corresponding background colours (hex string)
- **Notes**: All three strings must be the same length

#### Palette Functions:

**`term.setPaletteColour(index, colour)` / `term.setPaletteColor(...)`**
- **Description**: Set the palette for a specific colour
- **Parameters**: 
  - `index` (number) - The colour whose palette should be changed
  - `colour` (number) - A 24-bit integer representing the RGB value
- **Alternative signature**: `(index, r, g, b)` where r, g, b are intensities between 0 and 1

**`term.getPaletteColour(colour)` / `term.getPaletteColor(colour)`**
- **Description**: Get the current palette for a specific colour
- **Parameters**: `colour` (number) - The colour whose palette should be fetched
- **Returns**: `number, number, number` - The red, green, and blue channels (0-1)

**`term.nativePaletteColour(colour)` / `term.nativePaletteColor(colour)`**
- **Description**: Get the default palette value for a colour
- **Parameters**: `colour` (number) - The colour whose palette should be fetched
- **Returns**: `number, number, number` - The red, green, and blue channels (0-1)

#### Terminal Redirection:

**`term.redirect(target)`**
- **Description**: Redirects terminal output to a monitor, window, or other terminal object
- **Parameters**: `target` (Redirect) - The terminal redirect to draw to
- **Returns**: `Redirect` - The previous redirect object

**`term.current()`**
- **Description**: Returns the current terminal object of the computer
- **Returns**: `Redirect` - The current terminal redirect

**`term.native()`**
- **Description**: Get the native terminal object of the current computer
- **Returns**: `Redirect` - The native terminal redirect
- **Warning**: Use only when absolutely necessary in multitasked environments

---

### **fs** - Filesystem API
Interact with the computer's files and filesystem, allowing you to manipulate files, directories and paths.

#### File Operations:

**`fs.open(path, mode)`**
- **Description**: Open a file for reading or writing
- **Parameters**: 
  - `path` (string) - The path to the file to open
  - `mode` (string) - The mode to open the file in ("r", "w", "a", "rb", "wb", "ab")
- **Returns**: `Handle | nil` - The opened file handle, or nil if failed

**`fs.copy(from, to)`**
- **Description**: Copy a file or directory from one location to another
- **Parameters**: 
  - `from` (string) - The path to copy from
  - `to` (string) - The path to copy to

**`fs.move(from, to)`**
- **Description**: Move/rename a file or directory
- **Parameters**: 
  - `from` (string) - The current path
  - `to` (string) - The new path

**`fs.delete(path)`**
- **Description**: Delete a file or directory
- **Parameters**: `path` (string) - The path to delete

#### Directory Operations:

**`fs.list(path)`**
- **Description**: List the contents of a directory
- **Parameters**: `path` (string) - The path to list
- **Returns**: `{string...}` - A list of files and subdirectories

**`fs.makeDir(path)`**
- **Description**: Create a directory
- **Parameters**: `path` (string) - The path of the directory to create

**`fs.exists(path)`**
- **Description**: Check if a path exists
- **Parameters**: `path` (string) - The path to check
- **Returns**: `boolean` - Whether the path exists

**`fs.isDir(path)`**
- **Description**: Check if a path is a directory
- **Parameters**: `path` (string) - The path to check
- **Returns**: `boolean` - Whether the path is a directory

**`fs.isReadOnly(path)`**
- **Description**: Check if a path is read-only
- **Parameters**: `path` (string) - The path to check
- **Returns**: `boolean` - Whether the path is read-only

#### Path Utilities:

**`fs.combine(path, ...)`**
- **Description**: Combine multiple path components into a single path
- **Parameters**: `path` (string), `...` - Path components to combine
- **Returns**: `string` - The combined path

**`fs.getName(path)`**
- **Description**: Get the final component of a path
- **Parameters**: `path` (string) - The path to process
- **Returns**: `string` - The final component

**`fs.getDir(path)`**
- **Description**: Get the directory containing a path
- **Parameters**: `path` (string) - The path to process
- **Returns**: `string` - The parent directory

**`fs.getSize(path)`**
- **Description**: Get the size of a file in bytes
- **Parameters**: `path` (string) - The path to check
- **Returns**: `number` - The size in bytes

#### File System Information:

**`fs.getFreeSpace(path)`**
- **Description**: Get the remaining free space on the drive containing the given path
- **Parameters**: `path` (string) - The path to check
- **Returns**: `number` - The free space in bytes

**`fs.getCapacity(path)`**
- **Description**: Get the total capacity of the drive containing the given path
- **Parameters**: `path` (string) - The path to check
- **Returns**: `number` - The total capacity in bytes

**`fs.getDrive(path)`**
- **Description**: Get the name of the mount that contains the given path
- **Parameters**: `path` (string) - The path to check
- **Returns**: `string` - The drive name

#### Advanced Functions:

**`fs.find(pattern)`**
- **Description**: Find all files and directories matching a pattern
- **Parameters**: `pattern` (string) - The pattern to search for (supports wildcards)
- **Returns**: `{string...}` - A list of matching paths

**`fs.complete(partial, path, include_files, include_dirs)`**
- **Description**: Provides completion for a file or directory name
- **Parameters**: 
  - `partial` (string) - The partial path to complete
  - `path` (string) - The path to search in
  - `include_files` (boolean) - Whether to include files
  - `include_dirs` (boolean) - Whether to include directories
- **Returns**: `{string...}` - A list of possible completions

---

### **peripheral** - Peripheral API
Find and control peripherals attached to this computer.

#### Discovery Functions:

**`peripheral.getNames()`**
- **Description**: Provides a list of all peripherals available
- **Returns**: `{string...}` - A list of the names of all attached peripherals

**`peripheral.isPresent(name)`**
- **Description**: Determines if a peripheral is present with the given name
- **Parameters**: `name` (string) - The side or network name to check
- **Returns**: `boolean` - If a peripheral is present with the given name

**`peripheral.getType(peripheral)`**
- **Description**: Get the types of a named or wrapped peripheral
- **Parameters**: `peripheral` (string | table) - The name or wrapped peripheral
- **Returns**: `string...` - The peripheral's types, or nil if not present

**`peripheral.hasType(peripheral, peripheral_type)`**
- **Description**: Check if a peripheral is of a particular type
- **Parameters**: 
  - `peripheral` (string | table) - The name or wrapped peripheral
  - `peripheral_type` (string) - The type to check
- **Returns**: `boolean | nil` - If peripheral has the type, or nil if not present

**`peripheral.getMethods(name)`**
- **Description**: Get all available methods for the peripheral with the given name
- **Parameters**: `name` (string) - The name of the peripheral to find
- **Returns**: `{string...} | nil` - A list of methods, or nil if not present

**`peripheral.getName(peripheral)`**
- **Description**: Get the name of a peripheral wrapped with peripheral.wrap
- **Parameters**: `peripheral` (table) - The peripheral to get the name of
- **Returns**: `string` - The name of the given peripheral

#### Interaction Functions:

**`peripheral.call(name, method, ...)`**
- **Description**: Call a method on the peripheral with the given name
- **Parameters**: 
  - `name` (string) - The name of the peripheral
  - `method` (string) - The name of the method
  - `...` - Additional arguments to pass to the method
- **Returns**: The return values of the peripheral method

**`peripheral.wrap(name)`**
- **Description**: Get a table containing all functions available on a peripheral
- **Parameters**: `name` (string) - The name of the peripheral to wrap
- **Returns**: `table | nil` - The table containing the peripheral's methods, or nil if not present

**`peripheral.find(ty [, filter])`**
- **Description**: Find all peripherals of a specific type, and return the wrapped peripherals
- **Parameters**: 
  - `ty` (string) - The type of peripheral to look for
  - `filter?` (function) - A filter function for additional criteria
- **Returns**: `table...` - 0 or more wrapped peripherals matching the given filters

---

### **turtle** - Turtle API
Turtles are robotic devices that can break and place blocks, attack mobs, and move about the world.

#### Movement Functions:

**`turtle.forward()`**
- **Description**: Move the turtle forward one block
- **Returns**: `boolean, string | nil` - Whether successful and error reason if failed

**`turtle.back()`**
- **Description**: Move the turtle backwards one block
- **Returns**: `boolean, string | nil` - Whether successful and error reason if failed

**`turtle.up()`**
- **Description**: Move the turtle up one block
- **Returns**: `boolean, string | nil` - Whether successful and error reason if failed

**`turtle.down()`**
- **Description**: Move the turtle down one block
- **Returns**: `boolean, string | nil` - Whether successful and error reason if failed

**`turtle.turnLeft()`**
- **Description**: Rotate the turtle 90 degrees to the left
- **Returns**: `boolean, string | nil` - Whether successful and error reason if failed

**`turtle.turnRight()`**
- **Description**: Rotate the turtle 90 degrees to the right
- **Returns**: `boolean, string | nil` - Whether successful and error reason if failed

#### Block Interaction:

**`turtle.dig([side])`**
- **Description**: Attempt to break the block in front of the turtle
- **Parameters**: `side?` (string) - The specific tool to use ("left" or "right")
- **Returns**: `boolean, string | nil` - Whether a block was broken and error reason if failed

**`turtle.digUp([side])`**
- **Description**: Attempt to break the block above the turtle
- **Parameters**: `side?` (string) - The specific tool to use
- **Returns**: `boolean, string | nil` - Whether a block was broken and error reason if failed

**`turtle.digDown([side])`**
- **Description**: Attempt to break the block below the turtle
- **Parameters**: `side?` (string) - The specific tool to use
- **Returns**: `boolean, string | nil` - Whether a block was broken and error reason if failed

**`turtle.place([text])`**
- **Description**: Place a block or item into the world in front of the turtle
- **Parameters**: `text?` (string) - When placing a sign, set its contents to this text
- **Returns**: `boolean, string | nil` - Whether the block could be placed and error reason if failed

**`turtle.placeUp([text])`**
- **Description**: Place a block or item into the world above the turtle
- **Parameters**: `text?` (string) - When placing a sign, set its contents to this text
- **Returns**: `boolean, string | nil` - Whether the block could be placed and error reason if failed

**`turtle.placeDown([text])`**
- **Description**: Place a block or item into the world below the turtle
- **Parameters**: `text?` (string) - When placing a sign, set its contents to this text
- **Returns**: `boolean, string | nil` - Whether the block could be placed and error reason if failed

#### Detection Functions:

**`turtle.detect()`**
- **Description**: Check if there is a solid block in front of the turtle
- **Returns**: `boolean` - If there is a solid block in front

**`turtle.detectUp()`**
- **Description**: Check if there is a solid block above the turtle
- **Returns**: `boolean` - If there is a solid block above

**`turtle.detectDown()`**
- **Description**: Check if there is a solid block below the turtle
- **Returns**: `boolean` - If there is a solid block below

#### Comparison Functions:

**`turtle.compare()`**
- **Description**: Check if the block in front matches the item in the currently selected slot
- **Returns**: `boolean` - If the block and item are equal

**`turtle.compareUp()`**
- **Description**: Check if the block above matches the item in the currently selected slot
- **Returns**: `boolean` - If the block and item are equal

**`turtle.compareDown()`**
- **Description**: Check if the block below matches the item in the currently selected slot
- **Returns**: `boolean` - If the block and item are equal

**`turtle.compareTo(slot)`**
- **Description**: Compare the item in the currently selected slot to the item in another slot
- **Parameters**: `slot` (number) - The slot to compare to
- **Returns**: `boolean` - If the two items are equal

#### Inspection Functions:

**`turtle.inspect()`**
- **Description**: Get information about the block in front of the turtle
- **Returns**: `boolean, table | string` - Whether there is a block and information about it

**`turtle.inspectUp()`**
- **Description**: Get information about the block above the turtle
- **Returns**: `boolean, table | string` - Whether there is a block and information about it

**`turtle.inspectDown()`**
- **Description**: Get information about the block below the turtle
- **Returns**: `boolean, table | string` - Whether there is a block and information about it

#### Combat Functions:

**`turtle.attack([side])`**
- **Description**: Attack the entity in front of the turtle
- **Parameters**: `side?` (string) - The specific tool to use
- **Returns**: `boolean, string | nil` - Whether an entity was attacked and error reason if failed

**`turtle.attackUp([side])`**
- **Description**: Attack the entity above the turtle
- **Parameters**: `side?` (string) - The specific tool to use
- **Returns**: `boolean, string | nil` - Whether an entity was attacked and error reason if failed

**`turtle.attackDown([side])`**
- **Description**: Attack the entity below the turtle
- **Parameters**: `side?` (string) - The specific tool to use
- **Returns**: `boolean, string | nil` - Whether an entity was attacked and error reason if failed

#### Inventory Management:

**`turtle.select(slot)`**
- **Description**: Change the currently selected slot
- **Parameters**: `slot` (number) - The slot to select
- **Returns**: `true` - Always succeeds

**`turtle.getSelectedSlot()`**
- **Description**: Get the currently selected slot
- **Returns**: `number` - The current slot

**`turtle.getItemCount([slot])`**
- **Description**: Get the number of items in the given slot
- **Parameters**: `slot?` (number) - The slot to check (defaults to selected slot)
- **Returns**: `number` - The number of items in this slot

**`turtle.getItemSpace([slot])`**
- **Description**: Get the remaining number of items which may be stored in this stack
- **Parameters**: `slot?` (number) - The slot to check (defaults to selected slot)
- **Returns**: `number` - The space left in this slot

**`turtle.getItemDetail([slot [, detailed]])`**
- **Description**: Get detailed information about the items in the given slot
- **Parameters**: 
  - `slot?` (number) - The slot to get information about (defaults to selected slot)
  - `detailed?` (boolean) - Whether to include detailed information
- **Returns**: `table | nil` - Information about the item, or nil if empty

**`turtle.transferTo(slot [, count])`**
- **Description**: Move an item from the selected slot to another one
- **Parameters**: 
  - `slot` (number) - The slot to move this item to
  - `count?` (number) - The maximum number of items to move
- **Returns**: `boolean` - If some items were successfully moved

#### Item Transfer Functions:

**`turtle.drop([count])`**
- **Description**: Drop the currently selected stack into the inventory in front of the turtle
- **Parameters**: `count?` (number) - The number of items to drop
- **Returns**: `boolean, string | nil` - Whether items were dropped and error reason if failed

**`turtle.dropUp([count])`**
- **Description**: Drop the currently selected stack into the inventory above the turtle
- **Parameters**: `count?` (number) - The number of items to drop
- **Returns**: `boolean, string | nil` - Whether items were dropped and error reason if failed

**`turtle.dropDown([count])`**
- **Description**: Drop the currently selected stack into the inventory below the turtle
- **Parameters**: `count?` (number) - The number of items to drop
- **Returns**: `boolean, string | nil` - Whether items were dropped and error reason if failed

**`turtle.suck([count])`**
- **Description**: Suck an item from the inventory in front of the turtle
- **Parameters**: `count?` (number) - The number of items to suck
- **Returns**: `boolean, string | nil` - Whether items were picked up and error reason if failed

**`turtle.suckUp([count])`**
- **Description**: Suck an item from the inventory above the turtle
- **Parameters**: `count?` (number) - The number of items to suck
- **Returns**: `boolean, string | nil` - Whether items were picked up and error reason if failed

**`turtle.suckDown([count])`**
- **Description**: Suck an item from the inventory below the turtle
- **Parameters**: `count?` (number) - The number of items to suck
- **Returns**: `boolean, string | nil` - Whether items were picked up and error reason if failed

#### Fuel Management:

**`turtle.getFuelLevel()`**
- **Description**: Get the maximum amount of fuel this turtle currently holds
- **Returns**: `number | "unlimited"` - The current amount of fuel

**`turtle.getFuelLimit()`**
- **Description**: Get the maximum amount of fuel this turtle can hold
- **Returns**: `number | "unlimited"` - The maximum fuel capacity
- **Notes**: Normal turtles: 20,000, Advanced turtles: 100,000

**`turtle.refuel([count])`**
- **Description**: Refuel this turtle
- **Parameters**: `count?` (number) - The maximum number of items to consume
- **Returns**: `boolean, string | nil` - Whether refueling succeeded and error reason if failed

#### Equipment Management:

**`turtle.equipLeft()`**
- **Description**: Equip (or unequip) an item on the left side of this turtle
- **Returns**: `boolean, string | nil` - Whether the item was equipped and error reason if failed

**`turtle.equipRight()`**
- **Description**: Equip (or unequip) an item on the right side of this turtle
- **Returns**: `boolean, string | nil` - Whether the item was equipped and error reason if failed

**`turtle.getEquippedLeft()`**
- **Description**: Get the upgrade currently equipped on the left of the turtle
- **Returns**: `table | nil` - Information about the equipped item, or nil if none

**`turtle.getEquippedRight()`**
- **Description**: Get the upgrade currently equipped on the right of the turtle
- **Returns**: `table | nil` - Information about the equipped item, or nil if none

#### Crafting:

**`turtle.craft([limit=64])`**
- **Description**: Craft a recipe based on the turtle's inventory
- **Parameters**: `limit?` (number) - The maximum number of crafting steps to run (default 64)
- **Returns**: `boolean, string | nil` - Whether crafting succeeded and error reason if failed
- **Notes**: Turtle's inventory should be set up like a crafting grid

---

### **redstone** - Redstone API
Functions for interacting with redstone signals.

#### Basic Redstone:

**`redstone.getSides()`**
- **Description**: Returns a table containing the six sides of the computer
- **Returns**: `{string...}` - A table of side names

**`redstone.getInput(side)`**
- **Description**: Get the redstone input signal on a specific side
- **Parameters**: `side` (string) - The side to check
- **Returns**: `boolean` - Whether the redstone input is on

**`redstone.setOutput(side, on)`**
- **Description**: Turn the redstone signal of a specific side on or off
- **Parameters**: 
  - `side` (string) - The side to set
  - `on` (boolean) - Whether the redstone signal should be on

**`redstone.getOutput(side)`**
- **Description**: Get the current redstone output of a specific side
- **Parameters**: `side` (string) - The side to get the output of
- **Returns**: `boolean` - Whether the redstone output is on

#### Analog Redstone:

**`redstone.getAnalogueInput(side)` / `redstone.getAnalogInput(side)`**
- **Description**: Get the redstone input signal strength for a specific side
- **Parameters**: `side` (string) - The side to check
- **Returns**: `number` - The input signal strength (0-15)

**`redstone.setAnalogueOutput(side, value)` / `redstone.setAnalogOutput(side, value)`**
- **Description**: Set the redstone signal strength for a specific side
- **Parameters**: 
  - `side` (string) - The side to set
  - `value` (number) - The signal strength to set (0-15)

**`redstone.getAnalogueOutput(side)` / `redstone.getAnalogOutput(side)`**
- **Description**: Get the current redstone output signal strength for a specific side
- **Parameters**: `side` (string) - The side to get the output of
- **Returns**: `number` - The output signal strength (0-15)

#### Bundled Cables:

**`redstone.setBundledOutput(side, colors)`**
- **Description**: Set the bundled cable output for a specific side
- **Parameters**: 
  - `side` (string) - The side to set
  - `colors` (number) - The color channels to set

**`redstone.getBundledOutput(side)`**
- **Description**: Get the bundled cable output for a specific side
- **Parameters**: `side` (string) - The side to get the output of
- **Returns**: `number` - The bundled cable output

**`redstone.getBundledInput(side)`**
- **Description**: Get the bundled cable input for a specific side
- **Parameters**: `side` (string) - The side to check
- **Returns**: `number` - The bundled cable input

**`redstone.testBundledInput(side, colors)`**
- **Description**: Determine if a specific combination of colours are on for the given side
- **Parameters**: 
  - `side` (string) - The side to test
  - `colors` (number) - The color combination to test for
- **Returns**: `boolean` - Whether the colors are on

---

### **colors** / **colours** - Color API
Constants and functions for colour values, suitable for working with term and redstone.

#### Color Constants:
- **`colors.white`** / **`colours.white`** = 1
- **`colors.orange`** / **`colours.orange`** = 2
- **`colors.magenta`** / **`colours.magenta`** = 4
- **`colors.lightBlue`** / **`colours.lightBlue`** = 8
- **`colors.yellow`** / **`colours.yellow`** = 16
- **`colors.lime`** / **`colours.lime`** = 32
- **`colors.pink`** / **`colours.pink`** = 64
- **`colors.gray`** / **`colours.grey`** = 128
- **`colors.lightGray`** / **`colours.lightGrey`** = 256
- **`colors.cyan`** / **`colours.cyan`** = 512
- **`colors.purple`** / **`colours.purple`** = 1024
- **`colors.blue`** / **`colours.blue`** = 2048
- **`colors.brown`** / **`colours.brown`** = 4096
- **`colors.green`** / **`colours.green`** = 8192
- **`colors.red`** / **`colours.red`** = 16384
- **`colors.black`** / **`colours.black`** = 32768

#### Color Functions:

**`colors.combine(...)`**
- **Description**: Combines a set of colors (or sets of colors) into a larger set
- **Parameters**: `...` - The colors to combine
- **Returns**: `number` - The combined color set

**`colors.subtract(colors, ...)`**
- **Description**: Removes one or more colors from an initial set
- **Parameters**: 
  - `colors` (number) - The initial set of colors
  - `...` - The colors to remove
- **Returns**: `number` - The resulting color set

**`colors.test(colors, color)`**
- **Description**: Tests whether color is contained within colors
- **Parameters**: 
  - `colors` (number) - The set of colors to test
  - `color` (number) - The color to test for
- **Returns**: `boolean` - Whether the color is in the set

**`colors.packRGB(r, g, b)`**
- **Description**: Combine a three-colour RGB value into one hexadecimal representation
- **Parameters**: 
  - `r` (number) - The red channel, should be between 0 and 1
  - `g` (number) - The green channel, should be between 0 and 1
  - `b` (number) - The blue channel, should be between 0 and 1
- **Returns**: `number` - The combined color as a 24-bit integer

**`colors.unpackRGB(rgb)`**
- **Description**: Separate a packed RGB color into its three channels
- **Parameters**: `rgb` (number) - The 24-bit color value
- **Returns**: `number, number, number` - The red, green, and blue channels

**`colors.rgb8(r, g, b)`**
- **Description**: Combine three 8-bit RGB values into a single color
- **Parameters**: 
  - `r` (number) - The red channel (0-255)
  - `g` (number) - The green channel (0-255)  
  - `b` (number) - The blue channel (0-255)
- **Returns**: `number` - The combined color

**`colors.toBlit(color)`**
- **Description**: Convert a color value to its single-character hex representation
- **Parameters**: `color` (number) - The color to convert
- **Returns**: `string` - The hex character for this color

---

## Display and Text Processing APIs

### **paintutils** - Painting Utilities
Utilities for drawing and painting on screens.

**`paintutils.parseImage(image)`**
- **Description**: Parse an image string into a table of pixels
- **Parameters**: `image` (string) - The image data
- **Returns**: `table` - A 2D array of pixel data

**`paintutils.loadImage(path)`**
- **Description**: Load an image from a file
- **Parameters**: `path` (string) - Path to the image file
- **Returns**: `table` - A 2D array of pixel data

**`paintutils.drawPixel(x, y, [color])`**
- **Description**: Draw a single pixel
- **Parameters**: 
  - `x` (number) - The x coordinate
  - `y` (number) - The y coordinate
  - `color?` (number) - The color to draw with

**`paintutils.drawLine(startX, startY, endX, endY, [color])`**
- **Description**: Draw a line between two points
- **Parameters**: 
  - `startX` (number) - The starting x coordinate
  - `startY` (number) - The starting y coordinate
  - `endX` (number) - The ending x coordinate
  - `endY` (number) - The ending y coordinate
  - `color?` (number) - The color to draw with

**`paintutils.drawBox(startX, startY, endX, endY, [color])`**
- **Description**: Draw a filled rectangle
- **Parameters**: 
  - `startX` (number) - The starting x coordinate
  - `startY` (number) - The starting y coordinate
  - `endX` (number) - The ending x coordinate
  - `endY` (number) - The ending y coordinate
  - `color?` (number) - The color to draw with

**`paintutils.drawFilledBox(startX, startY, endX, endY, [color])`**
- **Description**: Draw a filled rectangle (alias for drawBox)

**`paintutils.drawImage(image, xPos, yPos)`**
- **Description**: Draw an image onto the screen
- **Parameters**: 
  - `image` (table) - The image data to draw
  - `xPos` (number) - The x position to draw at
  - `yPos` (number) - The y position to draw at

## **textutils** - Text Utilities
Helpful utilities for formatting and manipulating strings.

#### Serialization Functions:

**`textutils.serialize(t, [opts])` / `textutils.serialise(t, [opts])`**
- **Description**: Convert a table or value into a string representation
- **Parameters**: 
  - `t` (any) - The value to serialize
  - `opts?` (table) - Serialization options
- **Returns**: `string` - The serialized representation
- **Options**:
  - `compact` (boolean) - Do not emit indentation and whitespace between terms
  - `allow_repetitions` (boolean) - Relax check for recursive tables

**`textutils.unserialize(s)` / `textutils.unserialise(s)`**
- **Description**: Convert a serialized string back into a value
- **Parameters**: `s` (string) - The string to unserialize
- **Returns**: `any` - The unserialized value, or nil if invalid

**`textutils.serializeJSON(t, [opts])` / `textutils.serialiseJSON(t, [opts])`**
- **Description**: Convert a table into JSON format
- **Parameters**: 
  - `t` (any) - The value to serialize
  - `opts?` (table) - JSON serialization options
- **Returns**: `string` - The JSON representation
- **Options**:
  - `unicode_strings` (boolean) - Treat input strings as UTF-8
- **Notes**: 
  - Tables with only numeric keys become arrays
  - Tables with string keys become objects
  - Non-string keys are dropped
  - Empty tables become objects (use `textutils.empty_json_array` for empty arrays)

**`textutils.unserializeJSON(s, [opts])` / `textutils.unserialiseJSON(s, [opts])`**
- **Description**: Convert a JSON string back into a value
- **Parameters**: 
  - `s` (string) - The JSON string to parse
  - `opts?` (table) - JSON parsing options
- **Returns**: `any` - The parsed value, or nil if invalid

#### Special JSON Constants:

**`textutils.empty_json_array`**
- **Description**: A table representing an empty JSON array (to distinguish from empty object)
- **Usage**: `textutils.serialiseJSON(textutils.empty_json_array)` produces `[]`

**`textutils.json_null`**
- **Description**: A table representing the JSON null value

#### URL Encoding:

**`textutils.urlEncode(str)`**
- **Description**: Encode a string for use in a URL
- **Parameters**: `str` (string) - The string to encode
- **Returns**: `string` - The URL-encoded string

#### Text Formatting:

**`textutils.formatTime(time, [twentyFourHour])`**
- **Description**: Format a time value into a readable string
- **Parameters**: 
  - `time` (number) - The time to format (as provided by os.time)
  - `twentyFourHour?` (boolean) - Whether to use 24-hour format (default false)
- **Returns**: `string` - The formatted time string
- **Example**: `textutils.formatTime(6.5)` returns `"6:30 AM"`

**`textutils.tabulate(...)`**
- **Description**: Print tables in a tabular format
- **Parameters**: `...` - Tables to display (alternating colors and data)
- **Notes**: Prints directly to the terminal

**`textutils.pagedTabulate(...)`**
- **Description**: Print tables in a paginated tabular format
- **Parameters**: `...` - Tables to display (alternating colors and data)
- **Notes**: Prints with pagination controls using "Press any key to continue"

**`textutils.slowWrite(text, [rate])`**
- **Description**: Write text character by character with a delay
- **Parameters**: 
  - `text` (string) - The text to write
  - `rate?` (number) - The delay between characters (default 20)

**`textutils.slowPrint(text, [rate])`**
- **Description**: Print text character by character with a delay
- **Parameters**: 
  - `text` (string) - The text to print
  - `rate?` (number) - The delay between characters (default 20)

**`textutils.pagedPrint(text, [freeLines])`**
- **Description**: Print text with pagination if it doesn't fit on screen
- **Parameters**: 
  - `text` (string) - The text to print
  - `freeLines?` (number) - Number of free lines before pagination

#### Text Processing:

**`textutils.complete(text, options)`**
- **Description**: Complete a partial string with possible options
- **Parameters**: 
  - `text` (string) - The partial text
  - `options` (table) - Table of possible completions
- **Returns**: `{string...}` - Matching completions

**Example Usage**:
```lua
-- Serialization
local data = {name = "John", age = 25, hobbies = {"reading", "coding"}}
local serialized = textutils.serialize(data)
print(serialized)
local restored = textutils.unserialize(serialized)

-- JSON
local json = textutils.serializeJSON(data)
print(json) -- {"name":"John","age":25,"hobbies":["reading","coding"]}

-- Time formatting
print(textutils.formatTime(14.5, true))  -- "14:30"
print(textutils.formatTime(14.5, false)) -- "2:30 PM"

-- URL encoding
local encoded = textutils.urlEncode("hello world!")
print(encoded) -- "hello%20world%21"

-- Slow text effects
textutils.slowWrite("Loading...")
textutils.slowPrint("Complete!", 10)
```

---

## Networking and Communication APIs

### **http** - HTTP Client API
Make HTTP requests, sending and receiving data to a remote web server.

#### Basic HTTP Functions:

**`http.get(url, [headers], [binary])`**
- **Description**: Make a GET request to the specified URL
- **Parameters**: 
  - `url` (string) - The URL to request
  - `headers?` (table) - Additional headers to send
  - `binary?` (boolean) - Whether to download in binary mode
- **Returns**: `Response | nil` - The response object, or nil if failed

**`http.post(url, postData, [headers], [binary])`**
- **Description**: Make a POST request to the specified URL
- **Parameters**: 
  - `url` (string) - The URL to request
  - `postData` (string | table) - The data to send
  - `headers?` (table) - Additional headers to send
  - `binary?` (boolean) - Whether to download in binary mode
- **Returns**: `Response | nil` - The response object, or nil if failed

**`http.request(url, [postData], [headers], [binary])`**
- **Description**: Make an asynchronous HTTP request
- **Parameters**: 
  - `url` (string) - The URL to request
  - `postData?` (string | table) - The data to send for POST requests
  - `headers?` (table) - Additional headers to send
  - `binary?` (boolean) - Whether to download in binary mode
- **Notes**: Use os.pullEvent to wait for http_success or http_failure events

#### WebSocket Functions:

**`http.websocket(url, [headers])`**
- **Description**: Open a WebSocket connection
- **Parameters**: 
  - `url` (string) - The WebSocket URL to connect to
  - `headers?` (table) - Additional headers to send
- **Returns**: `WebSocket | nil` - The WebSocket object, or nil if failed

**`http.websocketAsync(url, [headers])`**
- **Description**: Asynchronously open a WebSocket connection
- **Parameters**: 
  - `url` (string) - The WebSocket URL to connect to
  - `headers?` (table) - Additional headers to send
- **Notes**: Use os.pullEvent to wait for websocket_success or websocket_failure events

#### Utility Functions:

**`http.checkURL(url)`**
- **Description**: Check if a URL is allowed by the current configuration
- **Parameters**: `url` (string) - The URL to check
- **Returns**: `boolean` - Whether the URL is allowed

**`http.checkURLAsync(url)`**
- **Description**: Asynchronously check if a URL is allowed
- **Parameters**: `url` (string) - The URL to check
- **Notes**: Use os.pullEvent to wait for http_check events

### **rednet** - Rednet Networking API
High-level networking API built on top of modems.

#### Setup Functions:

**`rednet.open(side)`**
- **Description**: Open a modem for rednet communication
- **Parameters**: `side` (string) - The side the modem is on

**`rednet.close([side])`**
- **Description**: Close rednet communication
- **Parameters**: `side?` (string) - The side to close (or all if not specified)

**`rednet.isOpen([side])`**
- **Description**: Check if rednet is open
- **Parameters**: `side?` (string) - The side to check (or any if not specified)
- **Returns**: `boolean` - Whether rednet is open

#### Communication Functions:

**`rednet.send(recipient, message, [protocol])`**
- **Description**: Send a message to a specific computer
- **Parameters**: 
  - `recipient` (number) - The computer ID to send to
  - `message` (any) - The message to send
  - `protocol?` (string) - The protocol identifier
- **Returns**: `boolean` - Whether the message was sent

**`rednet.broadcast(message, [protocol])`**
- **Description**: Broadcast a message to all computers
- **Parameters**: 
  - `message` (any) - The message to broadcast
  - `protocol?` (string) - The protocol identifier

**`rednet.receive([protocolFilter], [timeout])`**
- **Description**: Wait for and receive a rednet message
- **Parameters**: 
  - `protocolFilter?` (string) - Only receive messages with this protocol
  - `timeout?` (number) - Maximum time to wait
- **Returns**: `number, any, string | nil` - Sender ID, message, and protocol

#### Host/Lookup Functions:

**`rednet.host(protocol, hostname)`**
- **Description**: Register this computer as providing a service
- **Parameters**: 
  - `protocol` (string) - The protocol/service name
  - `hostname` (string) - The hostname to register

**`rednet.unhost(protocol)`**
- **Description**: Unregister this computer from providing a service
- **Parameters**: `protocol` (string) - The protocol to unregister

**`rednet.lookup(protocol, [hostname])`**
- **Description**: Find computers providing a specific service
- **Parameters**: 
  - `protocol` (string) - The protocol to look for
  - `hostname?` (string) - Specific hostname to find
- **Returns**: `number... | number | nil` - Computer IDs providing the service

### **gps** - GPS API
Use modems to locate the position of the current turtle or computers.

**`gps.CHANNEL_GPS`**
- **Description**: The channel GPS requests are sent on
- **Value**: 65534

**`gps.locate([timeout], [debug])`**
- **Description**: Determine the position of the current computer
- **Parameters**: 
  - `timeout?` (number) - Maximum time to wait for responses (default 2 seconds)
  - `debug?` (boolean) - Whether to print debug information
- **Returns**: `number, number, number | nil` - The x, y, z coordinates, or nil if failed
- **Notes**: 
  - Requires at least 4 GPS hosts to be set up for triangulation
  - Computer must have a wireless modem attached and be in range of GPS constellation
  - GPS constellation must be in the same dimension

### **GPS Setup Guide:**

To use GPS, you need to set up multiple GPS hosts. These are computers running the `gps host` program.

#### **Requirements:**
- At least 4 computers with wireless or ender modems
- Area at least 6x6x6 blocks
- For wireless modems: build as high as possible to increase range
- GPS constellation only works when chunks are loaded

#### **Setting Up GPS Hosts:**

1. **Build the constellation structure** - Place 4 computers in a configuration where:
   - Three computers should be in a plane (not in a straight line)
   - Fourth computer should be above or below the other three
   - Recommended: Place at different Y levels to avoid ambiguous positioning

2. **Configure each host** - For each computer, create a startup file:
   ```lua
   -- Example startup.lua for GPS host
   shell.run("gps", "host", x, y, z)
   ```
   Where x, y, z are the exact coordinates of that computer block.

3. **Find coordinates** - Use F3 debug screen to find coordinates:
   - Look at the computer block
   - Note the "Targeted Block" coordinates
   - Use these exact coordinates in the GPS host command

#### **Example GPS Host Setup:**
```lua
-- For a computer at coordinates 59, 65, -150
-- Content of startup.lua:
shell.run("gps", "host", 59, 65, -150)
```

#### **Testing GPS:**
Once your constellation is set up, test it with another computer:
```lua
local x, y, z = gps.locate(5)
if x then
    print("Position:", x, y, z)
else
    print("GPS failed - check constellation setup")
end
```

#### **GPS Best Practices:**
- Use consistent coordinate system across all hosts
- Avoid having 3+ hosts at the same Y level (causes ambiguous positioning)
- Ender modems provide much larger range than wireless modems
- One GPS constellation can cover an entire dimension if using ender modems
- Multiple constellations may be needed for wireless modem coverage

---

## System and Utility APIs

### **shell** - Shell API
The shell API provides access to CraftOS's command line interface.

#### Path Management:

**`shell.dir()`**
- **Description**: Return the current working directory
- **Returns**: `string` - The current directory path

**`shell.setDir(path)`**
- **Description**: Set the current working directory
- **Parameters**: `path` (string) - The new directory path

**`shell.path()`**
- **Description**: Get the current program search path
- **Returns**: `string` - The current path

**`shell.setPath(path)`**
- **Description**: Set the current program search path
- **Parameters**: `path` (string) - The new path

**`shell.resolve(path)`**
- **Description**: Resolve a relative path to an absolute path
- **Parameters**: `path` (string) - The path to resolve
- **Returns**: `string` - The absolute path

**`shell.resolveProgram(name)`**
- **Description**: Find the full path to a program
- **Parameters**: `name` (string) - The program name
- **Returns**: `string | nil` - The full path, or nil if not found

#### Program Execution:

**`shell.run(...)`**
- **Description**: Run a program with arguments
- **Parameters**: `...` - Program name and arguments
- **Returns**: `boolean` - Whether the program ran successfully

**`shell.execute(...)`**
- **Description**: Execute a command (alias for shell.run)
- **Parameters**: `...` - Command and arguments
- **Returns**: `boolean` - Whether the command executed successfully

**`shell.openTab(...)`**
- **Description**: Open a new tab (if multishell is available)
- **Parameters**: `...` - Program name and arguments
- **Returns**: `number | nil` - The tab ID, or nil if multishell unavailable

**`shell.switchTab(id)`**
- **Description**: Switch to a specific tab
- **Parameters**: `id` (number) - The tab ID to switch to

#### Aliases:

**`shell.setAlias(alias, program)`**
- **Description**: Add an alias for a program
- **Parameters**: 
  - `alias` (string) - The alias name
  - `program` (string) - The program path

**`shell.clearAlias(alias)`**
- **Description**: Remove an alias
- **Parameters**: `alias` (string) - The alias to remove

**`shell.aliases()`**
- **Description**: Get the current aliases for this shell
- **Returns**: `{[string] = string}` - Table mapping aliases to programs

#### Completion:

**`shell.setCompletionFunction(program, completionFunction)`**
- **Description**: Set the completion function for a program
- **Parameters**: 
  - `program` (string) - The program name
  - `completionFunction` (function) - The completion function

**`shell.getCompletionInfo()`**
- **Description**: Get a table containing all completion functions
- **Returns**: `table` - Completion function information

#### System:

**`shell.exit()`**
- **Description**: Exit the current shell

**`shell.getRunningProgram()`**
- **Description**: Returns the path to the currently running program
- **Returns**: `string` - The program path

### **multishell** - Multitasking API
Multitasking support for running multiple programs simultaneously.

**`multishell.getCurrent()`**
- **Description**: Get the currently visible tab
- **Returns**: `number` - The current tab ID

**`multishell.getCount()`**
- **Description**: Get the number of tabs
- **Returns**: `number` - The tab count

**`multishell.launch(environment, path, ...)`**
- **Description**: Launch a new program in a new tab
- **Parameters**: 
  - `environment` (table) - The environment for the program
  - `path` (string) - The program path
  - `...` - Arguments to pass to the program
- **Returns**: `number` - The new tab ID

**`multishell.setFocus(id)`**
- **Description**: Switch the focus to a specific tab
- **Parameters**: `id` (number) - The tab ID to focus

**`multishell.getTitle(id)`**
- **Description**: Get the title of a tab
- **Parameters**: `id` (number) - The tab ID
- **Returns**: `string` - The tab title

**`multishell.setTitle(id, title)`**
- **Description**: Set the title of a tab
- **Parameters**: 
  - `id` (number) - The tab ID
  - `title` (string) - The new title

### **parallel** - Parallel Execution API
Run multiple functions in parallel, switching between them each tick.

**`parallel.waitForAny(...)`**
- **Description**: Switches between execution of the functions, until any of them finishes
- **Parameters**: `...` - Functions to run in parallel
- **Notes**: Functions are not truly simultaneous, but switch when they yield

**`parallel.waitForAll(...)`**
- **Description**: Switches between execution of the functions, until all of them finish
- **Parameters**: `...` - Functions to run in parallel
- **Returns**: The combined results of all functions

### **settings** - Settings API
Read and write configuration options for CraftOS and your programs.

**`settings.define(name, options)`**
- **Description**: Define a new setting
- **Parameters**: 
  - `name` (string) - The setting name
  - `options` (table) - Setting options including description, default, type

**`settings.undefine(name)`**
- **Description**: Remove a setting definition
- **Parameters**: `name` (string) - The setting name

**`settings.set(name, value)`**
- **Description**: Set the value of a setting
- **Parameters**: 
  - `name` (string) - The setting name
  - `value` (any) - The value to set

**`settings.get(name, [default])`**
- **Description**: Get the value of a setting
- **Parameters**: 
  - `name` (string) - The setting name
  - `default?` (any) - Default value if not set
- **Returns**: `any` - The setting value

**`settings.getDetails(name)`**
- **Description**: Get detailed information about a setting
- **Parameters**: `name` (string) - The setting name
- **Returns**: `table | nil` - Setting details, or nil if not defined

**`settings.unset(name)`**
- **Description**: Remove a setting
- **Parameters**: `name` (string) - The setting name

**`settings.clear()`**
- **Description**: Remove all settings

**`settings.getNames()`**
- **Description**: Get the names of all defined settings
- **Returns**: `{string...}` - List of setting names

**`settings.load([path])`**
- **Description**: Load settings from a file
- **Parameters**: `path?` (string) - The file path (defaults to .settings)
- **Returns**: `boolean` - Whether loading was successful

**`settings.save([path])`**
- **Description**: Save settings to a file
- **Parameters**: `path?` (string) - The file path (defaults to .settings)
- **Returns**: `boolean` - Whether saving was successful

### **help** - Help System API
Find and display help files for CraftOS.

**`help.path()`**
- **Description**: Get the current help search path
- **Returns**: `string` - The help path

**`help.setPath(path)`**
- **Description**: Set the help search path
- **Parameters**: `path` (string) - The new help path

**`help.lookup(topic)`**
- **Description**: Find the path to a help file
- **Parameters**: `topic` (string) - The help topic
- **Returns**: `string | nil` - The path to the help file, or nil if not found

**`help.topics()`**
- **Description**: Get a list of all available help topics
- **Returns**: `{string...}` - List of topic names

**`help.completeTopic(text)`**
- **Description**: Complete a partial help topic name
- **Parameters**: `text` (string) - The partial topic name
- **Returns**: `{string...}` - List of matching topics

---

## Storage and Disk APIs

### **disk** - Disk Drive API
Interact with floppy disks and other storage devices.

**`disk.isPresent(side)`**
- **Description**: Check if a disk is present in the drive
- **Parameters**: `side` (string) - The side the drive is on
- **Returns**: `boolean` - Whether a disk is present

**`disk.getLabel(side)`**
- **Description**: Get the label of a disk
- **Parameters**: `side` (string) - The side the drive is on
- **Returns**: `string | nil` - The disk label, or nil if no disk

**`disk.setLabel(side, label)`**
- **Description**: Set the label of a disk
- **Parameters**: 
  - `side` (string) - The side the drive is on
  - `label` (string | nil) - The new label, or nil to clear

**`disk.hasData(side)`**
- **Description**: Check if a disk contains data (files/folders)
- **Parameters**: `side` (string) - The side the drive is on
- **Returns**: `boolean` - Whether the disk has data

**`disk.getMountPath(side)`**
- **Description**: Get the mount path of a disk
- **Parameters**: `side` (string) - The side the drive is on
- **Returns**: `string | nil` - The mount path, or nil if no disk

**`disk.hasAudio(side)`**
- **Description**: Check if a disk contains audio
- **Parameters**: `side` (string) - The side the drive is on
- **Returns**: `boolean` - Whether the disk has audio

**`disk.getAudioTitle(side)`**
- **Description**: Get the title of the audio on a disk
- **Parameters**: `side` (string) - The side the drive is on
- **Returns**: `string | nil` - The audio title, or nil if no audio

**`disk.playAudio(side)`**
- **Description**: Play the audio on a disk
- **Parameters**: `side` (string) - The side the drive is on

**`disk.stopAudio([side])`**
- **Description**: Stop playing audio
- **Parameters**: `side?` (string) - The side to stop (or all if not specified)

**`disk.eject(side)`**
- **Description**: Eject a disk from the drive
- **Parameters**: `side` (string) - The side the drive is on

**`disk.getID(side)`**
- **Description**: Get the unique ID of a disk
- **Parameters**: `side` (string) - The side the drive is on
- **Returns**: `number | nil` - The disk ID, or nil if no disk

---

## Mathematical APIs

### **vector** - Vector API
A basic 3D vector type and common vector operations.

**`vector.new(x, y, z)`**
- **Description**: Create a new vector
- **Parameters**: 
  - `x` (number) - The x component
  - `y` (number) - The y component
  - `z` (number) - The z component
- **Returns**: `Vector` - A new vector object

#### Vector Methods:

**`Vector:add(other)`**
- **Description**: Add two vectors
- **Parameters**: `other` (Vector) - The vector to add
- **Returns**: `Vector` - The sum vector

**`Vector:sub(other)`**
- **Description**: Subtract two vectors
- **Parameters**: `other` (Vector) - The vector to subtract
- **Returns**: `Vector` - The difference vector

**`Vector:mul(scalar)`**
- **Description**: Multiply a vector by a scalar
- **Parameters**: `scalar` (number) - The scalar to multiply by
- **Returns**: `Vector` - The scaled vector

**`Vector:div(scalar)`**
- **Description**: Divide a vector by a scalar
- **Parameters**: `scalar` (number) - The scalar to divide by
- **Returns**: `Vector` - The scaled vector

**`Vector:unm()`**
- **Description**: Get the negative of a vector
- **Returns**: `Vector` - The negated vector

**`Vector:dot(other)`**
- **Description**: Calculate the dot product of two vectors
- **Parameters**: `other` (Vector) - The other vector
- **Returns**: `number` - The dot product

**`Vector:cross(other)`**
- **Description**: Calculate the cross product of two vectors
- **Parameters**: `other` (Vector) - The other vector
- **Returns**: `Vector` - The cross product vector

**`Vector:length()`**
- **Description**: Get the length (magnitude) of the vector
- **Returns**: `number` - The vector length

**`Vector:normalize()`**
- **Description**: Get the normalized (unit) vector
- **Returns**: `Vector` - The normalized vector

**`Vector:round([tolerance])`**
- **Description**: Round the vector components
- **Parameters**: `tolerance?` (number) - The rounding tolerance
- **Returns**: `Vector` - The rounded vector

**`Vector:tostring()`**
- **Description**: Convert the vector to a string representation
- **Returns**: `string` - The string representation

---

## Special Purpose APIs

### **commands** - Command Computer API
Execute Minecraft commands and gather data from the results from a command computer.

**Note**: This API is only available on Command computers. It is not accessible to normal players.

#### Command Execution:

**`commands.exec(command)`**
- **Description**: Execute a specific command
- **Parameters**: `command` (string) - The command to execute
- **Returns**: `boolean, {string...}, number | nil` - Success, output lines, affected objects

**`commands.execAsync(command)`**
- **Description**: Asynchronously execute a command
- **Parameters**: `command` (string) - The command to execute
- **Returns**: `number` - The task ID

**`commands.list()`**
- **Description**: List all available commands which the computer has permission to execute
- **Returns**: `{string...}` - List of available commands

#### World Information:

**`commands.getBlockPosition()`**
- **Description**: Get the position of the current command computer
- **Returns**: `number, number, number` - The x, y, z coordinates

**`commands.getBlockInfo(x, y, z, [dimension])`**
- **Description**: Get some basic information about a block
- **Parameters**: 
  - `x` (number) - The x coordinate
  - `y` (number) - The y coordinate
  - `z` (number) - The z coordinate
  - `dimension?` (string) - The dimension to query
- **Returns**: `table` - Information about the block

**`commands.getBlockInfos(minX, minY, minZ, maxX, maxY, maxZ, [dimension])`**
- **Description**: Get information about a range of blocks
- **Parameters**: 
  - `minX` (number) - The start x coordinate
  - `minY` (number) - The start y coordinate
  - `minZ` (number) - The start z coordinate
  - `maxX` (number) - The end x coordinate
  - `maxY` (number) - The end y coordinate
  - `maxZ` (number) - The end z coordinate
  - `dimension?` (string) - The dimension to query
- **Returns**: `{table...}` - List of information about each block

#### Helper Command Methods:

The commands API provides helper methods to execute every command. For instance:
- **`commands.say("Hi!")`** is equivalent to **`commands.exec("say Hi!")`**
- **`commands.give("player", "item")`** is equivalent to **`commands.exec("give player item")`**

#### Asynchronous Commands:

**`commands.async`** provides a similar interface to execute asynchronous commands:
- **`commands.async.say("Hi!")`** is equivalent to **`commands.execAsync("say Hi!")`**

---

## Window Management

### **window** - Window API
Create terminal redirects occupying a smaller area of an existing terminal.

**`window.create(parent, nX, nY, nWidth, nHeight, [bStartVisible])`**
- **Description**: Returns a terminal object that is a space within the specified parent terminal object
- **Parameters**: 
  - `parent` (Redirect) - The parent terminal redirect to draw to
  - `nX` (number) - The x coordinate this window is drawn at in the parent terminal
  - `nY` (number) - The y coordinate this window is drawn at in the parent terminal
  - `nWidth` (number) - The width of this window
  - `nHeight` (number) - The height of this window
  - `bStartVisible?` (boolean) - Whether the window is visible initially
- **Returns**: `Window` - The window object

#### Window Methods:

**`Window.write(text)`**
- **Description**: Write text at the current cursor position
- **Parameters**: `text` (string) - The text to write

**`Window.scroll(y)`**
- **Description**: Scroll the window contents
- **Parameters**: `y` (number) - The number of lines to scroll

**`Window.getCursorPos()`**
- **Description**: Get the cursor position within this window
- **Returns**: `number, number` - The x and y coordinates

**`Window.setCursorPos(x, y)`**
- **Description**: Set the cursor position within this window
- **Parameters**: 
  - `x` (number) - The new x position
  - `y` (number) - The new y position

**`Window.getCursorBlink()`**
- **Description**: Get whether the cursor is blinking
- **Returns**: `boolean` - Whether the cursor is blinking

**`Window.setCursorBlink(blink)`**
- **Description**: Set whether the cursor should blink
- **Parameters**: `blink` (boolean) - Whether the cursor should blink

**`Window.getSize()`**
- **Description**: Get the size of this window
- **Returns**: `number, number` - The width and height

**`Window.clear()`**
- **Description**: Clear the window

**`Window.clearLine()`**
- **Description**: Clear the current line

**`Window.getTextColour()` / `Window.getTextColor()`**
- **Description**: Get the text color
- **Returns**: `number` - The current text color

**`Window.setTextColour(color)` / `Window.setTextColor(color)`**
- **Description**: Set the text color
- **Parameters**: `color` (number) - The new text color

**`Window.getBackgroundColour()` / `Window.getBackgroundColor()`**
- **Description**: Get the background color
- **Returns**: `number` - The current background color

**`Window.setBackgroundColour(color)` / `Window.setBackgroundColor(color)`**
- **Description**: Set the background color
- **Parameters**: `color` (number) - The new background color

**`Window.isColour()` / `Window.isColor()`**
- **Description**: Check if the window supports color
- **Returns**: `boolean` - Whether the window supports color

**`Window.blit(text, textColors, backgroundColors)`**
- **Description**: Draw text with specific colors
- **Parameters**: 
  - `text` (string) - The text to draw
  - `textColors` (string) - The text colors for each character
  - `backgroundColors` (string) - The background colors for each character

**`Window.setPaletteColour(index, ...)` / `Window.setPaletteColor(index, ...)`**
- **Description**: Set a palette color
- **Parameters**: 
  - `index` (number) - The color index
  - `...` - Color values

**`Window.getPaletteColour(index)` / `Window.getPaletteColor(index)`**
- **Description**: Get a palette color
- **Parameters**: `index` (number) - The color index
- **Returns**: `number, number, number` - The RGB values

**`Window.setVisible(visible)`**
- **Description**: Set whether this window is visible
- **Parameters**: `visible` (boolean) - Whether the window should be visible

**`Window.isVisible()`**
- **Description**: Get whether this window is visible
- **Returns**: `boolean` - Whether the window is visible

**`Window.redraw()`**
- **Description**: Draw this window

**`Window.restoreCursor()`**
- **Description**: Set the current terminal's cursor to where this window's cursor is

**`Window.getPosition()`**
- **Description**: Get the position of the top left corner of this window
- **Returns**: `number, number` - The x and y coordinates

**`Window.reposition(new_x, new_y, [new_width], [new_height], [new_parent])`**
- **Description**: Reposition or resize the given window
- **Parameters**: 
  - `new_x` (number) - The new x position
  - `new_y` (number) - The new y position
  - `new_width?` (number) - The new width
  - `new_height?` (number) - The new height
  - `new_parent?` (Redirect) - The new parent terminal

**`Window.getLine(y)`**
- **Description**: Get the buffered contents of a line in this window
- **Parameters**: `y` (number) - The line to get
- **Returns**: `string, string, string` - The text, text colors, and background colors

---

# Peripherals

## Monitor Peripheral
Monitors are blocks that act as a terminal, displaying information on one side.

All monitor functions are the same as the **term** API functions, so refer to the term API documentation above. Monitors can be wrapped as peripherals:

```lua
local monitor = peripheral.wrap("top")
monitor.write("Hello, Monitor!")
monitor.setCursorPos(1, 2)
monitor.setTextColor(colors.red)
```

## Speaker Peripheral
The speaker peripheral allows your computer to play notes and other sounds. The speaker can play three kinds of sound, in increasing orders of complexity:

### **Basic Functions:**

**`speaker.playNote(instrument, [volume], pitch)`**
- **Description**: Play a note block note through the speaker
- **Parameters**: 
  - `instrument` (string) - The instrument to use to play this note
  - `volume?` (number) - The volume to play the note at (0.0-3.0, default 1.0)  
  - `pitch` (number) - The pitch to play the note at (0.5-2.0)
- **Returns**: `boolean` - Whether the note was played successfully
- **Notes**: 
  - Maximum of 8 notes can be played in a single tick
  - The pitch argument uses semitones as the unit (0, 12, and 24 map to F#; 6 and 18 map to C)
- **Supported instruments**: "harp", "basedrum", "snare", "hat", "bass", "flute", "bell", "guitar", "chime", "xylophone", "iron_xylophone", "cow_bell", "didgeridoo", "bit", "banjo", "pling"

**`speaker.playSound(name, [volume], [pitch])`**
- **Description**: Play a Minecraft sound
- **Parameters**: 
  - `name` (string) - The sound name
  - `volume?` (number) - The volume (0.0-3.0, default 1.0)
  - `pitch?` (number) - The pitch (0.5-2.0, default 1.0)
- **Returns**: `boolean` - Whether the sound was played successfully

**`speaker.playAudio(audio, [volume])`**
- **Description**: Attempt to stream some audio data to the speaker
- **Parameters**: 
  - `audio` (table) - A list of audio samples as amplitudes between -128 and 127
  - `volume?` (number) - The volume to play this audio at (0.0-3.0, default 1.0)
- **Returns**: `boolean` - Whether the audio was queued successfully
- **Notes**: 
  - Audio samples are stored in an internal buffer and played back at 48kHz
  - If buffer is full, function returns false. Wait for `speaker_audio_empty` event before trying again
  - Speaker only buffers a single call to playAudio at once
  - Try to play as many samples as possible (up to 128×1024) to reduce audio stuttering
  - Audio stream is re-encoded before playing, so supplied samples may not be played exactly

**`speaker.stop()`**
- **Description**: Stop all audio being played by this speaker

### **Audio Formats:**

CC:Tweaked speakers work with PCM audio at 48kHz with 8-bit resolution. For more complex audio, DFPWM (Dynamic Filter Pulse Width Modulation) is the recommended format.

**Example - Playing DFPWM Audio:**
```lua
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()

for chunk in io.lines("data/example.dfpwm", 16 * 1024) do
    local buffer = decoder(chunk)
    while not speaker.playAudio(buffer) do
        os.pullEvent("speaker_audio_empty")
    end
end
```

**Example - Generating a Sine Wave:**
```lua
local speaker = peripheral.find("speaker")
local sample_rate = 48000
local frequency = 220
local duration = 3
local volume = 0.5

local samples = {}
for i = 1, sample_rate * duration do
    local t = (i - 1) / sample_rate
    local sample = math.sin(2 * math.pi * frequency * t) * volume * 127
    samples[i] = math.floor(sample)
end

-- Play in chunks
local chunk_size = 16384
for i = 1, #samples, chunk_size do
    local chunk = {}
    for j = 0, chunk_size - 1 do
        if samples[i + j] then
            chunk[j + 1] = samples[i + j]
        end
    end
    
    while not speaker.playAudio(chunk) do
        os.pullEvent("speaker_audio_empty")
    end
end
```

## Modem Peripheral
Modems allow you to send messages between computers over long distances.

**`modem.open(channel)`**
- **Description**: Open a channel on a modem
- **Parameters**: `channel` (number) - The channel to open (0-65535)

**`modem.isOpen(channel)`**
- **Description**: Check if a channel is open
- **Parameters**: `channel` (number) - The channel to check
- **Returns**: `boolean` - Whether the channel is open

**`modem.close(channel)`**
- **Description**: Close an open channel
- **Parameters**: `channel` (number) - The channel to close

**`modem.closeAll()`**
- **Description**: Close all open channels

**`modem.transmit(channel, replyChannel, message)`**
- **Description**: Send a modem message on a certain channel
- **Parameters**: 
  - `channel` (number) - The channel to send on
  - `replyChannel` (number) - The channel for replies
  - `message` (any) - The message to send

**`modem.isWireless()`**
- **Description**: Check if this is a wireless modem
- **Returns**: `boolean` - Whether the modem is wireless

### Wired Modem Functions:

**`modem.getNameLocal()`**
- **Description**: Returns the network name of the current computer
- **Returns**: `string | nil` - The network name, or nil if modem is off

**`modem.getNamesRemote()`**
- **Description**: List all remote peripherals on the wired network
- **Returns**: `{string...}` - Remote peripheral names

**`modem.isPresentRemote(name)`**
- **Description**: Determine if a peripheral is available on this wired network
- **Parameters**: `name` (string) - The peripheral name
- **Returns**: `boolean` - Whether the peripheral is present

**`modem.getTypeRemote(name)`**
- **Description**: Get the type of a peripheral on the wired network
- **Parameters**: `name` (string) - The peripheral name
- **Returns**: `string...` - The peripheral types

**`modem.hasTypeRemote(name, type)`**
- **Description**: Check if a remote peripheral is of a particular type
- **Parameters**: 
  - `name` (string) - The peripheral name
  - `type` (string) - The type to check
- **Returns**: `boolean` - Whether the peripheral is of the given type

**`modem.getMethodsRemote(name)`**
- **Description**: Get all available methods for a remote peripheral
- **Parameters**: `name` (string) - The peripheral name
- **Returns**: `{string...} | nil` - List of methods, or nil if not present

**`modem.callRemote(name, method, ...)`**
- **Description**: Call a method on a peripheral on this wired network
- **Parameters**: 
  - `name` (string) - The peripheral name
  - `method` (string) - The method to call
  - `...` - Arguments to pass
- **Returns**: The return values of the remote method

## Printer Peripheral
Printers can be used to create printed documents and books.

**`printer.write(text)`**
- **Description**: Write text to the current page
- **Parameters**: `text` (string) - The text to write
- **Returns**: `boolean` - Whether the text was written successfully

**`printer.setCursorPos(x, y)`**
- **Description**: Set the cursor position on the current page
- **Parameters**: 
  - `x` (number) - The new x position
  - `y` (number) - The new y position

**`printer.getCursorPos()`**
- **Description**: Get the current cursor position
- **Returns**: `number, number` - The x and y coordinates

**`printer.getPageSize()`**
- **Description**: Get the size of the current page
- **Returns**: `number, number` - The width and height

**`printer.newPage()`**
- **Description**: Start a new page
- **Returns**: `boolean` - Whether a new page was started

**`printer.endPage()`**
- **Description**: Finish the current page
- **Returns**: `boolean` - Whether the page was finished

**`printer.setPageTitle([title])`**
- **Description**: Set the title of the current page
- **Parameters**: `title?` (string) - The page title

**`printer.getInkLevel()`**
- **Description**: Get the amount of ink left in the printer
- **Returns**: `number` - The ink level (0-64000)

**`printer.getPaperLevel()`**
- **Description**: Get the amount of paper left in the printer
- **Returns**: `number` - The paper level

## Drive Peripheral
Disk drives for reading floppy disks and other storage media.

All drive functions are the same as the **disk** API functions, so refer to the disk API documentation above. Drives can be wrapped as peripherals:

```lua
local drive = peripheral.wrap("top")
if drive.isPresent() then
    print("Disk label:", drive.getLabel())
end
```

## Computer Peripheral
A computer or turtle wrapped as a peripheral for basic interaction with adjacent computers.

**`computer.turnOn()`**
- **Description**: Turn on the wrapped computer
- **Returns**: `boolean` - Whether the computer was turned on

**`computer.shutdown()`**
- **Description**: Shut down the wrapped computer
- **Returns**: `boolean` - Whether the computer was shut down

**`computer.reboot()`**
- **Description**: Reboot the wrapped computer
- **Returns**: `boolean` - Whether the computer was rebooted

**`computer.getID()`**
- **Description**: Get the ID of the wrapped computer
- **Returns**: `number` - The computer ID

**`computer.getLabel()`**
- **Description**: Get the label of the wrapped computer
- **Returns**: `string | nil` - The computer label

**`computer.isOn()`**
- **Description**: Check if the wrapped computer is on
- **Returns**: `boolean` - Whether the computer is on

---

# Events

CC:Tweaked has an event-driven system where computers can listen for and respond to various events. Use `os.pullEvent()` or `os.pullEventRaw()` to listen for events.

## System Events

### **terminate**
Fired when Ctrl-T is held down.

**Parameters**: None

**Example**:
```lua
local event = os.pullEventRaw()
if event == "terminate" then
    print("Termination requested!")
end
```

### **term_resize**
Fired when the main terminal is resized.

**Parameters**: None

## Timer Events

### **timer**
Fired when a timer started with `os.startTimer` completes.

**Parameters**: 
- `timer_id` (number) - The ID of the timer that fired

**Example**:
```lua
local timer_id = os.startTimer(5)
local event, id = os.pullEvent("timer")
if id == timer_id then
    print("Timer completed!")
end
```

### **alarm**
Fired when an alarm started with `os.setAlarm` completes.

**Parameters**: 
- `alarm_id` (number) - The ID of the alarm that fired

## Input Events

### **key**
Fired when a key is pressed.

**Parameters**: 
- `key` (number) - The key code that was pressed
- `is_held` (boolean) - Whether the key is being held

### **key_up**
Fired when a key is released.

**Parameters**: 
- `key` (number) - The key code that was released

### **char**
Fired when a character is typed on the keyboard.

**Parameters**: 
- `character` (string) - The character that was typed

### **paste**
Fired when text is pasted into the computer through Ctrl-V.

**Parameters**: 
- `text` (string) - The text that was pasted

## Mouse Events

### **mouse_click**
Fired when the terminal is clicked with a mouse.

**Parameters**: 
- `button` (number) - The mouse button (1=left, 2=right, 3=middle)
- `x` (number) - The x coordinate clicked
- `y` (number) - The y coordinate clicked

### **mouse_up**
Fired when a mouse button is released.

**Parameters**: 
- `button` (number) - The mouse button released
- `x` (number) - The x coordinate
- `y` (number) - The y coordinate

### **mouse_drag**
Fired when the mouse is dragged.

**Parameters**: 
- `button` (number) - The mouse button being dragged
- `x` (number) - The new x coordinate
- `y` (number) - The new y coordinate

### **mouse_scroll**
Fired when the mouse wheel is scrolled.

**Parameters**: 
- `direction` (number) - The scroll direction (1=up, -1=down)
- `x` (number) - The x coordinate
- `y` (number) - The y coordinate

## Peripheral Events

### **peripheral**
Fired when a peripheral is attached on a side or to a modem.

**Parameters**: 
- `side` (string) - The side the peripheral was attached to

### **peripheral_detach**
Fired when a peripheral is detached from a side or from a modem.

**Parameters**: 
- `side` (string) - The side the peripheral was detached from

### **monitor_resize**
Fired when an adjacent or networked monitor's size is changed.

**Parameters**: 
- `side` (string) - The side of the monitor that was resized

### **monitor_touch**
Fired when an adjacent or networked Advanced Monitor is right-clicked.

**Parameters**: 
- `side` (string) - The side of the monitor
- `x` (number) - The x coordinate touched
- `y` (number) - The y coordinate touched

## Storage Events

### **disk**
Fired when a disk is inserted into an adjacent or networked disk drive.

**Parameters**: 
- `side` (string) - The side of the disk drive

### **disk_eject**
Fired when a disk is removed from an adjacent or networked disk drive.

**Parameters**: 
- `side` (string) - The side of the disk drive

## Network Events

### **modem_message**
Fired when a message is received on an open channel on any modem.

**Parameters**: 
- `side` (string) - The side of the modem
- `channel` (number) - The channel the message was sent on
- `reply_channel` (number) - The reply channel
- `message` (any) - The message content
- `distance` (number) - The distance to the sender

### **rednet_message**
Fired when a message is sent over Rednet.

**Parameters**: 
- `sender` (number) - The ID of the sending computer
- `message` (any) - The message content
- `protocol` (string | nil) - The protocol the message was sent with

## HTTP Events

### **http_success**
Fired when an HTTP request returns successfully.

**Parameters**: 
- `url` (string) - The URL that was requested
- `handle` (table) - The response handle

### **http_failure**
Fired when an HTTP request fails.

**Parameters**: 
- `url` (string) - The URL that was requested
- `error` (string) - The error message

### **http_check**
Fired when a URL check finishes.

**Parameters**: 
- `url` (string) - The URL that was checked
- `success` (boolean) - Whether the URL is allowed

## WebSocket Events

### **websocket_success**
Fired when a WebSocket connection request returns successfully.

**Parameters**: 
- `url` (string) - The WebSocket URL
- `handle` (table) - The WebSocket handle

### **websocket_failure**
Fired when a WebSocket connection request fails.

**Parameters**: 
- `url` (string) - The WebSocket URL
- `error` (string) - The error message

### **websocket_closed**
Fired when an open WebSocket connection is closed.

**Parameters**: 
- `url` (string) - The WebSocket URL

### **websocket_message**
Fired when a message is received on an open WebSocket connection.

**Parameters**: 
- `url` (string) - The WebSocket URL
- `message` (string) - The message content
- `binary` (boolean) - Whether the message is binary

## Audio Events

### **speaker_audio_empty**
Fired when the speaker's audio buffer becomes empty.

**Parameters**: 
- `side` (string) - The side of the speaker

## Redstone Events

### **redstone**
Fired whenever any redstone inputs on the computer or relay change.

**Parameters**: None

## Turtle Events

### **turtle_inventory**
Fired when a turtle's inventory is changed.

**Parameters**: None

## System Command Events

### **computer_command**
Fired when the `/computercraft queue` command is run for the current computer.

**Parameters**: 
- `args` (table) - The arguments passed to the command

### **task_complete**
Fired when an asynchronous task completes.

**Parameters**: 
- `task_id` (number) - The ID of the completed task
- `success` (boolean) - Whether the task succeeded
- `error` (string) - Error message if the task failed
- `...` - Additional return values from the task

## File Transfer Events

### **file_transfer**
Fired when a user drags-and-drops a file on an open computer.

**Parameters**: 
- `files` (table) - A table of files that were transferred

---

# Libraries (cc.* modules)

## **cc.completion** - Completion Helpers
A collection of helper methods for working with input completion.

**`cc.completion.choice(text, choices, [add_space])`**
- **Description**: Complete from a list of choices
- **Parameters**: 
  - `text` (string) - The current text
  - `choices` (table) - The available choices
  - `add_space?` (boolean) - Whether to add a space after completion
- **Returns**: `{string...}` - Possible completions

**`cc.completion.file(shell, text, [previous], [add_space])`**
- **Description**: Complete file and directory names
- **Parameters**: 
  - `shell` (table) - The current shell
  - `text` (string) - The current text
  - `previous?` (table) - Previous arguments
  - `add_space?` (boolean) - Whether to add a space
- **Returns**: `{string...}` - Possible completions

**`cc.completion.dir(shell, text, [previous], [add_space])`**
- **Description**: Complete directory names only
- **Parameters**: 
  - `shell` (table) - The current shell
  - `text` (string) - The current text
  - `previous?` (table) - Previous arguments
  - `add_space?` (boolean) - Whether to add a space
- **Returns**: `{string...}` - Possible completions

**`cc.completion.program(shell, text, [previous], [add_space])`**
- **Description**: Complete program names
- **Parameters**: 
  - `shell` (table) - The current shell
  - `text` (string) - The current text
  - `previous?` (table) - Previous arguments
  - `add_space?` (boolean) - Whether to add a space
- **Returns**: `{string...}` - Possible completions

**`cc.completion.help(text, [previous], [add_space])`**
- **Description**: Complete help topics
- **Parameters**: 
  - `text` (string) - The current text
  - `previous?` (table) - Previous arguments
  - `add_space?` (boolean) - Whether to add a space
- **Returns**: `{string...}` - Possible completions

**`cc.completion.setting(text, [previous], [add_space])`**
- **Description**: Complete setting names
- **Parameters**: 
  - `text` (string) - The current text
  - `previous?` (table) - Previous arguments
  - `add_space?` (boolean) - Whether to add a space
- **Returns**: `{string...}` - Possible completions

**`cc.completion.command(text, [previous], [add_space])`**
- **Description**: Complete command names
- **Parameters**: 
  - `text` (string) - The current text
  - `previous?` (table) - Previous arguments
  - `add_space?` (boolean) - Whether to add a space
- **Returns**: `{string...}` - Possible completions

## **cc.shell.completion** - Shell Completion Helpers
A collection of helper methods for working with shell completion.

**`cc.shell.completion.file(shell, index, text, previous)`**
- **Description**: Complete file names in shell context
- **Parameters**: 
  - `shell` (table) - The shell object
  - `index` (number) - Argument index
  - `text` (string) - Current text
  - `previous` (table) - Previous arguments
- **Returns**: `{string...}` - Possible completions

**`cc.shell.completion.dir(shell, index, text, previous)`**
- **Description**: Complete directory names in shell context
- **Parameters**: 
  - `shell` (table) - The shell object
  - `index` (number) - Argument index
  - `text` (string) - Current text
  - `previous` (table) - Previous arguments
- **Returns**: `{string...}` - Possible completions

**`cc.shell.completion.program(shell, index, text, previous)`**
- **Description**: Complete program names in shell context
- **Parameters**: 
  - `shell` (table) - The shell object
  - `index` (number) - Argument index
  - `text` (string) - Current text
  - `previous` (table) - Previous arguments
- **Returns**: `{string...}` - Possible completions

**`cc.shell.completion.programWithArgs(shell, index, text, previous, start)`**
- **Description**: Complete program names, then defer to program's completion
- **Parameters**: 
  - `shell` (table) - The shell object
  - `index` (number) - Argument index
  - `text` (string) - Current text
  - `previous` (table) - Previous arguments
  - `start` (number) - Starting argument index
- **Returns**: `{string...}` - Possible completions

## **cc.expect** - Argument Validation
Helper functions for verifying that function arguments are well-formed and of the correct type.

**`cc.expect.expect(index, value, ...)`**
- **Description**: Expect an argument to have a specific type
- **Parameters**: 
  - `index` (number) - The argument index
  - `value` (any) - The value to check
  - `...` (string) - The expected types
- **Returns**: `any` - The given value
- **Throws**: If the value is not one of the allowed types

**`cc.expect.field(tbl, index, ...)`**
- **Description**: Expect a field in a table to be one of several types
- **Parameters**: 
  - `tbl` (table) - The table to check
  - `index` (string) - The field name
  - `...` (string) - The expected types
- **Returns**: `any` - The contents of the given field
- **Throws**: If the field is not one of the expected types

**`cc.expect.range(num, [min], [max])`**
- **Description**: Expect a number to be within a range
- **Parameters**: 
  - `num` (number) - The number to check
  - `min?` (number) - The minimum value (default -math.huge)
  - `max?` (number) - The maximum value (default math.huge)
- **Returns**: `number` - The given number
- **Throws**: If the number is outside the range

**Example Usage**:
```lua
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local function add_person(name, info)
    expect(1, name, "string")
    expect(2, info, "table", "nil")
    
    if info then
        local age = field(info, "age", "number")
        local gender = field(info, "gender", "string", "nil")
        print("Name:", name, "Age:", age, "Gender:", gender or "unspecified")
    end
end

add_person("John", { age = 25, gender = "male" })
```

## **cc.strings** - String Utilities
Various utilities for working with strings and text.

**`cc.strings.wrap(text, width)`**
- **Description**: Wrap text to a specific width
- **Parameters**: 
  - `text` (string) - The text to wrap
  - `width` (number) - The maximum line width
- **Returns**: `{string...}` - A table of wrapped lines

**`cc.strings.ensure_width(line, width)`**
- **Description**: Makes the input string a fixed width by truncating or padding with spaces
- **Parameters**: 
  - `line` (string) - The line to adjust
  - `width` (number) - The desired width
- **Returns**: `string` - The adjusted line

**`cc.strings.split(text, delim, [plain], [limit])`**
- **Description**: Split a string into parts, each separated by a delimiter
- **Parameters**: 
  - `text` (string) - The string to split
  - `delim` (string) - The delimiter to split by (Lua pattern by default)
  - `plain?` (boolean) - Whether to treat delimiter as literal string instead of pattern
  - `limit?` (number) - Maximum number of elements to return
- **Returns**: `{string...}` - The split string parts

**Example Usage**:
```lua
local strings = require "cc.strings"

-- Wrap text for display
term.clear()
local lines = strings.wrap("This is a very long piece of text that needs to be wrapped", 20)
for i = 1, #lines do
    term.setCursorPos(1, i)
    term.write(lines[i])
end

-- Split strings
local words = strings.split("apple,banana,cherry", ",", true)
-- words = {"apple", "banana", "cherry"}

local sentence = strings.split("This is a sentence", "%s+")
-- sentence = {"This", "is", "a", "sentence"}
```

## **cc.pretty** - Pretty Printing
A pretty printer for rendering data structures in an aesthetically pleasing manner.

**`cc.pretty.pretty(obj, [options])`**
- **Description**: Pretty print a value to a document
- **Parameters**: 
  - `obj` (any) - The value to pretty print
  - `options?` (table) - Pretty printing options
- **Returns**: `table` - A document representing the pretty printed value

**`cc.pretty.pretty_print(obj, [options])`**
- **Description**: Pretty print a value directly to the terminal
- **Parameters**: 
  - `obj` (any) - The value to pretty print
  - `options?` (table) - Pretty printing options

**`cc.pretty.render(doc, [width], [ribbon_frac])`**
- **Description**: Render a document to a string
- **Parameters**: 
  - `doc` (table) - The document to render
  - `width?` (number) - The maximum width (default 80)
  - `ribbon_frac?` (number) - The ribbon fraction (default 0.6)
- **Returns**: `string` - The rendered string

**`cc.pretty.write(doc, [options])`**
- **Description**: Write a document to the current terminal
- **Parameters**: 
  - `doc` (table) - The document to write
  - `options?` (table) - Writing options

### Document Construction Functions:

**`cc.pretty.empty`**
- **Description**: An empty document

**`cc.pretty.space`**
- **Description**: A document with a single space

**`cc.pretty.line`**
- **Description**: A line break (becomes empty when collapsed with group)

**`cc.pretty.space_line`**
- **Description**: A line break (becomes space when collapsed with group)

**`cc.pretty.text(text, [colour])`**
- **Description**: Create a document with the given text
- **Parameters**: 
  - `text` (string) - The text content
  - `colour?` (number) - The text color
- **Returns**: `Doc` - The text document

**`cc.pretty.concat(...)`**
- **Description**: Concatenate several documents together
- **Parameters**: `...` - Documents to concatenate
- **Returns**: `Doc` - The concatenated document

**`cc.pretty.nest(indent, doc)`**
- **Description**: Indent later lines of the document with the given number of spaces
- **Parameters**: 
  - `indent` (number) - Number of spaces to indent
  - `doc` (Doc) - The document to nest
- **Returns**: `Doc` - The nested document

**`cc.pretty.group(doc)`**
- **Description**: Try to display document on single line if there's room
- **Parameters**: `doc` (Doc) - The document to group
- **Returns**: `Doc` - The grouped document

**Pretty Printing Options**:
- `function_args` (boolean) - Show function arguments if known (default false)
- `function_source` (boolean) - Show where function was defined (default false)

**Example Usage**:
```lua
local pretty = require "cc.pretty"

-- Pretty print a table
local data = {
    name = "John",
    age = 25,
    hobbies = {"reading", "gaming", "coding"}
}
pretty.pretty_print(data)

-- Create a custom document
local doc = pretty.group(
    pretty.text("Hello") .. 
    pretty.space_line .. 
    pretty.text("World", colors.blue)
)
pretty.print(doc)
```

## **cc.require** - Module System
A pure Lua implementation of the builtin require function and package library.

**`cc.require.require(modname)`**
- **Description**: Load a module
- **Parameters**: `modname` (string) - The module name
- **Returns**: `any` - The loaded module

**`cc.require.make_require(env, dir)`**
- **Description**: Create a require function for a specific environment
- **Parameters**: 
  - `env` (table) - The environment table
  - `dir` (string) - The directory to search from
- **Returns**: `function` - A require function

## **cc.audio.dfpwm** - Audio Processing
Convert between streams of DFPWM audio data and a list of amplitudes.

**`cc.audio.dfpwm.make_decoder()`**
- **Description**: Create a new DFPWM decoder
- **Returns**: `table` - A decoder object

**`cc.audio.dfpwm.make_encoder()`**
- **Description**: Create a new DFPWM encoder
- **Returns**: `table` - An encoder object

### Decoder Methods:

**`decoder:decode(input)`**
- **Description**: Decode a DFPWM chunk into amplitudes
- **Parameters**: `input` (string) - The DFPWM data
- **Returns**: `{number...}` - The decoded amplitudes

### Encoder Methods:

**`encoder:encode(input)`**
- **Description**: Encode amplitudes into DFPWM
- **Parameters**: `input` ({number...}) - The amplitudes to encode
- **Returns**: `string` - The encoded DFPWM data

## **cc.image.nft** - Image Processing
Read and draw nft ("Nitrogen Fingers Text") images.

**`cc.image.nft.parse(image)`**
- **Description**: Parse an NFT image string
- **Parameters**: `image` (string) - The NFT image data
- **Returns**: `table` - The parsed image data

**`cc.image.nft.load(path)`**
- **Description**: Load an NFT image from a file
- **Parameters**: `path` (string) - The file path
- **Returns**: `table | nil` - The image data, or nil if failed

**`cc.image.nft.draw(image, [x], [y], [target])`**
- **Description**: Draw an NFT image to the screen or a target
- **Parameters**: 
  - `image` (table) - The image data
  - `x?` (number) - The x position (default 1)
  - `y?` (number) - The y position (default 1)  
  - `target?` (table) - The target to draw to (default current terminal)

---

# Generic Peripherals

## **inventory** - Inventory Management
Methods for interacting with inventories. Provides functions to manipulate items in chests and other storage containers.

**`inventory.size()`**
- **Description**: Get the size of this inventory
- **Returns**: `number` - The number of slots in the inventory

**`inventory.list()`**
- **Description**: List all items in this inventory
- **Returns**: `{[number] = table}` - A table mapping slot numbers to item details

**`inventory.getItemDetail(slot)`**
- **Description**: Get detailed information about an item in a specific slot
- **Parameters**: `slot` (number) - The slot to inspect
- **Returns**: `table | nil` - Item information, or nil if slot is empty

**`inventory.getItemLimit(slot)`**
- **Description**: Get the maximum number of items which can be stored in this slot
- **Parameters**: `slot` (number) - The slot to check
- **Returns**: `number` - The maximum stack size for this slot

**`inventory.pushItems(toName, fromSlot, [limit], [toSlot])`**
- **Description**: Move items from this inventory to another
- **Parameters**: 
  - `toName` (string) - The name of the target inventory
  - `fromSlot` (number) - The slot to move items from
  - `limit?` (number) - The maximum number of items to move
  - `toSlot?` (number) - The target slot (auto-selected if not specified)
- **Returns**: `number` - The number of items moved

**`inventory.pullItems(fromName, fromSlot, [limit], [toSlot])`**
- **Description**: Move items from another inventory to this one
- **Parameters**: 
  - `fromName` (string) - The name of the source inventory
  - `fromSlot` (number) - The slot to move items from
  - `limit?` (number) - The maximum number of items to move
  - `toSlot?` (number) - The target slot (auto-selected if not specified)
- **Returns**: `number` - The number of items moved

## **fluid_storage** - Fluid Storage Management
Methods for interacting with fluid storage systems.

**`fluid_storage.tanks()`**
- **Description**: Get all tanks in this fluid storage
- **Returns**: `{table...}` - A list of tank information

**`fluid_storage.pushFluid(toName, [limit], [fluidName])`**
- **Description**: Move fluid from this storage to another
- **Parameters**: 
  - `toName` (string) - The name of the target fluid storage
  - `limit?` (number) - The maximum amount of fluid to move
  - `fluidName?` (string) - The type of fluid to move
- **Returns**: `number` - The amount of fluid moved

**`fluid_storage.pullFluid(fromName, [limit], [fluidName])`**
- **Description**: Move fluid from another storage to this one
- **Parameters**: 
  - `fromName` (string) - The name of the source fluid storage
  - `limit?` (number) - The maximum amount of fluid to move
  - `fluidName?` (string) - The type of fluid to move
- **Returns**: `number` - The amount of fluid moved

---

# Common Programming Patterns

## Event Handling Pattern
```lua
while true do
    local event, p1, p2, p3, p4, p5 = os.pullEvent()
    
    if event == "key" then
        print("Key pressed:", p1)
    elseif event == "mouse_click" then
        print("Mouse clicked at:", p2, p3)
    elseif event == "redstone" then
        print("Redstone changed")
    elseif event == "timer" then
        print("Timer", p1, "completed")
    end
end
```

## Parallel Processing Pattern
```lua
local function task1()
    while true do
        print("Task 1 running")
        sleep(1)
    end
end

local function task2()
    while true do
        print("Task 2 running")
        sleep(2)
    end
end

parallel.waitForAll(task1, task2)
```

## Turtle Movement with Error Checking
```lua
local function move(direction)
    local success, error = direction()
    if not success then
        print("Movement failed:", error)
        return false
    end
    return true
end

-- Usage
if move(turtle.forward) then
    print("Moved forward successfully")
end
```

## File Handling Pattern
```lua
local function readFile(path)
    local file = fs.open(path, "r")
    if not file then
        error("Could not open file: " .. path)
    end
    
    local content = file.readAll()
    file.close()
    return content
end

local function writeFile(path, content)
    local file = fs.open(path, "w")
    if not file then
        error("Could not open file for writing: " .. path)
    end
    
    file.write(content)
    file.close()
end
```

## HTTP Request Pattern
```lua
local function httpGet(url)
    local response = http.get(url)
    if not response then
        error("HTTP request failed")
    end
    
    local content = response.readAll()
    response.close()
    return content
end

-- Async HTTP pattern
http.request("https://example.com")
local event, url, handle = os.pullEvent("http_success")
local content = handle.readAll()
handle.close()
```

## Peripheral Management Pattern
```lua
local function findPeripheral(peripheralType)
    local peripherals = {peripheral.find(peripheralType)}
    if #peripherals == 0 then
        error("No " .. peripheralType .. " found")
    end
    return peripherals[1]
end

-- Usage
local monitor = findPeripheral("monitor")
monitor.clear()
monitor.setCursorPos(1, 1)
monitor.write("Hello, World!")
```

---

This comprehensive documentation covers all major APIs, functions, peripherals, events, and common patterns in CC:Tweaked. Always refer to the official documentation at https://tweaked.cc/ for the most up-to-date information and detailed examples.