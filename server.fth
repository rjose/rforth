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
# Subtracts 1 from top of stack
#
# Stack effect: (num -- num)
# -----------------------------------------------------------
: DEC
   1 -
;



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
# Updates all active forth machines
# -----------------------------------------------------------
: UPDATE-FORTH-MACHINES
     ." TODO: Implement UPDATE-FORTH-MACHINES" LOG
;


# EPOLL-WAIT ( -- count) Checks for epoll events and pushes count onto stack
# EPOLL-WEB-FD: (index -- fd)  Pushes web fd associated with index onto stack
# UPDATE-WEB-FD (fd -- ) If a new connection, creates a connection.
#                        Otherwise, reads/writes data and does something with it



: MAKE-HTTP-CONNECTIONS
   DROP
   ." TODO: Implement MAKE-HTTP-CONNECTIONS" LOG
;

# -----------------------------------------------------------
# If web fd is http-fd, establishes a connection; otherwise, reads/writes data
#
# (web-fd -- )
# -----------------------------------------------------------
: UPDATE-WEB-FD
   DUP http_fd @ === IF                                     # If web-fd == http_fd,
      MAKE-HTTP-CONNECTIONS                                 # then establish new HTTP connections to clients
   ELSE                                                     # Otherwise,
      DROP                                                  # handle existing connections
      ." TODO: Handle existing connections" LOG
   THEN
;

# -----------------------------------------------------------
# Decrements top of stack then pushes 1 if >= 0, 0 otherwise
# -----------------------------------------------------------
: DEC>=0?
   DEC DUP 0 >=
;


# -----------------------------------------------------------
# Updates any connections requiring attention
#
# This also includes the main http_fd for handling requests
# -----------------------------------------------------------
: UPDATE-CONNECTIONS
   epoll_fd @ EPOLL-WAIT                                    # Check for epoll events (gets a count of them)
   DEC>=0? WHILE                                            # Decrement loop index and repeat while >= 0:
      DUP                                                   # DUP loop index since EPOLL-WEB-FD consumes it
      EPOLL-WEB-FD                                          # Get fd at loop index,
      UPDATE-WEB-FD                                         #    and update it
   REPEAT
   DROP                                                     # Drop the loop index
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