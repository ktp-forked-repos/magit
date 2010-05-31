(defvar rebase-mode-action-line-re
  (rx
   line-start
   (group
    (|
     (any "presf")
     "pick"
     "reword"
     "edit"
     "squash"
     "fixup"))
   (char space)
   (group
    (** 7 40 (char "0-9" "a-f" "A-F"))) ;sha1
   (char space)
   (* anything)                         ; msg
   line-end))

(defvar rebase-font-lock-keywords
  (list
   (list rebase-mode-action-line-re
         '(1 font-lock-keyword-face)
         '(2 font-lock-builtin-face))))

(defun rebase-mode-edit-line (change-to)
    (let ((buffer-read-only nil)
          (start (point)))
      (goto-char (point-at-bol))
      (kill-region (point) (progn (forward-word 1) (point)))
      (insert change-to)
      (goto-char start)))

(defun rebase-mode-looking-at-action ()
  (save-excursion
    (goto-char (point-at-bol))
    (looking-at rebase-mode-action-line-re)))

(defun rebase-mode-setup ()
  (setq buffer-read-only t)
  (use-local-map rebase-mode-map))

(defun rebase-mode-move-line-up ()
  (interactive)
  (when (rebase-mode-looking-at-action)
    (let ((buffer-read-only nil))
      (transpose-lines 1)
      (previous-line 2))))

(defun rebase-mode-move-line-down ()
  (interactive)
  ;; if we're on an action and the next line is also an action
  (when (and (rebase-mode-looking-at-action)
             (save-excursion
               (forward-line)
               (rebase-mode-looking-at-action)))
    (let ((buffer-read-only nil))
      (next-line 1)
      (transpose-lines 1)
      (previous-line 1))))

(defun rebase-mode-kill-line ()
  (interactive)
  (let* ((buffer-read-only nil)
         (region (list (point-at-bol)
                       (progn (forward-line)
                              (point-at-bol))))
         ;; might be handy to let the user know what went
         ;; somehow... sometime
         (text (apply 'buffer-substring region)))
    (apply 'kill-region region)))

(defvar rebase-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") 'server-edit)
    (define-key map (kbd "M-p") 'rebase-mode-move-line-up)
    (define-key map (kbd "M-n") 'rebase-mode-move-line-down)
    (define-key map (kbd "k") 'rebase-mode-kill-line)
    (dolist (key-fun '(("p" . "pick")
                       ("r" . "reword")
                       ("e" . "edit")
                       ("s" . "squash")
                       ("f" . "fixup")))
      (define-key map (car key-fun)
         `(lambda ()
           (interactive)
           (rebase-mode-edit-line ,(cdr key-fun)))))
    map))

(define-generic-mode 'rebase-mode
  '("#")
  nil
  rebase-font-lock-keywords
  '("git-rebase-todo")
  '(rebase-mode-setup)
  "Mode for blah")

;;(defun rebase-mode ()
;;  (interactive)
;;  (kill-all-local-variables)
;;  (make-local-variable 'font-lock-defaults)
;;  (setq font-lock-defaults '(rebase-font-lock-keywords nil t nil nil))
;;
;;  (set (make-local-variable 'comment-start) "#")
;;  (set (make-local-variable 'comment-end) "")
;;
;;  (setq mode-name "rebase" major-mode 'rebase-mode))

(provide 'rebase-mode)


;; "\\([0-9a-fA-F]\\{40\\}\\) "
