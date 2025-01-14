open Lean

namespace Curl

inductive ErrorCode
  | CURLE_OK
  | CURLE_UNSUPPORTED_PROTOCOL
  | CURLE_FAILED_INIT
  | CURLE_URL_MALFORMAT
  | CURLE_NOT_BUILT_IN
  | CURLE_COULDNT_RESOLVE_PROXY
  | CURLE_COULDNT_RESOLVE_HOST
  | CURLE_COULDNT_CONNECT
  | CURLE_WEIRD_SERVER_REPLY
  | CURLE_REMOTE_ACCESS_DENIED
  | CURLE_FTP_ACCEPT_FAILED
  | CURLE_FTP_WEIRD_PASS_REPLY
  | CURLE_FTP_ACCEPT_TIMEOUT
  | CURLE_FTP_WEIRD_PASV_REPLY
  | CURLE_FTP_WEIRD_227_FORMAT
  | CURLE_FTP_CANT_GET_HOST
  | CURLE_HTTP2
  | CURLE_FTP_COULDNT_SET_TYPE
  | CURLE_PARTIAL_FILE
  | CURLE_FTP_COULDNT_RETR_FILE
  | CURLE_OBSOLETE20
  | CURLE_QUOTE_ERROR
  | CURLE_HTTP_RETURNED_ERROR
  | CURLE_WRITE_ERROR
  | CURLE_OBSOLETE24
  | CURLE_UPLOAD_FAILED
  | CURLE_READ_ERROR
  | CURLE_OUT_OF_MEMORY
  | CURLE_OPERATION_TIMEDOUT
  | CURLE_OBSOLETE29
  | CURLE_FTP_PORT_FAILED
  | CURLE_FTP_COULDNT_USE_REST
  | CURLE_OBSOLETE32
  | CURLE_RANGE_ERROR
  | CURLE_HTTP_POST_ERROR
  | CURLE_SSL_CONNECT_ERROR
  | CURLE_BAD_DOWNLOAD_RESUME
  | CURLE_FILE_COULDNT_READ_FILE
  | CURLE_LDAP_CANNOT_BIND
  | CURLE_LDAP_SEARCH_FAILED
  | CURLE_OBSOLETE40
  | CURLE_FUNCTION_NOT_FOUND
  | CURLE_ABORTED_BY_CALLBACK
  | CURLE_BAD_FUNCTION_ARGUMENT
  | CURLE_OBSOLETE44
  | CURLE_INTERFACE_FAILED
  | CURLE_OBSOLETE46
  | CURLE_TOO_MANY_REDIRECTS
  | CURLE_UNKNOWN_OPTION
  | CURLE_TELNET_OPTION_SYNTAX
  | CURLE_OBSOLETE50
  | CURLE_OBSOLETE51
  | CURLE_GOT_NOTHING
  | CURLE_SSL_ENGINE_NOTFOUND
  | CURLE_SSL_ENGINE_SETFAILED
  | CURLE_SEND_ERROR
  | CURLE_RECV_ERROR
  | CURLE_OBSOLETE57
  | CURLE_SSL_CERTPROBLEM
  | CURLE_SSL_CIPHER
  | CURLE_PEER_FAILED_VERIFICATION
  | CURLE_BAD_CONTENT_ENCODING
  | CURLE_LDAP_INVALID_URL
  | CURLE_FILESIZE_EXCEEDED
  | CURLE_USE_SSL_FAILED
  | CURLE_SEND_FAIL_REWIND
  | CURLE_SSL_ENGINE_INITFAILED
  | CURLE_LOGIN_DENIED
  | CURLE_TFTP_NOTFOUND
  | CURLE_TFTP_PERM
  | CURLE_REMOTE_DISK_FULL
  | CURLE_TFTP_ILLEGAL
  | CURLE_TFTP_UNKNOWNID
  | CURLE_REMOTE_FILE_EXISTS
  | CURLE_TFTP_NOSUCHUSER
  | CURLE_CONV_FAILED
  | CURLE_CONV_REQD
  | CURLE_SSL_CACERT_BADFILE
  | CURLE_REMOTE_FILE_NOT_FOUND
  | CURLE_SSH
  | CURLE_SSL_SHUTDOWN_FAILED
  | CURLE_AGAIN
  | CURLE_SSL_CRL_BADFILE
  | CURLE_SSL_ISSUER_ERROR
  | CURLE_FTP_PRET_FAILED
  | CURLE_RTSP_CSEQ_ERROR
  | CURLE_RTSP_SESSION_ERROR
  | CURLE_FTP_BAD_FILE_LIST
  | CURLE_CHUNK_FAILED
  | CURLE_NO_CONNECTION_AVAILABLE
  | CURLE_SSL_PINNEDPUBKEYNOTMATCH
  | CURLE_SSL_INVALIDCERTSTATUS
  | CURLE_HTTP2_STREAM
  | CURLE_RECURSIVE_API_CALL
  | CURLE_AUTH_ERROR
  | CURLE_HTTP3
  | CURLE_UNKNOWN : UInt32 -> ErrorCode
deriving BEq, Hashable

instance : ToString ErrorCode where
  toString
    | .CURLE_OK => "CURLE_OK"
    | .CURLE_UNSUPPORTED_PROTOCOL => "CURLE_UNSUPPORTED_PROTOCOL"
    | .CURLE_FAILED_INIT => "CURLE_FAILED_INIT"
    | .CURLE_URL_MALFORMAT => "CURLE_URL_MALFORMAT"
    | .CURLE_NOT_BUILT_IN => "CURLE_NOT_BUILT_IN"
    | .CURLE_COULDNT_RESOLVE_PROXY => "CURLE_COULDNT_RESOLVE_PROXY"
    | .CURLE_COULDNT_RESOLVE_HOST => "CURLE_COULDNT_RESOLVE_HOST"
    | .CURLE_COULDNT_CONNECT => "CURLE_COULDNT_CONNECT"
    | .CURLE_WEIRD_SERVER_REPLY => "CURLE_WEIRD_SERVER_REPLY"
    | .CURLE_REMOTE_ACCESS_DENIED => "CURLE_REMOTE_ACCESS_DENIED"
    | .CURLE_FTP_ACCEPT_FAILED => "CURLE_FTP_ACCEPT_FAILED"
    | .CURLE_FTP_WEIRD_PASS_REPLY => "CURLE_FTP_WEIRD_PASS_REPLY"
    | .CURLE_FTP_ACCEPT_TIMEOUT => "CURLE_FTP_ACCEPT_TIMEOUT"
    | .CURLE_FTP_WEIRD_PASV_REPLY => "CURLE_FTP_WEIRD_PASV_REPLY"
    | .CURLE_FTP_WEIRD_227_FORMAT => "CURLE_FTP_WEIRD_227_FORMAT"
    | .CURLE_FTP_CANT_GET_HOST => "CURLE_FTP_CANT_GET_HOST"
    | .CURLE_HTTP2 => "CURLE_HTTP2"
    | .CURLE_FTP_COULDNT_SET_TYPE => "CURLE_FTP_COULDNT_SET_TYPE"
    | .CURLE_PARTIAL_FILE => "CURLE_PARTIAL_FILE"
    | .CURLE_FTP_COULDNT_RETR_FILE => "CURLE_FTP_COULDNT_RETR_FILE"
    | .CURLE_OBSOLETE20 => "CURLE_OBSOLETE20"
    | .CURLE_QUOTE_ERROR => "CURLE_QUOTE_ERROR"
    | .CURLE_HTTP_RETURNED_ERROR => "CURLE_HTTP_RETURNED_ERROR"
    | .CURLE_WRITE_ERROR => "CURLE_WRITE_ERROR"
    | .CURLE_OBSOLETE24 => "CURLE_OBSOLETE24"
    | .CURLE_UPLOAD_FAILED => "CURLE_UPLOAD_FAILED"
    | .CURLE_READ_ERROR => "CURLE_READ_ERROR"
    | .CURLE_OUT_OF_MEMORY => "CURLE_OUT_OF_MEMORY"
    | .CURLE_OPERATION_TIMEDOUT => "CURLE_OPERATION_TIMEDOUT"
    | .CURLE_OBSOLETE29 => "CURLE_OBSOLETE29"
    | .CURLE_FTP_PORT_FAILED => "CURLE_FTP_PORT_FAILED"
    | .CURLE_FTP_COULDNT_USE_REST => "CURLE_FTP_COULDNT_USE_REST"
    | .CURLE_OBSOLETE32 => "CURLE_OBSOLETE32"
    | .CURLE_RANGE_ERROR => "CURLE_RANGE_ERROR"
    | .CURLE_HTTP_POST_ERROR => "CURLE_HTTP_POST_ERROR"
    | .CURLE_SSL_CONNECT_ERROR => "CURLE_SSL_CONNECT_ERROR"
    | .CURLE_BAD_DOWNLOAD_RESUME => "CURLE_BAD_DOWNLOAD_RESUME"
    | .CURLE_FILE_COULDNT_READ_FILE => "CURLE_FILE_COULDNT_READ_FILE"
    | .CURLE_LDAP_CANNOT_BIND => "CURLE_LDAP_CANNOT_BIND"
    | .CURLE_LDAP_SEARCH_FAILED => "CURLE_LDAP_SEARCH_FAILED"
    | .CURLE_OBSOLETE40 => "CURLE_OBSOLETE40"
    | .CURLE_FUNCTION_NOT_FOUND => "CURLE_FUNCTION_NOT_FOUND"
    | .CURLE_ABORTED_BY_CALLBACK => "CURLE_ABORTED_BY_CALLBACK"
    | .CURLE_BAD_FUNCTION_ARGUMENT => "CURLE_BAD_FUNCTION_ARGUMENT"
    | .CURLE_OBSOLETE44 => "CURLE_OBSOLETE44"
    | .CURLE_INTERFACE_FAILED => "CURLE_INTERFACE_FAILED"
    | .CURLE_OBSOLETE46 => "CURLE_OBSOLETE46"
    | .CURLE_TOO_MANY_REDIRECTS => "CURLE_TOO_MANY_REDIRECTS"
    | .CURLE_UNKNOWN_OPTION => "CURLE_UNKNOWN_OPTION"
    | .CURLE_TELNET_OPTION_SYNTAX => "CURLE_TELNET_OPTION_SYNTAX"
    | .CURLE_OBSOLETE50 => "CURLE_OBSOLETE50"
    | .CURLE_OBSOLETE51 => "CURLE_OBSOLETE51"
    | .CURLE_GOT_NOTHING => "CURLE_GOT_NOTHING"
    | .CURLE_SSL_ENGINE_NOTFOUND => "CURLE_SSL_ENGINE_NOTFOUND"
    | .CURLE_SSL_ENGINE_SETFAILED => "CURLE_SSL_ENGINE_SETFAILED"
    | .CURLE_SEND_ERROR => "CURLE_SEND_ERROR"
    | .CURLE_RECV_ERROR => "CURLE_RECV_ERROR"
    | .CURLE_OBSOLETE57 => "CURLE_OBSOLETE57"
    | .CURLE_SSL_CERTPROBLEM => "CURLE_SSL_CERTPROBLEM"
    | .CURLE_SSL_CIPHER => "CURLE_SSL_CIPHER"
    | .CURLE_PEER_FAILED_VERIFICATION => "CURLE_PEER_FAILED_VERIFICATION"
    | .CURLE_BAD_CONTENT_ENCODING => "CURLE_BAD_CONTENT_ENCODING"
    | .CURLE_LDAP_INVALID_URL => "CURLE_LDAP_INVALID_URL"
    | .CURLE_FILESIZE_EXCEEDED => "CURLE_FILESIZE_EXCEEDED"
    | .CURLE_USE_SSL_FAILED => "CURLE_USE_SSL_FAILED"
    | .CURLE_SEND_FAIL_REWIND => "CURLE_SEND_FAIL_REWIND"
    | .CURLE_SSL_ENGINE_INITFAILED => "CURLE_SSL_ENGINE_INITFAILED"
    | .CURLE_LOGIN_DENIED => "CURLE_LOGIN_DENIED"
    | .CURLE_TFTP_NOTFOUND => "CURLE_TFTP_NOTFOUND"
    | .CURLE_TFTP_PERM => "CURLE_TFTP_PERM"
    | .CURLE_REMOTE_DISK_FULL => "CURLE_REMOTE_DISK_FULL"
    | .CURLE_TFTP_ILLEGAL => "CURLE_TFTP_ILLEGAL"
    | .CURLE_TFTP_UNKNOWNID => "CURLE_TFTP_UNKNOWNID"
    | .CURLE_REMOTE_FILE_EXISTS => "CURLE_REMOTE_FILE_EXISTS"
    | .CURLE_TFTP_NOSUCHUSER => "CURLE_TFTP_NOSUCHUSER"
    | .CURLE_CONV_FAILED => "CURLE_CONV_FAILED"
    | .CURLE_CONV_REQD => "CURLE_CONV_REQD"
    | .CURLE_SSL_CACERT_BADFILE => "CURLE_SSL_CACERT_BADFILE"
    | .CURLE_REMOTE_FILE_NOT_FOUND => "CURLE_REMOTE_FILE_NOT_FOUND"
    | .CURLE_SSH => "CURLE_SSH"
    | .CURLE_SSL_SHUTDOWN_FAILED => "CURLE_SSL_SHUTDOWN_FAILED"
    | .CURLE_AGAIN => "CURLE_AGAIN"
    | .CURLE_SSL_CRL_BADFILE => "CURLE_SSL_CRL_BADFILE"
    | .CURLE_SSL_ISSUER_ERROR => "CURLE_SSL_ISSUER_ERROR"
    | .CURLE_FTP_PRET_FAILED => "CURLE_FTP_PRET_FAILED"
    | .CURLE_RTSP_CSEQ_ERROR => "CURLE_RTSP_CSEQ_ERROR"
    | .CURLE_RTSP_SESSION_ERROR => "CURLE_RTSP_SESSION_ERROR"
    | .CURLE_FTP_BAD_FILE_LIST => "CURLE_FTP_BAD_FILE_LIST"
    | .CURLE_CHUNK_FAILED => "CURLE_CHUNK_FAILED"
    | .CURLE_NO_CONNECTION_AVAILABLE => "CURLE_NO_CONNECTION_AVAILABLE"
    | .CURLE_SSL_PINNEDPUBKEYNOTMATCH => "CURLE_SSL_PINNEDPUBKEYNOTMATCH"
    | .CURLE_SSL_INVALIDCERTSTATUS => "CURLE_SSL_INVALIDCERTSTATUS"
    | .CURLE_HTTP2_STREAM => "CURLE_HTTP2_STREAM"
    | .CURLE_RECURSIVE_API_CALL => "CURLE_RECURSIVE_API_CALL"
    | .CURLE_AUTH_ERROR => "CURLE_AUTH_ERROR"
    | .CURLE_HTTP3 => "CURLE_HTTP3"
    | .CURLE_UNKNOWN code => s!"CURLE_UNKNOWN, code {code}"

inductive ErrorCodeM
  | CURLM_OK
  | CURLM_BAD_HANDLE
  | CURLM_BAD_EASY_HANDLE
  | CURLM_OUT_OF_MEMORY
  | CURLM_INTERNAL_ERROR
  | CURLM_BAD_SOCKET
  | CURLM_UNKNOWN_OPTION
  | CURLM_ADDED_ALREADY
  | CURLM_RECURSIVE_API_CALL
  | CURLM_WAKEUP_FAILURE
  | CURLM_UNKNOWN : UInt32 -> ErrorCodeM
deriving BEq, Hashable

instance : ToString ErrorCodeM where
  toString
    | .CURLM_OK => "CURLM_OK"
    | .CURLM_BAD_HANDLE => "CURLM_BAD_HANDLE"
    | .CURLM_BAD_EASY_HANDLE => "CURLM_BAD_EASY_HANDLE"
    | .CURLM_OUT_OF_MEMORY => "CURLM_OUT_OF_MEMORY"
    | .CURLM_INTERNAL_ERROR => "CURLM_INTERNAL_ERROR"
    | .CURLM_BAD_SOCKET => "CURLM_BAD_SOCKET"
    | .CURLM_UNKNOWN_OPTION => "CURLM_UNKNOWN_OPTION"
    | .CURLM_ADDED_ALREADY => "CURLM_ADDED_ALREADY"
    | .CURLM_RECURSIVE_API_CALL => "CURLM_RECURSIVE_API_CALL"
    | .CURLM_WAKEUP_FAILURE => "CURLM_WAKEUP_FAILURE"
    | .CURLM_UNKNOWN code => s!"CURLM_UNKNOWN, code {code}"

inductive Error
  | init (code : UInt32)
  | setopt (code : UInt32) (opt : UInt32)
  | perform (code : UInt32)
  | initM (code : UInt32)
  | performM (code : UInt32)
  deriving Inhabited

namespace Error

  def ofCode : UInt32 -> ErrorCode
    | 0 => .CURLE_OK
    | 1 => .CURLE_UNSUPPORTED_PROTOCOL
    | 2 => .CURLE_FAILED_INIT
    | 3 => .CURLE_URL_MALFORMAT
    | 4 => .CURLE_NOT_BUILT_IN
    | 5 => .CURLE_COULDNT_RESOLVE_PROXY
    | 6 => .CURLE_COULDNT_RESOLVE_HOST
    | 7 => .CURLE_COULDNT_CONNECT
    | 8 => .CURLE_WEIRD_SERVER_REPLY
    | 9 => .CURLE_REMOTE_ACCESS_DENIED
    | 10 => .CURLE_FTP_ACCEPT_FAILED
    | 11 => .CURLE_FTP_WEIRD_PASS_REPLY
    | 12 => .CURLE_FTP_ACCEPT_TIMEOUT
    | 13 => .CURLE_FTP_WEIRD_PASV_REPLY
    | 14 => .CURLE_FTP_WEIRD_227_FORMAT
    | 15 => .CURLE_FTP_CANT_GET_HOST
    | 16 => .CURLE_HTTP2
    | 17 => .CURLE_FTP_COULDNT_SET_TYPE
    | 18 => .CURLE_PARTIAL_FILE
    | 19 => .CURLE_FTP_COULDNT_RETR_FILE
    | 20 => .CURLE_OBSOLETE20
    | 21 => .CURLE_QUOTE_ERROR
    | 22 => .CURLE_HTTP_RETURNED_ERROR
    | 23 => .CURLE_WRITE_ERROR
    | 24 => .CURLE_OBSOLETE24
    | 25 => .CURLE_UPLOAD_FAILED
    | 26 => .CURLE_READ_ERROR
    | 27 => .CURLE_OUT_OF_MEMORY
    | 28 => .CURLE_OPERATION_TIMEDOUT
    | 29 => .CURLE_OBSOLETE29
    | 30 => .CURLE_FTP_PORT_FAILED
    | 31 => .CURLE_FTP_COULDNT_USE_REST
    | 32 => .CURLE_OBSOLETE32
    | 33 => .CURLE_RANGE_ERROR
    | 34 => .CURLE_HTTP_POST_ERROR
    | 35 => .CURLE_SSL_CONNECT_ERROR
    | 36 => .CURLE_BAD_DOWNLOAD_RESUME
    | 37 => .CURLE_FILE_COULDNT_READ_FILE
    | 38 => .CURLE_LDAP_CANNOT_BIND
    | 39 => .CURLE_LDAP_SEARCH_FAILED
    | 40 => .CURLE_OBSOLETE40
    | 41 => .CURLE_FUNCTION_NOT_FOUND
    | 42 => .CURLE_ABORTED_BY_CALLBACK
    | 43 => .CURLE_BAD_FUNCTION_ARGUMENT
    | 44 => .CURLE_OBSOLETE44
    | 45 => .CURLE_INTERFACE_FAILED
    | 46 => .CURLE_OBSOLETE46
    | 47 => .CURLE_TOO_MANY_REDIRECTS
    | 48 => .CURLE_UNKNOWN_OPTION
    | 49 => .CURLE_TELNET_OPTION_SYNTAX
    | 50 => .CURLE_OBSOLETE50
    | 51 => .CURLE_OBSOLETE51
    | 52 => .CURLE_GOT_NOTHING
    | 53 => .CURLE_SSL_ENGINE_NOTFOUND
    | 54 => .CURLE_SSL_ENGINE_SETFAILED
    | 55 => .CURLE_SEND_ERROR
    | 56 => .CURLE_RECV_ERROR
    | 57 => .CURLE_OBSOLETE57
    | 58 => .CURLE_SSL_CERTPROBLEM
    | 59 => .CURLE_SSL_CIPHER
    | 60 => .CURLE_PEER_FAILED_VERIFICATION
    | 61 => .CURLE_BAD_CONTENT_ENCODING
    | 62 => .CURLE_LDAP_INVALID_URL
    | 63 => .CURLE_FILESIZE_EXCEEDED
    | 64 => .CURLE_USE_SSL_FAILED
    | 65 => .CURLE_SEND_FAIL_REWIND
    | 66 => .CURLE_SSL_ENGINE_INITFAILED
    | 67 => .CURLE_LOGIN_DENIED
    | 68 => .CURLE_TFTP_NOTFOUND
    | 69 => .CURLE_TFTP_PERM
    | 70 => .CURLE_REMOTE_DISK_FULL
    | 71 => .CURLE_TFTP_ILLEGAL
    | 72 => .CURLE_TFTP_UNKNOWNID
    | 73 => .CURLE_REMOTE_FILE_EXISTS
    | 74 => .CURLE_TFTP_NOSUCHUSER
    | 75 => .CURLE_CONV_FAILED
    | 76 => .CURLE_CONV_REQD
    | 77 => .CURLE_SSL_CACERT_BADFILE
    | 78 => .CURLE_REMOTE_FILE_NOT_FOUND
    | 79 => .CURLE_SSH
    | 80 => .CURLE_SSL_SHUTDOWN_FAILED
    | 81 => .CURLE_AGAIN
    | 82 => .CURLE_SSL_CRL_BADFILE
    | 83 => .CURLE_SSL_ISSUER_ERROR
    | 84 => .CURLE_FTP_PRET_FAILED
    | 85 => .CURLE_RTSP_CSEQ_ERROR
    | 86 => .CURLE_RTSP_SESSION_ERROR
    | 87 => .CURLE_FTP_BAD_FILE_LIST
    | 88 => .CURLE_CHUNK_FAILED
    | 89 => .CURLE_NO_CONNECTION_AVAILABLE
    | 90 => .CURLE_SSL_PINNEDPUBKEYNOTMATCH
    | 91 => .CURLE_SSL_INVALIDCERTSTATUS
    | 92 => .CURLE_HTTP2_STREAM
    | 93 => .CURLE_RECURSIVE_API_CALL
    | 94 => .CURLE_AUTH_ERROR
    | 95 => .CURLE_HTTP3
    | code => .CURLE_UNKNOWN code

  def ofCodeM : UInt32 -> ErrorCodeM
    | 0 => .CURLM_OK
    | 1 => .CURLM_BAD_HANDLE
    | 2 => .CURLM_BAD_EASY_HANDLE
    | 3 => .CURLM_OUT_OF_MEMORY
    | 4 => .CURLM_INTERNAL_ERROR
    | 5 => .CURLM_BAD_SOCKET
    | 6 => .CURLM_UNKNOWN_OPTION
    | 7 => .CURLM_ADDED_ALREADY
    | 8 => .CURLM_RECURSIVE_API_CALL
    | 9 => .CURLM_WAKEUP_FAILURE
    | code => .CURLM_UNKNOWN code

  instance : ToString Curl.Error where
    toString
      | .init code =>  s!"easy_init failed (error code: {Curl.Error.ofCode code})"
      | .setopt code opt =>  s!"easy_setopt {opt} failed (error code: {Curl.Error.ofCode code})"
      | .perform code =>  s!"easy_perform failed (error code: {Curl.Error.ofCode code})"
      | .initM code =>  s!"multi_init failed (error code: {Curl.Error.ofCodeM code})"
      | .performM code =>  s!"multi_perform failed (error code: {Curl.Error.ofCodeM code})"

end Error
