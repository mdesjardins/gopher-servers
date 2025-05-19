defmodule GopherServer.Application do
  @moduledoc false
  require Logger
  use Application


  def init(init_arg) do
      {:ok, init_arg}
  end

  #   use Application

  @impl true
  def start(_type, _args) do
    Logger.info "start"
    port = String.to_integer(Application.get_env(:gopher_server, :port))
    children = [
      {GopherServer.Server, port},
      {DynamicSupervisor, strategy: :one_for_one, name: GopherServer.ClientSupervisor},
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

end
