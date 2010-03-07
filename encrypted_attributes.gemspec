# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{encrypted_attributes}
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aaron Pfeifer"]
  s.date = %q{2010-03-07}
  s.description = %q{Adds support for automatically encrypting ActiveRecord attributes}
  s.email = %q{aaron@pluginaweek.org}
  s.files = ["lib/encrypted_attributes", "lib/encrypted_attributes/sha_cipher.rb", "lib/encrypted_attributes.rb", "test/unit", "test/unit/sha_cipher_test.rb", "test/unit/encrypted_attributes_test.rb", "test/app_root", "test/app_root/db", "test/app_root/db/migrate", "test/app_root/db/migrate/001_create_users.rb", "test/app_root/app", "test/app_root/app/models", "test/app_root/app/models/user.rb", "test/app_root/config", "test/app_root/config/environment.rb", "test/test_helper.rb", "test/factory.rb", "test/keys", "test/keys/public", "test/keys/private", "CHANGELOG.rdoc", "init.rb", "LICENSE", "Rakefile", "README.rdoc"]
  s.homepage = %q{http://www.pluginaweek.org}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{pluginaweek}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Adds support for automatically encrypting ActiveRecord attributes}
  s.test_files = ["test/unit/sha_cipher_test.rb", "test/unit/encrypted_attributes_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<encrypted_strings>, [">= 0.3.3"])
    else
      s.add_dependency(%q<encrypted_strings>, [">= 0.3.3"])
    end
  else
    s.add_dependency(%q<encrypted_strings>, [">= 0.3.3"])
  end
end
