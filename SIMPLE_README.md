# TurtleCraft Simple Version

A simplified crafting system for ComputerCraft: Tweaked that coordinates between a Jobs Computer (ME System) and Crafting Turtles.

## Key Features

- **Direct item transfer** - Items sent directly from ME to turtle inventory
- **Recipe-based crafting** - Turtles have built-in recipes and know what they need
- **Smart waiting** - Turtles wait for all items to arrive before crafting (15 second timeout)
- **Minimal code** - Easy to understand and modify (~230 lines each file)

## Architecture

```
ME System (Applied Energistics)
    |
    v
Jobs Computer (with ME Bridge)
    |
    | (direct peripheral transfer via wired network)
    v
Crafting Turtles
```

## Setup

### Jobs Computer
1. Place computer with ME Bridge on **back** side
2. Connect to wired network with networking cable
3. Attach wireless modem for rednet
4. Label computer: `set jobs`
5. Run: `startup`

### Crafting Turtles
1. Place crafting turtle
2. Connect to same wired network as Jobs Computer
3. Attach wireless modem for rednet
4. Run: `startup`

## How It Works

1. **Registration**: Turtle finds Jobs Computer via rednet and registers
2. **Discovery**: Jobs Computer discovers turtle's peripheral name on wired network
3. **Crafting Process**:
   - Turtle checks recipe for required items
   - Requests each ingredient from Jobs Computer
   - Jobs Computer exports items directly to turtle via `exportItemToPeripheral`
   - Turtle waits up to 15 seconds for items to arrive in inventory
   - Once all items arrive, turtle arranges them and crafts
   - Results are pulled back to ME system

## Files

- `jobs_computer.lua` - ME System manager (237 lines)
- `turtle.lua` - Crafting turtle with recipes (374 lines)
- `startup.lua` - Auto-start script (49 lines)
- `installer.lua` - Simple installer (49 lines)

## Adding Recipes

Edit the `recipes` table in `turtle.lua`:

```lua
["minecraft:item_id"] = {
    name = "Display Name",
    result = {item = "minecraft:item_id", count = 1},
    ingredients = {
        {item = "minecraft:ingredient", count = 1, slot = 1},
        -- slot numbers: 1,2,3,5,6,7,9,10,11 (3x3 grid)
    }
}
```

## Troubleshooting

- **"Turtle not identified"**: Press D on Jobs Computer to run discovery
- **Items not arriving**: Check wired network connections
- **ME Bridge not found**: Check `ME_BRIDGE_SIDE` setting in jobs_computer.lua
- **Crafting fails**: Verify recipe slots match Minecraft crafting grid