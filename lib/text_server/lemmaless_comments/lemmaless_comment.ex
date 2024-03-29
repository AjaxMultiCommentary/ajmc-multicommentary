defmodule TextServer.LemmalessComments.LemmalessComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lemmaless_comments" do
    field :attributes, :map
    field :content, :string
    field :urn, TextServer.Ecto.Types.CTS_URN
    field :interface_id, :string, virtual: true

    belongs_to :canonical_commentary, TextServer.Commentaries.CanonicalCommentary

    timestamps()
  end

  @doc false
  def changeset(lemmaless_comment, attrs) do
    lemmaless_comment
    |> cast(attrs, [:content, :attributes, :urn, :canonical_commentary_id])
    |> validate_required([:content])
    |> assoc_constraint(:canonical_commentary)
  end
end
