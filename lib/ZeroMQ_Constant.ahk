class ZeroMQ_Constant
{
    ; 经过比较发现，所有常量名与函数名不存在冲突，故常量名无需区分大小写

    ; 11-102 共21个错误码来自 https://pyzmq.readthedocs.io/en/latest/api/zmq.html#constants
    static obj_abbr_error := {11             : "EAGAIN"
                            , 14             : "EFAULT"
                            , 22             : "EINVAL"
                            , 95             : "ENOTSUP"
                            , 93             : "EPROTONOSUPPORT"
                            , 105            : "ENOBUFS"
                            , 100            : "ENETDOWN"
                            , 98             : "EADDRINUSE"
                            , 99             : "EADDRNOTAVAIL"
                            , 111            : "ECONNREFUSED"
                            , 115            : "EINPROGRESS"
                            , 88             : "ENOTSOCK"
                            , 90             : "EMSGSIZE"
                            , 97             : "EAFNOSUPPORT"
                            , 101            : "ENETUNREACH"
                            , 103            : "ECONNABORTED"
                            , 104            : "ECONNRESET"
                            , 107            : "ENOTCONN"
                            , 110            : "ETIMEDOUT"
                            , 113            : "EHOSTUNREACH"
                            , 102            : "ENETRESET"
                            ; 156384712 及之后的错误码来自文件 zmq.h
                            ; 156384712 +1 到 +18 与上面的 ENOTSUP 到 ENETRESET 是重复的
                            , 156384712      : "ZMQ_HAUSNUMERO"
                            , 156384712 + 1  : "ENOTSUP"
                            , 156384712 + 2  : "EPROTONOSUPPORT"
                            , 156384712 + 3  : "ENOBUFS"
                            , 156384712 + 4  : "ENETDOWN"
                            , 156384712 + 5  : "EADDRINUSE"
                            , 156384712 + 6  : "EADDRNOTAVAIL"
                            , 156384712 + 7  : "ECONNREFUSED"
                            , 156384712 + 8  : "EINPROGRESS"
                            , 156384712 + 9  : "ENOTSOCK"
                            , 156384712 + 10 : "EMSGSIZE"
                            , 156384712 + 11 : "EAFNOSUPPORT"
                            , 156384712 + 12 : "ENETUNREACH"
                            , 156384712 + 13 : "ECONNABORTED"
                            , 156384712 + 14 : "ECONNRESET"
                            , 156384712 + 15 : "ENOTCONN"
                            , 156384712 + 16 : "ETIMEDOUT"
                            , 156384712 + 17 : "EHOSTUNREACH"
                            , 156384712 + 18 : "ENETRESET"
                            , 156384712 + 51 : "EFSM"
                            , 156384712 + 52 : "ENOCOMPATPROTO"
                            , 156384712 + 53 : "ETERM"
                            , 156384712 + 54 : "EMTHREAD"}

    ; Errno
    static EAGAIN          := 11            
    static EFAULT          := 14            
    static EINVAL          := 22            
    static ENOTSUP         := 95            
    static EPROTONOSUPPORT := 93            
    static ENOBUFS         := 105           
    static ENETDOWN        := 100           
    static EADDRINUSE      := 98            
    static EADDRNOTAVAIL   := 99            
    static ECONNREFUSED    := 111           
    static EINPROGRESS     := 115           
    static ENOTSOCK        := 88            
    static EMSGSIZE        := 90            
    static EAFNOSUPPORT    := 97            
    static ENETUNREACH     := 101           
    static ECONNABORTED    := 103           
    static ECONNRESET      := 104           
    static ENOTCONN        := 107           
    static ETIMEDOUT       := 110           
    static EHOSTUNREACH    := 113           
    static ENETRESET       := 102           
    static EFSM            := 156384712 + 51
    static ENOCOMPATPROTO  := 156384712 + 52
    static ETERM           := 156384712 + 53
    static EMTHREAD        := 156384712 + 54

    ; Context options
    static IO_THREADS                 := 1
    static MAX_SOCKETS                := 2
    static SOCKET_LIMIT               := 3
    static THREAD_PRIORITY            := 3
    static THREAD_SCHED_POLICY        := 4
    static MAX_MSGSZ                  := 5
    static MSG_T_SIZE                 := 6
    static THREAD_AFFINITY_CPU_ADD    := 7
    static THREAD_AFFINITY_CPU_REMOVE := 8
    static THREAD_NAME_PREFIX         := 9

    ; Default for new contexts
    static IO_THREADS_DFLT          := 1
    static MAX_SOCKETS_DFLT         := 1023
    static THREAD_PRIORITY_DFLT     := -1
    static THREAD_SCHED_POLICY_DFLT := -1

    ; Socket types
    static PAIR   := 0
    static PUB    := 1
    static SUB    := 2
    static REQ    := 3
    static REP    := 4
    static DEALER := 5
    static ROUTER := 6
    static PULL   := 7
    static PUSH   := 8
    static XPUB   := 9
    static XSUB   := 10
    static STREAM := 11

    ; Deprecated aliases
    static XREQ := 5 ; ZMQ_DEALER
    static XREP := 6 ; ZMQ_ROUTER

    ; Socket options
    static AFFINITY                          := 4
    static ROUTING_ID                        := 5
    static SUBSCRIBE                         := 6
    static UNSUBSCRIBE                       := 7
    static RATE                              := 8
    static RECOVERY_IVL                      := 9
    static SNDBUF                            := 11
    static RCVBUF                            := 12
    static RCVMORE                           := 13
    static FD                                := 14
    static EVENTS                            := 15
    static TYPE                              := 16
    static LINGER                            := 17
    static RECONNECT_IVL                     := 18
    static BACKLOG                           := 19
    static RECONNECT_IVL_MAX                 := 21
    static MAXMSGSIZE                        := 22
    static SNDHWM                            := 23
    static RCVHWM                            := 24
    static MULTICAST_HOPS                    := 25
    static RCVTIMEO                          := 27
    static SNDTIMEO                          := 28
    static LAST_ENDPOINT                     := 32
    static ROUTER_MANDATORY                  := 33
    static TCP_KEEPALIVE                     := 34
    static TCP_KEEPALIVE_CNT                 := 35
    static TCP_KEEPALIVE_IDLE                := 36
    static TCP_KEEPALIVE_INTVL               := 37
    static IMMEDIATE                         := 39
    static XPUB_VERBOSE                      := 40
    static ROUTER_RAW                        := 41
    static IPV6                              := 42
    static MECHANISM                         := 43
    static PLAIN_SERVER                      := 44
    static PLAIN_USERNAME                    := 45
    static PLAIN_PASSWORD                    := 46
    static CURVE_SERVER                      := 47
    static CURVE_PUBLICKEY                   := 48
    static CURVE_SECRETKEY                   := 49
    static CURVE_SERVERKEY                   := 50
    static PROBE_ROUTER                      := 51
    static REQ_CORRELATE                     := 52
    static REQ_RELAXED                       := 53
    static CONFLATE                          := 54
    static ZAP_DOMAIN                        := 55
    static ROUTER_HANDOVER                   := 56
    static TOS                               := 57
    static CONNECT_ROUTING_ID                := 61
    static GSSAPI_SERVER                     := 62
    static GSSAPI_PRINCIPAL                  := 63
    static GSSAPI_SERVICE_PRINCIPAL          := 64
    static GSSAPI_PLAINTEXT                  := 65
    static HANDSHAKE_IVL                     := 66
    static SOCKS_PROXY                       := 68
    static XPUB_NODROP                       := 69
    static BLOCKY                            := 70
    static XPUB_MANUAL                       := 71
    static XPUB_WELCOME_MSG                  := 72
    static STREAM_NOTIFY                     := 73
    static INVERT_MATCHING                   := 74
    static HEARTBEAT_IVL                     := 75
    static HEARTBEAT_TTL                     := 76
    static HEARTBEAT_TIMEOUT                 := 77
    static XPUB_VERBOSER                     := 78
    static CONNECT_TIMEOUT                   := 79
    static TCP_MAXRT                         := 80
    static THREAD_SAFE                       := 81
    static MULTICAST_MAXTPDU                 := 84
    static VMCI_BUFFER_SIZE                  := 85
    static VMCI_BUFFER_MIN_SIZE              := 86
    static VMCI_BUFFER_MAX_SIZE              := 87
    static VMCI_CONNECT_TIMEOUT              := 88
    static USE_FD                            := 89
    static GSSAPI_PRINCIPAL_NAMETYPE         := 90
    static GSSAPI_SERVICE_PRINCIPAL_NAMETYPE := 91
    static BINDTODEVICE                      := 92

    ; Message options
    static MORE   := 1
    static SHARED := 3

    ; Send/recv options
    static DONTWAIT := 1
    static SNDMORE  := 2

    ; Security mechanisms
    static NULL   := 0
    static PLAIN  := 1
    static CURVE  := 2
    static GSSAPI := 3

    ; RADIO-DISH protocol
    static GROUP_MAX_LENGTH := 255

    ; Deprecated options and aliases
    static IDENTITY                := 5  ; ZMQ_ROUTING_ID
    static CONNECT_RID             := 61 ; ZMQ_CONNECT_ROUTING_ID
    static TCP_ACCEPT_FILTER       := 38
    static IPC_FILTER_PID          := 58
    static IPC_FILTER_UID          := 59
    static IPC_FILTER_GID          := 60
    static IPV4ONLY                := 31
    static DELAY_ATTACH_ON_CONNECT := 39 ; ZMQ_IMMEDIATE
    static NOBLOCK                 := 1  ; ZMQ_DONTWAIT
    static FAIL_UNROUTABLE         := 33 ; ZMQ_ROUTER_MANDATORY
    static ROUTER_BEHAVIOR         := 33 ; ZMQ_ROUTER_MANDATORY

    ; Deprecated Message options
    static SRCFD := 2

    ; GSSAPI principal name types
    static GSSAPI_NT_HOSTBASED      := 0
    static GSSAPI_NT_USER_NAME      := 1
    static GSSAPI_NT_KRB5_PRINCIPAL := 2

    ; Socket transport events (TCP, IPC and TIPC only)
    static EVENT_CONNECTED       := 0x0001
    static EVENT_CONNECT_DELAYED := 0x0002
    static EVENT_CONNECT_RETRIED := 0x0004
    static EVENT_LISTENING       := 0x0008
    static EVENT_BIND_FAILED     := 0x0010
    static EVENT_ACCEPTED        := 0x0020
    static EVENT_ACCEPT_FAILED   := 0x0040
    static EVENT_CLOSED          := 0x0080
    static EVENT_CLOSE_FAILED    := 0x0100
    static EVENT_DISCONNECTED    := 0x0200
    static EVENT_MONITOR_STOPPED := 0x0400
    static EVENT_ALL             := 0xFFFF

    static EVENT_HANDSHAKE_FAILED_NO_DETAIL := 0x0800
    static EVENT_HANDSHAKE_SUCCEEDED        := 0x1000
    static EVENT_HANDSHAKE_FAILED_PROTOCOL  := 0x2000

    static EVENT_HANDSHAKE_FAILED_AUTH                       := 0x4000
    static PROTOCOL_ERROR_ZMTP_UNSPECIFIED                   := 0x10000000
    static PROTOCOL_ERROR_ZMTP_UNEXPECTED_COMMAND            := 0x10000001
    static PROTOCOL_ERROR_ZMTP_INVALID_SEQUENCE              := 0x10000002
    static PROTOCOL_ERROR_ZMTP_KEY_EXCHANGE                  := 0x10000003
    static PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_UNSPECIFIED := 0x10000011
    static PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_MESSAGE     := 0x10000012
    static PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_HELLO       := 0x10000013
    static PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_INITIATE    := 0x10000014
    static PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_ERROR       := 0x10000015
    static PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_READY       := 0x10000016
    static PROTOCOL_ERROR_ZMTP_MALFORMED_COMMAND_WELCOME     := 0x10000017
    static PROTOCOL_ERROR_ZMTP_INVALID_METADATA              := 0x10000018

    static PROTOCOL_ERROR_ZMTP_CRYPTOGRAPHIC      := 0x11000001
    static PROTOCOL_ERROR_ZMTP_MECHANISM_MISMATCH := 0x11000002
    static PROTOCOL_ERROR_ZAP_UNSPECIFIED         := 0x20000000
    static PROTOCOL_ERROR_ZAP_MALFORMED_REPLY     := 0x20000001
    static PROTOCOL_ERROR_ZAP_BAD_REQUEST_ID      := 0x20000002
    static PROTOCOL_ERROR_ZAP_BAD_VERSION         := 0x20000003
    static PROTOCOL_ERROR_ZAP_INVALID_STATUS_CODE := 0x20000004
    static PROTOCOL_ERROR_ZAP_INVALID_METADATA    := 0x20000005
    static PROTOCOL_ERROR_WS_UNSPECIFIED          := 0x30000000

    ; Deprecated I/O multiplexing. Prefer using zmq_poller API
    static POLLIN  := 1
    static POLLOUT := 2
    static POLLERR := 4
    static POLLPRI := 8

    static POLLITEMS_DFLT := 16

    ; Probe library capabilities
    static HAS_CAPABILITIES := 1

    ; Deprecated aliases
    static STREAMER  := 1
    static FORWARDER := 2
    static QUEUE     := 3

    ; DRAFT Socket types
    static SERVER  := 12
    static CLIENT  := 13
    static RADIO   := 14
    static DISH    := 15
    static GATHER  := 16
    static SCATTER := 17
    static DGRAM   := 18
    static PEER    := 19
    static CHANNEL := 20

    ; DRAFT Socket options
    static ZAP_ENFORCE_DOMAIN     := 93
    static LOOPBACK_FASTPATH      := 94
    static METADATA               := 95
    static MULTICAST_LOOP         := 96
    static ROUTER_NOTIFY          := 97
    static XPUB_MANUAL_LAST_VALUE := 98
    static SOCKS_USERNAME         := 99
    static SOCKS_PASSWORD         := 100
    static IN_BATCH_SIZE          := 101
    static OUT_BATCH_SIZE         := 102
    static WSS_KEY_PEM            := 103
    static WSS_CERT_PEM           := 104
    static WSS_TRUST_PEM          := 105
    static WSS_HOSTNAME           := 106
    static WSS_TRUST_SYSTEM       := 107
    static ONLY_FIRST_SUBSCRIBE   := 108
    static RECONNECT_STOP         := 109
    static HELLO_MSG              := 110
    static DISCONNECT_MSG         := 111
    static PRIORITY               := 112

    ; DRAFT ZMQ_RECONNECT_STOP options
    static RECONNECT_STOP_CONN_REFUSED     := 0x1
    static RECONNECT_STOP_HANDSHAKE_FAILED := 0x2
    static RECONNECT_STOP_AFTER_DISCONNECT := 0x3

    ; DRAFT Context options
    static ZERO_COPY_RECV := 10

    ; DRAFT Msg property names
    static MSG_PROPERTY_ROUTING_ID   := "Routing-Id"
    static MSG_PROPERTY_SOCKET_TYPE  := "Socket-Type"
    static MSG_PROPERTY_USER_ID      := "User-Id"
    static MSG_PROPERTY_PEER_ADDRESS := "Peer-Address"

    ; Router notify options
    static NOTIFY_CONNECT    := 1
    static NOTIFY_DISCONNECT := 2

    ; DRAFT Socket monitoring events
    static EVENT_PIPES_STATS := 0x10000

    static CURRENT_EVENT_VERSION       := 1
    static CURRENT_EVENT_VERSION_DRAFT := 2

    static EVENT_ALL_V1 := 0xFFFF           ; ZMQ_EVENT_ALL
    static EVENT_ALL_V2 := 0xFFFF | 0x10000 ; ZMQ_EVENT_ALL_V1 | ZMQ_EVENT_PIPES_STATS
}