" {{{
" snippet.vim
" a plugin for doing keyword replacement using vim's :read function
" Author : Timothy Aldrich tim@aldrichsystems.com
" License: This file is placed in the public domain.
" last modified : August 19 , 2002
" Comments welcome
" }}}
" TODO: read replacement codes from snippetrc file ?
" TODO: just find snippets directory in 'runtimepath'
" {{{=ChangeLog================================================================
" | 8/19/2002 added license information
" | Thanks to Vikas Agnihotri for all these
" | 8/9/2002 changed the visual selection from character wise 'v' to 
" |          line wise 'V'
" | 8/9/2002 fixed bug that deleted keyword if snippet was not found
" | 8/9/2002 added \<Esc> so that vim recognizes this as start of change for
" |          undo to only remove the snippet
" | 8/8/2002 added reformatting indents after :read'ing
" | 8/7/2002 changed mapping to test if the map exists already, correctly
" | 8/6/2002 added <SID> to all function calls
" | 8/6/2002 added 'global' snippet functionality
" | 8/6/2002 changed case of g: variables
" | 8/6/2002 changed win32 default snippet dir from $HOME to $VIM
" | Thanks to Randall Maier for this
" | 8/1/2002 replacement strings were "replaced" in initial upload
" ==========================================================================}}}
if exists("loaded_snippets")
    finish
endif
let loaded_snippets = 1
let g:DEBUG_SNIPPET=1

" set the Snippets root if not already defined
if !exists("g:snippet_directory")
        " set the Snippets root in the runtime directory by default
        if has("unix")
                let g:snippet_directory = "$HOME/.vim/snippets"
        endif
        if has("win32")
                let g:snippet_directory = "$VIM/vimfiles/snippets"
        endif

endif

" do not follow includes further than this deep
if !exists("g:snippet_max_depth")
        let g:snippet_max_depth = 10
endif

" prefer the snippet in the global folder over the current syntax folder
if !exists("g:snippet_use_global")
        let g:snippet_use_global = 0
endif


" {{{ disclaimer
" *borrowed* from Benji Fisher's foo.vim
" Usage:  let ma = Mark() ... execute ma
" has the same effect as  normal ma ... normal 'a
" without affecting global marks.
" You can also use Mark(17) to refer to the start of line 17 and Mark(17,34)
" to refer to the 34'th (screen) column of the line 17.  The functions
" Line() and Virtcol() extract the line or (screen) column from a "mark"
" constructed from Mark() and default to line() and virtcol() if they do not
" recognize the pattern.
" Update:  :execute Mark() now restores screen position as well as the cursor.
" }}}
fun! Mark(...) "{{{
  if a:0 == 0
    let mark = line(".") . "G" . virtcol(".") . "|"
    normal! H
    let mark = "normal!" . line(".") . "Gzt" . mark
    execute mark
    return mark
  elseif a:0 == 1
    return "normal!" . a:1 . "G1|"
  else
    return "normal!" . a:1 . "G" . a:2 . "|"
  endif
endfun "}}}

function! <SID>Has_Include(SnippetType) " {{{
"determine if this filetype has includes
"by looking for _include.spt in the directory
        if ( filereadable(expand(<SID>Get_IncludeFile())) )
                " found include file in a:SnippetType
                return 1
        else
                " did not find include file in a:SnippetType
                return 0
        endif
endfunction " }}}

function! <SID>Has_Snippet(keyword) " {{{
"determine if this keyword has a snippet in the current
"filetype by looking for the SNIPPET_DIRECTORY/filetype/keyword.spt file
        if ( filereadable( expand(<SID>Get_SnippetFile(a:keyword))) )
                return 1
        else
                return 0
        endif
endfunction " }}}

function! <SID>Has_GlobalSnippet(keyword) " {{{
        if ( filereadable( expand(<SID>Get_GlobalSnippetFile(a:keyword))) )
                return 1
        else
                return 0
        endif
endfunction " }}}

function! <SID>Insert_File(fileName) " {{{
        " *read* the file into this one 
        silent! exe ":" . s:_keyword_line . "read " . a:fileName
        "move to end of change and mark it because we lose `] when we J
        exe "norm! `]me"
        exe Mark(s:_keyword_line,s:_keyword_pos)
        "move to original position and Join the lines
        exe "norm! J"
        " start visual, select to `e and apply our indenting rules
        exe "norm! V`e="
        call <SID>Do_Replacements()
endfunction " }}}

function! <SID>Do_Replacements() " {{{
        "save the line we want the cursor on
        let s:_currentLine = search("<#cursor#>")
        "save the column we want the cursor to be on
        let s:_cursorPos = match(getline(s:_currentLine),"<#cursor#>")

        let s:_datex     = strftime("%c")
        let s:_file      = expand("%:r")
        let s:_ext       = expand("%:e")
        let s:_cwd       = substitute(getcwd(), "\\", "/", "g")
        let s:_modified  = strftime( "%c",getftime(s:_file) )

        silent! subst /<#cursor#>//
        silent! exe "%s/<#file#>/" . s:_file       ."/g"
        silent! exe "%s!<#datex#>!". s:_datex      ."!g"
        silent! exe "%s!<#mod#>!"  . s:_modified   ."!g"
        silent! exe "%s!<#dir#>!"  . s:_cwd        ."!g"
        silent! exe "%s!<#ext#>!"  . s:_ext        ."!g"

        "move the cursor
        exe Mark(s:_currentLine,s:_cursorPos+1)

endfunction " }}}

function! <SID>Get_IncludeType(lineNumber) " {{{
        exe 'hide :e ' . <SID>Get_IncludeFile()
        let s:_IncType = getline(a:lineNumber)
        echo "lineNumber in include:".a:lineNumber
        exe 'bdelete'
        return s:_IncType
endfunction " }}}

function! <SID>Get_SnippetType() " {{{
        "if there is no filetype in this buffer, use "general"
        if !exists("b:current_syntax")
                let s:_filetype = "general"
        else
                let s:_filetype = b:current_syntax
        endif
        return s:_filetype
endfunction " }}}

function! <SID>Get_IncludeFile() " {{{
        return (g:snippet_directory . "/" . g:SnippetType . "/_include.spt")
endfunction " }}}

function! <SID>Get_SnippetFile(keyword) " {{{
        return (g:snippet_directory . "/" . g:SnippetType . "/" . a:keyword . ".spt")
endfunction " }}}

function! <SID>Get_GlobalSnippetFile(keyword) " {{{
        return (g:snippet_directory . "/global/" . a:keyword . ".spt")
endfunction " }}}

function! <SID>Run_Snippet() " {{{
        "if has snippet
        "insert file
        "elseif has include
        " if get IncludeType(count) = 
        let g:SnippetType    = <SID>Get_SnippetType()
        let g:SnippetKeyword = expand("<cword>")
        "Change the word
        if (g:DEBUG_SNIPPET==1) | echo "the keyword is ". g:SnippetKeyword | endif
        if (<sid>Has_Snippet(g:SnippetKeyword)==0 && <sid>Has_GlobalSnippet(g:SnippetKeyword)==0 && <SID>Has_Include(g:SnippetKeyword)==0)
                echo "None Found"
                return ""
        endif
        exe "norm! \<Esc>bcw"
        let s:_keyword_line = line(".")
        let s:_keyword_pos  =  col(".")
        let s:_hasSnippet    = <SID>Has_Snippet(g:SnippetKeyword)
        let s:_hasGlobalSnippet = 0
        if (g:snippet_use_global == 1 )
                let s:_hasGlobalSnippet = <SID>Has_GlobalSnippet(g:SnippetKeyword)
        endif
        echo "Global " . s:_hasGlobalSnippet
        if (s:_hasGlobalSnippet == 1)
                call <SID>Insert_File(<SID>Get_GlobalSnippetFile(g:SnippetKeyword))
        else
                let s:includeCount = 0
                while ( s:_hasSnippet == 0 )
                        if (g:DEBUG_SNIPPET==1) | echo "the current count is ".s:includeCount | endif
                        if (s:includeCount == g:snippet_max_depth) | break | endif
                        let s:_hasInclude = <SID>Has_Include(g:SnippetType)
                        if (s:_hasInclude == 1)
                            let s:_originalSnippetType = g:SnippetType
                            let s:includeCount = s:includeCount + 1
                            let g:SnippetType = <SID>Get_IncludeType(s:includeCount)
                            echo "g:SnippetType :".g:SnippetType
                        else
                            break
                        endif
                        "let g:SnippetType = s:_originalSnippetType
                        let s:_hasSnippet = <SID>Has_Snippet(g:SnippetKeyword)
                endwhile
                call <SID>Insert_File(<SID>Get_SnippetFile(g:SnippetKeyword))
        endif
        return ""
endfunction " }}}

if !hasmapto('<Plug>Run_Snippet')
        imap <unique> <C-S> <Plug>Run_Snippet
endif
inoremap <silent> <script> <Plug>Run_Snippet <C-R>=<SID>Run_Snippet()<CR>

