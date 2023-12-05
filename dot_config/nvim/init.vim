se fdc=1
se vop=folds
se ts=4
se sw=4
se nu
se winbl=20
se pb=20
se cul
se cuc
se sb
se hid
se ls=3
se sms
se so=3
se guifont=HackGenNerd_Console:h13
lua << EOF
	_G.get_skkeleton_modestring = function() return "󱌯" end
	function _G.get_warn_count()
		local warns = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
		return #warns
	end
	function _G.get_error_count()
		local errors = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
		return #errors
	end
EOF
se stl=%f%r%m%h%w%=%{v:lua.get_skkeleton_modestring()}\ %{&et?'(et)':''}sw=%{&sw}\ E%{v:lua.get_error_count()}W%{v:lua.get_warn_count()}\ %l/%L

ino <c-f> <c-g>U<right>
ino <c-b> <c-g>U<left>
ino <c-p> <c-g>U<up>
ino <c-n> <c-g>U<down>
ino <c-d> <c-g>U<del>
ino <expr> <c-a> col('.') == match(getline('.'), '\S') + 1 ?
	\ repeat('<C-G>U<Left>', col('.') - 1) :
	\ (col('.') < match(getline('.'), '\S') ?
	\     repeat('<C-G>U<Right>', match(getline('.'), '\S') + 0) :
	\     repeat('<C-G>U<Left>', col('.') - 1 - match(getline('.'), '\S')))
ino <expr> <c-e> repeat('<C-G>U<Right>', col('$') - col('.'))

cno <c-f> <right>
cno <c-b> <left>
cno <c-p> <up>
cno <c-n> <down>
cno <c-d> <del>
cno <c-a> <home>
cno <c-e> <end>

se ut=1
au CursorHold * ++once se ut=4000

let g:loaded_netrwPlugin = v:true
let g:loaded_remote_plugins = v:true
let g:skip_loading_mswin = v:true
let g:loaded_tutor_mode_plugin = v:true
let g:loaded_2html_plugin = v:true

let s:dein = $"{stdpath('cache')}/dein"
let s:dein_plugin = $"{s:dein}/repos/github.com/Shougo/dein.vim"
if !(s:dein_plugin->isdirectory())
	exe '!git clone https://github.com/Shougo/dein.vim' s:dein_plugin
endi
exe $"se rtp^={s:dein_plugin}"

if dein#min#load_state(s:dein)
	cal dein#begin(s:dein)
	let s:toml = $"{stdpath('config')}/dein"
	cal dein#load_toml($'{s:toml}/plugin.toml', #{lazy:0})
	cal dein#load_toml($'{s:toml}/common.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/game.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/treesitter.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/lsp-core.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/lsp.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/cmp.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/tweaks.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/ft.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/fern.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/ui.toml', #{lazy:1})
	cal dein#end()
	let g:dein#auto_recache = v:true
	cal dein#save_state()
endi

if dein#check_install()
	cal dein#install()
	cal dein#deno_cache()
endi

au BufEnter *.er setl ft=erg
colo onedark
