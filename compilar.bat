@echo off
if not exist ebin mkdir ebin
del /q ebin\*.beam 2>nul
elixirc -o ebin lib\*.ex
