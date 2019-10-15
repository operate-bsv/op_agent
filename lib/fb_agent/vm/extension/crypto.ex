defmodule FBAgent.VM.Extension.Crypto do
  @moduledoc """
  Extends the VM state with common crypto functions.
  """
  alias FBAgent.VM

  @behaviour VM.Extension

  def extend(vm) do
    vm
    |> VM.set!("crypto", [])
    |> VM.set!("crypto.aes", [])
    |> VM.set!("crypto.ecdsa", [])
    |> VM.set!("crypto.ecies", [])
    |> VM.set!("crypto.rsa", [])
    |> VM.set!("crypto.hash", [])
    |> VM.set_function!("crypto.aes.encrypt", fn _vm, args -> apply(__MODULE__, :aes_encrypt, args) end)
    |> VM.set_function!("crypto.aes.decrypt", fn _vm, args -> apply(__MODULE__, :aes_decrypt, args) end)
    |> VM.set_function!("crypto.ecies.encrypt", fn _vm, args -> apply(__MODULE__, :ecies_encrypt, args) end)
    |> VM.set_function!("crypto.ecies.decrypt", fn _vm, args -> apply(__MODULE__, :ecies_decrypt, args) end)
    |> VM.set_function!("crypto.ecdsa.sign", fn _vm, args -> apply(__MODULE__, :ecdsa_sign, args) end)
    |> VM.set_function!("crypto.ecdsa.verify", fn _vm, args -> apply(__MODULE__, :ecdsa_verify, args) end)
    |> VM.set_function!("crypto.rsa.encrypt", fn _vm, args -> apply(__MODULE__, :rsa_encrypt, args) end)
    |> VM.set_function!("crypto.rsa.decrypt", fn _vm, args -> apply(__MODULE__, :rsa_decrypt, args) end)
    |> VM.set_function!("crypto.rsa.sign", fn _vm, args -> apply(__MODULE__, :rsa_sign, args) end)
    |> VM.set_function!("crypto.rsa.verify", fn _vm, args -> apply(__MODULE__, :rsa_verify, args) end)
    |> VM.set_function!("crypto.hash.ripemd160", fn _vm, args -> apply(__MODULE__, :hash, [:ripemd160 | args]) end)
    |> VM.set_function!("crypto.hash.sha1", fn _vm, args -> apply(__MODULE__, :hash, [:sha | args]) end)
    |> VM.set_function!("crypto.hash.sha256", fn _vm, args -> apply(__MODULE__, :hash, [:sha256 | args]) end)
    |> VM.set_function!("crypto.hash.sha512", fn _vm, args -> apply(__MODULE__, :hash, [:sha512 | args]) end)
  end


  @doc """
  Hashes the given data using the specified algorithm.
  """
  def hash(algo, data, opts \\ %{}) do
    BSV.Crypto.Hash.hash(data, algo, parse_opts(opts))
  end

  @doc """
  Encrypts the given data with the given secret using AES-GCM.
  """
  def aes_encrypt(data, key, opts \\ %{}) do
    BSV.Crypto.AES.encrypt(data, :gcm, key, parse_opts(opts))
  end

  @doc """
  Decrypts the given data with the given secret using AES-GCM.
  """
  def aes_decrypt(data, key, opts \\ %{}) do
    BSV.Crypto.AES.decrypt(data, :gcm, key, parse_opts(opts))
  end

  @doc """
  Encrypts the given data with the given ECDSA public key using ECIES.
  """
  def ecies_encrypt(data, key, opts \\ %{}) do
    BSV.Crypto.ECIES.encrypt(data, key, parse_opts(opts))
  end

  @doc """
  Decrypts the given data with the given ECDSA private key using ECIES.
  """
  def ecies_decrypt(data, key, opts \\ %{}) do
    BSV.Crypto.ECIES.decrypt(data, key, parse_opts(opts))
  end

  @doc """
  Signs the given data with the given ECDSA private key.
  """
  def ecdsa_sign(data, key, opts \\ %{}) do
    BSV.Crypto.ECDSA.sign(data, key, parse_opts(opts))
  end

  @doc """
  Verifies the given signature and message with the given ECDSA public key.
  """
  def ecdsa_verify(sig, data, key, opts \\ %{}) do
    BSV.Crypto.ECDSA.verify(sig, data, key, parse_opts(opts))
  end

  @doc """
  Encrypts the given data with the given RSA public or private key.
  """
  def rsa_encrypt(data, key, opts \\ %{}) do
    key = VM.decode(key) |> from_raw
    BSV.Crypto.RSA.encrypt(data, key, parse_opts(opts))
  end

  @doc """
  Decrypts the given data with the given RSA public or private key.
  """
  def rsa_decrypt(data, key, opts \\ %{}) do
    key = VM.decode(key) |> from_raw
    BSV.Crypto.RSA.decrypt(data, key, parse_opts(opts))
  end

  @doc """
  Signs the given data with the given RSA private key.
  """
  def rsa_sign(data, key, opts \\ %{}) do
    key = VM.decode(key) |> from_raw
    BSV.Crypto.RSA.sign(data, key, parse_opts(opts))
  end

  @doc """
  Verifies the given signature and message with the given RSA public key.
  """
  def rsa_verify(sig, data, key, opts \\ %{}) do
    key = VM.decode(key) |> from_raw
    BSV.Crypto.RSA.verify(sig, data, key, parse_opts(opts))
  end


  defp parse_opts(opts) do
    Enum.into(opts, [], fn {k, v} ->
      key = String.to_atom(k)
      val = case key do
        :encode -> String.to_atom(v)
        _ -> v
      end
      {key, val}
    end)
  end

  defp from_raw([_e, _n] = key), do: BSV.Crypto.RSA.PublicKey.from_raw(key)
  defp from_raw(key), do: BSV.Crypto.RSA.PrivateKey.from_raw(key)
  
end