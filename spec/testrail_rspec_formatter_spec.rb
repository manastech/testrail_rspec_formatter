require "spec_helper"

describe TestrailRspecFormatter do
  it "has a version number", testrail: 1182 do
    expect(TestrailRspecFormatter::VERSION).not_to be nil
  end
end
