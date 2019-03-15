# frozen_string_literal: true

require "yaml/store"

require "foxy/storages/yaml"

module Foxy
  class Repository
    attr_reader :pk, :collection, :storage, :model, :class_key

    def initialize(collection: nil, pk: :id, storage: Foxy::Storages::Yaml, model: true, class_key: :class)
      @collection = collection || class_name.downcase
      @pk = pk
      @storage = storage
      @model = model == true ? find_model : model
      @class_key = class_key
    end

    def find_or_create(entity)
      deserialize(find_or_create!(serialize(entity)))
    end

    def find(id)
      deserialize(find!(id))
    end

    def all
      deserialize_collection(store.all)
    end

    def where(query = {})
      deserialize_collection(where!(query))
    end

    def create(entity)
      deserialize(create!(serialize(entity)))
    end

    def update(entity, attrs)
      deserialize(update!(serialize(entity), attrs))
    end

    def save(entity)
      deserialize(save!(serialize(entity)))
    end

    def destroy(entity)
      destroy!(serialize(entity))
    end

    def destroy_all
      store.destroy_all
    end

    private

    def store
      @store ||= storage.new(collection)
    end

    def serialize(entity)
      return entity.as_json.merge(class_key => model.name) if model && entity.is_a?(Hash)
      raise "#{entity} is not a #{model.class}" if model && !entity.is_a?(model)

      entity.as_json.merge(class_key => entity.class.name)
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

    def where!(query)
      store.where(query)
    end

    def create!(attrs)
      store.add(attrs)
    end

    def find!(id)
      where!(pk => id).first
    end

    def find_or_create!(attrs)
      find!(attrs[pk]) || create!(attrs)
    end

    def save!(attrs)
      destroy!(attrs)
      create!(attrs)
    end

    def update!(attrs, more)
      store.update(attrs) { |item| item.merge!(more) }.first
    end

    def destroy!(attrs)
      store.delete(pk => attrs[pk])
    end

    def find_model
      Object.const_get(class_name)
    end

    def class_name
      self.class.name.split("::").last
    end
  end
end
