require 'spec_helper'

describe "relationships" do
  let(:node) { 'test.example.com' }
  let(:facts) { {
    :fqdn     => 'test.example.com',
  } }

  it { is_expected.to contain_yumrepo('internal').that_comes_before('Multi_rel[internal]') }

  # these tests fail because they're calculated internally. I don't know how to test them
  it { is_expected.to contain_manifold('internal').that_comes_before('Package[foo]') }
  it { is_expected.to contain_manifold('internal').that_comes_before('Package[bar]') }
  it { is_expected.to contain_manifold('internal').that_comes_before('Package[baz]') }

  it { is_expected.to contain_package('foo') }
  it { is_expected.to contain_package('bar') }
  it { is_expected.to contain_package('baz') }

end
