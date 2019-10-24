require 'smart_proxy_dns_gitops/dns_gitops_version'
require 'smart_proxy_dns_gitops/dns_gitops_configuration'

module Proxy::Dns::Gitops
  class Plugin < ::Proxy::Provider
    plugin :dns_gitops, ::Proxy::Dns::Gitops::VERSION

    # Settings listed under default_settings are required.
    # An exception will be raised if they are initialized with nil values.
    # Settings not listed under default_settings are considered optional and by default have nil value.
    default_settings :zones => [], :git_path => '/tmp', :git_zones_path => '/', :git_bin_path => '/bin/git', :git_push => false, :git_remote => 'origin'

    requires :dns, '>= 1.15'

    # Verifies that a file exists and is readable.
    # Uninitialized optional settings will not trigger validation errors.
    validate_readable :git_path

    # Loads plugin files and dependencies
    load_classes ::Proxy::Dns::Gitops::PluginConfiguration
    # Loads plugin dependency injection wirings
    load_dependency_injection_wirings ::Proxy::Dns::Gitops::PluginConfiguration
  end
end
