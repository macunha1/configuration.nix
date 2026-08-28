;; Let Emacs prompt for GPG passphrases in its own minibuffer. Other clients
;; continue using the configured pinentry program.
(setq epa-pinentry-mode 'loopback)

;; Workflow map
;;
;; Storage model (from the original External Brain index and its successor
;; notes):
;;   external-brain/agenda   current actions and their execution timeline
;;   external-brain/logs     time-bound work evidence for stand-ups/reviews
;;   external-brain/journal  chronological personal context
;;   external-brain/notes    quick capture awaiting refinement
;;   hippocampus             durable, linked knowledge and Org-roam hub notes
;;   stdout/ideas/box        screened ideas ready for research or execution
;;   stdout                  publishable output derived from the system
;;
;; The goal is retrieval and reuse, not accumulation: revisit captured material,
;; enrich and connect it, then move it toward the appropriate durable area.
;; Preserve old material when reorganizing so past decisions, failures, and
;; progress remain available as evidence.
;;
;; Start with `M-x org-capture', then choose a template key:
;;   n    transient note -> external-brain/notes/<year>/index.org :: INBOX
;;   i    fleeting idea -> external-brain/ideas/parking-lot/<year>/index.org
;;   j    journal entry -> external-brain/journal/<year>/index.org
;;   t    personal task -> external-brain/agenda/index.org :: PARKING LOT
;;   w i  work idea -> external-brain/ideas/parking-lot/<year>/work.org
;;   w n  work note -> external-brain/notes/<year>/work.org :: INBOX
;;   w t  work task -> external-brain/agenda/work.org :: CAPTURED
;;   w l  completed-work log -> external-brain/logs/<year>/index.org
;;
;; The parking lot is deliberately low-friction: capture a distracting thought
;; without leaving the current task. During review, discard it, enrich it into a
;; durable Hippocampus note, or promote a viable project manually to
;; stdout/ideas/box. The promotion step is intentionally not automated because
;; the Ideas Box is the screened staging area before research and execution.
;; See hippocampus/notes/productivity/ideas-boxes.org for the complete model:
;; Parking Lot -> Ideas Box -> private or public production.
;;
;; Run `M-x org-agenda' and select:
;;   o  overview across deadlines, priorities, projects, WAIT, and MAYBE
;;   w  active work projects from agenda/work.org
;;   p  active personal projects from agenda/index.org
;;   f  the Someday/Maybe backlog

;; Org mode and the gang {{
(setq org-base-directory "~/Workspace/org-mode"
      org-directory (expand-file-name "external-brain" org-base-directory)
      org-roam-directory (expand-file-name "hippocampus" org-base-directory)

      org-blank-before-new-entry '((heading . always)
                                   (plain-list-item . always))
      org-cycle-separator-lines 1

      ;; Org Capture
      +org-capture-timestamp-format "<%F %a %H:%M>"
      +org-capture-work-todo-file (expand-file-name "agenda/work.org"
                                                    org-directory)
      +org-capture-personal-todo-file (expand-file-name "agenda/index.org"
                                                        org-directory)
      +org-capture-logs-file (expand-file-name (format-time-string
                                                "logs/%Y/index.org")
                                               org-directory)
      +org-capture-ideas-file (expand-file-name (format-time-string
                                                 "ideas/parking-lot/%Y/index.org")
                                                org-directory)
      +org-capture-work-ideas-file (expand-file-name (format-time-string
                                                      "ideas/parking-lot/%Y/work.org")
                                                     org-directory)
      +org-capture-work-notes-file  (expand-file-name (format-time-string
                                                       "notes/%Y/work.org")
                                                      org-directory)

      ;; Doom Emacs variables with custom values
      +org-capture-todo-file "agenda/captured.org"
      +org-capture-projects-file "projects/captured.org"

      ;; Same as the Org Journal file specified below
      +org-capture-journal-file (format-time-string "journal/%Y/index.org")
      +org-capture-notes-file (format-time-string "notes/%Y/index.org"))

(setq org-journal-dir (expand-file-name "journal" org-directory)
      org-journal-file-format "%Y/index.org"
      org-journal-file-type 'yearly
      org-journal-date-format "%A, %d %B %Y %Z")

;; Org Agenda and Super Agenda tuning {{
(use-package! org-super-agenda
  :commands (org-super-agenda-mode))
(after! org-agenda (org-super-agenda-mode))

;; TODO is actionable now, MAYBE belongs to a future review, and WAIT requires
;; external input. Add a PROJECT property to group related work in the overview;
;; add the gotd tag to make the day's primary outcome visible near the top.
(after! org (setq org-todo-keywords (append '((sequence "TODO(t)" "MAYBE(m)" "WAIT(w)" "|" "DONE(d)"))
                                            org-todo-keywords)
                  org-todo-keyword-faces '(("TODO" . org-todo)
                                           ("MAYBE" . org-todo)
                                           ("WAIT" . org-warning)
                                           ("KILL" . error)
                                           ("DONE" . org-done))))

(setq org-agenda-files (let ((agenda-directory (expand-file-name "agenda" org-directory)))
                         (when (file-directory-p agenda-directory)
                           (directory-files-recursively agenda-directory "\\.org$")))
      org-agenda-skip-scheduled-if-done t
      org-agenda-skip-deadline-if-done t
      org-agenda-include-deadlines t
      org-agenda-compact-blocks t)

(setq org-agenda-custom-commands
      '(("o" "Overview"
         ((alltodo nil ((org-super-agenda-groups
                         '((:name "Overdue"
                            :deadline past
                            :face error
                            :order 0)
                           (:name "Goal of the Day"
                            :tag "gotd"
                            :order 1)
                           (:name "Due Today"
                            :deadline today
                            :order 3)
                           (:name "High Priority"
                            :priority "A"
                            :order 5)
                           (:name "Projects"
                            :auto-property "PROJECT"
                            :order 14)
                           (:name "Waiting"
                            :todo "WAIT"
                            :order 20)
                           (:name "Someday/Maybe"
                            :todo "MAYBE"
                            :order 90)))))))
        ("w" "On-going Work Projects"
         ((todo nil ((org-super-agenda-groups
                      '((:name "Hide future Projects"
                         :discard (:todo "MAYBE"))
                        (:name "Filter by Path"
                         :discard (:not (:file-path "work.org")))
                        (:name "Discard hidden entries"
                         :discard (:tag ("hide")))
                        (:name "High Priority"
                         :priority "A")
                        (:name "Overdue"
                         :deadline past
                         :face error
                         :order 0)
                        (:name "On-going Projects"
                         :auto-parent)))))))
        ("p" "On-going Personal Projects"
         ((todo nil ((org-super-agenda-groups
                      '((:name "Hide future Projects"
                         :discard (:todo "MAYBE"))
                        (:name "Filter by Path"
                         :discard (:not (:file-path "index.org")))
                        (:name "On-going Projects"
                         :auto-parent)))))))
        ("f" "Future (Someday/Maybe only)"
         ((todo nil ((org-super-agenda-groups
                      '((:name "Someday/Maybe only"
                         :discard (:not (:todo "MAYBE")))
                        (:name "On-going Projects"
                         :auto-property "PROJECT"
                         :order 10)))))))))
;; }} Org Agenda and Super Agenda tuning

;; Before finalizing with Org Capture, add DATE property to entry
;; Example: a `w t' capture receives DATE=<today> below the CAPTURED heading,
;; making it sortable and reviewable without requiring manual bookkeeping.
(defun mc/org-capture-add-date-h ()
  "Add DATE property to the captured item."
  (interactive)
  (org-set-property "DATE" (format-time-string +org-capture-timestamp-format)))
(add-hook! 'org-capture-mode-hook #'mc/org-capture-add-date-h)

;; Code based mostly on file+headline part of org-capture-set-target-location
;; Look for a headline that matches a custom format. If it's found then insert
;; it; otherwise position the cursor at the end of the subtree.
;; Journal, idea, and work-log captures use this to reuse one dated heading per
;; day instead of creating a new top-level heading for every quick entry.
(defun mc/org-capture-find-time-heading (time-string)
  "Find or create the headline described by TIME-STRING."
  (let ((search-for (format-time-string time-string)))
    (goto-char (point-min))
    (unless (derived-mode-p 'org-mode)
      (error "Target buffer \"%s\" must use Org mode" (current-buffer)))

    (if (re-search-forward
         (format org-complex-heading-regexp-format (regexp-quote search-for))
         nil t)
        (goto-char (line-beginning-position))

      ;; Headline doesn't exist yet, create one and set the base properties.
      (goto-char (point-min))
      (or (bolp) (insert "\n"))
      (insert "* " search-for "\n")
      (beginning-of-line 0)

      ;; Match Org Journal's base properties so captures remain searchable.
      (org-set-property "CREATED" (format-time-string "%Y%m%d"))
      (org-set-property "DATE" (format-time-string "<%F %a>")))

    (org-end-of-subtree)))

(after! org (setq org-capture-templates
                  (doct '(
                          ;; Parking Lot for notes to be processed later into
                          ;; "external brain"
                          ("Note" :keys "n"
                           :file +org-capture-notes-file
                           :headline "INBOX"
                           :template "* %?\n%i\n%a"
                           :prepend t)

                          ;; Parking Lot for ideas that quickly pop to mind and
                          ;; have to be captured somewhere before it fade-away
                          ("Ideas (Parking Lot)" :keys "i"
                           :type plain
                           :file +org-capture-ideas-file
                           :function (lambda ()
                                       (mc/org-capture-find-time-heading
                                        org-journal-date-format))
                           :template "** \n%i%?"
                           :prepend t)

                          ;; Create entries similar to Org Journal from Org
                          ;; Capture
                          ("Journal" :keys "j"
                           :type plain
                           :file +org-capture-journal-file
                           ;; Matches the defined format for Org Journal
                           :function (lambda ()
                                       (mc/org-capture-find-time-heading
                                        org-journal-date-format))
                           :template "** %(format-time-string \"%H:%M\")\n%?"
                           :prepend nil)

                          ;; Capture tasks TODO later
                          ("To-Do" :keys "t"
                           :file +org-capture-personal-todo-file
                           :warn nil ; No, I'm not missing the leading '*'
                           :headline "PARKING LOT"
                           :template "** MAYBE %?\n%^{PROJECT}p"
                           :prepend t)

                          ;; Work related templates are similar to the personal
                          ;; ones, but commonly stored in either "work.org" file
                          ;; or a "work" dir (as prefix)
                          ("Work" :keys "w"
                           :children (("Ideas (Parking Lot)" :keys "i"
                                       :type plain
                                       :file +org-capture-work-ideas-file
                                       :function (lambda ()
                                                   (mc/org-capture-find-time-heading
                                                    org-journal-date-format))
                                       :template "** \n%i%?"
                                       :prepend t)
                                      ("Note" :keys "n"
                                       :file +org-capture-work-notes-file
                                       :headline "INBOX"
                                       :template "* %?\n%i\n%a"
                                       :prepend t)
                                      ("To-Do" :keys "t"
                                       :file +org-capture-work-todo-file
                                       :warn nil ; Not missing here as well
                                       :headline "CAPTURED"
                                       :template "** MAYBE %?\n%^{PROJECT}p"
                                       :prepend t)
                                      ;; Work logs are entries similar to journal but for
                                      ;; tasks complete at work (to share in the stand-up
                                      ;; daily)
                                      ("Log" :keys "l"
                                       :type plain
                                       :file +org-capture-logs-file
                                       ;; Matches the defined format for Org Journal
                                       :function (lambda ()
                                                   (mc/org-capture-find-time-heading
                                                    org-journal-date-format))
                                       :template "** %(format-time-string \"%H:%M\")\n%?"
                                       :prepend nil)))))))
;; }} Org mode and the gang
