
function! s:GtdNoteTemplate()
	return [
		\ '=',
		\ '@'.g:gtd#default_context,
		\ '!'.g:gtd#default_action
		\ ]
endfunction

function! gtd#note#Key(key, value)
	return fnamemodify(a:value, ':t:r')
endfunction

function! gtd#note#GetAll(mode)
	let l:all_files = glob(g:gtd#dir.'*.gtd', 0, 1)
	if a:mode == 'full'
		return l:all_files
	elseif a:mode == 'short'
		return map(
			\ l:all_files,
			\ function('gtd#note#Key')
			\ )
	endif
endfunction

function! gtd#note#Read(note, count)
	if a:count == 0
		return readfile(a:note)
	else
		return readfile(a:note, '', a:count)
	endif
endfunction

function! gtd#note#Create(mods, command, bang, isrange) range

	" a:isrange is deduced from <count>
	" Ugly workaround :
	" - to avoid having one line insertion when no range is really given
	" - and having a lonely command to do both note creation from scratch and
	"   from selection.

	try
		let l:content = s:GtdNoteTemplate()
		if a:isrange != -1
			if a:firstline == a:lastline
				let l:line = getline(a:firstline)
				if !empty(l:line)
					let l:content += [ '', l:line ]
				endif
			else
				let l:content += [ '' ] + getline(a:firstline, a:lastline)
			endif
		endif

		execute a:mods a:command.a:bang fnamemodify(
			\ g:gtd#dir.strftime("%Y%m%d_%H%M%S").'.gtd',
			\ ':.'
			\ )

		if append(0, l:content)
			throw "Gtd default content couldn't be inserted"
		else
			execute 'normal! gg'
			execute 'startinsert!'
		endif
	catch /.*/
		echomsg v:exception
	endtry

endfunction

function! gtd#note#Delete()
	let l:gtd_note_dir = gtd#files#DirGet()
	let [ l:confirm, l:gtd_note_dir_test ] = [
		\ 1,
		\ gtd#files#DirTest(l:gtd_note_dir)
		\ ]

	if l:gtd_note_dir_test
		\ && input("Attached files found. Do you confirm? (Y/N) ") != 'Y'
		let l:confirm = 0
	endif

	if l:confirm
		if l:gtd_note_dir_test
			if delete(l:gtd_note_dir, 'rf') != 0
				redraw | echomsg "Attached files couldn't be deleted"
			endif
		endif

		let l:gtd_note_file = expand('%:p')
		if !empty(glob(l:gtd_note_file))
			if delete(l:gtd_note_file) == 0
				execute 'bwipeout!'
			else
				redraw | echomsg "GTD file couldn't be deleted"
			endif

			let l:key = gtd#note#Key('N/A', l:gtd_note_file)
			if g:gtd#cache
				call gtd#cache#Delete(l:key)
			endif

			call gtd#results#Remove(l:key)
		else
			execute 'bwipeout!'
		endif
	else
		redraw | echomsg "Deletion cancelled"
	endif
endfunction

