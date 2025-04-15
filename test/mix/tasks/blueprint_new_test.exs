Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.BlueprintNewTest do
  use ExUnit.Case, async: false
  import MixHelper
  import ExUnit.CaptureIO

  @app_name "blueprint_blog"

  setup do
    send(self(), {:mix_shell_input, :yes?, false})
    :ok
  end

  test "returns the version" do
    Mix.Tasks.Blueprint.New.run(["-v"])
    assert_received {:mix_shell, :info, ["Blueprint installer v" <> _]}
  end

  test "new with defaults" do
    in_tmp("new with defaults", fn ->
      Mix.Tasks.Blueprint.New.run([@app_name])

      assert_file("blueprint_blog/README.md")

      # assert_file("phx_blog/.formatter.exs", fn file ->
      #    assert file =~ "import_deps: [:ecto, :ecto_sql, :phoenix]"
      #    assert file =~ "subdirectories: [\"priv/*/migrations\"]"
      #    assert file =~ "plugins: [Phoenix.LiveView.HTMLFormatter]"

      #    assert file =~
      #             "inputs: [\"*.{heex,ex,exs}\", \"{config,lib,test}/**/*.{heex,ex,exs}\", \"priv/*/seeds.exs\"]"
      #  end)
    end)
  end
end
