defmodule Cvax do
  # TODO: write docs
  # TODO: write typespecs
  # TODO: write functionality for compound components
  # TODO: refactor implementaations

  @moduledoc """
  Documentation for `Cvax`.
  """

  # cvax
  # ============================================
  @spec cx(any()) :: String.t()
  def cx(classes) when is_binary(classes) do
    classes
    |> String.trim()
    |> String.replace(~r/ +/, " ")
  end

  def cx(class: classes), do: cx(classes)
  def cx({:class, classes}), do: cx(classes)
  def cx(%{:class => classes}), do: cx(classes)

  def cx(classes) when is_list(classes) do
    List.flatten(classes)
    |> Enum.filter(fn x -> !(x == nil || x == true || x == false) end)
    |> Enum.map(fn x -> if(is_binary(x), do: x, else: cx(x)) end)
    |> Enum.join(" ")
    |> String.trim()
    |> String.replace(~r/ +/, " ")
  end

  def cx({true, classes}), do: if(is_binary(classes), do: classes, else: cx(classes))
  def cx(%{true => classes}), do: if(is_binary(classes), do: classes, else: cx(classes))
  def cx(_), do: ""

  # variants
  # ============================================
  @spec compose_variants(%{
          base: String.t(),
          variants: %{},
          default_variants: %{},
          # TODO:
          compound_variants: [%{}]
        }) :: (any() -> String.t())
  def compose_variants(configs) do
    case configs do
      %{variants: variants, default_variants: default_variants}
      when is_map(variants) and map_size(variants) > 0 and is_map(default_variants) ->
        fn
          props when is_map(props) and map_size(props) > 0 ->
            get_classes_from_map(props, configs.base, variants, default_variants)

          props when is_list(props) ->
            get_classes_from_list(props, configs.base, variants, default_variants)

          _props ->
            return_defaults(configs)
        end

      %{variants: variants}
      when is_map(variants) and map_size(variants) > 0 ->
        fn
          props when is_map(props) and map_size(props) > 0 ->
            get_classes_from_map(props, configs.base, variants)

          props when is_list(props) ->
            get_classes_from_list(props, configs.base, variants)

          _props ->
            return_defaults(configs)
        end

      %{base: base} ->
        fn
          %{:class => class} -> cx([base, class])
          {:class, class} -> cx([base, class])
          [class: class] -> cx([base, class])
          _ -> cx(base)
        end

      _ ->
        fn
          %{:class => class} -> cx(class)
          {:class, class} -> cx(class)
          [class: class] -> cx(class)
          _ -> ""
        end
    end
  end

  defp get_classes_from_list(props, base, variants) do
    # get variants
    Enum.reduce(
      props,
      %{defaults: [], variants: [], class: "", configs_variants: variants},
      fn
        {:class, class}, acc ->
          Map.put(acc, :class, class)

        {props_key, props_prop}, acc ->
          case Map.has_key?(variants, props_key) do
            true ->
              Map.put(acc, :variants, [
                acc.variants,
                Map.get(variants[props_key], props_prop)
              ])
              |> Map.put(:configs_variants, Map.delete(acc.configs_variants, props_key))

            false ->
              acc
          end
      end
    )

    # get default variants
    |> then(fn x ->
      Enum.reduce(
        x.configs_variants,
        x,
        fn _, acc ->
          # fn {key, prop}, acc ->
          Map.put(acc, :defaults, [acc.defaults])
        end
      )
    end)

    # stringify variants
    |> then(fn
      acc ->
        cx([base, acc.defaults, acc.variants, acc.class])
    end)
  end

  defp get_classes_from_list(props, base, variants, default_variants) do
    # get variants
    Enum.reduce(
      props,
      %{defaults: [], variants: [], class: "", configs_variants: variants},
      fn
        {:class, class}, acc ->
          Map.put(acc, :class, class)

        {props_key, props_prop}, acc ->
          case Map.has_key?(variants, props_key) do
            #
            true ->
              Map.put(acc, :variants, [
                acc.variants,
                Map.get(variants[props_key], props_prop)
              ])
              |> Map.put(:configs_variants, Map.delete(acc.configs_variants, props_key))

            false ->
              acc
          end
      end
    )

    # get default variants
    |> then(fn x ->
      Enum.reduce(
        x.configs_variants,
        x,
        fn {key, prop}, acc ->
          Map.put(acc, :defaults, [
            acc.defaults,
            Map.get(prop, default_variants[key])
          ])
        end
      )
    end)

    # stringify variants
    |> then(fn
      acc ->
        cx([base, acc.defaults, acc.variants, acc.class])
    end)
  end

  defp get_classes_from_map(props, base, variants) do
    Enum.reduce(variants, %{defaults: [], variants: []}, fn {key, prop}, acc ->
      case Map.get(props, key) do
        nil ->
          %{
            defaults: [
              acc.defaults
            ],
            variants: acc.variants
          }

        prop_key ->
          %{defaults: acc.defaults, variants: [acc.variants, prop[prop_key]]}
      end
    end)
    |> then(fn
      %{defaults: defaults, variants: variants} ->
        cx([base, defaults, variants, Map.get(props, :class)])
    end)
  end

  defp get_classes_from_map(props, base, variants, default_variants) do
    Enum.reduce(variants, %{defaults: [], variants: []}, fn {key, prop}, acc ->
      case Map.get(props, key) do
        nil ->
          %{
            defaults: [acc.defaults, prop[Map.get(default_variants, key)]],
            variants: acc.variants
          }

        prop_key ->
          %{defaults: acc.defaults, variants: [acc.variants, prop[prop_key]]}
      end
    end)
    |> then(fn
      %{defaults: defaults, variants: variants} ->
        cx([base, defaults, variants, Map.get(props, :class)])
    end)
  end

  defp return_defaults(configs) do
    cx([
      configs.base,
      Map.has_key?(configs, :default_variants) &&
        Enum.map(configs.default_variants, fn {key, prop} ->
          Map.get(configs.variants[key], prop)
        end)
    ])
  end
end
