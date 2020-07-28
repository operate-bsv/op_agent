defmodule Operate.VM.Extension.CryptoTest do
  use ExUnit.Case
  alias Operate.VM
  doctest Operate.VM.Extension.Crypto

  setup_all do
    aes_key = BSV.Test.symetric_key
    ecdsa_key = BSV.Test.ecdsa_key |> BSV.Crypto.ECDSA.PrivateKey.from_sequence
    rsa_priv_key = BSV.Crypto.RSA.PrivateKey.from_sequence(BSV.Test.rsa_key)
    rsa_pub_key = BSV.Crypto.RSA.PrivateKey.get_public_key(rsa_priv_key)
    bsv_keys = BSV.KeyPair.from_ecdsa_key(BSV.Test.bsv_keys)
    bsv_address = BSV.Address.from_public_key(bsv_keys)
    vm = VM.init
    |> VM.set!("aes_key", aes_key)
    |> VM.set!("ecdsa_priv_key", ecdsa_key.private_key)
    |> VM.set!("ecdsa_pub_key", ecdsa_key.public_key)
    |> VM.set!("rsa_priv_key", BSV.Crypto.RSA.PrivateKey.as_raw(rsa_priv_key))
    |> VM.set!("rsa_pub_key", BSV.Crypto.RSA.PublicKey.as_raw(rsa_pub_key))
    |> VM.set!("bsv_priv_key", bsv_keys.private_key)
    |> VM.set!("bsv_pub_key", bsv_keys.public_key)
    |> VM.set!("bsv_address", BSV.Address.to_string(bsv_address))
    %{
      vm: vm
    }
  end


  describe "Operate.VM.Extension.Crypto.aes_encrypt/3 and Operate.VM.Extension.Crypto.aes_decrypt/3" do
    test "must encrypt with public key and decrypt with private key", ctx do
      script = """
      enc_data = crypto.aes.encrypt('hello world', aes_key)
      return crypto.aes.decrypt(enc_data, aes_key)
      """
      assert VM.eval!(ctx.vm, script) == "hello world"
    end
  end


  describe "Operate.VM.Extension.Crypto.ecies_encrypt/3 and Operate.VM.Extension.Crypto.ecies_decrypt/3" do
    test "must encrypt with public key and decrypt with private key", ctx do
      script = """
      enc_data = crypto.ecies.encrypt('hello world', ecdsa_pub_key)
      return crypto.ecies.decrypt(enc_data, ecdsa_priv_key)
      """
      assert VM.eval!(ctx.vm, script) == "hello world"
    end
  end


  describe "Operate.VM.Extension.Crypto.ecdsa_sign/3 and Operate.VM.Extension.Crypto.ecdsa_verify/4" do
    test "must sign and verify message", ctx do
      script = """
      sig = crypto.ecdsa.sign('hello world', ecdsa_priv_key)
      return crypto.ecdsa.verify(sig, 'hello world', ecdsa_pub_key)
      """
      assert VM.eval!(ctx.vm, script) == true
    end

    test "wont verify when different message", ctx do
      script = """
      sig = crypto.ecdsa.sign('hello world', ecdsa_priv_key)
      return crypto.ecdsa.verify(sig, 'goodbye world', ecdsa_pub_key)
      """
      assert VM.eval!(ctx.vm, script) == false
    end
  end


  describe "Operate.VM.Extension.Crypto.rsa_encrypt/3 and Operate.VM.Extension.Crypto.rsa_decrypt/3" do
    @tag :rsa
    test "must encrypt with public key and decrypt with private key", ctx do
      script = """
      enc_data = crypto.rsa.encrypt('hello world', rsa_pub_key)
      return crypto.rsa.decrypt(enc_data, rsa_priv_key)
      """
      assert VM.eval!(ctx.vm, script) == "hello world"
    end

    @tag :rsa
    test "must encrypt with private key and decrypt with public key", ctx do
      script = """
      enc_data = crypto.rsa.encrypt('hello world', rsa_priv_key)
      return crypto.rsa.decrypt(enc_data, rsa_pub_key)
      """
      assert VM.eval!(ctx.vm, script) == "hello world"
    end
  end


  describe "Operate.VM.Extension.Crypto.rsa_sign/3 and Operate.VM.Extension.Crypto.rsa_verify/4" do
    @tag :rsa
    test "must sign and verify message", ctx do
      script = """
      sig = crypto.rsa.sign('hello world', rsa_priv_key)
      return crypto.rsa.verify(sig, 'hello world', rsa_pub_key)
      """
      assert VM.eval!(ctx.vm, script) == true
    end

    @tag :rsa
    test "wont verify when different message", ctx do
      script = """
      sig = crypto.rsa.sign('hello world', rsa_priv_key)
      return crypto.rsa.verify(sig, 'goodbye world', rsa_pub_key)
      """
      assert VM.eval!(ctx.vm, script) == false
    end
  end


  describe "Operate.VM.Extension.Crypto.hash functions" do
    test "must create a ripemd160 hash", ctx do
      assert VM.eval!(ctx.vm, "return crypto.hash.ripemd160('hello world')") == <<
        152, 198, 21, 120, 76, 203, 95, 229, 147, 111, 188, 12, 190, 157,
        253, 180, 8, 217, 47, 15>>
    end

    test "must create a sha1 hash", ctx do
      assert VM.eval!(ctx.vm, "return crypto.hash.sha1('hello world')") == <<
        42, 174, 108, 53, 201, 79, 207, 180, 21, 219, 233, 95, 64, 139,
        156, 233, 30, 232, 70, 237>>
    end

    test "must create a sha256 hash", ctx do
      assert VM.eval!(ctx.vm, "return crypto.hash.sha256('hello world')") == <<
        185, 77, 39, 185, 147, 77, 62, 8, 165, 46, 82, 215, 218, 125, 171,
        250, 196, 132, 239, 227, 122, 83, 128, 238, 144, 136, 247, 172,
        226, 239, 205, 233>>
    end

    test "must create a sha512 hash", ctx do
      assert VM.eval!(ctx.vm, "return crypto.hash.sha512('hello world')") == <<
        48, 158, 204, 72, 156, 18, 214, 235, 76, 196, 15, 80, 201, 2, 242,
        180, 208, 237, 119, 238, 81, 26, 124, 122, 155, 205, 60, 168, 109,
        76, 216, 111, 152, 157, 211, 91, 197, 255, 73, 150, 112, 218, 52, 37,
        91, 69, 176, 207, 216, 48, 232, 31, 96, 93, 207, 125, 197, 84,
        46, 147, 174, 156, 215, 111>>
    end
  end


  describe "Operate.VM.Extension.Crypto.bitcoin_message_sign/3 and Operate.VM.Extension.Crypto.bitcoin_message_verify/4" do
    test "must sign and verify message", ctx do
      script = """
      sig = crypto.bitcoin_message.sign('hello world', bsv_priv_key)
      return crypto.bitcoin_message.verify(sig, 'hello world', bsv_pub_key)
      """
      assert VM.eval!(ctx.vm, script) == true
    end

    test "must verify message with address", ctx do
      script = """
      sig = crypto.bitcoin_message.sign('hello world', bsv_priv_key)
      return crypto.bitcoin_message.verify(sig, 'hello world', bsv_address)
      """
      assert VM.eval!(ctx.vm, script) == true
    end

    test "wont verify when different message", ctx do
      script = """
      sig = crypto.bitcoin_message.sign('hello world', bsv_priv_key)
      return crypto.bitcoin_message.verify(sig, 'goodbye world', bsv_pub_key)
      """
      assert VM.eval!(ctx.vm, script) == false
    end
  end

end
