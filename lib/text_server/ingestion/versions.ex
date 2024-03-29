defmodule TextServer.Ingestion.Versions do
  alias TextServer.Collections
  alias TextServer.ElementTypes
  alias TextServer.Languages
  alias TextServer.TextElements
  alias TextServer.TextGroups
  alias TextServer.TextNodes
  alias TextServer.Versions
  alias TextServer.Works

  def create_versions do
    {:ok, collection} = create_collection()
    {:ok, text_group} = create_text_group(collection)
    {:ok, work} = create_work(text_group)
    {:ok, language} = create_language()

    for {xml_file, version_data} <- xml_files() do
      xml = File.read!(xml_file)

      {:ok, version} = create_version(work, language, xml, version_data)

      version = TextServer.Repo.preload(version, :xml_document)

      if is_nil(version.xml_document) do
        Versions.create_xml_document!(version, %{document: xml})
      end

      create_text_nodes(version)
      create_navigation(version)

      version
    end
  end

  defp create_collection do
    Collections.find_or_create_collection(%{
      repository: "https://github.com/gregorycrane/Wolf1807",
      urn: "urn:cts:greekLit",
      title: "Towards a Smart App. Crit.: Sophocles' Ajax"
    })
  end

  defp create_language do
    Languages.find_or_create_language(%{slug: "grc", title: "Greek"})
  end

  def create_navigation(%Versions.Version{} = version) do
    raw_synopsis = File.read!(synopsis_json())
    {:ok, synopsis} = Jason.decode(raw_synopsis)

    synopsis
    |> Map.get("synopsis", [])
    |> Enum.with_index(1)
    |> Enum.map(fn {passage, i} ->
      passage_urn = passage |> Map.get("passage_urn") |> CTS.URN.parse()

      passage_urn =
        Map.merge(version.urn, Map.take(passage_urn, [:passage_component, :citations]))

      passage_label = passage |> Map.get("label") |> Map.get("en") |> String.trim()
      [start_location, end_location] = passage_urn.citations

      Versions.Passages.create_passage!(%{
        version_id: version.id,
        urn: passage_urn,
        label: passage_label,
        end_location: [end_location],
        start_location: [start_location],
        passage_number: i
      })
    end)
  end

  defp create_text_group(%Collections.Collection{} = collection) do
    TextGroups.find_or_create_text_group(%{
      title: "Sophocles",
      urn: "urn:cts:greekLit:tlg0011",
      collection_id: collection.id
    })
  end

  defp create_text_nodes(%Versions.Version{} = version) do
    # make sure we have a fresh version
    version =
      TextServer.Repo.get(Versions.Version, version.id) |> TextServer.Repo.preload(:xml_document)

    {:ok, version_body} = DataSchema.to_struct(version.xml_document, DataSchemas.Version)

    %{word_count: _word_count, lines: lines} =
      version_body.body.lines
      |> Enum.reduce(%{word_count: 0, lines: []}, fn line, acc ->
        text = line.text |> String.trim()
        word_count = acc.word_count

        words =
          Regex.split(~r/[[:space:]]+/, text)
          |> Enum.with_index()
          |> Enum.map(fn {word, index} ->
            offset =
              case String.split(text, word, parts: 2) do
                [left, _] -> String.length(left)
                [_] -> nil
              end

            %{
              xml_id: "word_index_#{word_count + index}",
              offset: offset,
              text: word
            }
          end)

        speaker =
          version_body.body.speakers
          |> Enum.find(fn speaker -> Enum.member?(speaker.lines, line.n) end)

        new_line = %{
          elements: [
            %{
              attributes: %{name: speaker.name},
              start_offset: 0,
              end_offset: String.length(text),
              name: "speaker"
            }
            | line.elements
          ],
          location: [line.n],
          text: text,
          words: words
        }

        %{word_count: word_count + length(words), lines: [new_line | acc.lines]}
      end)

    lines = Enum.reverse(lines)

    lines
    |> Enum.with_index()
    |> Enum.each(fn {line, offset} ->
      {:ok, text_node} =
        TextNodes.find_or_create_text_node(%{
          offset: offset,
          location: line.location,
          text: line.text,
          urn: "#{version.urn}:#{Enum.at(line.location, 0)}",
          version_id: version.id
        })

      line.elements
      |> Enum.each(fn element ->
        {:ok, element_type} = ElementTypes.find_or_create_element_type(%{name: element.name})

        {:ok, _text_element} =
          %{
            attributes: Map.new(element.attributes),
            end_offset: element.end_offset,
            element_type_id: element_type.id,
            end_text_node_id: text_node.id,
            start_offset: element.start_offset,
            start_text_node_id: text_node.id
          }
          |> TextElements.find_or_create_text_element()
      end)
    end)
  end

  defp create_version(%Works.Work{} = work, %Languages.Language{} = language, xml, version_data) do
    Versions.find_or_create_version(
      Map.merge(version_data, %{
        filemd5hash: :crypto.hash(:md5, xml) |> Base.encode16(case: :lower),
        language_id: language.id,
        work_id: work.id
      })
    )
  end

  defp create_work(%TextGroups.TextGroup{} = text_group) do
    Works.find_or_create_work(%{
      description: "",
      english_title: "Ajax",
      original_title: "Αἶας",
      urn: "urn:cts:greekLit:tlg0011.tlg003",
      text_group_id: text_group.id
    })
  end

  defp xml_files do
    [
      {"priv/static/xml/tlg0011.tlg003.ajmc-lj.xml",
       %{
         description: "Sophocles' <i>Ajax</i>, edited by Hugh Lloyd-Jones",
         filename: "tlg0011.tlg003.ajmc-lj.xml",
         label: "Lloyd-Jones (1994)",
         urn: "urn:cts:greekLit:tlg0011.tlg003.ajmc-lj",
         version_type: :edition
       }},
      {"priv/static/xml/tlg0011.tlg003.1st1K-grc1.xml",
       %{
         description:
           "Sophoclis Aiax: commentario perpetuo illustravit Christ. Augustus Lobeck. Editio Tertia. Edited by Francis Storr",
         filename: "tlg0011.tlg003.1st1K-grc1.xml",
         label: "Lobeck (1866)",
         urn: "urn:cts:greekLit:tlg0011.tlg003.ajmc-lobeck",
         version_type: :edition
       }},
      {"priv/static/xml/tlg0011.tlg003.opp-grc1.xml",
       %{
         description:
           "Sophoclis Fabulae: recognovit brevique adnotatione critica instruxit, edited by A. C. Pearson",
         filename: "tlg0011.tlg003.opp-grc1.xml",
         label: "Pearson (1924)",
         urn: "urn:cts:greekLit:tlg0011.tlg003.ajmc-pearson",
         version_type: :edition
       }}
    ]
    |> Enum.map(&{Application.app_dir(:text_server, elem(&1, 0)), elem(&1, 1)})
  end

  defp synopsis_json do
    Application.app_dir(:text_server, "priv/static/json/ajax_synopsis.json")
  end
end
