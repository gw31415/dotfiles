(setq-default tab-width 4 indent-tabs-mode nil)
(require 'ox-latex)

(setq org-latex-with-hyperref nil)
(add-to-list 'org-latex-packages-alist "\\hypersetup{setpagesize=false}" t)
(add-to-list 'org-latex-packages-alist "\\hypersetup{colorlinks=true}" t)
(add-to-list 'org-latex-packages-alist "\\hypersetup{linkcolor=blue}" t)

(setq org-latex-pdf-process
      '("latexmk %f"
		"latexmk -c %f"))

(setq org-latex-title-command "\\maketitle")
(setq org-latex-toc-command
      "\\tableofcontents\n")
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
