" Vim filetype plugin
" Language:	Gtd-results

if exists("b:did_ftplugin")
	finish
endif

execute 'setlocal nomodifiable'
execute 'setlocal buftype=nofile'
execute 'setlocal bufhidden=unload'
execute 'setlocal nobuflisted'
execute 'setlocal noswapfile'
execute 'setlocal nowrap'
execute 'setlocal nospell'
execute 'setlocal nonumber'
execute 'setlocal norelativenumber'
execute 'setlocal nolist'
execute 'setlocal foldcolumn=0'
execute 'setlocal foldlevel=1'
execute 'setlocal textwidth=0'
execute 'setlocal noundofile'
execute 'setlocal colorcolumn=0'
execute 'setlocal cursorline'

execute 'silent! file! Gtd results'

execute "nnoremap <buffer> <silent> <Enter> :call gtd#results#Edit(line('.'))<CR>"
let b:undo_ftplugin = 'execute "nunmap <buffer> <Enter>"'

execute "nnoremap <buffer> <silent> <C-Left> :call gtd#results#Browse(-1)<CR>"
let b:undo_ftplugin = ' | execute "nunmap <buffer> <C-Left>"'

execute "nnoremap <buffer> <silent> <C-Right> :call gtd#results#Browse(1)<CR>"
let b:undo_ftplugin = ' | execute "nunmap <buffer> <C-Right>"'

if has('folding')

	" Folding function
	function! GtdResultsFold()
		let l:line = getline(v:lnum)
		if match(l:line, '^[^ ].\+$') != -1
			return '>1'
		elseif match(l:line, '^$') != -1
			return 0
		else
			return '='
		endif
	endfunction

	setlocal foldexpr=GtdResultsFold()
	setlocal foldmethod=expr
	let b:undo_ftplugin .= ' | setlocal foldexpr< foldmethod<'
endif

augroup gtd-results
	execute 'autocmd BufUnload <buffer> call gtd#results#Close()'
augroup END

let b:did_ftplugin = 1

