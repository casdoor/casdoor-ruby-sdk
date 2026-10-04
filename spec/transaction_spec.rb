# frozen_string_literal: true

# Copyright 2026 The Casdoor Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

RSpec.describe 'Casdoor transaction API', :integration do
  it 'adds, gets, updates and deletes a transaction' do
    TestUtil.init_config

    # Add a new object, Casdoor names it
    transaction = Casdoor::Transaction.new(
      owner: 'casbin',
      created_time: Casdoor.get_current_time,
      state: 'Paid'
    )
    affected, transaction_id = Casdoor.add_transaction(transaction)
    expect(affected).to be(true)
    expect(transaction_id).not_to be_empty

    # Get all objects, check if our added object is inside the list
    transactions = Casdoor.get_transactions
    expect(transactions.map(&:name)).to include(transaction_id)

    # Get the object
    transaction = Casdoor.get_transaction(transaction_id)
    expect(transaction.name).to eq(transaction_id)

    # Update the object
    updated_display_name = 'Organization'
    transaction.display_name = updated_display_name
    expect(Casdoor.update_transaction(transaction)).to be(true)

    # Validate the update
    updated_transaction = Casdoor.get_transaction(transaction_id)
    expect(updated_transaction.display_name).to eq(updated_display_name)

    # Delete the object
    expect(Casdoor.delete_transaction(transaction)).to be(true)

    # Validate the deletion
    deleted_transaction = Casdoor.get_transaction(transaction_id)
    expect(deleted_transaction).to be_nil
  end
end
