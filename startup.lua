-- TurtleCraft Startup Script
-- Detects computer type and runs appropriate program

print("TurtleCraft Startup")
print("===================")
print()

-- Check what type of computer this is
if turtle then
    print("Detected: Turtle")
    print("Starting turtle client...")
    sleep(1)
    shell.run("turtle.lua")
else
    print("Detected: Computer")
    print()
    print("Select program to run:")
    print("1. Jobs Computer")
    print("2. Main Computer") 
    print("3. Network Test")
    print("4. Exit")
    print()
    write("Choice: ")
    
    local choice = read()
    
    if choice == "1" then
        shell.run("jobs_computer.lua")
    elseif choice == "2" then
        shell.run("main_computer.lua")
    elseif choice == "3" then
        shell.run("test_network.lua")
    end
end