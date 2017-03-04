" Vim filetype plugin
" Language:	Gtd

if exists("b:did_ftplugin")
	finish
endif

command! -buffer -nargs=0 GtdFiles call gtd#Files()
let b:undo_ftplugin = 'execute "delcommand GtdFiles"'

execute "nnoremap <buffer> <silent> <Plug>GtdAttachedFiles :GtdFiles<CR>"
let b:undo_ftplugin .= ' | execute "nunmap <buffer> <Plug>GtdAttachedFiles"'

command! -buffer -nargs=0 GtdExplore call gtd#Explore()
let b:undo_ftplugin .= ' | execute "delcommand GtdExplore"'

execute "nnoremap <buffer> <silent> <Plug>GtdExplore :GtdExplore<CR>"
let b:undo_ftplugin .= ' | execute "nunmap <buffer> <Plug>GtdExplore"'

setlocal completefunc=gtd#search#InsertTagComplete
let b:undo_ftplugin .= ' | setlocal completefunc<'

function! GtdMarkdowFold()
	let l:fold_level = match(getline(v:lnum), '^#\{1,6}\zs .*$')
	if l:fold_level > 0
		return '>'.l:fold_level
	else
		return '='
	endif
endfunction

if has('folding') && g:gtd#folding == 1
	setlocal foldexpr=GtdMarkdowFold()
	setlocal foldmethod=expr
	let b:undo_ftplugin .= ' | setlocal foldexpr< foldmethod<'
endif

let b:did_ftplugin = 1

