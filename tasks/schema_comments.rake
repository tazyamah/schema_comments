# -*- coding: utf-8 -*-
require 'yaml'
# require 'yaml_waml'
require 'active_record'
require 'schema_comments'
SchemaComments.setup

db_namespace = namespace :db do
  namespace :schema do

    Rake.application.send(:eval, "@tasks.delete('db:schema:dump')")
    desc 'Create a db/schema.rb file that can be portably used against any DB supported by AR'
    task :dump => [:environment, :load_config] do
      begin
        require 'active_record/schema_dumper'
        filename = ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb"
        File.open(filename, "w:utf-8") do |file|
          ActiveRecord::Base.establish_connection(Rails.env)
          # ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
          SchemaComments::SchemaDumper.dump(ActiveRecord::Base.connection, file)
        end
        db_namespace['schema:dump'].reenable
      rescue Exception => e
        puts "[#{e.class}] #{e.message}:\n  " << e.backtrace.join("\n  ")
        raise e
      end
    end

  end
end

class ActiveRecord::Base
  class << self
    attr_accessor :ignore_pattern_to_export_i18n
  end

  self.ignore_pattern_to_export_i18n = /\(\(\(.*\)\)\)/

  class << self
    def export_i18n_models
      subclasses = ActiveRecord::Base.send(:subclasses).select do |klass|
        (klass != SchemaComments::SchemaComment) and
          klass.respond_to?(:table_exists?) and klass.table_exists?
      end
      result = subclasses.inject({}) do |d, m|
        comment = (m.table_comment || '').dup
        comment.gsub!(ignore_pattern_to_export_i18n, '') if ignore_pattern_to_export_i18n
        # テーブル名(複数形)をモデル名(単数形)に
        model_name = (comment.scan(/\[\[\[(?:model|class)(?:_name)?:\s*?([^\s]+?)\s*?\]\]\]/).flatten.first || m.name).underscore
        comment.gsub!(/\[\[\[.*?\]\]\]/)
        d[model_name] = comment
        d
      end
      result.instance_eval do
        def each_with_order(*args, &block)
          self.keys.sort.each do |key|
            yield(key, self[key])
          end
        end
        alias :each_without_order :each
        alias :each :each_with_order
      end
      result
    end

    def export_i18n_attributes
      subclasses = ActiveRecord::Base.send(:subclasses).select do |klass|
        (klass != SchemaComments::SchemaComment) and
          klass.respond_to?(:table_exists?) and klass.table_exists?
      end
      result = subclasses.inject({}) do |d, m|
        attrs = {}
        m.columns.each do |col|
          next if col.name == 'id'
          comment = (col.comment || '').dup
          comment.gsub!(ignore_pattern_to_export_i18n, '') if ignore_pattern_to_export_i18n

          # カラム名を属性名に
          attr_name = (comment.scan(/\[\[\[(?:attr|attribute)(?:_name)?:\s*?([^\s]+?)\s*?\]\]\]/).flatten.first || col.name)
          comment.gsub!(/\[\[\[.*?\]\]\]/)
          attrs[attr_name] = comment
        end

        column_names = m.columns.map(&:name) - ['id']
        column_order_modeule = Module.new do
          def each_with_column_order(*args, &block)
            @column_names.each do |column_name|
              yield(column_name, self[column_name])
            end
          end

          def self.extended(obj)
            obj.instance_eval do
              alias :each_without_column_order :each
              alias :each :each_with_column_order
            end
          end
        end
        attrs.instance_variable_set(:@column_names, column_names)
        attrs.extend(column_order_modeule)

        # テーブル名(複数形)をモデル名(単数形)に
        model_name = ((m.table_comment || '').scan(/\[\[\[(?:model|class)(?:_name)?:\s*?([^\s]+?)\s*?\]\]\]/).flatten.first || m.name).underscore
        d[model_name] = attrs
        d
      end

      result.instance_eval do
        def each_with_order(*args, &block)
          self.keys.sort.each do |key|
            yield(key, self[key])
          end
        end
        alias :each_without_order :each
        alias :each :each_with_order
      end
      result
    end
  end
end

namespace :i18n do
  namespace :schema_comments do
    task :load_all_models => :environment do
      Dir.glob(Rails.root.join('app/models/**/*.rb')) do |file_name|
        require file_name
      end
    end

    desc "Export i18n model resources from schema_comments. you can set locale with environment variable LOCALE"
    task :export_models => :"i18n:schema_comments:load_all_models" do
      locale = (ENV['LOCALE'] || I18n.locale).to_s
      obj = {locale => {'activerecord' => {'models' => ActiveRecord::Base.export_i18n_models}}}
      puts YAML.dump(obj)
    end

    desc "Export i18n attributes resources from schema_comments. you can set locale with environment variable LOCALE"
    task :export_attributes => :"i18n:schema_comments:load_all_models" do
      locale = (ENV['LOCALE'] || I18n.locale).to_s
      obj = {locale => {'activerecord' => {'attributes' => ActiveRecord::Base.export_i18n_attributes}}}
      puts YAML.dump(obj)
    end

    desc "update i18n YAML. you can set locale with environment variable LOCALE"
    task :update_config_locale => :"i18n:schema_comments:load_all_models" do
      require 'yaml/store'
      locale = (ENV['LOCALE'] || I18n.locale).to_s
      path = (ENV['YAML_PATH'] || Rails.root.join("config/locales/#{locale}.yml"))
      print "updating #{path}..."

      begin
        db = YAML::Store.new(path)
        db.transaction do
          locale = db[locale] ||= {}
          activerecord = locale['activerecord'] ||= {}
          activerecord['models'] = ActiveRecord::Base.export_i18n_models
          activerecord['attributes'] = ActiveRecord::Base.export_i18n_attributes
        end
        puts "Complete!"
      rescue Exception
        puts "Failure!!!"
        puts $!.to_s
        puts "  " << $!.backtrace.join("\n  ")
        raise
      end
    end
  end
end
