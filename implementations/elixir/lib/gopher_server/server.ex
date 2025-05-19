defmodule GopherServer.Server do
  require Logger
  use GenServer

  def start_link(port) do
    Logger.info "start_link"
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  @impl true
  def init(port) do
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: :once, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    {:ok, listen_socket, {:continue, :accept}}
  end

  @impl true
  def handle_continue(:accept, listen_socket) do
    Logger.info "loop_acceptor"
    {:ok, socket} = :gen_tcp.accept(listen_socket)
    {:ok, pid} = DynamicSupervisor.start_child(
      GopherServer.ClientSupervisor,
      {GopherServer.Client, socket}
    )
    :gen_tcp.controlling_process(socket, pid)
    {:noreply, listen_socket, {:continue, :accept}}
  end
end
