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

  def test_front_configure_layout_double
    e = JPCabinetPro::Doors::FrontEngine.new
    r = e.configure({ width_mm: 800, height_mm: 720 }, { type: 'double', split: 'vertical', gap_mm: 2, perimeter_gap_mm: 2 })
    assert r.ok, r.errors.inspect
    assert_equal 2, r.fronts.length
    assert r.fronts.all? { |f| f[:width_mm] > 0 && f[:height_mm] > 0 }
    total_w = r.fronts.sum { |f| f[:width_mm] } + 2.0
    assert_in_delta 796.0, total_w, 0.01
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

  def test_drawer_configure_layout
    e = JPCabinetPro::Drawers::Engine.new
    r = e.configure({ width_mm: 600, height_mm: 720, depth_mm: 560 }, { count: 3, gap_mm: 2, perimeter_gap_mm: 2, slide_clearance_mm: 12, box_depth_mm: 500 })
    assert r.ok, r.errors.inspect
    assert_equal 3, r.drawers.length
    assert r.drawers.all? { |d| d[:parts].length == 5 } # front + 4 box parts
    assert r.drawers.all? { |d| d[:box][:width_mm] <= 596.0 }
  end
end
