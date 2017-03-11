" Vim auto-load file

function! gtd#Init()

	try
		if !exists('g:gtd#dir')
			let g:gtd#dir = '.'
		elseif !isdirectory(expand(g:gtd#dir))
			throw "Gtd directory has not been set properly (g:gtd#dir)"
		endif
		let g:gtd#dir = fnamemodify(g:gtd#dir, ':p')

		if !exists('g:gtd#debug') || g:gtd#debug != 1
			let g:gtd#debug = 0
		endif

		if !exists('g:gtd#cache') || g:gtd#cache != 1
			let g:gtd#cache = 0
		endif

		if !exists('g:gtd#default_action') || empty(g:gtd#default_action)
			let g:gtd#default_action = ''
		endif

		if !exists('g:gtd#default_context') || empty(g:gtd#default_context)
			let g:gtd#default_context = ''
		endif

		if !exists('g:gtd#review') || type(g:gtd#review) != v:t_list
			let g:gtd#review = []
		endif

		if !exists('g:gtd#folding') || g:gtd#folding != 1
			let g:gtd#folding = 0
		endif

		if !exists('g:gtd#tag_lines_count')
			\ || type(g:gtd#tag_lines_count) != v:t_number
			let g:gtd#tag_lines_count = 20
		endif

		return 1

	catch /.*/
		echomsg v:exception
		return 0
	endtry

endfunction

function! gtd#Debug(message)
	if g:gtd#debug
		echo a:message
	endif
endfunction

function! gtd#Files()

	try
		let l:gtd_note_dir = expand('%:r')

		" Creation of the directory if needed
		if !isdirectory(l:gtd_note_dir)
			\ && (!exists('*mkdir') || !mkdir(l:gtd_note_dir))
			throw "Gtd note directory ".l:gtd_note_dir." can't be created"
		endif

		" Browsing directory
		if has('win32')
			execute 'silent !explorer.exe' l:gtd_note_dir
		else
			" TODO Test it
			execute 'silent !xdg-open' l:gtd_note_dir
		endif

		" We wait the user to continue...
		call input("Hit enter to continue")

		if isdirectory(l:gtd_note_dir)
			if empty(glob(l:gtd_note_dir.'/**'))
				let delete_test = delete(l:gtd_note_dir, 'd')
				if delete_test == 0
					call s:AttachedFilesTagRemove()
				else
					throw "Gtd note directory couldn't be deleted"
				endif
			else
				call s:AttachedFilesTagAdd()
			endif
		else
			throw "Gtd note directory couldn't be found"
		endif
	catch /.*/
		echomsg v:exception
	endtry

endfunction

function! gtd#Explore()
	execute "Vexplore" expand('%:r')
endfunction

function! gtd#Review(mods)

	if empty(g:gtd#review)
		echo "Gtd review has not been set (g:gtd#review)"
	else
		let l:debug_switch = s:GtdDebugSwitch(0)
		let l:debug_reactivate = 0

		let l:split = 1

		if a:mods == 'tab' && l:split == 1
			execute 'tabedit'
		endif

		let open = []
		for g in g:gtd#review
			if l:split
				if empty(l:open)
					if a:mods != 'tab'
						execute 'enew'
					endif
				else
					execute 'belowright new'
				endif
			else
				execute 'tabedit'
			endif
			let l:bufnr = bufnr('%')
			if !l:split
				call add(open, tabpagenr())
			endif
			silent call gtd#search#Start(g, 'new', '!')
			" Focus is now to the location list
			setlocal nowinfixheight nowinfixwidth
			if l:split
				call add(open, bufnr('%'))
			endif
			execute 'silent bw' l:bufnr
		endfor
		execute 'normal!' open[0].'gt'

		if l:debug_switch
			call s:GtdDebugSwitch(1)
		endif
	endif

endfunction

function! gtd#Refresh()
	let l:current_search_args = gtd#quickfix#ArgsGet()
	if !empty(l:current_search_args)
		call gtd#search#Start(l:current_search_args, 'refresh', '!')
	else
		echo "No current Gtd search available"
	endif
endfunction

function! gtd#New(bang, mods)
	call s:GtdNew(a:bang, a:mods, 0, 0)
endfunction

function! gtd#NewFromSelection(bang, mods) range
	call s:GtdNew(a:bang, a:mods, a:firstline, a:lastline)
endfunction

function! gtd#Bench(formula)
	let l:debug_switch = s:GtdDebugSwitch(0)
	try
		let l:i = 0
		let l:bench_sum = 0.0
		let l:bench_nb = 100
		while l:i < l:bench_nb
			let l:start_time = reltime()
			silent call gtd#search#Start(a:formula, 'new', '')
			let l:bench_sum = l:bench_sum
				\ + reltimefloat(reltime(l:start_time))
			let l:i = l:i+1
		endwhile
	catch /^Vim:Interrupt$/
		let l:i = l:bench_nb
		echoerr "Gtd Interruption"
	endtry
	let l:bench_avg = l:bench_sum / l:bench_nb
	echo "Gtd benchmark:" l:bench_avg
	if l:debug_switch
		call s:GtdDebugSwitch(1)
	endif
endfunction

function! gtd#Context(context)
	if a:context =~ '@\S\+'
		let g:gtd#default_context = a:context[1:]
		echo "Gtd context is now:" a:context
	else
		echo "Gtd context doesn't seem legit"
	endif
endfunction

function! s:GtdNew(bang, mods, range_start, range_end)

	try
		let l:gtd_date = strftime("%Y%m%d_%H%M%S")
		let l:gtd_note = g:gtd#dir.l:gtd_date.'.gtd'
		let l:template = s:Template(a:range_start, a:range_end)
		if empty(a:mods)
			let l:action = 'edit'.a:bang
		else
			let l:action = a:mods.' split'
		endif
		execute l:action.' '.l:gtd_note
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

function! s:Template(range_start, range_end)
	let l:template = []
	call add(l:template, '=')
	if !empty(g:gtd#default_context)
		call add(l:template, '@'.g:gtd#default_context)
	endif
	if !empty(g:gtd#default_action)
		call add(l:template, '!'.g:gtd#default_action)
	endif
	if a:range_start != 0 && a:range_end != 0
		call add(l:template, '')
		let l:selection = getline(a:range_start, a:range_end)
		let l:template = l:template + l:selection
	endif
	return l:template
endfunction

function! s:AttachedFilesTagTest()
	return getline(1) =~ '^=.* \[\*\]$'
endfunction

function! s:AttachedFilesTagAdd()
	let l:title = getline(1)
	if l:title =~ '^=' && !s:AttachedFilesTagTest()
		call setline(1, substitute(l:title, '\s*$', ' \[\*\]', ''))
	endif
endfunction

function! s:AttachedFilesTagRemove()
	let l:title = getline(1)
	if l:title =~ '^=' && s:AttachedFilesTagTest()
		call setline(1, substitute(l:title, ' \[\*\]$', '', ''))
	endif
endfunction

function! s:GtdDebugSwitch(target)
	let l:switch_done = 0
	if g:gtd#debug != a:target
		let g:gtd#debug = a:target
		let l:switch_done = 1
	endif
	return l:switch_done
endfunction

function! gtd#AllFiles()
	return glob(g:gtd#dir.'*.gtd', 0, 1)
endfunction

