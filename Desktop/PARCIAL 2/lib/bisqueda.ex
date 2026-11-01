defmodule Busqueda do
  @moduledoc """
  Enumeración recursiva de TODOS los recorridos simples de S a M sin superar B.
  """

  @doc """
  Stream de %Recorrido{} en el orden fijo arriba, derecha, abajo, izquierda.

  terrenos es un mapa %{simbolo => %Terreno{}}.
  """
  def recorridos(%Edificio{inicio: inicio} = edificio, terrenos, bateria) do
    explorar(inicio, edificio, terrenos, bateria, MapSet.new([inicio]), [inicio], 0)
  end

  # Caso base (pattern matching: la posición actual ES la meta): se emite el recorrido.
  defp explorar(posicion, %Edificio{meta: posicion}, _terrenos, _bateria, _visitadas, camino, energia) do
    [Recorrido.crear(Enum.reverse(camino), energia)]
  end

  # Caso recursivo: probar los cuatro movimientos, en orden, de forma perezosa.
  defp explorar(posicion, edificio, terrenos, bateria, visitadas, camino, energia) do
    posicion
    |> Edificio.vecinos()
    |> Stream.flat_map(fn vecino ->
      intentar(vecino, edificio, terrenos, bateria, visitadas, camino, energia)
    end)
  end

  defp intentar(vecino, edificio, terrenos, bateria, visitadas, camino, energia) do
    with false <- MapSet.member?(visitadas, vecino),
         {:ok, terreno} <- terreno_en(edificio, terrenos, vecino),
         {:ok, nueva_energia} <- entrar(terreno, energia, bateria) do
      explorar(
        vecino,
        edificio,
        terrenos,
        bateria,
        MapSet.put(visitadas, vecino),
        [vecino | camino],
        nueva_energia
      )
    else
      _ -> []
    end
  end

  defp terreno_en(%Edificio{celdas: celdas}, terrenos, posicion) do
    with {:ok, simbolo} <- Map.fetch(celdas, posicion) do
      Map.fetch(terrenos, simbolo)
    end
  end

  # Pattern matching para rechazar terrenos no transitables y sin energía.
  defp entrar(%Terreno{transitable: false}, _energia, _bateria), do: :bloqueado

  defp entrar(%Terreno{costo: costo}, energia, bateria) when energia + costo <= bateria do
    {:ok, energia + costo}
  end

  defp entrar(%Terreno{}, _energia, _bateria), do: :sin_energia

  # ------------------------------------------------------------------
  # Acumulador de estadísticas (mantiene solo los mejores, no todos los recorridos)
  # ------------------------------------------------------------------

  @doc "Estado inicial del acumulador."
  def estadisticas_iniciales, do: %{total: 0, por_movimientos: nil, por_energia: nil}

  @doc "Incorpora un recorrido (con su id) conservando los empates."
  def acumular(estadisticas, id, %Recorrido{energia: energia} = recorrido) do
    item = {id, recorrido}

    %{
      estadisticas
      | total: estadisticas.total + 1,
        por_movimientos:
          mejorar(estadisticas.por_movimientos, Recorrido.movimientos(recorrido), item),
        por_energia: mejorar(estadisticas.por_energia, energia, item)
    }
  end

  defp mejorar(nil, valor, item), do: {valor, [item]}
  defp mejorar({mejor, _items}, valor, item) when valor < mejor, do: {valor, [item]}
  defp mejorar({mejor, items}, valor, item) when valor == mejor, do: {mejor, [item | items]}
  defp mejorar(actual, _valor, _item), do: actual

  @doc "Deja los empates en el orden en que fueron encontrados."
  def finalizar(%{por_movimientos: movimientos, por_energia: energia} = estadisticas) do
    %{estadisticas | por_movimientos: ordenar(movimientos), por_energia: ordenar(energia)}
  end

  defp ordenar(nil), do: nil
  defp ordenar({valor, items}), do: {valor, Enum.reverse(items)}
end
