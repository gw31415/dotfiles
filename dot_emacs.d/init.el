(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(set-language-environment "Japanese")
(prefer-coding-system 'utf-8)
(set-default 'buffer-file-coding-system 'utf-8)

(define-key key-translation-map [?\C-h] [?\C-?])

(require 'package)
(require 'ox-latex)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages '(org)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(setq org-export-default-language 'ja)

(setq org-latex-pdf-process '("tectonic %f"))
(add-to-list 'org-latex-logfiles-extensions "tex~")
(add-to-list 'org-latex-logfiles-extensions "tex")

(setq org-latex-title-command "\\maketitle")
(setq org-latex-toc-command "\\tableofcontents\n")

(setq org-latex-text-markup-alist '((bold . "\\textbf{%s}")
                (code . verb)
                (italic . "\\it{%s}")
                (strike-through . "\\sout{%s}")
                (underline . "\\uline{%s}")
                (verbatim . protectedtexttt)))
(setq org-export-latex-listings t)
(setq org-latex-listings 'minted)
(setq org-latex-minted-options
      '(("frame" "lines")
        ("framesep=2mm")
        ("linenos=true")
        ("baselinestretch=1.2")
        ("fontsize=\\footnotesize")
        ("breaklines")
        ))

(add-to-list 'org-latex-classes
             '("jsarticle"
               "\\documentclass[uplatex]{jsarticle}
[NO-DEFAULT-PACKAGES]
\\usepackage[dvipdfmx]{graphicx}
\\usepackage[dvipdfmx]{color}
\\usepackage[dvipdfmx]{hyperref}
\\usepackage{pxjahyper}
\\usepackage{mhchem}"
	("\\section{%s}" . "\\section*{%s}")
	("\\subsection{%s}" . "\\subsection*{%s}")
	("\\subsubsection{%s}" . "\\subsubsection*{%s}")
	("\\paragraph{%s}" . "\\paragraph*{%s}")
	("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

(add-to-list 'org-latex-classes
             '("ltjsarticle"
               "\\documentclass[a4paper]{ltjsarticle}
[NO-DEFAULT-PACKAGES]
\\usepackage{etoolbox}
\\usepackage{letltxmacro}
\\usepackage{graphicx}
\\usepackage{grffile}
\\usepackage{xcolor}
\\usepackage{tikz}
\\usepackage{textcomp}
\\usepackage[luatex,pdfencoding=auto]{hyperref}

% ハイパーリンク
\\AtEndPreamble{
  \\usepackage{bookmark}
  \\usepackage{xurl}
  \\hypersetup{unicode,bookmarksnumbered=true,hidelinks,final}
}

% LuaTeX-ja設定
\\usepackage[no-math,deluxe,expert,haranoaji]{luatexja-preset}
\\setmainjfont[BoldFont=HaranoAjiGothic-Medium]{Harano Aji Mincho}[AutoFakeSlant=0.25]
\\setsansjfont{Harano Aji Gothic}[AutoFakeSlant=0.25]

\\newcommand{\\setdefaultjacharrange}{%
  \\ltjsetparameter{jacharrange={-1, -2, +3, -4, -5, +6, +7, +8, +9}}}
\\usepackage{luatexja-otf}
\\usepackage{lltjext}
\\AtEndPreamble{
  \\setdefaultjacharrange
  \\LetLtxMacro{\\orgmbox}{\\mbox}
  \\renewcommand{\\mbox}[1]{\\orgmbox{\\setdefaultjacharrange #1}}
  \\LetLtxMacro{\\amstext}{\\text}
  \\renewcommand{\\text}[1]{\\amstext{\\setdefaultjacharrange #1}}
}

% 引用は斜体
\\AtBeginEnvironment{quote}{\\itshape}

\\usepackage{amsmath}
\\usepackage{amsthm}
\\usepackage{amssymb}
\\usepackage{mathtools}
\\usepackage{mhchem}"
	("\\section{%s}" . "\\section{%s}")
	("\\subsection{%s}" . "\\subsection*{%s}")
	("\\subsubsection{%s}" . "\\subsubsection*{%s}")
	("\\paragraph{%s}" . "\\paragraph*{%s}")
	("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

(add-to-list 'org-latex-classes
             '("bxjsarticle"
               "\\documentclass[a4paper,xelatex,ja=standard]{bxjsarticle}
[NO-DEFAULT-PACKAGES]

% フォント設定
\\usepackage{fontspec}
\\setmainfont{Times New Roman}
\\setCJKmainfont[AutoFakeSlant=0.25,BoldFont=HaranoAjiGothic-Medium]{HaranoAjiMincho}
\\setsansfont[AutoFakeSlant=0.25]{HaranoAjiGothic}

% 引用は斜体
\\AtBeginEnvironment{quote}{\\itshape}

% ハイパーリンク
\\usepackage[pdfencoding=auto]{hyperref}
\\usepackage{bookmark}
\\usepackage{xurl}
\\hypersetup{unicode,bookmarksnumbered=true,hidelinks,final}

% パッケージ
\\usepackage{amsmath}
\\usepackage{amsthm}
\\usepackage{amssymb}
\\usepackage{mathtools}
\\usepackage[version]{mhchem}

"
	("\\section{%s}" . "\\section{%s}")
	("\\subsection{%s}" . "\\subsection*{%s}")
	("\\subsubsection{%s}" . "\\subsubsection*{%s}")
	("\\paragraph{%s}" . "\\paragraph*{%s}")
	("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

(setq org-latex-default-class "bxjsarticle")
