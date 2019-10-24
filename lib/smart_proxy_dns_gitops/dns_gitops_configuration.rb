module ::Proxy::Dns::Gitops
  class PluginConfiguration
    def load_classes
      require 'dns_common/dns_common'
      require 'smart_proxy_dns_gitops/dns_gitops_main'
    end

    def load_dependency_injection_wirings(container_instance, settings)
      container_instance.dependency :dns_provider, (lambda do
        ::Proxy::Dns::Gitops::Record.new(
            settings[:zones],
            settings[:dns_ttl],
            settings[:git_path],
            settings[:git_zones_path],
            settings[:git_bin_path],
            settings[:git_ssh_path],
            settings[:git_lockfile],
            settings[:git_push],
            settings[:git_remote])
      end)
    end
  end
end
