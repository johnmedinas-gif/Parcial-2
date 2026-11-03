# Carga los módulos de lib/ en orden (primero los structs, que otros módulos necesitan).
# Así se puede ejecutar:  elixir 01-Rescate.exs   sin compilar antes.
[
  "util",
  "terreno",
  "edificio",
  "recorrido",
  "entrada",
  "validacion_edificio",
  "busqueda",
  "expansion",
  "svg_rescate",
  "parentesis",
  "validacion_parentesis"
]
|> Enum.each(fn modulo ->
  Code.require_file(Path.join(["lib", modulo <> ".ex"]), __DIR__)
end)
