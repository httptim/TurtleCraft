-- Simple TurtleCraft Installer

print("=== TurtleCraft Simple Installer ===")
print("Installing simple crafting system...")
print()

-- Files to download from pastebin or local source
local files = {
    ["startup.lua"] = "startup.lua",
    ["jobs_computer.lua"] = "jobs_computer.lua", 
    ["turtle.lua"] = "turtle.lua"
}

-- Download/copy files
for source, dest in pairs(files) do
    if fs.exists(source) then
        print("Installing " .. dest .. "...")
        if fs.exists(dest) and dest ~= source then
            fs.delete(dest)
        end
        if source ~= dest then
            fs.copy(source, dest)
        end
    else
        print("Warning: " .. source .. " not found")
    end
end

print()
print("Installation complete!")
print()
print("Setup Instructions:")
print("1. Jobs Computer:")
print("   - Attach ME Bridge on back side")
print("   - Attach wireless modem")
print("   - Run: startup")
print()
print("2. Crafting Turtles:") 
print("   - Place chest in front")
print("   - Attach wireless modem")
print("   - Run: startup")
print()
print("The system uses a chest-based exchange:")
print("- Jobs Computer exports items to chest")
print("- Turtles pull items from chest")
print("- Turtles deposit crafted items back")
print()
print("Press any key to continue...")
os.pullEvent("key")