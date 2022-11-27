defmodule TextServer.ExemplarsTest do
  use TextServer.DataCase

  alias TextServer.Exemplars
  alias TextServer.Exemplars.Exemplar
  alias TextServer.TextNodes

  import TextServer.ExemplarsFixtures
  import TextServer.TextNodesFixtures

  @valid_attrs %{
    description: "some description",
    filemd5hash: "some md5hash",
    filename: "some_filename.docx",
    label: "some label",
    parsed_at: nil,
    source: "some source",
    source_link: "https://some.source.link/",
    title: "some title",
    urn: "urn:cts:some:urn"
  }

  @invalid_attrs %{
    description: nil,
    filemd5hash: nil,
    filename: nil,
    label: nil,
    parsed_at: nil,
    source: nil,
    source_link: nil,
    title: nil,
    urn: nil
  }

  describe "exemplars" do
    test "list_exemplars/0 returns all exemplars" do
      exemplar = exemplar_fixture()
      assert List.first(Exemplars.list_exemplars()).description == exemplar.description
    end

    test "get_exemplar!/1 returns the exemplar with given id" do
      exemplar = exemplar_fixture()
      assert Exemplars.get_exemplar!(exemplar.id).filename == exemplar.filename
    end

    test "get_exemplar_page/2 returns TextNodes for the given exemplar_id and page_number" do
      exemplar = exemplar_fixture()

      Enum.each(1..5, fn i ->
        text_node_fixture(%{
          exemplar_id: exemplar.id,
          location: [1, i, 1]
        })
      end)

      Exemplars.paginate_exemplar(exemplar)

      page = Exemplars.get_exemplar_page(exemplar.id, 2)
      text_nodes = page.text_nodes
      text_node = List.first(text_nodes)

      assert page.page_number == 2
      assert text_node.location == [1, 2, 1]
    end

    test "create_exemplar/1 with valid data creates a exemplar" do
      language = TextServer.LanguagesFixtures.language_fixture()
      version = TextServer.VersionsFixtures.version_fixture()

      assert {:ok, %Exemplar{} = exemplar} =
               @valid_attrs
               |> Map.put(:language_id, language.id)
               |> Map.put(:version_id, version.id)
               |> Exemplars.create_exemplar()

      assert exemplar.description == "some description"
      assert exemplar.title == "some title"
      assert exemplar.urn == "urn:cts:some:urn"
    end

    test "create_exemplar/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Exemplars.create_exemplar(@invalid_attrs)
    end

    test "update_exemplar/2 with valid data updates the exemplar" do
      exemplar = exemplar_fixture()

      update_attrs = %{
        description: "some updated description",
        title: "some updated title",
        urn: "urn:cts:some:updated_urn"
      }

      assert {:ok, %Exemplar{} = exemplar} = Exemplars.update_exemplar(exemplar, update_attrs)
      assert exemplar.description == "some updated description"
      assert exemplar.title == "some updated title"
      assert exemplar.urn == "urn:cts:some:updated_urn"
    end

    test "update_exemplar/2 with invalid data returns error changeset" do
      exemplar = exemplar_fixture()
      assert {:error, %Ecto.Changeset{}} = Exemplars.update_exemplar(exemplar, @invalid_attrs)
    end

    test "delete_exemplar/1 deletes the exemplar" do
      exemplar = exemplar_fixture()
      assert {:ok, %Exemplar{}} = Exemplars.delete_exemplar(exemplar)
      assert_raise Ecto.NoResultsError, fn -> Exemplars.get_exemplar!(exemplar.id) end
    end

    test "change_exemplar/1 returns a exemplar changeset" do
      exemplar = exemplar_fixture()
      assert %Ecto.Changeset{} = Exemplars.change_exemplar(exemplar)
    end

    test "get_table_of_contents/1 returns the table of contents for the given exemplar" do
      exemplar = exemplar_fixture()

      Enum.each(1..5, fn i ->
        text_node_fixture(%{
          exemplar_id: exemplar.id,
          location: [i, 1, 1]
        })
      end)

      toc = Exemplars.get_table_of_contents(exemplar.id)

      assert Map.get(toc, 1) == %{1 => [1, 1]}
      assert Map.get(toc, 2) == %{1 => [1]}
      assert Map.get(toc, 3) == %{1 => [1]}
      assert Map.get(toc, 4) == %{1 => [1]}
      assert Map.get(toc, 5) == %{1 => [1]}
    end
  end

  describe "Exemplar DOCX parsing" do
    import TextServer.ExemplarsFixtures

    test "parse_exemplar/1 can parse a docx" do
      exemplar = exemplar_with_docx_fixture()

      assert {:ok, %Exemplar{} = _} = Exemplars.parse_exemplar(exemplar)

      text_node = TextNodes.get_by(%{exemplar_id: exemplar.id, location: [1, 1, 1]})

      assert String.contains?(
               text_node.text,
               "This is a test document for TextServer.Exemplars.parse_xml/1"
             )

      text_node = TextNodes.get_by(%{exemplar_id: exemplar.id, location: [1, 2, 1]})

      assert String.contains?(
               text_node.text,
               "Now we want to test inline styles and TextElements."
             )
    end
  end
end
