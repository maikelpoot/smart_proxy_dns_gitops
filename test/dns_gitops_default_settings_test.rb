require 'test_helper'
require 'smart_proxy_dns_gitops/dns_gitops_configuration'
require 'smart_proxy_dns_gitops/dns_gitops_plugin'

class DnsGitopsDefaultSettingsTest < Test::Unit::TestCase
  def test_default_settings
    Proxy::Dns::Gitops::Plugin.load_test_settings({})
    assert_equal "default_value", Proxy::Dns::Gitops::Plugin.settings.required_setting
    assert_equal "/must/exist", Proxy::Dns::Gitops::Plugin.settings.required_path
  end
end
