# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../src/jp_cabinet_pro/commands/registry'
require_relative '../../src/jp_cabinet_pro/commands/factory'

class TestCommandRegistry < Minitest::Test
  def setup
    # reset defaults flag for isolation
    JPCabinetPro::Commands::Registry.instance_variable_set(:@defaults_registered, false)
    JPCabinetPro::Commands::Registry.instance_variable_set(:@commands, {})
    JPCabinetPro::Commands::Registry.register_defaults
  end

  def test_registers_core_commands
    ids = JPCabinetPro::Commands::Registry.commands.keys
    %w[cabinet.edit_dimensions nesting.plan report.generate cnc.export_csv cnc.export_nesting_dxf library.manage].each do |id|
      assert_includes ids, id
    end
  end

  def test_command_contract_fields
    cmd = JPCabinetPro::Commands::Registry.fetch('cabinet.edit_dimensions')
    %i[id icon label_sq label_en input_schema validation handler required_selection undo_behavior test_id].each do |k|
      assert cmd.key?(k), "missing #{k}"
    end
    assert_equal 'cmd.cabinet.edit_dimensions', cmd[:test_id]
  end

  def test_factory_builds_known_handlers
    assert JPCabinetPro::Commands::Factory.build('cabinet.edit_dimensions')
    assert JPCabinetPro::Commands::Factory.build('nesting.plan')
    assert JPCabinetPro::Commands::Factory.build('report.generate')
    assert JPCabinetPro::Commands::Factory.build('cnc.export_csv')
    assert JPCabinetPro::Commands::Factory.build('library.manage')
    assert_nil JPCabinetPro::Commands::Factory.build('unknown.command')
  end
end
