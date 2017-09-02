# ExecutablePathname

The `executable_pathname` gem provides additional methods for inspecting executable pathnames, within a subclass of the Pathname class.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'executable_pathname'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install executable_pathname

## Usage

    require 'executable_pathname'

### Class Methods

    .valid_executable?(path)

Returns true if `path` is a _valid_ executable file, where validity is
determined by examining the file, and ensuring that if it is a "hash-bang"
script, that the hash-bang path exists, or is likely to exist.

    .path_list

Returns the current environment variable `PATH` split into an array.

    .remote_path_list

Returns the remote path list, as an array, which is obtained from the envar `REMOTE_PATH`, if defined, or defaults to `'/bin:/usr/bin:/usr/local/bin'` _(split into an array)_.

    .new(path)

Creates a new instance of an `ExecutablePathname`, with the below instance methods.

### Instance Methods

    #first_line

Returns the first line of the file at `path`, if text.

    #shbang?

Returns true if the first line of the file at `path` starts with `#!`.  "shbang" is a contraction of "hash bang".

    #shbang_paths

Returns the paths from the hash-bang line.  If the hash-bang line looks like this:

    #!/path/to/some/file arg1 arg2

then the resulting array from `shbang_paths` is `['/path/to/some/file', 'arg1', 'arg2']`.

    #env_shbang?

Returns true if the `first_line` value contains at least two paths, the first of which ends with `/env`

    #valid_shbang?

Returns true if the `first_line` is a valid hash-bang, where validity is
determined by the actual existence of the first path, or the probable existence
of the path, based on it being one of the well-known paths from `REMOTE_PATH`.

    #invalid_shbang?

Returns false if the `first_line` value is not a valid hash-bang.

    #valid_env_shbang?

Returns false if the `first_line` value is not a valid `env` hash-bang path.

    #executable_file?

Returns true if the instance is an executable file.

    #valid_executable?

Returns true if the instance is a _valid_ executable file; that is, if the
hash-bang path exists, or is in a well-known path.

    #well_known_path?

Returns true if the instance path is in one of the REMOTE_PATH directories.

    #remove_execute_permissions

Removes the execute permissions on the instance.  An error is raised if the
instance path does not exist.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aks/executable_pathname. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
