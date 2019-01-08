
function! gtd#files#Open()

	try
		let l:gtd_note_dir = gtd#files#DirGet()

		" Creation of the directory if needed
		if !gtd#files#DirTest(l:gtd_note_dir)
			\ && (!exists('*mkdir') || !mkdir(l:gtd_note_dir))
			throw "Gtd note directory ".l:gtd_note_dir." can't be created"
		endif

		" Browsing directory
		execute 'silent !'.g:gtd#folder_command.' '.l:gtd_note_dir

		" We wait the user to continue...
		call input("Hit enter to continue")

		if gtd#files#DirTest(l:gtd_note_dir)
			if empty(glob(l:gtd_note_dir.'/**'))
				if delete(l:gtd_note_dir, 'd') == 0
					call s:GtdFilesTagRemove()
				else
					throw "Gtd note directory couldn't be deleted"
				endif
			else
				call s:GtdFilesTagAdd()
			endif
		else
			throw "Gtd note directory couldn't be found"
		endif
		execute "redraw!"
	catch /.*/
		execute "redraw!"
		echomsg v:exception
	endtry

endfunction

function! gtd#files#Explore()
	let l:gtd_note_dir = gtd#files#DirGet()

	if !gtd#files#DirTest(l:gtd_note_dir)
		echomsg "Gtd note directory ".l:gtd_note_dir." doesn't exist"
	else
		execute "Vexplore" l:gtd_note_dir
	endif
endfunction

function! gtd#files#DirGet()
	return expand('%:p:r')
endfunction

function! gtd#files#DirTest(dir)
	return isdirectory(a:dir)
endfunction

function! s:GtdFilesTagTest()
	return getline(1) =~ '^=.* \[\*\]$'
endfunction

function! s:GtdFilesTagAdd()
	let l:title = getline(1)
	if l:title =~ '^=' && !s:GtdFilesTagTest()
		call setline(1, substitute(l:title, '\s*$', ' \[\*\]', ''))
	endif
endfunction

function! s:GtdFilesTagRemove()
	let l:title = getline(1)
	if l:title =~ '^=' && s:GtdFilesTagTest()
		call setline(1, substitute(l:title, ' \[\*\]$', '', ''))
	endif
endfunction

