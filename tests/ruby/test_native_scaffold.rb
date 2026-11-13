# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/adapter/sketchup_adapter'
require_relative '../../src/jp_cabinet_pro/selection/extractor'
require_relative '../../src/jp_cabinet_pro/cabinet/builder'
require_relative '../../src/jp_cabinet_pro/commands/create_cabinet'

class TestNativeScaffold < Minitest::Test
  FakeEntity = Struct.new(:attrs, :name, :children) do
    def set_attribute(dict, key, value)
      self.attrs ||= {}
      self.attrs[[dict, key]] = value
      value
    end
    def get_attribute(dict, key)
      (self.attrs || {})[[dict, key]]
    end
  end

  def test_adapter_attributes_and_name_non_runtime
    a = JPCabinetPro::Adapter::SketchupAdapter.new(model: nil)
    refute a.available?
    e = FakeEntity.new({}, nil, nil)
    a.mark_cabinet!(e, { width_mm: 800, height_mm: 720, depth_mm: 560 }, {})
    assert_equal 'cabinet', a.get_attr(e, 'type')
    assert_equal 'JP Cabinet 800x720x560', e.name
    params = a.read_params(e)
    assert params
    assert_equal 800, params[:width_mm] || params['width_mm']
  end

  def test_extractor_no_runtime
    a = JPCabinetPro::Adapter::SketchupAdapter.new(model: nil)
    ex = JPCabinetPro::Selection::Extractor.new(adapter: a)
    r = ex.selected_cabinet([])
    refute r.ok
  end

  def test_builder_and_create_command_non_runtime
    a = JPCabinetPro::Adapter::SketchupAdapter.new(model: nil)
    b = JPCabinetPro::Cabinet::Builder.new(adapter: a)
    r = b.create(params: { width_mm: 800 }, parts: [])
    refute r.ok
    assert_includes r.errors, 'sketchup_runtime_required'

    cmd = JPCabinetPro::Commands::CreateCabinet.new(adapter: a)
    res = cmd.execute({ width_mm: 800, height_mm: 720, depth_mm: 560, panel_thickness_mm: 18 })
    assert res.ok, res.errors.inspect
    refute_empty res.parts
    assert_equal false, res.entity_status[:runtime]
  end
end
