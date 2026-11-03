defmodule Util do
  @moduledoc """
  Funciones de apoyo reutilizadas por los dos problemas del Parcial 2.
  - Utilidades de texto: escapar XML, convertir enteros, formatear posiciones.
  """

  @doc """
  Muestra un mensaje en pantalla.

  ## Ejemplo
  iex> Util.mostrar("Hola", :mensaje)
  iex> Util.mostrar("Algo salió mal", :error)
  iex> Util.mostrar("No existe el archivo", :aviso)
  """
  def mostrar(mensaje, :mensaje), do: IO.puts(mensaje)
  def mostrar(mensaje, :error), do: IO.puts(:standard_error, mensaje)
  def mostrar(mensaje, :aviso), do: IO.puts(:standard_error, "AVISO: #{mensaje}")

  @doc "Ordena una colección (igual que Util2.ordenar/3)."
  def ordenar(coleccion, sentido \\ :asc, obtener_campo \\ & &1) do
    Enum.sort_by(coleccion, obtener_campo, sentido)
  end

  # ------------------------------------------------------------------
  # Lectura
  # ------------------------------------------------------------------

  @doc """
  Lee un archivo como Stream de líneas, de forma perezosa (File.stream!/1).

  Devuelve un Stream de tuplas `{numero_de_linea_fisica, texto_recortado}`.
  Ignora las líneas en blanco y las que empiezan con # (primer carácter no
  blanco). El número de línea es el físico, para poder informar errores.
  """
  def lineas_utiles(ruta) do
    ruta
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.map(fn {texto, numero} -> {numero, limpiar(texto, numero)} end)
    |> Stream.reject(fn {_numero, texto} -> ignorable?(texto) end)
  end

  # La primera línea puede traer BOM (archivos guardados desde Windows).
  defp limpiar(texto, 1), do: texto |> String.trim_leading("\uFEFF") |> String.trim()
  defp limpiar(texto, _numero), do: String.trim(texto)

  defp ignorable?(""), do: true
  defp ignorable?("#" <> _resto), do: true
  defp ignorable?(_texto), do: false

  @doc """
  Recibe una lista de rutas y devuelve (recursivamente) las que NO existen.
  Una lista vacía significa que todos los archivos están presentes.
  """
  def faltantes([]), do: []

  def faltantes([ruta | resto]) do
    if File.regular?(ruta) do
      faltantes(resto)
    else
      [ruta | faltantes(resto)]
    end
  end

  @doc "Ejecuta una función y convierte los errores de archivo en un mensaje claro."
  def ejecutar_seguro(funcion) do
    funcion.()
  rescue
    error in File.Error ->
      mostrar("Error de archivo: #{Exception.message(error)}", :error)
  end

  # ------------------------------------------------------------------
  # Escritura progresiva
  # ------------------------------------------------------------------

  @doc """
  Crea (o reemplaza) un archivo y le entrega a `escritor` el dispositivo abierto.
  El archivo se cierra solo al terminar. Devuelve lo que devuelva `escritor`.

  ## Ejemplo
  Util.escribir("salida/x.txt", fn dispositivo ->
    Util.linea(dispositivo, "primera línea")
    Util.linea(dispositivo, "segunda línea")
  end)
  """
  def escribir(ruta, escritor) do
    ruta |> Path.dirname() |> File.mkdir_p!()
    File.open!(ruta, [:write, :utf8], escritor)
  end

  @doc "Escribe una línea (con salto de línea) en un dispositivo abierto."
  def linea(dispositivo, texto), do: IO.write(dispositivo, [texto, "\n"])

  # ------------------------------------------------------------------
  # Texto
  # ------------------------------------------------------------------

  @doc "Convierte un texto en entero estricto: {:ok, n} o :error."
  def parsear_entero(texto) do
    case Integer.parse(texto) do
      {numero, ""} -> {:ok, numero}
      _ -> :error
    end
  end

  @doc "Escapa los caracteres especiales de XML (para textos dentro de un SVG)."
  def escapar_xml(texto) do
    texto
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  @doc "Formatea una posición {fila, columna} como texto: {1,2}."
  def formatear_posicion({fila, columna}), do: "{#{fila},#{columna}}"

  @doc """
  Une una lista de textos con un separador. Es recursiva a propósito: las
  validaciones previas no pueden usar Enum ni Stream, y necesitan unir textos.
  """
  def unir([], _separador), do: ""
  def unir([texto], _separador), do: texto
  def unir([texto | resto], separador), do: texto <> separador <> unir(resto, separador)
end
