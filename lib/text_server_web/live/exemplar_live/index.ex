defmodule TextServerWeb.ExemplarLive.Index do
  use TextServerWeb, :live_view

  alias TextServer.Exemplars

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :exemplars, list_exemplars())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Exemplars")
    |> assign(:exemplar, nil)
  end

  @impl true
  def handle_event(event, params, socket) do
    IO.inspect(event)
    IO.inspect(params)

    {:noreply, socket}
  end

  defp list_exemplars do
    Exemplars.list_exemplars()
  end
end
