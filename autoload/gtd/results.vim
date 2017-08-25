
function! gtd#results#Get()
	let l:previous_results = []
	for l:qf_item in getloclist(0)
		let l:previous_results += [ bufname(l:qf_item['bufnr']) ]
	endfor
	return map(
		\ l:previous_results,
		\ function('gtd#note#Key')
		\ )
endfunction

function! gtd#results#Args()
	let l:args = ''
	let l:qf_title = s:GtdResultsTitleGet()
	if s:GtdResultsTest(l:qf_title)
		let l:args = substitute(l:qf_title, '^:Gtd ', '', '')
	endif
	return l:args
endfunction

function! gtd#results#Set(formula, results, previous_args, type)
	if a:type == 'refresh'
		let l:qf_action = 'r'
	else
		let l:qf_action = ' '
	endif
	call setloclist(0, s:GtdResultsListCreate(a:results), l:qf_action)
	call s:GtdResultsTitleSet(a:formula, a:previous_args, a:type)
endfunction

function! s:GtdResultsTest(qf_title)
	return a:qf_title =~ '^:Gtd '
endfunction

function! s:GtdResultsTitleGet()
	return get(getloclist(0, {'title': 1}), 'title', '')
endfunction

function! s:GtdResultsTitleSet(formula, previous_args, type)
	if a:type == 'add'
		let l:qf_title = '('.a:previous_args.') + ('.a:formula.')'
	elseif a:type == 'filter'
		let l:qf_title = '('.a:previous_args.') ('.a:formula.')'
	else
		let l:qf_title = a:formula
	endif

	call setloclist(
		\ 0, [], 'a',
		\ {'title': ':Gtd '.gtd#formula#Simplify(l:qf_title)}
		\ )
endfunction

function! s:GtdResultsCreateResult(filename)
	let l:filename_path = g:gtd#dir.a:filename.'.gtd'
	let l:title = gtd#search#TitleGet(l:filename_path)
	return {
		\ 'filename': fnamemodify(l:filename_path, ':.'),
		\ 'text': l:title[0],
		\ 'type': l:title[1],
		\ 'lnum': 1
		\ }
endfunction

function! s:GtdResultsListCreate(results)
	let l:qf = []
	for l:gtd_result in uniq(sort(a:results))
		let l:qf += [ s:GtdResultsCreateResult(l:gtd_result) ]
	endfor
	return l:qf
endfunction

