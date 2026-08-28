;;; doom-retrowave-theme.el --- Inspired by VSCode retrowave -*- no-byte-compile: t; -*-

;;; Commentary:
;;; This theme was inspired by the port of Horizon to Emacs
;;; see: https://github.com/aodhneine/retrowave-theme.el

(require 'doom-themes)

;;; Code:
(defgroup doom-retrowave-theme nil
  "Options for doom-themes"
  :group 'doom-themes)

(defcustom doom-retrowave-brighter-modeline nil
  "If non-nil, more vivid colors will be used to style the mode-line."
  :group 'doom-retrowave-theme
  :type 'boolean)

(defcustom doom-retrowave-brighter-comments nil
  "If non-nil, comments will be highlighted in more vivid colors."
  :group 'doom-retrowave-theme
  :type 'boolean)

(defcustom doom-retrowave-comment-bg doom-retrowave-brighter-comments
  "If non-nil, comments will have a subtle, darker background. Enhancing their legibility."
  :group 'doom-retrowave-theme
  :type 'boolean)

(defcustom doom-retrowave-padded-modeline doom-themes-padded-modeline
  "If non-nil, adds a 4px padding to the mode-line. Can be an integer to determine the exact padding."
  :group 'doom-retrowave-theme
  :type '(choice integer boolean))

;;
(def-doom-theme doom-retrowave
  ;; Color palette ref https://www.color-hex.com/color-palette/80753
  "A port of the Vim theme retrowave"

  ;; name         default   256       16
  ( (bg         '("#000000" "#000000" nil            ))
    (bg-alt     '("#000000" "#000000" nil            ))
    (base0      '("#16161c" "#16161c" "black"        ))
    (base1      bg-alt)
    (base2      '("#1d1f27" "#1c1e26" "brightblack"  ))
    (base3      '("#232530" "#232530" "brightblack"  ))
    (base4      '("#666666" "#626262" "brightblack"  ))
    (base5      '("#f9cec3" "#f9cec3" "brightblack"  ))
    (base6      '("#f9cbbe" "#f9cbbe" "brightblack"  ))
    (base7      '("#fadad1" "#fadad1" "brightblack"  ))
    (base8      '("#ffffff" "#ffffff" "white"        ))
    (fg-alt     '("#c4ccc4" "#d7d7d7" "brightwhite"  ))
    (fg         '("#ffffff" "#ffffff" "white"        ))

    (white      base8)
    (grey       base3)
    (red        '("#f84672" "#ff5f5f" "red"          ))
    (orange     '("#f09383" "#f09383" "brightred"    ))
    (green      '("#09f7a0" "#09f7a0" "green"        ))
    (teal       '("#00ffbb" "#00ffaf" "brightgreen"  ))
    (yellow     '("#fab795" "#fab795" "yellow"       ))
    (blue       '("#00fcf8" "#00ffff" "brightblue"   ))
    (dark-blue  '("#25b2bc" "#25b2bc" "blue"         ))
    (magenta    '("#6c6f93" "#6c6f93" "magenta"      ))
    (violet     '("#f6019d" "#ff00af" "brightmagenta"))
    (cyan       '("#4deedd" "#5fffd7" "brightcyan"   ))
    (dark-cyan  '("#2de2e6" "#00d7d7" "cyan"         ))

    ;; additional highlighting colours for retrowave
    (hor-highlight  (doom-lighten base1 0.05))
    (hor-highlight-selected (doom-lighten base4 0.1))
    (hor-highlight-bright (doom-lighten white 0.1))

    ;; face categories -- required for all themes
    (highlight      violet)
    (vertical-bar   base0)
    (selection      violet)
    (builtin        teal)
    (comments       hor-highlight-selected)
    (doc-comments   teal)
    (constants      cyan)
    (functions      teal)
    (keywords       violet)
    (methods        teal)
    (operators      teal)
    (type           teal)
    (strings        violet)
    (variables      dark-cyan)
    (numbers        teal)
    (region         hor-highlight)
    (error          violet)
    (warning        magenta)
    (success        green)
    (vc-modified    blue)
    (vc-added       green)
    (vc-deleted     violet)


    ;; custom categories
    (hidden     `(,(car bg) "black" "black"))
    (-modeline-bright doom-retrowave-brighter-modeline)
    (-modeline-pad
      (when doom-retrowave-padded-modeline
        (if (integerp doom-retrowave-padded-modeline) doom-retrowave-padded-modeline 4)))

    (modeline-fg     (doom-darken fg 0.2))
    (modeline-fg-alt (doom-lighten bg 0.2))

    (modeline-bg
      (if -modeline-bright
          base4
        `(,(car base1), (cdr fg-alt))))
    (modeline-bg-l
      (if -modeline-bright
          base4
        `(,(car base1), (cdr fg))))
    (modeline-bg-inactive   base1)
    (modeline-bg-inactive-l base1))


  ;; --- extra faces ------------------------
  ((elscreen-tab-other-screen-face :background "#353a42" :foreground "#1e2022")

    ((line-number &override) :foreground hor-highlight-selected)
    ((line-number-current-line &override) :foreground hor-highlight-bright
                                          :weight 'ultra-bold)

    (font-lock-keyword-face
     :foreground keywords
     :weight 'bold)

    (font-lock-function-name-face
     :foreground methods
     :weight 'bold)

    (font-lock-comment-face
      :inherit 'italic
      :foreground comments
      :background (if doom-retrowave-comment-bg (doom-lighten bg 0.05)))
    (font-lock-doc-face
      :inherit 'font-lock-comment-face
      :foreground doc-comments)

    (mode-line
      :background modeline-bg :foreground modeline-fg
      :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
    (mode-line-inactive
      :background modeline-bg-inactive :foreground modeline-fg-alt
      :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
    (mode-line-emphasis
      :foreground (if -modeline-bright base8 highlight))
    (header-line :inherit 'mode-line :background fg-alt)
    (mode-line-highlight :background base1 :foreground fg)

    ;; modeline
    (doom-modeline-bar :background (if -modeline-bright modeline-bg highlight))
    (doom-modeline-highlight :foreground (doom-lighten bg 0.3))
    (doom-modeline-project-dir :foreground violet :inherit 'bold )
    (doom-modeline-buffer-path :foreground violet)
    (doom-modeline-buffer-file :foreground fg)
    (doom-modeline-buffer-modified :foreground violet)
    (doom-modeline-panel :background base1)
    (doom-modeline-urgent :foreground modeline-fg)
    (doom-modeline-info :foreground dark-cyan)

    (solaire-mode-line-face
      :inherit 'mode-line
      :background modeline-bg-l
      :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-l)))
    (solaire-mode-line-inactive-face
      :inherit 'mode-line-inactive
      :background modeline-bg-inactive-l
      :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive-l)))

    ;; css-mode / scss-mode
    (css-proprietary-property :foreground violet)
    (css-property             :foreground fg)
    (css-selector             :foreground violet)

    ;; mic-paren
    (paren-face-match    :foreground green   :background base0 :weight 'ultra-bold)
    (paren-face-mismatch :foreground teal :background base0   :weight 'ultra-bold)
    (paren-face-no-match :inherit 'paren-face-mismatch :weight 'ultra-bold)

    ;; markdown-mode
    (markdown-markup-face           :foreground dark-cyan)
    (markdown-link-face             :foreground teal)
    (markdown-link-title-face       :foreground teal)
    (markdown-header-face           :foreground violet :inherit 'bold)
    (markdown-header-delimiter-face :foreground violet :inherit 'bold)
    (markdown-language-keyword-face :foreground teal)
    (markdown-markup-face           :foreground fg)
    (markdown-bold-face             :foreground violet)
    (markdown-table-face            :foreground fg :background base1)
    ((markdown-code-face &override) :foreground teal :background base1)

    ;; outline (affects org-mode)
    ((outline-1 &override) :foreground blue :background nil)

    ;; org-mode
    ((org-block &override) :background base1)
    ((org-block-begin-line &override) :background base1 :foreground comments)
    (org-hide :foreground hidden)
    (org-link :inherit 'underline :foreground teal)
    (org-agenda-done :foreground dark-cyan)
    (solaire-org-hide-face :foreground hidden)
    (solaire-header-line-face :background bg :foreground fg)
    (header-line :background base2 :foreground fg)

    ;; tooltip
    (tooltip              :background base0 :foreground fg)

    ;; haskell
    (haskell-type-face :foreground violet)
    (haskell-constructor-face :foreground teal)
    (haskell-operator-face :foreground fg)
    (haskell-literate-comment-face :foreground hor-highlight-selected)

    ;; magit
    (magit-section-heading :foreground violet)
    (magit-branch-remote   :foreground dark-cyan)

    ;; --- extra variables ---------------------
    ;; basics
    (link :foreground teal :inherit 'underline)
    (fringe :background bg)

    ;; evil
    (evil-ex-search          :background hor-highlight-selected :foreground fg)
    (evil-ex-lazy-highlight  :background hor-highlight :foreground fg)

    ;; completion
    (vertico-current :background violet :foreground bg :weight 'bold)
    (orderless-match-face-0 :foreground white :weight 'bold)
    (orderless-match-face-1 :foreground white :weight 'bold)
    (orderless-match-face-2 :foreground white :weight 'bold)
    (orderless-match-face-3 :foreground white :weight 'bold)
    (corfu-default :background base0 :foreground fg)
    (corfu-current :background hor-highlight :foreground fg)
    (corfu-bar :background violet)
    (corfu-border :background base3)

   ;; treemacs
   (treemacs-root-face :foreground fg :weight 'bold :height 1.2)
   (doom-themes-treemacs-root-face :foreground fg :weight 'ultra-bold :height 1.2)
   (doom-themes-treemacs-file-face :foreground fg)
   (treemacs-directory-face :foreground fg)
   (treemacs-git-modified-face :foreground green)

   ;; js2-mode
   (js2-object-property        :foreground violet)

   ;; rjsx-mode
   (rjsx-tag :foreground violet)
   (rjsx-tag-bracket-face :foreground violet)
   (rjsx-attr :foreground dark-cyan :slant 'italic :weight 'medium)))


;;; doom-retrowave-theme.el ends here
