    (define-module (worldofguix packages kind)
      #:use-module (guix packages)
      #:use-module (guix download)
      #:use-module ((guix licenses) :prefix license:)
      #:use-module (guix gexp)
      #:use-module (guix build-system copy))

    (define-public kind
      (package
       (name "kind")
       (version "0.20.0")
       (source (origin
                 (method url-fetch)
                 (uri (string-append "https://kind.sigs.k8s.io/dl/v" version "/kind-linux-amd64"))
                  (sha256
                   (base32
                    "1v9x953a5n0l3kz78wm29yh11vz56nmlvhi7xzcjscyksq9p4fji"))))
        (build-system copy-build-system)
        (arguments
         (list
          #:substitutable? #f
          #:install-plan
          #~'(("kind" "bin/"))
          #:phases
          #~(modify-phases %standard-phases
              (replace 'unpack
                (lambda _
                  (copy-file #$source "./kind")
                  (chmod "kind" #o644)))
              (add-before 'install 'chmod
                (lambda _
                  (chmod "kind" #o555))))))
        (home-page "https://kind.sigs.k8s.io")
        (synopsis "kind is a tool for running local Kubernetes clusters using Docker container “nodes”.")
        (description "kind was primarily designed for testing Kubernetes itself, but may be used for local development or CI.")
        (license license:asl2.0)))

    kind
