defmodule SvgRescate do
  @moduledoc """
  Dibuja el edificio en SVG (casillas de 40 x 40) y remarca la ruta de menor energía.

  """

  @lado 40
  @ancho_minimo 360
  @alto_leyenda 22

  # Colores elegidos por nosotros; para símbolos nuevos se usa la paleta de respaldo.
  @colores %{
    "X" => "#37474f",
    "." => "#eceff1",
    "L" => "#a1887f",
    "S" => "#66bb6a",
    "M" => "#ffca28"
  }
  @paleta ["#90caf9", "#ce93d8", "#80cbc4", "#ffab91", "#c5e1a5", "#f48fb1"]
  @color_ruta "#d32f2f"

  @doc """
  Escribe el SVG. terrenos es la lista de %Terreno{} (orden del CSV) y
  mejor es el %Recorrido{} a resaltar o nil si no hay ruta.
  """
  def escribir(ruta, %Edificio{} = edificio, terrenos, mejor) do
    colores = asignar_colores(terrenos)
    terrenos_por_simbolo = Map.new(terrenos, fn terreno -> {terreno.simbolo, terreno} end)

    ancho_mapa = edificio.columnas * @lado
    alto_mapa = edificio.filas * @lado
    ancho = max(ancho_mapa, @ancho_minimo)
    alto = alto_mapa + 40 + length(terrenos) * @alto_leyenda

    Util.escribir(ruta, fn d ->
      Util.linea(d, ~s(<?xml version="1.0" encoding="UTF-8"?>))

      Util.linea(
        d,
        ~s(<svg xmlns="http://www.w3.org/2000/svg" width="#{ancho}" height="#{alto}" viewBox="0 0 #{ancho} #{alto}">)
      )

      Util.linea(d, ~s(<title>Ruta de menor energía del robot de rescate</title>))
      Util.linea(d, ~s(<rect width="100%" height="100%" fill="#ffffff"/>))

      dibujar_celdas(d, edificio, colores, terrenos_por_simbolo)
      dibujar_ruta(d, mejor)
      dibujar_estado(d, mejor, alto_mapa)
      dibujar_leyenda(d, terrenos, colores, alto_mapa + 40)

      Util.linea(d, "</svg>")
    end)
  end

  defp asignar_colores(terrenos) do
    terrenos
    |> Enum.with_index()
    |> Map.new(fn {terreno, indice} ->
      respaldo = Enum.at(@paleta, rem(indice, length(@paleta)))
      {terreno.simbolo, Map.get(@colores, terreno.simbolo, respaldo)}
    end)
  end

  defp dibujar_celdas(d, edificio, colores, terrenos) do
    Enum.each(0..(edificio.filas - 1), fn fila ->
      Enum.each(0..(edificio.columnas - 1), fn columna ->
        simbolo = Map.fetch!(edificio.celdas, {fila, columna})
        dibujar_celda(d, {fila, columna}, simbolo, colores, Map.get(terrenos, simbolo))
      end)
    end)
  end

  defp dibujar_celda(d, {fila, columna}, simbolo, colores, terreno) do
    x = columna * @lado
    y = fila * @lado
    color = Map.get(colores, simbolo, "#ffffff")
    texto_color = if terreno && not terreno.transitable, do: "#ffffff", else: "#263238"

    Util.linea(
      d,
      ~s(<rect x="#{x}" y="#{y}" width="#{@lado}" height="#{@lado}" fill="#{color}" stroke="#90a4ae" stroke-width="0.5">) <>
        ~s(<title>#{Util.escapar_xml(descripcion(Util.formatear_posicion({fila, columna}), terreno))}</title></rect>)
    )

    Util.linea(
      d,
      ~s(<text x="#{x + div(@lado, 2)}" y="#{y + div(@lado, 2) + 5}" text-anchor="middle" ) <>
        ~s(font-family="monospace" font-size="16" fill="#{texto_color}">#{Util.escapar_xml(simbolo)}</text>)
    )
  end

  defp descripcion(posicion, nil), do: posicion
  defp descripcion(posicion, terreno), do: "#{posicion} #{terreno}"

  # Sin ruta no se dibuja nada encima del mapa.
  defp dibujar_ruta(_d, nil), do: :ok

  defp dibujar_ruta(d, %Recorrido{posiciones: posiciones}) do
    posiciones
    |> Stream.chunk_every(2, 1, :discard)
    |> Enum.each(fn [{f1, c1}, {f2, c2}] ->
      Util.linea(
        d,
        ~s(<line x1="#{centro(c1)}" y1="#{centro(f1)}" x2="#{centro(c2)}" y2="#{centro(f2)}" ) <>
          ~s(stroke="#{@color_ruta}" stroke-width="4" stroke-linecap="round"/>)
      )
    end)

    Enum.each(posiciones, fn {fila, columna} ->
      Util.linea(
        d,
        ~s(<circle cx="#{centro(columna)}" cy="#{centro(fila)}" r="4" fill="#{@color_ruta}"/>)
      )
    end)
  end

  defp centro(indice), do: indice * @lado + div(@lado, 2)

  defp dibujar_estado(d, nil, alto_mapa) do
    texto_estado(d, alto_mapa, "sin recorrido")
  end

  defp dibujar_estado(d, %Recorrido{energia: energia} = recorrido, alto_mapa) do
    texto_estado(
      d,
      alto_mapa,
      "Ruta de menor energía: #{energia} de energía, #{Recorrido.movimientos(recorrido)} movimientos"
    )
  end

  defp texto_estado(d, alto_mapa, texto) do
    Util.linea(
      d,
      ~s(<text x="8" y="#{alto_mapa + 24}" font-family="sans-serif" font-size="14" fill="#{@color_ruta}">) <>
        ~s(#{Util.escapar_xml(texto)}</text>)
    )
  end

  defp dibujar_leyenda(d, terrenos, colores, y_inicial) do
    terrenos
    |> Enum.with_index()
    |> Enum.each(fn {terreno, indice} ->
      y = y_inicial + indice * @alto_leyenda
      color = Map.get(colores, terreno.simbolo)

      Util.linea(
        d,
        ~s(<rect x="8" y="#{y}" width="14" height="14" fill="#{color}" stroke="#90a4ae" stroke-width="0.5"/>)
      )

      Util.linea(
        d,
        ~s(<text x="30" y="#{y + 12}" font-family="sans-serif" font-size="12" fill="#263238">) <>
          ~s(#{Util.escapar_xml(to_string(terreno))}</text>)
      )
    end)
  end
end
