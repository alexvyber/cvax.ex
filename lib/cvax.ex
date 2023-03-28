defmodule Cvax do
  @moduledoc """
  Documentation for `Cvax`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Cvax.cn()
      :world

  """

  @type class_value :: String.t() | nil | boolean() | list(class_value)

  def cn() do
    :world
  end

  # cvax
  # ============================================
  @spec cx(any()) :: String.t()
  def cx(classes) when is_list(classes) do
    List.flatten(classes)
    |> Enum.filter(fn x -> !(x == nil || x == true || x == false) end)
    |> Enum.map(fn x -> if(is_binary(x), do: x, else: cx(x)) end)
    |> Enum.join(" ")
    |> String.trim()
    |> String.replace(~r/ +/, " ")
  end

  def cx(classes) when is_binary(classes), do: classes
  def cx({true, classes}), do: if(is_binary(classes), do: classes, else: cx(classes))
  def cx(%{true => classes}), do: if(is_binary(classes), do: classes, else: cx(classes))
  def cx(_), do: ""

  # variants
  # ============================================
  @type configs :: %{
          base: String.t(),
          variants: %{},
          default_variants: %{},
          compound_variants: [%{}]
        }
  @spec compose_variants(%{
          base: String.t(),
          variants: %{},
          default_variants: %{},
          compound_variants: [%{}]
        }) :: (%{} | nil -> String.t())
  def compose_variants(configs) do
    case configs do
      %{variants: variants} when is_map(variants) ->
        fn props ->
          if is_map(props) do
            Enum.reduce(variants, %{defaults: [], variants: []}, fn {key, prop}, acc ->
              case Map.get(props, key) do
                nil ->
                  %{
                    defaults: [acc.defaults, prop[configs.default_variants[key]]],
                    variants: acc.variants
                  }

                prop_key ->
                  %{defaults: acc.defaults, variants: [acc.variants, prop[prop_key]]}
              end
            end)
            |> then(fn x ->
              cx([configs.base, x.defaults, x.variants, Map.get(props, :class)])
            end)
          else
            cx([
              configs.base,
              Enum.map(configs.default_variants, fn {key, prop} ->
                Map.get(configs.variants[key], prop)
              end)
            ])
          end
        end

      %{base: base} when is_binary(base) ->
        fn props -> cx([props, base, Map.get(props, :class)]) end

      _ ->
        fn props -> cx(Map.get(props, :class)) end
    end
  end
end

# IO.inspect(key)
# IO.inspect(prop)
