;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'doom-material)
(setq doom-theme 'doom-city-lights)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Show major-mode icon in modeline (Doom disables it by default).
(setq doom-modeline-major-mode-icon t)

;; Prevent dirvish from spawning expensive batch processes to fetch vc-state
;; per file when opening dired buffers in large repos.
(after! dirvish
  (setq dirvish-attributes (remove 'vc-state dirvish-attributes)))

;; Neovim-style VCS markers in TTY line-number margin.
(after! diff-hl-margin
  (setf (alist-get 'insert diff-hl-margin-symbols-alist) "┃"
        (alist-get 'change diff-hl-margin-symbols-alist) "┃"
        (alist-get 'delete diff-hl-margin-symbols-alist) "┃"))

;; Match GUI behavior in TTY: don't show staged hunks as reference markers.
(after! diff-hl
  (unless (display-graphic-p)
    (setq diff-hl-highlight-reference-function nil)))

;; Spacemacs-style expand-region flow: `SPC v` to expand, then `V` to contract.
(after! expand-region
  (setq expand-region-contract-fast-key "V"))

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; Restore Org default for inactive timestamps in Org buffers.
(after! org
  (define-key org-mode-map (kbd "C-c !") #'org-time-stamp-inactive))

;; Keep Flycheck bindings out of Org buffers.
(after! flycheck
  (add-hook 'org-mode-hook (lambda () (flycheck-mode -1))))

;; Scrach buffer starts in text-mode
(setq doom-scratch-initial-major-mode 'text-mode)

;; Highlight trailing whitespace
(setq-default show-trailing-whitespace t)
;; Keep minibuffer/echo area free of trailing-whitespace highlights.
(add-hook 'minibuffer-setup-hook #'doom-disable-show-trailing-whitespace-h)
(add-hook 'minibuffer-inactive-mode-hook #'doom-disable-show-trailing-whitespace-h)

;; Treat _ as a word character (like Neovim) so `*` searches the full SNAKE_CASE symbol.
(modify-syntax-entry ?_ "w" (standard-syntax-table))
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook (lambda () (modify-syntax-entry ?_ "w"))))
;; Make `*` use word boundaries, not symbol boundaries (matches Neovim behavior).
(setq evil-symbol-word-search nil)



;; This section contains general Evil rebindings.
(after! evil
  (define-key evil-motion-state-map (kbd "C-k") #'evil-scroll-line-up)
  (define-key evil-motion-state-map (kbd "C-j") #'evil-scroll-line-down)
  (define-key evil-motion-state-map (kbd "C-e") #'evil-end-of-line)
  (define-key evil-motion-state-map (kbd "C-a") #'evil-first-non-blank)
  (define-key evil-visual-state-map (kbd "s") #'evil-surround-region)

  (define-key evil-insert-state-map (kbd "C-e") #'move-end-of-line)
  (define-key evil-insert-state-map (kbd "C-a") #'evil-first-non-blank)
  ;; makes C-y works as default Emacs
  (define-key evil-insert-state-map (kbd "C-y") nil)

  (map! :nvim
        "C-s" #'+default/search-buffer
        "C-S-s" #'isearch-forward))

(defun +evil-buffer-new-start-in-text-mode-a (orig-fn &optional file)
  "Force unnamed buffers created by `evil-buffer-new' to use `text-mode'."
  (funcall orig-fn file)
  (unless file
    (with-current-buffer (window-buffer (selected-window))
      (text-mode))))

(advice-add 'evil-buffer-new :around #'+evil-buffer-new-start-in-text-mode-a)

(map! :when (modulep! :editor multiple-cursors)
      :nv "C-n" #'evil-mc-make-and-goto-next-match
      :nv "C-p" #'evil-mc-make-and-goto-prev-match)

(defun henrique/copy-clipboard-to-whole-buffer ()
  "Copy clipboard and replace buffer."
  (interactive)
  (delete-region (point-min) (point-max))
  (clipboard-yank)
  (deactivate-mark))

(map! "C-x C-b" #'ibuffer)

(map! :leader
      :desc "M-x" "SPC" #'execute-extended-command
      :desc "Switch to last buffer" "TAB" #'evil-switch-to-windows-last-buffer
      :desc "Expand region" "v" #'er/expand-region
      :desc "Contract region" "V" #'er/contract-region
      (:prefix "b"
       :desc "Paste and replace buffer" "p" #'henrique/copy-clipboard-to-whole-buffer
       :desc "Scratch buffer" "s" #'doom/switch-to-scratch-buffer
       :desc "Kill buffer & window" "D" #'kill-buffer-and-window
       :desc "List buffers (ibuffer)" "l" #'ibuffer)
      (:prefix "w"
       :desc "Other window" "TAB" #'other-window
       :desc "Maximize buffer" "m" #'doom/window-maximize-buffer
       :desc "Kill buffer & window" "D" #'kill-buffer-and-window)
      (:prefix "g"
       :desc "Magit status" "s" #'magit-status))

(with-eval-after-load 'magit
  ;; restore traditional magit window placement
  (setq magit-display-buffer-function #'magit-display-buffer-traditional)
  ;; remove "recent commits" section
  (setq magit-log-section-commit-count 0))

;; Spacemacs parity: switch between source/header.
(map! :after cc-mode
      :map (c-mode-map c++-mode-map)
      :n ", g a" #'projectile-find-other-file
      :n ", g A" #'projectile-find-other-file-other-window)

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
