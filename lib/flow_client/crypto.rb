# frozen_string_literal: true

require "openssl"

module FlowClient
  # Crypto helpers
  class Crypto
    def self.sign(data, key)
      digest = OpenSSL::Digest.digest("SHA3-256", data)
      asn = key.dsa_sign_asn1(digest)
      asn1 = OpenSSL::ASN1.decode(asn)
      r, s = asn1.value
      combined_bytes = Utils.left_pad_bytes([r.value.to_s(16)].pack("H*").unpack("C*"), 32) +
                       Utils.left_pad_bytes([s.value.to_s(16)].pack("H*").unpack("C*"), 32)
      combined_bytes.pack("C*")
    end

    # TODO: Handle both sig algos here
    # secp256k1
    # prime256v1
    def self.key_from_hex_keys(private_hex, public_hex)
      asn1 = OpenSSL::ASN1::Sequence(
        [
          OpenSSL::ASN1::Integer(1),
          OpenSSL::ASN1::OctetString([private_hex].pack("H*")),
          OpenSSL::ASN1::ObjectId("prime256v1", 0, :EXPLICIT),
          OpenSSL::ASN1::BitString([public_hex].pack("H*"), 1, :EXPLICIT)
        ]
      )

      OpenSSL::PKey::EC.new(asn1.to_der)
    end
  end
end
