defmodule Blueprint.New.Generator do
  alias Blueprint.New.{Project}

  @phoenix_version Version.parse!(Mix.Project.config()[:version])

  @callback prepare_project(Project.t()) :: Project.t()
  @callback generate(Project.t()) :: Project.t()

  defmacro __using__(_env) do
    quote do
      @behaviour unquote(__MODULE__)
      import Mix.Generator
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :templates, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    root = Path.expand("../../lib/templates", __DIR__)

    templates_ast =
      for {name, mappings} <- Module.get_attribute(env.module, :templates) do
        for {format, files} <- mappings,
            format != :keep,
            {source, _target} <- files,
            source = to_string(source) do
          path = Path.join(root, source)

          if format in [:config, :prod_config, :eex] do
            compiled = EEx.compile_file(path)

            quote do
              @external_resource unquote(path)
              @file unquote(path)
              def render(unquote(name), unquote(source), var!(assigns)) when is_list(var!(assigns)) do

                var!(maybe_heex_attr_gettext) = &unquote(__MODULE__).maybe_heex_attr_gettext/2
                _ = var!(maybe_heex_attr_gettext)
                var!(maybe_eex_gettext) = &unquote(__MODULE__).maybe_eex_gettext/2
                _ = var!(maybe_eex_gettext)
                unquote(compiled)
              end
            end
          end
        end
      end

    quote do
      unquote(templates_ast)
      def template_files(name), do: Keyword.fetch!(@templates, name)
    end
  end

  defmacro template(name, mappings) do
    quote do
      @templates {unquote(name), unquote(mappings)}
    end
  end

  def put_binding(%Project{opts: opts} = project) do
    dbg(opts)

    ecto = Keyword.get(opts, :ecto, true)
    html = Keyword.get(opts, :html, true)
    live = html && Keyword.get(opts, :live, true)
    dashboard = Keyword.get(opts, :dashboard, true)
    gettext = Keyword.get(opts, :gettext, true)
    assets = Keyword.get(opts, :assets, true)
    esbuild = Keyword.get(opts, :esbuild, assets)
    tailwind = Keyword.get(opts, :tailwind, assets)
    mailer = Keyword.get(opts, :mailer, true)
    dev = Keyword.get(opts, :dev, false)
    from_elixir_install = Keyword.get(opts, :from_elixir_install, false)

    binding = [
      app_name: project.app,
      app_module: inspect(project.app_mod),
      root_app_name: project.root_app,
      root_app_module: inspect(project.root_mod),
      phoenix_version: @phoenix_version,
      in_umbrella: project.in_umbrella?,
      asset_builders: Enum.filter([tailwind && :tailwind, esbuild && :esbuild], & &1),
      javascript: esbuild,
      css: tailwind,
      mailer: mailer,
      ecto: ecto,
      html: html,
      live: live,
      live_comment: if(live, do: nil, else: "// "),
      dashboard: dashboard,
      gettext: gettext,
      dev: dev,
      from_elixir_install: from_elixir_install,
    ]

    %{project | binding: binding}
  end

  def copy_from(%Project{} = project, mod, name) when is_atom(name) do
    mapping = mod.template_files(name)

    for {format, project_location, files} <- mapping,
        {source, target_path} <- files,
        source = to_string(source) do
      target = Project.join_path(project, project_location, target_path)

      case format do
        :keep ->
          File.mkdir_p!(target)

        :text ->
          create_file(target, mod.render(name, source, project.binding))

        :config ->
          contents = mod.render(name, source, project.binding)
          config_inject(Path.dirname(target), Path.basename(target), contents)

        :prod_config ->
          contents = mod.render(name, source, project.binding)
          prod_only_config_inject(Path.dirname(target), Path.basename(target), contents)

        :eex ->
          contents = mod.render(name, source, project.binding)
          create_file(target, contents)
      end
    end
  end
end
