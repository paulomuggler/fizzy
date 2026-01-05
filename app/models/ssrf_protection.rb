module SsrfProtection
  extend self

  DNS_RESOLUTION_TIMEOUT = 2

  DNS_NAMESERVERS = %w[
    1.1.1.1
    8.8.8.8
  ]

  DISALLOWED_IP_RANGES = [
    IPAddr.new("0.0.0.0/8"),     # "This" network (RFC1700)
    IPAddr.new("100.64.0.0/10"), # Carrier-grade NAT (RFC6598)
    IPAddr.new("198.18.0.0/15")  # Benchmark testing (RFC2544)
  ].freeze

  # Allow .localhost domains in development for Docker service-to-service webhooks
  DEVELOPMENT_ALLOWED_SUFFIXES = %w[.localhost].freeze

  def resolve_public_ip(hostname)
    # Allow .localhost domains when ALLOW_LOCALHOST_WEBHOOKS is set (Docker development)
    if allow_localhost_webhooks? && development_allowed_host?(hostname)
      return resolve_local_ip(hostname)
    end

    ip_addresses = resolve_dns(hostname)
    public_ips = ip_addresses.reject { |ip| private_address?(ip) }
    public_ips.sort_by { |ipaddr| ipaddr.ipv4? ? 0 : 1 }.first&.to_s
  end

  def allow_localhost_webhooks?
    ENV["ALLOW_LOCALHOST_WEBHOOKS"].present?
  end

  def private_address?(ip)
    ip = IPAddr.new(ip.to_s) unless ip.is_a?(IPAddr)
    ip.private? || ip.loopback? || ip.link_local? || ip.ipv4_mapped? || in_disallowed_range?(ip)
  end

  private
    def resolve_dns(hostname)
      ip_addresses = []

      Resolv::DNS.open(nameserver: DNS_NAMESERVERS, timeouts: DNS_RESOLUTION_TIMEOUT) do |dns|
        dns.each_address(hostname) do |ip_address|
          ip_addresses << IPAddr.new(ip_address.to_s)
        end
      end

      ip_addresses
    end

    def in_disallowed_range?(ip)
      DISALLOWED_IP_RANGES.any? { |range| range.include?(ip) }
    end

    def development_allowed_host?(hostname)
      DEVELOPMENT_ALLOWED_SUFFIXES.any? { |suffix| hostname.end_with?(suffix) }
    end

    def resolve_local_ip(hostname)
      # Resolve using system DNS (Docker resolver) for local development
      Resolv.getaddress(hostname)
    rescue Resolv::ResolvError
      nil
    end
end
