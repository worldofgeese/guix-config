(define-module (worldofguix packages emacs-exwm-next)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system emacs)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages texinfo)
  #:use-module ((guix licenses) #:prefix license:))

(define-public emacs-exwm-next
  (package
    (inherit emacs-exwm)
    (name "emacs-exwm-next")
    (arguments
     `(#:emacs ,emacs
       #:phases
       (modify-phases %standard-phases
         (add-after 'build 'install-xsession
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (xsessions (string-append out "/share/xsessions"))
                    (bin (string-append out "/bin"))
                    (exwm-executable (string-append bin "/exwm")))
               ;; Add a .desktop file to xsessions
               (mkdir-p xsessions)
               (mkdir-p bin)
               (make-desktop-entry-file
                (string-append xsessions "/exwm.desktop")
                #:name ,name
                #:exec exwm-executable
                #:try-exec exwm-executable)
               ;; Add a shell wrapper to bin
               (with-output-to-file exwm-executable
                 (lambda _
                   (format #t "#!~a ~@
                     ~a +SI:localuser:$USER ~@
                     exec ~a --exit-with-session ~a \"$@\" --eval '~s' ~%"
                           (search-input-file inputs "/bin/sh")
                           (search-input-file inputs "/bin/xhost")
                           (search-input-file inputs "/bin/dbus-launch")
                           (search-input-file inputs "/bin/emacs")
                           '(cond
                             ((file-exists-p "~/.exwm")
                              (load-file "~/.exwm"))
                             ((not (featurep 'exwm))
                              (require 'exwm)
                              (require 'exwm-config)
                              (exwm-config-default)
                              (message (concat "exwm configuration not found. "
                                               "Falling back to default configuration...")))))))
               (chmod exwm-executable #o555)
               #t))))))
    (home-page "https://github.com/ch11ng/exwm")
    (description
     "EXWM is a full-featured tiling X window manager for Emacs built on top
of XELB.")
    (license license:gpl3+)))

emacs-exwm-next
