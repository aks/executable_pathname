require 'spec_helper'
require 'executable_pathname'

require 'pry-byebug'

RSpec.describe ExecutablePathname do

  RUBY_SCRIPT             = "/tmp/my-test-ruby-script.rb"
  BASH_SCRIPT             = "/tmp/my-bash-script.sh"
  SCRIPT_WITH_BAD_SHBANG  = "/tmp/bad-shbang-script.sh"
  SCRIPT_WITH_BAD_ENV     = "/tmp/bad-env-shbang-script.sh"
  SCRIPT_WITH_NO_SHBANG   = "/tmp/no-shbang-script.sh"
  NON_EXECUTABLE_SCRIPT   = "/tmp/no-execute-script.sh"
  NO_SUCH_SCRIPT          = "/tmp/no_such_script"
  TEST_X_SCRIPT           = '/tmp/test-x-script'
  TEST_NX_SCRIPT          = '/tmp/test-nx-script'

  $all_scripts_pathnames = []

  def create_script(file, contents, executable=true)
    pn = ExecutablePathname.new(file)
    perms = executable ? 0755 : 0644
    pn.unlink if pn.exist?
    pn.open('w+', perms) do |f|
      f.write(contents.lstrip.gsub(/\n\s+/, "\n"))
    end
    $all_scripts_pathnames << pn
  end

  before(:all) do
    create_script(RUBY_SCRIPT, <<-EOF)
      #!/usr/bin/env ruby
      puts "howdy!"
    EOF

    create_script(BASH_SCRIPT, <<-EOF)
      #!/bin/bash
      echo "howdy!"
    EOF

    create_script(SCRIPT_WITH_BAD_SHBANG, <<-EOF)
      #!/foo/bash
      echo "howdy!"
    EOF

    create_script(SCRIPT_WITH_BAD_ENV, <<-EOF)
      #!/usr/bin/env bad/basharoobod
      echo "howdy!"
    EOF

    create_script(SCRIPT_WITH_NO_SHBANG, <<-EOF)
      ../usr/bin/env basharoobod
      echo "howdy!"
    EOF

    create_script(NON_EXECUTABLE_SCRIPT, <<-EOF, false)
      #!/bin/bash
      echo "howdy!"
    EOF

    File.exist?(NO_SUCH_SCRIPT) && File.unlink(NO_SUCH_SCRIPT)

    create_script(TEST_X_SCRIPT, <<~EOF)
      #!/bin/bash
      exit
    EOF

    create_script(TEST_NX_SCRIPT, <<~EOF, false)
      # no shbang no shame
    EOF
  end

  after(:all) do
    while (pathname = $all_scripts_pathnames.shift) do
      pathname.unlink if pathname.exist?
    end
  end

  context "class methods" do
    subject { ExecutablePathname }
    it { is_expected.to respond_to(:valid_executable?, :path_list, :remote_path_list) }

    context ".valid_executable?" do

      it "returns true when given an executable file with a valid shbang" do
        expect(ExecutablePathname.valid_executable?(RUBY_SCRIPT)).to eq true
        expect(ExecutablePathname.valid_executable?(BASH_SCRIPT)).to eq true
      end

      it "returns false when given a non-existant file" do
        expect(ExecutablePathname.valid_executable?(NO_SUCH_SCRIPT)).to eq false
      end

      it "returns false when given an executable file with an invalid shbang" do
        expect(ExecutablePathname.valid_executable?(SCRIPT_WITH_BAD_SHBANG)).to eq false
        expect(ExecutablePathname.valid_executable?(SCRIPT_WITH_BAD_ENV)).to eq false
      end

      it "returns true when given a binary executable file" do
        expect(ExecutablePathname.valid_executable?('/bin/bash')).to eq true
      end

      it "returns false when given a non-executable file" do
        expect(ExecutablePathname.valid_executable?(NON_EXECUTABLE_SCRIPT)).to eq false
      end
    end

    context ".path_list" do
      TEST_PATH = '/bin:/usr/bin:/usr/local/bin:/usr/opt/bin'

      it "returns the elements of the PATH envar as an array" do
        expect(ENV).to receive(:[]).with('PATH').and_return(TEST_PATH)
        expect(ExecutablePathname.path_list).to match_array(TEST_PATH.split(':'))
      end
    end

    context ".remote_path_list" do
      TEST_REMOTE_PATH = '/bin:/usr/bin:/usr/local/bin:/usr/opt/bin'

      it "returns the elements of the defined REMOTE_PATH as an array" do
        expect(ENV).to receive(:[]).with('REMOTE_PATH').and_return(TEST_REMOTE_PATH)
        expect(ExecutablePathname.remote_path_list).to match_array(TEST_REMOTE_PATH.split(':'))
      end
    end

  end

  context "instance methods" do
    subject { ExecutablePathname.new('foobar') }
    it { is_expected.to respond_to(:shbang?,
                                   :first_line,
                                   :valid_shbang?,
                                   :invalid_shbang?,
                                   :executable_file?,
                                   :well_known_path?,
                                   :remove_execute_permissions
                                  )
    }
  end

  context "#shbang? and other instance condition methods" do

    methods_to_test = [         :shbang?,  :env_shbang?,  :valid_shbang?, :invalid_shbang?, :executable_file? ]
    test_matrix = [
        [ :RUBY_SCRIPT,             true,   true,          true,           false,          true  ],
        [ :BASH_SCRIPT,             true,   false,         true,           false,          true  ],
        [ :SCRIPT_WITH_BAD_SHBANG,  true,   false,         false,          true,           true  ],
        [ :SCRIPT_WITH_BAD_ENV,     true,   true,          false,          true,           true  ],
        [ :SCRIPT_WITH_NO_SHBANG,   false,  false,         false,          false,          true  ],
        [ :NON_EXECUTABLE_SCRIPT,   true,   false,         true,           false,          false ],
        [ :NO_SUCH_SCRIPT,          nil,    nil,           nil,            nil,            false ],
      ]

    test_matrix.each_with_index do |test_data|
      test_result = test_data.dup
      script = test_result.shift.to_s

      methods_to_test.each_with_index do |method_name, index|
        context "##{script} and #{method_name}" do
          subject { ExecutablePathname.new(eval(script)).send(method_name) }
          it { is_expected.to eq(test_result[index]) }
        end
      end
    end
  end

  context "#first_line" do

    test_scripts_and_lines = [ [:RUBY_SCRIPT,             "#!/usr/bin/env ruby"        ],
                               [:BASH_SCRIPT,             "#!/bin/bash"                ],
                               [:SCRIPT_WITH_BAD_SHBANG,  "#!/foo/bash"                ],
                               [:SCRIPT_WITH_BAD_ENV,     "#!/usr/bin/env basharoobod" ],
                               [:SCRIPT_WITH_NO_SHBANG,   "../usr/bin/env basharoobod" ],
                               [:NON_EXECUTABLE_SCRIPT,   "#!/bin/bash"                ],
                             ]
    test_scripts_and_lines.each do |script, line|
      context "script #{script}" do
        subject {
          line = ExecutablePathname.new(eval(script.to_s)).first_line
          line.chomp if line
        }
        it { is_expected.to eq(line) }
      end
    end
  end

  context "#executable_file?" do
    it "returns true when the instance path is an executable file" do
      expect(ExecutablePathname.new(RUBY_SCRIPT).valid_executable?).to eq true
      expect(ExecutablePathname.new(BASH_SCRIPT).valid_executable?).to eq true
    end

    it "returns false when the instance path is a non-executable file" do
      expect(ExecutablePathname.new(NON_EXECUTABLE_SCRIPT).valid_executable?).to eq false
    end
  end

  context "#valid_executable?" do
    it "returns true when the instance path is a valid executable" do
      expect(ExecutablePathname.new(RUBY_SCRIPT).valid_executable?).to eq true
      expect(ExecutablePathname.new(BASH_SCRIPT).valid_executable?).to eq true
    end

    it "returns false when the instance path is not a valid executable file" do
      expect(ExecutablePathname.new(SCRIPT_WITH_BAD_SHBANG).valid_executable?).to eq false
      expect(ExecutablePathname.new(SCRIPT_WITH_BAD_ENV).valid_executable?).to    eq false
      expect(ExecutablePathname.new(NON_EXECUTABLE_SCRIPT).valid_executable?).to  eq false
      expect(ExecutablePathname.new(NO_SUCH_SCRIPT).valid_executable?).to         eq false
    end
  end

  context "#well_known_path?" do
    it "returns true if the instance is a script in a well-known path" do
      expect(ExecutablePathname.new(RUBY_SCRIPT).valid_executable?).to         eq true
      expect(ExecutablePathname.new(BASH_SCRIPT).valid_executable?).to         eq true
    end

    it "returns false if the instance shbang or the instance path is not in a well-known path" do
      expect(ExecutablePathname.new(SCRIPT_WITH_BAD_SHBANG).valid_executable?).to eq false
      expect(ExecutablePathname.new(SCRIPT_WITH_BAD_ENV).valid_executable?).to    eq false
      expect(ExecutablePathname.new(NON_EXECUTABLE_SCRIPT).valid_executable?).to  eq false
      expect(ExecutablePathname.new(NO_SUCH_SCRIPT).valid_executable?).to         eq false
    end
  end

  context "#remove_execute_permissions" do
    it "removes the execute permissions on an executable file" do
      expect(File.executable?(TEST_X_SCRIPT)).to be true
      expect { ExecutablePathname.new(TEST_X_SCRIPT).remove_execute_permissions }.to_not raise_error
      expect(File.executable?(TEST_X_SCRIPT)).to be false
    end

    it "does not affect non-executable files" do
      expect(File.executable?(TEST_NX_SCRIPT)).to be false
      expect { ExecutablePathname.new(TEST_NX_SCRIPT).remove_execute_permissions }.to_not raise_error
      expect(File.executable?(TEST_NX_SCRIPT)).to be false
    end
  end

end
