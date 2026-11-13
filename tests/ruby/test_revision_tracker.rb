# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/diagnostics/revision_tracker'

class TestRevisionTracker < Minitest::Test
  def setup
    @t = JPCabinetPro::Diagnostics::RevisionTracker.new
  end

  def test_touch_invalidates_all
    s = @t.touch!('asm1', 2)
    assert_equal 2, s[:revision]
    assert_equal false, s[:valid][:bom]
    assert_equal false, s[:valid][:nesting]
    assert_equal false, s[:valid][:drawings]
  end

  def test_mark_valid_and_invalidate
    @t.touch!('asm1', 1)
    @t.mark_valid!('asm1', :bom, :cutlist)
    assert_equal true, @t.status('asm1')[:valid][:bom]
    @t.invalidate!('asm1', :bom)
    assert_equal false, @t.status('asm1')[:valid][:bom]
    assert_equal true, @t.status('asm1')[:valid][:cutlist]
  end

  def test_snapshot_view
    @t.touch!('asm1', 3)
    @t.mark_valid!('asm1', :bom)
    snap = @t.snapshot('asm1')
    assert_equal 3, snap[:revision]
    assert_includes snap[:stale], :nesting
    refute_includes snap[:stale], :bom
  end
end
