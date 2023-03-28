defmodule CvaxTest do
  use ExUnit.Case
  doctest Cvax

  test "greets the world" do
    assert Cvax.cn() == :world
  end

  describe "variants..." do
    test "..." do
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
          size: :lg,
          font_size: :base,
          intent: :secondary
        },
        compound_Variants: %{}
      }

      # catch all
      catch_all_variants = Cvax.compose_variants(%{})

      assert catch_all_variants.(%{font_size: :sm, intent: :primary, class: "shadow-sm"}) ==
               "shadow-sm"

      # with only base
      with_variants = Cvax.compose_variants(%{base: "rounded-md"})

      assert with_variants.(%{font_size: :sm, intent: :primary, class: "shadow-sm"}) ==
               "rounded-md shadow-sm"

      # with variants
      with_variants = Cvax.compose_variants(configs)

      # with props
      assert with_variants.(%{font_size: :sm, intent: :primary}) ==
               "rounded-md p-4 text-sm bg-red-300"

      # with class
      assert with_variants.(%{font_size: :sm, intent: :primary, class: "shadow-sm"}) ==
               "rounded-md p-4 text-sm bg-red-300 shadow-sm"

      # with nil
      assert with_variants.(nil) ==
               "rounded-md text-base bg-slate-100 p-4"
    end
  end

  describe "cx works..." do
    test "cx works..." do
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
        {:other, "bg-blue-500 text-white"} => "",
        %{true: "bg-blue-500 text-white"} => "bg-blue-500 text-white",
        %{false: "bg-blue-500 text-white"} => "",
        %{other: "bg-blue-500 text-white"} => "",
        [{true, "bg-blue-500 text-white"}, {false, "bg-red-500 text-black"}] =>
          "bg-blue-500 text-white",
        [%{true: "bg-blue-500 text-white"}, %{false: "bg-red-500 text-black"}] =>
          "bg-blue-500 text-white",
        [true && "bg-blue-500 text-white", true && "bg-red-500 text-black"] =>
          "bg-blue-500 text-white bg-red-500 text-black",
        [{true, [{true, [{true, "bg-blue-500 text-white"}]}]}] => "bg-blue-500 text-white",
        (true && "bg-blue-500 text-white") => "bg-blue-500 text-white",
        (false || "bg-blue-500 text-white") => "bg-blue-500 text-white",
        # [[] | "p-4"] => "p-4",
        "" => ""
      }

      Enum.map(test_cases, fn {input, output} ->
        assert Cvax.cx(input) == output
      end)
    end
  end
end
