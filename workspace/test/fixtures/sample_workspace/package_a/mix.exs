defmodule PackageA.MixProject do
  use Mix.Project

  def project do
    [
      app: :package_a,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      workspace: [
        tags: [:shared, {:area, :core}]
      ],
      package: [
        maintainers: ["Jack Sparrow"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:package_b, path: "../package_b/"},
      {:package_c, path: "../package_c/"},
      {:package_d, path: "../package_d/"},
      {:ex_doc, "~> 0.28", [only: :dev, runtime: false]}
    ]
  end
end
