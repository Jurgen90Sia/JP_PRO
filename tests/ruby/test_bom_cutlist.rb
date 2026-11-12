# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/cabinet/construction'
require_relative '../../src/jp_cabinet_pro/bom/generator'
require_relative '../../src/jp_cabinet_pro/cutlist/generator'

class TestBomCutlist < Minitest::Test
  def setup
    @construction = JPCabinetPro::Cabinet::Construction.new(adapter: nil)
    @params = {
      width_mm: 800.0, height_mm: 720.0, depth_mm: 560.0,
      panel_thickness_mm: 18.0, shelf_count: 1, rear_inset_mm: 10.0
    }
  end

  def test_build_parts_includes_shelf
    parts = @construction.build_parts(@params)
    roles = parts.map { |p| p[:role] }
    assert_includes roles, 'shelf_1'
    assert_equal 6, parts.length
  end

  def test_bom_and_cutlist_generate
    parts = @construction.build_parts(@params)
    bom = JPCabinetPro::Bom::Generator.new.generate(parts: parts, assembly_id: 'asm1')
    refute_empty bom
    assert bom.all? { |i| i[:part_id] }
    cut = JPCabinetPro::Cutlist::Generator.new.generate(bom)
    assert_equal bom.length, cut.length
    assert cut.first.key?(:barcode_qr)
  end
end
