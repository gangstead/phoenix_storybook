Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Phx.Gen.StorybookTest do
  use ExUnit.Case
  import PhoenixStorybook.MixHelper
  alias Mix.Tasks.Phx.Gen.Storybook

  setup do
    Mix.Task.clear()
    :ok
  end

  @tag :capture_log
  test "mix phx.gen.storybook generates a working storybook", config do
    in_tmp_project(config.test, fn ->
      for _ <- 1..8, do: send(self(), {:mix_shell_input, :yes?, true})
      Storybook.run([])

      [{index, _}] = Code.compile_file("storybook/_root.index.exs")
      assert index.folder_icon() == {:fa, "book-open", :light, "lsb-mr-1"}

      [{page, _}] = Code.compile_file("storybook/welcome.story.exs")
      assert page.storybook_type() == :page

      [{backend, _}] = Code.compile_file("lib/phoenix_storybook_web/storybook.ex")
      assert backend.config(:otp_app) == :phoenix_storybook_web
      assert backend.config(:sandbox_class) == "phoenix-storybook-web"

      assert_file("assets/js/storybook.js")

      assert_file("assets/css/storybook.css", fn file ->
        assert String.contains?(file, ~s|@import "tailwindcss/base|)
      end)

      assert_shell_receive(:info, ~r|Starting storybook generation|)
      assert_shell_receive(:info, ~r|creating lib/phoenix_storybook_web/storybook.ex|)
      assert_shell_receive(:info, ~r|creating storybook/_root.index.exs|)
      assert_shell_receive(:info, ~r|creating storybook/welcome.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/button.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/table.story.exs|)
      assert_shell_receive(:info, ~r|creating assets/css/storybook.css|)
      assert_shell_receive(:info, ~r|creating assets/js/storybook.js|)
      assert_shell_receive(:yes?, ~r|Add the following to your.*router.ex.*:|)

      assert_shell_receive(
        :yes?,
        ~r|Add.*js/storybook.js.*as a new entry point to your esbuild args in .*config/config.exs.*|
      )

      assert_shell_receive(
        :yes?,
        ~r|Add a new Tailwind build profile for.*css/storybook.css.*in.*config/config.exs.*|
      )

      assert_shell_receive(
        :yes?,
        ~r|Add a new.*endpoint watcher.*for your new Tailwind build profile in.*config/dev.exs.*|
      )

      assert_shell_receive(
        :yes?,
        ~r|Add a new.*live_reload pattern.*to your endpoint in.*config/dev.exs.*|
      )

      assert_shell_receive(:yes?, ~r|Add your storybook content to.*\.formatter.exs.*|)
      assert_shell_receive(:yes?, ~r|Add an alias to .*mix.exs.*|)
      assert_shell_receive(:yes?, ~r|Add a COPY directive in .*Dockerfile.*|)
    end)
  end

  @tag :capture_log
  test "mix phx.gen.storybook --no-tailwind generates a working storybook without tailwind",
       config do
    in_tmp_project(config.test, fn ->
      for _ <- 1..5, do: send(self(), {:mix_shell_input, :yes?, true})
      Storybook.run(["--no-tailwind"])

      assert_file("storybook/_root.index.exs")
      assert_file("storybook/welcome.story.exs")
      assert_file("lib/phoenix_storybook_web/storybook.ex")

      assert_file("assets/js/storybook.js")

      assert_file("assets/css/storybook.css", fn file ->
        refute String.contains?(file, ~s|@import "tailwindcss/base|)
      end)

      assert_shell_receive(:info, ~r|Starting storybook generation|)
      assert_shell_receive(:info, ~r|creating lib/phoenix_storybook_web/storybook.ex|)
      assert_shell_receive(:info, ~r|creating storybook/_root.index.exs|)
      assert_shell_receive(:info, ~r|creating storybook/welcome.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/button.story.exs|)
      assert_shell_receive(:info, ~r|creating storybook/core_components/table.story.exs|)
      assert_shell_receive(:info, ~r|creating assets/css/storybook.css|)
      assert_shell_receive(:info, ~r|creating assets/js/storybook.js|)
      assert_shell_receive(:yes?, ~r|Add the following to your.*router.ex.*:|)

      assert_shell_receive(
        :yes?,
        ~r|Add.*js/storybook.js.*as a new entry point to your esbuild args in .*config/config.exs.*|
      )

      assert_shell_receive(
        :yes?,
        ~r|Add a new.*live_reload pattern.*to your endpoint in.*config/dev.exs.*|
      )

      assert_shell_receive(:yes?, ~r|Add your storybook content to.*\.formatter.exs.*|)
      assert_shell_receive(:yes?, ~r|Add a COPY directive in .*Dockerfile.*|)
    end)
  end

  test "with wrong flags it fails", config do
    in_tmp_project(config.test, fn ->
      assert_raise Mix.Error, "Invalid option: --unknown-flag", fn ->
        Storybook.run(["--unknown-flag"])
      end
    end)
  end

  defp assert_shell_receive(kind, pattern) do
    assert_receive {:mix_shell, ^kind, [msg]}
    assert msg =~ pattern
  end
end

defmodule PhoenixStorybookWeb.CoreComponents do
  use Phoenix.Component
  def button(assigns), do: ~H[]
  def table(assigns), do: ~H[]
end
