
let s:results_buffer = 0
let s:results_history = []
let s:results_current = -1

" s:results_history looks like this:
" [
" 	[
" 		{
" 			'title': '#hashtag',
" 			'formula': '#hastag',
" 			'display_list': 1,
" 			'results': [
" 				{
"					'key': '20170414_104443',
"					'list': '!inbox',
"					'attached': 0,
"					'title': 'Example 1'
"				},
" 				{
"					'key': '20170818_100024',
"					'list': '!next',
"					'attached': 1,
"					'title': 'Example 2'
"				},
" 			]
" 		}
" 	],
" 	[
" 		{
" 			'title': 'INBOX',
" 			'formula': '!inbox @work',
" 			'display_list': 0,
" 			'results': [
" 				{
"					'key': '20161205_153911',
"					'list': '!inbox',
"					'attached': 0,
"					'title': 'Example 3'
"				},
" 			]
" 		},
" 		{
" 			'title': 'WAITING',
" 			'formula': '!waiting @work',
" 			'display_list': 0,
" 			'results': [
" 				{
"					'key': '20161115_150000',
"					'list': '!waiting',
"					'attached': 0,
"					'title': 'Example 4'
"				},
" 			]
" 		},
" 		{
" 			'title': 'SOMEDAY',
" 			'formula': '!someday @work',
" 			'display_list': 0,
" 			'results': [
" 				{
"					'key': '20161207_112100',
"					'list': '!someday',
"					'attached': 0,
"					'title': 'Example 5'
"				},
" 				{
"					'key': '20161216_162500',
"					'list': '!someday',
"					'attached': 0,
"					'title': 'Example 6'
"				},
" 			]
" 		}
" 	]
" ]

function! gtd#results#Create(recycling)
	if a:recycling < 0
		let l:idx_end_delete = len(s:results_history) - g:gtd#results_history
		if g:gtd#results_history != 0 && l:idx_end_delete >= 0
			call remove(s:results_history, 0, l:idx_end_delete)
		endif
		call add(s:results_history, [])
		return len(s:results_history)-1
	else
		let s:results_history[a:recycling] = []
		return a:recycling
	endif
endfunction

function! gtd#results#Set(history_id, title, formula, results)
	let l:results = []
	for l:r in a:results
		let l:list = ''
		let l:r_data = gtd#note#Read(g:gtd#dir.l:r.'.gtd', g:gtd#tag_lines_count)
		for l:l in l:r_data
			if match(l:l, '^!\S\+') != -1
				let l:list = l:l
				break
			endif
			if match(l:l, '^\s*$') != -1
				break
			endif
		endfor
		let l:results += [
				\ {
				\ 'key': l:r,
				\ 'list': l:list,
				\ 'attached': match(l:r_data[0], ' \[\*\]$') == -1 ? 0 : 1,
				\ 'title': substitute(
					\ l:r_data[0],
					\ '^=\(.\{-}\)\( \[\*\]\)\?$',
					\ '\1',
					\ ''
					\ )
				\ }
			\ ]
	endfor

	let s:results_history[a:history_id] += [ {
		\ 'title': a:title,
		\ 'formula': a:formula,
		\ 'display_list': s:GtdResultsDisplayList(a:formula),
		\ 'results': l:results
		\ } ]

endfunction

function! gtd#results#Get()
	let l:requests = []
	if s:results_current != -1
		for l:q in get(s:results_history, s:results_current, [])
			let l:results = []
			for l:r in l:q['results']
				let l:results += [ l:r['key'] ]
			endfor
			let l:requests += [
					\ {
						\ 'title': l:q['title'],
						\ 'formula': l:q['formula'],
						\ 'results': l:results
					\ }
				\ ]
		endfor
	endif
	return {
		\ 'id': s:results_current,
		\ 'gtd': l:requests
		\ }
endfunction

function! gtd#results#Browse(move)
	if type(a:move) == v:t_number && s:results_current != -1
		let l:len = len(s:results_history)
		let l:idx = eval('(s:results_current+'.a:move.'+l:len)%l:len')

		" We do not autorize looping on the history
		if l:idx >= 0 && l:idx-s:results_current == a:move
			call gtd#results#Display('', l:idx)
		endif
	endif
endfunction

function! gtd#results#CurrentId()
	return s:results_current
endfunction

function! gtd#results#Display(mods, gtd_id)
	try
		let l:content = []

		for l:gtd in get(s:results_history, a:gtd_id, [])
			let l:title = l:gtd['title']
			let l:nb_notes = len(l:gtd['results'])
			if l:nb_notes <= 1
				let l:title .= ' ['.l:nb_notes.' note]'
			else
				let l:title .= ' ['.l:nb_notes.' notes]'
			endif
			let l:content += [ l:title ]
			if !empty(l:gtd['results'])
				for l:r in l:gtd['results']
					let l:attached = l:r['attached'] ? ' [*]' : ''
					if l:gtd['display_list']
						let l:content += [
							\ l:r['key'].' '.l:r['list'].' '.l:r['title'].l:attached
							\ ]
					else
						let l:content += [
							\ l:r['key'].' '.l:r['title'].l:attached
							\ ]
					endif
				endfor
			endif
			let l:content += [ '' ]
		endfor

		let s:results_buffer = s:GtdResultsOpen(a:mods)
		let s:results_current = a:gtd_id
		call append(0, l:content)
		call s:GtdResultsFreeze()
	catch /.*/
		echomsg v:exception
	endtry
endfunction

function! gtd#results#Edit(line)
	let l:key = matchstr(getline(a:line), '^\zs\d\{8}_\d\{6}')
	if !empty(l:key)
		execute "silent split" g:gtd#dir.l:key.'.gtd'
	else
		call gtd#search#Start('', '', 'refresh')
	endif
endfunction

function! s:GtdResultsOpen(mods)
	if s:results_buffer != 0 && bufloaded(s:results_buffer)
		let l:w = bufwinnr(s:results_buffer)
		if l:w != -1
			execute l:w 'wincmd w'
			call s:GtdResultsFree()
			return s:results_buffer
		else
			execute 'silent! bwipeout' s:results_buffer
		endif
	endif
	let l:mods = split(a:mods)
	if empty(a:mods) && &hidden
		let l:action = 'enew'
	else
		if index(l:mods, 'aboveleft') == -1
			let l:mods += [ 'botright' ]
		endif
		let l:action = 'new'
	endif
	execute join(l:mods) l:action ' | set ft=gtd-results'
	call s:GtdResultsFree()
	return bufnr('%')
endfunction

function! gtd#results#Close()
	let s:results_buffer = 0
endfunction

function! gtd#results#Remove(key)
	let l:results_new = []
	for l:h in s:results_history
		let l:history = []
		for l:s in l:h
			let l:results = []
			for l:r in get(l:s, 'results', [])
				if l:r['key'] != a:key
					let l:results += [ l:r ]
				endif
			endfor
			let l:history += [ {
				\ 'title': l:s['title'],
				\ 'formula': l:s['formula'],
				\ 'results': l:results
				\ } ]
		endfor
		let l:results_new += [ l:history ]
	endfor
	let s:results_history = l:results_new

	if s:results_buffer && s:results_current != -1
		call gtd#results#Display('', s:results_current)
	endif
endfunction

function! s:GtdResultsFree()
	execute "setlocal modifiable | silent! 1,$d"
endfunction

function! s:GtdResultsFreeze()
	execute "silent! keeppatterns $-1,$g/^$/d | 1"
	execute "setlocal nomodifiable"
endfunction

function! gtd#results#Do(cmd)
	let l:targets = []
	for l:search in get(gtd#results#Get(), 'gtd')
		let l:targets += get(l:search, 'results')
	endfor
	execute '%argdelete'
	for l:target in uniq(sort(l:targets))
		execute 'argadd '.g:gtd#dir.l:target.'.gtd'
	endfor
	execute 'argdo '.a:cmd
endfunction

function! s:GtdResultsDisplayList(formula)
	if type(a:formula) == v:t_string
		return match(a:formula, '^!\S\+') != -1
			\ ? 0 : 1
	else
		return get(a:formula, 0) == ' '
			\ && (match(get(a:formula, 1, ''), '^!\S\+') != -1
				\ || match(get(a:formula, 2, ''), '^!\S\+') != -1)
			\ ? 0 : 1
	endif
endfunction

