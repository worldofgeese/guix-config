;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules (gnu home)
             (gnu packages)
             (gnu packages gnupg)
             (gnu services)
             (guix gexp)
             (gnu home services)
             (gnu home services ssh)
             (gnu home services gnupg)
             (gnu home services desktop)
             (worldofguix services pipewire)
             (rde features)
             (rde features linux)
             (gnu home services shells))

(define my-rde-services
  (home-environment-services
   (rde-config-home-environment
    (rde-config
     (features
      (list (feature-pipewire)))))))

(home-environment
 ;; Below is the list of packages that will show up in your
 ;; Home profile, under ~/.guix-home/profile.
 (packages (specifications->packages
            (list "git" 
                  "fd"
                  "openssh"
                  "direnv"
                  "openssl"
                  "curl"
                  "racket"
                  "flatpak"
                  "xdg-utils" ;; Set default browser with xdg-settings set default-web-browser org.mozilla.firefox.desktop
                  "ncurses"
                  "gnome-tweaks"
                  "ripgrep"
                  ;; tools for gooseandquill.blog
                  "tidy-html"
                  "texlive-scheme-basic"
                  "make"
                  "python"
                  ;; end tools for gooseandquill.blog
                  "emacs-guix"
                  "emacs-all-the-icons"
                  "steam"
                  "firefox-wayland"
                  "neovim"
                  "font-jetbrains-mono"
                  "font-google-noto" ;; display symbols normally in Doom Emacs
                  "podman"
                  "kind"
                  "pinentry-gnome3"
                  "rsync"
                  ;; tools for EXWM
                  "gtk+:bin" ;; provides gtk-launch required for counsel-linux-app
                  "brightnessctl"
                  "scrot"
                  "slock"
                  "pasystray"
                  "dunst"
                  "network-manager-applet"
                  "emacs-pulseaudio-control"
                  "emacs-desktop-environment"
                  "emacs-windower"
                  "emacs-ace-window"
                  "emacs-vterm"
                  "pavucontrol" ;; provides pactl for pulseaudio-control
                  "playerctl"
                  "blueman"
                  "redshift"
                  ;; tools for Guix hacking
                  "podman"
                  "iptables"
                  "kind"
                  "guile-picture-language"
                  "ardour"
                  )))


 ;; Below is the list of Home services.  To search for available
 ;; services, run 'guix home search KEYWORD' in a terminal.
 (services
  (append
   (list
    (my-rde-services)
    (service home-dbus-service-type)
    (service home-pipewire-service-type)
    (service home-bash-service-type
             (home-bash-configuration
              (bashrc
               (list (plain-file "bashrc"
                                 (string-append
                                  "case $- in\n"
                                  "  *i*) ;;\n"
                                  "    *) return;;\n"
                                  "esac\n"
                                  "export OSH='/home/worldofgeese/.oh-my-bash'\n"
                                  "OSH_THEME=\"font\"\n"
                                  "OMB_USE_SUDO=true\n"
                                  "completions=(\n"
                                  "  git\n"
                                  "  composer\n"
                                  "  ssh\n"
                                  ")\n"
                                  "aliases=(\n"
                                  "  general\n"
                                  ")\n"
                                  "plugins=(\n"
                                  "  git\n"
                                  "  bashmarks\n"
                                  "  kubectl\n"
                                  "  bu\n"
                                  "  battery\n"
                                  "  zoxide\n"
                                  "  sudo\n"
                                  ")\n"
                                  "source \"$OSH\"/oh-my-bash.sh\n"
                                  "export GPG_TTY=$(tty)\n"
                                  "source ~/.local/share/blesh/ble.sh\n"
                                  "source ~/.bash-preexec.sh\n"
                                  "eval \"$(atuin init bash)\"\n"
                                  "eval \"$(direnv hook bash)\"\n"
                                  "gpg-connect-agent updatestartuptty /bye"))))))
    (service home-openssh-service-type
             (home-openssh-configuration
              (hosts
               (list (openssh-host (name "mother")
                                   (host-name "192.168.99.200")
                                   (user "taohansen")
                                   (port 2235)
                                   (extra-content "controlmaster yes\ncontrolpersist 10m"))))))
    (service home-gpg-agent-service-type
             (home-gpg-agent-configuration
              (ssh-support? #t) ;; This flag doesn't appear to do anything
              (default-cache-ttl 60480000)
              (default-cache-ttl-ssh 60480000)
              (max-cache-ttl 60480000)
              (max-cache-ttl-ssh 60480000)
              (pinentry-program
               (file-append pinentry-gnome3 "/bin/pinentry-gnome3"))
              (extra-content "enable-ssh-support\n")))

    (simple-service 'custom-profile
                    home-shell-profile-service-type
                    (list (plain-file "profile" "source ~/.nix-profile/etc/profile.d/nix.sh")))

    (simple-service 'gnome-keyring-config
                    home-xdg-configuration-files-service-type
                    (list `("autostart/gnome-keyring-ssh.desktop"
                            ,(plain-file "gnome-keyring-file.txt"
                                         "[Desktop Entry]\nType=Application\nName=SSH Key Agent\nX-GNOME-Autostart-enabled=false\n"))))

    (simple-service 'nix-config
                    home-xdg-configuration-files-service-type
                    (list `("nix/nix.conf"
                            ,(plain-file "nix-file.txt"
                                         (string-append
                                          "extra-trusted-substituters = https://cache.floxdev.com https://devenv.cachix.org https://nixpkgs-python.cachix.org\n"
                                          "extra-trusted-public-keys = flox-store-public-0:8c/B+kjIaQ+BloCmNkRUKwaVPFWkriSAd0JJvuDu4F0= devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU=\n"
                                          "experimental-features = nix-command flakes")))))

    (simple-service 'additional-env-vars-service
                    home-environment-variables-service-type
                    `(("PATH" . "$HOME/.local/bin:$HOME/.config/emacs/bin:$HOME/.krew/bin:$PATH")
                      ("XDG_DATA_DIRS" . "$XDG_DATA_DIRS:$HOME/.local/share/flatpak/exports/share:$HOME/.nix-profile/share:$HOME/.local/share/fonts")
                      ("VISUAL" . "emacsclient")
                      ("BROWSER" . "firefox")
                      ("_JAVA_AWT_WM_NONREPARENTING" . "1")
                      ("npm_config_prefix" . "$HOME/.local")
                      ("EDITOR" . "emacsclient")))))))
