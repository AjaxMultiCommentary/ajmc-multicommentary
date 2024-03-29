defmodule TextServer.Comments do
  @moduledoc """
  The Comments context.
  """

  import Ecto.Query, warn: false
  alias TextServer.Repo

  alias TextServer.Commentaries
  alias TextServer.Commentaries.CanonicalCommentary
  alias TextServer.Comments.Comment

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
  end

  def list_comments(current_user, first_line_n, last_line_n) when is_nil(current_user) do
    range = Range.new(first_line_n, last_line_n) |> Range.to_list()

    query =
      from(c in Comment,
        join: parent in assoc(c, :canonical_commentary),
        where:
          fragment("(? -> ? ->> 0)::int", c.urn, "citations") in ^range and
            parent.public_domain_year < ^NaiveDateTime.utc_now().year() and
            not is_nil(parent.public_domain_year),
        preload: [canonical_commentary: :creators]
      )

    Repo.all(query)
  end

  def list_comments(_current_user, first_line_n, last_line_n) do
    range = Range.new(first_line_n, last_line_n) |> Range.to_list()

    Comment
    |> where([c], fragment("(? -> ? ->> 0)::int", c.urn, "citations") in ^range)
    |> preload(canonical_commentary: :creators)
    |> Repo.all()
  end

  @doc """
  Returns a list of comments that have canonical_commentary_ids matching the given
  list.

  ## Examples

      iex> filter_comments([1, 2, 3])
      [%Comment{canonical_commentary_id: 1}, %Comment{canonical_commentary_id: 2}, ...]
  """
  def filter_comments(current_user, canonical_commentary_ids, first_n, last_n)
      when length(canonical_commentary_ids) == 0 do
    list_comments(current_user, first_n, last_n)
  end

  def filter_comments(current_user, canonical_commentary_ids, first_line_n, last_line_n)
      when is_nil(current_user) do
    range = Range.new(first_line_n, last_line_n) |> Range.to_list()

    query =
      from(c in Comment,
        join: parent in assoc(c, :canonical_commentary),
        where:
          fragment("(? -> ? ->> 0)::int", c.urn, "citations") in ^range and
            c.canonical_commentary_id in ^canonical_commentary_ids and
            parent.public_domain_year < ^NaiveDateTime.utc_now().year() and
            not is_nil(parent.public_domain_year),
        preload: [canonical_commentary: :creators]
      )

    Repo.all(query)
  end

  def filter_comments(_current_user, canonical_commentary_ids, first_line_n, last_line_n) do
    range = Range.new(first_line_n, last_line_n) |> Range.to_list()

    Comment
    |> where(
      [c],
      fragment("(? -> ? ->> 0)::int", c.urn, "citations") in ^range and
        c.canonical_commentary_id in ^canonical_commentary_ids
    )
    |> preload(canonical_commentary: :creators)
    |> Repo.all()
  end

  @doc """
  Used only for the API routes. Allows searching comments by `commentary_urn`, `start`,
  `end`, `search` (which searches the `content` field), and `lemma` parameters.
  """
  def search_comments(_current_user, attrs \\ %{}) do
    query =
      Comment
      |> by_commentary(attrs)
      |> within_range(attrs)
      |> with_lemma(attrs)
      |> search(attrs)

    Repo.all(query)
  end

  defp by_commentary(query, %{"commentary_urn" => commentary_urn}) do
    {:ok, urn} = CanonicalCommentary.full_urn(commentary_urn)

    commentary = Commentaries.get_canonical_commentary_by(%{urn: urn})

    query |> where([c], c.canonical_commentary_id == ^commentary.id)
  end

  defp by_commentary(query, _attrs), do: query

  defp search(query, %{"search" => search}) do
    s = "%#{search}%"
    query |> where([c], fragment("f_unaccent(?) ILIKE f_unaccent(?)", c.content, ^s))
  end

  defp search(query, _attrs), do: query

  defp with_lemma(query, %{"lemma" => lemma}) do
    s = "%#{lemma}%"
    query |> where([c], fragment("f_unaccent(?) ILIKE f_unaccent(?)", c.lemma, ^s))
  end

  defp with_lemma(query, _attrs), do: query

  defp within_range(query, %{"start" => start_n, "end" => end_n})
       when is_integer(start_n) and is_integer(end_n) do
    range = Range.new(start_n, end_n) |> Range.to_list()
    query |> where([c], fragment("(? -> ? ->> 0)::int", c.urn, "citations") in ^range)
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  def get_comment_by_urn!(%CTS.URN{} = urn) do
    Comment
    |> where([c], c.urn == ^urn)
    |> Repo.one!()
  end

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Upserts a comment.
  """
  def upsert_comment(attrs) do
    query =
      from(c in Comment,
        where:
          c.canonical_commentary_id == ^attrs.canonical_commentary_id and
            c.end_offset == ^attrs.end_offset and
            c.start_offset == ^attrs.start_offset
      )

    case Repo.one(query) do
      nil -> create_comment(attrs)
      comment -> update_comment(comment, attrs)
    end
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  def with_interface_id(%Comment{} = comment) do
    %{comment | interface_id: "comment-#{comment.id}"}
  end
end
