# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../../src/jp_cabinet_pro/commands/edit_dimensions'
require_relative '../../src/jp_cabinet_pro/commands/plan_nesting'
require_relative '../../src/jp_cabinet_pro/commands/generate_report'
require_relative '../../src/jp_cabinet_pro/commands/export_cnc'
require_relative '../../src/jp_cabinet_pro/commands/manage_library'

class TestCommandsIntegration < Minitest::Test
  def test_plan_nesting_command
    cmd = JPCabinetPro::Commands::PlanNesting.new
    parts = [{ id: 'A', w: 400, h: 300, qty: 1, material: 'm1', thickness: 18, grain: 'none' }]
    sheets = [{ id: 'S1', w: 1000, h: 1000, kerf: 0, trim: 0, material: 'm1', thickness: 18 }]
    r = cmd.execute(parts: parts, sheets: sheets, strategy: 'maxrects')
    assert r.ok, r.errors.inspect
    assert r.nesting[:placements].length >= 1
  end

  def test_report_and_exports_from_snapshot
    dim = JPCabinetPro::Commands::EditDimensions.new
    input = { width_mm: 800, height_mm: 720, depth_mm: 560, panel_thickness_mm: 18, shelf_count: 1 }
    applied = dim.apply(input, revision: 1)
    assert applied.ok

    rep = JPCabinetPro::Commands::GenerateReport.new.execute(snapshot: applied.snapshot)
    assert rep.ok, rep.errors.inspect
    assert_includes rep.html, 'Production Report'

    exp = JPCabinetPro::Commands::ExportCnc.new
    csv = exp.export_csv(applied.cutlist)
    assert csv.ok
    assert_includes csv.export.content, 'part_id'

    # nesting DXF via command (separate nesting result)
    nest = JPCabinetPro::Commands::PlanNesting.new.execute(
      parts: [{ id: 'P', w: 200, h: 200, qty: 1, material: 'm', thickness: 18, grain: 'none' }],
      sheets: [{ id: 'S1', w: 1000, h: 1000, kerf: 0, trim: 0, material: 'm', thickness: 18 }]
    )
    dxf = exp.export_nesting_dxf(nest.nesting, sheets: [{ id: 'S1', w: 1000, h: 1000 }])
    assert dxf.ok, dxf.errors.inspect
    assert_includes dxf.export.content, 'SECTION'
  end

  def test_manage_library_command
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'lib.json')
      cmd = JPCabinetPro::Commands::ManageLibrary.new(index_path: path)
      u = cmd.upsert({ id: 'c1', name: 'Cabinet 1', category: 'Base' })
      assert u.ok
      s = cmd.search('Cabinet')
      assert s.ok
      assert s.result.items.any? { |i| i[:id] == 'c1' }
    end
  end
end
