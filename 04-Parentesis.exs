# Carga los módulos de lib/ (no hace falta compilar antes).
Code.require_file("cargar.exs", __DIR__)

defmodule ProblemaParentesis do
  @moduledoc """
  Problema 4 - Secuencias de paréntesis balanceados con profundidad máxima.

  Uso:
    elixir -pa ebin 04-Parentesis.exs [carpeta_entrada] [carpeta_salida]

  Por defecto: datos/parentesis  ->  salida/parentesis
  """

  def main do
    {entrada, salida} = System.argv() |> directorios()
    Util.ejecutar_seguro(fn -> ejecutar(entrada, salida) end)
  end

  defp directorios([]), do: {"datos/parentesis", "salida/parentesis"}
  defp directorios([entrada]), do: {entrada, "salida/parentesis"}
  defp directorios([entrada, salida | _resto]), do: {entrada, salida}

  defp ejecutar(entrada, salida) do
    generar_desde_parametros(Path.join(entrada, "parametros.csv"), salida)
    primera_solucion(salida)
    verificar_propuestas(Path.join(entrada, "propuestas.txt"), salida)
    crecimiento(salida)
  end

  # ------------------------------------------------------------------
  # parametros.csv -> parentesis_n<N>_p<P>.txt
  # ------------------------------------------------------------------
  defp generar_desde_parametros(ruta, salida) do
    case Util.faltantes([ruta]) do
      [] ->
        ruta
        |> Parentesis.leer_parametros()
        |> separar_parametros(salida)
        |> Enum.uniq()
        |> Enum.each(fn {n, p} ->
          total = Parentesis.escribir_soluciones(salida, n, p)
          Util.mostrar("n=#{n}, p=#{p}: #{total} solución(es)", :mensaje)
        end)

      [faltante] ->
        Util.mostrar("no existe el archivo requerido #{faltante}; se omiten los parámetros.", :aviso)
    end
  end

  # Devuelve los pares válidos y reporta cada registro incorrecto con su línea.
  defp separar_parametros(leidos, salida) do
    errores = for {linea, {:error, motivo}} <- leidos, do: "parametros.csv línea #{linea}: #{motivo}"

    Enum.each(errores, &Util.mostrar(&1, :error))
    escribir_errores(Path.join(salida, "errores_parametros.txt"), errores)

    for {_linea, {:ok, par}} <- leidos, do: par
  end

  defp escribir_errores(_ruta, []), do: :ok

  defp escribir_errores(ruta, errores) do
    Util.escribir(ruta, fn dispositivo ->
      Enum.each(errores, &Util.linea(dispositivo, &1))
    end)
  end

  # ------------------------------------------------------------------
  # Solo el primer elemento del Stream para n=18, p=18
  # ------------------------------------------------------------------
  defp primera_solucion(salida) do
    solucion = Parentesis.escribir_primera(salida, 18, 18)
    Util.mostrar("Primera solución n=18, p=18 (sin calcular las demás): #{solucion}", :mensaje)
  end

  # ------------------------------------------------------------------
  # propuestas.txt -> verificacion_parentesis.txt
  # ------------------------------------------------------------------
  defp verificar_propuestas(ruta, salida) do
    case Util.faltantes([ruta]) do
      [] ->
        leidas = ValidacionParentesis.leer_propuestas(ruta)

        Util.escribir(Path.join(salida, "verificacion_parentesis.txt"), fn dispositivo ->
          Enum.each(leidas, &escribir_propuesta(dispositivo, &1))
        end)

        Util.mostrar("Verificación de propuestas escrita en #{salida}/verificacion_parentesis.txt", :mensaje)

      [faltante] ->
        Util.mostrar("no existe el archivo requerido #{faltante}; se omite la verificación.", :aviso)
    end
  end

  defp escribir_propuesta(dispositivo, {linea, {:error, motivo}}) do
    Util.linea(dispositivo, "Línea #{linea}: registro incorrecto - #{motivo}")
  end

  defp escribir_propuesta(dispositivo, {linea, {:ok, {n, p, cadena}}}) do
    resultado = ValidacionParentesis.verificar(n, p, cadena)
    encabezado = "Línea #{linea} | n=#{n} p=#{p} | #{cadena} | "

    case resultado do
      %{valida: true, profundidad: profundidad} ->
        Util.linea(dispositivo, encabezado <> "VÁLIDA (profundidad alcanzada #{profundidad})")

      %{motivos: motivos, profundidad: profundidad} ->
        Util.linea(dispositivo, encabezado <> "INVÁLIDA (profundidad alcanzada #{profundidad})")
        Enum.each(motivos, fn motivo -> Util.linea(dispositivo, "    - #{motivo}") end)
    end
  end

  # ------------------------------------------------------------------
  # Stream infinito n = 1, 2, 3... -> secuencia_parentesis.csv
  # ------------------------------------------------------------------
  defp crecimiento(salida) do
    {n, total} = Parentesis.escribir_secuencia(salida)
    Util.mostrar("Secuencia: se detuvo en n=#{n} con total #{total} (n=#{n + 1} nunca se calculó).", :mensaje)
  end
end

ProblemaParentesis.main()
