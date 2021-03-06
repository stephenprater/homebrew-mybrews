require 'formula'

class PraterMacvim < Formula
  homepage 'http://code.google.com/p/macvim/'
  url 'https://github.com/b4winckler/macvim/tarball/snapshot-64'

  head 'https://github.com/b4winckler/macvim.git', :branch => 'master'

  option "custom-icons", "Try to generate custom document icons"
  option "override-system-vim", "Override system vim"

  def options
  [
    ["--with-cscope", "Build with Cscope support."],
    ["--with-lua", "Build with Lua scripting support."],
    ["--override-system-vim", "Override system vim."],
    ["--with-lua", "Build with Lua scripting support."],
    ["--with-brew-python", "Build with homebrew's python instead of system"],
    ["--with-brew-ruby", "Build with homebrew's (or rvms) python instead of system"]
  ]
  end

  depends_on 'cscope' if ARGV.include? '--with-cscope'
  depends_on 'lua' if ARGV.include? '--with-lua'

  def install
    # Set ARCHFLAGS so the Python app (with C extension) that is
    # used to create the custom icons will not try to compile in
    # PPC support (which isn't needed in Homebrew-supported systems.)
    arch = MacOS.prefer_64_bit? ? 'x86_64' : 'i386'
    ENV['ARCHFLAGS'] = "-arch #{arch}"

    args = %W[
      --with-features=huge
      --with-tlib=ncurses
      --enable-multibyte
      --with-macarchs=#{arch}
      --enable-perlinterp
      --enable-pythoninterp
      --enable-rubyinterp
      --enable-tclinterp
    ]

    args << "--enable-cscope" if ARGV.include? "--with-cscope"

    if ARGV.include? "--with-lua"
      args << "--enable-luainterp"
      args << "--with-lua-prefix=#{HOMEBREW_PREFIX}"
    end

    if ARGV.include? "--with-brew-ruby"
      args << "--enable-rubyinterp"
      args << "--with-ruby-command=#{`which ruby`}"
    end

    if ARGV.include? "--with-brew-python"
      args << "--enable-pythoninterp"
      args << "--with-python-command=#{`which python`}"
    end
    
    system "./configure", *args

    # Building custom icons fails for many users, so off by default.
    unless build.include? "custom-icons"
      inreplace "src/MacVim/icons/Makefile", "$(MAKE) -C makeicns", ""
      inreplace "src/MacVim/icons/make_icons.py", "dont_create = False", "dont_create = True"
    end

    # Reference: https://github.com/b4winckler/macvim/wiki/building
    cd 'src/MacVim/icons' do
      system "make getenvy"
    end

    system "make"

    prefix.install "src/MacVim/build/Release/MacVim.app"
    inreplace "src/MacVim/mvim", /^# VIM_APP_DIR=\/Applications$/,
                                 "VIM_APP_DIR=#{prefix}"
    bin.install "src/MacVim/mvim"

    # Create MacVim vimdiff, view, ex equivalents
    executables = %w[mvimdiff mview mvimex]
    executables += %w[vi vim vimdiff view vimex] if build.include? "override-system-vim"
    executables.each {|f| ln_s bin+'mvim', bin+f}
  end

  def caveats; <<-EOS.undent
    MacVim.app installed to:
      #{prefix}

    To link the application to a normal Mac OS X location:
        brew linkapps
    or:
        ln -s #{prefix}/MacVim.app /Applications
    EOS
  end
end
