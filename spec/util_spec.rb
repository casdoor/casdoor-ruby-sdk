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

# Unit tests of the HTTP layer with stubbed requests, they don't need a Casdoor
RSpec.describe Casdoor::Client do
  subject(:client) do
    Casdoor.new_client('https://door.example.com/', 'id', 'secret', nil, 'casbin', 'app-casbin')
  end

  let(:api) { 'https://door.example.com/api' }

  def ok(data, data2 = nil)
    { status: 200, body: { status: 'ok', msg: '', data: data, data2: data2 }.to_json }
  end

  it 'calls the API with the client ID and secret' do
    stub = stub_request(:get, "#{api}/get-users?owner=casbin")
           .with(basic_auth: %w[id secret])
           .to_return(ok([{ owner: 'casbin', name: 'alice' }]))
    users = client.get_users
    expect(stub).to have_been_requested
    expect(users.map(&:class)).to eq([Casdoor::User])
    expect(users.first.name).to eq('alice')
  end

  it 'calls the API as a user with an access token' do
    stub = stub_request(:get, "#{api}/get-account")
           .with(headers: { 'Authorization' => 'Bearer token' })
           .to_return(ok({ owner: 'casbin', name: 'alice' }))
    expect(client.with_access_token('token').get_account.name).to eq('alice')
    expect(stub).to have_been_requested
    expect(client.access_token).to be_nil
  end

  it 'adds the custom headers' do
    client.custom_headers['X-Gateway'] = '1'
    stub = stub_request(:get, "#{api}/get-user?id=casbin/alice")
           .with(headers: { 'X-Gateway' => '1' })
           .to_return(ok(nil))
    expect(client.get_user('alice')).to be_nil
    expect(stub).to have_been_requested
  end

  it 'uses "admin" as the owner of the admin objects' do
    stub_request(:get, "#{api}/get-application?id=admin/app").to_return(ok({ owner: 'admin', name: 'app' }))
    stub_request(:get, "#{api}/get-organizations?owner=admin").to_return(ok([{ owner: 'admin', name: 'casbin' }]))
    stub_request(:get, "#{api}/get-user?id=other/bob").to_return(ok({ owner: 'other', name: 'bob' }))

    expect(client.get_application('app')).to be_a(Casdoor::Application)
    expect(client.get_organizations.map(&:name)).to eq(['casbin'])
    expect(client.get_user('other/bob').owner).to eq('other')
  end

  it 'returns the total count of the paginated lists' do
    stub_request(:get, "#{api}/get-roles?sortField=name&owner=casbin&p=2&pageSize=10")
      .to_return(ok([{ name: 'r1' }], 11))
    roles, total = client.get_pagination_roles(2, 10, sort_field: 'name')
    expect(roles.first).to be_a(Casdoor::Role)
    expect(total).to eq(11)
  end

  it 'adds an object with the default owner' do
    stub = stub_request(:post, "#{api}/add-user?id=casbin/alice")
           .with(body: { name: 'alice', displayName: 'Alice', owner: 'casbin' }.to_json)
           .to_return(ok('Affected'))
    expect(client.add_user(Casdoor::User.new(name: 'alice', display_name: 'Alice'))).to be(true)
    expect(stub).to have_been_requested
  end

  it 'updates only the given columns' do
    stub = stub_request(:post, "#{api}/update-user?id=casbin/alice&columns=displayName,email")
           .to_return(ok('Affected'))
    user = Casdoor::User.new(owner: 'casbin', name: 'alice')
    expect(client.update_user_for_columns(user, %i[display_name email])).to be(true)
    expect(stub).to have_been_requested
  end

  it 'returns false when nothing is affected' do
    stub_request(:post, "#{api}/update-user?id=casbin/alice").to_return(ok('Unaffected'))
    expect(client.update_user(Casdoor::User.new(owner: 'casbin', name: 'alice'))).to be(false)
  end

  it 'raises the error message of Casdoor' do
    stub_request(:get, "#{api}/get-users?owner=casbin")
      .to_return(status: 200, body: { status: 'error', msg: 'Unauthorized operation' }.to_json)
    expect { client.get_users }.to raise_error(Casdoor::ApiError, 'Unauthorized operation')
  end

  it 'raises the HTTP errors' do
    stub_request(:get, "#{api}/get-users?owner=casbin").to_return(status: 502, body: '<html>Bad Gateway</html>')
    expect { client.get_users }.to raise_error(Casdoor::HttpError) { |error| expect(error.status).to eq(502) }
  end

  it 'posts the policies with the JSON names of Casdoor' do
    stub = stub_request(:post, "#{api}/add-policy?id=casbin/enforcer")
           .with(body: { Ptype: 'p', V0: 'alice', V1: 'data1', V2: 'read' }.to_json)
           .to_return(ok('Affected'))
    rule = Casdoor::CasbinRule.new(ptype: 'p', v0: 'alice', v1: 'data1', v2: 'read')
    expect(client.add_policy(Casdoor::Enforcer.new(name: 'enforcer'), rule)).to be(true)
    expect(stub).to have_been_requested
  end

  it 'calls the API with the global client' do
    Casdoor.init_config('https://door.example.com', 'id', 'secret', nil, 'casbin', 'app-casbin')
    stub_request(:get, "#{api}/get-user?id=casbin/alice").to_return(ok({ owner: 'casbin', name: 'alice' }))
    expect(Casdoor.get_user('alice').name).to eq('alice')
    expect(Casdoor.get_signin_url('https://app.example.com/callback')).to include('client_id=id')
  end
end
