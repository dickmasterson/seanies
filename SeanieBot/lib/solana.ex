defmodule Seanies.Solana do
  use GenServer

  alias Solana.RPC

  def start_link(_args) do
    rpc = Application.get_env(:seanies, :rpc_endpoint)
    GenServer.start_link(__MODULE__, rpc, name: __MODULE__)
  end

  def init(rpc) do
    client = RPC.client(network: rpc)
    {:ok, client}
  end

  def make_request(request) do
    GenServer.call(__MODULE__, {:request, request})
  end

  def handle_call({:request, request}, _sender, client) do
    res = RPC.send(client, request)
    {:reply, res, client}
  end
end
