# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/commands/edit_dimensions'
require_relative '../../src/jp_cabinet_pro/diagnostics/revision_tracker'

class TestVerticalSlice < Minitest::Test
  def setup
    @cmd = JPCabinetPro::Commands::EditDimensions.new(adapter: nil)
    @input = {
      width_mm: 900.0, height_mm: 800.0, depth_mm: 560.0,
      panel_thickness_mm: 18.0, shelf_count: 2,
      top_construction: 'top_between_sides', bottom_construction: 'bottom_between_sides',
      back_mount_type: 'recessed_back', groove_depth_mm: 8.0, rear_inset_mm: 10.0
    }
  end

  def test_preview_valid
    r = @cmd.preview(@input)
    assert r.ok, r.errors.inspect
    assert r.preview[:parts].length >= 7
    assert r.preview[:params][:internal]
  end

  def test_preview_invalid
    r = @cmd.preview(width_mm: -1)
    refute r.ok
  end

  def test_apply_generates_bom_cutlist_view_and_invalidations
    r = @cmd.apply(@input, assembly_id: 'asm_test', revision: 2, waste_factor: 0.1)
    assert r.ok, r.errors.inspect
    assert r.applied
    refute_empty r.bom
    assert_equal r.bom.length, r.cutlist.length
    assert_equal :front, r.view[:type]
    assert r.view_svg.is_a?(String)
    assert_includes r.view_svg, '<svg'
    assert_equal 2, r.view[:revision]
    assert_includes r.invalidations, 'nesting'
    assert_includes r.invalidations, 'drawings'
    assert r.snapshot
    assert_equal 2, r.snapshot[:revision]
    assert_equal r.view_svg, r.snapshot[:view_svg]
    assert r.materials
    assert_equal 0.1, r.materials[:waste_factor]
    assert r.edge_banding.is_a?(Array)
    assert_nil r.nesting
  end

  def test_apply_with_nesting_sheets
    sheets = [{ id: 'S1', w: 2800.0, h: 2070.0, kerf: 3.0, trim: 10.0, material: nil, thickness: 18.0 }]
    r = @cmd.apply(@input, assembly_id: 'asm_test', revision: 3, nesting_sheets: sheets, nesting_strategy: 'maxrects')
    assert r.ok, r.errors.inspect
    assert r.nesting
    assert r.nesting[:ok]
    assert_equal 'maxrects', r.nesting[:strategy]
    assert r.nesting[:placements].is_a?(Array)
    assert r.nesting.key?(:utilization)
    assert_equal r.nesting, r.snapshot[:nesting]
  end

  def test_apply_updates_revision_tracker
    tracker = JPCabinetPro::Diagnostics::RevisionTracker.new
    cmd = JPCabinetPro::Commands::EditDimensions.new(adapter: nil, revision_tracker: tracker)
    r = cmd.apply(@input, assembly_id: 'asm_rt', revision: 5)
    assert r.ok, r.errors.inspect
    assert r.revision_state
    assert_equal 5, r.revision_state[:revision]
    assert_equal true, r.revision_state[:valid][:bom]
    assert_equal true, r.revision_state[:valid][:drawings]
    assert_equal false, r.revision_state[:valid][:nesting]
    assert_includes r.revision_state[:stale], :reports
    assert_equal r.revision_state, r.snapshot[:metadata][:revision_state]
  end

  def test_apply_with_fronts_drawers_hardware
    input = @input.merge(
      fronts: { type: 'double', split: 'vertical', gap_mm: 2, perimeter_gap_mm: 2, front_thickness_mm: 18 },
      drawers: { count: 2, gap_mm: 2, perimeter_gap_mm: 2, slide_clearance_mm: 12, box_depth_mm: 500 },
      hardware: [{ id: 'h1', type: 'hinge', quantity: 4 }]
    )
    r = @cmd.apply(input, assembly_id: 'asm_fd', revision: 1)
    assert r.ok, r.errors.inspect
    assert_equal 2, r.fronts.length
    assert_equal 2, r.drawers.length
    assert_equal 1, r.hardware.length
    # carcass(5+2 shelves)=7 + 2 fronts + 2*5 drawer parts = 19
    assert_operator r.bom.length, :>=, 19
    assert_equal r.fronts, r.snapshot[:metadata][:fronts]
    assert_equal r.hardware, r.snapshot[:metadata][:hardware]
  end
end
