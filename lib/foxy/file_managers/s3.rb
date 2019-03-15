# frozen_string_literal: true

begin
  require "aws-sdk"
rescue LoadError
end

if defined?(Aws)
  module Foxy
    module FileManagers
      class S3
        attr_accessor :bucket

        def initialize(opts)
          @bucket = Aws::S3::Bucket.new(opts.fetch(:bucket))
        end

        def put(path, input)
          bucket.put_object(key: path, body: input)
        end

        def get(path)
          # ["<html><meta http-equiv='refresh' content='0; url=#{url_for(path)}' /></html>"]
          # [302, {location: url_for(path)}, []]
          bucket.object(path).get.body
        rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
          nil
        end

        def delete(path)
          objects = bucket.objects(prefix: path).map { |obj| { key: obj.key } }
          bucket.delete_objects(delete: {  objects: objects }) unless objects.empty?
        end

        private

        def url_for(path)
          bucket.object(path).presigned_url(:get, expires_in: 3600)
        end
      end

      Foxy.file_adapters[:s3] = S3
    end
  end
end
