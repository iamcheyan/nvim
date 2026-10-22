@echo off
call :process
goto :eof
:process
echo ready
goto :eof
:error_input
echo error
goto :eof
