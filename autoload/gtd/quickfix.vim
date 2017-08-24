
function! gtd#quickfix#ResultsGet()
	let l:previous_results = []
	for l:qf_item in getloclist(0)
		let l:previous_results += [ bufname(l:qf_item['bufnr']) ]
	endfor
	return map(
		\ l:previous_results,
		\ function('gtd#note#Key')
		\ )
endfunction

function! gtd#quickfix#ArgsGet()
	let l:args = ''
	let l:qf_title = s:GtdQfTitleGet()
	if s:GtdQfTest(l:qf_title)
		let l:args = substitute(l:qf_title, '^:Gtd ', '', '')
	endif
	return l:args
endfunction

function! gtd#quickfix#ListSet(formula, results, previous_args, type)
	let l:qf_list = s:GtdQfListCreate(a:results)
	if a:type == 'refresh'
		let l:qf_action = 'r'
	else
		let l:qf_action = ' '
	endif
	call setloclist(0, l:qf_list, l:qf_action)
	call s:GtdQfTitleSet(a:formula, a:previous_args, a:type)
endfunction

function! s:GtdQfTest(qf_title)
	return a:qf_title =~ '^:Gtd '
endfunction

function! s:GtdQfTitleGet()
	return get(getloclist(0, {'title': 1}), 'title', '')
endfunction

function! s:GtdQfTitleSet(formula, previous_args, type)
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

function! s:GtdQfCreateResult(filename)
	let l:filename_path = g:gtd#dir.a:filename.'.gtd'
	let l:title = gtd#search#TitleGet(l:filename_path)
	return {
		\ 'filename': fnamemodify(l:filename_path, ':.'),
		\ 'text': l:title[0],
		\ 'type': l:title[1],
		\ 'lnum': 1
		\ }
endfunction

function! s:GtdQfListCreate(results)
	let l:qf = []
	for l:gtd_result in uniq(sort(a:results))
		let l:qf += [ s:GtdQfCreateResult(l:gtd_result) ]
	endfor
	return l:qf
endfunction

