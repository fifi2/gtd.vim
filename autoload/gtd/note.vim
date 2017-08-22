
function! gtd#note#Create(bang, mods, range_start, range_end)

	try
		if empty(a:mods)
			let l:action = 'edit'.a:bang
		else
			let l:action = a:mods.' split'
		endif
		let l:template = s:GtdNoteTemplate(a:range_start, a:range_end)
		execute l:action fnamemodify(g:gtd#dir.strftime("%Y%m%d_%H%M%S").'.gtd', ':.')
		if append(0, l:template)
			throw "Gtd template couldn't be inserted"
		else
			execute 'normal! gg'
			execute 'startinsert!'
		endif
	catch /.*/
		echomsg v:exception
	endtry

endfunction

function! gtd#note#Read(note, count)
	if a:count == 0
		return readfile(a:note)
	else
		return readfile(a:note, '', a:count)
	endif
endfunction

function! s:GtdNoteTemplate(range_start, range_end)
	let l:template = []
	let l:template += [ '=' ]
	if !empty(g:gtd#default_context)
		let l:template += [ '@'.g:gtd#default_context ]
	endif
	if !empty(g:gtd#default_action)
		let l:template += [ '!'.g:gtd#default_action ]
	endif
	if a:range_start != 0 && a:range_end != 0
		let l:template += [ '' ] + getline(a:range_start, a:range_end)
	endif
	return l:template
endfunction

