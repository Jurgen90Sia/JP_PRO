# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/drawing/technical_view'
require_relative '../../src/jp_cabinet_pro/report/generator'

class TestDrawingReport < Minitest::Test
  def setup
    @drawing = JPCabinetPro::Drawing::TechnicalView.new
    @report = JPCabinetPro::Report::Generator.new
    @params = { width_mm: 800.0, height_mm: 720.0, depth_mm: 560.0 }
    @parts = [
      { part_id: 'p1', name: 'side_left', role: 'side', width_mm: 18, height_mm: 720, thickness_mm: 560 },
      { part_id: 'p2', name: 'top', role: 'top', width_mm: 764, height_mm: 18, thickness_mm: 560 }
    ]
  end

  def test_drawing_view_model_and_svg
    vm = @drawing.generate(parts: @parts, cabinet_params: @params, view_type: :front, revision: 2)
    assert_equal :front, vm[:type]
    assert_equal 2, vm[:parts].length
    svg = @drawing.to_svg(vm, paper: 'A4', title: 'JP Cabinet PRO')
    assert_includes svg, '<svg'
    assert_includes svg, 'xmlns="http://www.w3.org/2000/svg"'
    assert_includes svg, 'JP Cabinet PRO'
    assert_includes svg, '800'
  end

  def test_drawing_rejects_unsupported_view
    assert_raises(ArgumentError) { @drawing.generate(parts: [], cabinet_params: @params, view_type: :bogus) }
  end

  def test_report_from_snapshot
    vm = @drawing.generate(parts: @parts, cabinet_params: @params, view_type: :front, revision: 3)
    svg = @drawing.to_svg(vm)
    snap = {
      snapshot_version: 1, revision: 3, project_id: 'prj', assembly_id: 'asm',
      params: @params,
      bom: @parts,
      cutlist: [{ part_id: 'p1', part_name: 'side_left', length: 720, width: 18, quantity: 1 }],
      materials: { net: [{ material_id: 'm1', thickness_mm: 18, area_mm2: 1000 }], gross: [{ material_id: 'm1', thickness_mm: 18, area_mm2: 1100 }], waste_factor: 0.1 },
      edge_banding: [{ material_id: 'eb1', thickness_mm: 1.0, length_mm: 1440 }],
      nesting: { ok: true, strategy: 'maxrects', validated: true, utilization: 0.5, sheets_used: ['S1'], placements: [{ sheet_id: 'S1', part_id: 'p1', x: 10, y: 10, w: 100, h: 200, rotated: false, validated: true }], unplaced: [], cut_length_status: 'NOT_IMPLEMENTED' },
      view: vm,
      view_svg: svg
    }
    r = @report.generate(snap)
    assert r.ok, r.errors.inspect
    assert r.report[:project][:revision] == 3
    assert_includes r.html, 'Production Report'
    assert_includes r.html, 'side_left'
    assert_includes r.html, 'Cut List'
    assert_includes r.html, 'Nesting'
    assert_includes r.html, '<svg'
  end

  def test_report_rejects_empty_snapshot
    r = @report.generate(nil)
    refute r.ok
  end
end
