# -----------------------------------------------------------
# All time units are in ms
# -----------------------------------------------------------
: ms NOP ;

VARIABLE http_port
VARIABLE http_fd
VARIABLE epoll_fd
VARIABLE loop_timestamp
1000 ms CONSTANT MIN-DELAY

# -----------------------------------------------------------
# Pushes a 1 onto the stack
# -----------------------------------------------------------
: TRUE   1 ;


# -----------------------------------------------------------
# Opens and monitors an http socket
#
# Stack args (port -- )
#   * port: Port number to listen for HTTP requests on
# -----------------------------------------------------------
: INIT-HTTP-SOCKET
     DUP http_port !  MAKE-HTTP-SOCKET
     DUP http_fd !    MONITOR-FD
     epoll_fd !
;

# -----------------------------------------------------------
# Waits some time if not long enough
#
# Stack args ( -- )
# -----------------------------------------------------------
: WAIT-IF-NEEDED
     TIMESTAMP  loop_timestamp @   -
     MIN-DELAY < IF
        MIN-DELAY WAIT
     THEN
;

# -----------------------------------------------------------
# Updates any sockets requiring attention
# -----------------------------------------------------------
: UPDATE-CONNECTIONS
     ." TODO: Implement UPDATE-CONNECTIONS" LOG
;


# -----------------------------------------------------------
# Updates all active forth machines
# -----------------------------------------------------------
: UPDATE-FORTH-MACHINES
     ." TODO: Implement UPDATE-FORTH-MACHINES" LOG
;



# -----------------------------------------------------------
# Runs main server loop
#
# (port -- )
#
# Stack args:
#   * Top:  Port number to listen for HTTP requests
# -----------------------------------------------------------
: RUN   INIT-HTTP-SOCKET
        TRUE WHILE
           TIMESTAMP loop_timestamp !
           UPDATE-CONNECTIONS
           UPDATE-FORTH-MACHINES
           WAIT-IF-NEEDED
        REPEAT
;



# Run server with port 9876
9876 RUN
