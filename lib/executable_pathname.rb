require 'pathname'

require "executable_pathname/version"

class ExecutablePathname < Pathname

  # Absolute paths must exist or be in a well-known directory path.  Relative
  # paths must exist within one of the PATH directories, or within a well-known
  # directory path

  # Define the envar REMOTE_PATH as the colon-separated list of well-known
  # directory paths that will be referenced on remote hosts.  The default is
  # '/bin:/usr/bin:/usr/local/bin'

  def self.valid_executable?(name)
    case name
    when %r{^/}, %r{.+/.+}
      pn = new(name)
      return true if pn.valid_executable?
    else
      path_list.each do |dirname|
        pn = new(File.join(dirname, name))
        return true if pn.valid_executable?
      end
    end
    false
  end

  def self.path_list
    @@path_list ||= ENV['PATH'].split(':')
  end

  def self.remote_path_list
    (ENV['REMOTE_PATH'] || '/bin:/usr/bin:/usr/local/bin').split(':')
  end

  def initialize(path)
    super(path)
    @first_line = nil
    @shbang_paths = nil
  end

  def first_line
    @first_line ||= open { |io|
      line = io.gets
      line.chomp if line
    }
  rescue Errno::ENOENT, Errno::EACCES, IOError
    nil
  end

  def shbang?
    first_line && first_line[0..1] == '#!'
  end

  def shbang_paths
    @shbang_paths ||= first_line &&
      case first_line
      when /^#!\s*(\S+)\s+(\S+.)/ then [$1, $2.chomp]
      when /^#!\s*(\S+)/          then [$1.chomp]
      else []
      end
  end

  def env_shbang?
    shbang_paths && shbang_paths.size > 1 && shbang_paths[0].end_with?('env')
  end

  def valid_shbang?
    shbang? && (env_shbang? ? valid_env_shbang? : valid_shbang_command?)
  end

  def invalid_shbang?
    shbang? && (env_shbang? ? !valid_env_shbang? : !valid_shbang_command?)
  end

  def valid_env_shbang?
    env_shbang? && valid_shbang_command? && shbang_paths.last.split('/').size == 1
  end

  def valid_shbang_command?
    shbang_paths.size > 0 && ExecutablePathname.valid_executable?(shbang_paths[0])
  end

  def executable_file?
    exist? && file? && executable?
  end

  def valid_executable?
    exist? && executable_file? && (!shbang? || valid_shbang?)
  end

  def well_known_path?
    return false unless exist?
    ExecutablePathname.remote_path_list.any? {|rp| (shbang? ? shbang_paths.first : to_path).start_with?(rp)}
  end

  def remove_execute_permissions
    chmod(stat.mode & ~0111)
  end

end
