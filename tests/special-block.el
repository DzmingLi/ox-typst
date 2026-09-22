;;; special-block.el --- Special block export tests -*- lexical-binding: t; -*-
(require 'ert)
(require 'ox-typst)
(setq org-export-use-babel nil)

(ert-deftest org-typst-block-raw-arguments ()
  (let* ((text "#+begin_custom :positional [A :literal B] :name \"a :key b\" :empty \"\" :fill rgb(\"#fff\") :numbering none :outlined false :data (key: [value])\n*Body*\n#+end_custom\n")
         (out (org-export-string-as text 'typst t)))
    (should (string-match-p (regexp-quote "#custom([A :literal B], name: \"a :key b\", empty: \"\", fill: rgb(\"#fff\"), numbering: none, outlined: false, data: (key: [value]))[") out))
    (should (string-match-p "Body" out))))

(ert-deftest org-typst-block-nesting-and-labels ()
  (let* ((text "#+NAME: claim-one\n#+begin_claim :title [Title]\nA\n#+begin_reason\nDone.\n#+end_reason\n#+end_claim\nSee [[claim-one][the claim]].\n")
         (out (org-export-string-as text 'typst t)))
    (should (string-match-p "#claim(title: \\[Title\\])" out))
    (should (string-match-p "#reason\\[" out))
    (should (string-match "#label(\"\\([^\"]+\\)\")" out))
    (let ((label (match-string 1 out)))
      (should (string-match-p (regexp-quote (format "#link(label(\"%s\"))[the claim]" label)) out)))))

(ert-deftest org-typst-block-label-argument ()
  (let* ((out (org-export-string-as "#+NAME: claim-one\n#+begin_claim :label <thm:one> :name [Title]\nBody\n#+end_claim\n[[claim-one]]\n" 'typst t)))
    (should (string-match-p (regexp-quote "#claim(label: <thm:one>, name: [Title])[") out))
    (should (string-match-p (regexp-quote "#ref(<thm:one>)") out))
    (should-not (string-match-p "#label(" out))))

(ert-deftest org-typst-block-names ()
  (let ((text "#+begin_typst-theorem\nBody\n#+end_typst-theorem\n"))
    ;; Names are preserved verbatim; there is no implicit prefix stripping.
    (should (string-match-p (regexp-quote "#typst-theorem[")
                            (org-export-string-as text 'typst t))))
  ;; Org's built-in example block is not exported as a function call.
  (let ((out (org-export-string-as
              "#+begin_example\n$unknown$\n#+end_example\n" 'typst t)))
    (should-not (string-match-p (regexp-quote "#example[") out))))

(ert-deftest org-typst-block-header-is-argument-source ()
  (let ((out (org-export-string-as
              "#+ATTR_TYPST: :title [Ignored] :label <ignored>\n#+begin_theorem :positional [勾股定理] :positional 2 :numbering none\nBody\n#+end_theorem\n" 'typst t)))
    (should (string-match-p
             (regexp-quote "#theorem([勾股定理], 2, numbering: none)[") out))
    (should-not (string-match-p "Ignored\\|ignored" out))))
