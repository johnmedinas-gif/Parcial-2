# Ejecutar con:  elixir test/parcial2_test.exs   (desde la carpeta parcial2)
Code.require_file("../cargar.exs", __DIR__)

ExUnit.start()

defmodule Parcial2Test do
  use ExUnit.Case

  # ---------------- Problema 4: paréntesis ----------------
  test "n=3, p=2 genera exactamente las cuatro cadenas, en orden" do
    assert Enum.to_list(Parentesis.generar(3, 2)) == ["(()())", "(())()", "()(())", "()()()"]
  end

  test "sin restricción de profundidad se obtienen los números de Catalan" do
    assert Parentesis.contar(4, 4) == 14
    assert Parentesis.contar(8, 8) == 1430
  end

  test "el generador es perezoso: la primera solución de n=18 llega al instante" do
    assert Parentesis.primera(18, 18) == [String.duplicate("(", 18) <> String.duplicate(")", 18)]
  end

  test "caso límite n=1" do
    assert Enum.to_list(Parentesis.generar(1, 1)) == ["()"]
  end

  test "la profundidad máxima poda soluciones" do
    assert Parentesis.contar(4, 2) == 8
    assert Parentesis.contar(5, 3) == 34
  end

  test "la secuencia infinita se corta en n=8 y no calcula n=9" do
    assert Enum.take(Parentesis.secuencia(), 4) == [{1, 1}, {2, 2}, {3, 5}, {4, 14}]
  end

  test "verificación recursiva de propuestas" do
    assert %{valida: true} = ValidacionParentesis.verificar(3, 2, "(()())")

    assert %{valida: false, motivos: [motivo]} = ValidacionParentesis.verificar(3, 2, "((()))")
    assert motivo =~ "profundidad"

    assert %{valida: false, motivos: motivos} = ValidacionParentesis.verificar(3, 2, "())(()")
    assert Enum.any?(motivos, &(&1 =~ "\"())\""))

    assert %{valida: false, motivos: motivos} = ValidacionParentesis.verificar(2, 2, "(x))")
    assert Enum.any?(motivos, &(&1 =~ "no permitido"))

    assert %{valida: false} = ValidacionParentesis.verificar(3, 3, "")
  end

  # ---------------- Problema 1: robot de rescate ----------------
  defp cargar(carpeta) do
    terrenos_leidos = Entrada.leer_terrenos("#{carpeta}/terrenos.csv")
    filas = Entrada.leer_edificio("#{carpeta}/edificio.txt")
    bateria = Entrada.leer_bateria("#{carpeta}/bateria.txt")
    {terrenos_leidos, filas, bateria}
  end

  defp preparar(carpeta) do
    {terrenos_leidos, filas, bateria} = cargar(carpeta)
    terrenos = terrenos_leidos |> Entrada.terrenos_validos() |> Map.new(&{&1.simbolo, &1})
    {Edificio.construir(filas), terrenos, Entrada.valor_bateria(bateria)}
  end

  test "el ejemplo del enunciado es consistente" do
    {t, f, b} = cargar("datos/rescate")
    assert ValidacionEdificio.validar(t, f, b) == []
  end

  test "el ejemplo del enunciado tiene 6 recorridos y el mejor cuesta 5" do
    {edificio, terrenos, bateria} = preparar("datos/rescate")
    recorridos = edificio |> Busqueda.recorridos(terrenos, bateria) |> Enum.to_list()

    assert length(recorridos) == 6
    assert Enum.min_by(recorridos, & &1.energia).energia == 5
    assert hd(recorridos).posiciones == [{1, 1}, {1, 2}, {1, 3}, {1, 4}]
  end

  test "ningún recorrido repite casillas ni supera B" do
    {edificio, terrenos, bateria} = preparar("pruebas/rescate/empates")

    for r <- Busqueda.recorridos(edificio, terrenos, bateria) do
      assert length(r.posiciones) == length(Enum.uniq(r.posiciones))
      assert r.energia <= bateria
    end
  end

  test "con batería insuficiente no hay recorridos" do
    {edificio, terrenos, bateria} = preparar("pruebas/rescate/sin_ruta")
    assert Enum.to_list(Busqueda.recorridos(edificio, terrenos, bateria)) == []
  end

  test "la relajación se estabiliza y detecta metas inalcanzables" do
    {edificio, terrenos, bateria} = preparar("datos/rescate")

    [{estado_a, _}, {estado_b, _}] =
      edificio
      |> Expansion.estados(terrenos, bateria)
      |> Stream.with_index()
      |> Stream.chunk_every(2, 1, :discard)
      |> Enum.find(fn [{a, _}, {b, _}] -> a == b end)

    assert estado_a == estado_b
    assert estado_a[edificio.meta] == 5

    {edificio, terrenos, bateria} = preparar("pruebas/rescate/meta_encerrada")
    final = edificio |> Expansion.estados(terrenos, bateria) |> Enum.at(20)
    refute Map.has_key?(final, edificio.meta)
  end

  test "la validación recursiva reporta todos los errores con ubicación" do
    {t, f, b} = cargar("pruebas/rescate/invalido")
    errores = ValidacionEdificio.validar(t, f, b)

    assert length(errores) == 9
    assert Enum.any?(errores, &(&1 =~ "coordenada {1,3}"))
    assert Enum.any?(errores, &(&1 =~ "bateria.txt línea 2"))
  end

  test "caso límite: S y M contiguos con batería exacta" do
    {edificio, terrenos, bateria} = preparar("pruebas/rescate/limite_minimo")
    assert [%Recorrido{energia: 1}] = edificio |> Busqueda.recorridos(terrenos, bateria) |> Enum.to_list()
  end

  test "escapar XML" do
    assert Util.escapar_xml("<a & \"b\">") == "&lt;a &amp; &quot;b&quot;&gt;"
  end
end
