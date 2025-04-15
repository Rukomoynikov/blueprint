defmodule Blueprint.New.Single do
  alias Blueprint.New.Project
  use Blueprint.New.Generator

  template(:new, [
    {:eex, "blueprint/README.md": "README.md"}
  ])

  def prepare_project(%Project{} = project) do
    project
  end

  def generate(%Project{} = project) do
    copy_from(project, __MODULE__, :new)

    project
  end
end
