# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/materials/engine'

class TestMaterials < Minitest::Test
  def setup
    @e = JPCabinetPro::Materials::Engine.new
  end

  def test_upsert_fetch_assign
    @e.upsert({ id: 'mat1', name: 'White', thickness_variants_mm: [18] })
    assert_equal 'White', @e.fetch('mat1')[:name]
    p = @e.assign({ role: 'side' }, 'mat1')
    assert_equal 'mat1', p[:material_id]
  end

  def test_quantities_net_gross
    parts = [
      { material_id: 'm1', thickness_mm: 18, width_mm: 1000, height_mm: 500, quantity: 2 },
      { material_id: 'm1', thickness_mm: 18, width_mm: 500, height_mm: 500, quantity: 1 },
      { material_id: 'm2', thickness_mm: 16, width_mm: 400, height_mm: 300, quantity: 1 }
    ]
    q = @e.quantities(parts, waste_factor: 0.1)
    net_m1 = q[:net].find { |r| r[:material_id] == 'm1' }
    assert_in_delta 1_250_000.0, net_m1[:area_mm2], 0.01
    gross_m1 = q[:gross].find { |r| r[:material_id] == 'm1' }
    assert_in_delta 1_375_000.0, gross_m1[:area_mm2], 0.01
    assert_equal 0.1, q[:waste_factor]
  end

  def test_quantities_rejects_negative_waste
    assert_raises(ArgumentError) { @e.quantities([], waste_factor: -0.1) }
  end
end
