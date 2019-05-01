# frozen_string_literal: true

module Foxy
  class HtmlResponse
    attr_accessor :html, :params

    def initialize(html, params)
      @html = html
      @params = params
    end

    def foxy
      @foxy ||= Foxy::Html.new(@html)
    end

    def clean
      @clean ||= foxy.clean(allow: %w[alt src href title class])
    end

    protected

    def is_number(hash, key)
      hash[key] = hash[key].try_first(:gsub, ",", "").try_first(:to_i) if hash[key]
    end

    def is_list(hash, key, sep = /\s*,\s*/)
      return if hash[key].is_a? Array

      hash[key] = hash[key].to_s.split(sep)
    end
  end
end
