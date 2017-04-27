# encoding: UTF-8
require "docker_helper"

describe "Certificate authority" do

  context "CA certificate" do
    file = "/var/lib/simple-ca/secrets/ca_crt.pem"
    it "has set permissions" do
      expect(file(file)).to be_a_file
      expect(file(file)).to be_readable.by_user("lighttpd")
    end
    it "is valid certificate" do
      expect(file(file)).to be_a_file
      expect(x509_certificate(file)).to be_certificate
      expect(x509_certificate(file)).to be_valid
      expect(x509_certificate(file).subject).to eq "/CN=Docker Simple CA"
      expect(x509_certificate(file).issuer).to eq "/CN=Docker Simple CA"
      expect(x509_certificate(file).validity_in_days).to be > 36500
      expect(x509_certificate(file).keylength).to be >= 2048
    end
  end

  context "CA private key" do
    file = "/var/lib/simple-ca/secrets/ca_key.pem"
    it "has set permissions" do
      expect(file(file)).to be_a_file
      expect(file(file)).to be_owned_by("lighttpd")
      expect(file(file)).to be_grouped_into("lighttpd")
      expect(file(file)).not_to be_readable.by("others")
    end
    # TODO: x509_private_key.encrypted? does not accept OpenSSL PEM keys format
    # https://github.com/mizzy/serverspec/blob/master/lib/serverspec/type/x509_private_key.rb
    # it "is encrypted" do
    #   expect(x509_private_key(file)).to be_encrypted
    # end
  end

  context "CA private key passphrase" do
    file = "/var/lib/simple-ca/secrets/ca_key.pwd"
    it "has set permissions" do
      expect(file(file)).to be_a_file
      expect(file(file)).to be_owned_by("lighttpd")
      expect(file(file)).to be_grouped_into("lighttpd")
      expect(file(file)).not_to be_readable.by("others")
    end
  end

  context "CA web user password" do
    file = "/var/lib/simple-ca/secrets/ca_user.pwd"
    it "has set permissions" do
      expect(file(file)).to be_a_file
      expect(file(file)).to be_owned_by("lighttpd")
      expect(file(file)).to be_grouped_into("lighttpd")
      expect(file(file)).not_to be_readable.by("others")
    end
  end

  context "CGI script" do
    file = "/var/www/simple-ca.cgi"
    it "has set permissions" do
      expect(file(file)).to be_a_file
      expect(file(file)).to be_executable.by_user("lighttpd")
    end
  end

  context "web services" do
    context "CA certificate endpoint" do
      subject do
        command("
          curl -fs \
            --cacert /var/lib/simple-ca/secrets/ca_crt.pem \
            https://localhost/ca.pem
        ")
      end
      it "returns valid certificate" do
        ca_crt = File.read("secrets/ca_crt.pem")
        expect(subject.exit_status).to eq 0
        expect(subject.stdout).to eq(ca_crt)
      end
    end
    context "certificate sign endpoint" do
      key = "/var/lib/simple-ca/secrets/test_key.pem"
      crt = "/var/lib/simple-ca/secrets/test_crt.pem"
      # Create private key and request certificate
      subject do
        command("
          openssl req \
            -subj /CN=test.local \
            -nodes -newkey rsa:2048 \
            -keyout #{key} |
          curl -fs \
            --cacert /var/lib/simple-ca/secrets/ca_crt.pem \
            --user agent007:`cat /var/lib/simple-ca/secrets/ca_user.pwd` \
            --data-binary @- \
            --output #{crt} \
            'https://localhost/sign?dn=CN=test.local&dns=test.local,localhost&ip=192.0.2.1,127.0.0.1&rid=1.2.3'
        ")
      end
      # Read certificate
      it "returns valid certificate" do
        expect(subject.exit_status).to eq 0
        expect(file(key)).to exist
        expect(file(crt)).to exist
        expect(x509_private_key(key)).to be_valid
        expect(x509_certificate(crt)).to be_certificate
        expect(x509_certificate(crt)).to be_valid
        expect(x509_certificate(crt).subject).to eq "/CN=test.local"
        expect(x509_certificate(crt).issuer).to eq "/CN=Docker Simple CA"
        expect(x509_certificate(crt).validity_in_days).to be > 3650
        expect(x509_certificate(crt).subject_alt_names).to include "DNS:test.local"
        expect(x509_certificate(crt).subject_alt_names).to include "DNS:localhost"
        expect(x509_certificate(crt).subject_alt_names).to include "IP Address:192.0.2.1"
        expect(x509_certificate(crt).subject_alt_names).to include "IP Address:127.0.0.1"
        expect(x509_certificate(crt).subject_alt_names).to include "Registered ID:1.2.3"
        expect(x509_private_key(key)).to have_matching_certificate(crt)
      end
    end
  end
end
