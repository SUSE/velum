FactoryGirl.define do
  factory :certificate do
    certificate %(
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            e6:4d:fd:80:de:e5:5e:20
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=AU, ST=Some-State, O=Internet Widgits Pty Ltd
        Validity
            Not Before: Jan 15 13:04:33 2018 GMT
            Not After : Feb 14 13:04:33 2018 GMT
        Subject: C=AU, ST=Some-State, O=Internet Widgits Pty Ltd
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (4096 bit)
                Modulus:
                    00:d3:f7:39:b9:c4:f6:fb:ff:bf:97:fb:38:42:f3:
                    48:da:4b:fa:c6:62:92:27:44:7c:8c:72:a6:11:a8:
                    e6:d3:1b:d5:c2:68:d7:be:2e:91:c8:c6:67:d1:78:
                    f9:10:e4:73:0f:f1:43:c3:f2:da:f3:38:9e:7e:4e:
                    af:aa:bf:40:d6:6e:28:86:0f:f3:5e:b7:b8:09:52:
                    a9:03:28:b4:f8:64:3b:d2:29:0a:9f:4c:eb:6f:35:
                    8a:ec:c9:4f:14:20:73:33:6d:a4:8f:18:fa:46:fd:
                    4f:08:3e:42:f0:ce:69:45:b6:ca:bb:0a:82:7f:4c:
                    f9:c4:28:c8:28:2c:c8:a5:6c:e9:1c:ec:e9:07:84:
                    fa:62:35:13:11:f0:c6:b3:2f:46:82:d7:cb:7c:23:
                    71:e5:8b:2d:11:32:ca:4c:1d:c5:17:57:37:1c:8f:
                    76:15:7e:2c:d5:b3:79:6c:cd:c7:b6:11:dd:64:52:
                    13:24:69:7f:ad:e8:a3:f6:d5:60:06:16:bd:b8:8d:
                    e0:4a:ab:d3:2a:e3:e1:41:cb:fa:0b:72:4d:09:f6:
                    9d:8e:9e:86:7a:ea:87:1f:7f:49:1f:40:93:ad:a5:
                    b0:64:33:e4:3a:a6:5d:94:23:3e:9f:2a:0a:e6:97:
                    df:b6:dc:1b:eb:3b:d0:8b:ab:33:0d:e2:78:83:c4:
                    ca:f7:9d:d9:9a:dc:33:54:0c:bf:5f:48:35:b1:c3:
                    df:b6:0f:f2:b4:5b:b0:c3:86:ee:b4:c6:5f:8a:e4:
                    8c:f8:83:44:4b:fb:da:3f:06:4c:73:8e:a2:48:fb:
                    4e:60:58:d7:84:4d:5e:78:43:db:2e:3e:1d:c5:16:
                    63:b1:d6:44:c0:6c:ab:35:66:de:a5:27:f1:25:48:
                    43:e9:a9:75:42:ac:f4:3d:4c:f0:7e:84:0e:db:60:
                    41:61:26:ca:b1:6f:e9:9e:b1:94:9e:2e:4c:42:85:
                    63:9f:14:79:c4:27:78:f7:90:44:49:28:48:7d:d1:
                    01:33:90:8a:91:2b:e4:f2:b0:10:b9:af:e4:e4:10:
                    a0:ad:71:bc:df:75:d5:45:2f:04:0f:f0:65:e5:1f:
                    df:18:e1:96:34:ba:c0:84:3b:7c:d9:ff:86:8d:d2:
                    2e:a4:4b:e6:42:0e:82:5f:36:cd:6e:dd:f4:c6:ba:
                    48:51:21:27:00:26:a6:2d:6b:61:0d:a5:43:a5:ca:
                    82:0d:a5:3f:fb:b1:04:d2:0f:41:35:49:35:3b:6e:
                    9d:ad:e0:2d:81:18:bb:8d:d3:18:64:c5:01:79:16:
                    2d:1f:13:75:1a:d6:7d:a7:ba:fd:f4:15:5b:8b:03:
                    19:25:1a:7e:49:90:69:07:0d:68:b2:46:1b:5e:ba:
                    1f:a2:13
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Key Identifier:
                6C:B5:66:46:4D:CE:8A:B0:DF:7F:2D:7A:A3:C6:6B:08:37:9D:53:5B
            X509v3 Authority Key Identifier:
                keyid:6C:B5:66:46:4D:CE:8A:B0:DF:7F:2D:7A:A3:C6:6B:08:37:9D:53:5B

            X509v3 Basic Constraints:
                CA:TRUE
    Signature Algorithm: sha256WithRSAEncryption
         18:6c:28:a7:c0:2d:fa:14:0a:6f:84:73:ed:3b:a6:10:04:6d:
         88:af:dc:83:c2:8b:7c:a3:99:69:f3:35:b8:26:3c:f3:c5:7c:
         2f:c8:00:f1:83:e4:1e:42:e7:ac:0c:4d:5e:1e:22:b5:a7:9b:
         32:e6:4a:8a:63:28:50:3a:68:80:38:d3:d8:c5:82:92:95:a7:
         30:a8:6e:ba:d8:47:2c:ed:70:16:b9:a9:aa:27:99:08:65:e7:
         2d:24:7b:d6:e8:0f:7e:6b:b9:88:40:3c:18:a1:20:29:75:85:
         15:5e:d7:d7:12:2c:87:ba:17:7c:11:f5:69:40:64:96:0d:e6:
         2b:d8:5b:9d:74:a3:7b:3f:aa:15:fd:7d:b6:fd:54:23:bc:af:
         62:40:11:c9:d5:d5:1c:c7:80:9d:fb:42:ea:a9:15:cc:e2:a2:
         43:55:6d:9a:cb:95:0e:c8:11:3a:1a:e1:15:25:95:ad:e8:9c:
         00:af:04:2c:65:b0:5e:5e:73:c3:84:8a:6a:46:dc:12:c5:dc:
         2f:95:0c:17:70:f1:6b:d8:65:68:f2:a0:1a:b4:16:be:c0:99:
         64:e4:2a:8a:0b:3e:19:4b:97:3b:86:75:c3:cb:3f:90:b6:c1:
         39:7e:69:45:99:57:29:ef:68:3d:48:fd:06:03:aa:87:7a:2b:
         01:c5:8d:89:d6:f5:b8:b5:61:c1:03:54:3a:c4:a3:3e:59:a5:
         86:4f:ee:8c:92:55:93:5a:37:b1:3d:8f:1f:05:cc:bd:5f:0f:
         cf:ab:70:0b:14:31:30:74:11:ce:a0:32:8c:10:f0:38:54:92:
         78:88:dd:ca:76:63:f3:ab:22:af:c5:7c:93:2f:b9:21:42:16:
         a1:60:54:f6:39:28:e5:ff:84:ac:29:43:4e:5a:ee:d3:f2:fa:
         30:d3:79:05:a2:8d:b6:6f:9a:d6:b0:b8:1e:d6:50:6d:03:59:
         2f:55:86:21:99:c8:d8:d9:d6:24:46:2e:1b:44:9f:a2:0b:8d:
         6a:44:bb:01:96:8b:99:ac:6c:ed:4c:c8:12:e8:9a:5c:eb:1f:
         2c:0f:b7:1d:4c:b5:3f:e8:60:0c:83:a2:fd:c3:d2:02:e3:3f:
         71:72:38:9d:0e:e3:34:ca:7d:19:c6:a1:ac:a5:5e:13:ea:d7:
         d4:81:d5:5e:12:2b:23:18:c1:7a:79:c9:01:41:0c:07:59:32:
         b9:66:eb:ae:9f:4f:00:7a:95:66:69:d2:6a:d3:fb:05:1d:61:
         01:c6:07:5a:76:85:37:c7:54:0d:5e:bf:47:31:33:d0:dd:52:
         ee:1e:8c:61:56:c6:db:9c:ed:62:a9:9f:f7:1e:1e:a8:f7:45:
         5c:f8:18:72:14:3d:5c:58
-----BEGIN CERTIFICATE-----
MIIFXTCCA0WgAwIBAgIJAOZN/YDe5V4gMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMTgwMTE1MTMwNDMzWhcNMTgwMjE0MTMwNDMzWjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
CgKCAgEA0/c5ucT2+/+/l/s4QvNI2kv6xmKSJ0R8jHKmEajm0xvVwmjXvi6RyMZn
0Xj5EORzD/FDw/La8ziefk6vqr9A1m4ohg/zXre4CVKpAyi0+GQ70ikKn0zrbzWK
7MlPFCBzM22kjxj6Rv1PCD5C8M5pRbbKuwqCf0z5xCjIKCzIpWzpHOzpB4T6YjUT
EfDGsy9GgtfLfCNx5YstETLKTB3FF1c3HI92FX4s1bN5bM3HthHdZFITJGl/reij
9tVgBha9uI3gSqvTKuPhQcv6C3JNCfadjp6GeuqHH39JH0CTraWwZDPkOqZdlCM+
nyoK5pffttwb6zvQi6szDeJ4g8TK953ZmtwzVAy/X0g1scPftg/ytFuww4butMZf
iuSM+INES/vaPwZMc46iSPtOYFjXhE1eeEPbLj4dxRZjsdZEwGyrNWbepSfxJUhD
6al1Qqz0PUzwfoQO22BBYSbKsW/pnrGUni5MQoVjnxR5xCd495BESShIfdEBM5CK
kSvk8rAQua/k5BCgrXG833XVRS8ED/Bl5R/fGOGWNLrAhDt82f+GjdIupEvmQg6C
XzbNbt30xrpIUSEnACamLWthDaVDpcqCDaU/+7EE0g9BNUk1O26dreAtgRi7jdMY
ZMUBeRYtHxN1GtZ9p7r99BVbiwMZJRp+SZBpBw1oskYbXrofohMCAwEAAaNQME4w
HQYDVR0OBBYEFGy1ZkZNzoqw338teqPGawg3nVNbMB8GA1UdIwQYMBaAFGy1ZkZN
zoqw338teqPGawg3nVNbMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggIB
ABhsKKfALfoUCm+Ec+07phAEbYiv3IPCi3yjmWnzNbgmPPPFfC/IAPGD5B5C56wM
TV4eIrWnmzLmSopjKFA6aIA409jFgpKVpzCobrrYRyztcBa5qaonmQhl5y0ke9bo
D35ruYhAPBihICl1hRVe19cSLIe6F3wR9WlAZJYN5ivYW510o3s/qhX9fbb9VCO8
r2JAEcnV1RzHgJ37QuqpFcziokNVbZrLlQ7IEToa4RUlla3onACvBCxlsF5ec8OE
impG3BLF3C+VDBdw8WvYZWjyoBq0Fr7AmWTkKooLPhlLlzuGdcPLP5C2wTl+aUWZ
VynvaD1I/QYDqod6KwHFjYnW9bi1YcEDVDrEoz5ZpYZP7oySVZNaN7E9jx8FzL1f
D8+rcAsUMTB0Ec6gMowQ8DhUkniI3cp2Y/OrIq/FfJMvuSFCFqFgVPY5KOX/hKwp
Q05a7tPy+jDTeQWijbZvmtawuB7WUG0DWS9VhiGZyNjZ1iRGLhtEn6ILjWpEuwGW
i5msbO1MyBLomlzrHywPtx1MtT/oYAyDov3D0gLjP3FyOJ0O4zTKfRnGoaylXhPq
19SB1V4SKyMYwXp5yQFBDAdZMrlm666fTwB6lWZp0mrT+wUdYQHGB1p2hTfHVA1e
v0cxM9DdUu4ejGFWxtuc7WKpn/ceHqj3RVz4GHIUPVxY
-----END CERTIFICATE-----
)
  end
end
