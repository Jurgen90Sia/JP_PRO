# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/parametric/dimensions'

class TestDimensions < Minitest::Test
  def test_valid_defaults_compute_internal
    r = JPCabinetPro::Parametric::Dimensions.validate({})
    assert r.ok, r.errors.inspect
    assert_equal 764.0, r.values[:internal][:internal_width_mm]
    assert_equal 684.0, r.values[:internal][:internal_height_mm]
  end

  def test_rejects_non_positive
    r = JPCabinetPro::Parametric::Dimensions.validate(width_mm: 0)
    refute r.ok
    assert r.errors.any? { |e| e.include?('width_mm') }
  end

  def test_rejects_negative_shelves
    r = JPCabinetPro::Parametric::Dimensions.validate(shelf_count: -1)
    refute r.ok
  end
end
