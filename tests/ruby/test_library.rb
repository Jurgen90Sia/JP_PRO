# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../../src/jp_cabinet_pro/library/manager'

class TestLibrary < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @path = File.join(@dir, 'index.json')
    @lib = JPCabinetPro::Library::Manager.new(index_path: @path, auto_load: false)
  end

  def teardown
    FileUtils.remove_entry(@dir) if @dir && Dir.exist?(@dir)
  end

  def test_upsert_search_find
    @lib.upsert(id: 'cab1', name: 'Base Cabinet', category: 'Cabinets', tags: ['base', '600'])
    @lib.upsert(id: 'cab2', name: 'Wall Cabinet', category: 'Cabinets', tags: ['wall'])
    r = @lib.search('base')
    assert r.ok
    assert_equal 1, r.items.length
    assert_equal 'cab1', r.items.first[:id]
    f = @lib.find('cab2')
    assert f.ok
    assert_equal 'Wall Cabinet', f.item[:name]
  end

  def test_favorites_and_recent
    @lib.upsert(id: 'a', name: 'A')
    @lib.mark_favorite('a', true)
    assert_equal 1, @lib.favorites.items.length
    @lib.touch_recent('a')
    assert_equal 'a', @lib.recent.items.first[:id]
  end

  def test_save_load_import_export
    @lib.upsert(id: 'x', name: 'X', category: 'User')
    s = @lib.save
    assert s.ok
    lib2 = JPCabinetPro::Library::Manager.new(index_path: @path)
    assert lib2.find('x').ok

    exp = File.join(@dir, 'x.json')
    e = @lib.export('x', exp)
    assert e.ok
    assert File.exist?(exp)

    lib3 = JPCabinetPro::Library::Manager.new(index_path: nil, auto_load: false)
    im = lib3.import(exp)
    assert im.ok
    assert lib3.find('x').ok
  end

  def test_insert_requires_sketchup
    r = @lib.insert('x')
    refute r.ok
    assert_equal 'SKETCHUP_RUNTIME_REQUIRED', r.status
  end
end
