require File.expand_path('../lib/smart_proxy_dns_gitops/dns_gitops_version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'smart_proxy_dns_gitops'
  s.version     = Proxy::Dns::Gitops::VERSION
  s.date        = Date.today.to_s
  s.license     = 'GPL-3.0'
  s.authors     = ['Maikel Poot']
  s.email       = ['maikel.poot@topicus.nl']
  s.homepage    = 'https://github.com/theforeman/smart_proxy_dns_gitops'

  s.summary     = "GitOps DNS provider plugin for Foreman's smart proxy"
  s.description = "GitOps DNS provider plugin for Foreman's smart proxy"

  s.files       = Dir['{config,lib,bundler.d}/**/*'] + ['README.md', 'LICENSE']
  s.test_files  = Dir['test/**/*']

  s.add_development_dependency('rake')
  s.add_development_dependency('mocha')
  s.add_development_dependency('test-unit')
end
