
let s:cache_atoms = {
	\ '@': '^@.*$',
	\ '!': '^!.*$',
	\ '#': '^#.*$',
	\ '[*]': '^=.* \zs\[\*\]$'
	\ }

function! gtd#cache#Load()
	if !exists('s:cache')
		let [ s:cache, l:curr, l:ratio ] = [ {}, 1, 0.0 ]
		let l:all_files = gtd#note#GetAll('full')
		let l:nb_files = len(l:all_files)
		for l:f in l:all_files
			let l:ratio_before = l:ratio
			let l:ratio = float2nr(
				\ eval(l:curr.'/'.l:nb_files.'.0*100')
				\ )
			if l:ratio != l:ratio_before
				redraw | echo "Gtd cache:" l:ratio.'%'
			endif
			let l:curr += 1
			call gtd#cache#One(l:f)
		endfor
	endif
endfunction

function! gtd#cache#Query(file, key, tag, time)
	" Update of the cache may be needed.
	if get(get(s:cache, a:key, {}), 'time', 0) < a:time
		call gtd#cache#One(g:gtd#dir.a:key.'.gtd')
	endif

	" Then, the cache query is possible.
	return match(
		\ get(get(s:cache, a:key, {}), 'tags', []),
		\ a:tag
		\ ) >= 0
endfunction

function! gtd#cache#All()
	unlet! s:cache
	call gtd#cache#Load()
endfunction

function! gtd#cache#One(file)
	if g:gtd#cache && exists('s:cache')
		let l:file_tags = []
		for l:l in gtd#note#Read(a:file, g:gtd#tag_lines_count)
			if l:l =~ '^$'
				break
			endif
			for l:k_reg in keys(s:cache_atoms)
				let l:tag = matchstr(l:l, s:cache_atoms[l:k_reg])
				if !empty(l:tag)
					let l:file_tags += [ l:tag ]
					break
				endif
			endfor
		endfor
		let s:cache[gtd#note#Key('N/A', a:file)] = {
			\ 'time': localtime(),
			\ 'tags': l:file_tags
			\ }
	endif
endfunction

function! gtd#cache#IsPossible(atom_type)
	return index(keys(s:cache_atoms), a:atom_type) >= 0
endfunction

function! gtd#cache#Delete(key)
	if exists('s:cache') && exists('s:cache[a:key]')
		unlet! s:cache[a:key]
	endif
endfunction

function! gtd#cache#TagsGet(key)
	return get(get(s:cache, a:key, {}), 'tags', [])
endfunction

