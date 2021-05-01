" Map .gtd extension with gtd filetype
augroup gtd
	autocmd!
	autocmd BufReadPost,BufNewFile *.gtd set filetype=gtd
	autocmd BufWritePost *.gtd call gtd#cache#One(expand("%"))
augroup END

