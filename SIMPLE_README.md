# TurtleCraft Simple Version

A simplified crafting system for ComputerCraft: Tweaked that coordinates between a Jobs Computer (ME System) and Crafting Turtles.

## Key Features

- **No timing issues** - Simple fixed delays ensure items arrive before crafting
- **Chest-based exchange** - Items are transferred through chests, not complex networking
- **Minimal code** - Easy to understand and modify
- **No main computer** - Just Jobs Computer and Turtles

## Architecture

```
ME System
    |
    v
Jobs Computer (with ME Bridge)
    |
    v
Chest (item exchange point)
    |
    v
Crafting Turtles
```

## Setup

### Jobs Computer
1. Place computer with ME Bridge on **back** side
2. Attach wireless modem
3. Place chest on **top** for item export
4. Label computer: `set jobs`
5. Run: `startup`

### Crafting Turtles
1. Place crafting turtle
2. Attach wireless modem  
3. Place chest in **front** for item pickup/deposit
4. Run: `startup`

## How It Works

1. Turtle requests items from Jobs Computer via rednet
2. Jobs Computer exports items from ME to chest
3. Jobs Computer waits 2 seconds for transfer to complete
4. Jobs Computer tells turtle items are ready
5. Turtle waits 3 more seconds to be sure
6. Turtle pulls items from chest
7. Turtle crafts
8. Turtle deposits results back to chest

## Files

- `jobs_computer.lua` - ME System manager
- `turtle.lua` - Crafting turtle program
- `startup.lua` - Auto-start script
- `installer.lua` - Simple installer

## Configuration

Edit these constants in the files:

**jobs_computer.lua:**
- `ME_BRIDGE_SIDE = "back"` - Which side the ME Bridge is on
- Item export direction in line with `exportItem`

**turtle.lua:**
- `CHEST_DIRECTION = "front"` - Where turtle gets/puts items

## Troubleshooting

- **Items not arriving**: Increase wait times in code
- **ME Bridge not found**: Check `ME_BRIDGE_SIDE` setting
- **Turtles not connecting**: Ensure wireless modems attached
- **Crafting fails**: Check chest placement and directions