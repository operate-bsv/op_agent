# Operate | Agent

<!-- MDOC !-->

[![hex.pm](https://img.shields.io/hexpm/v/operate.svg)](https://hex.pm/packages/operate)
[![hex.pm](https://img.shields.io/hexpm/dt/operate.svg)](https://hex.pm/packages/operate)
[![hex.pm](https://img.shields.io/hexpm/l/operate.svg)](https://hex.pm/packages/operate)
[![github.com](https://img.shields.io/github/last-commit/operate-bsv/op_agent.svg)](https://github.com/operate-bsv/op_agent)
[![github.com](https://img.shields.io/github/workflow/status/operate-bsv/op_agent/Elixir%20CI)](https://github.com/operate-bsv/op_agent/actions?query=workflow%3A"Elixir+CI")

**Operate | Agent** is an Elixir agent used to load and run programs (known as "tapes") encoded in Bitcoin SV transactions.

## About Operate

Operate is a toolset to help developers build applications, games and services on top of Bitcoin (SV). It lets you write functions, called "Ops", and enables transactions to become small but powerful programs, capable of delivering new classes of services layered over Bitcoin.

More information:

* [Project website](https://www.operatebsv.org)
* [Full documentation](https://hexdocs.pm/operate)

## Installation

The package is bundled with `libsecp256k1` NIF bindings. `libtool`, `automake` and `autogen` are required in order for the package to compile.

The package can be installed by adding `operate` to your list of dependencies in `mix.exs`.

**The most recent `luerl` package published on `hex.pm` is based on Lua 5.2 which may not be compatible with all Ops. It is recommended to override the `luerl` dependency with the latest development version to benefit from Lua 5.3.**

```elixir
def deps do
  [
    {:operate, "~> 0.1.0-beta"},
    {:luerl, github: "rvirding/luerl", branch: "develop", override: true}
  ]
end
```

## Quick start

Operate can be used straight away without starting any processes. This will run without caching so should only be used for testing and kicking the tyres.

```elixir
{:ok, tape} = Operate.load_tape(txid)
{:ok, tape} = Operate.run_tape(tape)

tape.result
```

## Process supervision

To enable caching, Operate should be started as part of your application's process supervision tree.

```elixir
children = [
  {Operate, [
    cache: Operate.Cache.ConCache,
  ]},
  {ConCache, [
    name: :operate,
    ttl_check_interval: :timer.minutes(1),
    global_ttl: :timer.minutes(10),
    touch_on_read: true
  ]}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

## Configuration

Operate can be configured with the following options. Additionally, any of these options can be passed to `Operate.load_tape/2` and `Operate.run_tape/2` to override the configuration.

* `:tape_adapter` - The adapter module used to fetch the tape transaction.
* `:op_adapter` - The adapter module used to fetch the tape's function scripts.
* `:cache` - The cache module used for caching tapes and functions.
* `:extensions` - A list of extension modules to extend the VM state.
* `:aliases` - A map of references to alias functions to alternative references.
* `:strict` - Set `false` to disable strict mode and ignore missing and/or erring functions.

The default configuration:

```elixir
tape_adapter: Operate.Adapter.Bob,
op_adapter: Operate.Adapter.FBHub,
cache: Operate.Cache.NoCache,
extensions: [],
aliases: %{},
strict: true
```

## License

Operate is open source and released under the [Apache-2 License](https://github.com/operate-bsv/op_agent/blob/master/LICENSE).

© Copyright 2019-2020 Chronos Labs Ltd.
