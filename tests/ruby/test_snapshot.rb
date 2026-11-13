# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/persistence/snapshot'

class TestSnapshot < Minitest::Test
  def test_build_and_serialize
    snap = JPCabinetPro::Persistence::Snapshot.build(
      revision: 3, project_id: 'p1', assembly_id: 'a1',
      params: { width_mm: 800 }, bom: [{ part_id: 'x' }], cutlist: [], view: { type: :front },
      nesting: { ok: true, utilization: 0.5 }, view_svg: '<svg/>'
    )
    assert_equal 3, snap[:revision]
    assert snap.frozen?
    assert snap[:params].frozen?
    assert_equal 0.5, snap[:nesting][:utilization]
    assert_equal '<svg/>', snap[:view_svg]
    json = JPCabinetPro::Persistence::Snapshot.serialize(snap)
    assert_includes json, '"revision": 3'
    assert_includes json, '"part_id"'
    assert_includes json, '"nesting"'
  end
end
