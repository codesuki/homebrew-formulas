class EmacsOsx < Formula
    desc "GNU Emacs text editor"
    homepage "https://www.gnu.org/software/emacs/"
    url "https://ftp.gnu.org/gnu/emacs/emacs-26.1.tar.xz"
    mirror "https://ftpmirror.gnu.org/emacs/emacs-26.1.tar.xz"
    sha256 "1cf4fc240cd77c25309d15e18593789c8dbfba5c2b44d8f77c886542300fd32c"
    head "https://github.com/emacs-mirror/emacs.git", :shallow => true

    depends_on "gnutls"
    depends_on "imagemagick@7"
    depends_on "libpng"
    depends_on "jpeg"
    depends_on "librsvg"
    depends_on "little-cms2"
    depends_on "jansson"

    resource "spacemacs-icon" do
      url "https://github.com/nashamri/spacemacs-logo/blob/master/spacemacs.icns?raw=true"
      sha256 "b3db8b7cfa4bc5bce24bc4dc1ede3b752c7186c7b54c09994eab5ec4eaa48900"
    end

    if build.head?
      depends_on "autoconf" => :build
      depends_on "pkg-config" => :build
      depends_on "jansson"
      depends_on "gmp"
      depends_on "texinfo"
      depends_on "harfbuzz"
    end

    def install
      args = %W[
            --prefix=#{prefix}
            --disable-dependency-tracking
            --disable-silent-rules
            --with-ns
            --with-module
            --with-json
            --with-gnutls
            --with-imagemagick
            --with-rsvg
            --with-harfbuzz
        ]
      if build.head?
        system "./autogen.sh"
      end
      system "./configure", *args
      system "make"
      system "make", "install"
      icons_dir = buildpath/"nextstep/Emacs.app/Contents/Resources"
      resource("spacemacs-icon").stage do
        icons_dir.install "spacemacs.icns" => "Emacs.icns"
      end
      prefix.install "nextstep/Emacs.app"
      if (bin/"emacs").exist?
        (bin/"emacs").unlink
      end
      (bin/"emacs").write <<~EOS
            #!/bin/bash
            exec #{prefix}/Emacs.app/Contents/MacOS/Emacs "$@"
        EOS
      #bin.install_symlink prefix/"Emacs.app/Contents/MacOS/Emacs" => "emacs"
    end

    def caveats
      target_dir = File.expand_path("~/Applications")
      s = <<-EOS
Run the following script to link the app into ~/Applications.
/usr/bin/osascript << EOF
tell application "Finder"
    set macSrcPath to POSIX file "#{prefix/"Emacs.app"}" as text
    set macDestPath to POSIX file "#{target_dir}" as text
    make new alias file to file macSrcPath at folder macDestPath
end tell
EOF
        EOS
      s
    end

    test do
      assert_equal "4", shell_output("#{bin}/emacs --batch --eval=\"(print (+ 2 2))\"").strip
    end
end
