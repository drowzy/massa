defmodule MassaProxy.Cluster.HordeConnector do
  @moduledoc false
  require Logger

  def connect() do
    Logger.info("Starting Proxy Cluster...")

    set_members(MassaProxy.GlobalRegistry)
    set_members(MassaProxy.GlobalSupervisor)
  end

  def start_children() do
    # The order in which supervisors start matters, so be careful when you move here
    Logger.debug("Starting Supervisors...")

    Horde.DynamicSupervisor.start_child(
      MassaProxy.Supervisor,
      {MassaProxy.Cluster.StateHandoff, []}
    )

    Horde.DynamicSupervisor.start_child(
      MassaProxy.Supervisor,
      {MassaProxy.Entity.EntityRegistry, "EventSourced"}
    )

    Horde.DynamicSupervisor.start_child(
      MassaProxy.Supervisor,
      {MassaProxy.Entity.EntityRegistry, "CRDT"}
    )

    Horde.DynamicSupervisor.start_child(
      MassaProxy.Supervisor,
      {MassaProxy.Entity.EntityRegistry, "Stateless"}
    )

    Horde.DynamicSupervisor.start_child(MassaProxy.Supervisor, EventSourced.Router)
  end

  defp set_members(name) do
    members =
      [Node.self() | Node.list()]
      |> Enum.map(fn node ->
        Logger.debug(
          "[massa proxy on #{inspect(Node.self())}]: Connecting Horde to #{inspect(node)}"
        )

        {name, node}
      end)

    :ok = Horde.Cluster.set_members(name, members)
  end
end
