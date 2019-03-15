# frozen_string_literal: true

module Foxy
  module Persistence
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def primary_key=(key)
        @primary_key = key.to_s
      end

      def primary_key(field_name = nil, type = :string, **opts)
        if field_name
          self.primary_key = field_name
          field(field_name, type, **opts)
        else
          @primary_key || "id"
        end
      end

      def store
        @store ||= YAML::Store.new "db/#{model_name}.store.yaml"
      end

      def find(primary_key)
        data = store.transaction { store[primary_key] }

        return unless data

        new(data, persisted: true)
      end

      def find_or_create(attrs)
        find(new(attrs, persisted: true).primary_key) || create(attrs)
      end

      def create(attrs)
        new(attrs).tap(&:save)
      end

      def all
        store.transaction { store.roots.map { |primary_key| new(store[primary_key], persisted: true) } }
      end

      # def by(attrs)
      #   store.transaction { store.roots.map { |primary_key| new(store[primary_key], persisted: true) } }
      # end

      def destroy_all
        File.delete store.path if File.exist? store.path

        true
      end
    end

    def initialize(attrs, persisted: false)
      super(attrs)
      @persisted = persisted
    end

    def store
      self.class.store
    end

    def save
      @persisted = true
      store.transaction { store[primary_key] = attributes }

      self
    end

    def destroy
      store.transaction { store.delete(primary_key) }
    end

    def primary_key
      send self.class.primary_key
    end

    def update(attrs)
      assign_attributes(attrs)
      tap(&:save)
    end

    def new?
      !persisted?
    end

    def persisted?
      !!@persisted
    end
  end
end
