# frozen_string_literal: true

RSpec.describe Casdoor::Entity do
  subject(:user) { Casdoor::User.new('owner' => 'casbin', 'name' => 'alice', 'displayName' => 'Alice', 'isAdmin' => true) }

  it 'converts snake_case to camelCase' do
    expect(described_class.camelize(:display_name)).to eq('displayName')
    expect(described_class.camelize('enable_web_authn')).to eq('enableWebAuthn')
    expect(described_class.camelize('email')).to eq('email')
  end

  it 'reads the fields in snake_case' do
    expect(user.owner).to eq('casbin')
    expect(user.display_name).to eq('Alice')
    expect(user[:display_name]).to eq('Alice')
    expect(user['displayName']).to eq('Alice')
    expect(user.is_admin?).to be(true)
    expect(user.email).to be_nil
  end

  it 'writes the fields in snake_case' do
    user.email = 'alice@example.com'
    user[:phone_number] = '123'
    expect(user.to_h).to include('email' => 'alice@example.com', 'phoneNumber' => '123')
  end

  it 'keeps the fields that the SDK does not know' do
    user = Casdoor::User.new(JSON.parse('{"name":"alice","someNewField":{"a":1}}'))
    user.display_name = 'Alice'
    expect(JSON.parse(user.to_json)).to eq('name' => 'alice', 'someNewField' => { 'a' => 1 }, 'displayName' => 'Alice')
  end

  it 'accepts symbol keys in snake_case' do
    app = Casdoor::Application.new(owner: 'admin', name: 'app', homepage_url: 'https://casdoor.org')
    expect(app.to_h).to eq('owner' => 'admin', 'name' => 'app', 'homepageUrl' => 'https://casdoor.org')
  end

  it 'compares by class and fields' do
    expect(user).to eq(Casdoor::User.new(user.to_h))
    expect(user).not_to eq(Casdoor::Application.new(user.to_h))
  end
end
