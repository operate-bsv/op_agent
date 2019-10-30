# Operate | Agent

Operate is an extensible Bitcoin meta programming protocol. It offers a way of constructing Turing Complete programs encapsulated in Bitcoin transactions that can be be used to process data, perform calculations and operations, and return any kind of result.

**Operate | Agent** is an Elixir agent used to load and run programs (known as "tapes").

More infomation:

* [Project website](https://www.operatebsv.org)
* [Full documentation](https://hexdocs.pm/operate)

## Installation

The package is bundled with `libsecp256k1` NIF bindings. `libtool`, `automake` and `autogen` are required in order for the package to compile.

The package can be installed by adding `operate` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:operate, "~> 0.0.1"}
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

* `:tape_adpater` - The adapter module used to fetch the tape transaction.
* `:proc_adpater` - The adapter module used to fetch the tape's function scripts.
* `:cache` - The cache module used for caching tapes and functions.
* `:extensions` - A list of extension modules to extend the VM state.
* `:aliases` - A map of references to alias functions to alternative references.
* `:strict` - Set `false` to disable strict mode and ignore missing and/or erring functions.

The default configuration:

```elixir
tape_adapter: Operate.Adapter.Bob,
proc_adapter: Operate.Adapter.FBHub,
cache: Operate.Cache.NoCache,
extensions: [],
aliases: %{},
strict: true
```

## License

© Copyright 2019 libitx.

BSV-ex is free software and released under the [MIT license](https://github.com/libitx/bsv-elixir/blob/master/LICENSE.md).