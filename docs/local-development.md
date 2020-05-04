# Local Development

Documentation regarding standing up a local development environment.

## Getting Started

### Conveniences

The prerequisites section will want you to install Elixir and Erlang, this is one way:

- [asdf](https://github.com/asdf-vm/asdf)
  - [Install asdf](https://asdf-vm.com/#/core-manage-asdf-vm)
  - `asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git`
  - `asdf install erlang 22.3.2`.
  - `asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git`
  - `asdf install elixir 1.10.3-otp-22`

### Prerequisites

- Erlang version `22.x.x`.
- Elixir version `1.10.x-otp-22`.
- `mix local.hex`
- `mix local.rebar`
- `mix deps.get`
- Ensure you are [setup for Nerves](https://hexdocs.pm/nerves/installation.html#all-platforms).
- `pkg-config`. A Brew installable dependency required by VintageNetWiFi.
- `fwup`. A Brew installable dependency required by Nerves.
- `squashfs`. A Brew installable dependency required by Nerves.
- `glfw3`. A Brew installable dependency required by Scenic.
- `glew`. A Brew installable dependency required by Scenic.

## Testing

`mix test`.

## Building Firmware

```
MIX_TARGET=rpi3 mix do deps.get, firmware
```

## Burning Firmware

First build the firware, then:

```
MIX_TARGET=rpi3 mix firmware.burn
```
