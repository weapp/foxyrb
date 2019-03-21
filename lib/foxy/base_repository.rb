# frozen_string_literal: true

require "yaml/store"

require "foxy/storages/yaml"

module Foxy
  class BaseRepository
    attr_reader :pk, :collection, :storage, :model, :class_key

    def initialize(collection: nil, pk: :id, storage: nil, model: true, class_key: :class)
      @collection = collection || class_name.downcase
      @pk = pk
      @storage = storage || f.storage
      @model = model == true ? find_model : model
      @class_key = class_key
    end

    def find(primary_key)
      raise NotImplementedError
    end

    def find_or_create(attrs)
      raise NotImplementedError
    end

    def create(attrs)
      raise NotImplementedError
    end

    def all
      raise NotImplementedError
    end

    def destroy_all
      raise NotImplementedError
    end

    def save(entity)
      raise NotImplementedError
    end

    def destroy(entity)
      raise NotImplementedError
    end

    private

    def serialize(entity)
      return merge_class(entity.as_json, model) if model && entity.is_a?(Hash)
      raise "#{entity} is not a #{model.class}" if model && !entity.is_a?(model)

      merge_class(entity.try([:serializable_hash], [:as_json], [:to_h]), entity.class)
    end

    def merge_class(hash_, model)
      return hash_ unless model.name

      hash_.merge(class_key => model.name)
    end

    def deserialize(hash)
      return if hash.nil?

      type = hash.delete(class_key)
      klass = (model || Object.const_get(type))
      klass.try([:from_database, hash], [:new, hash])
    end

    def deserialize_collection(collection)
      collection.map { |e| deserialize(e) }
    end

    def find_model
      Object.const_get(class_name)
    end

    def class_name
      self.class.name.split("::").last
    end
  end
end
