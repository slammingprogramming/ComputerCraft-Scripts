-- Printer Page Writer

-- Make sure there's a printer peripheral
local printer = peripheral.find("printer")
if not printer then
    print("No printer found. Please attach a printer.")
    return
end

-- Get user input
term.clear()
term.setCursorPos(1, 1)

write("Enter the page title: ")
local title = read()

write("Enter the page content: ")
local content = read()

-- Start a new page
if not printer.newPage() then
    print("Failed to start a new page. Out of paper or ink?")
    return
end

-- Print the title in bold
printer.setCursorPos(1, 1)
printer.write("== " .. title .. " ==")

-- Move to next line
printer.setCursorPos(1, 3)

-- Print the content (wraps automatically)
printer.write(content)

-- End and print the page
if not printer.endPage() then
    print("Failed to print the page.")
else
    print("Page printed successfully!")
end
