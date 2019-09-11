defmodule FBAgent.VM.CryptoExtension do
  @moduledoc """
  Extends the VM state with common crypto functions.
  """
  alias FBAgent.VM


  @doc """
  Sets up the given VM state setting a table with attached function handlers.
  """
  @spec setup(VM.vm) :: VM.vm
  def setup(state) do
    state
    |> Sandbox.set!("crypto.aes", [], true)
    |> Sandbox.set!("crypto.ecdsa", [], true)
    |> Sandbox.set!("crypto.rsa", [], true)
    |> Sandbox.set!("crypto.hash", [], true)
    |> Sandbox.let_elixir_eval!("crypto.aes.encrypt", fn _state, args -> apply(__MODULE__, :aes_encrypt, args) end)
    |> Sandbox.let_elixir_eval!("crypto.aes.decrypt", fn _state, args -> apply(__MODULE__, :aes_decrypt, args) end)
    |> Sandbox.let_elixir_eval!("crypto.ecdsa.sign", fn _state, args -> apply(__MODULE__, :ecdsa_sign, args) end)
    |> Sandbox.let_elixir_eval!("crypto.ecdsa.verify", fn _state, args -> apply(__MODULE__, :ecdsa_verify, args) end)
    |> Sandbox.let_elixir_eval!("crypto.rsa.encrypt", fn _state, args -> apply(__MODULE__, :rsa_encrypt, args) end)
    |> Sandbox.let_elixir_eval!("crypto.rsa.decrypt", fn _state, args -> apply(__MODULE__, :rsa_decrypt, args) end)
    |> Sandbox.let_elixir_eval!("crypto.rsa.sign", fn _state, args -> apply(__MODULE__, :rsa_sign, args) end)
    |> Sandbox.let_elixir_eval!("crypto.rsa.verify", fn _state, args -> apply(__MODULE__, :rsa_verify, args) end)
    |> Sandbox.let_elixir_eval!("crypto.hash.ripemd160", fn _state, args -> apply(__MODULE__, :hash, [:ripemd160 | args]) end)
    |> Sandbox.let_elixir_eval!("crypto.hash.sha1", fn _state, args -> apply(__MODULE__, :hash, [:sha | args]) end)
    |> Sandbox.let_elixir_eval!("crypto.hash.sha256", fn _state, args -> apply(__MODULE__, :hash, [:sha256 | args]) end)
    |> Sandbox.let_elixir_eval!("crypto.hash.sha512", fn _state, args -> apply(__MODULE__, :hash, [:sha512 | args]) end)
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