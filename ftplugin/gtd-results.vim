" Vim filetype plugin
" Language:	Gtd-results

if exists("b:did_ftplugin")
	finish
endif

execute 'setlocal nomodifiable'
execute 'setlocal buftype=nofile'
execute 'setlocal bufhidden=wipe'
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
execute 'setlocal conceallevel=2'
execute 'setlocal concealcursor=nvic'

execute 'silent! file! Gtd results'

if !hasmapto('<Plug>GtdEdit')
	execute 'nmap <buffer>' g:gtd#map_edit '<Plug>GtdEdit'
endif
execute "nnoremap <buffer> <silent> <Plug>GtdEdit :call gtd#results#Edit(line('.'))<CR>"
let b:undo_ftplugin = 'execute "nunmap <buffer> <Plug>GtdEdit"'

if !hasmapto('<Plug>GtdRefresh')
	execute 'nmap <buffer>' g:gtd#map_refresh '<Plug>GtdRefresh'
endif
execute "nnoremap <buffer> <silent> <Plug>GtdRefresh :GtdRefresh<CR>"
let b:undo_ftplugin = 'execute "nunmap <buffer> <Plug>GtdRefresh"'

if !hasmapto('<Plug>GtdBrowseOlder')
	execute 'nmap <buffer>' g:gtd#map_browse_older '<Plug>GtdBrowseOlder'
endif
execute "nnoremap <buffer> <silent> <Plug>GtdBrowseOlder :call gtd#results#Browse(-1)<CR>"
let b:undo_ftplugin = ' | execute "nunmap <buffer> <Plug>GtdBrowseOlder"'

if !hasmapto('<Plug>GtdBrowseNewer')
	execute 'nmap <buffer>' g:gtd#map_browse_newer '<Plug>GtdBrowseNewer'
endif
execute "nnoremap <buffer> <silent> <Plug>GtdBrowseNewer :call gtd#results#Browse(1)<CR>"
let b:undo_ftplugin = ' | execute "nunmap <buffer> <Plug>GtdBrowseNewer"'

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
	autocmd!
	execute 'command! -buffer -nargs=1 GtdDo call gtd#results#Do(<q-args>)'
	execute 'autocmd BufUnload <buffer> call gtd#results#Close()'
augroup END

let b:did_ftplugin = 1

