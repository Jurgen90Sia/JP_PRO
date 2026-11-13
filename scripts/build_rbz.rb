#!/usr/bin/env ruby
# frozen_string_literal: true

# Reproducible RBZ packaging for JP Cabinet PRO.
# Uses the system `zip` CLI (Ruby zip gem not required).
# Release gate: runs test_all.sh before packaging; fails if any test/JS check fails.

require 'fileutils'
require 'pathname'
require 'shellwords'

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

EXCLUDE_PATTERNS = %w[/.git/ /\.git/ /dist/ /node_modules/].freeze

def excluded?(path)
  path_str = path.to_s
  EXCLUDE_PATTERNS.any? { |p| path_str.include?(p) }
end

def main
  unless system_tests_pass?
    abort 'Release gate failed: test_all.sh did not pass. Do not build RBZ.'
  end

  if system('zip --version >/dev/null 2>&1').nil? || !$?.success?
    warn 'system `zip` CLI not available; cannot build RBZ'
    exit 2
  end

  FileUtils.mkdir_p(DIST)
  out = DIST.join("jp_cabinet_pro-#{VERSION}.rbz")
  FileUtils.rm_f(out)

  FileUtils.chdir(ROOT) do
    entries = INCLUDE.flat_map { |rel| collect(ROOT.join(rel)) }.sort
    cmd = ['zip', '-r', out.to_s] + entries.map(&:to_s).map(&:shellescape)
    unless system(*cmd)
      warn 'zip command failed'
      exit 1
    end
  end
  puts "Built: #{out} (#{out.size} bytes)"
end

def system_tests_pass?
  script = ROOT.join('scripts', 'test_all.sh')
  return false unless script.exist?
  system('bash', script.to_s, out: '/dev/null', err: '/dev/null')
end

def collect(dir)
  return [] unless dir.exist?
  files = []
  if dir.directory?
    dir.each_child do |child|
      next if excluded?(child)
      if child.directory?
        files.concat(collect(child))
      else
        files << child
      end
    end
  else
    files << dir
  end
  files
end

main if $PROGRAM_NAME == __FILE__
