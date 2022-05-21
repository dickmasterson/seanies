defmodule Seanies.Culler do
  use GenServer

  alias Seanies.Commands

  # 10 minutes
  @loop_period 1000 * 60 * 10

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    loop()
    {:ok, state}
  end

  def handle_info(:loop, state) do
    loop()
    {:noreply, state}
  end

  def loop() do
    Task.start(fn -> cull_beggars() end)
    Process.send_after(self(), :loop, @loop_period)
  end

  def cull_beggars() do
    Commands.read_beggars_file()
    |> Enum.filter(fn {wallet, _val} ->
      wallet
      |> Commands.get_tokens_owned_by_account()
      |> length()
      |> Kernel.>(0)
    end)
    |> Enum.map(fn {wallet, _val} -> wallet end)
    |> Commands.remove_beggars()
  end
end
