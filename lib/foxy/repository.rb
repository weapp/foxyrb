# frozen_string_literal: true

require "yaml/store"

require "foxy/storages/yaml"

module Foxy
  class Repository < BaseRepository
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
  end
end
