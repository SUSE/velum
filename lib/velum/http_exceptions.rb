module Velum
  module HTTPExceptions
    EXCEPTIONS = [
      SocketError,
      Errno::ETIMEDOUT,
      Net::ReadTimeout,
      Net::OpenTimeout,
      Net::ProtocolError,
      Errno::ECONNREFUSED,
      Errno::EHOSTDOWN,
      Errno::ECONNRESET,
      Errno::ENETUNREACH,
      Errno::EHOSTUNREACH,
      Errno::ECONNABORTED,
      OpenSSL::SSL::SSLError,
      EOFError
    ].freeze
  end
end
