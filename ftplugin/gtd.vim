" Vim filetype plugin
" Language:	Gtd

if exists("b:did_ftplugin")
	finish
endif

command! -buffer -nargs=0 GtdFiles call gtd#files#Open()
let b:undo_ftplugin = 'execute "delcommand GtdFiles"'

execute "nnoremap <buffer> <silent> <Plug>GtdFiles :GtdFiles<CR>"
let b:undo_ftplugin .= ' | execute "nunmap <buffer> <Plug>GtdFiles"'

command! -buffer -nargs=0 GtdExplore call gtd#files#Explore()
let b:undo_ftplugin .= ' | execute "delcommand GtdExplore"'

execute "nnoremap <buffer> <silent> <Plug>GtdExplore :GtdExplore<CR>"
let b:undo_ftplugin .= ' | execute "nunmap <buffer> <Plug>GtdExplore"'

command! -buffer -nargs=0 GtdDelete call gtd#note#Delete()
let b:undo_ftplugin .= ' | execute "delcommand GtdDelete"'

setlocal completefunc=gtd#search#InsertTagComplete
let b:undo_ftplugin .= ' | setlocal completefunc<'

" Define Gtd folding for markdown chapters
if has('folding') && g:gtd#folding == 1

	" Folding function
	function! GtdMarkdowFold()
		let l:line = getline(v:lnum)
		let l:fold_level = match(l:line, '^#\{1,6}\zs .*$')
		if l:fold_level > 0
			return '>'.l:fold_level
		elseif  l:line =~ '{\{3}'
			return 'a1'
		elseif  l:line =~ '}\{3}'
			return 's1'
		else
			return '='
		endif
	endfunction

	setlocal foldexpr=GtdMarkdowFold()
	setlocal foldmethod=expr
	let b:undo_ftplugin .= ' | setlocal foldexpr< foldmethod<'
endif

let b:did_ftplugin = 1

