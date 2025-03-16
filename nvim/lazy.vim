exec 'luafile' expand('<sfile>:p:h') . '/lua/lazy.lua'

se vop=folds
se cul
se cuc
se sb
se hid
se ls=3
se sms
se so=3
se diffopt+=algorithm:histogram
se stl=%f%r%m%h%w\ %{v:lua.get_macro_state()}%=%{&et?'(et)':''}sw=%{&sw}\ E%{v:lua.get_error_count()}W%{v:lua.get_warn_count()}\ %l/%L

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

" 空行での編集開始時に自動でインデント
nno <expr> a empty(getline('.')) ? '"_cc' : 'a'

if executable('rg')
	set grepprg=rg\ --vimgrep
	set grepformat=%f:%l:%c:%m
endif

if executable('mise')
	lua vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH
endif
