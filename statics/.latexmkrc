#!/usr/bin/env perl
$latex            = 'uplatex -halt-on-error -synctex=1 -interaction=nonstopmode';
$latex_silent     = 'uplatex -halt-on-error -synctex=1 -interaction=nonstopmode';
$bibtex           = 'upbibtex %O %B';
$biber            = 'biber --bblencoding=utf8 -u -U --output_safechars';
$dvipdf           = 'dvipdfmx %O -o %D %S';
$makeindex        = 'mendex %O -o %D %S';
$max_repeat       = 5;
$pdf_mode         = 3;
@generated_exts   = (@generated_exts, 'dvi', 'synctex.gz', 'bbl');
