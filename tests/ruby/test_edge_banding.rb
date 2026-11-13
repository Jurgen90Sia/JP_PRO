# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/edge_banding/engine'

class TestEdgeBanding < Minitest::Test
  def test_total_length
    e = JPCabinetPro::EdgeBanding::Engine.new
    parts = [
      {
        width_mm: 800.0, height_mm: 720.0, quantity: 1,
        edge_banding: {
          left: { material_id: 'eb1', thickness_mm: 1.0 },
          right: { material_id: 'eb1', thickness_mm: 1.0 },
          top: nil, bottom: nil
        }
      }
    ]
    res = e.total_length(parts)
    row = res.find { |r| r[:material_id] == 'eb1' }
    assert_equal 1440.0, row[:length_mm]
  end
end
