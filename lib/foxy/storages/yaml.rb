# frozen_string_literal: true

require "yaml/store"

module Foxy
  module Storages
    class Yaml
      attr_accessor :collection

      def initialize(collection)
        @collection = collection
      end

      def where(attrs)
        all.select(&query(attrs))
      end

      def add(attrs)
        attrs.tap { store.transaction { all! << attrs } }
      end

      def all
        store.transaction { all! }
      end

      def delete(attrs)
        store.transaction do
          before = all!.count
          all!.delete_if(&query(attrs))
          before - all!.count
        end
      end

      def update(attrs, &block)
        store.transaction { all!.select(&query(attrs)).each(&block) }
      end

      def destroy_all
        File.delete store.path if File.exist? store.path
        @store = nil

        true
      end

      private

      def store_folder
        "store"
      end

      def store
        @store ||= store!
      end

      def query(attrs)
        keys = attrs.keys
        values = attrs.values

        proc { |item| item.values_at(*keys) == values }
      end

      def all!
        store[:items] ||= []
      end

      def store!
        FileUtils.mkdir_p(store_folder)
        YAML::Store.new(path).tap { |s| s.transaction { s[:items] ||= [] } }
      end

      def path
        "#{store_folder}/#{collection}#{env}.store.yaml"
      end

      def env
        Foxy.env && "-#{Foxy.env}"
      end
    end
  end
end
