; -*- Mode: Emacs-Lisp -*-

;;; pig-mode.el -- Major mode for Pig files

;; Software License Agreement (BSD License)
;;
;; Copyright (c) 2009 Sergei Matusevich <sergei.matusevich@gmail.com>
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;; 3. The name of the author may not be used to endorse or promote products
;;    derived from this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
;; IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
;; OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
;; IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
;; INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
;; NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
;; THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;; Put this file into your Emacs lisp path (eg. site-lisp)
;; and add the following line to your ~/.emacs file:
;;
;;   (require 'pig-mode)

(require 'font-lock)

(defvar pig-mode-hook nil)

(defvar pig-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "RET") 'newline-and-indent)
    keymap)
  "Keymap for pig major mode")

(add-to-list 'auto-mode-alist '("\\.pig\\'" . pig-mode))

(defconst pig-font-lock-keywords
  `((,(regexp-opt
       '("LOAD" "STORE" "FILTER" "FOREACH" "ORDER" "ARRANGE"
         "DISTINCT" "COGROUP" "JOIN" "CROSS" "UNION" "SPLIT" "INTO"
         "IF" "ALL" "ANY" "AS" "BY" "USING" "INNER" "OUTER" "PARALLEL"
         "GROUP" "CONTINUOUSLY" "WINDOW" "TUPLES" "GENERATE" "EVAL"
         "DEFINE" "INPUT" "OUTPUT" "SHIP" "CACHE" "STREAM" "THROUGH"
         "SECONDS" "MINUTES" "HOURS" "ASC" "DESC"
         "NULL" "AND" "OR" "NOT" "EQ" "NEQ" "GT" "LT" "GTE" "LTE"
         "MATCHES" "IS")
       'words)
     (1 font-lock-keyword-face))

    ("^ *\\(REGISTER\\) *\\([^;]+\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-string-face))
    (,(concat
       (regexp-opt
        '("FLATTEN" "SUM" "COUNT" "MIN" "MAX" "AVG" "ARITY" "TOKENIZE"
          "DIFF" "SIZE" "CONCAT"
          "BinStorage" "PigStorage" "TextLoader" "PigDump" "IsEmpty")
        'words)
       "(")
     (1 font-lock-function-name-face))
    ("\\<\\([0-9]+[lL]\\|\\([0-9]+\\.?[0-9]*\\|\\.[0-9]+\\)\\([eE][-+]?[0-9]+\\)?[fF]?\\)\\>"
     . font-lock-constant-face)
    ("\\<$[0-9]+\\>" . font-lock-variable-name-face)
    (,(regexp-opt
       '("chararray" "bytearray" "int" "long" "float" "double" "tuple"
         "bag" "map")
       'words)
     (1 font-lock-type-face)))
  "regexps to highlight in pig mode")

(defvar pig-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?_  "w"      st)
    (modify-syntax-entry ?-  ". 56"   st)
    (modify-syntax-entry ?-  ". 12b"  st)
    (modify-syntax-entry ?/  ". 1456" st)
    (modify-syntax-entry ?*  ". 23"   st)
    (modify-syntax-entry ?\n "> b"    st)
    (modify-syntax-entry ?\" "\""     st)
    (modify-syntax-entry ?\' "\""     st)
    (modify-syntax-entry ?\` "\""     st)
    st)
  "Syntax table for pig mode")

(defun pig-indent-line ()
  "Indent current line as Pig code"
  (interactive)
  (indent-line-to (save-excursion
    (beginning-of-line)
    (if (looking-at ".*}[ \t]*;[ \t]*$")
        (pig-statement-indentation)
      (forward-line -1)
      (while (and (not (bobp)) (looking-at "^[ \t]*$"))
        (forward-line -1) )
      (cond
       ((bobp) 0)
       ((looking-at "^[ \t]*--") (current-indentation))
       ((looking-at ".*;[ \t]*$") (pig-statement-indentation))
       (t (+ (pig-statement-indentation) default-tab-width)) ) ) )) )

(defun pig-statement-indentation ()
  (save-excursion
    (beginning-of-line)
    (cond
     ((bobp) 0)
     ((looking-at ".*\\(}[ \t]*;\\|)\\)[ \t]*$")
      (end-of-line)
      (backward-list)
      (pig-statement-indentation) )
     ((search-backward-regexp "[{;][ \t]*$" nil t)
      (forward-line 1)
      (beginning-of-line)
      (while (and (looking-at "^[ \t]*\\(--.*\\)?$")
                  (save-excursion (end-of-line) (not (eobp))) )
        (forward-line 1) )
      (current-indentation) )
     (t 0) ) ) )

(define-derived-mode pig-mode fundamental-mode "pig"
  "Major mode for editing Yahoo! .pig files"
  :syntax-table pig-mode-syntax-table
  (set (make-local-variable 'font-lock-defaults) '(pig-font-lock-keywords nil t))
  (set (make-local-variable 'indent-line-function) 'pig-indent-line) )

(provide 'pig-mode)

;;; end of pig-mode.el
