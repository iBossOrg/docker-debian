require "docker_helper"

### DOCKER_IMAGE ###############################################################

describe "Docker image", :test => :docker_image do
  # Default Serverspec backend
  before(:each) { set :backend, :docker }

  ### DOCKER_IMAGE #############################################################

  describe docker_image(ENV["DOCKER_IMAGE"]) do
    # Execute Serverspec commands locally
    before(:each) { set :backend, :exec }
    it { is_expected.to exist }
  end

  ### OS #######################################################################

  describe "Operating system" do
    context "family" do
      subject { os[:family] }
      it { is_expected.to eq("debian") }
    end
    context "release" do
      subject { os[:release] }
      it { is_expected.to match(/^#{Regexp.escape(ENV["DOCKER_IMAGE_TAG"])}\./) }
    end
    context "locale" do
      context "CHARSET" do
        subject { command("echo ${CHARSET}") }
        it { expect(subject.stdout.strip).to eq("UTF-8") }
      end
      context "LANG" do
        subject { command("echo ${LANG}") }
        it { expect(subject.stdout.strip).to eq("en_US.UTF-8") }
      end
    end
  end

  ### PACKAGES #################################################################

  describe "Packages" do

    # package
    packages = [
      "bash",
      "ca-certificates",
      "curl",
      "less",
      "ncat",
      "openssl",
      "procps",
      "tini",
      "tzdata",
    ]

    packages.each do |package|
      describe package(package) do
        it { is_expected.to be_installed }
      end
    end
  end

  ### FILES ####################################################################

  describe "Files" do

    # KEEP IN SYNC WITH https://github.com/iBossOrg/docker-entrypoint-overlay
    # [file,                                            mode, user,   group,  [expectations]]
    files = [
      ["/container",                                    755,  "root", "root", [:be_directory]],
      ["/container/entrypoint",                         755,  "root", "root", [:be_file]],
      ["/entrypoint",                                   755,  "root", "root", [:be_directory]],
      ["/entrypoint/00.message-lib.sh",                 644,  "root", "root", [:be_file]],
      ["/entrypoint/01.wait-for-lib.sh",                644,  "root", "root", [:be_file]],
      ["/entrypoint/10.default-config.sh",              644,  "root", "root", [:be_file], :eq_sha256sum],
      ["/entrypoint/20.default-command.sh",             644,  "root", "root", [:be_file]],
      ["/entrypoint/30.redirect-logs.sh",               644,  "root", "root", [:be_file]],
      ["/entrypoint/40.reconfigure-locale.sh",          644,  "root", "root", [:be_file]],
      ["/entrypoint/80.wait-for.sh",                    644,  "root", "root", [:be_file]],
      ["/entrypoint/90.exec-user.sh",                   644,  "root", "root", [:be_file]],
      ["/etc/inputrc",                                  644,  "root", "root", [:be_file], :eq_sha256sum],
      ["/etc/profile.d/profile.sh",                     644,  "root", "root", [:be_file], :eq_sha256sum],
      ["/etc/ssl/openssl.cnf",                          644,  "root", "root", [:be_file], :eq_sha256sum],
      ["/usr/bin/su-exec",                              755,  "root", "root", [:be_file]],
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

  ##############################################################################

end

################################################################################
