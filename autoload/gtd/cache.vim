
let s:cache_atoms = {
	\ '@': '^@.*$',
	\ '!': '^!.*$',
	\ '#': '^#.*$',
	\ '[*]': '^=.* \zs\[\*\]$'
	\ }

function! gtd#cache#Load(silent)
	if !exists('s:cache')
		if filereadable(g:gtd#cache_file)
			let s:cache = json_decode(
				\ join(readfile(g:gtd#cache_file), '')
				\ )
		else
			let [ s:cache, l:curr, l:ratio ] = [ {}, 1, 0.0 ]
			let l:time = localtime()
			let l:all_files = gtd#note#GetAll('full')
			let l:nb_files = len(l:all_files)
			for l:f in l:all_files
				if !a:silent
					let l:ratio_before = l:ratio
					let l:ratio = float2nr(
						\ eval(l:curr.'/'.l:nb_files.'.0*100')
						\ )
					if l:ratio != l:ratio_before
						redraw | echo "Gtd cache:" l:ratio.'%'
					endif
					let l:curr += 1
				endif
				let l:l_tags = s:GtdCacheFileCreate(l:f)
				let s:cache[gtd#note#Key('N/A', l:f)] = {
					\ 'time': l:time,
					\ 'tags': l:l_tags
					\ }
			endfor
			if !empty(s:cache)
				call writefile(
					\ [ json_encode(s:cache) ],
					\ g:gtd#cache_file
					\ )
			endif
		endif
	endif
endfunction

function! gtd#cache#Query(file, key, tag, time)
	" Update of the cache may be needed.
	if get(get(s:cache, a:key, {}), 'time', 0) < a:time
		let s:cache[a:key] = {
			\ 'time': localtime(),
			\ 'tags': s:GtdCacheFileCreate(a:file)
			\}
	endif

	" Then, the cache query is possible.
	return match(
		\ get(get(s:cache, a:key, {}), 'tags', []),
		\ a:tag
		\ ) >= 0
endfunction

function! gtd#cache#Refresh()
	unlet! s:cache
	if !empty(glob(g:gtd#cache_file))
		call delete(g:gtd#cache_file)
	endif
	call gtd#cache#Load(0)
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

function! s:GtdCacheFileCreate(file)
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
	return l:file_tags
endfunction

