class ZeroMQ extends ZeroMQ_Constant
{
    ; 理论上来说，将 dll 载入内存并使用函数的地址来 dllcall 是最快的
    ; 可实际测试下来，这两步操作几乎没有提速
    __New(dll_path := "")
    {
        local
        SplitPath,A_LineFile,,dir
        path := ""
        lib_path := dir
        if(A_IsCompiled)
        {
            path := A_PtrSize == 4 ? A_ScriptDir . "\lib\dll_32\" : A_ScriptDir . "\lib\dll_64\"
            lib_path := A_ScriptDir . "\lib"
        }
        else
        {
            path := (A_PtrSize == 4) ? dir . "\dll_32\" : dir . "\dll_64\"
        }

        dllcall("SetDllDirectory", "Str", path)
        zmqdll := "libzmq-v141-mt-4_3_4.dll"
        if (!this.hModule_libzmq := DllCall("LoadLibrary", "Str", zmqdll, "Ptr"))
            throw Exception("libzmq.dll loading failed.", -1)
        
        ; api 的内容来自于此 http://api.zeromq.org/
        ; 注释掉的部分并不是函数，因为取到的地址为0
        api := [ "zmq_atomic_counter_dec"
               , "zmq_atomic_counter_destroy"
               , "zmq_atomic_counter_inc"
               , "zmq_atomic_counter_new"
               , "zmq_atomic_counter_set"
               , "zmq_atomic_counter_value"
               , "zmq_bind"                   ; *
               , "zmq_close"                  ; *
               , "zmq_connect"                ; *
               , "zmq_ctx_destroy"            ; deprecate by zmq_ctx_term
               , "zmq_ctx_get"
               , "zmq_ctx_new"                ; *
               , "zmq_ctx_set"
               , "zmq_ctx_shutdown"           ; *
               , "zmq_ctx_term"               ; *
               , "zmq_curve_keypair"
               , "zmq_curve_public"
               ; , "zmq_curve"
               , "zmq_disconnect"             ; *
               , "zmq_errno"                  ; *
               , "zmq_getsockopt"
               ; , "zmq_gssapi"
               , "zmq_has"
               , "zmq_init"                   ; deprecate by zmq_ctx_new
               ; , "zmq_inproc"
               ; , "zmq_ipc"
               , "zmq_msg_close"              ; *
               , "zmq_msg_copy"
               , "zmq_msg_data"               ; *
               , "zmq_msg_gets"
               , "zmq_msg_get"
               , "zmq_msg_init_data"
               , "zmq_msg_init_size"
               , "zmq_msg_init"               ; *
               , "zmq_msg_more"               ; *
               , "zmq_msg_move"
               , "zmq_msg_recv"               ; *
               , "zmq_msg_routing_id"
               , "zmq_msg_send"
               , "zmq_msg_set_routing_id"
               , "zmq_msg_set"
               , "zmq_msg_size"
               ; , "zmq_null"
               ; , "zmq_pgm"
               ; , "zmq_plain"
               ; , "zmq_poller"
               , "zmq_poll"                   ; *
               , "zmq_proxy_steerable"
               , "zmq_proxy"                  ; *
               , "zmq_recvmsg"                ; deprecate by zmq_msg_recv
               , "zmq_recv"                   ; *
               , "zmq_send_const"
               , "zmq_sendmsg"                ; deprecate by zmq_msg_send
               , "zmq_send"                   ; *
               , "zmq_setsockopt"             ; *
               , "zmq_socket_monitor"
               , "zmq_socket"                 ; *
               , "zmq_strerror"               ; *
               ; , "zmq_tcp"
               , "zmq_term"                   ; deprecate by zmq_ctx_term
               ; , "zmq_timers"
               ; , "zmq_tipc"
               ; , "zmq_udp"
               , "zmq_unbind"                 ; *
               , "zmq_version"                ; *
               ; , "zmq_vmci"
               , "zmq_z85_decode"
               , "zmq_z85_encode"]
        
        ; 查找 libzmq.dll 中函数的地址以供 dllcall 使用
        for k, v in api
            this[v] := DllCall("GetProcAddress", "Ptr", this.hModule_libzmq, "AStr", v, "Ptr")
        
        ; 将 ntdll.dll 载入内存
        if (!this.hModule_ntdll := DllCall("LoadLibrary", "Str", "ntdll.dll", "Ptr"))
            throw Exception("ntdll.dll loading failed.", -1)
        
        ; 查找 memcpy 函数地址
        this.zmq_memcpy := DllCall("GetProcAddress", "Ptr", this.hModule_ntdll, "AStr", "memcpy", "Ptr")
        
        this.is_from := "zmq"
    }
    
    __Delete()
    {
        ; var socket being released
        if (this.is_from = "socket")
        {
            created_sockets := ObjGetBase(this)["created_contexts", this.ptr_context]
            if (created_sockets.HasKey(this.ptr_socket))
            {
                this.close(this.ptr_socket)
                created_sockets.Delete(this.ptr_socket)
            }
        }
        
        ; var context being released
        if (this.is_from = "context")
        {
            created_contexts := ObjGetBase(this)["created_contexts"]
            if (created_contexts.HasKey(this.ptr_context))
            {
                ; Before destroying the context, all sockets MUST be closed first.
                ; if not, it will block here
                created_sockets := ObjGetBase(this)["created_contexts", this.ptr_context]
                for socket, v in created_sockets.Clone()
                {
                    this.close(socket)
                    created_sockets.Delete(socket)
                }
                
                this.term(this.ptr_context)
                created_contexts.Delete(this.ptr_context)
            }
        }
        
        ; var zmq being released
        if (this.is_from = "zmq")
        {
            ; destroy all contexts and sockets first
            created_contexts := ObjGetBase(this)["created_contexts"]
            for context, v in created_contexts.Clone()
            {
                created_sockets := ObjGetBase(this)["created_contexts", context]
                for socket, v in created_sockets.Clone()
                {
                    this.close(socket)
                    created_sockets.Delete(socket)
                }
                
                this.term(context)
                created_contexts.Delete(context)
            }
            
            DllCall("FreeLibrary", "Ptr", this.hModule_libzmq)
            DllCall("FreeLibrary", "Ptr", this.hModule_ntdll)
        }
        
        ; var poller being released
        if (this.is_from = "poller")
            return ; nothing to do
    }
    
    context()
    {
        ret := DllCall(this.zmq_ctx_new, "Ptr")
        if (ret = "")
            throw Exception(this.error(), -1, this.errno())
        else
        {
            this_clone := this.Clone() ; 避免在 zmq 对象中记录 ptr_context
            this_clone.ptr_context := ret
            this_clone.is_from := "context"
            return this_clone
        }
    }
    
    term(context)
    {
        if (DllCall(this.zmq_ctx_term, "Ptr", context, "Int") = -1)
            throw Exception(this.error(), -1, this.errno())
    }
    
    shutdown(context)
    {
        if (DllCall(this.zmq_ctx_shutdown, "Ptr", context, "Int") = -1)
            throw Exception(this.error(), -1, this.errno())
    }
    
    socket(type)
    {
        ret := DllCall(this.zmq_socket, "Ptr", this.ptr_context, "Int", type, "Ptr")
        if (ret = "")
            throw Exception(this.error(), -1, this.errno())
        else
        {
            this_clone := this.Clone() ; 避免在 context 对象中记录 ptr_socket
            this_clone.ptr_socket := ret
            this_clone.is_from := "socket"
            ObjGetBase(this)["created_contexts", this_clone.ptr_context, this_clone.ptr_socket] := true
            return this_clone
        }
    }
    
    bind(endpoint)
    {
        if (DllCall(this.zmq_bind, "Ptr", this.ptr_socket, "AStr", endpoint, "Int") = -1)
            throw Exception(this.error(), -1, this.errno())
    }
    
    unbind(endpoint)
    {
        if (DllCall(this.zmq_unbind, "Ptr", this.ptr_socket, "AStr", endpoint, "Int") = -1)
            throw Exception(this.error(), -1, this.errno())
    }
    
    connect(endpoint)
    {
        if (DllCall(this.zmq_connect, "Ptr", this.ptr_socket, "AStr", endpoint, "Int") = -1)
            throw Exception(this.error(), -1, this.errno())
    }
    
    disconnect(endpoint)
    {
        if (DllCall(this.zmq_disconnect, "Ptr", this.ptr_socket, "AStr", endpoint, "Int") = -1)
            throw Exception(this.error(), -1, this.errno())
    }
    
    close(socket)
    {
        if (DllCall(this.zmq_close, "Ptr", socket, "Int") = -1)
            throw Exception(this.error(), -1, this.errno())
    }
    
    setsockopt(option_name, ByRef option_value, option_len := "")
    {
        if (option_len = "")
        {
            option_value_bak := option_value
            
            ; int64_t
            if (   option_name = this.MAXMSGSIZE)
                VarSetCapacity(option_value, option_len := 8, 0)
                , NumPut(option_value_bak, option_value, "Int64")
            ; uint64_t
            if (   option_name = this.AFFINITY
                or option_name = this.VMCI_BUFFER_SIZE
                or option_name = this.VMCI_BUFFER_MIN_SIZE
                or option_name = this.VMCI_BUFFER_MAX_SIZE)
                VarSetCapacity(option_value, option_len := 8, 0)
                , NumPut(option_value_bak, option_value, "UInt64")
            ; int
            if (   option_name = this.BACKLOG
                or option_name = this.CONFLATE
                or option_name = this.CONNECT_TIMEOUT
                or option_name = this.CURVE_SERVER
                or option_name = this.GSSAPI_PLAINTEXT
                or option_name = this.GSSAPI_SERVER
                or option_name = this.GSSAPI_SERVICE_PRINCIPAL_NAMETYPE
                or option_name = this.GSSAPI_PRINCIPAL_NAMETYPE
                or option_name = this.HANDSHAKE_IVL
                or option_name = this.HEARTBEAT_IVL
                or option_name = this.HEARTBEAT_TIMEOUT
                or option_name = this.HEARTBEAT_TTL
                or option_name = this.IMMEDIATE
                or option_name = this.INVERT_MATCHING
                or option_name = this.IPV6
                or option_name = this.LINGER
                or option_name = this.MULTICAST_HOPS
                or option_name = this.MULTICAST_MAXTPDU
                or option_name = this.PLAIN_SERVER
                or option_name = this.USE_FD
                or option_name = this.PROBE_ROUTER
                or option_name = this.RATE
                or option_name = this.RCVBUF
                or option_name = this.RCVHWM
                or option_name = this.RCVTIMEO
                or option_name = this.RECONNECT_IVL
                or option_name = this.RECONNECT_IVL_MAX
                or option_name = this.RECOVERY_IVL
                or option_name = this.REQ_CORRELATE
                or option_name = this.REQ_RELAXED
                or option_name = this.ROUTER_HANDOVER
                or option_name = this.ROUTER_MANDATORY
                or option_name = this.ROUTER_RAW
                or option_name = this.SNDBUF
                or option_name = this.SNDHWM
                or option_name = this.SNDTIMEO
                or option_name = this.STREAM_NOTIFY
                or option_name = this.TCP_KEEPALIVE
                or option_name = this.TCP_KEEPALIVE_CNT
                or option_name = this.TCP_KEEPALIVE_IDLE
                or option_name = this.TCP_KEEPALIVE_INTVL
                or option_name = this.TCP_MAXRT
                or option_name = this.TOS
                or option_name = this.XPUB_VERBOSE
                or option_name = this.XPUB_VERBOSER
                or option_name = this.XPUB_MANUAL
                or option_name = this.XPUB_NODROP
                or option_name = this.ZAP_ENFORCE_DOMAIN
                or option_name = this.IPV4ONLY
                or option_name = this.VMCI_CONNECT_TIMEOUT
                or option_name = this.MULTICAST_LOOP
                or option_name = this.ROUTER_NOTIFY)
                VarSetCapacity(option_value, option_len := 4, 0)
                , NumPut(option_value_bak, option_value, "Int")
            /*
            ; character string
            if (   option_name = this.BINDTODEVICE
                or option_name = this.GSSAPI_PRINCIPAL
                or option_name = this.GSSAPI_SERVICE_PRINCIPAL
                or option_name = this.METADATA
                or option_name = this.PLAIN_PASSWORD
                or option_name = this.PLAIN_USERNAME
                or option_name = this.SOCKS_PROXY
                or option_name = this.ZAP_DOMAIN)
                option_len := VarSetCapacity(option_value, -1)
            ; binary data
            if (   option_name = this.CONNECT_ROUTING_ID
                or option_name = this.CURVE_PUBLICKEY
                or option_name = this.CURVE_SECRETKEY
                or option_name = this.CURVE_SERVERKEY
                or option_name = this.ROUTING_ID
                or option_name = this.SUBSCRIBE
                or option_name = this.UNSUBSCRIBE
                or option_name = this.XPUB_WELCOME_MSG)
                option_len := VarSetCapacity(option_value)
            */
        }
        
        if (DllCall(this.zmq_setsockopt
                    , "Ptr", this.ptr_socket
                    , "Int", option_name
                    , "Ptr", &option_value
                    , "UPtr", option_len
                    , "Int") = -1)
            throw Exception(this.error(), -1, this.errno())
    }
    
    setsockopt_string(option_name, string, encoding := "UTF-16")
    {
        if (encoding="UTF-16" or encoding="CP1200")
        {
            buf := string
            buf_size := VarSetCapacity(string, -1)
        }
        else
        {
            buf_size := StrPut(string, encoding) - 1
            VarSetCapacity(buf, buf_size, 0)
            StrPut(string, &buf, buf_size, encoding)
        }
        
        ; this.setsockopt() 不会被频繁调用，所以用略慢但更优雅的写法
        this.setsockopt(option_name, buf, buf_size)
    }
    
    parse_buffer_array(ByRef out, buffer_array, index := "")
    {
        if (!IsObject(buffer_array))
            throw Exception("param 2 is not a buffer array.", -1)
        
        if (index)
        {
            if (!buffer_array[index].is_buffer)
                throw Exception("param 2 index " index " is not a buffer object.", -1)
            
            frame := buffer_array[index]
            
            VarSetCapacity(out, frame.size, 0)
            DllCall(this.zmq_memcpy
                    , "Ptr", &out
                    , "Ptr", frame.ptr
                    , "UPtr", frame.size
                    , "Ptr")
            
            return frame.size
        }
        else
        {
            total_size := 0
            for k, frame in buffer_array
            {
                if (!frame.is_buffer)
                    throw Exception("param 2 index " k " is not a buffer object.", -1)
                
                total_size += frame.size
            }
            
            VarSetCapacity(out, total_size, 0)
            
            offset := 0
            for k, frame in buffer_array
            {
                DllCall(this.zmq_memcpy
                        , "Ptr", &out + offset
                        , "Ptr", frame.ptr
                        , "UPtr", frame.size
                        , "Ptr")
                
                offset += frame.size
            }
            
            return total_size
        }
    }
    
    ; return the full size of frame
    recv(address, recv_size, flags := 0)
    {
        full_size := DllCall(this.zmq_recv
                            , "Ptr", this.ptr_socket
                            , "Ptr", address
                            , "UPtr", recv_size
                            , "Int", flags
                            , "Int")
        if (full_size = -1)
            throw Exception(this.error(), -1, this.errno())
        
        return full_size
    }
    
    ; return the buffer array, MUST use parse_buffer_array() to get the value
    recv_binary(flags := 0)
    {
        data := []
        ; recv all parts infos to data[]
        loop
        {
            ; struct zmq_msg_t always 64 bytes
            VarSetCapacity(zmq_msg_t%A_Index%, 64, 0)
            
            ; zmq_msg_init() always return 0
            DllCall(this.zmq_msg_init, "Ptr", &zmq_msg_t%A_Index%, "Int")
            
            full_size := DllCall(this.zmq_msg_recv
                                , "Ptr", &zmq_msg_t%A_Index%
                                , "Ptr", this.ptr_socket
                                , "Int", flags
                                , "Int")
            if (full_size = -1)
            {
                errnum := this.errno()
                
                ; close current zmq_msg_t
                if (DllCall(this.zmq_msg_close, "Ptr", &zmq_msg_t%A_Index%, "Int") = -1)
                    throw Exception(this.error(), -1, this.errno())
                
                ; close pre zmq_msg_t
                for k, v in data
                    if (DllCall(this.zmq_msg_close, "Ptr", &zmq_msg_t%A_Index%, "Int") = -1)
                        throw Exception(this.error(), -1, this.errno())
                
                throw Exception(this.error(errnum), -1, errnum)
            }
            
            data[A_Index] := {size : full_size
                            , ptr  : DllCall(this.zmq_msg_data, "Ptr", &zmq_msg_t%A_Index%, "Ptr")}
            
            ; if no more
            if (DllCall(this.zmq_msg_more, "Ptr", &zmq_msg_t%A_Index%, "Int") = 0)
                break
        }
        
        buf_arr := []
        
        for k, frame in data
        {
            buffer := {}
            
            buffer.size := frame.size
            buffer.SetCapacity("data", buffer.size)
            buffer.ptr := buffer.GetAddress("data")
            buffer.is_buffer := true
            
            ; copy recv_data to buf
            DllCall(this.zmq_memcpy
                    , "Ptr", buffer.ptr
                    , "Ptr", frame.ptr
                    , "UPtr", frame.size
                    , "Ptr")
            
            buf_arr[A_Index] := buffer
        }
        
        ; close all zmq_msg_t
        for k, v in data
            if (DllCall(this.zmq_msg_close, "Ptr", &zmq_msg_t%A_Index%, "Int") = -1)
                throw Exception(this.error(), -1, this.errno())
        
        return buf_arr
    }
    
    ; return the buffer array, MUST use parse_buffer_array() to get the value
    recv_multipart(flags := 0)
    {
        try
            return this.recv_binary(flags)
        catch e
            throw Exception(e.Message, -1, e.Extra)
    }
    
    ; if merge_frames = true, return the string var
    ; if merge_frames = false, return the string array
    recv_string(flags := 0, encoding := "UTF-16", merge_frames := true)
    {
        if (!merge_frames)
            string := []
        
        loop
        {
            ; struct zmq_msg_t always 64 bytes
            VarSetCapacity(zmq_msg_t, 64, 0)
            
            ; zmq_msg_init() always return 0
            DllCall(this.zmq_msg_init, "Ptr", &zmq_msg_t, "Int")
            
            full_size := DllCall(this.zmq_msg_recv
                                , "Ptr", &zmq_msg_t
                                , "Ptr", this.ptr_socket
                                , "Int", flags
                                , "Int")
            if (full_size = -1)
            {
                errnum := this.errno()
                
                if (DllCall(this.zmq_msg_close, "Ptr", &zmq_msg_t, "Int") = -1)
                    throw Exception(this.error(), -1, this.errno())
                
                throw Exception(this.error(errnum), -1, errnum)
            }
            
            data_ptr := DllCall(this.zmq_msg_data, "Ptr", &zmq_msg_t, "Ptr")
            
            ; StrGet need the length of the string, not number of bytes
            if (encoding="UTF-16" or encoding="CP1200")
            {
                if (merge_frames)
                    string .= StrGet(data_ptr, full_size // 2)
                else
                    string[A_Index] := StrGet(data_ptr, full_size // 2)
            }
            else
            {
                if (merge_frames)
                    string .= StrGet(data_ptr, full_size, encoding)
                else
                    string[A_Index] := StrGet(data_ptr, full_size, encoding)
            }
            
            if (DllCall(this.zmq_msg_close, "Ptr", &zmq_msg_t, "Int") = -1)
                throw Exception(this.error(), -1, this.errno())
            
            ; if no more
            if (DllCall(this.zmq_msg_more, "Ptr", &zmq_msg_t, "Int") = 0)
                break
        }
        
        return string
    }
    
    send(address, send_size, flags := 0)
    {
        full_size := DllCall(this.zmq_send
                            , "Ptr", this.ptr_socket
                            , "Ptr", address
                            , "UPtr", send_size
                            , "Int", flags
                            , "Int")
        if (full_size = -1)
            throw Exception(this.error(), -1, this.errno())
        
        return full_size
    }
    
    ; binary can be a buffer array or a var
    ; if binary is a var, you'd better specify the binary_size
    send_binary(ByRef binary, binary_size := "", flags := 0)
    {
        if (IsObject(binary))
            this.send_multipart(binary, flags)
        else
        {
            if (DllCall(this.zmq_send
                        , "Ptr", this.ptr_socket
                        , "Ptr", &binary
                        , "UPtr", (binary_size != "") ? binary_size : VarSetCapacity(binary)
                        , "Int", flags
                        , "Int") = -1)
                throw Exception(this.error(), -1, this.errno())
        }
    }
    
    ; multipart is the buffer array
    send_multipart(ByRef multipart, flags := 0)
    {
        if (!IsObject(multipart))
            throw Exception("param 1 is not a buffer array.", -1)
        
        maxindex := multipart.MaxIndex()
        for i, v in multipart
        {
            if (!v.is_buffer)
                throw Exception("param 1 index " i " is not a buffer object.", -1)
            
            if (DllCall(this.zmq_send
                        , "Ptr", this.ptr_socket
                        , "Ptr", v.ptr
                        , "UPtr", v.size
                        , "Int", (i = maxindex) ? (flags | 0) : (flags | this.SNDMORE)
                        , "Int") = -1)
                throw Exception(this.error(), -1, this.errno())
        }
    }

    zmq_send_string(ByRef str, encoding := "UTF-8", mode := 0)
    {
        this.zmq_strputvar(str, buf, encoding)
        rtn := DllCall(this.zmq_send
                    , "Ptr", this.ptr_socket
                    , "Ptr", &buf
                    , "UPtr", VarSetCapacity(buf, -1)
                    , "Int", mod
                    , "Int")
        return rtn
    }

    zmq_strputvar(string, ByRef var, encoding)
    {
        ; 确定容量.
        VarSetCapacity( var, StrPut(string, encoding)
            ; StrPut 返回字符数, 但 VarSetCapacity 需要字节数.
            * ((encoding="utf-16"||encoding="cp1200") ? 2 : 1) )
        ; 复制或转换字符串.
        return StrPut(string, &var, encoding)
    }
    
    ; string 使用 ByRef 可以少复制一遍，对提速有帮助
    send_string(ByRef string, flags := 0, encoding := "UTF-16")
    {
        if (encoding="UTF-16" or encoding="CP1200")
        {
            ; this.send_binary(string, VarSetCapacity(string, -1), flags)
            ; 上面这样写比较简洁，但函数调用的消耗会导致速度慢5%左右
            if (DllCall(this.zmq_send
                        , "Ptr", this.ptr_socket
                        , "Ptr", &string
                        , "UPtr", VarSetCapacity(string, -1)
                        , "Int", flags
                        , "Int") = -1)
                throw Exception(this.error(), -1, this.errno())
        }
        else
        {
            ; when encoding is utf-16, StrPut return length of the string + 1
            ; when encoding is not utf-16(e.g. utf-8 or cp936), StrPut return bytes + 1
            ; e.g. "中文abcd" return 7(6+1) with utf-16, return 11(6+4+1) with utf-8
            buf_size := StrPut(string, encoding) - 1
            ; VarSetCapacity(buf, 11, 0) will return 12, i don't know why...
            VarSetCapacity(buf, buf_size, 0)
            StrPut(string, &buf, buf_size, encoding)
            
            if (DllCall(this.zmq_send
                        , "Ptr", this.ptr_socket
                        , "Ptr", &buf
                        , "UPtr", buf_size
                        , "Int", flags
                        , "Int") = -1)
                throw Exception(this.error(), -1, this.errno())
        }
    }
    
    ; items = [ [socket1, zmq.ZMQ_POLLIN], [socket2, zmq.ZMQ_POLLIN] ]
    poller(items)
    {
        if (!IsObject(items.1))
            throw Exception("param 1 must be a two-dimensional array.", -1)
        
        this_clone := this.Clone() ; 避免在 zmq 对象中记录 zmq_pollitem_t events 和 n_items
        
        /*
        特别注意：指南中定义 fd 的类型为 int 。
        zmq.h 中定义 fd 的类型为 zmq_fd_t ， zmq.h 才是对的！！！！！！
        
        typedef struct zmq_pollitem_t{
            void *socket;       //  ZeroMQ socket to poll on
            zmq_fd_t fd;        //  OR, native file handle to poll on
            short events;       //  Events to poll on
            short revents;      //  Events returned after poll
        } zmq_pollitem_t;
        
        以下是 c 语言的调用代码
        zmq_pollitem_t items [] = {
            { receiver,   0, ZMQ_POLLIN, 0 },
            { subscriber, 0, ZMQ_POLLIN, 0 }
        };
        */
        x64 := (A_PtrSize == 8)
        
        this_clone.SetCapacity("zmq_pollitem_t", (x64 ? 24 : 12) * items.Length())
        this_clone.events := []
        this_clone.n_items := 0
        
        address := this_clone.GetAddress("zmq_pollitem_t")
        for i, v in items
        {
            offset := (x64 ? 24 : 12) * (i - 1)
            
            NumPut(v.1.ptr_socket, address + 0, 0 + offset,               "Ptr")
            NumPut(0               address + 0, (x64 ? 8 : 4) + offset,   "Ptr")
            NumPut(v.2,            address + 0, (x64 ? 16 : 8) + offset,  "Short")
            NumPut(0,              address + 0, (x64 ? 18 : 10) + offset, "Short")
            
            this_clone.events[i] := v[2]
            this_clone.n_items++
        }
        
        this_clone.is_from := "poller"
        return this_clone
    }
    
    poll(timeout := -1)
    {
        address := this.GetAddress("zmq_pollitem_t")
        
        if (DllCall(this.zmq_poll
                    , "Ptr", address
                    , "Int", this.n_items
                    , "Int", timeout
                    , "Int") = -1)
            throw Exception(this.error(), -1, this.errno())
        
        x64 := (A_PtrSize == 8)
        ret := []
        loop % this.n_items
        {
            offset := (x64 ? 24 : 12) * (A_Index - 1)
            revents := NumGet(address + 0, (x64 ? 18 : 10) + offset, "Short")
            
            ret[A_Index] := revents & this.events[A_Index]
        }
        
        return ret
    }
    
    proxy(frontend, backend, capture := 0)
    {
        ; it always return -1 and set errno
        DllCall(this.zmq_proxy
                , "Ptr", frontend.ptr_socket
                , "Ptr", backend.ptr_socket
                , "Ptr", capture
                , "Int")
    }
    
    error(errno := "")
    {
        errno      := (errno != "") ? errno : this.errno()
        abbr_error := this.obj_abbr_error[errno]
        str_error  := this.strerror(errno)
        return Format("`n----------`nerrno: {}`nabbr: {}`nstr: {}", errno, abbr_error, str_error)
    }
    
    errno()
    {
        return DllCall(this.zmq_errno, "Int")
    }
    
    strerror(errnum)
    {
        return DllCall(this.zmq_strerror, "Int", errnum, "AStr")
    }
    
    version(flags := "libzmq")
    {
        DllCall(this.zmq_version, "Int*", major, "Int*", minor, "Int*", patch)
        switch flags
        {
            case "libzmq" : return major "." minor "." patch
            case "ahkzmq" : return 20220907
            case "major"  : return major
            case "minor"  : return minor
            case "patch"  : return patch
        }
    }
}

#Include %A_LineFile%\..\ZeroMQ_Constant.ahk