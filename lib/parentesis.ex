defmodule Parentesis do
  @moduledoc """
  Problema 4 - Secuencias de paréntesis balanceados con profundidad máxima.

  El generador es recursivo y PEREZOSO: devuelve un Stream de cadenas. Nunca se
  crea una lista con todas las soluciones; cada cadena se produce solo cuando
  alguien la consume (Enum.take/2, Enum.reduce/3, ...).
  """

  @umbral 1000

  # ------------------------------------------------------------------
  # Generador recursivo y perezoso
  # ------------------------------------------------------------------

  @doc """
  Stream de todas las cadenas balanceadas con n pares y profundidad máxima p.
  El orden es el de intentar primero "(" y luego ")".

  ## Ejemplo
  iex> Parentesis.generar(3, 2) |> Enum.to_list()
  ["(()())", "(())()", "()(())", "()()()"]
  """
  def generar(n, p), do: construir("", n, n, 0, p)

  # Caso base: ya no quedan paréntesis por abrir ni por cerrar.
  defp construir(prefijo, 0, 0, _profundidad, _p), do: [prefijo]

  # Caso recursivo. Se usa flat_map sobre [:abrir, :cerrar] para DIFERIR el trabajo:
  # las llamadas recursivas solo se evalúan cuando el consumidor pide más elementos.
  # (Si se llamara a construir/5 directamente en los argumentos de Stream.concat/2,
  # se recorrería el árbol completo de decisiones al construir el stream.)
  defp construir(prefijo, por_abrir, por_cerrar, profundidad, p) do
    [:abrir, :cerrar]
    |> Stream.flat_map(fn paso ->
      ramificar(paso, prefijo, por_abrir, por_cerrar, profundidad, p)
    end)
  end

  # Abrir solo si quedan por abrir y no se excede la profundidad máxima.
  defp ramificar(:abrir, prefijo, por_abrir, por_cerrar, profundidad, p)
       when por_abrir > 0 and profundidad < p do
    construir(prefijo <> "(", por_abrir - 1, por_cerrar, profundidad + 1, p)
  end

  # Cerrar solo si hay algún paréntesis abierto pendiente (balance > 0).
  defp ramificar(:cerrar, prefijo, por_abrir, por_cerrar, profundidad, p)
       when profundidad > 0 and por_cerrar > 0 do
    construir(prefijo <> ")", por_abrir, por_cerrar - 1, profundidad - 1, p)
  end

  defp ramificar(_paso, _prefijo, _por_abrir, _por_cerrar, _profundidad, _p), do: []

  @doc "Cuenta las soluciones sin guardarlas en una lista."
  def contar(n, p), do: n |> generar(p) |> Enum.count()

  @doc "Solo la primera solución del Stream (no calcula las demás)."
  def primera(n, p), do: n |> generar(p) |> Enum.take(1)

  # ------------------------------------------------------------------
  # Archivos de salida (escritura progresiva)
  # ------------------------------------------------------------------

  @doc """
  Escribe parentesis_n<N>_p<P>.txt: una solución por línea y el total al final.
  Cada solución se escribe apenas se consume. Devuelve el total.
  """
  def escribir_soluciones(carpeta, n, p) do
    ruta = Path.join(carpeta, "parentesis_n#{n}_p#{p}.txt")

    Util.escribir(ruta, fn dispositivo ->
      total =
        n
        |> generar(p)
        |> Enum.reduce(0, fn solucion, acumulado ->
          Util.linea(dispositivo, solucion)
          acumulado + 1
        end)

      Util.linea(dispositivo, "Total: #{total}")
      total
    end)
  end

  @doc "Escribe primera_n<N>_p<P>.txt con solo el primer elemento del Stream."
  def escribir_primera(carpeta, n, p) do
    ruta = Path.join(carpeta, "primera_n#{n}_p#{p}.txt")

    Util.escribir(ruta, fn dispositivo ->
      [solucion] = primera(n, p)
      Util.linea(dispositivo, solucion)
      solucion
    end)
  end

  # ------------------------------------------------------------------
  # Stream infinito: crecimiento de soluciones
  # ------------------------------------------------------------------

  @doc """
  Stream INFINITO {n, total} con n = 1, 2, 3, ... y p = n.
  Es perezoso: el total de cada n solo se calcula cuando se consume ese elemento.
  """
  def secuencia do
    Stream.iterate(1, fn n -> n + 1 end)
    |> Stream.map(fn n -> {n, contar(n, n)} end)
  end

  @doc """
  Escribe secuencia_parentesis.csv y corta después del primer n con total >= 1000
  (incluyéndolo). Como el Stream es perezoso, n+1 nunca se calcula.
  Devuelve {n, total} del último valor escrito.
  """
  def escribir_secuencia(carpeta) do
    ruta = Path.join(carpeta, "secuencia_parentesis.csv")

    Util.escribir(ruta, fn dispositivo ->
      Util.linea(dispositivo, "n;total")

      Enum.reduce_while(secuencia(), nil, fn {n, total}, _acumulado ->
        Util.linea(dispositivo, "#{n};#{total}")

        if total >= @umbral do
          {:halt, {n, total}}
        else
          {:cont, nil}
        end
      end)
    end)
  end

  # ------------------------------------------------------------------
  # Lectura de parametros.csv
  # ------------------------------------------------------------------

  @doc """
  parametros.csv -> lista de {linea, {:ok, {n, p}} | {:error, motivo}}.
  Reglas: n >= 1 y 1 <= p <= n. Formato: n;profundidad_max
  """
  def leer_parametros(ruta) do
    ruta
    |> Util.lineas_utiles()
    |> Stream.map(fn {linea, texto} -> {linea, convertir_parametro(texto)} end)
    |> Enum.to_list()
  end

  defp convertir_parametro(texto) do
    case texto |> String.split(";") |> Enum.map(&String.trim/1) do
      [n_texto, p_texto] ->
        with {:ok, n} <- entero(n_texto, "n"),
             {:ok, p} <- entero(p_texto, "profundidad_max"),
             :ok <- rango(n, p) do
          {:ok, {n, p}}
        end

      campos ->
        {:error, "se esperaban 2 campos (n;profundidad_max) y hay #{length(campos)}"}
    end
  end

  defp entero(texto, nombre) do
    case Util.parsear_entero(texto) do
      {:ok, valor} -> {:ok, valor}
      :error -> {:error, "#{nombre} debe ser un entero y se recibió '#{texto}'"}
    end
  end

  defp rango(n, _p) when n < 1, do: {:error, "n debe ser >= 1 y se recibió #{n}"}

  defp rango(n, p) when p < 1 or p > n do
    {:error, "profundidad_max debe cumplir 1 <= p <= n (n=#{n}) y se recibió #{p}"}
  end

  defp rango(_n, _p), do: :ok
end
