# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/hardware/engine'

class TestHardware < Minitest::Test
  def setup
    @e = JPCabinetPro::Hardware::Engine.new
  end

  def test_validate_and_bom_lines
    items = [
      { id: 'h1', type: 'hinge', catalog_ref: 'blum_x', quantity: 2, placement: { panel: 'door_left' } },
      { id: 'h2', type: 'handle', quantity: 1 }
    ]
    v = @e.validate(items)
    assert v[:ok], v[:errors].inspect
    assert v[:warnings].any? { |w| w.include?('catalog_ref') }
    lines = @e.bom_lines(items)
    assert_equal 2, lines.length
    assert_equal 2, lines.first[:quantity]
  end

  def test_aggregate_bom
    items = [
      { type: 'hinge', catalog_ref: 'c1', quantity: 2, placement: { side: 'l' } },
      { type: 'hinge', catalog_ref: 'c1', quantity: 2, placement: { side: 'l' } },
      { type: 'hinge', catalog_ref: 'c1', quantity: 1, placement: { side: 'r' } }
    ]
    agg = @e.aggregate_bom(items)
    assert_equal 2, agg.length
    left = agg.find { |x| x[:placement] == { side: 'l' } }
    assert_equal 4, left[:quantity]
  end

  def test_rejects_invalid_quantity
    v = @e.validate([{ type: 'hinge', quantity: 0 }])
    refute v[:ok]
  end
end
