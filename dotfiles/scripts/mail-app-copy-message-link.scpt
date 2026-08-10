tell application "Mail"
	set selectedMessages to selection
	
	if (count selectedMessages) is 0 then
		display alert "Copy Message Link" message "No messages are selected in Mail."
		return
	end if
	
	set messageURLs to {}
	
	repeat with msg in selectedMessages
		try
			set messageID to message id of msg
			
			if messageID is not missing value and messageID is not "" then
				set end of messageURLs to "message://%3C" & messageID & "%3E"
			end if
		end try
	end repeat
end tell

if (count messageURLs) is 0 then
	display alert "Copy Message Link" message "None of the selected messages has a usable Message-ID."
	return
end if

set oldTID to AppleScript's text item delimiters
try
	set AppleScript's text item delimiters to linefeed
	set output to messageURLs as text
	set AppleScript's text item delimiters to oldTID
on error errMsg number errNum
	set AppleScript's text item delimiters to oldTID
	error errMsg number errNum
end try

set the clipboard to output
