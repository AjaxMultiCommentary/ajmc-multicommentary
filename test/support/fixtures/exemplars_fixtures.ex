defmodule TextServer.ExemplarsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TextServer.Exemplars` context.
  """

  def unique_exemplar_filemd5hash, do: "some filemd5hash#{System.unique_integer([:positive])}"
  def unique_exemplar_filename, do: "some filename#{System.unique_integer([:positive])}"

  @doc """
  Generate a exemplar.
  """
  def exemplar_fixture(attrs \\ %{}) do
    {:ok, exemplar} =
      attrs
      |> Enum.into(%{
        filemd5hash: unique_exemplar_filemd5hash(),
        filename: unique_exemplar_filename(),
        version_id: version_fixture().id
      })
      |> TextServer.Exemplars.create_exemplar()

    # it should not be possible to create an exemplar
    # without at least one text node
    text_node_fixture(exemplar)

    exemplar
  end

  def text_node_exemplar_fixture(attrs \\ %{}) do
    {:ok, exemplar} =
      attrs
      |> Enum.into(%{
        filemd5hash: unique_exemplar_filemd5hash(),
        filename: unique_exemplar_filename(),
        version_id: version_fixture().id
      })
      |> TextServer.Exemplars.create_exemplar()

    exemplar
  end

  def exemplar_with_docx_fixture(attrs \\ %{}) do
    exemplar_fixture(
      attrs
      |> Enum.into(%{filename: Path.expand("test/support/fixtures/exemplar.docx")})
    )
  end

  defp text_node_fixture(exemplar) do
    TextServer.TextNodesFixtures.exemplar_text_node_fixture(exemplar.id)
  end

  defp version_fixture() do
    TextServer.VersionsFixtures.version_fixture()
  end
end
