# frozen_string_literal: true

require 'json'
require 'time'
require 'fileutils'

module JPCabinetPro
  module Library
    # Component library manager. Original/user-created components only; no copyrighted commercial assets.
    # JSON-backed index with lazy in-memory cache.
    class Manager
      Result = Struct.new(:ok, :items, :item, :errors, :status, keyword_init: true)

      def initialize(index_path: nil, auto_load: true)
        @index_path = index_path
        @data = default_data
        @loaded = false
        @dirty = false
        load if auto_load && @index_path && File.exist?(@index_path)
      end

      attr_reader :index_path

      def load
        return Result.new(ok: false, errors: ['no_index_path'], status: 'NO_PATH') unless @index_path
        return Result.new(ok: false, errors: ['index_not_found'], status: 'NOT_FOUND') unless File.exist?(@index_path)
        content = JSON.parse(File.read(@index_path), symbolize_names: true)
        @data = normalize_data(content)
        @loaded = true
        @dirty = false
        Result.new(ok: true, items: components, status: 'LOADED')
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message], status: 'LOAD_ERROR')
      end

      def save(path = @index_path)
        return Result.new(ok: false, errors: ['no_index_path'], status: 'NO_PATH') unless path
        FileUtils.mkdir_p(File.dirname(path))
        payload = @data.merge(updated_at: Time.now.utc.iso8601)
        File.write(path, JSON.pretty_generate(payload))
        @index_path = path
        @dirty = false
        Result.new(ok: true, status: 'SAVED')
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message], status: 'SAVE_ERROR')
      end

      def components
        @data[:components] || []
      end

      def categories
        components.map { |c| c[:category] }.compact.uniq.sort
      end

      def search(query = nil, category: nil, favorites_only: false, recent_only: false, limit: nil)
        items = components
        if query && !query.to_s.strip.empty?
          q = query.to_s.downcase
          items = items.select do |c|
            [c[:id], c[:name], c[:category], *(c[:tags] || [])].compact.any? { |v| v.to_s.downcase.include?(q) }
          end
        end
        items = items.select { |c| c[:category] == category } if category
        items = items.select { |c| c[:favorite] } if favorites_only
        if recent_only
          items = items.sort_by { |c| c[:last_used_at].to_s }.reverse
        end
        items = items.first(limit.to_i) if limit
        Result.new(ok: true, items: items, status: 'OK')
      end

      def find(id)
        item = components.find { |c| c[:id].to_s == id.to_s }
        Result.new(ok: !item.nil?, item: item, errors: item ? [] : ['not_found'], status: item ? 'OK' : 'NOT_FOUND')
      end

      def upsert(component)
        c = symbolize(component)
        return Result.new(ok: false, errors: ['id_required']) if c[:id].to_s.empty?
        c[:name] ||= c[:id]
        c[:tags] = Array(c[:tags])
        c[:favorite] = !!c[:favorite]
        c[:source] ||= 'user'
        c[:created_at] ||= Time.now.utc.iso8601
        c[:updated_at] = Time.now.utc.iso8601
        idx = components.index { |x| x[:id].to_s == c[:id].to_s }
        if idx
          @data[:components][idx] = components[idx].merge(c)
        else
          @data[:components] << c
        end
        @dirty = true
        find(c[:id])
      end

      def remove(id)
        before = components.length
        @data[:components].reject! { |c| c[:id].to_s == id.to_s }
        @dirty = true if components.length != before
        Result.new(ok: components.length != before, status: components.length != before ? 'REMOVED' : 'NOT_FOUND')
      end

      def mark_favorite(id, value = true)
        r = find(id)
        return r unless r.ok
        upsert(r.item.merge(favorite: !!value))
      end

      def touch_recent(id)
        r = find(id)
        return r unless r.ok
        upsert(r.item.merge(last_used_at: Time.now.utc.iso8601))
      end

      def favorites
        search(nil, favorites_only: true)
      end

      def recent(limit: 20)
        search(nil, recent_only: true, limit: limit)
      end

      # Import component metadata from JSON file (original/user data). Does not bundle copyrighted assets.
      def import(path)
        return Result.new(ok: false, errors: ['file_not_found'], status: 'NOT_FOUND') unless File.exist?(path)
        payload = JSON.parse(File.read(path), symbolize_names: true)
        items = if payload.is_a?(Array)
                  payload
                elsif payload.is_a?(Hash) && payload[:components].is_a?(Array)
                  payload[:components]
                elsif payload.is_a?(Hash) && payload[:component].is_a?(Hash)
                  [payload[:component]]
                elsif payload.is_a?(Hash)
                  [payload]
                else
                  []
                end
        imported = []
        items.each do |it|
          r = upsert(it)
          imported << r.item if r.ok
        end
        Result.new(ok: true, items: imported, status: 'IMPORTED')
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message], status: 'IMPORT_ERROR')
      end

      # Export component metadata to JSON file.
      def export(id, path)
        r = find(id)
        return r unless r.ok
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, JSON.pretty_generate({ component: r.item, exported_at: Time.now.utc.iso8601 }))
        Result.new(ok: true, item: r.item, status: 'EXPORTED')
      rescue StandardError => e
        Result.new(ok: false, errors: [e.message], status: 'EXPORT_ERROR')
      end

      # SketchUp insertion/replacement require runtime; provide explicit status.
      def insert(_component_id, _target = nil)
        Result.new(ok: false, status: 'SKETCHUP_RUNTIME_REQUIRED', errors: ['sketchup_runtime_required'])
      end

      def replace(_instance, _component_id)
        Result.new(ok: false, status: 'SKETCHUP_RUNTIME_REQUIRED', errors: ['sketchup_runtime_required'])
      end

      private

      def default_data
        { schema_version: 1, components: [], created_at: Time.now.utc.iso8601 }
      end

      def normalize_data(content)
        h = symbolize(content)
        h[:schema_version] ||= 1
        h[:components] = Array(h[:components]).map { |c| symbolize(c) }
        h
      end

      def symbolize(obj)
        case obj
        when Hash
          obj.each_with_object({}) { |(k, v), out| out[k.to_sym] = symbolize(v) }
        when Array
          obj.map { |v| symbolize(v) }
        else
          obj
        end
      end
    end
  end
end
