# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a ComputerCraft: Tweaked project using Lua 5.2 (with select Lua 5.3 features) for in-game computer programming in Minecraft.

## Critical Development Requirements

### Documentation Reference
- **ALWAYS** consult the `docs/CCTweaked.md` file in this repository before implementing any CC:Tweaked functionality
- This ensures consistency in API usage across the entire project
- The docs file contains comprehensive API documentation and critical compatibility notes

### Lua Version Compatibility
- CC:Tweaked uses **Lua 5.2 with select Lua 5.3 features**
- Available Lua 5.3 features: UTF-8 basics, integer division (//), bitwise operators (&, |, ~, <<, >>)
- NOT available: Full UTF-8 library, some string patterns, certain metamethods
- Always verify advanced Lua syntax compatibility: https://tweaked.cc/reference/feature_compat.html

### Official Documentation
- Base documentation URL: https://tweaked.cc/
- Breaking changes reference: https://tweaked.cc/reference/breaking_changes.html

## Coding Conventions

### File Structure
```lua
-- File purpose and description
-- Author: [Name]

-- Configuration constants at the top
local CONSTANT_NAME = "value"

-- Local variable declarations
local variableName = nil

-- Table definitions
local tableName = {
    {key = "value", another = "value"},
}

-- Helper functions
local function functionName(param1, param2)
    -- Function implementation
end

-- Main program logic at the bottom
```

### Naming Conventions
- **Constants**: `UPPERCASE_WITH_UNDERSCORES`
- **Local variables**: `camelCase`
- **Functions**: `camelCase`
- **Tables/Objects**: `camelCase`
- **Files**: `lowercase-with-hyphens.lua` or `camelCase.lua`

### Code Style
- Use 4-space indentation
- Always use `local` keyword for variable scoping
- Place opening braces on the same line for tables
- Separate logical sections with blank lines
- Use single-line comments (`--`) for documentation
- Comment above code blocks to explain functionality

### Color Scheme (for UI programs)
Define a consistent color table:
```lua
local colors = {
    title = colors.yellow,
    error = colors.red,
    success = colors.green,
    info = colors.lightBlue,
    background = colors.black,
    text = colors.white
}
```

## Key APIs and Concepts

### Core APIs to Reference
- **Global Functions (_G)**: sleep(), write(), print(), printError(), read()
- **os API**: Event handling with os.pullEvent(), timers, computer management
- **fs API**: File system operations
- **peripheral API**: Interact with Minecraft blocks and devices
- **rednet/http APIs**: Networking capabilities
- **term API**: Terminal/screen manipulation

### Event-Driven Architecture
CC:Tweaked programs are event-driven. Key concepts:
- Use `os.pullEvent()` for event handling
- Implement proper yielding with `sleep()` to avoid "Too long without yielding" errors
- Handle common events: key, char, mouse_click, timer, redstone, peripheral

### Error Handling
- Use `printError()` for error messages
- Implement proper error handling with pcall() for critical operations
- Provide user-friendly error messages

## Project Structure Guidelines

### Recommended Directory Structure
```
/startup.lua          # Main program entry point
/lib/                 # Shared libraries and utilities
/config/              # Configuration files
/data/                # Persistent storage
/src/                 # Source code modules (for larger projects)
  /client/           # Client-side code
  /server/           # Server-side code
  /common/           # Shared code
```

### Module Pattern
```lua
-- mymodule.lua
local M = {}

function M.publicFunction()
    -- Implementation
end

local function privateFunction()
    -- Implementation
end

return M
```

## Development Workflow

Since this is a CC:Tweaked Lua project, there are no traditional build/test commands. Development workflow:
- Write Lua files following the conventions above
- Test directly in Minecraft on CC:Tweaked computers
- Use `pastebin` or file transfer methods to deploy code
- Consider creating an installer.lua for easy deployment

## Important Reminders

- Always check `docs/CCTweaked.md` for API usage and examples
- All code must be compatible with CC:Tweaked's Lua environment
- Test on actual CC:Tweaked computers as behavior may differ from standard Lua
- Consider peripheral availability when designing features