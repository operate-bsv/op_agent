defmodule Operate.VM.Extension.Crypto do
  @moduledoc """
  Extends the VM state with common crypto functions.
  """
  use Operate.VM.Extension
  alias Operate.VM

  def extend(vm) do
    vm
    |> VM.set!("crypto", [])
    |> VM.set!("crypto.aes", [])
    |> VM.set!("crypto.ecdsa", [])
    |> VM.set!("crypto.ecies", [])
    |> VM.set!("crypto.rsa", [])
    |> VM.set!("crypto.hash", [])
    |> VM.set!("crypto.bitcoin_message", [])
    |> VM.set_function!("crypto.aes.encrypt", fn _vm, args ->
      apply(__MODULE__, :aes_encrypt, args)
    end)
    |> VM.set_function!("crypto.aes.decrypt", fn _vm, args ->
      apply(__MODULE__, :aes_decrypt, args)
    end)
    |> VM.set_function!("crypto.ecdsa.sign", fn _vm, args ->
      apply(__MODULE__, :ecdsa_sign, args)
    end)
    |> VM.set_function!("crypto.ecdsa.verify", fn _vm, args ->
      apply(__MODULE__, :ecdsa_verify, args)
    end)
    |> VM.set_function!("crypto.rsa.encrypt", fn _vm, args ->
      apply(__MODULE__, :rsa_encrypt, args)
    end)
    |> VM.set_function!("crypto.rsa.decrypt", fn _vm, args ->
      apply(__MODULE__, :rsa_decrypt, args)
    end)
    |> VM.set_function!("crypto.rsa.sign", fn _vm, args -> apply(__MODULE__, :rsa_sign, args) end)
    |> VM.set_function!("crypto.rsa.verify", fn _vm, args ->
      apply(__MODULE__, :rsa_verify, args)
    end)
    |> VM.set_function!("crypto.hash.ripemd160", fn _vm, args ->
      apply(__MODULE__, :hash, [:ripemd160 | args])
    end)
    |> VM.set_function!("crypto.hash.sha1", fn _vm, args ->
      apply(__MODULE__, :hash, [:sha1 | args])
    end)
    |> VM.set_function!("crypto.hash.sha256", fn _vm, args ->
      apply(__MODULE__, :hash, [:sha256 | args])
    end)
    |> VM.set_function!("crypto.hash.sha512", fn _vm, args ->
      apply(__MODULE__, :hash, [:sha512 | args])
    end)
    |> VM.set_function!("crypto.bitcoin_message.sign", fn _vm, args ->
      apply(__MODULE__, :bitcoin_message_sign, args)
    end)
    |> VM.set_function!("crypto.bitcoin_message.verify", fn _vm, args ->
      apply(__MODULE__, :bitcoin_message_verify, args)
    end)
    |> VM.set_function!("crypto.bitcoin_message.encrypt", fn _vm, args ->
      apply(__MODULE__, :bitcoin_message_encrypt, args)
    end)
    |> VM.set_function!("crypto.bitcoin_message.decrypt", fn _vm, args ->
      apply(__MODULE__, :bitcoin_message_decrypt, args)
    end)
  end

  @doc """
  Hashes the given data using the specified algorithm.
  """
  def hash(mode, data, opts \\ %{})

  def hash(:ripemd160, data, opts) do
    BSV.Hash.ripemd160(data, parse_opts(opts))
  end

  def hash(:sha1, data, opts) do
    BSV.Hash.sha1(data, parse_opts(opts))
  end

  def hash(:sha256, data, opts) do
    BSV.Hash.sha256(data, parse_opts(opts))
  end

  def hash(:sha512, data, opts) do
    BSV.Hash.sha512(data, parse_opts(opts))
  end

  @doc """
  Encrypts the given data with the given secret using AES-GCM.
  """
  def aes_encrypt(clear_text, secret, _opts \\ %{}) do
    # this defaults and tags are to be backward compatible to the BSV 0.3 interface
    ## {:ok, {ad, {iv, cipher_text, cipher_tag}}} =
    ##  ExCrypto.encrypt(secret, auth_data, init_vec, clear_text)
    {:ok, {iv, cipher_text}} = ExCrypto.encrypt(secret, clear_text)
    # pass this back to lua as a list, as then it gets converted to a table
    [iv, cipher_text]
  end

  @doc """
  Decrypts the given data with the given secret using AES-GCM.
  """
  def aes_decrypt(encrypted_payload, key, _opts \\ %{}) do
    [init_vec, cipher_text] = Operate.Util.lua_table_to_list(encrypted_payload)
    # this defaults and tags are to be backward compatible to the BSV 0.3 interface

    case ExCrypto.decrypt(key, init_vec, cipher_text) do
      {:ok, val} -> val
      {_, err} -> err
    end
  end

  @doc """
  Signs the given message with the given ECDSA private key.
  """
  def ecdsa_sign(message, key, opts \\ %{}) do
    Curvy.sign(message, key, parse_opts(opts))
  end

  @doc """
  Verifies the given signature and message with the given ECDSA public key.
  """
  def ecdsa_verify(sig, message, key, opts \\ %{}) do
    Curvy.verify(sig, message, key, parse_opts(opts))
  end

  @doc """
  Encrypts the given data with the given RSA public or private key (in PEM format)
  """
  def rsa_encrypt(data, key, opts \\ %{}) do
    maybe_passphrase =
      case Keyword.fetch(parse_opts(opts), :passphrase) do
        {:ok, pass} -> pass
        _ -> nil
      end

    key = ExPublicKey.loads!(key, maybe_passphrase)

    case key do
      %ExPublicKey.RSAPrivateKey{} ->
        {:ok, clear_text} = ExPublicKey.encrypt_private(data, key, parse_opts(opts))
        clear_text

      %ExPublicKey.RSAPublicKey{} ->
        {:ok, clear_text} = ExPublicKey.encrypt_public(data, key, parse_opts(opts))
        clear_text

      _ ->
        "Invalid or malformed key"
    end
  end

  @doc """
  Decrypts the given data with the given RSA public or private key (in PEM format)
  """
  def rsa_decrypt(data, key, opts \\ %{}) do
    maybe_passphrase =
      case Keyword.fetch(parse_opts(opts), :passphrase) do
        {:ok, pass} -> pass
        _ -> nil
      end

    key = ExPublicKey.loads!(key, maybe_passphrase)

    case key do
      %ExPublicKey.RSAPrivateKey{} ->
        case ExPublicKey.decrypt_private(data, key, parse_opts(opts)) do
          {:ok, clear_text} -> clear_text
          {_, err} -> err
        end

      %ExPublicKey.RSAPublicKey{} ->
        case ExPublicKey.decrypt_public(data, key, parse_opts(opts)) do
          {:ok, clear_text} -> clear_text
          {_, err} -> err
        end

      _ ->
        "Invalid or malformed key"
    end
  end

  @doc """
  Signs the given data with the given RSA private key (in PEM format)
  """
  def rsa_sign(data, key, opts \\ %{}) do
    maybe_passphrase =
      case Keyword.fetch(parse_opts(opts), :passphrase) do
        {:ok, pass} -> pass
        _ -> nil
      end

    key = ExPublicKey.loads!(key, maybe_passphrase)

    case key do
      %ExPublicKey.RSAPrivateKey{} ->
        case ExPublicKey.sign(data, key) do
          {:ok, res} -> res
          {_, _err} -> nil
        end

      _ ->
        "Invalid private key"
    end
  end

  @doc """
  Verifies the given signature and message with the given RSA public key (in PEM format)
  """
  def rsa_verify(sig, data, key, opts \\ %{}) do
    maybe_passphrase =
      case Keyword.fetch(parse_opts(opts), :passphrase) do
        {:ok, pass} -> pass
        _ -> ""
      end

    key = ExPublicKey.loads!(key, maybe_passphrase)

    case key do
      %ExPublicKey.RSAPrivateKey{} ->
        case ExPublicKey.verify(data, sig, ExPublicKey.public_key_from_private_key(key)) do
          {:ok, res} -> res
          {_, _err} -> nil
        end

      %ExPublicKey.RSAPublicKey{} ->
        case ExPublicKey.verify(data, sig, key) do
          {:ok, res} -> res
          {_, _err} -> nil
        end

      _ ->
        {:error, :bad_key}
    end
  end

  @doc """
  Signs the given Bitcoin Message with the given ECDSA private key.
  """
  def bitcoin_message_sign(msg, key, opts \\ %{}) do
    key = Operate.Util.lua_table_to_struct(key)
    BSV.Message.sign(msg, key, parse_opts(opts))
  end

  @doc """
  Verifies the given signature and Bitcoin Message with the given ECDSA public key.
  """
  def bitcoin_message_verify(sig, msg, pubkey_or_address, opts \\ %{})

  def bitcoin_message_verify(sig, msg, key, opts) when is_list(key) do
    key = Operate.Util.lua_table_to_struct(key)
    bitcoin_message_verify(sig, msg, key, opts)
  end

  def bitcoin_message_verify(sig, msg, address, opts) when is_bitstring(address) do
    BSV.Message.verify(sig, msg, BSV.Address.from_string!(address), parse_opts(opts))
  end

  def bitcoin_message_verify(sig, msg, pubkey, opts) when is_struct(pubkey, BSV.PubKey) do
    BSV.Message.verify(sig, msg, pubkey, parse_opts(opts))
  end

  def bitcoin_message_verify(_sig, _msg, _, _opts) do
    "Key must be a %BSV.PubKey{} or address"
  end

  @doc """
  Encrypts the given data with the given ECDSA public key using ECIES.
  """
  def bitcoin_message_encrypt(msg, key, opts \\ %{}) do
    key = Operate.Util.lua_table_to_struct(key)
    BSV.Message.encrypt(msg, key, parse_opts(opts))
  end

  @doc """
  Decrypts the given data with the given ECDSA private key using ECIES.
  """
  def bitcoin_message_decrypt(cipher_text, key, opts \\ %{}) do
    key = Operate.Util.lua_table_to_struct(key)
    BSV.Message.decrypt(cipher_text, key, parse_opts(opts))
  end

  defp parse_opts(opts) do
    Enum.into(opts, [], fn {k, v} ->
      key = String.to_atom(k)

      val =
        case key do
          :encoding -> String.to_atom(v)
          _ -> v
        end

      {key, val}
    end)
  end
end
