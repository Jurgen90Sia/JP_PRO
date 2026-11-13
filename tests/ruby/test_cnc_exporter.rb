# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/cnc/exporter'

class TestCncExporter < Minitest::Test
  def setup
    @e = JPCabinetPro::Cnc::Exporter.new
  end

  def test_generic_csv
    rows = [{ part_id: 'p1', length: 720, width: 564 }, { part_id: 'p2', length: 100, width: 200 }]
    r = @e.export_generic_csv(rows)
    assert r.ok
    assert_equal 'csv', r.format
    assert_includes r.content, 'part_id'
    assert_includes r.content, 'p1'
    assert_includes r.note, 'not a verified CNC program'
  end

  def test_generic_dxf_nesting
    nesting = {
      placements: [
        { sheet_id: 'S1', part_id: 'A', x: 10, y: 10, w: 400, h: 300, validated: true },
        { sheet_id: 'S1', part_id: 'B', x: 420, y: 10, w: 200, h: 200, validated: false }
      ]
    }
    sheets = [{ id: 'S1', w: 1000, h: 1000 }]
    r = @e.export_generic_dxf(nesting, sheets: sheets)
    assert r.ok, r.note
    assert_equal 'dxf', r.format
    assert_includes r.content, 'SECTION'
    assert_includes r.content, 'ENTITIES'
    assert_includes r.content, 'EOF'
    assert_includes r.content, 'LINE'
    assert_includes r.content, 'SHEET_S1'
    # only validated placement labeled
    assert_includes r.content, 'A'
    refute_includes r.content, "\nB\n"
    assert_includes r.note, 'not a verified CNC program'
  end

  def test_generic_dxf_empty
    r = @e.export_generic_dxf({ placements: [] }, sheets: [])
    refute r.ok
    assert_equal 'EMPTY', r.status
  end

  def test_machine_unverified
    r = @e.export_machine({}, 'scm')
    refute r.ok
    assert_equal 'UNVERIFIED', r.status
  end
end
