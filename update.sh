#!/bin/bash
gem install git
gem build smart_proxy_dns_gitops.gemspec && gem install smart_proxy_dns_gitops-0.1.gem && systemctl restart foreman-proxy.service
