# SchemaComments  [![Build Status](https://secure.travis-ci.org/akm/schema_comments.png)](http://travis-ci.org/akm/schema_comments)

## Install

### With Bundler
add this line into Gemfile

    gem "schema_comments"

And do bundle install

    bundle install

## Install(old)

### as a plugin

    ruby script/plugin install git://github.com/akm/schema_comments.git

### as a gem
insert following line to config/environment.rb

     config.gem 'schema_comments', :version => '0.2.0'

and 

    $ sudo rake gems:install

Or install gem manually

    $ sudo gem install schema_comments

And make lib/tasks/schema_comments.rake

    require 'schema_comments/task'

## Configuration for Rails App
1. make lib/tasks/schema_comments.rake
2. edit the file like following

    require 'schema_comments/task'
    SchemaComments.yaml_path = File.expand_path("../../../db/schema_comments.yml", __FILE__)


## Configuration (old)
If you install schema_comments as a gem, must create config/initializers/schema_comments.rb like this:

    require 'schema_comments'
    SchemaComments.setup


## Overview
schema_commentsプラグインを使うと、テーブルとカラムにコメントを記述することができます。

    class CreateProducts < ActiveRecord::Migration
      def self.up
        create_table "products", :comment => '商品' do |t|
          t.string   "product_type_cd", :comment => '種別コード'
          t.integer  "price", :comment => "価格"
          t.string   "name", :comment => "商品名"
          t.datetime "created_at", :comment => "登録日時"
          t.datetime "updated_at", :comment => "更新日時"
        end
      end
   
      def self.down
        drop_table "products"
      end
    end

こんな感じ。

でこのようなマイグレーションを実行すると、db/schema.rb には、
コメントが設定されているテーブル、カラムは以下のように出力されます。

    ActiveRecord::Schema.define(:version => 0) do
      create_table "products", :force => true, :comment => '商品' do |t|
        t.string   "product_type_cd", :comment => '種別コード'
        t.integer  "price", :comment => "価格"
        t.string   "name", :comment => "商品名"
        t.datetime "created_at", :comment => "登録日時"
        t.datetime "updated_at", :comment => "更新日時"
      end
    end


コメントは、以下のメソッドで使用することが可能です。

columns, create_table, drop_table, rename_table
remove_column, add_column, change_column


## コメントはどこに保存されるのか
db/schema_comments.yml にYAML形式で保存されます。
あまり推奨しませんが、もしマイグレーションにコメントを記述するのを忘れてしまった場合、db/schema_comments.yml
を直接編集した後、rake db:schema:dumpやマイグレーションを実行すると、db/schema.rbのコメントに反映されます。


## I18nへの対応

    rake i18n:schema_comments:update_config_locale

このタスクを実行すると、i18n用のYAMLを更新できます。

    rake i18n:schema_comments:update_config_locale LOCALE=ja

でデフォルトではconfig/locales/ja.ymlを更新します。

毎回LOCALEを指定するのが面倒な場合は、config/initializers/locale.rb に

    I18n.default_locale = 'ja'

という記述を追加しておくと良いでしょう。

また出力先のYAMLのPATHを指定したい場合、YAML_PATHで指定が可能です。

    rake i18n:schema_comments:update_config_locale LOCALE=ja YAML_PATH=/path/to/yaml

### コメント内コメント
コメント中の ((( から ))) は反映されませんので、モデル名／属性名に含めたくない箇所は ((( と ))) で括ってください。
((( ))) と同様に[[[ ]]]も使用できます。
例えば以下のようにdb/schema.rbに出力されている場合、

    ActiveRecord::Schema.define(:version => 0) do
      create_table "products", :force => true, :comment => '商品' do |t|
        t.string   "product_type_cd", :comment => '種別コード(((01:書籍, 02:靴, 03:パソコン)))'
        t.integer  "price", :comment => "価格"
        t.string   "name", :comment => "商品名"
        t.datetime "created_at", :comment => "登録日時"
        t.datetime "updated_at", :comment => "更新日時"
      end
    end


    rake i18n:schema_comments:update_config_locale LOCALE=ja

とすると、以下のように出力されます。

    ja:
      activerecord:
        attributes:
          product: 
            product_type_cd: "種別コード"
            price: "価格"
            name: "商品名"
            created_at: "登録日時"
            updated_at: "更新日時"



## MySQLのビュー
MySQLのビューを使用した場合、元々MySQLではSHOW TABLES でビューも表示してしまうため、
ビューはテーブルとしてSchemaDumperに認識され、development環境ではMySQLのビューとして作成されているのに、
test環境ではテーブルとして作成されてしまい、テストが正しく動かないことがあります。
これを避けるため、schema_commentsでは、db/schema.rbを出力する際、テーブルに関する記述の後に、CREATE VIEWを行う記述を追加します。


## annotate_models
rake db:annotate で以下のようなコメントを、モデル、テスト、フィクスチャといったモデルに関係の強いファイルの
先頭に追加します。

      # == Schema Info
      # 
      # Schema version: 20090721185959
      #
      # Table name: books # 書籍
      #
      #  id         :integer         not null, primary key
      #  title      :string(100)     not null               # タイトル
      #  size       :integer         not null, default(1)   # 判型
      #  price      :decimal(17, 14) not null, default(0.0) # 価格
      #  created_at :datetime                               # 登録日時
      #  updated_at :datetime                               # 更新日時
      # 
      # =================
      # 
    
また、rake db:updateで、rake db:migrateとrake db:annotateを実行します。

annotate_modelsは、達人プログラマーのDave Thomasさんが公開しているプラグインです。
http://repo.pragprog.com/svn/Public/plugins/annotate_models/

本プラグインでは、それを更に拡張したDave Boltonさんのプラグイン(
http://github.com/rotuka/annotate_models )をベースに拡張を加えています。

## License
Copyright (c) 2008 Takeshi AKIMA, released under the Ruby License
