# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/commands/edit_dimensions'

class TestVerticalSlice < Minitest::Test
  def setup
    @cmd = JPCabinetPro::Commands::EditDimensions.new(adapter: nil)
    @input = {
      width_mm: 900.0, height_mm: 800.0, depth_mm: 560.0,
      panel_thickness_mm: 18.0, shelf_count: 2,
      back_mount_type: 'recessed_back', groove_depth_mm: 8.0, rear_inset_mm: 10.0
    }
  end

  def test_preview_valid
    r = @cmd.preview(@input)
    assert r.ok, r.errors.inspect
    assert r.preview[:parts].length >= 5
  end

  def test_preview_invalid
    r = @cmd.preview(width_mm: -1)
    refute r.ok
  end

  def test_apply_generates_bom_cutlist_view
    r = @cmd.apply(@input, assembly_id: 'asm_test', revision: 1)
    assert r.ok, r.errors.inspect
    assert r.applied
    refute_empty r.bom
    assert_equal r.bom.length, r.cutlist.length
    assert_equal :front, r.view[:type]
    assert_equal 1, r.view[:revision]
  end
end
