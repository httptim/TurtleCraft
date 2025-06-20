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
    -- Check if this is the jobs computer
    local label = os.getComputerLabel()
    
    if label and label:lower() == "jobs" then
        print("Detected: Jobs Computer (by label)")
        print("Starting jobs computer...")
        sleep(1)
        shell.run("jobs_computer.lua")
    else
        -- Unknown computer type
        print("Detected: Computer")
        print()
        print("This computer is not configured.")
        print()
        print("Options:")
        print("1. Run Jobs Computer")
        print("2. Exit")
        print()
        print("Note: To automatically start the Jobs Computer,")
        print("set the computer label to 'jobs' using:")
        print("  label set jobs")
        print()
        write("Choice (1-2): ")
        
        local choice = read()
        
        if choice == "1" then
            shell.run("jobs_computer.lua")
        else
            print()
            print("Exiting startup.")
        end
    end
end