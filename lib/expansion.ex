defmodule Expansion do
  @moduledoc """
  Stream infinito de relajación de energía mínima.

  Estado = mapa %{posicion => costo_minimo_conocido}.
    * Paso 0: solo S con costo 0.
    * Paso k+1: se conservan los costos ya hallados y cada casilla transitable se
      actualiza con min(costo del vecino + costo de entrada a esa casilla).
      Los costos mayores que B se descartan.

  """

  @doc "Stream INFINITO de estados (paso 0, paso 1, paso 2, ...)."
  def estados(%Edificio{inicio: inicio} = edificio, terrenos, bateria) do
    Stream.iterate(%{inicio => 0}, fn estado ->
      relajar(estado, edificio, terrenos, bateria)
    end)
  end

  @doc """
  Consume el stream hasta estabilizarse y escribe los pasos distintos en ruta.
  Devuelve {indice_de_estabilizacion, estado_final}.
  """
  def escribir(ruta, edificio, terrenos, bateria) do
    Util.escribir(ruta, fn dispositivo ->
      {indice, final} =
        edificio
        |> estados(terrenos, bateria)
        |> hasta_estabilizar(dispositivo)

      Util.linea(dispositivo, "Índice de estabilización: #{indice}")
      escribir_meta(dispositivo, edificio.meta, final)
      {indice, final}
    end)
  end

  defp hasta_estabilizar(estados, dispositivo) do
    estados
    |> Stream.with_index()
    |> Stream.chunk_every(2, 1, :discard)
    |> Enum.reduce_while(nil, fn [{actual, indice}, {siguiente, _}], _acumulado ->
      escribir_paso(dispositivo, indice, actual)

      if actual == siguiente do
        {:halt, {indice, actual}}
      else
        {:cont, nil}
      end
    end)
  end

  defp escribir_paso(dispositivo, indice, estado) do
    Util.linea(dispositivo, "Paso #{indice}")

    estado
    |> Enum.sort()
    |> Enum.each(fn {posicion, costo} ->
      Util.linea(dispositivo, "  #{Util.formatear_posicion(posicion)} = #{costo}")
    end)
  end

  defp escribir_meta(dispositivo, meta, final) do
    case Map.fetch(final, meta) do
      {:ok, costo} ->
        Util.linea(dispositivo, "Meta #{Util.formatear_posicion(meta)}: costo mínimo #{costo}")

      :error ->
        Util.linea(dispositivo, "Meta #{Util.formatear_posicion(meta)}: inalcanzable con la batería B")
    end
  end

  # Un paso de relajación: todos los candidatos se calculan con el estado ANTERIOR.
  defp relajar(estado, %Edificio{celdas: celdas} = edificio, terrenos, bateria) do
    Enum.reduce(celdas, estado, fn {posicion, simbolo}, nuevo ->
      mejorar(nuevo, estado, posicion, Map.fetch!(terrenos, simbolo), edificio, bateria)
    end)
  end

  defp mejorar(nuevo, _anterior, _posicion, %Terreno{transitable: false}, _edificio, _bateria) do
    nuevo
  end

  defp mejorar(nuevo, anterior, posicion, %Terreno{costo: costo}, _edificio, bateria) do
    costos_vecinos =
      posicion
      |> Edificio.vecinos()
      |> Enum.flat_map(fn vecino ->
        case Map.fetch(anterior, vecino) do
          {:ok, costo_vecino} -> [costo_vecino]
          :error -> []
        end
      end)

    case costos_vecinos do
      [] -> nuevo
      _ -> actualizar(nuevo, posicion, Enum.min(costos_vecinos) + costo, bateria)
    end
  end

  defp actualizar(nuevo, _posicion, candidato, bateria) when candidato > bateria, do: nuevo

  defp actualizar(nuevo, posicion, candidato, _bateria) do
    case Map.fetch(nuevo, posicion) do
      {:ok, actual} when actual <= candidato -> nuevo
      _ -> Map.put(nuevo, posicion, candidato)
    end
  end
end
