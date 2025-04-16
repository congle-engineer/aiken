use aiken/collection/list
use cardano/assets.{PolicyId, quantity_of, merge}
use cardano/transaction.{Transaction, OutputReference, find_input}

pub type SwapParams {
  old_policy: PolicyId,
  old_token: ByteArray,
  new_policy: PolicyId,
  new_token: ByteArray
}

validator swap(params: SwapParams) {
  spend(_datum: Option<Data>, _redeemer: Data, own_ref: OutputReference, self: Transaction) {
    let Transaction { inputs, outputs, .. } = self

    // Get old tokens in inputs
    let old_token_in_inputs =
      list.filter(
        inputs,
        fn(input) { quantity_of(input.output.value, params.old_policy, params.old_token) >= 1 },
      )
 
    let sum_old_token_in_inputs =
      list.foldl(
        old_token_in_inputs,
        assets.zero,
        fn(input, total) { merge(input.output.value, total) },
      )

    let total_old_token_in_inputs =
      quantity_of(sum_old_token_in_inputs, params.old_policy, params.old_token)
 
    // Get new tokens in inputs
    expect Some(new_token_in_inputs) = find_input(inputs, own_ref)

    let total_new_token_in_inputs =
      quantity_of(new_token_in_inputs.output.value, params.new_policy, params.new_token)

    let contract_address = new_token_in_inputs.output.address

    // Get new tokens in outputs to user
    let new_token_in_outputs_to_user =
      list.any(
        outputs,
        fn(output) { quantity_of(output.value, params.new_policy, params.new_token) == total_old_token_in_inputs },
      )

    // Get old tokens in outputs to contract
    let old_token_in_outputs_to_contract =
      list.any(
        outputs,
        fn(output) { output.address == contract_address && quantity_of(output.value, params.old_policy, params.old_token) == total_old_token_in_inputs },
      )

    // Get remaining new tokens in outputs to contract
    let remaining_new_token_in_outputs_to_contract =
      list.any(
        outputs,
        fn(output) { output.address == contract_address && quantity_of(output.value, params.new_policy, params.new_token) == total_new_token_in_inputs - total_old_token_in_inputs },
      )

    // Check inputs has old tokens
    (total_old_token_in_inputs > 0)? &&
    // Check inputs has new tokens
    (total_new_token_in_inputs > 0)? &&
    // Check total new tokens >= total old tokens in inputs
    (total_new_token_in_inputs >= total_old_token_in_inputs)? &&
    // Check new tokens in outputs to user
    new_token_in_outputs_to_user? &&
    // Check old tokens in outputs to contract
    old_token_in_outputs_to_contract? &&
    // Check remaining new tokens in outputs to contract
    remaining_new_token_in_outputs_to_contract?
  }
}
