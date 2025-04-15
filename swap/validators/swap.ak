use aiken/collection/list
use cardano/assets.{PolicyId, AssetName, Value, quantity_of}
use cardano/transaction.{Transaction, OutputReference}

pub type SwapParams {
  old_policy: PolicyId,
  old_token: ByteArray,
  new_policy: PolicyId,
  new_token: ByteArray
}

validator swap(params: SwapParams) {
  spend(_datum: Option<Data>, _redeemer: Data, _utxo: OutputReference, self: Transaction) {
    let Transaction { inputs, .. } = self
    expect Some(old_tokens) = list.find(inputs, fn(input) { quantity_of(input.output.value, params.old_policy, params.old_token) >= 1 } )
    expect Some(new_tokens) = list.find(inputs, fn(input) { quantity_of(input.output.value, params.new_policy, params.new_token) >= 1 } )
    old_tokens.output.value == new_tokens.output.value
  }
}
