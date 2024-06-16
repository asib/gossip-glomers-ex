defmodule GossipGlomers.MixProject do
  use Mix.Project

  def project do
    [
      app: :gossip_glomers,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GossipGlomers.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ecto_ulid, "~> 0.2.0"}
    ]
  end
end
