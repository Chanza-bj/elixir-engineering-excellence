# Structural validator for this Agent Skill package.
#
#   elixir scripts/validate_skill.exs
#
# Checks frontmatter, name/description constraints, reference links in every
# Markdown file, and that every ```elixir block parses. It does not check
# engineering correctness or that examples compile against real dependencies.

root = Path.expand("..", __DIR__)
skill_path = Path.join(root, "SKILL.md")
refs_dir = Path.join(root, "references")

# Normalise CRLF so files saved on Windows validate the same way.
read = fn path -> path |> File.read!() |> String.replace("\r\n", "\n") end

errors =
  if File.exists?(skill_path) do
    content = read.(skill_path)

    frontmatter_errors =
      case Regex.run(~r/\A---\n(.*?)\n---\n/s, content) do
        nil ->
          ["SKILL.md must begin with a closed YAML frontmatter block"]

        [_, fm] ->
          name = Regex.run(~r/^name:\s*(.+)$/m, fm, capture: :all_but_first)
          desc = Regex.run(~r/^description:\s*(.+)$/m, fm, capture: :all_but_first)

          name_errors =
            case name do
              nil ->
                ["Frontmatter missing name"]

              [n] ->
                n = String.trim(n)

                [
                  !Regex.match?(~r/\A[a-z0-9]+(-[a-z0-9]+)*\z/, n) &&
                    "name must be lowercase letters, digits, and single hyphens: #{n}",
                  String.length(n) > 64 && "name exceeds 64 characters",
                  n != Path.basename(root) &&
                    "name '#{n}' does not match directory '#{Path.basename(root)}'"
                ]
            end

          desc_errors =
            case desc do
              nil -> ["Frontmatter missing description"]
              [d] -> [String.length(String.trim(d)) > 1024 && "description exceeds 1024 characters"]
            end

          Enum.filter(name_errors ++ desc_errors, &is_binary/1)
      end

    md_files = [skill_path | Path.wildcard(Path.join(refs_dir, "*.md"))]

    link_errors =
      for file <- md_files,
          [target] <- Regex.scan(~r/`((?:references\/)?[a-z0-9-]+\.md)`/, read.(file), capture: :all_but_first),
          # SKILL.md links use references/x.md; reference files link to siblings by bare name.
          resolved = if(String.starts_with?(target, "references/"), do: Path.join(root, target), else: Path.join(Path.dirname(file), target)),
          not File.exists?(resolved),
          do: "Broken reference in #{Path.relative_to(file, root)}: #{target}"

    empty_errors =
      for file <- Path.wildcard(Path.join(refs_dir, "*.md")),
          String.trim(read.(file)) == "",
          do: "Empty reference: #{Path.relative_to(file, root)}"

    parse_errors =
      for file <- md_files,
          {[code], i} <- Enum.with_index(Regex.scan(~r/```elixir\n(.*?)```/s, read.(file), capture: :all_but_first), 1),
          match?({:error, _}, Code.string_to_quoted(code)),
          do: "Elixir block ##{i} in #{Path.relative_to(file, root)} does not parse"

    if byte_size(content) > 20_000,
      do: IO.puts("WARNING: SKILL.md is large; consider moving specialist material into references.")

    frontmatter_errors ++ Enum.uniq(link_errors) ++ empty_errors ++ parse_errors
  else
    ["Missing SKILL.md"]
  end

if errors == [] do
  IO.puts("VALIDATION PASSED")
  IO.puts("References: #{length(Path.wildcard(Path.join(refs_dir, "*.md")))}")
else
  IO.puts("VALIDATION FAILED")
  Enum.each(errors, &IO.puts("- #{&1}"))
  System.halt(1)
end
