defmodule RubiconAPI do
  @callback handshake() :: :ok | {:error, any}
  @callback exunit_results(results :: map) :: :ok | {:error, any}

  def handshake(node) do
    :rpc.block_call(node, Rubicon, :handshake, [])
  end

  def prompt(node, type, message, opts \\ []) do
    :rpc.block_call(node, Rubicon, :prompt, [type, message, opts])
  end

  def exunit_results(node, results) do
    :rpc.block_call(node, Rubicon, :exunit_results, [results])
  end
end
