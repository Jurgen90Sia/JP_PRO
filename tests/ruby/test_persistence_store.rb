# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../../src/jp_cabinet_pro/persistence/store'

class TestPersistenceStore < Minitest::Test
  def test_serialize_deserialize_migrate
    json = JPCabinetPro::Persistence::Store.serialize({ 'a' => 1 })
    data = JPCabinetPro::Persistence::Store.deserialize(json)
    assert_equal 1, data['schema_version']
    assert_equal 1, data['data']['a']
  end

  def test_save_and_load
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'snap.json')
      r = JPCabinetPro::Persistence::Store.save(path, { 'x' => 'y' })
      assert r[:ok]
      l = JPCabinetPro::Persistence::Store.load(path)
      assert l[:ok]
      assert_equal 'y', l[:data]['data']['x']
    end
  end
end
