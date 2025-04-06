# https://github.com/phoenixframework/phoenix/blob/main/installer/lib/mix/tasks/phx.new.ex

defmodule Mix.Tasks.Blueprint.New do
  use Mix.Task

  alias Blueprint.New.{Project, Single, Generator}

  @version Mix.Project.config()[:version]
  @shortdoc "Creates a new Blueprint v#{@version} application"

  @impl true
  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("Blueprint installer v#{@version}")
  end

  def run(argv) do
    {opts, argv} = OptionParser.parse!(argv)

    result =
      case {opts, argv} do
        {_opts, []} ->
          Mix.Tasks.Help.run(["blueprint.new"])

        {opts, [base_path | _]} -> generate(base_path, :base_path, opts)
      end
  end

  defp generate(base_path, path, opts) do
    base_path
    |> Project.new(opts)
    |> Single.prepare_project()
    |> Generator.put_binding()
    |> Single.generate()
    # |> maybe_copy_cached_build(path)
    # |> maybe_prompt_to_install_deps(generator, path)
  end
end
