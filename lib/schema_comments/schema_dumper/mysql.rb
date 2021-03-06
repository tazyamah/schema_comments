# -*- coding: utf-8 -*-
require 'schema_comments/schema_dumper'

module SchemaComments

  class SchemaDumper::Mysql < SchemaComments::SchemaDumper

    class << self
      public :new
    end

    private
    def tables(stream)
      result = super(stream)
      # ビューはtableの後に実行するようにしないと rake db:schema:load で失敗します。
      mysql_views(stream)
      result
    end

    def mysql_view?(table)
      return false unless adapter_name == 'mysql'
      match_count = @connection.select_value(
        "select count(*) from information_schema.TABLES where TABLE_TYPE = 'VIEW' AND TABLE_SCHEMA = '%s' AND TABLE_NAME = '%s'" % [
          config["database"], table])
      match_count.to_i > 0
    end

    def config
      ActiveRecord::Base.configurations[Rails.env] || ActiveRecord::Base.configurations[ ENV['DB'] ]
    end

    def adapter_name
      c = ActiveRecord::Base.configurations[Rails.env]
      c ? c['adapter'] : ActiveRecord::Base.connection.adapter_name
    end

      def header(stream)
        define_params = @version ? ":version => #{@version}" : ""

        if stream.respond_to?(:external_encoding)
          stream.puts "# encoding: #{stream.external_encoding.name}"
        end

        stream.puts <<HEADER
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(#{define_params}) do

HEADER
      end

    def table(table, stream)
      # MySQLは、ビューもテーブルとして扱うので、一個一個チェックします。
      return if mysql_view?(table)

      columns = @connection.columns(table)
      begin
        tbl = StringIO.new

        # first dump primary key column
        if @connection.respond_to?(:pk_and_sequence_for)
          pk, _ = @connection.pk_and_sequence_for(table)
        elsif @connection.respond_to?(:primary_key)
          pk = @connection.primary_key(table)
        end

        tbl.print "  create_table #{table.inspect}"
        pk_exist = columns.detect { |c| c.name == pk } # for print ALTER TABLE ADD PRIMARY KEY
        if pk_exist
          if pk != 'id'
            tbl.print %Q(, :primary_key => "#{pk}")
          end
        else
          tbl.print ", :id => false"
        end
        tbl.print ", :force => true"

        table_comment = @connection.table_comment(table)
        tbl.print ", :comment => '#{table_comment}'" unless table_comment.blank?

        tbl.puts " do |t|"

        # then dump all non-primary key columns
        column_specs = columns.map do |column|
          raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" if @types[column.type].nil?
          # next if column.name == pk
          spec = {}
          spec[:name]      = column.name.inspect

          # AR has an optimization which handles zero-scale decimals as integers. This
          # code ensures that the dumper still dumps the column as a decimal.
#           spec[:type]      = if column.type == :integer && [/^numeric/, /^decimal/].any? { |e| e.match(column.sql_type) }
#                                'decimal'
#                              else
#                                column.type.to_s
#                              end
          spec[:type]      = column.sql_type.inspect
          # spec[:limit]     = column.limit.inspect if column.limit != @types[column.type][:limit] && spec[:type] != 'decimal'
          spec[:precision] = column.precision.inspect if column.precision
          spec[:scale]     = column.scale.inspect if column.scale
          spec[:null]      = 'false' unless column.null
          spec[:default]   = default_string(column.default) if column.has_default?
          if column.name == pk
            spec[:comment]   = '"AUTO_INCREMENT PRIMARY KEY by rails"'
          else
            spec[:comment]   = '"' << (column.comment || '').gsub(/\"/, '\"') << '"' # ここでinspectを使うと最後の文字だけ文字化け(UTF-8のコード)になっちゃう
          end
          (spec.keys - [:name, :type]).each{ |k| spec[k].insert(0, "#{k.inspect} => ")}
          spec
        end.compact

        # find all migration keys used in this table
        # keys = [:name, :limit, :precision, :scale, :default, :null, :comment] & column_specs.map{ |k| k.keys }.flatten
        keys = [:name, :type, :default, :null, :comment] & column_specs.map{ |k| k.keys }.flatten

        # figure out the lengths for each column based on above keys
        lengths = keys.map{ |key| column_specs.map{ |spec| spec[key] ? spec[key].length + 2 : 0 }.max }

        # the string we're going to sprintf our values against, with standardized column widths
        format_string = lengths.map{ |len| "%-#{len}s" }

        # find the max length for the 'type' column, which is special
        # type_length = column_specs.map{ |column| column[:type].length }.max

        # add column type definition to our format string
        # format_string.unshift "    t.%-#{type_length}s "

        format_string.unshift "    t.column "

        format_string *= ''

        column_specs.each do |colspec|
          values = keys.zip(lengths).map{ |key, len| colspec.key?(key) ? colspec[key] + ", " : " " * len }
          # values.unshift colspec[:type]
          s = (format_string % values).gsub(/,\s*$/, '')

          if colspec[:name] == pk.inspect
            tbl.print(s.sub(/ t.column /, " #t.column "))
          else
            tbl.print(s)
          end
          tbl.puts
        end

        tbl.puts "  end"
        primary_keys(table, tbl) unless pk_exist
        tbl.puts

        indexes(table, tbl)

        tbl.rewind
        stream.print tbl.read
      rescue => e
        stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
        stream.puts "#   #{e.message}"
        stream.puts
      end

      stream
    end

    def mysql_views(stream)
      view_names = @connection.select_values(
        "select TABLE_NAME from information_schema.TABLES where TABLE_TYPE = 'VIEW' AND TABLE_SCHEMA = '%s'" % config["database"])
      view_names.each do |view_name|
        mysql_view(view_name, stream)
      end
    end

    def mysql_view(view_name, stream)
      ddl = @connection.select_value("show create view #{view_name}")
      ddl.gsub!(/^CREATE .+? VIEW /i, "CREATE OR REPLACE VIEW ")
      ddl.gsub!(/AS select/, "AS \n select\n")
      ddl.gsub!(/( AS \`.+?\`\,)/){ "#{$1}\n" }
      ddl.gsub!(/ from /i         , "\n from \n")
      ddl.gsub!(/ where /i        , "\n where \n")
      ddl.gsub!(/ order by /i     , "\n order by \n")
      ddl.gsub!(/ having /i       , "\n having \n")
      ddl.gsub!(/ union /i        , "\n union \n")
      ddl.gsub!(/ and /i          , "\n and ")
      ddl.gsub!(/ or /i           , "\n or ")
      ddl.gsub!(/inner join/i     , "\n inner join")
      ddl.gsub!(/left join/i      , "\n left join")
      ddl.gsub!(/left outer join/i, "\n left outer join")
      stream.print("  ActiveRecord::Base.connection.execute(<<-EOS)\n")
      stream.print(ddl.split(/\n/).map{|line| '    ' << line.strip}.join("\n"))
      stream.print("\n  EOS\n")
    end


    def primary_keys(table, tbl)
      res = @connection.select("SHOW CREATE TABLE #{table}")
      create_table = res.first['Create Table']
      pks = create_table.scan(/\sPRIMARY KEY \((.+)\)\,/).flatten.first.
        split(/,/).map{|s| s.gsub(/^\`|\`$/, '')}
      tbl.puts("  execute \"ALTER TABLE #{table} ADD PRIMARY KEY (#{pks.join(',')})\"")

      if create_table =~ /`id` (.+) NOT NULL AUTO_INCREMENT,/
        tbl.puts("  execute \"ALTER TABLE #{table} CHANGE COLUMN `id` `id` #{$1} NOT NULL AUTO_INCREMENT\"")
      end

      if create_table =~ %r{/\*\!50100 (PARTITION .+ )\*/}m
        st = $1.gsub(/\n/, ' ')
        tbl.puts("  execute \"ALTER TABLE #{table} #{st}\"")
      end
    end

  end

end
