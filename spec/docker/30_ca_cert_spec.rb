require "docker_helper"

### CA_CERTIFICATE #############################################################

describe "Simple CA", :test => :ca_cert do
  # Default Serverspec backend
  before(:each) { set :backend, :docker }

  ### CONFIG ###################################################################

  user = "lighttpd"
  group = "lighttpd"

  crt = "/var/lib/simple-ca/secrets/ca.crt"
  key = "/var/lib/simple-ca/private/ca.key"
  pwd = "/var/lib/simple-ca/private/ca.pwd"

  subj = ENV["CA_CRT_SUBJECT"]  || "CN=Simple CA"

  ### CERTIFICATE ##############################################################

  describe x509_certificate(crt) do
    context "file" do
      subject { file(crt) }
      it { is_expected.to be_file }
      it { is_expected.to be_mode(444) }
      it { is_expected.to be_owned_by("root") }
      it { is_expected.to be_grouped_into("root") }
    end
    context "certificate" do
      it { is_expected.to be_certificate }
      it { is_expected.to be_valid }
    end
    its(:subject) { is_expected.to eq "/#{subj}" }
    its(:issuer)  { is_expected.to eq "/#{subj}" }
    its(:validity_in_days) { is_expected.to be > 36500 }
  end

  ### PRIVATE_KEY_PASSPHRASE ###################################################

  describe "X509 private key passphrase \"#{pwd}\"" do
    context "file" do
      subject { file(pwd) }
      it { is_expected.to be_file }
      it { is_expected.to be_mode(440) }
      it { is_expected.to be_owned_by(user) }
      it { is_expected.to be_grouped_into(group) }
    end
  end

  ### PRIVATE_KEY ##############################################################

  describe x509_private_key(key, {:passin => "file:#{pwd}"}) do
    context "file" do
      subject { file(key) }
      it { is_expected.to be_file }
      it { is_expected.to be_mode(440) }
      it { is_expected.to be_owned_by(user) }
      it { is_expected.to be_grouped_into(group) }
    end
    context "key" do
      it { is_expected.to be_encrypted }
      it { is_expected.to be_valid }
      it { is_expected.to have_matching_certificate(crt) }
    end
  end

  ### CA_SECRETS ####################################################################

  describe "secrets" do
    [
      # [file, mode]
      [ENV["CA_CRT_FILE"]          || "/var/lib/simple-ca/secrets/ca.crt",       444],
      [ENV["CA_USER_NAME_FILE"]    || "/var/lib/simple-ca/secrets/ca_user.name", 440],
      [ENV["CA_USER_PWD_FILE"]     || "/var/lib/simple-ca/secrets/ca_user.name", 440],
    ].each do |file, mode|
      context file(file) do
        it { is_expected.to be_file }
        it { is_expected.to be_mode(mode) }
        it { is_expected.to be_owned_by("root") }
        it { is_expected.to be_grouped_into("root") }
      end
    end
  end

##############################################################################

end

################################################################################
