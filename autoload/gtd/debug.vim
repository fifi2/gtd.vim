
function! gtd#debug#Message(message)
	if g:gtd#debug
		echo a:message
	endif
endfunction

function! gtd#debug#Bench(bang, formula)
	let l:debug_switch = gtd#debug#Switch(0)
	try
		let [ l:i, l:bench_sum, l:bench_nb ] = [ 0, 0.0, 100 ]
		while l:i < l:bench_nb
			let l:start_time = reltime()
			silent call gtd#search#Start('', a:bang, a:formula, 'new')
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
		call gtd#debug#Switch(1)
	endif
endfunction

function! gtd#debug#Switch(target)
	let l:switch_done = 0
	if g:gtd#debug != a:target
		let g:gtd#debug = a:target
		let l:switch_done = 1
	endif
	return l:switch_done
endfunction

