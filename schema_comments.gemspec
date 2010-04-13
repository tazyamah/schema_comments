# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{schema_comments}
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["akimatter"]
  s.date = %q{2010-04-13}
  s.description = %q{schema_comments generates extra methods dynamically for attribute which has options}
  s.email = %q{akm2000@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
     "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "LICENSE.txt",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "autotest/discover.rb",
     "init.rb",
     "lib/annotate_models.rb",
     "lib/hash_key_orderable.rb",
     "lib/schema_comments.rb",
     "lib/schema_comments/base.rb",
     "lib/schema_comments/connection_adapters.rb",
     "lib/schema_comments/migration.rb",
     "lib/schema_comments/migrator.rb",
     "lib/schema_comments/schema.rb",
     "lib/schema_comments/schema_comment.rb",
     "lib/schema_comments/schema_dumper.rb",
     "lib/schema_comments/task.rb",
     "schema_comments.gemspec",
     "spec/.gitignore",
     "spec/annotate_models_spec.rb",
     "spec/database.yml",
     "spec/fixtures/.gitignore",
     "spec/hash_key_orderable_spec.rb",
     "spec/i18n_export_spec.rb",
     "spec/migration_spec.rb",
     "spec/migrations/valid/001_create_products.rb",
     "spec/migrations/valid/002_rename_products.rb",
     "spec/migrations/valid/003_rename_products_again.rb",
     "spec/migrations/valid/004_remove_price.rb",
     "spec/migrations/valid/005_change_products_name.rb",
     "spec/migrations/valid/006_change_products_name_with_comment.rb",
     "spec/migrations/valid/007_change_comments.rb",
     "spec/rcov.opts",
     "spec/resources/models/product.rb",
     "spec/resources/models/product_name.rb",
     "spec/schema.rb",
     "spec/schema_comments/.gitignore",
     "spec/schema_comments/connection_adapters_spec.rb",
     "spec/schema_comments/schema_dumper_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "spec/yaml_export_spec.rb",
     "tasks/annotate_models_tasks.rake",
     "tasks/schema_comments.rake"
  ]
  s.homepage = %q{http://github.com/akm/schema_comments}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{schema_comments generates extra methods dynamically}
  s.test_files = [
    "spec/annotate_models_spec.rb",
     "spec/hash_key_orderable_spec.rb",
     "spec/i18n_export_spec.rb",
     "spec/migration_spec.rb",
     "spec/migrations/valid/001_create_products.rb",
     "spec/migrations/valid/002_rename_products.rb",
     "spec/migrations/valid/003_rename_products_again.rb",
     "spec/migrations/valid/004_remove_price.rb",
     "spec/migrations/valid/005_change_products_name.rb",
     "spec/migrations/valid/006_change_products_name_with_comment.rb",
     "spec/migrations/valid/007_change_comments.rb",
     "spec/resources/models/product.rb",
     "spec/resources/models/product_name.rb",
     "spec/schema.rb",
     "spec/schema_comments/connection_adapters_spec.rb",
     "spec/schema_comments/schema_dumper_spec.rb",
     "spec/spec_helper.rb",
     "spec/yaml_export_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
  end
end

