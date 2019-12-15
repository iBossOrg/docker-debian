require "docker_helper"

### DOCKER_CONTAINER ###########################################################

describe "Docker container", :test => :docker_container do
  # Default Serverspec backend
  before(:each) { set :backend, :docker }

  ### DOCKER_CONTAINER #########################################################

  describe docker_container(ENV["CONTAINER_NAME"]) do
    # Execute Serverspec command locally
    before(:each) { set :backend, :exec }
    it { is_expected.to be_running }
  end

  ### PROCESSES ################################################################

  describe "Processes" do
    # [process, user, group, pid]
    processes = [
      ["tini", "root", "root", 1],
    ]

    processes.each do |process, user, group, pid|
      context process(process) do
        it { is_expected.to be_running }
        its(:pid) { is_expected.to eq(pid) } unless pid.nil?
        its(:user) { is_expected.to eq(user) } unless user.nil?
        its(:group) { is_expected.to eq(group) } unless group.nil?
      end
    end
  end

  ### ENTRYPOINT ###############################################################

  # KEEP IN SYNC WITH https://github.com/iBossOrg/docker-entrypoint-overlay

  describe "Entrypoint", :test => :entrypoint do
    hostname = ENV["SERVICE_NAME"].gsub("_", "-")
    entrypoint_msg_lib = "/entrypoint/00.message-lib.sh"
    entrypoint_wait_for_lib = "/entrypoint/01.wait-for-lib.sh"

    describe entrypoint_msg_lib do

      describe "#msg" do
        context "works with default arguments" do
          subject { command(<<~END)
            /bin/bash -c ". #{entrypoint_msg_lib}; msg LEVEL bash message"
            END
          }
          its(:exit_status) { is_expected.to eq(0) }
          its(:stdout) { is_expected.to match(/^\[\d+-\d+-\d+T\d+:\d+:\d+Z\s*\]\[LEVEL\s*\]\[bash\s*\] message$/) }
        end
      end

      [
        "error",
        "warn",
        "info",
        "debug",
      ].each do |function|
        describe "##{function}" do
          context "works with default arguments" do
            subject { command(<<~END)
              /bin/bash -c ". #{entrypoint_msg_lib}; #{function} message"
              END
            }
            its(:exit_status) { is_expected.to eq(0) }
            its(:stdout) { is_expected.to match(/^\[\d+-\d+-\d+T\d+:\d+:\d+Z\s*\]\[#{function.upcase}\s*\]\[bash\s*\] message$/) }
          end
        end
      end
    end

    describe entrypoint_wait_for_lib do
      context "#wait_for_dns" do
        # [url,                                exit_status, match]
        [
          ["#{hostname}.local:80",             0, "Got the #{hostname}.local address \\d+\\.\\d+\\.\\d+\\.\\d+ in 0s"],
          ["nonexistent.local:80",             1, "nonexistent.local name resolution timed out after \\d+s"],
        ].each do |url, exit_status, match|
          context "resolve \"#{url}\"" do
            subject { command(<<~END)
              /bin/bash -c ". #{entrypoint_msg_lib}; . #{entrypoint_wait_for_lib}; wait_for_dns 1 #{url}"
              END
            }
            its(:exit_status) { is_expected.to eq(exit_status) }
            its(:stdout) { is_expected.to match(/#{match}/) }
          end
        end
      end

      context "#wait_for_tcp" do
        # [url,                                exit_status, match]
        [
          ["#{hostname}.local:80",             0, "Got the connection to tcp://#{hostname}.local:80 in 0s"],
          ["http://#{hostname}.local",         0, "Got the connection to tcp://#{hostname}.local:80 in 0s"],
          ["http://#{hostname}.local/test",    0, "Got the connection to tcp://#{hostname}.local:80 in 0s"],
          ["http://#{hostname}.local:88",      1, "Connection to tcp://#{hostname}.local:88 timed out after \\d+s"],
          ["http://#{hostname}.local:88/test", 1, "Connection to tcp://#{hostname}.local:88 timed out after \\d+s"],
          ["https://#{hostname}.local/test",   1, "Connection to tcp://#{hostname}.local:443 timed out after \\d+s"],
          ["nonexistent.local:80",             1, "nonexistent.local name resolution timed out after \\d+s"],
        ].each do |url, exit_status, match|
          context "connect to \"#{url}\"" do
            subject { command(<<~END)
              /bin/bash -c ". #{entrypoint_msg_lib}; . #{entrypoint_wait_for_lib}; wait_for_tcp 1 #{url}"
              END
            }
            its(:exit_status) { is_expected.to eq(exit_status) }
            its(:stdout) { is_expected.to match(/#{match}/) }
          end
        end
      end

      context "#wait_for_url" do
        # [url,                                exit_status, match]
        [
          ["http://#{hostname}.local/test",    0, "Got the connection to http://#{hostname}.local/test in 0s"],
          ["https://#{hostname}.local/test",   1, "Connection to https://#{hostname}.local/test timed out after \\d+s"],
          ["http://nonexistent.local",         1, "nonexistent.local name resolution timed out after \\d+s"],
        ].each do |url, exit_status, match|
          context "connect to \"#{url}\"" do
            subject { command(<<~END)
              /bin/bash -c ". #{entrypoint_msg_lib}; . #{entrypoint_wait_for_lib}; wait_for_url 1 #{url}"
              END
            }
            its(:exit_status) { is_expected.to eq(exit_status) }
            its(:stdout) { is_expected.to match(/#{match}/) }
          end
        end
      end
    end

    describe "/entrypoint/30.docker-logs.sh" do

      # [file,                                   mode, user,   group,  [expectations]]
      files = [
        ["/var/log/docker.log",                  600,  "root", "root", [:be_pipe]],
        ["/var/log/docker.err",                  600,  "root", "root", [:be_pipe]],
      ]

      files.each do |file, mode, user, group, expectations|
        expectations ||= []
        context file(file) do
          it { is_expected.to exist }
          it { is_expected.to be_file }       if expectations.include?(:be_file)
          it { is_expected.to be_pipe }       if expectations.include?(:be_pipe)
          it { is_expected.to be_directory }  if expectations.include?(:be_directory)
          it { is_expected.to be_mode(mode) } unless mode.nil?
          it { is_expected.to be_owned_by(user) } unless user.nil?
          it { is_expected.to be_grouped_into(group) } unless group.nil?
          its(:sha256sum) do
            is_expected.to eq(
                Digest::SHA256.file("rootfs/#{subject.name}").to_s
            )
          end if expectations.include?(:eq_sha256sum)
        end
      end
    end

    # TODO: /container/entrypoint
    # TODO: /entrypoint/20.default-command.sh
    # TODO: /entrypoint/40.reconfigure-locale.sh
    # TODO: /entrypoint/80.wait-for.sh
    # TODO: /entrypoint/90.docker-command.sh

  end

  ##############################################################################

  end

################################################################################
