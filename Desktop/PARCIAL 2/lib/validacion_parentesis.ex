defmodule ValidacionParentesis do
  @moduledoc """
  Verificación recursiva de cadenas propuestas (n;p;cadena).

  Comprueba: longitud 2n, solo ( y ), nunca cierra de más, termina con balance
  cero y no excede la profundidad p. Informa TODOS los motivos comprobables.
  """

  @doc """
  Verifica una cadena. Devuelve %{valida: boolean, motivos: [texto], profundidad: entero}.

  ## Ejemplo
  iex> ValidacionParentesis.verificar(3, 2, "(()())").valida
  true
  """
  def verificar(n, p, cadena) do
    final = recorrer(cadena, estado_inicial(p))
    motivos = motivos(n, p, cadena, final)

    %{valida: motivos == [], motivos: motivos, profundidad: final.profundidad}
  end

  defp estado_inicial(p) do
    %{
      p: p,
      indice: 0,
      balance: 0,
      profundidad: 0,
      prefijo: "",
      invalidos: [],
      cierre_excedido: nil,
      profundidad_excedida: nil
    }
  end

  # Recorrido recursivo por la cadena (caso base: cadena vacía).
  defp recorrer("", estado), do: estado

  defp recorrer(<<caracter::utf8, resto::binary>>, estado) do
    estado = %{estado | prefijo: estado.prefijo <> <<caracter::utf8>>}
    recorrer(resto, paso(caracter, estado))
  end

  defp paso(?(, estado) do
    balance = estado.balance + 1

    %{
      estado
      | indice: estado.indice + 1,
        balance: balance,
        profundidad: mayor(estado.profundidad, balance),
        profundidad_excedida: primero(estado.profundidad_excedida, balance > estado.p, estado)
    }
  end

  defp paso(?), estado) do
    balance = estado.balance - 1

    %{
      estado
      | indice: estado.indice + 1,
        balance: balance,
        cierre_excedido: primero(estado.cierre_excedido, balance < 0, estado)
    }
  end

  defp paso(otro, estado) do
    %{
      estado
      | indice: estado.indice + 1,
        invalidos: estado.invalidos ++ [{estado.indice, <<otro::utf8>>}]
    }
  end

  defp mayor(a, b) when a >= b, do: a
  defp mayor(_a, b), do: b

  # Guarda el primer prefijo problemático (no lo sobrescribe después).
  defp primero(nil, true, estado), do: {estado.indice, estado.prefijo}
  defp primero(actual, _ocurre, _estado), do: actual

  # ------------------------------------------------------------------
  # Motivos
  # ------------------------------------------------------------------

  defp motivos(n, p, cadena, final) do
    motivo_longitud(n, String.length(cadena)) ++
      motivos_invalidos(final.invalidos) ++
      motivo_cierre(final.cierre_excedido) ++
      motivo_balance(final.balance) ++
      motivo_profundidad(p, final)
  end

  defp motivo_longitud(n, longitud) when longitud == 2 * n, do: []

  defp motivo_longitud(n, longitud) do
    ["longitud #{longitud}, se esperaba 2n = #{2 * n}"]
  end

  defp motivos_invalidos([]), do: []

  defp motivos_invalidos([{indice, caracter} | resto]) do
    ["carácter no permitido '#{caracter}' en la posición #{indice} (solo ( y ))" | motivos_invalidos(resto)]
  end

  defp motivo_cierre(nil), do: []

  defp motivo_cierre({indice, prefijo}) do
    [
      "cierra más paréntesis de los abiertos: primer prefijo problemático \"#{prefijo}\" " <>
        "(posición #{indice})"
    ]
  end

  defp motivo_balance(0), do: []

  defp motivo_balance(balance) do
    ["no termina con balance cero (balance final #{balance})"]
  end

  defp motivo_profundidad(_p, %{profundidad_excedida: nil}), do: []

  defp motivo_profundidad(p, %{profundidad_excedida: {indice, prefijo}, profundidad: profundidad}) do
    [
      "excede la profundidad máxima p = #{p}: primer prefijo problemático \"#{prefijo}\" " <>
        "(posición #{indice}); profundidad máxima alcanzada #{profundidad}"
    ]
  end

  # ------------------------------------------------------------------
  # Lectura de propuestas.txt (File.stream!/1, formato n;p;cadena)
  # ------------------------------------------------------------------

  @doc """
  propuestas.txt -> lista de {linea, {:ok, {n, p, cadena}} | {:error, motivo}}.
  """
  def leer_propuestas(ruta) do
    ruta
    |> Util.lineas_utiles()
    |> Stream.map(fn {linea, texto} -> {linea, convertir(texto)} end)
    |> Enum.to_list()
  end

  defp convertir(texto) do
    case String.split(texto, ";") do
      [n_texto, p_texto, cadena] ->
        with {:ok, n} <- entero(n_texto, "n"),
             {:ok, p} <- entero(p_texto, "p") do
          {:ok, {n, p, String.trim(cadena)}}
        end

      campos ->
        {:error, "se esperaban 3 campos (n;p;cadena) y hay #{length(campos)}"}
    end
  end

  defp entero(texto, nombre) do
    case Util.parsear_entero(String.trim(texto)) do
      {:ok, valor} when valor >= 1 -> {:ok, valor}
      _ -> {:error, "#{nombre} debe ser un entero >= 1 y se recibió '#{String.trim(texto)}'"}
    end
  end
end
