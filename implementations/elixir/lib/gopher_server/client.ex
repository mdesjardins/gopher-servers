defmodule GopherServer.Client do
  use GenServer
  require Logger
  alias GopherServer.RequestHandler

  @initial_state %{socket: nil}

  def start_link(socket, opts \\ []) do
    GenServer.start_link(__MODULE__, socket, opts)
  end

  @impl true
  def init(socket) do
    {:ok, %{ @initial_state | socket: socket }}
  end

  @impl true
  def handle_info({:tcp, socket, data}, state) do
    Logger.info("Received request: #{inspect(data)}")
    RequestHandler.process_request(data)
    :inet.setopts(socket, active: :once)
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, _socket}, _state) do
    Process.exit(self(), :normal)
  end
end
