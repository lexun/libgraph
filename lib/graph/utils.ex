defmodule Graph.Utils do
  @moduledoc false
  @compile {:inline, [find_vertex_id: 2,
                      edge_weight: 3]}

  @binary_heap_limit 64

  @doc """
  A large portion of the code for `sizeof/1` is based on `erlang_term` which can be found
  at [here](https://github.com/okeuday/erlang_term), authored by Michael Truog, and licensed
  under the MIT license.
  """
  def sizeof(term) do
    sizeof(term, :erlang.system_info(:wordsize))
  end
  defp sizeof(term, wordsize) do
    sizeof_term_local(term, wordsize) + sizeof_term(term)
  end

  defp sizeof_term(term) when is_list(term) do
    sizeof_list(term)
  end
  defp sizeof_term(term) when is_tuple(term) do
    sizeof_tuple(term)
  end
  defp sizeof_term(%{__struct__: _} = term) when is_map(term) do
    Enum.reduce(Map.from_struct(term), 0, fn {k, v}, size ->
      sizeof_term(k) + sizeof_term(v) + size
    end)
  end
  defp sizeof_term(term) do
    sizeof_term_global(term)
  end

  defp sizeof_term_local(term, wordsize) do
    # stack/register size + heap size
    (1 + :erts_debug.flat_size(term)) * wordsize
  end

  defp sizeof_term_global(term) when is_binary(term) do
    case :erlang.byte_size(term) do
      bsize when bsize > @binary_heap_limit ->
        # refc binary
        bsize
      _ ->
        # heap binary
        0
    end
  end
  defp sizeof_term_global(_term) do
    0
  end

  defp sizeof_list(l, size \\ 0)

  defp sizeof_list([], size), do: size
  defp sizeof_list([term|rest], size) do
    sizeof_list(rest, size+sizeof_term(term))
  end
  defp sizeof_list(term, size) do
    # improper list
    size + sizeof_term(term)
  end

  defp sizeof_tuple(term) do
    sizeof_tuple(term, 1, :erlang.tuple_size(term), 0)
  end
  defp sizeof_tuple(term, n, n, size) do
    sizeof_term(:erlang.element(n, term)) + size
  end
  defp sizeof_tuple(term, i, n, size) do
    sizeof_tuple(term, i+1, n, size+sizeof_term(:erlang.element(i, term)))
  end

  def edge_weight(%Graph{edges_meta: em}, a, b) do
    case Map.get(em, {a, b}) do
      %{weight: w} -> w
      _ -> 0
    end
  end

  def find_vertex_id(%Graph{vertices: vs}, v) do
    case Map.get(vs, v) do
      nil  -> nil
      v_id -> {:ok, v_id}
    end
  end
end
