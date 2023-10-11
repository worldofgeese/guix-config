;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu)
             (gnu services shepherd)
             (nongnu packages linux)
             (gnu packages networking)
             (worldofguix packages emacs-exwm-next)
             (nongnu system linux-initrd)
             ;; (saml services tailscale)
             ;; (saml packages tailscale)
             (gnu packages gnome))
(use-service-modules desktop networking xorg dbus)
(use-package-modules package-management security-token)

(define %my-services
  ;; My very own list of services.
  ;; Enables Wayland for GNOME and adds a binary server for Nonguix.
  (modify-services %desktop-services
    (guix-service-type config => (guix-configuration
                                  (inherit config)
                                  (substitute-urls
                                   (append (list "https://substitutes.nonguix.org")
                                           %default-substitute-urls))
                                  (authorized-keys
                                   (append (list (plain-file "non-guix.pub" "
                                (public-key
                                 (ecc
                                  (curve Ed25519)
                                  (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)
                                  )
                                 )"))
                                           %default-authorized-guix-keys))))
    (dbus-root-service-type config =>
                            (dbus-configuration
                             (inherit config)
                             (verbose? #f)
                             (services (list gdm))))
    (gdm-service-type config =>
                      (gdm-configuration
                       (inherit config)
                       (wayland? #t)))))

(define username "worldofgeese")

(operating-system
  (kernel linux)
  (initrd microcode-initrd)
  (kernel-arguments (cons "i915.enable_psr=0" %default-kernel-arguments)) ;; stop lag in EXWM
  (firmware (list linux-firmware))
  (locale "en_US.utf8")
  (timezone "Europe/Copenhagen")
  (keyboard-layout (keyboard-layout "us" "altgr-intl"))
  (host-name "mahakala")

  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                 (name username)
                 (group "users")
                 (home-directory (string-append "/home/" username))
                 (supplementary-groups '("wheel" "netdev" "audio" "video" "plugdev")))
                %base-user-accounts))


  ;; Don't ask for password to elevate privileges
  (sudoers-file (plain-file "sudoers" "\
root ALL=(ALL) ALL
%wheel ALL=NOPASSWD: ALL\n"))

  ;; Packages installed system-wide.  Users can also install packages
  ;; under their own account: use 'guix search KEYWORD' to search
  ;; for packages and 'guix install PACKAGE' to install a package.
  (packages (append (specifications->packages (list
                                               "emacs"
                                               "emacs-exwm-next"
                                               ;; Allows Flatpak applications to e.g. open links in the default browser.
                                               "xdg-dbus-proxy"
                                               "xdg-desktop-portal-gtk"
                                               "emacs-desktop-environment"
                                               ;; "tailscale"
                                               "nss-certs"))
                    %base-packages))


  (services
   (cons*
    (udev-rules-service 'fido2 libfido2 #:groups '("plugdev"))
    (service gnome-desktop-service-type)
    (service bluetooth-service-type)
    ;; (service tailscaled-service-type)
    (set-xorg-configuration
     (xorg-configuration
      (keyboard-layout keyboard-layout)
      (extra-config (list
                     "Section \"InputClass\"
                                      Identifier \"TouchPad\"
                                      MatchIsTouchpad \"on\"
                                      Driver \"libinput\"
                                      Option \"Tapping\" \"on\"
                                      Option \"NaturalScrolling\" \"true\"
                                      Option \"DisableWhileTyping\" \"on\"
                              EndSection"))))

    ;; for Blueman applet in EXWM
    (simple-service 'blueman dbus-root-service-type (list blueman))

    ;; Rootless Podman requires the next 6 services
    ;; we're using the iptables service purely to make its resources available to minikube and kind
    (service iptables-service-type
             (iptables-configuration
              (ipv4-rules (plain-file "iptables.rules" "*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
COMMIT
"))
              (ipv6-rules (plain-file "ip6tables.rules" "*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
COMMIT
"))))
    (simple-service 'cgroup-setup shepherd-root-service-type
                    (list
                     (shepherd-service
                      (provision '(cgroup-setup))
                      (documentation "Configure cgroup on login.")
                      (one-shot? #t)
                      (start #~(make-forkexec-constructor
                                (list "/bin/sh" "-c"
                                      (string-append
                                       "echo '+cpu +cpuset +memory +pids' > /sys/fs/cgroup/cgroup.subtree_control && "
                                       "g=users && chgrp -R $g /sys/fs/cgroup/ && "
                                       "u=" '#$username " && chown -R $u: /sys/fs/cgroup"))))
                      (stop #~(make-kill-destructor)))))
	(simple-service 'etc-subuid etc-service-type
	     	        (list `("subuid" ,(plain-file "subuid" (string-append "root:0:65536\n" username ":100000:65536\n")))))
	(simple-service 'etc-subgid etc-service-type
	     	        (list `("subgid" ,(plain-file "subgid" (string-append "root:0:65536\n" username ":100000:65536\n")))))
    (service pam-limits-service-type
             (list
              (pam-limits-entry "*" 'both 'nofile 100000)))
    (simple-service 'etc-container-policy etc-service-type
	     	        (list `("containers/policy.json", (plain-file "policy.json" "{\"default\": [{\"type\": \"insecureAcceptAnything\"}]}"))))
    %my-services))


  (bootloader (bootloader-configuration
               (bootloader grub-efi-bootloader)
               (targets (list "/boot/efi"))
               (keyboard-layout keyboard-layout)))
  (mapped-devices (list (mapped-device
                         (source (uuid
                                  "c667edf6-fb07-4ce4-bd62-060d7b835cd3"))
                         (target "cryptroot")
                         (type luks-device-mapping))))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "2C9C-4D34"
                                       'fat32))
                         (type "vfat"))
                       (file-system
                         (mount-point "/")
                         (device "/dev/mapper/cryptroot")
                         (type "ext4")
                         (dependencies mapped-devices)) %base-file-systems)))
