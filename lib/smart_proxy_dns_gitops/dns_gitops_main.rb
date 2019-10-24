require 'dns_common/dns_common'
require 'smart_proxy_dns_gitops/dns_gitops_configuration'
require 'yaml'
require 'git'

module Proxy::Dns::Gitops
  class Record < ::Proxy::Dns::Record
    include Proxy::Log

    attr_reader :git_bin_path, :git_ssh_path, :git_lockfile

    def initialize(zones, dns_ttl, git_path, git_bin_path, git_ssh_path, git_lockfile, git_push, git_remote)
      @zones = zones.sort_by { |zone| zone.length } # never nil
      @git_path = git_path # file exists and is readable

      @git_lockfile = git_lockfile
      @git_lockfile = "#{@git_path}/.lockfile" unless @git_lockfile
      @git_push = false
      @git_push = true if git_push
      @git_remote = git_remote

      logger.debug("Lockfile set to: #{@git_lockfile}")

      Git.configure do |config|
        config.binary_path = git_bin_path if git_bin_path
        config.git_ssh = git_ssh_path if git_ssh_path
      end

      logger.debug("Git bin path: #{@git_bin_path}") if git_bin_path
      logger.debug("Git ssh path: #{@git_bin_path}") if git_ssh_path

      # Common settings can be defined by the main plugin, it's ok to use them locally.
      # Please note that providers must not rely on settings defined by other providers or plugins they are not related to.
      super('localhost', dns_ttl)
    end

    def split_name(name)

      return name, '' if @zones.include?(name)

      @zones.each do |zone|
        return zone, name[0, name.length - zone.length - 1] if name.end_with?(zone)
      end

      raise Proxy::Dns::Error.new("#{name} not part of enabled zones #{@zones}")

    end

    def load_file(zone)
      records = {}
      raise "Failed to load: #{@git_path}/#{zone}.yaml. File does not exists or is not readable" unless File.readable?("#{@git_path}/#{zone}.yaml")
      records = YAML.load(File.read("#{@git_path}/#{zone}.yaml")) if File.readable?("#{@git_path}/#{zone}.yaml")
      records = {} unless records

      records #return
    end

    def write_file(zone, records)

      logger.info("trying to save: #{@git_path}/#{zone}.yaml")
      File.open("#{@git_path}/#{zone}.yaml", "w") { |file| file.write(records.to_yaml) }

    end

    def commit_file(zone, message)
      original_stdout = $stdout  # capture previous value of $stdout
      original_stderr = $stderr  # capture previous value of $stdout
      $stdout = StringIO.new     # assign a string buffer to $stdout

      @git.add("#{@git_path}/#{zone}.yaml")
      @git.commit("Foreman: #{message}")
      logger.info("Files Committed")
      @git.push(@git.remote(@git_remote)) if @git_push
      logger.info("Files Pushed") if @git_push
    rescue

      no_changes = $!.message.include?"nothing to commit, working directory clean"
      no_changes_untracked = $!.message.include?"nothing added to commit but untracked files present"

      logger.info("nothing to commit") if no_changes || no_changes_untracked
      raise unless no_changes || no_changes_untracked

    ensure

      $stdout = original_stdout
      $stderr = original_stderr
    end

    def pull_repo()

      original_stdout = $stdout  # capture previous value of $stdout
      original_stderr = $stderr  # capture previous value of $stdout
      $stdout = StringIO.new     # assign a string buffer to $stdout

      @git.pull(@git.remote(@git_remote))
      logger.info("Checkout updated")

    rescue

      no_changes = $!.message.include?"nothing to commit, working directory clean"

      logger.info("nothing to commit, working directory clean") if no_changes
      raise unless no_changes

    ensure

      $stdout = original_stdout
      $stderr = original_stderr
    end


    def do_create(name, value, type)

      lock_workspace()

      logger.info("trying to add #{name}, #{type}, #{value}")

      zone, name = split_name(name)
      value += '.' if ['PTR', 'CNAME'].include?(type)
      records = load_file(zone)

      # Create template record
      new_record = {}
      new_record['type'] = type
      new_record['value'] = value
      new_record['ttl'] = ttl

      # Create a hash key if not exists.
      records[name] = [] unless records.include?(name)

      found = false

      records[name].each_with_index do |record, index|
        # Check if type is allready present
        if record['type'] == new_record['type']
          #record = new_record
          record['value'] = new_record['value']
          record['ttl'] = new_record['ttl']
          record.delete('values') if record.key?('values')
          found = true
        end

        if record['type'] == 'CNAME' && ['A', 'AAAA'].include?(new_record['type']) || new_record['type'] == 'CNAME' && ['A', 'AAAA'].include?(record['type'])
          records[name][index] = []
        end
      end

      records[name].reject! { |c| c.empty? }
      # if record is not found, add the template
      records[name] << new_record unless found

      write_file(zone, records)
      commit_file(zone, "Updated #{type} record: #{name}.#{zone} ")

      ensure
        unlock_workspace()

    end

    def do_remove(name, type)
      lock_workspace()

      zone, name = split_name(name)

      records = load_file(zone)
      records.delete(name) if records.key?(name)

      write_file(zone, records)
      commit_file(zone, "Removed #{type} record: #{name}.#{zone} ")

    ensure
      unlock_workspace()

    end

    def lock_workspace ()

      logger.info('Checking workspace')
      timer = 0
      while File.exists?(@git_lockfile)
        logger.warn("lock file found, waiting for it to leave (#{timer})")
        timer += 1
        sleep(1)
        if timer > 10
            raise Proxy::Dns::Error.new("lock file present for more than 10 seconds, skipping #{@git_path}")
        end
      end

      logger.info('Locking workspace')
      File.open(@git_lockfile, "w") { |file| file.write('locked') }

      # Proxy::Dns::Error.new()
      begin
        @git = Git.open(@git_path, :log => false)
        @git.reset_hard()
        logger.info('Git workspace opened')
      rescue ArgumentError
        no_git = $!.message.include?"path does not exist"
        raise Proxy::Dns::Error.new("No git repo found at #{@git_path}")
       end


      pull_repo() if @git_push

    end

    def unlock_workspace()

      logger.info('Unlocking workspace')
      File.delete(@git_lockfile)

    end
  end
end
