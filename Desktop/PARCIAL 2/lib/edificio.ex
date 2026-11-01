defmodule Edificio do
  @moduledoc """
  Cuadrícula del edificio. celdas es un mapa %{{fila, columna} => simbolo}
  con origen en {0, 0}. Solo se construye después de validar las entradas.
  """
  defstruct celdas: %{}, filas: 0, columnas: 0, inicio: nil, meta: nil

  @simbolo_inicio "S"
  @simbolo_meta "M"

  # Orden fijo exigido por el enunciado: arriba, derecha, abajo, izquierda.
  @movimientos [arriba: {-1, 0}, derecha: {0, 1}, abajo: {1, 0}, izquierda: {0, -1}]

  def simbolo_inicio, do: @simbolo_inicio
  def simbolo_meta, do: @simbolo_meta

  @doc "Movimientos posibles como lista de {nombre, {delta_fila, delta_columna}}."
  def movimientos, do: @movimientos

  def nombre_movimiento(delta) do
    case Enum.find(@movimientos, fn {_nombre, d} -> d == delta end) do
      {nombre, _delta} -> Atom.to_string(nombre)
      nil -> "desconocido"
    end
  end

  @doc "Construye el edificio desde las filas leídas: [{linea, [simbolos]}]."
  def construir(filas) do
    celdas =
      filas
      |> Enum.with_index()
      |> Enum.flat_map(fn {{_linea, simbolos}, fila} ->
        simbolos
        |> Enum.with_index()
        |> Enum.map(fn {simbolo, columna} -> {{fila, columna}, simbolo} end)
      end)
      |> Map.new()

    {_linea, primera} = hd(filas)

    %Edificio{
      celdas: celdas,
      filas: length(filas),
      columnas: length(primera),
      inicio: buscar(celdas, @simbolo_inicio),
      meta: buscar(celdas, @simbolo_meta)
    }
  end

  defp buscar(celdas, simbolo) do
    case Enum.find(celdas, fn {_posicion, s} -> s == simbolo end) do
      {posicion, _simbolo} -> posicion
      nil -> nil
    end
  end

  @doc "Vecinos de una posición, en el orden arriba, derecha, abajo, izquierda."
  def vecinos({fila, columna}) do
    Enum.map(@movimientos, fn {_nombre, {df, dc}} -> {fila + df, columna + dc} end)
  end
end
