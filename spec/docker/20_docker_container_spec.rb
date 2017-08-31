require "docker_helper"

################################################################################

describe "Docker container" do
  before(:each) { set :backend, :docker }

  ##############################################################################

  context docker_container(ENV["CONTAINER_NAME"]) do
    before(:each)  { set :backend, :exec }
    it { is_expected.to be_running }
  end

  ##############################################################################

  describe "Processes" do
    [
      ["/sbin/tini",                "root",           "root",           1],
      ["/usr/sbin/lighttpd",        "lighttpd",       "lighttpd"],
    ].each do |process, user, group, pid|
      context process(process) do
        it { is_expected.to be_running }
        its(:pid) { is_expected.to eq(pid) } unless pid.nil?
        its(:user) { is_expected.to eq(user) } unless user.nil?
        its(:group) { is_expected.to eq(group) } unless group.nil?
      end
    end
  end

  ##############################################################################

  describe "Ports" do
    [
      [80,    "tcp",  false],
      [443,   "tcp",  true],
    ].each do |port, proto, listenning|
      context port(port) do
        it { is_expected.not_to be_listening.with(proto) }  unless listenning
        it { is_expected.to be_listening.with(proto) }  if listenning
      end
    end
  end

  ##############################################################################

  describe "URLs" do
    # Execute Serverspec command locally
    before(:each)  { set :backend, :exec }
    [
      # [url, stdout, stderr]
      [ "https://#{ENV["SERVICE_NAME"]}.local/ca.crt",
        "^#{Regexp.escape(IO.binread("/run/secrets/ca.crt"))}$",
      ],
    ].each do |url, stdout, stderr|
      context url do
        subject { command("curl --location --silent --show-error --verbose #{url}") }
        it "should exist" do
          expect(subject.exit_status).to eq(0)
        end
        it "should match \"#{stdout.gsub(/\n/, "\\n")}\"" do
          expect(subject.stdout).to match(stdout)
        end unless stdout.nil?
        it "should match \"#{stderr}\"" do
          expect(subject.stderr).to match(stderr)
        end unless stderr.nil?
      end
    end
  end

  ##############################################################################

end

################################################################################
