defmodule CvaxTest do
  use ExUnit.Case
  doctest Cvax
  # TODO: write more detailed test descriptions
  # TODO: write exhaustive test cases
  # TODO: write tests for compounds variants

  test "empty map or any other value" do
    configs = [nil, "string", 420, [], {}, %{}, true, false, fn -> "" end]

    cases = %{
      [%{}, "", [], {true, false}, 69, %{font_size: :sm}, nil, true, false, fn -> 1212 end] => "",
      [
        %{font_size: :sm, class: "shadow-sm"},
        [class: "shadow-sm"],
        {:class, "shadow-sm"},
        %{class: "shadow-sm"}
      ] => "shadow-sm"
    }

    Enum.map(configs, fn config ->
      variants = Cvax.compose_variants(config)

      Enum.map(cases, fn {inputs, output} ->
        Enum.map(inputs, fn input -> assert variants.(input) == output end)
      end)
    end)
  end

  test "base only" do
    configs = [
      %{
        base: "rounded-md"
      },
      %{
        base: ["rounded-md"]
      },
      %{
        base: ["rounded-md"],
        variants: %{}
      },
      %{
        base: %{class: "rounded-md"},
        variants: nil
      },
      %{
        base: [true: "rounded-md"],
        variants: [nil]
      },
      %{
        base: %{class: [true: %{class: [true: "rounded-md"]}]},
        variants: {}
      }
    ]

    cases = %{
      [
        %{},
        "",
        [],
        {true, false},
        69,
        nil,
        true,
        false,
        fn -> nil end,
        %{class: ""}
      ] => "rounded-md",
      [
        [class: "shadow-sm"],
        [{:class, "shadow-sm"}],
        %{class: "shadow-sm", some: "some random"}
      ] => "rounded-md shadow-sm",
      [
        %{class: "shadow-sm"}
      ] => "rounded-md shadow-sm"
    }

    Enum.map(configs, fn config ->
      variants = Cvax.compose_variants(config)

      Enum.map(cases, fn {inputs, output} ->
        Enum.map(inputs, fn input -> assert variants.(input) == output end)
      end)
    end)
  end

  test "base and variants" do
    configs = [
      %{
        base: "rounded-md",
        variants: %{
          intent: %{
            primary: "bg-red-300",
            secondary: "bg-slate-100",
            outline: "ring-1 ring-red-300"
          },
          font_size: %{
            xs: "text-xs",
            sm: "text-sm",
            base: "text-base",
            md: "text-md",
            lg: "text-lg"
          },
          size: %{
            sm: "p-2",
            lg: "p-4",
            xl: "p-12"
          }
        }
      }
    ]

    cases = %{
      [
        %{},
        "",
        [],
        {true, false},
        69,
        nil,
        true,
        false,
        fn -> nil end,
        %{class: ""}
      ] => "rounded-md",
      [
        [class: "shadow-sm"],
        [
          {:class, "shadow-sm"},
          {:some, "some"},
          {:not_existing, "not existings"},
          {true, "true"}
        ],
        %{class: "shadow-sm"}
      ] => "rounded-md shadow-sm",
      [
        %{font_size: :sm, class: "shadow-sm"}
      ] => "rounded-md text-sm shadow-sm",
      [
        %{font_size: :sm, size: :xl, class: "shadow-sm", intent: :primary}
      ] => "rounded-md text-sm bg-red-300 p-12 shadow-sm",
      [
        [{:font_size, :sm}, {:size, :xl}, {:intent, :primary}, {:class, "shadow-sm"}]
      ] => "rounded-md text-sm p-12 bg-red-300 shadow-sm"
    }

    Enum.map(configs, fn config ->
      variants = Cvax.compose_variants(config)

      Enum.map(cases, fn {inputs, output} ->
        Enum.map(inputs, fn input -> assert variants.(input) == output end)
      end)
    end)
  end

  test "base, variants and default variants" do
    configs = %{
      base: "rounded-md",
      variants: %{
        intent: %{
          primary: "bg-red-300",
          secondary: "bg-slate-100",
          outline: "ring-1 ring-red-300"
        },
        font_size: %{
          xs: "text-xs",
          sm: "text-sm",
          base: "text-base",
          md: "text-md",
          lg: "text-lg"
        },
        size: %{
          sm: "p-2",
          lg: "p-4",
          xl: "p-12"
        }
      },
      default_variants: %{
        size: :xl,
        font_size: :base,
        intent: :secondary
      }
    }

    with_variants = Cvax.compose_variants(configs)

    assert with_variants.(nil) ==
             "rounded-md text-base bg-slate-100 p-12"

    assert with_variants.(%{}) ==
             "rounded-md text-base bg-slate-100 p-12"

    assert with_variants.(%{font_size: :md}) ==
             "rounded-md bg-slate-100 p-12 text-md"

    assert with_variants.(font_size: :xs) ==
             "rounded-md bg-slate-100 p-12 text-xs"

    assert with_variants.(font_size: :lg, size: :lg, intent: :outline, class: "shadow-sm") ==
             "rounded-md text-lg p-4 ring-1 ring-red-300 shadow-sm"

    assert with_variants.(%{class: "shadow-sm", size: :lg, font_size: :lg, intent: :outline}) ==
             "rounded-md text-lg ring-1 ring-red-300 p-4 shadow-sm"

    assert with_variants.(
             size: :lg,
             font_size: :sm,
             class: [
               "font-bold",
               %{class: ["sm:text-xl", {true, "lg:text-3xl"}]}
             ]
           ) ==
             "rounded-md bg-slate-100 p-4 text-sm font-bold sm:text-xl lg:text-3xl"

    assert with_variants.(
             size: :lg,
             font_size: :sm,
             intent: :primary,
             not_existing: :sm,
             class: "leading-7"
           ) ==
             "rounded-md p-4 text-sm bg-red-300 leading-7"
  end

  test "cx" do
    test_cases = %{
      %{} => "",
      {} => "",
      nil => "",
      false => "",
      true => "",
      fn -> "" end => "",
      %{false: "one"} => "",
      [%{true: "one"}, %{false: "two"}, %{true: "three"}] => "one three",
      {true, "one"} => "one",
      {false, "false"} => "",
      {true,
       [
         %{},
         {true, "one"},
         %{false: "false"},
         {true, "two"},
         {true, "three"},
         {true, [[{true, "four"}]]},
         [
           "five",
           [
             ["six"],
             [
               nil,
               false,
               true,
               %{},
               [
                 %{
                   true: [
                     {true, "seven"},
                     %{false: "eight"},
                     {true, "nine"},
                     {true, [[{true, "ten"}]]}
                   ]
                 }
               ],
               {true, "eleven"},
               {false, "false"},
               nil
             ]
           ]
         ]
       ]} => "one two three four five six seven nine ten eleven",
      [
        %{true: "one"},
        %{false: "false"},
        %{true: "two"},
        %{true: "three"},
        %{true: [[%{true: "four"}]]}
      ] => "one two three four",
      [
        %{},
        %{true: "one"},
        %{false: "false"},
        %{true: "two"},
        %{true: "three"},
        %{true: [[%{true: "four"}]]},
        [
          "five",
          [
            ["six"],
            [
              nil,
              false,
              true,
              %{},
              [
                %{
                  true: [
                    %{true: "seven"},
                    %{false: "eight"},
                    %{true: "nine"},
                    %{true: [[%{true: "ten"}]]}
                  ]
                }
              ],
              {true, "eleven"},
              {false, "false"},
              nil
            ]
          ]
        ]
      ] => "one two three four five six seven nine ten eleven",
      1 => "",

      # Mock classes
      "bg-blue-500 text-white" => "bg-blue-500 text-white",
      {true, "bg-blue-500 text-white"} => "bg-blue-500 text-white",
      [true: "bg-blue-500 text-white"] => "bg-blue-500 text-white",
      [other: "bg-blue-500 text-white"] => "",
      [class: "bg-blue-500 text-white"] => "bg-blue-500 text-white",
      {:other, "bg-blue-500 text-white"} => "",
      %{true: "bg-blue-500 text-white"} => "bg-blue-500 text-white",
      %{false: "bg-blue-500 text-white"} => "",
      %{other: "bg-blue-500 text-white"} => "",
      [{true, "bg-blue-500 text-white"}, {false, "bg-red-500 text-black"}] =>
        "bg-blue-500 text-white",
      [%{true: "bg-blue-500 text-white"}, %{false: "bg-red-500 text-black"}] =>
        "bg-blue-500 text-white",
      ["bg-blue-500 text-white", "bg-red-500 text-black"] =>
        "bg-blue-500 text-white bg-red-500 text-black",
      [{true, [{true, [{true, "bg-blue-500 text-white"}]}]}] => "bg-blue-500 text-white",
      [[], "p-4"] => "p-4",
      "" => ""
    }

    Enum.map(test_cases, fn {input, output} ->
      assert Cvax.cx(input) == output
    end)
  end
end
