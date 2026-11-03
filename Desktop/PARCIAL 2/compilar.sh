#!/usr/bin/env bash
# Compila los módulos de lib/ en la carpeta ebin/ (como compilar.sh de clase con Util.ex)
mkdir -p ebin
rm -f ebin/*.beam
elixirc -o ebin lib/*.ex