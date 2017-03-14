
function! gtd#search#Start(bang, formula, type)

	if g:gtd#debug
		echomsg "Gtd" a:formula
		let l:start_time = reltime()
	endif

	try
		let l:formula = a:formula

		" If we are dealing with a refresh, we might want to check if we
		" succeed to get the previous request.
		if a:type == 'refresh' && empty(l:formula)
			throw "Gtd refresh is not possible."
		endif

		" Do we need previous results?
		if a:type == 'add' || a:type == 'filter'
			let l:previous_results = gtd#quickfix#ResultsGet()
			let l:previous_args = gtd#quickfix#ArgsGet()
		elseif a:type == 'new' || a:type == 'refresh'
			let l:previous_results = []
			let l:previous_args = ''
		else
			throw "Gtd type forbidden ".a:type
		endif

		" Where are we looking for results?
		if a:type == 'new' || a:type == 'add' || a:type == 'refresh'
			let l:where = gtd#AllFiles('short')
		elseif a:type == 'filter'
			let l:where = l:previous_results
		endif

		" Are we going to keep some previous results?
		if a:type == 'new' || a:type == 'filter' || a:type == 'refresh'
			let l:results_to_keep = []
		elseif a:type == 'add'
			let l:results_to_keep = l:previous_results
		endif

		let s:gtd_highlighted = []

		if a:bang != '!' && !empty(g:gtd#default_context)
			let l:formula = '('.l:formula.') @'.g:gtd#default_context
		endif
		let l:search_actions = gtd#formula#Parser(
			\ gtd#formula#ListConvert(
				\ gtd#formula#OperatorPrecedenceHelper(l:formula)
				\ )
			\ )
		call gtd#Debug(l:search_actions)

		let l:gtd_results = l:results_to_keep
			\ + s:GtdSearchHandler(l:search_actions, l:where)


		" Highlighting
		if !empty(s:gtd_highlighted) && !empty(l:gtd_results)
			let @/ = '\('.join(s:gtd_highlighted, '\)\|\(').'\)'
		endif

		" Quickfix loading
		call gtd#quickfix#ListSet(
			\ l:formula,
			\ l:gtd_results,
			\ l:previous_args,
			\ a:type
			\ )

		if !empty(l:gtd_results)
			execute 'lwindow'
		else
			redraw | echomsg 'No results for' l:formula
		endif

	catch /.*/
		echomsg v:exception
	endtry

	if g:gtd#debug
		echomsg "Gtd elapsed time:" reltimestr(reltime(l:start_time))
	endif

endfunction

function! s:GtdSearchHandler(actions, where)

	if type(a:actions) == v:t_string
		return s:GtdSearchAtom(a:actions, a:where)
	else
		let l:operator = get(a:actions, 0)
		if l:operator == '+'
			return s:GtdSearchHandler(get(a:actions, 1), a:where)
				\ + s:GtdSearchHandler(get(a:actions, 2), a:where)
		elseif l:operator == ' '
			return s:GtdSearchHandler(
				\ get(a:actions, 2),
				\ s:GtdSearchHandler(
					\ get(a:actions, 1),
					\ a:where
					\ )
				\ )
		endif
	endif

endfunction

function! s:GtdSearchAtom(arg, where)

	" If there is no destination, there is no need to search for results
	if empty(a:where)
		return []
	endif

	" Search params
	let l:where = a:where
	let l:arg = a:arg

	" What is the type of the argument?
	" arg can be an attached files tag [*]
	" arg can be a negation if prefixed with -
	" arg can be a special tag if prefixed with @, !, = or #
	" arg can be a content search one if preceeded by /
	" arg can be a datetime filter Y, M, D

	" Negative arg?
	let l:arg_neg = 0
	if strpart(l:arg, 0, 1) == '-'
		let l:arg_neg = 1
		let l:arg = strpart(l:arg, 1)
	endif

	" Arg type?
	if l:arg == '[*]'
		let l:arg_type = l:arg
	else
		let l:arg_type = strpart(l:arg, 0, 1)
	endif

	" Preparing search...
	if index([ '@', '!', '#' ], l:arg_type) >= 0
		let l:arg_reg = '^'.l:arg.'$'
	elseif l:arg_type == '='
		let l:arg_reg = '^=.*'.strpart(l:arg, 1)
	elseif l:arg_type == '/'
		let l:arg_reg = strpart(l:arg, 1)
		call s:GtdSearchHighlightedAtomsCollect(l:arg_reg)
	elseif l:arg_type == '[*]'
		let l:arg_reg = '^=.* \[\*\]$'
	elseif index([ 'Y', 'M', 'D' ], l:arg_type) >= 0
		let l:arg_val = strpart(l:arg, 1)
		if l:arg_type == 'Y'
			let l:arg_reg = '^'.l:arg_val.'\d\{4}_\d\{6}$'
		elseif l:arg_type == 'M'
			let l:arg_reg = '^'.'\d\{4}'.l:arg_val.'\d\{2}_\d\{6}$'
		elseif l:arg_type == 'D'
			let l:arg_reg = '^'.'\d\{6}'.l:arg_val.'_\d\{6}$'
		endif
	else
		throw "Gtd arg type not possible ".l:arg
	endif

	" Search
	let l:search_results = []
	for l:gtd_name in l:where
		if index([ 'Y', 'M', 'D' ], l:arg_type) >= 0
			\ && l:gtd_name =~ l:arg_reg
			call add(l:search_results, l:gtd_name)
			continue
		endif
		let l:gtd_file = g:gtd#dir.l:gtd_name.'.gtd'
		if l:arg_type == '/' || g:gtd#tag_lines_count == 0
			let l:file_read = readfile(l:gtd_file)
		elseif l:arg_type == '=' || l:arg_type == '[*]'
			let l:file_read = readfile(l:gtd_file, '', 1)
		else
			let l:file_read = readfile(l:gtd_file, '', g:gtd#tag_lines_count)
		endif
		for l:l in l:file_read
			if l:l =~? l:arg_reg
				call add(l:search_results, l:gtd_name)
				break
			elseif l:arg_type != '/' && l:l !~ '^[@!#=]'
				break
			endif
		endfor
	endfor

	if l:arg_neg
		" Remove the files from the ones we had at the begining
		for l:gtd_res in l:search_results
			let l:idx = index(l:where, l:gtd_res)
			if l:idx >= 0
				call remove(l:where, l:idx)
			endif
		endfor
	else
		let l:where = l:search_results
	endif

	return l:where

endfunction

function! s:GtdSearchHighlightedAtomsCollect(atom)
	let s:gtd_highlighted = add(s:gtd_highlighted, a:atom)
endfunction

function! gtd#search#TitleGet(filename)
	let l:title_line = '=NO TITLE'
	let l:title_type = 'E'
	let l:title_line = readfile(a:filename, '', 1)[0]
	if l:title_line =~ '^='
		let l:title_type = ''
		if l:title_line =~ ' \[\*\]$'
			let l:title_type = 'I'
		endif
	endif
	return [ l:title_line, l:title_type ]
endfunction

function! gtd#search#InsertTagComplete(findstart, base)
	if a:findstart
		if getline('.') =~ '^[@!#]\s*'
			return 0
		else
			return -3
		endif
	else
		if empty(a:base)
			let l:complete_regex = '^[@!#]'
		else
			let l:complete_regex = '^'.a:base
		endif
		return s:GtdSearchTag(l:complete_regex, '')
	endif
endfunction

function! gtd#search#CommandTagComplete(arg_lead, cmd_line, cursor_pos)

	let l:arg_lead = a:arg_lead

	" Is there some parenthesis in front of arg_lead?
	let l:parenthesis = 0
	while !empty(l:arg_lead) && l:arg_lead[0] == '('
		let l:parenthesis += 1
		let l:arg_lead = strpart(l:arg_lead, 1)
	endwhile

	" Is it a negative atom?
	if !empty(l:arg_lead) && l:arg_lead[0] == '-'
		let l:arg_neg = '-'
		let l:arg_lead = l:arg_lead[1:]
	else
		let l:arg_neg = ''
	endif

	" Is there something remaining?
	if empty(l:arg_lead)
		let l:complete_regex = '^[@!#]'
	elseif index(['@', '!', '#'], l:arg_lead[0]) != -1
		let l:complete_regex = '^'.l:arg_lead
	endif

	if exists('l:complete_regex')
		return s:GtdSearchTag(
			\ l:complete_regex,
			\ repeat('(', l:parenthesis).l:arg_neg
			\ )
	else
		return []
	endif

endfunction

function! s:GtdSearchTag(pattern, prefix)
	let l:matches = []
	for l:f in gtd#AllFiles('full')
		if g:gtd#tag_lines_count == 0
			let l:fr = readfile(l:f)
		else
			let l:fr = readfile(l:f, '', g:gtd#tag_lines_count)
		endif
		for l:l in l:fr
			if l:l =~ '^$'
				break
			elseif l:l =~ a:pattern
				call add(l:matches, a:prefix.l:l)
			endif
		endfor
	endfor
	return uniq(sort(l:matches))
endfunction

