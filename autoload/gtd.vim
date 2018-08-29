" Vim auto-load file

function! gtd#Init()

	try
		if !exists('g:gtd#dir')
			let g:gtd#dir = '~/notes'
		else
			let g:gtd#dir = expand(g:gtd#dir)
			if !isdirectory(g:gtd#dir)
				\ && (!exists('*mkdir') || !mkdir(g:gtd#dir, 'p'))
				throw "Gtd directory has not been set properly (g:gtd#dir)"
			endif
		endif
		let g:gtd#dir = fnamemodify(g:gtd#dir, ':p')

		if !exists('g:gtd#folder_command')
			if has('win32')
				let g:gtd#folder_command = 'explorer.exe'
			else
				let g:gtd#folder_command = 'xdg-open'
			endif
		endif

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

		if !exists('g:gtd#results_history')
			\ || type(g:gtd#results_history) != v:t_number
			let g:gtd#results_history = 10
		endif

		if !exists('g:gtd#map_edit') || empty(g:gtd#map_edit)
			let g:gtd#map_edit = '<Enter>'
		endif

		if !exists('g:gtd#map_refresh') || empty(g:gtd#map_refresh)
			let g:gtd#map_refresh = '<F5>'
		endif

		if !exists('g:gtd#map_browse_older') || empty(g:gtd#map_browse_older)
			let g:gtd#map_browse_older = '<C-Left>'
		endif

		if !exists('g:gtd#map_browse_newer') || empty(g:gtd#map_browse_newer)
			let g:gtd#map_browse_newer = '<C-Right>'
		endif

		return 1

	catch /.*/
		echomsg v:exception
		return 0
	endtry

endfunction

