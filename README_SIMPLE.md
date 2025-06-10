# TurtleCraft - Simple Network Implementation

This is a simplified, working implementation of TurtleCraft that focuses on getting the network connectivity working properly.

## Quick Start

### Installation
```
wget run https://raw.githubusercontent.com/httptim/TurtleCraft/main/installer.lua
```

### Setup Requirements
1. **Jobs Computer** - Must be Computer ID 2 (or update config.lua)
   - Needs wireless modem attached
   
2. **Main Computer** - Any ID
   - Needs wireless modem attached
   
3. **Turtles** - Must be Crafty Turtles
   - Need wireless modem attached

### Running the System

**IMPORTANT: Start in this order!**

1. **Start Jobs Computer FIRST**:
   ```
   start-jobs
   ```
   The Jobs Computer will host itself on the network.

2. **Start Main Computer**:
   ```
   start-main
   ```
   It will automatically find and connect to the Jobs Computer.

3. **Start Turtles**:
   ```
   start-turtle
   ```
   They will register with the Jobs Computer.

### Testing

Run the network test on any computer:
```
test_network
```

This will show you what computers are visible on the network.

### Troubleshooting

1. **Main Computer can't find Jobs Computer**:
   - Make sure Jobs Computer is running first
   - Check that wireless modems are activated (right-click them)
   - Verify Jobs Computer is ID 2 (or update config.lua)
   - Run `test_network` to see what's on the network

2. **Debug Mode**:
   - Debug is ON by default in config.lua
   - You'll see all network messages in the console
   - Turn it off by setting `DEBUG = false` in config.lua

### Files Included

- `config.lua` - Simple configuration (Jobs Computer ID, protocol name)
- `lib/network.lua` - Clean network library using rednet properly
- `jobs_computer.lua` - Central manager
- `main_computer.lua` - User interface
- `turtle.lua` - Turtle client
- `startup.lua` - Menu selector
- `test_network.lua` - Network testing tool

### Key Differences from Full Version

This simplified version:
- Uses proper rednet hosting and lookup
- Has working network discovery
- Shows debug messages by default
- Doesn't include the complex peripheral detection
- Focuses on core connectivity

Once the network is working, additional features can be added back incrementally.