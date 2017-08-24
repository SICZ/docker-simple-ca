require "docker_helper"

### DOCKER_IMAGE ###############################################################

describe "Docker image", :test => :docker_image do
  # Default Serverspec backend
  before(:each) { set :backend, :docker }

  ### DOCKER_IMAGE #############################################################

  # describe docker_image(ENV["DOCKER_IMAGE"]) do
  #   # Execute Serverspec command locally
  #   before(:each) { set :backend, :exec }
  #   it { is_expected.to exist }
  # end

  ### USERS ####################################################################

  describe "Users" do
    [
      # [user,                      uid,  primary_group]
      ["lighttpd",                  1000, "lighttpd"],
    ].each do |user, uid, primary_group|
      context user(user) do
        it { is_expected.to exist }
        it { is_expected.to have_uid(uid) } unless uid.nil?
        it { is_expected.to belong_to_primary_group(primary_group) } unless primary_group.nil?
      end
    end
  end

  ### GROUPS ###################################################################

  describe "Groups" do
    [
      # [group,                     gid]
      ["lighttpd",                  1000],
    ].each do |group, gid|
      context group(group) do
        it { is_expected.to exist }
        it { is_expected.to have_gid(gid) } unless gid.nil?
      end
    end
  end

  ### PACKAGES #################################################################

  describe "Packages" do
    [
      # [package,                   version,                    installer]
      "bash",
      "libressl",
      ["lighttpd",                  ENV["LIGHTTPD_VERSION"]],
      ["lighttpd-mod_auth",         ENV["LIGHTTPD_VERSION"]],
    ].each do |package, version, installer|
      describe package(package) do
        it { is_expected.to be_installed }                        if installer.nil? && version.nil?
        it { is_expected.to be_installed.with_version(version) }  if installer.nil? && ! version.nil?
        it { is_expected.to be_installed.by(installer) }          if ! installer.nil? && version.nil?
        it { is_expected.to be_installed.by(installer).with_version(version) } if ! installer.nil? && ! version.nil?
      end
    end
  end

  ### FILES ####################################################################

  describe "Files" do
    # Fix persmissions broken after mounting simple_ca_secrets volume in test container
    before(:context) do
      system("chmod 750 /run/secrets")
      system("chown 1000:1000 /run/secrets")
    end
    [
      # [file,                                            mode, user,       group,      [expectations]]
      ["/docker-entrypoint.sh",                           755, "root",      "root",     [:be_file]],
      ["/docker-entrypoint.d/31-environment-simple-ca.sh", 644, "root",     "root",     [:be_file, :eq_sha256sum]],
      ["/docker-entrypoint.d/40-simple-ca-cert.sh",       644, "root",      "root",     [:be_file, :eq_sha256sum]],
      ["/docker-entrypoint.d/60-simple-ca-userdb.sh",     644, "root",      "root",     [:be_file, :eq_sha256sum]],
      ["/etc/lighttpd/lighttpd.conf",                     644, "root",      "root",     [:be_file]],
      ["/etc/lighttpd/server.conf",                       644, "root",      "root",     [:be_file, :eq_sha256sum]],
      ["/etc/ssl/openssl.cnf",                            644, "root",      "root",     [:be_file, :eq_sha256sum]],
      ["/var/lib/simple-ca",                              750, "lighttpd",  "lighttpd", [:be_directory]],
      ["/var/lib/simple-ca/certs",                        750, "lighttpd",  "lighttpd", [:be_directory]],
      ["/var/lib/simple-ca/newcerts",                     750, "lighttpd",  "lighttpd", [:be_directory]],
      ["/var/lib/simple-ca/secrets",                      750, "lighttpd",  "lighttpd", [:be_directory]],
      ["/var/lib/simple-ca/secrets/ca.crt",               444, "lighttpd",  "lighttpd"],
      ["/var/lib/simple-ca/secrets/ca.key",               440, "lighttpd",  "lighttpd"],
      ["/var/lib/simple-ca/index",                        644, "lighttpd",  "lighttpd", [:be_file]],
      ["/var/lib/simple-ca/serial",                       644,  "lighttpd", "lighttpd", [:be_file]],
      ["/var/lib/lighttpd",                               750, "lighttpd",  "lighttpd", [:be_directory]],
      ["/var/lib/lighttpd",                               750, "lighttpd",  "lighttpd", [:be_directory]],
      ["/var/www",                                        755, "root",      "root",     [:be_directory]],
      ["/var/www/simple-ca.cgi",                          555, "root",      "root",     [:be_file, :eq_sha256sum]],
    ].each do |file, mode, user, group, expectations|
      expectations ||= []
      context file(file) do
        it { is_expected.to exist }
        it { is_expected.to be_file }       if expectations.include?(:be_file)
        it { is_expected.to be_directory }  if expectations.include?(:be_directory)
        it { is_expected.to be_mode(mode) } unless mode.nil?
        it { is_expected.to be_owned_by(user) } unless user.nil?
        it { is_expected.to be_grouped_into(group) } unless group.nil?
        its(:sha256sum) do
          is_expected.to eq(
              Digest::SHA256.file("config/#{subject.name}").to_s
          )
        end if expectations.include?(:eq_sha256sum)
      end
    end
  end

  ##############################################################################

end

################################################################################
