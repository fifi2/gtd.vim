
function! gtd#quickfix#ResultsGet()
	let l:previous_results = []
	for l:qf_item in getloclist(0)
		call add(l:previous_results, buffer_name(l:qf_item['bufnr']))
	endfor
	return l:previous_results
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
	let l:qf_title = gtd#formula#Simplify(l:qf_title)
	call setloclist(0, [], 'a', {'title': ':Gtd '.l:qf_title})
endfunction

function! s:GtdQfCreateResult(filename)
	let l:title = gtd#search#TitleGet(a:filename)
	return {
		\ 'filename': fnamemodify(a:filename, ':.'),
		\ 'text': l:title[0],
		\ 'type': l:title[1],
		\ 'lnum': 1
		\ }
endfunction

function! s:GtdQfListCreate(results)
	let l:qf = []
	let l:gtd_results = uniq(sort(a:results))
	for l:gtd_result in l:gtd_results
		call add(l:qf, s:GtdQfCreateResult(l:gtd_result))
	endfor
	return l:qf
endfunction

