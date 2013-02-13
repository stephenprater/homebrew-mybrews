require File.join(File.dirname(__FILE__), 'abstract-php-prater')

class Php55 < AbstractPhp
  init
  homepage 'http://github.com/php/php-src'
  url 'https://github.com/php/php-src.git'
  version '5.5'

  head 'https://github.com/php/php-src.git', :branch => 'PHP-5.5'

  def install_args
    args = super
    args << "--with-homebrew-openssl" if MacOS.version == :leopard
    args + [
      "--enable-debug",
      "--enable-maintainer-zts",
      "--enable-zend-signals",
      "--enable-dtrace",
    ]
  end

  def php_version
    5.5
  end

  def php_version_path
    55
  end

end
