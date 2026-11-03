defmodule Terreno do
  @moduledoc """
  Tipo de casilla del edificio, leído de terrenos.csv.

  Registro: simbolo,nombre,transitable,costo
  """
  defstruct simbolo: "", nombre: "", transitable: false, costo: 0

  def crear(simbolo, nombre, transitable, costo) do
    %Terreno{simbolo: simbolo, nombre: nombre, transitable: transitable, costo: costo}
  end

  @doc """
  Convierte una línea de terrenos.csv en un %Terreno{}.
  Devuelve {:ok, terreno} o {:error, motivo}.
  """
  def desde_linea(texto) do
    texto
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> convertir()
  end

  defp convertir(["", _nombre, _transitable, _costo]), do: {:error, "el símbolo está vacío"}

  defp convertir([simbolo, nombre, transitable, costo]) do
    with {:ok, transitable} <- convertir_transitable(transitable),
         {:ok, costo} <- convertir_costo(costo) do
      {:ok, crear(simbolo, nombre, transitable, costo)}
    end
  end

  defp convertir(campos) do
    {:error,
     "se esperaban 4 campos (simbolo,nombre,transitable,costo) y hay #{length(campos)}"}
  end

  defp convertir_transitable(texto) do
    case String.downcase(texto) do
      "si" -> {:ok, true}
      "no" -> {:ok, false}
      _ -> {:error, "transitable debe ser 'si' o 'no' y se recibió '#{texto}'"}
    end
  end

  defp convertir_costo(texto) do
    case Util.parsear_entero(texto) do
      {:ok, costo} when costo >= 0 -> {:ok, costo}
      _ -> {:error, "el costo debe ser un entero no negativo y se recibió '#{texto}'"}
    end
  end

  defimpl String.Chars, for: Terreno do
    def to_string(%Terreno{simbolo: simbolo, nombre: nombre, transitable: true, costo: costo}) do
      "#{simbolo} (#{nombre}, transitable, costo #{costo})"
    end

    def to_string(%Terreno{simbolo: simbolo, nombre: nombre}) do
      "#{simbolo} (#{nombre}, no transitable)"
    end
  end
end
