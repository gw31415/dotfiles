;; extends
;; rsplug の TOML 内 lua_* キー (lua_after / lua_before / lua_start / ...) の
;; 文字列値を Lua として抜き出す。
;; Neovim 側 config/nvim_after/queries/toml/injections.scm (#vim-match? 版) に対応する
;; kakehashi 移植 (#lua-match? 版。kakehashi は #vim-match? を解さない)。
;; emmylua_ls がブリッジ経由で診断・補完を提供する。
;; 三重引用 (offset 3) と単引用 (offset 1) で規則を分け、重複領域を作らない。
;; 複数行文字列 ('''直後に改行) は先頭改行を範囲外にする (offset 4 = ''' + \n、
;; CRLF は offset 5)。仮想文書が "\n..." で始まると下流フォーマッタが先頭空行を
;; 除去し、書き戻し時に ''' 直後の改行が消えるため。行 offset は元の列を維持する
;; 仕様 (offset_calculator.rs) のため使えず、列 offset (row 0) のバイト加算で
;; 改行を跨ぐ。単一行 ('''...''') は従来通り offset 3。
((pair
  (bare_key) @_key
  (string) @injection.content)
  (#lua-match? @_key "^lua_")
  (#lua-match? @injection.content "^'''\r\n")
  (#set! injection.language "lua")
  (#offset! @injection.content 0 5 0 -3))
((pair
  (bare_key) @_key
  (string) @injection.content)
  (#lua-match? @_key "^lua_")
  (#lua-match? @injection.content "^'''\n")
  (#set! injection.language "lua")
  (#offset! @injection.content 0 4 0 -3))
((pair
  (bare_key) @_key
  (string) @injection.content)
  (#lua-match? @_key "^lua_")
  (#lua-match? @injection.content "^'''[^\n\r]")
  (#set! injection.language "lua")
  (#offset! @injection.content 0 3 0 -3))
((pair
  (bare_key) @_key
  (string) @injection.content)
  (#lua-match? @_key "^lua_")
  (#lua-match? @injection.content "^\"\"\"\r\n")
  (#set! injection.language "lua")
  (#offset! @injection.content 0 5 0 -3))
((pair
  (bare_key) @_key
  (string) @injection.content)
  (#lua-match? @_key "^lua_")
  (#lua-match? @injection.content "^\"\"\"\n")
  (#set! injection.language "lua")
  (#offset! @injection.content 0 4 0 -3))
((pair
  (bare_key) @_key
  (string) @injection.content)
  (#lua-match? @_key "^lua_")
  (#lua-match? @injection.content "^\"\"\"[^\n\r]")
  (#set! injection.language "lua")
  (#offset! @injection.content 0 3 0 -3))
((pair
  (bare_key) @_key
  (string) @injection.content)
  (#lua-match? @_key "^lua_")
  (#lua-match? @injection.content "^'[^']")
  (#set! injection.language "lua")
  (#offset! @injection.content 0 1 0 -1))
((pair
  (bare_key) @_key
  (string) @injection.content)
  (#lua-match? @_key "^lua_")
  (#lua-match? @injection.content "^\"[^\"]")
  (#set! injection.language "lua")
  (#offset! @injection.content 0 1 0 -1))
