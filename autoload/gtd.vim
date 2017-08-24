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

function! gtd#Bench(bang, formula)
	let l:debug_switch = gtd#DebugSwitch(0)
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
		call gtd#DebugSwitch(1)
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

function! gtd#DebugSwitch(target)
	let l:switch_done = 0
	if g:gtd#debug != a:target
		let g:gtd#debug = a:target
		let l:switch_done = 1
	endif
	return l:switch_done
endfunction

