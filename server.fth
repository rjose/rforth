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
# Pushes a 0 onto the stack
# -----------------------------------------------------------
: FALSE   0 ;

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



# -----------------------------------------------------------
# CLAIM-MACHINE
#
# Stack args ( -- machine-index), on error ( -- -1)
# -----------------------------------------------------------
: CLAIM-MACHINE
   ." TODO: Implement CLAIM-MACHINE" LOG
   10  # Bogus index
;


# -----------------------------------------------------------
# CONCAT
#
# Concatenates two strings
#
# Stack effect ( s1 s2 -- s1s2)
# -----------------------------------------------------------

# -----------------------------------------------------------
# Constructs an HTTP response status line given a code
#
# Stack effect (status-code -- str)
#
# Result looks like: "HTTP/1.1 200 OK"
# -----------------------------------------------------------
: MAKE-STATUS-LINE
   TO-STR                                                   # Convert status code to a string
   ." HTTP/1.1 " SWAP CONCAT                                # Put HTTP/1.1 first and then concatenate
   ." \ TODO: Get message\r\n" CONCAT                       # Then add message and CRLF
;



# -----------------------------------------------------------
# CONTENT-LENGTH-HEADER
#
# Adds a content length header like "Content-Length: 123"
#
# Stack effect (message -- header)
# -----------------------------------------------------------
: CONTENT-LENGTH-HEADER
   STRLEN TO-STR                                            # Gets len(message)
   ." Content-Length: " SWAP                                # Adds "Content-Length: " as prefix
   CONCAT
;

# -----------------------------------------------------------
# Constructs an HTTP response
#
# Stack effect (fd body status-code -- )
# -----------------------------------------------------------
: RESPOND
   MAKE-STATUS-LINE                                         # Constructs status line with status-code
   OVER                                                     # (fd body accum body)
   CONTENT-LENGTH-HEADER CONCAT                             # (fd body accum)
   ." \r\n" CONCAT                                          # Adds CRLF
   ." \r\n" CONCAT                                          # Adds CRLF
   SWAP CONCAT                                              # Puts |body| at end of string
   WRITE                                                    # Writes to fd
;



# -----------------------------------------------------------
# DELEGATE-REQUEST
#
# Stack args ( fd machine-index -- )
#
# If the machine-index is -1, then we need to return a 500
# -----------------------------------------------------------
: DELEGATE-REQUEST
   DUP 0 < IF                                               # If machine couldn't be claimed,
      DROP                                                  # drop machine index, and
      ." All forth machines in use" 500 RESPOND             # return a 500 response to the fd
   ELSE
      DROP # TODO: Implement for reals
      ." Success!" 200 RESPOND
   THEN
;


# -----------------------------------------------------------
# Establishes a connection and claims forth machine to handle it
#
# Stack args (http_fd -- http_fd)
# -----------------------------------------------------------
: MAKE-SINGLE-CONNECTION
   DUP                                                      # dup http_fd so we have it for later
   ACCEPT-CONNECTION 0 >= IF                                # Try to accept a connection
      CLAIM-MACHINE DELEGATE-REQUEST                        # If OK, then spin up a machine to handle request
      TRUE                                                  # and indicate success
   ELSE
      DROP                                                  # Otherwise, drop bogus fd
      FALSE                                                 # And indicate failure
   THEN
;


# -----------------------------------------------------------
# Establishes all pending HTTP connections
#
# Stack args (http_fd -- )
# -----------------------------------------------------------
: MAKE-HTTP-CONNECTIONS
   MAKE-SINGLE-CONNECTION WHILE REPEAT                      # Make connections while pending requests
   DROP                                                     # Drop the http_fd
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