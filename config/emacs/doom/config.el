;; Aesthetics
(setq display-line-numbers-type t
      indicate-empty-lines t
      doom-theme 'doom-retrowave
      doom-themes-enable-bold t)

(load! "org")

;; Generic writing (code or text)
(use-package! rainbow-delimiters
  :hook
  (prog-mode . rainbow-delimiters-mode))

;; Increase the Olivetti minor mode body width
;; Goal: improve visual experience when doom-big-font-mode is active
(setq olivetti-body-width 88)

;; Keep prose readable without rewriting source code as it is entered.
(setq-default fill-column 80)
(add-hook 'text-mode-hook #'turn-on-auto-fill)

;; Delete trailing whitespaces on file save
(add-hook! before-save-hook 'delete-trailing-whitespace)

;; Make Vertico/Orderless behave closer to Ivy's fuzzy matching.
(after! orderless
  (setq orderless-matching-styles
        '(orderless-literal orderless-regexp orderless-flex)))

(after! vertico
  (defun mc/face-contains-any-p (face target-faces)
    "Return non-nil if FACE contains any face in TARGET-FACES."
    (cond
     ((memq face target-faces))
     ((and (consp face) (keywordp (car face))) nil)
     ((consp face)
      (cl-some (lambda (subface)
                  (mc/face-contains-any-p subface target-faces))
                face))))

  (defun mc/vertico-current-inverted-face ()
    "Return a face plist that follows the active `vertico-current' colors."
    (let ((foreground (face-attribute 'vertico-current :foreground nil 'default))
          (fallback (face-attribute 'default :background nil 'default)))
      `(:foreground ,(if (eq foreground 'unspecified) fallback foreground)
        :weight bold)))

  (defun mc/vertico-current-marginalia-invert-face (candidate target-faces)
    "Make TARGET-FACES use selected-row colors in Vertico CANDIDATE."
    (let ((start 0)
          (selected-face (mc/vertico-current-inverted-face)))
      (while (< start (length candidate))
        (let* ((face (get-text-property start 'face candidate))
               (end (next-single-property-change start 'face candidate
                                                 (length candidate))))
          (when (mc/face-contains-any-p face target-faces)
            (add-face-text-property start end selected-face nil candidate))
          (setq start end))))
    candidate)

  (cl-defmethod vertico--format-candidate :around
    (candidate prefix suffix index start)
    (let ((formatted (cl-call-next-method candidate prefix suffix index start)))
      (if (= index vertico--index)
          (mc/vertico-current-marginalia-invert-face
           formatted
           '(marginalia-date
             marginalia-size
             marginalia-file-priv-write))
        formatted))))

(general-auto-unbind-keys :off)
