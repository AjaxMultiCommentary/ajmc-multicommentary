defmodule TextServerWeb.ProjectLive.FormComponent do
  use TextServerWeb, :live_component

  alias TextServer.Projects

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:project_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl true
  def update(%{project: project} = assigns, socket) do
    changeset = Projects.change_project(project)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      socket.assigns.project
      |> Projects.change_project(project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    save_project(socket, socket.assigns.action, project_params)
  end

  defp save_project(socket, :edit, project_params) do
    case Projects.update_project(socket.assigns.project, project_params) do
      {:ok, _project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_project(socket, :new, project_params) do
    project_params = Map.put(project_params, "created_by_id", socket.assigns.current_user.id)

    case Projects.create_project(project_params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully")
         |> push_redirect(to: Routes.project_edit_path(socket, :edit, project))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end