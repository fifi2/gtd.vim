" Vim auto-load file

function! gtd#Init()

	try
		if !exists('g:gtd#dir')
			let g:gtd#dir = '.'
		else
			let g:gtd#dir = expand(g:gtd#dir)
			if !isdirectory(g:gtd#dir)
				\ && (!exists('*mkdir') || !mkdir(g:gtd#dir, 'p'))
				throw "Gtd directory has not been set properly (g:gtd#dir)"
			endif
		endif
		let g:gtd#dir = fnamemodify(g:gtd#dir, ':p')

		if !exists('g:gtd#debug') || g:gtd#debug != 1
			let g:gtd#debug = 0
		endif

		if !exists('g:gtd#cache') || g:gtd#cache != 1
			let g:gtd#cache = 0
		else
			if !exists('g:gtd#cache_file')
				let g:gtd#cache_file = g:gtd#dir.'cache'
			else
				let g:gtd#cache_file = expand(g:gtd#cache_file)
			endif
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
		let l:gtd_note_dir = gtd#AttachedFilesDirGet()

		" Creation of the directory if needed
		if !gtd#AttachedFilesDirTest(l:gtd_note_dir)
			\ && (!exists('*mkdir') || !mkdir(l:gtd_note_dir))
			throw "Gtd note directory ".l:gtd_note_dir." can't be created"
		endif

		" Browsing directory
		if has('win32')
			execute 'silent !explorer.exe' l:gtd_note_dir
		else
			execute 'silent !xdg-open' l:gtd_note_dir
		endif

		" We wait the user to continue...
		call input("Hit enter to continue")

		if gtd#AttachedFilesDirTest(l:gtd_note_dir)
			if empty(glob(l:gtd_note_dir.'/**'))
				if delete(l:gtd_note_dir, 'd') == 0
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
	let l:gtd_note_dir = gtd#AttachedFilesDirGet()

	if !gtd#AttachedFilesDirTest(l:gtd_note_dir)
		echomsg "Gtd note directory ".l:gtd_note_dir." doesn't exist"
	else
		execute "Vexplore" l:gtd_note_dir
	endif
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
				let open += [ tabpagenr() ]
			endif
			silent call gtd#search#Start('!', g, 'new')
			" Focus is now to the location list
			setlocal nowinfixheight nowinfixwidth
			if l:split
				let open += [ bufnr('%') ]
			endif
			execute 'silent bw' l:bufnr
		endfor
		execute 'normal!' open[0].'gt'

		if l:debug_switch
			call s:GtdDebugSwitch(1)
		endif
	endif

endfunction

function! gtd#Bench(bang, formula)
	let l:debug_switch = s:GtdDebugSwitch(0)
	try
		let [ l:i, l:bench_sum, l:bench_nb ] = [ 0, 0.0, 100 ]
		while l:i < l:bench_nb
			let l:start_time = reltime()
			silent call gtd#search#Start(a:bang, a:formula, 'new')
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

function! s:AttachedFilesTagTest()
	return getline(1) =~ '^=.* \[\*\]$'
endfunction

function! gtd#AttachedFilesDirGet()
	return expand('%:p:r')
endfunction

function! gtd#AttachedFilesDirTest(dir)
	return isdirectory(a:dir)
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

