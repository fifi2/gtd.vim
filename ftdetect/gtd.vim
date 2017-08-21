" Map .gtd extension with gtd filetype
augroup gtd
	autocmd!
	autocmd BufReadPost,BufNewFile *.gtd set filetype=gtd
augroup END
