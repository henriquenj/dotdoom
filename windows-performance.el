;;; windows-performance.el -*- lexical-binding: t; -*-

;; Windows performance settings, loaded conditionally from config.el.

;; On Windows, disable Doom's automatic Git gutter in Dired. Enabling
;; `diff-hl-dired-mode' runs Git status queries when directories are opened
;; or refreshed, and process startup can be costly on Windows.
(remove-hook 'dired-mode-hook #'+vc-gutter-enable-maybe-h)

;; On Windows, disable diff-hl's on-the-fly updates to reduce subprocess
;; work and avoid requiring GNU `diff', which may be absent from exec-path.
;; The gutter shows saved changes and updates on save; Doom's escape,
;; window-switch, and frame-focus hooks also request updates when its cached
;; point or VC state changes.
(remove-hook 'diff-hl-mode-hook #'diff-hl-flydiff-mode)

;; Work around the debounce comparison in the pinned Doom revision on
;; Windows. Doom wraps the previous (point . PLIST) state in another cons,
;; so it never matches the new state. Compare the two states directly to
;; avoid redundant gutter updates on escape, window switch, and frame focus.
(after! diff-hl
  (defun +henrique/vc-gutter-update-h (&rest _)
    "Refresh the vc gutter, but only when point or the file's vc state moved.
Returns nil so it doesn't shadow other `doom-escape-hook' hooks."
    (when-let* (((or (bound-and-true-p diff-hl-mode)
                     (bound-and-true-p diff-hl-dir-mode)))
                ((not (file-remote-p default-directory)))
                (file (buffer-file-name (buffer-base-buffer)))
                ((not (equal +vc-gutter--last-state
                             (setq +vc-gutter--last-state
                                   (cons (point)
                                         (copy-sequence
                                          (symbol-plist
                                           (intern (expand-file-name file)
                                                   vc-file-prop-obarray)))))))))
      (ignore (diff-hl-update))))
  (advice-add '+vc-gutter-update-h :override #'+henrique/vc-gutter-update-h))

;; On Windows, take Doom's magit auto-revert off the frame-focus hook.
;; `+magit-mark-stale-buffers-h' scans buffers and refreshes visible repository
;; buffers, which can run Git repeatedly whenever Emacs regains focus.
;;
;; It stays on `magit-post-refresh-hook', so buffers still refresh after Git
;; operations made from inside Magit, and `+magit-revert-buffer-maybe-h' still
;; handles buffers marked stale when switching to them. Returning from an
;; external Git command no longer forces a VC-state refresh. Doom's file
;; auto-revert remains enabled, but use `vc-refresh-state' or refresh Magit
;; explicitly if external Git changes leave the VC state or gutter stale.
(after! magit
  (remove-hook 'doom-switch-frame-hook #'+magit-mark-stale-buffers-h))

;; On Windows, prefer Git for Windows' real binary to its cmd/bin wrapper
;; to avoid an extra process launch. Resolve it relative to the Git selected
;; by exec-path, so custom and portable installation locations also work.
;; Leave the existing settings alone if no known native binary is found.
;; VC's absolute Windows path needs a separate setting for remote TRAMP
;; repositories; Magit uses `magit-remote-git-executable' for remote hosts.
(when-let* ((git (executable-find "git"))
            (git-dir (file-name-directory git))
            ((member (downcase (file-name-nondirectory
                               (directory-file-name git-dir)))
                     '("cmd" "bin")))
            (git-root (file-name-directory (directory-file-name git-dir)))
            (git-bin (seq-find
                      #'file-executable-p
                      (mapcar (lambda (path) (expand-file-name path git-root))
                              '("mingw64/bin/git.exe"
                                "mingw32/bin/git.exe"
                                "clangarm64/bin/git.exe")))))
  (setq vc-git-program git-bin)
  (after! magit
    (setq magit-git-executable git-bin)))
