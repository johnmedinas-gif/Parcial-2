# Carga los módulos de lib/ (no hace falta compilar antes).
Code.require_file("cargar.exs", __DIR__)

defmodule Rescate do
  @moduledoc """
  Problema 1 - Robot de rescate con energía limitada y mapa SVG.

  Uso:
    elixir -pa ebin 01-Rescate.exs [carpeta_entrada] [carpeta_salida]

  Por defecto: datos/rescate  ->  salida/rescate
  """

  def main do
    {entrada, salida} = System.argv() |> directorios()
    Util.ejecutar_seguro(fn -> ejecutar(entrada, salida) end)
  end

  defp directorios([]), do: {"datos/rescate", "salida/rescate"}
  defp directorios([entrada]), do: {entrada, "salida/rescate"}
  defp directorios([entrada, salida | _resto]), do: {entrada, salida}

  defp ejecutar(entrada, salida) do
    rutas = Enum.map(["edificio.txt", "terrenos.csv", "bateria.txt"], &Path.join(entrada, &1))

    case Util.faltantes(rutas) do
      [] -> procesar(entrada, salida)
      faltantes -> mostrar_faltantes(faltantes)
    end
  end

  defp mostrar_faltantes(faltantes) do
    Enum.each(faltantes, fn ruta -> Util.mostrar("no existe el archivo requerido #{ruta}", :aviso) end)
    Util.mostrar("No se puede continuar sin los archivos de entrada.", :error)
  end

  # ------------------------------------------------------------------
  # 1) Lectura + validación recursiva
  # ------------------------------------------------------------------
  defp procesar(entrada, salida) do
    terrenos_leidos = Entrada.leer_terrenos(Path.join(entrada, "terrenos.csv"))
    filas = Entrada.leer_edificio(Path.join(entrada, "edificio.txt"))
    bateria = Entrada.leer_bateria(Path.join(entrada, "bateria.txt"))

    errores = ValidacionEdificio.validar(terrenos_leidos, filas, bateria)
    escribir_validacion(Path.join(salida, "validacion_edificio.txt"), errores)

    case errores do
      [] ->
        Util.mostrar("Validación correcta: el edificio es consistente.", :mensaje)
        buscar(salida, terrenos_leidos, filas, bateria)

      _ ->
        Util.mostrar(
          "Se encontraron #{length(errores)} error(es); ver #{Path.join(salida, "validacion_edificio.txt")}. " <>
            "No se inicia la búsqueda.",
          :error
        )
    end
  end

  defp escribir_validacion(ruta, errores) do
    Util.escribir(ruta, fn dispositivo ->
      case errores do
        [] ->
          Util.linea(dispositivo, "Validación correcta: no se encontraron errores.")

        _ ->
          Util.linea(dispositivo, "Se encontraron #{length(errores)} error(es):")
          Enum.each(errores, fn error -> Util.linea(dispositivo, "- #{error}") end)
      end
    end)
  end

  # ------------------------------------------------------------------
  # 2) Stream infinito (filtro) -> 3) enumeración recursiva -> 4) salidas
  # ------------------------------------------------------------------
  defp buscar(salida, terrenos_leidos, filas, bateria) do
    terrenos = Entrada.terrenos_validos(terrenos_leidos)
    terrenos_por_simbolo = Map.new(terrenos, fn terreno -> {terreno.simbolo, terreno} end)
    edificio = Edificio.construir(filas)
    energia_maxima = Entrada.valor_bateria(bateria)

    {indice, final} =
      Expansion.escribir(
        Path.join(salida, "expansion_energia.txt"),
        edificio,
        terrenos_por_simbolo,
        energia_maxima
      )

    Util.mostrar("Relajación de energía: se estabilizó en el paso #{indice}.", :mensaje)

    alcanzable? = Map.has_key?(final, edificio.meta)

    estadisticas =
      enumerar(
        Path.join(salida, "recorridos_rescate.csv"),
        edificio,
        terrenos_por_simbolo,
        energia_maxima,
        alcanzable?
      )
      |> Busqueda.finalizar()

    lineas = lineas_resumen(estadisticas, energia_maxima)
    escribir_resumen(Path.join(salida, "resumen_rescate.txt"), lineas)
    Enum.each(lineas, &Util.mostrar(&1, :mensaje))

    SvgRescate.escribir(
      Path.join(salida, "ruta_optima.svg"),
      edificio,
      terrenos,
      mejor_ruta(estadisticas)
    )

    Util.mostrar("Archivos generados en #{salida}", :mensaje)
  end

  # La meta es inalcanzable según la relajación: no se enumera nada.
  defp enumerar(ruta_csv, _edificio, _terrenos, _bateria, false) do
    Util.escribir(ruta_csv, fn dispositivo ->
      Util.linea(dispositivo, "id;movimientos;energia;posiciones")
      Busqueda.estadisticas_iniciales()
    end)
  end

  # Cada recorrido se escribe al CSV apenas lo produce el Stream recursivo.
  defp enumerar(ruta_csv, edificio, terrenos, bateria, true) do
    Util.escribir(ruta_csv, fn dispositivo ->
      Util.linea(dispositivo, "id;movimientos;energia;posiciones")

      edificio
      |> Busqueda.recorridos(terrenos, bateria)
      |> Enum.reduce(Busqueda.estadisticas_iniciales(), fn recorrido, acumulado ->
        id = acumulado.total + 1
        Util.linea(dispositivo, Recorrido.a_fila_csv(recorrido, id))
        Busqueda.acumular(acumulado, id, recorrido)
      end)
    end)
  end

  defp mejor_ruta(%{por_energia: nil}), do: nil
  defp mejor_ruta(%{por_energia: {_energia, [{_id, recorrido} | _resto]}}), do: recorrido

  defp lineas_resumen(%{total: 0}, bateria) do
    [
      "Resumen del rescate (B = #{bateria})",
      "Total de recorridos válidos: 0",
      "No existe ningún recorrido válido: la meta no se alcanza sin superar B."
    ]
  end

  defp lineas_resumen(estadisticas, bateria) do
    {minimo_mov, por_mov} = estadisticas.por_movimientos
    {minimo_en, por_en} = estadisticas.por_energia

    [
      "Resumen del rescate (B = #{bateria})",
      "Total de recorridos válidos: #{estadisticas.total}",
      "Recorridos con menos movimientos (#{minimo_mov} movimientos): #{length(por_mov)}"
    ] ++
      detalle(por_mov) ++
      ["Recorridos con menor consumo (#{minimo_en} de energía): #{length(por_en)}"] ++
      detalle(por_en)
  end

  defp detalle(items) do
    Enum.map(items, fn {id, recorrido} ->
      "  - id #{id}: energía #{recorrido.energia}, #{Recorrido.movimientos(recorrido)} movimientos, " <>
        "#{Recorrido.posiciones_texto(recorrido)} (#{Enum.join(Recorrido.direcciones(recorrido), ", ")})"
    end)
  end

  defp escribir_resumen(ruta, lineas) do
    Util.escribir(ruta, fn dispositivo ->
      Enum.each(lineas, &Util.linea(dispositivo, &1))
    end)
  end
end

Rescate.main()
