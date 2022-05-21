defmodule Seanies.Consumer do
  require Logger
  use Nostrum.Consumer
  alias Seanies.Commands
  alias Nostrum.Api

  def start_link, do: Consumer.start_link(__MODULE__)

  def handle_event({:READY, _event, _ws_state}) do
    {:ok, commands} = Api.get_global_application_commands()
    registered_commands = Enum.map(commands, fn x -> x.name end)
    all_commands = Commands.commands() |> Map.keys()

    (all_commands -- registered_commands)
    |> Enum.each(fn name ->
      {_, description, options} = Commands.commands()[name]

      Logger.debug("Creating global command: #{name}")

      Api.create_global_application_command(%{
        name: name,
        description: description,
        options: options
      })
    end)
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    case Commands.dispatch(interaction) do
      {:msg, msg} -> respond_with_msg(interaction, %{content: msg})
      {:eph_msg, msg} -> respond_with_msg(interaction, %{content: msg, flags: 64})
      {:embed, embed} -> respond_with_msg(interaction, %{embed: embed})
      {:embeds, embeds} -> respond_with_msg(interaction, %{embeds: embeds})
      {:modal, components} -> respond_with_modal(interaction, %{components: components})
    end
  end

  def handle_event(_event) do
    :noop
  end

  def respond_with_msg(interaction, data) do
    Api.create_interaction_response(interaction, %{type: 4, data: data})
  end

  def respond_with_modal(interaction, data) do
    Api.create_interaction_response(interaction, %{type: 9, data: data}) |> IO.inspect()
  end
end
