# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/nesting/optimizer'

class TestNesting < Minitest::Test
  def setup
    @opt = JPCabinetPro::Nesting::Optimizer.new
    @sheet = { id: 'S1', w: 1000.0, h: 1000.0, kerf: 3.0, trim: 10.0, material: 'm1', thickness: 18 }
  end

  def test_basic_maxrects_places_and_validates
    parts = [
      { id: 'A', w: 400, h: 300, qty: 2, material: 'm1', thickness: 18, grain: 'none' },
      { id: 'B', w: 200, h: 200, qty: 1, material: 'm1', thickness: 18, grain: 'none' }
    ]
    r = @opt.plan(parts, [@sheet], strategy: 'maxrects')
    assert r[:ok]
    assert_equal 3, r[:placements].length
    assert r[:placements].all? { |p| p[:validated] }
    assert r[:validated]
    assert r[:utilization].is_a?(Numeric)
    assert r[:utilization] > 0
    assert_empty r[:unplaced]
    assert r[:cut_length_mm].is_a?(Numeric)
    assert_equal 'OK', r[:cut_length_status]
    assert r[:offcuts].is_a?(Array)
  end

  def test_guillotine_strategy
    parts = [{ id: 'A', w: 400, h: 400, qty: 3, material: 'm1', thickness: 18, grain: 'none' }]
    r = @opt.plan(parts, [@sheet], strategy: 'guillotine')
    assert r[:ok]
    assert r[:placements].length >= 1
    assert r[:placements].all? { |p| p[:validated] }
  end

  def test_grain_restricts_rotation
    parts = [
      { id: 'A', w: 900, h: 100, qty: 1, material: 'm1', thickness: 18, grain: 'v', can_rotate: false },
      { id: 'B', w: 100, h: 900, qty: 1, material: 'm1', thickness: 18, grain: 'v', can_rotate: false }
    ]
    r = @opt.plan(parts, [@sheet], strategy: 'maxrects')
    assert r[:ok]
    assert r[:placements].all? { |p| p[:validated] }
  end

  def test_no_overlap_and_inside_trim
    parts = (1..6).map { |i| { id: "P#{i}", w: 300, h: 300, qty: 1, material: 'm1', thickness: 18, grain: 'none' } }
    r = @opt.plan(parts, [@sheet], strategy: 'best_area_fit')
    placed = r[:placements].select { |p| p[:validated] }
    placed.combination(2) do |a, b|
      overlap = !(a[:x] + a[:w] <= b[:x] + 0.001 || b[:x] + b[:w] <= a[:x] + 0.001 ||
                  a[:y] + a[:h] <= b[:y] + 0.001 || b[:y] + b[:h] <= a[:y] + 0.001)
      refute overlap, 'placements must not overlap'
    end
    trim = @sheet[:trim]
    placed.each do |p|
      assert p[:x] >= trim - 0.001
      assert p[:y] >= trim - 0.001
      assert p[:x] + p[:w] <= @sheet[:w] - trim + 0.001
      assert p[:y] + p[:h] <= @sheet[:h] - trim + 0.001
    end
  end

  def test_groups_by_material_thickness
    parts = [
      { id: 'A', w: 200, h: 200, qty: 1, material: 'm1', thickness: 18, grain: 'none' },
      { id: 'B', w: 200, h: 200, qty: 1, material: 'm2', thickness: 18, grain: 'none' }
    ]
    sheets = [
      @sheet,
      { id: 'S2', w: 1000.0, h: 1000.0, kerf: 0.0, trim: 0.0, material: 'm2', thickness: 18 }
    ]
    r = @opt.plan(parts, sheets, strategy: 'maxrects')
    assert_equal 2, r[:placements].length
    a = r[:placements].find { |p| p[:part_id] == 'A' }
    b = r[:placements].find { |p| p[:part_id] == 'B' }
    assert_equal 'S1', a[:sheet_id]
    assert_equal 'S2', b[:sheet_id]
  end

  def test_unplaceable_part
    parts = [{ id: 'BIG', w: 2000, h: 2000, qty: 1, material: 'm1', thickness: 18, grain: 'none' }]
    r = @opt.plan(parts, [@sheet], strategy: 'maxrects')
    assert r[:ok]
    assert_includes r[:unplaced], 'BIG'
  end

  def test_unsupported_strategy
    assert_raises(ArgumentError) { @opt.plan([], [@sheet], strategy: 'nope') }
  end
end
