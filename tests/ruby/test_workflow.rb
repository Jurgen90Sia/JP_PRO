# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/core/workflow'

class TestWorkflow < Minitest::Test
  def test_workflow_runs_full_pipeline
    wf = JPCabinetPro::Core::Workflow.new
    r = wf.run({ width_mm: 800, height_mm: 720, depth_mm: 560, panel_thickness_mm: 18, shelf_count: 1 }, revision: 2)
    assert r.ok, r.errors.inspect
    refute_empty r.bom
    assert_equal r.bom.length, r.cutlist.length
    assert r.view
    assert r.view_svg
    assert r.materials
    assert r.edge_banding.is_a?(Array)
    assert r.snapshot
    assert r.revision_state
    assert_equal 2, r.revision_state[:revision]
    assert_equal true, r.revision_state[:valid][:bom]
  end

  def test_dependency_graph
    wf = JPCabinetPro::Core::Workflow.new
    a = wf.affected('params')
    assert_includes a, 'geometry'
    assert_includes a, 'reports'
  end
end
