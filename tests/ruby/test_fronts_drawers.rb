# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/doors/front_engine'
require_relative '../../src/jp_cabinet_pro/drawers/engine'

class TestFrontsDrawers < Minitest::Test
  def test_front_validate_defaults
    r = JPCabinetPro::Doors::FrontEngine.new.validate({})
    assert r.ok, r.errors.inspect
    assert_equal 'single', r.config[:type]
  end

  def test_front_rejects_invalid
    r = JPCabinetPro::Doors::FrontEngine.new.validate(type: 'bogus')
    refute r.ok
  end

  def test_drawer_validate_defaults
    r = JPCabinetPro::Drawers::Engine.new.validate({})
    assert r.ok, r.errors.inspect
    assert_equal 1, r.config[:count]
  end

  def test_drawer_rejects_invalid
    r = JPCabinetPro::Drawers::Engine.new.validate(count: 0)
    refute r.ok
  end
end
