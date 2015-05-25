: TRUE   1 ;
: REPL   TRUE WHILE INTERPRET REPEAT ;

# -------------------------------------------------------------------------------
# The last function in main.fth is special. rforth runs this in its own loop
# and resets the forth stack if this ever aborts.
# -------------------------------------------------------------------------------
: RUN   REPL ;