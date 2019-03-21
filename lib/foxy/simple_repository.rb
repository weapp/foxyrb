# frozen_string_literal: true

require "yaml/store"

require "foxy/storages/yaml"

module Foxy
  class SimpleRepository < BaseRepository
    def store
      @store ||= YAML::Store.new "db/#{model_name}.store.yaml"
    end

    def find(primary_key)
      data = store.transaction { store[primary_key] }

      return unless data

      deserialize(data)
    end

    def find_or_create(attrs)
      find(deserialize(attrs).primary_key) || create(attrs)
    end

    def create(attrs)
      save(deserialize(attrs))
    end

    def all
      store.transaction { store.roots.map { |primary_key| deserialize(store[primary_key]) } }
    end

    def destroy_all
      File.delete path if File.exist? path

      true
    end

    def save(entity)
      store.transaction { store[entity.primary_key] = serialize(entity) }
      entity.persisted!
      entity
    end

    def destroy(entity)
      store.transaction { store.delete(entity.primary_key) }
    end

    private

    def store
      @store ||= YAML::Store.new(path)
    end

    def store_folder
      "db"
    end

    def path
      "#{store_folder}/#{collection}.store.yaml"
    end
  end
end
