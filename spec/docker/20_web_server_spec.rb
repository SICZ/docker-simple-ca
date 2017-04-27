# encoding: UTF-8
require "docker_helper"

describe "Web server" do

  context "configuration file" do
    [
      "/etc/lighttpd/lighttpd.conf",
      "/etc/lighttpd/logs.conf",
      "/etc/lighttpd/server.conf",
      "/etc/ssl/openssl.cnf",
    ].each do |file|
      context file do
        it "exists" do
          expect(file(file)).to exist
          expect(file(file)).to be_readable.by_user("lighttpd")
        end
      end
    end
  end

  context "user 'lighttpd'" do
    it "has uid 1000" do
      expect(user("lighttpd")).to exist
      expect(user("lighttpd")).to have_uid(1000)
    end
    it "belongs to primary group 'lighttpd'" do
      expect(user("lighttpd")).to belong_to_primary_group "lighttpd"
    end
  end

  context "group 'lighttpd'" do
    it "has gid 1000" do
      expect(group("lighttpd")).to exist
      expect(group("lighttpd")).to have_gid(1000)
    end
  end

  context "server certificate" do
    key = "/var/lib/simple-ca/secrets/ca_server.pem"
    crt = "/var/lib/simple-ca/secrets/ca_server.pem"
    it "has set permissions" do
      expect(file(key)).to be_owned_by("lighttpd")
      expect(file(key)).to be_grouped_into("lighttpd")
      expect(file(key)).not_to be_readable.by("others")
      # crt and key are the same file
      # expect(file(crt)).to be_owned_by("lighttpd")
      # expect(file(crt)).to be_grouped_into("lighttpd")
      # expect(file(crt)).not_to be_readable.by("others")
    end
    it "is valid" do
      expect(x509_private_key(key)).to be_valid
      expect(x509_certificate(crt)).to be_certificate
      expect(x509_certificate(crt)).to be_valid
      expect(x509_certificate(crt).subject).to eq "/CN=sicz_simple_ca"
      expect(x509_certificate(crt).issuer).to eq "/CN=Docker Simple CA"
      expect(x509_certificate(crt).validity_in_days).to be > 3650
      expect(x509_certificate(crt).subject_alt_names).to include "DNS:localhost"
      expect(x509_certificate(crt).subject_alt_names).to include "IP Address:127.0.0.1"
      expect(x509_private_key(key)).to have_matching_certificate(crt)
    end
  end

  context "daemon" do
    it "is listening on TCP port 443" do
      expect(process("lighttpd")).to be_running
      expect(port(80)).not_to be_listening.with("tcp")
      expect(port(443)).to be_listening.with("tcp")
    end
  end
end
