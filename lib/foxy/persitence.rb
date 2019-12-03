# frozen_string_literal: true

module Foxy
  module Persistence
    def self.included(base)
      base.extend(ClassMethods)
      base.config[:class_key] = :class
      base.config[:primary_key] = "id"
    end

    module ClassMethods
      def primary_key=(key)
        @repo = nil
        config[:primary_key] = key.to_s
      end

      def primary_key(field_name = nil, type = :string, **opts)
        if field_name
          self.primary_key = field_name
          field(field_name, type, **opts)
        else
          config[:primary_key].to_s
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
        @storage ||= Foxy::Env.current.storage
      end

      def class_key=(val)
        @repo = nil
        @class_key = val
      end

      def class_key
        config[:class_key]
      end

      def repository
        @repo ||= config[:repository_class].new(collection: model_name,
                                                pk: primary_key,
                                                storage: storage,
                                                model: self,
                                                class_key: class_key)
      end

      def find(primary_key)
        repository.find(primary_key)
      end

      def find_or_create(attrs)
        repository.find_or_create(attrs)
      end

      def create(attrs)
        repository.create(attrs)
      end

      def all
        repository.all
      end

      def destroy_all
        repository.destroy_all
      end

      def from_database(attrs)
        new(attrs, persisted: true)
      end
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
      send(self.class.primary_key)
    end

    def update(attrs)
      assign_attributes(attrs)
      tap(&:save)
    end

    def persisted!
      @persisted = true
    end

    def new?
      !persisted?
    end

    def persisted?
      !!@persisted
    end
  end
end
