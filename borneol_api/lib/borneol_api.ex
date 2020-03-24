defmodule BorneolApi do
  def set_status(node, status) do
    :rpc.block_call(node, GenServer, :call, [BorneolHost, {:set_status, status}])
  end

  def test_results(node, results) do
    :rpc.block_call(node, GenServer, :call, [BorneolHost, {:test_results, results}])
  end
end
