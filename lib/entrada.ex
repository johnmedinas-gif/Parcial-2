defmodule Entrada do
  @moduledoc """
  Lectura de los archivos de entrada del Problema 1 (robot de rescate).
  """

  @doc """
  terrenos.csv -> lista de {linea, {:ok, %Terreno{}} | {:error, motivo}}
  """
  def leer_terrenos(ruta) do
    ruta
    |> Util.lineas_utiles()
    |> Stream.map(fn {linea, texto} -> {linea, Terreno.desde_linea(texto)} end)
    |> Enum.to_list()
  end

  @doc """
  edificio.txt -> lista de {linea, [simbolos]}; los símbolos van separados por espacios.
  """
  def leer_edificio(ruta) do
    ruta
    |> Util.lineas_utiles()
    |> Stream.map(fn {linea, texto} -> {linea, String.split(texto)} end)
    |> Enum.to_list()
  end

  @doc """
  bateria.txt -> lista de {linea, texto} (sin convertir, para poder validar).
  """
  def leer_bateria(ruta) do
    ruta
    |> Util.lineas_utiles()
    |> Enum.to_list()
  end

  @doc "Extrae los %Terreno{} válidos de la lectura, en el orden del archivo."
  def terrenos_validos(leidos) do
    for {_linea, {:ok, terreno}} <- leidos, do: terreno
  end

  @doc "Valor entero de B (solo usar cuando la validación ya pasó)."
  def valor_bateria([{_linea, texto} | _resto]), do: String.to_integer(texto)
end
