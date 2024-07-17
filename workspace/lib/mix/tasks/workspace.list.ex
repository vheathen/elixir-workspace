defmodule Mix.Tasks.Workspace.List do
  opts = [
    json: [
      type: :boolean,
      default: false,
      doc: """
      If set a `json` file will be generated with the list of workspace projects and
      associated metadata. By default it will be saved in `workspace.json` in the
      current directory. You can override the output path by setting the `--output`
      option.
      """
    ],
    output: [
      type: :string,
      default: "workspace.json",
      doc: """
      The output file. Applicable only if `--json` is set.
      """
    ],
    relative_paths: [
      type: :boolean,
      default: false,
      doc: """
      If set the paths in the exported json file will be relative with respect to the
      workspace path. Applicable only if `--json` is set.
      """
    ]
  ]

  @options_schema Workspace.Cli.options(
                    [
                      :workspace_path,
                      :config_path,
                      :project,
                      :exclude,
                      :tags,
                      :excluded_tags,
                      :show_status
                    ],
                    opts
                  )

  @shortdoc "Display info about the workspace projects"

  @moduledoc """
  Shows workspace project info

      $ mix workspace.list

  By default the following are displayed:

  - the project app name
  - the project path with respect to workspace path
  - the description if set

  ## Command line options

  #{CliOptions.docs(@options_schema, sort: true)}
  """
  use Mix.Task
  alias Workspace.Cli

  @impl Mix.Task
  def run(args) do
    {opts, _args, _extra} = CliOptions.parse!(args, @options_schema)

    opts
    |> Mix.WorkspaceUtils.load_and_filter_workspace()
    |> list_or_save_workspace_projects(opts)
  end

  defp list_or_save_workspace_projects(workspace, opts) do
    case opts[:json] do
      false -> list_workspace_projects(workspace, opts[:show_status])
      true -> write_json(workspace, opts)
    end
  end

  defp list_workspace_projects(workspace, show_status) do
    projects = Workspace.projects(workspace)

    case Enum.count(projects, &(not &1.skip)) do
      0 ->
        Cli.log([:bright, :yellow, "No matching projects for the given options", :reset])

      valid ->
        Cli.log([
          "Found ",
          :bright,
          :blue,
          "#{valid} workspace projects",
          :reset,
          " matching the given options."
        ])
    end

    max_project_length = max_project_length(projects)

    projects
    |> Enum.sort_by(& &1.app)
    |> Enum.each(&print_project_info(&1, max_project_length, show_status))
  end

  defp max_project_length([]), do: 0

  defp max_project_length(projects) do
    projects
    |> Enum.map(fn project -> inspect(project.app) |> String.length() end)
    |> Enum.max()
  end

  defp print_project_info(%Workspace.Project{skip: true}, _length, _show_status), do: :ok

  defp print_project_info(project, max_project_length, show_status) do
    indent_size = max_project_length - String.length(inspect(project.app))
    indent = String.duplicate(" ", indent_size)

    Cli.log([
      "  * ",
      Cli.project_name(project, show_status: show_status, pretty: true),
      indent,
      :light_black,
      " ",
      Path.relative_to(project.mix_path, project.workspace_path),
      :reset,
      description(project.config[:description]),
      tags(project.tags)
    ])
  end

  defp description(nil), do: ""
  defp description(doc) when is_binary(doc), do: [" - ", doc]

  defp write_json(workspace, opts) do
    json_data = Workspace.Export.to_json(workspace, sort: true, relative: opts[:relative_paths])

    File.write!(opts[:output], json_data)

    Workspace.Cli.log([:green, "generated ", :reset, opts[:output]], prefix: :header)
  end

  defp tags([]), do: []

  defp tags(tags) do
    tags =
      Enum.map(tags, fn tag -> [:tag, Workspace.Project.format_tag(tag), :reset] end)
      |> Enum.intersperse(", ")

    [" " | tags]
  end
end
