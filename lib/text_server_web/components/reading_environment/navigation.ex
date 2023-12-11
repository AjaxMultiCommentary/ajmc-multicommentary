defmodule TextServerWeb.ReadingEnvironment.Navigation do
  use TextServerWeb, :component

  alias TextServerWeb.Helpers.Markdown

  attr :current_passage, TextServer.Versions.Passage
  attr :passages, :list, default: []

  def nav_menu(assigns) do
    ~H"""
    <ul class="menu bg-base-200 p-0 max-w-fit [&_li>*]:rounded-none">
      <%= for passage <- @passages do %>
        <li class="text-sm">
          <.link
            patch={"?page=#{passage.passage_number}"}
            class={[if(passage.passage_number == @current_passage.passage_number, do: "active", else: "")]}
          >
            <span class="items-start">
              <%= raw(Markdown.sanitize_and_parse_markdown(passage.label)) %> (vv. <%= passage.urn.citations |> List.first() %>&ndash;<%= passage.urn.citations
              |> List.last() %>)
            </span>
          </.link>
        </li>
      <% end %>
    </ul>
    """
  end
end