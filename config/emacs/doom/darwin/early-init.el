;;; early-init.el --- Darwin runtime environment -*- lexical-binding: t; no-byte-compile: t -*-

(with-temp-buffer
  (when (eq 0
            (call-process
             "/bin/sh" nil (list (current-buffer) nil) nil
             "@environmentFile@"))
    (dolist (entry (split-string (buffer-string) "\0" t))
      (when (string-match "\\`\\([^=]+\\)=\\(.*\\)\\'" entry)
        (let ((name (match-string 1 entry))
              (value (match-string 2 entry)))
          (unless (or (member name '("_" "PWD" "OLDPWD" "SHLVL" "GPG_TTY"))
                      (string-match-p "\\`__HM_" name))
            (setenv name value)))))))

(let* ((homebrew-bin "@homebrewBin@")
       (current-path (getenv "PATH"))
       (path-directories
        (delete-dups
         (mapcar #'directory-file-name
                 (append (and current-path
                              (split-string current-path ":" t))
                         exec-path
                         (list homebrew-bin "/usr/bin" "/bin"))))))
  (setq exec-path path-directories)
  (setenv "PATH" (mapconcat #'identity path-directories ":"))
  (let* ((gcc-driver (expand-file-name "gcc-@gccMajorVersion@" homebrew-bin))
         (gcc-runtime
          (ignore-errors
            (car (process-lines gcc-driver "-print-file-name=libemutls_w.a")))))
    (when (and gcc-runtime (file-readable-p gcc-runtime))
      (let ((current-library-path (getenv "LIBRARY_PATH")))
        (setenv "LIBRARY_PATH"
                (concat (file-name-directory gcc-runtime)
                        (if current-library-path
                            (concat ":" current-library-path)
                          "")))))))

(load (expand-file-name "early-init.doom.el"
                        (file-name-directory
                         (or load-file-name buffer-file-name)))
      nil nil)
