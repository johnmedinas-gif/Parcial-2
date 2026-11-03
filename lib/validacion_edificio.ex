defmodule ValidacionEdificio do
  @moduledoc """
  Validación previa del Problema 1.


  Se verifica:
    * cuadrícula rectangular y no vacía
    * todos los símbolos definidos en terrenos.csv
    * exactamente un S y una M
    * borde completo formado por X
    * tabla de terrenos sin símbolos repetidos (y costos válidos)
    * B es un único entero positivo

  Todas las funciones devuelven listas de mensajes de error; lista vacía = todo bien.
  """

  @pared "X"
  @inicio "S"

  @doc "Devuelve la lista COMPLETA de errores (no se detiene en el primero)."
  def validar(terrenos_leidos, filas, bateria) do
    definidos = simbolos_definidos(terrenos_leidos)

    errores_terrenos(terrenos_leidos, []) ++
      errores_edificio(filas, definidos) ++
      errores_bateria(bateria)
  end

  # ------------------------------------------------------------------
  # terrenos.csv
  # ------------------------------------------------------------------

  defp simbolos_definidos([]), do: []

  defp simbolos_definidos([{_linea, {:ok, %Terreno{simbolo: simbolo}}} | resto]) do
    [simbolo | simbolos_definidos(resto)]
  end

  defp simbolos_definidos([_con_error | resto]), do: simbolos_definidos(resto)

  # vistos acumula {simbolo, linea} para detectar repetidos.
  defp errores_terrenos([], _vistos), do: []

  defp errores_terrenos([{linea, {:error, motivo}} | resto], vistos) do
    ["terrenos.csv línea #{linea}: #{motivo}" | errores_terrenos(resto, vistos)]
  end

  defp errores_terrenos([{linea, {:ok, terreno}} | resto], vistos) do
    errores_repetido(linea, terreno.simbolo, vistos) ++
      errores_costo(linea, terreno) ++
      errores_terrenos(resto, vistos ++ [{terreno.simbolo, linea}])
  end

  defp errores_repetido(linea, simbolo, vistos) do
    case linea_de(vistos, simbolo) do
      nil ->
        []

      anterior ->
        ["terrenos.csv línea #{linea}: el símbolo '#{simbolo}' está repetido (ya definido en la línea #{anterior})"]
    end
  end

  defp linea_de([], _simbolo), do: nil
  defp linea_de([{simbolo, linea} | _resto], simbolo), do: linea
  defp linea_de([_otro | resto], simbolo), do: linea_de(resto, simbolo)

  # Las casillas transitables distintas de S deben tener costo positivo.
  defp errores_costo(linea, %Terreno{transitable: true, costo: 0, simbolo: simbolo})
       when simbolo != @inicio do
    ["terrenos.csv línea #{linea}: el terreno '#{simbolo}' es transitable y su costo debe ser positivo"]
  end

  defp errores_costo(_linea, _terreno), do: []

  # ------------------------------------------------------------------
  # edificio.txt
  # ------------------------------------------------------------------

  defp errores_edificio([], _definidos) do
    ["edificio.txt: la cuadrícula está vacía"]
  end

  defp errores_edificio([{_linea, primera} | _resto] = filas, definidos) do
    errores_rectangular(filas, length(primera)) ++
      errores_simbolos(filas, definidos, 0) ++
      errores_unico(filas, @inicio) ++
      errores_unico(filas, "M") ++
      errores_borde(filas, 0, length(filas))
  end

  defp errores_rectangular([], _ancho), do: []

  defp errores_rectangular([{linea, simbolos} | resto], ancho) do
    propios =
      case length(simbolos) do
        ^ancho -> []
        otro -> ["edificio.txt línea #{linea}: la fila tiene #{otro} columnas y se esperaban #{ancho}"]
      end

    propios ++ errores_rectangular(resto, ancho)
  end

  defp errores_simbolos([], _definidos, _fila), do: []

  defp errores_simbolos([{linea, simbolos} | resto], definidos, fila) do
    errores_simbolos_fila(simbolos, linea, definidos, fila, 0) ++
      errores_simbolos(resto, definidos, fila + 1)
  end

  defp errores_simbolos_fila([], _linea, _definidos, _fila, _columna), do: []

  defp errores_simbolos_fila([simbolo | resto], linea, definidos, fila, columna) do
    propios =
      if definido?(simbolo, definidos) do
        []
      else
        [
          "edificio.txt línea #{linea}, coordenada #{Util.formatear_posicion({fila, columna})}: " <>
            "el símbolo '#{simbolo}' no está definido en terrenos.csv"
        ]
      end

    propios ++ errores_simbolos_fila(resto, linea, definidos, fila, columna + 1)
  end

  defp definido?(_simbolo, []), do: false
  defp definido?(simbolo, [simbolo | _resto]), do: true
  defp definido?(simbolo, [_otro | resto]), do: definido?(simbolo, resto)

  # Exactamente un S y exactamente una M.
  defp errores_unico(filas, simbolo) do
    case posiciones(filas, simbolo, 0) do
      [_unica] ->
        []

      [] ->
        ["edificio.txt: no hay ningún '#{simbolo}' y se esperaba exactamente uno"]

      varias ->
        lugares = varias |> formatear_posiciones() |> Util.unir(", ")

        [
          "edificio.txt: hay #{length(varias)} símbolos '#{simbolo}' (en #{lugares}) " <>
            "y se esperaba exactamente uno"
        ]
    end
  end

  defp posiciones([], _simbolo, _fila), do: []

  defp posiciones([{_linea, simbolos} | resto], simbolo, fila) do
    posiciones_fila(simbolos, simbolo, fila, 0) ++ posiciones(resto, simbolo, fila + 1)
  end

  defp posiciones_fila([], _simbolo, _fila, _columna), do: []

  defp posiciones_fila([simbolo | resto], simbolo, fila, columna) do
    [{fila, columna} | posiciones_fila(resto, simbolo, fila, columna + 1)]
  end

  defp posiciones_fila([_otro | resto], simbolo, fila, columna) do
    posiciones_fila(resto, simbolo, fila, columna + 1)
  end

  defp formatear_posiciones([]), do: []

  defp formatear_posiciones([posicion | resto]) do
    [Util.formatear_posicion(posicion) | formatear_posiciones(resto)]
  end

  # Borde completo de X: primera y última fila completas; en las demás,
  # primera y última columna de esa fila.
  defp errores_borde([], _fila, _total), do: []

  defp errores_borde([{linea, simbolos} | resto], fila, total) do
    fila_completa? = fila == 0 or fila == total - 1

    errores_borde_fila(simbolos, linea, fila, 0, length(simbolos) - 1, fila_completa?) ++
      errores_borde(resto, fila + 1, total)
  end

  defp errores_borde_fila([], _linea, _fila, _columna, _ultima, _completa?), do: []

  defp errores_borde_fila([simbolo | resto], linea, fila, columna, ultima, completa?) do
    en_borde? = completa? or columna == 0 or columna == ultima

    propios =
      if en_borde? and simbolo != @pared do
        [
          "edificio.txt línea #{linea}, coordenada #{Util.formatear_posicion({fila, columna})}: " <>
            "el borde debe ser '#{@pared}' y hay '#{simbolo}'"
        ]
      else
        []
      end

    propios ++ errores_borde_fila(resto, linea, fila, columna + 1, ultima, completa?)
  end

  # ------------------------------------------------------------------
  # bateria.txt
  # ------------------------------------------------------------------

  defp errores_bateria([]), do: ["bateria.txt: no se encontró ningún valor de B"]

  defp errores_bateria([{linea, texto} | resto]) do
    errores_valor_bateria(linea, texto) ++ errores_sobrantes(resto)
  end

  defp errores_valor_bateria(linea, texto) do
    case Integer.parse(texto) do
      {valor, ""} when valor > 0 -> []
      _ -> ["bateria.txt línea #{linea}: '#{texto}' no es un entero positivo"]
    end
  end

  defp errores_sobrantes([]), do: []

  defp errores_sobrantes([{linea, texto} | resto]) do
    [
      "bateria.txt línea #{linea}: dato adicional '#{texto}'; B debe ser un único entero positivo"
      | errores_sobrantes(resto)
    ]
  end
end
