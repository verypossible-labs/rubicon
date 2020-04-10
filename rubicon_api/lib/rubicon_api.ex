defmodule RubiconApi do
  def set_status(node, status) do
    :rpc.block_call(node, GenServer, :call, [RubiconHost, {:set_status, status}])
  end

  def test_results(node, results) do
    :rpc.block_call(node, GenServer, :call, [RubiconHost, {:test_results, results}])
  end
end
