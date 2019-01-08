
function! gtd#search#Start(mods, bang, formula, type)

	if g:gtd#debug
		let l:start_time = reltime()
	endif

	try

		let l:searches = []
		let s:gtd_highlighted = []
		let l:highlight = 0

		if a:type == 'new'
			let l:what = s:GtdSearchContextAdd(
				\ a:bang,
				\ gtd#formula#Parser(a:formula)
				\ )
			let l:searches += [ {
				\ 'display': gtd#formula#ToString(l:what),
				\ 'keep': [],
				\ 'what': l:what,
				\ 'where': gtd#note#GetAll('short')
				\ } ]
		elseif a:type == 'review'
			if empty(g:gtd#review)
				throw "Gtd review has not been set (g:gtd#review)"
			else
				for l:r in g:gtd#review
					let l:what = s:GtdSearchContextAdd(
						\ a:bang,
						\ gtd#formula#Parser(l:r)
						\ )
					let l:searches += [ {
						\ 'display': gtd#formula#ToString(l:what),
						\ 'keep': [],
						\ 'what': l:what,
						\ 'where': gtd#note#GetAll('short')
						\ } ]
				endfor
			endif
		elseif a:type == 'refresh'
			let l:previous = gtd#results#Get()
			if l:previous['id'] == -1
				throw 'No previous result'
			else
				for l:p in l:previous['gtd']
					let l:what = s:GtdSearchContextAdd(
						\ a:bang,
						\ gtd#formula#Parser(l:p['formula'])
						\ )
					let l:searches += [ {
						\ 'display': gtd#formula#ToString(l:what),
						\ 'keep': [],
						\ 'what': l:what,
						\ 'where': gtd#note#GetAll('short')
						\ } ]
				endfor
			endif
		elseif a:type == 'add'
			let l:previous = gtd#results#Get()
			if l:previous['id'] == -1
				throw 'No previous result'
			else
				let l:what = s:GtdSearchContextAdd(
					\ a:bang,
					\ gtd#formula#Parser(a:formula)
					\ )
				for l:p in l:previous['gtd']
					let l:searches += [ {
						\ 'display': gtd#formula#ToString(
							\ [ '+', gtd#formula#Parser(l:p['formula']), l:what ]
							\ ),
						\ 'keep': l:p['results'],
						\ 'what': l:what,
						\ 'where': gtd#note#GetAll('short')
						\ } ]
				endfor
			endif
		elseif a:type == 'filter'
			let l:previous = gtd#results#Get()
			if l:previous['id'] == -1
				throw 'No previous result'
			else
				let l:what = s:GtdSearchContextAdd(
					\ a:bang,
					\ gtd#formula#Parser(a:formula)
					\ )
				for l:p in l:previous['gtd']
					let l:searches += [ {
						\ 'display': gtd#formula#ToString(
							\ [ ' ', gtd#formula#Parser(l:p['formula']), l:what ]
							\ ),
						\ 'keep': [],
						\ 'what': l:what,
						\ 'where': l:p['results']
						\ } ]
				endfor
			endif
		endif

		if a:type != 'refresh'
			let l:result_id = gtd#results#Create(-1)
		else
			let l:result_id = gtd#results#Create(l:previous['id'])
		endif

		if g:gtd#cache
			call gtd#cache#Load(1)
		endif

		for l:s in l:searches

			call gtd#debug#Message(l:s['what'])

			" No need to do each search if type is 'add' there will be no
			" change...
			if a:type != 'add' || !exists('l:gtd_results')
				let l:gtd_results = s:GtdSearchHandler(
					\ l:s['what'],
					\ l:s['where']
					\ )
			endif
			let l:gtd_results = reverse(
				\ uniq(
					\ sort(l:gtd_results + l:s['keep'])
					\ )
				\ )

			if l:highlight == 0 && !empty(l:gtd_results)
				let l:highlight = 1
			endif

			" Results loading
			call gtd#results#Set(l:result_id, l:s['display'], l:gtd_results)
		endfor

		" Highlighting
		if l:highlight && !empty(s:gtd_highlighted)
			let @/ = '\('.join(uniq(sort(s:gtd_highlighted)), '\)\|\(').'\)'
		endif

		call gtd#results#Display(a:mods, l:result_id)

		if g:gtd#debug
			echomsg "Gtd elapsed time:" reltimestr(reltime(l:start_time))
		endif

	catch /.*/
		echomsg v:exception
	endtry

endfunction

function! gtd#search#Context(context)
	if a:context =~ '@\S\+'
		let g:gtd#default_context = a:context[1:]
		echo "Gtd context is now:" a:context
	else
		echo "Gtd context doesn't seem legit"
	endif
endfunction

function! s:GtdSearchContextAdd(bang, formula)
	if a:bang != '!' && !empty(g:gtd#default_context)
		\ && gtd#formula#AtomUseful(a:formula, ' ', '@'.g:gtd#default_context)
		return [ ' ', a:formula, '@'.g:gtd#default_context ]
	else
		return a:formula
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
	let [ l:where, l:arg ] = [ a:where, a:arg ]

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

	" Can we use cache file?
	let l:cache_decision = g:gtd#cache && gtd#cache#IsPossible(l:arg_type)

	" Search
	let l:search_results = []
	for l:gtd_name in l:where
		let l:gtd_file = g:gtd#dir.l:gtd_name.'.gtd'

		if l:cache_decision
			if index([ '@', '!' ], l:arg_type) >= 0
				let l:arg_reg = '^'.l:arg.'$'
			elseif l:arg_type == '#'
				let l:arg_reg = '^'.l:arg.'\(:.\+\)\=$'
			elseif l:arg_type == '[*]'
				let l:arg_reg = '^\[\*\]$'
			endif

			if gtd#cache#Query(
				\ l:gtd_file,
				\ l:gtd_name, l:arg_reg,
				\ getftime(l:gtd_file)
				\ )
				let l:search_results += [ l:gtd_name ]
			endif
		else

			" Preparing search...
			if index([ '@', '!' ], l:arg_type) >= 0
				let l:arg_reg = '^'.l:arg.'$'
			elseif l:arg_type == '#'
				let l:arg_reg = '^'.l:arg.'\(:.\+\)\=$'
			elseif l:arg_type == '='
				let l:arg_reg = '^=.*'.strpart(l:arg, 1)
			elseif l:arg_type == '/'
				let l:arg_reg = strpart(l:arg, 1)
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

			if index([ 'Y', 'M', 'D' ], l:arg_type) >= 0
				\ && l:gtd_name =~ l:arg_reg
				let l:search_results += [ l:gtd_name ]
				continue
			endif

			if l:arg_type == '/'
				let l:file_read = gtd#note#Read(l:gtd_file, 0)
			elseif l:arg_type == '=' || l:arg_type == '[*]'
				let l:file_read = gtd#note#Read(l:gtd_file, 1)
			else
				let l:file_read = gtd#note#Read(
					\ l:gtd_file,
					\ g:gtd#tag_lines_count
					\ )
			endif

			for l:l in l:file_read
				if l:l =~? l:arg_reg
					let l:search_results += [ l:gtd_name ]
					if l:arg_type == '/'
						call s:GtdSearchHighlightedAtomsCollect(l:arg_reg)
					endif
					break
				elseif l:arg_type != '/' && l:l !~ '^[@!#=]'
					break
				endif
			endfor
		endif
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
	let s:gtd_highlighted += [ a:atom ]
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

	if a:cmd_line =~ '^GtdContext'
		let l:prefix_types_to_complete = [ '@' ]
	else
		let l:prefix_types_to_complete = [ '@', '!', '#' ]
	endif

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
		let l:complete_regex = '^['.join(l:prefix_types_to_complete).']'
	elseif index(l:prefix_types_to_complete, l:arg_lead[0]) != -1
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
	if g:gtd#cache
		call gtd#cache#Load(1)
		for l:f in gtd#note#GetAll('short')
			for l:t in gtd#cache#TagsGet(l:f)
				if l:t =~ a:pattern
					let l:matches += [ a:prefix.l:t ]
				endif
			endfor
		endfor
	else
		for l:f in gtd#note#GetAll('full')
			for l:l in gtd#note#Read(l:f, g:gtd#tag_lines_count)
				if l:l =~ '^$'
					break
				elseif l:l =~ a:pattern
					let l:matches += [ a:prefix.l:l ]
				endif
			endfor
		endfor
	endif
	return uniq(sort(l:matches))
endfunction

