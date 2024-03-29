defmodule TextServer.StaticPages.Page do
  @enforce_keys [:id, :author, :title, :body, :description, :tags, :date]
  defstruct [:id, :author, :title, :body, :description, :tags, :date]

  def build(filename, attrs, body) do
    id = filename |> Path.rootname() |> Path.split() |> List.last()
    date = Date.from_iso8601!("#{attrs.date}")

    struct!(
      __MODULE__,
      [id: id, date: date, body: body] ++ Map.to_list(attrs)
    )
  end
end
