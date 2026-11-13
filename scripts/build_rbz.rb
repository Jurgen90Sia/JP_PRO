#!/usr/bin/env ruby
# frozen_string_literal: true

# Reproducible RBZ packaging scaffold for JP Cabinet PRO.
# Requires Ruby with 'zip' gem and execution in a prepared release environment.
# Release gate: do not claim production-ready; run required tests/verification first.

require 'fileutils'
require 'pathname'

begin
  require 'zip'
rescue LoadError
  warn 'zip gem not available; cannot build RBZ in this environment'
  exit 2
end

ROOT = Pathname.new(__dir__).join('..').expand_path
DIST = ROOT.join('dist')
VERSION = ENV.fetch('JP_CABINET_PRO_VERSION', '0.1.0-dev')

INCLUDE = [
  'jp_cabinet_pro.rb',
  'src',
  'ui',
  'icons',
  'config',
  'README.md',
  'docs'
].freeze

def main
  FileUtils.mkdir_p(DIST)
  out = DIST.join("jp_cabinet_pro-#{VERSION}.rbz")
  FileUtils.rm_f(out)
  Zip::File.open(out.to_s, Zip::File::CREATE) do |zip|
    INCLUDE.each do |rel|
      path = ROOT.join(rel)
      next unless path.exist?
      if path.directory?
        Dir.glob(path.join('**', '*')).each do |f|
          next if File.directory?(f)
          add(zip, ROOT, Pathname.new(f))
        end
      else
        add(zip, ROOT, path)
      end
    end
  end
  puts "Built: #{out}"
end

def add(zip, root, file)
  entry = file.relative_path_from(root).to_s
  zip.add(entry, file.to_s) unless zip.find_entry(entry)
end

main if $PROGRAM_NAME == __FILE__
