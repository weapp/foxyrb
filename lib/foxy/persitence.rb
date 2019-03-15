# frozen_string_literal: true

module Foxy
  module Persistence
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def primary_key=(key)
        @repo = nil
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

      def model_name=(val)
        @repo = nil
        super
      end

      def storage=(val)
        @repo = nil
        @storage = val
      end

      def storage
        @storage ||= Foxy::Storages::Yaml
      end

      def class_key=(val)
        @repo = nil
        @class_key = val
      end

      def class_key
        @class_key ||= :class
      end

      def repository
        @repo ||= Foxy::Repository.new(collection: model_name,
                                       pk: primary_key,
                                       storage: storage,
                                       model: self,
                                       class_key: class_key)
      end

      def find(primary_key); repository.find(primary_key); end
      def find_or_create(attrs); repository.find_or_create(attrs); end
      def create(attrs); repository.create(attrs); end
      def all; repository.all; end
      def destroy_all; repository.destroy_all; end
    end

    def from_database(attrs)
      new(attrs, persisted: true)
    end

    def initialize(attrs, persisted: false)
      super(attrs)
      @persisted = persisted
    end

    def repository
      self.class.repository
    end

    def save
      @persisted = true
      repository.save(self)
      self
    end

    def destroy
      repository.destroy(self)
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
