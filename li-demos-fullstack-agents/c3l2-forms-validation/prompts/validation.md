Add validation to the add-task form. The page checks the title with the same rule as the server (trimmed, 1 to 120 characters) and shows
a plain message in the element with role="alert" before it sends anything. A 401 shows "Not authorised: check the token." The server still checks everything:
the page is a courtesy, not a defence. Add a test for each message. Do not use alert().
