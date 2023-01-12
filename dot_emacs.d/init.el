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

(setq org-latex-pdf-process '("latexmk %f" "latexmk -c %f"))

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
(setq org-latex-default-class "jsarticle")
