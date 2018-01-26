Every users connected to the same server should be able to send
public messages (received by all other users), like you see in public chatroom, IRC, etc.

The server running at 52.91.109.76 at port 1234.  
The server is socket-based.  
It sends and receives newline terminated lines of JSON over TCP sockets like this:

Send a message:
{"msg":"hello","client_time":1446754551485}\n

Receive a message: 
{"msg":"hello","client_time":1446754551485,"server_time":1446754551495}\n

Receive an error:
{"error":"2 errors: client_time is missing, msg is missing"}\n

Request history:
{"command":"history","client_time":1446754551485,"since":1446754551495}\n

You can test it using telnet or netcat (nc).

For telnet:
>telnet  52.91.109.76 1234

Your iOS app should:

  * Send valid JSON messages to the server
  * Receive and parse valid JSON messages from the server
  * Display all sent and received messages (the msg value) in a text view (note that the server echoes any message sent by a client, so the app only needs to display received messages to display all messages sent or received)
  * When a message is sent from one device, that message should show up on all other devices immediately
  * If the app is offline when a message is sent, it should be queued persistently and delivered to the server the next time the app is online
  
  Extra points:
  
  * When the app comes back online, use the history command to retrieve any messages that it missed while offline
