# pez (fish plugin manager)。conf.d hook を現シェルに反映。
# plugin 一覧は pez.toml、固定版は pez-lock.toml で管理。
if status is-interactive; and command -q pez
    pez activate fish | source
end
