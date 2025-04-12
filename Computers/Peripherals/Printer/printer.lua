-- Find the printer peripheral by side or auto-detect
local printer = peripheral.find("printer")

if not printer then
    print("Error: No printer block found. Attach a printer.")
    return
end

-- Prompt user for title and content
term.clear()
term.setCursorPos(1,1)
write("Enter a title for your page: ")
local title = read()

write("Enter the content to print: ")
local content = read()

-- Try to start a new page
if not printer.newPage() then
    print("Error: Could not start a new page. Check paper and ink.")
    return
end

-- Write title centered and bold
printer.setCursorPos(1, 1)
printer.write("=== " .. title .. " ===")

-- Leave a space, then write content starting at line 3
printer.setCursorPos(1, 3)
printer.write(content)

-- End the page (physically prints it)
local success = printer.endPage()
if success then
    print("Page printed successfully!")
else
    print("Failed to end the page. Check printer again.")
end
