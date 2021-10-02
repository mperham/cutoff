# frozen_string_literal:true

RSpec.describe Cutoff::Patch::NetHttp do
  it 'raises if started after cutoff expired' do
    Timecop.freeze
    Cutoff.start(2)
    Timecop.freeze(3)
    expect do
      Net::HTTP.get(URI.parse('http://example.com'))
    end.to raise_error(Cutoff::CutoffExceededError)
  end

  it 'sets timeouts to remaining seconds during start' do
    Timecop.freeze
    Cutoff.start(5)
    Timecop.freeze(2)
    uri = URI.parse('http://example.com')
    Net::HTTP.start(uri.host, uri.port, read_timeout: 20) do |http|
      expect(http.read_timeout).to eq(3)
      expect(http.continue_timeout).to eq(3)
      expect(http.open_timeout).to eq(3)
    end
  end

  it 'uses existing timeout if smaller' do
    Timecop.freeze
    Cutoff.start(5)
    Timecop.freeze(2)
    uri = URI.parse('http://example.com')
    Net::HTTP.start(uri.host, uri.port, read_timeout: 1) do |http|
      expect(http.read_timeout).to eq(1)
    end
  end

  it 'sets write timeout for ruby >=2.6' do
    skip unless Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.6')

    Timecop.freeze
    Cutoff.start(5)
    Timecop.freeze(2)
    uri = URI.parse('http://example.com')
    Net::HTTP.start(uri.host, uri.port) do |http|
      expect(http.write_timeout).to eq(3)
    end
  end

  it 'does nothing if cutoff is not active' do
    expect(Net::HTTP.get_response(URI.parse('http://example.com')).code)
      .to eq('200')
  end

  it 'returns normally if response is within timeout' do
    Cutoff.start(10)
    expect(Net::HTTP.get_response(URI.parse('http://example.com')).code)
      .to eq('200')
  end
end
