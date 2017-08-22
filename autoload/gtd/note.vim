
function! gtd#note#Read(note, count)
	if a:count == 0
		return readfile(a:note)
	else
		return readfile(a:note, '', a:count)
	endif
endfunction

