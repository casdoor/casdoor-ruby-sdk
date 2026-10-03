# frozen_string_literal: true

RSpec.describe Casdoor::Client do
  subject(:client) do
    described_class.new(endpoint: 'https://door.example.com/', client_id: 'id', client_secret: 'secret',
                        organization_name: 'casbin', application_name: 'app-casbin')
  end

  let(:api) { 'https://door.example.com/api' }

  def ok(data, data2 = nil)
    { status: 200, body: { status: 'ok', msg: '', data: data, data2: data2 }.to_json }
  end

  it 'calls the API with the client ID and secret' do
    stub = stub_request(:get, "#{api}/get-users?owner=casbin").with(basic_auth: %w[id secret])
                                                              .to_return(ok([{ owner: 'casbin', name: 'alice' }]))
    users = client.get_users
    expect(stub).to have_been_requested
    expect(users.map(&:class)).to eq([Casdoor::User])
    expect(users.first.name).to eq('alice')
  end

  it 'calls the API as a user with an access token' do
    stub = stub_request(:get, "#{api}/get-account").with(headers: { 'Authorization' => 'Bearer token' })
                                                   .to_return(ok({ owner: 'casbin', name: 'alice' }))
    expect(client.with_access_token('token').get_account.name).to eq('alice')
    expect(stub).to have_been_requested
    expect(client.access_token).to be_nil
  end

  it 'adds the custom headers' do
    client = described_class.new(endpoint: 'https://door.example.com', client_id: 'id', client_secret: 'secret',
                                 organization_name: 'casbin', application_name: 'app', headers: { 'X-Gateway' => '1' })
    stub = stub_request(:get, "#{api}/get-user?id=casbin/alice").with(headers: { 'X-Gateway' => '1' })
                                                                .to_return(ok(nil))
    expect(client.get_user('alice')).to be_nil
    expect(stub).to have_been_requested
  end

  it 'uses the owner of admin objects and explicit owners' do
    stub_request(:get, "#{api}/get-application?id=admin/app").to_return(ok({ owner: 'admin', name: 'app' }))
    stub_request(:get, "#{api}/get-user?id=other/bob").to_return(ok({ owner: 'other', name: 'bob' }))
    stub_request(:get, "#{api}/get-applications?owner=admin&organization=casbin").to_return(ok([]))

    expect(client.get_application('app')).to be_a(Casdoor::Application)
    expect(client.get_user('other/bob').owner).to eq('other')
    expect(client.get_applications(organization: 'casbin')).to eq([])
  end

  it 'returns the total count of paginated lists' do
    stub_request(:get, "#{api}/get-roles?owner=casbin&p=2&pageSize=10&sortField=name")
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

  it 'accepts hashes as objects' do
    stub_request(:post, "#{api}/add-role?id=casbin/admin").to_return(ok('Affected'))
    expect(client.add_role(name: 'admin')).to be(true)
  end

  it 'updates only the given columns' do
    stub = stub_request(:post, "#{api}/update-user?id=casbin/alice&columns=displayName,email")
           .to_return(ok('Affected'))
    user = Casdoor::User.new(owner: 'casbin', name: 'alice')
    expect(client.update_user(user, columns: %i[display_name email])).to be(true)
    expect(stub).to have_been_requested
  end

  it 'returns false when nothing is changed' do
    stub_request(:post, "#{api}/update-user?id=casbin/alice").to_return(ok('Unaffected'))
    expect(client.update_user(Casdoor::User.new(owner: 'casbin', name: 'alice'))).to be(false)
  end

  it 'deletes an object by name with the whole object' do
    app = { owner: 'admin', name: 'app', organization: 'casbin' }
    stub_request(:get, "#{api}/get-application?id=admin/app").to_return(ok(app))
    stub = stub_request(:post, "#{api}/delete-application?id=admin/app").with(body: app.to_json)
                                                                        .to_return(ok('Affected'))
    expect(client.delete_application('app')).to be(true)
    expect(stub).to have_been_requested
  end

  it 'returns false when deleting an object that does not exist' do
    stub_request(:get, "#{api}/get-application?id=admin/nope").to_return(ok(nil))
    expect(client.delete_application('nope')).to be(false)
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

  it 'finds users by email, phone and user ID' do
    stub_request(:get, "#{api}/get-user?owner=casbin&email=a@example.com").to_return(ok({ name: 'a' }))
    stub_request(:get, "#{api}/get-user?owner=casbin&phone=123").to_return(ok({ name: 'b' }))
    stub_request(:get, "#{api}/get-user?owner=casbin&userId=uuid").to_return(ok({ name: 'c' }))
    expect(client.get_user_by_email('a@example.com').name).to eq('a')
    expect(client.get_user_by_phone('123').name).to eq('b')
    expect(client.get_user_by_user_id('uuid').name).to eq('c')
  end

  it 'counts the users' do
    stub_request(:get, "#{api}/get-user-count?owner=casbin&isOnline=").to_return(ok(5))
    stub_request(:get, "#{api}/get-user-count?owner=casbin&isOnline=1").to_return(ok(2))
    expect(client.get_user_count).to eq(5)
    expect(client.get_user_count(is_online: true)).to eq(2)
  end

  it 'sets the password' do
    stub = stub_request(:post, "#{api}/set-password")
           .with(body: { userOwner: 'casbin', userName: 'alice', oldPassword: '', newPassword: 'new' })
           .to_return(ok(nil))
    expect(client.set_password('casbin', 'alice', 'new')).to be(true)
    expect(stub).to have_been_requested
  end

  it 'checks the password' do
    stub_request(:post, "#{api}/check-user-password?id=casbin/alice").to_return(ok(nil))
    stub_request(:post, "#{api}/check-user-password?id=casbin/bob")
      .to_return(status: 200, body: { status: 'error', msg: 'password or code is incorrect' }.to_json)
    expect(client.check_user_password(name: 'alice', password: '123')).to be(true)
    expect(client.check_user_password(name: 'bob', password: '123')).to be(false)
  end

  it 'enforces the permissions' do
    stub = stub_request(:post, "#{api}/enforce?permissionId=casbin/perm").with(body: '["alice","data1","read"]')
                                                                         .to_return(ok([false, true]))
    stub_request(:post, "#{api}/batch-enforce?modelId=casbin/model").to_return(ok([[true, false]]))
    expect(client.enforce(%w[alice data1 read], permission_id: 'casbin/perm')).to be(true)
    expect(client.batch_enforce([%w[a b c], %w[d e f]], model_id: 'casbin/model')).to eq([[true, false]])
    expect(stub).to have_been_requested
  end
end
