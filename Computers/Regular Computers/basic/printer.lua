-- Interactive Page Writer

-- Clear and setup
term.clear()
term.setCursorPos(1, 1)

-- Get title input
write("Enter the page title: ")
local title = read()

-- Get content input
write("Enter the page content: ")
local content = read()

-- Display the page
term.clear()
term.setCursorPos(1, 1)

-- Set title in bold (if available)
term.setTextColor(colors.yellow)
print("=== " .. title .. " ===")
term.setTextColor(colors.white)

print("")
print(content)
print("")

-- Wait for the user to press a key to exit
print("\nPress any key to exit...")
os.pullEvent("key")
