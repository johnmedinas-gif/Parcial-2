defmodule Recorrido do
  @moduledoc """
  Un recorrido simple del robot: lista ordenada de posiciones {fila, columna}
  desde S hasta M y la energía total consumida.
  """
  defstruct posiciones: [], energia: 0

  def crear(posiciones, energia) do
    %Recorrido{posiciones: posiciones, energia: energia}
  end

  @doc "Cantidad de movimientos (una posición menos que casillas visitadas)."
  def movimientos(%Recorrido{posiciones: posiciones}), do: length(posiciones) - 1

  @doc "Posiciones como texto: {1,1}|{2,1}|... (| para no chocar con el ; del CSV)."
  def posiciones_texto(%Recorrido{posiciones: posiciones}) do
    posiciones
    |> Enum.map(&Util.formatear_posicion/1)
    |> Enum.join("|")
  end

  @doc """
  Secuencia de movimientos como nombres: ["abajo", "derecha", ...].
  Recursiva sobre pares de posiciones consecutivas.
  """
  def direcciones(%Recorrido{posiciones: posiciones}), do: direcciones(posiciones, [])

  defp direcciones([{f1, c1}, {f2, c2} | resto], acumulado) do
    nombre = Edificio.nombre_movimiento({f2 - f1, c2 - c1})
    direcciones([{f2, c2} | resto], [nombre | acumulado])
  end

  defp direcciones(_fin, acumulado), do: Enum.reverse(acumulado)

  @doc "Fila del CSV: id;movimientos;energia;posiciones"
  def a_fila_csv(%Recorrido{energia: energia} = recorrido, id) do
    "#{id};#{movimientos(recorrido)};#{energia};#{posiciones_texto(recorrido)}"
  end

  defimpl String.Chars, for: Recorrido do
    def to_string(%Recorrido{energia: energia} = recorrido) do
      "#{Recorrido.movimientos(recorrido)} movimientos, energía #{energia}: " <>
        Recorrido.posiciones_texto(recorrido)
    end
  end
end
