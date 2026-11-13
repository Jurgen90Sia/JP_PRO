# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/parametric/dimensions'
require_relative '../../src/jp_cabinet_pro/cabinet/construction'

class TestConstructionExtensions < Minitest::Test
  def test_hdf_grooved_back_and_partitions
    v = JPCabinetPro::Parametric::Dimensions.validate(
      back_mount_type: 'hdf_grooved', panel_thickness_mm: 18, partition_count: 2
    )
    assert v.ok, v.errors.inspect
    c = JPCabinetPro::Cabinet::Construction.new(adapter: nil)
    parts = c.build_parts(v.values)
    back = parts.find { |p| p[:role] == 'back' }
    assert back, 'back part missing'
    assert_equal 4.0, back[:thickness_mm]
    assert parts.any? { |p| p[:role] == 'partition_1' }
    assert parts.any? { |p| p[:role] == 'partition_2' }
  end

  def test_plinth_and_legs_parts
    v = JPCabinetPro::Parametric::Dimensions.validate(
      plinth_height_mm: 100, legs_height_mm: 80, leg_count: 4
    )
    assert v.ok, v.errors.inspect
    c = JPCabinetPro::Cabinet::Construction.new(adapter: nil)
    parts = c.build_parts(v.values)
    assert parts.any? { |p| p[:role] == 'plinth_front' }
    assert parts.any? { |p| p[:role] == 'leg_1' }
    assert parts.any? { |p| p[:role] == 'leg_4' }
  end

  def test_custom_thickness_and_validation
    v = JPCabinetPro::Parametric::Dimensions.validate(panel_thickness_mm: 22, custom_thickness_mm: 20)
    assert v.ok
    assert_equal 20.0, v.values[:panel_thickness_mm]
    bad = JPCabinetPro::Parametric::Dimensions.validate(width_mm: 30, panel_thickness_mm: 18)
    refute bad.ok
  end
end
